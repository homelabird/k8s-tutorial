# CKA 2026 Next ServiceAccount Wave

These drafts cover the next recommended workload-identity pack from the `cka-035+` roadmap:

1. ServiceAccount projected token repair

## Scope

This template adds one hands-on single-domain drill:

- `1601` ServiceAccount projected token repair

## Status

- Question `1601` (ServiceAccount projected token repair) now mirrors the promoted hands-on facilitator pack `cka-035`.
- Question `1601` has now been promoted into facilitator pack `cka-035`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact ServiceAccount wiring, projected token audience/path, rollout success, and mounted token file.
- Question 1601 should avoid rollout restarts, deleting pods, or removing the projected token volume in the expected answer.

## Suggested Promotion Order

1. Question `1601` is already promoted; the next work is keeping runtime smoke and contract coverage green.
