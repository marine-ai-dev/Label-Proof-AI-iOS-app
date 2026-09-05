import Foundation

/// Deterministic text normalization used throughout the validation engine.
///
/// These rules are intentionally simple and documented, never fuzzy/ML-based:
/// - `normalize`: trims, collapses internal whitespace runs to a single space,
///   and lowercases (case-insensitive comparison for names/phrases).
/// - `normalizeWeight`: additionally removes the space between a numeric value
///   and its unit so "500 g" and "500g" compare equal, without changing the
///   numeric value or unit text itself (no unit conversion is performed).
public enum TextNormalizer {
    /// Trims leading/trailing whitespace, collapses interior whitespace runs
    /// (including newlines/tabs) to a single space, and lowercases.
    public static func normalize(_ text: String) -> String {
        let collapsed = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.lowercased()
    }

    /// Normalizes a weight/quantity string for deterministic comparison.
    ///
    /// Rule: normalize whitespace and case as in `normalize`, then remove any
    /// single space that sits directly between a digit and a following letter
    /// (e.g. "500 g" -> "500g", "1.5 kg" -> "1.5kg"). No unit conversion
    /// (e.g. g <-> oz) is performed — this is spacing normalization only, as
    /// specified.
    public static func normalizeWeight(_ text: String) -> String {
        let base = normalize(text)
        var result = ""
        var previousCharacter: Character?
        var characters = Array(base)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == " ",
               let previous = previousCharacter,
               previous.isNumber,
               index + 1 < characters.count,
               characters[index + 1].isLetter {
                // Skip the space between digit and unit letter.
                index += 1
                continue
            }
            result.append(character)
            previousCharacter = character
            index += 1
        }
        return result
    }

    /// Exact-match normalization for barcode payloads: trims whitespace only.
    /// Barcodes are never fuzzy-matched, case-folded, or otherwise altered.
    public static func normalizeBarcode(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
