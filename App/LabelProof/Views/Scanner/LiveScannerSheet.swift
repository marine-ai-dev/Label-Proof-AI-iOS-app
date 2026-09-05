import SwiftUI
import LabelProofCore

#if canImport(VisionKit) && canImport(UIKit)
/// Full-screen live camera scanning surface. Wraps `DataScannerRepresentable`
/// and lets the user capture the currently recognized text/barcodes once
/// VisionKit has picked something up, or cancel back to the import-photo
/// path. Requesting the camera happens implicitly when `DataScannerViewController`
/// starts scanning; a denial surfaces through `onError` (see
/// `DataScannerRepresentable.Coordinator.becameUnavailableWithError`).
struct LiveScannerSheet: View {
    let onUseScan: (_ textLines: [String], _ barcodes: [LabelProofCore.BarcodeObservation]) -> Void
    let onError: (String) -> Void
    let onCancel: () -> Void

    @State private var textLines: [String] = []
    @State private var barcodes: [LabelProofCore.BarcodeObservation] = []

    private var hasRecognizedSomething: Bool {
        !textLines.isEmpty || !barcodes.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DataScannerRepresentable(
                onRecognize: { newTextLines, newBarcodes in
                    textLines = newTextLines
                    barcodes = newBarcodes
                },
                onError: { message in
                    onError(message)
                }
            )
            .ignoresSafeArea()
            .accessibilityIdentifier("scanner.liveCameraView")

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(hasRecognizedSomething ? String(localized: "scanner.live.readyToUse") : String(localized: "scanner.live.pointAtLabel"))
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(.thinMaterial, in: Capsule())
                    .accessibilityIdentifier("scanner.live.statusText")

                HStack(spacing: AppTheme.Spacing.md) {
                    Button(String(localized: "action.cancel"), role: .cancel) {
                        onCancel()
                    }
                    .buttonStyle(.bordered)

                    Button(String(localized: "scanner.live.useScan")) {
                        onUseScan(textLines, barcodes)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasRecognizedSomething)
                    .accessibilityIdentifier("scanner.live.useScanButton")
                }
            }
            .padding()
        }
    }
}
#endif
