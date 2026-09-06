import SwiftUI
import LabelProofCore

/// Backup & Synchronization: local-first by default, with two independent,
/// user-controlled ways to protect data — an optional automatic iCloud
/// snapshot in the user's own iCloud account, and a manual export/import
/// through the native Files picker. Neither path touches any
/// developer-operated service; see docs/PRIVACY.md.
struct BackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore
    // See HomeView's comment on this same property.
    @EnvironmentObject private var languageStore: LanguageStore

    private let iCloudStore: ICloudBackupStoring = ICloudBackupStoreFactory.make()

    @State private var iCloudAvailable = false
    @State private var iCloudBackupExists = false
    @State private var iCloudBackupDate: Date?
    @State private var statusMessage: String?
    @State private var isSyncing = false

    @State private var showingExporter = false
    @State private var exportDocument = BackupFileDocument(data: Data())
    @State private var exportError: String?

    @State private var showingImporter = false
    @State private var pendingImportEnvelope: BackupEnvelope?
    @State private var showingImportConfirmation = false
    @State private var importError: String?

    @State private var showingICloudRestoreConfirmation = false
    @State private var showingDeleteICloudConfirmation = false
    @State private var deleteICloudError: String?

    var body: some View {
        Form {
            Section {
                Toggle(L("backup.automaticICloud"), isOn: $settings.automaticICloudBackupEnabled)
                    .tint(settings.accent.color)
                    .accessibilityIdentifier("backup.automaticICloudToggle")
                    .onChange(of: settings.automaticICloudBackupEnabled) { _, enabled in
                        if enabled { Task { await syncNow() } }
                    }
            } header: {
                Text("backup.section.icloud")
            } footer: {
                Text("backup.icloud.explanation")
            }

            Section {
                LabeledContent(L("backup.status.title")) {
                    Text(statusText)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("backup.statusRow")

                Button {
                    Task { await syncNow() }
                } label: {
                    if isSyncing {
                        ProgressView()
                    } else {
                        Text("backup.syncNow")
                    }
                }
                .tint(settings.accent.color)
                .disabled(isSyncing || !iCloudAvailable)
                .accessibilityIdentifier("backup.syncNowButton")

                if iCloudBackupExists {
                    Button(L("backup.restoreFromICloud")) {
                        showingICloudRestoreConfirmation = true
                    }
                    .tint(settings.accent.color)
                    .accessibilityIdentifier("backup.restoreFromICloudButton")
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("backup.statusMessage")
                }
            }

            Section {
                Button {
                    exportNow()
                } label: {
                    Text("backup.exportBackup")
                }
                .tint(settings.accent.color)
                .accessibilityIdentifier("backup.exportButton")

                Button {
                    showingImporter = true
                } label: {
                    Text("backup.importBackup")
                }
                .tint(settings.accent.color)
                .accessibilityIdentifier("backup.importButton")

                if let exportError {
                    Text(exportError).font(.footnote).foregroundStyle(.red)
                }
                if let importError {
                    Text(importError).font(.footnote).foregroundStyle(.red)
                }
            } header: {
                Text("backup.section.manual")
            } footer: {
                Text("backup.manual.explanation")
            }

            if iCloudBackupExists {
                Section {
                    Button(role: .destructive) {
                        showingDeleteICloudConfirmation = true
                    } label: {
                        Text("backup.deleteICloudBackup")
                    }
                    .accessibilityIdentifier("backup.deleteICloudButton")
                    if let deleteICloudError {
                        Text(deleteICloudError).font(.footnote).foregroundStyle(.red)
                    }
                } header: {
                    Text("backup.section.cloudData")
                }
            }
        }
        .navigationTitle(L("settings.backupSync"))
        .onAppear(perform: refreshStatus)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .labelProofBackup,
            defaultFilename: BackupCodec.defaultFilename()
        ) { result in
            switch result {
            case .success:
                exportError = nil
            case .failure(let error):
                exportError = L("backup.export.failed \(error.localizedDescription)")
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.labelProofBackup]) { result in
            handleImportPick(result)
        }
        .confirmationDialog(
            L("backup.import.confirmTitle"),
            isPresented: $showingImportConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("backup.import.confirmAction"), role: .destructive) {
                performImportRestore()
            }
            Button(L("action.cancel"), role: .cancel) { pendingImportEnvelope = nil }
        } message: {
            Text(importSummaryText)
        }
        .confirmationDialog(
            L("backup.restoreFromICloud.confirmTitle"),
            isPresented: $showingICloudRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("backup.import.confirmAction"), role: .destructive) {
                Task { await restoreFromICloud() }
            }
            Button(L("action.cancel"), role: .cancel) {}
        }
        .confirmationDialog(
            L("backup.deleteICloudBackup.confirmTitle"),
            isPresented: $showingDeleteICloudConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("backup.deleteICloudBackup.confirmAction"), role: .destructive) {
                Task { await deleteICloudBackup() }
            }
            Button(L("action.cancel"), role: .cancel) {}
        } message: {
            if settings.automaticICloudBackupEnabled {
                Text("backup.deleteICloudBackup.automaticStillOnWarning")
            }
        }
    }

    private var statusText: String {
        if !iCloudAvailable {
            return L("backup.status.unavailable")
        }
        if let date = iCloudBackupDate {
            return L("backup.status.lastBackup \(date.formatted(date: .abbreviated, time: .shortened))")
        }
        return L("backup.status.never")
    }

    private var importSummaryText: String {
        guard let envelope = pendingImportEnvelope else { return "" }
        return L("backup.import.summary \(envelope.createdAt.formatted(date: .abbreviated, time: .shortened)) \(envelope.goldenLabels.count) \(envelope.verificationHistory.count)")
    }

    private func refreshStatus() {
        iCloudAvailable = iCloudStore.isAvailable()
        iCloudBackupDate = settings.lastICloudBackupDate
        iCloudBackupExists = (try? iCloudStore.read()) != nil
    }

    private func syncNow() async {
        isSyncing = true
        statusMessage = nil
        defer { isSyncing = false }
        do {
            let data = try BackupService.makeSnapshotData(context: modelContext)
            try iCloudStore.write(data)
            settings.lastICloudBackupDate = Date()
            iCloudBackupDate = settings.lastICloudBackupDate
            iCloudBackupExists = true
            statusMessage = L("backup.sync.success")
        } catch {
            statusMessage = L("backup.sync.failed")
        }
        iCloudAvailable = iCloudStore.isAvailable()
    }

    private func exportNow() {
        do {
            exportDocument = BackupFileDocument(data: try BackupService.makeSnapshotData(context: modelContext))
            exportError = nil
            showingExporter = true
        } catch {
            exportError = L("backup.export.failed \(error.localizedDescription)")
        }
    }

    private func handleImportPick(_ result: Result<URL, Error>) {
        importError = nil
        switch result {
        case .failure(let error):
            importError = L("backup.import.failed \(error.localizedDescription)")
        case .success(let url):
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let envelope = try LocalRestoreService(context: modelContext).validate(data: data)
                pendingImportEnvelope = envelope
                showingImportConfirmation = true
            } catch RestoreError.unsupportedBackupVersion {
                importError = L("backup.import.unsupportedVersion")
            } catch {
                importError = L("backup.import.invalidFile")
            }
        }
    }

    private func performImportRestore() {
        guard let envelope = pendingImportEnvelope else { return }
        pendingImportEnvelope = nil
        do {
            try LocalRestoreService(context: modelContext).restore(envelope)
            importError = nil
        } catch {
            importError = L("backup.import.restoreFailed")
        }
    }

    private func restoreFromICloud() async {
        do {
            guard let data = try iCloudStore.read() else {
                statusMessage = L("backup.status.never")
                return
            }
            let envelope = try LocalRestoreService(context: modelContext).validate(data: data)
            try LocalRestoreService(context: modelContext).restore(envelope)
            statusMessage = L("backup.restoreFromICloud.success")
        } catch {
            statusMessage = L("backup.restoreFromICloud.failed")
        }
    }

    private func deleteICloudBackup() async {
        do {
            try iCloudStore.delete()
            iCloudBackupExists = false
            iCloudBackupDate = nil
            settings.lastICloudBackupDate = nil
            deleteICloudError = nil
        } catch {
            deleteICloudError = L("backup.deleteICloudBackup.failed")
        }
    }
}
