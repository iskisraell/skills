#!/usr/bin/env bash
set -euo pipefail

path=""
force=0
json=0

usage() {
  cat <<'EOF'
Usage: cleanup-worktree.sh --path <path> [options]

Options:
  --path <path>  Worktree path (required)
  --force        Remove even when uncommitted changes exist
  --json         Emit a JSON result payload
  -h, --help     Show this help message
EOF
}

emit_result() {
  local path="$1"
  local force="$2"

  if [[ ${json} -eq 1 ]]; then
    printf '{"path":"%s","forced":"%s","status":"ok"}\n' "${path}" "${force}"
    return
  fi

  echo "path=${path}"
  echo "forced=${force}"
  echo "status=ok"
}

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

if [[ -z "${path}" ]]; then
  echo "ERROR: --path is required" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: current directory is not inside a git repository" >&2
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

emit_result "${path}" "${force}"
