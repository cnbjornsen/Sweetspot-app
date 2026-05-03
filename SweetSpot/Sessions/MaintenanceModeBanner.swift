import SwiftUI
import SweetSpotKit

struct MaintenanceModeBanner: View {
    let state: SnapshotState
    let soberAt: Date?

    var body: some View {
        if message != nil {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 2) {
                    if let title { Text(title).font(.headline) }
                    if let message { Text(message).font(.footnote).opacity(0.85) }
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .background(Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private var icon: String {
        switch state {
        case .maintenance:    return "arrow.triangle.2.circlepath"
        case .coastingHome:   return "house.fill"
        default:              return "info.circle"
        }
    }

    private var title: String? {
        switch state {
        case .maintenance:    return "Maintenance mode"
        case .coastingHome:   return "Coast home"
        default:              return nil
        }
    }

    private var message: String? {
        switch state {
        case .maintenance:
            return "You're at the top of the band. About one drink an hour from here keeps you steady."
        case .coastingHome:
            if let soberAt {
                return "Session over. Estimated 0.00 BAC at \(soberAt.formatted(date: .omitted, time: .shortened))."
            }
            return "Session over. Drink water and head home."
        default:
            return nil
        }
    }
}
