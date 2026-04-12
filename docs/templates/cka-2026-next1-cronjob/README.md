# CKA 2026 Next CronJob Wave

These drafts cover the next recommended batch scheduling pack from the `cka-030+` roadmap:

1. CronJob schedule, suspend, and history diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1101` (`CronJob schedule, suspend, and history diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1101` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `1101` should stay in the `planning + evidence export` lane. It should validate exact CronJob inventory, schedule, suspend status, concurrency policy, history limits, and safe manifest review without deleting the CronJob.
- Question `1101` should export exact evidence files instead of creating ad hoc Jobs, forcing immediate schedule changes, or suspending the CronJob as a workaround.
- Question `1101` should avoid `kubectl delete cronjob`, `kubectl create job --from=cronjob/...`, and `kubectl patch cronjob ...` as corrective actions in the expected answer.

## Recommended Promotion Order

1. Promote question `1101` into facilitator pack `cka-030`.

## Planned Facilitator Mapping

- `q1101` -> `facilitator/assets/exams/cka/030`
