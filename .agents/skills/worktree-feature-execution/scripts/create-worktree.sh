#!/usr/bin/env bash
set -euo pipefail

feature=""
base="current-branch"
prefix="feat"
root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature)
      feature="$2"
      shift 2
      ;;
    --base)
      base="$2"
      shift 2
      ;;
    --prefix)
      prefix="$2"
      shift 2
      ;;
    --root)
      root="$2"
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${feature}" ]]; then
  echo "ERROR: --feature is required" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: current directory is not inside a git repository" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
project_name="$(basename "${repo_root}")"

slug="$(printf '%s' "${feature}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
if [[ -z "${slug}" ]]; then
  echo "ERROR: feature slug resolved to empty value" >&2
  exit 1
fi

if [[ "${base}" == "current-branch" ]]; then
  base="$(git branch --show-current || true)"
  if [[ -z "${base}" ]]; then
    base_remote_head="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [[ -z "${base_remote_head}" ]]; then
      echo "ERROR: cannot resolve base branch from detached HEAD" >&2
      exit 1
    fi
    base="${base_remote_head#origin/}"
  fi
fi

if [[ -z "${root}" ]]; then
  if [[ -d "${repo_root}/.worktrees" ]]; then
    root=".worktrees"
  elif [[ -d "${repo_root}/worktrees" ]]; then
    root="worktrees"
  else
    root=".worktrees"
  fi
fi

if [[ "${root}" == "~/.config/opencode/worktrees/{project}" ]]; then
  root="${HOME}/.config/opencode/worktrees/${project_name}"
fi

if [[ "${root}" == .* || "${root}" == worktrees* ]]; then
  mkdir -p "${repo_root}/${root}"
  if ! git check-ignore -q "${root}"; then
    if [[ -f "${repo_root}/.gitignore" ]] && grep -E "^${root%/}/?$" "${repo_root}/.gitignore" >/dev/null 2>&1; then
      :
    else
      printf '%s/\n' "${root%/}" >> "${repo_root}/.gitignore"
      echo "INFO: added ${root%/}/ to .gitignore"
    fi
  fi
  root_path="${repo_root}/${root}"
elif [[ "${root}" == /* ]]; then
  root_path="${root}"
  mkdir -p "${root_path}"
else
  root_path="${repo_root}/${root}"
  mkdir -p "${root_path}"
fi

branch="${prefix}/${slug}"
worktree_path="${root_path}/${slug}"

if [[ -e "${worktree_path}" ]] && [[ -n "$(ls -A "${worktree_path}" 2>/dev/null || true)" ]]; then
  echo "ERROR: target worktree path exists and is not empty: ${worktree_path}" >&2
  exit 1
fi

if git worktree list --porcelain | grep -F "branch refs/heads/${branch}" >/dev/null 2>&1; then
  echo "ERROR: branch ${branch} is already attached to another worktree" >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  git worktree add "${worktree_path}" "${branch}"
else
  if ! git show-ref --verify --quiet "refs/heads/${base}" && ! git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    echo "ERROR: base branch does not exist locally or on origin: ${base}" >&2
    exit 1
  fi

  base_ref="${base}"
  if git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    base_ref="origin/${base}"
  fi

  git worktree add -b "${branch}" "${worktree_path}" "${base_ref}"
fi

echo "worktree_path=${worktree_path}"
echo "branch=${branch}"
echo "base=${base}"
echo "status=ok"
