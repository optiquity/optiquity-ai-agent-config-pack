# PLAN — BD-243 SKILL-MIRROR INTEGRATION (folds the approved skill-mirror design into the BD-243 commit sequence, reconciled with V4)

Planner: FRESH planner instance (pack-planner, RO). I did NOT author the skill-mirror DESIGN, PLAN-V4, or PLAN-V2; conclusions are my own (reconciliation-instance-independence). I independently re-measured every load-bearing fact at runtime.
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`934a8a7`** (verified at runtime — `git rev-parse HEAD` = `934a8a70c09d351560e91825a0d086976722e5bf`; working tree clean except untracked plan/review docs), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: **PLANNER-READY** — goes to the user at the planner-to-coder gate (planner-output-user-review); NOT auto-approved into a coder spawn. The user's last cheap redirect window before CB-04's coder spawns.
Scope: **PACK-SIDE ONLY.** This plan re-scopes CB-04 (pack skills → tri-mirror-locked) + CB-05 (pack agents → tri-family), integrates the new Check 71 (skill-mirror byte-identity gate), and reconciles the count arithmetic to **63 → 69**. Project-side mirror work (CB-07/08/09, and the install-generated project skills) is a Wave-2 item — flagged, NOT planned here.

---

## 0. EXECUTIVE ANSWER (decision-ready commit list)

**What this plan changes vs PLAN-V4:**
- **CB-04 re-scopes** from `.claude/skills` (11 files) to **TRI-MIRROR-LOCKED (33 files)**: per skill, reduce `.claude` per the approved §A S-test, then byte-copy to `.codex`/`.agents`; the 3 files per skill land as ONE unit. `pack-only`. 11 independent tri-mirror work-units, parallel across distinct files.
- **CB-05 re-scopes** from `.claude/agents` (5 files) to **TRI-FAMILY (15 files)**: per agent, reduce each of the 3 families in ITS OWN format (NO byte-identity — md/toml/md), preserving the Check-56 28-verb + catch-all invariant in the 3 pack-coder surfaces. `pack-only`. 5 independent tri-family work-units, parallel.
- **Check 71** (`check_pack_skill_mirror_identity`, FAIL, byte-identity gate) is ADDED to the gate wave. Its BODY is authored at **CG-14-prep-b** (unregistered, alongside V4's Check 66/67/68/70 bodies); it REGISTERS at **CG-14** (the atomic count event).
- **The count bump becomes `63 → 69` (6 new checks)**, NOT V4's `63 → 68` (5 checks). Check 71 is the 6th new registry entry.

**The reconciled commit list (pack-side, post-HEAD `934a8a7`):**

| Seq | Commit | Scope kw | Files | Lands |
|---|---|---|---|---|
| (landed) | CB-01/02/03/06 | pack-only | pack-ops docs, RATIONALE, stream-meta _rules, pack-root trinity | DONE @ `934a8a7` |
| 1 | **CB-04** (re-scoped) | `pack-only` | 33 skill files (`.claude`/`.codex`/`.agents` skills ×11) | tri-mirror-locked per skill |
| 2 | **CB-05** (re-scoped) | `pack-only` | 15 agent files (`.claude/.md` + `.codex/.toml` + `.agents-plugin/.md` ×5) | tri-family per agent |
| — | (Wave-2: CB-07/08/09 project) | project-only | project-template — NOT planned here (Wave-2) | — |
| 3 | CG-CLIENT | project-only | `validate-docs.sh` + wiring (V4 §3.2) — Wave-2 boundary; pack-side plan ends before it | — |
| 4 | CG-14-prep-a | pack-only | `_iter_operating_docs()` + Check 69 body + Check-65 repoint + R2 + GC records (authored-unregistered) | count still 63 |
| 5 | CG-14-prep-b | pack-only | Check 66/67/68/70 bodies **+ Check 71 body** + allowlists + Gate-1 params + dangling-ref fix (authored-unregistered) | count still 63 |
| 6 | **CG-14** (re-scoped count) | pack-only | register **6** checks (66/67/68/69/70 **+71**) + bump `CHECK_REGISTRY_EXPECTED_COUNT` **63→69** + check-64 literal `63→69` (S4) + ledger/prose reconcile | ONE atomic count event |
| — | final push | — | manifest-sync → push → CI watch | (V4 §3.4) |

**The dependency edge that makes Check 71 safe:** `CB-04 → … → CG-14`. CB-04 produces the 11 byte-equal skill triples; Check 71 (registered at CG-14) measures them. CB-04 must land before Check 71 activates — the V4 sequence already guarantees all CB land before the gate wave. Check 71's BODY (authored at CG-14-prep-b) is parameter-free (byte-identity needs no value derived from the reduced tree), so it is NOT on CB-04's critical path; only its ACTIVATION is.

**The single most defect-prone item (unchanged class from V4, now +1):** the atomic count bump. With Check 71 it is **6 entries** at CG-14 — one more chance to drop an entry, and **`scripts/tests/test-validate-pack-check-64.sh`'s hardcoded literal becomes `63 → 69`** (the load-bearing trap). The new `test-validate-pack-check-71.sh` uses the DYNAMIC count form, NEVER a second hardcoded literal. Atomic lock-step: S1 (constant `=69`) + S2 (6 registry entries) + S4 (check-64 literal `69`) in ONE commit (CG-14); S3/S3b (ledger + stale prose) ride it.

**Per-commit verification = the FULL wired battery** (`ci-shard-plan.py` all shards + `validate-pack.py` no-flag + the relevant per-check tests INCLUDING the count-invariant tests) BEFORE each commit's patch — the prior CI failure came from a SUBSET verify (verify-full-ci-suite).

---

## 1. STATE BASELINE (measured @ `934a8a7`)

The bloat phase is mid-flight: CB-01/02/03/06 LANDED; CB-04/CB-05 NOT yet landed (the skill divergence is still present — see EE-DIVERGE). The gate is registered-but-inert; count is `63`; tree is GREEN.

**EE-BASE — state baseline @ `934a8a7`.**
- Cmd: `git rev-parse HEAD; git log --oneline -1; python3 scripts/validate-pack.py | tail -2; grep -n 'CHECK_REGISTRY_EXPECTED_COUNT = ' scripts/validate-pack.py`
- Output (verbatim, key): `934a8a70c09d351560e91825a0d086976722e5bf`; `934a8a7 feat: v11 — BD-243 bloat-reduce pack-root trinity (CB-06) (pack-only)`; `PASSED — all checks clean`; `496:CHECK_REGISTRY_EXPECTED_COUNT = 63`.
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: CB-01/02/03/06 landed; tree green; EXPECTED_COUNT 63; gate inert. CB-04/CB-05 + the gate wave are the remaining pack-side work this plan covers.
- Conclusion: **SUPPORTED.**

**EE-LANDED — files touched by the already-landed CB commits (disjointness baseline) @ `934a8a7`.**
- Cmd: `git show --name-only --format= c019e32 72553df e1cd5df 934a8a7`
- Output (verbatim): CB-01 (`c019e32`) → `pack-ops/{BOUNDARY-DEFINITION,CONCEPTUAL-REVIEW-METHODOLOGY,DRY-RUN-MIGRATION,MERGE-STRATEGY,OPTIONAL-FEATURES,PACK-AGENTS,PACK-CHAT}.md` + `scripts/validate-pack.py`; CB-02 (`72553df`) → `pack-ops/PACK-MEMORY-RATIONALE.md`; CB-03 (`e1cd5df`) → `backlog/_rules.md` + `changelog/_rules.md`; CB-06 (`934a8a7`) → `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` (pack-root).
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: NONE of the landed commits touched any skill mirror dir (`.claude/.codex/.agents/skills`) or any agent family dir (`.claude/agents`, `.codex/agents`, `.agents-plugin/pack-agents/agents`). CB-04's 33 skill files and CB-05's 15 agent files are file-disjoint from every landed commit. NOTE: CB-01 already edited `scripts/validate-pack.py` (the OPTIONAL ceiling re-derive) — so CB-04/CB-05 must NOT touch validate-pack.py (the gate body lands at the gate wave). 
- Conclusion: **SUPPORTED.**

---

## 2. CB-04 RE-SCOPE — TRI-MIRROR-LOCKED (33 files) — DETAIL

### 2.1 Membership (the exact 33 files)

`.claude/skills/<s>/SKILL.md` (11) + `.codex/skills/<s>/SKILL.md` (11) + `.agents/skills/<s>/SKILL.md` (11) = **33 files**, for the 11 skills:
`architecture-review`, `boundary-investigation`, `commit-discipline`, `dependency-intake`, `documentation`, `implementation-report`, `pack-help`, `pack-startup`, `planning`, `review`, `verification-harness`.

**EE-MEMBER — the 33-file membership + the 11 skill names @ `934a8a7`.**
- Cmd: `ls .claude/skills/ | sort; ls .claude/skills/*/SKILL.md | wc -l; ls .codex/skills/*/SKILL.md | wc -l; ls .agents/skills/*/SKILL.md | wc -l`
- Output (verbatim): 11 dir names (the list above); `.claude` 11, `.codex` 11, `.agents` 11 → 33 SKILL.md files.
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: all 11 skills exist in all 3 mirrors; the tri-mirror membership is exactly 33 files; no skill missing from any mirror.
- Conclusion: **SUPPORTED.**

### 2.2 The current divergence (what CB-04 must resolve)

@ `934a8a7`, 5 skills are byte-IDENTICAL across all 3 mirrors (no-ops that stay identical after `.claude` reduction is re-propagated); **6 skills DIVERGE** (`.claude` clean-canonical; `.codex`==`.agents` stale): `commit-discipline`, `implementation-report`, `pack-help`, `pack-startup`, `review`, `verification-harness`. These 6 are exactly the contamination set (the stale mirrors carry `incident|BD-[0-9]|pack tracker` that `.claude` lacks).

**EE-DIVERGE — the 6 divergent skills + contamination set @ `934a8a7`.**
- Cmd: per-skill `diff -q .claude/skills/<s>/SKILL.md .codex/...` + `... .agents/...`; `grep -rlE 'incident|BD-[0-9]|pack tracker' .codex/skills .agents/skills`
- Output (verbatim): IDENTICAL×3 = {architecture-review, boundary-investigation, dependency-intake, documentation, planning}; DIVERGE = {commit-discipline, implementation-report, pack-help, pack-startup, review, verification-harness} (each differs `.claude`-vs-`.codex` AND `.claude`-vs-`.agents`); contamination hits = the same 6 in BOTH `.codex/skills` and `.agents/skills` (12 file paths total), ZERO in `.claude/skills`.
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: the divergence set == the contamination set == 6 skills, all stale in `.codex`/`.agents`. CB-04 reduces `.claude` (canonical) and byte-copies to the 2 mirrors, simultaneously dropping contamination (for the 6) and propagating the reduced content (for all 11). Matches the design §1.1 map exactly.
- Conclusion: **SUPPORTED.**

### 2.3 The per-skill work-unit (tri-mirror lock)

For each skill `<s>` (one logical unit, all 3 files in ONE commit — CB-04):
1. **Reduce `.claude/skills/<s>/SKILL.md`** per the approved §A S-test (KEEP if S1 concrete-shape / S2 edge-case / S3 irreducible-enumeration; REMOVE only pure redundant illustration), NEVER touching the A.2 invariant set (guardrails / rules / triggers / exceptions / in-out-of-scope / frontmatter). (Method ALREADY specified — PLAN-V2 §3.1; reference, do not redefine.)
2. **Run the A.5 verification on the `.claude` reduction**: invariant-set diff EQUAL + example-removal justification log + retention spot-check + Check 1 frontmatter intact. (PLAN-V2 §3.1.)
3. **Byte-copy** the reduced `.claude/skills/<s>/SKILL.md` over `.codex/skills/<s>/SKILL.md` AND `.agents/skills/<s>/SKILL.md` (`cp`, exact bytes).
4. The mirrors need NO separate A.5 proof — they are byte-equal to the proven-clean canonical (Check 71, §4, is their structural proof).

**pack-startup special case (D-1 already DECIDED):** the `.claude` canonical carries the graphify "Step 5 — Graph freshness" block (CLI-agnostic) that the stale `.codex`/`.agents` copies LACK; byte-copying `.claude` makes that block cross-CLI (the user-approved D-1 ruling) AND drops the stale `Steps 5–7 are reserved` / `Step 8 … (deferred)` blocks mechanically. The coder does NOT relitigate D-1 — the byte-copy of the clean `.claude` realizes it.

### 2.4 Reduce-ONCE-then-propagate (the only correct method under D-1)

The mirrors are NEVER independently bloat-reduced — two independent S-test passes could legitimately keep/remove different borderline examples and produce byte-DIFFERENT (but each valid) results, violating byte-identity. Reduce `.claude` once, run A.5 once, `cp` to two. This also halves the reviewer's A.5 load (one invariant-set diff per skill, not three). (Design §4.)

### 2.5 Scope-keyword cleanliness (Check 36 — `pack-only`)

All 33 paths are pack-root mirrors (outside `project-template/` + `supporting-docs/`), so Check 36's `pack-only` deny-set is satisfied. **HAZARD (R2 from design):** CB-04 must NOT touch `scripts/validate-pack.py` — the Check 71 body lands at CG-14-prep-b. If the Check-71 body leaked into CB-04 it would still be `pack-only` (validate-pack.py is pack-side) but it would break the authored-unregistered gate-wave concentration and the count-bump atomicity. Keep CB-04 strictly skill-content.

### 2.6 CB-04 parallelization map (rule-10)

11 independent tri-mirror work-units, one per skill. No two units share a file (each unit owns exactly its skill's 3 files). So all 11 units are PARALLEL across distinct files within CB-04's worktree — the scheduler can fan out 11 reduce-then-copy units, then assemble ONE `pack-only` commit. (Design §6.4: "11 independent tri-mirror skill units, parallel across distinct files.")

### 2.7 CB-04-specific verification (in addition to the §6 full battery)

The CB-04 coder PREFLIGHT runs ALL of:
- **Per-skill tri-mirror `diff` empty:** `for s in .claude/skills/*/; do n=$(basename $s); diff .claude/skills/$n/SKILL.md .codex/skills/$n/SKILL.md && diff .claude/skills/$n/SKILL.md .agents/skills/$n/SKILL.md; done` → all empty (11 byte-equal triples). This is the projected post-CB-04 state Check 71 will assert.
- **Grep-zero contamination in the mirrors:** `grep -rlE 'incident|BD-[0-9]|pack tracker' .codex/skills .agents/skills` → ZERO (byte-equal to the grep-zero `.claude` ⇒ grep-zero by construction).
- **A.5 contract on `.claude`:** invariant-set diff EQUAL (`git show HEAD:<skill>` vs post) + example-removal log + retention spot-check + Check 1 frontmatter intact, per skill reduced.
- **Check 56 survives in the 3 commit-discipline mirrors:** Check 56 reads `.claude/skills/commit-discipline/SKILL.md` + `.codex/skills/commit-discipline/SKILL.md` + `.agents/skills/commit-discipline/SKILL.md` (3 of its 10 surfaces). A byte-copy of a verb-complete reduced `.claude` keeps the 28-verb denylist + catch-all phrase intact; the full-battery PREFLIGHT (which runs Check 56 over all 10 surfaces) FAILs immediately on a regression. The §A reduction of `.claude/skills/commit-discipline` MUST keep the verb enumeration (S3 irreducible-enumeration — a dropped verb narrows the ban = meaning change, forbidden by A.2).

**EE-CHECK56-CDISC — Check 56 reads the 3 commit-discipline skill mirrors @ `934a8a7`.**
- Cmd: `sed -n '9395,9406p' scripts/validate-pack.py` (the `_CHECK_56_VERB_PARITY_SURFACES` tuple)
- Output (verbatim, key): the tuple includes `".claude/skills/commit-discipline/SKILL.md"`, `".codex/skills/commit-discipline/SKILL.md"`, `".agents/skills/commit-discipline/SKILL.md"` (3 of the 10 surfaces; the other 7 = pack trinity ×3, RATIONALE, pack-coder ×3).
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: CB-04's byte-copy of the reduced `.claude/skills/commit-discipline` to the 2 mirrors is read by Check 56 across all 3; a full-battery PREFLIGHT catches a dropped verb / broken catch-all. No separate skill-verb gate needed.
- Conclusion: **SUPPORTED.**

---

## 3. CB-05 RE-SCOPE — TRI-FAMILY per pack agent (15 files) — DETAIL

### 3.1 Membership (the exact 15 files)

Per the 5 pack agents (`pack-architect`, `pack-coder`, `pack-docs-researcher`, `pack-planner`, `pack-reviewer`):
- `.claude/agents/pack-<a>.md` (5, Markdown + YAML frontmatter)
- `.codex/agents/pack-<a>.toml` (5, TOML, body in `developer_instructions`)
- `.agents-plugin/pack-agents/agents/pack-<a>.md` (5, Antigravity plugin-bundle Markdown)
= **15 files**.

**EE-AGENT-MEMBER — the 15-file agent membership + agent cleanliness @ `934a8a7`.**
- Cmd: `ls .claude/agents/pack-*.md; ls .codex/agents/pack-*.toml; ls .agents-plugin/pack-agents/agents/pack-*.md; grep -rlE 'incident|BD-[0-9]|pack tracker' .claude/agents .codex/agents .agents-plugin/pack-agents/agents`
- Output (verbatim): `.claude/agents` 5 `.md`; `.codex/agents` 5 `.toml`; `.agents-plugin/pack-agents/agents` 5 `.md` (15 files); contamination grep → ZERO in all 3 families.
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: agents have NO back-fill gap (all 3 families already clean — kept in sync during the strip phase). CB-05 is pure bloat reduction (per-platform), not a back-fill. Byte-identity is NOT the property (3 formats: md/toml/md).
- Conclusion: **SUPPORTED.**

### 3.2 The per-agent work-unit (tri-family, NO byte-identity)

For each agent `<a>` (one logical unit, all 3 family files in ONE commit — CB-05):
1. **Reduce each family's body PROSE in its own format** per the §A S-test — reduce padding/redundant illustration, keep S1/S2/S3 content + the A.2 invariant set. The `.toml` `developer_instructions` string and the two `.md` bodies are reduced INDEPENDENTLY to each platform's idiomatic form; they need NOT end byte-equal (design §7.1).
2. **Preserve per-platform structure** (frontmatter fields, `.toml` keys, plugin-bundle layout — §A already excludes frontmatter (Check 1) and structure from the reducible set).
3. **Trinity-rule parallel edit at the SEMANTIC level:** a substantive rule edit to one family's body lands in the other two (the trinity rule enforces parity of MEANING, not bytes — what `compare-agent-trinity.py` / Check 11 measure leniently).

### 3.3 PRESERVE the Check-56 28-verb + catch-all in the 3 pack-coder surfaces

Check 56 asserts the 28-verb denylist (`commit, push, stash, reset, restore, checkout, clean, merge, rebase, cherry-pick, revert, apply, switch, worktree, update-ref, update-index, pull, filter-branch, replace, add, rm, mv, config, remote, gc, tag, notes, am`) + the catch-all phrase `including but not limited to` present in ALL 10 surfaces — INCLUDING the 3 pack-coder surfaces (`.claude/agents/pack-coder.md`, `.codex/agents/pack-coder.toml`, `.agents-plugin/pack-agents/agents/pack-coder.md`). CB-05's reduction of pack-coder in EACH family MUST keep the full verb enumeration + the catch-all phrase intact (S3 irreducible-enumeration; dropping a verb narrows the ban = forbidden by A.2). The A.5 example-removal log must NOT touch the verb list.

**EE-CHECK56-VERBS — the 28-verb set + catch-all + the 3 pack-coder surfaces @ `934a8a7`.**
- Cmd: `sed -n '9395,9436p' scripts/validate-pack.py`
- Output (verbatim, key): `_CHECK_56_VERB_PARITY_SURFACES` includes `.claude/agents/pack-coder.md`, `.codex/agents/pack-coder.toml`, `.agents-plugin/pack-agents/agents/pack-coder.md`; `_CHECK_56_CANONICAL_VERBS` = the 28-verb tuple (19 base + 8 S-1 additions `add/rm/mv/config/remote/gc/tag/notes` + 1 N-2 addition `am`); `_CHECK_56_PRINCIPLE_PHRASE = "including but not limited to"` (matched whitespace-normalized, so a line-wrap in the Antigravity bundle still counts).
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: the verb invariant is live across all 3 pack-coder surfaces; CB-05's per-platform reduction must preserve it; Check 56 (read in the full-battery PREFLIGHT) FAILs immediately on a dropped verb / broken catch-all. No new agent gate needed.
- Conclusion: **SUPPORTED.**

### 3.4 No new agent gate (Check 11 + Check 56 already cover agents)

Byte-identity is the WRONG property for agents (a `.toml` can never byte-equal a `.md`). Check 11 (lenient body-parity COUNT, informational) + Check 56 (28-verb semantic-presence, FAIL) already cover agents. CB-05 adds NO new gate (design §7).

### 3.5 CB-05 scope keyword + parallelization

`pack-only` (all 15 paths pack-root). 5 independent tri-family work-units, parallel across distinct files (no two agents share a file). Each agent's 3 family files land as one tri-family unit (the trinity-rule parallel edit at the semantic level).

### 3.6 CB-05-specific verification (in addition to the §6 full battery)

- **Check 56 survives in all 3 pack-coder surfaces:** the full-battery PREFLIGHT runs Check 56 over all 10 surfaces — a dropped verb / broken catch-all in any pack-coder family FAILs before the patch.
- **Check 11 informational:** `compare-agent-trinity.py --all` lenient parity count (always-OK; informational — a divergence count rise is a SHOULD-review, not a FAIL).
- **A.5 contract per family** (invariant-set diff EQUAL + example-removal log + retention spot-check + Check 1 frontmatter intact), applied per family's reduction (NOT a cross-family byte diff — agents are not byte-identical).
- **Agent cleanliness preserved:** `grep -rlE 'incident|BD-[0-9]|pack tracker' .claude/agents .codex/agents .agents-plugin/pack-agents/agents` → still ZERO post-CB-05 (the reduction must not RE-introduce contamination).

---

## 4. CHECK 71 INTEGRATION — `check_pack_skill_mirror_identity` (byte-identity gate, FAIL)

### 4.1 Where the BODY is authored + where it REGISTERS

- **BODY authored at CG-14-prep-b** (the design's CG-14-prep-b instruction): `check_pack_skill_mirror_identity` + `_CHECK_71_SKILL_MIRROR_DIRS = (".claude/skills", ".codex/skills", ".agents/skills")` (canonical = `.claude/skills` = index 0; reuses the exact dir set Check 51 lists) + a NEW `scripts/tests/test-validate-pack-check-71.sh`. Authored alongside V4's Check 66/67/68/70 bodies — all **authored-UNREGISTERED** (defined but NOT in `CHECK_REGISTRY`; count stays 63). Verifiable while unregistered via `--only-check 71` (passes against the post-CB-04 byte-equal triples).
- **REGISTERS at CG-14** (the atomic count event): append `(71, "check_pack_skill_mirror_identity", check_pack_skill_mirror_identity, W)` to `CHECK_REGISTRY` as the 6th new entry.
- **Behavior:** for each `<s>` in `.claude/skills` (the canonical set), compare the bytes of `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md` to `.claude/skills/<s>/SKILL.md`; any byte-difference (or missing/extra mirror file) FAILs with `<s>` + which mirror + a "re-propagate the reduced canonical" remediation. Lenient ONLY on a wholly-absent mirror tree (init artifact); a PRESENT-but-divergent mirror FAILs. (Design §5.3 — ALREADY specified; reference.)
- **Runtime cost:** reads 33 small files once + byte-compares (no regex, no subprocess) — trivial across the ~155 battery invocations; far cheaper than the alternative (re-running Check 65's 11 regexes over 22 more files). The gate-the-canonical-once + assert-identity composition (Check 65 scans `.claude`; Check 71 asserts the 2 mirrors == `.claude`) gives "all three clean AND identical" at lower cost than triple-scanning (design §5.2).

### 4.2 The COUNT arithmetic reconciliation — V4's `63→68` becomes `63→69`

V4 bumped `63 → 68` (5 new checks: 66/67/68/69 + parity-70). Check 71 is the **6th** new registry entry, so the bump becomes **`63 → 69`**. The check NUMBERS are 66/67/68/69 + parity (70 if assigned sequentially) + skill-mirror (71); the COUNT delta is the entry-count = **+6** (number ≠ count — Checks 16/18/19 register twice + 2 checks carry number=None, so the count lags the max number; the CAUTION at validate-pack.py:489-495 states this).

**The 6 new checks (each +1 registry entry, +6 total):**
1. Check 66 — `check_operating_doc_bullet_concision` (Gate 1b).
2. Check 67 — `check_operating_doc_no_deferred_feature` (Gate 2).
3. Check 68 — `check_dangling_file_refs` (Gate 3).
4. Check 69 — `check_operating_doc_scope_completeness` (Gate 4).
5. Check 70 — `check_client_doc_gate_parity` (DC-2, polices the client gate).
6. **Check 71 — `check_pack_skill_mirror_identity` (NEW — skill-mirror byte-identity).**

(Gate 1a Check-44 advisory→FAIL + R2 Check-65 `incident` tighten are in-place edits to EXISTING checks = +0 registry entries.)

### 4.3 ALL count-encoding surfaces (enumerate-encoding-surfaces) — re-measured @ `934a8a7`

| # | Surface | File:line @ `934a8a7` | Current | Required at CG-14 (+6) | Mechanism | Miss = CI fail? |
|---|---|---|---|---|---|---|
| S1 | The constant | `scripts/validate-pack.py:496` (`CHECK_REGISTRY_EXPECTED_COUNT = 63`) | `63` | **`= 69`** | literal | **YES — Check 59 FAILs** |
| S2 | The **6** new `CHECK_REGISTRY` entries | registry tail | (absent) | append 66/67/68/69/70 **+71** | registry tuples | YES — count won't reach 69 without all 6 |
| S3 | EXPECTED_COUNT comment ledger | `scripts/validate-pack.py:475-495` | sums to 63 | add **6** `+1 net-new` lines (incl. `+1 net-new BD-243 Check 71 skill-mirror identity`); update CAUTION `(65 for BD-243)` → note 66-71 | comment | NO (doc) — required for audit |
| S3b | stale prose "62 entries" | `scripts/validate-pack.py:476` ("the registry now holds 62 entries") | says `62` (already stale; constant is 63) | reconcile to **69** | comment prose | NO (doc) — fix in same commit |
| S4 | **hardcoded-literal test** | `scripts/tests/test-validate-pack-check-64.sh:74` (`!= 63`), `:75` (`FAIL_COUNT_NOT_63`), `:82` (pass-msg `(== 63)`) | hardcodes `63` | **`!= 69` / `FAIL_COUNT_NOT_69` / `(== 69)`** | literal in `.sh` | **YES — THE load-bearing trap (recent-failure class)** |
| S5 | per-check test (NEW) | `scripts/tests/test-validate-pack-check-71.sh` (does NOT exist @ `934a8a7`) | (absent) | NEW file, **DYNAMIC count form** (`len(_build_check_registry()) != CHECK_REGISTRY_EXPECTED_COUNT` + `71 in nums`) — NEVER a 2nd hardcoded literal | code | YES if mis-shaped |
| S6 | ci-shard-plan test discovery | `scripts/lib/ci-shard-plan.py` `parse_wired_tests()` globs `scripts/tests/*.sh` minus `ci-test-wiring-allowlist.txt` (EXCLUDE list) | dynamic glob | self-satisfies (new test matches `scripts/tests/*.sh`; NO allowlist edit — the allowlist is EXCLUDE-only) | code (no edit) | auto |
| S7 | Check 59 runtime assertion | `check_registry_completeness` (`n != CHECK_REGISTRY_EXPECTED_COUNT` @ validate-pack.py:7188) | dynamic | self-satisfies once S1+S2 land together | code (no edit) | auto (FAILs if S1/S2 out of sync) |
| S8 | Check 60 shard-coverage | `check_ci_shard_coverage` (derives partition from registry) | dynamic | self-satisfies once S2 lands | code (no edit) | auto |

**The DYNAMIC count-invariant tests that need NO value edit (VERIFY they pass, do NOT touch):** `test-validate-pack-check-62.sh:70` (`len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT`), `test-validate-pack-check-63.sh:62` (same dynamic form), `test-validate-pack-checks-58-59-60.sh:145` (`actual = len(mod._build_check_registry())` then `!= CHECK_REGISTRY_EXPECTED_COUNT`). A correct +6 bump satisfies them automatically. **The asymmetry is the trap — ONLY check-64's test hardcodes the literal `63`.**

**The NEW check-71 test MUST use the DYNAMIC form** (`if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT` + `if 71 not in nums`), matching the check-62/63 pattern — NEVER the check-64 hardcoded-`63` pattern. Minting a 2nd hardcoded literal would create a NEW trap for the next count bump. **Hard instruction to the CG-14-prep-b / CG-14 coder.**

**EE-COUNT — the count-encoding surfaces @ `934a8a7` (re-measured independently).**
- Cmd: `grep -nE "CHECK_REGISTRY_EXPECTED_COUNT|!= 63|== 63|FAIL_COUNT_NOT" scripts/validate-pack.py scripts/tests/test-validate-pack-check-64.sh scripts/tests/test-validate-pack-check-62.sh scripts/tests/test-validate-pack-check-63.sh; grep -n "62 entries" scripts/validate-pack.py; grep -cE '^\s+\([0-9]+, "check_|^\s+\(None, "check_' scripts/validate-pack.py; ls scripts/tests/test-validate-pack-check-71.sh`
- Output (verbatim, key): `validate-pack.py:496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; registry tuple count `63`; `test-validate-pack-check-64.sh:74:if mod.CHECK_REGISTRY_EXPECTED_COUNT != 63:`, `:75:    print('FAIL_COUNT_NOT_63 got', …)`, `:82:    t_pass "… count invariant holds (== 63)"`; `test-validate-pack-check-62.sh:70:if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:`; `test-validate-pack-check-63.sh:62:` (same dynamic); `validate-pack.py:476:# … so the registry now holds 62 entries:` (STALE prose); `ls scripts/tests/test-validate-pack-check-71.sh` → "No such file or directory" (the per-check test does NOT exist yet).
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: exactly ONE test hardcodes `63` (check-64 lines 74/75/82); two named tests use the dynamic form (no edit); the prose carries a stale "62" while the constant + registry tuple-count both = 63; the check-71 test must be CREATED (dynamic form). The +6 bump must edit S1 (→69), append S2 (6 entries), edit S4 (check-64 literal `63→69`), create S5 (dynamic), reconcile S3/S3b (→69).
- Conclusion: **SUPPORTED.**

### 4.4 The atomic count-bump lock-step

**S1 + S2 + S4 land in ONE commit (CG-14); S3/S3b ride it.** The registration-deferral mechanism (CG-14-prep-a/-b author all 6 bodies UNREGISTERED; CG-14 registers all 6 + bumps once) concentrates the fragile bump into ONE reviewed commit with ONE chance to get S1+S2+S4 right — verified by the full battery (which exercises check-64's test) BEFORE the patch. If S1 bumps without all 6 S2 entries, or S2 lands without S4's `69` literal, CI is RED. This is the same atomic event V4 §2 concentrates — Check 71 adds one registry entry to it (no new atomic event), changing the magnitude `+5 → +6` and the literal `68 → 69`.

---

## 5. RECONCILED SEQUENCE (where CB-04/CB-05 sit; the dependency edges; parallel-vs-dependent)

### 5.1 The full pack-side order (one line)

```
[landed: CB-01/02/03/06 @ 934a8a7]  →  CB-04 (tri-mirror skills)  ∥  CB-05 (tri-family agents)
  →  [Wave-2 project: CB-07/08/09]  →  CG-CLIENT (project-only)  →  CG-14-prep-a (pack-only)
  →  CG-14-prep-b (pack-only; bodies 66/67/68/70 + 71, unregistered)
  →  CG-14 (pack-only; ATOMIC: register 6, count 63→69, check-64 literal →69)  →  final push
```

(Wave-2 / CG-CLIENT are shown for the reader's whole-sequence picture; this PACK-SIDE plan covers CB-04, CB-05, the Check-71 body at CG-14-prep-b, and the Check-71 registration + count arithmetic at CG-14. CG-CLIENT and the project bloat commits are a separate Wave-2 plan — §8.)

### 5.2 The dependency edges

- **CB-04 ∥ CB-05** — file-disjoint (skills dirs vs agents dirs — EE-DISJOINT), no same-file contention → parallel.
- **CB-04/CB-05 vs landed commits** — file-disjoint from CB-01/02/03/06 (EE-LANDED) → no rebase/serialization concern; both base on `934a8a7`.
- **CB-04 → Check 71 (registered at CG-14)** — HARD predecessor: Check 71 measures CB-04's output (the 11 byte-equal skill triples). CB-04 must land before Check 71 ACTIVATES. The sequence guarantees it (all CB land before the gate wave).
- **Check 71 BODY (CG-14-prep-b) vs CB-04** — the body is PARAMETER-FREE (byte-identity needs no value derived from the reduced tree, UNLIKE Gate-1's ceilings which need CB-01's measured-reduced counts). So the Check-71 body authoring is NOT on CB-04's critical path; only its ACTIVATION (CG-14) depends on CB-04. (Design §6.4.)
- **CB-05 → Check 56** — Check 56 already exists and runs over CB-05's output; no NEW dependency edge (Check 56 is in-place, not part of the count bump). CB-05 must keep the verb invariant so Check 56 stays green at CB-05's own PREFLIGHT and at every later commit's full-battery run.
- **Gate wave serial bottleneck** — CG-14-prep-a → CG-14-prep-b → CG-14 stay strictly serial (all edit `scripts/validate-pack.py`). Check 71's body joins CG-14-prep-b's validate-pack.py edits; its registration joins CG-14's atomic event — NO new serialization beyond V4's.

**EE-DISJOINT — CB-04, CB-05, and the landed commits are pairwise file-disjoint @ `934a8a7`.**
- Cmd: CB-04 set = `.{claude,codex,agents}/skills/*/SKILL.md`; CB-05 set = `.claude/agents/pack-*.md` + `.codex/agents/pack-*.toml` + `.agents-plugin/pack-agents/agents/pack-*.md`; landed set (from EE-LANDED) = `pack-ops/*.md` + `scripts/validate-pack.py` + RATIONALE + `{backlog,changelog}/_rules.md` + pack-root trinity.
- Output: the three path families share NO file — `skills/` dirs ∩ `agents/` dirs = ∅; neither touches `pack-ops/`, `scripts/`, `backlog/`, `changelog/`, or the pack-root trinity. CB-04 ∩ CB-05 = ∅ (skills vs agents). CB-04 ∩ landed = ∅. CB-05 ∩ landed = ∅.
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: CB-04 ∥ CB-05 (parallel worktree wave); both base cleanly on `934a8a7`; no same-file serialization with any landed or each-other commit. The only serial dependency is the gate wave's shared validate-pack.py.
- Conclusion: **SUPPORTED.**

### 5.3 Parallel-vs-dependent map (rule-10, for Pack Chat's scheduler)

| Wave | Commits | Relationship |
|---|---|---|
| Bloat-skills/agents wave | CB-04, CB-05 | PARALLEL (file-disjoint); each is an internal fan-out (CB-04: 11 tri-mirror units; CB-05: 5 tri-family units) |
| (Wave-2 project) | CB-07/08/09 | separate plan (§8) |
| Gate prep (serial) | CG-14-prep-a → CG-14-prep-b | SERIAL (shared validate-pack.py); Check-71 body in -prep-b |
| Gate activation | CG-14 | depends on CG-14-prep-a, -prep-b, CB-04 (Check-71 target), CB-05 (no edge — Check 56 in-place), AND CG-CLIENT (Check-70 parity target, Wave-2) |

**Worktree-isolation note (universal sub-agent rule):** each commit's first coder CREATES the isolated worktree (RW agent class); the whole review/fix cycle runs inside it; the patch is produced only AFTER the reviewer confirms clean; the worktree is removed only after the commit lands (exit 0). CB-04 and CB-05 can run in parallel worktree waves (file-disjoint). The gate-prep commits serialize (shared file). Pack Chat schedules per the map.

---

## 6. PER-COMMIT VERIFICATION — the FULL wired battery (verify-full-ci-suite)

**The lesson from the prior CI failure: per-commit verification MUST run the FULL wired battery, not a subset.** Every commit (CB-04, CB-05, CG-14-prep-a, CG-14-prep-b, CG-14) verifies the FULL battery BEFORE its patch is produced. The coder PREFLIGHT line asserts the FULL-battery PASS, not a validate-pack-only PASS.

**The full battery (every commit):**
1. `python3 scripts/lib/ci-shard-plan.py` executed across ALL shards (the partition CI uses) — confirms the wired-test set is coherent and every test is shard-assigned.
2. `python3 scripts/validate-pack.py` no-flag (every REGISTERED check).
3. The relevant per-check tests `scripts/tests/test-validate-pack-check-*.sh` — INCLUDING the count-invariant tests (`test-validate-pack-check-62/63/64.sh` + `test-validate-pack-checks-58-59-60.sh`) on the gate commits.

**Per-commit specifics:**

- **CB-04 (tri-mirror skills):** full battery green (count still 63 — gate inert). PLUS §2.7: per-skill tri-mirror `diff` empty (11 byte-equal triples); grep-zero contamination in `.codex`/`.agents` skills; A.5 contract on each reduced `.claude` skill; Check 56 survives in the 3 commit-discipline mirrors (run by the no-flag validate-pack). The byte-equal triples are the projected state Check 71 will assert at CG-14.
- **CB-05 (tri-family agents):** full battery green (count still 63). PLUS §3.6: Check 56 survives in all 3 pack-coder surfaces (no-flag validate-pack runs it); Check 11 informational; A.5 contract per family; agent cleanliness preserved (grep-zero).
- **CG-14-prep-a (pack-only):** `_iter_operating_docs()` + Check 69 body + Check-65 repoint + R2 + GC-3/GC-4 records. Full battery green (count still 63 — Check 69 unregistered, exercised via `--only-check 69` + its test). `--only-check 65` exit 0 over the auto-discovered scope.
- **CG-14-prep-b (pack-only):** Check 66/67/68/70 bodies + **Check 71 body** + allowlists + Gate-1 params + dangling-ref fix. Full battery green (count still 63 — all 6 new checks unregistered). Each new check CLEAN via `--only-check NN` — **CRITICALLY `--only-check 71` passes** (CB-04 already landed → 11 byte-equal triples exist). `test-validate-pack-check-71.sh` (dynamic form) passes.
- **CG-14 (pack-only — the ATOMIC count event):** the +6 bump (S1+S2+S3+S3b+S4) — full battery green with **count == 69**; Check 59 auto-asserts count==69; Check 60 shard partition includes 66-71; **`test-validate-pack-check-64.sh` passes with `69`** (S4); all 6 new per-check tests pass (incl. `test-validate-pack-check-71.sh` dynamic); Check 71 enforces byte-identity over the live tree (PASSes — CB-04's triples are byte-equal).

**ci-check-runtime-compounding (Check 71 added):** Check 71 reads 33 small files once + byte-compares (O(skill bytes), no regex/subprocess) — trivial across ~155 battery invocations. NO whole-tree scan, NO subprocess storm. Cheaper than the triple-scan alternative it avoids.

**Bounded review/fix cycle per commit:** ≤2 review/fix pairs + 1 final reviewer = 3 reviewer / 2 fix-coder spawns max per commit; if dirty after the final reviewer, STOP and spawn pack-architect (no fix-coder pass 3). Each commit: coder → (≤2 review/fix pairs + 1 final reviewer) → user commit gate → patch produced only after reviewer-clean (RW worktree isolation).

---

## 7. OPEN RISKS / UNKNOWNS

- **R-1 (count-bump lock-step, now 6 checks).** Check 71 makes the CG-14 atomic bump `63→69` (+6 entries) — one more entry than V4's +5, one more chance to drop an entry, and the check-64 literal is now `63→69`. MITIGATION: the registration-deferral mechanism (author all 6 unregistered at prep, register-all + bump-once at CG-14) + the full-battery PREFLIGHT exercising check-64's test BEFORE the patch. RESIDUAL: low if §4.3/§4.4 are followed.
- **R-2 (CB-04 scope-keyword).** CB-04 is `pack-only` (all 33 paths pack-root). HAZARD: do NOT let the Check-71 body (a `scripts/validate-pack.py` edit) leak into CB-04 — the gate body lands at CG-14-prep-b. RESIDUAL: low (membership §2.1 is explicit; the coder prompt must name the 33 skill files only).
- **R-3 (Check 56 verb invariant during the CB-04 byte-copy + the CB-05 reduction).** CB-04: a byte-copy of a verb-complete reduced `.claude/skills/commit-discipline` to the 2 mirrors cannot drop a verb; the `.claude` reduction itself must keep the §3 verb-ban enumeration (S3). CB-05: the per-platform pack-coder reduction in each family must keep the 28-verb + catch-all. Check 56 reads all 10 surfaces at every full-battery PREFLIGHT → FAILs on a regression before the patch. RESIDUAL: low.
- **R-4 (Check 71 number ≠ count).** Check 71's NUMBER is the next free integer after V4's 70; if the coder registers in a different order the NUMBER may shift, but the COUNT delta is FIXED at +1 (so the total bump is +6 / `63→69` regardless of the number assigned). The coder assigns the next free integer at registration; number ≠ count (validate-pack.py CAUTION). RESIDUAL: none (the count is the entry-count, not the max number).
- **R-5 (Check 69 scope-completeness must not flag the mirror dirs).** Check 69 (Gate 4) asserts every operating-doc family member is globbed-or-EXEMPT. The `.codex`/`.agents` skill dirs are deliberately NOT in a Check-65 family glob (they are mirror-checked by Check 71, not history-scanned). Check 69's OUT-OF-FAMILY reasoning must account for the mirror trees: they need no Check-69 record because they are not in the history-scan families at all — Check 71 owns them. The CG-14-prep-a coder (who authors Check 69) must ensure Check 69 does NOT flag `.codex/skills`/`.agents/skills` as "escaped". (Design §5.2 meta-note.) RESIDUAL: low — flag to the CG-14-prep-a coder prompt.
- **R-6 (graph staleness).** The knowledge graph was built before HEAD `934a8a7` (it returned generic test-script nodes for a Check-71 query, not the relevant surfaces). Per G2, every exact-state claim here is grep/`diff`/Read/`git`-authoritative over the named surfaces (byte-identity + count surfaces are byte-precise questions the graph cannot answer). Not a plan risk — a verification-method note.

---

## 8. WAVE-2 ITEM (FLAGGED, NOT PLANNED HERE) — project-side skill mirror

Per the scope constraint (PACK-SIDE ONLY) and the design's note: the **project-template skill mirror question is a Wave-2 item.** The architect noted project skills are **install-generated with a single committed family** — i.e., the project side does not carry 3 committed skill mirrors the way the pack root does; the project skill set is materialized by `init-project.sh` at install time from one committed family. This means a project-side byte-identity gate analogous to Check 71 may be UNNEEDED or differently-shaped (there is a single committed source, not three committed mirrors to keep in sync). 

This is a SCOPING flag, not a deferral of pack-side work: ALL pack-side mirror work (CB-04 skills, CB-05 agents, Check 71) lands in v11.0 per this plan (no-deferral-without-user-direction). The project-side mirror analysis + any project skill bloat (CB-09's project skills) is the separate Wave-2 plan the user runs after the pack side lands. Do NOT fold project-side mirror work into CB-04/CB-05.

**EE-WAVE2 — project skills are install-generated, not 3 committed mirrors (cross-check) @ `934a8a7`.**
- Cmd: the design §0/§7 scope statement ("Scope: PACK-SIDE ONLY … The project-template mirror question is OUT OF SCOPE here") + PLAN-V2 §4 CB-09 ("project skills `project-template/skills/*/SKILL.md` ×37" — a SINGLE committed family under `project-template/skills/`, not 3 mirrors).
- Output (verbatim, key): PLAN-V2 §4 CB-09 row lists `project-template/skills/*/SKILL.md (37)` as the single committed project skill family; there is no committed `project-template/.codex/skills` / `project-template/.agents/skills` mirror set in the bloat universe (the per-CLI project skill dirs are install-generated by `init-project.sh`, not committed).
- HEAD/date: `934a8a7` / 2026-06-22.
- Interpretation: the project side has ONE committed skill family (`project-template/skills/`), unlike the pack root's 3 committed mirrors. A project-side byte-identity gate is therefore a different question (single source, install-time fan-out) — correctly deferred to the Wave-2 plan, NOT folded into this pack-side plan.
- Conclusion: **SUPPORTED.**

---

## 9. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted command / output / file:line) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | Every state-claim carries an Empirical-Evidence Block with command + verbatim output + HEAD `934a8a7` + 2026-06-22 + interpretation + SUPPORTED: EE-BASE (count 63, tree green), EE-LANDED (`git show --name-only c019e32 72553df e1cd5df 934a8a7`), EE-MEMBER (33 skill files), EE-DIVERGE (6 divergent skills + contamination), EE-CHECK56-CDISC (`sed 9395,9406`), EE-AGENT-MEMBER (15 agent files clean), EE-CHECK56-VERBS (`sed 9395,9436` 28-verb tuple), EE-COUNT (check-64 literal `63` at lines 74/75/82; constant at :496; stale "62" at :476; check-71 test absent), EE-DISJOINT (pairwise file-disjoint), EE-WAVE2 (project single committed family). | COMPLIANT |
| **enumerate-encoding-surfaces** | §4.3 enumerates ALL count-encoding surfaces for the +6 (63→69): S1 constant (`validate-pack.py:496`), S2 6 registry entries, S3 ledger (`:475-495`), S3b stale prose (`:476`), S4 hardcoded check-64 literal (`test-validate-pack-check-64.sh:74/75/82` — the load-bearing trap, `63→69`), S5 NEW dynamic-form `test-validate-pack-check-71.sh`, S6 ci-shard-plan glob (`scripts/lib/ci-shard-plan.py` EXCLUDE-only allowlist), S7 Check 59 (`:7188`), S8 Check 60 — each with file:line + value + miss=CI-fail flag. §4.4 specifies the atomic lock-step (S1+S2+S4 in ONE commit). The Check-56 surfaces (the encoding of the verb invariant CB-04/CB-05 must preserve) are enumerated (EE-CHECK56-CDISC + EE-CHECK56-VERBS, all 10 surfaces). | COMPLIANT |
| **ci-guard-measure-then-bound** | §2.7/§6 plan Check 71's verification to assert it runs CLEAN against the projected post-CB-04 state (all 11 byte-equal triples): the CB-04 PREFLIGHT `diff` proves 11 byte-equal triples + grep-zero mirror contamination BEFORE the patch; CG-14-prep-b verifies `--only-check 71` passes; CG-14 verifies Check 71 enforces clean post-registration. The gate is sized exactly to 3 trees × 11 skills, no allowlist (byte-identity absolute — design §5.1). | COMPLIANT |
| **no-deferral-without-user-direction / deferral-is-scope-creep** | All pack-side mirror work lands in v11.0: CB-04 skills + CB-05 agents + Check 71 (body at CG-14-prep-b, registration at CG-14). NOTHING pack-side deferred. §8 flags the project-side mirror as a Wave-2 SCOPING item (project skills are install-generated from a single committed family — a different question, EE-WAVE2), not a deferral of pack-side work. | COMPLIANT |
| **bounded-review-fix-cycle** | §6 plans each commit (CB-04, CB-05, CG-14-prep-a, -prep-b, CG-14) as coder → ≤2 review/fix pairs + 1 final reviewer (max 3 reviewer / 2 fix-coder spawns) → user commit gate; if dirty after final reviewer → STOP + pack-architect (no fix-coder pass 3). Worktree isolation: patch produced only after reviewer-clean. | COMPLIANT |
| **verify-full-ci-suite** | §6 mandates the FULL wired battery per commit BEFORE its patch: `ci-shard-plan.py` all shards + `validate-pack.py` no-flag + the relevant per-check tests INCLUDING the count-invariant tests (62/63/64 + 58-59-60) on the gate commits — the explicit fix for the prior subset-verify CI failure. Coder PREFLIGHT asserts FULL-battery PASS. | COMPLIANT |
| **agents-never-commit** | Only read-only verbs ran: `git rev-parse HEAD` / `git status --short` / `git log --oneline` / `git show --name-only --format=` (read-only inspection), `diff -q`/`diff`, `grep`/`grep -rl`, `ls`, `wc -l`, `sed -n`, `python3 scripts/validate-pack.py` (read-only validation), `graphify query` (read-only). Sole write = this plan doc via `cat >`/`cat >>` to the caller-specified `/tmp/pack-handoff-bd243-plan/PLAN-BD-243-MIRROR-INTEGRATION.md`. NO repo-file edit; NO patch; NO `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **graph-first-context** | Discovery was graph-FIRST: queried the injected path verbatim (`graphify query "skill mirror identity check validate-pack count registry surfaces" --graph /Users/david/.../graphify-out/graph.json --backend claude-cli --budget 1500`). The graph is STALE (built before `934a8a7` — returned generic test-script nodes, not Check-71 surfaces) → per G2 fell back to grep/`diff`/Read/`git` for every exact-state claim (byte-identity + count surfaces are byte-precise — grep/Read's job, not the graph's). Did not block on the graph; did not recompute the path from own toplevel. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence (command + output + file:line) + a terminal COMPLIANT conclusion. No empty evidence; no AMBIGUOUS. | COMPLIANT |

**END — PLAN-BD-243-MIRROR-INTEGRATION.md (pack-side only)**
