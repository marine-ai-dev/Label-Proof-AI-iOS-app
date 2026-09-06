# App Store Metadata — LabelProof 1.0

The full, previously-prepared metadata (App name, subtitle, promotional
text, description, keywords, category, reviewer notes, submission
checklist) lives in [`docs/app-store/metadata.md`](../app-store/metadata.md)
and was re-reviewed as part of this pass — no inaccurate or invented claims
were found (no fabricated user counts, testimonials, awards, or
functionality that doesn't exist). Summary below; see that file for the
verbatim text to paste into App Store Connect.

## Core facts (verified against the actual app)

- **App name:** LabelProof
- **Subtitle:** On-Device Label Checker
- **Version:** 1.0 (build 1)
- **Category:** Business (primary) / Utilities (secondary)
- **Price:** Free — no IAP, no subscriptions, no ads (see `MONETIZATION.md`)
- **Core workflow (verified live in this pass, see `RELEASE_READINESS.md`):**
  create a Golden Label (expected product name, weight/quantity, barcode,
  required phrases) → scan or import a package photo → get PASS / FAIL /
  Insufficient Data with field-by-field mismatch detail → review local
  History.
- **Languages:** English, Ukrainian (verified — no other `.lproj` exists;
  see `docs/release/PHYSICAL_DEVICE_QA.md` and localization QA in
  `RELEASE_READINESS.md` for the ru/be/fa-IR exclusion check).

## What's New — 1.0

> Initial release: create golden labels, scan or import packaging photos,
> and get instant on-device PASS/FAIL verification with exact mismatch
> details. Live camera scanning and photo import both use Apple's
> on-device Vision framework — no account, no internet connection, no data
> ever leaves your device. Light, Dark, and Black appearances with 5 accent
> colors. Available in English and Ukrainian.

## Truthfulness check performed

- No user counts, testimonials, or awards are mentioned anywhere in the
  metadata — none exist to cite.
- No AI/cloud-inference claim is made; the copy explicitly and accurately
  states on-device Vision framework use only.
- No security/compliance certification is claimed beyond what's actually
  implemented (deterministic local processing, no data collection).
- Reviewer notes (in `docs/app-store/metadata.md`) accurately describe how
  to test the app without physical packaging (Settings → "Reset Demo
  Data", then Import Photo with any photo) — this was re-verified live in
  this pass and works exactly as described.
