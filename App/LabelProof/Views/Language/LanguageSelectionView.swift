import SwiftUI

/// Shown two ways:
/// 1. Full-screen, on the very first launch (`selectedLanguage == nil`),
///    before anything else in the app — see `LabelProofApp`.
/// 2. As a sheet from Settings → Language, to change the choice later.
/// Language selection only: no account, no permissions, no marketing
/// carousel — by explicit product requirement.
struct LanguageSelectionView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    /// Non-nil when presented as a Settings sheet, so it can dismiss itself
    /// after a change; `nil` for the full-screen first-launch presentation,
    /// which instead just proceeds into the app once a language is set.
    var onDismiss: (() -> Void)?

    @State private var recommended: AppLanguage = .systemRecommended()

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.shared.accent)
                    .accessibilityHidden(true)

                Text("language.chooseTitle.uk")
                    .font(.title2.bold())
                Text("language.chooseTitle.en")
                    .font(.title2.bold())
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.Spacing.lg)

            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(AppLanguage.allCases) { language in
                    languageOption(language)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    private func languageOption(_ language: AppLanguage) -> some View {
        let isSelected = languageStore.selectedLanguage == language
        return Button {
            languageStore.selectedLanguage = language
            onDismiss?()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Text(language.symbol)
                    .font(.system(size: 32))
                    .accessibilityHidden(true)
                Text(language.displayName)
                    .font(.title3.weight(.semibold))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.shared.accent)
                        .accessibilityHidden(true)
                } else if language == recommended {
                    Text("language.recommended")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.shared.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("language.option.\(language.rawValue)")
        .accessibilityLabel(Text(language.displayName))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
