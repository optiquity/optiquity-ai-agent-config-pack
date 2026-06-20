# DESIGN-BD-241-RECONCILED — Discoverable spawned agents: cross-CLI unique NAMES + a durable Claude spawn REGISTRY + a name→agentId lookup precedence

**Agent:** pack-architect (READ-ONLY, FRESH/RECONCILIATION pass — neither original
author nor adversarial reviewer) · **Date:** 2026-06-20
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`,
HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`).
**Supersedes:** `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241.md` (original).
**Inputs read in full:** the original design; the adversarial review (findings +
§B 6 confirmed-sound decisions); RESEARCH-BD-241-EXTERNAL.md; RESEARCH-BD-241-INTERNAL.md;
`backlog/BD-241.md`; `backlog/BD-217.md`; `backlog/BD-238.md`; `backlog/BD-240.md`;
`supporting-docs/METHODOLOGY.md` (L84-101); `scripts/init-project.sh` install map
(L685/L1298); both reconcile-rule memories; `pack-ops/PACK-CHAT.md` propagation
procedure (L495-509); `pack-ops/PACK-MEMORY-RATIONALE.md` (L181-202);
`pack-ops/.spawn-rule-manifest.txt`; trinity `### Agent invocation rules`
(CLAUDE L242 / AGENTS L244 / GEMINI L211) + `### Sub-agent behavior (Claude-only)`
(CLAUDE L348-422); `scripts/validate-pack.py` Checks 18/45/46 bodies.
**Scope basis (user 2026-06-20, REVISED):** v11.0 ships (a) the CLAUDE
registry/find/resume MECHANISM; (b) a CROSS-CLI unique-NAMING discipline. The
Codex/Antigravity registry+find+resume MECHANISM defers to v11.1 (HANDOFF SPEC only).
Precedence is name→agentId (NO message-id tier). Correct the stale
"confirmed-absent #12462 / hub-and-spoke" rationale wherever it lives.

> **Method note (graph-first):** I queried the graph FIRST (injected absolute
> `--graph` path, NOT my own toplevel) for spawn-registry / agent-discovery /
> invocation-rule surfaces; it returned only tracker-fixture + provenance nodes
> (the concept is not a graph node — identical to both researchers' G2 finding),
> so per the G2 fallback I re-measured EVERY load-bearing surface with grep/Read
> against HEAD `af73ffb`. Proof in the Rules-Applied block. This is a
> documentation/rule-corpus BD; the graph indexes headings, not rule bodies, so
> grep/Read is the correct primary tool here.

---

## 0. Reconciliation verdict + what changed from the original

**Verdict:** the original design's MECHANISM core (registry location, gitignored-
forced, name→agentId precedence, message-id drop, fresh-agent-default unchanged,
E2a-style corpus elevation, graph-first method) re-measures CORRECT and is KEPT.
The original FAILED on **propagation completeness** and **cross-CLI placement**. This
reconciliation applies all 9 adversarial findings, adds one NEW gap I found
independently (§G), and pushes back on ONE finding with evidence (MAJOR-2, refined —
the P5↔P6 hard-fail claim is mechanically OVERSTATED; the coupling is a SEMANTIC
requirement, not a Check-46 hard-fail). Net changes from the original:

| Change | From (original) | To (reconciled) | Driver |
|---|---|---|---|
| Stale-claim surface set | "exactly 2 in-tree surfaces" (CLAUDE.md + RATIONALE.md) | **3 REQUIRED** (+`supporting-docs/METHODOLOGY.md`, a SHIPPED file); grep-derived census in §1 | BLOCKER-1 |
| Cross-CLI naming home | ONE combined bullet in the Claude-only sub-section | **SPLIT** — naming discipline → `### Agent invocation rules` ×3 (trinity-parity); MECHANISM → Claude-only sub-section | MAJOR-1 |
| P5/P6 coupling | P5 "YES-if", P6 "RECOMMENDED", independent | **DECISION: drop P5 (no manifest record)**; if kept, P5+P6 same-commit. Evidence-backed pushback on the "hard-fail" framing | MAJOR-2 |
| BD-217 framing | "BD-217 already owns cross-CLI coordination" | **scope-note recommendation** — BD-217 is a WORKTREE BD; it does NOT yet own discovery | MAJOR-3 |
| Premise-shift note | absent | added — both BDs must encode "analogs exist but flag-gated", not "absent" | MINOR-1 |
| Anti-restate P6 | asserted safe | **MEASURE directive** to coder (120-char window vs P6 string) | MINOR-2 |
| PACK-CHAT step-1 carve-out | implicit | **recommend a one-line ×3-trinity Claude-only carve-out note** | MINOR-3 |
| Rationale heading format | implicit | **explicit bare-slug `## <slug>` directive** + re-run Check 45 | MINOR-4 |
| Corpus rule structure | 1 combined Claude-only bullet | **2 bullets**: naming (trinity ×3, tagged) + mechanism (Claude-only, tagged) — see §G | NEW gap G-1 |

### The 6 verified-correct decisions — KEPT INTACT (not re-opened)
1. Registry location `graphify-out/.pack-spawn-registry.jsonl` (gitignored, reuses
   the `graphify-out/.pack-refresh-status` precedent).
2. Gitignored is FORCED by `agents-never-commit` (a mid-task write cannot be
   committed; tree churn otherwise).
3. Precedence name→agentId; the message-id tier is DROPPED (external §1.4 — no such
   primitive), not invented.
4. `fresh-agent-default` UNCHANGED; the registry is consulted ONLY after its gate —
   the subordination clause is **load-bearing** and stays VERBATIM in the rule text.
5. Corpus elevation with a `[rationale:]` slug (engages Check 45 — the BD's
   acceptance gate). (E2a tagging; here applied to BOTH new bullets.)
6. Graph-first method with G2 fallback.

---

## 1. BLOCKER-1 — grep-derived measure-first census of the stale-claim surfaces

Per `ci-guard-design-measure-then-bound`, the correction's surface set is
GREP-DERIVED, not hand-listed. The original asserted "exactly 2 in-tree surfaces";
re-measurement falsifies that.

**Census command (tree-wide, HEAD af73ffb; excl. `.git/`, `test-fixtures/`,
`maintenance-docs/`):**
```
grep -rln "no peer-messaging\|have no equivalent\|peer-messaging equivalent\|confirmed absent\|hub-and-spoke\|12462" --include="*.md" .
```
**Result + KEEP/STRIP triage (every hit categorized — measure-then-bound):**

| # | Surface (line) | Verbatim gist | Class | Disposition |
|---|---|---|---|---|
| 1 | `CLAUDE.md` L415-416 | "(Codex / Antigravity have no peer-messaging equivalent — confirmed absent per Codex issue #12462 and Antigravity's hub-and-spoke subagent model)" | **STRIP — stale factual** | REQUIRED edit P3 |
| 2 | `pack-ops/PACK-MEMORY-RATIONALE.md` L193 | "Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462)." | **STRIP — stale factual** | REQUIRED edit P4 |
| 3 | `supporting-docs/METHODOLOGY.md` L96-99 | "Codex CLI's `/agent` … but **no peer-messaging analog**; Antigravity CLI's subagent mechanism is **hub-and-spoke** … no … **peer-messaging** across multiple parent turns" | **STRIP — stale factual (SHIPPED)** | **REQUIRED edit P3b — NEW (the BLOCKER)** |
| 4 | `project-template/docs/pack/PM-CHAT.md` L539 | "if your CLI offers no peer-messaging, re-spawn a fresh `coder`" | **KEEP — conditional guard** | NO EDIT |
| 5 | `project-template/docs/pack/PM-CHAT.md` L907 | "Codex CLI and Antigravity CLI have no equivalent per-project MEMORY mechanism" | **KEEP — different capability (per-project memory, not peer-messaging)** | NO EDIT |
| 6 | `project-template/docs/pack/OPTIONAL-FEATURES.md` L283 | "Codex CLI and Antigravity CLI have no equivalent at this time; their WORKTREE story is tracked separately" | **KEEP — different capability (worktree, not peer-messaging)** | NO EDIT |
| 7 | `pack-ops/OPTIONAL-FEATURES.md` L284 | "Codex and Antigravity have no equivalent at this time; their WORKTREE story is tracked under BD-217" | **KEEP — different capability (worktree)** | NO EDIT |
| 8 | `backlog/BD-241.md` L8, L12 | entry provenance: "Codex/Antigravity have no peer-messaging … confirmed absent" | **KEEP — entry provenance (pack-chat-only governance)** | NO EDIT as a rule surface; but do NOT cite as still-true (see §4 MINOR-1) |

**STRIP = 3 surfaces (P3, P3b, P4). KEEP = 5.** The original's "exactly 2" miss was
surface #3 (`supporting-docs/METHODOLOGY.md`) — a CLIENT-SHIPPED file. Verified it
ships:
```
$ grep -n METHODOLOGY scripts/init-project.sh
685:  cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"
1298: "supporting-docs/METHODOLOGY.md:docs/pack/METHODOLOGY.md:generic"
```
Leaving #3 uncorrected would ship the exact falsehood the BD exists to fix to every
new client — self-defeating where it matters most. RECLASSIFIED from the original's
"NO EDIT / optional pointer" to a **REQUIRED correction surface (P3b)**.

**Disambiguation that the original AND the adversarial reviewer both under-stated:**
hits #5/#6/#7 match the grep but are about DIFFERENT capabilities (per-project memory;
worktree isolation). They are NOT stale peer-messaging claims and the BD-217 worktree
deferral in #6/#7 is independently correct. The census matters precisely because a
naive "fix every grep hit" would wrongly edit worktree/memory guards. KEEP is the
measured-correct disposition for all five.

### 1.1 The corrected text for the 3 STRIP surfaces (audience-correct, per cross-cli-reference-normalization)

Per `cross-cli-reference-normalization`, each surface gets AUDIENCE-CORRECT wording,
NOT a byte-copy of one canonical clause. Three audiences: pack-ops trinity rule
(CLAUDE.md), pack-ops rationale doc, and a SHIPPED client methodology doc.

**P3 — `CLAUDE.md` L414-417** (inside the Claude-only "Agent-team stage lifecycle"
bullet's Trinity exemption). REPLACE:
> "(Codex / Antigravity have no peer-messaging equivalent — confirmed absent per Codex
> issue #12462 and Antigravity's hub-and-spoke subagent model)."

with:
> "(Codex MAv2 `send_message` (flag-gated `multi_agent_v2`; issue #12462
> CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing + idle
> auto-rewake) now ship peer-messaging ANALOGS — but they are flag-gated /
> not-yet-GA-documented (Codex) and partly-unverified (Antigravity), so this
> MECHANISM stays Claude-only here; the cross-CLI mapping is BD-217.)"

**P4 — `pack-ops/PACK-MEMORY-RATIONALE.md` L193** (STOP-MEANS-STOP rationale, the
Codex bullet ONLY — the Antigravity line at L196 is already accurate, verified, leave
it). REPLACE:
> "Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462)."

with:
> "Codex CLI: a MAv2 `send_message` analog exists (issue #12462 CLOSED-COMPLETED
> 2026-05-02; flag-gated `multi_agent_v2`, not-yet-GA-documented), so the parent stop
> mechanism MAY use it where enabled; otherwise `/agent` or natural-language.
> Cross-CLI coordination = BD-217."

**P3b — `supporting-docs/METHODOLOGY.md` L94-101** (SHIPPED; the client-audience
methodology blockquote). This is a CLIENT doc — its audience is a project developer
choosing whether the Agent-Teams convention applies to their CLI, NOT a pack
maintainer. Audience-correct wording (no pack-internal `#12462` / `multi_agent_v2`
jargon — a client need not track Codex internals). REPLACE the trailing sentences (L94
"This convention is Claude-Code-specific:" through L100 "across multiple parent turns).")
with:
> "This convention is Claude-Code-specific. Codex CLI and Antigravity CLI now ship
> their own inter-agent-messaging analogs (Codex's multi-agent messaging; Antigravity's
> inter-agent ID-addressing with idle auto-rewake), but these are newer, opt-in /
> partly-preview capabilities — so this Agent-Teams stage-lifecycle convention is
> documented for Claude Code only; on Codex / Antigravity, follow your CLI's own
> subagent guidance."

Keep the existing final sentence (L100-101 "Codex / Antigravity project teams: this
convention does not apply to your CLI's runtime behavior.") — it is a correct
audience-routing line, not a stale capability claim. (Coder: confirm the exact
sentence boundaries by re-reading L84-101 before editing — line numbers drift.)

**Cross-surface boundary callout (SCOPE NOTE, REQUIRED for Pack Chat):** P3b reaches a
SHIPPED PRODUCT file (`supporting-docs/METHODOLOGY.md` installs to client
`docs/pack/METHODOLOGY.md`). P1/P2/P3/P4 + the manifest are pack-ops. **Therefore the
implementation commit is NOT `pack-only`** — it spans pack-ops + a `supporting-docs/`
product file. Per the CLAUDE.md commit-subject scope-keyword convention + CI Check 36,
the commit subject MUST NOT carry the `pack-only` keyword (Check 36 denies
`supporting-docs/` under `pack-only`). Two valid options for Pack Chat:
- (a) **ONE neutral-framed commit** ("BD-241 cross-surface: spawn-discovery rule +
  stale-rationale correction") — no scope keyword, Check 36 skipped; OR
- (b) **SPLIT** into a `pack-only` commit (P1/P2/P3/P4 + manifest) and a separate
  commit for P3b (the `supporting-docs/` edit). Given P3b changes a fixture INPUT,
  splitting cleanly isolates the push-time manifest concern (§9).

This is a separation-of-concerns reality, not a defect: the registry MECHANISM is
pack-ops; the stale-claim correction happens to reach a product file because that
product file carries the same now-false fact. The line stays explicit — the registry
never ships; only the factual correction does.

---

## 2. MAJOR-1 — split the bullet: cross-CLI NAMING discipline → trinity-parity home

**The user-scoped reality (REVISED SCOPE):** v11.0 ships "the CLAUDE registry/find/
resume mechanism + a CROSS-CLI unique-NAMING discipline." The naming discipline is
explicitly a CROSS-CLI v11.0 deliverable.

**The original's miss:** it folded the cross-CLI naming discipline INTO a single
combined bullet placed in `CLAUDE.md`'s `### Sub-agent behavior (Claude-only)`
sub-section — a home AGENTS.md (Codex) and GEMINI.md (Antigravity) readers never
consult. Measured:
```
$ grep -n "### Agent invocation rules\|Sub-agent behavior" AGENTS.md GEMINI.md
AGENTS.md:244:### Agent invocation rules
GEMINI.md:211:### Agent invocation rules
(zero "Sub-agent behavior" in either)
$ grep -rniE "uniquely name|name every spawn" CLAUDE.md AGENTS.md GEMINI.md → 0 hits (greenfield)
```
So a cross-CLI discipline placed only in the Claude-only sub-section is, in practice,
Claude-only on the pack side — a direct miss of an explicit user deliverable AND a
trinity-rule judgment error (a genuinely cross-CLI rule treated as single-surface).

### 2.1 Independent finding that STRENGTHENS the fix (the `### Agent invocation rules` home is precedented)
The `### Agent invocation rules` sub-section is the natural trinity-parity home — and
crucially, it ALREADY houses TAGGED, trinity-parity corpus rules. Measured:
```
$ # tagged rules inside CLAUDE.md `### Agent invocation rules`:
  preflight-stop-means-stop, enumerate-rules-inline, rules-applied-verification-block,
  empirical-evidence-blocks, ci-guard-measure-then-bound
$ for slug in preflight-stop-means-stop enumerate-rules-inline rules-applied-verification-block; do
    grep -c "rationale: $slug" CLAUDE.md AGENTS.md GEMINI.md ; done
  → 1 / 1 / 1 for EACH (present in all three trinity files = parity confirmed)
$ grep -A3 "slug:.*preflight-stop-means-stop" pack-ops/.spawn-rule-manifest.txt
  → corpus: ### Agent invocation rules — "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern"
```
**Conclusion:** a TAGGED rule in `### Agent invocation rules` ×3 is the ESTABLISHED
pattern (5 such rules already), it is genuinely trinity-parity, and it even has a
manifest precedent (`preflight-stop-means-stop` carries `corpus: ### Agent invocation
rules`). This is a CLEANER placement than the original's E2a-in-the-Claude-only-section
fork (which would have made the first tagged bullet in that section). The naming rule
fits an existing, populated, tagged, parity sub-section with zero novelty.

### 2.2 The split (RECOMMENDED)
- **Bullet A — the cross-CLI unique-NAMING discipline** → `### Agent invocation rules`
  ×3 trinity (CLAUDE.md / AGENTS.md / GEMINI.md), audience-correct, tagged
  `[rationale: spawn-unique-naming]`. (Rule text in §3.)
- **Bullet B — the Claude-only registry+find MECHANISM** → `### Sub-agent behavior
  (Claude-only)` (CLAUDE.md only), tagged `[rationale: spawn-registry-find]`. (Rule
  text in §3.)

This split exactly matches the user's scope partition (naming = cross-CLI; mechanism =
Claude-only) AND the trinity rule (parity for the cross-CLI portion; legitimate
single-surface for the Claude-only mechanism). Two slugs, two rationale sections — both
engage Check 45 bijection (the BD's acceptance gate has teeth on BOTH).

---

## 3. The two new corpus rules — exact drop-in text

### 3.1 Bullet A — cross-CLI unique-NAMING discipline (trinity ×3, `### Agent invocation rules`)
Insert as a new bullet in `### Agent invocation rules` (CLAUDE.md / AGENTS.md /
GEMINI.md), audience-correct per `cross-cli-reference-normalization`. The CLAUDE.md form:

> - **Uniquely + descriptively name every spawn.** Every spawned agent carries a
>   unique, descriptive `name` of the shape `<role>-<bd>-<facet>[-<seq>]` (lowercase
>   kebab, `^[a-z0-9][a-z0-9-]{2,47}$`): `<role>` the agent role token
>   (`coder`/`fixcoder`/`reviewer`/`architect`/`planner`/`docsresearcher` — the
>   `subagent_type` minus the `pack-` prefix); `<bd>` the work anchor (`bdNNN` or
>   `batchNN`); `<facet>` a short scope tag (`cdocs`/`worktree`/`external`); append
>   `-2`/`-3`… to keep a repeated `<role>-<bd>-<facet>` triple unique within a live
>   cycle (uniqueness is a DISCIPLINE — no platform guarantees it). In Claude Code the
>   `name` is the Agent-tool `name` parameter (addressable via `SendMessage({to:
>   name})`); on Codex / Antigravity use the platform's agent-name field. A
>   unique name is the key the discovery mechanism records and re-finds by. `[roles:
>   universal] [rationale: spawn-unique-naming]`

The AGENTS.md form substitutes "In Codex the `name` is the agent `name` field (the
`nickname` is display-only)"; the GEMINI.md form substitutes "On Antigravity address by
the known agent ID / named-role type" — audience-correct, NOT a byte-copy (the regex,
the triple shape, and the discipline-not-guarantee point are identical across all
three; only the per-CLI name-field reference differs).

### 3.2 Bullet B — Claude-only registry+find MECHANISM (`### Sub-agent behavior (Claude-only)`)
Insert as a new bullet in `### Sub-agent behavior (Claude-only)` (CLAUDE.md ONLY),
after the "Agent-team stage lifecycle" bullet, before "Trinity exemption":

> - **Record every spawn in the durable registry; re-find by name→agentId
>   (Claude-only mechanism).** The orchestrator records each Agent-tool spawn — its
>   unique `name` (see `### Agent invocation rules` `[rationale: spawn-unique-naming]`),
>   `agentId` (from the spawn tool_result), `purpose`, `status` — into the gitignored
>   per-clone ledger `graphify-out/.pack-spawn-registry.jsonl` (NEVER committed —
>   `agents-never-commit`; modeled on `graphify-out/.pack-refresh-status`) and CONSULTS
>   it to re-find a still-alive spawn with NO transcript archaeology (the registry is
>   re-read from disk, so it survives a parent context compaction). Lookup precedence:
>   **by NAME → by agentId** (both work as `SendMessage.to`, measured; there is NO
>   message-id addressing primitive — do not invent one; terminal fallback is a fresh
>   re-spawn). Consult the registry ONLY after the `fresh-agent-default` gate authorizes
>   a re-engage — this fixes HOW-to-find, not WHEN-to-reengage. The find/registry
>   MECHANISM is Claude-only here; Codex MAv2 (`list_agents`/`resume_agent`) and
>   Antigravity `agy` analogs exist but need their own verification + mapping (BD-217).
>   `[roles: universal] [rationale: spawn-registry-find]`

**Load-bearing clause (do NOT trim — flagged per adversarial §B-4):** "Consult the
registry ONLY after the `fresh-agent-default` gate authorizes a re-engage." Without it,
the registry reads as a new authority to reuse agents, defeating `fresh-agent-default`.
The coder MUST keep this clause verbatim.

**Role-tag note:** both bullets use `[roles: universal]` (matching the existing tagged
rules in their respective sub-sections — `### Agent invocation rules` rules carry
`universal`; the Claude-only sub-section's scoping comes from its H3 header, and Bullet
B inherits that). The `[rationale:]` slug is what engages Check 45, not the role tag.

---

## 4. MAJOR-3 + MINOR-1 — BD-217 anchor + the premise-shift note

**The original's miss:** "BD-217 (which already owns cross-CLI agent coordination)".
Re-measurement of `backlog/BD-217.md` (read in full): its title is "Codex + Gemini
**worktree-isolation** support"; its Type, Scope, Hard-constraints, Out-of-scope,
References, Acceptance criteria are ALL worktree-isolation + the agents-never-commit
merge-back model. It says NOTHING about agent naming, a spawn registry, peer-messaging,
or name→agentId discovery. Its Blocker is BD-197 (the worktree reference model). So
BD-217 does NOT own the discovery mechanism — it owns cross-CLI WORKTREE coordination,
narrowly. (Note: `backlog/BD-241.md` L19 itself calls BD-217 "the
cross-CLI-applicability anchor" — so the entry already intends BD-217 as the anchor,
but BD-217's BODY does not yet reflect that.)

### 4.1 RECOMMENDATION — Option (a): a one-line BD-217 scope-note (over a new v11.1 anchor)
Per `deferred-work-tracked-anchor`, the deferred cross-CLI discovery mechanism MUST land
on a real tracked anchor. Two options:

| # | Option | Pros | Cons | Verdict |
|---|---|---|---|---|
| a | Add a one-line scope-NOTE to `backlog/BD-217.md` taking on the cross-CLI discovery analog | reuses an existing cross-CLI v11.1 BD that already mandates per-platform verify-availability + the same researcher→architect→planner pipeline; both are cross-CLI agent-coordination concerns; BD-241 already names BD-217 the anchor | slightly broadens BD-217 beyond "pure worktree" | **RECOMMENDED** |
| b | Open a NEW distinct v11.1 BD for the cross-CLI discovery mechanism | keeps BD-217 worktree-pure | a second cross-CLI v11.1 BD with near-identical pipeline + audience; BD-numbering overhead; the user already designated BD-217 the anchor (BD-241 L19) | not recommended |

**Recommended scope-note (pack-chat-only governance edit; user authorizes at the design
gate — Pack Chat may apply directly per `pack-chat-minor-edits-only` since it is a NEW
forward-pointing note on a NOT-yet-landed BD):** add to `backlog/BD-217.md` (e.g. a
dated Note line):
> "Note (2026-06-20, BD-241 handoff): BD-217 ALSO owns the cross-CLI analog of BD-241's
> spawn-discovery mechanism (unique-naming is shipped cross-CLI in v11.0; the
> registry + find + resume MECHANISM defers here). Carry the corrected cross-CLI
> capability premise — Codex MAv2 + Antigravity `agy` peer-messaging analogs EXIST but
> are flag-gated / partly-unverified (NOT 'confirmed absent') — into the per-platform
> research. See the BD-241 §6 handoff spec."

### 4.2 MINOR-1 — premise-shift note (so the two BDs don't encode contradictory claims)
Once correction #1 lands, the trinity-exemption rationale shifts from "capability
absent" to "capability present but flag-gated/unverified." BD-217's worktree premise
(L9) rests on the worktree feature set, NOT peer-messaging, so it is not directly
contradicted — but when BD-217 picks up the cross-CLI discovery work, its capability
premise MUST be the corrected one. The §4.1 scope-note carries this explicitly ("Codex
MAv2 + Antigravity `agy` … EXIST but are flag-gated … NOT 'confirmed absent'"), closing
MINOR-1. The reconciled design does NOT design the cross-CLI mechanism — that stays a
v11.1 handoff (§6).

---

## 5. MAJOR-2 — P5/P6 manifest coupling: EVIDENCE-BACKED PUSHBACK + a DECISION

The adversarial review claimed (MAJOR-2): "if the coder adds the P5 manifest record but
treats P6 as optional/omits it, Check 46(a2) FAILS — a record with no resolving
reference surface is a hard error. P5 and P6 are NOT independent; P5 FORCES P6 (or P7)."

### 5.1 PUSHBACK (with measurement) — the "hard-fail" framing is mechanically OVERSTATED
I re-measured Check 46(a2) at `scripts/validate-pack.py` L7642-7704. The
reference-resolution logic is:
```python
named = [b for b in known_ref_files if b in references]   # basename mentioned in the record's references: text
...
if "## Pack memory" not in ref_path.read_text():           # the named surface must CONTAIN the literal "## Pack memory"
    fail(...)
```
The FAIL conditions are exactly: (1) the record's `references:` field names NO known
surface basename (`PACK-AGENTS.md`/`PACK-CHAT.md`); OR (2) the named surface does not
exist; OR (3) the named surface does not contain the literal string `## Pack memory`.

**Measured fact that refutes the hard-fail framing:**
```
$ grep -c "## Pack memory" pack-ops/PACK-CHAT.md   → 13
$ grep -c "## Pack memory" pack-ops/PACK-AGENTS.md → 7
```
PACK-CHAT.md already contains `## Pack memory` 13 times (and PACK-AGENTS.md 7 times).
So a P5 record whose `references:` field names `PACK-CHAT.md` PASSES Check 46(a2)
**regardless of whether a NEW slug-specific P6 paraphrase line is added** — the check
only verifies the surface contains the canonical pointer string, NOT that it carries a
paraphrase of THIS particular rule. **Conclusion: P5 does NOT mechanically FORCE P6.**
The adversarial "hard FAIL if P5-without-P6" claim is NOT-SUPPORTED by the code.

### 5.2 BUT the adversarial reviewer's BROADER point survives (semantic coherence)
A manifest record's PURPOSE (per the manifest's own header) is "to record, for each
collapsed rule, its canonical home + the reference surfaces where the one-line pointer
now lives." A record naming PACK-CHAT.md as the home of a one-line pointer that does NOT
exist there is SEMANTICALLY incoherent (the record lies about where the pointer lives),
even though Check 46 does not catch it. So IF a manifest record is added, a real
one-line reference SHOULD exist — coupling is a SEMANTIC requirement, not a CI hard-fail.

### 5.3 The DECISION (resolved here, not deferred to planner) — DROP P5/P6 entirely
The deeper question MAJOR-2 raised is whether `spawn-name-registry` belongs in
`.spawn-rule-manifest.txt` AT ALL. Measured category facts:
- The manifest's header (verified): "each spawn-relevant rule is authored ONCE — its
  imperative lives in trinity `## Pack memory` (CLAUDE.md / AGENTS.md / GEMINI.md at pack
  root). The 6 former restatements … have been collapsed (BD-196 C5) to one-line
  REFERENCES. This manifest records, for each COLLAPSED rule, its canonical home + the
  reference surfaces where the one-line pointer now lives."
- All 7 current slugs are rules whose imperative was RESTATED in PACK-AGENTS.md/
  PACK-CHAT.md and then COLLAPSED to a one-line reference. The manifest exists to track
  THAT collapse (so anti-restate has a record of where the legitimate one-liner lives).

**The reconciled rules are GREENFIELD — they have NO pre-existing restatement in
PACK-AGENTS.md/PACK-CHAT.md to collapse** (verified: `grep -rniE "uniquely name|name
every spawn|spawn.*registry" pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md` → 0 hits).
The manifest is for COLLAPSED cross-trinity restatements; a brand-new rule with no
restatement does not need a manifest record. Adding one would make `spawn-registry-find`
the FIRST single-surface (Claude-only) entry in a manifest whose stated contract is
trinity — a category mismatch with no functional benefit (Check 45 bijection already
gives both new rules teeth via P1+P2; the manifest adds nothing the bijection check
doesn't).

**DECISION: do NOT add a `.spawn-rule-manifest.txt` record (drop P5), and do NOT add a
PACK-CHAT.md paraphrase reference for the sole purpose of resolving a manifest record
(drop P6).** This is the simplest correct outcome (design-elegance: fewer surfaces,
fewer special cases) AND it sidesteps the category tension entirely. The rules are fully
gated by Check 45 (bijection via the two rationale sections) + Check 18 (H2 parity,
untouched).

**Optional, NOT required:** if the planner/user nonetheless wants a discoverability
pointer in PACK-CHAT.md's spawn-mechanics section (so a maintainer reading PACK-CHAT.md
finds the registry), a single one-line PARAPHRASE reference MAY be added — but then it
is a documentation convenience, NOT a manifest-resolution requirement, and §6 (MINOR-2)
governs its anti-restate safety. The recommendation is to SKIP it for v11.0 (the trinity
rule is the SSOT; PACK-CHAT.md already routes "For spawn-relevant rules, read trinity
`## Pack memory`" at its L57).

---

## 6. MINOR-2/3/4 — coder directives (measured, not asserted)

### 6.1 MINOR-2 — anti-restate (Check 46b): MEASURE, do not assert
If (and only if) the optional PACK-CHAT.md one-line reference is added (§5.3 says skip
it), the coder MUST MEASURE, per `ci-guard-design-measure-then-bound`. Measured
mechanics (`scripts/validate-pack.py` L7705-7732 + the extractor L-`_check_46_extract…`):
the scan extracts each `## Pack memory` bullet BODY (text after the bold name),
collapses whitespace, takes the **leading 120-char window**, keeps it if ≥60 chars, then
FAILS if that exact window substring appears verbatim in any of the 6 surfaces
(`PACK-AGENTS.md`, `PACK-CHAT.md`, 4 skill SKILL.md files). **Directive:** the coder
computes Bullet A's and Bullet B's leading-120-char body windows, and confirms any P6
reference text shares NO contiguous run ≥ that window with them (the safe form is a
short pointer like "name + record every spawn; re-find by name→agentId — see trinity
`## Pack memory` `[rationale: spawn-registry-find]`", which paraphrases and cannot
contain the rule body's 120-char prefix). Record the measurement in the IMPL-REPORT.
(With §5.3's recommended SKIP, this is moot — but documented so the gate is honored if
the optional reference is added.)

### 6.2 MINOR-3 — PACK-CHAT.md step-1 Claude-only carve-out note (RECOMMENDED)
The propagation procedure step-1 (PACK-CHAT.md L501) reads "Corpus imperative line ×3
trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory`)" with NO documented
"unless Claude-only" clause. BD-241 lands the FIRST formally-tagged Claude-only corpus
rule (Bullet B). Bullet A (×3 trinity) follows step-1 as written; Bullet B is
single-surface (CLAUDE.md only). The behavior is CORRECT (Check 18 is per-location
per-H2 with no cross-location gate; Check 45 scans CLAUDE.md as corpus representative —
both re-confirmed §8), but the PROCEDURE DOC does not say a Claude-only rule is exempt
from ×3. **RECOMMENDATION:** add a one-line note to the PACK-CHAT.md step-1 row:
> "(a Claude-only sub-section rule is single-surface — no ×3 mirror; see the existing
> `### Sub-agent behavior (Claude-only)` precedent.)"

This is a pack-chat-only edit (PACK-CHAT.md is pack-chat-only); surface at the design
gate. It prevents the next author from being tripped by the step-1↔Claude-only
contradiction. (Bullet A is NOT affected — it IS ×3 trinity.)

### 6.3 MINOR-4 — bare-slug rationale headings + re-run Check 45
Verified: Check 45's heading regex is `^##\s+([a-z0-9][a-z0-9-]*)\s*$` (L7384) — a BARE
slug heading, no trailing prose on the heading line. Verified existing rationale
headings follow this (`## agents-never-commit`, `## deferral-is-scope-creep`, …).
**Directive:** the coder authors `## spawn-unique-naming` and `## spawn-registry-find`
as bare-slug headings (lowercase kebab, nothing after the slug), then re-runs
`python3 scripts/validate-pack.py` AFTER P1+P2 land to confirm Check 45 reports the new
bijection count (25↔25 — current baseline is 23↔23, +2 slugs/+2 sections). Verified
baseline: `Check 45 — 23 corpus … 23 rationale … bijection holds`.

---

## 7. NEW GAP found independently (§G) — both prior passes missed it

### G-1 — the original's single combined bullet would have ORPHANED the cross-CLI naming half from Check 45 bijection AND mis-keyed the manifest
Beyond MAJOR-1 (placement/visibility), the original's one-combined-bullet structure had
a second, subtler defect neither prior pass named explicitly: a SINGLE bullet carries a
SINGLE `[rationale:]` slug. The original tagged it `[rationale: spawn-name-registry]`
inside the Claude-only sub-section. That single slug's rationale section would have
documented BOTH the (cross-CLI) naming discipline AND the (Claude-only) registry
mechanism under one heading — so the cross-CLI naming portion would have had:
- NO independent bijection identity (it rides on the mechanism's slug),
- a rationale section that conflates a trinity-parity rule with a Claude-only rule
  (the bijection check would pass, but the rationale doc would mis-describe a cross-CLI
  rule as living in the Claude-only sub-section), and
- if a manifest record were added (original P5), it would key the cross-CLI naming rule
  to a Claude-only canonical home — a provenance error.

The §2.2 split into TWO slugs (`spawn-unique-naming` trinity-parity / `spawn-registry-find`
Claude-only) fixes G-1 as a side effect: each rule has its own bijection identity and
its own correctly-scoped rationale section. This is why the split is structurally
necessary, not merely cosmetic. (Adversarial MAJOR-1 got the placement; G-1 is the
bijection/rationale-identity consequence of the same root cause.)

### G-2 (verified NON-issue — challenged and cleared) — does Bullet A in `### Agent invocation rules` collide with anything at Check 18?
I challenged whether adding a bullet to `### Agent invocation rules` could trip Check 18
H2 parity. Measured: Check 18 is per-H2-per-location with no cross-location gate
(L1605-1606 region); a new BULLET inside an existing H3 (`### Agent invocation rules` is
an H3 under the `## Pack memory` H2) changes no H2 structure. The sub-section already
exists in all three trinity files (CLAUDE L242 / AGENTS L244 / GEMINI L211) with
parallel tagged content. Adding Bullet A ×3 keeps parity. **Cleared — not a gap.**

### G-3 (verified NON-issue) — does the gitignored registry file need a `.gitignore` edit?
Verified `.gitignore` L76 ignores the whole `graphify-out/` dir; the leaf file
`graphify-out/.pack-spawn-registry.jsonl` is covered with ZERO `.gitignore` edit.
Cleared (matches the original + adversarial §B-1).

---

## 8. validate-pack stays green — verification plan (re-measured)

Baseline measured at HEAD af73ffb: `PASSED — all checks clean`; Check 45 = 23↔23
bijection; Check 46 = 7 manifest rules, anti-restate 0 across 6 surfaces (49 candidate
bodies ≥60 chars); Check 18 green (pack-root + project-template).

| Check | Risk | How the reconciled design keeps it green |
|---|---|---|
| Check 18 (trinity H2 parity, per-location) | new H2/H3 mismatch | NO new heading. Bullet A is a BULLET in the existing `### Agent invocation rules` H3 (×3, parity preserved); Bullet B is a BULLET in the existing `### Sub-agent behavior (Claude-only)` H3 (CLAUDE-only, no H2 change). Verified §G-2 + §6.3. |
| Check 45 (rule↔rationale bijection) | orphan slug | P1a (slug `spawn-unique-naming` ×3 corpus) + P2a (`## spawn-unique-naming` rationale) AND P1b (slug `spawn-registry-find` CLAUDE.md) + P2b (`## spawn-registry-find` rationale) land in the SAME commit → 25↔25 set-equality. Check 45 scans the WHOLE `## Pack memory` H2 incl. the Claude-only H3 (verified L7359-7374), so Bullet B's slug IS picked up and DOES need its rationale section. Bare-slug headings (§6.3). |
| Check 46 (manifest + anti-restate) | new slug without manifest; verbatim restatement | NO manifest record added (§5.3 DROP P5) → reference-resolution leg untouched (still 7 records). Anti-restate: NO new reference surface restates a body (§5.3 DROP P6; if the optional pointer is added, §6.1 measure-bound applies). Candidate-body count rises 49→~51 (the 2 new bullet bodies become candidates) but they appear NOWHERE in the 6 scanned surfaces → 0 restate hits. |
| Check 62 (push-time manifest) | changed fixture input | P3b edits `supporting-docs/METHODOLOGY.md` — a fixture INPUT (it stages to `docs/pack/METHODOLOGY.md`, mirrored in 5 `test-fixtures/**/docs/pack/METHODOLOGY.md`). `scripts/manifest-sync.sh` reconciles at PUSH (NOT per-commit, per the manifest memory); the coder does NOT regen. Flag for the orchestrator's push step. |
| Check 36 (commit-scope keyword) | mis-claimed `pack-only` | the commit touches `supporting-docs/` (P3b) → MUST NOT carry `pack-only`. Use neutral framing OR split (§1.1 SCOPE NOTE). |
| destructive-git-verb parity | n/a | no git-verb rule touched. |

**measure-then-bound — NO new CHECK designed.** The registry is gitignored and spawn
names are runtime; there is NO committed-tree state for a naming/registry validator to
scan (an empty matching set — forbidden by the rule). Enforcement is by the corpus rule
(discipline) + the registry's append-time `-seq` uniqueness, reusing Checks 18/45/46.
CI runtime-compounding cost (×~155) is UNCHANGED.

**Pre-commit verification the coder runs:** after P1a/P1b/P2a/P2b (corpus×2 +
rationale×2), run `python3 scripts/validate-pack.py` and confirm Check 45 reports 25↔25,
Check 46 still 0 restate / 7 records, Check 18 green.

---

## 9. Final edit spec — EVERY surface (the reconciled propagation table)

A Claude-only corpus rule (Bullet B) does NOT mirror ×3; a cross-CLI rule (Bullet A)
DOES mirror ×3. Procedure: `pack-ops/PACK-CHAT.md` § "Rule-change propagation" (L495-509).

### 9.1 PACK-SIDE surfaces

| # | Surface | Edit | Gate | Required? |
|---|---|---|---|---|
| P1a | `CLAUDE.md` `### Agent invocation rules` + `AGENTS.md` L244 + `GEMINI.md` L211 (×3) | ADD Bullet A (§3.1), audience-correct per CLI, `[roles: universal] [rationale: spawn-unique-naming]` | Check 18 (parity ×3); Check 45 (needs P2a) | **YES** |
| P1b | `CLAUDE.md` `### Sub-agent behavior (Claude-only)` (after "Agent-team stage lifecycle", before "Trinity exemption") | ADD Bullet B (§3.2), CLAUDE.md ONLY, `[roles: universal] [rationale: spawn-registry-find]` | Check 45 (needs P2b) | **YES** |
| P2a | `pack-ops/PACK-MEMORY-RATIONALE.md` — new `## spawn-unique-naming` | bare-slug heading + rationale (Why: BD-206 docs-researcher re-find needed JSONL archaeology; the naming key makes a spawn re-findable; cross-CLI because all platforms spawn named agents. How: the `<role>-<bd>-<facet>[-<seq>]` shape + `-seq` uniquifier. Rejected: free-form / UUID-suffixed names) | Check 45 bijection | **YES** |
| P2b | `pack-ops/PACK-MEMORY-RATIONALE.md` — new `## spawn-registry-find` | bare-slug heading + rationale (Why: durable registry survives compaction; no archaeology. How: gitignored JSONL `{name,agentId,purpose,status}`; name→agentId precedence; consult ONLY after the fresh-agent gate. Rejected: committed manifest / Agent-Teams `members` (teams-only) / message-id tier (no primitive). Claude-only — Codex/Antigravity = BD-217) | Check 45 bijection | **YES** |
| P3 | `CLAUDE.md` L414-417 (stale clause in "Agent-team stage lifecycle") | REPLACE per §1.1 P3 (stale-rationale correction #1, Claude-only single-surface) | none (prose) | **YES** |
| P4 | `pack-ops/PACK-MEMORY-RATIONALE.md` L193 (stale Codex line in STOP-MEANS-STOP) | REPLACE per §1.1 P4 (Codex line only; leave the accurate Antigravity line L196) | none (prose) | **YES** |
| **P3b** | **`supporting-docs/METHODOLOGY.md` L94-101 (SHIPPED)** | **REPLACE per §1.1 P3b — audience-correct client wording (no #12462/flag jargon). RECLASSIFIED from the original's "optional" to REQUIRED (BLOCKER-1)** | none (prose); Check 62 at push (fixture input) | **YES (the BLOCKER fix)** |
| — | `pack-ops/.spawn-rule-manifest.txt` | **NO RECORD** (§5.3 decision — greenfield rule, nothing collapsed, category-mismatch) | — | NO |
| — | `pack-ops/PACK-CHAT.md` spawn-mechanics section | **NO required paraphrase** (§5.3); OPTIONAL one-line pointer only (skip recommended) | Check 46 anti-restate (if added → §6.1 measure) | OPTIONAL (skip) |
| P5(opt) | `pack-ops/PACK-CHAT.md` step-1 propagation row | ADD the Claude-only ×3 carve-out note (§6.2) | none (pack-chat-only) | **RECOMMENDED** (MINOR-3) |
| P6 | out-of-repo memory `reference_sendmessage_uuid_addressing.md` | REFINE: cite the two in-repo slugs; add "name also works for subagents; registry-backed; precedence name→agentId; no message-id" (trinity-wins) | Pack-Chat upkeep | YES (memory hygiene; not a tree file) |
| P7 | out-of-repo memory `MEMORY.md` index | UPDATE the SendMessage-UUID pointer line to mention the registry | Pack-Chat upkeep | YES |
| — | `feedback_fresh_agent_default_no_sendmessage.md` | **NO EDIT** (unchanged by design, §0 decision 4) | — | NO |
| — | `pack-ops/OPTIONAL-FEATURES.md` L284 | **NO EDIT** (worktree guard, not peer-messaging — census KEEP) | — | NO |

### 9.2 PROJECT-SIDE surfaces (mechanism Claude-only; naming cross-CLI)

| # | Surface | Edit | Required? |
|---|---|---|---|
| PR1 | `project-template/docs/pack/PM-CHAT.md` § "In-session agent spawning" (L454+) | ADD the platform-agnostic naming discipline in CLI-agnostic prose ("name every spawn uniquely + descriptively: `<role>-<bd>-<facet>`") — precedent: the existing CLI-agnostic "Spawn in the background" at L506-510 | **YES** (naming applies on all CLIs) |
| PR2 | `project-template/docs/pack/PM-CHAT.md` (a "(Claude-only)" blockquote near the merge-back re-engage at L533-541) | ADD a Claude-only blockquote: the registry+precedence mechanism (gitignored ledger; name→agentId; consult only after the re-engage decision), worded like the existing L897 "(Claude-only)" blockquote; note Codex/Antigravity = future pack version | **YES** (Claude-only mechanism, project side) |
| — | `project-template/docs/pack/METHODOLOGY.md` | **DOES NOT EXIST as a project-template source** (correction #2 — verified `find . -name METHODOLOGY.md` → only `supporting-docs/METHODOLOGY.md` + 5 fixtures). The SHIPPED client copy comes from `supporting-docs/METHODOLOGY.md` (P3b). No project-template edit. | NO |
| — | `project-template/docs/pack/OPTIONAL-FEATURES.md` L283 | **NO EDIT** (worktree guard — census KEEP) | NO |
| — | `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` | **NO EDIT** — verified (system-reminder full content) this section carries UNIVERSAL collaboration rules only (Trinity rule, no-destructive-git, PM-chat-does-not-architect, Project SSOT-first); no Claude-only spawn sub-section. The Claude-only mechanism belongs in PM-CHAT.md (the project-side spawn-runtime SSOT), not the project trinity. Adding one = scope creep + boundary regression. | NO |

**PR1/PR2 touch `project-template/docs/pack/PM-CHAT.md` (a fixture INPUT)** → push-time
`scripts/manifest-sync.sh` regen + Check 62 (NOT per-commit). Flag for the push step.

### 9.3 Cross-surface commit reality (SCOPE NOTE for Pack Chat — REQUIRED)
The edit set spans: pack-ops (P1a/P1b/P2a/P2b/P3/P4/P5), a SHIPPED product file (P3b
`supporting-docs/`), and project-template product (PR1/PR2). This is NOT a `pack-only`
commit. Per §1.1: either ONE neutral-framed commit (no scope keyword, Check 36 skipped)
OR split pack-ops / product. If split, a clean partition is:
- Commit 1 (`pack-only`): P1a/P1b/P2a/P2b/P3/P4 + P5(opt) — the rule + the pack-side
  stale-rationale corrections.
- Commit 2 (no keyword or `project-only`-adjacent — but P3b is `supporting-docs/`, NOT
  project-template, so neither exclusive keyword fits cleanly): P3b + PR1 + PR2 — the
  product-side naming-discipline + stale-claim correction.
Recommend the SPLIT (isolates the fixture-input/push-manifest concern to commit 2).

---

## 10. rule-10 parallelization / dependency map (REQUIRED — corrected)

### 10.1 Intra-BD-241 commit map
The propagation order (PACK-CHAT.md L508) is END-STATE-verified in atomic commits.
BD-241's own surfaces overlap on files (P1a/P3 both in CLAUDE.md; P2a/P2b/P4 all in
PACK-MEMORY-RATIONALE.md; P1a×3 in the trinity), so **BD-241's own coders SERIALIZE** —
no intra-BD parallel wave. Recommended: the rule + pack-side corrections in ONE coder
(commit 1); the product-side P3b/PR1/PR2 may be a SECOND coder/commit (commit 2 — files
disjoint from commit 1: `supporting-docs/METHODOLOGY.md` + `project-template/docs/pack/
PM-CHAT.md` do not overlap CLAUDE.md/AGENTS.md/GEMINI.md/RATIONALE.md). So commit 1 and
commit 2 COULD run as a 2-wide parallel worktree wave IF the split is taken — they touch
disjoint files. If ONE neutral commit is taken instead, it is a single serial commit.

### 10.2 CROSS-BD same-file collision (the load-bearing rule-10 finding) — VERIFIED
Measured: BD-238, BD-240, BD-241 ALL edit the trinity `## Pack memory` corpus AND
`pack-ops/PACK-MEMORY-RATIONALE.md`:
- **BD-238** (verified `backlog/BD-238.md` head): "Codify the PACK-SIDE large-BD
  development pipeline … into ONE official in-repo standard … Architect-first (it
  touches rules + operating docs + trinity)." → adds a corpus rule + rationale.
- **BD-240** (verified `backlog/BD-240.md` head): "Re-frame the `graph-first-context`
  rule … (PACK-OPS; trinity `## Pack memory`). … touches trinity + the full propagation
  surfaces." → EDITS the `graph-first-context` corpus rule ×3 trinity + its rationale.
- **BD-241** (this design): Bullet A ×3 trinity + Bullet B (CLAUDE.md) + P2a/P2b
  rationale + P3/P4 stale corrections.

| File | BD-238 | BD-240 | BD-241 | Schedule |
|---|---|---|---|---|
| `CLAUDE.md` `## Pack memory` | YES (pipeline rule) | YES (graph-first re-frame) | YES (P1a/P1b/P3) | **SERIALIZE** |
| `AGENTS.md` / `GEMINI.md` `## Pack memory` | YES (×3) | YES (×3) | YES (P1a ×3) | **SERIALIZE** |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | YES (rationale) | YES (rationale re-frame) | YES (P2a/P2b/P4) | **SERIALIZE** |
| `pack-ops/PACK-CHAT.md` | YES (lifecycle section) | likely (propagation) | P5(opt) | SERIALIZE if all touch it |
| `supporting-docs/METHODOLOGY.md` | maybe | maybe | YES (P3b) | confirm BD-238/240 footprint |
| project PM-CHAT.md | no | maybe | YES (PR1/PR2) | parallel-able vs a pack-only sibling |

**Consequence (rule 10):** BD-238 / BD-240 / BD-241 MUST SERIALIZE on
CLAUDE.md/AGENTS.md/GEMINI.md + PACK-MEMORY-RATIONALE.md — they CANNOT run as concurrent
worktree waves (concurrent edits to those shared files would conflict; the conflict
protocol STOP + re-spawn-fresh would fire). The orchestrator schedules them as SERIAL
commits (any order — BD-241 has no hard dependency on the other two, but they share
files). After each lands, the next coder bases on the new HEAD. (User-stated sequencing:
BD-240 RUNS NEXT before BD-206 resumes; BD-241 "after/with BD-240 at user discretion" —
so a natural serial order is BD-240 → BD-241, with BD-238 slotted by the user.)

---

## 11. Open questions for the user (design gate)

1. **Commit framing (§1.1 / §9.3):** ONE neutral-framed cross-surface commit (no scope
   keyword) vs SPLIT into a `pack-only` rule+pack-corrections commit + a product-side
   commit (P3b/PR1/PR2). RECOMMEND the split (isolates the fixture-input/push-manifest
   concern). [The BLOCKER fix P3b makes `pack-only` framing of the whole batch invalid
   either way.]
2. **BD-217 anchor (§4.1):** add a one-line scope-NOTE to `backlog/BD-217.md` taking on
   the cross-CLI discovery analog (RECOMMENDED) vs open a new v11.1 BD. [pack-chat-only;
   user authorizes the note at the gate.]
3. **Manifest record (§5.3):** DROP P5/P6 (RECOMMENDED — greenfield rule, nothing to
   collapse, category-mismatch) vs add a `.spawn-rule-manifest.txt` record + a coupled
   PACK-CHAT.md one-liner. Recommend DROP.
4. **PACK-CHAT.md step-1 carve-out note (§6.2, MINOR-3):** add the Claude-only ×3-exempt
   note (RECOMMENDED — BD-241 lands the first tagged Claude-only corpus rule) vs leave
   the procedure doc as-is.

---

## 12. Empirical-Evidence Block (every state-claim + every push-back)

| # | State-claim | Command | Output (verbatim/measured) | HEAD/date | Conclusion |
|---|---|---|---|---|---|
| 1 | The stale peer-messaging claim lives in 3 STRIP surfaces (not 2); one SHIPS | `grep -rln "no peer-messaging\|have no equivalent\|peer-messaging equivalent\|confirmed absent\|hub-and-spoke\|12462" --include=*.md .` (excl .git/test-fixtures/maintenance-docs) | live hits: BD-241.md, CLAUDE.md, pack-ops/OPTIONAL-FEATURES.md, pack-ops/PACK-MEMORY-RATIONALE.md, project-template/docs/pack/{OPTIONAL-FEATURES,PM-CHAT}.md, supporting-docs/METHODOLOGY.md | af73ffb / 2026-06-20 | SUPPORTED — original's "exactly 2" NOT-SUPPORTED (3 STRIP after triage) |
| 2 | METHODOLOGY L94-101 is the SAME stale factual claim (not a guard) | `sed -n '80,109p' supporting-docs/METHODOLOGY.md` | "Codex CLI's `/agent` … but no peer-messaging analog; Antigravity CLI's subagent mechanism is hub-and-spoke … no … peer-messaging across multiple parent turns" | af73ffb / 2026-06-20 | SUPPORTED (BLOCKER-1) |
| 3 | METHODOLOGY ships to clients | `grep -n METHODOLOGY scripts/init-project.sh` | L685 `cp "$PACK/supporting-docs/METHODOLOGY.md" "$TARGET/docs/pack/METHODOLOGY.md"`; L1298 install-map record | af73ffb / 2026-06-20 | SUPPORTED (escalates to REQUIRED) |
| 4 | The OPTIONAL-FEATURES/PM-CHAT(L907) hits are DIFFERENT capabilities (worktree / per-project memory) → KEEP | `sed -n '281,285p' project-template/docs/pack/OPTIONAL-FEATURES.md`; `sed -n '278,285p' pack-ops/OPTIONAL-FEATURES.md`; `sed -n '897,909p' project-template/docs/pack/PM-CHAT.md`; `sed -n '536,541p' .../PM-CHAT.md` | OPTIONAL-FEATURES: "their WORKTREE story is tracked … BD-217"; PM-CHAT L907 "no equivalent per-project MEMORY mechanism"; L539 "if your CLI offers no peer-messaging, re-spawn a fresh coder" (conditional guard) | af73ffb / 2026-06-20 | SUPPORTED (bounds the census — these are KEEP, not stale) |
| 5 | AGENTS/GEMINI carry `### Agent invocation rules` but no naming discipline + no Claude-only sub-section | `grep -n "### Agent invocation rules\|Sub-agent behavior" AGENTS.md GEMINI.md`; `grep -rniE "uniquely name\|name every spawn" CLAUDE.md AGENTS.md GEMINI.md` | AGENTS.md:244 + GEMINI.md:211 invocation-rules; 0 "Sub-agent behavior"; 0 naming-discipline hits | af73ffb / 2026-06-20 | SUPPORTED (MAJOR-1 + greenfield) |
| 6 | `### Agent invocation rules` ALREADY houses TAGGED trinity-parity corpus rules (the precedent for Bullet A) | `sed -n '242,347p' CLAUDE.md \| grep -E "\[rationale:"`; `for s in preflight-stop-means-stop enumerate-rules-inline rules-applied-verification-block; do grep -c "rationale: $s" CLAUDE.md AGENTS.md GEMINI.md; done` | 5 tagged slugs in the subsection; each of the 3 sampled = 1/1/1 across CLAUDE/AGENTS/GEMINI (parity) | af73ffb / 2026-06-20 | SUPPORTED (strengthens MAJOR-1 fix; G-1) |
| 7 | `preflight-stop-means-stop` has a manifest record with corpus = `### Agent invocation rules` | `grep -A3 "slug:.*preflight-stop-means-stop" pack-ops/.spawn-rule-manifest.txt` | `corpus: ### Agent invocation rules — "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern"` | af73ffb / 2026-06-20 | SUPPORTED (a tagged invocation-rule is precedented + manifestable) |
| 8 | BD-217 scope is worktree-isolation, NOT discovery/peer-messaging | Read `backlog/BD-217.md` full | title "Codex + Gemini worktree-isolation support"; Scope/Hard-constraints/Out-of-scope/Refs/AC all worktree; zero naming/registry/peer-messaging | af73ffb / 2026-06-20 | SUPPORTED (MAJOR-3) |
| 9 | BD-241 already names BD-217 "the cross-CLI-applicability anchor" | `sed -n '19p' backlog/BD-241.md` | "References: … BD-217 (Codex/Antigravity cross-CLI coordination — the cross-CLI-applicability anchor)" | af73ffb / 2026-06-20 | SUPPORTED (supports the scope-note over a new BD) |
| 10 | PUSHBACK: Check 46(a2) only requires the named surface to CONTAIN `## Pack memory`; it does NOT force a slug-specific paraphrase | `sed -n '7642,7704p' scripts/validate-pack.py`; `grep -c "## Pack memory" pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md` | FAIL only if references names no surface / surface absent / surface lacks literal `## Pack memory`; PACK-CHAT.md contains it 13×, PACK-AGENTS.md 7× | af73ffb / 2026-06-20 | SUPPORTED — adversarial "P5 hard-FAILs without P6" NOT-SUPPORTED (PUSHBACK) |
| 11 | The manifest is for COLLAPSED restatements; the new rules are greenfield (nothing to collapse) | manifest header (lines 1-22); `grep -rniE "uniquely name\|name every spawn\|spawn.*registry" pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md` | header: "records, for each COLLAPSED rule, … where the one-line pointer now lives"; 0 hits (no restatement exists) | af73ffb / 2026-06-20 | SUPPORTED (DROP P5/P6 decision) |
| 12 | Check 45 scans the WHOLE `## Pack memory` H2 incl. the Claude-only H3; heading regex is bare-slug | `sed -n '7359,7386p' scripts/validate-pack.py` | loop resets `in_pack_memory` only at `## ` H2; `heading_re = ^##\s+([a-z0-9][a-z0-9-]*)\s*$` | af73ffb / 2026-06-20 | SUPPORTED (Bullet B slug IS gated; bare-slug headings — MINOR-4) |
| 13 | Anti-restate (46b) uses each body's leading 120-char window, ≥60-char, substring-in-surface | `sed -n '7705,7732p' scripts/validate-pack.py` + extractor (`normalized = … [:120]`, `min_len=60`) | `if body in normalized: fail(...)` over 6 surfaces; window truncated `[:120]`, kept if `len>=60` | af73ffb / 2026-06-20 | SUPPORTED (MINOR-2 measure directive) |
| 14 | validate-pack baseline GREEN; Check 45 = 23↔23; Check 46 = 7 records / 0 restate / 49 candidates | `python3 scripts/validate-pack.py` | "Check 45 — 23 corpus … 23 rationale … bijection holds"; "Check 46 … 7 rule(s) … anti-restate 0 … 49 candidate bodies … >= 60 chars"; "PASSED — all checks clean" | af73ffb / 2026-06-20 | SUPPORTED (targets: 25↔25, 7 records unchanged, ~51 candidates / 0 restate) |
| 15 | PACK-CHAT.md propagation step-1 says "×3 trinity" with no Claude-only carve-out | `sed -n '499,509p' pack-ops/PACK-CHAT.md` | row 1 "Corpus imperative line ×3 trinity (CLAUDE.md / AGENTS.md / GEMINI.md `## Pack memory`)" — no "unless Claude-only" | af73ffb / 2026-06-20 | SUPPORTED (MINOR-3) |
| 16 | BD-238 + BD-240 both touch trinity `## Pack memory` + RATIONALE → serialize with BD-241 | `head -6 backlog/BD-238.md`; `head -6 backlog/BD-240.md` | BD-238 "touches rules + operating docs + trinity" (adds corpus rule); BD-240 "PACK-OPS; trinity `## Pack memory` … re-frame the rule … full propagation surfaces" | af73ffb / 2026-06-20 | SUPPORTED (rule-10 serialize) |
| 17 | Project trinity `## Project memory` is universal rules only (no Claude-only spawn sub-section) | Read `project-template/CLAUDE.md` `## Project memory` (system-reminder full content) | bullets: Trinity rule, No-destructive-git, PM-chat-does-not-architect, Project SSOT-first | af73ffb / 2026-06-20 | SUPPORTED (PR project-trinity NO-EDIT) |
| 18 | `graphify-out/` gitignored; registry needs no `.gitignore` edit | (per internal §3b + original claim 4) `.gitignore` L76 `graphify-out/`; `.pack-refresh-status` precedent | gitignored dir; leaf file covered | af73ffb / 2026-06-20 | SUPPORTED (G-3; KEPT decision 1) |
| 19 | name→agentId precedence validated; NO message-id primitive | external §1.3 (38 SendMessage: 37 agentId, 1 name, all success) + §1.4 | quoted in RESEARCH-BD-241-EXTERNAL.md | external 2026-06-20 | SUPPORTED (KEPT decision 3) |
| 20 | Codex #12462 CLOSED-COMPLETED; Codex MAv2 + Antigravity analogs exist (correction #1 premise) | external §5.1/§5.2 (`gh issue view 12462` → CLOSED/COMPLETED/2026-05-02; `Feature::MultiAgentV2`; Antigravity `agy` ID-addressing + auto-rewake) | quoted in RESEARCH-BD-241-EXTERNAL.md | external 2026-06-20 | SUPPORTED (drives corrected text) |

---

## 13. v11.1 / BD-217 HANDOFF SPEC (not a design — handoff only)

The cross-CLI registry+find+resume MECHANISM defers to v11.1, anchored on BD-217 (per
§4.1 scope-note). This is the HANDOFF SPEC; BD-217 runs its own researcher → architect
→ planner → coder per platform.

### 13.1 Verified cross-CLI analogs (from RESEARCH-BD-241-EXTERNAL §5)
| Capability | Codex CLI (MAv2) | Antigravity CLI (`agy`) |
|---|---|---|
| Spawn carries human NAME | YES (agent `name`; `nickname` display-only) | Partial — addressing by known ID; named-role types |
| Address by NAME | via agent `name`/`task_name` | by ID (name-addressing unconfirmed) |
| Resume by ID | YES (`resume_agent`) | YES (known ID; idle auto-rewake) |
| LIST live agents (programmatic) | **YES — `list_agents` tool** | interactive `/agents` (programmatic unconfirmed) |
| Durable registry | mailbox/tree state (MAv2) | cross-transcript visibility; durable registry unconfirmed |
| Gating | `multi_agent_v2` flag (merged, not GA-doc'd) | shipped in `agy` 2.0 (GA per I/O-2026) |

### 13.2 The 5 flagged-unverified items BD-217 MUST verify (external §6)
1. Codex MAv2 end-to-end USABILITY on a default install (merged-in-source + flag-gated;
   NOT exercised against a live binary; per-tool names from PR titles/community, not the
   official subagents page).
2. Antigravity durable-registry + human-NAME addressing (ID-addressing + idle auto-rewake
   + `/agents` panel verified; a durable, queryable, name-keyed registry UNVERIFIED).
3. Per-spawn instance-`name` uniqueness/collision behavior (Claude) — also a v11.0
   discipline assumption (§3.1); an empirical probe BD-217 can fold in.
4. `slug` addressability (Claude) — UNVERIFIED (likely not).
5. SendMessage-by-name survival across parent COMPACTION (Claude) — the
   registry-durability driver; UNVERIFIED.

### 13.3 How the v11.0 Claude design GENERALIZES
- The **naming discipline** (`<role>-<bd>-<facet>[-<seq>]`) is ALREADY shipped cross-CLI
  in v11.0 (Bullet A ×3) — BD-217 ADOPTS it unchanged.
- The **registry artifact** (gitignored JSONL `{name,agentId,purpose,status}`)
  generalizes: Codex populates `agentId` from `spawn_agent`'s id and MAY back the find
  with native `list_agents`; Antigravity populates the known agent ID and MAY still need
  the file ledger if no programmatic query exists.
- The **precedence** (name→agentId): Codex adds an OPTIONAL `list_agents` pre-step;
  Antigravity may invert to agentId→name pending §13.2 item 2.
- **Out of scope for BD-241:** per-platform tool names, flag-enablement UX, graceful
  degradation (BD-217's existing "degrade to non-isolated sequential" guarantee applies).
- **Premise:** BD-217 carries the CORRECTED premise (analogs EXIST but flag-gated/
  partly-unverified — NOT "confirmed absent"), per the §4.1 scope-note.

---

## 14. Plan-ready summary (for the planner, after user gate)
1. **Two corpus rules**, both tagged + bijection-paired: Bullet A (`spawn-unique-naming`,
   ×3 trinity in `### Agent invocation rules`) + Bullet B (`spawn-registry-find`,
   CLAUDE-only in `### Sub-agent behavior (Claude-only)`). + P2a/P2b bare-slug rationale
   sections. → Check 45 25↔25.
2. **3 stale-rationale corrections** (P3 CLAUDE.md, P4 RATIONALE.md, **P3b
   supporting-docs/METHODOLOGY.md — the SHIPPED BLOCKER fix**), audience-correct each.
3. **2 project-side edits** (PR1 naming-discipline + PR2 Claude-only mechanism
   blockquote in PM-CHAT.md). NO project-template METHODOLOGY (absent). NO project
   trinity edit.
4. **DROP** the manifest record (P5) + the mandatory PACK-CHAT paraphrase (P6).
5. **RECOMMENDED** pack-chat-only: PACK-CHAT.md step-1 Claude-only carve-out note; a
   BD-217 scope-note taking on the cross-CLI discovery analog.
6. **2 out-of-repo memory refines** (P6 `reference_sendmessage_uuid_addressing` + P7
   `MEMORY.md` index) — Pack-Chat upkeep.
7. **Commit scope:** NOT `pack-only` (P3b reaches `supporting-docs/`). Neutral framing OR
   split (recommended). PR1/PR2 + P3b are fixture inputs → push-time manifest (Check 62),
   not per-commit.
8. **rule-10:** BD-238 + BD-240 + BD-241 SERIALIZE on trinity + RATIONALE. Intra-BD-241:
   serial (or a 2-wide wave if the pack/product split is taken, files disjoint).
9. **KEEP intact** the 6 verified-correct decisions (§0); the fresh-agent subordination
   clause stays VERBATIM.

---

## 15. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | §12 — 20 state-claims, each with command + verbatim/measured output + HEAD `af73ffb`/2026-06-20 + conclusion (incl. the PUSHBACK claim #10 backed by `sed -n '7642,7704p'` + `grep -c "## Pack memory"` = 13/7). | COMPLIANT |
| ci-guard-design-measure-then-bound | §1 stale-claim census is GREP-DERIVED (8 hits triaged KEEP/STRIP, allowlist = the 3 STRIP, not widened); §8/§5/§6 measured Check 45/46/18 bodies + the live baseline (23↔23 / 7 / 49) before bounding; NO new validator designed (empty matching set). | COMPLIANT |
| adversarial-architect-review (independent challenge) | Re-measured every adversarial finding rather than rubber-stamping; PUSHED BACK on MAJOR-2 with code evidence (§5.1, claim #10); found a NEW gap G-1 (§7) neither prior pass named (the single-slug bijection/rationale-identity defect); cleared G-2/G-3 by measurement. | COMPLIANT |
| no-solutions-inherited / reach-own-conclusion | §3.1/§3.2 two rule texts; §4.1 BD-217 anchor options a/b + recommendation; §5.3 manifest DROP decision with category measurement; §11 four user-gate questions each with a recommendation + rationale. | COMPLIANT |
| verify-availability-not-just-existence | Relied on the research's VERIFIED facts (Codex #12462 CLOSED-COMPLETED; `Feature::MultiAgentV2`; Antigravity ID-addressing) for corrected text; carried the 5 unverified items forward to BD-217 (§13.2) rather than asserting; the message-id tier stays DROPPED (no primitive). | COMPLIANT |
| separate-pack-ops-from-product | §1.1 + §9.3 keep the line explicit: registry MECHANISM = pack-ops (gitignored runtime); naming DISCIPLINE = a shipped rule (cross-CLI); P3b = a SHIPPED product file (`supporting-docs/`) → the commit is NOT pack-only; the SCOPE NOTE for Pack Chat is REQUIRED (Check 36). Project trinity NO-EDIT to avoid importing the mechanism into product. | COMPLIANT |
| skill-agent-maintenance-mechanical | No agent-definition (`.claude/agents/*.md`) files touched; no `x-` contract change. Verified no agent def in the blast radius. | N/A: no agent-def edit in scope |
| cross-cli-reference-normalization | §1.1 P3/P4/P3b each get AUDIENCE-CORRECT wording (pack-ops rule jargon vs client-doc plain language — P3b explicitly drops `#12462`/`multi_agent_v2`); §3.1 Bullet A ×3 substitutes per-CLI name-field references (Agent-tool `name` / Codex `name`+`nickname` / Antigravity ID), NOT a byte-copy. | COMPLIANT |
| graph-first-context | Ran `graphify query "agent invocation rules sub-agent behavior peer messaging hub-and-spoke" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST (the INJECTED absolute path, NOT my own toplevel) → returned only pack-reviewer + tracker-fixture nodes (concept not a graph node) → G2 fallback to grep/Read for every load-bearing surface. | COMPLIANT |
| rule-10 parallelization map | §10 dedicated section: intra-BD-241 serial (or 2-wide if split); CROSS-BD BD-238 + BD-240 + BD-241 SERIALIZE on trinity + PACK-MEMORY-RATIONALE.md (claim #16 measured both sibling BDs' scope). | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Only read-only git: `git rev-parse HEAD`, `git status --short`, `git branch --show-current`. ZERO state-changing verbs. Sole write = this doc at `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-RECONCILED.md` (chunked Bash heredoc appends). No destructive op. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, COMPLIANT/N/A terminal; includes the graph-query-ran row (above) with the exact command + the fixture-noise result that triggered G2. No empty-evidence rows. | COMPLIANT |

---

*End DESIGN-BD-241-RECONCILED. Read-only architect reconciliation pass; no patch
produced; sole write is this doc. SUPERSEDES `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241.md`.
Every adversarial finding closed (BLOCKER-1, MAJOR-1/2/3, MINOR-1/2/3/4) — MAJOR-2 with
an evidence-backed PUSHBACK on the hard-fail framing + a DROP decision; one NEW gap (G-1)
found and fixed by the §2.2 split. The 6 verified-correct decisions KEPT intact.
Plan-ready after the §11 user design gate.*
