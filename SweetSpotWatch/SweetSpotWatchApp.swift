import SwiftUI
import SweetSpotKit

@main
struct SweetSpotWatchApp: App {
    @State private var watchState = WatchState()

    init() {
        WatchSessionManager.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(watchState)
                .task {
                    watchState.snapshot = WatchSnapshotCache.shared.read() ?? .empty
                    WatchSessionManager.shared.onSnapshot = { snapshot in
                        watchState.snapshot = snapshot
                        WatchSnapshotCache.shared.write(snapshot)
                        WatchHaptics.fireIfDue(snapshot: snapshot,
                                               state: watchState)
                    }
                }
        }
    }
}
