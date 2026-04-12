# CKA 2026 Next Wave Drafts

These drafts cover the next four recommended packs from the `cka-014+` roadmap:

1. Gateway API traffic management
2. Logs and resource usage triage
3. Kubeadm lifecycle planning
4. CRD and operator installation checks

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for each drill.
- Keep these drills single-domain and deterministic before promoting them into real facilitator packs.

## Current Template State

- Questions `401` (`Gateway API`), `402` (`logs/resource triage`), `403` (`kubeadm lifecycle planning`), and `404` (`CRD/operator checks`) are fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `401` has now been promoted into facilitator pack `cka-014`.
- Question `402` has now been promoted into facilitator pack `cka-015`.
- Question `403` has now been promoted into facilitator pack `cka-016`.
- Question `404` has now been promoted into facilitator pack `cka-017`.

## Important Constraints

- Question 401 should validate GatewayClass, Gateway, and HTTPRoute consistency without depending on a heavy external gateway controller.
- Question 402 should force the candidate to export both previous logs and `kubectl top` evidence, but validators should only assert the exported artifacts and repaired workload contract.
- Question 403 should stay strictly in the `planning + evidence export` lane. It should validate upgrade sequencing, backup scope, and control-plane command safety without attempting a live kubeadm upgrade inside the local Podman/kind stack.
- Question 404 should validate a deterministic `CRD + operator Deployment + custom resource` bundle without depending on OLM or a live reconciliation loop.
- Backend services should already exist so the drills stay focused on repair rather than generic workload creation.
- Validation should reject stale fallback routes such as `/legacy`.

## Recommended Promotion Order

The `cka-014` through `cka-017` wave is now fully promoted.

## Planned Facilitator Mapping

- `q401` -> `facilitator/assets/exams/cka/014`
- `q402` -> `facilitator/assets/exams/cka/015`
- `q403` -> `facilitator/assets/exams/cka/016`
- `q404` -> `facilitator/assets/exams/cka/017`
