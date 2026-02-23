#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: current directory is not inside a git repository" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
current_branch="$(git branch --show-current || true)"

if [[ -z "${current_branch}" ]]; then
  default_remote_head="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -z "${default_remote_head}" ]]; then
    echo "ERROR: detached HEAD and no origin/HEAD fallback available" >&2
    exit 1
  fi
  current_branch="${default_remote_head#origin/}"
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "ERROR: remote 'origin' is not configured" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI is not installed" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh CLI is not authenticated" >&2
  exit 1
fi

if ! git fetch origin --quiet >/dev/null 2>&1; then
  echo "WARN: could not fetch origin during preflight; proceeding with local refs" >&2
fi

echo "repo_root=${repo_root}"
echo "current_branch=${current_branch}"
echo "origin_remote=$(git remote get-url origin)"
echo "status=ok"
