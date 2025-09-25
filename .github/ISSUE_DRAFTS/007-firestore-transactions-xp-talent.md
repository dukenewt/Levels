Title: Firestore Transactions for XP/Level-Up and Talent Choice

Summary
- Prevent duplicate level-ups and lost talent choices by using Firestore transactions and idempotency for critical writes.

Scope
- Wrap XP/level-up and talent choice persistence in transactions.
- Add idempotency tokens for retries; safe offline replay behavior.
- Unit tests with artificial retries; chaos test toggling connectivity.

Acceptance Criteria
- Zero duplicate level-ups or missing choices under retry/offline scenarios.
- Transactions documented and linked to ADR.

Links
- Roadmap: Now — Persistence safety.
- ADR: (Add) Transactions & Data Consistency (stub acceptable initially).

Labels
- data, engine, now

