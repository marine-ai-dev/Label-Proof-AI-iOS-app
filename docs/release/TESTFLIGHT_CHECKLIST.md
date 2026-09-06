# TestFlight Checklist — LabelProof 1.0

Nothing in this checklist has been uploaded yet. This is the exact sequence
to follow after the account holder enrolls.

1. **Enroll in the Apple Developer Program** ($99/yr, ACCOUNT-SIDE ACTION —
   not performed by this pass).
2. In Xcode → Settings → Accounts, the paid team will appear alongside the
   existing free "Marina Antonevich (Personal Team)" (`LU4PK425G3`).
   Select the paid team as the project's Development Team (currently set
   to the Personal Team for local QA — see `project.yml`/build settings).
3. Register/finalize the App Identifier `com.labelproof.app` for the paid
   team in the Apple Developer portal, if not already auto-created.
4. Create the App Store Connect app record for LabelProof (Bundle ID
   `com.labelproof.app`, name "LabelProof").
5. Configure price = **Free** (see `MONETIZATION.md` — no IAP to configure).
6. Re-run archive/export with the paid team:
   ```
   xcodebuild -project LabelProof.xcodeproj -scheme LabelProof \
     -configuration Release -destination 'generic/platform=iOS' \
     -allowProvisioningUpdates DEVELOPMENT_TEAM=<paid team ID> \
     CODE_SIGN_STYLE=Automatic archive -archivePath LabelProof.xcarchive
   ```
   This should now succeed with an `app-store-connect` export method too
   (it currently fails only with "Team ... does not have permission to
   create iOS App Store provisioning profiles" — see
   `APP_STORE_SUBMISSION_CHECKLIST.md`).
7. **Validate App** (Xcode Organizer or
   `xcodebuild -exportArchive ... -exportOptionsPlist` with method
   `app-store-connect`, then `xcrun altool --validate-app` or Transporter).
8. **Upload build** (Xcode Organizer "Distribute App" or Transporter).
9. Wait for App Store Connect processing (usually minutes to ~1 hour).
10. Add the processed build to an **Internal TestFlight** group.
11. Install via TestFlight on the owner's iPhone 15 (`Marina`,
    `19D6C14B-86FB-5921-9224-B3F8C74D9D52`) — already paired and used for
    Debug installs throughout this pass.
12. Perform final TestFlight golden-path QA on that physical install:
    create/edit/delete a Golden Label, scan with the live camera against a
    real product, verify PASS and a deliberate FAIL, check History, check
    Settings (appearance/accent/history retention), and the denied-camera
    fallback — the human-only items listed in `PHYSICAL_DEVICE_QA.md`.
13. Submit for **App Review**, pasting `APP_REVIEW_NOTES.md`'s content into
    the Notes for Review field and `APP_STORE_METADATA.md`'s "What's New"
    text into the 1.0 release notes.
14. On approval, release the **FREE** app to the App Store.

No Paid Apps Agreement is required merely to distribute a free app; do not
configure banking/tax payout information as a prerequisite for this first
free release unless App Store Connect's own flow specifically requires it
at that point in time.
