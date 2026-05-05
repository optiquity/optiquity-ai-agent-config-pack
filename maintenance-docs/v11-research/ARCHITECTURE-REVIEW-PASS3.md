# ARCHITECTURE-REVIEW-PASS3 — full-corpus final review before commit

## §0. Status

- Date: 2026-05-05
- Inputs reviewed: V1 (`ARCHITECTURE.md`) + V2 (`ARCHITECTURE-V2.md`) + V3 (`ARCHITECTURE-V3.md`) + V3.1-DELTA + V3.3-DELTA + IMPLEMENTATION-PLAN.md + Addenda 1, 2, 3, 4. V3.2-DELTA reviewed only for supersession-discipline check.
- Prior reviews referenced: ARCHITECTURE-REVIEW.md (PASS1, approve-with-changes, 1 blocker + 8 warnings + 6 nits — fully resolved per PASS2); ARCHITECTURE-REVIEW-PASS2.md (approve-with-changes, all PASS1 blocker/warnings resolved; 6 new nits + 1 warning surfaced — substantially absorbed into V3.3 + Addendum 4).
- Live pack state spot-checks performed against `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `project-template/.claude/agents/`, pack-root skill directories, `scripts/validate-pack.py`, `BACKLOG.md`, `project-template/.claude/agents/auditor.md`.
- **Final verdict: `approve-with-changes`.**
- **Commit-and-implement: GO** — after the maintainer applies the two warning-class textual fixes in §5. The blocker-class issue is a planner-side numbering collision that the maintainer-deferred §6.C already covers, but Addendum 4 should explicitly acknowledge it (§5.1 below). No architect re-spawn required.

## §1. Per-document verdict

| Document | Verdict | One-line summary |
|---|---|---|
| `DESIGN-BRIEF.md` | n/a (input contract) | Not under review; the brief is the contract the corpus is checked against. |
| `ARCHITECTURE.md` (V1) | `approve` | V1 §5.1 line 859 is superseded-by-reference per V3.3 §2.6. Two `from TD-` hits at lines 1242 / 1749 are unrelated query-example phrasing; clean otherwise. |
| `ARCHITECTURE-V2.md` | `approve` | D-4-V2, D-16, D-17, D-18 hold. V2 §22.1 verb table silently extended by V3 D-19/D-20 + V3.3 D-22 verbs; intrinsic to additive-on-V2 structure (PASS2 §5.4 noted; reader-orientation hazard, not defect). |
| `ARCHITECTURE-V3.md` | `approve` | All PASS1+PASS2 textual fixes landed. Per-CLI documentation defense for D-20 verifiable; spot-checked against live `.codex/skills/`, `.claude/skills/`, `.gemini/skills/`. |
| `ARCHITECTURE-V3.1-DELTA.md` | `approve` | M2 / L1 / A2 cleanly integrated. Independent of V3.3 work; A2's sidecar extension composes with V3.3 §4.3's `phase_tasks` block and §6.R's `annotation` sub-field per maintainer resolution. |
| `ARCHITECTURE-V3.2-DELTA.md` | `superseded-historical` | Per V3.3 §1 supersession table. Live corpus contains zero references to V3.2-specific elements outside legitimate supersession/check-absence contexts. |
| `ARCHITECTURE-V3.3-DELTA.md` | `approve` | D-21 / D-22 / D-23 well-formed. §2.6 V1-§5-line-859 supersession explicit. §10 cross-impact check clean. §8.4 contradicts the actual pack-side per-CLI layout but Addendum 4 §6.M flags this for maintainer resolution. |
| `IMPLEMENTATION-PLAN.md` | `approve-with-changes` | Numbering collision: BD-089 (base plan) Check 25 collides with Addendum 4 §3.1's Check 25. §6.C MAINTAINER CHECK covers this, but it should be explicitly extended in Addendum 4 to name the collision. See §5.1. |
| `IMPLEMENTATION-PLAN-ADDENDUM.md` (1) | `approve` | BD-094..BD-101 hold under V3.3. BD-094's MERGE-STRATEGY.md row for IMPLEMENTATION-PLAN.md correctly added by Addendum 4 §2.12. |
| `IMPLEMENTATION-PLAN-ADDENDUM-2.md` (2) | `approve` | BD-102 (pack dog-food), BD-103 (pack tracker reset). Independent of V3.3 mechanics; §6.J flat-file ship decision unaffected. |
| `IMPLEMENTATION-PLAN-ADDENDUM-3.md` (3) | `approve` | BD-104 (rename) + BD-105 (STATUS dual-link). V3.3-DELTA already uses post-rename `IMPLEMENTATION-PLAN.md` form; consistent. |
| `IMPLEMENTATION-PLAN-ADDENDUM-4.md` (4) | `approve-with-changes` | V3.3 integration substantially correct. Two textual issues require fix: Check 25 collision acknowledgement (§5.1); §1.5 BD-110 §6.N skill-provenance phrasing inconsistency (§5.2). Both fixable without architect re-spawn. |

## §2. Per-decision verdict (D-1..D-23)

| Decision | Origin | Verdict | Implementing BDs |
|---|---|---|---|
| D-1 (provider surface) | V1 §2.1 | `traceable` | BD-060 |
| D-2 (tracker.toml) | V1 §3.1 | `traceable` | BD-061 |
| D-3 (tracker-migrate.sh) | V1 §6.1 | `traceable` | BD-065 / BD-067 |
| D-4-V2 (form family) | V2 §4 | `traceable` (extended) | BD-063; extended by Addendum 4 §2.1 |
| D-5 (mode detection) | V1 §3.2 | `traceable` | BD-061 |
| D-6 (Source column) | V1 §3.3 / V3 D-6 row | `traceable` | BD-062 |
| D-7 (failure UX) | V1 §9 | `traceable` | BD-070; A1 surface routed through it per V3.1-DELTA §3 |
| D-8 (reverse migration) | V1 §6.5 | `traceable` | BD-067 |
| D-9 (agent reads LCD) | V1 §8 | `traceable` | BD-071 |
| D-10 (single `gh auth`) | V1 §7.3 | `traceable` | BD-066 |
| D-11 (PACK-FEEDBACK upstream) | V1 §7.5 | `traceable` | (BD-066 family) |
| D-12 (pre-existing tracker deferred) | V1 §15 | `traceable` (deferred per brief) | (deferred) |
| D-13 (license) | V1 §11 | `traceable` | (no implementing BD; documentation-only) |
| D-14 (external triage) | V1 §10 | `traceable` | (BD-066 family) |
| D-15 (token measurement) | V1 §12 | `traceable` | (post-shipping) |
| D-16 (form-family canonical) | V2 §4 | `traceable` | BD-063 |
| D-17 (structure-vs-free-text) | V2 §25 | `traceable` | BD-063 |
| D-18 (template_version dual carrier) | V2 §26 | `traceable` (extended) | BD-069; extended by Addendum 4 §2.6 |
| D-19 (recommendation system) | V3 §28.1 | `traceable` | BD-072 / BD-073 / BD-074 |
| D-20 (help-verb scope) | V3 §28.2 | `traceable` | BD-075 / BD-076 / BD-077 |
| D-21 V3.2 (phase tasks at L3) | V3.2 | `superseded` | n/a — superseded by D-21 V3.3 |
| D-22 V3.2 (three-path TD promotion) | V3.2 | `superseded` | n/a — superseded by D-22 V3.3 |
| D-21 V3.3 (phase tasks at L2; TD/BD at L1) | V3.3 §2 | `traceable` | BD-106; existing BD extensions §2.1, §2.6 |
| D-22 V3.3 (two-path promotion + direct close) | V3.3 §3 | `traceable` | BD-107; METHODOLOGY § Part 7 lines 1057-1064 update |
| D-23 V3.3 (issue-tracking auditor pair) | V3.3 §8 | `traceable` | BD-109 (project-side); BD-110 (pack-side) |

All 23 active decisions are traceable to origin doc, architecture sections, and at least one implementing BD. Two superseded decisions (D-21 V3.2, D-22 V3.2) carry no implementing references in the live corpus per the supersession-discipline scan in §4.2.

## §3. Findings

### §3.1 Blockers

**None.**

The first-pass blocker (Codex skill format error) was resolved in V3 §28.2.3. No new blocker-severity issues emerged in this pass. The numbering collision in §5.1 is warning-severity, not blocker, because §6.C MAINTAINER CHECK already provides the deferral framework and Addendum 4 §6.O extends that framework to its new checks; the gap is textual acknowledgement, not load-bearing.

### §3.2 Warnings

**§3.2.1 — Check-number collision: BD-089 Check 25 ↔ Addendum 4 §3.1 Check 25.**

`IMPLEMENTATION-PLAN.md` line 770 / line 995: BD-089 ships **Check 25 (`check_25_customization_detection_regression_guard`, BD-059 fix)**.

`IMPLEMENTATION-PLAN-ADDENDUM-4.md` line 595 / line 631: V3.3 §3.1 Phase-task entity coverage is also numbered **Check 25**.

If both land mechanically as planned, two `def check_25_*` functions appear in `scripts/validate-pack.py` — a duplicate-numbering defect and likely a Python `NameError` if both functions register against a numeric `CHECKS` registry.

§6.C MAINTAINER CHECK covers the **base plan's Checks 19–25 vs current validate-pack.py state** (existing Checks 1–20 at HEAD per `grep "^def check_" scripts/validate-pack.py | wc -l = 20`; HEAD has Check 16 / 17 / 18 / 19 / 20 already assigned). The base plan's Check 19 / 20 collide with existing Checks 19 / 20 already; §6.C correctly defers renumbering to BD-078 land-time.

Addendum 4 §6.O addresses Check 28 redundancy with the existing per-CLI agent parity check, but does **not** address the BD-089 ↔ Addendum 4 Check 25 collision. The reader who follows §6.C alone may not realize Check 25 has two distinct claimants.

**Severity:** `warning`. Recommended action: extend Addendum 4 §6.O (or add §6.O.1) to name this collision explicitly. Concrete edit in §5.1.

**§3.2.2 — V3.3 §8.4 contradicted by actual pack layout; Addendum 4 §6.M flags but architecture is left wrong.**

`ARCHITECTURE-V3.3-DELTA.md` lines 774–776:

> The pack-side `pack-auditor.md` follows the existing pack-side agent pattern: a single file under `.claude/agents/` (the existing `pack-architect.md`, etc., are Claude-specific; pack-side agents are not trinity-replicated because pack development happens primarily in Claude Code per the maintainer's pack-development workflow). No trinity replication is required at the pack-side.

Actual pack state (verified):

```
.claude/agents/  → pack-architect.md, pack-docs-researcher.md, pack-planner.md, pack-reviewer.md
.codex/agents/   → pack-architect.toml, pack-docs-researcher.toml, pack-planner.toml, pack-reviewer.toml
.gemini/agents/  → pack-architect.md, pack-docs-researcher.md, pack-planner.md, pack-reviewer.md
```

All four existing pack-side agents are per-CLI replicated (12 files total). V3.3 §8.4's claim is factually wrong against the live pack.

Addendum 4 §0 line 14 documents the verification correctly and §6.M flags it for maintainer resolution. But the architecture document itself remains unchanged. After commit, anyone reading V3.3 §8.4 in isolation will see the wrong claim.

**Severity:** `warning`. Recommended action: when the maintainer commits the corpus, add a one-line footnote or correction to V3.3 §8.4 noting "**Verified incorrect against live pack state per Addendum 4 §0 / §6.M; pack-side IS per-CLI replicated. This sentence was authored under a mistaken premise; pack-side `pack-auditor` ships per-CLI per §6.M (a).**" Or equivalent. Concrete edit in §5.2.

### §3.3 Nits

**§3.3.1 — V3.3 §11 recommendation summary references BD-110 cadence at "before major version implementation pass" which post-dates v11.0 itself.**

V3.3 §11 / V3.3 §8.3 says cadence triggers include "before starting a major version's implementation pass (after architect + planner; before BDs land)." For v11.0 itself, this cadence cannot be honored — `pack-auditor` is being introduced *as part of* v11.0; it cannot run *before* v11.0 implementation. Addendum 4 §1.5 and §2.15 (BD-100 CP1/CP2/CP3 extension) handle this by making the cadence start at v11.0 CP-points rather than before the v11.0 implementation pass. The prose in V3.3 §11 is forward-looking from v11.1 onward but reads as if applicable to v11.0.

**Severity:** `nit`. No action required; reader-orientation only. The plan correctly carries the trigger forward.

**§3.3.2 — Addendum 4 §1.5 BD-110 §6.N "Recommendation: (a)" depends on BD-074 having shipped `audit-methodology` at pack root, but BD-074's scope (base plan §1.8 lines 324–344) ships `pack-startup` Step 8 only — not the `audit-methodology` skill.**

BD-074 in `IMPLEMENTATION-PLAN.md` lines 324–344 specifies: append Step 8 to `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`, `.gemini/commands/pack-startup.toml` (PACK-ROOT) plus `project-template/skills/pm-startup/SKILL.md` and three distributed copies. There is no `audit-methodology` skill ship in BD-074's file list. §6.F MAINTAINER CHECK (line 1078) confirms BD-074 introduces the pack-root `.claude/`, `.codex/`, `.gemini/` directories for the first time, but it ships `pack-startup` only.

If §6.N's recommendation (a) requires BD-074 to ship `audit-methodology` and `architecture-review` skills as well, BD-074 needs an explicit scope extension — but Addendum 4 doesn't formally extend BD-074. The §6.N text says "Recommendation: (a) — verify at BD-074 land-time. If BD-074's skill set already includes both, BD-110 has no extra work. If BD-074's set is `pack-startup` only, BD-110 ships them." The fallback is in BD-110's scope, so the dependency resolves either way.

This is a soft inconsistency that resolves at land-time. Not a structural issue.

**Severity:** `nit`. The §6.N maintainer check correctly anticipates both branches; no edit required pre-commit.

**§3.3.3 — V3.3 §6.5 D-18 carrier matrix extension lists "BD-NNN | `<!-- template_version: bd-v11.0.0 -->` | `template:bd-v11.0.0`" but V3 §I.3 / V2 §26 use `bd-v11.0` (no third version digit).**

V3 §I.3 + V2 §26 establish the template-version label at major.minor granularity (`bd-v11.0`). V3.3 §6.5 introduces three-digit versions (`bd-v11.0.0`). Both forms appear in the corpus.

If both carriers ship as written, the dual-carrier matrix is internally inconsistent: BD-069's existing implementation reads `bd-v11.0` and BD-106 / Addendum 4 §2.6 writes `phase-task-v11.0.0`. The reverse-migration reconciliation would need to handle both forms or risk silent drift.

**Severity:** `nit` (potentially `warning` if not aligned at BD-064 land-time). Recommended action: align to one form. The architect's V2 §26 form is `bd-v11.0` (two-digit); recommend V3.3 follow suit and use `bd-v11.0`, `td-v11.0`, `phase-epic-v11.0`, `phase-task-v11.0`. Or alternatively, V3.3 chose the more specific form because v11.x can have multiple template versions per minor; if so, BD-069's existing carrier strings need to change to three-digit. Either way, decide before BD-064 / BD-069 / BD-106 land.

**§3.3.4 — Addendum 4 §1.4 BD-109 ships Codex `.toml` agent files, but BD-109's per-CLI parity Check 28 specifies "the `.toml` form's `prompt = """..."""` block content matches the `.md` body content of the other two."**

V3.3 §8.2 says agent file is `.codex/agents/auditor-issue-tracking.toml`. Addendum 4 §1.4 says same. The Check 28 spec at §3.4 says Codex form is TOML with `prompt = """..."""` content matching the markdown body of Claude/Gemini.

Verified against live pack: pack-side `.codex/agents/pack-architect.toml` and project-template `.codex/agents/auditor-architecture.toml` both use this TOML format. The Check 28 spec is consistent with the existing Codex agent format.

This is correct; flagging only because the §3.4 spec's "line-comparison or normalized-content hash" approach needs the planner to design a normalizer that strips TOML wrapper before comparing. Implementation detail; not a finding.

**Severity:** `nit` (planner detail). No edit required pre-commit.

### §3.4 Info

**§3.4.1 — Pack-root pack-startup skill exists in `.claude/skills/` but not in `.codex/skills/` or `.gemini/skills/` at HEAD.**

Verified: `.claude/skills/pack-startup/SKILL.md` exists; `.codex/skills/pack-startup/` does not; `.gemini/skills/pack-startup/` does not. BD-074 (per §6.F) is supposed to ship the missing two. This is by design and on the plan; not a finding.

**§3.4.2 — `audit-methodology` skill not present at pack-root in any CLI variant at HEAD.**

Required by `pack-auditor` per V3.3 §8.3 (and conditionally `architecture-review`). §6.N flags the dependency; either BD-074 or BD-110 ships it. Not a finding pre-commit.

**§3.4.3 — V3.3-DELTA prose at line 7 says "The base IMPLEMENTATION-PLAN.md and Addenda 1, 2, 3 are approved and unchanged at the BD-content level."**

This is an architect-authored claim that the addenda are stable. Addendum 4 §0 line 4 confirms scope = "integrates V3.3-DELTA into the v11 implementation plan." No contradiction. The corpus is internally consistent.

## §4. Specific checks

### §4.1 Cross-document consistency

V3.3 §9.1 enumerates blast radius across V1 / V2 / V3 / V3.1-DELTA / V3.2-DELTA. Addendum 4 §2 (16 existing-BD extensions) maps to V3.3 §9.2 cleanly. Each existing BD's extension scope:

| BD | V3.3 §9.2 named | Addendum 4 §2 covers | Consistency |
|---|---|---|---|
| BD-063 | yes | §2.1 | consistent |
| BD-064 | yes | §2.2 | consistent |
| BD-065 | yes | §2.3 | consistent |
| BD-067 | yes | §2.4 | consistent |
| BD-068 | yes | §2.5 | consistent |
| BD-069 | yes | §2.6 | consistent |
| BD-072 | yes | §2.7 (deferred to v11.1) | consistent (defer is documented) |
| BD-076 | yes | §2.8 | consistent |
| BD-080 | yes | §2.9 | consistent |
| BD-082 | yes | §2.10 | consistent (modulo §3.2.1 numbering) |
| BD-084 | yes | §2.11 | consistent |
| BD-094 | yes | §2.12 | consistent |
| BD-096 | yes | §2.13 | consistent |
| BD-098 | yes | §2.14 | consistent |
| BD-100 | yes | §2.15 | consistent |
| BD-105 | yes | §2.16 (deferred to v11.1) | consistent |

All 16 enumerated BDs are extended consistently. No contradictions found between Addendum 4's extensions and the base plan or earlier addenda.

Addenda 1, 2, 3 hold under V3.3:
- Addendum 1's MERGE-STRATEGY (BD-094) extended by Addendum 4 §2.12 with IMPLEMENTATION-PLAN.md row.
- Addendum 2's BD-102 (pack dog-food) and BD-103 (`pack tracker reset`) are unaffected by V3.3's mechanics; both touch surfaces V3.3 doesn't reshape.
- Addendum 3's BD-104 (rename) lands at step 22c; V3.3-DELTA already uses post-rename form (`IMPLEMENTATION-PLAN.md` throughout) — consistent.
- Addendum 3's BD-105 (STATUS dual-link) extended by Addendum 4 §2.16 to optionally child-link to phase-task issue list (deferred to v11.1).

### §4.2 V3.2 supersession discipline

Grep against the live corpus (`ARCHITECTURE.md`, `ARCHITECTURE-V2.md`, `ARCHITECTURE-V3.md`, `ARCHITECTURE-V3.1-DELTA.md`, `ARCHITECTURE-V3.3-DELTA.md`, `IMPLEMENTATION-PLAN.md`, all four addenda):

| V3.2-specific element | Hits in live corpus | Disposition |
|---|---|---|
| `Path 3` / `Path-3` / `path-3` | All hits in V3.3-DELTA (legitimate supersession context) and Addendum 4 (legitimate "remove fixture" / "verify absent" / "release-readiness grep" instructions). Zero stray hits. | clean |
| `--fold-into` | All hits in V3.3-DELTA (supersession table) and Addendum 4 (release-readiness grep, Path 3 fixture removal). Zero stray hits. | clean |
| `folded-into:` label | Hits in V3.3-DELTA (supersession), Addendum 4 (BD-106 §1.1 negative DoD: "`folded-into:` is not present"; BD-107 grep). Zero stray hits. | clean |
| Inline `(from TD-NNN)` body marker | All hits in V3.3-DELTA + Addendum 4 (negative DoD). V1 §6.2 line 1242 / 1749 hits are unrelated query phrasing ("walk dependency tree from TD-031") — not the V3.2 marker. | clean |
| "L3 phase task" placement | V3.3 supersedes; live corpus places phase tasks at L2; Addendum 4 §1.1 BD-106 "L2 placement" consistent. Zero stray references to L3 phase task placement. | clean |

V3.2-DELTA itself remains in the directory as historical record per the architect's stated intent (V3.3 §1 "V3.2-DELTA is a historical proposal in `maintenance-docs/v11-research/`. It is not deleted; it stands as the prior-pass record.").

**Verdict: pass.** Supersession discipline holds.

### §4.3 Hierarchy consistency

| Doc | L1 placement | L2 placement | L3 placement | Notes |
|---|---|---|---|---|
| V1 §5.1 (line 859) | "Phase epic (project) or version epic (pack repo)" | TD-NNN / BD-NNN | sub-tasks (rare) | **Superseded by V3.3 §2.6.** V1 unchanged; supersession by reference is the architect's convention. |
| V3 (preserves V1) | as V1 | as V1 | as V1 | preserved-OK |
| V3.1-DELTA | n/a | n/a | n/a | M2/L1/A2 don't touch hierarchy |
| V3.3-DELTA §2 | phase epic + TD-NNN + BD-NNN as semantic peers (no parent-child) | phase task | reserved | new authoritative shape |
| V3.3-DELTA §2.6 | pack BDs explicitly L1 with no version-epic parent | n/a | n/a | "version epic" wording from V1 §5 line 859 explicitly superseded |
| IMPLEMENTATION-PLAN base + Addenda 1, 2, 3 | (does not directly opine on hierarchy at the BD level; references V1) | n/a | n/a | consistent |
| Addendum 4 §1.1 BD-106 | TD/BD at L1 (peers); phase epic at L1 | phase task at L2 (parented) | reserved | matches V3.3 §2 |
| Addendum 4 §1.4 BD-109 | (audit reads the hierarchy; doesn't define) | n/a | n/a | consistent |

**Verdict: consistent.** L1 = phase epic + TD-NNN + BD-NNN as peers; L2 = phase task; L3 = reserved. Pack BDs flat at L1 with no version-epic parent (V3.3 §2.6). Live corpus is end-to-end consistent.

### §4.4 Trinity rule

Trinity-rule scope across Addendum 4:

| Trinity surface | File-wise replication | Content-wise rule |
|---|---|---|
| Pack-root CLAUDE.md / AGENTS.md / GEMINI.md | n/a (single file each, not per-CLI) | Per V3.3 §9.7: not engaged at v11.0 by V3.3 work |
| Project-template CLAUDE.md / AGENTS.md / GEMINI.md | n/a (single file each per surface) | Per V3.3 §9.7: not engaged at v11.0 by V3.3 work |
| Pack-side `pack-architect.md` / `pack-planner.md` / `pack-reviewer.md` / `pack-docs-researcher.md` / `pack-auditor.md` (NEW) | per-CLI × 3 (×4 existing + 1 new = 15 files) | BD-110 ships 3 files per V3.3 §6.M (a); per-CLI parity already in place for existing 4 |
| Project-template per-agent prompts (`auditor.md`, 7 cluster sub-agents, +`auditor-issue-tracking` NEW) | per-CLI × 3 | BD-109 ships 3 files in one commit (Check 28 enforces) |
| Pack-side / project-template skills (`audit-methodology`, `architecture-review`) | per-CLI × 3 | BD-110 §6.N may ship via BD-074 or BD-110 |
| HELP-FRAGMENT-PACK.md / HELP-FRAGMENT-TRACKER.md / HELP-FRAGMENT.md | non-trinity (pack-root canonical + project-template mirror) | per V3.1-DELTA L1; Check 24 enforces byte-identity |

**Verdict: pass.** Trinity rule applied correctly:

- BD-109 ships project-side per-CLI agent file in three forms in one commit; auditor.md parent table extended in three forms in one commit; audit-methodology skill extended in three forms in one commit. Total of 9 files in one commit. Check 28 enforces.
- BD-110 ships pack-side `pack-auditor` in three per-CLI forms in one commit per maintainer-resolved §6.M (a). Matches existing pack-side per-CLI layout (4 existing agents × 3 CLIs = 12 files; +1 new × 3 = +3 files).
- Pack-root trinity content not engaged by V3.3 work; matches V3.3 §9.7's stated policy.

### §4.5 A1 UX

Every new failure path routes through typed errors per V1 §9 / D-7:

| Failure path | Routed via | BD |
|---|---|---|
| Cross-entity link failure | typed error per V1 §9; verb name `pack tracker doctor` | BD-108 |
| Cycle-check refusal | typed error `tracker-cycle-detected`; in-memory edit preserved | BD-108 |
| Promotion-target-missing | typed error `promote-target-not-found` | BD-107 |
| Phase-task parser failure on malformed `### Tasks` | warning (not error); migration continues | BD-106 |
| Auditor agent (read-only) | n/a — read-only; no write-failure surface | BD-109 / BD-110 |

Addendum 4 §7.3 enumerates all four routed paths plus the read-only auditor exemption. **Verdict: pass.** No silent retry; no fallback that masks the failure.

### §4.6 Bidirectionality

Addendum 4 §7.4 audits the bidirectionality contract:

- BACKLOG `Blockers:` field grammar: every legal v10 form continues to parse (regression-tested by including v10-only fixtures in BD-108's `test-cross-entity-links.sh` per Addendum 4 §1.3 DoD).
- Phase-task `Dependencies` bullet grammar: the grammar prior to v11.0 was free-form prose; v11.0 codifies a parser-recognized subset. Free-text annotation after the matched ID prefix is preserved per V3.3 §5.3 last paragraph + maintainer-resolved §6.R (`annotation` sub-field added to sidecar `dependency_edges`).

The two grammar extensions are **additive**: every legal v10 form remains legal. Round-trip is byte-equivalent on tracker side (V3.3 §3.3 / §3.4 explicitly state); whitespace-tolerant on flat-file side (V1 §6.7 carries forward).

Tracker-only enrichment (assignee, comments, reactions, audit log; per-task `dependency_edges`; `task_order`) routed to sidecar per V1 §6.6 / §6.6.1 (V3.1-DELTA A2).

**Verdict: pass.** Bidirectionality contract honored.

### §4.7 Path-3 forbidden

The TD-promotion paths in V3.3 are exactly:

1. Direct close — `pack td resolve` or BACKLOG-edit; v10 lifecycle unchanged.
2. Path 1 — `pack td promote --to=phase-N`; new phase epic at L1.
3. Path 2 — `pack td promote --to=phase-N.M`; new phase task at L2.

No third path. No fold-mechanism. No inline body marker. Verified by §4.2 supersession-discipline check above (zero stray references to V3.2 elements). The `promote` verb always creates a new entity; the alternative ("edit existing phase task body and direct-close the TD") is **outside** the promotion mechanism per V3.3 §3.1 paragraph 4.

**Verdict: pass.** Path 3 forbidden enforcement holds.

### §4.8 §3.3 commit-order acyclicity

Merging base plan §3.3 (steps 1–34) with Addenda 1–4 lettered insertions:

```
1. BD-060
2. BD-061
3. BD-063
4. BD-064
5. BD-070
6. BD-065
7. BD-066
8. BD-067
9. BD-068
   9a. BD-105 (Addendum 3)
   9b. BD-106 (Addendum 4)
   9c. BD-108 (Addendum 4)
   9d. BD-107 (Addendum 4)
10. BD-069
11. BD-062
12. BD-071
13. BD-072
14. BD-073
15. BD-074
16. BD-076
17. BD-075
18. BD-077
19. BD-088
   19a. BD-094 (Addendum 1)
20. BD-091
   20a. BD-098 (Addendum 1)
21. BD-080
22. BD-085
   22a. BD-095 (Addendum 1)
   22b. BD-101 (Addendum 1)
   22c. BD-104 (Addendum 3)
[CP3 audit]
23. BD-081
   23a. BD-109 (Addendum 4)
   23b. BD-082 ext — Check 28 (Addendum 4)
24. BD-082
   24a. BD-082 ext — Checks 25-27 (Addendum 4)
25. BD-078
26. BD-079
27. BD-089
28. BD-083
29. BD-092
30. BD-084
   30a. BD-099 (Addendum 1)
   30b. BD-096 (Addendum 1)
31. BD-090
32. BD-086
33. BD-087
   33a. BD-097 (Addendum 1)
   33b. BD-103 (Addendum 2)
   33c. BD-102 (Addendum 2)
   33d. BD-110 (Addendum 4)
34. BD-093
```

Spot-check Blockers acyclicity for new BD-106..BD-110:

- BD-106 Blockers: BD-063 (step 3), BD-064 (step 4), BD-065 (step 6), BD-067 (step 8) — all earlier than BD-106's step 9b. ✅
- BD-107 Blockers: BD-106 (step 9b), BD-108 (step 9c) — both earlier than BD-107's step 9d. ✅
- BD-108 Blockers: BD-106 (step 9b), BD-070 (step 5) — both earlier than BD-108's step 9c. ✅
- BD-109 Blockers: BD-082 recommended sequencing (per Addendum 4 §1.4 line 201 — "lands after BD-082 so the per-CLI agent parity check (Check 28) is in place"). BUT step 23a (BD-109) lands BEFORE step 24 (BD-082). The lettered-step convention places 23a between BD-081 (step 23) and BD-082 (step 24). The "lands after BD-082" sequencing claim conflicts with step 23a / step 24 ordering. **Concern**: if BD-109 lands at step 23a and BD-082 at step 24, then BD-109's per-CLI files exist before Check 28 exists. Step 23b (BD-082 ext — Check 28) is intended to land Check 28 in a paired commit immediately after step 23a. So BD-109 + BD-082-ext-Check-28 land as a pair, with BD-082's other Checks landing at step 24. This works, but is non-obvious. Acyclicity holds; sequencing comment in Addendum 4 §1.4 line 201 is misleading (says "after BD-082" but actually lands paired with BD-082's Check 28 sub-commit at step 23b).
- BD-110 Blockers: BD-074 (step 15) for skill-provenance — BD-074 lands earlier. ✅

**Verdict: acyclic.** CI green at every numbered + lettered boundary per Addendum 4 §6.1. The BD-109 sequencing prose at §1.4 line 201 is slightly inconsistent with the lettered insertion at step 23a — minor textual clarity issue (`nit`).

### §4.9 §6 MAINTAINER CHECK status

| Item | Origin | Status | Resolution |
|---|---|---|---|
| §6.A | base plan | resolved | Multi-template fixtures: ship empty bd-v11.1/, bd-v11.2/ dirs |
| §6.B | base plan | resolved | `pack-help.sh` ships first time at v11 |
| §6.C | base plan | deferred (correctly) | Validate-pack Check numbering audit at BD-078 land-time |
| §6.D | base plan | deferred (correctly) | BD-042 scope reconciliation at BD-091 land-time |
| §6.E | base plan | resolved | D-6 footnote scope: project-template trinity only |
| §6.F | base plan | resolved | BD-074 introduces .claude/.codex/.gemini at pack-root |
| §6.G | Addendum 1 | resolved | (per Addendum 1 §6.G line) |
| §6.H | Addendum 1 | resolved | (per Addendum 1 §6.H line) |
| §6.I | Addendum 1 | resolved | (per Addendum 1 §6.I line) |
| §6.J | Addendum 2 | resolved | (a) flat-file at v11.0 |
| §6.K | Addendum 2 | resolved | (per Addendum 2 §6.K line) |
| §6.L | Addendum 3 | resolved | (a) keep current; no STATUS.md template |
| §6.M | Addendum 4 | resolved | (a) per-CLI replication for pack-auditor |
| §6.N | Addendum 4 | deferred (correctly per land-time) | BD-074 vs BD-110 skill-shipping decision |
| §6.O | Addendum 4 | deferred (correctly per land-time) | Check 28 redundancy with existing per-CLI parity check |
| §6.P | Addendum 4 | resolved | (a) architect-by-default for Path 1 |
| §6.Q | Addendum 4 | resolved | (a) K=10 default, configurable |
| §6.R | Addendum 4 | resolved | (a) annotation sub-field on dependency_edges |

Two genuine deferrals (§6.N, §6.O) match the addendum's explicit framing. §6.C (base plan) was deferred and remains deferred under Addendum 4 — but Addendum 4's new Check 25 collision with BD-089's Check 25 is **not** explicitly captured; this is the §3.2.1 warning.

**Verdict: pass except §3.2.1.** The MAINTAINER CHECK framework is well-applied; one collision should be added to §6.C's scope or surfaced as a new sub-item.

### §4.10 New gaps surfaced

**§4.10.1 — IMPLEMENTATION-PLAN.md §4.2 line 987 says "After v11.0, validate-pack.py runs Checks 1–10 (existing v10) plus..." — but actual HEAD has Checks 1–20.** The plan's §6.C MAINTAINER CHECK (line 1066) acknowledges the discrepancy and directs the planner to audit at BD-078 land-time. So this is a known deferred item, not a new gap. But the plan prose at §4.2 line 987 is factually wrong against HEAD. Optional textual fix: "Checks 1–20 (existing v10 + v10.x extensions)."

**§4.10.2 — V3.3 §6.5 D-18 carrier matrix uses three-digit version (`bd-v11.0.0`); V2 §26 uses two-digit (`bd-v11.0`).** See §3.3.3 above. Decide before BD-064 / BD-069 / BD-106 land.

**§4.10.3 — Addendum 4 §1.4 BD-109's "Recommended sequencing: lands after BD-082" prose conflicts with lettered insertion at step 23a (which is before step 24's BD-082).** See §4.8 above. Minor clarity issue.

**§4.10.4 — Addendum 4 §6.1 commit-order list includes "[CP3 audit — BD-100 report]" between step 22c and step 23 (inherited from Addendum 3 §2.1). BD-110 (Addendum 4) extends BD-100 CP1/CP2/CP3 prompts to invoke `pack-auditor`. But BD-110 lands at step 33d, AFTER the [CP3 audit] runs at step 22c-23 boundary. So the FIRST run of CP3 (during v11.0 implementation) cannot use `pack-auditor` because BD-110 hasn't shipped yet.** This is correctly noted in Addendum 4 §1.5 ("**MAINTAINER CHECK §6.M:** ... the BD-100 CP-prompt extensions are textual; CP1/CP2/CP3 reports themselves are maintainer-driven and re-run incorporates the new step on next invocation"). Not a defect; documented behavior.

**§4.10.5 — Addendum 4 §1.4 BD-109 §1.4 lines 192–198 places BD-109 as "Independent of BD-106..108 (the agent reads pack state but does not depend on phase-task tooling existing)."** The auditor-issue-tracking sub-agent's prompt body (V3.3 §8.2 lines 503–600) does include phase-task-related checks ("Phase tasks marked Done in IMPLEMENTATION-PLAN.md have a corresponding `status:done` label in tracker mode"). If BD-109 lands at step 23a (before BD-106's step 9b is the right way of reading the lettered convention; actually 23a is *after* 9b). Re-checking: 9b/9c/9d come before 23a. So BD-106 has shipped before BD-109. The "Independent of BD-106..108" claim is sequencing-soft (BD-109 *could* land before BD-106 in principle, but the planner sequenced it after for fixture-ready coverage). Not a defect.

## §5. Recommendations

### §5.1 (Warning) Extend Addendum 4 §6.O to cover Check 25 collision

**File:** `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-4.md`

**Current §6.O (line 824):** addresses Check 28 redundancy only.

**Recommended addition** — add a new sub-item §6.O.1 (or rename §6.O to cover both):

```
- **§6.O.1 — Check 25 numbering collision: BD-089 (base plan) vs Addendum 4
  §3.1.** Base plan BD-089 (`IMPLEMENTATION-PLAN.md` line 770) ships Check 25
  as the customization-detection regression guard (BD-059 fix). Addendum 4
  §3.1 (line 595) also numbers the phase-task entity-coverage check as Check
  25. Two distinct functions cannot share the same Check number. Per §6.C
  audit framework, the planner runs `grep "def check_" scripts/validate-pack.py`
  at BD-078 land-time; the actual next-free integer absorbs the v11 Checks
  contiguously. Apply the same renumbering at BD-082 ext (24a) for the V3.3
  Checks 25–28: they become Checks N..N+3 where N is the next free integer
  after BD-089's customization-detection check (which itself may renumber
  under §6.C).
  - **Recommendation:** explicit acknowledgement that the V3.3 Checks
    25/26/27/28 are NOT guaranteed to be 25/26/27/28 in `validate-pack.py`;
    the numbers are pedagogical references in this addendum. The planner
    re-numbers contiguously at BD-082 land-time per §6.C. The check NAMES
    (`check_phase_task_coverage`, `check_cross_entity_reference_resolution`,
    `check_promotion_label_consistency`, `check_per_cli_auditor_issue_tracking_parity`)
    are stable; the numbers are not.
```

Severity: warning. Maintainer can apply this textual edit directly.

### §5.2 (Warning) Add correction footnote to V3.3 §8.4 about pack-side per-CLI replication

**File:** `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`

**Current §8.4 lines 774–776:**

> The pack-side `pack-auditor.md` follows the existing pack-side agent pattern: a single file under `.claude/agents/` (the existing `pack-architect.md`, etc., are Claude-specific; pack-side agents are not trinity-replicated because pack development happens primarily in Claude Code per the maintainer's pack-development workflow). No trinity replication is required at the pack-side.

**Recommended replacement:**

> The pack-side `pack-auditor.md` follows the existing pack-side agent pattern. **Authored under a mistaken premise that the pack-side is single-CLI; verified incorrect against live pack state per IMPLEMENTATION-PLAN-ADDENDUM-4 §0 / §6.M. The actual pack-side layout is per-CLI replicated (`.claude/agents/`, `.codex/agents/`, `.gemini/agents/` each contain `pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` — 12 files total). `pack-auditor` ships per-CLI to match per maintainer-resolved §6.M (a) — three files (`.claude/agents/pack-auditor.md`, `.codex/agents/pack-auditor.toml`, `.gemini/agents/pack-auditor.md`).** Trinity rule applies file-wise to the pack-side per-CLI replicas as it does for the existing four pack-side agents.

Severity: warning. Maintainer can apply this textual edit directly. Alternatively, leave V3.3 §8.4 as-is and rely on Addendum 4 §0 / §6.M for the correction; the corpus is internally consistent because §6.M is resolved as (a). The footnote prevents future readers from being misled by V3.3 §8.4 in isolation.

### §5.3 (Nit) Align template-version digit convention

**Files:** `ARCHITECTURE-V3.3-DELTA.md` §6.5; `ARCHITECTURE-V2.md` §26 (where carriers are first specified); `IMPLEMENTATION-PLAN-ADDENDUM-4.md` §2.6.

**Issue:** V2 §26 uses two-digit (`bd-v11.0`); V3.3 §6.5 uses three-digit (`bd-v11.0.0`). Pick one before BD-064 / BD-069 / BD-106 land.

**Recommendation:** the planner audits at BD-064 land-time. If V2's two-digit is the established convention, V3.3 §6.5's three-digit references update to match. If three-digit is intentional (covers v11.0.0 vs v11.0.1 patch granularity within v11.0), V2 §26 references update — but this would extend D-18 retroactively. Recommend two-digit unless three-digit serves a documented purpose.

Severity: nit. Defer to land-time per the existing land-time-audit pattern.

### §5.4 (Nit) Clarify Addendum 4 §1.4 BD-109 sequencing prose

**File:** `IMPLEMENTATION-PLAN-ADDENDUM-4.md` §1.4 line 201.

**Current:** "Recommended sequencing: lands after BD-082 so the per-CLI agent parity check (Check 28) is in place."

**Issue:** Step 23a (BD-109) is *before* step 24 (BD-082). The "lands after BD-082" prose is misleading.

**Recommended replacement:** "Recommended sequencing: lands paired with the BD-082 extension that introduces Check 28 (step 23b in §6.1 commit order); the agent files at step 23a and the parity check at step 23b land as paired commits, keeping CI green at the boundary."

Severity: nit. Optional clarity fix.

### §5.5 (Nit / Info) IMPLEMENTATION-PLAN.md §4.2 Check-count statement

**File:** `IMPLEMENTATION-PLAN.md` §4.2 line 987.

**Current:** "After v11.0, validate-pack.py runs Checks 1–10 (existing v10) plus..."

**Actual HEAD state:** validate-pack.py has 20 check functions (Checks 1–20).

**Recommendation:** update to "Checks 1–20 (existing v10 + v10.x extensions)." Or leave with §6.C MAINTAINER CHECK already noting the discrepancy. No action strictly required.

Severity: info / nit.

## §6. Go / no-go

**GO for commit-and-implement.**

The corpus is substantively complete and internally consistent. Two prior reviewer passes have surfaced and resolved all blocker-class issues. This pass surfaces:

- Zero blockers.
- Two warnings (§5.1, §5.2) — both fixable as direct textual edits the maintainer can apply pre-commit, or which can be acknowledged at land-time per the existing MAINTAINER CHECK framework. Neither requires architect or planner re-spawn.
- Three nits (§5.3, §5.4, §5.5) — optional clarity improvements; none blocking.

The recommended sequence:

1. Maintainer applies §5.1 (Addendum 4 §6.O extension or new §6.O.1) and §5.2 (V3.3 §8.4 correction footnote) as direct textual edits — ~10 minutes total.
2. Optionally apply §5.3, §5.4, §5.5 for clarity.
3. Commit the corpus. Begin BD-060 (step 1 of §3.3 commit order).

The decision integrity check (§2) shows all 23 active decisions traceable to origin, mechanism, and implementing BD. The supersession discipline check (§4.2) shows V3.2-DELTA elements correctly absent from the live corpus. The hierarchy check (§4.3) shows L1/L2/L3 placement consistent end-to-end. The trinity check (§4.4), A1 UX check (§4.5), bidirectionality check (§4.6), and Path-3-forbidden check (§4.7) all pass. The §3.3 commit-order acyclicity check (§4.8) verifies CI green at every numbered + lettered boundary.

**Next step explicitly:** maintainer applies §5.1 + §5.2 textual edits, then proceeds to commit-and-implement starting with BD-060 (step 1 of merged §3.3 commit order).

Honest assessment: the corpus is in genuinely good shape. Five architect passes and four planner passes have produced a coherent design package. The only outstanding issues are textual housekeeping that doesn't affect mechanism. The maintainer's resolution of §6.M / §6.P / §6.Q / §6.R during this pass closed the substantive open questions; §6.N and §6.O remain land-time deferrals that the addendum's framing supports.

— end of PASS3 review —
