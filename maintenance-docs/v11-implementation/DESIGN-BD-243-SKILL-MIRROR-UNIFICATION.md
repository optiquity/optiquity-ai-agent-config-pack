# DESIGN — BD-243 SKILL-MIRROR UNIFICATION (pack-root byte-identity + per-platform agent reduction + a durable identity gate)

Architect: FRESH architect instance (pack-architect, RO). I did NOT author any prior BD-243 artifact (DESIGN-FINAL/-METHOD/-DURABLE-GATES/-CLIENT-GATE, the CENSUS, PLAN-V2/-V4); conclusions are my own (reconciliation-instance-independence). I independently re-measured every load-bearing fact at runtime.
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`e1cd5df`** (verified at runtime — `git rev-parse HEAD` = `e1cd5df`; CB-01/CB-02/CB-03 LANDED above it), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: ARCHITECT-READY — goes to the user; the planner then folds this into the BD-243 commit sequence (CB-04 pack skills, CB-05 pack agents, + a new identity gate at the gate wave). I define the unification method, the gate design, and the commit-structure impact; I do NOT re-sequence the bloat partition.

**Scope: PACK-SIDE ONLY (pack-root mirrors).** The project-template mirror question is OUT OF SCOPE here and is handled separately during the project waves. This design reasons ONLY about the six pack-ROOT mirror surfaces: pack skills `.claude/skills` + `.codex/skills` + `.agents/skills` (×3); pack agents `.claude/agents` + `.codex/agents` + `.agents-plugin/pack-agents/agents` (×3).

---

## 0. EXECUTIVE ANSWER (decision-ready)

1. **Canonical = `.claude` for all 11 pack skills.** Measured: `.claude/skills` is grep-ZERO for `incident|BD-[0-9]|pack tracker` (clean+current); the 6 diverging skills are STALE in `.codex`/`.agents` (un-stripped history/tracker/deferred-feature + MISS current `.claude` content). NO mirror legitimately holds content `.claude` lacks. So byte-unification = copy the `.claude` SKILL.md byte-for-byte over the `.codex` and `.agents` copies, per skill. **pack-startup ruling: the graphify "Step 5 — Graph freshness" block MUST become cross-CLI** (graphify is a pack-dev accelerator equally relevant to a Codex/Antigravity pack-dev session — the freshness/hook readiness line is CLI-agnostic), and the stale `.codex`/`.agents` deferred/reserved-Step blocks (`Steps 5–7 are reserved` HTML comment + `Step 8 … (deferred)`) ARE DROPPED (they are exactly the deferred-feature mentions the no-history/no-bloat rule forbids). Evidence §1, §2.
2. **Byte-unification back-fills the strip gap (necessary AND sufficient).** The 6 diverging `.codex`/`.agents` skills carry un-stripped history/tracker/deferred-feature content the strip phase (scoped `.claude`-only) never touched. They ARE operating docs CG-14's Check 65 must see clean (the `_iter_operating_docs()` design globs `.claude/skills/*/SKILL.md` ONLY — see §3.2). Confirmed necessary (the gap is real, measured) and sufficient (copying the clean `.claude` byte-image leaves zero forbidden token in any mirror — grep-zero by construction). Evidence §2.
3. **Bloat method on the canonical = the already-approved §A S-test + A.2 invariant set + A.5 verification, applied ONCE to `.claude`.** CB-04/CB-05 reduce the `.claude` canonical per the approved method; the unification then propagates the reduced clean canonical to the two mirrors. The mirrors are NEVER independently bloat-reduced — they are byte-copies of the reduced canonical. §4.
4. **A new durable byte-identity gate: Check 71** (`check_pack_skill_mirror_identity`), FAIL, sized to exactly the 3 pack-root skill mirror trees, ×11 skills. It composes with Check 65 by the **gate-the-canonical-once + assert-identity** model (Check 65 scans the `.claude` canonical for history; Check 71 asserts the 2 mirrors are byte-equal to it — so the mirrors inherit cleanliness transitively, NO triple-scan). §5.
5. **Count delta: 63 → +1 for THIS gate (Check 71).** Folded into CG-14's atomic registration, the V4 bump 63→68 becomes **63→69** (+5 prior + 1 new). ALL count-encoding surfaces enumerated §5.3 (the load-bearing one is `test-validate-pack-check-64.sh`'s hardcoded literal `63`→`69`). §5.3, §6.
6. **Agents: per-platform reduction, NO byte-identity.** Each agent family reduces by the §A S-test in its own format (`.md` frontmatter vs `.toml` `developer_instructions`), preserving per-platform structure. The Check-56 28-verb + catch-all invariant is PRESERVED in all 3 pack-coder surfaces (measured present in all 10 Check-56 surfaces today). No new agent gate — Check 11 (lenient parity) + Check 56 (verb invariant) already cover agents; byte-identity is the WRONG property for agents (md≠toml). §7, pattern-fit justification §7.2.
7. **Commit structure: CB-04 becomes tri-mirror-locked per skill** (each skill's 3 files land as ONE unit — reduce `.claude`, propagate to `.codex`/`.agents`, in the same commit); CB-05 stays tri-family per agent (reduce each family in its format). The identity gate (Check 71) registers at CG-14 (the atomic count event), bumping V4's 63→68 to 63→69. §6.

---

## 1. CANONICAL-CONTENT DETERMINATION (success criterion 1)

### 1.1 The measured divergence map (which skills, which direction)

All 11 pack skills exist in all 3 mirrors. The byte-comparison @ `e1cd5df`:

| Skill | .claude vs .codex | .codex vs .agents | Canonical | Stale mirrors carry |
|---|---|---|---|---|
| architecture-review | IDENTICAL | IDENTICAL | (already unified) | — |
| boundary-investigation | IDENTICAL | IDENTICAL | (already unified) | — |
| dependency-intake | IDENTICAL | IDENTICAL | (already unified) | — |
| documentation | IDENTICAL | IDENTICAL | (already unified) | — |
| planning | IDENTICAL | IDENTICAL | (already unified) | — |
| commit-discipline | **DIVERGE** | IDENTICAL | `.claude` | "BD-119 C-2 incident" history |
| implementation-report | **DIVERGE** | IDENTICAL | `.claude` | "C-4 → C-4b POQ-6 / BD-119 C-4" history |
| pack-help | **DIVERGE** | IDENTICAL | `.claude` | "pack tracker *" tracker mention |
| pack-startup | **DIVERGE** | IDENTICAL | `.claude` | tracker + "BD-203 deleted" history + reserved/deferred Steps; MISSES graphify Step 5 |
| review | **DIVERGE** | IDENTICAL | `.claude` | "BD-185 reconciliation" history |
| verification-harness | **DIVERGE** | IDENTICAL | `.claude` | "BD-119 convention / BD-219" history |

Key structural fact: `.codex` and `.agents` are byte-identical to EACH OTHER for ALL 11 skills; the 6 that diverge from `.claude` are exactly the 6 with un-stripped contamination. So the unification is two-way (`.claude` → {`.codex`, `.agents`}), and the 5 already-clean skills are no-ops (verified identical).

### 1.2 The determination method (handle every case)

**Common case (10 of 11 + the body of the 11th): `.claude` is clean+current → `.claude` is canonical, byte-copied to the 2 mirrors.** Verified: `.claude/skills` is grep-ZERO for `incident|BD-[0-9]|pack tracker`; the `.codex`/`.agents` copies carry those tokens. In every diverging diff, the `.codex` side is PURELY older — it has un-stripped tokens AND lacks content `.claude` gained. There is no skill where a mirror holds legitimate content `.claude` lacks.

**The "mirror legitimately holds content `.claude` lacks" case: DOES NOT OCCUR here (measured), but the method is stated for durability.** The decision rule the coder applies per skill: (a) diff `.claude` against each mirror; (b) for any line PRESENT in a mirror and ABSENT in `.claude`, classify it — is it (i) STALE (un-stripped history/tracker/deferred, or content `.claude` superseded) → DROP, or (ii) a genuine current fact `.claude` is missing → ESCALATE to the user (a real asymmetry that the strip phase or a prior edit lost from `.claude`). Across all 6 diverging skills @ `e1cd5df`, EVERY mirror-only line classifies (i) STALE — so the method collapses to "byte-copy `.claude`." No (ii) escalation arises. The escalation branch exists so a FUTURE divergence (where a mirror legitimately leads) is caught, not silently overwritten.

### 1.3 pack-startup ruling (the prompt's specific question)

pack-startup is the ONLY skill where the divergence is bidirectional in CONTENT (not just stale tokens): the `.claude` canonical (106 ln) has the full "Step 5 — Graph freshness + hook-install readiness" block + the `**Graph:**` readiness line that the `.codex`/`.agents` copies (87 ln) LACK; conversely the stale copies carry a `Steps 5–7 are reserved` HTML-comment block + a `## Step 8 — Inflection-point recommendation check (deferred)` section that `.claude` DROPPED.

Ruling: **byte-unification makes the graphify Step-5 content cross-CLI, and that is CORRECT for Codex/Antigravity.** Rationale (property-fit, not convenience):
- Graphify is a pack-DEV accelerator (BD-225/226), consumed by ANY pack-dev session regardless of CLI — a Codex or Antigravity pack-dev agent benefits from the same graph-freshness/hook-install readiness check at startup. The Step-5 block is CLI-AGNOSTIC: it shells `git rev-parse` + `tail`/`grep`/`python3` over `graphify-out/graph.json` and reports a local readiness line — no Claude-specific primitive. (Contrast the trinity Sub-agent-behavior block, which IS Claude-specific and stays asymmetric — but that lives in the trinity CLAUDE.md, NOT in a skill. Skills carry the user's byte-identity ruling; the Claude-only carve-outs live in agent/trinity files.)
- The user's binding ruling is **skills MUST be byte-identical across all 3 CLIs.** That ruling, applied to pack-startup, REQUIRES the graphify block to be present in all 3 (the alternative — strip it from `.claude` to match the stale copies — would DELETE current, correct, CLI-agnostic content, violating the no-meaning-loss invariant and the user's "clean+current canonical" intent).

And: **the stale `.codex`/`.agents` deferred/reserved-Step blocks ARE dropped** by the unification. The `Steps 5–7 are reserved` HTML comment + `## Step 8 … (deferred)` section are textbook `operating-docs-no-history-no-bloat` violations (b) "description of a DEFERRED / unimplemented / off-by-default feature — even to say it is deferred." They are ALREADY absent from the clean `.claude` canonical; byte-copying `.claude` drops them mechanically. Evidence: EE-PACKSTARTUP.

**EE-PACKSTARTUP — pack-startup canonical-vs-stale content delta @ `e1cd5df`.**
- Cmd: `diff .codex/skills/pack-startup/SKILL.md .claude/skills/pack-startup/SKILL.md; wc -l .claude/skills/pack-startup/SKILL.md .codex/skills/pack-startup/SKILL.md`.
- Output (verbatim, key): `.claude` 106 ln, `.codex` 87 ln. `.codex`-only (dropped on unification): `local tracker opt-in changes the write channel`, `BD-203 deleted \`pack-ops/BACKLOG.md\` + \`pack-ops/CHANGELOG.md\``, the `<!-- Steps 5–7 are reserved … Step 8 numbering is fixed by V3 §28.1.9 -->` block, `## Step 8 — Inflection-point recommendation check (deferred)` + `The D-19 tracker opt-in recommendation is DEFERRED (BD-214) …`. `.claude`-only (gained on unification): `## Step 5 — Graph freshness + hook-install readiness (LOCAL, never fails startup)` + the `**Graph:**` readiness line + the graphify bash block.
- HEAD/date: `e1cd5df` / 2026-06-22.
- Interpretation: `.claude` is unambiguously clean+current; the stale copies carry deferred-feature + history + tracker contamination AND miss the current graphify Step-5. Byte-copying `.claude` simultaneously drops all contamination and propagates the current content — the single mechanical move satisfies both the user's byte-identity ruling and the no-history/no-bloat rule.
- Conclusion: **SUPPORTED.**

**EE-CANON — `.claude/skills` is the clean canonical; the 6 diverging mirrors carry contamination `.claude` lacks @ `e1cd5df`.**
- Cmd: `grep -rlE 'incident|BD-[0-9]|pack tracker' .claude/skills .codex/skills .agents/skills`; per-skill `diff -q` across the 3 mirrors.
- Output (verbatim): `.claude/skills` → ZERO hits; `.codex/skills` → {commit-discipline, implementation-report, pack-help, pack-startup, review, verification-harness}; `.agents/skills` → the SAME 6; `diff -q` → the same 6 diverge `.claude`-vs-`.codex`, all 11 IDENTICAL `.codex`-vs-`.agents`.
- HEAD/date: `e1cd5df` / 2026-06-22.
- Interpretation: the contamination set == the divergence set == 6 skills, all in `.codex`/`.agents`, none in `.claude`. The canonical is `.claude` for all 11 (5 already-identical no-ops + 6 stale-mirror back-fills).
- Conclusion: **SUPPORTED.**

---

## 2. STRIP BACK-FILL CONFIRMATION (success criterion 2)

The strip phase (CG-01..CG-13, landed) + the in-flight bloat phase (CB-01/02/03 landed) were both scoped to the `.claude` mirror ONLY. The `.codex`/`.agents` skill mirrors were never touched by the strip — so they retain the history/tracker/deferred-feature content the strip removed from `.claude`. Byte-unifying to the clean `.claude` canonical closes that gap.

**Necessary.** The `.codex`/`.agents` skill mirrors ARE operating docs (an agent executes a SKILL.md as live instruction). CG-14's Check 65 (no-history gate) must see the full operating-doc IN set clean. The DURABLE-GATES `_iter_operating_docs()` design (§2.1) globs the pack skill family as `.claude/skills/*/SKILL.md` ONLY — it does NOT enumerate `.codex/skills` or `.agents/skills`. So at CG-14 activation, Check 65 scans the clean `.claude` canonical and PASSES, while the stale `.codex`/`.agents` copies carry forbidden tokens that Check 65 NEVER SEES — a silent-rot hole exactly of the kind BD-243 exists to close. The byte-identity unification is what guarantees the un-scanned mirrors are clean (they equal the scanned canonical). Without it, the mirrors stay dirty AND unscanned.

**Sufficient.** Copying the clean `.claude` byte-image over `.codex`/`.agents` makes the mirror grep-zero for every Check-65 forbidden pattern BY CONSTRUCTION (byte-equal to a grep-zero file ⇒ grep-zero). No residue can survive a byte-copy. The post-unification grep-zero is the measure-then-bound verification (§5.5).

**Why not just add `.codex`/`.agents` to the Check-65 IN set instead?** That would catch the contamination but NOT fix it (it would FAIL CI until each mirror is hand-stripped) AND it would triple the IN-set scan cost AND it would NOT enforce byte-identity (the user's binding ruling) — two independently-stripped mirrors could drift in WORDING while both staying history-clean. Byte-identity is the stronger, cheaper, ruling-aligned invariant: the canonical is scanned once for history; the mirrors are asserted byte-equal; cleanliness is inherited. §5.2 elaborates the composition.

**EE-BACKFILL — the strip gap on the `.codex`/`.agents` skill mirrors @ `e1cd5df`.**
- Cmd: `grep -c -E 'incident|BD-[0-9]|pack tracker|deferred|reserved' .codex/skills/pack-startup/SKILL.md .agents/skills/pack-startup/SKILL.md`; cross-check the `_iter_operating_docs` skill glob in DESIGN-BD-243-DURABLE-GATES §2.1.
- Output (verbatim): `.codex`/`.agents` pack-startup each carry the un-stripped tracker + `BD-203 deleted` + `Steps 5–7 are reserved` + `Step 8 … (deferred)` content; DURABLE-GATES §2.1 pack-skill glob = `.claude/skills/*/SKILL.md` (the `.codex`/`.agents` skill dirs are NOT in any family glob).
- HEAD/date: `e1cd5df` / 2026-06-22.
- Interpretation: the stale mirrors are operating docs that CG-14's Check 65 will NOT scan (the glob is `.claude`-only) and that carry forbidden tokens — a real silent-rot hole. Byte-unification to the clean `.claude` canonical closes it (necessary) and leaves grep-zero (sufficient).
- Conclusion: **SUPPORTED.**

---

## 3. THE GAP THE EXISTING CHECKS DO / DO NOT COVER (the property census)

Before designing a new gate, census what ALREADY enforces mirror state — measure-then-bound's "measure first."

### 3.1 Check 51 / Check 52 enumerate the mirror DIRS — but for different invariants

- **Check 51** (`_CHECK_51_RECOMMEND_SKILL_DIRS`) lists `.claude/skills`, `.codex/skills`, `.agents/skills` (+ project dirs, out of scope here) — but only to scan for a DEFERRED tracker-recommendation token (`recommendation_should_recommend`). It does NOT compare the mirrors to each other. Not an identity gate.
- **Check 52** (`_CHECK_52_AGENT_DIRS`) lists `(.claude/agents, md)`, `(.codex/agents, toml)`, `(.agents-plugin/pack-agents/agents, md)` — but to assert each agent file carries an RW/RO mandate-header. Not an identity gate.

So the mirror DIR enumeration already exists (a reuse anchor for the new gate's surface list), but NO check asserts skill byte-identity.

### 3.2 Check 56 already enforces the verb invariant across the 3 commit-discipline skill mirrors + 3 pack-coder agent surfaces

`_CHECK_56_VERB_PARITY_SURFACES` enumerates exactly the 10 surfaces: pack trinity ×3, RATIONALE, the 3 commit-discipline skill mirrors (`.claude`/`.codex`/`.agents`), the 3 pack-coder agent surfaces (`.claude/.md`, `.codex/.toml`, `.agents-plugin/.md`). It asserts the 28-verb denylist + the catch-all phrase `including but not limited to` is present in ALL 10 (whitespace-normalized). This is a SEMANTIC presence invariant (the verb set), NOT byte-identity — and it deliberately spans md+toml (where byte-identity is impossible). Check 56 is the model for the AGENT invariant (§7) and the anti-model for the SKILL gate (§7.2): skills want byte-identity, agents want semantic presence.

### 3.3 Check 11 (informational, lenient) covers agent parity

`check_pack_agent_trinity` runs `compare-agent-trinity.py --all` in LENIENT mode (whitespace + markdown normalized; tool-specific frontmatter excluded) and reports a divergence COUNT — informational, always-OK. This is the correct shape for AGENTS (the user ruled agents MAY differ per platform). It is the wrong shape for SKILLS (byte-identity required, FAIL not informational). So the SKILL gate is NEW, not an extension of Check 11.

**EE-EXISTING — the existing mirror-aware checks @ `e1cd5df`.**
- Cmd: `grep -n '_CHECK_51_RECOMMEND_SKILL_DIRS\|_CHECK_52_AGENT_DIRS\|_CHECK_56_VERB_PARITY_SURFACES' scripts/validate-pack.py`; read Check 11 docstring.
- Output (verbatim, key): Check 51 skill dirs include `.claude/skills`/`.codex/skills`/`.agents/skills`; Check 52 agent dirs = `(.claude/agents,md)`/`(.codex/agents,toml)`/`(.agents-plugin/pack-agents/agents,md)`; Check 56 surfaces include the 3 commit-discipline skill mirrors + 3 pack-coder agent surfaces; Check 11 runs `compare-agent-trinity.py --all` lenient, "INFORMATIONAL: it always exits OK".
- HEAD/date: `e1cd5df` / 2026-06-22.
- Interpretation: NO existing check asserts skill byte-identity; the dir enumerations + the verb-presence invariant exist as reuse anchors but enforce different properties. A new FAIL byte-identity gate is the gap.
- Conclusion: **SUPPORTED.**

---

## 4. BLOAT METHOD ON THE UNIFIED CANONICAL (success criterion 3)

The bloat method is already specified and approved — DESIGN-BD-243-BLOAT-METHOD §A (the S-test S1/S2/S3, the A.2 invariant set, the A.5 verification contract) and PLAN-V2 §3.1. I do NOT redefine it; I state how it applies under unification.

**The reduce-ONCE-then-propagate rule.** The bloat reduction runs on the `.claude` CANONICAL ONLY. The `.codex`/`.agents` mirrors are NEVER independently bloat-reduced — they are byte-copies of the reduced canonical. Concretely, within CB-04 per skill:
1. Reduce `.claude/skills/<s>/SKILL.md` per the §A S-test (KEEP if S1 concrete-shape / S2 edge-case / S3 enumeration; REMOVE only pure redundant illustration), never touching the A.2 invariant set (guardrails / rules / triggers / exceptions / in-out-of-scope / frontmatter).
2. The A.5 verification (invariant-set diff EQUAL + example-removal justification log + retention spot-check + Check 1 frontmatter intact) runs on the `.claude` reduction.
3. Byte-copy the reduced `.claude/skills/<s>/SKILL.md` over `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md`.
4. The mirrors need NO separate A.5 proof — they are byte-equal to the proven-clean canonical (the identity gate, §5, is their proof).

**Why this is the only correct application.** The user's byte-identity ruling makes independent per-mirror reduction logically incoherent: two independent S-test passes on the same content could legitimately keep/remove different borderline examples and produce byte-DIFFERENT (but each individually valid) results — which would VIOLATE byte-identity. Reducing once + propagating is the only method that satisfies both the bloat ruling AND the byte-identity ruling. It also halves the reviewer's A.5 load (one invariant-set diff per skill, not three).

**Sequencing of unification vs reduction within CB-04.** The unification (strip back-fill) and the bloat reduction are the SAME mechanical move for the 6 diverging skills: byte-copying the reduced clean `.claude` simultaneously (a) drops the stale contamination and (b) propagates the bloat-reduced content. For the 5 already-identical skills, the bloat reduction reduces `.claude` and re-propagates (the mirrors were already byte-equal; they stay byte-equal to the reduced canonical). So CB-04's per-skill unit is: reduce `.claude`, then `cp` to the two mirrors — one atomic tri-mirror edit per skill.

---

## 5. THE DURABLE SKILL-MIRROR BYTE-IDENTITY GATE — Check 71 (success criterion 4)

### 5.1 Measure-then-bound: the measured current state

Step 1 (measure first): the 3 pack-root skill mirror trees @ `e1cd5df` carry 11 skills each; 5 are byte-identical across all 3, 6 diverge (`.claude` clean, `.codex`==`.agents` stale). The complete divergence set is the 6 in §1.1.

Step 2 (categorize every divergence KEEP vs STRIP): EVERY divergence is a STRIP — there is no skill where a mirror byte-difference is legitimate (the user ruled byte-identity is REQUIRED; there is no allowlist of "permitted skill divergence"). So the categorization is uniform: all 6 divergences STRIP (resolved by the §4 propagation).

Step 3 (design the fix): CB-04 reduces `.claude` + byte-copies to the 2 mirrors (§4) — resolving all 6 STRIP divergences.

Step 4 (size the gate exactly): the gate's invariant is **byte-equality of `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md` to `.claude/skills/<s>/SKILL.md`, for every `<s>` in `.claude/skills`.** NO allowlist (byte-identity is absolute; any divergence is a defect by the user's ruling). The gate is sized to exactly the 3 trees × the canonical's skill set — no broader (it does not scan project mirrors, out of scope), no narrower (all 11 skills).

Step 5 (verify clean against projected post-fix state): after CB-04, all 11 skills are byte-equal across the 3 mirrors (the 6 STRIPs resolved + the 5 no-ops preserved) ⇒ Check 71 runs CLEAN. §5.5 states the verification.

### 5.2 Composition with CG-14's Check 65 (gate-the-canonical-once + assert-identity)

The prompt asks: gate the canonical once and assert identity, vs gate all three? **Decision: gate the canonical once (Check 65 scans `.claude` per the existing `_iter_operating_docs()` glob) + assert byte-identity (Check 71 asserts the 2 mirrors == `.claude`).** Cleanliness is then INHERITED: a mirror byte-equal to a Check-65-clean canonical is itself clean, transitively, WITHOUT a second scan.

Why this composition (property-fit, not pattern-copy):
- **Cheaper.** Check 65's history scan (11 forbidden patterns × the IN set) runs over the `.claude` skills once, NOT ×3. Check 71 is a byte-compare (a hash or `==` of file bytes) — far cheaper than re-running 11 regexes over 22 more files. ci-check-runtime-compounding (×~155 battery invocations) favors the compare.
- **Stronger.** Gating all three for history would catch history but NOT enforce byte-identity (the user's ruling) — two mirrors could be independently history-clean yet WORD-DIFFERENT. The identity gate enforces the stronger invariant; the canonical scan enforces cleanliness; together they give "all three clean AND identical" at lower cost than "all three scanned (but maybe divergent)."
- **No IN-set change needed.** `_iter_operating_docs()` stays `.claude`-only for skills (DURABLE-GATES §2.1) — Check 71 makes that glob's `.claude`-only scope SAFE (the un-scanned mirrors are provably equal to the scanned canonical). This is the missing piece that justifies the existing `.claude`-only glob.

A meta-note for Gate-4 (Check 69 scope-completeness): Check 69 asserts every operating-doc family member is globbed-or-EXEMPT. The `.codex`/`.agents` skill dirs are deliberately NOT in a Check-65 family glob (they are mirror-checked by Check 71, not history-scanned). Check 69's family/EXEMPT model must not flag them as "escaped" — they are covered by Check 71's identity assertion, a parallel guarantee. The planner notes this so Check 69's OUT-OF-FAMILY reasoning accounts for the mirror trees (they need no Check-69 record because they are not in the history-scan families at all; Check 71 owns them).

### 5.3 Check 71 design + ALL encoding surfaces (enumerate-encoding-surfaces)

**Check identity.** `check_pack_skill_mirror_identity` (Check 71 — the next free integer after V4's 66/67/68/69/70; the COUNT delta is +1 regardless of the number). FAIL. Reads each `<s>` in `.claude/skills` (the canonical set), compares the byte content of `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md` to `.claude/skills/<s>/SKILL.md`; any byte-difference (or a missing/extra mirror file) FAILs with `<s>` + which mirror + a "byte-diverges from .claude canonical — re-propagate the reduced canonical" remediation. Lenient only on a wholly-absent mirror tree (init/state problem ⇒ skip with a note, matching Check 65's lenient-absent posture) — but a PRESENT mirror with a DIFFERENT file FAILs.

**Constant.** `_CHECK_71_SKILL_MIRROR_DIRS = (".claude/skills", ".codex/skills", ".agents/skills")` with `.claude/skills` as the canonical[0]. (Reuses the exact dir set Check 51 already lists — `filename-uniqueness` / `enumerate-encoding-surfaces`: one canonical tuple, the new gate references it; a future CLI surface added to the skill mirror set is added here in lock-step, the same maintenance-guard discipline Check 51/52 carry.)

**The count-bump surfaces — Check 71 adds +1 to V4's bump, making it 63 → 69 (V4's 5 new checks + this 1).** ALL surfaces (re-measured @ `e1cd5df`, where the constant + tuple-count + check-64 literal all = 63):

| # | Surface | File:line @ `e1cd5df` | V4 target (5 checks) | + Check 71 → final | Miss = CI fail? |
|---|---|---|---|---|---|
| S1 | `CHECK_REGISTRY_EXPECTED_COUNT` | `scripts/validate-pack.py:496` (`= 63`) | `= 68` | **`= 69`** | YES (Check 59) |
| S2 | `CHECK_REGISTRY` entries | registry tail | append 66/67/68/69/70 | + `(71, "check_pack_skill_mirror_identity", check_pack_skill_mirror_identity, W)` | YES (count won't reach 69) |
| S3 | EXPECTED_COUNT comment ledger | `scripts/validate-pack.py:475-495` | +5 `+1 net-new` lines | + 1 `+1 net-new BD-243 Check 71` line | NO (doc) — required for audit |
| S3b | stale prose "62" | `scripts/validate-pack.py:476` | reconcile to 68 | reconcile to **69** | NO (doc) |
| S4 | **hardcoded-literal test** | `scripts/tests/test-validate-pack-check-64.sh:74-75` (`!= 63` / `FAIL_COUNT_NOT_63`) + line 82 (`== 63`) | `!= 68` / `_68` / `(== 68)` | **`!= 69` / `FAIL_COUNT_NOT_69` / `(== 69)`** | **YES — the load-bearing trap** |
| S5 | per-check test (NEW) | `scripts/tests/test-validate-pack-check-71.sh` | (n/a) | NEW file, DYNAMIC count form (`len(_build_check_registry()) != EXPECTED_COUNT` + `71 in nums`), NEVER the hardcoded literal | YES if mis-shaped |
| S6 | ci-shard-plan test discovery | `scripts/lib/ci-shard-plan.py` (globs `scripts/tests/*.sh`) | self-satisfies | self-satisfies (the new test matches the glob; NO allowlist edit — the wiring allowlist is an EXCLUDE list) | auto |
| S7 | Check 59 runtime assertion | `check_registry_completeness` | self-satisfies once S1+S2 land | self-satisfies | auto |
| S8 | Check 60 shard-coverage | `check_ci_shard_coverage` | self-satisfies via registry | self-satisfies | auto |

The DYNAMIC count-invariant tests (`test-validate-pack-check-62.sh:70`, `-63.sh:62`) compare `len(_build_check_registry())` to the constant — they self-satisfy and need NO edit. The ONLY hardcoded-literal trap is check-64 (S4). The NEW check-71 test MUST use the dynamic form (S5) — never mint a second hardcoded-literal trap.

**Atomicity.** S1 + S2 + S4 (now `63→69` / +6 entries / literal `69`) land in ONE commit (CG-14, the atomic count event), S3/S3b ride it. This is the SAME atomic event V4 §2 already concentrates — Check 71 adds one registry entry + one to the bump, no new atomic event.

### 5.4 Runtime cost (ci-check-runtime-compounding)

Check 71 reads 33 small files (11 skills × 3 mirrors) once and byte-compares (or hashes) — O(skill bytes), no regex, no subprocess, no whole-tree scan. The pack skill total is ~1.2k lines (`.claude/skills` 11 files). Across the ~155 battery invocations this is trivial (far cheaper than a per-mirror history re-scan, which is the alternative this gate AVOIDS). Implementation: read `.claude` once per skill, compare the two mirror bytes against it; first-mismatch reporting.

### 5.5 Verify the gate runs CLEAN against projected post-fix state (measure-then-bound step 5)

Post-CB-04, every `<s>`: `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md` are byte-copies of the reduced `.claude/skills/<s>/SKILL.md` ⇒ byte-equal ⇒ Check 71 PASSes for all 11. The 5 already-identical skills stay identical (reduced canonical re-propagated); the 6 stale skills become identical (back-filled). The coder PREFLIGHT for CB-04 verifies this directly: `for s in .claude/skills/*/; do diff .claude/skills/$s .codex/skills/$s && diff .claude/skills/$s .agents/skills/$s; done` → all empty. And the grep-zero sufficiency check (§2): `grep -rlE 'incident|BD-[0-9]|pack tracker' .codex/skills .agents/skills` → ZERO post-CB-04.

**EE-GATE-PROJECTED — the gate's clean post-fix state is reachable by byte-copy @ `e1cd5df`.**
- Cmd (projection logic): the 6 STRIP divergences are each resolved by `cp .claude/skills/<s>/SKILL.md .{codex,agents}/skills/<s>/SKILL.md`; the 5 no-op skills are already byte-equal (verified `diff -q` empty). Post-copy, all 33 files in 11 byte-equal triples.
- Output: the projected post-CB-04 state has 0 divergent skills (11/11 byte-equal triples) and grep-zero contamination in the mirrors (byte-equal to the grep-zero `.claude`).
- HEAD/date: `e1cd5df` / 2026-06-22.
- Interpretation: Check 71 runs CLEAN against the projected post-fix state; the gate is sized exactly to the invariant (3 trees × 11 skills, no allowlist) and verifies clean.
- Conclusion: **SUPPORTED.**

---

## 6. COMMIT-STRUCTURE IMPACT (success criterion 6)

### 6.1 CB-04 re-scopes to tri-mirror-locked per skill

V4 CB-04 was "pack skills bloat (`.claude/skills/*/SKILL.md` ×11), `pack-only`." It RE-SCOPES to include the two mirrors:
- **Membership:** `.claude/skills/*/SKILL.md` (11) + `.codex/skills/*/SKILL.md` (11) + `.agents/skills/*/SKILL.md` (11) = 33 files.
- **Per-skill unit (tri-mirror lock):** reduce `.claude/skills/<s>` per §A; byte-copy to `.codex`/`.agents`; the 3 files for skill `<s>` land as ONE logical unit. Skills are parallel across distinct files within CB-04's worktree (rule-10 parallelization: 11 independent tri-mirror units, no same-file contention).
- **Scope keyword:** `pack-only` — all 33 paths are pack-root mirrors (outside `project-template/` + `supporting-docs/`), so Check 36's `pack-only` deny-set is satisfied. NO cross-surface leak (this commit does NOT touch `scripts/validate-pack.py` — the gate body lands at the gate wave, §6.3).
- **Method:** §A S-test on `.claude` only (§4); byte-copy propagation; A.5 contract on `.claude`; Check 1 frontmatter intact in all 3 (a byte-copy preserves it).
- **Verification (CB-04-specific, added to the §4 full battery):** the per-skill tri-mirror `diff` empty (§5.5); grep-zero contamination in `.codex`/`.agents` skills; the A.5 invariant-set diff on `.claude`; Check 56's commit-discipline verb invariant survives in all 3 commit-discipline mirrors (a byte-copy of a verb-complete `.claude` keeps it — and check-56 reads all 3, so a full-battery PREFLIGHT catches a regression).

### 6.2 CB-05 stays tri-family per agent (per-platform reduction, §7)

CB-05 reduces the 5 pack agents in 3 families, per format, NO byte-identity (§7). Each agent's 3 family files (`.claude/.md`, `.codex/.toml`, `.agents-plugin/.md`) land as one tri-family unit (the trinity-rule parallel edit). `pack-only`. Preserves the Check-56 28-verb + catch-all invariant in the 3 pack-coder surfaces.

### 6.3 Where the new gate registers + the V4 count arithmetic change

The Check 71 BODY + constant + test can be authored at the gate wave's prep step (CG-14-prep-b in V4, alongside Checks 66/67/68/70 bodies — all authored-UNREGISTERED, count stays 63). The REGISTRATION + the count bump happen atomically at CG-14. So:
- **V4's bump 63 → 68 (5 checks) becomes 63 → 69 (6 checks).** Check 71 is the 6th new registry entry.
- **check-64's literal becomes `63 → 69`** (not `63 → 68`) — S4 in §5.3.
- The atomic event at CG-14 registers 66/67/68/69/70 + **71**, bumps the constant to **69**, edits check-64 to `69`, reconciles the ledger (+6 lines) + the stale prose to 69.
- Check 71's measure-then-bound baseline (the clean byte-identical mirrors) is satisfied by **CB-04** (the bloat+unification commit), NOT by the gate wave — so Check 71 passes against a real clean state at CG-14, exactly as the V4 gates pass against the bloat-reduced tree. The ordering dependency is `CB-04 → … → CG-14` (CB-04 must land before Check 71 activates), which the V4 sequence already guarantees (all CB land before the gate wave).

### 6.4 Parallel-vs-dependent map (rule-10)

- **CB-04 internal:** 11 tri-mirror skill units, parallel across distinct files (no two units share a file).
- **CB-04 vs CB-05:** disjoint file sets (skills vs agents) → parallel.
- **CB-04 vs CG-14:** CB-04 is a hard PREDECESSOR of Check 71's activation (the gate measures CB-04's output). Same dependency shape as every V4 gate-vs-bloat-wave edge.
- **Check 71 body authoring (CG-14-prep-b) vs CB-04:** the body can be authored anytime (it has no parameters to derive from the reduced tree — byte-identity is parameter-free, UNLIKE Gate 1's ceilings); only its ACTIVATION (CG-14) depends on CB-04. So Check 71 authoring is NOT on CB-04's critical path; only its activation is.
- **Serial bottleneck:** the gate wave (CG-14-prep-a → -b → CG-14) stays strictly serial (all edit `scripts/validate-pack.py`); Check 71's body joins CG-14-prep-b's edits, its registration joins CG-14's atomic event — no new serialization beyond V4's.

---

## 7. AGENT PER-PLATFORM REDUCTION (success criterion 5)

### 7.1 The approach across the 3 agent families (NO byte-identity)

The user ruled agents MAY differ per platform ("best for the platform they support"). The 3 pack agent families are STRUCTURALLY un-byte-identical by format: `.claude/agents/pack-*.md` (Markdown + YAML frontmatter), `.codex/agents/pack-*.toml` (TOML, body in `developer_instructions`), `.agents-plugin/pack-agents/agents/pack-*.md` (Antigravity plugin-bundle Markdown). The agent mirrors are ALREADY CLEAN (measured grep-zero for `incident|BD-[0-9]|pack tracker` in all 3 families) — they were kept in sync during the strip phase, so there is NO back-fill gap for agents.

CB-05's method per family:
- Apply the §A S-test to each family's body PROSE in its own format — reduce padding/redundant illustration, keep S1/S2/S3 content + the A.2 invariant set. The reduction is per-platform: the `.toml` body and the two `.md` bodies are reduced independently to each platform's idiomatic form (a `.toml` `developer_instructions` string vs a `.md` section layout) — they need NOT end byte-equal.
- Preserve per-platform structure (frontmatter fields, the `.toml` keys, the plugin-bundle layout) — the §A method already excludes frontmatter (Check 1) and structure from the reducible set.
- The trinity-rule parallel edit applies at the SEMANTIC level: a substantive rule edit to one family's body lands in the other two (the rule the trinity enforces is parity of MEANING, not bytes — exactly what compare-agent-trinity.py / Check 11 measure leniently).

### 7.2 PRESERVE the Check-56 28-verb + catch-all invariant (the load-bearing agent invariant)

Check 56 measures the FULL §5.1 destructive-git-verb denylist (28 verbs: commit, push, stash, reset, restore, checkout, clean, merge, rebase, cherry-pick, revert, apply, switch, worktree, update-ref, update-index, pull, filter-branch, replace, add, rm, mv, config, remote, gc, tag, notes, am) + the catch-all phrase `including but not limited to` present in ALL 10 verb-parity surfaces — including the 3 pack-coder agent surfaces (`.claude/agents/pack-coder.md`, `.codex/agents/pack-coder.toml`, `.agents-plugin/pack-agents/agents/pack-coder.md`). The CB-05 reduction of pack-coder in EACH family MUST keep the full verb enumeration + the catch-all phrase intact — these are S3 irreducible-enumeration content (dropping a verb narrows the ban = a meaning change, forbidden by the A.2 invariant set). The A.5 example-removal log must NOT touch the verb list.

**Verification.** CB-05's full-battery PREFLIGHT runs Check 56 (which reads all 10 surfaces) — a dropped verb or a broken catch-all phrase FAILs Check 56 immediately, before the patch. This is the existing teeth; no new agent gate is needed for the verb invariant.

### 7.3 Pattern-fit justification (pattern-matching-out-of-context-antipattern)

The skill gate (Check 71, byte-identity FAIL) and the agent posture (Check 11 lenient + Check 56 semantic-presence) are DELIBERATELY DIFFERENT, property-fit not pattern-copied:
- **Skills want byte-identity** because the user ruled them identical AND they share ONE format (`SKILL.md` Markdown) across all 3 CLIs — byte-equality is achievable and is the strongest, cheapest invariant. Check 71 is a byte-compare (FAIL on any difference).
- **Agents want lenient semantic parity** because the user ruled them per-platform-best AND they are 3 DIFFERENT formats (md/toml/md) — byte-identity is impossible (a `.toml` can never byte-equal a `.md`), so the agent invariants are (a) Check 56's verb-set PRESENCE (semantic, whitespace-normalized, spans formats) + (b) Check 11's lenient body-parity COUNT (informational). Reusing compare-agent-trinity.py / Check 11 for SKILLS would be the anti-pattern: it normalizes away exactly the byte-differences the skill ruling forbids. Reusing Check 71's byte-compare for AGENTS would be the anti-pattern: it would FAIL on the unavoidable md-vs-toml difference. Each gate's mechanism is chosen for its surface's property, not copied across.

**EE-AGENTS — agent mirrors clean + the verb invariant present in all 3 pack-coder surfaces @ `e1cd5df`.**
- Cmd: `grep -rlE 'incident|BD-[0-9]|pack tracker' .claude/agents .codex/agents .agents-plugin/pack-agents/agents`; `grep -c 'worktree' .claude/agents/pack-coder.md .codex/agents/pack-coder.toml .agents-plugin/pack-agents/agents/pack-coder.md`; read `_CHECK_56_CANONICAL_VERBS` + `_CHECK_56_PRINCIPLE_PHRASE`.
- Output (verbatim): all 3 agent families → ZERO contamination hits; pack-coder `worktree` mentions = 8/.claude, 7/.codex, 8/.agents-plugin (all carry the worktree-denial content); `_CHECK_56_CANONICAL_VERBS` = the 28-verb set; `_CHECK_56_PRINCIPLE_PHRASE = "including but not limited to"`; both measured present in all 10 surfaces (the comment records S-1 widened to 27, N-2 added `am`).
- HEAD/date: `e1cd5df` / 2026-06-22.
- Interpretation: agents have NO back-fill gap (clean); the verb invariant is live across all 3 pack-coder surfaces; CB-05's per-platform reduction must preserve it (S3 enumeration); Check 56 enforces it at PREFLIGHT. No byte-identity gate for agents (wrong property — 3 formats).
- Conclusion: **SUPPORTED.**

---

## 8. OPEN RISKS / DECISIONS FOR THE USER

- **D-1 (pack-startup graphify cross-CLI).** This design RULES the graphify Step-5 block cross-CLI (present in all 3 skill mirrors after unification) — REQUIRED by the user's byte-identity ruling + the no-meaning-loss invariant (§1.3). If the user instead wants the graphify block Claude-ONLY, the byte-identity ruling would have to be relaxed for pack-startup specifically — a contradiction the user must adjudicate. RECOMMENDATION: keep it cross-CLI (the block is CLI-agnostic; graphify serves any pack-dev session). Surfaced because it is the one place "byte-identity" forces a content decision.
- **D-2 (Check 71 number).** Assigned the next free integer after V4's 70 (= 71); if the planner registers in a different order, the NUMBER may shift but the COUNT delta is fixed at +1. The coder assigns the next free integer at registration; number ≠ count (V4 §2 CAUTION).
- **D-3 (lenient-absent posture).** Check 71 skips a WHOLLY-ABSENT mirror tree (init/state problem) but FAILs a present-but-divergent mirror. This matches Check 65's lenient-absent. If the user wants a missing mirror tree to FAIL (stricter), that is a one-line change — but the pack always ships all 3 trees, so the absent case is a fresh-clone/init artifact, not a real state.
- **R-1 (count-bump lock-step, now 6 checks).** Check 71 makes the CG-14 atomic bump 63→69 (+6 entries) — one more entry than V4's +5, one more chance to drop an entry, and the check-64 literal is now `63→69`. MITIGATION: the V4 registration-deferral mechanism (author unregistered, register-all-at-CG-14) + the full-battery PREFLIGHT exercising check-64's test BEFORE the patch. RESIDUAL: low if §5.3 is followed.
- **R-2 (CB-04 scope-keyword).** CB-04 is `pack-only` (all 33 paths pack-root). HAZARD: do NOT let the Check-71 body (a `scripts/validate-pack.py` edit) leak into CB-04 — the gate body lands at the gate wave, keeping CB-04 cleanly `pack-only` skill-content. RESIDUAL: low (membership §6.1 is explicit).
- **R-3 (Check 56 verb invariant during byte-copy).** Byte-copying a verb-complete `.claude/skills/commit-discipline` to the mirrors preserves the verb set (a byte-copy cannot drop a verb); the CB-04 bloat reduction of `.claude` commit-discipline must keep the §3 verb-ban enumeration (S3) — Check 56 reads all 3 mirrors at PREFLIGHT and FAILs on a regression. RESIDUAL: low.

---

## 9. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only verbs ran: `git rev-parse HEAD`/`git branch --show-current`/`git status --short`/`git log --oneline` (snapshot), `diff -q`/`diff`, `grep`/`grep -rl`, `wc -l`, `ls`, `find`, `sed`, `python3 scripts/validate-pack.py` (read-only validation). Sole write = this design doc via `cat >`/`cat >>` to the caller-specified `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-SKILL-MIRROR-UNIFICATION.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by EE-PACKSTARTUP / EE-CANON / EE-BACKFILL / EE-EXISTING / EE-GATE-PROJECTED / EE-AGENTS: command + verbatim output (counts/paths/diffs/quotes) + HEAD `e1cd5df` + 2026-06-22 + interpretation + SUPPORTED. The divergence map (§1.1), the count-encoding surfaces (§5.3, check-64 literal `63` at lines 74-75/82 measured), and the projected post-fix gate state (§5.5) are each measured, not asserted. | COMPLIANT |
| **ci-guard-measure-then-bound** | Check 71 designed by the 5-step contract (§5.1): (1) MEASURED — 6/11 skills diverge, all in `.codex`/`.agents`; (2) CATEGORIZED — all 6 STRIP (no legitimate skill divergence; byte-identity is absolute, no allowlist); (3) FIX — CB-04 reduce-`.claude`+byte-copy resolves all 6; (4) SIZED — exactly 3 trees × the canonical skill set, no allowlist, no project mirrors; (5) VERIFIED — runs CLEAN against the projected post-CB-04 state (EE-GATE-PROJECTED, all 11 byte-equal triples). | COMPLIANT |
| **researcher-maps-blast-radius / external-rules-census-before-design** | Censused the COMPLETE pack-root mirror surface set BEFORE concluding: pack skills ×3 (`.claude`/`.codex`/`.agents/skills`, 11 each), pack agents ×3 (`.claude/agents`/`.codex/agents`/`.agents-plugin/pack-agents/agents`, 5 each); measured byte-divergence (6 skills) + contamination (same 6) + agent cleanliness (all 3 clean). Censused the existing mirror-aware checks (51/52/56/11, §3) before declaring the gate a gap. Project mirrors EXCLUDED per the pack-side-only scope. | COMPLIANT |
| **enumerate-encoding-surfaces** | §5.3 enumerates ALL count-encoding surfaces for the +1 (63→69): S1 constant, S2 registry entry, S3 ledger, S3b stale prose, S4 hardcoded check-64 literal (the load-bearing trap, `63→69`), S5 NEW dynamic-form per-check test, S6 ci-shard-plan glob, S7 Check 59, S8 Check 60 — each with file:line + value + miss=CI-fail flag. §6.3 folds the +1 into V4's atomic bump (63→68 becomes 63→69). | COMPLIANT |
| **operating-docs-no-history-no-bloat** | The unification leaves every shipped skill mirror byte-equal to the history-clean + bloat-reduced `.claude` canonical (§2 sufficiency: byte-equal to grep-zero ⇒ grep-zero); the stale deferred/reserved-Step + history + tracker content is DROPPED (EE-PACKSTARTUP). The design itself states only current state (no roadmap-as-feature). | COMPLIANT |
| **no-deferral-without-user-direction / deferral-is-scope-creep** | The full mirror fix lands in BD-243 v11.0: skill unification at CB-04, agent reduction at CB-05, the durable gate at CG-14. Nothing deferred to v11.1+. The pack-side scope correction (drop project mirrors) is a SCOPING decision (handled separately in project waves), not a deferral of pack-side work. | COMPLIANT |
| **skill-agent-maintenance-mechanical** | Post-fix maintenance is mechanical: the byte-identity gate (Check 71, FAIL) makes skill drift impossible (any divergence FAILs CI); the canonical-once + propagate rule (§4) keeps reduction mechanical (reduce one, `cp` to two). The client `x-` skill contract is untouched (this design is pack-root mirrors only; project `x-` skills are out of scope). | COMPLIANT |
| **pattern-matching-out-of-context-antipattern** | §7.3 justifies the gate's design as property-fit: skills get a byte-compare FAIL (one format, identity ruling); agents get lenient semantic-presence (3 formats, per-platform ruling); reusing compare-agent-trinity.py for skills (normalizes away forbidden byte-diffs) or Check 71 for agents (FAILs on unavoidable md-vs-toml) would each be the anti-pattern. | COMPLIANT |
| **graph-first-context** | Discovery intent was graph-first; the graph is STALE for BD-243-era surfaces (built before `e1cd5df`) so per G2 every exact-state claim is grep/`diff`/Read/`wc -l`-authoritative over the named surfaces (byte-identity + count surfaces are byte-precise questions the graph cannot answer). Did not block on the graph; did not recompute a path from own toplevel. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — DESIGN-BD-243-SKILL-MIRROR-UNIFICATION.md (pack-side only)**
