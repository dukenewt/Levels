# ADR 0006 — Motion Modes and Gating

Status: Accepted

Date: 2025-09-30

Related: ADR-0003 AnimationOrchestrator and Reduced Motion Policy (`docs/adr/0003-animation-orchestrator.md`)

## Context

Recent work introduced richer animations (XP orbs, ring-unravel celebrations, gem shatter). While the architecture improved (central orchestration, reduced-motion plumbing), the visual layer regressed: animations felt janky on mid‑tier devices and sometimes obscured the core feedback loop (complete task → XP increases → level changes). We need a clear, smooth default experience with strong performance and accessibility, while preserving a path to iterate on advanced motion.

Constraints and goals:
- Clarity first: users must immediately see XP and level changes.
- Performance: 60fps target; p95 frame ≤ 16.6ms; <1% dropped frames on mid‑tier devices (Pixel 5 / iPhone 11) in profile builds.
- Accessibility: Reduced Motion path uses short crossfades and no spatial travel.
- Maintainability: animations use shared tokens and orchestrated lifecycles.

## Decision

Adopt two motion modes with feature gating. Make Basic Motion the default; keep Advanced Motion opt‑in for development and future refinement.

- Basic Motion (default):
  - Progress: 180–220ms ease‑out bar fill; number count‑up (≤300ms).
  - Level‑up: minimal scale+fade LevelUpPanel; immediate carryover XP visualization.
  - No particles or heavy overlays; no center level badge in rings.
  - Reduced Motion: 120ms crossfade; no transforms.

- Advanced Motion (behind flag):
  - XP orbs overlay, ring‑unravel celebration, gem shatter micro‑effect.
  - Iterated only when passing perf and accessibility criteria.

- Implementation policies:
  - All durations/curves pulled from AppDesignTokens; no raw constants.
  - Prefer CustomPainter with `repaint: controller`; avoid per‑frame `setState`.
  - Compute overlay coordinates via anchors (e.g., RingAnchor + showFromAnchors) to avoid drift.
  - Provide a dev override to flip Advanced Motion on/off at runtime via Motion Debug overlay.

## Consequences

Positive:
- Smooth, clear default experience ready to ship.
- Safety: advanced effects cannot regress production without flipping a flag.
- Observability: Motion Debug overlay and frame timings logger make animation perf measurable.

Trade‑offs:
- Additional complexity from feature gating and dual paths.
- Advanced effects require extra iteration to meet the performance bar.

## Technical Notes (Summary of Changes)

- Feature gating
  - `FeatureFlags.enableAdvancedMotion` defaults to false; `shouldUseAdvancedMotion()` respects a dev override.
  - Motion Debug overlay exposes Off / Default / On override in debug builds.

- Defaults and gating
  - Level‑up: default to `LevelUpPanel` (scale+fade). Gate `RingUnravelingCelebration` behind Advanced Motion.
  - XP orbs and gem shatter: gated behind Advanced Motion; no‑op in Basic mode.
  - Removed center level badge inside the rings.

- Performance + accessibility
  - Refactored orb painter to use `repaint: controller`; reduced streams; lighter glow; skip glow under Reduced Motion.
  - Reduced Motion audited to use short crossfades; no path/transform motion.

## Acceptance Criteria

- Performance: p95 frame ≤ 16.6ms and <1% dropped frames on Pixel 5 / iPhone 11 (profile).
- Accessibility: Reduced Motion path avoids spatial motion; uses crossfades; passes manual audit.
- Determinism: No per‑frame widget rebuilds from animation ticks on heavy surfaces.
- Consistency: Timings and curves sourced from AppDesignTokens.

## Alternatives Considered

- Ship advanced animations by default: Rejected due to jank risk and unclear feedback.
- Remove advanced animations entirely: Rejected; we want a path to ASMR‑level polish.
- Keep status quo without gating: Rejected; lacks safety and slows iteration.

## Rollout

- Ship with Basic Motion default; Advanced Motion gated and off by default.
- Use Motion Debug overlay to flip overrides during development and playtests.
- Monitor frame timings and adjust assets/curves; only consider enabling Advanced by default after meeting criteria.

