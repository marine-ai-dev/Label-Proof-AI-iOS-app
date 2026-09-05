import XCTest

/// XCUITest scaffolding for LabelProof's main flows, driven entirely by
/// deterministic fixture injection (see `LaunchArguments.swift` and
/// `App/LabelProof/Services/LaunchEnvironment.swift`) — no real camera/Vision
/// calls happen in these tests. NOT executed in this cloud sandbox (no
/// Simulator available); see docs/LOCAL_QA_HANDOFF.md for how to run these
/// locally in Xcode.
final class LabelProofUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchedApp(fixtureScenario: UITestLaunch.FixtureScenario? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [UITestLaunch.uiTestModeArgument]
        app.launchEnvironment[UITestLaunch.EnvironmentKey.resetState] = "1"
        app.launchEnvironment[UITestLaunch.EnvironmentKey.seedDemoData] = "1"
        if let fixtureScenario {
            app.launchEnvironment[UITestLaunch.EnvironmentKey.fixtureScenario] = fixtureScenario.rawValue
        }
        app.launch()
        return app
    }

    func testHomeShowsSeededGoldenLabels() {
        let app = launchedApp()
        XCTAssertTrue(app.tabBars.buttons["tab.home"].waitForExistence(timeout: 5))
        // At least one seeded golden-label row should exist and the empty
        // state should not be shown.
        XCTAssertFalse(app.otherElements["home.emptyState"].exists)
    }

    func testGoldenLabelsListShowsSeededEntries() {
        let app = launchedApp()
        app.tabBars.buttons["tab.goldenLabels"].tap()
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["goldenLabels.emptyState"].exists)
    }

    func testFullMatchScanShowsPassResult() {
        let app = launchedApp(fixtureScenario: .fullMatch)
        app.tabBars.buttons["tab.home"].tap()
        let firstGoldenLabelCell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'home.goldenLabel.'")).firstMatch
        guard firstGoldenLabelCell.waitForExistence(timeout: 5) else {
            XCTFail("No seeded golden label found")
            return
        }
        firstGoldenLabelCell.tap()
        // The fixture-injected scan runs automatically in UITEST_MODE with a
        // forced scenario (see ScannerView.task), producing a result screen.
        XCTAssertTrue(app.otherElements["result.statusBanner.pass"].waitForExistence(timeout: 5))
    }

    func testWrongBarcodeScanShowsFailResultWithMismatch() {
        let app = launchedApp(fixtureScenario: .wrongBarcode)
        app.tabBars.buttons["tab.home"].tap()
        let firstGoldenLabelCell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'home.goldenLabel.'")).firstMatch
        guard firstGoldenLabelCell.waitForExistence(timeout: 5) else {
            XCTFail("No seeded golden label found")
            return
        }
        firstGoldenLabelCell.tap()
        XCTAssertTrue(app.otherElements["result.statusBanner.fail"].waitForExistence(timeout: 5))
    }

    func testEmptyRecognitionShowsInsufficientData() {
        let app = launchedApp(fixtureScenario: .emptyRecognition)
        app.tabBars.buttons["tab.home"].tap()
        let firstGoldenLabelCell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'home.goldenLabel.'")).firstMatch
        guard firstGoldenLabelCell.waitForExistence(timeout: 5) else {
            XCTFail("No seeded golden label found")
            return
        }
        firstGoldenLabelCell.tap()
        XCTAssertTrue(app.otherElements["result.statusBanner.insufficientData"].waitForExistence(timeout: 5))
    }

    func testSettingsAppearancePickerExists() {
        let app = launchedApp()
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.buttons["settings.appearancePicker"].waitForExistence(timeout: 5) ||
                      app.otherElements["settings.appearancePicker"].waitForExistence(timeout: 5))
    }
}
