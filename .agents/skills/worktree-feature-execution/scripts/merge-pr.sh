#!/usr/bin/env bash
set -euo pipefail

pr=""
method="squash"
queue=0
json=0

usage() {
  cat <<'EOF'
Usage: merge-pr.sh [options]

Options:
  --pr <number|url>    PR number or URL (defaults to current branch PR)
  --method <method>    squash|merge|rebase (default: squash)
  --queue              Enable auto-merge / merge queue mode
  --json               Emit a JSON result payload
  -h, --help           Show this help message
EOF
}

emit_result() {
  local pr="$1"
  local method="$2"
  local queue="$3"

  if [[ ${json} -eq 1 ]]; then
    printf '{"pr":"%s","method":"%s","queued":"%s","status":"ok"}\n' "${pr}" "${method}" "${queue}"
    return
  fi

  echo "pr=${pr}"
  echo "method=${method}"
  echo "queued=${queue}"
  echo "status=ok"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      pr="$2"
      shift 2
      ;;
    --method)
      method="$2"
      shift 2
      ;;
    --queue)
      queue=1
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

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI is not installed" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh CLI is not authenticated" >&2
  exit 1
fi

if [[ -z "${pr}" ]]; then
  pr="$(gh pr view --json number --jq '.number' 2>/dev/null || true)"
fi

if [[ -z "${pr}" ]]; then
  echo "ERROR: --pr is required when current context has no PR" >&2
  exit 1
fi

case "${method}" in
  squash)
    merge_flag="--squash"
    ;;
  merge)
    merge_flag="--merge"
    ;;
  rebase)
    merge_flag="--rebase"
    ;;
  *)
    echo "ERROR: invalid merge method '${method}'" >&2
    exit 1
    ;;
esac

checks_state="$(gh pr checks "${pr}" --required --json state --jq '.[].state' 2>/dev/null || true)"
if [[ -z "${checks_state}" ]]; then
  echo "WARN: no required check states found; continuing" >&2
fi

mergeable_state="$(gh pr view "${pr}" --json mergeable,isDraft,state --jq '.mergeable + "," + (.isDraft|tostring) + "," + .state' 2>/dev/null || true)"
if [[ -n "${mergeable_state}" ]]; then
  IFS=',' read -r mergeable is_draft pr_state <<<"${mergeable_state}"
  if [[ "${pr_state}" != "OPEN" ]]; then
    echo "ERROR: pull request state is ${pr_state}, expected OPEN" >&2
    exit 1
  fi
  if [[ "${is_draft}" == "true" ]]; then
    echo "ERROR: pull request is draft; mark as ready before merge" >&2
    exit 1
  fi
  if [[ "${mergeable}" == "CONFLICTING" ]]; then
    echo "ERROR: pull request has merge conflicts" >&2
    exit 1
  fi
fi

if echo "${checks_state}" | grep -E 'FAILURE|ERROR|CANCELLED|TIMED_OUT' >/dev/null 2>&1; then
  echo "ERROR: required checks are failing; refusing merge" >&2
  exit 1
fi

if echo "${checks_state}" | grep -E 'PENDING|IN_PROGRESS|QUEUED|WAITING' >/dev/null 2>&1 && [[ ${queue} -eq 0 ]]; then
  echo "ERROR: required checks are still running; rerun with --queue or wait for completion" >&2
  exit 1
fi

if [[ ${queue} -eq 1 ]]; then
  gh pr merge "${pr}" "${merge_flag}" --auto --delete-branch
else
  gh pr merge "${pr}" "${merge_flag}" --delete-branch
fi

emit_result "${pr}" "${method}" "${queue}"
