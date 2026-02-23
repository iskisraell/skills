#!/usr/bin/env bash
set -euo pipefail

path=""
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      path="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${path}" ]]; then
  echo "ERROR: --path is required" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
if [[ "${path}" != /* ]]; then
  path="${repo_root}/${path}"
fi

if [[ ! -d "${path}" ]]; then
  echo "ERROR: worktree path does not exist: ${path}" >&2
  exit 1
fi

if [[ ${force} -eq 0 ]]; then
  if [[ -n "$(git -C "${path}" status --porcelain 2>/dev/null || true)" ]]; then
    echo "ERROR: uncommitted changes found in worktree; re-run with --force to remove" >&2
    exit 1
  fi
  git worktree remove "${path}"
else
  git worktree remove --force "${path}"
fi

git worktree prune

echo "path=${path}"
echo "forced=${force}"
echo "status=ok"
