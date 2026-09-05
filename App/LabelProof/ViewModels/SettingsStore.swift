import Foundation
import Combine

/// Persists user-facing settings via `UserDefaults` (no analytics, no
/// network — purely local preference storage).
@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let appearance = "settings.appearance"
        static let accent = "settings.accent"
        static let keepHistoryDays = "settings.keepHistoryDays"
    }

    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published var accent: AppAccent {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: Keys.accent) }
    }
    /// 0 means "keep forever".
    @Published var keepHistoryDays: Int {
        didSet { UserDefaults.standard.set(keepHistoryDays, forKey: Keys.keepHistoryDays) }
    }

    init() {
        let defaults = UserDefaults.standard
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        accent = AppAccent(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .teal
        keepHistoryDays = defaults.object(forKey: Keys.keepHistoryDays) != nil ? defaults.integer(forKey: Keys.keepHistoryDays) : 0
    }
}
