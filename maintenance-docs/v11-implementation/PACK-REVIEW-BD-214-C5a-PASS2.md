# PACK-REVIEW — BD-214 COMMIT C5a PASS-2 (NIT-1 title fix + whole-set commit-readiness)

**Reviewer:** fresh pack-reviewer (final pass, independent). **Date:** 2026-06-13.
**Branch:** v11-dev. **HEAD:** `cdfe87dd6a7a063d0a5c913265b7e230f144d3c8`.
**Scope reviewed:** the ENTIRE uncommitted C5a working-tree change set as it now
stands AFTER the NIT-1 fix — 21 modified backlog entries + the title fix on
`backlog/BD-185.md` + regenerated `backlog/_toc.md` + the NEW `backlog/BD-216.md`
+ the BD-197 fold. (`backlog/BD-214.md` carries only a pre-existing 2026-06-12 dated
note; the untracked `maintenance-docs/` IMPL/REVIEW reports are agent artifacts, not
codebase edits.)

**Read-only mandate honored:** the only file written this session is THIS report. All
other operations were read-only — `git status/rev-parse/log/diff/show`, an independent
toc regen (produced byte-identical output, no net change), validate-pack ×2, and the
full wired test battery. NO `add/commit/push/tag/stash/reset`. The CI manifest-restore
step (`git checkout HEAD -- test-fixtures/manifest.txt`) was reproduced read-only via a
`/tmp` backup + `cp` (no git state change). HEAD unchanged.

---

## VERDICT: **APPROVE — CLEAN.** The C5a set (incl. the NIT-1 title fix) is commit-ready.

The pass-1 NIT (BD-185 title overclaiming "tracker-mode execution ordering") is FIXED
correctly and minimally. The fix is a single title-text change on line 2 plus a
sanctioned `_toc.md` regeneration; no body content changed; the new title accurately
reflects BD-185's flat-file-only re-scope with no tracker overclaim. The complete
pass-1-approved C5a set (all 21 re-scopes + BD-216 authoring + BD-197 fold) is intact
and unregressed. The FULL CI wired battery is GREEN. Scope is clean (backlog/-only; no
v11-surface/manifest delta). No new findings of any severity.

---

## 1. NIT-1 title fix — correct + minimal (independently verified)

### The title diff (`git diff HEAD -- backlog/BD-185.md`, line 2)

```
-**BD-185 — Phase parts hierarchy + tracker-mode execution ordering**
+**BD-185 — Phase-parts hierarchy + flat-file execution ordering**
```

**ID + em-dash unchanged; only the title text after the em-dash changed.** Parsed the
line structurally:

```
RAW: '**BD-185 — Phase-parts hierarchy + flat-file execution ordering**'
ID: BD-185                         (unchanged)
EM-DASH present: True              (the U+2014 em-dash retained)
TITLE-after-em-dash: Phase-parts hierarchy + flat-file execution ordering
contains 'tracker': False          (no tracker overclaim)
```

No pre-em-dash parenthetical; no letter suffix (no-bd-letter-suffix clean). The
ID-extraction contract (text after the em-dash) holds.

### Title accuracy vs the as-re-scoped body (no overclaim)

The body is re-scoped flat-file-only — `RE-SCOPE 2026-06-13` line; `File/Symbol
(flat-file half — this entry)`; `Goal (flat-file half…)`; `Success Criteria (flat-file
half — this entry)`; tracker legs (SC6/SC7, P3, `work-item.yml` Part field,
TrackerProvider sync) explicitly "MOVED to BD-216." The new title:
- "Phase-parts hierarchy" mirrors P2 (`Phase N → Parts (1..p)`) and the dominant
  in-body hyphenated usage ("phase-parts structure/design"); the hyphenation is the
  more-correct compound form and is harmless.
- "flat-file execution ordering" mirrors the retained `SC4 (flat-file leg)` ("Execution
  ordering of phases is expressible in flat-file mode via execution notes"). The dropped
  "tracker-mode" qualifier is precisely the leg now carried by BD-216. No concept the
  body has relocated is advertised by the title. CORRECT.

### `_toc.md` BD-185 row regenerated (not hand-edited)

`backlog/_toc.md:19` reads `- [BD-185](./BD-185.md) — Phase-parts hierarchy +
flat-file execution ordering` — byte-identical to the entry title (line 2). Independent
regeneration via the sanctioned helper produced a BYTE-IDENTICAL file:

```
source scripts/lib/per-entry/toc-regenerate.sh && per_entry_regenerate_toc pack-backlog backlog
REGEN EXIT=0
TOC BYTE-IDENTICAL: regenerated matches working tree (not hand-edited)
```

Confirmed regenerated, not hand-edited (Check 33 in-sync, see §3).

---

## 2. Whole C5a set still coherent (nothing regressed)

- **Scope unchanged from pass-1:** `git diff HEAD --stat -- backlog/` shows the same 23
  modified files + untracked `backlog/BD-216.md`. The only delta the FIX layered on top
  of the pass-1-approved working tree is BD-185 line 2 + the regenerated `_toc.md`
  BD-185 row (confirmed against IMPL-REPORT-BD-214-C5a-FIX1.md and by diffing).
- **BD-185 body intact:** every body change in `git diff HEAD -- backlog/BD-185.md` is
  the pass-1-approved C5a re-scope (RE-SCOPE line, flat-file File/Symbol set, P3/P4
  tracker-moved annotations, SC re-scope, SC-SER add, SC6/SC7→BD-216). The fix did not
  alter any of it.
- **BD-216 (NEW) intact + on-scope:** Status `Deferred`; Target `none — no release
  version; lands with the tracker-resumption release` (cluster enumerated). Blockers =
  BD-185 (semantic source) + BD-215 (format) + BD-204/BD-207 (machinery). Carries the
  moved tracker SCs (SC6/SC7/SC4-tracker/SC8-tracker) + SC-RT round-trip + the
  symbiosis-with-BD-185 hard clause. Next-integer (BD-215 → 216); filename unique.
- **BD-197 fold intact:** single +1-line bolded sub-heading inside `Description:`
  (git-permission hardening anchor); `Status: Unblocked` and `Target: v11.0` unchanged.
- **Reciprocal wiring consistent:** BD-185 `Unblocks: BD-215` ↔ BD-215 `Blockers:
  BD-185` ↔ BD-216 names BD-185 as semantic source (BD-185 → blocks → BD-215 → gates
  resumption). All three agree.

---

## 3. Integrity — Check 33 / 34 / 32′ (general + DEEP)

`python3 scripts/validate-pack.py` → **EXIT=0** — `PASSED — all checks clean`.
`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **EXIT=0** — `PASSED — all
checks clean`.

Quoted from the general run:
```
── Check 32′: no pack monolith exists (BD-203) ──
  OK: backlog/ — no monolith present; _rules.md + _toc.md present; filenames conform (no-mirror SSOT)
  OK: changelog/ — no monolith present; _rules.md + _toc.md present; filenames conform (no-mirror SSOT)
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/_toc.md byte-identical (22180 bytes)
  OK: changelog/_toc.md byte-identical (582 bytes)
── Check 34: cross-reference integrity (BD-168) ──
  OK: cross-reference integrity: 3069 reference(s) across 227 per-entry file(s); all resolved to defined IDs ...
```

- **Check 33 (toc in-sync):** byte-identical (22180 bytes). PASS.
- **Check 34 (cross-refs):** 3069 references across 227 files, all resolved. The
  BD-185→BD-216 and BD-215→BD-216 references resolve (BD-216.md present; referenced by
  BD-185, BD-215, BD-216, _toc.md). Deprecation pointers (BD-100→BD-205, BD-102, BD-174)
  resolve. PASS.
- **Check 32′ (no monolith):** PASS. DEEP run additionally clean (Check 49 title-length
  ≤256 codepoints covers the new title; Check 51 flip-block PASS).

---

## 4. Full CI suite — every wired script, NO sampling

Wired-command list extracted from `.github/workflows/validate-pack.yml`
(`grep -nE "run: (bash|python3|git checkout)"` — both jobs). Every command run locally
against the C5a working tree.

### `validate` job (2 commands)
| Command | Exit | Evidence |
|---|---|---|
| `python3 scripts/validate-pack.py` | **0** | `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** | `PASSED — all checks clean` |

### `tests` job — pre-fixture scripts (49), all EXIT=0
Run individually (per-name, not glob, not sampled); summary line:
```
===PRE_DONE fail=0 count=49===
```
Each of: `test-detect.sh, tracker-provider-test.sh, tracker-config-test.sh,
tracker-init-test.sh, tracker-agent-read-test.sh, tracker-migrate-{forward,reverse,
roundtrip}-test.sh, test-tracker-phase-task.sh, test-tracker-links.sh,
test-tracker-cycle-check.sh, tracker-errors-test.sh, tracker-config-schema-test.sh,
recommendation-state-schema-test.sh, test-per-entry.sh,
test-validate-pack-checks-32-33-34.sh, ...-checks-36-37-38.sh,
...-check-{39,40,41,18,16,19,42,43,44,45,46}.sh, ...-removed-doc-advisory.sh,
...-check-49-field-faithfulness.sh, ...-check-50-codec-single-source.sh,
...-check-51-flip-block.sh, tracker-deferral-gate-test.sh,
tracker-bd{129,130,132,133,134}-*.sh, recommendation-test.sh, pack-help-test.sh,
test-customization-preserve.sh, test-init-project.sh,
test-migrate-v10-to-v11{,-dry-run,-gates,-decompose}.sh, test-migrator-core.sh,
test-migrator-manifest.sh, test-migrator-capability-translation.sh` → **EXIT=0**.

### Fixture build / restore / verify
| Step | Exit | Evidence |
|---|---|---|
| `bash test-fixtures/build.sh --all --clean` | **0** | `manifest written: …/test-fixtures/manifest.txt` |
| manifest restore (read-only `cp` from /tmp backup; CI uses `git checkout HEAD --`) | n/a | restored to committed SHA `8337c164449d51bd46fc3224f22bbe56b179d3d3` |
| `bash test-fixtures/build.sh --verify` | **0** | all 6 fixtures `OK` (v10-minimal / v10-realistic-ot / v11-realistic-ot / v11-flat-file / v11-tracker-on / existing-project-mid-dev) |

### `tests` job — post-fixture scripts (6), all EXIT=0
```
test-v11-realistic-ot.sh        EXIT=0
test-migrator-skills.sh         EXIT=0
test-persona-contracts.sh       EXIT=0
template-translations-test.sh   EXIT=0
template-version-test.sh        EXIT=0
test-issue-forms.sh             EXIT=0
===POST_DONE fail=0 count=6===
```
`test-v11-realistic-ot.sh` re-runs Check 34 and PASSES, confirming the BD-216 cross-ref
is fully resolved.

**Result: ENTIRE wired battery GREEN** — validate ×2 (EXIT=0) + 49 pre-fixture (EXIT=0)
+ build/verify (EXIT=0) + 6 post-fixture (EXIT=0). Zero failures.

---

## 5. Scope — backlog/-only; deferred BDs untouched; no v11-surface/manifest delta

- **Only `backlog/` changed:** `git status --short` minus `backlog/` and untracked
  `maintenance-docs/` reports → `(none)`. No `project-template/`, `scripts/`,
  `pack-ops/`, `supporting-docs/`, or `test-fixtures/` tracked delta.
- **`backlog/BD-214.md`** carries ONLY the pre-existing single `+` 2026-06-12 dated note
  (`Note (2026-06-12, user decisions on scope item 5): GH-Issues disposition DECIDED …`)
  — NOT a C5a re-scope edit.
- **BD-188 / BD-198 / BD-212 / BD-213 UNCHANGED** (`git diff --quiet HEAD` clean for
  each) — correctly deferred to C5b.
- **No v11-surface / manifest delta:** `backlog/` is not under any v11-surface dir, so
  the `regenerate-manifest-v11-surface` rule does not apply; `test-fixtures/manifest.txt`
  is at the committed SHA `8337c164…` and `git status --short test-fixtures/` shows no
  tracked delta.

---

## 6. Findings by severity

**BLOCKER:** none.
**MUST:** none.
**SHOULD:** none.
**NIT:** none. (The pass-1 NIT-1 — BD-185 title overclaim at `backlog/BD-185.md:2` — is
RESOLVED; the new title contains no "tracker" string and matches the flat-file-only
body.)

---

## 7. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Git verbs this session: `status`, `rev-parse HEAD`, `log`, `diff`, `show`; one independent toc regen (byte-identical, no net change); manifest restore via `/tmp` backup + `cp` (NOT `git checkout`). Zero `add/commit/push/tag/stash/reset`. HEAD unchanged `cdfe87dd6a7a063d0a5c913265b7e230f144d3c8`. | COMPLIANT |
| 2 | Read-only mandate (write ONLY the report) | Sole file write = this report at the prompted path `…/PACK-REVIEW-BD-214-C5a-PASS2.md`. All codebase inspection read-only; no Edit/Write to any `backlog/` or other file. | COMPLIANT |
| 3 | Independent verification (commands + quoted output; full wired-test run) | §4 ran validate-pack general (EXIT=0) + DEEP (EXIT=0) + all 49 pre-fixture scripts (`===PRE_DONE fail=0 count=49===`) + build/verify (EXIT=0, 6 fixtures OK) + all 6 post-fixture scripts (`===POST_DONE fail=0 count=6===`). §1 re-parsed the title line + independently regenerated `_toc.md` (byte-identical). §3 quoted Check 32′/33/34. | COMPLIANT |
| 4 | Real fix (only title+toc changed; new title accurate) | §1: BD-185 line-2 title is the sole fix-introduced delta (`-…tracker-mode execution ordering**` / `+…flat-file execution ordering**`); ID `BD-185` + em-dash unchanged; `contains 'tracker': False`; body unchanged; `_toc.md:19` regenerated to match (byte-identical). New title matches the flat-file-only body (`File/Symbol (flat-file half — this entry)`, retained `SC4 (flat-file leg)`). | COMPLIANT |
| 5 | Severity-tagged findings with file:line | §6: BLOCKER/MUST/SHOULD/NIT = none; pass-1 NIT-1 at `backlog/BD-185.md:2` confirmed RESOLVED. | COMPLIANT |
| 6 | Rules-Applied Verification Block (name + quoted evidence + conclusion; empty=VIOLATED) | This table; 7 rows, each with concrete quoted evidence; no empty cells. | COMPLIANT |
| 7 | PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: review complete; full CI wired-test job run …; about to Write <path>` in the message immediately before this write. No parent stop/halt received. | COMPLIANT |

**Read-in-full attestation.** Read directly this session: CLAUDE.md (full, incl. all
`## Pack memory`); `.github/workflows/validate-pack.yml` (full, both jobs);
`backlog/BD-185.md` (full new title + body) + its prior `git show cdfe87d:` version;
`backlog/_toc.md` (full, BD-185 row); `backlog/BD-216.md` (full); the C5a diffs for
BD-197 / BD-214 / BD-215; PACK-REVIEW-BD-214-C5a.md (pass-1, for NIT context only — not
used to bias this independent pass) and IMPL-REPORT-BD-214-C5a-FIX1.md. No named
document was derived rather than read.

**End of PACK-REVIEW-BD-214-C5a-PASS2.md**
