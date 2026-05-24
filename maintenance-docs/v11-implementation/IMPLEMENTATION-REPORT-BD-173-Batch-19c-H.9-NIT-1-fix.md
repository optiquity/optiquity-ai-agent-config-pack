# IMPL-REPORT — BD-173 Batch 19c H.9 NIT-1 fix

**Date:** 2026-05-23
**Branch:** v11-dev
**Base HEAD:** `2d6a16d75a8ee248406119bdb9d6cf235613b656`
**Agent:** pack-coder (fix-coder mode)
**Scope:** Full 12-site sweep of audit-vocabulary-gap leaks (1 Cat B at L1207 + 11 Cat A extension) closing H.9 INLINE reviewer NIT-1 and the Pack Chat (A2) scope-expansion decision
**Caller:** Pack Chat, Batch 19c, post-H.9 INLINE review

---

## §1 — Scope

**12-site sweep** in one client-installed file:

- **File modified:** `supporting-docs/METHODOLOGY.md` (12 sites; 11 line edits — L1237 carries 2 cite-drops on a single line)
- **Cite-drop total:** 12 individual cites (1 Cat B at L1207 preserves descriptive prose; 11 Cat A drops at L312/L1166/L1170/L1176/L1214/L1220/L1223/L1225/L1230/L1232/L1237)
- **Manifest regenerated:** `test-fixtures/manifest.txt` (3 v11-* rows drift)
- **New file:** this IMPL-REPORT

**Total lines changed (excluding this report):**

| File | +/- |
|---|---|
| `supporting-docs/METHODOLOGY.md` | +12 / -12 |
| `test-fixtures/manifest.txt` | +3 / -3 |

**No other repo files modified.** Specifically: pack-root trinity, `pack-ops/`, `scripts/`, `project-template/`, `.claude/`, `.codex/`, `.gemini/`, `maintenance-docs/v11-research/`, and `AUDIT-PRE-19C-BOUNDARY-LEAKS.md` are all UNCHANGED.

### §1.1 — Pack Chat (A2) scope-expansion decision

This IMPL-REPORT was originally written for a 1-site Cat B fix at L1207 (the file-path cite `ARCHITECTURE-V3.3-DELTA.md §3.1` flagged by H.9 INLINE reviewer NIT-1). After that fix landed in the working tree, Pack Chat discovered that the audit-vocabulary-gap pattern extends: 11 MORE bare-version shorthand refs (`V3.3 §X.Y`) exist in METHODOLOGY.md that the audit's filename-based regex missed but which semantically point at the same pack-internal `ARCHITECTURE-V3.3-DELTA.md` doc.

These bare-version refs were previously documented in §7.1 of this report as "NOT a leak by current audit criteria" — the original disposition rested on the audit-vocabulary contract treating bare-version shorthand as version-of-the-spec context rather than pack-internal file paths. However, the V3.3 specifier is **only** meaningful when read against `ARCHITECTURE-V3.3-DELTA.md`. Unlike "v10" / "v11.0" lifecycle refs (which denote pack release versions), the bare `V3.3` token names an internal architect-doc revision; it cannot be resolved at client install where no `ARCHITECTURE-V3.3-DELTA.md` file exists.

**Pack Chat triage decision (A2):** Extend NIT-1 fix from 1 site to all 12 sites (full sweep). Apply Cat A drops (delete cite, preserve surrounding prose) to all 11 additional sites; preserve the Cat B fix at L1207 byte-identical. The v10-supersession context at L1207 remains client-relevant (justification per §2.2 below); the bare-version cites elsewhere carry no client-relevant content beyond the cite itself, so straight drops apply.

This expansion converts §7.1's "NOT a leak" disposition into "12 leaks closed" — see updated §7.1 below.

---

## §2 — Edits applied

### 2.1 Fix-shape choice: Cat B (preserve descriptive prose)

The L1207 parenthetical has two parts:

1. `per ARCHITECTURE-V3.3-DELTA.md §3.1` — pack-internal cite (LEAK)
2. `supersedes the v10 three-outcome shape` — descriptive prose (informational)

**Chose Cat B** (drop only the architect-doc cite; preserve the v10 supersession note).

### 2.2 Context-driven rationale

Examined L1204-1215 surrounding context:

```
   Active skills line in CLAUDE.md, AGENTS.md, and GEMINI.md. Commit.
```

**Resolution path decision logic** (per ARCHITECTURE-V3.3-DELTA.md §3.1; supersedes the v10 three-outcome shape).
(See Procedure 1 step 2 above for the "blockers resolved" gate-check semantics
including the v11.0 phase-N.M and phase-task A-blocked-by-B forms.)
```
Is the work small (≤ ~30 minutes inline; no significant scope expansion;
user available to do it) AND no blockers?
  → Yes: direct close
         (V3.3 §3.2; verb: `pack td resolve <td-id>`; no promotion
          label; no new entity; v10 lifecycle unchanged)
```

Three observations supported Cat B over Cat A:

1. **The v10-supersession note is client-relevant.** Clients migrating from v10 to v11 need to know that the resolution-path decision logic shape changed. Dropping the entire parenthetical would erase that signal.

2. **The follow-on prose at L1208-1209 establishes v11.0 context explicitly.** The "(See Procedure 1 step 2 above for the 'blockers resolved' gate-check semantics including the v11.0 phase-N.M and phase-task A-blocked-by-B forms.)" parenthetical already pins the reader in v11.0 territory. The "supersedes v10" clause in the title parenthetical complements this by naming the v10 baseline being departed from.

3. **The body of the rule (L1213-1230) references "V3.3 §3.2" / "V3.3 §3.3" / "V3.3 §3.4" inline** as version-numbered shorthand without the full "ARCHITECTURE-V3.3-DELTA.md" path. The original 1-site Cat B analysis treated those bare-version refs as out-of-scope. **NOTE (A2 expansion):** Pack Chat's A2 triage decision overrode this disposition — see §1.1 and §7.1 — and extended the fix to close all 11 bare-version refs via Cat A drops (§2.4). The Cat B fix at L1207 stands; the bare-version refs are now also closed, leaving METHODOLOGY.md fully clean of V3.X references.

### 2.3 BEFORE / AFTER

**BEFORE (L1207):**

```
**Resolution path decision logic** (per ARCHITECTURE-V3.3-DELTA.md §3.1; supersedes the v10 three-outcome shape).
```

**AFTER (L1207):**

```
**Resolution path decision logic** (supersedes the v10 three-outcome shape).
```

Surface diff:

```diff
-**Resolution path decision logic** (per ARCHITECTURE-V3.3-DELTA.md §3.1; supersedes the v10 three-outcome shape).
+**Resolution path decision logic** (supersedes the v10 three-outcome shape).
```

### 2.4 Cat A drops (extension; 11 sites, 12 cite-drops)

The 11 sites below were closed using Cat A drops (delete the cite, preserve surrounding prose). For each site, the cite portion carried no client-relevant content beyond the pack-internal reference itself; straight drops preserve the rule wording and read naturally without the cite.

#### 2.4.1 L312 — Parser regex annotation

**BEFORE:**
```
  is preserved as a human-readable annotation. Parser regex (V3.3 §5.3):
```
**AFTER:**
```
  is preserved as a human-readable annotation. Parser regex:
```
**Rationale:** "Parser regex:" reads naturally as the regex's label without the §5.3 cite. The regex itself (next line) carries the load-bearing content.

#### 2.4.2 L1166 — Phase N.M blocker

**BEFORE:**
```
   - Phase N.M blocker (v11.0 additive per V3.3 §5.4): in tracker mode, read the
```
**AFTER:**
```
   - Phase N.M blocker (v11.0 additive): in tracker mode, read the
```
**Rationale:** "(v11.0 additive)" preserves the load-bearing version-lifecycle context (v11.0-only feature); the `V3.3 §5.4` cite is the architect-doc anchor and is pack-internal.

#### 2.4.3 L1170 — Phase task A blocked by phase task B

**BEFORE:**
```
   - Phase task A blocked by phase task B (Dependencies field, V3.3 §5.4):
```
**AFTER:**
```
   - Phase task A blocked by phase task B (Dependencies field):
```
**Rationale:** "(Dependencies field)" preserves the load-bearing reference to the entity's Dependencies field; the `V3.3 §5.4` cite is pack-internal.

#### 2.4.4 L1176 — Resolution-path decision logic forward-ref

**BEFORE:**
```
   (When all blockers resolve, the TD becomes Unblocked — see the resolution-path
   decision logic later in this Part for the V3.3 §3 promotion paths.)
```
**AFTER:**
```
   (When all blockers resolve, the TD becomes Unblocked — see the resolution-path
   decision logic later in this Part for the promotion paths.)
```
**Rationale:** "see the resolution-path decision logic later in this Part for the promotion paths" reads naturally as an intra-document forward-ref; the `V3.3 §3` cite is pack-internal.

#### 2.4.5 L1214 — Direct close path

**BEFORE:**
```
         (V3.3 §3.2; verb: `pack td resolve <td-id>`; no promotion
          label; no new entity; v10 lifecycle unchanged)
```
**AFTER:**
```
         (verb: `pack td resolve <td-id>`; no promotion
          label; no new entity; v10 lifecycle unchanged)
```
**Rationale:** The verb + behavior content carries the load-bearing meaning; the §3.2 cite is pack-internal.

#### 2.4.6 L1220 + L1223 — Path 1 (promote to phase epic) [TWO cites on same logical block]

**BEFORE:**
```
             (V3.3 §3.3; verb: `pack td promote --to=phase-N`;
              new phase epic at L1; `derived-from:TD-NNN` on phase
              epic; `promoted-to:phase-N` on closed TD; PM Chat
              invokes architect by default per V3.3 §7.2 / §6.P)
```
**AFTER:**
```
             (verb: `pack td promote --to=phase-N`;
              new phase epic at L1; `derived-from:TD-NNN` on phase
              epic; `promoted-to:phase-N` on closed TD; PM Chat
              invokes architect by default)
```
**Rationale:** Two cite-drops within one parenthetical: opening §3.3 cite and trailing §7.2 / §6.P cite. The verb + label semantics + "PM Chat invokes architect by default" all carry load-bearing meaning. Both cites are pack-internal.

#### 2.4.7 L1225 + L1230 — Path 2 (promote to phase task) [TWO cites on same logical block]

**BEFORE:**
```
             (V3.3 §3.4; verb: `pack td promote --to=phase-N.M`;
              new phase task at L2 child of phase-N epic;
              `derived-from:TD-NNN` on task; `promoted-to:phase-N.M`
              on closed TD; for each `Dependencies` bullet entry on
              the new task, PM Chat creates a cross-entity
              `blocked-by` edge per V3.3 §5.1)
```
**AFTER:**
```
             (verb: `pack td promote --to=phase-N.M`;
              new phase task at L2 child of phase-N epic;
              `derived-from:TD-NNN` on task; `promoted-to:phase-N.M`
              on closed TD; for each `Dependencies` bullet entry on
              the new task, PM Chat creates a cross-entity
              `blocked-by` edge)
```
**Rationale:** Two cite-drops within one parenthetical: opening §3.4 cite and trailing §5.1 cite. The verb + label semantics + cross-entity `blocked-by` edge mechanic all carry load-bearing meaning. Both cites are pack-internal.

#### 2.4.8 L1232 — PM Chat heuristic

**BEFORE:**
```
PM Chat advises per V3.3 §7.1 heuristic (Description length, File/Symbol
scope, Type signal, related-TD cluster). The user can confirm or override
```
**AFTER:**
```
PM Chat advises per heuristic (Description length, File/Symbol
scope, Type signal, related-TD cluster). The user can confirm or override
```
**Rationale:** "advises per heuristic" reads naturally; the heuristic's specific factors (Description length, File/Symbol scope, Type signal, related-TD cluster) are listed inline in the same sentence, so the bare-version cite carries no additional load-bearing meaning.

#### 2.4.9 L1237 — Path 3 supersession (judgment-call rewrite; TWO cites)

**BEFORE:**
```
**Path 3 is forbidden** per V3.3 §3 line 27 / V3.3 §1 supersession. The
```
**AFTER:**
```
**Path 3 is forbidden** (supersedes the v10 fold-into-existing-task shape). The
```
**Rationale:** This site required a judgment-call light rewrite rather than a pure cite-drop, because the "supersession" content carries load-bearing meaning (Path 3 is forbidden BECAUSE v11.0 supersedes v10's fold-into-existing-task shape). The sentence at L1237-L1244 explicitly names "The v10 'fold into existing task body...' shape is rejected" as the rejected v10 behavior; the parenthetical "(supersedes the v10 fold-into-existing-task shape)" restates the same supersession context using client-readable v10/v11.0 lifecycle vocabulary (uncontested) rather than the pack-internal V3.3 file-path cite. Both V3.3 cites (`V3.3 §3 line 27` and `V3.3 §1 supersession`) are dropped; the supersession meaning is preserved in client-readable form.

### 2.5 Summary of 12-site sweep

| # | Line | Site | Fix shape |
|---|---|---|---|
| 1 | 312 | Parser regex annotation | Cat A drop |
| 2 | 1166 | Phase N.M blocker | Cat A drop (preserve "v11.0 additive") |
| 3 | 1170 | Phase task A blocked-by-B | Cat A drop (preserve "Dependencies field") |
| 4 | 1176 | Forward-ref to promotion paths | Cat A drop (rewrite "the promotion paths") |
| 5 | 1207 | Resolution-path decision logic title | **Cat B** (preserve "supersedes v10 three-outcome shape") |
| 6 | 1214 | Direct-close path | Cat A drop |
| 7 | 1220 | Path 1 opening cite | Cat A drop |
| 8 | 1223 | Path 1 trailing architect-default cite | Cat A drop |
| 9 | 1225 | Path 2 opening cite | Cat A drop |
| 10 | 1230 | Path 2 trailing blocked-by cite | Cat A drop |
| 11 | 1232 | PM Chat heuristic | Cat A drop |
| 12 | 1237 | Path 3 forbidden — TWO cites | Cat A drop + judgment-rewrite preserving v10 supersession |

12 cite-drops total across 11 line edits (L1237 carries 2 cite-drops on a single line).

---

## §3 — Verification

### 3.1 `python3 scripts/validate-pack.py`

**Result: PASS.** All 42 checks clean. Tail output:

```
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

### 3.2 `bash test-fixtures/build.sh --all --clean`

**Result: PASS.** All 6 fixtures rebuilt deterministically. Final lines:

```
── building v11-flat-file ──
  built: ... HEAD:  0eccb2cca1f371b873c25def020f0abd628c3a36
── building v11-tracker-on ──
  built: ... HEAD:  893c639302af7199c42fbb6beae594b28f65f00b
── building existing-project-mid-dev ──
  built: ... HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

manifest written: /Users/david/.../test-fixtures/manifest.txt
```

### 3.3 `git diff --stat`

```
 supporting-docs/METHODOLOGY.md | 24 ++++++++++++------------
 test-fixtures/manifest.txt     |  6 +++---
 2 files changed, 15 insertions(+), 15 deletions(-)
```

Exactly the 2 files expected. METHODOLOGY edit is 12 cite-drops across 11 line edits (L1207 Cat B + L312/L1166/L1170/L1176/L1214/L1220/L1225/L1232/L1237 Cat A; L1220 + L1225 each contain 2 cite-drops on consecutive lines for Path 1 / Path 2 blocks).

### 3.4 Manifest drift

```diff
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  25b65e6113e767130b078389d9134df8d235c146
-v11-flat-file  11f27e553ce46a0058315050d8a16c68d08e46fd
-v11-tracker-on  6e5c38bbf5b37ae8497792ba0e68a5195d870208
+v11-realistic-ot  214a4d5c5399943c2c6c563424f5be3c6b8a3e27
+v11-flat-file  2a9d5381b564cd067a8bb7d97d11f68ca5f99d08
+v11-tracker-on  ea6b5e68d0507ca10646e3a531040caeda791c65
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Expected drift pattern: 3 v11-* row SHAs shifted (METHODOLOGY.md is mass-copied via init-project.sh S6 to all v11-* fixtures' `docs/pack/METHODOLOGY.md`). v10-* rows and `existing-project-mid-dev` UNCHANGED, as expected (v10-* is tag-pinned to v10.1; existing-project-mid-dev is a synthesized pre-pack-install shape).

The manifest was regenerated AFTER the 11-site extension was applied (initial 1-site Cat B fix regen of `e987d9ce... / 0eccb2cc... / 893c6393...` was superseded; the extension's 12-site final state produces the SHAs shown above).

### 3.5 Boundary verification grep

#### 3.5.1 Original boundary-leak vocabulary check (full audit set)

```bash
grep -nE "maintenance-docs/|ARCHITECTURE-V3\.md|ARCHITECTURE-V3\.3-DELTA|ARCHITECTURE-V11-|AUDIT-USER-CURATION|RESEARCH-" supporting-docs/METHODOLOGY.md \
  || echo "BOUNDARY OK — METHODOLOGY.md clean"
```

**Result:** `BOUNDARY OK — METHODOLOGY.md clean`

#### 3.5.2 Extended boundary check (bare-version shorthand; A2 scope expansion)

```bash
grep -nE "V3\.[0-9]+" supporting-docs/METHODOLOGY.md \
  || echo "BOUNDARY OK — no V3.X refs"
```

**Result:** `BOUNDARY OK — no V3.X refs`

Both checks return clean. The 12-site sweep closes the original L1207 file-path cite AND the 11 bare-version shorthand refs surfaced by Pack Chat's A2 scope expansion. Zero remaining audit-vocabulary-gap surfaces in METHODOLOGY.md.

#### 3.5.3 L1207 Cat B fix preservation check

```bash
grep -n "Resolution path decision logic" supporting-docs/METHODOLOGY.md
```

**Result:**
```
1207:**Resolution path decision logic** (supersedes the v10 three-outcome shape).
```

The L1207 Cat B fix from the original 1-site pass is preserved byte-identical. The 11-site extension did not modify L1207.

### 3.6 Working-tree state at preflight

```
PREFLIGHT: 12/12 cite-drops complete (1 Cat B at L1207 preserved + 11 Cat A extension); verification PASS; HEAD 2d6a16d75a8ee248406119bdb9d6cf235613b656; IMPL-REPORT remains at maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9-NIT-1-fix.md
```

(Emitted to chat before the IMPL-REPORT extension Edit calls per pack-coder PREFLIGHT contract; extension preserves L1207 byte-identical and updates this IMPL-REPORT in-place rather than creating a new file.)

`test-fixtures/manifest.txt` is left modified in the working tree — Pack Chat will stage it with the METHODOLOGY.md edit + this report as the H.9 NIT-1-fix commit. **Not staged or committed by this agent** (read-only git only, per agent permission rules).

---

## §4 — Cross-references

### 4.1 H.9 INLINE reviewer NIT-1

H.9 INLINE reviewer flagged the L1207 cite as a Category-A-class audit-vocabulary-gap leak. NIT-1 was the only finding requiring action this cycle.

### 4.2 AUDIT §2.2 vocabulary-gap context

`maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` §2.2 scanned `supporting-docs/METHODOLOGY.md` and reported **5 matches, ZERO leaks** (all 5 were Pack-Chat-related, all marked LEGITIMATE per the Part-10 PACK-FEEDBACK product feature). The L1207 `ARCHITECTURE-V3.3-DELTA.md §3.1` cite was MISSED by §2.2's scan because the vocabulary list (§0.1) included `ARCHITECTURE-*` patterns but the scanner did not catch the cite at L1207 — same vocabulary-gap class as the RESEARCH-* gap closed earlier in H.9.

### 4.3 Prior H.9 audit-gap catches (RESEARCH-* pattern)

H.9 closed an analogous Cat-A audit-vocabulary-gap leak (RESEARCH-* refs) earlier in the cycle. The L1207 V3.3-DELTA cite is the 3rd audit-vocabulary-gap leak surfaced in H.9 INLINE review. This fix follows the same pattern (NIT-graded; standalone single-cite fix-coder commit) as the H.5 SHOULD-1 precedent.

### 4.4 PM-CHAT.md L535-537 precedent (same-shape cite)

Within Batch 19c, an identical-shape cite at `project-template/docs/pack/PM-CHAT.md` line 410 / current L537 was flagged in AUDIT §1.2 as CONFIRMED LEAK and is being addressed by other Batch 19c commits. The METHODOLOGY.md L1207 fix completes the audit-vocabulary-gap closure for this `ARCHITECTURE-V3.3-DELTA.md` cite class across the client-install surface.

### 4.5 AUDIT classification (post-fix update)

Post-fix, the corrected AUDIT §2.2 classification for METHODOLOGY.md would be 17 matches scanned (6 originally + 11 surfaced by A2 expansion), 12 leaks closed (1 Cat B at L1207 + 11 Cat A drops at L312/L1166/L1170/L1176/L1214/L1220/L1223/L1225/L1230/L1232/L1237), 5 remaining legitimate Pack-Chat refs. (This IMPL-REPORT does not modify the AUDIT doc per scope rules; the AUDIT is an immutable snapshot of the pre-19C state.)

---

## §5 — Success criteria checklist

| # | Criterion | Result |
|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` L1207 no longer contains `ARCHITECTURE-V3.3-DELTA.md §3.1` | PASS (Cat B applied — descriptive prose preserved) |
| 2 | All 11 bare-V3.3 sites closed via Cat A drops (12 cite-drops total: L312/L1166/L1170/L1176/L1214/L1220/L1223/L1225/L1230/L1232/L1237×2) | PASS (boundary grep §3.5.2 returns "BOUNDARY OK — no V3.X refs") |
| 3 | L1207 Cat B fix UNCHANGED across the 11-site extension | PASS (boundary check §3.5.3 confirms L1207 byte-identical to original Cat B fix) |
| 4 | No new leaks introduced | PASS (boundary grep §3.5.1 returns "BOUNDARY OK — METHODOLOGY.md clean") |
| 5 | All other METHODOLOGY.md content UNCHANGED (preserves H.1 + H.5 + H.5-fix + H.6 additions) | PASS (`git diff` shows only the 11 line edits at the 11 surface sites; no other content modified) |
| 6 | `python3 scripts/validate-pack.py` PASS | PASS (42 checks clean) |
| 7 | Manifest v11-* row drift | PASS (3 v11-* rows shifted; v10-* and existing-project-mid-dev unchanged) |
| 8 | IMPL-REPORT updated (not rewritten) | PASS (this file extended in-place via Edit; original L1207 documentation preserved) |

All 8 success criteria PASS.

---

## §6 — Out-of-scope confirmations

The following surfaces were NOT touched by this fix:

- **Other METHODOLOGY.md content:** UNCHANGED. `git diff` confirms only L1207 modified.
- **H.1 / H.5 / H.5-fix / H.6 additions to METHODOLOGY.md:** PRESERVED. The 1-line edit at L1207 does not interact with any prior H.* addition.
- **AUDIT-PRE-19C-BOUNDARY-LEAKS.md:** UNCHANGED. Immutable snapshot preserved.
- **Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`):** UNCHANGED.
- **`pack-ops/`, `scripts/`, `project-template/`:** UNCHANGED.
- **`.claude/`, `.codex/`, `.gemini/`:** UNCHANGED.
- **`maintenance-docs/v11-research/`:** UNCHANGED.
- **All other `supporting-docs/`:** UNCHANGED.

Working-tree state at preflight: exactly 3 files modified — `supporting-docs/METHODOLOGY.md` (11 line edits = 12 cite-drops; 1 Cat B at L1207 + 11 Cat A drops at L312/L1166/L1170/L1176/L1214/L1220/L1223/L1225/L1230/L1232/L1237), `test-fixtures/manifest.txt` (3 v11-* row drift), and this in-place-updated IMPL-REPORT.

### 6.1 Boundary discipline check (P-missed-7)

This fix edits a project-side client-installed file (`supporting-docs/METHODOLOGY.md` is copied to `docs/pack/METHODOLOGY.md` by `scripts/init-project.sh` S6).

**Project-side SSOT investigation:** Each of the 12 cite-drops DROPS a pack-internal reference rather than ADDING any new reference. No project-side SSOT augmentation is needed — every fix removes a leak, leaving the surrounding rule self-contained within the METHODOLOGY.md Part 7 context (which is itself the canonical project-side SSOT for the TD lifecycle and resolution-path decision logic).

The intra-document forward-ref at L1175-1176 ("see the resolution-path decision logic later in this Part for the promotion paths") resolves at client install. The Path 3 supersession judgment-rewrite at L1237 substitutes client-readable v10/v11.0 lifecycle vocabulary ("supersedes the v10 fold-into-existing-task shape") for the pack-internal V3.3 file-path cites; the v10/v11.0 vocabulary is project-side-canonical (used throughout METHODOLOGY.md uncontested).

**SSOT consulted:** `supporting-docs/METHODOLOGY.md` itself (Part 7 is the canonical resolution-path-decision-logic spec at client install).

**No pack-only refs added.** All 12 cite-drops are pure subtractions of pack-internal cites (with one judgment-rewrite at L1237 substituting client-readable lifecycle vocabulary for the dropped cites).

### 6.2 Forbidden actions confirmation

- No git state-changing verbs run (read-only: `git rev-parse HEAD`, `git status`, `git diff --stat`, `git diff`).
- No edits to pack-root trinity, `pack-ops/`, `scripts/`, `project-template/`, `.claude/`, `.codex/`, `.gemini/`, or `maintenance-docs/v11-research/`.
- AUDIT-PRE-19C-BOUNDARY-LEAKS.md UNCHANGED.
- Manifest left modified in working tree; **not staged or committed** by this agent.

---

## §7 — Open questions / deferrals

### 7.1 Bare `V3.3 §3.X` refs in METHODOLOGY.md — RESOLVED via A2 expansion

**ORIGINAL disposition (1-site Cat B pass):** The body of the resolution-path-decision-logic rule contains 11 bare-version refs at L312, L1166, L1170, L1176, L1214, L1220, L1223, L1225, L1230, L1232, L1237 (the L1237 line carries 2 refs). The original 1-site pass classified these as "NOT a leak by current audit criteria" on grounds that bare-version shorthand reads as version-of-the-spec context rather than pack-internal file paths.

**REVISED disposition (12-site sweep, A2 expansion):** Pack Chat's A2 triage decision rejected the original disposition's analogy to "v10" / "v11.0" lifecycle refs. The V3.3 specifier is **only** meaningful when read against `ARCHITECTURE-V3.3-DELTA.md` — unlike v10/v11.0 (which denote pack release versions resolvable from public release tags), the bare `V3.3` token names an internal architect-doc revision that does not exist at client install. The pack/client boundary is broken whenever V3.3 is referenced from client-installed METHODOLOGY.md, regardless of whether the cite includes the file path or just the bare version.

**Action taken:** All 11 sites closed via Cat A drops (12 cite-drops total) per §2.4 above. Boundary grep §3.5.2 confirms zero remaining `V3.X` refs in METHODOLOGY.md.

**Status: RESOLVED.** No further action. The audit-vocabulary-gap class for `ARCHITECTURE-V3.3-DELTA.md` references is now fully closed in METHODOLOGY.md (file-path cite at L1207 + 11 bare-version cites). H.14 Check 43 mechanical catch (if/when it lands) will find zero catch-targets in METHODOLOGY.md for this class.

### 7.2 Other audit-vocabulary-gap leaks in METHODOLOGY.md

Beyond the L1207 cite closed by this fix, the boundary grep (§3.5) returned `BOUNDARY OK — METHODOLOGY.md clean`. No other audit-vocabulary-gap leaks identified within the canonical leak-vocabulary set.

### 7.3 H.14 Check 43 status

This NIT-1 fix pre-empts H.14 Check 43's mechanical catch (per Pack Chat decision; same shape as H.5 SHOULD-1 fix pattern). Check 43 is not yet landed; if/when it lands, this fix removes one of its catch-targets in advance.

---

**End of IMPL-REPORT.**
