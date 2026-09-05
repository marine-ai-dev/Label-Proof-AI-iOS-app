import XCTest
@testable import LabelProofCore

final class LabelValidatorTests: XCTestCase {
    let goldenLabel = GoldenLabel(
        name: "Test Golden Label",
        expectedProductName: "Sunrise Rolled Oats",
        expectedWeight: "500 g",
        expectedBarcode: "5901234123457",
        requiredPhrases: ["Best before end", "Packed in a facility that also handles nuts"]
    )

    func testFullMatchPasses() {
        let scan = ScanFixtureScenario.fullMatch.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .pass)
        XCTAssertTrue(result.mismatches.isEmpty)
    }

    func testWeightMatchesRegardlessOfSpacing() {
        let scan = ExtractedLabelData(
            rawTextLines: ["Sunrise Rolled Oats", "500g"],
            barcodes: [BarcodeObservation(payload: "5901234123457", symbology: "ean13")],
            source: .fixture
        )
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .fail) // required phrases missing
        XCTAssertFalse(result.mismatches.contains { $0.field == .weight })
    }

    /// Regression test: weight matching must compare whole tokens, not do a
    /// raw substring search. A golden label expecting "500 g" must NOT pass
    /// just because the scanned text contains an unrelated "1500 g" or
    /// "2500 g" elsewhere on the label — that would be a false PASS, which
    /// is strictly worse than a false FAIL for this product.
    func testWeightDoesNotFalsePositiveOnSubstringOfLargerNumber() {
        let scan = ExtractedLabelData(
            rawTextLines: ["Sunrise Rolled Oats", "Net weight 1500 g", "Serving size 2500 g"],
            barcodes: [BarcodeObservation(payload: "5901234123457", symbology: "ean13")],
            source: .fixture
        )
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertTrue(result.mismatches.contains { $0.field == .weight && $0.reason == .valueMismatch })
    }

    func testWrongProductNameFails() {
        let scan = ScanFixtureScenario.wrongProductName.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .fail)
        XCTAssertTrue(result.mismatches.contains { $0.field == .productName && $0.reason == .textNotFound })
    }

    func testWrongWeightFails() {
        let scan = ScanFixtureScenario.wrongWeight.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .fail)
        XCTAssertTrue(result.mismatches.contains { $0.field == .weight && $0.reason == .valueMismatch })
    }

    func testWrongBarcodeFailsWithExactMismatchReason() {
        let scan = ScanFixtureScenario.wrongBarcode.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .fail)
        XCTAssertTrue(result.mismatches.contains { $0.field == .barcode && $0.reason == .barcodeMismatch })
    }

    func testMissingBarcodeReportsNotFound() {
        let scan = ExtractedLabelData(
            rawTextLines: [goldenLabel.expectedProductName, goldenLabel.expectedWeight] + goldenLabel.requiredPhrases,
            barcodes: [],
            source: .fixture
        )
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertTrue(result.mismatches.contains { $0.field == .barcode && $0.reason == .barcodeNotFound })
    }

    func testMissingRequiredPhraseFails() {
        let scan = ScanFixtureScenario.missingRequiredPhrase.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .fail)
        XCTAssertTrue(result.mismatches.contains { $0.field == .requiredPhrase && $0.reason == .phraseMissing })
    }

    func testEachRequiredPhraseIsCheckedIndividually() {
        let scan = ExtractedLabelData(
            rawTextLines: [goldenLabel.expectedProductName, goldenLabel.expectedWeight, "Best before end"],
            barcodes: [BarcodeObservation(payload: goldenLabel.expectedBarcode, symbology: "ean13")],
            source: .fixture
        )
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        let phraseMismatches = result.mismatches.filter { $0.field == .requiredPhrase }
        XCTAssertEqual(phraseMismatches.count, 1)
        XCTAssertEqual(phraseMismatches.first?.phraseIndex, 1)
    }

    func testMultipleMismatchesAreAllReported() {
        let scan = ScanFixtureScenario.multipleMismatches.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .fail)
        XCTAssertGreaterThanOrEqual(result.mismatches.count, 3)
    }

    func testEmptyRecognitionIsInsufficientDataNotFail() {
        let scan = ScanFixtureScenario.emptyRecognition.extractedLabelData(for: goldenLabel)
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertEqual(result.status, .insufficientData)
        XCTAssertTrue(result.mismatches.allSatisfy { $0.reason == .noRecognitionData })
    }

    func testProductNameComparisonIsCaseAndWhitespaceInsensitive() {
        let scan = ExtractedLabelData(
            rawTextLines: ["  sunrise   rolled oats  ", goldenLabel.expectedWeight] + goldenLabel.requiredPhrases,
            barcodes: [BarcodeObservation(payload: goldenLabel.expectedBarcode, symbology: "ean13")],
            source: .fixture
        )
        let result = LabelValidator.validate(scan: scan, against: goldenLabel)
        XCTAssertFalse(result.mismatches.contains { $0.field == .productName })
    }

    func testBarcodeNeverFuzzyMatches() {
        let almostRightGoldenLabel = GoldenLabel(
            name: "x", expectedProductName: "", expectedWeight: "", expectedBarcode: "123456789012"
        )
        let scan = ExtractedLabelData(
            rawTextLines: [],
            barcodes: [BarcodeObservation(payload: "123456789013", symbology: "ean13")], // off by one digit
            source: .fixture
        )
        let result = LabelValidator.validate(scan: scan, against: almostRightGoldenLabel)
        XCTAssertEqual(result.status, .fail)
        XCTAssertTrue(result.mismatches.contains { $0.field == .barcode && $0.reason == .barcodeMismatch })
    }
}
