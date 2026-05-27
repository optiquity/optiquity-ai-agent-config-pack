# IMPLEMENTATION-REPORT — BD-185 H.1 NITs

**Branch:** v11-dev
**Base HEAD (pre-fix):** `ba9e09d`
**Post-fix HEAD:** `ba9e09d` (working-tree edits; no commit per agent rules)
**Scope:** 4 NIT findings from `PACK-REVIEW-BD-185-H.1.md`
**Decision basis:** user-locked default-fix-all triage; single commit; frozen IMPL-REPORT-Batch-19d-H.1.md untouched
**Date:** 2026-05-27

---

## §1 Scope

Small follow-on fix landing the 4 NIT findings surfaced by the H.1
reviewer pass (`PACK-REVIEW-BD-185-H.1.md`). All four are local edits
in two files; no architecture, contract, or test surface is touched.

The frozen historical artifact `IMPLEMENTATION-REPORT-BD-185-Batch-19d-
H.1.md` is intentionally NOT modified per the reviewer §5 finding —
post-merge tampering with the IMPL-REPORT would falsify history; the
subsequent narrative cleanups are documented in the BD-193 / BD-194
IMPL-REPORTs.

---

## §2 Files modified

| Path | Change type | NITs landed |
|---|---|---|
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | modified | NIT-1, NIT-2 |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | modified | NIT-3, NIT-4 |

No new files. No deletions. Two `Edit` operations on SCHEMA.md; one
`Edit` on INDEX.md (covering both INDEX edits via a single contiguous
replacement).

---

## §3 Per-NIT details

### NIT-1 — `phase-part-v11.1/SCHEMA.md:L145` — stale `§4.1` cite

The reference was to the architect doc's old §4.1; the equivalent
in-file section in this SCHEMA.md is §1 (Identifier scheme), which
defines the null-Part task identifier form.

**BEFORE (L144-145):**
```
- `Phase-N.Task-M` — depends on a specific task (null-Part task
  identifier per §4.1)
```

**AFTER (L144-145):**
```
- `Phase-N.Task-M` — depends on a specific task (null-Part task
  identifier per §1)
```

### NIT-2 — `phase-part-v11.1/SCHEMA.md:L168` — stale `architect §7` cite

Anomalous reference to architect doc §7 post-BD-193 narrative cleanup.
The fallback extension is correctly noted as TBD; the architect-doc
back-reference is the stale element.

**BEFORE (L167-168):**
```
- **Label fallback** `parent:phase-N` on the Part otherwise (V3.2 §2.7;
  architect §7 fallback extension TBD).
```

**AFTER (L167-168):**
```
- **Label fallback** `parent:phase-N` on the Part otherwise (V3.2 §2.7;
  fallback extension TBD).
```

### NIT-3 — `v11.1/INDEX.md:L62` — tense mismatch

L53-60 frames the v11.1 forms cut as future-state ("Not yet created. …
will be populated …"); L62 then switched to present indicative ("is
bumped … gains"), creating a tense conflict. Both verbs in the
compound predicate are normalized to future-tense.

**BEFORE (L62-63):**
```
The live form is bumped to `template_version: work-item-v11.1`
and gains:
```

**AFTER (L62-63):**
```
The live form will be bumped to `template_version: work-item-v11.1`
and gain:
```

(Both "is bumped → will be bumped" AND "gains → gain" — compound
predicate matches in tense.)

### NIT-4 — `v11.1/INDEX.md:L53` — H2 heading restoration

The `**Forms file**` inline bold label functioned as an implicit
section header but was not a real H2; the surrounding INDEX.md
sections all use `##` H2 headings. Promoted to a real `## Forms file`
H2 and dropped the redundant bold-prefix on the now-following
paragraph.

**BEFORE (L53):**
```
**Forms file** — Not yet created. The v11.1 forms/ subdirectory will be
populated when the v11.1 archive cut is completed (architect-pass
decision pending). When populated, the snapshot must reflect the
post-BD-193 pack/project divergence: pack-root admits the `bd` wi-type
option for filing pack-development backlog items; project-template
does NOT, since clients use TD entries. The two forms are SEPARATE
artifacts with SEPARATE audiences per the pack/project
separation-of-concerns principle.
```

**AFTER (L53-62):**
```
## Forms file

Not yet created. The v11.1 forms/ subdirectory will be populated when
the v11.1 archive cut is completed (architect-pass decision pending).
When populated, the snapshot must reflect the post-BD-193 pack/project
divergence: pack-root admits the `bd` wi-type option for filing
pack-development backlog items; project-template does NOT, since
clients use TD entries. The two forms are SEPARATE artifacts with
SEPARATE audiences per the pack/project separation-of-concerns
principle.
```

---

## §4 Verification results

### 4.1 validate-pack.py — PASS

```
python3 scripts/validate-pack.py
…
Check 43 — 151 project-side / client-installed file(s) walked; zero pack-internal bare cross-references …
Check 42 — 10 per-check test file(s) on disk; 10 workflow invocation(s) found; zero unwired tests.

PASSED — all checks clean
```

No regression. All 43 checks clean.

### 4.2 Fixture manifest verify — PASS (no drift)

```
bash test-fixtures/build.sh --verify
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: 570b7f8628abaa0ebe8d5580797f790f1165eea7
  v11-flat-file OK: 4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
  v11-tracker-on OK: 8f584b117f39d5826c7360f0e45a56cc6bfc1fce
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All 6 fixtures verify OK against the committed manifest. As expected
for `maintenance-docs/` edits (not on the v11-surface trigger list of
`project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/`),
no fixture drift; no manifest regen required.

### 4.3 Grep verification — PASS

```
=== NIT-1 (expect 0) === grep -n "per §4.1" …/phase-part-v11.1/SCHEMA.md
(0 matches)

=== NIT-2 (expect 0) === grep -n "architect §7" …/phase-part-v11.1/SCHEMA.md
(0 matches)

=== NIT-3 (expect 0) === grep -n "live form is bumped" …/v11.1/INDEX.md
(0 matches)

=== NIT-4 (expect 1) === grep -n "^## Forms file" …/v11.1/INDEX.md
53:## Forms file
```

All four greps match the expected post-fix state (NIT-1/2/3 purged;
NIT-4 H2 heading present at L53).

---

## §5 PREFLIGHT

```
PREFLIGHT: 2 files edited (4 NITs across phase-part-v11.1/SCHEMA.md + v11.1/INDEX.md); validate-pack.py PASS; manifest verify PASS (no drift); HEAD ba9e09d; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-H.1-NITS.md
```

---

## §6 Definition-of-Done checklist

| Item | Status |
|---|---|
| All 4 NITs applied per BEFORE/AFTER specs | PASS |
| `validate-pack.py` PASS (no regression) | PASS |
| Manifest verify clean (no drift) | PASS |
| Grep verification confirms purge | PASS |
| PREFLIGHT emitted | PASS |
| IMPL-REPORT written | PASS |
| Out-of-scope files untouched (frozen IMPL-REPORT-Batch-19d-H.1.md, pack memory, PM-only) | PASS |
| Trinity rule N/A (no CLAUDE/AGENTS/GEMINI touched) | N/A |

---

## §7 Plan deviations

None. Zero deviations from the user-locked decisions and the
prompt's BEFORE/AFTER specs.

---

## §8 New POQs introduced

None. The fixes are textual cleanups against reviewer findings; no
new open questions surfaced.

---

## §9 Boundary discipline check

Both edited files live under `maintenance-docs/v11-research/
templates-archive/v11.1/` — pack-side maintenance content, not
project-shipped. No project-side SSOT investigation required; no
project-side surface touched. No pack-only-reference-in-project-side
risk.

---

## §10 Files changed inventory

```
M maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md
M maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
A maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-H.1-NITS.md
```

Three working-tree changes total: two source edits (the 4 NITs), one
new IMPL-REPORT (this file).
