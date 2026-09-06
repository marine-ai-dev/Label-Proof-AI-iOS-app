# Monetization — LabelProof 1.0

## Distribution model

```
LabelProof 1.0 distribution model:
FREE DOWNLOAD
NO IAP
NO SUBSCRIPTIONS
NO ADS
```

## Verification

Repository-wide grep for any monetization symbol, framework, or pattern:

```
$ grep -rniE "StoreKit|SKProduct|SKPaymentQueue|IAP|subscription|paywall|
  purchase|premium|trial|upgrade" --include="*.swift" App Sources Tests AppUITests
```
No matches for any purchase/subscription/paywall/trial/premium-lock code
path. There is no `StoreKit` import anywhere in the project, no purchase
button, no upgrade prompt, no locked feature, and no advertising SDK.

This is a from-scratch v1.0 codebase (first commit `29afdb2`) — there are
no abandoned monetization experiments to remove.

## Price configuration

App Store price (Free) is an **ACCOUNT-SIDE ACTION** set in App Store
Connect when creating the app record — no code or local configuration
controls this. It requires no financial infrastructure, no banking/tax
payout setup beyond whatever Apple's own free-app distribution flow
requires at enrollment time.

## Why this matters for v1.0

This release exists to validate the owner's complete Apple release
pipeline (local QA → Release Candidate → Apple Developer Program →
App Store Connect → TestFlight → App Review → public release) without
also having to build and validate revenue infrastructure at the same time.
StoreKit, purchase receipts, subscription state, and paywall logic are
explicitly out of scope for this pass and were not added.
