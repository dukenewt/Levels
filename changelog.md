# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Gem shatter overlay effect on task completion with OrchestrationMixin integration
- XP orbs overlay with deterministic energy streams flowing to ring progress endpoints
- Level number badge over the ring (temporary visual until final badge art)
- Visual debug indicators for orb targeting during development

### Changed
- Enhanced ring unraveling celebration with performance optimizations
  - Reduced segment count from 120 to 60 for smoother animation
  - Simplified physics simulation with clean easing curves instead of complex calculations
  - Modernized visual effects with subtle shadows and improved timing
- Improved XP orb visual design and behavior
  - Redesigned orb system as energy streams instead of random bubbles
  - Added deterministic targeting to ring progress endpoints
  - Enhanced particle appearance with bright cores and improved glow effects
  - Dynamic orb count based on XP amount (2-6 orbs)
- Refined ring rotation during animations
  - Smooth slowdown instead of abrupt stopping during orb flight
  - Maintains visual continuity while ensuring accurate orb targeting
- Updated level progress card animation system
  - Integrated OrchestrationMixin for proper lifecycle management
  - Added adaptive timing for Reduced Motion support
  - Reduced shimmer duration and scale effects for subtlety

### Fixed
- Ring visibility issue resolved by adding explicit size constraints to CustomPaint
- XP orb targeting accuracy improved with proper ring anchor endpoint calculations
- Ring rotation interference with orb targeting eliminated
- Talent dialog blocking issue when no choices available at level unlock
- iOS dialog assertion by providing barrierLabel to showGeneralDialog
- Multiple layout assertions by ensuring painters are wrapped with SizedBox.expand
- Debug logging spam removed from console output

### Removed
- Complex physics simulation in ring unraveling (replaced with cleaner easing)
- Excessive debug logging throughout animation system
- Visual debug markers from production builds

### Known issues / Follow‑ups
- XP orb visual refinement still in progress for professional polish
- Level badge visual needs refinement to match design language; awaiting art assets
- Carryover XP fill after level-up not yet implemented
- Animation system requires further professional polish despite functional improvements


## [0.8.1] - 2025-09-26

### Changed — Animation Architecture Overhaul
- **Enhanced AnimationOrchestrator**: Major refactor for centralized animation management and gaming-level polish
  - Added controller lifecycle management with automatic disposal
  - Implemented choreographed animation sequences with built-in timing control
  - Enhanced with controller pooling and named grouping for efficient resource management
  - Added preset animation sequences for common UI patterns (celebration, task completion, etc.)

- **Streamlined Animation Controllers**: Significant reduction in animation complexity across widgets
  - **Wheel of Time Progress Widget**: Reduced from 7 animation controllers to 2 controllers
  - Consolidated rotation, pulse, and progress animations under unified orchestration
  - Maintained all visual effects while dramatically simplifying code structure

- **OrchestrationMixin**: New widget integration pattern for clean animation management
  - Automatic controller creation and disposal through mixin lifecycle
  - Simplified API for creating animations with consistent curves and timing
  - Built-in support for choreographed animation sequences

### Added — Animation Foundation
- **Centralized Reduced Motion Support**: Consistent accessibility implementation across all animations
  - Automatic duration adjustment (70% reduction) when reduced motion is enabled
  - Built-in curve simplification for accessibility compliance
  - Global reduced motion state management through AnimationOrchestrator

- **Animation Specification System**: Standardized animation definitions for consistency
  - Predefined animation specs for common durations and curves (quick, medium, slow, bounce, celebration)
  - Type-safe animation step definitions for complex sequences
  - Enhanced debugging and maintainability through structured animation definitions

### Fixed — Build and Stability
- **iOS Build Compatibility**: Resolved naming conflicts in AnimationOrchestrator
  - Fixed duplicate 'delay' declaration that prevented iOS compilation
  - Cleaned up import dependencies and unused code references
  - Improved type safety and eliminated shadowing warnings

### Technical — Architecture Improvements
- **Animation Code Reduction**: Significant codebase cleanup and consolidation
  - Eliminated duplicate animation logic across multiple widgets
  - Centralized animation timing and curve definitions
  - Improved maintainability through consistent patterns and shared infrastructure

## [0.8.0] - 2025-09-25

### Added — Enhanced Progression System
- **Alternating Perk/Theme Unlock System**: Complete redesign of level progression with meaningful rewards at every level
  - **Odd Levels (1,3,5,7,9,11,13...)**: Unlock gameplay perks with real XP bonuses and conditional effects
  - **Even Levels (2,4,6,8...)**: Unlock cosmetic theme colorways for visual customization
  - **Level 1**: Routine Master (+20% XP for easy recurring tasks)
  - **Level 3**: Task Starter (+10% XP for all tasks)
  - **Level 7**: Morning Motivation (+15% XP for tasks completed before noon)
  - **Level 9**: Difficulty Dabbler (+15% XP for medium difficulty tasks)
  - **Level 11**: Category Explorer (+10% XP when completing 3+ categories per day)
  - **Level 13**: Consistency Champion (+10% XP for all tasks)

- **Cosmetic Theme Unlock System**: Four new colorway themes unlocked through level progression
  - **Level 2**: Crimson Wave (bold red colorway)
  - **Level 4**: Amber Blaze (warm amber/gold colorway)
  - **Level 6**: Emerald Mist (fresh emerald/jade colorway)
  - **Level 8**: Violet Storm (deep violet/purple colorway)

### Enhanced — Conditional Effect Engine
- **Advanced Conditional Bonuses**: New `conditionalBonus` perk effect type with sophisticated condition parsing
  - Supports operators: `>=`, `<=`, `>`, `<`, `equals` for numeric and boolean conditions
  - Smart condition parsing for difficulty, recurring status, time of day, category counts
  - Context-aware XP calculation including task recurrence, morning completion, difficulty matching
  - Enhanced Effect model with comprehensive condition evaluation system

- **Smart Context Building**: XP calculations now include rich contextual data
  - Task recurrence status (`recurring: task.recurrencePattern != null`)
  - Time-based conditions (`is_morning: completionTime.hour < 12`)
  - Difficulty matching for targeted bonuses
  - Daily category diversity tracking for exploration bonuses

### Technical Implementation
- **Enhanced PureEffectEngine**: Full support for conditional bonus evaluation with complex condition matching
- **Theme Provider Integration**: Automatic theme unlocking via `onThemeUnlock` callback system
- **UI Compatibility**: Updated `PerkSummaryCard` with user-friendly conditional bonus descriptions
- **Backwards Compatibility**: All existing perks and functionality preserved

### Planning
- Roadmap consolidated with a Now/Next/Later section; `TODO.md` reduced to a pointer.

### ADRs
- Added ADR index and stubs for core architecture decisions (Effect model, CompletionPipeline, AnimationOrchestrator, Provider boundaries).

### Security (ongoing)
- App Check: enable → monitor → enforce for Firestore/Storage (pending enforcement step).


## [0.7.3] - 2025-09-25

### Removed — Architecture Cleanup & Consolidation
- **🧹 Completed major codebase cleanup to eliminate bloat and architectural duplication**
  - **PerkEffect System Removal**: Fully removed legacy `PerkEffectEngine` system and related files
    - Deleted `lib/services/perk_effect_engine.dart` completely
    - Migrated `PerkEffectResult` usage to simplified `PerkEffectSummary` model in `enhanced_xp_calculation_service.dart`
    - Updated `task_creation_dialog.dart` to use `PureEffectEngine.getEffectPreview()` instead of old engine
    - All effect computation now uses `PureEffectEngine` as single source of truth
  - **Smart/Bound Suggestions Feature Removal**: Completely eliminated deprecated AI-like feature per roadmap
    - Deleted `lib/services/smart_suggestions_service.dart` and `lib/widgets/smart_suggestions_widget.dart`
    - Removed Smart Suggestions perk definition from `user_perk.dart` (level 3 perk)
    - Disabled Smart Suggestions in `enhanced_game_experience_manager.dart` level progression
    - Removed "Smart Difficulty Suggestions" from talent management features list
    - Removed Smart Suggestions widget usage from task dashboard screen
    - Cleaned up all imports and references throughout codebase

### Technical
- **Import Cleanup**: Swept and cleaned all imports related to removed systems
- **Tests**: All existing functionality preserved; 9/9 tests passing after cleanup
- **Static Analysis**: No compilation errors or functional regressions introduced

### Impact
- **Reduced Codebase Bloat**: Eliminated unused and misleading features that weren't providing real value
- **Cleaner Architecture**: Single source of truth for effect computation via `PureEffectEngine`
- **Honest UX**: Removed UI elements that promised AI capabilities that weren't actually implemented
- **Maintenance**: Easier to maintain with fewer duplicated systems and cleaner dependencies


## [0.7.2] - 2025-08-28

### Fixed — Notification Gating
- **🎯 Notifications now respect user preferences**: Fixed critical issue where notifications ignored `SettingsProvider` toggles
  - Task reminders now respect `enableTaskReminders` setting in `TaskNotificationService.scheduleTaskReminder()`
  - Completion celebrations now respect `enableCompletionCelebrations` setting in `TaskNotificationService.showImmediateNotification()`
  - Settings work independently - users can enable task reminders but disable celebrations, or vice versa
  - Updated all notification call sites in `TaskProvider` (4 locations) and `CompletionUiSequence` to pass settings
  - Added debug logging when notifications are skipped due to user preferences

### Added — Tests
- **📋 Notification Gating Smoke Test**: Added `task_notification_service_test.dart` to verify settings integration
  - Tests that notification preferences can be independently controlled
  - Verifies notification gating integration points exist and function correctly
  - Ensures backward compatibility for existing notification calls

### Technical
- Enhanced `TaskNotificationService` methods to accept `SettingsProvider` parameters with proper gating logic
- Maintained backward compatibility by making settings parameter optional in `showImmediateNotification()`


## [0.7.1] - 2025-08-28

### Changed — Consolidation & Effects
- Providers: canonicalized `UserProvider` (refactored) via `providers/user_provider.dart` re‑export; updated provider wiring in `main.dart` to inject `TalentPerkController` (ProxyProvider3).
- Pipeline: removed legacy feature-layer pipeline and introduced `presentation/flows/completion_ui_sequence.dart` as a UI‑only sequence orchestrated by `AnimationOrchestrator`.
- Effects: migrated `EnhancedXPCalculationService` to compute perk/talent bonuses via `PureEffectEngine` as single source of truth; resolved class name collisions with import aliases.

### Added — Tests
- Unit tests for `PureEffectEngine` and `EnhancedXPCalculationService`.
- Smoke tests for provider alias export and UI sequence symbol presence.

### Fixed
- Build issues from stale imports and provider constructor changes after refactor.

### Docs
- Roadmap updated with consolidation plan under “Now”.


## [0.7.0] - 2025-08-28

### Added
- ADR index (`docs/adr/0000-index.md`) and initial ADR stubs (0001–0004).
- Roadmap consolidation with top-level Now/Next/Later priorities.

### Fixed
- Talent selection dialog reliably triggers at levels 5/10/15/20/25.

### Security & Docs
- Hardened docs around secrets handling and CI security checks; clarified versioning note about earlier internal 1.x milestones.

---

## [1.x Internal Milestones] (pre-public)

## [1.5.0] - 2025-08-21

### Fixed - Critical Talent Selection Bug 🔧
- **🎯 Talent Dialog Now Triggers Correctly**: Fixed critical bug where talent selection dialog would not appear at levels 5, 10, 15, 20, 25
  - Implemented new `TalentPerkController` with proper state management and change detection
  - Added `TalentTriggerService` to bridge new architecture with existing UI
  - Added comprehensive integration testing to verify talent system functionality
  - Fixed race conditions and timing issues that prevented talent dialog from appearing

### Enhanced - Architecture Foundation 🏗️
- **🔧 Normalized Effect System**: Introduced unified `Effect` model for consistent perk and talent calculations
  - Replaced scattered effect logic with single `Effect` class supporting scope, modifier, stacking, and duration
  - Created `StateDelta` and `UiEvent` objects for clean separation of state changes and UI actions
  - Implemented pure `PureEffectEngine` for predictable, testable effect evaluation
  
- **🎯 Clean State Management**: Separated persistence from effect evaluation with clear boundaries
  - `TalentPerkController` owns effect evaluation and publishes view state
  - Refactored `UserProvider` to focus purely on data persistence
  - Added `CompletionPipeline` service for orchestrated task completion flow

### Technical Improvements
- **🧪 Integration Testing Framework**: Added comprehensive testing for architectural changes
  - Real-time testing with actual user data alongside existing system
  - Feature flag system for safe incremental rollout
  - Debug widgets showing system status and test results in development mode

- **🔒 Error Handling**: Improved provider lifecycle management and hot reload stability
  - Fixed `setState()` during build errors
  - Added safety checks for disposed providers during hot reload
  - Graceful fallback handling between old and new systems

### Developer Experience
- **📊 Debug Visibility**: Added debug widgets for monitoring new architecture
  - Feature flag status display
  - Integration test results
  - Talent trigger service monitoring
  - Effect evaluation status

### Backwards Compatibility
- **♻️ Zero Breaking Changes**: New architecture runs alongside existing system
  - Existing talent selection UI preserved and enhanced
  - All existing functionality continues to work unchanged
  - Incremental migration path with rollback capability

### Security
- Hardened `.gitignore` with additional protected patterns (secrets, keys, keystores, local databases, sensitive media)
- Treated Firebase client configs as sensitive per policy and documented local regeneration via FlutterFire

### Documentation
- Added Security and Secrets Policy to README, with steps for key rotation and history cleanup
- Roadmap updated with Talent/Perk stabilization plan and animation architecture direction

### Refactor and Architecture
- Added `AnimationOrchestrator` to serialize per-entity UI sequences and prevent animation conflicts
- Introduced `CompletionPipeline` to centralize post-completion flow (streak update, notifications, XP snackbar, breakdown, epic update)
- Fixed level-up XP threshold loop in `UserProvider.addXp()` (multi-level gains now correct)
- Unified loot box logic under `IntelligentXPEngine` to avoid duplication
- Added `StreakService` for consistent streak read/write; removed direct writes from `TaskCompletionService`
- Added Reduced Motion support via `SettingsProvider.reducedMotion` and respected it in pipeline and Wheel of Time widget
- Updated `WheelOfTimeProgress` to use design tokens, safe controllers, and Reduced Motion behavior
- Moved talent dialog invocation to post-frame to avoid navigator timing races

### Improvements
- Notifications now respect user preferences: immediate completion notifications gated by `enableCompletionCelebrations`
- Removed deprecated "Smart/Bound Suggestions" perk and references
- Epic completion now uses an orchestrated dialog (placeholder overlay) instead of only a snackbar

### Known Issues (to be addressed)
- Perk "Smart Suggestions"/"Bound suggestions" must be removed entirely from perks.
- Epic completion celebration is a basic snackbar; needs orchestrated overlay.

## [1.4.0] - 2025-08-20

### Added - Epic Project Management System 🚀
- **🎯 Complete Epic Project Management**: Full implementation of multi-task project collections for Project Management talent users
  - **Epic Project Provider**: Complete CRUD operations with persistent storage and error handling
  - **Dynamic Navigation**: Epic Projects tab appears automatically for Project Management talent users
  - **Epic Creation Dialog**: Beautiful interface for creating epics with task selection and validation
  - **Progress Tracking**: Visual progress cards with completion tracking and status management
  - **Epic Completion Celebrations**: Automatic reward reveals and celebration dialogs

- **🎨 Exclusive Theme Rewards**: Epic completion unlocks premium app themes
  - **Ocean Depths**: Calming blue theme inspired by ocean depths
  - **Forest Canopy**: Earthy green theme inspired by forest canopies  
  - **Sunset Glow**: Warm orange theme inspired by golden sunsets
  - **Automatic Unlock**: Theme rewards automatically unlocked on epic completion
  - **Theme Integration**: Seamless integration with existing theme provider system

- **📱 Enhanced Profile Display**: Complete talent and perk visualization
  - **Talent Tree Widget**: Visual representation of user's talent path and choices
  - **Perk Summary Cards**: Beautiful display of active perks with effect descriptions
  - **Progress Indicators**: Shows upcoming talent choices and requirements
  - **Achievement Display**: Showcases completed epics and unlocked rewards

### Enhanced - Task Completion & Integration
- **⚡ Seamless Epic Integration**: Epic progress updates automatically on task completion
  - **Real-time Progress**: Epic progress bars update immediately when linked tasks are completed
  - **Completion Detection**: Automatic epic completion when all required tasks are finished
  - **Celebration Flow**: Epic completion celebrations trigger after task completion celebrations
  - **Theme Unlocking**: Epic theme rewards are automatically unlocked and made available

- **🎮 Dynamic User Experience**: Interface adapts based on user progression
  - **Talent-Based Navigation**: App tabs change based on unlocked talents
  - **Feature Gating**: Epic difficulty and projects only available to eligible users
  - **Progressive Disclosure**: Features unlock naturally as users advance

### Technical Implementation
- **New Core Systems**:
  - `EpicProvider` - Complete state management for epic projects with error handling
  - `EpicProjectScreen` - Tabbed interface with Active, Planning, and Completed views
  - `EpicCreationDialog` - Task selection and epic creation with validation
  - `EpicProgressCard` - Reusable progress display component
  - `TalentTreeWidget` - Visual talent progression display
  - `PerkSummaryCard` - Active perks display with effect descriptions

- **Enhanced Theme System**:
  - Added 3 new epic reward themes to `ThemeModel`
  - Enhanced theme provider with epic reward unlocking
  - Automatic theme availability updates on epic completion

- **Integration Improvements**:
  - Enhanced task completion flow with epic progress updates
  - Dynamic navigation system based on user talents
  - Improved error handling with proper exception types
  - Fixed compilation issues and missing method implementations

### User Experience
- **Seamless Workflow**: Epic projects integrate naturally into existing task management flow
- **Visual Feedback**: Progress indicators, status badges, and completion celebrations
- **Reward System**: Exclusive themes provide meaningful incentives for epic completion
- **Progressive Enhancement**: Features unlock naturally as users advance their talents

## [1.3.0] - 2025-08-20

### Added - Comprehensive Perk & Talent System 🌟
- **🎯 Talent Tree System**: Complete talent specialization with forced choices at levels 5, 10, 15, 20, 25
  - **Project Management Path**: Unlocks Epic difficulty tasks, multi-task projects, and unique theme rewards
  - **Smart Categorization Path**: Enables AI-powered task categorization and intelligent keyword analysis
  - **Forced Choice UI**: Beautiful modal dialog system that prevents dismissal until talent is selected
  - **Persistent Talent Data**: All choices saved to Firebase with offline support

- **⭐ Enhanced Perk System**: 8 comprehensive perks with real gameplay impact
  - **Level 3**: Smart Task Suggestions (existing feature enhanced)
  - **Level 5**: Health Expert (+15% XP for Health category tasks)
  - **Level 8**: Lucky Charm (+25% loot box bonus chance)
  - **Level 12**: Streak Guardian (automatic streak freeze on overdue tasks)
  - **Level 15**: Learning Master (+20% XP for Learning category tasks)
  - **Level 18**: XP Veteran (+10% XP bonus for all tasks)
  - **Level 22**: Work Efficiency (+25% XP for Work category tasks)
  - **Level 25**: Grand Master (+15% all XP + 50% loot box chance)

- **🧠 Natural Language Processing**: Intelligent task analysis for NLP talent holders
  - **Smart Categorization**: Auto-assigns categories based on 80+ keyword mappings
  - **Difficulty Suggestions**: Analyzes task titles to suggest appropriate difficulty
  - **Confidence Scoring**: Shows reliability of AI suggestions to users
  - **Real-time Integration**: Works seamlessly in task creation dialog

- **🎮 Epic Difficulty System**: Talent-gated maximum difficulty level
  - **Project Management Exclusive**: Only available to users with Project Management talent
  - **Enhanced Multiplier**: 2.0x XP multiplier for epic-level tasks
  - **Future Integration**: Foundation for Epic Project system

### Enhanced - State Management & Integration
- **🔧 Enhanced UserProvider**: Complete talent and perk management system
  - **Talent Selection Methods**: Full CRUD operations for talent choices
  - **Callback System**: Automatic talent choice dialogs and perk unlock notifications
  - **Utility Methods**: Easy checking of user talents and abilities
  - **Perk Summary Generation**: Comprehensive overview of active perk effects

- **💪 Enhanced XP Calculation**: Perk effects integrated into core XP system
  - **Passive Perk Bonuses**: Automatically applied based on user's active perks
  - **Enhanced Notifications**: Shows perk bonus amounts in completion messages
  - **Real-time Previews**: Task creation shows expected XP including perk effects
  - **Detailed Breakdowns**: XP explanations include perk contribution analysis

- **🎨 Enhanced Task Creation Dialog**: Live perk effects display
  - **Active Perk Section**: Beautiful card showing current perk effects for the selected category
  - **Smart Categorization Indicator**: Shows when NLP has auto-assigned a category
  - **Perk Bonus Preview**: Real-time XP calculation including all perk bonuses
  - **Dynamic Difficulty Options**: Epic difficulty appears only for eligible users

### Technical Implementation
- **New Data Models**:
  - `UserTalent` - Comprehensive talent definition and tracking
  - `EnhancedUserPerk` - Multi-effect perk system with configurable bonuses
  - `EpicProject` - Foundation for future project management (model only)
  - `TalentChoice` - Forced choice system with validation
  - `PerkEffectData` - Flexible perk effect configuration

- **New Services**:
  - `PerkEffectEngine` - Applies passive perk bonuses to gameplay
  - `EnhancedXPCalculationService` - Integrates perks with existing XP engine
  - `TalentManagementService` - Handles talent selection and validation
  - `TaskAnalyzerService` - NLP keyword analysis for smart categorization
  - `AppTalentManager` - App-level coordination of talent system
  - `TalentDialogService` - Manages forced talent selection UI

- **Enhanced UI Components**:
  - `TalentSelectionDialog` - Beautiful forced choice modal with animations
  - Enhanced task creation dialog with live perk effects display
  - Automatic talent choice detection and triggering system

### Integration & Architecture
- **Firebase Integration**: Automatic persistence of talent and perk data through enhanced User model
- **Offline Support**: All talent/perk data works offline via existing SecureStorageService
- **Provider Pattern**: Seamless integration with existing state management
- **Callback System**: Event-driven talent unlocks and perk notifications
- **Backwards Compatibility**: All existing features continue to work unchanged

## [1.2.0] - 2025-08-19

### Added
- **🎁 Loot Box System**: Revolutionary random XP bonus system with difficulty-based probabilities
  - **Smart Probability Design**: Easy (15%), Medium (10%), Hard (6%), Epic (3%) chances
  - **Variable Multipliers**: 1.5x (60%), 2x (25%), 2.5x (11%), 3x (4%) bonus rates
  - **Celebratory UI**: Beautiful golden cards with shimmer animations and tier-specific messages
  - **Psychological Balance**: Easy tasks get higher chances to build momentum, harder tasks already rewarding
- **🧮 Enhanced XP Calculation Engine**: Complete overhaul of intelligent XP system
  - **Mathematical Time Formula**: Replaced bucketed system with smooth curve (10 × √minutes + 5)
  - **Comprehensive Breakdown Dialog**: Professional UI showing every XP calculation factor
  - **Educational Transparency**: Users can see and understand all multipliers and bonuses
  - **Interactive Elements**: Expandable tips with optimization strategies and probability details
- **✨ Advanced XP Breakdown Interface**: Complete redesign of XP explanation system
  - **Card-Based Layout**: Modern, organized sections for time, multipliers, and bonuses
  - **Smooth Animations**: Fade-in effects and elastic loot box reveal animations
  - **Mathematical Formulas**: Shows actual calculations used (Base XP = 10 × √minutes + 5)
  - **Optimization Guide**: Tips for maximizing XP with specific strategies

### Enhanced
- **Intelligent XP Engine**: Added `calculateDetailedXP()` method with comprehensive breakdown data
- **Task Completion Flow**: Now shows both snackbar and detailed breakdown dialog
- **Category Explanations**: Each category multiplier now includes reasoning (Health compounds over time, etc.)
- **Difficulty Explanations**: Clear descriptions of why different difficulties have different multipliers

### Technical Details
- New `LootBoxResult` class to encapsulate random bonus data
- Enhanced `XPCalculationBreakdown` class with loot box integration
- `TaskCompletionResult` now includes full breakdown data for UI display
- Probability system uses secure Random with balanced game design principles

## [1.1.1] - 2025-08-19

### Fixed
- **Swipe Gesture Stability**: Fixed critical dismissible widget error that occurred when completing tasks via swipe
  - Replaced `onDismissed` with `confirmDismiss` to properly handle dismissal state
  - Prevents "dismissed Dismissible widget still in tree" Flutter framework errors
- **Delete Confirmation Flow**: Fixed delete swipe bypassing confirmation dialog
  - Delete swipe now properly shows confirmation dialog before deletion
  - Prevents accidental task deletion from swipe gestures
  - Added proper async handling for deletion confirmation workflow

### Changed
- Enhanced swipe-to-complete responsiveness and error handling
- Improved user experience for task deletion with proper confirmation flow
- TaskTile widget now uses `confirmDismiss` callback instead of `onDismissed` for better control

### Technical Details
- Modified `TaskDashboardScreen._handleSwipeDismiss()` to return `Future<bool>` for proper dismissal control
- Updated `TaskTile` widget to accept `confirmDismiss` parameter instead of `onDismissed`
- Enhanced `_showDeleteConfirmation()` to return confirmation result and handle actual deletion

## [1.1.0] - 2025-08-18

### Added
- **Advanced Recurrence System**: Complete task recurrence capability with detailed pattern options
  - Multi-step wizard dialog (`RecurrencePatternDialog`) with mobile-optimized UI
  - Weekly pattern selection with visual day picker (Mon-Sun) and quick shortcuts (Weekdays, Weekends, All Days)
  - Custom interval support (Every N days/weeks/months/years)
  - Monthly patterns: day of month (15th) vs day of week (2nd Tuesday)
  - End conditions: Never, specific date, or after X occurrences
  - Smart pattern descriptions and real-time preview
- **Recurring Task Edit Logic**: Intelligent editing system for recurring tasks
  - "Edit this task only" - breaks individual task from series
  - "Edit all future tasks" - modifies entire recurring series going forward
  - Automatic recurring task detection with appropriate edit dialog
- **Enhanced Task Provider**: New `updateRecurringTask()` method with scope-based editing
- **Mobile-Responsive UI**: Dialog automatically adapts to screen size and prevents overflow
- **Screenshots folder** for UI debugging and documentation

### Fixed
- UI overflow issues on iPhone 16 Pro (67px bottom, 25px right overflows resolved)
- Dialog sizing now responsive (85% screen height, 90% screen width)
- Day picker buttons dynamically size to prevent horizontal overflow
- Syntax errors in recurrence dialog indentation
- Task editing flow now properly handles recurring vs non-recurring tasks
- Recurring task edit dialog not appearing for legacy "workdays" tasks
- Task dashboard screen bypassing recurring task detection logic
- Enhanced recurring task detection to include weeklyDays-based patterns

### Changed
- Task creation and editing now use enhanced recurrence pattern selection
- Reduced dialog padding throughout for better mobile experience
- Improved button layouts with wrapping and compact sizing
- Task model integration with existing recurrence fields maintained for backward compatibility

### Technical Details
- Files added: `recurrence_pattern_dialog.dart`, `recurring_task_edit_dialog.dart`
- Files modified: `task_creation_dialog.dart`, `task_editing_dialog.dart`, `task_provider.dart`, `task_tile.dart`
- Backward compatible with existing task data structure
- Ready for system-level timezone configuration

## [1.0.1] - 2025-08-14

### Added
- Functional local notifications for task reminders using `flutter_local_notifications`.
- Permission handling for notifications on iOS via `permission_handler`.
- Centralized notification scheduling and cancellation within `TaskProvider`.
- `ROADMAP.md` to track high-level development goals.

### Fixed
- A series of iOS build errors related to native configuration and Dart syntax.
- Ensured task creation, completion, and deletion flows correctly update or cancel pending notifications.

### Changed
- Refactored `changelog.md` into a feature backlog within `ROADMAP.md` and created a new formal changelog.
