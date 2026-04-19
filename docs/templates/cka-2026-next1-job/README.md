# CKA 2026 Next Job Wave

These drafts cover the next recommended batch workload controller pack from the `cka-031+` roadmap:

1. Job completions, parallelism, and backoff diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `1201` Job completions, parallelism, and backoff repair

## Status

- Question `1201` (Job completions, parallelism, and backoff repair) now mirrors the promoted hands-on facilitator pack `cka-031`.
- Question `1201` has now been promoted into facilitator pack `cka-031`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact Job spec, successful completion, and completed pod logs instead of deleting and recreating the workload.
- Question `1201` should avoid deleting the Job, creating a replacement Job, or mutating status fields in the expected answer.

## Suggested Promotion Order

1. Question `1201` is already promoted; the next work is keeping runtime smoke and contract coverage green.
