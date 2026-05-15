# PACK-REVIEW-BD-095-RETRO

Retroactive per-BD review of BD-095 ("`migrate-v10-to-v11.sh` two-phase
`--dry-run` / `--apply` / `--resume` workflow"), part of Batch 21c per
the 2026-05-15 review/fix cycle memory revision.

## Scope

- **BD:** BD-095
- **Original commit:** `735c152` (2026-05-10) "fix: v11 — BD-095 two-phase
  migrator workflow (--dry-run / --apply / --resume) (Batch 13 part 1) +
  POQ-1/POQ-2 doc updates"
- **In-scope files (per `git show --stat 735c152`):**
  - `scripts/lib/migrate-v10-to-v11/dry-run.sh` (NEW, +216)
  - `scripts/lib/migrate-v10-to-v11/apply.sh` (NEW, +384)
  - `scripts/lib/migrate-v10-to-v11/resume.sh` (NEW, +252)
  - `scripts/migrate-v10-to-v11.sh` (+148 / -2)
  - `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (NEW, +328)
  - `supporting-docs/MERGE-STRATEGY.md` (+23)
  - `supporting-docs/MIGRATION-v10-to-v11.md` (+7)
  - `IMPLEMENTATION-REPORT-BD-095.md` (now under
    `maintenance-docs/archive/v11/`)
- **Snapshot judged:** state of files AT current HEAD (post-`735c152`
  with downstream BD-101 / BD-104 / BD-139 / BD-144 / BD-147 / BD-165
  edits), with attention to the BD-095 contract (modes, fingerprint,
  sentinels, freshness gate, forward-only resume, bare-invocation
  back-compat). Edits introduced by sibling/successor BDs are flagged
  only when they regress or interact with BD-095's contract.
- **Out of scope:** all other BDs except where they directly compose
  with BD-095 (BD-101 gates, BD-119 framework, BD-104 rename, BD-144
  capability translation, BD-165 decompose). Stale references in
  framework code that predate BD-095 but were not updated when BD-095
  shipped ARE in scope (the "what BD-095 missed" question).

## Methodology

- Read the BD-095 entry in `BACKLOG.md` and the archived
  `IMPLEMENTATION-REPORT-BD-095.md`.
- Read all five BD-095 source artifacts (`dry-run.sh`, `apply.sh`,
  `resume.sh`, `migrate-v10-to-v11.sh`, `test-migrate-v10-to-v11-dry-run.sh`)
  at current HEAD.
- Cross-referenced against `scripts/lib/migrator-core.sh` +
  `migrator-stages.sh` (the BD-119 framework BD-095 wraps), `customization-preserve.sh`
  (the sidecar producer), `gate-1-dry-run-summary.sh` /
  `checkpoint.sh` (the BD-101 gates BD-095 hosts).
- Cross-referenced against `IMPLEMENTATION-PLAN-ADDENDUM.md` §1.2
  (the BD-095 spec) + §6.G / §6.H (the freshness + resolved-flag
  recommendations).
- Cross-referenced against `supporting-docs/MERGE-STRATEGY.md` §A1 and
  `supporting-docs/MIGRATION-v10-to-v11.md` (the user-facing surface
  BD-095's UX promises rest on).
- Applied the 6 review dimensions and touch-point classification from
  `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Risk dimensions
  weighted per the prompt: idempotency of `--apply` / `--resume`;
  failure-loud behavior on corrupt or partial state; UX of `--resume`
  at unexpected entry points; round-trip fidelity of `--dry-run`;
  state-file lifecycle; composition with BD-101.
- DID NOT read any prior `PACK-REVIEW-*.md` per prompt directive.

## Findings

### F1 — Dry-run fingerprint covers a *subset* of the customization surface

- **Severity:** MUST
- **Dimension:** (a) completeness / (f) concept-specific (round-trip safety)
- **Touch-point class:** SHARED-RW (the customization surface is read by
  the manifest engine, the framework's `_stage_dispatch`, the BD-088
  preserve library, and BD-095's fingerprint comparator — multiple
  concepts touch the same artifact set).
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/dry-run.sh` lines 85–96 hardcode the
    "explicit list" as `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
    `.codex/config.toml`, `BACKLOG.md` and the "sweep dirs" as
    `.claude/agents`, `.codex/agents`, `.gemini/agents`.
  - `scripts/migrate-v10-to-v11.sh` `migrator_manifest` lines 89–106
    lists 13 `transform` rows including `.claude/settings.json`,
    `.mcp.json.example`, `.codex/config.toml.example`,
    `.codex/requirements.toml`, `.gemini/.env`, `.gemini/settings.json`,
    plus the per-CLI `agents/` sweeps.
  - `scripts/lib/migrator-core.sh` lines 471–513 already exposes a
    canonical surface map via `migrator_target_surface_for_version vN`
    — exactly the API BD-095's fingerprint should consume per
    architecture §9.2 ("avoid duplicating surface knowledge").
  - The BD-095 implementation report §7 acknowledges the "v10 customization
    surface" comes from `migrator_target_surface_for_version v10
    adapted to file-level granularity" but the actual code does not
    call that function — it inlines a smaller, stale duplicate.
- **Description:** The freshness gate's whole job is to detect
  working-tree drift between `--dry-run` review and `--apply`. If the
  user opens `.claude/settings.json` (a `transform` row in the manifest)
  and edits it AFTER the dry-run report was rendered, `--apply` will
  proceed silently — the modified file is not in the fingerprint.
  Same for `.gemini/.env`, `.codex/requirements.toml`, the two `.example`
  files, `.gemini/settings.json`, and `.mcp.json.example`. The dry-run
  report no longer reflects what `--apply` will do, but the freshness
  gate says OK. This violates the contract ("`--apply` rejects stale
  reports", `IMPLEMENTATION-PLAN-ADDENDUM.md` line 363 + §6.G) and
  breaks the round-trip safety principle (CONCEPTUAL-REVIEW-METHODOLOGY
  §design-best-practice 2).
- **Suggested fix:** Replace the hardcoded `explicit` + `sweep_dirs`
  arrays in `dry-run.sh` lines 85–96 with `migrator_target_surface_for_version
  "$MIGRATOR_FROM_VERSION"`. Each non-directory entry becomes an
  "explicit" file; each directory entry becomes a sweep. The framework
  surface for `v10` already lists trinity + `.codex/config.toml` +
  `BACKLOG.md` + the three `agents/` dirs; expand it to include every
  `transform`-class manifest row not already covered (the seven
  files named above). Then BD-088 / BD-119 own the surface definition
  in one place and BD-095 inherits drift detection automatically when
  v11→v12 ships. Add a regression test under
  `test-migrate-v10-to-v11-dry-run.sh` Group 3 case 3.4: "drift on
  `.claude/settings.json` triggers freshness FAIL".

### F2 — Framework `--help` and idempotency error message are stale post-BD-095

- **Severity:** SHOULD
- **Dimension:** (c) touch points + cross-concept impact
- **Touch-point class:** SHARED-RO (the framework usage / error strings
  are read by users; BD-095 didn't update them but is the reason they
  changed)
- **Evidence:**
  - `scripts/lib/migrator-core.sh` lines 244–245 (the framework `--help`
    output): `"--apply       Default mode (full migration); reserved for
    BD-095 two-phase"` and `"--resume      Resume an interrupted
    migration; reserved for BD-095 (errors today)"`.
  - `scripts/lib/migrator-stages.sh` line 133 (the idempotency error):
    `die "to re-run the migration, restore from the backup at
    $_MIGRATOR_BACKUP_DIR first; --resume is reserved for BD-095 and
    not yet implemented" "$EXIT_ALREADY_MIGRATED"`.
  - `scripts/lib/migrator-core.sh` lines 271–283 (the framework's
    `--resume` arg-parser branch): `die "--resume is per-adapter; this
    framework call path was not intercepted by the adapter ..." `. This
    one is correct (it's the framework's escape hatch for adapters that
    didn't intercept `--resume`), but the `--help` and idempotency
    strings are now outright wrong.
- **Description:** A user who runs `migrate-v10-to-v11.sh --help`
  reads "`--apply` reserved for BD-095" and "`--resume` reserved for
  BD-095 (errors today)". BD-095 shipped 2026-05-10 — both flags work
  today. Worse, when the framework's S0 idempotency check fires
  (re-run on already-migrated tree), the user is told `--resume` is
  not yet implemented. They restore from backup unnecessarily — the
  correct guidance is to use `--resume` (when paused) or `restore-from-backup`
  (when not paused). This is the BD-095-vs-`--apply`-after-pause UX
  bug (see F4 for the related case).
- **Suggested fix:** In `migrator-core.sh` `_migrator_usage` (lines
  236–254), replace the two stale lines with accurate descriptions:
  ```
  --dry-run     Preview only; produces report + dispositions.tsv +
                a working-tree fingerprint. No project files are
                mutated.
  --apply       Default. Refuses to run unless a fresh dry-run
                fingerprint exists; pauses cleanly before S4 if
                conflicts are produced.
  --resume      Continue a paused migration after sidecar
                reconciliation. Forward-only; per-adapter (the
                v10→v11 adapter implements it; future adapters
                may opt out).
  ```
  In `migrator-stages.sh` line 133, replace the `--resume is reserved
  for BD-095 and not yet implemented` substring with `--resume is the
  forward-only continuation after a paused dispatch (see
  --help)`. BD-095's commit could/should have updated these in the
  same commit; that they remain stale 5+ days later is the gap this
  retro surfaces.

### F3 — Bare invocation does not detect a paused state; user gets a confusing S1 backup-dir failure

- **Severity:** SHOULD
- **Dimension:** (b) edge cases (bounded — paused state is a documented
  user path)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/migrate-v10-to-v11.sh` lines 695–744 (the bare-invocation
    branch). The code checks `dry-run.fingerprint` presence/freshness/sha;
    it does NOT check `sentinels/stage-S3.paused` presence.
  - `scripts/lib/migrator-stages.sh` lines 149–151 (`_stage_backup`
    refusal): `if [[ -d "$_MIGRATOR_BACKUP_DIR" ]]; then fail_stage S1
    "backup directory already exists: $_MIGRATOR_BACKUP_DIR — rename it
    (mv ...) or remove it before re-running"`.
  - `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` Group 6 (lines
    300–315) tests bare-invocation only on a fresh target. No test
    exercises bare-after-pause.
- **Description:** Sequence:
  1. User runs `migrate-v10-to-v11.sh <target>` (bare).
  2. Apply pauses with conflicts (S3.paused written, exit 0).
  3. User reconciles the sidecars but forgets to type `--resume`.
  4. User runs `migrate-v10-to-v11.sh <target>` again (bare).
  5. Bare flow sees fresh fingerprint (still within 24 h, sha unchanged
     because the user only touched sidecar files which aren't in the
     hardcoded surface — see also F1) → skips auto-dry-run.
  6. Calls `migrate_v10_to_v11_apply_run` → freshness OK → wipes
     `dispositions.tsv` + `report.md` → calls `migrator_run --apply`.
  7. Framework S0 preflight passes (no dispositions.tsv).
  8. Framework S1 backup → `<state-dir>-backup` already exists → `fail_stage
     S1` with the "backup directory already exists; rename it or remove
     it" message.
  The user is told to rename or remove the backup. The actual right
  answer is `--resume`. This is a real-world UX trap (the test fixture
  in Group 4 always uses `--resume` directly). The bare path is the
  pre-BD-095 single-shot UX; users who learned that pattern are most
  likely to bare-rerun in this scenario.
- **Suggested fix:** Insert a paused-state check at the top of the
  bare branch (before line 717 in `migrate-v10-to-v11.sh`):
  ```
  _paused="$_target_abs/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
  if [[ -f "$_paused" ]]; then
      printf 'error: a paused migration exists at %s\n' "$_paused" >&2
      printf '\n  Resolve the listed sidecars and run:\n' >&2
      printf '    PACK=%s scripts/migrate-v10-to-v11.sh --resume %s\n\n' \
          "${PACK:-/path/to/pack}" "$_target_abs" >&2
      printf '  Or to start over, restore from %s and re-run.\n' \
          "$_target_abs/.pack-migrate-v10-to-v11-backup" >&2
      exit "${EXIT_INTERNAL:-99}"
  fi
  ```
  Add a Group 6 case 6.3 to the regression test:
  "bare-after-pause errors with --resume guidance".

### F4 — `--apply` after pause produces no recovery guidance; same trap as F3 via the explicit-flag path

- **Severity:** SHOULD
- **Dimension:** (b) edge cases (bounded)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/apply.sh` `migrate_v10_to_v11_apply_run`
    (lines 265–408) does not check `sentinels/stage-S3.paused` before
    proceeding. It performs freshness check, installs hooks, wipes
    dispositions.tsv, then calls `migrator_run --apply`.
  - Same chain as F3 from step 6 onward (S1 backup-dir-exists failure,
    no `--resume` hint).
- **Description:** Identical UX trap as F3 but via `--apply` instead of
  bare. A user who explicitly types `--apply` after pause gets the same
  unhelpful S1 backup-dir error. The freshness gate's actionable
  messages (apply.sh lines 70–84, 116–128, 137–154) all carefully
  guide the user toward the right next step; this case bypasses all of
  them and falls through to a low-level framework error. Both apply
  modes (bare and `--apply`) need the same guard.
- **Suggested fix:** Add the paused-state check to
  `migrate_v10_to_v11_apply_run` immediately after target resolution
  and before the freshness check (around line 277):
  ```
  if [[ -f "$state_dir/sentinels/stage-S3.paused" ]]; then
      printf 'error: --apply refused; a paused migration exists\n' >&2
      printf '  paused-sentinel: %s\n\n' \
          "$state_dir/sentinels/stage-S3.paused" >&2
      printf '→ Resolve the listed sidecars then run:\n' >&2
      printf '    PACK=%s scripts/migrate-v10-to-v11.sh --resume %s\n' \
          "${PACK:-/path/to/pack}" "$target" >&2
      exit "$EXIT_INTERNAL"
  fi
  ```
  Add a Group 3 case 3.4: "apply-after-pause errors with --resume
  guidance". Single fix covers both F3 and F4 via the explicit-`--apply`
  path; F3's bare-invocation guard remains a separate concern because
  the bare path bypasses `apply.sh`'s pre-flight before reaching
  `migrate_v10_to_v11_apply_run` (the bare branch could either delegate
  to a unified pre-flight helper or carry a parallel check).

### F5 — Duplicate mode flag is silently mis-routed

- **Severity:** SHOULD
- **Dimension:** (b) edge cases / (e) design best practice (typed errors
  with named recovery verb — V1 §9 / V3 §27.1)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/migrate-v10-to-v11.sh` lines 645–663: when more than one
    of `--dry-run` / `--apply` / `--resume` is passed, the FIRST is
    captured as `_mode` and the SECOND is pushed to `_passthru`.
  - The comment at line 654–656 says "let the framework's parser reject
    the duplicate downstream", but the framework's parser will silently
    re-set `_MIGRATOR_DRY_RUN` / `_MIGRATOR_MODE` flags as it sees
    them (`migrator-core.sh` lines 264–272). For example,
    `--dry-run --apply` runs in dry-run mode (`_MIGRATOR_DRY_RUN=1`)
    but with `_MIGRATOR_MODE="apply"` — a contradictory state that the
    framework doesn't validate. `--dry-run --resume` causes the
    framework to fail with "--resume is per-adapter; this framework
    call path was not intercepted by the adapter ..." — confusing
    because the user did pass `--resume` but as a passthru.
- **Description:** Duplicate mode flags should fail loud at the
  dispatcher (where the contract is owned), not silently mis-route
  through the framework parser whose validation is incomplete. The
  pack memory rule "no silent retry / no silent fallback" (V3.3 §5.6)
  applies — silent acceptance of contradictory state is a fallback.
- **Suggested fix:** Replace the silent `_passthru+=("$_a")` at
  line 657 with an immediate error:
  ```
  printf 'error: multiple mode flags: %s and %s (only one of --dry-run / --apply / --resume permitted)\n' \
      "$_mode" "$_a" >&2
  exit "${EXIT_INTERNAL:-99}"
  ```
  Add a regression test case under Group 5 or a new Group 7 covering
  each of the six pairwise combinations.

### F6 — `customization_report` failure during dry-run is silently swallowed

- **Severity:** NIT
- **Dimension:** (e) design best practice 3 (typed errors)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/dry-run.sh` lines 183–190:
    `customization_report ... >/dev/null 2>&1 || true`. Both stderr
    and the non-zero exit code are silenced.
  - Gate 1 (`gate-1-dry-run-summary.sh` lines 55–60) detects the
    missing `report.md` and emits `[FAIL]` — so the user does see a
    failure, just with no diagnostic about WHY the renderer failed.
- **Description:** If the BD-088 renderer ever fails (malformed
  `dispositions.tsv` row, missing helper, awk error), the user sees
  Gate 1 FAIL with `report.md not rendered` but no actionable cause.
  The whole point of typed errors with named recovery verb is the
  user gets enough context to fix or escalate — silencing the
  underlying error defeats this.
- **Suggested fix:** Capture stderr to a known file and surface it on
  failure:
  ```
  local render_err
  render_err=$(mktemp)
  if ! customization_report \
          "$state_dir/dispositions.tsv" \
          "$state_dir/report.md" \
          "${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration customization report (--dry-run preview)" \
          2>"$render_err"; then
      warn "customization_report failed: $(head -5 "$render_err")"
      warn "see $render_err for full output"
      # do not delete render_err — Gate 1 FAIL will reference it
  else
      rm -f "$render_err"
  fi
  ```

### F7 — Stale `*.merge-conflict` aliasing comment in apply.sh

- **Severity:** NIT
- **Dimension:** (c) touch points
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/apply.sh` line 47: `# *.merge-conflict
    (a.k.a. *.${MIGRATOR_OWN_SIDECAR_SUFFIX}) sidecars`.
  - The actual sidecar suffix is `.v10-customized` (declared at
    `scripts/migrate-v10-to-v11.sh` line 76 — `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`).
    `*.merge-conflict` is the spec's generic synonym (POQ-2 in the
    impl report). It does not appear anywhere in the user-facing
    output or in the actual file system.
- **Description:** POQ-2 closure (per the BD-095 implementation report
  §11) updated the user-facing docs to drop bare `*.merge-conflict`
  in favor of the parameterized form. The remaining `*.merge-conflict
  (a.k.a. ...)` comment in apply.sh is a documentation artifact from
  the spec era. Keeping it in the code comment confuses future readers
  about whether `*.merge-conflict` is a real path pattern.
- **Suggested fix:** Replace line 47 with `# *.${MIGRATOR_OWN_SIDECAR_SUFFIX}
  sidecars (currently *.v10-customized for the v10→v11 adapter)`.

### F8 — `_stage_libs` wrapper writes the fingerprint even on `--apply` framework failure between S0 and S2

- **Severity:** NIT
- **Dimension:** (a) completeness (state-file lifecycle)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/apply.sh` lines 393–402: the
    `_stage_libs` wrapper restores the stashed fingerprint
    unconditionally after the framework's `_stage_libs` runs.
  - `_stage_libs` (in `migrator-stages.sh` line 195) is the third
    stage (S2). If S0 (preflight) or S1 (backup) fails, the wrapper
    never runs — the EXIT trap fires and the fp_stash mktemp file is
    leaked (see also F9). If S2 succeeds and S3 fails, the
    fingerprint is restored even though the run failed; the user can
    `--resume` with a freshness-validated fingerprint that matches a
    half-done run.
- **Description:** Subtle interaction: if dispatch (S3) fails for any
  reason, the `dry-run.fingerprint` is restored to the (now-half-mutated)
  state dir. The user re-running `--apply` will hit either S0
  idempotency (if S3 wrote any rows) or S1 backup-dir-exists. They
  cannot `--resume` because S3.paused was not written (S3 failed, not
  paused). Restoring the fingerprint on failed S3 is harmless (no
  --apply will succeed against a working tree where S3 already mutated
  files), but it's also pointless and slightly misleading. The
  fingerprint should only be restored on successful S6 — at which
  point it's also irrelevant because the migration completed. The
  whole stash/restore pattern exists because `_stage_libs` does
  `rm -rf $STATE_DIR`; a cleaner design would be to NOT wipe the
  state dir for files the apply path needs (the fingerprint).
- **Suggested fix:** Either (a) gate the restore on S3 success (move
  the `cp "$fp_stash" ...` from the `_stage_libs` wrapper to a new
  hook inside `_stage_dispatch`'s success path or
  `migrator_post_dispatch_hook`), or (b) make `_stage_libs` not wipe
  the fingerprint specifically. Option (b) is cleaner — add a
  preserve-list to the framework's state-dir reset:
  ```
  # In migrator-stages.sh _stage_libs, replace `rm -rf $_MIGRATOR_STATE_DIR`
  # with a selective reset that preserves dry-run.fingerprint.
  ```
  This belongs in BD-119's framework, not BD-095's adapter — flag as
  "framework cleanup; BD-095 currently works around with a stash".

### F9 — Fingerprint stash mktemp leaks on early framework failure

- **Severity:** NIT
- **Dimension:** (a) completeness (state-file lifecycle)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/apply.sh` line 344:
    `fp_stash=$(mktemp)`. Line 406: `rm -f "$fp_stash"`.
  - The `rm` only runs after `migrator_run --apply` returns. If the
    framework `exit`s mid-run (any `die` or `fail_stage`), the temp
    file in `$TMPDIR` is leaked.
- **Description:** Cosmetic but the BD-095 ship comment in the impl
  report §13 mentions "git status --short" hygiene at handoff; the
  `$TMPDIR` leak is the inverse — invisible to git but a real
  filesystem leak on every failed apply. The fix is one trap.
- **Suggested fix:** Add a local trap inside
  `migrate_v10_to_v11_apply_run`:
  ```
  fp_stash=$(mktemp)
  trap "rm -f '$fp_stash'" RETURN
  cp "$fp_src" "$fp_stash"
  ```
  bash 3.2 compatible; the trap fires when the function returns by any
  path including `exit` from a child callee. (Note: `RETURN` trap fires
  on function return, not on `exit`. For `exit` coverage, register
  with `EXIT` and `unset` in the `trap` body to avoid double-firing
  with the framework's existing EXIT trap. A simpler safe pattern:
  `eval "_v10_v11_apply_cleanup() { rm -f '$fp_stash'; }"; trap
  _v10_v11_apply_cleanup EXIT`. Confirm the EXIT trap composes with
  `_migrator_exit_trap` per `migrator-core.sh` line 185.)

### F10 — `--resume` re-runs `_stage_relocations` and `_stage_artifact_installs` despite the v10→v11 adapter declaring them empty

- **Severity:** NIT
- **Dimension:** (a) completeness (round-trip / no-op idempotency)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/resume.sh` lines 235–236 call
    `_stage_relocations` and `_stage_artifact_installs` directly.
  - `scripts/migrate-v10-to-v11.sh` lines 120–128:
    `migrator_relocations() { :; }` and `migrator_artifact_installs()
    { :; }` (both empty per the adapter's "everything happens in
    `migrator_post_dispatch_hook`" design).
  - `_stage_relocations` and `_stage_artifact_installs` (in
    `migrator-stages.sh` lines 260–272 + 352–363) gracefully no-op
    when adapter-declared rows are empty.
- **Description:** The two calls are no-ops by design but defensive
  programming favors not calling them (the adapter's contract is that
  all post-dispatch work lives in `migrator_post_dispatch_hook`).
  More importantly, if a future v11→v12 adapter does declare
  `migrator_relocations` rows, copy-pasting this resume.sh pattern
  would re-execute relocations — unsafe (double-rename). resume.sh
  is the v10→v11-specific adapter so the issue is contained today,
  but the pattern is fragile for v11→v12 reuse.
- **Suggested fix:** Either (a) drop the two calls (the v10→v11
  adapter's contract makes them no-ops, and any future per-version
  resume should be its own per-version file), or (b) leave them but
  add an explanatory comment noting they're no-ops here because the
  adapter declares them empty, and that future adapters with non-empty
  relocations / artifact_installs need to think carefully about resume
  semantics (was the relocation already done in apply.sh's S4 marking
  point? was it not?). Resume's forward-only contract assumes "S4..S6
  haven't run"; double-running relocations doesn't comport with
  forward-only.

### F11 — `_v10_v11_resume_classify_sidecars` runtime is unused: count loop iterates locally

- **Severity:** NIT
- **Dimension:** (e) design best practice 4 (composition over special
  cases)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/resume.sh` lines 43–57 define
    `_v10_v11_resume_classify_sidecars` returning `<status>\t<sidecar>`
    rows.
  - Lines 132–147 invoke it; lines 149–166 re-iterate the same rows
    via awk for the "Unresolved sidecars:" listing. The same
    classification work is done in two places.
- **Description:** Minor structural duplication. The unresolved-sidecar
  listing in the error message could come from a single pass over
  classification output, not a re-awk over `$classification`.
- **Suggested fix:** Consolidate:
  ```
  unresolved_list=$(printf '%s\n' "$classification" \
      | awk -F'\t' '$1 == "unresolved" {print "  " $2}')
  unresolved=$(printf '%s\n' "$unresolved_list" | grep -c '^  ' || true)
  ```
  Then the error block reuses `$unresolved_list` directly. Saves one
  awk invocation; reads cleaner.

### F12 — `--apply` recovery guidance always emits `${PACK:-/path/to/pack}` instead of a resolved PACK

- **Severity:** NIT
- **Dimension:** (e) design best practice 3 (named recovery verb)
- **Touch-point class:** SHARED-RO
- **Evidence:**
  - `scripts/lib/migrate-v10-to-v11/apply.sh` lines 77, 122, 148, 250
    all emit `"${PACK:-/path/to/pack}"`.
  - `scripts/lib/migrate-v10-to-v11/resume.sh` line 163 same.
- **Description:** The framework's S0 preflight already enforces PACK
  is set (`migrator-stages.sh` lines 66–69 — `die "PACK environment
  variable not set"`). By the time apply.sh's freshness check fires,
  PACK is guaranteed set. The fallback `:-/path/to/pack` is
  unreachable and renders as a real path-looking string in the
  error output. Users who copy-paste the recovery line will only
  realize PACK is unset if they happen to read carefully; the fallback
  string is a minor footgun.
- **Suggested fix:** Drop the fallback — `"$PACK"` directly. Same in
  resume.sh line 163. (The bare-invocation auto-rerun text in apply.sh
  line 250 — `say "  PACK=${PACK:-/path/to/pack} ..."` — is shown
  ONLY after S3 dispatch completed, so PACK is definitely set there.
  Same logic.)

## Coverage notes

- **What was IN scope but NOT reviewed:**
  - Detailed line-by-line analysis of `gate-1-dry-run-summary.sh` /
    `gate-2-phase-a-verify.sh` / `gate-3-phase-b-verify.sh`. These
    are BD-101's deliverable; BD-095 hosts them but doesn't own
    them. Touch points are flagged where the BD-095 contract feeds
    into the gate (Gate 1 inside `--dry-run`).
  - Performance / fingerprint computation cost on large trees. The
    sha-256 sweep is O(n) over the customization surface; with the
    F1 fix expanding the surface to ~13 files plus three sweep
    dirs, it remains trivially fast for any realistic project. No
    finding raised.
  - Backwards-compat with hypothetical pre-BD-095 callers passing
    `--apply` to the framework directly (bypassing the adapter
    dispatcher). Such a caller would land in the framework's
    `_migrator_parse_args` which sets `_MIGRATOR_MODE="apply"` and
    proceeds with no freshness check. That's by design — the
    framework predates BD-095 and the BD-095 contract attaches to
    the adapter, not the framework. Out of scope.

- **Why these were not pursued:** F1 is the dominant correctness
  finding; the rest are quality / UX. With F1 fixed and F2/F3/F4/F5
  surfaced for fix-or-defer, the BD-095 contract holds. No additional
  digging is warranted for the per-BD retro scope.

## Re-architect summary

No `ARCH` findings. All twelve findings are addressable inside BD-095's
existing module boundaries (the three lib files plus the dispatcher),
with one finding (F2) crossing into BD-119's framework module
(`migrator-core.sh` `--help` text + `migrator-stages.sh` idempotency
error message) — the suggested fix is mechanical text replacement and
does not require re-architecting either contract.

F8's underlying state-dir-wipe-then-restore pattern would benefit
from a small framework refinement (a preserve-list in `_stage_libs`),
but that's BD-119 cleanup, not a re-architect. F10's resume-replays-no-op-stages
pattern is a v10→v11-specific quirk; future per-version `resume.sh`
files will need their own design work and should not copy this one
verbatim.

## Severity rollup

| Severity | Count | Findings |
|---|---|---|
| BLOCKER | 0 | — |
| MUST | 1 | F1 |
| SHOULD | 4 | F2, F3, F4, F5 |
| NIT | 7 | F6, F7, F8, F9, F10, F11, F12 |
| ARCH | 0 | — |
| **Total** | **12** | |

The single MUST (F1, fingerprint surface incompleteness) is the
material correctness gap the original ship missed: the freshness gate
silently allows drift on any of the 7 manifest-listed files outside
the hardcoded subset. F2's stale `--help` / idempotency strings
mislead users away from BD-095's new capabilities. F3 / F4 are the
twin bare-after-pause and `--apply`-after-pause UX traps. F5 is the
silent duplicate-flag mis-routing. The seven NITs are quality /
hygiene polish.
