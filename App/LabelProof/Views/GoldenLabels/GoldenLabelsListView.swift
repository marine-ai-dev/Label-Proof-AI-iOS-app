import SwiftUI
import LabelProofCore

struct GoldenLabelsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var goldenLabels: [GoldenLabel] = []
    @State private var showingCreate = false
    @State private var editingGoldenLabel: GoldenLabel?

    var body: some View {
        NavigationStack {
            Group {
                if goldenLabels.isEmpty {
                    ContentUnavailableView(
                        String(localized: "goldenLabels.emptyTitle"),
                        systemImage: "checkmark.seal",
                        description: Text("goldenLabels.emptySubtitle")
                    )
                    .accessibilityIdentifier("goldenLabels.emptyState")
                } else {
                    List {
                        ForEach(goldenLabels) { goldenLabel in
                            Button {
                                editingGoldenLabel = goldenLabel
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goldenLabel.name).font(.body.weight(.semibold))
                                    Text(goldenLabel.expectedProductName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityIdentifier("goldenLabels.row.\(goldenLabel.id.uuidString)")
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle(String(localized: "goldenLabels.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label(String(localized: "goldenLabels.add"), systemImage: "plus")
                    }
                    .accessibilityIdentifier("goldenLabels.addButton")
                }
            }
            .onAppear(perform: reload)
            .sheet(isPresented: $showingCreate, onDismiss: reload) {
                GoldenLabelFormView(mode: .create)
            }
            .sheet(item: $editingGoldenLabel, onDismiss: reload) { goldenLabel in
                GoldenLabelFormView(mode: .edit(goldenLabel))
            }
        }
    }

    private func reload() {
        goldenLabels = GoldenLabelStore(context: modelContext).fetchAll()
    }

    private func delete(at offsets: IndexSet) {
        let store = GoldenLabelStore(context: modelContext)
        for index in offsets {
            store.delete(id: goldenLabels[index].id)
        }
        reload()
    }
}
