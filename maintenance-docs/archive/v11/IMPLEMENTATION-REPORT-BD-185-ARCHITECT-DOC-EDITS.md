# IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md

**Authored by:** pack-coder (architect-doc-edits pass)
**Date:** 2026-05-25 (US/Pacific)
**Branch:** v11-dev
**Repo HEAD at start of work:** 4d1f9e55a895a64e0304b8d13bd0c3b020c46363
**Repo HEAD at end of work:** 4d1f9e55a895a64e0304b8d13bd0c3b020c46363 (no commits made — agent does not commit)
**Source BD:** BD-185 — Phase Parts hierarchy + tracker-mode execution ordering
**Parent decision session:** Pack Chat decision-review session 2026-05-25 (sessionId `f6d6104f-9268-42ff-90cf-ac8ae35433e3`)
**Target doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`

---

## §1 — Scope

This implementation applies 20 user-approved edits to `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` to land all 14 decisions resolved at the Pack Chat decision-review session 2026-05-25. Edits are grouped across three categories:

- **Group A — Lock-ins (6 edits, A1-A6):** Strike POQ defer language; confirm architect's original proposals as locked decisions; replace §12 POQs table with resolution reference.
- **Group B — New design content (10 edits, B1-B10):** Add substantive design content for user-driven decisions (D2 no-collapse, D3 no empty Parts, D4 supersede-only, D5 cancelled state, D6 verification timing, D7 SSOT pattern, D8 structured warning, D9 Forgejo/Gitea v11.1+ scoping, D10 gh api graphql + tool-requirement, D11 new library file, D12 LAZY backfill, D13 name-collision handling, D14 append-to-end).
- **Group C — Cleanups + typos (4 edits, C1-C4):** Typo fix; DEPENDENCIES.md cross-reference; follow-on items section; comprehensive §1.4 Decision log.

Source decisions: D1-D14 (14 decisions; INV-7 breach + 10 POQs + 3 derivative design decisions).

No source code touched — doc-only pass.

---

## §2 — Inputs read

| # | Path | HEAD SHA | Sections used |
|---|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | 4d1f9e5 | Full (1036 lines pre-edit; 1209 lines post-edit) — the target doc |
| 2 | `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | a5c7e62 | (referenced; not edited) Architect's fact base for §12 observations and §13 worksheet citations |
| 3 | `pack-ops/BACKLOG.md` BD-185 entry | 4d1f9e5 | SC1-SC8 + C-1..C-5 grammar reference (referenced; not edited) |
| 4 | `supporting-docs/METHODOLOGY.md` | 4d1f9e5 | Multi-part phases section name + structure (referenced for §11.1 doc-surface guidance; not edited in this pass) |

**HEAD SHA at start of work:** 4d1f9e55a895a64e0304b8d13bd0c3b020c46363
**HEAD SHA at end of work:** 4d1f9e55a895a64e0304b8d13bd0c3b020c46363 (no commits — agent does not commit)

---

## §3 — Group A edits applied (Lock-ins; strike POQ defer language)

### §3.A1 — INV-7 breach confirmation (D1)

- **Section:** §4.3 — Form-family extension (SC6 + INV-7 + INV-8)
- **Before:** "Add `phase-part-skeleton` as the 5th `wi-type` option" with 3-point defense already documented. Forward-references existed to POQ-style framing in the §12 table.
- **After:** Same locked decision; the §12 POQ table replaced with §12 RESOLVED + §12a Follow-on items per A6. Per-line POQ references in §10.1 (Check 35) updated from "if architect carves the lib" → "per D11". §10.1 line 685 changed from "Extended OR paralleled by Check 35.5: enforces phase-part-v11.1 SCHEMA + library invariants (parser/emitter at new `tracker-phase-part.sh` if architect carves the lib)" → "Paralleled by Check 35.5: enforces phase-part-v11.1 SCHEMA + library invariants (parser/emitter at new `tracker-phase-part.sh` per D11)".
- **Source decision:** D1.

### §3.A2 — `gh api graphql` routing lock-in (D10)

- **Section:** §5.1 + §8.2 + §7 ops table
- **Before:** §8.2 line 654 carried `POQ-6` reference: "Issue Fields requires recent `gh` (or `gh api graphql` fallback) — flagged at `provider_capabilities` runtime check; pack tolerates older gh by routing through `gh api graphql` for field read/write | POQ-6". §7 `provider_set_field` row had `verify primary source — POQ-2` framing.
- **After:** §8.2 line reads "Issue Fields read/write routes through `gh api graphql` (avoids `gh` CLI version-pinning) — locked per D10 | §5.1". §7 `provider_set_field` row reads "primary-source verification at implementation-time per D6". §5.1 carries the routing strategy as locked (already documented in body text).
- **Source decision:** D10 (routing); D6 (verify-at-implementation-time).

### §3.A3 — NEW `scripts/lib/tracker-phase-part.sh` confirmation (D11)

- **Section:** §10.1 (CI check refs) + §14.2 (files touched) + §14.9 (test files)
- **Before:** POQ-7 framing — "CREATE (per POQ-7)" with "Parser/emitter + state taxonomy for Parts (parallels `tracker-phase-task.sh`)"; Check 35 noted "if architect carves the lib".
- **After:** All references changed to "CREATE (per D11)" and "per D11" — locked; new file confirmed parallel to `tracker-phase-task.sh`.
- **Source decision:** D11.

### §3.A4 — LAZY `pack-id-v2` backfill (D12)

- **Section:** §4.1 (last paragraph re Migration step)
- **Before:** "Migration step (§6) backfills the `pack-id-v2` marker on existing tasks during a v11.0 → v11.1 forward sweep (gated; opt-in per project)."
- **After:** "Migration step (§6) backfills the `pack-id-v2` marker on existing tasks LAZILY per D12 — only tasks in phases that undergo Part expansion receive the v2 marker. Most v11.0 tasks remain v1-only (`pack-id: phase-N.M`); the v1 marker continues to resolve in all parsers."
- **Source decision:** D12.

### §3.A5 — New phase appends to END of sub-issue priority order (D14)

- **Section:** §5.2 — Fallback mechanism
- **Before:** Section did not explicitly state behavior for new phases added mid-development to the fallback path. POQ-10 framing in §12 table only.
- **After:** Inserted new "Mid-development phase position (per D14):" sub-paragraph in §5.2 — "When a new phase is added mid-development to a phase-order-root fallback project, the new phase appears at the END of the sub-issue priority order by default. This matches GitHub's default sub-issue create behavior..."
- **Source decision:** D14.

### §3.A6 — §12 POQs section REPLACED with resolution reference (all 10 POQs)

- **Section:** §12 — Open architect questions (POQs)
- **Before:** 10-row POQ table with "Default" and "User decision needed" columns.
- **After:** Section retitled "§12 — Open architect questions (POQs) — RESOLVED". Body: "ALL 10 POQs RESOLVED 2026-05-25 per Pack Chat decision-review session. See §1.4 Decision log (NEW) for the full decision record. The original POQ table is preserved in git history for audit purposes." Sub-section §12a added carrying the 3 follow-on items (C3 cleanup).
- **Source decision:** All 10 POQs → D2/D6/D7/D8/D9/D10/D11/D12/D13/D14 resolved.

---

## §4 — Group B edits applied (Substantive new design content)

### §4.B1 — §4.7 Part collapse REJECTED as anti-pattern (D2)

- **Section:** §4.7 — Phase task migration to Part membership; reverse-operation paragraph
- **Before:** "Reverse operation (Part collapse) — DEFERRED per OQ-1: If a phase's Parts are later collapsed back into a single chunk, the design preserves Part history (Parts stay in tracker as `status:deferred` per §4.4) rather than deleting Part entities. Active task re-parentage moves back to phase-epic-direct-children. The reverse operation is rare and DEFERRED to a follow-up architect pass (POQ-1 in §12); BD-185 ships the forward expansion only."
- **After:** Verbatim wording from prompt applied — "**Reverse operation (Part collapse) — REJECTED as anti-pattern per user direction 2026-05-25.**" + rationale + operational paths (deferred status, natural close, supersession via `pack task supersede`).
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text without redrafting.
- **Source decision:** D2.

### §4.B2 — §4.7 NEW Part-creation rule (D3 — no empty Parts)

- **Section:** §4.7 — added after the no-collapse paragraph
- **Before:** No Part-creation empty-Part rejection rule.
- **After:** Verbatim wording from prompt applied — "**Part creation rule (D3 — no empty Parts):** Every Part must contain at least one task at creation time. The `pack phase split` verb enforces this..." + rationale + 4-step operational flow + NEW Check 44 (or next available) for CI extension.
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D3.

### §4.B3 — §4.7 Supersede-only rule for mid-life re-parenting (D4)

- **Section:** §4.7 — added after Part-creation rule
- **Before:** No explicit forbidding of mid-life task re-parenting. Step 3 of expansion ("Verb emits Parts + re-parents tasks") was ambiguous about whether mid-life moves were allowed.
- **After:** Verbatim wording from prompt applied — clarifying paragraph "**Initial Part assignment (allowed; one-time at phase split):**..." vs "**Mid-life re-parenting (FORBIDDEN per user direction 2026-05-25):**..." + Task immutability rule + "There is NO `pack task reparent` verb..." Also updated §4.4 lifecycle invariant to reference D4 / D2 / D3. Also updated §4.4 `deferred` row note from "tasks may be re-parented" to "member tasks stay assigned (re-parenting forbidden per D4 — see §4.7 supersede-only rule)" to remove the conflict.
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D4.

### §4.B4 — NEW §4.8 `pack task supersede` verb specification (D4)

- **Section:** New §4.8 — added at end of §4 (immediately before §5)
- **Before:** No `pack task supersede` verb spec existed; verbs only at §4.5 (Part creation) and §5.5 (reorder).
- **After:** Verbatim wording from prompt applied — full verb specification with signature, semantics (old task transitions to `status:superseded-by:Phase-N.Part-x.Task-M`; new task created with `pack-id` + `pack-id-v2` per D12), cross-reference behavior, and explicit "No `pack task reparent` verb exists" guidance. The "§10" placement reference in the prompt was interpreted as the natural verb section; I placed it at §4.8 alongside §4.5 Part creation verb. Cross-references in §4.7 supersede-related sentences updated to point to §4.8 (was "in §10" → "in §4.8").
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D4.

### §4.B5 — NEW §4.4a Phase task state taxonomy (D5 — `cancelled` state added)

- **Section:** New §4.4a inserted between §4.4 (Part state taxonomy) and §4.5 (Part creation verb)
- **Before:** Task state taxonomy was not consolidated as a section in this architect doc (existed implicitly via METHODOLOGY); 6-state taxonomy (pending / in-progress / done / deferred / merged-into / superseded-by).
- **After:** Verbatim wording from prompt applied — extended 7-state taxonomy table with `cancelled` (❌ marker, `state_reason:not_planned`, "decided not to do; permanent; not replaced"). Reverse-emit grammar extension noted (`#### ❌ N.M <task title>`). `phase-task-v11.0/SCHEMA.md` Section 3 extension noted. Validator extension (likely Check 35) noted.
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D5.

### §4.B6 — §5.3 LOCK `_order.md` + NEW §5.X SSOT subsection (D7)

- **Section:** §5.3 — locked `_order.md` as separate file (Option Y); new §5.X — Execution-order SSOT location
- **Before:** §5.3 line 423 carried "Decision deferred to the planner pass (POQ-3 in §12)" + "OPTIONAL" framing.
- **After:** §5.3 updated to "Per D7 (user direction 2026-05-25), `_order.md` is LOCKED as a separate per-entry supporting file — Option Y in the original POQ-3 framing. See §5.X Execution-order SSOT (below)..." Also "OPTIONAL" → "LOCKED per D7". NEW §5.X subsection inserted between §5.3 and §5.4 with full SSOT content: tracker-mode SSOT = Issue Field; flat-file SSOT = `<!-- execution-order: NNN -->` marker; `_order.md` = regenerated view (never SSOT); BD-189 forward-pointer for groupings pattern extensibility.
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D7.

### §4.B7 — NEW §6.3a Execution-note structured warning template (D8)

- **Section:** New §6.3a inserted between §6.3 (Reverse migration) and §6.4 (Initialization algorithm)
- **Before:** Bare warnings at §6.1 + §6.4 + worked-example lines: "Phase N has an execution note; verify execution order after migration." Bare warning was the only template content. POQ-4 framing carried throughout.
- **After:** Verbatim wording from prompt applied — full structured warning template with required content (7-item list): phase number + title, full note text, referenced entities (regex suggestions provided), current state of references, contextual assessment data, suggested actions [1]-[3] with concrete commands, doc cross-reference. Historical-marker persistence sub-section: `<!-- execution-note-status: historical -->` body marker; effect / round-trip / removal semantics. References at §6.1 + §6.4 + worked-example lines updated to point to §6.3a structured template; POQ-4 framing struck.
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D8.

### §4.B8 — §11.1 doc surface extensions (D5 + D8 + D3 + D4 + D2)

- **Section:** §11.1 — METHODOLOGY.md doc surface
- **Before:** §11.1 had baseline extension list (tracker representation, Part state taxonomy, Creating Parts programmatically, immutability note).
- **After:** Added "Additional Multi-part phases extensions (D3 + D4 + D8 + D2 + D5):" sub-block with Part creation rule (D3), Task immutability rule (D4), Execution-note-status marker convention (D8), and Decision-2 no-collapse rule. Added "SCHEMA archive extensions (D5 — `cancelled` state):" sub-block with `phase-task-v11.0/SCHEMA.md` Section 3 label-family extension (`cancelled` admitted) + Section 4 body-grammar extension (`<!-- execution-note-status: historical -->` marker).
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D5 (SCHEMA) + D8 (historical-marker convention) + D3 (creation rule cross-ref) + D4 (immutability cross-ref) + D2 (no-collapse cross-ref).

### §4.B9 — §5.2 + §7 Forgejo/Gitea v11.1+ forward-pointer + op count (D9)

- **Section:** §5.2 (closing paragraph) + §7 op count
- **Before:** §5.2 — Forgejo/Gitea listed as in scope for BD-185 with "fallback design (sub-issue reprioritize)". §7 — "Total surface: 18 → 21 ops + raw."
- **After:** §5.2 — Added explicit "Forgejo/Gitea support (per D9): DESIGNED for v11.1+ implementation; NOT shipping in v11.0..." paragraph. §7 — "Total surface:" split into "v11.0: 18 → 20 ops + raw (`provider_set_field` + `provider_get_field` added)" and "v11.1+ (when Forgejo/Gitea ships): 20 → 21 ops + raw (adds `provider_sub_issue_reprioritize`)". Note added: `provider_sub_issue_reprioritize` DESIGNED only in v11.0; implementation deferred to v11.1+ per D9. §7.1 Forgejo + Gitea rows updated from `POQ-5` to "primary-source verification at v11.1+ implementation per D6 + D9" and "Designed for v11.1+; NOT BD-185 implementation per D9".
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D9 (Forgejo/Gitea v11.1+ scoping); D6 (verify-at-implementation-time).

### §4.B10 — §5.1 tracker.toml schema + `pack tracker doctor` extension (D13)

- **Section:** §5.1 — Issue Fields shape for GitHub (added before §5.2)
- **Before:** No name-collision handling, no tracker.toml schema extension, no `pack tracker doctor` extension documented in §5.1.
- **After:** Verbatim wording from prompt applied — "Issue Fields name-collision handling (D13):" sub-paragraph (capability-detection + `Pack Execution Order` fallback name). "tracker.toml schema extension" TOML code block with `[execution_order] field_name = "Execution Order"  # or "Pack Execution Order" if fallback`. "`pack tracker doctor` extension:" sub-paragraph with three verification items (field existence, type=number, write-permission).
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text.
- **Source decision:** D13.

---

## §5 — Group C edits applied (Cleanups + typos)

### §5.C1 — §7.1 typo fix "v11.1 BD-185 ship" → "v11.0 BD-185 ship"

- **Section:** §7.1 — Per-backend support matrix (GitHub row)
- **Before:** "Default for v11.1 BD-185 ship"
- **After:** "Default for v11.0 BD-185 ship"
- **Source decision:** Typo (no D-tag; cleanup).

### §5.C2 — §5.1 DEPENDENCIES.md cross-reference (D10 follow-on)

- **Section:** §5.1 — end of section, before §5.2
- **Before:** No explicit pointer to `supporting-docs/DEPENDENCIES.md`.
- **After:** Added "**Tool requirement:** GitHub access via Issue Fields requires `gh` CLI installed + authenticated. See `supporting-docs/DEPENDENCIES.md` for the full tracker-mode dependency set. BD-185 adds no new tool dependency beyond the existing tracker-mode requirement."
- **Source decision:** D10 follow-on (tool-dependency clarity).

### §5.C3 — §12a Follow-on items (not BD-185 scope)

- **Section:** New §12a inserted within §12 (after the RESOLVED reference; before §13)
- **Before:** No follow-on items capture.
- **After:** Added 3-item bullet list as candidate follow-on BDs: (1) DEPENDENCIES.md framing cleanup (gh CLI is REQUIRED not OPTIONAL for tracker mode); (2) Required-tools discoverability via README + INSTALL-PROCEDURES; (3) Client-tool abstraction layer for non-gh paths (NOT v11.0 scope).
- **Source decision:** D10 follow-on session output.

### §5.C4 — NEW §1.4 Decision log (comprehensive audit trail)

- **Section:** New §1.4 inserted between §1.3 (User-locked constraints) and current §1.4 (renamed to §1.5)
- **Before:** §1.4 was "Architect-pass scope".
- **After:** New §1.4 = "Decision log (Pack Chat review session 2026-05-25)" with intro paragraph + 14-row decision table (#, Decision, Source, Resolution, Cross-ref) covering D1-D14 + sessionId reference (`f6d6104f-9268-42ff-90cf-ac8ae35433e3`). Original §1.4 renumbered to §1.5 with updated intro text noting "ALL 10 POQs + 3 derivative design decisions + INV-7 breach acceptance = 14 decisions were resolved 2026-05-25 per Pack Chat decision-review session — see §1.4 Decision log..."
- **Verbatim wording confirmation:** Yes — used the prompt's verbatim text for §1.4 content.
- **Source decision:** All 14 decisions (D1-D14).

---

## §6 — Verification

### Validate-pack.py

Command: `python3 scripts/validate-pack.py`
Result: **PASSED — all checks clean** (all 43 checks; no source code changed; architect doc not in v11-surface CI scans).

Excerpt from final-state run (tail):
```
── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 1 scope-claiming commit(s) verified clean; 0 implicit-scope commit(s) skipped
...
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 10 per-check test file(s) on disk; 10 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

### grep checks — D-decision references

Command: `grep -cE "\b(D1|D2|D3|D4|D5|D6|D7|D8|D9|D10|D11|D12|D13|D14)\b" maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`
Result: **52** — substantial cross-referencing (each of 14 decisions referenced in §1.4 Decision log + downstream sections).

### grep checks — POQ references

Command: `grep -cE "POQ-[0-9]" maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`
Result: **11** — down from 20+ in the original. All 10 surviving instances are the historical POQ→D mapping rows in the §1.4 Decision log table (e.g., "Architect POQ-1"); the 11th instance is the historical "POQ-3 framing" mention in §5.3 (explaining the Option Y locking). POQ-defer language struck throughout body sections (§4.3, §5.1, §5.2, §5.3, §6.1, §6.4, §7, §7.1, §8.2, §10.1, §14.2, §14.3, §14.9).

### Line count

Before edits: 1036 lines.
After edits: 1209 lines (+173 lines; net new = Decision log table + structured warning template + tracker.toml/doctor + supersede verb + 7-state taxonomy + SSOT section + Part-creation rule + supersede-only rule + Forgejo/Gitea forward-pointer language).

### Section structure

Numbering scheme intact + non-monotonic anchors used per the prompt's verbatim requirements (§4.4a after §4.4, §5.X between §5.3 and §5.4, §6.3a between §6.3 and §6.4, §12a within §12, §1.5 after §1.4). All other sub-section numbers continue monotonically.

---

## §7 — Cross-references

**Source decisions:**
- D1-D14 are the resolutions of the Pack Chat decision-review session 2026-05-25.
- sessionId: `f6d6104f-9268-42ff-90cf-ac8ae35433e3` (per pack memory convention; recorded in §1.4 of the updated architect doc).

**Documents referenced (not edited in this pass):**
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` — researcher fact base
- `pack-ops/BACKLOG.md` BD-185 entry — SC1-SC8 + C-1..C-5
- `supporting-docs/METHODOLOGY.md` — Multi-part phases section structure (for §11.1 doc-surface guidance)

**Pack-memory rules honored:**
- `feedback_filename_uniqueness` — section names cited; no line-number references introduced.
- `feedback_planner_user_review_before_coder` — this implementation lands user-approved decisions ahead of planner spawn.
- `feedback_pack_coder_preflight_pattern` — PREFLIGHT line emitted before IMPL-REPORT write.
- `feedback_agents_never_commit` — no state-changing git verbs run; report-only.

---

## §8 — Success criteria checklist

| # | Criterion | PASS/FAIL | Evidence |
|---|---|---|---|
| 1 | All 20 edits applied to ARCHITECTURE-BD-185.md | PASS | 6 Group A + 10 Group B + 4 Group C edits — see §3, §4, §5 of this report |
| 2 | Group B verbatim wording preserved (no redrafting) | PASS | All B1-B10 used the prompt's verbatim text; confirmed per-edit in §4 |
| 3 | POQ-defer language struck where decisions are now locked | PASS | 20+ POQ references reduced to 11 (all in §1.4 Decision log table audit trail + 1 historical "POQ-3 framing" call-out in §5.3) |
| 4 | §1.4 Decision log added with all 14 decisions | PASS | New §1.4 inserted between §1.3 and §1.5 (former §1.4 renumbered to §1.5); 14-row table covers D1-D14 with sessionId reference |
| 5 | §12 POQs section replaced with resolution reference | PASS | §12 retitled "POQs — RESOLVED"; body = resolution reference; §12a added for Follow-on items |
| 6 | validate-pack.py PASS | PASS | All 43 checks clean (see §6 verification) |
| 7 | No source code changed | PASS | Only edited `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`; no `scripts/`, `project-template/`, `supporting-docs/`, `pack-ops/`, `test-fixtures/` touched |
| 8 | IMPL-REPORT written | PASS | This document |

---

## §9 — Files touched inventory

| Path | Change type | Lines before | Lines after | Delta |
|---|---|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | modified (NB: untracked at start; was authored in prior architect pass; HEAD shows it as `??`) | 1036 | 1209 | +173 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md` | new | n/a | (this report) | n/a |

**Files NOT touched (per prompt's forbidden actions):**
- `scripts/**` — none
- `project-template/**` — none
- `supporting-docs/**` — none
- `pack-ops/**` — none
- `test-fixtures/**` — none
- `maintenance-docs/v11-research/**` — none (architect's inputs read-only)

**Plan deviations:** None. The prompt's "§10" placement reference for the new `pack task supersede` verb was interpreted as a placement signal (and clearly the verbs live alongside §4.5 Part creation verb); I placed it at §4.8 and updated `pack task supersede in §10` cross-references in the same edit to `pack task supersede in §4.8` for consistency. This is consistent with the prompt's overall structure (existing verb specs at §4.5 + §5.5) and not a redrafting of user-approved wording — the verbatim verb spec content itself was preserved.

**New POQs introduced:** None. All 14 decisions resolved into design language; no new POQ surface.

**Boundary discipline check:** The edited file is `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` — pack-internal maintenance doc, NOT a project-side surface. No project-side SSOT investigation required; no project-side files touched in this pass. Future planner / coder pass will need to apply the design to `project-template/` and `supporting-docs/` surfaces — at that point the boundary-investigation pre-flight applies to the implementer.

---

## End of IMPL-REPORT
