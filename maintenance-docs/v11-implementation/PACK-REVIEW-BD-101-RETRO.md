# PACK-REVIEW-BD-101-RETRO.md — Retroactive review of BD-101 (Batch 21c)

**Reviewer:** pack-reviewer (retroactive per-BD pass)
**Subject:** BD-101 — Client-migration validation gates (3 in-script gates with pass/fail)
**Original commit:** `60ac6d9` ("fix: v11 — Batch 13 part 2 (BD-101 validation gates) + BD-139 ...")
**Implementation report:** `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-101.md`
**Today's date:** 2026-05-15
**Verdict:** Findings present; ship is functional but has 1 MAJOR (broken UX recovery banner referencing wrong/legacy script) plus several MINOR/NIT items. Recommend a follow-up fix rather than relitigating BD-101.

---

## Scope isolated for this review

Per the BD-101 BACKLOG entry (lines 801–816) and `git show 60ac6d9 --stat`, the
BD-101 portion of the combined commit covers:

- NEW `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (8 public + 1 private helper)
- NEW `scripts/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh`
- NEW `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh`
- NEW `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh`
- NEW `scripts/tests/test-migrate-v10-to-v11-gates.sh` (38 cases)
- MOD `scripts/lib/migrator-core.sh` (added `EXIT_GATE_FAILED=31`)
- MOD `scripts/lib/migrate-v10-to-v11/dry-run.sh` (Gate 1 wiring)
- MOD `scripts/lib/migrate-v10-to-v11/apply.sh` (Gate 2 + Gate 3 in wrapped post_report_hook)
- MOD `scripts/lib/migrate-v10-to-v11/resume.sh` (Gate 2 + Gate 3 tail)
- MOD `scripts/migrate-v10-to-v11.sh` (source the four new lib files)
- MOD `supporting-docs/MIGRATION-v10-to-v11.md` (BD-101 portion of edits — exit-code 31 row + Gate semantics paragraphs)
- NEW `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-101.md` (now archived)

BD-139's portion of the same commit (BD-104 audit fix-follow) is OUT of scope for
this review.

---

## What BD-101 got right

Acknowledging the strong points before listing findings:

1. **Helper purity is well-respected.** Every `checkpoint_check_*` helper in
   `scripts/lib/migrate-v10-to-v11/checkpoint.sh:62–344` is read-only, returns
   0/1 cleanly, and never calls `exit`. The orchestrating gates do the
   process-exit decision. This is the correct separation.
2. **Idempotent re-source pattern.** Both `gate-1-dry-run-summary.sh:34-38`
   and `gate-2-phase-a-verify.sh:33-37` use `if ! declare -F …` guards before
   sourcing `checkpoint.sh`, allowing direct sourcing from tests
   (`scripts/tests/test-migrate-v10-to-v11-gates.sh:81-87`) without double-load.
3. **Gate 3's PASS/SKIP/FAIL discrimination is correct.** The
   `checkpoint_tracker_mode_active` boolean (`checkpoint.sh:352-366`) drives the
   SKIP path so flat-file users see a clean `[INFO] tracker: skipped` line
   rather than spurious `[FAIL]` noise.
4. **Exit-code distinguishability.** `EXIT_GATE_FAILED=31` slots above the
   stage-failure cap of 30 (`migrator-core.sh:70` + `fail_stage` cap at
   `migrator-core.sh:97-98`). This achieves the declared goal of letting
   `--resume` distinguish gate fix vs stage rerun. The Group 4 tests
   (`test-migrate-v10-to-v11-gates.sh:340-377`) exercise this end-to-end via a
   planted HELP-FRAGMENT.md drift — a clean fixture choice that avoids
   mid-flight hook injection.
5. **Atomicity is preserved.** Gate failures abort BEFORE the user has a
   reason to mutate further. The framework EXIT trap
   (`migrator-core.sh:185-208`) does NOT re-render the report on gate failure
   because `_MIGRATOR_REPORT_DONE=1` was set on `migrator-core.sh:228` before
   `migrator_post_report_hook` (and its wrapped Gate 2/3) ran — so the report
   reflects the actual post-S6 state without duplicate render attempts.
6. **`--resume` re-fires the gates.** `resume.sh:253-267` invokes Gate 2 +
   Gate 3 explicitly because the apply.sh wrapper is bypassed in resume mode.
   The contract is consistent across paths.
7. **Test coverage is generous.** 38 cases / 4 groups, well above the ≥10
   threshold. End-to-end Group 4.3 fixture exercises the full
   `--apply → Gate 2 FAIL → exit 31` chain.
8. **Scope isolation from BD-139.** The two co-shipped BDs touched
   `scripts/migrate-v10-to-v11.sh` line-disjointly (BD-139: ~163-260,
   BD-101: ~378-389 / sourcing block); no collision.

---

## Findings

### MAJOR

**MAJOR-1 — Gate 2 FAIL banner directs users to a script that does not work for v10→v11 backups (multiple defects)**

- **Location:** `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh:80`,
  `supporting-docs/MIGRATION-v10-to-v11.md:313`,
  `supporting-docs/MERGE-STRATEGY.md:409–410`
- **Description:** The Gate 2 FAIL recovery banner emits the literal command
  `bash $PACK/scripts/restore-from-backup.sh ${state_dir}-backup`. Three
  separate problems with that command:
  1. **Wrong script for v10→v11.** Per `scripts/restore-from-backup.sh:1-3`
     and `supporting-docs/MIGRATION-v10-to-v11.md:534-536`, this script is
     for the **v9.3→v10** backup layout (which flattens `docs/pack/` paths to
     `docs-pack-` prefixes). The v10→v11 backup written by
     `scripts/lib/migrator-stages.sh:_stage_backup` (lines 146-185) is a
     faithful tar-based working-tree mirror at `.pack-migrate-v10-to-v11-backup/`
     with NO flattening. `restore-from-backup.sh`'s `invert_path` function
     (`restore-from-backup.sh:93-103`) would silently no-op on every v10→v11
     backup file (no `docs-pack-*` to invert), but more importantly:
  2. **Wrong arity.** `restore-from-backup.sh` requires TWO positional args
     (`<backup-dir> <target-dir>`, see `restore-from-backup.sh:41-44`). The
     banner supplies ONE — the script will print "usage: …" to stderr and exit
     1 before doing anything.
  3. **Refuses non-empty target.** Even if the user fixes the arity by passing
     the project root as `<target-dir>`, `restore-from-backup.sh:54-58` refuses
     to merge into a non-empty target dir (exits 2). The v10→v11 project root
     is, of course, populated.
- **Severity rationale:** This is the user-visible recovery surface for the
  most-likely Gate 2 failure path. A user who hits this banner and copy-pastes
  the command will see `restore-from-backup.sh` exit 1 immediately and have no
  next step. The correct rollback recipe IS documented in
  `supporting-docs/MIGRATION-v10-to-v11.md:519-541` (Rollback section), but
  that's an `rsync -a --delete` invocation against the backup mirror, NOT
  `restore-from-backup.sh`.
- **Recommended fix:** Replace the recovery block in `gate-2-phase-a-verify.sh`
  (lines 73-86) with the rsync recipe from `MIGRATION-v10-to-v11.md` Rollback,
  templated against `${MIGRATOR_FROM_VERSION}` / `${MIGRATOR_TO_VERSION}`.
  Concretely: print the three commands `rm -rf .pack-migrate-v10-to-v11/`,
  `rsync -a --delete --exclude=.git/ --exclude=.pack-migrate-v10-to-v11-backup/
  .pack-migrate-v10-to-v11-backup/ ./`, `rm -rf .pack-migrate-v10-to-v11-backup/`.
  Update `supporting-docs/MIGRATION-v10-to-v11.md:313` exit-code-31 row in
  lockstep (currently says "Gate 2 ... requires `restore-from-backup.sh`").
  Update `supporting-docs/MERGE-STRATEGY.md:409-410` Gate 2 FAIL recovery in
  lockstep.

### MAJOR

**MAJOR-2 — Gate 2 coverage gap: BD-104, BD-035 (S5b), BD-144 (S5c) outcomes are not verified**

- **Location:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (no helper);
  `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh:39-65`
- **Description:** Gate 2 verifies five Phase-A outcomes (trinity addenda,
  HELP-FRAGMENT byte-equality, dispositions consistency, BD-042 relocations,
  validate-pack). It does NOT verify the other operations performed inside
  `migrator_post_dispatch_hook`:
  1. **BD-104 rename outcome** (`scripts/migrate-v10-to-v11.sh:167-219`,
     `_v10_to_v11_rename_implementation_plan`): Gate 2 does not check that
     `IMPLEMENTATION-PLAN.md` exists at target root if `IMPLEMENTATION_PLAN.md`
     was originally present. A silent `git mv` failure that returned 0 but
     left both files in place would not be caught (the rename is supposed to
     be atomic; a partial state would be a defect).
  2. **BD-035 advisory** (`scripts/migrate-v10-to-v11.sh:380-396`,
     `_v10_to_v11_rename_python_architecture_refs`): Gate 2 does not check
     whether `python-architecture-rename.advisory` was written when the project
     contained ambiguous `python-architecture` references. Silent advisory
     omission would mean the user never sees the manual-reconciliation surface.
  3. **BD-144 advisory** (`scripts/migrate-v10-to-v11.sh:432-585`,
     `_v10_to_v11_translate_capability_tokens`): Gate 2 does not check that
     `capability-rename.advisory` was written when the project's trinity
     contained `role:apple-app` or `role:python-server`. Same silent-omission
     class as BD-035.
- **Severity rationale:** The gates are positioned as the post-Phase-A truth
  oracle. Every additive operation inside `migrator_post_dispatch_hook` is
  load-bearing for v11.0 correctness. Missing verification of three of the
  five `migrator_post_dispatch_hook` sub-stages is a gap relative to the
  BACKLOG entry's "Gate 2: post-Phase-A (trinity addenda; HELP-FRAGMENT
  files; Source column; relocated docs; validate-pack)" wording — which
  does enumerate only the five checks Gate 2 implements, so this is a
  **scope-vs-need gap** rather than a plan deviation. But the practical
  effect is real: a silent S4a / S5b / S5c partial failure ships a broken
  client install with Gate 2 stamping PASS.
- **Recommended fix:** Add three helpers to `checkpoint.sh`:
  - `checkpoint_check_implementation_plan_rename <target>` — if either
    `IMPLEMENTATION_PLAN.md` (underscored) or `IMPLEMENTATION-PLAN.md`
    (hyphenated) is present, the OTHER must NOT be present (collision
    detection); if both absent, no-op OK.
  - `checkpoint_check_skill_rename_advisory <state-dir>` — if any of the
    BD-035 scanned files (`docs/pack/PLATFORM-SKILLS.md`, trinity) currently
    contains a stale bare `python-architecture` token, the advisory file
    `<state-dir>/python-architecture-rename.advisory` must exist (i.e. the
    migrator surfaced it). Read-only scan.
  - `checkpoint_check_capability_token_advisory <target> <state-dir>` —
    parallel to the previous; if trinity still contains `role:apple-app` or
    a `role:python-server` line lacking `deployment:linux-container`, the
    advisory must exist.
  Wire all three into `migrate_v10_to_v11_gate2_run`. Add 3 cases per check
  (PASS / FAIL-on-orphan / FAIL-on-collision) to
  `test-migrate-v10-to-v11-gates.sh` Group 2.

### MINOR

**MINOR-1 — `checkpoint_check_dispositions_consistency` over-counts rows by 1 (header counted as data row)**

- **Location:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh:89-92`
- **Description:** `n_rows=$(wc -l < "$tsv" | tr -d ' ')` followed by
  `[OK]   dispositions: %s row(s), no unknown-classification` reports the
  total line count of `dispositions.tsv`, including the header line that
  `customization_preserve_init` writes (`scripts/lib/customization-preserve.sh:129`).
  After a fresh dry-run with zero classified files, the OK message would say
  `1 row(s)` even though zero data rows exist. After a real apply with N data
  rows it says `N+1 row(s)`. This is misleading — the figure is intended to
  give the user a sense of "how many files did the migrator classify?".
- **Severity rationale:** Cosmetic; doesn't affect pass/fail. But the row
  count is a UX signal that's silently inaccurate by 1 in every report.
- **Recommended fix:** Change line 90 to count non-header data rows:
  `n_rows=$(awk -F'\t' '$1 !~ /^#/' "$tsv" | wc -l | tr -d ' ')`. Or
  equivalently `awk -F'\t' '$1 !~ /^#/{n++} END{print n+0}'` for a one-pass
  count. Add a 1.5 test case to Group 1 asserting the count after fixture
  population matches the data-row count.

**MINOR-2 — `checkpoint_check_dispositions_consistency` accepts header-only TSV as PASS in resume mode**

- **Location:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh:75-92`,
  `scripts/lib/migrate-v10-to-v11/resume.sh:208-214`
- **Description:** `resume.sh:214` calls `customization_preserve_init` which
  truncates `dispositions.tsv` and writes ONLY the header
  (`scripts/lib/customization-preserve.sh:128-131`). The post-S3 stages run
  inside `migrator_post_dispatch_hook` (BD-104 rename + BD-042 relocate +
  S5 artifact installs + BD-035 + BD-144) do NOT record dispositions through
  `customization_preserve` — they're additive operations bypassing the
  three-way machinery. Consequence: at Gate 2 resume time, `dispositions.tsv`
  has the header line plus zero data rows. `checkpoint_check_dispositions_consistency`
  sees `[[ -s "$tsv" ]]` (true — header present), `awk` for unknown-classification
  matches 0, returns OK with `1 row(s)`.
  This means a resumed migration could have dispositions.tsv truthfully showing
  zero classified files (because the resume re-init wiped the original) and
  Gate 2 would still PASS the dispositions check. The original apply's
  dispositions are lost to the report by the time Gate 2 runs in the resume
  path. Less of a functional defect than a contract gap: the gate's
  dispositions check is no-op-equivalent in resume mode.
- **Severity rationale:** The resume.sh comment (lines 208-213) acknowledges
  the truncation is intentional ("we DO want a fresh disposition file for the
  post-S3 stages so the resume report reflects what happened during resume").
  But Gate 2 was added LATER (BD-101) and its dispositions check assumes the
  pre-resume rows are still inspectable. In practice, the user trusts Gate 2's
  PASS for dispositions consistency that wasn't actually re-verified.
- **Recommended fix:** Either (a) preserve the original dispositions.tsv in
  resume.sh by stash-and-restore around the `customization_preserve_init`
  call, OR (b) explicitly skip the dispositions check in Gate 2 when running
  in resume mode (`_MIGRATOR_MODE == "resume"`) and emit a `[INFO]
  dispositions: skipped (resume mode)` line. Document the chosen behavior in
  the gate-2 header comment. Option (a) is a true verification; option (b) is
  a clean acknowledgement of the contract gap.

**MINOR-3 — Gate 2 does not detect orphaned `*.v10-customized` sidecars**

- **Location:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (no helper);
  `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh`
- **Description:** The `--resume` precondition check
  (`scripts/lib/migrate-v10-to-v11/resume.sh:131-168`) catches unresolved
  sidecars in the `stage-S3.paused` list — but only the sidecars listed there.
  If a user resolves a sidecar by editing the destination AND forgets to
  remove the sidecar (or if a sidecar from a different stage is left behind
  for any reason), Gate 2 reports PASS while the project tree still carries
  `*.v10-customized` files. The expected end-state of a successful migration
  is "zero `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}` files at the target."
- **Severity rationale:** Low-frequency in practice (the resume precondition
  catches the common case), but the gates are positioned as the
  truth-oracle for "is this client install consistent post-Phase-A?". Orphan
  sidecars contradict that.
- **Recommended fix:** Add `checkpoint_check_no_orphan_sidecars <target>`
  helper that does `find "$target" -type f -name "*.${MIGRATOR_OWN_SIDECAR_SUFFIX}"
  -not -path '*/.pack-migrate-*' -not -path '*/.git/*' | head -10` and FAILs
  if any matches found, listing them. Wire into `migrate_v10_to_v11_gate2_run`.
  Add 2 cases (PASS-no-orphans / FAIL-with-orphan) to Group 2.

**MINOR-4 — `migrator_post_report_hook` "pack tracker init" pointer prints BEFORE Gate 2/3 verdict**

- **Location:** `scripts/lib/migrate-v10-to-v11/apply.sh:361-388`,
  `scripts/migrate-v10-to-v11.sh:591-595`
- **Description:** The wrapped `migrator_post_report_hook` (apply.sh:361)
  calls `_v10_to_v11_orig_post_report` (the adapter's "To opt into the v11
  issue-tracker integration, run: pack tracker init" pointer) on line 363,
  THEN runs Gate 2 (line 369) and Gate 3 (line 381). User sees the
  optimistic "opt in" suggestion BEFORE the gate verdict. On Gate FAIL the
  user has already been encouraged toward the next step on a broken install.
- **Severity rationale:** UX confusion only; doesn't affect correctness. The
  exit code 31 is unambiguous to scripted callers, but humans reading
  console output get mixed signals.
- **Recommended fix:** Reorder the wrapper: run Gate 2 + Gate 3 first; call
  `_v10_to_v11_orig_post_report` only AFTER both pass. Apply same reorder
  in `resume.sh:241-267`. No test changes needed; existing assertions are
  on per-line content, not order.

**MINOR-5 — `EXIT_GATE_FAILED` addition not propagated to PLAN-BD-119 §3.5 / migrator-core.sh header comment**

- **Location:** `maintenance-docs/v11-implementation/PLAN-BD-119.md:149-162`,
  `scripts/lib/migrator-core.sh:14-17`
- **Description:** PLAN-BD-119 §3.5 declares the exit-code constants
  "Frozen" and lists 8 (10–16, 99). BD-101 added `EXIT_GATE_FAILED=31` to the
  frozen list (`migrator-core.sh:67-70`) without amending the plan. The
  plan still says "Stage failures use the existing `20+N` formula; that
  formula is also frozen. **Renaming `EXIT_NOT_V10` to `EXIT_NOT_BASELINE`
  is the only behavior-visible exit-code change.**" — a statement that became
  false at BD-101 ship.
  Separately, `migrator-core.sh:16-17` says "Public-API surface FROZEN per
  PLAN §3 (six function names + **eight** exit-code constants + EXIT_NOT_V10
  synonym)." The actual count is now nine.
- **Severity rationale:** Doc drift only; does not affect runtime. But
  PLAN-BD-119 is one of the documents future migrator authors will consult to
  understand the framework's contract. A future BD reading "Frozen, only
  rename was the visible change" will misunderstand.
- **Recommended fix:** Add a row for `EXIT_GATE_FAILED=31` to PLAN-BD-119 §3.5
  with a "BD-101 — gate failure (verification gate detected a defect
  post-stage)" note and remove/adjust the "only behavior-visible exit-code
  change" sentence. Update `migrator-core.sh:16-17` count from "eight" to
  "nine" and add a parenthetical noting the BD-101 addition. Both edits are
  one-line touches. Note: `validate-pack.py` Check 26 was already extended
  in `54dff63` (Batch 13 audit fix-follow on the same day) to include
  `EXIT_GATE_FAILED` — that drift is already closed; only the plan + core
  header doc drift remains.

**MINOR-6 — IMPLEMENTATION-REPORT-BD-101.md claim about validate-pack Check 26 was inaccurate at ship time**

- **Location:** `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-101.md:108-113`
- **Description:** The implementation report says "Check 26
  (`check_migrator_framework_inventory`) was inspected: it requires the 8
  named exit-code constants but does NOT forbid additional ones, so
  `EXIT_GATE_FAILED` adds no validator amendment." Per `git blame` of
  `scripts/validate-pack.py:1965-1980`, `EXIT_GATE_FAILED` was added to
  `required_exits` in commit `54dff63` (also 2026-05-11), the Batch 13 audit
  fix-follow, AFTER BD-101 itself shipped. So at ship time, Check 26 did not
  recognize `EXIT_GATE_FAILED`; the audit found this gap and added the
  enforcement. The report's "no validator amendment" claim was true on the
  day-of but missed the implication that without an amendment, Check 26
  would silently fail to enforce the new constant going forward (which is
  precisely why the audit added it).
- **Severity rationale:** Historical-record only — the gap is closed today.
  Worth noting because future retro reviews may re-check the implementation
  report against the current code state and find the discrepancy.
- **Recommended fix:** No code action required. If the archived report is
  edited for any reason, append a footnote: "Note 2026-05-11: Check 26 was
  subsequently extended in `54dff63` (Batch 13 audit fix-follow) to include
  `EXIT_GATE_FAILED` in the `required_exits` allowlist; see PACK-REVIEW
  Batch 13 audit." Otherwise leave alone.

### NIT

**NIT-1 — BACKLOG entry's File/Symbol field has ambiguous `checkpoint.sh` reference**

- **Location:** `BACKLOG.md:806`
- **Description:** Per the user's filename-uniqueness heuristic
  ("Filename uniqueness heuristic project-wide"), prose references should be
  unambiguous. The entry reads
  `File/Symbol: scripts/lib/migrate-v10-to-v11/gate-{1,2,3}-*.sh, checkpoint.sh, scripts/tests/test-migrate-v10-to-v11-gates.sh`
  — `checkpoint.sh` is bare without its directory prefix. There is no other
  `checkpoint.sh` in the pack today (`find . -name checkpoint.sh` returns
  exactly the one), so the reference is unambiguous in practice, but the
  heuristic prefers full paths.
- **Severity rationale:** Style only.
- **Recommended fix:** Update File/Symbol to read
  `scripts/lib/migrate-v10-to-v11/{gate-{1,2,3}-*.sh,checkpoint.sh}, scripts/tests/test-migrate-v10-to-v11-gates.sh`
  on next BACKLOG sweep. Not a per-BD fix.

**NIT-2 — `checkpoint_check_mapping_integrity` accepts non-integer numeric values (e.g., `1.5`)**

- **Location:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh:271-279`
- **Description:** The jq predicate `select((.value | type) != "number" or
  .value <= 0)` flags non-numbers and non-positives. JSON has no integer
  type — `1.5` would be type `"number"` and `> 0`, so it passes. Tracker
  issue numbers are strict positive integers; a float in `id-map.json`
  would be a defect that this check misses.
- **Severity rationale:** Hypothetical defect class. The forward migrator
  writes integers; for a float to appear, either the file would be
  hand-edited or a future tracker provider would emit floats. Defense in
  depth.
- **Recommended fix:** Tighten to
  `select((.value | type) != "number" or .value <= 0 or (.value | floor != .value))`.
  Adds zero risk and one extra safety net.

**NIT-3 — Gate 1 banner uses "(read-only)" parenthetical; Gate 2/3 do not**

- **Location:** `scripts/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh:44`,
  `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh:45`,
  `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh:45`
- **Description:** Gate 1 banner reads `── Gate 1 — pre-migration dry-run
  summary (read-only) ──`; Gates 2 and 3 omit the read-only annotation
  even though they are also read-only on the project tree (only the
  helpers' stdout has side effects). Inconsistent banner shape.
- **Severity rationale:** Style only.
- **Recommended fix:** Add `(read-only)` to Gate 2 and Gate 3 banners,
  OR drop it from Gate 1. Either direction; symmetry matters more than
  which way.

**NIT-4 — Gate 2 banner / `say` call uses `${state_dir}` and `${target}` without confirming their definedness**

- **Location:** `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh:80,82,83`
- **Description:** The recovery banner uses `${state_dir}` and `${target}`
  without `${var:-default}` fallbacks. They ARE the function's `local`
  parameters, which would be empty strings if the caller forgot them — but
  the function would have already failed earlier checks. Robustness in
  error reporting matters most because that's exactly when env state is
  abnormal.
- **Severity rationale:** Defensive code only; no observed defect.
- **Recommended fix:** Use `${state_dir:-<state-dir>}` / `${target:-<target>}`
  so the banner always reads sensibly even in degenerate input. Trivial
  edit.

---

## Six-dimension touch-point assessment (per CONCEPTUAL-REVIEW-METHODOLOGY)

| Dimension | Assessment |
|---|---|
| **Gate atomicity** | PASS. Gate 2/3 are post-stage observers; they do not partial-apply. A FAIL exits 31 cleanly without re-entering any stage. The only concern is the **dispositions.tsv truncation in resume mode** (MINOR-2) which makes the dispositions check no-op-equivalent on a resumed Phase-A. |
| **`--resume` re-entrancy** | PASS for gate invocation (resume.sh:253-267 mirrors apply.sh wrapping). DEGRADED for dispositions check (MINOR-2). The forward-only check at resume.sh:117-129 protects against re-running gates after they've passed. |
| **User-facing UX on gate failure** | FAIL. MAJOR-1 (broken `restore-from-backup.sh` reference) is the headline finding. MINOR-4 ("pack tracker init" suggestion before gate verdict) compounds. The DOCs in `MIGRATION-v10-to-v11.md` and `MERGE-STRATEGY.md` carry the same broken script reference. |
| **Coverage of failure modes** | DEGRADED. MAJOR-2 (BD-104 / BD-035 / BD-144 advisory verification gaps) plus MINOR-3 (orphan sidecar detection gap). The five existing checks are well-chosen; the gaps are the additive operations that bypass `customization_preserve`. |
| **Composition with `EXIT_GATE_FAILED=31`** | PASS at runtime; DEGRADED in docs (MINOR-5: PLAN-BD-119 + migrator-core.sh header not updated). The 20-30 stage-cap vs 31 gate-cap split is correct and tested (Group 4). |
| **Sidecar files & restore path** | DEGRADED. Gate 2's recovery says "restore + re-run" but points at the wrong tool (MAJOR-1). Gate 3's recovery is correct ("don't restore; run pack tracker doctor"). The asymmetry is intentional and correct in concept; only the Gate 2 implementation details are broken. |

---

## Cross-reference integrity

Grepped for stale references to BD-101 surface across the pack:

- `EXIT_GATE_FAILED` — present in `validate-pack.py:1976` (Batch 13 fix-follow),
  `MIGRATION-v10-to-v11.md:313`, `MERGE-STRATEGY.md:395`, all four BD-101 lib
  files, test file. Documentation matches code.
- `checkpoint_check_*` — defined only in `checkpoint.sh`, called only from the
  three gate libs, no stale references elsewhere.
- `migrate_v10_to_v11_gate{1,2,3}_run` — defined in respective gate libs,
  called from `dry-run.sh`, `apply.sh`, `resume.sh`, `test-migrate-v10-to-v11-gates.sh`.
  No stale references elsewhere.
- `restore-from-backup.sh` — referenced in MERGE-STRATEGY.md (Gate 2 recovery,
  same defect as MAJOR-1), MIGRATION-v10-to-v11.md (twice — once as the
  legacy v9.3→v10 script, once incorrectly in the Gate 2 row), and the
  banner inside gate-2-phase-a-verify.sh. Three places; one is correctly
  scoped (the legacy note); two are MAJOR-1 instances.

No stale references found beyond the MAJOR-1 / MINOR-5 items above.

---

## Trinity / migration / README impact

- **Trinity rule.** No trinity-file edits in BD-101. N/A.
- **MIGRATION-v10-to-v11.md.** Carries one of the MAJOR-1 instances
  (line 313). Rest of the BD-101-added content (gates intro paragraphs at
  315-333) is correct and consistent with the code.
- **README.md Repository Layout.** No new top-level dirs added by BD-101.
  Existing layout entry for `scripts/lib/migrate-v10-to-v11/` covers the
  four new files. N/A.
- **BACKLOG accuracy.** BD-101 entry is `Status: Resolved` with a thorough
  Resolved line. NIT-1 is the only nit.
- **validate-pack.py.** Already extended in `54dff63` (post-BD-101) to
  include `EXIT_GATE_FAILED`. No further pack-validator amendment needed.

---

## Summary

| Severity | Count | Headline |
|---|---:|---|
| MAJOR | 2 | Gate 2 recovery banner points at wrong/legacy script (multi-defect) + Gate 2 coverage gap for BD-104 / BD-035 / BD-144 outcomes |
| MINOR | 6 | Dispositions row over-count, resume-mode dispositions no-op, orphan-sidecar gap, premature "tracker init" message, plan/header doc drift, archived-report inaccuracy |
| NIT | 4 | BACKLOG path style, jq integer tightening, banner symmetry, defensive var fallbacks |

**Recommended action:** Land a single fix-follow commit covering MAJOR-1
(the user-visible recovery banner — Gate 2 lib + MIGRATION-v10-to-v11.md +
MERGE-STRATEGY.md, three sites in lockstep) and MINOR-5 (PLAN-BD-119 +
migrator-core.sh header doc drift, two one-line touches). MAJOR-2 (coverage
gap for BD-104 / BD-035 / BD-144) is a meaningful new feature surface and
should be a separate BD if pursued — three new helpers + nine test cases is
a planned increment, not a fix-follow. The remaining MINORs and NITs can
roll into a follow-up sweep at v11 ship.

The BD-101 implementation is functionally sound: the gates fire at the
right places, exit codes propagate correctly, and 38 tests pass. The
findings here are about completeness (coverage gaps), correctness of
user-facing recovery instructions (broken script reference), and doc
hygiene (FROZEN-list drift). None of the findings indicate the gates
themselves mis-classify a true PASS or FAIL on the dimensions they DO
check.
