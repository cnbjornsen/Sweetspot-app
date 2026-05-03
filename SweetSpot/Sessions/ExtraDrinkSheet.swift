import SwiftUI
import SweetSpotKit

struct ExtraDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionController.self) private var sessionController

    @State private var selection: DrinkType = .shot15oz
    @State private var multiplier: Double = 1.0
    @State private var customGrams: Double = 14

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $selection) {
                        ForEach(alcoholicTypes, id: \.self) { type in
                            Label(type.displayName, systemImage: type.sfSymbolName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }
                Section("Pour size") {
                    HStack {
                        Text("Multiplier")
                        Spacer()
                        Text(String(format: "×%.2f", multiplier)).monospacedDigit()
                    }
                    Slider(value: $multiplier, in: 0.5...3.0, step: 0.25)
                }
                if selection == .custom {
                    Section("Custom") {
                        Stepper("Ethanol grams: \(Int(customGrams))",
                                value: $customGrams,
                                in: 1...60)
                    }
                }
            }
            .navigationTitle("Extra drink")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log it") {
                        Task {
                            let override = DrinkSizeOverride(
                                multiplier: multiplier,
                                customEthanolGrams: selection == .custom ? customGrams : nil)
                            await sessionController.logExtraDrink(selection,
                                                                  override: override)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var alcoholicTypes: [DrinkType] {
        DrinkType.allCases.filter { $0.contributesToBAC || $0 == .custom }
    }
}
