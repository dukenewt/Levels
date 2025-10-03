# TaskBound Development Roadmap

This document outlines the strategic development priorities for TaskBound, with a focus on the **Fun-First MVP** before broader beta.

## 🎯 Mission: Prove the Core Loop is Fun
**Goal**: Complete task → get XP → level → choose talent → feel a power-up

### Success Metrics (Pre-Beta)
- 80% of playtesters reach level 3 in their first 30–45 min session
- >60% can describe their last talent's effect unaided
- Early levels feel fast and rewarding (L5 in ~2–3 sessions)
- All talent choices feel measurably impactful

---

## Now / Next / Later

### 🔥 NOW (Fun-First MVP - 4 Week Track)
*Priority: Make the core loop undeniably fun before beta*

#### 1. Celebration & Feedback (Week 1-2)
- [ ] **Task Completion Celebration Overlay**
  - AnimationOrchestrator-driven overlay with XP breakdown
  - "Next level in X XP" clarity
  - Reduced Motion variant (fade/scale only, no transforms)
  - Show perk bonuses breakdown
  - Link: ADR-0003 AnimationOrchestrator

- [ ] **Real-time XP Preview**
  - Show expected XP in task creation dialog
  - Update live as user changes difficulty/category/time
  - Include active perk bonuses in preview
  - Visual indicator when perks apply

#### 2. Talent Impact & Clarity (Week 2-3)
- [ ] **Talent Choice Dialog Overhaul**
  - Full-screen dialog with before/after XP preview
  - Show numeric impact: "Routine Master: +20% XP on easy recurring tasks"
  - Example: "Complete 'Morning Exercise' → 50 XP becomes 60 XP"
  - Non-dismissable until choice made
  - Locked In talent features prominently displayed

- [ ] **Talent Feature Visibility**
  - [x] Locked In: Focus Mode tab appears after selection
  - [ ] Project Management: Epic Projects tutorial on unlock
  - [ ] NLP: "Auto-categorize" badge on task creation

#### 3. Material 3 Polish (Week 3)
- [ ] **Dashboard Modernization**
  - Material 3 cards and spacing
  - Prominent "Create Task" FAB
  - Today's goal widget at top
  - Quick access to active talents' features

- [ ] **Task Creation Flow**
  - [x] Modal bottom sheet (completed)
  - [ ] XP preview prominent at top
  - [ ] Difficulty selector with visual XP impact
  - [ ] Perk bonus indicators

- [ ] **Pomodoro Timer UI Polish** (Locked In Feature)
  - [ ] Enhanced clock animation with smooth hand sweep
  - [ ] Session completion celebration (confetti/badge animation)
  - [ ] Quick duration presets (15/25/45 min work sessions)
  - [ ] Visual state indicators (working/break/paused)
  - [ ] Sound/haptic feedback on session start/end (respects Reduced Motion)
  - [ ] History widget showing today's completed sessions
  - [ ] Integration with task completion flow (auto-start next session)

#### 4. Tuning & Balance (Week 4)
- [ ] **Gameplay Debug Panel** (dev-only)
  - Centralized tunables in `lib/gameplay/game_balance.dart`
  - Quick XP curve adjustments
  - Level skip for testing
  - Perk toggle for A/B testing

- [ ] **XP Curve Tuning**
  - Target: L3 in 30-45 min, L5 in 2-3 sessions
  - Adjust base XP, difficulty multipliers
  - Test with 5+ playtesters
  - Document findings

#### 5. Quality & Reliability (Ongoing)
- [ ] **Testing**
  - Deterministic tests for CompletionPipeline
  - Stacking/override matrices for PureEffectEngine
  - Talent unlock integration tests

- [ ] **Persistence Safety**
  - Firestore transactions for XP/level-up
  - Talent choice persistence with conflict resolution
  - No duplicate level-ups or lost choices

---

### 🚀 NEXT (Post-MVP)
*After Fun-First MVP is validated*

#### Motion & Performance
- **Motion Baseline + Gating**
  - Default to Basic Motion: progress fill (180–220ms), number count-up (≤300ms)
  - Gate Advanced Motion (orbs, ring-unravel, shatter) behind feature flag (default off)
  - Motion Debug panel with dev override (Off/Default/On)
  - Tokenize all durations/curves via AppDesignTokens
  - Reduced Motion audit: crossfades only, no transforms/path motion

- **Performance Targets**
  - p95 frame ≤16.6ms, <1% dropped frames on Pixel 5 / iPhone 11
  - Timeline markers around key sequences
  - Performance Overlay during playtests

#### Polish & Features
- **Advanced Motion Polish** (behind flag)
  - Improve orb aesthetics (simplify glow, 2–4 streams)
  - Shorten ring-unravel phases
  - Shared-element badge pop with Reduced Motion fallback

- **Material 3 Completion**
  - Profile screen modernization
  - Settings screen redesign
  - Stats screen charts and visuals

- **Analytics Foundation**
  - Progression metrics (time to first perk, etc.)
  - Talent selection patterns
  - Feature usage by talent type

---

### 🔮 LATER (Future Expansion)
*After product-market fit is proven*

- **Achievement System**: Build on conditional bonus system
- **Intelligent Progression**: Personalized perk recommendations
- **Advanced Mechanics**: Seasonal themes, limited-time perks, challenges
- **Social Features**: Share achievements, compare talent builds
- **Advanced Analytics**: User cohorts, retention analysis

---

## 📦 Recently Completed

### v0.8.3 - Locked In Talent Path (Focus & Productivity) - Oct 2025
- **Third Talent Tree Added**: "Locked In" focuses on deep work and productivity
  - **Level 5 "Focus Master"**: Unlocks Pomodoro timer with animations + Quiet Mode
  - **Level 10 "Workflow Optimizer"**: Task prioritization, due date prominence, break suggestions
  - Talent selection dialog now offers 3 choices at levels 5 and 10
  - Dynamic navigation: Focus Mode tab appears for Locked In users

- **Core Services** (4 new)
  - **PomodoroTimerService**: 25/5 min work/break cycles, session tracking, persistent state
  - **QuietModeService**: Notification blocking with timed/indefinite modes, auto-expiration
  - **BreakSuggestionService**: Smart break reminders after 50 min work, rotating break types
  - **TaskPrioritizationService**: 5 sorting strategies, urgency detection, completion goals

- **UI Components**
  - **PomodoroTimerWidget**: Circular clock with gradient progress ring, pulse animation (Reduced Motion aware)
  - **FocusModeScreen**: Complete productivity dashboard with timer, break tracking, and task prioritization
  - **Due Date Prominence** (Level 10): Color-coded chips using difficulty colors (green/orange/red/purple)

- **Integration**
  - Services integrated into app provider tree
  - Quiet Mode hooks into notification system
  - Talent-based feature gating throughout app
  - All features respect Reduced Motion settings

### v0.8.2 - Epic UX & Theme Rewards - Oct 2025
- Epic UX: Task search in Epic creation, inline task creation, bottom sheet completion
- Reward celebration with theme preview chip, "Apply Theme", and "Manage Themes" actions
- Difficulty Gating: Epic difficulty reserved for Epic context only
- Celebration Motion: Reduced Motion–aware fade/scale timing via AnimationOrchestrator

### v0.8.1 - Animation Architecture Hardening - Sep 2025
- Animation Architecture Overhaul: Enhanced AnimationOrchestrator with lifecycle management
- Streamlined Wheel of Time Widget: Reduced from 7 controllers to 2
- Motion Debug + Gating: Motion Debug overlay, Advanced Motion flag (default off)
- Ring Center Cleanup: Removed level number badge for cleaner design

---

## 🔧 Technical Debt & Consolidation

### Architecture
- [ ] Providers: unify on `user_provider_refactored.dart` and remove duplication
- [ ] Pipeline: expose a single `CompletionPipeline` that sequences analyze → compute → persist → emit
- ✅ Effects: route perk/talent logic through `PureEffectEngine` only (COMPLETED)
- ✅ Animations: centralized with `AnimationOrchestrator` (COMPLETED)

### Security & Infrastructure
- [ ] CI: Security Check workflow (Gitleaks + TruffleHog) on pushes/PRs
- [ ] Firestore: baseline rules, App Check enablement then enforcement
- [ ] Branch protection: require Security Check CI to pass on `main`

### Testing
- [ ] Deterministic tests for CompletionPipeline outputs
- [ ] Stacking/override matrices for PureEffectEngine
- [ ] Talent unlock integration tests
- [ ] Golden/widget tests for key flows

---

## 📚 Version History (Detailed)

### v0.8.1 - Animation Architecture Hardening (Sep 2025)
- **Animation Architecture Overhaul**: Major refactor of animation system for gaming-level polish and maintainability
  - **Enhanced AnimationOrchestrator**: Added controller lifecycle management, choreographed sequences, and automatic disposal
  - **Streamlined Wheel of Time Widget**: Reduced from 7 animation controllers to 2, significantly cleaner codebase
  - **OrchestrationMixin**: Provided clean widget integration pattern for managed animations
  - **Motion Debug + Gating**: Added Motion Debug overlay, frame timing logger, and Advanced Motion flag (default off)
  - **Basic Level-Up Panel**: Minimal scale+fade panel replaces heavy celebration by default
  - **Ring Center Cleanup**: Removed level number badge from ring center

- **Ring Visualization System**: Resolved critical rendering issues and improved visual feedback
  - **Fixed Ring Visibility**: Added explicit size constraints to CustomPaint resolving invisible ring issue
  - **Enhanced XP Orb System**: Redesigned from random bubbles to deterministic energy streams
  - **Improved Targeting**: Implemented accurate orb targeting to ring progress endpoints
  - **Smooth Ring Rotation**: Eliminated jarring stops during animations with gradual slowdown

- **Level-Up Animation Enhancements**: Performance and visual improvements to celebration sequences
  - **Ring Unraveling Optimization**: Reduced segment count from 120 to 60 for smoother performance
  - **Simplified Physics**: Replaced complex gravity simulation with clean easing curves
  - **Professional Visual Effects**: Modernized shadows and timing for polished appearance
  - **Adaptive Timing**: Implemented Reduced Motion support with shorter durations

- **System Integration**: Comprehensive cleanup and professional polish
  - **Talent Dialog Fix**: Resolved blocking issue when no talent choices available
  - **Debug System Cleanup**: Removed excessive logging and debug markers from production
  - **Level Progress Card**: Integrated OrchestrationMixin with proper lifecycle management
  - **Animation Consistency**: Standardized timing and reduced motion support across components

- **Code Quality Improvements**: Enhanced maintainability and professional standards
  - **Removed Legacy Code**: Eliminated complex physics calculations in favor of Flutter curves
  - **Improved Documentation**: Updated animation system with clear architectural patterns
  - **Performance Optimization**: Reduced computational overhead in custom painters

### v0.8.0 - Enhanced Progression System (Sep 2025)
- **Enhanced Progression System**: Complete redesign of level progression with alternating perk/theme rewards
  - **Conditional Bonus System**: Added `conditionalBonus` perk effect type with advanced condition parsing (`>=`, `<=`, time-based, recurring tasks)
  - **7 New Gameplay Perks**: Level 1, 3, 7, 9, 11, 13 now unlock meaningful XP bonuses (Routine Master, Morning Motivation, Difficulty Dabbler, Category Explorer, etc.)
  - **4 Cosmetic Theme Unlocks**: Level 2, 4, 6, 8 unlock colorway themes (Crimson Wave, Amber Blaze, Emerald Mist, Violet Storm)
  - **Smart Context Building**: XP calculations include task recurrence, time of day, difficulty matching, category diversity
  - **Theme Integration**: Automatic theme unlocking via callback system; premium theme gating for progression rewards
  - **UI Compatibility**: Enhanced `PerkSummaryCard` with user-friendly conditional bonus descriptions

### v0.7.3 - Architecture Cleanup (Aug 2025)
- **PerkEffect → PureEffect Migration**: Removed legacy `PerkEffectEngine` system
- **Smart/Bound Suggestions Removal**: Eliminated deprecated feature completely
- **Import Cleanup**: Swept all imports related to removed systems
- All tests passing (9/9) after cleanup

### v0.7.2 - Notification Preferences (Aug 2025)
- User preference gating for task reminders and completion celebrations
- Smoke tests for notification gating functionality

### v0.7.1 - Provider Consolidation (Aug 2025)
- Canonicalized `UserProvider` with `TalentPerkController` DI
- Pipeline UI: unified completion sequence
- Effects: migrated to `PureEffectEngine` as single source of truth
- Added unit tests for PureEffectEngine and EnhancedXPCalculationService

---

## 📚 References & ADRs

### Architecture Decision Records
- **ADR-0001**: Effect Model - Pure functional approach to perk/talent effects
- **ADR-0002**: CompletionPipeline - Unified task completion flow
- **ADR-0003**: AnimationOrchestrator - Centralized animation management
- **ADR-0004**: Provider Boundaries - Clear separation of concerns

### Design Guidelines
- **UX**: Material 3/Apple HIG compliance
- **Accessibility**: Reduced Motion support, dynamic text, contrast
- **Performance**: p95 frame ≤16.6ms, <1% dropped frames target

---

**Last Updated**: October 2025
**Current Version**: v0.8.3
**Status**: Fun-First MVP in progress
