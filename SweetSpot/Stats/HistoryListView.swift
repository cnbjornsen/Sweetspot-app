import SwiftUI
import SwiftData
import SweetSpotKit

struct HistoryListView: View {
    @Query(filter: #Predicate<Session> { $0.endedAt != nil },
           sort: [SortDescriptor(\Session.startedAt, order: .reverse)])
    private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.calmGradient.ignoresSafeArea()
                if sessions.isEmpty {
                    EmptyStateView(
                        symbol: "wineglass",
                        title: "No sessions yet",
                        message: "Your first occasion awaits 🍾")
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                SessionRow(session: session)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.occasion?.name ?? "Session")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "Peak %.3f", session.peakBAC))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white)
                Text("\(session.minutesInSweetSpot) min in band")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
