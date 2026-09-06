import Foundation

extension AppLanguage {
    /// Explicitly resolves `key` against THIS language's `.lproj` bundle,
    /// bypassing SwiftUI's `Text(LocalizedStringKey)`/`String(localized:)`
    /// magic entirely.
    ///
    /// Needed only for `.tabItem` labels: `TabView` bridges its tab titles
    /// to a native `UITabBarItem`, which does not participate in SwiftUI's
    /// environment at all — it keeps showing the string resolved against
    /// the *system* language regardless of `.environment(\.locale, ...)`
    /// set anywhere in the view tree above it.
    func localized(_ key: String) -> String {
        guard let bundle = lprojBundle else { return key }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    var lprojBundle: Bundle? {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }
}

/// `String(localized: "key")` (as opposed to SwiftUI's `Text("key")`)
/// resolves via `Bundle.main`/`Locale.current` — i.e. the device's *system*
/// language — completely independent of any SwiftUI `.environment(\.locale,
/// ...)` set anywhere in the view tree, and (verified empirically) is NOT
/// fixed by overriding `Bundle.main`'s class either: modern
/// `String(localized:)` does not route through the overridable
/// `Bundle.localizedString(forKey:value:table:)` at all on this SDK.
///
/// `L(_:)` is the drop-in replacement used at every call site throughout
/// the app that needs an already-resolved `String` (navigationTitle,
/// confirmationDialog, Section/Picker/Toggle/Button labels, etc.) instead
/// of a lazy `Text`: it explicitly passes the current `LanguageStore`
/// selection's own bundle to `String(localized:bundle:)`, which — unlike
/// the implicit-bundle form — is documented to honor whatever bundle is
/// passed regardless of system language or `Bundle.main`'s state.
@MainActor
func L(_ value: String.LocalizationValue) -> String {
    guard let bundle = LanguageStore.currentLanguageBundle else {
        return String(localized: value)
    }
    return String(localized: value, bundle: bundle)
}
