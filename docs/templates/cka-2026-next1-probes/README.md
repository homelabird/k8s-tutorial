# CKA 2026 Next Probe Wave

These drafts cover the next recommended application-health pack from the `cka-032+` roadmap:

1. Readiness, liveness, and startupProbe diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1301` (`Readiness, liveness, and startupProbe diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1301` has now been promoted into facilitator pack `cka-032`.

## Important Constraints

- Question `1301` should stay in the `planning + evidence export` lane. It should validate exact probe inventory, startup/liveness/readiness inspection commands, events, and safe manifest review without patching the live Deployment.
- Question `1301` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching probe fields as a workaround.
- Question `1301` should avoid `kubectl rollout restart`, `kubectl delete pod`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q1301` -> `facilitator/assets/exams/cka/032`
