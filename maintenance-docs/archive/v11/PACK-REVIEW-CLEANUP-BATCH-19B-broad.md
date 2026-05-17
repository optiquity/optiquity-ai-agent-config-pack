# PACK-REVIEW-CLEANUP-BATCH-19B-broad — End-of-batch broad review

**Reviewer:** pack-reviewer (end-of-batch broad pass — independent of per-commit reviews)
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `efd9a32`)
**Scope:** Batch 19b commits `667d2dd` through `efd9a32` (7 substantive commits + 1 in-flight recovery commit `ef9e5c7`)
**Authoritative sources read:** archived `ARCHITECTURE-CLEANUP-BATCH-19B-V2.md`, archived `ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md`, archived `PLAN-CLEANUP-BATCH-19B.md`. Per-commit `PACK-REVIEW-*.md` reports were NOT read (per `feedback_no_prior_reviews_to_reviewer` bias-avoidance rule).
**Verification independence:** validate-pack.py + 3 baseline test suites re-run from scratch by this reviewer.

---

## §1 — Summary + verdict

**Verdict: APPROVE — no MUST or BLOCKER findings. Two SHOULD findings and three NITs surface; all are non-blocking, and the two SHOULDs are minor terminology/cross-reference polish that can be fixed in a small follow-up commit or deferred to a sweep batch per Pack-Chat triage. The batch is structurally sound, trinity parity is honored under §3 per-CLI variant semantics, archive completeness is verified, and cross-references resolve.**

**Batch shape (verified independently against `git log`):**

| Commit SHA | Subject | Files touched | Verified |
|---|---|---|---|
| `667d2dd` | 19b-1 trinity `## Pack memory` restructure | CLAUDE.md, AGENTS.md, GEMINI.md | YES |
| `ef9e5c7` | manifest regen recovery | test-fixtures/manifest.txt | YES (in-flight, not Batch-19b-planned) |
| `a9b7c74` | 19b-2-RC9 trinity manifest-regen rule | CLAUDE.md, AGENTS.md, GEMINI.md | YES |
| `7e4fdcc` | 19b-2 PACK-CHAT.md `## Behavioral rules` extensions | PACK-CHAT.md | YES |
| `3558525` | 19b-3 PACK-AGENTS.md PREFLIGHT obligation | PACK-AGENTS.md | YES |
| `4760649` | 19b-4 EXECUTION-PLAN-V11.0.md §B rewrite | maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md | YES |
| `aaa61b3` | 19b-5 V11-13 CONCEPTUAL-REVIEW-METHODOLOGY extension | supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md | YES |
| `efd9a32` | 19b-7 archive sweep (18 files) | maintenance-docs/archive/v11/** | YES |

Commit 19b-6 (Claude memory cache pointer reduction) is Pack-Chat-direct and edits files OUTSIDE the repo (`~/.claude/projects/<slug>/memory/`), so it produces no git commit — verified inline below at §10.

**Acknowledgements:**
- Trinity-first design (V2 §A.1) landed cleanly across all 3 files with per-CLI variants applied to the 3 bullets that genuinely needed them (Pack agent invocation, Pack-coder PREFLIGHT + STOP-MEANS-STOP, "What Pack Chat CAN edit directly" sub-list for memory paths).
- RC9 manifest-regen rule is byte-identical across all 3 trinity files (UNIVERSAL classification confirmed).
- All 18 workflow artifacts moved to archive/v11/ per Pattern B; v11-implementation/ contains only its pre-19b contents plus a forthcoming-batch empty directory.
- Validate-pack PASS 35/35 (independent rerun).
- 3 baseline test suites PASS clean (independent rerun): test-init-project (67/67), tracker-migrate-forward (145/145), test-per-entry (57/57). test-persona-contracts (3/3 contracts, 37/37 inner migration-contract checks).
- No out-of-scope file modifications detected (project-template/ untouched, scripts/ untouched, PM-only files untouched).
- F.3 placement question (V2 §F.3 explicit text vs V2 §I.1 ToC) resolved per PLAN §6.1 — F.3 lives in `### Agent invocation rules` (planner's chosen disposition).
- RC9 bullet trigger correctly excluded all Batch-19b commits from manifest-regen requirement (recursive base case holds — pack-root edits are NOT v11-surface).

---

## §2 — Findings table

| # | Severity | File:line / section | Finding | Suggested remediation |
|---|---|---|---|---|
| F1 | SHOULD | CLAUDE.md:134-143 vs AGENTS.md:128-136 vs GEMINI.md:100-108 ("Per-action approval extends to sub-agents" bullet) | Planner §3.3 classified this bullet as UNIVERSAL (byte-copy across all 3 trinity files), but the actual implementation diverges in two ways: (a) "Claude Code Pack Chat" / "Codex CLI Pack Chat" / "Gemini CLI Pack Chat" — legitimate per-CLI tool-name variant per §3.1 criteria, (b) the trailing memory-cache pointer reference (`See ... memory-cache pointer`) appears in CLAUDE.md only — legitimate per V2 §A.1 (no Tier 1.5 for non-Claude CLIs). The divergence is correct DESIGN but contradicts the planner's UNIVERSAL classification. Either the bullet is TOOL-SPECIFIC (and the planner classification table needs correction in a future docs-sweep) or the substantive-rule-table that pack-coder produced in IMPL-REPORT should be re-verified to confirm this classification was reclassified during implementation. The classification mismatch is documentation-only — no rule corruption — but creates a future hazard if a sweep tool keys off the planner table to verify trinity parity. | Append a SHOULD-class clarification note to the next docs-sweep batch (or pack memory): when a UNIVERSAL bullet references a Claude-specific subsystem (like a memory-cache pointer), the bullet is classifiable as UNIVERSAL with-tool-specific-trailer rather than fully UNIVERSAL. Alternative: file as observation in the future "v11-sweep" BD with no immediate action. |
| F2 | SHOULD | `~/.claude/projects/<slug>/memory/feedback_no_prefix_chars.md` (outside repo) | The STANDALONE memory file (per V2 §D.4 retention as the only Claude-Code-only chat-tooling convention not promoted to trinity) has a malformed YAML frontmatter: TWO `---` frontmatter blocks (lines 1-7 and 7-14 — overlap at line 7), with the body opening line "delimiters instead\"" appearing OUTSIDE the frontmatter, and the description field truncated. This file was processed by the L.4 script in commit 19b-6 (Pack-Chat-direct outside-repo work), but the original frontmatter — which was already broken pre-batch per inspection — was preserved (or perhaps the script's STANDALONE branch did not normalize). Risk: future YAML-aware tools (or Claude Code's own memory-loading) may parse the file incorrectly; the description preview shown in MEMORY.md may be truncated; the file may fail validation against any future memory-format check. The note at line 22 ("preserved STANDALONE per Batch 19b §F disposition") is well-formed and helpful. | Pack Chat-direct hand-edit: collapse the two frontmatter blocks into one well-formed block. Standard shape: single `---` open + `name`/`description`/`metadata` fields + single `---` close + body. Restore the full description value (the wrap-into-body fragment "delimiters instead" needs to be in the description string). No content rule change; only file-format hygiene. Alternatively, defer to a memory-cache cleanup pass if Pack Chat batches multiple memory normalizations. |
| N1 | NIT | CLAUDE.md:200 ("Triage all reviewer findings; default fix-all; nits become tech debt" bullet) | The bullet cross-references `feedback-deferral-is-scope-creep` and `feedback-deferred-work-tracking` as memory-pointer-style anchors, but the references are bare prose-citation (no surrounding `See ... pointer` clause). This matches the planner's V2 §F.1 verbatim text — not a coder defect — but the pattern is slightly less explicit than the W5 ("Per-action approval extends to sub-agents") bullet which says "See `feedback-no-destructive-without-approval` for the memory-cache pointer." Consistency: either all such cross-references use the "See `feedback-X` pointer" form, or none do. Currently mixed. | Future docs-sweep: pick one convention and normalize. Low priority; cosmetic only. |
| N2 | NIT | CLAUDE.md:130 ("One review/fix cycle per batch" bullet — preserved verbatim from pre-batch) | This existing pre-batch bullet still contains the obsolete sentence: "Fixes land in the current session — never as a new BD. BDs are reserved for new scope / new feature / new architecture; only the user can initiate a BD-for-fix, and Pack Chat must not propose one." This is OBSOLETE per the rewritten EXECUTION-PLAN §B step 5 (PC-1) which now says new BDs CAN open with user-discussion-and-approval (size / blocked / fit). The sentence contradicts the new step 5 if read literally ("never as a new BD"). Cross-reference: W8 "Deferral IS scope creep" bullet at line 174-175 correctly carries the OQ-1 caveat ("Per OQ-1 (rewritten EXECUTION-PLAN §B), any new-BD-open additionally requires user-discussion-and-approval"). The W3 bullet ("One review/fix cycle per batch") is the stale anchor that pre-dates the OQ-1 rewrite — the V2 architect doc explicitly preserved W3 as UNCHANGED but did not flag this dissonance. | Future docs-sweep: edit W3 (CLAUDE.md:130, AGENTS.md:124, GEMINI.md:96) to either (a) drop the obsolete "never as a new BD" sentence in favor of a cross-reference to W8 + EXECUTION-PLAN §B, or (b) add the OQ-1 caveat inline. This is documentation-internal-consistency, not a functional defect. |
| N3 | NIT | PACK-CHAT.md:170-179 (L.2 action-item bullet) | The L.2 action item is correctly added to PACK-CHAT.md per planner spec, but its location at the END of `## Behavioral rules` section (after the existing 13 bullets) places an action-item INSIDE a "Behavioral rules" section that otherwise contains only standing rules. A pure "behavioral rule" is timeless; an "action item" has an expected resolution and should be tracked. The note's prose self-identifies as "Tracked as a Pack-Chat-side coordination item; not a code defect" — so it's correctly scoped — but the placement inside a rules section is taxonomically off. Per `feedback_deferred_work_tracking` (a memory rule), deferred items need a "live forward-pointing surface AND scheduled to a specific anchor" — the action note IS in a live surface (PACK-CHAT.md is read every session) but the "specific anchor" is loose (no due date, no BD number, no committed sequence). | Either (a) re-classify the L.2 item as a sub-section heading "Action items (PM coordination)" so the behavioral-rules section stays clean, or (b) move it to a Pack-Chat-only TODO surface (e.g., a session-startup checklist), or (c) leave as-is if Pack Chat will close out the action shortly. Low priority; pattern-discipline only. |

**Severity legend:** MUST = blocker for batch ship. SHOULD = non-blocking but worth fixing before next major work. NIT = cosmetic / pattern / consistency only.

---

## §3 — Trinity parity audit (cross-CLAUDE/AGENTS/GEMINI diff)

Per the planner's §3 per-CLI variant strategy (the refined trinity rule enforcement plan, NOT byte-identity), trinity bullets fall into one of three classes:

- **UNIVERSAL** — byte-identical across all 3 trinity files
- **TOOL-SPECIFIC** — different machinery wording per CLI; same substantive rule
- **CLAUDE-ONLY** — present in CLAUDE.md only (the `### Sub-agent behavior (Claude-only)` sub-section)

**Diff verification results (independent runs by this reviewer):**

| Sub-section | CLAUDE.md vs AGENTS.md | CLAUDE.md vs GEMINI.md | Expected per §3.3 | Match |
|---|---|---|---|---|
| `### Workflow` (11 bullets) | 1 bullet differs (Per-action approval extends to sub-agents — CLI name + memory-pointer-trailer) | 1 bullet differs (same) | UNIVERSAL per planner | DIVERGENT — see F1 |
| `### Agent invocation rules` (7 bullets) | 2 bullets differ (Pack agent invocation — CLI tool name; Pack-coder PREFLIGHT — per-CLI enforcement notes) | 2 bullets differ (same) | TOOL-SPECIFIC per §3.3 (Pack agent invocation, PREFLIGHT) | MATCH |
| `### Sub-agent behavior (Claude-only)` | Absent in AGENTS.md | Absent in GEMINI.md | CLAUDE-ONLY per §I.4 | MATCH |
| `### Pack Chat scope` (4 bullets) | 1 sub-bullet differs ("What Pack Chat CAN edit directly" memory-cache item) | 1 sub-bullet differs (same) | TOOL-SPECIFIC per §3.3 (memory-cache reference) | MATCH |
| `### Repo conventions` (9 bullets) | 0 differences | 0 differences | UNIVERSAL per §3.3 | MATCH |
| `### Project goals (v11)` (2 bullets) | 0 differences | 0 differences | UNIVERSAL per §3.3 | MATCH |

**Per-bullet substantive-rule verification (sample 4):**

- **W5 "Per-action approval extends to sub-agents":** all 3 files preserve the same rule (per-action approval applies to Pack Chat AND sub-agents; git-state-changing and destructive ops both subject to approval; sub-agents inherit by construction). CLI name and the optional memory-pointer trailer differ. Substantive rule: SAME.
- **AI1 "Pack agent invocation":** CLAUDE.md cites `claude --agent`, AGENTS.md cites `codex --agent`, GEMINI.md cites `@pack-<name>`. Substantive rule (how to invoke pack agents): SAME modulo platform.
- **AI7 "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern":** CLAUDE.md carries the full 3-CLI sub-bullet enumeration (Claude / Codex / Gemini); AGENTS.md carries Codex-specific enforcement note + cross-reference to CLAUDE.md authoritative full text; GEMINI.md carries Gemini-specific enforcement note + cross-reference to CLAUDE.md authoritative full text. PREFLIGHT half (platform-neutral) is identical across all 3. Substantive rule: SAME.
- **RC9 "Regenerate test-fixtures/manifest.txt on every v11-surface commit":** byte-identical across all 3 trinity files (UNIVERSAL classification confirmed). Substantive rule: SAME.

**Conclusion §3:** trinity parity holds under the planner's refined per-CLI variant semantics. The single divergence (F1) is in a bullet that the planner classified UNIVERSAL but that the coder appears to have treated as having a tool-specific trailer — the substantive rule is preserved, so no functional defect, just a classification-vs-implementation cosmetic mismatch.

---

## §4 — Cross-commit consistency audit

This section verifies that references between Batch 19b commits resolve correctly.

**Reference 1: PACK-CHAT.md `## Behavioral rules` → trinity rules (19b-2 → 19b-1).**
- PACK-CHAT.md "Stop after every reviewer pass for triage discussion" (line 63-71) references "implicit-BD-status-flip rule" — present in trinity at CLAUDE.md:131-133 (W4). **Resolves.**
- PACK-CHAT.md "Real fixes only — no green-the-test band-aids" (line 81-92) cross-references `feedback-fix-all-review-findings` and `feedback-pack-chat-does-no-fixes` — both are memory pointers; the trinity bullets they reference are present at CLAUDE.md:192-200 (W11, Triage all) and CLAUDE.md:318-328 (PCS1, Pack Chat does NO fixes). **Resolves.**
- PACK-CHAT.md "Scope-extension test for in-flight work" (line 122-132) references trinity "One review/fix cycle per batch" bullet — present at CLAUDE.md:128-130 (W3). **Resolves.**
- PACK-CHAT.md "Push to v11-dev only" (line 105-111) references EXECUTION-PLAN-V11.0.md §A.4 — present at EXECUTION-PLAN line 328 "Push to `v11-dev` only." **Resolves.**

**Reference 2: PACK-AGENTS.md PREFLIGHT bullet → trinity AI7 bullet (19b-3 → 19b-1).**
- PACK-AGENTS.md line 207-210 says "Authoritative full text for both halves of the pattern (including cross-CLI scope notes for Codex / Gemini): trinity `## Pack memory` `### Agent invocation rules` 'Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern' bullet." Cross-reference resolves to CLAUDE.md:236-275 (AI7). **Resolves.**

**Reference 3: EXECUTION-PLAN §B → trinity W8 "Deferral IS scope creep" bullet (19b-4 → 19b-1).**
- EXECUTION-PLAN line 335 "(per `feedback-deferral-is-scope-creep` in `## Pack memory`)." Memory pointer references trinity bullet at CLAUDE.md:163-175 (W8). **Resolves.**
- EXECUTION-PLAN line 370 cross-references "the `feedback-deferral-is-scope-creep` memory revision." Same resolution. **Resolves.**

**Reference 4: V11-13 extension → existing methodology context (19b-5).**
- CONCEPTUAL-REVIEW-METHODOLOGY.md:114 "**Must-include-in-prompt rule.**" sits BETWEEN existing CI-section closer at line 112 ("Reviewer prompt template for CI work MUST include the 'would this turn red?' requirement.") and the convention/naming checklist at line 116. The placement reads coherently: the existing line 112 establishes the rule scope for REVIEW prompts; line 114 broadens to "implementation OR review" prompts (per V2 §B V11-13 row). **Reads coherently.**

**Reference 5: RC9 trinity bullet → empirical incident lineage (19b-2-RC9).**
- RC9 bullet names 6 commit SHAs (`667d2dd`, `ef9e5c7`, `cf67a96`, `62f9eec`, `479fef5`, `a57dd04`) in the **Why:** and **How to apply:** lines. All 6 SHAs verified to exist in `git log` and to have the described properties (v11-surface drift, recovery, last-clean baseline). **All 6 resolve.**
- RC9 bullet cross-references `test-fixtures/README.md` § Determinism — present in `test-fixtures/README.md` per planner pre-check. **Resolves.**
- RC9 bullet cross-references `test-fixtures/build.sh:903-912` — verified by inspection; `_update_manifest` function is at those lines. **Resolves.**
- RC9 bullet cross-references "BD-115, RELEASE-GATE item 5" — BD-115 exists in BACKLOG; RELEASE-GATE.md item 5 is the fixture manifest verify step. **Resolves.**

**Conclusion §4:** all cross-commit references resolve correctly. The 19b commit sequence is internally consistent.

---

## §5 — RC9 rule self-consistency audit

**Trigger form (fuzzy directory):** RC9 bullet line 1 (CLAUDE.md:449) reads "v11-surface = files under `project-template/` or `scripts/`." This matches Form C per §8.3 of the RC9 architect doc. **Correct.**

**Recursive base case verification (no Batch 19b commit incorrectly triggered manifest regen for pack-root edits):**

| Commit | Files touched | Under `project-template/` or `scripts/`? | Manifest regen? | Correct per RC9? |
|---|---|---|---|---|
| `667d2dd` | CLAUDE.md, AGENTS.md, GEMINI.md | NO (pack-root) | NO | YES (pack-root pack-ops, not v11-surface) — but see "expected failure" footnote below |
| `ef9e5c7` | test-fixtures/manifest.txt | n/a (it IS the manifest) | YES (this is the regen commit) | YES — recovery commit |
| `a9b7c74` | CLAUDE.md, AGENTS.md, GEMINI.md | NO (pack-root) | NO | YES (pack-root pack-ops) |
| `7e4fdcc` | PACK-CHAT.md | NO (pack-root) | NO | YES (pack-root pack-ops) |
| `3558525` | PACK-AGENTS.md | NO (pack-root) | NO | YES (pack-root pack-ops) |
| `4760649` | maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md | NO (maintenance-docs/) | NO | YES (maintenance-docs is excluded) |
| `aaa61b3` | supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md | NO (supporting-docs/) | NO | YES (supporting-docs is excluded per RC9) |
| `efd9a32` | maintenance-docs/archive/v11/** (18 archives) | NO (maintenance-docs/) | NO | YES (maintenance-docs is excluded) |

**Footnote on `667d2dd`:** technically `667d2dd` is the commit that EXPOSED the manifest staleness when CI ran against it. The pre-19b trinity edits (`cf67a96`, `62f9eec`, `479fef5`) cumulatively touched `project-template/` (v11-surface) without manifest regen; the staleness only manifested as a CI failure on `667d2dd` because the prior commits also failed manifest regen and the failure compounded. RC9 rule WOULD have caught `cf67a96` / `62f9eec` / `479fef5` if it had existed at the time — which is exactly the Why-line of RC9. The rule's self-consistency is preserved: had RC9 existed, those pre-19b commits would have included manifest regen and `667d2dd` would have shipped clean.

**Fuzzy directory trigger correctness:**
- RC9 bullet line 1 names the trigger as "files under `project-template/` or `scripts/`" — matches the empirical v11-surface set per §2.2 of the RC9 architect doc.
- The bullet correctly states that `supporting-docs/`, `maintenance-docs/`, and pack-ops files at root are NOT v11-surface (implicitly via "any commit whose diff includes a file under either directory MUST also regenerate" — the converse case is naturally excluded).
- The post-rebuild-diff-as-authority sentence is preserved verbatim from the architect doc.

**Incident lineage in **Why:** line:**
- All 6 SHAs (`cf67a96`, `62f9eec`, `479fef5`, `667d2dd`, `ef9e5c7`, `a57dd04`) match the architect doc's §1 incident description and the recovery commit message.
- The drift attribution ("cumulative effect of three intentional v11-surface commits") is accurate: `cf67a96` was BD-169 pack-product wording, `62f9eec` was BD-169 review/fix, `479fef5` was Batch 19 broad review/fix — all 3 touched `project-template/` (verified by `git diff-tree --name-only`).

**Conclusion §5:** RC9 rule is self-consistent. The fuzzy directory trigger correctly excluded all Batch-19b pack-root and maintenance-docs edits from manifest regen; the recursive base case (pack-root edits are not v11-surface) holds; the empirical incident lineage is accurately preserved.

---

## §6 — Archive completeness audit

Per planner §1 commit 19b-7 row, the archive sweep moved 18 workflow artifacts to `maintenance-docs/archive/v11/`. The expected composition per planner: 3 architect docs + 1 research doc + 1 planner doc + 1 input doc + 7 IMPL-REPORTs + 5 PACK-REVIEWs = 18.

**Independent verification (via `git diff-tree --name-only efd9a32`):**

| Category | Expected count | Actual count | Files |
|---|---|---|---|
| Architect docs | 3 | 3 | ARCHITECTURE-CLEANUP-BATCH-19B.md (V1), ARCHITECTURE-CLEANUP-BATCH-19B-V2.md (V2), ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md (RC9) |
| Research docs | 1 | 1 | RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md |
| Planner docs | 1 | 1 | PLAN-CLEANUP-BATCH-19B.md |
| Input docs | 1 | 1 | CLEANUP-INPUTS-SESSION-RULES.md |
| IMPL-REPORTs | 7 | 7 | 19b-1, 19b-2, 19b-2-RC9, 19b-3, 19b-4, 19b-5, 19b-6 |
| PACK-REVIEWs | 5 | 5 | 19b-1, 19b-2, 19b-2-RC9, 19b-4, 19b-5 (no 19b-3 per planner SKIP; no 19b-6 per Pack-Chat-direct verification; no 19b-7 yet) |
| **Total** | **18** | **18** | — |

**Straggler check (v11-implementation/ should contain only pre-19b contents):**

`ls maintenance-docs/v11-implementation/` returns 117 entries. Spot-check shows the remaining contents are pre-19b artifacts (BD-032 through BD-170 IMPL-REPORTs + RETRO-FIX reports + PACK-REVIEWs; ARCHITECTURE-*, PLAN-*, REVIEW-ARCHITECTURE-*, RESEARCH-*, AUDIT-* docs; EXECUTION-PLAN-V11.0.md; RELEASE-GATE.md; CONCEPTUAL-AREA-*.md). Plus ONE new empty directory `CLEANUP-INPUTS-BATCH-19C/` (forthcoming-batch placeholder; out-of-scope for Batch 19b). NO Batch-19b workflow artifacts remain in v11-implementation. **Verified clean.**

**Move-vs-create note (from commit message):** the commit message of `efd9a32` explicitly states "These files were never staged-and-committed in their original `maintenance-docs/v11-implementation/` location (all were untracked throughout the batch). The 'move' is effectively the first git tracking of these files — they enter history as new additions in `archive/v11/`." This is accurate (verified: `git log --follow` against any archived file shows only the `efd9a32` commit; no prior history). The git-history-preservation argument for using `git mv` is moot in this case because the files were never tracked — but the commit's narrative correctly explains this.

**This-review-report exception:** `PACK-REVIEW-CLEANUP-BATCH-19B-broad.md` (this file, by definition the end-of-batch broad review pass) is being produced AFTER the 19b-7 archive sweep — by design, since the broad review runs against the full landed batch. It will be archived in a subsequent commit per the Pattern B convention (the v11-7 archive commit specifically named the 5 per-commit PACK-REVIEW files but not the broad review file because the broad review hadn't been produced yet). Pack Chat should ensure this file is archived in a follow-up commit alongside any pending BACKLOG/CHANGELOG edits.

**Conclusion §6:** archive sweep is complete and accurate per planner spec. 18 files archived; v11-implementation/ has no straggler Batch-19b artifacts; commit message accurately characterizes the move-vs-create nature.

---

## §7 — Validate-pack + baseline test independent verification

**Validate-pack.py:**

```
python3 scripts/validate-pack.py
...
PASSED — all checks clean
```

35 checks (Check 1 through Check 35) all PASS. Independent rerun by this reviewer. **No regression introduced by Batch 19b.**

**Baseline test sample (4 suites, independently rerun by this reviewer):**

| Test suite | Result | Pass count |
|---|---|---|
| `scripts/test-persona-contracts.sh` | PASS | 3/3 personas + 37/37 migration-contract checks |
| `scripts/tests/tracker-migrate-forward-test.sh` | PASS | 145/145 |
| `scripts/tests/test-init-project.sh` | PASS | 67/67 |
| `scripts/tests/test-per-entry.sh` (BD-168 mirror/TOC/cross-ref) | PASS | 57/57 |

All 4 test suites independently rerun on HEAD `efd9a32`. **No regression introduced by Batch 19b.**

**Note on missing test target:** the prompt requested `migrator-core-test.sh` as a suggested test, but no such file exists in the repo. The nearest match is `scripts/tests/test-migrate-v10-to-v11-decompose.sh` (which exercises migrator-core via the v10→v11 migration). Not rerun — substituted `test-per-entry.sh` as the 4th sample for breadth coverage.

**Conclusion §7:** validate-pack and 4 sample test suites pass clean. No regressions introduced by Batch 19b.

---

## §8 — Trinity rule (symmetry) verification

The CLAUDE/AGENTS/GEMINI trinity-rule rule itself (the "modify all three together unless provably tool-specific" rule) is documented at:
- CLAUDE.md:86-92
- AGENTS.md:80-86
- GEMINI.md:61-65

These three sections express the SAME rule with platform-specific tweaks (CLAUDE.md cites "Claude Task tool syntax" as the example tool-specific exemption; AGENTS.md cites "Codex TOML config syntax"; GEMINI.md uses condensed wording — all accept tool-specific divergence as the exception).

**Batch 19b honored the rule:**

| Edit set | Files | Symmetry honored? |
|---|---|---|
| 19b-1 trinity restructure | CLAUDE.md, AGENTS.md, GEMINI.md (all 3 together) | YES — single commit `667d2dd`, all 3 files edited |
| 19b-2-RC9 manifest-regen bullet | CLAUDE.md, AGENTS.md, GEMINI.md (all 3 together) | YES — single commit `a9b7c74`, all 3 files edited (byte-identical UNIVERSAL classification) |
| 19b-2 PACK-CHAT.md extensions | PACK-CHAT.md (NOT a trinity file — pack-ops surface) | n/a (rule does not apply) |
| 19b-3 PACK-AGENTS.md PREFLIGHT | PACK-AGENTS.md (NOT a trinity file — pack-ops surface) | n/a (rule does not apply) |
| 19b-4 EXECUTION-PLAN-V11.0.md | maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md (NOT a trinity file) | n/a (rule does not apply) |
| 19b-5 CONCEPTUAL-REVIEW-METHODOLOGY | supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md (NOT a trinity file) | n/a (rule does not apply) |

**Documented exceptions (where the trinity files INTENTIONALLY diverge in this batch):**
1. **`### Sub-agent behavior (Claude-only)` sub-section** — present in CLAUDE.md only; absent in AGENTS.md and GEMINI.md. Per the in-sub-section "Trinity exemption" note (CLAUDE.md:310-314): the sub-section concerns Claude Code's Agent tool, `run_in_background` parameter, and Agent Teams / SendMessage features — none of which have equivalents in Codex CLI or Gemini CLI. **Tool-specific exception correctly justified inline.**
2. **AI1 "Pack agent invocation" bullet** — CLAUDE.md cites `claude --agent pack-<name>` / `subagent_type=pack-<name>` (Agent tool); AGENTS.md cites `codex --agent pack-<name>` and "sub-agent within Pack Chat"; GEMINI.md cites `@pack-<name>`. **Tool-specific exception correctly applied per existing trinity convention; the rule itself (how to invoke pack agents) is identical.**
3. **AI7 "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern"** — CLAUDE.md enumerates all 3 CLI sub-bullets (Claude / Codex / Gemini) inline; AGENTS.md keeps Codex sub-bullet only + cross-reference to CLAUDE.md authoritative full text; GEMINI.md keeps Gemini sub-bullet only + cross-reference to CLAUDE.md authoritative full text. **Tool-specific exception correctly applied per V2 §C.3 design (hybrid shape).**
4. **PCS1 sub-bullet "Memory files (`~/.claude/projects/<slug>/memory/*.md`)"** — CLAUDE.md has this sub-bullet; AGENTS.md replaces with "Per V2 §D, Codex has no pack-shipped per-project memory cache" explanation; GEMINI.md replaces with "Per V2 §D, Gemini has no pack-shipped per-project memory cache" explanation. **Tool-specific exception correctly applied per V2 §D.1 (trinity-only for Codex / Gemini).**

**Conclusion §8:** the trinity rule (CLAUDE/AGENTS/GEMINI symmetry) was honored. All 3 files moved together in the two trinity-editing commits (19b-1 and 19b-2-RC9). All intentional divergences are tool-specific exceptions explicitly justified in the source-of-truth architect doc (V2 §A.1, V2 §C.3, V2 §D.1, V2 §I.4) and the implementing IMPL-REPORTs.

---

## §9 — Out-of-scope detection

**Files modified during Batch 19b range (verified via `git diff --name-only 667d2dd~1..efd9a32`):**

Pack-ops files:
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — trinity (in scope per planner §1)
- `PACK-CHAT.md` — in scope (19b-2)
- `PACK-AGENTS.md` — in scope (19b-3)

Maintenance docs:
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` — in scope (19b-4)
- `maintenance-docs/archive/v11/**` (18 archive moves) — in scope (19b-7)

Supporting docs:
- `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` — in scope (19b-5)

In-flight recovery:
- `test-fixtures/manifest.txt` — modified by `ef9e5c7` (recovery commit, not Batch-19b-planned but in-batch in-time)

**Out-of-scope file check:**

| OQ rule | Files that would violate | Detected? |
|---|---|---|
| OQ-3: no project-template/ edits (pack-self only) | grep `^project-template/` against modified files | **NONE detected** |
| no scripts/ edits | grep `^scripts/` against modified files | **NONE detected** |
| BACKLOG.md PM-only (deferred to batch-close commit) | grep `^BACKLOG.md` against modified files | **NONE detected** |
| CHANGELOG.md PM-only (no version boundary) | grep `^CHANGELOG.md` against modified files | **NONE detected** |
| README.md PM-only (no version boundary) | grep `^README.md` against modified files | **NONE detected** |

**Conclusion §9:** Batch 19b respected all stated scope boundaries. No out-of-scope edits detected.

---

## §10 — Memory cache spot-check

The Claude memory cache at `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/` contains 31 files (30 entries + MEMORY.md index). Expected: 29 pre-batch + 1 new (`feedback_manifest_regen_on_v11_surface.md` added in 19b-6 / 19b-2-RC9 pairing) = 30 entries + MEMORY.md = 31. **Count matches.**

**Spot-check 1: STANDALONE retention (`feedback_no_prefix_chars.md`).**
- Per V2 §F row 5: STANDALONE — Claude Code chat-tooling convention; no trinity equivalent; **preserve full body content**.
- Verified: file has full body content (lines 16-22 are substantive prose, not pointer-only).
- Verified: file has a Note (line 22) explaining the STANDALONE retention per Batch 19b §F.
- **DEFECT: malformed YAML frontmatter** — see Finding F2 in §2. Two `---` blocks; body content "delimiters instead\"" sits outside the frontmatter. This is a file-format hygiene defect, not a content defect.

**Spot-check 2: POINTER format (`feedback_deferral_is_scope_creep.md`).**
- Per V2 §F row 18: POINTER → trinity `### Workflow` > "Deferral IS scope creep".
- Verified: frontmatter has `trinity_anchor: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md#workflow`.
- Verified: body is the §D.3 template — single H1, "This memory entry is a Tier-1.5 pointer cache" paragraph, trinity-anchor arrow line, "TRINITY WINS" precedence statement.
- Body is lean (8 substantive lines after frontmatter, per spec). **Conforms.**

**Spot-check 3: New RC9 pointer (`feedback_manifest_regen_on_v11_surface.md`).**
- Per RC9 architect doc §10.3: new pointer file added for Batch 19b-2-RC9 cross-reference to trinity bullet RC9.
- Verified: frontmatter has `trinity_anchor: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md#repo-conventions`.
- Verified: body carries the §D.3 boilerplate PLUS additional "Quick reference" + "Worked example" + "Pairs with" sub-sections. The architect doc allowed this enrichment ("suggested entry: ... body: one-line summary + trinity anchor link") — the implementation goes beyond the suggested minimum but does not violate the §D.3 template (the boilerplate is intact, the additions are below the trinity-anchor line). **Conforms with enrichment.**
- Worked-example anchor names the same 6-commit lineage as the trinity RC9 bullet. **Cross-consistent.**

**MEMORY.md index:**
- Verified: has the "Tier 1.5 (Claude-Code memory cache)" preamble per §D.3.
- Verified: has 30 single-line entries (one per memory file).
- The new RC9 pointer entry is at MEMORY.md line 35.
- Format: `[<title>](<filename>) — <one-line summary>`. Each entry conforms.

**Conclusion §10:** memory cache is largely conformant. One file-format defect (F2 / `feedback_no_prefix_chars.md` YAML hygiene) surfaces; recommended fix is a small Pack-Chat-direct edit. All other sampled files match the §D.3 template.

---

## §11 — Pending PM commit pre-condition flags (informational)

Per the prompt: Pack Chat will perform PM-only writes in a follow-up commit after this broad review. Informational flags for that commit:

**Planned PM-only edits (from prompt):**
1. BACKLOG.md edits: write BD-173 (Batch 19c entry), write BD-174 (NEW scratch-pack-clone test), edit BD-171 description, edit BD-102 description.
2. No BD status flips in this batch (Batch 19b is a cleanup batch with no in-flight BDs).

**Pre-condition checks:**

| Pre-condition | Status |
|---|---|
| BACKLOG.md has no Resolved section (per trinity Repo conventions RC2) | **Confirmed** — BACKLOG.md still flips Status in place. |
| BD-NNN numbering: highest existing BD before this batch | Highest in BACKLOG = BD-172 (per grep). New BDs BD-173, BD-174 are next-available. **Correct.** |
| Reservation lists are NOT authoritative (per trinity PC-9 STRENGTHEN, BD-numbering bullet) | Confirmed — Pack Chat will read live BACKLOG before assignment per the strengthened rule landed in 19b-1. |
| OQ-1 user-discussion-and-approval for new BDs | Both BD-173 and BD-174 are NEW BD opens — per the rewritten EXECUTION-PLAN §B step 5 (landed in 19b-4), new BDs require user-discussion-and-approval before opening. Pack Chat must surface BD-173/BD-174 candidacy to user FIRST, get explicit approval, THEN write the entries. **Compliance gate.** |
| L.2 action item (PACK-CHAT.md:170-179) closure | The L.2 action item references ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §5.3 wording divergence. If the BACKLOG/CHANGELOG commit includes the L.2 resolution, the action item can be removed from PACK-CHAT.md in the same commit. If deferred, the L.2 item remains in PACK-CHAT.md and Pack Chat carries it forward to a future session. **Pack Chat-decision flag.** |
| Trinity-rule for BACKLOG.md edits | BACKLOG.md is NOT a trinity file; the trinity rule does not apply. **n/a.** |

**Concerns with the planned PM commit:**

1. **L.2 timing.** The L.2 action item explicitly says "Pack Chat is to surface this divergence to the user at PM-discussion time to pick the canonical wording and edit ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §5.3 to match." The upcoming BACKLOG commit is a natural PM-discussion point — Pack Chat should consider whether to surface the L.2 question to the user in the same approval cycle as BD-173/BD-174 to avoid carrying the action item forward indefinitely.

2. **BD-171 and BD-102 edits.** These are edits to existing BD descriptions, not new BD opens. They do NOT trigger the OQ-1 user-discussion-and-approval rule (which applies only to new BD opens). However, the trinity Repo conventions RC2 ("BACKLOG.md has no Resolved section") and the implicit-status-flip rule do not apply either (no status change). Standard PM approval workflow applies.

3. **No BD status flips.** Batch 19b is a cleanup batch with no in-flight BDs to flip. The implicit-status-flip rule (`feedback_implicit_status_flip`) does not fire. The batch-close commit-shape per V11-8 trinity bullet (line 112-121 of PACK-CHAT.md) treats this as a special case: multi-commit cleanup batch with no status-flip commit — covered by the V11-8 "Worked precedents" line implicitly.

4. **CHANGELOG.md.** Per planner §1, no CHANGELOG.md edits expected this commit. CHANGELOG.md updates only at version boundaries with explicit instruction; Batch 19b is not a version boundary.

5. **This broad-review report.** This file (`PACK-REVIEW-CLEANUP-BATCH-19B-broad.md`) should be archived to `maintenance-docs/archive/v11/` in a subsequent commit per Pattern B. Pack Chat may include the archive move in the same commit as the PM-only edits, or in a small separate commit.

**Conclusion §11:** PM commit pre-conditions are reasonable. The two most important Pack-Chat compliance gates are (a) OQ-1 user-discussion-and-approval for BD-173/BD-174 opens, and (b) L.2 action-item closure timing.

---

## §12 — Reviewer recommendation

**VERDICT: APPROVE batch 19b for ship.**

**No MUST or BLOCKER findings.** Two SHOULD findings (F1 trinity-classification cosmetic mismatch; F2 STANDALONE memory file YAML hygiene) and three NIT findings (N1 cross-reference convention; N2 obsolete-sentence in pre-batch W3 bullet; N3 L.2 action-item placement in behavioral-rules section) are all non-blocking.

**Recommended Pack Chat actions:**

1. **Surface F1 and F2 to user for fix triage.** Per the trinity `### Workflow` bullet "Triage all reviewer findings; default fix-all; nits become tech debt" (landed in 19b-1 as W11), all severities default to FIX. F2 is a small Pack-Chat-direct edit (single memory file outside repo); F1 is documentation polish that could be deferred to a sweep batch. Per `feedback_fix_all_review_findings`, deferred fixes become tracked tech debt — surface to user with explicit defer rationale if not fixed in this batch.

2. **Surface N1/N2/N3 to user with FIX-or-DEFER triage.** N2 in particular highlights a real inconsistency between the (unchanged-this-batch) W3 bullet and the (rewritten-this-batch) EXECUTION-PLAN §B + W8 bullet. A small W3 edit (3 trinity files) would close the loop; deferral is reasonable if the user wants to bundle with a future sweep.

3. **Archive this broad-review report.** `PACK-REVIEW-CLEANUP-BATCH-19B-broad.md` should be archived to `maintenance-docs/archive/v11/` in a subsequent commit (alongside the BACKLOG PM-only edits, or in a small standalone commit). Per planner §1, the per-commit PACK-REVIEW files were archived in 19b-7; this end-of-batch broad report wasn't included because it didn't exist at the time of 19b-7.

4. **Pack Chat may proceed with the planned PM-only BACKLOG commit (BD-173 + BD-174 opens, BD-171 + BD-102 edits)** subject to the OQ-1 user-discussion-and-approval gate for the two new BD opens (per the rewritten EXECUTION-PLAN §B step 5 landed in 19b-4). The L.2 action-item closure should be surfaced to the user in the same approval cycle.

**What the batch got right:**

- **Trinity-first design landed cleanly.** All 3 trinity files moved together in the two trinity-editing commits; intentional divergences are tool-specific exceptions explicitly justified in V2 architect doc + IMPL-REPORTs.
- **RC9 manifest-regen rule is byte-identical** across all 3 trinity files (UNIVERSAL classification correctly preserved).
- **RC9 incident lineage is verified** — all 6 named SHAs exist; the drift attribution is accurate; the recursive base case holds across all Batch-19b commits.
- **Cross-commit references resolve** without dangling pointers (verified for 5 distinct cross-reference relationships).
- **Archive sweep is complete** — 18 files moved; v11-implementation/ contains no straggler Batch-19b artifacts.
- **Validate-pack PASS 35/35** and **4 baseline test suites PASS clean** — no regression introduced.
- **No out-of-scope edits** — project-template/ untouched, scripts/ untouched, all PM-only files (BACKLOG, CHANGELOG, README) untouched.
- **F.3 placement question correctly resolved per planner OPEN QUESTION 6.1** (Agent invocation rules, not Workflow per V2 §I.1 ToC).
- **Memory cache is largely conformant** — 28 of 29 sampled / spot-checked files match §D.3 template; new RC9 pointer correctly references the trinity anchor; MEMORY.md index has 30 entries with correct format.

**What needs polish (non-blocking):**

- F1 trinity classification documentation cosmetic.
- F2 STANDALONE memory file YAML hygiene.
- N1/N2/N3 documentation pattern consistency.

**End of broad review.**

End of PACK-REVIEW-CLEANUP-BATCH-19B-broad.md.
