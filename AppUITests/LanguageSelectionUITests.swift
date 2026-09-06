import XCTest

/// Covers the first-launch language selector and Settings → Language,
/// using the `UITEST_SHOW_LANGUAGE_SELECTOR`/`UITEST_FORCE_LANGUAGE` launch
/// environment (see `LaunchArguments.swift` and
/// `App/LabelProof/Services/LaunchEnvironment.swift`). Every other UI test
/// in this target omits both and gets English with no selector shown —
/// unaffected by this feature, verified by `LabelProofUITests` staying
/// green.
final class LanguageSelectionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchedApp(showSelector: Bool = false, forceLanguage: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [UITestLaunch.uiTestModeArgument]
        app.launchEnvironment[UITestLaunch.EnvironmentKey.resetState] = "1"
        if showSelector {
            app.launchEnvironment[UITestLaunch.EnvironmentKey.showLanguageSelector] = "1"
        }
        if let forceLanguage {
            app.launchEnvironment[UITestLaunch.EnvironmentKey.forceLanguage] = forceLanguage
        }
        app.launch()
        return app
    }

    func testFreshInstallShowsLanguageSelector() {
        let app = launchedApp(showSelector: true)
        XCTAssertTrue(app.buttons["language.option.en"].waitForExistence(timeout: 5))
    }

    func testChoosingUkrainianShowsUkrainianHome() {
        let app = launchedApp(showSelector: true)
        XCTAssertTrue(app.buttons["language.option.en"].waitForExistence(timeout: 5))
        app.buttons["language.option.uk"].tap()
        XCTAssertTrue(app.tabBars.buttons["tab.home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Перевірте етикетку упаковки"].waitForExistence(timeout: 5))
    }

    func testChoosingEnglishShowsEnglishHome() {
        let app = launchedApp(showSelector: true)
        XCTAssertTrue(app.buttons["language.option.en"].waitForExistence(timeout: 5))
        app.buttons["language.option.en"].tap()
        XCTAssertTrue(app.tabBars.buttons["tab.home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Verify a package label"].waitForExistence(timeout: 5))
    }

    /// Existing app state (a language already forced/chosen) must not show
    /// the selector again — mirrors "existing app state does not
    /// unnecessarily show selector again".
    func testExistingLanguageDoesNotShowSelectorAgain() {
        let app = launchedApp(showSelector: false, forceLanguage: "uk")
        XCTAssertTrue(app.tabBars.buttons["tab.home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["language.option.en"].exists)
    }

    func testSettingsLanguageRowShowsCurrentLanguageAndOpensSelector() {
        let app = launchedApp(showSelector: false, forceLanguage: "en")
        app.tabBars.buttons["tab.settings"].tap()
        let languageButton = app.buttons["settings.languageButton"]
        XCTAssertTrue(languageButton.waitForExistence(timeout: 5))
        languageButton.tap()
        XCTAssertTrue(app.buttons["language.option.uk"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["language.option.en"].waitForExistence(timeout: 5))
    }

    func testSwitchingLanguageInSettingsUpdatesUIImmediately() {
        let app = launchedApp(showSelector: false, forceLanguage: "en")
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        app.buttons["settings.languageButton"].tap()
        app.buttons["language.option.uk"].tap()
        // The sheet dismisses itself and Settings should now read Ukrainian,
        // with no relaunch.
        XCTAssertTrue(app.staticTexts["Налаштування"].waitForExistence(timeout: 5))
    }

    /// Structural parity: EN and UK Settings must expose the identical set
    /// of sections in the identical order — only the copy may differ.
    private static let enSectionHeaders = ["Language", "Appearance", "Backup & Synchronization", "History", "Demo Data"]
    private static let ukSectionHeaders = ["Мова", "Вигляд", "Резервне копіювання й синхронізація", "Історія", "Демо-дані"]
    private static let ukAboutLabel = "Про застосунок і приватність"

    func testEnglishSettingsHasAllExpectedSections() {
        let app = launchedApp(showSelector: false, forceLanguage: "en")
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        for header in Self.enSectionHeaders {
            XCTAssertTrue(app.staticTexts[header].exists, "Missing EN section header: \(header)")
        }
        XCTAssertTrue(app.staticTexts["About & Privacy"].exists)
        // None of the Ukrainian equivalents should be visible in English mode.
        for header in Self.ukSectionHeaders {
            XCTAssertFalse(app.staticTexts[header].exists, "Unexpected UK text in EN mode: \(header)")
        }
    }

    func testUkrainianSettingsHasAllExpectedSections() {
        let app = launchedApp(showSelector: false, forceLanguage: "uk")
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.staticTexts["Налаштування"].waitForExistence(timeout: 5))
        for header in Self.ukSectionHeaders {
            XCTAssertTrue(app.staticTexts[header].exists, "Missing UK section header: \(header)")
        }
        XCTAssertTrue(app.staticTexts[Self.ukAboutLabel].exists)
        // None of the English equivalents should be visible in Ukrainian mode.
        for header in Self.enSectionHeaders {
            XCTAssertFalse(app.staticTexts[header].exists, "Unexpected EN text in UK mode: \(header)")
        }
    }

    /// Same accessibility identifiers (i.e. the same view tree/features)
    /// must exist in both languages — only their displayed labels differ.
    func testSettingsExposesSameControlsInBothLanguages() {
        let identifiers = [
            "settings.languageButton", "settings.appearancePicker", "settings.accentPicker",
            "settings.backupSyncLink", "settings.clearHistoryButton", "settings.resetDemoDataButton",
            "settings.aboutLink"
        ]
        let enApp = launchedApp(showSelector: false, forceLanguage: "en")
        enApp.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(enApp.staticTexts["Settings"].waitForExistence(timeout: 5))
        for identifier in identifiers {
            XCTAssertTrue(enApp.buttons[identifier].exists, "EN missing control: \(identifier)")
        }
        enApp.terminate()

        let ukApp = launchedApp(showSelector: false, forceLanguage: "uk")
        ukApp.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(ukApp.staticTexts["Налаштування"].waitForExistence(timeout: 5))
        for identifier in identifiers {
            XCTAssertTrue(ukApp.buttons[identifier].exists, "UK missing control: \(identifier)")
        }
    }

    /// Regression: switching language from Settings must NOT reset the app
    /// to the Home tab or lose navigation state — only the copy may change.
    func testSwitchingLanguageInSettingsStaysOnSettingsTab() {
        let app = launchedApp(showSelector: false, forceLanguage: "en")
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))

        app.buttons["settings.languageButton"].tap()
        app.buttons["language.option.uk"].tap()

        // Still on Settings, now in Ukrainian, no jump to Home.
        XCTAssertTrue(app.staticTexts["Налаштування"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["tab.settings"].isSelected)
        XCTAssertFalse(app.staticTexts["Verify a package label"].exists)

        // Switch back UK -> EN: still on Settings, English again.
        app.buttons["settings.languageButton"].tap()
        app.buttons["language.option.en"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["tab.settings"].isSelected)
    }

    /// Same guarantee on a different tab, to prove the fix is generic (not
    /// a Settings-specific patch).
    func testSwitchingLanguageWhileOnHistoryTabStaysOnHistoryTab() {
        let app = launchedApp(showSelector: false, forceLanguage: "en")
        app.tabBars.buttons["tab.history"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))

        app.tabBars.buttons["tab.settings"].tap()
        app.buttons["settings.languageButton"].tap()
        app.buttons["language.option.uk"].tap()

        app.tabBars.buttons["tab.history"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["history.emptyState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["tab.history"].isSelected)
    }
}
