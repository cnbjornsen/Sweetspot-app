import SwiftUI
import SwiftData
import SweetSpotKit

struct SessionDetailView: View {
    let session: Session

    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Theme.calmGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if let profile = profiles.first {
                        BACTimelineChart(session: session, profile: profile)
                            .padding()
                            .background(Color.black.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    statsGrid
                    drinksList
                    if let q = QuoteLibrary.shared.dailyQuote(for: .stat) {
                        QuoteBannerView(text: q.text)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(session.occasion?.name ?? "Session")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt.formatted(date: .complete, time: .shortened))
                .foregroundStyle(.white.opacity(0.8))
            if let ended = session.endedAt {
                let duration = ended.timeIntervalSince(session.startedAt)
                Text("Duration: \(Self.durationFormatter.string(from: duration) ?? "?")")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.callout)
            }
        }
    }

    private var statsGrid: some View {
        let alcoholic = session.drinks.filter { $0.type != .water }
        return LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            StatCard(label: "Drinks", value: "\(alcoholic.count)")
            StatCard(label: "Water", value: "\(session.waterCount)")
            StatCard(label: "Peak BAC", value: String(format: "%.3f", session.peakBAC))
            StatCard(label: "In sweet spot", value: "\(session.minutesInSweetSpot) min")
            StatCard(label: "Extras", value: "\(session.unscheduledExtrasCount)")
            StatCard(label: "Sober at",
                     value: session.soberAt?.formatted(date: .omitted, time: .shortened) ?? "—")
        }
    }

    private var drinksList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drinks").font(.headline).foregroundStyle(.white)
            ForEach(session.drinks.sorted { $0.timestamp < $1.timestamp }) { drink in
                HStack {
                    Image(systemName: drink.type.sfSymbolName)
                    VStack(alignment: .leading) {
                        Text(drink.type.displayName)
                        Text(drink.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f g", drink.ethanolGrams))
                        .monospacedDigit()
                    if !drink.wasScheduled && drink.type != .water {
                        Image(systemName: "exclamationmark.bubble")
                            .foregroundStyle(.yellow)
                    }
                }
                .foregroundStyle(.white)
                .padding(.vertical, 6)
                .swipeActions(allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(drink)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        return f
    }()
}

private struct StatCard: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.7))
            Text(value).font(.title3.monospacedDigit().bold()).foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
