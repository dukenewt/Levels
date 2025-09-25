Title: XP Curve & Tunables + Dev Debug Panel

Summary
- Centralize gameplay balance in a tunables file and add a dev-only debug panel to speed iteration (base XP, difficulty multipliers, perk strengths). Target fast early leveling.

Scope
- Add `lib/gameplay/game_balance.dart` (constants/config provider).
- Wire real-time XP preview in task creation dialog.
- Dev-only debug panel: sliders for base XP and multipliers, predicted time-to-level.
- Gate debug panel behind assert/dev flag.

Acceptance Criteria
- Changing tunables hot-reloads and immediately affects previews and completions.
- Playtesters can reach Level 5 within ~2–3 sessions under default curve.
- Unit tests for curve boundaries and invariants.

Links
- Roadmap: Fun‑First MVP (Pre‑Beta).

Labels
- engine, ux, now

