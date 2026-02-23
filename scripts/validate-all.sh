#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

for script in .agents/skills/worktree-feature-execution/scripts/*.sh; do
  bash -n "${script}"
done

echo "Shell syntax validation passed."
