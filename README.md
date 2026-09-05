# 🏷️ LabelProof — On-Device Packaging Label Verifier

LabelProof is a free, open-source iOS app that scans a packaging label and
checks it against a reference ("golden label") — product name, weight,
barcode, and required phrases — entirely on your device. No account, no
internet connection, no cloud AI.

## ✨ Features

- 📷 **Scan or import** — live camera scanning via VisionKit, or import a
  photo for deterministic, repeatable testing.
- 🔍 **On-device OCR + barcode recognition** — powered by Apple's Vision
  framework, never a cloud service.
- ✅ **Deterministic PASS/FAIL** — clear, rule-based validation with exact
  field-by-field mismatch reporting. No AI guesswork, no fuzzy barcode
  matching.
- 🧭 **"Insufficient data" as a first-class result** — a blank or unreadable
  scan is reported honestly, never silently marked PASS or FAIL.
- 🗂️ **Golden Labels library** — create, edit, and delete reference labels
  with expected product name, weight/quantity, barcode, and required
  phrases.
- 🕘 **Local history** — a compact, on-device record of past verifications
  (text/barcode data only — never full images).
- 🎨 **Liquid Glass design** — a polished, project-local SwiftUI design
  layer with Light, Dark, and true-black OLED appearances, plus 5 accent
  colors.
- 🌍 **Localized** — English and Ukrainian out of the box.
- ♿️ **Accessible** — VoiceOver labels, Dynamic Type support, non-color-only
  PASS/FAIL indication, Reduce Motion-safe.
- 🔒 **Privacy-first** — no account, no login, no analytics, no tracking, no
  cloud AI, no networking code at all. See [docs/PRIVACY.md](docs/PRIVACY.md).

## 🧱 Architecture

LabelProof splits into a pure-Swift core package and a SwiftUI app target:

```
Sources/LabelProofCore/   # Foundation-only: models, validation engine, service protocols
Tests/LabelProofCoreTests/# XCTest suite for the core (swift test)
App/LabelProof/           # SwiftUI + Vision + VisionKit + SwiftData app target
AppUITests/                # XCUITest scaffolding, fixture-driven
docs/                      # Architecture, privacy, App Store, local QA docs
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full breakdown,
including why the validation engine is a standalone Swift package, how
dependency injection isolates test fixtures from production code, and the
documented "Liquid Glass" design-system extraction path.

## 🚀 Getting started

This repository does not commit a generated `.xcodeproj` (see
`.gitignore`) — generate one locally with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) or by hand. Full,
step-by-step instructions — including simulator smoke tests, visual QA
matrix, screenshot plan, and physical-device camera verification — are in
[docs/LOCAL_QA_HANDOFF.md](docs/LOCAL_QA_HANDOFF.md).

Quick start for the core logic only (no Xcode required, if you have the
`swift` CLI):

```bash
swift build --package-path .
swift test --package-path .
```

> **Note:** this project was authored in a cloud sandbox without Xcode,
> Simulator, or the `swift` CLI available, so the commands above have not
> actually been executed in this repository's history yet — they are the
> first thing to run on a real Mac. See
> [docs/LOCAL_QA_HANDOFF.md](docs/LOCAL_QA_HANDOFF.md) for full context.

## 🧪 Testing

- **Unit tests** (`Tests/LabelProofCoreTests`): cover the deterministic
  validation engine — full match, wrong product name, wrong weight, wrong
  barcode, missing required phrase, multiple mismatches, and empty/blank
  recognition.
- **UI tests** (`AppUITests`): drive the app end-to-end using launch-argument
  fixture injection (`UITEST_FIXTURE_SCENARIO`) — no real camera or Vision
  calls happen in these tests, and there is no user-facing "fake scan"
  control in the shipped app.

## 🔐 Privacy

Read the full breakdown in [docs/PRIVACY.md](docs/PRIVACY.md). In short:
nothing ever leaves your device.

## 🗺️ App Store

Metadata, reviewer notes, screenshots plan, and the submission checklist
live in [docs/app-store/metadata.md](docs/app-store/metadata.md).

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please read the ground rules — this
project intentionally stays on-device, account-free, and free of
analytics/tracking by design.

## 🛡️ Security

See [SECURITY.md](SECURITY.md) for how to report a vulnerability.

## 📄 License

MIT — see [LICENSE](LICENSE).
