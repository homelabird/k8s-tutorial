# CKA 2026 Next Image Pull Secret Wave

These drafts cover the next recommended registry-auth pack from the `cka-039+` roadmap:

1. ServiceAccount imagePullSecrets and private registry diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `2001` (`ServiceAccount imagePullSecrets and private registry diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `2001` has now been promoted into facilitator pack `cka-039`.

## Important Constraints

- Question `2001` should stay in the `planning + evidence export` lane. It should validate exact Deployment inventory, ServiceAccount wiring, imagePullSecrets inspection, secret-type evidence, and safe manifest review without patching the live Deployment or ServiceAccount.
- Question `2001` should export exact evidence files instead of restarting the Deployment, deleting pods, or force-patching the live ServiceAccount and imagePullSecrets as a workaround.
- Question `2001` should avoid `kubectl rollout restart`, `kubectl delete pod`, `kubectl set serviceaccount`, and ad hoc `kubectl patch deployment ...` remediation commands in the expected answer.

## Recommended Promotion Order

1. No further promotion work remains in this template set.

## Planned Facilitator Mapping

- `q2001` -> `facilitator/assets/exams/cka/039`
