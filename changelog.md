# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
