import SwiftUI
import SweetSpotKit

struct MidIntervalCheckSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionController.self) private var sessionController

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let q = QuoteLibrary.shared.random(for: .cautionary) {
                    Text(q.text)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Text("Did anything sneak in since the last drink?")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    quickButton(.shot15oz, label: "A shot")
                    quickButton(.wine5oz, label: "A glass of wine")
                    quickButton(.beer12oz, label: "A beer")
                    quickButton(.cocktailStandard, label: "A cocktail")
                    quickButton(.water, label: "Just water 💧")
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Honest check")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Nope, all clean") {
                        sessionController.acknowledgeMidIntervalCheck()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hush this session") {
                        sessionController.snoozeMidIntervalForSession()
                        dismiss()
                    }
                }
            }
        }
    }

    private func quickButton(_ type: DrinkType, label: String) -> some View {
        Button {
            Task {
                if type == .water {
                    await sessionController.logWater()
                } else {
                    await sessionController.logExtraDrink(type)
                }
                sessionController.acknowledgeMidIntervalCheck()
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: type.sfSymbolName)
                Text(label)
                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
