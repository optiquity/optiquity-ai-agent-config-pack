# IMPLEMENTATION REPORT — BD-167 (Commit 19b-pack)

**Branch:** v11-dev
**HEAD SHA at start:** `ab51d768d4f027679f4a87fd4effc64083ea06ff`
**HEAD SHA at end:** `ab51d768d4f027679f4a87fd4effc64083ea06ff` (no commits;
Pack Chat owns commit per `feedback_agents_never_commit`).
**Date:** 2026-05-15
**Coder:** pack-coder

## §1 — Summary

Commit 19b-pack implements **BD-167 — Per-entry split client artifact
installs** (which absorbs **BD-161** per integration parent §17.2 +
§8.14). The commit creates the eight pack-product canonical templates
for the project-side per-entry trees (3 streams × `_rules.md` +
`_intro.md`, plus the changelog-only `_format.md`) under
`project-template/docs/project/`, extends the v10→v11 migrator's
`_v10_to_v11_install_v11_artifacts` function to ship those templates
to client repos AND to install the six BD-161 net-new SKILL.md
directories (BD-156 / BD-157 / BD-158 + python-server-architecture /
python-data-architecture / python-observability-patterns), and
extends the `_tar_read_entry_flat` function in
`scripts/lib/tracker-agent-read.sh` with a per-entry-prefer-mirror-
fallback shim. All three architectural binding constraints —
pointer-heavy `_rules.md` (~30–60 lines), Layer 1 "DO NOT EDIT"
warning in every `_intro.md`, supporting-file basenames as the sixth
contract item — are honored. All baseline tests (per-entry 57/57,
validate-pack 32/32 checks clean, migrator 43/43, tracker-init
95/95, tracker-migrate-forward 145/145, tracker-agent-read 31/31,
roundtrip 45/45, dry-run 61/61) PASS with no regressions.

## §2 — Per-template detail

Eight new files (7 markdown templates + 1 directory entry counted
as the eighth per plan §5.2 file table). All sit under the new
`project-template/docs/project/` directory tree.

### `project-template/docs/project/backlog/_rules.md` (55 lines)

**Purpose:** per-stream contract for the project-side per-entry
backlog tree.

**Key content choices:**
- Pointer-heavy + short (55 lines, in the 30–60 target range per
  sidecar §4.1).
- Six contract sections (the addendum §3.3 sixth contract item is
  "Supporting files" with `_rules.md` / `_intro.md` / `_toc.md` —
  consumed by `pe_supporting_files_admitted` at runtime per
  integration parent §7.5).
- Filename regex `^TD-\d+\.md$` cited inline.
- Lifecycle states `Open` and `Resolved` only (project side; per
  `ARCHITECTURE-V3.3-DELTA.md` §6.3 + `ARCHITECTURE-PER-ENTRY-
  SPLIT.md` §3.3).
- Write-authority pointer to `docs/pack/PM-CHAT.md` +
  `docs/pack/METHODOLOGY.md` Part 7.
- Mirror-vs-source-of-truth disclaimer at the bottom.

### `project-template/docs/project/backlog/_intro.md` (54 lines)

**Purpose:** stream preamble + recovery-anchor for the regenerated
mirror.

**Key content choices:**
- HTML-comment "DO NOT EDIT" block at lines 1–5 per Addendum #1
  §5.2 (Layer 1 mandatory). Names the per-entry tree, the per-entry
  filename pattern, and the regenerator step.
- Three "How to use this file" bullets covering reading entries,
  adding a new entry, and resolving an entry.
- Explicit mode-aware "Source of truth" section per Addendum #1
  §3.4 (flat-file mode = per-entry tree is SoT; tracker mode =
  tracker is SoT, both per-entry tree and mirror are regenerated).
- Pointer to `_rules.md` at the bottom for contract resolution.

### `project-template/docs/project/implementation-plan/_rules.md` (55 lines)

**Purpose:** per-stream contract for the project-side per-entry
implementation-plan tree.

**Key content choices:**
- Filename regex `^phase-\d+\.md$` (NOT `^phase-\d+(\.\d+)?\.md$`)
  per Addendum #1 §6.4 BD-167 spec ("one file per phase, tasks
  inline"; planner-deferred decision applied per plan §5.2 final
  paragraph).
- Phase-state vocabulary per `ARCHITECTURE-V3.3-DELTA.md` §6.3
  (pending / in-progress / done / deferred / merged-into /
  superseded-by, marked via 🚧 / ✅ / ➡ in the H2).
- Entry contract names the phase-epic-with-tasks-inline shape per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.4 with the inline
  `#### N.M — <title>` task sub-sections.
- Six contract sections including Supporting files
  (`_rules.md` / `_intro.md` / `_toc.md`).

### `project-template/docs/project/implementation-plan/_intro.md` (62 lines)

**Purpose:** stream preamble for the regenerated implementation-plan
mirror.

**Key content choices:**
- HTML-comment "DO NOT EDIT" block at lines 1–6 per Addendum #1
  §5.2.
- Four "How to use this file" bullets: reading phases, adding a
  new phase (with the H2 + Goal + Prerequisite + tasks-inline
  + Verification + Agent + Risks shape), updating a phase task
  inline, marking phase state (with the V3.3-DELTA §6.3
  vocabulary).
- Mode-aware "Source of truth" section per Addendum #1 §3.4.

### `project-template/docs/project/changelog/_rules.md` (55 lines)

**Purpose:** per-stream contract for the project-side per-entry
changelog tree.

**Key content choices:**
- Filename regex `^\d{4}-\d{2}-\d{2}-.+\.md$` per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5.
- Append-only-historical lifecycle (NO lifecycle states).
- Entry contract names the H3 heading shape (`### YYYY-MM-DD —
  Phase N — <title>` or `### YYYY-MM-DD — Architecture Iteration
  — <title>`) and points at `_format.md` for the body-fields spec.
- Six contract sections including Supporting files (the only
  stream with four supporting files: `_rules.md` / `_intro.md`
  / `_toc.md` / `_format.md` — project-side asymmetry per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5 + §11).
- `_format.md` cross-reference noted as project-side only (no
  pack-side analog).

### `project-template/docs/project/changelog/_intro.md` (57 lines)

**Purpose:** stream preamble for the regenerated changelog mirror.

**Key content choices:**
- HTML-comment "DO NOT EDIT" block at lines 1–7 per Addendum #1
  §5.2; explicitly names the append-only rule ("CHANGELOG entries
  are append-only — never edit a prior per-entry file").
- One-line "Historical record of architectural decisions" preamble
  matching the OT v10 source per `RESEARCH-PER-ENTRY-SPLIT.md`
  §3 lines 405–407.
- Three "How to use this file" bullets including the append-only
  reminder.
- Mode-aware "Source of truth" section per Addendum #1 §3.4.

### `project-template/docs/project/changelog/_format.md` (72 lines)

**Purpose:** project-side CHANGELOG Format Rules block, preserving
OT v10 `docs/project/CHANGELOG.md` Format Rules H2 content per
sidecar §3.5 + `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 408–421.

**Key content choices:**
- Reproduces the entry-format spec from OT v10's "Format Rules"
  H2 (lines 7–39 per RESEARCH §3): the `### YYYY-MM-DD — Phase N`
  heading shape, body fields (`**Summary**:`, `**Tasks
  completed**:`, `**Backlog items addressed**:`, `**Files
  created**:`, `**Files modified**:`, `**Test count**:`,
  `**Build warnings**:`).
- Reproduces the OT v10 rules verbatim in shape: Append-only,
  One-entry-per-phase, Date convention, Separator (`---`)
  precedes every entry, Architecture Iteration label, BACKLOG.md
  ✅ marking convention, README.md Known Limitations sync.
- Updates per-entry-tree-aware framing: per-entry files do NOT
  contain `---` separators (the file boundary IS the separator
  per `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.0); mirror generator
  emits the separator deterministically.
- Filename mapping section maps heading → per-entry filename
  (e.g., `### 2026-04-20 — Phase 35 — Live Broker Sandbox
  Verification` → `2026-04-20-phase-35.md`).
- Pack-shipped immutable per `ARCHITECTURE-PER-ENTRY-SPLIT-
  INTEGRATION.md` §3.3 (project-side asymmetry — pack changelog
  has no `_format.md` analog).

### `project-template/docs/project/` (directory)

**Purpose:** new canonical-template home for project-side per-entry
trees. Contains the three stream sub-directories (`backlog/`,
`implementation-plan/`, `changelog/`), each holding the support
files above.

**Pre-state:** absent (verified by `find project-template/docs
-type d` returning only `project-template/docs` and
`project-template/docs/pack` and `project-template/docs/pack/prompts`
prior to this commit).

## §3 — Migrator install-step extension

Extended `_v10_to_v11_install_v11_artifacts` in
`scripts/migrate-v10-to-v11.sh` (was lines 270–337, now lines
270–410). The extension folds two new install loops into the end of
the existing function per Addendum #1 §6.4 recommendation
("planner picks function placement; coder authors. Recommendation
per Addendum #1 §6.4: fold."). Per integration parent §17.2 and
§8.14, BD-161's net-new SKILL.md installs land in the same step as
BD-167's canonical templates.

### Before (function tail, prior to extension)

```bash
    # The pack-help shell script + its single dep (lib/detect.sh) — BD-097
    # audit B-1 documented this as required because the per-CLI surfaces
    # invoke `bash scripts/pack-help.sh` relative to the project.
    mkdir -p "$_MIGRATOR_TARGET/scripts/lib"
    if [[ -f "$PACK/scripts/pack-help.sh" \
       && ! -f "$_MIGRATOR_TARGET/scripts/pack-help.sh" ]]; then
        cp "$PACK/scripts/pack-help.sh" "$_MIGRATOR_TARGET/scripts/pack-help.sh"
        chmod +x "$_MIGRATOR_TARGET/scripts/pack-help.sh"
    fi
    if [[ -f "$PACK/scripts/lib/detect.sh" \
       && ! -f "$_MIGRATOR_TARGET/scripts/lib/detect.sh" ]]; then
        cp "$PACK/scripts/lib/detect.sh" "$_MIGRATOR_TARGET/scripts/lib/detect.sh"
    fi
}
```

### After (function tail, post-extension)

The pre-existing pack-help block is unchanged; two new install
loops follow it (full text is in the file at lines 338–409). The
new logic, paraphrased:

```bash
    # ... pack-help block unchanged ...

    # BD-167: canonical project-side per-entry tree skeletons.
    local stream_dir support_basenames base
    for stream_dir in backlog implementation-plan changelog; do
        local pack_stream_dir="$PACK/project-template/docs/project/$stream_dir"
        local target_stream_dir="$_MIGRATOR_TARGET/docs/project/$stream_dir"
        [[ -d "$pack_stream_dir" ]] || continue
        mkdir -p "$target_stream_dir"
        case "$stream_dir" in
            changelog) support_basenames="_rules.md _intro.md _format.md" ;;
            *)         support_basenames="_rules.md _intro.md" ;;
        esac
        for base in $support_basenames; do
            if [[ -f "$pack_stream_dir/$base" \
               && ! -f "$target_stream_dir/$base" ]]; then
                cp "$pack_stream_dir/$base" "$target_stream_dir/$base"
            fi
        done
    done

    # BD-161 (absorbed into BD-167): net-new v11 SKILL.md dirs.
    local skill_name skill_src cli skill_dest
    for skill_name in swift-concurrency-patterns apple-swiftdata-patterns \
                      protobuf-patterns python-server-architecture \
                      python-data-architecture python-observability-patterns; do
        skill_src="$PACK/project-template/skills/$skill_name/SKILL.md"
        [[ -f "$skill_src" ]] || continue
        for cli in .claude .codex .gemini; do
            skill_dest="$_MIGRATOR_TARGET/$cli/skills/$skill_name/SKILL.md"
            if [[ ! -f "$skill_dest" ]]; then
                mkdir -p "$_MIGRATOR_TARGET/$cli/skills/$skill_name"
                cp "$skill_src" "$skill_dest"
            fi
        done
    done
}
```

### Confirmed install coverage

End-to-end smoke test of the function (extracted via `awk` and run
under stub framework helpers) on a clean target directory shows:

- **7 canonical template files installed** (3 streams × `_rules.md`
  + `_intro.md` = 6, plus `_format.md` for changelog = 7). The 8th
  "entry" in the plan §5.2 file table is the `project-template/
  docs/project/` directory itself.
- **18 BD-161 SKILL.md files installed** (6 skills × 3 CLIs).
  Confirmed by name-filtered count over
  `swift-concurrency-patterns`, `apple-swiftdata-patterns`,
  `protobuf-patterns`, `python-server-architecture`,
  `python-data-architecture`, `python-observability-patterns`
  under `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`.

### Additive-only semantics preserved

The install loop uses `! -f "$target_stream_dir/$base"` /
`! -f "$skill_dest"` guards: client-customized files are NOT
overwritten. Idempotent — re-running the install on an already-
v11-installed target is a no-op. This matches the existing
HELP-FRAGMENT / tracker.toml.example / ISSUE_TEMPLATE / pack-help
install patterns above. Customization-preserve at next pack
version-bump is handled by BD-088 truthful-report mechanism per
`ARCHITECTURE-PER-ENTRY-SPLIT.md` §4.2.

## §4 — `_tar_read_entry_flat` extension

Extended `_tar_read_entry_flat` in
`scripts/lib/tracker-agent-read.sh` (was lines 153–186, now lines
153–284) per integration parent §6.3 + §18.1 #10 (extend existing
function, do NOT add a sibling) + §18.2 #2 (preserve backward
compatibility for pre-v11.0 clients).

### Before (function body, prior to extension)

```bash
_tar_read_entry_flat() {
    local pack_id="$1"
    local repo_root="$2"
    local backlog="$repo_root/BACKLOG.md"
    if [[ ! -f "$backlog" ]]; then
        tracker_error_emit "not-found" \
            "agent_read: BACKLOG.md not found at $backlog"
        return 1
    fi
    python3 - "$backlog" "$pack_id" <<'PYEOF' || return 1
    # ... mirror-only Python parser ...
PYEOF
}
```

The function read the BACKLOG.md mirror only — no per-entry tree
awareness.

### After (extended)

The function now resolves the stream from the pack-id prefix
(`BD-NNN` → pack backlog, `TD-NNN` → project backlog, `phase-N` /
`phase-N.M` → project implementation-plan), checks for per-entry
tree presence, and prefers the per-entry file when both the
directory and the file are present. Otherwise it falls through to
the mirror read (preserving full pre-v11.0 behavior).

```bash
_tar_read_entry_flat() {
    local pack_id="$1"
    local repo_root="$2"

    # ... (per Addendum #1 §3.2 + integration parent §6.3 + §18.1 #10) ...
    local per_entry_dir="" per_entry_file="" per_entry_id="$pack_id"
    case "$pack_id" in
        BD-*)
            per_entry_dir="$repo_root/backlog"
            per_entry_file="$per_entry_dir/$pack_id.md"
            ;;
        TD-*)
            per_entry_dir="$repo_root/docs/project/backlog"
            per_entry_file="$per_entry_dir/$pack_id.md"
            ;;
        phase-*)
            per_entry_dir="$repo_root/docs/project/implementation-plan"
            case "$pack_id" in
                phase-*.*)
                    per_entry_id="${pack_id%%.*}"
                    ;;
            esac
            per_entry_file="$per_entry_dir/$per_entry_id.md"
            ;;
    esac

    if [[ -n "$per_entry_dir" && -d "$per_entry_dir" \
       && -f "$per_entry_file" ]]; then
        # Per-entry tree exists AND per-entry file is present —
        # prefer it. Strip the line-1 HTML-comment back-pointer
        # per Addendum #2 §2 before emitting.
        printf 'Source: flat-file (per-entry: %s)\n\n' "$per_entry_file"
        python3 - "$per_entry_file" <<'PYEOF' || return 1
import re, sys
path = sys.argv[1]
try:
    with open(path) as f:
        text = f.read()
except OSError as e:
    sys.stderr.write("ERROR: not-found\nMESSAGE: %s\n→ Run: verify the issue id and re-run\n" % e)
    sys.exit(1)
lines = text.split('\n', 1)
if lines and re.match(r'^<!-- per-entry source: .*; contract: .* -->\s*$', lines[0]):
    text = lines[1] if len(lines) > 1 else ''
if text.startswith('\n'):
    text = text[1:]
sys.stdout.write(text.rstrip())
sys.stdout.write('\n')
PYEOF
        return 0
    fi

    # Fall through: per-entry tree absent (pre-v11.0 client) OR
    # per-entry file missing. Read from the mirror.
    local backlog="$repo_root/BACKLOG.md"
    if [[ ! -f "$backlog" ]]; then
        tracker_error_emit "not-found" \
            "agent_read: BACKLOG.md not found at $backlog"
        return 1
    fi
    python3 - "$backlog" "$pack_id" <<'PYEOF' || return 1
    # ... (unchanged mirror-read Python parser) ...
PYEOF
}
```

### Confirmed prefer-then-fallback semantics

End-to-end smoke test (synthetic per-entry trees + mirrors under
`/tmp`) showed all six scenarios working:

1. **Pre-v11 client (no per-entry tree, mirror only) — BD-001:**
   reads from `BACKLOG.md`, emits `Source: flat-file (BACKLOG.md)`.
2. **v11 client with per-entry tree — BD-001:** reads from
   `<tmpdir>/backlog/BD-001.md`, emits `Source: flat-file
   (per-entry: <path>)`. Back-pointer comment stripped from
   output.
3. **v11 client with per-entry tree but a specific entry only in
   mirror — BD-002:** falls back to mirror read; emits `Source:
   flat-file (BACKLOG.md)`. (Backward compat for stale per-entry
   trees / partial migrations.)
4. **Project per-entry tree — TD-005:** reads from
   `<tmpdir>/docs/project/backlog/TD-005.md`.
5. **phase-N — phase-3:** reads from
   `<tmpdir>/docs/project/implementation-plan/phase-3.md`.
6. **phase-N.M — phase-3.2:** correctly resolves to the parent
   `phase-3.md` file (per Addendum §6.4 BD-167 spec — tasks-inline,
   no per-task files); reads `phase-3.md`.

All six scenarios returned rc=0.

### Backward compatibility verified

The `tracker-agent-read-test.sh` baseline (31 tests, all
pre-existing) PASSES with zero regression — the existing test cases
all run in the "no per-entry tree" branch (the test fixtures don't
build per-entry trees), exercising the mirror-fallback path
exclusively. This confirms the extension is byte-equivalent to the
prior behavior for pre-v11.0 clients.

## §5 — Files modified / created

### Created (8 entries — 7 files + 1 directory)

| Path | Lines | Type |
|---|---|---|
| `project-template/docs/project/` | n/a | directory (new) |
| `project-template/docs/project/backlog/_rules.md` | 55 | new file |
| `project-template/docs/project/backlog/_intro.md` | 54 | new file |
| `project-template/docs/project/implementation-plan/_rules.md` | 55 | new file |
| `project-template/docs/project/implementation-plan/_intro.md` | 62 | new file |
| `project-template/docs/project/changelog/_rules.md` | 55 | new file |
| `project-template/docs/project/changelog/_intro.md` | 57 | new file |
| `project-template/docs/project/changelog/_format.md` | 72 | new file |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-167.md` | this file | new file (output report) |

### Modified (2 source files)

| Path | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | 779 | 853 | +74 | extended `_v10_to_v11_install_v11_artifacts` (lines 338–409 are new) |
| `scripts/lib/tracker-agent-read.sh` | 208 | 302 | +94 | extended `_tar_read_entry_flat` (per-entry-prefer-mirror-fallback shim; lines 156–242 are the new prefer block, 243–284 are the unchanged mirror-fallback) |

### Deleted

None.

## §6 — Verification

### Syntax checks (`bash -n`)

```
$ bash -n scripts/migrate-v10-to-v11.sh && echo OK
OK

$ bash -n scripts/lib/tracker-agent-read.sh && echo OK
OK
```

### `validate-pack.py`

```
$ python3 scripts/validate-pack.py 2>&1 | tail -8
── Check 32: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

(Note: the validator's existing Check 32 is BD-106's phase-task lib
invariants — unrelated to the new mirror-in-sync Check 32 that
lands in 19e per BD-168.)

### `test-per-entry.sh` (no regression to 19a's tests)

```
$ bash scripts/tests/test-per-entry.sh 2>&1 | tail -5
=== Summary ===
PASS: 57
FAIL: 0

All per-entry tests PASSED (57/57).
```

### Existing migrator tests (no regression)

```
$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -5
=== Summary ===
Passed: 43
Failed: 0
All tests passed.

$ bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh 2>&1 | tail -5
=== Summary ===
Passed: 61
Failed: 0
All BD-095 tests passed.
```

### Existing tracker tests (no regression)

```
$ bash scripts/tests/tracker-init-test.sh 2>&1 | tail -5
=== Summary ===
Passed: 95
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-forward-test.sh 2>&1 | tail -5
=== Summary ===
Passed: 145
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-roundtrip-test.sh 2>&1 | tail -5
=== Summary ===
Passed: 45
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-agent-read-test.sh 2>&1 | tail -5
=== Summary ===
Passed: 31
Failed: 0
All tests passed.
```

The `tracker-agent-read-test.sh` 31/31 PASS is the load-bearing
backward-compatibility check for the `_tar_read_entry_flat`
extension: every existing test exercises the fallback (mirror-read)
path with no per-entry tree present, confirming byte-equivalent
behavior with pre-v11.0 clients per integration parent §18.2 #2.

### End-to-end migrator install smoke test (out-of-test-suite)

Extracted `_v10_to_v11_install_v11_artifacts` via `awk`, ran it
under stub framework helpers (`say`/`info`/`fail_stage` no-ops)
against a clean `/tmp` target. Result:

- 7 canonical template files installed under
  `<target>/docs/project/{backlog,implementation-plan,changelog}/`.
- 18 BD-161 SKILL.md files installed (6 net-new skill names × 3
  per-CLI homes).
- Re-run with the same target was a no-op (no overwrites).
- Manual customization-preservation check: appended a "client
  edit" line to `_rules.md`, re-ran the install loop, confirmed
  the line survived (additive-only semantics preserved).

### End-to-end `_tar_read_entry_flat` smoke test (out-of-test-suite)

Synthetic tree built under `/tmp`; six scenarios exercised
(documented in §4 above). All six returned rc=0 with the expected
source attribution (`per-entry: <path>` for tree-present entries,
`BACKLOG.md` for fallback / pre-v11 cases).

### Manual: visual confirmation each `_intro.md` has Layer 1 "DO NOT EDIT" warning block

Confirmed by `head -7` on each of the three `_intro.md` files:

- `project-template/docs/project/backlog/_intro.md` — 5-line HTML
  comment at lines 1–5 ("DO NOT EDIT THIS FILE — ... Hand-edits to
  this mirror are silently overwritten on the next regeneration.").
- `project-template/docs/project/implementation-plan/_intro.md` —
  6-line HTML comment at lines 1–6.
- `project-template/docs/project/changelog/_intro.md` — 7-line HTML
  comment at lines 1–7 (extra line for the append-only reminder).

All three match the Addendum #1 §5.2 sample shape (per-stream tree
named, regenerator step named, "Hand-edits ... silently overwritten"
last sentence).

### Manual: visual confirmation each `_rules.md` is ~30–60 lines + 6 contract items + supporting-file basenames sixth item

Line counts: 55 / 55 / 55 (all three `_rules.md` files within the
30–60 target per sidecar §4.1).

Section structure (via `grep -E '^## ' <file>`):

- `backlog/_rules.md`: Stream identity / Filename convention /
  Entry contract / Lifecycle states admitted / **Supporting files**
  / Write authority — 6 sections.
- `implementation-plan/_rules.md`: same 6 sections.
- `changelog/_rules.md`: same 6 sections.

The "Supporting files" section is the addendum §3.3 sixth contract
item; consumed by `pe_supporting_files_admitted` at runtime per
integration parent §7.5. Verified the helpers parse the canonical
templates correctly:

```
$ source scripts/lib/per-entry/_lib.sh
$ pe_supporting_files_admitted project-template/docs/project/backlog
_rules.md _intro.md _toc.md
$ pe_supporting_files_admitted project-template/docs/project/implementation-plan
_rules.md _intro.md _toc.md
$ pe_supporting_files_admitted project-template/docs/project/changelog
_rules.md _intro.md _toc.md _format.md
```

The `changelog/_rules.md` correctly admits the four-element list
(project-side asymmetry: `_format.md` is project-side only per
sidecar §3.5).

## §7 — Out-of-scope items / observations

Per the prompt's explicit guidance ("Per
`feedback_no_deferral_without_user_direction` rule: do NOT
recommend deferral to v11.1+; surface to Pack Chat for in-v11.0
decision"). All items below are surfaced for Pack Chat decision in
v11.0; none have been independently deferred by this implementer.

### O-1 — Pack-side `/backlog/` and `/changelog/` canonical templates not in scope of this commit

The plan §5.2 file table names ONLY project-side canonical
templates (`project-template/docs/project/...`). Per Addendum #1
§6.2 BD-167 File/Symbol field, the BD-167 scope ALSO includes
"Pack-side `/backlog/_rules.md`, `_intro.md`,
`_v8-resolved-archive.md` (initial content extracted from
`BACKLOG.md:1-20` + `BACKLOG.md:2248`-onward at first migration
per original §9.7)" and "Pack-side `/changelog/_rules.md`,
`_intro.md` (initial content extracted from `CHANGELOG.md:1-6`)".

However, the plan §5.2 verification gate, file-creation table, and
constraints all reference project-side only. The pack-side
canonical templates are extracted at FIRST MIGRATION per integration
parent §9.7 (decompose step in 19c — BD-165), not pre-shipped from
`project-template/`. The pack repo's pack-self decompose happens at
Batch 23 dog-food per the v11.0 batch sequence.

This implementer interpreted the plan §5.2 file-creation table as
authoritative and did NOT create pack-side canonical templates in
this commit. Surfaced for Pack Chat: confirm whether (a) plan §5.2
is correct (project-side only in this commit; pack-side extracted
at first migration via 19c), or (b) Addendum #1 §6.2 also requires
pre-shipping pack-side templates in 19b-pack.

### O-2 — `--force-overwrite-mirror` flag (BD-095 bridge) is 19c scope, not 19b-pack

The plan §5.4 (Commit 19c, BD-165) names a `--force-overwrite-mirror`
flag for the migrator that ties to Addendum #2 §4 (BD-095 two-phase
contract bridge). This implementer did NOT add the flag in 19b-pack
because the plan explicitly scopes it to 19c. Confirmed for the
record so 19c's coder picks it up.

### O-3 — Plan §5.2 file count "8 canonical templates" matches "7 files + 1 directory entry" interpretation

The plan §5.2 file table has 8 rows; the first row is the
`project-template/docs/project/` directory and the remaining 7 are
files. The prompt's success-criteria line "All 8 canonical template
files created" is satisfied by reading the directory entry as one
of the 8. Surfaced for Pack Chat to confirm interpretation.

### O-4 — `_intro.md` "Source of truth" mode-aware paragraph included in pack-shipped immutable file

Each `_intro.md` includes a "Source of truth" section that
distinguishes flat-file mode from tracker mode per Addendum #1 §3.4
("In flat-file mode ... the per-entry tree is source of truth ...
In tracker mode ... the tracker is source of truth"). This is
mode-aware language (per Addendum #1 §3.2) and is BAKED INTO the
pack-shipped `_intro.md`, not generated at install time. Pack Chat
should confirm this is the intended shape (vs. e.g., a generated
preamble that adapts to the client's tracker.toml at install). The
canonical-template approach was chosen because the `_intro.md` is
"pack-shipped immutable" per integration parent §3.3 — modifying
it at install would break the immutability contract.

### O-5 — `_format.md` content reconstructed from `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 408–421 (no live OT v10 source available)

The plan §5.2 spec for `_format.md` says: "Sourced from OT v10
`docs/project/CHANGELOG.md` Format Rules H2 (per sidecar §3.5 +
RESEARCH §3 line 408–421 area)" with the constraint "_format.md
... MUST preserve OT v10 Format Rules block content". This
implementer does not have an OT clone available (per the project-
goals rule "OT itself is read-only for testing"); reconstructed
the Format Rules block from the prose description in
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 408–421. The reconstruction
faithfully reproduces:

- The entry-format spec (heading + body fields enumerated at
  RESEARCH §3 lines 422–448).
- The five rules at RESEARCH §3 lines 412–421 (Append-only;
  One-entry-per-phase; Date convention; Separator (`---`)
  precedes every entry; Architecture Iteration label; BACKLOG.md
  ✅ marking; README.md Known Limitations sync).
- One per-entry-tree update (the per-entry file boundary IS the
  separator; mirror generator emits `---` deterministically).

Pack Chat should confirm this faithfulness. If a live OT clone
becomes available, a future pack-coder can do byte-equivalence
diff against the OT source.

## §8 — Definition-of-Done checklist

Per the prompt's success criteria + plan §5.2 verification gate.

| Check | Status |
|---|---|
| All 8 canonical template files (7 files + 1 directory) created | **PASS** |
| 2 source files modified (migrator install + tracker reader) | **PASS** |
| IMPLEMENTATION-REPORT-BD-167.md exists on disk | **PASS** (this file) |
| `_rules.md` files pointer-heavy + ~30–60 lines | **PASS** (55 / 55 / 55) |
| `_rules.md` files contain six contract items inc. Supporting files | **PASS** |
| `_intro.md` files contain Layer 1 "DO NOT EDIT" HTML-comment | **PASS** (lines 1–5 / 1–6 / 1–7) |
| `_intro.md` files are pack-shipped immutable shape (no install-time mutation) | **PASS** (canonical templates copied as-is) |
| `_format.md` (changelog only) preserves OT v10 Format Rules block content | **PASS** (per O-5 caveat above; reconstructed from RESEARCH §3) |
| BD-161 net-new SKILL.md dirs install in same step as canonical templates | **PASS** (both loops in `_v10_to_v11_install_v11_artifacts`) |
| `_tar_read_entry_flat` extension preserves backward-compat for pre-v11.0 clients | **PASS** (tracker-agent-read-test 31/31; mirror-fallback exercised) |
| Filename regex per stream correct (TD-NNN / phase-N / YYYY-MM-DD-*) | **PASS** |
| Bash 3.2 + macOS BSD utility compatibility | **PASS** (`bash --norc -c` syntax check OK; no associative arrays, no `&>`, no GNU-only flags) |
| `bash -n` clean on modified shell scripts | **PASS** |
| `python3 scripts/validate-pack.py` passes existing 32 checks | **PASS** |
| `bash scripts/tests/test-per-entry.sh` 57/57 PASS (no regression to 19a) | **PASS** |
| `test-migrate-v10-to-v11.sh` 43/43 PASS | **PASS** |
| `tracker-init-test.sh` 95/95 PASS | **PASS** |
| `tracker-migrate-forward-test.sh` 145/145 PASS | **PASS** |
| `tracker-migrate-roundtrip-test.sh` 45/45 PASS | **PASS** |
| `tracker-agent-read-test.sh` 31/31 PASS (load-bearing backward-compat) | **PASS** |
| No edits to forbidden files (`BACKLOG.md`, `CHANGELOG.md`, `init-project.sh`, `validate-pack.py`, `test-fixtures/`, trinity files, `PACK-AGENTS.md`, `PACK-CHAT.md`) | **PASS** |
| No new POQs proposed without explicit Pack Chat decision | **PASS** (5 items in §7 surfaced for Pack Chat; none deferred) |
| No state-changing git verbs run | **PASS** |

## §9 — Plan deviations

**Zero plan deviations.** Every item in plan §5.2 was implemented
as specified. The five items in §7 above are observations /
clarifications surfaced for Pack Chat, not deviations from the
plan. Specifically:

- The "8 canonical templates" count is interpreted as 7 files + 1
  directory entry per the plan §5.2 file table shape.
- Pack-side canonical templates were NOT pre-shipped (per plan §5.2
  scoping); they extract at first migration per 19c.
- `_format.md` content was reconstructed from RESEARCH §3 (no live
  OT clone available; per the read-only-OT project rule).
- The migrator install logic folds canonical-template install AND
  BD-161 SKILL.md install into the existing
  `_v10_to_v11_install_v11_artifacts` function per the recommended
  fold (Addendum #1 §6.4 + plan §5.2 final paragraph).
- The `_tar_read_entry_flat` extension extends the existing
  function (recommended option per integration parent §18.1 #10
  + plan §5.2 final paragraph) rather than adding a sibling
  `_tar_read_entry_per_entry`.

## §10 — Full file contents (canonical templates)

### `project-template/docs/project/backlog/_rules.md`

```markdown
# Stream contract — project-backlog

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §3.3).

## Stream identity

- Stream name: `project-backlog`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/backlog/`

## Filename convention

Per-entry files match `^TD-\d+\.md$` (e.g., `TD-001.md`). Three-
digit zero-padded TD-NNN per `ARCHITECTURE-V3.3-DELTA.md` §6.4.

## Entry contract

One v10-grammar TD entry per file, byte-additive on the legacy
monolithic per `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3. The first
line is an HTML-comment back-pointer ABOVE the bold-header per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` §2; the
byte-identical span begins at `**TD-NNN — <Title>**`. Grammar:
`ARCHITECTURE-V3.1-DELTA.md` §3 A2 + `ARCHITECTURE-V3.3-DELTA.md`
§6.4.

## Lifecycle states admitted

- `Open` — entry is active.
- `Resolved` — entry is closed; carries `Resolution:` plus inline
  `✅ RESOLVED (Phase NN)` annotation per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3.

Project backlog uses only these two states (per
`ARCHITECTURE-V3.3-DELTA.md` §6.3).

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §7.5.
Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md`,
`docs/pack/METHODOLOGY.md` Part 7, and pack `PACK-AGENTS.md` (the
project-side analog ships in PM-CHAT.md). The monolithic
`docs/project/BACKLOG.md` is a regenerated mirror — read-stable but
never source of truth; hand-edits are silently overwritten on the
next regeneration.
```

### `project-template/docs/project/backlog/_intro.md`

```markdown
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at docs/project/backlog/. To change an entry, edit the
     corresponding docs/project/backlog/<TD-NNN>.md per-entry file
     and re-run the mirror regenerator. Hand-edits to this mirror
     are silently overwritten on the next regeneration. -->

# Project backlog

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/backlog/`. The per-entry tree is where TD-NNN
entries live; this file is a read-stable concatenation produced by
the per-entry mirror generator at `scripts/lib/per-entry/`.

## How to use this file

- **Reading entries.** Read this file for a full TD-NNN inventory.
  For a single entry, read the per-entry file directly at
  `docs/project/backlog/<TD-NNN>.md`. The per-entry file's first
  line is an HTML-comment back-pointer that names the per-stream
  contract at `docs/project/backlog/_rules.md` — read that file
  for the contract (filename regex, lifecycle states admitted,
  supporting-file basenames, write-authority pointers).

- **Adding a new entry.** Find the highest existing `TD-NNN`,
  increment by 1, write a new per-entry file at
  `docs/project/backlog/TD-NNN.md`. Then re-run the mirror
  regenerator before staging. PM Chat writes; agents do not.

- **Resolving an entry.** Edit the per-entry file: flip
  `Status: Open` to `Status: Resolved`, fill in the `Resolution:`
  line, and add the `✅ RESOLVED (Phase NN)` annotation to the
  bold-header per `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3. Then
  re-run the mirror regenerator before staging.

- **Cross-references.** TD-NNN, BD-NNN, phase-N, phase-N.M
  identifiers may appear in `Blockers:` / `Unblocks:` / prose
  per `ARCHITECTURE-V3.3-DELTA.md` §5.3.

## Source of truth

In flat-file mode (the default — no `tracker.toml`, or
`tracker.toml` with `mode.state = "flat-file"`), the per-entry
files at `docs/project/backlog/` are source of truth for entry
content. This file is the regenerated mirror — never source of
truth.

In tracker mode (`tracker.toml` with `mode.state = "tracker"` and
`migration.forward_complete = true`), the tracker (e.g., GH Issues)
is source of truth and BOTH the per-entry tree and this mirror are
regenerated from tracker state per the Mode 2 → Mode 3 transition
contract (per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §5.6).

For the per-stream contract, read
`docs/project/backlog/_rules.md`.
```

### `project-template/docs/project/implementation-plan/_rules.md`

```markdown
# Stream contract — project-implementation-plan

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §3.3).

## Stream identity

- Stream name: `project-implementation-plan`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/implementation-plan/`

## Filename convention

Per-entry files match `^phase-\d+\.md$` (e.g., `phase-0.md`,
`phase-35.md`). One file per phase; tasks live inline in the phase
file (no `phase-N.M.md` per-task files) per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §6.4 BD-167
spec.

## Entry contract

Phase epic + tasks inline per `ARCHITECTURE-PER-ENTRY-SPLIT.md`
§3.4: H2 phase heading (`## Phase N — <title>`), `**Goal**:`,
`**Prerequisite**:`, `---`, `### Tasks` (with `#### N.M — <title>`
sub-sections inline), `### Verification`, `### Agent`, `### Risks`.
The first line is an HTML-comment back-pointer ABOVE the phase
heading per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`
§2. Parser contract: `ARCHITECTURE-V3.3-DELTA.md` §4.1.

## Lifecycle states admitted

Phase-state vocabulary per `ARCHITECTURE-V3.3-DELTA.md` §6.3:
pending / in-progress / done / deferred / merged-into /
superseded-by. State is annotated in the H2 heading via `🚧`
(in-progress) / `✅` (done) / `➡` (merged / superseded).

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §7.5.
Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md`,
`docs/pack/METHODOLOGY.md` Part 4, and pack `PACK-AGENTS.md` (the
project-side analog ships in PM-CHAT.md). The monolithic
`docs/project/IMPLEMENTATION-PLAN.md` is a regenerated mirror —
read-stable but never source of truth; hand-edits are silently
overwritten on the next regeneration.
```

### `project-template/docs/project/implementation-plan/_intro.md`

```markdown
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at docs/project/implementation-plan/. To change a phase,
     edit the corresponding docs/project/implementation-plan/<phase-N>.md
     per-entry file and re-run the mirror regenerator. Hand-edits
     to this mirror are silently overwritten on the next
     regeneration. -->

# Project implementation plan

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/implementation-plan/`. The per-entry tree is
where `phase-N.md` files live (one file per phase, tasks inline);
this file is a read-stable concatenation produced by the per-entry
mirror generator at `scripts/lib/per-entry/`.

## How to use this file

- **Reading phases.** Read this file for the full phase inventory.
  For a single phase, read the per-entry file directly at
  `docs/project/implementation-plan/<phase-N>.md`. The per-entry
  file's first line is an HTML-comment back-pointer that names
  the per-stream contract at
  `docs/project/implementation-plan/_rules.md` — read that file
  for the contract (filename regex, phase-state vocabulary,
  supporting-file basenames, write-authority pointers).

- **Adding a new phase.** Find the highest existing `phase-N`,
  increment by 1, write a new per-entry file at
  `docs/project/implementation-plan/phase-N.md`. The phase file
  contains the H2 phase heading, `**Goal**:`, `**Prerequisite**:`,
  `---`, then `### Tasks` (with `#### N.M — <title>` sub-sections
  inline), `### Verification`, `### Agent`, `### Risks`. Then
  re-run the mirror regenerator before staging. PM Chat writes;
  agents do not.

- **Updating a phase task.** Edit the appropriate `phase-N.md`
  per-entry file (tasks live inline in the phase file, not in
  separate `phase-N.M.md` files). Then re-run the mirror
  regenerator before staging.

- **Marking phase state.** Phase-state vocabulary is per
  `ARCHITECTURE-V3.3-DELTA.md` §6.3: pending / in-progress / done
  / deferred / merged-into / superseded-by. Annotate the H2 phase
  heading with `🚧` (in-progress) / `✅` (done) / `➡` (merged /
  superseded) per the same reference.

## Source of truth

In flat-file mode (the default — no `tracker.toml`, or
`tracker.toml` with `mode.state = "flat-file"`), the per-entry
files at `docs/project/implementation-plan/` are source of truth
for phase content. This file is the regenerated mirror — never
source of truth.

In tracker mode (`tracker.toml` with `mode.state = "tracker"` and
`migration.forward_complete = true`), the tracker (e.g., GH Issues)
is source of truth and BOTH the per-entry tree and this mirror are
regenerated from tracker state per the Mode 2 → Mode 3 transition
contract (per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §5.6).

For the per-stream contract, read
`docs/project/implementation-plan/_rules.md`.
```

### `project-template/docs/project/changelog/_rules.md`

```markdown
# Stream contract — project-changelog

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §3.3).

## Stream identity

- Stream name: `project-changelog`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/changelog/`

## Filename convention

Per-entry files match `^\d{4}-\d{2}-\d{2}-.+\.md$` (e.g.,
`2026-04-20-phase-35.md`). Date-first for lexical sorting; trailing
slug for human readability per
`ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5.

## Entry contract

One v10-grammar CHANGELOG entry per file. Shape per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 422–448: H3 heading
(`### YYYY-MM-DD — Phase N — <title>` or `### YYYY-MM-DD —
Architecture Iteration — <title>`), then body fields per the
Format Rules in `_format.md`. The first line is an HTML-comment
back-pointer ABOVE the H3 heading per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` §2.

## Lifecycle states admitted

Append-only-historical — no lifecycle states. Once written, an
entry is never edited per the `_format.md` "Append-only" rule.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
- `_format.md`

The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §7.5.
Files not matching the entry regex AND not in this list are SKIP.
`_format.md` is project-side only (no pack analog per
`ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5).

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md`,
`_format.md` (this directory), and pack `PACK-AGENTS.md` (the
project-side analog ships in PM-CHAT.md). The monolithic
`docs/project/CHANGELOG.md` is a regenerated mirror — read-stable
but never source of truth; hand-edits are silently overwritten on
the next regeneration.
```

### `project-template/docs/project/changelog/_intro.md`

```markdown
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at docs/project/changelog/. To add a new entry, write a
     new docs/project/changelog/<YYYY-MM-DD-slug>.md per-entry
     file and re-run the mirror regenerator. Hand-edits to this
     mirror are silently overwritten on the next regeneration.
     CHANGELOG entries are append-only — never edit a prior
     per-entry file. -->

# Project change log

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/changelog/`. The per-entry tree is where
dated phase / architecture-iteration records live; this file is a
read-stable concatenation produced by the per-entry mirror generator
at `scripts/lib/per-entry/`.

Historical record of architectural decisions and phase completions.
Current architecture is documented in the project's `ARCHITECTURE.md`.

## How to use this file

- **Reading entries.** Read this file for the full date-descending
  history. For a single entry, read the per-entry file directly at
  `docs/project/changelog/<YYYY-MM-DD-slug>.md`. The per-entry
  file's first line is an HTML-comment back-pointer that names the
  per-stream contract at `docs/project/changelog/_rules.md` and
  the entry-format spec at `docs/project/changelog/_format.md` —
  read those files for the contract and the format rules.

- **Adding a new entry.** Write a new per-entry file at
  `docs/project/changelog/<YYYY-MM-DD-slug>.md` per the format
  rules in `_format.md` (Append-only; one entry per phase at phase
  completion; date = the date the phase was committed to `main`).
  Then re-run the mirror regenerator before staging. PM Chat
  writes; agents do not.

- **Append-only.** Never edit a prior per-entry file. To correct a
  mistake, add a new entry that supersedes the prior one and
  document the supersession.

## Source of truth

In flat-file mode (the default — no `tracker.toml`, or
`tracker.toml` with `mode.state = "flat-file"`), the per-entry
files at `docs/project/changelog/` are source of truth for entry
content. This file is the regenerated mirror — never source of
truth.

In tracker mode (`tracker.toml` with `mode.state = "tracker"` and
`migration.forward_complete = true`), the tracker (e.g., GH Issues)
is source of truth and BOTH the per-entry tree and this mirror are
regenerated from tracker state per the Mode 2 → Mode 3 transition
contract (per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §5.6).

For the per-stream contract, read
`docs/project/changelog/_rules.md`. For the entry-format spec,
read `docs/project/changelog/_format.md`.
```

### `project-template/docs/project/changelog/_format.md`

````markdown
# CHANGELOG Format Rules

This file is the project-side CHANGELOG entry-format spec. It is
project-side asymmetry: pack-side CHANGELOG has no `_format.md`
analog (per `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5 and §11). Pack-
shipped immutable: updates only on pack version bump (per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §3.3).

## Entry format

Each per-entry file contains one v10-grammar CHANGELOG entry. The
shape (per `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 411–421):

```
### YYYY-MM-DD — Phase N — <title>

**Summary**: <one-paragraph summary of what was completed>

**Tasks completed**:
- §N.0a — <task description>
- §N.0b — <task description>
- ...

**Backlog items addressed**: TD-NNN resolved. TD-NNN, TD-NNN
investigated and deferred with logging (blocked on <reason>).
TD-NNN–TD-NNN created from §N.M audit.

**Files created**: <comma-separated file list>
**Files modified**: <comma-separated file list>
**Test count**: <NNN> passing, <NNN> failing
**Build warnings**: <NNN>
```

For early-project iterations not tied to a numbered phase, use the
heading form `### YYYY-MM-DD — Architecture Iteration — <title>`
instead of `### YYYY-MM-DD — Phase N — <title>`.

## Rules

- **Append-only**: never edit prior entries. Add new entries at
  the top of the (regenerated) mirror, which corresponds to a new
  per-entry file with the most-recent date in the per-entry tree.
- **One entry per phase** at phase completion, committed in the
  same PR as the phase work.
- **Date** = the date the phase was committed to `main`.
- **Separator** (`---`) precedes every entry — including the
  first one. The mirror generator emits the separator
  deterministically; per-entry files do not contain `---`
  separators (the file boundary IS the separator per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.0).
- **Architecture Iteration** label for early-project architecture
  doc iterations (rather than `Phase N`).
- **BACKLOG.md**: mark resolved TD items ✅ in the same commit as
  the phase. (The `✅ RESOLVED (Phase NN)` annotation goes in the
  TD entry's bold-header per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3.)
- **README.md**: update Known Limitations in the same commit when
  a TD that appears there is resolved.

## Filename mapping

The per-entry filename is `YYYY-MM-DD-<slug>.md` where `<slug>`
mirrors the heading suffix:

- `### 2026-04-20 — Phase 35 — Live Broker Sandbox Verification`
  → `2026-04-20-phase-35.md`
- `### 2026-03-20 — Architecture Iteration — Strategy Event Model`
  → `2026-03-20-architecture-iteration.md` (or a more specific
  slug if multiple iterations land on the same date).

The mirror generator emits entries in date-descending order (newest
first) per the append-only-historical convention.
````

## §11 — Final-line marker

End of IMPLEMENTATION-REPORT-BD-167.md.

