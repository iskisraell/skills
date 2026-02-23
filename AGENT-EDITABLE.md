## Backlog

- [high][completed] Enforce non-empty PR body in `open-pr.sh`.
  - Fix plan: auto-generate body file when omitted, create PR with `--body-file`, verify and patch empty bodies.
  - Blast radius: `open-pr.sh`, `run-feature-flow.sh`, PR quality guarantees.
- [high][completed] Improve Windows runner compatibility diagnostics.
  - Fix plan: enrich `preflight-check.sh` with `git`/`gh` path + shell output, add Windows wrappers and doctor helper.
  - Blast radius: `preflight-check.sh`, docs, Windows invocation UX.
- [high][completed] Add explicit mutation serialization rule.
  - Fix plan: document prohibition of parallel mutating git commands in skill workflow.
  - Blast radius: `SKILL.md`, agent execution reliability.
- [medium][completed] Reduce automation parsing fragility.
  - Fix plan: add `--json` output mode to orchestration-critical scripts and keep logs on stderr.
  - Blast radius: scripts consumed by agent runners and CI wrappers.
- [medium][completed] Make `.gitignore` side-effects explicit and controllable.
  - Fix plan: add `--no-gitignore-edit`, `--print-ignore-patch`, and side-effect surfacing in orchestration output.
  - Blast radius: `create-worktree.sh`, `run-feature-flow.sh`, caller expectations.
- [medium][completed] Add manual fallback checklist for constrained environments.
  - Fix plan: add a strict manual sequence in `SKILL.md`.
  - Blast radius: docs and operator behavior under degraded shells.
- [medium][pending] Add CI workflow to validate shell scripts and markdown links.
  - Fix plan: run syntax checks + markdown link checks in GitHub Actions.
  - Blast radius: repository quality gates.
- [medium][pending] Add cross-platform PowerShell parity wrappers.
  - Fix plan: mirror key entrypoints (`preflight`, `run-feature-flow`) with `.ps1` wrappers.
  - Blast radius: Windows-native shells outside Git Bash.

## Findings

- Existing public worktree skills are typically CLAUDE.md-oriented and need AGENTS.md adaptation.
- Skills.sh leaderboard listing is telemetry-driven and appears after `npx skills add <owner/repo>` installs.
- Agent runners can aggressively split quotes on Windows `cmd`, so wrapper scripts and file-based inputs are safer than inline multi-word args.

## Session Notes

- Goal: ship an AGENTS-native worktree + PR + merge automation skill with robust edge-case coverage.
- Added `run-feature-flow.sh` and `generate-pr-body.sh` for one-command execution plus structured PR content.
- Incorporated field feedback from real run (`searchForActivesAPI`) and released hardening update with versioned changelog.
