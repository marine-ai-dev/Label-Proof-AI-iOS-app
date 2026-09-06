import Foundation

/// LabelProof 1.0 supports exactly these two interface languages. Adding a
/// language means adding a case here plus its `.lproj` directory — nothing
/// else in the language-selection UI branches by language name.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case uk
    case en

    var id: String { rawValue }

    /// Best-effort match from the device's preferred system language,
    /// falling back to English for anything unsupported — used only to
    /// preselect/recommend an option on the first-launch screen; the user
    /// still makes an explicit choice.
    static func systemRecommended() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            let code = Locale(identifier: preferred).language.languageCode?.identifier ?? preferred
            if code.hasPrefix("uk") { return .uk }
            if code.hasPrefix("en") { return .en }
        }
        return .en
    }

    var displayName: String {
        switch self {
        case .uk: return "Українська"
        case .en: return "English"
        }
    }

    /// Decorative-only glyph — VoiceOver announces `displayName`, never
    /// this symbol alone (see `LanguageSelectionView`).
    var symbol: String {
        switch self {
        case .uk: return "🇺🇦"
        case .en: return "🌐"
        }
    }

    /// The `Locale` SwiftUI's `Text(LocalizedStringKey)` resolution should
    /// use — this is what actually makes runtime language switching work:
    /// `Text` picks which of the app's own bundled `.lproj` localizations
    /// to resolve a key against based on the `\.locale` environment value,
    /// independent of the device's system language.
    var locale: Locale { Locale(identifier: rawValue) }
}
