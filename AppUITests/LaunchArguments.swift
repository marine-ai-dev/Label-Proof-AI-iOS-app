import Foundation

/// Shared constants for driving the app deterministically from XCUITest,
/// mirroring `App/LabelProof/Services/LaunchEnvironment.swift`. Kept as a
/// separate copy (rather than importing the app target) so this file can be
/// dropped into an `XCUITest` target with no dependency wiring beyond adding
/// it to that target's membership in Xcode.
enum UITestLaunch {
    static let uiTestModeArgument = "UITEST_MODE"

    enum EnvironmentKey {
        static let resetState = "UITEST_RESET_STATE"
        static let seedDemoData = "UITEST_SEED_DEMO_DATA"
        static let fixtureScenario = "UITEST_FIXTURE_SCENARIO"
    }

    /// Matches `LabelProofCore.ScanFixtureScenario.rawValue`.
    enum FixtureScenario: String {
        case fullMatch
        case wrongProductName
        case wrongWeight
        case wrongBarcode
        case missingRequiredPhrase
        case multipleMismatches
        case emptyRecognition
    }
}
