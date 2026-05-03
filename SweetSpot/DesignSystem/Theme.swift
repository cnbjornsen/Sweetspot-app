import SwiftUI

enum Theme {
    static let cornerRadius: CGFloat = 20
    static let cardPadding: CGFloat = 16

    /// Primary festive gradient — purples through pinks. Used on hero cards.
    static let festiveGradient = LinearGradient(
        colors: [
            Color(red: 0.45, green: 0.10, blue: 0.65),
            Color(red: 0.95, green: 0.30, blue: 0.55),
            Color(red: 1.00, green: 0.62, blue: 0.32),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing)

    /// Calm gradient for non-active screens (history, settings).
    static let calmGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.13, blue: 0.30),
            Color(red: 0.20, green: 0.18, blue: 0.42),
        ],
        startPoint: .top,
        endPoint: .bottom)

    static func displayFont(size: CGFloat = 56) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func numberFont(size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }
}
