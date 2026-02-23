# Project Agent Instructions

This repository stores reusable agent skills and automation scripts.

## Scope

- Treat `AGENTS.md` as the primary harness contract.
- Avoid relying on `CLAUDE.md` conventions in this repository.
- Keep skills deterministic, auditable, and tool-oriented.

## Repository conventions

- Default shell: Bash (`bash -lc`) for cross-platform compatibility.
- Prefer `git` and `gh` CLI flows over manual UI steps.
- Keep skill docs imperative and explicit about trigger phrases.
- Keep scripts idempotent and safe by default.
- Never commit secrets, credentials, or `.env` files.

## Validation

- Run `bash scripts/validate-all.sh` when available.
- For new skills, verify frontmatter and referenced files exist.
