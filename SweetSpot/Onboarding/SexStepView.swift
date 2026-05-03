import SwiftUI
import SweetSpotKit

struct SexStepView: View {
    @Binding var sex: BiologicalSex
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("Biological sex")
                .font(Theme.displayFont(size: 36))
                .foregroundStyle(.white)
            Text("The Widmark formula uses different distribution ratios for men and women — that's why we ask.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal)
            Picker("Sex", selection: $sex) {
                Text("Male").tag(BiologicalSex.male)
                Text("Female").tag(BiologicalSex.female)
            }
            .pickerStyle(.segmented)
            .colorScheme(.dark)
            Button("Continue", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.black)
        }
        .padding()
    }
}
