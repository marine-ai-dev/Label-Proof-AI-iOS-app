import Foundation

/// Named deterministic scan fixtures used by unit tests, UI tests (via
/// launch-argument injection), and the in-app "demo data" seeding — never a
/// visible fake-scan button in production UI. See
/// `docs/ARCHITECTURE.md` for how launch-environment flags route to these.
public enum ScanFixtureScenario: String, CaseIterable, Codable, Sendable {
    case fullMatch
    case wrongProductName
    case wrongWeight
    case wrongBarcode
    case missingRequiredPhrase
    case multipleMismatches
    case emptyRecognition

    /// Produces the fixture `ExtractedLabelData` for this scenario, relative
    /// to a given golden label (so the "full match" scenario, for example,
    /// always matches whatever golden label it's tested against).
    public func extractedLabelData(for goldenLabel: GoldenLabel) -> ExtractedLabelData {
        switch self {
        case .fullMatch:
            var lines = [goldenLabel.expectedProductName, goldenLabel.expectedWeight]
            lines.append(contentsOf: goldenLabel.requiredPhrases)
            let barcodes = goldenLabel.expectedBarcode.isEmpty ? [] : [
                BarcodeObservation(payload: goldenLabel.expectedBarcode, symbology: "ean13")
            ]
            return ExtractedLabelData(rawTextLines: lines, barcodes: barcodes, source: .fixture)

        case .wrongProductName:
            var lines = ["Definitely Different Product", goldenLabel.expectedWeight]
            lines.append(contentsOf: goldenLabel.requiredPhrases)
            let barcodes = goldenLabel.expectedBarcode.isEmpty ? [] : [
                BarcodeObservation(payload: goldenLabel.expectedBarcode, symbology: "ean13")
            ]
            return ExtractedLabelData(rawTextLines: lines, barcodes: barcodes, source: .fixture)

        case .wrongWeight:
            var lines = [goldenLabel.expectedProductName, "999 g"]
            lines.append(contentsOf: goldenLabel.requiredPhrases)
            let barcodes = goldenLabel.expectedBarcode.isEmpty ? [] : [
                BarcodeObservation(payload: goldenLabel.expectedBarcode, symbology: "ean13")
            ]
            return ExtractedLabelData(rawTextLines: lines, barcodes: barcodes, source: .fixture)

        case .wrongBarcode:
            var lines = [goldenLabel.expectedProductName, goldenLabel.expectedWeight]
            lines.append(contentsOf: goldenLabel.requiredPhrases)
            let barcodes = [BarcodeObservation(payload: "000000000000", symbology: "ean13")]
            return ExtractedLabelData(rawTextLines: lines, barcodes: barcodes, source: .fixture)

        case .missingRequiredPhrase:
            var lines = [goldenLabel.expectedProductName, goldenLabel.expectedWeight]
            lines.append(contentsOf: goldenLabel.requiredPhrases.dropLast())
            let barcodes = goldenLabel.expectedBarcode.isEmpty ? [] : [
                BarcodeObservation(payload: goldenLabel.expectedBarcode, symbology: "ean13")
            ]
            return ExtractedLabelData(rawTextLines: lines, barcodes: barcodes, source: .fixture)

        case .multipleMismatches:
            let barcodes = [BarcodeObservation(payload: "111111111111", symbology: "ean13")]
            return ExtractedLabelData(
                rawTextLines: ["Wrong Product Entirely", "1 g"],
                barcodes: barcodes,
                source: .fixture
            )

        case .emptyRecognition:
            return ExtractedLabelData(rawTextLines: [], barcodes: [], source: .fixture)
        }
    }
}

/// Deterministic `OCRServicing` fixture. Never used in production code paths —
/// only injected by tests/UI-tests via launch-environment flags, or by the
/// app's own "reset to demo data" settings action (still writing real
/// `ExtractedLabelData`/`ValidationResult` through the exact same validation
/// engine, no UI shortcuts).
public struct FixtureOCRService: OCRServicing {
    private let lines: [String]
    public init(lines: [String]) { self.lines = lines }
    public func recognizeText(imageData: Data) async throws -> [String] { lines }
}

/// Deterministic `BarcodeServicing` fixture. See `FixtureOCRService`.
public struct FixtureBarcodeService: BarcodeServicing {
    private let barcodes: [BarcodeObservation]
    public init(barcodes: [BarcodeObservation]) { self.barcodes = barcodes }
    public func recognizeBarcodes(imageData: Data) async throws -> [BarcodeObservation] { barcodes }
}

/// Deterministic `LabelScanServicing` fixture that ignores the input image
/// bytes entirely and returns a canned `ExtractedLabelData` — used for both
/// unit tests and XCUITest launch-argument injection.
public struct FixtureLabelScanService: LabelScanServicing {
    private let result: ExtractedLabelData
    public init(result: ExtractedLabelData) { self.result = result }
    public init(scenario: ScanFixtureScenario, goldenLabel: GoldenLabel) {
        self.result = scenario.extractedLabelData(for: goldenLabel)
    }
    public func scan(imageData: Data, source: ScanSourceType) async throws -> ExtractedLabelData { result }
}
