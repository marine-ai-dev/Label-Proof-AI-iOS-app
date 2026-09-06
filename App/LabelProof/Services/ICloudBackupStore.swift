import Foundation
import LabelProofCore

/// Real iCloud-backed implementation of `ICloudBackupStoring`: stores the
/// single current LabelProof backup as one file inside this app's iCloud
/// Documents ubiquity container — the user's own iCloud account, not any
/// developer-operated storage. Requires the iCloud Documents entitlement
/// (`com.apple.developer.icloud-container-identifiers` /
/// `com.apple.developer.icloud-services` = `CloudDocuments`); see
/// `docs/release/KNOWN_LIMITATIONS.md` for the current provisioning state
/// (a paid Apple Developer Program team is required to actually provision
/// the container — this implementation is written and buildable now, but
/// its runtime behavior can only be verified once that's provisioned).
struct ICloudBackupStore: ICloudBackupStoring {
    /// `nil` when no ubiquity container is available at all (iCloud Drive
    /// off, not signed in, or — currently — no provisioned container for
    /// this app's entitlement).
    private var containerDocumentsURL: URL? {
        guard FileManager.default.ubiquityIdentityToken != nil else { return nil }
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documents = container.appendingPathComponent("Documents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: documents.path) {
            try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        }
        return documents
    }

    private var backupFileURL: URL? {
        containerDocumentsURL?.appendingPathComponent(BackupCodec.iCloudBackupFilename, isDirectory: false)
    }

    func isAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil && containerDocumentsURL != nil
    }

    func write(_ data: Data) throws {
        guard let url = backupFileURL else { throw ICloudBackupError.unavailable }
        var coordinatorError: NSError?
        var writeError: Error?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinatorError) { coordinatedURL in
            do {
                try data.write(to: coordinatedURL, options: .atomic)
            } catch {
                writeError = error
            }
        }
        if coordinatorError != nil || writeError != nil {
            throw ICloudBackupError.writeFailed
        }
    }

    func read() throws -> Data? {
        guard let url = backupFileURL else { throw ICloudBackupError.unavailable }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        var coordinatorError: NSError?
        var result: Data?
        var readError: Error?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { coordinatedURL in
            do {
                result = try Data(contentsOf: coordinatedURL)
            } catch {
                readError = error
            }
        }
        if coordinatorError != nil || readError != nil {
            throw ICloudBackupError.readFailed
        }
        return result
    }

    func delete() throws {
        guard let url = backupFileURL else { throw ICloudBackupError.unavailable }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        var coordinatorError: NSError?
        var deleteError: Error?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorError) { coordinatedURL in
            do {
                try FileManager.default.removeItem(at: coordinatedURL)
            } catch {
                deleteError = error
            }
        }
        if coordinatorError != nil || deleteError != nil {
            throw ICloudBackupError.deleteFailed
        }
    }

    func lastModifiedDate() -> Date? {
        guard let url = backupFileURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        return (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }
}

/// Selects the real or fixture-injected iCloud backup store. Mirrors
/// `ScanServiceFactory`'s existing pattern: production always gets the real
/// store; `UITEST_MODE` with a forced iCloud fixture scenario gets a
/// deterministic `FakeICloudBackupStore` instead, so XCUITests can exercise
/// every Backup & Synchronization UI state without a real iCloud account.
enum ICloudBackupStoreFactory {
    static func make() -> ICloudBackupStoring {
        if let behavior = LaunchEnvironment.forcedICloudBackupBehavior {
            return FakeICloudBackupStore(behavior: behavior)
        }
        return ICloudBackupStore()
    }
}
