import SwiftUI
import SwiftData

@main
struct LabelProofApp: App {
    let modelContainer: ModelContainer

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
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
