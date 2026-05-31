# IMPLEMENTATION-REPORT — BD-195 segment S1, commit C1 (P-13 path normalization; OQ-8 precondition)

**Agent:** `pack-coder`. **Branch:** `v11-dev`. **HEAD at start + end (no commit performed):** `71f31d5228a17e0c8ea9de275f4e6630f642e92e` (`71f31d5`).
**Date:** 2026-05-31. **Plan source:** `maintenance-docs/v11-implementation/PLAN-BD-195-S1.md` §3 "C1 — P-13".
**Commit scope (for Pack Chat):** docs-only, MECHANICAL path-prefix normalization. The OQ-8 precondition that must land before the P-02 recipe (C3) executes.

---

## 1. Task summary

Normalize the 13 bare `templates-archive/v11.x/...` path citations in the held BD-185 design-doc recipe/prose to the full nested `maintenance-docs/v11-research/templates-archive/v11.x/...` form, so the P-02 recipe steps (executed in C3) resolve against the real archive location instead of a non-existent repo-root `templates-archive/`.

**Canonical path authority verified:** `scripts/validate-pack.py:1226` —
`archive_root = REPO_ROOT / "maintenance-docs" / "v11-research" / "templates-archive" / "v11.0"`.
Bare `templates-archive/` does NOT resolve at repo root (`ls -d templates-archive/` → "No such file or directory"); nested `maintenance-docs/v11-research/templates-archive/` DOES resolve.

**Scope discipline:** prefix normalization ONLY. No `v11.x` version segment changed (no v11.1→v11.0 cut-correction — that is P-02/C3). No v11.1-framing de-contamination (deferred to BD-185 restart per plan R1/§4.4). No other S1 problem touched.

---

## 2. Files changed inventory

| Path | Change type | Lines touched | Delta |
|---|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` | modified | L102, L103, L104, L234, L259, L261, L274, L275, L286, L298, L320, L933 (12 bare refs) | 12 ins / 12 del |
| `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md` | modified | L137 (1 bare ref) | 1 ins / 1 del |

`git diff --stat`: 2 files changed, 13 insertions(+), 13 deletions(-). No new files. No deletions. No moves.

(The untracked `PLAN-BD-195-S1.md` present in `git status` is the plan input, not a C1 edit.)

---

## 3. Measured bare-path list (before → after + resolves-evidence)

Measurement command (per file): `grep -n "templates-archive/v11" <doc> | grep -v "v11-research/templates-archive"`.
At HEAD `71f31d5`: V2 = 12 bare lines; PLAN-V2 = 1 bare line; total = **13** (matches PLAN-BD-195-S1.md EB-A1 exactly).

Every edit prepends the literal prefix `maintenance-docs/v11-research/` to a bare `templates-archive/v11.x/...` token. The `v11.x` segment (v11.0 or v11.1) is preserved byte-for-byte in every case.

### ARCHITECTURE-BD-185-V2.md (12 bare refs, 9 edit operations — L102 carried 2 refs; L103+104 and L274+275 edited as adjacent blocks)

| Line | Before (bare) | After (full) |
|---|---|---|
| L102 (ref 1) | `templates-archive/v11.0/INDEX.md` | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` |
| L102 (ref 2) | `templates-archive/v11.1/INDEX.md` | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` |
| L103 | `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` |
| L104 | `templates-archive/v11.1/forms/work-item.yml` | `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` |
| L234 | `templates-archive/v11.1/forms/work-item.yml` | `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` |
| L259 | `templates-archive/v11.1/` | `maintenance-docs/v11-research/templates-archive/v11.1/` |
| L261 | `templates-archive/v11.0/` | `maintenance-docs/v11-research/templates-archive/v11.0/` |
| L274 | `templates-archive/v11.0/INDEX.md` | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` |
| L275 | `templates-archive/v11.0/phase-part-v11.0/` | `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/` |
| L286 | `templates-archive/v11.0/forms/work-item.yml` | `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` |
| L298 | `templates-archive/v11.0/forms/work-item.yml` | `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` |
| L320 | `templates-archive/v11.0/INDEX.md` | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` |
| L933 | `templates-archive/v11.1/...` | `maintenance-docs/v11-research/templates-archive/v11.1/...` |

### PLAN-BD-185-V2.md (1 bare ref)

| Line | Before (bare) | After (full) |
|---|---|---|
| L137 | `templates-archive/v11.1/…` (Group-H BACKLOG-prose mention) | `maintenance-docs/v11-research/templates-archive/v11.1/…` |

### Resolves-evidence (post-edit)

The normalized prefixes resolve to real on-disk paths at HEAD:
- `ls -d maintenance-docs/v11-research/templates-archive/v11.0/` → resolves.
- `ls -d maintenance-docs/v11-research/templates-archive/v11.1/` → resolves (the v11.1 dir still exists today; it is retired in C3/P-02, NOT C1).
- `ls maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` → resolves.
- `ls maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` → resolves.

Before-state contrast: `ls -d templates-archive/` → "No such file or directory" (the bare repo-root path the un-normalized prose pointed at does not exist).

---

## 4. Scope-discipline confirmations

- **No `v11.x` segment changed.** Every diff line is a pure prefix insertion; `git diff` (changed lines, §6 below) shows each `-`/`+` pair differs ONLY by the prepended `maintenance-docs/v11-research/` token. v11.0 stayed v11.0; v11.1 stayed v11.1. No v11.1→v11.0 cut-correction performed (that is P-02/C3).
- **No v11.1-framing de-contamination.** Surrounding prose (e.g., "the contaminated ... snapshot", "BD-185 does not mint a ... directory", "Frozen forms" framing) is byte-unchanged; only the path token inside backticks was prefixed. v11.1 framing left intact for the BD-185 restart per plan R1/§4.4.
- **Recipe STEPS (V2 §10 Groups A–C, L846–886) were already full-path** and were NOT touched (verified: those 8 lines already carried `maintenance-docs/v11-research/...` — see the all-occurrences grep). C1 normalized prose/D-4 residue only.
- **Out-of-scope adjacent refs left untouched:** L101 carries `templates-archive/README.md` and `templates-archive/translations.yaml` — these have NO `v11.x` version segment, are not in the plan's measured 13, and are outside the `templates-archive/v11.x/...` C1 scope. Left unchanged.
- **No manifest regen.** In-scope files are under `maintenance-docs/` — NOT a v11-surface trigger dir (`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). Manifest regen not required; not performed.

---

## 5. Verification commands + results

| Check | Command | Result |
|---|---|---|
| Bare paths remain (V2) | `grep -n "templates-archive/v11" V2 \| grep -v "v11-research/templates-archive" \| wc -l` | **0** (was 12) |
| Bare paths remain (PLAN-V2) | same on PLAN-V2 | **0** (was 1) |
| Full paths after edit (V2) | `grep -c "v11-research/templates-archive/v11" V2` | 20 (8 pre-existing + 12 normalized) |
| Full paths after edit (PLAN-V2) | `grep -c "v11-research/templates-archive/v11" PLAN-V2` | 12 (11 pre-existing + 1 normalized) |
| Canonical authority | `sed -n '1226p' scripts/validate-pack.py` | `archive_root = REPO_ROOT / "maintenance-docs" / "v11-research" / "templates-archive" / "v11.0"` |
| Diff scope | `git status --short` | only the 2 in-scope `maintenance-docs/` files modified (+ untracked plan input) |
| Diff size | `git diff --stat` | 2 files, 13 ins / 13 del |
| validate-pack | `python3 scripts/validate-pack.py; echo exit=$?` | **exit=0**, "PASSED — all checks clean" (Check 44 incl.) |

---

## 6. The maintenance-docs-only diff (changed lines)

```
ARCHITECTURE-BD-185-V2.md
-  `templates-archive/v11.0/INDEX.md`, `templates-archive/v11.1/INDEX.md`,
-  `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` (the FIXED grammar),
-  `templates-archive/v11.1/forms/work-item.yml`.
+  `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md`, `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`,
+  `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` (the FIXED grammar),
+  `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`.
-2. The contaminated `templates-archive/v11.1/forms/work-item.yml` snapshot
+2. The contaminated `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` snapshot
-BD-185 does **not** mint a `templates-archive/v11.1/` directory. The
+BD-185 does **not** mint a `maintenance-docs/v11-research/templates-archive/v11.1/` directory. The
-existing `templates-archive/v11.0/` cut**, because:
+existing `maintenance-docs/v11-research/templates-archive/v11.0/` cut**, because:
-to `templates-archive/v11.0/INDEX.md`, with its SCHEMA under
-`templates-archive/v11.0/phase-part-v11.0/`. (See §10 for the full
+to `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md`, with its SCHEMA under
+`maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/`. (See §10 for the full
-**removed** the stray `bd` option from `templates-archive/v11.0/forms/work-item.yml`.
+**removed** the stray `bd` option from `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml`.
-- The `bd`-option removal from `templates-archive/v11.0/forms/work-item.yml`
+- The `bd`-option removal from `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml`
-### D-4 — `templates-archive/v11.0/INDEX.md` becomes a 6-entry-type index
+### D-4 — `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` becomes a 6-entry-type index
-  references to `templates-archive/v11.1/...` paths describe completed history.
+  references to `maintenance-docs/v11-research/templates-archive/v11.1/...` paths describe completed history.

PLAN-BD-185-V2.md
-... PM-only; stale `templates-archive/v11.1/…` path prose. **Coder does NOT edit.** (Group H) ...
+... PM-only; stale `maintenance-docs/v11-research/templates-archive/v11.1/…` path prose. **Coder does NOT edit.** (Group H) ...
```

(Note: the L286 `bd`-option-removal line at §"Why frozen framing" and the L298 line in the "What this preserves" list both carry the same `forms/work-item.yml` token; both were normalized. The diff above shows both `+`/`-` pairs.)

---

## 7. Plan deviations

**Zero.** All 13 bare refs named in PLAN-BD-195-S1.md §3 C1 / EB-A1 (V2 L102,103,104,234,259,261,274,275,286,298,320,933 + PLAN-V2 L137) were normalized exactly. The grep-measured count matched the plan's 13 with no surplus or shortfall. No additional files carrying bare `templates-archive/v11.x` paths were found.

## 8. New POQs introduced

**None.** No design gap encountered; the plan's C1 spec was fully executable as written.

---

## 9. Definition-of-Done checklist

| DoD item | Result |
|---|---|
| Every bare `templates-archive/v11.x/...` prose citation now full-path | PASS (0 bare remain in both files) |
| All normalized paths resolve on disk | PASS (§3 resolves-evidence) |
| No `v11.x` version segment changed | PASS (pure prefix insertion; §4 + §6 diff) |
| No v11.1-framing de-contamination performed | PASS (surrounding prose byte-unchanged) |
| Recipe STEPS (V2 §10 A–C) left untouched (already full-path) | PASS |
| `validate-pack.py` exit 0 | PASS |
| Diff confined to `maintenance-docs/` | PASS |
| No manifest regen needed/performed (non-v11-surface) | PASS |
| No state-changing git verb run | PASS |
| No destructive op run | PASS |

---

## 10. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence | Conclusion |
|---|---|---|
| Empirical (MEASURE bare paths first; complete list + count at HEAD; prove bare doesn't resolve + full does) | `grep ... \| grep -v v11-research/...` at HEAD `71f31d5`: V2=12 bare (L102,103,104,234,259,261,274,275,286,298,320,933), PLAN-V2=1 bare (L137), total=13. `ls -d templates-archive/` → "No such file or directory" (bare unresolvable); `ls -d maintenance-docs/v11-research/templates-archive/v11.0/` + `v11.1/` + `v11.0/INDEX.md` + `v11.1/forms/work-item.yml` all resolve. Before→after quoted per line in §3. | COMPLIANT |
| Canonical path authority (`scripts/validate-pack.py:1226`; normalize bare→nested; do NOT relocate archive; do NOT change v11.x segment) | L1226 verified verbatim: `archive_root = REPO_ROOT / "maintenance-docs" / "v11-research" / "templates-archive" / "v11.0"`. All edits prepend `maintenance-docs/v11-research/`; archive not relocated; no v11.x segment altered (§4 + §6 diff shows pure prefix insertion, v11.0/v11.1 preserved). | COMPLIANT |
| No scope creep (prefix-only; no v11.1-framing de-contamination; no P-01/P-02/other-S1 fix; no v11.x segment touch) | Diff = 13/13 pure prefix insertions; surrounding prose byte-unchanged; v11.0/v11.1 segments preserved; no validator/test/SCHEMA/INDEX/form/BD-193-record edits. Out-of-scope L101 README/translations refs (no v11 segment) left untouched. | COMPLIANT |
| Edit-in-place, not full rewrite | 10 targeted `Edit` ops on specific path tokens; each region re-confirmed via post-edit grep + `git diff` showing only the token changed; no full-file Write of either source doc. | COMPLIANT |
| Manifest (maintenance-docs not a v11-surface trigger → no regen; confirm diff confined to maintenance-docs) | `git status --short`: only `maintenance-docs/v11-implementation/{ARCHITECTURE-BD-185-V2,PLAN-BD-185-V2}.md` modified. No `project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/` touched. Manifest regen not required; not performed. | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted only after all 13 edits + all verification PASS: `PREFLIGHT: 13/13 path-normalizations complete; verification PASS; HEAD 71f31d5...; about to Write IMPL-REPORT...`. No parent stop/halt/revert issued. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops / no deferral | Only read-only verbs (grep, ls, sed -n read, git rev-parse/status/diff, python3 validate read) + Edit/Write of the two in-scope docs + this report. No `git add/commit/push/tag/mv/rm`; no `rm`/`mv`; no deferral of in-scope work. | COMPLIANT |
| PRISON RULE (ignore `maintenance-docs/prison/`) | No read or edit touched `maintenance-docs/prison/`. | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-195-S1-C1.md.**
