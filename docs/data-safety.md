# Play Console: Data safety and app content answers

These answers match the current build: study data local only, Google Play Billing, Google AdMob banner, email-based reports. Re-check them if you add analytics, accounts, or a backend.

## Data safety form

**Does your app collect or share any of the required user data types?** Yes. The AdMob SDK collects data. The app's own study data stays on the device and does not count as collected.

**Is all of the user data collected by your app encrypted in transit?** Yes. The AdMob SDK uses HTTPS.

**Do you provide a way for users to request that their data is deleted?** Study data is deleted by uninstalling the app. For ad data, point to Google's controls (resetting the advertising ID). Answer according to the current Play form wording.

Data types (all collected and shared by the AdMob SDK, for **Advertising or marketing**, **Analytics**, and **Fraud prevention, security, and compliance**; processing is ephemeral where the form asks; collection is required for free users):

| Category | Data type | Collected | Shared | Optional? |
|---|---|---|---|---|
| Location | Approximate location | Yes | Yes | Required for free tier |
| App activity | App interactions | Yes | Yes | Required for free tier |
| App info and performance | Crash logs, Diagnostics | Yes | Yes | Required for free tier |
| Device or other IDs | Device or other IDs | Yes | Yes | Required for free tier |

Not collected: personal info (name, email, and so on), financial info (Google Play handles payments), messages, photos, contacts, health, files, calendar, web browsing.

**Problem reports**: the user sends these from their own email app, so the app doesn't transmit anything itself. If Play's form treats received support emails as collection, declare **Personal info → Email address** under **App functionality**, as optional.

## App content declarations

- **Advertising ID**: Yes, the app uses it (the `AD_ID` permission comes from the AdMob SDK). Purpose: Advertising or marketing.
- **Ads**: Yes, the app contains ads.
- **Target audience**: 18 and over. You can include 16–17, but don't select any age group under 13.
- **Content rating**: Education reference. Answer the questionnaire honestly; expected rating is Everyone/3+.
- **Government apps**: No. The app is not affiliated with or endorsed by the CSC. Keep the disclaimer in the listing.
- **Financial features**: None.
- **Health**: None.
- **News app**: No.
- **Privacy policy URL**: required. Host `docs/privacy-policy.md` publicly (GitHub Pages, Google Sites, or similar) after filling in the bracketed fields.
