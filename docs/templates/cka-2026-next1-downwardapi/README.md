# CKA 2026 Next Single-Domain Drill: Downward API Env and Metadata

These drafts cover the next recommended workload-configuration pack from the `cka-050+` roadmap:

1. Downward API env wiring repair

## Scope

This template adds one hands-on single-domain drill:

- `5001` Downward API env wiring repair

## Status

- Question `5001` (`Downward API env wiring repair`) now mirrors the promoted hands-on facilitator pack `cka-050`.
- Question `5001` has now been promoted into facilitator pack `cka-050`.

## Promotion Notes

- Keep the runtime deterministic by fixing the Deployment env names and `fieldRef` paths instead of replacing the workload.
- Question `5001` should validate the exact env names, `metadata.name` and `metadata.namespace` references, rollout success, and printed env values from the running container.
- Question `5001` should avoid one-off Pods, rollout restarts, or direct live pod edits in the expected answer.

## Suggested Promotion Order

1. Question `5001` is already promoted; the next work is keeping runtime smoke and contract coverage green.
