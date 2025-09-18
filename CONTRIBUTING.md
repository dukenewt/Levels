# Contributing Guide

Thanks for contributing to TaskBound. This guide explains how we branch, ship, and keep the codebase safe.

## Branch Strategy
- `main`: release branch. Only merge here when shipping a public build (e.g., 1.0.0).
- `develop`: staging branch. All feature/fix work merges here first.
- Feature branches: branch from `develop` using `feature/<name>` or `fix/<name>`, then open PRs into `develop`.

## PR Requirements
- CI must pass:
  - Build & Tests (Flutter analyze + unit tests)
  - Security Check (forbidden paths + secret scans)
- Keep changes scoped and focused. Reference relevant ADRs when architectural choices are involved.
- No secrets or generated configs in commits. See SECURITY.md for the canonical forbidden list and incident response.

## Versioning & Releases
- SemVer pre-1.0:
  - Work on `develop` as 0.7.x (e.g., tag `v0.7.1` for this consolidation).
- First public release:
  - Merge `develop` → `main`, tag `v1.0.0` and publish.
- Post-release iterations:
  - Use 1.x.y (patch for fixes, minor for non-breaking features, major for breaking changes).

## Release Flow Checklist
1. Ensure `develop` is green (Security Check + Build & Tests).  
2. Update `CHANGELOG.md` and `ROADMAP.md` (mark “Recently Completed”).
3. Bump version as needed (pre-1.0: 0.7.x; release: 1.0.0).
4. Merge `develop` → `main` via PR; require approvals.
5. Tag release on `main` (e.g., `v1.0.0`).
6. Distribute (TestFlight/internal tracks); collect feedback and iterate.

## Security & Secrets
- Canonical forbidden patterns live in `scripts/forbidden-paths.txt` and are enforced by CI.
- Never commit Firebase client configs, env files, signing keys, or generated artifacts.
- If an incident occurs, rotate credentials and follow the history cleanup guides in SECURITY.md.

## Architecture & UI/UX
- Follow ADRs under `docs/adr/` for architecture decisions.
- UI/UX adheres to Material 3 (Android) and Apple HIG (iOS); prioritize clarity, consistency, and accessibility (Reduced Motion supported).

## Contact
Open PRs and Issues against `develop`. For questions about architecture/security, reference ADRs and SECURITY.md first.
