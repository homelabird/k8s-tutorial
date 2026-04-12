# CKA 2026 Gap-Coverage Drafts

These are draft question objects for five high-priority CKA-aligned areas that are still underrepresented in the current `cka/003`, `cka/004`, and `cka/005` packs:

1. RBAC least-privilege repair
2. Deployment rolling update and rollback
3. NetworkPolicy troubleshooting
4. PersistentVolume / PersistentVolumeClaim troubleshooting
5. Scheduling with taints, tolerations, and affinity

## Intended Use

- Use `assessment.json` as the question-authoring baseline for future CKA expansion packs.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for each draft question.
- Keep future packs focused on uncovered official curriculum areas, not on repeating `PSA`, `Ingress`, or `CoreDNS`.

## Current Template State

- Questions `201` (`RBAC`), `202` (`rollout / rollback`), `203` (`NetworkPolicy`), `204` (`storage`), and `205` (`scheduling`) are fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- All five drafts have now been promoted into facilitator packs `cka-006` through `cka-010`.
- The remaining work is no longer authoring. It is discovery, regression coverage, and deciding whether these single-domain drills should be bundled into a new multi-question pack.

## Important Constraints

- Question 202 should avoid deprecated `--record` usage and instead rely on rollout history plus change-cause annotation.
- Question 203 should use real listeners on ports `8080` and `5432` so NetworkPolicy port checks match actual traffic.
- Question 204 should stay deterministic in local kind/Podman environments by using a simple local PV backend and by validating binding plus mount behavior.
- Question 205 should verify both workload spec and final node placement, even if the implementation uses a simple node selector instead of required node affinity.

## Recommended Promotion Order

1. Question 201 (`RBAC`) because it closes a full curriculum gap with minimal infra overhead.
2. Question 202 (`rollout / rollback`) because it adds a common real CKA workflow with low runtime variance.
3. Question 205 (`scheduling`) because it rounds out current workload coverage with taints and placement control.
4. Question 203 (`NetworkPolicy`) because it closes a major networking gap once a deterministic reachability harness is in place.
5. Question 204 (`storage`) because it now has a deterministic scaffold but still benefits from extra runtime checks when promoted into a real exam pack.

## Promoted Packs

- `q201` -> `facilitator/assets/exams/cka/006`
- `q202` -> `facilitator/assets/exams/cka/007`
- `q205` -> `facilitator/assets/exams/cka/008`
- `q203` -> `facilitator/assets/exams/cka/009`
- `q204` -> `facilitator/assets/exams/cka/010`
