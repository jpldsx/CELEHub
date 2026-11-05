# CELEHub app (Android)

A native Flutter app for CELEHub. It reads the same videos, comments and quick survey as your website,
so updating videos from Telegram updates the app too.

## Set up (one time)
1. Create a NEW GitHub repository (for example `celehub-app`). Do not put this in your website repo.
2. Add every file from this folder with the same folder names (`lib/`, `lib/screens/`, `.github/workflows/`).
3. Open `lib/config.dart` and fill in `siteUrl` and `turnstileSiteKey`.
4. Commit. GitHub builds the app automatically (Actions tab, "Build Android APK").
5. When the run is green, open it and download the `celehub-apk` file at the bottom. Unzip it and install `app-release.apk` on your phone (allow "install unknown apps" when asked).

## If the build fails
Open the failed run, copy the first red error and send it to Claude.

## If the app shows no videos
The empty screen now says why. Also try opening `https://YOUR-DOMAIN/api/videos?page=study` in your phone browser:
- it shows `{"ok":true,"videos":[...]}` with items: the app should work; check `siteUrl` in `lib/config.dart`.
- it shows `"videos":[]`: the database has no videos yet. Add some with the Telegram bot, or run the import of js/videos.js.
- it shows a "Just a moment" page: Cloudflare is blocking automatic requests (Security > Bots). Ask Claude.
