# CKA 2026 Next Single-Domain Drill: DNS Policy and dnsConfig

These drafts cover the next recommended networking-observability pack from the `cka-048+` roadmap:

1. Pod DNS policy repair

## Scope

This template adds one hands-on single-domain drill:

- `4801` Pod DNS policy repair

## Status

- Question `4801` (`Pod DNS policy repair`) now mirrors the promoted hands-on facilitator pack `cka-048`.
- Question `4801` has now been promoted into facilitator pack `cka-048`.

## Promotion Notes

- Keep the runtime deterministic by fixing only Deployment-level `dnsPolicy` and `dnsConfig` fields.
- Question `4801` should validate the exact nameserver, search, and `ndots` values plus the resolver file observed from the running Pod.
- Question `4801` should avoid any CoreDNS or cluster DNS mutation in the expected answer.

## Suggested Promotion Order

1. Question `4801` is already promoted; the next work is keeping runtime smoke and contract coverage green.
