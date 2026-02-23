#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-feature-flow.sh --feature <text> [options]

Core options:
  --feature <text>      Feature statement (required)
  --base <branch>       Branch used for worktree branch creation (default: current-branch)
  --pr-base <branch>    PR target branch and sync base (default: main)
  --prefix <prefix>     Branch prefix, e.g. feat|fix (default: feat)
  --root <path>         Override worktree root
  --title <text>        PR title (default: "<prefix>: <feature>")
  --draft               Create a draft PR
  --no-sync             Skip rebase/sync step
  --no-pr               Stop before PR creation

Merge options:
  --merge               Merge after PR creation
  --queue               Use merge queue/auto-merge mode
  --merge-method <m>    squash|merge|rebase (default: squash)

Template options:
  --body-file <path>    PR body output path (default: <worktree>/.git/PR_BODY.md)
  --risk <level>        low|medium|high (default: medium)
  --issue <number>      Issue number for closing reference
  --summary <text>      Extra summary bullet in PR body

Setup options:
  --setup <mode>        auto|none|"<custom command>" (default: auto)

Other:
  -h, --help            Show this help message
EOF
}

feature=""
feature_base="current-branch"
pr_base="main"
prefix="feat"
root=""
title=""
draft=0
sync=1
open_pr=1
merge=0
queue=0
merge_method="squash"
setup="auto"
body_file=""
risk="medium"
issue=""
summary=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature)
      feature="$2"
      shift 2
      ;;
    --base)
      feature_base="$2"
      shift 2
      ;;
    --pr-base)
      pr_base="$2"
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
    --title)
      title="$2"
      shift 2
      ;;
    --draft)
      draft=1
      shift
      ;;
    --no-sync)
      sync=0
      shift
      ;;
    --no-pr)
      open_pr=0
      shift
      ;;
    --merge)
      merge=1
      shift
      ;;
    --queue)
      queue=1
      shift
      ;;
    --merge-method)
      merge_method="$2"
      shift 2
      ;;
    --setup)
      setup="$2"
      shift 2
      ;;
    --body-file)
      body_file="$2"
      shift 2
      ;;
    --risk)
      risk="$2"
      shift 2
      ;;
    --issue)
      issue="$2"
      shift 2
      ;;
    --summary)
      summary="$2"
      shift 2
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

if [[ ${merge} -eq 1 ]] && [[ ${open_pr} -eq 0 ]]; then
  echo "ERROR: --merge cannot be combined with --no-pr" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: current directory is not inside a git repository" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

extract_value() {
  local payload="$1"
  local key="$2"
  printf '%s\n' "${payload}" | sed -n "s/^${key}=//p" | head -n 1
}

bash "${script_dir}/preflight-check.sh" >/dev/null

create_cmd=(bash "${script_dir}/create-worktree.sh" --feature "${feature}" --base "${feature_base}" --prefix "${prefix}")
if [[ -n "${root}" ]]; then
  create_cmd+=(--root "${root}")
fi

create_output="$(cd "${repo_root}" && "${create_cmd[@]}")"
worktree_path="$(extract_value "${create_output}" "worktree_path")"
branch="$(extract_value "${create_output}" "branch")"

if [[ -z "${worktree_path}" ]] || [[ -z "${branch}" ]]; then
  echo "ERROR: failed to parse worktree creation output" >&2
  echo "DEBUG: ${create_output}" >&2
  exit 1
fi

if [[ "${setup}" == "auto" ]]; then
  if [[ -f "${worktree_path}/package.json" ]]; then
    (cd "${worktree_path}" && bun install)
  fi
elif [[ "${setup}" != "none" ]]; then
  (cd "${worktree_path}" && bash -lc "${setup}")
fi

if [[ ${sync} -eq 1 ]]; then
  (cd "${worktree_path}" && bash "${script_dir}/sync-worktree.sh" --base "${pr_base}")
fi

if [[ ${open_pr} -eq 0 ]]; then
  echo "worktree_path=${worktree_path}"
  echo "branch=${branch}"
  echo "status=ok"
  exit 0
fi

if [[ -z "${title}" ]]; then
  title="${prefix}: ${feature}"
fi

if [[ -z "${body_file}" ]]; then
  body_file="${worktree_path}/.git/PR_BODY.md"
fi

body_cmd=(bash "${script_dir}/generate-pr-body.sh" --base "${pr_base}" --feature "${feature}" --output "${body_file}" --risk "${risk}")
if [[ -n "${issue}" ]]; then
  body_cmd+=(--issue "${issue}")
fi
if [[ -n "${summary}" ]]; then
  body_cmd+=(--summary "${summary}")
fi

(cd "${worktree_path}" && "${body_cmd[@]}") >/dev/null

open_cmd=(bash "${script_dir}/open-pr.sh" --base "${pr_base}" --title "${title}" --body-file "${body_file}")
if [[ ${draft} -eq 1 ]]; then
  open_cmd+=(--draft)
fi

open_output="$(cd "${worktree_path}" && "${open_cmd[@]}")"
pr_url="$(extract_value "${open_output}" "pr_url")"

if [[ -z "${pr_url}" ]]; then
  echo "ERROR: failed to parse PR URL" >&2
  echo "DEBUG: ${open_output}" >&2
  exit 1
fi

if [[ ${merge} -eq 1 ]]; then
  merge_cmd=(bash "${script_dir}/merge-pr.sh" --pr "${pr_url}" --method "${merge_method}")
  if [[ ${queue} -eq 1 ]]; then
    merge_cmd+=(--queue)
  fi
  (cd "${worktree_path}" && "${merge_cmd[@]}") >/dev/null
fi

echo "worktree_path=${worktree_path}"
echo "branch=${branch}"
echo "pr_url=${pr_url}"
echo "merged=${merge}"
echo "status=ok"
