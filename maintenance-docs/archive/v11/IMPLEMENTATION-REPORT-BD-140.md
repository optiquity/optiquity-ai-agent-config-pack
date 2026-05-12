# Implementation Report — BD-140 (Skill-dimensions reframe — BACKLOG entries umbrella)

**Batch:** 1 of 11 (skill-dimensions reframe v11.0 work).
**Scope:** Single-file BACKLOG-ops batch. Adds 16 new BD entries (BD-140..BD-150 v11.0 work-items + BD-151..BD-155 v12-deferred).
**Coder:** pack-coder agent, 2026-05-11.
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` on branch `v11-dev`.

---

## 1. Pre-flight state

| Item | Value |
|---|---|
| Branch | `v11-dev` |
| Pre-batch HEAD SHA | `76ffd756245e330977fa78f5c243c18c56205be1` |
| `git status` (pre-batch) | clean |
| BACKLOG.md pre-batch line count | 3336 |
| Highest existing BD pre-batch | **BD-139** (confirmed via `grep -oE "^\\*\\*BD-[0-9]+" BACKLOG.md \| sort -u \| tail`) |
| Pre-batch `Status: Open` count | 27 |
| Pre-batch `Status: Deferred` count | 5 |

Highest-existing-BD confirmation matches the spec (BD-139). No collision.

---

## 2. Format conformance

### 2.1 Format observed in BACKLOG.md

Each BD entry in the existing file uses this template:

```
**BD-NNN — Title**
Type: TODO(version)[ — provenance note]
Status: Open|Resolved|Deferred|Cancelled
Blockers: <BD-NNN list, "none", or "<version> — <reason>">
Unblocks: <BD-NNN list or "None">
File/Symbol: <files>
Description: <description paragraph(s)>
Resolved: <date — pointer or "n/a">

---
```

Field order is invariant: `Type:`, `Status:`, `Blockers:`, `Unblocks:`, `File/Symbol:`, `Description:`, `Resolved:`. A blank line separates `Resolved:` from the trailing `---` separator.

### 2.2 Spec-vs-BACKLOG conformance decisions

The implementation prompt's spec named several fields/values that conflict with the actual BACKLOG.md convention. Per the operating rule "If BACKLOG.md uses a different field naming convention than what the spec assumes, MATCH BACKLOG.md, not the spec — file format consistency is the priority," I adopted the BACKLOG conventions:

| Spec said | BACKLOG.md uses | Decision |
|---|---|---|
| `Created: 2026-05-11` field | No `Created:` field anywhere (0 occurrences) | OMIT `Created:`; encode date in `Type:` line as "surfaced 2026-05-11 during ..." (matches BD-138, BD-127, BD-126, BD-125 convention) |
| `Type: TODO(v11.0)` for BD-140..BD-150 | All entries use `Type: TODO(version)` (uniform) | Use `TODO(version)` (matches every existing v11 entry) |
| `Type: TODO(v12)` for BD-151..BD-155 | No `TODO(v12)` precedent; deferred entries (BD-055..BD-058) use `Type: TODO(version)` + `Status: Deferred` + `Blockers: <version> — ...` | Use `Type: TODO(version)`, `Status: Deferred`, `Blockers: v12 — <rationale>`, `Resolved: n/a` (matches BD-055..BD-058) |
| `Status: Open` for BD-151..BD-155 | Deferred items use `Status: Deferred` (BD-055..BD-058 precedent) | Use `Status: Deferred` (the conflict between "Status: Open" and "Blockers: v12" in the spec is resolved in favor of the existing BACKLOG convention which is unambiguous) |

These are format-conformance decisions, not spec deviations — the spec explicitly authorized them via the "MATCH BACKLOG.md" rule.

### 2.3 Insertion location

BACKLOG.md's "Active — v11 Scope" cluster has a non-trivial ordering:

- BD-060..BD-122 in ascending order (line 33 onward).
- BD-123..BD-139 in **descending** order (BD-139 at line 1339, BD-138 at 1355, ..., BD-123 at 1713).

The descending-block pattern is consistent with a "prepend newest at the top of the recent block" workflow: each new BD is added immediately above the previous newest. Following that established pattern, the 16 new entries are inserted as a contiguous block immediately ABOVE BD-139 (line 1339), in **descending order** (BD-155 at the very top → BD-140 just above BD-139). The resulting file ordering:

```
... BD-122, [BD-155, BD-154, ..., BD-141, BD-140], BD-139, BD-138, ..., BD-123
```

This preserves the prepend-newest convention: the next new BD added in a future batch will be prepended above BD-155.

---

## 3. Per-BD entry log

The full text of each appended entry follows. Entries are listed below in the order they appear in the file (descending — BD-155 first, BD-140 last).

### 3.1 BD-155 — Naming-convention enforcement migration (deferred to v12)

```
**BD-155 — Naming-convention enforcement migration (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — naming-convention codification (BD-149) lands in v11.0 as documentation-only ("Extending this file" prose); enforcement migration (rename existing skills to comply) is the v12 follow-on
Unblocks: full naming-convention compliance across the skill catalog (today the suffixes `*-best-practices`, `*-language`, `*-architecture`, `*-patterns` are all in active use without enforcement)
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" section (the convention codified by BD-149); skill directories under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` (rename targets in v12); `scripts/lib/migrator-skills.sh` (BD-147 deliverable would be reused for v11→v12 client-side renames)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10 the skill catalog uses four suffixes inconsistently — `*-best-practices` (idiomatic-style rules), `*-language` (ownership/memory/interop), `*-architecture` (platform-specific structural rules), `*-patterns` (cross-cutting concerns). The convention is not enforced. BD-149 codifies the convention in PLATFORM-SKILLS.md "Extending this file" so new skills follow it; existing skills are NOT renamed in v11.0 because the cost of breaking external references outweighs the consistency benefit at this point. v12 enforcement migration: identify non-compliant existing skill names, rename them, run BD-147's `migrator_skill_rename` API across client projects, update all SKILL.md cross-references and trinity prose, ship a v11→v12 migrator stage analogous to BD-035 / S5b. Defer until v12 per architecture §7.10 disposition.
Resolved: n/a
```

### 3.2 BD-154 — Skill-versioning frontmatter convention (deferred to v12)

```
**BD-154 — Skill-versioning frontmatter convention (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.9 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — adding versioning frontmatter requires the v12 skill-catalog cleanup pass (BD-155) so the version-stamp design lands once across a stabilized name set, not twice
Unblocks: machine-readable skill-version detection (today the migrator's S5b advisory pattern catches renames but a content-only major revision of a SKILL.md has no signal); cross-version drift diagnostics; `pack tracker doctor`-style skill-revision reporting
File/Symbol: every `SKILL.md` under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` (frontmatter addition); `scripts/validate-pack.py` (new check enforcing version frontmatter presence and well-formedness); `scripts/lib/detect.sh` (loader of the skill version stamp); `supporting-docs/MIGRATION-vN-to-vM.md` template (cross-version skill-revision diff section)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.9, skills do not carry a version stamp in their frontmatter. When the Python split happened (Python `python-architecture` → `python-server-architecture` + `python-data-architecture`, IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md), a project on v10.x reading `python-architecture/SKILL.md` and a project on v11.0 reading `python-server-architecture/SKILL.md` had no machine-readable way to know which version of the skill ruleset they were on. The migrator's BD-035 / S5b advisory pattern catches the rename, but if a SKILL.md gets a content-only major revision (no name change), there is no signal. v12 design: add a `version: <semver>` frontmatter key to every SKILL.md (Tier 0 base + Tier 1 + Tier 2); validator enforces presence + monotonic-bump on content change; loader exposes the version to consumers (auditor agents, migrator advisory). Defer until v12 per architecture §7.9 disposition.
Resolved: n/a
```

### 3.3 BD-153 — Tier 0 concurrency-architecture skill (deferred to v12)

```
**BD-153 — Tier 0 concurrency-architecture skill (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.3 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — same reorganization-cost rationale as BD-151 (observability) and BD-152 (accessibility); concurrency rules currently embedded in language-specific skills (`swift-best-practices` Swift 6 strict concurrency, `python-best-practices` asyncio, `apple-architecture-core` actor isolation) would need re-numbering to factor out
Unblocks: a single Tier 0 home for the universal concurrency principles (actor model, structured concurrency, cancellation propagation, backpressure); cleaner cross-language reasoning about concurrency patterns in audit-methodology and architecture review
File/Symbol: NEW `project-template/.claude/skills/concurrency-architecture/SKILL.md` (and `.codex/skills/...` / `.gemini/skills/...` trinity copies, byte-identical); existing source skills carrying concurrency rules today: `swift-best-practices/SKILL.md`, `python-best-practices/SKILL.md`, `apple-architecture-core/SKILL.md` (rule extraction + re-numbering); `project-template/docs/pack/PLATFORM-SKILLS.md` Tier 0 section (add the new skill row)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.3, concurrency rules are spread across `swift-best-practices` (Swift 6 strict concurrency), `python-best-practices` (asyncio), and `apple-architecture-core` (actor isolation). A Tier 0 `concurrency-architecture` skill would carry the universal principles (actor model, structured concurrency, cancellation propagation, backpressure). Same factoring risk as observability (BD-151) and accessibility (BD-152) — extracting the rules requires re-numbering the existing skills, which `auditor-architecture` cites by number, plus revising the audit-methodology cluster boundaries. Defer until v12 per architecture §7.3 disposition (note in BACKLOG as a known factoring opportunity).
Resolved: n/a
```

### 3.4 BD-152 — Tier 0 accessibility skill (deferred to v12)

```
**BD-152 — Tier 0 accessibility skill (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.2 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — adding an accessibility skill before the non-Apple UI skills land (web-architecture, android-architecture, embedded-mcu-architecture; Phase 2A/2B/3 of skill-dimensions reframe) would force premature factoring; once those skills are in, the shared accessibility patterns become visible and the right factoring obvious
Unblocks: a Tier 0 home for the universal accessibility principles (semantic landmarks, focus order, screen reader announcements as design constraints) currently scattered across `apple-architecture-core`, `ios-architecture`, `macos-architecture`, and the proposed `web-architecture` / `android-architecture`; complements the cross-platform audit-methodology rule 20 extension (architecture-doc §6.3, BD-143)
File/Symbol: NEW `project-template/.claude/skills/accessibility-architecture/SKILL.md` (and `.codex/skills/...` / `.gemini/skills/...` trinity copies, byte-identical); existing source skills carrying accessibility rules today: `apple-architecture-core/SKILL.md`, `ios-architecture/SKILL.md`, `macos-architecture/SKILL.md`, future `web-architecture/SKILL.md` and `android-architecture/SKILL.md` (rule extraction + re-numbering); `project-template/docs/pack/PLATFORM-SKILLS.md` Tier 0 section (add the new skill row); `audit-methodology/SKILL.md` rule 20 (cross-link)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.2, accessibility rules live in `apple-architecture-core`, `ios-architecture`, `macos-architecture`, and the proposed `web-architecture` / `android-architecture`. The proposed cross-platform audit-methodology rule 20 extension (architecture-doc §6.3, BD-143) addresses the audit side. The skill side does not have a Tier 0 home for the universal principles. Defer to v12 per architecture §7.2 disposition: adding the skill before the non-Apple UI skills land would force premature factoring; once web + Android + embedded-MCU are in, the shared patterns will be visible and the right factoring obvious.
Resolved: n/a
```

### 3.5 BD-151 — Tier 0 observability skill (deferred to v12)

```
**BD-151 — Tier 0 observability skill (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.1 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — extracting observability into a Tier 0 skill requires re-numbering rules in `ios-architecture`, `macos-architecture`, and `python-server-architecture` (which `auditor-architecture` cites by number), plus redrawing the `auditor-architecture` (infrastructure) vs `auditor-ops` (configuration) cluster boundary; the cost is non-trivial and best done with the v12 skill-catalog cleanup pass
Unblocks: a single Tier 0 home for "observability infrastructure" rules currently scattered as sub-bullets across `ios-architecture` (PLATFORM-SKILLS.md line 278), `macos-architecture` (line 279), `python-server-architecture` (line 282), with adjacent `auditor-ops` reading `deployment-apple` / `deployment-python` for "observability *configuration*" (line 224); two adjacent concerns split across four skills today
File/Symbol: NEW `project-template/.claude/skills/observability-architecture/SKILL.md` (and `.codex/skills/...` / `.gemini/skills/...` trinity copies, byte-identical); existing source skills carrying observability sub-bullets today: `ios-architecture/SKILL.md`, `macos-architecture/SKILL.md`, `python-server-architecture/SKILL.md` (rule extraction + re-numbering); `project-template/docs/pack/PLATFORM-SKILLS.md` Tier 0 section (add the new skill row); `auditor-architecture/SKILL.md` and `auditor-ops/SKILL.md` (cluster-boundary redefinition)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.1, `ios-architecture`, `macos-architecture`, and `python-server-architecture` each carry "observability infrastructure" as a sub-bullet (PLATFORM-SKILLS.md lines 278, 279, 282), while `auditor-ops` reads `deployment-apple` / `deployment-python` for "observability *configuration*" (line 224). Two adjacent concerns (infrastructure rules vs. config rules) are split across four skills. A dedicated Tier 0 `observability` skill would absorb the scattered sub-bullets. Absorption requires re-numbering rules in the existing platform skills (`auditor-architecture` cites by number) and redrawing the `auditor-architecture` (infrastructure) vs `auditor-ops` (config) cluster boundary. Defer until v12 per architecture §7.1 disposition.
Resolved: n/a
```

### 3.6 BD-150 — CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh

```
**BD-150 — CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh**
Type: TODO(version) — Batch 11 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 11)
Status: Open
Blockers: BD-146 (Check 31 must gate the new tables before the version-row CHANGELOG entry goes in), BD-148 (MIGRATION + MERGE-STRATEGY behavioral notes must exist before CHANGELOG quotes them)
Unblocks: v11.0 release-pin readiness (cross-cutting with BD-093 release pin); machine-readable skill counts in README are reconciled to post-reframe reality; downstream Phase 2A architect handoff (per `PLAN-SKILL-DIMENSIONS.md` §6)
File/Symbol: `CHANGELOG.md` v11.0 section (single entry referencing BD-141..BD-150 cluster as "skill-dimensions reframe — 5 dimensions + Tier 0 + intersection + trigger tables; behavioral note per `MIGRATION-v10-to-v11.md`"); `README.md` skill-count mentions ("30 skills" / "31 skills" instances must be reconciled to the post-reframe count); `README.md` v11.0 row in version table picks up the reframe BD references
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 11, the closing batch of the skill-dimensions reframe lands the CHANGELOG entry plus README skill-count refresh. Single CHANGELOG.md v11.0 entry referencing the BD-141..BD-150 cluster. README.md "30 skills" / "31 skills" mentions reconciled to the post-reframe count (which depends on whether the python split BD landed before or after the count was last touched — implementor verifies via `grep -n "skill" README.md`). README v11.0 row in version table picks up the reframe BD references. Critical-path gating per `PLAN-SKILL-DIMENSIONS.md` §1: BD-146 (Check 31 internal-consistency gate) and BD-148 (MIGRATION + MERGE-STRATEGY behavioral note) must have shipped first.
Resolved:
```

### 3.7 BD-149 — PLATFORM-SKILLS.md "Extending this file" naming convention codification (no skill renames)

```
**BD-149 — PLATFORM-SKILLS.md "Extending this file" naming convention codification (no skill renames)**
Type: TODO(version) — Batch 10 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 10)
Status: Open
Blockers: BD-142 (PLATFORM-SKILLS.md must be reframed before the "Extending this file" section can codify the new convention)
Unblocks: BD-155 (the v12 enforcement migration — cannot rename existing skills to comply with a convention that has not yet been codified)
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" section (NEW or extended; documents the four-suffix naming convention)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10, the skill catalog has four suffixes in active use: `*-best-practices` (`swift-best-practices`, `python-best-practices` — language style); `*-language` (`c-language`, `cpp-language`, `objc-language` — language structure where ownership / memory / interop dominate); `*-architecture` (`ios-architecture`, `macos-architecture`, `python-server-architecture`, `python-data-architecture`, `apple-architecture-core` — platform-specific structural rules); `*-patterns` (`grpc-patterns`, `rest-patterns`, `security-patterns` — cross-cutting concerns). The convention is not enforced; BD-149 documents it explicitly in PLATFORM-SKILLS.md "Extending this file" section per architecture §7.10 recommended disposition. Existing skills are NOT renamed in v11.0 — the cost of breaking external references outweighs the consistency benefit at this point; new skills must follow the convention. Enforcement migration (renaming existing non-compliant skills) is deferred to v12 (BD-155).
Resolved:
```

### 3.8 BD-148 — MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md skill-model-changes documentation

```
**BD-148 — MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md skill-model-changes documentation**
Type: TODO(version) — Batch 9 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 9)
Status: Open
Blockers: BD-142 (PLATFORM-SKILLS.md reframe must exist before MIGRATION + MERGE-STRATEGY can describe the change), BD-143 (trinity prose must be updated before MIGRATION can reference the new Skill-loading section)
Unblocks: BD-150 (CHANGELOG entry references the MIGRATION + MERGE-STRATEGY behavioral notes); v11.0 release-pin readiness on the migration-doc surface
File/Symbol: `supporting-docs/MIGRATION-v10-to-v11.md` (new "Skill model changes" section documenting the reframe as a behavioral note per architecture §7.8); `supporting-docs/MERGE-STRATEGY.md` (per-file matrix entry for PLATFORM-SKILLS.md updated to note the reframe; D5 monorepo gotcha per architecture §7.4; D2 reshape advisory per architecture §7.6); cross-link to BD-136 trinity-marker non-overlap (architecture §6.7)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 9, MIGRATION-v10-to-v11.md and MERGE-STRATEGY.md gain skill-model-change documentation. Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.8, the dimension reframe is a pack-product change masquerading as a doc change — PM chats re-read PLATFORM-SKILLS.md every time they generate a prompt, so the actual impact is minimal, but the v11.0 release notes and migration doc must call it out as a behavioral change, not a doc-only change. MIGRATION-v10-to-v11.md gets a new "Skill model changes" section. MERGE-STRATEGY.md per-file matrix entry for PLATFORM-SKILLS.md is updated; D5 monorepo gotcha (architecture §7.4 — "deployment skills load globally; agent prompts scope to component") and D2 reshape advisory (architecture §7.6 — "if you have locally edited PLATFORM-SKILLS.md, re-apply your edits manually") are documented. Cross-link to BD-136 trinity-marker non-overlap (architecture §6.7) confirms PLATFORM-SKILLS.md edits do not overlap with trinity Shape A / Shape B marker territory.
Resolved:
```

### 3.9 BD-147 — Extract S5b BD-035 rename helper into scripts/lib/migrator-skills.sh + Check 26 extension + BD-119 docs update

```
**BD-147 — Extract S5b BD-035 rename helper into scripts/lib/migrator-skills.sh + Check 26 extension + BD-119 docs update**
Type: TODO(version) — Batch 8 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 8 + §7.2 expanded scope)
Status: Open
Blockers: BD-142 (the reframe must establish the post-v11 skill catalog before the rename helper is generalized; otherwise the API would be designed against the v10 skill set)
Unblocks: future N→N+1 migrations needing skill renames or splits (e.g., the v12 BD-155 naming-convention enforcement migration); cleaner BD-119 migrator-core composition (skill-rename becomes a reusable adapter rather than an ad-hoc S5b inline helper)
File/Symbol: NEW `scripts/lib/migrator-skills.sh` (extracts BD-035 rename helper into reusable `migrator_skill_rename` API per architecture §6.5); `scripts/migrate-v10-to-v11.sh` S5b stage (rewritten to call the extracted helper); `scripts/validate-pack.py` Check 26 extension (recognizes the new lib in the migrator-core sourcing graph); `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` (docs update describing `migrator-skills.sh` as a sibling to `migrator-core.sh`); golden-snapshot fixture in `test-fixtures/v10-realistic-ot/` (pre-extraction migrator S5b output state-dir, used as behavior-equivalence baseline per BD-035 regression risk in `PLAN-SKILL-DIMENSIONS.md` §4.5)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.5 and `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 8 + §7.2 expanded scope, the BD-035 rename helper currently lives inline in the `scripts/migrate-v10-to-v11.sh` S5b stage. Extracting it into `scripts/lib/migrator-skills.sh` makes it reusable for future N→N+1 migrations needing skill renames or splits (notably the v12 BD-155 naming-convention enforcement migration). New API: `migrator_skill_rename <old-skill-dir> <new-skill-dir> [<advisory-text>]` plus a future `migrator_skill_split` for one-to-many cases (forward-declared; BD-035 only needs rename in v11.0). S5b is rewritten to call the extracted helper. Behavior-equivalence test per `PLAN-SKILL-DIMENSIONS.md` §4.5 mitigation: golden-snapshot the migrator's S5b output state-dir against the v10-realistic-ot fixture pre-extraction; compare post-extraction byte-for-byte. validate-pack.py Check 26 (BD-119 migrator-core sourcing graph) extended to recognize `migrator-skills.sh`. ARCHITECTURE-BD-119.md updated to describe the new sibling library.
Resolved:
```

### 3.10 BD-146 — validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension

```
**BD-146 — validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension**
Type: TODO(version) — Batch 7 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 7)
Status: Open
Blockers: BD-142 (Check 31 parses the new D1-D5 + Tier 0 + intersection tables — they must exist first), BD-143 (Check 31 also verifies agent files' "Skills to load" lists conform to the reframe-derived per-agent assignment; trinity prose update must precede)
Unblocks: BD-150 (CHANGELOG entry depends on Check 31 gating — proves the new tables are internally consistent before the version-row CHANGELOG goes in); ongoing CI gate for any future PLATFORM-SKILLS.md edit
File/Symbol: `scripts/validate-pack.py` NEW Check 31 (parses `project-template/docs/pack/PLATFORM-SKILLS.md`; verifies every existing SKILL.md under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` appears in exactly one cell of the D1-D5 / Tier 0 / trigger-loaded tables; verifies no skill is missing or double-counted); Check 27 extension (extends agent-file `Skills to load:` validation to conform to per-agent assignment derived from the new tables per architecture §5)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 7 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3-§5 + §3.7-§3.8, validate-pack.py gains Check 31 enforcing skill-cell consistency: every SKILL.md appears in exactly one cell across D1-D5 + Tier 0 + trigger-loaded tables; no orphan SKILL.md (present on disk but missing from PLATFORM-SKILLS.md); no phantom cell (referenced in PLATFORM-SKILLS.md but no SKILL.md on disk). Check 27 (per-agent skill-list validation, currently agent-file scoped) extends to verify the listed skills conform to the per-agent assignment derived from the new tables (architecture §5.1-§5.9). Per `PLAN-SKILL-DIMENSIONS.md` §4.3, the next free check number is 31; coder must `grep -nE "Check [0-9]+" scripts/validate-pack.py | tail` immediately before coding to verify still-free in case of mid-flight collision.
Resolved:
```

### 3.11 BD-145 — init-project.sh — D1/D5 detection hint + python-data marker integration

```
**BD-145 — init-project.sh — D1/D5 detection hint + python-data marker integration**
Type: TODO(version) — Batch 6 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 6)
Status: Open
Blockers: BD-141 (`python_data_marker_detected()` must exist for `pack_skill_coverage_for()` to call it), BD-142 (post-install hint points the PM chat at the new D1-D5 tables — those must exist first)
Unblocks: clean fresh-init flow under the reframed dimension model; eliminates the "init unconditionally lists `python-data-architecture`" detection inconsistency per architecture §7.5
File/Symbol: `scripts/init-project.sh` `pack_skill_coverage_for()` (line 219-228) — wires `python_data_marker_detected()` from BD-141 for the python row; post-install hint output at end of init pointing the PM chat at the new D1-D5 tables in PLATFORM-SKILLS.md
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 6, init-project.sh's `pack_skill_coverage_for()` is extended to (a) consult D1/D5 markers when listing applicable skills (per the reframed dimension model from BD-142), and (b) call `python_data_marker_detected()` from BD-141 for the python row so `python-data-architecture` is loaded conditionally rather than unconditionally. Per architecture §7.5 the current behavior at line 224 unconditionally lists `python-data-architecture` even for projects that are pure Python scripts with no data-access markers — a known detection inconsistency. Post-install hint at end of `init-project.sh` adds a one-liner pointing the PM chat at the new D1-D5 tables in PLATFORM-SKILLS.md so first-edit awareness lands at the right moment. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene mitigation: `ls -l scripts/init-project.sh` after editing to confirm `-rwxr-xr-x` exec bit unchanged.
Resolved:
```

### 3.12 BD-144 — add-capability.sh D5 rename + role:python-server intersection fix + v10→v11 migrator translation

```
**BD-144 — add-capability.sh D5 rename (role:apple-app → deployment:apple) + role:python-server intersection fix + v10→v11 migrator translation**
Type: TODO(version) — Batch 5 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 + §7.1 expanded scope)
Status: Open
Blockers: BD-142 (the reframe must establish D5 deployment surface and the new D2 ∩ D3 intersection model before add-capability.sh can be aligned)
Unblocks: clean `add-capability.sh` UX under the reframed dimension model; v10→v11 migrator translation stage so existing client `tracker.toml` / `add-capability` invocations keep working
File/Symbol: `scripts/add-capability.sh` — RENAME row `role:apple-app` → `deployment:apple` (D5 dimension assignment); NEW rows `deployment:linux-container` / `platform:android` / `platform:web-browser` / `platform:embedded-mcu` (forward-declared per `PLAN-SKILL-DIMENSIONS.md` §4.6 — SKILL.md files ship in Phase 3); FIX `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` (drops the obsolete `deployment-python`, per architecture §3.3 + §3.5 corrected intersection); `scripts/migrate-v10-to-v11.sh` NEW translation stage that maps any `role:apple-app` in client `tracker.toml` to `deployment:apple` per §7.1 expanded scope; golden-snapshot fixture for the migrator translation in `test-fixtures/v10-realistic-ot/`
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 and §7.1 expanded scope, add-capability.sh is realigned to the reframed dimensions: `role:apple-app` becomes `deployment:apple` (D5 — deployment surface, the missing dimension per architecture §3.5); new rows for `deployment:linux-container` (D5), `platform:android` / `platform:web-browser` / `platform:embedded-mcu` (D1 — runtime/OS substrate, per architecture §3.1) are added as forward-declared (the SKILL.md files ship in Phase 3 per `PLAN-SKILL-DIMENSIONS.md` §6; default to gating with directory-exists check + warning per §4.6 mitigation); `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` and DROPS the obsolete `deployment-python` (per architecture §3.3 + §3.5 corrected D2 ∩ D3 intersection — the old `deployment-python` was a misnamed catch-all). v10→v11 migrator translation stage maps any `role:apple-app` in a client's existing `tracker.toml` (or other capability config) to `deployment:apple` so existing client invocations keep working. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene: `ls -l scripts/add-capability.sh scripts/migrate-v10-to-v11.sh` after editing to confirm exec bit unchanged.
Resolved:
```

### 3.13 BD-143 — Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list

```
**BD-143 — Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list**
Type: TODO(version) — Batch 4 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 4)
Status: Open
Blockers: BD-142 (trinity prose points at PLATFORM-SKILLS.md as the authoritative reframe — the file must be reframed first)
Unblocks: BD-146 (Check 31 verifies agent files' "Skills to load" lists against the reframed per-agent assignment — those lists must be updated first), BD-148 (MIGRATION + MERGE-STRATEGY can reference the new Skill-loading section)
File/Symbol: `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` "Skill loading" section (trinity-replicated; reframe prose to 5-dimension D1-D5 + Tier 0 + intersection model; retire "Tier 1 / Tier 2" nomenclature); pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` parallel edits per Trinity rule; `audit-methodology/SKILL.md` rule 20 (cross-platform UI bullet seam extension per architecture §6.1, §6.3); `architecture-review/SKILL.md` skill-list update (4 trinity copies under `.claude/skills/` / `.codex/skills/` / `.gemini/skills/`; pack-repo template + project-template instances)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 4 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.1 + §6.3, the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) carry "Skill loading" prose that must be re-aligned to the reframed 5-dimension model; "Tier 1 / Tier 2" nomenclature is retired (per architecture §3.6-§3.9 the new model is Tier 0 base + D1-D5 dimensions + trigger-loaded). Trinity rule applies: project-template trinity AND pack-repo trinity get the parallel edit in the same set of changes (pack-repo CLAUDE.md / AGENTS.md / GEMINI.md). audit-methodology/SKILL.md rule 20 extended for the cross-platform UI bullet seam (per architecture §6.3 — the rule currently has Apple-specific UI accessibility hardcoded; extension lets the auditor consume PLATFORM-SKILLS.md to find applicable UI skills per architecture §7.7). architecture-review/SKILL.md skill list updated under all four trinity copies. Per `PLAN-SKILL-DIMENSIONS.md` §4.1 trinity-violation mitigation: verification step requires `diff` between every pair of trinity files in the section body and `diff` between every pair of architecture-review SKILL.md copies; Check 9 (init-project structure) and Check 18 (trinity H2 parity) enforce structurally.
Resolved:
```

### 3.14 BD-142 — PLATFORM-SKILLS.md — 5 dimensions + Tier 0 + intersection + trigger tables

```
**BD-142 — PLATFORM-SKILLS.md — 5 dimensions + Tier 0 + intersection + trigger tables**
Type: TODO(version) — Batch 3 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 3)
Status: Open
Blockers: BD-141 (PLATFORM-SKILLS.md text references `python_data_marker_detected()` for the python-data-architecture row; the helper must exist first)
Unblocks: BD-143 (trinity Skill-loading prose), BD-144 (add-capability.sh D5 rename), BD-145 (init-project.sh detection), BD-146 (validate-pack Check 31), BD-147 (migrator-skills.sh extraction), BD-148 (MIGRATION + MERGE-STRATEGY docs), BD-149 (naming-convention codification) — all downstream batches depend on the reframed PLATFORM-SKILLS.md
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` — major rewrite per architecture §3-§5: D1 (Runtime / OS substrate), D2 (Cross-platform languages), D3 (Component role / app-layer), D4 (Communication protocols), D5 (Deployment surface) tables; Tier 0 base-skills section (loaded for every project, every agent, per architecture §3.6); intersection-table sparse-cell layout (per architecture §3.7); trigger-loaded skills section (loaded by agent role, not project shape, per architecture §3.8); preserve project-owned `## Custom agents` and `## Custom skills` sections (lines 310-345) byte-identical per `PLAN-SKILL-DIMENSIONS.md` §4.4
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 3 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3-§5, PLATFORM-SKILLS.md is rewritten to the explicit five-dimension model + 3 orthogonal load mechanisms (Tier 0 base + dimension-implied + trigger-loaded). The reframe replaces the implicit four-dimension model documented today: D1 Runtime/OS substrate (apple-platform, linux, windows, web-browser, android, embedded-mcu); D2 Cross-platform languages (only swift / c / cpp / objc / python that have multi-platform applicability); D3 Component role / app-layer (cli, daemon, ui-app, library, service); D4 Communication protocols (grpc, rest, websocket); D5 Deployment surface NEW (apple-distribution, linux-container, native-binary, web-deploy). Tier 0 base skills load for every project, every agent (e.g., `audit-methodology`, `architecture-review`, `documentation`). Intersection table is sparse — most cells empty (per architecture §3.7). Trigger-loaded skills load by agent role (per architecture §3.8 — e.g., `repo-ops` triggers `git-operations`). Per `PLAN-SKILL-DIMENSIONS.md` §4.4, the project-owned `## Custom agents` and `## Custom skills` sections at lines 310-345 are NOT edited (BD-088 customization-preserve sidecar tests depend on the illustrative `x-deployer` / `x-brokerage-api` rows). No SKILL.md content changes in this batch — those are deferred to Phase 2A/2B/3.
Resolved:
```

### 3.15 BD-141 — Concrete python-data-architecture load predicate (lib/detect.sh marker function)

```
**BD-141 — Concrete python-data-architecture load predicate (lib/detect.sh marker function)**
Type: TODO(version) — Batch 2 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 2)
Status: Open
Blockers: BD-140 (BACKLOG entries must exist before downstream batches reference each other by BD number)
Unblocks: BD-142 (PLATFORM-SKILLS.md text references the helper for the python-data-architecture row), BD-145 (init-project.sh `pack_skill_coverage_for()` calls the helper)
File/Symbol: `scripts/lib/detect.sh` — NEW function `python_data_marker_detected()` around line 230 (after `detect_installed_capabilities`), sourceable by init-project.sh and add-capability.sh (~30-40 LoC); `scripts/init-project.sh` `pack_skill_coverage_for()` (line 219-228) — wires the helper for the python row (~5-line change); `scripts/add-capability.sh` A1 resolver — comment-references the helper as the canonical predicate when `language:python` is added without explicit `role:python-server` (~5-10 line change near line 110)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.5 and `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 2, the current `python-data-architecture` load predicate is fuzzy ("multi-file Python with data access, async I/O, or ML inference; otherwise omit" — PLATFORM-SKILLS.md line 54); init-project.sh `pack_skill_coverage_for python` row (line 224) unconditionally lists it; auditor-architecture (line 198) tries to thread the conditional through prose — detection inconsistency between init-project, add-capability, and PM chat is possible. BD-141 makes the predicate concrete: new function `python_data_marker_detected()` in `scripts/lib/detect.sh` returns yes if ANY of these markers are true: (a) `requirements.txt` or `pyproject.toml` lists any of `sqlalchemy`, `alembic`, `pydantic`, `aiohttp`, `httpx`, `psycopg`, `aiomysql`, `asyncpg`, `redis`, `pymongo`, `motor`, `boto3`, `aioboto3`, `grpc-tools`, `protobuf`, `pyarrow`, `pandas`, `numpy`, `scikit-learn`, `torch`, `tensorflow`; (b) ≥5 `.py` files outside `tests/`. Implementation uses `grep -lE` and `find ... -not -path '*/tests/*' | wc -l`. init-project.sh `pack_skill_coverage_for()` calls the helper for the python row; add-capability.sh A1 resolver comment-references the helper as the canonical predicate. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene: `ls -l scripts/lib/detect.sh scripts/init-project.sh scripts/add-capability.sh` after editing to confirm exec bit unchanged (lib/detect.sh is sourced, not exec).
Resolved:
```

### 3.16 BD-140 — Skill-dimensions reframe — BACKLOG entries (umbrella)

```
**BD-140 — Skill-dimensions reframe — BACKLOG entries (umbrella)**
Type: TODO(version) — surfaced 2026-05-11 during pack-planner Phase 1 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 1; spawns BD-141..BD-150 sequenced batches plus BD-151..BD-155 v12-deferred entries)
Status: Open
Blockers: none
Unblocks: BD-141..BD-150 (the 10 sequenced execution batches of the skill-dimensions reframe); BD-151..BD-155 (the 5 v12-deferred entries created inline by this batch)
File/Symbol: `BACKLOG.md` (this file — the only file edited in BD-140's batch); references `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` as the authoritative plan + architecture for the reframe
Description: Umbrella BD for the skill-dimensions reframe v11.0 work. Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §0 batch summary and §2 per-batch detail, BD-140 is the BACKLOG-ops batch that lands the 16 new BD entries (BD-140..BD-155) all in one commit and unblocks downstream sequenced execution. The reframe replaces the implicit four-dimension PLATFORM-SKILLS.md model with an explicit five-dimension model (D1 Runtime/OS substrate, D2 Cross-platform languages, D3 Component role / app-layer, D4 Communication protocols, D5 Deployment surface NEW) plus 3 orthogonal load mechanisms (Tier 0 base, dimension-implied, trigger-loaded), plus `scripts/lib/migrator-skills.sh` extraction (BD-147), naming-convention codification (BD-149), and supporting trinity / validator / migrator / docs work. BD-141..BD-150 sequence the v11.0 execution per the critical-path diagram in `PLAN-SKILL-DIMENSIONS.md` §1 (BD-140 → BD-141 → BD-142 → BD-143 → BD-146 → BD-150 critical path). BD-151..BD-155 are v12-deferred items recorded inline per architecture §7.1 (observability skill), §7.2 (accessibility skill), §7.3 (concurrency-architecture skill), §7.9 (skill-versioning frontmatter), §7.10 (naming-convention enforcement migration). After BD-150 ships, Pack Chat spawns a fresh `pack-architect` session for Phase 2A per `PLAN-SKILL-DIMENSIONS.md` §6 (per-skill rule designs for `web-architecture`, `android-architecture`, `embedded-mcu-architecture`).
Resolved:
```

---

## 4. Verification

### 4.1 validate-pack.py

```
$ python3 scripts/validate-pack.py 2>&1 | tail -5
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', backend='github', mode='flat-file')

── Check 30: Recommendation-state JSON schema (BD-079) ──
  OK: .pack-tracker/recommendation-state.json absent — lazy-create is by design, nothing to validate

============================================================
PASSED — all checks clean
```

All 30 checks PASS. No regressions; no new failures.

### 4.2 BD-entry-presence grep

```
$ grep -nE "^\*\*BD-(14[0-9]|15[0-5])" BACKLOG.md
1339:**BD-155 — Naming-convention enforcement migration (deferred to v12)**
1350:**BD-154 — Skill-versioning frontmatter convention (deferred to v12)**
1361:**BD-153 — Tier 0 concurrency-architecture skill (deferred to v12)**
1372:**BD-152 — Tier 0 accessibility skill (deferred to v12)**
1383:**BD-151 — Tier 0 observability skill (deferred to v12)**
1394:**BD-150 — CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh**
1405:**BD-149 — PLATFORM-SKILLS.md "Extending this file" naming convention codification (no skill renames)**
1416:**BD-148 — MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md skill-model-changes documentation**
1427:**BD-147 — Extract S5b BD-035 rename helper into scripts/lib/migrator-skills.sh + Check 26 extension + BD-119 docs update**
1438:**BD-146 — validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension**
1449:**BD-145 — init-project.sh — D1/D5 detection hint + python-data marker integration**
1460:**BD-144 — add-capability.sh D5 rename (role:apple-app → deployment:apple) + role:python-server intersection fix + v10→v11 migrator translation**
1471:**BD-143 — Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list**
1482:**BD-142 — PLATFORM-SKILLS.md — 5 dimensions + Tier 0 + intersection + trigger tables**
1493:**BD-141 — Concrete python-data-architecture load predicate (lib/detect.sh marker function)**
1504:**BD-140 — Skill-dimensions reframe — BACKLOG entries (umbrella)**
```

Exactly 16 lines returned, matching the 16-BD spec.

### 4.3 Status-Open / Status-Deferred deltas

| Field | Pre-batch | Post-batch | Delta | Expected |
|---|---|---|---|---|
| `Status: Open` | 27 | 38 | **+11** | +11 (BD-140..BD-150) |
| `Status: Deferred` | 5 | 10 | **+5** | +5 (BD-151..BD-155) |
| Total new entries | — | — | **+16** | +16 |

All deltas match.

### 4.4 TD-TBD sentinel check (Check 3)

```
$ grep -nE "TD-TBD" BACKLOG.md
2394:  entries contain TD-TBD sentinels; README.md version table is consistent with
2399:  SKILL.md frontmatter validation, TOML parsing, TD-TBD sentinel check,
```

The two matches are pre-existing (inside BD-029's Description text). No `TD-TBD` sentinels introduced by this batch.

### 4.5 BD-number / blocker / status spot-checks against spec

| Spec entry | BD # | Title (matches spec) | Status | Blockers (matches spec) |
|---|---|---|---|---|
| 1 | BD-140 | "Skill-dimensions reframe — BACKLOG entries (umbrella)" | Open | none |
| 2 | BD-141 | "Concrete python-data-architecture load predicate (lib/detect.sh marker function)" | Open | BD-140 |
| 3 | BD-142 | "PLATFORM-SKILLS.md — 5 dimensions + Tier 0 + intersection + trigger tables" | Open | BD-141 |
| 4 | BD-143 | "Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list" | Open | BD-142 |
| 5 | BD-144 | "add-capability.sh D5 rename (role:apple-app → deployment:apple) + role:python-server intersection fix + v10→v11 migrator translation" | Open | BD-142 |
| 6 | BD-145 | "init-project.sh — D1/D5 detection hint + python-data marker integration" | Open | BD-141, BD-142 |
| 7 | BD-146 | "validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension" | Open | BD-142, BD-143 |
| 8 | BD-147 | "Extract S5b BD-035 rename helper into scripts/lib/migrator-skills.sh + Check 26 extension + BD-119 docs update" | Open | BD-142 |
| 9 | BD-148 | "MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md skill-model-changes documentation" | Open | BD-142, BD-143 |
| 10 | BD-149 | "PLATFORM-SKILLS.md — 'Extending this file' naming convention codification (no skill renames)" | Open | BD-142 |
| 11 | BD-150 | "CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh" | Open | BD-146, BD-148 |
| 12 | BD-151 | "Tier 0 observability skill (deferred to v12)" | Deferred | v12 |
| 13 | BD-152 | "Tier 0 accessibility skill (deferred to v12)" | Deferred | v12 |
| 14 | BD-153 | "Tier 0 concurrency-architecture skill (deferred to v12)" | Deferred | v12 |
| 15 | BD-154 | "Skill-versioning frontmatter convention (deferred to v12)" | Deferred | v12 |
| 16 | BD-155 | "Naming-convention enforcement migration (deferred to v12)" | Deferred | v12 |

All 16 entries match the spec on BD #, title, blockers, and (with the format-conformance Status decision documented in §2.2) status.

---

## 5. POQ (Plan Open Questions)

**No new POQs introduced.** The four format-conformance decisions in §2.2 (omit `Created:` field; use `Type: TODO(version)` not `TODO(v11.0)` / `TODO(v12)`; use `Status: Deferred` for v12-deferred entries; use `Resolved: n/a` for deferred entries) are not POQs — they are the prompt's explicit "MATCH BACKLOG.md" rule applied to a recognized format conflict.

The insertion-location decision (prepend to top of recent-block in descending order) is not a POQ either — it follows the unambiguous BD-123..BD-139 precedent in the file.

No ambiguity blocked any entry from being authored.

---

## 6. Files touched

```
$ git diff --stat
 BACKLOG.md | 176 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 176 insertions(+)
```

| Path | Change type | Lines added | Lines removed |
|---|---|---|---|
| `BACKLOG.md` | modified | 176 | 0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-140.md` | new | (this report) | — |

No other file modified. No file deleted. No file renamed.

---

## 7. Definition-of-Done checklist

| # | Spec requirement | Status |
|---|---|---|
| 1 | Read BACKLOG.md in full before appending | **PASS** (read in chunks; format observed and documented in §2.1) |
| 2 | Confirm highest existing BD = BD-139 | **PASS** (confirmed via `grep` in §1) |
| 3 | Identify existing entry format and document in report §2 | **PASS** (§2.1 + §2.2 + §2.3) |
| 4 | Insert 16 new BD entries (BD-140..BD-155) at appropriate location | **PASS** (16 entries appended above BD-139, in descending order matching prepend-newest convention) |
| 5 | Use `Status: Open` for v11.0 BDs (BD-140..BD-150) | **PASS** (11 entries, all Status: Open) |
| 6 | Use `Type: TODO(version)` matching BACKLOG convention (spec said TODO(v11.0); BACKLOG uniformly uses TODO(version)) | **PASS** (format-conformance decision per §2.2) |
| 7 | Use `Status: Deferred` for v12 BDs (BD-151..BD-155) (spec said Open; BACKLOG convention for deferred is Status: Deferred) | **PASS** (5 entries, all Status: Deferred; format-conformance per §2.2) |
| 8 | All entries cite ARCHITECTURE-SKILL-DIMENSIONS.md / PLAN-SKILL-DIMENSIONS.md sections per spec | **PASS** (each entry's Description quotes the relevant §) |
| 9 | All entries have File/Symbol pointers | **PASS** |
| 10 | All entries have Blockers per spec critical-path diagram | **PASS** (verified in §4.5 spot-check table) |
| 11 | Match existing format exactly (heading level, field names, blank lines) | **PASS** (matches BD-139 / BD-138 / BD-127 template — `**BD-NNN — Title**` H-line, fields in order Type/Status/Blockers/Unblocks/File/Symbol/Description/Resolved, blank line + `---` + blank line separator) |
| 12 | `python3 scripts/validate-pack.py` PASS all 30 checks | **PASS** (§4.1) |
| 13 | `grep -nE "^\\*\\*BD-(14[0-9]\|15[0-5])" BACKLOG.md` returns exactly 16 lines | **PASS** (§4.2) |
| 14 | `grep -c "Status: Open" BACKLOG.md` increased by exactly 16 vs pre-batch (spec assumption) — adjusted for §2.2 format-conformance: Open delta +11, Deferred delta +5, total +16 | **PASS** (§4.3 — total new entries = 16; Open +11 + Deferred +5 = 16) |
| 15 | No TD-TBD sentinels introduced | **PASS** (§4.4) |
| 16 | Single file (BACKLOG.md) modified — no other pack source file edited | **PASS** (§6) |
| 17 | No state-changing git verbs run by coder | **PASS** (only `git rev-parse HEAD`, `git status`, `git diff --stat` invoked — all read-only) |
| 18 | Do not edit plan / architecture docs | **PASS** (those files read-only; §6 confirms only BACKLOG.md modified) |
| 19 | Implementation report at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-140.md` | **PASS** (this file) |
| 20 | Report chunked if > 300 lines | **PASS** (initial Write + Edit-append; this file is well under 300 LoC per chunk) |

---

## 8. Final summary

- **16 new BD entries added to BACKLOG.md** (BD-140..BD-155), in descending order at the top of the recent-block per established convention.
- **`python3 scripts/validate-pack.py` PASS** (all 30 checks clean).
- **Status delta confirmed:** `Status: Open` 27 → 38 (+11 for BD-140..BD-150); `Status: Deferred` 5 → 10 (+5 for BD-151..BD-155); total +16.
- **No commits, no pushes, no state-changing git verbs.** Pack Chat reviews this report and commits.
- **No spec deviations.** Format-conformance decisions (§2.2) are explicitly authorized by the prompt's "MATCH BACKLOG.md, not the spec" rule.
- **No POQs introduced.**
- **Files changed:** `BACKLOG.md` (modified, +176 LoC) and `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-140.md` (new, this report).

Final HEAD SHA on coder's worktree (read-only): `76ffd756245e330977fa78f5c243c18c56205be1` (unchanged — coder did not commit; working-tree edits are pending Pack Chat review).
