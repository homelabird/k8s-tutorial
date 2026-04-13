# CKA 2026 Next Ephemeral Debug Wave

These drafts cover the next recommended troubleshooting pack from the `cka-042+` roadmap:

1. Ephemeral containers and kubectl debug diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2301` (`Ephemeral containers and kubectl debug diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2301` has now been promoted into facilitator pack `cka-042`.

## Important Constraints

- Question `2301` should stay in the `planning + evidence export` lane. It should validate exact pod inventory, target-container evidence, `kubectl debug` invocation, ephemeral-container visibility, logs and events, and safe manifest review without mutating the live Pod or Deployment.
- Question `2301` should export exact evidence files instead of deleting the Pod, restarting the workload, or force-patching the Pod spec as a workaround.
- Question `2301` should avoid `kubectl delete pod`, `kubectl rollout restart`, `kubectl patch pod`, and ad hoc `kubectl exec` remediation commands in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q2301` -> `facilitator/assets/exams/cka/042`
