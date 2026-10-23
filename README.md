# Camion

## Flavor Setup

- `development`
  - Entry point: `lib/main_development.dart`
  - Android package: `com.camion.development`
  - Android app label: `CAMION DEVELOPMENT`
- `production`
  - Entry point: `lib/main_production.dart`
  - Android package: `com.camiontrading.app`
  - Android app label: `CAMION`

## Where To Change URLs

Update these files:
- `/.env.development`
- `/.env.production`

Keys you can change:
- `BASE_URL`
- `ENABLE_NETWORK_LOGS=true|false`

Current setup allows same URLs for both flavors now, and different URLs later.

## Firebase Files Location

Android:
- Development: `android/app/src/development/google-services.json`
- Production: `android/app/src/production/google-services.json`

iOS:
- Current single target file: `ios/Runner/GoogleService-Info.plist`
- If you later split iOS bundle ids by flavor, create separate plist files per scheme.

## Run Locally

Development:
```bash
flutter run --flavor development --target lib/main_development.dart --dart-define-from-file=.env.development
```

Production:
```bash
flutter run --flavor production --target lib/main_production.dart --dart-define-from-file=.env.production
```

## Debug Build (APK)

Development debug APK:
```bash
flutter build apk --debug --flavor development --target lib/main_development.dart --dart-define-from-file=.env.development
```

Development debug APK (one command script):
```bash
./scripts/build_debug_development.sh
```

Development debug APK with custom URL override:
```bash
./scripts/build_debug_development.sh https://your-dev-api.example.com
```

Production debug APK:
```bash
flutter build apk --debug --flavor production --target lib/main_production.dart --dart-define-from-file=.env.production
```

## Production Release AAB

```bash
flutter build appbundle --release --flavor production --target lib/main_production.dart --dart-define-from-file=.env.production
```

Output:
- `build/app/outputs/bundle/productionRelease/app-production-release.aab`

## Versioning (Both Flavors)

Base app version is in `pubspec.yaml`:
- `version: X.Y.Z+BUILD`

How to update:
1. Change `version` in `pubspec.yaml` for normal releases.
2. For one-off CI/release override, use:
```bash
flutter build appbundle --release --flavor production --target lib/main_production.dart --dart-define-from-file=.env.production --build-name X.Y.Z --build-number N
```

Notes:
- Android development flavor automatically appends `-dev` to version name (`versionNameSuffix`).
- Build number (`+BUILD` / `--build-number`) should always increase for store releases.

## Android Studio One-Click Run

Create 2 Flutter run configurations:
- `Camion Dev`
  - Target: `lib/main_development.dart`
  - Args: `--flavor development --dart-define-from-file=.env.development`
- `Camion Prod`
  - Target: `lib/main_production.dart`
  - Args: `--flavor production --dart-define-from-file=.env.production`

Then select either config from the top toolbar dropdown and press Run.
If you just press the Play button without choosing a config, the app now defaults to the development flavor.
