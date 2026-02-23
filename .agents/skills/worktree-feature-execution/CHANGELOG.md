# Changelog

## 0.2.1 - 2026-02-23

- Add a Windows `cmd` PATH-degradation fallback that detects command-resolution failure and forces absolute executable usage for `git`, `bash`, `gh`, and `bun`.
- Document required stop condition when required executables cannot be resolved, including reporting checked paths.

## 0.2.0 - 2026-02-23

- Harden PR creation to guarantee non-empty descriptions by auto-generating and validating `--body-file` in `open-pr.sh`.
- Add Windows compatibility diagnostics and wrappers (`scripts/windows/doctor.cmd`, `scripts/windows/run-feature-flow.cmd`).
- Add machine-readable `--json` mode to core scripts used in orchestration.
- Add `.gitignore` side-effect controls in `create-worktree.sh` (`--no-gitignore-edit`, `--print-ignore-patch`).
- Surface gitignore mutation side effects explicitly in orchestration output.
- Improve workflow docs with Windows guidance, serialization warnings, and manual fallback checklist.

## 0.1.0 - 2026-02-23

- Initial AGENTS-native worktree skill release with preflight, worktree creation, sync, PR open, merge, and cleanup scripts.
