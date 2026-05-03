import SwiftUI
import SweetSpotKit

struct EditProfileView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Weight") {
                WeightStepView(weightKg: $profile.weightKg,
                               unitSystem: profile.unitSystem) {
                    // No-op continue — we're inline in settings.
                }
            }
            Section("Biological sex") {
                Picker("Sex", selection: $profile.sex) {
                    Text("Male").tag(BiologicalSex.male)
                    Text("Female").tag(BiologicalSex.female)
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Profile")
    }
}
