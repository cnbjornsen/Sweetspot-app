import SwiftUI
import SwiftData
import SweetSpotKit
import UIKit

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @Environment(NotificationPermissionCoordinator.self) private var notifications
    @Environment(\.modelContext) private var modelContext
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.calmGradient.ignoresSafeArea()
                Form {
                    profileSection
                    notificationsSection
                    sessionSection
                    festiveSection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            NavigationLink {
                EditProfileView(profile: profile)
            } label: {
                HStack {
                    Text("Weight")
                    Spacer()
                    Text(profile.unitSystem.formatWeight(kilograms: profile.weightKg))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Sex")
                Spacer()
                Text(profile.sex == .male ? "Male" : "Female")
                    .foregroundStyle(.secondary)
            }
            Picker("Units", selection: $profile.unitSystem) {
                Text("Metric").tag(UnitSystem.metric)
                Text("Imperial").tag(UnitSystem.imperial)
            }
            HStack {
                Text("One drink =")
                Spacer()
                Picker("", selection: $profile.standardDrinkGrams) {
                    ForEach(LocaleStandardDrink.presets, id: \.self) { g in
                        Text("\(Int(g)) g").tag(g)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            HStack {
                Text("Status")
                Spacer()
                Text(statusText)
                    .foregroundStyle(.secondary)
            }
            Button("Open system settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Toggle("Fanfare sound", isOn: $profile.fanfareEnabled)
        }
    }

    private var sessionSection: some View {
        Section("Sessions") {
            Picker("Mid-interval check", selection: $profile.midIntervalCheckMinutes) {
                Text("Off").tag(0)
                Text("Every 15 min").tag(15)
                Text("Every 25 min").tag(25)
                Text("Every 45 min").tag(45)
            }
            Picker("Auto-end grace", selection: $profile.watchdogGraceHours) {
                Text("1 hour").tag(1)
                Text("2 hours").tag(2)
                Text("4 hours").tag(4)
            }
        }
    }

    private var festiveSection: some View {
        Section("Festive") {
            Toggle("Quotes", isOn: $profile.quotesEnabled)
            Toggle("Memes", isOn: $profile.memesEnabled)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            NavigationLink("Manage occasions") {
                ManageOccasionsView()
            }
            Button("Delete all data", role: .destructive) {
                confirmingDelete = true
            }
        }
        .alert("Delete everything?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Profile, occasions, sessions, and drinks will be permanently removed.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            NavigationLink("About Sweet Spot") {
                AboutView()
            }
        }
    }

    private var statusText: String {
        switch notifications.status {
        case .authorized:    return "On"
        case .denied:        return "Denied"
        case .notDetermined: return "Not asked"
        case .provisional:   return "Provisional"
        case .ephemeral:     return "Ephemeral"
        @unknown default:    return "Unknown"
        }
    }

    private func deleteAll() {
        try? modelContext.delete(model: DrinkEvent.self)
        try? modelContext.delete(model: Session.self)
        try? modelContext.delete(model: Occasion.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.save()
        SnapshotStore().clear()
    }
}
