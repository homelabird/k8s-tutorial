# CKA Roadmap 2026-04-12

## Current Baseline

The current CKA 2026 line now includes these promoted packs:

- `cka-003` security, ingress, dedicated DNS
- `cka-004` cluster DNS recovery
- `cka-005` mixed-environment security, ingress, cluster DNS
- `cka-006` RBAC least privilege
- `cka-007` deployment rollout and rollback
- `cka-008` scheduling constraints
- `cka-009` NetworkPolicy troubleshooting
- `cka-010` persistent storage troubleshooting
- `cka-011` ConfigMap and Secret repair
- `cka-012` HPA troubleshooting
- `cka-013` node troubleshooting and maintenance
- `cka-014` Gateway API traffic management
- `cka-015` logs and resource usage triage
- `cka-016` kubeadm lifecycle planning
- `cka-017` CRD and operator installation checks
- `cka-018` etcd backup and restore workflow
- `cka-019` scheduler / controller-manager troubleshooting
- `cka-020` service and pod connectivity diagnostics
- `cka-021` service exposure and endpoint debugging
- `cka-022` kubelet and node NotReady troubleshooting

This closes the first high-value curriculum gaps identified in the April 2026 audit. The next milestone should avoid repeating PSA, Ingress, and CoreDNS, and should focus on the remaining uncovered CKA operator workflows.

## Goal For The Next Milestone

Ship the next expansion wave as `cka-024+` drills that fills the remaining practical gaps in the public CKA curriculum while staying deterministic in local Podman/kind environments.

`cka-011`, `cka-012`, `cka-013`, `cka-014`, `cka-015`, `cka-016`, `cka-017`, `cka-018`, `cka-019`, `cka-020`, `cka-021`, and `cka-022` are now promoted facilitator packs. `cka-023` is template-scaffolded and `cka-024+` remain roadmap-only candidates.

## Recommended Candidate Packs

| Proposed pack | Focus | Why it matters | Runtime risk | Recommendation |
|---|---|---|---|---|
| `cka-024` | resource quota and LimitRange troubleshooting | Adds a focused drill for namespace guardrails, quota inspection, and safe workload sizing guidance without overlapping HPA or storage drills. | Medium | Roadmap-only candidate |

## Proposed Build Order

1. `cka-023` PKI and certificate expiry troubleshooting
2. `cka-024` resource quota and LimitRange troubleshooting

## Suggested Problem Shapes

### `cka-023` PKI and certificate expiry troubleshooting

- A certificate renewal brief is incomplete and contains stale or unsafe renewal guidance.
- Candidate verifies:
  - certificate inspection and expiry reasoning are captured
  - renewal planning evidence is exported for later review
  - the drill stays in the safe planning/evidence-export lane without rotating live certificates

## Current Authoring State

- `cka-016` is now promoted as facilitator pack `cka-016`, sourced from template question `403` in `docs/templates/cka-2026-next4`.
- `cka-017` is now promoted as facilitator pack `cka-017`, sourced from template question `404` in `docs/templates/cka-2026-next4`.
- `cka-018` is now promoted as facilitator pack `cka-018`, sourced from template question `405` in `docs/templates/cka-2026-next4`.
- `cka-019` is now promoted as facilitator pack `cka-019`, sourced from template question `501` in `docs/templates/cka-2026-next3-ops`.
- `cka-020` is now promoted as facilitator pack `cka-020`, sourced from template question `502` in `docs/templates/cka-2026-next3-ops`.
- `cka-021` is now promoted as facilitator pack `cka-021`, sourced from template question `503` in `docs/templates/cka-2026-next3-ops`.
- `cka-022` is now promoted as facilitator pack `cka-022`, sourced from template question `601` in `docs/templates/cka-2026-next2-ops`.
- `cka-023` is now template-scaffolded from question `602` in `docs/templates/cka-2026-next2-ops` and is ready for facilitator promotion.
- The current `cka-016` contract remains intentionally planning-focused: it repairs a kubeadm upgrade brief and exports evidence files instead of performing a live kubeadm upgrade.
- The current `cka-017` contract stays deterministic by validating a repaired `CRD + operator Deployment + custom resource` bundle without OLM.
- The current `cka-018` contract stays planning-focused: it validates exact `etcdctl` snapshot/restore commands, static pod manifest handoff, and evidence export without performing a live restore.
- The current `cka-019` contract stays planning-focused: it repairs exact scheduler/controller-manager manifest paths, health endpoints, kubeconfig references, and evidence export without touching live static Pods.
- The current `cka-020` contract stays evidence-export focused: it repairs exact service, headless service, pod DNS, and probe commands without mutating live selectors or workloads.
- The current `cka-021` contract stays evidence-export focused: it repairs exact Service selector, port, endpoint, and reachability guidance without patching Deployments or introducing ingress resources.
- The current `cka-022` contract stays planning-focused: it repairs exact node-condition, kubelet service, runtime, and config guidance while exporting evidence without restarting services or draining nodes.
- The current `cka-023` contract should stay planning-focused: it should repair exact certificate inspection, kubeadm expiry, renewal planning, and readiness verification guidance while exporting evidence without rotating live certificates.

## Design Constraints

- Keep each new drill single-domain and independently evaluable.
- Prefer one namespace per drill and deterministic fixtures over cross-cluster orchestration.
- Add setup + validation scripts first, then a dedicated runtime smoke, then contract smoke coverage if the drill is promoted.
- Avoid adding heavy multi-node or kubeadm behavior unless the simulation contract is explicit and reproducible locally.

## Exit Criteria

A `cka-024+` drill should be considered ready only when all of the following are true:

- facilitator pack exists and is registered in `labs.json`
- setup and validation scripts are syntax-checked
- `/api/v1/assessments` discovery test covers the new pack
- a dedicated runtime smoke can solve and evaluate it end to end
- release notes and changelog can describe it without caveats
