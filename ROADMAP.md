# TaskBound Development Roadmap

This document outlines the strategic development priorities for TaskBound, focusing on building upon the completed Epic Project Management system and enhancing the RPG experience.

## Fun‑First MVP (Pre‑Beta)
Goal: prove the core loop is fun and understandable for new users before broader beta. Focus on “complete task → get XP → level → choose talent → feel a power‑up” with minimal, polished UI.

- Objectives
  - Make early levels fast and rewarding (reach L5 in ~2–3 sessions).
  - Talent choices are few, clear, and measurably impactful.
  - Reduced Motion respected across celebrations and key flows.

- Scope (4‑Week Track)
  1. Celebration overlay v1 (Reduced Motion variant) with XP breakdown and “next level” clarity.
  2. Talent choice overhaul: impact preview (before/after XP), simplified options per gate.
  3. Material 3 pass on dashboard + task creation; real‑time XP preview during creation.
  4. Tuning/playtests: add debug panel for balance; iterate on XP curve and perks.

- Deliverables
  - `AnimationOrchestrator`-driven celebration overlay with tokenized motion; low‑motion path.
  - Talent dialog (full‑screen) with numeric effect + preview; non‑dismissable until choice.
  - Gameplay tunables centralized (e.g., `lib/gameplay/game_balance.dart`) + dev‑only debug panel.
  - Deterministic tests for `CompletionPipeline` outputs; stacking/override matrices for `PureEffectEngine`.
  - Firestore transactions for XP/level‑up and talent choice persistence.

- Acceptance Criteria
  - 80% of playtesters reach level 3 in a first 30–45 min session.
  - >60% can describe their last talent’s effect unaided.
  - Celebration overlay passes Reduced Motion audit; durations/curves pulled from `AppDesignTokens`.
  - Pipeline and effect tests green and deterministic.
  - No duplicate level‑ups or lost talent choices in offline/retry scenarios (transactional).

- References
  - ADRs: Effect Model (0001), CompletionPipeline (0002), AnimationOrchestrator (0003), Provider Boundaries (0004).
  - UX: follow Material 3/HIG, Reduced Motion, dynamic text, and contrast guidance in agents.md.

## Now / Next / Later
- Now:
  - **Progression UI Polish**: Add celebration dialogs for perk unlocks and theme unlocks to match talent choice experience
  - **Enhanced Celebrations**: Replace snackbar with orchestrated celebration overlay (Reduced Motion aware) for perk/theme unlocks
  - **Progression Testing**: Add unit tests for conditional bonus evaluation, theme unlocking, and new perk effects
  - **Balance Tuning**: Gather gameplay data to tune XP bonus percentages and conditional thresholds for optimal fun
- Next:
  - **Animation Polish**: Implement Reduced Motion in progression celebrations; centralize timings in `AppDesignTokens`
  - **Persistence Safety**: Use Firestore transactions for XP/level-up, perk unlocks, and theme unlocks to avoid races
  - **Material 3 Polish**: Update progression screens (perk display, theme selection) with Material 3 components
  - **Analytics Foundation**: Track progression metrics (time to first perk, theme unlock engagement, etc.)
- Later:
  - **Achievement System**: Build on the conditional bonus system for complex achievements
  - **Intelligent Progression**: Personalized perk recommendations based on user task patterns
  - **Advanced Mechanics**: Seasonal themes, limited-time perks, progression challenges

## Consolidation Plan (Now)
- Providers: unify on `user_provider_refactored.dart` and remove duplication.
- Pipeline: expose a single `CompletionPipeline` that sequences analyze → compute → persist → emit; keep the feature-layer helper only as a UI façade if needed.
- ✅ **Effects: route perk/talent logic through `PureEffectEngine` only; keep the "enhanced" layer as formatting for breakdowns.** (COMPLETED)
- Animations: centralize durations/curves in `AppDesignTokens`; ensure Reduced Motion across major celebratory widgets.

## Recently Completed (v0.8.0)
- **Enhanced Progression System**: Complete redesign of level progression with alternating perk/theme rewards
  - **Conditional Bonus System**: Added `conditionalBonus` perk effect type with advanced condition parsing (`>=`, `<=`, time-based, recurring tasks)
  - **7 New Gameplay Perks**: Level 1, 3, 7, 9, 11, 13 now unlock meaningful XP bonuses (Routine Master, Morning Motivation, Difficulty Dabbler, Category Explorer, etc.)
  - **4 Cosmetic Theme Unlocks**: Level 2, 4, 6, 8 unlock colorway themes (Crimson Wave, Amber Blaze, Emerald Mist, Violet Storm)
  - **Smart Context Building**: XP calculations include task recurrence, time of day, difficulty matching, category diversity
  - **Theme Integration**: Automatic theme unlocking via callback system; premium theme gating for progression rewards
  - **UI Compatibility**: Enhanced `PerkSummaryCard` with user-friendly conditional bonus descriptions

## Recently Completed (v0.7.3)
- **Architecture Cleanup & Consolidation**: completed major codebase cleanup to eliminate bloat and architectural duplication
  - **PerkEffect → PureEffect Migration**: fully removed legacy `PerkEffectEngine` system; migrated `PerkEffectResult` to simplified `PerkEffectSummary` model; all effect computation now uses `PureEffectEngine` as single source of truth
  - **Smart/Bound Suggestions Removal**: completely eliminated deprecated Smart Suggestions feature (services, widgets, UI, perks) per roadmap; removed misleading AI-like capabilities that weren't actually implemented
  - **Import Cleanup**: swept and cleaned all imports related to removed systems; updated `task_creation_dialog.dart` to use `PureEffectEngine.getEffectPreview()`
  - **Tests**: all existing functionality preserved; 9/9 tests passing after cleanup

## Recently Completed (v0.7.2)
- Notifications: implemented user preference gating for task reminders and completion celebrations via `SettingsProvider` in `TaskNotificationService`; added smoke test for notification gating functionality.

## Recently Completed (v0.7.1)
- Providers: canonicalized `UserProvider` and updated DI (ProxyProvider3) to include `TalentPerkController`.
- Pipeline UI: replaced legacy feature-layer pipeline with `presentation/flows/completion_ui_sequence.dart`; removed old file and fixed imports.
- Effects: migrated `EnhancedXPCalculationService` to use `PureEffectEngine` for compute; eliminated duplicate compute path; added import aliases to avoid collisions.
- Tests: added unit tests for PureEffectEngine and EnhancedXPCalculationService; smoke tests for provider alias and UI sequence.

## **📋 REFINED DEVELOPMENT PRIORITY LIST**
*Updated based on recent Epic Project Management implementation and existing roadmap analysis*

### Security Hardening (ongoing)
- Goal: Prevent secret/config leakage and enforce safe defaults as MAUs grow.
- Deliverables:
  - CI: Security Check workflow (Gitleaks + TruffleHog + forbidden-path guard) on pushes/PRs
  - Repo hygiene: `.gitignore` protections for Firebase configs, envs, keystores, and generated files
  - Local bootstrap: `scripts/bootstrap.sh` for FlutterFire config generation (no secrets in git)
  - Firestore: baseline rules in `firestore.rules`, App Check enablement then enforcement
  - History cleanup: `scripts/bfg_cleanup.md` and `scripts/bfg_cleanup.sh` playbooks
  - Release hygiene: publish checklist covering App Check enforcement, rules deploy, and platform signing
  - Environments: document dev/staging/prod Firebase projects and switching via bootstrap vars

### Talent & Perk System Stabilization (v1.4.x)
- Goal: Robust, testable, conflict-free talent/perk gameplay that scales.
- Deliverables:
  - Domain: normalized `Effect` model, pure `PerkEffectEngine`, deterministic `StateDelta`/`UiEvent` outputs
  - Pipeline: `CompletionPipeline` to orchestrate compute → persist → emit
    - UI: unified animations via a screen-level `AnimationOrchestrator` and Reduced Motion support
    - Tests: unit tests for engine and pipeline, talent trigger coverage, golden/widget tests, event timeline logger for debugging

### UI/UX Overhaul (v1.5)
- Modernize core screens (dashboard, creation flows, profile) with Material 3 components and consistent motion
- Reduced Motion: ensure all major animations have accessible fallbacks
- Replace epic completion snackbar with orchestrated overlay (celebration component)
- Remove legacy “Smart/Bound Suggestions” surfaces and copy

### Data & Security (v1.5)
- Notifications: honor `SettingsProvider` toggles for completion celebrations
- Firebase: add query pagination for task lists; design Firestore structure for scalable reads
- Secure storage hygiene: audit sensitive fields, minimize over-fetching, and document environment setup
 - App Check: enable, monitor, then enforce for Firestore/Storage
 - Branch protection: require Security Check CI to pass on `main`

### Integration Track --DONE
- Merge plan for architecture refactor:
  - Create `integrate/arch-refactor` from refactor branch
  - Merge rewritten `main` with `--allow-unrelated-histories`, keep security scaffolding
  - Sanity scan for forbidden files; regenerate configs; ensure CI green
  - PR into `main`


### **🏆 TIER 1: POLISH & STABILIZATION** 
*Focus: Refine the newly implemented features and ensure production readiness*

**Priority 1.1: Epic Project System Refinement**
- [ ] **User Experience Testing**
  - Test epic creation flow with various task combinations
  - Validate epic completion celebration sequence
  - Verify theme unlock persistence across app restarts
  - Test epic progress updates during task completion

- [ ] **Performance Optimization**
  - Optimize epic loading for users with many projects
  - Improve theme switching performance  
  - Memory management for large epic task lists
  - Epic creation dialog responsiveness with 50+ tasks

**Priority 1.2: Talent & Perk System Polish**
- [ ] **Enhanced Visual Feedback**
  - Talent choice celebration animations
  - Perk unlock notification improvements
  - Talent tree visualization enhancements
  - Progress indicators for next talent unlock

- [ ] **Smart Categorization Refinement**
  - Expand NLP keyword database (currently 80+ keywords)
  - Improve confidence scoring accuracy
  - Add user feedback mechanism for AI suggestions
  - Category learning from user corrections

### **🎮 TIER 2: ADVANCED RPG MECHANICS**
*Focus: Expand the gamification elements that make the app unique*

**Priority 2.1: Achievement System** 
- [ ] **Epic-Based Achievements**
  - "Epic Master": Complete 5 epic projects
  - "Theme Collector": Unlock all epic themes
  - "Project Pioneer": Create first epic project
  - "Streak Warrior": Complete epic within deadline

- [ ] **Talent-Specific Achievements** 
  - "Smart Assistant": 100 AI-categorized tasks
  - "Organization Guru": Maintain 30-day epic streak
  - "Category Expert": Master all task categories

**Priority 2.2: Advanced Epic Features**
- [ ] **Epic Templates** 
  - Pre-built epic projects (Home Renovation, Career Development, etc.)
  - Community-shared epic templates
  - Template rating and discovery system

- [ ] **Epic Collaboration** (Future)
  - Shared epic projects with family/team
  - Epic progress sharing and encouragement
  - Multi-user epic completion celebrations

### **🔧 TIER 3: TECHNICAL EXCELLENCE**
*Focus: Complete the architectural improvements identified in existing roadmap*

**Priority 3.1: Code Architecture Cleanup** *(From existing roadmap)*
- [ ] **Complete Storage Service Unification**
  - Migrate any remaining old storage service usage
  - Ensure all epic data uses SecureStorageService
  - Add comprehensive error handling for epic operations

- [ ] **Provider Responsibility Audit**
  - Verify EpicProvider doesn't overlap with TaskProvider
  - Ensure clean separation between talent and task management
  - Document provider interaction patterns

- [ ] **Architecture Docs (ADR/Overview)**
  - One-page Architecture overview or ADR covering Effect model, `CompletionPipeline`, `TalentPerkController`, and `UiEvent/StateDelta`
  - Update README links to ADR; keep diagrams minimal but current

- [ ] **Dead Code & TODO Hygiene**
  - Remove deprecated surfaces (e.g., legacy Smart/Bound Suggestions remnants)
  - Convert lingering TODOs into issues or roadmap items; prune stale notes

**Priority 3.2: Enhanced Error Handling & Resilience**
- [ ] **Epic System Error Recovery**
  - Handle corrupted epic project data gracefully
  - Epic progress recovery after app crashes
  - Theme unlock failure recovery mechanisms

**Priority 3.3: CI & Quality Gates**
- [ ] **Baseline CI Pipeline**
  - Run `flutter pub get`, `flutter analyze`, and unit tests on PRs/pushes
  - Add formatter check (`dart format --set-exit-if-changed`)
  - Add test coverage report with an initial floor (e.g., 30–40%)
- [ ] **Branch Protection**
  - Require Security Check and CI Build to pass on `main`

### **🚀 TIER 4: NEXT-GENERATION FEATURES**
*Focus: Innovative features that push the app beyond traditional task management*

**Priority 4.1: Dynamic Intelligence**
- [ ] **Adaptive Epic Suggestions**
  - AI-powered epic project recommendations
  - Smart task grouping for epic creation
  - Difficulty-based epic classification

- [ ] **Personalized Talent Recommendations**
  - Analyze user behavior to suggest optimal talent paths
  - Provide talent choice impact previews
  - Historical talent choice analytics

**Priority 4.2: Social & Community Features**
- [ ] **Epic Showcasing**
  - Share completed epic projects with community
  - Epic progress screenshots and celebrations
  - Inspiration gallery of community epics

### **📊 TIER 5: DATA & ANALYTICS**
*Focus: Understanding user behavior and optimizing engagement*

**Priority 5.1: Epic Analytics**
- [ ] **Epic Engagement Metrics**
  - Epic completion rates by talent type
  - Most popular epic project patterns
  - Theme preference analysis
  - Talent path effectiveness tracking

**Priority 5.2: Intelligent Insights**
- [ ] **Personal Progress Analytics**
  - Epic completion time predictions
  - Optimal epic size recommendations
  - Talent-based productivity insights

---

## **🎯 IMMEDIATE NEXT STEPS** 
*Recommended focus for next development session*

1. **Epic System User Testing** - Validate the core epic workflow with real usage
2. **Theme Unlock Bug Testing** - Ensure theme rewards work reliably across scenarios  
3. **Performance Optimization** - Test epic creation with large task lists
4. **Visual Polish** - Enhance epic completion animations and celebrations
5. **Achievement System Foundation** - Begin implementing epic-based achievements

---

## **📚 COMPLETED FEATURES** *(As of v1.4.0)*
- ✅ **Complete Epic Project Management System** with multi-task collections
- ✅ **Comprehensive Perk & Talent System** with forced choice dialogs
- ✅ **Theme Reward System** with epic completion unlocks
- ✅ **Enhanced Profile Display** with talent tree and perk visualization
- ✅ **Smart Categorization** with NLP keyword analysis
- ✅ **Dynamic Navigation** based on user talents
- ✅ **Enhanced XP Calculations** with perk bonuses

---

<!--
## ARCHIVED: Previous Roadmap (Commented Out for Reference)

# TaskBound Development Roadmap

This document outlines the strategic development priorities for TaskBound, focusing on perfecting the single-player RPG experience first.

## Tier 1: The Unbreakable Core Loop
*Focus: Make the app fundamentally useful and ensure the basic "game" is in place.*

- [x] **1. Flawless Task Management & Notifications:** Clean up and perfect all core task interactions (Create, Read, Update, Delete, Recurrence). Integrate a reliable notification system for task reminders.
- [x] **2. Compelling Progress Tracking:** Enhance the UI for tracking user progress (XP, level, stats). Ensure the feedback for completing tasks is clear, satisfying, and motivating.

## Tier 2: The "Secret Sauce" - Making it Fun
*Focus: Build out the unique RPG differentiation that makes the app engaging and delightful.*

- [x] **3. Skill/Improvement Tree:** Implement the skill tree, allowing users to make meaningful choices when they level up. This is the core reward system.
- [x] **4. UI & Animation Polish:** Refine the user interface and add animations to make the core loop (completing tasks, leveling up, choosing skills) feel tactile and exciting.

## Tier 3: Advanced Features
*Focus: Add major new features and intelligence that build upon the polished, stable core.*

- [x] **5. IntelligentXP Engine:** Evolve the static XP system into a dynamic engine that can assign rewards based on task difficulty, user history, or other factors.
- [ ] **6. Calendar Functionality:** Implement a full calendar view as a powerful, alternative way for users to manage and visualize their tasks.

---

## Future Ideas & Feature Backlog
*A collection of ideas extracted from changelog.md for future consideration after the core roadmap is complete.*

### Core App Enhancements
- [ ] **Advanced Onboarding:** A more detailed tutorial explaining the XP and leveling systems.
- [ ] **Performance Optimization:** Implement lazy loading and caching for users with many tasks.
- [ ] **In-App Feedback System:** Add a simple way for users to report bugs or suggest features directly within the app.
- [ ] **Analytics:** Integrate basic analytics (like Firebase) to understand feature usage and user retention.
- [ ] **Data Backup/Restore:** Add manual export/import functionality for user data peace of mind.

### Advanced RPG Mechanics
- [x] **Skill-Specific Unlocks:** Have different skills (e.g., Organization, Focus) unlock unique tools like project templates or a deep work timer.
- [x] **Adaptive Interface:** The UI could evolve and show more advanced features as a user completes more tasks and levels up.
- [ ] **Achievements:** A dedicated system for rewarding milestones and special accomplishments.

### Social & Community Features
- [ ] **Shared Templates:** Allow high-level users to share their custom task/project templates with the community.
- [ ] **Mentorship:** Potentially allow expert users to provide guidance or tips to new users.

[Previous detailed implementation roadmap archived...]
-->
