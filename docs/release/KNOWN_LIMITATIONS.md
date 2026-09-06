# Known Limitations — LabelProof 1.0

## Product-level (by design, not defects)

- **Live camera scanning cannot be tested in the Simulator.**
  `DataScannerViewController` requires physical camera hardware; the
  Simulator path correctly shows a "camera unavailable, use Import Photo"
  message. This is standard behavior for any app using this API.
- **Barcode/weight/name matching is deterministic, never fuzzy.** This is
  an intentional product decision (see `docs/ARCHITECTURE.md`), not a
  limitation to fix — a barcode one digit off is a real mismatch, not a
  "close enough" pass.

## Engineering notes reviewed and accepted as-is (not release-blocking)

- `LabelProofApp.init()` calls `fatalError` if `ModelContainer`
  initialization throws. This is Apple's own standard SwiftData boilerplate
  pattern; for a v1.0 app with no prior on-disk schema to migrate away
  from, this path is only reachable by a corrupted installation, not a
  realistic user scenario. Documented here rather than papered over with a
  fake recovery UI that would itself be untested and potentially worse.
- The `Reset Demo Data` action in Settings is an intentional, visibly
  labeled product/reviewer-aid feature (populates three fictional golden
  labels), not a hidden debug leak — see `APP_REVIEW_NOTES.md`. It is
  reachable by real users, by design, so a new user or reviewer without
  physical packaging on hand can try the app immediately.
- The `UITEST_MODE` fixture-injection code path compiles into Release
  builds (it is not `#if DEBUG`-gated) but is unreachable without an
  explicit process launch argument that no normal launch path (SpringBoard,
  TestFlight, or the App Store) ever passes. Empirically confirmed in this
  pass: a fresh Release install launched with no arguments shows a clean,
  unseeded empty state (see `RELEASE_READINESS.md`).

## Screenshot sizing

`docs/app-store/screenshots/iphone17-6.3in-en-light/` and
`docs/release/screenshots/iphone15qa-en-light/` are QA/preview screenshot
sets captured on 6.3"-class simulators, not App Store Connect's currently
required submission display classes (6.9"/6.5", plus 5.5" if supporting
older devices). Re-capture on an iPhone 17 Pro Max (6.9", already confirmed
to render correctly in this pass — see `06_home_17promax.png`) and, if
needed, a 5.5"-class device before uploading. See
`APP_STORE_SUBMISSION_CHECKLIST.md`.

## Site/URLs

`docs/site/privacy.html` and `docs/site/support.html` are prepared locally
but not published to a public URL — publishing requires the account
holder's hosting choice (e.g. GitHub Pages) and is out of scope for this
pass to perform unilaterally. See `KNOWN_LIMITATIONS.md`'s counterpart note
in `APP_STORE_SUBMISSION_CHECKLIST.md`.

## Apple account state

No Apple Developer Program membership exists yet on this Mac (only a
Personal Team, `LU4PK425G3`). This is the sole reason an `app-store-connect`
export fails — confirmed with the exact Xcode error in
`APP_STORE_SUBMISSION_CHECKLIST.md`. Nothing else blocks the Release
Candidate.
