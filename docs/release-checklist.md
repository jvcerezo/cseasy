# Release checklist

These are the steps that need your accounts or decisions. Everything else is done in code.

## 1. Back up the upload key (do this first)
`app/android/upload-keystore.jks` and `app/android/key.properties` were generated on 2026-10-27 and are gitignored. Copy both to a safe place, such as a password manager or encrypted drive. With Play App Signing (the default for new apps), a lost upload key can be reset through Play support, but that takes time.

Upload certificate fingerprints:
- SHA-1: `52:AB:1C:40:C5:66:15:BF:FE:D8:E2:DE:DD:E6:60:EF:52:C2:CE:8B`
- SHA-256: `92:12:30:29:CC:A1:F9:AA:4C:A5:F4:C6:44:2B:6E:23:3D:0B:2F:A5:AE:D7:C0:5C:53:97:F2:FE:38:20:57:6D`

## 2. Support email
Reports go to `jetjetcerezo@gmail.com`, the default in `report_sheet.dart`. Override it with `--dart-define=SUPPORT_EMAIL=...` if that changes. It is public in the listing and the privacy policy.

## 3. Play Console: in-app product
Monetize → Products → In-app products → Create:
- Product ID: `cseasy_full_access` (must match `premium_gate.dart`)
- Name: Full access. Description: Every question and unlimited full mock exams. One-time payment.
- Price: ₱199. The app shows whatever price Play returns.
- Activate it. The first AAB upload enables billing for the app.

## 4. Privacy policy
Fill in the bracketed fields in `docs/privacy-policy.md`, host it publicly, and put the URL in Play Console → App content.

## 5. Build the release bundle
Raise the build number (`+N`) for every upload: in `app/pubspec.yaml` (`version: 0.1.0+1`), or with `--build-number`.

```sh
cd app
flutter build appbundle --release \
  --build-number=1
```

Output: `app/build/app/outputs/bundle/release/app-release.aab`. Flutter may print "failed to strip debug symbols". On this PC, that's a false alarm caused by the space in the Android SDK path. The bundle is still signed and valid.

## 6. Play Console
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
