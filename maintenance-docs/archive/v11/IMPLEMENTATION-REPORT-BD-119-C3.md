# IMPLEMENTATION-REPORT-BD-119 C-3 — core sequencer + public API (surface lock)

**Agent:** pack-coder
**Branch:** `worktree-agent-accaa265ddb0652b7`
**Worktree HEAD SHA at completion:** `2b171848243edc28df4601ceb353f26f1fe05d48`
(no commits made — pack-coder never stages or commits; HEAD unchanged from
session start, as expected by the harness)
**Date:** 2026-05-08
**Scope:** BD-119, commit C-3 only (per `PLAN-BD-119.md` §6).
**Tasks bundled:** T-7 + T-11 (PLAN §4 / §6 row "C-3").

---

## 1. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-accaa265ddb0652b7

$ git rev-parse HEAD
2b171848243edc28df4601ceb353f26f1fe05d48

$ git rev-parse --abbrev-ref HEAD
worktree-agent-accaa265ddb0652b7

$ git log --oneline -8
2b17184 feat: v11 — BD-119 C-2: land migrator-core/stages/manifest skeletons
dcd37f7 feat: v11 — pack-coder agent + repo-local Pack memory section
fda99ef feat: v11 — BD-119 C-1: detect_target_pack_version + validate-pack Check 26 (lenient)
6286fcf feat: v11 — BD-115 existing-project-mid-dev fixture
d7b3f07 docs: v11 — BD-119 architecture + plan
4a6aa6b docs: v11 — BD-114..BD-120 pre-Phase-A persona-coverage batch (Open)
ef3b41e feat: v11 — BD-113 test-fixtures/ persistent baseline directory
1228db3 fix: ci — add pyyaml dep to tests job (was only in validate job)

$ ls maintenance-docs/v11-implementation/
ARCHITECTURE-BD-119.md
IMPLEMENTATION-REPORT-BD-115.md
IMPLEMENTATION-REPORT-BD-119-C2.md
IMPLEMENTATION-REPORT-BD-119.md
PLAN-BD-119.md
SEMANTIC-AUDIT-REPORT.md

$ ls scripts/lib/ | grep migrator
migrator-core.sh
migrator-manifest.sh
migrator-stages.sh
```

All required artifacts present:

- `pwd` ends in `/.claude/worktrees/agent-accaa265ddb0652b7/` — worktree
  discipline confirmed; every Write/Edit in this session goes under this
  path.
- HEAD at `2b17184` (the BD-119 C-2 skeleton commit), descended from
  `fda99ef` (C-1) and `d7b3f07` (architecture + plan).
- Branch is `worktree-agent-accaa265ddb0652b7` (matches `-agent-*` prefix).
- `maintenance-docs/v11-implementation/` contains
  `ARCHITECTURE-BD-119.md`, `PLAN-BD-119.md`,
  `IMPLEMENTATION-REPORT-BD-119.md` (C-1), and
  `IMPLEMENTATION-REPORT-BD-119-C2.md` (C-2).
- `scripts/lib/` contains the three migrator skeletons from C-2.

---

## 2. Per-task summary

### T-7 — Core sequencer + arg parsing + EXIT trap + adapter-contract reader

**File:** `scripts/lib/migrator-core.sh` (modified — was 114 lines after C-2,
now 496 lines).
**Line delta:** +420 / −41 (per `git diff --stat`).
**What landed:**

- `say` / `info` / `warn` / `die` helpers — verbatim from the monolith
  lines 47–50, so behavior-preservation diffs (C-5 / C-6) will match
  banner output exactly.
- `fail_stage <stage> <msg>` — verbatim 20+N formula from monolith
  lines 52–59 (capped at 30).
- Source-time loading of sibling libs `migrator-stages.sh` and
  `migrator-manifest.sh` via `_migrator_core_dir` lookup
  (`BASH_SOURCE[0]` + `dirname` + `pwd`; bash 3.2 portable, no
  `:A`-style path resolution).
- Internal env-var family `_MIGRATOR_*` documented:
  `_MIGRATOR_TARGET`, `_MIGRATOR_DRY_RUN`, `_MIGRATOR_MODE`,
  `_MIGRATOR_STATE_DIR`, `_MIGRATOR_BACKUP_DIR`,
  `_MIGRATOR_REPORT_DONE`. Reset by `_migrator_reset_state`, which is
  called at file source time (initialization) and at the start of each
  `migrator_run`.
- Adapter-contract reader (`_migrator_check_adapter_contract`):
  iterates the four required `MIGRATOR_*` scalars
  (`MIGRATOR_FROM_VERSION`, `MIGRATOR_TO_VERSION`,
  `MIGRATOR_BASELINE_TAG`, `MIGRATOR_OWN_SIDECAR_SUFFIX`), checks
  `MIGRATOR_PRIOR_SIDECAR_SUFFIXES` is *declared* (via
  `declare -p`, even if empty), and verifies the five required hooks
  (`migrator_manifest`, `migrator_directory_sweeps`,
  `migrator_relocations`, `migrator_artifact_installs`,
  `migrator_post_report_hook`) are defined via `declare -F`. Any
  missing piece exits `EXIT_INTERNAL` with a clear "adapter contract
  violation" message naming the specific missing piece.
- EXIT trap (`_migrator_exit_trap`): on any path out of `migrator_run`
  (success or failure), if the report has not yet been rendered AND
  the state dir exists AND `customization_report` is loaded AND
  `dispositions.tsv` exists, it attempts a best-effort partial-report
  render. Architecture §6 I9 ("report rendering is mandatory — even
  on partial failure") is now structurally guaranteed.
- Stage sequencer (`_migrator_run_stages`): calls in order
  `_stage_preflight → _stage_backup → _stage_libs → [pre-dispatch hook] → _stage_dispatch → [post-dispatch hook] → _stage_relocations → _stage_artifact_installs → _stage_report → migrator_post_report_hook`.
  Optional hooks (`migrator_pre_dispatch_hook`,
  `migrator_post_dispatch_hook`) are invoked only when the adapter
  defined them (`declare -F` guard), matching architecture §3.2's
  "Optional adapter-declared functions" contract.
- Argument parser (`_migrator_parse_args`):
  - `--help` / `-h` → prints usage and exits 0.
  - `--dry-run` → sets `_MIGRATOR_DRY_RUN=1`, `_MIGRATOR_MODE=dry-run`
    (BD-095 plumbing per PLAN POQ-2; stages will branch on this in C-4).
  - `--apply` → default mode, recognized for symmetry.
  - `--resume` → errors loudly with "not yet implemented; tracked as
    BD-095" per PLAN OQ1 disposition (do not silently treat as fresh
    run).
  - `--` → end-of-flags sentinel; remaining args are positional.
  - Any other `--*` → unknown-option error.
  - Single positional argument is the target dir; resolved to absolute
    via `cd … && pwd`, falling back to the literal string if `cd`
    fails (so the downstream preflight error names what the user
    typed). Default `.`.
  - Derives `_MIGRATOR_STATE_DIR` and `_MIGRATOR_BACKUP_DIR` from the
    version pair (architecture §3.3 — names are *derived*, never
    adapter-declared, so a defect fixed once is fixed for every
    adapter).
  - Exports `TARGET`, `STATE_DIR`, `BACKUP_DIR` for the stage
    functions (preserves the monolith-era contract `_stage_*`
    functions consume).
- `migrator_run "$@"`: sets `set -euo pipefail`, resets state, installs
  the EXIT trap, validates the adapter contract, parses args, runs the
  stages.
- `migrator_dispatch <target-dir>`: thin wrapper around `migrator_run`
  that requires exactly one argument (no flags) per architecture §3.2;
  used by external harnesses (BD-114).

### T-11 — Detect / select / baseline-to-tmp / target-surface helpers

Same file (`scripts/lib/migrator-core.sh`).

- `migrator_detect_target_version <target-dir>`: lazy-loads
  `lib/detect.sh` if `detect_target_pack_version` is not already
  defined (so external callers can use this without manually sourcing
  detect.sh first), then delegates. The C-1 commit
  (`fda99ef`) already added `detect_target_pack_version` to detect.sh;
  this function is the framework-side wrapper.
- `migrator_select_adapter <from-version>`: globs
  `$PACK/scripts/migrate-v*-to-v*.sh`, parses the version pair from
  each filename via the regex `migrate-v([0-9]+)-to-v([0-9]+)\.sh`,
  and returns the path of the unique match for `<from-version>`.
  Accepts both `v10` and `10` (strips leading `v`). Errors if zero
  matches (no adapter for that from-version) or more than one match
  (PLAN POQ disposition: hotfix-style names like
  `migrate-v10-to-v11-hotfix.sh` would currently fail filename-regex
  and be skipped, so collision is only triggered by genuine
  duplicate-named files — matches the OQ3 "glob with ambiguity
  detection" intent).
  Bash 3.2 portable — no `nullglob`; uses an inner `[[ -e $f ]]` guard
  to handle the no-match case.
- `migrator_baseline_to_tmp <pack-relpath> <tmpfile>`: writes the
  BASE blob to `<tmpfile>` via `git -C $PACK show $MIGRATOR_BASELINE_TAG:<pack-relpath>`.
  Returns 0 if the file existed at the baseline tag, non-zero
  (with `<tmpfile>` truncated to empty) otherwise. The signature
  differs from the monolith's `v10_baseline_to_tmp` (which echoed a
  fresh `mktemp` path on stdout): per PLAN §3.1 / architecture §3.2,
  the framework version takes the tmpfile as a caller-provided
  argument so the caller controls cleanup. The monolith's pattern is
  `mktemp` + `migrator_baseline_to_tmp pack_rel /tmpfile + use + rm`
  in the v10→v11 adapter (lands in C-6).
- `migrator_target_surface_for_version <vN>`: returns a
  newline-delimited list of project-relative paths that a vN install
  creates and that real-client customization can target. Currently
  knows v10 (8 paths: trinity + per-CLI agent dirs + codex config +
  BACKLOG.md) and v11 (14 paths: v10 surface plus HELP-FRAGMENT,
  tracker.toml.example, ISSUE_TEMPLATE, per-CLI pack-help). Other
  versions echo `unknown` and return non-zero (so callers under
  `set -e` fail fast on a typo). Architecture §9.2: this is the BD-120
  consumer surface; intentionally a list, not a transformation map.

### Stages / manifest stubs (NOT modified — C-4 work)

- `scripts/lib/migrator-stages.sh` — UNCHANGED from C-2. Stage bodies
  remain stubs that return 1. C-3 wires them into the sequencer; their
  bodies land in C-4 (PLAN T-8, T-9, T-10).
- `scripts/lib/migrator-manifest.sh` — UNCHANGED from C-2. Same
  reason.

This is consistent with the C-3 contract per the prompt:
"After C-3, the framework can run end-to-end on a manifest, but real
per-version dispatch logic still lands in C-4 (manifest engine) and
C-5 (behavior-preservation harness). … Stub them where C-3 needs to
touch them so subsequent commits can fill in." A test
`bash migrate-v10-to-v11.sh` against a fixture today would still get
through preflight only as far as `_stage_preflight`'s stub returning 1
— which is the expected end-state until C-4 fills bodies and C-6 cuts
the adapter over.

---

## 3. Files changed inventory

| Path | Change type | Lines (after) | Net delta |
|---|---|---|---|
| `scripts/lib/migrator-core.sh` | Modified (was C-2 skeleton) | 496 | +420 / −41 |
| `scripts/lib/migrator-stages.sh` | Unchanged | 67 | 0 |
| `scripts/lib/migrator-manifest.sh` | Unchanged | 68 | 0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C3.md` | NEW | (this file) | (this file) |

Total: 1 modified, 1 new, 0 deleted.

**No PM-only files touched** (BACKLOG.md, CHANGELOG.md, README.md,
PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md/AGENTS.md/GEMINI.md trinity
all unchanged). **No trinity update needed for this commit**; PLAN §9
defers trinity touches to C-7.

**No other source files modified.** Specifically not modified
(scope-fence per the prompt): `scripts/migrate-v10-to-v11.sh`
(monolith — refactor lands in C-6), `scripts/lib/customization-preserve.sh`,
`scripts/lib/three-way.sh`, `scripts/lib/detect.sh` (the C-1 addition
of `detect_target_pack_version` is already on tree), `scripts/init-project.sh`
(OQ4 deferred), `scripts/migrate-v9-to-v10.sh` (frozen),
`test-fixtures/build.sh` (BD-115 / BD-120 surface),
`scripts/validate-pack.py` (Check 26 needs no changes — its strict-mode
assertions from C-2 are still the right contract for C-3).

---

## 4. Verification output

### 4.1 `bash -n` syntax checks (every modified file)

```
$ bash -n scripts/lib/migrator-core.sh
OK
$ bash -n scripts/lib/migrator-stages.sh
OK
$ bash -n scripts/lib/migrator-manifest.sh
OK
```

All three pass under macOS bash 3.2 (the Apple-shipped default at
`/bin/bash`). No GNU-only flags, no bash 4+ features
(no associative arrays, no `&>`, no `${var^^}` case-conversion — that
was caught and replaced with a `tr '[:lower:]' '[:upper:]'` call in
the usage helper).

### 4.2 Source + `type` smoke (matches PLAN §6 row "C-3" verification)

```
$ bash -c 'set -e; source scripts/lib/migrator-core.sh; \
    type migrator_run migrator_dispatch \
         migrator_detect_target_version migrator_select_adapter \
         migrator_baseline_to_tmp migrator_target_surface_for_version \
         >/dev/null && echo all six public-API names defined'
all six public-API names defined
```

The PLAN §6 C-3 row says "**Public surface locked at this commit**" and
gives this exact smoke as the verification. PASS.

### 4.3 `python3 scripts/validate-pack.py` (last 12 lines)

```
── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 8 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym

============================================================
PASSED — all checks clean
```

All 26 checks pass. Check 26's strict-mode contract from C-2 still
holds with C-3's expansion (six public-API names declared, eight
exit-code constants declared, EXIT_NOT_V10 synonym preserved).

### 4.4 Existing detect.sh test suite (regression check)

```
$ bash scripts/test-detect.sh 2>&1 | tail -3
=== Results: 40 passed, 0 failed ===
```

The existing 40-case `test-detect.sh` (which covers
`detect_target_pack_version` from C-1) is unchanged and still green.
C-3 did not modify `lib/detect.sh`.

### 4.5 `git status` (working-tree-discipline check)

```
$ git status --short
 M scripts/lib/migrator-core.sh
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C3.md
```

One modified file (the C-3 expansion) and one new file (this report).
Zero git state changes performed by the agent (no
`git add`, `git commit`, `git push`, `git tag`, `git checkout`, etc.).
HEAD is unchanged from the session start.

---

## 5. Plan deviations

**Zero plan deviations.** PLAN §6 row "C-3" specifies T-7 + T-11; both
are now LIVE in `migrator-core.sh`. Stage bodies in `migrator-stages.sh`
and `migrator-manifest.sh` remain stubs (C-4 work, intentionally), per
the explicit prompt instruction "Do NOT do C-4 work … Stub them where
C-3 needs to touch them."

The single API-shape choice that warrants explicit callout (and is NOT
a deviation, since it matches PLAN §3.1 / architecture §3.2 verbatim):

- `migrator_baseline_to_tmp <pack-relpath> <tmpfile>` takes the
  tmpfile path as an explicit argument rather than echoing a fresh
  `mktemp` path on stdout (the monolith's
  `v10_baseline_to_tmp` did the latter). Per PLAN §3.1's signature
  table the framework signature is `<pack-relpath> <tmpfile>` →
  "side effect: writes BASE", so this matches the locked surface. The
  v10→v11 adapter at C-6 will call
  `local tmp=$(mktemp); migrator_baseline_to_tmp "$pack_rel" "$tmp" || true; … rm -f "$tmp"`.

Line counts comfortably within PLAN T-7 (+180) and T-11 (+90)
budget — total +270 budget vs +420 actual delta on the file. The
overrun is in the helpers (`say/info/warn/die/fail_stage`,
`_migrator_required_*` arrays, `_migrator_exit_trap`,
`_migrator_run_stages`, `_migrator_usage`, `_migrator_parse_args`,
`_migrator_check_adapter_contract`, `_migrator_reset_state`) — none
of these are new functionality, they are the splittings the
architecture §3.1 explicitly requested ("the file an adapter sources …
public API, argument parsing, stage sequencing, exit-code constants").
The monolith had ~120 lines covering the same surface area
(`fail_stage`, `say/info/warn/die`, S0..S6 sequencing, `main`/`usage`).

---

## 6. New POQs introduced

**Zero new POQs.** All POQs from PLAN §15 still apply unchanged:

- POQ-1 (manifest TSV: heredoc vs separate file) — not exercised in
  C-3; the manifest engine bodies land in C-4 / C-9 of T-9.
- POQ-2 (`--dry-run` plumbing depth) — handled by C-3 plumbing only:
  arg parser sets `_MIGRATOR_DRY_RUN`, stage stubs do not yet branch
  on it. C-4 stages will short-circuit writes when set. Matches the
  POQ-2 default ("BD-119 ships `--dry-run` flag plumbing only").
- POQ-3 (`[pack] version` write to tracker.toml) — defers to C-4
  `_stage_report` body per PLAN T-10. Not exercised in C-3.
- POQ-4 (snapshot file location) — already on `.gitignore` (verified
  in C-2 report); the snapshot file is not present in this worktree
  (it was created in the worktree where C-1 / C-2 ran; it lives
  per-worktree per the gitignore comment "Lives only on the
  implementer's working tree"). No action required for C-3.

One micro-implementation choice taken in C-3 worth recording (not a
new POQ — the architecture and plan accommodate either option):

- The framework's `_migrator_exit_trap` calls
  `customization_report` only when the function is *defined* AND the
  state dir AND `dispositions.tsv` exist. This means a preflight or
  backup failure (i.e. before `_stage_libs` sources the report
  library) gets no partial report — the user sees the failure
  message and that is all. Architecture §6 I9 says report-rendering
  is "mandatory — even on partial failure" but does not specify
  what to do when the report library has not been loaded yet. Two
  resolutions were possible: (a) source the lib in the trap if it
  is missing (more code, more chances to mask the original error),
  or (b) skip report rendering when the lib was never loaded in this
  run (the monolith does not render either — it `die`s before S6).
  C-3 chose (b) for monolith parity. If the C-5 / C-6 behavior-
  preservation harness reports a divergence on this axis, the choice
  is reversible to (a) without changing the public surface.

---

## 7. Definition-of-Done for C-3

Per PLAN §6 row "C-3" the verification points are: bash -n clean on
all touched files, and the smoke `bash -c 'source …; type <six names>'`
returns 0 for all six. PLAN §14 has the broader BD-119 DoD; the
subset relevant to C-3 (i.e. items that should be true *now*, not at
final BD closure):

| Item | Status | Evidence |
|---|---|---|
| `bash -n` clean on `migrator-core.sh` | PASS | §4.1 |
| `bash -n` clean on `migrator-stages.sh` | PASS | §4.1 (file unchanged from C-2 baseline) |
| `bash -n` clean on `migrator-manifest.sh` | PASS | §4.1 (file unchanged from C-2 baseline) |
| `python3 scripts/validate-pack.py` exits 0 with all 26 checks PASS | PASS | §4.3 |
| Six public-API names callable via `type` after sourcing core | PASS | §4.2 |
| Eight exit-code constants present (Check 26 confirms) | PASS | §4.3 |
| `EXIT_NOT_V10` back-compat synonym preserved | PASS | §4.3 |
| Public surface (function names, variable names, exit-code symbols) frozen | PASS | No name in §3.1 / §3.5 of PLAN was renamed; Check 26 enforces |
| `say/info/warn/die/fail_stage` helpers match monolith verbatim (banner-text parity for behavior-preservation diff) | PASS | Lines 47–59 of monolith vs lines after `# ── Logging helpers ──` of C-3 core |
| Stage sequencer calls all seven `_stage_*` functions in architecture-§6 order | PASS | `_migrator_run_stages` in core (preflight → backup → libs → [pre-dispatch hook] → dispatch → [post-dispatch hook] → relocations → artifact_installs → report → post-report-hook) |
| Adapter-contract reader checks all five required hooks + four required vars + the prior-sidecars array | PASS | `_migrator_check_adapter_contract` in core |
| EXIT trap installed by `migrator_run` (architecture §6 I9 guarantee) | PASS | `trap _migrator_exit_trap EXIT` in `migrator_run` body |
| `migrator_select_adapter` glob-discovers from `$PACK/scripts/migrate-v*-to-v*.sh` (PLAN OQ3) | PASS | Body of `migrator_select_adapter` in core; bash 3.2 compatible (no `nullglob`) |
| `migrator_target_surface_for_version` returns a list for v10 and v11 (PLAN BD-120 cue) | PASS | Body of `migrator_target_surface_for_version` in core |
| `migrator_detect_target_version` delegates to `lib/detect.sh::detect_target_pack_version` (C-1 surface) | PASS | Body of `migrator_detect_target_version` in core; lazy-loads detect.sh on demand |
| `migrator_baseline_to_tmp` uses `MIGRATOR_BASELINE_TAG` (architecture §C8) | PASS | Body of `migrator_baseline_to_tmp` in core; signature `<pack-relpath> <tmpfile>` matches PLAN §3.1 |
| No public-API name in §3 was renamed after C-3 | PASS (this is C-3 itself) | The six names in PLAN §3.1 are byte-identical to the names declared in C-2 + C-3 core |
| No PM-only file modified | PASS | §3 inventory; `git status` confirms |
| No git state changes performed | PASS | HEAD unchanged from session start (`2b17184…`); zero `git add/commit/push/tag/checkout` invocations |
| Trinity rule respected | PASS | No CLAUDE/AGENTS/GEMINI edits this commit; PLAN defers to C-7 |
| Report file exists at the agreed worktree path | PASS | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C3.md` (this file); path is under the worktree per the prompt's "WRITE TARGET DISCIPLINE" |

Items that intentionally do NOT pass at C-3 (they are C-4 / C-5 / C-6
work and the prompt explicitly scopes them out):

- Stage bodies (`_stage_preflight` etc.) implementing I1..I8 — C-4 work.
- Manifest TSV parser + trinity-parity validator + dispatch engine
  bodies — C-4 work.
- The v10→v11 adapter refactored to source the framework — C-6 work.
- Behavior-preservation harness — C-5 / C-6 work.
- README / pack-repo trinity bullet for the framework — C-7 work.

---

## 8. Files touched — full unified diffs

### 8.1 `scripts/lib/migrator-core.sh` (modified)

The full pre/post-state shows up via `git diff scripts/lib/migrator-core.sh`.
Post-state (final file contents) shown in §9 below; the unified diff is
~520 lines and is reproducible from the C-2 baseline (commit `2b17184`)
plus the C-3 final content. A faithful re-application path is:

1. Start from `scripts/lib/migrator-core.sh` at HEAD `2b17184` (the
   C-2 skeleton — 114 lines).
2. Replace the entire file with the full contents in §9 below (496
   lines).
3. Run `bash -n scripts/lib/migrator-core.sh` (must return 0).
4. Run `python3 scripts/validate-pack.py` (must end with
   `PASSED — all checks clean`).
5. Run `bash -c 'source scripts/lib/migrator-core.sh; type migrator_run
   migrator_dispatch migrator_detect_target_version migrator_select_adapter
   migrator_baseline_to_tmp migrator_target_surface_for_version'` (must
   exit 0 with all six identified as functions).

The post-C-3 file content is canonical; the diff is mechanically
derivable.

---

## 9. Full file contents (verbatim) — `scripts/lib/migrator-core.sh`

```bash
# scripts/lib/migrator-core.sh — orchestrator for the BD-119 N→N+1 migrator
# framework.
#
# Sourced by per-version adapters (e.g. `scripts/migrate-v10-to-v11.sh`) and by
# external harnesses (BD-114 `dry-run-real-ot.sh`). Adapters declare a small
# version-specific contract via `MIGRATOR_*` environment variables and a set
# of hook functions, then call `migrator_run "$@"`. Every shared safety
# concern (preflight, backup, three-way dispatch, report rendering, exit
# codes, dry-run, idempotency) lives here so per-version adapters can never
# regress the N→N+1 safety contract.
#
# Architecture: maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
# Plan:         maintenance-docs/v11-implementation/PLAN-BD-119.md §3
#
# State at C-3 (this file):
#   - Public-API surface FROZEN per PLAN §3 (six function names + eight
#     exit-code constants + EXIT_NOT_V10 synonym).
#   - Stage sequencer + arg parser + EXIT trap + adapter-contract reader
#     are LIVE (this is T-7 from PLAN §4).
#   - Public-API helpers `migrator_detect_target_version`,
#     `migrator_select_adapter`, `migrator_baseline_to_tmp`,
#     `migrator_target_surface_for_version` are LIVE (T-11).
#   - `_stage_*` bodies in `migrator-stages.sh` and `_manifest_*` bodies in
#     `migrator-manifest.sh` remain stubs that return 1 — bodies land in
#     C-4 (PLAN T-8, T-9, T-10). An end-to-end `migrator_run` call will
#     therefore reach `_stage_preflight` and fail there; this is expected
#     and lets the framework be wired up before stage bodies are written.
#
# Internal env-var conventions:
#   MIGRATOR_*   adapter-declared (read by core; FROZEN public surface)
#   _MIGRATOR_*  core-internal (reset between runs; not part of public surface)
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Source sibling libraries ───────────────────────────────────────────────
#
# Resolve the directory containing this file independent of $PWD, so the
# sibling libs load whether the adapter sources by absolute or relative
# path. macOS bash 3.2 compatible — no `${BASH_SOURCE[0]:A}` zsh-isms.

_migrator_core_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=migrator-stages.sh disable=SC1091
. "$_migrator_core_dir/migrator-stages.sh"
# shellcheck source=migrator-manifest.sh disable=SC1091
. "$_migrator_core_dir/migrator-manifest.sh"

# ── Exit-code constants (PLAN §3.5; FROZEN) ────────────────────────────────
#
# Adapters reference these by name, never by literal value. Stage failures
# use the `20+N` formula computed by `fail_stage` (see helpers below).

readonly EXIT_PACK_INVALID=10
readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_NOT_BASELINE=13
readonly EXIT_BASELINE_MISSING=14
readonly EXIT_LIB_MISSING=15
readonly EXIT_ALREADY_MIGRATED=16
readonly EXIT_INTERNAL=99

# Back-compat synonym — the monolithic v10→v11 migrator exposed
# `EXIT_NOT_V10`. Architecture §C1 / PLAN §3.5 require the rename to
# `EXIT_NOT_BASELINE` plus a synonym so any external caller that grepped the
# old name still resolves. Adapters SHOULD use `EXIT_NOT_BASELINE` directly.
readonly EXIT_NOT_V10="$EXIT_NOT_BASELINE"

# ── Logging helpers (replaces the monolith's say/info/warn/die/fail_stage) ─
#
# These names match the monolith's helpers verbatim so behavior-preservation
# diffs against the pre-refactor stdout do not regress on banner text.
# Defined unconditionally — adapters SHOULD NOT redefine them. (Bash has no
# private-namespace mechanism; convention is the only enforcement.)

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-$EXIT_INTERNAL}"; }

# fail_stage <stage-id> <message>
#   stage-id is "S0".."S6" (or any "S<N>" pattern). Numeric exit code is
#   `20 + N`, capped at 30 (PLAN §3.5 + monolith parity at lines 52–59).
fail_stage() {
    local stage="$1" msg="$2"
    local n="${stage#S}"
    local code=$(( 20 + n ))
    (( code > 30 )) && code=30
    printf 'error: stage %s failed: %s\n' "$stage" "$msg" >&2
    exit "$code"
}

# ── Internal state (reset on every migrator_run / migrator_dispatch call) ──
#
# Adapters MUST NOT read or write these. They are documented here so the
# core's contract is explicit — naming convention is `_MIGRATOR_*`.
#
#   _MIGRATOR_TARGET       absolute path to the target project
#   _MIGRATOR_DRY_RUN      "1" if --dry-run, else "0"
#   _MIGRATOR_MODE         one of: apply | dry-run | resume
#   _MIGRATOR_STATE_DIR    "$_MIGRATOR_TARGET/.pack-migrate-<from>-to-<to>"
#   _MIGRATOR_BACKUP_DIR   "$_MIGRATOR_STATE_DIR-backup"
#   _MIGRATOR_REPORT_DONE  "1" once `_stage_report` has run; gates the
#                          EXIT trap's truthful-report-on-failure guarantee
#                          so a failed run still attempts to render the
#                          report exactly once.

_migrator_reset_state() {
    _MIGRATOR_TARGET=""
    _MIGRATOR_DRY_RUN="0"
    _MIGRATOR_MODE="apply"
    _MIGRATOR_STATE_DIR=""
    _MIGRATOR_BACKUP_DIR=""
    _MIGRATOR_REPORT_DONE="0"
}
_migrator_reset_state

# ── Adapter-contract reader ────────────────────────────────────────────────
#
# Validates the adapter declared the required MIGRATOR_* variables and
# defined the required hook functions before `migrator_run` was called.
# Errors with EXIT_INTERNAL when the adapter is malformed — this is a
# coding bug in the adapter, not a user-facing failure.

_migrator_required_vars=(
    MIGRATOR_FROM_VERSION
    MIGRATOR_TO_VERSION
    MIGRATOR_BASELINE_TAG
    MIGRATOR_OWN_SIDECAR_SUFFIX
)

# MIGRATOR_PRIOR_SIDECAR_SUFFIXES is a bash array — checked separately
# because `[[ -z "${VAR[@]}" ]]` is awkward for empty arrays. The check
# is "declared" (even if empty), not "non-empty" (some transitions may
# have no prior sidecars).

_migrator_required_hooks=(
    migrator_manifest
    migrator_directory_sweeps
    migrator_relocations
    migrator_artifact_installs
    migrator_post_report_hook
)

_migrator_check_adapter_contract() {
    local var hook
    for var in "${_migrator_required_vars[@]}"; do
        # Indirect expansion bash 3.2 compatible — no nameref.
        if [[ -z "${!var:-}" ]]; then
            die "adapter contract violation: $var must be set before sourcing migrator-core.sh / calling migrator_run" \
                "$EXIT_INTERNAL"
        fi
    done
    # MIGRATOR_PRIOR_SIDECAR_SUFFIXES must be declared (declare -p succeeds)
    # but may be empty.
    if ! declare -p MIGRATOR_PRIOR_SIDECAR_SUFFIXES >/dev/null 2>&1; then
        die "adapter contract violation: MIGRATOR_PRIOR_SIDECAR_SUFFIXES array must be declared (use empty array if no priors)" \
            "$EXIT_INTERNAL"
    fi
    for hook in "${_migrator_required_hooks[@]}"; do
        if ! declare -F "$hook" >/dev/null 2>&1; then
            die "adapter contract violation: required hook function $hook is not defined" \
                "$EXIT_INTERNAL"
        fi
    done
}

# ── Stage sequencer + EXIT trap ────────────────────────────────────────────
#
# Architecture §6 I9: report rendering is mandatory — even on partial
# failure the core attempts a final report render so the user has a
# truthful artifact. The trap fires on any path out of `migrator_run`
# (including `die`, `fail_stage`, and `set -e` propagation).

_migrator_exit_trap() {
    local rc=$?
    # Only attempt a report render once. If `_stage_report` already ran
    # (rc=0 path), do nothing. If we are bailing before the report stage
    # and the state dir exists, attempt a best-effort render so the user
    # sees what classifications happened up to the failure point.
    if [[ "$_MIGRATOR_REPORT_DONE" == "0" \
       && -n "$_MIGRATOR_STATE_DIR" \
       && -d "$_MIGRATOR_STATE_DIR" ]]; then
        # Only attempt if customization_report is actually defined (the
        # libs were loaded by `_stage_libs`). Pre-libs failures (e.g.
        # `_stage_preflight` or `_stage_backup`) have no report to render.
        if declare -F customization_report >/dev/null 2>&1 \
           && [[ -f "$_MIGRATOR_STATE_DIR/dispositions.tsv" ]]; then
            customization_report \
                "$_MIGRATOR_STATE_DIR/dispositions.tsv" \
                "$_MIGRATOR_STATE_DIR/report.md" \
                "${MIGRATOR_FROM_VERSION:-vN} → ${MIGRATOR_TO_VERSION:-vM} migration customization report (partial — run failed at exit code $rc)" \
                2>/dev/null || true
            warn "migration failed (exit $rc); partial report rendered to $_MIGRATOR_STATE_DIR/report.md"
        fi
    fi
    return "$rc"
}

# Stage order is fixed (architecture §6, PLAN §3.4). The seven stages are
# the I1..I9 invariants in execution order. Adapters cannot reorder.
_migrator_run_stages() {
    _stage_preflight
    _stage_backup
    _stage_libs
    # Optional pre-dispatch hook (architecture §3.2; default no-op).
    if declare -F migrator_pre_dispatch_hook >/dev/null 2>&1; then
        migrator_pre_dispatch_hook
    fi
    _stage_dispatch
    # Optional post-dispatch hook.
    if declare -F migrator_post_dispatch_hook >/dev/null 2>&1; then
        migrator_post_dispatch_hook
    fi
    _stage_relocations
    _stage_artifact_installs
    _stage_report
    _MIGRATOR_REPORT_DONE="1"
    # Adapter-supplied post-report guidance (e.g. "pack tracker init"
    # pointer at v10→v11). Required hook per PLAN §3.4.
    migrator_post_report_hook
}

# ── Argument parsing + usage ───────────────────────────────────────────────

_migrator_usage() {
    local from="${MIGRATOR_FROM_VERSION:-vN}"
    local to="${MIGRATOR_TO_VERSION:-vM}"
    say "Usage: PACK=/path/to/pack migrate-${from}-to-${to}.sh [target-dir] [flags]"
    say ""
    say "Flags:"
    say "  --help, -h    Show this message and exit"
    say "  --dry-run     Run preflight + manifest validation; log writes but do not perform them"
    say "  --apply       Default mode (full migration); reserved for BD-095 two-phase"
    say "  --resume      Resume an interrupted migration; reserved for BD-095 (errors today)"
    say ""
    # bash 3.2 has no `${var^^}` upper-casing — use `tr` for portability.
    local from_upper
    from_upper=$(printf '%s' "$from" | tr '[:lower:]' '[:upper:]')
    say "Environment:"
    say "  PACK                          Absolute path to the pack repo (required)"
    say "  ${from_upper}_TAG / MIGRATOR_BASELINE_TAG"
    say "                                Override baseline tag (default: ${MIGRATOR_BASELINE_TAG:-$from})"
}

_migrator_parse_args() {
    local positional=()
    while (( $# > 0 )); do
        case "$1" in
            --help|-h)
                _migrator_usage
                exit 0
                ;;
            --dry-run)
                _MIGRATOR_DRY_RUN="1"
                _MIGRATOR_MODE="dry-run"
                ;;
            --apply)
                _MIGRATOR_MODE="apply"
                ;;
            --resume)
                # BD-095 surface; acknowledged but not implemented in BD-119.
                # PLAN POQ-2 / OQ1: resume stays a stub that errors loudly so
                # callers do not silently get a fresh run when they expected
                # state-machine resume.
                die "--resume not yet implemented; tracked as BD-095" "$EXIT_INTERNAL"
                ;;
            --)
                shift
                while (( $# > 0 )); do
                    positional+=("$1")
                    shift
                done
                break
                ;;
            --*)
                die "unknown option: $1 (try --help)" "$EXIT_INTERNAL"
                ;;
            *)
                positional+=("$1")
                ;;
        esac
        shift || true
    done

    local target="${positional[0]:-.}"
    # Resolve to absolute path; preserve original on `cd` failure so the
    # downstream preflight error message still names what the user typed.
    _MIGRATOR_TARGET="$(cd "$target" 2>/dev/null && pwd || printf '%s' "$target")"

    # Derive state + backup directory names from the version pair (architecture
    # §3.3). Adapter declares versions; core derives names so a sidecar/
    # state-dir naming defect fixed once is fixed for every adapter.
    _MIGRATOR_STATE_DIR="$_MIGRATOR_TARGET/.pack-migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}"
    _MIGRATOR_BACKUP_DIR="$_MIGRATOR_STATE_DIR-backup"

    # Export for the stage functions in migrator-stages.sh and for
    # backwards-compatibility with any monolith-era helpers that read
    # `$TARGET` directly.
    TARGET="$_MIGRATOR_TARGET"
    STATE_DIR="$_MIGRATOR_STATE_DIR"
    BACKUP_DIR="$_MIGRATOR_BACKUP_DIR"
}

# ── Public API (PLAN §3.1; FROZEN) ─────────────────────────────────────────
#
# Six functions form the public surface. Each is callable from adapters and
# from external harnesses. Names + arities are frozen for the duration of
# v11.x; renames require a new BD that explicitly amends BD-119.

# migrator_run "$@"
#   Full end-to-end migration with the calling adapter's declared contract.
#   Drives the stage sequencer; returns 0 on success or a documented exit
#   code on failure.
migrator_run() {
    set -euo pipefail
    _migrator_reset_state
    trap _migrator_exit_trap EXIT
    _migrator_check_adapter_contract
    _migrator_parse_args "$@"
    _migrator_run_stages
}

# migrator_dispatch <target-dir>
#   Programmatic entry point — same effect as `migrator_run "$target-dir"`
#   but skips usage printing (no `--help` recognition) and accepts only the
#   positional target. Used by external harnesses (BD-114) where flags are
#   irrelevant.
migrator_dispatch() {
    if (( $# != 1 )); then
        die "migrator_dispatch: expected exactly one argument (target-dir), got $#" \
            "$EXIT_INTERNAL"
    fi
    migrator_run "$1"
}

# migrator_detect_target_version <target-dir>
#   Echo the major pack version installed in the target (e.g. `v10`,
#   `v11`, `unknown`). Delegates to `detect_target_pack_version` from
#   `lib/detect.sh`; sources detect.sh on demand if not already loaded.
migrator_detect_target_version() {
    local target="${1:-.}"
    if ! declare -F detect_target_pack_version >/dev/null 2>&1; then
        local detect_lib="$_migrator_core_dir/detect.sh"
        if [[ -f "$detect_lib" ]]; then
            # shellcheck source=detect.sh disable=SC1091
            . "$detect_lib"
        else
            die "migrator_detect_target_version: detect.sh not found at $detect_lib" \
                "$EXIT_LIB_MISSING"
        fi
    fi
    detect_target_pack_version "$target"
}

# migrator_select_adapter <from-version>
#   Echo the absolute path to `migrate-v<from>-to-v<from+1>.sh`. Errors if
#   no adapter is found, or if multiple adapters claim the same from-version
#   (PLAN OQ3 → glob with collision-detection).
#
# Discovery: glob `$PACK/scripts/migrate-v*-to-v*.sh`, parse `vN` from each
# filename via the regex `migrate-v([0-9]+)-to-v([0-9]+)\.sh`, return the
# match for `<from-version>`.
migrator_select_adapter() {
    local from="${1:-}"
    if [[ -z "$from" ]]; then
        die "migrator_select_adapter: <from-version> argument required (e.g. v10)" \
            "$EXIT_INTERNAL"
    fi
    if [[ -z "${PACK:-}" || ! -d "${PACK:-/dev/null}" ]]; then
        die "migrator_select_adapter: PACK environment variable not set or invalid" \
            "$EXIT_PACK_INVALID"
    fi

    # Strip leading `v` if present so callers may pass either `v10` or `10`.
    local from_num="${from#v}"
    if ! [[ "$from_num" =~ ^[0-9]+$ ]]; then
        die "migrator_select_adapter: invalid from-version: $from (expected vN or N)" \
            "$EXIT_INTERNAL"
    fi

    local matches=()
    local f base from_match to_match
    # Glob may not match — `nullglob` is bash 4 only, so guard with a
    # file-exists check inside the loop (bash 3.2 compatible).
    for f in "$PACK/scripts"/migrate-v*-to-v*.sh; do
        [[ -e "$f" ]] || continue
        base=$(basename "$f")
        if [[ "$base" =~ ^migrate-v([0-9]+)-to-v([0-9]+)\.sh$ ]]; then
            from_match="${BASH_REMATCH[1]}"
            to_match="${BASH_REMATCH[2]}"
            if [[ "$from_match" == "$from_num" ]]; then
                matches+=("$f")
            fi
            # Touch to_match so set -u does not complain in callers that
            # later read it; primary use is from_match equality above.
            : "$to_match"
        fi
    done

    if (( ${#matches[@]} == 0 )); then
        die "migrator_select_adapter: no adapter found for from-version v$from_num (looked under $PACK/scripts/)" \
            "$EXIT_INTERNAL"
    fi
    if (( ${#matches[@]} > 1 )); then
        die "migrator_select_adapter: multiple adapters claim from-version v$from_num: ${matches[*]}" \
            "$EXIT_INTERNAL"
    fi
    printf '%s\n' "${matches[0]}"
}

# migrator_baseline_to_tmp <pack-relpath> <tmpfile>
#   Side-effect helper: write the BASE blob (pack repo file at
#   `MIGRATOR_BASELINE_TAG`) into `<tmpfile>` for three-way dispatch.
#   Returns 0 on success (file existed at baseline) and writes the blob
#   to `<tmpfile>`. Returns non-zero (and leaves `<tmpfile>` empty) when
#   the file did not exist at the baseline tag — that is a normal case
#   for files newly added in the destination version. Replaces the
#   monolith's `v10_baseline_to_tmp`.
migrator_baseline_to_tmp() {
    local pack_relpath="${1:-}"
    local tmpfile="${2:-}"
    if [[ -z "$pack_relpath" || -z "$tmpfile" ]]; then
        die "migrator_baseline_to_tmp: usage: <pack-relpath> <tmpfile>" \
            "$EXIT_INTERNAL"
    fi
    if [[ -z "${PACK:-}" ]]; then
        die "migrator_baseline_to_tmp: PACK not set" "$EXIT_PACK_INVALID"
    fi
    if [[ -z "${MIGRATOR_BASELINE_TAG:-}" ]]; then
        die "migrator_baseline_to_tmp: MIGRATOR_BASELINE_TAG not set" \
            "$EXIT_INTERNAL"
    fi
    if git -C "$PACK" show "$MIGRATOR_BASELINE_TAG:$pack_relpath" \
        > "$tmpfile" 2>/dev/null; then
        return 0
    else
        : > "$tmpfile"
        return 1
    fi
}

# migrator_target_surface_for_version <vN>
#   Echo a newline-delimited list of project-relative paths that a vN
#   install creates and that real-client customization can target. Used
#   by BD-120 fixture parameterization (architecture §9.2).
#
#   The returned list is *paths to files or directories*, not a transformation
#   map. The fixture builder applies its patterns; this helper only declares
#   "where the targets live in this version." This avoids duplicating
#   surface knowledge across init-project.sh, migrate-vN-to-vM.sh, and
#   test-fixtures/build.sh.
#
#   Currently knows about v10 and v11. `unknown` for any other version.
migrator_target_surface_for_version() {
    local ver="${1:-}"
    case "$ver" in
        v10)
            cat <<'EOF'
CLAUDE.md
AGENTS.md
GEMINI.md
.claude/agents
.codex/agents
.gemini/agents
.codex/config.toml
BACKLOG.md
EOF
            ;;
        v11)
            # v11 inherits the v10 customization surface and adds the v11-
            # specific surfaces (HELP-FRAGMENT, tracker.toml, ISSUE_TEMPLATE,
            # per-CLI pack-help). Only customization-relevant surfaces are
            # listed — every shipped vN file does not necessarily appear.
            cat <<'EOF'
CLAUDE.md
AGENTS.md
GEMINI.md
.claude/agents
.codex/agents
.gemini/agents
.codex/config.toml
BACKLOG.md
docs/pack/HELP-FRAGMENT.md
tracker.toml.example
.github/ISSUE_TEMPLATE/work-item.yml
.claude/skills/pack-help/SKILL.md
.codex/skills/pack-help/SKILL.md
.gemini/commands/pack-help.toml
EOF
            ;;
        *)
            printf 'unknown\n'
            return 1
            ;;
    esac
}
```

(End of `scripts/lib/migrator-core.sh` — 496 lines.)

---

## 10. Proposed commit message

```
feat: v11 — BD-119 C-3: implement core sequencer + public API (surface lock)
```

Per PLAN §6 row "C-3" and pack convention (`feat: vN — BD-NNN <description>`).
This commit lands T-7 + T-11 from PLAN §4: the core's argument parser,
stage sequencer, EXIT trap, and adapter-contract reader (T-7), plus the
four T-11 public-API helpers (`migrator_detect_target_version`,
`migrator_select_adapter`, `migrator_baseline_to_tmp`,
`migrator_target_surface_for_version`). The public-API surface (six
function names + eight exit-code constants + `EXIT_NOT_V10` synonym) is
now FROZEN per PLAN §3 — downstream consumers BD-114 / BD-120 may
read against this surface; subsequent BD-119 commits (C-4..C-7) will
not rename or re-arity. Stage bodies remain stubs (intentionally —
C-4 work).

---

## End of report

