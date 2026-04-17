# CKA 2026 Next Single-Domain Drill: DNS Policy and dnsConfig

These drafts cover the next recommended networking-observability pack from the `cka-048+` roadmap:

1. Pod DNS policy and dnsConfig diagnostics

## Scope

This template adds one planning-focused single-domain drill:

- `4801` Pod DNS policy and dnsConfig diagnostics

## Status

- Question `4801` (`Pod DNS policy and dnsConfig diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- Question `4801` has now been promoted into facilitator pack `cka-048`.

## Promotion Notes

- Keep the runtime deterministic by validating exact `dnsPolicy`, `dnsConfig`, resolver search/order evidence, and safe manifest review instead of requiring a live CoreDNS or node-level mutation.
- Question `4801` should avoid `kubectl delete pod dns-client`, `kubectl rollout restart deployment dns-client`, `kubectl patch deployment dns-client`, and ad hoc edits to cluster DNS services in the expected answer.

## Suggested Promotion Order

1. Question `4801` is already promoted; the next work is keeping runtime smoke and contract coverage green.
