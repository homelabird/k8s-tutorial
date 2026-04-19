# CKA 2026 Next Static Pod Wave

These drafts cover the next recommended cluster-architecture pack from the `cka-043+` roadmap:

1. Static pod manifest repair

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2401` (`Static pod manifest repair`) now mirrors the promoted hands-on facilitator pack `cka-043`.
- Question `2401` has now been promoted into facilitator pack `cka-043`.

## Important Constraints

- Question `2401` should require editing `/etc/kubernetes/manifests/audit-agent.yaml` in place instead of replacing the workload with a normal Pod or Deployment.
- Question `2401` should keep the Pod identity (`audit-agent`), namespace (`staticpod-lab`), and image (`busybox:1.36`) while repairing `hostNetwork` and the command loop.
- The local drill runtime uses a sync helper to mirror manifest edits into the inner cluster, so validators should assert the corrected manifest, Running mirror Pod, and emitted log line rather than kubelet restart behavior.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q2401` -> `facilitator/assets/exams/cka/043`
