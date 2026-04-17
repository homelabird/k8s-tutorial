# CKA 2026 Next RWOP Wave

These drafts cover the next recommended storage-semantics pack from the `cka-047+` roadmap:

1. ReadWriteOncePod and PVC access mode diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2801` (`ReadWriteOncePod and PVC access mode diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2801` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `2801` should stay in the `planning + evidence export` lane. It should validate exact PVC access-mode inventory, StorageClass expansion flags, consumer pod evidence, and safe manifest guidance without mutating the live PVC or Pods.
- Question `2801` should export exact evidence files instead of deleting pods, recreating claims, or patching the live PVC as a shortcut.
- Question `2801` should avoid `kubectl delete pvc data-claim`, `kubectl delete pod -n rwop-lab -l app=rwop-reader`, `kubectl patch pvc data-claim`, and ad hoc `kubectl edit pod ...` commands in the expected answer.

## Recommended Promotion Order

1. Promote `q2801` into `facilitator/assets/exams/cka/047`

## Planned Facilitator Mapping

- `q2801` -> `facilitator/assets/exams/cka/047`
