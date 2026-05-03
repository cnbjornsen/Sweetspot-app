import SwiftUI
import SweetSpotKit

struct MemeCardView: View {
    let meme: Meme

    var body: some View {
        VStack(spacing: 8) {
            Image(meme.assetName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            Text(meme.caption)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
