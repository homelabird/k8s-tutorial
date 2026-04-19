# CKA 2026 Next SecurityContext Wave

These drafts cover the next recommended workload-security pack from the `cka-036+` roadmap:

1. pod securityContext and fsGroup repair

## Scope

This template adds one hands-on single-domain drill:

- `1701` pod securityContext and fsGroup repair

## Status

- Question `1701` (pod securityContext and fsGroup repair) now mirrors the promoted hands-on facilitator pack `cka-036`.
- Question `1701` has now been promoted into facilitator pack `cka-036`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact pod and container securityContext fields, rollout success, and runtime file ownership evidence.
- Question 1701 should avoid rollout restarts, deleting pods, or replacing the Deployment with a different workload kind in the expected answer.

## Suggested Promotion Order

1. Question `1701` is already promoted; the next work is keeping runtime smoke and contract coverage green.
