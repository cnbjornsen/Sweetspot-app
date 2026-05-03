import SwiftUI
import SweetSpotKit

struct ActiveSessionView: View {
    @Environment(SessionController.self) private var sessionController
    @State private var showingExtra = false
    @State private var showingMidCheck = false
    @State private var showingEndConfirm = false
    @State private var showingMeme = false

    var body: some View {
        ZStack {
            Theme.festiveGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    occasionTitle
                    bacRing
                    countdown
                    MaintenanceModeBanner(state: sessionController.snapshotState,
                                          soberAt: sessionController.soberAt)
                    quoteBanner
                    actionButtons
                    soberAtRow
                    endButton
                }
                .padding()
            }
            ConfettiView(trigger: sessionController.lastConfettiTrigger)
                .allowsHitTesting(false)
            if showingMeme, let meme = QuoteLibrary.shared.randomMeme(for: .fanfare) {
                MemeCardView(meme: meme)
                    .transition(.opacity.combined(with: .scale))
                    .padding()
            }
        }
        .sheet(isPresented: $showingExtra) {
            ExtraDrinkSheet()
        }
        .sheet(isPresented: $showingMidCheck) {
            MidIntervalCheckSheet()
        }
        .alert("End session?", isPresented: $showingEndConfirm) {
            Button("End", role: .destructive) {
                Task { await sessionController.endSession() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll save your stats and dismiss the lock-screen activity.")
        }
        .onChange(of: sessionController.midIntervalCheckDue) { _, due in
            showingMidCheck = due
        }
        .onChange(of: sessionController.lastConfettiTrigger) { _, _ in
            withAnimation(.spring) { showingMeme = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showingMeme = false }
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: NotificationDelegate.confettiTriggerName)) { _ in
            // System notification fired while app was in foreground.
            // SessionController's tick will increment the trigger soon,
            // but force confetti immediately for snappier feel.
            withAnimation { showingMeme = true }
        }
    }

    // MARK: Sections

    private var occasionTitle: some View {
        Text(sessionController.session?.occasion?.name ?? "Sweet Spot")
            .font(Theme.displayFont(size: 32))
            .foregroundStyle(.white)
    }

    private var bacRing: some View {
        BACRing(bac: sessionController.currentBAC, target: 0.05)
            .frame(width: 220, height: 220)
            .padding(.top, 12)
    }

    @ViewBuilder
    private var countdown: some View {
        if let next = sessionController.nextDrinkAt, next > .now {
            VStack {
                Text("Next drink in")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(next, style: .timer)
                    .font(Theme.numberFont(size: 56))
                    .foregroundStyle(.white)
            }
        } else if sessionController.fanfarePending {
            Text("🎉 Time for the next one")
                .font(Theme.displayFont(size: 28))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var quoteBanner: some View {
        if let q = QuoteLibrary.shared.random(for: .encouraging) {
            QuoteBannerView(text: q.text)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                Task { await sessionController.logScheduledDrink() }
            } label: {
                Label("I had one", systemImage: "wineglass.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.white)
            .foregroundStyle(.black)

            HStack {
                Button {
                    showingExtra = true
                } label: {
                    Label("Had extra", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)

                Button {
                    Task { await sessionController.logWater() }
                } label: {
                    Label("Water", systemImage: "drop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
            }

            Button("Undo last") {
                Task { await sessionController.undoLastDrink() }
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var soberAtRow: some View {
        if let soberAt = sessionController.soberAt {
            HStack {
                Image(systemName: "moon.stars.fill")
                Text("Estimated 0.00 BAC at \(soberAt.formatted(date: .omitted, time: .shortened))")
                Spacer()
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.85))
            .padding()
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private var endButton: some View {
        Button("End session") {
            showingEndConfirm = true
        }
        .buttonStyle(.bordered)
        .tint(.white)
    }
}
