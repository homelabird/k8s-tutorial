# Verify Scripts

This directory contains local regression scripts for the exam stack.

## CKA 2026

- `cka-003-dedicated-dns-e2e.sh`
  - Verifies the `cka-003` shared-environment drill with PSA, dedicated `dns-lab/coredns` recovery, and ingress-nginx repair.
- `cka-004-cluster-dns-e2e.sh`
  - Verifies the `cka-004` single-question drill for cluster-wide `kube-system/coredns` recovery.
- `cka-005-isolated-env-e2e.sh`
  - Verifies the mixed-environment `cka-005` flow with shared security/ingress tasks and isolated cluster DNS recovery.
- `cka-2026-summary-renderer-smoke.sh`
  - Exercises the markdown renderer with a synthetic multi-host diagnostics summary so `Read Next`, host ordering, and pass/recovered/failed grouping do not regress back to a fixed two-host assumption.
- `cka-2026-diagnostics-collector-smoke.sh`
  - Exercises the raw diagnostics collector with fake `sudo`/`podman`/`curl` shims so host discovery, host-specific orchestration logs, question recovery timelines, and `summary.txt` generation stay correct when suites expose more than two hosts.
- `cka-2026-diagnostics-pack-smoke.sh`
  - Exercises the archive path with a synthetic diagnostics directory so `pack-cka-2026-diagnostics.sh` keeps including the expected summary, lifecycle, host log, and metadata files in a shareable tarball, then verifies that the extracted `summary.txt` still renders cleanly through the markdown summary script.
- `cka-2026-single-domain-contract-smoke.sh`
  - Verifies that the promoted single-domain `cka-006` through `cka-031` drills stay aligned across the runner inventory, facilitator `labs.json`, facilitator README listing, and promoted template docs without starting the Podman stack.
- `cka-2026-workflow-contract-smoke.sh`
  - Verifies the self-hosted workflow contract without running Podman, checking that `.github/workflows/cka-2026-regressions.yml` still exposes the expected manual inputs, timeout guard, diagnostics packing gates, summary publication, and artifact upload steps in the expected order.
- `review-batch-workflow-contract-smoke.sh`
  - Verifies the manual review-batch workflow contract without running CI, checking that `.github/workflows/review-batch-checks.yml` still exposes the expected inputs, matrix planning job, conditional install steps, and `run-review-batch-checks.sh` invocation.
- `review-batch-handoff-pack-smoke.sh`
  - Verifies the review handoff export path with synthetic note and memo manifests so `pack-review-batch-handoff.sh` keeps emitting the handoff index, raw and expanded landing plans, landing commands, markdown landing summary, status snapshots, manifest reports, copied artifacts, and shareable archive contents.
- `browser-ui-scenario-contract-smoke.sh`
  - Verifies the browser smoke inventory without launching Playwright, checking that `browser-ui-smoke.mjs --list`, `package.json`, and the README scenario list all stay aligned.
- `browser-ui-smoke.mjs`
  - Runs a browser-level smoke against fixture-backed `index`, `exam`, `results`, and `answers` flows, covering the active-session warning modal refresh path, the dashboard `View Results` redirect, the terminal/remote-desktop toggle flow, the exam terminate-session modal and redirect, completed-exam review-mode navigation to results, result-page re-evaluation polling, the failed-evaluation error branch plus `Retry` recovery, feedback modal submit success/failure, and the `Current Exam` / `View Answers` / `Terminate Session` actions without needing the full Podman stack.
- `run-cka-2026-regressions.sh`
  - Runs the selected CKA 2026 regressions sequentially.
- `run-cka-2026-single-domain-drills.sh`
  - Runs the promoted single-domain `cka-006` through `cka-031` drills sequentially, resetting the local Podman stack and solving each drill through the shared jumphost before evaluation.
- `run-verify-contract-smokes.sh`
  - Runs the lightweight diagnostics/workflow/browser/review-handoff contract smokes sequentially, including both GitHub workflow contract checks, with `--list` support for quick inventory checks.
- `run-review-batch-checks.sh`
  - Runs the review-inventory batches sequentially so landing checks can follow the same `batch-1..batch-5` grouping used in the audit notes.
- `collect-cka-2026-diagnostics.sh`
  - Captures Podman state, facilitator and runtime logs, current exam metadata, dynamically discovered host orchestration summaries, and a facilitator lifecycle summary into an artifact-friendly directory.
- `pack-cka-2026-diagnostics.sh`
  - Collects the diagnostics bundle and compresses it into a `.tar.gz` archive for sharing or attachment.
- `pack-review-batch-handoff.sh`
  - Collects the completed review handoff state into one export directory and `.tar.gz`, including the handoff index, raw and expanded landing plans, landing commands, outside-batch landing candidates, formal outside landing-batch views, markdown landing summary, markdown landing drafts, status snapshot, next-command snapshot, manifest reports, raw manifests, and generated note/memo artifacts.
- `render-review-landing-summary.sh`
  - Converts `landing-plan --show` output into a markdown handoff summary so the commit/PR landing order is readable without scanning the raw `LANDING-*` rows, and when `landing-commands.txt` is supplied, surfaces the first actionable stage/commit pair directly in the summary or falls back to the next pending handoff command.
- `render-review-landing-drafts.sh`
  - Converts `landing-plan --show` output into per-batch commit and PR draft sections and, when `landing-commands.txt` is supplied, appends shell-ready stage/commit blocks so the export bundle can be used directly as a landing memo.
- `render-cka-2026-summary-markdown.sh`
  - Converts `summary.txt` into a GitHub-friendly markdown summary with a verdict banner, a compact `Snapshot`, collapsed passing sections, verdict-aware `Read Next`, and a nested `Additional context` block that hides the default local base URL, compresses extra log references into a short archive hint, only shows the latest facilitator event on failed runs, and follows the discovered host list from the bundle.

## Usage

Run all CKA 2026 regressions:

```bash
./scripts/verify/run-cka-2026-regressions.sh
```

Run the promoted single-domain CKA 2026 drills:

```bash
./scripts/verify/run-cka-2026-single-domain-drills.sh
```

Run only one single-domain drill:

```bash
./scripts/verify/run-cka-2026-single-domain-drills.sh cka-031
```

List the available single-domain drill suites:

```bash
./scripts/verify/run-cka-2026-single-domain-drills.sh --list
```

Run only one suite:

```bash
./scripts/verify/run-cka-2026-regressions.sh cka-004
```

List available suites:

```bash
./scripts/verify/run-cka-2026-regressions.sh --list
```

Run all lightweight contract smokes:

```bash
./scripts/verify/run-verify-contract-smokes.sh
```

List the available contract smokes:

```bash
./scripts/verify/run-verify-contract-smokes.sh --list
```

Describe the contract-smoke coverage:

```bash
./scripts/verify/run-verify-contract-smokes.sh --describe
```

Run all review-inventory batch checks:

```bash
./scripts/verify/run-review-batch-checks.sh
```

List the available review batches:

```bash
./scripts/verify/run-review-batch-checks.sh --list
```

Describe the review-batch coverage:

```bash
./scripts/verify/run-review-batch-checks.sh --describe
```

Print the file manifest for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --files batch-4
```

Print landing subsets for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --split batch-2
```

Print curated untracked landing groups for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-1
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-1 --name lifecycle-api-tests
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-2
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-2 --name regression-suites
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-3
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-3 --name browser-runtime
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-4
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-4 --name default-ci
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-5
./scripts/verify/run-review-batch-checks.sh --untracked-groups batch-5 --name review-docs
```

Write a structured landing note for one curated untracked group:

```bash
./scripts/verify/run-review-batch-checks.sh --note batch-1 --filter untracked --name lifecycle-api-tests --write .artifacts/review-notes/batch-1-untracked-lifecycle-api-tests.txt
./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter untracked --name regression-suites --write .artifacts/review-notes/batch-2-untracked-regression-suites.txt
./scripts/verify/run-review-batch-checks.sh --note batch-3 --filter untracked --name browser-runtime --write .artifacts/review-notes/batch-3-untracked-browser-runtime.txt
./scripts/verify/run-review-batch-checks.sh --note batch-4 --filter untracked --name default-ci --write .artifacts/review-notes/batch-4-untracked-default-ci.txt
./scripts/verify/run-review-batch-checks.sh --note batch-5 --filter untracked --name review-docs --write .artifacts/review-notes/batch-5-untracked-review-docs.txt
```

Print tracked-modified diff summaries for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --diff batch-2 --filter tracked-modified
```

Print tracked-modified hunk scopes for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --hunks batch-2 --filter tracked-modified
```

Print named tracked-modified landing groups for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified
```

Print one named tracked-modified landing group:

```bash
./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified --name bounded-wait-guards
```

Print a structured landing note for one named tracked-modified group:

```bash
./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter tracked-modified --name bounded-wait-guards
```

Print a structured landing memo for every named tracked-modified group in one batch:

```bash
./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter tracked-modified
```

Write one named landing note to a file:

```bash
./scripts/verify/run-review-batch-checks.sh --note batch-2 --filter tracked-modified --name bounded-wait-guards --write .artifacts/bounded-wait-guards-note.txt
```

Inspect the recorded note artifacts:

```bash
./scripts/verify/run-review-batch-checks.sh --note-manifest
./scripts/verify/run-review-batch-checks.sh --note-manifest --latest
./scripts/verify/run-review-batch-checks.sh --note-manifest --latest --show
```

Write that landing memo to a file:

```bash
./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter tracked-modified --write .artifacts/batch-2-tracked-memo.txt
```

Write an untracked-group landing memo after the individual group notes are recorded:

```bash
./scripts/verify/run-review-batch-checks.sh --memo batch-1 --filter untracked --write .artifacts/review-memos/batch-1-untracked-memo.txt
./scripts/verify/run-review-batch-checks.sh --memo batch-2 --filter untracked --write .artifacts/review-memos/batch-2-untracked-memo.txt
./scripts/verify/run-review-batch-checks.sh --memo batch-3 --filter untracked --write .artifacts/review-memos/batch-3-untracked-memo.txt
./scripts/verify/run-review-batch-checks.sh --memo batch-4 --filter untracked --write .artifacts/review-memos/batch-4-untracked-memo.txt
./scripts/verify/run-review-batch-checks.sh --memo batch-5 --filter untracked --write .artifacts/review-memos/batch-5-untracked-memo.txt
```

Inspect the recorded memo artifacts:

```bash
./scripts/verify/run-review-batch-checks.sh --memo-manifest
./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest
./scripts/verify/run-review-batch-checks.sh --memo-manifest --latest --show
```

Print the batch-by-batch handoff artifact index:

```bash
./scripts/verify/run-review-batch-checks.sh --handoff-index
./scripts/verify/run-review-batch-checks.sh --handoff-index batch-2 --show
```

Print the landing plan in commit order:

```bash
./scripts/verify/run-review-batch-checks.sh --landing-plan
./scripts/verify/run-review-batch-checks.sh --landing-plan batch-2 --show
```

Print copy-pasteable landing commands from that plan:

```bash
./scripts/verify/run-review-batch-checks.sh --landing-commands
./scripts/verify/run-review-batch-checks.sh --landing-commands batch-2 outside-frontend-runtime
```

Render a markdown landing summary from the expanded landing plan:

```bash
./scripts/verify/run-review-batch-checks.sh --landing-plan --show > .artifacts/review-handoff/landing-plan-expanded.txt
./scripts/verify/run-review-batch-checks.sh --outside-landing-batches --show > .artifacts/review-handoff/outside-landing-batches-expanded.txt
./scripts/verify/run-review-batch-checks.sh --landing-commands > .artifacts/review-handoff/landing-commands.txt
./scripts/verify/render-review-landing-summary.sh .artifacts/review-handoff/landing-plan-expanded.txt .artifacts/review-handoff/outside-landing-batches-expanded.txt .artifacts/review-handoff/landing-commands.txt > .artifacts/review-handoff/landing-summary.md
./scripts/verify/render-review-landing-drafts.sh .artifacts/review-handoff/landing-plan-expanded.txt .artifacts/review-handoff/outside-landing-batches-expanded.txt .artifacts/review-handoff/landing-commands.txt > .artifacts/review-handoff/landing-drafts.md
```

Pack the generated review handoff artifacts:

```bash
./scripts/verify/pack-review-batch-handoff.sh
./scripts/verify/pack-review-batch-handoff.sh .artifacts/review-handoff .artifacts/review-handoff.tar.gz
```

Print the hunk-level detail for one named tracked-modified landing group:

```bash
./scripts/verify/run-review-batch-checks.sh --subchanges batch-2 --filter tracked-modified --name bounded-wait-guards --detail
```

Print landing readiness for one review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --status batch-4
```

Print compact landing readiness for every review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --status-all
```

Print changed files that are not covered by any current review batch:

```bash
./scripts/verify/run-review-batch-checks.sh --outside-batches
```

Print curated landing groups for those outside-batch changes:

```bash
./scripts/verify/run-review-batch-checks.sh --outside-batch-groups
./scripts/verify/run-review-batch-checks.sh --outside-batch-groups --name facilitator-runtime
```

Print the ordered landing plan for those outside-batch changes:

```bash
./scripts/verify/run-review-batch-checks.sh --outside-batch-plan
./scripts/verify/run-review-batch-checks.sh --outside-batch-plan --show
./scripts/verify/run-review-batch-checks.sh --outside-landing-batches
./scripts/verify/run-review-batch-checks.sh --outside-landing-batches --show
```

Print or write one outside-batch handoff note and the grouped memo:

```bash
./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name frontend-runtime
./scripts/verify/run-review-batch-checks.sh --outside-batch-note --name frontend-runtime --write .artifacts/review-notes/outside-batches-frontend-runtime.txt
./scripts/verify/run-review-batch-checks.sh --outside-batch-memo
./scripts/verify/run-review-batch-checks.sh --outside-batch-memo --write .artifacts/review-memos/outside-batches-outside-batch-memo.txt
```

Print only the next recommended review command:

```bash
./scripts/verify/run-review-batch-checks.sh --next
```

Print the next command with reason and focus details:

```bash
./scripts/verify/run-review-batch-checks.sh --next --verbose
```

Collect a local diagnostics bundle:

```bash
./scripts/verify/collect-cka-2026-diagnostics.sh
```

Collect and pack a local diagnostics bundle:

```bash
./scripts/verify/pack-cka-2026-diagnostics.sh
```

Render a collected `summary.txt` as markdown:

```bash
./scripts/verify/render-cka-2026-summary-markdown.sh .artifacts/cka-2026/summary.txt
```

Run the multi-host renderer smoke:

```bash
./scripts/verify/cka-2026-summary-renderer-smoke.sh
```

Run the multi-host diagnostics collector smoke:

```bash
./scripts/verify/cka-2026-diagnostics-collector-smoke.sh
```

Run the diagnostics archive pack smoke:

```bash
./scripts/verify/cka-2026-diagnostics-pack-smoke.sh
```

Run the self-hosted workflow contract smoke:

```bash
./scripts/verify/cka-2026-workflow-contract-smoke.sh
```

Run the review-batch workflow contract smoke:

```bash
./scripts/verify/review-batch-workflow-contract-smoke.sh
```

Run the browser smoke scenario contract:

```bash
./scripts/verify/browser-ui-scenario-contract-smoke.sh
```

Install the browser smoke dependency once:

```bash
npm --prefix scripts/verify install
```

Run the browser-level UI smoke:

```bash
(cd scripts/verify && npm run browser-ui-smoke)
```

List the browser smoke scenarios without launching Playwright:

```bash
(cd scripts/verify && npm run browser-ui-smoke:list)
```

## Notes

- These scripts assume a local Podman-based stack and restart the stack as part of the flow.
- Each script creates an exam, waits for `READY`, applies a known-good solution, runs evaluation, and verifies cleanup.
- `run-cka-2026-regressions.sh --list` is safe to run in lightweight CI because it only validates the entrypoint wiring and does not restart the stack.
- `run-verify-contract-smokes.sh` runs only the synthetic contract checks and is safe to use during review without starting the full Podman exam stack.
- `run-verify-contract-smokes.sh --describe` prints the smoke name, backing script, and the coverage area each smoke is meant to protect, including the manual review-batch workflow contract and the review handoff export contract.
- `run-review-batch-checks.sh` maps directly to the `review-inventory` batches. By default it keeps batch-3 lightweight; set `RUN_FULL_BROWSER_UI_SMOKE=1` if that batch should also run the full Playwright browser smoke.
- `run-review-batch-checks.sh --files <batch>` prints the landing manifest for that batch so review prep can use the same file grouping as the audit inventory.
- `run-review-batch-checks.sh --split <batch>` prints per-state subset counts plus file lines for `tracked-modified`, `untracked`, and `missing`, so a mixed landing batch can be split before staging or review.
- `run-review-batch-checks.sh --split <batch> --filter <state>` narrows that view to one state such as `tracked-modified` or `untracked`, which is what `--next` recommends for `missing` and `untracked` mixed batches.
- `run-review-batch-checks.sh --untracked-groups <batch>` prints curated landing groupings for untracked files when a batch has many new scripts that should not be reviewed as one undifferentiated list.
- `run-review-batch-checks.sh --untracked-groups <batch> --name <group>` narrows that view to one untracked landing group such as `lifecycle-api-tests`, `regression-suites`, `browser-runtime`, `default-ci`, or `review-docs`.
- `run-review-batch-checks.sh --diff <batch>` prints structured `git diff --numstat` summaries for the `tracked-modified` subset, and `--diff <batch> --filter tracked-modified` makes that target explicit for review notes or handoff.
- `run-review-batch-checks.sh --hunks <batch> --filter tracked-modified` prints `@@` hunk ranges and scope labels for the modified tracked subset, which is useful when one file needs to be split into smaller landing-sized changes.
- `run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified` prints curated landing-sized review groups for tracked files when a known subchange map exists. For `batch-2`, the current map breaks `scripts/verify/cka-005-isolated-env-e2e.sh` into bounded waits, stack reset, isolated DNS precheck, and post-fix retry groups.
- `run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified --name <subchange>` narrows that curated view to one landing group, such as `bounded-wait-guards`, so review or staging can start from a single named slice.
- `run-review-batch-checks.sh --note <batch> --filter tracked-modified --name <subchange>` prints a structured landing note for that named slice, including the file, line range, focus, and review bullets that can be reused in a PR or handoff note.
- `run-review-batch-checks.sh --note <batch> --filter untracked --name <group>` prints a structured landing note for one curated untracked group, including the grouped files and review bullets that explain why that cluster should land together.
- `run-review-batch-checks.sh --memo <batch> --filter tracked-modified` prints the same note data grouped for every named tracked subchange in that batch, which is useful for a full landing memo or PR summary once the slice-level review is done.
- `run-review-batch-checks.sh --memo <batch> --filter untracked` prints the same memo structure across every curated untracked group still present in the batch, which is useful once the individual untracked-group notes are already recorded.
- `run-review-batch-checks.sh --note <batch> --filter tracked-modified --name <subchange> --write <path>` saves one named landing note to disk and prints `NOTE-WRITE` plus `NOTE-MANIFEST` lines, which is useful when the next review hop should hand off only the current slice.
- `run-review-batch-checks.sh --note <batch> --filter untracked --name <group> --write <path>` does the same for curated untracked groups after the tracked review memo is already recorded.
- `run-review-batch-checks.sh --note-manifest` prints the note write log from `NOTE_MANIFEST_PATH` as `NOTE-MANIFEST` plus `NOTE-ENTRY` lines, which makes it easy to confirm which slice-level handoff files were generated and whether the recorded output paths still exist.
- `run-review-batch-checks.sh --note-manifest --latest` narrows that view to the newest recorded note artifact and prints it as a `NOTE-LATEST` line.
- `run-review-batch-checks.sh --note-manifest --latest --show` prints the latest recorded note artifact together with a `NOTE-SHOW` header and `NOTE-CONTENT` lines, which is useful when the current slice-level handoff note should be re-read without opening the file manually.
- `run-review-batch-checks.sh --memo <batch> --filter tracked-modified --write <path>` saves that memo to disk and prints a `MEMO-WRITE` line with the target path and byte count, so the generated handoff note can be referenced from another script or copied into a review artifact.
- `run-review-batch-checks.sh --memo <batch> --filter untracked --write <path>` does the same for the grouped untracked landing memo after the untracked-group notes are complete.
- `run-review-batch-checks.sh --memo-manifest` prints the memo write log from `MEMO_MANIFEST_PATH` as `MEMO-MANIFEST` plus `MEMO-ENTRY` lines, which makes it easy to confirm which handoff files were generated and whether the recorded output paths still exist.
- `run-review-batch-checks.sh --memo-manifest --latest` narrows that view to the latest recorded handoff artifact and prints it as a `MEMO-LATEST` line for quick follow-up.
- `run-review-batch-checks.sh --memo-manifest --latest --show` prints the latest recorded memo artifact together with a `MEMO-SHOW` header and `MEMO-CONTENT` lines, which is useful when the handoff note should be re-read without opening the file manually.
- `run-review-batch-checks.sh --handoff-index` converts the raw note/memo manifests into `batch-N | HANDOFF-ARTIFACTS` lines, showing `artifact-state`, actual-vs-expected note and memo counts, and the latest artifact path per batch; when repo drift still sits outside the current review manifests it also emits `outside-batches | HANDOFF-ARTIFACTS ...` so the handoff summary does not imply a false fully-landed state.
- `run-review-batch-checks.sh --handoff-index --show` expands selected batches into `NOTE-ARTIFACT` and `MEMO-ARTIFACT` rows so the recorded handoff files can be reviewed without manually cross-referencing both manifests.
- `run-review-batch-checks.sh --landing-plan` collapses the current handoff and git-state view into one commit-order landing plan with `LANDING-STEP` rows per batch and a `LANDING-PLAN-SUMMARY` aggregate. `--landing-plan --show` expands each batch into `LANDING-HANDOFF`, `LANDING-FILE`, and latest `LANDING-ARTIFACT` rows.
- `run-review-batch-checks.sh --landing-commands` turns the ready-for-landing batch and outside-batch rows into `LANDING-COMMAND-STEP` plus `LANDING-COMMAND` lines with copy-pasteable `git add -- ...` and `git commit -m ...` drafts; pass explicit targets such as `batch-2` or `outside-frontend-runtime` to narrow that command sheet.
- `render-review-landing-summary.sh` turns `landing-plan --show` output into `landing-summary.md`; when `outside-landing-batches --show` is passed as a second argument it also appends an `Outside Landing Order` section so the markdown landing checklist reflects formal landing rows for repo drift outside the current review manifests, and when `landing-commands.txt` is passed as a third argument it surfaces either the first actionable stage/commit command block or the next pending handoff command directly in the summary entrypoint.
- `render-review-landing-drafts.sh` turns `landing-plan --show` output into `landing-drafts.md`; when `outside-landing-batches --show` is passed as a second argument it also appends `Outside Landing Drafts` sections with commit/PR text for each outside landing group, and when `landing-commands.txt` is passed as a third argument it adds shell-ready `git add` / `git commit` blocks under each batch or outside landing group.
- `pack-review-batch-handoff.sh` snapshots the current review handoff surface into one export directory and `.tar.gz`, including `handoff-index.txt`, `landing-plan.txt`, `landing-plan-expanded.txt`, `landing-commands.txt`, `outside-batch-plan.txt`, `outside-batch-plan-expanded.txt`, `outside-landing-batches.txt`, `outside-landing-batches-expanded.txt`, `landing-summary.md`, `landing-drafts.md`, `status-all.txt`, `next.txt`, `next-verbose.txt`, manifest reports, raw manifest copies, and the generated note/memo artifacts.
- `run-review-batch-checks.sh --subchanges <batch> --filter tracked-modified --name <subchange> --detail` prints only the diff hunk scopes that intersect that named slice, which is the fastest way to read the current bounded-wait or DNS-hardening change without scanning the whole file.
- `run-review-batch-checks.sh --status <batch>` prints `readiness`, a short `reason`, `total/existing/missing/clean/tracked-modified/untracked` counts, plus explicit `HANDOFF`, `STATE`, and `MISSING` lines so landing readiness and review-artifact completion can be checked before preparing a commit or PR.
- `run-review-batch-checks.sh --status-all` prints readiness-sorted batch summaries, puts `tracked-modified-present` batches ahead of `untracked-present` batches inside the same readiness level, adds an `OUTSIDE-BATCHES` aggregate for changed files that are not covered by any current review manifest, and emits aggregate `HANDOFF`, `VERDICT`, and `ALL` lines; when a real next handoff command still exists, `FIRST-ACTION` includes the copy-pasteable highest-priority step, and once every handoff artifact is complete the summary omits `FIRST-ACTION` even if landing work still remains.
- `run-review-batch-checks.sh --outside-batches` prints that outside-batch drift directly as one summary line plus per-file `OUTSIDE-BATCH` rows, which is the right follow-up when landed review batches are clean but the repo still has tracked-modified or untracked work that is not yet assigned to a landing batch.
- `run-review-batch-checks.sh --outside-batch-groups` collapses that outside-batch drift into curated subsystem groups such as `frontend-runtime`, `facilitator-runtime`, `exam-content`, `infra-runtime`, and `rollout-docs`, which is the fastest grouping view before deciding the actual next landing order.
- `run-review-batch-checks.sh --outside-batch-plan` turns those groups into ordered `OUTSIDE-LANDING-STEP` rows with `focus`, `file-count`, and tracked/untracked counts; `--outside-batch-plan --show` expands each step into `OUTSIDE-LANDING-FILE` rows. This is now the preferred next action once the current review batches are clean but repo drift still exists outside the manifests.
- `run-review-batch-checks.sh --outside-landing-batches` turns those same outside groups into formal `LANDING-STEP` rows named `outside-<group>`, `--outside-landing-batches --name outside-frontend-runtime --show` narrows that view to one concrete landing batch, and `--outside-landing-batches --show` expands every matched outside batch into `LANDING-HANDOFF`, `LANDING-FILE`, and `LANDING-ARTIFACT` rows that can be exported or rendered like normal landing batches.
- `run-review-batch-checks.sh --outside-landing-draft --name outside-frontend-runtime` turns one formal outside landing batch into a commit/PR draft, and `--write .artifacts/review-drafts/outside-frontend-runtime.md` materializes that draft on disk.
- `run-review-batch-checks.sh --outside-batch-note --name <group>` turns one matched outside-batch group into a reusable handoff note, and `--write <path>` materializes that note as an artifact under `.artifacts/review-notes/...`.
- `run-review-batch-checks.sh --outside-batch-memo` collapses all matched outside-batch groups into one grouped memo, and `--write <path>` materializes that memo under `.artifacts/review-memos/...`.
- `run-review-batch-checks.sh --next` prints only that copy-pasteable next command, using the same priority rules as `--status-all`; it points at a filtered `--split` for `missing` drift, at `--note ... --filter tracked-modified --name <next-pending-subchange> --write .artifacts/review-notes/<batch>-<subchange>.txt` when modified tracked files have a curated landing map, then at `--memo ... --write .artifacts/review-memos/<batch>-tracked-modified-memo.txt`, then at the next pending `--note ... --filter untracked --name <group> --write .artifacts/review-notes/<batch>-untracked-<group>.txt` when the batch still has curated untracked groups to land, then at `--memo ... --filter untracked --write .artifacts/review-memos/<batch>-untracked-memo.txt`, and once the review batches are exhausted it now advances through pending `--outside-batch-note ... --write .artifacts/review-notes/outside-batches-<group>.txt` artifacts, then the grouped `--outside-batch-memo --write .artifacts/review-memos/outside-batches-outside-batch-memo.txt`, before escalating to the first concrete `--outside-landing-draft --name outside-<group> --write .artifacts/review-drafts/outside-<group>.md` command when a grouped landing target exists or to `--outside-landing-batches --show` when only unmatched outside drift remains. It only prints `echo no-pending-review-actions` when both the review batches and outside-batch scan are clean.
- `run-review-batch-checks.sh --next --verbose` prints the same recommendation with the selected batch or outside-batch scan, reason, counts, and focus file so the operator can see why that command was chosen; for curated tracked and curated untracked batches it walks forward through pending note artifacts, then the relevant batch-level memo artifact, and only then advances to outside-batch notes, the outside-batch grouped memo, and finally the outside-batch landing plan. Once no further handoff action remains, it prints `NEXT | state=complete | next=echo no-pending-review-actions`; use `--handoff-index`, `--landing-plan`, or `--outside-landing-batches --show` to follow the remaining landing order.
- `NOTE_MANIFEST_PATH` can be overridden when note handoff artifacts should be recorded somewhere other than `.artifacts/review-batch-note-manifest.txt`.
- `BASE_URL` can be overridden if the web stack is exposed on a non-default port.
- `SUITE_TIMEOUT_SECONDS` controls the per-suite timeout wrapper in the aggregated runner. Set it to `0` to disable the timeout.
- `SMOKE_TIMEOUT_SECONDS` controls the per-smoke timeout wrapper in the contract-smoke runner. Set it to `0` to disable the timeout.
- `BATCH_TIMEOUT_SECONDS` controls the per-batch timeout wrapper in the review-batch runner. Set it to `0` to disable the timeout.
- `collect-cka-2026-diagnostics.sh` accepts an output directory as its first argument and also honors `BASE_URL`.
- `pack-cka-2026-diagnostics.sh` accepts an output directory first and an archive path second. Set `SKIP_COLLECT=1` to pack an existing diagnostics directory without recollecting.
- Start with `summary.txt` in the diagnostics bundle. It includes the current exam state, suite ID, recent exam ID, evaluation attempts, score history, an overall health verdict, question-level pass/fail totals with the last failure and failure-to-recovery timeline per question, dynamically discovered host-level prepare/cleanup plus last failed verification, and a recommended file read order for deeper triage.
- `cka-2026-diagnostics-collector-smoke.sh` is the lightweight contract test for the raw collector path. It does not start Podman; it feeds the collector a synthetic facilitator log through fake `sudo`, `podman`, and `curl` wrappers so host discovery and `summary.txt` generation can be validated in normal CI.
- `cka-2026-diagnostics-pack-smoke.sh` is the lightweight contract test for the archive path. It feeds `pack-cka-2026-diagnostics.sh` a synthetic diagnostics directory with `SKIP_COLLECT=1`, checks that the resulting tarball preserves the expected triage files, and then renders the extracted `summary.txt` back through the markdown renderer.
- `cka-2026-workflow-contract-smoke.sh` is the lightweight contract test for `.github/workflows/cka-2026-regressions.yml`. It does not touch a self-hosted runner; it checks that the manual inputs, timeout validation, diagnostics packing gates, job-summary publishing, and artifact uploads do not silently drift.
- `review-batch-workflow-contract-smoke.sh` is the lightweight contract test for `.github/workflows/review-batch-checks.yml`. It checks the manual inputs, matrix planning job, conditional dependency installation, and `run-review-batch-checks.sh` invocation without needing to trigger GitHub Actions.
- `browser-ui-scenario-contract-smoke.sh` is the lightweight contract test for the browser fixture inventory. It checks the exact scenario order exposed by `browser-ui-smoke.mjs --list`, confirms that list mode still avoids browser startup, and verifies that the README documents the same scenario sequence.
- `render-cka-2026-summary-markdown.sh` turns that same `summary.txt` into markdown with a verdict banner, a compact `Snapshot`, collapsed passing sections, verdict-aware `Read Next`, and a nested `Additional context` block that suppresses the default local base URL, compresses extra log references into a small archive hint, only exposes the latest facilitator event by default when the verdict is `FAILED`, and follows the host list discovered in the diagnostics bundle instead of assuming a fixed two-host layout.
- `browser-ui-smoke.mjs` uses a tiny fixture server plus Playwright to verify that the index-page active-session modal refreshes with the latest exam name across repeated openings, that the dashboard `View Results` button still redirects when a current exam is already evaluated, that the exam page can switch between remote desktop and terminal views without regressing the toggle text or panel visibility, that exam-session termination still goes through its modal and returns to the dashboard, that completed-exam review mode still reaches the results page, and that the results page still handles both re-evaluation polling, `EVALUATION_FAILED` errors, the `Retry` recovery path, and feedback submission success/failure correctly while keeping the `Current Exam`, `View Answers`, and `Terminate Session` actions wired up.
- The browser smoke currently runs these fixture-backed scenarios in order:
  - `index-active-exam-warning`
  - `index-view-results-redirect`
  - `exam-terminal-toggle`
  - `exam-terminate-session`
  - `exam-review-mode-results`
  - `results-re-evaluation`
  - `results-evaluation-failed`
  - `results-retry-recovery`
  - `results-actions`
  - `results-feedback`
- The suite scripts now fail with explicit timeout errors for stack readiness, exam status transitions, and cleanup instead of waiting forever.

## GitHub Actions

- `.github/workflows/ci.yml` keeps the lightweight smoke check that validates the aggregated runner entrypoint.
- The same CI workflow also runs `run-verify-contract-smokes.sh --list` and `--describe` so the top-level contract-smoke runner wiring and its documented coverage labels stay aligned with the individual scripts, including the review-batch workflow contract entry and the review handoff export contract entry.
- The same CI workflow also runs `run-review-batch-checks.sh --list` and `--describe` so the review-inventory batch runner stays aligned with the documented `batch-1..batch-5` landing plan.
- The same CI workflow also checks `run-review-batch-checks.sh --files batch-4` so the workflow batch manifest does not drift away from the documented landing grouping.
- The same CI workflow also checks `run-review-batch-checks.sh --split batch-4` so the per-state landing-subset view keeps its stable subset/count layout.
- The same CI workflow also checks `run-review-batch-checks.sh --status batch-4` so the workflow landing manifest stays present and complete, including the `readiness` and `reason` fields.
- The same CI workflow also checks `run-review-batch-checks.sh --status-all` so the readiness-sorted aggregate summary keeps its `HANDOFF` / `VERDICT` / `ALL` field layout, `reason` field, batch count contract, and command-style `next=` field, while still accepting `FIRST-ACTION` only when pending handoffs remain.
- The same CI workflow also checks `run-review-batch-checks.sh --outside-batches` with a synthetic untracked file so the runner keeps surfacing manifest drift outside the current landing batches instead of reporting a false clean handoff.
- The same CI workflow also checks `run-review-batch-checks.sh --handoff-index` so the batch-level handoff artifact inventory keeps its `HANDOFF-INDEX`, `HANDOFF-ARTIFACTS`, and `HANDOFF-INDEX-SUMMARY` layout.
- The same CI workflow also checks `run-review-batch-checks.sh --next` so the minimal next-command entrypoint stays aligned with `FIRST-ACTION`.
- The same CI workflow also checks `run-review-batch-checks.sh --next --verbose` so the detailed next-step summary keeps its `NEXT` line shape and focus-file field.
- The same CI workflow also runs `cka-2026-diagnostics-collector-smoke.sh` so multi-host host discovery and raw `summary.txt` generation do not silently regress before markdown rendering is involved.
- The same CI workflow also runs `cka-2026-diagnostics-pack-smoke.sh` so the packed archive path cannot silently drop key triage files.
- The same CI workflow also runs `cka-2026-summary-renderer-smoke.sh` so multi-host diagnostics summaries do not silently regress back to a fixed host layout.
- The same CI workflow also runs `cka-2026-workflow-contract-smoke.sh` so the self-hosted regression workflow cannot silently lose its manual inputs, timeout guard, or diagnostics publication steps.
- The same CI workflow also runs `review-batch-workflow-contract-smoke.sh` so the manual review-batch workflow cannot silently drift away from the local batch runner.
- The same CI workflow also runs `browser-ui-scenario-contract-smoke.sh` so the documented browser smoke inventory does not drift before the heavier Playwright job runs.
- The same CI workflow also runs the fixture-backed browser UI smoke so index active-session warnings and exam terminal toggling stay covered without requiring the full Podman stack.
- `.github/workflows/cka-2026-regressions.yml` runs the real CKA 2026 regressions on a `self-hosted` Linux runner.
- `.github/workflows/review-batch-checks.yml` runs the review-inventory batches on `ubuntu-latest` with a matrix derived from the selected `batch-1..batch-5` inputs.
- The full regression workflow assumes rootful Podman and privileged containers are available on the runner, matching the local Podman requirements documented for CK-X.
- The manual workflow accepts optional `suites` and `suite_timeout_seconds` inputs, plus `pack_success_diagnostics` when a successful run should upload a packed diagnostics bundle too.
- Each workflow run writes the aggregated regression output to an artifact-friendly log file. Diagnostics are always packed and uploaded on failure, and can also be packed on success for manual dispatch runs when `pack_success_diagnostics=true`.
- When diagnostics are packed, the workflow uploads `summary.txt` as a separate artifact too so the top-level triage view is available without downloading the full tarball.
- The same packed `summary.txt` is also rendered into markdown and appended to the GitHub job summary so the latest exam state and failure/recovery timeline are visible directly in the Actions UI.
- The same workflow also has a nightly `schedule` trigger so the full regression set can run without bloating the default PR CI path.
