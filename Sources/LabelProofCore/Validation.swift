import Foundation

/// The overall outcome of verifying a scan against a golden label.
///
/// `insufficientData` is explicitly distinct from `fail`: it means the scan
/// itself did not produce usable recognition (no text, no barcode), as
/// opposed to `fail`, which means recognition succeeded but one or more
/// fields did not match the golden label.
public enum VerificationStatus: String, Codable, Sendable {
    case pass
    case fail
    case insufficientData
}

/// Which field a validation rule concerns.
public enum LabelField: String, Codable, Sendable {
    case productName
    case weight
    case barcode
    case requiredPhrase
}

/// Why a single rule failed, as a structured, localizable-key-friendly reason.
public enum MismatchReason: String, Codable, Sendable {
    case textNotFound
    case valueMismatch
    case barcodeNotFound
    case barcodeMismatch
    case phraseMissing
    case noRecognitionData
}

/// A single field-level mismatch between the scan and the golden label.
public struct LabelMismatch: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var field: LabelField
    /// Human-readable expected value (already the "golden" source of truth).
    public var expected: String
    /// What was actually found on the scan, or empty string if nothing was found.
    public var actual: String
    public var reason: MismatchReason
    /// Only set for `.requiredPhrase` mismatches, to identify which phrase failed.
    public var phraseIndex: Int?

    public init(
        id: UUID = UUID(),
        field: LabelField,
        expected: String,
        actual: String,
        reason: MismatchReason,
        phraseIndex: Int? = nil
    ) {
        self.id = id
        self.field = field
        self.expected = expected
        self.actual = actual
        self.reason = reason
        self.phraseIndex = phraseIndex
    }
}

/// The result of a single validation rule (used internally and exposed for
/// detailed reporting/testing of individual rules, independent of the
/// aggregate `ValidationResult`).
public struct ValidationRuleResult: Codable, Equatable, Sendable {
    public var field: LabelField
    public var passed: Bool
    public var mismatch: LabelMismatch?

    public init(field: LabelField, passed: Bool, mismatch: LabelMismatch? = nil) {
        self.field = field
        self.passed = passed
        self.mismatch = mismatch
    }
}

/// The full result of verifying one `ExtractedLabelData` scan against one
/// `GoldenLabel`.
public struct ValidationResult: Codable, Equatable, Sendable {
    public var status: VerificationStatus
    public var goldenLabelID: UUID
    public var ruleResults: [ValidationRuleResult]
    public var mismatches: [LabelMismatch]
    public var evaluatedAt: Date

    public init(
        status: VerificationStatus,
        goldenLabelID: UUID,
        ruleResults: [ValidationRuleResult],
        mismatches: [LabelMismatch],
        evaluatedAt: Date = Date()
    ) {
        self.status = status
        self.goldenLabelID = goldenLabelID
        self.ruleResults = ruleResults
        self.mismatches = mismatches
        self.evaluatedAt = evaluatedAt
    }
}

/// Deterministic, rule-based validation engine. No fuzzy matching, no ML,
/// no network calls — every rule is a pure function of its inputs.
public enum LabelValidator {
    /// Validates `scan` against `goldenLabel`.
    ///
    /// - If the scan has no usable recognition data at all (`isEmptyRecognition`),
    ///   the result status is `.insufficientData` and a single mismatch with
    ///   reason `.noRecognitionData` is reported per checked field so callers
    ///   can still see what was expected.
    /// - Otherwise every rule (product name, weight, barcode, each required
    ///   phrase) is evaluated independently; `.pass` requires all rules to pass.
    public static func validate(scan: ExtractedLabelData, against goldenLabel: GoldenLabel) -> ValidationResult {
        if scan.isEmptyRecognition {
            let mismatches = insufficientDataMismatches(for: goldenLabel)
            let ruleResults = mismatches.map { ValidationRuleResult(field: $0.field, passed: false, mismatch: $0) }
            return ValidationResult(
                status: .insufficientData,
                goldenLabelID: goldenLabel.id,
                ruleResults: ruleResults,
                mismatches: mismatches
            )
        }

        var ruleResults: [ValidationRuleResult] = []

        ruleResults.append(validateProductName(scan: scan, goldenLabel: goldenLabel))
        ruleResults.append(validateWeight(scan: scan, goldenLabel: goldenLabel))
        ruleResults.append(validateBarcode(scan: scan, goldenLabel: goldenLabel))
        ruleResults.append(contentsOf: validateRequiredPhrases(scan: scan, goldenLabel: goldenLabel))

        let mismatches = ruleResults.compactMap(\.mismatch)
        let status: VerificationStatus = mismatches.isEmpty ? .pass : .fail

        return ValidationResult(
            status: status,
            goldenLabelID: goldenLabel.id,
            ruleResults: ruleResults,
            mismatches: mismatches
        )
    }

    // MARK: - Individual rules

    static func validateProductName(scan: ExtractedLabelData, goldenLabel: GoldenLabel) -> ValidationRuleResult {
        let expected = TextNormalizer.normalize(goldenLabel.expectedProductName)
        let haystack = scan.normalizedFullText
        if expected.isEmpty || haystack.contains(expected) {
            return ValidationRuleResult(field: .productName, passed: true)
        }
        let mismatch = LabelMismatch(
            field: .productName,
            expected: goldenLabel.expectedProductName,
            actual: scan.rawTextLines.joined(separator: " "),
            reason: .textNotFound
        )
        return ValidationRuleResult(field: .productName, passed: false, mismatch: mismatch)
    }

    static func validateWeight(scan: ExtractedLabelData, goldenLabel: GoldenLabel) -> ValidationRuleResult {
        guard !goldenLabel.expectedWeight.trimmingCharacters(in: .whitespaces).isEmpty else {
            return ValidationRuleResult(field: .weight, passed: true)
        }
        let expected = TextNormalizer.normalizeWeight(goldenLabel.expectedWeight)
        // Compare whole tokens, not a raw substring search: a blind
        // `.contains` on the joined scan text would let expected "50g"
        // spuriously match inside an unrelated "150g"/"250g" elsewhere on
        // the scan, producing a false PASS. Instead build the set of
        // candidate weight tokens from the scan: each individual word, plus
        // each adjacent word pair merged the same way `normalizeWeight`
        // merges "500 g" -> "500g" (OCR often reports the numeric value and
        // unit as separate words), and require an exact match against one
        // of those candidates.
        let words = scan.rawTextLines.joined(separator: " ").split(separator: " ").map(String.init)
        var candidates = words.map { TextNormalizer.normalizeWeight($0) }
        for index in 0..<max(words.count - 1, 0) {
            candidates.append(TextNormalizer.normalizeWeight(words[index] + " " + words[index + 1]))
        }
        if candidates.contains(expected) {
            return ValidationRuleResult(field: .weight, passed: true)
        }
        let mismatch = LabelMismatch(
            field: .weight,
            expected: goldenLabel.expectedWeight,
            actual: scan.rawTextLines.joined(separator: " "),
            reason: .valueMismatch
        )
        return ValidationRuleResult(field: .weight, passed: false, mismatch: mismatch)
    }

    static func validateBarcode(scan: ExtractedLabelData, goldenLabel: GoldenLabel) -> ValidationRuleResult {
        guard !goldenLabel.expectedBarcode.trimmingCharacters(in: .whitespaces).isEmpty else {
            return ValidationRuleResult(field: .barcode, passed: true)
        }
        let expected = TextNormalizer.normalizeBarcode(goldenLabel.expectedBarcode)

        if scan.barcodes.isEmpty {
            let mismatch = LabelMismatch(
                field: .barcode,
                expected: goldenLabel.expectedBarcode,
                actual: "",
                reason: .barcodeNotFound
            )
            return ValidationRuleResult(field: .barcode, passed: false, mismatch: mismatch)
        }

        // Barcode matching is EXACT only, never fuzzy: the normalized payload
        // must equal the expected value exactly (whitespace-trimmed).
        let matchFound = scan.barcodes.contains { TextNormalizer.normalizeBarcode($0.payload) == expected }
        if matchFound {
            return ValidationRuleResult(field: .barcode, passed: true)
        }

        let actual = scan.barcodes.map(\.payload).joined(separator: ", ")
        let mismatch = LabelMismatch(
            field: .barcode,
            expected: goldenLabel.expectedBarcode,
            actual: actual,
            reason: .barcodeMismatch
        )
        return ValidationRuleResult(field: .barcode, passed: false, mismatch: mismatch)
    }

    static func validateRequiredPhrases(scan: ExtractedLabelData, goldenLabel: GoldenLabel) -> [ValidationRuleResult] {
        let haystack = scan.normalizedFullText
        return goldenLabel.requiredPhrases.enumerated().map { index, phrase in
            let normalizedPhrase = TextNormalizer.normalize(phrase)
            if normalizedPhrase.isEmpty || haystack.contains(normalizedPhrase) {
                return ValidationRuleResult(field: .requiredPhrase, passed: true)
            }
            let mismatch = LabelMismatch(
                field: .requiredPhrase,
                expected: phrase,
                actual: "",
                reason: .phraseMissing,
                phraseIndex: index
            )
            return ValidationRuleResult(field: .requiredPhrase, passed: false, mismatch: mismatch)
        }
    }

    private static func insufficientDataMismatches(for goldenLabel: GoldenLabel) -> [LabelMismatch] {
        var mismatches: [LabelMismatch] = [
            LabelMismatch(field: .productName, expected: goldenLabel.expectedProductName, actual: "", reason: .noRecognitionData)
        ]
        if !goldenLabel.expectedWeight.trimmingCharacters(in: .whitespaces).isEmpty {
            mismatches.append(LabelMismatch(field: .weight, expected: goldenLabel.expectedWeight, actual: "", reason: .noRecognitionData))
        }
        if !goldenLabel.expectedBarcode.trimmingCharacters(in: .whitespaces).isEmpty {
            mismatches.append(LabelMismatch(field: .barcode, expected: goldenLabel.expectedBarcode, actual: "", reason: .noRecognitionData))
        }
        for (index, phrase) in goldenLabel.requiredPhrases.enumerated() {
            mismatches.append(LabelMismatch(field: .requiredPhrase, expected: phrase, actual: "", reason: .noRecognitionData, phraseIndex: index))
        }
        return mismatches
    }
}
