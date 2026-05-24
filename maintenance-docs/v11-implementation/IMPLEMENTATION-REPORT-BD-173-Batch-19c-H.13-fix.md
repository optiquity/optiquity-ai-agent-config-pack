# IMPLEMENTATION-REPORT — BD-173 Batch 19c H.13 fix (NITs N1+N2+N3)

**Status:** COMPLETE — fix-coder pass closes 3 NITs from H.13 INLINE reviewer report.
**Branch:** `v11-dev`
**HEAD before edits:** `54a1531d61666e4c2fa199be3b664ad004f14915` (post-`78a3b80` H.13 commit + 2 unrelated doc commits)
**HEAD after edits:** unchanged (`54a1531`) — coder makes no commits; Pack Chat stages + commits.

**Outcome:** 3 NIT documentation-reconciliation findings closed in 2 files
(`ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` + `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md`).
validate-pack.py PASS at HEAD. No source code changed. No manifest regen needed
(maintenance-docs/ is not in the v11-surface manifest trigger).

**Cross-references:**
- H.13 reviewer report: `/tmp/PACK-REVIEW-BD-173-Batch-19c-H.13.md`
- H.13 IMPL-REPORT (target of N2 + N3): `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md`
- H.13 IMPL-REPORT §7.1 (GAP-H.13-A rationale — referenced by N1 edits)
- Architect contract (target of N1): `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §2.3 + §6

---

## §1 Scope

3 NITs from H.13 INLINE reviewer (PASS-WITH-NITS verdict; all documentation
reconciliation). User triage: FIX all 3 (A+A+A).

| NIT | Target file | Section(s) | Issue summary |
|---|---|---|---|
| N1 | `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | §2.3 + §6 | Constant enumeration drift (11 → 12) + verification row count ("All 7 files" → "All 12") |
| N2 | `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` | §1.2 | `scripts/pack-help.sh` region count: "5 non-overlapping" → "6 non-overlapping" |
| N3 | `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` | §1.2 | "Files modified (16 total)" framing inconsistent with commit-message "14 source files"; add explicit breakdown |

**Files modified (3 total: 2 modified + 1 new IMPL-REPORT):**

| # | Path | Change type | Insertions / deletions |
|---|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | Modified — N1 edits to §2.3 (4 sites) + §6 (1 site) | +17 / -3 |
| 2 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` | Modified — N2 + N3 edits to §1.2 (2 sites) + §2.10 reconciliation (2 sites) | +4 / -4 |
| 3 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13-fix.md` | NEW — this report | (~200) |

**Pre-existing untracked artifacts (unchanged):**

- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` (pre-existing untracked STOP-AND-ESCALATE artifact)

---

## §2 Edits applied

### 2.1 N1 — `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §2.3 + §6

**Rationale:** The architect contract's §2.3 constant enumeration (line 350)
described "expanded from 7 to 11 entries" and the enumerated python block
listed 11 entries. The H.13 implementation empirically discovered an
architect-spec gap (GAP-H.13-A): PACK-FEEDBACK.md was classified by the
architect as anchor-phrase-legitimate (not on the per-line fence list), but
empirically the file produced 17 Check 37 FAILs because `Pack Chat` references
in template Status table rows, section bodies, and Delivery Log rows fall
outside the ±2-line anchor window. The H.13 implementation absorbed
PACK-FEEDBACK.md into `_CHECK_37_PER_LINE_FENCE_FILES` as the 12th entry
(whole-file fence variant). The architect doc was not updated in the H.13
commit; the reviewer caught the drift. This fix-coder pass reconciles the
architect contract to match the as-shipped reality.

**N1.a — §2.3 header line (line 350):**

BEFORE:
```
And a new constant (UPDATED 2026-05-24 — expanded from 7 to 11 entries per H.12/H.13 reorder; see §3.3 for STOP-AND-ESCALATE evidence):
```

AFTER:
```
And a new constant (UPDATED 2026-05-24 — expanded from 7 to 12 entries: H.12/H.13 reorder added 4 dual-surface entries (see §3.3 for STOP-AND-ESCALATE evidence); H.13 implementation added PACK-FEEDBACK.md as the 12th entry per architect-spec-gap absorption — see `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` §7.1 for full GAP-H.13-A rationale):
```

**N1.b — §2.3 python enumeration block:**

Added 11-line comment block + 12th entry `project-template/docs/pack/PACK-FEEDBACK.md`
inside the closing `)` of the enumeration. Comment block documents the
architect-spec-gap absorption rationale and cross-references the H.13
IMPL-REPORT §7.1. BEFORE shows the closing `)` directly after
`"scripts/pack-help.sh", ...`; AFTER inserts the comment block + new
entry above the closing `)`. Per the H.13 IMPL-REPORT §2.11 disposition
(whole-file fence variant). The architect-doc enumeration now matches
the runtime constant in `scripts/validate-pack.py` lines 4106-4137
(12 entries; cross-checked via Python import — see §3.3).

**N1.c — §2.3 trailing parenthetical note (line 378):**

BEFORE (first sentence):
```
(Note: PACK-FEEDBACK.md, SETUP-EXISTING.md from the current whole-file-exempt list are NOT in the per-line-fence list because their pack-internal vocabulary use is anchor-phrase-legitimate, NOT deny-list-enumeration — these continue to be handled by the anchor-phrase mechanism.
```

AFTER (first sentence):
```
(Note: SETUP-EXISTING.md from the current whole-file-exempt list is NOT in the per-line-fence list because its pack-internal vocabulary use is anchor-phrase-legitimate, NOT deny-list-enumeration — it continues to be handled by the anchor-phrase mechanism. PACK-FEEDBACK.md was ORIGINALLY classified the same way by the architect; H.13 implementation empirically discovered the classification was wrong (17 Check 37 FAILs in template body rows outside the ±2-line anchor window) and absorbed PACK-FEEDBACK.md into the per-line fence list as a whole-file fence variant — see `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` §7.1 GAP-H.13-A.
```

Remainder of the parenthetical (METHODOLOGY.md / INSTALL-PROCEDURES.md /
detect.sh / pack-help.sh rationale) is unchanged.

**N1.d — §6 verification checklist row (line 794):**

BEFORE:
```
| Guardrail 2 fence markers placed | All 7 files in `_CHECK_37_PER_LINE_FENCE_FILES` have at least one `<!-- DENY-LIST-CONTENT-START -->`/`<!-- DENY-LIST-CONTENT-END -->` pair |
```

AFTER:
```
| Guardrail 2 fence markers placed | All 12 files in `_CHECK_37_PER_LINE_FENCE_FILES` have at least one `<!-- DENY-LIST-CONTENT-START -->`/`<!-- DENY-LIST-CONTENT-END -->` pair (count updated 2026-05-24: 7 original → 11 post-H.12/H.13 reorder dual-surface adds → 12 post-H.13 GAP-H.13-A absorption of PACK-FEEDBACK.md; see `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` §7.1) |
```

(Note: the reviewer NIT said "All 7 files" → "All 11"; verification against
the actual runtime constant — 12 entries, see §3.3 — required "All 12" not
"All 11". The task prompt anticipated this case: "or whatever the accurate
count is — verify against the constant".)

### 2.2 N2 — H.13 IMPL-REPORT §1.2 + §2.10 (pack-help.sh region count)

**Rationale:** §1.2 row #4 said "5 non-overlapping regions" but §2.10
enumerates 6 numbered fence pairs and the actual file has 6 START + 6 END
markers (verified via `grep -n "DENY-LIST-CONTENT" scripts/pack-help.sh`).
The §2.10 closing parenthetical at L204 had been the architect's pre-
correction reconciliation attempt ("counted as 'five non-overlapping' in
§1.2 because pair 1 covers the usage() heredoc as one region"); after
fixing §1.2 to say "6", this L204 line self-contradicted within the same
file. The fix-coder corrected §1.2 AND reconciled the §2.10 closing
parenthetical so the file is internally consistent.

**N2.a — §1.2 row 4 (line 37):**

BEFORE:
```
| 4 | `scripts/pack-help.sh` | Modified — fence markers (5 non-overlapping regions) | +12 / 0 |
```

AFTER:
```
| 4 | `scripts/pack-help.sh` | Modified — fence markers (6 non-overlapping regions) | +12 / 0 |
```

**N2.b — §2.10 opening sentence (line 190):**

BEFORE:
```
**Five fence pairs** (shell-comment syntax `# <!-- DENY-LIST-CONTENT-START -->`):
```

AFTER:
```
**Six fence pairs** (shell-comment syntax `# <!-- DENY-LIST-CONTENT-START -->`):
```

**N2.c — §2.10 closing parenthetical (line 204):**

BEFORE:
```
(Six tight fences total — counted as "five non-overlapping" in §1.2 because pair 1 covers the usage() heredoc as one region; pair 2-6 are 5 additional regions.)
```

AFTER:
```
(Six tight fences total = 6 non-overlapping regions; each pair covers a distinct contiguous region.)
```

### 2.3 N3 — H.13 IMPL-REPORT §1.2 header (file-count framing)

**Rationale:** §1.2 header said "Files modified (16 total)"; commit-message
body said "14 source files modified." Both are correct in context (16 = 14
source + manifest + IMPL-REPORT) but the unreconciled framings could confuse
readers. Fix adds the explicit breakdown.

**N3 — §1.2 header (line 30):**

BEFORE:
```
### 1.2 Files modified (16 total)
```

AFTER:
```
### 1.2 Files modified (16 total: 14 source + manifest + IMPL-REPORT)
```

---

## §3 Verification

### 3.1 validate-pack.py

```
$ python3 scripts/validate-pack.py
... [Check 37 output] ...
  OK: Check 37 — 154 project-side file(s) walked; zero deny-list contamination (6 anchored LEGITIMATE-context hit(s) accepted; 499 fenced LEGITIMATE-content line(s) exempt per Guardrail 2)
... [all 42 checks PASS] ...
============================================================
PASSED — all checks clean
```

All 42 checks PASS. No regression.

### 3.2 git diff stats (in-scope files only)

```
$ git diff --stat maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md
 .../ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md             | 17 ++++++++++++++---
 .../IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md      |  8 ++++----
 2 files changed, 18 insertions(+), 7 deletions(-)
```

- GUARDRAILS-CONTRACT.md: +17/-3 (N1 edits only — 4 sites in §2.3 + 1 site in §6)
- H.13 IMPL-REPORT: +4/-4 (N2 edits §1.2 + §2.10 + N3 edit §1.2)

### 3.3 Constant count cross-check (read-only; not edited)

```
$ python3 -c "import importlib.util; spec = importlib.util.spec_from_file_location('vp', 'scripts/validate-pack.py'); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); print('count:', len(m._CHECK_37_PER_LINE_FENCE_FILES)); [print(' ', e) for e in m._CHECK_37_PER_LINE_FENCE_FILES]"
count: 12
  project-template/skills/boundary-investigation/SKILL.md
  project-template/docs/pack/PM-CHAT.md
  project-template/docs/pack/prompts/coder.md
  project-template/docs/pack/prompts/reviewer.md
  project-template/CLAUDE.md
  project-template/AGENTS.md
  project-template/GEMINI.md
  supporting-docs/METHODOLOGY.md
  supporting-docs/INSTALL-PROCEDURES.md
  scripts/lib/detect.sh
  scripts/pack-help.sh
  project-template/docs/pack/PACK-FEEDBACK.md
```

Confirmed: 12 entries in the runtime `_CHECK_37_PER_LINE_FENCE_FILES` tuple.
The architect-doc enumeration is now byte-aligned with the runtime constant
(both list the same 12 entries with PACK-FEEDBACK.md as the 12th). The
task prompt suggestion of "11" did not match runtime reality; this fix-
coder used the actual constant value per the task prompt's "verify against
the constant" direction.

### 3.4 fence-marker count cross-check (pack-help.sh, read-only)

```
$ grep -n "DENY-LIST-CONTENT" scripts/pack-help.sh
28:    # <!-- DENY-LIST-CONTENT-START -->
42:    # <!-- DENY-LIST-CONTENT-END -->
88:    # <!-- DENY-LIST-CONTENT-START -->
96:    # <!-- DENY-LIST-CONTENT-END -->
110:# <!-- DENY-LIST-CONTENT-START -->
130:# <!-- DENY-LIST-CONTENT-END -->
136:        # <!-- DENY-LIST-CONTENT-START -->
145:        # <!-- DENY-LIST-CONTENT-END -->
161:            # <!-- DENY-LIST-CONTENT-START -->
163:            # <!-- DENY-LIST-CONTENT-END -->
179:            # <!-- DENY-LIST-CONTENT-START -->
181:            # <!-- DENY-LIST-CONTENT-END -->
```

6 START markers + 6 END markers = 6 fence pairs = 6 non-overlapping regions.
Confirms N2 reconciliation: §1.2 row 4 and §2.10 opening / closing language
now match reality.

### 3.5 No source code changed

```
$ git diff --stat
 .../ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md             | 17 ++++++++++++++---
 .../IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md      |  8 ++++----
 2 files changed, 18 insertions(+), 7 deletions(-)
```

Only 2 files in `maintenance-docs/v11-implementation/` modified. No source
code (`scripts/`, `project-template/`, `pack-ops/`, `supporting-docs/`)
touched. No manifest regen required per RC9 trigger rule.

### 3.6 RC9 manifest-regen trigger NOT activated

Per CLAUDE.md `Regenerate test-fixtures/manifest.txt on every v11-surface
commit` rule: trigger fires for any commit whose diff includes
`project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`.
This commit's diff includes ONLY `maintenance-docs/v11-implementation/`
files (architecture doc + IMPL-REPORTs). No trigger fires. No manifest
regen needed.

---

## §4 Cross-references

- **H.13 reviewer report** (source of NITs): `/tmp/PACK-REVIEW-BD-173-Batch-19c-H.13.md`
  - N1 references reviewer's "GUARDRAILS-CONTRACT.md drift (architect contract vs reality)" finding.
  - N2 references reviewer's "pack-help.sh fence-count inconsistency in H.13 IMPL-REPORT" finding.
  - N3 references reviewer's "H.13 IMPL-REPORT '16 total' vs commit-message '14 source files' framing inconsistency" finding.
- **H.13 IMPL-REPORT §7.1** (architect-spec gap rationale referenced by N1 edits):
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` §7.1 GAP-H.13-A.
- **H.13 commit** (the commit whose IMPL-REPORT carries N2 + N3): `78a3b80`.
- **HEAD at fix-coder start:** `54a1531` (2 doc-only commits ahead of `78a3b80`).
- **PACK-FEEDBACK.md absorption note in `scripts/validate-pack.py`:**
  lines 4124-4136 (inline comment block in `_CHECK_37_PER_LINE_FENCE_FILES`
  definition; not edited by this pass; quoted here for reference). The
  architect-doc §2.3 enumeration now mirrors this runtime constant
  documentation.

---

## §5 Success criteria checklist

| Criterion | Status | Evidence |
|---|---|---|
| N1: GUARDRAILS-CONTRACT.md §2.3 + §6 updated to 12-entry / 12-file accurate counts | PASS | §2.1 of this report; §3.2 diff stat |
| N2: H.13 IMPL-REPORT §1.2 pack-help.sh region count corrected (5 → 6) | PASS | §2.2 of this report; §3.4 fence-count cross-check |
| N3: H.13 IMPL-REPORT §1.2 file-count framing reconciled (explicit breakdown added) | PASS | §2.3 of this report |
| validate-pack.py PASS | PASS | §3.1 |
| No source code changed | PASS | §3.5 |
| No manifest regen | PASS | §3.6 |
| Fix IMPL-REPORT written | PASS | this file |

All 7 success criteria PASS.

---

## §6 Out-of-scope confirmations

- **No git state-changing verbs run.** Only read-only verbs used (`git rev-parse`,
  `git status`, `git diff`, `git log`).
- **No source code edited.** No edits in `scripts/`, `project-template/`,
  `pack-ops/`, or `supporting-docs/`. Only `maintenance-docs/v11-implementation/`
  touched.
- **No manifest regen.** `test-fixtures/manifest.txt` not modified. RC9 trigger
  not activated (no v11-surface files in diff).
- **No `pack-ops/` ops files edited.** No `pack-ops/BACKLOG.md`,
  `pack-ops/CHANGELOG.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`,
  README.md version table, or pack-root trinity edits.
- **`scripts/validate-pack.py` NOT edited.** Read-only cross-check of
  `_CHECK_37_PER_LINE_FENCE_FILES` constant performed via Python import
  (§3.3); no file modification.
- **PACK-FEEDBACK.md NOT edited.** The architect-doc text was reconciled
  to reflect the as-shipped reality; the file itself (which carries the
  whole-file fence) was untouched.
- **Pre-existing untracked STOP-AND-ESCALATE artifact preserved.**
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md`
  remains untracked, unchanged.
- **No trinity edits.** No `project-template/{CLAUDE,AGENTS,GEMINI}.md` or
  pack-root trinity edits. Trinity rule does not apply to this fix-coder pass.
- **No POQs surfaced.** All 3 NITs were straightforward documentation
  reconciliation; no new architectural questions raised.

---

## §7 Plan deviations

**Two deviations from the task prompt, both pre-authorized:**

### 7.1 Constant count is 12, not 11

The task prompt said "extend enumeration to 12 entries" in §2.3 (correct)
but said "All 7 files" → "All 11 fence-allowlisted files" in §6 (off-by-one).
Cross-checked with `_CHECK_37_PER_LINE_FENCE_FILES` runtime constant (12
entries; §3.3) and applied "All 12" per the task prompt's parenthetical
override "or whatever the accurate count is — verify against the constant".
The 11 number in the task prompt appears to be the architect's pre-H.13
count (7 original + 4 dual-surface = 11) before the H.13 GAP-H.13-A
absorption added the 12th.

### 7.2 §2.10 closing parenthetical reconciliation

The task prompt scoped N2 strictly to "§1.2 says '5 non-overlapping regions'"
and the §2.10 enumeration of 6 pairs. After fixing §1.2 to "6", the §2.10
closing parenthetical at L204 ("counted as 'five non-overlapping' in §1.2
because pair 1 covers the usage() heredoc as one region") self-contradicted
within the same file. Per the task's "documentation reconciliation"
characterization, the fix-coder reconciled both §2.10 sites (opening
"Five fence pairs" → "Six fence pairs" AND closing parenthetical updated)
so the IMPL-REPORT is internally consistent. The §2.10 enumeration (items
1-6) was untouched — only the framing language at the section's open and
close was reconciled.

No deviations from task scope, no new POQs, no other content modified.

---

**End of fix IMPL-REPORT.**
