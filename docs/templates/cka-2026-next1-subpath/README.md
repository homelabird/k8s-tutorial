# CKA 2026 Next subPath Wave

These drafts cover the next recommended workload-configuration pack from the `cka-046+` roadmap:

1. ConfigMap subPath mount troubleshooting

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2701` (`ConfigMap subPath mount troubleshooting`) now mirrors the promoted hands-on facilitator pack `cka-046`.
- Question `2701` has now been promoted into facilitator pack `cka-046`.

## Important Constraints

- Question `2701` should require fixing the Deployment mount wiring in place instead of replacing the ConfigMap with an inline file or recreating the workload from scratch.
- Question `2701` should validate the exact ConfigMap item path, `subPath`, mount path, read-only flag, rollout success, and file contents inside the running container.
- Question `2701` should keep the runtime deterministic by using a single Deployment and ConfigMap pair rather than rollout restarts or ad hoc pod deletion.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q2701` -> `facilitator/assets/exams/cka/046`
