import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageStore: LanguageStore
    @StateObject private var theme = AppTheme.shared
    @StateObject private var settings = SettingsStore()

    private var language: AppLanguage { languageStore.selectedLanguage ?? .en }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(language.localized("tab.home"), systemImage: "house.fill").accessibilityIdentifier("tab.home") }

            GoldenLabelsListView()
                .tabItem { Label(language.localized("tab.goldenLabels"), systemImage: "checkmark.seal.fill").accessibilityIdentifier("tab.goldenLabels") }

            HistoryView()
                .tabItem { Label(language.localized("tab.history"), systemImage: "clock.fill").accessibilityIdentifier("tab.history") }

            SettingsView()
                .tabItem { Label(language.localized("tab.settings"), systemImage: "gearshape.fill").accessibilityIdentifier("tab.settings") }
        }
        .environmentObject(settings)
        .appThemeRoot(theme)
        .onAppear {
            theme.appearance = settings.appearance
            theme.accent = settings.accent.color
        }
        .onChange(of: settings.appearance) { _, newValue in theme.appearance = newValue }
        .onChange(of: settings.accent) { _, newValue in theme.accent = newValue.color }
    }
}
