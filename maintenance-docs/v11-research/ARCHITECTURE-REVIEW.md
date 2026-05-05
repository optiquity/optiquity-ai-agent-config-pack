# v11 Architecture Review — Independent Audit

**Reviewer.** pack-reviewer agent.

**Subject.** `maintenance-docs/v11-research/ARCHITECTURE-V3.md` (the
current architecture), with V1 (`ARCHITECTURE.md`) and V2
(`ARCHITECTURE-V2.md`) as preserved historical context.

**Date.** 2026-04-30.

**Inputs read.** `DESIGN-BRIEF.md`; `ARCHITECTURE-V3.md`;
`ARCHITECTURE-V2.md`; `ARCHITECTURE.md` (V1); `EXTERNAL-RESEARCH.md`;
`INTERNAL-INVENTORY.md`; `RESEARCH-AUDIT.md`. Plus selected
ground-truth checks against the live pack repository (`scripts/`,
trinity files, skill directory layout, LICENSE.md) and three live
per-CLI documentation fetches (Claude Code skills doc, Codex
`slash_command.rs`, Gemini CLI `custom-commands.md`).

**Methodology.** `review` skill (correctness / regression /
architecture compliance) and `architecture-review` skill (layer
discipline / state ownership / abstraction quality), applied to a
documentation deliverable rather than executable code. Findings cite
section + line range when load-bearing. No re-design proposed; where
the architecture is wrong, the wrongness is documented and referred
back.

---

## §1. Executive summary

**Overall verdict: `approve-with-changes`.**

The V3 architecture is substantively correct, faithful to the brief,
and largely ready for the planner. V1 + V2 + V3 form a coherent
design package that resolves all 20 OQs, defends D-19 and D-20 with
research-backed reasoning, and respects the brief's hard
constraints (out-of-scope items, LCD parity, refusal-respecting
recommendation, reverse-migration mandatory). The per-CLI
documentation defense in V3 §28.2.2 is verifiable (I spot-checked
all three CLIs against live docs; the citations hold).

However, the architecture has **four correctness-class issues** the
maintainer must address before planner spawn — chiefly a Codex skill
file-format error that propagates through V3 §28.2.3, §A.1, §I.1,
§I.4 (V3 ships `.codex/skills/pack-help.toml` but the documented
Codex-skills convention used everywhere else in the pack is
`.codex/skills/<name>/SKILL.md`); a stale validate-pack check-number
citation in V1 §3.3 and V1 §17.1 R10 (cites Check 17 for
`check_trinity_h2_parity`, but the function is Check 18 in
`scripts/validate-pack.py`); a §0.6 / §28.1 internal contradiction
where V3 says "The verb spellings in V2 §22.1" are unchanged but
D-19 adds `pack tracker enable-recommendations` and D-20 adds
`pack help` — both new verbs not in V2 §22.1; and a Codex-CLI help
discoverability gap that V3 acknowledges but does not fully
mitigate (a Codex user with no skills installed has only the static
greeting text "run `pack help`" as their path; there is no
discoverable CLI-native verb path).

The remaining findings are **warnings** (e.g., the citation slip in
"audit §A.5 token-cost crossover" — the inflection number is from
EXTERNAL-RESEARCH §6, not audit §A.5; D-6 ambiguity about pack-repo
trinity scope), **clarity-for-planner** issues (the architectural
relationship between pack-repo `HELP-FRAGMENT-PACK.md` and the
client-template-located `HELP-FRAGMENT-TRACKER.md` is awkward but
unaddressed), and one **risk-completeness** gap (V3 §17 R15–R17 do
not address an obvious failure: a user on a corrupted state file who
hits R16 may then get re-prompted on the same session within the
same chat process — V3 doesn't say whether the reset state survives
the session).

**Reading path for the maintainer.**

If the verdict is acceptable and the goal is to spawn the planner
quickly:

1. Read §3.1 (Codex skill format error — easy fix; affects
   §28.2.3, §A.1, §I.1, §I.4 and validate-pack Check 21 design).
2. Read §3.2 (validate-pack check number citation — easy fix in
   V1 §3.3 and V1 §17.1 R10).
3. Read §3.3 (verb-spelling contradiction in §0.6 vs D-19 / D-20).
4. Read §3.4 (Codex `/help` discoverability gap — design-level;
   may need architect re-spawn).
5. Skim §3.5 onwards (warnings) and §4 (missed risks) for
   completeness.

If the verdict's force is "needs revision before planner": the
single design-level issue is §3.4. The other three are textual
corrections the maintainer can apply directly without architect
re-spawn.

---

## §2. Five-level verdict tables

### §2.1 Overall verdict

| Aspect | Verdict | Rationale |
|---|---|---|
| The architecture as a whole | `approve-with-changes` | The V3 design (and the V1/V2 substrate it preserves) is substantively correct and faithful to the brief. Four findings require maintainer action before planner spawn — three are textual / format errors fixable without architect re-spawn; one (Codex `/help` gap) is design-level and may need architect attention. None invalidate the architecture's core decisions (D-1..D-20). |

### §2.2 Per-concern-axis verdicts

| Axis | Verdict | One-line finding |
|---|---|---|
| Consistency | `pass-with-note` | §0.6 says "verb spellings in V2 §22.1 unchanged" but D-19 adds `pack tracker enable-recommendations` and D-20 adds `pack help` — both new verbs (see §3.3). |
| Brief faithfulness | `pass` | All 6 priorities and all 20 OQs addressed; all hard constraints (§1 out-of-scope; §3.1 LCD parity; §3.1 reverse-migration mandatory; §6.5 naming convention; §3.4 P6 refusal-respecting) honored. |
| Research faithfulness | `pass-with-note` | Constraints from EXTERNAL-RESEARCH and RESEARCH-AUDIT respected. One citation slip ("audit §A.5" cited for the ~50–100 issues inflection, which is in EXTERNAL §6.1; audit §A.5 verifies §6's costs but does not itself state the inflection — see §3.6). |
| Decision rigor | `pass` | D-19 thresholds tied to OT scale baseline + audit findings; D-20 path forced by per-CLI documentation evidence (verifiable; spot-checked). All other decisions reaffirmed from V1/V2 with stated reason. |
| Risk completeness | `pass-with-note` | R15–R17 cover the obvious new failure modes. One gap noted: the in-session implication of an R16 corrupted-state recovery is unspecified (see §4.1). |
| Clarity for planner | `pass-with-note` | Most sections are concrete enough for BD breakdown. The HELP-FRAGMENT layout (pack-root file depending on a `project-template/`-located fragment) and the V3 Codex-skill format question (see §3.1) require clarification before the planner builds Check 21. |
| Trinity rule | `pass-with-note` | V3 §28.2.5 correctly extends the trinity rule to the per-CLI command files. D-6 is silent on whether the Source-column addition to `## Document locations` applies to the pack-repo trinity (which has no such section today); see §3.7. |
| License interaction | `pass` | V1 §11 / D-13 correctly characterize LICENSE.md §3.3. The recommendation-state file (V3 D-19) is correctly identified as machine-local and not crossing the SaaS boundary. |
| Cross-CLI parity | `pass-with-note` | LCD floor preserved (`gh` shell-out for tracker; `pack help` shell verb for help). One gap: the per-CLI namespaced `/pack-help` is documented for Claude / Codex / Gemini but the Codex implementation uses a file format the rest of the pack does not use (see §3.1 + §3.4). |


### §2.3 Per-section verdicts (V3 sections + appendices)

V3 explicitly preserves V1 §§1–15 (via V2) and V2 §§16–22, 24–26 unchanged.
Verdicts marked "preserved-OK" mean the V2 design holds for V3's purposes;
findings against the preserved content are still raised when relevant.

| V3 section | Verdict | One-line finding |
|---|---|---|
| §0 Change log V2→V3 | `approve` | Accurate index of what V3 changes vs preserves. |
| §1 Architectural overview (V1, preserved) | `approve` (preserved-OK) | Provider abstraction shape stable across V1/V2/V3. |
| §2 Provider abstraction (V1, preserved) | `approve` (preserved-OK) | 18 ops + capability flags + open-string `link.kind` + raw escape hatch — matches audit §A.9 requirements. |
| §3 Tracker config / detection (V1, preserved) | `approve-with-changes` (preserved) | V1 §3.3 cites `validate-pack Check 17 (check_trinity_h2_parity)` — the function is at Check 18 in `scripts/validate-pack.py`; minor textual fix (§3.2). D-6 silent on pack-repo trinity scope (§3.7). |
| §4 Issue template schemas (V2, preserved) | `approve` (preserved-OK) | D-4-V2 form-family defended in §24. |
| §5 Dependency model (V1, preserved) | `approve` (preserved-OK) | 3-level cap matches Jira free's hard floor (audit §B.1). |
| §6 Migration algorithm (V1 + V2 §6.2 addendum, preserved) | `approve` (preserved-OK) | Idempotent forward + reverse mandatory. |
| §7 Chat orchestration (V1, preserved) | `approve` (preserved-OK) | — |
| §8 Agent reads (V1, preserved) | `approve` (preserved-OK) | LCD `gh` universal; MCP optional. |
| §9 Failure UX (V1, preserved) | `approve` (preserved-OK) | Typed errors, no silent retry — matches D-7. |
| §10 External triage (V1, preserved) | `approve` (preserved-OK) | — |
| §11 License (V1, preserved) | `approve` (preserved-OK) | Spot-checked against LICENSE.md §3.3 lines 110–138; characterization correct. |
| §12 Token economy (V1, preserved) | `approve` (preserved-OK) | Side-effect, not gating. |
| §13 Per-CLI matrix (V1, preserved) | `approve` (preserved-OK) | Codex `max_threads = 6` correctly noted (per audit §A.1 correction). |
| §14 Tracker compatibility (V1, preserved) | `approve` (preserved-OK) | — |
| §15 Pre-existing tracker (V1, preserved) | `approve` (preserved-OK) | D-12 deferred per brief OQ-12 latitude. |
| §16 Decisions table (V3) | `approve-with-changes` | Accurate index. The "no V2 decision is superseded" claim in §0.2 is correct. D-19 / D-20 well-formed. See §3.3 about V3 §0.6's verb-spelling claim vs new verbs introduced. |
| §17 Risks (V3 update) | `approve-with-changes` | R15 / R16 / R17 are well-stated. R16 has an editorial fragment ("If the project moves between machines (clone, fresh worktree), the file is in git? — **No.**") — minor nit; one missing risk noted in §4.1. |
| §18 P1 lifecycle (V2, preserved) | `approve` (preserved-OK) | Comprehensive state machines per entry type. |
| §19 P2 maintenance (V2, preserved) | `approve` (preserved-OK) | `pack tracker update-templates` + archive directory. |
| §20 P3 backend extensibility (V2, preserved) | `approve` (preserved-OK) | Backend contract documented; conformance harness specified. |
| §21 P4 auditability (V2, preserved) | `approve` (preserved-OK) | `provider.list_events()` extension; query patterns. |
| §22 P5 verb surface (V2, preserved verbatim) | `approve-with-changes` | V2 §22.1 lists 9 verbs. V3 §0.6 says verb spellings unchanged, but D-19 + D-20 + V3 §28.2.1 introduce two new verbs (`pack tracker enable-recommendations`, `pack help`). The §22 surface is silently extended; V3 should note that §22's "9-verb surface" sentence is now an "11-verb surface" (or have V3 revise §22 explicitly). See §3.3. |
| §23 (V2 Discoverability replaced) | `approve` | Pointer-only section is appropriate; preserves V2 §23 by reference. |
| §24 OQ-16 multi-template defense (V2, preserved) | `approve` (preserved-OK) | — |
| §25 OQ-17 structure-vs-free-text (V2, preserved) | `approve` (preserved-OK) | — |
| §26 OQ-18 template_version dual-carrier (V2, preserved) | `approve` (preserved-OK) | — |
| §27 P6 (revised) discoverability + proactive guidance | `approve` | Hybrid Layer 1+2+3 design well-justified; §27.4 coexistence model concrete. |
| §28.1 OQ-19 inflection signals + thresholds | `approve-with-changes` | Signals + thresholds tied to research data. Citation slip: §28.1 / §B.1 / §B.3 cite "audit §A.5 token-cost crossover at ~50–100 issues" but the inflection is in EXTERNAL-RESEARCH §6.1 / §6.6 (audit §A.5 verifies §6's plausibility). See §3.6. |
| §28.2 OQ-20 help-verb scope, naming, content | `approve-with-changes` | Verb-list manifest correct. Per-CLI documentation defense rigorous and verifiable (spot-checked). Codex skill file format wrong (§3.1). Codex discoverability gap (§3.4). |
| Appendix A V3 deltas (artifact list) | `approve-with-changes` | Lists `.codex/skills/pack-help.toml` — wrong format (§3.1). Otherwise complete. |
| Appendix B V3 deltas (citations) | `approve` | Per-CLI doc citations match live-doc spot-check. |
| Appendix C V3 traceability | `approve` | Mechanical, accurate. |
| Appendix D Worked examples | `approve` | D.1–D.12 are useful as planner test fixtures. |
| Appendix E Per-CLI doc cross-check | `approve` | Verbatim quotes verified against live docs (Gemini custom-commands.md; Codex slash_command.rs; Claude Code skills page). All three citations current as of 2026-04-30 spot-check. |
| Appendix F Conformance with brief | `approve` | All priorities and success criteria mapped. |
| Appendix G Reading path | `approve` | — |
| Appendix H Alternatives considered | `approve` | Rejected-alternative documentation aligns with `architecture-review` skill's expectation. |
| Appendix I Implementation surface | `approve-with-changes` | Lists `.codex/skills/pack-help.toml` and `.codex/skills/pack-startup.toml` — both wrong format (§3.1). |
| Appendix J V3 vs V2 gap analysis | `approve` | Accurate map of which V2 elements are preserved vs revised. |
| Appendix K Glossary | `approve` | — |

### §2.4 Per-decision verdicts

| Decision | Verdict | One-line rationale |
|---|---|---|
| D-1 (provider surface) | `matched-rationale` | Op set tied to audit §A.9 requirements + EXTERNAL §8.5–8.6. |
| D-2 (tracker.toml) | `matched-rationale` | "One file = one decision" preserved; recommendation-state correctly separated (V3 §28.1.4). |
| D-3 (tracker-migrate.sh) | `matched-rationale` | LCD bash works on all three CLIs. |
| D-4-V2 (two-form family) | `matched-rationale` | §24 defense covers all axes the brief enumerated for OQ-16. |
| D-5 (mode detection) | `matched-rationale` | One signal, one place; the recommendation-state read is non-mutating to mode declaration. |
| D-6 (Source column in trinity) | `weak-rationale` | Rationale solid for project-template trinity. **Pack-repo trinity has no `## Document locations` section** today; D-6 is silent on whether the addition applies pack-side. See §3.7. |
| D-7 (failure UX) | `matched-rationale` | Recommendation-state failure modes (§28.1.4) honor no-silent-retry. |
| D-8 (reverse migration) | `matched-rationale` | Recommendation-state preservation across migrations explicit. |
| D-9 (agent reads LCD) | `matched-rationale` | — |
| D-10 (single `gh auth`) | `matched-rationale` | — |
| D-11 (PACK-FEEDBACK upstream) | `matched-rationale` | — |
| D-12 (pre-existing tracker deferred) | `matched-rationale` | Brief allows; rationale clear. |
| D-13 (license) | `matched-rationale` | Recommendation-state file correctly identified as machine-local. |
| D-14 (external triage) | `matched-rationale` | — |
| D-15 (token measurement post-shipping) | `matched-rationale` | Distinction between post-opt-in verification (D-15) and pre-opt-in recommendation (D-19) explicit. |
| D-16 (form-family canonical) | `matched-rationale` | — |
| D-17 (structure-vs-free-text) | `matched-rationale` | — |
| D-18 (template_version dual carrier) | `matched-rationale` | — |
| D-19 (signals + thresholds + state file + state machine) | `matched-rationale` | Thresholds tied to OT scale baseline + audit findings. The 25% growth window (§28.1.5 Guard 4) prevents oscillation re-fires; the OR-logic across signals (§28.1.3) is justified. The state-machine (§28.1.6) is small and correct. |
| D-20 (help-verb scope, naming, per-surface content) | `matched-rationale` | Per-CLI documentation defense (§28.2.2 + §E) is the load-bearing logic; the brief's directive ("if not best-practice across all three, prefer (b)") forces the choice. Spot-checked: 1 of 3 CLIs (Gemini) documents augmentation; choice (b) is therefore correct per the brief's directive. |

### §2.5 Per-priority verdicts

| Priority | Verdict | Rationale |
|---|---|---|
| P1 Entry lifecycle completeness | `addressed` | V2 §18 covers all 6 entry types with explicit state machines, comment-prefix conventions, deprecation-vs-cancellation rule, and deletion stance (`provider.delete()` not in op set; escape via `raw()`). |
| P2 Maintenance ergonomics | `addressed` | V2 §19 designs `pack tracker update-templates`, archive directory, translation manifest, cadence rules; V3 §27.4.4 adds maintenance cadence for help fragments. |
| P3 Backend extensibility ergonomics | `addressed` | V2 §20 provides file-layout, required interface methods, capability declaration shape, conformance test suite, sample Linear backend, tier-of-support graduation rules. |
| P4 Auditability | `addressed` | V2 §21 designs `provider.list_events()`, audit-query patterns, per-backend resolution, retention. |
| P5 Cognitive load floor | `partially-addressed` | V2 §22 lists 9 verbs and justifies each; V3 adds two more (D-19 `pack tracker enable-recommendations`, D-20 `pack help`) without folding them into §22's verb table. The "9-verb surface" claim in V2 §22 is silently broken. See §3.3. |
| P6 (revised) Discoverability + proactive guidance | `addressed` | V3 §27 (three-layer surface + hybrid balance + refusal-respecting + coexistence model) and V3 §28.1 / §28.2 (concrete decisions). All three new §4.1 success criteria mapped via Appendix F. |

### §2.6 Per-OQ verdicts

| OQ | Verdict | Rationale |
|---|---|---|
| OQ-1 (provider surface shape) | `resolved` | D-1 + V1 §2. |
| OQ-2 (config location) | `resolved` | D-2 + V1 §3.1. |
| OQ-3 (migration command surface) | `resolved` | D-3 + V1 §6.1 + V2 §22. |
| OQ-4 (issue template schema) | `resolved` | D-4-V2 + V2 §4 + §24. |
| OQ-5 (mode detection) | `resolved` | D-5 + V1 §3.2. |
| OQ-6 (trinity Document locations interaction) | `partially-resolved` | D-6 + V1 §3.3. Resolution clear for project-template trinity; pack-repo trinity scope ambiguous (see §3.7). |
| OQ-7 (failure UX) | `resolved` | D-7 + V1 §9. |
| OQ-8 (reverse migration) | `resolved` | D-8 + V1 §6.5–6.7. |
| OQ-9 (agent read mechanism) | `resolved` | D-9 + V1 §8. |
| OQ-10 (auth surface) | `resolved` | D-10 + V1 §7.3. |
| OQ-11 (PACK-FEEDBACK upstream wiring) | `resolved` | D-11 + V1 §7.5. |
| OQ-12 (pre-existing tracker integration) | `resolved` | D-12 (deferred per brief allowance). |
| OQ-13 (license interaction) | `resolved` | D-13 + V1 §11. Spot-checked against LICENSE.md §3.3. |
| OQ-14 (external-issue triage) | `resolved` | D-14 + V1 §10 + V2 §18.2. |
| OQ-15 (token-economy measurement) | `resolved` | D-15 + V1 §12. |
| OQ-16 (multi-template strategy) | `resolved` | D-16 + V2 §24 (defended on every axis the brief specified). |
| OQ-17 (structure vs free-text) | `resolved` | D-17 + V2 §25. |
| OQ-18 (`template_version` placement) | `resolved` | D-18 + V2 §26 (dual carrier defended). |
| OQ-19 (inflection-point signals + thresholds) | `resolved` | D-19 + V3 §28.1. |
| OQ-20 (help-verb scope, naming, discoverability) | `resolved` | D-20 + V3 §28.2 + Appendix E. |



---

## §3. Detailed findings

Each finding lists what the architecture says, why it's a problem,
the source of truth, and severity. Severity scale:

- **`blocker`** — planner spawn must wait until addressed.
- **`warning`** — planner can proceed but architect / maintainer
  should address.
- **`nit`** — cosmetic / writing-style.

### §3.1 Codex skill file format error

**What the architecture says.** V3 §28.2.3 (lines ~1244–1248)
specifies the Codex per-CLI implementation file as
`~/.codex/skills/pack-help.toml` and `.codex/skills/pack-help.toml`.
Appendix A.1 (lines ~1581–1582) lists the same path. Appendix I.1
(line ~2732) lists `.codex/skills/pack-help.toml`. Appendix I.2
(line ~2751) lists `.codex/skills/pack-startup.toml`. Appendix I.4
(line ~2769) cites the same.

**Why it's a problem.** The current pack convention for Codex skills
is `.codex/skills/<name>/SKILL.md` (Markdown with frontmatter), not
TOML. The pack ships five Codex skills today
(`.codex/skills/architecture-review/SKILL.md`,
`.codex/skills/dependency-intake/SKILL.md`,
`.codex/skills/documentation/SKILL.md`,
`.codex/skills/planning/SKILL.md`,
`.codex/skills/review/SKILL.md`). All five are markdown SKILL.md
files in a per-skill subdirectory. Inspection of
`.codex/skills/review/SKILL.md` confirms the format: YAML frontmatter
(`name`, `description`, `allowed-tools`) + markdown body.

The audit's clarification (RESEARCH-AUDIT.md §A.1 Codex CLI bullet
list, lines ~45–50) describes Codex's user-extension surfaces as
"agents at `~/.codex/agents/<name>.toml`" (TOML) and "skills" (the
`/skills` slash surface) but does not pin the skill file format.
EXTERNAL-RESEARCH.md §12.2 mentions skills among Codex's extension
surfaces but doesn't enforce a format. Inspection of the live pack
shows the in-repo convention is markdown SKILL.md, not TOML.

The error then propagates to V3 Appendix I.1's ".codex/skills/
pack-startup.toml" claim and to the trinity-replication matrix
(§I.4, §28.2.5). The file `validate-pack.py` Check 21 (V3) is
designed to verify "all three per-CLI command files exist with
consistent target verb name (`pack-help`)" — if Check 21 is built
against `.codex/skills/pack-help.toml` it will fail on the actual
file `.codex/skills/pack-help/SKILL.md`.

**Source of truth.** Live pack at
`/Users/david/Developer/optiquity-ai-agent-config-pack/.codex/skills/`
shows directory-with-SKILL.md format. Existing five Codex skills all
follow this convention.

**Severity.** `blocker`. The planner cannot author Check 21
correctly while V3 specifies a non-existent file format. Either:
(a) the architecture is right and the pack needs to add a *new*
Codex skill format alongside the existing one (architectural change
requiring justification); or (b) V3 is using the wrong file
extension and should specify `.codex/skills/pack-help/SKILL.md`
to match the existing convention. Path (b) is almost certainly
correct — the architect should update §28.2.3, §A.1, §I.1, §I.4 to
say `.codex/skills/<name>/SKILL.md`.

The fix is a textual edit; if path (b) is correct, the maintainer
can apply it directly without architect re-spawn — but the
maintainer should confirm the architect's intent, since some Codex
documentation does also document a `~/.codex/agents/<name>.toml`
TOML format for *agents* (which V3 may be conflating with skills).

### §3.2 validate-pack check-number citation is stale

**What the architecture says.** V1 §3.3 (final paragraph, line
~596) says "The validate-pack `Check 17 (check_trinity_h2_parity)`
already enforces H2 parity." V1 §17.1 R10 (lines ~1919–1923) says
"The pack's own validate-pack.py Checks 16 / 17 / 18 must pass on
the v11 trinity changes."

**Why it's a problem.** The actual function `check_trinity_h2_parity()`
in `scripts/validate-pack.py` (line 1021) is documented as Check 18
("Check 18 — v10 trinity templates have matching H2 structure.").
Check 17 is `check_tool_config_capability_parity()` (line 832,
"Check 17 — AGENT_CAPABILITIES expressed identically...").

The intended cross-reference from V1 §3.3 to the validate-pack
function is correct in name (`check_trinity_h2_parity`) but wrong
in number (it's Check 18, not Check 17). Similarly V1 §17.1 R10's
"Checks 16 / 17 / 18" range nominally covers the trinity-related
checks but conflates `tool-config capability parity` (17) with
the trinity H2 / Project addenda / scaffolding checks (16, 18,
19).

The risk: V3 §28.2.5 newly adds Check 21 / 22 / 23. If the planner
reads V1 §3.3 and writes BD entries that say "Check 17 needs
extending" they'll touch the wrong function.

**Source of truth.** `scripts/validate-pack.py`:
- Check 16 = `check_trinity_addenda_h2` (line 1095, "Check 16 — ...
  carry `## Project addenda` H2").
- Check 17 = `check_tool_config_capability_parity` (line 832,
  "Check 17 — AGENT_CAPABILITIES").
- Check 18 = `check_trinity_h2_parity` (line 1021, "Check 18 —
  v10 trinity templates have matching H2 structure").
- Check 19 = `check_trinity_no_scaffolding_comments` (line 967).
- Check 20 = `check_gitignore_env_example_exception` (line 932).

**Severity.** `warning`. Easy textual fix in V1 §3.3 (change "Check
17" to "Check 18") and V1 §17.1 R10 (clarify which checks are
actually trinity-related). The maintainer can apply this edit
directly; no architect re-spawn needed. But it should be applied
*before* the planner consumes V1 §3.3 / R10 to author BDs that
extend validate-pack.

### §3.3 Verb-spelling contradiction in §0.6 vs D-19 / D-20

**What the architecture says.** V3 §0.6 (lines ~96–107) lists
"Things V3 deliberately does not change" including:

> - The verb spellings in V2 §22.1.

V2 §22.1 (lines ~1414–1424) lists exactly 9 verbs: `pack tracker
init`, `pack tracker disable`, `pack tracker doctor`, `pack tracker
status`, `pack tracker update-templates`, `pack tracker
mirror-rebuild`, `pack triage <id>`, `pack audit query [...]`,
`pack feedback upstream`. V2 §22.1 closes with "That is the
**9-verb surface** v11 introduces."

V3 D-19 (line ~179, V3 §16) introduces a new verb:
`pack tracker enable-recommendations`. V3 §28.1.9 (line ~979)
acknowledges the new verb: "Wrapper for `pack tracker
enable-recommendations`. Sets `persistent_refusal: false` in the
state file. Already in V2 §22 verb table; V3 adds the
`enable-recommendations` subcommand."

V3 D-20 (line ~180, V3 §16) plus V3 §28.2.1 (line ~1059)
introduces another new verb: `pack help`.

V3 §28.2.1's verb manifest tables explicitly list both new verbs
(line 1058: "`pack tracker enable-recommendations` | Re-enable
proactive recommendations | V3 §28.1"; line 1059: "`pack help` |
Show this help | V3 §28.2 (this section)").

**Why it's a problem.** Three internal contradictions:

1. §0.6 says verb spellings are unchanged. They are (the existing
   9 are unchanged), but two new ones are added. §0.6 should say
   "the 9 verb spellings in V2 §22.1 are unchanged; V3 adds two
   new verbs (`pack tracker enable-recommendations`, `pack help`)
   per D-19 and D-20."

2. V3 §28.1.9 says `pack tracker enable-recommendations` is
   "Already in V2 §22 verb table". It is NOT. V2 §22.1 lists 9
   verbs and closes with the explicit "9-verb surface" sentence.
   `pack tracker enable-recommendations` is NEW in V3.

3. P5 (cognitive load floor) — V2 §22.4 contains a justification
   table for every new verb. V3 introduces two new verbs without
   adding parallel justifications. The P5 bar requires
   justification by user value, not architectural elegance. V3
   §28.1 implicitly justifies `enable-recommendations` (refusal-
   respecting state machine), and V3 §27.1 / §28.2.1 implicitly
   justifies `pack help` (discoverability surface), but these
   justifications are scattered across §27 / §28 rather than
   collected in a §22-equivalent table. The planner has to hunt
   for the user-value statement for each new verb.

**Source of truth.** V2 ARCHITECTURE-V2.md §22.1 (verb table,
lines 1414–1424) and §22.4 (justification table, lines 1485–1495).
V3 ARCHITECTURE-V3.md §0.6 (lines 96–107) and §28.1.9 (line 982).

**Severity.** `warning`. The verbs are added; the architecture
intends them; the contradictions are textual. Three fixes:

(a) §0.6 should be edited to acknowledge the two new verb spellings
    rather than claim "no change."
(b) §28.1.9's "Already in V2 §22 verb table" sentence is factually
    wrong and should be deleted or edited.
(c) The architect should add a §22-style justification cell (or a
    new §27.5 / §28.3 subsection) for the two new verbs against the
    P5 bar.

The maintainer can apply (a) and (b) directly. Item (c) is a
small architect addition.

### §3.4 Codex-CLI help discoverability gap

**What the architecture says.** V3 §28.2.2 (lines ~1133–1156)
documents that Codex CLI has no `/help` slash command and the
slash-command surface is a compiled-in Rust enum. V3 §28.2.3 ships
a Codex `pack-help` skill via `/skills` and the LCD shell verb
`pack help`. V3 §28.2.6 (line ~1382) acknowledges: "For Codex CLI
specifically (no `/help`, no `/pack-help` slash if the user is
running Codex without project-level skills installed), the LCD path
is the shell `pack help`. The static greeting (Layer 1) tells the
user 'run `pack help`'; the user runs it in shell. Works
identically across all three CLIs at the LCD floor."

V3 §28.2.10 (lines ~1502–1514) documents that on Codex, the
discoverability path is `/skills` → see `pack-help` → invoke it,
which is 3 steps vs the 1-step shell `pack help`.

**Why it's a problem.** The brief's P6 (revised) sentence — "A new
user finds tracker commands AND all other pack functionality
without reading external documentation" — combined with the
"5-minute SLA" / "self-discoverability" requirement (§4.1 NEW
success criterion 2) — requires every CLI to surface help
*natively in the chat*, not via a shell escape. On Claude Code and
Gemini CLI, the user types `/p` and autocomplete shows
`/pack-help` (a CLI-native discoverability path). On Codex, that
path doesn't exist — Codex has no `/help`, and `/skills` is a
generic listing surface that the user has to know to consult.

V3 acknowledges this (§28.2.10 explicitly: "There's no conflict;
the user who knows Codex's conventions uses `/skills`; the user
who reads the static greeting uses `pack help`."). The mitigation
relies on the static greeting (Layer 1) telling the user "run
`pack help`". But the static greeting is part of `pack-startup` /
`pm-startup` Step 0 / Step 1 — which only fires if the user
actually runs that skill. A user who *opens Codex CLI directly
without invoking `pack-startup` first* (entirely possible — Codex
is a coding-agent CLI that lots of users use without skill
chaining) does not see the static greeting and has no native
discoverability path until they hit an error (Layer 2).

The 5-minute SLA test in V3 §28.2.6 assumes the user runs
`pm-startup` (or `pack-startup`) as Step 1. The "negative case" in
§28.2.6 (lines ~1391–1404) acknowledges users who skip the static
greeting and lists three fallback paths:
- ask the chat colloquially ("how do I use this pack?") — but on
  Codex, "the chat" is not a single chat with a routing layer; it's
  the bare Codex CLI without pm-startup-installed routing.
- type `pack help` directly in shell — but the user has to *know*
  to do this; that knowledge comes from external docs the brief
  says we shouldn't require.
- encounter errors and Layer 2 catches — works only after the user
  attempts something that errors.

For the Codex CLI user who doesn't go through pack-startup and
doesn't yet know any pack verb, there is **no on-ramp from the
discoverability surface alone**. They have to read external docs
or hit an error.

**Source of truth.** V3 §28.2.6 (5-step UX walk explicitly assumes
Step 1 = run `pm-startup`); V3 §28.2.10 (acknowledges the
discoverability tradeoff but does not close it); EXTERNAL-RESEARCH
§12.2 (Codex CLI's slash-command surface is closed-enum); brief
§3.4 P6 second bullet ("the user finds ... without reading
external documentation").

**Severity.** `warning`, escalating to `blocker` if the maintainer
considers the brief's "without reading external documentation"
language strict. The architect's analysis of the tradeoff is
correct; the question is whether the trade is acceptable. Two
mitigations the architect could add:

(M1) **Force the static greeting.** Make `pack-startup` /
     `pm-startup` discoverability-mandatory: any time the chat is
     active, ensure the greeting fires at session start. This is
     a Codex-specific concern; on Claude / Gemini the autocomplete
     surface is enough. Codex would need a startup hook that
     ensures the greeting prints before any user interaction. R17
     touches a related concern but doesn't address this gap.

(M2) **Document the gap explicitly as accepted scope.** V3 §28.2.6
     "negative case" partially does this; making it more explicit
     ("Codex users who do not run pack-startup will not have
     in-chat discoverability without external docs; we accept this
     for v11 because Codex's compiled-in slash surface forecloses
     the alternatives") would let the planner not pretend it's
     solved.

The maintainer should choose between M1 (architect re-spawn to
design the forced greeting) and M2 (textual edit + accepted-scope
note). M1 is the correct path if "without reading external
documentation" is strict; M2 is the right path if the maintainer
considers Codex's lack of native `/help` an acceptable cross-CLI
asymmetry below the LCD floor.



### §3.5 HELP-FRAGMENT layout architecturally awkward

**What the architecture says.** V3 §28.2.4 (lines ~1287–1301)
specifies file layout:

```
project-template/docs/pack/
├── HELP-FRAGMENT.md                 (client-surface verb list)
├── HELP-FRAGMENT-TRACKER.md         (shared tracker verbs)
└── ...

(pack root)
HELP-FRAGMENT-PACK.md                (pack-repo verb list)
```

`HELP-FRAGMENT-PACK.md` (at pack root) and
`project-template/docs/pack/HELP-FRAGMENT.md` (template) each
include `HELP-FRAGMENT-TRACKER.md` (located in
`project-template/docs/pack/`).

**Why it's a problem.** This places the pack-repo's runtime help
fragment in a dependency on a file located inside `project-template/`.
That directory is the *template* shipped to client projects; it is
not pack-repo runtime content. Pack Chat running on the pack repo
itself ends up reading `project-template/docs/pack/
HELP-FRAGMENT-TRACKER.md` to render its own help — which couples
pack-repo runtime to template content that is supposed to be
client-side state.

`PACK-CHAT.md` Separation of Concerns rule (and the user's MEMORY
guidance "Separate pack ops from pack product") suggests the
pack-repo should not depend on `project-template/` files for its
own runtime. This finding does not invalidate the design — the
fragment is read-only and the dependency is an include, not a
write — but the layout is awkward and asymmetric.

**Source of truth.** Pack repository conventions (validate-pack
Check 8 reserved `x-` prefix, the user MEMORY note on ops/product
separation), V3 §28.2.4 file layout.

**Severity.** `warning`. Two clean alternatives the architect could
consider (no re-design proposed, just naming for the architect):

- (a) Co-locate the shared fragment at pack root:
  `HELP-FRAGMENT-TRACKER.md` at pack root; `init-project.sh` copies
  it into `project-template/docs/pack/` at install time (existing
  pattern for many template files).
- (b) Keep the layout as designed but document the cross-tree
  dependency in V3 §28.2.4 explicitly so the planner doesn't try to
  refactor it.

The maintainer should ask the architect which they prefer; either
fix is small.

### §3.6 Citation slip — "audit §A.5 token-cost crossover"

**What the architecture says.** V3 D-19 (line ~179, V3 §16) and
V3 §28.1.2 (lines ~617–619) and Appendix B.1 (line ~1675) and
Appendix B.3 (line ~1710) all cite "audit §A.5 token-cost
crossover at ~50–100 issues" or "audit §A.5 inflection at
~50–100 active items where filtered tracker queries beat full-file
reads."

**Why it's a problem.** RESEARCH-AUDIT.md §A.5 verifies the
plausibility of EXTERNAL-RESEARCH §6's token-cost numbers but does
not itself state the "~50–100 issues" inflection. That number is
in `EXTERNAL-RESEARCH.md` §6.1 ("**Inflection point**: at ~50–100
open items, projected JSON ...", line 533) and §6.6.

The citation is reachable (audit §A.5 verifies §6's numbers, so
the inflection is implicit), but a strict reader looking for the
~50–100 number in audit §A.5 will not find it. The planner will
also write BD-NNN entries with the wrong source citation.

**Source of truth.** EXTERNAL-RESEARCH.md §6.1 line 533 ("at
~50–100 open items"); RESEARCH-AUDIT.md §A.5 lines 90–99 (verifies
§6 plausibility; does not restate the inflection).

**Severity.** `nit`, escalating to `warning` for any future
verifier who tries to trace the threshold rationale to its source.
Replace "audit §A.5 token-cost crossover at ~50–100 issues" with
"EXTERNAL-RESEARCH §6.1 token-cost inflection at ~50–100 issues
(verified plausible by audit §A.5)" everywhere V3 cites this.

Maintainer can apply directly.

### §3.7 D-6 ambiguous on pack-repo trinity scope

**What the architecture says.** V1 §3.3 / D-6 (V3 reaffirmed) says
"Trinity `## Document locations` table gains a Source column." V1
§3.3 walks through the v10 → v11 trinity table edit using the
client-project trinity (with `docs/project/...` paths) as the
example.

**Why it's a problem.** The pack-repo trinity (CLAUDE.md / AGENTS.md
/ GEMINI.md at pack root) does **not** have a `## Document
locations` section today. Live inspection of the three files
confirms: pack-repo CLAUDE.md has H2s `## What this repo is`,
`## Repo structure`, `## Rules for agents working on this repo` —
no `## Document locations`. So D-6's Source-column addition is
*not applicable* to pack-repo trinity.

This is fine in practice, but D-6 is silent on this asymmetry. The
planner reading D-6 may write a BD entry "Add Source column to
pack-repo CLAUDE.md / AGENTS.md / GEMINI.md trinity" and discover
mid-implementation that the section doesn't exist there.

V3 §28.2.5 (Trinity propagation) does correctly distinguish
pack-repo trinity (gets a one-line "Pack commands" reference) from
project-template trinity (also gets a one-line reference plus the
Source column). But D-6 itself doesn't make this distinction
explicit.

**Source of truth.** Live inspection of pack-repo CLAUDE.md (and
parallel AGENTS.md / GEMINI.md). V1 §3.3 example uses
project-template trinity.

**Severity.** `nit`. D-6 should explicitly note: "Source column
applies to project-template trinity (where `## Document locations`
exists). Pack-repo trinity has no `## Document locations` section
and is not affected by D-6." Or: V3 §28.2.5 already handles this
correctly; the architect could just add a one-line note in V3 §16
D-6's V3-status column.

Maintainer can apply directly.

### §3.8 R16 internal contradiction (editorial)

**What the architecture says.** V3 §17 R16 (lines ~221–229) reads:

> If the project moves between machines (clone, fresh worktree),
> the file is in git? — **No.** The file is in `.pack-tracker/`,
> which is in `.gitignore` per V1 §3.4 (state files). Each machine
> starts with no recommendation history. A user who declined "don't
> ask again" on machine A and switches to machine B will be
> re-prompted unless they declined in
> `.pack-tracker/recommendation-state.json` is committed, which
> would be wrong (machine-private state).

**Why it's a problem.** The "unless they declined in
`.pack-tracker/recommendation-state.json` is committed" phrase is
fragmentary; the sentence breaks mid-clause. The intent is clear
(persistent refusal does not survive machine-switch because the
state file is gitignored), but the editorial slip makes the risk
analysis less authoritative.

**Source of truth.** V3 §17 R16 lines 221–229 (textual).

**Severity.** `nit`. Easy editorial fix; maintainer can apply.



---

## §4. Risks the architect missed

V3 §17 lists R1–R8, R10 (V1), R11–R14 (V2), R15–R17 (V3). Cross-checking
against EXTERNAL-RESEARCH §10, RESEARCH-AUDIT §10, INTERNAL-INVENTORY
"Risks for migration to a tracker integration" R1–R10, V3 §13
per-CLI matrix, audit §A.8 cross-CLI gotchas, and the P1–P6 priorities,
the following risks are absent from §17:

### §4.1 In-session implication of corrupted-state recovery (R16 expansion)

**What's missed.** V3 §17 R16 covers state-file corruption (parse
fail, partial write). The mitigation: write a fresh default state.
But V3 doesn't specify what happens *in the same session* after
that recovery. If the fresh default state has `persistent_refusal:
false` and signals are over threshold, does the session immediately
fire the recommendation? The user just hit a confusing error
("state file corrupted, resetting") and is now seeing the full
recommendation prompt — high-friction, possibly the worst possible
UX for a user who was doing nothing wrong.

**Why it matters.** The recommendation prompt's P6 "refusal-respecting"
contract assumes the user gets to make a deliberate choice. A
corrupted-file recovery surfacing the prompt right after the
recovery message is not a deliberate choice; it's confused noise.

**Severity.** `warning`. Mitigation: V3 §28.1.4 should specify that
after a state-file rebuild, the session does not fire the active
recommendation in the same session — it logs the recovery, treats
the session as if recommendation already shown, and lets the next
session evaluate fresh.

**Where it should land.** Add a sub-bullet to V3 §28.1.4 "Failure
modes" → "File corrupted (JSON parse fails)" branch: "After
rebuild, treat current session as if recommendation already shown;
defer evaluation to next session." Also add a test to V3 §28.1.10.

### §4.2 BACKLOG-format drift between flat-file and tracker reverse (P1 / R3)

**What's missed.** V1 §6.5 / D-8 designs reverse migration to
reconstruct BACKLOG.md to v10 grammar. V3 §28.1.4 also preserves
the recommendation-state file across migrations. But the pack
between v11.0 and v11.x may evolve the BACKLOG entry format itself
(e.g., adding fields per V2 §19 templates). If a user opts into
tracker on v11.0, then upgrades the pack to v11.1 (which adds a
new BD field), then runs reverse migration, the reverse fails to
reconstruct the v11.1 field accurately — because the reverse
algorithm is pinned to v10 grammar.

V2 §19 covers template upgrade in the *forward* direction (entries
migrate from v11.0 templates to v11.1 templates inside the
tracker). But V3 / V2 / V1 don't say what reverse migration emits
when the active templates have evolved past v11.0.

**Why it matters.** The brief mandates reverse migration; an
implicit grammar lock to v10 means a user who reverses out at v11.x
loses the v11-introduced fields. Mitigation: emit them to the
sidecar (V1 §6.6) or document the loss explicitly.

**Severity.** `warning`. The brief's mandatory-reverse contract
needs a story for "v11 entry format evolved past v10".

**Where it should land.** New risk R18 in V3 §17. Or extend V1
§6.6 sidecar coverage to v11-introduced fields.

### §4.3 GH search 1,000-result hard cap interacts with `bd_count_total` signal

**What's missed.** V3 §28.1.1 client-side `td_count_total` signal
greps the local BACKLOG.md for `^\*\*TD-` — that's a local-file read,
not a tracker query. Fine. But V3 §19 / §28.2 mentions the
recommendation system uses *flat-file* token-cost estimates, while
*after* opt-in the chat queries the tracker. Per audit §A.2 / EXTERNAL
§1.6, GH search results are capped at 1,000 per query. A client
project past 1,000 active TDs in the tracker — exactly the scale
the recommendation system is designed for — needs paginated reads.
V1 §2.6 covers pagination, but V3's recommendation flow assumes the
post-opt-in surface is faster — it is, but only if the planner
implements pagination correctly.

**Why it matters.** Not a v11 ship blocker (the recommendation is
correctly designed pre-opt-in; the post-opt-in pagination is V1
§2.6). But the recommendation message wording in V3 §28.1.7 promises
"GH Issues lets you filter and search faster than reading
BACKLOG.md in full." For projects at the high end of the
recommendation threshold (well over 1,000 entries), the user may
hit the 1,000-search cap and be confused. R5 (capability drift)
partially covers this; an explicit note doesn't hurt.

**Severity.** `nit`. Optional addition to V3 §28.1.7 prompt notes:
"At very large scale (>1,000 entries) some search queries paginate
or filter further; tracker queries remain cheaper than full-file
reads."

**Where it should land.** V3 §28.1.7 prompt-shape notes, or a new
risk R19.

### §4.4 INTERNAL-INVENTORY R10 (no validate-pack project-side hygiene check)

**What's missed.** INTERNAL-INVENTORY R10 (line 1618) flags that
"No validate-pack check covers the project-side flat-file hygiene.
Every rule is enforced at runtime by the agent or skill, not by
CI." V3 adds new validate-pack Checks 21 / 22 / 23 — they cover
trinity per-CLI parity, help-fragment freshness, help-fragment
completeness. None of them cover *project-side* flat-file hygiene
(the original R10 concern). R10 is preserved silently; V3 does not
say "out of scope for v11" nor adopt it.

**Why it matters.** Not a tracker-integration issue per se, but the
brief's P1 (Entry lifecycle completeness) mentions "duplicate
detection workflow" — duplicate detection at create-time at the
flat-file BACKLOG level is exactly the project-side hygiene R10
calls out. V2 §18.1 designs duplicate detection at the *tracker*
level (Pack Chat triage). For projects on flat-file mode (the
default), duplicate detection is still chat-side, not CI-side.

**Severity.** `nit`. Document the gap explicitly as out-of-scope
for v11, or add a future-minor note. The architect's Appendix H or
§17.2 trade-offs could note this.

### §4.5 Codex skill conflict on shared user-level path `~/.codex/skills/`

**What's missed.** V3 §28.2.3 and §A.1 list `~/.codex/skills/
pack-help.toml` (user-level) AND `.codex/skills/pack-help.toml`
(project-level). Codex CLI loads both; if a user has the same skill
installed at both levels, behavior is unspecified by Codex CLI's own
docs (audit §A.1). V3 doesn't say which level wins or how the pack
handles a stale user-level skill from an old pack version against
a project-level skill from the current pack. (Format error from
§3.1 also applies; here we're flagging the precedence concern
independently.)

**Why it matters.** A user with multiple pack-installed projects on
their machine (the "multiple surfaces" case V3 §D.8 walks through)
may have the user-level Codex skill from one project and the
project-level skill from another. If they conflict, debugging is
hard. Mitigation: pack ships *only* the project-level Codex skill
(`.codex/skills/pack-help/SKILL.md` after the §3.1 fix), never
user-level.

**Severity.** `nit`. V3 §28.2.3 should drop `~/.codex/skills/`
(user-level) and ship only `.codex/skills/<name>/SKILL.md`
(project-level). Same for Gemini (`.gemini/commands/` is fine
project-only; `~/.gemini/commands/` removed).

**Where it should land.** V3 §28.2.3 implementation table.



---

## §5. Clarity-for-planner section list

These sections are correct (or correct after §3 fixes apply) but
the planner needs additional clarity to break them into BDs. They
are not findings against the architecture's correctness; they are
gaps in the planner-facing layer.

### §5.1 §28.2.3 Per-CLI implementation table

**What's unclear.** After fixing §3.1 (Codex skill format) and §3.7
(D-6 pack-repo trinity scope), the implementation table is mostly
clear. But the table mixes file format and shell-injection syntax
across CLIs. For example, V3 §28.2.3 uses ``!`bash scripts/
pack-help.sh` `` for Claude Code, ``!{bash scripts/pack-help.sh}``
for Gemini. The exact escape syntax for Codex skills is unspecified
(after the §3.1 fix to use SKILL.md format, the body must reference
how Codex skills invoke shell scripts — Codex skill docs differ
from Claude/Gemini in how shell injection works).

**What planner needs.** Concrete shell-injection patterns for each
of the three CLIs in V3 §28.2.3, OR a note that the patterns are
the planner's discretion provided each invokes `pack-help.sh`.

### §5.2 §28.1.9 Shared `recommendation.sh` library API

**What's unclear.** V3 §28.1.9 says "`scripts/lib/recommendation.sh`
(new) — shared bash library that the skills source. Contains:
signal computation, state-file read / write, the
`should_recommend()` test, the prompt-rendering helper." The
function signatures, return-value conventions, and error-output
shape are not specified.

**What planner needs.** The planner can reasonably break this into
"BD: implement recommendation.sh library" with the signals from
§28.1.1 and the state-machine from §28.1.6 as inputs. The library
API itself can be a planner decision. But the architect should
confirm this is intentional latitude vs an oversight.

### §5.3 Trinity replication of pack-startup / pm-startup Step 8

**What's unclear.** V3 §A.2 lists the per-CLI files that need
modification:

```
.claude/skills/pack-startup/SKILL.md
.codex/skills/pack-startup.toml      <-- format wrong per §3.1
.gemini/commands/pack-startup.toml
project-template/skills/pm-startup/SKILL.md
.claude/skills/pm-startup/SKILL.md
.codex/skills/pm-startup.toml        <-- format wrong per §3.1
.gemini/commands/pm-startup.toml
```

Live inspection confirms today only:
- `.claude/skills/pack-startup/SKILL.md` exists (pack-side).
- `project-template/skills/pm-startup/SKILL.md` exists
  (project-template canonical).

There are no `.codex/skills/pack-startup/...` or
`.gemini/commands/pack-startup.toml` files in the pack today, and
no `.claude/skills/pm-startup/SKILL.md` — they are presumably
distributed at install time by `init-project.sh`.

INTERNAL-INVENTORY R9 (line 1613) says "the skill exists in three
copies (.claude/, .codex/, .gemini/skills/pm-startup/)" — but
ground-truth check finds only one copy. The "three copies" claim
appears to be aspirational (post-init-project distribution) not
current pack-repo state.

**What planner needs.** The planner needs to know which files
exist *in the pack repo source* vs which are *generated by
init-project.sh / merge-trinity.py / merge-platform-skills.py at
install time*. V3 §I.4 trinity matrix tries to capture this but
mixes "pack repo files" and "client repo files after init."

A clarifying note in V3 §I.4 or §A.2: "Files marked
`(distributed)` are generated by init-project.sh from the
canonical source under `project-template/`; pack-repo edits go to
the canonical only" would help.

### §5.4 §28.2.5 Check 22 verb-extraction algorithm

**What's unclear.** Check 22 (V3) is "for every verb named in
PACK-CHAT.md, PM-CHAT.md, QUICKSTART.md, OPTIONAL-FEATURES.md,
INSTALL-PROCEDURES.md, verify the verb is also in HELP-FRAGMENT*.md."
The algorithm to *extract* verb names from prose is not specified.
A regex like `pack [a-z-]+` will catch real verbs but also some
false positives (e.g., "pack tracker" appearing in narrative
sentences). Without an extraction grammar, Check 22 will be
brittle.

**What planner needs.** Specify the verb format ("verb is
backtick-quoted with `pack ` prefix") OR allow Check 22 to be
narrower (only verbs explicitly enumerated in a sentinel block in
each file).

### §5.5 Reverse-migration of recommendation-state across surfaces

**What's unclear.** V3 §28.1.4 says the recommendation-state file
is preserved across forward / reverse migrations. But V3 §A.5
reverse direction says "The per-CLI help surfaces are removed by
the reverse (they're v11-specific)." If the state file is
preserved but the v11-specific surfaces are removed, what does
`pack tracker enable-recommendations` do on a project that has
reverted to v10 + flat-file? The verb is also v11-specific.

**What planner needs.** A clarifying note: after reverse migration,
the recommendation-state file remains as inert data; the
recommendations system itself is no longer active because it lives
in the v11-specific skill steps. If the user re-installs v11
later, the state file is read fresh and persistent_refusal applies.

This is implicit in V3's design but worth one sentence in §A.5
reverse direction.

---

## §6. Per-CLI doc citation spot-check

Per the prompt's directive: "Spot-check at least one citation per
CLI to confirm currency."

I performed live HTTP fetches against the URLs cited in V3 §28.2.2
and Appendix E, on the V3 audit date (2026-04-30, current session
date). Results:

### §6.1 Claude Code

**Citation in V3.** "Custom commands have been merged into skills.
A file at `.claude/commands/deploy.md` and a skill at
`.claude/skills/deploy/SKILL.md` both create `/deploy`..."
(https://code.claude.com/docs/en/skills, V3 §28.2.2 lines
~1115–1124).

**Spot-check result.** **Verified.** Live fetch of
`https://code.claude.com/docs/en/skills` returned the page
containing the verbatim text:

> Custom commands have been merged into skills. A file at
> `.claude/commands/deploy.md` and a skill at
> `.claude/skills/deploy/SKILL.md` both create `/deploy` and work
> the same way. Your existing `.claude/commands/` files keep
> working.

Citation accurate; conclusion in V3 §28.2.2 (no documented
augmentation of `/help`) is consistent with the live page.

### §6.2 Codex CLI

**Citation in V3.** "The `SlashCommand` enum in
`codex-rs/tui/src/slash_command.rs` ... does not include `Help`."
(https://github.com/openai/codex/blob/main/codex-rs/tui/src/slash_command.rs,
V3 §28.2.2 lines ~1136–1156).

**Spot-check result.** **Verified.** Live fetch of the raw file
returned the SlashCommand enum. Variants present: `Model`, `Fast`,
`Ide`, `Permissions`, `Keymap`, `Vim`, `ElevateSandbox`,
`SandboxReadRoot`, `Experimental`, `AutoReview`, `Memories`,
`Skills`, `Hooks`, `Review`, `Rename`, `New`, `Resume`, `Fork`,
`Init`, `Compact`, `Plan`, `Goal`, `Collab`, `Agent`, `Side`,
`Copy`, `Diff`, `Mention`, `Status`, `DebugConfig`, `Title`,
`Statusline`, `Theme`, `Mcp`, `Apps`, `Plugins`, `Logout`, `Quit`,
`Exit`, `Feedback`, `Rollout`, `Ps`, `Stop`, `Clear`,
`Personality`, `Realtime`, `Settings`, `TestApproval`,
`MultiAgents`, `MemoryDrop`, plus more. **`Help` is NOT in the
enum.** Confirmed via `grep -ic Help` returning 0.

The variant list is current (the file shows commands like
`Personality`, `Realtime` not in V3's paraphrased list — Codex CLI
has added more variants since V3 was authored, but `Help` remains
absent). Citation accurate.

### §6.3 Gemini CLI

**Citation in V3.** "**`description` (String): A brief, one-line
description of what the command does. This text will be displayed
next to your command in the `/help` menu.**"
(https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md,
V3 §28.2.2 lines ~1163–1178).

**Spot-check result.** **Verified.** Live fetch of the raw
custom-commands.md returned the verbatim sentence:

> does. This text will be displayed next to your command in the
> `/help` menu.

Citation accurate. The V3 conclusion (only Gemini documents `/help`
augmentation, satisfying the brief's "if not best-practice across
all three, prefer (b)" branch) holds.

### §6.4 Spot-check verdict

All three V3 §28.2.2 citations are current and accurate as of
2026-04-30. The per-CLI documentation defense in V3 §28.2.2 stands.
The chosen path (D-20 namespaced `/pack-help`) is correctly forced
by the brief's directive.



---

## §7. Final verdict + go / no-go

**Final verdict: `approve-with-changes`.**

The V3 architecture is substantively correct. V1 + V2 + V3 form a
coherent design package; the two new decisions (D-19, D-20) are
defended on research-data and per-CLI-documentation grounds; all 20
OQs resolve; all six priorities are addressed; the brief's hard
constraints are honored; the per-CLI doc citations are current
(spot-checked).

The architecture has the following changes that the maintainer must
apply or refer to the architect before the planner spawns.

### §7.1 Changes the maintainer can apply directly (no architect re-spawn)

These are textual / format edits that don't require architect
re-design:

1. **§3.1 Codex skill format** — assuming the architect intended
   the existing pack convention (almost certainly yes), edit V3
   §28.2.3, §A.1, §I.1, §I.4 to specify `.codex/skills/<name>/SKILL.md`
   instead of `.codex/skills/<name>.toml`. Same fix for any
   `.codex/skills/pack-startup.toml` references — should be
   `.codex/skills/pack-startup/SKILL.md`. **(Verify with architect
   if uncertain; if format change to TOML is intentional, this
   becomes architect re-spawn.)**

2. **§3.2 validate-pack check-number citation** — edit V1 §3.3
   ("Check 17" → "Check 18"); edit V1 §17.1 R10's "Checks 16 / 17 /
   18" range to specify which functions (16=`check_trinity_addenda_h2`,
   18=`check_trinity_h2_parity`, 19=`check_trinity_no_scaffolding_comments`).

3. **§3.3 Verb-spelling contradiction** — edit V3 §0.6 to
   acknowledge two new verbs. Edit V3 §28.1.9 to delete or fix
   "Already in V2 §22 verb table." Optionally add a §22-style
   justification mini-table for the new verbs.

4. **§3.6 Citation slip** — replace "audit §A.5 token-cost
   crossover at ~50–100 issues" with "EXTERNAL-RESEARCH §6.1
   token-cost inflection at ~50–100 issues (verified plausible by
   audit §A.5)" everywhere this is cited (D-19 row, §28.1.2,
   §B.1, §B.3).

5. **§3.7 D-6 pack-repo trinity scope** — add a one-line note in
   D-6 V3-status column: "Source column applies to project-template
   trinity only; pack-repo trinity has no `## Document locations`
   section."

6. **§3.8 R16 fragment** — fix the editorial slip in V3 §17 R16.

7. **§4.1 R16 expansion (in-session implication)** — add a
   sub-bullet to V3 §28.1.4 "Failure modes" → "File corrupted":
   "After rebuild, treat current session as if recommendation
   already shown; defer evaluation to next session." Add a parallel
   test in §28.1.10.

8. **§4.5 Codex skill user-level vs project-level** — edit V3
   §28.2.3 to drop user-level `~/.codex/skills/` and `~/.gemini/
   commands/`; ship project-level only.

9. **§5.5 reverse-migration recommendation-state clarification** —
   add one sentence to V3 §A.5 reverse direction: "After reverse,
   the recommendation-state file remains as inert data; the
   recommendation system is no longer active without v11 skills.
   Reinstalling v11 reads the file fresh."

### §7.2 Changes that require architect re-spawn

10. **§3.4 Codex `/help` discoverability gap** — the architect
    must choose between M1 (force the static greeting pattern at
    every Codex session start, redesigning §28.2.6 negative case
    into a positive design) or M2 (textually accept the gap as
    out-of-scope, update §28.2.6 to say so). Either is small but
    both require the architect's authorial decision since the
    brief's "without reading external documentation" language is
    plausibly strict.

11. **§3.5 HELP-FRAGMENT layout** — architect picks between
    co-locating `HELP-FRAGMENT-TRACKER.md` at pack root or
    documenting the cross-tree dependency. Either path is fine; the
    pick is the architect's.

12. **§4.2 BACKLOG format drift between flat-file and tracker
    reverse** — architect adds R18 in V3 §17 (template evolution
    affects reverse-migration grammar) or extends V1 §6.6 sidecar
    coverage. The mandatory-reverse contract needs a story.

### §7.3 Optional / lower-priority items

These are warnings / nits the maintainer can elect to defer to
v11.x.

13. §4.3 GH search 1,000-cap interaction with very-large-scale
    recommendations.
14. §4.4 INTERNAL-INVENTORY R10 (validate-pack project-side
    hygiene) — explicitly mark out-of-scope or future-minor.
15. §5.1 §28.2.3 shell-injection syntax per CLI — clarify or
    leave to planner discretion.
16. §5.2 `recommendation.sh` API — clarify or leave to planner.
17. §5.3 trinity replication source-of-truth distinction —
    clarify "canonical vs distributed" in §I.4.
18. §5.4 Check 22 verb-extraction algorithm — specify or narrow.

### §7.4 Go / no-go for planner spawn

If the maintainer applies the §7.1 changes (10 textual edits) and
addresses §7.2 items 10–12 (architect re-spawn or scope acceptance),
the architecture is ready for the planner. The §7.3 optional items
can be deferred to BD entries written by the planner with explicit
"future minor" notes.

If the maintainer accepts the §3.4 Codex discoverability gap as
out-of-scope (M2), no architect re-spawn is required; the architect
just needs to add one sentence acknowledging the gap. In that case,
the maintainer can apply all changes directly and proceed to
planner spawn after a brief architect ack on the textual fixes.

---

## §8. Summary of severities

For audit completeness:

| Severity | Count | Items |
|---|---|---|
| `blocker` | 1 | §3.1 (Codex skill format error) |
| `warning` | 7 | §3.2, §3.3, §3.4, §3.5, §3.6, §3.7, §4.1, §4.2 (note: §3.4 may escalate to `blocker` per maintainer interpretation) |
| `nit` | 6 | §3.8, §4.3, §4.4, §4.5, §5.1, §5.2, §5.3, §5.4, §5.5 |

Decision verdicts: 20 of 20 `matched-rationale`; 0 `weak-rationale`
beyond the D-6 ambiguity covered as a `nit` (§3.7).

Priority verdicts: 5 of 6 `addressed`; 1 `partially-addressed` (P5
cognitive load floor, owing to the §3.3 verb-spelling contradiction).

OQ verdicts: 19 of 20 `resolved`; 1 `partially-resolved` (OQ-6,
covered by §3.7).

Section verdicts: most `approve` or `approve` (preserved-OK); a
handful `approve-with-changes` reflecting findings; 0 `needs-revision`.

The architecture is ready for planner spawn after the §7.1 / §7.2
maintenance step.

---

## End of architecture review

The architect's V3 design is substantively complete. The findings
above are tractable. The planner should not spawn until §7.1's
textual fixes are applied and §7.2's architect decisions are
recorded; the planner can then break the architecture (V1 + V2 +
V3 deltas, with this review's notes incorporated) into BD-NNN
entries for v11 implementation.

