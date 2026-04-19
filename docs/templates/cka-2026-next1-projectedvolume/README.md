# CKA 2026 Next Projected Volume Wave

These drafts cover the next recommended workload-configuration pack from the `cka-044+` roadmap:

1. projected ConfigMap and Secret volume repair

## Scope

This template adds one hands-on single-domain drill:

- `2501` projected ConfigMap and Secret volume repair

## Status

- Question `2501` (projected ConfigMap and Secret volume repair) now mirrors the promoted hands-on facilitator pack `cka-044`.
- Question `2501` has now been promoted into facilitator pack `cka-044`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact projected source names, item paths, read-only mount, rollout success, and mounted files.
- Question 2501 should avoid patching the live ConfigMap or Secret, deleting pods, or replacing the projected volume with inline data in the expected answer.

## Suggested Promotion Order

1. Question `2501` is already promoted; the next work is keeping runtime smoke and contract coverage green.
