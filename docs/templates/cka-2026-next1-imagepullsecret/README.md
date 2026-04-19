# CKA 2026 Next Image Pull Secret Wave

These drafts cover the next recommended registry-auth pack from the `cka-039+` roadmap:

1. ServiceAccount imagePullSecret wiring repair

## Scope

This template adds one hands-on single-domain drill:

- `2001` ServiceAccount imagePullSecret wiring repair

## Status

- Question `2001` (ServiceAccount imagePullSecret wiring repair) now mirrors the promoted hands-on facilitator pack `cka-039`.
- Question `2001` has now been promoted into facilitator pack `cka-039`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact ServiceAccount, imagePullSecret, preserved secret type, rollout success, and running Pod wiring.
- Question 2001 should avoid mutating the existing Secret type, deleting pods, or creating replacement pull credentials in the expected answer.

## Suggested Promotion Order

1. Question `2001` is already promoted; the next work is keeping runtime smoke and contract coverage green.
