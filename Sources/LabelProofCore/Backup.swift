import Foundation

/// The current backup schema version this build can both write and read.
/// Bump this only when the envelope's shape changes in a way that isn't
/// purely additive; `BackupCodec.decode` rejects any file whose
/// `schemaVersion` is newer than this build understands, rather than
/// guessing at how to interpret unknown fields.
public let currentBackupSchemaVersion = 1

/// A versioned, portable snapshot of a user's LabelProof data — golden
/// labels and verification history — and nothing else. No temporary scan
/// state, no camera frames, no fixtures/debug data, and (per
/// `docs/PRIVACY.md`) no captured images ever existed to include in the
/// first place.
public struct BackupEnvelope: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var appVersion: String
    public var createdAt: Date
    public var goldenLabels: [GoldenLabel]
    public var verificationHistory: [VerificationRecord]

    public init(
        schemaVersion: Int = currentBackupSchemaVersion,
        appVersion: String,
        createdAt: Date = Date(),
        goldenLabels: [GoldenLabel],
        verificationHistory: [VerificationRecord]
    ) {
        self.schemaVersion = schemaVersion
        self.appVersion = appVersion
        self.createdAt = createdAt
        self.goldenLabels = goldenLabels
        self.verificationHistory = verificationHistory
    }
}

/// A short, user-presentable summary of a backup file's contents — shown
/// before the user confirms a destructive restore, never used to drive the
/// restore itself (the full decoded `BackupEnvelope` is used for that).
public struct BackupSummary: Equatable, Sendable {
    public var createdAt: Date
    public var appVersion: String
    public var goldenLabelCount: Int
    public var historyCount: Int

    public init(createdAt: Date, appVersion: String, goldenLabelCount: Int, historyCount: Int) {
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.goldenLabelCount = goldenLabelCount
        self.historyCount = historyCount
    }
}

public extension BackupEnvelope {
    var summary: BackupSummary {
        BackupSummary(
            createdAt: createdAt,
            appVersion: appVersion,
            goldenLabelCount: goldenLabels.count,
            historyCount: verificationHistory.count
        )
    }
}

/// Errors surfaced while encoding/decoding a backup file. Deliberately
/// specific (never a blind "something went wrong") so the UI can explain
/// what happened without exposing raw decoding internals.
public enum BackupError: Error, Equatable, Sendable {
    /// The file isn't valid JSON, or isn't shaped like a `BackupEnvelope` at
    /// all (missing/mistyped required fields).
    case malformedData
    /// The file parses, but declares a `schemaVersion` newer than this
    /// build knows how to read (e.g. a backup made by a future version of
    /// LabelProof).
    case unsupportedSchemaVersion(found: Int, maxSupported: Int)
    /// The file is empty or otherwise trivially not a backup.
    case emptyFile
}

/// Encodes/decodes `BackupEnvelope` to/from the on-disk `.labelproofbackup`
/// format: a plain, inspectable JSON document. Deliberately not a ZIP/
/// archive — the data is small, text-only, and a bare JSON file is both
/// simpler and more transparent to a user who opens it in a text editor.
public enum BackupCodec {
    /// Encodes a fresh backup envelope for the given data. Always writes
    /// `currentBackupSchemaVersion` — a running app only ever produces
    /// current-format backups; older formats are only ever read, not
    /// written, by design (see `decode`).
    public static func encode(
        goldenLabels: [GoldenLabel],
        verificationHistory: [VerificationRecord],
        appVersion: String,
        createdAt: Date = Date()
    ) throws -> Data {
        let envelope = BackupEnvelope(
            appVersion: appVersion,
            createdAt: createdAt,
            goldenLabels: goldenLabels,
            verificationHistory: verificationHistory
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(envelope)
    }

    /// Decodes and validates a backup file. Never partially trusts a file:
    /// either it fully decodes into a well-formed `BackupEnvelope` with a
    /// supported schema version, or this throws — callers must not act on
    /// a `nil`/best-effort partial result.
    public static func decode(_ data: Data) throws -> BackupEnvelope {
        guard !data.isEmpty else { throw BackupError.emptyFile }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let envelope: BackupEnvelope
        do {
            envelope = try decoder.decode(BackupEnvelope.self, from: data)
        } catch {
            throw BackupError.malformedData
        }

        guard envelope.schemaVersion <= currentBackupSchemaVersion else {
            throw BackupError.unsupportedSchemaVersion(
                found: envelope.schemaVersion,
                maxSupported: currentBackupSchemaVersion
            )
        }

        return envelope
    }

    /// A stable, sortable-by-date default filename, e.g.
    /// `LabelProof-Backup-2026-09-06.labelproofbackup`.
    public static func defaultFilename(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return "LabelProof-Backup-\(formatter.string(from: date)).labelproofbackup"
    }

    /// The canonical filename used for the single current iCloud backup
    /// snapshot (see `docs/ARCHITECTURE.md`'s Backup & Synchronization
    /// section) — stable, not date-stamped, since only one iCloud snapshot
    /// is kept at a time.
    public static let iCloudBackupFilename = "LabelProof Backup.labelproofbackup"

    public static let fileExtension = "labelproofbackup"
}
