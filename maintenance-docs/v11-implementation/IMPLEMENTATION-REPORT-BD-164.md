# IMPLEMENTATION REPORT — BD-164 (Batch 19 Commit 19a)

## 1. Summary

Created the per-entry split helper foundation under `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/` (4 files: `_lib.sh`, `decompose.sh`, `mirror-generate.sh`, `toc-regenerate.sh`) plus a new test runner at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-per-entry.sh` (57 test cases, all PASS). The helpers honor every architectural binding constraint: line-1 HTML-comment back-pointer per Addendum #2 §2 (no body field), runtime `_rules.md` read scoped to supporting-file basename list only per integration parent §7.5, unknown supporting basenames SKIP, mirror generator deterministic + idempotent, divergence-warning routing split between interactive (TTY prompt) and non-interactive (warn + non-zero exit, with `PE_FORCE_OVERWRITE_MIRROR=1` seam for 19c's `--force-overwrite-mirror` wiring). Pre-flight: branch `v11-dev`, HEAD `2b6ad7fb972d12547ee359454bfe0a935fb47b36`. Final HEAD: `2b6ad7fb972d12547ee359454bfe0a935fb47b36` (read-only worktree per agents-never-commit rule). No state-changing git verbs run.

## 2. File structure decision (planner-deferred per integration parent §18.1 #2)

**Chose: sub-directory `scripts/lib/per-entry/` with 4 files** (over single-file `scripts/lib/per-entry.sh`).

Rationale — three distinct surfaces with shared parsing logic:
- `decompose.sh` — split monolith → per-entry tree (one direction, write-mostly)
- `mirror-generate.sh` — concat per-entry tree → monolith (other direction, with divergence routing)
- `toc-regenerate.sh` — derive `_toc.md` from per-entry tree (axis-by-stream)
- `_lib.sh` — shared parser utilities consumed by all three (stream-shape constants, back-pointer add/strip, supporting-file admission, atomic write, TTY detection)

Sub-directory matches integration parent §18.1 #2 recommendation ("sub-directory because three distinct surfaces with shared parsing logic suggests a `_lib.sh` helper too. Planner-final."). It also keeps each file under ~300 lines (heuristic: each helper has one concern), matches the precedent set by `scripts/lib/migrate-v10-to-v11/` (sibling adapter-private library directory).

## 3. Per-helper detail

### `scripts/lib/per-entry/_lib.sh` (419 lines)

**Public API** consumed by the three sibling helpers:
- `pe_canonical_mirror_for_stream <key>` — returns canonical mirror path
- `pe_entry_regex_for_stream <key>` — returns BSD-grep ERE for entry filenames
- `pe_supporting_files_known_for_stream <key>` — hard-coded known list
- `pe_dir_suffix_for_stream <key>` — directory suffix for the stream
- `pe_stream_for_path <abs_dir>` — reverse lookup stream from path (longest-suffix-match)
- `pe_supporting_files_admitted <stream_dir>` — runtime read of `_rules.md`'s `## Supporting files` section
- `pe_supporting_files_effective <key> <stream_dir>` — intersection of admitted ∩ known (unknown SKIP per §7.5)
- `pe_backpointer_line <key> <id>` — compose the line-1 HTML comment
- `pe_strip_backpointer_stdin` — awk filter, drops line 1 iff it matches the back-pointer pattern
- `pe_first_line_is_backpointer` — boolean check on stdin
- `pe_ensure_backpointer <path> <key> <id>` — idempotent: prepend back-pointer iff not already present
- `pe_die`, `pe_warn`, `pe_write_atomic`, `pe_is_interactive` — shared utilities
- `pe_sort_entries`, `pe_list_entry_files`, `pe_id_from_filename` — entry enumeration

**Key implementation choices:**
- 5 streams hard-coded in a `pe__stream_attr` dispatch (bash 3.2 has no associative arrays — used `case` per attr index)
- Filename regex per stream (per §7.5 "hard-coded entry regex"): `^BD-[0-9]+\.md$`, `^v[0-9]+\.[0-9]+(-[a-z0-9-]+)?\.md$`, `^TD-[0-9]+\.md$`, `^phase-[0-9]+\.md$` (per Addendum #1 §6.4 BD-167 spec — tasks inline; no `phase-N.M.md`), `^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$`
- Supporting-file admission uses awk to parse `_rules.md`'s `## Supporting files` section; bullet items (with optional backticks) become the admitted list. Helpers SKIP basenames not in the hard-coded known list (per §7.5 final paragraph)
- Back-pointer shape uses non-dot paths per Addendum #1 §10: pack streams `/backlog/`, `/changelog/`; project streams `docs/project/<dir>/`. NO body field per Addendum #2 §2 (the body-field upgrade in Addendum #1 §1.2 was DROPPED)

### `scripts/lib/per-entry/decompose.sh` (280 lines)

**Public API:** `per_entry_decompose <stream_key> <monolithic_path> <stream_dir>`

**Implementation:** bash dispatch + python3 for markdown parsing (precedent: `scripts/lib/tracker-mirror.sh`).

**Algorithm:**
- Anchor regex per stream identifies entry boundaries (e.g. `^\*\*(BD-\d+) — ` for pack-backlog, `^### (v\d+\.\d+...)` for pack-changelog, `^## Phase (\d+) — ` for project-implementation-plan)
- Section-break regex (`^## `) closes an open entry without opening a new one (so the v8 H2 + preamble H2 boundaries are recognized)
- Per-entry body normalization: trim trailing blank lines + trailing `---` separator (these are inter-entry connective tissue, re-emitted by mirror generator)
- Each per-entry file gets the line-1 HTML-comment back-pointer prepended; entry body content is byte-identical to the corresponding span in the legacy monolith (sidecar parent §3.1 invariant)
- Atomic write via `os.replace` (idempotent under POSIX)

### `scripts/lib/per-entry/mirror-generate.sh` (276 lines)

**Public API:** `per_entry_regenerate_mirror <stream_key> <stream_dir> <mirror_path>`

**Concatenation order** (sidecar §2.7 + addendum §3.6):
1. `_intro.md` content (verbatim, if admitted + present)
2. Inter-section separator `\n---\n\n`
3. Entry files in deterministic sort order, back-pointer stripped, joined with `\n---\n\n` separator
4. `_v8-resolved-archive.md` (pack-backlog ONLY) preceded by `\n---\n\n`
5. `_format.md` (project-changelog ONLY) preceded by `\n---\n\n`

**Determinism + idempotency:**
- Entry sort: `LC_ALL=C sort` on filenames
- Trailing-newline normalization via python3 helper (BSD sed in-place is awkward)
- If on-disk mirror is byte-identical to regenerated content → no-op (no mtime churn)

**Divergence-warning routing** (Addendum #1 §5.3 + Addendum #2 §4):
- If on-disk mirror absent → write fresh
- If byte-identical → no-op (return 0)
- If divergent + `PE_FORCE_OVERWRITE_MIRROR=1` → overwrite + audit-trail warning to stderr (return 0)
- If divergent + interactive (`[[ -t 0 ]] && [[ -t 1 ]]`) → prompt user `[y/N]`; abort with return 1 on rejection
- If divergent + non-interactive → warn to stderr with the recovery instruction (`Pass --force-overwrite-mirror...`) + return 2 (BD-095-mode wiring in 19c interprets the exit code per Addendum #2 §4)

### `scripts/lib/per-entry/toc-regenerate.sh` (285 lines)

**Public API:** `per_entry_regenerate_toc <stream_key> <stream_dir>`

**Per-stream axis** (sidecar §5.1):
- pack-backlog / project-backlog → grouped by `Status:` value (canonical order: Open, Resolved, Deferred, Cancelled, Deprecated; unknowns sorted alphabetically)
- pack-changelog → grouped by major version, descending (v11, v10, ...)
- project-implementation-plan → grouped by phase number ascending (Phase 0, Phase 1, ...)
- project-changelog → grouped by year-month, descending

**Output shape:**
```
# Table of contents — <stream-display-name>

<!-- generated by scripts/lib/per-entry/toc-regenerate.sh — DO NOT EDIT BY HAND -->

## <group>

- [<id>](./<id>.md) — <title>
```

**Idempotency:** if existing `_toc.md` is byte-identical to regenerated content → no rewrite (no mtime churn).

### `scripts/tests/test-per-entry.sh` (610 lines)

**11 test groups covering:**
- Stream-shape lookups + reverse path resolution (longest-suffix-match)
- Back-pointer add/strip (line-1 only; idempotent)
- Round-trip identity: decompose → regenerate → byte-identical to original
- Decompose idempotency: 2nd run produces byte-identical per-entry files
- Mirror generator determinism: 3 consecutive regens produce byte-identical output
- Empty-tree mirror: only `_intro.md` content emitted
- Supporting-file admission: `_quotas.md` (unknown) SKIP; `_v8-resolved-archive.md` (known) emitted
- Divergence-warning routing: non-interactive returns non-zero + warning to stderr + mirror unchanged; `PE_FORCE_OVERWRITE_MIRROR=1` overwrites + audit trail
- TOC regeneration: status-grouped, deterministic, idempotent
- pack-changelog second-stream coverage (round-trip + TOC)
- bash 3.2 compatibility smoke (`bash --norc -c "source"`)

## 4. Files created

| Path | Lines | Type |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/` | (dir) | new directory |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh` | 419 | new |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/decompose.sh` | 280 | new |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh` | 276 | new |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/toc-regenerate.sh` | 285 | new |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-per-entry.sh` | 610 | new (chmod +x) |

Total: **5 new source files (1,870 lines)**, 0 modified, 0 deleted.

## 5. Verification

All architectural binding constraints honored:

| Constraint | How verified | Result |
|---|---|---|
| `bash -n` clean on all 4 helpers + test | `bash -n` per file | 5/5 OK |
| `bash scripts/tests/test-per-entry.sh` exit 0 with all cases | Full run | **57/57 PASS** |
| `python3 scripts/validate-pack.py` PASSES | Full run | PASSES (no regression) |
| Round-trip identity (decompose → regenerate yields byte-identical mirror) | Test group 3 (cases 3.1–3.7) | PASS — `cmp -s baseline regenerated` returns 0 |
| Determinism (multiple regens produce identical output) | Test group 5 (5.1, 5.2) | PASS — 3 consecutive regens byte-identical |
| Idempotency (decompose twice == decompose once) | Test group 4 (4.1, 4.2, 4.3) | PASS — 2nd decompose byte-identical to 1st |
| Supporting-file admission (`_quotas.md` SKIP, `_v8-resolved-archive.md` emitted) | Test group 7 (7.1–7.4) | PASS — effective set excludes unknown; mirror omits unknown content |
| Divergence-warning interactive vs non-interactive routing | Test group 8 (8.1–8.9) | PASS — non-interactive: rc=2 + stderr warning + mirror unchanged; force-overwrite: rc=0 + audit-trail warning + mirror updated; no-divergence: rc=0 + no warning |
| Line-1 HTML-comment back-pointer per Addendum #2 §2 (no body field) | Test 3.4: line 1 of `BD-100.md` is the HTML comment; line 2 is `**BD-100 — Sample first entry**` | PASS — byte-identical span starts at line 2 (sidecar parent §3.1 invariant preserved) |
| Mirror generator strips back-pointer when emitting (preserves byte-additive grammar invariant) | Test 3.7 (round-trip mirror == baseline) | PASS — back-pointer absent from regenerated mirror |
| Helper reads `_rules.md` at runtime ONLY for supporting-file basename list | `pe_supporting_files_admitted` parses only `## Supporting files` section; no other `_rules.md` content consumed | PASS — verified by code inspection + test 7.x behavior |
| Hard-coded entry regex + state vocab + grammar field labels (per §7.5) | Constants in `_lib.sh` `pe__stream_attr`; status vocab in `toc-regenerate.sh` `order_groups()` | PASS — code inspection |
| Helpers live in `scripts/lib/` per signal-6 carve-out (no new top-level scripts) | All 4 helpers under `scripts/lib/per-entry/` | PASS |
| Bash 3.2 + macOS BSD compat (no associative arrays, no `&>`, no GNU-only flags) | Test 11.1 (`bash --norc -c "source"`); use of `case`+parallel arrays instead of associative arrays; awk/cmp/sort with `LC_ALL=C` | PASS |
| No state-changing git verbs run | Only `git rev-parse HEAD` and `git status --short` | PASS |
| No edits to forbidden files | `git status --short` shows only the 5 new files | PASS — no modifications to `BACKLOG.md`, `CHANGELOG.md`, `scripts/lib/migrate-v10-to-v11/`, `scripts/init-project.sh`, `scripts/validate-pack.py`, `test-fixtures/`, `project-template/`, or any architecture doc |

**Test group breakdown (all PASS, 57/57):**
- Group 1 — stream-shape lookups: 11 cases
- Group 2 — back-pointer add/strip: 4 cases
- Group 3 — pack-backlog round-trip identity: 7 cases
- Group 4 — decompose idempotency: 3 cases
- Group 5 — mirror determinism: 2 cases
- Group 6 — empty-tree mirror: 2 cases
- Group 7 — supporting-file admission: 4 cases
- Group 8 — divergence-warning routing (interactive vs non-interactive): 9 cases
- Group 9 — TOC regeneration: 8 cases
- Group 10 — pack-changelog round-trip: 6 cases
- Group 11 — bash 3.2 compat smoke: 1 case

**Regression check:** ran existing `tracker-init-test.sh` → **95/95 PASS**, confirming no spillover into existing test infrastructure.

## 6. Out-of-scope items (Pack Chat triages)

These were noticed during 19a implementation but explicitly NOT acted on:

1. **The `_v8-resolved-archive.md` extraction step is BD-167's job (per integration parent §9.7).** The decompose helper as shipped does NOT pre-extract the v8 H2 from the monolithic input — the migrator (BD-165 in 19c) is the contract owner for splitting v8 H2 content into `_v8-resolved-archive.md` BEFORE invoking the decompose helper. By design — handled by subsequent commit in same batch. NOT a deferral.

2. **Project-implementation-plan + project-changelog round-trips not yet exercised.** BD-167's coder pass (19b-pack) and BD-170's fixture builder (19f) will exercise project-implementation-plan and project-changelog round-trips against real OT content. By design — handled by subsequent commits in same batch. NOT a deferral.

3. **`PE_FORCE_OVERWRITE_MIRROR` env var is the seam used by 19c's `--force-overwrite-mirror` flag.** Naming of the env var is provisional; 19c's BD-095-mode wiring in `migrator-core.sh` will define how the flag is plumbed. By design — handled by subsequent commit in same batch. NOT a deferral.

4. **Validate-pack.py "Check 32 collision" concern from initial agent reading was incorrect.** Re-verification: validate-pack.py currently has 30 `def check_` functions; PLAN §5.6 pre-state says "highest is Check 31" (off-by-one against grep but immaterial). BD-168 (19e) adds 32/33/34 with no collision. NOT a real issue.

No new POQs surfaced. No deviations from the plan; the file structure decision matches the planner's recommendation per integration parent §18.1 #2 + Addendum #1 §9.

---

**Definition-of-Done checklist:**
- [PASS] All 5 source files created (4 helpers in `scripts/lib/per-entry/` + 1 test in `scripts/tests/`)
- [PASS] `bash -n` clean on all helpers + test
- [PASS] `test-per-entry.sh` exits 0 with all integration-parent §18.2 #1 cases passing (round-trip identity / empty-tree / supporting-file admission / divergence-warning routing) — 57/57 PASS
- [PASS] `validate-pack.py` passes (no regression on existing checks)
- [PASS] All architectural binding constraints honored (verified per item in §5 above)
- [PASS] No edits to forbidden files (git status confirms)
- [PASS] No state-changing git verbs run

Branch: `v11-dev`. Pre-flight HEAD: `2b6ad7fb972d12547ee359454bfe0a935fb47b36`. Final HEAD: `2b6ad7fb972d12547ee359454bfe0a935fb47b36` (unchanged — agents-never-commit rule observed).

**Files created (absolute paths):**
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/decompose.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/toc-regenerate.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-per-entry.sh`
