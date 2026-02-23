#!/usr/bin/env bash
set -euo pipefail

base="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base="$2"
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: current directory is not inside a git repository" >&2
  exit 1
fi

branch="$(git branch --show-current || true)"
if [[ -z "${branch}" ]]; then
  echo "ERROR: detached HEAD is not supported for sync" >&2
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "ERROR: remote 'origin' is not configured" >&2
  exit 1
fi

git fetch origin --prune

if ! git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
  echo "ERROR: origin/${base} does not exist" >&2
  exit 1
fi

if ! git rebase "origin/${base}"; then
  echo "ERROR: rebase failed; resolve conflicts and run 'git rebase --continue'" >&2
  exit 1
fi

echo "branch=${branch}"
echo "base=${base}"
echo "status=ok"
