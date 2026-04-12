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

This closes the first high-value curriculum gaps identified in the April 2026 audit. The next milestone should avoid repeating PSA, Ingress, and CoreDNS, and should focus on the remaining uncovered CKA operator workflows.

## Goal For The Next Milestone

Ship the next expansion wave as `cka-031+` drills that fill the remaining practical gaps in the public CKA curriculum while staying deterministic in local Podman/kind environments.

`cka-011` through `cka-030` are now promoted facilitator packs, `cka-031` is now template-scaffolded, and `cka-032+` remain roadmap-only candidates.

## Recommended Candidate Packs

| Proposed pack | Focus | Why it matters | Runtime risk | Recommendation |
|---|---|---|---|---|
| `cka-031` | Job completions, parallelism, and backoff diagnostics | Fills the remaining core batch-controller workflow gap after the CronJob drill while staying deterministic and single-domain. | Low | Template scaffolded, promote next |

## Proposed Build Order

1. Promote `cka-031` into a facilitator pack after validating the template contract

## Suggested Problem Shapes

### `cka-031`: Job completions, parallelism, and backoff diagnostics

- The next drill after `cka-030` should target the standalone `Job` controller gap that remains after the CronJob drill.
- It should stay in the same planning/evidence-export lane: exact Job inventory, completions, parallelism, backoffLimit, pod evidence, and safe manifest review.
- It should avoid deleting the Job, replacing it with a new Job, force-replacing manifests, or mutating status fields during the expected solution.

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
- `cka-031` is now template-scaffolded as question `1201` in `docs/templates/cka-2026-next1-job` and is the next promotion candidate.
- The current `cka-030` contract stays planning-focused: it repairs exact CronJob inventory, schedule, suspend state, concurrency policy, history limits, and job template review while exporting evidence without deleting the CronJob or forcing an immediate run.
- The current `cka-016` contract remains intentionally planning-focused: it repairs a kubeadm upgrade brief and exports evidence files instead of performing a live kubeadm upgrade.
- The current `cka-017` contract stays deterministic by validating a repaired `CRD + operator Deployment + custom resource` bundle without OLM.
- The current `cka-018` contract stays planning-focused: it validates exact `etcdctl` snapshot/restore commands, static pod manifest handoff, and evidence export without performing a live restore.
- The current `cka-019` contract stays planning-focused: it repairs exact scheduler/controller-manager manifest paths, health endpoints, kubeconfig references, and evidence export without touching live static Pods.
- The current `cka-020` contract stays evidence-export focused: it repairs exact service, headless service, pod DNS, and probe commands without mutating live selectors or workloads.
- The current `cka-021` contract stays evidence-export focused: it repairs exact Service selector, port, endpoint, and reachability guidance without patching Deployments or introducing ingress resources.
- The current `cka-022` contract stays planning-focused: it repairs exact node-condition, kubelet service, runtime, and config guidance while exporting evidence without restarting services or draining nodes.
- The current `cka-023` contract stays planning-focused: it repairs exact certificate inspection, kubeadm expiry, renewal planning, and readiness verification guidance while exporting evidence without rotating live certificates.
- The current `cka-024` contract stays planning-focused: it repairs exact resource quota, LimitRange, workload sizing, and safe remediation guidance while exporting evidence without deleting guardrail objects or stripping requests and limits from workloads.
- The current `cka-025` contract stays planning-focused: it repairs exact kubelet runtime endpoint, `crictl`, and runtime inspection guidance while exporting evidence without restarting services or rewriting kubelet configuration.
- The current `cka-026` contract stays planning-focused: it repairs exact StorageClass inventory, default-class inspection, PVC/workload analysis, and safe manifest guidance while exporting evidence without deleting StorageClass objects or PVCs.
- The current `cka-027` contract stays planning-focused: it repairs exact PodDisruptionBudget inventory, node workload audit, safe cordon/drain preview guidance, and evidence export without executing a live drain or deleting disruption budgets.
- The current `cka-028` contract stays planning-focused: it repairs exact StatefulSet inventory, headless Service inspection, ordinal DNS guidance, PVC inventory, and safe manifest review while exporting evidence without deleting StatefulSets or PVCs.
- The current `cka-029` contract stays planning-focused: it repairs exact DaemonSet inventory, rollout status, node coverage, update-strategy guidance, and safe manifest review while exporting evidence without deleting the DaemonSet or cordoning nodes.
- The current `cka-031` contract is defined as planning-focused: it repairs exact Job inventory, completions, parallelism, backoffLimit, pod evidence, and safe manifest review while exporting evidence without deleting the Job or creating a replacement Job.

## Design Constraints

- Keep each new drill single-domain and independently evaluable.
- Prefer one namespace per drill and deterministic fixtures over cross-cluster orchestration.
- Add setup + validation scripts first, then a dedicated runtime smoke, then contract smoke coverage if the drill is promoted.
- Avoid adding heavy multi-node or kubeadm behavior unless the simulation contract is explicit and reproducible locally.

## Exit Criteria

A `cka-031+` drill should be considered ready only when all of the following are true:

- facilitator pack exists and is registered in `labs.json`
- setup and validation scripts are syntax-checked
- `/api/v1/assessments` discovery test covers the new pack
- a dedicated runtime smoke can solve and evaluate it end to end
- release notes and changelog can describe it without caveats
