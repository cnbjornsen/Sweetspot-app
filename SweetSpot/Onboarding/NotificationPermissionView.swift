import SwiftUI

struct NotificationPermissionView: View {
    @Environment(NotificationPermissionCoordinator.self) private var coordinator
    let onDone: (Bool) -> Void

    @State private var requesting = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("Stay in the band")
                .font(Theme.displayFont(size: 36))
                .foregroundStyle(.white)
            Text("We'll only ping you when your next drink is due — no marketing, no nags.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))

            Button(requesting ? "Asking..." : "Enable notifications") {
                Task {
                    requesting = true
                    let granted = await coordinator.requestAuthorization()
                    requesting = false
                    onDone(granted)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.white)
            .foregroundStyle(.black)
            .disabled(requesting)

            Button("Skip for now") { onDone(false) }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
        }
        .padding()
    }
}
