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

This closes the first high-value curriculum gaps identified in the April 2026 audit. The next milestone should avoid repeating PSA, Ingress, and CoreDNS, and should focus on the remaining uncovered CKA operator workflows.

## Goal For The Next Milestone

Ship the next expansion wave as `cka-016+` drills that fills the remaining practical gaps in the public CKA curriculum while staying deterministic in local Podman/kind environments.

`cka-011`, `cka-012`, `cka-013`, `cka-014`, and `cka-015` are now promoted facilitator packs. `cka-016+` remain roadmap-only candidates.

## Recommended Candidate Packs

| Proposed pack | Focus | Why it matters | Runtime risk | Recommendation |
|---|---|---|---|---|
| `cka-016` | Kubeadm lifecycle / upgrade planning | High-value admin skill, but heavier to simulate correctly. | High | Keep as stretch goal |
| `cka-017` | CRD / operator installation checks | Publicly relevant, but lower practical priority than node and workload operations. | Medium | Keep as optional stretch goal |

## Proposed Build Order

1. `cka-016` kubeadm lifecycle planning
2. `cka-017` CRD / operator installation checks

## Suggested Problem Shapes

### `cka-011` ConfigMap and Secret repair

- Broken deployment mounts the wrong ConfigMap key and references a missing Secret key.
- Candidate verifies:
  - workload becomes Available
  - env/volume references are corrected
  - only the intended keys are exposed

### `cka-012` HPA troubleshooting

- Deployment exists, HPA exists, but target reference or metric threshold is wrong.
- Candidate verifies:
  - HPA points at the intended workload
  - min/max replicas and target are corrected
  - scale-up condition can be observed or structurally validated

### `cka-013` Node troubleshooting and maintenance

- One node is intentionally unschedulable or NotReady-like from the drill contract perspective.
- Candidate verifies:
  - node maintenance commands are applied in the right order
  - workload is rescheduled correctly
  - cluster returns to intended scheduling state

## Design Constraints

- Keep each new drill single-domain and independently evaluable.
- Prefer one namespace per drill and deterministic fixtures over cross-cluster orchestration.
- Add setup + validation scripts first, then a dedicated runtime smoke, then contract smoke coverage if the drill is promoted.
- Avoid adding heavy multi-node or kubeadm behavior unless the simulation contract is explicit and reproducible locally.

## Exit Criteria

A `cka-016+` drill should be considered ready only when all of the following are true:

- facilitator pack exists and is registered in `labs.json`
- setup and validation scripts are syntax-checked
- `/api/v1/assessments` discovery test covers the new pack
- a dedicated runtime smoke can solve and evaluate it end to end
- release notes and changelog can describe it without caveats
