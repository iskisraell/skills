#!/usr/bin/env bash
set -euo pipefail

base="main"
title=""
body_file=""
draft=0

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
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

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

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name "${branch}@{upstream}" 2>/dev/null || true)"
if [[ -z "${upstream}" ]]; then
  git push -u origin "${branch}"
else
  git push
fi

existing_url="$(gh pr view "${branch}" --json url --jq '.url' 2>/dev/null || true)"
if [[ -n "${existing_url}" ]]; then
  echo "pr_url=${existing_url}"
  echo "status=ok"
  exit 0
fi

draft_flag=()
if [[ ${draft} -eq 1 ]]; then
  draft_flag+=("--draft")
fi

if [[ -n "${body_file}" ]]; then
  if [[ ! -f "${body_file}" ]]; then
    echo "ERROR: body file does not exist: ${body_file}" >&2
    exit 1
  fi
  create_output="$(gh pr create --base "${base}" --head "${branch}" --title "${title}" --body-file "${body_file}" "${draft_flag[@]}")"
else
  create_output="$(gh pr create --base "${base}" --head "${branch}" --title "${title}" --fill "${draft_flag[@]}")"
fi

pr_url="$(printf '%s\n' "${create_output}" | grep -Eo 'https://[^[:space:]]+/pull/[0-9]+' | head -n1 || true)"

if [[ -z "${pr_url}" ]]; then
  echo "ERROR: failed to parse PR URL from gh output" >&2
  echo "DEBUG: ${create_output}" >&2
  exit 1
fi

echo "pr_url=${pr_url}"
echo "status=ok"
