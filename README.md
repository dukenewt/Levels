# TaskBound

TaskBound is a gamified task manager for iOS and Android. Complete tasks to earn XP, level up, unlock perks, and make forced talent choices that shape your experience. Build epics (multi-task projects), track streaks, and enjoy satisfying, accessible animations.

## Features

- Levels & XP: satisfying feedback loop with streaks, loot boxes, and level thresholds.
- Perk & Talent System: forced choices at levels 5/10/15/20/25 with meaningful bonuses and gated features (e.g., Epic difficulty, Epic Projects).
- Epic Projects: plan, track, and celebrate multi-task projects; unlock exclusive themes on completion.
- IntelligentXP Engine: unified effect model and pure effect evaluation for deterministic XP breakdowns.
- Orchestrated Animations: conflict-free UI via AnimationOrchestrator; Reduced Motion supported throughout.
- Modern Architecture: CompletionPipeline, TalentPerkController, StateDelta/UiEvent, and debug flags/widgets.

## Architecture Overview

- Flutter + Firebase (Firestore, Auth, Storage)
- Provider for state management, feature-oriented modules.
- Effect model + PureEffectEngine: predictable, testable effect evaluation (perks/talents/bonuses).
- CompletionPipeline: orchestrates complete → compute → persist → emit events (snackbar, dialogs, epics).
- TalentPerkController: owns evaluated effects snapshot and publishes view state.
- AnimationOrchestrator: serializes per-entity sequences; centralized timings; respects Reduced Motion.

## Security & Secrets

- Sensitive client configs are not committed. `.gitignore` protects Firebase configs, signing files, env files, keystores, and generated artifacts.
- Security Check CI runs on pushes/PRs: blocks forbidden files and scans with Gitleaks + TruffleHog.
- Firestore rules included at `firestore.rules` (per‑user access, ownership validation).
- App Check recommended: enable (Play Integrity / App Attest), monitor, then enforce for Firestore/Storage.
- See `SECURITY.md` for setup, rotation, history cleanup (git-filter-repo/BFG), and incident response.

## Getting Started

Prerequisites
- Flutter (stable channel), Xcode (iOS), Android SDK, Firebase account
- Firebase CLI and FlutterFire CLI (`dart pub global activate flutterfire_cli`)

Clone and install
```
git clone https://github.com/dukenewt/Levels.git
cd taskbound
flutter pub get
```

Generate Firebase config (ignored by git)
```
export FIREBASE_PROJECT_ID=<your-project-id>
export ANDROID_APP_ID=com.dailyxp
export IOS_BUNDLE_ID=com.sam.dailyxp
bash scripts/bootstrap.sh
```

iOS setup
```
cd ios
pod repo update
rm -f Podfile.lock
pod install
cd ..
```

Run
```
flutter run
```

## Development Workflow

- Branching: large changes land via an integration branch (e.g., `integrate/arch-refactor`) before merging to `main`.
- CI: “Security Check” must pass; consider enabling branch protection on `main`.
- Local checks (optional): install pre-commit and add gitleaks to run locally.
- Firebase configs: regenerate with `scripts/bootstrap.sh` whenever rotating creds or adding environments.

## UI/UX Guidelines

- Platform-specific design: Material 3 on Android; Apple HIG on iOS.
- Clarity & Simplicity: clean, intuitive flows; consistent motion.
- Consistency: design tokens for color/typography/spacing; orchestrated animation sequences.
- Accessibility: Reduced Motion supported globally; respect dynamic text and contrast; haptics thoughtfully applied.

## Roadmap & Tasks

- High-level roadmap: see `ROADMAP.md` (security hardening, talent/perk stabilization, achievements).
- Active tasks and checklists: see `TODO.md`.

## Screenshots

See the `screenshots/` directory for the latest UI captures.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/...`)
3. Keep changes focused and covered by the architecture patterns above
4. Ensure CI “Security Check” passes; avoid committing client configs
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
