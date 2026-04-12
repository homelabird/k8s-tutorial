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

This closes the first high-value curriculum gaps identified in the April 2026 audit. The next milestone should avoid repeating PSA, Ingress, and CoreDNS, and should focus on the remaining uncovered CKA operator workflows.

## Goal For The Next Milestone

Ship a second expansion wave as `cka-011+` drills that fills the remaining practical gaps in the public CKA curriculum while staying deterministic in local Podman/kind environments.

## Recommended Candidate Packs

| Proposed pack | Focus | Why it matters | Runtime risk | Recommendation |
|---|---|---|---|---|
| `cka-011` | ConfigMap and Secret repair | Basic workload configuration is still uncovered in the promoted drill set. | Low | Build next |
| `cka-012` | HorizontalPodAutoscaler troubleshooting | Autoscaling is a common exam workflow and currently missing. | Medium | Build next |
| `cka-013` | Node troubleshooting and maintenance | Adds `cordon`, `drain`, `uncordon`, and node readiness recovery. | Medium | Build next |
| `cka-014` | Gateway API traffic management | Covers the newer public curriculum direction beyond classic Ingress. | Medium | Build after `cka-011..013` |
| `cka-015` | Logs and resource usage triage | Covers `kubectl logs`, `previous`, `top`, and fast operator diagnosis workflows. | Low | Build after `cka-014` |
| `cka-016` | Kubeadm lifecycle / upgrade planning | High-value admin skill, but heavier to simulate correctly. | High | Keep as stretch goal |
| `cka-017` | CRD / operator installation checks | Publicly relevant, but lower practical priority than node and workload operations. | Medium | Keep as optional stretch goal |

## Proposed Build Order

1. `cka-011` ConfigMap and Secret repair
2. `cka-012` HPA troubleshooting
3. `cka-013` node troubleshooting and maintenance
4. `cka-014` Gateway API traffic management
5. `cka-015` logs and resource usage triage
6. `cka-016` kubeadm lifecycle planning
7. `cka-017` CRD / operator installation checks

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

### `cka-014` Gateway API traffic management

- Gateway and HTTPRoute exist but host/path routing is incomplete.
- Candidate verifies:
  - GatewayClass / Gateway / HTTPRoute references are consistent
  - traffic reaches the intended backend
  - old fallback route is removed

### `cka-015` Logs and resource usage triage

- Multi-container workload has one failing sidecar and resource pressure symptoms.
- Candidate verifies:
  - the correct failing container is identified
  - operator extracts the intended log evidence file
  - resource requests/limits or probe config are corrected

## Design Constraints

- Keep each new drill single-domain and independently evaluable.
- Prefer one namespace per drill and deterministic fixtures over cross-cluster orchestration.
- Add setup + validation scripts first, then a dedicated runtime smoke, then contract smoke coverage if the drill is promoted.
- Avoid adding heavy multi-node or kubeadm behavior unless the simulation contract is explicit and reproducible locally.

## Exit Criteria

A `cka-011+` drill should be considered ready only when all of the following are true:

- facilitator pack exists and is registered in `labs.json`
- setup and validation scripts are syntax-checked
- `/api/v1/assessments` discovery test covers the new pack
- a dedicated runtime smoke can solve and evaluate it end to end
- release notes and changelog can describe it without caveats
