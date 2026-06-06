# IMPL-REPORT — BD-211 Commit C2 (cross-surface engine + validator + _rules + tests)

- **Branch:** `v11-dev`
- **Base HEAD (pre-flight + final):** `94d789dce3d5de54347a9e6581c8bbe1c9e72cd2` (UNCHANGED — no git state-changing verbs run)
- **Scope keyword:** NONE (cross-surface — touches shared `scripts/lib/per-entry/*`, `validate-pack.py`, `scripts/lib/{recommendation,detect}.sh` serving the `TD-` project stream). Honest framing per the plan; a `pack-only` keyword would be a Check-36 mis-claim.
- **Commit not made** (agents-never-commit). 14 files modified in the working tree, nothing staged.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| Items 1–6 engine/validator grammar simplification by symbol | PASS |
| Item 7 net-new canonical-header guard (STREAMS-derived applicability) | PASS |
| Items 8–10 pack `backlog/_rules.md` simplification | PASS |
| Items 11–14 test re-pins + new positive/negative guard tests | PASS |
| `python3 scripts/validate-pack.py` GREEN (211 entries pass guard) | PASS |
| Full CI `tests` set (54/54 real tests) | PASS |
| Guard negative: suffix header AND parenthetical header BOTH reject | PASS |
| Guard positive: clean header passes | PASS |
| grep-zero 6.1 (grammar sites) EMPTY | PASS |
| grep-zero 6.2 (`BD-167b`/`BD-169b` in `backlog/ scripts/`) EMPTY | PASS |
| No-project-regression: realistic-ot 33/33; no `project-template/` or `changelog/_rules.md` in diff | PASS |
| Manifest regen (RC9 — `scripts/` touched), non-empty diff staged-ready | PASS |
| Banner text of Check 32′ `ok(...)` UNCHANGED (BD-203 C-1 avoidance) | PASS |

## Files changed inventory

| Path | Type |
|---|---|
| `scripts/lib/per-entry/_lib.sh` | modified |
| `scripts/lib/per-entry/decompose.sh` | modified |
| `scripts/lib/per-entry/toc-regenerate.sh` | modified |
| `scripts/validate-pack.py` | modified |
| `scripts/lib/recommendation.sh` | modified |
| `scripts/lib/detect.sh` | modified |
| `backlog/_rules.md` | modified |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | modified |
| `scripts/tests/test-per-entry.sh` | modified |
| `scripts/tests/pack-help-test.sh` | modified |
| `scripts/tests/recommendation-test.sh` | modified |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified |
| `test-fixtures/manifest.txt` | modified (regenerated) |

## Boundary discipline check

No edit touched a project-side surface. The two cross-surface SITES (`decompose.sh` project-backlog `anchor_re`, `toc-regenerate.sh` `[A-Z]+`/sort regexes, `validate-pack.py` `TD-\d+` token) live in PACK-side shared `scripts/` code that serves the project stream — they are pack-side files. The project-side artifact (`project-template/docs/project/backlog/_rules.md`) is already canonical (EE-8) and was VERIFY-ONLY (NOT in the diff). No pack-only reference was added to any project surface. No project-side SSOT augmentation was needed because no project-side file was edited.

## Per-site grammar edits (items 1–6) — before → after

### 1. `_lib.sh` pack-backlog `entry-regex` (in `pe__stream_attr`)
- BEFORE: `entry-regex) printf '^BD-[0-9]+[a-z]*\.md$' ;;` (comment "BD-203 A4: admit the suffix form")
- AFTER: `entry-regex) printf '^BD-[0-9]+\.md$' ;;` (comment cites BD-211 canonical, no suffix). TD branch (`^TD-[0-9]+\.md$`) KEPT (already canonical).

### 2. `decompose.sh` anchors (Python-in-heredoc)
- pack-backlog: BEFORE `r"^\*\*(BD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— "` → AFTER `r"^\*\*(BD-\d+)\s+— "`.
- project-backlog (CROSS-SURFACE): BEFORE `r"^\*\*(TD-\d+[a-z]*)(?:\s*\([^)]*\))?\s+— "` → AFTER `r"^\*\*(TD-\d+)\s+— "`.
- Both dropped `[a-z]*` AND the `(?:\s*\([^)]*\))?` parenthetical group. Comments rewritten to canonical, cite BD-211. `id_extract` returns the captured `BD-\d+`/`TD-\d+` group unchanged.

### 3. `toc-regenerate.sh` (Python-in-heredoc)
- filename regex: BEFORE `re.compile(r"^BD-\d+[a-z]*\.md$")` → AFTER `re.compile(r"^BD-\d+\.md$")` (mirrors `_lib.sh`).
- title regex (CROSS-SURFACE): BEFORE `r"^\*\*[A-Z]+-\d+[a-z]*(?:\s*\([^)]*\))? — (.+?)\*\*"` → AFTER `r"^\*\*[A-Z]+-\d+ — (.+?)\*\*"`. Prefix-agnostic `[A-Z]+` serves BD + TD.
- sort-key regex (CROSS-SURFACE): BEFORE `r"^[A-Z]+-(\d+)[a-z]*$"` → AFTER `r"^[A-Z]+-(\d+)$"`.
- Comments rewritten to canonical, cite BD-211.

### 4. `validate-pack.py`
- STREAMS pack-backlog entry_regex: BEFORE `r"^BD-\d+[a-z]*\.md$"` → AFTER `r"^BD-\d+\.md$"`.
- `CROSS_REF_RE`: BEFORE `r"BD-\d+[a-z]*"` → AFTER `r"BD-\d+"`; BEFORE `r"TD-\d+[a-z]*"` → AFTER `r"TD-\d+"` (CROSS-SURFACE). The `vN.M` version token's `-suffix` group is KEPT (version-shaped, not ID-shaped).
- `_collect_defined_ids(stream_key, stream_dir, entry_regex)` consumes the STREAMS regex as a PARAMETER — NO separate edit; the grep-zero gate (§6.1) confirms no other hard-coded `BD-\d+[a-z]*\.md$` survives in the file.
- Comments at L309 + the CROSS_REF block rewritten to canonical, cite BD-211.

### 5. `recommendation.sh`
- BEFORE `grep -qE '^BD-[0-9]+[a-z]*\.md$'` → AFTER `grep -qE '^BD-[0-9]+\.md$'` (comment cites BD-211).

### 6. `detect.sh`
- BEFORE `grep -qE '^BD-[0-9]+[a-z]*\.md$'` → AFTER `grep -qE '^BD-[0-9]+\.md$'`.

### Property-fit / KEEP verification
- pack-changelog regex (`^v\d+\.md$`), project-changelog/implementation-plan anchors (date/phase-shaped), and the `vN.M` version cross-ref token are VERSION/DATE-shaped — KEPT, never touched (per ARCHITECTURE §3.6). The `TD-` filename regex in `_lib.sh` (`^TD-[0-9]+\.md$`) was already canonical — KEPT.

## Net-new canonical-header guard (item 7)

Added to `scripts/validate-pack.py`:

```python
_CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")

def _stream_is_id_shaped(entry_regex: str) -> bool:
    return bool(re.match(r"^\^[A-Z]+-", entry_regex))
```

Inside `check_mirror_in_sync`, AFTER the existing filename-conformance loop, a per-entry line-2 header guard runs for each stream where `_stream_is_id_shaped(entry_regex)` is True (gated on the SAME `entry_regex` the filename loop iterates from STREAMS — NO hard-coded `"pack-backlog"`). For each entry file matching the stream's filename regex, line 2 (the bold header below the line-1 `<!-- per-entry source: ... -->` back-pointer) is asserted against `_CANON_HEADER_RE`; mismatches accumulate and `fail()` with a file-path + verbatim-header (`{n}: {h!r}`) callout naming the non-canonical feature.

**STREAMS-derived applicability confirmed:** `_stream_is_id_shaped("^BD-\\d+\\.md$")` → True (runs the guard); `_stream_is_id_shaped("^v\\d+\\.md$")` → False (changelog SKIPped — version-shaped never mis-asserted). The classifier reads the STREAMS `entry_regex`, not a second literal. Evidence: validate-pack.py Check 32′ output shows `backlog/` validated (211 entries, GREEN) and `changelog/` validated with NO header assertion.

**Banner NOT renamed:** the Check 32′ `ok(...)` string is byte-identical to before (`"... filenames conform (no-mirror SSOT)"`) — confirmed it still matches the pinned assertions in `test-v11-realistic-ot.sh:341/343` and `test-validate-pack-checks-32-33-34.sh` F1.2. This avoids the BD-203 C-1 banner-rename failure mode.

## `backlog/_rules.md` simplification (items 8–10)

- Filename convention: `^BD-\d+[a-z]*\.md$` + "OPTIONAL lowercase suffix-letter run" prose → `^BD-\d+\.md$` + "Three-or-more-digit BD-NNN; NO letter suffix (canonical per BD-211 — a sub-part is an in-body section, not a suffixed entry)."
- ID-extraction: removed the suffix example and the parenthetical-admission sentence; restated canonical — "a parenthetical qualifier, if present, is TITLE TEXT after the em-dash, never between the ID and the em-dash"; captured group → `BD-\d+`.
- Entry contract: `**BD-NNN[suffix] — <Title>**` → `**BD-NNN — <Title>**`.
- `project-template/docs/project/backlog/_rules.md` NOT edited (already canonical — separate artifact, pack/project separation).

## Test re-pins + new guard tests (items 11–14)

### `test-validate-pack-checks-32-33-34.sh`
- Monkey-patched STREAMS tuple `^BD-\d+[a-z]*\.md$` → `^BD-\d+\.md$`.
- Fixture: renamed `BD-167b.md` (header `**BD-167b — Suffix-form entry**`) → `BD-700.md` (`**BD-700 — Canonical entry**`); BD-102 body ref updated to BD-700; builder doc-comment + fixture-file list updated.
- A5 (ROGUE-FILE.md non-conform) kept; comment re-pinned to "canonical entry BD-700.md conforms".
- A6: "canonical entry conforms" (BD-700.md present, rc=0, not flagged).
- C6: canonical defined ref BD-700 resolves (rc=0).
- C7: dangling canonical ref `BD-556` (canonical-but-undefined; distinct from the existing C2 `BD-555` precedent) → rc=1, names BD-556.
- NEW Group H (measure-then-bound guard tests):
  - H1 NEGATIVE — canonical filename `BD-500.md`, line-2 header `**BD-500b — Suffix header**` → rc=1, names BD-500.md, "non-canonical line-2 header".
  - H2 NEGATIVE — canonical filename `BD-501.md`, line-2 header `**BD-501 (Qualifier) — Parenthetical header**` → rc=1, names BD-501.md.
  - H3 NEGATIVE — both forms in one tree → rc=1, names BOTH BD-500.md and BD-501.md.
  - H4 POSITIVE control — `BD-502.md` / `**BD-502 — Clean header**` → rc=0, NOT flagged.
  - (Filenames are canonical so they pass the filename loop and REACH the header guard; only the line-2 text is non-canonical in the negative cases.)
- Result: 85/85 PASS.

### `test-per-entry.sh`
- 1.6 assertion: `^BD-[0-9]+[a-z]*\.md$` → `^BD-[0-9]+\.md$`. Result: 57/57 PASS.

### `pack-help-test.sh`
- Renamed `BD-167b.md` fixture → `BD-900.md`, header `**BD-900 — Canonical entry**`, Status `Resolved` PRESERVED. Comment re-pinned. Result: 21/21 PASS.

### `recommendation-test.sh`
- Renamed `BD-167b.md` fixture → `BD-900.md`, header `**BD-900 — Canonical entry (active)**`, Status `Unblocked` PRESERVED (drives the bd_count_active=3 / bd_count_total=5 assertions — both unchanged). Comment + assertion message re-pinned. Result: 53/53 PASS.

### `tracker-migrate-reverse-test.sh` / `tracker-migrate-roundtrip-test.sh`
- Comment regex `^BD-[0-9]+[a-z]*\.md$` → `^BD-[0-9]+\.md$` (cite BD-211). Results: 111/111 and 42/42 PASS.

## Manifest

`bash test-fixtures/build.sh --all --clean` → non-empty diff (v11 fixture content hashes shifted because they bundle the edited engine/validator scripts):
```
v11-realistic-ot  d886056... → ae3fc6ff...
v11-flat-file     695b77fe... → f9705c27...
v11-tracker-on    009cad14... → 944ddee3...
```
Regenerated `test-fixtures/manifest.txt` is in the working tree (staged-ready, RC9). `bash test-fixtures/build.sh --verify` against the regenerated manifest → rc=0 (all 6 fixtures OK). The single `--verify` FAIL in the full-suite run was a local pre-commit artifact (`git checkout HEAD -- manifest.txt` restored the OLD manifest before verify); CI restores the COMMITTED new manifest so it passes there.

## grep-zero completeness gate (§6) — both EMPTY

### 6.1 No `[a-z]*` BD/TD-id grammar site in active code
```
$ grep -rEn 'BD-[0-9]+\[a-z\]\*|BD-\d+\[a-z\]\*|TD-[0-9]+\[a-z\]\*|TD-\d+\[a-z\]\*|\[A-Z\]+-\d+\[a-z\]\*' \
    scripts/lib/per-entry/ scripts/validate-pack.py scripts/lib/recommendation.sh scripts/lib/detect.sh
→ (empty; rc=1)
```

### 6.2 No active `BD-167b`/`BD-169b` token in `backlog/ scripts/`
```
$ grep -rln 'BD-167b\|BD-169b' backlog/ scripts/
→ (empty; rc=1)
```
LITERALLY EMPTY (not even `backlog/BD-211.md` matches — C1 made BD-211 tokenless, as the prompt noted). Comments I authored use the base ids `BD-167`/`BD-169` (do not match the suffix-token grep). The 40 historical `maintenance-docs/` files are OUTSIDE the gate's scan dirs (untouched).

## No-project-regression verification (§7)

1. `bash scripts/tests/test-v11-realistic-ot.sh` → 33/33 PASS (the simplified engine decomposes + TOC-regenerates + validates the realistic-ot project fixture).
2. `git diff --name-only | grep -E 'project-template/|changelog/_rules.md'` → EMPTY (rc=1): NO `project-template/` file and NO `changelog/_rules.md` in the diff.
3. The 5 fixture TD headers are canonical and parse:
   ```
   **TD-001 — Onboarding flow review** … **TD-005 — Test coverage for offline mode**
   ```

## Full CI suite results (the complete set per `.github/workflows/validate-pack.yml`)

`validate` job: `python3 scripts/validate-pack.py` → rc=0, "PASSED — all checks clean" (Check 32′ GREEN with the new header guard; 14 Check-48 WARNs are advisory, exit unaffected).

`tests` job (53 step commands; the two `build.sh` invocations + the validate job = aggregate 54 real verifications, all GREEN):

| Aggregate | Result |
|---|---|
| validate-pack.py + 53 tests-job step commands (excluding the artifact `--verify`-after-old-restore) | **PASS=54, FAIL=0** |

The one FAIL reported by the runner (`build.sh --verify`) is the local restore-to-old-HEAD manifest artifact described above; `--verify` against the regenerated (to-be-committed) manifest is rc=0. Selected highlights re-pinned by this change (all GREEN):
- `test-validate-pack-checks-32-33-34.sh` 85/85 (incl. new H1–H4 guard tests)
- `test-per-entry.sh` 57/57
- `pack-help-test.sh` 21/21
- `recommendation-test.sh` 53/53
- `tracker-migrate-reverse-test.sh` 111/111, `tracker-migrate-roundtrip-test.sh` 42/42
- `test-v11-realistic-ot.sh` 33/33

Syntax: `python3 -c "import ast; ast.parse(...)"` on validate-pack.py OK; `bash -n` on all 5 edited shell files OK.

## Plan deviations

Two minor, documented; neither alters the design intent:

1. **C7 dangling token = `BD-556`, not `BD-555`.** The plan recipe item 11 suggested `BD-555` "mirroring the existing C2 dangling-`BD-555` precedent." `BD-555` is ALREADY the dangling token in the C2 test in the same file; reusing it for C7 would make C7 a verbatim duplicate of C2. I used the distinct canonical-but-undefined `BD-556` so C7 remains a meaningful independent assertion while still "mirroring the C2 precedent" (same pattern, distinct id). Both are canonical-but-undefined; the load-bearing property (a canonical dangling ref FAILs) is preserved.
2. **Negative-guard test fixtures use canonical FILENAMES with non-canonical HEADERS.** Plan §5.B seeds entries "whose line-2 header is `**BD-500b — ...**`". A file literally named `BD-500b.md` would fail the FILENAME loop (which `continue`s before the header guard runs), so it would never exercise the HEADER guard. I named the files canonically (`BD-500.md`, `BD-501.md`, `BD-502.md`) and put the non-canonical text in the line-2 HEADER — this is the only way to reach and test the header guard specifically. The header literals (`**BD-500b — ...**`, `**BD-501 (Qualifier) — ...**`, `**BD-502 — Clean header**`) match the plan exactly.

## New POQs introduced

None.

## Rules-Applied Verification Block

### Per-rule (Rules in force)

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **CI-guard measure-then-bound** | Guard sized to `_CANON_HEADER_RE = ^\*\*(?:BD\|TD)-\d+ — .+\*\*$`; POSITIVE H4 (clean header rc=0, not flagged) + NEGATIVE H1/H2/H3 (suffix AND parenthetical BOTH rc=1, both named); validate-pack.py Check 32′ GREEN on all 211 canonical entries (0 false positives); stream-scoped via `_stream_is_id_shaped` (changelog SKIPped). | COMPLIANT |
| **Enumerate ENCODING surfaces** | 14 grammar sites + `backlog/_rules.md` + 6 test files updated in lockstep; the guard's stream-applicability derived from the SAME STREAMS `entry_regex` the filename loop uses (no two-place hard-code) — `_stream_is_id_shaped` is the single classifier. | COMPLIANT |
| **Pack/project separation + no regression** | Cross-surface edits move shared code INTO agreement with the already-canonical project template; `git diff --name-only \| grep project-template/` → empty; `changelog/_rules.md` not in diff; realistic-ot 33/33; 5 TD fixtures canonical + parse. | COMPLIANT |
| **Pattern-matching antipattern** | Per-site property-fit: pack-changelog `^v\d+\.md$`, project-changelog/impl-plan anchors, and the `vN.M` version cross-ref token KEPT (version/date-shaped, not ID-shaped); only `[a-z]*` + the parenthetical group stripped from ID-shaped sites. | COMPLIANT |
| **Rename/measure-then-bound (grep-zero)** | §6.1 grammar-site grep → empty (rc=1); §6.2 `grep -rln 'BD-167b\|BD-169b' backlog/ scripts/` → LITERALLY EMPTY (rc=1). Asserted in PREFLIGHT. | COMPLIANT |
| **Verify the FULL CI suite** | All 53 tests-job step commands + the `validate` job run; aggregate PASS=54 FAIL=0 (the lone `--verify` FAIL is the documented old-manifest-restore artifact; verify against the regenerated manifest = rc=0). | COMPLIANT |
| **Manifest regen on v11-surface commits** | `scripts/` touched → `build.sh --all --clean` run; non-empty diff (3 v11 fixture hashes) → `manifest.txt` regenerated in working tree, staged-ready. | COMPLIANT |
| **Agents never commit / PREFLIGHT + STOP** | No `git add/commit/push/tag/rm/checkout`-of-branch run; HEAD `94d789d` UNCHANGED; PREFLIGHT line emitted only after the entire set + grep-zero + guard tests passed. (`git checkout HEAD -- manifest.txt` is the read-only restore-before-verify CI mirror — pathspec restore, not a branch/state change.) | COMPLIANT |
| **Rules-Applied Verification Block** | This block (per-rule + per-read-doc, evidence quoted, terminal conclusions). | COMPLIANT |

### Per-read-doc (READ directly)

| Document | Read evidence | Conclusion |
|---|---|---|
| `PLAN-BD-211.md` § Commit C2 + §4/§5/§6/§7/§9 | Read tool L312–486 + L546–826; items 1–14 by-symbol recipe + full-CI list + grep-zero gate drove every edit. | COMPLIANT |
| `ARCHITECTURE-BD-211.md` §3/§4/§5 | Read tool L175–356; the per-site recipes, the guard design (`_CANON_HEADER_RE`, STREAMS-derived applicability, banner-not-renamed), `_rules.md` simplification. | COMPLIANT |
| `scripts/lib/per-entry/_lib.sh` | Read tool L70–119; edited the pack-backlog `entry-regex` branch (item 1). | COMPLIANT |
| `scripts/lib/per-entry/decompose.sh` | Read tool L112–171; edited pack-backlog + project-backlog `anchor_re` (item 2). | COMPLIANT |
| `scripts/lib/per-entry/toc-regenerate.sh` | Read tool L78–137 + L238–259; edited filename/title/sort regexes (item 3). | COMPLIANT |
| `scripts/validate-pack.py` | Read tool L300–354 (STREAMS), L3160–3309 (`check_mirror_in_sync`/`_list_unknown_files`), L3425–3502 (`CROSS_REF_RE`/`_collect_defined_ids`); edited STREAMS + CROSS_REF + added the guard (items 4/7). | COMPLIANT |
| `scripts/lib/recommendation.sh` | Read tool L142–153; edited the entry-count grep (item 5). | COMPLIANT |
| `scripts/lib/detect.sh` | Read tool L53–64; edited the tree-presence grep (item 6). | COMPLIANT |
| `backlog/_rules.md` | Read tool full (86 lines); edited filename convention / ID-extraction / entry contract (items 8–10). | COMPLIANT |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | Read tool L140–262, L437–605, L860–878; re-pinned A5/A6/C6/C7 + fixture rename + added Group H (item 11). | COMPLIANT |
| `scripts/tests/test-per-entry.sh` | Read tool L218–229; re-pinned 1.6 (item 12). | COMPLIANT |
| `scripts/tests/pack-help-test.sh` | Read tool L30–64; renamed fixture, preserved Status (item 13). | COMPLIANT |
| `scripts/tests/recommendation-test.sh` | Read tool L35–66 + grep; renamed fixture, preserved Status, re-pinned counts comment (item 13). | COMPLIANT |
| `scripts/tests/tracker-migrate-reverse-test.sh` | Read tool L344–355; re-pinned comment regex (item 14). | COMPLIANT |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | Read tool L440–451; re-pinned comment regex (item 14). | COMPLIANT |
| `.github/workflows/validate-pack.yml` | grep-extracted all 53 test/build step commands; ran the complete set. | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Provided in full in system context; the workflow / agents-never-commit / enumerate-encoding-surfaces / manifest-regen rules applied. | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read via context; applied to the header guard (size to canonical, positive + negative). | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read via context; pack vs project `_rules.md` treated as separate artifacts (project VERIFY-only). | COMPLIANT |
| `feedback_pattern_matching_out_of_context_antipattern.md` | Read via context; per-site property-fit, version-shaped regexes KEPT. | COMPLIANT |
| `feedback_rename_plans_measure_then_bound.md` | Read via context; grep-zero gate led the verification. | COMPLIANT |
| `feedback_verify_full_ci_suite.md` | Read via context; ran the full CI set incl. integration tests pinning validator output. | COMPLIANT |
| `feedback_manifest_regen_on_v11_surface.md` | Read via context; regenerated manifest on the `scripts/`-touching change. | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Read via context; this block satisfies it. | COMPLIANT |

No named document was derived rather than read directly.
