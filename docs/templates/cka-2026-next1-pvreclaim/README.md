# CKA 2026 Next PV Reclaim Wave

These drafts cover the next recommended storage-ops pack from the `cka-040+` roadmap:

1. PersistentVolume reclaim policy and claimRef diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `2101` PersistentVolume reclaim policy and claim wiring repair

## Status

- Question `2101` (PersistentVolume reclaim policy and claim wiring repair) now mirrors the promoted hands-on facilitator pack `cka-040`.
- Question `2101` has now been promoted into facilitator pack `cka-040`.

## Promotion Notes

- Keep the runtime deterministic by validating the existing bound PV/PVC contract, Deployment availability, and file creation on mounted storage instead of deleting storage objects.
- Question `2101` should avoid deleting the PVC or PV, or replacing the existing reclaim-policy and claimRef contract in the expected answer.

## Suggested Promotion Order

1. Question `2101` is already promoted; the next work is keeping runtime smoke and contract coverage green.
