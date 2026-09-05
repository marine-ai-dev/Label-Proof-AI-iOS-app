import Foundation
import SwiftData
import LabelProofCore

/// SwiftData-persisted counterpart of `LabelProofCore.VerificationRecord`.
/// The `ValidationResult`/mismatch payload is stored as encoded JSON in a
/// single column: it's a small, immutable value type with no need for
/// separate queryable columns, and this keeps the schema simple and compact
/// (no images are ever stored here, by design — see docs/PRIVACY.md).
@Model
final class VerificationHistoryRecord {
    @Attribute(.unique) var id: UUID
    var goldenLabelID: UUID
    var goldenLabelNameSnapshot: String
    var statusRawValue: String
    var scanSourceRawValue: String
    var createdAt: Date
    var resultJSON: Data

    init(record: VerificationRecord) {
        self.id = record.id
        self.goldenLabelID = record.goldenLabelID
        self.goldenLabelNameSnapshot = record.goldenLabelNameSnapshot
        self.statusRawValue = record.result.status.rawValue
        self.scanSourceRawValue = record.scanSource.rawValue
        self.createdAt = record.createdAt
        self.resultJSON = (try? JSONEncoder().encode(record.result)) ?? Data()
    }

    var asDomainModel: VerificationRecord? {
        guard let result = try? JSONDecoder().decode(ValidationResult.self, from: resultJSON),
              let scanSource = ScanSourceType(rawValue: scanSourceRawValue) else { return nil }
        return VerificationRecord(
            id: id,
            goldenLabelID: goldenLabelID,
            goldenLabelNameSnapshot: goldenLabelNameSnapshot,
            result: result,
            scanSource: scanSource,
            createdAt: createdAt
        )
    }
}
