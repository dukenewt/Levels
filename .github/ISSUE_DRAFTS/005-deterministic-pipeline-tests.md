Title: Deterministic CompletionPipeline Tests (StateDelta/UiEvent)

Summary
- Lock down the post-completion flow with deterministic tests to ensure XP math and UI events never “feel wrong”.

Scope
- Unit tests asserting StateDelta and UiEvent sequences for representative scenarios (with/without perks, level-ups, Reduced Motion on/off).
- Golden test for key event payloads.

Acceptance Criteria
- Tests fail on any ordering or payload drift.
- Reduced Motion path emits expected minimal events.

Links
- Roadmap: Fun‑First MVP (Pre‑Beta) and Now: Tests section.
- ADR: 0002 CompletionPipeline.

Labels
- tests, engine, now

