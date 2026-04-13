# CKA 2026 Next PV Resize Wave

These drafts cover the next recommended storage-resize pack from the `cka-041+` roadmap:

1. PersistentVolumeClaim expansion and resize diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2201` (`PersistentVolumeClaim expansion and resize diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2201` has now been promoted into facilitator pack `cka-041`.

## Important Constraints

- Question `2201` should stay in the `planning + evidence export` lane. It should validate exact PVC inventory, requested-size inspection, StorageClass resize capability, PVC condition evidence, workload mount-path checks, and safe manifest review without patching the live PVC, StorageClass, or Deployment.
- Question `2201` should export exact evidence files instead of deleting the PVC, restarting the workload, or force-patching the live PVC request and StorageClass as a workaround.
- Question `2201` should avoid `kubectl edit pvc`, `kubectl delete pvc`, `kubectl patch storageclass`, and ad hoc `kubectl rollout restart` remediation commands in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q2201` -> `facilitator/assets/exams/cka/041`
