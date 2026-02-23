#!/usr/bin/env bash
set -euo pipefail

base="main"
title=""
body_file=""
draft=0
json=0
body_patched=0

usage() {
  cat <<'EOF'
Usage: open-pr.sh --title <text> [options]

Options:
  --base <branch>      Base branch for PR target (default: main)
  --title <text>       Pull request title (required)
  --body-file <path>   PR body file path (auto-generated when omitted)
  --draft              Create as draft
  --json               Emit a JSON result payload
  -h, --help           Show this help message
EOF
}

emit_result() {
  local pr_url="$1"
  local body_file="$2"
  local body_patched="$3"

  if [[ ${json} -eq 1 ]]; then
    printf '{"pr_url":"%s","body_file":"%s","body_patched":"%s","status":"ok"}\n' "${pr_url}" "${body_file}" "${body_patched}"
    return
  fi

  echo "pr_url=${pr_url}"
  echo "body_file=${body_file}"
  echo "body_patched=${body_patched}"
  echo "status=ok"
}

trimmed_content() {
  tr -d '[:space:]'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base="$2"
      shift 2
      ;;
    --title)
      title="$2"
      shift 2
      ;;
    --body-file)
      body_file="$2"
      shift 2
      ;;
    --draft)
      draft=1
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

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git CLI is not installed or not available in PATH" >&2
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

branch="$(git branch --show-current || true)"
if [[ -z "${branch}" ]]; then
  echo "ERROR: detached HEAD is not supported for PR creation" >&2
  exit 1
fi

if [[ -z "${title}" ]]; then
  echo "ERROR: --title is required" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${body_file}" ]]; then
  body_file=".git/PR_BODY.md"
fi

if [[ ! -f "${body_file}" ]] || [[ -z "$(trimmed_content < "${body_file}")" ]]; then
  feature_label="${branch#*/}"
  feature_label="${feature_label//-/ }"
  bash "${script_dir}/generate-pr-body.sh" --base "${base}" --feature "${feature_label}" --output "${body_file}" >/dev/null
fi

if [[ ! -f "${body_file}" ]] || [[ -z "$(trimmed_content < "${body_file}")" ]]; then
  echo "ERROR: PR body file is missing or empty after generation: ${body_file}" >&2
  exit 1
fi

ensure_pr_body() {
  local pr_ref="$1"
  local body
  body="$(gh pr view "${pr_ref}" --json body --jq '.body // ""' 2>/dev/null || true)"
  if [[ -z "$(printf '%s' "${body}" | trimmed_content)" ]]; then
    gh pr edit "${pr_ref}" --body-file "${body_file}" >/dev/null
    body_patched=1
  fi

  body="$(gh pr view "${pr_ref}" --json body --jq '.body // ""' 2>/dev/null || true)"
  if [[ -z "$(printf '%s' "${body}" | trimmed_content)" ]]; then
    echo "ERROR: PR body is still empty after patch attempt" >&2
    exit 1
  fi
}

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name "${branch}@{upstream}" 2>/dev/null || true)"
if [[ -z "${upstream}" ]]; then
  git push -u origin "${branch}"
else
  git push
fi

existing_url="$(gh pr view "${branch}" --json url --jq '.url' 2>/dev/null || true)"
if [[ -n "${existing_url}" ]]; then
  ensure_pr_body "${branch}"
  emit_result "${existing_url}" "${body_file}" "${body_patched}"
  exit 0
fi

draft_flag=()
if [[ ${draft} -eq 1 ]]; then
  draft_flag+=("--draft")
fi

create_output="$(gh pr create --base "${base}" --head "${branch}" --title "${title}" --body-file "${body_file}" "${draft_flag[@]}")"

pr_url="$(printf '%s\n' "${create_output}" | grep -Eo 'https://[^[:space:]]+/pull/[0-9]+' | head -n1 || true)"

if [[ -z "${pr_url}" ]]; then
  echo "ERROR: failed to parse PR URL from gh output" >&2
  echo "DEBUG: ${create_output}" >&2
  exit 1
fi

ensure_pr_body "${pr_url}"
emit_result "${pr_url}" "${body_file}" "${body_patched}"
