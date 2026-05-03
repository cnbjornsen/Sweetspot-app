import SwiftUI
import SwiftData
import SweetSpotKit

/// Linear onboarding. Each step writes into a `Draft`; the final step
/// commits a `UserProfile` to SwiftData.
struct OnboardingFlowView: View {
    let existingProfile: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationPermissionCoordinator.self) private var notificationCoordinator

    @State private var step: Step = .ageGate
    @State private var draft = Draft()
    @State private var ageBlocked = false

    var body: some View {
        ZStack {
            Theme.festiveGradient.ignoresSafeArea()
            VStack {
                content
                    .padding(.top, 60)
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if let p = existingProfile {
                draft = Draft(from: p)
                step = nextIncompleteStep(for: p)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .ageGate:
            AgeGateView(blocked: $ageBlocked) { confirmed in
                draft.ageGateConfirmedAt = confirmed ? .now : nil
                if confirmed { step = .disclaimer }
            }
        case .disclaimer:
            DisclaimerView { acknowledged in
                draft.disclaimerAcknowledgedAt = acknowledged ? .now : nil
                if acknowledged { step = .units }
            }
        case .units:
            UnitsStepView(unitSystem: $draft.unitSystem) {
                step = .weight
            }
        case .weight:
            WeightStepView(weightKg: $draft.weightKg,
                           unitSystem: draft.unitSystem) {
                step = .sex
            }
        case .sex:
            SexStepView(sex: $draft.sex) {
                step = .notifications
            }
        case .notifications:
            NotificationPermissionView { _ in
                Task {
                    await commit()
                }
            }
        }
    }

    private func nextIncompleteStep(for profile: UserProfile) -> Step {
        if profile.ageGateConfirmedAt == nil { return .ageGate }
        if profile.disclaimerAcknowledgedAt == nil { return .disclaimer }
        return .notifications
    }

    @MainActor
    private func commit() async {
        let profile = existingProfile ?? UserProfile(
            weightKg: draft.weightKg,
            sex: draft.sex,
            unitSystem: draft.unitSystem,
            standardDrinkGrams: LocaleStandardDrink.grams())
        profile.weightKg = draft.weightKg
        profile.sex = draft.sex
        profile.unitSystem = draft.unitSystem
        profile.ageGateConfirmedAt = draft.ageGateConfirmedAt
        profile.disclaimerAcknowledgedAt = draft.disclaimerAcknowledgedAt
        profile.notificationsAuthorized = notificationCoordinator.isAuthorized
        if existingProfile == nil {
            modelContext.insert(profile)
        }
        try? modelContext.save()
    }

    enum Step {
        case ageGate, disclaimer, units, weight, sex, notifications
    }

    struct Draft {
        var weightKg: Double = 70
        var sex: BiologicalSex = .male
        var unitSystem: UnitSystem = UnitSystem.defaultForCurrentLocale()
        var ageGateConfirmedAt: Date?
        var disclaimerAcknowledgedAt: Date?

        init() {}

        init(from profile: UserProfile) {
            self.weightKg = profile.weightKg
            self.sex = profile.sex
            self.unitSystem = profile.unitSystem
            self.ageGateConfirmedAt = profile.ageGateConfirmedAt
            self.disclaimerAcknowledgedAt = profile.disclaimerAcknowledgedAt
        }
    }
}
