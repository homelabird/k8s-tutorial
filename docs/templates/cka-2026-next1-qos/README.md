# CKA 2026 Next QoS Wave

These drafts cover the next recommended workload-resource pack from the `cka-038+` roadmap:

1. resource requests, limits, and QoS repair

## Scope

This template adds one hands-on single-domain drill:

- `1901` resource requests, limits, and QoS repair

## Status

- Question `1901` (resource requests, limits, and QoS repair) now mirrors the promoted hands-on facilitator pack `cka-038`.
- Question `1901` has now been promoted into facilitator pack `cka-038`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact requests and limits, rollout success, and resulting Guaranteed QoS class.
- Question 1901 should avoid rollout restarts, deleting pods, or using kubectl set resources as a shortcut in the expected answer.

## Suggested Promotion Order

1. Question `1901` is already promoted; the next work is keeping runtime smoke and contract coverage green.
