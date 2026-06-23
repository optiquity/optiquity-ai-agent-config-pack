# PLAN (V2) — BD-243 BLOAT PHASE (folds the approved architect method + the accumulated cleanup items)

Planner: FRESH planner instance (pack-planner, RO). I did NOT author `PLAN-BD-243-BLOAT-PHASE.md` (the prior bloat plan) nor any DESIGN/CENSUS; conclusions are my own (reconciliation-instance-independence).
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`103cca8`** (verified at runtime: `git rev-parse HEAD` = `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: PLANNER-READY — goes to the user at the planner-to-coder gate (planner-output-user-review); NOT auto-approved into a coder spawn.

This V2 plan SUPERSEDES `PLAN-BD-243-BLOAT-PHASE.md` for the bloat phase. It folds in: (1) the now-approved `DESIGN-BD-243-BLOAT-METHOD.md` (the §A S-test + A.2 invariant set + A.5 verification contract for skills; §B human-readable reduction + ceiling re-derivation for OPTIONAL-FEATURES; §C plan impact); (2) the user's two binding rulings (skills = text-amount-only / zero-meaning-change; OPTIONAL-FEATURES = human-readable, structures/code/JSON untouched); and (3) the accumulated cleanup items surfaced during the strip waves (FLAG-2a, history-NARRATIVE prose, and the CG-14-prep gate-completeness items). The STRIP phase (CG-01..CG-13) is DONE, committed, pushed, CI-green at `103cca8`; this plan does NOT re-plan or re-run it (scope-deliverables-to-the-ask).

---

## 0. EXECUTIVE ANSWER (decision-ready)

- **Commit count:** **9 bloat commits CB-01..CB-09** (CB-09 splittable to CB-09a/CB-09b on reviewer-size demand). The architect's "all-skills text-amount-only" ruling does NOT change the count or the partition (DESIGN-METHOD §C.2.1). Confirmed at `103cca8`.
- **Method per surface:** OPTIONAL-FEATURES → §B human-readable reduction + the ceiling reduce-then-re-derive recipe (CB-01); skills (pack + project) → the §A S-test (S1/S2/S3 KEEP, else REMOVE) + A.2 invariant-set-never-touched + the A.5 verification contract (CB-04 pack skills, CB-05 pack agents, CB-09/CB-09b project skills); all other operating docs → the four bloat types B1-B4 + C.2 clause-preserving conversion + C.3 reviewer clause-set-diff.
- **Accumulated cleanup, sequenced:** **FLAG-2a** → folded into CB-01 (it lives in `pack-ops/OPTIONAL-FEATURES.md`, which CB-01 already touches). **History-NARRATIVE prose** (no Check-65 regex token) → folded into the bloat commit that touches each carrier file (BOUNDARY-DEFINITION → CB-01; CONCEPTUAL-REVIEW → CB-01). **Gate-completeness items** (the `incident`-regex tightening + the K7-extension allowlist record + the FLAG-2a confirmation) → the **CG-14-prep** step, NOT the bloat commits. Division: bloat passes handle history-NARRATIVE prose; CG-14-prep handles the gate allowlist + the regex tightening.
- **Phase position:** all CB-01..CB-09 land first (gate inert) → then **CG-14-prep** (two-axis sweep + gate-completeness fixes) → then **CG-14 activation** (populate `_CHECK_65_OPERATING_DOCS`, gate enforces) → then **push**.

---

## 1. STATE BASELINE (measured @ `103cca8`)

The full strip phase has landed; the anti-bloat gate (Check 65) is registered but INERT:

- The strip waves CG-01..CG-13 are committed + pushed + CI-green (`git log` shows CG-13 `be94aa8`, then `2780ada` manifest regen, then `103cca8` the CG-01 retroactive test-count fix at HEAD).
- `CHECK_REGISTRY_EXPECTED_COUNT = 63` (validate-pack.py:496); `_CHECK_65_OPERATING_DOCS = ()` (validate-pack.py:7926) — Check 65 enforces NOTHING against the live tree yet. CG-14 is the sole activation point.
- `pack-ops/.operating-doc-history-allowlist.txt` — 37 KEEP records (K1-K13), content-anchored by `snippet:` substring.
- `scripts/tests/test-validate-pack-check-65.sh` exists (the per-check test the gate's Check-43 wiring requires).
- Full `validate-pack.py` is GREEN at `103cca8` (verified: `PASSED — all checks clean`).

**EE-BASE — state baseline @ `103cca8`.**
- Cmd: `git rev-parse HEAD; git log --oneline -8; grep -n 'CHECK_REGISTRY_EXPECTED_COUNT = ' scripts/validate-pack.py; grep -n '_CHECK_65_OPERATING_DOCS = (' scripts/validate-pack.py; python3 scripts/validate-pack.py | tail -2`
- Output (verbatim, key): `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`; `103cca8 fix: v11 — BD-243 retroactive per-BD review-fix (CG-01) … (pack-only)`, `be94aa8 … (CG-13)`, `7f2e952 … (CG-12)`, `1ba8496 … (CG-09)`, `f6c8ffd … (CG-08)`, `697e955 … (CG-06)`; `496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; `7926:_CHECK_65_OPERATING_DOCS = ()`; `PASSED — all checks clean`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: strip phase complete; gate inert; tree green; EXPECTED_COUNT 63.
- Conclusion: **SUPPORTED.**

---

## 2. THE BLOAT UNIVERSE (re-measured @ `103cca8`)

The bloat axis applies to the WHOLE operating-doc IN set (DESIGN-FINAL §C; DESIGN-METHOD §A — ALL skills in scope, text-amount-only). Four bloat types (DESIGN-FINAL §C.1): **B1** mega-bullet run-on (one bullet = N clauses); **B2** prose-that-should-be-a-table; **B3** verbosity/hedging/restatement padding; **B4** cross-file duplication (trinity/tri-family parity — NOT dedup-able; reshape multiplies ×3, parity-locked).

Only ONE doc carries a measured Check-44 advisory ceiling it EXCEEDS: `pack-ops/OPTIONAL-FEATURES.md` (544 vs 271). All other Check-44 durable docs are UNDER ceiling post-strip (BOUNDARY 135/156, CONCEPTUAL 289/343, DRY-RUN 198/229, HELP-PACK n/a, MERGE 486/557) — for those the bloat axis is "reduce where it improves the doc," not "hit a ceiling." Docs with NO ceiling (trinity, RATIONALE, PACK-CHAT, project docs, skills, agents) carry absolute bloat ranked by line count + B1 density.

### 2.1 High-bloat doc table (named targets, @ `103cca8`)

| File | Lines @ `103cca8` | Advisory ceiling | Dominant bloat type | Method | Surface | Client-facing? |
|---|---|---|---|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | 1109 | — | B2 + B3 | B-types | project | YES |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | 784 | — | B1 (per-`## slug` Why) + B3 | B-types | pack | no |
| `CLAUDE.md` (pack-root) | 773 | — | **B1 (graph-first 5024c; 5 rules >1200c)** | B-types + C.2 | pack | no |
| `AGENTS.md` (pack-root) | 650 | — | B1 | B-types + C.2 | pack | no |
| `GEMINI.md` (pack-root) | 638 | — | B1 | B-types + C.2 | pack | no |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | 616 | — | B2 + B3 | B-types | project | YES |
| `pack-ops/OPTIONAL-FEATURES.md` | **544** | **271** (EXCEEDED) | B3 (worktree + graphify prose) | **§B human-readable + ceiling re-derive** | pack | no |
| `project-template/GEMINI.md` | 526 | — | B1 + B4 | B-types | project | YES |
| `pack-ops/PACK-CHAT.md` | 495 | — | B1 + B3 | B-types | pack | no |
| `project-template/CLAUDE.md` | 490 | — | B1 + B4 | B-types | project | YES |
| `pack-ops/MERGE-STRATEGY.md` | 486 | 557 (under) | B2 + B3 | B-types | pack | no |
| `project-template/AGENTS.md` | 466 | — | B1 + B4 | B-types | project | YES |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | 425 | — | B3 | B-types (NOT §B — no ceiling, project copy) | project | YES |
| `project-template/docs/pack/PACK-FEEDBACK.md` | 452 | — | B3 | B-types | project | YES |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | 289 | 343 (under) | B3 | B-types + history-NARRATIVE fold | pack | no |
| `pack-ops/PACK-AGENTS.md` | 282 | — | B2 + B3 | B-types | pack | no |
| `pack-ops/DRY-RUN-MIGRATION.md` | 198 | 229 (under) | B3 | B-types | pack | no |
| `pack-ops/BOUNDARY-DEFINITION.md` | 135 | 156 (under) | B3 | B-types + history-NARRATIVE fold | pack | no |

### 2.2 Class bloat (per-class waves)

- **Pack skills (11)** `.claude/skills/*/SKILL.md` (1218 total): top — commit-discipline 275, verification-harness 241, boundary-investigation 185, implementation-report 154, pack-startup 106. **Method: §A S-test** (Check 1 frontmatter NEVER stripped; A.2 invariant set never touched).
- **Pack agents (5)** `.claude/agents/pack-*.md` (484 total): pack-coder 204 is the only large one; architect 63, planner 74, reviewer 72, docs-researcher 71. **Method: §A S-test** (Check 11 informational; the trinity-rule symmetry statement is an invariant).
- **Project agent-defs (16 roles ×3 families = 48 + RUNTIME-SUBAGENT-PATTERN.md 77)** `.claude/agents/*.md` (1818), `.agents-plugin/optiquity-agents/agents/*.md` (1613), `.codex/agents/*.toml` (884): B4 tri-family duplication; per-role reshape multiplies ×3, parity-locked.
- **Project skills (37)** `project-template/skills/*/SKILL.md` (3614 total): largest python-observability-patterns 527, swift-concurrency-patterns 418, apple-swiftdata-patterns 271, protobuf-patterns 249, pm-startup 206, boundary-investigation 194, audit-methodology 159, api-design 50. **Method: §A S-test** — the architect's ruling RESOLVES the prior plan's "aggressive terseness risks substance" §8 flag: these technical skills are IN, but text-amount-only; expect MODEST reduction (most lines are S1/S2/S3-passing content).
- **Project prompts (10)** `docs/pack/prompts/*.md` (1313 total): B3.
- **Project stream-meta (4)** `docs/project/{backlog,changelog,implementation-plan}/_rules.md` + `changelog/_format.md` (214 total, 47-69 each): minor B3 only. K9/K10 date examples allowlisted — do NOT touch those lines.

**EE-2A — bloat universe line counts @ `103cca8`.**
- Cmd: `wc -l` over the named IN docs + class totals.
- Output (verbatim, top): pack — `PM-CHAT 1109`, `RATIONALE 784`, `CLAUDE 773`, `AGENTS 650`, `GEMINI 638`, `OPTIONAL 544`, `PACK-CHAT 495`, `MERGE 486`; project — `PM-CHAT 1109`, `PLATFORM-SKILLS 616`, `GEMINI 526`, `CLAUDE 490`, `AGENTS 466`, `OPTIONAL 425`, `PACK-FEEDBACK 452`; classes — pack skills `1218`, pack agents `484`, project skills `3614`, .claude agents `1818`, .agents-plugin `1613`, .codex `884`, project prompts `1313`, project stream-meta `214`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: bloat concentrated in pack-root trinity + RATIONALE + OPTIONAL-FEATURES (pack) and PM-CHAT + PLATFORM-SKILLS + project trinity (project); agent-def + project-skill classes carry distributed bloat. Counts are within a few lines of the prior plan's `4de8d50` sizing (the deferred-mention strips were small), confirming the bloat that REMAINS.
- Conclusion: **SUPPORTED.**

**EE-2B — only OPTIONAL-FEATURES exceeds its Check-44 advisory ceiling @ `103cca8`.**
- Cmd: `python3 scripts/validate-pack.py --only-check 44 2>&1 | grep -iE "ADVISORY|PASS"`.
- Output (verbatim): `OK: pack-ops/OPTIONAL-FEATURES.md — ADVISORY: 544 lines exceeds the per-doc advisory ceiling 271 (derived from measured cleaned content). Advisory only — not a failure …`; `PASSED — all checks clean`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: among the 6 Check-44 durable docs, only OPTIONAL-FEATURES is over its ceiling post-strip — the one HARD bloat target with a numeric goal; the rest get reduce-where-it-helps only.
- Conclusion: **SUPPORTED.**

**EE-2C — pack CLAUDE.md B1 mega-bullet offenders (chars per top-level memory bullet) @ `103cca8`.**
- Cmd: `awk` accumulating each `- **` memory bullet + its continuation lines, `sort -rn`.
- Output (verbatim, top): `5024 - **Graph-first context when the knowledge graph exists`; `2799 - **Sub-agent isolation is keyed by agent class`; `2394 - **Pack Chat does MINOR edits only`; `1379 - **Reconciliation-instance independence`; `1287 - **Agents never commit`; `1203 - **Record every spawn in the durable registry`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: `graph-first-context` is the single biggest B1 mega-bullet (5024c; was 5111c at `4de8d50`, 5274c pre-strip — the strip waves trimmed it). Five rules exceed 1200c. These are the C.2 "rule >~800 chars" structural-conversion targets for CB-06.
- Conclusion: **SUPPORTED.**

**EE-2D — OPTIONAL-FEATURES structure (the §B human-readable floor inputs) @ `103cca8`.**
- Cmd: python line-classifier over `pack-ops/OPTIONAL-FEATURES.md`.
- Output (verbatim): `total=544 blank=73 fence_markers=10 fenced_content=35 headers=11`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: ~45 protected lines (35 fenced content + 10 fence markers) + 11 headers + 73 blanks = ~129 structural/protected; ~415 prose+settings lines are the reduction surface, of which the settings-spec lines (Check-54 trio + enums/defaults) are additionally protected. NB: at `103cca8` the doc shows 10 fence markers / 35 fenced content (vs the architect's `2780ada` measurement of 8 markers / 30 content) — the strip waves left the doc slightly restructured; the coder re-measures at its worktree HEAD (the floor is computed against the actual reduced text, never a stale number). This is exactly why §B.3 re-derives FROM the measured reduced content.
- Conclusion: **SUPPORTED.**


---

## 3. THE METHOD (folded from DESIGN-BD-243-BLOAT-METHOD.md — apply per surface)

Three methods, applied by surface class. The coder selects the method by which CB commit / which file (the per-commit table §4 names it).

### 3.1 Skills + agent-defs → the §A examples S-test + A.2 invariant set + A.5 verification (DESIGN-METHOD §A)

Binding user ruling (verbatim-in-spirit): **TEXT-AMOUNT-ONLY reduction; ZERO meaning/functionality change. Guardrails, rules, in/out-of-scope concepts INVARIANT. Examples kept only if they add irreplaceable specificity.**

**The S-test (per example/pattern/snippet — KEEP if ANY sub-test is YES):**
- **(S1) Concrete shape** — the example shows a literal shape a reader would otherwise guess: an exact API call, config-key path, code construct, filename grammar, message format, settings snippet (e.g. `@Attribute(.externalStorage)`, `worktree.baseRef: "head"`, `2026-04-20-phase-35.md`). KEEP.
- **(S2) Edge case / disambiguation** — the example pins a case the reader would get WRONG: a counter-example, a "this NOT that" contrast, a boundary the prose states abstractly (e.g. "`isolation` has only `"worktree"`; `head`/`none` are SETTINGS values"). KEEP.
- **(S3) Irreducible enumeration** — the example is one item in a set the rule MUST enumerate to be correct (the deletion rules `.nullify`/`.cascade`/`.deny`/`.noAction`; the denied git-verb list). KEEP.
- **REMOVE only if ALL three are NO** — pure redundant illustration that restates what adjacent prose already says, adding no shape/edge/enumeration. That is text-amount bloat → REMOVE.

**The A.2 INVARIANT set — NEVER touched (the meaning-invariant):** guardrails (what the skill protects against/prohibits); rules/directives (the numbered/bulleted instructions); triggers (the load predicate / "when this applies"); exceptions/carve-outs (every "except"/"unless"/"only when"); in-scope / out-of-scope concepts (boundary statements — an "out of scope for this skill" statement is an OPERATIVE GUARDRAIL → KEEP, per CENSUS §5 user ruling); frontmatter (Check 1). Only REDUCIBLE: redundant prose, hedging, restated imperatives, padding, redundant examples (the REMOVE-class above).

**B-type license on skills (tightened by the ruling):** B1/B2 = pure RESHAPE (every clause survives as a row, the C.2 method); B3 = the primary text-amount lever (delete padding; directive + trigger survive verbatim-equivalent); B4 = parity-locked ×3, reshape not dedup. The phrase "aggressive terseness" from DESIGN-FINAL §C.4 is SUPERSEDED for skills — there is NO deletion of substantive content; expect MODEST reduction on technical skills (most lines are S-test-passing).

**The A.5 verification contract (the reviewer's per-skill proof, EXTENDS C.3):** for every skill a bloat commit touches —
1. **Invariant-set diff** — enumerate the A.2 invariant set from `git show HEAD:<skill>` (the strip-clean baseline) and from the post-bloat file; the two sets MUST be EQUAL. A non-empty asymmetric diff = a meaning-loss BLOCKER.
2. **Example-removal justification log** — the IMPL-REPORT records, for every example REMOVED, the S-test verdict ("removed — failed S1/S2/S3; pure restatement of `<the prose it duplicated>`"). An example removed WITHOUT a log entry is a BLOCKER.
3. **Example-retention spot-check** — sample KEPT examples; each must pass ≥1 S-test.
4. **Frontmatter intact (Check 1)** + **no net new directive/clause** (diff is removals + reshapes only).

### 3.2 OPTIONAL-FEATURES → the §B human-readable reduction (DESIGN-METHOD §B) — CB-01 ONLY

Binding user ruling (verbatim-in-spirit): **human-readable reference doc; reduce text without losing clarity/meaning; NEVER modify structures/code/JSON/examples; apply the rule human-readably.**

**Process-doc finding (DESIGN-METHOD §B.1):** OPTIONAL-FEATURES is NOT executed as a process doc (no script/agent reads its PROSE as instruction). It IS treated as a content-presence target by two CI guards — Check 54 (asserts the literal tokens `baseRef`, `bgIsolation`, `permissions.deny` present in BOTH surfaces; FAILS the build if missing) and Check 44 (advisory length). These are content-presence GUARDRAILS the reduction must respect, not execution semantics.

**REDUCIBLE (prose only):** restatement padding (the worktree section's consecutive paragraphs each re-explaining the class-keyed default → collapse to one statement + the consequence); hedging/persuasive padding ("it is worth noting that," doubled parentheticals, post-hoc WHY-arguments); B2 prose→table where it improves human readability AND never reshapes a protected block.

**PROTECTED (NEVER modified — the ruling's explicit list):** all fenced code/JSON/text/bash blocks (measured @ `103cca8`: 10 fence markers, 35 fenced content lines — UNTOUCHED, byte-identical); inline settings specifications (the literal setting names / enum value sets / defaults stated in prose: `worktree.baseRef: "head"`, `["head","fresh"]`, `worktree.bgIsolation`, `permissions.deny`, `isolation:"worktree"`) — these ARE both the "settings examples" the ruling protects AND the Check-54 tokens; structure (section headers, the §1.1 backend caveat "do NOT 'correct' it", the privacy/secrets subsection facts, any worked-example shape).

### 3.3 All other operating docs → B1-B4 + C.2 clause-preserving + C.3 clause-set-diff (DESIGN-FINAL §C)

**C.2 clause-preserving conversion (mandatory for any rule >~800 chars):** (1) clause-enumerate first (list every directive/trigger/exception/cross-CLI note/Trinity-exemption note — this is the meaning-invariant); (2) convert prose→structured one-clause-per-row; (3) re-enumerate (post == pre — a dropped clause = behavior change = FAIL); (4) trim B3 padding within a clause only; (5) trinity/tri-family lock in the same commit.
**C.3 reviewer clause-set-diff:** for every swept rule, a before/after clause-set diff (`git show HEAD:<file>` vs post-edit) asserting set-equality modulo flagged B3 padding; a non-empty asymmetric diff that is NOT flagged padding = a meaning-loss BLOCKER.

---

## 4. THE 9-COMMIT BLOAT-PHASE STRUCTURE (confirmed; partition + cleanup folds)

A bloat commit collects reviewed-clean work-unit patches and applies them as ONE grouped commit, GREEN at apply (full `validate-pack.py` exit 0; Check 65 still vacuous until CG-14). Grouping mirrors the strip-phase surface partition so the no-double-BLOAT-touch invariant holds (each file = at most one bloat commit). The architect confirmed the all-skills ruling does NOT change the count or partition (DESIGN-METHOD §C.2.1).

| Commit | Content (bloat axis + folded cleanup) | Files | Method | Scope keyword | Sequencing / lock |
|---|---|---|---|---|---|
| **CB-01** | Pack-ops operating-doc bloat **+ FLAG-2a strip + 2 history-NARRATIVE strips + OPTIONAL ceiling re-derive** | `pack-ops/OPTIONAL-FEATURES.md` (hard: 544→floor; §3.2 + FLAG-2a + ceiling recipe §5), `MERGE-STRATEGY.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md` (+ Empirical-validation history-NARRATIVE para), `PACK-CHAT.md`, `PACK-AGENTS.md`, `DRY-RUN-MIGRATION.md`, `BOUNDARY-DEFINITION.md` (+ AUDIT-USER-CURATION history-NARRATIVE clause) | §3.2 (OPTIONAL) + §3.3 (rest) | `pack-only` | parallel across distinct files |
| **CB-02** | Pack RATIONALE bloat (surgical) | `pack-ops/PACK-MEMORY-RATIONALE.md` | §3.3 (B1 per-`## slug` Why + B3) | `pack-only` | own commit (784 ln, heaviest; K2-K5/K13 snippet-stable) |
| **CB-03** | Pack stream-meta bloat | `backlog/_rules.md`, `changelog/_rules.md` | §3.3 (B3) | `pack-only` | parallel; K7 snippet-stable (backlog/_rules) |
| **CB-04** | Pack skills bloat | `.claude/skills/*/SKILL.md` (11) | **§3.1 S-test** | `pack-only` | parallel across distinct files; Check 1 frontmatter intact; A.5 contract |
| **CB-05** | Pack agent-defs bloat | `.claude/agents/pack-*.md` (5) | **§3.1 S-test** | `pack-only` | parallel; Check 11 informational; A.5 contract |
| **CB-06** | Pack-root trinity bloat | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack root) | §3.3 (C.2 mega-rule) | `pack-only` | trinity-locked ×3 ONE commit; K1/K2/K3/K12 snippet-stable; sanctioned Claude-only asymmetry (the `### Sub-agent behavior (Claude-only)` block + Trinity-exempt notes) |
| **CB-07** | Project trinity bloat | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | §3.3 (C.2 mega-rule) | `project-only` | trinity-locked ×3 ONE commit; ∥ CB-06; K12 snippet-stable |
| **CB-08** | Project docs/pack + prompts + stream-meta bloat | `docs/pack/PM-CHAT.md`, `PLATFORM-SKILLS.md`, `OPTIONAL-FEATURES.md`, `PACK-FEEDBACK.md`; `docs/pack/prompts/*.md` (10); `docs/project/{backlog,changelog,implementation-plan}/_rules.md` + `changelog/_format.md` | §3.3 (B-types); project OPTIONAL is NOT §3.2 (no ceiling, project copy) | `project-only` | parallel across distinct files; K11 snippet-stable (PACK-FEEDBACK); K9/K10 date lines NOT touched |
| **CB-09** | Project agent-defs + skills bloat | 16 roles ×3 families + `RUNTIME-SUBAGENT-PATTERN.md`; `project-template/skills/*/SKILL.md` (37) | agent-defs §3.3 (B4 tri-family); skills **§3.1 S-test** | `project-only` | tri-family-locked per role (3 files/role ONE unit); roles parallel; skills parallel; Check 1 intact; A.5 contract on skills. SPLITTABLE → CB-09a (agent-defs) / CB-09b (project skills) |

**Splitability note.** CB-09 is the largest (48 agent-def files + 37 skills). If the reviewer's load is too heavy, split into **CB-09a** (agent-defs, `project-only`) and **CB-09b** (project skills, `project-only`) — 10 bloat commits total. The architect confirms this is a reviewability split, not a scope change (DESIGN-METHOD §C.2.1 — the partition is unchanged); no re-approval needed. **The §3.1 S-test + A.5 contract attach to CB-09b (project skills) specifically.**

**Scope-keyword cleanliness (Check 36).** Every bloat commit is single-surface (CB-01..CB-06 pack; CB-07..CB-09 project) → each carries a clean `pack-only` / `project-only` keyword. NO bloat commit is cross-surface. Guard: keep the keyword token out of any subject prose except as the scope claim (commit-subject-keyword-token-trap). **CRITICAL for CB-07/CB-08/CB-09 (project-only):** if a project-doc snippet reword would require co-updating the pack-ops allowlist (C-SNIP-2(b)), that makes the commit cross-surface and BREAKS `project-only` → AVOID by preferring C-SNIP-2(a) verbatim-keep (§7).

### 4.1 Accumulated cleanup folds — assignment + confirmation

**FLAG-2a (confirmed → CB-01).** `pack-ops/OPTIONAL-FEATURES.md` carries a deferred-axis forward-look the CG-04 strip wave MISSED: the worktree section's **`**Status:**` line** "Claude Code only — no Codex or Antigravity equivalent yet (the cross-CLI story is tracked separately and is out of scope here)." Measured @ `103cca8` at the `## Claude Code — Isolated parallel agents (worktree isolation)` section. Per CENSUS §5 KEEP-the-guardrail/STRIP-the-promise split: KEEP the operative "Claude Code only" current-state fact; STRIP the "no Codex or Antigravity equivalent yet … the cross-CLI story is tracked separately" deferred forward-look. CB-01 already touches OPTIONAL-FEATURES → fold this strip into CB-01 (the §3.2 human-readable reduction pass handles it as part of the same file's edit). CONFIRMED: CB-01 is the right home.

**History-NARRATIVE prose (→ the bloat commit that touches each file).** These carry no Check-65 regex token (the gate won't catch them; the bloat passes re-touch the files so they strip it):
- `pack-ops/BOUNDARY-DEFINITION.md` — the "Per user-curation direction in `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` §1 — sufficient authority" audit-provenance clause (in the exempt-file table "Reason exempt" cell). History-narrative prose; reduce to the operative exempt reason without the audit-provenance. → **CB-01** (CB-01 touches BOUNDARY-DEFINITION).
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` — the `## Empirical validation requirement` section's trailing paragraph "The per-BD-AND-per-batch review cycle was empirically validated retroactively across prior multi-BD batches: …". History-narrative (a retroactive-validation account). Reduce to the operative requirement; the "empirically validated retroactively across prior batches" account is the history-narrative to strip. → **CB-01** (CB-01 touches CONCEPTUAL-REVIEW).
- Both files are in CB-01's membership → both folds land in CB-01. No new commit needed.

**Gate-completeness items (→ CG-14-prep, NOT the bloat commits).** See §6. The division is explicit: **bloat passes handle history-NARRATIVE prose** (the two items above, in CB-01); **CG-14-prep handles the gate allowlist + the regex tightening** (the four false-positive/legitimate-KEEP sites). This keeps the bloat commits free of gate-code edits and concentrates the Check-65 calibration in the one CG-14-prep step.


### 4.2 Sequencing / dependency map (rule-10 parallel-vs-dependent)

- **Phase gate:** all CB-01..CB-09 run AFTER `103cca8` (the strip-clean, pushed, CI-green baseline). The clause-set-diff / invariant-set-diff baseline for every commit is `git show HEAD:<file>` against the strip-clean version.
- **Same-file serialization:** none across CB commits — the §4 partition gives every bloat-bearing file exactly one CB commit (no file in two), so there is NO same-file serialization between bloat commits. Each CB commit serializes only internally (its trinity/tri-family lock).
- **Trinity lock:** CB-06 (pack trinity ×3) and CB-07 (project trinity ×3) are each ONE atomic commit. CB-06 ∥ CB-07 (disjoint file sets).
- **Tri-family lock:** CB-09 (or CB-09a) edits each role's 3 family files as ONE unit; roles parallel.
- **High parallelism:** CB-01 (distinct files), CB-04, CB-05, CB-08, CB-09 skills half — all parallel across distinct files within the commit's worktree wave.
- **Wave order to Pack Chat (scheduler):** CB-02/CB-03/CB-04/CB-05 (pack, distinct) can run as a parallel wave; CB-01 (pack, distinct files incl. the ceiling re-derive) parallel; CB-06 + CB-07 the trinity serial bottlenecks (∥ each other); CB-08 + CB-09 high-parallelism project waves. No bloat commit blocks another on a shared file.
- **CG-14-prep depends on ALL CB-01..CB-09 landed** (the two-axis sweep runs over the final bloat-reduced tree).
- **CG-14 activation depends on CG-14-prep clean** (populates the gate over the final state).

**EE-4A — no-double-BLOAT-touch census @ `103cca8`.**
- Cmd (manual cross-check of §4 file membership): each bloat-bearing file mapped to exactly one CB commit — pack OPTIONAL/MERGE/CONCEPTUAL/PACK-CHAT/PACK-AGENTS/DRY-RUN/BOUNDARY → CB-01; RATIONALE → CB-02; pack stream-meta → CB-03; pack skills → CB-04; pack agents → CB-05; pack trinity → CB-06; project trinity → CB-07; project docs/pack + prompts + stream-meta → CB-08; project agent-defs + project skills → CB-09.
- Output: no file appears in two CB rows of the §4 table.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the no-double-BLOAT-touch invariant holds across the 9-commit partition.
- Conclusion: **SUPPORTED.**

---

## 5. THE CB-01 OPTIONAL-FEATURES RECIPE (ceiling reduce-then-re-derive — measure-then-bound)

Folds DESIGN-METHOD §B.3. The 271 ceiling is STALE: it was derived as `271 = ceil(235 × 1.15)` from a 235-line measured-cleaned baseline that PRE-DATES the graphify section. The doc is now 544 lines (2.3× the 235 the ceiling was derived against). A ceiling derived against pre-graphify content cannot correctly bound post-graphify content.

**The deterministic recipe the CB-01 coder runs (no architect escalation — resolved):**
1. **Reduce to the human-readable floor (§3.2).** Apply the §B.2 prose-only reduction (restatement padding + hedging + B2-where-it-helps) + the FLAG-2a strip + leave ALL fenced blocks byte-identical + preserve the Check-54 trio (`baseRef`, `bgIsolation`, `permissions.deny`) + the K13 graphify snippet (`DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`) verbatim.
2. **Measure the result:** `wc -l pack-ops/OPTIONAL-FEATURES.md` in the worktree = `measured_reduced_lines`.
3. **Re-derive the ceiling FROM the measured reduced content (same formula the existing ceiling used):** `new_ceiling = ceil(measured_reduced_lines × 1.15)`.
4. **Apply the bound:**
   - If `measured_reduced_lines ≤ 235` → the existing 271 ceiling STANDS (no change).
   - If `235 < measured_reduced ≤ 271` → 271 still holds (under ceiling) → no change.
   - If `measured_reduced > 271` → UPDATE the ceiling in the SAME `pack-only` commit (CB-01) to `ceil(measured_reduced × 1.15)`.
5. **Do NOT over-terse to hit 271.** The ruling is explicit: the reduction cannot remove clarity/meaning. If reaching 271 would force dropping a settings example or human-useful clarity, re-derive the ceiling UP to the irreducible floor instead. The advisory NEVER fails the build → no functional pressure to undershoot meaning.

**Lock-step surfaces IF the ceiling changes (enumerate-encoding-surfaces — measured @ `103cca8`):**
- `scripts/validate-pack.py` — the `("pack-ops/OPTIONAL-FEATURES.md", 271)` tuple row in `_CHECK_44_DURABLE_DOCS` (validate-pack.py:7763) → new value.
- The accompanying comment block (validate-pack.py:7752-7755) that records the measured baselines `(BOUNDARY 135, CONCEPTUAL-REVIEW 298, DRY-RUN 199, HELP-PACK 48, MERGE 484, OPTIONAL 235)` → update the `OPTIONAL 235` token to the new `measured_reduced_lines`.
- **The Check-44 TEST needs NO value edit.** `scripts/tests/test-validate-pack-check-44.sh` uses a SYNTHETIC doc with a mocked `_CHECK_44_DURABLE_DOCS` + a parameterized `advisory_ceiling` — it does NOT hard-code the real 271. Changing the real ceiling row touches ONLY the one tuple + its comment; the test is unaffected (DESIGN-METHOD EE-TEST-MOCK).
- No other surface encodes 271 (greped: only validate-pack.py:7763 + the comment).
This keeps CB-01's `pack-only` scope clean (validate-pack.py + the doc are both pack-side).

**EE-5A — the 271 ceiling basis + staleness @ `103cca8`.**
- Cmd: `sed -n '7746,7763p' scripts/validate-pack.py`.
- Output (verbatim, key): comment "per-doc ADVISORY line ceiling, DERIVED from its measured cleaned content as ceil(measured * 1.15) … (BOUNDARY 135, CONCEPTUAL-REVIEW 298, DRY-RUN 199, HELP-PACK 48, MERGE 484, OPTIONAL 235)"; tuple `("pack-ops/OPTIONAL-FEATURES.md", 271)`; `_CHECK_44_DURABLE_DOCS` has 6 rows (HELP-FRAGMENT-TRACKER row removed by the strip phase — confirms BOUNDARY/CONCEPTUAL/DRY-RUN/HELP-PACK/MERGE/OPTIONAL).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: `271 = ceil(235×1.15)`; the 235 baseline pre-dates the graphify section; re-derivation FROM the measured reduced content is the measure-then-bound fix; only validate-pack.py:7763 + the comment encode 271 (test is mock-parameterized).
- Conclusion: **SUPPORTED.**

---

## 6. THE CG-14-PREP STEP (after all CB commits, before CG-14 activation)

CG-14-prep is a single `pack-only` + (one cross-surface re-grep, no edit) preparation step that calibrates Check 65 against the FINAL bloat-reduced tree and lands the accumulated gate-completeness items. It runs AFTER CB-01..CB-09 land and BEFORE CG-14 populates the gate. It is gate-code work → routes to a `pack-coder` under the bounded review/fix cycle (the gate-code + allowlist edits are NOT Pack-Chat-direct).

### 6.1 The two-axis sweep (recall gates over the full IN set, post-bloat)

Per CENSUS §6 (the completeness backstop Check 65 cannot provide as a regex):
- **Axis 1 — Check-65 history sweep.** Run the Check-65 forbidden-pattern set over the full IN set on the post-bloat tree and confirm every hit is allowlist-covered. Mechanically: temporarily populate `_CHECK_65_OPERATING_DOCS` to the full IN set, run `python3 scripts/validate-pack.py --only-check 65`, expect exit 0 (this IS the CG-14 dry-run; discard the temp population — agents never commit a probe). Any uncovered hit = a residue a bloat reword introduced or a gate-completeness item to fix (§6.2).
- **Axis 2 — deferred-feature re-grep.** Re-grep the CENSUS §1 deferred-feature term set over the full IN set; expect ZERO hits outside the CENSUS §5 KEEP set:
  - `grep -rniE "tracker (mode|integration|opt-in)|pack tracker|tracker\.toml\.example|TrackerProvider|GH Issues" $IN` → only KEEP-set generics.
  - `grep -rniE "deferred to a future|future pack version|future release|future version|not yet created|once those skills land|v11\.1|v11\.x|when BD-[0-9]+ lands|on the .*roadmap|Phase B" $IN` → ZERO.
  - `grep -rni "pack-auditor|auditor-issue-tracking|Future integration|tracker opt-in walkthrough" $IN` → ZERO.
  Any hit not in §5 KEEP = a BLOCKER (an un-stripped deferred-feature mention a bloat re-touch should have caught, or a FLAG-2a-class miss). This is the recall gate over the bloat re-touches.

### 6.2 The accumulated gate-completeness items (measured @ `103cca8`)

These are Check-65 pattern hits the strip census missed — each is either an operative-word false-positive or a legitimate KEEP. Fix at CG-14-prep by allowlist OR by tightening the over-broad `incident` regex.

**Recommendation: tighten the `incident` regex `re.compile(r"incident")` → `re.compile(r"\bincident\b")`.** This is ONE edit that kills the substring false-positives "incidents" (PACK-FEEDBACK:59) and "coincidental" (prompts/reviewer.md:128) in one move, while still catching the real history-narrative "incident" the gate targets. This is a gate-design call within the architect/coder surface (it narrows a forbidden pattern that was over-broad — measure-then-bound: the legitimate forbidden hit is the standalone word "incident", not its appearance inside "incidents"/"coincidental").

| # | Site (measured @ `103cca8`) | Pattern matched | Disposition | Recipe |
|---|---|---|---|---|
| GC-1 | `project-template/docs/pack/PACK-FEEDBACK.md:59` "individual **incidents**" | `incident` (substring) | false-positive | killed by `\bincident\b` tightening (no allowlist record needed) |
| GC-2 | `project-template/docs/pack/prompts/reviewer.md:128` "not **coincidental**" | `incident` (substring) | false-positive | killed by `\bincident\b` tightening |
| GC-3 | `project-template/skills/boundary-investigation/SKILL.md:33` "The audit **incident** (P-missed-7)" | `incident` (whole word) | legitimate KEEP (operative reference to the P-missed-7 boundary regression — a current rule's rationale, not history-narrative) | SURVIVES the `\bincident\b` tightening → needs a K-extension allowlist record (doc + pattern `incident` + snippet `The audit incident (P-missed-7)` + reason "live operative reference to the P-missed-7 boundary regression the skill teaches, not history provenance"). NB: this is the PROJECT copy; the PACK copy `.claude/skills/boundary-investigation/SKILL.md` has NO "incident" hit (measured) — only the project copy needs the record. |
| GC-4 | `backlog/_rules.md:35` header-grammar `**BD-167 — <Title>**` | `bd-tag` (`BD-\d+`) | legitimate KEEP (the write-contract's filename-grammar example — a header form the agent acts on, not provenance) | K7-EXTENSION allowlist record. The existing K7 record's snippet is `BD-167.md`, which does NOT substring-match line 35 (line 35 has `BD-167 —`, not `BD-167.md`). Add a new K7-extension record: doc `backlog/_rules.md` + pattern `bd-tag` + snippet `**BD-167 — <Title>**` + reason "filename/header-grammar example the write-contract acts on (illustrative, not provenance)". |

**Division (explicit, per the prompt):** the bloat passes handle history-NARRATIVE prose (the two CB-01 folds, §4.1); CG-14-prep handles the gate allowlist (GC-3 + GC-4 new records) + the regex tightening (`incident` → `\bincident\b`). The `incident` tightening is a `scripts/validate-pack.py` edit; the GC-3/GC-4 records are `pack-ops/.operating-doc-history-allowlist.txt` edits — both pack-side → CG-14-prep is `pack-only`.

**FLAG-2a confirmation at CG-14-prep:** the Axis-2 re-grep (`future pack version` etc.) over OPTIONAL-FEATURES confirms the FLAG-2a strip (folded into CB-01) actually landed — if the worktree Status forward-look survives, it surfaces here as a non-zero hit (BLOCKER) before CG-14 activates. This is the backstop that the CB-01 fold was complete.

**EE-6A — the `incident` regex is an unbounded substring match @ `103cca8`.**
- Cmd: `sed -n '7902,7918p' scripts/validate-pack.py`.
- Output (verbatim): `("incident", re.compile(r"incident")),` (no word boundaries) — alongside `("user-locked", re.compile(r"User-locked"))`, `("carry-over", re.compile(r"carried from|carry-over"))`, `("bd-tag", re.compile(r"BD-\d+"))`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: `re.compile(r"incident")` matches "incidents" and "coincidental" as substrings → the GC-1/GC-2 false-positives are real; `\bincident\b` fixes both without admitting them to the allowlist.
- Conclusion: **SUPPORTED.**

**EE-6B — the 4 gate-completeness sites + their coverage @ `103cca8`.**
- Cmd: `grep -nE "incident" project-template/docs/pack/PACK-FEEDBACK.md project-template/docs/pack/prompts/reviewer.md project-template/skills/boundary-investigation/SKILL.md .claude/skills/boundary-investigation/SKILL.md`; `grep -nE "BD-167" backlog/_rules.md`; `sed -n '35p' backlog/_rules.md | grep -o "BD-167.md"`.
- Output (verbatim): `PACK-FEEDBACK.md:59 … individual incidents`; `reviewer.md:128 … not coincidental`; `project-template/skills/boundary-investigation/SKILL.md:33 The audit incident (P-missed-7)`; (pack copy `.claude/skills/boundary-investigation/SKILL.md` returns NO incident hit); `backlog/_rules.md:35 … For a header **BD-167 — <Title>**`; line-35 `grep -o "BD-167.md"` → (empty, no match).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: GC-1/GC-2 are substring false-positives (tightening fixes); GC-3 is a whole-word legitimate KEEP on the PROJECT copy only (needs a record); GC-4 line 35 has `BD-167 —` not `BD-167.md` → the existing K7 `BD-167.md` snippet does NOT cover it → needs a K7-extension record.
- Conclusion: **SUPPORTED.**


---

## 7. THE SNIPPET-STABILITY CONTRACT (C-SNIP — binding; load-bearing because CG-14 activates AFTER bloat)

Check 65 clears an allowlisted line ONLY when its `snippet:` is a SUBSTRING of that line (`_check_65_load_allowlist` matches `(doc, snippet-substring)`; line numbers are NOT used). A bloat reword that moves/alters an allowlisted line so the snippet no longer matches makes the forbidden token resurface UNCOVERED → CG-14 turns RED at activation. So every bloat reword on a doc carrying allowlisted lines MUST keep every snippet substring matchable. (Carried forward from the prior plan §6.2, unchanged by the architect rulings; DESIGN-METHOD §C.3 reaffirms it and adds the OPTIONAL K13 graphify snippet + the Check-54 trio as concrete CB-01 protected tokens.)

**C-SNIP-1 — Inventory per bloat commit.** Before a bloat commit touches a file with allowlist records, the coder lists every `snippet:` for that file (from `pack-ops/.operating-doc-history-allowlist.txt`). The snippet-bearing bloat files (from the 37-record allowlist, measured @ `103cca8`):

| Bloat commit | File | Allowlisted snippets that must stay matchable |
|---|---|---|
| CB-01 | `pack-ops/OPTIONAL-FEATURES.md` | `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (K13) |
| CB-01 | `pack-ops/PACK-CHAT.md` | the 2 PACK-CHAT records (K5/K6 doc-refs) |
| CB-01 | `pack-ops/PACK-AGENTS.md` | the 1 PACK-AGENTS record (K5 doc-ref) |
| CB-02 | `pack-ops/PACK-MEMORY-RATIONALE.md` | the 6 RATIONALE records (K2-K5/K13 doc-refs) |
| CB-03 | `backlog/_rules.md` | `BD-167.md` (K7), `^BD-\d+\.md$` (K7) — AND after CG-14-prep, the new `**BD-167 — <Title>**` K7-extension (GC-4) |
| CB-06 | `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (pack) | the 5 records each (K1 `until BD-206`, K2/K3 doc-refs, K12 rule self-ref ×2) |
| CB-07 | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | the 2 records each (K12 rule self-ref) |
| CB-08 | `project-template/docs/pack/PACK-FEEDBACK.md` | `Status: Ready (2026-06-15)` (K11) |
| CB-08 | `project-template/docs/project/changelog/_format.md` | the 2 date-format records (K9) — do NOT reword the example lines |
| CB-08 | `project-template/docs/project/changelog/_rules.md` | the 1 date-format record (K10) |

**C-SNIP-2 — Preserve OR co-update.** For each touched allowlisted line, EITHER (a) leave the snippet substring verbatim in the reworded line (PREFERRED — the snippets are stable tokens: filenames, dates, rule-self-ref phrases), OR (b) if the reword genuinely changes the snippet, update the matching allowlist record's `snippet:` in the SAME commit. **CRITICAL scope hazard:** the allowlist file is `pack-ops/` (pack-only). For CB-07/CB-08 (project-only commits) a (b) co-update would make the commit cross-surface and BREAK the `project-only` keyword (Check 36) → those commits MUST use (a) verbatim-keep. For CB-01..CB-06 (pack-only) a (b) co-update stays in-scope.

**C-SNIP-3 — Coder PREFLIGHT dry-activation probe.** Before each bloat commit's IMPL-REPORT, the coder runs `python3 scripts/validate-pack.py` (gate vacuous, proves no NEW history token via the reviewer grep) AND a DRY activation probe: temporarily set `_CHECK_65_OPERATING_DOCS` to JUST the touched files, run `--only-check 65`, expect exit 0 (every allowlisted snippet still matches; no residue). Revert the probe — NO commit of the probe (agents never commit; local read-only verification, discarded). Cheap per-commit insurance that CG-14 will be green for those files.

**C-SNIP-4 — CG-14 activation re-verification.** At CG-14, before flipping `_CHECK_65_OPERATING_DOCS` to the full IN set, re-run the §6.1 Axis-1 sweep (full IN set) and confirm `--only-check 65` exits 0. The single authoritative activation gate over the final state.

**EE-7A — Check-65 allowlist matches by `(doc, snippet-substring)` @ `103cca8`.**
- Cmd: `head -40 pack-ops/.operating-doc-history-allowlist.txt` + `grep -c "^doc:" pack-ops/.operating-doc-history-allowlist.txt` + `grep "^doc:" … | sort | uniq -c`.
- Output (verbatim, key): header "snippet: a stable substring of the allowlisted line (content-anchored, so a line that MOVES is still matched and a line whose content CHANGES stops matching — line numbers are NOT the key)"; `37` records; per-doc counts — `CLAUDE.md 5`, `AGENTS.md 5`, `GEMINI.md 5`, `PACK-MEMORY-RATIONALE.md 6`, `PACK-CHAT.md 2`, `PACK-AGENTS.md 1`, `OPTIONAL-FEATURES.md 1`, `backlog/_rules.md 2`, `project-template/CLAUDE.md 2`, `project-template/AGENTS.md 2`, `project-template/GEMINI.md 2`, `project-template/docs/pack/PACK-FEEDBACK.md 1`, `…/changelog/_format.md 2`, `…/changelog/_rules.md 1`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: a reworded line that drops the snippet substring stops being cleared → the forbidden token resurfaces uncovered → CG-14 FAILs at activation. Confirms the C-SNIP contract is necessary; the per-doc counts are exactly the C-SNIP-1 table.
- Conclusion: **SUPPORTED.**

---

## 8. PER-COMMIT VERIFICATION PLAN (cheap; no new battery checks)

Every bloat commit verifies with:

1. **The method's substantive proof (by surface):**
   - **Skills/agent-defs (CB-04, CB-05, CB-09 skills):** the A.5 contract (§3.1) — invariant-set diff EQUAL before/after (the meaning proof) + the example-removal justification log + the example-retention spot-check + frontmatter intact. This is the gate the skill bloat lives or dies on.
   - **OPTIONAL-FEATURES (CB-01):** the §3.2 protected-content proof — the Check-54 trio survives (`python3 scripts/validate-pack.py --only-check 54` exit 0), all fenced blocks byte-unchanged (`git diff` on fence-delimited ranges = empty), the K13 graphify snippet verbatim, the FLAG-2a strip applied; PLUS the §5 ceiling reduce-then-re-derive recipe in the coder PREFLIGHT (`wc -l`; re-derive; update the tuple + comment if `measured_reduced > 271`).
   - **All other docs (CB-01 rest, CB-02, CB-03, CB-06, CB-07, CB-08, CB-09 agent-defs):** the C.3 clause-set-diff — `git show HEAD:<file>` vs post-bloat, set-equality modulo flagged B3 padding; a non-empty asymmetric diff that is NOT flagged padding = a meaning-loss BLOCKER. The C.2 clause-preserving method (clause-enumerate → convert → re-enumerate → trim padding) is mandatory for any rule >~800 chars (hardest on CB-06: `graph-first-context` 5024c + 5 rules >1200c, and CB-07).
2. **History-NARRATIVE fold proof (CB-01 only):** the reviewer confirms the BOUNDARY-DEFINITION audit-provenance clause + the CONCEPTUAL-REVIEW empirical-validation-retroactive paragraph are reduced to operative form (no history-narrative survives).
3. **Allowlist-snippet-stability probe (C-SNIP-3)** for any file in the §7 table.
4. **Full `validate-pack.py` exit 0** on the combined group result (Check 65 vacuous until CG-14; Check 1 frontmatter intact for skill commits; Check 11 informational for pack agents; tri-family parity for CB-09 agent-defs; trinity parity for CB-06/CB-07).
5. **Trinity/tri-family parity (enumerate-encoding-surfaces):** CB-06/CB-07 assert the structural conversion is byte-parallel across the 3 trinity files AT THAT LOCATION, MODULO the sanctioned Claude-only asymmetries (the `### Sub-agent behavior (Claude-only)` block — present only in pack CLAUDE.md, measured — + the Trinity-exempt notes). The reviewer verifies parity of the SHARED clauses, not byte-identity. CB-09 asserts identical substance ×3 per role.

**CG-14-prep verification:** the §6.1 two-axis sweep (Axis-1 dry-populated `--only-check 65` exit 0 over the full IN set; Axis-2 deferred-feature re-grep ZERO outside §5 KEEP) + the `incident`→`\bincident\b` tightening's per-check test (`scripts/tests/test-validate-pack-check-65.sh` still green; add/adjust a case asserting "incidents"/"coincidental" do NOT match and standalone "incident" DOES) + the GC-3/GC-4 allowlist records verified by re-running the Axis-1 sweep clean.

**CG-14 activation verification:** populate `_CHECK_65_OPERATING_DOCS` to the full IN set; `python3 scripts/validate-pack.py` exit 0 (Check 65 now enforcing); the C-SNIP-4 re-verification; then push (manifest-sync.sh at push if a fixture input changed — doc edits do not change fixture inputs, so expect no manifest churn, but the orchestrator runs the push-time check per the manifest rule).

**ci-check-runtime-compounding note:** NO new per-commit battery check is proposed. The C-SNIP-3 dry probe is a LOCAL coder verification (not added to the battery — does not run ×~155). The `incident`→`\bincident\b` tightening does not add a pattern (it narrows an existing one — same compile-cost, same in-process scan). CG-14's Check 65 enforces over the frozen IN-set list (no whole-tree walk), bounded to Check 44's cost. The bloat phase + CG-14-prep + CG-14 add ZERO recurring CI cost beyond the single Check-65 activation the design already sized.

**Reviewer escalation:** if a bloat reduction cannot preserve the invariant/clause set without judgment (a line genuinely ambiguous between directive and padding), the reviewer flags it; bounded-review-fix-cycle applies (≤2 review/fix pairs + 1 final reviewer; architect escalation if dirty after final).

---

## 9. OPEN RISKS / UNKNOWNS

- **R1 — Project-only commits + allowlist co-update conflict (CB-07/CB-08).** A project-doc snippet reword that needs a `pack-ops/` allowlist co-update breaks the `project-only` Check-36 keyword. MITIGATION: C-SNIP-2(a) verbatim-keep is mandatory for CB-07/CB-08 (§7). RESIDUAL RISK: low — the project-side snippets are the K11/K9/K10 date/status format examples + the K12 rule self-ref, all stable tokens trivially kept verbatim. If a reword genuinely must change one, the commit drops the `project-only` keyword (neutral subject) rather than carrying a false claim.
- **R2 — The `incident`→`\bincident\b` tightening is a gate-behavior change.** Narrowing a forbidden pattern is a Check-65 semantics edit. MITIGATION: it is measure-then-bound (the legitimate forbidden hit is the standalone word, not the substring); the GC-1/GC-2 false-positives are proven (EE-6A/EE-6B); the per-check test gains a case. NOTE for the user: this is a gate-design decision the architect endorsed as the one-move fix — surface it explicitly at the plan-approval gate; the alternative (allowlist GC-1/GC-2 as records) would admit substring false-positives into the allowlist, which treats non-contamination as contamination-by-default (worse per ci-guard-measure-then-bound).
- **R3 — OPTIONAL-FEATURES floor vs Check-54.** The §3.2 reduction must keep the Check-54 trio + the K13 graphify snippet + all fences verbatim while compressing prose. RESIDUAL RISK: low — the protected set is explicitly enumerated (§3.2) and the `--only-check 54` PREFLIGHT + the byte-unchanged-fence check (§8.1) catch any slip before the IMPL-REPORT.
- **R4 — Skill invariant-set-diff judgment.** The A.5 invariant-set diff requires the reviewer to enumerate "guardrail/rule/trigger/exception/scope-statement" consistently across baseline + post-bloat. RESIDUAL RISK: medium on the largest technical skills (python-observability 527, swift-concurrency 418) where most lines are S-test-passing — but that is precisely why the expected reduction is MODEST; an over-zealous coder is caught by the invariant-set diff (BLOCKER on any asymmetric loss).
- **R5 — Stale graph.** The knowledge graph is STALE for BD-243-era surfaces (confirmed in DESIGN/CENSUS EE-GRAPH); discovery used the graph then fell through to grep/`wc -l` (G2). All sizing in this plan is `wc -l`-authoritative. No residual risk — the gate is the file read, not the graph.
- **R6 — CG-14-prep is the SOLE backstop for the deferred-feature axis.** Check 65 cannot regex "is this feature shipped?" (CENSUS §6). If the CG-14-prep Axis-2 re-grep is skipped, an un-stripped deferred mention (or a bloat re-touch that reintroduced one) ships uncaught. MITIGATION: Axis-2 is a hard step in §6.1; the §5 KEEP set is the adjudication reference; any hit outside it is a BLOCKER.

---

## 10. ASSUMPTIONS / DEPENDENCIES

- The strip phase (CG-01..CG-13) is LANDED, pushed, CI-green at `103cca8` (EE-BASE) — the bloat phase operates on this strip-clean baseline; the no-double-touch boundary holds (each file got its strip in a CG commit and gets its bloat in one CB commit).
- The bloat phase does NOT touch the gate code, the new rule, or the allowlist EXCEPT: (a) the CB-01 conditional ceiling re-derivation (validate-pack.py tuple + comment, pack-only, §5); (b) the C-SNIP-2(b) co-update path (pack-only commits only); (c) the CG-14-prep `incident` tightening + GC-3/GC-4 allowlist records (pack-only). All are within their commit's scope keyword.
- CG-14 remains the LAST step and the sole Check-65 activation point, now over the bloat-reduced final tree.
- No manifest/push concerns from the bloat phase (doc edits only; no fixture inputs change) — manifest is push-time per its rule; the orchestrator runs `manifest-sync.sh` at push and commits any regenerated `test-fixtures/manifest.txt` with user approval before the final push.
- This plan is PLANNER-READY → goes to the user for review (planner-output-user-review); NOT auto-approved into a coder spawn. The user's last cheap redirect window is before CB-01's coder spawns.

---

## 11. EMPIRICAL-EVIDENCE BLOCK (consolidated)

All measurements @ HEAD `103cca8` (`103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery; STALE for BD-243-era surfaces (per DESIGN/CENSUS EE-GRAPH) → G2 fallback to `wc -l`/grep/`git`/`python3 validate-pack.py` for every exact-state claim. The authoritative sizing gate is `wc -l`.

- **EE-BASE** (§1) — strip phase landed (CG-13 `be94aa8` → manifest `2780ada` → CG-01 retro fix `103cca8` HEAD); `CHECK_REGISTRY_EXPECTED_COUNT = 63`; `_CHECK_65_OPERATING_DOCS = ()`; Check-65 test exists; full validate-pack green. SUPPORTED.
- **EE-2A** (§2) — bloat-universe line counts @ `103cca8` (PM-CHAT 1109, RATIONALE 784, pack CLAUDE 773/AGENTS 650/GEMINI 638, PLATFORM-SKILLS 616, OPTIONAL 544, PACK-CHAT 495, MERGE 486; project CLAUDE 490/AGENTS 466/GEMINI 526, OPTIONAL 425, PACK-FEEDBACK 452; pack skills 1218, pack agents 484, project skills 3614, agent families 1818/1613/884, prompts 1313, stream-meta 214). SUPPORTED.
- **EE-2B** (§2) — only `pack-ops/OPTIONAL-FEATURES.md` exceeds its Check-44 advisory ceiling (544 vs 271); 1 ADVISORY line; full validate-pack green. SUPPORTED.
- **EE-2C** (§2) — pack CLAUDE.md B1 offenders @ `103cca8`: `graph-first-context` 5024c, `Sub-agent isolation` 2799c, `Pack Chat does MINOR edits` 2394c, `Reconciliation-instance independence` 1379c, `Agents never commit` 1287c, `Record every spawn` 1203c. SUPPORTED.
- **EE-2D** (§2) — OPTIONAL-FEATURES structure: total 544, blank 73, fence-markers 10, fenced-content 35, headers 11 (the §B human-readable floor inputs; coder re-measures at worktree HEAD). SUPPORTED.
- **EE-4A** (§4.2) — no-double-BLOAT-touch: each bloat-bearing file maps to exactly one CB commit. SUPPORTED.
- **EE-5A** (§5) — `271 = ceil(235×1.15)`; 235 baseline pre-dates graphify (now 544); `_CHECK_44_DURABLE_DOCS` has 6 rows (HELP-TRACKER removed by strip); only validate-pack.py:7763 + the comment encode 271 (test mock-parameterized). SUPPORTED.
- **EE-6A** (§6) — `("incident", re.compile(r"incident"))` is an unbounded substring match → matches "incidents"/"coincidental"; `\bincident\b` fixes both. SUPPORTED.
- **EE-6B** (§6) — the 4 gate-completeness sites: PACK-FEEDBACK:59 "incidents" (FP), reviewer.md:128 "coincidental" (FP), project boundary-investigation/SKILL.md:33 "The audit incident (P-missed-7)" (whole-word KEEP, project copy only — pack copy clean), backlog/_rules.md:35 `**BD-167 — <Title>**` (bd-tag, uncovered — K7 snippet `BD-167.md` does not substring-match). SUPPORTED.
- **EE-7A** (§7) — Check-65 allowlist matches by `(doc, snippet-substring)`; 37 records; per-doc counts = the C-SNIP-1 table. SUPPORTED.
- **EE-FLAG2A** (§4.1) — `pack-ops/OPTIONAL-FEATURES.md` worktree section `**Status:**` line carries "no Codex or Antigravity equivalent yet … the cross-CLI story is tracked separately and is out of scope here" (deferred forward-look CG-04 missed). Cmd: `sed -n '108,120p' pack-ops/OPTIONAL-FEATURES.md`. Output (verbatim): "**Status:** Claude Code only — no Codex or Antigravity equivalent yet (the cross-CLI story is tracked separately and is out of scope here)." Interpretation: KEEP "Claude Code only" current-state; STRIP the "no … equivalent yet … tracked separately" forward-look (CENSUS §5 split) → fold into CB-01. Conclusion: SUPPORTED.
- **EE-HISTNARR** (§4.1) — the 2 history-NARRATIVE prose targets. Cmd: `sed -n '105,114p' pack-ops/BOUNDARY-DEFINITION.md`; `grep -n "Empirical validation requirement\|empirically validated retroactively" pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Output (verbatim): BOUNDARY-DEFINITION exempt-table cell "Per user-curation direction in `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` §1 — sufficient authority"; CONCEPTUAL `275:## Empirical validation requirement`, `289:The per-BD-AND-per-batch review cycle was empirically validated retroactively across prior multi-BD batches: …`. Interpretation: both carry no Check-65 regex token (the gate won't catch them) → bloat passes (CB-01) strip the history-narrative. Conclusion: SUPPORTED.
- **EE-ASYM** (§8) — the `### Sub-agent behavior (Claude-only)` block exists only in pack CLAUDE.md (count 1) vs AGENTS.md/GEMINI.md/project CLAUDE.md (count 0) — the sanctioned trinity asymmetry CB-06 preserves. Cmd: `grep -c "Sub-agent behavior (Claude-only)\|### Sub-agent behavior" CLAUDE.md AGENTS.md GEMINI.md project-template/CLAUDE.md`. Output (verbatim): `CLAUDE.md:1`, `AGENTS.md:0`, `GEMINI.md:0`, `project-template/CLAUDE.md:0`. Conclusion: SUPPORTED.

---

## 12. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only git/tooling verbs run: `git rev-parse HEAD`, `git log --oneline`, `git status --short` (snapshot), `wc -l`, `grep`, `sed`, `python3 scripts/validate-pack.py` (read-only validation), `find`, `ls`. Sole write = this plan doc via `cat >>` to the caller-specified `/tmp/pack-handoff-bd243-plan/PLAN-BD-243-BLOAT-PHASE-V2.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH planner; did NOT author `PLAN-BD-243-BLOAT-PHASE.md` (the prior bloat plan) nor any DESIGN/CENSUS. Reached own conclusions: re-measured the entire bloat universe at `103cca8` (not copied from `4de8d50`); independently dry-probed the 4 gate-completeness sites (EE-6B) and FOUND the GC-4 coverage gap (line-35 `BD-167 —` not covered by the existing `BD-167.md` K7 snippet) + that GC-3 is the PROJECT copy only (pack copy clean); confirmed FLAG-2a's exact anchor (EE-FLAG2A); recommended the `incident`→`\bincident\b` tightening as the one-move fix (R2). Folded the architect method without relitigating it. | COMPLIANT |
| **planner-output-user-review** | Plan marked PLANNER-READY (header + §0); not auto-approved into a coder spawn; §0 one-line decision-ready answers + per-section detail; R2 explicitly surfaced as a user decision at the approval gate. | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by EE-BASE/2A/2B/2C/2D/4A/5A/6A/6B/7A/FLAG2A/HISTNARR/ASYM: command + verbatim output (counts/paths/quotes) + HEAD `103cca8` + 2026-06-22 + interpretation + SUPPORTED. Line counts via `wc -l`; ceiling via `sed` of `_CHECK_44_DURABLE_DOCS` + comment; gate patterns via `sed`/`grep` of `_CHECK_65_FORBIDDEN_PATTERNS`; allowlist via `grep` of the snippet records; gate-inert via `grep` of `_CHECK_65_OPERATING_DOCS`. | COMPLIANT |
| **deferral-is-scope-creep** | The bloat axis (CB-01..CB-09) + ALL accumulated cleanup items are planned to LAND: FLAG-2a → CB-01; 2 history-NARRATIVE strips → CB-01; gate-completeness (incident-tighten + GC-3/GC-4 records + FLAG-2a confirmation) → CG-14-prep. Nothing hand-waved to "later"; the CG-14-prep two-axis sweep is the completeness backstop for the no-regex deferred-feature axis. | COMPLIANT |
| **ci-check-runtime-compounding** | §8: NO new per-commit battery check; the C-SNIP-3 dry probe is LOCAL (not ×~155); the `incident`→`\bincident\b` tightening narrows an existing pattern (no added pattern, same in-process scan); CG-14's Check 65 scopes to the frozen IN-set list (no whole-tree walk), bounded to Check 44's cost. Zero recurring CI cost beyond the single sized Check-65 activation. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly: the re-measured bloat universe (§2); the CB-01..CB-09 structure with method-per-surface + cleanup folds (§4); the CB-01 ceiling recipe (§5); the CG-14-prep two-axis sweep + gate-completeness items + FLAG-2a confirmation (§6); the CG-14 activation + push (§6/§8); the snippet-stability contract (§7); verification (§8); EE blocks; this RAVB. Did NOT redesign the architect's method (folded it) nor re-run/re-plan the strip waves. | COMPLIANT |
| **graph-first-context** | Discovery used graph-first intent via the injected absolute path; STALE for BD-243-era surfaces (per DESIGN/CENSUS EE-GRAPH) → G2 fallback to `wc -l`/grep/`git`/`python3 validate-pack.py` IMMEDIATELY for every exact-state claim; `wc -l` over the named IN set is the authoritative sizing gate. Did not block on the graph. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — PLAN-BD-243-BLOAT-PHASE-V2.md**
