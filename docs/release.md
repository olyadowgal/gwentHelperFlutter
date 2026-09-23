# Releasing to Play Store

This app updates the existing Play Store listing (`com.dowgalolya.gwenthelper`,
the original Android app). That only works if every upload is signed with the
**same key** the original app was signed with, and has a **versionCode higher
than the last published one** (22, as of the last Android release, `1.91`).

## One-time setup

### 1. The signing keystore

Locate the original `.jks`/`.keystore` file used to sign `gwentHelper`
releases (check wherever you keep release keys — this machine didn't have
one for this app when the Flutter project was set up). Place it at:

```
android/upload-keystore.jks
```

(or anywhere else under `android/` — just update `storeFile` in the next step
to match).

If the file is truly lost and Play App Signing is enabled for this app
(check **Play Console → your app → Setup → App integrity**), you'll need to
request an **upload key reset** there instead. That requires identity
verification and can take a few days — do this well before a deadline.

### 2. `android/key.properties`

Copy the template and fill in the real values:

```bash
cp android/key.properties.example android/key.properties
```

```properties
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=<the key alias inside the keystore>
storeFile=upload-keystore.jks
```

`android/key.properties` is gitignored — it never gets committed. Without
it, `flutter build apk/appbundle --release` silently falls back to debug
signing (fine for local testing, **not acceptable for a Play Store upload**
— Play Console will reject it as a signature mismatch against the
existing app).

To sanity-check which key an app bundle/APK is actually signed with:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### 3. Play Developer API service account (for Fastlane uploads)

Only needed if you want `fastlane` to upload builds directly, rather than
uploading manually through the Play Console web UI each time.

1. In **Google Cloud Console** (same Google account as Play Console),
   create a service account and a JSON key for it.
2. In **Play Console → Setup → API access**, link that Google Cloud project
   and grant the service account **Release manager** permissions (or
   narrower — just enough to upload to the tracks you'll use) for this app.
3. Save the downloaded JSON as:

   ```
   android/fastlane/play-service-account.json
   ```

   Also gitignored — never commit it.

### 4. Install Fastlane

```bash
cd android
bundle install
```

## Releasing a new version

1. Bump the version in `pubspec.yaml` — the format is `versionName+versionCode`,
   e.g. `2.0.1+24`. The `+N` part (versionCode) **must** be strictly higher
   than the previous upload's; the part before `+` (versionName) is just the
   display string and has no Play Console constraints.
2. From `android/`, run one of:

   ```bash
   bundle exec fastlane android internal     # Internal testing track
   bundle exec fastlane android production   # Production track
   ```

   Or build only, without uploading:

   ```bash
   bundle exec fastlane android build
   ```

3. If you'd rather upload by hand: the built bundle is at
   `build/app/outputs/bundle/release/app-release.aab` — drag that into
   Play Console → your app → the release track of your choice.

## What this repo does *not* automate

- Store listing text (title, descriptions), screenshots, and the feature
  graphic — these live only in Play Console; nothing in this repo mirrors
  them yet. `fastlane`'s `upload_to_play_store` calls above are configured
  with `skip_upload_metadata`/`skip_upload_images`/`skip_upload_screenshots`
  for that reason.
- The Data Safety form — worth revisiting once this app is live, since the
  Flutter rewrite collects no analytics/crash data (unlike the old Firebase-
  based app), which should simplify that disclosure.
