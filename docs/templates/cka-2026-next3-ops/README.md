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
- Question `503` has now been promoted into facilitator pack `cka-021`.
- Authoring for this wave is complete. The remaining work is not new promotion, but hands-on conversion of the already promoted `cka-020` and `cka-021` packs.

## Important Constraints

- Question `501` should stay in the `planning + evidence export` lane. It should validate exact scheduler/controller-manager manifest paths, health endpoints, kubeconfig references, and safe troubleshooting notes without touching live static Pods.
- Question `502` is the next hands-on conversion candidate from this wave. The promoted `cka-020` pack still exports evidence today, but the next revision should repair live Service and headless-Service reachability with deterministic probe fixtures instead of staying brief-only.
- Question `503` is the other next hands-on conversion candidate from this wave. The promoted `cka-021` pack still exports evidence today, but the next revision should repair live selector, endpoint, and exposure wiring without reintroducing ingress or Gateway API overlap.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q501` -> `facilitator/assets/exams/cka/019`
- `q502` -> `facilitator/assets/exams/cka/020`
- `q503` -> `facilitator/assets/exams/cka/021`
