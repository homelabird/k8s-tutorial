# CKA 2026 Next PriorityClass Wave

These drafts cover the next recommended scheduling-operations pack from the `cka-037+` roadmap:

1. PriorityClass and preemption diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1801` (`PriorityClass and preemption diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1801` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `1801` should stay in the `planning + evidence export` lane. It should validate exact PriorityClass inventory, workload priority wiring, preemption-policy evidence, scheduler events, and safe manifest review without patching the live Deployment or PriorityClass.
- Question `1801` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching live PriorityClass fields as a workaround.
- Question `1801` should avoid `kubectl rollout restart`, `kubectl delete pod`, `kubectl patch priorityclass`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. Promote question `1801` into facilitator pack `cka-037`

## Planned Facilitator Mapping

- `q1801` -> `facilitator/assets/exams/cka/037`
