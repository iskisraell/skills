# Pull Request Template Reference

Use this structure for feature PRs created from isolated worktrees.

## Summary

- Implement `<feature>` on branch `<branch>`.
- Include `<N>` commits and `<M>` changed files against `<base>`.
- Add one short line describing expected user-facing value.

## Changes

- List the key implementation changes as bullets.
- Keep each bullet outcome-oriented and easy to review.

## Compatibility Review

- API/interface changes: [ ] none [ ] yes (documented)
- Schema/data changes: [ ] none [ ] yes (migration included)
- Env/config changes: [ ] none [ ] yes (documented)
- Feature flags: [ ] not needed [ ] included

## Validation

- [ ] `bun run typecheck`
- [ ] `bun test`
- [ ] `bun run build` (if applicable)

## Risk and Rollback

- Risk level: `low|medium|high`
- Rollback plan: revert merge commit or disable feature flag.

## Linked Issues

Use `Closes #<issue-number>` when applicable.
