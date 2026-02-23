#!/usr/bin/env bash
set -euo pipefail

feature=""
base="current-branch"
prefix="feat"
root=""
json=0
no_gitignore_edit=0
print_ignore_patch=0
gitignore_modified=0
gitignore_path=""

usage() {
  cat <<'EOF'
Usage: create-worktree.sh --feature <text> [options]

Options:
  --feature <text>        Feature label used to create the branch slug
  --base <branch>         Base branch or "current-branch" (default)
  --prefix <prefix>       Branch prefix, e.g. feat|fix (default: feat)
  --root <path>           Worktree root path override
  --no-gitignore-edit     Fail instead of auto-editing .gitignore
  --print-ignore-patch    Print the ignore line that would be added
  --json                  Emit a JSON result payload
  -h, --help              Show this help message
EOF
}

emit_result() {
  local worktree_path="$1"
  local branch="$2"
  local base="$3"
  local gitignore_modified="$4"
  local gitignore_path="$5"

  if [[ ${json} -eq 1 ]]; then
    printf '{"worktree_path":"%s","branch":"%s","base":"%s","gitignore_modified":"%s","gitignore_path":"%s","status":"ok"}\n' \
      "${worktree_path}" "${branch}" "${base}" "${gitignore_modified}" "${gitignore_path}"
    return
  fi

  echo "worktree_path=${worktree_path}"
  echo "branch=${branch}"
  echo "base=${base}"
  echo "gitignore_modified=${gitignore_modified}"
  echo "gitignore_path=${gitignore_path}"
  echo "status=ok"
}

print_ignore_hint() {
  local entry="$1"
  echo "INFO: missing ignore rule for worktree root. Add this line to .gitignore:" >&2
  echo "+${entry}" >&2
}

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
    --no-gitignore-edit)
      no_gitignore_edit=1
      shift
      ;;
    --print-ignore-patch)
      print_ignore_patch=1
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

if [[ "${root}" != /* ]]; then
  mkdir -p "${repo_root}/${root}"
  ignore_entry="${root%/}/"
  if ! git check-ignore -q "${root}" && ! git check-ignore -q "${ignore_entry}"; then
    if [[ ${print_ignore_patch} -eq 1 ]]; then
      print_ignore_hint "${ignore_entry}"
    fi

    if [[ ${no_gitignore_edit} -eq 1 ]]; then
      echo "ERROR: ignore rule missing for ${root}. Re-run without --no-gitignore-edit or add '${ignore_entry}' manually." >&2
      exit 1
    fi

    if [[ -f "${repo_root}/.gitignore" ]] && grep -E "^${root%/}/?$" "${repo_root}/.gitignore" >/dev/null 2>&1; then
      :
    else
      printf '%s\n' "${ignore_entry}" >> "${repo_root}/.gitignore"
      gitignore_modified=1
      gitignore_path="${repo_root}/.gitignore"
      echo "INFO: modified repo root .gitignore at ${gitignore_path}" >&2
    fi
  fi
  root_path="${repo_root}/${root}"
else
  root_path="${root}"
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
  git worktree add --quiet "${worktree_path}" "${branch}"
else
  if ! git show-ref --verify --quiet "refs/heads/${base}" && ! git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    echo "ERROR: base branch does not exist locally or on origin: ${base}" >&2
    exit 1
  fi

  base_ref="${base}"
  if git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    base_ref="origin/${base}"
  fi

  git worktree add --quiet -b "${branch}" "${worktree_path}" "${base_ref}"
fi

emit_result "${worktree_path}" "${branch}" "${base}" "${gitignore_modified}" "${gitignore_path}"
