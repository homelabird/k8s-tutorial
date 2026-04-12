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

- Question `401` (`Gateway API`) is fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `401` has now been promoted into facilitator pack `cka-014`.
- Questions `402` through `404` remain roadmap-only candidates and should be authored after `cka-014` runtime and discovery coverage are stable.

## Important Constraints

- Question 401 should validate GatewayClass, Gateway, and HTTPRoute consistency without depending on a heavy external gateway controller.
- Backend services should already exist so the drill stays focused on Gateway API repair rather than generic workload creation.
- Validation should reject stale fallback routes such as `/legacy`.

## Recommended Promotion Order

1. Question 401 (`Gateway API`) because it closes the highest-priority remaining networking curriculum gap.
2. Question 402 (`logs/resource triage`) because it adds operator evidence collection with low runtime variance.
3. Question 403 (`kubeadm lifecycle`) only after the lighter single-domain drills are stable.
4. Question 404 (`CRD/operator checks`) as the final stretch goal in this wave.

## Planned Facilitator Mapping

- `q401` -> `facilitator/assets/exams/cka/014`
