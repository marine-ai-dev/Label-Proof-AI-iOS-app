import XCTest
@testable import LabelProofCore

final class BackupCodecTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_757_000_000)

    private func makeGoldenLabel() -> GoldenLabel {
        GoldenLabel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Test Label",
            expectedProductName: "Allantoin Restore Hand Cream",
            expectedWeight: "100 ml",
            expectedBarcode: "5901234123457",
            requiredPhrases: ["Keep out of reach of children"],
            notes: "note",
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
    }

    private func makeHistoryRecord() -> VerificationRecord {
        let result = ValidationResult(
            status: .pass,
            goldenLabelID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            ruleResults: [],
            mismatches: [],
            evaluatedAt: fixedDate
        )
        return VerificationRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            goldenLabelID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            goldenLabelNameSnapshot: "Test Label",
            result: result,
            scanSource: .fixture,
            createdAt: fixedDate
        )
    }

    // MARK: - Roundtrip

    func testEmptyBackupRoundtrips() throws {
        let data = try BackupCodec.encode(goldenLabels: [], verificationHistory: [], appVersion: "1.0", createdAt: fixedDate)
        let envelope = try BackupCodec.decode(data)
        XCTAssertEqual(envelope.goldenLabels, [])
        XCTAssertEqual(envelope.verificationHistory, [])
        XCTAssertEqual(envelope.schemaVersion, currentBackupSchemaVersion)
        XCTAssertEqual(envelope.appVersion, "1.0")
    }

    func testGoldenLabelsRoundtrip() throws {
        let label = makeGoldenLabel()
        let data = try BackupCodec.encode(goldenLabels: [label], verificationHistory: [], appVersion: "1.0", createdAt: fixedDate)
        let envelope = try BackupCodec.decode(data)
        XCTAssertEqual(envelope.goldenLabels, [label])
    }

    func testHistoryRoundtrips() throws {
        let record = makeHistoryRecord()
        let data = try BackupCodec.encode(goldenLabels: [], verificationHistory: [record], appVersion: "1.0", createdAt: fixedDate)
        let envelope = try BackupCodec.decode(data)
        XCTAssertEqual(envelope.verificationHistory, [record])
    }

    func testRequiredPhrasesRoundtrip() throws {
        var label = makeGoldenLabel()
        label.requiredPhrases = ["Phrase one", "Phrase two", "Phrase three"]
        let data = try BackupCodec.encode(goldenLabels: [label], verificationHistory: [], appVersion: "1.0", createdAt: fixedDate)
        let envelope = try BackupCodec.decode(data)
        XCTAssertEqual(envelope.goldenLabels.first?.requiredPhrases, ["Phrase one", "Phrase two", "Phrase three"])
    }

    func testSchemaVersionIsEncoded() throws {
        let data = try BackupCodec.encode(goldenLabels: [], verificationHistory: [], appVersion: "1.0", createdAt: fixedDate)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"schemaVersion\":\(currentBackupSchemaVersion)"))
    }

    func testDeterministicIDsAndDatesSurviveRoundtrip() throws {
        let label = makeGoldenLabel()
        let record = makeHistoryRecord()
        let data = try BackupCodec.encode(goldenLabels: [label], verificationHistory: [record], appVersion: "1.0", createdAt: fixedDate)
        let envelope = try BackupCodec.decode(data)
        XCTAssertEqual(envelope.goldenLabels.first?.id, label.id)
        XCTAssertEqual(envelope.verificationHistory.first?.id, record.id)
        XCTAssertEqual(envelope.createdAt, fixedDate)
    }

    // MARK: - Rejection

    func testUnsupportedFutureSchemaVersionIsRejected() throws {
        var envelope = BackupEnvelope(appVersion: "1.0", createdAt: fixedDate, goldenLabels: [], verificationHistory: [])
        envelope.schemaVersion = currentBackupSchemaVersion + 1
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(envelope)

        XCTAssertThrowsError(try BackupCodec.decode(data)) { error in
            XCTAssertEqual(
                error as? BackupError,
                .unsupportedSchemaVersion(found: currentBackupSchemaVersion + 1, maxSupported: currentBackupSchemaVersion)
            )
        }
    }

    func testMalformedJSONIsRejected() {
        let data = Data("{ this is not valid json".utf8)
        XCTAssertThrowsError(try BackupCodec.decode(data)) { error in
            XCTAssertEqual(error as? BackupError, .malformedData)
        }
    }

    func testValidJSONButWrongShapeIsRejected() {
        let data = Data("{\"hello\": \"world\"}".utf8)
        XCTAssertThrowsError(try BackupCodec.decode(data)) { error in
            XCTAssertEqual(error as? BackupError, .malformedData)
        }
    }

    func testEmptyFileIsRejected() {
        XCTAssertThrowsError(try BackupCodec.decode(Data())) { error in
            XCTAssertEqual(error as? BackupError, .emptyFile)
        }
    }

    func testDefaultFilenameIsDateStamped() {
        let filename = BackupCodec.defaultFilename(for: fixedDate)
        XCTAssertTrue(filename.hasPrefix("LabelProof-Backup-"))
        XCTAssertTrue(filename.hasSuffix(".labelproofbackup"))
    }

    func testSummaryReflectsEnvelopeContents() throws {
        let label = makeGoldenLabel()
        let record = makeHistoryRecord()
        let data = try BackupCodec.encode(goldenLabels: [label, label], verificationHistory: [record], appVersion: "1.2", createdAt: fixedDate)
        let envelope = try BackupCodec.decode(data)
        let summary = envelope.summary
        XCTAssertEqual(summary.goldenLabelCount, 2)
        XCTAssertEqual(summary.historyCount, 1)
        XCTAssertEqual(summary.appVersion, "1.2")
        XCTAssertEqual(summary.createdAt, fixedDate)
    }
}
