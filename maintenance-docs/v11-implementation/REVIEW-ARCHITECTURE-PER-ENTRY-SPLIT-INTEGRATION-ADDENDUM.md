---
title: REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM
reviewer: primary-chat (v11-dev) — fresh critical reviewer (no prior session context on the addendum itself)
target: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md (2,050 lines, 2026-05-14)
target-author: primary-chat (v11-dev) integration architect
parent-under-review: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (3,477 lines)
prior-review-of-parent: maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (1,433 lines) — established the 10 items the addendum closes
sidecar-corpus-not-edited: maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (1,649 lines) + ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md (1,101 lines)
date: 2026-05-14
recommendation: NEEDS-ANOTHER-ITERATION (one BLOCKER + four SHOULD-FIX + several minor)
---

# Review of ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md

## §0 — TL;DR

The addendum is a disciplined consolidation of ten user-Pack-Chat-decided
items. Items 2 (batch BLOCKER), 3 (Signal 9 honest framing), 7 (audit-
methodology fact-check + new pack-startup discovery), 8 (cost constants)
are addressed cleanly. Items 4 (concurrent-write expansion), 5 (mirror-
divergence layered defense), 6 (BD split), 9 (qualifiers), and 10
(leading-dot drop) are addressed substantively but with verifiable
defects in the cascade specifications.

**One BLOCKER.** Item 1's Layer 4 sub-agent context closure enumerates
fifteen pack-* agent files using `.md` extensions for ALL three CLIs —
including Codex, whose agents are `.toml`. The actual files are
`.codex/agents/pack-architect.toml`, `pack-coder.toml`, `pack-docs-
researcher.toml`, `pack-planner.toml`, `pack-reviewer.toml` (verified
by direct `ls`). The addendum's "15 files (5 agents × 3 CLIs)"
enumeration in §1.4, restated in §6.2 BD-167b File/Symbol, restated
in §6.5 commit 19b-PM, restated in §11.1 §18.2 row, all carry the
wrong file extensions for Codex. A coder or Pack Chat applying these
edits would either (a) fail to find the files (write goes to a non-
existent path), or (b) silently create new files at the wrong path.
This is a load-bearing factual error in a PM-only edit specification;
the planner cannot act on it without correction.

**Four SHOULD-FIX:**
1. **Body-field back-pointer breaks the sidecar's stricter "byte-additive"
   reading.** Item 1 §1.2 adds `Stream contract:` as a new first body
   field (between bold header and `Type:`) of every per-entry file.
   The addendum defends this as "byte-additive on the v10 entry grammar
   (V3.1-DELTA §3 A2 invariant preserved): the v10 grammar admits
   arbitrary body fields with `Field-Name: value` shape." But sidecar
   §3.1 (lines 248–256) defines byte-additive more strictly: "the file
   content from `**BD-NNN —` through the last narrative line of the
   entry is byte-identical to the corresponding span in the legacy
   monolithic `BACKLOG.md`." Inserting a new first body field violates
   that span-identity. The mirror-strip mechanism recovers the mirror
   but the per-entry file no longer matches the monolith span byte-for-
   byte. The addendum must either acknowledge this is a deviation from
   the sidecar's stricter framing (and defend the deviation) or pick
   a different position for the back-pointer that preserves the span.
   See §1 of this review for analysis.

2. **EXECUTION-PLAN line-282 update specification is internally
   inconsistent.** Item 2 §2.4 row "line 282 (totals line)" proposes:
   "Total: 26 main batches (24 + Batch 5b + Batch 21b + Batch 19 = 27
   total once per-entry split inserts; with conditional fix slots up
   to 30 main + 3 conditional)." This is double-counted and mathematically
   garbled: Batch 19 IS the per-entry-split batch (per §2.2 of the
   addendum), so listing "24 + Batch 5b + Batch 21b + Batch 19" lists
   Batch 19 twice (once in "24" and once explicitly), and the running
   sum "26 main = 27 total" contradicts itself. The original line 282
   reads cleanly: "25 main batches (23 + Batch 5b + Batch 20b)" —
   the structure is "N numbered slots + special non-numbered suffix
   batches = total." The post-cascade structure should be "26 main
   batches (24 numbered slots + Batch 5b + Batch 21b)" with no Batch
   19 mentioned separately. The Pack Chat applier cannot copy this
   line as-is. See §2 of this review.

3. **PACK-CHAT.md classification is inconsistent.** §6.2 BD-169
   File/Symbol places `project-template/docs/pack/PM-CHAT.md` (pack-
   product) in BD-169 (the pack-product wording BD), and §6.3 BD-169b
   places `PACK-CHAT.md` (pack-root, PM-only) in BD-169b. So far
   correct. But §6.5 row 8 (commit 19g-pack) says "BD-169 pack-product
   wording updates (... project-template PM-CHAT.md row, ...)" while
   §6.5 row 9 (commit 19g-PM) says "BD-169b PM-only wording (PACK-
   CHAT.md row, README.md Repository Layout entries)." That part is
   internally consistent. However, the addendum §6.1 rationale opens
   with "PM-CHAT.md is pack-product: ships from `project-template/docs/
   pack/`" which directly contradicts the prior-review's own §10.1
   classification of PM-CHAT vs PACK-CHAT (PACK-CHAT.md is pack-
   operational/PM-only; PM-CHAT.md is pack-product). The addendum's
   classification is correct, but the prompt for this review explicitly
   says "VERIFY: PM-CHAT.md classified as pack-product; commits go from
   8 to 10; v11.0 max from ~38 to ~40" — both classifications hold.
   The SHOULD-FIX is that the addendum nowhere lists `PACK-CHAT.md`'s
   exact line-42–43 row addition shape; it just says "PACK-CHAT.md row
   addition in file-access strategy table (lines 42–43) per original
   §4.4.3." The prior-review's own §10 walk noted that the original
   §4.4.3 list was incomplete (one likely miss flagged); the addendum
   does not re-verify that list. Lower-severity but should be tightened
   for the Pack Chat applier. See §6 of this review.

4. **Layer 2 regenerator divergence-warning for non-interactive paths
   creates a new silent-data-loss surface.** Item 5 §5.3 says the
   non-interactive path "prints a warning to stderr and proceeds" with
   silent-overwrite behavior. The migrator runs non-interactively per
   `scripts/lib/migrator-stages.sh:146` (`_stage_backup`) and downstream
   stages. If a developer runs `migrate-v10-to-v11.sh --apply` after
   making manual edits to a partial mirror, the migrator's non-
   interactive overwrite path drops the developer's edits with a stderr
   warning that may not be surfaced in the migrator's stdout summary.
   The addendum acknowledges "interactive prompting in CI / migrator
   would hang the run; silent-overwrite in interactive mode would lose
   user intent invisibly" — but does not address the symmetric concern:
   silent-overwrite in non-interactive migrator may also lose intent
   invisibly when stderr is redirected or buffered. The migrator's
   existing two-phase `--dry-run`/`--apply` discipline (BD-095) plus
   stage-level fail-stop is the existing safety net; the addendum
   should explicitly defer to it (e.g., "non-interactive contexts
   include the migrator post-dispatch hook; the migrator's `--dry-run`
   phase surfaces the planned overwrite before `--apply` commits to
   it; this Layer 2 warning is supplementary to the migrator's
   existing two-phase contract"). Without that bridging language, the
   defense-in-depth chain has a logical gap. See §5 of this review.

**Several minor / nits** detailed in §1–§12 below: stale-classifier
risk in `customization-preserve.sh` (a pre-existing bug the addendum
inherits but does not flag); §11.1 cascade table claims §17.5 is
unchanged but §17.5 references EXECUTION-PLAN batch numbers that
will renumber; addendum's §0 disposition table says "9 new BDs" but
§6.4 lists 8 new BDs + BD-161 absorbed — the 9 vs 8 count needs
disambiguation; addendum §11.1 omits §3.2 from the cascade table
even though §7's audit-methodology correction borrows the §3.2
friction-2 acknowledgement pattern (cosmetic).

**Recommendation: NEEDS-ANOTHER-ITERATION.** The Codex `.toml`
extension error is a load-bearing factual mistake that cascades
through three sections of the addendum (§1.4, §6.2 BD-167b, §6.5
commit 19b-PM) and would corrupt the resulting commit if applied
verbatim. The body-field back-pointer tension with the sidecar's
byte-additive framing is a defensible architectural choice but is
not honestly framed in the addendum (it claims preservation when
the sidecar's stricter reading shows deviation). The EXECUTION-PLAN
line 282 garble is unambiguously wrong. Each of these is a 5-15-
minute architect fix; the rest of the addendum is sound.

---

## §1 — Item 1 (Discoverability): closure verification

**Verdict: WEAK (one BLOCKER, one SHOULD-FIX, otherwise sound).**

### §1.1 — Drop of `stream-discovery` skill (Layer 3): PASS

The addendum drops the proposed Layer 3 skill cleanly per §1.3. The
defense ("skill authoring overhead is high; one-line directive is
cheap; PLATFORM-SKILLS.md skill-cell consistency surface (Check 31
per BD-146) untripped") is sound. The maintainability-principle
signal-trip avoidance argument is correct — a one-line directive in
an existing skill is mechanical maintenance, not structural.

### §1.2 — Layer 2 body-field back-pointer: SHOULD-FIX (sidecar tension)

**Verified problem statement.** Original §4.2 Layer 2 fails when an
agent reads with non-zero `offset` — the line-1 HTML comment is
missed. The addendum's diagnosis is correct.

**Verified solution mechanism.** A `Stream contract:` body field
between bold header and `Type:` would be inside any chunked Read of
the entry body. Sound recovery property.

**The defense claim is overstated.** Addendum §1.2 says the field is
"byte-additive on the v10 entry grammar (V3.1-DELTA §3 A2 invariant
preserved): the v10 grammar admits arbitrary body fields with
`Field-Name: value` shape, and the `Stream contract:` field follows
that shape."

But sidecar `ARCHITECTURE-PER-ENTRY-SPLIT.md:248-256` defines byte-
additive more strictly:

> "A single per-entry file contains exactly one v10-grammar entry.
> The bold-header line is the H1-equivalent ... then the field
> labels (`Type:`, `Status:`, etc.) ... This is byte-additive on
> entry format: the file content from `**BD-NNN —` through the
> last narrative line of the entry is byte-identical to the
> corresponding span in the legacy monolithic `BACKLOG.md`."

The sidecar's byte-additive contract is **span-identity to the
monolith** — the per-entry file's body must match the monolith
verbatim. Inserting a new first body field violates that contract.

**The mirror-strip mechanism recovers the MIRROR but does not
recover the per-entry-file = monolith-span identity.** The per-
entry file now contains content that never appears in the
monolith. A user who reads `/backlog/BD-160.md` directly sees a
field that does not exist in `BACKLOG.md`. This is a deviation
from the sidecar's contract, not a preservation of it.

**Three resolution paths:**
1. **Acknowledge the deviation honestly.** Frame Item 1.2 as "the
   sidecar's strict span-identity contract is loosened to allow a
   single architecturally-justified back-pointer field; the
   loosening is justified by the offset-read recovery requirement;
   alternatives considered (HTML-only, YAML frontmatter, directory-
   prefix encoding, trailer line) all fail one or more of the
   constraints."
2. **Place the back-pointer at a position the sidecar's contract
   already admits as variable.** The `Description:` field in v10
   grammar admits arbitrary multi-line content; a back-pointer line
   inside `Description:` would be span-additive at the description
   layer, not at the entry-shape layer. (Trade-off: less obviously
   structural; harder to grep by field name.)
3. **Drop the body-field upgrade and accept the offset-read
   limitation.** Add an instruction to the agents-reading-with-
   offset directive in pack-startup / pm-startup ("when reading a
   per-entry file with non-zero offset, also Read line 1 to
   recover the back-pointer"). This is what the original §4.2
   Layer 2 implicitly relied on; the addendum's §1.2 escalates it.

The addendum picks none of these explicitly; it claims preservation
when the sidecar's reading shows deviation. **SHOULD-FIX:** rework
the §1.2 defense to honestly frame the contract loosening, OR pick
resolution path 2 or 3.

**Mirror-strip discipline.** The strip-on-emit invariant in §1.2 is
sound. Idempotency claim verified — strip is regex-based and runs
on every emit. The "if a developer hand-edits a per-entry file and
removes the `Stream contract:` field, the next regeneration restores
it" claim is correct only if the regenerator re-inserts on emit.
The addendum says "the next regeneration restores it" but the
mirror-strip is on EMIT TO MIRROR (the regenerator strips when
producing the monolith from the per-entry tree, NOT when writing
back to the per-entry file). The decompose helper inserts on
DECOMPOSE; subsequent regeneration of the mirror does NOT touch
the per-entry file. So the field is restored ONLY if the user re-
runs decompose. Misclaim. **MINOR.**

### §1.3 — Layer 3 (one-line directives in pack-startup + pm-startup): PASS

The skill-edit shape (one body-directive line) is bounded and cheap.
The defense vs Check 31 (PLATFORM-SKILLS.md skill-cell consistency)
is correct: existing skill content gets one extra line, no new skill
file shipped. Sound.

The path enumeration in §1.3 is correct per the §7 fact-check
(pack-startup at pack root, not in `project-template/`).

### §1.4 — Layer 4 (pack-* agent prompts): BLOCKER (Codex extension error)

**The factual error.** §1.4 enumerates 15 files:

> "Pack-side per-CLI agent files:
> - `.claude/agents/pack-architect.md` + `.codex/agents/pack-architect.md` + `.gemini/agents/pack-architect.md`
> - [...four more agents, same pattern]
> Total: 15 files (5 agents × 3 CLIs)."

**Direct file system verification:**
- `ls .codex/agents/` returns `pack-architect.toml`, `pack-coder.toml`,
  `pack-docs-researcher.toml`, `pack-planner.toml`, `pack-reviewer.toml`
  (TOML, not Markdown).
- `ls .claude/agents/` returns five `.md` files (correct).
- `ls .gemini/agents/` returns five `.md` files (correct).

The actual file count is 15, but 5 of them have `.toml` extension,
not `.md`. The addendum's enumeration uses `.md` for all 15.

**Cascade through the addendum.** This error appears in:
- §1.4 (the source enumeration)
- §6.2 BD-167b File/Symbol "Pack-* agent prompt edits × 15 files
  (5 agents × 3 CLIs)" — same wrong shape
- §6.5 row 3 (commit 19b-PM) "pack-* agent prompts × 15"
- §11.1 §18.2 row "Item 1 (back-pointer body field add/strip per
  §1.2 above) ... Item 10 (paths)" — implicitly relies on the
  enumeration

**Why this is a BLOCKER, not a NIT.** The architecture document is
the spec for the planner/coder. A coder applying the spec to
"`.codex/agents/pack-architect.md`" finds no such file. Two failure
modes: (a) silent file creation at the wrong path (a new `.md` file
ships alongside the existing `.toml`, both present, validator
divergence); (b) error-out and Pack Chat investigates. Either way,
the spec must be corrected before the planner pass.

**The deeper architectural question.** Codex agents use a single
`developer_instructions = """..."""` block — the "Inputs to read"
addition is a string-edit inside that block, not a Markdown bullet
addition. Trinity rule still applies (per the existing pack-*
agent files being CLAUDE-mirrored across .claude/.codex/.gemini),
but the EDIT SHAPE for Codex differs from Markdown bullet add. The
addendum's "Sample addition" block:

> ```
> - /backlog/_rules.md (pack per-entry tree contract)
> - /changelog/_rules.md (pack changelog per-entry tree contract)
> ```

… is a Markdown bullet pair, which lands cleanly in `.claude/agents/
pack-architect.md` and `.gemini/agents/pack-architect.md` but
requires reformatting (no bullets; concatenated prose) for the
Codex `.toml` `developer_instructions` string. The addendum should
specify both shapes.

**MINOR add-on.** The addendum says "Resolution. Each pack-* agent
prompt file gains a `_rules.md` reference in its 'Before making any
design recommendation, read:' / 'Inputs to read' section." The actual
section heading varies between pack-architect ("Before making any
design recommendation, read:") and pack-coder / pack-reviewer
(different heading shapes). The addendum's "either heading" framing
is imprecise — coder authoring the edit needs to know the actual
heading text per agent. Pack-coder doesn't have a "Before making
any design recommendation" section at all.

### §1.5 — Closure verdict for Item 1

**Layers 1-3:** PASS.
**Layer 4:** BLOCKER (Codex `.toml` enumeration error) + MINOR
(per-agent heading variation imprecision).
**Layer 2 body-field back-pointer:** SHOULD-FIX (sidecar tension
not honestly framed) + MINOR (mirror-strip vs decompose-re-insert
clarification).

---

## §2 — Item 2 (BLOCKER batch positioning): closure verification

**Verdict: PASS with one SHOULD-FIX (line 282 math garble).**

### §2.1 — Verify-by-grep correctly applied: PASS

§2.1 states: "Verified error. `grep -nE '^\| \*\*[0-9]+[a-z]?\*\*'
maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`
returns the current batch sequence. Batch 18 is occupied by BD-111."

**Direct re-verification:** the grep returns rows for Batches 1–23
including row 272 "Batch 18 BD-111." The fact is correctly stated.

### §2.2 — Renumber cascade: PASS

The mapping table in §2.2 is correct:

| Original | NEW |
|---|---|
| Batch 19 (BD-105 ∥ BD-103) | Batch 20 |
| Batch 20 (BD-109 ∥ BD-110) | Batch 21 |
| Batch 20b (BD-136) | Batch 21b |
| Batch 21 (BD-100 audit) | Batch 22 |
| Batch 21b (conditional fix) | Batch 22b |
| Batch 22 (BD-102 dog-food) | Batch 23 |
| Batch 22b (conditional fix) | Batch 23b |
| Batch 23 (BD-093 release pin) | Batch 24 |

All eight rows map cleanly. No omissions.

### §2.3 — Sequencing rationale: PASS

The hard-sequencing constraints in §2.3 (AFTER Batch 6, 7-10, 12,
13, 17, 18; BEFORE Batches 22, 23) are coherent. The new "AFTER
Batch 18 (BD-111 dependency-API switch)" is correctly justified
as "the per-entry split's 1-to-N flat ↔ tracker contract for
project `implementation-plan/` composes against the FINAL tracker
dependency surface; BD-111 settles the dependency-API switch." This
is sound — BD-111's GH dependency API change shouldn't be re-done
once per-entry split lands, so per-entry split waits.

### §2.4 — EXECUTION-PLAN edit specification: SHOULD-FIX

**The line 282 row is mathematically garbled.** Per §2.4 row 4:

> | 282 (totals line) | "Total: 25 main batches (23 + Batch 5b + Batch 20b)" | "Total: 26 main batches (24 + Batch 5b + Batch 21b + Batch 19 = 27 total once per-entry split inserts; with conditional fix slots up to 30 main + 3 conditional)" — PRECISE wording for Pack Chat to refine |

**Why this is wrong:** the ORIGINAL line structure is "[main count]
([numbered slots] + [special suffix slots])". The original "23"
counts numbered slots 1–23; "5b" and "20b" are non-numbered suffix
slots; sum 23+1+1 = 25 main. After per-entry-split inserts as new
Batch 19 with renumber: numbered slots become 1–24 (the prior 23
slots plus the new Batch 19); suffix slots become 5b and 21b
(renamed from 20b). Sum: 24+1+1 = 26 main. The proposed text
double-counts Batch 19 (once in "24" and once in the explicit
"+ Batch 19"), gives a contradictory "26 main = 27 total" sum, and
introduces "30 main + 3 conditional" with no explanation of where
30 came from.

**The correct text should be:** "Total: 26 main batches (24 + Batch
5b + Batch 21b) + up to 3 conditional in-session fix commits if
audits/dog-food surface defects = max 29 commits, plus Batch 21b
internally ships 4 commits and new Batch 19 internally ships 10
commits, putting practical max at ~37 commits." Or similar; the
addendum says "PRECISE wording for Pack Chat to refine" which
abdicates the math to Pack Chat.

**Why this matters.** The addendum explicitly says the line edits
in §2.4 are surfaced for Pack Chat to apply mechanically. A
mechanically-applied edit cannot have "PRECISE wording for Pack
Chat to refine" embedded in it. Pack Chat would have to do the
arithmetic itself. The architect-pass output should be the actual
correct line.

### §2.5 — BACKLOG.md cascade: PASS

The seven line-edits to BD-138 (lines 1595/1597/1599/1600) and
BD-136 (line 1624) are individually correct per direct verification:
- Line 1595: BD-138 Unblocks references "Batch 21" (BD-100) and
  "Batch 22" (BD-102) — both correctly mapped to "Batch 22" and
  "Batch 23".
- Line 1624: BD-136 Blockers cites "Batch 22 BD-102" — correctly
  mapped to "Batch 23".

The note on line 1600 ("BD-138 is already Resolved; the Resolved
line edit is a historical-record clarification") is honest and
correctly defers to Pack Chat for the back-stamp vs parenthetical
decision.

### §2.6 — RELEASE-GATE.md cascade: PASS

Lines 38 and 39 verified — they reference Batch 21 and Batch 22
respectively, correctly mapped to Batch 22 and Batch 23.

### §2.7 — Renumber cascade summary: PASS

The "~18 lines across 3 files" estimate is consistent with §2.4
(8 line edits + 1 row insert), §2.5 (7 line edits), §2.6 (2 line
edits) = 17 line-edit-equivalents + 1 row-insert. Close enough.

### §2.8 — Closure verdict for Item 2

**The BLOCKER is correctly resolved.** Renumber cascade is complete
and verified. The line 282 totals-line garble is a SHOULD-FIX (the
arithmetic is wrong and the "Pack Chat refines" abdication is not
appropriate for an architect-pass output).

---

## §3 — Item 3 (§6.4 framing + mode-aware language): closure verification

**Verdict: PASS.**

### §3.1 — "Refactor not expansion" framing dropped: PASS

The honest framing in §3.1 of the addendum (the block quote starting
"Per-entry decomposition mandatorily extends the source-of-truth
surface...") is rigorously correct. It:
- Names the Signal 9 trip explicitly with citation (`ARCHITECTURE-
  SKILL-AGENT-MAINTAINABILITY.md` §3.2 line 305-306).
- Provides the architect-pass justification (Goal 3 + Goal 2
  invariants would fail without the extension).
- Acknowledges the structural change rather than reframing it.

**Direct verification of line 305-306 citation.** The actual text at
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-
MAINTAINABILITY.md` line 305: "**PM-only file expansion.** Any
addition to the agents-never-modify list or the PM-only file list
in PACK-AGENTS.md." Cited correctly.

The framing drop is exactly what the prior review's §6.4 SHOULD-FIX
asked for ("the defense should be tightened to acknowledge the
shape-expansion honestly rather than recasting it as a refactor").

### §3.2 — Mode-aware language throughout: PASS

The corrected §5.1 declarations distinguish flat-file mode (Mode 2)
and tracker mode (Mode 3) cleanly. The two-mode rule for workflow
source-of-truth resolution is explicit:
1. Tracker mode: read tracker via `tracker_agent_read.sh`
   `_tar_read_entry_tracker`.
2. Flat-file mode: read per-entry file `<stream>/<ID>.md`.

**Verified function name at scripts/lib/tracker-agent-read.sh:100**
(`_tar_read_entry_tracker`) and **line 153** (`_tar_read_entry_flat`).
Citations correct.

The mode-detection pointer to `scripts/lib/tracker-config.sh` and
`tracker_mode()` per BD-061 + V1 §3.2 is correct (verified via grep
in scripts/lib/).

### §3.3 — §6.4 PACK-AGENTS.md edit specification clarification: PASS

The clarification in §3.3 (write-authority protection in BOTH modes,
not source-of-truth designation) is internally consistent and
addresses the mode-confusion risk cleanly.

### §3.4 — §6.5 CLAUDE.md pack-memory bullet correction: PASS

The corrected bullet text:
- Names both modes with concrete predicate (`tracker.toml` presence
  + content + `migration.forward_complete = true` for Mode 3).
- Names the canonical mirror locations correctly (`BACKLOG.md`,
  `CHANGELOG.md`, `IMPLEMENTATION-PLAN.md`).
- Refers reader to `<stream>/_rules.md` for further detail.
- Uses the post-Item-10 non-dot paths consistently.

The bullet is concrete enough for Pack Chat to apply directly. PASS.

### §3.5 — Closure verdict for Item 3

**PASS.** The §6.4 framing is honestly Signal-9-tripped and defended.
Mode-aware language is uniformly applied across §5.1 / §5.2 / §6.4
/ §6.5. No "refactor not expansion" language survives in the addendum.

---

## §4 — Item 4 (§7.4 concurrent-write expansion): closure verification

**Verdict: WEAK with one SHOULD-FIX (non-interactive silent overwrite gap).**

### §4.1 — Six scenarios enumerated: PASS

Each of the six scenarios in §4.2 has a race-window + safety-net +
failure-mode triple. The enumeration is structurally complete.

**Spot-check Scenario 4 (sub-agent prohibition).** "Per Goal 3
binding (original §6 unified treatment) + original §6.3 ('tooling-
not-agent'), the helpers are NOT agent capabilities. Pack-* sub-
agents read source; they do not invoke the helpers."

This is the cleanest of the six scenarios. The "stated explicitly
so future contributors don't violate" language is exactly the kind
of forward-defense the prior review asked for. PASS.

**Spot-check Scenario 5 (BD-132 reference).** "Per pack
`BACKLOG.md:1743`" — verified directly that BACKLOG.md line ~1743
contains BD-132 entry. The cross-reference is correct and the
"per-entry split inherits the fix" framing is accurate.

### §4.2 — Defense-in-depth layering: PASS

Layer 1 (stop-before-commit) / Layer 2 (git merge-conflict) / Layer
3 (CI Check 32+33) is clean. The cite to `PACK-CHAT.md:50-99` and
`EXECUTION-PLAN-V11.0.md:290-296` is verifiable (PACK-CHAT.md does
have a behavioral-rules section in that range; EXECUTION-PLAN
§A "Commit / push gating" lives in lines 290-296).

### §4.3 — CI-dependence gap acknowledgement: PASS

The three failure conditions (no push / no client CI / branch
excluded from CI workflow) are realistic. The acknowledgement that
"transient divergence is possible" while "Goal 2 holds long-term
(silent overwrite eventually corrects)" is honest framing.

### §4.4 — Optional pre-commit hook for planner: PASS

The Layer 0 surface (opt-in pre-commit hook in `project-template/
scripts/git-hooks/`) flagged for v11.x planner is well-bounded.
"Out of scope for the v11.0 design; surfaced for the planner /
coder as a Phase 2 enhancement if demand emerges." Correctly
positioned.

### §4.5 — SHOULD-FIX: non-interactive migrator silent-overwrite gap

**The gap.** Item 5 §5.3 (which §4 cross-references) says non-
interactive contexts "print 'Warning: mirror was hand-edited;
regenerator overwriting.' to stderr and proceeds." This includes
the v10→v11 migrator.

The migrator is the highest-stakes non-interactive context: a
client running `migrate-v10-to-v11.sh --apply` after they have
manually edited the partial mirror would silently overwrite their
edits with a warning that may be (a) lost in stderr buffering,
(b) lost if Pack Chat captures only stdout, (c) not surfaced in
the migrator's stage summary.

The migrator already has a defense for this: BD-095's two-phase
`--dry-run`/`--apply` discipline. A user can run `--dry-run` to
see what `--apply` would do before committing. The Layer 2 warning
adds nothing if the user runs `--dry-run` first.

**The addendum does not bridge this.** §4.6 says "Original §10.6
(Goal 2 enforcement) gains the CI-dependence gap acknowledgement
explicitly; see Item 5 §5.4 below for the expanded §10.6 treatment."
But Item 5 §5.3's non-interactive path doesn't reference the
migrator's existing two-phase contract. The defense-in-depth
argument has a logical gap: Layer 2's non-interactive silent
overwrite is the same failure mode the layered defense was supposed
to prevent.

**Resolution.** Item 5 §5.3 should add: "For migrator non-interactive
invocations, the existing BD-095 two-phase `--dry-run`/`--apply`
discipline is the primary defense; the Layer 2 stderr warning is
supplementary. For other non-interactive contexts (CI, scripted
batch runs), the warning is the only Layer 2 signal; users running
in those contexts should accept the silent-overwrite contract or
opt into Layer 0 (pre-commit hook)."

**Severity.** SHOULD-FIX, not BLOCKER. The mechanism still works —
silent overwrite is the documented behavior. But the defense-in-
depth chain has a logical gap that a future reader would notice.

### §4.6 — Closure verdict for Item 4

The 80-100-line expansion is achieved. Six scenarios enumerated.
Defense-in-depth layered. CI-dependence gap acknowledged. Sub-
agent prohibition explicit. **One gap:** non-interactive migrator
defense-in-depth not bridged with BD-095's existing `--dry-run`
discipline.

---

## §5 — Item 5 (§10.6 Goal 2 layered defense): closure verification

**Verdict: PASS with the same gap as Item 4.**

### §5.1 — New failure mode honestly named: PASS

§5.1 of the addendum: "Per-entry decomposition introduces a failure
mode that did NOT exist in v10.1: mirror divergence. In v10.1, the
monolithic file IS the source of truth; there is no 'mirror' to
diverge from."

This is the explicit acknowledgement the prior review asked for.

### §5.2 — Layer 1 (DO NOT EDIT mirror preamble): PASS

The HTML-comment shape is concrete and idempotent (re-emitted on
every regeneration). The placement in `_intro.md` (which the mirror
generator emits verbatim per the §3.6 sidecar concatenation order)
is mechanically correct.

**One MINOR concern.** The sample text says "To change an entry,
edit the corresponding `/backlog/<ID>.md` per-entry file and re-run
the mirror regenerator." A user with no `_rules.md` context might
not know how to "re-run the mirror regenerator" — the warning
should reference the helper script path or the `pack` verb, e.g.,
"…and re-run `bash scripts/lib/<helper>.sh regenerate-mirror
/backlog/`" or "…and run `pack regenerate /backlog/`." Pack-product
authoring detail; planner can refine. NIT.

### §5.3 — Layer 2 (regenerator divergence-warning): SHOULD-FIX

See §4.5 of this review — the non-interactive silent-overwrite path
needs to bridge to the migrator's BD-095 `--dry-run`/`--apply`
two-phase contract. Same finding; cross-referenced.

### §5.4 — Layer 3 (defense-in-depth doc in original §10.6): PASS

The block quote that appends to original §10.6 is rigorous:
- Five layers enumerated with clear in-scope vs flagged-for-planner
  distinction.
- Pack-CI scope limit explicitly named ("Pack-CI does NOT extend to
  client repos").
- Layer 0 (pre-commit hook) positioned as opt-in for clients.

### §5.5 — Layer 4 (pack doctor extension): PASS

Correctly identifies BD-130 (`pack tracker doctor`, per pack
`BACKLOG.md:1765`) as the existing surface. Three planner options
(fold into BD-130, open new BD, accept Layers 0-3) is clean
deferral.

**Verified BD-130 location.** Direct grep of BACKLOG.md confirms
BD-130 exists and is `pack tracker doctor` per the existing tracker
helper inventory. Citation correct.

### §5.6 — Layer 0 (opt-in pre-commit hook for planner): PASS

Cross-references Item 4 §4.5 cleanly. No duplication.

### §5.7 — Closure verdict for Item 5

The five-layer defense is well-specified. Layer 1 mechanism is
concrete (HTML-comment in `_intro.md`; regenerator emits verbatim).
Layer 2 distinguishes interactive vs non-interactive (with the
SHOULD-FIX gap noted in §4.5/§5.3). Layer 3 explicitly acknowledges
the new failure mode (mirror divergence didn't exist in v10.1).
Layers 4 and 5 are correctly deferred to planner.

---

## §6 — Item 6 (§17.2 BD split): closure verification

**Verdict: PASS with one SHOULD-FIX (PACK-CHAT.md row spec imprecision)
and the cascading Codex-extension BLOCKER from §1.4.**

### §6.1 — Rationale for the split: PASS

The rationale ("PM-only edits should land in their own commit so
the stop-before-commit visibility is on the PM-only diff in
isolation") is sound and matches the EXECUTION-PLAN §A.1 stop-
before-commit discipline.

### §6.2 — BD-167 / BD-167b split: PASS (with BLOCKER carried from §1.4)

The File/Symbol fields are non-overlapping:
- BD-167 (pack-product): canonical templates × 5 streams + migrator
  install plumbing + tracker-agent-read extension + BD-161 SKILL.md
  installs.
- BD-167b (PM-only): trinity Key files × 6 + PACK-AGENTS.md PM-only
  directories list + STATUS.md disclaimer + CLAUDE.md pack-memory
  bullet + pack-* agent prompt edits × 15.

**The pack-* agent prompt edits × 15 carries the §1.4 BLOCKER**
(Codex `.toml` extensions, not `.md`). This must be corrected in
both §1.4 source and §6.2 BD-167b File/Symbol restatement.

**STATUS.md treatment:** §6.2 says "(the project-template-side
`STATUS.md` if it ships; otherwise surfaced for client-side STATUS.md
only per the client-tooling boundary)." The prior review's §5.3
flagged exactly this ambiguity. The addendum acknowledges it but
does not resolve — defers to "client-tooling boundary." This is
honest deferral; PASS.

### §6.3 — BD-169 / BD-169b split: PASS with one SHOULD-FIX

The split is structurally sound:
- BD-169 (pack-product wording): MERGE-STRATEGY paragraph,
  MIGRATION-v10-to-v11 section, project-template PM-CHAT.md row,
  auditor agent edits × 3, pack-startup directive × 3, pm-startup
  directive × 4.
- BD-169b (PM-only wording): PACK-CHAT.md row + README.md
  Repository Layout entries.

**SHOULD-FIX (PACK-CHAT.md row exact spec).** §6.3 says "PACK-CHAT.md
row addition in file-access strategy table (lines 42–43) per
original §4.4.3." The addendum nowhere shows the exact row text.
The original §4.4.3 also did not show the exact text. Pack Chat
applying this edit needs the actual row content (column values for
the file-access strategy table). The architect-pass output should
include either the exact row or an explicit deferral to planner.

**Auditor agent edits × 3 verified correct.** Per direct ls,
project-template `.claude/agents/auditor.md`, `.codex/agents/
auditor.toml`, `.gemini/agents/auditor.md` exist. Same Codex `.toml`
vs `.md` issue applies here that applied in §1.4 — the addendum
says "auditor agent file extensions × 3 CLIs" without specifying
the per-CLI extension. **MINOR** (the Codex `.toml` distinction is
implicit in trinity rule and the planner-coder pair will catch it,
but explicit naming is cleaner).

**Pack-startup directive × 3 verified correct.** Three pack-root
files: `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-
startup/SKILL.md`, `.gemini/commands/pack-startup.toml`. (Note: the
Gemini one is a `.toml` per §1.3 enumeration, which IS correctly
called out — Gemini commands are `.toml`, while Gemini agents are
`.md`. The addendum's per-CLI specifics are correct here.)

### §6.4 — Updated Batch 19 BD list: PASS

10 BDs total. Blocker chains coherent:
- BD-164 ← BD-104, BD-128, BD-131..BD-134, BD-111
- BD-167 ← BD-164
- BD-167b ← BD-167
- BD-165 ← BD-164
- BD-166 ← BD-164, BD-167
- BD-168 ← BD-164, BD-167
- BD-169 ← BD-167
- BD-169b ← BD-169
- BD-170 ← BD-164, BD-160

The status-flips row is correct (Pack-Chat-direct, BD-161 absorbed
with attribution).

**One small INCONSISTENCY.** §0.2 says "BD-set growth (Item 6):
BD-164..BD-170 + BD-167b + BD-169b = 9 new BDs (was 7 in original
§17.2)." But BD-164..BD-170 is 7 BDs (164/165/166/167/168/169/170)
and adding 167b + 169b makes 9 — count is correct, but §0.2 also
says "(was 7 in original §17.2)" which conflates BD-164..BD-170
(7 BDs from original) with the new total. The arithmetic is right
but the framing is confusing. NIT.

### §6.5 — Updated Batch 19 commit ordering: PASS

10 commits total. Each commit has clear author (pack-coder vs
Pack Chat direct), clear scope (one BD per commit, except 19h which
covers status flips), clear dependency (each commit's prerequisite
identifiable from the BD blocker chain).

**Commit 19b-pack vs 19b-PM ordering.** §6.5 row 2 (19b-pack) lists
"BD-167 canonical templates × 5 streams + BD-161 net-new SKILL.md
installs + migrate-v10-to-v11.sh install step extension + tracker-
agent-read.sh extension." Row 3 (19b-PM) is the BD-167b PM-only
edits. Order is correct: pack-product first, then PM-only edits
that reference the pack-product paths.

### §6.6 — v11.0 commit count update: PASS

"Original §17.3 had 8 commits (max ~38 total); Item 6 split adds 2
to make 10 (max ~40)." Math checks: 8+2=10; 38+2=40. PASS.

### §6.7 — EXECUTION-PLAN §1 in-scope inventory: PASS

"+9 new BDs ... bump 'Total' from '41 BDs in-scope' to '50 BDs in-
scope'." Math: 41+9=50. PASS.

### §6.8 — Closure verdict for Item 6

The split is clean. Commits separable. PM-only edits land in their
own commits per stop-before-commit discipline. The Codex `.toml`
BLOCKER from §1.4 carries through. The PACK-CHAT.md row exact spec
is missing (SHOULD-FIX).

---

## §7 — Item 7 (§1.1 audit-methodology + fact-check sweep): closure verification

**Verdict: PASS — fully resolved with new pack-startup discovery sound.**

### §7.1 — audit-methodology correction: PASS

**Direct verification:**
- `ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/
  project-template/skills/audit-methodology/` returns the directory.
- `SKILL.md` is 26496 bytes (matches addendum claim).

**Original §1.1 line 260-263 verified verbatim** (read directly):
"`audit-methodology/SKILL.md` (auditor scope rules) — searched; no
current `audit-methodology` skill exists in pack repo at this name;
the audit methodology lives in the auditor agent files (project-
template/.claude/agents/auditor.md and per-CLI mirrors)."

The original was wrong; the addendum's correction is correct.

The acknowledgement pattern follows the friction-2 §3.2 style
("Cited correctly herein"). Honest framing.

### §7.2 — Fact-check sweep: PASS with one new pack-startup finding

**Direct verification of pack-startup paths:**
- `find . -path "*/skills/pack-startup/SKILL.md"` returns:
  - `.codex/skills/pack-startup/SKILL.md` (PACK ROOT)
  - `.claude/skills/pack-startup/SKILL.md` (PACK ROOT)
- `find . -name "pack-startup*"` returns also:
  - `.gemini/commands/pack-startup.toml` (PACK ROOT)
  - (no project-template/ matches)

**The addendum's claim is correct:** pack-startup is pack-repo-only
and lives at PACK ROOT, not in `project-template/`.

**Original integration architect doc citations of pack-startup:**
Direct grep returns:
- Line 243-245: cites `project-template/.claude/skills/pack-startup/
  SKILL.md`, `.codex/skills/pack-startup/SKILL.md`, `.gemini/commands/
  pack-startup.toml` — first one is wrong (`project-template/`
  prefix); second is ambiguous (no `project-template/` prefix
  shown but in a list following the first); third is correct.
- Line 941-944: cites `project-template/skills/pack-startup/SKILL.md
  (canonical)` and the three per-CLI mirrors — first one is wrong;
  the three per-CLI mirrors are correct PACK ROOT paths.
- Line 861-863: cites `.claude/skills/pack-startup/SKILL.md:19-21`,
  `.codex/skills/pack-startup/SKILL.md:19-21`, `.gemini/commands/
  pack-startup.toml:16-18` — all PACK ROOT, all correct.
- Line 1957: cites "(canonical pack-startup + per-CLI mirrors × 2
  paths" — implies a canonical at project-template, which is wrong.

**The addendum's pack-startup correction is real and important.**
The original's path-citation was inconsistent: lines 861-863 had
it right, lines 243-245 + 941-944 + 1957 had it wrong. The addendum
identifies the wrong-citations and corrects.

**One MINOR.** The addendum's §7.2 reports the inaccuracy precisely
("Pack-startup is a pack-repo-only skill. It does NOT ship in
`project-template/`") but does NOT enumerate every place in the
original doc where the wrong citation appears — it just names the
two contexts (§1.1 line 243-245 cluster + §4.4.2 line 941-944
cluster). A reviewer or planner reading the original for cascade
verification would have to grep for all `pack-startup` occurrences.
The addendum's cascade audit (§7.3) names §1.1 + §4.4.2 + §17.2
BD-169 — three places. Direct grep confirms these are the locations
of the wrong citations. The cascade is complete. PASS.

### §7.3 — Cascade impact: PASS

The cascade list correctly identifies the original-doc sections
that carry the wrong pack-startup citation.

### §7.4 — audit-methodology skill consideration: PASS

The deferral to planner ("planner verifies whether the skill file
itself needs the extension or whether the auditor agent files cover
it") is appropriately scoped.

### §7.5 — Closure verdict for Item 7

**PASS.** Both inaccuracies in original §1.1 are corrected with
honest acknowledgement. The fact-check sweep is documented (~30
files verified). The new pack-startup discovery is factually correct
and the cascade is complete.

**Implicit additional finding** — the original integration architect
doc references `project-template/.claude/skills/pack-startup/SKILL.md`
in §1.1 line 243 as the FIRST item in a comma-separated list, then
follows with `.codex/skills/pack-startup/SKILL.md` and `.gemini/
commands/pack-startup.toml` (no `project-template/` prefix on items
2-3). A reader could interpret items 2-3 as inheriting the prefix
from item 1, in which case all three are wrong. The addendum's
correction explicitly says "they live at `.claude/skills/`, `.codex/
skills/`, `.gemini/commands/` at PACK ROOT level" which is the
correct interpretation. The addendum surfaces the correction
cleanly.

---

## §8 — Item 8 (cost constants 10ms→2ms): closure verification

**Verdict: PASS.**

### §8.1 — Constant correction: PASS

10ms/file → ~2ms/file is realistic. Modern Markdown read+parse on
contemporary hardware is sub-millisecond for small files; ~2ms is
a conservative "cold cache + parser pass" estimate. The prior
review's §2.1 estimate was 1-3ms; addendum's 2ms is within range.

### §8.2 — Recomputed table: PASS

Spot-check the v11.0 baseline row:
- Sidecar model: 150 entries × 3-5 regen runs × ~2ms = 900-1500ms
  ≈ 0.9-1.5 sec. Table says 0.9-1.5 sec. PASS.
- Commit-time model: 150 entries × 1 regen × ~2ms = 300ms ≈ 0.3
  sec. Table says 0.3 sec. PASS.
- Speedup ratio: 1.5/0.3 = 5x or 0.9/0.3 = 3x. Range 3-5x. The
  addendum says "3.3× speedup of commit-time over sidecar-model
  survives any reasonable constant" — 3.3× is in the range. PASS.

Spot-check the v13 projected row:
- Sidecar: 1000 × 3-5 × ~2ms = 6-10 sec. Table says 6-10 sec. PASS.
- Commit-time: 1000 × 1 × ~2ms = 2 sec. Table says ~2 sec. PASS.

### §8.3 — Updated §7.1 prose: PASS

"50-second regenerator runs at v13 scale" → "10-second regenerator
runs at v13 scale under the sidecar model" and "2-second runs under
the commit-time model" — consistent with the recomputed table.

### §8.4 — Empirical-measurement note: PASS

"Constants are approximate ... planner-pass implementation should
empirically measure regenerator cost on representative hardware
(CI runner + developer macOS/Linux)" — appropriate planner deferral.

### §8.5 — Closure verdict for Item 8

PASS. Constants corrected, table recomputed consistently, prose
updated, empirical-measurement deferral honest.

---

## §9 — Item 9 (BD File/Symbol qualifiers + pseudo-code disclaimers): closure verification

**Verdict: PASS.**

### §9.1 — Qualifiers added: PASS

The addendum extends the "(planner picks file structure / specific
helper file naming)" qualifier consistently across BD-167, BD-167b,
BD-169, BD-169b. Per §6.4 these qualifiers are inline in the BD
table. The qualifier wording matches what BD-164 already had per
original §18.1 #2.

BD-165 + BD-166 + BD-168 + BD-170 each get their own qualifier
shape ("planner picks function name / position", "planner picks
fixture-generator function structure"). Consistent.

### §9.2 — Pseudo-code disclaimers: PASS

The disclaimer ("Pseudo-code sketches the behavioral contract;
planner refines exact implementation") is concrete and bounded.
"Pseudo-code STAYS in the original integration architect doc as
illustrative scaffolding" — the disclaimer adds context, doesn't
remove content. Sound.

### §9.3 — Closure verdict for Item 9

PASS. Mechanical refinement; no design or scope change.

---

## §10 — Item 10 (REDESIGN-CORE #2 leading-dot drop): closure verification

**Verdict: PASS with one MINOR (cascade audit completeness).**

### §10.1 — The decision: PASS

Pack-side `/.backlog/` → `/backlog/`; `/.changelog/` → `/changelog/`.
Project-side unchanged (already non-dot). `.pack-tracker/` STAYS
leading-dot. Sidecar parent + addendum NOT edited.

The semantic distinction (tool state vs primary data) is preserved:
`.pack-tracker/` is tool state (id-map.json, checkpoints, etc.);
`/backlog/` and `/changelog/` are primary data (humans hand-edit).
Sound.

### §10.2 — Rationale: PASS

Three rationales (Goal 1 discoverability, Goal 2 pack/project
symmetry, semantic alignment of leading-dot signal). Each is
concretely defended.

The Goal 1 rationale ("`ls` without `-a` does not show them; `find`
without explicit predicates does not descend; many IDE file browsers
default to hidden; macOS Finder hides them by default") is
verifiable. PASS.

### §10.3 — Cascade through original doc: PASS

The enumeration covers §2.1, §2.4, §2.6, §2.7, §3.3, §4.1, §4.2,
§4.4.1, §4.4.3, §4.5, §5.1, §5.2, §5.5, §5.6, §6.1, §6.4, §6.5,
§7.3, §7.6, §8.16, §8.17, §8.18, §9.1, §9.5, §9.7, §10.1, §10.5,
§11.3, §12, §14.2, §14.3, §16.1, §17.2, §17.4 — 30+ sub-sections.

**Spot-check cascade chain 1: §2.1 → §6.1 audit table → §17.2 BD
File/Symbol.** Original §2.1 names `/.backlog/` and `/.changelog/`
in stream-shape rationale; §6.1 names them as protected surfaces
in the write-authority audit table; §17.2 BD-167 File/Symbol names
the install paths. The addendum's cascade hits all three (§10.3
explicitly lists §2.1, §6.1, and §17.2). PASS.

**Spot-check cascade chain 2: §4.2 Layer 2 sample HTML-comment.**
The original's HTML-comment back-pointer line uses `/.backlog/`;
the addendum's §1.2 sample uses `/backlog/`. The cascade hits §4.2
(per §10.3 enumeration). The addendum's sample in §1.2 itself uses
the post-Item-10 form. Internally consistent.

**Spot-check cascade chain 3: §10.1 Check 32 STREAMS constant.**
Original §10.1 pseudo-code has `STREAMS = [(...path...)]` with
leading-dot paths. Addendum §10.3 names §10.1 explicitly: "STREAMS
constant shape — paths update to non-dot." Cascade present.

### §10.4 — NEW §16.3 entry text: PASS

The new §16.3 entry parallels §16.1 (REDESIGN-CORE #1 regenerator
invocation) cleanly:
- Names the sidecar's locked decision.
- Explains why integration overturns.
- Names the proposed alternative.
- Explains why the alternative resolves the failures.
- Scopes the redesign (path-naming only).
- Names the cascade impact.
- Names the sidecar parent compatibility note (sidecar files NOT
  edited; integration's REDESIGN-CORE language is authoritative).

This matches the §16.1 precedent. PASS.

### §10.5 — NIT sizing rationale: PASS

The defense ("naming-only; no contract changes; no semantic changes;
no new mechanisms; no new BDs; mechanical cost; no v11.0 ship-date
impact") is sound. The user-Pack-Chat call to overturn captures
qualitative gains; cost is mechanical cascade.

### §10.6 — Cascade verification: MINOR (one omission)

§10.6 says "Per the PROCESS SAFEGUARD instruction (cascade
verification: every REDESIGN-CORE / structural change MUST propagate
through ALL references in the original doc), §10.3 above enumerates
the affected sections explicitly: §2.1, §2.4, §2.6, §2.7, §3.3,
§4.1, §4.2 (Layer 1 + Layer 2), §4.4.1, §4.4.3, §4.5, §5.1, §5.2,
§5.5, §5.6, §6.1, §6.4, §6.5, §7.3, §7.6, §8.16, §8.17, §8.18,
§9.1, §9.5, §9.7, §10.1, §10.5, §11.3, §14.2, §14.3, §16 (gains
§16.3 NEW), §17.2 (replaced via Item 6 §6.4), §17.4."

**Direct grep for `/.backlog\|/.changelog` in original doc:**
returns matches in §2.1, §2.4, §2.6, §2.7, §3.3, §4.1, §4.2, §4.5,
§5.1, §5.2, §5.5, §5.6, §6.1, §6.4, §6.5, §7.3, §7.6, §8.16, §8.17,
§9.1, §9.5, §9.7, §10.1, §10.5, §11.3, §14.2, §14.3, §17.2, §17.4
— PLUS §4.4 and §4.4.3 (subsections of §4.4 not separately listed)
— PLUS §8.18 (cited).

The addendum's enumeration is substantively complete. One sub-section
(§4.3 recovery scenarios table) has an indirect reference via the
Layer 2 row but no path mention. Could be added for completeness.
**MINOR.**

### §10.7 — Closure verdict for Item 10

PASS. The leading-dot drop is sound; cascade enumeration is
substantively complete (one minor omission); §16.3 NEW entry
parallels §16.1; sidecar parent + addendum correctly NOT edited.

---

## §11 — Cross-cutting reviews

### §11.1 — Cascade audit table (§11.1 of addendum): PASS with one inconsistency

**Inconsistency.** §11.1 row "§3.2 Friction 2: §5.r citation slip"
is marked unchanged. But Item 7 (§7 of the addendum) explicitly
borrows the friction-2 acknowledgement pattern ("the parallel to
original §3.2 friction 2 acknowledgement pattern"). If §3.2 is
unchanged, the borrowing is fine. But the cascade table should
note that §3.2 is the source of the pattern Item 7 reuses (a
"referenced by Item 7" annotation). Cosmetic. NIT.

### §11.2 — Coverage verification: PASS

The addendum claims 60+ sub-sections affected; "Modified" list and
"Unchanged" list together cover the full original-doc TOC. Spot-
check three "Unchanged" rows (§2.2 Mirror contract, §6.2 Pack agent
permission verification, §10.4 Why three checks not one) — none of
these are touched by any of the 10 items. PASS.

### §11.3 — Architect-overreach scan: PASS

**Direct verification.** The addendum has no Edit calls to PM-only
files (BACKLOG / CHANGELOG / README / PACK-CHAT / PACK-AGENTS /
CLAUDE / AGENTS / GEMINI / EXECUTION-PLAN-V11.0 / RELEASE-GATE /
V3.x corpus). It surfaces edit specifications in §2.4 / §2.5 / §2.6
for Pack Chat to apply.

The addendum has no Edit calls to pack-product files (project-
template/, supporting-docs/, scripts/). It surfaces planner / coder
work via the BD table in §6.4.

The addendum has no Edit calls to the sidecar's design corpus
(`maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md`,
`-ADDENDUM.md`) or the original integration architect doc
(`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-
INTEGRATION.md`).

The §16.3 NEW REDESIGN-CORE entry is in the addendum doc itself,
not edited into the original. The "supersedes those references —
future readers see the sidecar's leading-dot paths and the
integration's non-dot correction in the same way they see REDESIGN-
CORE #1" pattern is honored.

**PASS.** Architect-pass discipline preserved.

### §11.4 — v10 entry-format grammar: SHOULD-FIX (carry from §1.2)

The body-field back-pointer (§1.2) claim of "byte-additive on the
v10 entry grammar (V3.1-DELTA §3 A2 invariant preserved)" is at
tension with the sidecar's stricter span-identity reading. See §1.2
of this review. **SHOULD-FIX.**

### §11.5 — Internal consistency of addendum structure: PASS

Final-line marker present (§12, "ARCHITECTURE-PER-ENTRY-SPLIT-
INTEGRATION-ADDENDUM-COMPLETE: 2026-05-14 ..."). Section count
matches §0 promise (§0 + §1 + §2 + ... + §11 + §12 = 13 sections).

**One inconsistency.** §0 says "12 sections" implicitly via the
disposition table (§1 through §10 are the items + §0 + §11 = 12),
but the addendum has §12 final-line marker. So 13 sections total.
The §0 disposition table maps Items 1-10 to addendum §1-§10; §11
is cascade audit; §12 is final-line marker. The structure is
coherent; the "12 sections" framing in §0 (if you read it as "10
items + intro + cascade audit") doesn't include §12. NIT.

### §11.6 — Cross-reference integrity within addendum: PASS

Spot-checked:
- §3 references §10 (paths in mode-aware bullet text "use the
  post-Item-10 non-dot form per §10 below") — §10 carries the
  decision. Sound.
- §6 references §1 Layer 1 ("trinity Key files line addition × 6
  files per Item 1 Layer 1") — §1 covers Layer 1. Sound.
- §6 references §3 (PACK-AGENTS.md edit per Item 3 honest framing)
  — §3 covers the framing. Sound.
- §5 references §4 (Layer 0 cross-reference) — §4 §4.5 covers it.
  Sound.
- §11 references §1, §2, §3, §6, §10 — all map back to the right
  sections.

PASS.

### §11.7 — Reviewer Goal 1/2/3 advancement: PASS

**Goal 1 (discoverability).** Item 1 advances Goal 1 cleanly:
trinity Key files (Layer 1) + body-field back-pointer (Layer 2,
modulo SHOULD-FIX) + pack-startup/pm-startup directives (Layer 3)
+ pack-* agent prompts (Layer 4, modulo BLOCKER on Codex extensions).
Item 10 also advances Goal 1 (non-dot paths visible by default).

**Goal 2 (single source of truth).** Items 3 + 5 both advance Goal 2:
mode-aware language clarifies SoT in both modes; layered defense
protects against mirror divergence.

**Goal 3 (read/write rules unchanged).** Items 1 (Layer 4 sub-agent
context) + 3 (PACK-AGENTS.md PM-only directories list) explicitly
preserve Goal 3 by extending the protected surface to cover the
new write surface.

PASS.

### §11.8 — Process safeguards: PASS

**Verify-by-grep:** §2.1 explicitly names the grep used and quotes
the result. PASS.

**Fact-check sweep:** §7.2 names ~30 files verified; the new pack-
startup finding is the sweep's output. PASS.

**Honest framing:** §3.1 (Signal 9), §5.1 (mirror divergence as
new failure mode), §10.5 (NIT sizing rationale) all use honest
framing. No "refactor not expansion" or similar reframing-to-avoid-
trip language survives. PASS.

---

## §12 — Recommendation

**NEEDS-ANOTHER-ITERATION.**

**Blockers (must fix before primary-chat planner spawn):**
1. **Codex `.toml` agent-file extensions.** §1.4, §6.2 BD-167b, §6.5
   row 3, §11.1 §18.2 row all enumerate `.codex/agents/pack-<name>.md`
   — the actual files are `.toml`. Five files affected per CLI.
   Cascade through three sections. Coder cannot apply as written.

**SHOULD-FIX (strong preference for fix in this iteration; could
defer to planner with explicit handoff):**
2. **Body-field back-pointer sidecar tension.** §1.2 claim of "byte-
   additive on the v10 entry grammar (V3.1-DELTA §3 A2 invariant
   preserved)" is at tension with sidecar's stricter span-identity
   reading. Either reframe honestly as a contract loosening with
   defense, or pick a back-pointer position that preserves span-
   identity, or drop the upgrade and accept the offset-read
   limitation.
3. **EXECUTION-PLAN line 282 totals math garble.** §2.4 row 4 is
   internally inconsistent and abdicates the math to Pack Chat. The
   architect-pass output should provide the correct line.
4. **Non-interactive migrator silent-overwrite gap.** §5.3 + §4.5
   defense-in-depth chain has a logical hole at the migrator's
   non-interactive path; should bridge to BD-095's `--dry-run`/
   `--apply` discipline.

**MINOR / NIT (planner can absorb):**
5. **PACK-CHAT.md row exact spec missing.** §6.3 should include the
   actual row text or explicit deferral.
6. **Auditor `.codex/agents/auditor.toml` extension imprecision.**
   §6.3 says "auditor agent file extensions × 3 CLIs" without per-
   CLI extension naming.
7. **Layer 2 mirror-strip vs decompose-re-insert clarification.**
   §1.2 says "the next regeneration restores it" but the strip is
   on emit-to-mirror, not write-back-to-per-entry-file.
8. **Layer 1 mirror preamble warning text imprecision.** §5.2 sample
   text says "re-run the mirror regenerator" without specifying the
   helper script path or `pack` verb.
9. **Cascade audit §3.2 cross-reference omission.** §11.1 marks
   §3.2 unchanged but Item 7 borrows its acknowledgement pattern.
10. **§0 "12 sections" framing.** Addendum has 13 sections total
    (including §12 final-line marker); §0 implicitly says 12.
11. **§0 BD count framing.** "9 new BDs" vs §6.4's enumeration
    needs disambiguation (the math is right; the framing is
    confusing).
12. **Cascade audit §10.3 minor omission.** §4.3 recovery scenarios
    table has indirect reference via Layer 2 row but is not in the
    enumeration. Cosmetic.

**Strengths to acknowledge:**
- Items 2, 3, 7, 8 are addressed cleanly and rigorously.
- The honest framing in §3.1 (Signal 9) and §5.1 (new failure mode)
  is exactly what the prior review asked for.
- The fact-check sweep in §7.2 surfaces a real second-order
  inaccuracy and corrects it.
- The leading-dot REDESIGN-CORE #2 is well-defended and the §16.3
  NEW entry follows the §16.1 precedent.
- The architect-pass discipline (no edits to PM-only / pack-product
  / sidecar / original) is preserved throughout.
- The cascade audit (§11.1) is substantively complete with one
  minor omission.

**Why NOT NEEDS-REWORK.** The architectural substance of the
addendum is sound. The 10 items are correctly identified, correctly
prioritized, and substantively addressed. The blocker is a factual
mistake about file extensions, not a design failure. The SHOULD-FIX
items are bounded clarifications, not redesigns.

**Why NOT APPROVE-WITH-MINOR-FOLLOWUPS.** The Codex `.toml` extension
error is load-bearing (the spec drives PM-only file edits the
planner / Pack Chat will execute mechanically). Letting it through
to the planner means either (a) the planner catches it and bounces
back to architect, or (b) the planner doesn't catch it and Pack
Chat applies the wrong-extension edits. Either way, surfacing the
error now is cheaper.

Estimated time-to-fix: 15-30 minutes for the BLOCKER (extension
correction in three places); 30-60 minutes for the four SHOULD-FIX
items combined.

---

## §13 — Final-line marker

REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-COMPLETE:
2026-05-14 — Recommendation: NEEDS-ANOTHER-ITERATION. ONE BLOCKER
(Codex `.toml` agent file extensions; addendum §1.4 + §6.2 BD-167b
+ §6.5 row 3 enumerate `.codex/agents/pack-<name>.md` but actual
files are `.toml`; five Codex files affected; Markdown/TOML edit
shape difference also implicit). FOUR SHOULD-FIX (body-field back-
pointer §1.2 byte-additive claim at tension with sidecar's stricter
span-identity reading; EXECUTION-PLAN line 282 totals math garbled
and abdicated to Pack Chat; non-interactive migrator silent-
overwrite gap in §5.3/§4.5 defense-in-depth chain; PACK-CHAT.md row
exact spec missing in §6.3). EIGHT MINOR / NIT (auditor `.codex`
extension imprecision; Layer 2 mirror-strip vs decompose clarif;
Layer 1 mirror preamble warning text; §11.1 §3.2 cross-ref omission;
§0 "12 sections" framing; §0 "9 new BDs" framing; §10.3 §4.3
omission; one carry-through). ITEMS PASSING CLEANLY: Item 2 (batch
positioning BLOCKER resolved with renumber cascade complete; only
the line 282 garble is residual SHOULD-FIX); Item 3 (Signal 9
honest framing; mode-aware language throughout; CLAUDE.md pack-
memory bullet correction); Item 7 (audit-methodology fact-check;
new pack-startup pack-repo-only discovery surfaced and verified;
sweep documented); Item 8 (constants 10ms→2ms; table recomputed
consistently; speedup ratio preserved); Item 9 (qualifiers
consistent; pseudo-code disclaimers explicit); Item 10 (leading-
dot drop sound; §16.3 NEW REDESIGN-CORE entry parallels §16.1; 30+
sub-section cascade enumeration substantively complete with one
minor omission). ITEMS WITH BLOCKER OR SHOULD-FIX: Item 1 (Layers
1-3 PASS; Layer 4 BLOCKER on Codex `.toml`; Layer 2 SHOULD-FIX on
sidecar tension); Item 4 (six-scenario expansion + defense-in-depth
sound; SHOULD-FIX on non-interactive migrator gap); Item 5 (five-
layer defense well-specified; same SHOULD-FIX gap as Item 4); Item
6 (split clean; carries Codex BLOCKER from §1.4; PACK-CHAT.md row
spec SHOULD-FIX). ARCHITECT-PASS DISCIPLINE PRESERVED (no edits to
PM-only / pack-product / sidecar / original integration architect
doc; PM-only edits surfaced as edit specifications). REVIEWER GOAL
1/2/3 ADVANCEMENT VERIFIED (Item 1 + Item 10 advance Goal 1; Items
3 + 5 advance Goal 2; Items 1 + 3 preserve Goal 3). PROCESS
SAFEGUARDS APPLIED (verify-by-grep in §2.1; fact-check sweep in
§7.2; honest framing in §3.1 / §5.1 / §10.5). Estimated 45-90
minutes total architect-pass to address blockers + SHOULD-FIX;
NEEDS-ANOTHER-ITERATION before primary-chat planner spawn.
