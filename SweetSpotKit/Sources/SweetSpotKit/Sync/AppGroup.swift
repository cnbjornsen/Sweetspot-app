import Foundation

/// App Group identifier shared by the iOS app, widget extension, and watch app.
/// Must match the App Groups capability configured on every target in Xcode.
/// Override at runtime via `AppGroup.identifier = ...` from each target's
/// `init` if you fork the bundle ID.
public enum AppGroup {
    public static var identifier = "group.com.sweetspot.shared"

    public static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier)
    }

    public static var snapshotURL: URL? {
        containerURL?.appendingPathComponent("snapshot.json", conformingTo: .json)
    }

    public static var swiftDataStoreURL: URL? {
        containerURL?.appendingPathComponent("SweetSpot.sqlite")
    }

    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}
