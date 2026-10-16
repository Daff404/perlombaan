# SHION

Android Flutter app with original local artwork, a live camera scanner, Gemini image understanding, real map searches, and a local points ledger. No Firebase.

## 1. Configure Gemini

Open `settings/private.json` and fill in your own key:

```json
{
  "GEMINI_API_KEY": "YOUR_KEY_HERE",
  "GEMINI_MODEL": "gemini-3.8-flash"
}
```

Create the key in Google AI Studio: https://aistudio.google.com/apikey . The file included in this ZIP has an empty key. Never paste your key into a chat or commit it; `settings/private.json` is in `.gitignore`.

Values are read by `lib/settings.dart` through Dart defines. Changing the file requires rebuilding/restarting with the define file. A public APK can be reverse-engineered: for public distribution with a shared paid key, place Gemini behind an authenticated backend/proxy with quotas. This build directly uses your own key for personal testing and use; it does not pretend to provide server-side protection.

## 2. Build on Windows + VS Code

Java 25.0.3 configuration is included: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, legacy Android/Kotlin DSL compatibility flags, and Java 11 bytecode target. Everything is included in this single project folder. Run `Build-Java25.ps1` to check your existing Java 25 installation and Android SDK, then clean, resolve dependencies, and build. See `JAVA25.md`. `Apply-Java25.ps1` is only needed to patch another older checkout.

Open the `shion` folder in VS Code. Complete the Android toolchain in `flutter doctor`, then:

```powershell
.\build-apk.ps1
```

If PowerShell blocks scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-apk.ps1
```

Or run the commands directly:

```powershell
flutter pub get
flutter build apk --release --dart-define-from-file=settings/private.json
```

APK: `build/app/outputs/flutter-apk/app-release.apk`.

To run during development:

```powershell
flutter run --dart-define-from-file=settings/private.json
```

Linux/Android build-shell environments can run `sh build-apk.sh`. A build editor that invokes Flutter itself must pass `--dart-define-from-file=settings/private.json` in its Flutter arguments; filling the JSON alone does not inject the key.

## Scanner

- Tap **Buka Kamera** to show a real camera preview. Microphone is not used.
- Tap **Ambil & Analisis** to take a photo, or use **Galeri**.
- The app asks for consent before sending a photo to Gemini.
- Gemini fills the object name, category, visible material, handling steps and warnings. There is no manual category selector in the scanner.
- Save the actual result/photo to local history and earn eligible local points. API errors never create a substitute prediction.
- Failed requests, missing keys, denied camera permission, quota exhaustion and unclear images show visible errors. AI results can be wrong; displayed confidence is not a measured accuracy claim.

## Real locations

**Bank Sampah** opens a map with GPS, a city search, map/list views, real OpenStreetMap points, material/opening-hour tags when available, bookmarks and directions through Google Maps. The initial map center is Sukabumi and is labeled as such; it is not claimed as your GPS position.

Search is user-triggered within 15 km of the selected center. Places are read from Overpass (`amenity=recycling`, `amenity=waste_disposal`, or names containing `bank sampah`). City search uses Nominatim. Data coverage varies; empty results remain empty. These are community records, not automatically verified SHION partners. Confirm acceptance and opening hours with the operator. Map data needs internet. Saved places remain local.

## Functioning points

- 10 local points for a newly saved AI-recognized waste image (model confidence at least 0.65, not unclear).
- At most five rewarded scans per device day.
- Exact file hash and a perceptual image hash detect common duplicates; duplicate scans can be saved but earn zero.
- Every credit/debit has a persisted ledger entry. Scan and credit are written in one serialized transaction.
- 20 points can be redeemed for a Gemini-generated **Panduan Pilah Personal** based on scan categories. Points are deducted only after a complete guide is returned and saved. The guide can be reopened offline.
- These are functioning local service points, not money or a transport/product voucher. No external reward partner is connected. Real bank-deposit verification, financial redemption and anti-fraud enforcement across devices require a trusted server/partner integration.

Local storage and device time can be changed by a device owner; the local duplicate checks are not a financial anti-fraud system. Clearing app data deletes the profile, photos, points and guides. Personal records are not synced.

## Other features

Education, a local profile, deposit planning, and activity tracking remain available. Deposits are personal plans and do not create partner-verified points. Activity tracking records distance/kWh; it does not invent CO₂ estimates without sourced factors.

Original images, logo/icons and fonts are bundled under `assets/`. See `ASSETS.md`. Theme matches the foliage/green-glass reference and is constrained to a readable phone width on desktop.

## Test and integration status

This package is source code, not a verified release APK. The current changes have been parsed/formatted by Dart, but Flutter analysis/tests and APK build could not finish here because Flutter tooling dependencies were unavailable. This environment has Java 17 and no Android SDK; it cannot validate your Windows Java 25 runtime. Check the real build output on your PC before treating the application as ready.

Run `flutter analyze` and `flutter test`. Automated service tests use HTTP test doubles to verify the production request/response paths, errors, points and map-data parsing; they do not fabricate runtime data. Live Gemini recognition requires your key/quota. Camera/GPS permissions and preview must be checked on a real device. An APK build additionally requires the Android SDK/JDK and network access to Gradle/Maven dependencies.

Primary integration references:
- https://ai.google.dev/gemini-api/docs/generate-content/image-understanding
- https://ai.google.dev/api/generate-content
- https://dev.overpass-api.de/overpass-doc/en/
- https://operations.osmfoundation.org/policies/nominatim/
- https://docs.fleaflet.dev/
