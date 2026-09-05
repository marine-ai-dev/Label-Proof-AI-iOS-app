import XCTest
@testable import LabelProofCore

final class ExtractedLabelDataTests: XCTestCase {
    func testBarcodesAreDeduplicatedByPayloadAndSymbology() {
        let data = ExtractedLabelData(
            rawTextLines: [],
            barcodes: [
                BarcodeObservation(payload: "123", symbology: "ean13"),
                BarcodeObservation(payload: "123", symbology: "ean13"),
                BarcodeObservation(payload: "123", symbology: "qr")
            ],
            source: .fixture
        )
        XCTAssertEqual(data.barcodes.count, 2)
    }

    func testIsEmptyRecognitionTrueWhenNoTextAndNoBarcodes() {
        let empty = ExtractedLabelData(rawTextLines: ["   ", ""], barcodes: [], source: .fixture)
        XCTAssertTrue(empty.isEmptyRecognition)

        let withBarcodeOnly = ExtractedLabelData(
            rawTextLines: [],
            barcodes: [BarcodeObservation(payload: "1", symbology: "qr")],
            source: .fixture
        )
        XCTAssertFalse(withBarcodeOnly.isEmptyRecognition)
    }
}

final class FixtureScanServiceTests: XCTestCase {
    func testFixtureLabelScanServiceIgnoresInputAndReturnsCannedResult() async throws {
        let goldenLabel = GoldenLabel(name: "n", expectedProductName: "P", expectedWeight: "1 g", expectedBarcode: "1")
        let service = FixtureLabelScanService(scenario: .fullMatch, goldenLabel: goldenLabel)
        let result = try await service.scan(imageData: Data(), source: .fixture)
        XCTAssertEqual(result.rawTextLines.first, "P")
    }
}
