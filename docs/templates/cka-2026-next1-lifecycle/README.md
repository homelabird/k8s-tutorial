# CKA 2026 Next Single-Domain Drill: Lifecycle Hooks and Graceful Termination

These drafts cover the next recommended workload-behavior pack from the `cka-049+` roadmap:

1. Lifecycle hooks and graceful termination diagnostics

## Scope

This template adds one planning-focused single-domain drill:

- `4901` Lifecycle hooks and graceful termination diagnostics

## Status

- Question `4901` (`Lifecycle hooks and graceful termination diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- It is still a template draft and has not yet been promoted into `facilitator/assets/exams/cka/049`.

## Promotion Notes

- Promote this template into facilitator pack `cka-049` once the lifecycle-hook contract is stable.
- Keep the runtime deterministic by validating exact `preStop`, `terminationGracePeriodSeconds`, and container command evidence instead of forcing live rollout timing or signal-delivery assertions.
- Question `4901` should avoid `kubectl delete pod lifecycle-api`, `kubectl rollout restart deployment lifecycle-api`, `kubectl patch deployment lifecycle-api`, and ad hoc force-delete commands in the expected answer.

## Suggested Promotion Order

1. Promote question `4901` into facilitator pack `cka-049`.
