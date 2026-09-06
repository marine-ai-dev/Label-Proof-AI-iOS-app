# Baseline — LabelProof 1.0

Recorded 2026-09-06, macOS 26.5.1, Xcode 26.6, Swift 6.3.3, on the repository
at commit `bfb3792` (branch `claude/labelproof-ondevice-verifier-e8gqyh`),
before this release-hardening pass.

## Repository state

```
$ git status
On branch claude/labelproof-ondevice-verifier-e8gqyh
nothing to commit, working tree clean

$ git log --oneline -4
bfb3792 Wire up live camera scanning (was never actually presented) + release prep
a472018 Fix local Xcode build/test failures found during first real compile
ad5fe8e Fix false-PASS bug in weight validation (substring vs token match)
29afdb2 Build LabelProof v1: on-device packaging label verifier (iOS, Swift/SwiftUI)
```

## Xcode project

```
$ xcodebuild -list -project LabelProof.xcodeproj
Targets: LabelProof, LabelProofUITests
Build Configurations: Debug, Release
Schemes: LabelProof, LabelProofCore
```

## Simulators discovered (dynamic, not hardcoded)

```
$ xcrun simctl list devices available
iPhone 17 Pro, iPhone 17 Pro Max, iPhone 17e, iPhone 17, iPhone 15 QA,
iPad Pro 13-inch (M5), iPad Pro 11-inch (M5), iPad mini (A17 Pro),
iPad Air 13-inch (M4), iPad Air 11-inch (M4), iPad (A16)
```
Used for this pass: **iPhone 15 QA** (small/representative) and
**iPhone 17 Pro Max** (large, 6.9"-class). No plain "iPhone 15" simulator
exists on this Xcode's runtime; "iPhone 15 QA" is the iPhone15,4-class
device available and was used per explicit instruction.

## Physical device discovered (dynamic)

```
$ xcrun devicectl list devices
Marina   iPhone 15 (iPhone15,4)   iOS 26.6   available (paired)
```

## Baseline test/build results (unchanged by this pass — already green
entering this session; re-verified after all fixes in this pass, see
`RELEASE_READINESS.md`)

- `swift test --package-path .` → 20/20 passed
- `xcodebuild test ... -only-testing:LabelProofUITests` (iPhone 15 QA) → 6/6 passed
- `xcodebuild build` (Debug, Simulator) → BUILD SUCCEEDED
- `xcodebuild build -configuration Release` (Simulator) → BUILD SUCCEEDED
- Local Release archive with Personal Team (`LU4PK425G3`) → ARCHIVE SUCCEEDED
  (see `docs/release/APP_STORE_SUBMISSION_CHECKLIST.md` for the
  app-store-connect export failure that is the sole remaining
  account-side blocker).

## Signing identities available on this Mac

```
$ security find-identity -v -p codesigning
3 valid identities found — 2 belong to other, unrelated projects on this
Mac (omitted here); the one used for LabelProof:
Apple Development: marina.antonevich@gmail.com (6QGX482FLP)
```

```
$ defaults read com.apple.dt.Xcode IDEProvisioningTeams
marina.antonevich@gmail.com → teamID LU4PK425G3, "Marina Antonevich
(Personal Team)", isFreeProvisioningTeam = 1
```

Personal Team ⇒ no Apple Developer Program membership yet. Sufficient for
Debug/Release builds, Simulator, physical-device Debug installs, and local
archive; insufficient for an `app-store-connect` export (see
`TESTFLIGHT_CHECKLIST.md`).
