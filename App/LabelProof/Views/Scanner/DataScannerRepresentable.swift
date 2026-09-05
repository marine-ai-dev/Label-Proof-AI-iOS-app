import SwiftUI

#if canImport(VisionKit) && canImport(UIKit)
import VisionKit
import UIKit

/// Thin `UIViewControllerRepresentable` wrapper around VisionKit's
/// `DataScannerViewController`, used only to capture a still frame (as image
/// data) for the shared OCR+barcode pipeline — recognition itself always
/// goes through `LabelScanServicing` so live-camera and imported-image scans
/// are validated identically. Structurally correct but NOT executed/verified
/// in this cloud sandbox (no camera/Simulator available).
struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
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
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onError: onError)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCapture: (Data) -> Void
        let onError: (String) -> Void

        init(onCapture: @escaping (Data) -> Void, onError: @escaping (String) -> Void) {
            self.onCapture = onCapture
            self.onError = onError
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            onError("\(error)")
        }
    }
}
#endif
