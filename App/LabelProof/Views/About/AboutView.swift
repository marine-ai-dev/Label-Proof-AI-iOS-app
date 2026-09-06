import SwiftUI

struct AboutView: View {
    // See HomeView's comment on this same property.
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                GlassCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("about.appName").font(.title2.bold())
                        Text("about.tagline").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                sectionCard(titleKey: "about.privacyTitle", bodyKey: "about.privacyBody")
                sectionCard(titleKey: "about.howItWorksTitle", bodyKey: "about.howItWorksBody")
                sectionCard(titleKey: "about.limitationsTitle", bodyKey: "about.limitationsBody")
                sectionCard(titleKey: "about.deletionWarningTitle", bodyKey: "about.deletionWarningBody")
                sectionCard(titleKey: "about.openSourceTitle", bodyKey: "about.openSourceBody")
            }
            .padding()
        }
        .navigationTitle(L("about.title"))
        .accessibilityIdentifier("about.screen")
    }

    private func sectionCard(titleKey: String.LocalizationValue, bodyKey: String.LocalizationValue) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(L(titleKey)).font(.headline)
                Text(L(bodyKey)).font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
