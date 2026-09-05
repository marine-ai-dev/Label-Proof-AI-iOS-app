import Foundation

/// Where a scan's raw observations came from.
public enum ScanSourceType: String, Codable, Sendable, CaseIterable {
    case liveCamera
    case importedImage
    case fixture // deterministic test/UI-test fixture injection
}

/// A single decoded barcode/QR observation.
public struct BarcodeObservation: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    /// The decoded payload string, exactly as reported by the barcode reader.
    public var payload: String
    /// The symbology name (e.g. "ean13", "qr", "code128"). Stored as a plain string
    /// so this type has zero dependency on Vision's `VNBarcodeSymbology`.
    public var symbology: String

    public init(id: UUID = UUID(), payload: String, symbology: String) {
        self.id = id
        self.payload = payload
        self.symbology = symbology
    }
}

/// The normalized result of scanning one physical label: OCR text plus any
/// decoded barcodes. This is the single boundary type that separates
/// Vision/VisionKit-specific code from the deterministic validation engine.
public struct ExtractedLabelData: Codable, Equatable, Sendable {
    /// Raw text lines as reported by the OCR engine, top-to-bottom / reading order,
    /// unmodified (aside from what the OCR engine itself returns).
    public var rawTextLines: [String]
    /// Deduplicated barcode observations. Deduplication is by (payload, symbology).
    public var barcodes: [BarcodeObservation]
    public var source: ScanSourceType
    public var timestamp: Date

    public init(
        rawTextLines: [String],
        barcodes: [BarcodeObservation],
        source: ScanSourceType,
        timestamp: Date = Date()
    ) {
        self.rawTextLines = rawTextLines
        self.barcodes = Self.deduplicate(barcodes)
        self.source = source
        self.timestamp = timestamp
    }

    /// Single joined-and-normalized text blob used by the validator for
    /// substring/phrase search. Whitespace is collapsed and case is folded.
    public var normalizedFullText: String {
        TextNormalizer.normalize(rawTextLines.joined(separator: "\n"))
    }

    /// True when the scan produced essentially nothing usable — no text and
    /// no barcodes — which the validator must treat as "insufficient data"
    /// rather than as a mismatch.
    public var isEmptyRecognition: Bool {
        let hasText = rawTextLines.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !hasText && barcodes.isEmpty
    }

    public static func deduplicate(_ barcodes: [BarcodeObservation]) -> [BarcodeObservation] {
        var seen = Set<String>()
        var result: [BarcodeObservation] = []
        for barcode in barcodes {
            let key = "\(barcode.symbology)|\(barcode.payload)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(barcode)
            }
        }
        return result
    }
}
