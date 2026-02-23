# Branch Naming Reference

## Goal

Generate stable branch names that remain readable, searchable, and conflict-resistant across multiple agents.

## Pattern

Use `<prefix>/<slug>` where:

- `prefix`: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`
- `slug`: lowercase words joined by `-`

Examples:

- `feat/add-billing-retries`
- `fix/handle-null-webhook-signature`
- `refactor/split-ledger-service`

## Rules

- Keep names under 60 characters when possible.
- Remove punctuation and repeated separators.
- Keep task-specific and avoid umbrella names like `feat/update`.
- Reuse an existing branch only when continuing the same PR.

## Multi-Agent Suffix Option

Add agent suffix for parallel runs on similar topics:

- `feat/add-billing-retries-a1`
- `feat/add-billing-retries-a2`

Use suffixes only when collision risk is high.
