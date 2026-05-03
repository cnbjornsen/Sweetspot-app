import WidgetKit
import SwiftUI
import SweetSpotKit

struct NextDrinkRectangularWidget: Widget {
    let kind = "NextDrinkRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            NextDrinkRectangularView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next drink")
        .description("Countdown to your next drink and a quick total.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct NextDrinkRectangularView: View {
    let snapshot: SessionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch snapshot.state {
            case .idle, .ended:
                Text("Sweet Spot").font(.caption.bold())
                Text("Start a session in the app").font(.caption2)
            case .waiting:
                Text("Next sip in").font(.caption2)
                if let next = snapshot.nextDrinkAt {
                    Text(next, style: .timer)
                        .font(.title3.monospacedDigit().bold())
                }
                Text("🍺 \(snapshot.drinkCount) so far").font(.caption2)
            case .readyForDrink:
                Text("🎉 Time for the next one")
                    .font(.caption.bold())
                Text("Tap the activity to log it").font(.caption2)
            case .maintenance:
                Text("Maintenance mode").font(.caption.bold())
                if let next = snapshot.nextDrinkAt {
                    Text("Next in \(next, style: .relative)").font(.caption2)
                }
            case .coastingHome:
                Text("Coast home 🏠").font(.caption.bold())
                if let sober = snapshot.soberAt {
                    Text("0.00 at \(sober, style: .time)").font(.caption2)
                }
            }
            if let quote = snapshot.quote {
                Text(quote)
                    .font(.caption2.italic())
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
