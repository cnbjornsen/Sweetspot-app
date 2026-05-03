import SwiftUI
import SweetSpotKit

struct UnitsStepView: View {
    @Binding var unitSystem: UnitSystem
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "ruler")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("Units")
                .font(Theme.displayFont(size: 36))
                .foregroundStyle(.white)
            Text("We'll use these everywhere — you can change later.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
            Picker("Units", selection: $unitSystem) {
                Text("Metric (kg, ml)").tag(UnitSystem.metric)
                Text("Imperial (lb, fl oz)").tag(UnitSystem.imperial)
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
