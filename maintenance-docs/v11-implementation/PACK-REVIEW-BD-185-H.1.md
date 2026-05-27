# PACK-REVIEW — BD-185 H.1 (re-do after Code Red 2 cleanup)

**Reviewer:** pack-reviewer (read-only).
**Date:** 2026-05-27 (US/Pacific).
**Branch:** `v11-dev`.
**Repo HEAD reviewed:** `ba9e09d96895a2d697916c23150a1472d59eabc0` —
`docs: v11 — pack memory PREFLIGHT per-check test runs (PM-only)`.
**Pipeline:** docs-researcher → architect (ARCHITECTURE-BD-185.md;
USER-LOCKED) → planner (PLAN-BD-185.md) → coder (commit 8b4c607
2026-05-26) → BD-193 cleanup (85196d4, 8b0718e) → BD-194 cleanup
(4ef6c02, 6c76582) → THIS review.

---

## §1 — Scope

This pack-review covers BD-185 Batch 19d.H.1 — the v11.1 templates-
archive cut establishing the new `phase-part-v11.1` entry type schema
and `v11.1/INDEX.md` enumeration. The original H.1 commit shipped at
`8b4c607` (2026-05-26); the H.1 review was deferred because Code Red 2
fired against the same surface immediately after H.1 landed (BD-193 +
BD-194 cleanup commits modified the two H.1 files extensively). This
re-do reviews the **current HEAD state** of the H.1 surfaces — i.e.,
the post-cleanup state — against the architect spec, not the original
8b4c607 cut state.

H.1 surface (3 files in scope):

1. `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`
   (224 lines at HEAD; 225 lines at original H.1 cut).
2. `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`
   (89 lines at HEAD; 78 lines at original H.1 cut).
3. `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`
   (507 lines; historical artifact — not modified post-H.1).

Cleanup commits between H.1 and HEAD that touched these surfaces:

| Commit | Title | H.1-surface impact |
|---|---|---|
| `85196d4` | BD-193 Code Red 2 BD/TD scope cleanup | F1 INDEX segregation (client-applicable / pack-internal); F2 BD-NNN admission removal from Prerequisites grammar; 23 BD-185 narrative cite removals from SCHEMA.md, 12 from INDEX.md |
| `8b0718e` | BD-193 Phase 5 Code Red 2 remediation | S-1 INDEX Forms-file forward-looking framing; A-2 SCHEMA.md L170 BD/TD-parent constraint trim |
| `4ef6c02`, `6c76582` | BD-194 Check 24 byte-identity gate replacement | No H.1-surface impact (touched scripts/validate-pack.py only) |

---

## §2 — Methodology

Four review dimensions per prompt:

1. **Architectural fidelity (Part-id grammar + lifecycle).** Verify
   `phase-part-v11.1/SCHEMA.md` still correctly expresses the
   USER-LOCKED C-1 Part-id grammar and the Part lifecycle invariants
   D2 / D3 / D4 / D5 (cancelled-state phase-task-only).
2. **Architectural fidelity (INDEX segregation).** Verify
   `v11.1/INDEX.md` still correctly expresses the segregated client-
   applicable vs pack-internal entry-type structure (BD-193 F1).
3. **Cosmetic quality.** Typos, formatting consistency, line-length
   discipline, cross-reference accuracy at current HEAD.
4. **IMPL-REPORT accuracy.** Whether the historical IMPL-REPORT is
   still a faithful description of the H.1 surfaces, or whether
   cleanup has materially superseded its claims.

Read-only methodology:
- Read both source files in full at HEAD.
- Read architect spec sections cited by IMPL-REPORT (§1.4 D1-D16;
  §4.1 C-1 grammar; §4.3 form-family; §4.4 state taxonomy; §4.7 lifecycle).
- Read cleanup commit diffs (`git show 85196d4 -- ...`, `git show 8b0718e -- ...`)
  to understand what the cleanup intended.
- Read v11.0/INDEX.md and v11.0/phase-task-v11.0/SCHEMA.md for parallel-
  pattern verification.
- Verify `python3 scripts/validate-pack.py` PASS at HEAD (43/43 checks).

No git state-changing verbs, no edits to source files.

---

## §3 — Per-file findings

### §3.1 — `phase-part-v11.1/SCHEMA.md` (224 lines at HEAD)

**Architectural fidelity:** PASS. The file correctly expresses the
USER-LOCKED C-1 grammar and lifecycle invariants:

- **C-1 Part-id grammar (§4.1 of architect doc).** SCHEMA.md L17-29
  declares `Phase-N.Part-x` with atom regex `[1-9][0-9]*` (phase
  integer; v10-compat zero exception) + `[a-z]` (single lowercase
  letter; 26-Part architect-pass cap). Round-trip carrier
  (title-prefix + body-marker) matches architect §4.1.
- **Prohibited forms.** L31-37 enumerates 3 rejected shapes (empty
  separator, lowercase atoms, numeric Part identifier) matching
  architect §4.1 + §4.1's three architectural rejections.
- **Body marker trio.** L41-45 trio matches architect §11.1 archive
  extension spec; parser/emitter cite uses bare `tracker-phase-part.sh`
  (post-BD-193 cleanup — the architectural BD-185 §4.X cite was
  removed per F2/F3 cleanup intent).
- **Label family.** L65-70 mirrors phase-task-v11.0 label family with
  the appropriate Part substitutions; "Excluded labels" block at
  L72-84 correctly enumerates 4 excluded patterns per architect §4.4
  lifecycle invariant including the D5 carve-out (`status:cancelled`
  applies to phase-task only).
- **State taxonomy (D2/D3/D4).** L86-108 declares the 4-state
  restrictive taxonomy (`pending / in-progress / done / deferred`) +
  lifecycle invariant block covering D2 (no-collapse), D3 (no-empty-
  Part at creation), D4 (no-mid-life-re-parent), and deferral-as-only-
  exit. Matches architect §4.4.
- **Body section grammar (§5).** L110-160 declares Goal / Prerequisites
  / Member tasks order; Prerequisites grammar admits 6 ID forms
  (phase-N, Phase-N.Part-x, Phase-N.Task-M, Phase-N.Part-x.Task-M,
  phase-N.M legacy shim, TD-NNN). BD-NNN was REMOVED per BD-193 F2.b
  (correct — Prerequisites should not admit pack-internal entity).
- **Sub-issue hierarchy (§6).** L162-182 correctly declares depth-2
  under phase-epic / depth-3 parent of tasks; capability-flag fallback;
  re-parentage via `provider_sub_issue_unlink` + `provider_sub_issue_create`.
  Sub-issue depth-cap (8) + 100-children-per-parent / 1-parent-per-
  child preservation noted.
- **Reverse-emit grammar (§7) + Body marker reservations (§8).**
  L184-224. §7 is correctly TBD-stubbed for downstream `tracker-migrate-
  reverse.sh` work; §8 documents the intentional absence of
  `<!-- execution-note-status: historical -->` (phase-N.md only).

**Cosmetic quality findings:**

1. **NIT-1.** `SCHEMA.md:L145` — `Phase-N.Task-M — depends on a specific
   task (null-Part task identifier per §4.1)`. The trailing `§4.1`
   is a stale BD-185 architect-doc cite that escaped BD-193 cleanup.
   In the current file the equivalent in-file section is `§1`
   (`## 1. Identifier scheme`), not `§4.1`. A reader navigating
   in-file lands on a missing anchor. **Severity:** NIT. **Suggested
   fix:** change `per §4.1` to either `per §1` (in-file) or drop the
   parenthetical (the term "null-Part task" is self-descriptive at
   that point). Alternatively rewrite as `per the canonical grammar`
   matching the BD-193 cleanup pattern used elsewhere.

2. **Acceptable bare cross-refs (NOT findings, but flagged for context).**
   L152 cites `V3.3 §5.5`; L166 cites `V1 §2.7.2`; L167 cites `V3.2 §2.7`;
   L180 cites `V1 §2.7.2`; L210 cites `V1 §6.6.1`. These are bare-version
   shorthand for architect docs without filename context (the form
   explicitly flagged in CLAUDE.md filename uniqueness heuristic as a
   leak under the rule's spirit). However, the parallel patterns exist
   in v11.0/phase-task-v11.0/SCHEMA.md and v11.0/phase-epic-v11.0/SCHEMA.md
   (templates SCHEMA.md files use this convention throughout). Cleaning
   this up across the templates-archive is a broader hygiene pattern
   beyond H.1 scope. Not a finding for this review; flagged for
   awareness if a future BD addresses bare-version shorthand across
   the archive.

3. **NIT-2.** `SCHEMA.md:L168` — `architect §7 fallback extension TBD`.
   The "architect §7" cite has no preceding context for which architect
   doc; the reader has to infer it's ARCHITECTURE-BD-185.md or possibly
   another archive-design doc. Given BD-193 cleanup removed most
   architect cross-references (replacing them with self-contained
   prose), this surviving "architect §7" is anomalous. **Severity:**
   NIT. **Suggested fix:** either remove the parenthetical (the
   fallback IS the label, no further design surface needed at this
   level) or replace with "fallback extension TBD" without the
   architect-§7 cite.

### §3.2 — `v11.1/INDEX.md` (89 lines at HEAD)

**Architectural fidelity:** PASS. The file correctly expresses the
segregated entry-type structure per BD-193 F1:

- **Client-applicable entry types (§"Entry types at v11.1").**
  L16-22 declares a 5-row table (TD, phase-epic, phase-task,
  phase-part NEW in v11.1, inbound). All 5 schema link to either
  `../v11.0/<entry-type>-v11.0/SCHEMA.md` or in-cut
  `phase-part-v11.1/SCHEMA.md`. Matches architect §4.3 form-family
  spec.
- **Pack-internal entry types (§"Pack-internal entry types").**
  L24-28 declares a 1-row table (BD-NNN) with the parenthetical
  classifier "(informational only; NOT applicable to client projects)".
  This is the F1.b lock action from BD-193 §3.1.
- **v11.0 archive cross-reference.** L30-51 correctly declares
  Convention Y (D16; USER-LOCKED 2026-05-26): v11.0 frozen at 5 subdirs;
  intra-file additive extensions permitted. The two enumerated
  extensions (phase-task-v11.0/SCHEMA.md `status:cancelled`;
  v11.0/INDEX.md forward-reference footnote) are still forward-looking
  — neither has landed at HEAD (verified: v11.0/phase-task-v11.0/SCHEMA.md
  has no `status:cancelled` row at HEAD; v11.0/INDEX.md has no forward
  footnote). This is intentional and correct.
- **Forms file (§"Forms file").** L53-60 BD-193 Phase 5 S-1 fix
  declares "Not yet created" + post-BD-193 pack/project divergence
  constraint (pack admits `bd` wi-type; project does not). The two
  forms are SEPARATE artifacts. This is the architecturally-correct
  state given pack/project separation-of-concerns lock 2026-05-26.
- **Decision log cross-reference (§"Decision log").** L77-89 enumerates
  8 of 16 USER-LOCKED decisions (D1, D2, D3, D4, D5, D11, D15, D16) —
  the curated "most-load-bearing" subset matching IMPL-REPORT §5
  intent. D6/D7/D8/D9/D10/D12/D13/D14 intentionally omitted (focus on
  schema-shaping decisions for this archive cut INDEX).

**Cosmetic quality findings:**

3. **NIT-3.** `INDEX.md:L62` paragraph (`The live form is bumped to
   template_version: work-item-v11.1 and gains: ...`) reads as if the
   form HAS been bumped, but L53-60 explicitly says "Not yet created"
   for the archived form. The juxtaposition is slightly confusing —
   the L62-69 paragraph describes the post-bump form spec (what it
   WILL look like when populated), but the prose phrasing
   ("is bumped" present tense) reads as fait accompli. The L53-60 fix
   landed as a Phase 5 S-1 retrofit; the L62-69 paragraph was the
   original H.1 prose untouched. **Severity:** NIT. **Suggested fix:**
   change "is bumped" to "will be bumped" or "is bumped (post-H.2)"
   to align tense with the Forms-file-not-yet-created note. Alternative:
   merge the two sections into one "Forms file (when created)" block.

4. **NIT-4.** `INDEX.md:L53` — `**Forms file** — Not yet created.`
   The bold-headed paragraph at L53 reads as a sub-section but is not
   declared as a `## Forms file` or `### Forms file` H2/H3. It floats
   between `## v11.0 archive cross-reference` (L32) and the implicit
   continuation about the live form (L62). A reader scanning the TOC
   would not find "Forms file" as a distinct section. **Severity:**
   NIT. **Suggested fix:** add an explicit `## Forms file` H2 heading
   before L53. (This is consistent with INDEX.md's other H2 structure
   — Entry types / v11.0 archive cross-reference / Decision log are
   all H2.)

### §3.3 — `IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md` (507 lines, untouched since 8b4c607)

**Accuracy at HEAD:** SUPERSEDED in narrow line-count + architectural-
cite claims, but the IMPL-REPORT is a frozen historical artifact and
should NOT be modified to reflect post-cleanup state. The IMPL-REPORT
correctly described the H.1 commit at the moment H.1 landed. BD-193
and BD-194 are separate BDs with their own IMPL-REPORTs covering
their changes.

**Drift items (informational only — do NOT fix in IMPL-REPORT):**

- **§3.1 L67:** Claims SCHEMA.md is "225 lines (~9.4 KB markdown)".
  At HEAD: 224 lines. Drift = 1 line removed by BD-193 cleanup
  (A-2 BD/TD-parent constraint trim at L170).
- **§3.2 L96:** Claims INDEX.md is "78 lines (~3.7 KB markdown)".
  At HEAD: 89 lines. Drift = +11 lines from BD-193 F1 segregation
  (split into client-applicable / pack-internal tables; added the
  pack-internal table header + row) + BD-193 Phase 5 S-1 Forms-file
  forward-looking paragraph.
- **§3.1 + §4 + §7:** Multiple references to "BD-185 H.5
  `tracker-phase-part.sh`", "per BD-185 §4.X", "per D5" embedded in
  cross-reference tables. The IMPL-REPORT correctly described
  SCHEMA.md as containing these architectural cites at H.1 cut time.
  At HEAD, the cites are stripped (per BD-193 F3 + Phase 4 narrative
  cleanup). The IMPL-REPORT is an accurate description of the
  ORIGINAL state but readers should consult the SCHEMA.md at HEAD for
  the current state.
- **§6.4 (line 322 of IMPL-REPORT):** grep claims `16` matches against
  the 6 entry-type tokens. Re-running at HEAD: `14` matches (BD-193
  cleanup removed 2 narrative occurrences). Drift is expected;
  threshold (≥6) still satisfied.
- **§6.5 (line 332 of IMPL-REPORT):** Section line offsets shifted —
  IMPL-REPORT shows `18:## 1. Identifier scheme` etc. At HEAD: L15.
  Drift = -3 lines from BD-193 cleanup of the introductory reference
  block (lines 8-10 of H.1 cut were the "Reference: ARCHITECTURE-BD-185.md
  §4.1 / §4.1a / ..." block now removed).

**Severity:** NONE. The IMPL-REPORT is a historical artifact. Modifying
it would falsify the audit history. The cleanup BDs (BD-193, BD-194)
have their own IMPL-REPORTs documenting the modifications they applied.

**Recommendation:** Leave IMPL-REPORT-BD-185-Batch-19d-H.1.md
unchanged. If desired, BD-193's IMPL-REPORT (already exists per BD-193
commit message) is the cross-reference document for the post-H.1
modifications.

---

## §4 — Findings summary

| ID | Severity | File | Description |
|---|---|---|---|
| NIT-1 | NIT | `phase-part-v11.1/SCHEMA.md:L145` | Stale `§4.1` architect-doc cite in Prerequisites grammar; should be `§1` (in-file) or removed |
| NIT-2 | NIT | `phase-part-v11.1/SCHEMA.md:L168` | Stale `architect §7` cite in capability-flag-fallback line; should be removed or filename-qualified |
| NIT-3 | NIT | `v11.1/INDEX.md:L62` | "The live form is bumped" present-tense conflicts with L53 "Not yet created"; suggest "will be bumped" or merge with Forms-file section |
| NIT-4 | NIT | `v11.1/INDEX.md:L53` | "Forms file" pseudo-section lacks an explicit H2/H3 heading; floats between v11.0-archive and live-form prose |

**Severity distribution:** 0 BLOCKER, 0 MUST, 0 SHOULD, 4 NIT.
**Per-dimension verdict:**

1. **Architectural fidelity (grammar + lifecycle).** PASS.
2. **Architectural fidelity (INDEX segregation).** PASS.
3. **Cosmetic quality.** 4 NIT-level findings (NIT-1 through NIT-4).
4. **IMPL-REPORT accuracy.** Historical artifact; NOT a finding.
   Drift is expected and documented in §3.3.

**Carry-forward discipline note:** Per the review SKILL.md carry-
forward rules + Pack memory `feedback-review-carry-forward-discipline`,
all 4 NIT findings are surfaced as fix-or-defer triage items for
Pack Chat. None qualify as architect-pass material (SIZE), none are
BLOCKED on a future artifact, and none have a LOGICAL-FIT with another
BD. They are small in-place text edits and should default to FIX NOW
unless the user defers them with explicit SIZE/BLOCKED/LOGICAL-FIT
justification.

**Acknowledgment of what H.1 + cleanup got right:**

- The C-1 grammar is correctly captured with atom regex + uniqueness
  scope + identity owner + round-trip carrier.
- The 4-state restrictive taxonomy is correctly restricted to pending /
  in-progress / done / deferred (no cancelled — D5 phase-task carve-out
  respected).
- The Excluded-labels block correctly enumerates 4 forbidden label
  patterns per D2 / D3 / D4 / D5 lifecycle invariant.
- Sub-issue hierarchy (depth-2 under phase-epic / depth-3 parent of
  tasks) is correctly stated; capability-flag fallback preserved.
- BD-193 F1 INDEX segregation is structurally clean: client-applicable
  vs pack-internal tables, with the "informational only; NOT applicable
  to client projects" parenthetical conveying intent clearly.
- The Prerequisites grammar's BD-NNN removal (BD-193 F2.b) is
  semantically correct — pack-internal entity should not be a
  client-facing dependency form.
- The IMPL-REPORT is well-structured, thorough, and honest about
  what was created (§3) vs deferred (§3.0 references POQ-1 deferral
  to H.2 for forms/).
- `python3 scripts/validate-pack.py` PASS (43/43) at HEAD.

---

## §5 — Recommended remediation

**Recommendation:** Apply NIT-1 + NIT-2 + NIT-3 + NIT-4 as a small
follow-on fix-coder commit. The four NITs total ~6 lines of textual
change across two files; bundling them as a single
`fix: v11 — BD-185 H.1 post-cleanup NIT sweep (pack-only)` commit is
proportionate.

**Concrete fix-coder triage items (Pack Chat may override per finding):**

- **NIT-1 (FIX).** `SCHEMA.md:L145` — change
  `(null-Part task identifier per §4.1)` to either:
  - `(null-Part task identifier per §1)` (in-file ref), OR
  - `(null-Part task identifier — see §1)` (in-file ref, clearer prose), OR
  - drop the parenthetical entirely.
- **NIT-2 (FIX).** `SCHEMA.md:L168` — change
  `architect §7 fallback extension TBD` to either:
  - `fallback extension TBD` (drop the architect-§7 cite), OR
  - move the architectural design-pointer into the IMPL-REPORT (which
    is the appropriate venue for unresolved architect surfaces).
- **NIT-3 (FIX).** `INDEX.md:L62` — change `The live form is bumped to`
  to `When created, the live form will be bumped to`. Or restructure
  to put L53-60 + L62-75 into a single `## Forms file` H2 section
  (this also addresses NIT-4).
- **NIT-4 (FIX).** `INDEX.md:L53` — add an explicit `## Forms file`
  H2 heading before "Not yet created." If NIT-3 is fixed via section
  restructure, this is addressed jointly.

**Total estimated change:** 4-8 lines across 2 files. No architectural
implications. No CI risk.

**Defer rationale (if Pack Chat / user prefers to defer):** None of
the four NITs are blocking; they are cosmetic clarity issues. They
could ride alongside the H.2 commit if the user prefers a single
cleanup pass rather than a standalone H.1 NIT-sweep commit. However,
per Pack memory `feedback-deferral-is-scope-creep`, the default is
FIX NOW unless a SIZE/BLOCKED/LOGICAL-FIT case is made — none of the
NITs meet that bar, so FIX-NOW is the architecturally-correct default.

**One open question for Pack Chat triage:** the 5 bare-version
cross-references in SCHEMA.md (V3.3, V1, V3.2 cites at L152, L166,
L167, L180, L210) are a broader pattern across all templates-archive
SCHEMA.md files (not unique to H.1). Cleaning them up across the
archive is beyond H.1 scope; not raised as findings here. If the
user wants this addressed pack-wide, it would be a new BD for archive-
wide bare-cite cleanup.

---

## §6 — Cross-references

| Doc | Section | Purpose |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | §1.3 C-1 / §1.4 D1-D16 / §4.1 / §4.1a / §4.3 / §4.4 / §4.7 / §10.1 / §11.1 | User-locked architectural source-of-truth for H.1 design |
| `maintenance-docs/v11-implementation/PLAN-BD-185.md` | §H.1 | H.1 commit specification |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md` | full | Historical record of the original 8b4c607 commit (frozen artifact) |
| `maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md` | §3.1 F1 / §3.2 F2 / §4.7 / §4.8 | BD-193 cleanup disposition that landed at 85196d4 |
| `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | full | Parallel-pattern reference for the v11.1 INDEX.md segregation structure (post-BD-193) |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | full | Parallel-pattern reference for the SCHEMA.md structure (8 H2 sections, fenced grammar block H2 sub-headings convention) |
| `maintenance-docs/v11-research/templates-archive/README.md` | full | Archive contract: pack-repo-only, append-only after release tag |
| `.claude/skills/review/SKILL.md` | full | Reviewer methodology + carry-forward discipline |
| Pack memory `feedback-review-carry-forward-discipline` (trinity CLAUDE.md § Pack memory) | full | Trinity-cached high-bar test for any carry-forward framing |

**Review verdict:** APPROVE with 4 NIT findings. Architectural fidelity
is PASS on both dimensions; cosmetic quality has small in-file text
clarity items that warrant a follow-on fix-coder commit per Pack
Chat triage.

**Reviewer attestation:** Read-only review per pack-reviewer prompt.
No source files modified. Only Write call was this report file at
`maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.1.md`.
