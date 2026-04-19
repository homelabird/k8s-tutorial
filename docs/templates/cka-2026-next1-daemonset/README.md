# CKA 2026 Next DaemonSet Wave

These drafts cover the next recommended DaemonSet-focused operations pack from the `cka-029+` roadmap:

1. DaemonSet rollout and node coverage diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `1001` DaemonSet rollout and Linux node coverage repair

## Status

- Question `1001` (DaemonSet rollout and Linux node coverage repair) now mirrors the promoted hands-on facilitator pack `cka-029`.
- Question `1001` has now been promoted into facilitator pack `cka-029`.

## Promotion Notes

- Keep the runtime deterministic by validating the Linux node selector, RollingUpdate strategy, rollout readiness, and desired pod coverage instead of mutating nodes.
- Question `1001` should avoid deleting the DaemonSet, cordoning nodes, or converting the workload into a Deployment in the expected answer.

## Suggested Promotion Order

1. Question `1001` is already promoted; the next work is keeping runtime smoke and contract coverage green.
