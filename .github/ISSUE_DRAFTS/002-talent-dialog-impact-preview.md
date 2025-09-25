Title: Talent Choice Dialog with Impact Preview

Summary
- Redesign the level-up talent selection to present 2–3 clear options with numeric effects and a live “Before vs After” XP preview on a representative task.

Scope
- Full-screen modal, non-dismissable until a choice is made.
- Each option: short description, numeric effect (e.g., +20% XP for Health), example preview (50 → 60 XP).
- Integrate with PureEffectEngine for preview math.
- Respect Reduced Motion for dialog transitions.

Acceptance Criteria
- Users can explain chosen perk’s impact unaided in usability test.
- Preview values match final CompletionPipeline results (no drift).
- Unit tests for preview calculations; golden snapshot for dialog states.

Links
- Roadmap: Fun‑First MVP (Pre‑Beta).
- ADRs: 0001 Effect Model; 0002 CompletionPipeline; 0004 Provider Boundaries.

Labels
- ux, engine, now

