import Foundation

/// A compact, persisted record of one verification event, for local history.
/// By design this never stores the captured image — only the extracted text/
/// barcode data and the validation outcome — to minimize on-device storage
/// and avoid any incidental sensitive-data retention.
public struct VerificationRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var goldenLabelID: UUID
    public var goldenLabelNameSnapshot: String
    public var result: ValidationResult
    public var scanSource: ScanSourceType
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        goldenLabelID: UUID,
        goldenLabelNameSnapshot: String,
        result: ValidationResult,
        scanSource: ScanSourceType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goldenLabelID = goldenLabelID
        self.goldenLabelNameSnapshot = goldenLabelNameSnapshot
        self.result = result
        self.scanSource = scanSource
        self.createdAt = createdAt
    }
}
