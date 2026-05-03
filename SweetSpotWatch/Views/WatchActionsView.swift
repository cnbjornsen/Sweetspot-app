import SwiftUI
import SweetSpotKit

struct WatchActionsView: View {
    @State private var showingExtra = false

    var body: some View {
        VStack(spacing: 6) {
            Button {
                WatchSessionManager.shared.sendLogScheduled()
            } label: {
                Label("I had one", systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Button {
                    showingExtra = true
                } label: {
                    Label("Extra", systemImage: "plus")
                }
                Button {
                    WatchSessionManager.shared.sendLogWater()
                } label: {
                    Label("Water", systemImage: "drop.fill")
                }
            }
            .buttonStyle(.bordered)
        }
        .sheet(isPresented: $showingExtra) {
            WatchExtraPicker()
        }
    }
}

struct WatchExtraPicker: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(alcoholic, id: \.self) { type in
                    Button {
                        WatchSessionManager.shared.sendLogExtra(type: type)
                        dismiss()
                    } label: {
                        Label(type.displayName, systemImage: type.sfSymbolName)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var alcoholic: [DrinkType] {
        [.beer12oz, .wine5oz, .shot15oz, .cocktailStandard]
    }
}

private extension DrinkType {
    var sfSymbolName: String {
        switch self {
        case .beer12oz:         return "mug.fill"
        case .wine5oz:          return "wineglass.fill"
        case .shot15oz:         return "drop.fill"
        case .cocktailStandard: return "wineglass"
        case .custom:           return "sparkles"
        case .water:            return "drop"
        }
    }
}
