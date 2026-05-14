---
title: REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM
reviewer: primary-chat (v11-dev) — pack-architect, second-pass review
target: maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md (1,101 lines, dated 2026-05-13)
parent-target: maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (1,649 lines)
prior-review: maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md
date: 2026-05-13
recommendation: APPROVE-FOR-PRIMARY-CHAT-ARCHITECT-INTEGRATION (see §8)
---

# Review of ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md

## §0 — TL;DR

The addendum is **substantive, disciplined, and closes the brief
cleanly**. All four corrections (Sections 1–4) are delivered at the
right scope, all 15 required identify-only items (§5.a–§5.o) are
present, and the three architect-added items (§5.p / §5.q / §5.r) are
real concerns surfaced at the right time, properly framed
"OWNED BY: primary chat v11-dev architect / planner pass" with no
solution language.

The addendum also closes prior-review **Gaps A, B, and C** — the
mirror generator / `_rules.md` / regenerator-call-site / supporting-
file-convention questions raised in REVIEW-ARCHITECTURE-PER-ENTRY-
SPLIT.md §5.8 are answered partly by Section 3 (sixth `_rules.md`
contract item; supporting-file basenames) and partly by deferral to
§5.b / §5.c (regenerator call site). Gap A is partly closed, partly
re-deferred (correctly — the runtime semantics of `_rules.md` is
still implementation territory and §5.a names it explicitly).

**Three minor frictions** rise above noise:

1. **§1.3 hook-sequencing decision is design beyond what was asked.**
   The addendum picks "decompose runs sixth and last in the v10→v11
   post-dispatch hook." This is a sound choice and well rationalized,
   but it crosses the architect/planner line — the prior design's
   §15.1 explicitly framed BD-104 sequencing as planner-owned. The
   addendum hard-orders the entire hook sequence (six sub-operations
   numbered 1–6). This is a defensible architect-pass call IF the
   architect owns the hook sequence; less defensible if the planner
   does. Pack Chat may want to ratify the boundary.

2. **One small factual citation slip in §5.r** (`migrator-core.sh:146`
   should be `migrator-stages.sh:146` — `_stage_backup` is defined in
   `migrator-stages.sh`, not `migrator-core.sh`). Trivial fix.

3. **Section 3 closes Gap C but introduces a new file class
   (`_intro.md`) without surfacing the cascade question** the prior
   review §5.8 Gap C named: should `_rules.md`'s filename regex
   *enumerate* supporting basenames, or should it have a separate
   "supporting files admitted" list? The addendum picks the second
   (sixth contract item, §3.3 — basename list, not regex). That is
   the right call. Worth noting that this answers Gap C cleanly.

**Architect-overreach scan: zero overreach.** No PM-only file edits;
no v10 grammar changes. Strong discipline maintained.

**Internal consistency cascade:** the Q1 reversal (§2) and v11.0
lock-in (§1) cascade through the parent doc cleanly. §2.6 explicitly
enumerates parent §3.4 / §5.1 / §11.1 / §11.2 corrections. §1.3
explicitly addresses the §15.1 BD-104 sequencing collision. §1.4
explicitly addresses the §17 final-line marker. No cascade gaps
detected.

**Recommendation:** **APPROVE-FOR-PRIMARY-CHAT-ARCHITECT-INTEGRATION.**
The addendum + parent doc together form a complete design that
primary chat's own architect can integrate into the v11.0
implementation plan. The three frictions above can be resolved by
primary chat directly without another addendum iteration.

---

## §1 — Closure check on Sections 1–5

### §1.1 — Section 1 (version-target lock)

The Pack Chat brief required three properties: (a) MANDATORY for
every v10.1 client, (b) NON-REVERSIBLE, (c) v11.0 lock-in throughout
with §15.3 + §17 reversed.

| Required | Addendum location | Status |
|---|---|---|
| Mandatory for every v10.1 client, no opt-out | §1.1 property 1 (lines 40–44) | CLOSED |
| Non-reversible (per-entry tree = source of truth, no revert) | §1.1 property 2 (lines 45–50) | CLOSED |
| v11.0 lock-in throughout — remove "v11.x" / "planner picks" / placeholder language | §1.1 property 3 (lines 51–54) + §1.2 reversal of §15.3 (lines 64–84) + §1.4 §17 marker correction (lines 143–153) | CLOSED |
| Explicit reversal of parent §15.3 | §1.2 (lines 64–84) — verbatim quote of parent §15.3 followed by replacement text | CLOSED |
| Explicit correction of parent §17 final-line marker | §1.4 (lines 143–153) — names the "version-target placeholder" clause as superseded; provides the authoritative replacement state in prose | CLOSED |
| Reasoning that ties to existing migrator infrastructure | §1.3 (lines 86–141) — verifies the v10→v11 adapter hook structure and slots decomposition as the 6th sub-operation | CLOSED-WITH-OVERREACH (see §3 below) |

**Section 1 closure: CLOSED.** All required items addressed. The §1.3
hook-sequencing detail goes beyond what was strictly asked (Pack Chat
asked for v11.0 lock-in, not for a hard-ordered hook sequence) — this
is flagged in §3 below as design-beyond-brief.

### §1.2 — Section 2 (phase decomposition reversal)

The Pack Chat brief required: (a) one file per phase, tasks inline;
(b) NO `phase-N.M.md` files; (c) reasoning (discoverability,
brittleness, flat files ≠ issue tracker); (d) V3.3-DELTA §6.4
identifiers preserved via `<!-- pack-id: phase-N.M -->` body markers
within phase file.

| Required | Addendum location | Status |
|---|---|---|
| One file per phase | §2.1 DECISION (lines 168–177); §2.3 filename convention (lines 224–229) | CLOSED |
| Phase file contains epic + all tasks inline | §2.1 (lines 173–177) — explicit H2/H3 layout enumeration | CLOSED |
| NO `phase-N.M.md` files | §2.1 last bullet (line 178); §2.3 (line 226) "No `phase-N.M.md` files" | CLOSED |
| Reasoning: discoverability | §2.2 point 1 (lines 190–197) with file-count math (~140 vs ~28) | CLOSED |
| Reasoning: brittleness reduction | §2.2 point 2 (lines 198–201) | CLOSED |
| Reasoning: flat files are not an issue tracker | §2.2 point 3 (lines 202–207) | CLOSED |
| V3.3-DELTA §6.4 identifiers preserved via body markers | §2.2 point 4 (lines 208–215) — `<!-- pack-id: phase-N.M -->` body marker lives inside phase file alongside H4 task heading | CLOSED |
| Cascading corrections to parent §3.4 / §5.1 / §11.1 / §11.2 | §2.6 (lines 279–318) — explicit enumeration of each parent section's needed correction | CLOSED |
| Forward-parser implications addressed | §2.4 (lines 230–257) — parser unchanged because mirror is byte-identical to v10 | CLOSED |
| Reverse-emitter implications addressed | §2.5 (lines 259–277) — reverse-emit produces monolithic mirror, post-emit decompose splits to per-phase files | CLOSED |

**Section 2 closure: CLOSED.** Excellent coverage. The cascading-
corrections enumeration in §2.6 is exactly what the brief implied
the addendum should do; the architect performed it explicitly so the
planner doesn't have to re-derive it.

### §1.3 — Section 3 (one-entry-per-file rule + supporting-file exceptions + explanatory text home)

The Pack Chat brief required: (a) operationalize the rule per stream;
(b) acknowledge supporting-file exceptions; (c) add a sixth `_rules.md`
contract item enumerating supporting-file basenames; (d) resolve
explanatory text home (Pack Chat Q2 — preamble + "How to use this
file" need a named storage location; pick one of three options).

| Required | Addendum location | Status |
|---|---|---|
| Operationalize per stream (define "entry" per stream) | §3.1 table (lines 329–335) — 5-row stream/entry-unit/filename-pattern table | CLOSED |
| Confirmation of pack-changelog version-block-not-scope-bucket | §3.1 confirmation paragraph (lines 337–347) | CLOSED |
| Acknowledge supporting-file exceptions | §3.2 table (lines 355–361) — per-stream supporting-file admittance | CLOSED |
| Sixth `_rules.md` contract item enumerating supporting-file basenames | §3.3 (lines 376–392) — explicit "Supporting-file basenames admitted in this directory" item with separation-from-entry-regex semantics | CLOSED |
| Explanatory text home — Pack Chat Q2 — pick one of three options | §3.4 (lines 394–462) — picks option (b): per-stream `_intro.md` | CLOSED |
| Reasoning for the choice | §3.4 rationale block (lines 404–417) — addresses why not (a) [keeps `_rules.md` short] and not (c) [different streams have different intros] | CLOSED |
| `_intro.md` contents per stream specified | §3.4 (lines 419–450) — per-stream contents enumeration with file:line citations | CLOSED |
| Mirror generator behavior with `_intro.md` | §3.4 (lines 452–462) — read verbatim, emit at top, BD-088 customization-preserve handles drift, missing-file degraded default | CLOSED |
| `_v8-resolved-archive.md` clarification (vs `_intro.md`) | §3.5 (lines 464–486) — disambiguation: `_intro.md` = preamble + how-to-use; `_v8-resolved-archive.md` = mid-file historical block | CLOSED |
| Generator concatenation order | §3.6 (lines 488–502) — explicit order: `_intro.md` → entries → `_v8-resolved-archive.md`; `_toc.md` excludes supporting files | CLOSED |

**Section 3 closure: CLOSED.** The most thorough section in the
addendum — every Pack Chat sub-question explicitly answered. The
introduction of `_intro.md` as a new supporting-file class is
defended cleanly and respects the architect/planner line (mirror
generator's read behavior is named; the runtime trigger for the
generator is not — that is correctly deferred to §5.b/§5.c).

### §1.4 — Section 4 (bidirectional flat ↔ tracker for multi-entity files)

The Pack Chat brief required: (a) per-entry-split migration is
one-way; (b) flat ↔ tracker is bidirectional per V1 §6.3; (c) phase
file maps to multiple tracker issues (epic + N tasks); (d) design
forward (1 file → N issues, recorded in id-map.json), reverse (N
issues → 1 file byte-identical), round-trip byte-identity as
verification probe; (e) identify which tracker functions need
extension (don't fix; name them).

| Required | Addendum location | Status |
|---|---|---|
| Confirm per-entry-split is one-way | §4.1 (lines 510–514) — references §1 of addendum; bidirectionality scope narrowed to flat ↔ tracker boundary only | CLOSED |
| Flat ↔ tracker bidirectional per V1 §6.3 | §4.1 (lines 512–514) cites V1 §6.3 + parent §6.1 + §8.1 | CLOSED |
| Phase file ↔ epic + N task issues | §4.1 (lines 516–528) — explicit 1-to-N mapping framing with V3.3-DELTA §6.3 + §6.4 citations | CLOSED |
| Other multi-entity cases verified or excluded | §4.1 (lines 530–550) — explicit verification: pack-changelog scope buckets are multi-bucket but NOT multi-entity from tracker's perspective; all other streams 1-to-1 | CLOSED |
| Forward contract (flat → tracker, 1-to-N-aware id-map) | §4.2 (lines 552–585) — 5-step forward emission spec; id-map 1-to-N-aware noted | CLOSED |
| Reverse contract (tracker → 1 file byte-identical) | §4.3 (lines 587–610) — 5-step reverse spec; round-trip verification step explicit | CLOSED |
| Round-trip byte-identity verification | §4.4 (lines 612–637) — two round trips composed; harness extension named | CLOSED |
| Existing tracker functions to extend (identify-only) | §4.5 (lines 639–678) — names `tmf_parse_implementation_plan` (line 399), `tmf_compose_issue_body` (line 459), downstream forward emitters, `_tmr_emit_implementation_plan` (line 485), id-map schema | CLOSED |
| Scope-bucket sub-units clarification | §4.6 (lines 680–700) — explicit: pack-changelog scope buckets are NOT multi-entity from tracker's perspective; 1-to-N scope is project `implementation-plan/` only | CLOSED |

**Section 4 closure: CLOSED.** The scope-narrowing finding (§4.1 + §4.6
— 1-to-N applies to project `implementation-plan/` only) is the
single most useful piece of Section 4. It eliminates a hypothetical
contract-extension burden the brief left open. Strong delivery.

### §1.5 — Section 5 (identify-only inventory)

The Pack Chat brief listed 15 required items (a)–(o). Walking each:

| Required item | Addendum location | Status |
|---|---|---|
| (a) Workflow discovery of `_rules.md` | §5.a (lines 711–725) | CLOSED |
| (b) `_toc.md` runtime invocation | §5.b (lines 727–738) | CLOSED |
| (c) Mirror generator runtime invocation | §5.c (lines 740–754) | CLOSED |
| (d) Stale-mirror / stale-TOC detection | §5.d (lines 756–770) | CLOSED |
| (e) Concurrent-write safety | §5.e (lines 772–784) | CLOSED |
| (f) Cross-reference integrity | §5.f (lines 786–799) | CLOSED |
| (g) Test fixture migration | §5.g (lines 801–815) | CLOSED |
| (h) Validator new-checks | §5.h (lines 817–842) | CLOSED |
| (i) Read-site audit completeness | §5.i (lines 844–880) | CLOSED |
| (j) Skill update inventory | §5.j (lines 882–904) | CLOSED |
| (k) STATUS.md interaction | §5.k (lines 906–927) | CLOSED |
| (l) Pattern B archive sweep impact | §5.l (lines 929–952) | CLOSED |
| (m) Customization-preserve at per-entry verification | §5.m (lines 954–979) | CLOSED |
| (n) BD-161 absorption | §5.n (lines 981–1008) | CLOSED |
| (o) Diffability / git history tradeoff | §5.o (lines 1010–1027) | CLOSED |

**Section 5 closure: CLOSED.** All 15 required items present with
file:line citations and "OWNED BY: primary chat v11-dev architect /
planner pass" markers.

Each item is in the 2–4-sentence range the brief requested. Each
properly describes-not-solves. §5.h's candidate validator-check list
is the densest item; the framing "Likely candidates for new
`check_*` functions … this design defers all of them per parent
§13.1" is correctly identify-only — naming candidates is description,
not design proposal.


---

## §2 — Architect-added Section 5 items (§5.p / §5.q / §5.r) evaluation

The Pack Chat brief explicitly invited the architect to add OTHER
concerns surfaced during the write, with the same identify-only shape
("OWNED BY:" + describe, don't solve). The architect added three:

### §2.1 — §5.p (`.pack-tracker/` vs `/.backlog/` namespace collision risk)

**Real concern?** YES. The `/.backlog/` and `/.changelog/` pack-root
directories are introduced by this design (parent §3.1 + §3.2). They
sit alongside the existing `.pack-tracker/` (per V3 §28.1.4). The
question of whether *presence-of-`/.backlog/`* should be an implicit
v11.0+ flag (vs `tracker.toml` template_version, vs README version
table) is a real signal-detection question that affects
`scripts/lib/detect.sh`, `tracker-config.sh`, and `recommendation.sh`.

**Properly framed as identify-only?** YES. The architect names the
question ("whether any existing detection code … needs to know about
`/.backlog/` presence as a v11.0+ flag, or whether the
`template_version` mechanism … and the README version table are
sufficient version signals") without proposing the answer. OWNED-BY
marker present.

**Status: VALID ADDITION.** This concern was not in the original
brief and should have been; the architect surfacing it is exactly
what "add OTHER concerns" was meant to catch.

### §2.2 — §5.q (init-project.sh greenfield path)

**Real concern?** YES. The non-reversible v11.0 lock-in (Section 1)
implies that net-new projects initialized via `scripts/init-project.sh`
receive the per-entry tree directly, not the monolithic file. This
is not addressed by the v10→v11 migrator (which handles existing
clients). The greenfield path is a separate code path
(`init-project.sh stage_s11_v11_artifacts()` per BD-116/BD-161
resolution prose at pack `BACKLOG.md:1157` — verified) that needs
its own per-entry-tree install logic.

**Properly framed as identify-only?** YES. The architect names the
question ("whether `init-project.sh` needs a new stage or whether the
existing stage-S11 absorbs the per-entry-tree install") without
proposing which. The parallel concern about pack-self-side init
(pack repo's `/.backlog/` is created by the pack-self v10.1→v11.0
migration, not by `init-project.sh`) is correctly named.
OWNED-BY marker present.

**Status: VALID ADDITION.** This is a critical gap that the original
brief missed entirely. Without it, the planner could ship the v11.0
migrator + per-entry tree decomposition but leave new projects with
no init path. Strong catch.

### §2.3 — §5.r (backup and rollback under non-reversible migration)

**Real concern?** YES. Section 1's non-reversible lock makes the
existing `_stage_backup` step the only path back to monolithic-as-
source state for a user who wants to disown v11.0 after migration.
The question of whether the existing backup contract is sufficient
under decomposition (restore must restore the monolithic file AND
remove the per-entry tree to avoid stale dual-state) is a real
backup-semantics question. The companion question (whether
post-report-hook advisory text needs to mention backup as the
rollback path) is also real.

**Properly framed as identify-only?** YES. The architect names both
questions without proposing answers. OWNED-BY marker present.

**Status: VALID ADDITION.** Closely tied to Section 1's lock — if
non-reversibility is the contract, the rollback story matters more,
not less. The architect correctly notices that and surfaces it.

**Citation slip:** §5.r cites `scripts/lib/migrator-core.sh:146` for
`_stage_backup`. **Verified incorrect:** `_stage_backup()` is defined
at `scripts/lib/migrator-stages.sh:146`, not `migrator-core.sh:146`.
The line number is right; the file is wrong. Trivial fix; flagged
in §5 of this review as one of three minor frictions.

### §2.4 — Summary of three additions

All three are real concerns, all three are properly framed identify-
only, all three carry OWNED-BY markers. Combined with the 15 required
items, the addendum's §5 inventory has 18 items total (a–r) — exactly
the count the brief states ("18 items (a-r)").

**Net:** the architect's three additions are a strength of the
addendum, not scope drift. They surface gaps the original brief
missed, particularly §5.q (greenfield init path) which is a
load-bearing planner concern.

---

## §3 — Internal consistency: does the cascade close?

Section 1 (v11.0 lock-in) reverses parent §15.3 + §17. Section 2
(one-file-per-phase) reverses parent §3.4. Both changes have
downstream effects on the rest of the parent doc. The question is
whether the addendum addresses the cascade or just declares the
change.

### §3.1 — Section 1 cascade

| Cascade target | Addendum coverage | Status |
|---|---|---|
| Parent §15.3 ("v11.x feature, not v11.0") | §1.2 — verbatim quote + replacement text | CLOSED |
| Parent §17 final-line marker ("version-target placeholder") | §1.4 — explicit correction in prose, leaves parent §17 unedited per architect-prompt rules | CLOSED |
| Parent §10 (BD-119 hook integration) — was generically "v11.0 → v11.x migrator"; now must be "v10.1 → v11.0 migrator" | §1.3 — explicit refinement to the v10→v11 adapter; six-sub-operation hook sequence with decompose as 6th-and-last | CLOSED |
| Parent §15.1 (BD-104 sequencing) — was "either order is correct"; now both run in same migrator hook | §1.3 (lines 110–115) — sequencing inside the hook puts BD-104 rename first so decompose reads the hyphenated name; explicitly "resolves parent §15.1's BD-104 sequencing constraint within the hook itself" | CLOSED |
| Parent §15.2 (BD-131..BD-134 sequencing) — hard constraint AFTER tracker repairs | §1.2 (lines 81–84) — "Parent §15.2 (sequencing relative to Batches 7–10 — hard constraint AFTER) still applies" | CLOSED (preserved) |
| Parent §13.4 (signal 8 advisory text) | §1.3 (lines 137–141) — "Maintainability signal 8 ... is the same conditionally-tripped status as parent §13.4 — the post-report-hook advisory text needs one new paragraph" | CLOSED (preserved) |

**Section 1 cascade: CLOSED.** The addendum addresses every
downstream effect. §1.3's hook-sequencing decision additionally
**resolves** §15.1's BD-104 sequencing question (which was previously
flagged-not-resolved per the prior-review guard rail 6) — see §3 of
this review for the "design beyond brief" flag on this.

### §3.2 — Section 2 cascade

| Cascade target | Addendum coverage | Status |
|---|---|---|
| Parent §3.4 (phase-N + phase-N.M file design) | §2.1 + §2.6 (lines 281–290) — explicit reversal; phase-task sub-paragraph collapsed; `### Tasks` H3 retains inline content (no longer "becomes an index") | CLOSED |
| Parent §5.1 (`_toc.md` schema for project-implementation-plan) | §2.6 (lines 292–306) — corrected: each phase file listed once; phase tasks NOT separately indexed | CLOSED |
| Parent §11.1 (asymmetry table row "Project-side decomposes by phase + phase task") | §2.6 (lines 308–311) — corrected to "decomposes by phase only; phase tasks remain inline" | CLOSED |
| Parent §11.2 (surface-count table row "Yes (phase-N + phase-N.M)") | §2.6 (lines 313–315) — corrected to "Yes (phase-N only; phase tasks inline)" | CLOSED |
| Parent §6.2 (mirror generator must split mirror back to per-entry — affected by phase shape change) | §2.5 (lines 259–277) — reverse-emit produces mirror, post-emit decompose splits per `## Phase NN` H2 blocks (one block per file) | CLOSED |
| Forward parser (V3.3-DELTA §4.1 contract) | §2.4 (lines 230–257) — parser unchanged because mirror is byte-identical to v10 | CLOSED |
| Tracker 1-to-N contract (Section 4 dependency) | Section 4 §4.1 — phase file ↔ epic + N tasks; explicit composition with §2 decomposition | CLOSED |

**Section 2 cascade: CLOSED.** The addendum's §2.6 is a model of
explicit cascade enumeration. Every parent-section reference that
needs correcting is named with line numbers, the old text quoted, and
the new text given.

### §3.3 — Cross-section internal consistency

The addendum has one cross-section consistency check the architect
must implicitly satisfy: §1 (one-way migration) and §4 (bidirectional
flat ↔ tracker) must coexist. They do — §4.1 explicitly narrows
bidirectionality to the flat ↔ tracker boundary (per V1 §6.3) and
preserves §1's one-way scope for the per-entry-split migration.
This is named in addendum lines 56–62 ("Contrast with tracker mode …
Per-entry decomposition is specifically NOT bidirectional with respect
to the monolithic-as-source past state. The bidirectionality that
remains is the flat-file ↔ tracker boundary"). Clean.

§3 (`_intro.md`) and §4 (1-to-N tracker mapping) interact only
through the round-trip byte-identity contract (§4.4) — which must
hold for `_intro.md` content too. The addendum implies but does not
state that `_intro.md` content survives the flat ↔ tracker round trip
(forward emission discards `_intro.md` since the tracker has no
analog; reverse emission must re-introduce `_intro.md` from the
client's existing file or from a degraded default). This is a minor
implicit consistency check the planner should verify; the architect
could have surfaced it in §4.4 explicitly. Minor.

---

## §4 — Scope-creep / focus-drift audit

The addendum was scoped as: corrections (Sections 1–4) + identify-
only inventory (Section 5). Audit walks each section for content
that proposes design beyond what was asked or strays into solving
identify-only items.

### §4.1 — Section 1 audit

§1.1 + §1.2 + §1.4 are pure correction-of-parent — no design beyond
brief. CLEAN.

**§1.3 contains design-beyond-brief.** The Pack Chat brief asked for
v11.0 lock-in; it did not ask for the architect to hard-order the
six sub-operations of the v10→v11 adapter's post-dispatch hook. The
addendum picks an explicit numbered sequence (1: BD-104 rename;
2: BD-042 relocate; 3: artifact installs; 4: python rename; 5:
capability translation; 6: NEW decompose). The first five are
already in production at `scripts/migrate-v10-to-v11.sh:144-148` in
exactly the order the addendum names — verified. The 6th is the
new addition. The architect's argument for "sixth and last" (line
124–134: decompose reads the final v11-translated text byte-for-byte)
is sound.

**Is this overreach?** Borderline. The architect-pass owns the design
of how the new operation slots into the existing hook; the planner-
pass owns the actual implementation including ordering decisions. The
addendum's choice is *defensible* as architect-pass scope (it's a
design-level "this must run last because it must read the final
text" constraint, not a planner-level implementation detail). It is
*also* defensible as planner-pass scope (the constraint could be
stated as a constraint without picking the position). The addendum
picks the position. This is mild scope-creep; not blocking, but
worth Pack Chat ratifying the architect/planner boundary on
sequence-within-hook.

**Recommendation:** Pack Chat may want to either (a) accept the
addendum's hard-ordering as final architect-pass output (and remove
sequence-within-hook from the planner's open scope), or (b) downgrade
the addendum's §1.3 numbered sequence to a constraint statement
("decompose must run after all monolithic-content mutations") and
let the planner choose position. Either is fine; the addendum's
choice is sound either way.

### §4.2 — Section 2 audit

§2.1 + §2.2 + §2.3 are pure decision + reasoning per Pack Chat brief.
CLEAN.

§2.4 + §2.5 (forward-parser and reverse-emitter implications) are
required by the brief implicitly (the brief's "design forward …
reverse … byte-identical" framing in Section 4 implies that Section
2's phase shape change has parser/emitter cascade). The architect
addresses the cascade in §2.4 + §2.5 by saying "parser unchanged
because mirror is byte-identical to v10" — which is the right
not-design answer. CLEAN.

§2.6 is the cascading-corrections enumeration — explicitly required
by Pack Chat brief Section 2 ("REVERSES original OQ-1"). CLEAN.

### §4.3 — Section 3 audit

§3.1 (per-stream operationalization) — directly required. CLEAN.

§3.2 (supporting-file table) — directly required. CLEAN.

§3.3 (sixth `_rules.md` contract item) — directly required. CLEAN.

§3.4 (`_intro.md` decision) — directly required (Pack Chat Q2: pick
one of three options). The architect picks option (b) and rationalizes.
The contents-per-stream enumeration (lines 419–450) and the
mirror-generator-behavior block (lines 452–462) go slightly beyond
"pick one of three options" — they specify *what `_intro.md`
contains* per stream and *how the generator handles it*. This is
arguably design-beyond-brief.

**However:** the brief's framing ("explanatory text homes ... need a
named storage location; pick one of three options") implicitly
requires the architect to *make the choice complete* — without
specifying contents-per-stream and generator-behavior, the choice is
not actionable. The architect's expansion is a natural completion of
the choice, not scope-creep. CLEAN.

§3.5 (`_v8-resolved-archive.md` clarification vs `_intro.md`) — not
explicitly required, but necessary because the addendum introduces
`_intro.md` and parent §6.2 already established `_v8-resolved-
archive.md`; without disambiguation, the planner could conflate them.
Defensible micro-addition. CLEAN.

§3.6 (generator concatenation order) — also not explicitly required,
but follows from §3.4 + §3.5. The order matters for round-trip byte-
identity. Defensible micro-addition. CLEAN.

### §4.4 — Section 4 audit

§4.1 (problem statement + scope-narrowing to project
`implementation-plan/` only) — directly required. CLEAN.

§4.2 (forward contract) — directly required. The 5-step spec is
specific but correctly stays at design level (issue title format,
body markers, label assignments). CLEAN.

§4.3 (reverse contract) — directly required. Same shape. CLEAN.

§4.4 (round-trip byte-identity) — directly required. CLEAN.

§4.5 (existing tracker functions to extend, identify-only) —
directly required. The architect names functions, cites file:line,
explicitly says "named, not solved" + "Fix-design ownership: primary
chat v11-dev planner pass and the BD-131..BD-134 tracker repair
scope (parent §15.2)." Clean identify-only discipline. CLEAN.

§4.6 (scope-bucket sub-units clarification) — directly required by
brief's "verify and resolve" prompt. The architect verifies (against
existing function inventory) and concludes the contract scope is
project `implementation-plan/` only. CLEAN.

### §4.5 — Section 5 audit

All 15 required items + 3 architect-added items examined in §1.5 +
§2 above. None propose solutions; all carry OWNED-BY markers; all
2–4 sentences with file:line citations. CLEAN.

### §4.6 — Net scope-creep finding

**One mild scope-creep:** §1.3 hard-orders the six sub-operations of
the post-dispatch hook. Pack Chat may ratify or downgrade.

**One naturally-completing micro-additions:** §3.4 contents-per-
stream + generator-behavior expansion makes the `_intro.md` choice
actionable rather than abstract.

**Two defensible micro-additions:** §3.5 (disambiguates
`_intro.md` vs `_v8-resolved-archive.md`) and §3.6 (concatenation
order) — both follow from §3.4 + necessary for round-trip identity.

**No drift into solving identify-only items.** Section 5 stays
strictly identify-only. The candidate-list naming in §5.h
("Mirror-in-sync … TOC-in-sync … `_rules.md` exists … per-entry
filename conformance … cross-reference integrity … `_v8-resolved-
archive.md` byte-stable") is description, not design — naming
candidate validators is part of describing the inventory.

**Net:** the addendum is well within scope. The §1.3 hook-sequencing
decision is the only mild creep and is defensible as architect-pass
scope.


---

## §5 — Factual accuracy spot-check

Sampling addendum claims and verifying against source.

### §5.1 — Sample 1: §1.3 hook sub-operation list at `migrate-v10-to-v11.sh:144-148`

**Addendum claim** (lines 91–99):
> "The adapter's hook currently runs 5 sub-operations at
> `scripts/migrate-v10-to-v11.sh:144-148`:
> ```
> _v10_to_v11_rename_implementation_plan       # BD-104
> _v10_to_v11_relocate_legacy_docs              # BD-042
> _v10_to_v11_install_v11_artifacts             # additive v11 installs
> _v10_to_v11_rename_python_architecture_refs   # BD-144 etc.
> _v10_to_v11_translate_capability_tokens       # BD-144 capability tokens
> ```"

**Verified.** Direct read of `scripts/migrate-v10-to-v11.sh:144-148`
shows exactly these five lines in this exact order. Function names
match verbatim. **PASS.**

### §5.2 — Sample 2: §2.5 reverse-emitter function at `tracker-migrate-reverse.sh:485`

**Addendum claim** (lines 264–266):
> "`_tmr_emit_implementation_plan()` at
> `scripts/lib/tracker-migrate-reverse.sh:485` emits the full
> `IMPLEMENTATION-PLAN.md` skeleton."

**Verified.** `grep -n "^_tmr_emit_implementation_plan"
scripts/lib/tracker-migrate-reverse.sh` returns line 485 exactly.
Function comment at line 484 ("Emit IMPLEMENTATION-PLAN.md skeleton
from phase epic titles. Per V1 §6.5 step 5, skipped if the file
already exists.") confirms the "skeleton" framing. **PASS.**

### §5.3 — Sample 3: §3.4 pack BACKLOG.md preamble at `BACKLOG.md:1-7`

**Addendum claim** (lines 419–429):
> "**pack `backlog/_intro.md`** — captures pack `BACKLOG.md:1-7`
> preamble (`# Backlog` H1 + 'All planned improvements …' + 'Items
> use BD-NNN identifiers …' + 'Format follows the standard BACKLOG
> item format from METHODOLOGY.md Part 7.' reference) and pack
> `BACKLOG.md:9-20` 'How to use this file' H2 block …"

**Verified.** Direct read of `BACKLOG.md:1-7` shows the H1, the
"All planned improvements" line, the "Items use BD-NNN identifiers"
line, and the "Format follows the standard BACKLOG item format from
METHODOLOGY.md Part 7." line at line 5 — exactly as quoted. The
"How to use this file" H2 is at line 9 with the bullet content
through line 20 — verified. **PASS.**

### §5.4 — Sample 4: §4.5 `tmf_compose_issue_body()` at `tracker-migrate-forward.sh:459`

**Addendum claim** (lines 652–658):
> "`tmf_compose_issue_body()` at
> `scripts/lib/tracker-migrate-forward.sh:459` per
> `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 798–800. Today composes a
> single GH issue body for a parsed BACKLOG entry."

**Verified.** `grep -n "^tmf_compose_issue_body"
scripts/lib/tracker-migrate-forward.sh` returns line 459 exactly.
Comment at lines 454–458 confirms "Type: / Status: / Blockers: /
Unblocks: are NOT in the body — they map to labels and link
relationships per V1 §4.1. File/Symbol IS in the body" framing
matches the addendum's description. **PASS.**

### §5.5 — Sample 5: §5.r `_stage_backup` at `migrator-core.sh:146`

**Addendum claim** (lines 1080–1082):
> "The v10→v11 migrator's `_stage_backup` step (per
> `scripts/lib/migrator-core.sh:146` per
> `RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 534–538) creates a backup …"

**FAIL — citation slip.** `_stage_backup()` is defined at
`scripts/lib/migrator-stages.sh:146`, NOT
`scripts/lib/migrator-core.sh:146`. Verified via:
- `grep -n "^_stage_backup()" scripts/lib/migrator-core.sh
  scripts/lib/migrator-stages.sh` returns
  `scripts/lib/migrator-stages.sh:146:_stage_backup() {`
- `migrator-core.sh:214` *invokes* `_stage_backup` from
  `_migrator_run_stages` but does not define it.

The line number (146) is correct; the file is wrong. Trivial fix —
the architect (or planner) can correct in the addendum or the
implementation BD. **CITATION DEFECT, NOT CONTENT DEFECT.**

### §5.6 — Sample 6: §5.n BD-161 description at pack `BACKLOG.md:1388`

**Addendum claim** (lines 983–989):
> "BD-161 (per pack `BACKLOG.md:1388` 'v10→v11 migrator: install
> net-new v11 SKILL.md dirs (BD-156/157/158 + python-server-
> architecture / python-data-architecture split)') was scheduled to
> install net-new v11 SKILL.md directories via the v10→v11
> migrator's existing `migrator_post_dispatch_hook` (per
> `scripts/migrate-v10-to-v11.sh:144-148`)."

**Verified.** `grep -n "BD-161" BACKLOG.md` returns
`1388:**BD-161 — v10→v11 migrator: install net-new v11 SKILL.md
dirs (BD-156/157/158 + python-server-architecture /
python-data-architecture split)**` — exactly as quoted. **PASS.**

### §5.7 — Sample 7: §3.4 pack CHANGELOG preamble at `CHANGELOG.md:1-6`

**Addendum claim** (lines 430–433):
> "**pack `changelog/_intro.md`** — captures pack `CHANGELOG.md:1-6`
> preamble ('All notable changes to the AI Agent Config Pack are
> documented here. Each version is available as a git tag')."

**Verified** (with minor over-specification). Direct read of
`CHANGELOG.md:1-6` shows the H1 ("# Changelog") at line 1, the "All
notable changes" line at line 3, the "Each version is available as
a git tag (v1, v2, …)." line at line 4, and a `---` separator at
line 6. The preamble itself is lines 3–4; the addendum's "1-6"
range is the H1-through-separator block which is what `_intro.md`
would capture. Acceptable. **PASS.**

### §5.8 — Factual accuracy summary

- 6 of 7 spot-checked claims **PASS** verbatim.
- 1 of 7 (Sample 5, §5.r) **FAILS** with a file-name slip
  (`migrator-core.sh:146` should be `migrator-stages.sh:146`). Line
  number is correct; file is wrong. Trivial fix.

**Net:** factual accuracy is high. The one slip is a citation typo,
not a content defect. The addendum's overall citation discipline is
strong (file:line citations on virtually every claim).

---

## §6 — Architect-overreach scan

The original prior-review §5.4 enumerated six overreach signals an
architect could misread as license to expand scope. The addendum is
checked against (a) the same six signals, (b) the cross-cutting
PM-only-files check, and (c) the v10 entry-format grammar check.

### §6.1 — Six §5.4 signals

| Signal | Tested by addendum? | Result |
|---|---|---|
| 1: harmonize Resolved: vs Resolution: field names | Section 3 enumerates supporting files per stream — preserves the existing field-name asymmetry by deferring to parent §11.1's defense | NO OVERREACH |
| 2: redesign 5-state vs 2-state vocabulary | Sections 1–4 do not touch state vocabulary; supporting-file table preserves per-stream lifecycle | NO OVERREACH |
| 3: edit CLAUDE.md to "fix" no-Resolved-section rule | §3.5 preserves `_v8-resolved-archive.md` per parent §6.2; no CLAUDE.md edit proposed | NO OVERREACH |
| 4: add a new BD-119 framework hook | §1.3 explicitly slots into the EXISTING `migrator_post_dispatch_hook` as a 6th sub-operation; no new hook | NO OVERREACH |
| 5: redesign pack-startup / agent-file read flow | §5.j (identify-only) names skill-update inventory as a planner question; no read-flow redesign proposed | NO OVERREACH |
| 6: redesign tracker reverse-emit contract | §4.3 and §4.5 explicitly preserve the existing reverse-emit shape (monolithic mirror) and add a post-emit decompose step; reverse-emit functions named for extension only, not redesigned | NO OVERREACH |

### §6.2 — Cross-cutting PM-only-files scan

Walking the addendum for any "edit X" proposal where X is PM-only:

- BACKLOG.md — referenced for entry-format authority (`BACKLOG.md:1-7`,
  `:9-20`, `:1388`, `:1399`, etc.); no edit proposed.
- CHANGELOG.md — referenced for preamble (`CHANGELOG.md:1-6`); no
  edit proposed.
- README.md — referenced for fixture wiring (`README.md:181`,
  `:230`, `:232`); no edit proposed.
- PACK-CHAT.md / PM-CHAT.md — referenced via parent §14 surfaces;
  no edit proposed.
- PACK-AGENTS.md — not edited; §1.4 explicitly observes "the parent
  doc's §17 line is not edited (architect prompt §0 forbids edits to
  any file other than this addendum)" — same discipline applied
  throughout.
- pack-root + project-template CLAUDE/AGENTS/GEMINI — not edited.
  §5.l mentions `CLAUDE.md:174-183` (the Pattern B sweep rule) as
  identify-only; no edit proposed.
- EXECUTION-PLAN-V11.0.md — not edited.
- v11-research authoritative corpus (V3 / V3.1 / V3.2 / V3.3
  deltas / IMPLEMENTATION-PLAN.md) — referenced extensively; no
  edits proposed.

**Cross-cutting overreach: ZERO.** The addendum holds the line as
cleanly as the parent doc did.

**One subtle observation:** §1.4 explicitly addresses the "parent
doc §17 marker is not edited per architect-prompt rules" question
in prose, naming the addendum as "the authoritative correction the
planner pass reads." This is the right discipline — the addendum
makes itself the read-target without modifying the parent.

### §6.3 — V10 entry-format grammar scan

Walking the addendum for any change to:
- The bold-header line (`**BD-NNN — Title**` / `**TD-NNN — Title**`)
- The field labels (Type, Status, Blockers, Unblocks, File/Symbol,
  Description, Resolved, Context, Resolution)
- The `---` separator
- The cross-reference syntax

**Section 1** does not touch entry format.
**Section 2** preserves the v10 OT phase shape verbatim — the
`#### N.M — <title>` task headings live inside the phase file
unchanged (lines 173–177).
**Section 3** introduces `_intro.md` as a NEW file class, but this
is supporting-file territory (not entry-format territory). The
entry-format grammar inside per-entry files is byte-additive on v10
per parent §0 + §3.x.
**Section 4** preserves the v10 grammar via the byte-identical
mirror contract; tracker round-trips operate on the mirror, so
entry-format invariants are preserved at the mirror boundary.
**Section 5** is identify-only — names questions, doesn't touch
grammar.

**Grammar overreach: ZERO.**

### §6.4 — Net overreach scan

**Zero overreach across all three checks.** The architect-pass
discipline is strong throughout the addendum.

---

## §7 — Effect on prior-review §5.x findings (Gaps A/B/C)

The prior review (REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md §5.8)
identified three gaps:
- Gap A: `_rules.md` runtime semantics — config or documentation?
- Gap B: regenerator call site — who invokes it?
- Gap C: leading-underscore filename convention — generic pattern or
  specific list?

Walking each:

### §7.1 — Gap C — CLOSED by addendum §3.3

**Prior review's framing:** the parent §3.1 example regex
`^BD-\d+\.md$` would reject `_v8-resolved-archive.md` without a
special case. Three options proposed: (a) enumerate supporting
basenames in `_rules.md`, (b) entry-regex OR leading-underscore,
(c) entry-regex; non-matching files ignored as control files.

**Addendum's resolution:** §3.3 picks option (a) explicitly:
"`_rules.md` declares it as a literal basename list, not a regex
(the list is small and stable; regex would over-generalize)." The
sixth `_rules.md` contract item enumerates supporting-file basenames
per stream (table at §3.2). Generators MUST treat the supporting-
file list as distinct from the entry-file regex.

**Status: CLOSED.** Clean resolution. Picks the planner-friendliest
option (small explicit list, no regex grammar to validate).

### §7.2 — Gap A — PARTIALLY CLOSED by addendum §3.3 + §3.4 + §5.a

**Prior review's framing:** does the mirror generator load
`_rules.md` at runtime? If yes, the design needs to say what
happens when client `_rules.md` is internally inconsistent. If no,
`_rules.md` is documentation-only.

**Addendum's resolution:**
- §3.3 implies `_rules.md` is **read at runtime** by generators
  ("Generators (mirror generator + `_toc.md` regenerator) MUST
  treat the supporting-file list as distinct from the entry-file
  regex: supporting files are read for control state").
- §3.4 implies `_intro.md` is **also read at runtime** by the
  mirror generator ("Reads `_intro.md` (if present) and emits its
  content verbatim at the top of the regenerated monolithic file").
- §5.a explicitly identifies "workflow discovery of `_rules.md`" as
  an unsolved planner question — agents and skills do not yet know
  to read `_rules.md` for stream-contract resolution.
- The sub-question "what happens when client `_rules.md` is
  internally inconsistent" is NOT explicitly addressed. The closest
  the addendum gets is §5.a's deferral.

**Status: PARTIALLY CLOSED.** The addendum confirms `_rules.md`
**is** read at runtime (resolves prior review's binary question).
The cascade question "what about internal inconsistency / client
customization conflicts" is correctly deferred to identify-only
items §5.a (workflow discovery) + §5.m (customization-preserve at
per-entry verification). The architect-pass output is sound;
remaining work is planner-pass.

### §7.3 — Gap B — CLOSED-BY-DEFERRAL via addendum §5.b + §5.c

**Prior review's framing:** does Pack Chat / PM Chat after staging
invoke the regenerator? A git pre-commit hook? The agent that wrote
the per-entry file? The migrator at version-bump time?

**Addendum's resolution:** §5.b ("`_toc.md` runtime invocation") and
§5.c ("Mirror generator runtime invocation") explicitly enumerate
three plausible triggers (writer-side hook / pre-commit hook /
migrator-only) and defer the choice to planner-pass. §5.c notes the
choice has user-facing implications and makes migrator-only
"probably unworkable — mentioned for completeness."

**Status: CLOSED-BY-DEFERRAL.** This is the right scope. Picking the
trigger is implementation-decision territory; the architect properly
identifies the question and frames the choice space.

### §7.4 — Net effect on prior review

| Prior gap | Addendum closure | Net |
|---|---|---|
| Gap A (`_rules.md` runtime) | PARTIALLY CLOSED — confirmed read-at-runtime; cascade questions deferred to §5.a + §5.m | Resolved at architect-pass scope |
| Gap B (regenerator call site) | CLOSED-BY-DEFERRAL — three triggers enumerated in §5.b + §5.c | Resolved at architect-pass scope (planner picks) |
| Gap C (filename convention) | CLOSED — option (a), explicit basename list in `_rules.md` per §3.3 | Resolved at architect-pass scope |

**All three prior gaps closed at the appropriate scope.** The
addendum's discipline of "design the architect-pass call, defer the
implementation-pass call to identify-only items" is exactly right.

---

## §8 — Recommendation

**APPROVE-FOR-PRIMARY-CHAT-ARCHITECT-INTEGRATION.**

**Rationale:**

1. **Section 1–5 closure is complete.** Every required item from the
   Pack Chat brief is closed. All 18 identify-only items present.
   Three architect-added items (§5.p / §5.q / §5.r) are real
   concerns properly framed.

2. **Internal consistency cascade is complete.** Section 1 (v11.0
   lock-in) and Section 2 (one-file-per-phase) cascade cleanly
   through parent §3.4 / §5.1 / §10 / §11.1 / §11.2 / §13.4 /
   §15.1 / §15.2 / §17. §2.6 enumerates each cascade explicitly.

3. **Architect-overreach scan is clean.** Zero overreach across the
   six §5.4 signals + cross-cutting PM-only-files + v10 grammar
   checks.

4. **Factual accuracy is high.** 6 of 7 spot-checked claims pass
   verbatim. The one defect (§5.r `_stage_backup` file citation) is
   a typo, not a content error.

5. **Three minor frictions, all resolvable directly by primary chat:**
   - **Friction 1:** §1.3 hard-orders the v10→v11 hook sub-operations
     1–6. This is mild scope-creep into planner territory but
     defensible as architect-pass design. Pack Chat may ratify or
     downgrade to a constraint statement.
   - **Friction 2:** §5.r citation slip (`migrator-core.sh:146` →
     should be `migrator-stages.sh:146`). Trivial fix.
   - **Friction 3:** §3.3 + §4.4 do not state explicitly that
     `_intro.md` content survives the flat ↔ tracker round trip
     (forward emission discards it; reverse must re-introduce from
     client file or degraded default). Implicit consistency check
     for the planner.

6. **Prior review's Gaps A/B/C are closed at appropriate scope.**
   Gap C explicitly resolved (§3.3 — basename list); Gap A
   confirmed read-at-runtime (§3.3 + §3.4) with cascade deferred to
   identify-only items; Gap B closed-by-deferral with three trigger
   options enumerated (§5.b + §5.c).

**Recommendation specifically:** primary chat may take the addendum
+ parent doc as the **complete architect-pass output** for per-entry
decomposition and proceed to:

- Spawn primary chat's own architect to integrate per-entry
  decomposition into the v11.0 implementation plan, addressing the
  identify-only inventory items (§5.a–§5.r) and resolving the three
  minor frictions above.
- Spawn the planner pass after the integration architect to
  schedule the implementation BDs (the planner reads the addendum's
  §5 inventory as the implementation-question backlog).

**No further addendum iteration required.** The three frictions
above are within primary chat's territory and do not block
integration.

If Pack Chat prefers to settle Friction 1 (hook-sequence scope
boundary) before integration, a single SendMessage to the sidecar
architect at UUID `a24f716efec12fd53` asking "is §1.3 numbered
sequence final-architect output, or should the planner choose
position?" would resolve it in one round trip. Optional; not
blocking.

---

## §9 — Read-record

This second-pass review consumed:

- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-
  ADDENDUM.md` (1,101 lines) — read in full across three chunks.
- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md`
  (1,649 lines) — refreshed via prior review notes; specific
  parent sections (§3.4, §5.1, §6.2, §10, §11, §13.4, §15.x, §17)
  cross-referenced for cascade verification.
- `maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-
  ENTRY-SPLIT.md` — Gaps A/B/C re-read from §5.8 + §6 follow-ups.
- `scripts/migrate-v10-to-v11.sh:125-155` — verified the existing
  five sub-operations in `migrator_post_dispatch_hook` exactly
  match addendum §1.3 (lines 144–148, function names verbatim,
  order verbatim).
- `scripts/lib/tracker-migrate-forward.sh:268, 399, 459` — verified
  function definitions exactly match addendum §4 citations.
- `scripts/lib/tracker-migrate-reverse.sh:409, 485, 553` — verified
  function definitions exactly match addendum §4 + §2.5 citations.
- `scripts/lib/migrator-core.sh:214` — verified
  `_migrator_run_stages` invokes `_stage_backup` (definition is in
  `migrator-stages.sh:146`, not `migrator-core.sh:146` — addendum
  §5.r citation slip).
- `scripts/lib/migrator-stages.sh:146` — verified `_stage_backup()`
  definition (the actual file the addendum should have cited).
- `BACKLOG.md:1-7` — verified preamble matches addendum §3.4 quote.
- `BACKLOG.md:9-20` — verified "How to use this file" block matches
  addendum §3.4 citation range.
- `BACKLOG.md:1388` — verified BD-161 entry text matches addendum
  §5.n quote verbatim.
- `BACKLOG.md:1157, 1399, 1402` — verified BD-116 / BD-160 / BD-161
  cross-references in addendum §5.g + §5.n.
- `CHANGELOG.md:1-6` — verified preamble matches addendum §3.4
  quote.
- `PACK-AGENTS.md:102-105` — verified Pack-Chat-only authority for
  BACKLOG/CHANGELOG (referenced indirectly via §1 + §3 of the
  addendum — both correctly preserve PM-only authority).
- `CLAUDE.md:174-183` — verified Pattern B sweep rule for
  workflow-artifact archival (referenced in addendum §5.l).
- `project-template/` directory listing — verified the
  project-template structure (addendum §5.q references
  `init-project.sh stage_s11_v11_artifacts()`).

No design or implementation files were edited by this review.

---

## §10 — Final-line marker

REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM-COMPLETE: 2026-05-13 —
APPROVE-FOR-PRIMARY-CHAT-ARCHITECT-INTEGRATION. Sections 1–5 closure
complete (all 4 corrections delivered + all 15 required identify-only
items + 3 architect-added items §5.p/§5.q/§5.r all valid). Internal
consistency cascade complete (parent §3.4/§5.1/§10/§11.1/§11.2/§13.4/
§15.1/§15.2/§17 all addressed by addendum's §1/§2/§2.6/§1.3/§1.4).
Architect-overreach scan: ZERO across six §5.4 signals + PM-only-files
+ v10 grammar. Factual accuracy 6/7 PASS (one citation slip §5.r —
`migrator-core.sh:146` should be `migrator-stages.sh:146`; line number
correct, file wrong; trivial fix). Prior-review Gaps A/B/C closed at
appropriate scope (Gap C explicitly resolved in §3.3; Gap A confirmed
runtime-read in §3.3+§3.4 with cascade deferred to §5.a+§5.m;
Gap B closed-by-deferral in §5.b+§5.c with three trigger options
enumerated). Three minor frictions resolvable by primary chat
directly (Friction 1: §1.3 hook-sequence scope boundary — Pack Chat
ratify or downgrade; Friction 2: §5.r citation typo; Friction 3:
implicit `_intro.md` round-trip identity in §4.4). No further addendum
iteration required. Recommendation: primary chat spawns its own
architect to integrate per-entry decomposition into v11.0
implementation plan + planner to schedule BDs from the addendum's
§5 inventory.
