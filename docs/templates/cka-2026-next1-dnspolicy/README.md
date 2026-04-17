# CKA 2026 Next Single-Domain Drill: DNS Policy and dnsConfig

These drafts cover the next recommended networking-observability pack from the `cka-048+` roadmap:

1. Pod DNS policy and dnsConfig diagnostics

## Scope

This template adds one planning-focused single-domain drill:

- `4801` Pod DNS policy and dnsConfig diagnostics

## Status

- Question `4801` (`Pod DNS policy and dnsConfig diagnostics`) is now fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- It is still a template draft and has not yet been promoted into `facilitator/assets/exams/cka/048`.

## Promotion Notes

- Promote this template into facilitator pack `cka-048` once the DNS-policy contract is stable.
- Keep the runtime deterministic by validating exact `dnsPolicy`, `dnsConfig`, resolver search/order evidence, and safe manifest review instead of requiring a live CoreDNS or node-level mutation.
- Question `4801` should avoid `kubectl delete pod dns-client`, `kubectl rollout restart deployment dns-client`, `kubectl patch deployment dns-client`, and ad hoc edits to cluster DNS services in the expected answer.

## Suggested Promotion Order

1. Promote question `4801` into facilitator pack `cka-048`.
