# ADVERSARIAL-REVIEW-BD-241 — independent re-measurement of DESIGN-BD-241

**Agent:** pack-architect (READ-ONLY, FRESH/ADVERSARIAL) · **Date:** 2026-06-20
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`,
HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`).
**Under review:** `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241.md`.
**Inputs read in full:** the design; RESEARCH-BD-241-EXTERNAL.md; RESEARCH-BD-241-INTERNAL.md;
`backlog/BD-241.md`; `backlog/BD-217.md`; both reconcile-rule memory files;
`pack-ops/PACK-CHAT.md` § "Keeping … current"; `pack-ops/PACK-MEMORY-RATIONALE.md`;
the trinity `### Sub-agent behavior (Claude-only)` sub-section; `scripts/validate-pack.py`
Checks 18/45/46; `scripts/init-project.sh` METHODOLOGY install map.
**Method:** I did NOT read the design's self-assessment as authoritative. I re-ran the graph
query first (dogfooding `graph-first-context`), then re-measured EVERY load-bearing state-claim
with grep/Read against HEAD `af73ffb`. Empirical-Evidence Block at §C.

---

## VERDICT: NEEDS-REWORK

**Counts:** 1 BLOCKER · 4 MAJOR · 4 MINOR.

The design is largely sound on the registry-mechanism / location / lookup-precedence /
corpus-elevation mechanics — those re-measure as correct. But it FAILS the
adversarial bar on **propagation completeness** (the same class of miss the spawn
prompt warned about — the BD-240 OPTIONAL-FEATURES analogue): the stale-rationale
correction (#1) is INCOMPLETE and, worse, leaves a now-FALSE factual claim in a
**client-shipped** deliverable (`supporting-docs/METHODOLOGY.md`, which installs to
`docs/pack/METHODOLOGY.md`). The design's own Empirical-Evidence claim #1 ("lives in
exactly 2 in-tree surfaces") is measurably false. Secondary gaps: the cross-CLI naming
discipline is buried inside a Claude-only-located bullet where Codex/Antigravity readers
never see it (parity gap); the P5↔P6 manifest coupling is under-specified; the BD-217
handoff over-states BD-217's current scope.

---

## A. ADVERSARIAL FINDINGS (numbered, severity-tagged, with exact fix)

### BLOCKER-1 — The stale-rationale correction (#1) is INCOMPLETE and ships a falsehood to clients

**The design's claim (Empirical-Evidence #1, §0 bullet 6, §6.4):** the stale
"#12462 / confirmed-absent / hub-and-spoke" rationale "lives in exactly 2 in-tree
surfaces" — `CLAUDE.md` L415-416 and `pack-ops/PACK-MEMORY-RATIONALE.md` L193 — and
those are the only two corrected.

**Re-measurement (adversarial, HEAD af73ffb):**
```
$ grep -rln "no peer-messaging|have no equivalent|peer-messaging equivalent|confirmed absent|hub-and-spoke" --include="*.md" .  (excl .git, test-fixtures, maintenance-docs/archive)
CLAUDE.md
project-template/docs/pack/OPTIONAL-FEATURES.md
project-template/docs/pack/PM-CHAT.md
backlog/BD-241.md
pack-ops/PACK-MEMORY-RATIONALE.md
pack-ops/OPTIONAL-FEATURES.md
supporting-docs/METHODOLOGY.md
```
Triaging each (KEEP-correct vs STALE-must-fix):
- `CLAUDE.md` L415-416 — **STALE** (design catches it; correct).
- `pack-ops/PACK-MEMORY-RATIONALE.md` L193 — **STALE** (design catches it; correct).
- `supporting-docs/METHODOLOGY.md` L96-99 — **STALE + MISSED.** Verbatim:
  > "Codex CLI's `/agent` slash command provides similar long-lived-thread
  > behavior but **no peer-messaging analog**; Antigravity CLI's subagent
  > mechanism is **hub-and-spoke** (a parent dispatches subagents; no
  > parent-controlled keep-alive or **peer-messaging** across multiple parent
  > turns)."
  This is the SAME now-false factual claim the correction exists to fix. The design
  explicitly dispositions METHODOLOGY as "NO EDIT REQUIRED … OPTIONAL thin pointer at
  most" (§6.5, §7.1 last NO-EDIT row, §7.2 PR-table) — i.e. it CLEARS the exact surface
  that carries the contradiction.
- `project-template/docs/pack/PM-CHAT.md` L539 + `project-template/docs/pack/OPTIONAL-FEATURES.md`
  L114 + `pack-ops/OPTIONAL-FEATURES.md` L113 — **KEEP (NOT stale).** These are
  CONDITIONAL guards ("if your CLI offers no peer-messaging, re-spawn a fresh coder"),
  which make no "confirmed-absent" factual assertion and remain correct. No edit needed.
- `backlog/BD-241.md` L8/L12 — entry prose ("Codex/Antigravity have no peer-messaging /
  confirmed absent"). The entry is pack-chat-only governance; arguably leave as
  provenance, but it should at minimum not be cited as still-true (see MINOR-4).

**Why this is a BLOCKER, not a MINOR:** `supporting-docs/METHODOLOGY.md` is a
**client-shipped deliverable** — it installs to `docs/pack/METHODOLOGY.md` at init:
```
$ grep -n METHODOLOGY scripts/init-project.sh
685:  cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
1298: "supporting-docs/METHODOLOGY.md:docs/pack/METHODOLOGY.md:generic"
```
So the design as written would land a BD whose stated purpose is "correct the stale
'confirmed absent' rationale" while LEAVING that exact falsehood in a file the pack
ships to every new client. The correction is self-defeating where it matters most.
This is precisely the failure mode the spawn prompt flagged (the BD-240 adversarial
pass found OPTIONAL-FEATURES wrongly cleared) — BD-241 has the analogous miss in
METHODOLOGY.

**Fix the reconciliation architect MUST make:** RECLASSIFY `supporting-docs/METHODOLOGY.md`
L96-99 from "NO EDIT / optional" to a **REQUIRED correction surface** for correction #1.
Edit the blockquote to drop the now-false "no peer-messaging analog … hub-and-spoke … no
peer-messaging across multiple parent turns" assertions, replacing with the
project-audience-correct paraphrase of the §6.4 corrected text (Codex MAv2 + Antigravity
`agy` analogs exist but are flag-gated / partly-unverified; the convention stays
Claude-specific here). This is a pack-side methodology doc that SHIPS, so apply the
`cross-cli-reference-normalization` audience-correct wording, not a byte-copy of the
CLAUDE.md clause. Add it as a REQUIRED row (not the dropped NO-EDIT row) and rebuild the
§A.4 measure-first census so the correction's surface set is grep-derived, not
hand-enumerated.

### MAJOR-1 — The cross-CLI NAMING discipline is buried in a Claude-only-located bullet; Codex/Antigravity readers never see it (parity gap)

**The REVISED SCOPE (user 2026-06-20, in the spawn prompt):** v11.0 ships
"the CLAUDE registry/find/resume mechanism **+ a cross-CLI unique-NAMING discipline**."
So the naming discipline is explicitly a CROSS-CLI v11.0 deliverable, not Claude-only.

**What the design does (§5.4 rule text, §0 bullet 1):** it folds the cross-CLI naming
discipline INTO the single combined bullet placed in `CLAUDE.md`'s
`### Sub-agent behavior (Claude-only)` sub-section ("The unique-NAMING discipline
applies on ALL CLIs; the registry+find MECHANISM is Claude-only here"). On the project
side it adds PR1 (a CLI-agnostic naming line in PM-CHAT.md).

**The adversarial problem (re-measured):** AGENTS.md (Codex audience) and GEMINI.md
(Antigravity audience) each carry their OWN spawn-construction home —
```
$ grep -n "### Agent invocation rules" AGENTS.md GEMINI.md
AGENTS.md:244:### Agent invocation rules
GEMINI.md:211:### Agent invocation rules
```
— and they do NOT carry (and never read) CLAUDE.md's Claude-only sub-section
(`grep "Sub-agent behavior" AGENTS.md GEMINI.md` → 0 hits). A Codex or Antigravity
PM-chat reading AGENTS.md/GEMINI.md will NOT discover the cross-CLI naming discipline,
because the only PACK-side home the design gives it is a CLAUDE.md sub-section those
audiences never consult. The design even confirms no naming discipline exists in
AGENTS/GEMINI today (`grep -niE "uniquely name|name every spawn" AGENTS.md GEMINI.md` →
0 hits). So a discipline the user scoped as cross-CLI is, in practice, Claude-only on
the pack side.

**Why MAJOR (not MINOR):** this is a direct miss of an explicit user-scoped v11.0
deliverable, AND it is a trinity-rule judgment error: the design treats a genuinely
cross-CLI rule as single-surface by co-locating it with the Claude-only mechanism. The
trinity rule's parity default applies to the CROSS-CLI portion (the naming discipline);
only the MECHANISM portion is legitimately Claude-only/single-surface.

**Fix the reconciliation architect MUST make:** SPLIT the bullet. (a) The cross-CLI
unique-NAMING discipline belongs in a trinity-PARITY home that all three CLIs read — the
existing `### Agent invocation rules` sub-section is the natural fit (it exists in
CLAUDE.md L242, AGENTS.md L244, GEMINI.md L211 and already houses "Agent prompt
requirements"). Author the naming rule there ×3 (audience-correct per
`cross-cli-reference-normalization`: Claude says "Agent-tool `name`", Codex/Antigravity
say their analog), OR explicitly justify (with evidence) why a cross-CLI discipline may
live only in the Claude-only sub-section. (b) Keep ONLY the registry+find MECHANISM
(registry file, name→agentId precedence, SendMessage) in the Claude-only sub-section.
Re-derive the propagation table (§7) for the now-split surfaces and re-check Check 18
(an `### Agent invocation rules` bullet does not change H2 parity, but a new trinity
bullet must land ×3 in the SAME commit).

### MAJOR-2 — P5 (.spawn-rule-manifest.txt) is presented as independently "YES if spawn-relevant"; it is COUPLED to a REQUIRED P6, and it injects a Claude-only rule into a manifest documented as trinity-only

**The design (§7.1 P5/P6, §10 Q3):** marks P5 (add a `.spawn-rule-manifest.txt` record)
as "YES if … spawn-relevant" and P6 (the PACK-CHAT.md paraphrase reference) as merely
"RECOMMENDED". §8.1 lists "P1+P2+P5 (corpus+rationale+manifest, same commit)" as the
bijection group — but OMITS P6 from that same-commit group.

**Re-measurement of Check 46 (a2) (`scripts/validate-pack.py` L7642-7700):** the
spawn-manifest reference-resolution REQUIRES every record's `references:` field to NAME a
known reference surface (`PACK-AGENTS.md` or `PACK-CHAT.md`) AND that surface must exist
AND carry the canonical `## Pack memory` pointer. Verbatim FAIL condition:
"the `references:` field names no known reference surface (expected one of
['PACK-AGENTS.md','PACK-CHAT.md'])". **Consequence:** if the coder adds the P5 manifest
record but treats P6 as optional/omits it, Check 46(a2) FAILS — a record with no resolving
reference surface is a hard error. P5 and P6 are NOT independent; P5 FORCES P6 (or P7).
The design's "P6 RECOMMENDED / P5 YES-if" framing invites exactly the half-applied state
that breaks the gate.

**Second issue (category):** `.spawn-rule-manifest.txt` is documented (its own header,
verified) as recording rules whose "imperative lives in trinity `## Pack memory`
(CLAUDE.md / AGENTS.md / GEMINI.md at pack root)". All 7 current slugs are cross-trinity
universal rules. `spawn-name-registry` is Claude-only/single-surface — it would be the
FIRST single-surface entry in a manifest whose stated contract is trinity. Check 46 keys
on CLAUDE.md only so it won't FAIL, but the manifest's documented purpose no longer
matches its contents.

**Fix:** (a) If a manifest record is wanted, make P5 and P6 a SINGLE coupled
requirement in the SAME commit (record + its resolving PACK-CHAT.md pointer), and add
both to the §8.1 bijection-group sentence. (b) Reconsider whether
`spawn-name-registry` belongs in `.spawn-rule-manifest.txt` at all given it is
single-surface — EITHER justify the first Claude-only manifest entry and note the
header's trinity wording now over-claims (a one-line header note), OR drop P5/P6
entirely (the rule is still gated by Check 45 bijection via P1+P2; the manifest is for
collapsed cross-trinity restatements, of which a Claude-only rule has none). Resolve this
as a design decision, not a "confirm with planner" deferral.

### MAJOR-3 — The BD-217 handoff over-states BD-217's current scope (BD-217 is a WORKTREE BD, not an agent-discovery/peer-messaging BD)

**The design (§0 bullet 7, §6):** "co-designed with BD-217 (which already owns cross-CLI
agent coordination + mandates per-platform verify-availability)."

**Re-measurement (`backlog/BD-217.md`, HEAD af73ffb):** BD-217's title is
"Codex + Gemini **worktree-isolation** support (platform-specific; the cross-CLI half of
BD-197)". Its Type, Scope, Hard-constraints, Out-of-scope, References, and Acceptance
criteria are ALL about worktree isolation + the agents-never-commit merge-back model. It
says NOTHING about agent naming, a spawn registry, peer-messaging, or name→agentId
discovery. Its Blockers gate on BD-197 (the worktree reference model). So BD-217 does
NOT "already own cross-CLI agent coordination" in the generic sense the design implies —
it owns cross-CLI WORKTREE coordination, narrowly.

**Why MAJOR:** routing the cross-CLI registry/find/resume mechanism to BD-217 as if BD-217
already encompasses it (a) mis-frames the handoff (the planner/user may assume BD-217's
existing acceptance criteria cover it — they do not), and (b) risks the deferred work
having NO real tracked anchor inside BD-217's actual scope, violating
`deferred-work-tracked-anchor`. The handoff is plausible (both are cross-CLI agent-coordination
concerns and BD-241 is correctly Claude-first), but BD-217's entry must be UPDATED to
explicitly take on the discovery mechanism, or a distinct anchor named.

**Fix:** EITHER (a) recommend a one-line scope-addition to `backlog/BD-217.md` (a
"Note: also covers the cross-CLI analog of BD-241's spawn registry/find/resume" line —
which is a pack-chat-only governance edit the user can authorize at the design gate), OR
(b) name a separate v11.1 anchor for the cross-CLI discovery mechanism. Do NOT describe
BD-217 as already owning it. Also flag the contradiction noted in MINOR-1 below.

### MINOR-1 — Correcting the stale rationale in BD-241/CLAUDE.md while BD-217's premise stays stale is an internal inconsistency to flag

**Observation:** BD-217's Description (L9) rests on the worktree premise, not the
peer-messaging one, so it is NOT directly contradicted. BUT BD-241's whole correction #1
declares "#12462 CLOSED-COMPLETED; Codex MAv2 + Antigravity analogs exist" — and BD-217's
own framing (and the broader trinity exemption it inherits) still implicitly leans on the
"Claude-only because the others lack the capability" stance for the MECHANISM. The design
should, per the spawn prompt's target 6, EXPLICITLY note that once correction #1 lands,
the trinity-exemption rationale shifts from "capability absent" to "capability present
but flag-gated/unverified" — and confirm BD-217's entry carries the corrected premise
when it picks up the cross-CLI work. **Fix:** add a one-line note in §6 that BD-217's
premise must be re-stated as "analogs exist but flag-gated/unverified" (not "absent") when
the cross-CLI mechanism is designed, so the two BDs do not encode contradictory cross-CLI
capability claims.

### MINOR-2 — Anti-restate (Check 46b) risk on the P6 paraphrase is asserted, not measured

**The design (§9 Check 46 row, §5.4):** asserts P6/P7 "PARAPHRASE (one-line ref … not
the body)" and is therefore safe.

**Re-measurement:** Check 46's anti-restate extracts each `## Pack memory` body's leading
120-char window and FAILS on any ≥60-char verbatim reappearance in the 6 scanned surfaces
(`scripts/validate-pack.py` L7484, L7553-7556; baseline: "49 candidate bodies scanned, >=
60 chars"). The new rule's body becomes the 50th candidate. The design's P6 sample text
("Name every spawn + record it in `graphify-out/.pack-spawn-registry.jsonl`; re-find by
name→agentId") is short and paraphrased, so it likely clears the 60-char bound — but the
design did NOT measure the proposed P6 string against the proposed rule body, and
`ci-guard measure-then-bound` requires measuring, not asserting. **Fix:** the
planner/coder must compute the new rule body's leading 120-char window and confirm the P6
(and any P7) reference shares no ≥60-char contiguous run with it; record the measurement.
Low risk, but the design should direct the measurement rather than assert the conclusion.

### MINOR-3 — The propagation procedure's step-1 "×3 trinity" has no documented Claude-only carve-out; the design relies on an undocumented exception

**Re-measurement (`pack-ops/PACK-CHAT.md` L501):** propagation step 1 reads
"Corpus imperative line **×3 trinity** (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
`## Pack memory`)". There is no "unless Claude-only" clause. The design's whole §5.3/§7
rests on "a Claude-only rule is single-surface (doesn't mirror ×3)", justified by the
EXISTING Claude-only sub-section precedent and Check 18's per-location design — which I
CONFIRM is correct in behavior (Check 18 is per-H2-per-location; Check 45 scans CLAUDE.md
as corpus representative). But the PROCEDURE DOC does not say so. **Fix:** if BD-241 lands
the FIRST tagged Claude-only corpus rule, the design should recommend a one-line addition
to the PACK-CHAT.md step-1 row noting "(a Claude-only sub-section rule is single-surface —
no ×3 mirror; see the existing `### Sub-agent behavior (Claude-only)` precedent)", so the
next author isn't tripped by the contradiction. Pack-chat-only edit; surface at the gate.

### MINOR-4 — E2a tagging is sound, but "first tagged bullet" is mischaracterized as harmless without confirming the rationale-section format

**Re-measurement (confirms the design's premise, refines the conclusion):** the 4 existing
Claude-only bullets ARE untagged (`sed -n '348,422p' CLAUDE.md | grep -E "\[roles:|\[rationale:"`
→ 0 hits) — design claim CONFIRMED. Check 45 scans the WHOLE `## Pack memory` H2
including the H3 Claude-only sub-section (the scan loop only resets `in_pack_memory` at
`## ` H2 boundaries — `scripts/validate-pack.py` L7366-7374), so a `[rationale:]` tag on a
Claude-only bullet IS picked up and DOES require a matching `## spawn-name-registry`
rationale section. E2a mechanics are correct (24↔24 if P1+P2 land together; baseline 23↔23
verified). **The refinement:** the design says being the first tagged bullet is "cosmetically
inconsistent but functionally correct" — true, but it should also confirm the NEW rationale
section follows the exact `## <slug>` lowercase-kebab heading format the bijection regex
requires (`^##\s+([a-z0-9][a-z0-9-]*)\s*$`, L7384) so P2 doesn't silently fail to match.
**Fix:** direct the coder to author `## spawn-name-registry` as a bare slug heading (no
trailing prose on the heading line) and re-run Check 45 after P1+P2. Trivial, but the
design leaves it implicit.

---

## B. WHAT RE-MEASURES AS CORRECT (adversarial confirmations — not rubber-stamps)

These survived the challenge; I re-measured each rather than trusting the design:

1. **Registry location (`graphify-out/.pack-spawn-registry.jsonl`) is NOT a category
   error and a graph rebuild will NOT wipe it.** `.gitignore` L76 ignores the whole
   `graphify-out/` dir; the precedent `graphify-out/.pack-refresh-status` is an
   orchestrator-maintained runtime status file in the same dir. The spawn registry is a
   leaf file with a distinct name; the graphify build writes `graph.json` /
   `.pack-refresh-status` and would not target an unrelated `.pack-spawn-registry.jsonl`.
   The only residual is operational hygiene (a `rm -rf graphify-out/` clean would take it
   — acceptable for session-scoped runtime state, and the design says so). The category
   ("per-clone, gitignored, orchestrator-written, never SSOT") matches. **Caveat the
   design already carries:** durability across a context COMPACTION is the payoff and is
   sound — the file is re-read, not held in context. **Sound.**
2. **`agents-never-commit` genuinely forces gitignored.** A mid-task registry write
   committed would require a mid-task commit (forbidden) or churn the tree per spawn.
   The constraint logic is correct; the path is already ignored (no `.gitignore` edit).
   **Sound.**
3. **name→agentId precedence; message-id tier correctly DROPPED.** External §1.3/§1.4
   measured both name and agentId as `SendMessage.to`, and NO message-id agent-recall
   primitive. Dropping the BD entry's "message-id" tier (rather than inventing it) is the
   `verify-availability` correct call. **Sound.**
4. **`fresh-agent-default` left UNCHANGED; orthogonal-axes reconciliation holds.** The
   registry is consulted only AFTER the re-engage gate; it fixes HOW-to-find, not
   WHEN-to-reengage. I constructed the counterexample the spawn prompt asked for (target
   3): could the registry be READ as encouraging reuse? Answer: only if the rule text
   omits the subordination clause. The design's §5.4 text DOES include "Consult the
   registry ONLY after the `fresh-agent-default` gate authorizes a re-engage." With that
   clause present, the counterexample does NOT survive — the registry is a lookup tool
   gated behind the existing decision, not a new authority to reuse. **Sound, CONDITIONAL
   on the subordination clause remaining verbatim in the final rule text** (call this out
   to the coder as load-bearing — do not let it be trimmed for concision).
5. **Check 18 untouched; Check 45 bijection mechanics correct.** Re-measured: Check 18 is
   per-location per-H2 ("There is NO cross-location parity gate" — L1605-1606 region; the
   design quoted it accurately); a new BULLET inside an existing H3 changes no H2. Baseline
   green (Check 18 runs pack-root + project-template separately). **Sound.**
6. **Graph-first dogfooded; G2 fallback correct.** I ran
   `graphify query "sub-agent spawn name registry agentId discovery SendMessage" --graph
   …/graph.json --backend claude-cli --budget 1500` → 19 nodes, all INTAKE-GROUPINGS
   provenance + tracker-fixture noise; no spawn-registry node. The concept is not a graph
   node; grep/Read is the correct primary tool — the design's method note is accurate.
   **Sound.**

---

## C. EMPIRICAL-EVIDENCE BLOCK (my own re-measurements)

| # | State-claim (mine) | Command | Output (measured) | HEAD/date | Conclusion |
|---|---|---|---|---|---|
| 1 | The stale "confirmed-absent/peer-messaging" claim lives in MORE than the 2 surfaces the design corrects; one is client-shipped | `grep -rln "no peer-messaging\|have no equivalent\|confirmed absent\|hub-and-spoke" --include=*.md .` (excl .git, test-fixtures, archive) | CLAUDE.md; PACK-MEMORY-RATIONALE.md; **supporting-docs/METHODOLOGY.md**; project-template/docs/pack/{PM-CHAT,OPTIONAL-FEATURES}.md; pack-ops/OPTIONAL-FEATURES.md; backlog/BD-241.md | af73ffb / 2026-06-20 | SUPPORTED — design's "exactly 2 in-tree surfaces" is NOT-SUPPORTED |
| 2 | METHODOLOGY's hit is the SAME stale factual claim (not a conditional guard) | `sed -n '84,105p' supporting-docs/METHODOLOGY.md` | "Codex CLI's `/agent` … but **no peer-messaging analog**; Antigravity CLI's subagent mechanism is **hub-and-spoke** … no … **peer-messaging** across multiple parent turns" | af73ffb / 2026-06-20 | SUPPORTED (drives BLOCKER-1) |
| 3 | METHODOLOGY ships to clients | `grep -n METHODOLOGY scripts/init-project.sh` | L685 `cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"`; L1298 install-map record | af73ffb / 2026-06-20 | SUPPORTED (escalates BLOCKER-1 severity) |
| 4 | The PM-CHAT/OPTIONAL-FEATURES hits are CONDITIONAL guards, not stale claims | `sed -n '536,541p' project-template/docs/pack/PM-CHAT.md`; `sed -n '112,116p' project-template/docs/pack/OPTIONAL-FEATURES.md` | "if your CLI offers no peer-messaging, re-spawn a fresh `coder`" (both) | af73ffb / 2026-06-20 | SUPPORTED (these correctly need NO edit — bounds BLOCKER-1) |
| 5 | AGENTS/GEMINI have `### Agent invocation rules` but NO naming discipline and NO Claude-only sub-section | `grep -n "### Agent invocation rules\|Sub-agent behavior" AGENTS.md GEMINI.md`; `grep -niE "uniquely name\|name every spawn" AGENTS.md GEMINI.md` | AGENTS.md:244 + GEMINI.md:211 invocation-rules; 0 "Sub-agent behavior"; 0 naming-discipline hits | af73ffb / 2026-06-20 | SUPPORTED (drives MAJOR-1) |
| 6 | BD-217 scope is worktree-isolation, not agent-discovery/peer-messaging | Read `backlog/BD-217.md` full | title "worktree-isolation support"; Scope/AC/Refs all worktree; zero naming/registry/peer-messaging mention | af73ffb / 2026-06-20 | SUPPORTED (drives MAJOR-3) |
| 7 | Check 46(a2) REQUIRES each manifest record's references to name a known surface | `sed -n '7642,7700p' scripts/validate-pack.py` | FAIL if "the `references:` field names no known reference surface (expected one of ['PACK-AGENTS.md','PACK-CHAT.md'])" | af73ffb / 2026-06-20 | SUPPORTED (drives MAJOR-2 P5↔P6 coupling) |
| 8 | `.spawn-rule-manifest.txt` is documented as trinity-only; all 7 slugs are cross-trinity | `cat pack-ops/.spawn-rule-manifest.txt` | header "imperative lives in trinity `## Pack memory` (CLAUDE.md / AGENTS.md / GEMINI.md @ pack root)"; 7 universal slugs | af73ffb / 2026-06-20 | SUPPORTED (drives MAJOR-2 category note) |
| 9 | Check 45 scans the WHOLE `## Pack memory` H2 incl. the Claude-only H3 sub-section | `sed -n '7359,7386p' scripts/validate-pack.py` | loop resets `in_pack_memory` only at `## ` H2; H3 sub-section text included; slug regex `[a-z0-9][a-z0-9-]*` | af73ffb / 2026-06-20 | SUPPORTED (E2a mechanics correct → MINOR-4) |
| 10 | Bijection + manifest + anti-restate baseline is green | `python3 scripts/validate-pack.py` (Check 18/45/46) | "Check 45 — 23 corpus … 23 rationale … bijection holds"; "Check 46 … 7 rule(s) … anti-restate 0 … 49 candidate bodies, >= 60 chars" | af73ffb / 2026-06-20 | SUPPORTED (24↔24 / 50-candidate targets) |
| 11 | The 4 Claude-only sub-section bullets are untagged; bullet anchors L350/391/402/418 | `awk 'NR>=348&&NR<=423 && /^- \*\*/' CLAUDE.md`; tag grep over range | bullets at 350/391/402/418; 0 `[roles:`/`[rationale:` in range | af73ffb / 2026-06-20 | SUPPORTED (P1 anchor + E2a premise both correct) |
| 12 | Graph has no spawn-registry node (G2 fallback justified) | `graphify query "sub-agent spawn name registry agentId discovery SendMessage" --graph …/graph.json --backend claude-cli --budget 1500` | 19 nodes; all INTAKE-GROUPINGS provenance + tracker-fixture; no registry node | af73ffb / 2026-06-20 | SUPPORTED |
| 13 | PACK-MEMORY-RATIONALE.md L193 Codex line is stale; the Antigravity line below it is ALREADY correct | `sed -n '185,200p' pack-ops/PACK-MEMORY-RATIONALE.md` | L193 "Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462)"; L196 "Antigravity: parent-control stop is native" | af73ffb / 2026-06-20 | SUPPORTED (design's P4 correctly targets only the Codex line) |

---

## D. ANSWERS TO THE 8 ADVERSARIAL TARGETS (verdict per target)

1. **Registry mechanism + location** — SOUND (B-1/B-2). Not a category error; gitignored
   is genuinely forced by `agents-never-commit`; durable across compaction; the path is
   already covered by `.gitignore` L76; no new check needed (correctly).
2. **Naming convention** — PARTIALLY SOUND. The `<role>-<bd>-<facet>[-<seq>]` shape +
   `-seq` uniquifier is a reasonable discipline-based answer to the UNVERIFIED-collision
   gap (external §6.1), and "discipline only" is acceptable because the registry's
   append-time `-seq` makes within-cycle collisions avoidable. BUT the cross-CLI half of
   the naming convention is mis-placed (MAJOR-1) — the discipline is correct; its HOME is
   wrong for non-Claude audiences.
3. **Rule reconciliation** — SOUND, conditional (B-4). The counterexample (registry read
   as encouraging reuse) does NOT survive PROVIDED the subordination clause stays verbatim.
   Flag the clause as load-bearing.
4. **Corpus elevation (E2a)** — SOUND (B-5, MINOR-4). The "currently untagged" claim is
   CONFIRMED; E2a does not break Check 45/46/18; tagging the first bullet in the
   sub-section is functionally fine. Elevation IS warranted (the BD's bijection-green
   acceptance gate only has teeth on a tagged corpus rule). One trivial format note.
5. **Propagation completeness** — FAILS (BLOCKER-1 + MAJOR-1 + MINOR-3). The design MISSED
   the client-shipped `supporting-docs/METHODOLOGY.md` stale-claim surface (the BD-240
   OPTIONAL-FEATURES analogue the prompt warned of), under-placed the cross-CLI naming
   discipline, and relies on an undocumented ×3 carve-out. The stale-rationale correction
   is INCOMPLETE.
6. **v11.1/BD-217 handoff** — MOSTLY handoff-only (good — no cross-CLI over-design pulled
   into v11.0), BUT over-states BD-217's current scope (MAJOR-3) and does not flag the
   premise-shift inconsistency (MINOR-1).
7. **Trinity parity** — the registry MECHANISM placement is CORRECT (Claude-only,
   single-surface, matches precedent). The cross-CLI NAMING discipline placement is WRONG
   (MAJOR-1) — a cross-CLI rule needs a trinity-parity home (or explicit justification).
8. **validate-pack green** — green is ACHIEVABLE but NOT guaranteed by the design as
   written: Check 45 stays green only if P1+P2 land together (design says so); Check 46
   stays green only if P5 is coupled to P6 (design does NOT say so — MAJOR-2) and the P6
   paraphrase is measured against the body (design asserts, not measures — MINOR-2).
   At-risk checks: **Check 46** (P5-without-P6 → hard FAIL; anti-restate if P6 restates).

---

## E. WHAT THE RECONCILIATION ARCHITECT MUST DO (consolidated, ordered)

1. **(BLOCKER-1)** Re-run a grep-derived measure-first census of EVERY surface carrying the
   stale "confirmed-absent/peer-messaging/hub-and-spoke" claim (not a hand-list).
   Reclassify `supporting-docs/METHODOLOGY.md` L96-99 as a REQUIRED correction-#1 surface
   (it ships to clients). Triage each grep hit KEEP (conditional guards) vs STRIP (stale
   factual claims). Apply `cross-cli-reference-normalization` (audience-correct, not
   byte-copy) to the METHODOLOGY edit.
2. **(MAJOR-1)** Split the bullet: cross-CLI NAMING discipline → a trinity-parity home
   (`### Agent invocation rules` ×3, audience-correct) OR explicit evidence-backed
   justification for Claude-only placement; registry+find MECHANISM stays Claude-only.
   Re-derive the propagation table; land any new trinity bullet ×3 same-commit.
3. **(MAJOR-2)** Couple P5↔P6 in one commit (or drop both); resolve the Claude-only-in-a-
   trinity-manifest category tension as a decision, not a planner deferral.
4. **(MAJOR-3 / MINOR-1)** Stop describing BD-217 as already owning the discovery
   mechanism; recommend a concrete BD-217 scope-note (or a distinct v11.1 anchor) and flag
   the capability-premise shift so BD-217 and BD-241 do not encode contradictory claims.
5. **(MINOR-2/3/4)** Direct the coder to: measure the P6 paraphrase vs the rule body (≥60
   anti-restate); add the PACK-CHAT.md step-1 Claude-only carve-out note; author
   `## spawn-name-registry` as a bare-slug heading and re-run Check 45 after P1+P2.
6. Keep the verified-correct decisions intact (registry location, name→agentId precedence,
   message-id drop, fresh-agent-default unchanged, E2a tagging) — do NOT re-open them.

---

## F. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | §C — 13 of my own state-claims, each with command + measured output + HEAD `af73ffb`/date + conclusion (SUPPORTED / and where the design is NOT-SUPPORTED, named so). | COMPLIANT |
| adversarial-architect-review (mandate) | Challenged every target; built the reuse-counterexample (B-4); did NOT trust the design's self-assessment — re-measured claims #1/#3/#5 and FALSIFIED the design's "exactly 2 surfaces" (BLOCKER-1); confirmed 6 decisions only after independent measurement (§B). | COMPLIANT |
| ci-guard-design-measure-then-bound | I MEASURED before contesting: re-ran the stale-claim grep tree-wide (BLOCKER-1), read Check 45/46 bodies (L7312-7427, L7559-7700), ran `validate-pack` for the live baseline (23↔23 / 7 records / 49 candidates). Findings backed by measurement, not assertion. | COMPLIANT |
| graph-first-context | Ran `graphify query "sub-agent spawn name registry agentId discovery SendMessage" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST → 19 nodes, all provenance/fixture noise, no registry node → G2 fallback to grep/Read for every surface, using the INJECTED absolute `--graph` path (not my own toplevel). | COMPLIANT |
| verify-availability-not-just-existence | Verified each contested claim against the actual file/CLI: METHODOLOGY ships (init-project.sh L685); BD-217 scope (read full entry); Check 46 references-required (code L7676-7683); did not assert any capability without the measurement. | COMPLIANT |
| separate-pack-ops-from-product | Kept the line explicit: BLOCKER-1 turns on METHODOLOGY being PRODUCT (ships); the registry is pack-ops runtime; MAJOR-1 distinguishes the cross-CLI naming DISCIPLINE (rule that applies to product spawns) from the Claude-only MECHANISM (pack-ops). | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Read-only git only (`git rev-parse HEAD`, `git rev-parse --abbrev-ref`, `git status --short`). ZERO state-changing verbs. Sole write = this review at `/tmp/pack-handoff-bd241-arch/ADVERSARIAL-REVIEW-BD-241.md`. No destructive op. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, COMPLIANT terminal; includes the graph-query proof row. No empty-evidence rows. | COMPLIANT |

---

*End ADVERSARIAL-REVIEW-BD-241. Read-only architect pass; no patch produced; sole write is
this doc. Verdict: NEEDS-REWORK (1 BLOCKER, 4 MAJOR, 4 MINOR). The mechanism design is
sound; the propagation completeness (esp. the client-shipped stale-claim surface) and the
cross-CLI naming placement must be reworked before the user design gate.*
