# CKA 2026 Next EnvFrom Wave

These drafts cover the next recommended workload-configuration pack from the `cka-045+` roadmap:

1. ConfigMap and Secret envFrom repair

## Scope

This template adds one hands-on single-domain drill:

- `2601` ConfigMap and Secret envFrom repair

## Status

- Question `2601` (ConfigMap and Secret envFrom repair) now mirrors the promoted hands-on facilitator pack `cka-045`.
- Question `2601` has now been promoted into facilitator pack `cka-045`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact envFrom source names, secret prefix, rollout success, and printed environment variables.
- Question 2601 should avoid inlining the values into env entries, deleting pods, or patching the live ConfigMap or Secret in the expected answer.

## Suggested Promotion Order

1. Question `2601` is already promoted; the next work is keeping runtime smoke and contract coverage green.
