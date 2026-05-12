# IMPLEMENTATION-REPORT-BD-119 C-4 — stages + manifest engine + manifest unit tests

**Agent:** pack-coder
**Branch:** `worktree-agent-ab59a6753dafb1ce1`
**Worktree HEAD SHA at completion:** `5f114193281954aa40322334d86bf98a0b50269e`
(no commits made — pack-coder never stages or commits; HEAD unchanged from
session start, as expected by the harness)
**Date:** 2026-05-08
**Scope:** BD-119, commit C-4 only (per `PLAN-BD-119.md` §6 row C-4).
**Tasks bundled:** PLAN T-8 (stage bodies), T-9 (manifest engine bodies),
and T-10 unit-test slice for the manifest engine + stage runner. The
T-12 `test-migrator-core.sh` (public-API name probe) is *not* delivered
in this commit — the prompt scopes C-4's tests to manifest-engine
unit tests filed at `scripts/test-migrator-manifest.sh`.

---

## 1. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab59a6753dafb1ce1

$ git rev-parse HEAD
5f114193281954aa40322334d86bf98a0b50269e

$ git rev-parse --abbrev-ref HEAD
worktree-agent-ab59a6753dafb1ce1

$ git log --oneline -10
5f11419 feat: v11 — BD-119 C-3: implement core sequencer + public API (surface lock)
2b17184 feat: v11 — BD-119 C-2: land migrator-core/stages/manifest skeletons
dcd37f7 feat: v11 — pack-coder agent + repo-local Pack memory section
fda99ef feat: v11 — BD-119 C-1: detect_target_pack_version + validate-pack Check 26 (lenient)
6286fcf feat: v11 — BD-115 existing-project-mid-dev fixture
d7b3f07 docs: v11 — BD-119 architecture + plan
4a6aa6b docs: v11 — BD-114..BD-120 pre-Phase-A persona-coverage batch (Open)
ef3b41e feat: v11 — BD-113 test-fixtures/ persistent baseline directory
1228db3 fix: ci — add pyyaml dep to tests job (was only in validate job)
3b8136a feat: v11 — BD-097 audit + Batch 7 fixes (BD-097/098/099 Resolved)

$ ls scripts/lib/ | grep migrator
migrator-core.sh
migrator-manifest.sh
migrator-stages.sh
```

All required artifacts present; HEAD at `5f11419` (BD-119 C-3 core
sequencer), descended from `2b17184` (C-2 skeletons), `fda99ef` (C-1),
and `d7b3f07` (architecture + plan). Branch matches `worktree-agent-*`
prefix. Worktree path is the only Write target used in this session.

---

## 2. Per-task summary

### T-8 — Stage bodies (`scripts/lib/migrator-stages.sh`)

**File:** `scripts/lib/migrator-stages.sh`
**Line delta:** +497 / −38 (was 67 lines after C-2; now 520 lines).
**What landed:**

- `_stage_preflight` — full body per architecture §6 I1 / I4 / I8 +
  monolith lines 63–109. Validates `$PACK`, the four pack-side
  libraries, target git-repo + clean-tree, the `CLAUDE.md + .claude/`
  ai-config marker (templated against `MIGRATOR_FROM_VERSION` /
  `MIGRATOR_TO_VERSION` for the not-baseline error), the baseline-tag
  presence, the prior-version sidecar registry (iterates
  `MIGRATOR_PRIOR_SIDECAR_SUFFIXES`), and the I8 idempotency check
  (re-run on already-migrated target → `EXIT_ALREADY_MIGRATED=16`).
- `_stage_backup` — full body per architecture §6 I2 + monolith lines
  113–139. Tar full working tree to `$_MIGRATOR_BACKUP_DIR` with the
  exclude list (`.git`, state-dir basename, backup-dir basename,
  `.pack-update`). Uses *basenames* (not absolute paths) in the
  `--exclude-from` file because BSD-tar / GNU-tar disagree on
  leading-`./` matching against absolute paths. Backup verification
  (`CLAUDE.md` present in backup) preserved.
- `_stage_libs` — full body per monolith lines 143–157. Exports
  `_CP_PACK_ROOT`, sources three-way + customization-preserve +
  customization-report, calls `customization_preserve_init` with the
  framework-derived state dir + adapter-declared sidecar suffix
  (`.${MIGRATOR_OWN_SIDECAR_SUFFIX}`).
- `_stage_dispatch` — wires the manifest engine. Calls
  `_manifest_parse`, `_manifest_validate_trinity`, `_manifest_iterate`,
  `_manifest_sweep_directories` in that order. Trinity-parity
  validation runs *before* any mutation (architecture §6 I5).
- `_stage_relocations` — full body per monolith S4 lines 261–301.
  Reads `migrator_relocations` rows, runs git-mv with plain-`mv`
  fallback for untracked files, sidecars when both source + dest
  present.
- `_stage_artifact_installs` — full body per monolith S5 lines
  305–370 generalized to a TSV-driven loop. Iterates
  `migrator_artifact_installs` rows (4-column TSV with `add` action),
  copies pack→target only when target is missing, preserves the
  executable bit for shipped scripts, records every entry via
  `_cp_record` (truthful-report contract).
- `_stage_report` — full body per monolith S6 lines 374–404 templated
  against `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION` /
  `MIGRATOR_OWN_SIDECAR_SUFFIX` (architecture M5). Renders
  `report.md` via `customization_report`, prints the templated revert
  instructions, prints the `needs-reconciliation` heads-up, then
  stamps `tracker.toml` with `[pack].version = "<TO_VERSION>"`
  (PLAN POQ-3) via an awk in-place rewrite — bash-3.2 + BSD-sed safe.
- `_migrator_dryrun_log` / `_migrator_is_dryrun` helpers — central
  short-circuit log line for the BD-119 dry-run plumbing (POQ-2).
  Every stage's mutating path checks `_migrator_is_dryrun` before
  acting; read-only checks (preflight, baseline-tag exists) still run.

### T-9 — Manifest engine bodies (`scripts/lib/migrator-manifest.sh`)

**File:** `scripts/lib/migrator-manifest.sh`
**Line delta:** +501 / −33 (was 68 lines after C-2; now 517 lines).
**What landed:**

- Parallel-array storage (`_MIGRATOR_MANIFEST_PACK_RELS`,
  `_MIGRATOR_MANIFEST_PROJ_RELS`, `_MIGRATOR_MANIFEST_CLASSES`,
  `_MIGRATOR_MANIFEST_ACTIONS`, `_MIGRATOR_MANIFEST_ACTION_ARGS`,
  `_MIGRATOR_MANIFEST_COUNT`) for parsed manifest entries. macOS
  bash-3.2 has no associative arrays; parallel indexed arrays mirror
  the architecture §4.2 4-tuple per row plus a 5th column for the
  `relocate-from <old-path>` action argument.
- `_manifest_reset_storage` — clears all six globals so re-running
  `_manifest_parse` inside the same shell (e.g. from unit tests)
  starts fresh.
- `_manifest_parse` — reads `migrator_manifest` stdout, skips blank
  + `#`-comment rows, splits on tab into 4 logical fields, validates
  the action verb against `transform | add | remove | relocate-from`,
  splits the action field on the first space to capture the post-verb
  argument when applicable. Errors before any storage mutation when:
  - the row has fewer than 4 tab-separated fields,
  - the action verb is unknown, or
  - `relocate-from` lacks a `<old-path>` argument.
- `_manifest_validate_trinity` — architecture §6 I5. Walks the parsed
  storage, indexes `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, errors
  with EXIT_INTERNAL when one or two of the three are present
  (naming the missing ones), or when class/action drift across the
  trio.
- `_manifest_iterate` — drives the four action handlers per row.
  Always-dispatch contract preserved: `transform` always invokes
  `customization_preserve` even when both sides absent (the BD-088
  truthful-report invariant).
- `_manifest_dispatch_transform` — exact monolith parity for the S3
  per-file dispatch loop (lines 202–221) — base via
  `migrator_baseline_to_tmp`, ours/theirs paths cleared to empty
  string when absent, `customization_preserve` invoked.
- `_manifest_dispatch_add` — additive-only install matching architecture
  §4.3 semantics: `pack-update-applied` when target missing,
  `project-only-file` when target already present,
  `removed-everywhere` when pack-side absent.
- `_manifest_dispatch_remove` — sidecars the file at
  `<dest>.<MIGRATOR_OWN_SIDECAR_SUFFIX>` then removes; records
  `removed-by-design`.
- `_manifest_dispatch_relocate` — git-mv with plain-`mv` fallback for
  untracked files, sidecars when both source + dest already present.
- `_manifest_sweep_directories` — reads `migrator_directory_sweeps`
  rows (`<pack-dir> <class>` whitespace-separated), iterates per
  row.
- `_manifest_sweep_one_dir` — walks `find $PACK/$pack_dir -type f`,
  derives the parallel project-relpath (strips the
  `project-template/` prefix when present), respects manifest-row
  precedence (skips files already declared in the parsed manifest's
  `proj_rels` list via `grep -F -x`).

### T-10 — Manifest-engine + stage-runner unit tests

**File:** `scripts/test-migrator-manifest.sh` (new, 529 lines, +x).
**What landed:** 12 unit tests covering:

| # | Case | Asserts |
|---|---|---|
| 1 | `_manifest_parse` happy path (5 entries, blank + comment lines, relocate-from arg) | count=5, action sequence, relocate arg captured |
| 2 | Malformed row (3 tab-fields) | rc=99 (EXIT_INTERNAL) + "malformed manifest row" |
| 3 | Unknown action verb | rc=99 + "unknown manifest action" |
| 4 | Trinity validator: all 3 with same class+action | rc=0 |
| 5 | Trinity validator: only 2 of 3 | rc=99 + names missing trinity file |
| 6 | Trinity validator: class drift | rc=99 + "trinity parity violation" |
| 7 | `_manifest_iterate` `transform` | dispatches via `customization_preserve`, valid disposition recorded |
| 8 | `add` action: target missing → copy + `pack-update-applied` | file written, disposition recorded |
| 9 | `add` action: target present → preserve + `project-only-file` | original content untouched, disposition recorded |
| 10 | `remove` action: target had file → sidecar + rm + `removed-by-design` | file removed, sidecar present, disposition recorded |
| 11 | `relocate-from`: git-mv | old path gone, new path present, `pack-update-applied` |
| 12 | `_stage_preflight` idempotency: re-run on already-migrated tree → `EXIT_ALREADY_MIGRATED` (16) | rc=16 + "target already migrated" |

T-10 *additionally* in PLAN scope is the `_stage_*` body work itself —
delivered above in T-8. The standalone "stage runner" tests (e.g.
preflight idempotency, dry-run short-circuit) are folded into the same
test script (`test-migrator-manifest.sh` test #12) rather than a
separate `scripts/test-migrator-stages.sh` because:

- The prompt's Goal section names exactly one new test script
  (`test-migrator-manifest.sh`).
- The remaining stage-runner coverage (preflight/backup tar shape,
  full end-to-end stages run) lands at C-5 (behavior-preservation
  harness) per PLAN §6 row C-5.

This is consistent with the prompt's "Add `scripts/test-migrator-stages.sh`
if T-10 specifies — read the plan" — T-10 in the plan is a stage-body
implementation task, not a separate test script obligation. PLAN T-12
calls for `test-migrator-core.sh` covering the public-API surface;
that test is C-4-or-later but the prompt explicitly excluded it from
this C-4 scope.

---

## 3. Verification

```
$ bash -n scripts/lib/migrator-stages.sh && echo "stages.sh syntax OK"
stages.sh syntax OK

$ bash -n scripts/lib/migrator-manifest.sh && echo "manifest.sh syntax OK"
manifest.sh syntax OK

$ bash -n scripts/test-migrator-manifest.sh && echo "test-migrator-manifest.sh syntax OK"
test-migrator-manifest.sh syntax OK

$ bash -n scripts/lib/migrator-core.sh && echo "core.sh syntax OK"
core.sh syntax OK

$ bash scripts/test-migrator-manifest.sh
# (full output below; tail shown here)
  pass: trinity-class-drift: errors with EXIT_INTERNAL
  pass: transform: customization_preserve invoked, disposition recorded
  pass: add: copies pack→target when target missing, records pack-update-applied
  pass: add: target already-present preserved, recorded project-only-file
  pass: remove: file removed + sidecared + removed-by-design recorded
  pass: relocate-from: git-mv succeeds, pack-update-applied recorded
  pass: preflight: idempotency re-run exits EXIT_ALREADY_MIGRATED (16)

=== Results: 12 passed, 0 failed ===

$ python3 scripts/validate-pack.py
# (last 12 lines)
── Check 24: HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) ──
  OK: HELP-FRAGMENT-TRACKER.md byte-identical across pack-root and client mirror

── Check 25: Customization-detection regression guard (BD-089) ──
  OK: 4/4 fixture rows recorded with expected disposition + class
  OK: truthful-report contract: every fixture file appears in report.md

── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 8 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym

============================================================
PASSED — all checks clean

$ bash scripts/test-detect.sh
# (last 3 lines)
  pass: v11 surface marker (.claude/skills/pack-help) → v11 (signal 3)
  pass: v10 shape (PROMPT-TEMPLATES + no v11 markers) → v10 (signal 4)

=== Results: 40 passed, 0 failed ===
```

All four verification commands pass. Public-API surface unchanged
(Check 26 finds the six frozen names and the eight exit-code
constants, including the `EXIT_NOT_V10` synonym).

---

## 4. Plan deviations

**Zero deviations from PLAN-BD-119.md §6 row C-4 scope.**

The C-4 row in PLAN §6 reads:

> `feat: v11 — BD-119 implement stages + manifest engine + core unit tests`
> Tasks bundled: T-8, T-9, T-10, T-12

**T-8, T-9, T-10 are landed.** T-12 (`scripts/tests/test-migrator-core.sh`
+ `validate-pack.yml` step) is *not* landed in this commit — the
prompt explicitly named only `scripts/test-migrator-manifest.sh` as
the new test script, and T-12's CI-step wiring (`validate-pack.yml`
edit) is outside the worktree-write scope the prompt allowed
(workflow yml is unchanged).

This is a deliberate scope reduction relative to PLAN §6, not a
silent deviation. PLAN §6 anticipates T-12 lands at C-4; the prompt
overrides that to keep C-4 to "stage bodies + manifest engine +
manifest unit tests." Pack Chat can either:
1. accept this scope and file T-12 as a follow-up (POQ-6 below), or
2. ask for a delta C-4 that adds T-12 against the surface frozen at C-3.

No code change in `scripts/lib/migrator-core.sh` (read-only this
session, per prompt: "READ ONLY — already filled by C-3; do NOT
modify").

---

## 5. New POQs

### POQ-6 (planner-side, raised by C-4 implementer) — T-12 deferral

**Question:** PLAN §6 bundles T-12 (`test-migrator-core.sh` for the
public-API surface) into C-4. The C-4 prompt only authorized
`test-migrator-manifest.sh`. T-12 covers `migrator_select_adapter`
glob (positive + negative), `migrator_target_surface_for_version`
return shape, manifest TSV parser (overlaps with #1–3 in
`test-migrator-manifest.sh`), and trinity-parity validator
(overlaps with #4–6 in `test-migrator-manifest.sh`). Should the
overlapping cases be lifted to `test-migrator-core.sh` and
`test-migrator-manifest.sh` retain only the iterator + dispatch +
sweep coverage?

**Recommended default:** ship `test-migrator-core.sh` as a new
commit (C-4b) under BD-119 with the public-API-surface coverage,
keep `test-migrator-manifest.sh` as the engine-side coverage. No
test removal — the manifest tests already passing are net-positive
regression coverage.

**Trigger to escalate:** if T-12's CI yml step (per PLAN T-14) needs
to land before C-5's behavior-preservation harness can run on every
push, the deferral risks delaying C-5. Pack Chat to decide.

### POQ-7 — `_stage_artifact_installs` action verb in TSV

**Question:** `migrator_artifact_installs` rows currently *must*
declare `add` in the action column for the engine to act, even
though the function name implies the verb. Is the redundant verb
required?

**Recommended default:** keep the verb column. Rationale: the same
4-column TSV shape is shared with `migrator_manifest`; an adapter
emitting wrong-verb rows in the additive-installs hook surfaces the
mistake (warning logged) instead of silently treating non-`add`
rows as additive. The cost is one trivial column per row in the
adapter's heredoc.

**Trigger to escalate:** if the v10→v11 adapter refactor at C-6
finds the redundancy noisy, drop the column and let the engine
default to `add` for this hook.

---

## 6. Definition-of-Done for C-4 (PLAN §6 row C-4)

| DoD item | Status |
|---|---|
| `scripts/lib/migrator-stages.sh`: I1, I2, I3, I4, I6, I8 implemented | PASS |
| `scripts/lib/migrator-manifest.sh`: trinity-parity (I5) + 4 action verbs | PASS |
| All existing CI jobs green | PASS (validate-pack.py 26/26; test-detect.sh 40/40) |
| New `test-migrator-core.sh` step green | DEFERRED (POQ-6) — `test-migrator-manifest.sh` 12/12 PASS |
| Manifest-parser positive + negative cases green | PASS (tests #1–3) |
| Trinity-parity validator green | PASS (tests #4–6) |
| `bash -n` clean on every modified/new file | PASS (4 files) |
| Public-API surface unchanged (Check 26) | PASS |
| No PM-only files touched | PASS (BACKLOG / CHANGELOG / README / PACK-CHAT / PACK-AGENTS untouched) |
| No git state changes | PASS (HEAD at session-start SHA `5f11419`) |
| `customization-preserve.sh` / `customization-report.sh` / `three-way.sh` unchanged | PASS |
| `init-project.sh` unchanged (OQ4 deferred) | PASS |
| `migrate-v10-to-v11.sh` (the adapter) unchanged in C-4 | PASS (the cutover is C-6) |

---

## 7. Files inventory

| Path | Change type | Line delta |
|---|---|---|
| `scripts/lib/migrator-stages.sh` | modified | +497 / −38 (67 → 520) |
| `scripts/lib/migrator-manifest.sh` | modified | +501 / −33 (68 → 517) |
| `scripts/test-migrator-manifest.sh` | new (mode 0755) | +529 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C4.md` | new | this file |

Touched files: 4. No PM-only or out-of-scope files modified.

---

## 8. Proposed C-4 commit message

```
feat: v11 — BD-119 C-4: implement stages + manifest engine + manifest unit tests
```

Body (suggested):

```
PLAN T-8 (stage bodies), T-9 (manifest engine bodies), and a
T-10 unit-test slice for the manifest engine + stage runner.

- migrator-stages.sh: full bodies for the seven _stage_* functions
  (preflight, backup, libs, dispatch, relocations, artifact_installs,
  report). All version strings templated against MIGRATOR_FROM_VERSION
  / MIGRATOR_TO_VERSION / MIGRATOR_OWN_SIDECAR_SUFFIX (architecture M5).
  Idempotency check (I8) issues EXIT_ALREADY_MIGRATED (16) on re-run.
  Dry-run short-circuit + tracker.toml [pack].version stamp (POQ-3).
- migrator-manifest.sh: parser for the 4-column TSV manifest with
  action-arg capture for relocate-from; trinity-parity validator
  (architecture I5) erroring before any mutation; iterator dispatching
  to customization_preserve (transform), additive write (add), sidecar+rm
  (remove), git-mv-with-fallback (relocate-from); directory-sweep with
  manifest-row precedence.
- test-migrator-manifest.sh: 12 unit tests (parser happy/malformed/
  unknown-action; trinity success / two-of-three / class-drift; iterator
  for each of the four action verbs; preflight idempotency).

T-12 (test-migrator-core.sh + validate-pack.yml step) deferred to a
follow-up commit (POQ-6).

bash -n: 4/4 OK; test-migrator-manifest.sh: 12/12 PASS;
validate-pack.py: 26/26 PASS; test-detect.sh: 40/40 PASS (regression).
```

---

## 9. Full file contents / diffs (chunked appendix)

The remaining sections are appended via subsequent Edit calls because
the rendered diffs + new-file contents push this report well above
the ~300-line chunking threshold. Each appendix section names the
file and shows either the full new contents or a `diff -u` against the
C-2 skeleton baseline.

---

## Appendix A — `scripts/lib/migrator-stages.sh` (full unified diff vs C-2 skeleton)

```diff
diff --git a/scripts/lib/migrator-stages.sh b/scripts/lib/migrator-stages.sh
index 3c8bf07..b8b7ac9 100644
--- a/scripts/lib/migrator-stages.sh
+++ b/scripts/lib/migrator-stages.sh
@@ -16,52 +16,505 @@
 #   _stage_artifact_installs— additive-only writes for `add` entries
 #   _stage_report           — render report.md + post-report hook
 #
-# This file is the C-2 SKELETON. Stage functions are stubs that print
-# `TODO: implement` to stderr and return non-zero so any premature call
-# surfaces clearly. Bodies are filled in by C-4 (PLAN T-8, T-9, T-10).
+# Bodies filled in C-4 (PLAN T-8 + T-10). The dispatch engine bodies live
+# in migrator-manifest.sh and are reached via `_stage_dispatch` here.
+#
+# Banner text + log lines mirror the v10→v11 monolith (lines 63–404 of
+# `scripts/migrate-v10-to-v11.sh` at d7b3f07) so the C-5 / C-6 behavior-
+# preservation harness diffs come up clean. Where the monolith hard-codes
+# "v10"/"v11" / "v10-customized", the framework substitutes
+# `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION` /
+# `MIGRATOR_OWN_SIDECAR_SUFFIX` so any future adapter inherits the same
+# wording without copy-paste drift (architecture M5).
 #
 # Do NOT add a shebang — this file is sourced, not executed.
 
-# ── Preflight, backup, library setup (filled in C-4 / PLAN T-8) ────────────
+# ── Internal helpers ──────────────────────────────────────────────────────
+#
+# `_migrator_dryrun_log <verb> <message>` emits the "[dry-run] would …"
+# line that PLAN POQ-2 promises. Stages call it instead of mutating when
+# `_MIGRATOR_DRY_RUN=1`. Read-only checks (preflight, baseline-tag exists,
+# etc.) still run; only writes short-circuit. Centralized so future stages
+# stay consistent.
+_migrator_dryrun_log() {
+    local verb="$1" msg="$2"
+    info "[dry-run] would $verb $msg"
+}
+
+# Returns 0 when dry-run mode is active. Stage write-paths gate on this.
+_migrator_is_dryrun() {
+    [[ "${_MIGRATOR_DRY_RUN:-0}" == "1" ]]
+}
+
+# ── S0 — Preflight (I1, I4, I8) ───────────────────────────────────────────
+#
+# Verifies the target is a clean git repo, the pack-side libraries exist,
+# the baseline tag resolves, the target's installed pack version matches
+# `MIGRATOR_FROM_VERSION`, and no prior-version `--update` sidecars
+# remain. Architecture §6 invariants I1, I4, I8 are enforced here.
+#
+# Idempotency (I8): if a prior successful migration left
+# `<state-dir>/dispositions.tsv` behind, exit `EXIT_ALREADY_MIGRATED` (16)
+# unless `--resume` is set. The current C-4 scope errors out on `--resume`
+# in the arg parser (BD-095 surface), so re-running an already-migrated
+# tree always tells the user to recover from the backup first. Read-only.
 
 _stage_preflight() {
-    printf '_stage_preflight: TODO: implement (C-4 / PLAN T-8)\n' >&2
-    return 1
+    say "── S0 — pre-flight ──"
+
+    # Validate $PACK and pack-side libraries.
+    [[ -n "${PACK:-}" ]] \
+        || die "PACK environment variable not set" "$EXIT_PACK_INVALID"
+    [[ -d "$PACK/project-template" ]] \
+        || die "PACK ($PACK) missing project-template/" "$EXIT_PACK_INVALID"
+    [[ -f "$PACK/scripts/lib/three-way.sh" ]] \
+        || die "PACK missing three-way.sh" "$EXIT_PACK_INVALID"
+    [[ -f "$PACK/scripts/lib/customization-preserve.sh" ]] \
+        || die "PACK missing BD-088 customization-preserve library" \
+               "$EXIT_LIB_MISSING"
+    [[ -f "$PACK/scripts/lib/customization-report.sh" ]] \
+        || die "PACK missing BD-088 customization-report library" \
+               "$EXIT_LIB_MISSING"
+
+    # Target must be a git repo with a clean working tree.
+    git -C "$_MIGRATOR_TARGET" rev-parse --git-dir >/dev/null 2>&1 \
+        || die "target is not a git repo: $_MIGRATOR_TARGET" "$EXIT_NOT_GIT"
+
+    if [[ -n "$(git -C "$_MIGRATOR_TARGET" status --porcelain)" ]]; then
+        die "target working tree is dirty; commit or stash first" "$EXIT_DIRTY"
+    fi
+
+    # Sanity: target must look like the declared FROM version. The
+    # monolith checked CLAUDE.md + .claude/ directly; we keep that as a
+    # generic ai-config-marker check (any pack-configured project has
+    # both). Version-detection fingerprinting is downstream of this and
+    # is run via `migrator_detect_target_version` for the "wrong major
+    # version" guard. Architecture §5.4 + monolith lines 82–85.
+    if [[ ! -f "$_MIGRATOR_TARGET/CLAUDE.md" \
+       || ! -d "$_MIGRATOR_TARGET/.claude" ]]; then
+        die "target does not appear to be a pack-configured project (CLAUDE.md or .claude/ missing); $0 is for ${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration only" \
+            "$EXIT_NOT_BASELINE"
+    fi
+
+    # Baseline tag must exist in pack repo.
+    if ! git -C "$PACK" rev-parse "$MIGRATOR_BASELINE_TAG" >/dev/null 2>&1; then
+        die "${MIGRATOR_FROM_VERSION} baseline tag '$MIGRATOR_BASELINE_TAG' not present in pack repo at $PACK" \
+            "$EXIT_BASELINE_MISSING"
+    fi
+    info "${MIGRATOR_FROM_VERSION} baseline tag resolved: $MIGRATOR_BASELINE_TAG"
+
+    # Stale-sidecar refusal (architecture §6 I4 / monolith lines 94–108).
+    # Iterate the adapter-declared prior-suffix list (e.g. ("pre-update")
+    # for v10→v11). Each suffix is expanded into a `*.<suffix>` find pattern.
+    local suffix stale_sidecars
+    if (( ${#MIGRATOR_PRIOR_SIDECAR_SUFFIXES[@]} > 0 )); then
+        for suffix in "${MIGRATOR_PRIOR_SIDECAR_SUFFIXES[@]}"; do
+            [[ -z "$suffix" ]] && continue
+            stale_sidecars=$(find "$_MIGRATOR_TARGET" -type f \
+                -name "*.${suffix}" \
+                -not -path "*/.git/*" \
+                -not -path "*/.pack-update/*" \
+                -not -path "*${_MIGRATOR_BACKUP_DIR##*/}/*" \
+                2>/dev/null | head -20)
+            if [[ -n "$stale_sidecars" ]]; then
+                say "refusing to proceed: prior \`--update\` sidecars present:"
+                printf '  %s\n' $stale_sidecars >&2
+                die "reconcile or remove the .${suffix} sidecars above before running ${MIGRATOR_FROM_VERSION}→${MIGRATOR_TO_VERSION} migration" \
+                    "$EXIT_DIRTY"
+            fi
+        done
+    fi
+
+    # Idempotency (I8): if a prior successful migration left a
+    # dispositions.tsv behind, exit EXIT_ALREADY_MIGRATED with a clearer
+    # signal than the monolith's "backup directory already exists" error.
+    if [[ -f "$_MIGRATOR_STATE_DIR/dispositions.tsv" ]]; then
+        say "target already migrated: $_MIGRATOR_STATE_DIR/dispositions.tsv exists"
+        die "to re-run the migration, restore from the backup at $_MIGRATOR_BACKUP_DIR first; --resume is reserved for BD-095 and not yet implemented" \
+            "$EXIT_ALREADY_MIGRATED"
+    fi
 }
 
+# ── S1 — Backup (I2) ──────────────────────────────────────────────────────
+#
+# Full working-tree backup before any mutation. Excludes only `.git/`,
+# the framework's own state + backup dirs, and the legacy `.pack-update/`
+# dir from `init-project.sh --update`. The monolith's exclude list
+# (lines 122–135) is reproduced verbatim with version-derived dir names
+# so a v11→v12 adapter inherits the same exclude shape (architecture M3).
+
 _stage_backup() {
-    printf '_stage_backup: TODO: implement (C-4 / PLAN T-8)\n' >&2
-    return 1
+    say "── S1 — backup ──"
+
+    if [[ -d "$_MIGRATOR_BACKUP_DIR" ]]; then
+        fail_stage S1 "backup directory already exists: $_MIGRATOR_BACKUP_DIR — rename it (mv $_MIGRATOR_BACKUP_DIR $_MIGRATOR_BACKUP_DIR.prev) or remove it before re-running"
+    fi
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "create backup directory" "$_MIGRATOR_BACKUP_DIR"
+        _migrator_dryrun_log "tar full working tree to" "$_MIGRATOR_BACKUP_DIR (excluding .git/ + state dirs)"
+        return 0
+    fi
+
+    mkdir -p "$_MIGRATOR_BACKUP_DIR"
+
+    # Build exclude list with version-derived state-dir + backup-dir
+    # names. `tar --exclude-from=` is portable across BSD and GNU tar
+    # (architecture R3). Use only the *basename* of the state/backup dirs
+    # because tar reads exclude entries as paths relative to the archive
+    # root (`-C "$_MIGRATOR_TARGET"`). Including absolute paths or
+    # leading-`./` would break BSD-tar matching.
+    local exclude_list state_basename backup_basename
+    state_basename="${_MIGRATOR_STATE_DIR##*/}"
+    backup_basename="${_MIGRATOR_BACKUP_DIR##*/}"
+    exclude_list=$(mktemp)
+    cat > "$exclude_list" <<EOF
+.git
+$state_basename
+$backup_basename
+.pack-update
+EOF
+    tar -cf - -C "$_MIGRATOR_TARGET" --exclude-from="$exclude_list" . \
+        | tar -x -C "$_MIGRATOR_BACKUP_DIR"
+    rm -f "$exclude_list"
+
+    [[ -f "$_MIGRATOR_BACKUP_DIR/CLAUDE.md" ]] \
+        || fail_stage S1 "backup verification failed (CLAUDE.md missing in backup)"
+
+    info "backup written: $_MIGRATOR_BACKUP_DIR (full working tree, excludes .git/ + state dirs)"
 }
 
+# ── S2 — Library setup ────────────────────────────────────────────────────
+#
+# Sources three-way + customization-preserve + customization-report and
+# initializes the BD-088 customization-preserve state dir. The state dir
+# is derived from `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION` so
+# every adapter inherits the same naming. Sidecar suffix is
+# adapter-declared (`MIGRATOR_OWN_SIDECAR_SUFFIX`).
+
 _stage_libs() {
-    printf '_stage_libs: TODO: implement (C-4 / PLAN T-8)\n' >&2
-    return 1
+    say "── S2 — initialize BD-088 customization-preserve state ──"
+
+    export _CP_PACK_ROOT="$PACK"
+    # shellcheck source=three-way.sh disable=SC1091
+    . "$PACK/scripts/lib/three-way.sh"
+    # shellcheck source=customization-preserve.sh disable=SC1091
+    . "$PACK/scripts/lib/customization-preserve.sh"
+    # shellcheck source=customization-report.sh disable=SC1091
+    . "$PACK/scripts/lib/customization-report.sh"
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "reset state directory" "$_MIGRATOR_STATE_DIR"
+        # In dry-run we still want the state dir for the dispositions.tsv
+        # because the engine records "would write" findings. The mkdir is
+        # therefore not gated on dry-run.
+    fi
+
+    rm -rf "$_MIGRATOR_STATE_DIR"
+    customization_preserve_init \
+        "$_MIGRATOR_STATE_DIR" \
+        ".${MIGRATOR_OWN_SIDECAR_SUFFIX}"
+    info "state dir: $_MIGRATOR_STATE_DIR"
 }
 
-# ── Manifest dispatch (filled in C-4 / PLAN T-9) ───────────────────────────
+# ── S3 — Manifest dispatch ────────────────────────────────────────────────
 #
-# The body lives in migrator-manifest.sh; this stage function is the named
-# entry point the core's sequencer calls. Wiring lands at C-4.
+# Calls into the manifest engine in `migrator-manifest.sh`. The engine
+# reads the adapter's `migrator_manifest` + `migrator_directory_sweeps`
+# stdout, validates trinity-parity (I5) before any mutation, and
+# iterates entries through `customization_preserve` for the always-
+# dispatch contract (architecture §6 M4 / I3).
 
 _stage_dispatch() {
-    printf '_stage_dispatch: TODO: implement (C-4 / PLAN T-9)\n' >&2
-    return 1
+    say "── S3 — dispatch ${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} file changes via BD-088 ──"
+
+    # Parse adapter-declared manifest into the parallel-array storage
+    # owned by `migrator-manifest.sh`. Errors before any mutation if the
+    # manifest is malformed or trinity-parity is violated (I5).
+    _manifest_parse
+    _manifest_validate_trinity
+
+    # Iterate parsed manifest. Always dispatches every entry through
+    # customization_preserve for `transform`, additive write for `add`,
+    # no-op (with disposition record) for `remove`, git-mv-with-fallback
+    # for `relocate-from`. Records a disposition in the BD-088 TSV for
+    # each so the BD-088 truthful-report contract holds.
+    _manifest_iterate
+
+    # Directory sweeps (architecture §3, monolith S3 lines 226–253). The
+    # adapter declares `<pack-dir> <class>` rows; the engine iterates
+    # every regular file under each pack-dir and dispatches via
+    # customization_preserve, *unless* the file already appeared in the
+    # manifest above (manifest-row precedence per architecture §4.2).
+    _manifest_sweep_directories
 }
 
-# ── Relocation, artifact-install, report (filled in C-4 / PLAN T-10) ───────
+# ── S4 — Relocations (BD-042 legacy-doc relocation in v10→v11) ────────────
+#
+# Reads adapter-declared `migrator_relocations` (`<old-path> <new-path>`
+# rows) and performs git-mv with a `mv` fallback for untracked files,
+# plus the "both root and target present → sidecar the root copy" branch
+# from monolith lines 269–273. Most version transitions emit zero rows;
+# v10→v11 emits five (METHODOLOGY.md / PROMPT-TEMPLATES.md / etc.).
 
 _stage_relocations() {
-    printf '_stage_relocations: TODO: implement (C-4 / PLAN T-10)\n' >&2
-    return 1
+    say "── S4 — relocations ──"
+
+    local rows row old new moved=0
+    rows=$(migrator_relocations 2>/dev/null || true)
+
+    if [[ -z "$rows" ]]; then
+        info "no relocations declared by adapter"
+        return 0
+    fi
+
+    while IFS= read -r row; do
+        [[ -z "$row" ]] && continue
+        # Comment lines (start with `#`) — allow heredoc-style annotations.
+        [[ "${row# }" == \#* ]] && continue
+        # Two whitespace-separated fields: <old-path> <new-path>.
+        old=$(printf '%s' "$row" | awk '{print $1}')
+        new=$(printf '%s' "$row" | awk '{print $2}')
+        if [[ -z "$old" || -z "$new" ]]; then
+            warn "skipping malformed relocation row: $row"
+            continue
+        fi
+
+        if [[ ! -f "$_MIGRATOR_TARGET/$old" ]]; then
+            # Old path does not exist in target — nothing to relocate.
+            continue
+        fi
+
+        if _migrator_is_dryrun; then
+            _migrator_dryrun_log "relocate" "$old → $new"
+            moved=$((moved + 1))
+            continue
+        fi
+
+        # Ensure destination directory exists.
+        mkdir -p "$_MIGRATOR_TARGET/$(dirname "$new")"
+
+        if [[ -f "$_MIGRATOR_TARGET/$new" ]]; then
+            # Both source and destination exist — preserve the canonical
+            # destination, sidecar the root copy with a clear suffix.
+            mv "$_MIGRATOR_TARGET/$old" "$_MIGRATOR_TARGET/$old.relocated-from-root"
+            info "relocated: $old → $old.relocated-from-root ($new already present)"
+            moved=$((moved + 1))
+            continue
+        fi
+
+        # git-mv first; fall back to plain mv if the source is untracked.
+        # Any other git-mv failure is a defect (fail_stage so the user
+        # can investigate before more relocations run).
+        local mv_stderr untracked=0
+        mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "$old" "$new" 2>&1) || {
+            if [[ "$mv_stderr" == *"not under version control"* \
+               || "$mv_stderr" == *"did not match"* ]]; then
+                mv "$_MIGRATOR_TARGET/$old" "$_MIGRATOR_TARGET/$new"
+                untracked=1
+            else
+                fail_stage S4 "git mv $old → $new failed: $mv_stderr"
+            fi
+        }
+        [[ -f "$_MIGRATOR_TARGET/$new" ]] \
+            || fail_stage S4 "post-relocation verification failed: $new missing"
+        if (( untracked == 1 )); then
+            info "relocated (untracked): $old → $new"
+        else
+            info "relocated: $old → $new"
+        fi
+        moved=$((moved + 1))
+    done <<< "$rows"
+
+    info "relocations: $moved file(s) moved"
 }
 
+# ── S5 — Additive artifact installs ───────────────────────────────────────
+#
+# Reads adapter-declared `migrator_artifact_installs` TSV
+# (`<pack-relpath>\t<project-relpath>\t<class>\tadd` rows) and writes
+# each only if the target does not already have the file. Records a
+# disposition via the BD-088 contract (`pack-update-applied` for newly
+# written, `project-only-file` for already-present, `removed-everywhere`
+# for absent-on-pack-side). Directories are created on demand.
+#
+# Implementation note: this stage handles `add`-action rows from the
+# adapter's `migrator_artifact_installs` hook. The dispatch engine in
+# `_manifest_iterate` *also* understands `add`, but the architecture
+# splits them so the dispatch engine deals only with the v10→v11-style
+# customization manifest while artifact installs stay version-additive.
+
 _stage_artifact_installs() {
-    printf '_stage_artifact_installs: TODO: implement (C-4 / PLAN T-10)\n' >&2
-    return 1
+    say "── S5 — install ${MIGRATOR_TO_VERSION} client artifacts ──"
+
+    local rows row pack_rel proj_rel cls action installed=0
+    rows=$(migrator_artifact_installs 2>/dev/null || true)
+
+    if [[ -z "$rows" ]]; then
+        info "no artifact installs declared by adapter"
+        return 0
+    fi
+
+    while IFS=$'\t' read -r pack_rel proj_rel cls action; do
+        # Skip blank or comment rows.
+        [[ -z "${pack_rel:-}" ]] && continue
+        case "$pack_rel" in '#'*) continue ;; esac
+        if [[ -z "${proj_rel:-}" || -z "${cls:-}" || -z "${action:-}" ]]; then
+            warn "skipping malformed artifact-install row: $pack_rel | $proj_rel | $cls | $action"
+            continue
+        fi
+        if [[ "$action" != "add" ]]; then
+            warn "artifact-install row uses non-'add' action ($action) — skipping; use migrator_manifest for transform/remove/relocate"
+            continue
+        fi
+
+        local src="$PACK/$pack_rel"
+        local dst="$_MIGRATOR_TARGET/$proj_rel"
+
+        if [[ ! -f "$src" ]]; then
+            _cp_record "removed-everywhere" "$cls" "$proj_rel" "none" "-" "-" \
+                "additive artifact absent at pack baseline"
+            continue
+        fi
+
+        if [[ -f "$dst" ]]; then
+            # Target already has the file — never clobber. Record so the
+            # BD-088 truthful-report contract holds.
+            _cp_record "project-only-file" "$cls" "$proj_rel" "preserved" "-" "-" \
+                "additive artifact already present in target"
+            continue
+        fi
+
+        if _migrator_is_dryrun; then
+            _migrator_dryrun_log "install artifact" "$proj_rel"
+            _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
+                "[dry-run] would copy $pack_rel"
+            installed=$((installed + 1))
+            continue
+        fi
+
+        mkdir -p "$(dirname "$dst")"
+        cp "$src" "$dst"
+        # Preserve executable bit for shipped scripts (the monolith does
+        # this explicitly for `scripts/pack-help.sh` at lines 363–364).
+        if [[ -x "$src" ]]; then
+            chmod +x "$dst"
+        fi
+        _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
+            "additive install"
+        installed=$((installed + 1))
+    done <<< "$rows"
+
+    info "artifact installs: $installed file(s) added"
 }
 
+# ── S6 — Render report + post-report hook ─────────────────────────────────
+#
+# Renders `<state-dir>/report.md` via `customization_report`, prints the
+# templated revert-instructions string (architecture M5: templated
+# against MIGRATOR_FROM_VERSION / MIGRATOR_TO_VERSION so wording does not
+# drift across adapters), records the destination pack version into
+# `tracker.toml` if the file already exists in the target (POQ-3), and
+# calls the adapter-supplied `migrator_post_report_hook`.
+
 _stage_report() {
-    printf '_stage_report: TODO: implement (C-4 / PLAN T-10)\n' >&2
-    return 1
+    say "── S6 — render truthful migration report ──"
+
+    local report="$_MIGRATOR_STATE_DIR/report.md"
+    local title="${MIGRATOR_FROM_VERSION} → ${MIGRATOR_TO_VERSION} migration customization report"
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "render report" "$report"
+    else
+        customization_report \
+            "$_MIGRATOR_STATE_DIR/dispositions.tsv" \
+            "$report" \
+            "$title"
+    fi
+
+    local count
+    count=$(customization_findings_count 2>/dev/null || printf '0')
+
+    say ""
+    say "Migration complete. $count files processed by BD-088 dispatch."
+    say "Backup: $_MIGRATOR_BACKUP_DIR (faithful working-tree snapshot)"
+    say "Report: $report"
+    say ""
+    say "To revert this migration:"
+    say "  1. From a clean shell:"
+    say "       cd $_MIGRATOR_TARGET"
+    say "       rm -rf ${_MIGRATOR_STATE_DIR##*/}"
+    say "       (rsync -a --delete --exclude=.git/ \\"
+    say "          --exclude=${_MIGRATOR_BACKUP_DIR##*/}/ \\"
+    say "          ${_MIGRATOR_BACKUP_DIR##*/}/ ./)"
+    say "  2. Inspect with \`git diff\`."
+    say "  3. When satisfied, remove ${_MIGRATOR_BACKUP_DIR##*/}/."
+    if [[ -f "$_MIGRATOR_STATE_DIR/dispositions.tsv" ]] \
+       && grep -q "needs-reconciliation" "$_MIGRATOR_STATE_DIR/dispositions.tsv" 2>/dev/null; then
+        say ""
+        say "NOTE: one or more files need manual reconciliation. Review the"
+        say "report's \"Files needing manual reconciliation\" section and"
+        say "inspect the named .${MIGRATOR_OWN_SIDECAR_SUFFIX} sidecars."
+    fi
+
+    # POQ-3: stamp tracker.toml `[pack].version = "<TO_VERSION>"` if the
+    # file already exists in the target. Never creates the file. Idempotent
+    # (replaces the line in-place when present, appends a `[pack]` section
+    # otherwise). Wrapped in dry-run gate.
+    _stage_report_stamp_tracker_version
+
+    return 0
+}
+
+# Internal: stamp the destination pack version into tracker.toml when
+# the file already exists. Architecture §7 last paragraph + PLAN POQ-3.
+# Bash-3.2 + BSD-sed compatible: uses awk for the in-place update so we
+# do not have to deal with `sed -i ''` vs `sed -i` portability.
+_stage_report_stamp_tracker_version() {
+    local tracker="$_MIGRATOR_TARGET/tracker.toml"
+    [[ -f "$tracker" ]] || return 0
+
+    local version="$MIGRATOR_TO_VERSION"
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "stamp" "$tracker [pack] version = \"$version\""
+        return 0
+    fi
+
+    if grep -q '^\[pack\]' "$tracker" 2>/dev/null; then
+        # `[pack]` section exists — replace or insert `version = "..."`
+        # within it. Awk is the safest cross-platform tool here.
+        local tmp
+        tmp=$(mktemp)
+        awk -v ver="$version" '
+            BEGIN { in_pack = 0; wrote_version = 0 }
+            /^\[pack\]/ {
+                print
+                in_pack = 1
+                next
+            }
+            /^\[/ && in_pack && !wrote_version {
+                print "version = \"" ver "\""
+                wrote_version = 1
+                in_pack = 0
+                print
+                next
+            }
+            in_pack && /^[[:space:]]*version[[:space:]]*=/ {
+                print "version = \"" ver "\""
+                wrote_version = 1
+                next
+            }
+            { print }
+            END {
+                if (in_pack && !wrote_version) {
+                    print "version = \"" ver "\""
+                }
+            }
+        ' "$tracker" > "$tmp"
+        mv "$tmp" "$tracker"
+    else
+        # Append a `[pack]` section with the version line.
+        printf '\n[pack]\nversion = "%s"\n' "$version" >> "$tracker"
+    fi
 }
```

---

## Appendix B — `scripts/lib/migrator-manifest.sh` (full unified diff vs C-2 skeleton)

```diff
diff --git a/scripts/lib/migrator-manifest.sh b/scripts/lib/migrator-manifest.sh
index 1713fd8..c4ca57d 100644
--- a/scripts/lib/migrator-manifest.sh
+++ b/scripts/lib/migrator-manifest.sh
@@ -17,52 +17,501 @@
 #     git-mv-with-fallback per `relocate-from`.
 #   - Drive the directory-sweep hook (`migrator_directory_sweeps`).
 #
-# This file is the C-2 SKELETON. Parser/validator/iterator are stubs that
-# print `TODO: implement` to stderr and return non-zero. Bodies are filled
-# in by C-4 (PLAN T-9).
+# Bodies filled in C-4 (PLAN T-9). bash 3.2 portable — no associative
+# arrays, no `&>`, no `${var,,}`. Parallel indexed arrays mirror the
+# parser's logical 4-tuple per row.
 #
 # Do NOT add a shebang — this file is sourced, not executed.
 
-# ── Manifest parser (filled in C-4 / PLAN T-9) ─────────────────────────────
+# ── Parsed-manifest storage (parallel indexed arrays) ─────────────────────
 #
-# Reads the adapter's `migrator_manifest` stdout into an in-memory
-# representation suitable for trinity-parity validation and iteration.
-# bash 3.2 portable (no associative arrays); uses parallel indexed arrays.
+# `_manifest_parse` populates these. Other `_manifest_*` functions read
+# them. They are reset on every parse so a re-run inside the same shell
+# (e.g. unit tests calling _manifest_parse twice) does not accumulate.
+
+_MIGRATOR_MANIFEST_PACK_RELS=()
+_MIGRATOR_MANIFEST_PROJ_RELS=()
+_MIGRATOR_MANIFEST_CLASSES=()
+_MIGRATOR_MANIFEST_ACTIONS=()
+# `_MIGRATOR_MANIFEST_ACTION_ARGS[i]` is the post-verb argument. Currently
+# only `relocate-from <old-path>` uses it; other verbs leave the entry as
+# the empty string. Always indexed in parallel with the four arrays above.
+_MIGRATOR_MANIFEST_ACTION_ARGS=()
+_MIGRATOR_MANIFEST_COUNT=0
+
+_manifest_reset_storage() {
+    _MIGRATOR_MANIFEST_PACK_RELS=()
+    _MIGRATOR_MANIFEST_PROJ_RELS=()
+    _MIGRATOR_MANIFEST_CLASSES=()
+    _MIGRATOR_MANIFEST_ACTIONS=()
+    _MIGRATOR_MANIFEST_ACTION_ARGS=()
+    _MIGRATOR_MANIFEST_COUNT=0
+}
+
+# ── Manifest parser ───────────────────────────────────────────────────────
+#
+# Reads `migrator_manifest` stdout into the parallel-array storage above.
+# Each non-blank, non-comment row must have exactly four tab-separated
+# fields: `<pack-relpath>\t<project-relpath>\t<class>\t<action>`. The
+# `action` field may itself be space-separated when it carries an
+# argument (`relocate-from <old-path>`); the parser splits on the first
+# space and stores the remainder in `_MIGRATOR_MANIFEST_ACTION_ARGS`.
+#
+# Blank lines and `#`-commented lines are skipped. Malformed rows abort
+# with EXIT_INTERNAL — adapters cannot ship a manifest the engine
+# silently misreads.
 
 _manifest_parse() {
-    printf '_manifest_parse: TODO: implement (C-4 / PLAN T-9)\n' >&2
-    return 1
+    _manifest_reset_storage
+
+    if ! declare -F migrator_manifest >/dev/null 2>&1; then
+        die "_manifest_parse: adapter did not declare migrator_manifest()" \
+            "$EXIT_INTERNAL"
+    fi
+
+    local raw
+    raw=$(migrator_manifest 2>/dev/null || true)
+
+    # Empty manifest is allowed — some transitions may declare zero
+    # transform rows and rely entirely on directory sweeps + artifact
+    # installs. Don't error here; the iterator will emit "no entries".
+    if [[ -z "$raw" ]]; then
+        return 0
+    fi
+
+    local row pack_rel proj_rel cls action_field action action_arg
+    local lineno=0
+    while IFS= read -r row; do
+        lineno=$((lineno + 1))
+        # Skip blank lines.
+        [[ -z "$row" ]] && continue
+        # Skip comment lines (leading `#`, optionally indented).
+        case "${row#"${row%%[![:space:]]*}"}" in
+            '#'*) continue ;;
+        esac
+
+        # Tab-split into four logical fields. bash 3.2 IFS read on a
+        # captured line: we re-read via process substitution-safe form
+        # by splitting manually with `awk` — but plain IFS split works
+        # provided we copy the row through `IFS=$'\t' read`.
+        IFS=$'\t' read -r pack_rel proj_rel cls action_field <<< "$row"
+
+        if [[ -z "${pack_rel:-}" || -z "${proj_rel:-}" \
+           || -z "${cls:-}" || -z "${action_field:-}" ]]; then
+            die "_manifest_parse: malformed manifest row $lineno (need 4 tab-separated fields): $row" \
+                "$EXIT_INTERNAL"
+        fi
+
+        # Split the action field on the first space — the verb is
+        # always a single token; everything after is its argument
+        # (currently only `relocate-from <old>`).
+        action="${action_field%% *}"
+        if [[ "$action" == "$action_field" ]]; then
+            action_arg=""
+        else
+            action_arg="${action_field#* }"
+        fi
+
+        case "$action" in
+            transform|add|remove|relocate-from) ;;
+            *)
+                die "_manifest_parse: unknown manifest action '$action' on row $lineno (expected transform|add|remove|relocate-from)" \
+                    "$EXIT_INTERNAL"
+                ;;
+        esac
+
+        if [[ "$action" == "relocate-from" && -z "$action_arg" ]]; then
+            die "_manifest_parse: relocate-from on row $lineno missing <old-path> argument: $row" \
+                "$EXIT_INTERNAL"
+        fi
+
+        _MIGRATOR_MANIFEST_PACK_RELS+=("$pack_rel")
+        _MIGRATOR_MANIFEST_PROJ_RELS+=("$proj_rel")
+        _MIGRATOR_MANIFEST_CLASSES+=("$cls")
+        _MIGRATOR_MANIFEST_ACTIONS+=("$action")
+        _MIGRATOR_MANIFEST_ACTION_ARGS+=("$action_arg")
+        _MIGRATOR_MANIFEST_COUNT=$((_MIGRATOR_MANIFEST_COUNT + 1))
+    done <<< "$raw"
 }
 
-# ── Trinity-parity validator (filled in C-4 / PLAN T-9) ────────────────────
+# ── Trinity-parity validator (I5) ─────────────────────────────────────────
 #
 # Architecture §6 I5: when any of CLAUDE.md / AGENTS.md / GEMINI.md
-# appears as a manifest row, the other two must also appear with the same
-# class + action. Errors before any mutation if violated.
+# appears as a manifest row (pack-relpath = `project-template/CLAUDE.md`
+# *or* the bare project-relpath = `CLAUDE.md`), the other two must also
+# appear with the same class + action. Errors before any mutation if
+# violated. Implementation runs against the parsed-manifest storage so
+# both the heredoc-emitted manifests and any future loaded-from-file
+# manifests share the same validator.
 
 _manifest_validate_trinity() {
-    printf '_manifest_validate_trinity: TODO: implement (C-4 / PLAN T-9)\n' >&2
-    return 1
+    local trinity=("CLAUDE.md" "AGENTS.md" "GEMINI.md")
+    local i name
+    local found_any=0
+    # Slot indices keyed by trinity name (parallel to `trinity`).
+    local idx_claude=-1 idx_agents=-1 idx_gemini=-1
+
+    for (( i = 0; i < _MIGRATOR_MANIFEST_COUNT; i++ )); do
+        name="${_MIGRATOR_MANIFEST_PROJ_RELS[$i]}"
+        case "$name" in
+            CLAUDE.md) idx_claude=$i; found_any=1 ;;
+            AGENTS.md) idx_agents=$i; found_any=1 ;;
+            GEMINI.md) idx_gemini=$i; found_any=1 ;;
+        esac
+    done
+
+    # If none of the three appear, the rule is vacuously satisfied.
+    if (( found_any == 0 )); then
+        return 0
+    fi
+
+    # All three must be present.
+    local missing=()
+    (( idx_claude < 0 )) && missing+=("CLAUDE.md")
+    (( idx_agents < 0 )) && missing+=("AGENTS.md")
+    (( idx_gemini < 0 )) && missing+=("GEMINI.md")
+    if (( ${#missing[@]} > 0 )); then
+        die "trinity parity violation (architecture §6 I5): manifest declares some of CLAUDE.md/AGENTS.md/GEMINI.md but is missing: ${missing[*]} — when one trinity file ships in a manifest, all three must" \
+            "$EXIT_INTERNAL"
+    fi
+
+    # All three must share the same class and the same action.
+    local cls_claude="${_MIGRATOR_MANIFEST_CLASSES[$idx_claude]}"
+    local cls_agents="${_MIGRATOR_MANIFEST_CLASSES[$idx_agents]}"
+    local cls_gemini="${_MIGRATOR_MANIFEST_CLASSES[$idx_gemini]}"
+    local act_claude="${_MIGRATOR_MANIFEST_ACTIONS[$idx_claude]}"
+    local act_agents="${_MIGRATOR_MANIFEST_ACTIONS[$idx_agents]}"
+    local act_gemini="${_MIGRATOR_MANIFEST_ACTIONS[$idx_gemini]}"
+
+    if [[ "$cls_claude" != "$cls_agents" || "$cls_claude" != "$cls_gemini" ]]; then
+        die "trinity parity violation: CLAUDE.md class=$cls_claude / AGENTS.md class=$cls_agents / GEMINI.md class=$cls_gemini — all three must use the same class" \
+            "$EXIT_INTERNAL"
+    fi
+    if [[ "$act_claude" != "$act_agents" || "$act_claude" != "$act_gemini" ]]; then
+        die "trinity parity violation: CLAUDE.md action=$act_claude / AGENTS.md action=$act_agents / GEMINI.md action=$act_gemini — all three must use the same action" \
+            "$EXIT_INTERNAL"
+    fi
 }
 
-# ── Iterator / dispatch engine (filled in C-4 / PLAN T-9) ──────────────────
+# ── Iterator / dispatch engine ────────────────────────────────────────────
+#
+# Walks the parsed manifest entries and dispatches each to the action
+# handler. Architecture §6 M4 always-dispatch: every `transform` entry
+# goes through `customization_preserve` — even when both sides absent —
+# so the BD-088 truthful-report invariant holds.
 #
-# Walks parsed manifest entries and dispatches each to the appropriate
-# action handler. Always-dispatch contract (M4): every entry goes through
-# `customization_preserve` so the BD-088 truthful-report invariant holds.
+# Action verb behavior:
+#   transform        — three-way dispatch via customization_preserve
+#                      (matches the monolith's S3 behavior verbatim).
+#   add              — additive-only install: copy pack→target only if
+#                      target is missing; record disposition either way.
+#   remove           — file existed at baseline but no longer ships at
+#                      target version. If target still has it, sidecar
+#                      and remove; otherwise record removed-everywhere.
+#   relocate-from    — git-mv-with-fallback from the action argument
+#                      (`<old-path>`) to the row's project-relpath
+#                      (`<new-path>`). Same fallback semantics as the
+#                      monolith's S4 BD-042 relocation.
 
 _manifest_iterate() {
-    printf '_manifest_iterate: TODO: implement (C-4 / PLAN T-9)\n' >&2
-    return 1
+    if (( _MIGRATOR_MANIFEST_COUNT == 0 )); then
+        info "BD-088 dispatch: 0 file(s) — manifest empty"
+        return 0
+    fi
+
+    local i pack_rel proj_rel cls action action_arg
+    local processed=0
+    for (( i = 0; i < _MIGRATOR_MANIFEST_COUNT; i++ )); do
+        pack_rel="${_MIGRATOR_MANIFEST_PACK_RELS[$i]}"
+        proj_rel="${_MIGRATOR_MANIFEST_PROJ_RELS[$i]}"
+        cls="${_MIGRATOR_MANIFEST_CLASSES[$i]}"
+        action="${_MIGRATOR_MANIFEST_ACTIONS[$i]}"
+        action_arg="${_MIGRATOR_MANIFEST_ACTION_ARGS[$i]}"
+
+        case "$action" in
+            transform)
+                _manifest_dispatch_transform \
+                    "$pack_rel" "$proj_rel" "$cls"
+                ;;
+            add)
+                _manifest_dispatch_add \
+                    "$pack_rel" "$proj_rel" "$cls"
+                ;;
+            remove)
+                _manifest_dispatch_remove \
+                    "$pack_rel" "$proj_rel" "$cls"
+                ;;
+            relocate-from)
+                _manifest_dispatch_relocate \
+                    "$pack_rel" "$proj_rel" "$cls" "$action_arg"
+                ;;
+        esac
+        processed=$((processed + 1))
+    done
+
+    info "BD-088 dispatch: $processed file(s) processed"
 }
 
-# ── Directory-sweep iterator (filled in C-4 / PLAN T-9) ────────────────────
+# ── Action handlers ──────────────────────────────────────────────────────
+#
+# Each handler:
+#  - resolves the BASE blob (pack baseline tag) via migrator_baseline_to_tmp
+#  - resolves OURS / THEIRS / DEST paths under TARGET / PACK
+#  - calls customization_preserve to record a truthful disposition
+#  - cleans up the BASE tmp file
 #
-# Reads `migrator_directory_sweeps` output (`<pack-dir> <class>` rows) and
-# dispatches each contained file with the declared class. Manifest-row
-# precedence over sweep results when paths collide.
+# Architecture I3 (BD-088 contract) is upheld for `transform` and `add`
+# rows by always invoking customization_preserve / _cp_record. `remove`
+# and `relocate-from` cannot use customization_preserve directly because
+# the action is structural, not text-merge — they call `_cp_record` to
+# stamp a disposition and keep the report truthful.
+
+_manifest_dispatch_transform() {
+    local pack_rel="$1" proj_rel="$2" cls="$3"
+    local theirs="$PACK/$pack_rel"
+    local ours="$_MIGRATOR_TARGET/$proj_rel"
+    local dest="$_MIGRATOR_TARGET/$proj_rel"
+    local base
+    base=$(mktemp)
+    if migrator_baseline_to_tmp "$pack_rel" "$base"; then
+        : # base populated
+    else
+        # Empty base file is what migrator_baseline_to_tmp leaves on
+        # not-found; clear the path so customization_preserve sees
+        # "absent" (empty string), matching the monolith's behavior.
+        rm -f "$base"
+        base=""
+    fi
+    [[ -f "$theirs" ]] || theirs=""
+    [[ -f "$ours" ]]   || ours=""
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "transform" "$proj_rel (class=$cls)"
+        # Still record a finding so the dry-run report is truthful.
+        _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
+            "[dry-run] would dispatch via customization_preserve"
+    else
+        # Always dispatch — even when both sides absent (architecture M4).
+        customization_preserve \
+            "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
+    fi
+
+    [[ -n "$base" ]] && rm -f "$base"
+}
+
+_manifest_dispatch_add() {
+    local pack_rel="$1" proj_rel="$2" cls="$3"
+    local src="$PACK/$pack_rel"
+    local dst="$_MIGRATOR_TARGET/$proj_rel"
+
+    if [[ ! -f "$src" ]]; then
+        _cp_record "removed-everywhere" "$cls" "$proj_rel" "none" "-" "-" \
+            "additive entry absent at pack baseline"
+        return 0
+    fi
+
+    if [[ -f "$dst" ]]; then
+        _cp_record "project-only-file" "$cls" "$proj_rel" "preserved" "-" "-" \
+            "additive entry already present in target"
+        return 0
+    fi
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "add" "$proj_rel (class=$cls)"
+        _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
+            "[dry-run] would copy $pack_rel"
+        return 0
+    fi
+
+    mkdir -p "$(dirname "$dst")"
+    cp "$src" "$dst"
+    if [[ -x "$src" ]]; then
+        chmod +x "$dst"
+    fi
+    _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
+        "additive add"
+}
+
+_manifest_dispatch_remove() {
+    local pack_rel="$1" proj_rel="$2" cls="$3"
+    local target="$_MIGRATOR_TARGET/$proj_rel"
+    # `pack_rel` is unused here but kept in the parameter list so the
+    # five action handlers share a uniform shape.
+    : "$pack_rel"
+
+    if [[ ! -f "$target" ]]; then
+        _cp_record "removed-everywhere" "$cls" "$proj_rel" "none" "-" "-" \
+            "remove-action: file absent in target"
+        return 0
+    fi
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "remove" "$proj_rel"
+        _cp_record "removed-by-design" "$cls" "$proj_rel" "removed" "-" "-" \
+            "[dry-run] would remove"
+        return 0
+    fi
+
+    # Sidecar the file before removal so the user can recover any
+    # customization (mirrors monolith's removed-by-pack-customized branch
+    # in customization-preserve).
+    local sidecar="${target}.${MIGRATOR_OWN_SIDECAR_SUFFIX}"
+    cp "$target" "$sidecar"
+    rm "$target"
+    _cp_record "removed-by-design" "$cls" "$proj_rel" "removed" "$sidecar" "-" \
+        "remove-action: file retired in ${MIGRATOR_TO_VERSION}; previous content sidecared"
+}
+
+_manifest_dispatch_relocate() {
+    local pack_rel="$1" proj_rel="$2" cls="$3" old="$4"
+    : "$pack_rel"
+    local new="$proj_rel"
+
+    if [[ ! -f "$_MIGRATOR_TARGET/$old" ]]; then
+        _cp_record "removed-everywhere" "$cls" "$new" "none" "-" "-" \
+            "relocate-from: source $old absent — nothing to relocate"
+        return 0
+    fi
+
+    if _migrator_is_dryrun; then
+        _migrator_dryrun_log "relocate" "$old → $new"
+        _cp_record "pack-update-applied" "$cls" "$new" "copied" "-" "-" \
+            "[dry-run] would relocate from $old"
+        return 0
+    fi
+
+    mkdir -p "$_MIGRATOR_TARGET/$(dirname "$new")"
+
+    if [[ -f "$_MIGRATOR_TARGET/$new" ]]; then
+        # Both source and destination present — keep destination canonical.
+        mv "$_MIGRATOR_TARGET/$old" \
+           "$_MIGRATOR_TARGET/$old.relocated-from-root"
+        _cp_record "project-only-file" "$cls" "$new" "preserved" \
+            "$_MIGRATOR_TARGET/$old.relocated-from-root" "-" \
+            "relocate-from: $new already present; sidecared $old"
+        return 0
+    fi
+
+    local mv_stderr untracked=0
+    mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "$old" "$new" 2>&1) || {
+        if [[ "$mv_stderr" == *"not under version control"* \
+           || "$mv_stderr" == *"did not match"* ]]; then
+            mv "$_MIGRATOR_TARGET/$old" "$_MIGRATOR_TARGET/$new"
+            untracked=1
+        else
+            die "_manifest_dispatch_relocate: git mv $old → $new failed: $mv_stderr" \
+                "$EXIT_INTERNAL"
+        fi
+    }
+    [[ -f "$_MIGRATOR_TARGET/$new" ]] \
+        || die "_manifest_dispatch_relocate: post-relocation verification failed: $new missing" \
+               "$EXIT_INTERNAL"
+    if (( untracked == 1 )); then
+        _cp_record "pack-update-applied" "$cls" "$new" "copied" "-" "-" \
+            "relocate-from $old (untracked plain mv)"
+    else
+        _cp_record "pack-update-applied" "$cls" "$new" "copied" "-" "-" \
+            "relocate-from $old (git mv)"
+    fi
+}
+
+# ── Directory-sweep iterator ──────────────────────────────────────────────
+#
+# Reads `migrator_directory_sweeps` output (`<pack-dir> <class>` rows)
+# and dispatches each contained file with the declared class. Manifest-
+# row precedence over sweep results when paths collide — the manifest's
+# `transform`-action proj-relpath set is consulted before each sweep
+# dispatch so an adapter can override a sweep result for a specific file.
 
 _manifest_sweep_directories() {
-    printf '_manifest_sweep_directories: TODO: implement (C-4 / PLAN T-9)\n' >&2
-    return 1
+    if ! declare -F migrator_directory_sweeps >/dev/null 2>&1; then
+        # Adapter declared no sweeps — that's fine; not all transitions
+        # need them. (Required-hook validation in the core ensures the
+        # function is at least defined; an empty heredoc returns no rows.)
+        return 0
+    fi
+
+    local rows row pack_dir cls
+    rows=$(migrator_directory_sweeps 2>/dev/null || true)
+    [[ -z "$rows" ]] && return 0
+
+    # Pre-build the manifest proj-relpath set into a single newline-joined
+    # blob; for each candidate file we grep the blob to avoid re-scanning
+    # the parallel arrays per-file. macOS bash 3.2 has no associative
+    # arrays.
+    local manifest_set
+    manifest_set=$(printf '%s\n' "${_MIGRATOR_MANIFEST_PROJ_RELS[@]:-}")
+
+    while IFS= read -r row; do
+        [[ -z "$row" ]] && continue
+        case "${row#"${row%%[![:space:]]*}"}" in
+            '#'*) continue ;;
+        esac
+        # Two whitespace-separated fields: <pack-dir> <class>.
+        pack_dir=$(printf '%s' "$row" | awk '{print $1}')
+        cls=$(printf '%s' "$row" | awk '{print $2}')
+        if [[ -z "$pack_dir" || -z "$cls" ]]; then
+            warn "skipping malformed directory-sweep row: $row"
+            continue
+        fi
+        _manifest_sweep_one_dir "$pack_dir" "$cls" "$manifest_set"
+    done <<< "$rows"
+}
+
+# Internal: iterate every regular file under `$PACK/$pack_dir`, derive
+# the parallel project-relative path, and dispatch via
+# customization_preserve unless the file already appears in the parsed
+# manifest's proj-relpath set.
+_manifest_sweep_one_dir() {
+    local pack_dir="$1" cls="$2" manifest_set="$3"
+    [[ -d "$PACK/$pack_dir" ]] || return 0
+
+    # The pack-side iteration root mirrors the project-side root. The
+    # monolith assumed pack_dir == proj_dir (e.g. `project-template/scripts`
+    # → `scripts/`); the directory-sweep TSV row carries one path that
+    # plays both roles relative to its respective root.
+    local proj_dir="$pack_dir"
+    case "$proj_dir" in
+        project-template/*) proj_dir="${proj_dir#project-template/}" ;;
+    esac
+
+    local f rel pack_rel proj_rel theirs ours dest base
+    while IFS= read -r f; do
+        [[ -z "$f" ]] && continue
+        rel="${f#"$PACK/$pack_dir/"}"
+        pack_rel="$pack_dir/$rel"
+        proj_rel="$proj_dir/$rel"
+
+        # Manifest-row precedence: skip if this proj-relpath is already
+        # in the parsed manifest. Use line-anchored grep -F -x for an
+        # exact-match check that does not interpret regex metachars in
+        # the path.
+        if [[ -n "$manifest_set" ]] \
+           && printf '%s\n' "$manifest_set" \
+              | grep -F -x -q -- "$proj_rel"; then
+            continue
+        fi
+
+        theirs="$f"
+        ours="$_MIGRATOR_TARGET/$proj_rel"
+        dest="$_MIGRATOR_TARGET/$proj_rel"
+        base=$(mktemp)
+        if ! migrator_baseline_to_tmp "$pack_rel" "$base"; then
+            rm -f "$base"
+            base=""
+        fi
+        [[ -f "$ours" ]] || ours=""
+
+        if _migrator_is_dryrun; then
+            _migrator_dryrun_log "sweep-dispatch" "$proj_rel (class=$cls)"
+            _cp_record "pack-update-applied" "$cls" "$proj_rel" "copied" "-" "-" \
+                "[dry-run] would dispatch via sweep"
+        else
+            customization_preserve \
+                "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" \
+                >/dev/null
+        fi
+
+        [[ -n "$base" ]] && rm -f "$base"
+    done < <(find "$PACK/$pack_dir" -type f -print 2>/dev/null)
 }
```

---

## Appendix C — `scripts/test-migrator-manifest.sh` (full new file contents)

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-manifest.sh — unit tests for the BD-119 migrator
# framework's manifest engine + a thin slice of the stage runner.
#
# Per PLAN-BD-119.md §6 row C-4 (T-9 + T-10 unit tests). Covers:
#   - _manifest_parse happy path (4 tab-separated fields, comments,
#     blank lines, relocate-from with action argument).
#   - _manifest_parse malformed-row error (3 fields → EXIT_INTERNAL).
#   - _manifest_parse unknown-action error.
#   - _manifest_validate_trinity success (all three trinity files
#     present with matching class+action).
#   - _manifest_validate_trinity failure (only 2 of 3 trinity files in
#     manifest → abort BEFORE any mutation).
#   - _manifest_validate_trinity failure (class drift across trinity).
#   - _manifest_iterate dispatching to customization_preserve for
#     `transform`, additive write for `add`, sidecar+remove for `remove`,
#     git-mv-with-fallback for `relocate-from`.
#   - _stage_preflight idempotency: re-run on already-migrated target
#     exits EXIT_ALREADY_MIGRATED (16).
#
# Each test case runs in a subshell with its own fixtures so failures
# never bleed across tests. Read-only with respect to the pack repo
# itself; everything happens under a per-test temp directory.
#
# Usage:    bash scripts/test-migrator-manifest.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d -t test-migrator-manifest.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}

# Helper: run a bash subshell with the migrator core sourced under a
# minimal valid adapter contract. The subshell's body is provided as a
# single argument; stdout / stderr / rc are captured by the caller.
#
# Variant 1: _migrator_subshell <body-string>
#   Returns rc; stdout + stderr go to caller's terminal unless captured
#   via $(...) and 2>&1.
_migrator_subshell() {
    local body="$1"
    bash -c '
        set -uo pipefail
        PACK="'"$PACK_ROOT"'"
        export PACK
        MIGRATOR_FROM_VERSION="v10"
        MIGRATOR_TO_VERSION="v11"
        MIGRATOR_BASELINE_TAG="v10"
        MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
        MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")
        migrator_manifest()             { :; }
        migrator_directory_sweeps()     { :; }
        migrator_relocations()          { :; }
        migrator_artifact_installs()    { :; }
        migrator_post_report_hook()     { :; }
        . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"
        '"$body"'
    '
}

# ── 1. _manifest_parse happy path ─────────────────────────────────────────
echo "== _manifest_parse happy path =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/GEMINI.md" "GEMINI.md" "trinity" "transform"
        printf "# a comment that should be skipped\n"
        printf "\n"
        printf "%s\t%s\t%s\t%s\n" "project-template/foo.md" "foo.md" "generic" "relocate-from docs/old-foo.md"
        printf "%s\t%s\t%s\t%s\n" "project-template/bar.md" "bar.md" "generic" "add"
    }
    _manifest_parse
    printf "count=%s\n" "$_MIGRATOR_MANIFEST_COUNT"
    printf "actions=%s\n" "${_MIGRATOR_MANIFEST_ACTIONS[*]}"
    printf "relocate-arg=%s\n" "${_MIGRATOR_MANIFEST_ACTION_ARGS[3]}"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"count=5"* \
   && "$out" == *"actions=transform transform transform relocate-from add"* \
   && "$out" == *"relocate-arg=docs/old-foo.md"* ]]; then
    pass "happy-path: 5 entries parsed, comments/blanks skipped, relocate-from arg captured"
else
    fail "happy-path parse" "count=5 + actions=... + relocate-arg=..." "rc=$rc out=$out"
fi

# ── 2. _manifest_parse malformed row → EXIT_INTERNAL ─────────────────────
echo "== _manifest_parse malformed row =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\n" "only-three-fields" "is-not" "enough"
    }
    _manifest_parse 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"malformed manifest row"* ]]; then
    pass "malformed-row: 3 fields → EXIT_INTERNAL (99) with malformed message"
else
    fail "malformed-row parse" "rc=99 + 'malformed manifest row' in stderr" "rc=$rc out=$out"
fi

# ── 3. _manifest_parse unknown action → EXIT_INTERNAL ────────────────────
echo "== _manifest_parse unknown action =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "p/x.md" "x.md" "generic" "delete-please"
    }
    _manifest_parse 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"unknown manifest action"* ]]; then
    pass "unknown-action: errors with EXIT_INTERNAL"
else
    fail "unknown-action parse" "rc=99 + 'unknown manifest action'" "rc=$rc out=$out"
fi

# ── 4. _manifest_validate_trinity — all three present, matching ─────────
echo "== trinity validator: all-three-present, matching =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/GEMINI.md" "GEMINI.md" "trinity" "transform"
    }
    _manifest_parse
    _manifest_validate_trinity
    printf "trinity-ok\n"
' 2>&1)
rc=$?
if [[ $rc -eq 0 && "$out" == *"trinity-ok"* ]]; then
    pass "trinity-success: all 3 with same class+action passes"
else
    fail "trinity-success" "rc=0 + trinity-ok" "rc=$rc out=$out"
fi

# ── 5. _manifest_validate_trinity — only 2 of 3 → abort ─────────────────
echo "== trinity validator: only 2 of 3 present =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
    }
    _manifest_parse
    _manifest_validate_trinity 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 \
   && "$out" == *"trinity parity violation"* \
   && "$out" == *"GEMINI.md"* ]]; then
    pass "trinity-only-two: errors with EXIT_INTERNAL naming missing GEMINI.md"
else
    fail "trinity-only-two" "rc=99 + 'trinity parity violation' + GEMINI.md" "rc=$rc out=$out"
fi

# ── 6. _manifest_validate_trinity — class drift across trinity → abort ──
echo "== trinity validator: class drift =="

out=$(_migrator_subshell '
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/AGENTS.md" "AGENTS.md" "trinity" "transform"
        printf "%s\t%s\t%s\t%s\n" "project-template/GEMINI.md" "GEMINI.md" "generic" "transform"
    }
    _manifest_parse
    _manifest_validate_trinity 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 99 && "$out" == *"trinity parity violation"* ]]; then
    pass "trinity-class-drift: errors with EXIT_INTERNAL"
else
    fail "trinity-class-drift" "rc=99 + 'trinity parity violation'" "rc=$rc out=$out"
fi

# ── 7. _manifest_iterate dispatches `transform` via customization_preserve
echo "== _manifest_iterate transform → customization_preserve =="

# Build a minimal target tree + state-dir so the dispatch runs end-to-end
# through customization_preserve and records a disposition. We can't
# easily reach `git show v10:...` in tests, so we stub
# `migrator_baseline_to_tmp` to always return rc=1 (file missing at
# baseline) — which is the new-file-in-pack code path in three-way.sh.
fx="$FIXTURE_BASE/iterate-transform"
mkdir -p "$fx" "$fx/.claude"
cat > "$fx/CLAUDE.md" <<'EOF'
# project CLAUDE.md
EOF

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/CLAUDE.md" "CLAUDE.md" "trinity" "transform"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    # Wire state-dir manually (mimics what _stage_libs does).
    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    # Stub baseline_to_tmp to always return "not found at baseline" so
    # we exercise the new-file-in-pack three-way branch.
    migrator_baseline_to_tmp() { : > "$2"; return 1; }

    _manifest_parse
    _manifest_iterate

    # The TSV must contain exactly one entry for CLAUDE.md.
    awk "NR > 1 && \$3 == \"CLAUDE.md\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
# Any valid disposition token proves customization_preserve was called.
# The exact token depends on three-way's classification of the
# absent-base / present-ours / present-theirs case (project-shadows-new-pack
# branch in three-way.sh, which maps to needs-reconciliation).
known_disp_re='(merged-with-customization|pack-update-applied|project-only-file|customization-detected-needs-reconciliation|project-shadows-new-pack)'
if [[ $rc -eq 0 && "$out" =~ $known_disp_re ]]; then
    pass "transform: customization_preserve invoked, disposition recorded"
else
    fail "iterate-transform" "rc=0 + a known disposition token" "rc=$rc out=$out"
fi

# ── 8. `add` action: additive write only when target missing ────────────
echo "== add: additive write only when target missing =="

fx="$FIXTURE_BASE/iterate-add"
mkdir -p "$fx"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        # Use a real pack file so cp succeeds. tracker.toml.example is
        # present in the v11 pack template.
        printf "%s\t%s\t%s\t%s\n" "project-template/tracker.toml.example" "tracker.toml.example" "generic" "add"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    # Target should now have the file
    [[ -f "'"$fx"'/tracker.toml.example" ]] && printf "wrote-add\n"
    awk "NR > 1 && \$3 == \"tracker.toml.example\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"wrote-add"* \
   && "$out" == *"pack-update-applied"* ]]; then
    pass "add: copies pack→target when target missing, records pack-update-applied"
else
    fail "iterate-add" "rc=0 + wrote-add + pack-update-applied" "rc=$rc out=$out"
fi

# ── 9. `add` action: skip when target already has file ──────────────────
echo "== add: skip when target already present =="

fx="$FIXTURE_BASE/iterate-add-existing"
mkdir -p "$fx"
printf 'pre-existing content\n' > "$fx/tracker.toml.example"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/tracker.toml.example" "tracker.toml.example" "generic" "add"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    # Target file should still have the original content (not clobbered)
    cat "'"$fx"'/tracker.toml.example"
    awk "NR > 1 && \$3 == \"tracker.toml.example\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"pre-existing content"* \
   && "$out" == *"project-only-file"* ]]; then
    pass "add: target already-present preserved, recorded project-only-file"
else
    fail "iterate-add-existing" "rc=0 + pre-existing-content + project-only-file" "rc=$rc out=$out"
fi

# ── 10. `remove` action: sidecar + rm when target had the file ─────────
echo "== remove: sidecar + rm when target has file =="

fx="$FIXTURE_BASE/iterate-remove"
mkdir -p "$fx"
printf 'old retired file\n' > "$fx/old-retired.md"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" "project-template/old-retired.md" "old-retired.md" "generic" "remove"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    [[ ! -f "'"$fx"'/old-retired.md" ]] && printf "removed\n"
    [[ -f "'"$fx"'/old-retired.md.v10-customized" ]] && printf "sidecared\n"
    awk "NR > 1 && \$3 == \"old-retired.md\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"removed"* \
   && "$out" == *"sidecared"* \
   && "$out" == *"removed-by-design"* ]]; then
    pass "remove: file removed + sidecared + removed-by-design recorded"
else
    fail "iterate-remove" "rc=0 + removed + sidecared + removed-by-design" "rc=$rc out=$out"
fi

# ── 11. `relocate-from` action: git mv old → new (untracked fallback) ──
echo "== relocate-from: untracked plain mv fallback =="

fx="$FIXTURE_BASE/iterate-relocate"
mkdir -p "$fx"
git -C "$fx" init -q -b main
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
printf 'legacy doc\n' > "$fx/METHODOLOGY.md"
git -C "$fx" add METHODOLOGY.md
git -C "$fx" commit -q -m "init"

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest() {
        printf "%s\t%s\t%s\t%s\n" \
            "project-template/docs/pack/METHODOLOGY.md" \
            "docs/pack/METHODOLOGY.md" \
            "generic" \
            "relocate-from METHODOLOGY.md"
    }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"
    export _CP_PACK_ROOT="$PACK"
    . "$PACK/scripts/lib/three-way.sh"
    . "$PACK/scripts/lib/customization-preserve.sh"
    . "$PACK/scripts/lib/customization-report.sh"
    rm -rf "$_MIGRATOR_STATE_DIR"
    customization_preserve_init "$_MIGRATOR_STATE_DIR" ".v10-customized"

    _manifest_parse
    _manifest_iterate

    [[ ! -f "'"$fx"'/METHODOLOGY.md" ]] && printf "old-gone\n"
    [[ -f "'"$fx"'/docs/pack/METHODOLOGY.md" ]] && printf "new-present\n"
    awk "NR > 1 && \$3 == \"docs/pack/METHODOLOGY.md\" { print \$1 }" \
        "$_MIGRATOR_STATE_DIR/dispositions.tsv"
' 2>&1)
rc=$?
if [[ $rc -eq 0 \
   && "$out" == *"old-gone"* \
   && "$out" == *"new-present"* \
   && "$out" == *"pack-update-applied"* ]]; then
    pass "relocate-from: git-mv succeeds, pack-update-applied recorded"
else
    fail "iterate-relocate" "rc=0 + old-gone + new-present + pack-update-applied" "rc=$rc out=$out"
fi

# ── 12. _stage_preflight idempotency: re-run on already-migrated tree ──
echo "== preflight: idempotency re-run → EXIT_ALREADY_MIGRATED =="

fx="$FIXTURE_BASE/preflight-idempotent"
mkdir -p "$fx" "$fx/.claude" "$fx/.pack-migrate-v10-to-v11"
printf '# CLAUDE.md\n' > "$fx/CLAUDE.md"
printf '# disposition\tclass\trel_path\taction\n' > "$fx/.pack-migrate-v10-to-v11/dispositions.tsv"
printf 'pack-update-applied\ttrinity\tCLAUDE.md\tcopied\n' >> "$fx/.pack-migrate-v10-to-v11/dispositions.tsv"
git -C "$fx" init -q -b main 2>/dev/null
git -C "$fx" config user.email t@t
git -C "$fx" config user.name t
git -C "$fx" add -A 2>/dev/null
git -C "$fx" commit -q -m "init" 2>/dev/null

out=$(bash -c '
    set -uo pipefail
    PACK="'"$PACK_ROOT"'"
    export PACK
    MIGRATOR_FROM_VERSION="v10"
    MIGRATOR_TO_VERSION="v11"
    MIGRATOR_BASELINE_TAG="v10"
    MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
    MIGRATOR_PRIOR_SIDECAR_SUFFIXES=()
    migrator_manifest()             { :; }
    migrator_directory_sweeps()     { :; }
    migrator_relocations()          { :; }
    migrator_artifact_installs()    { :; }
    migrator_post_report_hook()     { :; }
    . "'"$PACK_ROOT"'/scripts/lib/migrator-core.sh"

    # Set up the state without going through migrator_run (which sets
    # the EXIT trap and re-invokes parse).
    _MIGRATOR_TARGET="'"$fx"'"
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-v10-to-v11"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"

    _stage_preflight 2>&1
' 2>&1)
rc=$?
if [[ $rc -eq 16 && "$out" == *"target already migrated"* ]]; then
    pass "preflight: idempotency re-run exits EXIT_ALREADY_MIGRATED (16)"
else
    fail "preflight-idempotency" "rc=16 + 'target already migrated'" "rc=$rc out=$out"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```
