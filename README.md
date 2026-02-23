# skills

Reusable skills and automation playbooks for agent-driven development.

## Included skill

- `worktree-feature-execution`: orchestrates isolated worktrees, feature implementation flow, PR creation, and merge/cleanup automation with `git` + `gh`.

## Install globally

```bash
npx skills add iskisraell/skills --skill worktree-feature-execution -g -a opencode
```

## Orchestration example

```bash
bash .agents/skills/worktree-feature-execution/scripts/run-feature-flow.sh \
  --feature "add billing retries" \
  --base "current-branch" \
  --pr-base "main" \
  --summary "Improve retry reliability for transient failures"
```

## Layout

- `.agents/skills/` - skill definitions and bundled resources.
- `AGENTS.md` - project-level harness behavior.
- `PROJECT-OVERVIEW.md` - architecture and process map.
- `project.yaml` - machine-readable metadata and conventions.

## Quick start

1. Clone the repository.
2. Open or copy the target skill directory under `.agents/skills/`.
3. Follow each skill's `SKILL.md` trigger + workflow guidance.
4. Use bundled scripts under each skill's `scripts/` folder.
5. Run `bash scripts/validate-all.sh` after modifications.

## Safety

- All automation is designed to avoid destructive git actions.
- Merge operations require `gh` auth and repository permissions.
- Worktree directories are ignored by default via `.gitignore`.
