import Foundation
import SwiftData

@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var weightKg: Double
    public var sexRaw: String
    public var unitSystemRaw: String
    /// Grams of pure ethanol per "standard drink" — locale dependent.
    public var standardDrinkGrams: Double
    public var notificationsAuthorized: Bool
    public var fanfareEnabled: Bool
    public var quotesEnabled: Bool
    public var memesEnabled: Bool
    public var midIntervalCheckMinutes: Int
    public var watchdogGraceHours: Int
    public var disclaimerAcknowledgedAt: Date?
    public var ageGateConfirmedAt: Date?
    public var createdAt: Date

    public init(weightKg: Double,
                sex: BiologicalSex,
                unitSystem: UnitSystem,
                standardDrinkGrams: Double,
                notificationsAuthorized: Bool = false,
                fanfareEnabled: Bool = true,
                quotesEnabled: Bool = true,
                memesEnabled: Bool = true,
                midIntervalCheckMinutes: Int = 25,
                watchdogGraceHours: Int = 2,
                disclaimerAcknowledgedAt: Date? = nil,
                ageGateConfirmedAt: Date? = nil,
                createdAt: Date = .now) {
        self.id = UUID()
        self.weightKg = weightKg
        self.sexRaw = sex.rawValue
        self.unitSystemRaw = unitSystem.rawValue
        self.standardDrinkGrams = standardDrinkGrams
        self.notificationsAuthorized = notificationsAuthorized
        self.fanfareEnabled = fanfareEnabled
        self.quotesEnabled = quotesEnabled
        self.memesEnabled = memesEnabled
        self.midIntervalCheckMinutes = midIntervalCheckMinutes
        self.watchdogGraceHours = watchdogGraceHours
        self.disclaimerAcknowledgedAt = disclaimerAcknowledgedAt
        self.ageGateConfirmedAt = ageGateConfirmedAt
        self.createdAt = createdAt
    }

    public var sex: BiologicalSex {
        get { BiologicalSex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }

    public var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }

    /// Pure-value snapshot for the BAC engine.
    public var bacProfile: BACProfile {
        BACProfile(weightKg: weightKg,
                   sex: sex,
                   standardDrinkGrams: standardDrinkGrams)
    }

    public var hasCompletedOnboarding: Bool {
        ageGateConfirmedAt != nil && disclaimerAcknowledgedAt != nil
    }
}
