# Dry-run migration harness

`scripts/dry-run-migration.sh` previews what
`scripts/migrate-v10-to-v11.sh` (or any future N->N+1 migrator) would
do to a target repo, **without ever modifying the original**. The
target is opened only via `git clone` (URL) or read-only copy (local
path); all migration work happens in a disposable directory under
`/tmp` / `$TMPDIR` that is removed on every exit path.

Audience: any org maintaining a v10 (or future-vN) pack-managed client.
Nothing about Optiquity is hardcoded; you supply the target at
invocation. For the canonical flag listing, run
`scripts/dry-run-migration.sh --help` — this doc covers when to use
it, how to read the output, and how to wire it into a release gate.

---

## 1. Input contract

The harness produces meaningful output only if the target satisfies:

- **Pack version detectable.** Trinity context file (`CLAUDE.md` /
  `AGENTS.md` / `GEMINI.md`) and at least one of `.claude/`,
  `.codex/`, `.agents/` at the target root, so detection returns a
  concrete version (`v10`, ...) rather than `unknown`. (A departing v10
  target's `.gemini/` tree is still recognized as a legacy-READ
  detection marker, so a v10 project migrates cleanly.)
- **Clean working tree.** No uncommitted changes. URL mode is clean by
  construction; for local-path mode, `git status` first.
- **No in-flight prior migration.** No `.pack-migrate-vN-to-vM/` state
  dir and no `.pack-migrate-vN-to-vM-backup/` at the target root.
  Finish reconciling or roll back (`supporting-docs/MIGRATION-v10-to-v11.md` §
  Rollback) before dry-running.
- **No unresolved merge conflicts.** Conflict markers in tracked files
  produce noisy and misleading dry-run diffs.
- **On the branch you intend to migrate.** Results reflect HEAD at
  clone time. URL mode clones the default branch; for a non-default
  branch, prepare a local clone on that branch and use local-path mode.

A target outside this contract is not refused — the harness still runs
and renders a report — but the diff may not predict what a real
migration would do.

---

## 2. Usage

Three invocation modes, all the same script:

**Mode 1 — synthetic fixture (CI smoke):**

```sh
scripts/dry-run-migration.sh test-fixtures/v10-realistic-ot
```

No network. Build the fixture first if absent: `bash
test-fixtures/build.sh --name v10-realistic-ot --clean`.

**Mode 2 — your own v10 client (local path or URL):**

```sh
scripts/dry-run-migration.sh /path/to/your/v10/clone
scripts/dry-run-migration.sh https://github.com/your-org/your-v10-repo
scripts/dry-run-migration.sh git@github.com:your-org/your-v10-repo.git
```

Use `--report-out <path>` to keep the rendered report past cleanup:

```sh
scripts/dry-run-migration.sh /path/to/clone --report-out ./dry-run.md
```

**Mode 3 — release gate (URL via CI secret):**

```sh
scripts/dry-run-migration.sh "$TARGET_URL" --report-out "$CI_ARTIFACTS/dry-run.md"
```

`$TARGET_URL` is supplied at invocation time from your CI's secret
store. See § 4.

---

## 3. Reading the output

The report (Markdown) has: target input, detected version, selected
adapter, adapter exit code, diff file-list, adapter stdout tail,
adapter stderr tail. The diff section is load-bearing — it reflects
what the real migration would write.

A **safe** dry-run:

- Adapter exit `0`.
- Diff file-list contains only the v11 forced additions (per
  `supporting-docs/MIGRATION-v10-to-v11.md` § What changed in v11): trinity `## Quick
  reference` blocks, `HELP-FRAGMENT*.md`,
  `.github/ISSUE_TEMPLATE/*.yml`, per-CLI `pack-help` skill/command,
  `.pack-migrate-v10-to-v11/` state dir, the relocation moves.
- Stderr tail empty or only `[dry-run] would ...` lines.

A **would-break-customizations** dry-run:

- Adapter exit `0`, but the diff overwrites files you have customized,
  AND the stdout tail shows `customization-detected-needs-reconciliation`
  rows from the customization-preservation report. Each such
  row means the real migration would write a `<file>.v10-customized`
  sidecar that you would manually merge per `supporting-docs/MIGRATION-v10-to-v11.md`
  § Step 2. Recoverable, but real work — plan accordingly.

A **would-fail** dry-run:

- Non-zero adapter exit (harness exit `7`) or detection failure
  (harness exit `6`). Read the stderr tail. Common causes: dirty tree
  at clone time, missing `v10` tag in the pack repo, target not
  v10-shaped.

See `supporting-docs/MIGRATION-v10-to-v11.md` § Step 2 for the full vocabulary of the
underlying migrator's report sections.

---

## 4. Release-gate integration

Pattern for using the harness as a CI gate before tagging a new pack
version:

1. **Target URL via secret.** Store the target client URL in a CI
   secret (`TARGET_URL`); inject as env var, never inline.
2. **One harness call per target.**
   ```sh
   scripts/dry-run-migration.sh "$TARGET_URL" \
       --report-out "$RUNNER_ARTIFACTS/dry-run-${TARGET_NAME}.md"
   ```
3. **Exit-code policy:**
   - `0` — green; safe to tag.
   - `2` / `4` / `5` — pipeline issue (bad arg, clone failed, refused
     tmp dir). Fix the pipeline; the gate has not actually run.
   - `6` — version detection failed (target not v10-shaped, or pack
     lacks the adapter). Release blocker until resolved.
   - `7` — adapter ran and would fail. Hard release blocker; read
     the stderr tail.
4. **Diff-noise tolerance.** A non-empty diff with exit `0` is the
   expected case — the migration *should* change files. Treat as
   acceptable unless your governance requires per-diff review.
5. **Archive the report.** Persist `--report-out` artifacts; they are
   the audit trail for "we knew what the migration would do."

---

## 5. Limitations

The harness does NOT verify:

- **Post-migration runtime behavior.** Whether `pack help`,
  `pm-startup`, or any project command actually works after migration.
- **Downstream tool compatibility.** Whether your CI, IDE
  integrations, or local tooling work against the v11 file layout.
- **Customization semantics.** It will say a sidecar *would* be
  written; it cannot say whether the three-way merge result is
  semantically what you want.
- **Anything outside the file-tree diff.** Permissions, symlinks,
  submodule state, encoding edge cases.

For full pre-migration confidence: dry-run + sidecar review + a test
commit on a branch + your project's own CI green.

---

## 6. Recovery — dry-run vs real-run divergence

If a real migration produces a diff materially different from the
dry-run, target state changed between the two runs. Common causes:
a commit landed on the target between clone and real run; local
uncommitted changes accumulated on the real-run working copy;
the pack repo was updated between runs.

To recover:

1. **Stop the real migration if still in progress.** The migrator's
   `.pack-migrate-v10-to-v11-backup/` (S1) is the rollback target —
   see `supporting-docs/MIGRATION-v10-to-v11.md` § Rollback.
2. **Pin both sides.** `git -C "$PACK" rev-parse HEAD` before dry-run;
   same SHA before real run. For URL mode, ensure no commits land on
   the target between dry-run clone and real run.
3. **Re-dry-run from the exact state the real run will start from**,
   then diff the new report against the prior one — the deltas
   explain the divergence.

If both sides are pinned and the dry-run and real-run still diverge,
that is a migrator defect — file a BD with both reports attached.

---

## See also

- `supporting-docs/MIGRATION-v10-to-v11.md` — the actual migration narrative.
- `MERGE-STRATEGY.md` — per-file customization-preservation matrix.
- `scripts/dry-run-migration.sh --help` — canonical flag listing.
