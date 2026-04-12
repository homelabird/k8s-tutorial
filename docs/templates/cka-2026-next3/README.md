# CKA 2026 Next Wave Drafts

These drafts cover the next three recommended packs from the `cka-011+` roadmap:

1. ConfigMap and Secret repair
2. HorizontalPodAutoscaler troubleshooting
3. Node troubleshooting and maintenance

## Intended Use

- Use `assessment.json` as the authoring baseline for the next facilitator expansion wave.
- Use `answers.md`, `scripts/setup/`, and `scripts/validation/` as the implementation contract for each drill.
- Keep these drills single-domain and deterministic before promoting them into real facilitator packs.

## Current Template State

- Questions `301` (`ConfigMap/Secret`), `302` (`HPA`), and `303` (`node maintenance`) are fully scaffolded with `answers.md`, `scripts/setup/`, and validation scripts.
- None of these drafts have been promoted into facilitator packs yet.
- The expected promotion path is `q301 -> cka-011`, `q302 -> cka-012`, and `q303 -> cka-013`.

## Important Constraints

- Question 301 should keep configuration externalized. Validation should reject hardcoded replacements for Secret-backed values.
- Question 302 should validate HPA structure deterministically even when a local cluster does not expose live metrics.
- Question 303 should focus on `cordon` / `uncordon` style maintenance recovery and avoid requiring a heavyweight multi-node failure simulation.

## Recommended Promotion Order

1. Question 301 (`ConfigMap` / `Secret`) because it closes a common workload-configuration gap with minimal runtime variance.
2. Question 302 (`HPA`) because autoscaling remains uncovered and can be validated structurally before a full metrics-backed drill exists.
3. Question 303 (`node maintenance`) because it adds operator-grade cluster recovery workflow once the first two workload drills are in place.

## Planned Facilitator Mapping

- `q301` -> `facilitator/assets/exams/cka/011`
- `q302` -> `facilitator/assets/exams/cka/012`
- `q303` -> `facilitator/assets/exams/cka/013`
