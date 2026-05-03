import SwiftUI
import SwiftData
import SweetSpotKit

struct ManageOccasionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Occasion.lastUsedAt, order: .reverse)])
    private var occasions: [Occasion]

    @State private var newName = ""

    var body: some View {
        List {
            Section {
                ForEach(occasions) { occasion in
                    HStack {
                        if let emoji = occasion.emoji { Text(emoji) }
                        Text(occasion.name)
                        Spacer()
                        if occasion.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            modelContext.delete(occasion)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            occasion.isFavorite.toggle()
                        } label: {
                            Label("Favorite",
                                  systemImage: occasion.isFavorite ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                }
            }
            Section("Add new") {
                TextField("Occasion name", text: $newName)
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    modelContext.insert(Occasion(name: trimmed, emoji: "🎉"))
                    newName = ""
                }
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Occasions")
    }
}
