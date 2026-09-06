import SwiftUI
import SwiftData

@main
struct LabelProofApp: App {
    let modelContainer: ModelContainer
    @StateObject private var languageStore = LanguageStore()

    init() {
        do {
            modelContainer = try ModelContainer(for: GoldenLabelRecord.self, VerificationHistoryRecord.self)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
        LaunchEnvironment.applyIfNeeded(to: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            // RootTabView applies the live, observed accent tint itself via
            // `.appThemeRoot(theme)` — do not also apply a static tint here.
            // A second, non-reactive `.tint(AppTheme.shared.accent)` at this
            // level previously caused some system-rendered chrome (Picker
            // disclosure values/chevrons) to keep showing the default accent
            // after the user changed it in Settings, since it froze that
            // outer tint at launch time instead of observing `SettingsStore`.
            Group {
                if languageStore.hasChosenLanguage {
                    RootTabView()
                } else {
                    LanguageSelectionView()
                }
            }
            .environmentObject(languageStore)
            .environment(\.locale, (languageStore.selectedLanguage ?? .systemRecommended()).locale)
            .animation(.default, value: languageStore.hasChosenLanguage)
            // No `.id(languageStore.selectedLanguage)` here: that would
            // force the whole TabView (and its NavigationStacks) to be
            // torn down and recreated on every language change, resetting
            // tab selection back to Home and losing any pushed navigation
            // state. It isn't needed — `Text("key")` follows
            // `.environment(\.locale, ...)` above, `String(localized:)`
            // call sites use `L(_:)` (explicit bundle, re-evaluated on
            // every body re-render `languageStore` triggers), and
            // `.tabItem` labels use `AppLanguage.localized(_:)` in
            // `RootTabView` (also explicit-bundle) — none of the three
            // need a full view-identity reset to pick up a language
            // change.
        }
        .modelContainer(modelContainer)
    }
}
