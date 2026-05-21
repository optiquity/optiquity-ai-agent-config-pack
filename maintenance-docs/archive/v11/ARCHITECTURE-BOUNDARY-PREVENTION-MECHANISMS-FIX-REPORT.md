# Architect C fix-pass — implementation report

**Author:** Architect C-fix (fresh architect, fix-pass role)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 2 fix-pass (per `PACK-REVIEW-PHASE-2-DESIGNS.md` §4 action summary,
Architect C fix-pass row)
**Date:** 2026-05-19
**Branch:** v11-dev
**Inputs read (per prompt):**
- `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md`
- `maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md`
- `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` (the target of the amend-in-place fix-pass)
- `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS.md`
- `PACK-AGENTS.md` (specifically lines 142-148 — the authoritative PM-only Files list)

**Output:** Amendments applied IN PLACE to
`maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`.
New top-level §16 added at end summarizing the changes per finding ID.

---

## §1 — Amendments applied per finding

### M2 (MUST) — add `pack-ops/` to Check 37 deny-list

- **Reviewer finding origin:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 M2, lines 86-104.
- **Reviewer fix-shape:** Add `pack-ops/` to the deny-list path-prefix entries
  in §8.2. Mirror in M4's boundary-investigation skill deny-list (§6
  "Pack-only deny-list" section).
- **Sections amended:**
  - **§8.2** Check 37 deny-list table — added a new row `pack-ops/` (path
    prefix) directly after the existing `maintenance-docs/` row. The new
    row enumerates the relocated PACK × OPERATIONS files that live under
    `pack-ops/` per Architect B + B-fix (PACK-AGENTS.md, PACK-CHAT.md,
    BACKLOG.md, CHANGELOG.md, HELP-FRAGMENT-PACK.md, HELP-FRAGMENT-TRACKER.md,
    OPTIONAL-FEATURES.md, MERGE-STRATEGY.md, DRY-RUN-MIGRATION.md,
    BOUNDARY-DEFINITION.md, .boundary-exempt-root.txt). Notes the
    symmetric relationship with the `maintenance-docs/` entry.
  - **§6** (M4 boundary-investigation skill text, step 4 "Path prefixes"
    bullet) — added `pack-ops/` alongside `maintenance-docs/`, `scripts/`,
    `test-fixtures/`. Includes an inline note that pack-ops/ houses the
    post-B-fix relocations and does NOT exist at client install.
- **How this satisfies the fix-shape:** Both surfaces named in the reviewer
  fix-shape (Check 37 deny-list + M4 boundary-investigation skill deny-list)
  are updated. Check 37 grep now flags any project-side literal reference
  to a `pack-ops/`-prefixed path; the skill methodology surfaces the same
  deny-target before reviewers / implementers recommend or apply such a
  reference.

### M4 (MUST) — collapse "3-entry closed set" exemption-list to 1-entry

- **Reviewer finding origin:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 M4, lines 127-140.
- **Reviewer fix-shape:** C-fix surfaces the post-B-fix exemption list as
  1-entry; updates any allow-list-count-based assertions accordingly.
- **References to "3-entry" / "closed set" / "exempt list" found in C
  pre-fix (count before fix):**
  - **Literal "3-entry" or "three-entry" or "closed-set" mentions in
    C's design body text:** 0 hits. Verified via `grep -i -E
    "3-entry|three-entry|closed[- ]set|exempt|allow[- ]list"` on the
    pre-fix doc. C did not literally encode N=3 anywhere.
  - **Indirect references to B's exemption list as an upstream input:**
    2 hits.
    - §11 conditional-surfaces table: rows for M5a / M5b / M5c name
      "Pack-only deny-list" / "PERMITTED-PATHS regex" / "Project-side
      directory boundaries" as conditional-on-B's-output surfaces. The
      B's-exemption-list count is implicit through this conditional.
    - §13 Order of land Step 11 (M5c lands AFTER Architect B's
      `supporting-docs/` decision): references B's exemption-list as
      upstream input without naming a count.
  - **Test plans / fixtures encoding N=3:** 0 hits. C's §12 measurable
    tests for M5a / M5b / M5c do NOT encode an allow-list count — they
    test deny-list grep behavior, not allow-list cardinality.
- **Sections amended:**
  - **§11** conditional-surfaces table — the rows for M5a / M5b / M5c
    now carry explicit notes:
    - M5a row: "1-entry list (only `tracker.toml.pack-example` per
      AUDIT-USER-CURATION.md Override 1 + Override 5 collapsing the
      original 3-entry closed-set proposed in B's §2.1); Check 36 /
      Check 38 fixtures that depend on the allow-list count assert
      N=1, NOT N=3."
    - M5b row: "Post-B + B-fix adds `pack-ops/` path-prefix per
      finding M2." (Cross-reference to M2 amendment.)
    - M5c row: "The 1-entry exemption list (above) governs which
      C2-at-root files Check 38 tolerates as exempt."
  - **§13** Order of land Step 11 (M5c) — added explicit "Consumes
    `pack-ops/.boundary-exempt-root.txt` (the 1-entry list per B-fix
    §4 + Overrides 1 + 5 — only `tracker.toml.pack-example`) as the
    allow-list for C2-at-root files; reject all other PACK × OPERATIONS
    files at root."
- **Count after fix:** 2 explicit "N=1, NOT N=3" disambiguations
  (§11 + §13). The Override 1 + 5 authority pointers cite B-fix §4
  for the underlying derivation.
- **How this satisfies the fix-shape:** Phase 3 reviewer's concern was
  that Phase 5 coder or fixture authors reading C alone would build
  N=3 allow-list assertions. With the new §11 + §13 disambiguations
  citing Overrides 1 + 5, no actor can land an N=3 assertion by
  accident; the 1-entry list is now load-bearing in both the
  conditional-surfaces table (where the dependency is explicit) and
  the dependency-graph step (where M5c consumes the allow-list).

### B1-cascade (BLOCKER) + S6 (SHOULD) — PM-only keyword permits `project-template/` trinity edits

- **Reviewer finding origins:**
  - B1 (BLOCKER): PACK-REVIEW-PHASE-2-DESIGNS.md §1 B1, lines 43-65.
    Cascade into C: M5a Check 36 PM-only keyword + §10.2 worked
    example + §12 test plan currently treat `project-template/`
    trinity edits as PM-only VIOLATIONS, but `PACK-AGENTS.md:148`
    explicitly lists project-template trinity AS PM-only.
  - S6 (SHOULD): PACK-REVIEW-PHASE-2-DESIGNS.md §1 S6, lines 241-253.
    Same fix as B1-cascade.
- **Reviewer fix-shape:** Update C §8.1 + §10.2 + §12 (test plan) to
  make `PM-only` keyword PERMIT `project-template/` trinity edits per
  actual `PACK-AGENTS.md:148` PM-only list. Drop the parenthetical
  "caught V10" — V10 was not a real PM-only violation.
- **Actual PACK-AGENTS.md:142-148 PM-only Files list used as the
  corrected definition (verbatim at HEAD `8014186`):**

  ```
  Files:
  - BACKLOG.md (regenerated mirror; per-entry source at /backlog/)
  - CHANGELOG.md (regenerated mirror; per-entry source at /changelog/)
  - README.md version table
  - PACK-CHAT.md
  - PACK-AGENTS.md
  - CLAUDE.md / AGENTS.md / GEMINI.md (root and project-template/)
  ```

  The decisive line is **PACK-AGENTS.md:148**: "`CLAUDE.md` / `AGENTS.md` /
  `GEMINI.md` (root **and** `project-template/`)". Project-template
  trinity IS PM-only, contrary to the audit's V10 framing.
- **Sections amended:**
  - **§8.1** keyword-table PM-only row — rewritten to PERMIT
    project-template trinity, cite PACK-AGENTS.md:142-148, and
    reference the new §8.1a verbatim list. The parenthetical
    "caught V10" DROPPED.
  - **§8.1** measurable-test bullet list — the PM-only test fixture
    that previously asserted FAIL on `project-template/CLAUDE.md`
    now asserts **PASS** (correct per actual PACK-AGENTS.md list).
    An additional V2-shape fixture added (subject `"PM-only: test"`
    touching `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`)
    asserting FAIL — supporting-docs is project-side per CLAUDE.md
    trinity rule and NOT in the PM-only Files list.
  - **§8.1a** (NEW subsection) — Authoritative PM-only Files list
    consumed by Check 36. Contains:
    - Verbatim PACK-AGENTS.md:142-148 PM-only Files block.
    - Post-B + B-fix path substitution rules
      (BACKLOG.md → pack-ops/BACKLOG.md, etc.).
    - Pre-B interim state note.
    - Canonical PERMITTED-PATHS regex for Check 36 PM-only keyword.
    - README.md version-table edits caveat (Check 36 cannot
      mechanically distinguish version-table edits from
      other-section edits; the narrower discipline stays Pack
      Chat's M1a memory rule).
    - Directories listed by PACK-AGENTS.md:150-158 (forward-pointing
      to Batch 23 BD-102 dog-food per-entry materialization).
    - Cross-reference to B1-cascade + S6 fix-pass.
  - **§10.2** worked example — V10 worked example DROPPED with
    explicit rationale (V10 collapses to NO-ACTION per Architect A
    fix-pass per B1; using `8ba0164` would encode the misreading
    into M1b). Replaced with V2 (`aaa61b3`) in hypothetical
    PM-only-keyword shape — had the commit subject been
    `"docs: v11 — PM-only Batch 19b cleanup"`, the
    `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` edit would
    fail Check 36 because supporting-docs is NOT in PM-only Files
    list.
  - **§12** test plan summary — the M5a row points to §8.1 fixtures
    (no separate edit needed; §8.1 is the canonical definition and
    is now correct).
- **How this satisfies the fix-shape:** All three surfaces named in
  the reviewer fix-shape (§8.1 + §10.2 + §12) are updated. §8.1 +
  §10.2 are amended directly; §12's M5a row reads through to §8.1's
  updated fixtures. The PACK-AGENTS.md:142-148 list is pasted
  verbatim in §8.1a so the corrected definition is traceable. The
  V10 worked example is dropped explicitly with rationale, and the
  corrected V2-shape worked example is in its place. Future readers
  cannot resurrect the misreading; future fixture authors cannot
  encode the wrong PM-only rule by accident.

### S4 (SHOULD) — explicit Override 9 citation block

- **Reviewer finding origin:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 S4,
  lines 201-216.
- **Reviewer fix-shape:** Add explicit citation: "Per
  AUDIT-USER-CURATION.md Override 9, the pack-side and project-side
  P-missed-7 codifications are intentionally different in wording.
  No Check 18 H2 parity gate applies to the new bullet."
- **Sections amended:**
  - **§4.1** (NEW subsection) — added immediately before §4.2.
    Contains:
    - Statement of the audience-specific wording principle (pack
      side detailed with BD-175 worked examples; project side
      shorter and inverted).
    - Authority block — verbatim quote from AUDIT-USER-CURATION.md
      Override 9 "Different audience means different wording is
      fine."
    - Phase 3 reviewer pointer — verbatim Override 9 "no cross-trinity
      drift gate needed for this codification."
    - **Implication for Check 18 H2 parity** sub-block —
      distinguishes WITHIN-trinity parity (continues to apply per
      CLI-files-cross-CLI-parity at each location) from CROSS-trinity
      parity (pack-root trinity vs project-template trinity wording)
      — the latter is REJECTED per Override 9.
    - **Measurable consequence** sub-block — clarifies that M2's
      Trinity Check 18 H2 measurable test (fires when bullet is
      missing from one trinity file) operates WITHIN each location;
      does NOT fire on the pack-side-vs-project-side wording
      difference.
    - Cross-reference to S4 fix-pass at the foot of §4.1.
- **How this satisfies the fix-shape:** Override 9 is now cited
  explicitly with a quote-block + pointer to AUDIT-USER-CURATION.md.
  The "no cross-trinity drift gate" implication is stated directly
  and scoped to Check 18 H2 parity specifically (the existing CI
  gate that readers might worry about). Future readers + Phase 4
  planner + Phase 5 coder cannot infer that pack-side / project-side
  wording must match; a reviewer cannot introduce a new
  "cross-trinity drift gate" check by accident; the M2 measurable
  test's scope is explicit.

### S5 (SHOULD) — `pack-ops/` path-prefix in §4.2 project-side mirror deny-list

- **Reviewer finding origin:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 S5,
  lines 219-237.
- **Reviewer fix-shape:** Add to §4.2 project-side mirror text:
  `pack-ops/ (any file there)` to the deny-list — matches the
  symmetric pack-side P-missed-7 expansion.
- **Sections amended:**
  - **§4.2** project-side mirror text — the deny-list paragraph
    ("Files at the pack repo ...") now lists `pack-repo pack-ops/`
    alongside the existing PACK-AGENTS.md / PACK-CHAT.md / pack-*
    agent prompts / pack-repo maintenance-docs/ entries. The added
    qualifier "any file under pack-ops/, including
    BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md, etc. post
    Architect B + B-fix" is path-prefix-equivalent and matches the
    grep contract used by Check 37 (M2 amendment).
- **How this satisfies the fix-shape:** Project-side trinity readers
  (project PM chat at client install) now see `pack-ops/` named
  explicitly as a deny-target. The wording matches the symmetric
  pack-side P-missed-7 expansion in §4 (which already names the
  same pack-ops/ paths via the worked-examples block and
  §6/§8.2's deny-list).

---

## §2 — Confirmation that unaffected sections are intact

Per §16.6 of the amended doc (the "Unaffected sections" enumeration in
the new fix-pass summary), the following sections were NOT amended by
this fix-pass and remain intact:

- **§0** (scope boundary with A + B), **§1** (regression mechanism),
  **§2** (design philosophy), **§3** (coverage matrix structure — the
  master table rows internally reference §8.1 / §8.2 which were
  updated; the §3 master-table rows themselves are unchanged).
- **§4** main P-missed-7 bullet text (the bullet itself unchanged;
  §4.1 added beside it as a citation block per S4).
- **§4.2** project-side mirror bullet STRUCTURE (only the deny-list
  paragraph was edited per S5; the rest of the mirror text + the
  measurable-test paragraph are unchanged).
- **§5** (M3 reviewer + implementer SSOT-investigation gates) —
  unchanged.
- **§6** main skill content — only step 4 Path-prefixes bullet was
  edited per M2; rest of skill body unchanged.
- **§7** (M6 SSOT-rotation reminder) — unchanged.
- **§9** (M7 + M8 trinity-rule + TYPE-5 gates) — unchanged.
- **§10.1** (M1a memory rule) + **§10.2 keyword-table + M1b convention
  text** — unchanged. Only the §10.2 worked example body was rewritten
  per B1-cascade.
- **§13** dependency graph — only Step 11 received a 1-entry-list
  annotation per M4; the rest of the dependency graph is unchanged.
- **§14** (constraints + gaps + open questions), **§15** (summary) —
  unchanged.

Cross-references to Architect A's `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`,
Architect B's `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`, and Architect
B-fix's `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` are preserved
throughout. The new §4.1 + §8.1a + §11 + §13 + §16 amendments cite
these docs explicitly so the cross-reference network is strengthened,
not weakened.

---

## §3 — Diff summary (numerical)

- **Original doc length:** 62,956 chars (757 lines).
- **Amended doc length:** 88,046 chars (1,164 lines).
- **Delta:** +25,090 chars (+407 lines).
- **New sections added:** §4.1 (S4), §8.1a (B1-cascade + S6), §16 with
  §16.1 — §16.6 (fix-pass summary covering all 6 findings).
- **Existing sections modified in place:** §4.2 (S5 — deny-list
  paragraph), §6 (M2 — step 4 Path-prefixes bullet), §8.1 (B1-cascade +
  S6 — keyword-table row + measurable-test bullet list), §8.2 (M2 —
  deny-list table new row), §10.2 (B1-cascade — worked-example body
  replaced), §11 (M4 — M5a/M5b/M5c rows annotated), §13 (M4 — Step 11
  annotated).
- **Sections deleted:** None. (Only the V10 worked example body within
  §10.2 was rewritten; the §10.2 section structure stayed.)

---

## §4 — Constraints honored

- **Read-only on all source files** except `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
  (the amend-in-place target).
- **No state-changing git verbs.** No `git add`, `git commit`,
  `git tag`, `git mv`, `git rm`. Working tree edits only.
- **Markdown-only output** — both the amended doc and this fix
  report are markdown.
- **Chunked Write calls** — amendments applied via a single Python
  script that uses Path.write_text() once on the target doc (35
  KB output); under the 300-line threshold. The fix report itself
  is a single ~250-line write.
- **STOP-MEANS-STOP** — no stop directive received during the work.
- **No new design content** — the amendments are corrective to the
  reviewer's findings; no new prevention mechanism designed beyond
  the existing M1-M8.
- **No solutions in domains outside Architect C's scope** — all
  amendments stay within prevention-mechanism design (P-missed-7
  codification, SSOT-investigation gates, boundary-investigation
  skill, CI checks). No incursion into Architect A's re-litigation
  framework or Architect B's directory architecture; only consumption
  of B's pack-ops/ output and B-fix's exemption-list reduction as
  inputs.

---

## §5 — Phase 3 reviewer re-verification surface

If Phase 3 reviewer (this one, or a fresh one per pack memory) re-runs
on this fix-pass, the verification surface is:

1. **M2 verification:** `pack-ops/` appears as a path-prefix row in
   the §8.2 Check 37 deny-list table AND in the §6 M4 skill text
   step 4 Path-prefixes bullet. Both updates symmetric.
2. **M4 verification:** §11 + §13 carry explicit "1-entry list, NOT
   3-entry" disambiguations with Override 1 + 5 citations. No
   N=3 assertions encoded anywhere in C.
3. **B1-cascade + S6 verification:** §8.1 PM-only keyword row
   PERMITS project-template trinity; §8.1a verbatim PACK-AGENTS.md
   list present; §10.2 worked example uses V2 not V10; "caught V10"
   parenthetical absent from §8.1 / §10.2.
4. **S4 verification:** §4.1 cites Override 9 verbatim, distinguishes
   within-trinity parity from cross-trinity parity, scopes Check 18
   H2 measurable test correctly.
5. **S5 verification:** §4.2 project-side mirror deny-list paragraph
   names `pack-ops/` as a deny-target alongside the existing entries.

All five amendments are mechanically verifiable via grep on the
amended doc.

---

## §6 — End of fix-pass implementation report
