import Foundation
import SwiftData
import LabelProofCore

/// SwiftData-persisted counterpart of `LabelProofCore.GoldenLabel`.
///
/// Kept as a separate `@Model` type (rather than making the Core struct a
/// SwiftData model directly) so `LabelProofCore` stays a plain Foundation
/// package with zero SwiftData/UIKit dependency, per the architecture
/// decision in docs/ARCHITECTURE.md. Conversion helpers below map 1:1.
@Model
final class GoldenLabelRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var expectedProductName: String
    var expectedWeight: String
    var expectedBarcode: String
    var requiredPhrases: [String]
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        expectedProductName: String,
        expectedWeight: String,
        expectedBarcode: String,
        requiredPhrases: [String] = [],
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.expectedProductName = expectedProductName
        self.expectedWeight = expectedWeight
        self.expectedBarcode = expectedBarcode
        self.requiredPhrases = requiredPhrases
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var asDomainModel: GoldenLabel {
        GoldenLabel(
            id: id,
            name: name,
            expectedProductName: expectedProductName,
            expectedWeight: expectedWeight,
            expectedBarcode: expectedBarcode,
            requiredPhrases: requiredPhrases,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from domain: GoldenLabel) {
        name = domain.name
        expectedProductName = domain.expectedProductName
        expectedWeight = domain.expectedWeight
        expectedBarcode = domain.expectedBarcode
        requiredPhrases = domain.requiredPhrases
        notes = domain.notes
        updatedAt = Date()
    }
}

extension GoldenLabel {
    init(record: GoldenLabelRecord) {
        self = record.asDomainModel
    }
}
