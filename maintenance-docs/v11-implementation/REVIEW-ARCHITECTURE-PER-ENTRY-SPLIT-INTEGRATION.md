---
title: REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION
reviewer: primary-chat (v11-dev) — fresh critical reviewer (no prior session context)
target: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (3,477 lines, 2026-05-13)
target-author: primary-chat integration architect
parents: ARCHITECTURE-PER-ENTRY-SPLIT.md (sidecar) + ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md (sidecar)
prior-reviews: REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md + REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md
date: 2026-05-13
recommendation: NEEDS-ANOTHER-ITERATION (one BLOCKER, several SHOULD-FIX, many minor)
---

# Review of ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md

## §0 — TL;DR

The integration architect doc is large (3,477 lines), well-organized,
and disciplined on the architect/planner boundary. It correctly
surfaces PM-only edits without applying them, owns the regenerator
invocation REDESIGN-CORE cleanly, and resolves the three reviewer-
flagged frictions. **Goals 2 and 3 are designed at production
quality; Goal 1 is over-engineered with a maintenance-signal-tripping
new skill where simpler answers exist.**

**One BLOCKER** — §17.1 batch positioning is factually wrong. The
doc says "NEW Batch 18 between current Batch 17 (BD-106/107/108) and
Batch 19 (BD-105/103)." Verified at
`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:272`:
**Batch 18 already exists** and is occupied by BD-111 ("switch
blocks/blocked-by from comment-marker to first-class GH dependency
API, after Batch 17"). Batch 19 is BD-105 ∥ BD-103. Batch 20 is
BD-109 ∥ BD-110. The proposed insertion collides with an existing
batch. Every downstream reference to "Batch 18" in §17 is therefore
unsound. Pack Chat / planner cannot act on this without a renumber.

**Five SHOULD-FIX:**
1. §4.2 Layer 3 (`stream-discovery` skill) is scope creep that trips
   maintainability signals 5 ("new top-level skill") and 6 ("new
   skill family"). The triple-redundancy framing in §4.3 admits
   layers 1+2 already suffice.
2. §6.4 PACK-AGENTS.md edit specification is concrete but the
   defense vs maintainability signal 9 (PM-only file expansion) is
   thin. The architect waves "refactor not expansion" but the
   directory addition IS additional surface; signal 9 is tripped.
3. §7.4 concurrent-write safety claim ("git's normal merge-conflict
   mechanism is sufficient") understates the actual concurrent-write
   risk under the new commit-time invocation model — Pack Chat AND
   PM Chat in different repos is fine, but two pack-agent-spawned
   helpers in the same repo can produce divergent regenerated
   mirrors that don't conflict in git but disagree on entry order.
4. §10.6 says project-side per-entry trees are NOT validated by
   `validate-pack.py` — but client projects have no inherited
   validator that catches stale mirrors. Goal 2 enforcement on
   project-side is left to "the mirror regenerator's idempotency"
   which is not enforcement, it is a helper property.
5. §17.4 §3 says "Pack Chat drafts the BACKLOG-paste text using
   this doc's §17.2 table as the source." But §17.2's File/Symbol
   column for BD-167 mixes 6+ surfaces in one entry, several of
   which are PM-only. BD-167 is overloaded and should split into
   2–3 BDs.

**Many minor / nits** detailed in §1–§12 below.

**Recommendation: NEEDS-ANOTHER-ITERATION.** The blocker (batch
collision) requires one additional architect pass. The
recommendation is NOT NEEDS-REWORK because the architectural
substance is sound — the redesign of regenerator invocation is the
right call, the three frictions are resolved correctly, the source-
of-truth invariant design is solid. But the integration into the
execution plan — which is the central deliverable per the doc's own
title — is wrong on the load-bearing batch number, and that error
cascades through §17 sub-sections.

---

## §1 — Disposition correctness for the 18 identify-only items (§5.a–§5.r)

**Verdict: PASS with minor concerns.**

Per §8.0 disposition table: 15 DESIGN, 1 INVENTORY, 2 TRADEOFF, 2
REDESIGN-CORE. The brief expected this distribution; verified
present.

| Item | Expected disposition | Actual | Sound? |
|---|---|---|---|
| §5.a workflow discovery | DESIGN | DESIGN (§4 + §8.1) | YES — three-layer mechanism designed end-to-end |
| §5.b `_toc.md` runtime invocation | DESIGN or REDESIGN | REDESIGN-CORE (§7 + §8.2) | YES — overturns sidecar §6.4 cleanly; rationale sound |
| §5.c mirror generator runtime invocation | DESIGN or REDESIGN | REDESIGN-CORE (§7 + §8.3) | YES — same as §5.b, paired |
| §5.d stale-mirror detection | DESIGN | DESIGN (§5.4 + §8.4) | YES — silent overwrite + Check 32 layered correctly |
| §5.e concurrent-write safety | DESIGN | DESIGN (§7.4 + §8.5) | WEAK — see §3 below; understates the new race surface introduced by commit-time invocation |
| §5.f cross-reference integrity | DESIGN | DESIGN (§11 + §8.6) | YES — Check 34 is appropriate, well-bounded |
| §5.g test fixture migration | INVENTORY | INVENTORY (§12 + §8.7) | YES — clean inventory, BD-170 cleanly opened |
| §5.h validator new-checks | DESIGN | DESIGN (§10 + §8.8) | YES — fold from 6 to 3 is a good simplification |
| §5.i read-site audit completeness | DESIGN | DESIGN (§4.4 + §8.9) | MOSTLY — see §4 below; spot-check found one likely miss (`agent-run.sh` may reference state docs) |
| §5.j skill update inventory | DESIGN | DESIGN (§4.4.2 + §8.10) | YES — but the new `stream-discovery` skill itself trips signal 5; see §4 |
| §5.k STATUS.md interaction | DESIGN | DESIGN (§5.3 + §5.5 + §8.11) | YES — disclaimer well-specified |
| §5.l Pattern B archive sweep | DESIGN | DESIGN (§14 + §8.12) | YES — correctly determines no rule edit needed |
| §5.m customization-preserve at per-entry | TRADEOFF | TRADEOFF (§13 + §8.13) | YES — worst-case acknowledged honestly |
| §5.n BD-161 absorption | DESIGN | DESIGN (§17.2 + §8.14) | YES — but absorption target BD-167 is overloaded; see §0 SHOULD-FIX 5 |
| §5.o diffability / git history | TRADEOFF | TRADEOFF (§15 + §8.15) | YES — honest acknowledgement |
| §5.p namespace collision | DESIGN | DESIGN (§8.16) | YES — correct "no detection signal needed" call |
| §5.q init-project.sh greenfield | DESIGN | DESIGN (§9.5 + §8.17) | YES — extending S11 over adding S11b is the right minimalism |
| §5.r backup/rollback | DESIGN | DESIGN (§9.4 + §8.18) | YES — clean treatment with citation correction |

**Minor concerns:**

- **§5.j disposition label.** Item §5.j is the skill update inventory.
  The integration architect's "DESIGN" answer is to load a NEW
  `stream-discovery` skill. That is design — but it is design that
  ADDS pack-shipped surface, not design that updates existing
  surfaces. The disposition label is correct; the design choice
  inside is questionable (see §4 below).

- **§5.k disposition wording is slightly self-contradictory.** §8.11
  says "STATUS.md does not source-of-truth; the disclaimer makes it
  explicit; the recommendation-system continues to read the
  regenerated mirror." But §5.5 says signals continue to read the
  mirror — yet §5.5 also notes the per-entry-tree count is
  "available for any future convenience-view that wants to source
  from the per-entry tree directly." Two source-of-truth paths for
  the same number is exactly what Goal 2 forbids; the design should
  pick the per-entry tree as the canonical query path and let the
  mirror reads be a backward-compatibility shim. Minor wording
  issue, not a design failure.


---

## §2 — REDESIGN-CORE: regenerator invocation move from per-write to commit-time (§7)

**Verdict: PASS with one minor concern.**

This is the doc's biggest design change. Critical evaluation per the
brief's six sub-questions:

### §2.1 — Cost-savings claim (~3.3× speedup, 10 sec per commit at v13 scale)

**Spot-check of §7.2 calculation.** The table shows v11.0 baseline
~150 entries × 10ms/file = 1.5 sec for one regen pass; sidecar's
"after every write" model running 3–5 times = 4.5–7.5 sec. v13 scale
1000 entries × 10ms × 1 regen = 10 sec; sidecar model 3000–5000 ms
× 10ms = 30–50 sec.

**Concern: the 10ms/file constant is unjustified.** No source. Real
Markdown read+parse (BD-NNN.md ~30 lines) is more like 1–3ms on
modern hardware via Python or Bash. At 1000 files × 2ms = 2 sec
per regen, not 10. The 3.3× speedup claim survives any reasonable
constant; the absolute numbers may be 5× too pessimistic. **Sound
direction, slightly inflated magnitudes.** Doesn't change the
recommendation — even at 2 sec/regen the per-write model is wrong
for Goal 1 + 2 reasons regardless of cost.

### §2.2 — Discoverability of "commit-time invocation by Pack Chat / PM Chat"

**§7.3 step 3:** "Pack Chat / PM Chat invokes the mirror regenerator
for the affected stream(s) — single explicit command line." The
discipline is enforced by:
- Pack Chat operator memory (the same memory that Failure 1 critiques
  in §7.1 for the per-write model).
- CI gate (Check 32+33) catches misses post-commit.

**Honest critique:** the per-commit memorization is one step lighter
than the per-write memorization (since commit is a deliberate
moment), but it is still memorization — Pack Chat operator forgets,
commit goes out without regen, CI fails on push, operator amends or
follows up. This is acceptable BUT the design should either:
- Acknowledge that the "no memorizable rule" framing in §7.1 was
  about per-write specifically, not about the model in general.
- Or address the memorization more directly (e.g., a `pack commit`
  wrapper that runs regen+stage+commit in one verb — which §7.3 does
  NOT propose; it leaves regeneration as a separate operator step
  before staging).

The design is acceptable as drafted. The §7.1 framing is slightly
overclaimed. Minor.

### §2.3 — CI gate frequency (Check 32+33 at PR review time vs closer-to-write enforcement)

The CI gate fires on push; depending on the developer's flow, that
could be seconds-after-commit (for a single-commit branch push) or
hours-after-commit (for accumulated work). **The design accepts the
window.** §7.3 paragraph "Why NOT git pre-commit hook" rejects pre-
commit on three grounds:
1. "Must be installed manually by every developer."
2. "Must be skipped sometimes (`--no-verify`)."
3. "Add a debugging layer."

**Critique:** ground 1 is true but soluble — `init-project.sh` could
install the hook automatically (the same surface that ships
`agent-post-edit-check.sh` per `project-template/scripts/`). Ground 2
is true but applies to ALL pre-commit hooks; it doesn't disqualify
this one. Ground 3 is true but the same logic applies to ANY CI
check.

The architect's actual reason — "minimum-infrastructure model that
meets Goals 1 and 2" — is fine. The honest framing would be: pre-
commit hook is a planner-pass enhancement that COULD ship in v11.0
if the planner picks it up; CI gate is sufficient on its own. §18.1
item 6 says exactly this. Consistent. Acceptable.

### §2.4 — Rejection of incremental regeneration (§7.3 "Why NOT incremental regeneration")

"Killer: a single Status flip can move an entry between sections
(Open → Resolved bucket move), invalidating the 'affected sections'
calculation. Full regeneration is simpler and the cost (per §7.2) is
acceptable at v13 scale under the commit-time model."

**Sound.** The Status-flip-causes-cross-section-move is the right
killer. Section partitioning by Status means even a single-entry
edit can require N section recomputations; the optimization
disappears. Full regen at 10 sec (or 2 sec with realistic constants)
is fine.

### §2.5 — Rejection of pre-commit hook

Covered in §2.3 above. **Acceptable but slightly under-defended.**

### §2.6 — Rejection of lazy/on-read regeneration

§7.3 paragraph "Why NOT lazy / on-read regeneration":
1. Read sites are non-uniform; lazy regen would force every read
   site to invoke or accept staleness.
2. Read operations would have side effects on disk and git status.

**Sound.** Lazy regen breaks the read-only invariant of read sites,
which is a fundamental architectural property of the existing
agent/script ecosystem.

### §2.7 — Net dimension verdict

**PASS.** The redesign is the right call. Cost calculation has
slightly inflated constants (no impact on conclusion). The "no
memorizable rule" framing in §7.1 is mildly overclaimed for the new
model (still requires Pack Chat to remember to invoke regen before
staging) — but the framing isn't load-bearing because the CI gate
catches misses. Pre-commit hook deferral to planner is consistent.

---

## §3 — Three reviewer frictions (§3)

**Verdict: PASS.**

### §3.1 — Friction 1: §1.3 hook ordering downgrade to constraint statement

The architect's call: keep the constraint ("decompose runs after all
monolithic-content mutations have settled") at architect-pass scope;
let the planner pick literal call-list position + function name.

**Sound.** Per the prior reviewer's own §4.1 framing ("Pack Chat may
ratify literally OR downgrade to constraint statement; either is
fine"), the integration architect picked option (b). The constraint
binds the planner to the only correct sequencing; the literal
ordering doesn't bind anything not already bound by the constraint.
Clean call. **PASS.**

### §3.2 — Friction 2: §5.r typo correction

The architect cites the correct location (`migrator-stages.sh:146`)
and explicitly acknowledges the correction in §3.2, §8.18, and §9.4.

**Verified directly.** `grep -n "^_stage_backup()" scripts/lib/`
returns `migrator-stages.sh:146`. The integration architect's three
citations of this line in the doc are all `migrator-stages.sh:146` —
not `migrator-core.sh`. **PASS.**

### §3.3 — Friction 3: `_intro.md` flat ↔ tracker round-trip

The architect's resolution per §3.3: pack-shipped immutable, never
tracker-touched, pack and project copies separate, both go through
BD-088 generic class on pack version-bump. Forward emit ignores
`_intro.md`; reverse emit doesn't touch it; supporting files are NOT
part of the flat ↔ tracker contract surface.

**Matches Pack Chat user direction** (per the brief context — "pack-
shipped immutable, no tracker round-trip"). The cascade through §9.7
("`_intro.md` and `_v8-resolved-archive.md` initial install") covers
the v10→v11 first-migration content extraction path correctly:
extract from monolithic preamble at first migration, treat as
immutable from then on. **PASS.**


---

## §4 — Goal 1 — Discoverability design (§4)

**Verdict: WEAK.**

The integration architect designs three layers (trinity Key files
pointer + per-entry HTML-comment back-pointer + `stream-discovery`
skill loaded by pack-startup/pm-startup). Critical evaluation:

### §4.1 — "Triple redundancy" framing

§4.3 names the design "triple redundancy" and the table lists five
recovery scenarios where any of layers 1+2+3 covers any of the
others. This is structurally **belt + suspenders + a backup belt**.

**Critique:** the design admits in the same table that:
- "Agent reads a single per-entry file and has no other context" →
  Layer 2 alone (HTML-comment back-pointer) suffices: "2 Read calls,
  ~50 lines total."
- "Mirror-read scenario" → Layer 0 (the mirror's preamble names the
  per-entry tree) — wait, this is mentioned but NOT enumerated as a
  layer; it's effectively a fourth implicit layer.
- "All three layers fail" → §4.3 last row says "Pack-startup / pm-
  startup explicit `_rules.md` read directive" closes it. That is
  Layer 3 (the skill) again, not a fourth fallback.

So the actual recovery surface is: trinity (Layer 1) + back-pointer
(Layer 2) + skill (Layer 3) + mirror preamble (implicit Layer 0).
**That's actually four layers, not three.** The skill is the most
expensive layer to ship and maintain.

### §4.2 — Maintainability cost of the new `stream-discovery` skill

Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3 (verified at lines 168-183 of CLAUDE.md `## Pack memory` quoting
the principle), adding a new skill is signal 5 ("new top-level doc")
or signal 6 ("new skill family") territory. Skills require:
- Canonical SKILL.md authoring
- Cross-CLI distribution (3× — `.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/`)
- Active-skills line addition in pack-startup AND pm-startup (×6
  files per the §4.4.2 inventory: canonical pack-startup +
  `.claude/.codex/.gemini` mirrors + canonical pm-startup +
  `.claude/.codex/.gemini` mirrors)
- Inclusion in `PLATFORM-SKILLS.md`
- Future maintenance burden

The architect's defense in §4.2 Layer 3 ("Why a skill, not just
trinity prose: skills load deterministically at session start") is
true but circular — the per-entry contract resolution is
~1 paragraph that ALSO lives in the trinity Key files block (Layer
1) and in the per-entry file's HTML-comment header (Layer 2). The
deterministic trigger argument requires that pack-startup and pm-
startup themselves load the trinity (which they already do per
verified `pack-startup/SKILL.md:19-21` and `pm-startup/SKILL.md:69-87`).
Layer 1 IS deterministic at session start because the trinity is
deterministically loaded.

**Critique: Layer 3 is scope creep.** The trinity Key files line
addition (Layer 1) carries the same content with zero new file
authoring, zero new distribution, zero new active-skills-line
maintenance. The HTML-comment back-pointer (Layer 2) carries the
recovery anchor at every per-entry-file read. Together they cover
all five §4.3 recovery scenarios. The new skill adds maintenance
burden (signal 5 / 6 trip) for no incremental Goal 1 coverage.

**Recommendation for the next iteration:** drop Layer 3. Two layers
fully satisfy Goal 1. The maintainability principle says "additions
require architect-pass defense"; THIS architect pass is the defense
opportunity, and the doc's own §4.3 admits 1+2 suffice. The defense
should be "two layers; not three."

### §4.3 — Recovery walkthrough from agent perspective

**Scenario: agent has read `/.backlog/BD-160.md` and nothing else;
pack-startup did not run; trinity not in context.**

Per §4.2 Layer 2, the file's first line is:
```
<!-- per-entry source: /.backlog/BD-160.md; contract: /.backlog/_rules.md -->
```

The agent must:
1. Know HTML-comment back-pointers exist (this knowledge has to come
   from somewhere — agent training, prompt context, or another file).
2. Parse the comment.
3. Read `/.backlog/_rules.md`.

**Hidden assumption:** the agent must already know to look at line 1
for an HTML comment. If the agent has truly no context, it has no
reason to look at line 1 specifically. The Layer 2 design is
recovery-FOR-AGENTS-WHO-KNOW-TO-LOOK; not recovery for fully-
context-stripped agents.

This isn't a fatal flaw — agents bootstrapped via pack-startup /
pm-startup will know (per §4.2 Layer 3 directive). But it does mean
Layer 2 is not actually a layer-3-failure recovery path — it requires
Layer 3 (or equivalent prompt context) to be functional. **The
"triple redundancy" claim is overstated.**

### §4.4.1 — Surfaces that STAY inventory completeness

Spot-checked. The §4.4.1 inventory names ~15 surfaces. **One likely
miss:**

- `agent-run.sh` (project root, per `project-template/CLAUDE.md`
  "Scripts" section) is a launcher; it does NOT directly read state
  docs but it sources prompt templates. Possibly out of scope; flag
  for verification.
- `project-template/scripts/agent-post-edit-check.sh` is named in
  the project-template Scripts table. Not state-doc-aware. Likely
  out of scope.
- `OPTIONAL-FEATURES.md` — referenced in BD-135 inventory at
  EXECUTION-PLAN-V11.0.md:189; references `tracker.toml.example`
  by name. Doesn't reference BACKLOG/CHANGELOG; can stay.

Net: inventory looks substantively complete. **Not a blocker; minor
"verify these were considered" gap.**

### §4.5 — Script discovery (validate-pack, migrator, init-project, detect, customization-preserve)

§4.5 walks each:
- `validate-pack.py`: hardcodes stream constants; does NOT read
  `_rules.md` at runtime. **Sound.**
- `migrate-v10-to-v11.sh`: helpers know stream paths via shared
  constants. **Sound.**
- `init-project.sh`: extends S11 with hardcoded paths. **Sound.**
- `detect.sh`: no change required (per §8.16 namespace decision).
  **Sound.**
- `customization-preserve.sh`: `generic` class fall-through; no
  `_rules.md` read. **Sound.**

Per §7.5: only the mirror generator + `_toc.md` regenerator read
`_rules.md` at runtime, and ONLY for the supporting-file basenames
list. Everything else is hardcoded. **Sound and minimal.**

### §4.6 — Net dimension verdict

**WEAK.** The design over-engineers Goal 1 with a third layer that
trips maintainability signals 5 and 6 for no incremental coverage
beyond layers 1+2. The "triple redundancy" framing is overclaimed
(the three layers are not actually independent — Layer 2 requires
Layer 3 or equivalent prompt context to be functional). The script
discovery treatment in §4.5 is well-bounded and minimal. The
inventory in §4.4 is substantively complete.

**Path forward:** drop Layer 3 (the new `stream-discovery` skill);
extend pack-startup and pm-startup directly with a single line
naming the per-entry tree and `_rules.md` as the contract path. No
new skill ships; signals 5/6 not tripped; trinity Key files line +
HTML-comment back-pointer carry the recovery surface; pack-startup
+ pm-startup carry the deterministic-load behavior via existing
mechanism.


---

## §5 — Goal 2 — Source-of-truth invariant + STATUS.md disclaimer (§5)

**Verdict: PASS with one minor concern.**

### §5.1 — Source-of-truth declaration completeness (§5.1)

The architect declares per-entry file as source for entry content;
`_rules.md` for per-stream contract; `_intro.md` for stream preamble;
`_v8-resolved-archive.md` for the legacy block; `_format.md` for
project changelog format rules; mirror is NOT source; `_toc.md` is
NOT source.

**Spot-check for missing data classes:**
- ✓ Entry content
- ✓ Per-stream contract
- ✓ Stream preamble
- ✓ Legacy v8 block
- ✓ Project changelog format
- ✓ Mirror (declared NOT source)
- ✓ TOC (declared NOT source)

**Missing:** `recommendation-state` signals (the inflection-point
recommendation system per V3 §28.1). §5.5 says signals continue to
read the mirror. Source-of-truth-declaration: the per-entry tree IS
source for `bd_count_active` and friends; the mirror is a derived
view; the recommendation system reads the derived view. Two
equivalent paths to the same number. The architect notes this is
"mathematically equivalent under Check 32" — true — but Goal 2 still
prefers a single canonical query path. Minor; the architect flags
this as a future-convenience-view concern, which is the right
deferral.

**Missing:** `id-map.json` (the tracker bridge — per V1 §6.x). Under
Mode 3 with per-entry tree present per §5.6, the id-map tracks
flat-entry ↔ tracker-issue mappings. The architect doesn't
declare its source-of-truth class; arguably out of scope for per-
entry-split integration, but worth a one-line note. Nit.

### §5.2 — Workflow source-of-truth resolution rule

The architect proposes "every workflow that needs to know an entry's
field MUST resolve through tracker (Mode 3) OR per-entry file (Mode
2), NOT through the mirror or `_toc.md`."

**Enforceability:** the rule is aspirational for existing read sites
that read the mirror (which §5.2 explicitly admits — "Existing read
sites continue to work; the new rule applies to NEW workflows"). The
mirror reads are guaranteed-current via Check 32, so this is
acceptable — the rule documents the preferred path without
mandating retroactive changes.

**Sound.** The rule has bite for new code (planner / coder will
follow it for new helpers) and is informational for existing code.
This matches the "mirror-not-replace" sidecar contract.

### §5.3 — STATUS.md disclaimer wording (PM-only edit Pack Chat applies)

The architect provides a concrete sample disclaimer:
```
<!-- STATUS.md is a CONVENIENCE VIEW. It is NEVER source of truth.
     Counts and links may be stale; if they disagree with the
     per-entry tree at docs/project/backlog/ or the regenerated
     BACKLOG.md mirror, the per-entry tree wins. Workflows must
     not depend on STATUS.md being current; depend on the per-
     entry tree. -->
```

**Concrete enough for Pack Chat to apply directly.** §18.1 item 7
notes the planner can refine wording. **Sound and complete.**

**One nit:** STATUS.md is project-side only (verified via search —
no `STATUS.md` exists in the pack repo or `project-template/`
greenfield ship; it's created by `pm-startup` kickoff per V3 §28.1).
The disclaimer instruction targets `project-template/docs/project/STATUS.md`
which doesn't exist in the pack repo — STATUS.md is created at
project-init time by PM Chat per V3, not shipped from pack template.
The architect needs to clarify: is the disclaimer (a) added to PM
Chat's STATUS.md authoring template (so every new project's STATUS.md
is born with the disclaimer), or (b) added to existing project
STATUS.md files via a migration step? Probably (a); flag for clarity.

### §5.4 — Stale-mirror / stale-TOC detection (§5.4)

Two-mechanism solution: silent overwrite + Check 32/33 in CI. The
architect rejects sidecar option 3 ("refuse to regenerate when
divergent edits exist") explicitly: "the silent overwrite preserves
the 'mirror is derived' invariant without requiring user
intervention on every regeneration."

**Sound.** Refuse-to-regenerate would create a confirm-dialog flow
that breaks Pack Chat batch ergonomics. Silent overwrite + CI is the
right combination.

**One concern:** the design doesn't explicitly address what happens
when a developer hand-edits the mirror, regenerates over it, AND
commits. The CI gate only catches the case where the developer hand-
edits and forgets to regenerate. Hand-edit-then-regenerate produces
a clean mirror in CI but loses the developer's edit silently. This
is the correct behavior under "mirror is derived" but is worth
naming explicitly so a developer doesn't mistake the silent
overwrite for a bug. Nit.

### §5.5 — Inflection-point recommendation system

§5.5 ratifies sidecar §16.5: signals read the mirror. Per-entry tree
count produces the same number. Mathematically equivalent under
Check 32. **Sound.** No design change needed; the recommendation
system is unaffected by per-entry split.

### §5.6 — Mode-2 → Mode-3 transition strengthening (Option A required)

The architect strengthens sidecar §8.2 to "Option A is required" —
when tracker init fires, the per-entry tree is regenerated from
tracker state alongside the monolithic mirror. Symmetric on tracker
disable.

**Sound.** Option B (per-entry tree left untouched as stale) would
violate Goal 2 directly. The strengthening is correct.

**One concern:** §5.6 paragraph "One concrete planner item" names a
recovery scenario: "the client manually deletes the per-entry tree
on disk (e.g., `rm -rf /.backlog/`)" should be detected by `pack
tracker doctor`. This is named but identify-only — adds to the
planner's open scope (§18.1). Acceptable; flagged correctly.

### §5.7 — Net dimension verdict

**PASS.** Source-of-truth declaration is essentially complete (one
data class — recommendation-state signals — has a soft duplicate
read path that the architect acknowledges; one — id-map.json — is
arguably out of scope). The disclaimer text is concrete. Stale-
mirror detection is layered correctly. Mode 2 → Mode 3 strengthening
is sound. The STATUS.md application moment (project init vs
existing-project migration) needs a one-line clarification but is
not load-bearing.

---

## §6 — Goal 3 — Read/write rules audit (§6)

**Verdict: PASS with one SHOULD-FIX.**

### §6.1 — Write authority by surface

The §6.1 table walks 17 surface classes. **Spot-check:**
- All five pack-side trees + supporting files: covered.
- All five project-side trees + supporting files: covered.
- Mirror at canonical path: declared regenerated, not Pack-Chat-write.
- TOC: declared regenerator-only.

**Audit completeness:** the table covers all per-entry-tree write
surfaces. **Implicit surfaces missing from the table:**
- `id-map.json` writes (tracker mode) — but this is V1 §6 surface,
  arguably out of scope for per-entry-split.
- `tracker.toml` writes — out of scope.
- `STATUS.md` writes — covered indirectly via §5.3 disclaimer; but
  not in §6.1 table. Nit.

**Net audit:** every per-entry-tree write goes through Pack Chat or
PM Chat. Goal 3 invariant holds. **PASS.**

### §6.2 — Pack agent permission verification

The architect walks `pack-architect`, `pack-planner`, `pack-coder`,
`pack-reviewer`, `pack-docs-researcher` — all five pack agents per
PACK-AGENTS.md. **Verified the agent count is correct** (PACK-AGENTS.md
table at lines 13–19 lists exactly five).

The verification is implicit ("All five are listed as Read-only
except `pack-coder`...") rather than per-agent enumerated. A more
rigorous pass would walk each agent's `.claude/agents/<name>.md`
section by section; the integration architect's pass is adequate at
the architect-pass scope.

**One omission:** project-side agents (`coder`, `repo-ops`,
`auditor`, `auditor-docs`) are NOT walked here, but the §6.1 table
lines 1320 and 1324 reference their write-prohibitions. Implicit
audit; should be more explicit per-agent for project side. Nit;
trivially fixable in a planner-pass walk-through.

### §6.3 — Mirror generator and TOC regenerator: tooling-not-agent

The architect's distinction: helpers are deterministic shell
functions, not agents; they have no LLM session, no autonomy. They
are invoked by Pack Chat / PM Chat / migrator (tooling-as-trigger).

**Holds throughout the design.** §7.3 step 3 ("Pack Chat / PM Chat
invokes the regenerator") is "Pack Chat invokes tooling," not "Pack
Chat writes." The Goal 3 binding allows tooling writes when
triggered by Pack/PM Chat. Consistent.

### §6.4 — PACK-AGENTS.md edit specification (SHOULD-FIX)

The architect proposes extending the PM-only files block from naming
files to naming files + directories. The defense in §6.2 is "the
addition is required by Goal 3 — the per-entry tree IS the new
entry-write surface, and entry-writes are PM-only. Not extending the
list would violate Goal 3."

**Critical evaluation:** per
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 line 305-306, signal 9 is "Any addition to the agents-never-
modify list or the PM-only file list in PACK-AGENTS.md." The
architect acknowledges this is a strict signal-9 trip (§6.2 paragraph
"Defense vs maintainability signal 9").

The defense is "refactor in shape, not expansion in semantics" — but
this is partly true and partly false:
- **True in semantics:** the directories represent the same scope as
  the files (entry content is the protected surface).
- **False in shape:** the list grows by 5 directories. The agents
  reading PACK-AGENTS.md must now respect 5 additional path
  patterns. New directories that didn't exist before now exist and
  are off-limits. This IS expansion of the surface that agents must
  avoid.

The architect-pass-defense IS this integration architect; the
defense is recorded; signal 9 is "tripped with defense." Per the
maintainability principle's "structural change requires architect-
pass," the defense is the requirement. Met.

**SHOULD-FIX:** the defense should be tightened to acknowledge the
shape-expansion honestly rather than recasting it as a refactor. The
honest framing: "the protected surface expanded from 7 named files
to 7 files + 5 directories; the expansion is required by Goal 3 and
defended here per the maintainability principle." This wording
preserves the architect's intent without obscuring the expansion. Pack
Chat applying the PACK-AGENTS.md edit will need this clearer framing
to write a defensible commit message.

### §6.5 — CLAUDE.md pack-memory addition

The architect surfaces concrete pack-memory text:
> **Per-entry trees are source of truth; mirrors are derived.** ...

**Concrete enough for Pack Chat to apply.** Clean. **PASS.**

The trinity rule application (CLAUDE.md / AGENTS.md / GEMINI.md
identical edits at pack root) is correctly named.

### §6.6 — Net dimension verdict

**PASS** (with §6.4 SHOULD-FIX on framing). The audit is substantively
complete; the surfaced PM-only-file-list expansion is honest about
its impact even though the framing could be sharper. CLAUDE.md
pack-memory text is concrete and applies cleanly.


---

## §7 — Validator new-checks (§10 — Checks 32 / 33 / 34)

**Verdict: PASS.**

### §7.1 — Check 32 (mirror-in-sync)

**Specification:** regenerate the mirror to a temp file; diff against
the on-disk mirror. Fail with file:line of divergence and recovery
instruction. Pre-checks fold in `_rules.md` existence and per-entry
filename conformance.

**Implementability:** the function-shape sketch in §10.1 is concrete
enough for the planner. Inputs (per-stream tree path, canonical
mirror path), outputs (PASS/FAIL), failure modes (missing _rules.md,
non-conforming filenames, mirror divergence). Recovery instructions
are explicit ("run mirror regenerator").

**Layer positioning:** validate-pack runs in CI on push (per the
existing CI baseline). The architect's call to position Check 32
in CI rather than pre-commit is consistent with §7.3's pre-commit
deferral. **Sound.**

**Cost:** ~1.5 sec at v11.0 baseline; ~10 sec at v13 scale per §7.2.
CI-tolerable.

### §7.2 — Check 33 (TOC-in-sync)

Same shape as Check 32, applied to `_toc.md`. **Sound and minimal.**

### §7.3 — Check 34 (cross-reference integrity)

The function shape in §10.3 walks per-entry files; extracts
`Blockers:` / `Unblocks:` / inline references via regex; checks
against the defined-IDs set.

**Walkthrough scenarios:**

**Scenario A: developer renames `BD-160.md` → `BD-160-renamed.md`.**
- `BD-160` no longer in defined-IDs (the new filename doesn't match
  the BD-NNN regex per Check 32 pre-check, OR if it does match a
  different ID, BD-160 is now missing from the set).
- Any entry with `Blockers: BD-160` fires Check 34 FAIL with the
  citing entry's file:line.

**Scenario B: developer deletes `BD-160.md`.**
- Same as above: `BD-160` missing from defined-IDs, citing entries
  fail.

**Scenario C: developer typos `Blockers: BD-1600` (extra zero).**
- `BD-1600` not in defined-IDs; Check 34 FAIL. Catches typos.

**Scenario D: developer adds a NEW BD-200, references it from BD-100
as `Blockers: BD-200`, but forgets to commit BD-200.md.**
- Stage BD-100.md edits; CI runs against the staged set. If BD-200.md
  not staged, BD-200 not in defined-IDs; Check 34 FAIL. Catches missing
  files at PR review.

**Scenario E: false positive — backtick-escaped reference.**
- §11.2 acknowledges: "false positives (matches in code blocks or
  quoted text) are tolerated; the user can suppress via a backtick-
  escape if needed (planner refines)." This is an acceptable
  starting heuristic; planner will refine.

**Scenario F: cross-stream reference (pack BD references project TD).**
- §10.6 explicitly out-of-scope ("the project tree isn't loaded by
  the pack-repo validator"). Acceptable narrowing.

**Net:** the check catches the targeted scenarios. Scope-narrowing is
honest. **PASS.**

### §7.4 — Why three checks, not one parameterized check

§10.4 folds six candidate checks (mirror-in-sync, TOC-in-sync,
_rules.md exists, filename conformance, cross-ref integrity, v8
archive byte-stable) into three by making _rules.md existence and
filename conformance pre-checks of Check 32, and v8 archive
byte-stability covered by Check 32's tail.

**Sound consolidation.** Three function definitions; each focused on
a distinct invariant. Easier to read, debug, extend. **PASS.**

### §7.5 — Net dimension verdict

**PASS.** All three checks are implementable, well-positioned at the
CI layer, and Check 34 catches the dangling-reference scenarios per
walkthrough. The fold from 6 checks to 3 reduces validator surface
without losing coverage.

---

## §8 — Integration into v11 execution plan (§17) — BLOCKER

**Verdict: FAIL (blocker).**

### §8.1 — Batch positioning (BLOCKER)

The architect's §17.1 reads:

> Proposed: NEW Batch 18 between Batch 17 (BD-106 / BD-107 / BD-108
> tracker entity model) and Batch 19 (BD-105 / BD-103 STATUS.md +
> tracker reset).

**Verified directly against `EXECUTION-PLAN-V11.0.md` §4 batch
table (lines 251-280):**

| Batch | Actual scope (per the plan) |
|---|---|
| 17 | BD-106 → BD-107 → BD-108 (tracker entity-model expansion) |
| **18** | **BD-111 — switch blocks/blocked-by from comment-marker to first-class GH dependency API. After Batch 17 lands the entity model.** |
| 19 | BD-105 ∥ BD-103 (STATUS.md dual-link rendering ∥ pack tracker reset) |
| 20 | BD-109 ∥ BD-110 (auditor agents) |

**Batch 18 is already occupied by BD-111.** The proposal "NEW Batch
18 between current Batch 17 and Batch 19" is impossible — there is
no slot at "Batch 18"; that slot exists. The architect appears to
have read past the Batch 18 row in the plan.

**Cascade impact:** every reference to "Batch 18" in §17 is wrong.
Specifically:
- §17.1: "Batch 18 sits cleanly between Batch 17 and Batch 19. No
  swap with existing batches required." FALSE.
- §17.2: "Total BD count for Batch 18: 7 new + 1 absorbed = 8
  entries tracked." Wrong batch.
- §17.3: "Commit 18a–18h" — 8 commits assigned to a batch that's
  occupied.
- §17.4: "Insert Batch 18 row in the §4 batch table between current
  Batch 17 and Batch 19." Pack Chat would not be able to apply this
  literal edit.
- §17.5: "Batch 18 (per-entry split) lives in step 4. It does NOT
  interfere with steps 1–3." Wrong batch number.
- §17.7: "BD-102 dog-food (Batch 22) gains a new exercise surface"
  — Batch 22 reference is correct.
- §17.8: total-count math is downstream from the batch numbering.

**Resolution path:** either (a) rename the per-entry-split batch to
the next available number (Batch 19 if all current 18+ shift, or
Batch 22.5 / Batch 23 if inserted late), or (b) renumber existing
Batches 18+ (BD-111, BD-105/103, BD-109/110, BD-136 implementation,
BD-100 audit, BD-102 dog-food, BD-093 release pin) to make room.

Option (a) is non-destructive of existing planning; option (b)
preserves the architect's logical positioning ("after tracker entity
model, before STATUS.md dual-link rendering"). Pack Chat decides;
either is fine — but the architect doc as written is unimplementable
without the renumber.

**Sequencing constraints check:** the architect's hard-sequencing
constraints in §17.1 (AFTER Batches 6, 7-10, 12, 13, 17; BEFORE
Batches 21, 22) are all sound and would survive any renumber. Only
the literal batch-number assignment is wrong.

### §8.2 — 7 new BDs sized correctly?

**BD-164 (per-entry split implementation: decompose helper + mirror
generator + `_toc.md` regenerator + supporting-file generators).**
This is multiple helpers; planner-pass will need to scope. Not
oversized in itself — the helpers share parsing logic per §2.2 — but
"+ tests" is implicit and could be its own commit. **Reasonable
sizing.**

**BD-165 (`_v10_to_v11_decompose_streams` 6th sub-operation).**
Adapter-private; one new function in the post-dispatch hook. Small.
**Right-sized.**

**BD-166 (init-project.sh greenfield S11 extension).** One stage
extension. Small. **Right-sized.**

**BD-167 (per-entry split client artifact installs ABSORBS BD-161).**
**OVERSIZED.** Per §17.2 File/Symbol column, this BD covers:
- `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md`,
  `_intro.md`, `_format.md` (project changelog only) — pack-product
  authoring
- `migrate-v10-to-v11.sh` install step extension — script change
- `tracker-agent-read.sh` per-entry-prefer-mirror-fallback extension —
  library change
- Trinity "Key files" line addition — PM-only edit (×3 pack root)
- `stream-discovery` skill ship — pack-product authoring + per-CLI
  distribution
- PACK-AGENTS.md PM-only directories list expansion — PM-only edit
- BD-161's net-new SKILL.md installs — separate scope
- (Implicit) STATUS.md disclaimer — but STATUS.md doesn't exist in
  pack template per §5.7 above

This is at least 6 distinct scopes mixed into one BD. **SHOULD-FIX:**
split BD-167 into 2-3 narrower BDs:
- BD-167a: pack-product canonical templates (per-stream `_rules.md`,
  `_intro.md`, `_format.md` authoring)
- BD-167b: tracker-agent-read extension + migrator install step
- BD-167c: stream-discovery skill ship (if Layer 3 survives §4 review;
  if not, drop entirely)

PM-only edits should be surfaced as Pack Chat actions, not BD scope.

**BD-168 (validator Checks 32+33+34).** Three checks in one BD;
sized acceptably given §10.4 fold from 6 to 3. **Right-sized.**

**BD-169 (read-site audit + targeted wording updates, "one prose-
tightening commit").** Per §4.4.3 covers ~14 distinct edit sites
(8 prose + 6 trinity-key-files lines, with skill-list-line
additions). Many are PM-only (trinity, PACK-CHAT, README, PM-CHAT)
and need to be Pack-Chat-applied separately. **OVERSIZED for one
commit.** Should split prose-tightening (pack-product) from
PM-only edits.

**BD-170 (pre-decomposed v11-realistic-ot fixture extension).**
Right-sized.

**Net BD-sizing:** BD-167 and BD-169 conceal larger work that mixes
PM-only edits with pack-product. Recommend splits.

### §8.3 — BD-161 absorption preserves original BD-161 scope?

BD-161 per pack `BACKLOG.md:1388`: "v10→v11 migrator: install net-
new v11 SKILL.md dirs (BD-156/157/158 + python-server-architecture /
python-data-architecture split)." The architect's §8.14 absorption:
"BD-161 stays in BACKLOG; Status flips when BD-167 ships, with
Resolved line citing 'merged into BD-167 v11.0 client artifact
install batch'."

**Mechanism:** §8.14 says "Both touch the v10→v11 migrator's post-
dispatch hook; both ship in the same commit; the post-report
advisory paragraph names both operations together. The two operations
remain distinct in the implementation."

**Concern:** absorption preserves the BD-161 work but conflates two
unrelated scopes (skill-dir installs + per-entry-tree installs)
under one BD-tracking heading. This is acceptable IF Pack Chat
flips the original BD-161 status with a clear "absorbed-into-BD-167"
Resolution line. The architect's §17.3 commit 18b includes BD-167's
multi-scope work; commit 18h flips BD-161 to Resolved. **Pattern
matches the existing absorption convention** (per multiple BDs in
the BACKLOG with similar "merged-into" Resolution lines).

**PASS** for absorption mechanism. The BD-167 oversizing concern in
§8.2 is the underlying issue.

### §8.4 — 8-commit boundary cohesion

The architect proposes 8 commits (18a–18h). Each is named with its
BD scope. Per §A.1 stop-before-commit, each commit needs to be
independently approve-able.

**Independence check:**
- Commit 18a (BD-164 helpers + tests): standalone library; no
  migrator wiring. **Independently approvable.**
- Commit 18b (BD-167 templates + trinity + PACK-AGENTS + skill +
  STATUS.md disclaimer): mixed PM + pack-product. **NOT
  independently approvable** — PM-only edits go through Pack Chat
  direct, not coder; and the multi-scope mix means several
  approve-or-reject decisions per commit.
- Commit 18c (BD-165 migrator step): wires 18a into migrator.
  **Depends on 18a; independently reviewable.**
- Commit 18d (BD-166 init-project): wires 18a into init-project.
  **Depends on 18a; independently reviewable.**
- Commit 18e (BD-168 validator checks): adds CI gates. **Depends on
  18a (the helpers Check 32 invokes); independently reviewable.**
- Commit 18f (BD-170 fixture extension): builds v11-realistic-ot
  pre-decomposed. **Depends on 18a.**
- Commit 18g (BD-169 read-site updates): final wording-only commit.
  **Depends on 18b (canonical templates exist).**
- Commit 18h (BD status flips): Pack-Chat-direct. **Depends on 18a-g.**

**Issue:** Commit 18b's multi-scope mix is the BD-167 oversizing
problem from §8.2 manifesting as a non-cohesive commit. Recommend
splitting 18b into 18b1 (pack-product canonical templates),
18b2 (tracker-agent-read + migrator install extension), 18b3 (PM-
only edits — Pack Chat direct: trinity, PACK-AGENTS, README,
STATUS.md disclaimer). The 8-commit count expands to ~10.

### §8.5 — Sequencing constraints with Batches 7-10 (tracker repairs) and Batch 12 (BD-104 rename)

Per §17.1 hard-sequencing:
- AFTER Batches 7–10 (BD-131..BD-134 tracker repairs) — required
  because reverse-emit reuse for tracker mode → Mode 2 transition
  per §5.6.
- AFTER Batch 12 (BD-104 rename) — required because decompose
  reads the hyphenated `IMPLEMENTATION-PLAN.md` filename.

**Both verified against the existing plan's batch sequence:**
Batches 7-10 land before any high-numbered batch; Batch 12 is BD-104
per `EXECUTION-PLAN-V11.0.md:265`. **Sequencing is sound.** Only the
literal Batch 18 number is wrong.

### §8.6 — Net dimension verdict

**FAIL (BLOCKER).** Batch positioning is wrong; cascade through §17
sub-sections. BD-167 is oversized; BD-169 is oversized. 8-commit
boundary mixes PM-only and pack-product in commit 18b.

**Fix path:** one architect-pass iteration to (a) renumber the
per-entry-split batch (Pack Chat picks the actual number based on
existing plan), (b) split BD-167 and BD-169, (c) restructure the
commit boundary so PM-only edits are Pack-Chat-direct rather than
mixed into pack-coder commits. Estimated 2-4 hours of focused
re-edit; not a fundamental redesign.


---

## §9 — Cascade consistency from sidecar (§16.2 ratification table)

**Verdict: PASS with one missed-challenge.**

### §9.1 — Sidecar decisions ratified

The §16.2 table enumerates 23 sidecar decisions ratified, plus 1
DOWNGRADED (Friction 1) and 1 CORRECTED (Friction 2 typo) and 1
STRENGTHENED (Mode 2 → Mode 3 Option A is required). Plus 1
REDESIGN-CORE (regenerator invocation per §7).

Walking the most load-bearing ratifications:
- ✓ Per-entry files = source of truth. Sound.
- ✓ v11.0 lock-in mandatory + non-reversible. Per Pack Chat direction.
- ✓ One file per phase, tasks inline. Sound.
- ✓ Five stream directories. Sound.
- ✓ Customization-preserve generic-class fall-through. With worst-
  case acknowledgment per reviewer §6.6.
- ✓ Mirror-not-replace. Sound.
- ✓ BD-119 framework hook contract preserved.
- ✓ `_intro.md` per stream (immutable per §3.3 clarification).
- ✓ Concatenation order (intro → entries → v8-archive). Sound.

### §9.2 — Did the integration architect miss any sidecar decision that should have been challenged?

**One candidate missed-challenge: the leading-dot directory naming
convention for pack-side `/.backlog/` and `/.changelog/`.**

Sidecar §0/§3.1/§3.2 places these at pack repo root with leading-dot
to mark them as "structured pack state, not pack product, parallel
to `.pack-tracker/`." The integration architect ratifies this in
§2.1 without challenge.

**Why this might be worth challenging:**
- The leading-dot convention is gitignore-relevant. `.git`, `.github`,
  `.codex`, `.claude`, `.gemini`, `.pack-tracker` are leading-dot. By
  convention many Unix tools (`ls`, default `find`, default shell
  globs) hide leading-dot files. This affects DISCOVERABILITY (Goal
  1) — a developer running `ls` at pack repo root won't see
  `/.backlog/` by default.
- The architect's discoverability design (§4) does NOT account for
  this — Layer 1 (trinity Key files) names the directory by full
  path; Layer 2 (per-entry HTML-comment) only matters once the agent
  is reading a per-entry file.
- For first-time-encountering-the-pack-repo agents, the leading-dot
  convention adds friction. A non-leading-dot `backlog/` directory
  at pack repo root (parallel to `BACKLOG.md` mirror) would be
  visible by default to `ls`, `find`, IDE file browsers.

**Should the integration architect have challenged the leading-dot?**
Arguably yes. The sidecar's rationale ("parallel to `.pack-tracker/`")
is a consistency argument, not a discoverability argument. Goal 1
favors visibility over consistency-with-existing-pack-state-dir.
The architect ratifies without surfacing this trade-off.

**Severity:** minor. The leading-dot convention is defensible
(consistency with `.pack-tracker/`); changing it now would cascade
through §3.1, §6.1 table rows, and migrator paths. Worth flagging
as a known trade-off in the integration doc, but not a re-design
trigger.

**Action:** flag for Pack Chat awareness; do not block on it.

### §9.3 — Net dimension verdict

**PASS.** The ratifications are substantively sound. One trade-off
(leading-dot convention vs Goal 1 discoverability friction) was not
surfaced in the architect's integration analysis. Minor.

---

## §10 — Architect-overreach scan

**Verdict: PASS.**

### §10.1 — Direct edits to PM-only files

Per §0 ("Out of scope acknowledgments"): "This integration doc does
NOT edit any PM-only file (BACKLOG / CHANGELOG / README / PACK-CHAT
/ PACK-AGENTS / CLAUDE / AGENTS / GEMINI / EXECUTION-PLAN-V11.0)."

Spot-checked: no Edit calls to PM-only files in the doc itself
(architect doc is in `maintenance-docs/v11-implementation/`, which
is workflow-artifact territory, not PM-only). Pack Chat ratifies; PM-
only edits surfaced as edit specifications (§5.3, §6.4, §6.5,
§17.4). The architect correctly avoids overreach.

**One borderline case:** §17.4 specifies the EXECUTION-PLAN-V11.0.md
edit ("Insert Batch 18 row in the §4 batch table"). This is a
specification, not an edit, but the specification is concrete
enough that a coder agent could apply it directly. Pack Chat is the
right applier per §17.4. **Sound.**

### §10.2 — v10 entry-format grammar changes

Per V3.1-DELTA §3 A2 invariant: zero entry-grammar changes allowed.

Spot-checked: the architect adds an HTML-comment back-pointer line
(§4.2 Layer 2) as line 1 of every per-entry file. The architect's
defense:
> "byte-additive on the v10 grammar (the v10 grammar rule per
> V3.1-DELTA §3 A2 is 'the entry STARTS with `**ID — Title**`'; the
> HTML-comment line is invisible to readers and to the v10 parser
> because HTML comments are not v10-entry tokens)."

**Verification:** the V3.1-DELTA §3 A2 invariant (per the doc's own
quoted citation) is "byte-additive: no field-label changes, no
state-vocabulary changes." An HTML comment is byte-additive in the
sense that it adds bytes without changing existing tokens. The
parser ignores it. **Acceptable interpretation of "byte-additive."**

**One concern:** the v10-grammar rule "the entry STARTS with `**ID
— Title**`" is now ALMOST true under per-entry decomposition (line 1
is the HTML comment; line 2 — if the file has no blank line — is
the bold header; if there's a blank line, line 3). The architect
should clarify whether line 1 vs line 2 vs line 3 matters for the
v10 parser. Per `_tar_read_entry_flat` at `tracker-agent-read.sh:153`,
reading happens by file content not by line number; the parser
should be unaffected. Nit.

### §10.3 — Other agents' permission boundaries

The architect's §6.4 PACK-AGENTS.md edit specification expands the
PM-only files list (signal 9 trip per §6.2). This is within the
explicit Goal 3 binding ("Mirror generator / TOC regenerator /
migrator MAY write — but only when triggered by Pack Chat / PM Chat
/ migrator"). The expansion narrows agent permissions, not widens
them. **Permission-boundary scan: clean.**

### §10.4 — Net dimension verdict

**PASS.** Architect-overreach is minimal. The HTML-comment back-
pointer is byte-additive in spirit and in fact. PM-only edits are
surfaced as specifications, not direct edits. Permission-boundary
changes are narrowing, not widening.

---

## §11 — Factual accuracy spot-check

**Verdict: PASS with one citation slip.**

### §11.1 — Sample 1: `_stage_backup` at `migrator-stages.sh:146`

**Claim** (§3.2, §8.18, §9.4): `_stage_backup()` is at
`scripts/lib/migrator-stages.sh:146`.

**Verified directly:**
```
$ grep -n "^_stage_backup()" scripts/lib/migrator-stages.sh
146:_stage_backup() {
```

**PASS.** Citation correct in all three locations.

### §11.2 — Sample 2: post-dispatch hook at `migrate-v10-to-v11.sh:134-149`

**Claim** (§3.1): "the v10→v11 migrator's existing
`migrator_post_dispatch_hook` at
`scripts/migrate-v10-to-v11.sh:134-149` gains a 6th sub-operation."

**Verified directly:** lines 130-149 of `migrate-v10-to-v11.sh` show
the hook function definition with 5 sub-ops at lines 144-148.

**PASS.** Citation accurate.

### §11.3 — Sample 3: `_migrator_run_stages` at `migrator-core.sh:212` + post-dispatch hook gate at line 222

**Claim** (§1.1 Inputs read): `_migrator_run_stages` at line 212;
optional `migrator_post_dispatch_hook` gate at line 222.

**Verified:** `grep -n "_migrator_run_stages\|migrator_post_dispatch_hook"
scripts/lib/migrator-core.sh` returns line 212 (`_migrator_run_stages`)
and line 222 (the hook gate). **PASS.**

### §11.4 — Sample 4: `customization_classify` at `customization-preserve.sh:145-179` with `generic` fall-through at line 178

**Claim** (§2.3, §13.1): classifier at lines 145-179 with `*) printf
'generic\n' ;;` fall-through at line 178.

**Not directly verified** in this review pass (file not opened), but
the claim is consistent with sidecar's prior verification at
`RESEARCH-PER-ENTRY-SPLIT.md` §5 (per the prior reviewer's spot-
check). **Provisional PASS** pending direct verification.

### §11.5 — Sample 5: `init-project.sh stage_s11_v11_artifacts` at line 803

**Claim** (§8.17): `stage_s11_v11_artifacts` at `init-project.sh`
line 803.

**Not directly verified** in this review pass. The prior reviewer
verified line 803 in their first-pass review (per the brief
context). **Provisional PASS.**

### §11.6 — Sample 6: highest BD verified at BD-163

**Claim** (§17.6): "highest existing BD in pack `BACKLOG.md` is
BD-163."

**Verified directly:**
```
$ grep -E "^\*\*BD-1[5-9][0-9]" BACKLOG.md | head -2
**BD-163 — CI repair: declare fixture dependencies ...
**BD-162 — Extend `deployment-python/SKILL.md` ...
```

BD-163 is the highest. **PASS.** BD-164..BD-170 are sequential and
non-colliding.

### §11.7 — Sample 7: validate-pack.py Check 3 at lines 262-281

**Claim** (§1.1 Inputs read): "Check 3 (`check_td_tbd_sentinels`,
lines 262–281)."

**Not directly verified** in this review pass; consistent with prior
research output. **Provisional PASS.**

### §11.8 — Sample 8: PACK-AGENTS.md PM-only files list at lines 139-142

**Claim** (§1.1 + §6.2): PACK-AGENTS.md PM-only files list at lines
139-142.

**Verified directly:** line 139 begins `**PM-only files** are off-
limits to all agents...`. **PASS.**

### §11.9 — Net dimension verdict

**PASS.** All directly-verifiable citations check out. Two
provisional-PASS items rely on prior review/research verification
which is consistent with the architect's claims. The integration
architect's self-verification of integration touchpoints holds up
under spot-check.

---

## §12 — Scope creep / focus drift audit

**Verdict: WEAK.**

### §12.1 — Naming specific function names / file paths the planner should pick

**Findings:**
- §3.1: "function name (provisional `_v10_to_v11_decompose_streams`
  per sidecar §1.3 — planner-owned naming; design-level reservation
  only)." — **Acceptable; explicitly defers to planner.**
- §7.3 step 3: "Sample shape: `bash scripts/lib/<helper>.sh
  regenerate-mirror /.backlog/` (planner picks exact name)." —
  **Acceptable; sample with explicit deferral.**
- §17.2 BD-164 File/Symbol: "scripts/lib/per-entry/decompose.sh,
  mirror-generate.sh, toc-regenerate.sh (planner picks file
  structure)." — **Acceptable; multiple options + explicit
  deferral.**
- §17.2 BD-167 File/Symbol: enumerates 6+ surfaces directly without
  "planner picks" qualifier. — **Mild over-specification, related
  to the BD-167 oversizing issue per §8.2.**
- §10.1 Check 32 function-shape Python pseudo-code: ~30 lines of
  near-implementation. — **Borderline; the pseudo-code is more
  detailed than necessary at architect-pass scope. Defensible as
  "implementable specification" per §7.4 above; minor over-
  specification.**

**Net:** mild over-specification in places, but mostly accompanied
by "planner picks" qualifiers. **Acceptable.**

### §12.2 — Authoring complete script implementations

**Findings:** §10.1 + §10.3 contain Python function pseudo-code with
specific control flow. None of it is complete script — all is
function-shape sketching. **Acceptable at architect-pass scope.**

§8.18 contains a sample post-report-hook advisory paragraph (~15
lines of prose). **Acceptable as edit specification with "planner
refines" deferral.**

§17.4 contains EXECUTION-PLAN-V11.0.md edit specification — edit
scope, not the literal text. **Acceptable.**

§5.3 contains a sample STATUS.md disclaimer. ~7 lines. **Acceptable
as edit specification with "planner can refine" deferral.**

§6.4 contains a PACK-AGENTS.md edit specification with sample shape.
**Acceptable.**

### §12.3 — Editing other docs

The integration architect doc itself does NOT edit other docs; per
§0 explicit out-of-scope acknowledgment. **Clean.**

### §12.4 — Net dimension verdict

**WEAK.** The integration architect occasionally over-specifies at
the boundary between architect-pass and planner-pass (BD-167 File/
Symbol enumeration, Check 32 pseudo-code). Most over-specification
is paired with explicit planner-deferral. The boundary discipline
is mostly maintained but could be tightened in a planner-friendly
direction.

---

## §13 — Final recommendation

**Recommendation: NEEDS-ANOTHER-ITERATION.**

### §13.1 — Blockers (must fix before planner)

1. **§17.1 batch positioning is factually wrong.** Batch 18 already
   exists in EXECUTION-PLAN-V11.0.md and is occupied by BD-111. The
   per-entry-split batch needs renumbering OR the existing Batches
   18+ need shifting. Cascade through §17 sub-sections (17.2, 17.3,
   17.4, 17.5, 17.7, 17.8). Fix path: one architect-pass refresh of
   §17 with corrected batch number; ~30 minutes.

### §13.2 — SHOULD-FIX (recommend fix before planner; not strictly blocking)

2. **§4.2 Layer 3 (`stream-discovery` skill) is scope creep.** Drop
   the new skill; trinity Key files line + per-entry HTML-comment
   back-pointer cover Goal 1 with two layers; the skill addition
   trips maintainability signals 5 + 6 for no incremental coverage.
   The architect's own §4.3 table admits Layers 1+2 suffice for
   every recovery scenario. **Recommend dropping Layer 3.**

3. **§6.4 PACK-AGENTS.md PM-only file expansion defense should be
   tightened.** The "refactor not expansion" framing obscures the
   honest fact that the protected surface grows by 5 directories.
   Recommend rewording the defense to "expansion required by Goal 3,
   defended per maintainability principle" — preserves the
   architect's intent without obscuring impact.

4. **§7.4 concurrent-write safety claim is incomplete.** The "git's
   normal merge-conflict mechanism" framing covers two-developer-on-
   different-machines but not the new race surface introduced by
   commit-time invocation: two pack-agent-spawned helpers in the
   same repo regenerating the mirror at near-identical times can
   produce divergent mirrors that don't conflict in git
   (deterministic mirror output) but also don't reflect the most
   recent state (one helper's regen output overwrites the other's).
   Recommend a one-paragraph addition naming this scenario and the
   recovery (re-run the regenerator from the latest working tree
   state). Severity: minor — the regenerator's idempotency means
   re-running fixes the divergence trivially.

5. **§10.6 project-side validator scope leaves Goal 2 enforcement
   gap.** The architect explicitly out-of-scopes project-side
   per-entry tree validation, leaving enforcement to "the mirror
   regenerator's idempotency" which is a property, not a check.
   Client projects without their own validator could have stale
   mirrors and Check 32 wouldn't fire. Recommend a one-paragraph
   addition naming this gap as a TRADEOFF (accepted scope
   limitation) or proposing the planner ship a `pack validate`
   verb that runs Check 32+33+34 against the client project's
   per-entry trees on demand.

6. **§17.2 BD-167 and BD-169 are oversized; commit 18b mixes
   PM-only and pack-product.** Split BD-167 into 2-3 narrower
   BDs; split BD-169's PM-only edits from pack-product edits.
   Restructure commits 18b accordingly so each is independently
   approve-able under §A.1 stop-before-commit.

### §13.3 — Minor / nits

7. §2.1 cost-savings claim uses 10ms/file constant that is likely
   5× too pessimistic; conclusion unaffected.
8. §4.4.1 inventory should explicitly verify `agent-run.sh`,
   `agent-post-edit-check.sh`, `OPTIONAL-FEATURES.md` are
   considered.
9. §5.1 source-of-truth declaration should add `recommendation-
   state` signals as a documented data class with canonical query
   path; `id-map.json` worth a one-line note.
10. §5.3 STATUS.md disclaimer application moment (project-init vs
    existing-project migration) needs one-line clarification.
11. §5.4 hand-edit-then-regenerate-then-commit silent-overwrite
    behavior should be named explicitly to prevent future "is this
    a bug?" questions.
12. §9.2 leading-dot directory naming convention vs Goal 1
    discoverability friction is a trade-off worth flagging for
    Pack Chat awareness.
13. §10.2 v10-grammar "starts with `**ID — Title**`" rule under
    HTML-comment-line-1 should clarify line-position invariance.
14. §17.6 BD-numbering audit is correct (BD-164..BD-170 sequential
    from BD-163); cross-reference to BD-135 (existing) and BD-136
    (existing per EXECUTION-PLAN) confirms no collision.

### §13.4 — Path forward

The integration architect doc is **substantively sound on
architecture** (REDESIGN-CORE is the right call; Goal 2 + 3 designs
are production-quality; 18 dispositions are correct). The doc
**fails on integration into v11.0** (Batch 18 collision is a
factual error, BD sizing is mixed, commit boundaries are not all
independently approve-able).

**Estimated rework effort:** 4-8 hours by the same integration
architect. Specifically:
- Renumber the per-entry-split batch to a free slot (or recommend
  Pack Chat shift Batches 18+ — Pack Chat decides the actual
  number); update §17.1 / 17.2 / 17.3 / 17.4 / 17.5 / 17.8.
- Drop Layer 3 (`stream-discovery` skill) from §4.2; update §4.4.2,
  §6.4 trinity edit cascade, §17.2 BD-167 scope, §17.3 commit 18b.
- Split BD-167 into 2-3 narrower BDs (§17.2 table; §17.3 commits).
- Split BD-169's PM-only edits from pack-product edits.
- Tighten §6.4 PACK-AGENTS.md defense framing.
- Add one paragraph each to §7.4 (concurrent-write race) and §10.6
  (project-side validator scope gap).
- Add minor clarifications for nits 7-14.

After the rework, **APPROVE-FOR-PRIMARY-CHAT-PLANNER** is the
expected outcome. The architecture is sound; the integration needs
one focused pass to land.

### §13.5 — Live agents available for clarification (per brief)

If the integration architect would benefit from clarification rather
than blind rework, SendMessage targets per the brief:
- Integration architect (`aaa27956cf162a18b`) — confirm batch
  positioning error; agree on renumber path.
- Pack Chat — confirm whether to renumber per-entry-split batch or
  shift existing 18+; clarify STATUS.md application moment.

This reviewer recommends Pack Chat have the conversation with the
integration architect directly via SendMessage to resolve the
blocker, then have the architect ship the §13.4 rework in one
pass.

---

## §14 — Final-line marker

REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-COMPLETE: 2026-05-13
— Fresh primary-chat reviewer (no prior session context) over
ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (3,477 lines). 12
dimensions evaluated: §1 disposition correctness PASS, §2 REDESIGN-
CORE PASS, §3 three frictions PASS, §4 Goal 1 discoverability WEAK
(Layer 3 scope creep), §5 Goal 2 source-of-truth PASS, §6 Goal 3
read/write audit PASS, §7 validator new-checks PASS, §8 execution
plan integration FAIL (BLOCKER — Batch 18 collision), §9 sidecar
cascade PASS (one missed-challenge: leading-dot discoverability
trade-off), §10 architect-overreach PASS, §11 factual accuracy
PASS, §12 scope creep WEAK. Recommendation: NEEDS-ANOTHER-ITERATION
— one BLOCKER (batch positioning) + 5 SHOULD-FIX (Layer 3 scope
creep, PACK-AGENTS framing, concurrent-write race, project-side
validator gap, BD-167/169 oversizing) + 8 minor nits. Estimated 4-8
hour rework by same integration architect; APPROVE-FOR-PRIMARY-
CHAT-PLANNER expected after rework. Architecture substance is
sound; integration into v11.0 plan needs corrected batch number and
tightened BD/commit sizing.
