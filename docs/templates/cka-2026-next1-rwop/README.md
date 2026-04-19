# CKA 2026 Next RWOP Wave

These drafts cover the next recommended storage-semantics pack from the `cka-047+` roadmap:

1. ReadWriteOncePod workload repair

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2801` (`ReadWriteOncePod workload repair`) now mirrors the promoted hands-on facilitator pack `cka-047`.
- Question `2801` has now been promoted into facilitator pack `cka-047`.

## Important Constraints

- Question `2801` should keep the existing StorageClass, PersistentVolume, and PVC contract intact while requiring the candidate to fix the consuming Deployment.
- Question `2801` should validate bound PVC state, `ReadWriteOncePod` access mode, corrected claim wiring, corrected mount path, rollout success, and the marker file written by the running workload.
- Question `2801` should avoid PVC deletion, StorageClass replacement, or ad hoc manual pod restarts in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q2801` -> `facilitator/assets/exams/cka/047`
