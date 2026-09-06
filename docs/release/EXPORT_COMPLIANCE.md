# Export Compliance — LabelProof 1.0

## Evidence

Repository-wide search for custom or third-party cryptography:

```
$ grep -rniE "CryptoKit|CommonCrypto|CC_SHA|CC_MD5|RSA|AES|SecKey|SecItem" \
    --include="*.swift" App Sources
```
No matches. LabelProof implements no cryptography of its own, includes no
third-party crypto library, and performs no networking at all (see
`APP_PRIVACY_AUDIT.md`) — so there is no TLS/HTTPS traffic to consider
either.

The only encryption present is whatever the OS itself applies transparently
(e.g. standard iOS file-system data protection for locally-stored SwiftData
files) — this is Apple's own system-provided encryption, not something the
app implements, links, or configures.

## `Info.plist` configuration

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```
This is already set and matches the evidence above.

## Likely App Store Connect export compliance answer

- "Does your app use encryption?" → No custom encryption beyond
  standard OS-provided protection; App Store Connect's export-compliance
  flow for apps that only use exempt (standard OS-level) encryption
  typically resolves to no additional documentation being required, and
  `ITSAppUsesNonExemptEncryption = false` avoids the yearly self-classification
  report from being prompted at all on upload.

This is prepared guidance from code evidence, not legal certainty — the
account holder should confirm the final selection in App Store Connect at
upload time, since Apple's export-compliance UI can change independently of
this document.
