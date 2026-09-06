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
        static let automaticICloudBackupEnabled = "settings.automaticICloudBackupEnabled"
        static let lastICloudBackupDate = "settings.lastICloudBackupDate"
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
    /// Controls FUTURE automatic iCloud backups only. Turning this off does
    /// NOT delete an existing iCloud backup — that's a separate, explicit,
    /// destructive action ("Delete iCloud Backup") — per the product
    /// requirement that these two stay clearly distinct.
    @Published var automaticICloudBackupEnabled: Bool {
        didSet { UserDefaults.standard.set(automaticICloudBackupEnabled, forKey: Keys.automaticICloudBackupEnabled) }
    }
    /// Local record of the last time this device successfully wrote an
    /// iCloud backup — purely informational (drives the "Last backup: ..."
    /// status line), not a sync cursor of any kind.
    @Published var lastICloudBackupDate: Date? {
        didSet {
            if let lastICloudBackupDate {
                UserDefaults.standard.set(lastICloudBackupDate, forKey: Keys.lastICloudBackupDate)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastICloudBackupDate)
            }
        }
    }

    init() {
        let defaults = UserDefaults.standard
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        accent = AppAccent(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .teal
        keepHistoryDays = defaults.object(forKey: Keys.keepHistoryDays) != nil ? defaults.integer(forKey: Keys.keepHistoryDays) : 0
        automaticICloudBackupEnabled = defaults.bool(forKey: Keys.automaticICloudBackupEnabled)
        lastICloudBackupDate = defaults.object(forKey: Keys.lastICloudBackupDate) as? Date
    }
}
