import Foundation

/// Abstraction over "one current backup file, kept in the user's own
/// iCloud account." Deliberately narrow — this is a single-snapshot backup
/// mechanism (see `BackupCodec.iCloudBackupFilename`), not a general sync
/// engine and not a CloudKit database. Kept as a protocol so the real
/// ubiquity-container-backed implementation (in the app target, which needs
/// `FileManager`'s iCloud APIs and the iCloud entitlement) can be swapped
/// for a deterministic test double here and in UI-test fixture injection.
public protocol ICloudBackupStoring: Sendable {
    /// Whether iCloud is currently reachable for this app (signed in,
    /// iCloud Drive enabled, container reachable). `false` must never be
    /// treated as an error state by callers — it's a normal, common
    /// condition the UI should show plainly (e.g. "iCloud unavailable").
    func isAvailable() -> Bool

    /// Overwrites the single current iCloud backup with `data`.
    func write(_ data: Data) throws

    /// Reads the current iCloud backup, if one exists.
    /// Returns `nil` when no backup has ever been written (not an error).
    func read() throws -> Data?

    /// Deletes the current iCloud backup, if one exists. A no-op (not an
    /// error) if none exists.
    func delete() throws

    /// The last-modified date of the current iCloud backup, if one exists.
    func lastModifiedDate() -> Date?
}

/// Errors an `ICloudBackupStoring` implementation may throw. Kept generic
/// enough that the UI can map every case to a plain-language message
/// without ever surfacing a raw system/CloudKit error to the user.
public enum ICloudBackupError: Error, Equatable, Sendable {
    case unavailable
    case writeFailed
    case readFailed
    case deleteFailed
    case corruptBackup
}

/// Deterministic in-memory test double for `ICloudBackupStoring`, used by
/// unit tests and by the app in `UITEST_MODE` (see `LaunchEnvironment`) so
/// XCUITests can exercise Backup & Synchronization UI states (available/
/// unavailable, has-backup/never-backed-up, write failure, corrupt backup)
/// without touching a real iCloud account.
public final class FakeICloudBackupStore: ICloudBackupStoring, @unchecked Sendable {
    public enum Behavior: String, Sendable {
        case normal
        case unavailable
        case writeFails
        case readFails
        case deleteFails
        case corruptExistingBackup
    }

    private let lock = NSLock()
    private var storedData: Data?
    private var storedDate: Date?
    public var behavior: Behavior

    public init(behavior: Behavior = .normal, initialData: Data? = nil, initialDate: Date? = nil) {
        self.behavior = behavior
        self.storedData = initialData
        self.storedDate = initialDate
    }

    public func isAvailable() -> Bool {
        behavior != .unavailable
    }

    public func write(_ data: Data) throws {
        guard behavior != .unavailable else { throw ICloudBackupError.unavailable }
        guard behavior != .writeFails else { throw ICloudBackupError.writeFailed }
        lock.lock()
        storedData = data
        storedDate = Date()
        lock.unlock()
    }

    public func read() throws -> Data? {
        guard behavior != .unavailable else { throw ICloudBackupError.unavailable }
        guard behavior != .readFails else { throw ICloudBackupError.readFailed }
        if behavior == .corruptExistingBackup { return Data("not a valid backup".utf8) }
        lock.lock()
        defer { lock.unlock() }
        return storedData
    }

    public func delete() throws {
        guard behavior != .unavailable else { throw ICloudBackupError.unavailable }
        guard behavior != .deleteFails else { throw ICloudBackupError.deleteFailed }
        lock.lock()
        storedData = nil
        storedDate = nil
        lock.unlock()
    }

    public func lastModifiedDate() -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return storedDate
    }
}
