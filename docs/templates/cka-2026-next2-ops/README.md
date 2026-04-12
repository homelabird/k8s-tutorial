# CKA 2026 Next Ops Wave 2 Drafts

These drafts cover the next recommended ops-oriented packs from the `cka-022+` roadmap:

1. kubelet and node NotReady troubleshooting

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for each drill.
- Keep these drills single-domain and deterministic before promoting them into real facilitator packs.

## Current Template State

- Question `601` (`kubelet and node NotReady troubleshooting`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `601` has now been promoted into facilitator pack `cka-022`.
- No further promotion work remains in this template set.

## Important Constraints

- Question `601` should stay in the `planning + evidence export` lane. It should validate exact node-condition checks, kubelet service checks, kubelet log hints, and safe maintenance notes without stopping or restarting kubelet.
- Question `601` should export exact evidence files instead of attempting live node repair inside the drill.
- Question `601` should avoid `reboot`, `systemctl restart kubelet`, and `kubectl drain` as corrective actions in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q601` -> `facilitator/assets/exams/cka/022`
