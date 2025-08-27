Branch Protection Configuration for `main`

Overview
- Enforce security and quality gates on `main` to prevent regressions or sensitive files from entering history.
- Pair with CI workflows: `Security Check` and `Flutter CI`.

Steps (GitHub UI)
- Navigate to: Settings → Branches → Branch protection rules → Add rule
- Branch name pattern: `main`
- Protect matching branches: enable the following
  - Require a pull request before merging (min. 1 approval)
  - Require status checks to pass before merging
    - Select required checks: `Security Check`, `Flutter CI`
    - (Recommended) Require branches to be up to date before merging
  - Require conversation resolution before merging
  - (Optional) Require signed commits
  - Include administrators (recommended)
  - Restrict who can push to matching branches (optional, if using protected admins)
  - Disallow force pushes and prevent branch deletion

gh CLI (alternative)
- Install GitHub CLI and authenticate: `gh auth login`
- Example command to require checks and PRs (replace ORG/REPO as needed):
  - `gh api -X PUT \` 
    `repos/ORG/REPO/branches/main/protection \` 
    `-f required_status_checks.strict=true \` 
    `-f required_status_checks.contexts[]='Security Check' \` 
    `-f required_status_checks.contexts[]='Flutter CI' \` 
    `-f required_pull_request_reviews.required_approving_review_count=1 \` 
    `-f enforce_admins=true \` 
    `-f restrictions=''`

Notes
- Keep the required status checks list in sync if workflow names change.
- Use merge commits for large integration PRs to preserve traceability.
- Tag the post-merge baseline (e.g., `v0.7.0`) for a clean starting point.
