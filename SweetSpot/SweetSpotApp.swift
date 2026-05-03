import SwiftUI
import SwiftData
import SweetSpotKit

@main
struct SweetSpotApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var sessionController: SessionController
    @State private var notificationCoordinator = NotificationPermissionCoordinator()
    private let modelContainer: ModelContainer

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer.sweetSpotShared()
        } catch {
            fatalError("Failed to open SwiftData container: \(error)")
        }
        self.modelContainer = container
        let context = ModelContext(container)
        OccasionSeeder.seedIfNeeded(in: context)
        self._sessionController = State(initialValue: SessionController(context: context))

        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionController)
                .environment(notificationCoordinator)
                .modelContainer(modelContainer)
                .task {
                    await sessionController.bootstrap()
                    await notificationCoordinator.refreshAuthorization()
                    IntentBridgeListener.shared.start { event in
                        Task { await sessionController.handleIntentNotification(event) }
                    }
                    WatchSync.shared.start()
                    WatchSync.shared.onCommand = { command in
                        Task { await sessionController.handleWatchCommand(command) }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    sessionController.handleScenePhase(phase)
                }
        }
    }
}
