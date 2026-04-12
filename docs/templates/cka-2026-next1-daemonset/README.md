# CKA 2026 Next DaemonSet Wave

These drafts cover the next recommended DaemonSet-focused operations pack from the `cka-029+` roadmap:

1. DaemonSet rollout and node coverage diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1001` (`DaemonSet rollout and node coverage diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1001` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `1001` should stay in the `planning + evidence export` lane. It should validate exact DaemonSet inventory, rollout status, node coverage, and safe manifest review without deleting the DaemonSet or cordoning nodes.
- Question `1001` should export exact evidence files instead of deleting DaemonSet pods, converting the workload into a Deployment, or scaling nodes to simulate coverage.
- Question `1001` should avoid `kubectl delete daemonset`, `kubectl scale daemonset`, and `kubectl cordon` as corrective actions in the expected answer.

## Recommended Promotion Order

1. Promote question `1001` into facilitator pack `cka-029`.

## Planned Facilitator Mapping

- `q1001` -> `facilitator/assets/exams/cka/029`
