# AUDIT-BD-104.md — Reviewer audit of Batch 12 (BD-104)

**Verdict:** Findings — fix-follow BD recommended

**Scope.** Cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`
(commits `ef20113` BD-104 sweep + `5e77939` mode-bit fix-up).
Standalone reviewer pass that did not run as part of the original
batch; this report closes that gap per standing rule §5.B.

The audit was performed read-only against the worktree at HEAD =
`f1dc255` (BD-137 harness retirement). The BD-104 commits sit at
HEAD~3 and HEAD~2.

---

## Summary of findings

| Severity | Count | Items |
|----------|-------|-------|
| BLOCKER  | 0     | — |
| MAJOR    | 1     | F-1 |
| MINOR    | 2     | F-2, F-3 |
| NIT      | 2     | F-4, F-5 |

Recommended fix-follow: a single BD covering F-1 (migrator-test extension),
F-2 (MIGRATION-v10-to-v11.md stage table), and the NITs in one cleanup pass.

---

## Spec requirement verification matrix

| # | Requirement | Verdict | Evidence |
|---|-------------|---------|----------|
| R1 | Hyphenated-all-caps form applied to current-state references | PASS | `project-template/`, `supporting-docs/`, `scripts/` (excluding migrator and v8→v9 archive) contain zero `IMPLEMENTATION_PLAN` literals. |
| R2 | Historical / archival references preserved | PASS — see allowlist audit below | 224 surviving `IMPLEMENTATION_PLAN` matches across the repo: 43 are the BD-104 implementation report itself (legitimate paper trail), and the remaining 181 fall entirely into the allowlist classes the BACKLOG spec named. Sample of 10+ inspected: all legitimate. (Note: spec says 179; actual count 181 — a 2-entry drift, see F-5.) |
| R3 | Migrator gained the rename stage | PASS | `scripts/migrate-v10-to-v11.sh` lines 165–205 (`_v10_to_v11_rename_implementation_plan`) wired into `migrator_post_dispatch_hook` at line 144. |
| R4 | Collision case surfaces `migration-rename-collision` typed error | PASS (code path); FAIL (test coverage — F-1) | The rename function lines 173–189 emit `ERROR: migration-rename-collision\nMESSAGE: ...\n<context>\n→ Run: ...` to stderr then calls `fail_stage S4`, matching the BD-070 / `scripts/lib/tracker-errors.sh` line-25 contract. No test asserts the path. |
| R5 | `git mv` (history-preserving) for tracked source; plain `mv` fallback for untracked | PASS (code path); FAIL (test coverage — F-1) | Lines 191–201 attempt `git -C "$_MIGRATOR_TARGET" mv` and fall back to plain `mv` on the documented `not under version control` / `did not match` stderr substrings. The fallback pattern matches `_v10_to_v11_relocate_legacy_docs` (BD-042). Test runner does not exercise either branch for BD-104. |
| R6 | Trinity rule preserved (CLAUDE / AGENTS / GEMINI symmetric) | PASS | The two affected lines (the trinity prose mentioning the four state docs, and the Document-locations table row) are byte-identical across `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` modulo line numbering. Verified by `diff` on the post-commit blobs. |
| R7 | Source-absent no-op path | PASS (code path); FAIL (test coverage — F-1) | Lines 169–172. |
| R8 | Post-rename verification | PASS (code path); FAIL (test coverage — F-1) | Lines 202–203. |

---

## Per-area assessment

### Trinity (`project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`)

Symmetric edit. Both touched lines (the `BACKLOG.md, STATUS.md, CHANGELOG.md, and IMPLEMENTATION-PLAN.md` prose and the `docs/project/` Document-locations table row) read identically in all three files. Trinity rule satisfied.

### Per-CLI pm-startup surfaces

`project-template/.claude/skills/pm-startup/SKILL.md`,
`project-template/.codex/skills/pm-startup/SKILL.md`,
`project-template/skills/pm-startup/SKILL.md`,
`project-template/.gemini/commands/pm-startup.toml` — all four updated. The
canonical Step-4 / Step-6 RAG lines audited by validator Check 28 still
pass. No drift.

### Prompts (`project-template/docs/pack/prompts/`)

`architect.md`, `coder.md`, `docs-researcher.md`, `planner.md`, `pm-chat.md`,
`reviewer.md` — all sampled lines reference `IMPLEMENTATION-PLAN.md` with
backticks and consistent casing. No half-renames found.

### `project-template/docs/pack/PM-CHAT.md`

20-line diff applied; the two notable spots (anchor-link prose at line 206
and resume-procedure prose at line 522) both use the hyphenated form.

### Migrator (`scripts/migrate-v10-to-v11.sh`)

New function `_v10_to_v11_rename_implementation_plan` is the core deliverable
on the script side. Inspection findings:

1. **Function placement is correct.** Called from `migrator_post_dispatch_hook`
   before `_v10_to_v11_relocate_legacy_docs` (BD-042) and
   `_v10_to_v11_install_v11_artifacts` (BD-085). Order matters because the
   BD-042 relocation operates on `METHODOLOGY.md` / `PM-CHAT.md` / etc., not
   on `IMPLEMENTATION_PLAN.md` — no ordering conflict.

2. **Typed-error block format is conformant** to the BD-070 / tracker-errors.sh
   contract at `scripts/lib/tracker-errors.sh:25-31`: code line, MESSAGE
   line, context lines, `→ Run:` line. Emitted to stderr then
   `fail_stage S4` invoked.

3. **Dry-run is honored.** The hook short-circuits via `_migrator_is_dryrun`
   at line 140, so the rename does not execute on `--dry-run`. Good.

4. **Both stages share the "S4" banner.** The rename emits
   `── S4 — BD-104 rename ... ──` at line 166 and the relocation emits
   `── S4 — BD-042 relocation of legacy root docs (if any) ──` at line 213.
   Two banners under one framework stage. Confusing but not strictly wrong;
   noted as F-3.

5. **The fallback `mv` path leaves a non-empty `$mv_stderr` from the
   failed `git mv`.** That output is captured into a local but never
   surfaced. If the `git mv` failure was actually some third class of
   error (corrupted index, refusal to overwrite, permission denied) that
   matched neither sentinel substring, the migrator would `fail_stage`
   *with* the captured stderr — that part is fine. But the fallback path
   silently swallows whatever stderr the user might want to see. Minor.
   See F-4.

### Fixtures

`scripts/tests/fixtures/roundtrip/bd-v11.0/IMPLEMENTATION_PLAN.md` and
`scripts/tests/fixtures/tracker-migrate/IMPLEMENTATION_PLAN.md` renamed to
hyphenated form. Git auto-detected the renames via content similarity per
the commit summary. Verified via `find` — only hyphenated forms remain.
Fixture references in `tracker-migrate-forward-test.sh`,
`tracker-migrate-reverse-test.sh`, `tracker-migrate-roundtrip-test.sh`,
`recommendation-test.sh` all use the new name.

### Supporting docs

`supporting-docs/METHODOLOGY.md` (largest diff: 42 lines, ~22 occurrences),
`supporting-docs/SETUP-NEW.md`, `supporting-docs/SETUP_TEMPLATE.md`,
`supporting-docs/CLI-PM-SETUP.md`, `supporting-docs/INSTALL-PROCEDURES.md`,
`maintenance-docs/TOOL-COMPARISON.md` — all consistent.

Note: the file name `SETUP_TEMPLATE.md` (with underscore) is itself
outside BD-104 scope (the BD covers content references to
`IMPLEMENTATION_PLAN.md`, not the rest of the underscore-vs-hyphen file
naming inconsistency in the repo).

### BACKLOG / CHANGELOG / EXECUTION-PLAN

All three keep `IMPLEMENTATION_PLAN` references — correctly allowlisted as
historical context describing the rename itself (i.e. the words "rename
IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md" must spell out the old
name verbatim).

### Permission bits (commit `5e77939`)

The 6 scripts (`scripts/tracker-migrate.sh` plus the 5
`scripts/tests/tracker-*.sh`) had their +x bit silently dropped by the
Edit-tool side-effect in `ef20113` (mode `100755 → 100644`). The follow-up
commit restores `100755`. Verified via `ls -la` on the worktree and via
`git show --raw` on both commits.

Audit of whether any OTHER scripts in the BD-104 set silently lost +x:
checked all 30 changed-file modes in `ef20113`. The only `100755 → 100644`
transitions are exactly those 6. Other test scripts already
shipped as `100644` from inception (e.g. `recommendation-test.sh` —
verified via `git log --raw -- scripts/tests/recommendation-test.sh`; it
was added as 100644 in `b612c01` and was never +x). Those non-+x
test scripts are an unrelated repo-cleanliness issue, not a BD-104
regression. Out of scope.

---

## Allowlist spot-check (≥ 10 random samples)

I sampled 10 surviving `IMPLEMENTATION_PLAN` occurrences across the
remaining 181:

| # | File | Line | Context | Allowlisted? |
|---|------|------|---------|--------------|
| 1 | `BACKLOG.md` | 72 | `BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION_PLAN tracker-mirrored` inside BD-066 Resolved: line (historical record) | YES — historical |
| 2 | `BACKLOG.md` | 836 | BD-104 entry header itself | YES — describing the rename |
| 3 | `CHANGELOG.md` | 230 | v9-era four-doc list inside `pm-chat.md kickoff body` description | YES — historical |
| 4 | `supporting-docs/MIGRATION-v8-to-v9.md` | 625, 652 | Old v8→v9 procedure | YES — explicitly allowlisted |
| 5 | `scripts/migrate-v10-to-v11.sh` | 167, 181, 192 | Migrator manipulating the literal v10 filename | YES — references both names by necessity |
| 6 | `maintenance-docs/v11-research/INTERNAL-INVENTORY.md` | 383–388 | v10 inventory table | YES — research-stage, pre-decision archive |
| 7 | `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md` | 26, 86 | Architectural delta talking about v10 IMPLEMENTATION_PLAN.md | YES — research-stage |
| 8 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | 111 | "Reverse migration emits the phase task as the v10 IMPLEMENTATION_PLAN.md" | YES — explicit reference to the v10 form |
| 9 | `maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md` | 76, 85, 90 | v1 origin doc | YES — origins (frozen) |
| 10 | `maintenance-docs/archive/V10-PROMPT-STRUCTURE-PLAN.md` | 170, 183, 339 | V10 plan archive | YES — archive |
| 11 | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | 46, 244 | Execution plan describing BD-104 itself | YES — describes the rename |

All 11 samples pass. The allowlist is well-formed. No half-rename was
missed in current-state files.

---

## Cross-pack symmetry spot-check (≥ 5 random `IMPLEMENTATION-PLAN`
references after rename)

| # | File | Line | Reads | Context-correct? |
|---|------|------|-------|------------------|
| 1 | `project-template/docs/pack/prompts/architect.md` | 25 | `` `IMPLEMENTATION-PLAN.md` Phase [N] in full.`` | YES |
| 2 | `project-template/docs/pack/prompts/coder.md` | 67 | `CHANGELOG/IMPLEMENTATION-PLAN are tracker-mirrored read-only files` | YES |
| 3 | `project-template/docs/pack/PM-CHAT.md` | 206 | anchor-link format `[Title](IMPLEMENTATION-PLAN.md#anchor)` | YES |
| 4 | `project-template/.gemini/commands/pm-startup.toml` | 76 | `from `IMPLEMENTATION-PLAN.md`.` | YES |
| 5 | `supporting-docs/METHODOLOGY.md` | 124 | "ARCHITECTURE.md and IMPLEMENTATION-PLAN.md are source of truth" | YES |
| 6 | `maintenance-docs/TOOL-COMPARISON.md` | 185 | four-doc list `(`IMPLEMENTATION-PLAN.md`, `STATUS.md`, `BACKLOG.md`, `CHANGELOG.md`)` | YES |

All 6 samples context-correct. No broken cross-refs. No half-renames.

---

## Validator + tests

- `python3 scripts/validate-pack.py` — 30 checks PASS at HEAD.
- `bash scripts/tests/test-migrate-v10-to-v11.sh` — 39 PASS / 0 FAIL on a
  clean second run. (First run flaked at Group 2 with several `rc=12`
  failures; appears nondeterministic and unrelated to BD-104. Worth a
  separate investigation if the flake reproduces in CI.)
- BD-137 (test-migrator-behavior-preservation.sh retirement) at HEAD
  removed the harness that was failing on BD-104's intentional stdout
  drift — so the CI tests job should now be green end-to-end. Confirmed:
  the script no longer exists at HEAD.

---

## Findings

### F-1 (MAJOR) — Migrator integration test not extended for BD-104

**Severity:** MAJOR (no test coverage on a multi-branch code path with a
typed-error contract).

**Evidence.** Spec
`maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-3.md:235`
states explicitly:

> `scripts/tests/test-migrate-v10-to-v11.sh` (extended by BD-104) —
> fixture has `docs/project/IMPLEMENTATION_PLAN.md`; after `--apply`,
> asserts new path exists, old path absent, `git log --follow` shows
> continuous history. Collision case: pre-create both paths; assert
> halt with typed error `migration-rename-collision`.

The actual `scripts/tests/test-migrate-v10-to-v11.sh` at HEAD has zero
occurrences of `IMPLEMENTATION`, `BD-104`, `S4`, `collision`, or `rename`
(verified with `grep -nc`). The script ends at line 290 with Group 4
"customization preservation"; no Group 5 / Group 6 was added.

**Impact.** All four BD-104 migrator behaviors (rename happy path,
source-absent no-op, untracked-source `mv` fallback, collision typed
error) are uncovered. A future regression that, say, mis-spells the
typed-error code, drops the `→ Run:` line, removes `git mv`
history-preservation, or skips the fallback for untracked files would
ship green. Given BD-070 makes the typed-error surface a contract
(ARCHITECTURE.md §2.5), shipping the contract without a test for it is
the substantive gap in this batch.

The BD-104 implementation report (per its own statement) "manually
verified" the four paths — but manual verification on an unbounded
contract is exactly what the test runner is for.

**Fix-follow recommendation.** New BD scoped narrowly: add Group 5 to
`scripts/tests/test-migrate-v10-to-v11.sh` covering the four paths.
Minimal asserts:

- Happy path: pre-create `IMPLEMENTATION_PLAN.md` (committed); migrate;
  assert `IMPLEMENTATION-PLAN.md` exists, old name absent, and `git -C
  $TARGET log --follow IMPLEMENTATION-PLAN.md` lists at least the
  pre-rename commit.
- No-op: omit the source; assert migrator exits 0 and S4 banner reports
  "nothing to rename".
- Untracked: stage the source via `mv` into target without committing
  (or via .gitignore); assert plain `mv` fallback path executes and the
  "renamed (untracked)" info line emits.
- Collision: pre-create both files; assert non-zero exit, stderr
  contains `ERROR: migration-rename-collision`, `MESSAGE:`, and `→ Run:`
  lines.

### F-2 (MINOR) — `MIGRATION-v10-to-v11.md` stage table not updated

**Evidence.** `supporting-docs/MIGRATION-v10-to-v11.md:119-129` describes
"The script runs 7 stages" with S0–S6. S4 is labeled "BD-042 relocation
tail (legacy root docs → `docs/pack/`)." After BD-104 the migrator's
`migrator_post_dispatch_hook` runs `_v10_to_v11_rename_implementation_plan`
(BD-104) before `_v10_to_v11_relocate_legacy_docs` (BD-042), and both
emit "── S4 — ... ──" banners.

The user-facing migration doc does not mention the rename at all. Per
the pack memory rule "If the change affects files that exist in
projects, verify that MIGRATION guides and QUICKSTART.md reflect the new
state," this is a user-doc gap.

**Impact.** A user reading `MIGRATION-v10-to-v11.md` to understand what
the migrator does before they run it will not know that their
`IMPLEMENTATION_PLAN.md` is about to be renamed. Recoverable from the
S4 banner output, but the doc should pre-disclose.

**Fix-follow recommendation.** Add a row or sub-bullet under the S4
entry describing the rename, or split S4 into S4a (BD-104 rename) and
S4b (BD-042 relocation) and update the count from "7 stages" to "8
stages" accordingly. Either is fine.

### F-3 (MINOR) — Two functions share the "S4" framework stage label

**Evidence.** `scripts/migrate-v10-to-v11.sh:166` emits `── S4 — BD-104
rename ... ──` and line 213 emits `── S4 — BD-042 relocation of legacy
root docs ──`. Both run inside the same `migrator_post_dispatch_hook`
call.

**Impact.** Cosmetic — a user reading the migrator's stdout sees two
S4 banners and may wonder whether the second is a re-run of the first.
Also, when `fail_stage S4` fires from inside `_v10_to_v11_rename_implementation_plan`,
the framework records "stage S4 failed" with no automatic
disambiguation between the rename and the relocation as cause.

**Fix-follow recommendation.** Either re-label the second banner as
"S4b" (or "S5" if the framework supports a new ID), or expand the
`fail_stage S4` call sites with a stage-prefix string so the report
distinguishes "S4-rename" from "S4-relocate".

### F-4 (NIT) — `git mv` fallback path silently drops captured stderr

**Evidence.** `scripts/migrate-v10-to-v11.sh:191-201`:

```
mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "IMPLEMENTATION_PLAN.md" "IMPLEMENTATION-PLAN.md" 2>&1) || {
    if [[ "$mv_stderr" == *"not under version control"* \
       || "$mv_stderr" == *"did not match"* ]]; then
        mv "$src" "$dst"
        info "renamed (untracked): IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
        return 0
    else
        fail_stage S4 "git mv IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md failed: $mv_stderr"
    fi
}
```

When the fallback branch runs, `$mv_stderr` (containing the actual git
output that prompted the fallback) is never surfaced. Debugging an
unexpected fallback is harder than it needs to be.

**Fix-follow recommendation.** Add `info "git mv hint: $mv_stderr"`
or similar in the fallback branch.

### F-5 (NIT) — Spec-doc count mismatch (179 vs 181)

**Evidence.** Commit message and BACKLOG Resolved: line both say "179
remaining IMPLEMENTATION_PLAN references audited and explicitly
allowlisted." Actual count at HEAD, excluding the BD-104 implementation
report itself (43 references): 181. The 2-entry drift may be:

- 2 references in the implementation report that got double-counted, or
- 2 references in newer commits (BD-137 etc.) added after the BD-104
  audit, or
- a simple counting error in the commit message.

**Impact.** Cosmetic; the allowlist itself is sound (per the 11-sample
spot-check above).

**Fix-follow recommendation.** Re-run `grep -rn IMPLEMENTATION_PLAN
--include='*.md' --include='*.sh' --include='*.toml' --include='*.py' |
grep -v 'IMPLEMENTATION-REPORT-BD-104.md' | wc -l` and update the
BACKLOG Resolved: line if the audit BD touches BACKLOG anyway.

---

## Recommended fix-follow BD scope

A single fix-follow BD covers F-1 + F-2 + F-3 + F-4 + F-5 cleanly:

- F-1 is the only MAJOR; it is contained (~80 lines of bash test
  fixture + assertions) and self-verifies.
- F-2 is a doc-only patch to `MIGRATION-v10-to-v11.md`.
- F-3 is a 1–2 line stdout-label change in `migrate-v10-to-v11.sh`.
- F-4 is a 1-line `info` add.
- F-5 is a 1-character BACKLOG edit (after re-counting).

All five fit one batch comfortably. Suggested title:
"BD-NNN — BD-104 fix-follow: migrator test coverage + doc/stdout polish".

---

## What is NOT a finding

For the record, the following were investigated and ruled out:

- **`recommendation-test.sh` shipping as 100644.** Born as 100644 in
  commit `b612c01` (BD-072). Not a BD-104 regression. Out of scope.
- **`SETUP_TEMPLATE.md` filename with underscore.** Out of BD-104 scope
  (BD-104 is content references to `IMPLEMENTATION_PLAN.md`, not the
  general underscore-vs-hyphen file naming question).
- **Migrator test flake on first run.** Group 2 produced spurious
  `rc=12` failures on the first invocation but cleared on re-run. Not
  related to BD-104 (the rename function isn't exercised by the test
  at all per F-1). May warrant a separate stability investigation.
- **The implementation report file at
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-104.md`.**
  Per the standing rule "no prior reviews/reports to pack-reviewer,"
  not read during this audit. Its 43 internal `IMPLEMENTATION_PLAN`
  references are excluded from the allowlist-correctness denominator.
