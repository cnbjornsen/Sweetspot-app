import Foundation
import SwiftUI
import SwiftData
import Observation
import WidgetKit
import SweetSpotKit
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Single source of truth for the active drinking session.
///
/// Owns the session record, the planner, the notification scheduler, the
/// fanfare player, the Live Activity, and the cross-process snapshot. Every
/// state-changing call funnels through `reconcile()` so the system stays
/// consistent.
@Observable
@MainActor
final class SessionController {

    // MARK: Public observed state

    private(set) var session: Session?
    private(set) var schedule: [ScheduledDrink] = []
    private(set) var nextDrinkAt: Date?
    private(set) var currentBAC: Double = 0
    private(set) var peakBAC: Double = 0
    private(set) var soberAt: Date?
    private(set) var snapshotState: SnapshotState = .idle
    private(set) var fanfarePending: Bool = false
    private(set) var midIntervalCheckDue: Bool = false
    private(set) var lastConfettiTrigger: Int = 0

    // MARK: Dependencies

    private let context: ModelContext
    private let planner = DrinkPlanner()
    private let snapshotStore = SnapshotStore()
    private let scheduler = NotificationScheduler()
    private let fanfare = FanfarePlayer()

    // MARK: Internals

    private var tickTask: Task<Void, Never>?
    private var midIntervalTask: Task<Void, Never>?
    private var lastFiredFanfareSlot: Date?
    private var midIntervalSnoozedForSession: Bool = false
    #if canImport(ActivityKit)
    private var activity: Activity<SweetSpotAttributes>?
    #endif

    // MARK: Init

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Lifecycle

    func bootstrap() async {
        guard session == nil else { return }
        let profile = currentProfile()
        do {
            let result = try SessionHydrator.hydrate(in: context, profile: profile)
            if let restored = result.session {
                attach(to: restored)
            }
        } catch {
            // Hydration is best-effort; nothing to do if it fails.
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // OS-driven Live Activity timer keeps counting in the background;
            // refresh derived numbers as soon as we're foregrounded.
            Task { await reconcile() }
        case .background, .inactive:
            tickTask?.cancel()
            tickTask = nil
        @unknown default: break
        }
    }

    func handleIntentNotification(_ event: IntentBridgeNotification) async {
        await reconcile()
        if event == .drinkLogged {
            triggerConfetti()
        }
    }

    func handleWatchCommand(_ command: WatchSync.Command) async {
        switch command {
        case .logScheduled:
            await logScheduledDrink()
        case .logExtra(let type):
            await logExtraDrink(type)
        case .logWater:
            await logWater()
        }
    }

    // MARK: Mutations

    func startSession(occasion: Occasion?, mode: SessionMode) async {
        guard session == nil else { return }
        let new = Session(startedAt: mode.start,
                          plannedEndAt: mode.end,
                          plannedPeakAt: mode.peak,
                          mode: mode,
                          occasion: occasion)
        context.insert(new)
        if let occasion {
            occasion.lastUsedAt = .now
        }
        try? context.save()
        QuoteLibrary.shared.resetSessionMemory()
        attach(to: new)
    }

    func logScheduledDrink(type: DrinkType = .beer12oz,
                           override: DrinkSizeOverride = .standard) async {
        await logDrink(type: type, override: override, scheduled: true)
    }

    func logExtraDrink(_ type: DrinkType,
                       override: DrinkSizeOverride = .standard) async {
        await logDrink(type: type, override: override, scheduled: false)
    }

    func logWater() async {
        await logDrink(type: .water, override: .standard, scheduled: false)
    }

    func undoLastDrink() async {
        guard let session,
              let last = session.drinks.sorted(by: { $0.timestamp > $1.timestamp }).first
        else { return }
        context.delete(last)
        try? context.save()
        await reconcile()
    }

    func deleteDrink(_ drinkID: UUID) async {
        guard let session,
              let target = session.drinks.first(where: { $0.id == drinkID })
        else { return }
        context.delete(target)
        try? context.save()
        await reconcile()
    }

    func endSession(reason: EndReason = .user) async {
        guard let session else { return }
        let now = Date.now
        finalizeStats(on: session, at: now)
        session.endedAt = now
        session.endReason = reason
        try? context.save()
        scheduler.cancelAll()
        #if canImport(ActivityKit)
        if let activity {
            await activity.end(.init(state: currentLiveActivityState(),
                                     staleDate: now.addingTimeInterval(60)),
                               dismissalPolicy: .after(now.addingTimeInterval(30)))
        }
        activity = nil
        #endif
        snapshotStore.write(SessionSnapshot(state: .ended, updatedAt: now))
        WidgetCenter.shared.reloadAllTimelines()
        detach()
    }

    func snoozeMidIntervalForSession() {
        midIntervalSnoozedForSession = true
        midIntervalCheckDue = false
    }

    func acknowledgeMidIntervalCheck() {
        midIntervalCheckDue = false
    }

    func acknowledgeFanfare() {
        fanfarePending = false
    }

    // MARK: Core

    private func attach(to session: Session) {
        self.session = session
        startTicker()
        startMidIntervalTimer()
        Task { await reconcile() }
        startLiveActivityIfPossible()
    }

    private func detach() {
        session = nil
        schedule = []
        nextDrinkAt = nil
        currentBAC = 0
        peakBAC = 0
        soberAt = nil
        snapshotState = .idle
        tickTask?.cancel()
        tickTask = nil
        midIntervalTask?.cancel()
        midIntervalTask = nil
        lastFiredFanfareSlot = nil
        midIntervalSnoozedForSession = false
    }

    private func logDrink(type: DrinkType,
                          override: DrinkSizeOverride,
                          scheduled: Bool) async {
        guard let session, let profile = currentProfile() else { return }
        let grams = type.ethanolGrams(profile: profile.bacProfile, override: override)
        let event = DrinkEvent(timestamp: .now,
                               type: type,
                               ethanolGrams: grams,
                               sizeMultiplier: override.multiplier,
                               wasScheduled: scheduled,
                               session: session)
        context.insert(event)
        try? context.save()
        if scheduled { triggerConfetti() }
        await reconcile()
    }

    private func reconcile() async {
        guard let session, let profile = currentProfile(),
              let mode = session.mode else { return }
        let now = Date.now
        let drinks = session.drinks.map(\.asDrink)
        let timeline = BACTimeline(drinks: drinks, profile: profile.bacProfile)
        currentBAC = timeline.bac(at: now)
        peakBAC = max(peakBAC, currentBAC)
        soberAt = SoberTimeEstimator(timeline: timeline)
            .time(reaching: 0.0, after: now)

        let plan = planner.schedule(PlannerInput(
            profile: profile.bacProfile,
            mode: mode,
            now: now,
            alreadyConsumed: drinks))
        schedule = plan
        nextDrinkAt = plan.first?.scheduledAt
        snapshotState = computeState(now: now)
        fanfarePending = nextDrinkAt.map { $0 <= now } ?? false

        scheduler.rescheduleNextDrinkNotification(at: nextDrinkAt)
        let snapshot = currentSnapshot(now: now)
        snapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        updateLiveActivity()
        WatchSync.shared.push(snapshot)

        if fanfarePending,
           let fired = nextDrinkAt,
           lastFiredFanfareSlot != fired {
            lastFiredFanfareSlot = fired
            fanfare.playIfEnabled(profile: profile)
            triggerConfetti()
        }
    }

    private func computeState(now: Date) -> SnapshotState {
        guard let session else { return .idle }
        if session.endedAt != nil { return .ended }
        if let nextDrinkAt, nextDrinkAt <= now { return .readyForDrink }
        if let plannedPeak = session.plannedPeakAt, now > plannedPeak,
           let nextDrinkAt, nextDrinkAt > plannedPeak {
            return .maintenance
        }
        if now > session.plannedEndAt { return .coastingHome }
        return .waiting
    }

    private func currentSnapshot(now: Date) -> SessionSnapshot {
        SessionSnapshot(
            sessionID: session?.id,
            occasionName: session?.occasion?.name ?? "",
            state: snapshotState,
            nextDrinkAt: nextDrinkAt,
            drinkCount: session?.drinks.filter { $0.type != .water }.count ?? 0,
            waterCount: session?.drinks.filter { $0.type == .water }.count ?? 0,
            currentBAC: currentBAC,
            peakBAC: peakBAC,
            soberAt: soberAt,
            plannedEndAt: session?.plannedEndAt,
            quote: QuoteLibrary.shared.random(for: .encouraging)?.text,
            updatedAt: now)
    }

    // MARK: Tick + mid-interval timer

    private func startTicker() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                await self?.tick()
            }
        }
    }

    private func tick() async {
        guard let session, let profile = currentProfile() else { return }
        let drinks = session.drinks.map(\.asDrink)
        let timeline = BACTimeline(drinks: drinks, profile: profile.bacProfile)
        let now = Date.now
        currentBAC = timeline.bac(at: now)
        peakBAC = max(peakBAC, currentBAC)

        if let next = nextDrinkAt, next <= now, !fanfarePending {
            await reconcile() // crosses the slot — full reconcile
        }
    }

    private func startMidIntervalTimer() {
        midIntervalTask?.cancel()
        guard let profile = currentProfile(),
              profile.midIntervalCheckMinutes > 0 else { return }
        let interval = TimeInterval(profile.midIntervalCheckMinutes * 60)
        midIntervalTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled { break }
                if let s = self, !s.midIntervalSnoozedForSession {
                    await MainActor.run { s.midIntervalCheckDue = true }
                }
            }
        }
    }

    // MARK: Live Activity

    private func startLiveActivityIfPossible() {
        #if canImport(ActivityKit)
        guard let session,
              ActivityAuthorizationInfo().areActivitiesEnabled,
              activity == nil else { return }
        let occasionName = session.occasion?.name ?? "Sweet Spot"
        let attributes = SweetSpotAttributes(sessionID: session.id,
                                             occasionName: occasionName,
                                             startedAt: session.startedAt,
                                             plannedEndAt: session.plannedEndAt)
        let initial = currentLiveActivityState()
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initial,
                               staleDate: nextDrinkAt?.addingTimeInterval(5 * 60))
            )
        } catch {
            activity = nil
        }
        #endif
    }

    private func updateLiveActivity() {
        #if canImport(ActivityKit)
        guard let activity else { return }
        let stale = nextDrinkAt?.addingTimeInterval(5 * 60)
            ?? Date.now.addingTimeInterval(15 * 60)
        Task {
            await activity.update(.init(state: currentLiveActivityState(),
                                        staleDate: stale))
        }
        #endif
    }

    #if canImport(ActivityKit)
    private func currentLiveActivityState() -> SweetSpotAttributes.ContentState {
        SweetSpotAttributes.ContentState(
            nextDrinkAt: nextDrinkAt,
            drinkCount: session?.drinks.filter { $0.type != .water }.count ?? 0,
            waterCount: session?.drinks.filter { $0.type == .water }.count ?? 0,
            currentBAC: currentBAC,
            soberAt: soberAt,
            snapshotState: snapshotState,
            quote: QuoteLibrary.shared.dailyQuote(for: .encouraging)?.text)
    }
    #endif

    // MARK: Helpers

    private func currentProfile() -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? context.fetch(descriptor))?.first
    }

    private func triggerConfetti() {
        lastConfettiTrigger &+= 1
    }

    private func finalizeStats(on session: Session, at endDate: Date) {
        guard let profile = currentProfile() else { return }
        let drinks = session.drinks.map(\.asDrink)
        let timeline = BACTimeline(drinks: drinks, profile: profile.bacProfile)
        let range = session.startedAt...endDate
        session.peakBAC = timeline.peakBAC(in: range)
        session.minutesInSweetSpot = timeline.minutesAtOrBelow(0.05, in: range)
        session.unscheduledExtrasCount = session.drinks.filter {
            !$0.wasScheduled && $0.type != .water
        }.count
        session.waterCount = session.drinks.filter { $0.type == .water }.count
        session.soberAt = SoberTimeEstimator(timeline: timeline)
            .time(reaching: 0.0, after: endDate)
    }
}
