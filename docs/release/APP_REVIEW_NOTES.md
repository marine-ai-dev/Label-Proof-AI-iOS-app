# App Review Notes — LabelProof 1.0

Prepared for pasting into App Store Connect's "Notes for Review" field.
See `docs/app-store/metadata.md` for the original version; this is the
re-verified copy after this release-hardening pass.

## Account / login

None. LabelProof has no account system, no login, no server component —
there is nothing to authenticate against and no backend to reach for
review.

## How to test the core flow without printed packaging on hand

1. Launch the app.
2. Go to **Settings → "Reset Demo Data"** and confirm. This populates
   three fictional golden labels (Blue Valley Honey, Northpeak Trail Mix,
   Sunrise Oats) and matching history entries — clearly labeled in the UI,
   not a hidden debug feature.
3. Go to **Home**, tap any golden label to open the Scanner.
4. Tap **"Import Photo"** and pick any photo (even a blank one) from the
   Photos library — this exercises the exact same on-device Vision OCR +
   barcode + `LabelValidator` pipeline as the live camera path. A
   blank/text-free photo correctly produces an "Insufficient data" result,
   never a false PASS or FAIL.
5. Live camera scanning ("Scan with Camera") requires a physical device
   with a camera; the Simulator shows a "camera unavailable" message and
   reviewers should use Import Photo instead — this is expected, not a bug.

## App Review risk self-audit performed in this pass

- No placeholder/"Coming Soon" screens exist anywhere.
- No dead navigation — every tab, button, and destructive action was
  exercised live in Simulator QA (see `RELEASE_READINESS.md`).
- No permission is requested without a corresponding, immediately-visible
  feature: Camera is the only permission requested, and it's requested
  only when the user taps "Scan with Camera."
- No hidden debug menu or QA toggle is reachable from the shipped UI. The
  one launch-argument-gated fixture path (`UITEST_MODE`) requires an
  explicit process launch argument that SpringBoard/TestFlight/App Store
  launches never pass — empirically confirmed in this pass by installing
  the Release build fresh and launching it with no arguments (clean empty
  state, no seeded content; see `RELEASE_READINESS.md`).
- No private API usage — only public Vision, VisionKit, SwiftData, SwiftUI,
  PhotosUI APIs.
- No external payment link, no misleading claim, no broken external URL
  (privacy/support URLs are prepared under `docs/site/` — see
  `KNOWN_LIMITATIONS.md` for the one remaining action: publishing them to a
  public URL, which needs the account holder's hosting choice).

## Known non-blocking limitation

Live camera scanning cannot be exercised in the Simulator (VisionKit's
`DataScannerViewController` requires physical camera hardware) — this is
standard Apple platform behavior affecting every app that uses this API,
not a defect in LabelProof.
