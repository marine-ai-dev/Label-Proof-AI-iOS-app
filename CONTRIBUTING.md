# Contributing to LabelProof

Thanks for your interest in contributing! LabelProof is a free, open-source,
privacy-first iOS app, and contributions are welcome.

## Ground rules

- **Privacy-first, always.** No networking code, no analytics/tracking SDKs,
  no cloud OCR/AI, no account/login system, no custom-trained ML models. Pull
  requests that introduce any of these will be declined.
- **On-device only.** All recognition must go through Apple's Vision /
  VisionKit frameworks behind the `OCRServicing` / `BarcodeServicing`
  protocols in `LabelProofCore`.
- **Deterministic validation.** The verification engine
  (`LabelValidator` in `Sources/LabelProofCore/Validation.swift`) must remain
  pure, deterministic, and unit-testable — no fuzzy matching, no
  probabilistic scoring, no ML-based comparison.
- **Localization.** English (`en`) and Ukrainian (`uk`) are the supported
  locales. Do **not** add Russian (`ru`), Belarusian (`be`), or Persian/Iran
  (`fa-IR`) localizations to this project.

## Project layout

See `docs/ARCHITECTURE.md` for the full breakdown of `Sources/LabelProofCore`
(pure Swift/Foundation, testable with `swift test`) vs. `App/LabelProof`
(SwiftUI/Vision/VisionKit/SwiftData app target).

## Development workflow

1. Fork and branch from `main`.
2. For core logic changes: add/update tests in `Tests/LabelProofCoreTests`
   and run `swift test --package-path .` locally.
3. For app/UI changes: you'll need Xcode on macOS — see
   `docs/LOCAL_QA_HANDOFF.md` for generating a local Xcode project (none is
   committed to the repo).
4. Keep PRs focused — this project intentionally avoids feature creep beyond
   the "scan → validate → PASS/FAIL → history" core loop.
5. Update relevant docs (`docs/ARCHITECTURE.md`, `docs/PRIVACY.md`) when
   behavior changes.

## Commit messages

Write clear, imperative commit messages describing what changed and why.

## Reporting bugs / requesting features

Open a GitHub issue. Include repro steps, iOS version, and device/Simulator
details where relevant.

## Security issues

Do not open a public issue for security/privacy vulnerabilities — see
`SECURITY.md`.
