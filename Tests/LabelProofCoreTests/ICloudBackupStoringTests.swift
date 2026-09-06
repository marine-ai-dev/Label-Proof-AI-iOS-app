import XCTest
@testable import LabelProofCore

/// Exercises the `ICloudBackupStoring` abstraction via its deterministic
/// test double — the same double the app injects in `UITEST_MODE` — so
/// Backup & Synchronization UI/view-model behavior can be verified without
/// a real iCloud account (per docs/ARCHITECTURE.md's Backup section).
final class ICloudBackupStoringTests: XCTestCase {
    func testBackupAvailableAfterWrite() throws {
        let store = FakeICloudBackupStore()
        XCTAssertNil(try store.read())
        try store.write(Data("backup".utf8))
        XCTAssertEqual(try store.read(), Data("backup".utf8))
        XCTAssertNotNil(store.lastModifiedDate())
    }

    func testUnavailableRejectsAllOperations() {
        let store = FakeICloudBackupStore(behavior: .unavailable)
        XCTAssertFalse(store.isAvailable())
        XCTAssertThrowsError(try store.write(Data())) { XCTAssertEqual($0 as? ICloudBackupError, .unavailable) }
        XCTAssertThrowsError(try store.read()) { XCTAssertEqual($0 as? ICloudBackupError, .unavailable) }
        XCTAssertThrowsError(try store.delete()) { XCTAssertEqual($0 as? ICloudBackupError, .unavailable) }
    }

    func testWriteFailureLeavesPreviousBackupIntact() throws {
        let store = FakeICloudBackupStore(behavior: .normal)
        try store.write(Data("first".utf8))
        store.behavior = .writeFails
        XCTAssertThrowsError(try store.write(Data("second".utf8))) { XCTAssertEqual($0 as? ICloudBackupError, .writeFailed) }
        store.behavior = .normal
        XCTAssertEqual(try store.read(), Data("first".utf8))
    }

    func testReadFailureIsReported() {
        let store = FakeICloudBackupStore(behavior: .readFails)
        XCTAssertThrowsError(try store.read()) { XCTAssertEqual($0 as? ICloudBackupError, .readFailed) }
    }

    func testDeleteRemovesBackup() throws {
        let store = FakeICloudBackupStore()
        try store.write(Data("backup".utf8))
        try store.delete()
        XCTAssertNil(try store.read())
        XCTAssertNil(store.lastModifiedDate())
    }

    func testDeleteFailureIsReported() {
        let store = FakeICloudBackupStore(behavior: .deleteFails)
        XCTAssertThrowsError(try store.delete()) { XCTAssertEqual($0 as? ICloudBackupError, .deleteFailed) }
    }

    func testCorruptExistingBackupIsNotSilentlyTrusted() throws {
        let store = FakeICloudBackupStore(behavior: .corruptExistingBackup)
        let data = try XCTUnwrap(store.read())
        XCTAssertThrowsError(try BackupCodec.decode(data)) { error in
            XCTAssertEqual(error as? BackupError, .malformedData)
        }
    }

    func testNeverBackedUpReportsNilDate() {
        let store = FakeICloudBackupStore()
        XCTAssertNil(store.lastModifiedDate())
    }
}
