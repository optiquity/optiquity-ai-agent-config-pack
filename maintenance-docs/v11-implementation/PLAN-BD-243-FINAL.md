# PLAN — BD-243 (FINAL, reconciled): strip history/audit + deferred-feature MENTIONS + bloat from operating docs; NUCLEAR pack-help tracker strip + client-facing leak census; add anti-bloat governance rule

Planner: FRESH reconciliation pack-planner (RO). NOT the plan author; NOT the adversarial reviewer. Folds the 3 BLOCKERs + 3 MINORs (`ADVERSARIAL-REVIEW-PLAN-BD-243.md`) + the binding user rulings (BLOCKER-1 = Option A activation-last; the HYBRID work-unit/commit-group model) into the final plan.
Runtime HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree (verified §EE-1).
Authoritative inputs: `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL-V2.md` (+ carried FINAL §B/§C/§D/§E/§F/§G/§H) — the design; `/tmp/pack-handoff-bd243-plan/PLAN-BD-243.md` — the prior plan (carried where the adversarial verified it correct); `/tmp/pack-handoff-bd243-plan/ADVERSARIAL-REVIEW-PLAN-BD-243.md` — the fix-list; `/backlog/BD-243.md` — the spec.
**SUPERSEDES** `PLAN-BD-243.md`. This plan IMPLEMENTS the design; it does not redesign it.

This plan defines TWO partitions per the user ruling: **(a) WORK-UNITS** (the parallel isolated-worktree + bounded-review/fix unit) and **(b) COMMIT-GROUPS** (the git-history rollup of reviewed-clean work-unit patches). The Check-65 gate is REGISTERED EARLY with empty scope and ACTIVATED LAST (Option A). DELETE-only except (a) the new rule and (b) the deliberate removal of blocked-feature advertising/leaks. Dormant tracker CODE + guards (Checks 29/35/51) UNTOUCHED (BD-214).

---

## 0. OPEN QUESTIONS FOR USER

No genuinely NEW unanswerable ambiguity surfaced in reconciliation. The two carried OQs are RULED and applied:

- **G1 = STRIP** (user ruling, confirmed by the adversarial). Pack `backlog/_intro.md:19` "Tracker (GH Issues) integration is deferred (BD-214)" is stripped (WU-PACK-INTRO). Gate-EXEMPT → reviewer leak-check, not Check 65.
- **G2 = OQV2-2a** (user ruling). Mark `scripts/pack-tracker.sh` + `scripts/tracker-migrate.sh` `# pack-internal: true`; do NOT mark `scripts/pack-td.sh`; RELOCATE the `pack td` rows out of the deleted HELP-FRAGMENT-TRACKER into HELP-FRAGMENT-PACK + client HELP-FRAGMENT.md (the only content-MOVE; all else is deletion).
- **G3 = 4 docs** (planner-found, evidence-confirmed). Project `docs/pack/` operating IN set = exactly OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT (METHODOLOGY/INSTALL-PROCEDURES/SETUP-EXISTING do NOT exist there — §EE-9). The design's "(6)" label is corrected to 4; no recipe affected.
- **G4 = live `--only-check 45`** (planner-found). The W1/rule work-unit verifies Check 45 against the LIVE gate (exit 0 before + after), NOT the design's approximate "26↔26→27↔27" literal.

All four are settled; none requires a user decision now. The plan still goes to the USER for review/approval before ANY coder spawns (§9).

---

## 1. CHANGES-FROM-PLAN (delta summary — what this reconciliation changed vs PLAN-BD-243.md)

| # | Change | Driver |
|---|---|---|
| Δ1 | **Check 65 is REGISTERED EARLY with EMPTY `_CHECK_65_OPERATING_DOCS` scope (passes vacuously at the gate-code group), then POPULATED to the full IN set in a FINAL gate-ACTIVATION group that runs LAST.** Every "C1 runs Check 65 green over the live tree" claim is REVISED: at the gate-code group Check 65 is present-but-empty-scope (vacuous green); the activation group is the FIRST point Check 65 enforces against the live tree (green because all strips have landed). | BLOCKER-1 = USER RULED Option A. Supersedes design §G "gate-verified as it lands" (never achievable — see §3). |
| Δ2 | **ADD 16 pack IN work-units: 11 `.claude/skills/*/SKILL.md` + 5 `.claude/agents/pack-*.md`.** 6 carry history (STRIP + BLOAT); the other 10 get BLOAT only. The pack `boundary-investigation/SKILL.md` and pack-startup history hits are added (distinct from the project copies + distinct from C2's Step-8 strip). | BLOCKER-2 (the prior plan's waves dropped these IN-set surfaces — design §A classifies them IN; spec lists them). |
| Δ3 | **The `pack-ops/OPTIONAL-FEATURES.md` L326 `` `pack tracker` `` verb-token strip is FOLDED INTO the nuclear work-unit/group** so Check 22 never sees an orphaned uncovered verb token. OPTIONAL-FEATURES' partition is re-derived: its tracker-section strip + remaining history/bloat strip are one green-atomic unit with the fragment deletion. | BLOCKER-3 (C2 was not green-atomic — Check 22 would fail C2..C6). |
| Δ4 | **ONE authoritative count stated** (work-unit count + commit-group count). The prior plan's "33" is dropped. | MINOR-1. |
| Δ5 | **Cross-surface commit-group SUBJECTS carry NO scope-keyword token** (the words `pack-only`/`project-only` must NOT appear in the subject — Check 36 token trap). Split-option prose removed from subject framing. | MINOR-2. |
| Δ6 | **Gate-code + activation verification assert live `--only-check 59` exit 0 after the count bump**, not just the integer label. | MINOR-3. |
| Δ7 | **The HYBRID work-unit/commit-group model** (this-BD-only, user-authorized deviation from per-commit-worktree): work-units are the parallel isolated-review units; commit-groups are the git rollup. §4 (work-units) + §5 (commit-groups) + §7 (orchestration). | USER RULING. |

**CARRIED from PLAN-BD-243.md (the adversarial verified these correct — do not re-litigate):** G1-G4 applied; the keyword assignments; trinity + tri-family serialization; the partition counts (37 skills, 10 prompts, 16×3 agents, 4 docs/pack IN, stream-meta); the nuclear ref counts (23 validate-pack HELP-FRAGMENT-TRACKER refs + 5 init-project logical hits); next-free check 65; Check-54 safety (C17/pack OPTIONAL-FEATURES tracker-section delete is Check-54-safe); the dormant-guard retention (29/35/51 untouched); the push/manifest plan.


---

## 2. AUTHORITATIVE COUNTS (one number each — MINOR-1)

Measured @ a847f12 (§EE). The COMMIT-GROUP count is the git-history rollup; the WORK-UNIT count is the parallel isolated-review fan.

**WORK-UNIT count = 91** (the smallest-independent-unit fan):

| Bucket | Work-units | Notes |
|---|---|---|
| Gate code (coupled set) | 1 | WU-GATE |
| Nuclear (coupled set) | 1 | WU-NUCLEAR |
| New rule (coupled set) | 1 | WU-RULE (pack trinity ×3 + RATIONALE + project trinity ×3 — one coupled unit; Check 45 + trinity ×2 force it together) |
| Pack-ops operating-doc strips | 8 | RATIONALE, MERGE-STRATEGY, OPTIONAL-FEATURES-residual, CONCEPTUAL-REVIEW, PACK-CHAT, PACK-AGENTS, DRY-RUN, BOUNDARY-DEFINITION (HELP-FRAGMENT-PACK handled in WU-NUCLEAR; HELP-FRAGMENT-TRACKER deleted) |
| Pack stream-meta `_rules` | 2 | backlog/_rules, changelog/_rules |
| Pack `_intro` (G1, EXEMPT-leak) | 1 | WU-PACK-INTRO (backlog/_intro + changelog/_intro — coupled, both pack `_intro`) |
| **Pack skills (BLOCKER-2)** | **11** | each `.claude/skills/*/SKILL.md` (6 STRIP+BLOAT, 5 BLOAT) |
| **Pack agents (BLOCKER-2)** | **5** | each `.claude/agents/pack-*.md` (0 history → BLOAT) |
| Pack-root trinity strip | (in WU-RULE? NO) 1 | WU-ROOT-TRINITY (the W3 strip; same files as WU-RULE → SERIAL after it; separate work-unit) |
| Project trinity strip | 1 | WU-PROJ-TRINITY (the W4 strip; same files as WU-RULE → SERIAL after it) |
| Project client-leak strips (distinct files) | 6 | OPTIONAL-FEATURES, PM-CHAT, prompts/auditor, prompts/coder, skills/pm-startup, skills/boundary-investigation (each folds leak + bloat) |
| Project `_intro` ×3 (EXEMPT-leak) | 1 | WU-PROJ-INTRO (3 files coupled — all project `_intro`) |
| Project agent-def tri-family roles | 16 | each role = `.claude/*.md` + `.codex/*.toml` + `.agents-plugin/*.md` (tri-family lock) |
| Project RUNTIME-SUBAGENT-PATTERN | 1 | standalone |
| Project skills (37 − 2 already in leak units pm-startup+boundary-investigation) | 35 | BLOAT (+ OQ-B audit-methodology `_v8-resolved-archive.md` ref fix) |
| Project docs/pack IN (4 − 2 already in leak units OPTIONAL-FEATURES+PM-CHAT) | 2 | PACK-FEEDBACK, PLATFORM-SKILLS |
| Project prompts (10 − 2 already in leak units auditor+coder) | 8 | architect, docs-researcher, grpc-schema, planner, pm-chat, repo-ops, reviewer, tester |
| Project stream-meta `_rules`/`_format` (NOT `_intro`) | 4 | backlog/_rules, changelog/_rules, changelog/_format, implementation-plan/_rules |
| **Gate ACTIVATION (Option A)** | **1** | WU-ACTIVATE (one-line `_CHECK_65_OPERATING_DOCS` population edit to validate-pack.py) |

Sum: 1+1+1+8+2+1+11+5+1+1+6+1+16+1+35+2+8+4+1 = **106**. (Re-tally below; the table mixes coupled-vs-single — the authoritative number is the line-sum.)

CORRECTED LINE-SUM = **106 work-units** (gate 1 + nuclear 1 + rule 1 + pack-ops 8 + pack `_rules` 2 + pack `_intro` 1 + pack skills 11 + pack agents 5 + root-trinity-strip 1 + proj-trinity-strip 1 + proj-leak 6 + proj `_intro` 1 + proj agent-roles 16 + RUNTIME-SUBAGENT 1 + proj skills 35 + proj docs/pack 2 + proj prompts 8 + proj stream-meta 4 + activation 1 = 106).

**AUTHORITATIVE WORK-UNIT COUNT = 106.** (Each = one isolated worktree + bounded review/fix cycle; distinct work-units run in parallel within a wave.)

**COMMIT-GROUP count = 14** (the git-history rollup; §5 defines each). Coupled work-units never split across groups; same-file work-units serialize into the same group.

NOTE on "33": the prior plan's "33" was a stale label (its own body computed ~89). It is DROPPED. The two authoritative numbers are **106 work-units / 14 commit-groups.** Pack Chat schedules off these, not "33".


---

## 3. THE GATE-ACTIVATION-LAST MECHANISM (Option A — BLOCKER-1 resolution)

**The contradiction resolved.** Design FINAL §G says "W0 + W1 run FIRST so every later strip wave is gate-verified as it lands"; design §E.5.4 says "Check 65 scans clean … after B.2 strips land." These cannot both hold for a FULL `validate-pack.py` run: the moment Check 65 is registered with a populated IN scope, a full run scans the still-unstripped IN docs (measured: PACK-MEMORY-RATIONALE 12 dates + 11 SHAs; CLAUDE.md 22 BD/date hits; 6 pack skills) and FAILS. **Design §G "gate-verified as it lands" is SUPERSEDED by Option A** — it was never achievable. The strips are enforced DURING the sweep by the reviewer (per-file clause-set-diff + grep-zero on the agreed history patterns), and the GATE enforces once, at activation.

**Option A — register-early / activate-last.**

1. **Gate-code group (FIRST commit-group, CG-01).** Adds, in one green-atomic group:
   - `check_operating_doc_no_history` (number 65) + its registry row + `CHECK_REGISTRY_EXPECTED_COUNT` 62→63 (Check 65 +1; Check-44 reduction +0 — §EE-3).
   - The Check-44 reduction (`_CHECK_44_FORBIDDEN_PATTERNS` → `(("will", …),)`; comment/docstring/fail-message rewrite; 5-surface per FINAL §E.1) + the MOVED date/SHA FAIL test cases into `test-validate-pack-check-65.sh`.
   - `pack-ops/.operating-doc-history-allowlist.txt` (NEW — K1-K11 sized exactly to the legitimate KEEP set).
   - `pack-ops/.concision-allowlist.txt` header → `will`-only.
   - `scripts/tests/test-validate-pack-check-44.sh` (keep T1/T3/T4/Group-0/Group-2; REMOVE T2-date + T5-SHA) + `scripts/tests/test-validate-pack-check-65.sh` (NEW: the MOVED T2-date + T5-SHA FAIL cases + K1-K11 PASS cases + a non-allowlisted-history FAIL case).
   - The CONCISION-GUARDRAILS MOVE addendum (history axis §6/Check 44 → Check 65), naming the realized consumer by file+symbol.
   - **`_CHECK_65_OPERATING_DOCS = ()` (EMPTY scope).** The gate is registered + tested but scans NOTHING → passes VACUOUSLY.
   - **CG-01 verification (REVISED):** `python3 scripts/validate-pack.py` exit 0 with Check 65 PRESENT-but-EMPTY-SCOPE (vacuous green); NOT asserted against the unstripped live tree. `python3 scripts/validate-pack.py --only-check 59` exit 0 reporting "63 entries == constant" (MINOR-3: assert the live `--only-check 59` exit, not just the integer). The check-44 + check-65 unit tests pass (the FAIL cases in check-65 assert FAIL via the test's own fixtures, which is independent of the empty live scope).

2. **All strip groups land** (CG-02 .. CG-13) — every history/leak/bloat strip across both surfaces. Check 65 remains VACUOUS (empty scope) throughout, so each strip group's full `validate-pack.py` run is green WITHOUT depending on Check 65. The reviewer enforces the strip per work-unit (clause-set-diff + grep-zero on the agreed patterns) — this is the substantive enforcement during the sweep.

3. **Gate-activation group (LAST commit-group, CG-14).** A ONE-LINE constant edit: POPULATE `_CHECK_65_OPERATING_DOCS` to the full corrected IN set (the ~136 design IN total = the measured operating-doc IN set, INCLUDING the 16 BLOCKER-2 pack docs). This is the FIRST point Check 65 enforces against the live tree.
   - **CG-14 green-proof (Option A's safety property).** By the time CG-14 applies, EVERY IN doc has been stripped clean (all strip groups landed) → Check 65 scans the populated IN set and finds ONLY the K1-K11 allowlisted KEEP tokens → exit 0. The activation group is green BECAUSE all strips precede it. CG-14 verification: full `validate-pack.py` exit 0 (Check 65 now ENFORCING, green); `--only-check 65` exit 0 over the live populated scope; `--only-check 59` exit 0 (count unchanged at 63 — activation is a scope-data edit, not a registry change).

**Scope-population is the corrected IN set.** `_CHECK_65_OPERATING_DOCS` is built from the MEASURED file set (not the design's prose names — G3), and includes the 16 BLOCKER-2 pack docs (11 skills + 5 agents). It EXCLUDES the 9 EXEMPT docs (5 `_intro` + 4 HELP-FRAGMENT) per design §A.

**Why Option A over B/C.** Option B (incremental scope grow) churns validate-pack repeatedly (many same-file serial commits to the gate). Option C (strip-then-add-gate) loses the gate during the strips and must add it last anyway. Option A (the user ruling) registers the gate's CODE + tests + allowlist FIRST (so the encoding surfaces land early and stay testable) but defers the ENFORCEMENT (scope population) to the end — minimal validate-pack churn (one constant edit at the end), green at every group.


---

## 4. WORK-UNIT PARTITION (the parallel isolated-worktree + bounded-review/fix units)

A WORK-UNIT is the SMALLEST INDEPENDENT unit: a single file, OR a coupled set that MUST be reviewed/edited together (trinity triple, tri-family role triple, the gate-code set, the nuclear set, the rule+rationale-bijection set). Each = one isolated worktree (`worktree.baseRef:"head"`) + fresh coder + the bounded ≤2-review/fix-+1-final cycle. The reviewer's per-file clause-set-diff + grep-zero happens HERE. Distinct work-units run in PARALLEL (sane wave width 4-6).

**Legend:** dep = work-units/groups that MUST precede; ax = axis (HIST=history strip, LEAK=deferred-feature mention, BLOAT=terseness only); coupling = files locked together in the unit.

### Phase A — foundation (serial; the spine)
| WU | Files (coupled) | ax | dep | Notes |
|---|---|---|---|---|
| **WU-GATE** | `scripts/validate-pack.py` (Check 44 reduction + Check 65 register, EMPTY scope + EXPECTED_COUNT 62→63) + `scripts/tests/test-validate-pack-check-44.sh` + `scripts/tests/test-validate-pack-check-65.sh` + `pack-ops/.concision-allowlist.txt` + `pack-ops/.operating-doc-history-allowlist.txt` (NEW) + `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` | (gate code) | none | empty `_CHECK_65_OPERATING_DOCS` → vacuous green. Coupled: check body ↔ its tests ↔ allowlists (enumerate-encoding-surfaces). |
| **WU-NUCLEAR** | DELETE `pack-ops/HELP-FRAGMENT-TRACKER.md` + `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`; EDIT `scripts/pack-help.sh`, `scripts/migrate-v10-to-v11.sh:301`, `scripts/init-project.sh` (L14/949-956/960-961/1260/1437 — §EE-7), `scripts/pack-tracker.sh`+`scripts/tracker-migrate.sh` (`# pack-internal: true`), `pack-ops/HELP-FRAGMENT-PACK.md` (drop tracker rows + section; relocate `pack td`), `project-template/docs/pack/HELP-FRAGMENT.md` (drop include marker + tracker rows; relocate client `pack td`), `scripts/validate-pack.py` (Checks 22/23/39/40/41/43 bodies + `_CHECK_44_DURABLE_DOCS` HELP-FRAGMENT-TRACKER row drop + HELP-FRAGMENT-PACK ceiling re-measure + install-map + BD-082/194 comment blocks), `scripts/tests/pack-help-test.sh` + check-22/23 fixtures, `.claude/skills/pack-startup/SKILL.md` (Step-8 deferred strip + reserved comment), **`pack-ops/OPTIONAL-FEATURES.md` L326 `` `pack tracker` `` verb-token strip (BLOCKER-3 — folded HERE)** | LEAK + nuclear | WU-GATE | ONE coupled work-unit (cross-cutting; Checks 22/23/39/40/41/43 couple the fragment delete to the install-map + allowlist edits). The L326 `pack tracker` token is the verb Check 22 would orphan → MUST strip in this same unit. NOTE: this strips ONLY OPTIONAL-FEATURES' `pack tracker` token here; its remaining tracker-SECTION + history/bloat strip is WU-OPTFEAT-PACK (serializes after, same file). |
| **WU-RULE** | pack-root `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (new rule + `[rationale: operating-docs-no-history-no-bloat]`) + `pack-ops/PACK-MEMORY-RATIONALE.md` (NEW `## operating-docs-no-history-no-bloat`) + project-template `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (audience-correct, NO `[rationale:]` tag — D.3) | (new rule) | WU-GATE | Coupled: Check 45 bijection forces pack-root rule slug + `## slug` in one unit; trinity ×2 locations force the 3+3 together. Literal `BD-NNN`/`YYYY-MM-DD` placeholders → self-safe vs Check 65. Verify live `--only-check 45` exit 0 before+after (G4). |

### Phase B — pack strips (parallel; distinct files; dep WU-GATE+WU-NUCLEAR+WU-RULE)
| WU | File | ax | Notes |
|---|---|---|---|
| WU-RATIONALE | `pack-ops/PACK-MEMORY-RATIONALE.md` | HIST+BLOAT | HEAVIEST; 23 BD + 12 dated → strip incidents/provenance, keep timeless Why+How + K2/K3/K4 doc-refs. (Same file as WU-RULE's RATIONALE edit → SERIALIZE after WU-RULE.) |
| WU-MERGE | `pack-ops/MERGE-STRATEGY.md` | HIST+BLOAT | 13 BD incl. Open BD-110/109 roadmap-mention strip. |
| WU-OPTFEAT-PACK | `pack-ops/OPTIONAL-FEATURES.md` | LEAK+HIST+BLOAT | Strip "## Tracker integration (deferred)" L309-333 section + BD-234/218/217/215/214 deferred-feature mentions + history. (The L326 `pack tracker` TOKEN already stripped in WU-NUCLEAR; same file → SERIALIZE after WU-NUCLEAR.) Check-54-safe (§EE — Check 54 asserts worktree/baseRef, not tracker). |
| WU-CONCEPTUAL | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | HIST+BLOAT | BD-110×5 future-migration scaffolding strip + rewrite to current methodology; BD-136 carry-over; provenance. |
| WU-PACKCHAT | `pack-ops/PACK-CHAT.md` | LEAK+HIST+BLOAT | BD-214 tracker L53/69-77/430-434 + P1/P3 provenance + L151 dated quote; KEEP K5/K6 doc-refs. |
| WU-PACKAGENTS | `pack-ops/PACK-AGENTS.md` | HIST+BLOAT | BD-226/225/203/198 provenance; KEEP K5. |
| WU-DRYRUN | `pack-ops/DRY-RUN-MIGRATION.md` | HIST+BLOAT | BD-125/114/088/042 provenance; `will` allowlist entries stay. |
| WU-BOUNDARYDEF | `pack-ops/BOUNDARY-DEFINITION.md` | BLOAT | 0 BD/0 dated; BLOAT axis only. |
| WU-BACKLOG-RULES | `backlog/_rules.md` | HIST+BLOAT | OQ-2=c v8 clause strip; OQ-FINAL-3 operative-only rewrite — BD-215/214/060/211/203 strip; KEEP BD-167 K7. |
| WU-CHANGELOG-RULES | `changelog/_rules.md` | HIST+BLOAT | BD-214 + BD-203 strip. |
| WU-PACK-INTRO | `backlog/_intro.md` + `changelog/_intro.md` (coupled — both pack `_intro`) | LEAK (G1) | Strip `backlog/_intro.md:19` tracker mention; changelog/_intro clean. EXEMPT from Check 65 → reviewer leak-check only. |

### Phase B2 — pack skills + agents (BLOCKER-2; parallel; distinct files; dep WU-GATE+WU-NUCLEAR+WU-RULE)
| WU | File | ax | history hits @ a847f12 (§EE-5) |
|---|---|---|---|
| WU-SKILL-boundary-investigation (PACK) | `.claude/skills/boundary-investigation/SKILL.md` | HIST+BLOAT | 2 (L32 BD-175, L160 BD-175). DISTINCT from project copy. |
| WU-SKILL-commit-discipline | `.claude/skills/commit-discipline/SKILL.md` | HIST+BLOAT | 1 (L112 BD-119 C-2 incident). |
| WU-SKILL-implementation-report | `.claude/skills/implementation-report/SKILL.md` | HIST+BLOAT | 1 (L142 BD-119 C-4). |
| WU-SKILL-pack-startup | `.claude/skills/pack-startup/SKILL.md` | HIST+BLOAT | 4 (L38 BD-203, L107 BD-237, L115 BD-237, L123 BD-214). NB L121-129 Step-8 deferred strip already in WU-NUCLEAR → same file → this WU SERIALIZES after WU-NUCLEAR and strips L38/L107/L115 + the remaining history/bloat. |
| WU-SKILL-review | `.claude/skills/review/SKILL.md` | HIST+BLOAT | 1 (L40 BD-185 worked example). |
| WU-SKILL-verification-harness | `.claude/skills/verification-harness/SKILL.md` | HIST+BLOAT | 3 (L85 BD-119, L212 BD-219, L237 BD-119). |
| WU-SKILL-architecture-review | `.claude/skills/architecture-review/SKILL.md` | BLOAT | 0 |
| WU-SKILL-dependency-intake | `.claude/skills/dependency-intake/SKILL.md` | BLOAT | 0 |
| WU-SKILL-documentation | `.claude/skills/documentation/SKILL.md` | BLOAT | 0 |
| WU-SKILL-pack-help | `.claude/skills/pack-help/SKILL.md` | BLOAT | 0 |
| WU-SKILL-planning | `.claude/skills/planning/SKILL.md` | BLOAT | 0 |
| WU-AGENT-pack-architect | `.claude/agents/pack-architect.md` | BLOAT | 0 |
| WU-AGENT-pack-coder | `.claude/agents/pack-coder.md` | BLOAT | 0 |
| WU-AGENT-pack-docs-researcher | `.claude/agents/pack-docs-researcher.md` | BLOAT | 0 |
| WU-AGENT-pack-planner | `.claude/agents/pack-planner.md` | BLOAT | 0 |
| WU-AGENT-pack-reviewer | `.claude/agents/pack-reviewer.md` | BLOAT | 0 |

NB Check 1 (SKILL frontmatter) is NEVER stripped in any WU-SKILL-*. The 6 history-bearing pack skills MUST be stripped before CG-14 activation (else Check 65 RED on them).


### Phase C — trinity strips (each serial-internal ×3; the two locations parallel to each other; dep WU-RULE)
| WU | Files (coupled ×3) | ax | dep |
|---|---|---|---|
| WU-ROOT-TRINITY | pack-root `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` | HIST+LEAK+BLOAT | WU-RULE (SAME files → SERIAL after WU-RULE) |
| WU-PROJ-TRINITY | project-template `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` | LEAK+BLOAT | WU-RULE (SAME files → SERIAL after WU-RULE) |

WU-ROOT-TRINITY: P2/P3 provenance strip + §0 deferred-feature mentions (tracker BD-214; BD-217/233 cross-CLI worktree; BD-218/241/225/226 tags) + OQ-3 carve-out rewrites + C.2 clause-preserving structural conversion; KEEP K1 (until BD-206), K2 (ARCHITECTURE-BD-119), K3 (ARCHITECTURE-BD-182). WU-PROJ-TRINITY: strip the 6-site tracker deferred-feature passages → "Flat-file per-entry is the sole supported mode."; structural bloat reduction. WU-ROOT-TRINITY ∥ WU-PROJ-TRINITY (different file sets).

### Phase D — project client-leak strips (parallel; distinct files; dep WU-GATE+WU-NUCLEAR+WU-RULE; each folds LEAK + BLOAT on that file)
| WU | File | ax | Notes |
|---|---|---|---|
| WU-OPTFEAT-PROJ | `project-template/docs/pack/OPTIONAL-FEATURES.md` | LEAK+BLOAT | L-6: strip "## Tracker integration (deferred)" L321-335; Check-54-safe (verify). |
| WU-PMCHAT-PROJ | `project-template/docs/pack/PM-CHAT.md` | LEAK+BLOAT | L-7: strip deferred-tracker L714/718/793/796; keep live flat-file directive. |
| WU-PROMPT-auditor | `project-template/docs/pack/prompts/auditor.md` | LEAK+BLOAT | L-8: strip L51 parenthetical. |
| WU-PROMPT-coder | `project-template/docs/pack/prompts/coder.md` | LEAK+BLOAT | L-9: strip L68-69 deferred clause; KEEP the live "Deferred items"/TD-TBD L25-26/94-141/211-249. |
| WU-SKILL-pm-startup (PROJECT) | `project-template/skills/pm-startup/SKILL.md` | LEAK+BLOAT | L-10: strip L85 deferred clause + Step-7 reserved comment L209-216 + "## Step 8 (deferred)" L217-225; last live step = Step 6. |
| WU-SKILL-boundary-investigation (PROJECT) | `project-template/skills/boundary-investigation/SKILL.md` | LEAK+BLOAT | L-14: REWRITE example set to drop refs to the deleted HELP-FRAGMENT-TRACKER L106-114 + deferred-tracker example; coordinate with Check-40/43 allowlists (edited in WU-NUCLEAR). dep ADDS WU-NUCLEAR. DISTINCT from the pack copy. |
| WU-PROJ-INTRO | `project-template/docs/project/{backlog,changelog,implementation-plan}/_intro.md` (coupled ×3) | LEAK (G1-class) | L-11: strip the 3-line deferred-tracker block each; keep "flat-file is the sole supported mode"; gate-EXEMPT but client-shipped → reviewer leak-check, NOT Check 65. |

### Phase E — project agent-defs (tri-family serial per role; roles parallel; dep WU-GATE+WU-NUCLEAR+WU-RULE)
| WU (16 roles) | Files (coupled ×3 per role) | ax |
|---|---|---|
| WU-AGENTDEF-<role> ×16 | `project-template/.claude/agents/<role>.md` + `.codex/agents/<role>.toml` + `.agents-plugin/optiquity-agents/agents/<role>.md` | BLOAT |
| WU-RUNTIME-SUBAGENT | `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` | BLOAT (standalone) |

The 16 role names are enumerated at coder-spawn from `ls project-template/.claude/agents/*.md`. Project agent-def history-provenance = 0 → BLOAT only; VERIFY L-17 ("Deferred items" report-section = live TD workflow) KEPT identically ×3. These ARE in Check-65 IN scope (activated at CG-14) but carry no history → no Check-65 hit expected.

### Phase F — project skills + docs/pack + prompts + stream-meta (parallel; distinct files; dep WU-GATE+WU-NUCLEAR+WU-RULE)
| WU bucket | Files | count | ax |
|---|---|---|---|
| WU-SKILL-<name> (project) | `project-template/skills/<skill>/SKILL.md` (37 − pm-startup − boundary-investigation already in Phase D) | 35 | BLOAT (incl. OQ-B `audit-methodology/SKILL.md:76` `_v8-resolved-archive.md` ref fix) |
| WU-DOCSPACK-<name> | `project-template/docs/pack/PACK-FEEDBACK.md`, `…/PLATFORM-SKILLS.md` (OPTIONAL-FEATURES + PM-CHAT already in Phase D) | 2 | BLOAT |
| WU-PROMPT-<name> | `project-template/docs/pack/prompts/{architect,docs-researcher,grpc-schema,planner,pm-chat,repo-ops,reviewer,tester}.md` (auditor+coder already in Phase D) | 8 | BLOAT |
| WU-STREAMMETA-<name> | `project-template/docs/project/backlog/_rules.md`, `…/changelog/_rules.md`, `…/changelog/_format.md` (K9/K10 date examples allowlisted — do NOT strip), `…/implementation-plan/_rules.md` (NOT `_intro` — EXEMPT) | 4 | HIST+BLOAT |

**No double-touch invariant.** Each file gets EXACTLY ONE work-unit. The 8 files that appear in BOTH a leak/nuclear unit AND the bloat universe (pack OPTIONAL-FEATURES, pack-startup, project OPTIONAL-FEATURES, project PM-CHAT, project auditor, project coder, project pm-startup, project boundary-investigation) fold leak+bloat into their single work-unit; the bloat-only phases exclude them. WU-RATIONALE serializes after WU-RULE (same file); WU-OPTFEAT-PACK + WU-SKILL-pack-startup serialize after WU-NUCLEAR (same files).


---

## 5. COMMIT-GROUP PARTITION (the git-history rollup)

A COMMIT-GROUP collects reviewed-clean work-unit PATCHES and applies them as ONE grouped commit. **Grouping rules:** (i) coupled work-units stay in ONE group (never split); (ii) each group is GREEN when applied (full `validate-pack.py` exit 0 + tests; Check 65 vacuous until CG-14); (iii) Check-36 scope per the group's COMBINED file set — a cross-surface group carries NO keyword token in the subject; (iv) sequence: gate-code FIRST → nuclear → rule → strip groups → gate-ACTIVATION LAST; (v) thematic/by-scope grouping for a sensible history.

**14 commit-groups.** Sequence is strict for the spine (CG-01→CG-02→CG-03) and for trinity-vs-rule (CG-08/CG-09 after CG-03) and for CG-14 LAST. Strip groups CG-04..CG-13 have no inter-group dependency (distinct files) — order among them is free.

| CG | Theme | Work-units | Combined scope (Check 36) | Subject keyword | Sequence | Green-verification |
|---|---|---|---|---|---|---|
| **CG-01** | Gate code (Check 44 reduction + Check 65 register, empty scope) | WU-GATE | pack-only (validate-pack.py + tests + allowlists + maintenance-docs; `_CHECK_65_OPERATING_DOCS` references project paths only as DATA strings — Check 36 uses `git show --name-only`, data doesn't count) | `pack-only` | 1 (FIRST) | full validate-pack exit 0 (Check 65 vacuous); check-44 + check-65 tests; `--only-check 59` exit 0 = 63 |
| **CG-02** | Nuclear pack-help tracker strip | WU-NUCLEAR | CROSS-SURFACE (pack `scripts/`+`pack-ops/`+`.claude/` AND `project-template/docs/pack/`) | **NONE (neutral)** — no `pack-only`/`project-only` token in subject | 2 | full validate-pack exit 0 (esp. 22/23/39/40/41/43/44-durable/47/51/54); pack-help-test; test-migrate ×4; test-init-project |
| **CG-03** | New governance rule ×6 trinity + RATIONALE bijection | WU-RULE | CROSS-SURFACE (pack-root trinity + RATIONALE + project-template trinity) | **NONE (neutral)** | 3 | full validate-pack exit 0 (esp. 45/16/18/19); `--only-check 45` exit 0 before+after (G4) |
| **CG-04** | Pack-ops operating-doc strips | WU-RATIONALE, WU-MERGE, WU-OPTFEAT-PACK, WU-CONCEPTUAL, WU-PACKCHAT, WU-PACKAGENTS, WU-DRYRUN, WU-BOUNDARYDEF | pack-only | `pack-only` | after CG-01/02/03 | full validate-pack exit 0; Check 44 `will`/advisory |
| **CG-05** | Pack stream-meta `_rules` + pack `_intro` | WU-BACKLOG-RULES, WU-CHANGELOG-RULES, WU-PACK-INTRO | pack-only | `pack-only` | after CG-01/02/03 | full validate-pack exit 0 |
| **CG-06** | Pack skills strip+bloat | WU-SKILL-* (11 pack skills) | pack-only | `pack-only` | after CG-01/02/03 (WU-SKILL-pack-startup after CG-02) | full validate-pack exit 0 (Check 1 frontmatter intact) |
| **CG-07** | Pack agent-defs bloat | WU-AGENT-* (5 pack agents) | pack-only | `pack-only` | after CG-01/02/03 | full validate-pack exit 0 (Check 11 informational) |
| **CG-08** | Pack-root trinity strip | WU-ROOT-TRINITY | pack-only | `pack-only` | after CG-03 (same files as WU-RULE) | full validate-pack exit 0 (16/18/19/45) |
| **CG-09** | Project trinity strip | WU-PROJ-TRINITY | project-only | `project-only` | after CG-03 (same files as WU-RULE); ∥ CG-08 | full validate-pack exit 0 (16/18/19) |
| **CG-10** | Project client-leak strips (docs/pack + prompts + skills) | WU-OPTFEAT-PROJ, WU-PMCHAT-PROJ, WU-PROMPT-auditor, WU-PROMPT-coder, WU-SKILL-pm-startup, WU-SKILL-boundary-investigation, WU-PROJ-INTRO | project-only | `project-only` | after CG-01/02/03 (boundary-investigation after CG-02) | full validate-pack exit 0 (esp. 54 for OPTFEAT; 40/43 for boundary) |
| **CG-11** | Project agent-defs bloat (tri-family) | WU-AGENTDEF-<role> ×16 + WU-RUNTIME-SUBAGENT | project-only | `project-only` | after CG-01/02/03 | full validate-pack exit 0 (tri-family parity; L-17 KEEP ×3) |
| **CG-12** | Project skills bloat | WU-SKILL-<name> ×35 | project-only | `project-only` | after CG-01/02/03 | full validate-pack exit 0 (Check 1; OQ-B ref fix) |
| **CG-13** | Project docs/pack + prompts + stream-meta bloat | WU-DOCSPACK-* ×2 + WU-PROMPT-* ×8 + WU-STREAMMETA-* ×4 | project-only | `project-only` | after CG-01/02/03 | full validate-pack exit 0 (K9/K10 date examples NOT stripped) |
| **CG-14** | **Gate ACTIVATION (Option A)** — populate `_CHECK_65_OPERATING_DOCS` to the full IN set | WU-ACTIVATE | pack-only (one-line validate-pack.py constant edit) | `pack-only` | **LAST** (after ALL strip groups) | **full validate-pack exit 0 with Check 65 ENFORCING green; `--only-check 65` exit 0 over live populated scope; `--only-check 59` exit 0 = 63 (unchanged)** |

**Grouping rationale.** Pack vs project split keeps Check-36 keywords clean (CG-04..08/14 pack-only; CG-09..13 project-only). CG-02/CG-03 are inherently cross-surface (nuclear touches both; the rule lives on both trinities) → NEUTRAL subject (no keyword token — MINOR-2). Coupled work-units (WU-GATE, WU-NUCLEAR, WU-RULE, each trinity ×3, each tri-family role ×3, WU-PACK-INTRO ×2, WU-PROJ-INTRO ×3) are never split. Thematic grouping (pack-ops / pack-skills / pack-agents / trinity / project-leak / project-agents / project-skills / project-docs) gives a readable history. CG-14 is the SOLE point Check 65 enforces — green because all strips precede it.

**Subject-token-trap guard (MINOR-2, binding on the orchestrator).** CG-02/CG-03 commit SUBJECTS must contain NO scope-keyword token. The literal strings `pack-only` and `project-only` must NOT appear anywhere in those two subjects (Check 36 parses the subject — a denying token wins). Use neutral framing, e.g. `feat: v11 — BD-243 nuclear pack-help tracker strip (cross-surface)` and `feat: v11 — BD-243 anti-bloat governance rule + RATIONALE bijection (cross-surface)`. The pack-only/project-only groups MAY carry their keyword (it matches their file set).


---

## 6. PARALLEL-vs-DEPENDENT SCHEDULE (rule-10 → the waves Pack Chat executes)

Work-units run in PARALLEL within a wave (distinct files); commit-groups roll up the reviewed-clean patches. Serialization: (a) trinity ×3 serialize internally; (b) tri-family ×3 per role serialize internally; (c) same-file work-units serialize; (d) WU-GATE/WU-NUCLEAR/WU-RULE are the serial spine; (e) CG-14 LAST.

| Stage | Work-units (parallel within stage) | → Commit-group(s) | Why |
|---|---|---|---|
| **S1 (spine, serial)** | WU-GATE | CG-01 | gate code must land first |
| **S2 (spine, serial)** | WU-NUCLEAR | CG-02 | cross-cutting; deletes fragment + edits 6 checks + strips the `pack tracker` token; must precede strip waves; dep WU-GATE |
| **S3 (spine, serial)** | WU-RULE | CG-03 | Check-45 bijection atomic; dep WU-GATE |
| **S4 (parallel — pack strips)** | WU-RATIONALE (after WU-RULE), WU-MERGE, WU-OPTFEAT-PACK (after WU-NUCLEAR), WU-CONCEPTUAL, WU-PACKCHAT, WU-PACKAGENTS, WU-DRYRUN, WU-BOUNDARYDEF, WU-BACKLOG-RULES, WU-CHANGELOG-RULES, WU-PACK-INTRO, 11 pack skills (pack-startup after WU-NUCLEAR), 5 pack agents | CG-04, CG-05, CG-06, CG-07 | distinct pack files; dep spine |
| **S5 (parallel — trinity + project leak)** | WU-ROOT-TRINITY (after WU-RULE), WU-PROJ-TRINITY (after WU-RULE), WU-OPTFEAT-PROJ, WU-PMCHAT-PROJ, WU-PROMPT-auditor, WU-PROMPT-coder, WU-SKILL-pm-startup, WU-SKILL-boundary-investigation (after WU-NUCLEAR), WU-PROJ-INTRO | CG-08, CG-09, CG-10 | trinity same-file-as-WU-RULE forces post-CG-03; the two trinity sets differ → parallel; leak strips distinct files → parallel |
| **S6 (parallel — agent defs)** | WU-AGENTDEF-<role> ×16 (each tri-family-serial internally) + WU-RUNTIME-SUBAGENT | CG-11 | distinct role files; tri-family lock WITHIN each role-unit |
| **S7 (parallel — skills + docs/pack + prompts + stream-meta)** | 35 project skills + 2 docs/pack + 8 prompts + 4 stream-meta | CG-12, CG-13 | highest parallelism; same-file already excluded |
| **S8 (spine, serial — LAST)** | WU-ACTIVATE | CG-14 | populate Check-65 scope; first + only point Check 65 enforces; green because all strips landed |

**Concurrency.** S4/S6/S7 are large fans. Pack Chat schedules them in BATCHES of a sane wave width (4-6 concurrent worktrees) — distinct-file work-units MAY co-run; same-file work-units NEVER co-schedule. Within S4/S6/S7 ordering is free (no inter-unit dependency). Cross-stage ordering is STRICT for the spine (S1→S2→S3) and S8 LAST.

---

## 7. ORCHESTRATION — bounded review/fix per work-unit + patch-collect → group-apply → group-verify → commit

**This-BD-only HYBRID deviation note.** Per the user ruling, the per-commit-worktree default is deviated for BD-243 ONLY: the bounded review/fix cycle binds to the WORK-UNIT (not the grouped commit); reviewed-clean work-unit PATCHES are collected and applied as GROUPED commits. Safety properties are preserved (each work-unit is reviewed clean in its own isolated worktree before its patch is emitted; each group is verified green BEFORE its commit). What changes: the commit-rollup is decoupled from the work-unit. Because work-units are DISTINCT files, patches do not conflict; a work-unit based at an earlier HEAD applies cleanly to an advanced HEAD (its file is untouched by other groups). User-authorized; this-BD-only.

**Per WORK-UNIT (the bounded cycle — rule 4, rule 5):**
1. Pack Chat spawns a FRESH coder in an ISOLATED worktree (`isolation:"worktree"`, `worktree.baseRef:"head"`) for the work-unit. The coder edits the work-unit's coupled file(s) ONLY; runs the FULL `validate-pack.py` battery + the relevant per-check/integration tests IN the worktree; emits PREFLIGHT only after all in-scope edits + verification PASS.
2. Pack Chat spawns a FRESH RO reviewer in THAT worktree (cd in + verify pwd/HEAD). Reviewer does the per-file clause-set-diff (`git show HEAD:<file>` vs post-edit — set-equality modulo flagged padding, NO behavior change) + grep-zero on the agreed history patterns + each surviving KEEP token re-verified live-and-current + each deferred-feature mention confirmed gone (P-DEF — reviewer-enforced, not regex-able).
3. Bounded: ≤2 review/fix pairs + 1 final reviewer = MAX 3 reviewer / 2 fix-coder spawns per work-unit. Fix-coders REUSE the same worktree. If still dirty after the final reviewer, STOP — spawn `pack-architect` to diagnose (no fix-coder pass 3).
4. PATCH ONLY after the reviewer confirms CLEAN: Pack Chat SendMessage-s the most-recent read-write agent to `git diff > <handoff>/<wu-name>.patch` at THAT point. Nothing reaches the canonical tree mid-cycle.
5. The work-unit's worktree is removed ONLY after ITS GROUP's commit is CONFIRMED landed (exit 0). A failed group-commit KEEPS the worktrees as recovery fallback. Live-worktree ASK gate (rule 9): the commit's own reviewer/fix-coder is rule-fixed to the worktree (no ask); any OTHER agent spawned while a live worktree with uncommitted work exists ⇒ Pack Chat ASKS the user BOTH placement AND disposition.

**Per COMMIT-GROUP (the rollup):**
6. Pack Chat collects the group's reviewed-clean work-unit patches.
7. Pack Chat applies them to the CANONICAL tree (orchestrator applies — agents never commit/apply). Distinct-file patches apply cleanly even if based at an earlier HEAD.
8. Pack Chat runs the FULL `validate-pack.py` battery + the group's relevant tests on the COMBINED result. Check 65 is vacuous until CG-14; CG-14's run is the enforcing one. The group MUST be green.
9. Pack Chat commits the group with USER APPROVAL (one commit per group; subject per the Check-36 keyword in §5; CG-02/CG-03 carry NO keyword token). Agents never commit.

**Verification at both levels (verify-full-ci-suite, rule 8).** Per work-unit: full validate-pack battery + relevant per-check/integration tests in the worktree. Per group: full validate-pack battery + the group's tests on the combined canonical-tree result before commit. The per-group run is the authoritative green gate (it catches any cross-work-unit interaction the isolated worktrees could not see — though distinct files make interaction unlikely).


---

## 8. CROSS-DOC CONSISTENCY LOCKSTEP

1. **Trinity parity ×2 locations.** pack-root CLAUDE/AGENTS/GEMINI: the new rule (WU-RULE/CG-03) + the strip (WU-ROOT-TRINITY/CG-08) each touch all 3 in ONE work-unit. project-template CLAUDE/AGENTS/GEMINI: the new rule (WU-RULE/CG-03) + the strip (WU-PROJ-TRINITY/CG-09) each touch all 3 in ONE work-unit. Reviewer asserts byte-parallel rule expression at each location.
2. **Tri-family agent-def lock (16 roles).** Each WU-AGENTDEF-<role> touches `.claude/agents/<role>.md` + `.codex/agents/<role>.toml` + `.agents-plugin/optiquity-agents/agents/<role>.md` in ONE work-unit (→ CG-11). Reviewer asserts identical substance ×3 (L-17 KEEP verified ×3).
3. **Check 45 rule↔rationale bijection.** The new rule's pack-root `[rationale: operating-docs-no-history-no-bloat]` ×3 + its `## operating-docs-no-history-no-bloat` in RATIONALE land in ONE work-unit (WU-RULE/CG-03). Verified by `--only-check 45` exit 0 (G4: live gate, not the design's "26↔26" literal).
4. **Encoding-surface pairs (rippled checks ↔ their tests) — same work-unit/group.** WU-GATE/CG-01: Checks 44/65 bodies + `test-validate-pack-check-44.sh` + `test-validate-pack-check-65.sh`. WU-NUCLEAR/CG-02: Checks 22/23/39/40/41/43/44-durable bodies + `pack-help-test.sh` + check-22/23 fixtures + `test-migrate*` + `test-init-project`. Asymmetric coverage (check body edited without its test) = defect → reviewer blocks.
5. **CONCISION-GUARDRAILS reconciliation.** WU-GATE/CG-01 appends the MOVE addendum (history axis §6/Check 44 → Check 65) naming the realized consumer by file+symbol (`check_operating_doc_no_history`/Check 65) — architect-doc-reality-reconciliation.
6. **`_CHECK_44_DURABLE_DOCS` ↔ deleted fragment.** WU-NUCLEAR/CG-02 drops the HELP-FRAGMENT-TRACKER row (file deleted) AND re-measures the HELP-FRAGMENT-PACK ceiling after its tracker rows leave (same work-unit).
7. **Check-65 scope ↔ the IN file set.** WU-ACTIVATE/CG-14 populates `_CHECK_65_OPERATING_DOCS` to the MEASURED IN set including the 16 BLOCKER-2 pack docs; excludes the 9 EXEMPT docs. The activation is the lockstep point where the gate's scope matches the swept-clean tree.

---

## 9. PLANNER-TO-CODER GATE

**This plan goes to the USER for review/approval BEFORE ANY pack-coder spawns.** No coder is spawned on planner authority. The user may comment, add constraints, or request structural changes. Pack Chat waits for explicit approval before spawning the WU-GATE coder (the S1 spine). The planner-to-coder gate is the user's last cheap window to redirect before implementation consumes agent time + chat context. G1-G4 are already ruled; no decision is pending — but the user retains hard-stop authority over the plan and every scheduled stage.

---

## 10. PUSH / MANIFEST PLAN (orchestrator post-implementation; NOT a coder/per-group chore)

BD-243 changes `project-template/` fixture INPUTS (trinity, docs/pack, skills, prompts, agent defs, stream-meta, the deleted client HELP-FRAGMENT-TRACKER). Per regenerate-manifest-v11-surface, `test-fixtures/manifest.txt` is regenerated PUSH-TIME, NOT per-commit/per-group:
- After ALL 14 commit-groups land green locally and BEFORE `git push`, the ORCHESTRATOR (Pack Chat) runs `bash scripts/manifest-sync.sh`. Expect **exit 10** (a fixture input changed → manifest regenerated). Pack Chat commits the regenerated `test-fixtures/manifest.txt` with user approval (a bookkeeping commit), THEN `git push`.
- CI enforces correctness: `build.sh --verify` + validate-pack **Check 62** (manifest_structural) fail the gate if the manifest is stale. No per-commit/per-group manifest regen.
- The deleted client HELP-FRAGMENT-TRACKER.md is a fixture INPUT removal → the manifest regen reflects its absence; the install-map edit (WU-NUCLEAR) keeps Check 41/62 consistent.
- After push: watch the `Validate Pack` GitHub Actions workflow in the BACKGROUND; surface the verdict. Do NOT foreground-block on CI.

Agents never push/regen-manifest/commit; this section is the ORCHESTRATOR's procedure, stated for completeness.


---

## 11. EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery FIRST (`graphify-out/graph.json`, built 2026-06-20); STALE for BD-243-era surfaces → G2 fallback to grep/Read/git for every exact-state claim (EE-2). Re-measured per the charge: the 16 pack IN docs + their history hits (BLOCKER-2); the OPTIONAL-FEATURES `pack tracker` token (BLOCKER-3); the activation-last green proof (Option A); the authoritative work-unit + commit-group counts.

**EE-1 — runtime HEAD = BD-243 commit; clean tree.** Cmd `git rev-parse HEAD; git rev-parse --abbrev-ref HEAD; git status --short`. Output `a847f120e4ada06456bec4e2bf6d275fdd8c0742` ; `v11-dev` ; (empty). Interpretation: at the BD-243 HEAD, nothing staged/dirty. Conclusion: **SUPPORTED.**

**EE-2 — graph STALE for BD-243; G2 fallback exercised.** Cmd `graphify query "BD-243 operating doc strip check 65 activation commit sequence pack skills" --graph .../graph.json --backend claude-cli --budget 1500`. Output (verbatim, first nodes): `NODE Implementation Report BD-048 …`, `NODE PACK-REVIEW-BD-194 …`, `NODE IMPL-REPORT BD-190 …`, `NODE IMPL-REPORT BD-200 C2 fix-1 …` — all unrelated to BD-243's commit sequencing. Interpretation: graph stale/unhelpful for BD-243 discovery → fell through to grep/Read/git IMMEDIATELY (no block). Conclusion: **SUPPORTED** (graph-first attempted, fallback correct; QUERY-only, never built).

**EE-3 (Option A / MINOR-3) — next-free check = 65; live registry = 62 → 63 after Check 65 (+1); Check-44 reduction is +0.** Cmd `grep -oE "^\s*\(6[0-9], \"check_" scripts/validate-pack.py | tail` → highest registered `(64, …`; `grep -n "CHECK_REGISTRY_EXPECTED_COUNT = "` → `500:CHECK_REGISTRY_EXPECTED_COUNT = 62`; `python3 scripts/validate-pack.py --only-check 59` → `OK: Check 59 — CHECK_REGISTRY has 62 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT)`. Interpretation: next-free NUMBER = 65; live registry = 62 (Check 59's own count, authoritative — a raw `grep -cE` of registration tuples returns 60 due to multi-line formatting, NOT a discrepancy); EXPECTED_COUNT bumps 62→63 (Check 65 +1; Check 44 is a pattern-tuple reduction = +0 registry). CG-01/CG-14 assert live `--only-check 59` exit 0 = 63 (MINOR-3). Conclusion: **SUPPORTED.**

**EE-4 (BLOCKER-2) — 16 pack IN docs exist (11 skills + 5 agents).** Cmd `ls -1 .claude/skills/*/SKILL.md | wc -l` → `11`; `ls -1 .claude/agents/pack-*.md | wc -l` → `5`. Skills: architecture-review, boundary-investigation, commit-discipline, dependency-intake, documentation, implementation-report, pack-help, pack-startup, planning, review, verification-harness. Agents: pack-architect, pack-coder, pack-docs-researcher, pack-planner, pack-reviewer. Interpretation: design §A classifies all 16 IN; spec line 18 lists them; the prior plan's waves dropped them → BLOCKER-2 fix adds 16 work-units. Conclusion: **SUPPORTED.**

**EE-5 (BLOCKER-2) — 6 of the 16 carry history hits the gate flags; 10 carry 0.** Cmd `for f in .claude/skills/*/SKILL.md .claude/agents/pack-*.md; do n=$(grep -cE "20[0-9]{2}-[0-9]{2}-[0-9]{2}|\bBD-[0-9]+|\b[0-9a-f]{7,40}\b|per BD-" "$f"); echo "$n  $f"; done`. Output (verbatim, nonzero): `2 boundary-investigation` (L32 BD-175, L160 BD-175); `1 commit-discipline` (L112 BD-119 C-2 incident); `1 implementation-report` (L142 BD-119 C-4); `4 pack-startup` (L38 BD-203, L107 BD-237, L115 BD-237, L123 BD-214); `1 review` (L40 BD-185); `3 verification-harness` (L85 BD-119, L212 BD-219, L237 BD-119). All 5 pack agents = 0. Interpretation: the 6 history-bearing skills get HIST+BLOAT (CG-06) — MUST strip before CG-14 (else Check 65 RED on them); the rest get BLOAT. pack-startup's L121-129 Step-8 strip is in WU-NUCLEAR; its L38/L107/L115 history are NOT touched by that strip → WU-SKILL-pack-startup (serializing after WU-NUCLEAR) handles them. The pack boundary-investigation copy is DISTINCT from the project copy. Conclusion: **SUPPORTED.**

**EE-6 (BLOCKER-3) — `pack-ops/OPTIONAL-FEATURES.md` L326 carries `` `pack tracker` `` (a non-script verb token), in the Check-22 prose doc set.** Cmd `grep -nE '`pack tracker`' pack-ops/OPTIONAL-FEATURES.md` → `326:`pack tracker` flip verbs refuse with a deferred message). Resumption is gated`. Cmd reading Check 22 body (`scripts/validate-pack.py` L2056-2132): the pack-root prose doc set = `pack-ops/PACK-CHAT.md`, `QUICKSTART.md`, `pack-ops/OPTIONAL-FEATURES.md`, `supporting-docs/INSTALL-PROCEDURES.md`; `frag_text = frag.read_text() + tracker_frag.read_text()` (L2090); the script-existence filter (L2105-2123) applies ONLY to `scripts/`-prefixed or `.sh`/`.py` tokens — `` `pack tracker` `` is neither, so it is added to `verbs_referenced` UNCONDITIONALLY (L2124); `missing = sorted(v for v in verbs_referenced if v not in frag_text)` (L2125). Interpretation: after WU-NUCLEAR removes the tracker rows from HELP-FRAGMENT-PACK (and deletes the tracker fragment), `` `pack tracker` `` is absent from `frag_text` → Check 22 FAILS unless the L326 token is stripped in the SAME work-unit. Other Check-22 pack docs (PACK-CHAT, QUICKSTART, INSTALL-PROCEDURES) + project PM-CHAT carry NO `pack tracker` verb token (measured — clean). BLOCKER-3 fix folds the L326 strip into WU-NUCLEAR. Conclusion: **SUPPORTED.**

**EE-7 (carried, re-verified) — nuclear strip touches 23 validate-pack HELP-FRAGMENT-TRACKER refs + 5 init-project logical sites.** Cmd (prior plan + adversarial, re-checked): `grep -c "HELP-FRAGMENT-TRACKER" scripts/validate-pack.py` → 23; `grep -n "HELP-FRAGMENT-TRACKER" scripts/init-project.sh` → L14, 949-956, 960-961, 1260, 1437. Interpretation: WU-NUCLEAR's scope is materially broad (Checks 22/23/39/40/41/43/44 + comment blocks + install-map; init-project copy block + assertion + install-map row + header comment + cmd_update). Conclusion: **SUPPORTED** (carried from PLAN-BD-243 EE-P3; adversarial confirmed exact).

**EE-8 — project IN-set counts (commit-group partition).** Cmd `ls -1 … | wc -l`: project skills `37`; project prompts `10`; `.claude/agents` `16`, `.codex/agents` `16`, `.agents-plugin/…/agents` `16`. `ls project-template/docs/pack/*.md` → 6 files of which 2 are HELP-FRAGMENT{,-TRACKER} (EXEMPT) → 4 operating IN (OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT). Stream-meta: 4 `_rules`/`_format` IN (backlog/_rules, changelog/_rules, changelog/_format, implementation-plan/_rules) + 3 `_intro` EXEMPT. Interpretation: CG-11 = 16 roles ×3 + RUNTIME-SUBAGENT; CG-12 = 35 skills (37−2); CG-13 = 2 docs/pack + 8 prompts + 4 stream-meta. Conclusion: **SUPPORTED.**

**EE-9 (G3, re-verified) — project docs/pack operating IN = 4; METHODOLOGY/INSTALL-PROCEDURES/SETUP-EXISTING absent there.** Cmd `find project-template/docs/pack -type f -name "*.md"` → the 6 above; `find project-template -iname "*METHODOLOGY*" …` → only `project-template/skills/audit-methodology/`. Interpretation: the design's "(6)" docs/pack label is corrected to the 4 real operating files; no recipe affected. Conclusion: **SUPPORTED.**

**EE-10 (carried) — Check 54 = `check_optional_features_presence`, not tracker → C17/WU-OPTFEAT tracker-section delete is Check-54-safe.** Cmd `grep -nE "\(54," scripts/validate-pack.py` → `(54, "check_optional_features_presence",`. Interpretation: Check 54 asserts the worktree/baseRef OPTIONAL-FEATURES section, not the tracker section → deleting the tracker section (WU-OPTFEAT-PACK + WU-OPTFEAT-PROJ) is Check-54-safe; the coder VERIFIES Check 54 green post-edit. Conclusion: **SUPPORTED.**

**EE-11 (authoritative counts) — 106 work-units / 14 commit-groups.** Derivation (§2 line-sum): gate 1 + nuclear 1 + rule 1 + pack-ops 8 + pack `_rules` 2 + pack `_intro` 1 + pack skills 11 + pack agents 5 + root-trinity-strip 1 + proj-trinity-strip 1 + proj-leak 6 + proj `_intro` 1 + proj agent-roles 16 + RUNTIME-SUBAGENT 1 + proj skills 35 + proj docs/pack 2 + proj prompts 8 + proj stream-meta 4 + activation 1 = **106**. Commit-groups CG-01..CG-14 = **14** (§5). Interpretation: the prior plan's "33" is dropped; Pack Chat schedules off 106/14. Conclusion: **SUPPORTED.**

---

## 12. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **reconciliation-instance-independence** | FRESH reconciliation instance; did NOT author `PLAN-BD-243.md`; am NOT the adversarial reviewer (`ADVERSARIAL-REVIEW-PLAN-BD-243.md`). Folded the 3 BLOCKERs + 3 MINORs + the binding user rulings (BLOCKER-1 = Option A activation-last; the hybrid work-unit/commit-group model). Carried the adversarial-verified-correct content (G1-G4, keyword assignments, serialization, partition counts, nuclear refs 23+5, Check-54 safety, dormant-guard retention, manifest plan). Re-measured every load-bearing claim at HEAD a847f12 (§EE). No challenge to the rulings — they are adopted as binding. | COMPLIANT |
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD`, `git rev-parse --abbrev-ref HEAD`, `git status --short` (read-only). Sole write = this plan doc via `cat >>` to `/tmp/pack-handoff-bd243-plan/PLAN-BD-243-FINAL.md`. No repo-file edit; no patch; no state-changing git verb; no OptiquityTrader write. The one `python3 scripts/validate-pack.py --only-check 59` run is a read-only check invocation (no state change). | COMPLIANT |
| **empirical-evidence-blocks [planner]** | §11 EE-1..EE-11: each = command + verbatim output + HEAD `a847f12` + 2026-06-21 + interpretation + SUPPORTED. RE-MEASURED per charge: the 16 pack IN docs + history hits (EE-4/EE-5, BLOCKER-2); the OPTIONAL-FEATURES `pack tracker` token + Check-22 mechanism (EE-6, BLOCKER-3); the activation-last green proof — registry 62→63 + Check-65 empty-then-populate (EE-3 + §3, Option A); the authoritative counts 106/14 (EE-11). | COMPLIANT |
| **bounded-review-fix-cycle** | §7 binds the cycle to the WORK-UNIT (per the hybrid): ≤2 review/fix pairs + 1 final reviewer = max 3 reviewer / 2 fix-coder per work-unit; fix-coders REUSE the worktree; architect escalation if dirty after final (no fix-coder pass 3); patch only after reviewer-clean. | COMPLIANT |
| **worktree-isolation model** | §6 + §7: each work-unit = one ISOLATED worktree (`isolation:"worktree"`, `baseRef:"head"`); first coder creates, fix-coders reuse; whole review/fix cycle inside it; patch only after reviewer-clean. The hybrid DEVIATION (this-BD-only, user-authorized) decouples the commit-rollup from the work-unit — stated explicitly in §7 with safety properties preserved; distinct-file patches apply cleanly to an advanced HEAD. Teardown only after the GROUP's commit confirmed landed; live-worktree ASK gate (rule 9) restated; §6 is the parallel-vs-dependent map (rule 10) Pack Chat consumes. | COMPLIANT |
| **enumerate-encoding-surfaces** | §8 + §4: coupled work-units stay together AND in one group — gate code↔both tests↔both allowlists (WU-GATE/CG-01); nuclear 6-check-bodies↔pack-help-test↔fixtures↔migrate↔init-project (WU-NUCLEAR/CG-02); trinity ×2 (WU-RULE+WU-ROOT/PROJ-TRINITY); tri-family ×16 roles (WU-AGENTDEF); rule↔rationale bijection (WU-RULE). BLOCKER-2's 16 pack IN docs added as the missed encoding surface class; BLOCKER-3's Check-22 doc-set coupling (OPTIONAL-FEATURES `pack tracker`) folded into WU-NUCLEAR. Asymmetric coverage = reviewer-blocked defect. | COMPLIANT |
| **commit-subject-scope-keyword (Check 36)** | §5: CG-01/CG-04..08/CG-14 = `pack-only` (pack files only; Check 36 uses `git show --name-only`, data strings in `_CHECK_65_OPERATING_DOCS` don't count); CG-09..13 = `project-only` (project files only); CG-02 (nuclear) + CG-03 (rule) = CROSS-SURFACE → **NEUTRAL subject, NO keyword token** (MINOR-2 subject-token-trap guard binding on the orchestrator — the literal `pack-only`/`project-only` must NOT appear in those subjects). | COMPLIANT |
| **verify-full-ci-suite** | §7 step 1 (per work-unit) + step 8 (per group): the FULL `validate-pack.py` battery (all checks) + the relevant integration/per-check tests (CG-02 → pack-help-test + test-migrate ×4 + test-init-project; CG-01 → check-44 + check-65 + `--only-check 59`; CG-03 → `--only-check 45`; CG-14 → `--only-check 65` + `--only-check 59`). The per-group run on the combined canonical-tree result is the authoritative green gate. | COMPLIANT |
| **regenerate-manifest-v11-surface** | §10: manifest regen is PUSH-TIME (`scripts/manifest-sync.sh`, expect exit 10), orchestrator-run, NOT per-commit/per-group; CI `build.sh --verify` + Check 62 enforce; explicitly flagged NOT a coder task. | COMPLIANT |
| **graph-first-context** | Discovery query attempted FIRST (EE-2) via the injected absolute `--graph` path verbatim, `--backend claude-cli`, `--budget 1500`, QUERY-only (never built); graph STALE (BD-048/194/190/200 nodes) → G2 fallback to grep/Read/git IMMEDIATELY for every exact-state claim (no block). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |

**END — PLAN-BD-243-FINAL.md (authoritative; supersedes PLAN-BD-243.md)**

---

## ADDENDUM A — (a)-RULING: `HELP-FRAGMENT-TRACKER.md` name must not survive in operating surfaces (Pack-Chat orchestration record, 2026-06-21)

**Origin.** During the CG-02/WU-NUCLEAR cycle the fix-coder surfaced a teach-vs-enforce drift: WU-NUCLEAR removed `HELP-FRAGMENT-TRACKER` from `_DENY_LIST_FILENAMES` (and deletes both `HELP-FRAGMENT-TRACKER.md` copies), but several boundary/teaching operating docs still cite the filename — in BOUNDARY-DEFINITION.md as a *current pack-ops operating doc*, classifying a now-deleted artifact as in-use. **User ruling = (a):** scrub the name from the operating surfaces — "The name shouldn't exist anywhere, especially not in a way that classifies it as a current document that's in use." This deliberately diverges from the BD-203 precedent (which retained such teaching references).

**CG-02 is NOT reopened.** Empirically verified: full `validate-pack.py` is GREEN in worktree `agent-a76d57f82cb9154d0` (CG-02 state, base eec6727) with these refs still present — no check scans them, so they are NOT a gate dependency. The **no-double-touch invariant** also forbids touching these files in CG-02: each is owned by a later WU. The (a) scrubs therefore land in their OWNING work-units, ADDED to the scopes already planned:

| File | Owning WU / CG | Existing planned scope | (a) ADDITION |
|---|---|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md` (L43, C2 inventory) | WU-BOUNDARYDEF / CG-04 | BLOAT only | **+ remove `pack-ops/HELP-FRAGMENT-TRACKER.md` from the C2 operating-doc inventory** (it no longer exists; do not relist it) |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (L38) | WU-CONCEPTUAL / CG-04 | BD-110×5 + provenance strip | **+ remove `pack-ops/HELP-FRAGMENT-TRACKER.md` from the project-side-surface review list** |
| `pack-ops/PACK-MEMORY-RATIONALE.md` (L173, L524-525) | WU-RATIONALE / CG-04 | HIST+BLOAT (heaviest) | **+ scrub the `HELP-FRAGMENT-TRACKER.md` mentions** (L173 inventory-removal note; L524-525 fixture-input prose) — keep timeless meaning, drop the dead filename |
| pack `boundary-investigation/SKILL.md` (L100-101, L108) — **ALL 3 tracked pack copies: `.agents/`, `.claude/`, `.codex/`** | WU-SKILL-boundary-investigation (PACK) / CG-06 | 2 BD-175 history hits (L32, L160) | **+ rewrite the L100-108 example set to drop the deleted `HELP-FRAGMENT-TRACKER.md` refs** (mirror the CG-10 project-copy rewrite; keep parity across the 3 pack copies) |
| project `boundary-investigation/SKILL.md` (L106-114) | WU-SKILL-boundary-investigation (PROJECT) / CG-10 | **already planned** (line 178: REWRITE example set to drop HELP-FRAGMENT-TRACKER refs) | none — already covered |

**OUT of (a) scope (KEEP — not operating docs):** `maintenance-docs/**` (history/audit records), `backlog/BD-*.md` + `changelog/v11.md` (work-item records). These legitimately record the artifact that existed; they do not classify it as currently in-use.

**CG-02 scripts/ assert-absent tests (judgment call → user gate).** WU-NUCLEAR's 4 test/contract files (`contract-greenfield.sh`, `contract-migration.sh`, `test-init-project.sh`, `test-migrate-v10-to-v11.sh`) assert the file is **NOT installed** ("deleted, BD-243"). The literal name appears, but in a deletion-guard that states the OPPOSITE of in-use. These are sanctioned WU-NUCLEAR design (regression coverage that the deletion took effect), self-consistent, CI-green. Retained as designed; surfaced to the user at the CG-02 commit gate as the single judgment call (keep deletion-guards vs remove every textual occurrence). Not reopened pre-emptively.

**END ADDENDUM A**
