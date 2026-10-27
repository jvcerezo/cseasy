# Release checklist

These are the steps that need your accounts or decisions. Everything else is done in code.

## 1. Back up the upload key (do this first)
`app/android/upload-keystore.jks` and `app/android/key.properties` were generated on 2026-10-27 and are gitignored. Copy both to a safe place, such as a password manager or encrypted drive. With Play App Signing (the default for new apps), a lost upload key can be reset through Play support, but that takes time.

Upload certificate fingerprints:
- SHA-1: `52:AB:1C:40:C5:66:15:BF:FE:D8:E2:DE:DD:E6:60:EF:52:C2:CE:8B`
- SHA-256: `92:12:30:29:CC:A1:F9:AA:4C:A5:F4:C6:44:2B:6E:23:3D:0B:2F:A5:AE:D7:C0:5C:53:97:F2:FE:38:20:57:6D`

## 2. Support email
Choose the address that receives problem reports. It is public in the listing and the privacy policy. Pass it at build time (step 6). Without it, the "Report a problem" link is hidden.

## 3. AdMob
1. Create an AdMob account, then add an Android app (you can link it to Play later).
2. Copy the **App ID** (`ca-app-pub-…~…`) into `app/android/key.properties` as `admobAppId=…`.
3. Create a **Banner** ad unit and copy its ID (`ca-app-pub-…/…`) for step 6.
4. AdMob → Privacy & messaging: create a GDPR consent message. The app already runs Google's consent flow.
5. Until you do this, builds use Google's test IDs. They work but never pay out.

## 4. Play Console: in-app product
Monetize → Products → In-app products → Create:
- Product ID: `cseasy_full_access` (must match `premium_gate.dart`)
- Name: Full access. Description: Every question, unlimited full mock exams, no ads.
- Price: ₱199, or your choice. The app shows whatever price Play returns.
- Activate it. The first AAB upload enables billing for the app.

## 5. Privacy policy
Fill in the bracketed fields in `docs/privacy-policy.md`, host it publicly, and put the URL in Play Console → App content.

## 6. Build the release bundle
Raise the build number (`+N`) for every upload: in `app/pubspec.yaml` (`version: 0.1.0+1`), or with `--build-number`.

```sh
cd app
flutter build appbundle --release \
  --build-number=1 \
  --dart-define=SUPPORT_EMAIL=you@example.com \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
```

Output: `app/build/app/outputs/bundle/release/app-release.aab`. Flutter may print "failed to strip debug symbols". On this PC, that's a false alarm caused by the space in the Android SDK path. The bundle is still signed and valid.

## 7. Play Console
- Store listing: copy from `docs/store-listing.md`, and upload the icon, feature graphic, and screenshots.
- App content: fill in the forms using `docs/data-safety.md`.
- Closed test: follow `docs/closed-testing.md`.

## Before each content update
```sh
cd pipeline
python -m unittest discover -s tests -t .
python check_quotes.py
python validate.py
python build.py
python spotcheck.py   # review the sheet in pipeline/out/spotcheck.md
cd ../app && flutter test
```
