import Foundation
import SwiftData
import LabelProofCore

/// Assembles a fresh backup snapshot of the user's current local data.
/// Used identically by manual Export and by automatic/manual iCloud backup
/// — one snapshot format, one code path, per docs/ARCHITECTURE.md.
@MainActor
enum BackupService {
    static func makeSnapshotData(context: ModelContext) throws -> Data {
        let goldenLabels = GoldenLabelStore(context: context).fetchAll()
        let history = VerificationHistoryStore(context: context).fetchAll()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        return try BackupCodec.encode(goldenLabels: goldenLabels, verificationHistory: history, appVersion: appVersion)
    }
}

/// Errors surfaced to the UI for a restore attempt — always specific enough
/// to explain what happened without exposing raw decoding/SwiftData
/// internals to the user.
enum RestoreError: Error, Equatable {
    case invalidBackupFile
    case unsupportedBackupVersion
    case restoreFailed
}

/// Validates a backup file, then — only on the user's explicit confirmation
/// — replaces all local Golden Labels and Verification History with its
/// contents. Never partially trusts a file: validation (via `BackupCodec`)
/// always happens first and completely, before any destructive step; if
/// the destructive replace itself fails partway, the in-flight SwiftData
/// changes are rolled back rather than left half-applied.
@MainActor
struct LocalRestoreService {
    let context: ModelContext

    /// Decodes and validates `data` without changing any local data.
    /// Callers should show the resulting summary and get explicit user
    /// confirmation before calling `restore(envelope:)`.
    func validate(data: Data) throws -> BackupEnvelope {
        do {
            return try BackupCodec.decode(data)
        } catch BackupError.unsupportedSchemaVersion {
            throw RestoreError.unsupportedBackupVersion
        } catch {
            throw RestoreError.invalidBackupFile
        }
    }

    /// Replaces all local Golden Labels and Verification History with
    /// `envelope`'s contents. Must only be called after the user has
    /// explicitly confirmed the destructive replace (see
    /// `BackupSettingsView`).
    func restore(_ envelope: BackupEnvelope) throws {
        do {
            try context.delete(model: GoldenLabelRecord.self)
            try context.delete(model: VerificationHistoryRecord.self)

            for label in envelope.goldenLabels {
                context.insert(GoldenLabelRecord(
                    id: label.id,
                    name: label.name,
                    expectedProductName: label.expectedProductName,
                    expectedWeight: label.expectedWeight,
                    expectedBarcode: label.expectedBarcode,
                    requiredPhrases: label.requiredPhrases,
                    notes: label.notes,
                    createdAt: label.createdAt,
                    updatedAt: label.updatedAt
                ))
            }
            for record in envelope.verificationHistory {
                context.insert(VerificationHistoryRecord(record: record))
            }
            try context.save()
        } catch {
            context.rollback()
            throw RestoreError.restoreFailed
        }
    }
}
