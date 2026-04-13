# CKA 2026 Next Projected Volume Wave

These drafts cover the next recommended workload-configuration pack from the `cka-044+` roadmap:

1. Projected ConfigMap and Secret volume diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2501` (`Projected ConfigMap and Secret volume diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2501` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `2501` should stay in the `planning + evidence export` lane. It should validate exact projected-volume source inspection, ConfigMap and Secret item-path checks, mount-path evidence, and safe manifest guidance without mutating the live Deployment or source objects.
- Question `2501` should export exact evidence files instead of restarting the Deployment, deleting pods, or patching the live ConfigMap, Secret, or Deployment as a shortcut.
- Question `2501` should avoid `kubectl rollout restart deployment/bundle-api`, `kubectl delete pod -n projectedvolume-lab -l app=bundle-api`, `kubectl patch configmap app-config`, and ad hoc `kubectl patch deployment bundle-api ...` commands in the expected answer.

## Recommended Promotion Order

1. Promote `q2501` into `facilitator/assets/exams/cka/044`

## Planned Facilitator Mapping

- `q2501` -> `facilitator/assets/exams/cka/044`
