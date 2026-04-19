# CKA 2026 Next Stateful Wave

These drafts cover the next recommended stateful workload pack from the `cka-028+` roadmap:

1. StatefulSet identity and headless service diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `901` StatefulSet identity and headless service repair

## Status

- Question `901` (StatefulSet identity and headless service repair) now mirrors the promoted hands-on facilitator pack `cka-028`.
- Question `901` has now been promoted into facilitator pack `cka-028`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact headless Service contract, StatefulSet readiness, ordinal DNS lookup, and bound PVC state instead of deleting stateful objects.
- Question `901` should avoid deleting the StatefulSet, deleting PVCs, or converting the headless Service into a normal Service type in the expected answer.

## Suggested Promotion Order

1. Question `901` is already promoted; the next work is keeping runtime smoke and contract coverage green.
