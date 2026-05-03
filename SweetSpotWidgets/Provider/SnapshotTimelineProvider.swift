import WidgetKit
import SweetSpotKit

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: SessionSnapshot
}

struct SnapshotTimelineProvider: TimelineProvider {
    private let store = SnapshotStore()

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: store.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = store.read()
        let entries = [SnapshotEntry(date: .now, snapshot: snapshot)]
        let nextRefresh = snapshot.nextDrinkAt ?? Date.now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}
