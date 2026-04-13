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

This closes the first high-value curriculum gaps identified in the April 2026 audit. The next milestone should avoid repeating PSA, Ingress, and CoreDNS, and should focus on the remaining uncovered CKA operator workflows.

## Goal For The Next Milestone

Ship the next expansion wave as `cka-039+` drills that fill the remaining practical gaps in the public CKA curriculum while staying deterministic in local Podman/kind environments.

`cka-011` through `cka-038` are now promoted facilitator packs, `cka-039` is now template-scaffolded, and `cka-040+` remain roadmap-only candidates.

## Recommended Candidate Packs

| Proposed pack | Focus | Why it matters | Runtime risk | Recommendation |
|---|---|---|---|---|
| `cka-039` | ServiceAccount imagePullSecrets and private registry diagnostics | Covers a remaining workload-identity gap around registry auth wiring, secret type validation, ServiceAccount linkage, and safe manifest inspection without mutating the live Deployment. | Low | Template scaffolded |

## Proposed Build Order

1. Promote `cka-039` into facilitator pack `cka-039`
2. Define the next `cka-040` candidate from the remaining uncovered operator workflows after registry-auth coverage is closed

## Suggested Problem Shapes

### `cka-039` ServiceAccount imagePullSecrets and private registry diagnostics

- This drill targets one remaining workload-identity workflow that still fits the deterministic single-domain model.
- It stays in the planning/evidence-export contract and focuses on ServiceAccount wiring, imagePullSecrets inspection, secret-type evidence, event visibility, and safe manifest review without mutating the live Deployment.

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
- `cka-039` is now scaffolded as template question `2001` in `docs/templates/cka-2026-next1-imagepullsecret`.
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
- The current `cka-031` contract stays planning-focused: it repairs exact Job inventory, completions, parallelism, backoffLimit, pod evidence, and safe manifest review while exporting evidence without deleting the Job or creating a replacement Job.
- The current `cka-032` contract stays planning-focused: it repairs exact startup, liveness, and readiness probe inventory, event evidence, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, or patching live probe fields.
- The current `cka-033` contract stays planning-focused: it repairs exact init container inventory, shared volume checks, mount-path evidence, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, or patching the live init container command.
- The current `cka-034` contract stays planning-focused: it repairs exact anti-affinity selectors, topology spread constraints, event evidence, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, scaling replicas, or patching the live placement rules.
- The current `cka-035` contract stays planning-focused: it repairs exact ServiceAccount inventory, projected token checks, mount-path evidence, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, or patching the live ServiceAccount fields.
- The current `cka-036` contract stays planning-focused: it repairs exact pod-level securityContext inventory, container privilege checks, fsGroup evidence, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, or patching the live securityContext fields.
- The current `cka-037` contract stays planning-focused: it repairs exact PriorityClass inventory, workload priority wiring, preemption-policy evidence, scheduler visibility, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, or patching the live PriorityClass or Deployment fields.
- The current `cka-038` contract stays planning-focused: it repairs exact pod-level resource inventory, QoS-class evidence, namespace events, and safe manifest review while exporting evidence without restarting the Deployment, deleting pods, or patching the live resource requests and limits.
- The current `cka-039` contract stays planning-focused: it repairs exact ServiceAccount, imagePullSecrets, image reference, secret-type, and event evidence while exporting safe manifest review without restarting the Deployment, deleting pods, or patching the live ServiceAccount or Deployment fields.

## Design Constraints

- Keep each new drill single-domain and independently evaluable.
- Prefer one namespace per drill and deterministic fixtures over cross-cluster orchestration.
- Add setup + validation scripts first, then a dedicated runtime smoke, then contract smoke coverage if the drill is promoted.
- Avoid adding heavy multi-node or kubeadm behavior unless the simulation contract is explicit and reproducible locally.

## Exit Criteria

A `cka-039+` drill should be considered ready only when all of the following are true:

- facilitator pack exists and is registered in `labs.json`
- setup and validation scripts are syntax-checked
- `/api/v1/assessments` discovery test covers the new pack
- a dedicated runtime smoke can solve and evaluate it end to end
- release notes and changelog can describe it without caveats
