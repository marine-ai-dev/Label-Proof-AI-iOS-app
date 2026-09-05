# App Store Metadata

## App name
LabelProof

## Subtitle (30 chars max)
On-Device Label Checker

## Promotional text (170 chars max)
Scan packaging labels and instantly verify product name, weight, barcode,
and required phrases against your reference — 100% on-device, no account.

## Description

LabelProof helps you verify that a printed packaging label matches what it's
supposed to say — entirely on your device, with no account, no internet
connection required, and no data ever leaving your phone.

**How it works**
1. Create a "golden label" with the expected product name, weight/quantity,
   barcode, and any required phrases (allergen statements, certifications,
   country of origin, etc.).
2. Scan a package with your camera, or import a photo.
3. LabelProof uses Apple's on-device Vision framework to read the text and
   barcode, then checks it against your golden label using clear,
   deterministic rules — never AI guesswork.
4. Get an instant PASS or FAIL, with the exact field, expected value, and
   what was actually found for every mismatch.

**Built for accuracy and trust**
- Barcode matching is always exact — never "close enough."
- Product name and required-phrase matching ignores harmless whitespace/case
  differences, never anything more.
- Weight/quantity matching tolerates spacing differences ("500 g" vs
  "500g") without silently accepting a different value.
- When a scan doesn't produce enough readable text or barcode data,
  LabelProof tells you clearly instead of guessing at a result.

**Built for privacy**
- No account, no login, no sign-up.
- No analytics, no tracking, no third-party SDKs.
- No cloud OCR or cloud AI — all recognition happens on your device using
  Apple's Vision framework.
- Your golden labels and verification history stay on your device.

**Local history**
Keep a compact history of past verifications (text and barcode results only
— never full images) so you can review or export what was checked.

LabelProof is free, and its source code is open — see the About screen for
details.

## Keywords (100 chars max, comma-separated)
label,barcode,scan,verify,packaging,ocr,quality,check,compliance,inspection

## Category
Primary: Business
Secondary: Utilities

## Age rating notes
No objectionable content: no user-generated content shared with others, no
gambling, no mature/suggestive themes, no unrestricted web access. Expected
rating: 4+.

## App Privacy (App Store Connect "App Privacy" questionnaire answers)

**Data collection: "No, we do not collect data from this app."**

Rationale (see `docs/PRIVACY.md` for the full audit):
- No networking code exists in the app at all.
- No analytics/crash-reporting/advertising SDKs are integrated.
- All data (golden labels, verification history, settings) is stored only in
  local SwiftData storage and `UserDefaults`, never transmitted.
- Camera access is used only for on-device Vision processing of the live
  camera feed; no captured frames are stored or transmitted.

If App Store Connect requires per-category answers even with "no collection"
selected overall, confirm each category (Contact Info, Health & Fitness,
Financial Info, Location, Sensitive Info, Contacts, User Content, Browsing
History, Search History, Identifiers, Purchases, Usage Data, Diagnostics,
Other Data) is left unchecked/"Not Collected."

## Permission explanations (shown to reviewers / users)

- **Camera** — "LabelProof uses the camera to scan packaging labels
  on-device for verification. No images are uploaded or shared." Matches
  `NSCameraUsageDescription` in `Info.plist` exactly.

## Reviewer notes

- The app requires no account and has no server component — there is nothing
  to log into and no backend to reach for review.
- To test the core flow without printed packaging on hand: go to Settings >
  "Reset Demo Data" to populate three fictional golden labels, then use Home
  > tap a golden label > Scanner > "Import Photo" with any photo (even a
  blank one) to see a Result screen. A blank/text-free photo correctly
  produces an "Insufficient data" result rather than a false PASS or FAIL.
- Live camera scanning requires a physical device with a camera; the
  Simulator will show the "camera unavailable" message and reviewers should
  use the Import Photo path instead.

## v1.0 release notes

Initial release: create golden labels, scan or import packaging photos, get
instant on-device PASS/FAIL verification with exact mismatch details, and
review local scan history. Light, Dark, and Black appearances with 5 accent
colors. Available in English and Ukrainian.

## Screenshot plan / matrix

See `docs/LOCAL_QA_HANDOFF.md` section 10 for the exact screen list and
device/appearance matrix.

Captured so far, under `docs/app-store/screenshots/iphone17-6.3in-en-light/`
(Home, Result PASS, Result FAIL, History, Settings — Light appearance, Teal
accent, English, on the iPhone 17 Simulator, iOS 26.5): a QA-verified preview
set, **not** yet the official App Store Connect submission sizes. App Store
Connect requires screenshots at specific display-size classes (currently
6.9" and 6.5", plus 5.5" if targeting older devices) — recapture this same
matrix on an iPhone 17 Pro Max (6.9") and, if supporting smaller phones, a
5.5"-class device/simulator before uploading.

## Icon checklist

- [x] 1024×1024 App Store marketing icon generated
      (`App/LabelProof/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`),
      via `scripts/generate_app_icon.py` (Pillow). Single-size universal
      appiconset (`Contents.json`), relying on Xcode 14+/iOS 17+ automatic
      icon generation from the 1024×1024 source — confirm this renders
      correctly for all required sizes once opened in Xcode locally.
- [x] Visually reviewed at actual Home Screen render sizes (1024, 180, 120,
      58px) on a real Mac: clean checkmark-in-circle + barcode mark on a
      teal gradient, legible and distinct down to the smallest (Settings)
      size. Accepted as release-quality, not a placeholder.
- [x] Confirmed no alpha channel (`sips -g hasAlpha` → `no`) and
      `ASSETCATALOG_COMPILER_APPICON_NAME` = `AppIcon` is set in
      `project.yml`/build settings.

## Submission checklist

- [ ] Local QA handoff (`docs/LOCAL_QA_HANDOFF.md`) fully completed.
- [ ] Version/build numbers bumped.
- [ ] Screenshots captured per the matrix above and uploaded.
- [ ] App Privacy questionnaire answered per this document.
- [ ] Age rating questionnaire completed (expect 4+).
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption` = `false` already
      set in `Info.plist` (no custom encryption beyond standard OS-provided
      HTTPS/TLS, and no networking exists anyway).
- [ ] Reviewer notes pasted into App Store Connect from this document.
- [ ] TestFlight build validated before public submission.
