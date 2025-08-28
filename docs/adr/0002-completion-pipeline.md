# ADR 0002 — CompletionPipeline Ownership and Boundaries

Status: Accepted
Date: 2025-08-28

Context
- Task completion triggered races between providers and interleaved side effects (notifications, streaks, XP, UI).

Decision
- Introduce a `CompletionPipeline` service that orchestrates analyze → compute → persist → emit events.
- The pipeline calls the pure effect engine, persists `StateDelta`, and emits `UiEvent` for the UI layer.

Consequences
- Eliminates state races, centralizes sequencing, and improves observability.

Alternatives
- Let individual providers handle their own side effects (rejected: race-prone and inconsistent).

