# CKA 2026 Next Single-Domain Drill: Taints, Tolerations, and NoExecute Eviction

These drafts cover the next recommended scheduling-behavior pack from the `cka-051+` roadmap:

1. Taints, tolerations, and NoExecute eviction diagnostics

## Scope

This template adds one planning-focused single-domain drill:

- `5101` Taints, tolerations, and NoExecute eviction diagnostics

## Status

- Question `5101` (`Taints, tolerations, and NoExecute eviction diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- It is still a template draft and has not yet been promoted into `facilitator/assets/exams/cka/051`.

## Promotion Notes

- Promote this template into facilitator pack `cka-051` once the taint/toleration contract is stable.
- Keep the runtime deterministic by validating exact taint keys, effects, toleration seconds, and workload wiring instead of forcing a live node eviction timer.
- Question `5101` should avoid `kubectl drain`, `kubectl delete pod`, `kubectl rollout restart deployment taint-api`, and ad hoc patching of live node taints in the expected answer.

## Suggested Promotion Order

1. Promote question `5101` into facilitator pack `cka-051`.
