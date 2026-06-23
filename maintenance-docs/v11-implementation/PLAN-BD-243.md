# PLAN — BD-243: strip history/audit + deferred-feature MENTIONS + bloat from operating docs; NUCLEAR pack-help tracker strip + client-facing leak census; add anti-bloat governance rule

Planner: pack-planner (RO). Runtime HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. BD-243 confirmed at this HEAD (clean tree).
Authoritative inputs: `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL-V2.md` (supersedes) + carried §B/§C/§D/§E/§F/§G/§H of `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL.md` + `/backlog/BD-243.md` spec. This plan IMPLEMENTS the design; it does not redesign it.

This plan turns the 8 design waves (W0, W-NUCLEAR, W1, W2, W3, W4/W-LEAK, W5, W6) into 33 concrete commits with a parallel-vs-dependent worktree schedule, per-commit verification, the bounded review/fix cycle, the cross-doc lockstep, and the push/manifest plan.

---

## 0. OPEN QUESTIONS FOR USER / DESIGN-GAPS

These are surfaced (not silently filled). G1/G2 are carried architect OQs the planner cannot self-rule; G3/G4 are planner-found state discrepancies (resolved with evidence, surfaced for transparency).

**G1 (carried — OQV2-1) — pack-INTERNAL EXEMPT `_intro` deferred mention: strip or keep?**
`backlog/_intro.md:19` "Tracker (GH Issues) integration is deferred (BD-214)" is gate-EXEMPT (orientation doc) and pack-internal (never ships) → the leak axis does NOT force it. Architect RECOMMENDS strip (self-consistency with the new rule); degrades cleanly if user keeps it. **Plan default (absent ruling):** STRIP, scheduled in W2-pack-intro commit. USER: confirm STRIP vs KEEP.

**G2 (carried — OQV2-2 / OQV2-2a) — tracker-script `# pack-internal: true` + the `pack td` relocation.**
Architect RECOMMENDS: mark `pack-tracker.sh` + `tracker-migrate.sh` `# pack-internal: true` (so Check 23 stops requiring them in help output; dormant code stays); do NOT mark `pack-td.sh` (live feature); RELOCATE the `pack td` rows out of the deleted HELP-FRAGMENT-TRACKER into HELP-FRAGMENT-PACK + client HELP-FRAGMENT.md. **Plan default (absent ruling):** apply OQV2-2a as written, in W-NUCLEAR. USER: confirm (alternative is hide `pack td` too, or keep `pack tracker` rows — both degrade cleanly).

**G3 (planner-found, evidence-based — NOT a blocker) — design's "Project docs/pack/*.md (6)" count-label is inaccurate.**
DESIGN-BD-243-FINAL §A.50 names the project docs/pack operating set as "METHODOLOGY, INSTALL-PROCEDURES, PM-CHAT, PLATFORM-SKILLS, PACK-FEEDBACK, OPTIONAL-FEATURES" (6). MEASURED @ a847f12: `project-template/docs/pack/*.md` = exactly 6 FILES, of which 2 are HELP-FRAGMENT{,-TRACKER} (reclassified EXEMPT in FINAL-V2) → only **4 operating IN docs**: OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT. **METHODOLOGY / INSTALL-PROCEDURES / SETUP-EXISTING do NOT exist at `project-template/docs/pack/`** (`find` returned only `project-template/skills/audit-methodology/`). The leak census (L-6=OPTIONAL-FEATURES, L-7=PM-CHAT) and W6's docs/pack edits reference only the 4 real files, so NO strip recipe is affected — this is a count-label error in the IN-set tally, not a recipe error. **Plan uses the measured 4 docs/pack IN files.** The corrected total IN count (~136) is unaffected in direction; the planner flags it so the Check-65 `_CHECK_65_OPERATING_DOCS` frozen list is built from the MEASURED file set, not the design's prose names. USER: no action needed; surfaced for accuracy.

**G4 (planner-found, evidence-based — NOT a blocker) — Check-45 bijection baseline is NOT "26↔26" as the design states.**
DESIGN §D.4 / §F state the current bijection balance is "26↔26 → 27↔27" after the new rule. MEASURED @ a847f12: `grep -cE "\[rationale: " CLAUDE.md` = **27**; `grep -cE "^## [a-z0-9-]+\s*$" pack-ops/PACK-MEMORY-RATIONALE.md` = **26**. The raw greps differ from Check 45's exact extraction (Check 45 scans `[rationale: slug]` tokens INSIDE `## Pack memory` only, and de-dupes), so the literal "26↔26" is a design approximation, not the live Check-45 state. **Plan instruction:** the W1 coder MUST NOT trust the "26↔26→27↔27" literal; it runs `validate-pack.py --only-check 45` and asserts EXIT 0 both before (baseline) and after (new rule + its `## slug`). The mechanism (rule slug + matching `## slug` land in ONE commit) is correct regardless of the baseline integer. USER: no action needed; surfaced so W1's verification is against the live gate, not the design number.

**No other design gaps.** OQ-FINAL-1/2/3, CORRECTION A/B, the leak census, the nuclear spec, and the gate changes are internally consistent and state-verified (see Empirical-Evidence Block §8).

---

## 1. PLANNER-TO-CODER GATE (mandatory, stated up front)

**This plan goes to the USER for review/approval BEFORE ANY pack-coder spawns.** No coder is spawned on planner authority. The user may comment, add constraints, request structural changes, or rule G1/G2. Pack Chat waits for explicit approval (and rulings on G1/G2) before spawning the W0 coder. The planner-to-coder gate is the user's last cheap window to redirect before implementation consumes agent time + chat context.


---

## 2. CONCRETE COMMIT SEQUENCE (ordered; deps + scope-keyword + file set)

33 commits in 8 waves. Each commit is a coherent unit that lands green atomically (validate-pack exit 0 + the relevant integration/per-check tests). Scope-keyword per CI Check 36: a commit touching BOTH `project-template/` and pack paths must NOT claim an exclusive keyword (`pack-only`/`project-only`) — it carries NO keyword (neutral cross-surface framing) OR is split into clean pack-only + project-only commits. Atomic-spine commits are flagged.

Legend: **dep** = commits that MUST precede; **scope** = Check-36 keyword.

### Wave W0 — the gate (atomic, FIRST)
**C1 — Check 44 reduction + Check 65 (new) + EXPECTED_COUNT 62→63.** ATOMIC, ONE commit.
- Files: `scripts/validate-pack.py` (reduce `_CHECK_44_FORBIDDEN_PATTERNS`→`(("will", …),)`; add `check_operating_doc_no_history` (65) + registry row; `CHECK_REGISTRY_EXPECTED_COUNT` 62→63; rewrite Check-44 comment/docstring/fail-message; build `_CHECK_65_OPERATING_DOCS` frozen list from the MEASURED ~136 IN set per G3); `scripts/tests/test-validate-pack-check-44.sh` (keep T1/T3/T4/Group-0/Group-2; REMOVE T2-date + T5-SHA); `scripts/tests/test-validate-pack-check-65.sh` (NEW — incl. the MOVED T2-date + T5-SHA FAIL cases + the K1-K11 allowlist-PASS cases); `pack-ops/.concision-allowlist.txt` (header→`will`-only; 6 `will` records unchanged); `pack-ops/.operating-doc-history-allowlist.txt` (NEW — K1-K11 sized exactly); `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` (MOVE addendum).
- dep: none (FIRST).
- scope: **pack-only** (no `project-template/` path; `_CHECK_65_OPERATING_DOCS` references project paths as DATA strings inside a pack file — no project FILE is edited).
- Note: builds the gate the later strip waves are verified against. Lands BEFORE any strip.

### Wave W-NUCLEAR — pack-help tracker strip (atomic, runs with/just after W0)
**C2 — nuclear pack-help tracker strip (cross-cutting).** ATOMIC, ONE commit.
- Files (DELETE): `pack-ops/HELP-FRAGMENT-TRACKER.md`; `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`.
- Files (EDIT, pack-side): `scripts/pack-help.sh` (rip the tracker-include path — N.1.3); `scripts/migrate-v10-to-v11.sh:301` (drop from copy loop); `scripts/init-project.sh` (drop the S11 copy block L949-956 + the `fail_stage S11` assertion L960-961 + the install-map row L1260 + the header comment L14 + the cmd_update mapping L1437 — ALL HELP-FRAGMENT-TRACKER hits, see EE-P3); `scripts/pack-tracker.sh` + `scripts/tracker-migrate.sh` (add `# pack-internal: true`); `pack-ops/HELP-FRAGMENT-PACK.md` (drop L21 "(… / tracker)"→"(install / migrate)", L30 pack-tracker row, L32 tracker-migrate row, the whole "## Tracker commands (deferred)" L34-36; KEEP pack-td row; RELOCATE "## TD promotion (v11+)" in from the deleted fragment); `scripts/validate-pack.py` (Checks 22/23/39/40/41/43 body edits + drop the `_CHECK_44_DURABLE_DOCS` HELP-FRAGMENT-TRACKER row L7802 + re-measure the HELP-FRAGMENT-PACK ceiling L7801 + the install-map row L5475 + the BD-082/BD-194 comment blocks L66/L70/L2046/L2053/L2327-2328); `.claude/skills/pack-startup/SKILL.md` (STRIP the reserved 6-7 HTML comment + the "## Step 8 (deferred)" L121-129 — N.4 pack side).
- Files (EDIT, project-side): `project-template/docs/pack/HELP-FRAGMENT.md` (drop the include marker + any `pack tracker` rows; RELOCATE the client `pack td` rows in).
- Files (TEST): `scripts/tests/pack-help-test.sh` (assert tracker section ABSENT from `pack help` output on BOTH surfaces; assert `pack td` rows PRESENT); any check-22/23 test fixtures.
- dep: C1 (Check 65 must exist; W0 first per design sequencing note). May combine with C1 if the user prefers a single foundational commit, but kept separate here for review clarity. C2 MUST precede the trinity/leak strip waves (it deletes the fragment the L-14 boundary refs + Check 40/43 allowlists point at, and its Check-22/23 body edits must be in place before any prose tracker-verb strip).
- scope: **NEUTRAL cross-surface** (touches BOTH pack paths `scripts/`+`pack-ops/`+`.claude/` AND `project-template/docs/pack/`). MUST NOT carry `pack-only`/`project-only`. SPLIT-OPTION: a clean split is possible (pack-only commit C2a = pack fragment delete + scripts + validate-pack + pack-startup; project-only commit C2b = client HELP-FRAGMENT-TRACKER delete + client HELP-FRAGMENT.md edit). HOWEVER the design flags W-NUCLEAR as ONE atomic commit because validate-pack Checks 41/43 (client-installed-files / project-side-bare-internal-refs) couple the client fragment delete to the pack-side install-map + allowlist edits — splitting risks a transiently-red intermediate (C2a green but C2b's client delete leaves Check 41's install-map referencing a gone file until C2a, or vice versa). **Plan recommendation: keep C2 ATOMIC + NEUTRAL** (no keyword) to preserve green-at-every-commit; if the user wants the keyword discipline, the planner's split-order is C2a (pack, incl. the install-map row removal) THEN C2b (client delete) — but this needs the install-map edit to tolerate the client file still present, which it does (removing an install-map row before the file is deleted is benign). Default: ATOMIC NEUTRAL.


### Wave W1 — the new governance rule (atomic)
**C3 — new rule ×6 trinity + RATIONALE `## slug` bijection.** ATOMIC, ONE commit.
- Files: pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (the D.1 rule in `## Pack memory`→`### Repo conventions`, WITH `[roles:][rationale:operating-docs-no-history-no-bloat]` tags); `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (under `## Document locations`, audience-correct, NO `[rationale:]` tag — D.3 asymmetry); `pack-ops/PACK-MEMORY-RATIONALE.md` (NEW `## operating-docs-no-history-no-bloat` section — terse, literal placeholders only).
- dep: C1 (Check 65 must exist so the new rule's literal `BD-NNN`/`YYYY-MM-DD` placeholders are verified self-safe against it). Independent of C2. Runs before/with the strip waves.
- scope: **NEUTRAL cross-surface** (pack-root trinity + RATIONALE are pack paths; `project-template/` trinity is project paths). MUST NOT claim exclusive. SPLIT-OPTION: NOT cleanly splittable — Check 45 bijection requires the pack-root rule slug AND its `## slug` in ONE commit (else Check 45 FAILs mid-sequence), and the trinity rule requires the 3 project-template files in the SAME commit as each other. The pack-root-trinity+RATIONALE half could be a pack-only commit and the project-template-trinity half a project-only commit (Check 45 only governs the pack side), BUT the design treats W1 as ONE atomic commit (the rule is one logical unit ×2 locations). **Plan recommendation: keep C3 ATOMIC + NEUTRAL.** Alternative if keyword discipline wanted: C3a pack-only (pack trinity + RATIONALE, Check 45 self-contained) + C3b project-only (project trinity). Default: ATOMIC NEUTRAL.

### Wave W2 — pack history-heavy strip (PARALLEL across distinct files)
Each is its own commit (distinct file → parallel worktree). All **pack-only** scope. dep: C1+C2+C3 (gate + nuclear + rule must precede; Check 65 verifies each as it lands; C2 already handled the HELP-FRAGMENT-PACK tracker rows).
- **C4 — `pack-ops/PACK-MEMORY-RATIONALE.md`** (HEAVIEST/surgical; 23 BD + 12 dated → strip incidents/provenance, keep timeless Why + How-to-apply + K2/K3/K4 doc-refs). pack-only.
- **C5 — `pack-ops/MERGE-STRATEGY.md`** (13 BD incl. Open BD-110/109 roadmap-mention strip). pack-only.
- **C6 — `pack-ops/OPTIONAL-FEATURES.md`** (7 BD incl. the "## Tracker integration (deferred)" L309-333 section strip + BD-234/218/217/215/214 deferred-feature mentions). pack-only.
- **C7 — `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`** (BD-110×5 future-migration scaffolding strip + rewrite to current methodology; BD-136 carry-over; provenance). pack-only.
- **C8 — `pack-ops/PACK-CHAT.md`** (BD-214 tracker L53/69-77/430-434 + P1/P3 provenance + the L151 dated quote; KEEP K5/K6 doc-refs). pack-only.
- **C9 — `pack-ops/PACK-AGENTS.md`** (BD-226/225/203/198 provenance; KEEP K5). pack-only.
- **C10 — `pack-ops/DRY-RUN-MIGRATION.md`** (BD-125/114/088/042 provenance; `will` allowlist entries stay). pack-only.
- **C11 — `pack-ops/BOUNDARY-DEFINITION.md`** (0 BD/0 dated — BLOAT axis only, 135 lines under ceiling). pack-only.
- **C12 — `backlog/_rules.md`** (OQ-2=c whole v8 clause strip; OQ-FINAL-3 `_rules` operative-only rewrite — BD-215/214/060/211/203 strip; KEEP BD-167 K7). pack-only.
- **C13 — `changelog/_rules.md`** (BD-214 + BD-203 strip). pack-only.
- **C14 — pack `_intro` ×2 (G1) — `backlog/_intro.md` + `changelog/_intro.md`** (strip the `_intro` tracker mention pending G1 confirmation; EXEMPT from Check 65 → reviewer leak-check, not gate). pack-only. **CONDITIONAL on G1=STRIP.**

NOTE: HELP-FRAGMENT-PACK's tracker rows were stripped in C2 (W-NUCLEAR); W2 does NOT re-touch it. If a light P1 history strip on HELP-FRAGMENT-PACK is still wanted it folds into C2 (same file, must serialize) — the planner folds it into C2 to avoid a same-file second commit.

### Wave W3 — root-trinity strip + bloat (atomic trinity commit)
**C15 — pack-root CLAUDE/AGENTS/GEMINI strip + structural conversion.** ATOMIC trinity (3 files).
- Files: pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`. Content: P2/P3 provenance strip (BD-226/225/203/241/218/182-doc-ref-KEEP etc.) + §0 deferred-feature mentions (tracker BD-214; BD-217/233 cross-CLI worktree; BD-218/241/225/226 tags) + OQ-3 carve-out rewrites (drop "pre-2026-05-15 batches only" + "was the pre-2026-05-16 pattern…") + C.2 clause-preserving structural conversion of mega-rules; KEEP K1 (until BD-206), K2 (ARCHITECTURE-BD-119), K3 (ARCHITECTURE-BD-182).
- dep: C1+C2+C3. Same files as C3 (pack-root trinity) → MUST serialize after C3 (same-file constraint).
- scope: **pack-only**.

### Wave W4 / W-LEAK — project trinity + client-facing leak strip
**C16 — project-template CLAUDE/AGENTS/GEMINI tracker passages (L-1/2/3) + structural reduction.** ATOMIC trinity (3 files).
- Files: `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`. Content: strip the 6-site tracker deferred-feature passages → state only "Flat-file per-entry is the sole supported mode."; structural bloat reduction.
- dep: C1+C2+C3. Same files as C3 (project trinity) → MUST serialize after C3.
- scope: **project-only**.

The other client leak strips run PARALLEL (distinct files), all **project-only**, dep C1+C2+C3:
- **C17 — `project-template/docs/pack/OPTIONAL-FEATURES.md`** (L-6: strip the "## Tracker integration (deferred)" L321-335 section; Check-54-safe — Check 54 asserts the worktree/baseRef section, NOT tracker; VERIFY). project-only.
- **C18 — `project-template/docs/pack/PM-CHAT.md`** (L-7: strip deferred-tracker L714/718/793/796; keep live flat-file directive). project-only.
- **C19 — `project-template/docs/pack/prompts/auditor.md`** (L-8: strip the L51 parenthetical). project-only.
- **C20 — `project-template/docs/pack/prompts/coder.md`** (L-9: strip the L68-69 deferred-tracker clause; KEEP the "Deferred items"/TD-TBD live feature L25-26/94-141/211-249). project-only.
- **C21 — `project-template/skills/pm-startup/SKILL.md`** (L-10: strip L85 deferred clause + Step-7 reserved comment L209-216 + the whole "## Step 8 (deferred)" L217-225; keep live step flow; last live step = Step 6 — N.4). project-only.
- **C22 — project `_intro` ×3 — `project-template/docs/project/{backlog,changelog,implementation-plan}/_intro.md`** (L-11: strip the 3-line deferred-tracker block on each; keep "flat-file is the sole supported mode"; gate-EXEMPT but client-shipped → leak axis → reviewer-verified). project-only.
- **C23 — `project-template/skills/boundary-investigation/SKILL.md`** (L-14: REWRITE the example set to drop refs to the now-deleted HELP-FRAGMENT-TRACKER L106-114 + the deferred-tracker example; keep the boundary methodology; coordinate with Check-40/43 allowlists already edited in C2). project-only. dep ADDS C2 (the fragment must be deleted + the allowlists edited first).


### Wave W5 — project bloat: agent defs (tri-family serial per role, PARALLEL across roles)
16 roles × 3 families (`.claude/agents/*.md` + `.codex/agents/*.toml` + `.agents-plugin/optiquity-agents/agents/*.md`) = 48 files + RUNTIME-SUBAGENT-PATTERN.md. Each ROLE = ONE commit touching its 3 family files in lockstep (tri-family lock). Roles run PARALLEL (distinct role files). All **project-only**. dep: C1+C2+C3.
- **C24..C39 (16 commits, one per role)** — for each of the 16 roles: terseness/structural bloat reduction across `.claude/agents/<role>.md` + `.codex/agents/<role>.toml` + `.agents-plugin/optiquity-agents/agents/<role>.md` in ONE commit (tri-family lock). VERIFY L-17 ("Deferred items" report-section = live TD workflow) KEPT identically across all 3 family files. project-only.
- **C40 — `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`** — terseness (single file, not tri-family). project-only.

(The 16 role names are enumerated at coder-spawn time from `ls project-template/.claude/agents/*.md`; project-side history-provenance = 0 (EE-12), so W5 is the BLOAT axis only — no Check-65 history hits expected; Check 65 does not scan agent-def history because there is none.)

### Wave W6 — project bloat: skills + docs/pack + prompts + stream-meta (PARALLEL)
All **project-only**. dep: C1+C2+C3. Same-file edits serialize (none cross here). Distinct files → high parallelism.
- **C41..C77 (37 commits, one per skill)** — `project-template/skills/<skill>/SKILL.md` terseness (Check 1 frontmatter NEVER stripped). Includes OQ-B: `audit-methodology/SKILL.md` strip/correct the `:76` `_v8-resolved-archive.md` non-existent-file ref. project-only. (boundary-investigation already handled in C23 → excluded here to avoid same-file double commit; pm-startup already handled in C21 → excluded; so the W6 skill count is 37 − 2 already-touched = 35 NEW skill commits; the 2 touched skills are NOT re-committed in W6.)
- **C78..C81 (4 commits) — project docs/pack operating IN docs (G3-corrected set)** — `OPTIONAL-FEATURES.md` (already C17 → excluded), `PM-CHAT.md` (already C18 → excluded), `PACK-FEEDBACK.md`, `PLATFORM-SKILLS.md`. So NEW W6 docs/pack commits = **2** (PACK-FEEDBACK, PLATFORM-SKILLS); OPTIONAL-FEATURES + PM-CHAT bloat folds into their leak commits C17/C18 (same file). project-only.
- **C82..C89 (8 commits) — project prompts (the 10 minus auditor+coder already in C19/C20)** — architect, docs-researcher, grpc-schema, planner, pm-chat, repo-ops, reviewer, tester (8 NEW). project-only.
- **C90..C93 (4 commits) — project stream-meta `_rules`/`_format` (NOT `_intro` — EXEMPT)** — `docs/project/backlog/_rules.md`, `docs/project/changelog/_rules.md`, `docs/project/changelog/_format.md` (K9/K10 date examples allowlisted — do NOT strip), `docs/project/implementation-plan/_rules.md`. project-only.

**Commit-count reconciliation (no double-touch):** the leak/nuclear waves (C17/C18/C19/C20/C21/C23) already touch 6 files that ALSO appear in the W6 bloat universe (OPTIONAL-FEATURES, PM-CHAT, auditor, coder, pm-startup, boundary-investigation). Per the same-file-serialize rule each file gets exactly ONE commit: its leak strip + its bloat reduction fold into the SAME commit (the coder for C17/C18/C19/C20/C21/C23 does BOTH the leak strip AND the terseness pass on that file). W6 therefore commits only the NOT-yet-touched files. Total distinct-file commits = 33 logical commit-IDs above (C1..C93 with the excluded ranges collapsed): W0(1)+W-NUCLEAR(1)+W1(1)+W2(11, C14 conditional)+W3(1)+W4/W-LEAK(8)+W5(17)+W6(35 skills + 2 docs/pack + 8 prompts + 4 stream-meta = 49). The C-numbering above is illustrative of the file partition; the EXECUTABLE commit list is the wave→file partition in §3, which Pack Chat schedules.

---

## 3. PARALLEL-vs-DEPENDENT WORKTREE SCHEDULE (rule-10 → concrete waves Pack Chat executes)

Serialization constraints (design §G): (a) trinity sets (3 files) serialize within a location; (b) tri-family agent sets (3 files/role) serialize per role; (c) same-file edits serialize; (d) the atomic spine W0/W-NUCLEAR/W1 are each ONE commit. RW coders run in an ISOLATED worktree per commit (the first coder of a commit CREATES it; fix-coders REUSE it); the whole review/fix cycle runs INSIDE that worktree; the patch is produced ONLY after a reviewer confirms clean. `worktree.baseRef:"head"` so the worktree bases at local HEAD.

### Scheduling timeline (waves are sequential; commits WITHIN a parallel wave run concurrently in separate worktrees)

| Stage | Commits | Parallel? | Why serial / why parallel |
|---|---|---|---|
| **S1 (spine, serial)** | C1 (W0) | serial | gate must land first |
| **S2 (spine, serial)** | C2 (W-NUCLEAR) | serial | cross-cutting; deletes fragment + edits 6 checks; must precede strip/leak waves; depends on C1 |
| **S3 (spine, serial)** | C3 (W1 rule) | serial | Check-45 bijection atomic; depends on C1 |
| **S4 (parallel wave — pack strip)** | C4..C13 (+C14 if G1=STRIP) — W2 | PARALLEL | distinct pack files; depends on S1+S2+S3 |
| **S5 (parallel wave — trinity bottlenecks + client leak)** | C15 (W3 pack trinity), C16 (W4 project trinity), C17..C23 (W-LEAK) | C15 + C16 each serial-internally (trinity ×3 atomic); the leak strips C17..C23 PARALLEL with each other AND with C15/C16 (distinct files). BUT C15 + C16 each touch the SAME trinity files as C3 → MUST run AFTER C3 (already S3). C15 and C16 touch DIFFERENT locations (pack-root vs project-template) → C15 ∥ C16 OK. | trinity same-file-as-C3 forces post-C3; the two trinity commits are different file sets → parallel to each other; leak strips are distinct files → parallel |
| **S6 (parallel wave — agent defs)** | W5: 16 role commits (each tri-family-serial internally) + RUNTIME-SUBAGENT | PARALLEL across the 16 roles + the 1 standalone (17 concurrent worktrees max; Pack Chat caps concurrency to a sane wave width) | distinct role files; tri-family lock is WITHIN each role-commit |
| **S7 (parallel wave — skills + docs/pack + prompts + stream-meta)** | W6: 35 skills + 2 docs/pack + 8 prompts + 4 stream-meta | PARALLEL (distinct files) | highest parallelism; same-file already excluded (C17/18/19/20/21/23 fold leak+bloat) |

**Concurrency note.** S6 and S7 are large parallel fans (17 and ~49 worktrees). Pack Chat schedules them in BATCHES of a manageable wave width (the rule does not mandate all-at-once; it mandates distinct-file commits MAY run concurrently). A practical wave width (e.g. 4-6 concurrent worktrees) keeps the bounded review/fix cycle tractable per commit. Same-file commits NEVER co-schedule.

**Cross-wave ordering is STRICT for the spine (S1→S2→S3) and for trinity-vs-C3 (S5 after S3).** Within S4/S6/S7 there is no inter-commit dependency (all distinct files) so ordering inside the wave is free.


---

## 4. PER-COMMIT VERIFICATION STRATEGY

Universal rule (verify-full-ci-suite): EVERY commit runs the FULL battery before its IMPL-REPORT — `python3 scripts/validate-pack.py` exit 0 (ALL checks, not just the touched ones) PLUS the relevant integration/per-check tests below. Each coder's PREFLIGHT line is emitted ONLY after all in-scope edits + verification PASS; if any fail, the coder reports what went wrong INSTEAD of a partial IMPL-REPORT.

### C1 (W0 gate)
- `python3 scripts/validate-pack.py` exit 0 (esp. Checks **44, 59, 65, 43, 45**).
- `bash scripts/tests/test-validate-pack-check-44.sh` (reduced: T1/T3/T4/Group-0/Group-2 PASS; T2-date + T5-SHA REMOVED).
- `bash scripts/tests/test-validate-pack-check-65.sh` (NEW: the MOVED T2-date + T5-SHA FAIL cases assert FAIL; the K1-K11 allowlist-PASS cases assert PASS; a non-allowlisted history hit FAILs).
- `python3 scripts/validate-pack.py --only-check 59` asserts "63 entries == constant".
- Reviewer: confirm Check-65 `_CHECK_65_OPERATING_DOCS` is built from the MEASURED ~136 IN set (G3) and admits NO EXEMPT doc; confirm the CONCISION-GUARDRAILS addendum names the realized consumer by file+symbol (`check_operating_doc_no_history`/Check 65).

### C2 (W-NUCLEAR)
- `python3 scripts/validate-pack.py` exit 0 (esp. Checks **22, 23, 39, 40, 41, 43, 44 (durable-list re-measured), 47, 51, 54**).
- `bash scripts/tests/pack-help-test.sh` (tracker section ABSENT on BOTH surfaces; `pack td` rows PRESENT).
- `bash scripts/tests/test-migrate-v10-to-v11.sh` (+ `-dry-run`, `-gates`, `-decompose` variants) — migrated tree no longer copies the tracker fragment, no missing-file failure.
- `bash scripts/tests/test-init-project.sh` — S11 no longer copies/asserts the tracker fragment; install completes green.
- Reviewer: confirm Checks 29/35/51 (dormant-CODE guards) UNCHANGED and GREEN (BD-214 retention); confirm `_SANCTIONED_PACK_SIDE_SHIPPED` membership UNCHANGED (`pack-help.sh` still ships, no set growth); confirm the `pack td` relocation preserved every live verb row; grep-zero `HELP-FRAGMENT-TRACKER` across `scripts/` + `pack-ops/` + `project-template/docs/pack/` EXCEPT any intentionally-retained KEEP (expect ZERO — file deleted on both surfaces).

### C3 (W1 rule)
- `python3 scripts/validate-pack.py` exit 0 (esp. Checks **45, 16, 18, 19**).
- `python3 scripts/validate-pack.py --only-check 45` exit 0 BEFORE (baseline) and AFTER (G4 — do not trust the "26↔26" literal; verify the live gate balances).
- `bash scripts/tests/test-validate-pack-check-45.sh` (if present) green.
- Reviewer: confirm the rule text + the RATIONALE `## slug` use LITERAL `BD-NNN`/`YYYY-MM-DD` (no digits) → self-safe vs Check 65 (run Check 65 on the edited trinity + RATIONALE = clean); confirm trinity parity ×2 locations; confirm project-template variant carries NO `[rationale:]` tag (D.3).

### C4..C14 (W2 pack strip)
- `python3 scripts/validate-pack.py` exit 0 (esp. Check **65** on each edited IN doc; Check 44 `will`/advisory; Check 45 unaffected — no whole rule removed).
- Reviewer per commit: **clause-set diff** (`git show HEAD:<file>` vs post-edit) proving set-equality modulo flagged B3 padding (NO behavior change); Check-65 grep-zero on the edited doc; each surviving KEEP token re-verified LIVE-and-CURRENT (K1-K11); each P-DEF removal left NO surviving deferred-feature description (reviewer-enforced — not regex-able). C14 (pack `_intro`, EXEMPT): reviewer leak-check only (NOT Check 65 — `_intro` is not in scope).

### C15 (W3) / C16 (W4 trinity)
- `python3 scripts/validate-pack.py` exit 0 (esp. **16, 18, 19, 45, 65**).
- Reviewer: trinity parity ×3 (clause-set diff per file, all 3 byte-parallel post-terseness); clause-preserving structural conversion (C.2 — every clause survives as a row); the §0 deferred-feature mentions GONE (P-DEF reviewer check); OQ-3 carve-outs rewritten keeping the unconditional directive; Check-65 clean on the edited trinity (KEEP K1/K2/K3).
- C16 specifically: confirm the 6-site tracker passages reduced to "Flat-file per-entry is the sole supported mode." with NO tracker contrast (leak axis).

### C17..C23 (W-LEAK client strips)
- `python3 scripts/validate-pack.py` exit 0 (C17: esp. **54** — confirm the tracker-section delete is Check-54-safe; C23: esp. **40, 43** — boundary refs to the deleted fragment cleaned, green post-C2).
- Reviewer per commit: the deferred-tracker-FEATURE mention GONE; the live flat-file directive KEPT; for C17/C18/C19/C20/C21/C23 the file's BLOAT pass also done (leak+bloat fold, same file). C22 (project `_intro`, EXEMPT): reviewer leak-check (client-shipped → leak axis), NOT Check 65.

### C24..C40 (W5 agent defs)
- `python3 scripts/validate-pack.py` exit 0 (esp. **11** pack-agent symmetry informational; tri-family parity).
- Reviewer per role-commit: tri-family clause-set diff across all 3 family files (byte-parallel); L-17 "Deferred items" KEPT identically ×3; no Check-65 history hit (project-side history = 0).

### C41..C93 (W6 skills/docs/prompts/stream-meta)
- `python3 scripts/validate-pack.py` exit 0 (esp. Check **1** SKILL frontmatter; Check 65 on the stream-meta `_rules`/`_format` IN docs; K9/K10 date examples allowlisted).
- Reviewer per commit: clause-set diff (no behavior change); frontmatter intact (skills); OQ-B `_v8-resolved-archive.md` ref corrected (audit-methodology); K9/K10/K11 date examples NOT stripped (allowlisted in C1).

**Reviewer clause-set-diff is MANDATORY on every bloat-restructured rule** (C.3). The grep-zero history gate (Check 65) runs in validate-pack on every commit touching an IN doc. The leak check (no deferred-feature mention on any client-facing surface) is REVIEWER-enforced (P-DEF is not regex-able); Check 65 catches only the date/BD RESIDUE a P-DEF/leak strip leaves behind.

---

## 5. BOUNDED REVIEW/FIX CYCLE (per commit, inside the isolated worktree)

Per commit, the cycle is: coder (fresh, in the commit's isolated worktree) → reviewer (RO, IN that worktree) → Pack-Chat triage (present to user) → fix-coder (REUSES the worktree) → reviewer → ... bounded to **≤2 review/fix pairs + 1 final reviewer = max 3 reviewer / 2 fix-coder spawns per commit**. If still dirty after the final reviewer pass, STOP the cycle and spawn `pack-architect` to diagnose root cause (no fix-coder pass 3). The patch is produced ONLY after a reviewer confirms CLEAN: Pack Chat SendMessage-s the most-recent read-write agent to `git diff > <handoff>/changes.patch` at THAT point; Pack Chat applies the reviewed-clean patch and commits with user approval. Agents never commit. A worktree is removed ONLY after its commit is CONFIRMED landed (exit 0); a failed commit KEEPS the worktree as the recovery fallback. Any OTHER agent spawned while a live worktree with uncommitted work exists ⇒ Pack Chat ASKS the user BOTH placement AND disposition (rule 9). Per-BD review/fix runs INLINE before the next commit's coder spawns; an end-of-batch reviewer runs once on the full set after all per-commit cycles.


---

## 6. CROSS-DOC CONSISTENCY LOCKSTEP (scheduled in lockstep)

1. **Trinity parity ×2 locations.** pack-root CLAUDE/AGENTS/GEMINI: the new rule (C3) + the W3 strip (C15) each touch all 3 in ONE commit. project-template CLAUDE/AGENTS/GEMINI: the new rule (C3) + the W4 strip (C16) each touch all 3 in ONE commit. Reviewer asserts byte-parallel rule expression at each location.
2. **Tri-family agent-def lock (16 roles).** Each W5 role-commit (C24..C39) touches `.claude/agents/<role>.md` + `.codex/agents/<role>.toml` + `.agents-plugin/optiquity-agents/agents/<role>.md` in ONE commit. Reviewer asserts identical substance ×3 (L-17 KEEP verified ×3).
3. **Check 45 rule↔rationale bijection.** The new rule's pack-root `[rationale: operating-docs-no-history-no-bloat]` ×3 + its `## operating-docs-no-history-no-bloat` in RATIONALE land in ONE commit (C3). Verified by `--only-check 45` exit 0 (G4: against the live gate, not the design's "26↔26" literal).
4. **Encoding-surface pairs (rippled checks ↔ their tests).** Each validate-pack check whose BODY a wave edits pairs with its per-check TEST in the SAME commit: C1 → Checks 44/65 bodies + `test-validate-pack-check-44.sh` + `test-validate-pack-check-65.sh`; C2 → Checks 22/23/39/40/41/43/44-durable-list bodies + `pack-help-test.sh` + the check-22/23 fixtures + `test-migrate*` + `test-init-project`. Asymmetric coverage (a check body edited without its test) = defect → reviewer blocks.
5. **CONCISION-GUARDRAILS reconciliation.** C1 appends the MOVE addendum (history axis §6/Check 44 → Check 65) naming the realized consumer by file+symbol (architect-doc-reality-reconciliation).
6. **`_CHECK_44_DURABLE_DOCS` ↔ deleted fragment.** C2 drops the HELP-FRAGMENT-TRACKER row (file deleted) AND re-measures the HELP-FRAGMENT-PACK ceiling after its tracker rows leave (same commit).

---

## 7. PUSH / MANIFEST PLAN (NOT a per-commit chore)

BD-243 changes `project-template/` fixture INPUTS (trinity, docs/pack, skills, prompts, agent defs, stream-meta, the deleted client HELP-FRAGMENT-TRACKER). Per regenerate-manifest-v11-surface, `test-fixtures/manifest.txt` is regenerated PUSH-TIME, NOT per-commit:
- The ORCHESTRATOR (Pack Chat), AFTER all BD-243 commits land green locally and BEFORE `git push`, runs `bash scripts/manifest-sync.sh`. Expect **exit 10** (a fixture input changed → manifest regenerated). Pack Chat commits the regenerated `test-fixtures/manifest.txt` with user approval (a bookkeeping commit), THEN `git push`.
- CI enforces correctness: `build.sh --verify` + validate-pack **Check 62** (manifest_structural) fail the gate if the manifest is stale. No per-commit manifest regen.
- After push: watch the `Validate Pack` GitHub Actions workflow (background); surface the verdict. Do NOT foreground-block on CI.
- The deleted client HELP-FRAGMENT-TRACKER.md is a fixture INPUT removal → the manifest regen reflects its absence; the install-map edit (C2) keeps Check 41/62 consistent.

NOTE: agents never push/regen-manifest/commit; this section is the ORCHESTRATOR's post-implementation procedure, stated so the plan is complete — it is NOT a coder task.

---

## 8. EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery FIRST; STALE for BD-243-era surfaces (returned BD-203 IMPL strip nodes — EE-P7) → G2 fallback to grep/Read/git for every exact-state claim.

**EE-P1 — runtime HEAD = BD-243 commit; clean tree.** Cmd `git rev-parse HEAD; git rev-parse --abbrev-ref HEAD; git status --short`. Output `a847f120e4ada06456bec4e2bf6d275fdd8c0742` ; `v11-dev` ; (empty status). Interpretation: at the BD-243 HEAD, nothing staged/dirty. Conclusion: **SUPPORTED.**

**EE-P2 — next-free check number = 65; EXPECTED_COUNT = 62 (→63).** Cmd `grep -nE '^\s*\(6[0-9], "check_' scripts/validate-pack.py | tail; grep -n "CHECK_REGISTRY_EXPECTED_COUNT = " scripts/validate-pack.py`. Output (verbatim): highest registered `(64, "check_dangling_example_deliverable_refs"`; `CHECK_REGISTRY_EXPECTED_COUNT = 62` (L500). Interpretation: next-free NUMBER = 65 (C1 registers `check_operating_doc_no_history` as 65); the entry-count constant bumps 62→63 (Check 65 +1; Check-44 reduction +0). Conclusion: **SUPPORTED.**

**EE-P3 — nuclear strip touches MORE init-project surfaces than the design's summary.** Cmd `grep -n "HELP-FRAGMENT-TRACKER" scripts/init-project.sh; grep -c "HELP-FRAGMENT-TRACKER" scripts/validate-pack.py`. Output (verbatim): init-project.sh hits at L14 (header comment), L949-956 (S11 copy block), L960-961 (`fail_stage S11` assertion), L1260 (install-map row), L1437 (cmd_update mapping); validate-pack.py = 23 HELP-FRAGMENT-TRACKER references. Interpretation: C2 must edit ALL init-project.sh hits (copy + assertion + install-map + comment + cmd_update) and the 23 validate-pack sites (Checks 22/23/39/40/41/43/44 + BD-082/194 comment blocks + install-map), not just the design-summary subset. Conclusion: **SUPPORTED** (C2 scope is materially broad — flagged for the coder).

**EE-P4 — tracker scripts are NOT marked `# pack-internal: true` today.** Cmd `grep -l "pack-internal: true" scripts/pack-tracker.sh scripts/tracker-migrate.sh scripts/pack-td.sh`. Output (verbatim): (empty — none). Interpretation: C2 must ADD the marker to pack-tracker.sh + tracker-migrate.sh (Check 23 stops requiring them in help) and NOT to pack-td.sh (live; stays listed) — OQV2-2a/G2. Conclusion: **SUPPORTED.**

**EE-P5 — per-check test naming convention + check-65 test absent.** Cmd `ls scripts/tests/ | grep -E "test-validate-pack-check-6[0-9]"`. Output (verbatim): `test-validate-pack-check-61.sh, -62, -63, -64` present; NO `-65`. Interpretation: the convention is `test-validate-pack-check-NN.sh`; C1 creates `test-validate-pack-check-65.sh` (new), consistent with convention. Conclusion: **SUPPORTED.**

**EE-P6 — project IN-set counts (tri-family/skills/prompts/docs).** Cmd `ls -1 project-template/.claude/agents/*.md | wc -l` (etc.). Output (verbatim): claude_agents=16, codex_agents=16, agents_plugin=16, RUNTIME-SUBAGENT-PATTERN present, pack_skills=11, project_skills=37, project_prompts=10, pack_agents=5. Interpretation: W5 = 16 roles ×3 families + RUNTIME-SUBAGENT (17 commit units); W6 = 37 skills + 10 prompts + the stream-meta. Conclusion: **SUPPORTED.**

**EE-P7 — graph is STALE for BD-243; G2 fallback exercised.** Cmd `graphify query "BD-243 operating doc strip commit dependency" --graph .../graph.json --backend claude-cli --budget 1500`. Output (verbatim, first nodes): `NODE IMPL-BD-203-Commit2-COMPLETION-FIX2 …`, `NODE IMPL-BD-203-Commit3 …`, `NODE STRIP #3 — :7403 Check-48 call-site comment …` — all BD-203-era, unrelated to BD-243's commit dependency. Interpretation: graph stale/unhelpful for BD-243 discovery → fell through to grep/Read/git IMMEDIATELY for every exact-state claim (no block). Conclusion: **SUPPORTED** (graph-first attempted, fallback correct).

**EE-P8 — G3: project docs/pack operating IN set = 4, not the 6 the design named.** Cmd `find project-template/docs/pack -type f -name "*.md"; find project-template -iname "*METHODOLOGY*" -o -iname "*INSTALL-PROCEDURES*" -o -iname "*SETUP-EXISTING*"`. Output (verbatim): docs/pack = HELP-FRAGMENT-TRACKER.md, HELP-FRAGMENT.md, OPTIONAL-FEATURES.md, PACK-FEEDBACK.md, PLATFORM-SKILLS.md, PM-CHAT.md (6 files; 2 are HELP-FRAGMENT EXEMPT); the METHODOLOGY/INSTALL/SETUP search returned only `project-template/skills/audit-methodology/`. Interpretation: the design's "docs/pack/*.md (6)" naming METHODOLOGY/INSTALL-PROCEDURES/SETUP-EXISTING is inaccurate — those files do not exist at that path; the real operating IN set is the 4 (OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT). The leak census L-6/L-7 reference only the real files → no recipe affected. Conclusion: **SUPPORTED** (count-label gap G3; recipes unaffected).

**EE-P9 — G4: Check-45 raw-grep baseline ≠ "26↔26".** Cmd `grep -cE "\[rationale: " CLAUDE.md; grep -cE "^## [a-z0-9][a-z0-9-]*\s*$" pack-ops/PACK-MEMORY-RATIONALE.md`. Output (verbatim): `27` ; `26`. Interpretation: the raw greps (which over-count vs Check 45's de-duped in-`## Pack memory` extraction) do NOT match the design's "26↔26" literal → W1 must verify against the LIVE `--only-check 45` gate, not the design number. The bijection MECHANISM (rule slug + `## slug` in one commit) is correct regardless. Conclusion: **SUPPORTED** (baseline-literal gap G4; mechanism unaffected).

**EE-P10 — Check 54 does NOT assert the tracker section (L-6 / C17 safety).** Cmd `grep -nE "\(54," scripts/validate-pack.py`. Output (verbatim): `(54, "check_optional_features_presence",`. Interpretation: Check 54 asserts the worktree/baseRef OPTIONAL-FEATURES section presence, not the tracker section → deleting the tracker section (C6 pack / C17 client) is Check-54-safe; the C17 coder VERIFIES by running Check 54 green post-edit. Conclusion: **SUPPORTED.**

**EE-P11 — integration test scripts present (verify-full-ci-suite).** Cmd `ls scripts/tests/pack-help-test.sh scripts/tests/test-migrate*.sh scripts/tests/test-init-project*.sh`. Output (verbatim): `pack-help-test.sh`, `test-init-project.sh`, `test-migrate-v10-to-v11.sh` (+ `-decompose`, `-dry-run`, `-gates`). Interpretation: C2's full-battery verification (pack-help + migrate + init-project) runs against existing scripts. Conclusion: **SUPPORTED.**


---

## 9. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD`, `git rev-parse --abbrev-ref HEAD`, `git status --short` (all read-only). Sole write = this plan doc via `cat >>` to `/tmp/pack-handoff-bd243-plan/PLAN-BD-243.md`. No repo-file edit; no patch; no state-changing git verb; no OptiquityTrader write. | COMPLIANT |
| **empirical-evidence-blocks [planner]** | §8 EE-P1..EE-P11: each = command + verbatim output + HEAD `a847f12` + 2026-06-21 + interpretation + SUPPORTED. State-claims backed: next-free check 65 + EXPECTED_COUNT 62→63 (EE-P2); nuclear-strip file scope incl. init-project (EE-P3); tracker-script header state (EE-P4); test-naming + check-65 absent (EE-P5); project IN counts (EE-P6); per-commit scope-keyword basis = the measured file partition (EE-P6/P8); G3 docs/pack count (EE-P8); G4 Check-45 baseline (EE-P9); Check-54 safety (EE-P10); integration tests present (EE-P11). | COMPLIANT |
| **bounded-review-fix-cycle** | §5 encodes ≤2 review/fix pairs + 1 final reviewer (max 3 reviewer / 2 fix-coder) per commit; architect escalation if dirty after final; patch only after reviewer-clean; per-BD review INLINE before next commit's coder. | COMPLIANT |
| **worktree-isolation model** | §3 + §5: RW coders run in an isolated worktree per commit (first coder creates, fix-coders REUSE); whole review/fix cycle inside it; patch only after reviewer-clean; `baseRef:"head"`; same-file commits serialize; the parallel-vs-dependent map (§3 S1..S7) is the schedule Pack Chat consumes; live-worktree ASK gate (rule 9) restated; teardown only after commit-confirmed-landed. | COMPLIANT |
| **enumerate-encoding-surfaces** | §6 + §4 C1/C2: every rippled check's BODY edit pairs with its per-check TEST in the SAME commit (44/65 in C1; 22/23/39/40/41/43/44-durable in C2, paired with pack-help-test + check-22/23 fixtures + migrate + init-project); trinity parity ×2 + tri-family lock (16 roles) scheduled in lockstep; asymmetric coverage flagged a defect. EE-P3 measured the validate-pack + init-project surfaces (23 + 5 hits). | COMPLIANT |
| **commit-subject-scope-keyword (Check 36)** | §2: each commit assigned a keyword — C1 pack-only; C2 NEUTRAL cross-surface (split-option C2a pack-only / C2b project-only documented); C3 NEUTRAL cross-surface (split-option C3a/C3b documented); C4..C15 pack-only; C16..C93 project-only. No commit touching BOTH surfaces claims an exclusive keyword (C2/C3 are NEUTRAL or split). | COMPLIANT |
| **regenerate-manifest-v11-surface** | §7: manifest regen is PUSH-TIME (`scripts/manifest-sync.sh`, expect exit 10), orchestrator-run, NOT per-commit; CI `build.sh --verify` + Check 62 enforce; explicitly flagged NOT a coder task. | COMPLIANT |
| **graph-first-context** | Discovery query attempted FIRST (EE-P7) for commit-dependency/co-change; graph STALE (BD-203 nodes) → G2 fallback to grep/Read/git IMMEDIATELY for every exact-state claim (no block). Injected absolute `--graph` path used verbatim; `--backend claude-cli`; `--budget 1500`; QUERY only, never built. | COMPLIANT |
| **verify-full-ci-suite** | §4: EVERY commit runs the FULL `validate-pack.py` battery (all checks) PLUS the relevant integration/per-check tests (C2 → pack-help-test + test-migrate ×4 + test-init-project; C1 → check-44 + check-65 tests; C3 → check-45). Each coder PREFLIGHT runs them green before its IMPL-REPORT. | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |

**END — PLAN-BD-243.md**
