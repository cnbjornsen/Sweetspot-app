import Foundation

public enum WeightConversion {
    public static let kgPerPound = 0.45359237

    public static func poundsToKilograms(_ lb: Double) -> Double {
        lb * kgPerPound
    }

    public static func kilogramsToPounds(_ kg: Double) -> Double {
        kg / kgPerPound
    }
}

public enum VolumeConversion {
    /// US fluid ounce.
    public static let mlPerFluidOunce = 29.5735295625

    public static func fluidOuncesToMilliliters(_ floz: Double) -> Double {
        floz * mlPerFluidOunce
    }

    public static func millilitersToFluidOunces(_ ml: Double) -> Double {
        ml / mlPerFluidOunce
    }
}

public enum WeightBounds {
    /// Plausible adult weight bounds. Outside these, BAC math becomes
    /// unreliable and the onboarding should reject the input.
    public static let minKg = 35.0
    public static let maxKg = 250.0
    public static let minLb = 80.0
    public static let maxLb = 550.0

    public static func isValidKg(_ kg: Double) -> Bool {
        kg >= minKg && kg <= maxKg
    }

    public static func isValidLb(_ lb: Double) -> Bool {
        lb >= minLb && lb <= maxLb
    }
}

public extension UnitSystem {
    /// Format a kilogram weight for display in the user's chosen units.
    func formatWeight(kilograms kg: Double) -> String {
        let measurement = Measurement(value: kg, unit: UnitMass.kilograms)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        switch self {
        case .metric:
            return formatter.string(from: measurement)
        case .imperial:
            return formatter.string(from: measurement.converted(to: .pounds))
        }
    }

    /// Volume display in ml or US fluid ounces.
    func formatVolume(milliliters ml: Double) -> String {
        let measurement = Measurement(value: ml, unit: UnitVolume.milliliters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        switch self {
        case .metric:
            return formatter.string(from: measurement)
        case .imperial:
            return formatter.string(from: measurement.converted(to: .fluidOunces))
        }
    }
}
