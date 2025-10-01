# Agent Guide

## Project Overview
TaskBound (DailyXP) is an RPG-style gamified task management Flutter app. Core loop: complete tasks → earn XP → level up → unlock perks/talents → feel progression.

## Design Guidelines

### Material 3 Compliance
- Use Material 3 color tokens: `colorScheme.primary`, `secondaryContainer`, `onSurfaceVariant`, etc.
- Follow Material 3 component specs (heights, padding, spacing)
- NavigationBar standard: 64dp height
- Elevation and shadows: minimal, follow M3 guidelines
- Border radius: 12-16px for consistency
- Typography: use theme text styles with proper weights

### Apple HIG Compliance
- Respect iOS safe areas (notch, home indicator)
- Icon sizes: 22-24dp for tab bars
- Font sizes: 11-12sp for labels in compact spaces
- Touch targets: minimum 44x44pt
- Bottom sheets: use drag handles, respect safe areas
- Animations: smooth, 200-300ms durations

### Cross-Platform Considerations
- Always wrap bottom UI in SafeArea
- Use `MediaQuery.viewInsets.bottom` for keyboard handling
- Test with iPhone notch designs
- Adaptive widgets: `Switch.adaptive`, etc.

## Code Style & Practices

### General Guidelines
- **No emojis** in code, comments, commits, or documentation
- Concise, direct communication - avoid preamble/postamble
- Use existing patterns and architecture
- Prefer editing existing files over creating new ones
- Read files before editing them
- Ask questions to gain context 

### Architecture Patterns
- **State Management**: Provider pattern
- **Effects System**: `PureEffectEngine` for perk/talent calculations
- **Animation**: `AnimationOrchestrator` for coordinated sequences
- **Completion Flow**: `CompletionPipeline` orchestrates post-completion logic
- **Motion Modes**: Basic Motion (default), Advanced Motion (feature-flagged)

### Key Services & Controllers
- `UserProvider`: User data and XP management
- `TaskProvider`: Task CRUD and filtering
- `TalentPerkController`: Effect evaluation and state
- `SettingsProvider`: User preferences including `reducedMotion`
- `AnimationOrchestrator`: Centralized animation lifecycle

### File Organization
- Widgets: `/lib/widgets/`
- Screens: `/lib/screens/`
- Services: `/lib/services/`
- Providers: `/lib/providers/`
- Models: `/lib/models/`
- Core utilities: `/lib/core/`
- Debug tools: `/lib/debug/`

## Working Process

### Problem-Solving Approach
1. Review screenshots when provided
2. Search for relevant code (Grep, Glob)
3. Read files before editing
4. Propose solutions before implementing
5. Use TodoWrite for multi-step work
6. Test changes (flutter analyze)
7. Update documentation

### Documentation Updates
After completing work, update:
- `changelog.md`: Add to [Unreleased] section with Added/Changed/Fixed/Removed
- `ROADMAP.md`: Update progress, mark completed items with `[x]`
- Use markdown checkboxes, not emojis

### Commit Guidelines
- Only commit when user requests it
- Use conventional commit format: `type(scope): description`
- Include bullet points for multi-part changes
- Add Co-Authored-By: Claude line
- Keep commits cohesive and focused

### Communication Style
- Concise and direct
- Avoid unnecessary explanations unless asked
- Use screenshots for debugging UI issues
- Suggest next steps but don't be overly proactive
- Trust user's judgement on priorities

## Current State & Context

### Recent Work (Session Context)
- Task creation dialog: converted to modal bottom sheet
- Bottom navigation: redesigned for Material 3/HIG compliance
- Keyboard handling: proper viewport insets and SafeArea
- Motion system: Basic Motion default, Advanced Motion feature-flagged

### Active Priorities (ROADMAP.md "Now")
- Motion Baseline + Gating
- Instrumentation & Performance
- Mobile UX Polish (in progress)

### Known Technical Details
- Debug mode: Motion Debug overlay accessible via double-tap
- Feature flags: `FeatureFlags.shouldUseAdvancedMotion()`
- Reduced Motion: respected globally via `SettingsProvider`
- Animation tokens: `AppDesignTokens` for durations/curves
- No raw animation values in widgets

## File-Specific Notes

### Do Not Use
- `smooth_xp_animation_service.dart`: Unused, removed from imports
- Deprecated perk systems: Use `PureEffectEngine` only

### Important Files
- `/lib/main.dart`: App entry, provider setup, navigation
- `/lib/widgets/wheel_of_time_progress.dart`: Main XP ring widget
- `/lib/widgets/custom_bottom_nav_bar.dart`: Custom navigation bar
- `/lib/widgets/task_creation_dialog.dart`: Modal bottom sheet for task creation
- `ROADMAP.md`: Development priorities and progress
- `changelog.md`: All notable changes

## Testing & Quality
- Run `flutter analyze` after changes
- Check for unused imports
- Verify keyboard interactions on mobile
- Test with iOS notch designs
- Ensure Reduced Motion compatibility

## Avoid
- Creating new documentation files unprompted
- Using emojis anywhere
- Over-explaining completed work
- Creating files when editing would suffice
- Making commits without explicit user request
- Adding TODO comments in code (use ROADMAP.md instead)
