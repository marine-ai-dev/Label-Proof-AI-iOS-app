import SwiftUI

/// Project-local "Liquid Glass" design tokens for LabelProof.
///
/// This is intentionally a self-contained, project-local design layer (not a
/// separate package) but is written so it can be lifted into a future shared
/// `DesignKit` package with minimal changes — see docs/ARCHITECTURE.md
/// "Design system extraction candidate".
///
/// Tokens cover color, material, spacing, and radius, with explicit
/// Light/Dark/Black appearance handling (Black is a distinct true-OLED-style
/// palette, not simply Dark) and an accent color chosen in Settings.
enum AppAppearance: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark
    case black

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .black: return .dark
        }
    }
}

enum AppAccent: String, CaseIterable, Identifiable, Codable {
    case teal, indigo, coral, mint, amber

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .teal: return Color(red: 0.13, green: 0.62, blue: 0.60)
        case .indigo: return Color(red: 0.35, green: 0.34, blue: 0.84)
        case .coral: return Color(red: 0.92, green: 0.42, blue: 0.36)
        case .mint: return Color(red: 0.24, green: 0.75, blue: 0.55)
        case .amber: return Color(red: 0.88, green: 0.62, blue: 0.16)
        }
    }
}

/// Observable holder for the user's chosen appearance/accent, backed by
/// `AppStorage` under the hood via `SettingsStore` (see ViewModels). Views
/// read tokens through `AppTheme.shared` for previews/defaults and through
/// `@Environment` injected values for live updates — see `ThemeEnvironment.swift`.
@MainActor
final class AppTheme: ObservableObject {
    static let shared = AppTheme()

    @Published var appearance: AppAppearance = .system
    @Published var accent: Color = AppAccent.teal.color

    // MARK: - Spacing scale (points)
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner radius scale
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: - Surface colors (Light / Dark / Black)
    /// Background behind glass cards. Black mode uses true black (#000000)
    /// for OLED power savings and maximal contrast, distinct from Dark's
    /// dark-gray system background.
    static func background(for appearance: AppAppearance, systemColorScheme: ColorScheme) -> Color {
        switch resolvedAppearance(appearance, systemColorScheme: systemColorScheme) {
        case .light: return Color(white: 0.96)
        case .dark: return Color(red: 0.09, green: 0.09, blue: 0.10)
        case .black: return .black
        case .system: return Color(white: 0.96) // unreachable after resolve
        }
    }

    static func cardMaterial(for appearance: AppAppearance, systemColorScheme: ColorScheme) -> Material {
        switch resolvedAppearance(appearance, systemColorScheme: systemColorScheme) {
        case .light: return .regularMaterial
        case .dark: return .thinMaterial
        case .black: return .ultraThinMaterial
        case .system: return .regularMaterial
        }
    }

    static func primaryText(for appearance: AppAppearance, systemColorScheme: ColorScheme) -> Color {
        switch resolvedAppearance(appearance, systemColorScheme: systemColorScheme) {
        case .light: return .black
        case .dark, .black: return .white
        case .system: return .primary
        }
    }

    private static func resolvedAppearance(_ appearance: AppAppearance, systemColorScheme: ColorScheme) -> AppAppearance {
        guard appearance == .system else { return appearance }
        return systemColorScheme == .dark ? .dark : .light
    }
}

/// A "Liquid Glass" styled card container: rounded rect, translucent
/// material, subtle border and shadow, honoring the current appearance +
/// accent tokens. Falls back to plain materials on older OS availability.
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var theme: AppTheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                    .fill(AppTheme.cardMaterial(for: theme.appearance, systemColorScheme: systemColorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

/// Applies the app's chosen appearance/accent to the view hierarchy root.
struct AppThemeRoot: ViewModifier {
    @ObservedObject var theme: AppTheme

    func body(content: Content) -> some View {
        content
            .environmentObject(theme)
            .tint(theme.accent)
            .preferredColorScheme(theme.appearance.colorScheme)
    }
}

extension View {
    func appThemeRoot(_ theme: AppTheme) -> some View {
        modifier(AppThemeRoot(theme: theme))
    }
}
