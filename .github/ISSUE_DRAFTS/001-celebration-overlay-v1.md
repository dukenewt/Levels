Title: Celebration Overlay v1 (Reduced Motion aware)

Summary
- Replace post-completion snackbar with an orchestrated celebration overlay that clearly communicates XP gained, perk bonuses, and progress to next level. Provide a low-motion variant that respects Reduced Motion.

Scope
- Implement overlay sequenced via AnimationOrchestrator.
- Tokenize durations/curves in AppDesignTokens; no hardcoded timings.
- Show: XP total, perk bonus chips, progress arc/bar, “Next level in X XP”.
- Add Reduced Motion path: fade/scale only, minimal movement.

Acceptance Criteria
- Overlay shows on completion and exits cleanly; no animation conflicts.
- Reduced Motion path activated by SettingsProvider.reducedMotion.
- All timings/curves come from design tokens.
- Widget tests cover standard and Reduced Motion variants.

Links
- Roadmap: Fun‑First MVP (Pre‑Beta).
- ADRs: 0003 AnimationOrchestrator; 0001 Effect Model; 0002 CompletionPipeline.

Labels
- ux, animation, now

