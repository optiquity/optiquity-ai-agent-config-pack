# ADVERSARIAL REVIEW — PLAN-BD-209.md

**Reviewer:** pack-planner (adversarial) · **HEAD:** `4086705` (`40867052b31e822e1742de4806016bdca1131f6e`) · **Date:** 2026-06-05 · **Branch:** v11-dev
**Under review:** `maintenance-docs/v11-implementation/PLAN-BD-209.md` (corrected plan; HARD-RETIRE + A13 fold).
**Mandate:** independently re-measure the blast radius and try to break the corrected plan. REVIEW ONLY — no source edits, no plan edits, no git verbs.

---

## VERDICT — NOT-SOUND (1 MUST + 2 SHOULD + 1 NIT). No BLOCKER.

The plan's **in-scope file set is complete**, its **Sense-A/B classification is correct**, the **A13 fold is correct on all 3 lockstep surfaces**, the **token-trap-safe commit subject is sound**, and there are **no missed Sense-A surfaces outside the 16-file set**. The prior under-enumeration of the test file IS fixed (all 18 occurrences covered; the multi-line `§ "PM-only files and directories"` comment is confirmed real and covered). HOWEVER, my independent re-measurement found:

1. **MUST — the completeness GATE has a pattern blind spot:** it does NOT match the bare local variable `is_pm_only` (underscore, no leading `_`) at `validate-pack.py:3951` and `:3982`. The plan's central claim that the gate is "the authoritative completeness check ... enumeration-independent" (§5.1 step-4, §6) is therefore FALSE for that token form.
2. **SHOULD — the plan's headline occurrence counts are over-stated** (claims 125 total / 123 Sense-A; true is **122 / 120**), traceable entirely to a `validate-pack.py` miscount (claims 37, true is **34**). The gate still enforces correctly, but a "re-measured exact" plan must not carry wrong load-bearing counts — it repeats (in milder form) the measurement-discipline failure the rename memory was written to prevent.
3. **SHOULD — the §2A trinity row sub-counts are wrong** (claims row :78/:80 = 3 occ, row :60 = 2 occ; true is **4 / 4 / 3**), an internal-attribution error.
4. **NIT — internal count inconsistency between PLAN (125/37) and its source ARCHITECTURE (130/36) and RESEARCH (1248 raw; vp "36 occurrences")** — three documents, three different validate-pack.py numbers, none equal to the measured 34.

Each finding has file:line evidence + exact fix below. None blocks implementation IF fixed; the MUST is the one a coder must not rely on as-written.

---

## GAP-1 (MUST) — completeness gate misses the bare local `is_pm_only`

**Evidence (my measurement at HEAD `40867052`):**

The gate pattern (plan §5.1 step-4 / §6) is:
```
grep -rnE 'PM-only|pack-memory-only|PM_ONLY|pm-only|_is_pm_only' <16 files>
```
The Check-36 driver uses a **bare local variable** `is_pm_only` (underscore separator, NO leading underscore):
```
3950:        is_pm_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PM_ONLY)
3951:        if not (is_pack_only or is_project_only or is_pm_only):
3982:        if is_pm_only:
3983:            offenders = [p for p in paths if not _is_pm_only_permitted(p)]
```
Tested each gate alternative against the string `is_pm_only`:
- `PM_ONLY` — uppercase; does NOT match lowercase `is_pm_only`.
- `pm-only` — hyphen; `is_pm_only` uses an underscore → no match.
- `_is_pm_only` — requires a LEADING underscore; the bare local has none → no match.

Direct test (verbatim):
```
$ echo "        if is_pm_only:" | grep -oE 'PM-only|pack-memory-only|PM_ONLY|pm-only|_is_pm_only'
>>> GATE MISSES: 'if is_pm_only:' would survive a forgotten local-var rename and the gate would NOT flag it <<<
$ echo "        if not (is_pack_only or is_project_only or is_pm_only):" | grep -oE 'PM-only|pack-memory-only|PM_ONLY|pm-only|_is_pm_only'
>>> GATE MISSES is_pm_only here too <<<
```
Lines :3951 and :3982 contain ONLY the bare local `is_pm_only` (no other family token). Line :3950 happens to ALSO contain `_SCOPE_KEYWORDS_PM_ONLY` (matched via `PM_ONLY`), and :3983 also contains `_is_pm_only_permitted` (matched via `_is_pm_only`) — so :3950/:3983 are coincidentally gate-visible, but **:3951 and :3982 are gate-invisible.**

**Why this matters (the plan's own claim is the defect):** §5.1 step-4 states the gate "does not depend on the §2 task enumeration being exhaustive; if a task list under-enumerates, this gate catches the residue," and §6 calls it "enumeration-independent." That is the entire safety thesis of the corrected plan (and of memory `rename-plans-measure-then-bound`). It is FALSE for `is_pm_only`: a coder who renames the keyword symbol but forgets the bare local at :3951/:3982 leaves `is_pm_only` referencing an undefined name AND the gate reports clean.

**Mitigating (why MUST not BLOCKER):** the residue would NOT silently ship — a forgotten local-var rename produces a `NameError` when `check_commit_scope_honesty` executes, caught by both `python3 scripts/validate-pack.py` (PREFLIGHT step 1) and the Check-36 test suite (step 2). So the plan has independent backstops; the failure is that the gate is mis-advertised as the authoritative net.

**Exact fix:** widen the gate pattern so the bare local cannot escape — add the underscore form. Replace the gate regex everywhere it appears (§5.1 step-4, §6 verification row, §8.1 read-proof if echoed) with:
```
grep -rnE 'PM-only|pack-memory-only|PM_ONLY|pm-only|is_pm_only' <16 files>
```
i.e. drop the leading-underscore anchor: `is_pm_only` (without the leading `_`) matches BOTH the bare local AND `_is_pm_only_permitted` (since the latter contains `is_pm_only`). This is strictly more inclusive and introduces no new false positives in the 16-file set (verified: the only `is_pm_only`-containing tokens are the local var + `_is_pm_only_permitted`, both Sense-A renames). Update the §6 "exactly 2 allowed exceptions" allowlist text accordingly (the 2 PROFILE_PHRASES are unaffected — they contain `PM-only`, not `is_pm_only`).

---

## GAP-2 (SHOULD) — plan headline counts over-state by 3 (validate-pack.py miscount)

**Evidence (my measurement at HEAD `40867052`):**

Per-file occurrence counts (`grep -oE 'PM-only|pack-memory-only|PM_ONLY|pm-only|_is_pm_only' <file> | wc -l`):
```
12  CLAUDE.md
12  AGENTS.md
11  GEMINI.md
34  scripts/validate-pack.py        <-- PLAN §2A claims 37 ; ARCH §3.1 claims 36
18  scripts/tests/test-validate-pack-checks-36-37-38.sh
 4  pack-ops/PACK-AGENTS.md
 3  pack-ops/PACK-CHAT.md
 6  pack-ops/PACK-MEMORY-RATIONALE.md
 1  pack-ops/.spawn-rule-manifest.txt
 6  .claude/skills/commit-discipline/SKILL.md
 6  .codex/skills/commit-discipline/SKILL.md
 6  .gemini/skills/commit-discipline/SKILL.md
 1  .claude/agents/pack-coder.md
 1  .gemini/agents/pack-coder.md
 1  .codex/agents/pack-coder.toml
---
GRAND TOTAL (grep -rhoE ... | wc -l) = 122    <-- PLAN §2A claims 125
```
Regex-part breakdown for validate-pack.py (verbatim): `PM-only`=20, `pack-memory-only`=4, `PM_ONLY`=7, `pm-only`=1, `_is_pm_only`=2 → **34** non-overlapping matches. The 2 PROFILE_PHRASES (:1608/:1615) are inside that 34, so **Sense-A = 34 − 2 = 32** for that file.

True totals: **122 occurrences / 2 Sense-B LEAVE / 120 Sense-A** — versus the plan's §2A "**125 / 2 / 123**". The entire 3-occurrence delta is the validate-pack.py line (34 vs 37). Every other file matches the plan exactly.

**Why this matters:** the plan is explicitly framed as a re-measured correction to a prior plan that failed on miscounting. Memory `rename-plans-measure-then-bound` exists precisely because hand-counts drift. A 37-vs-34 error in the single most complex file is the same class of slip (milder, because the gate — once GAP-1 is fixed — enforces by real occurrence, not by the table). But the §0 Empirical-Evidence Block asserts CONCLUSION: SUPPORTED on counts that do not match the tree, which is a `architect-planner-empirical-evidence` defect (the verbatim output does not back the stated count).

**Exact fix:** correct §0, §2A, and §8.2 to **122 / 2 / 120** total and **validate-pack.py = 34** (32 Sense-A + 2 Sense-B). The task rows A1–A11 themselves do not change (they enumerate by anchor, and the anchors are real); only the count cells are wrong.

---

## GAP-3 (SHOULD) — §2A trinity row sub-counts are wrong

**Evidence (my measurement at HEAD `40867052`):**
```
$ sed -n '78p' CLAUDE.md | grep -oE 'PM-only|pack-memory-only' | wc -l   -> 4
$ sed -n '80p' AGENTS.md | grep -oE 'PM-only|pack-memory-only' | wc -l   -> 4
$ sed -n '60p' GEMINI.md | grep -oE 'PM-only|pack-memory-only' | wc -l   -> 3
```
CLAUDE.md:78 carries FOUR occurrences: `PM-only` + `pack-memory-only` + `PM-only files and directories` + `ARE PM-only`. The plan §2A says "B1 (row :78 = 3 occ)". AGENTS.md:80 is byte-parallel = 4, plan says 3. GEMINI.md:60 (abbreviated, no "ARE PM-only" clause) = 3, plan says "B3 (row :60 = 2 occ)".

The per-FILE totals (12/12/11) still reconcile because the plan compensates with an over-count in the prose attribution (e.g. it lists `:379×2` and `:405` for CLAUDE that net out). So this is an internal-attribution error, not a coverage gap — every prose line is still assigned. But it is a wrong measurement in a "re-measured" table.

**Exact fix:** §2A "Covered by" cells for CLAUDE/AGENTS/GEMINI: change row sub-counts to `row :78 = 4 occ`, `row :80 = 4 occ`, `row :60 = 3 occ`, and re-balance the prose sub-counts so each file still sums to 12/12/11 against the actual prose lines (CLAUDE prose = 8 occ across :376/:379×2/:385/:404/:405/:421/:444; check the actual per-line counts when re-tabulating).

---

## GAP-4 (NIT) — three documents carry three different validate-pack.py counts

**Evidence:** PLAN §2A = 37; ARCHITECTURE §3.1 EE-block = 36 ("34 Sense-A + 2"); RESEARCH §1 header = "36 occurrences"; my measurement = 34. None of the three upstream docs equals the tree. The architect's "34 Sense-A + 2 Sense-B = 36" is internally the closest (its 34-Sense-A figure happens to equal my TOTAL of 34, by coincidence of two offsetting errors). This is cosmetic provenance drift, not a coverage risk.

**Exact fix (optional, NIT):** when correcting GAP-2, add a one-line note in §0 reconciling to the tree value 34 and flagging that ARCH/RESEARCH carry stale 36 (no re-spawn needed; the gate governs).

---

## What I VERIFIED SOUND (earned, by re-measurement)

- **In-scope file set is COMPLETE (no missing Sense-A surface).** Repo-wide grep for the token family (excluding `.git/`) returns, outside `maintenance-docs/` + `pack-ops/BACKLOG.md`/`CHANGELOG.md`, EXACTLY: the 16 in-scope files + the 7 Sense-B project-side files (`project-template/.{claude,codex,gemini}/agents/{coder,repo-ops}.{md,toml}` + `project-template/docs/pack/PM-CHAT.md`). No Sense-A occurrence lives outside the 16-file set. (`maintenance-docs/` = historical design/review docs incl. this BD's own ARCH/RESEARCH; `BACKLOG.md`/`CHANGELOG.md` = Pack-Chat-direct bookkeeping per §8 — all legitimately out of scope.)
- **Near-variant sweep is clean.** `PM only` (space), `Pack Memory`, `pack memory`, case variants: every hit outside the token family is a legitimate `## Pack memory` section reference (e.g. `.{claude,codex,gemini}/skills/review/SKILL.md`, `validate-pack.py:65/1144/...`, `PACK-CHAT.md:182`) — NOT the keyword. No hidden Sense-A surface.
- **Sense-B classification is correct line-by-line.** The 7 project-side `No PM-only file edits` occurrences are Sense B (client deliverable, `coder`/`repo-ops` stems validated by `WRITE_SCOPED_AGENTS={"coder"}` / `WRITE_SCRIPT_AGENTS={"repo-ops"}` at vp:1581/1582). The 2 PROFILE_PHRASES vp:1608/:1615 are the only Sense-B occurrences inside the 16-file set, correctly the gate's allowlist. The pack-coder ×3 lines (`No PM-only file edits without explicit caller instruction`) are Sense A (stem `pack-coder` ∉ the profile sets), correctly renamed by Group H. The PACK-CHAT archetype lines (:21/:23 "PM chat") and PACK-AGENTS :169 "PM Chat" are SPACE-form, not token-family — gate will not false-flag them; D-LEAVE/C6 dispositions are correct.
- **The prior under-enumeration IS fixed.** Test file = 18 occurrences across lines `:50,:94,:95,:96,:100,:104,:105,:107,:115,:125,:127,:128,:132,:136,:140` — EXACTLY the plan's I-CATCH-ALL list. The four lines the prior plan missed (`:104/:105/:115/:140`) are covered by I13. The multi-line `§ "PM-only files and directories"` comment is REAL (token at `:128` "PM-only files and", wrapping to `:129` "directories") and is covered by I13 in lockstep with the C1 heading rename — the prior false "does NOT exist" note is corrected. No self-contradiction remains: the §6 gate is the contract, the anchor list a convenience (consistent framing).
- **A13 fold is correct on all 3 lockstep surfaces.** Current state verified: vp:3741-3744 comment "BD-203 A13 ... removed here" + set EXCLUDES BACKLOG/CHANGELOG; PACK-AGENTS Files list INCLUDES them; test:119-120 assert `False`. The 3 surfaces disagree today (the A13 inconsistency). Plan A2/C2/I10-I12 make all three INCLUDE (validator add + doc keep + test flip to True) — restore is correct for the on-disk reality, and the §3 single-commit rationale (validator↔test encoding pair) is sound (an intermediate split would leave a validator-vs-test disagreement).
- **Token-trap subject is safe.** Proposed subject `feat: v11 — BD-209 rename the overloaded commit-scope governance keyword + A13 fold (pack-only)` carries exactly one keyword token (`pack-only`) and no literal `pack-chat-only`/`pm-only`/`pack-memory-only`/second-`project-only` — Check-36-clean once `pack-chat-only` goes live. Honest claim: the whole diff is pack-side (`scripts/`, `pack-ops/`, repo-root trinity + dotted dirs, `test-fixtures/manifest.txt`); no `project-template/` path touched (Sense-B DENY honored). Matches memory `commit-subject-keyword-token-trap` (the BD-198 failure class).
- **Baseline green.** `python3 scripts/validate-pack.py` exits 0 ("PASSED — all checks clean") at HEAD `40867052`, so the projected post-rename verification has a clean baseline.

---

## Empirical-Evidence Block — my independent re-measurement

```
CLAIM: true token-family totals across the 16 in-scope files = 122 occ / 2 Sense-B / 120 Sense-A;
       validate-pack.py = 34 (not 37/36); trinity rows = 4/4/3 (not 3/3/2);
       gate pattern misses bare `is_pm_only` at :3951/:3982; in-scope file set is complete.
COMMAND: grep -oE per file; grep -rhoE across 16; grep -nE 'is_pm_only' validate-pack.py;
         echo "if is_pm_only:" | grep -oE '<gate pattern>'; repo-wide grep -rlE token-family;
         near-variant grep; sed -n '78p/80p/60p' | grep -oE; python3 scripts/validate-pack.py
OUTPUT (verbatim, abridged):
  per-file: 12 12 11 34 18 4 3 6 1 6 6 6 1 1 1 ; grand total = 122
  validate-pack.py parts: PM-only=20 pack-memory-only=4 PM_ONLY=7 pm-only=1 _is_pm_only=2 -> 34
  "if is_pm_only:" vs gate -> NO MATCH (gate misses bare local)
  trinity rows: CLAUDE:78=4 AGENTS:80=4 GEMINI:60=3
  test file lines: 50,94,95,96,100,104,105,107,115,125,127,128,132,136,140 (=18 occ) == plan I-CATCH-ALL
  repo-wide token-family files outside maintenance-docs/+BACKLOG/CHANGELOG = the 16 in-scope + 7 Sense-B project-template = no extras
  validate-pack.py exit=0 "PASSED — all checks clean"
HEAD-SHA: 40867052b31e822e1742de4806016bdca1131f6e   DATE: 2026-06-05
INTERPRETATION: file set + Sense-A/B classification + A13 fold + token-trap subject are SOUND;
  counts (125/37, rows 3/3/2) are over-stated; the gate pattern has one blind spot (bare is_pm_only).
CONCLUSION: NOT-SOUND on counts + gate pattern (GAP-1 MUST, GAP-2/3 SHOULD, GAP-4 NIT);
  SOUND on completeness of file set, classification, A13, and commit shape.
```

---

## Rules-Applied Verification Block

### Per-file READ-IN-FULL proof (direct Read/Bash, this session)

| Named doc | Direct-read proof (own tool call: line count or offset + first/last/unique-mid) | Conclusion |
|---|---|---|
| `PLAN-BD-209.md` (IN FULL) | Read tool, 349 lines (offset 1, full). `:1` "# PLAN — BD-209: rename the Check-36 commit-scope keyword..."; mid `:190` "**TOTAL** | **125** | **2** | **123** |"; last `:349` "*End PLAN-BD-209.md*". | COMPLIANT |
| `ARCHITECTURE-BD-209.md` (IN FULL) | Read tool, 501 lines (offset 1, full). `:1` "# ARCHITECTURE — BD-209..."; mid `:251` `_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)`; last `:501` "*End ARCHITECTURE-BD-209.md*". | COMPLIANT |
| `RESEARCH-BD-209-BLAST-RADIUS.md` | Bash grep -nE across the file: `:11` "Reconciled raw total: 1248 `PM-only` lines across 227 files"; `:32` "Check 36 machinery ... Sense A core; 36 occurrences"; `:71` "`is_pm_only` ... VAR-RENAME (local ref)". Direct line reads, not derived. | COMPLIANT |
| BD-209 entry (`pack-ops/BACKLOG.md`) | Bash sed range read. `:3419` "**BD-209 — Rename the `PM-only` commit-scope keyword → `pack-chat-only`...**"; `:3429` "FOLD the BD-203 A13 sequencing fix..."; "Position: pack-self governance; rename-first, between BD-203 Commit 1 and Commit 2." | COMPLIANT |
| `scripts/validate-pack.py` Check 36 + PROFILE_PHRASES | Bash grep -nE token-family: `:1608/:1615` `"No PM-only file edits"` (PROFILE_PHRASES); `:3732` `_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")`; `:3950/:3951/:3982/:3983` `is_pm_only` driver; `:1581` `WRITE_SCOPED_AGENTS = {"coder"}`; `:1582` `WRITE_SCRIPT_AGENTS = {"repo-ops"}`. | COMPLIANT |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | Read tool offset 44 limit 110 + Bash grep -nE returning all 18 occ. `:50` `'_is_pm_only_permitted',`; `:95-96` T3a/T3b; `:107` helper `mod._is_pm_only_permitted`; `:119-120` T6d/T6e=False; `:128` multi-line `§ "PM-only files and"` wrapping to `:129` `directories"`. | COMPLIANT |
| `CLAUDE.md ## Pack memory` IN FULL | Supplied in full in this session's system context (project instructions); the `## Pack memory` block (Workflow / Agent-invocation / Sub-agent / Pack-Chat-scope / Repo-conventions / Project-goals) read in full; trinity table row at CLAUDE.md:78 separately read via Bash `sed -n '78p'`. Read SEPARATELY from each memory file below. | COMPLIANT |
| `feedback_rename_plans_measure_then_bound.md` | Read tool, 44 lines (full). `name: rename-plans-measure-then-bound-not-anchor-enumeration`; `:25-29` "missed `PM-only` comments at :104/:105/:115/:140 ... single-line grep missed a MULTI-LINE comment"; last `:43` "...feeds the gate's in-scope file set + allowlist)." | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read tool, 14 lines (full). `name: ci-guard-design-measure-then-bound`; `:10` "measure the repo first, categorize every occurrence KEEP...or STRIP...size the allowlist exactly to KEEP"; last `:14` "Related: [[architect-planner-empirical-evidence]], [[triage-workflow-protocol]]." | COMPLIANT |
| `feedback_researcher_maps_blast_radius_before_architect.md` | Read tool, 41 lines (full). `name: researcher-maps-blast-radius-before-architect`; `:26` "claimed 185 vs the true 189 — it missed the `BD-NNNb` sub-entries"; last `:40` "...[[adversarial-architect-review-on-major-gap]]." | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read tool, 33 lines (full). `name: pack-project-separation-of-concerns`; `:15` "Cross-side substitution is FORBIDDEN."; last `:32` "Cross-refs: [[bd-pack-only-operational-rule]]...[[pack-entry-type-data-structure-semantics]]..." | COMPLIANT |
| `feedback_commit_subject_keyword_token_trap.md` | Read tool, 38 lines (full). `name: commit-subject-keyword-token-trap`; `:19` "Check 36 latched onto `PM-only`, which denies `scripts/` paths"; last `:38` "...[[feedback_no_prestaging_until_commit_approval]]." | COMPLIANT |
| `feedback_preliminary_triage_architect_challenge.md` | Read tool, 46 lines (full). `name: preliminary-triage-architect-challenge-discipline`; `:14` "No decision is locked just because it was triaged."; last `:45` "Cross-refs: [[feedback-user-prescriptive-authority]]...[[pack-chat-boundaries]]." | COMPLIANT |
| `feedback_architect_planner_empirical_evidence.md` | Read tool, 14 lines (full). `name: architect-planner-empirical-evidence`; `:10` "command + verbatim output + HEAD SHA + date + interpretation + SUPPORTED / NOT-SUPPORTED / PARTIAL"; last `:14` "Related: [[agent-output-rules-applied-block]], [[ci-guard-design-measure-then-bound]]." | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Read tool, 14 lines (full). `name: agent-output-rules-applied-block`; `:10` "per rule: name + quoted evidence + COMPLIANT / N/A:‹reason› / VIOLATED:‹reason›; empty = VIOLATED"; last `:14` "Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]]." | COMPLIANT |
| `feedback_agents_read_rule_docs_in_full.md` | Read tool, 117 lines (full). `name: agents-read-rule-docs-in-full`; `:98` "No-cache-substitution clause"; last `:117` "...accepting a derived-not-read attestation erodes the very standard that catches the dangerous cases." | COMPLIANT |
| `feedback_scope_deliverables_to_the_ask.md` | Read tool, 34 lines (full). `name: scope-deliverables-to-the-ask-no-noise`; `:25` "...this is a disaster and why we're in this mess."; last `:34` "...the user's standing preference for terse, exactly-scoped work." | COMPLIANT |

### Per-rule compliance

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION | Per-file table above: PLAN/ARCH read in full via Read tool; RESEARCH/BACKLOG/validate-pack read via direct Bash grep/sed line reads; all 11 named memory files Read DIRECTLY with per-file line count + first/last/unique-mid proof; `CLAUDE.md ## Pack memory` read in full SEPARATELY (system context) from the memory files; nothing derived from cache. | COMPLIANT |
| empirical-evidence-blocks | The Empirical-Evidence Block above carries command + verbatim output + HEAD-SHA `40867052` + date 2026-06-05 + interpretation + CONCLUSION; every count finding (122/120, vp=34, rows 4/4/3, gate-miss) is my own command output, not the plan's claim. | COMPLIANT |
| ci-guard-design-measure-then-bound | Independently MEASURED the tree (per-file + grand total + regex-part breakdown); categorized every occurrence Sense-A RENAME vs Sense-B LEAVE; verified the gate's allowlist is sized exactly to the 2 PROFILE_PHRASES; tested the gate pattern against each token form and found the `is_pm_only` blind spot (GAP-1). | COMPLIANT |
| researcher-maps-blast-radius-before-architect | Re-ran the exhaustive repo-wide blast radius myself (token family + near-variants); reconciled the in-scope file set against the full file list; confirmed no Sense-A surface outside the 16; this is the adversarial re-measurement the rule demands. | COMPLIANT |
| pack-project-separation-of-concerns | Verified Sense B (project-template client deliverable + PROFILE_PHRASES) is NOT renamed and the keyword is pack-self only; the plan's DENY-list + the 7 untouched project-side occurrences honor the boundary. | COMPLIANT |
| commit-subject-keyword-token-trap | Verified §4 landing subject carries only `pack-only` and no `pack-chat-only`/`pm-only`/`pack-memory-only` literal; matches the BD-198 lesson. SOUND. | COMPLIANT |
| preliminary-triage-architect-challenge | Adversarial mandate honored: assumed gaps, re-measured every load-bearing count independently rather than trusting the plan; surfaced 1 MUST + 2 SHOULD + 1 NIT; SOUND items earned by matching measurement. | COMPLIANT |
| architect-planner-empirical-evidence | Flagged the plan's §0 EE-block CONCLUSION: SUPPORTED resting on counts (125/37) that do not match the tree (122/34) as a defect (GAP-2). | COMPLIANT |
| scope-deliverables-to-the-ask | Led with the verdict; delivered the adversarial review (verdict + numbered GAPs with file:line evidence + severity + exact fix + earned SOUND list); no padding. | COMPLIANT |
| agent-output-rules-applied-block | This block: per-file READ-IN-FULL proof + per-rule table; no empty rows; no VIOLATED rows. | COMPLIANT |

**No VIOLATED rows. No empty evidence.**

---

*End PLAN-BD-209-ADVERSARIAL-REVIEW.md*
