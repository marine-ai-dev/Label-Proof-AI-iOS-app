import SwiftUI

struct AboutView: View {
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
                sectionCard(titleKey: "about.openSourceTitle", bodyKey: "about.openSourceBody")
            }
            .padding()
        }
        .navigationTitle(String(localized: "about.title"))
        .accessibilityIdentifier("about.screen")
    }

    private func sectionCard(titleKey: String.LocalizationValue, bodyKey: String.LocalizationValue) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(String(localized: titleKey)).font(.headline)
                Text(String(localized: bodyKey)).font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
