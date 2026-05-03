import SwiftUI

struct DisclaimerView: View {
    let onAcknowledge: (Bool) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("A few honest words")
                .font(Theme.displayFont(size: 32))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                bullet("BAC estimates are approximations. Your real BAC depends on food, sleep, medications, and more.")
                bullet("Sweet Spot is not medical or legal advice. Don't drive after drinking.")
                bullet("Some people should not drink at all. Listen to your doctor over us.")
                bullet("Your data lives only on this device. We don't have an account or a server.")
            }
            .font(.callout)
            .foregroundStyle(.white)
            .padding()
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            Button("I understand") { onAcknowledge(true) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.black)
        }
        .padding()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill").font(.caption2)
            Text(text)
        }
    }
}
