import WidgetKit
import SwiftUI
import SweetSpotKit

struct BACCircularWidget: Widget {
    let kind = "BACCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotTimelineProvider()) { entry in
            BACCircularView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("BAC ring")
        .description("How close you are to the 0.05 sweet-spot ceiling.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct BACCircularView: View {
    let snapshot: SessionSnapshot

    private var fill: Double {
        min(1, max(0, snapshot.currentBAC / 0.08))
    }

    var body: some View {
        Gauge(value: fill, in: 0...1) {
            Image(systemName: zoneSymbol)
        } currentValueLabel: {
            Text(String(format: "%.2f", snapshot.currentBAC))
                .font(.caption2.monospacedDigit())
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(zoneColor)
    }

    private var zoneSymbol: String {
        switch snapshot.currentBAC {
        case ..<0.005: return "moon.zzz.fill"
        case ..<0.05:  return "checkmark.seal.fill"
        case ..<0.08:  return "exclamationmark.triangle.fill"
        default:       return "xmark.octagon.fill"
        }
    }

    private var zoneColor: Color {
        switch snapshot.currentBAC {
        case ..<0.005: return .blue
        case ..<0.05:  return .green
        case ..<0.08:  return .orange
        default:       return .red
        }
    }
}
