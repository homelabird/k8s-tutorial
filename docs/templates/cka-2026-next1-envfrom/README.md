# CKA 2026 Next EnvFrom Wave

These drafts cover the next recommended workload-configuration pack from the `cka-045+` roadmap:

1. ConfigMap and Secret envFrom diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2601` (`ConfigMap and Secret envFrom diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2601` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `2601` should stay in the `planning + evidence export` lane. It should validate exact `envFrom` source wiring, prefix usage, event evidence, and safe manifest guidance without mutating the live Deployment, ConfigMap, or Secret.
- Question `2601` should export exact evidence files instead of restarting the Deployment, deleting pods, or patching the live `envFrom` sources as a shortcut.
- Question `2601` should avoid `kubectl rollout restart deployment/env-bundle`, `kubectl delete pod -n envfrom-lab -l app=env-bundle`, `kubectl patch configmap app-env`, and ad hoc `kubectl patch deployment env-bundle ...` commands in the expected answer.

## Recommended Promotion Order

1. Promote `q2601` into `facilitator/assets/exams/cka/045`

## Planned Facilitator Mapping

- `q2601` -> `facilitator/assets/exams/cka/045`
