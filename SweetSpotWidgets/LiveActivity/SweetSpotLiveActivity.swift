import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import SweetSpotKit

struct SweetSpotLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SweetSpotAttributes.self) { context in
            // Lock-screen / banner layout
            LockScreenLiveActivityView(attributes: context.attributes,
                                       state: context.state)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.4))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "wineglass.fill")
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.drinkCount)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    if let next = context.state.nextDrinkAt, next > .now {
                        Text(next, style: .timer)
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(.white)
                    } else {
                        Text("🎉 Now")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Button(intent: LogDrinkIntent()) {
                            Label("Log drink", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.white)
                        Spacer()
                        Text(String(format: "BAC %.3f", context.state.currentBAC))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            } compactLeading: {
                Image(systemName: "wineglass.fill")
            } compactTrailing: {
                if let next = context.state.nextDrinkAt, next > .now {
                    Text(next, style: .timer)
                        .monospacedDigit()
                } else {
                    Text("🎉")
                }
            } minimal: {
                Text("\(context.state.drinkCount)")
                    .monospacedDigit()
            }
            .keylineTint(.white)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let attributes: SweetSpotAttributes
    let state: SweetSpotAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.occasionName)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
                if let next = state.nextDrinkAt, next > .now {
                    Text("Next sip in").font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(next, style: .timer)
                        .font(.title.monospacedDigit().bold())
                        .foregroundStyle(.white)
                } else {
                    Text("🎉 Time for the next one")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                if let quote = state.quote {
                    Text(quote)
                        .font(.caption.italic())
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(spacing: 4) {
                Text("\(state.drinkCount)")
                    .font(.title.bold().monospacedDigit())
                    .foregroundStyle(.white)
                Text("drinks").font(.caption2).foregroundStyle(.white.opacity(0.7))
                Text(String(format: "%.3f", state.currentBAC))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
            }
            Button(intent: LogDrinkIntent()) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
            }
            .tint(.white)
        }
    }
}
