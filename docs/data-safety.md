# Play Console: Data safety and app content answers

These answers match the current build: study data local only, Google Play Billing, email-based reports, no ads or analytics. Re-check them if you add analytics, ads, accounts, or a backend.

## Data safety form

**Does your app collect or share any of the required user data types?** No. Study data stays on the device and does not count as collected. Google Play Billing is handled by Google and is not declared by the app.

**Problem reports**: the user sends these from their own email app, so the app doesn't transmit anything itself. If Play's form treats received support emails as collection, answer Yes instead and declare **Personal info → Email address**, collected, not shared, for **App functionality**, optional, encrypted in transit (email providers use TLS), deletion by emailing the support address.

## App content declarations

- **Advertising ID**: No. The app does not use it, and the manifest has no `AD_ID` permission.
- **Ads**: No, the app does not contain ads.
- **Target audience**: 18 and over. You can include 16–17, but don't select any age group under 13.
- **Content rating**: Education reference. Answer the questionnaire honestly; expected rating is Everyone/3+.
- **Government apps**: No. The app is not affiliated with or endorsed by the CSC. Keep the disclaimer in the listing.
- **Financial features**: None.
- **Health**: None.
- **News app**: No.
- **Privacy policy URL**: required. Host `docs/privacy-policy.md` publicly after setting the publication date.
