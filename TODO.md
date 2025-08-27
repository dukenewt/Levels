# TaskBound- Perk & Talent System Implementation

## 🌟 PROJECT OVERVIEW
This is a **Flutter/Dart gamified task management application** with a sophisticated XP progression system. The app helps users build habits by gamifying task completion with levels, XP, streaks, and now a comprehensive **perk and talent specialization system**.

### Core App Architecture:
- **Flutter + Firebase** (Firestore, Auth, Storage)
- **Provider Pattern** for state management
- **Feature-based architecture** with domain-driven design
- **Existing Systems**: Intelligent XP engine, streak tracking, loot boxes, recurring tasks


## 🔐 Security/Config Follow-ups (from recent review)

- [x] Rotate Firebase client credentials and redistribute fresh `GoogleService-Info.plist` / `google-services.json`
- [x] Purge sensitive files from git history (if ever committed):
      `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`, `ios/Runner/firebase_config.swift`, `firebase.json`
- [x] Add a bootstrap script to generate Firebase configs locally/CI via FlutterFire (`scripts/bootstrap.sh`)
- [x] Document local setup in SECURITY.md (setup, incident response, App Check)
- [x] Add a CI check to block commits containing forbidden patterns; run Gitleaks/TruffleHog
- [x] Widen workflow triggers to run on all pushes/PRs and manual dispatch
- [ ] Enable App Check, monitor, then enforce for Firestore/Storage
- [ ] Deploy `firestore.rules` to Firebase; add to release checklist
- [ ] Add branch protection requiring “Security Check” to pass on `main`

---

## 🧭 Talent & Perk System Stabilization (Architecture Tasks)

Goal: Resolve critical issues and make the talent/perk system robust, testable, and maintainable without sacrificing animations or UX flair.

1) Domain and Data Modeling
- [ ] Normalize effects: define a single `Effect` model (scope: global/category/task, modifier: additive/multiplicative, duration/stacking)
- [ ] Define `StateDelta` and `UiEvent` objects returned by completion flows
- [ ] Make `PerkEffectEngine` pure: input (User, Task, Context) -> output (Breakdown, Deltas, Events)

2) State Management Boundaries
- [ ] Create `TalentPerkController` (`ChangeNotifier`) that owns evaluated effects snapshot and publishes view state
- [ ] Limit `UserProvider` to user persistence; route effect evaluation through the controller
- [ ] Introduce `CompletionPipeline` service to orchestrate: analyze → compute → persist → emit events

3) Animation Orchestration (conflict-free)
- [ ] Introduce a per-screen `AnimationOrchestrator` that:
      - provides controllers by entity id
      - serializes conflicting sequences (queue/locks)
      - centralizes tokens (durations/curves) using `AppDesignTokens`
- [ ] Convert scattered explicit controllers to orchestrator-managed or implicit animations
- [ ] Add Reduced Motion setting; orchestrator no-ops or shortens animations when enabled

4) Testing and Debuggability
- [ ] Unit tests for `PerkEffectEngine` (idempotence, stacking, category overrides)
- [ ] Unit tests for `CompletionPipeline` (deterministic `StateDelta` for given context)
- [ ] Log-only mode: toggle to record event timelines without running animations (for debugging)

5) Performance/Resilience
- [ ] Ensure item-level keys and avoid full list rebuilds during per-item animations
- [ ] Use `TickerMode` for offstage widgets; dispose controllers via orchestrator
- [ ] Guard against double-taps and race conditions in completion flow

6) UX Consistency
- [ ] Unify completion animation set across swipe/tap actions
- [ ] Add haptic feedback timing from `AppDesignTokens`
- [ ] Ensure Material 3 semantics (shape, elevation, color) across new widgets

---

## 🎯 Immediate Bug-Fix Sprint (Talent/Perk Critical)

- [ ] Fix: talent selection not showing at thresholds (ensure detection runs after level-up commit and navigation is ready)
- [ ] Fix: conflicting animations cancel each other (introduce orchestrator; sequence checkmark → slide-out → confetti)
- [ ] Fix: state races between `UserProvider` and `TaskProvider` updates (run via `CompletionPipeline` transaction)
- [ ] Add: defensive `SafeAnimationController` usage everywhere controllers remain local

---

## 🔔 Notifications Respect Preferences

- [x] Ensure `CompletionPipeline` checks preferences before issuing immediate notifications
- [ ] Wire `TaskNotificationService` reminder scheduling/cancellations to `SettingsProvider` toggles (task reminders, overdue, re-engagement)
- [ ] Add quick unit smoke test or manual checklist for each toggle

---

## 🧠 Talent Dialog & Selection Flow

- [ ] Re-enable forced talent dialog after level-up using post-frame trigger with single-fire guard
- [ ] Add pipeline event to request dialog (avoid firing from `UserProvider` directly)
- [ ] Verify thresholds (5/10/15/20/25) and persist `talentChoices` only once per level

---

## 🎯 Perks Cleanup

- [x] Remove "Smart Suggestions" / "Bound suggestions" perk entirely from data and UI
- [ ] Audit `EnhancedUserPerks` and UI surfaces to eliminate references
- [ ] Validate remaining perks apply only desired effects via `PerkEffectEngine`

---

## 🎉 Epic Completion UX

- [x] Replace snackbar with orchestrated overlay celebration (Reduced Motion aware) — initial dialog in pipeline
- [ ] Optionally unlock theme rewards via `ThemeProvider` when epic completes (policy-dependent)

---

## ♿ Reduced Motion Toggle (UI)

- [ ] Add a settings toggle UI bound to `SettingsProvider.setReducedMotion()`
- [ ] Audit `ring_unraveling_celebration.dart` and `xp_orb_overlay.dart` for Reduced Motion and safe controllers

### Animation Polish: Wheel of Time
- [ ] Revisit the "Wheel of Time" animation: migrate to orchestrator-managed sequence, ensure it doesn’t conflict with completion/snackbar dialogs, and respect Reduced Motion.

---

## 🔀 Architecture Refactor Integration Track

- [x] Create `integrate/arch-refactor` from refactor branch
- [x] Merge rewritten `main` with `--allow-unrelated-histories`; keep security scaffolding from `main`
- [x] Regenerate local Firebase configs via bootstrap; verify no sensitive files tracked
- [x] Ensure Security Check CI passes on integration branch
- [ ] Open/merge PR into `main` after functional verification (Android/iOS build + smoke tests)
tough