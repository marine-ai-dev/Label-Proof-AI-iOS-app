# Local QA Handoff (macOS + Xcode required)

This project was built in a cloud sandbox with **no macOS, no Xcode, no iOS
Simulator, and no physical device**. Everything below must be done on a real
Mac before release. Nothing in this checklist has been executed — treat every
step as unverified until you run it yourself.

## 1. Prerequisites

- macOS with Xcode 15.4+ (Vision/VisionKit APIs used here — `DataScannerViewController`
  quality-level/guidance options, current `VNRecognizeTextRequest` API — target
  iOS 17+; adjust the deployment target in `Package.swift`/project settings if
  you need to support earlier iOS).
- Command Line Tools installed (`xcode-select --install`).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
  or willingness to create the Xcode project by hand — **no `.xcodeproj` is
  committed to this repo** (see step 3).

## 2. Fresh checkout

```bash
git clone https://github.com/marine-ai-dev/Label-Proof-AI-iOS-app.git
cd Label-Proof-AI-iOS-app
git checkout claude/labelproof-ondevice-verifier-e8gqyh
```

## 3. Generate/create the Xcode project for the App target

`App/LabelProof` is a plain source tree (no `.xcodeproj`), by design, to keep
generated project files out of version control (see `.gitignore`). Two ways
to get it into Xcode:

**Option A — XcodeGen (recommended).** Create a `project.yml` at repo root:

```yaml
name: LabelProof
options:
  bundleIdPrefix: com.labelproof
targets:
  LabelProof:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources: [App/LabelProof]
    info:
      path: App/LabelProof/Resources/Info.plist
      properties:
        CFBundleDisplayName: LabelProof
        NSCameraUsageDescription: "LabelProof uses the camera to scan packaging labels on-device for verification. No images are uploaded or shared."
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.labelproof.app
        SWIFT_VERSION: "5.9"
        TARGETED_DEVICE_FAMILY: "1"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    dependencies:
      - package: LabelProofCore
  LabelProofUITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "17.0"
    sources: [AppUITests]
    dependencies:
      - target: LabelProof
packages:
  LabelProofCore:
    path: .
```

Then: `xcodegen generate` and open `LabelProof.xcodeproj`.

**Option B — manual Xcode project.** File > New > Project > iOS App
(SwiftUI, Swift), add `App/LabelProof` as the source folder, add
`App/LabelProof/Resources/Info.plist` as the target's Info.plist, add the
local Swift package (`File > Add Package Dependencies… > Add Local…`,
pointing at the repo root, product `LabelProofCore`), and add a new UI
Testing bundle target with `AppUITests` as its source.

In both cases: make sure `App/LabelProof/Resources/PrivacyInfo.xcprivacy` and
`Assets.xcassets` are included in the app target's Copy Bundle Resources /
asset catalog compilation.

## 4. Resolve dependencies

There are no third-party dependencies — only the local `LabelProofCore`
Swift package. Xcode resolves it automatically on first build/open.

## 5. Build the app

```bash
xcodebuild -project LabelProof.xcodeproj -scheme LabelProof \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Fix any compiler errors surfaced here first — this repo's Swift was authored
without a compiler available, so treat the first local build as the real
first compilation check.

## 6. Run the Swift Package unit tests (pure logic, no simulator needed)

```bash
swift test --package-path .
```

This exercises `Tests/LabelProofCoreTests` (`TextNormalizerTests`,
`LabelValidatorTests`, `ExtractedLabelDataTests`) against `LabelProofCore`
directly. This is the fastest correctness signal and does not require a
Simulator.

## 7. Run the XCUITests

```bash
xcodebuild test -project LabelProof.xcodeproj \
  -scheme LabelProof \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:LabelProofUITests
```

These tests launch with `UITEST_MODE` plus `UITEST_RESET_STATE=1`,
`UITEST_SEED_DEMO_DATA=1`, and (per test) `UITEST_FIXTURE_SCENARIO=<scenario>`
— see `AppUITests/LaunchArguments.swift` and
`App/LabelProof/Services/LaunchEnvironment.swift`. No camera/Vision calls
happen in these tests; scan results come from `FixtureLabelScanService`.

## 8. Simulator smoke test checklist (manual)

- [ ] App launches to Home tab without crashing.
- [ ] Golden Labels tab: create a golden label, edit it, delete it; empty
      state appears when list is empty.
- [ ] Home tab: tapping a golden label opens the Scanner sheet.
- [ ] Scanner: "Import Photo" opens `PhotosPicker`; picking a photo of a real
      or printed label runs OCR/barcode recognition and navigates to Result.
      (Simulator has no camera — live `DataScannerViewController` scanning
      cannot be smoke-tested here; see step 10.)
- [ ] Result screen shows PASS with a green checkmark-seal icon for a
      correct label; FAIL with a red xmark-seal and a mismatch list for an
      incorrect one; "Insufficient data" with an orange question-mark icon
      for a blank/unreadable photo.
- [ ] History tab lists past verifications; swipe-to-delete works; Settings
      "Clear All History" prompts for confirmation before clearing.
- [ ] Settings: Appearance (System/Light/Dark/Black) and Accent color
      pickers visibly change the UI; "Reset Demo Data" prompts for
      confirmation, then repopulates golden labels + history with the
      fictional demo data in `LabelProofCore.DemoData`.
- [ ] About & Privacy screen text renders and matches `docs/PRIVACY.md`
      claims.

## 9. Visual QA matrix

Check the following combinations for layout/contrast issues, at minimum on
one compact and one regular-width simulator:

| Appearance | Accent | Locale | Dynamic Type |
|---|---|---|---|
| Light | Teal | en | Default |
| Dark | Indigo | en | Default |
| Black | Coral | en | Default |
| Light | Mint | uk | Default |
| Dark | Amber | uk | XL (Accessibility) |
| System | Teal | en | XXL (Accessibility) |

Switch locale via Scheme > Options > App Language = Ukrainian, or
Simulator > Settings > General > Language & Region.
Switch Dynamic Type via Simulator > Settings > Accessibility > Display & Text
Size > Larger Text.

## 10. Screenshot plan

Capture on at least one 6.7" and one 5.5" (or current required App Store
sizes) simulator, Light and Dark:
1. Home tab with 2-3 golden labels.
2. Golden Label create/edit form.
3. Scanner screen (Import Photo state).
4. Result screen — PASS.
5. Result screen — FAIL with 2+ mismatches visible.
6. History tab with mixed PASS/FAIL/Insufficient entries.
7. Settings — Appearance/Accent section.

Save under a local (git-ignored) `screenshots/` directory; do not commit raw
simulator screenshots into the repo unless curating a small final set for
App Store Connect upload.

## 11. Physical device camera verification

Required because Simulator cannot exercise the camera:
- [ ] Build & run on a physical iPhone (iOS 17+) via Xcode.
- [ ] Grant camera permission when prompted; verify the system permission
      dialog text matches `NSCameraUsageDescription` in `Info.plist`.
- [ ] Point the camera at a printed label (or another screen showing one);
      confirm `DataScannerViewController` highlights recognized text/barcodes
      live (VisionKit's built-in highlighting, `isHighlightingEnabled: true`).
- [ ] Capture and confirm the same OCR+barcode+validation pipeline produces a
      sensible Result screen.
- [ ] Deny camera permission once and confirm the app shows a clear, non-crashing
      fallback (rely on `scanner.cameraUnavailable` messaging / Import Photo
      path) — verify/extend `ScannerView`'s handling here if the current
      messaging isn't sufficient after real device testing.

## 12. Release / archive / signing checklist

- [ ] Set a real bundle identifier, signing team, and provisioning in Xcode
      (Signing & Capabilities).
- [ ] Bump `CFBundleShortVersionString`/`CFBundleVersion` in `Info.plist` (or
      via `xcodegen`/Xcode build settings) for each submission.
- [ ] `Product > Archive`, validate, and upload via Xcode Organizer or
      `xcodebuild -exportArchive`.
- [ ] Confirm `PrivacyInfo.xcprivacy` is present in the archived app bundle
      (`unzip -l LabelProof.ipa | grep PrivacyInfo`).
- [ ] Grep the archived binary/bundle for unexpected network frameworks as a
      final privacy sanity check:
      `strings LabelProof.app/LabelProof | grep -iE "http|https://" ` should
      show nothing beyond incidental Swift runtime/system framework strings.
- [ ] Fill in App Store Connect metadata from `docs/app-store/` and complete
      the submission checklist there.

## 13. Final git status check

Before/after any local fixes:

```bash
git status
git log --oneline -5
```

Confirm the branch is `claude/labelproof-ondevice-verifier-e8gqyh` (or your
working branch), all intended changes are committed, and nothing generated
locally (`*.xcodeproj/`, `.build/`, `DerivedData/`) is accidentally staged —
these are already covered by `.gitignore`.
