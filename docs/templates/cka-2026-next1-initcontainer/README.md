# CKA 2026 Next InitContainer Wave

These drafts cover the next recommended workload-startup pack from the `cka-033+` roadmap:

1. init-container shared volume repair

## Scope

This template adds one hands-on single-domain drill:

- `1401` init-container shared volume repair

## Status

- Question `1401` (init-container shared volume repair) now mirrors the promoted hands-on facilitator pack `cka-033`.
- Question `1401` has now been promoted into facilitator pack `cka-033`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact init command, shared-volume mounts, rollout success, and seeded file instead of rebuilding the image.
- Question 1401 should avoid rollout restarts, deleting pods, or replacing the init-container workflow with baked-in image content.

## Suggested Promotion Order

1. Question `1401` is already promoted; the next work is keeping runtime smoke and contract coverage green.
