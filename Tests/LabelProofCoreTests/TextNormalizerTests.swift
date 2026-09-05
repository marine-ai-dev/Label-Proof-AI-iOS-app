import XCTest
@testable import LabelProofCore

final class TextNormalizerTests: XCTestCase {
    func testNormalizeCollapsesWhitespaceAndLowercases() {
        XCTAssertEqual(TextNormalizer.normalize("  Sunrise   Rolled\nOats "), "sunrise rolled oats")
    }

    func testNormalizeWeightRemovesSpaceBetweenDigitAndUnit() {
        XCTAssertEqual(TextNormalizer.normalizeWeight("500 g"), "500g")
        XCTAssertEqual(TextNormalizer.normalizeWeight("500g"), "500g")
        XCTAssertEqual(TextNormalizer.normalizeWeight("1.5 kg"), "1.5kg")
    }

    func testNormalizeWeightDoesNotConvertUnits() {
        XCTAssertNotEqual(TextNormalizer.normalizeWeight("500 g"), TextNormalizer.normalizeWeight("0.5 kg"))
    }

    func testNormalizeBarcodeOnlyTrims() {
        XCTAssertEqual(TextNormalizer.normalizeBarcode("  5901234123457 "), "5901234123457")
        // Case must NOT be folded for barcodes (exact match only).
        XCTAssertEqual(TextNormalizer.normalizeBarcode("ABC123"), "ABC123")
    }
}
