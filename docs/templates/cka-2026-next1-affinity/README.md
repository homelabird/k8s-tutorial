# CKA 2026 Next Affinity Wave

These drafts cover the next recommended workload-placement pack from the `cka-034+` roadmap:

1. Pod anti-affinity and topology spread diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1501` (`Pod anti-affinity and topology spread diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1501` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `1501` should stay in the `planning + evidence export` lane. It should validate exact pod anti-affinity inventory, topology spread checks, event evidence, and safe manifest review without patching the live Deployment.
- Question `1501` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching live placement rules as a workaround.
- Question `1501` should avoid `kubectl rollout restart`, `kubectl delete pod`, `kubectl scale deployment`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. Promote question `1501` into facilitator pack `cka-034`

## Planned Facilitator Mapping

- `q1501` -> `facilitator/assets/exams/cka/034`
