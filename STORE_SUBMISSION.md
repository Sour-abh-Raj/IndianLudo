# Store Submission Checklist — Indian Ludo

## Versioning (both stores)

- Single source: `pubspec.yaml` → `version: 1.0.0+1`
  (`build-name` = store version, `+build-number` = versionCode/CFBundleVersion).
- Every upload needs a HIGHER build number:
  `flutter build appbundle --build-name=1.0.1 --build-number=2`
- Android: `applicationId com.indianludo.app` (gradle). iOS: bundle
  `com.indianludo.app`, display name "Indian Ludo".

## Google Play

1. **Closed testing first (required for new personal accounts):** run a closed
   track with **≥12 testers for the last 14 days** before production access.
   Create an email list / Google Group of testers in Console → Testing.
2. Upload `.aab` to Closed testing; fix pre-launch report issues.
3. **Content rating questionnaire:** Board game, no real-money gambling, no
   chat with strangers (local pass-and-play / bots only), no user content.
   Answer truthfully; expect Everyone / PEGI 3 style outcome.
4. **Privacy policy (required):** host one page stating: fully offline game,
   no accounts, no data collection, no ads SDK, no analytics. Link it in
   Console → Store presence. Data-safety form: "no data collected or shared".
5. **Screenshots/feature graphic:** at least 2 phone screenshots
   (16:9 or 9:16 OK), 1 feature graphic 1024×500, icon 512×512.
6. Roll to production only after the 14-day tester requirement is met.

## Apple App Store (TestFlight → Review)

1. Upload build → TestFlight internal testing (up to 100 team users, no
   review); add external testers (up to 10,000, light review) if desired.
2. **Privacy narrative (App Store Connect → App Privacy):** "No data
   collected" — offline game, no accounts, no tracking (no ATT prompt needed).
3. **Age rating questionnaire:** no gambling with real money, no chat,
   no user-generated content, no web access → expect 4+.
4. **Screenshots:** 6.7" and 6.5" iPhone sets required (portrait of the
   board + a mid-game shot + game-over screen recommended).
5. Export compliance: answer "No" to using non-exempt encryption
   (matches `ITSAppUsesNonExemptEncryption=false`); no encryption
   documentation needed.
6. Submit for review with demo notes: "No login. Pick 2–4 players, tap dice,
   tap a highlighted token. Bots fill empty seats."

## Release-day commands (after SIGNING_SETUP.md is done)

```powershell
flutter build appbundle --release   # -> Play Console (.aab)
flutter build ipa --release         # -> TestFlight (macOS only)
```
