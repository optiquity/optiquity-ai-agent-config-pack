# ADVERSARIAL PLAN REVIEW 2 — BD-226 (FRESH independent pack-planner, READ-ONLY)

**Agent:** pack-planner (FRESH, empty context, adversarial, READ-ONLY). **Repo:** optiquity-ai-agent-config-pack, branch `v11-dev`. **HEAD:** `a84094aa7fa2bda0213f66fb1588fdd162d92247` (verified `git rev-parse HEAD`). **Regime:** IN-PLACE (`pwd` = `git rev-parse --show-toplevel` = `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`; branch `v11-dev`). **Deliverable:** this ONE review doc. No repo edits; read-only git verbs only.

**Under review:** `/tmp/handoff-bd226-plan2/PLAN-BD-226-FINAL.md`
**Plan-of-record (SSOT):** `/tmp/handoff-bd226-final/DESIGN-BD-226-FINAL.md` + `backlog/BD-226.md` (rules 1-10).
**Method:** read all three in full; re-measured every load-bearing claim (copy sets, S-RT, agent-run.sh, baselines, leak gates, anchors, manifest/bijection, Check 36 scope) against the LIVE tree at HEAD `a84094a`. I trusted neither doc; every SUPPORTED below is my own measurement.

---

## 1. VERDICT

**READY-FOR-CODER** (with two NIT polish items the orchestrator may fold pre-spawn; neither blocks a coder).

The plan faithfully and executably encodes the FINAL design. Every §2 delta is present; no settled decision (A1, B1, C1-extended, D1, E2, F, F-1..F-13, F-A..F-G, Constraints 1-3, report-location) is dropped, weakened, or re-opened. The ×3 lock-step (incl. S-RT) is complete and each copy is assigned to ONE coder task. The dedicated parallelization section is self-contained and PASSES the user directive. All baselines (31/22/21), the empty-residual proof, the agent-run.sh 2-KEEP/2-STRIP, the project leak gates (0/0), and the anchor quotes re-measure as the plan states. The two NITs are cosmetic (physical section-number ordering; one mildly self-contradictory heading word) and do not impair executability.

### Findings table

| ID | Dim | Severity | One-line |
|---|---|---|---|
| F-P1-a | P1 | NIT | Plan §4.3 heading "OPTIONAL accelerator — the binding-when-parallel schedule" mixes "OPTIONAL" + "binding"; design says "E2 — the binding, executable schedule" — same intent, mildly self-contradictory wording. |
| F-P1-b | P1 | NIT | Plan physical section order is 0,1,2,2.5,3,**5,4**,6,7,8 — `## 5` precedes `## 4`. Self-contained §4 still satisfies rule 10, but a top-to-bottom coder hits §5 before §4. |
| F-P2-a | P2 | INFO (no defect) | All copy sets re-measured EXACTLY match (pack-coder ×3; 4 RO ×12; skills ×3+×3; project coder ×3; repo-ops ×3; S-RT ×1). Fixture copies correctly excluded. No omitted/split copy. |
| F-P3-a | P3 | PASS | Dedicated §4 is its own self-contained section; explicit serial-executability + concrete serial order; correct deps + waves + per-wave mechanics. |
| F-P4-a | P4 | INFO (no defect) | Each commit single-scope; C2 (incl. S-RT `.agents-plugin/…`) stays pack-only; Check 36 `_PROJECT_SIDE_PATH_PREFIXES` re-measured confirms partition; no denying token in any subject. |
| F-P5-a | P5 | INFO (no defect) | Full CI battery per commit; whole-tree-minus-exclusions gate with KEEP allowlist (remainder = 0); per-commit vs batch-end scoping correct; bijection/manifest claims re-measured TRUE. |
| F-P5-b | P5 | NIT (optional) | C4/G1 must PRESERVE the `[rationale: graph-first-context]` tag at CLAUDE.md L624 while reworking the body; plan implies it ("no slug churn") but does not call it out as an explicit G1 sub-step. Re-measured: bijection scans CLAUDE.md `## Pack memory` only; dropping the tag would orphan `## graph-first-context` and FAIL Check 45. |
| F-P6-a | P6 | INFO (no defect) | Every quoted anchor the plan keys on exists verbatim in the live tree; no ordering error, missing file, or new leak found. |

No BLOCKER, MUST, or SHOULD finding. Two NITs (F-P1-a, F-P1-b) + one optional defensive NIT (F-P5-b).

---

## 2. PER-DIMENSION FINDINGS

### P1 — FAITHFUL ENCODING (drift / re-opened decisions)

**Conclusion: faithful. No §2 delta dropped, altered, or weakened; no settled decision re-opened.** I cross-walked every design surface (S1, S2, S3, S4, S6, S7, S-RO, S-RT, S8, S9, S15, S16, S18, G1-G4; S10, S11, S12, S13, S13b, S14, S17, S-AR, S-RT(proj), trinity) to a plan task and a commit.

Spot-verified the highest-risk encodings against the design SSOT and the live tree:
- **S-RT (F-B)** — design §2 S-RT rewords L88 "emit a patch + report" → rule-4 model; project twin NO-OP. Plan T-C2-S-RT (PLAN L79) encodes this verbatim-in-intent + §2.5 NON-targets marks the project twin NO-OP. Live `sed -n '80,95p' .agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` shows the exact "then emit a patch + report" RW bullet; project-twin OLD-model grep is EMPTY. **No drift.**
- **F-1 CLAUDE-only** — design §2 G-surfaces + §6 say edit CLAUDE.md only; do NOT touch AGENTS.md/GEMINI.md graph-first or RATIONALE `## graph-first-context`. Plan C4 file-set (PLAN L113-117) lists exactly G1/G4 (CLAUDE.md), G2 (PACK-CHAT.md), G3 (PACK-AGENTS.md) and an explicit DO-NOT-TOUCH for AGENTS/GEMINI + RATIONALE graph-first. Live grep confirms the self-derivation is duplicated across CLAUDE.md (L597/L610), AGENTS.md (L556/L569), GEMINI.md (L533/L546), RATIONALE (L649) — so the divergence is REAL and the plan's documentation of it is faithful. **No drift.**
- **S-AR (F-C)** — design's 4-location 2-KEEP/2-STRIP table reproduced verbatim in plan T-C6-S-AR (PLAN L169-173). Live `sed` of all four ranges matches the design's verbatim quotes and classification exactly. **No drift.**
- **Constraint 3 derivation-not-baked** — design §2 S3/S10 + §5.4 require stating the DERIVATION (pack→`maintenance-docs/v<major>-…`; project→`docs/impl-reports/<phase>/`), not a literal. Plan T-C2-S3(g) + T-C5-S10(d) both say "state the DERIVATION, not the literal." **No drift.**
- **REPORT-LOCATION-always-/tmp** — design settles "every agent report → named /tmp ALWAYS (no regime conditional)." Plan repeats "REPORT-LOCATION: report ALWAYS → named /tmp handoff dir (remove the in-place conditional)" on every applicable task (T-C2-S7, T-C2-S-RO, T-C3-S15, T-C5-S13, T-C6-S17). **No drift.**

**F-P1-a (NIT).** PLAN L288 heading: "### 4.3 Wave schedule (OPTIONAL accelerator — the binding-when-parallel schedule)". The word "OPTIONAL accelerator" combined with "binding" reads as mildly self-contradictory. The design (DESIGN L348) says "### 4.3 Wave schedule (E2 — the binding, executable schedule)". Both mean "the waves are optional; IF you parallelize, this is the binding schedule" — the plan even states this correctly in §4.0. *Remediation (optional):* align the heading to "OPTIONAL accelerator — binding ONLY when parallelism is chosen" or adopt the design's wording. Non-blocking.

**F-P1-b (NIT).** Physical section order in the plan file is `## 0, 1, 2, 2.5, 3, 5, 4, 6, 7, 8` — i.e., `## 5. CROSS-DOC CONSISTENCY` (PLAN L240) physically precedes `## 4. PARALLELIZATION` (PLAN L252). Logical numbering is fine and §4 remains self-contained (satisfies rule 10's "own section"), but a coder reading top-to-bottom encounters §5 before §4. *Remediation (optional):* swap the two blocks so physical order matches numbering, OR add a one-line forward-pointer at §3's end. Non-blocking — every cross-reference uses the section number, not physical position.

### P2 — ×3 LOCK-STEP COMPLETENESS (incl. S-RT)

**Conclusion: COMPLETE. Every copy enumerated + assigned to ONE coder task; S-RT in C2 + project twin NO-OP.** Re-measured independently with `git ls-files`:

- pack-coder ×3: `.agents-plugin/pack-agents/agents/pack-coder.md`, `.claude/agents/pack-coder.md`, `.codex/agents/pack-coder.toml` → all in T-C2-S7 (PLAN §2.5 row S7). ✔
- 4 RO defs ×3 = 12: pack-{architect,planner,reviewer,docs-researcher} under `.claude/agents/*.md` + `.agents-plugin/pack-agents/agents/*.md` + `.codex/agents/*.toml` → all in T-C2-S-RO (PLAN §2.5 rows). ✔
- commit-discipline SKILL ×3 + implementation-report SKILL ×3 under `.claude`/`.agents`/`.codex` → T-C3-S15/S16. ✔ (Confirmed third member is `.agents` NOT `.agents-plugin` — the plan's §2.5 note + EB-2 call this out; a coder must not confuse the skill triad with the def triad. Re-measured TRUE.)
- project coder ×3 + project repo-ops ×3 under `project-template/.claude`/`.agents-plugin/optiquity-agents`/`.codex` → T-C5-S13/S13b. ✔
- S-RT ×1 `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` → T-C2-S-RT; project twin `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` marked NO-OP (verified CLEAN). ✔
- Fixture copies (`scripts/tests/fixtures/customization-preserve/**`) appear in `git ls-files` but are correctly listed as NON-targets (§2.5) — they are regenerated snapshots, not canonical defs. ✔

No copy is omitted, no copy is split across two tasks. **F-P2-a is INFO, not a defect.**

### P3 — DEDICATED PARALLELISM SECTION (USER DIRECTIVE) — **PASS**

(Full PASS/FAIL in §4 below.) The plan's §4 is a self-contained section with: §4.0 explicit serial-executability statement; §4.1 dependency graph; §4.2 same-file⇒serialize invariant; §4.3 optional wave schedule; §4.4 per-wave worktree mechanics (own worktree, baseRef:head, reviewer rule-fixed, Constraint-1 teardown, rule-9 ASK); §4.5 within-commit ordering; §4.6 concrete serial fallback order `C1 → C5 → C2 → C3 → C6 → C4`; §4.7 future-effort encoding. Dependencies re-checked against the live shared-file edges (below). **PASS.**

### P4 — COMMIT PARTITION / CHECK 36

**Conclusion: clean. Each commit single-scope; C2 stays pack-only after S-RT; C4 serial after C1+C2; no denying token.** Re-measured Check 36 scope: `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")` (validate-pack.py). Therefore:
- C1-C4 (`pack-only`) touch NO path under those two prefixes. S-RT is `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (NOT under `project-template/`) → C2 stays pack-only. ✔
- C5-C6 (`project-only`) touch ONLY `project-template/` (+ `supporting-docs/METHODOLOGY.md` for S11 in C6) → Check 36 clean. ✔
- C4 shared-file edges re-verified live: CLAUDE.md (C1 S1 keystone L339 + C4 G1 L596-624/G4); PACK-AGENTS.md (C1 S4 L139 + C4 G3); PACK-CHAT.md (C2 S3 L232 + C4 G2). So C4 MUST serialize after C1 AND C2 — the plan's §4.2/§4.6 encode exactly this. ✔
- Subjects: I scanned each fixed subject for a denying scope-keyword token. C1-C4 subjects contain no "project-template"/"supporting-docs" token; C5-C6 subjects contain no pack-only token (no "PACK-AGENTS"/"PACK-CHAT"/"pack-ops"). C6's subject names `agent-run.sh` (project-side, safe) and C2's names "agent defs" (not a path). **No token trap.** ✔

**F-P4-a is INFO, not a defect.**

### P5 — VERIFICATION COMPLETENESS

**Conclusion: complete.** Re-measured each load-bearing gate claim:
- **Full CI battery per commit** — PLAN §3 mandates `validate-pack.py` (all checks incl. 18/45/36/62/43) + DEEP + sharded suites + `build.sh --verify`, NOT validate-pack alone. ✔ (verify-full-ci-suite honored.)
- **Whole-tree-minus-exclusions gate + KEEP allowlist (remainder = 0)** — re-measured: `isolated regime`=31, `in-place regime`=22, `emit…patch`=21 over the corrected pack array (with `.agents-plugin`). Whole-tree union minus the 3 exclusions, residual OUTSIDE the two side-arrays = exactly `scripts/lib/tracker-edit.sh` + `scripts/pack-tracker.sh` (tracker "patch JSON" false-positives → KEEP). Empty-residual proof holds; gate is measure-then-bound, not "zero by fiat." ✔
- **Per-commit (own file set) vs batch-end (whole-side) scoping (F-E)** — PLAN §3 + the design §5.5 both scope per-commit grep to THAT commit's files (whole-side mid-batch is unsatisfiable) and run the whole-side union grep ONCE per side at batch end. ✔
- **Project leak gates** — re-measured: project BD-[0-9] over all C5/C6 edited surfaces = 0; project `graphify|graph.json|--graph` over `project-template supporting-docs` = 0. Gates correctly sized to empty. ✔
- **Constraint-2 no-hardcoded-path gate (C4)** + **Constraint-3 derivation gate (C2/C5)** + **C1 trinity body-parity hand-verify** + **C4 F-1 CLAUDE-only + degradation** + **coder PREFLIGHT + bounded review/fix cycle** — all present in PLAN §3 / §5 / §6. ✔
- **No test/validator asserts OLD-default text** — re-measured: zero hits of the OLD-model strings in `scripts/tests/` (non-fixture), zero in `validate-pack.py`, zero hand-asserted in fixtures. So the flip needs no test edit. ✔

**F-P5-b (NIT, optional defensive).** C4/G1 reworks the CLAUDE.md "Graph-first context (BD-225)" bullet body. That bullet ENDS with `[roles: universal] [rationale: graph-first-context]` at CLAUDE.md L624. Check 45's bijection scans the CLAUDE.md `## Pack memory` section for `[rationale: <slug>]` and requires a matching `## <slug>` in RATIONALE.md (`## graph-first-context` @ RATIONALE L635). If a coder, reworking the body, drops or mangles the `[rationale: graph-first-context]` tag, Check 45 fails (orphan rationale heading). The plan's §6 ("Slugs UNCHANGED … graph-first-context untouched by C4") covers this by intent, but the G1 task list (PLAN L120) does not explicitly say "preserve the `[rationale: graph-first-context]` tag." *Remediation (optional):* add one explicit clause to T-C4-G1: "PRESERVE the trailing `[roles: universal] [rationale: graph-first-context]` tag verbatim (Check 45 bijection)." Non-blocking — the §6 + full-CI-battery already catch it, but an inline reminder removes a foreseeable coder slip.

### P6 — EXECUTABILITY + NEW GAPS

**Conclusion: executable; no new gap.** Every quoted anchor the plan keys on exists verbatim:
- pack-reviewer `**RO-emit:**` (`.claude` L48, `.agents-plugin` L52, `.codex/.toml` L28) ✔
- pack-coder RW-emit "in the isolated regime, also emit a `git diff` patch" (L24/L34) ✔
- project `coder.toml` L29 "**Merge-back: emit a patch, never commit.**" ✔
- commit-discipline §1 "Detect your regime" + `worktree-agent-*` + §2 "Write-target rule" ✔
- implementation-report "survives the worktree's auto-removal on agent return" (L16-17) ✔
- CONCEPTUAL-REVIEW L194 "run in-place by default, with opt-in worktree isolation (BD-197)" ✔
- project implementation SKILL "Reporting the change set (regime-aware)" + "Isolated (opt-in worktree)" + "persisted artifact … survives even after" (L34/L46/L51) ✔
- project PM-CHAT.md "Isolation is for read-write agents only." + "RW ⇒ isolate; RO ⇒ in-place." + "Merge-back — the `/tmp` patch handoff." + "via a patch the agent writes before it returns" (bold lead-ins, L~469-520) ✔ — the design's "§ 'Isolation is for RW only' + 'Merge-back'" anchors EXIST as bold lead-ins (not `###` headers); the plan's quoted anchors are findable.

One xref-label nuance (NOT a defect, recorded for the coder): the live agent-run.sh L275-278 xref reads `docs/pack/PM-CHAT.md "In-session agent spawning" and docs/pack/OPTIONAL-FEATURES.md`, and the project PM-CHAT.md has `### In-session agent spawning` (L451) but NO `### Merge-back` header (the merge-back content is a bold lead-in inside that section). The plan's S-AR reword says "Keep the existing PM-CHAT.md + OPTIONAL-FEATURES.md xrefs" and cross-references `docs/pack/PM-CHAT.md 'Merge-back'` — since project PM-CHAT.md's merge-back is a bold lead-in (not a heading), the coder should reference the section that exists (`In-session agent spawning`) or the bold lead-in label, not invent a `### Merge-back` anchor. The plan's "keep existing xrefs" instruction already avoids this; flagged only so the coder does not introduce a dangling `'Merge-back'` heading reference.

No pack-self ref leaks into a project task; no audience-incorrect restatement; ordering is sound; no missing file. **F-P6-a is INFO, not a defect.**

---

## 3. CONSOLIDATED "PLAN MUST INCORPORATE" LIST

None are blocking. In priority order:

1. **(NIT, recommended) F-P5-b** — Add one explicit clause to T-C4-G1: preserve the trailing `[roles: universal] [rationale: graph-first-context]` tag verbatim while reworking the CLAUDE.md graph-first body (Check 45 bijection guard). Re-measured: the tag at CLAUDE.md L624 is the bijection partner of `## graph-first-context` @ RATIONALE L635; dropping it fails Check 45.
2. **(NIT, optional) F-P1-b** — Reorder the physical `## 5` / `## 4` blocks so file order matches the numbering (or add a forward-pointer), so a coder reading top-to-bottom hits §4 before §5.
3. **(NIT, optional) F-P1-a** — Soften the §4.3 heading ("OPTIONAL accelerator — the binding-when-parallel schedule") to remove the "OPTIONAL"+"binding" tension; align to the design's "binding ONLY when parallelism is chosen."
4. **(Coder note, no plan change) P6 xref** — When reworking agent-run.sh L275-278/L306-307, keep the existing live xref labels (`docs/pack/PM-CHAT.md "In-session agent spawning"`); do not introduce a `### Merge-back` heading reference that does not exist in the project PM-CHAT.md.

A coder can execute the plan AS-IS; items 1-4 are polish that reduce a foreseeable slip.

---

## 4. EXPLICIT PASS/FAIL ON P3 (DEDICATED PARALLELIZATION SECTION)

**P3 = PASS.**

| Requirement | Evidence (re-measured / quoted) | Verdict |
|---|---|---|
| Its OWN self-contained section (not inline) | PLAN §4 (L252-318) is a single dedicated section; §4.0 explicitly states it is "deliberately separate from §1/§2 (rule 10 + the USER DIRECTIVE: the parallelization map lives in its own section and does NOT bias the rest of the plan)." | PASS |
| EXPLICIT that main plan is serially executable | PLAN §4.0 (L256-260): "The dependency EDGES (§4.1) are the ONLY mandatory ordering. The parallel WAVES (§4.3) are an OPTIONAL accelerator — never a precondition." | PASS |
| Dependency edges = only mandatory ordering | §4.1 + §4.2 give edges {C1<C2, C1<C3, C1<C4, C2<C4, C5<C6}; re-verified against live shared-file edges (CLAUDE.md/PACK-AGENTS.md C1∩C4; PACK-CHAT.md C2∩C4). | PASS |
| Waves = optional accelerator | §4.3 labeled optional; §4.0 says waves never a precondition. | PASS |
| A CLI without worktree isolation runs the SAME plan serially | §4.0 (L258): "a CLI without worktree isolation (Codex/Antigravity … BD-217, OUT of scope here) or simply operator choice — the SAME plan runs SERIALLY … No task changes; no step is skipped." | PASS |
| A concrete valid serial order given | §4.0 + §4.6: `C1 → C5 → C2 → C3 → C6 → C4` (respects all edges). Re-checked: C4 last (after C1+C2); C6 after C5; C3 after C1; C5 no pack dep. Valid. | PASS |
| Correct dependencies (C4 after C1+C2; C6 after C5; same-file⇒serialize) | §4.1/§4.2 correct; re-measured shared-file edges confirm. | PASS |
| Waves present | §4.3: Wave 0 {C1∥C5}; Wave 1 {C3 ∥ C2→C4 ∥ C6}; max concurrency 3. File-disjointness re-checked (C2∥C3, C1∥C5, C3∥C6, project chain disjoint from pack). | PASS |
| Per-wave worktree mechanics | §4.4: own worktree (rule 1); baseRef:head shared base (rule 8); reviewer/fix-coder RULE-FIXED to the commit's worktree (no ask); rule-9 ASK for non-cycle spawns; Constraint-1 teardown gate; conflict protocol at post-review-clean step. All five mechanics present. | PASS |

---

## 5. EMPIRICAL-EVIDENCE BLOCKS (re-measured THIS pass)

All at **HEAD `a84094aa7fa2bda0213f66fb1588fdd162d92247`**, **2026-06-19**, IN-PLACE in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (pwd = `git rev-parse --show-toplevel`; branch `v11-dev`).

**EB-1 — ×3 copy sets (P2).**
- Command: `git ls-files | grep -E 'agents/pack-coder\.(md|toml)$'`; `… pack-(architect|planner|reviewer|docs-researcher)\.(md|toml)$`; `… project-template/.*agents/(coder|repo-ops)\.(md|toml)$`; `… (commit-discipline|implementation-report)/SKILL\.md$`; `… RUNTIME-SUBAGENT-PATTERN`.
- Output: pack-coder = `.agents-plugin/pack-agents/agents/pack-coder.md`, `.claude/agents/pack-coder.md`, `.codex/agents/pack-coder.toml` (3, + 3 fixture copies under `scripts/tests/fixtures/`). 4 RO ×3 = 12 canonical (`.agents-plugin`, `.claude`, `.codex`). project coder ×3 + repo-ops ×3. commit-discipline + implementation-report SKILL ×3 each under `.agents`/`.claude`/`.codex`. RUNTIME-SUBAGENT-PATTERN = pack `.agents-plugin/pack-agents/…` + project `project-template/.agents-plugin/optiquity-agents/…`.
- Interpretation: exactly matches PLAN §2.5 + DESIGN §1.2; fixtures correctly NON-targets; skill triad third member is `.agents` (not `.agents-plugin`).
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-2 — S-RT content + project twin clean (P1/P2).**
- Command: `sed -n '80,95p' .agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md`; `grep -nE "isolated regime|in-place regime|emit[a-z]*[^.]*patch|patch \+ report|opt-in|merge-back|survives.*auto-removal" project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`.
- Output: pack RW bullet = "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set, then emit a patch + report." Project twin grep → EMPTY.
- Interpretation: S-RT is a real OLD-model pack surface (F-B); project twin a verified NO-OP. Matches plan T-C2-S-RT + §2.5 NON-target.
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-3 — agent-run.sh 4 locations + 2-KEEP/2-STRIP (P1/P6).**
- Command: `sed -n` over L170-180, L273-280, L304-309, L604-610 of `project-template/agent-run.sh`.
- Output: L173-176 `--worktree` help "SECONDARY/opt-in …"; L275-278 "the PM-chat merge-back applies the patch the agent leaves; see docs/pack/PM-CHAT.md \"In-session agent spawning\" and docs/pack/OPTIONAL-FEATURES.md"; L306-307 echo "bring its work back via the PM-chat patch merge-back."; L606-608 "SECONDARY isolated-worktree path (opt-in)."
- Interpretation: matches DESIGN §2 S-AR table + PLAN T-C6-S-AR verbatim. Two launcher-flag (KEEP), two patch-timing (STRIP). The L275-278 live xref label is `"In-session agent spawning"` (not `"Merge-back"`) — coder must keep the existing xref.
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-4 — pack baselines + empty-residual (P5; F-A/F-D).**
- Command: per-dir `grep -rIn -- "isolated regime"` / `"in-place regime"` / `grep -rInE "emit[a-z]*[^.]*patch"` over `CLAUDE.md AGENTS.md GEMINI.md pack-ops/ .claude/agents/ .claude/skills/ .codex/ .agents/ .agents-plugin/`; then `git ls-files -z | xargs -0 grep -IlE "<union>" | grep -vE '^maintenance-docs/|^backlog/|^test-fixtures/|^changelog/|^scripts/tests/fixtures/'` minus the two side-array prefixes.
- Output: isolated regime=**31**, in-place regime=**22**, emit…patch=**21**. Whole-tree residual outside the two side-arrays = exactly `scripts/lib/tracker-edit.sh` + `scripts/pack-tracker.sh`.
- Interpretation: baselines 31/22/21 match the design; empty-residual proof holds; gate is measure-then-bound; only tracker false-positives remain outside the arrays (KEEP).
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-5 — project leak gates = 0 + F-F pre-existing refs (P5).**
- Command: `grep -rEo "BD-[0-9]+" project-template supporting-docs | wc -l`; `grep -rEn "graphify|graph\.json|--graph" project-template supporting-docs | wc -l`; `grep -n "Pack Chat" project-template/docs/pack/PM-CHAT.md`.
- Output: project BD-NNN = 0; project graphify = 0; PM-CHAT.md "Pack Chat" at L342 + L344 ONLY (outside the S10 L470-532 region).
- Interpretation: leak gates correctly sized to empty; F-F pre-existing-ref scoping is justified (whole-file audience grep would false-positive on L342/L344).
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-6 — manifest + Check 45 bijection facts (P5; F-P5-b).**
- Command: `grep -c "graph-first-context" pack-ops/.spawn-rule-manifest.txt`; `grep -c "^slug:" …`; `grep -rn "\[rationale: agents-never-commit\]" CLAUDE.md AGENTS.md GEMINI.md`; `grep -rn "\[rationale: graph-first-context\]" CLAUDE.md AGENTS.md GEMINI.md`; `sed -n '339,360p' CLAUDE.md | grep rationale`; validate-pack.py Check 45 corpus = `REPO_ROOT/CLAUDE.md` `## Pack memory` ↔ `pack-ops/PACK-MEMORY-RATIONALE.md`.
- Output: `graph-first-context` NOT in manifest (manifest has 7 slugs; `agents-never-commit` @ manifest L24). `[rationale: agents-never-commit]` @ CLAUDE.md L170 / AGENTS.md L172 / GEMINI.md L139. `[rationale: graph-first-context]` @ CLAUDE.md L624 / AGENTS.md L584 / GEMINI.md L562. Keystone region (L339-360) has NO rationale tag. Check 45 scans CLAUDE.md `## Pack memory` only.
- Interpretation: keystone outside bijection (no tag) — S1 safe; `agents-never-commit` tagged → S8 body edit keeps `## agents-never-commit` heading → bijection holds; `graph-first-context` tagged in CLAUDE.md L624 with partner heading RATIONALE L635 → C4/G1 must PRESERVE the tag (F-P5-b). `graph-first-context` not manifest-tracked → C4 triggers no manifest change (plan/design claim TRUE).
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED** (all plan/design claims TRUE; F-P5-b is a defensive reminder, not a contradiction).

**EB-7 — Check 36 project-side prefixes (P4).**
- Command: `grep -n "_PROJECT_SIDE_PATH_PREFIXES" scripts/validate-pack.py` + surrounding lines.
- Output: `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`.
- Interpretation: `project-only` permits exactly those two prefixes; `pack-only` denies them. S-RT (`.agents-plugin/…`) is not under them → C2 stays pack-only; C5/C6 touch only those prefixes → project-only clean. Plan's partition + token-trap handling SUPPORTED.
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-8 — no test/validator asserts OLD text (P5).**
- Command: `grep -rIn "isolated regime|in-place regime|isolation is opt-in|in-place by default|patch + report" scripts/tests/ | grep -v fixtures/`; same over `scripts/validate-pack.py`; `grep -rIl … scripts/tests/fixtures/ test-fixtures/`.
- Output: all EMPTY.
- Interpretation: the flip needs no test edit; install-snapshot fixtures don't hand-assert the OLD-model phrases. Plan §3/§5 claim SUPPORTED.
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

**EB-9 — BK-1 state + impl-reports absence (bookkeeping facts).**
- Command: `git status --short backlog/`; `git ls-files | grep docs/impl-reports`.
- Output: ` M backlog/_toc.md` + `?? backlog/BD-235.md`; `docs/impl-reports` ABSENT.
- Interpretation: BK-1 (BD-235 entry + `_toc.md`) correctly framed as out-of-scope bookkeeping; `docs/impl-reports/` is a NEW project subtree the S10 rule introduces by derivation. Plan BK-1 + §5.4 SUPPORTED.
- Date/HEAD: 2026-06-19 / a84094a. **Conclusion: SUPPORTED.**

---

## 6. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran read-only git verbs only: `git rev-parse HEAD` → `a84094a…`, `git branch --show-current` → `v11-dev`, `git rev-parse --show-toplevel`, `git ls-files`, `git status --short backlog/`; plus `grep`/`sed -n`(read)/`wc`/Read/`mkdir /tmp/…`. No add/commit/apply/worktree/branch/reset/restore/checkout/mv/rm/stash. Sole write = this review at `/tmp/handoff-bd226-adv-plan2/ADVERSARIAL-PLAN-REVIEW-2-BD-226.md` (caller-specified, under `/tmp`, outside the repo). No repo state changed. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op attempted; untracked `backlog/BD-235.md` + modified `backlog/_toc.md` only `git status`-read, never touched. | COMPLIANT |
| **deferral-is-scope-creep** | Verified the plan defers NO unblocked in-scope work — every §2 surface (incl. S-RT, S-AR ×4, all ×3 copies, all gates) is assigned to a commit. Only out-of-scope items are the BD's pre-authorized BD-235/BD-217/BD-218. No invented deferral found. | COMPLIANT |
| **no-deferral-without-user-direction** | No invented "defer to v11.1+" anywhere in the plan; the only out-of-scope items are the BD's own pre-authorized deferrals. | COMPLIANT |
| **graph-first-context** | Exact-string / SSOT / freshly-changed-file work → used grep/Read (the rule's own fall-through). No relationship/orientation question needed the graph; per the prior census the graph token-collides on prose for this exact-string work. | COMPLIANT |
| **preflight-stop-means-stop** | No parent stop received; full review completed and written to the named path. | COMPLIANT |
| **rules-applied-verification-block** | This table; every row carries a measurement/quote + terminal conclusion (no empty cell, no AMBIGUOUS). | COMPLIANT |
| **empirical-evidence-blocks** | §5 EB-1..9: each state-claim (copy sets; S-RT + twin; agent-run.sh 4 loc; baselines 31/22/21 + empty residual; project leak=0 + F-F; manifest/bijection; Check 36 prefixes; no-test-assert; BK + impl-reports) has command + verbatim output + HEAD a84094a + 2026-06-19 + interpretation + SUPPORTED. Every figure re-measured by me, not taken from the plan/design. | COMPLIANT |
| **ci-guard-measure-then-bound** | Re-measured the gate: whole-tree-minus-exclusions form (31/22/21); residual outside side-arrays = exactly the 2 tracker false-positives (KEEP); KEEP allowlist sized to the measured legitimate set; expected model-phrase remainder = 0. Confirmed the gate is not over/under-bound. | COMPLIANT |
| **enumerate-encoding-surfaces** | Re-measured EVERY duplicated copy (pack-coder ×3, 4 RO ×12, commit-discipline ×3, implementation-report ×3, project coder ×3, repo-ops ×3, S-RT ×1) → each maps to ONE coder task (PLAN §2.5). Confirmed no validator/test encodes the OLD default (EB-8). No omitted/split copy. | COMPLIANT |
| **pack-project-separation-of-concerns** | Verified C1-C4 (pack-only) and C5-C6 (project-only) never mix; Check 36 `_PROJECT_SIDE_PATH_PREFIXES` re-measured (EB-7); S-RT pack-only (C2), project twin NO-OP. | COMPLIANT |
| **bd-pack-only-operational-rule** | Re-measured project BD-[0-9] over project surfaces = 0 (EB-5); the plan mandates the project BD-NNN=0 gate (PLAN §3 C5/C6, §5.2). | COMPLIANT |
| **cross-cli-reference-normalization** | Verified the plan requires each ×3 def/skill edit to respect the CLI format (`.md` vs `.toml`) and match content-intent not byte-copy (PLAN §2.5 note + per-task "lock-step"); project restatements audience-correct (P-missed-7 headers C5/C6). | COMPLIANT |
| **worktree-isolation-mergeback-ops** | Verified the plan reflects rules 1-10 + Constraint-1 teardown (§4.4) + report-location-always-/tmp + Constraint-3 merge-back (S3/S10); bounded review/fix cycle (§6) unchanged. | COMPLIANT |
| **rename-plans-measure-then-bound** | Verified the flip-completeness gate is a coder-PREFLIGHT + reviewer KEEP-allowlist assertion over the whole-tree `git ls-files` union grep (PLAN §3/§5.1-form), NOT a hand-enumerated anchor list; re-measured the whole-tree form cannot omit a directory (empty-residual EB-4). | COMPLIANT |
| **verify-full-ci-suite** | Verified PLAN §3 mandates the FULL CI battery per commit (validate-pack all checks + DEEP + sharded suites + `build.sh --verify`), not validate-pack alone. | COMPLIANT |
| **commit-subject-keyword-token-trap** | Scanned each fixed subject; no denying scope token in any (C1-C4 carry no project-template/supporting-docs token; C5-C6 carry no pack-only token). C2's S-RT path is pack-side (EB-2/EB-7). | COMPLIANT |
| **adversarial-planner-review-on-major-plans** | This IS that review: re-measured independently (EB-1..9), defaulted skeptical, hunted drift/un-executable tasks/mis-encodings; confirmed no plan claim without my own measurement. Found 2 NITs + 1 optional defensive NIT, no BLOCKER/MUST/SHOULD. | COMPLIANT |

---

*End of ADVERSARIAL PLAN REVIEW 2 for BD-226. Verdict: READY-FOR-CODER. The plan faithfully and executably encodes the FINAL design; all load-bearing claims re-measured at HEAD a84094a SUPPORT the plan. Three optional polish items (F-P5-b explicit tag-preserve clause; F-P1-b section-order swap; F-P1-a heading wording) reduce a foreseeable coder slip but block nothing.*
