# CKA 2026 Next Affinity Wave

These drafts cover the next recommended workload-placement pack from the `cka-034+` roadmap:

1. pod anti-affinity and topology spread repair

## Scope

This template adds one hands-on single-domain drill:

- `1501` pod anti-affinity and topology spread repair

## Status

- Question `1501` (pod anti-affinity and topology spread repair) now mirrors the promoted hands-on facilitator pack `cka-034`.
- Question `1501` has now been promoted into facilitator pack `cka-034`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact node selector, anti-affinity selector, topology spread settings, and rollout success.
- Question 1501 should avoid deleting pods, scaling the Deployment, or stripping the placement rules entirely in the expected answer.

## Suggested Promotion Order

1. Question `1501` is already promoted; the next work is keeping runtime smoke and contract coverage green.
