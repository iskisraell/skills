# Project Overview

## Purpose

Provide robust, reusable agent skills that standardize engineering workflows with clear guardrails and low ambiguity.

## Architecture tree

```
skills/
  .agents/
    skills/
      worktree-feature-execution/
        SKILL.md
        references/
          branch-naming.md
          conflict-playbook.md
          merge-policy.md
        scripts/
          cleanup-worktree.sh
          create-worktree.sh
          merge-pr.sh
          open-pr.sh
          preflight-check.sh
          sync-worktree.sh
  AGENTS.md
  AGENT-EDITABLE.md
  PROJECT-OVERVIEW.md
  README.md
  progress.txt
  project.yaml
  scripts/
    validate-all.sh
```

## Module map

- `SKILL.md`: trigger phrases, workflow contract, safety gates, edge cases.
- `references/*.md`: deeper policy and operational playbooks.
- `scripts/*.sh`: deterministic execution helpers for git/gh automation.

## Data flow

1. Receive feature request.
2. Run preflight checks.
3. Create isolated worktree from configured base branch.
4. Implement feature and sync branch with base.
5. Push branch and create PR with `gh`.
6. Merge policy checks.
7. Merge to `main` and cleanup worktree.

## Design decisions

- AGENTS-first configuration over CLAUDE-specific conventions.
- Safe defaults (non-destructive git behavior).
- Explicit edge-case handling for detached HEAD, stale base branch, existing PRs, and merge queue behavior.
