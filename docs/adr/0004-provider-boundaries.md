# ADR 0004 — Provider Responsibilities (UserProvider vs TalentPerkController)

Status: Accepted
Date: 2025-08-28

Context
- Providers mixed persistence with effect evaluation and UI triggers, leading to tight coupling and race conditions.

Decision
- Limit `UserProvider` to persistence of user data.
- Introduce `TalentPerkController` to own evaluated effects snapshot and publish view state.
- Route effect evaluation via the controller and pipeline, not directly from persistence providers.

Consequences
- Clear separation of concerns; easier testing and safer hot reload.

Alternatives
- Keep logic in `UserProvider` (rejected: coupling and race risks).

