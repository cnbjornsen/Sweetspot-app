import SwiftUI
import SwiftData
import SweetSpotKit

struct OccasionPickerView: View {
    @Binding var selection: Occasion?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Occasion.lastUsedAt, order: .reverse)])
    private var occasions: [Occasion]

    @State private var newName: String = ""
    @State private var showingNew = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Occasion").font(.headline).foregroundStyle(.white)
                Spacer()
                Button {
                    showingNew = true
                } label: {
                    Label("New", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(occasions) { occasion in
                        OccasionChip(
                            occasion: occasion,
                            selected: selection?.id == occasion.id) {
                                selection = occasion
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .alert("New occasion", isPresented: $showingNew) {
            TextField("Name", text: $newName)
            Button("Add") { addOccasion() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("e.g. Summer wedding, Friday with the team")
        }
    }

    private func addOccasion() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let occasion = Occasion(name: trimmed, emoji: "🎉")
        modelContext.insert(occasion)
        try? modelContext.save()
        selection = occasion
        newName = ""
    }
}

private struct OccasionChip: View {
    let occasion: Occasion
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji = occasion.emoji {
                    Text(emoji)
                }
                Text(occasion.name)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(selected ? Color.white.opacity(0.95) : Color.white.opacity(0.18))
            .foregroundStyle(selected ? .black : .white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
