import Foundation

/// A "golden" reference label that a scanned package is verified against.
///
/// `GoldenLabel` is pure Foundation and platform-agnostic so it can be used
/// both in the SwiftData-backed app layer (see `App/LabelProof/Models`) and
/// tested here with `swift test` without any Apple UI/Vision frameworks.
public struct GoldenLabel: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    /// Short human-readable name for this golden label definition (e.g. "Acme Oats 500g").
    public var name: String
    /// The exact product name expected to be printed on the package.
    public var expectedProductName: String
    /// The expected weight/quantity string as printed, e.g. "500 g" or "12 fl oz".
    public var expectedWeight: String
    /// The expected barcode payload (numeric or alphanumeric depending on symbology).
    public var expectedBarcode: String
    /// Phrases that must all appear somewhere on the label (e.g. allergen statements,
    /// certification marks, country of origin).
    public var requiredPhrases: [String]
    /// Free-form notes for the person maintaining this golden label.
    public var notes: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
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
}
