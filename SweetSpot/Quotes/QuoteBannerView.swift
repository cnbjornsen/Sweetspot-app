import SwiftUI

struct QuoteBannerView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout.italic())
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.92))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
