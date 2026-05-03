import SwiftUI
import Charts
import SweetSpotKit

/// Plot BAC over the duration of a session, with the 0.05 sweet-spot ceiling
/// drawn as a rule mark and the in-band region shaded.
struct BACTimelineChart: View {
    let session: Session
    let profile: UserProfile

    var body: some View {
        let timeline = BACTimeline(drinks: session.drinks.map(\.asDrink),
                                   profile: profile.bacProfile)
        let samples = sample(timeline: timeline)

        Chart {
            ForEach(samples, id: \.time) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("BAC", point.bac)
                )
                .interpolationMethod(.monotone)
                AreaMark(
                    x: .value("Time", point.time),
                    yStart: .value("Floor", 0),
                    yEnd: .value("BAC", point.bac)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(.white.opacity(0.15))
            }
            RuleMark(y: .value("Sweet spot ceiling", 0.05))
                .foregroundStyle(.green.opacity(0.6))
                .annotation(position: .topTrailing, alignment: .trailing) {
                    Text("0.05").font(.caption2).foregroundStyle(.green)
                }
            ForEach(session.drinks.filter { $0.contributesToBAC }, id: \.id) { drink in
                PointMark(
                    x: .value("Time", drink.timestamp),
                    y: .value("BAC", timeline.bac(at: drink.timestamp)))
                .symbol(by: .value("Type", drink.type.displayName))
                .foregroundStyle(drink.wasScheduled ? .white : .yellow)
            }
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .foregroundStyle(.white)
    }

    private struct Sample { let time: Date; let bac: Double }

    private func sample(timeline: BACTimeline) -> [Sample] {
        let start = session.startedAt
        let end = session.endedAt ?? Date.now
        guard end > start else { return [] }
        let totalSeconds = end.timeIntervalSince(start)
        let stepCount = 80
        let step = totalSeconds / Double(stepCount)
        return (0...stepCount).map { i in
            let t = start.addingTimeInterval(Double(i) * step)
            return Sample(time: t, bac: timeline.bac(at: t))
        }
    }
}

private extension DrinkEvent {
    var contributesToBAC: Bool { ethanolGrams > 0 }
}
