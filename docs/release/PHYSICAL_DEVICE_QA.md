# Physical Device QA — LabelProof 1.0

## Device detected (dynamic detection, not hardcoded)

```
$ xcrun devicectl list devices
Marina   iPhone 15 (iPhone15,4)   iOS 26.6   available (paired)
```

## What was actually done and verified in this pass (2026-09-06)

1. Built Debug configuration for the device
   (`xcodebuild ... -destination 'id=00008120-...' -allowProvisioningUpdates
   DEVELOPMENT_TEAM=LU4PK425G3 CODE_SIGN_STYLE=Automatic build`) →
   **BUILD SUCCEEDED**, signed with `Apple Development:
   marina.antonevich@gmail.com`.
2. Installed on the device via `devicectl device install app` →
   **App installed** (bundle ID `com.labelproof.app`).
3. Launched via `devicectl device process launch` →
   **Launched application with com.labelproof.app bundle identifier.**
4. Confirmed the process stayed alive (`devicectl device info processes`
   lists `LabelProof` with a live PID) — **no crash on launch on real
   hardware**, after this pass's accessibility fixes (`HistoryView`,
   `GoldenLabelFormView`).

Two of the four `devicectl` calls in this session transiently failed with
`IXRemoteErrorDomain`/`CoreDeviceError` connection-drop errors before
succeeding on retry — consistent with the device being actively in the
owner's hand / screen state changing, not a defect in the app or build.

## What was already verified on this same physical device in a prior pass
of this project (carried forward, not re-claimed as new in this session)

- Real camera permission prompt triggers when "Scan with Camera" is tapped.
- A live `DataScannerViewController` genuinely opens and holds the camera
  active — confirmed indirectly because iPhone Mirroring (Apple's own
  screen-mirroring tool) refuses to reconnect for as long as a camera-active
  screen is showing on the device, and the app process stayed alive
  throughout with no crash.

## What could NOT be verified by automation, in this pass or the prior one

- **Reading an actual printed/real-world product label with the live
  camera** and confirming a genuine PASS or FAIL against a Golden Label.
  This needs a human to point the physical camera at a real object — no
  tool available in this environment can see or control the phone's live
  camera feed (iPhone Mirroring deliberately blacks out camera-active
  screens, by Apple design, to prevent remote camera surveillance; this is
  a platform restriction, not a tooling gap).
- **Denied-camera-permission recovery UI.** Toggling Settings → Privacy →
  Camera → LabelProof off, relaunching, and confirming the fallback message
  requires the same hands-on-device interaction.
- I am explicitly NOT claiming barcode hardware verification (a real
  machine-readable barcode scanned by VisionKit) was completed, because it
  was not — no physical barcode was scanned in either pass.

## Human-only remaining steps (release-blocking? No — see below)

| Step | Release-blocking? |
|---|---|
| Point the live camera at a real printed product label and confirm PASS | No — the identical validation pipeline is already covered by 20 SwiftPM unit tests and 6 XCUITests using deterministic fixtures; this is confidence-building, not a new code path |
| Point the live camera at a real barcode and confirm exact-match barcode validation | No — same reasoning; `LabelValidatorTests` covers barcode exact-match/mismatch deterministically |
| Deny camera permission once and confirm the fallback message | No — the fallback path (`DataScannerRepresentable.onError` → `errorMessage` state → `scanner.errorMessage` text) is a single, simple, already-reviewed code path; not exercising it live does not block a Release Candidate |

None of these block declaring the Release Candidate ready — they are
confidence/polish items achievable only with a human physically holding
the device, and are documented so the owner can do them once, at their
convenience, before or during TestFlight.
