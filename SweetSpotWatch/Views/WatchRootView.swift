import SwiftUI
import SweetSpotKit

struct WatchRootView: View {
    @Environment(WatchState.self) private var watchState

    var body: some View {
        if watchState.snapshot.sessionID == nil
            || watchState.snapshot.state == .idle
            || watchState.snapshot.state == .ended {
            WatchIdleView()
        } else if watchState.stale {
            WatchOfflineFallbackView()
        } else {
            WatchCountdownView()
        }
    }
}

struct WatchIdleView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "wineglass")
                .font(.title)
            Text("Sweet Spot")
                .font(.headline)
            Text("Start a session on iPhone")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct WatchOfflineFallbackView: View {
    @Environment(WatchState.self) private var watchState

    var body: some View {
        VStack(spacing: 4) {
            Label("Offline", systemImage: "wifi.slash")
                .font(.caption)
                .foregroundStyle(.orange)
            if let next = watchState.snapshot.nextDrinkAt, next > .now {
                Text(next, style: .timer)
                    .font(.title.monospacedDigit().bold())
            }
            Text("Showing last known")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
