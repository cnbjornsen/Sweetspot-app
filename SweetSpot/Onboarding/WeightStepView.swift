import SwiftUI
import SweetSpotKit

struct WeightStepView: View {
    @Binding var weightKg: Double
    let unitSystem: UnitSystem
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure")
                .font(.system(size: 56))
                .foregroundStyle(.white)
            Text("Your weight")
                .font(Theme.displayFont(size: 36))
                .foregroundStyle(.white)
            Text("This is the only number that drives the BAC math. We never share it.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))

            VStack(spacing: 8) {
                Text(formattedDisplay)
                    .font(Theme.numberFont(size: 56))
                    .foregroundStyle(.white)
                Slider(value: sliderBinding,
                       in: sliderRange,
                       step: 1)
                    .tint(.white)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

            if !inRange {
                Text("Plausible adult range only — please double-check.")
                    .foregroundStyle(.yellow)
                    .font(.footnote)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(!inRange)
        }
        .padding()
    }

    private var inRange: Bool {
        switch unitSystem {
        case .metric:   return WeightBounds.isValidKg(weightKg)
        case .imperial: return WeightBounds.isValidLb(WeightConversion.kilogramsToPounds(weightKg))
        }
    }

    private var sliderRange: ClosedRange<Double> {
        switch unitSystem {
        case .metric:   return WeightBounds.minKg...WeightBounds.maxKg
        case .imperial: return WeightBounds.minLb...WeightBounds.maxLb
        }
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: {
                switch unitSystem {
                case .metric:   return weightKg
                case .imperial: return WeightConversion.kilogramsToPounds(weightKg)
                }
            },
            set: { newValue in
                switch unitSystem {
                case .metric:   weightKg = newValue
                case .imperial: weightKg = WeightConversion.poundsToKilograms(newValue)
                }
            })
    }

    private var formattedDisplay: String {
        unitSystem.formatWeight(kilograms: weightKg)
    }
}
