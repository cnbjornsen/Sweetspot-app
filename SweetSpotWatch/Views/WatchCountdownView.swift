import SwiftUI
import SweetSpotKit

struct WatchCountdownView: View {
    @Environment(WatchState.self) private var watchState

    var body: some View {
        let snapshot = watchState.snapshot
        ScrollView {
            VStack(spacing: 8) {
                if let next = snapshot.nextDrinkAt, next > .now {
                    Text("Next sip in")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(next, style: .timer)
                        .font(.system(.title, design: .rounded).monospacedDigit().bold())
                } else {
                    Text("🎉 Cheers!")
                        .font(.title3.bold())
                }

                HStack(spacing: 8) {
                    Image(systemName: zoneSymbol(for: snapshot.currentBAC))
                        .foregroundStyle(zoneColor(for: snapshot.currentBAC))
                    Text(String(format: "%.3f", snapshot.currentBAC))
                        .font(.subheadline.monospacedDigit())
                }

                HStack(spacing: 12) {
                    VStack {
                        Image(systemName: "wineglass.fill")
                        Text("\(snapshot.drinkCount)").font(.caption.bold())
                    }
                    VStack {
                        Image(systemName: "drop.fill")
                        Text("\(snapshot.waterCount)").font(.caption.bold())
                    }
                }
                .foregroundStyle(.secondary)

                WatchActionsView()

                if let quote = snapshot.quote {
                    Text(quote)
                        .font(.caption2.italic())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func zoneSymbol(for bac: Double) -> String {
        switch bac {
        case ..<0.005: return "moon.zzz.fill"
        case ..<0.05:  return "checkmark.seal.fill"
        case ..<0.08:  return "exclamationmark.triangle.fill"
        default:       return "xmark.octagon.fill"
        }
    }

    private func zoneColor(for bac: Double) -> Color {
        switch bac {
        case ..<0.005: return .blue
        case ..<0.05:  return .green
        case ..<0.08:  return .orange
        default:       return .red
        }
    }
}
