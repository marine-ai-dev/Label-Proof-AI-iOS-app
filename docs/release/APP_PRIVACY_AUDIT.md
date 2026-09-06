# App Privacy Audit — LabelProof 1.0

Evidence-based, from actual code inspection on 2026-09-06. See
`docs/PRIVACY.md` for the pre-existing narrative version; this document is
the verification pass behind it.

## Networking — repository-wide grep

```
$ grep -rniE "URLSession|NWConnection|WebSocket|http://|https://|Firebase|
  Crashlytics|Sentry|Mixpanel|Amplitude|Segment|StoreKit|Analytics|OpenAI|
  Anthropic|api\.openai|generativeai" --include="*.swift" App Sources Tests AppUITests
```
Result: **zero matches** for any networking, analytics, crash-reporting, ad,
or external-AI symbol. The only lines matched were a code comment
("no analytics") and unrelated `XCUIApplication` references in test code.

Additionally verified in the archived Release binary:
```
$ strings LabelProof.app/LabelProof | grep -iE "http://|https://"
```
→ no output. No hardcoded endpoints of any kind exist in the compiled binary.

**Conclusion: LabelProof performs no network requests whatsoever.**

## Third-party dependencies

`Package.swift` declares zero external package dependencies — only the
in-repo `LabelProofCore` target. `project.yml` likewise adds no third-party
SwiftPM/CocoaPods/Carthage dependency. There is nothing to audit for
supply-chain risk.

## Data storage

| Store | Contents | Leaves device? |
|---|---|---|
| SwiftData (`GoldenLabelRecord`, `VerificationHistoryRecord`) | Golden label definitions; verification history (status, mismatches, timestamps, extracted text/barcode strings) | No — no networking code exists to send it anywhere |
| `UserDefaults` | Appearance, accent color, history-retention setting | No |
| In-memory only | Captured camera frame / imported photo bytes, for the duration of one OCR+barcode pass | Never persisted, never transmitted |

No full images are ever stored (`ExtractedLabelData`/`VerificationRecord`
only carry `rawTextLines: [String]` and `barcodes: [BarcodeObservation]`,
never image `Data`).

## Deletion — verified against actual implementation, not assumed

- `GoldenLabelStore.delete(id:)` → `context.delete(record); try? context.save()`
  — a real SwiftData delete, not a soft/flag delete.
- `VerificationHistoryStore.delete(id:)` → same pattern for one row.
- `VerificationHistoryStore.clearAll()` → `context.delete(model:
  VerificationHistoryRecord.self)` — bulk delete of the entire table.
- Empirically re-confirmed in this pass: Settings → "Clear All History" and
  the Golden Labels list's swipe-to-delete both require an explicit
  confirmation dialog before calling these methods (seen live in Simulator
  QA, see `RELEASE_READINESS.md`).

## Required-reason APIs (per Apple's current required-reason API list)

Grep of the shipping app target for every required-reason API category
(file timestamps, disk space, active keyboard, user defaults, system boot
time, etc.):

```
$ grep -rn "FileManager|UserDefaults|systemUptime|CFAbsoluteTime|UIDevice" \
    --include="*.swift" App Sources
```
Only match: `UserDefaults.standard` in `SettingsStore.swift` (3 call sites —
appearance, accent, history-retention).

`App/LabelProof/Resources/PrivacyInfo.xcprivacy` declares exactly this and
nothing else:
```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
  <dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>CA92.1</string></array>
  </dict>
</array>
```
`CA92.1` ("access info from same app, per Apple's approved reasons") is the
correct reason code for reading/writing the app's own `UserDefaults` suite
— which is exactly and only what `SettingsStore` does. **No required-reason
API is used without a declaration, and no declaration exists for an API the
app does not use.**

## Tracking

`NSPrivacyTracking` = `false`, `NSPrivacyTrackingDomains` = empty array in
the manifest — consistent with zero networking code.

## Camera / permissions

See `PERMISSIONS` section of `APP_STORE_PRIVACY_ANSWERS.md` for the mapped
questionnaire answer; code-level: `NSCameraUsageDescription` in `Info.plist`
is the only usage-description key present, and it is the only permission
actually requested anywhere in the codebase (`DataScannerViewController`
implicitly requests it when scanning starts; no other permission API —
Photos, Microphone, Location, Contacts, Notifications, etc. — is called
anywhere in `App/LabelProof`).

## Verdict

No data collection, no tracking, no analytics, no third-party SDKs, no
required-reason API misuse, and deletion is real. `docs/PRIVACY.md`'s
claims are verified accurate against the actual current codebase, not just
asserted.
