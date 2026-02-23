#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: generate-pr-body.sh [options]

Options:
  --base <branch>       Base branch for diff metadata (default: main)
  --feature <text>      Feature label used in summary
  --output <path>       Output markdown file (default: .git/PR_BODY.md)
  --risk <level>        Risk level: low|medium|high (default: medium)
  --issue <number>      Optional issue number for "Closes #<number>"
  --summary <text>      Optional extra summary bullet
  --json                Emit a JSON result payload
  -h, --help            Show this help message
EOF
}

base="main"
feature=""
output=".git/PR_BODY.md"
risk="medium"
issue=""
summary=""
json=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base="$2"
      shift 2
      ;;
    --feature)
      feature="$2"
      shift 2
      ;;
    --output)
      output="$2"
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

case "${risk}" in
  low|medium|high)
    ;;
  *)
    echo "ERROR: invalid --risk value '${risk}' (allowed: low|medium|high)" >&2
    exit 1
    ;;
esac

branch="$(git branch --show-current || true)"
if [[ -z "${branch}" ]]; then
  echo "ERROR: detached HEAD is not supported for PR template generation" >&2
  exit 1
fi

if [[ -z "${feature}" ]]; then
  feature="${branch#*/}"
  feature="${feature//-/ }"
fi

base_ref="origin/${base}"
if ! git show-ref --verify --quiet "refs/remotes/origin/${base}"; then
  if git show-ref --verify --quiet "refs/heads/${base}"; then
    base_ref="${base}"
  else
    echo "ERROR: base branch does not exist locally or on origin: ${base}" >&2
    exit 1
  fi
fi

commit_count="$(git rev-list --count "${base_ref}..HEAD" 2>/dev/null || true)"
if [[ -z "${commit_count}" ]]; then
  commit_count="0"
fi

changed_files="$(git diff --name-only "${base_ref}...HEAD" | wc -l | tr -d ' ')"
if [[ -z "${changed_files}" ]]; then
  changed_files="0"
fi

commit_bullets="$(git log --pretty=format:'- %s' "${base_ref}..HEAD" | head -n 8 || true)"
if [[ -z "${commit_bullets}" ]]; then
  commit_bullets="- Add implementation details for ${feature}"
fi

summary_line=""
if [[ -n "${summary}" ]]; then
  summary_line="- ${summary}"
fi

issue_line=""
if [[ -n "${issue}" ]]; then
  issue_line="Closes #${issue}"
fi

output_dir="$(dirname "${output}")"
mkdir -p "${output_dir}"

{
  printf '## Summary\n'
  printf -- '- Implement %s on branch `%s`.\n' "${feature}" "${branch}"
  printf -- '- Include %s commit(s) across %s changed file(s) against `%s`.\n' "${commit_count}" "${changed_files}" "${base_ref}"
  if [[ -n "${summary_line}" ]]; then
    printf '%s\n' "${summary_line}"
  fi
  printf '\n'
  printf '## Changes\n'
  printf '%s\n' "${commit_bullets}"
  printf '\n'
  printf '## Compatibility Review\n'
  printf -- '- API/interface changes: [ ] none [ ] yes (documented)\n'
  printf -- '- Schema/data changes: [ ] none [ ] yes (migration included)\n'
  printf -- '- Env/config changes: [ ] none [ ] yes (documented)\n'
  printf -- '- Feature flags: [ ] not needed [ ] included\n'
  printf '\n'
  printf '## Validation\n'
  printf -- '- [ ] `bun run typecheck`\n'
  printf -- '- [ ] `bun test`\n'
  printf -- '- [ ] `bun run build` (if applicable)\n'
  printf '\n'
  printf '## Risk and Rollback\n'
  printf -- '- Risk level: `%s`\n' "${risk}"
  printf -- '- Rollback plan: revert merge commit or disable feature flag.\n'
  printf '\n'
  if [[ -n "${issue_line}" ]]; then
    printf '%s\n' "${issue_line}"
  fi
} > "${output}"

if [[ ${json} -eq 1 ]]; then
  printf '{"body_file":"%s","branch":"%s","base_ref":"%s","commit_count":"%s","changed_files":"%s","status":"ok"}\n' \
    "${output}" "${branch}" "${base_ref}" "${commit_count}" "${changed_files}"
else
  echo "body_file=${output}"
  echo "branch=${branch}"
  echo "base_ref=${base_ref}"
  echo "commit_count=${commit_count}"
  echo "changed_files=${changed_files}"
  echo "status=ok"
fi
