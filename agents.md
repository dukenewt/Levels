# Agent Guide

- Explain high-level decisions in commits/PRs and link the relevant ADR.
- Think through each request step by step
- Ask any questions to provide more clarity. 
- Treat secrets/config as forbidden to commit. The canonical list lives in `SECURITY.md` and is enforced by CI via `scripts/forbidden-paths.txt`.

## UI/UX Guidelines
When making UI changes, follow these principles:

- Platform-Specific Design:
  - Android: Material 3
  - iOS: Apple Human Interface Guidelines
- Clarity and Simplicity: keep interfaces clean and intuitive.
- Consistency: use shared design tokens; consistent motion and components.
- Accessibility: support Reduced Motion, dynamic text, and sufficient contrast.

For security and forbidden paths, see `SECURITY.md`. For architecture decisions, see `docs/adr/0000-index.md`.
**/private_media/
