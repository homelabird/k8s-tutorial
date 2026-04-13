# CKA 2026 Next ServiceAccount Wave

These drafts cover the next recommended workload-identity pack from the `cka-035+` roadmap:

1. ServiceAccount identity and projected token diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1601` (`ServiceAccount identity and projected token diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1601` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `1601` should stay in the `planning + evidence export` lane. It should validate exact ServiceAccount inventory, projected token checks, mount-path evidence, and safe manifest review without patching the live Deployment.
- Question `1601` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching live ServiceAccount fields as a workaround.
- Question `1601` should avoid `kubectl rollout restart`, `kubectl delete pod`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. Promote question `1601` into facilitator pack `cka-035`

## Planned Facilitator Mapping

- `q1601` -> `facilitator/assets/exams/cka/035`
