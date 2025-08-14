# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
