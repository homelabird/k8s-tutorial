# CKA 2026 Next Storage Wave

These drafts cover the next recommended storage-oriented pack from the `cka-026+` roadmap:

1. StorageClass and dynamic provisioning diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `701` (`StorageClass and dynamic provisioning diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `701` has now been promoted into facilitator pack `cka-026`.

## Important Constraints

- Question `701` now stays in the `ops-diagnostics` lane rather than the next hands-on wave. It should validate exact StorageClass inventory commands, default-class inspection, PVC analysis, and safe manifest guidance without deleting live PVCs or mutating cluster-scoped provisioners.
- Question `701` should export exact evidence files instead of deleting StorageClass objects or patching live cluster-scoped storage configuration inside the drill.
- Question `701` should avoid `kubectl delete storageclass`, `kubectl patch storageclass`, and `kubectl delete pvc reports-pvc -n storageclass-lab` as corrective actions in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q701` -> `facilitator/assets/exams/cka/026`
