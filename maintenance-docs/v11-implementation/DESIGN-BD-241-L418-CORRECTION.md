# DESIGN-BD-241-L418-CORRECTION — the 4th STRIP surface: CLAUDE.md L418-422 "Trinity exemption" rationale

**Agent:** pack-architect (READ-ONLY, FRESH/INDEPENDENT, EMPTY context) · **Date:** 2026-06-20
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`,
HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`).
**Scope (surgical — single-clause):** design the EXACT reworded text for CLAUDE.md L418-422 —
the `**Trinity exemption.**` standalone bullet at the END of `### Sub-agent behavior
(Claude-only)`. The user DECIDED (2026-06-20) to INCLUDE this clause in BD-241's correction as
a 4th STRIP surface, resolving the open item the planner surfaced in PLAN-BD-241 §2.6 (the
census `grep -rln` collapsed BOTH CLAUDE.md hits into one file-level match, leaving this
second clause unclassified). This is a PARTIAL correction — correct the now-FALSE
peer-messaging "no equivalents" portion; PRESERVE the still-true portion + the exemption's
purpose.
**Does NOT re-open:** the settled BD-241 design (RECONCILED + D3-ADDENDUM) or the plan's
3-STRIP / 5-KEEP census, the 3 new corpus rules, the commit framing, or rule-10. It ADDS one
surgical edit to the EXISTING Commit-1 pack-only group.

**Inputs read in full:** CLAUDE.md L405-423 (the two adjacent bullets in context);
`/tmp/pack-handoff-bd241-research/RESEARCH-BD-241-EXTERNAL.md` (the verified capability
matrix, §5.1/§5.2/§5.3/§7); `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-RECONCILED.md` §1.1
(the S1/L415-416 corrected text — my wording is consistent with it) + §8 (validate-pack
green plan); `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-D3-ADDENDUM.md` (consistency check);
`/tmp/pack-handoff-bd241-plan/PLAN-BD-241.md` §2.6 (the surfaced open item), §4.1 (S1
replacement), §10 (commit framing), §11 (rule-10); `scripts/validate-pack.py` Check 45 regex
(L7376) + Check 46 extractor (`_check_46_extract_pack_memory_imperative_bodies`, L7521-7556).

> **Method note (graph-first, G2 fallback applied).** I queried the injected graph FIRST
> (the orchestrator-supplied absolute `--graph` path, NOT my own toplevel) for the
> trinity-exemption / peer-messaging / Agent-Teams surfaces; it returned only fixture +
> provenance nodes (the rule-body concept is not a graph node — identical G2 result to all
> three prior BD-241 passes). Per the G2 fallback I re-measured EVERY load-bearing surface
> with grep/Read against HEAD `af73ffb`. The graph indexes headings/code, not memory-rule
> bodies, so grep/Read is the correct primary tool for this prose-correction BD. Proof + the
> graph-query-ran row are in the Rules-Applied block.

---

## 0. The current text being corrected (verbatim, CLAUDE.md L418-422)

```
- **Trinity exemption.** This sub-section is Claude-specific (not
  mirrored in `AGENTS.md` / `GEMINI.md`) because it concerns Claude
  Code's Agent tool, `run_in_background` parameter, and Agent Teams /
  SendMessage features — none of which have equivalents in Codex CLI
  or Antigravity CLI per research §2.5 / §2.7 / §3.5 / §3.7.
```

This is a standalone `**Trinity exemption.**` bullet (distinct from the `Trinity exemption:`
TAIL inside the preceding `**Agent-team stage lifecycle + per-commit fresh-coder.**` bullet —
that tail is S1/L413-417, already in the settled STRIP set). The standalone bullet is the
EXEMPTION RATIONALE for the entire `### Sub-agent behavior (Claude-only)` sub-section: it
explains WHY that sub-section is not mirrored ×3.

---

## 1. Deliverable 2 (answered first, because it drives the wording) — what is STILL-TRUE vs STALE

The clause bundles a FEATURE SET and asserts "none of which have equivalents." It must be
decomposed feature-by-feature against the verified research, not treated as one atomic claim.

| Bundled feature | Claim in the clause | Verified status (research) | KEEP/CORRECT |
|---|---|---|---|
| **Claude Code's Agent tool** | "concerns Claude Code's Agent tool … none of which have equivalents" | Codex has `spawn_agent`/MAv2 + `/agent`; Antigravity has `define_subagent`/`/agents`. The SUB-AGENT-SPAWN concept HAS cross-CLI analogs — but the pack's rules are written against the **Claude Agent-tool specifics** (the `name`/`agentId`/`subagent_type` schema, the `isolation:"worktree"` trigger, the tool_result format). | **PARTIAL** — the *spawn-an-agent concept* is not Claude-unique, but the *Agent-tool's concrete parameter surface* the sub-section's rules invoke IS Claude-specific. Reword to "built against Claude Code's Agent-tool mechanism" rather than "no equivalent anywhere." |
| **`run_in_background` parameter** | "none of which have equivalents" | RESEARCH does NOT assert a Codex/Antigravity equivalent of the specific `run_in_background` Agent-tool PARAMETER. The existing `## Pack memory` rule "Default sub-agent spawns to background" already states the audience-correct truth: Codex parallel-spawn is "implicit (parallel-by-default, capped by `agents.max_threads`)"; Antigravity parallel-spawn is "implicit via its dynamic-subagent mechanism." So the BEHAVIOR has platform-native analogs, but the **named `run_in_background` parameter** is a Claude-tool-specific knob. | **STILL-TRUE (as a named parameter)** — preserve. There is no `run_in_background` *parameter* on the other CLIs; their async behavior is implicit/platform-native, which is exactly the existing background-spawn rule's framing. Keep this as a genuine Claude-specific item; do NOT claim a parameter-level equivalent exists. |
| **Agent Teams / SendMessage (peer-messaging)** | "none of which have equivalents in Codex CLI or Antigravity CLI per research §2.5/§2.7/§3.5/§3.7" | **NOW STALE.** Codex MAv2 `send_message` (issue #12462 CLOSED-COMPLETED 2026-05-02; flag-gated `multi_agent_v2`) and Antigravity `agy` (inter-agent ID-addressing + idle auto-rewake) ship peer-messaging ANALOGS (RESEARCH §5.1/§5.2/§5.3/§7). The "confirmed absent" / "no equivalents" assertion for peer-messaging is FALSE as of 2026-06-20. | **CORRECT** — this is the now-false portion. The analogs EXIST but are flag-gated/not-yet-GA-documented (Codex) and partly-unverified (Antigravity), so the Claude-only TREATMENT survives for v11.0 pending BD-217 — but the JUSTIFICATION ("no equivalents") must be replaced with the corrected premise. |

**Conclusion (Deliverable 2):** the clause is NOT fully stale and NOT fully true. The
peer-messaging "none of which have equivalents" assertion is STALE (must be corrected). The
Agent-tool-specificity and the `run_in_background`-as-a-named-parameter points remain TRUE
(must be preserved). The Trinity-exemption ITSELF (this sub-section is Claude-specific, not
mirrored ×3) remains correct on its STRUCTURAL merits — the MECHANISM is built Claude-first —
so the exemption is PRESERVED; only its rationale's stale leg is reworded.

**Evidence anchors (verbatim, RESEARCH-BD-241-EXTERNAL.md):**
- §5.3 verdict: *"do NOT cite '#12462 confirmed absent' — cite '#12462 CLOSED COMPLETED;
  Codex MAv2 + Antigravity inter-agent messaging exist; cross-CLI mapping = BD-217.'"*
- §7: *"peer-messaging/named-recall/resume are NO LONGER Claude-exclusive — Codex MAv2
  (flag-gated, #12462 CLOSED COMPLETED) and Antigravity `agy` (ID-addressing + auto-rewake +
  `/agents`) both ship analogs."*
- §5.3 verdict (the defensible position the architect must carry): *"the unique-naming
  discipline applies wherever agents spawn (all CLIs); the concrete registry+precedence
  mechanism is built Claude-first, with Codex/Antigravity applicability now PLAUSIBLE (no
  longer 'confirmed absent') and properly scoped to BD-217 — because their analogs exist but
  need their own verification + mapping."*

---

## 2. Deliverable 1 — the EXACT reworded text for CLAUDE.md L418-422

The wording is AUDIENCE-CORRECT for CLAUDE.md (Claude-maintainer audience —
`cross-cli-reference-normalization`) and CONSISTENT with the settled S1/L415-416 corrected
text (RECONCILED §1.1 P3: *"Codex MAv2 `send_message` (flag-gated `multi_agent_v2`; issue
#12462 CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing + idle auto-rewake)
now ship peer-messaging ANALOGS — but they are flag-gated / not-yet-GA-documented (Codex) and
partly-unverified (Antigravity), so this MECHANISM stays Claude-only here; the cross-CLI
mapping is BD-217."*). My L418-422 wording reuses the SAME corrected premise vocabulary
("ship analogs … flag-gated / not-yet-GA-documented … partly-unverified … BD-217") so the two
adjacent bullets do not contradict each other.

**REPLACE the entire L418-422 bullet with:**

```
- **Trinity exemption.** This sub-section is Claude-specific (not
  mirrored in `AGENTS.md` / `GEMINI.md`) because its rules are built
  against Claude Code's Agent-tool mechanism — the Agent tool's spawn
  schema, the `run_in_background` parameter (Codex/Antigravity async
  spawning is implicit/platform-native, not a named parameter), and the
  Agent Teams / SendMessage peer-messaging primitives. Codex MAv2
  `send_message` (flag-gated `multi_agent_v2`; issue #12462
  CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing +
  idle auto-rewake) now ship peer-messaging ANALOGS, but they are
  flag-gated / not-yet-GA-documented (Codex) and partly-unverified
  (Antigravity) — so this mechanism stays Claude-only here; the
  cross-CLI mapping is BD-217.
```

### 2.1 What the rewording does, clause by clause (audit trail)

- **PRESERVES the exemption + its purpose** — the opening "This sub-section is Claude-specific
  (not mirrored in `AGENTS.md` / `GEMINI.md`)" is kept VERBATIM. The exemption is NOT deleted;
  only its justification's stale leg is reworded. The Trinity-exemption's point — this
  sub-section is Claude-specific because the MECHANISM is built Claude-first — survives intact
  and is even sharpened ("its rules are built against Claude Code's Agent-tool mechanism").
- **PRESERVES the still-true `run_in_background` item** — kept as a named Claude-tool parameter
  with the audience-correct truth that other CLIs' async spawning is implicit/platform-native
  (consistent with the existing "Default sub-agent spawns to background" rule's exact framing,
  measured at CLAUDE.md — Codex "implicit (parallel-by-default, capped by
  `agents.max_threads`)"; Antigravity "implicit via its dynamic-subagent mechanism").
- **PRESERVES the Agent-tool-specificity** — reframed from "no equivalents anywhere" to "built
  against Claude Code's Agent-tool mechanism," which is TRUE (the rules invoke Claude's concrete
  spawn schema) without the now-false universal-absence claim.
- **CORRECTS the stale peer-messaging leg** — replaces "Agent Teams / SendMessage features —
  none of which have equivalents in Codex CLI or Antigravity CLI per research §2.5/§2.7/§3.5/§3.7"
  with the verified corrected premise (analogs EXIST but flag-gated/not-yet-GA/partly-unverified).
- **DROPS the stale internal cross-reference** "per research §2.5 / §2.7 / §3.5 / §3.7" — those
  pointers reference the SUPERSEDED v11-archive research that reached the now-falsified
  "confirmed-absent" conclusion (RESEARCH §5: *"the v11 archive research
  (`maintenance-docs/archive/v11/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md`, retrieved
  2026-05-16) … is now out of date"*). Citing a superseded source for a corrected claim would
  reintroduce the staleness; the corrected text cites the LIVE evidence (#12462 status, MAv2,
  `agy`) inline, matching the S1 pattern (which also dropped the stale citation).
- **KEEPS the Claude-only TREATMENT for v11.0** — "so this mechanism stays Claude-only here;
  the cross-CLI mapping is BD-217" — the analogs' existence does NOT force cross-CLI
  implementation now; BD-217 owns the mapping (consistent with RECONCILED §4.1 + the plan's
  BD-217 scope-note, and with `verify-availability-not-just-existence` — the capability exists
  but its end-to-end usability on a default install is the open caveat per RESEARCH §6).

### 2.2 Consistency with the adjacent S1 edit (no contradiction across the two bullets)

After both edits land, the `### Sub-agent behavior (Claude-only)` sub-section will carry the
corrected premise in TWO adjacent places: the `Trinity exemption:` tail of the
"Agent-team stage lifecycle" bullet (S1/L413-417) and this standalone `**Trinity exemption.**`
bullet (L418-422). Both now say the same thing in the same vocabulary (analogs exist,
flag-gated/partly-unverified, Claude-only here, BD-217 owns the mapping). This is intentional
redundancy that the section already had (two "Trinity exemption" notes existed pre-edit, both
asserting Claude-specificity) — the correction keeps the two consistent rather than letting one
say "confirmed absent" while the other says "analogs exist." There is NO new contradiction; the
edit REMOVES a latent inconsistency that would otherwise exist if only S1 were corrected.

---

## 3. Deliverable 4 — NO new rule-10 collision + NO validate-pack impact (confirmed)

### 3.1 rule-10 (parallelization / same-file serialization) — NO NEW collision
This edit touches `CLAUDE.md` ONLY. `CLAUDE.md` is ALREADY in the BD-238/240/241 serialization
set (PLAN-BD-241 §11.1: *"BD-238 + BD-240 + BD-241 ALL edit the same shared files — trinity
`## Pack memory`"*). The L418-422 bullet is INSIDE the `## Pack memory` H2, `### Sub-agent
behavior (Claude-only)` H3 — the same file region BD-241's Bullet B (B1) already edits. It adds
NO new file to the serialization set, NO new parallel wave, and NO cross-file dependency.
Within BD-241 itself this edit co-locates with S1 (the same bullet-cluster, same CLAUDE.md
region, same Commit-1 group) — it is absorbed into the existing serial structure. **CONFIRMED:
no new rule-10 collision class.**

### 3.2 validate-pack — NO impact (Checks 45/46/18 all unaffected)

**Check 45 (rule↔rationale bijection) — UNAFFECTED.** Check 45 keys off `[rationale: <slug>]`
tags (regex `\[rationale:\s*([a-z0-9][a-z0-9-]*)\]`, validate-pack.py L7376; only
`[rationale:]`-tagged bullets enter the corpus set, L7333 "Rules that carry NO `[rationale:]`
tag are simply not in the set"). The L418-422 bullet carries NEITHER a `[rationale:]` NOR a
`[roles:]` tag — measured (`sed -n '418,422p' CLAUDE.md | grep "rationale:\|roles:"` → 0 hits).
It is untagged prose. Rewording it adds/removes NO slug → bijection count UNCHANGED (the
BD-241 corpus delta stays +3 from Bullets A/B/C, exactly as the plan's §3.4 arithmetic states;
this edit contributes 0).

**Check 46 (anti-restate) — UNAFFECTED (0 restate hits, baseline-preserving).** Check 46's
anti-restate extractor (`_check_46_extract_pack_memory_imperative_bodies`, L7521-7556) DOES
scan ALL bold-name `- **<name>.**` bullets in `## Pack memory` (regex `^- \*\*.+?\*\*\s*(.+?)`,
L7547) — so the `**Trinity exemption.**` bullet IS a candidate body in BOTH the baseline AND
the post-edit tree (the candidate-body count is unchanged: it was 1 candidate before, 1 after —
a reword does not add/remove the bullet). The check FAILS only if the bullet's leading-120-char
window appears VERBATIM in one of the 6 scanned reference surfaces (PACK-AGENTS.md, PACK-CHAT.md,
4 skill `SKILL.md`). The reworded text is UNIQUE to this CLAUDE.md bullet — it adds NO text to
any reference surface, and its leading-120-char window ("This sub-section is Claude-specific
(not mirrored in `AGENTS.md` / `GEMINI.md`) because its rules are built against Claude Code's
Agent-tool …") does not appear in any of the 6 surfaces (baseline anti-restate = 0; this edit
introduces no new reference-surface restatement). **CODER DIRECTIVE (measure-then-bound, per
`ci-guard-design-measure-then-bound`):** after the edit, re-run `python3 scripts/validate-pack.py`
and confirm Check 46 still reports `anti-restate: 0` (the reworded window's non-collision is
trivially satisfied since no reference surface is touched, but the gate is measured, not
asserted).

**Check 18 (trinity H2/H3 parity) — UNAFFECTED.** Check 18 keys off H2/H3 HEADINGS, not bullet
bodies. The L418-422 bullet lives inside the EXISTING `### Sub-agent behavior (Claude-only)` H3
(L348) under the EXISTING `## Pack memory` H2 (L140) — verified. Rewording a bullet body within
an existing heading changes NO heading structure. Critically, `### Sub-agent behavior
(Claude-only)` is CLAUDE.md-ONLY by design (measured: zero `### Sub-agent behavior` in AGENTS.md
or GEMINI.md) — and Check 18 is per-H2-per-location with no cross-location gate, so a CLAUDE-only
H3 is not a parity violation (it is the established Claude-only-section pattern). The edit is
CLAUDE.md-only and needs NO trinity-parity ×3.

**Check 36 (commit-scope keyword) — this edit is `pack-only`-clean.** It touches CLAUDE.md
only (a pack-ops file) — NOT `project-template/` or `supporting-docs/`. It is fully compatible
with the Commit-1 `pack-only` keyword claim (§4 below).

**Check 62 (push-time manifest) — UNAFFECTED.** CLAUDE.md is a pack-ops file, NOT a fixture
input (it does not stage to `test-fixtures/**`). No manifest concern.

**No new CHECK designed (measure-then-bound).** This is a one-line prose correction; there is
no committed-tree state a new validator could scan (an empty matching set — forbidden by
`ci-guard-design-measure-then-bound`). CI runtime-compounding cost (×~155) UNCHANGED.

---

## 4. Deliverable 3 — the plan-delta (this is a 4th STRIP surface joining Commit 1)

### 4.1 Census reclassification
This edit RESOLVES the open item in PLAN-BD-241 §2.6 (the `**Trinity exemption.**` bullet at
L418-422, flagged "BORDERLINE … editing it is REDESIGN/scope-drift … leave UNTOUCHED … surface
to Pack Chat + the user"). The user has now DECIDED (2026-06-20) to INCLUDE it. So the settled
STRIP set grows from {S1, S2, S3} to {S1, **S4 (NEW)**, S2, S3}, where **S4 = CLAUDE.md
L418-422** (the standalone `**Trinity exemption.**` bullet). It is a PARTIAL correction (correct
the peic-messaging leg; preserve the Agent-tool/`run_in_background` leg + the exemption), per
the user's nuance — NOT a clean strip.

### 4.2 Commit-group assignment — S4 joins COMMIT 1 (the `pack-only`-clean group)
Per PLAN-BD-241 §10 Option B (the RECOMMENDED split):
- **Commit 1 (`pack-only` clean):** Bullets A/B/C ×3, rationale R1/R2/R3, **S1** (CLAUDE stale),
  S2 (RATIONALE stale). Files: CLAUDE.md, AGENTS.md, GEMINI.md, pack-ops/PACK-MEMORY-RATIONALE.md.
- **Commit 2 (NO scope keyword):** S3 (METHODOLOGY), PR1/PR2, CPR1a/b/c, CPR2.

**S4 joins Commit 1.** It is a CLAUDE.md edit (a pack-ops file) — it adds NO `project-template/`
or `supporting-docs/` path, so it preserves Commit 1's `pack-only` keyword validity (Check 36).
It belongs in Commit 1 alongside S1 because both are stale-claim corrections in the SAME
CLAUDE.md `### Sub-agent behavior (Claude-only)` bullet-cluster — they should land atomically so
the two adjacent "Trinity exemption" notes are corrected together (avoiding the transient
inconsistency §2.2 warns of). S4 does NOT belong in the cross-surface Commit 2 (it touches no
product file).

### 4.3 The grep-zero PREFLIGHT line (for the coder's IMPL-REPORT, per `rename-plans-measure-then-bound`)
The coder's PREFLIGHT must include a grep-ZERO completeness gate proving the removed stale
phrasing is gone from the trinity-exemption bullet. Recommended PREFLIGHT line:

```
grep -n "none of which have equivalents\|per research §2.5 / §2.7 / §3.5 / §3.7" CLAUDE.md
  → EXPECT 0 hits (S4 stale phrasing removed)
```

Note the FIRST pattern (`none of which have equivalents`) is the load-bearing stale assertion;
the SECOND (`per research §2.5 / §2.7 / §3.5 / §3.7`) is the stale superseded-research citation
this edit drops. Both must grep-ZERO after S4 lands. (Measured at baseline HEAD af73ffb: both
patterns currently match ONLY L421-422 — so post-edit 0 hits proves the removal is complete and
introduced no copy elsewhere.) The coder also confirms the PRESERVED phrasing survives:

```
grep -n "not.*mirrored in \`AGENTS.md\` / \`GEMINI.md\`\|run_in_background" CLAUDE.md
  → EXPECT the L418-422 bullet still carries the exemption opener + the run_in_background item
```

### 4.4 Plan-table delta (additive to PLAN-BD-241 §2.1)
Add one row to the pack-side tree-files inventory:

| ID | File | Anchor (grep literal) | Edit kind |
|---|---|---|---|
| **S4 (NEW)** | `CLAUDE.md` | standalone bullet `- **Trinity exemption.** This sub-section is Claude-specific (not mirrored in \`AGENTS.md\` / \`GEMINI.md\`)` … `none of which have equivalents … per research §2.5 / §2.7 / §3.5 / §3.7.` (ctx L418-422), at the END of `### Sub-agent behavior (Claude-only)` | STRIP/REPLACE (PARTIAL — §2 text; correct peer-messaging leg, preserve Agent-tool/`run_in_background` leg + exemption) |

No other plan section changes: §2.6's open item is now RESOLVED (decision: INCLUDE as S4 in
Commit 1); §3.4 bijection arithmetic UNCHANGED (S4 is untagged prose, +0 slugs); §10 commit
framing UNCHANGED (S4 rides Commit 1's existing `pack-only` claim); §11 rule-10 UNCHANGED (S4
edits a file already serialized). The coder applies S4 with S1 in the same CLAUDE.md edit pass.

---

## 5. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **graph-first-context** | Queried the INJECTED `--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST (not my own toplevel). The trinity-exemption/peer-messaging rule-body concept returned only fixture/provenance nodes (not a graph node) → G2 fallback to grep/Read, which I used to verify every load-bearing surface against HEAD af73ffb. Graph-query-ran row recorded below. | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by command + verbatim output + HEAD/date. E2 (clause is CLAUDE-only): `grep -rn "none of which have equivalents…" CLAUDE.md AGENTS.md GEMINI.md` → 3 hits all CLAUDE.md (L420-422), 0 in AGENTS/GEMINI [af73ffb]. E3 (untagged prose): `sed -n '418,422p' CLAUDE.md \| grep "rationale:\|roles:"` → 0 hits [af73ffb]. E4 (Check 45 keys on `[rationale:]`): validate-pack.py L7376 `rationale_re = re.compile(r"\[rationale:\s*([a-z0-9][a-z0-9-]*)\]")` + L7333 "Rules that carry NO `[rationale:]` tag are simply not in the set" [read]. E5 (Check 46 scans all bold bullets): validate-pack.py L7547 `r"^- \*\*.+?\*\*\s*(.+?)…"` [read]. E6 (inside existing H3): `grep -n "^## Pack memory\|^### Sub-agent behavior" CLAUDE.md` → 140 / 348 [af73ffb]. See §1, §3.2. | COMPLIANT |
| **verify-availability-not-just-existence** | Relied on RESEARCH-BD-241-EXTERNAL.md's verified capabilities, quoted verbatim: §5.3 "#12462 CLOSED COMPLETED; Codex MAv2 + Antigravity inter-agent messaging exist; cross-CLI mapping = BD-217"; §6 caveat that Codex MAv2 end-to-end usability on a default install is NOT-yet-verified (flag-gated) and Antigravity durable-registry is partly-unverified. The reworded text encodes EXISTS-but-flag-gated/partly-unverified, not "available everywhere." | COMPLIANT |
| **cross-cli-reference-normalization** | The reworded text is AUDIENCE-CORRECT for CLAUDE.md (Claude-maintainer audience); it cites pack-internal evidence (#12462, `multi_agent_v2`, `agy`) appropriate for a pack-ops file, consistent with the adjacent S1/L415-416 corrected text (RECONCILED §1.1 P3) which uses the same vocabulary. No byte-copy of a client-audience clause. | COMPLIANT |
| **separate-pack-ops-from-product** | S4 edits CLAUDE.md (a pack-ops file) ONLY — no `project-template/` or `supporting-docs/` path. Confirmed `pack-only`-clean → joins Commit 1's `pack-only` group (§3.2 Check 36, §4.2). | COMPLIANT |
| **agents-never-commit / per-action-approval-sub-agents** | No git state-changing verb run; read-only `git rev-parse HEAD` / `git branch` / `git status` only; sole write = this design doc at the named /tmp path; no destructive op. | COMPLIANT |
| **rules-applied-verification-block** | This block present with quoted/measured evidence per rule; includes the graph-query-ran row below; no empty evidence. | COMPLIANT |
| **graph-query-ran (evidence row)** | Ran `graphify query "trinity exemption peer-messaging Agent Teams SendMessage Claude-only sub-agent behavior" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` (injected path, not self-derived). Result: fixture/provenance nodes only, no rule-body node → G2 fallback to grep/Read. | COMPLIANT |
