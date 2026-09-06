import Foundation
import Combine

/// Single source of truth for LabelProof's chosen interface language.
/// `selectedLanguage == nil` means "never chosen" — the only condition
/// under which the first-launch language screen appears (see
/// `LabelProofApp`). Runtime switching (no restart) needs three
/// mechanisms together, because different pieces of SwiftUI/UIKit resolve
/// localized strings through different paths that don't all listen to the
/// same thing:
/// - `LabelProofApp` binds `.environment(\.locale, ...)` to
///   `selectedLanguage`, which is what SwiftUI's `Text("key")` consults.
/// - `L(_:)` (see `ExplicitBundleLocalization.swift`) is used at every call
///   site that needs an already-resolved `String` rather than a lazy
///   `Text` (`.navigationTitle`, `.confirmationDialog`, `Section`/
///   `Picker`/`Toggle` labels, etc.) — plain `String(localized:)` ignores
///   the SwiftUI environment entirely and, empirically, isn't fixed by a
///   `Bundle.main` class-swizzle either (verified not to work on this SDK),
///   so those call sites instead explicitly pass `currentLanguageBundle`.
/// - `.tabItem` labels need a third, separate fix (`AppLanguage.localized`
///   in `RootTabView`), since `TabView` bridges them to a native
///   `UITabBarItem` that doesn't consult either of the above.
@MainActor
final class LanguageStore: ObservableObject {
    private enum Keys {
        static let selectedLanguage = "settings.selectedLanguage"
    }

    /// Read by the free function `L(_:)` so any call site can resolve
    /// against the current language without needing a reference to this
    /// object. Kept in sync by `selectedLanguage`'s `didSet` and by `init`.
    static var currentLanguageBundle: Bundle?

    @Published var selectedLanguage: AppLanguage? {
        didSet {
            if let selectedLanguage {
                UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.selectedLanguage)
            }
            Self.currentLanguageBundle = selectedLanguage?.lprojBundle
        }
    }

    var hasChosenLanguage: Bool { selectedLanguage != nil }

    init() {
        // In UITEST_MODE, existing/older UI tests never set a language
        // launch argument at all and must keep working exactly as before
        // (English, no first-launch screen) — see LaunchEnvironment. Only
        // a test that explicitly asks to see the selector gets `nil` here.
        if LaunchEnvironment.isUITesting && !LaunchEnvironment.forceShowLanguageSelector {
            let language = LaunchEnvironment.forcedLanguage ?? .en
            selectedLanguage = language
            Self.currentLanguageBundle = language.lprojBundle
            return
        }
        if LaunchEnvironment.isUITesting && LaunchEnvironment.forceShowLanguageSelector {
            selectedLanguage = nil
            Self.currentLanguageBundle = nil
            return
        }

        if let raw = UserDefaults.standard.string(forKey: Keys.selectedLanguage), let language = AppLanguage(rawValue: raw) {
            selectedLanguage = language
            Self.currentLanguageBundle = language.lprojBundle
        } else {
            selectedLanguage = nil
            Self.currentLanguageBundle = nil
        }
    }
}
