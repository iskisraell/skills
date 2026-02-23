# Conflict Playbook

## Goal

Resolve conflicts quickly without losing semantic correctness.

## Procedure

1. Fetch latest remote state.
2. Rebase feature branch onto base branch.
3. Resolve file conflicts with smallest safe edits.
4. Run tests and type checks.
5. Continue rebase and re-run checks.

## Conflict Classes

- **Text conflicts**: same file and line region; resolve directly.
- **Behavior conflicts**: compile succeeds but runtime behavior differs; validate with tests.
- **Contract conflicts**: API/schema mismatches; validate with integration or contract tests.

## Recovery Rules

- Abort rebase only when resolution direction is unclear.
- Preserve both behavioral expectations when possible.
- Document compatibility decisions in PR body.

## Anti-Patterns

- Blindly taking `ours` or `theirs` for large files.
- Skipping test re-runs after conflict resolution.
- Force pushing unresolved or unverified branch states.
