import Foundation

/// Pure Widmark BAC math. No Foundation Date — operates on hours and grams.
public enum WidmarkCalculator {
    /// Default ethanol elimination rate (BAC %/hr). Constant across people.
    public static let defaultBeta = 0.015

    /// Estimated %BAC (g/100mL) from a single drink contribution.
    ///
    /// `BAC% = (ethanol_g / (r · weight_g)) · 100  −  β · hours`
    /// clamped at 0 (we don't model "negative BAC").
    public static func bac(ethanolGrams: Double,
                           weightKg: Double,
                           r: Double,
                           hoursElapsed: Double,
                           beta: Double = defaultBeta) -> Double {
        guard ethanolGrams > 0, weightKg > 0, r > 0 else { return 0 }
        let weightGrams = weightKg * 1000.0
        let raw = (ethanolGrams / (r * weightGrams)) * 100.0
        let elapsed = max(0, hoursElapsed)
        return max(0, raw - beta * elapsed)
    }

    /// Convenience: peak BAC (instant absorption) from a single drink at t=0.
    public static func peakBAC(ethanolGrams: Double,
                               profile: BACProfile) -> Double {
        bac(ethanolGrams: ethanolGrams,
            weightKg: profile.weightKg,
            r: profile.widmarkR,
            hoursElapsed: 0)
    }

    /// Hours required to fully eliminate `bac` at rate `beta`.
    public static func hoursToZero(from bac: Double,
                                   beta: Double = defaultBeta) -> Double {
        guard bac > 0, beta > 0 else { return 0 }
        return bac / beta
    }
}
