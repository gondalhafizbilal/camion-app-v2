# fastlane documentation

================

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```bash
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios distribute

```bash
[bundle exec] fastlane ios distribute
```

Distribute app to Firebase App Distribution

This lane will:
1. Clean the Flutter build
2. Build the iOS IPA for production flavor
3. Distribute the IPA to Firebase App Distribution for testers

### ios build

```bash
[bundle exec] fastlane ios build
```

Build iOS IPA

This lane will:
1. Clean the Flutter build
2. Build the iOS IPA for production flavor

---

## Setup Instructions

### Required Secrets for GitHub Actions

You need to configure the following secrets in your GitHub repository settings:

1. **FIREBASE_CLI_TOKEN**: Your Firebase CLI token for authentication
2. **FIREBASE_IOS_APP_ID**: Your Firebase iOS App ID (format: 1:xxx:ios:xxx)
3. **IOS_P12_BASE64**: Base64 encoded .p12 certificate file
4. **IOS_P12_PASSWORD**: Password for the .p12 certificate
5. **IOS_PROVISIONING_PROFILE_BASE64**: Base64 encoded provisioning profile
6. **KEYCHAIN_PASSWORD**: Password for temporary keychain (can be any secure password)
7. **DOTENV_FILE**: Your .env file content

### How to Generate Required Certificates

#### 1. Export P12 Certificate

1. Open Keychain Access on your Mac
2. Find your distribution certificate under "My Certificates"
3. Right-click and select "Export"
4. Save as .p12 file with a password
5. Convert to base64:
   ```bash
   base64 -i YourCertificate.p12 | pbcopy
   ```

#### 2. Export Provisioning Profile

1. Download your provisioning profile from Apple Developer Portal
2. Convert to base64:
   ```bash
   base64 -i YourProfile.mobileprovision | pbcopy
   ```

### Firebase Setup

1. Create an iOS app in your Firebase project
2. Get your Firebase iOS App ID from Firebase Console
3. Generate a Firebase CLI token:
   ```bash
   firebase login:ci
   ```

### Local Testing

To test the fastlane setup locally:

```bash
cd ios
bundle install
bundle exec fastlane ios build
```

---

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
