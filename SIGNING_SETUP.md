# Signing Setup (run these yourself; placeholders only below)

No real secrets live in this repo. Never commit a keystore, `key.properties`,
or real passwords — `android/.gitignore` already excludes them.

## 1. Android upload keystore (run once, on your machine)

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\indian-ludo-upload.jks" `
  -alias indian-ludo -keyalg RSA -keysize 2048 -validity 10000
```

When prompted, invent a strong store password and key password and store them
in your password manager. Back up the `.jks` file offline — losing it means a
new app listing.

## 2. Point the build at your keystore (pick ONE)

Option A — `android/local.properties` (never committed; template values only):

```properties
sdk.dir=C:\\Users\\<YOU>\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\<path-to>\\flutter
keystore.file=<ABS-PATH-TO-YOUR-JKS e.g. C:\\Users\\<YOU>\\indian-ludo-upload.jks>
keystore.password=<YOUR-STORE-PASSWORD>
key.alias=indian-ludo
key.password=<YOUR-KEY-PASSWORD>
```

Option B — environment variables (CI-friendly): `KEYSTORE_FILE`,
`KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

Precedence per key: `local.properties` → env var. Values starting with `<`
are treated as unset. Without a keystore, release builds fall back to debug
keys (fine for `flutter run --release`, NOT for store uploads).

## 3. Google Play Console records (you, in the browser)

1. Create app: package `com.indianludo.app`, name "Indian Ludo", category Board.
2. On first `.aab` upload, opt in to **Play App Signing** (Google holds the
   signing key; your `.jks` becomes the upload key).
3. Record the upload-key SHA-1/SHA-256 (from the keytool output) in Console
   under Setup → App signing, and keep a copy in your password manager.

Verify locally: `flutter build appbundle --release`, then upload the `.aab`
from `build/app/outputs/bundle/release/` to a test track first.

## 4. Apple Developer records (you, Xcode + App Store Connect)

1. Apple Developer portal → Identifiers: App ID `com.indianludo.app`
   ("Indian Ludo"). Xcode target already uses this bundle id; display name is
   "Indian Ludo" (`ios/Runner/Info.plist`).
2. In Xcode, set your Team under Signing & Capabilities (Automatic signing).
   Never paste a Team ID or certificate into the repo.
3. App Store Connect → new app with bundle `com.indianludo.app`.
4. `ITSAppUsesNonExemptEncryption=false` is already in Info.plist (no custom
   encryption); confirm the export-compliance prompt on first TestFlight
   upload matches.

Verify locally: `flutter build ipa --release` (needs macOS + Xcode), then
upload via Xcode Organizer or Transporter to TestFlight.
