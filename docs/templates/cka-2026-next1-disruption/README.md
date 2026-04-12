# CKA 2026 Next Disruption Wave

These drafts cover the next recommended disruption-aware operations pack from the `cka-027+` roadmap:

1. PodDisruptionBudget and drain planning

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `801` (`PodDisruptionBudget and drain planning`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `801` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `801` should stay in the `planning + evidence export` lane. It should validate exact PodDisruptionBudget inventory, node workload audit, cordon/drain preview guidance, and safe uncordon follow-up without performing a live drain.
- Question `801` should export exact evidence files instead of deleting Pods, deleting PodDisruptionBudgets, or draining a node without `--dry-run=client`.
- Question `801` should avoid `kubectl delete pod`, `kubectl delete pdb`, and `kubectl drain kind-cluster-worker --force --ignore-daemonsets --delete-emptydir-data` as corrective actions in the expected answer.

## Recommended Promotion Order

1. Promote question `801` into facilitator pack `cka-027`.

## Planned Facilitator Mapping

- `q801` -> `facilitator/assets/exams/cka/027`
