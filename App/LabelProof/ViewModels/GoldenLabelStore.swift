import Foundation
import SwiftData
import LabelProofCore

/// Thin SwiftData-backed CRUD wrapper around `GoldenLabelRecord`, exposing
/// the platform-agnostic `GoldenLabel` domain type to views/view models.
@MainActor
final class GoldenLabelStore: ObservableObject {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [GoldenLabel] {
        let descriptor = FetchDescriptor<GoldenLabelRecord>(sortBy: [SortDescriptor(\.name)])
        let records = (try? context.fetch(descriptor)) ?? []
        return records.map(\.asDomainModel)
    }

    func create(_ goldenLabel: GoldenLabel) {
        let record = GoldenLabelRecord(
            id: goldenLabel.id,
            name: goldenLabel.name,
            expectedProductName: goldenLabel.expectedProductName,
            expectedWeight: goldenLabel.expectedWeight,
            expectedBarcode: goldenLabel.expectedBarcode,
            requiredPhrases: goldenLabel.requiredPhrases,
            notes: goldenLabel.notes
        )
        context.insert(record)
        try? context.save()
    }

    func update(_ goldenLabel: GoldenLabel) {
        let targetID = goldenLabel.id
        let descriptor = FetchDescriptor<GoldenLabelRecord>(predicate: #Predicate { $0.id == targetID })
        guard let record = try? context.fetch(descriptor).first else { return }
        record.update(from: goldenLabel)
        try? context.save()
    }

    func delete(id: UUID) {
        let descriptor = FetchDescriptor<GoldenLabelRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try? context.fetch(descriptor).first else { return }
        context.delete(record)
        try? context.save()
    }

    func seedDemoDataIfEmpty() {
        guard fetchAll().isEmpty else { return }
        for goldenLabel in DemoData.goldenLabels {
            create(goldenLabel)
        }
    }
}
