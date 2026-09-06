# App Store Connect — App Privacy Questionnaire Answers (prepared)

Based on the verified audit in `APP_PRIVACY_AUDIT.md`. To be entered by the
account holder in App Store Connect's "App Privacy" section
(ACCOUNT-SIDE ACTION REQUIRED to submit — values below are what the
evidence supports).

## Does this app collect data?

**No, we do not collect data from this app.**

Rationale: no networking code exists anywhere in the app (verified by grep
of source and by string-scanning the compiled Release binary); all storage
is local SwiftData/UserDefaults with no transmission path to leave the
device.

## Per-category answers (all should be left "Not Collected")

| Category | Collected? | Evidence |
|---|---|---|
| Contact Info | No | No contact/account fields exist in the data model |
| Health & Fitness | No | Not applicable to this app |
| Financial Info | No | Not applicable — no payment code exists |
| Location | No | No location API called anywhere |
| Sensitive Info | No | Not applicable |
| Contacts | No | No Contacts framework usage |
| User Content | No (stored locally only, never collected by the developer) | Golden labels / verification history stored in local SwiftData; no upload path exists |
| Browsing History | No | No web browsing feature exists |
| Search History | No | Not applicable |
| Identifiers | No | No `UIDevice.identifierForVendor`, no advertising ID, no custom analytics ID generated anywhere in the codebase |
| Purchases | No | No StoreKit/IAP code exists (see `MONETIZATION.md`) |
| Usage Data | No | No analytics SDK, no custom usage logging call sites |
| Diagnostics | No | No crash reporter integrated |
| Other Data | No | — |

## Data Used to Track You

None. `NSPrivacyTracking = false` in the privacy manifest, and there is no
cross-app/cross-site tracking mechanism (no IDFA, no fingerprinting, no
third-party SDK) anywhere in the code.

## Data Linked to You / Data Not Linked to You

Not applicable — no data is collected off-device at all, so neither
category applies.

## Camera permission (contextual note for the questionnaire's permissions
section, not a "data collection" category)

Camera access is requested (`NSCameraUsageDescription`) solely to run
on-device Vision/VisionKit OCR and barcode recognition during a scan. No
captured frame is stored beyond the in-memory duration of one scan, and
none is ever transmitted — this is a local processing permission, not a
data-collection event.
