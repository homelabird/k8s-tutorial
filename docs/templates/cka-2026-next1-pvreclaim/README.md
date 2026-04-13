# CKA 2026 Next PV Reclaim Wave

These drafts cover the next recommended storage-ops pack from the `cka-040+` roadmap:

1. PersistentVolume reclaim policy and claimRef diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2101` (`PersistentVolume reclaim policy and claimRef diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2101` has not been promoted yet and should be the next candidate for facilitator pack `cka-040`.

## Important Constraints

- Question `2101` should stay in the `planning + evidence export` lane. It should validate exact PVC inventory, PV reclaim-policy inspection, claimRef evidence, workload mount-path checks, and safe manifest review without patching the live PV, PVC, or Deployment.
- Question `2101` should export exact evidence files instead of deleting storage objects, scaling the Deployment, or force-patching the live claimRef and reclaim policy as a workaround.
- Question `2101` should avoid `kubectl delete pvc`, `kubectl delete pv`, `kubectl scale deployment`, and ad hoc `kubectl patch pv ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. Promote `q2101` into facilitator pack `cka-040`.

## Planned Facilitator Mapping

- `q2101` -> `facilitator/assets/exams/cka/040`
