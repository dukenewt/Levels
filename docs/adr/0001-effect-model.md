# ADR 0001 — Effect Model and State Separation

Status: Accepted
Date: 2025-08-28

Context
- Perk/talent effects were scattered and implicit, making behavior hard to test and reason about.

Decision
- Introduce a normalized `Effect` model supporting scope (global/category/task), modifier (additive/multiplicative), duration, and stacking.
- Separate computation outputs into `StateDelta` (persisted changes) and `UiEvent` (view actions and animations).
- Keep the evaluation engine pure: `input(User, Task, Context) -> (Breakdown, Deltas, Events)`.

Consequences
- Testable, deterministic effect evaluation; easier to reason about stacking and overrides.
- Clear contract between domain logic and UI orchestration.

Alternatives
- Continue ad-hoc effect handling (rejected: brittle, untestable).

