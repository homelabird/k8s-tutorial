# CKA 2026 Next QoS Wave

These drafts cover the next recommended workload-resource pack from the `cka-038+` roadmap:

1. Pod resource requests, limits, and QoS diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1901` (`Pod resource requests, limits, and QoS diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1901` has now been promoted into facilitator pack `cka-038`.

## Important Constraints

- Question `1901` should stay in the `planning + evidence export` lane. It should validate exact requests/limits inventory, QoS-class evidence, namespace events, and safe manifest review without patching the live Deployment.
- Question `1901` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching live requests and limits as a workaround.
- Question `1901` should avoid `kubectl rollout restart`, `kubectl delete pod`, `kubectl set resources`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q1901` -> `facilitator/assets/exams/cka/038`
