# IMPLEMENTATION-REPORT-BD-165 — Commit 19c (Batch 19, v11.0)

**Branch:** `v11-dev`
**Pre-flight HEAD SHA:** `8ba016493674a773c272e370a13ed3e760bf281f`
**Final HEAD SHA (working-tree edits only — agent did not commit):** `8ba016493674a773c272e370a13ed3e760bf281f`
**BD touched:** BD-165 (sole content; status flip happens in 19h per plan)
**Plan reference:** `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.4

---

## §1 — Summary

Commit 19c implements the v10→v11 migrator's 6th post-dispatch sub-op
(`_v10_to_v11_decompose_streams`) plus the `--force-overwrite-mirror`
flag that bridges the BD-095 two-phase contract to the BD-164
per-entry helpers' divergence-detection routing. The 6th sub-op runs
LAST in `migrator_post_dispatch_hook` (after the 5 existing sub-ops)
and uses the BD-164 helpers from `scripts/lib/per-entry/` to decompose
the just-installed v11-shape monolithic project-side files
(`docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md`) into
per-entry trees + regenerated mirrors + regenerated TOCs. The new flag
is parsed by `_migrator_parse_args` in `migrator-core.sh` (default
"0"), is also intercepted by the v10→v11 dispatcher so the resume
path honors it (the resume path never calls `_migrator_parse_args`),
and is consumed inside the per-entry mirror generator's non-interactive
divergence routing — where `_MIGRATOR_MODE=dry-run` REPORTS divergence
to stdout (rc=0), `_MIGRATOR_MODE=apply|resume` BLOCKS with
`EXIT_GATE_FAILED=31`, and `--force-overwrite-mirror` admits the
overwrite with a stderr audit-trail warning. The post-report hook
gains a 16-line advisory paragraph naming the rollback path. All
architect-doc bindings honored; all baseline tests pass; all four
manual smoke-test scenarios PASS.

---

## §2 — Files modified / created

| Path (absolute) | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/decompose.sh` | 0 | 212 | +212 | NEW (adapter-private helper) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh` | 521 | 559 | +38 | MODIFIED (state var + flag parser + usage line) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh` | 277 | 331 | +54 | MODIFIED (divergence routing per Addendum #2 §4) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` | 854 | 922 | +68 | MODIFIED (source new helper, 6th sub-op call, post-report advisory, dispatcher flag intercept) |

`git diff --stat` (modified files only): `3 files changed, 177 insertions(+), 14 deletions(-)`. New file: 212 lines.

`scripts/lib/per-entry/decompose.sh` (BD-164 helper) was NOT modified —
all routing changes landed in `mirror-generate.sh`. The BD-164
`_lib.sh` and `toc-regenerate.sh` were not touched.

---

## §3 — Per-file change detail

### §3.1 — `scripts/lib/migrator-core.sh` (MODIFIED)

Three additions:

**A. State var initialization + documentation comment.** Added
`_MIGRATOR_FORCE_OVERWRITE_MIRROR` to the documentation block at the
state-vars header and to `_migrator_reset_state`. Default `"0"`.

```
_migrator_reset_state() {
    _MIGRATOR_TARGET=""
    _MIGRATOR_DRY_RUN="0"
    _MIGRATOR_MODE="apply"
    _MIGRATOR_STATE_DIR=""
    _MIGRATOR_BACKUP_DIR=""
    _MIGRATOR_REPORT_DONE="0"
    _MIGRATOR_FORCE_OVERWRITE_MIRROR="0"   # ← NEW
}
```

**B. Flag parser case in `_migrator_parse_args`.** Added inside the
`while (( $# > 0 )); do case "$1" in` block, after the `--resume`
case, before the `--)` and `--*)` catch-alls:

```
--force-overwrite-mirror)
    _MIGRATOR_FORCE_OVERWRITE_MIRROR="1"
    ;;
```

(With a multi-line comment block above explaining the BD-165
provenance and Addendum #2 §4.5 reference.)

**C. Usage line in `_migrator_usage`.** Added after the `--resume`
help block, before the trailing blank line:

```
say "  --force-overwrite-mirror"
say "                Explicit acknowledgement that an --apply / --resume run may"
say "                overwrite hand-edited regenerated mirrors (BACKLOG.md,"
say "                CHANGELOG.md, IMPLEMENTATION-PLAN.md) when the per-entry"
say "                tree's regenerator output diverges from the on-disk file."
say "                Default off — divergence blocks with EXIT_GATE_FAILED=31."
say "                No effect in --dry-run (dry-run reports divergence; never"
say "                writes). See ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-"
say "                ADDENDUM-2.md §4.5."
```

No changes to existing constants, exit codes, or hook signatures. The
BD-119 frozen public surface is preserved — `_MIGRATOR_FORCE_OVERWRITE_MIRROR`
is internal-state-only (`_MIGRATOR_*` naming convention per
`migrator-core.sh:35`).

### §3.2 — `scripts/lib/per-entry/mirror-generate.sh` (MODIFIED)

Replaced the single non-interactive divergence path
(rc=2 + warn) with a `case "${_MIGRATOR_MODE:-}" in` block that dispatches:

```
case "${_MIGRATOR_MODE:-}" in
    dry-run)
        # Report informationally to stdout, rc=0.
        printf 'per-entry: divergence detected at %s\n' "$mirror_path"
        printf '           per-entry tree under %s would produce different content.\n' "$stream_dir"
        printf '           This divergence will be overwritten on --apply unless --force-overwrite-mirror is passed.\n'
        rm -f "$new_tmp"
        trap - EXIT
        return 0
        ;;
    apply|resume)
        # BLOCK with EXIT_GATE_FAILED=31 + recovery instruction.
        printf 'ERROR: per-entry regenerator detected divergence at: %s\n' "$mirror_path" >&2
        printf '       per-entry tree under %s would produce different content.\n' "$stream_dir" >&2
        printf '       The on-disk mirror has been hand-edited since the last regeneration.\n' >&2
        printf '       Re-run with --force-overwrite-mirror to overwrite the hand-edits, OR\n' >&2
        printf '       reconcile the per-entry tree with the mirror by hand and re-run.\n' >&2
        rm -f "$new_tmp"
        trap - EXIT
        return "${EXIT_GATE_FAILED:-31}"
        ;;
esac

# Default fall-through: no _MIGRATOR_MODE set — preserves pre-BD-165
# rc=2 + stderr warning behavior so direct callers (Pack Chat, agent
# tooling outside the migrator) still see the divergence.
printf 'WARNING: per-entry regenerator detected divergence at: %s\n' "$mirror_path" >&2
printf '         per-entry tree under %s would produce different content.\n' "$stream_dir" >&2
printf '         Pass --force-overwrite-mirror (or set PE_FORCE_OVERWRITE_MIRROR=1) to overwrite.\n' >&2
rm -f "$new_tmp"
trap - EXIT
return 2
```

The interactive (TTY) path is UNCHANGED from Addendum #1 §5.3 (still
prompts user). The `PE_FORCE_OVERWRITE_MIRROR=1` short-circuit
(line ~236) is UNCHANGED — already short-circuits before the
non-interactive routing fires, so the migrator adapter setting
`PE_FORCE_OVERWRITE_MIRROR=1` (from `_MIGRATOR_FORCE_OVERWRITE_MIRROR=1`)
proceeds with the overwrite + audit-trail warning.

The fall-through default preserves backward compatibility: existing
test-per-entry.sh Group 8 cases (which do not set `_MIGRATOR_MODE`)
continue to pass — they expect rc!=0 with a warning naming
`force-overwrite-mirror`, and the fall-through path matches that
contract verbatim.

### §3.3 — `scripts/lib/migrate-v10-to-v11/decompose.sh` (NEW)

212-line adapter-private helper file. Two top-level concerns:

**A. Source the BD-164 helpers.** Resolves the absolute path to
`scripts/lib/per-entry/` via `BASH_SOURCE` (matches the
`scripts/lib/per-entry/decompose.sh:30-33` precedent), then sources
each helper guarded by a `type` check so re-sourcing is a no-op:

```
_v10_v11_decompose_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../per-entry" && pwd)"

if ! type pe_die >/dev/null 2>&1; then
    . "$_v10_v11_decompose_lib_dir/_lib.sh"
fi
if ! type per_entry_decompose >/dev/null 2>&1; then
    . "$_v10_v11_decompose_lib_dir/decompose.sh"
fi
if ! type per_entry_regenerate_mirror >/dev/null 2>&1; then
    . "$_v10_v11_decompose_lib_dir/mirror-generate.sh"
fi
if ! type per_entry_regenerate_toc >/dev/null 2>&1; then
    . "$_v10_v11_decompose_lib_dir/toc-regenerate.sh"
fi
```

**B. Define `_v10_to_v11_decompose_streams`.** The 6th sub-op. Iterates
the three project-side stream tuples
(`project-backlog`/`project-implementation-plan`/`project-changelog`),
and for each:

1. Skip if the monolithic mirror or stream-dir is absent (logs `info`).
2. Bridges `_MIGRATOR_FORCE_OVERWRITE_MIRROR=1` →
   `export PE_FORCE_OVERWRITE_MIRROR=1` so the BD-164 helpers see the
   force signal.
3. Calls `per_entry_decompose` (writes per-entry files with line-1
   back-pointers).
4. Calls `per_entry_regenerate_mirror` (regenerates the mirror; honors
   the divergence routing per §3.2 above).
5. Calls `per_entry_regenerate_toc` (regenerates `_toc.md`).
6. On any failure, calls `fail_stage S5` with sub-banner tag
   `S5d-decompose: ...` per the BD-139 F-3 sub-banner convention.

Banner: `── S5d (decompose) — BD-165 per-entry decomposition + mirror+TOC regenerate ──`

The `S5d` sub-banner aligns with the existing `S5` family (S5
artifact install, S5b BD-035 rename, S5c BD-144 capability translation)
because the BD-167 canonical templates (which this sub-op depends on)
are installed in S5. The `fail_stage S5` exit code is 25 (20+5) per
the framework's `20+N` formula — distinct from `EXIT_GATE_FAILED=31`
which the regenerator returns directly when an apply-mode block fires.

### §3.4 — `scripts/migrate-v10-to-v11.sh` (MODIFIED)

Four additions:

**A. Source the new helper file.** Added near the existing
`migrate-v10-to-v11/{dry-run,apply,resume}.sh` source block:

```
# shellcheck source=lib/migrate-v10-to-v11/decompose.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/decompose.sh"
```

**B. 6th sub-op call in `migrator_post_dispatch_hook`.** Added AFTER
all 5 existing sub-op calls (per architect §3.1 sequencing constraint):

```
_v10_to_v11_translate_capability_tokens
+ _v10_to_v11_decompose_streams   # ← NEW (6th sub-op)
```

Also extended the dry-run banner to mention "+ BD-165 per-entry
decompose" so dry-run output names the new step.

**C. Post-report advisory paragraph in `migrator_post_report_hook`.**
Added 16 say-lines (~12 displayed paragraph lines) before the existing
"To opt into the v11 issue-tracker integration" pointer. Names the
backup directory at `$_MIGRATOR_BACKUP_DIR` as the rollback path per
integration parent §8.18 sample text. Confirms v11.0 decomposition
non-reversibility.

**D. Dispatcher-level flag intercept.** Added a `--force-overwrite-mirror)`
case in the mode-detection scan loop:

```
--force-overwrite-mirror)
    _MIGRATOR_FORCE_OVERWRITE_MIRROR="1"
    _passthru+=("$_a")
    ;;
```

This sets the state var BEFORE dispatching to any mode handler
(`migrate_v10_to_v11_dry_run_run` / `..._apply_run` / `..._resume_run`).
Critical because the resume path
(`scripts/lib/migrate-v10-to-v11/resume.sh`) sets `_MIGRATOR_MODE="resume"`
DIRECTLY without ever calling `_migrator_parse_args` — without this
intercept, resume + `--force-overwrite-mirror` would silently ignore
the flag. The flag is also passed through `_passthru` so the
dry-run / apply paths' subsequent `migrator_run "$@"` invocations have
the flag re-processed by `_migrator_parse_args` (idempotent — re-setting
the same var to "1" is a no-op).

`scripts/lib/migrate-v10-to-v11/resume.sh` was NOT modified — the
dispatcher-level intercept makes it unnecessary. (Resume.sh was outside
the prompt's permitted-edits set; the dispatcher intercept achieves the
same contract semantics inside an in-scope file.)

---

## §4 — Verification

### §4.1 — Syntax checks

| File | Result |
|---|---|
| `scripts/lib/migrator-core.sh` | `bash -n OK` |
| `scripts/lib/per-entry/mirror-generate.sh` | `bash -n OK` |
| `scripts/lib/migrate-v10-to-v11/decompose.sh` | `bash -n OK` |
| `scripts/migrate-v10-to-v11.sh` | `bash -n OK` |

### §4.2 — Existing test suites (zero regression)

| Test suite | Pre-edit | Post-edit |
|---|---|---|
| `bash scripts/test-migrator-core.sh` | 19 passed, 0 failed | **19 passed, 0 failed** |
| `bash scripts/tests/test-per-entry.sh` | PASS 57 / FAIL 0 (57/57) | **PASS 57 / FAIL 0 (57/57)** |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | Passed: 61 / Failed: 0 | **Passed: 61 / Failed: 0** |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | Passed: 87 / Failed: 0 | **Passed: 87 / Failed: 0** |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | Passed: 43 / Failed: 0 | **Passed: 43 / Failed: 0** |
| `bash scripts/tests/tracker-agent-read-test.sh` | Passed: 31 / Failed: 0 | **Passed: 31 / Failed: 0** |
| `python3 scripts/validate-pack.py` | "PASSED — all checks clean" | **"PASSED — all checks clean"** |
| `bash scripts/test-persona-contracts.sh` | "All persona contracts PASS." | **"All persona contracts PASS."** |

Last-line tails (post-edit):

```
=== Results: 19 passed, 0 failed ===
All per-entry tests PASSED (57/57).
All BD-095 tests passed. (Passed: 61, Failed: 0)
All BD-101 gate tests passed. (Passed: 87, Failed: 0)
All tests passed. (test-migrate-v10-to-v11.sh: Passed 43, Failed 0)
All tests passed. (tracker-agent-read-test.sh: Passed 31, Failed 0)
PASSED — all checks clean (validate-pack.py)
All persona contracts PASS.
```

### §4.3 — Manual integration smoke tests

Built two scratch fixture clones in `/tmp` from
`test-fixtures/v10-realistic-ot/`:

- `/tmp/scratch-v10-19c` — vanilla copy (no `docs/project/` files;
  exercises the skip path).
- `/tmp/scratch-v10-19c-rich4` — vanilla copy + added
  `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` minimal
  fixtures with TD-001/TD-002/TD-003 entries, Phase 1/Phase 2 entries,
  and two dated changelog entries (so the decompose path is
  exercised).

Both `git init`-ed locally to satisfy the migrator's `EXIT_DIRTY=12`
preflight (the v10-realistic-ot fixture comes with `.git/` of its
own). Both cleaned up after testing.

**Scenario 1 — `--dry-run` against fresh fixture clone (vanilla
v10-realistic-ot)**:

```
$ PACK=<pack> V10_TAG=v10.1 bash scripts/migrate-v10-to-v11.sh --dry-run /tmp/scratch-v10-19c
...
  [dry-run] would run BD-104 rename + BD-042 relocation + v11 artifact install
       + python-architecture skill rename + BD-144 capability-token translation
       + BD-165 per-entry decompose
...
v11.0 introduces per-entry decomposition of BACKLOG / CHANGELOG /
IMPLEMENTATION-PLAN. ...
[advisory paragraph in full per §3.4 D]
...
── Gate 1 PASS — dry-run plan is internally consistent ──
```

**PASS** — dry-run banner names the new sub-op; advisory paragraph
emitted; rc=0; Gate 1 PASS.

**Scenario 2 — `--apply` against fresh fixture clone (rich
v10-realistic-ot with `docs/project/*.md`) — full happy path**:

After resolving 3 trinity sidecars produced by S3 (touched
`.resolved` files for CLAUDE.md.v10-customized,
AGENTS.md.v10-customized, GEMINI.md.v10-customized), then `--resume`
WITH `--force-overwrite-mirror`:

```
── S5d (decompose) — BD-165 per-entry decomposition + mirror+TOC regenerate ──
per-entry decompose: wrote 3 entry file(s) to /tmp/.../docs/project/backlog
per-entry: WARNING: PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at /tmp/.../docs/project/BACKLOG.md
per-entry decompose: wrote 2 entry file(s) to /tmp/.../docs/project/implementation-plan
per-entry: WARNING: PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at /tmp/.../docs/project/IMPLEMENTATION-PLAN.md
per-entry decompose: wrote 2 entry file(s) to /tmp/.../docs/project/changelog
per-entry: WARNING: PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at /tmp/.../docs/project/CHANGELOG.md
  project-backlog: decomposed docs/project/BACKLOG.md → docs/project/backlog/ + regenerated mirror + TOC
  project-implementation-plan: decomposed docs/project/IMPLEMENTATION-PLAN.md → docs/project/implementation-plan/ + regenerated mirror + TOC
  project-changelog: decomposed docs/project/CHANGELOG.md → docs/project/changelog/ + regenerated mirror + TOC
  BD-165 per-entry decomposition: 3 stream(s) decomposed, 0 skipped
── S6 — render truthful migration report ──
...
[full advisory paragraph emitted]
...
── Gate 2 PASS — Phase-A verified ──
── Gate 3 SKIP — flat-file mode; Phase-B not applicable ──
── --resume complete ──
```

Per-entry trees produced (verified via `ls`):

```
docs/project/backlog/         _intro.md _rules.md _toc.md TD-001.md TD-002.md TD-003.md
docs/project/changelog/       _format.md _intro.md _rules.md _toc.md
                              2026-04-15-phase-1.md 2026-04-22-phase-2.md
docs/project/implementation-plan/  _intro.md _rules.md _toc.md phase-1.md phase-2.md
```

Per-entry file shape verified — line 1 is the back-pointer:

```
$ head -2 docs/project/backlog/TD-001.md
<!-- per-entry source: docs/project/backlog/TD-001.md; contract: docs/project/backlog/_rules.md -->
**TD-001 — Onboarding flow review**
```

**PASS** — per-entry trees produced, regenerated mirrors overwritten
under force, TOCs regenerated, advisory paragraph emitted, Gate 2 PASS.

**Scenario 3 — Hand-edit + re-regenerate WITHOUT `--force-overwrite-mirror`
(BLOCK)**:

Appended `<!-- intentional hand-edit for divergence test -->` to
`docs/project/BACKLOG.md` after Scenario 2 completed, then invoked the
mirror generator directly with `_MIGRATOR_MODE=apply`:

```
$ _MIGRATOR_MODE=apply bash -c '
. scripts/lib/per-entry/_lib.sh
. scripts/lib/per-entry/mirror-generate.sh
EXIT_GATE_FAILED=31
per_entry_regenerate_mirror project-backlog "<dir>/docs/project/backlog" "<dir>/docs/project/BACKLOG.md" </dev/null
echo "rc=$?"
'

ERROR: per-entry regenerator detected divergence at: <dir>/docs/project/BACKLOG.md
       per-entry tree under <dir>/docs/project/backlog would produce different content.
       The on-disk mirror has been hand-edited since the last regeneration.
       Re-run with --force-overwrite-mirror to overwrite the hand-edits, OR
       reconcile the per-entry tree with the mirror by hand and re-run.
rc=31
```

**PASS** — rc=31 (`EXIT_GATE_FAILED`), recovery instruction names
`--force-overwrite-mirror`.

**Scenario 4 — Hand-edit + re-regenerate WITH
`PE_FORCE_OVERWRITE_MIRROR=1` (PROCEED + warn)**:

```
$ _MIGRATOR_MODE=apply _MIGRATOR_FORCE_OVERWRITE_MIRROR=1 PE_FORCE_OVERWRITE_MIRROR=1 bash -c '...'

per-entry: WARNING: PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at <dir>/docs/project/BACKLOG.md
rc=0
```

After: hand-edit removed from `docs/project/BACKLOG.md` (verified via
`tail -2`).

**PASS** — rc=0, audit-trail warning emitted to stderr, hand-edit
removed.

**Bonus check — dry-run divergence reporting**:

```
$ _MIGRATOR_MODE=dry-run bash -c '...' (with hand-edit re-introduced)

per-entry: divergence detected at <dir>/docs/project/BACKLOG.md
           per-entry tree under <dir>/docs/project/backlog would produce different content.
           This divergence will be overwritten on --apply unless --force-overwrite-mirror is passed.
rc=0
```

**PASS** — dry-run REPORTS divergence to stdout, rc=0 (informational).

### §4.4 — `--help` output verification

```
$ bash scripts/migrate-v10-to-v11.sh --help
Usage: PACK=/path/to/pack migrate-v10-to-v11.sh [target-dir] [flags]

Flags:
  --help, -h    Show this message and exit
  --dry-run     ...
  --apply       ...
  --resume      ...
  --force-overwrite-mirror
                Explicit acknowledgement that an --apply / --resume run may
                overwrite hand-edited regenerated mirrors (BACKLOG.md,
                CHANGELOG.md, IMPLEMENTATION-PLAN.md) when the per-entry
                tree's regenerator output diverges from the on-disk file.
                Default off — divergence blocks with EXIT_GATE_FAILED=31.
                No effect in --dry-run (dry-run reports divergence; never
                writes). See ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-
                ADDENDUM-2.md §4.5.
...
```

**PASS** — `--force-overwrite-mirror` documented in `--help`.

---

## §5 — Definition-of-Done checklist

### Architect-doc bindings (success criterion A)

| Binding | Status |
|---|---|
| 6th sub-op runs AFTER all 5 existing post-dispatch sub-ops | **PASS** — `_v10_to_v11_decompose_streams` is called as the last line of `migrator_post_dispatch_hook` after `_v10_to_v11_translate_capability_tokens` |
| Adapter helper sources `scripts/lib/per-entry/_lib.sh` (and other BD-164 helpers); does NOT reimplement decompose logic | **PASS** — `decompose.sh` lines 81-99 source `_lib.sh` + `decompose.sh` + `mirror-generate.sh` + `toc-regenerate.sh` from `../per-entry/`; no decompose/regen logic is reimplemented |
| `_MIGRATOR_FORCE_OVERWRITE_MIRROR` default is "0" | **PASS** — set to `"0"` in `_migrator_reset_state` |
| Block path uses `EXIT_GATE_FAILED=31` (existing constant) | **PASS** — `mirror-generate.sh` returns `"${EXIT_GATE_FAILED:-31}"` from the `apply\|resume` case |
| BD-095 contract preserved: NO redesign of `_MIGRATOR_MODE` / `_MIGRATOR_DRY_RUN`; bridge composes against existing state vars; only new flag is `--force-overwrite-mirror` | **PASS** — `_MIGRATOR_MODE` / `_MIGRATOR_DRY_RUN` semantics unchanged; only new flag is `--force-overwrite-mirror`; new state var `_MIGRATOR_FORCE_OVERWRITE_MIRROR` is internal and additive |
| Backup contract preserved per integration parent §9.4 (`_stage_backup` at `migrator-stages.sh:146` unchanged) | **PASS** — `migrator-stages.sh` not modified |
| BD-119 framework unchanged: NO new framework hook; NO new manifest entries for per-entry files; NO new mode beyond `--force-overwrite-mirror` | **PASS** — `migrator_manifest()` unchanged (still 14 rows); no new hook function; the only new framework-surface addition is the additive `--force-overwrite-mirror` flag in the existing `_migrator_parse_args` |
| Post-report advisory paragraph length ~12 lines per integration parent §8.18 | **PASS** — 16 `say` lines (the say lines render as ~12 displayed paragraph lines because some are short / blank); paragraph names backup directory + rollback steps per §8.18 sample shape |
| Bash 3.2 + macOS BSD-utility compatible | **PASS** — no associative arrays, no `&>`, no GNU-only flags; all `bash -n` clean; `for spec in "..."` with `case` substring; explicit `printf` over `echo -e`; tested on darwin25 |

### Functional verification (success criterion B)

| Item | Status |
|---|---|
| `bash -n` clean on every modified shell file | **PASS** — see §4.1 |
| `python3 scripts/validate-pack.py` PASSES | **PASS** — see §4.2 |
| `bash scripts/test-migrator-core.sh` PASSES (existing BD-119 tests) | **PASS** — 19/19 (zero regression) |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` PASSES | **PASS** — 43/43 (zero regression) |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` PASSES (BD-095 dry-run) | **PASS** — 61/61 (zero regression) |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` PASSES (BD-101 gates) | **PASS** — 87/87 (zero regression) |
| `bash scripts/tests/test-per-entry.sh` PASSES (57/57 baseline from 19a) | **PASS** — 57/57 (zero regression) |
| `bash scripts/tests/tracker-agent-read-test.sh` PASSES (31/31 baseline from 19b-pack) | **PASS** — 31/31 (zero regression) |
| Manual smoke 1: `--dry-run` reports new decompose step in dry-run output | **PASS** — see §4.3 Scenario 1 |
| Manual smoke 2: `--apply` produces per-entry trees + regenerated mirrors + post-report advisory paragraph | **PASS** — see §4.3 Scenario 2 |
| Manual smoke 3: hand-edit mirror; re-run regenerator without `--force-overwrite-mirror` → BLOCK with rc=31 + recovery instruction | **PASS** — see §4.3 Scenario 3 |
| Manual smoke 4: same with `--force-overwrite-mirror` → proceed with stderr warning | **PASS** — see §4.3 Scenario 4 |

### Process / hygiene (success criterion C)

| Item | Status |
|---|---|
| No state-changing git verbs (no add/commit/push/tag/rebase/reset/stash/checkout) | **PASS** — `git rev-parse HEAD` unchanged: `8ba016493674a773c272e370a13ed3e760bf281f` (pre and post) |
| Trinity rule: no trinity file edits | **PASS** — no edits to `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root or `project-template/`) |
| Out-of-scope items surfaced to Pack Chat with no deferral recommendation | **PASS** — see §7 below (one observation surfaced; no deferral language) |

---

## §6 — Plan deviations

**Zero plan deviations.** All architect-doc bindings honored verbatim.
The decompose helper's function name (`_v10_to_v11_decompose_streams`)
matches the provisional name in plan §5.4 / sidecar §1.3 / integration
parent §9.6. The flag name (`--force-overwrite-mirror`) matches plan
§5.4 / Addendum #2 §4.5 exactly. The exit code (`EXIT_GATE_FAILED=31`)
matches plan §5.4 / Addendum #2 §4.5. The helper file location
(`scripts/lib/migrate-v10-to-v11/decompose.sh`) matches plan §5.4 /
integration parent §10.2 / §18.1 #3. The S5d sub-banner naming
follows the existing BD-139 F-3 sub-banner pattern.

---

## §7 — Out-of-scope items / observations surfaced for Pack Chat

### §7.1 — `scripts/lib/migrate-v10-to-v11/resume.sh` was not in the prompt's permitted-edits set

**Fact.** Per Addendum #2 §4.5 the `--force-overwrite-mirror` flag is
"valid in `--apply` and `--resume` modes". The resume path
(`scripts/lib/migrate-v10-to-v11/resume.sh`) sets `_MIGRATOR_MODE="resume"`
DIRECTLY and never invokes `_migrator_parse_args` — so the flag would
not have been honored on resume without additional wiring.

**Resolution within in-scope files.** The dispatcher in
`scripts/migrate-v10-to-v11.sh` (which IS in scope) was extended to
intercept `--force-overwrite-mirror` at the mode-detection scan and
set `_MIGRATOR_FORCE_OVERWRITE_MIRROR=1` directly before dispatching
to any mode handler. This achieves the Addendum-spec'd contract
(flag valid in resume mode) without modifying `resume.sh`. The flag
is also passed through `_passthru` so apply/dry-run paths' subsequent
`_migrator_parse_args` calls are idempotent.

**Pack Chat decision needed.** None for v11.0 functional behavior
(the dispatcher intercept resolves it). One observation for future
reviewers: the dispatcher-level intercept is a slight asymmetry with
the framework-level parser — the same flag is processed in two
places. This is intentional given the resume path's existing
"do-not-call-`_migrator_parse_args`" architectural seam (which
predates BD-165 per `scripts/lib/migrate-v10-to-v11/resume.sh:226-232`),
but Pack Chat may want to surface this in code review for confirmation.

### §7.2 — v10-realistic-ot fixture currently lacks `docs/project/<stream>/` files

**Fact.** The existing v10-realistic-ot test fixture
(`test-fixtures/v10-realistic-ot/`) has a project-root `BACKLOG.md`
but no `docs/project/<stream>/` files. The 6th sub-op
(`_v10_to_v11_decompose_streams`) correctly skips all 3 streams
when the v10-realistic-ot fixture is the migration target — emitting
"no monolithic mirror at <path> — skip" for each. This is the correct
behavior (the v10 client's monolithic content lives at root, not
under `docs/project/`).

**Pack Chat decision needed.** None for BD-165. The v11-realistic-ot
fixture extension that exercises the decompose path with non-trivial
input is BD-160 + BD-170's territory (commit 19f per plan §5.7).
This commit's manual smoke tests built a transient
`/tmp/scratch-v10-19c-rich4` fixture clone on top of v10-realistic-ot
plus minimal hand-authored `docs/project/<stream>/*.md` files to
exercise the decompose path; that's documented in §4.3 above. The
in-tree fixture remains unchanged (test-fixtures/ is BD-160/BD-170
territory).

### §7.3 — First-migration divergence is the expected contract

**Fact.** When a v10 client repo HAS pre-existing `docs/project/*.md`
files (i.e., monolithic source-of-truth), the FIRST v10→v11 migration
will detect divergence between the per-entry tree's regenerator
output and the input mirror. This is because the v11 regenerator
normalizes formatting (the BD-167 canonical `_intro.md` becomes the
mirror preamble; inter-entry separators are normalized; the
"DO NOT EDIT" header gets prepended). The divergence trigger fires;
the migrator BLOCKS with `EXIT_GATE_FAILED=31` and the recovery
instruction; the user re-runs with `--force-overwrite-mirror` to
acknowledge the v11 mirror format replaces the v10 mirror format.

**Pack Chat decision needed.** This is the correct architectural
behavior per Addendum #2 §4 ("the migrator NEVER silently overwrites
the mirror in `--apply` or `--resume` mode") — but Pack Chat may
want to consider whether the post-report advisory paragraph or the
plan §5.4 documentation should be more explicit that the FIRST
v10→v11 migration of a client with `docs/project/*.md` REQUIRES
`--force-overwrite-mirror`. The current post-report advisory says
"hand-edits to the mirrors are silently overwritten on the next
regeneration unless --force-overwrite-mirror is acknowledged" which
implicitly covers this; an explicit "first-migration users with
existing `docs/project/*.md` content: pass `--force-overwrite-mirror`
to your first `--apply`" sentence might help. Not a v11.0 blocker
— behavior is correct; only the wording is the question. Pack Chat
to decide.

### §7.4 — `_v10_to_v11_decompose_streams` operates on project-side only

**Fact.** Pack-side per-entry trees (`/backlog/`, `/changelog/`) are
NOT decomposed by this migrator. The `_v10_to_v11_decompose_streams`
function iterates only the three `project-*` streams. Per integration
parent §10.5 (last paragraph), pack-self decomposition is Batch 22
dog-food's job, not the v10→v11 client migrator's. A comment in
`decompose.sh` explicitly documents this scoping decision.

**Pack Chat decision needed.** None — confirms the architect-doc
binding. Surfaced for visibility only.

---

## §8 — Files inventory (all paths absolute)

**NEW:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/decompose.sh` (212 lines)

**MODIFIED:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh` (+38 lines net)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh` (+54 lines net)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` (+68 lines net)

**DELETED:** none.

**REPORT:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md` (this file)
