# Architecture Issues and Decisions (AID)

This document tracks current architecture gaps, decisions, and planned remediations.

## Current State (Post-Refactor Snapshot)

- Completion flow centralized via `CompletionPipeline`: sequences streak update → notification → XP snackbar → breakdown → epic update.
- Animation conflicts reduced using `AnimationOrchestrator` with per-entity queues.
- Level progression corrected in `UserProvider.addXp()`; unified loot box logic under `IntelligentXPEngine`.
- Wheel of Time now respects Reduced Motion and uses safe controller helpers.

## Gaps and Risks

- Notifications bypass preferences: `CompletionPipeline` and `TaskNotificationService` must consult `SettingsProvider` toggles before showing notifications.
- Talent dialog orchestration: dialog currently triggered from provider and manager. Move to an event emitted by pipeline or a single app-level coordinator to avoid races.
- Perk surface drift: Perk summaries exist in both `UserProvider` and `PerkEffectEngine`.
- Widget-local logic: Some animation widgets still contain logic and timers; migrate to orchestrator or respect Reduced Motion consistently.

## Decisions

- Defer all post-completion UI to `CompletionPipeline` for deterministic sequencing; remove scattered triggers from providers.
- Make perk/XP engine pure; emit `StateDelta` + `UiEvents` from the pipeline (next step) to cleanly separate compute vs side effects.
- Treat Reduced Motion as a first-class setting and short-circuit animations where feasible.

## Planned Remediations

1) Notifications and Preferences
   - Gate notifications in pipeline with `SettingsProvider` flags
   - Add tests/checklist for toggles

2) Talent Dialog Flow
   - Fire a single dialog request event after level-up commit (post-frame), managed by one coordinator
   - Remove direct dialog calls from `UserProvider`

3) Perk Cleanup
   - Remove "Smart/Bound Suggestions" perk and audit references
   - Consolidate perk summary to `PerkEffectEngine` only

4) Epic Celebration
   - Replace snackbar with orchestrated overlay (Reduced Motion aware)
   - Optionally unlock theme rewards via `ThemeProvider`

5) Expand Orchestrator Adoption
   - Update `ring_unraveling_celebration.dart`, `xp_orb_overlay.dart`, and other animation-heavy widgets
   - Centralize timing using `AppDesignTokens`

