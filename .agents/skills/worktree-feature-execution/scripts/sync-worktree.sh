#!/usr/bin/env bash
set -euo pipefail

base="main"
json=0

usage() {
  cat <<'EOF'
Usage: sync-worktree.sh [options]

Options:
  --base <branch>  Base branch to rebase onto (default: main)
  --json           Emit a JSON result payload
  -h, --help       Show this help message
EOF
}

emit_result() {
  local branch="$1"
  local base="$2"

  if [[ ${json} -eq 1 ]]; then
    printf '{"branch":"%s","base":"%s","status":"ok"}\n' "${branch}" "${base}"
    return
  fi

  echo "branch=${branch}"
  echo "base=${base}"
  echo "status=ok"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base="$2"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
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

emit_result "${branch}" "${base}"
