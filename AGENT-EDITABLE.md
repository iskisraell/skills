## Backlog

- Add cross-platform PowerShell variants for script parity (priority: medium).
- Add CI workflow to validate shell scripts and markdown links (priority: medium).

## Findings

- Existing public worktree skills are typically CLAUDE.md-oriented and need AGENTS.md adaptation.
- Skills.sh leaderboard listing is telemetry-driven and appears after `npx skills add <owner/repo>` installs.

## Session Notes

- Goal: ship an AGENTS-native worktree + PR + merge automation skill with robust edge-case coverage.
- Added `run-feature-flow.sh` and `generate-pr-body.sh` for one-command execution plus structured PR content.
