import SwiftUI
import LabelProofCore

#if canImport(VisionKit) && canImport(UIKit)
import VisionKit
import UIKit

/// Thin `UIViewControllerRepresentable` wrapper around VisionKit's
/// `DataScannerViewController` for live camera scanning. VisionKit performs
/// on-device text and barcode recognition itself (there is no separate
/// "capture a frame" step), so this feeds recognized items straight into
/// `onRecognize` as they update; `LiveScannerService` (see ScanServiceFactory)
/// wraps the latest snapshot as a `LabelScanServicing` so the live-camera
/// path still runs through the exact same `LabelValidator` used by imported
/// images and fixtures.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onRecognize: (_ textLines: [String], _ barcodes: [LabelProofCore.BarcodeObservation]) -> Void
    var onError: (String) -> Void

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text(), .barcode()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                onError(error.localizedDescription)
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRecognize: onRecognize, onError: onError)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onRecognize: (_ textLines: [String], _ barcodes: [LabelProofCore.BarcodeObservation]) -> Void
        let onError: (String) -> Void

        init(
            onRecognize: @escaping (_ textLines: [String], _ barcodes: [LabelProofCore.BarcodeObservation]) -> Void,
            onError: @escaping (String) -> Void
        ) {
            self.onRecognize = onRecognize
            self.onError = onError
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            report(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            report(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            report(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            onError("\(error)")
        }

        private func report(_ items: [RecognizedItem]) {
            var textLines: [String] = []
            var barcodes: [LabelProofCore.BarcodeObservation] = []
            for item in items {
                switch item {
                case .text(let text):
                    textLines.append(text.transcript)
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue {
                        barcodes.append(LabelProofCore.BarcodeObservation(payload: payload, symbology: barcode.observation.symbology.rawValue))
                    }
                @unknown default:
                    break
                }
            }
            onRecognize(textLines, barcodes)
        }
    }
}
#endif
