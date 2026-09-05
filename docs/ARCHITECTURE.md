# Architecture

LabelProof is split into two layers so the deterministic verification logic
is testable independent of any Apple UI/Vision framework, and so it can
eventually move into a shared package across projects.

```
Label-Proof-AI-iOS-app/
├── Package.swift                  # SwiftPM manifest for LabelProofCore
├── Sources/LabelProofCore/        # Pure Foundation, platform-agnostic core
├── Tests/LabelProofCoreTests/     # XCTest suite for the core (swift test)
├── App/LabelProof/                # Xcode app target source tree
│   ├── App/                       # @main entry point
│   ├── Models/                    # SwiftData @Model wrappers around Core types
│   ├── Services/                  # Vision/VisionKit-backed service impls
│   ├── ViewModels/                # SwiftData-backed stores (CRUD)
│   ├── Views/                     # SwiftUI screens + design system
│   └── Resources/                 # Info.plist, PrivacyInfo.xcprivacy, assets, strings
├── AppUITests/                    # XCUITest scaffolding (fixture-driven)
└── docs/                          # Architecture, privacy, App Store, QA docs
```

## Why a Swift Package for the core

`LabelProofCore` (Models, deterministic validation, service protocols,
fixtures) has **zero** dependency on Vision, VisionKit, SwiftUI, SwiftData,
or UIKit — only `Foundation`. This means:

- `swift build` / `swift test` can validate the core's correctness on any
  platform with a Swift toolchain (including Linux CI), independent of Xcode.
- The validation engine — the part of the app with the strongest correctness
  requirements — has the smallest, most auditable dependency surface.
- Framework-specific code (Vision OCR, VisionKit barcode/scanner, SwiftData
  persistence, SwiftUI views) lives entirely in `App/LabelProof`, isolated
  behind `#if canImport(Vision)` / `#if canImport(UIKit)` guards where it
  bridges back into `LabelProofCore` types.

**Sandbox note:** this cloud environment has no `swift` CLI installed
(`which swift` returns nothing), so `swift build`/`swift test` could not
actually be executed or verified here. The package is structured to be
correct and idiomatic SwiftPM; running the test suite locally is the first
item in `docs/LOCAL_QA_HANDOFF.md`.

## Domain model & validation flow

1. `GoldenLabel` — the reference/expected values for one product.
2. `ExtractedLabelData` — one scan's OCR text lines + deduplicated barcode
   observations, tagged with a `ScanSourceType` (live camera / imported image
   / fixture).
3. `LabelValidator.validate(scan:against:)` — pure function producing a
   `ValidationResult` with a `VerificationStatus` (`pass` / `fail` /
   `insufficientData`) and a list of `LabelMismatch` values, each carrying
   the field, expected value, actual value, and a structured `MismatchReason`.

Rules, all deterministic (no fuzzy matching, no ML):
- **Product name**: whitespace-collapsed, case-insensitive substring match.
- **Weight/quantity**: same as product name, plus removal of the single space
  between a digit and a following unit letter (`"500 g"` == `"500g"`); no
  unit conversion is performed.
- **Barcode**: exact match only (trimmed, case-sensitive) against decoded
  barcode payloads. Never fuzzy.
- **Required phrases**: each phrase is checked individually so a result can
  report exactly which phrase(s) are missing.
- **Insufficient data**: when a scan has no text and no barcodes at all
  (`ExtractedLabelData.isEmptyRecognition`), the result status is
  `.insufficientData` rather than `.fail` — this is a distinct explicit
  domain state, not inferred from an empty mismatch list.

## Scan pipeline & dependency injection

`OCRServicing` and `BarcodeServicing` are protocols in `LabelProofCore`.
Production implementations (`VisionOCRService`, `VisionBarcodeService` in
`App/LabelProof/Services`) wrap `VNRecognizeTextRequest` and
`VNDetectBarcodesRequest` respectively, composed into a
`CompositeLabelScanService` conforming to `LabelScanServicing`.

`ScanServiceFactory.makeScanService(goldenLabel:)` is the single seam that
chooses between the real Vision-backed service and a deterministic
`FixtureLabelScanService`. The switch is driven only by
`LaunchEnvironment.forcedFixtureScenario`, which reads the
`UITEST_FIXTURE_SCENARIO` process environment variable set exclusively by
XCUITest launch configuration (`AppUITests/LaunchArguments.swift`) — there is
no user-facing "fake scan" button anywhere in production UI, and this path is
inert unless the app is launched by a test runner with that environment
variable set.

Both the live-camera path (`DataScannerRepresentable`, VisionKit
`DataScannerViewController`) and the image-import path (`PhotosPicker`)
converge on the same `LabelScanServicing.scan(imageData:source:)` call, so
results are validated identically regardless of source. `DataScannerRepresentable`
is only usable on a physical device/Simulator with camera support and could
not be exercised in this sandbox.

## Persistence

`GoldenLabel` and `VerificationRecord` (from `LabelProofCore`) are mirrored by
SwiftData `@Model` classes (`GoldenLabelRecord`, `VerificationHistoryRecord`)
in the app target, with explicit conversion helpers (`asDomainModel`,
`update(from:)`). History records never store the captured image — only the
extracted text/barcode data and validation outcome — to minimize on-device
storage. See `docs/PRIVACY.md`.

## Design system: "Liquid Glass" (project-local, extraction candidate)

`App/LabelProof/Views/Design/AppTheme.swift` centralizes color, material,
spacing, and radius tokens, plus `AppAppearance` (System/Light/Dark/Black —
Black is a true-OLED-style palette, distinct from Dark, not just Dark at a
different opacity) and `AppAccent` (5 accent colors). `GlassCard` is the
reusable translucent-material card component used throughout the UI.

This is deliberately a **project-local** design layer, not a separate Swift
package, but every token and component is written with no other
LabelProof-specific coupling so it can be lifted into a future shared
`DesignKit` package with minimal changes — extraction candidates are the
`AppAppearance`, `AppAccent`, `AppTheme` spacing/radius enums, and `GlassCard`.

## Localization: LocalizationKit gap

No shared `LocalizationKit` package exists in this (empty, freshly created)
repository or any discoverable parent directory. Per spec, this project ships
a minimal localization boundary instead: standard Apple `.strings` files for
`en` (base) and `uk`, under `App/LabelProof/Resources/{en,uk}.lproj/`. All
user-facing strings go through `String(localized:)` / SwiftUI's automatic
`LocalizedStringKey` resolution against these tables.

**Documented gap:** if/when a shared `LocalizationKit` exists for other
LabelProof-family apps, this project's `Localizable.strings` keys and the
`String(localized:)` call sites should migrate to it with no other code
changes, since no other part of the app talks to localization directly.

**Do not** add Russian (`ru`), Belarusian (`be`), or Persian/Iran (`fa-IR`)
localizations to this project, per explicit product requirement.

## What was NOT verified in this sandbox

This environment has no Xcode, no macOS, no iOS Simulator, and no physical
device. The following were written to be structurally correct but were
**not** built, run, or visually verified:
- Any `xcodebuild` build of the `App/LabelProof` target (no `.xcodeproj`
  exists yet — see `docs/LOCAL_QA_HANDOFF.md` for generating one).
- `swift build` / `swift test` for `LabelProofCore` (`swift` CLI not present
  in this sandbox).
- XCUITest execution.
- Any camera/VisionKit/Vision runtime behavior.
- Any visual/appearance/accessibility QA.

`docs/LOCAL_QA_HANDOFF.md` is the authoritative checklist for completing all
of the above on a real Mac.
