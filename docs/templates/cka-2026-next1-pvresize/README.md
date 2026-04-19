# CKA 2026 Next PV Resize Wave

These drafts cover the next recommended storage-resize pack from the `cka-041+` roadmap:

1. PersistentVolumeClaim expansion and resize diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `2201` PersistentVolumeClaim expansion and resize repair

## Status

- Question `2201` (PersistentVolumeClaim expansion and resize repair) now mirrors the promoted hands-on facilitator pack `cka-041`.
- Question `2201` has now been promoted into facilitator pack `cka-041`.

## Promotion Notes

- Keep the runtime deterministic by validating the resize-capable storage contract, Deployment availability, and file creation on mounted storage instead of replacing the PVC or StorageClass.
- Question `2201` should avoid deleting the PVC or PV, or replacing the existing resize-capable StorageClass in the expected answer.

## Suggested Promotion Order

1. Question `2201` is already promoted; the next work is keeping runtime smoke and contract coverage green.
