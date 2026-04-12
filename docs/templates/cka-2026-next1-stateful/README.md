# CKA 2026 Next Stateful Wave

These drafts cover the next recommended stateful workload pack from the `cka-028+` roadmap:

1. StatefulSet identity and headless service diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `901` (`StatefulSet identity and headless service diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `901` has now been promoted into facilitator pack `cka-028`.

## Important Constraints

- Question `901` should stay in the `planning + evidence export` lane. It should validate exact StatefulSet inventory, headless Service inspection, ordinal DNS guidance, and safe manifest review without deleting stateful workloads.
- Question `901` should export exact evidence files instead of deleting PVCs, deleting the StatefulSet, or changing the Service type away from `ClusterIP`/headless semantics.
- Question `901` should avoid `kubectl delete statefulset`, `kubectl delete pvc`, and `kubectl patch svc web-svc -p '{"spec":{"type":"NodePort"}}'` as corrective actions in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q901` -> `facilitator/assets/exams/cka/028`
