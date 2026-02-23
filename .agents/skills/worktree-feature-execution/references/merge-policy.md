# Merge Policy

## Default Policy

- Base branch: `main`
- Merge method: `squash`
- Requirement: green required checks
- Prefer merge queue when enabled

## Merge Gates

Allow merge only when all conditions are true:

1. PR is open and mergeable.
2. Required checks pass.
3. Branch is rebased or up to date with base.
4. No unresolved review blockers.

## Queue Handling

When queue is enabled:

- Use queued auto-merge.
- Avoid manual bypass merges.
- Keep branch alive until queue completion.

## Stacked PRs

- Merge root dependency PR first.
- Rebase child PRs onto updated base.
- Re-validate child PR checks.

## Emergency Exceptions

For critical hotfixes:

- Use `fix/*` prefix.
- Keep PR scope minimal.
- Add post-merge follow-up issue for debt.
