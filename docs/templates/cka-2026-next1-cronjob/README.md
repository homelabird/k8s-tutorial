# CKA 2026 Next CronJob Wave

These drafts cover the next recommended batch scheduling pack from the `cka-030+` roadmap:

1. CronJob schedule, suspend, and history diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `1101` CronJob schedule, suspend, and history repair

## Status

- Question `1101` (CronJob schedule, suspend, and history repair) now mirrors the promoted hands-on facilitator pack `cka-030`.
- Question `1101` has now been promoted into facilitator pack `cka-030`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact CronJob fields and then grading a smoke Job created from the repaired template instead of forcing the live schedule.
- Question `1101` should avoid deleting the CronJob, changing the schedule just to trigger an immediate run, or replacing it with a one-off Job in the expected answer.

## Suggested Promotion Order

1. Question `1101` is already promoted; the next work is keeping runtime smoke and contract coverage green.
