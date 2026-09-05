import Foundation

/// Errors a scan service implementation may surface. Kept generic/Foundation-only
/// so this file has no dependency on Vision/VisionKit.
public enum ScanServiceError: Error, Equatable, Sendable {
    case unavailable
    case permissionDenied
    case cancelled
    case underlying(String)
}

/// Abstraction over Apple Vision text recognition (`VNRecognizeTextRequest`).
/// The concrete implementation lives in the app target behind
/// `#if canImport(Vision)`; this protocol lets the validation/UI layers and
/// tests depend only on this Foundation-only interface.
public protocol OCRServicing: Sendable {
    /// Performs OCR over already-loaded image data (e.g. JPEG/PNG bytes) and
    /// returns recognized text lines in reading order.
    func recognizeText(imageData: Data) async throws -> [String]
}

/// Abstraction over Apple Vision/VisionKit barcode recognition.
public protocol BarcodeServicing: Sendable {
    /// Performs barcode detection over already-loaded image data and returns
    /// deduplicated observations.
    func recognizeBarcodes(imageData: Data) async throws -> [BarcodeObservation]
}

/// Combines OCR + barcode recognition into one `ExtractedLabelData` scan,
/// used by both the live camera pipeline and the image-import pipeline.
public protocol LabelScanServicing: Sendable {
    func scan(imageData: Data, source: ScanSourceType) async throws -> ExtractedLabelData
}

/// Default composition of an `OCRServicing` + `BarcodeServicing` pair into a
/// `LabelScanServicing`. Concrete production instances are assembled in the
/// app target with real Vision-backed services; tests/UI-tests assemble this
/// with `FixtureOCRService`/`FixtureBarcodeService` for determinism.
public struct CompositeLabelScanService: LabelScanServicing {
    private let ocrService: OCRServicing
    private let barcodeService: BarcodeServicing

    public init(ocrService: OCRServicing, barcodeService: BarcodeServicing) {
        self.ocrService = ocrService
        self.barcodeService = barcodeService
    }

    public func scan(imageData: Data, source: ScanSourceType) async throws -> ExtractedLabelData {
        async let text = ocrService.recognizeText(imageData: imageData)
        async let barcodes = barcodeService.recognizeBarcodes(imageData: imageData)
        return try await ExtractedLabelData(
            rawTextLines: text,
            barcodes: barcodes,
            source: source
        )
    }
}
