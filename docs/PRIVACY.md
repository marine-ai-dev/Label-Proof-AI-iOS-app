# Privacy

LabelProof is designed to be privacy-first by construction, not by policy
alone.

## What LabelProof does NOT do

- No account, no login, no user identity of any kind.
- No network requests. There is no networking code anywhere in this
  repository — no `URLSession`, no third-party SDK, no analytics, no crash
  reporter, no ad SDK.
- No cloud OCR or cloud AI inference. All text and barcode recognition uses
  Apple's on-device Vision framework (`VNRecognizeTextRequest`,
  `VNDetectBarcodesRequest`) and VisionKit's `DataScannerViewController`.
- No custom/trained ML model. Only Apple's built-in system Vision models are
  used, as provided by the OS.
- No full images stored. `VerificationRecord`/`VerificationHistoryRecord`
  store only the extracted text lines, decoded barcode payloads, and the
  validation outcome — never the captured photo or camera frame.

## Data that stays on-device

| Data | Where it lives | Ever leaves device? |
|---|---|---|
| Golden labels (name, expected product name/weight/barcode/phrases/notes) | SwiftData (local app storage) | No |
| Verification history (status, mismatches, timestamps) | SwiftData (local app storage) | No |
| Appearance/accent/history-retention settings | `UserDefaults` (local) | No |
| Captured camera frame / imported photo bytes | Held in memory only for the duration of one scan's OCR+barcode pass; not persisted | No |

## Permissions requested

- **Camera** (`NSCameraUsageDescription`): required for live label scanning
  via VisionKit's `DataScannerViewController`. The description in
  `Info.plist` states the on-device-only, no-upload nature of this use.
- No photo-library usage description is declared: importing an image uses
  `PhotosPicker`, which runs in a separate system process and grants the app
  access only to the specific photo the user selects, not general Photos
  library access — so `NSPhotoLibraryUsageDescription` is intentionally not
  requested.

## App Privacy manifest

`App/LabelProof/Resources/PrivacyInfo.xcprivacy` declares:
- `NSPrivacyTracking`: `false`
- `NSPrivacyTrackingDomains`: empty
- `NSPrivacyCollectedDataTypes`: empty (nothing is collected off-device)
- `NSPrivacyAccessedAPITypes`: declares `UserDefaults` usage with reason code
  `CA92.1` (app's own local settings storage).

## Audit method

Because there is no networking code in the app, a grep-based audit is
sufficient and is included as the `secret-scan` job pattern in
`.github/workflows/ci.yml`; additionally, `docs/LOCAL_QA_HANDOFF.md` includes
a step to grep the built app for networking symbols/frameworks as a final
local sanity check before submission.

## Contact / disclosure

See `SECURITY.md` for how to report a security or privacy concern.
