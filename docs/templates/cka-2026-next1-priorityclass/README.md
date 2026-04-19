# CKA 2026 Next PriorityClass Wave

These drafts cover the next recommended scheduling-operations pack from the `cka-037+` roadmap:

1. PriorityClass workload wiring repair

## Scope

This template adds one hands-on single-domain drill:

- `1801` PriorityClass workload wiring repair

## Status

- Question `1801` (PriorityClass workload wiring repair) now mirrors the promoted hands-on facilitator pack `cka-037`.
- Question `1801` has now been promoted into facilitator pack `cka-037`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact PriorityClass reference, preserved priority value and preemption policy, rollout success, and running Pod priority.
- Question 1801 should avoid mutating the existing PriorityClass, deleting pods, or creating a replacement PriorityClass in the expected answer.

## Suggested Promotion Order

1. Question `1801` is already promoted; the next work is keeping runtime smoke and contract coverage green.
