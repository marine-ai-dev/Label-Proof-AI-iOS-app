import SwiftUI
import LabelProofCore

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    // See HomeView's comment on this same property.
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var records: [VerificationRecord] = []

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        L("history.emptyTitle"),
                        systemImage: "clock",
                        description: Text("history.emptySubtitle")
                    )
                    .accessibilityIdentifier("history.emptyState")
                } else {
                    List {
                        ForEach(records) { record in
                            HStack {
                                Image(systemName: iconName(for: record.result.status))
                                    .foregroundStyle(color(for: record.result.status))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.goldenLabelNameSnapshot).font(.body.weight(.semibold))
                                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(Text("history.rowAccessibilityLabel \(statusTitle(for: record.result.status)) \(record.goldenLabelNameSnapshot) \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"))
                            .accessibilityIdentifier("history.row.\(record.id.uuidString)")
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle(L("history.title"))
            .onAppear(perform: reload)
        }
    }

    private func reload() {
        records = VerificationHistoryStore(context: modelContext).fetchAll()
    }

    private func delete(at offsets: IndexSet) {
        let store = VerificationHistoryStore(context: modelContext)
        for index in offsets {
            store.delete(id: records[index].id)
        }
        reload()
    }

    private func iconName(for status: VerificationStatus) -> String {
        switch status {
        case .pass: return "checkmark.seal.fill"
        case .fail: return "xmark.seal.fill"
        case .insufficientData: return "questionmark.circle.fill"
        }
    }

    private func color(for status: VerificationStatus) -> Color {
        switch status {
        case .pass: return .green
        case .fail: return .red
        case .insufficientData: return .orange
        }
    }

    private func statusTitle(for status: VerificationStatus) -> String {
        switch status {
        case .pass: return L("result.status.pass")
        case .fail: return L("result.status.fail")
        case .insufficientData: return L("result.status.insufficientData")
        }
    }
}
