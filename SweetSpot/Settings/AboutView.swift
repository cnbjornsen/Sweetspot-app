import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sweet Spot")
                    .font(Theme.displayFont(size: 36))
                Text("Version \(appVersion) (\(appBuild))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Privacy promise").font(.headline)
                    Text("All your data lives on this device. No analytics, no network calls, no third-party SDKs. There is no account. There is no server. We can't see anything you log because we never receive it.")
                }

                Group {
                    Text("Disclaimer").font(.headline)
                    Text("BAC estimates are approximations based on the Widmark formula. Real BAC depends on factors we can't measure (food, sleep, medications, individual physiology). Sweet Spot is not medical or legal advice. Don't drive after drinking. Some people should not drink at all — listen to your doctor over us.")
                }

                Group {
                    Text("Credits").font(.headline)
                    Text("BAC math: Erik M.P. Widmark, 1932. Sweet-spot framing: University of Arizona Campus Health Service.")
                }
            }
            .padding()
            .foregroundStyle(.primary)
        }
        .navigationTitle("About")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
