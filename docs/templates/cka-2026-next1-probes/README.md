# CKA 2026 Next Probe Wave

These drafts cover the next recommended application-health pack from the `cka-032+` roadmap:

1. readiness, liveness, and startupProbe wiring repair

## Scope

This template adds one hands-on single-domain drill:

- `1301` readiness, liveness, and startupProbe wiring repair

## Status

- Question `1301` (readiness, liveness, and startupProbe wiring repair) now mirrors the promoted hands-on facilitator pack `cka-032`.
- Question `1301` has now been promoted into facilitator pack `cka-032`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact HTTP probe paths, rollout success, and served endpoint instead of force-restarting the workload.
- Question 1301 should avoid rollout restarts, deleting pods, or swapping out the container image in the expected answer.

## Suggested Promotion Order

1. Question `1301` is already promoted; the next work is keeping runtime smoke and contract coverage green.
