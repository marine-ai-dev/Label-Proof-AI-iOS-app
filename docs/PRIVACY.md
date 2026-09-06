# Privacy

LabelProof is designed to be privacy-first by construction, not by policy
alone.

## Summary

Core verification is entirely on-device. Your data is stored locally by
default. LabelProof has **no developer-operated backend of any kind** — the
only two ways your data can ever leave this device are both fully optional
and fully under your control: an automatic backup to your own iCloud
account, or a manual export to a Files location you explicitly choose. There
is no LabelProof server, no LabelProof database, and no LabelProof analytics
anywhere.

## What LabelProof does NOT do

- No account, no login, no user identity of any kind.
- No developer-operated network service of any kind — no LabelProof
  server, no LabelProof database, no analytics, no crash reporter, no ad
  SDK, no third-party SDK. Grep the codebase: there is no `URLSession` call
  anywhere in `App/LabelProof` or `Sources/LabelProofCore`.
- No cloud OCR or cloud AI inference. All text and barcode recognition uses
  Apple's on-device Vision framework (`VNRecognizeTextRequest`,
  `VNDetectBarcodesRequest`) and VisionKit's `DataScannerViewController`.
- No custom/trained ML model. Only Apple's built-in system Vision models are
  used, as provided by the OS.
- No full images stored. `VerificationRecord`/`VerificationHistoryRecord`
  store only the extracted text lines, decoded barcode payloads, and the
  validation outcome — never the captured photo or camera frame.
- No Google Drive/Dropbox/etc. API integration of any kind. If you export a
  backup to one of those through the native Files picker, that's a
  connection between the Files app and your own account on that service —
  LabelProof never sees or handles those credentials.

## Backup & Synchronization (optional)

LabelProof offers two independent, user-controlled ways to protect your
Golden Labels and verification history:

1. **Automatic iCloud Backup** (off by default) — when enabled, LabelProof
   writes one backup snapshot to your own iCloud account's storage for this
   app. This is Apple's iCloud infrastructure, not a LabelProof-operated
   service; LabelProof cannot read this data from any other user's device,
   and there is no LabelProof database anywhere in this flow.
2. **Manual Export/Import** — creates a `.labelproofbackup` file (plain,
   inspectable JSON — see `Sources/LabelProofCore/Backup.swift`) and hands
   it to the system Files picker, which saves it only to whatever location
   you explicitly choose (iCloud Drive, On My iPhone, or another Files
   provider such as Google Drive/Dropbox if installed).

Precise wording used in the app: "Your LabelProof data stays on your device
unless you choose to back it up. Optional iCloud backups are stored in your
iCloud account. Manual exports go only to the location you choose in Files.
LabelProof has no developer-operated backend for your data."

## Data that stays on-device

| Data | Where it lives | Ever leaves device? |
|---|---|---|
| Golden labels (name, expected product name/weight/barcode/phrases/notes) | SwiftData (local app storage) | Only if you enable iCloud Backup or manually export |
| Verification history (status, mismatches, timestamps) | SwiftData (local app storage) | Only if you enable iCloud Backup or manually export |
| Appearance/accent/language/history-retention settings | `UserDefaults` (local) | No — never included in a backup, so restoring one never changes your interface language |
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

Because there is no developer-operated networking code in the app, a
grep-based audit is sufficient and is included as the `secret-scan` job
pattern in `.github/workflows/ci.yml`; additionally,
`docs/LOCAL_QA_HANDOFF.md` includes a step to grep the built app for
networking symbols/frameworks as a final local sanity check before
submission. (iCloud Backup, when enabled, legitimately uses Apple's own
system `FileManager`/iCloud APIs — see `App/LabelProof/Services/
ICloudBackupStore.swift` — which is Apple-system networking, not a
LabelProof-operated network service.)

## Contact / disclosure

See `SECURITY.md` for how to report a security or privacy concern.
