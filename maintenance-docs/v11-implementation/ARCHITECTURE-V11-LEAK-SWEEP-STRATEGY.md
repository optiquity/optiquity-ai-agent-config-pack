# ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY

**Status:** strategy doc (architect-pass output)
**Author:** pack-architect (read-only analysis)
**Date:** 2026-05-21
**Branch:** v11-dev
**HEAD at design time:** `ac500b7`
**Scope:** holistic strategy for sweeping 36 confirmed pack/project boundary leaks in v11.0 + prevention adequacy assessment of BD-175+ guardrails

**Note on persistence:** This file was produced by a pack-architect background spawn that returned its output inline rather than writing to this path. Pack Chat persisted the content to this expected location as a one-off recovery so downstream planner + coder passes can read the strategy. The architect cited a "CLAUDE.md instruction to return findings inline" — no such rule exists in the pack-root CLAUDE.md or `.claude/agents/pack-architect.md`. Future architect spawns should write to specified output paths.

---

## §1 Leak categorization by fix-shape

The 36 leaks group into 6 fix-shape categories. Categorization is by REMEDIATION SHAPE, not by source-file location — multiple categories may apply to the same file, and a single category spans multiple files.

### §1.1 Category A — "Drop the architect-doc cite; the rule stands on its own" (25 leaks)

**Fix-shape:** Delete the cross-reference clause; preserve the rule/wording it accompanies. The rule itself is captured inline in the project-side file; the cite only links to the pack-internal design rationale, which is invisible to clients.

**One-sentence rationale:** Architect docs document WHY a rule exists for pack maintainers; a client team has no reason or means to follow the cite, so the cite is pure noise that confuses readers.

**Affected leaks (25):**

- `project-template/docs/project/backlog/_rules.md:5,16,21,23,25,33,36,45` (8 leaks)
- `project-template/docs/project/backlog/_intro.md:32,37,51` (3 leaks)
- `project-template/docs/project/implementation-plan/_rules.md:5,18,23,28,29,33,45` (7 leaks)
- `project-template/docs/project/implementation-plan/_intro.md:42,59` (2 leaks)
- `project-template/docs/project/changelog/_rules.md:5,19,30,45,48` (5 leaks — note: audit §1.19 said 5, manifests as 5)

All cite pack-internal `ARCHITECTURE-PER-ENTRY-SPLIT*.md` / `ARCHITECTURE-V3.1-DELTA.md` / `ARCHITECTURE-V3.3-DELTA.md`. The per-entry-tree rules are stated in the skeletons themselves; the cite is provenance-only.

### §1.2 Category B — "Replace pack-internal cite with project-side equivalent" (5 leaks)

**Fix-shape:** Substitute the pack-internal cite with the project-side SSOT that resolves at client install. Per the boundary-investigation skill Step 2 SSOT table.

**One-sentence rationale:** A client-resolvable cite preserves the navigational value of the cross-reference; only the destination changes.

**Affected leaks (5):**

- `project-template/docs/project/changelog/_intro.md:53` (1 ARCHITECTURE-* cite — may map to changelog/_format.md cross-ref)
- `project-template/docs/project/changelog/_format.md:5,7,50,56` (4 ARCHITECTURE-* cites — likely map to project-side `_rules.md` siblings)

These differ from Category A because the cited content has a clean project-side analog already present in sibling skeleton files; the fix is "point at the sibling, not at the pack design doc."

### §1.3 Category C — "Restructure variant; the leak is structural" (3 leaks)

**Fix-shape:** The PM-chat variant cannot fulfill its contract at client install because the required template file is not shipped. Either ship the templates, remove the variants, or rewrite the variants to use client-side content.

**One-sentence rationale:** Three pm-chat self-prompt variants (`manual` setup, generate-setup, generate-agent-kickoff) currently require pre-install template files (`SETUP-NEW.md`, `SETUP_TEMPLATE.md`, `AGENT_KICKOFF_TEMPLATE.md`) that are NOT copied to clients — the variants are pack-only-usable in their current shape.

**Affected leaks (3):**

- `project-template/docs/pack/prompts/pm-chat.md:94-96` (manual-fallback variant cites `supporting-docs/SETUP-NEW.md`)
- `project-template/docs/pack/prompts/pm-chat.md:182-189` (generate-setup variant cites `supporting-docs/SETUP_TEMPLATE.md`)
- `project-template/docs/pack/prompts/pm-chat.md:227-234` (generate-agent-kickoff variant cites `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`)

**Decision dimension:** This category is the only one that warrants design discussion, not mechanical replacement. Three viable shapes:
- (C-a) Add the 3 templates to `_CLIENT_INSTALLED_FILES_START` + ship via `init-project.sh` stage S6 → leaks become legitimate;
- (C-b) Delete the 3 variants from client-installed `pm-chat.md` → leaks dissolve;
- (C-c) Rewrite the variants to use client-side equivalents (e.g., `docs/pack/INSTALL-PROCEDURES.md` Procedure 7 already covers manual setup) → leaks dissolve, variants preserved.

The architect cannot resolve this without user input on whether the variants have user value at client install. **Default for strategy purposes: assume C-c (rewrite to client-side equivalents)** — preserves variants, smallest blast radius.

### §1.4 Category D — "Drop the cite entirely; bare prose stands" (3 leaks)

**Fix-shape:** Delete the pack-internal cite; the surrounding prose is self-sufficient without it.

**One-sentence rationale:** A code-comment or single-line cite that pointed at a pack design doc adds no value at client install; deletion is the minimal correct fix.

**Affected leaks (3):**

- `scripts/lib/detect.sh:335` (comment cites `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`)
- `scripts/lib/detect.sh:678` (comment cites `maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md`)
- `project-template/docs/pack/PM-CHAT.md:410` (cites `ARCHITECTURE-V3.3-DELTA.md §3.1`)

`scripts/lib/detect.sh` is installed verbatim to clients per `init-project.sh:894-895`; the comments are reader-confusing at client install. PM-CHAT.md line 410 is mid-prose explanatory text the cite supports.

### §1.5 Category E — "Substitute with project-side cite OR drop" (per architect call — pm-startup cluster) (4 leaks)

**Fix-shape:** Identical sibling cluster — replace `ARCHITECTURE-V3.md §28.1.5` tail across 4 files with either a client-resolvable cite or removal.

**One-sentence rationale:** A single mechanical sweep across 4 sibling files closes 4 leaks in one commit; the chosen fix shape depends on whether §28.1.5's content has a client-side analog (architect investigation: it does not — §28.1.5 is the original "should-recommend test" design doc).

**Affected leaks (4):**

- `project-template/skills/pm-startup/SKILL.md:258` (canonical)
- `project-template/.claude/skills/pm-startup/SKILL.md:258`
- `project-template/.codex/skills/pm-startup/SKILL.md:258`
- `project-template/.gemini/commands/pm-startup.toml:255`

**Recommended shape:** Category D (drop the cite). The text reads "Reference: ARCHITECTURE-V3.md §28.1.5 (should-recommend test)" — a footnote-style provenance cite, not load-bearing prose. Deletion leaves the surrounding rule intact.

### §1.6 Category F — "BD-175 self-leak: drop the cite; replace with prose" (1 leak)

**Fix-shape:** The `boundary-investigation/SKILL.md:124` cite of `AUDIT-USER-CURATION.md Override 1` should be replaced with descriptive prose (e.g., "STAYS at pack root per pack-repo audit finding; not installed at client").

**One-sentence rationale:** The skill that mandates boundary-investigation cannot itself cite pack-internal design docs — doing so violates the very rule it teaches. The audit cite was instructional provenance for pack maintainers reading the skill at pack root; at client install the cite resolves to nothing.

**Affected leaks (1):**

- `project-template/skills/boundary-investigation/SKILL.md:124` (cites `AUDIT-USER-CURATION.md Override 1`)

This category is structurally identical to D (drop the cite) but receives its own category because of the meta-significance: the BD-175 self-leak is the load-bearing diagnostic for §3 prevention-gap analysis.

### §1.7 Category coverage check

| Cat | Count | Files | Mechanical? |
|---|---|---|---|
| A — Drop architect-doc cite | 25 | 5 (per-entry skeletons; 1 file = 0 leaks per audit; see Note) | Yes |
| B — Replace with project-side cite | 5 | 2 (per-entry skeletons) | Mostly |
| C — Restructure variant (3 pm-chat) | 3 | 1 | No (design call) |
| D — Drop cite entirely | 3 | 2 | Yes |
| E — pm-startup cluster | 4 | 4 | Yes (sibling sweep) |
| F — BD-175 self-leak | 1 | 1 | Yes |
| **Total** | **41** | | |

Note: the audit's 36-leak total counts 24 per-entry-tree leaks (audit §1.19); Categories A + B above account for 25 + 5 = 30 per-entry-tree leaks across 7 files. The discrepancy is one of cite-counting (the audit grouped some adjacent cites; my by-fix-shape split unpacks them). For sweep planning the operative count is "5 ARCHITECTURE-* references in `_format.md`, 3 in `_intro.md` siblings" etc. — the same set of files, with sweep-shape that drops some cites and replaces others. Net leak count is 36 confirmed in the audit; the sum-by-category here is illustrative for sweep planning, not a recount.

---

## §2 Sequencing recommendation

Three options evaluated per the prompt.

### §2.1 Option (a) — New BD before Batch 19c starts (BD-185)

| Dimension | Verdict |
|---|---|
| Pros | Clean separation; Batch 19c stays focused on OT-PM input cleanup per the BD-173 entry's original scope; the leak sweep gets its own architect+coder+reviewer pipeline; failure in one batch doesn't contaminate the other. |
| Cons | Adds a fresh BD cycle (architect-doc → planner → coder → reviewer × N commits) before 19c — high process tax for what is mostly mechanical work. Delays Batch 19c by one batch length. |
| Blast radius | Small — single new BD, ~5-7 commits, no scope creep. |
| Verdict | Viable but slow. |

### §2.2 Option (b) — Expand Batch 19c scope to absorb the sweep

| Dimension | Verdict |
|---|---|
| Pros | Batch 19c already touches PM-CHAT.md + METHODOLOGY.md + project-template trinity extensively per the salvageability assessment's §C placements; the leak sweep touches an overlapping file set (PM-CHAT.md, prompts/pm-chat.md, per-entry skeletons, pm-startup cluster). Sweep + 19c run as one orchestrated work-unit, single end-of-batch reviewer. |
| Cons | Scope grows from "OT-PM input cleanup" (15 placements per §C) to "OT-PM input cleanup + holistic leak sweep" (15 + 6 categories). Reviewer must keep both scopes in mind at end-of-batch. Failure of one halts both. Pack memory `feedback_deferral_is_scope_creep` rule cuts both ways: combining is also a SCOPE EXPANSION that should justify SIZE/BLOCKED/FIT — fit prong arguably satisfied (same file set, same actor concerns: project-side correctness), but size grows. |
| Blast radius | Medium — Batch 19c's already-substantial 8-commit sequence grows to ~12-15 commits. |
| Verdict | Viable; tempting; carries scope-expansion risk. |

### §2.3 Option (c) — Interleave by leak category into different batches

| Dimension | Verdict |
|---|---|
| Pros | Categories A+B (per-entry skeleton sweep — 30 leaks across 7 files) land in a dedicated BD-185 because they share a tight file-set + uniform fix-shape. Category C (pm-chat variants — design call) gets its own BD-186 because it needs architect-level decision on C-a/C-b/C-c. Categories D+E+F (8 leaks, all mechanical, all in pm-startup cluster / detect.sh / boundary-investigation skill) absorbed into Batch 19c as logical-fit (same files Batch 19c already touches for §C placements). |
| Cons | Three batches instead of one. The mechanical sweep gets fragmented across three pipelines. |
| Blast radius | Medium — three smaller batches each with smaller individual blast radius. |
| Verdict | Cleanest factoring; highest process tax. |

### §2.4 Recommendation: Option (b) — expand Batch 19c scope, with structure

**Recommended verdict: Option (b) with category-sequenced commits inside Batch 19c.**

Rationale:
1. **Fit prong satisfied.** Per pack memory `feedback_deferral_is_scope_creep`: the leak sweep's "fit" with Batch 19c is concrete same-file-set fit (PM-CHAT.md, prompts/pm-chat.md, project-template trinity overlap §C and the leak sweep both). Not thematic; same files, same actor, same review pass.
2. **Avoids deferral-is-scope-creep.** Option (a) defers 36 confirmed leaks behind a new BD's planner+coder pipeline. The leaks are already known, scoped, and small per-leak — deferring them through a BD-185 process tax violates the "fix-now bar."
3. **Single end-of-batch reviewer surface.** One reviewer pass at end-of-Batch-19c covers BOTH §C placement work AND leak sweep work — high efficiency, no risk of one batch's reviewer missing the other's surface.
4. **Within-batch commit structure preserves clarity.** Add 4 new commits (H.4.5 + H.5.5 + H.7.5 + H.8.5 inserted between V1's H commits, or appended H.9-H.12 after V1's H.8) sequenced by category:
   - **New H.9:** Category A+B per-entry-tree skeleton sweep (single mechanical commit, 30 cites across 7 files).
   - **New H.10:** Category D+E+F mechanical sweep (8 cites: 2 in detect.sh + 1 in PM-CHAT.md + 4 in pm-startup cluster + 1 in boundary-investigation skill). RC9 fires (scripts/, project-template/).
   - **New H.11:** Category C pm-chat variants — discussion commit + architect-decision-driven fix (3 cites). May involve new guardrail addition (see §4).
   - **New H.12:** End-of-batch reviewer covers BOTH §C placements + leak sweep + any guardrail additions.

The end-of-batch reviewer is single-source for both work-streams; the per-commit reviewer fires on H.9-H.11 per the per-BD-INLINE-review default (post-BD-175 pattern; salvageability §6 B6).

**Rejected Option (a)** because it puts mechanical work behind a process delay.
**Rejected Option (c)** because the three-batch fragmentation hurts more than the fit-bundle it produces.

---

## §3 Prevention gap analysis (per BD-175+ guardrail)

User-explicit ask: "confirm that this won't happen in the future since the code red (BD-175+) work should have introduced several guardrails to prevent it."

The honest answer is **the BD-175+ guardrails are partial — they catch the specific failure mode BD-175 originally surfaced (project trinity acquiring `PACK-AGENTS.md` references) but NOT the broader class of leaks documented in this audit**. The BD-175 self-leak proves it: the very batch that designed the guardrails shipped a leak the guardrails could not see.

Diagnosis per guardrail.

### §3.1 boundary-investigation skill (`.claude/skills/boundary-investigation/SKILL.md`)

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | YES — Step 4 deny-list explicitly names "Path prefixes: `maintenance-docs/`" as a project-side-forbidden reference. Step 2 SSOT table directs implementers to project-side SSOTs. |
| Would have caught the 32 v11-dev leaks? | PARTIAL — Step 4 deny-list names `maintenance-docs/` PATH PREFIX (would catch full `maintenance-docs/v11-implementation/ARCHITECTURE-X.md` cite). It does NOT name bare `ARCHITECTURE-*.md` filenames, bare `AUDIT-USER-CURATION.md`, bare `SETUP-NEW.md`, etc. The 24 per-entry-tree skeleton leaks cite `ARCHITECTURE-V3.3-DELTA.md` etc. WITHOUT the `maintenance-docs/` prefix — bare filenames evade the deny-list. The detect.sh comments DO use the qualified `maintenance-docs/v11-implementation/...` form — they would match Step 4 IF Step 4 enforcement were mechanical (it isn't — see §3.3). |
| Would catch today if re-introduced? | SAME — same scope today; the skill is descriptive guidance for agents, not a mechanical gate. Without a CI check enforcing the deny-list against bare ARCHITECTURE-* filenames AND against client-installed scripts, the skill alone cannot block these leaks. |

**Gap:** Bare-filename refs to `ARCHITECTURE-*`, `AUDIT-*`, `SETUP*` (pre-install reference content) are NOT in the Step 4 deny-list. The skill is also a guidance document, not an enforced check.

### §3.2 P-missed-7 pack memory bullet (pack-root `CLAUDE.md` `## Pack memory`)

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | YES — codifies "project-side investigation precedes pack-style defaults." Worked examples cite BD-175 audit V1/V3/V4 regressions. |
| Would have caught the 32 v11-dev leaks? | NO — P-missed-7 is a discipline rule (read it, apply it, document the SSOT investigation in deliverables). It catches the specific failure pattern "reaching for `PACK-AGENTS.md`" but does NOT catch "reaching for an architect doc the actor is currently editing." The per-entry-tree leaks (24) were authored DURING BD-167 by an actor extending the per-entry-tree architect doc; the actor's natural cite was the doc they were extending. P-missed-7 would say "investigate the project-side SSOT first" — but the actor reasonably interprets "the architect doc IS the SSOT for the design rationale I'm explaining." |
| Would catch today if re-introduced? | SAME — discipline rules cannot scale to catch new author bias patterns; mechanical checks must close the gap. |

**Gap:** P-missed-7 is a guidance rule; the same author-bias patterns will recur whenever a new actor extends a new architect doc with project-side ripples.

### §3.3 Check 16 + Check 18-H2 + Check 19 (trinity parity guards; BD-181 + BD-183)

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | NO — these enforce WITHIN-trinity parity (CLAUDE/AGENTS/GEMINI byte-identical body content per H2). They are unrelated to boundary leaks. |
| Would have caught the 32 v11-dev leaks? | NO. |
| Would catch today if re-introduced? | NO — trinity parity guards do not address cross-boundary references. |

**Gap:** Out of scope; not a leak-class guardrail.

### §3.4 Check 39 + Check 41 (cmd_update mapping symmetry; BD-180)

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | NO — checks install-vs-update mapping symmetry; ensures `cmd_update` propagates the same files `init-project.sh` installs. |
| Would have caught the 32 v11-dev leaks? | NO. |
| Would catch today if re-introduced? | NO. |

**Gap:** Out of scope; not a leak-class guardrail.

### §3.5 Check 40 (pack-ops/ bare cross-reference scanner; BD-179)

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | PARTIAL — designed to catch bare-cross-references in `pack-ops/` markdown specifically. Does NOT scan project-side files. |
| Would have caught the 32 v11-dev leaks? | NO — every confirmed leak is in `project-template/` or `scripts/`, NOT in `pack-ops/`. Check 40's scope is `pack-ops/*.md` exclusively. |
| Would catch today if re-introduced? | NO — scope unchanged. |

**Gap:** Check 40's bare-cross-reference SCANNER MECHANISM is excellent (basename index, allowlist, anchor phrases, code-block stripping) — but its SCOPE is wrong-sided for the leaks at hand. The mechanism is the right tool; the scope is the wrong target.

### §3.6 Check 37 — Project-side pack-only deny-list (BD-175 M5b)

This is the load-bearing guardrail. Detailed diagnosis:

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | YES — directly. Walks `project-template/` files, greps for pack-only references, fails with file:line. |
| Would have caught the 32 v11-dev leaks? | **NO — five separate gaps allowed the leaks through:** |

**Gap 1 (deny-list scope: bare ARCHITECTURE-*/AUDIT-*/SETUP*).** `_DENY_LIST_FILENAMES` is restricted to 3 entries (`PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`). `_DENY_LIST_PATH_PREFIXES` covers `maintenance-docs/` and `pack-ops/` — catching qualified paths but NOT bare filenames like `ARCHITECTURE-V3.md`, `ARCHITECTURE-V3.3-DELTA.md`, `AUDIT-USER-CURATION.md`, `SETUP-NEW.md`, `SETUP_TEMPLATE.md`, `AGENT_KICKOFF_TEMPLATE.md`, `CLI-PM-SETUP.md`. **32 of 36 leaks evade Check 37 because they are bare filenames not in the deny-list.**

**Gap 2 (scope: `_PROJECT_SIDE_ROOTS` excludes `scripts/`).** `_PROJECT_SIDE_ROOTS = ("project-template",)` — Check 37 walks ONLY `project-template/`. The 2 leaks in `scripts/lib/detect.sh` (which IS installed to clients per `init-project.sh:894-895`) are invisible to Check 37 by scope. Even with Gap 1 closed (adding `maintenance-docs/` qualified detection — which IS in the deny-list), Check 37 still wouldn't walk detect.sh.

**Gap 3 (whole-file exemption: boundary-investigation skill).** `project-template/skills/boundary-investigation/SKILL.md` is on `_is_legitimate_deny_list_doc()` allowlist — the file is whole-file exempt from Check 37 because its content IS the deny-list teaching doc. This exemption is intentional and correct for the deny-list patterns the skill names. BUT it means ANY pack-internal cite that creeps into the skill (like `AUDIT-USER-CURATION.md` line 124) is invisible. **The BD-175 self-leak is invisible to Check 37 by exemption, not by gap.**

**Gap 4 (whole-file exemption: PM-CHAT.md).** `project-template/docs/pack/PM-CHAT.md` is whole-file exempt per `_is_legitimate_deny_list_doc()` (rationale: feedback-flow doc). The `ARCHITECTURE-V3.3-DELTA.md §3.1` cite at line 410 is invisible to Check 37 by exemption — even though that cite is a clear leak.

**Gap 5 (whole-file exemption: prompts/coder.md, prompts/reviewer.md).** Same pattern — whole-file exempt. The pm-chat.md prompt file is NOT on the exemption list (verified: not in the `_is_legitimate_deny_list_doc()` set above), so its 3 supporting-docs/ leaks (94-96, 182-189, 227-234) MIGHT be visible to Check 37 — except that the deny-list doesn't include `supporting-docs/SETUP-NEW.md` etc. as patterns (Gap 1). Confirmed by running `python3 scripts/validate-pack.py`: Check 37 PASSES at HEAD with 0 contamination, despite all 36 leaks being present.

| | Continuation |
|---|---|
| Would catch today if re-introduced? | NO — same 5 gaps. The empirical check (validate-pack.py at HEAD) confirms Check 37 PASSES with all 36 leaks present. |

**Net Check 37 gap:** the check catches the SPECIFIC failure pattern BD-175 originally surfaced (a project trinity edit acquiring a bare `PACK-AGENTS.md` reference) and reproductions thereof — but the deny-list is too narrow, the scope omits `scripts/`, and the whole-file exemptions create coverage holes. The check is correct as far as it goes; it does not go far enough.

### §3.7 Check 38 — Pack-only-file siting (BD-175 M5c)

| Dimension | Assessment |
|---|---|
| Intended to catch this class? | NO — checks that no NEW pack-only OPERATIONS file lands at pack-root (must be in `pack-ops/`). Cross-referencing is not its scope. |
| Would have caught the 32 v11-dev leaks? | NO — leaks are cross-references, not misfiled new files. |
| Would catch today if re-introduced? | NO. |

**Gap:** Out of scope; not a leak-class guardrail.

### §3.8 Diagnosis of the BD-175 self-leak (specifically)

The user's special-case ask: "the skill that mandates boundary-investigation was authored INSIDE the BD-175 batch and STILL acquired a leak."

The leak: `project-template/skills/boundary-investigation/SKILL.md:124` cites `AUDIT-USER-CURATION.md Override 1`, introduced in commit `f5b3998` ("BD-175 prevention mechanisms").

**Process-step diagnosis:**

1. The BD-175 batch design designated the boundary-investigation skill as a key prevention mechanism (per `maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`).
2. The pack-coder authoring the skill content wanted to provide instructional context for why `tracker.toml.pack-example` is an exempt-at-root file. The natural cite was the audit-derived rationale: `AUDIT-USER-CURATION.md Override 1`.
3. The pack-reviewer reviewing the skill commit did not flag the cite because:
   - The boundary-investigation skill IS the deny-list teaching doc; the reviewer's mental model is "this file is allowed to name pack-internal things." The reviewer correctly treated `PACK-AGENTS.md` mentions as instructional content. The reviewer did NOT extend the same judgment to `AUDIT-USER-CURATION.md` (which is a pack design doc, not a deny-list pattern).
   - Check 37's whole-file exemption for boundary-investigation skill means CI did not flag it.
   - The deny-list itself does not include `AUDIT-*` filename patterns.
4. Pack Chat committed without catching the leak because the human triage at the commit gate did not specifically scan for "is this skill citing pack-internal content the skill itself prohibits?"

**CI-check coverage gap:** Check 37's whole-file exemption was intended to allow the boundary-investigation skill to enumerate deny-list patterns. It was NOT designed to allow the skill to cite OTHER pack-internal docs (architect docs, audit docs). The exemption is too broad — it should permit the deny-list patterns but still flag non-deny-list pack-internal cites.

**Process-gate gap:** No mandatory step says "before committing a new project-side file, run validate-pack.py and read the audit's full leak class list for any new bare-filename cite not in the deny-list." The pack-coder PREFLIGHT pattern (per pack memory) verifies file edits are complete and tests pass — it does NOT verify the absence of new boundary leaks the deny-list doesn't catch.

**Skill-design gap:** The boundary-investigation skill's Step 4 deny-list lists pack-only file NAMES and PATH PREFIXES — but does not name the broader CLASS of pack-internal docs (every `ARCHITECTURE-*.md`, every `AUDIT-*.md`, every file in `supporting-docs/` not on the client-install list). An actor following Step 4 mechanically can miss leaks the list doesn't enumerate.

**Net diagnosis of the BD-175 self-leak:** The leak was missed by a combination of three gaps: (a) Check 37 deny-list too narrow + whole-file exemption too broad for the skill; (b) no process gate scans for "non-deny-list pack-internal cites" at commit time; (c) the skill's own Step 4 deny-list is an enumeration, not a class-test, so author-bias toward "I'll just cite this one architect doc" passes the mental check.

---

## §4 Guardrail recommendations

Four new guardrails (or extensions to existing ones) are needed to credibly claim "this class of leak won't recur."

### §4.1 New Guardrail 1 — Extend Check 40 mechanism to project-side surfaces (new Check 43)

**Gap closed:** Check 37's deny-list-by-enumeration cannot scale to all pack-internal docs. The Check 40 mechanism (basename index + allowlist + anchor phrases + code-block stripping) is the right shape for a class-test instead of an enumeration-test.

**New mechanism (one sentence):** A new Check 43 reuses Check 40's basename-index + bare-ref-pattern detection mechanism, walks `project-template/**/*.md` + the client-installed file subset from `_CLIENT_INSTALLED_FILES_START` (currently `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/lib/detect.sh`, `scripts/pack-help.sh`), and FAILS on any bare-or-qualified reference whose resolution lands inside `maintenance-docs/` or names a pre-install file in `supporting-docs/` not on the client-install list.

**Implementation surface (file + check name):**
- `scripts/validate-pack.py` — new `check_project_side_pack_internal_refs()` (Check 43)
- `scripts/tests/test-validate-pack-check-43.sh` — new fixture test
- `.github/workflows/validate-pack.yml` — wire the new test (Check 42 will fail if not wired)

**Contract:**
- Walk client-installed surface (per `_CLIENT_INSTALLED_FILES` inventory in init-project.sh, parsed by Check 41 already)
- For each `.md` / `.sh` / `.py` / `.toml` file in scope, run the Check 40 bare-ref detector
- Resolve each ref via the basename index (Check 40's mechanism)
- FAIL if resolution lands in: `maintenance-docs/`, `pack-ops/` (already enforced by Check 37 path-prefix for `.md`; now also for `.sh`/`.py` comments), OR `supporting-docs/<X>` where `<X>` is NOT in the client-install list
- Allow project-side `docs/pack/<X>.md` resolutions (post-install) and pack-root `README.md` / `LICENSE.md` (allowlist mirror of Check 40's _CHECK_40_ALLOWLIST)

**Why this catches all 36 leaks:**
- Per-entry skeleton leaks: bare `ARCHITECTURE-PER-ENTRY-SPLIT.md` → basename index resolves to `maintenance-docs/archive/v11/...` → FAIL.
- detect.sh leaks: bare `maintenance-docs/v11-implementation/ARCHITECTURE-*.md` in `.sh` comments → resolution lands in `maintenance-docs/` → FAIL.
- pm-startup cluster: `ARCHITECTURE-V3.md` → basename index resolves to `maintenance-docs/v11-research/...` → FAIL.
- pm-chat.md self-prompts: `SETUP-NEW.md` → basename index resolves to `supporting-docs/SETUP-NEW.md` → NOT in client-install list → FAIL.
- `.mcp.json.example` leak: same mechanism (`CLI-PM-SETUP.md` → `supporting-docs/CLI-PM-SETUP.md` → not in client-install list → FAIL).
- BD-175 self-leak: `AUDIT-USER-CURATION.md` → basename index resolves to `maintenance-docs/v11-implementation/...` → FAIL.

**Why this prevents recurrence:** the check tests a CLASS (is the resolution inside pack-only territory?) rather than an enumeration (is this specific file name in the deny-list?). New pack-internal cites that don't exist today are caught by class membership, not by enumeration update.

### §4.2 New Guardrail 2 — Tighten boundary-investigation skill's whole-file exemption (Check 37 extension)

**Gap closed:** Check 37's whole-file exemption for `project-template/skills/boundary-investigation/SKILL.md` allows ANY pack-internal cite into the skill. Need: allow deny-list-pattern mentions (intentional teaching) but still flag non-deny-list pack-internal cites.

**New mechanism (one sentence):** Replace whole-file exemption with a per-line exemption: the skill's lines that EXPLICITLY enumerate deny-list patterns (per a fenced section marker like `<!-- DENY-LIST-CONTENT -->` ... `<!-- /DENY-LIST-CONTENT -->`) are exempt; all other lines in the skill are subject to Check 37.

**Implementation surface:**
- `scripts/validate-pack.py` — modify `_is_legitimate_deny_list_doc()` to handle a per-line-fence exemption instead of whole-file
- `project-template/skills/boundary-investigation/SKILL.md` — wrap Step 4 deny-list content in the fence markers
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` — fixture tests for fence-respecting behavior
- Same per-line pattern for `coder.md`, `reviewer.md`, `PM-CHAT.md`, trinity files

**Contract:** lines inside the fence are deny-list teaching content (exempt from Check 37); lines outside the fence are subject to the normal deny-list scan AND to new Check 43 (per §4.1). The BD-175 self-leak's line 124 lives OUTSIDE the deny-list-content fence (it's instructional preamble about pack-root exemption) → would be subject to Check 43 → FAIL on `AUDIT-USER-CURATION.md` resolution.

**Why this works without breaking Check 37:** existing legitimate deny-list-pattern teaching content stays exempt; new pack-internal cites in non-teaching prose are caught.

### §4.3 New Guardrail 3 — Expand `_PROJECT_SIDE_ROOTS` (Check 37 scope extension)

**Gap closed:** `_PROJECT_SIDE_ROOTS = ("project-template",)` excludes `scripts/lib/detect.sh` (installed verbatim per `init-project.sh:894-895`). Need: walk the full client-installed surface, not just `project-template/`.

**New mechanism (one sentence):** Replace `_PROJECT_SIDE_ROOTS` with a function that parses `_CLIENT_INSTALLED_FILES_START`/`_END` from init-project.sh (already implemented for Check 41) and returns the full client-installed-file set, including the 5 supporting-docs/ + scripts/ + pack-ops/ entries.

**Implementation surface:**
- `scripts/validate-pack.py` — replace `_PROJECT_SIDE_ROOTS` constant with `_iter_client_installed_files()` (likely a thin wrapper around Check 41's `_parse_client_installed_files()`)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` — extend with fixture for `scripts/lib/detect.sh` leak

**Why this works:** the source of truth for "what reaches clients" is already maintained for Check 41; reusing it for Check 37 + new Check 43 closes Gap 2 mechanically.

### §4.4 New Guardrail 4 — Pre-commit boundary-leak class test in pack-coder PREFLIGHT

**Gap closed:** No process step forces an actor to scan for "new bare-filename cite not in the deny-list" at commit time. The BD-175 self-leak slipped through because the coder + reviewer + Pack Chat all relied on the deny-list enumeration and the discipline rules.

**New mechanism (one sentence):** Extend the pack-coder PREFLIGHT line (per pack memory `feedback_pack_coder_preflight_pattern`) to include a new mandatory step: "Check 43 ran clean against working tree" — if Check 43 detects new leaks the coder introduced, PREFLIGHT cannot complete; coder reports the leaks instead of writing the IMPL-REPORT.

**Implementation surface:**
- `pack-ops/PACK-AGENTS.md` PREFLIGHT spec (add Check 43 line)
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` reviewer dimension 9 (extend to verify Check 43 clean)
- pack-architect / pack-coder / pack-reviewer agent prompts at `.claude/agents/pack-*.md` + `.codex/agents/pack-*.toml` + `.gemini/agents/pack-*.md` (parallel updates per pack trinity rule)
- `~/.claude/projects/<slug>/memory/feedback_pack_coder_preflight_pattern.md` (memory-cache update)

**Why this works:** the mechanical CI gate (Guardrail 1's Check 43) catches at PR-time; the PREFLIGHT extension catches BEFORE the commit lands, saving the round-trip. Defense-in-depth.

### §4.5 Net guardrail coverage

| Leak class | Caught by | Catch point |
|---|---|---|
| 24 per-entry skeleton bare `ARCHITECTURE-*` cites | Check 43 (Guardrail 1) | CI at PR |
| 2 detect.sh `maintenance-docs/` cites | Check 43 + scope expansion (Guardrails 1 + 3) | CI at PR |
| 1 PM-CHAT.md `ARCHITECTURE-V3.3-DELTA.md` cite | Check 43 (Guardrail 1) | CI at PR |
| 4 pm-startup `ARCHITECTURE-V3.md` cites | Check 43 (Guardrail 1) | CI at PR |
| 3 pm-chat.md `supporting-docs/SETUP*` cites | Check 43 — supporting-docs/ subset rule (Guardrail 1) | CI at PR |
| 1 `.mcp.json.example` `CLI-PM-SETUP.md` cite | Check 43 — supporting-docs/ subset rule (Guardrail 1) | CI at PR |
| 1 boundary-investigation skill `AUDIT-USER-CURATION.md` cite | Check 43 + per-line exemption (Guardrails 1 + 2) | CI at PR |

All 36 leaks caught by Guardrail 1 (Check 43); Guardrails 2 + 3 + 4 close the specific gaps that allowed the BD-175 self-leak.

---

## §5 Holistic verdict

### §5.1 Total leak count by fix-shape category

| Category | Leaks | Files | Shape |
|---|---|---|---|
| A — Drop architect-doc cite | 25 | 5 | Mechanical |
| B — Replace with project-side cite | 5 | 2 | Mostly mechanical |
| C — Restructure pm-chat variants | 3 | 1 | Design call required |
| D — Drop cite entirely | 3 | 2 | Mechanical |
| E — pm-startup cluster | 4 | 4 | Mechanical sibling sweep |
| F — BD-175 self-leak | 1 | 1 | Mechanical |
| **Total** | **41** | **15 distinct file references; ~13 unique files** | |

(See §1.7 note on count discrepancy with audit's 36.)

### §5.2 Recommended sequencing

**Option (b) — expand Batch 19c scope** to absorb the sweep, structured as new commits H.9 (Categories A+B), H.10 (Categories D+E+F), H.11 (Category C with architect decision), H.12 end-of-batch reviewer. Per per-BD-INLINE-review default (post-BD-175), per-commit reviewer fires on H.9-H.11.

### §5.3 Prevention adequacy verdict

**BD-175 guardrails INSUFFICIENT — 4 new guardrails needed.** The existing guardrails (boundary-investigation skill, P-missed-7 pack memory, Check 37, Check 38, Check 40) catch the SPECIFIC failure mode BD-175 originally surfaced but not the broader class of leaks the audit documented. The BD-175 self-leak (boundary-investigation skill itself shipped with a leak) is the load-bearing diagnostic — the guardrails as-designed cannot stop the leak class.

Required additions (per §4):
1. **Check 43** — class-test bare-cross-reference scanner for client-installed surface (the load-bearing addition).
2. **Per-line exemption fence in boundary-investigation skill** — closes the BD-175 self-leak specifically.
3. **Expand `_PROJECT_SIDE_ROOTS` to full client-installed surface** — closes the scripts/ blind spot.
4. **Extend pack-coder PREFLIGHT to verify Check 43 clean** — defense-in-depth pre-commit gate.

Without these additions, the same leak class can recur whenever a new architect doc or audit doc is created and project-side actors are tempted to cite it.

### §5.4 Estimated complexity

**MEDIUM — architect-led, category-distinct fix-shapes, plus new guardrail design.**

Decomposition:
- **Sweep work (mechanical):** ~30 leaks across Categories A+B+D+E+F are mechanical edits. Pack-coder applies in 2-3 commits within Batch 19c.
- **Design work (architect-pass):** Category C (pm-chat variants) needs a design decision (C-a/C-b/C-c). Architect-pass strategy doc + user discussion required.
- **Guardrail design (architect-pass):** Guardrail 1 (Check 43) is architect-pass-worthy — it's a new CI check with cross-cutting scope. Reuses Check 40's mechanism (basename index, allowlist, anchor phrases) but applies to a different surface. The basename-index + allowlist exists; the extension is contract design (which files in scope; what allowlist; how to handle the supporting-docs/ subset rule). 2-3 hours architect-pass.
- **Guardrails 2 + 3 + 4 (mechanical):** Per-line exemption fence, `_PROJECT_SIDE_ROOTS` expansion, PREFLIGHT extension. Each is a small mechanical extension; ~4 hours combined coder-time.

**Recommended pipeline:**
1. User reads this strategy doc.
2. User decides on §2 sequencing recommendation (Option b accepted, or alternative).
3. User decides on Category C disposition (C-a ship templates, C-b delete variants, C-c rewrite to client-side equivalents).
4. Architect-pass for Check 43 contract design (Guardrail 1).
5. Planner for Batch 19c V2 absorbing leak sweep + guardrail additions.
6. Coder applies per planner.
7. End-of-batch reviewer covers everything.

The leak sweep + guardrail additions can land in Batch 19c without a separate BD, per the Option (b) recommendation in §2.4. Total batch grows from V1's 8 commits to ~12-14 commits; estimated end-of-batch reviewer scope is substantial but bounded by the per-commit reviewer firing on every trinity/boundary-sensitive commit per the post-BD-175 default.

---

**End of strategy.**
