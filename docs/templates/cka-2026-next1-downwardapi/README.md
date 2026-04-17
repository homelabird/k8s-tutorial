# CKA 2026 Next Single-Domain Drill: Downward API Env and Metadata

These drafts cover the next recommended workload-configuration pack from the `cka-050+` roadmap:

1. Downward API env and metadata diagnostics

## Scope

This template adds one planning-focused single-domain drill:

- `5001` Downward API env and metadata diagnostics

## Status

- Question `5001` (`Downward API env and metadata diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- It is still a template draft and has not yet been promoted into `facilitator/assets/exams/cka/050`.

## Promotion Notes

- Promote this template into facilitator pack `cka-050` once the Downward API contract is stable.
- Keep the runtime deterministic by validating exact `fieldRef`, env name, container target, and metadata evidence instead of relying on live pod restarts.
- Question `5001` should avoid `kubectl delete pod meta-api`, `kubectl rollout restart deployment meta-api`, `kubectl patch deployment meta-api`, and ad hoc edits to live pods in the expected answer.

## Suggested Promotion Order

1. Promote question `5001` into facilitator pack `cka-050`.
