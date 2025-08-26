## PR Title

Integration baseline: secure merge to main, reset to 0.7.0, enforce security gates

## Summary
- Establish a secure, stable baseline on `main` after history cleanup.
- Use pre-1.0 SemVer (`0.7.0`) while continuing stabilization work.
- Verify security controls (secret scanning, forbidden paths, .gitignore) and baseline CI.
- Merge via merge commit to preserve traceability; tag `v0.7.0` post-merge.

## High-Level Decisions
- Pre-1.0 SemVer: allows minor-series breaking changes during stabilization.
- Merge-then-tag baseline: create a known-good, security-checked point to branch from.
- Defense-in-depth: prevent secret leaks via CI gates and .gitignore; generate Firebase configs locally only.

## Checklist

### Versioning and App Metadata
- [ ] `pubspec.yaml` set to `version: 0.7.0+<build>` (build > last iOS/Android build)
- [ ] iOS/Android pick up Flutter version (no manual overrides committed)
- [ ] CHANGELOG explains renumbering (1.x were internal, pre-1.0 starts at 0.7.0)

### Security: Repo Hygiene
- [ ] `.gitignore` protects sensitive and generated files:
  - Firebase: `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, `ios/Runner/firebase_config.swift`, `firebase.json`
  - Envs/Secrets: `.env*`, `**/secrets/**`, `**/*_secret.*`, `**/*_key.*`, `**/private_keys/**`
  - Keystores: `android/**/keystore*`, `*.jks`
  - Local DB/Media: `**/*.sqlite`, `**/database.db`, `**/user_data/`, `**/sensitive_images/`, `**/private_media/`
  - Generated: `build/`, `.dart_tool/`, `ios/Pods/`, `android/build/`
- [ ] PR diff contains none of the above

### Security: CI Gates
- [ ] Security Check passes (PR and merge to `main`):
  - [ ] Gitleaks: 0 findings
  - [ ] TruffleHog: 0 findings
  - [ ] Forbidden paths guard: 0 matches
- [ ] Branch protection requires Security Check + Flutter CI on `main`

### Security: Firebase/Config
- [ ] `scripts/bootstrap.sh` generates Firebase configs locally (not committed)
- [ ] `firestore.rules` tracked; included in release checklist
- [ ] App Check plan documented (enable → monitor → enforce)
- [ ] SECURITY.md includes rotation/history cleanup/App Check/local setup

### Build, Lint, and Tests
- [ ] CI runs: `flutter pub get` / format check / analyze / tests
- [ ] Optional pre-merge builds: Android appbundle or APK; iOS `--no-codesign` (macOS runner)
- [ ] CI is green

### Functional Smoke Tests
- [ ] App launches with generated Firebase configs; sign-in works
- [ ] Completing a task runs `CompletionPipeline`; XP increments; no provider race warnings
- [ ] Reduced Motion toggle respected by a visible animation
- [ ] Talent dialog triggers at thresholds in dev flow (post-frame, single-fire guard)
- [ ] No references to removed “Smart/Bound Suggestions” in UI (or follow-up filed)

### Merge Hygiene
- [ ] Strategy: Create a merge commit (do not squash/rebase)
- [ ] Acknowledge large diff (intentional integration)
- [ ] Post-merge tag: `v0.7.0`

### Post-Merge Follow-Ups (track via issues)
- [ ] Enable App Check (monitor → enforce) and deploy `firestore.rules`
- [ ] Land `AnimationOrchestrator` on key screens; wire Reduced Motion
- [ ] Finalize pure `PerkEffectEngine` + unit tests; add `CompletionPipeline` tests
- [ ] Wire notification scheduling to `SettingsProvider` toggles; add smoke checklist
- [ ] Remove any lingering “Smart/Bound Suggestions” references
- [ ] Add ADR/overview: Effect model, `CompletionPipeline`, `TalentPerkController`, `UiEvent/StateDelta`

## Notes
- Use merge commit to preserve traceability of the integration.
- Ensure branch protection is turned on for `main` before merging.
