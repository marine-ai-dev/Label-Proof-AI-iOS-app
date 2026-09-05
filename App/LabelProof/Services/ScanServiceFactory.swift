import Foundation
import LabelProofCore

/// Assembles the `LabelScanServicing` instance the app should use: the real
/// Vision-backed pipeline in production, or a deterministic fixture when
/// `LaunchEnvironment.forcedFixtureScenario` is set (XCUITest only). This is
/// the single seam that keeps fixture injection out of every other call site.
enum ScanServiceFactory {
    static func makeScanService(goldenLabel: GoldenLabel?) -> LabelScanServicing {
        if let scenario = LaunchEnvironment.forcedFixtureScenario, let goldenLabel {
            return FixtureLabelScanService(scenario: scenario, goldenLabel: goldenLabel)
        }
        #if canImport(Vision) && canImport(UIKit)
        return CompositeLabelScanService(ocrService: VisionOCRService(), barcodeService: VisionBarcodeService())
        #else
        // Non-Apple-platform fallback (e.g. a Linux CI sanity build of the
        // app target is not expected to happen, but keep this exhaustive).
        return FixtureLabelScanService(result: ExtractedLabelData(rawTextLines: [], barcodes: [], source: .fixture))
        #endif
    }
}
