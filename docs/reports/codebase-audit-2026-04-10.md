# Codebase Audit Report

Date: 2026-04-10

## Scope

This audit combined parallel sub-agent review across:

- `facilitator/src`, `facilitator/tests`, and exam validator wiring
- `scripts/verify`, diagnostics packaging, and GitHub workflow wiring
- `app/public`, `app/services`, `nginx`, and active exam user-flow code

The goal was to identify current risks in the active worktree and immediately reduce the highest-value ones.

## Findings

### 1. Backend exam lifecycle had state-consistency failure modes

- Area: `facilitator/src/services/examService.js`, `facilitator/src/utils/redisClient.js`
- Risk:
  - cleanup failure could leave the API reporting a clean end while Redis metadata was deleted too early
  - evaluation could leave orphan status state if the exam payload was missing
  - asynchronous preparation failure could keep the single active-exam lock stuck
  - Redis TTL defaults could keep exam data far longer than intended
- Impact: Critical
- Action in this pass: Fixed

### 2. Diagnostics summary was still tied to a two-host assumption

- Area: `scripts/verify/collect-cka-2026-diagnostics.sh`, `scripts/verify/render-cka-2026-summary-markdown.sh`
- Risk:
  - summary generation assumed only `jumphost` and `jumphost-dns`
  - new environment layouts would not automatically appear in diagnostics or job summaries
  - markdown triage output could drift from the raw bundle as more suites were added
- Impact: High
- Action in this pass: Fixed

### 3. Workflow and runner input handling needed hardening

- Area: `.github/workflows/cka-2026-regressions.yml`, `scripts/verify/run-cka-2026-regressions.sh`
- Risk:
  - manual workflow inputs were too trusting
  - invalid timeout values could fail late and opaquely on a self-hosted runner
  - optional archive upload behavior was noisy when diagnostics were intentionally skipped
- Impact: High
- Action in this pass: Fixed

### 4. Frontend session and terminal lifecycle was brittle under repeated use

- Area: `app/public/js/components/terminal-service.js`, `app/public/js/index.js`
- Risk:
  - reconnect and resize paths could accumulate fragile listener state
  - the active exam warning modal was easy to couple to stale content or repeated lifecycle cleanup
- Impact: High
- Action in this pass: Fixed

### 5. Event payload validation was too permissive for downstream merges

- Area: `facilitator/src/middleware/validators.js`, `facilitator/src/controllers/examController.js`
- Risk:
  - array payloads could pass validation and then be merged into stored exam metadata as numeric keys
- Impact: High
- Action in this pass: Fixed and covered by unit tests

### 6. Remaining regression protection is still thin at the browser layer

- Area: `app/public/js/*`, `docs/webapp/index-functionality.md`
- Risk:
  - the frontend still has many stateful branches, so fixture-backed smoke must keep covering the highest-risk flows as UI work continues
  - results-page recovery and feedback flows are especially easy to regress because they depend on async state transitions and localStorage
- Impact: Medium
- Action in this pass: Fixed with a Playwright-backed browser smoke for `index`, `exam`, `results`, and `answers`, covering active-session warnings, terminal toggling, results navigation, re-evaluation recovery, retry recovery, feedback success/failure, and terminate flows

## Work Completed From This Report

- Hardened backend exam lifecycle handling around evaluation, cleanup, lock release, and Redis TTL defaults.
- Generalized diagnostics host discovery so summary generation and markdown rendering follow the current exam environment layout automatically, then added top-level contract/review runners plus synthetic collector, pack, review handoff export, landing-summary rendering, and renderer smokes so the raw bundle, packed archive, exported review handoff archive, markdown landing summary, and markdown job summary all stay protected in normal CI.
- Tightened workflow and aggregated runner input handling, separated always-on logs from optional diagnostics uploads, and added lightweight workflow contract smokes so both the self-hosted regression wiring and the review-batch workflow stay protected without having to trigger the full runners.
- Reduced terminal and active-session modal lifecycle fragility in the frontend.
- Tightened exam event validation and expanded unit coverage.
- Added a browser-level smoke harness for the index active-session modal refresh path, dashboard results navigation, exam terminal toggling, exam terminate flow, completed-exam review-mode entry, results re-evaluation/retry recovery, results actions, answers navigation, and feedback success/failure, plus a lightweight scenario-contract smoke so the documented fixture inventory stays aligned with the executable list mode.
- Wired the browser-level smoke into the default CI workflow so fixture-backed UI regressions fail before the heavier self-hosted suites are needed.

## Recommended Next Work

1. Land the currently untracked regression scripts, diagnostics helpers, browser smoke harness, workflows, reports, and facilitator tests in reviewable batches, using `run-review-batch-checks.sh` as the default local review entrypoint, `run-review-batch-checks.sh --files <batch>` as the matching landing manifest, `run-review-batch-checks.sh --split <batch>` as the per-state sub-batch view for mixed landings, `run-review-batch-checks.sh --split <batch> --filter <state>` when one state such as `tracked-modified` needs isolated review, `run-review-batch-checks.sh --diff <batch> --filter tracked-modified` when the next step is to inspect actual tracked-file changes, `run-review-batch-checks.sh --hunks <batch> --filter tracked-modified` when that tracked subset still needs to be split by scope or function, `run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified` when a curated landing-sized grouping already exists, `run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified --name <subchange>` when that curated map should be narrowed to a single landing slice, `run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified --name <subchange> --detail` when that slice should immediately expand to its relevant diff hunks, `run-review-batch-checks.sh --note <batch> --filter tracked-modified --name <subchange>` when that slice should turn into a reusable landing note, `run-review-batch-checks.sh --note <batch> --filter tracked-modified --name <subchange> --write <path>` when that slice-level note should be materialized as a handoff artifact on disk, `run-review-batch-checks.sh --note-manifest` when previously generated slice-level handoff artifacts need to be rechecked from the note manifest log, `run-review-batch-checks.sh --note-manifest --latest` when only the newest slice-level handoff artifact needs follow-up, `run-review-batch-checks.sh --note-manifest --latest --show` when that newest slice-level handoff artifact should be printed inline again as `NOTE-CONTENT`, `run-review-batch-checks.sh --memo <batch> --filter tracked-modified` when the full tracked batch should collapse into a single structured landing memo, `run-review-batch-checks.sh --memo <batch> --filter tracked-modified --write <path>` when that memo should be materialized as a handoff artifact on disk, `run-review-batch-checks.sh --memo-manifest` when previously generated handoff artifacts need to be rechecked from the manifest log, `run-review-batch-checks.sh --memo-manifest --latest` when only the newest handoff artifact needs follow-up, `run-review-batch-checks.sh --memo-manifest --latest --show` when that newest handoff artifact should be printed inline again as `MEMO-CONTENT`, `run-review-batch-checks.sh --handoff-index` when the raw note/memo manifests should be collapsed back into one batch-level artifact inventory, `run-review-batch-checks.sh --handoff-index <batch> --show` when that inventory should expand into concrete `NOTE-ARTIFACT` and `MEMO-ARTIFACT` rows for one batch, `run-review-batch-checks.sh --landing-plan` when the completed handoff artifacts should be collapsed into commit-order `LANDING-STEP` rows, `run-review-batch-checks.sh --landing-plan <batch> --show` when that plan should expand into concrete `LANDING-FILE` and latest `LANDING-ARTIFACT` rows for one batch, `run-review-batch-checks.sh --landing-commands` when that same plan should become copy-pasteable `LANDING-COMMAND-STEP` and `LANDING-COMMAND` rows with `git add` / `git commit` drafts, `render-review-landing-summary.sh` when that expanded plan should become a human-readable markdown landing checklist and, with `landing-commands.txt` as a third input, surface either the first actionable stage/commit pair or the next pending handoff command directly in the summary entrypoint, `render-review-landing-drafts.sh` when that same expanded plan should become per-batch commit/PR draft text and, with `landing-commands.txt` as a third input, per-batch shell-ready stage/commit blocks, and `pack-review-batch-handoff.sh` when the completed handoff artifacts should be exported as one shareable directory and archive, `run-review-batch-checks.sh --untracked-groups <batch>` when the tracked review is complete but the batch still has many new files to land, `run-review-batch-checks.sh --untracked-groups <batch> --name <group>` when that untracked surface should be narrowed to a curated landing group, `run-review-batch-checks.sh --note <batch> --filter untracked --name <group>` when that curated untracked landing group should turn into a reusable handoff note, `run-review-batch-checks.sh --note <batch> --filter untracked --name <group> --write <path>` when that untracked-group note should be materialized on disk, `run-review-batch-checks.sh --memo <batch> --filter untracked --write <path>` when the complete set of curated untracked groups should collapse into one grouped handoff memo, `run-review-batch-checks.sh --status <batch>` as the batch-level readiness check with a short cause for `clean` / `tracked-modified` / `untracked` drift plus a `HANDOFF` line that says whether note/memo generation is complete, `run-review-batch-checks.sh --status-all` as the readiness-sorted one-screen landing overview with aggregate `HANDOFF`, verdicts, reasons, and a copy-pasteable next command when one exists, `run-review-batch-checks.sh --next` when only that next command is needed, and `run-review-batch-checks.sh --next --verbose` when that recommendation needs a `NEXT` line with batch and focus-file context and, for curated tracked slices, advances through pending `.artifacts/review-notes/<batch>-<subchange>.txt` note artifacts, then the batch-level memo artifact, then through pending `.artifacts/review-notes/<batch>-untracked-<group>.txt` notes for curated untracked landing groups, then to the grouped untracked memo artifact, and finally to the next unresolved landing batch; batches like `batch-1`, `batch-3`, `batch-4`, and `batch-5` follow that same curated untracked note/memo path instead of falling back to a plain `--split` immediately. When no pending review handoff remains, `--next` now returns `echo no-pending-review-actions`, `--next --verbose` reports `NEXT | state=complete`, `FIRST-ACTION` disappears from `--status-all`, `--handoff-index` becomes the artifact follow-up view, `--landing-plan` becomes the staging-order view, `--landing-commands` becomes the copy-pasteable shell draft view, `render-review-landing-summary.sh` becomes the human handoff rendering step plus first-command-or-next-handoff entrypoint, `render-review-landing-drafts.sh` becomes the commit/PR draft plus shell-command rendering step, and `pack-review-batch-handoff.sh` becomes the export step.
   - Use `run-review-batch-checks.sh --outside-batches` whenever the review batches look clean but the repo still has tracked-modified or untracked files outside the current manifests; `--status-all` now exposes that drift as an `OUTSIDE-BATCHES` line, `--outside-batch-groups` collapses it into subsystem-sized landing candidates, `--outside-batch-note` and `--outside-batch-memo` materialize those candidates as reusable handoff artifacts, `--handoff-index` now shows an explicit `outside-batches | HANDOFF-ARTIFACTS ...` row while that drift remains, `--outside-batch-plan` turns the remaining groups into ordered `OUTSIDE-LANDING-STEP` rows, `--outside-landing-batches` turns those same groups into formal `LANDING-STEP` rows named `outside-<group>`, `--outside-landing-batches --name outside-frontend-runtime --show` narrows that view to the first concrete outside landing target, and `--outside-landing-draft --name outside-frontend-runtime --write .artifacts/review-drafts/outside-frontend-runtime.md` turns that target into the next commit/PR draft artifact. Exported handoff bundles now include both views, and the landing renderers can take the formal outside landing view as a second input so exported `landing-summary.md` and `landing-drafts.md` no longer omit repo drift outside the current review manifests.
2. Keep the workflow and diagnostics contract smokes synthetic and deterministic as more runner inputs, archive contents, host layouts, and summary fields are added, rather than letting them turn into mini end-to-end suites.
3. Keep the browser smoke fixture lean and deterministic as more UI branches are added, rather than letting it turn into a slow end-to-end suite, and keep the lightweight scenario-contract smoke as the first line of defense against scope drift.
