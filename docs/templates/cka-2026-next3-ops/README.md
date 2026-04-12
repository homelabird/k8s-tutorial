# CKA 2026 Next Ops Wave Drafts

These drafts cover the next recommended ops-oriented packs from the `cka-020+` roadmap:

1. scheduler / controller-manager troubleshooting
2. service and pod connectivity diagnostics
3. service exposure and endpoint debugging

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for each drill.
- Keep these drills single-domain and deterministic before promoting them into real facilitator packs.

## Current Template State

- Question `501` (`scheduler / controller-manager troubleshooting`) is fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `501` has now been promoted into facilitator pack `cka-019`.
- Question `502` (`service and pod connectivity diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `502` has now been promoted into facilitator pack `cka-020`.
- Question `503` (`service exposure and endpoint debugging`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- The remaining work is no longer authoring for `q503`. It is promoting `q503` into a real facilitator pack with discovery and runtime coverage.

## Important Constraints

- Question `501` should stay in the `planning + evidence export` lane. It should validate exact scheduler/controller-manager manifest paths, health endpoints, kubeconfig references, and safe troubleshooting notes without touching live static Pods.
- Question `502` should prove pod-to-pod and service reachability with deterministic probe workloads and exported evidence, not with flaky external traffic generation.
- Question `503` should stay focused on selector, endpoint, and exposure repair without reintroducing ingress or Gateway API overlap.
- Question `503` should keep the current wave pattern: repair a deterministic brief, export exact evidence, and avoid mutating live workloads during the drill.

## Recommended Promotion Order

1. Question `503` because service exposure debugging is now fully scaffolded and is the next remaining single-domain networking gap in this wave.

## Planned Facilitator Mapping

- `q501` -> `facilitator/assets/exams/cka/019`
- `q502` -> `facilitator/assets/exams/cka/020`
- `q503` -> `facilitator/assets/exams/cka/021`
