# CKA 2026 Next Single-Domain Drill: Taints, Tolerations, and NoExecute Scheduling Repair

These drafts cover the next recommended scheduling-behavior pack from the `cka-051+` roadmap:

1. Taints, tolerations, and NoExecute scheduling repair

## Scope

This template adds one hands-on single-domain drill:

- `5101` Taints, tolerations, and NoExecute scheduling repair

## Status

- Question `5101` (`Taints, tolerations, and NoExecute scheduling repair`) has now been promoted into facilitator pack `cka-051`.

## Promotion Notes

- Keep the runtime deterministic by validating exact taint keys, effects, toleration seconds, and workload wiring instead of forcing live eviction timing.
- Question `5101` should avoid `kubectl drain`, deleting nodes, or mutating the taint itself in the expected answer.

## Suggested Promotion Order

1. Question `5101` has now been promoted into facilitator pack `cka-051`.
