# CKA 2026 Next subPath Wave

These drafts cover the next recommended workload-configuration pack from the `cka-046+` roadmap:

1. ConfigMap subPath mount diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2701` (`ConfigMap subPath mount diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2701` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `2701` should stay in the `planning + evidence export` lane. It should validate exact ConfigMap-backed volume inventory, item-path and `subPath` evidence, mount-path checks, and safe manifest guidance without mutating the live Deployment or ConfigMap.
- Question `2701` should export exact evidence files instead of restarting the Deployment, deleting pods, or patching the live ConfigMap or Deployment as a shortcut.
- Question `2701` should avoid `kubectl rollout restart deployment/subpath-api`, `kubectl delete pod -n subpath-lab -l app=subpath-api`, `kubectl patch configmap app-config`, and ad hoc `kubectl patch deployment subpath-api ...` commands in the expected answer.

## Recommended Promotion Order

1. Promote `q2701` into `facilitator/assets/exams/cka/046`

## Planned Facilitator Mapping

- `q2701` -> `facilitator/assets/exams/cka/046`
