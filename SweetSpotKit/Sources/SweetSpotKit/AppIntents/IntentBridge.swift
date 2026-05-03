import Foundation

/// Darwin notification names the iOS app listens for so the in-process
/// `SessionController` can react when an `AppIntent` (running in the widget
/// extension's process) inserts a drink.
public enum IntentBridgeNotification: String {
    case drinkLogged   = "com.sweetspot.intent.drink-logged"
    case extraLogged   = "com.sweetspot.intent.extra-logged"
    case waterLogged   = "com.sweetspot.intent.water-logged"
}
