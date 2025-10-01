# Talent Ideas (Capability‑Based)

Purpose: Capture talent concepts that unlock new capabilities/flows (not just numerical buffs). Aligned with Reduced Motion, Material 3/HIG, and existing architecture (Epics, Providers, AnimationOrchestrator).

## Principles
- Talents unlock UI surfaces, actions, or automation — not raw multipliers.
- Choices should change playstyle and the core loop meaningfully.
- Deterministic, testable, and respect Reduced Motion with clear affordances.

## Tracks

### Project Mastery (Epics‑centric)
- Milestone Checkpoints (L5)
  - Add checkpoints to epics; mini‑celebrations and a milestone view when reached.
- Dependencies (L10)
  - Mark tasks as “blocked by” others; epic auto‑orders tasks; blocks advance until unblocked.
- Templates (L15)
  - Save any epic as a reusable template; one‑tap create from template.

### Flow & Focus (Execution)
- Focus Mode (L5)
  - Full‑screen minimal view with session timer; Reduced Motion variant uses color/contrast only.
- Quick Queue (L10)
  - Time‑boxed queue (up to 5 tasks); “Next” one‑tap control; compact overlay.
- Batch Actions (L15)
  - Multi‑select in dashboard for move/defer/complete with orchestrated confirmations.

### Planning & Time (Scheduling)
- Smart Timebox (L5)
  - One‑tap convert a task to a calendar block (30/45/60 min); auto‑reschedule within bounds.
- Priority Rules (L10)
  - Lightweight rules (e.g., Morning→Health, Evening→Social). Deterministic, no heavy NLP.
- Day Modes (L15)
  - Select a “mode” (e.g., Learning Day) that surfaces a curated set and hides others temporarily.

### Aesthetic & Mood (Cosmetic Capability)
- Category Theme Paths (L5)
  - Unlock themed palette families per category; category‑reactive accents in UI.
- Ambient Display (L10)
  - Subtle dashboard ambient reflecting streak/level; static accents under Reduced Motion.
- Celebration Studio (L15)
  - Toggle/fine‑tune celebration variants (Basic Motion presets) per event.

## Epic‑Specific Talents
- Synergy Slot (L5)
  - Assign an epic a focus category; that category’s tasks get special treatment + “synergy” meter.
- Milestone Board (L10)
  - Kanban‑like per‑epic board (Planning/Active/Done) with drag‑and‑drop.
- Rally Mode (L15)
  - Short post‑completion window where the next epic task gets a distinctive start transition.

## Theme as Talent (Functional Unlocks)
- Theme Shards (per category)
  - Deterministic shard accrual for completing category tasks; unlock theme variants without RNG.
- Dynamic Accents
  - In Focus Mode, shift to higher‑contrast accent subset automatically (accessibility‑friendly).

## Implementation Notes
- Gate with `TalentManagementService.canX(user)` and small UI affordances (tabs, FABs, kebab actions).
- Tokenize durations/curves via `AppDesignTokens`; use `AnimationOrchestrator` for sequencing and Reduced Motion.
- Keep deterministic tests per talent path (conditions, caps) for balance safety.

## Suggested Next Sprint
- L5: Choice between Project Mastery → Milestone Checkpoints vs Flow & Focus → Focus Mode.
- L10: Synergy Slot (epics) or Quick Queue (execution).
- Theme Path pilot: Health → “Vital Pulse” family with two variants; deterministic shards.

## Open Questions
- Should level‑based choices be mutually exclusive to enforce meaningful tradeoffs?
- Where to surface Focus Mode (FAB on dashboard vs. quick action on TaskTile)?
- How many Day Modes are useful without causing decision fatigue?
