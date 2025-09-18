# Security Policy and Setup

This document describes how we protect secrets/configuration and how to set up the project securely.

## Never Commit (policy)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `ios/Runner/firebase_config.swift`
- Any `*.env*`, `*.p12`, `*.mobileprovision`, `*.jks`, `*keystore*`, private keys, or credentials

These are blocked by `.gitignore` and CI. CI enforces a shared list in `scripts/forbidden-paths.txt`. If you accidentally commit any, rotate and run history cleanup.

## Local Setup
1. Ensure you have Flutter, Dart, Firebase CLI, and FlutterFire CLI installed.
2. Set environment variables for your Firebase project:
   - `export FIREBASE_PROJECT_ID=your-project-id`
   - Optional (defaults provided):
     - `export ANDROID_APP_ID=com.dailyxp`
     - `export IOS_BUNDLE_ID=com.sam.dailyxp`
3. Run `bash scripts/bootstrap.sh` to generate `lib/firebase_options.dart` (ignored by git).

## CI/CD Secret Scanning
- GitHub Actions workflow at `.github/workflows/security-check.yml` runs on push/PR:
  - Denies commits containing forbidden files.
  - Runs Gitleaks and TruffleHog scans to catch credentials.

## Firestore Security Rules
A recommended baseline lives in `firestore.rules`. Enforce per-user access and validate ownership on writes. Deploy via Firebase Console/CLI.

## App Check
Enable Firebase App Check:
- Android: Play Integrity
- iOS: App Attest (or DeviceCheck fallback)

In app initialization:
```
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

## History Cleanup (BFG/git filter-repo)
If secrets ever hit history:
1. Rotate the compromised credentials immediately in provider consoles.
2. Prepare a maintenance window and notify contributors (history rewrite is disruptive).
3. Use git-filter-repo or BFG to strip files (see `scripts/bfg_cleanup.md`).
4. Force-push protected branches; local clones must reclone or hard-reset.
5. Verify CI/build and tags after rewrite.

## Incident Response
- Rotate keys/tokens.
- Remove secrets from code and history.
- Audit access logs where possible.
- Post-mortem: add rules/tests to prevent repeat.
