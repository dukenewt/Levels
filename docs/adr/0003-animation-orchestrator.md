# ADR 0003 — AnimationOrchestrator and Reduced Motion Policy

Status: Accepted
Date: 2025-08-28

Context
- Conflicting, ad-hoc animations caused cancellations and inconsistent UX; accessibility needed Reduced Motion support.

Decision
- Introduce a per-screen `AnimationOrchestrator` to provide controllers by entity, serialize sequences, and centralize tokens (durations/curves).
- Respect a global Reduced Motion setting: shorten/skip animations and avoid disruptive motion.

Consequences
- Consistent motion language, fewer conflicts, accessible defaults.

Alternatives
- Keep local controllers everywhere (rejected: fragile and uncoordinated).

