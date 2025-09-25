Title: PureEffectEngine Stacking/Override Test Matrix

Summary
- Ensure perk effects combine and override correctly across categories and global bonuses.

Scope
- Table-driven tests covering: single perk, multi-perk stacking, category bonuses vs global bonuses, override precedence.
- Boundary cases: zero/negative inputs guarded; deterministic outputs.

Acceptance Criteria
- Matrix passes; any regression flags exact failing combo.

Links
- Roadmap: Now: Tests — PureEffectEngine stacking/overrides.
- ADR: 0001 Effect Model.

Labels
- tests, engine, now

