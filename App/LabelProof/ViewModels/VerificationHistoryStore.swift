import Foundation
import SwiftData
import LabelProofCore

@MainActor
final class VerificationHistoryStore: ObservableObject {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [VerificationRecord] {
        let descriptor = FetchDescriptor<VerificationHistoryRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.compactMap(\.asDomainModel)
    }

    func append(_ record: VerificationRecord) {
        context.insert(VerificationHistoryRecord(record: record))
        try? context.save()
    }

    func delete(id: UUID) {
        let descriptor = FetchDescriptor<VerificationHistoryRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try? context.fetch(descriptor).first else { return }
        context.delete(record)
        try? context.save()
    }

    /// Requires explicit confirmation at the call site (Settings UI) before
    /// invoking — this is a destructive, irreversible action.
    func clearAll() {
        try? context.delete(model: VerificationHistoryRecord.self)
        try? context.save()
    }

    func seedDemoDataIfEmpty() {
        guard fetchAll().isEmpty else { return }
        for record in DemoData.seedVerificationRecords() {
            append(record)
        }
    }
}
