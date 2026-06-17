# PACK-REVIEW — BD-189 / BD-227 user-directed groupings split

**Reviewer:** pack-reviewer (read-only)
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ad8dd784c233467de`
**HEAD:** `b68aa258ed49e6710b8753f5e532788a528651a1` (matches expected)
**Date:** 2026-06-17
**Scope under review:** UNCOMMITTED split of BD-189 (groupings implementation) into a re-scoped flat-file BD-189 + a new tracker BD-227.

---

## VERDICT: CLEAN (ready to patch + commit)

No BLOCKER and no MUST findings. Two SHOULD-grade observations and one NIT, all advisory — none of them block the commit. The content-preservation conclusion is **no loss, no duplication** (detailed map below).

---

## Section 0 — Worktree / boundary preflight (PASS)

| Check | Result |
|---|---|
| `pwd` is the isolated worktree | PASS — `…/.claude/worktrees/agent-ad8dd784c233467de` |
| `git rev-parse HEAD` == expected | PASS — `b68aa258ed49e6710b8753f5e532788a528651a1` |
| Tracked changes (`git diff --name-only`) | `backlog/BD-186.md`, `backlog/BD-189.md`, `backlog/_toc.md` |
| Untracked (`git ls-files --others`) | `backlog/BD-227.md` (NEW) |
| Total touched | EXACTLY 4 backlog files (3 modified + 1 new) — PASS |
| BD-188.md in diff? | NO (`git diff HEAD backlog/BD-188.md` is empty) — PASS |
| BD-192.md in diff? | NO — PASS |
| Any C7 file / any non-`/backlog/` file? | NO — PASS |

Boundary is exactly the user-specified surface. No edits made by the reviewer; TOC was NOT re-run (verified `_toc.md` by reading).

---

## Section 2 — CONTENT-PRESERVATION MAP (the key check)

Original BD-189 at HEAD (`git show HEAD:backlog/BD-189.md`) diffed against {re-scoped BD-189} ∪ {new BD-227}. Every substantive item lands in **exactly one** destination. **No item dropped; no item double-counted.**

| Original BD-189 substantive item | Disposition | Destination | Evidence |
|---|---|---|---|
| Title "groupings implementation (architect/planner/coder cycle)" | Re-titled to flat-file framing | BD-189 | `**BD-189 — Flat-file groupings implementation (architect/planner/coder cycle)**` |
| `Type:` anchor-role line | Kept, re-scoped to FLAT-FILE + split note | BD-189 | line 3 |
| `Status: Open` | Kept | BD-189 | line 4 |
| `Blockers: v11.0 ships` | Replaced with `BD-206` (new sequencing) | BD-189 | line 6 |
| `Unblocks:` per-capability BDs + user-facing feature | Kept, scoped to flat-file; tracker pointer added | BD-189 | line 7 |
| `File/Symbol:` ARCHITECTURE/PLAN deliverables + PRIMARY INPUTS doc list | Kept verbatim (read-only inputs, not impl scope) | BD-189 | lines 8–21 (byte-identical to HEAD except the umbrella-doc names) |
| Description umbrella role ("all 17 capabilities ... defer") | Re-scoped: flat-file legs → BD-189; tracker-projection legs called out as → BD-227 | BD-189 (flat-file legs) + BD-227 (tracker legs) | BD-189 line 22; BD-227 lines 13–17 |
| `feedback_deferred_work_tracking` anchor rationale | Kept | BD-189 | line 24 |
| **Inbound deferral P-31l** (INTAKE fidelity caveat) | Kept (flat-file core item) | BD-189 only | grep: BD-189=1, BD-227=0 |
| **Pipeline (7 steps)** | Kept | BD-189 only | grep: BD-189=1, BD-227=0 |
| **Migration architect/planner/coder pass SEPARATELY scoped** | Kept | BD-189 only | grep: BD-189=1, BD-227=0 |
| **Scope boundary** (#1-#17 + #11; BD-187/BD-188 sibling) | Kept, scoped to flat-file legs; tracker legs → BD-227 | BD-189 (flat) + BD-227 (tracker) | BD-189 line 37; BD-227 line 20 (Out of scope) |
| **No-tracker constraint** (BD-214; tracker-PROJECTION legs BLOCKED + C7 degradation) | Tracker-leg substance MOVED to BD-227; BD-189 retains a pointer-only restatement | BD-227 (substance) + BD-189 (pointer) | BD-189 line 39 (pointer); BD-227 lines 13–17, 20–21 (substance: TrackerProvider sync, per-backend projection, C7 degradation) |
| **C7 graceful-tracker-degradation** design-principle application | MOVED to BD-227 as a first-class block | BD-227 | line 15 ("Graceful degradation (C7 design principle)") |
| **BD-210 LIVE-classification constraint** | Kept | BD-189 only | grep: BD-189=1, BD-227=0 |
| **Resolution** | Kept, flat-file framing | BD-189 only | line 43 |
| **Position** (v11.1+ deferred) | Replaced with v11.0-after-BD-206 + REVERSIBLE + References | BD-189 | line 45 |

**New content originated in BD-227** (not present in original BD-189, but a legitimate projection of the tracker-leg substance the original carried implicitly inside "all 17 capabilities"): the File/Symbol tracker legs (`tracker-provider-*.sh`, ISSUE_TEMPLATE field, flat→tracker migrator tracker leg, validate-pack tracker-side check — lines 8–12), the Symbiosis-with-BD-189 round-trip contract (line 17), the Distinction-from-BD-188 block (line 19), Out-of-scope (line 20), Acceptance criteria (line 21), References (line 22), Position (line 24). These elaborate the tracker half; they do not duplicate any flat-file block in BD-189.

**Conclusion:** Content preservation is CLEAN. The flat-file CORE substance lives only in BD-189; the tracker-PROJECTION substance lives only in BD-227. No substantive item dropped; no item duplicated across both entries. This satisfies `fail-loud-delete-old-source` (tracker content MOVED, not mirrored; BD-189 retains no stale tracker-implementation scope — only forward-pointers to BD-227) and `edit-in-place-not-full-rewrite` (BD-189 was edited in place via targeted line edits — 8 hunks, +17/-14 net per `git diff --stat`, all known blocks intact, no silent section drop).

---

## Section 3 — Entry correctness

### BD-189 (re-scoped) — PASS
- Title reflects flat-file-only; no "v11.1+" in title. PASS (`Flat-file groupings implementation …`).
- `Status: Open`. PASS.
- `Target:` present: v11.0, "sequenced directly after BD-206", REVERSIBLE note present (user direction 2026-06-17, may move out later). PASS — matches the spec verbatim in intent.
- Tracker legs excised → now pointers to BD-227 (10 `tracker` token hits, all either pointers to BD-227, the "no tracker dependency" framing, or the unchanged read-only research-input doc names; NO tracker-implementation scope remains). PASS.
- `_rules.md` conformance: back-pointer comment line 1 correct; bold-header content span; `Type/Status/Description` present (plus admitted extension field `Target:`). PASS.
- Title length `BD-189 — Flat-file groupings implementation (architect/planner/coder cycle)` = 75 codepoints, well under 256 (Check 49 / R-TITLE-1). PASS.

### BD-227 (new) — PASS
- New file present; back-pointer `<!-- per-entry source: /backlog/BD-227.md; contract: /backlog/_rules.md -->`. PASS.
- ID is the next INTEGER after BD-226 (highest existing entry is BD-226; BD-227 is +1). **No letter suffix.** PASS (`no-bd-letter-suffix`).
- `Status: Deferred`. PASS.
- `Target: none — no release version`. PASS.
- Joins the named tracker cluster `{BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}` — byte-identical to the cluster set in BD-216 and BD-188. PASS.
- DISTINCT from BD-188: BD-188.md is unmodified vs HEAD (empty diff); the BD-227 "Distinction from BD-188" block states they are DISTINCT tracker primitives. PASS.
- BD-188↔BD-227 dependency stated as decided-later, NOT invented: "Whether BD-227 … depends on BD-188 is DECIDED LATER — no dependency is asserted here." PASS.
- References point to BD-189 / BD-186 / BD-188 / BD-214 (plus BD-215, BD-204, BD-207, BD-060, BD-216 — all legitimate, accurate cross-refs). PASS — the required four are present and correct.
- `_rules.md` conformance: `Type/Status/Description` present; extension fields (`Target`, `Blockers`, `Unblocks`, `File/Symbol`, `Out of scope`, `Acceptance criteria`, `References`, `Position`) admitted + preserved per the field-faithful contract. PASS.
- Title length `BD-227 — Tracker-only groupings support (the tracker-mode projection of groupings)` = 82 codepoints, under 256. PASS.

### BD-186 — PASS
- Exactly ONE line added (`git diff --numstat` = `1  0`). PASS — the cross-ref/traceability note appended after the `Resolved:` line. Pre-existing wording byte-identical (no other change). Confirms the coder's self-reverted over-reach left no residue.

---

## Section 4 — TOC + gate + boundary

### `_toc.md` (read, not regenerated) — PASS
- BD-189 under **Open**, line 20, with UPDATED title; ascending position between BD-187 and BD-192 — correct. PASS.
- BD-227 under **Deferred**, line 57, after BD-220 (the prior last numeric in Deferred) — correct ascending placement. PASS.
- Format consistent with the generated convention (`- [BD-NNN](./BD-NNN.md) — Title`); DO-NOT-EDIT-BY-HAND banner intact. No stale/missing/misplaced entry. PASS.

### validate-pack — PASS
- `python3 scripts/validate-pack.py` → **EXIT 0** ("PASSED — all checks clean").
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **EXIT 0** ("PASSED — all checks clean"). DEEP exercises entry-faithfulness + title-limit. PASS.

### Boundary — PASS
`git diff --name-only` ∪ untracked = exactly `{BD-186.md (mod), BD-189.md (mod), _toc.md (mod), BD-227.md (new)}`. No C7 file, no non-`/backlog/` file, no BD-188.md, no BD-192.md.

---

## Findings (advisory only — none block the commit)

### SHOULD-1 — BD-227 References list is broader than the prompt's named set
**File:** `backlog/BD-227.md:22` (References) and line 6/24 (Blockers/Position cite BD-215, BD-204, BD-207).
The prompt named BD-189/BD-186/BD-188/BD-214 as the expected reference set. BD-227's References additionally cite BD-215, BD-204, BD-207, BD-060, BD-216. These extras are all accurate and well-justified (BD-215 = resumption gate; BD-204/BD-207 = tracker machinery this rides on; BD-060 = TrackerProvider; BD-216 = sibling tracker-split precedent the entry explicitly mirrors). This is correct, complete cross-referencing that matches the BD-216 sibling-split precedent — not a defect. Flagged only so the triager is aware the reference set exceeds the four named in the spec by design.
**Fix recipe:** None needed. If strict minimalism is desired, the extras could be trimmed, but doing so would *weaken* cross-ref integrity and diverge from the BD-216 precedent — recommend KEEP.

### SHOULD-2 — BD-189 retains the full read-only research-input doc list (which includes tracker-research docs)
**File:** `backlog/BD-189.md:15-19` (`File/Symbol` → PRIMARY INPUTS).
The flat-file-only BD-189 still lists `RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`, `IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md`, and the EXTERNAL-RESEARCH tracker-pattern sections among its read-only inputs. These are *research inputs*, not implementation scope, and were present in the original BD-189 — keeping them is consistent with `edit-in-place-not-full-rewrite` (no silent drop). It is defensible that the flat-file architect still benefits from per-backend grouping-primitive research when designing the canonical grouping shape that BD-227 must later project. Not a content-preservation violation (these are not tracker-*implementation* scope). Flagged only because a stricter reading might argue the tracker-research docs belong solely under BD-227's input set.
**Fix recipe:** None required. If the user wants the strictest separation, the two tracker-research doc lines could be cross-referenced from BD-227's File/Symbol instead — but the current placement is acceptable and avoids dropping a known-useful input. Recommend KEEP as-is.

### NIT-1 — Minor grammar in two split-note sentences ("this split from")
**File:** `backlog/BD-189.md:45` ("BD-227 (the tracker-projection half this split from)") and `backlog/BD-227.md:2,22` ("Split out of BD-189 … this split from").
Reads slightly awkwardly; "that this was split from" / "split out of" would be cleaner. Purely cosmetic; meaning is unambiguous.
**Fix recipe:** Optional — reword to "the tracker-projection half split out from this BD" / "the FLAT-FILE part this was split from." Not worth a fix-coder cycle on its own.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | No state-changing git verb run. Commands used: `git rev-parse`, `git status --short`, `git diff`, `git show`, `git ls-files --others`, `git diff --numstat`, `ls`, `python3 scripts/validate-pack.py`. No `add/commit/push/mv/rm/restore/checkout`; TOC regen NOT run (verified `_toc.md` by Read). No file edits made (single Write = this report at `/tmp/handoff-bd189-split/`). | COMPLIANT |
| **no-bd-letter-suffix** | `ls backlog/ \| sort -t- -k2 -n \| tail` → highest existing = `BD-226.md`; new entry = `BD-227.md` (next integer, no suffix). Header `**BD-227 — …**` is canonical (`BD-\d+`, em-dash, no pre-em-dash parenthetical, no letter). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | BD-189 `git diff --stat` = `27 lines, +17/-14` across 8 hunks (targeted edits, not a wholesale rewrite); all original substantive blocks (Pipeline, P-31l, Migration-scoped, BD-210, Resolution, File/Symbol inputs) verified present by grep. BD-186 `git diff --numstat` = `1  0` (single appended line, pre-existing wording byte-identical). No silent section drop detected. | COMPLIANT |
| **fail-loud-delete-old-source** | Tracker substance MOVED to BD-227 (TrackerProvider sync, per-backend projection, C7 degradation — BD-227 lines 13–17, 20–21), NOT mirrored. BD-189's tracker mentions (10 hits) are all forward-pointers to BD-227 or "no tracker dependency" framing or unchanged read-only research-input names — no stale tracker-implementation scope retained. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly the 4-file split. `git diff --name-only` = `{BD-186, BD-189, _toc.md}` + untracked `BD-227.md`; no C7 file, no non-`/backlog/` file, no BD-188.md, no BD-192.md. Out-of-scope items surfaced (SHOULD-1 reference breadth, SHOULD-2 input-list breadth) as advisory, not chased/edited. | COMPLIANT |
| **rules-applied-verification-block** | This block present with rule name + quoted evidence + COMPLIANT conclusion per rule; no empty-evidence rows; no AMBIGUOUS terminal states. | COMPLIANT |
