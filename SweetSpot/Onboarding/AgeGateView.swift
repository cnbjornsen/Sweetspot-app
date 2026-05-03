import SwiftUI

struct AgeGateView: View {
    @Binding var blocked: Bool
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("Quick check")
                .font(Theme.displayFont(size: 36))
                .foregroundStyle(.white)
            Text("Are you of legal drinking age in your jurisdiction?")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal)
            VStack(spacing: 12) {
                Button("Yes, I am") { onAnswer(true) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.white)
                    .foregroundStyle(.black)
                Button("Not yet") { blocked = true; onAnswer(false) }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.white)
            }
            if blocked {
                Text("Sweet Spot is for adults of legal drinking age. Come back when you can.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top)
            }
        }
        .padding()
    }
}
