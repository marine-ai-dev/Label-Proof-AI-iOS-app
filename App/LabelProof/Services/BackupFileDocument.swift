import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// LabelProof's portable backup file format — see `BackupCodec` in
    /// LabelProofCore. Declared as an exported type in Info.plist so Files/
    /// the system recognizes `.labelproofbackup` and shows a sensible name/
    /// icon rather than a generic "Document" placeholder.
    static var labelProofBackup: UTType {
        UTType(exportedAs: "com.labelproof.app.backup")
    }
}

/// `FileDocument` wrapper around an already-encoded backup snapshot, used
/// only to drive SwiftUI's `.fileExporter` — the encoding itself always
/// happens in `BackupService`/`BackupCodec`, never here.
struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.labelProofBackup] }
    static var writableContentTypes: [UTType] { [.labelProofBackup] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
