import SwiftUI
import SweetSpotKit

struct NewSessionView: View {
    let profile: UserProfile

    @Environment(SessionController.self) private var sessionController
    @State private var occasion: Occasion?
    @State private var modeKind: ModeKind = .evenlyPaced
    @State private var startAt: Date = .now
    @State private var endAt: Date = .now.addingTimeInterval(4 * 3600)
    @State private var peakAt: Date = .now.addingTimeInterval(2 * 3600)

    var body: some View {
        ZStack {
            Theme.festiveGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    OccasionPickerView(selection: $occasion)
                    modePicker
                    timesSection
                    startButton
                }
                .padding()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sweet Spot")
                .font(Theme.displayFont(size: 44))
                .foregroundStyle(.white)
            if let q = QuoteLibrary.shared.dailyQuote(for: .onboarding) {
                Text(q.text)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pace strategy").font(.headline).foregroundStyle(.white)
            Picker("Mode", selection: $modeKind) {
                Text("Even").tag(ModeKind.evenlyPaced)
                Text("Ramp + maintain").tag(ModeKind.peakThenMaintain)
            }
            .pickerStyle(.segmented)
            .colorScheme(.dark)
            Text(modeKind.subtitle)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var timesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker("Start", selection: $startAt, displayedComponents: [.hourAndMinute])
            if modeKind == .peakThenMaintain {
                DatePicker("Peak", selection: $peakAt,
                           in: startAt...endAt,
                           displayedComponents: [.hourAndMinute])
            }
            DatePicker("End", selection: $endAt,
                       in: startAt.addingTimeInterval(60)...,
                       displayedComponents: [.hourAndMinute])
        }
        .colorScheme(.dark)
        .padding()
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var startButton: some View {
        Button {
            Task {
                await sessionController.startSession(
                    occasion: occasion, mode: makeMode())
            }
        } label: {
            Label("Start session", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.white)
        .foregroundStyle(.black)
        .disabled(occasion == nil)
    }

    private func makeMode() -> SessionMode {
        switch modeKind {
        case .evenlyPaced:
            return .evenlyPaced(start: startAt, end: endAt)
        case .peakThenMaintain:
            return .peakThenMaintain(start: startAt,
                                     peak: max(startAt.addingTimeInterval(60),
                                              min(peakAt, endAt.addingTimeInterval(-60))),
                                     end: endAt)
        }
    }

    private enum ModeKind: Hashable {
        case evenlyPaced
        case peakThenMaintain

        var subtitle: String {
            switch self {
            case .evenlyPaced:
                return "Spread drinks evenly across the whole window."
            case .peakThenMaintain:
                return "Ramp up to a peak, then coast at one drink an hour."
            }
        }
    }
}
