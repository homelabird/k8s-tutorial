# CKA 2026 Next Static Pod Wave

These drafts cover the next recommended cluster-architecture pack from the `cka-043+` roadmap:

1. Static pod manifest and mirror pod diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2401` (`Static pod manifest and mirror pod diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2401` has not been promoted yet and should be the next candidate for facilitator pack `cka-043`.

## Important Constraints

- Question `2401` should stay in the `planning + evidence export` lane. It should validate exact static-pod inventory, mirror-pod evidence, manifest-path inspection, hostNetwork review, and safe manifest guidance without mutating the live manifest path or restarting kubelet.
- Question `2401` should export exact evidence files instead of deleting the mirror pod, editing `/etc/kubernetes/manifests`, or force-restarting kubelet as a workaround.
- Question `2401` should avoid `kubectl delete pod`, `sudo systemctl restart kubelet`, `sudo mv /etc/kubernetes/manifests/*`, and ad hoc manifest rewrites in the expected answer.

## Recommended Promotion Order

1. Promote `q2401` into facilitator pack `cka-043`.

## Planned Facilitator Mapping

- `q2401` -> `facilitator/assets/exams/cka/043`
