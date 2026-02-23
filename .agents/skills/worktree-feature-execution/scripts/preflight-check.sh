#!/usr/bin/env bash
set -euo pipefail

json=0

usage() {
  cat <<'EOF'
Usage: preflight-check.sh [options]

Options:
  --json      Emit a JSON result payload
  -h, --help  Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

emit_result() {
  local repo_root="$1"
  local current_branch="$2"
  local origin_remote="$3"
  local git_path="$4"
  local gh_path="$5"
  local shell_type="$6"

  if [[ ${json} -eq 1 ]]; then
    printf '{"repo_root":"%s","current_branch":"%s","origin_remote":"%s","git_path":"%s","gh_path":"%s","shell_type":"%s","status":"ok"}\n' \
      "${repo_root}" "${current_branch}" "${origin_remote}" "${git_path}" "${gh_path}" "${shell_type}"
    return
  fi

  echo "repo_root=${repo_root}"
  echo "current_branch=${current_branch}"
  echo "origin_remote=${origin_remote}"
  echo "git_path=${git_path}"
  echo "gh_path=${gh_path}"
  echo "shell_type=${shell_type}"
  echo "status=ok"
}

shell_type="${SHELL:-${ComSpec:-unknown}}"

git_path="$(command -v git || true)"
if [[ -z "${git_path}" ]]; then
  echo "ERROR: git executable not found in PATH" >&2
  echo "HINT: On Windows, run from Git Bash or add Git cmd/bin to PATH." >&2
  echo "HINT: Common path: C:/Program Files/Git/cmd" >&2
  exit 1
fi

gh_path="$(command -v gh || true)"
if [[ -z "${gh_path}" ]]; then
  echo "ERROR: gh executable not found in PATH" >&2
  echo "HINT: Install GitHub CLI or add it to PATH." >&2
  echo "HINT: Scoop path example: C:/Users/<user>/scoop/shims" >&2
  exit 1
fi

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

emit_result "${repo_root}" "${current_branch}" "$(git remote get-url origin)" "${git_path}" "${gh_path}" "${shell_type}"
