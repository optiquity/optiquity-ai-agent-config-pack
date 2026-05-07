# MAINTAINER CHECK NEEDED — audit at HEAD `f2d603e`

Audit of every `MAINTAINER CHECK NEEDED` item in the v11 plan + addenda
(§6.A through §6.R). For each item: current state, classification
(state-verifiable / judgment / already-resolved), and disposition.

Performed: 2026-05-07. Triggered by: BD-091 verification batch + the
`pack-planner` role-policy update at `.claude/agents/pack-planner.md`
that prohibits punting state-verifiable questions to MAINTAINER CHECK.

---

## §6.A — Multi-template-version fixture stubs at v11.0 cut

**Source:** `IMPLEMENTATION-PLAN.md` line 198, line 1056.
**State-verifiable.** Verification: `ls scripts/tests/fixtures/roundtrip/`.
**Result:** `bd-v11.0/` (real fixtures), `bd-v11.1/` (README only),
`bd-v11.2/` (README only) all present. Matches plan's stated v11.0
ship state ("v11.0 ships with stub directories that are exercised
when later minors add real entries").
**Disposition: RESOLVED — stubs in place per plan; future minors
populate when shipping.**

## §6.B — `scripts/pack-help.sh` provenance

**Source:** `IMPLEMENTATION-PLAN.md` line 353, line 1061.
**State-verifiable.** Verification: `ls scripts/pack-help.sh`.
**Result:** File exists (shipped in BD-075, commit `ef4e584`).
**Disposition: RESOLVED — shipped new in BD-075. V3 §I.3's
"preserved-from-V2" wording was inaccurate; the file did not exist
in v10 and was created at v11.**

## §6.C — Next free `validate-pack.py` Check number

**Source:** `IMPLEMENTATION-PLAN.md` line 425, line 1066, line 997.
**State-verifiable.** Verification:
`grep -cE "^def check_" scripts/validate-pack.py`.
**Result:** 22 `check_*` functions currently defined. v11 checks
named in the plan (BD-078 Check 19, BD-079 Check 20, BD-082 Checks
21–24, BD-089 Check 25) will land at the next contiguous integers
**23 onward** (not at 19–25 as the plan labels suggest). Plan's
§6.O.1 already documents this — pedagogical numbers ≠ actual
numbers; check NAMES are stable.
**Disposition: RESOLVED — BD-082 / BD-078 / BD-079 / BD-089
implementations re-number to next-free-integer at land-time. Names
authoritative: `check_tracker_config`, `check_recommendation_state_schema`,
`check_per_cli_pack_help_parity`, `check_help_fragment_freshness`,
`check_help_fragment_completeness`, `check_help_fragment_byte_identity`,
`check_customization_detection_regression_guard`.**

## §6.D — BD-042 scope at v11

**Source:** `IMPLEMENTATION-PLAN.md` line 684, line 690, line 1071.
**State-verifiable.** Verification:
`find project-template -maxdepth 1 -name '*.md'`.
**Result:** project-template root contains only trinity (CLAUDE,
AGENTS, GEMINI) + README. The 3 named pack reference docs
(PM-CHAT, PLATFORM-SKILLS, PACK-FEEDBACK) are at
`project-template/docs/pack/` (relocated in v9.2, commit `fb434a1`).
METHODOLOGY.md correctly lives at `supporting-docs/METHODOLOGY.md`
per V10-DESIGN §7.6 and is copied at install time. PROMPT-TEMPLATES.md
was removed in v10.0.
**Disposition: RESOLVED — verification-only no-op. BD-091 +
BD-042 both flip to Resolved in this batch.**

## §6.E — Pack-repo trinity exemption from `## Document locations`

**Source:** `IMPLEMENTATION-PLAN.md` line 1076.
**Already resolved by recommendation.** Plan's own recommendation:
"defer; honor V3 D-6 as stated." V3 D-6 says the Source column applies
to project-template trinity only.
**Verification:** `grep -l "## Document locations" CLAUDE.md AGENTS.md
GEMINI.md` returns empty.
**Disposition: RESOLVED — pack-repo trinity correctly omits the
section per D-6.**

## §6.F — Pack-root pack-startup skill location

**Source:** `IMPLEMENTATION-PLAN.md` line 1078.
**State-verifiable.** Verification: `ls -d .claude/skills/pack-startup
.codex/skills/pack-startup .gemini/commands/pack-startup.toml`.
**Result:** All three present (created in BD-074, commit `0d62429`).
**Disposition: RESOLVED — BD-074 created the directories; pack-side
parity matches V3 §I.2.**

## §6.G — Dry-run report freshness window for `--apply` (BD-095)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM.md` line 431.
**Judgment.** UX call: 24-hour window vs longer/configurable.
**Disposition: DEFER — resolves at BD-095 implementation. Not
state-verifiable.**

## §6.H — `--resume` resolved-flag detection mechanism (BD-095)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM.md` line 437.
**Judgment.** UX call: companion `.resolved` flag-file vs removal of
`.merge-conflict` extension.
**Disposition: DEFER — resolves at BD-095 implementation.**

## §6.I — BD-097 audit invocation: pack-reviewer vs ad-hoc

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM.md` line 443.
**Premise invalidated.** §6.I states: "The base plan does not commit
a `pack-reviewer` agent in v11."
**Reality at HEAD `f2d603e`:** `pack-reviewer` exists at
`.claude/agents/pack-reviewer.md` (Codex / Gemini equivalents at
`.codex/agents/pack-reviewer.toml` / `.gemini/agents/pack-reviewer.md`)
and has been used as the standard reviewer agent throughout v11
implementation (BD-060..BD-077 review passes).
**Disposition: PARTIALLY RESOLVED — pack-reviewer is available.
BD-097's invocation can default to `pack-reviewer`. Final choice
deferred to BD-097 implementation, but the §6.I premise (no
pack-reviewer in v11) is no longer valid.**

## §6.J — Ship v11.0 in tracker mode or flat-file mode (BD-102)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-2.md` line 281.
**Judgment.** Ship-time decision: should the v11.0 release pin ship
the pack-repo itself in tracker mode (dog-food) or flat-file mode?
**Disposition: DEFER — resolves at BD-102 / BD-093 ship pin.**

## §6.K — Exact confirm-flag for `pack tracker reset` (BD-103)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-2.md` line 287.
**Judgment.** UX call: exact spelling of the confirmation flag.
**Disposition: DEFER — resolves at BD-103 implementation.**

## §6.L — STATUS.md template provenance

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-3.md` line 222.
**State-verifiable.** Verification: `find project-template -name
'STATUS*.md'` → zero hits.
**Result:** No `STATUS.md` template exists. Matches §6.L stated state:
"STATUS.md is created at project init by PM-chat-driven setup per
METHODOLOGY.md." This is the documented v10 design; no template file
was intended.
**Disposition: RESOLVED — confirms current architecture. BD-105's
`MIGRATION-v10-to-v11.md` Phase B documents the dual-link rendering
without a template file.**

## §6.M — Pack-side `pack-auditor` per-CLI replication

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 812, line 14.
**State-verifiable (layout) + judgment (intent).** Verification:
`ls .claude/agents/pack-*.md .codex/agents/pack-*.toml
.gemini/agents/pack-*.md`.
**State result:** Pack-side IS per-CLI replicated. All 4 existing
pack agents (architect, docs-researcher, planner, reviewer) ship
across `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` (12
files total). V3.3 §8.4's claim "pack-side `pack-auditor.md` is
single-CLI (pack development is Claude-Code-primary)" contradicts
the existing pack-side layout.
**Plan's recommendation:** option (a) — adopt per-CLI replication
for `pack-auditor` to match the existing layout.
**Disposition: PARTIALLY RESOLVED — state confirms per-CLI is the
existing pattern. Plan's recommended option (a) (per-CLI) is the
default for BD-110. Maintainer can override at BD-110 land-time;
absent override, BD-110 ships per-CLI to match.**

## §6.N — Pack-side `audit-methodology` + `architecture-review` skills

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 257, line 818.
**State-verifiable.** Verification: `ls -d .claude/skills/X
.codex/skills/X .gemini/skills/X` for X in
{audit-methodology, architecture-review}.
**Result:**
- `architecture-review`: PRESENT in all 3 CLIs at pack root.
- `audit-methodology`: ABSENT in all 3 CLIs at pack root.

BD-074's actual ship set was pack-startup only — it did NOT include
audit-methodology or architecture-review. Plan's option (a)
("BD-074 ships audit-methodology and architecture-review at pack
root") was not honored at BD-074 land-time.
**Disposition: STATE-RESOLVED — `architecture-review` is at pack
root (provenance unclear; not from BD-074); `audit-methodology` is
absent. BD-110 (pack-auditor) MUST ship `audit-methodology` at pack
root in its commit. `architecture-review` is already in place; no
action.**

## §6.O — Check 28 redundancy with existing per-CLI parity check

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 824, line 631.
**State-verifiable.** Verification:
`grep -E "def check_" scripts/validate-pack.py | grep -iE "trinity|parity|cli"`.
**Result:** Generic checks present include
`check_pack_agent_trinity`, `check_tool_config_capability_parity`,
`check_trinity_h2_parity`. The first two cover per-CLI agent file
parity already. Per §6.O resolution path: "If yes [generic check
exists], Check 28 reduces to a list-extension."
**Disposition: RESOLVED — Check 28 in BD-082 reduces to extending
`check_pack_agent_trinity`'s name list (or a sibling) to cover
`auditor-issue-tracking.md`. No new function needed.**

## §6.O.1 — Check 25 numbering collision (BD-089 vs Addendum-4 §3.1)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 829.
**Already resolved by recommendation.** Per the recommendation:
numbers are pedagogical references; function NAMES are stable.
Numbering re-assigned to contiguous next-free integer at BD-082 +
BD-089 land-time.
**Disposition: RESOLVED — names authoritative; numbers float.**

## §6.P — Architect-default for Path 1 (BD-107)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 832.
**Judgment.** Design decision: architect-default vs allow opt-out.
**Disposition: DEFER — resolves at BD-107 implementation.**

## §6.Q — Cycle-check K-value (BD-108)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 837.
**Judgment.** Default value for `tracker.toml [graph] cycle_check_k`.
**Disposition: DEFER — resolves at BD-108 implementation. Plan
recommends K=10 as default with configurability.**

## §6.R — Sidecar `dependency_edges` annotation preservation (BD-108)

**Source:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 843.
**Judgment.** Design decision: preserve free-text annotation
after matched ID prefix in `Dependencies` bullet, or drop on
round-trip?
**Disposition: DEFER — resolves at BD-108 implementation. Plan
recommends preserve.**

---

## Summary

| Class | Count | Items |
|---|---|---|
| Resolved by prior implementation | 3 | §6.B, §6.D, §6.F |
| Resolved by plan recommendation | 3 | §6.E, §6.O.1, §6.O |
| Resolved by state verification (this audit) | 5 | §6.A, §6.C, §6.L, §6.M (state part), §6.N |
| Premise invalidated (action item produced) | 1 | §6.I (pack-reviewer now exists; BD-097 can use it) |
| Genuine maintainer judgment, deferred to future BD | 7 | §6.G, §6.H, §6.J, §6.K, §6.M (intent), §6.P, §6.Q, §6.R |

**Action items produced by this audit (besides BD-091/BD-042 resolution):**

1. **BD-110 must ship `audit-methodology` skill at pack root** in all
   three CLI variants (`.claude/skills/`, `.codex/skills/`,
   `.gemini/skills/`). `architecture-review` is already in place.
   Source: §6.N state verification.

2. **BD-097 invocation can default to `pack-reviewer`** (now
   available; §6.I premise invalidated).

3. **BD-082 Check-28 implementation reduces to a list-extension** of
   the existing generic `check_pack_agent_trinity` (or sibling), not a
   new function. Source: §6.O state verification.

4. **All v11 validate-pack Checks re-number to next-free integer**
   (currently 23+) at BD-078 / BD-079 / BD-082 / BD-089 land-time.
   Names authoritative, not numbers.

These four are recorded here so the relevant BD implementations don't
re-litigate them.

## Process implication

This audit was triggered by the realization that `pack-planner`'s
default behavior — emitting `MAINTAINER CHECK NEEDED` for any
question it cannot answer from architecture docs alone — has been
producing checks for state-verifiable questions that read-only tools
could have resolved at planning time. The agent file at
`.claude/agents/pack-planner.md` was hardened in commit (this batch's
agent-policy edit) to require state verification before punting.

Going forward: state-verifiable questions are not MAINTAINER CHECK
items; the planner verifies via Read/Grep/Glob/Bash and writes BD
scope reflecting actual current state. MAINTAINER CHECK NEEDED is
reserved for genuine judgment / intent / future-decision questions.
