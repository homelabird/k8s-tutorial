# CKA 2026 Next SecurityContext Wave

These drafts cover the workload-security pack that was promoted from the `cka-036+` roadmap:

1. Pod securityContext and fsGroup diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1701` (`Pod securityContext and fsGroup diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1701` has now been promoted into facilitator pack `cka-036`.

## Important Constraints

- Question `1701` should stay in the `planning + evidence export` lane. It should validate exact pod-level securityContext inventory, container-level privilege checks, fsGroup evidence, and safe manifest review without patching the live Deployment.
- Question `1701` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching live securityContext fields as a workaround.
- Question `1701` should avoid `kubectl rollout restart`, `kubectl delete pod`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. Validate facilitator discovery and single-domain runtime coverage for `cka-036`

## Planned Facilitator Mapping

- `q1701` -> `facilitator/assets/exams/cka/036`
