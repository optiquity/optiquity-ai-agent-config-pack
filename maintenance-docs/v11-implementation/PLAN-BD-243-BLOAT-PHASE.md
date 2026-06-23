# PLAN — BD-243 BLOAT PHASE (axis 3: structural terseness / bloat reduction, run as a separate phase)

Planner: FRESH planner instance (pack-planner, RO). I did NOT author `PLAN-BD-243-FINAL.md`; conclusions are my own (reconciliation-instance-independence).
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`.
Prompt-named canonical HEAD: `0592a81` (CG-03). **Live HEAD at planning time: `4de8d50` (CG-04 already landed).** All line-count sizing below is measured at `4de8d50` — i.e. the post-token-strip state, which is the correct baseline for sizing the bloat that REMAINS. Where a number is HEAD-sensitive I say so.
Status: PLANNER-READY — goes to the user at the planner-to-coder gate (planner-output-user-review); NOT auto-approved into a coder spawn.

This plan covers ONLY axis 3 (structural BLOAT / terseness reduction, DESIGN §C). Axes 1 (history/audit token strip) and 2 (deferred-feature mention strip) are handled by the in-flight token-strip waves (CG-04 landed; CG-05..CG-13 pending) and are NOT re-planned here (scope-deliverables-to-the-ask). The user has DECIDED to decouple CG-04 into a token-strip-only commit and run bloat as a separate phase; this plan answers HOW and WHEN that separate phase runs.

---

## 0. EXECUTIVE ANSWER (the four questions, one line each — detail in §3-§6)

- **Q1 (how many bloat commits + WHEN):** **9 bloat commits**, run as a **clean trailing phase AFTER all token-strip waves (CG-05..CG-13) and BEFORE CG-14 gate-activation.** Position: CG-05..CG-13 (token strips) → **CB-01..CB-09 (bloat)** → CG-14 (activation). See §3.
- **Q2 (scope — CG-04 files only, or ALL remaining):** **ALL operating docs in the IN set carry the bloat axis, not just CG-04's files.** The bloat universe is 17 high-bloat docs + the tri-family agent-def class + the project-skill class; see the §2 table. The single hard offender over a measured ceiling is `pack-ops/OPTIONAL-FEATURES.md` (544 vs 271). See §2.
- **Q3 (decouple ALL vs leave CG-05..CG-13 combined):** **DECOUPLE ALL — run every remaining token strip as a strip-only commit (CG-05..CG-13) and every bloat reduction in the trailing bloat phase (CB-01..CB-09).** Do NOT revert CG-05..CG-13 to combined. Reasoning in §5: the two jobs have different verification disciplines (grep-zero vs clause-set-diff), different risk profiles, and decoupling makes the riskiest edit (B1 mega-bullet → table) reviewable in isolation. The deliberate double-touch cost is bounded and acceptable.
- **Q4 (gate ordering — bloat BEFORE or AFTER CG-14 activation):** **Bloat runs BEFORE CG-14 activation** (gate inert during the bloat phase; bloat is reviewer-enforced via clause-set-diff; CG-14 activates on the final reduced tree). This sidesteps the allowlist-snippet-stability hazard entirely for the strip-clean lines, and CG-14's own re-grep audit (CENSUS §6) becomes the single activation-gate over the FINAL state. The snippet-stability contract (§6) is still binding as a reviewer rule because a bloat reword can move/alter an allowlisted line. See §4 + §6.

---

## 1. STATE BASELINE (measured @ `4de8d50`)

The token-strip spine + CG-04 have landed; the gate is registered but INERT:

- CG-01 `eec6727` — Check 44 reduced to `will`-only; Check 65 registered with **empty scope**; `CHECK_REGISTRY_EXPECTED_COUNT = 63`.
- CG-02 `7de1fbc` — nuclear deferred-tracker pack-help strip.
- CG-03 `0592a81` — new `operating-docs-no-history-no-bloat` rule (6 trinity + RATIONALE bijection) + K12 self-ref allowlist records.
- CG-04 `4de8d50` — pack-ops history + deferred-feature token strips (9 files) + K13 allowlist records. **TOKEN axis only; NO bloat reduction.**
- `_CHECK_65_OPERATING_DOCS = ()` — VACUOUS. Check 65 enforces nothing against the live tree yet. CG-14 is the sole activation point.
- `pack-ops/.operating-doc-history-allowlist.txt` — 37 KEEP records (K1-K13), content-anchored by `snippet:` substring.
- Full `validate-pack.py` is GREEN at `4de8d50` (verified).

**EE-BASE — state baseline.**
- Cmd: `git log --oneline -5; grep -n 'CHECK_REGISTRY_EXPECTED_COUNT = ' scripts/validate-pack.py; sed -n '/_CHECK_65_OPERATING_DOCS = (/p' scripts/validate-pack.py; python3 scripts/validate-pack.py | tail -3`
- Output (verbatim, key lines): `4de8d50 feat: v11 — BD-243 strip history + deferred-feature mentions from pack-ops operating docs (CG-04) (pack-only)`; `496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; `_CHECK_65_OPERATING_DOCS = ()`; `PASSED — all checks clean`.
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: CG-01..CG-04 landed; gate inert; tree green; EXPECTED_COUNT at 63.
- Conclusion: **SUPPORTED.**

---

## 2. THE BLOAT UNIVERSE (Q2 scope — measured @ `4de8d50`)

The bloat axis applies to the WHOLE IN set (DESIGN §A; §C.4 sizing) — NOT just CG-04's 9 files. DESIGN §C.1 defines four bloat types: **B1** mega-bullet run-on (one bullet = N clauses), **B2** prose-that-should-be-a-table, **B3** verbosity/hedging/restatement padding, **B4** cross-file duplication (tri-family / trinity parity — NOT dedup-able; terseness multiplies ×3).

Only ONE doc carries a measured Check-44 advisory ceiling it EXCEEDS: `pack-ops/OPTIONAL-FEATURES.md` (544 vs 271). The other durable docs (BOUNDARY 135/156, CONCEPTUAL 289/343, DRY-RUN 198/229, HELP-PACK 48/56, MERGE 486/557) are now UNDER their ceilings after the token strips — so for those the bloat axis is "aggressive terseness where it improves the doc," not "must hit a ceiling." Docs with NO advisory ceiling (trinity, PACK-CHAT, RATIONALE, PM-CHAT, etc.) carry absolute bloat ranked by line count + B1 mega-bullet density.

### 2.1 High-bloat doc table (the named bloat targets)

| File | Lines @ `4de8d50` | Advisory ceiling | Dominant bloat type | Surface | Client-facing? |
|---|---|---|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | 1124 | — (no ceiling) | B2 (per-tool sections enumerable) + B3 | project | YES |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | 784 | — | B1 (per-`## slug` Why blocks) + B3 | pack | no |
| `CLAUDE.md` (pack-root) | 783 | — | **B1 (graph-first 5,111c; 4 rules >2,400c)** | pack | no |
| `AGENTS.md` (pack-root) | 658 | — | B1 (graph-first 3,802c; Recommended-first 4,644c) | pack | no |
| `GEMINI.md` (pack-root) | 647 | — | B1 (graph-first 3,877c; Recommended-first 5,742c) | pack | no |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | 616 | — | B2 + B3 | project | YES |
| `pack-ops/OPTIONAL-FEATURES.md` | **544** | **271** (EXCEEDED) | B3 (worktree §111-293; graphify §324-544 prose) | pack | no |
| `project-template/GEMINI.md` | 529 | — | B1 + B4 (trinity parity) | project | YES |
| `pack-ops/PACK-CHAT.md` | 495 | — | B1 + B3 | pack | no |
| `project-template/CLAUDE.md` | 493 | — | B1 + B4 | project | YES |
| `pack-ops/MERGE-STRATEGY.md` | 486 | 557 (under) | B2 (gate enumerations) + B3 | pack | no |
| `project-template/AGENTS.md` | 469 | — | B1 + B4 | project | YES |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | 461 | — | B3 | project | YES |
| `project-template/docs/pack/PACK-FEEDBACK.md` | 452 | — | B3 | project | YES |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | 289 | 343 (under) | B3 | pack | no |
| `pack-ops/PACK-AGENTS.md` | 282 | — | B2 (permission/routing tables) + B3 | pack | no |
| `pack-ops/DRY-RUN-MIGRATION.md` | 198 | 229 (under) | B3 | pack | no |
| `pack-ops/BOUNDARY-DEFINITION.md` | 135 | 156 (under) | B3 | pack | no |

### 2.2 Class bloat (not individually tabled — per-class waves)

- **Pack skills (11)** `.claude/skills/*/SKILL.md`: top offenders commit-discipline 275, verification-harness 241, boundary-investigation 185, implementation-report 155 — B1/B3. (Check 1 frontmatter NEVER stripped.)
- **Pack agents (5)** `.claude/agents/pack-*.md`: pack-coder 204 is the only large one — B3.
- **Project agent-defs (16 roles ×3 families = 48 + RUNTIME-SUBAGENT-PATTERN.md)** `.claude/agents/*.md` (1818 total), `.agents-plugin/.../agents/*.md` (1613), `.codex/agents/*.toml` (884): B4 tri-family duplication; per-role terseness multiplies ×3, parity-locked. Largest: auditor-ops 144, auditor-architecture 139, coder/auditor-ui/auditor-code 137.
- **Project skills (37)** `project-template/skills/*/SKILL.md` (3635 total): largest python-observability-patterns 527 (0 code fences — pure prose, B1/B3), swift-concurrency-patterns 418, apple-swiftdata-patterns 272, protobuf-patterns 249. NOTE: the technical-pattern skills (Swift/Python/gRPC/protobuf) are reference-leaning content; DESIGN §A classifies `skills/*/SKILL.md` IN, but their "bloat" is largely substantive technical guidance — **aggressive terseness here risks deleting substance**. See ARCHITECT-NEEDED flag in §7.
- **Project prompts (10)** `docs/pack/prompts/*.md` (1316 total): B3.
- **Project stream-meta (4)** `docs/project/{backlog,changelog,implementation-plan}/_rules.md` + `changelog/_format.md`: small (47-69 lines each) — minor B3 only (and the K9/K10 date examples are allowlisted — do NOT touch those lines).

**EE-2A — bloat universe line counts.**
- Cmd: `wc -l` over the named IN docs + `wc -l .claude/skills/*/SKILL.md project-template/skills/*/SKILL.md project-template/.claude/agents/*.md project-template/.agents-plugin/optiquity-agents/agents/*.md project-template/.codex/agents/*.toml`
- Output (verbatim, top): `1124 PM-CHAT.md`; `784 PACK-MEMORY-RATIONALE.md`; `783 CLAUDE.md`; `658 AGENTS.md`; `647 GEMINI.md`; `616 PLATFORM-SKILLS.md`; `544 OPTIONAL-FEATURES.md`; project skills total `3635`; .claude agents total `1818`; .agents-plugin total `1613`; .codex total `884`.
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: bloat is concentrated in the pack-root trinity + RATIONALE + OPTIONAL-FEATURES (pack) and PM-CHAT + PLATFORM-SKILLS + project trinity (project); the agent-def + project-skill classes carry distributed bloat.
- Conclusion: **SUPPORTED.**

**EE-2B — only OPTIONAL-FEATURES exceeds its Check-44 advisory ceiling.**
- Cmd: `python3 scripts/validate-pack.py --only-check 44 2>&1 | grep -c ADVISORY` then the matching line.
- Output (verbatim): `1`; `OK: pack-ops/OPTIONAL-FEATURES.md — ADVISORY: 544 lines exceeds the per-doc advisory ceiling 271 ... Advisory only — not a failure`.
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: among the 6 Check-44 durable docs, only OPTIONAL-FEATURES is over its ceiling post-strip — it is the one HARD bloat target with a numeric goal; the rest are advisory-clean and get terseness-where-it-helps only.
- Conclusion: **SUPPORTED.**

**EE-2C — pack-root CLAUDE.md B1 mega-bullet offenders (char count per top-level memory bullet).**
- Cmd: `LC_ALL=C awk '/^- \*\*/ {...accumulate...}' CLAUDE.md | LC_ALL=C sort -rn | head`
- Output (verbatim, top): `5111  - **Graph-first context when the knowledge graph exists`; `4644  - **Recommended first action:`; `2879  - **Sub-agent isolation is keyed by agent class`; `2855  - **No letter suffix.`; `2425  - **Pack Chat does MINOR edits only`.
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: `graph-first-context` is the single biggest B1 mega-bullet (5,111 chars; DESIGN §C.1 cited 5,274 pre-strip — CG-04 token-strips trimmed it ~163 chars). Five rules exceed 2,400 chars. These are the C.2 "rule >~800 chars" structural-conversion targets.
- Conclusion: **SUPPORTED.**

---

## 3. Q1 — HOW MANY BLOAT COMMITS, AND WHEN

**Recommendation: 9 bloat commits (CB-01..CB-09), as a clean trailing phase positioned AFTER all token strips (CG-05..CG-13) and BEFORE CG-14 activation.**

### 3.1 Position in the overall BD-243 process

```
CG-01 (gate code)          [landed eec6727]
CG-02 (nuclear strip)      [landed 7de1fbc]
CG-03 (new rule)           [landed 0592a81]
CG-04 (pack-ops strips)    [landed 4de8d50]   ← token axis only
CG-05..CG-13 (token strip waves, pending)     ← finish ALL token strips first
─────────────────────────────────────────────
CB-01..CB-09 (BLOAT PHASE) ← this plan
─────────────────────────────────────────────
CG-14 (gate ACTIVATION)    ← LAST; activates Check 65 on the FINAL reduced tree
```

### 3.2 Why a clean trailing phase (not interleaved)

1. **Different verification disciplines must not be conflated mid-stream.** Token strips verify by grep-zero on history/deferred patterns (DESIGN §C.3); bloat verifies by clause-set-diff (§C.3). Interleaving them per-file means a reviewer holds two unrelated proof obligations in one review — exactly the conflation the user's decouple decision exists to remove.
2. **The token strips are nearly self-contained and lower-risk; finishing them first banks a clean baseline.** Once CG-05..CG-13 land, every IN doc is history/deferred-clean. The bloat phase then operates on a known-stable text and the reviewer's clause-set-diff baseline is `git show HEAD:<file>` against the strip-clean version — no entanglement with which-token-moved.
3. **CG-14 must activate on the FINAL state (§4/Q4).** Running bloat as a trailing phase before CG-14 means the gate's first enforcing run sees the fully-reduced tree, and the allowlist snippets are re-verified ONCE against final content (no mid-phase snippet churn). If bloat were interleaved or ran after CG-14, every bloat reword would risk a live-gate snippet break (§6).
4. **Wall-clock is not improved by interleaving.** The bloat phase is high-parallelism across distinct files (§4); interleaving with strips would serialize same-file work (a strip and a bloat on one file cannot run concurrently) without any net gain — and it would forfeit the clean baseline.

### 3.3 Why 9 commits (not 1, not 14)

- Not 1 mega-commit: a single 17-doc + 2-class bloat commit is unreviewable (clause-set-diff per swept rule across ~60 files in one review violates bounded-review-fix-cycle reviewability).
- Not 14 (mirroring CG-01..CG-14): the gate/rule/nuclear groups have no bloat counterpart; the bloat axis only needs commits for docs that carry bloat.
- 9 groups by surface + class keeps Check-36 scope keywords clean (pack-only vs project-only), respects trinity-lock and tri-family-lock as atomic units, and keeps each commit's clause-set-diff review tractable. See §4 for the exact 9.

---

## 4. THE 9-COMMIT BLOAT-PHASE STRUCTURE

A bloat commit collects reviewed-clean work-unit patches and applies them as ONE grouped commit, GREEN at apply (full `validate-pack.py` exit 0; Check 65 still vacuous until CG-14). Grouping mirrors the token-strip CG partition surface-for-surface so the no-double-touch invariant holds (each file = one strip commit + at most one bloat commit).

| Commit | Content (bloat axis only) | Files | Scope keyword (Check 36) | Sequencing / lock |
|---|---|---|---|---|
| **CB-01** | Pack-ops operating-doc bloat | `pack-ops/OPTIONAL-FEATURES.md` (hard: 544→≤~271), `MERGE-STRATEGY.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `PACK-CHAT.md`, `PACK-AGENTS.md`, `DRY-RUN-MIGRATION.md`, `BOUNDARY-DEFINITION.md` | `pack-only` | parallel across distinct files; serialize AFTER CG-04 (same files); after CG-05..CG-13 land |
| **CB-02** | Pack RATIONALE bloat (surgical) | `pack-ops/PACK-MEMORY-RATIONALE.md` | `pack-only` | own commit (784 ln, heaviest; per-`## slug` Why terseness; K2-K5/K13 snippet-stable) |
| **CB-03** | Pack stream-meta bloat | `backlog/_rules.md`, `changelog/_rules.md` | `pack-only` | parallel; K7 snippet-stable (backlog/_rules) |
| **CB-04** | Pack skills bloat | `.claude/skills/*/SKILL.md` (11) | `pack-only` | parallel across distinct files; Check 1 frontmatter intact |
| **CB-05** | Pack agent-defs bloat | `.claude/agents/pack-*.md` (5) | `pack-only` | parallel; Check 11 informational |
| **CB-06** | Pack-root trinity bloat | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack root) | `pack-only` | trinity-locked ×3 ONE commit; serialize after CG-08 (same files); C.2 mega-rule method; K1/K2/K3/K12 snippet-stable |
| **CB-07** | Project trinity bloat | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | `project-only` | trinity-locked ×3 ONE commit; serialize after CG-09 (same files); ∥ CB-06; K12 snippet-stable |
| **CB-08** | Project docs/pack + prompts + stream-meta bloat | `docs/pack/PM-CHAT.md`, `PLATFORM-SKILLS.md`, `OPTIONAL-FEATURES.md`, `PACK-FEEDBACK.md`; `docs/pack/prompts/*.md` (10); `docs/project/{backlog,changelog,implementation-plan}/_rules.md` + `changelog/_format.md` | `project-only` | parallel across distinct files; K11 snippet-stable (PACK-FEEDBACK); K9/K10 date lines NOT touched (changelog meta) |
| **CB-09** | Project agent-defs + skills bloat | 16 roles ×3 families + `RUNTIME-SUBAGENT-PATTERN.md`; `project-template/skills/*/SKILL.md` (37) | `project-only` | tri-family-locked per role (3 files/role ONE unit); roles parallel; skills parallel; Check 1 intact. SPLITTABLE if review-size demands (CB-09a agent-defs / CB-09b skills) |

**Splitability note.** CB-09 is the largest (48 agent-def files + 37 skills). If the reviewer's clause-set-diff load is too heavy in one commit, split into **CB-09a** (agent-defs, `project-only`) and **CB-09b** (project skills, `project-only`) — 10 bloat commits total. The plan defaults to 9 with CB-09a/b as a sanctioned in-flight split (no re-approval needed; it is a reviewability split, not a scope change).

**Scope-keyword cleanliness (Check 36).** Every bloat commit is single-surface (CB-01..CB-06 pack; CB-07..CB-09 project) → each carries a clean `pack-only` / `project-only` keyword. Unlike CG-02/CG-03 (cross-surface, neutral), NO bloat commit is cross-surface, so NO neutral-subject case arises. Guard: keep the keyword token out of any prose in the subject except as the scope claim (commit-subject-keyword-token-trap).

### 4.1 Sequencing / dependency summary

- All bloat commits depend on **CG-05..CG-13 fully landed** (clean strip baseline) — this is the phase gate.
- Same-file serialization: CB-01 after CG-04 (pack-ops); CB-06 after CG-08 (pack trinity); CB-07 after CG-09 (project trinity). Since the whole bloat phase runs after all strips, these are satisfied by construction.
- CB-06 ∥ CB-07 (different file sets). CB-01..CB-05 parallel (distinct files). CB-08, CB-09 high parallelism.
- CG-14 depends on ALL of CB-01..CB-09 landed (activates on final state).

---

## 5. Q3 — DECOUPLE ALL REMAINING COMMITS vs LEAVE CG-05..CG-13 COMBINED (the crux)

**Recommendation: DECOUPLE ALL.** Run every remaining token strip (CG-05..CG-13) as a strip-only commit, and every bloat reduction in the trailing bloat phase (CB-01..CB-09). Do NOT revert CG-05..CG-13 to the original "HIST+BLOAT combined" labeling.

### 5.1 The trade-off, concretely

| Dimension | DECOUPLE ALL (recommended) | COMBINED (strip + bloat per commit) |
|---|---|---|
| **No-double-touch invariant** | DELIBERATELY broken: a bloat-bearing file gets TWO commits (strip + bloat). Cost: extra git churn on ~17 docs + 2 classes. | Preserved: one commit per file. This is the ONLY real advantage of combined. |
| **Verification discipline** | Each commit has ONE proof obligation: strip = grep-zero on history/deferred patterns; bloat = clause-set-diff set-equality (§C.3). Reviewer reasons about one thing. | Each commit mixes grep-zero AND clause-set-diff. The reviewer must separate "this line changed because it was stripped" from "this line changed because it was re-tabled" — exactly the entanglement that hides a meaning-loss bug. |
| **Reviewability / commit size** | Strip commits are small + token-precise. Bloat commits are structural but bounded per surface/class. | Combined commits are larger and mix concerns; a B1 mega-bullet→table conversion buried alongside 12 token strips is hard to audit. |
| **Meaning-preservation risk (B1→table is riskiest)** | The riskiest edit (B1 mega-bullet → table, where a dropped clause = behavior change) is isolated in a bloat commit with a dedicated clause-set-diff. A reviewer can diff the pre/post clause set cleanly because the strip already happened. | The clause-set-diff baseline is muddied: `git show HEAD:<file>` still contains the un-stripped history tokens, so the "did every clause survive?" diff is contaminated by the simultaneous token removals. Higher chance a dropped directive hides as "that was just a strip." |
| **Gate-activation ordering** | Clean: all strips land → gate can be reasoned about → bloat lands → CG-14 activates on final state. Snippet-stability is verified ONCE on final content (§6). | A combined commit reword can move an allowlisted line AND strip a token in the same diff — if CG-14 had already activated (it hasn't, but the ordering is fragile), a snippet break and a residue would be indistinguishable. |
| **Wall-clock** | Slightly more commits (9 strips already planned + 9 bloat). But bloat is high-parallelism; the extra commits are cheap relative to the review-clarity gain. | Fewer commits, but each is a slower, higher-risk review. Net wall-clock is a wash; risk is higher. |

### 5.2 Why decouple wins

The combined approach's sole advantage is avoiding the double-touch. But double-touch is cheap here (git churn, not data loss) and the user has ALREADY paid it for CG-04. Reverting CG-05..CG-13 to combined would:
- re-introduce the grep-zero / clause-set-diff conflation the decouple decision removed;
- contaminate the clause-set-diff baseline for the riskiest edits;
- couple the bloat reword to the gate-activation ordering hazard.

CG-04 set the precedent (strip-only). Consistency + the verification-clarity argument both point to decouple-all. The double-touch is a stated, bounded cost, not a regression — it does not lose meaning, it just costs two commits on a file. Per deferral-is-scope-creep, the bloat axis is a stated BD-243 goal and lands fully in the bloat phase; decoupling does not defer it, it sequences it.

### 5.3 The no-double-touch invariant is REPLACED by a no-double-BLOAT-touch invariant

Under decouple-all, the binding invariant becomes: **each file gets EXACTLY ONE strip commit AND EXACTLY ONE bloat commit (or zero bloat commit if it carries no bloat).** A file must never appear in two bloat commits. The §4 partition enforces this: every bloat-bearing file is in exactly one CB-NN. The 8 files the original plan flagged as leak+bloat folds (pack OPTIONAL-FEATURES, pack-startup, project OPTIONAL-FEATURES, project PM-CHAT, project auditor, project coder, project pm-startup, project boundary-investigation) now get their LEAK strip in their CG-NN strip commit and their BLOAT in their CB-NN bloat commit — cleanly separated.

**EE-5A — double-bloat-touch census (no file in two bloat commits).**
- Cmd (manual cross-check of §4 file membership): each bloat-bearing file mapped to exactly one CB-NN; pack OPTIONAL-FEATURES → CB-01 only; RATIONALE → CB-02 only; pack trinity → CB-06 only; project trinity → CB-07 only; PM-CHAT/PLATFORM-SKILLS/project-OPTIONAL/PACK-FEEDBACK/prompts/project-stream-meta → CB-08 only; project agent-defs + project skills → CB-09 only; pack skills → CB-04; pack agents → CB-05; pack stream-meta → CB-03.
- Output: no file appears in two CB-NN rows of the §4 table.
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: the no-double-BLOAT-touch invariant holds across the 9-commit partition.
- Conclusion: **SUPPORTED.**

---

## 6. Q4 — GATE ORDERING (bloat BEFORE or AFTER CG-14) + allowlist-snippet-stability contract

**Recommendation: the bloat phase (CB-01..CB-09) runs BEFORE CG-14 activation. The gate is INERT (`_CHECK_65_OPERATING_DOCS = ()`) throughout the bloat phase; bloat is reviewer-enforced via clause-set-diff; CG-14 activates Check 65 on the FINAL fully-reduced tree.**

### 6.1 The two options, weighed

**(a) Bloat AFTER CG-14 (gate live during bloat) — REJECTED.**
With Check 65 active, a bloat reword that touches an allowlisted line can SILENTLY break the substring match. The allowlist clears a line ONLY when its `snippet:` is a substring of that line (verified: `_check_65_load_allowlist` matches `(doc, snippet-substring)`). If a B1→table conversion or a B3 trim restructures an allowlisted line, the snippet stops matching, the forbidden pattern (e.g. `ARCHITECTURE-BD-119.md`, `until BD-206 retires`) is no longer cleared, and **Check 65 FAILS the bloat commit.** This couples every bloat reword to the allowlist's exact substrings — fragile, and it makes the gate fire for a non-violation (the line is still legitimate; the snippet just drifted). It also means each bloat commit must pre-edit the allowlist in lockstep, multiplying the surface.

**(b) Bloat BEFORE CG-14 (gate inert during bloat) — RECOMMENDED.**
Check 65 enforces nothing during the bloat phase, so a reword that moves/alters an allowlisted line cannot trip the gate mid-phase. Bloat correctness is the reviewer's clause-set-diff (history/deferred re-introduction is caught because the reviewer also re-runs the grep patterns on the post-bloat file). CG-14 then activates ONCE, on the final reduced tree, and its activation green-proof (DESIGN §E.5; CENSUS §6 re-grep audit) is performed against final content with the allowlist snippets re-verified against THAT content. One activation gate, final state, no per-commit snippet fragility.

This matches the original plan's Option-A safety property (CG-14 LAST, green because all strips precede it) — extended so all BLOAT also precedes CG-14.

### 6.2 The allowlist-snippet-stability contract (binding EITHER way; load-bearing under option (b) because CG-14 activates AFTER bloat)

Even with the gate inert during bloat, a bloat reword that changes an allowlisted line will make CG-14 RED at activation (the snippet no longer matches the moved/reworded line, the forbidden token resurfaces uncovered). So the bloat phase MUST preserve allowlist-snippet matchability. The contract:

**C-SNIP-1 — Inventory the snippet-bearing lines per bloat commit.** Before a bloat commit touches a file that has allowlist records, the coder lists every `snippet:` for that file (from `pack-ops/.operating-doc-history-allowlist.txt`). The bloat-bearing files that carry allowlist snippets (from the 37-record allowlist measured @ `4de8d50`):

| Bloat commit | File | Allowlisted snippets that must stay matchable |
|---|---|---|
| CB-01 | `pack-ops/OPTIONAL-FEATURES.md` | `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (K13) |
| CB-01 | `pack-ops/PACK-CHAT.md` | `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (K5), `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (K6) |
| CB-01 | `pack-ops/PACK-AGENTS.md` | `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (K5) |
| CB-02 | `pack-ops/PACK-MEMORY-RATIONALE.md` | `ARCHITECTURE-BD-119.md` (K2), `ARCHITECTURE-BD-182.md` (K3), `ARCHITECTURE-BD-208.md` (K4), `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (K5), `ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` (K13), `RESEARCH-BD-221-ANTIGRAVITY-DOCS-CAPTURE.md` (K13) |
| CB-03 | `backlog/_rules.md` | `BD-167.md` (K7), `^BD-\d+\.md$` (K7) |
| CB-06 | `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (pack) | `until BD-206 retires` (K1), `ARCHITECTURE-BD-119.md` (K2), `ARCHITECTURE-BD-182.md` (K3), the K12 rule self-ref lines (2 snippets ×3) |
| CB-07 | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | the K12 rule self-ref lines (2 snippets ×3) |
| CB-08 | `project-template/docs/pack/PACK-FEEDBACK.md` | `Status: Ready (2026-06-15)` (K11) |
| CB-08 | `project-template/docs/project/changelog/_format.md` | `2026-04-20`, `2026-03-20` (K9) — these are date FORMAT examples; do NOT reword the example lines |
| CB-08 | `project-template/docs/project/changelog/_rules.md` | `2026-04-20` (K10) |

**C-SNIP-2 — Preserve OR co-update.** For each such line a bloat commit touches, EITHER (a) leave the snippet substring intact verbatim in the reworded line (preferred — the snippet is a stable token like a filename or a date, easy to keep), OR (b) if the reword genuinely changes the snippet text, UPDATE the matching allowlist record's `snippet:` in the SAME bloat commit (the allowlist file is pack-ops/, pack-only — fits CB-01..CB-06; for CB-07/CB-08 project-side reword of a project-doc snippet, the allowlist edit is a pack-ops file, making that commit cross-surface → it must then drop the `project-only` keyword. AVOID this by preferring (a)).

**C-SNIP-3 — Coder PREFLIGHT proof.** Before each bloat commit's IMPL-REPORT, the coder runs `python3 scripts/validate-pack.py` (gate still vacuous, so this proves no NEW history token introduced by the reword via the reviewer grep, not Check 65). Additionally, the coder runs a DRY activation probe: temporarily set `_CHECK_65_OPERATING_DOCS` to include just the touched files and run `--only-check 65`; it must exit 0 (every allowlisted snippet still matches; no residue). Revert the probe (NO commit of the probe — agents never commit; this is a local read-only verification the coder discards). This is the cheap per-commit insurance that CG-14 will be green.

**C-SNIP-4 — CG-14 activation re-verification.** At CG-14, before flipping `_CHECK_65_OPERATING_DOCS` to the full IN set, re-run the CENSUS §6 re-grep audit against the final bloat-reduced tree and confirm `--only-check 65` exits 0 over the populated scope. This is the single authoritative activation gate over the final state.

### 6.3 ci-check-runtime-compounding note

No NEW per-commit CI check is proposed. The C-SNIP-3 dry activation probe is a LOCAL coder verification (not added to the battery) — it does not run ×155. CG-14's activation makes Check 65 enforce over ~136 IN docs × a handful of compiled regexes, in-process, scoped to the frozen list (no whole-tree walk) — bounded, matching Check 44's cost (the design already sized this). The bloat phase adds ZERO recurring CI cost.

**EE-6A — allowlist matches by snippet substring (the stability hazard is real).**
- Cmd: `sed -n '/_check_65_load_allowlist/,/return by_doc/p' scripts/validate-pack.py` + the matcher comment.
- Output (verbatim, key): `# matching key is (doc, snippet-substring) — line numbers are NOT used`; `# The check matches an occurrence to a record when the doc matches AND the record's snippet is a substring of the offending line.`
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: a reworded line that drops the snippet substring stops being cleared → the forbidden token resurfaces uncovered → gate FAILs when active. Confirms the C-SNIP contract is necessary.
- Conclusion: **SUPPORTED.**

**EE-6B — the snippet-bearing bloat files (37-record allowlist enumerated).**
- Cmd: `grep -E "^doc:|^snippet:|^# ── K" pack-ops/.operating-doc-history-allowlist.txt; grep -cE "^doc:" pack-ops/.operating-doc-history-allowlist.txt`
- Output (verbatim, count): `37`. Records cover CLAUDE/AGENTS/GEMINI (pack: K1/K2/K3/K12), project trinity (K12), PACK-MEMORY-RATIONALE (K2-K5/K13), PACK-CHAT (K5/K6), PACK-AGENTS (K5), OPTIONAL-FEATURES (K13), backlog/_rules (K7), changelog/_format (K9), changelog/_rules (K10), PACK-FEEDBACK (K11).
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: exactly the C-SNIP-1 table; these are the lines a bloat reword must keep matchable.
- Conclusion: **SUPPORTED.**

**EE-6C — gate is currently inert (CG-14 not done).**
- Cmd: `sed -n '/_CHECK_65_OPERATING_DOCS = (/p' scripts/validate-pack.py`
- Output (verbatim): `_CHECK_65_OPERATING_DOCS = ()`.
- HEAD/date: `4de8d50` / 2026-06-22.
- Interpretation: Check 65 enforces nothing now; option (b) (bloat before activation) is the live default — the bloat phase naturally runs while the gate is inert.
- Conclusion: **SUPPORTED.**

---

## 7. PER-COMMIT VERIFICATION PLAN

Every bloat commit verifies with (cheap, no new battery checks):

1. **Clause-set-diff (DESIGN §C.2/§C.3 — the substantive bloat proof).** For EVERY swept rule the reviewer produces a before/after clause-set diff from `git show HEAD:<file>` (the strip-clean baseline) vs the post-bloat file, asserting set-equality modulo flagged B3 padding. A non-empty asymmetric diff that is NOT a flagged-padding trim = a meaning-loss BLOCKER. This is the gate the bloat axis lives or dies on.
2. **C.2 clause-preserving method for any rule >~800 chars** (mandatory): clause-enumerate → convert prose→structured one-clause-per-row → re-enumerate (post == pre) → trim only B3 padding → trinity/tri-family lock. Applies hardest to CB-06 (`graph-first-context` 5,111c; 4 more >2,400c) and CB-07.
3. **Advisory-ceiling target** (CB-01 only, the one hard numeric goal): `pack-ops/OPTIONAL-FEATURES.md` 544 → at or under the Check-44 advisory ceiling 271, OR a reviewer+user-accepted ceiling re-measure if 271 proves too aggressive for the legitimate cleaned content (the ceiling is "derived from measured cleaned content" — if the worktree/graphify sections are irreducibly long, the ceiling row in `_CHECK_44_DURABLE_DOCS` may need a measured re-derivation in the SAME commit; that is a pack-only validate-pack.py edit, keeps CB-01 pack-only). Advisory NEVER fails the build; it is the smell-signal the bloat targets.
4. **Allowlist-snippet-stability probe (C-SNIP-3)** for any file in the §6.2 table.
5. **Full `validate-pack.py` exit 0** on the combined group result (Check 65 vacuous until CG-14; Check 1 frontmatter intact for skill commits; Check 11 informational for pack agents; tri-family parity for CB-09 agent-defs; trinity parity for CB-06/CB-07).
6. **Trinity/tri-family parity** (enumerate-encoding-surfaces): CB-06/CB-07 assert the structural conversion is byte-parallel across the 3 trinity files AT THAT LOCATION, MODULO the sanctioned Claude-only asymmetries (the `### Sub-agent behavior (Claude-only)` block + the Trinity-exempt notes — these legitimately differ; e.g. pack `graph-first-context` is 5,111c in CLAUDE.md vs 3,802c in AGENTS.md by design). The reviewer verifies parity of the SHARED clauses, not byte-identity. CB-09 asserts identical substance ×3 per role.

**Reviewer escalation:** if a bloat reduction cannot preserve the clause set without judgment (a clause is genuinely ambiguous between directive and padding), the reviewer flags it; bounded-review-fix-cycle applies (≤2 review/fix pairs + 1 final; architect escalation if dirty after final).

---

## 8. ARCHITECT-NEEDED FLAGS (escalate; do not guess)

1. **ARCHITECT NEEDED: project technical-pattern skills bloat policy (CB-09 skills half).** DESIGN §A classifies `project-template/skills/*/SKILL.md` (37) as IN, and §C.4 counts their 3,635 lines in the bloat sizing. BUT the largest (python-observability-patterns 527 ln, 0 code fences; swift-concurrency-patterns 418; apple-swiftdata-patterns 272) are SUBSTANTIVE technical reference content, not operating-instruction bloat. DESIGN §C.1's four bloat types (B1-B4) target run-on rule bullets and prose-that-should-be-tables in OPERATING docs — they do not obviously license terseness on technical how-to guidance where the prose IS the deliverable value. The §C.2 clause-preserving method assumes "clauses" = directives/triggers/exceptions, which maps poorly onto technical exposition. Aggressive terseness here risks deleting genuinely useful client-facing content (these ship to client projects). **The architect must rule whether the technical-pattern skills are in the AGGRESSIVE bloat scope or only the operating/process skills (pm-startup, audit-methodology, boundary-investigation, review, implementation, architecture-review) are.** This is a §C.2-method-insufficiency case, not a planner judgment call.

2. **ARCHITECT NEEDED (conditional): OPTIONAL-FEATURES advisory ceiling re-derivation.** If CB-01's clause-preserving terseness on `pack-ops/OPTIONAL-FEATURES.md` cannot reach ≤271 lines without dropping legitimate operating content (the worktree-isolation §111-293 and graphify §324-544 are both load-bearing operating instruction), the 271 ceiling — "derived from measured cleaned content" — may itself be stale (it predates the graphify section's growth). The coder/reviewer should attempt ≤271 first; if the irreducible cleaned content exceeds it, escalate to the architect to RE-DERIVE the ceiling against the measured post-bloat cleaned content (a `_CHECK_44_DURABLE_DOCS` row edit), rather than over-terse the doc to hit a possibly-stale number. Flagged conditional because it only fires if ≤271 proves infeasible.

3. **(NOT architect-needed, noted for the user) CB-09 split decision.** Whether CB-09 ships as one commit or splits into CB-09a/CB-09b is a reviewability call the orchestrator can make in-flight (§4 splitability note); it needs no architect ruling.

---

## 9. ASSUMPTIONS / DEPENDENCIES

- This plan assumes CG-05..CG-13 land per `PLAN-BD-243-FINAL.md` §5 as STRIP-ONLY commits (mirroring CG-04's decoupling). If the user instead keeps any of CG-05..CG-13 combined, the corresponding CB-NN drops that file (it is already bloated in its combined commit) — but per §5 the recommendation is decouple-all.
- The bloat phase does NOT touch the gate code, the new rule, or the allowlist EXCEPT the C-SNIP-2(b) co-update path and the conditional CB-01 ceiling re-derivation — both pack-only validate-pack.py / allowlist edits that stay within their commit's pack-only scope.
- CG-14 remains the LAST commit and the sole Check-65 activation point, now over the bloat-reduced final tree.
- No manifest/push concerns are introduced by the bloat phase (doc edits only; no fixture inputs change) — manifest is push-time per its rule.

---

## 10. EMPIRICAL-EVIDENCE BLOCK (consolidated)

All measurements @ live HEAD `4de8d50`, branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery during research; STALE for BD-243-era surfaces per the design's EE-V10 → G2 fallback to `wc -l`/grep/`git`/`python3 validate-pack.py` for every exact-state claim (the authoritative sizing gate is `wc -l`, per the prompt).

- **EE-BASE** (§1) — CG-01..CG-04 landed; `_CHECK_65_OPERATING_DOCS = ()`; EXPECTED_COUNT 63; full validate-pack green. SUPPORTED.
- **EE-2A** (§2) — bloat-universe line counts (PM-CHAT 1124, RATIONALE 784, pack CLAUDE 783, AGENTS 658, GEMINI 647, PLATFORM-SKILLS 616, OPTIONAL-FEATURES 544; project skills 3635; agent families 1818/1613/884). SUPPORTED.
- **EE-2B** (§2) — only `pack-ops/OPTIONAL-FEATURES.md` exceeds its Check-44 advisory ceiling (544 vs 271); 1 ADVISORY line total. SUPPORTED.
- **EE-2C** (§2) — pack CLAUDE.md B1 offenders: `graph-first-context` 5,111c (was 5,274 pre-strip), Recommended-first 4,644c, Sub-agent-isolation 2,879c, No-letter-suffix 2,855c, Pack-Chat-MINOR 2,425c. SUPPORTED.
- **EE-5A** (§5) — no-double-BLOAT-touch: each bloat-bearing file maps to exactly one CB-NN. SUPPORTED.
- **EE-6A** (§6) — Check 65 allowlist matches by `(doc, snippet-substring)`; a reworded line that drops the snippet resurfaces the forbidden token (the stability hazard is real). SUPPORTED.
- **EE-6B** (§6) — 37 allowlist records enumerated; the snippet-bearing bloat files are exactly the §6.2 C-SNIP-1 table. SUPPORTED.
- **EE-6C** (§6) — gate currently inert (`_CHECK_65_OPERATING_DOCS = ()`); option (b) bloat-before-activation is the natural default. SUPPORTED.
- **EE-CEIL** — Check-44 durable-doc ceilings (the advisory mechanism): `sed -n '7756,7763p' scripts/validate-pack.py` → `BOUNDARY 156, CONCEPTUAL 343, DRY-RUN 229, HELP-PACK 56, MERGE 557, OPTIONAL 271` (HELP-FRAGMENT-TRACKER row gone, removed by CG-02). @ `4de8d50` / 2026-06-22. Interpretation: 6 durable docs with per-doc ceilings; OPTIONAL is the only one over. SUPPORTED.
- **EE-HEAD-DELTA** — prompt-named canonical HEAD `0592a81` vs live `4de8d50`: `git log --oneline -1` → `4de8d50 ... (CG-04) (pack-only)`. Interpretation: CG-04 landed after the prompt was written; sizing is correctly taken at the post-CG-04 state (the bloat that REMAINS after strips). SUPPORTED.

---

## 11. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD`, `git log`, `git status --short`, `git worktree list`, `git show` (all read-only). Sole write = this plan doc via `cat >>` to `/tmp/pack-handoff-bd243-plan/PLAN-BD-243-BLOAT-PHASE.md`. No repo-file edit; no patch; no state-changing git verb. | COMPLIANT |
| **reconciliation-instance-independence** | Fresh planner; did NOT author `PLAN-BD-243-FINAL.md`. Reached own conclusions: recommend 9 bloat commits as a trailing phase, decouple-all, bloat-before-CG-14 — derived from measured tree state + the allowlist matcher semantics, not copied from the existing plan. One independent extension recorded: the no-double-touch invariant is REPLACED by a no-double-BLOAT-touch invariant (§5.3). | COMPLIANT |
| **planner-output-user-review** | Plan marked PLANNER-READY (§0 header); not auto-approved into a coder spawn; recommendations are crisp + decision-ready (§0 one-line answers + per-question detail). | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by EE-BASE/2A/2B/2C/5A/6A/6B/6C/CEIL/HEAD-DELTA: command + verbatim output + HEAD `4de8d50` + 2026-06-22 + interpretation + SUPPORTED. Line counts via `wc -l`; ceilings via `sed` of `_CHECK_44_DURABLE_DOCS`; allowlist via `grep` of the snippet records; gate-inert via `sed` of `_CHECK_65_OPERATING_DOCS`. | COMPLIANT |
| **deferral-is-scope-creep** | The bloat axis (a stated BD-243 goal) is planned to LAND fully in CB-01..CB-09 — NOT hand-waved to later. Decoupling sequences it, does not drop it. Two genuine §C-method-insufficiency / stale-ceiling cases escalated as ARCHITECT NEEDED (§8) rather than guessed or deferred. | COMPLIANT |
| **ci-check-runtime-compounding** | §6.3: NO new per-commit battery check proposed; the C-SNIP-3 dry activation probe is a LOCAL coder verification (not ×155). CG-14's Check 65 is in-process, scoped to the frozen ~136-doc list (no whole-tree walk), bounded to Check 44's cost. Bloat phase adds zero recurring CI cost. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Answered exactly the 4 questions + the 9-commit structure + the snippet-stability contract + the architect-escalation note + EE blocks + this RAVB. Did NOT re-plan the in-flight token-strip waves (CG-05..CG-13) beyond noting their decouple dependency. | COMPLIANT |
| **graph-first-context** | Discovery graph-first attempted (per design EE-V10 the graph is STALE for BD-243-era surfaces) → G2 fallback to `wc -l`/grep/git immediately for every exact-state claim; `wc -l` over the named IN set is the authoritative sizing gate, as the prompt directs. Did not block on the graph. | COMPLIANT |
| **rules-applied-verification-block** | This table. Every rule in the prompt's Rules-in-force block has measured evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — PLAN-BD-243-BLOAT-PHASE.md**
