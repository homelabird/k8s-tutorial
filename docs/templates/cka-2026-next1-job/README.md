# CKA 2026 Next Job Wave

These drafts cover the next recommended batch workload controller pack from the `cka-031+` roadmap:

1. Job completions, parallelism, and backoff diagnostics

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for the drill.
- Keep this drill single-domain and deterministic before promoting it into a real facilitator pack.

## Current Template State

- Question `1201` (`Job completions, parallelism, and backoff diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `1201` has not yet been promoted into a facilitator pack.

## Important Constraints

- Question `1201` should stay in the `planning + evidence export` lane. It should validate exact Job inventory, completions, parallelism, backoff limit, pod evidence, and safe manifest review without deleting the Job.
- Question `1201` should export exact evidence files instead of creating replacement Jobs, deleting pods as a workaround, or patching status fields.
- Question `1201` should avoid `kubectl delete job`, `kubectl create job ...`, `kubectl replace --force`, and status mutation commands in the expected answer.

## Recommended Promotion Order

1. Promote `q1201` into facilitator pack `cka-031`

## Planned Facilitator Mapping

- `q1201` -> `facilitator/assets/exams/cka/031`
