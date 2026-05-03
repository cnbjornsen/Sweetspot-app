import SwiftUI
import SwiftData
import SweetSpotKit

/// Top-level navigation gate. Routes users through onboarding the first
/// launch, then presents the main tab interface.
struct RootView: View {
    @Query private var profiles: [UserProfile]
    @Environment(SessionController.self) private var sessionController

    var body: some View {
        if let profile = profiles.first, profile.hasCompletedOnboarding {
            MainTabsView(profile: profile)
        } else {
            OnboardingFlowView(existingProfile: profiles.first)
        }
    }
}

struct MainTabsView: View {
    let profile: UserProfile
    @Environment(SessionController.self) private var sessionController

    var body: some View {
        TabView {
            sessionTab.tabItem {
                Label("Session", systemImage: "wineglass")
            }
            HistoryListView()
                .tabItem { Label("History", systemImage: "chart.bar.fill") }
            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.white)
    }

    @ViewBuilder
    private var sessionTab: some View {
        if sessionController.session != nil {
            ActiveSessionView()
        } else {
            NewSessionView(profile: profile)
        }
    }
}
