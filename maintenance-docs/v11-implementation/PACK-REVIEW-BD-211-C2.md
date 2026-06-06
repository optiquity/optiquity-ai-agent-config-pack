# PACK-REVIEW-BD-211-C2 — Cross-surface grammar canonicalization

**Reviewer:** pack-reviewer (READ-ONLY)
**Branch / HEAD:** `v11-dev` / `94d789d`
**Scope:** Commit C2 (uncommitted working tree) — 14 grammar sites simplified to
`<ID>-NNN`, net-new canonical-header guard in `check_mirror_in_sync`, pack
`backlog/_rules.md` simplified, 6 test files re-pinned + new Group H guard tests.
**Reads:** PLAN-BD-211 §Commit C2 (items 1–14), ARCHITECTURE-BD-211 §3/§4/§5, the
full `git diff`, `validate-pack.py` (`check_mirror_in_sync` / `_CANON_HEADER_RE` /
`_stream_is_id_shaped` / STREAMS / CROSS_REF_RE), both `_rules.md`, the 6 test
files, `.github/workflows/validate-pack.yml`, CLAUDE.md ## Pack memory.

---

## HEADLINE: **PASS**

C2 is a clean, property-fit simplification + a correctly-bounded net-new guard.
The diff is exactly the 14-file set (no `project-template/`, no `changelog/_rules.md`).
The guard is STREAMS-derived (no two-place hard-code), passes all 211 canonical
entries (0 false positives), and rejects BOTH non-canonical forms (0 false
negatives). grep-zero gates are literally empty. Full CI suite (52 steps +
validate-pack) green. **No BLOCKER / MUST / SHOULD findings. One NIT (advisory).**

> NOTE on C1: the suffix files are already deleted and BD-167/BD-169 already
> folded in the working tree (BD-167b.md / BD-169b.md absent; BD-195 line-2
> normalized; 211 live entries) — C1 landed in a prior commit, consistent with
> the fold-then-guard ordering. C2 is reviewed against that already-canonical tree.

---

## Check 1 — Grammar simplifications property-fit (14 sites)

**PASS.** Each ID-shaped site drops `[a-z]*` and (where present) the pre-em-dash
parenthetical group; version-shaped regexes are KEPT. Per-site verification:

| Site | Change | Verdict |
|---|---|---|
| `_lib.sh:88` pack-backlog filename | `^BD-[0-9]+[a-z]*\.md$` → `^BD-[0-9]+\.md$` | property-fit |
| `decompose.sh:127` pack-backlog anchor | drops `[a-z]*` + `(?:\s*\([^)]*\))?` → `^\*\*(BD-\d+)\s+— ` | property-fit |
| `decompose.sh:152` project-backlog (TD) anchor | drops `[a-z]*` + parenthetical → `^\*\*(TD-\d+)\s+— ` (CROSS-SURFACE) | property-fit |
| `toc-regenerate.sh:85` pack-backlog filename | drops `[a-z]*` (mirrors `_lib.sh`) | property-fit |
| `toc-regenerate.sh:128` title regex | drops `[a-z]*` + parenthetical; keeps prefix-agnostic `[A-Z]+` (CROSS-SURFACE) | property-fit |
| `toc-regenerate.sh:246` sort regex | `^[A-Z]+-(\d+)[a-z]*$` → `^[A-Z]+-(\d+)$` (CROSS-SURFACE) | property-fit |
| `validate-pack.py:311` STREAMS pack-backlog | drops `[a-z]*` | property-fit |
| `validate-pack.py` CROSS_REF_RE BD token | `BD-\d+[a-z]*` → `BD-\d+` | property-fit |
| `validate-pack.py` CROSS_REF_RE TD token | `TD-\d+[a-z]*` → `TD-\d+` (CROSS-SURFACE) | property-fit |
| `recommendation.sh:148` entry-count grep | drops `[a-z]*` | property-fit |
| `detect.sh:59` tree-presence grep | drops `[a-z]*` | property-fit |
| comments at the 6 sites | re-pointed BD-203→BD-211, canonical prose | property-fit |

**Version-shaped regexes confirmed UNTOUCHED** (not over-simplified):
- `toc-regenerate.sh:88` `^v\d+\.md$` — kept.
- `validate-pack.py:313` STREAMS pack-changelog `^v\d+\.md$` — kept.
- `validate-pack.py:3502` CROSS_REF `v\d+\.\d+(?:-[a-z0-9-]+)?` — version token
  KEEPS its `-suffix` group (correctly NOT treated as an ID suffix).
- `phase-\d+(?:\.\d+)?` cross-ref token — untouched.

`_collect_defined_ids` consumes the STREAMS regex as a parameter — no separate
hard-coded copy edited (confirmed by grep-zero, Check 5). No blind find-replace:
the project-backlog TD anchor was simplified intentionally (cross-surface,
agreeing with the already-canonical project template), and the version/phase
regexes were deliberately left alone.

---

## Check 2 — Net-new header guard (measure-then-bound) — THE KEY CHECK

**PASS.** `validate-pack.py`:

- `_CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")` — matches the
  design spec exactly (no suffix, no pre-em-dash parenthetical).
- **Stream-applicability is DERIVED from STREAMS**, NOT hard-coded:
  `_stream_is_id_shaped(entry_regex)` returns `bool(re.match(r"^\^[A-Z]+-", entry_regex))`.
  Verified against the real STREAMS regexes:
  ```
  '^BD-\d+\.md$'  -> id_shaped=True
  '^v\d+\.md$'    -> id_shaped=False   (version-shaped → SKIPPED)
  '^TD-\d+\.md$'  -> id_shaped=True
  ```
  The guard consumes the SAME `entry_regex` the filename loop uses — single source
  of stream-applicability (no two-place "pack-backlog" hard-code). pack-changelog
  is version-shaped → header assertion correctly SKIPPED.
- **Line 2 read correctly:** `header = lines[1]` (the bold header BELOW the line-1
  `<!-- per-entry source: ... -->` back-pointer). The guard re-applies the
  `entry_regex` filename match and skips `known_supporting` files before reading
  line 2 — so `_rules.md` / `_intro.md` / `_toc.md` are not scanned.

**(a) 0 false positives** — `python3 scripts/validate-pack.py` against the real
211-entry tree: `PASSED — all checks clean` (RC=0). Check 32′ passes all 211
canonical entries.

**(b) 0 false negatives** — Group H tests (Check 4) prove a suffix header AND a
pre-em-dash-parenthetical header both REJECT (rc=1, named).

**(c) Check 32′ banner UNCHANGED** (the BD-203 C-1 lesson): the `ok()` string is
`"{stream_rel}/ — no monolith present; _rules.md + _toc.md present; filenames
conform (no-mirror SSOT)"` — byte-identical to pre-C2. No stale-assertion break;
`test-v11-realistic-ot.sh` green (33/33). The FAIL branch is a net-new `fail(...)`
that only fires on a non-canonical header — it does not alter the OK banner.

The guard is sized EXACTLY to the canonical set (measure-then-bound): it neither
over-admits (no widened allowlist) nor under-admits (both non-canonical forms
reject). COMPLIANT.

---

## Check 3 — `_rules.md`

**PASS.**
- Pack `backlog/_rules.md` simplified: filename convention `^BD-\d+\.md$` (suffix
  prose removed), ID-extraction restated canonical (suffix example + parenthetical-
  admission sentence removed; "a parenthetical, if present, is TITLE TEXT after the
  em-dash"), entry contract `**BD-NNN — <Title>**` (was `**BD-NNN[suffix] — ...**`).
  Matches PLAN items 8/9/10.
- `project-template/docs/project/backlog/_rules.md` — **zero diff** (not in
  `git diff --name-only`; already canonical per EE-8). Confirmed.
- `changelog/_rules.md` — **zero diff** (not in the diff). Confirmed.

Pack and project `_rules.md` are treated as separate artifacts; the engine moves
INTO agreement with the already-canonical project template (no cross-side edit).

---

## Check 4 — Tests genuine

**PASS.** All 6 re-pins correct; Group H guard tests genuinely assert the four
cases:

- **Re-pins:** `test-per-entry.sh` 1.6 → `^BD-[0-9]+\.md$`; `pack-help-test.sh` +
  `recommendation-test.sh` `BD-167b.md` fixture → `BD-900.md` (canonical, Status
  fields preserved — Resolved / Unblocked drive the active/resolved counts);
  `test-validate-pack-checks-32-33-34.sh` A5/A6 fixture `BD-167b.md` → `BD-700.md`,
  C6 defined-ref → `BD-700`, C7 dangling-ref → `BD-556` (mirrors the existing
  `BD-555` precedent); `tracker-migrate-{reverse,roundtrip}-test.sh` comment
  regexes synced to `^BD-[0-9]+\.md$`. No coverage weakened (A5 ROGUE-FILE non-
  conform test retained; C6/C7 resolve+dangling both retained).
- **Group H (net-new):**
  - **H1** (suffix): canonical filename `BD-500.md` + line-2 `**BD-500b — ...**`
    → rc=1, names `BD-500.md`, "non-canonical line-2 header".
  - **H2** (parenthetical): canonical filename `BD-501.md` + line-2
    `**BD-501 (Qualifier) — ...**` → rc=1, names `BD-501.md`.
  - **H3** (both): both offenders named in one tree.
  - **H4** (positive control): `**BD-502 — Clean header**` → rc=0, not flagged.

**Deviation sound (confirmed):** the negative fixtures use a CANONICAL filename
with a NON-canonical line-2 header — this is the only way to reach the header
guard, since a suffix FILENAME is rejected by the filename-conformance loop first
(the guard's filename re-match would skip a non-conforming file). The test comments
state this explicitly. Genuine measure-then-bound coverage (positive control +
both negative forms). All Group H + re-pinned assertions pass in the live run
(`test-validate-pack-checks-32-33-34.sh` rc=0).

---

## Check 5 — grep-zero literally empty

**PASS.**
```
grep -rln 'BD-167b\|BD-169b' backlog/ scripts/        → EMPTY
grep -rEn '...[a-z]* ID grammar...' (6 code files)    → EMPTY
```
Both literally empty. BD-211 is tokenless (the fold scrubbed the self-referential
tokens; `backlog/BD-211.md` does NOT carry `BD-167b`/`BD-169b`), so NO allowlist
exception is needed — the gate's expected output is genuinely empty, stronger than
the plan's "exactly BD-211.md" fallback. No surviving `[a-z]*` ID grammar site in
any of the 6 code files.

---

## Check 6 — No project regression (cross-surface)

**PASS.**
- `test-v11-realistic-ot.sh` → rc=0, **33/33 PASSED**, "FAIL: 0". The simplified
  engine decomposes + TOC-regenerates + validates the 5 canonical TD fixtures with
  no error; no banner/SKIP-wording assertion broke.
- The engine change AGREES with the already-canonical project `_rules.md`
  (`^TD-\d+\.md$`, `**TD-NNN — <Title>**`): the cross-surface sites
  (decompose.sh:152 TD anchor, toc-regenerate.sh:128/246 prefix-agnostic `[A-Z]+`,
  CROSS_REF TD token) move the shared code INTO agreement with the template — the
  project side gets more consistent, not regressed.
- `project-template/.../backlog/_rules.md` and the 9 fixture `_rules.md` copies +
  5 fixture TD entries are UNCHANGED (not in the diff) and still parse.

---

## Check 7 — Full CI suite (the C-5 lesson)

**PASS.** Enumerated the entire `tests` job from `.github/workflows/validate-pack.yml`
(50 test steps + 2 `build.sh` invocations) + the `validate` job, and ran them ALL.

**Aggregate: ALL GREEN.**
- `validate-pack.py` → **PASSED — all checks clean** (RC=0).
- Batch 1 (validate-pack + 45 test scripts incl. test-per-entry,
  test-validate-pack-checks-32-33-34 with Group H, recommendation-test,
  pack-help-test, both tracker-migrate comment tests, all check-NN tests,
  migrator-core/manifest/capability): **PASS=46 FAIL=0**.
- Batch 2 (build --all --clean, build --verify, test-v11-realistic-ot,
  test-migrator-skills, test-persona-contracts, template-translations,
  template-version, test-issue-forms): **PASS=7, plus build --verify confirmed
  PASS on re-check** (see manifest note below).
- **Total: 52/52 GREEN.**

**Manifest (RC9):** the working-tree `test-fixtures/manifest.txt` is already
regenerated + staged with the new v11 fixture hashes
(`ae3fc6f` / `f9705c2` / `944ddee`). A fresh `build.sh --all --clean` produces
EXACTLY those hashes, and `build.sh --verify` against the working-tree manifest
returns rc=0 (all 6 fixtures OK). RC9 satisfied — C2 touches `scripts/`, manifest
regen present in the same change set.

> Self-note: an interim `build --verify` "FAIL" in my run was a harness artifact
> of my own `git checkout HEAD -- manifest.txt` (which reverted to the STALE
> committed manifest before verify). Re-verified against the correct working-tree
> manifest → rc=0. The working tree was restored; final `git diff --name-only` is
> the unchanged 14-file set.

**Check 32′ banner unchanged** — confirmed (Check 2c); no stale realistic-ot
assertion broke (the BD-203 C-1 failure mode does not recur).

---

## Severity-ranked findings

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT (advisory, no action required for C2 correctness):** `_stream_is_id_shaped`
  classifies a stream as ID-shaped via `^\^[A-Z]+-` on the `entry_regex` string.
  This is correct for the current STREAMS set and is the right STREAMS-derived
  approach (vs a two-place hard-code). It does assume future ID streams keep an
  uppercase-letter-run-then-hyphen filename anchor; the docstring already documents
  this assumption, so no change is needed — noted only for future-stream awareness.

---

## Rules-Applied Verification Block

### Per-rule

| Rule | Evidence | Conclusion |
|---|---|---|
| **CI-guard measure-then-bound** | `_CANON_HEADER_RE` = design spec; guard passes 211 canonical entries (validate-pack PASSED, RC=0) + rejects suffix (H1) + parenthetical (H2) + both (H3) + admits clean (H4); stream-scoped via `_stream_is_id_shaped` (STREAMS-derived `^\^[A-Z]+-`, version stream SKIPPED); no widened allowlist. | COMPLIANT |
| **Enumerate ENCODING surfaces** | 14 grammar sites + pack `_rules.md` + 6 tests simplified in lockstep; guard applicability derived from the SAME STREAMS `entry_regex` the filename loop consumes (no two-place hard-code); Group H tests added in the same commit as the guard. | COMPLIANT |
| **Pack/project separation + no regression** | diff = 14 files, NO `project-template/`, NO `changelog/_rules.md` (verified `git diff --name-only`); pack `_rules.md` edited, project `_rules.md` zero-diff; engine agrees with canonical template; `test-v11-realistic-ot.sh` 33/33 green. | COMPLIANT |
| **Pattern-matching antipattern** | per-site property-fit (table, Check 1); version-shaped `^v\d+\.md$` (×2) + `v\d+\.\d+(?:-[a-z0-9-]+)?` cross-ref + `phase-` token KEPT, not over-simplified. | COMPLIANT |
| **Rename/measure-then-bound (grep-zero)** | `grep -rln 'BD-167b\|BD-169b' backlog/ scripts/` → EMPTY; `[a-z]*` ID grammar grep over 6 code files → EMPTY (quoted, Check 5). | COMPLIANT |
| **Verify the FULL CI suite** | entire `tests` job (50 steps) + 2 `build.sh` + `validate` job run; aggregate 52/52 GREEN (quoted, Check 7); Check 32′ banner unchanged. | COMPLIANT |
| **Empirical evidence + Rules-Applied Block** | every claim backed by quoted command output at HEAD `94d789d`; this block present. | COMPLIANT |

### Per-read-doc

| Document | Read evidence | Conclusion |
|---|---|---|
| `PLAN-BD-211.md` | Read full (827 lines); §Commit C2 items 1–14 mapped to diff. | COMPLIANT |
| `ARCHITECTURE-BD-211.md` | Read full (530 lines); §3/§4/§5 recipes verified against diff. | COMPLIANT |
| `git diff` (14 files) | Read full via `git diff`; every hunk inspected. | COMPLIANT |
| `validate-pack.py` (`check_mirror_in_sync`, `_CANON_HEADER_RE`, `_stream_is_id_shaped`, STREAMS, CROSS_REF_RE) | Read via diff + grep (L306–313, L3187–3340, L3489–3504); `_stream_is_id_shaped` behavior run live. | COMPLIANT |
| `backlog/_rules.md` (pack) | Read full diff; simplifications confirmed. | COMPLIANT |
| `project-template/.../backlog/_rules.md` + `changelog/_rules.md` | `git diff --stat` → zero diff (VERIFY-only). | COMPLIANT |
| 6 test files | Read full diffs; Group H read in full; re-pins confirmed; all run green. | COMPLIANT |
| `.github/workflows/validate-pack.yml` | Enumerated all `tests`-job + `validate` steps via grep; full set run. | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Provided in full in context; the relevant rules (measure-then-bound, enumerate-encoding-surfaces, pack/project separation, pattern-matching, grep-zero, full-CI, empirical-evidence) applied above. | COMPLIANT |

**No named document was derived rather than read.** Every claim was measured live
via Bash/python3 at HEAD `94d789d` against the C2 working tree.

---

**Verdict: PASS — ready to commit. No fixes required.**
