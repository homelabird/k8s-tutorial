# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- No unreleased changes.

## [v1.2.0] - 2026-04-12

### Added

- Added five CKA 2026 single-domain drills:
  - `cka-006` RBAC least privilege
  - `cka-007` deployment rollout and rollback
  - `cka-008` scheduling constraints
  - `cka-009` NetworkPolicy troubleshooting
  - `cka-010` persistent storage troubleshooting
- Added `docs/templates/cka-2026-next5` as the source template set for those five drill domains.
- Added `scripts/verify/run-cka-2026-single-domain-drills.sh` to run the promoted drills end to end.
- Added `scripts/verify/cka-2026-single-domain-contract-smoke.sh` and CI wiring to protect drill registry, docs, and runner alignment.

### Changed

- Updated facilitator discovery so `/api/v1/assessments` and `facilitator/assets/exams/labs.json` expose the new single-domain drills.
- Refreshed `review-batch-handoff-pack-smoke.sh` expectations so handoff export contract checks match the current landing summary and draft output format.

### Verification

- `cd facilitator && npm test -- --runInBand`
- `SUITE_TIMEOUT_SECONDS=0 bash scripts/verify/run-cka-2026-single-domain-drills.sh`
- `bash scripts/verify/run-verify-contract-smokes.sh`
- `python3` YAML parse of `.github/workflows/ci.yml`

## [v1.1.0] - 2026-04-12

### Added

- Added facilitator lifecycle and validation unit coverage.
- Added browser UI smoke coverage for dashboard, exam, results, retry, terminate, and feedback flows.
- Added review landing and handoff tooling, including summaries, drafts, commands, and packed export artifacts.
- Added workflow contract coverage for regression and review-batch paths.

### Changed

- Tightened `cka-003`, `cka-004`, and `cka-005` validators to better match question intent.
- Hardened `kind-cluster`, `jumphost`, and verification runtime behavior for stable full regression execution.
- Aligned handoff pack smoke behavior with landed outside-batch state.

### Verification

- `cd facilitator && npm test -- --runInBand`
- `cd scripts/verify && node browser-ui-smoke.mjs`
- `bash scripts/verify/run-verify-contract-smokes.sh`
- `bash scripts/verify/run-review-batch-checks.sh --status-all`
- `bash scripts/verify/run-cka-2026-regressions.sh`
