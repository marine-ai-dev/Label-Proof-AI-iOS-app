import Foundation
import SwiftData
import LabelProofCore

/// Central point that routes XCUITest launch arguments/environment variables
/// to deterministic fixture behavior, kept fully isolated from normal
/// production code paths (there is no user-facing "fake scan" control
/// anywhere in the UI).
///
/// Recognized launch environment variables (set by XCUITest, see
/// `AppUITests/LaunchArguments.swift`):
/// - `UITEST_RESET_STATE` = "1": wipes the SwiftData store before first launch.
/// - `UITEST_SEED_DEMO_DATA` = "1": seeds `DemoData` golden labels + history.
/// - `UITEST_FIXTURE_SCENARIO` = one of `ScanFixtureScenario.rawValue`:
///   forces the scan pipeline to use `FixtureLabelScanService` with that
///   scenario instead of the real Vision-backed camera/import pipeline.
enum LaunchEnvironment {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_MODE")
    }

    static var forcedFixtureScenario: ScanFixtureScenario? {
        guard let raw = ProcessInfo.processInfo.environment["UITEST_FIXTURE_SCENARIO"] else { return nil }
        return ScanFixtureScenario(rawValue: raw)
    }

    static func applyIfNeeded(to container: ModelContainer) {
        guard isUITesting else { return }
        let context = ModelContext(container)

        if ProcessInfo.processInfo.environment["UITEST_RESET_STATE"] == "1" {
            try? context.delete(model: GoldenLabelRecord.self)
            try? context.delete(model: VerificationHistoryRecord.self)
        }

        if ProcessInfo.processInfo.environment["UITEST_SEED_DEMO_DATA"] == "1" {
            for goldenLabel in DemoData.goldenLabels {
                context.insert(GoldenLabelRecord(
                    id: goldenLabel.id,
                    name: goldenLabel.name,
                    expectedProductName: goldenLabel.expectedProductName,
                    expectedWeight: goldenLabel.expectedWeight,
                    expectedBarcode: goldenLabel.expectedBarcode,
                    requiredPhrases: goldenLabel.requiredPhrases,
                    notes: goldenLabel.notes
                ))
            }
            try? context.save()
        }
    }
}
