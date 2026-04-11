# Review Inventory

Date: 2026-04-10

## Purpose

This inventory groups the current untracked additions into reviewable batches so they can be landed without mixing infrastructure, browser smoke, diagnostics, and backend test work into one opaque diff.

Use `./scripts/verify/run-review-batch-checks.sh --files <batch>` to print the exact landing manifest for any batch below.
Use `./scripts/verify/run-review-batch-checks.sh --split <batch>` to print per-state landing subsets for any batch below.
Use `./scripts/verify/run-review-batch-checks.sh --split <batch> --filter <state>` to focus on only `clean`, `tracked-modified`, `untracked`, or `missing`.
Use `./scripts/verify/run-review-batch-checks.sh --diff <batch> --filter tracked-modified` to print structured diff summaries for the modified tracked subset before landing.
Use `./scripts/verify/run-review-batch-checks.sh --hunks <batch> --filter tracked-modified` to break that tracked subset into function- or scope-level landing chunks.
Use `./scripts/verify/run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified` to print named landing-sized review groups when a curated map exists.
Use `./scripts/verify/run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified --name <subchange>` to isolate one named landing group inside that map.
Use `./scripts/verify/run-review-batch-checks.sh --memo <batch> --filter tracked-modified` to print one structured landing memo across every named tracked subchange in the batch.
Use `./scripts/verify/run-review-batch-checks.sh --note <batch> --filter tracked-modified --name <subchange> --write <path>` to persist one named landing note as a generated handoff artifact.
Use `./scripts/verify/run-review-batch-checks.sh --note-manifest` to inspect generated note artifacts from `NOTE_MANIFEST_PATH`, and `--note-manifest --latest` to focus on the most recent one.
Use `./scripts/verify/run-review-batch-checks.sh --note-manifest --latest --show` to print the latest recorded note body inline as `NOTE-CONTENT` lines.
Use `./scripts/verify/run-review-batch-checks.sh --memo <batch> --filter tracked-modified --write <path>` to persist that landing memo as a generated handoff artifact.
Use `./scripts/verify/run-review-batch-checks.sh --memo <batch> --filter untracked --write <path>` to persist one grouped untracked landing memo after the per-group notes are complete.
Use `./scripts/verify/run-review-batch-checks.sh --memo-manifest` to inspect generated memo artifacts from `MEMO_MANIFEST_PATH`, and `--memo-manifest --latest` to focus on the most recent one.
Use `./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest --show` to print the latest recorded memo body inline as `MEMO-CONTENT` lines.
Use `./scripts/verify/run-review-batch-checks.sh --handoff-index` to pivot those raw manifests back into batch-level handoff inventory lines with actual-vs-expected note and memo counts.
Use `./scripts/verify/run-review-batch-checks.sh --handoff-index <batch> --show` to expand one batch into its recorded `NOTE-ARTIFACT` and `MEMO-ARTIFACT` rows.
Use `./scripts/verify/run-review-batch-checks.sh --landing-plan` to collapse the current handoff state into commit-order `LANDING-STEP` rows once notes and memos are complete.
Use `./scripts/verify/run-review-batch-checks.sh --landing-plan <batch> --show` to expand one batch into `LANDING-HANDOFF`, `LANDING-FILE`, and latest `LANDING-ARTIFACT` rows before staging.
Use `./scripts/verify/run-review-batch-checks.sh --landing-commands` to turn those `LANDING-STEP` rows into `LANDING-COMMAND-STEP` and `LANDING-COMMAND` drafts with ready-to-run `git add` and `git commit` lines.
Use `./scripts/verify/run-review-batch-checks.sh --landing-commands <batch-or-outside-batch>` to narrow that command sheet to one landing target such as `batch-2` or `outside-frontend-runtime`.
Use `./scripts/verify/pack-review-batch-handoff.sh` to export the current handoff state as a shareable directory plus `.tar.gz` once `--next` has no pending actions left, including both raw `OUTSIDE-LANDING-*` candidates and the formal `outside-<group>` landing-batch view.
Use `./scripts/verify/render-review-landing-summary.sh <landing-plan-expanded.txt> [outside-landing-batches-expanded.txt] [landing-commands.txt]` when that export needs a human-readable markdown commit/PR landing checklist in addition to the raw `LANDING-*` rows; pass the outside landing view too when repo drift still sits outside the current review manifests, and pass `landing-commands.txt` when the summary entrypoint should also show the first actionable stage/commit pair or, if landing is still pending, the next handoff command.
Use `./scripts/verify/render-review-landing-drafts.sh <landing-plan-expanded.txt> [outside-landing-batches-expanded.txt] [landing-commands.txt]` when the same export needs per-batch and per-outside-group commit/PR draft text plus shell-ready stage/commit blocks.
Use `./scripts/verify/run-review-batch-checks.sh --note <batch> --filter tracked-modified --name <subchange>` to print a reusable landing note for that group.
Use `./scripts/verify/run-review-batch-checks.sh --note <batch> --filter untracked --name <group>` to print a reusable landing note for one curated untracked group.
Use `./scripts/verify/run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified --name <subchange> --detail` to print only the hunk scopes inside that named landing group.
Use `./scripts/verify/run-review-batch-checks.sh --status <batch>` to print `readiness`, a short `reason`, `total/existing/missing/clean/tracked-modified/untracked` counts, plus `HANDOFF`, `STATE`, and `MISSING` lines and spot drift before landing.
Use `./scripts/verify/run-review-batch-checks.sh --status-all` to scan the full landing surface across all batches in one view, sorted by readiness and then reason severity, with `HANDOFF`, `VERDICT`, and `ALL` lines plus an `OUTSIDE-BATCHES` aggregate for changed files that are not covered by any current review manifest. When pending handoffs remain it also prints `FIRST-ACTION`; once handoffs are exhausted the next command is exposed through `HANDOFF` and `--next`, and `FIRST-ACTION` disappears.
Use `./scripts/verify/run-review-batch-checks.sh --outside-batches` to print that outside-batch drift directly as one summary line plus per-file `OUTSIDE-BATCH` rows.
Use `./scripts/verify/run-review-batch-checks.sh --outside-batch-groups` to collapse that outside-batch drift into curated subsystem groups before deciding the next landing order.
Use `./scripts/verify/run-review-batch-checks.sh --outside-batch-plan` to turn those groups into ordered `OUTSIDE-LANDING-STEP` rows, and `--outside-batch-plan --show` when the plan needs per-file expansion.
Use `./scripts/verify/run-review-batch-checks.sh --outside-landing-batches` to turn those same groups into formal `LANDING-STEP` rows named `outside-<group>`, `--outside-landing-batches --name outside-frontend-runtime --show` to inspect one concrete outside landing batch, and `--outside-landing-batches --show` when they need the same `LANDING-HANDOFF`, `LANDING-FILE`, and `LANDING-ARTIFACT` detail as the primary review batches.
Use `./scripts/verify/run-review-batch-checks.sh --outside-landing-draft --name outside-frontend-runtime --write .artifacts/review-drafts/outside-frontend-runtime.md` when the first concrete outside landing batch should become a copy-pasteable commit/PR draft artifact.
Use `./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name <group>` to turn one outside-batch landing group into a reusable handoff note, and `--write <path>` to materialize it on disk.
Use `./scripts/verify/run-review-batch-checks.sh --outside-batch-memo` to collapse the matched outside-batch groups into one grouped memo, and `--write <path>` to materialize that memo on disk.
Use `./scripts/verify/run-review-batch-checks.sh --next` to print only that next command.
Use `./scripts/verify/run-review-batch-checks.sh --next --verbose` to print the same recommendation as a `NEXT` line with batch or outside-batch cause, counts, and focus file context; for curated tracked slices it recommends the next pending `--note --write .artifacts/review-notes/...` handoff path directly, then escalates to the batch memo, then to the next pending untracked-group note write, then to the grouped untracked memo once those notes are recorded, then through pending `--outside-batch-note` artifacts, then the `--outside-batch-memo`, and finally to the first concrete `--outside-landing-draft --name outside-<group> --write .artifacts/review-drafts/outside-<group>.md` command when grouped outside landing candidates exist or to `--outside-landing-batches --show` when only unmatched outside drift remains. Once `--next` converges to `echo no-pending-review-actions`, `--next --verbose` also reports `NEXT | state=complete`, and `--handoff-index`, `--landing-plan`, plus `--outside-landing-batches --show` become the follow-up views.

## Batch 1: Backend lifecycle and validation tests

Files:

- `facilitator/tests/app.test.js`
- `facilitator/tests/examService.test.js`
- `facilitator/tests/redisClient.test.js`
- `facilitator/tests/validators.test.js`

Why:

- These files protect the backend lifecycle, Redis state handling, and payload validation fixes that were called out in the audit report.
- The batch now also covers API response mapping for exam creation conflicts/failures and the async fallback from `EVALUATING` to `EVALUATION_FAILED`.

## Batch 2: CKA 2026 regressions and diagnostics tooling

Files:

- `scripts/verify/cka-003-dedicated-dns-e2e.sh`
- `scripts/verify/cka-004-cluster-dns-e2e.sh`
- `scripts/verify/cka-005-isolated-env-e2e.sh`
- `scripts/verify/run-cka-2026-regressions.sh`
- `scripts/verify/collect-cka-2026-diagnostics.sh`
- `scripts/verify/pack-cka-2026-diagnostics.sh`
- `scripts/verify/pack-review-batch-handoff.sh`
- `scripts/verify/render-review-landing-drafts.sh`
- `scripts/verify/render-review-landing-summary.sh`
- `scripts/verify/render-cka-2026-summary-markdown.sh`
- `scripts/verify/run-verify-contract-smokes.sh`
- `scripts/verify/run-review-batch-checks.sh`
- `scripts/verify/cka-2026-diagnostics-collector-smoke.sh`
- `scripts/verify/cka-2026-diagnostics-pack-smoke.sh`
- `scripts/verify/cka-2026-summary-renderer-smoke.sh`
- `scripts/verify/review-batch-handoff-pack-smoke.sh`

Why:

- These files define the core CKA 2026 regression entrypoints, diagnostics bundle, review handoff export path, landing summary/draft renderers, diagnostics summary rendering path, and review handoff export contract.
- The batch now also includes top-level contract/review runners plus synthetic collector, diagnostics pack, and review handoff pack smokes so host discovery, tarball packaging, local review entrypoints, review handoff export, landing-summary rendering, and commit-draft rendering are covered before the workflow layer.

## Batch 3: Browser smoke and verify package wiring

Files:

- `scripts/verify/browser-ui-smoke.mjs`
- `scripts/verify/browser-ui-scenario-contract-smoke.sh`
- `scripts/verify/package.json`
- `scripts/verify/README.md`

Why:

- These files are the fixture-backed browser smoke harness and its local usage contract.
- They should be reviewed together because the smoke scope, scenario inventory, and the README/package wiring need to stay aligned.

## Batch 4: Workflow wiring

Files:

- `.github/workflows/ci.yml`
- `.github/workflows/cka-2026-regressions.yml`
- `.github/workflows/review-batch-checks.yml`
- `scripts/verify/cka-2026-workflow-contract-smoke.sh`
- `scripts/verify/review-batch-workflow-contract-smoke.sh`

Why:

- These files decide where the lightweight browser smoke runs, how the self-hosted CKA 2026 regressions package diagnostics, and how the review batches are executed in GitHub Actions.
- The batch now also includes workflow contract smokes so both the self-hosted workflow and the manual review-batch workflow can be reviewed with deterministic CI checks instead of only YAML syntax passes.

## Batch 5: Audit and rollout notes

Files:

- `docs/reports/codebase-audit-2026-04-10.md`
- `docs/reports/review-inventory-2026-04-10.md`

Why:

- These files explain why the new regression and diagnostics work exists and how to review it safely.

## Batch Validation Map

- `batch-1`
  - Run `./scripts/verify/run-review-batch-checks.sh batch-1`
  - List files with `./scripts/verify/run-review-batch-checks.sh --files batch-1`
  - Split landing subsets with `./scripts/verify/run-review-batch-checks.sh --split batch-1`
  - Print curated untracked landing groups with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-1`
  - Narrow that untracked view to one landing group with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-1 --name lifecycle-api-tests`
  - Write a landing note for that untracked group with `./scripts/verify/run-review-batch-checks.sh --note batch-1 --filter untracked --name lifecycle-api-tests --write .artifacts/review-notes/batch-1-untracked-lifecycle-api-tests.txt`
  - Write the grouped untracked memo with `./scripts/verify/run-review-batch-checks.sh --memo batch-1 --filter untracked --write .artifacts/review-memos/batch-1-untracked-memo.txt`
  - Check landing readiness with `./scripts/verify/run-review-batch-checks.sh --status batch-1`
  - Covers the `facilitator` unit suite for backend lifecycle, Redis, and validation paths.
- `batch-2`
  - Run `./scripts/verify/run-review-batch-checks.sh batch-2`
  - List files with `./scripts/verify/run-review-batch-checks.sh --files batch-2`
  - Split landing subsets with `./scripts/verify/run-review-batch-checks.sh --split batch-2`
  - Focus on the tracked-modified subset with `./scripts/verify/run-review-batch-checks.sh --split batch-2 --filter tracked-modified`
  - Inspect tracked-modified diff summaries with `./scripts/verify/run-review-batch-checks.sh --diff batch-2 --filter tracked-modified`
  - Break tracked-modified changes into hunk scopes with `./scripts/verify/run-review-batch-checks.sh --hunks batch-2 --filter tracked-modified`
  - Print named landing groups with `./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified`
  - Print the full tracked landing memo with `./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter tracked-modified`
  - Write that memo to disk with `./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter tracked-modified --write .artifacts/batch-2-tracked-memo.txt`
  - Inspect recorded memo artifacts with `./scripts/verify/run-review-batch-checks.sh --memo-manifest`
  - Focus on the latest recorded memo artifact with `./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest`
  - Print the latest recorded memo artifact inline with `./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest --show`
  - Isolate the first landing group with `./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified --name bounded-wait-guards`
  - Print a reusable landing note for that group with `./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter tracked-modified --name bounded-wait-guards`
  - Write that reusable landing note to disk with `./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter tracked-modified --name bounded-wait-guards --write .artifacts/bounded-wait-guards-note.txt`
  - Inspect recorded landing-note artifacts with `./scripts/verify/run-review-batch-checks.sh --note-manifest`
  - Print the latest recorded landing-note artifact inline with `./scripts/verify/run-review-batch-checks.sh --note-manifest --latest --show`
  - Print only the detail hunks for that first landing group with `./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified --name bounded-wait-guards --detail`
  - Print curated untracked landing groups with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-2`
  - Narrow that untracked view to one landing group with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-2 --name regression-suites`
  - Write a landing note for that untracked group with `./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter untracked --name regression-suites --write .artifacts/review-notes/batch-2-untracked-regression-suites.txt`
  - Write the grouped untracked memo with `./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter untracked --write .artifacts/review-memos/batch-2-untracked-memo.txt`
  - Check landing readiness with `./scripts/verify/run-review-batch-checks.sh --status batch-2`
  - Covers the CKA 2026 runner inventory plus the diagnostics collector/pack/renderer contract smokes and the review handoff export pack smoke.
- `batch-3`
  - Run `./scripts/verify/run-review-batch-checks.sh batch-3`
  - List files with `./scripts/verify/run-review-batch-checks.sh --files batch-3`
  - Split landing subsets with `./scripts/verify/run-review-batch-checks.sh --split batch-3`
  - Print curated untracked landing groups with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-3`
  - Narrow that untracked view to one landing group with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-3 --name browser-runtime`
  - Write a landing note for that untracked group with `./scripts/verify/run-review-batch-checks.sh --note batch-3 --filter untracked --name browser-runtime --write .artifacts/review-notes/batch-3-untracked-browser-runtime.txt`
  - Write the grouped untracked memo with `./scripts/verify/run-review-batch-checks.sh --memo batch-3 --filter untracked --write .artifacts/review-memos/batch-3-untracked-memo.txt`
  - Check landing readiness with `./scripts/verify/run-review-batch-checks.sh --status batch-3`
  - Covers browser scenario inventory and `browser-ui-smoke:list`; set `RUN_FULL_BROWSER_UI_SMOKE=1` to include the full Playwright smoke.
- `batch-4`
  - Run `./scripts/verify/run-review-batch-checks.sh batch-4`
  - List files with `./scripts/verify/run-review-batch-checks.sh --files batch-4`
  - Split landing subsets with `./scripts/verify/run-review-batch-checks.sh --split batch-4`
  - Print curated untracked landing groups with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-4`
  - Narrow that untracked view to one landing group with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-4 --name default-ci`
  - Write a landing note for that untracked group with `./scripts/verify/run-review-batch-checks.sh --note batch-4 --filter untracked --name default-ci --write .artifacts/review-notes/batch-4-untracked-default-ci.txt`
  - Write the grouped untracked memo with `./scripts/verify/run-review-batch-checks.sh --memo batch-4 --filter untracked --write .artifacts/review-memos/batch-4-untracked-memo.txt`
  - Check landing readiness with `./scripts/verify/run-review-batch-checks.sh --status batch-4`
  - Covers the self-hosted workflow contract smoke, the review-batch workflow contract smoke, and YAML parsing for all workflow files.
- `batch-5`
  - Run `./scripts/verify/run-review-batch-checks.sh batch-5`
  - List files with `./scripts/verify/run-review-batch-checks.sh --files batch-5`
  - Split landing subsets with `./scripts/verify/run-review-batch-checks.sh --split batch-5`
  - Print curated untracked landing groups with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-5`
  - Narrow that untracked view to one landing group with `./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-5 --name review-docs`
  - Write a landing note for that untracked group with `./scripts/verify/run-review-batch-checks.sh --note batch-5 --filter untracked --name review-docs --write .artifacts/review-notes/batch-5-untracked-review-docs.txt`
  - Write the grouped untracked memo with `./scripts/verify/run-review-batch-checks.sh --memo batch-5 --filter untracked --write .artifacts/review-memos/batch-5-untracked-memo.txt`
  - Check landing readiness with `./scripts/verify/run-review-batch-checks.sh --status batch-5`
  - Covers the review docs by checking that the batch runner and validation map are documented consistently.

Overall landing scan:

- Run `./scripts/verify/run-review-batch-checks.sh --status-all`
- Covers all five batches with readiness-sorted summary lines, promotes higher-severity `tracked-modified` batches ahead of plain `untracked` batches, adds an `OUTSIDE-BATCHES` aggregate for changed files that are not covered by any current batch manifest, and adds `FIRST-ACTION`, `VERDICT`, and `ALL` lines, with `FIRST-ACTION` pointing to the next command to run.
- Run `./scripts/verify/run-review-batch-checks.sh --outside-batches`
- Prints the concrete tracked-modified and untracked file list that is currently outside the review-batch manifests.
- Run `./scripts/verify/run-review-batch-checks.sh --outside-batch-groups`
- Prints curated subsystem groups for that outside-batch drift so the next landing surface can be cut by subsystem instead of by raw file order.
- Run `./scripts/verify/run-review-batch-checks.sh --outside-batch-plan`
- Converts those outside-batch groups into ordered `OUTSIDE-LANDING-STEP` rows, which is the actual next-action view once current review-batch handoffs are complete.
- Run `./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name frontend-runtime`
- Generates one reusable handoff note for a matched outside-batch landing group before those changes are folded back into the next review inventory.
- Run `./scripts/verify/run-review-batch-checks.sh --outside-batch-memo`
- Collapses the matched outside-batch groups into one grouped memo once the per-group outside-batch notes are complete.
- Run `./scripts/verify/run-review-batch-checks.sh --handoff-index`
- Covers the generated review artifacts themselves with per-batch `HANDOFF-ARTIFACTS` lines, an additional `outside-batches | HANDOFF-ARTIFACTS ...` row when repo drift still exists outside the current manifests, and a final `HANDOFF-INDEX-SUMMARY` aggregate, which is the right follow-up once `--next` reports no pending actions.
- Run `./scripts/verify/run-review-batch-checks.sh --landing-plan`
- Converts that completed handoff state into commit-order `LANDING-STEP` rows with `landing-state`, `handoff`, `artifact-state`, `commit-scope`, and file counts, which is the right pre-staging view once the raw note and memo artifacts are complete.
- Run `./scripts/verify/run-review-batch-checks.sh --landing-commands`
- Converts the same ready-for-landing steps into `LANDING-COMMAND-STEP` and `LANDING-COMMAND` rows so staging and commit drafts can be copied directly into the shell.
- Run `./scripts/verify/pack-review-batch-handoff.sh`
- Exports that same completed handoff state into one directory and archive so the note/memo artifacts, handoff index, raw/expanded landing plans, `landing-commands.txt`, raw/expanded outside-batch plans, markdown landing summary, and markdown landing drafts with shell-ready command blocks can be shared without rerunning the batch progression logic.
- Run `./scripts/verify/run-review-batch-checks.sh --next`
- Prints only the next recommended review command using the same priority model; that command now escalates to the next pending `--note ... --filter tracked-modified --name <subchange> --write .artifacts/review-notes/<batch>-<subchange>.txt`, then to `--memo ... --write .artifacts/review-memos/<batch>-tracked-modified-memo.txt` once the slice-level notes are recorded, then to the next pending `--note ... --filter untracked --name <group> --write .artifacts/review-notes/<batch>-untracked-<group>.txt` once the tracked memo artifact is also recorded and curated untracked landing groups remain, then to `--memo ... --filter untracked --write .artifacts/review-memos/<batch>-untracked-memo.txt` once those untracked-group notes are complete, and only falls back to a plain `--split <batch> --filter untracked` when no curated untracked grouping exists for that batch, before finally advancing to pending `--outside-batch-note` artifacts, then `--outside-batch-memo`, and only then to the first concrete `--outside-landing-draft --name outside-<group> --write .artifacts/review-drafts/outside-<group>.md` command when grouped outside landing candidates exist or to `--outside-landing-batches --show` when only unmatched outside drift remains. When no pending review handoff remains and no outside-batch drift exists, it prints `echo no-pending-review-actions`.
- Run `./scripts/verify/run-review-batch-checks.sh --next --verbose`
- Prints the same recommendation as a `NEXT` line with enough context to explain why that batch or outside-batch scan was selected.

## Generated Artifacts

These are local outputs and should stay ignored:

- `.artifacts/`
- `.codex`
- `.playwright-mcp/`
- `test-results/`
