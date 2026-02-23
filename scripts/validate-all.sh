#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

for script in .agents/skills/worktree-feature-execution/scripts/*.sh; do
  bash -n "${script}"
done

skill_dir=".agents/skills/worktree-feature-execution"
skill_file="${skill_dir}/SKILL.md"
version_file="${skill_dir}/VERSION"
changelog_file="${skill_dir}/CHANGELOG.md"

skill_version="$(sed -n 's/^version:[[:space:]]*//p' "${skill_file}" | head -n 1 | tr -d '[:space:]')"
version_value="$(tr -d '[:space:]' < "${version_file}")"

if [[ -z "${skill_version}" ]]; then
  echo "ERROR: missing version in ${skill_file}" >&2
  exit 1
fi

if [[ "${skill_version}" != "${version_value}" ]]; then
  echo "ERROR: version mismatch between SKILL.md (${skill_version}) and VERSION (${version_value})" >&2
  exit 1
fi

if ! grep -E "^## ${version_value} -" "${changelog_file}" >/dev/null 2>&1; then
  echo "ERROR: changelog is missing heading for version ${version_value}" >&2
  exit 1
fi

echo "Shell syntax validation passed."
echo "Version validation passed (${version_value})."
