# CKA 2026 Next Single-Domain Drill: Lifecycle Hooks and Graceful Termination

These drafts cover the next recommended workload-behavior pack from the `cka-049+` roadmap:

1. Lifecycle hooks and graceful termination repair

## Scope

This template adds one hands-on single-domain drill:

- `4901` Lifecycle hooks and graceful termination repair

## Status

- Question `4901` (`Lifecycle hooks and graceful termination repair`) now mirrors the promoted hands-on facilitator pack `cka-049`.
- Question `4901` has now been promoted into facilitator pack `cka-049`.

## Promotion Notes

- Keep the runtime deterministic by fixing only Deployment template fields and validating rollout success through a saved rollout-status artifact.
- Question `4901` should validate the exact `preStop` command, `terminationGracePeriodSeconds`, image, and long-running command contract.
- Question `4901` should avoid manual pod deletion, force-delete flows, or rollout restarts in the expected answer.

## Suggested Promotion Order

1. Question `4901` is already promoted; the next work is keeping runtime smoke and contract coverage green.
