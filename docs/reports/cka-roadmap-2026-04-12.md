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
- `cka-023` PKI and certificate expiry troubleshooting
- `cka-024` resource quota and LimitRange troubleshooting
- `cka-025` container runtime and CRI endpoint diagnostics
- `cka-026` StorageClass and dynamic provisioning diagnostics
- `cka-027` PodDisruptionBudget and drain planning
- `cka-028` StatefulSet identity and headless service diagnostics
- `cka-029` DaemonSet rollout and node coverage diagnostics
- `cka-030` CronJob schedule, suspend, and history diagnostics
- `cka-031` Job completions, parallelism, and backoff diagnostics
- `cka-032` Readiness, liveness, and startupProbe diagnostics
- `cka-033` InitContainer and shared volume diagnostics
- `cka-034` Pod anti-affinity and topology spread diagnostics
- `cka-035` ServiceAccount identity and projected token diagnostics
- `cka-036` Pod securityContext and fsGroup diagnostics
- `cka-037` PriorityClass and preemption diagnostics
- `cka-038` Pod resource requests, limits, and QoS diagnostics
- `cka-039` ServiceAccount imagePullSecrets and private registry diagnostics
- `cka-040` PersistentVolume reclaim policy and claimRef diagnostics
- `cka-041` PersistentVolumeClaim expansion and resize diagnostics
- `cka-042` Ephemeral containers and kubectl debug diagnostics
- `cka-043` Static pod manifest and mirror pod diagnostics
- `cka-044` Projected ConfigMap and Secret volume diagnostics
- `cka-045` ConfigMap and Secret envFrom diagnostics

This closes the first high-value curriculum gaps identified in the April 2026 audit. The next milestone should avoid repeating PSA, Ingress, and CoreDNS, and should focus on the remaining uncovered CKA operator workflows.

## Goal For The Next Milestone

Ship the next expansion wave as `cka-046+` drills that fill the remaining practical gaps in the public CKA curriculum while staying deterministic in local Podman/kind environments.

`cka-011` through `cka-050` are now promoted facilitator packs, and `cka-051+` remain roadmap-only candidates.

## Recommended Candidate Packs

| Proposed pack | Focus | Why it matters | Runtime risk | Recommendation |
|---|---|---|---|---|
| `cka-051` | Taints, tolerations, and NoExecute eviction diagnostics | Covers workload-level NoExecute tolerations, selector wiring, and taint evidence without relying on live eviction timing. | Low | Template scaffold next |

## Proposed Build Order

1. Promote `cka-051` taints, tolerations, and NoExecute eviction diagnostics from template to facilitator pack

## Suggested Problem Shapes

### `cka-051` Taints, tolerations, and NoExecute eviction diagnostics

- Validate exact toleration key, effect, operator, seconds, and workload selector wiring for a single deployment.
- Export event history and manifest evidence without relying on live eviction timing.
- Keep the drill planning-focused by forbidding pod deletion, rollout restart, drain, and ad hoc node-taint mutation.

## Current Authoring State

- `cka-016` is now promoted as facilitator pack `cka-016`, sourced from template question `403` in `docs/templates/cka-2026-next4`.
- `cka-017` is now promoted as facilitator pack `cka-017`, sourced from template question `404` in `docs/templates/cka-2026-next4`.
- `cka-018` is now promoted as facilitator pack `cka-018`, sourced from template question `405` in `docs/templates/cka-2026-next4`.
- `cka-019` is now promoted as facilitator pack `cka-019`, sourced from template question `501` in `docs/templates/cka-2026-next3-ops`.
- `cka-020` is now promoted as facilitator pack `cka-020`, sourced from template question `502` in `docs/templates/cka-2026-next3-ops`.
- `cka-021` is now promoted as facilitator pack `cka-021`, sourced from template question `503` in `docs/templates/cka-2026-next3-ops`.
- `cka-022` is now promoted as facilitator pack `cka-022`, sourced from template question `601` in `docs/templates/cka-2026-next2-ops`.
- `cka-023` is now promoted as facilitator pack `cka-023`, sourced from template question `602` in `docs/templates/cka-2026-next2-ops`.
- `cka-024` is now promoted as facilitator pack `cka-024`, sourced from template question `603` in `docs/templates/cka-2026-next2-ops`.
- `cka-025` is now promoted as facilitator pack `cka-025`, sourced from template question `604` in `docs/templates/cka-2026-next2-ops`.
- `cka-026` is now promoted as facilitator pack `cka-026`, sourced from template question `701` in `docs/templates/cka-2026-next1-storage`.
- `cka-027` is now promoted as facilitator pack `cka-027`, sourced from template question `801` in `docs/templates/cka-2026-next1-disruption`.
- `cka-028` is now promoted as facilitator pack `cka-028`, sourced from template question `901` in `docs/templates/cka-2026-next1-stateful`.
- `cka-029` is now promoted as facilitator pack `cka-029`, sourced from template question `1001` in `docs/templates/cka-2026-next1-daemonset`.
- `cka-030` is now promoted as facilitator pack `cka-030`, sourced from template question `1101` in `docs/templates/cka-2026-next1-cronjob`.
- `cka-031` is now promoted as facilitator pack `cka-031`, sourced from template question `1201` in `docs/templates/cka-2026-next1-job`.
- `cka-032` is now promoted as facilitator pack `cka-032`, sourced from template question `1301` in `docs/templates/cka-2026-next1-probes`.
- `cka-033` is now promoted as facilitator pack `cka-033`, sourced from template question `1401` in `docs/templates/cka-2026-next1-initcontainer`.
- `cka-034` is now promoted as facilitator pack `cka-034`, sourced from template question `1501` in `docs/templates/cka-2026-next1-affinity`.
- `cka-035` is now promoted as facilitator pack `cka-035`, sourced from template question `1601` in `docs/templates/cka-2026-next1-serviceaccount`.
- `cka-036` is now promoted as facilitator pack `cka-036`, sourced from template question `1701` in `docs/templates/cka-2026-next1-securitycontext`.
- `cka-037` is now promoted as facilitator pack `cka-037`, sourced from template question `1801` in `docs/templates/cka-2026-next1-priorityclass`.
- `cka-038` is now promoted as facilitator pack `cka-038`, sourced from template question `1901` in `docs/templates/cka-2026-next1-qos`.
- `cka-039` is now promoted as facilitator pack `cka-039`, sourced from template question `2001` in `docs/templates/cka-2026-next1-imagepullsecret`.
- `cka-040` is now promoted as facilitator pack `cka-040`, sourced from template question `2101` in `docs/templates/cka-2026-next1-pvreclaim`.
- `cka-041` is now promoted as facilitator pack `cka-041`, sourced from template question `2201` in `docs/templates/cka-2026-next1-pvresize`.
- `cka-042` is now promoted as facilitator pack `cka-042`, sourced from template question `2301` in `docs/templates/cka-2026-next1-ephemeraldebug`.
- `cka-043` is now promoted as facilitator pack `cka-043`, sourced from template question `2401` in `docs/templates/cka-2026-next1-staticpod`.
- `cka-044` is now promoted as facilitator pack `cka-044`, sourced from template question `2501` in `docs/templates/cka-2026-next1-projectedvolume`.
- `cka-045` is now promoted as facilitator pack `cka-045`, sourced from template question `2601` in `docs/templates/cka-2026-next1-envfrom`.
- `cka-046` is now promoted as facilitator pack `cka-046`, sourced from template question `2701` in `docs/templates/cka-2026-next1-subpath`.
- `cka-047` is now promoted as facilitator pack `cka-047`, sourced from template question `2801` in `docs/templates/cka-2026-next1-rwop`.
- `cka-048` is now promoted as facilitator pack `cka-048`, sourced from template question `4801` in `docs/templates/cka-2026-next1-dnspolicy`.
- `cka-049` is now promoted as facilitator pack `cka-049`, sourced from template question `4901` in `docs/templates/cka-2026-next1-lifecycle`.
- `cka-050` is now promoted as facilitator pack `cka-050`, sourced from template question `5001` in `docs/templates/cka-2026-next1-downwardapi`.
- `cka-051` is now promoted as facilitator pack `cka-051`, sourced from template question `5101` in `docs/templates/cka-2026-next1-taints`.
- Current track policy as of `2026-04-19` is split into three lanes rather than one broad planning-focused bucket.
- `cka-016`, `cka-018`, `cka-019`, `cka-022`, `cka-023`, `cka-025`, and `cka-027` remain intentionally `planning-focused`. These drills validate command safety, evidence export, and control-plane or node-ops sequencing without live kubeadm, etcd, kubelet, PKI, runtime, or drain mutations.
- `cka-017` remains deterministic but not planning-only: it validates a repaired `CRD + operator Deployment + custom resource` bundle without OLM.
- `cka-020` and `cka-021` stay evidence-export based in the current promoted packs, but they are now selected as the next hands-on conversion wave because Service selector, endpoint, and reachability repair can be graded deterministically with local fixtures.
- `cka-024` and `cka-026` now stay in the `ops-diagnostics` lane for the near term instead of the next hands-on wave. Quota, LimitRange, StorageClass, and PVC guardrails interact with namespace or cluster-scoped safety constraints, so the current non-mutating drills remain the safer contract until a tighter live-repair design exists.
- `cka-028`, `cka-029`, `cka-030`, `cka-031`, `cka-032`, `cka-033`, `cka-034`, `cka-035`, `cka-036`, `cka-037`, `cka-038`, `cka-039`, `cka-040`, `cka-041`, `cka-042`, `cka-043`, `cka-044`, `cka-045`, `cka-046`, `cka-047`, `cka-048`, `cka-049`, `cka-050`, and `cka-051` are now hands-on workload repair drills rather than planning-focused checklist exports.

## Design Constraints

- Keep each new drill single-domain and independently evaluable.
- Prefer one namespace per drill and deterministic fixtures over cross-cluster orchestration.
- Add setup + validation scripts first, then a dedicated runtime smoke, then contract smoke coverage if the drill is promoted.
- Avoid adding heavy multi-node or kubeadm behavior unless the simulation contract is explicit and reproducible locally.

## Exit Criteria

A `cka-052+` drill should be considered ready only when all of the following are true:

- facilitator pack exists and is registered in `labs.json`
- setup and validation scripts are syntax-checked
- `/api/v1/assessments` discovery test covers the new pack
- a dedicated runtime smoke can solve and evaluate it end to end
- release notes and changelog can describe it without caveats
