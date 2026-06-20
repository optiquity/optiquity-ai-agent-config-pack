# ADVERSARIAL-PLAN-REVIEW-BD-241 — fresh independent pack-planner review of PLAN-BD-241

**Agent:** pack-planner (READ-ONLY, FRESH/INDEPENDENT, EMPTY context — adversarial) · **Date:** 2026-06-20
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`,
HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`), clean tree.
**Subject reviewed:** `/tmp/pack-handoff-bd241-plan/PLAN-BD-241.md`.
**Settled design (3 docs, read in full):** `DESIGN-BD-241-RECONCILED.md` +
`DESIGN-BD-241-D3-ADDENDUM.md` (Bullet C) + `DESIGN-BD-241-L418-CORRECTION.md` (S4).
**Method:** I challenged every load-bearing claim by re-measuring against HEAD `af73ffb`
(grep/Read/validate-pack). Graph queried FIRST per graph-first-context; it returned only
fixture/provenance nodes for the rule-corpus concept (G2 fallback to grep/Read — same result
the three prior passes hit). I did NOT read prior review reports.

---

## VERDICT: **NEEDS-REWORK**

The plan is structurally sound, surface-complete, and correct on the load-bearing
architecture (commit split, rebase-on-BD-240 robustness, bijection, anti-restate, S4
placement, Check 36). The rebase-on-BD-240 case is **ROBUST** (see §3 below). However, the
plan ships **two PREFLIGHT grep-gate specification defects** that, as written, would make a
correct coder's PREFLIGHT FAIL on legitimate KEEP surfaces (false-negative gate) — a
MAJOR coder-executability defect — plus three MINOR gaps. None re-open the design; all are
fixable by the reconciliation planner with surgical edits to §12.2.

**Severity counts: BLOCKER 0 · MAJOR 1 · MINOR 4.**

---

## Finding 1 [MAJOR] — PREFLIGHT KEEP-surface grep gates (§12.2 gate #6) use wrong literal casing/wording → a correct coder's gate FAILS

**Location:** PLAN-BD-241.md §12.2 gate #6 (lines ~636-638).

**The defect.** Gate #6 instructs the coder to confirm KEEP surfaces are untouched with:
```
grep -c "no equivalent per-project MEMORY mechanism" project-template/docs/pack/PM-CHAT.md  → 1
grep -c "WORKTREE story is tracked" project-template/docs/pack/OPTIONAL-FEATURES.md pack-ops/OPTIONAL-FEATURES.md  → 1/1
```
Both literals are WRONG against the actual tree. Measured at HEAD `af73ffb`:
```
$ grep -c "no equivalent per-project MEMORY mechanism" project-template/docs/pack/PM-CHAT.md
0      # actual text is "no equivalent per-project memory mechanism" (lowercase "memory")
$ grep -c "WORKTREE story is tracked" project-template/docs/pack/OPTIONAL-FEATURES.md pack-ops/OPTIONAL-FEATURES.md
0 / 0  # actual text is "worktree story is tracked" (lowercase "worktree")
```
Verbatim actual lines (re-measured):
- `project-template/docs/pack/PM-CHAT.md` L908: `> Codex CLI and Antigravity CLI have no equivalent per-project memory`
- `project-template/docs/pack/OPTIONAL-FEATURES.md` L283: `have no equivalent at this time; their worktree story is tracked separately and`
- `pack-ops/OPTIONAL-FEATURES.md` L284: `and Antigravity have no equivalent at this time; their worktree story is`

**Root cause.** The settled design's census KEEP table (RECONCILED §1, rows 5/6/7) wrote
"per-project MEMORY" and "WORKTREE" in ALL-CAPS as PROSE EMPHASIS (to contrast capabilities).
The plan copied that emphasis-casing verbatim into LITERAL grep gates. grep `-c` is
case-sensitive by default, so the gates return 0 — meaning a coder running gate #6 exactly as
written would read "0 ≠ expected 1" and conclude the KEEP surface was accidentally stripped
(or, worse, "re-add the missing line"), when in fact the surface is correctly untouched. This
is a false-FAIL gate that actively misleads the coder away from a clean state.

**Why MAJOR (not MINOR).** The plan's own §15 Rules-Applied block claims
`rename-plans-measure-then-bound: COMPLIANT` on the basis that "§12.2 PREFLIGHT gates are
grep-ZERO completeness gates on the 3 STRIP surfaces + grep-PRESENT on KEEP." A grep-PRESENT
gate that cannot match the present string is not measure-bound — it is unmeasured. The
measure-then-bound rule requires the gate to be measured against the actual tree; this one was
not (it was copied from emphasis prose). This is the exact class of defect the rule exists to
prevent.

**The concrete fix (reconciliation planner must apply to §12.2 gate #6).** Either:
(a) make the gates case-insensitive — `grep -ci "no equivalent per-project memory" …` and
`grep -ci "worktree story is tracked" …`; OR
(b) correct the literals to the measured exact casing:
`grep -c "no equivalent per-project memory" project-template/docs/pack/PM-CHAT.md → 1` and
`grep -c "worktree story is tracked" project-template/docs/pack/OPTIONAL-FEATURES.md pack-ops/OPTIONAL-FEATURES.md → 1/1`.
Recommend (b) (exact, complete — `grep` is the precision tool). The third gate-#6 line
(`if your CLI offers no peer-messaging, re-spawn a fresh` → 1) is CORRECT as written
(measured = 1) — leave it.

---

## Finding 2 [MINOR] — §2.5 KEEP-surface anchor text mis-quotes the same two surfaces (consistency with Finding 1)

**Location:** PLAN-BD-241.md §2.5 KEEP list (lines ~110-112) and §13 claim #10.

**The defect.** §2.5 quotes the KEEP surfaces as `no equivalent per-project MEMORY mechanism`
and `WORKTREE story is tracked` — the same ALL-CAPS emphasis the §12.2 gates inherited. While
§2.5 is descriptive (not an executed gate), the coder cross-references §2.5 against §12.2; the
mis-quote compounds Finding 1. §13 claim #10's "Output" column likewise renders the gist in a
way that obscures the true lowercase literal.

**Fix.** Normalize the §2.5 and §13-claim-#10 quotes to the measured lowercase text (or mark
them explicitly as "gist, not literal"). Low effort; do it alongside Finding 1 so the plan is
internally consistent on the KEEP literals.

---

## Finding 3 [MINOR] — the 3 NEW rationale sections (R1/R2/R3) have NO specified insertion point → an avoidable rebase-adjacency to BD-240's edited tail section

**Location:** PLAN-BD-241.md §2.1 rows R1/R2/R3 and §3 (no placement directive).

**The measured concern.** `## graph-first-context` is the LAST `## <slug>` section in
`pack-ops/PACK-MEMORY-RATIONALE.md` (measured: heading at L638, EOF at L684) AND it is exactly
the section BD-240 re-frames (BD-240 File/Symbol: "`[rationale: graph-first-context]` in
`PACK-MEMORY-RATIONALE.md`"). The plan tells the coder to "ADD rationale section" for R1/R2/R3
but never says WHERE. The natural coder default — append at EOF — places the 3 new sections
immediately after the very section BD-240 edits. In SERIAL execution (BD-240 lands first,
BD-241 bases on the new HEAD) this is benign (no concurrent edit), so it is not a BLOCKER. But
it is an avoidable adjacency that a content-anchored placement directive removes entirely, and
the omission is a measure-then-bound gap: the plan anchors every OTHER surface to a content
literal but leaves R1/R2/R3 placement implicit.

**Fix.** Add a one-line directive to §3: insert the 3 new bare-slug sections via a CONTENT
ANCHOR not at EOF — e.g. "insert the 3 new `## <slug>` sections immediately AFTER the existing
`## pack-chat-minor-edits-only` section (RATIONALE.md, anchor `## pack-chat-minor-edits-only`)
and BEFORE `## graph-first-context`, so they do not abut BD-240's edited tail section." (Any
stable interior anchor works; the point is to specify one and keep it off BD-240's region.)
This also keeps R1/R2/R3 clear of S2's region (`## preflight-stop-means-stop`, L138-208).

---

## Finding 4 [MINOR] — §12.2 gate #6 final clause directs `git diff` audit of "the 5 KEEP files in §2.5 except PM-CHAT" but two of those files are NOT edited at all by BD-241

**Location:** PLAN-BD-241.md §12.2 gate #6, final parenthetical (lines ~639-641).

**The nit.** The parenthetical says "Confirm via `git diff --name-only` that none of the 5 KEEP
files in §2.5 except PM-CHAT … appear." Of the 5 KEEP surfaces, `backlog/BD-241.md` is
pack-chat-only governance (not a coder file at all — §2.4/§6 forbid the coder touching it) and
the two OPTIONAL-FEATURES files are never in BD-241's edit set. Asking the coder to assert
their absence from `git diff` is harmless but slightly muddles the gate (the coder might wonder
why a never-touched governance file is in a completeness check). The substantive point — PM-CHAT
must show only ADD hunks for PR1/PR2/CPR2 — is correct and worth keeping.

**Fix.** Tighten the parenthetical to: "Confirm `git diff project-template/docs/pack/PM-CHAT.md`
shows only ADD hunks for PR1/PR2/CPR2 (the KEEP lines unchanged); the two OPTIONAL-FEATURES
files and `backlog/BD-241.md` must NOT appear in `git diff --name-only` at all (not in BD-241's
edit set)." Optional polish; not load-bearing.

---

## Finding 5 [MINOR] — §6 / §10 / §11 lean on the BD-240-FIRST serialization but the plan never states the coder MUST re-confirm BD-240 has LANDED before applying (a `RE-VERIFY` marker is absent)

**Location:** PLAN-BD-241.md §11.1 (rule-10) + §14 risk #3.

**The concern.** The plan correctly states "each coder BASES ON THE PRIOR-LANDED HEAD … NEVER
hand-merges … if a base is stale, STOP and re-spawn." That is the right rule-10 framing. But
the D3-ADDENDUM §3.2 and the broader pipeline convention call for an explicit `RE-VERIFY at
impl` marker when one BD's correctness depends on another's landed state. Here BD-241's bijection
arithmetic (§3.4: "do NOT hard-code 26 — if BD-238/BD-240 land first, the baseline shifts") and
its content anchors both assume a specific predecessor state. The plan tells the coder to confirm
the LIVE count, which is good — but it does not give the coder a one-line PREFLIGHT assertion
"BD-240 landed: `grep -c 'DISCOVERY' CLAUDE.md` (or the BD-240 marker) ≥ 1 at base HEAD" to PROVE
the base is the post-BD-240 tree rather than the af73ffb tree.

**Why this matters (counterexample).** If the orchestrator accidentally spawns BD-241's coder on
`af73ffb` (pre-BD-240) instead of post-BD-240 HEAD, every BD-241 content anchor STILL resolves
(they are in disjoint regions — see §3 rebase verdict), so the coder would proceed and produce a
clean validate-pack — but the resulting tree would be missing BD-240 entirely, and the
serialization invariant would be silently violated. The PREFLIGHT HEAD-SHA check (§12.2 gate #10
mentions validate-pack but not a base-predecessor assertion) does not catch a wrong-but-valid base.

**Fix.** Add to §12.2 a PREFLIGHT line: "Confirm the base HEAD is the post-BD-240 tree (the
serialization predecessor): `git log --oneline -5 | grep -i BD-240` returns the landed BD-240
commit; if absent, STOP — the base is stale/wrong-order, re-spawn on the correct HEAD." This is
the `RE-VERIFY at impl` marker the D3 handoff §3.2 prescribes, applied to BD-241's own base.
(MINOR because the design's serial-order intent is clear and the orchestrator drives ordering;
but the plan should make the coder's base-assertion explicit, not implicit.)

---

## ADVERSARIAL TARGET-BY-TARGET VERDICTS (each re-measured)

### Target 1 — Surface fidelity: **PASS (with Finding 1/2 caveat on KEEP-gate literals)**
Every surface's content-anchor matches the settled design + the live tree, re-measured:
- **Bullet A** (`spawn-unique-naming`, ×3, `### Agent invocation rules`) — anchors verified:
  CLAUDE L242 / AGENTS L244 / GEMINI L211 (`grep -n "### Agent invocation rules"`). Text matches
  RECONCILED §3.1 verbatim incl. the load-bearing "uniqueness is a DISCIPLINE — no platform
  guarantees it" clause and the audience-correct ×3 substitutions. COMPLIANT.
- **Bullet B** (`spawn-registry-find`, CLAUDE-only, `### Sub-agent behavior (Claude-only)`) —
  insertion neighbors verified: `**Agent-team stage lifecycle…**` at CLAUDE L402, `**Trinity
  exemption.**` at L418; insert-between is valid. AGENTS/GEMINI have ZERO `### Sub-agent behavior`
  (measured `grep -c` = 0/0) → Claude-only placement correct. Load-bearing fresh-agent-default
  subordination clause preserved verbatim. COMPLIANT.
- **Bullet C** (`reconciliation-instance-independence`, ×3, `### Agent invocation rules`, after
  `**No prior reviews to pack-reviewer.**`) — anchor verified ×3: CLAUDE L269 / AGENTS L259 /
  GEMINI L233. Text matches D3-ADDENDUM §1.2 verbatim incl. the 3 load-bearing clauses
  (NEVER-author/NOR-reviewer; EXCEPT docs-researcher; REINFORCES fresh-agent-default). COMPLIANT.
- **R1/R2/R3 rationale sections** — bare-slug headings confirmed against Check 45 regex
  `^##\s+([a-z0-9][a-z0-9-]*)\s*$` (validate-pack.py L7384). Placement unspecified — see Finding 3.
- **4 STRIPs:**
  - **S1** (CLAUDE L415-417, Agent-team bullet tail) — verified present: `(Codex / Antigravity
    have no peer-messaging equivalent — confirmed absent per Codex issue #12462 and Antigravity's
    hub-and-spoke subagent model).` Replacement matches RECONCILED §1.1 P3. COMPLIANT.
  - **S4** (CLAUDE L418-422, standalone `**Trinity exemption.**` bullet) — verified present:
    `…none of which have equivalents in Codex CLI or Antigravity CLI per research §2.5 / §2.7 /
    §3.5 / §3.7.` This is the 4th STRIP per L418-CORRECTION; the plan correctly carries it as a
    plan-table addendum row (§2.6 + the L418-CORRECTION §4.4 row) and it joins Commit 1. The plan
    body still labels §2.6 as an "OPEN ITEM the coder MUST surface (do NOT strip)" — see Target-1
    sub-note below. PARTIAL.
  - **S2** (RATIONALE L193, Codex line inside `## preflight-stop-means-stop`) — verified present:
    `- Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462).` Replacement
    matches RECONCILED §1.1 P4 (Codex line only; Antigravity line L196+ untouched). COMPLIANT.
  - **S3** (METHODOLOGY L94-100, SHIPPED) — verified present: blockquote `This convention is
    Claude-Code-specific:` … `no peer-messaging analog;` … `hub-and-spoke` … `peer-messaging
    across multiple parent turns).` Replacement matches RECONCILED §1.1 P3b (client-audience, no
    #12462/multi_agent_v2 jargon). COMPLIANT.
- **6 project surfaces** (PR1/PR2 + CPR1a/b/c + CPR2) — all anchors verified: `## Project memory`
  ×3 (CLAUDE L349 / AGENTS L326 / GEMINI L346); PM-CHAT `### In-session agent spawning` L454,
  `**Spawn in the background.**` L506, `> **Per-project Claude memory cache (Claude-only).**`
  L897, `re-spawn a fresh coder` L539/L591. CPR1 project roster matches the live
  `project-template/.claude/agents/` set (architect/auditor[+6]/coder/docs-researcher/grpc-schema/
  planner/repo-ops/reviewer/tester). COMPLIANT.
- **2 out-of-repo memory edits** (M1/M2/M3 + optional M4) — flagged for Pack Chat, not coder
  edits; all 3 target files exist (the plan's §13 claim #18 measured them). COMPLIANT.
- **BD-217 scope-note** (G1) — flagged pack-chat-only; coder must NOT touch `backlog/BD-217.md`.
  BD-217.md re-read: title "Codex + Gemini worktree-isolation support", Status Deferred / v11.1 —
  confirms RECONCILED §4's finding that BD-217 is the worktree BD that does NOT yet own discovery.
  COMPLIANT.

**Target-1 sub-note (carried as part of the S4 PARTIAL, NOT a separate finding).** The plan body
§2.6 still frames CLAUDE.md L418-422 as an OPEN ITEM the coder must "leave UNTOUCHED … surface in
the IMPL-REPORT." The L418-CORRECTION (the user's settled 4th-STRIP decision) RESOLVES that open
item: L418-422 IS now S4 and IS stripped in Commit 1. The plan's §2.1 addendum row + §4.3/§4.4
(from L418-CORRECTION) say "strip it"; the plan's §2.6 body + §12.2 gate #7 + §14 risk #1 still say
"leave it untouched." These two halves of the plan CONTRADICT each other. This is the single most
important fidelity item: a coder reading §2.6 + gate #7 literally would LEAVE the stale clause and
the BD would ship a half-corrected CLAUDE.md (the exact failure mode §14 risk #1 warns of). The
reconciliation planner MUST reconcile the plan to a single voice: S4 is IN scope (strip per
L418-CORRECTION §2 text), delete the "OPEN ITEM / leave untouched" framing in §2.6, FLIP §12.2
gate #7 from "→ 1 (leave it)" to a grep-ZERO gate (`grep -c "none of which have equivalents\|per
research §2.5 / §2.7 / §3.5 / §3.7" CLAUDE.md → 0`), and update §14 risk #1 to "RESOLVED — S4
included." **I am recording this as part of Finding 6 below (BLOCKER-adjacent), not as a pass.**

### Target 2 — Commit split: **PASS**
The 2-commit split is correct.
- **Commit 1** (`pack-only` clean): A1/A2/A3 + B1 + C1/C2/C3 + R1/R2/R3 + S1 + **S4** + S2.
  Files: CLAUDE.md, AGENTS.md, GEMINI.md, pack-ops/PACK-MEMORY-RATIONALE.md — all pack-ops. NO
  `project-template/` or `supporting-docs/` path → Check 36 `pack-only` claim VALID. S4 correctly
  sits in Commit 1 (CLAUDE.md is pack-ops; L418-CORRECTION §4.2 confirms). VERIFIED: Check 45
  (26↔26) + Check 18 pack-root parity both fall in Commit 1 (all 3 corpus slugs + 3 rationale +
  trinity ×3 here).
- **Commit 2** (NO keyword): S3 (supporting-docs/METHODOLOGY.md) + PR1/PR2/CPR2 (PM-CHAT) +
  CPR1a/b/c (project trinity). Mixed product surface (`supporting-docs/` + `project-template/`)
  → `project-only` does NOT fit (S3 is supporting-docs/, denied under project-only) and
  `pack-only` does NOT fit → NO keyword (Check 36 skipped). CORRECT. Check 18 project-template
  parity falls in Commit 2 (CPR1 ×3 here). CONFIRMED: CPR1 lives in `## Project memory`, NOT
  `## Pack memory`, so it does NOT affect Check 45 bijection — Commit 1's 26↔26 is undisturbed by
  Commit 2.

### Target 3 — Rebase-on-BD-240 robustness: **ROBUST (the CRITICAL verdict — PASS)**
This is the load-bearing adversarial target and the plan PASSES it. Re-measured the collision map:
- BD-240 (Status: Open at af73ffb — NOT yet landed; verified `grep "^Status:" backlog/BD-240.md`)
  edits the `graph-first-context` rule. Measured its region: CLAUDE.md L637-706 (the LAST rule in
  `## Pack memory`, ending just before `### Project goals` at L708) + RATIONALE.md
  `## graph-first-context` (L638-684, the LAST section, at EOF).
- BD-241's edit regions (measured): CLAUDE.md `### Agent invocation rules` (L242-347, Bullets A/C)
  + `### Sub-agent behavior (Claude-only)` (L348-422, Bullet B + S1 + S4); RATIONALE.md S2 inside
  `## preflight-stop-means-stop` (L138-208) + 3 new sections (placement TBD — Finding 3).
- **The regions are DISJOINT** — BD-240 touches the file TAIL; BD-241 touches the file MIDDLE
  (CLAUDE) and an early section + TBD (RATIONALE). No line-range overlap exists. Because the plan
  anchors every surface on a CONTENT literal (not a bare line number — §15 measure-then-bound
  COMPLIANT, re-verified), BD-240's line-shift of the file tail does NOT move BD-241's middle
  anchors out from under the coder.
- The ONLY adjacency risk is Finding 3 (R1/R2/R3 appended at EOF would abut BD-240's edited tail);
  fixing Finding 3 removes even that. The plan's §3.4 explicitly handles the bijection-count shift
  ("do NOT hard-code 26 — if BD-238/BD-240 land first, the baseline shifts"). The plan's §11.1 +
  §14 risk #3 correctly mandate base-on-prior-landed-HEAD + never-hand-merge. **No spot in the plan
  assumes the pre-BD-240 (af73ffb) state in a way that breaks post-BD-240.** The one gap is the
  missing base-predecessor assertion (Finding 5), which is a coder-hygiene MINOR, not a structural
  break. **Rebase-on-BD-240 verdict: ROBUST.**

### Target 4 — Bijection (Check 45): **PASS**
Baseline re-measured: `Check 45 — 23 corpus … 23 rationale … bijection holds`. The plan adds +3
corpus slugs (A/B/C, all `[rationale:]`-tagged — verified the tag is what engages Check 45, not
the role tag) + 3 bare-slug rationale sections → 26↔26, all in Commit 1. CONFIRMED: Check 45 scans
from `## Pack memory` to the next `## ` H2 (validate-pack.py L7367-7373); `### Sub-agent behavior
(Claude-only)` is an H3, so Bullet B's slug IS in the corpus set and DOES require its rationale
section — the plan's §3.2/§3.4 claim is correct. The 4 STRIPs (S1-S4) are untagged prose (S4
verified: `sed -n '418,422p' CLAUDE.md | grep "rationale:\|roles:"` → 0 hits) → 0 bijection impact.
`[roles: universal]` confirmed valid (20 in-use occurrences). PASS.

### Target 5 — Anti-restate (Check 46): **PASS**
The 6 scanned surfaces are `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, and 4 skill
SKILL.md (validate-pack.py `_CHECK_46_ANTI_RESTATE_SURFACES`, L7459-7466). **No `project-template/`
and no `supporting-docs/` file is scanned** — so CPR1/CPR2/PR1/PR2 (project-audience) and S3
(METHODOLOGY) CANNOT trip Check 46 regardless of wording. The 3 new CLAUDE.md bullet bodies become
new candidate bodies (count rises 49→~52, re-measured baseline = 49) but appear in NONE of the 6
surfaces → 0 restate hits. The 120-char leading-window mechanic (≥60 chars) is correctly described.
The optional PACK-CHAT.md pointer (§3.2.1) IS a scanned surface and is correctly flagged
measure-then-bound with a recommended SKIP. PASS.

### Target 6 — METHODOLOGY (S3) shipped-file edit: **PASS**
S3 is audience-correct (client-developer audience; drops #12462/multi_agent_v2 pack-internal
jargon per RECONCILED §1.1 P3b) — NOT a byte-copy of the CLAUDE.md clause. The grep-derived
KEEP/STRIP census holds: the 5 KEEP surfaces are measured-correct (different capabilities:
worktree / per-project memory / conditional guard), and the STRIP set is exactly {S1,S2,S3,S4}.
Install map verified: `scripts/init-project.sh` L685 copies METHODOLOGY to `docs/pack/`. The plan
correctly keeps the final routing sentence and directs the coder to preserve `> ` blockquote
markers. (NOTE: the KEEP-surface GATE literals are wrong — Finding 1 — but the census CLASSIFICATION
is correct; the defect is in the verification gate, not the strip design.) PASS on the edit; the
gate defect is Finding 1.

### Target 7 — rule-10: **PASS**
The plan states BD-238/240/241 serialize on trinity + RATIONALE (§11.1) and the project-trinity
edit (CPR1) serializes with BD-239 (§11.1 table + §14 risk #3). It mandates base-on-prior-landed-
HEAD + never-hand-merge ("if a base is stale, STOP and re-spawn the coder on the fresh HEAD").
The intra-BD-241 serialization (shared files within the BD) is correctly noted. The only gap is the
missing explicit base-predecessor assertion (Finding 5). PASS with the Finding-5 MINOR.

### Target 8 — Green-after-execute: **PASS (post-fix)**
Post-execution (post-BD-240) the FULL validate-pack will pass: Check 45 26↔26, Check 46 7
records/0 restate, Check 18 pack-root + project-template parity, Check 36 (Commit 1 pack-only
valid / Commit 2 no keyword), Check 62 push-time manifest (S3 + PM-CHAT + project trinity fixture
inputs reconciled at push, NOT per-commit — correctly flagged for the orchestrator). No check is at
risk PROVIDED Finding 6 (the S4 self-contradiction) is reconciled so the coder actually strips S4 —
otherwise the BD's correction-completeness goal (not a CI check) is unmet. PASS contingent on the
findings being applied.

---

## Finding 6 [MAJOR, fidelity-critical] — the plan CONTRADICTS ITSELF on S4: §2.1/§4.3/§4.4 say "strip L418-422"; §2.6/§12.2-gate-#7/§14-risk-#1 say "leave it untouched"

**Location:** PLAN-BD-241.md §2.6 (lines 115-131), §12.2 gate #7 (lines 642-644), §14 risk #1
(lines 691-694) — versus the L418-CORRECTION-derived addendum (§2.1 S4 row in the corrected plan,
§4.3/§4.4 of the L418-CORRECTION).

**The defect.** The L418-CORRECTION is a SETTLED design input (the user DECIDED 2026-06-20 to
include L418-422 as the 4th STRIP, S4, in Commit 1). The plan PLAN-BD-241.md, however, was authored
in a state where §2.6 still treats L418-422 as an unresolved OPEN ITEM: "leave L418-422 UNTOUCHED …
surface it … do NOT edit it without explicit direction." §12.2 gate #7 enforces that stale
position: `grep -c "none of which have equivalents in Codex CLI" CLAUDE.md → 1 (… leave it)`. §14
risk #1 frames it as an open user decision. The L418-CORRECTION resolves all of this (S4 IS stripped),
but the plan's body was NOT updated to absorb the resolution — only the addendum row was added.

**Why MAJOR/fidelity-critical.** A coder is handed the WHOLE plan. Reading §2.6 + gate #7 + risk #1
literally, the coder LEAVES the stale clause AND the PREFLIGHT gate #7 (`→ 1`) PASSES on the
UNSTRIPPED state — so the coder's PREFLIGHT would GREEN-LIGHT a tree where S4 was never corrected.
The result is precisely the half-corrected CLAUDE.md (S1 fixed, the adjacent L418-422 still saying
"no equivalents") that §14 risk #1 itself warns against. This is a direct path to shipping the BD's
target falsehood. It is not a CI failure (validate-pack stays green either way), which is exactly
why it is dangerous — only the BD's correctness goal catches it.

**The concrete fix (reconciliation planner MUST apply, single-voice the plan to S4-IN-scope).**
1. §2.6: DELETE the "OPEN ITEM … leave UNTOUCHED … surface-but-do-not-strip" framing. Replace with
   "S4 RESOLVED — per the L418-CORRECTION the user included L418-422 as the 4th STRIP (Commit 1);
   apply the §2 text from DESIGN-BD-241-L418-CORRECTION (PARTIAL correction: correct the
   peer-messaging leg, preserve the Agent-tool/`run_in_background` leg + the exemption opener)."
2. §12.2 gate #7: FLIP from `grep -c "none of which have equivalents in Codex CLI" CLAUDE.md → 1
   (leave it)` to a grep-ZERO gate: `grep -c "none of which have equivalents\|per research §2.5 /
   §2.7 / §3.5 / §3.7" CLAUDE.md → 0` (S4 stale phrasing removed) PLUS a grep-PRESENT for the
   preserved leg: `grep -c "run_in_background" CLAUDE.md → ≥1` and `grep -c "not\b.*mirrored in"
   CLAUDE.md → ≥1` (exemption opener survives).
3. §14 risk #1: change from an open user decision to "RESOLVED — S4 included as a 4th STRIP."
4. Add S4 to the §3.4-style bijection note as "+0 slugs (untagged prose)" so it is explicit S4 has
   no Check-45 impact.

(I assign this MAJOR rather than BLOCKER because the L418-CORRECTION addendum DOES carry the strip
instruction, so a careful coder reading ALL inputs would catch the conflict and ask — but a plan
that contradicts itself on its single most-sensitive surface fails the coder-executability bar and
must be reconciled before the gate. Combined with Finding 1, the reconciliation planner has two
must-fix items.)

---

## Summary of required reconciliation-planner edits (in priority order)
1. **Finding 6 (MAJOR, fidelity-critical):** single-voice the plan to S4-IN-scope — rewrite §2.6,
   FLIP §12.2 gate #7 to grep-ZERO + preserved-leg grep-PRESENT, update §14 risk #1.
2. **Finding 1 (MAJOR):** fix §12.2 gate #6 KEEP-surface grep literals (lowercase `memory` /
   `worktree`, or use `grep -ci`).
3. **Finding 2 (MINOR):** normalize §2.5 + §13-claim-#10 KEEP quotes to the measured lowercase text.
4. **Finding 3 (MINOR):** give R1/R2/R3 a content-anchored insertion point off BD-240's tail
   section.
5. **Finding 4 (MINOR):** tighten §12.2 gate #6's final `git diff` parenthetical.
6. **Finding 5 (MINOR):** add a PREFLIGHT base-predecessor assertion (`git log | grep BD-240`).

None of these re-open the settled design. The architecture (commit split, bijection, anti-restate,
rebase-robustness, Check 36, S4 placement-in-Commit-1) is correct; the rework is confined to plan
internal consistency (Findings 6/2), gate literals (Findings 1/4), and two coder-hygiene anchors
(Findings 3/5).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | Every finding backed by a re-run command + verbatim output at HEAD `af73ffb`/2026-06-20: Finding 1 (`grep -c "no equivalent per-project MEMORY mechanism" …` → 0; actual `no equivalent per-project memory` at PM-CHAT L908; `WORKTREE story is tracked` → 0/0; actual `worktree story is tracked` at OPTIONAL-FEATURES L283/L284); Finding 3 (`## graph-first-context` = last RATIONALE section L638, EOF L684); Target 3 (BD-240 region CLAUDE L637-706 vs BD-241 L242-422 — disjoint); Target 4 (Check 45 baseline 23↔23 via `validate-pack.py`; scan boundary L7367-7373); Target 5 (`_CHECK_46_ANTI_RESTATE_SURFACES` L7459-7466 = 6 surfaces, no project-template); baseline candidate bodies = 49 (re-counted). | COMPLIANT |
| adversarial-planner-review (mandate) | Challenged every load-bearing claim by re-measurement, not confirmation; constructed the rebase counterexample (Target 3 + Finding 5 wrong-but-valid-base case); found the plan's self-contradiction on S4 (Finding 6) that the plan's own self-assessment did not surface; falsified two PREFLIGHT gates (Finding 1) the plan claimed measure-then-bound COMPLIANT. | COMPLIANT |
| ci-guard-design-measure-then-bound | Measured Check 36 (split valid both commits), Check 45 (26↔26, scan boundary), Check 46 (6 surfaces, project-template excluded), Check 62 (push-time) implications against the actual validator code before concluding green; did not assert. | COMPLIANT |
| rename-plans-measure-then-bound / measure-then-bound | Verified the plan anchors on content literals (not bare line numbers) for every surface; the EXCEPTION is the two KEEP-gate literals (Finding 1, miscased) + the R1/R2/R3 placement (Finding 3, unspecified) — both flagged as measure-then-bound gaps. | COMPLIANT (gaps reported) |
| separate-pack-ops-from-product | Verified the commit split keeps pack-ops (Commit 1: trinity + RATIONALE + S4) separate from product (Commit 2: shipped METHODOLOGY S3 + project-template); S4 correctly pack-ops (Commit 1); Check 36 honesty verified for both. | COMPLIANT |
| graph-first-context | Ran `graphify query "agent invocation rules sub-agent behavior reconciliation registry peer messaging" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST → returned fixture/provenance nodes only (rule-corpus concept not a graph node) → G2 fallback to grep/Read for every load-bearing surface. | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Read-only git only (`git rev-parse HEAD`, `git status --short`, `git log --oneline`, `git branch`); ZERO state-changing verbs; sole filesystem write = this review doc at `/tmp/pack-handoff-bd241-plan/ADVERSARIAL-PLAN-REVIEW-BD-241.md`. No destructive op. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, COMPLIANT terminal; includes the graph-query-ran row above. No empty-evidence rows. | COMPLIANT |
| graph-query-ran (evidence row) | `graphify query "…" --graph <injected absolute path> --backend claude-cli --budget 1500` executed FIRST (injected path, not self-derived); result = fixture/provenance nodes only → G2 fallback. | COMPLIANT |

---

*End ADVERSARIAL-PLAN-REVIEW-BD-241. Fresh independent read-only pack-planner adversarial review;
no patch produced; sole write is this doc. Verdict: NEEDS-REWORK (0 BLOCKER / 2 MAJOR / 4 MINOR).
Rebase-on-BD-240: ROBUST. The design is sound; the rework is confined to plan internal consistency
(S4 self-contradiction), two miscased PREFLIGHT KEEP-gate literals, and two coder-hygiene anchors.*
