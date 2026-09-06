# Age Rating Preparation — LabelProof 1.0

Based on actual app content and features (no content was invented for this
document).

| Questionnaire item | Answer | Evidence |
|---|---|---|
| Cartoon/Fantasy or Realistic Violence | None | No violence-related content of any kind exists |
| Sexual Content or Nudity | None | Not applicable |
| Profanity or Crude Humor | None | All user-facing strings are functional UI copy (see `en.lproj`/`uk.lproj`) |
| Alcohol, Tobacco, or Drug Use | None | Not applicable — app is a generic packaging-label verifier |
| Mature/Suggestive Themes | None | Not applicable |
| Horror/Fear Themes | None | Not applicable |
| Gambling (Simulated) | None | Not applicable |
| Contests | None | Not applicable |
| Unrestricted Web Access | No | No in-app browser, no `WKWebView`/`SFSafariViewController` anywhere in the codebase |
| User-Generated Content shared with others | No | Golden labels/history are private, on-device, single-user, never shared or published (see `APP_PRIVACY_AUDIT.md`) |
| Gambling/Contests (real-money) | No | Not applicable |

**Expected rating: 4+.**

Final submission of the age-rating questionnaire is an
**ACCOUNT-SIDE ACTION REQUIRED** step performed in App Store Connect.
