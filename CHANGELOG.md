# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Added `scripts/verify/cka-2026-single-domain-inventory.sh` and `.github/workflows/cka-2026-single-domain-nightly.yml` for balanced nightly sampling across the promoted `cka-006` through `cka-050` drills.
- Added `scripts/verify/cka-2026-single-domain-nightly-workflow-contract-smoke.sh` plus CI wiring to protect nightly lane planning, serialization, and diagnostics artifact publication.

### Changed

- Hardened the promoted single-domain contract smoke so it now derives the full `cka-006` through `cka-050` inventory from a shared helper and enforces required facilitator metadata fields.
- Updated the root and verification docs to describe the nightly lane inventory helper and the self-hosted nightly workflow.

### Fixed

- Repaired missing `labs.json` metadata for `cka-046` through `cka-050`.
- Fixed the single-domain timeout rerun path so `wait_for_validation_script` stays available inside the timeout shell.
- Fixed `cka-009` NetworkPolicy validation by isolating real service endpoints from probe pods with workload-only selectors.

### Verification

- `bash scripts/verify/cka-2026-single-domain-contract-smoke.sh`
- `bash scripts/verify/cka-2026-single-domain-nightly-workflow-contract-smoke.sh`
- `bash scripts/verify/run-verify-contract-smokes.sh single-domain-contract single-domain-nightly`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-006`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-009`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-014 cka-015`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-017 cka-018`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-023 cka-025`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-032 cka-037`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-043 cka-048`
- `bash scripts/verify/run-cka-2026-single-domain-drills.sh cka-011 cka-012 cka-013 cka-016 cka-019 cka-020 cka-021 cka-022 cka-024 cka-026 cka-027 cka-028 cka-029 cka-030 cka-031 cka-033 cka-034 cka-035 cka-036 cka-038 cka-039 cka-040 cka-041 cka-042 cka-044 cka-045 cka-046 cka-047 cka-049 cka-050`

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
