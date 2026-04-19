# CKA 2026 Next Ephemeral Debug Wave

These drafts cover the next recommended troubleshooting pack from the `cka-042+` roadmap:

1. Ephemeral containers and kubectl debug diagnostics

## Scope

This template adds one hands-on single-domain drill:

- `2301` Ephemeral container and kubectl debug repair

## Status

- Question `2301` (Ephemeral container and kubectl debug repair) now mirrors the promoted hands-on facilitator pack `cka-042`.
- Question `2301` has now been promoted into facilitator pack `cka-042`.

## Promotion Notes

- Keep the runtime deterministic by validating the exact ephemeral container name, image, target-container wiring, Running pod state, and debug logs instead of patching the Pod directly.
- Question `2301` should avoid deleting or restarting the Pod, or replacing `kubectl debug` with direct Pod-spec patching in the expected answer.

## Suggested Promotion Order

1. Question `2301` is already promoted; the next work is keeping runtime smoke and contract coverage green.
