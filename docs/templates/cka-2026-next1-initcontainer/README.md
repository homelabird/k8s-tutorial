# CKA 2026 Next InitContainer Wave

These drafts cover the next recommended workload-startup pack from the `cka-033+` roadmap:

1. InitContainer and shared volume diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1401` (`InitContainer and shared volume diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1401` has now been promoted into facilitator pack `cka-033`.

## Important Constraints

- Question `1401` should stay in the `planning + evidence export` lane. It should validate exact init container inventory, shared volume checks, command inspection, events, and safe manifest review without patching the live Deployment.
- Question `1401` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching init container commands as a workaround.
- Question `1401` should avoid `kubectl rollout restart`, `kubectl delete pod`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q1401` -> `facilitator/assets/exams/cka/033`
