import SwiftUI
import PhotosUI
import LabelProofCore

/// Scanner screen offering two deterministic-testable input paths:
/// 1. Live camera via VisionKit `DataScannerViewController` (device only).
/// 2. Image import via `PhotosPicker`, which works in Simulator and is the
///    path exercised by fixture-injected XCUITests.
/// Both paths converge on the same `LabelScanServicing` -> `LabelValidator`
/// pipeline, so results are validated identically regardless of source.
struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goldenLabel: GoldenLabel

    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var validationResult: ValidationResult?
    @State private var lastScan: ExtractedLabelData?
    @State private var showingLiveScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                GlassCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text("scanner.targetLabel \(goldenLabel.name)")
                            .font(.headline)
                        Text("scanner.instructions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                #if canImport(VisionKit) && canImport(UIKit)
                if DataScannerRepresentable.isSupported {
                    Text("scanner.cameraNote")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        showingLiveScanner = true
                    } label: {
                        Label(String(localized: "scanner.scanWithCamera"), systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("scanner.liveCameraButton")
                } else {
                    Text("scanner.cameraUnavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                #endif

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(String(localized: "scanner.importImage"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("scanner.importImageButton")

                if isProcessing {
                    ProgressView(String(localized: "scanner.processing"))
                        .accessibilityIdentifier("scanner.processingIndicator")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("scanner.errorMessage")
                }

                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: "scanner.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
            .onChange(of: photoItem) { _, newValue in
                guard let newValue else { return }
                Task { await handlePickedPhoto(newValue) }
            }
            .task {
                // In UITEST_MODE with a forced fixture scenario, run the scan
                // immediately with an empty placeholder image so XCUITests
                // don't need PhotosPicker automation.
                if LaunchEnvironment.forcedFixtureScenario != nil {
                    await runScan(imageData: Data(), source: .fixture)
                }
            }
            .navigationDestination(item: $validationResult) { result in
                if let lastScan {
                    ResultView(goldenLabel: goldenLabel, scan: lastScan, result: result)
                }
            }
            #if canImport(VisionKit) && canImport(UIKit)
            .fullScreenCover(isPresented: $showingLiveScanner) {
                LiveScannerSheet(
                    onUseScan: { textLines, barcodes in
                        showingLiveScanner = false
                        Task { await runLiveScan(textLines: textLines, barcodes: barcodes) }
                    },
                    onError: { message in
                        showingLiveScanner = false
                        errorMessage = message
                    },
                    onCancel: { showingLiveScanner = false }
                )
            }
            #endif
        }
    }

    #if canImport(VisionKit) && canImport(UIKit)
    private func runLiveScan(textLines: [String], barcodes: [LabelProofCore.BarcodeObservation]) async {
        let scanResult = ExtractedLabelData(rawTextLines: textLines, barcodes: barcodes, source: .liveCamera)
        await runScan(imageData: Data(), source: .liveCamera, precomputedResult: scanResult)
    }
    #endif

    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = String(localized: "scanner.errorLoadingImage")
                return
            }
            await runScan(imageData: data, source: .importedImage)
        } catch {
            errorMessage = String(localized: "scanner.errorLoadingImage")
        }
    }

    private func runScan(imageData: Data, source: ScanSourceType, precomputedResult: ExtractedLabelData? = nil) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        let service: LabelScanServicing = precomputedResult.map { FixtureLabelScanService(result: $0) }
            ?? ScanServiceFactory.makeScanService(goldenLabel: goldenLabel)
        do {
            let scan = try await service.scan(imageData: imageData, source: source)
            let result = LabelValidator.validate(scan: scan, against: goldenLabel)
            let record = VerificationRecord(
                goldenLabelID: goldenLabel.id,
                goldenLabelNameSnapshot: goldenLabel.name,
                result: result,
                scanSource: source
            )
            VerificationHistoryStore(context: modelContext).append(record)
            lastScan = scan
            validationResult = result
        } catch {
            errorMessage = String(localized: "scanner.errorScanFailed")
        }
    }
}

extension ValidationResult: Identifiable {
    public var id: UUID { goldenLabelID }
}
