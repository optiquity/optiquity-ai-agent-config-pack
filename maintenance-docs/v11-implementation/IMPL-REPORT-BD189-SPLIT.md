# IMPL-REPORT — BD-189 split (flat-file BD-189 / tracker BD-227)

**Task:** User-directed backlog split — split the groupings-implementation BD
into a flat-file part (keeps BD-189) and a new tracker part (BD-227).
**Scope:** `pack-chat-only` (only `/backlog/` files), scoped into this coder by
the prompt (supported path for MAJOR pack-chat-only work).
**Regime:** ISOLATED WORKTREE (new live model). Edits left UNCOMMITTED. No patch
emitted (per Section 0) — awaiting post-review SendMessage to produce the patch.

## Worktree / regime (Section 0)

| Item | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ad8dd784c233467de` |
| Worktree HEAD | `b68aa258ed49e6710b8753f5e532788a528651a1` |
| `v11-dev` HEAD | `b68aa258ed49e6710b8753f5e532788a528651a1` (EXACT match — bases at v11-dev HEAD) |
| Branch (worktree) | `worktree-agent-ad8dd784c233467de` (auto-generated isolated-worktree branch; expected) |
| Worktree path | `.claude/worktrees/agent-…` — CONFIRMED isolated |
| `git worktree list` | confirms this worktree `locked` at `b68aa25 [worktree-agent-ad8dd784c233467de]` |

Pre-flight gate (Section 2B): highest existing BD = **BD-226**; `backlog/BD-227.md`
did **not** exist before this task → next-integer = BD-227 confirmed (no STOP).

## Pre-flight reads (Section 1 — read IN FULL)

`CLAUDE.md ## Pack memory`; `backlog/_rules.md`; `backlog/BD-189.md`;
`backlog/BD-186.md`; `backlog/BD-188.md`; `backlog/BD-216.md`; `backlog/BD-206.md`;
memory files `feedback_no_bd_letter_suffix.md`,
`feedback_edit_in_place_not_full_rewrite.md`, `feedback_fail_loud_delete_old_source.md`.

## Files changed inventory

| Path | Change type |
|---|---|
| `backlog/BD-189.md` | modified (re-scoped flat-file-only, v11.0) |
| `backlog/BD-227.md` | **new** (tracker-only groupings support, Deferred) |
| `backlog/BD-186.md` | modified (ONE traceability Note line appended) |
| `backlog/_toc.md` | regenerated (derived; not hand-edited) |

`git diff --name-only` (tracked) → `backlog/BD-186.md`, `backlog/BD-189.md`,
`backlog/_toc.md`. New file `backlog/BD-227.md` appears under `git status --short`
as `?? backlog/BD-227.md` (untracked, so absent from `diff --name-only` by design).
Net = exactly the 4 expected files. NO other file. NO C7 file.

---

## (A) BD-189 — new header (re-scoped flat-file-only)

| Field | Before | After |
|---|---|---|
| Title | `v11.1+ groupings implementation (architect/planner/coder cycle)` | `Flat-file groupings implementation (architect/planner/coder cycle)` |
| Status | `Open` | `Open` (unchanged) |
| Target | *(none — body said "v11.1+ deferred")* | `v11.0 — sequenced directly after BD-206 … REVERSIBLE (user direction 2026-06-17)` |
| Position | `v11.1+ deferred — EXECUTION-PLAN §1.6 Group 4` | `v11.0 — sequenced directly after BD-206 … REVERSIBLE … References: BD-227, BD-206, BD-186, BD-214` |

Targeted in-place edits (no full rewrite): header block (title/Type/Target/
Blockers/Unblocks), Description first paragraph, Pipeline step 6, Scope-boundary
paragraph, No-tracker-constraint paragraph, Resolution paragraph, Position
paragraph, plus two stale-v11.1-framing remnant fixes (Inbound-deferral note +
BD-210-LIVE-classification note). All unrelated flat-file content (File/Symbol
input list, BD-195 inbound-deferral substance, BD-210 liveness caveat, pipeline
steps 1-5+7) preserved verbatim except the targeted framing reconciliation.

`Title` codepoint measurement (Check 49 / R-TITLE-1, limit 256):
`BD-189: Flat-file groupings implementation (architect/planner/coder cycle)` =
**74 codepoints** → OK.

## (B) BD-227 — new entry (tracker-only groupings support)

Full header:
- Backpointer: `<!-- per-entry source: /backlog/BD-227.md; contract: /backlog/_rules.md -->`
- Header: `**BD-227 — Tracker-only groupings support (the tracker-mode projection of groupings)**` (NO letter suffix; next integer after BD-226)
- `Type: feat — STRUCTURAL. The TRACKER counterpart of BD-189 … Split out of BD-189 on 2026-06-17 (user-directed split)`
- `Status: Deferred`
- `Target: none — no release version; lands with the tracker-resumption release (the deferred cluster {BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}; BD-227 joins it).` (mirrors BD-216 conventions)
- `Blockers: tracker resumption (BD-214 … gated on BD-215 first); BD-189 (flat-file grouping shape locked + deterministically serializable first); BD-204 + BD-207 (tracker machinery, deferred).`
- `Unblocks:` tracker-mode users express groupings as tracker-native primitives, degrading gracefully.
- `File/Symbol (tracker legs — deferred):` TrackerProvider projection; form-family field/label (if architect requires); flat→tracker migrator leg; validate-pack tracker-side check.
- `References: BD-189 … BD-186 … BD-188 (related primitive; DISTINCT; deps TBD) … BD-214 … BD-215 … BD-204 + BD-207 … BD-060 … BD-216.`
- `Resolved: n/a`
- `Position:` deferred — lands with the tracker-resumption cluster.

Body summary: carries the tracker-PROJECTION legs that split out of BD-189 —
tracker-native grouping primitives projecting BD-189's flat-file grouping shape
into the tracker; C7 graceful-degradation paragraph; HARD symbiosis-with-BD-189
paragraph (round-trip faithfulness, BD-215 readable==tracker property); DISTINCT-
from-BD-188 paragraph that EXPLICITLY states "Whether BD-227 depends on BD-188 is
DECIDED LATER — no dependency is asserted here" and "BD-188 is left untouched by
this split"; Out-of-scope; Acceptance criteria.

`Title` codepoint measurement (limit 256):
`BD-227: Tracker-only groupings support (the tracker-mode projection of groupings)` =
**81 codepoints** → OK.

Distinct-from-BD-188 (Section 2B requirement): BD-188 left UNTOUCHED (verified —
empty `git status --short backlog/BD-188.md`); BD-227 states the BD-188↔BD-227
dependency is decided later (no invented dependency).

## (C) BD-186 cross-ref note (ONE line)

BD-186's original `Resolved:` line restored byte-identical (a transient edit that
softened "v11.1+ groupings architect" was reverted to keep BD-186 otherwise
unchanged). Exactly ONE new line appended after `Resolved:`:

```
Note (2026-06-17, user-directed split): the groupings IMPLEMENTATION was split into a flat-file half (BD-189, v11.0 — sequenced after BD-206) and a tracker half (BD-227 — Deferred, lands with the tracker-resumption cluster). Traceability only; this Resolved entry is otherwise unchanged.
```

`git diff --stat` confirms `backlog/BD-186.md | 1 +` (one insertion, zero
deletions) — BD-186 otherwise unchanged.

## (D) _toc.md regeneration

Command (run from the script's own dir per the sourcing gotcha):
```
( cd <worktree>/scripts/lib/per-entry && source ./toc-regenerate.sh \
  && per_entry_regenerate_toc pack-backlog <worktree>/backlog )   → EXIT=0
```
Result (post-regen grep):
- line 20 (under `## Open`): `- [BD-189](./BD-189.md) — Flat-file groupings implementation (architect/planner/coder cycle)` ← updated title
- line 57 (under `## Deferred`): `- [BD-227](./BD-227.md) — Tracker-only groupings support (the tracker-mode projection of groupings)` ← new entry, correct status section
`_toc.md` was NOT hand-edited (derived index; regenerated via the script).

---

## Content-preservation map (Section 3.1 — nothing dropped / nothing duplicated)

ORIGINAL BD-189 substantive items → disposition:

| Original BD-189 item | Disposition |
|---|---|
| Umbrella forward-pointing-anchor role (`feedback_deferred_work_tracking`) | KEPT in BD-189 (re-scoped to flat-file core) |
| File/Symbol architect/planner deliverables + PRIMARY INPUTS list | KEPT verbatim in BD-189 |
| BD-195 inbound deferral (P-31l INTAKE fidelity caveat) | KEPT in BD-189 (flat-file quality item; v11.1 framing dropped) |
| Pipeline steps 1-7 (architect→planner→coder→migration→release) | KEPT in BD-189 (flat-file pipeline) |
| Scope boundary capabilities #1-#17 + #11 | KEPT in BD-189, limited to FLAT-FILE legs of each capability |
| BD-187 / BD-188 sibling-parking-lot non-subsumption | KEPT in BD-189 |
| BD-210 LIVE-classification input-liveness caveat | KEPT in BD-189 |
| Resolution criteria | KEPT in BD-189 (flat-file children) |
| **No-tracker-constraint: tracker-PROJECTION legs (tracker-native grouping primitives)** | **MOVED to BD-227** (BD-189 now POINTS to BD-227, retains no tracker impl scope) |
| **Tracker-native grouping primitive implementation surfaces** (TrackerProvider projection, form-family, migrator leg, tracker validate-pack check) | **MOVED to BD-227** File/Symbol (these are NEW concrete surfaces the tracker half owns) |
| C7 graceful-tracker-degradation applied to tracker grouping primitives | **MOVED to BD-227** (C7 paragraph) |

Verification method: (1) grep of BD-189 for `tracker-projection|tracker-native|
tracker projection` → every hit is a POINTER ("split out to BD-227" / "= BD-227"
/ "NOT in this BD"), never a retained implementation directive (fail-loud — no
stale tracker scope left in BD-189); (2) grep of BD-227 for `tracker-native
grouping primitives` → the legs live there; (3) no item appears as an active
directive in BOTH entries (no duplication). Flat-file core is wholly in BD-189;
tracker projection is wholly in BD-227.

## Verification results (Section 3)

| # | Check | Result |
|---|---|---|
| 1 | Content-preservation (map above) | PASS — every original item in exactly one of BD-189/BD-227; nothing dropped/duplicated |
| 2 | Entry well-formedness vs `_rules.md` | PASS — BD-227 backpointer + canonical `**BD-227 — …**` header + Type/Status/Blockers/Unblocks/Description/References/Resolved/Position all present; BD-189/BD-186 conform |
| 2 | Title ≤256 codepoints (Check 49 / R-TITLE-1) | PASS — `BD-189: …` = 74; `BD-227: …` = 81 |
| 3 | `validate-pack.py` default | PASS — exit 0; last line `PASSED — all checks clean` |
| 3 | `PACK_VALIDATE_DEEP=1 validate-pack.py` | PASS — exit 0; last line `PASSED — all checks clean` |
| 4 | `_toc.md` regenerated + correct | PASS — BD-227 under Deferred (line 57); BD-189 updated title under Open (line 20) |
| 5 | `git diff --name-only` = exactly 4 files | PASS — BD-186 + BD-189 + _toc tracked; BD-227 new (`??`); no other; no C7 file |

Captured command outputs:
- `DEFAULT_EXIT=0` / `PACKED — all checks clean`
- `DEEP_EXIT=0` / `PASSED — all checks clean`
- `git status --short`:
  ```
   M backlog/BD-186.md
   M backlog/BD-189.md
   M backlog/_toc.md
  ?? backlog/BD-227.md
  ```

## Plan deviations

Zero functional deviations. One self-corrected over-reach during execution:
the BD-186 edit transiently softened "v11.1+ groupings architect" → "the
groupings architect" in the existing Resolved line; reverted immediately to honor
"do NOT otherwise edit BD-186 / ONE line added." Net BD-186 change = exactly +1
line (confirmed by `--stat`).

## New POQs introduced

None. The BD-188↔BD-227 dependency is explicitly left "decided later" per the
prompt (Section 2B) — surfaced as an open question inside the BD-227 body, not
resolved here, and not opened as a new BD.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| (A) BD-189 re-scoped flat-file-only, title updated, v11.1+ framing dropped | PASS |
| (A) BD-189 Target v11.0, sequenced after BD-206, REVERSIBLE noted | PASS |
| (A) BD-189 tracker legs removed (pointers to BD-227 only) | PASS |
| (A) BD-189 no-tracker-constraint paragraph updated (core=this BD; projection=BD-227) | PASS |
| (B) BD-227 authored, next integer, NO letter suffix | PASS |
| (B) BD-227 Status Deferred / Target none / cluster membership (mirrors BD-216) | PASS |
| (B) BD-227 DISTINCT from BD-188; deps decided-later; BD-188 untouched | PASS |
| (C) BD-186 ONE traceability line; otherwise unchanged | PASS |
| (D) _toc.md regenerated via script (not hand-edited); BD-227 + BD-189 title correct | PASS |
| validate-pack default + DEEP exit 0 | PASS |
| Titles ≤256 codepoints | PASS |
| diff scope = exactly 4 backlog files; no C7 file; no non-/backlog/ file | PASS |
| Edits left UNCOMMITTED; no state-changing git verb; no patch emitted | PASS |

## Full content of new file (BD-227.md) — for re-apply without re-derivation

```
<!-- per-entry source: /backlog/BD-227.md; contract: /backlog/_rules.md -->
**BD-227 — Tracker-only groupings support (the tracker-mode projection of groupings)**
Type: feat — STRUCTURAL. The TRACKER counterpart of BD-189: the tracker-mode projection of the groupings feature (tracker-native grouping primitives). Split out of BD-189 on 2026-06-17 (user-directed split) so the flat-file half (BD-189) can ship in v11.0 while the tracker half defers with the rest of the deferred tracker cluster.
Status: Deferred
Target: none — no release version; lands with the tracker-resumption release (the deferred cluster {BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}; BD-227 joins it). (user-directed split 2026-06-17; cluster semantic per BD-214 Track-2 US-5.)
Blockers: tracker resumption (tracker (GH Issues) integration is deferred indefinitely per BD-214 — the ability to flip to tracker mode is BLOCKED on both surfaces, gated on the entry-format redesign BD-215 landing first); BD-189 (the flat-file groupings core — the canonical grouping shape this projects into the tracker MUST be locked + deterministically serializable first); BD-204 + BD-207 (the pack-side and project-side tracker machinery this rides on, both deferred). No work begins until the tracker cluster resumes.
Unblocks: tracker-mode users can express groupings of phases as tracker-native grouping primitives (projecting the BD-189 flat-file grouping shape into the tracker), degrading gracefully on backends that lack the native primitive.
File/Symbol (tracker legs — deferred):
  - `scripts/lib/tracker-provider-*.sh` (BD-060 TrackerProvider) — projection of grouping membership into tracker-native grouping primitives (per the #11 capability matrix, per-backend), forward (flat→tracker) and reverse (tracker→flat).
  - `project-template/.github/ISSUE_TEMPLATE/*.yml` — any grouping-membership field / label namespace the form family needs to carry grouping projection (per the BD-068 form-family rules + the BD-069 `template_version` delta), if the architect determines one is required.
  - any v11.x flat→tracker migrator — initialize the tracker-native grouping projection from the current flat-file grouping shape (the tracker leg of the migration; the flat-file pass-through is BD-189's).
  - `scripts/validate-pack.py` — tracker-side check(s) enforcing grouping-projection invariants in tracker mode (architect determines specifics; complements BD-189's flat-file invariant check).
Description: The tracker-PROJECTION legs of the groupings feature, split out of BD-189 (the flat-file core). BD-189 owns the canonical, deterministically-serializable flat-file grouping shape + the user-facing flat-file groupings feature. BD-227 is the TRACKER half: it projects that same grouping shape into tracker-native grouping primitives (per backend, per the REQUIREMENTS-GROUPINGS-V11.md #11 capability matrix), syncs grouping membership bi-directionally via the BD-060 TrackerProvider, and gives tracker mode a native grouping mechanism that does not depend on a flat-file artifact.

  **Graceful degradation (C7 design principle):** backends that lack a native grouping primitive degrade gracefully per BD-186's C7 graceful-tracker-degradation design principle (emulation OR explicit unsupported declaration) rather than failing — the same property BD-188/BD-216 apply to their tracker primitives.

  **Symbiosis with BD-189 (HARD — interdependent, must be elegant not forced):** BD-227's tracker representation MUST round-trip BD-189's flat-file grouping shape faithfully. BD-189 owns the grouping shape + its flat-file serialization; BD-227 owns the tracker projection of that shape. Neither redefines the other's half; the tracker form is a faithful projection of the flat-file canonical form (readable form == tracker form, the BD-215 property).

  **Distinction from BD-188 (DISTINCT — deps decided later):** BD-188 (Phase-Iteration sprint view) projects phases as Iteration values on a single all-phases tracker Project (a sprint/temporal view). BD-227 projects GROUPINGS (purpose/theme grouping of phases) as tracker-native grouping primitives. They are DISTINCT tracker primitives; both can coexist on capable trackers (one phase can live in multiple Projects with different Project semantics per V11.1 §8 dedup). Whether BD-227 (Part-2 grouping projection) depends on BD-188 is DECIDED LATER — no dependency is asserted here. BD-188 is left untouched by this split.
Out of scope: the flat-file groupings core implementation + the user-facing flat-file groupings feature (BD-189, v11.0); the canonical entry-format redesign (BD-215); any tracker migration EXECUTION (BD-204/BD-207 — this BD only supplies the grouping projection those migrations carry); the Phase-as-Iteration sprint view (BD-188); tracker backends' specific per-backend designs beyond the C7 graceful-degradation contract (architect determines specifics at scheduling time).
Acceptance criteria: tracker mode expresses groupings of phases as tracker-native grouping primitives; grouping membership round-trips faithfully through the TrackerProvider (forward + reverse); the BD-189 flat-file grouping shape projects into the tracker without a flat-file artifact serving as the tracker-mode SSOT; backends lacking a native grouping primitive degrade gracefully per C7; validate-pack green incl. the tracker-side invariant check.
References: BD-189 (the FLAT-FILE part this split from — the canonical grouping shape + flat-file feature this projects into the tracker); BD-186 (Resolved — groupings requirements + design principles incl. C7 graceful degradation); BD-188 (related tracker grouping primitive — Phase-as-Iteration sprint view; DISTINCT from this BD; deps TBD); BD-214 (no-tracker constraint — tracker integration deferred indefinitely); BD-215 (canonical entry format — resumption gated on it); BD-204 + BD-207 (the deferred tracker machinery this rides on); BD-060 (TrackerProvider abstraction); BD-216 (the tracker legs of BD-185 — adjacent tracker-cluster split, same pattern).
Resolved: n/a
Position: deferred — no release version; lands with the tracker-resumption release (the deferred cluster {BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}; BD-227 joins it). Blocked on tracker resumption (BD-214) + BD-189 (flat-file grouping shape locked + deterministically serializable) + BD-215 (canonical format) + BD-204/BD-207 (tracker machinery). The tracker half of BD-189's split (user-directed 2026-06-17).
```

## Awaiting

Edits are UNCOMMITTED in the isolated worktree. No patch emitted (Section 0). I
await the post-review SendMessage to produce the patch after a reviewer confirms
CLEAN. The orchestrator applies the reviewed-clean patch + commits with human
approval.

---

## Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit | All edits via Write/Edit only. Read-only git only run: `git rev-parse`, `git status --short`, `git diff --name-only/--stat`, `git worktree list`. No `git add/commit/apply/checkout/restore` issued. No patch emitted. | COMPLIANT |
| per-action-approval-sub-agents | Pre-flight gate honored: highest BD measured = `BD-226`; `ls backlog/BD-227.md` → "No such file or directory" → next-integer BD-227 confirmed; no STOP condition triggered. No destructive op run on own authority. | COMPLIANT |
| preflight-stop-means-stop | Single PREFLIGHT line emitted only AFTER Section 3 all PASS (`DEFAULT_EXIT=0`, `DEEP_EXIT=0`, content-preserved, 4-file diff). No stop/halt message received. | COMPLIANT |
| no-bd-letter-suffix | New entry header `**BD-227 — …**` — next INTEGER after BD-226, no letter suffix. Filename `backlog/BD-227.md` matches `^BD-\d+\.md$`. | COMPLIANT |
| edit-in-place-not-full-rewrite | BD-189 + BD-186 edited via targeted `Edit` blocks (header, specific paragraphs), NOT full-file Write. Re-read BD-189 after edits (Read at line-state) to confirm no unrelated section dropped. `git diff --stat`: `BD-189.md 27 ++/--`, `BD-186.md 1 +`. | COMPLIANT |
| fail-loud-delete-old-source | Tracker legs MOVED to BD-227, not duplicated; grep of BD-189 for tracker-projection terms → every hit is a POINTER to BD-227 (no retained tracker impl scope) — BD-189 carries no stale tracker-implementation directive. | COMPLIANT |
| per-entry-toc-regen | `_toc.md` regenerated via `per_entry_regenerate_toc pack-backlog` sourced from `scripts/lib/per-entry/` (EXIT=0); never hand-edited. Post-regen grep confirms BD-227 (line 57, Deferred) + BD-189 title (line 20, Open). | COMPLIANT |
| rules-applied-verification-block | This block; per-rule evidence + conclusion; worktree-isolation behavior (Section 0) recorded: isolated worktree at `.claude/worktrees/agent-ad8dd784c233467de`, HEAD == v11-dev HEAD `b68aa258…`, edits uncommitted, no patch (awaiting post-review SendMessage). | COMPLIANT |
