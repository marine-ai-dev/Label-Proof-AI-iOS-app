# App Store Submission Checklist — LabelProof 1.0

## Prepared locally (this pass) — no account access needed

- [x] `docs/release/APP_STORE_METADATA.md` (+ full text in
      `docs/app-store/metadata.md`)
- [x] `docs/release/APP_STORE_PRIVACY_ANSWERS.md`
- [x] `docs/release/APP_PRIVACY_AUDIT.md`
- [x] `docs/release/MONETIZATION.md`
- [x] `docs/release/APP_REVIEW_NOTES.md`
- [x] `docs/release/EXPORT_COMPLIANCE.md`
- [x] `docs/release/AGE_RATING_PREP.md`
- [x] `docs/site/privacy.html`, `docs/site/support.html` (not yet published
      to a public URL — see below)
- [x] Screenshot source sets:
      `docs/app-store/screenshots/iphone17-6.3in-en-light/` (5 images),
      `docs/release/screenshots/iphone15qa-en-light/` (6 images, this pass)
- [x] `docs/release/TESTFLIGHT_CHECKLIST.md`
- [x] Local Release archive succeeded
      (`xcodebuild archive` with Personal Team → **ARCHIVE SUCCEEDED**)

## Verified evidence this pass

- Debug build (Simulator): **BUILD SUCCEEDED**
- Release build (Simulator): **BUILD SUCCEEDED**
- `swift test`: **20/20 passed**
- `xcodebuild test -only-testing:LabelProofUITests` (iPhone 15 QA):
  **6/6 passed**
- Local Release archive (Personal Team `LU4PK425G3`): **ARCHIVE SUCCEEDED**
- Development-signed export (`method: development`): **EXPORT SUCCEEDED**
  (in a prior pass of this project; re-confirmed archive step this pass)
- `app-store-connect` export attempt (this pass, fresh):
  ```
  error: exportArchive Team "Marina Antonevich" does not have permission
  to create "iOS App Store" provisioning profiles.
  error: exportArchive No profiles for 'com.labelproof.app' were found
  ** EXPORT FAILED **
  ```
  This is the **only** archive/export failure, and it is entirely
  account-side (no Apple Developer Program membership yet) — not a code or
  configuration defect.

## ACCOUNT-SIDE ACTIONS REQUIRED (cannot be done locally before enrollment)

1. Enroll in the Apple Developer Program.
2. Select the paid Development Team in Xcode.
3. Register/finalize the App ID if needed.
4. Create the App Store Connect app record.
5. Configure price = Free.
6. Submit App Privacy questionnaire (`APP_STORE_PRIVACY_ANSWERS.md` has the
   prepared answers).
7. Submit age rating questionnaire (`AGE_RATING_PREP.md` has the prepared
   answers, expected 4+).
8. Submit export compliance selection (`EXPORT_COMPLIANCE.md` has the
   prepared answer).
9. Upload screenshots (recapture at the then-current required display
   classes — see `KNOWN_LIMITATIONS.md`).
10. Publish `docs/site/privacy.html` and `docs/site/support.html` to a
    public URL (e.g. GitHub Pages) and enter those URLs in App Store
    Connect. Publishing itself was not performed by this pass (no existing
    repository Pages workflow/authorization to act on).
11. Archive, Validate, Upload (see `TESTFLIGHT_CHECKLIST.md`).
12. Internal TestFlight, final TestFlight QA, submit for App Review,
    release.

Everything else in the local, code-side release pipeline is complete and
requires no further local work before enrollment.
