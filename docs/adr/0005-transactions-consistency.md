# 0005 — Transactions & Data Consistency

Status: Proposed
Date: 2025-09-25

Context
- Duplicate level-ups and lost talent selections can occur under retries, offline replay, or concurrent writes.
- Critical state transitions: XP increments, level-up boundaries, talent choice persistence, and theme unlocks.

Decision
- Use Firestore transactions for XP/level-up and talent choice writes.
- Introduce idempotency tokens for retried operations and offline replay safety.
- Keep non-critical UI state eventually consistent; only critical transitions must be transactional.

Consequences
- Eliminates double level-ups and missing choices in race conditions.
- Adds minor complexity (transaction boundaries, idempotency storage) but reduces user-facing inconsistencies.

Alternatives
- Pure client-side guards (insufficient under multi-device or retry scenarios).
- Serializing all writes (hurts UX; unnecessary for non-critical paths).

Implementation Notes
- Define transaction helpers in a shared persistence layer.
- Store idempotency keys with operation timestamps to dedupe replays.
- Tests: artificial retries + connectivity toggles to validate idempotency.

