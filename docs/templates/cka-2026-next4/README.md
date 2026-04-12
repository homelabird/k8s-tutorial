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

- Questions `401` (`Gateway API`) and `402` (`logs/resource triage`) are fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `401` has now been promoted into facilitator pack `cka-014`.
- Question `402` has now been promoted into facilitator pack `cka-015`.
- Questions `403` and `404` remain roadmap-only candidates and should be authored after `cka-015` runtime and discovery coverage are stable.

## Important Constraints

- Question 401 should validate GatewayClass, Gateway, and HTTPRoute consistency without depending on a heavy external gateway controller.
- Question 402 should force the candidate to export both previous logs and `kubectl top` evidence, but validators should only assert the exported artifacts and repaired workload contract.
- Backend services should already exist so the drills stay focused on repair rather than generic workload creation.
- Validation should reject stale fallback routes such as `/legacy`.

## Recommended Promotion Order

1. Question 403 (`kubeadm lifecycle`) once the lighter single-domain drills are stable.
2. Question 404 (`CRD/operator checks`) as the final stretch goal in this wave.

## Planned Facilitator Mapping

- `q401` -> `facilitator/assets/exams/cka/014`
- `q402` -> `facilitator/assets/exams/cka/015`
