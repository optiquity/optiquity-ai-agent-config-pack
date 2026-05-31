# AUDIT-BD-195-RECONCILED-PROBLEM-LIST

**Author:** pack-docs-researcher (BD-195 Step 3 reconciliation pass; read-only). **Date:** 2026-05-29. **Branch:** v11-dev.
**Inputs:** the 9 read-only audit segments R1–R9 (`RESEARCH-BD-195-SEGMENT-R{1..9}-*.md`).
**Purpose:** ONE de-duplicated, prioritized problem list — the single decision surface the user reviews at G3 before BD-185 restart. Self-contained: a reader decides here without opening the 9 segment docs.
**Categorical fact applied (not re-litigated):** v11.0 is UNRELEASED, never frozen; phase-parts is v11.0 (never v11.1); GitHub Projects + groupings ARE legitimately v11.1+ (not the mislabel).
**Standard:** Findings are framed as the researchers stated them. Recommendations carry the researchers' stated remediation only — this pass does NOT design new fixes. Where researchers left a question open or disagreed, that is surfaced as an OPEN QUESTION for the user, not resolved here.

---

## Summary — problem count by severity

59 raw segment findings (R1-F01…R9-F03) consolidate into **28 top-level problem records (P-01 … P-28)** plus **3 grouped lower-priority buckets (P-29 / P-30 / P-31)** that hold the long tail of low-blast-radius NIT/SHOULD findings (22 sub-records, each individually attributed so nothing is lost). Counting by the SUBSTANTIVE severity of every distinct underlying problem:

| Severity | Count | Where |
|---|---|---|
| BLOCKER | 2 | P-01, P-02 |
| MUST | 10 | P-03, P-04, P-05, P-06, P-07, P-08, P-09, P-10, P-11, P-28 |
| SHOULD | 19 | P-12, P-13, P-14, P-15, P-16, P-17, P-18, P-19, P-20, P-22, P-23, P-24, P-26 (standalone) + P-29a/b/c/d/e/f, P-30b, P-31d/f (grouped) |
| NIT | 18 | P-21, P-25, P-27 (standalone) + P-29g/h, P-30a, P-31a/b/c/e/g/h/i/j/k/l (grouped) |
| **Total distinct problems** | **49** | (from 59 raw findings; the merge ratio is the v11.1-mislabel cluster + the README-mis-filing pair + the v10-prose triple + the prison-V3.2 pair) |

Open questions for G3: **7 user decisions** (OQ-1 … OQ-7) + **1 sequencing precondition** (OQ-8) — see § Cross-segment open questions. Reconciler-added (low-confidence, NOT from a segment): **0**.

> **Note on the grouped buckets.** P-29/P-30/P-31 are scannability buckets, NOT single fixes — each sub-letter is a distinct problem with its own surfaces, source finding, and stated action. They are grouped because each is low-priority and the user will likely triage them as a batch. Two SHOULDs (P-31d ENCODING-lock-step, P-31f client-dead-ref) sit in P-31 for thematic adjacency and are flagged for promotion in triage.

**The headline.** The contamination BD-195 exists to expunge — phase-parts mislabeled as "v11.1" / v11.0 falsely "frozen" — is the dominant theme. It is **one underlying mis-versioning** spread across: **two live shipped code surfaces** (validator + its CI test → P-01, BLOCKER), **one tracked design-archive cut** (the fictional `v11.1/` templates-archive → P-02, BLOCKER), **the propagating review/remediation that blessed it** (P-08), and **a wide tail of contaminated BD-185-attempt workflow artifacts** (P-09, P-17, P-18). The second-largest theme is **prison stale-refs**: live docs/code that still cite docs moved to `maintenance-docs/prison/` in Step 2 (P-14, P-15, P-21, P-25). The remainder are **client-shipped dead-pack-doc references** (P-04, P-05, P-06, P-31f) and **version-currency staleness** (v9/v10 labels on a v11 pack: P-19, P-20, P-29e/f, P-31e).

---

## THEME A — v11.1 mislabel / "frozen v11.0" contamination (the BD-195 epicenter)

### P-01 — LIVE v11.1 mislabel encoded in shipped pack code: `validate-pack.py` + `test-issue-forms.sh` comments
- **Severity:** BLOCKER
- **Surfaces:**
  - `scripts/validate-pack.py` — `check_issue_template_forms()` docstring + inline comments (3 occurrences: "added at v11.1 (BD-185 H.2)", "introduced at v11.1"). Runtime dict `expected_wi_type_options_per_surface` is CORRECT — do not touch.
  - `scripts/tests/test-issue-forms.sh` — 6 comment blocks ("added at v11.1 (BD-185 H.2)" in docstring, `check_workitem`, forbidden-list comment, `wi-part-letter` comment, Blockers Part-id comment, Group 5 comment). Assertions are version-neutral and CORRECT — do not touch.
- **Found by:** R5-F01, R6-F01, R7-F04 (validator, BLOCKER), R7-F06 (test, MUST). Merged: same lock-step ENCODING unit (validator F2 + its CI test F3).
- **Why it's a problem:** Violates the BD-195 CATEGORICAL FACT — phase-parts was ALWAYS v11.0 scope, never v11.1. This is the exact mis-versioning that fractured the prior BD-185 attempt, now living in tracked, CI-executing pack code (the highest-stakes surface in the epicenter). Per the pack-memory "Enumerate ENCODING surfaces" rule, a comment in a CI-wired ENCODING surface asserting the wrong version is the "LEAK (operational, code/test-encoded)" verdict class. `BD-185 H.2` is also a recovery-volatile sub-batch label.
- **Recommended action (as researchers stated):** Replace "added at v11.1 (BD-185 H.2)" / "introduced at v11.1" with "added in v11.0 (BD-185)" (R7) or "added at v11.0 (phase-parts hierarchy work)" dropping the volatile `H.2` sub-batch label (R6) — researchers agree on direction (v11.0), differ only on whether to keep a BD anchor; settle at fix time. No functional change. Per `ARCHITECTURE-BD-185-V2.md` §10 Groups D + F.
- **Cross-surface coupling (lock-step partners):** validator + test MUST update together (same lock-step unit per "Enumerate ENCODING surfaces"). Because `scripts/` is touched: regenerate `test-fixtures/manifest.txt` in the same commit (`feedback_manifest_regen_on_v11_surface`) AND run per-check tests (`test-issue-forms.sh`, `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-43.sh`) per the PREFLIGHT gate. The shipped form-file prose (P-08) carries the parallel label and updates in the same lock-step.

### P-02 — `templates-archive/v11.1/` cut is fictional contamination: false "v11.1 cut" premise, fabricated Convention-Y edits, misplaced duplicates
- **Severity:** BLOCKER
- **Surfaces:** (all under `maintenance-docs/v11-research/templates-archive/`)
  - `v11.1/INDEX.md` — densest contamination: "v11.1 archive cut" premise (L7, L12, L21), "NEW in v11.1" + `phase-part-v11.1` marker, "v11.0 archive remains structurally frozen … USER-LOCKED" framing (L32–35), TWO fabricated Convention-Y "exercises" (independently falsified by grep: no `status:cancelled` in `phase-task-v11.0/SCHEMA.md`; no v11.1 forward-ref footnote in `v11.0/INDEX.md`), `work-item-v11.1` bump claim (L89–93, self-contradicted by sibling form), D1–D16 superseded decision-log block (L95–107).
  - `v11.1/phase-part-v11.1/SCHEMA.md` — `phase-part-v11.1` version tag throughout (L1, L43, L69, L117) + wrong directory. GRAMMAR SUBSTANCE is user-approved and FIXED (V2 §2.B carve-out) — keep verbatim; ONLY the version tag + location are contamination. This is the SOLE live home of the phase-part grammar.
  - `v11.1/forms/work-item.yml` — misplaced duplicate; its own markers (`work-item-v11.0`, L7/L186) are accidentally CORRECT and refute the sibling INDEX bump claim; collides with the existing `v11.0/forms/work-item.yml`.
- **Found by:** R7-F01 (BLOCKER), R7-F02 (MUST), R7-F03 (MUST). Merged: one contaminated directory cut.
- **Why it's a problem:** CATEGORICAL FACT — there is NO v11.1 cut; phase-parts is v11.0. The "frozen / Convention Y / USER-LOCKED" premise is rejected by `ARCHITECTURE-BD-185-V2.md` §11 CR-1 (v11.0 unshipped → archive mutable; BD-193 already mutated it). The INDEX both encodes the mislabel AND fabricates edits that never happened.
- **Recommended action (as researchers stated):** Per `ARCHITECTURE-BD-185-V2.md` §10 Groups A/B/C — (A) RELOCATE the phase-part SCHEMA to `v11.0/phase-part-v11.0/SCHEMA.md`, correct the version tag everywhere, KEEP grammar verbatim, fix §5 sibling cross-refs on co-location; (B) RETIRE `v11.1/INDEX.md`, fold the phase-part row into `v11.0/INDEX.md` with `phase-part-v11.0` tags, remove the Convention-Y/frozen/bump/D1–D16 content; (C) RETIRE the duplicate form, UPDATE the existing `v11.0/forms/work-item.yml` to the current 4-option project-template shape (markers stay `work-item-v11.0`). No script consumes the SCHEMA path (verified) — zero code-consumer blast radius.
- **Cross-surface coupling:** `v11.0/INDEX.md` (gains the phase-part row; P-23 reword rides along); `scripts/validate-pack.py check_template_archive_v11()` must add `"phase-part"` to its 5-type loop once the v11.0 cut gains the 6th type (P-12). `pack-ops/BACKLOG.md` carries stale `templates-archive/v11.1/...` path prose (P-22, PM-only). The §10 / PLAN-V2 §6 recipes that drive this fix carry bare archive paths that must be normalized first (P-13).

### P-03 — README maintenance-docs/ layout is materially stale after the Step-2 prison move
- **Severity:** MUST
- **Surfaces:** `README.md` § "Repository Layout" → `maintenance-docs/` block. Lists relocated files `GEMINI-CLI-ANALYSIS.md` + `ANDROID-ANALYSIS.md` as present (both moved to `prison/` in Step 2, commit `4a3f5e2`); omits the two largest live subdirs `v11-implementation/` (193 entries) + `v11-research/` (64 entries) and `prison/`.
- **Found by:** R1-F03.
- **Why it's a problem:** CLAUDE.md § "Repo structure" designates the README layout as "the authoritative reference"; it lists prison-moved files as present and omits the directories holding all active v11 work. This is a stale-layout-after-Step-2 defect (not a v11.1 issue).
- **Recommended action (as researchers stated):** Drop the `GEMINI-CLI-ANALYSIS.md` / `ANDROID-ANALYSIS.md` root lines; add `v11-implementation/` + `v11-research/` subdir lines; either add a one-line `prison/` entry or deliberately omit it with rationale. PM-only edit.
- **Cross-surface coupling:** none beyond README (PM-only). Compounds the README-currency cluster (P-04, P-05, P-19, P-20).

### P-08 — BD-193 review + Phase-5 remediation BLESSED and DEEPENED the v11.1 mislabel (propagation; correction targets)
- **Severity:** MUST
- **Surfaces:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md` §3.1.2 + §4.7 M-5 (graded the v11.1 INDEX heading + phase-part-v11.1 row "CONFIRMED-CORRECT"; recommended creating the "v11.1 archive cut"); `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` §4 S-1 (rewrote the v11.1 INDEX forms paragraph to deepen the "v11.1 archive cut" framing).
- **Found by:** R7-F09.
- **Why it's a problem:** CATEGORICAL FACT — both passes treated the nonexistent "v11.1 archive cut" as a legitimate future deliverable, blessing (review) and deepening (remediation) the mislabel during Code Red 2 instead of catching it. The Phase-5 S-1 edits are themselves correction targets (V2 §10 Group B). BD-193's in-scope work (per-surface wi-type split, `bd`-removal carve-out) is correct and retained — only the v11.1 framing it propagated is the issue.
- **Recommended action (as researchers stated):** When the P-02 corrections land, ensure the Phase-5 S-1 language + Phase-4 §3.1.2 "CONFIRMED-CORRECT" verdict are explicitly reversed (the blessed source `v11.1/INDEX.md` is retired). As workflow artifacts these sweep to archive (Pattern B) and may stay as historical record of the propagation; record this as a missed-finding so the review process learns the v11.0/v11.1 categorical check.
- **Cross-surface coupling:** `v11.1/INDEX.md` (the blessed surface, P-02); BD-195 missed-finding ledger.

---

## THEME B — pack/project boundary & client-shipped dead references

### P-04 — `docs/pack/PM-CHAT.md` cites a client-side `docs/pack/MERGE-STRATEGY.md` that is never installed
- **Severity:** MUST
- **Surfaces:** `project-template/docs/pack/PM-CHAT.md` § "Recommendation routing (v11+)". Primary path `docs/pack/MERGE-STRATEGY.md` resolves to nothing at a client install (file exists ONLY at `pack-ops/MERGE-STRATEGY.md`; absent from `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES`; S6 globs don't copy it).
- **Found by:** R3-F01.
- **Why it's a problem:** A client-shipped file points the PM chat at a `docs/pack/` path that resolves to nothing (cross-reference integrity) and surfaces a pack-only artifact as a client `docs/pack/` path (separation-of-concerns). The same content is referenced correctly one file over in `OPTIONAL-FEATURES.md` ("See `MERGE-STRATEGY.md` in the pack repo").
- **Recommended action (as researchers stated):** Drop the `docs/pack/MERGE-STRATEGY.md` primary path; make the pack-side qualification primary (mirror OPTIONAL-FEATURES.md: "see `MERGE-STRATEGY.md` in the pack repo (`pack-ops/MERGE-STRATEGY.md`)"), kept DENY-LIST-wrapped. Do NOT add MERGE-STRATEGY.md to the client inventory — it is pack-internal design material.
- **Cross-surface coupling:** `pack-ops/MERGE-STRATEGY.md` (the real target); `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES`. Same MERGE-STRATEGY mis-filing surfaces in README (P-05, R1-F01).

### P-05 — `.mcp.json.example` points clients at pack-only `supporting-docs/CLI-PM-SETUP.md` that is never installed
- **Severity:** MUST
- **Surfaces:** `project-template/.mcp.json.example` `_readme` / `local-rag.env._readme`: "See supporting-docs/CLI-PM-SETUP.md for setup instructions." Client-shipped (in `test-fixtures/v11-flat-file/`); `CLI-PM-SETUP.md` lives only at pack `supporting-docs/` and is NOT copied to clients (init-project.sh copies only METHODOLOGY.md + INSTALL-PROCEDURES.md from `supporting-docs/`).
- **Found by:** R4-F01.
- **Why it's a problem:** Dead client cross-reference + pack/project separation violation (`feedback_pack_project_separation_of_concerns`) + client-facing token economy (`feedback_client_facing_token_economy`) — a pack-only path on a RAG/client surface. At a client there is no `supporting-docs/` dir.
- **Recommended action (as researchers stated):** Replace with the client-installed equivalent (`docs/pack/INSTALL-PROCEDURES.md` if it carries local-rag setup, or `docs/pack/PM-CHAT.md` § RAG ingestion manifest) or drop the "See …" sentence and inline the one-line instruction. Confirm the target exists at client install before re-pointing.
- **Cross-surface coupling:** segment owning `supporting-docs/CLI-PM-SETUP.md` (verify whether that doc should be split client/pack); `docs/pack/` client docs. Same dead-pack-doc class as P-06, P-07 (R4-F02/F03).

### P-06 — Client-shipped Codex config example leaks a pack-internal maintenance doc + raw commit SHA
- **Severity:** MUST
- **Surfaces:** `project-template/.codex/config.toml.example` header comment: "# Source: V10-CODEX-MCP-RESEARCH.md (commit 73d480e). …". Client-shipped (in fixture); `V10-CODEX-MCP-RESEARCH.md` lives only at pack `maintenance-docs/` (never at a client).
- **Found by:** R4-F02.
- **Why it's a problem:** Citing a pack maintenance-doc + raw SHA on a client surface violates deliverable-only / separation-of-concerns and wastes RAG tokens at client query time. The reader at a client has no doc to follow and no repo to resolve `73d480e`.
- **Recommended action (as researchers stated):** Remove the "Source: V10-CODEX-MCP-RESEARCH.md (commit 73d480e)" provenance line; KEEP the substantive client-useful guidance (STDIO via `command`, HTTP gated by `experimental_use_rmcp_client`); move provenance to pack-internal authoring history if needed. Bundle with the R4-F07 "v10 ships STDIO only" label fix (P-29) in the same file edit.
- **Cross-surface coupling:** segment owning `maintenance-docs/V10-CODEX-MCP-RESEARCH.md`.

### P-09 — `PACK-REVIEW-BD-185-H.2.md` is UNTRACKED, anchors to a now-PRISONED plan, and cites v11.1 archive paths as the legitimate spec
- **Severity:** MUST
- **Surfaces:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md` §1 (spec anchor `PLAN-BD-185-ADDENDUM.md` §4.2 — now in `maintenance-docs/prison/`); ENCODING-surface citations listing `templates-archive/v11.1/...` paths as correct; reproduces "introduced at v11.1" framing. UNTRACKED (`git status` → `??`).
- **Found by:** R7-F10.
- **Why it's a problem:** (1) Its spec anchor is a prisoned/superseded doc (PRISON RULE → stale-ref). (2) It treats the contaminated `v11.1/` paths as the legitimate spec and reproduces the v11.1 framing without flagging it (propagation class, same as P-08). (3) Untracked → no committed provenance; a same-named tracked variant may exist (provenance ambiguity). Its functional verdicts match V2 §2.C as correct — the anchor and framing are the issue.
- **Recommended action (as researchers stated):** The supersession-map / disposition pass owns this doc (track vs prison vs leave). It should NOT be treated as a live spec or a clean review; if retained as historical, it sweeps to archive (Pattern B). Researcher flags but does not decide disposition — surfaced as an OPEN QUESTION.
- **Cross-surface coupling:** `maintenance-docs/prison/PLAN-BD-185-ADDENDUM.md` (do NOT read/cite); supersession-map disposition owner; any tracked same-named variant.

### P-10 — README pack-ops/ block omits three resident files; mis-files MERGE-STRATEGY + DRY-RUN-MIGRATION under supporting-docs/
- **Severity:** MUST
- **Surfaces:** `README.md` § "Repository Layout" — the `supporting-docs/` block wrongly lists `MERGE-STRATEGY.md` + `DRY-RUN-MIGRATION.md` (both live ONLY in `pack-ops/`); the `pack-ops/` block omits `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`, `MERGE-STRATEGY.md` (all resident there).
- **Found by:** R1-F01, R1-F02. Merged: two halves of one README pack-ops/-vs-supporting-docs/ mis-filing defect.
- **Why it's a problem:** README is the designated authoritative layout (CLAUDE.md § "Repo structure"); mis-filing contradicts the canonical `pack-ops/BOUNDARY-DEFINITION.md` §5 content rules (BD-175 F-1 resolution; the §5.1 sub-section was collapsed into the flat §5 Ban-A/separated-not-combined bullets by BD-196) and renders three resident files invisible. QUICKSTART.md already uses the correct `pack-ops/MERGE-STRATEGY.md`.
- **Recommended action (as researchers stated):** Move the two mis-filed entries from the README `supporting-docs/` block to the `pack-ops/` block; add the three omitted resident files to the `pack-ops/` block. PM-only edit. BOUNDARY-DEFINITION.md §5 (content rules) is the SSOT.
- **Cross-surface coupling:** none beyond README (PM-only); compounds the README-currency cluster (P-03, P-04, P-19, P-20).

### P-11 — PACK-CHAT.md says "Four pack agents" but there are five (omits pack-coder)
- **Severity:** MUST
- **Surfaces:** `pack-ops/PACK-CHAT.md` § "Behavioral rules" → "Delegate to pack agents" bullet ("Four pack agents exist … architect, planner, reviewer, docs-researcher"). Contradicts `pack-ops/PACK-AGENTS.md` ("Five dedicated agents") and the on-disk roster (5 in each of `.claude/.codex/.gemini/agents/`).
- **Found by:** R1-F04.
- **Why it's a problem:** Direct contradiction between two pack-self governance surfaces; PACK-AGENTS.md's "Keeping … current" rule requires accuracy. An agent reading PACK-CHAT.md would conclude pack-coder is not delegable.
- **Recommended action (as researchers stated):** Change "Four" to "Five" and add `pack-coder` to the enumerated list. PM-only edit (PACK-CHAT.md).
- **Cross-surface coupling:** PACK-AGENTS.md is the authoritative roster (no edit needed there — it is already correct).

---

## THEME C — prison stale-refs (live docs citing Step-2-prisoned docs)

### P-14 — Completed-batch 19c workflow artifacts forward-reference now-prisoned 19c V1 / PRINCIPLE-CHECK / DISCARDED as live inputs
- **Severity:** SHOULD
- **Surfaces:** `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` (L7 "V1 is retained as a historical input"; §A.2 items 1–9 cite PRINCIPLE-CHECK); `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md`; `AUDIT-PRE-19C-BOUNDARY-LEAKS.md`; `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md`; `RESEARCH-BATCH-19B-STRATEGIC-RULES.md`; `PLAN-CLEANUP-BATCH-19C.md`; `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`; the `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.*` set — all cite 19C V1 / PRINCIPLE-CHECK / DISCARDED, now in `maintenance-docs/prison/`. BD-173 is Resolved.
- **Found by:** R8-F06.
- **Why it's a problem:** Per the PRISON RULE, live in-tree docs treating a prisoned doc as a "retained historical input" or active assessment target are stale-refs. The supersession map was authored when "the prison directory does not yet exist," so the chain now resolves into prison.
- **Recommended action (as researchers stated):** Two viable paths (researcher leaves the choice to the user): (a) at version-ship Pattern-B sweep, move the whole 19c-family artifact set to `archive/v11/` together (preferred — Resolved-batch records); OR (b) if any remains live, annotate the prisoned-doc citations as "superseded; now in `maintenance-docs/prison/`". Do NOT leave live docs describing prisoned docs as "retained historical input."
- **Cross-surface coupling:** prison docs are out of scope (never edit). `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` is the superseding doc, stays live until the sweep.

### P-15 — Per-entry-split + V3.x chain reference now-prisoned ARCHITECTURE-V3.2-DELTA.md as "remains in the directory" / authoritative-design
- **Severity:** SHOULD
- **Surfaces:** `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` (§0 supersession line); `ARCHITECTURE-REVIEW-PASS3.md` (§4.2 "V3.2-DELTA itself remains in the directory"); `RESEARCH-PER-ENTRY-SPLIT.md` (front-matter `authoritative-design:` lists V3.2; corpus lines); `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`; `REVIEW-RESEARCH-PER-ENTRY-SPLIT.md`; `PACK-REVIEW-CUMULATIVE-V11-POSTSWEEP.md`; `PACK-REVIEW-BD-106.md`. `ARCHITECTURE-V3.2-DELTA.md` is now in `maintenance-docs/prison/`.
- **Found by:** R8-F07. Also touched in code by R5-F04 (see P-21 — same prisoned doc, different surfaces).
- **Why it's a problem:** Supersession is correctly recorded (V3.2 → V3.3) but multiple in-tree docs assert V3.2-DELTA "remains in the directory" / list it as authoritative-design — both now false (prisoned). The `RESEARCH-PER-ENTRY-SPLIT.md` `authoritative-design:` front-matter is the sharpest (presents a prisoned doc as authoritative).
- **Recommended action (as researchers stated):** Where a doc asserts V3.2-DELTA "remains in the directory," correct to "superseded by V3.3-DELTA; now in `maintenance-docs/prison/`." Drop V3.2 from any `authoritative-design:` enumeration. Cross-ref/consulted-list mentions inside completed review artifacts may instead ride the Pattern-B ship sweep. User decides per-surface.
- **Cross-surface coupling:** `ARCHITECTURE-V3.2-DELTA.md` is prison (never edit). Shares the prisoned target with P-21 (R5-F04 lib headers).

### P-21 — Two lib headers cite now-prisoned ARCHITECTURE-V3.2-DELTA.md at its pre-prison path
- **Severity:** NIT
- **Surfaces:** `scripts/lib/tracker-migrate-forward.sh` (mapping-helpers header) and `scripts/lib/tracker-phase-task.sh` ("Reference:" header) cite `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md §4.1` (now in `prison/`; no non-prison copy).
- **Found by:** R5-F04.
- **Why it's a problem:** Prisoned-doc citation at a path that no longer resolves (PRISON RULE). Low severity — both comments already note content was "carried forward unchanged in V3.3" and cite the live V3.3-DELTA alongside, so the load-bearing reference is intact.
- **Recommended action (as researchers stated):** Drop the `ARCHITECTURE-V3.2-DELTA.md` citations; rely on the live `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` §4.1 (and §4.1–§4.3) which both comments already reference.
- **Cross-surface coupling:** Same prisoned target as P-15 (R8 docs). Touches `scripts/` → manifest-regen + per-check tests apply per PREFLIGHT.

### P-25 — TOOL-COMPARISON.md points at GEMINI-CLI-ANALYSIS.md / ANDROID-ANALYSIS.md at their pre-prison path
- **Severity:** NIT
- **Surfaces:** `maintenance-docs/TOOL-COMPARISON.md` (L5–6 "Supersedes:" header; L217–219 "Deprecated analysis documents"). Both named files are now in `maintenance-docs/prison/`, not `maintenance-docs/`; `V9-DESIGN.md` (also cited) is at `archive/`, not root.
- **Found by:** R8-F05.
- **Why it's a problem:** In-tree refs should point AWAY from prisoned docs, never describe them as live "in the repo for historical reference" at a path where they no longer sit. The supersession FACT is correct; the path and "remain in the repo" framing are stale.
- **Recommended action (as researchers stated):** Update the references to note these are superseded-and-prisoned (or drop the path and keep only "content absorbed here"). Do not cite the prison path as a live reference.
- **Cross-surface coupling:** the two named docs are prison (do not edit); TOOL-COMPARISON edit is in-scope.

---

## THEME D — README / version-currency staleness (v10/v9 labels on a v11 pack)

### P-12 — `check_template_archive_v11()` enumerates only 5 entry types; missing `phase-part`
- **Severity:** SHOULD
- **Surfaces:** `scripts/validate-pack.py` `check_template_archive_v11()` — entry-type loop (5 types: bd/td/phase-epic/phase-task/inbound) + docstring; `archive_root` already correctly encodes `…/templates-archive/v11.0`.
- **Found by:** R7-F05.
- **Why it's a problem:** Once the phase-part SCHEMA relocates into the v11.0 cut (P-02), this check must verify `v11.0/phase-part-v11.0/SCHEMA.md` exists or the archive report is incomplete and the new entry type unchecked. INFO/soft-style check (won't hard-fail CI) → SHOULD; but it is an ENCODING surface that must move in lock-step with the archive (V2 §10 Group E).
- **Recommended action (as researchers stated):** Add `"phase-part"` to the entry-type loop (6 types); update the docstring; function name + `v11.0` target stay correct. Manifest regen + per-check tests apply.
- **Cross-surface coupling:** depends on P-02 (the relocation creating `v11.0/phase-part-v11.0/SCHEMA.md`); `test-fixtures/manifest.txt`. Touches `scripts/`.

### P-13 — `ARCHITECTURE-BD-185-V2.md` §10 + `PLAN-BD-185-V2.md` §6 recipes cite BARE `templates-archive/...` paths
- **Severity:** SHOULD
- **Surfaces:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` §10 Groups A–C; `PLAN-BD-185-V2.md` §6 commit recipes + §10 commit-A table. They cite `templates-archive/v11.1/...` dropping the `maintenance-docs/v11-research/` prefix; no repo-root `templates-archive/` exists.
- **Found by:** R7-F07.
- **Why it's a problem:** A coder executing a §10/§6 recipe against a literal `templates-archive/...` path would fail. Collides with the filename/path-uniqueness posture. Recoverable (PLAN-V2 §2 inventory + `validate-pack.py:1226` carry the full path) → SHOULD not BLOCKER, but the step-by-step recipes a coder follows are the bare form.
- **Recommended action (as researchers stated):** Before any coder executes the P-02 corrections, normalize the bare `templates-archive/...` citations to full `maintenance-docs/v11-research/templates-archive/...` paths in the recipe prose (or add a one-line "all archive paths are relative to `maintenance-docs/v11-research/`" preamble). Confirm the canonical archive location is nested (validator says nested) — do NOT silently relocate the archive to repo root.
- **Cross-surface coupling:** This is a PRECONDITION for executing P-02 cleanly. `scripts/validate-pack.py:1226` is the path authority.

### P-16 — `ARCHITECTURE-BD-185-V2.md` carries NO forward "superseded-by ordering addendum" pointer
- **Severity:** SHOULD
- **Surfaces:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` header / §0 / §5.1 / §3 D-8 / §7 ordering-ops table. The ordering subsystem (Issue-Fields-primary) is presented as live; the demotion to gated-OFF + sub-issue-reprioritize default exists ONLY in `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0.1 (backward pointer only).
- **Found by:** R7-F08.
- **Why it's a problem:** The supersession is one-directional. A reader opening V2 first ("Authoritative. Standalone.") and reading §5.1/D-8 has no in-doc signal the ordering subsystem is superseded — the lock-step-between-paired-docs gap that produces stale-design execution. (`PLAN-BD-185-V2.md` §0.1 carries the correct reconciliation, so the plan is safe; V2 read in isolation is not.)
- **Recommended action (as researchers stated):** Add a forward pointer to V2 (header status line or a §0 note): "the tracker-mode execution-ordering subsystem (§5.1/§5.2, D-7 mechanism clause, D-8, §7 ordering ops, §6 ordering reads/writes) is SUPERSEDED by `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0.1; that addendum wins for ordering, this doc for all else." Held untracked design doc — correctable before BD-185 restart.
- **Cross-surface coupling:** `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` (superseding doc); `PLAN-BD-185-V2.md` §0.1 (correct reconciliation).

### P-17 — Six BD-185 IMPL reports carry the v11.1 mislabel framing and reference now-prisoned docs (group)
- **Severity:** SHOULD
- **Surfaces:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md` (38 v11.1 / 19 prisoned-refs), `-Batch-19d-H.2.md` (22/13), `-H.1-NITS.md` (21/0), `-POST-PLANNER-POQS.md` (26/24), `-ARCHITECT-DOC-EDITS.md` (8/9), `-ARCHITECT-DOC-REVIEW-FIXES.md` (2/22). Prisoned refs: `ARCHITECTURE-BD-185.md`, `PLAN-BD-185.md`, `PLAN-BD-185-ADDENDUM.md`, `ARCHITECTURE-BD-185-RECONCILIATION.md`.
- **Found by:** R7-F12.
- **Why it's a problem:** These reports document the contaminated BD-185 attempt; their v11.1 framing is the mislabel and their prisoned-doc refs are stale. Per V2 §10 Group H these are Pattern-B archive-sweep workflow artifacts — a historical record of "what was done, including the error."
- **Recommended action (as researchers stated):** Treat as a group; confirm Pattern-B disposition (archive-sweep, NOT edit) with the user. If the BD-195 "pristine" bar requires the active `v11-implementation/` tree to be free of contaminated attempt-records, move them to `maintenance-docs/archive/v11/` (or prison if deemed contaminated-superseded) per the supersession-map pass. Do NOT individually de-contaminate prose in archived workflow artifacts (rewriting history loses the audit trail). Surfaced as an OPEN QUESTION (pristine bar definition).
- **Cross-surface coupling:** supersession-map disposition owner; prison docs they reference (do not cite); BD-195 "pristine state" definition.

### P-18 — `PACK-REVIEW-BD-185-H.1.md` blesses the v11.1 mislabel and anchors to two now-prisoned docs
- **Severity:** SHOULD
- **Surfaces:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.1.md` pipeline header (anchors to `ARCHITECTURE-BD-185.md` + `PLAN-BD-185.md`, both prisoned); §1/§3.1/§3.2 affirm "the v11.1 templates-archive cut … the new `phase-part-v11.1` entry type" as correct; references the `work-item-v11.1` bump as expected.
- **Found by:** R7-F11.
- **Why it's a problem:** Stale-ref-to-prisoned anchors + same propagation class as P-08/P-09 (blessed H.1's v11.1 framing rather than catching it). SHOULD because it is a completed historical review whose disposition is Pattern-B archive (gates nothing live).
- **Recommended action (as researchers stated):** Record as a propagation instance for the BD-195 missed-finding ledger; leave as historical record (Pattern-B archive sweep). Do NOT treat its CONFIRMED-CORRECT verdicts on the v11.1 framing as authoritative. Its NIT-1/NIT-2 (stale architect-doc cites in the SCHEMA) overlap the P-02 SCHEMA cross-ref cleanup.
- **Cross-surface coupling:** `maintenance-docs/prison/ARCHITECTURE-BD-185.md` + `PLAN-BD-185.md` (do not cite); P-02 (SCHEMA cross-ref NITs); missed-finding ledger.

### P-19 — `docs/pack/PACK-FEEDBACK.md` is stamped/operated as v9 throughout (client-shipped, v11)
- **Severity:** SHOULD
- **Surfaces:** `project-template/docs/pack/PACK-FEEDBACK.md` — Status row `Pack version in use | v9.[N]`; "broken v9 defect"; Q1–Q6 `[v9 release date]` seed-stamps; "while using v9" (17 `v9` occurrences). Header declares "AI Agent Config Pack v11".
- **Found by:** R3-F02.
- **Why it's a problem:** Lens A — pack is v11.0; a v11 install ships a feedback log telling the PM chat the pack is v9.
- **Recommended action (as researchers stated):** Bump `Pack version in use` default to `v11.[N]` (or neutral `[pack version]`); "broken v9 defect" → "broken pack defect"; re-stamp Q1–Q6 to v11/neutral; make the seed-context block version-neutral. Confirm with user whether the v9-auditor-split seed set is still the intended v11 seed (the split still ships in v11) — OPEN QUESTION.
- **Cross-surface coupling:** part of the client-shipped v-currency sweep (P-19, P-20, P-26, P-27); coordinate with `supporting-docs/METHODOLOGY.md` Part 10 (stamped v10 — see P-22 note).

### P-20 — Three client-shipped surfaces with stale v10 version prose / misdirected migrator
- **Severity:** SHOULD
- **Surfaces (merged):**
  - `project-template/docs/pack/prompts/pm-chat.md` — kickoff hardcodes "Pack version: AI Agent Config Pack v10" (R3-F03).
  - `project-template/docs/pack/HELP-FRAGMENT.md` § "Project commands" — lists `migrate-v9-to-v10.sh` as the prominent migrator with "v10→v11 migrator ships separately" (inaccurate — `scripts/migrate-v10-to-v11.sh` is in the same `scripts/`) (R3-F05).
  - `project-template/skills/pm-startup/SKILL.md` Step 4 ("Default manifest in v10 …") + its 3 distributed copies (`.claude/.codex` skills, `.gemini/commands/pm-startup.toml`) (R4-F05).
- **Found by:** R3-F03, R3-F05, R4-F05. Merged: client-shipped v10-prose-currency class.
- **Why it's a problem:** Lens A — v11 client surfaces assert v10 (kickoff version, default-manifest prose) or foreground the prior-cycle migrator and call the current migrator "ships separately."
- **Recommended action (as researchers stated):** pm-chat.md → `[pack version, e.g. v11.0]` (match surrounding placeholders); HELP-FRAGMENT.md → make `migrate-v10-to-v11.sh` the listed migrator, drop "ships separately", optionally list v9→v10 as secondary; pm-startup Step 4 → version-neutral "The default manifest is exactly one path: `docs/pack/METHODOLOGY.md`" applied to canonical + all 3 distributed copies in the same edit (parity).
- **Cross-surface coupling:** pm-startup canonical + 3 distributed copies move in lock-step. The HELP-FRAGMENT v9→v10 sunset theme also surfaces pack-side (P-24, R1-F05) and in QUICKSTART (R1 closing note) — see OPEN QUESTION on sunset-artifact policy.

### P-22 — `tracker-migrate-forward.sh` client BACKLOG/PLAN path resolution diverges from the pack's own canonical client layout
- **Severity:** SHOULD
- **Surfaces:** `scripts/lib/tracker-migrate-forward.sh` — client-surface `backlog_path="$repo_root/BACKLOG.md"` + `plan_path="$repo_root/IMPLEMENTATION-PLAN.md"` (repo-root only). Pack's canonical client mirrors are `docs/project/BACKLOG.md` + `docs/project/IMPLEMENTATION-PLAN.md` (per-entry `_rules.md`; init-project.sh installs empty mirrors there). `scripts/lib/detect.sh::detect_pack_surface` correctly probes `docs/project/BACKLOG.md` — so detection knows the v11 client layout but forward-migrate's client branch reads ONLY repo-root. The reverse counterpart documents repo-root emit as deliberate pre-v10 back-compat; forward has no such note.
- **Found by:** R5-F03 (source); R6-F02 cross-ref note flags the forward-migrate fixtures place BACKLOG.md at fixture root (may encode the same assumption).
- **Why it's a problem:** Internal inconsistency — if forward client branch is intentional back-compat (like reverse) it should SAY so; if not, forward silently parses zero entries/phases for a correctly-laid-out v11 client. Either way the asymmetry is undocumented on the forward side.
- **Recommended action (as researchers stated):** Reconcile forward client-path resolution with detect.sh's candidate order (probe `docs/project/BACKLOG.md` then repo-root fallback) OR add an explicit comment mirroring the reverse back-compat rationale. Architect-level call on which — surface to user (OPEN QUESTION). Re-check forward-migrate fixtures (R6) once decided.
- **Cross-surface coupling:** `scripts/lib/tracker-migrate-reverse.sh` (documented back-compat counterpart); `scripts/lib/detect.sh`; forward-migrate test fixtures at `scripts/tests/fixtures/tracker-migrate/` (Lens-E pairing with R6). Pairs with P-23 (dead fallback in the same function).

---

## THEME E — pack-self agent/skill parity & stale refs

### P-07 — pack-root pack-help skill cites moved docs by stale bare name (Claude + Codex), diverging from the already-correct Gemini command
- **Severity:** MUST
- **Surfaces:** `.claude/skills/pack-help/SKILL.md` + `.codex/skills/pack-help/SKILL.md` "## Notes" block — cite bare `PACK-CHAT.md` and `OPTIONAL-FEATURES.md` (neither resolves at pack root; both live at `pack-ops/`). The sibling `.gemini/commands/pack-help.toml` already cites the correct `pack-ops/...` paths.
- **Found by:** R2-F01.
- **Why it's a problem:** Dead cross-references — a BD-175 reorg leftover (commit `59a7dbb` moved the docs under `pack-ops/` and updated the Gemini command but not the Claude/Codex skills). Violates filename-uniqueness ("references must resolve") and the quad-parity expectation (Gemini diverges with the correct value). Exactly the BD-195 Step-3 target class (stale reference from a prior reorg).
- **Recommended action (as researchers stated):** In both `.claude/skills/pack-help/SKILL.md` and `.codex/skills/pack-help/SKILL.md`, change `PACK-CHAT.md`, `OPTIONAL-FEATURES.md` → `pack-ops/PACK-CHAT.md`, `pack-ops/OPTIONAL-FEATURES.md` (match the already-correct Gemini command). Leave `QUICKSTART.md` + `README.md` bare. Gemini needs no change.
- **Cross-surface coupling:** 2 of 3 pack-help surfaces (Gemini is the reference value). Do NOT byte-copy the project-side pack-help quad (which correctly uses `docs/pack/PM-CHAT.md` for its own audience).

### P-26 — pack-planner: substantive "state-verifiable questions" rule present only in the Claude version
- **Severity:** SHOULD
- **Surfaces:** `.claude/agents/pack-planner.md` Responsibilities ("State-verifiable questions are not `MAINTAINER CHECK NEEDED` items" rule); ABSENT from `.codex/agents/pack-planner.toml` `developer_instructions` and `.gemini/agents/pack-planner.md`. Minor secondary: `description` field "cross-doc consistency checks" present in Claude+Gemini, omitted in Codex.
- **Found by:** R2-F02.
- **Why it's a problem:** Content-bearing planner behavior (how to treat state-verifiable vs maintainer-check questions), not a tool-specific construct → unjustified trinity asymmetry (CLAUDE.md § "Trinity rule" + commit-discipline skill §5). A Codex/Gemini pack-planner would mis-route state queries to MAINTAINER CHECK that the Claude one answers directly.
- **Recommended action (as researchers stated):** Add the rule to the Codex `developer_instructions` + Gemini agent body, mirroring the Claude wording (adapt only mechanical formatting). Align the `description` "cross-doc consistency checks" phrase across all three. Confirm whether intentionally Claude-only (unlikely — reads as universal planner discipline); default is propagate to all three.
- **Cross-surface coupling:** the three pack-planner files (trinity-style parity). Pack-self only.

### P-27 — commit-discipline skill cites `agent-run.sh` as a pack-side Codex example, but it does not exist pack-side
- **Severity:** NIT
- **Surfaces:** `.claude/skills/commit-discipline/SKILL.md` §5 "Trinity rule cross-reference" (+ byte-identical `.codex/` + `.gemini/` mirrors): "…Codex's `agent-run.sh` references…". Per CLAUDE.md the pack repo has no `agent-run.sh` (project-template helper only).
- **Found by:** R2-F03.
- **Why it's a problem:** Names a project-template helper as if it were a Codex pack-side invocation mechanism, on a pack-self skill. Illustrative (no live path broken) but mildly misleading and conflicts with CLAUDE.md's explicit disclaimer. Low confidence — the in-context reading is defensible (the surrounding clause is about the project-template trinity, where `agent-run.sh` IS correct).
- **Recommended action (as researchers stated):** Optional. Either (a) qualify as project-side ("Codex's project-template `agent-run.sh` references") or (b) replace the Codex example with a pack-side-applicable tweak (Codex TOML `developer_instructions` vs Claude/Gemini markdown frontmatter). Byte-identical across CLIs → any edit lands in all three (quad/trinity).
- **Cross-surface coupling:** all three commit-discipline mirrors (byte-identical).

---

## THEME F — companion templates (Xcode / VS Code)

### P-28 — Xcode Codex `config.toml` declares 7 agents whose `config_file` targets are never shipped or installed
- **Severity:** MUST
- **Surfaces:** `xcode-companion-templates/Codex/config.toml` (`[agents.*]` blocks → `config_file = "agents/*.toml"`); install blocks at `supporting-docs/SETUP-NEW.md` § 5.D, `supporting-docs/SETUP_TEMPLATE.md` Xcode copy block, `xcode-companion-templates/README.md` § Installation. There is NO `agents/` subdir in the template, and the install blocks copy only `Codex/AGENTS.md` + `Codex/config.toml` — so all 7 `config_file` paths point at files that do not exist at the install target.
- **Found by:** R9-F01.
- **Why it's a problem:** Codex resolves `config_file` relative to the config location; the referenced agent tomls are absent both in the template dir and at install → every declared sub-agent fails to load. Broken cross-reference in a client-shipped template (pre-existing, not version-related). `project-template/.codex/` honors the "ship the referenced agent files" contract; the Xcode companion violates it.
- **Recommended action (as researchers stated):** Either (a) add `xcode-companion-templates/Codex/agents/` shipping the 7 referenced tomls and extend the README + SETUP-NEW.md + SETUP_TEMPLATE.md install blocks to copy the `agents/` dir; OR (b) remove the `[agents.*]` blocks if machine-level Xcode Codex is intentionally agent-less. Decision belongs to the user — confirm whether Xcode-level Codex supports sub-agents at all (OPEN QUESTION).
- **Cross-surface coupling:** `supporting-docs/SETUP-NEW.md` + `SETUP_TEMPLATE.md` install blocks (if option a); `project-template/.codex/` (reference contract).

### P-23 — `tracker-migrate-forward.sh` has a dead fallback to a nonexistent `maintenance-docs/IMPLEMENTATION-PLAN.md`
- **Severity:** SHOULD
- **Surfaces:** `scripts/lib/tracker-migrate-forward.sh` — Step 1+2 `plan_path` assignment: fallback `[[ ! -f "$plan_path" ]] && plan_path="$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md"`. No such file exists anywhere in the repo (the pack plan corpus lives under `maintenance-docs/v11-implementation/`). The fallback can only resolve to a missing path → `phases='[]'`. Guarded (no crash) → SHOULD not BLOCKER.
- **Found by:** R5-F02.
- **Why it's a problem:** Stale reference that pretends a pack-side plan location exists.
- **Recommended action (as researchers stated):** Remove the dead `maintenance-docs/IMPLEMENTATION-PLAN.md` fallback line (simplest correct fix), OR repoint to an actual pack plan mirror if pack-surface forward-migration is intended to read one (none exists at that name today — pack uses BD-tracked backlog).
- **Cross-surface coupling:** Same function as P-22; R6 forward-migrate tests that assert the fallback path resolution should be re-checked once removed (Lens-E). Touches `scripts/`.

---

## THEME G — pack-self help/reference precision & boundary nuance (NIT cluster)

### P-24 — Pack-side surfaces advertise sunset v9→v10 migrator as live verbs
- **Severity:** SHOULD
- **Surfaces (merged):**
  - `pack-ops/HELP-FRAGMENT-PACK.md` § "Pack scripts" — `scripts/migrate-v9-to-v10.sh` row presented as a live verb (script absent at v11 HEAD; sunset per BD-121) (R1-F05).
  - `QUICKSTART.md` line 34 — links `supporting-docs/MIGRATION-v9-to-v10.md` which does not exist (sunset per BD-121); one of two migration paths offered (R1 closing note).
- **Found by:** R1-F05 (+ R1 closing note for QUICKSTART). Merged: v9→v10 sunset-artifact-on-live-surface class.
- **Why it's a problem:** `pack help` / `/pack-help` renders a runnable command for a script that does not exist at v11 HEAD → file-not-found for the user; QUICKSTART links a sunset migration guide. README's mention is in the historical v10.0 version-history row (acceptable); the help fragment + QUICKSTART present them as current.
- **Recommended action (as researchers stated):** Remove the HELP-FRAGMENT-PACK row (or replace with a "(sunset in v11 per BD-121 — recover from `git checkout v10`)" note that does not present a live verb); decide whether QUICKSTART's v9→v10 sunset link should be scrubbed. Researcher low-confidence on severity — surfaced as part of the sunset-artifact policy OPEN QUESTION.
- **Cross-surface coupling:** README v10.0 version-history row is the acceptable historical home (no edit).

### P-29 — Lower-priority NITs (grouped — minor staleness / precision, each low blast-radius)
This record groups eight NIT findings that share "minor, low-impact, surface-to-user-don't-auto-apply" character. Each is listed with its own surfaces/source so none is lost; they are NOT a single fix.

- **P-29a — BOUNDARY-DEFINITION.md §6 declares a discoverability cross-reference network whose pack-self pointers do not exist.** SHOULD. `pack-ops/BOUNDARY-DEFINITION.md` §6.1/§6.2/§6.4 assert one-line pointers in README, PACK-CHAT.md, PACK-AGENTS.md, and pack-trinity pack-memory; none exist on the R1-owned surfaces. Found by R1-F06. Action (as stated): either add the declared pointers (trinity in lock-step) OR downgrade §6 to aspirational and drop the "discoverability invariant" claim — architect pass (touches trinity). Coupling: §6.2 also claims a pointer in each pack-* agent read-list and in project-side PM-CHAT.md — verify those (cross-segment). [Severity SHOULD; grouped here as a single boundary-self-consistency record.]
- **P-29b — CONCEPTUAL-REVIEW-METHODOLOGY.md references a nonexistent `ARCHITECTURE-V1.md` + bare-version "V3.3 §X" shorthand.** SHOULD. `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` cites "V1 §…" (no `ARCHITECTURE-V1.md` exists anywhere — dangling) and bare "V3.3 §X" (resolves only to `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`, no path given). Found by R1-F07. Action: replace bare "V3.3 §X" with the full path; resolve or remove the dangling "V1 §…" anchors; verify the "now-archived" claim. Coupling: same bare-shorthand class recurs at R3-F04/R4-F06 (`V10-DESIGN.md Part 7 §7.6`).
- **P-29c — `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` cites the methodology doc at the wrong dir (`supporting-docs/` vs `pack-ops/`).** SHOULD. Live doc (governs a not-yet-run trial review) → broken path is load-bearing. Found by R8-F01. Action: re-point both citations to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`.
- **P-29d — `EXECUTION-PLAN-V11.0.md` status line is stale ("Awaiting user review before any commits").** SHOULD. Body updated through 2026-05-25 (sequences BD-189/BD-192; many sequenced BDs are Resolved). Found by R8-F02. Action: update the Status line to reflect actual in-flight state; bump date; drop the "awaiting first review" claim.
- **P-29e — `RECOMMENDATIONS.md` is a v9-era doc with no deprecation banner, presented as current by README.** SHOULD. `maintenance-docs/RECOMMENDATIONS.md` line 1 "…using the AI Agent Config Pack v9"; no Status/date; README lists it as a current top-level reference. Found by R8-F03. Action: add a v9-era deprecation banner OR move to `archive/`; fix the README description either way.
- **P-29f — `project-template/README.md` is v10-stale (title, skill count 30 vs 36, `V10-DESIGN.md` shorthand, config-row omissions).** Severity split between segments (R3-F04 SHOULD; R4-F06 NIT) — both note it is NOT client-shipped (init-project.sh never copies it; no fixture), audience is a pack maintainer / manual `cp -r` user. Found by R3-F04, R4-F06. Action: retitle v11; fix skills count to 36; replace/qualify the `V10-DESIGN.md Part 7 §7.6` bare shorthand; add the two `.gemini` config files to the Config row; re-verify 16-agents/15-scripts. OPEN QUESTION: should this README ship to clients at all, or be relabeled pack-maintainer-only? [Researchers disagreed on severity SHOULD vs NIT — recorded as the higher SHOULD.]
- **P-29g — `PLATFORM-SKILLS.md` cites the pack-repo trinity `## Pack memory` from a client-shipped, RAG-indexed surface.** NIT. `project-template/docs/pack/PLATFORM-SKILLS.md` § "Extending this file" points at the pack-repo-only `## Pack memory` construct + "the pack's design documentation" (no path); ships to clients (S6), re-read every prompt-gen. Found by R3-F06. Action: drop the `## Pack memory` pointer + "design documentation" sentence (keep client-relevant naming + `x-` rule inline) OR restate client-side without a pack-only pointer. [Researcher flagged NIT on a conservative reading; reasonable as SHOULD.]
- **P-29h — undated CLI-fact / version-string staleness.** NIT (two findings): `maintenance-docs/VERIFIED-NOTES.md` carries CLI capability facts with no "Last verified" date (R8-F04); `xcode-companion-templates/README.md` describes itself as mirroring "v9 project-level policy" + a prose/table tension on tool-identity routing (R9-F03). Action: add a "Last verified: <date>; verify currency before relying" header to VERIFIED-NOTES (matching TOOL-COMPARISON's convention); update the Xcode README "v9 policy" to current major or version-neutral.

### P-30 — Pack-self help/boundary deliverable-only NITs (architect-adjudication, do-not-mechanically-delete)
- **P-30a — Pack-side HELP-FRAGMENT-TRACKER.md advertises TD/phase-task verbs as pack-self commands.** NIT. `pack-ops/HELP-FRAGMENT-TRACKER.md` § "TD promotion" + "Colloquial mappings" surface `pack td promote --to=phase-N.M` on the pack's own `pack help` render; byte-identical to the project-side copy; `pack-td.sh` is a real shipped script. Found by R1-F09. Action (as stated): architect adjudication of the deliverable-only test ("constructing a project-side deliverable vs pack-self-management?") — gate out of the pack-side render if project-deliverable-only (mirroring the work-item.yml cleanup), or document the exemption. Do NOT mechanically delete. OPEN QUESTION.
- **P-30b — `test-tracker-phase-task.sh` hard-asserts `BD-NNN` admission in a tracker dependency grammar.** SHOULD. `scripts/tests/test-tracker-phase-task.sh` Group 1 asserts the exported regex contains `BD-[0-9]+` and feeds a `BD-108` sample line that MUST match; mirrors `scripts/lib/tracker-phase-task.sh` `tracker_phase_task_dependency_re()`. Potential tension with `feedback_bd_pack_only_operational_rule` ("client-facing content MUST NOT operationally treat BDs … parser regexes"). No validate-pack check guards this → the test is the only ENCODING surface and encodes admission as desired. COUNTER-EVIDENCE: reverse-migration libs legitimately need BD in the grammar for v10 OT round-trip fidelity. Found by R6-F02 (cross-ref R5). Action (as stated): pair with R5's source verdict — if client-authoring surface → strip `BD-\d+` from grammar AND test in lock-step; if migration-fidelity surface → keep + add a one-line comment citing the fidelity rationale + the BD-pack-only rule. Do NOT edit unilaterally — source-design call. OPEN QUESTION.

### P-31 — Lowest-priority informational NITs (no version/boundary correction needed)
- **P-31a — `v11.0/INDEX.md` "Frozen forms" heading + bare "D16" cite carry the now-rejected "frozen" framing.** NIT. `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` — the carve-out FACT is correct and retained; only "Frozen forms" + the bare superseded "D16" decision-ID are stale framing. Found by R7-F13. Action (as stated, optional polish per V2 §10 Group G): "Frozen forms" → "Archived forms"; bare "D16" → "BD-193 bug-fix carve-out"; KEEP the fact. Cosmetic; surface to user.
- **P-31b — `D16 "v11.0 archive structural shape frozen" wrapper recorded verbatim in AUDIT-INVENTORY-BD-TD-PATH.md`.** NIT. Point-in-time Code-Red-2 record of the rejected wrapper. Found by R8-F09. Action (as stated): likely no edit — historical snapshot; if R7 reconciles the BD-TD-path audits, adopt the corrected v11.0-mutable framing. Surface to R7 for ownership.
- **P-31c — Trinity parity: `AGENTS.md` iOS-26 Xcode line lacks the `$XCODE_APP` relocation mechanism that CLAUDE.md/GEMINI.md document.** NIT. `project-template/AGENTS.md` hardcodes `/Applications/Xcode.app/...` with no override; CLAUDE.md/GEMINI.md expose `$XCODE_APP` + per-CLI override location. The override LOCATION is legitimately tool-specific but the EXISTENCE of the mechanism should be parity-held. Found by R3-F07. Action (as stated): add `$XCODE_APP` + a Codex-appropriate override location to AGENTS.md (concise but capability-preserving), or document the asymmetry justification if the user judges it tool-specific.
- **P-31d — `.gemini/settings.json` claims local-rag indexes a second doc, contradicting the authoritative RAG manifest.** SHOULD. `project-template/.gemini/settings.json` `_tools` says local-rag indexes METHODOLOGY.md AND INSTALL-PROCEDURES.md; `.mcp.json.example` says METHODOLOGY.md only; `pm-startup/SKILL.md` Step 4 (authoritative) says "exactly one path: METHODOLOGY.md". Three ENCODING surfaces disagree. Found by R4-F04. Action (as stated): align all three to the authoritative single-path manifest (or, if INSTALL-PROCEDURES.md is genuinely intended, update PM-CHAT.md manifest + pm-startup Step 4 + .mcp.json.example together). Verify against the PM-CHAT.md manifest SSOT before deciding direction. [Severity SHOULD — recorded here for the ENCODING-lock-step thematic adjacency; promote in the table.]
- **P-31e — `.codex/config.toml.example` "v10 ships STDIO only" version prose stale.** NIT. `project-template/.codex/config.toml.example` MCP transport note. The "defer to a future pack version" HTTP-MCP clause is a legitimate feature deferral; only the "v10" label is stale. Found by R4-F07. Action (as stated): "v10 ships STDIO only" → "v11 ships STDIO only" (or version-neutral); bundle with the P-06 provenance-line removal in the same file edit.
- **P-31f — `bootstrap.sh` comment references pack-only `supporting-docs/SETUP-NEW.md` absent at client install.** SHOULD. `project-template/scripts/bootstrap.sh` top comment cites `supporting-docs/SETUP-NEW.md` (not installed to clients); partly self-discloses "in the pack repo". Found by R4-F03. Action (as stated): drop the parenthetical doc cite (surrounding comment already explains the behavior) or rephrase to a client-resolvable reference. Same dead-pack-doc class as P-05/P-06. [Severity SHOULD.]
- **P-31g — README `RECOMMENDATIONS.md` / `VERIFIED-NOTES.md` presented as current top-level references.** Compounding cross-ref for P-29e/P-29h. README is a whole-repo surface; fix the descriptions when the underlying docs are banner'd/moved. Found by R8 cross-segment note.
- **P-31h — `xcode-companion-templates/Codex/config.toml` model `gpt-5` lags project-template `gpt-5.4`.** NIT. Unintended parity drift between two pack-shipped Codex configs. Found by R9-F02. Action (as stated): bump to `gpt-5.4` in both the top-level key + `[profiles.cloud-default]`, or confirm the Xcode companion intentionally pins an older cloud model.
- **P-31i — "Task tool" vs "Agent tool" terminology drift across PACK-AGENTS.md / PACK-CHAT.md vs the pack trinity.** NIT. PACK-AGENTS.md + PACK-CHAT.md say "Task tool"; CLAUDE.md pack-memory says "Agent tool". Found by R1-F08. Action (as stated): pick one term (VERIFY the current Claude Code tool name against docs before normalizing), normalize across all three + trinity in one pass (lock-step). Researcher medium-confidence — which name is canonical not independently confirmed; flag for doc-verification.
- **P-31j — `tracker.toml.pack-example` points the pack user to a path-less design doc ("ARCHITECTURE.md §6") to run a migration.** NIT. `tracker.toml.pack-example` header. bare `ARCHITECTURE.md` (resolves only to `maintenance-docs/v11-research/ARCHITECTURE.md`, no path) + usability (directs to a design doc when the command is `bash scripts/pack-tracker.sh init`). Found by R1-F10. Action (as stated): replace "see ARCHITECTURE.md §6" with the concrete command; give the full path for spec pointers.
- **P-31k — `ARCHITECTURE-V3.3-DELTA.md` D-22/D-4-V2 row records project-side work-item.yml options overtaken by BD-193, with no overtaken-by note.** NIT (NOT a leak — pack-side architect doc designing a project-side deliverable is allowed). Found by R8-F08. Action (as stated): optional one-line "overtaken by BD-193" addendum if kept live; else rely on Pattern-B ship sweep.
- **P-31l — `INTAKE-GROUPINGS-V11.md` self-flags unverified fidelity (quality caveat, not contamination).** NIT. Its v11.1+ framing is the LEGITIMATE groupings deferral (not the mislabel). Found by R7-F14. Action (as stated): optional — user may review fidelity or rely on REQUIREMENTS-GROUPINGS-V11.md (canonical, wins on conflict). No version/boundary correction.

---

## Cross-segment open questions (for G3 — genuine user decisions the segments surfaced)

These are the items the researchers explicitly left open or disagreed on. They are decisions, not fixes — surfaced distinctly so the user can decide before the correction phase designs anything.

**OQ-1 — Prison stale-ref remediation: per-doc edits vs Pattern-B ship-sweep.** Multiple live docs cite Step-2-prisoned docs (P-14 19c family; P-15 / P-21 V3.2-DELTA; P-25 TOOL-COMPARISON; P-09 / P-17 / P-18 BD-185 attempt records). For the completed-batch / Resolved-BD workflow artifacts, R8 + R7 offer two paths and do NOT pick: (a) move the whole artifact family to `maintenance-docs/archive/v11/` at version-ship (Pattern B, preferred for Resolved batches — avoids rewriting history), or (b) annotate each prisoned-doc citation in-place as "superseded; now in prison/". LIVE docs (P-21 lib headers, P-25 TOOL-COMPARISON, P-29c concept-scope doc) likely need (b) regardless. **Decision needed:** which path per artifact class, and whether the BD-195 "pristine post-Batch-19c state" bar requires the active `v11-implementation/` tree to be cleared of contaminated attempt-records now vs at ship.

**OQ-2 — `BD-NNN` admission in the tracker phase-task dependency grammar: leak or intentional fidelity? (P-30b / R6-F02 ↔ R5).** A client-installed `scripts/lib/` grammar admits `BD-\d+`; a CI test asserts that admission as required. This either violates `feedback_bd_pack_only_operational_rule` (client-facing parser regex treating BDs) OR is intentional v10-OT round-trip fidelity (reverse-migration needs BD). R6 explicitly defers the verdict to R5's source-design analysis; R5 did not file a counterpart finding on the grammar's audience. **Decision needed:** is `tracker_phase_task_dependency_re` a client-authoring surface (→ strip BD from grammar + test in lock-step) or a migration-fidelity surface (→ keep + add a rationale comment + BD-pack-only-rule pointer)? Resolving this determines whether P-30b is a fix or a comment-only annotation.

**OQ-3 — Disposition of UNTRACKED contaminated review `PACK-REVIEW-BD-185-H.2.md` (P-09 / R7-F10).** Untracked, anchored to a prisoned plan, propagates the v11.1 framing. R7 flags it but assigns disposition to the supersession-map pass. **Decision needed:** track / prison / leave-and-Pattern-B-sweep — and whether a same-named tracked variant exists (provenance ambiguity to resolve).

**OQ-4 — v9-auditor seed set currency in client-shipped feedback log (P-19 / R3-F02).** When re-stamping `PACK-FEEDBACK.md` to v11, is the v9-era auditor-split seed question set (Q1–Q6) still the intended v11 seed? The split still ships in v11, so the seeds may be valid; researcher asks for confirmation rather than assuming.

**OQ-5 — `project-template/README.md`: ship to clients, or relabel pack-maintainer-only? (P-29f / R3-F04 / R4-F06).** It is v10-stale (title, 30-vs-36 skill count, `V10-DESIGN.md` shorthand) but is NOT client-installed today. R3 rated it SHOULD, R4 rated it NIT (the disagreement is precisely about whether a non-shipped pack-authoring artifact matters). **Decision needed:** is this README a client deliverable (→ fix + verify it ships) or a pack-maintainer artifact (→ relabel and lower the bar)?

**OQ-6 — Xcode Codex companion: support sub-agents or not? (P-28 / R9-F01).** The companion `config.toml` declares 7 agents whose toml targets are never shipped. Fix is either (a) ship an `agents/` dir + extend 3 install blocks, or (b) strip the `[agents.*]` blocks. **Decision needed:** is machine-level Xcode Codex meant to support sub-agents at all? Also relates to the sunset-artifact policy below.

**OQ-7 (policy) — v9→v10 sunset-artifact scrub on live user-facing surfaces (P-24 / R1-F05 + R1 closing note).** `pack help` renders a runnable verb for the absent `migrate-v9-to-v10.sh`; QUICKSTART links an absent `MIGRATION-v9-to-v10.md`. **Decision needed:** scrub v9→v10 sunset artifacts from live user-facing surfaces, or retain as historical notes (and if retained, with what non-live framing)? README's v10.0 version-history row is the acceptable historical home either way.

**OQ-8 (precondition, not a decision — flagged for sequencing) — normalize bare archive paths before executing P-02 (P-13 / R7-F07).** The `ARCHITECTURE-BD-185-V2.md` §10 / `PLAN-BD-185-V2.md` §6 correction recipes that drive the P-02 cleanup cite bare `templates-archive/...` paths that don't resolve at repo root. This is not a user decision but a sequencing requirement: P-13 must land (or a path-prefix preamble be added) BEFORE a coder executes P-02, or the recipe steps fail. Surfaced here so the correction-phase ordering accounts for it.

---

## Coverage / no-drop table (every segment finding-ID → consolidated PID)

Mandatory no-drop ledger. Every R1-F01 … R9-F03 maps to exactly one consolidated record (or is explicitly carried as a sub-letter). Nothing silently disappears.

| Finding | Severity (segment) | → Consolidated PID | Notes |
|---|---|---|---|
| R1-F01 | MUST | P-10 | README MERGE-STRATEGY/DRY-RUN mis-filed under supporting-docs/ (merged with R1-F02) |
| R1-F02 | MUST | P-10 | README pack-ops/ block omits 3 resident files (merged with R1-F01) |
| R1-F03 | MUST | P-03 | README maintenance-docs/ stale after prison move |
| R1-F04 | MUST | P-11 | PACK-CHAT "Four" vs five agents |
| R1-F05 | SHOULD | P-24 | HELP-FRAGMENT-PACK sunset migrator verb (merged with R1 QUICKSTART closing note) |
| R1-F06 | SHOULD | P-29a | BOUNDARY-DEFINITION §6 missing discoverability pointers |
| R1-F07 | SHOULD | P-29b | CONCEPTUAL-REVIEW-METHODOLOGY dangling ARCHITECTURE-V1.md + bare V3.3 shorthand |
| R1-F08 | NIT | P-31i | "Task tool" vs "Agent tool" terminology drift |
| R1-F09 | NIT | P-30a | pack-side HELP-FRAGMENT-TRACKER TD/phase verbs (architect adjudication) |
| R1-F10 | NIT | P-31j | tracker.toml.pack-example path-less ARCHITECTURE.md ref |
| R2-F01 | MUST | P-07 | pack-help skill stale bare PACK-CHAT/OPTIONAL-FEATURES refs (Claude+Codex) |
| R2-F02 | SHOULD | P-26 | pack-planner state-verifiable-questions rule Claude-only |
| R2-F03 | NIT | P-27 | commit-discipline agent-run.sh pack-side example |
| R3-F01 | MUST | P-04 | PM-CHAT cites uninstalled docs/pack/MERGE-STRATEGY.md |
| R3-F02 | SHOULD | P-19 | PACK-FEEDBACK.md stamped v9 |
| R3-F03 | SHOULD | P-20 | pm-chat.md kickoff hardcodes v10 (merged) |
| R3-F04 | SHOULD | P-29f | project-template/README.md v10-stale (merged with R4-F06; severity disagreement noted) |
| R3-F05 | SHOULD | P-20 | HELP-FRAGMENT.md foregrounds v9→v10 migrator (merged) |
| R3-F06 | NIT | P-29g | PLATFORM-SKILLS.md cites pack-repo ## Pack memory on client surface |
| R3-F07 | NIT | P-31c | AGENTS.md missing $XCODE_APP relocation mechanism (trinity parity) |
| R4-F01 | MUST | P-05 | .mcp.json.example cites uninstalled supporting-docs/CLI-PM-SETUP.md |
| R4-F02 | MUST | P-06 | .codex/config.toml.example leaks V10-CODEX-MCP-RESEARCH.md + SHA |
| R4-F03 | SHOULD | P-31f | bootstrap.sh cites uninstalled supporting-docs/SETUP-NEW.md |
| R4-F04 | SHOULD | P-31d | .gemini/settings.json local-rag manifest contradicts authoritative manifest |
| R4-F05 | SHOULD | P-20 | pm-startup SKILL "in v10" default-manifest prose (merged) |
| R4-F06 | NIT | P-29f | project-template/README.md v10-stale (merged with R3-F04) |
| R4-F07 | NIT | P-31e | .codex/config.toml.example "v10 ships STDIO only" label |
| R5-F01 | MUST | P-01 | validate-pack.py v11.1 mislabel comments (merged into the live-encoding cluster) |
| R5-F02 | SHOULD | P-23 | tracker-migrate-forward.sh dead maintenance-docs/IMPLEMENTATION-PLAN.md fallback |
| R5-F03 | SHOULD | P-22 | forward-migrate client path diverges from canonical docs/project/ layout |
| R5-F04 | NIT | P-21 | lib headers cite prisoned ARCHITECTURE-V3.2-DELTA.md |
| R6-F01 | MUST | P-01 | test-issue-forms.sh v11.1 mislabel comments (merged into the live-encoding cluster) |
| R6-F02 | SHOULD | P-30b | test-tracker-phase-task.sh asserts BD-NNN admission (→ OQ-2; paired with R5) |
| R7-F01 | BLOCKER | P-02 | v11.1/INDEX.md fictional cut + fabricated Convention-Y |
| R7-F02 | MUST | P-02 | phase-part-v11.1/SCHEMA.md wrong version tag + dir (merged) |
| R7-F03 | MUST | P-02 | v11.1/forms/work-item.yml misplaced duplicate (merged) |
| R7-F04 | BLOCKER | P-01 | validate-pack.py LIVE code-encoded v11.1 mislabel (merged with R5-F01) |
| R7-F05 | SHOULD | P-12 | check_template_archive_v11() missing phase-part entry type |
| R7-F06 | MUST | P-01 | test-issue-forms.sh LIVE test-encoded v11.1 mislabel (merged with R6-F01) |
| R7-F07 | SHOULD | P-13 | V2 §10 / PLAN-V2 §6 bare templates-archive paths (→ OQ-8 precondition) |
| R7-F08 | SHOULD | P-16 | ARCHITECTURE-BD-185-V2.md no forward ordering-addendum pointer |
| R7-F09 | MUST | P-08 | BD-193 review+Phase-5 blessed/deepened the mislabel |
| R7-F10 | MUST | P-09 | PACK-REVIEW-BD-185-H.2.md untracked + prisoned anchor + v11.1 cites (→ OQ-3) |
| R7-F11 | SHOULD | P-18 | PACK-REVIEW-BD-185-H.1.md blesses mislabel + prisoned anchors |
| R7-F12 | SHOULD | P-17 | 6 BD-185 IMPL reports v11.1 framing + prisoned refs (group; → OQ-1) |
| R7-F13 | NIT | P-31a | v11.0/INDEX.md "Frozen forms" + bare D16 framing |
| R7-F14 | NIT | P-31l | INTAKE-GROUPINGS-V11.md unverified-fidelity self-flag (quality caveat, legit v11.1+) |
| R8-F01 | SHOULD | P-29c | CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md wrong methodology-doc dir |
| R8-F02 | SHOULD | P-29d | EXECUTION-PLAN-V11.0 stale status line |
| R8-F03 | SHOULD | P-29e | RECOMMENDATIONS.md v9-era no banner + README presents as current |
| R8-F04 | NIT | P-29h | VERIFIED-NOTES.md undated CLI facts (merged with R9-F03 currency theme) |
| R8-F05 | NIT | P-25 | TOOL-COMPARISON.md cites GEMINI-CLI/ANDROID-ANALYSIS at pre-prison path |
| R8-F06 | SHOULD | P-14 | 19c-family artifacts forward-ref prisoned V1/PRINCIPLE-CHECK/DISCARDED (→ OQ-1) |
| R8-F07 | SHOULD | P-15 | per-entry/V3.x chain refs prisoned V3.2-DELTA as authoritative |
| R8-F08 | NIT | P-31k | V3.3-DELTA D-22/D-4-V2 row overtaken by BD-193 (not a leak) |
| R8-F09 | NIT | P-31b | AUDIT-INVENTORY-BD-TD-PATH.md D16 "frozen" wrapper snapshot (cross-with-R7) |
| R9-F01 | MUST | P-28 | Xcode Codex config.toml 7 agents never shipped (→ OQ-6) |
| R9-F02 | NIT | P-31h | Xcode config.toml model gpt-5 lags gpt-5.4 |
| R9-F03 | NIT | P-29h | Xcode README "v9 policy" staleness + prose/table tension (merged with R8-F04 currency theme) |

**No findings dropped.** All 60 segment finding-IDs (R1-F01…R1-F10, R2-F01…F03, R3-F01…F07, R4-F01…F07, R5-F01…F04, R6-F01…F02, R7-F01…F14, R8-F01…F09, R9-F01…F03) are mapped above.

**Merge map (where N findings → 1 record):**
- P-01 ← R5-F01 + R6-F01 + R7-F04 + R7-F06 (the live-code-encoded v11.1 mislabel: validator + test, 4 findings)
- P-02 ← R7-F01 + R7-F02 + R7-F03 (the fictional v11.1 archive cut, 3 findings)
- P-10 ← R1-F01 + R1-F02 (README pack-ops/-vs-supporting-docs/ mis-filing, 2 findings)
- P-20 ← R3-F03 + R3-F05 + R4-F05 (client-shipped v10 prose / migrator, 3 findings)
- P-24 ← R1-F05 + R1 QUICKSTART closing note (v9→v10 sunset artifacts, 2 findings)
- P-29f ← R3-F04 + R4-F06 (project-template/README.md v10-stale, 2 findings, severity disagreement SHOULD/NIT)
- P-29h ← R8-F04 + R9-F03 (undated/stale-version-string currency, 2 findings)
- P-15 / P-21 share the prisoned ARCHITECTURE-V3.2-DELTA.md target (R8-F07 docs; R5-F04 code) — kept as 2 records (different surface classes) but cross-linked.

---

## RECONCILER-ADDED (not from a segment)

None. No genuinely new finding surfaced during reconciliation. Every record above traces to a cited segment finding-ID. The only reconciler value-add is structural: the merge groupings, the severity-honest recount (49 distinct problems from 59 raw findings), and the 8 open questions distilled from the segments' own "surface to user / source-design call / disposition pass owns this" deferrals.
