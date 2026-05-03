import SwiftUI

/// Circular BAC gauge. Carries an SF Symbol overlay so the zone reads
/// without color (accessibility requirement).
struct BACRing: View {
    let bac: Double
    let target: Double
    var lineWidth: CGFloat = 10
    var showsLabel: Bool = true

    private var zone: BACZone { BACZone.zone(for: bac) }
    private var fill: Double { min(1, max(0, bac / max(0.0001, target * 1.6))) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fill)
                .stroke(zone.color, style: StrokeStyle(lineWidth: lineWidth,
                                                       lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Image(systemName: zone.symbolName)
                    .foregroundStyle(zone.color)
                    .font(.title2)
                if showsLabel {
                    Text(formattedBAC)
                        .font(.system(.title3, design: .rounded).bold())
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Current blood alcohol \(formattedBAC), \(zone.label)"))
    }

    private var formattedBAC: String {
        String(format: "%.3f", bac)
    }
}

#Preview {
    HStack(spacing: 16) {
        BACRing(bac: 0.001, target: 0.05).frame(width: 80, height: 80)
        BACRing(bac: 0.030, target: 0.05).frame(width: 80, height: 80)
        BACRing(bac: 0.060, target: 0.05).frame(width: 80, height: 80)
        BACRing(bac: 0.090, target: 0.05).frame(width: 80, height: 80)
    }
    .padding()
    .background(.black)
}
