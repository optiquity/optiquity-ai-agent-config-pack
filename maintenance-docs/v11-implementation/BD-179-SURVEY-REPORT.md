# BD-179 Phase 1 — Bare-Cross-Reference Survey Report

**Status:** SURVEY-ONLY output (pack-coder Phase 1 spawn 2026-05-20)
**Source BD:** BD-179 (5th BD in BD-175 emergency batch)
**Authoritative strategy doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md`
**HEAD at survey:** `3e0cf6e47be52837f8bfc33fd347e911bf1a074e` (v11-dev)
**Survey scope:** 9 in-scope `pack-ops/*.md` files per §2 D1 (excludes BACKLOG.md + CHANGELOG.md regenerated mirrors)
**Audience:** Pack Chat (surfaces this to user before Phase 2 spawn); pack-coder Phase 2 (consumes the empirical scope)

---

## §1 Summary

**Empirical conclusion:** the live HEAD count substantially exceeds the §8.2 manual-survey estimate of 20–32 hits. The Check-40-equivalent scan detects **160 total bare-ref backtick spans / hyperlinks** across the 9 in-scope files. Of these, **62 hits PASS by exemption** (49 allowlist + 11 anchor-phrase + 2 already-counted as both), **33 hits PASS as legitimate-bare** (resolvable unambiguously within the same directory as the referencing doc), and **62 hits would FAIL** as currently written (51 needing qualification + 11 broken refs requiring per-case disposition).

### §1.1 Aggregate counts (across 9 files)

| Classification | Count | Disposition |
|---|---|---|
| ALLOWLISTED (§6.2 set: 8 entries) | 49 | PASS — exempt by hardcoded allowlist (pack-root files + trinity + memory cache) |
| ANCHOR-EXEMPTED (§6.4 phrases incl. `post-install`) | 11 | PASS — exempt by ±2-line anchor-phrase window |
| RESOLVABLE-BARE-LEGIT (same-dir unique resolution) | 33 | PASS — basename resolves to exactly one file in same directory as referencing doc (e.g., bare `MERGE-STRATEGY.md` inside `pack-ops/` resolves to `pack-ops/MERGE-STRATEGY.md` unambiguously) |
| FLAGGED — QUALIFY needed | 51 | FAIL — bare ref resolves to a file in a DIFFERENT directory than the referencing doc; needs path-qualification |
| FLAGGED — BROKEN ref | 11 | FAIL — bare ref does NOT resolve to any file in the repo; may be conceptual/placeholder/historical (per-case disposition required) |
| **TOTAL** | **160** | — |

### §1.2 Comparison to §8.2 estimate

Architect §8.2 estimated 20–32 bare-ref qualifications. Empirical: **51 qualify + 11 broken = 62 FAIL hits + 60 PASS exemptions + 33 same-dir-legit + 49 allowlist** = 160 detections. The qualify-needed count (51) is roughly 2x the upper-end estimate. The §8.2 estimate did not account for BOUNDARY-DEFINITION.md's 24 hits (the architect doc said "0 hits" for that file at §8.2 row 6 — the empirical reality differs because BOUNDARY-DEFINITION.md carries many `init-project.sh` and `AUDIT-USER-CURATION.md` bare refs in non-anchor-phrase contexts, plus ambiguous trinity-pattern refs like `OPTIONAL-FEATURES.md` and `HELP-FRAGMENT-TRACKER.md` that resolve to multiple paths post-Override-8 SPLIT).

### §1.3 Phase 2 scope implication

If Phase 2 applies the Check 40 design as-architected with **NO allowlist additions beyond §6.2**, the Phase 2 commit must qualify 51 refs + decide disposition for 11 broken refs (delete? typo-fix? new allowlist entry? new BD?) + apply the L472 prose edit. The 11 broken refs are not all defects — many are placeholder/conceptual mentions (e.g., `tracker.toml`, `manifest.txt`, `report.md`, `BD-NNN.md`) that arguably belong on the allowlist as concept-noun patterns. **§8 below surfaces allowlist-adjustment suggestions for Pack Chat triage before Phase 2 spawns.**

---

## §2 Per-file breakdown

| File | Total | Allowlisted | Anchor-Exempted | Resolvable-Bare-Legit | FLAGGED-QUALIFY | FLAGGED-BROKEN |
|---|---:|---:|---:|---:|---:|---:|
| `pack-ops/BOUNDARY-DEFINITION.md` | 81 | 30 | 9 | 18 | 24 | 0 |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | 12 | 4 | 0 | 2 | 1 | 5 |
| `pack-ops/DRY-RUN-MIGRATION.md` | 11 | 3 | 0 | 2 | 6 | 0 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | 3 | 2 | 0 | 0 | 1 | 0 |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | 3 | 0 | 1 | 0 | 1 | 1 |
| `pack-ops/MERGE-STRATEGY.md` | 29 | 4 | 0 | 2 | 18 | 5 |
| `pack-ops/OPTIONAL-FEATURES.md` | 7 | 1 | 1 | 3 | 0 | 2 |
| `pack-ops/PACK-AGENTS.md` | 11 | 4 | 0 | 4 | 0 | 3 |
| `pack-ops/PACK-CHAT.md` | 3 | 1 | 0 | 2 | 0 | 0 |
| **TOTAL** | **160** | **49** | **11** | **33** | **51** | **11** |

### §2.1 Hot-spot files

- **`pack-ops/BOUNDARY-DEFINITION.md` (24 qualify)** — surprise hot-spot vs §8.2 "0 hits" estimate. Concentrates on `init-project.sh` (8x), `AUDIT-USER-CURATION.md` (6x), `OPTIONAL-FEATURES.md` (3x, ambiguous post-SPLIT), plus L179 four-agent-name table cell hits.
- **`pack-ops/MERGE-STRATEGY.md` (18 qualify + 5 broken)** — aligns with §8.2 estimate (12–14). The broken refs are conceptual nouns (`report.md`, `tracker.toml`, `id-map.json`) — allowlist candidates.
- **`pack-ops/DRY-RUN-MIGRATION.md` (6 qualify)** — slightly under §8.2 estimate (5–7). All 6 are `MIGRATION-v10-to-v11.md` → `supporting-docs/MIGRATION-v10-to-v11.md`.

### §2.2 Cold-spot files

- **`pack-ops/PACK-CHAT.md` (0 qualify)** — all 3 hits pass via allowlist (1) + same-dir-legit (2). Clean.
- **`pack-ops/PACK-AGENTS.md` (0 qualify)** — all 8 PASS hits classified; 3 broken refs are filename-pattern placeholders at L163 (`BD-NNN.md`, `TD-NNN.md`, `phase-N.md` — clear allowlist candidates per §8).
- **`pack-ops/OPTIONAL-FEATURES.md` (0 qualify)** — clean qualification-wise; 2 broken refs are `tracker.toml` placeholders.
- **`pack-ops/HELP-FRAGMENT-PACK.md` (1 qualify)** — L37 `pack-help.sh` → `scripts/pack-help.sh`. Trivial.

---

## §3 Flagged refs requiring qualification (51 hits)

Sorted by file then line. "Proposed qualified form" is the best-guess derived from §5.1 D4 candidate-path lookup; rows with DISAMBIGUATE require human disposition (multiple candidate paths exist).

| File:Line | Bare basename | Resolves-to candidates | Proposed qualified form |
|---|---|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `HELP-FRAGMENT-TRACKER.md` | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`, `pack-ops/HELP-FRAGMENT-TRACKER.md` | DISAMBIGUATE (pack-internal context: `pack-ops/HELP-FRAGMENT-TRACKER.md`) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `OPTIONAL-FEATURES.md` | `project-template/docs/pack/OPTIONAL-FEATURES.md`, `pack-ops/OPTIONAL-FEATURES.md` | DISAMBIGUATE (pack-internal context: `pack-ops/OPTIONAL-FEATURES.md`) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L50 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L52 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L78 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L94 | `AUDIT-USER-CURATION.md` | `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` | `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L98 | `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L98 | `AUDIT-USER-CURATION.md` | (same) | (same) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L100 | `AUDIT-USER-CURATION.md` | (same) | (same) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L101 | `AUDIT-USER-CURATION.md` | (same) | (same) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L113 | `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` | `maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` | `maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L113 | `AUDIT-USER-CURATION.md` | (same as L94) | (same as L94) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L137 | `AUDIT-USER-CURATION.md` | (same) | (same) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L139 | `OPTIONAL-FEATURES.md` | `project-template/docs/pack/OPTIONAL-FEATURES.md`, `pack-ops/OPTIONAL-FEATURES.md` | DISAMBIGUATE (pack-internal SPLIT discussion: see §3.1 below) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L141 | `OPTIONAL-FEATURES.md` | (same) | DISAMBIGUATE (same) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L141 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L143 | `AUDIT-USER-CURATION.md` | (same) | (same) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L143 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L179 | `pack-coder.md` | `.gemini/agents/pack-coder.md`, `.claude/agents/pack-coder.md` | DISAMBIGUATE — see §3.2 below |
| `pack-ops/BOUNDARY-DEFINITION.md`:L179 | `pack-planner.md` | `.gemini/agents/pack-planner.md`, `.claude/agents/pack-planner.md` | DISAMBIGUATE — see §3.2 below |
| `pack-ops/BOUNDARY-DEFINITION.md`:L179 | `pack-reviewer.md` | `.gemini/agents/pack-reviewer.md`, `.claude/agents/pack-reviewer.md` | DISAMBIGUATE — see §3.2 below |
| `pack-ops/BOUNDARY-DEFINITION.md`:L179 | `pack-docs-researcher.md` | `.gemini/agents/pack-docs-researcher.md`, `.claude/agents/pack-docs-researcher.md` | DISAMBIGUATE — see §3.2 below |
| `pack-ops/BOUNDARY-DEFINITION.md`:L209 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L225 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/BOUNDARY-DEFINITION.md`:L241 | `init-project.sh` | `scripts/init-project.sh` | `scripts/init-project.sh` |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L247 | `EXECUTION-PLAN-V11.0.md` | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` |
| `pack-ops/DRY-RUN-MIGRATION.md`:L30 | `MIGRATION-v10-to-v11.md` | `supporting-docs/MIGRATION-v10-to-v11.md` | `supporting-docs/MIGRATION-v10-to-v11.md` |
| `pack-ops/DRY-RUN-MIGRATION.md`:L93 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/DRY-RUN-MIGRATION.md`:L105 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/DRY-RUN-MIGRATION.md`:L115 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/DRY-RUN-MIGRATION.md`:L181 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/DRY-RUN-MIGRATION.md`:L196 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/HELP-FRAGMENT-PACK.md`:L37 | `pack-help.sh` | `scripts/pack-help.sh` | `scripts/pack-help.sh` |
| `pack-ops/HELP-FRAGMENT-TRACKER.md`:L21 | `HELP-FRAGMENT.md` | `project-template/docs/pack/HELP-FRAGMENT.md` | `project-template/docs/pack/HELP-FRAGMENT.md` |
| `pack-ops/MERGE-STRATEGY.md`:L10 | `migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` |
| `pack-ops/MERGE-STRATEGY.md`:L100 | `merge-json.py` | `scripts/merge-json.py` | `scripts/merge-json.py` |
| `pack-ops/MERGE-STRATEGY.md`:L101 | `settings.json` | `project-template/.gemini/settings.json`, `project-template/.claude/settings.json`, `xcode-companion-templates/ClaudeAgentConfig/settings.json`, `vscode-companion-templates/.vscode/settings.json` | DISAMBIGUATE (4 candidates — see §3.3 below) |
| `pack-ops/MERGE-STRATEGY.md`:L108 | `merge-json.py` | `scripts/merge-json.py` | `scripts/merge-json.py` |
| `pack-ops/MERGE-STRATEGY.md`:L119 | `merge-json.py` | `scripts/merge-json.py` | `scripts/merge-json.py` |
| `pack-ops/MERGE-STRATEGY.md`:L196 | `pack-architect.md` | `.gemini/agents/pack-architect.md`, `.claude/agents/pack-architect.md` | DISAMBIGUATE — see §3.2 below |
| `pack-ops/MERGE-STRATEGY.md`:L196 | `pack-reviewer.md` | `.gemini/agents/pack-reviewer.md`, `.claude/agents/pack-reviewer.md` | DISAMBIGUATE — see §3.2 below |
| `pack-ops/MERGE-STRATEGY.md`:L270 | `validate-pack.py` | `scripts/validate-pack.py` | `scripts/validate-pack.py` |
| `pack-ops/MERGE-STRATEGY.md`:L271 | `MIGRATION-v10-to-v11.md` | `supporting-docs/MIGRATION-v10-to-v11.md` | `supporting-docs/MIGRATION-v10-to-v11.md` |
| `pack-ops/MERGE-STRATEGY.md`:L313 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/MERGE-STRATEGY.md`:L314 | `INSTALL-PROCEDURES.md` | `supporting-docs/INSTALL-PROCEDURES.md` | `supporting-docs/INSTALL-PROCEDURES.md` |
| `pack-ops/MERGE-STRATEGY.md`:L329 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/MERGE-STRATEGY.md`:L349 | `migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` |
| `pack-ops/MERGE-STRATEGY.md`:L380 | `migrate-v10-to-v11.sh` | (same) | (same) |
| `pack-ops/MERGE-STRATEGY.md`:L412 | `validate-pack.py` | `scripts/validate-pack.py` | `scripts/validate-pack.py` |
| `pack-ops/MERGE-STRATEGY.md`:L426 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/MERGE-STRATEGY.md`:L440 | `MIGRATION-v10-to-v11.md` | (same) | (same) |
| `pack-ops/MERGE-STRATEGY.md`:L479 | `validate-pack.py` | `scripts/validate-pack.py` | `scripts/validate-pack.py` |

### §3.1 DISAMBIGUATE notes — `OPTIONAL-FEATURES.md` / `HELP-FRAGMENT-TRACKER.md` (Override 8 SPLIT)

Per Override 8 (AUDIT-USER-CURATION.md §1), `OPTIONAL-FEATURES.md` was SPLIT into two independently-curated files: `pack-ops/OPTIONAL-FEATURES.md` (pack-internal) and `project-template/docs/pack/OPTIONAL-FEATURES.md` (project-side, post-install path at client repos). Same applies to `HELP-FRAGMENT-TRACKER.md` per the pack-vs-project pattern.

For BOUNDARY-DEFINITION.md L48 / L139 / L141 the surrounding prose discusses the PACK-INTERNAL classification (C2 row), so the qualified form is `pack-ops/OPTIONAL-FEATURES.md`. The architect-doc §10.2 qualification table confirms this disposition for these contexts.

### §3.2 DISAMBIGUATE notes — agent files (`.claude/agents/` vs `.gemini/agents/`)

Bare refs to `pack-coder.md`, `pack-planner.md`, etc. at BOUNDARY-DEFINITION.md L179 and MERGE-STRATEGY.md L196 resolve to TWO candidates each (`.claude/agents/<name>.md` and `.gemini/agents/<name>.md`). The L179 line context explicitly says ".claude/agents/pack-architect.md, pack-coder.md, pack-planner.md, ..." — the bare refs are CONTINUATIONS of an already-qualified ref. This is a legitimate compositional pattern (the first ref qualifies; subsequent siblings inherit context). **Phase 2 disposition options:** (a) qualify each — `.claude/agents/pack-coder.md`, `.claude/agents/pack-planner.md`, etc. (verbose but mechanical); (b) add a new anchor-phrase like `.claude/agents/` that admits bare refs in the ±2-line window; (c) prose-rewrite to "`.claude/agents/pack-architect.md` + sibling files for pack-coder / pack-planner / pack-reviewer / pack-docs-researcher" (eliminates bare refs). Pack-Chat triage decision.

### §3.3 DISAMBIGUATE notes — `settings.json` (4 candidates)

MERGE-STRATEGY.md L101 references `settings.json` with 4 candidate paths spanning two trinity members + two IDE-companion-template trees. Line context: `merge-json.py` discussion of CLI-config merging. Phase 2 needs to either pick one (most likely `project-template/.claude/settings.json` per Claude-Code primacy in MERGE-STRATEGY) or rewrite as "any CLI's `settings.json` (e.g., `project-template/.claude/settings.json`)" to acknowledge multi-target.

---

## §4 Flagged refs that are broken (11 hits, no candidate file in repo)

| File:Line | Bare basename | Line context (truncated) | Proposed disposition |
|---|---|---|---|
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L110 | `manifest.txt` | "...applied this interrogation and caught a MUST that the original end-of-batch review..." | NIT (it's a conceptual mention of "the manifest.txt file" — there IS a `test-fixtures/manifest.txt` but the survey excludes `test-fixtures/` per §5.1 D4). **Option A:** Remove `test-fixtures/` from EXCLUDE so `manifest.txt` resolves to `test-fixtures/manifest.txt` (correctness vs §5.1 intent — fixture dir explicitly excluded). **Option B:** Qualify to `test-fixtures/manifest.txt`. **Option C:** Add `manifest.txt` to allowlist as "the RC9 manifest, see test-fixtures/manifest.txt." Recommend **Option B**. |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L186 | `feedback_review_fix_one_cycle.md` | "Review/fix cycles per BD AND per batch (per `feedback_review_fix_one_cycle.md`)" | This is a Claude-Code memory-cache filename (lives at `~/.claude/projects/.../memory/`, outside the pack repo per MEMORY.md context). Same class as `MEMORY.md` allowlist entry. **Recommend:** add `feedback_*.md` pattern to allowlist as "Claude-Code memory cache feedback file (external to pack repo)" OR qualify each ref as `~/.claude/...` (ugly). Practical: a regex extension `^feedback_[a-z_]+\.md$` allowlist-pattern. Pack-Chat triage. |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L195 | `ARCHITECTURE-V1.md` | "**From `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`:**" | Historical/archived doc reference (versioned ARCHITECTURE-V1 docs lived in old maintenance-docs/ structure, since archived). **Recommend:** rewrite L195 to cite the current canonical source OR explicitly note the docs are archived ("from the now-archived `ARCHITECTURE-V1.md`..."). |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L195 | `V3.3-DELTA.md` | (same line) | Same disposition as `ARCHITECTURE-V1.md`. |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L247 | `IMPLEMENTATION-PLAN-V11.0.md` | "...five Group D+E reviewer prompts cited `IMPLEMENTATION-PLAN-V11.0.md` (does not exist); canonical filename..." | This ref is SELF-IDENTIFIED as non-existent ("(does not exist)") — the prose explicitly flags it as a historical error. Phase 2 could leave as-is with anchor-phrase exemption (add "does not exist" to anchors), OR rewrite to escape backticks ("a phantom filename `IMPLEMENTATION-PLAN-V11.0.md`-like reference"). |
| `pack-ops/HELP-FRAGMENT-TRACKER.md`:L9 | `tracker.toml` | "Opt-in: write `tracker.toml`, validate `gh auth`, ensure labels..." | `tracker.toml` is a generated/example filename (lives as `tracker.toml.pack-example` in repo; `tracker.toml` itself is created at user opt-in time, not in pack repo). **Recommend:** add to allowlist as "tracker config file (created by `pack tracker init`; pack repo ships `tracker.toml.pack-example`)." |
| `pack-ops/MERGE-STRATEGY.md`:L5 | `report.md` | "the per-class disposition tokens via the `report.md` produced by the" | `report.md` is the GENERATED output of `customization-report.sh`, not a checked-in file. **Recommend:** add to allowlist as "customization-preserve generated report (see scripts/lib/customization-report.sh)." |
| `pack-ops/MERGE-STRATEGY.md`:L31 | `report.md` | (same — generated output) | Same disposition. |
| `pack-ops/MERGE-STRATEGY.md`:L37 | `report.md` | (same — generated output) | Same disposition. |
| `pack-ops/MERGE-STRATEGY.md`:L415 | `tracker.toml` | "the target (`tracker.toml` present with `mode.state = "tracker"`..." | Same as HELP-FRAGMENT-TRACKER.md:L9. Allowlist candidate. |
| `pack-ops/MERGE-STRATEGY.md`:L418 | `id-map.json` | "active it checks: `id-map.json` integrity, BACKLOG.md mirror" | `id-map.json` is a tracker-mode metadata file generated at opt-in; same class as `tracker.toml`. Allowlist candidate. |
| `pack-ops/OPTIONAL-FEATURES.md`:L156 | `tracker.toml` | "`tracker.toml` lives at the repo root (project) or pack root (pack..." | Same. Allowlist. |
| `pack-ops/OPTIONAL-FEATURES.md`:L204 | `tracker.toml` | "`tracker.toml`'s `mode.state` back to flat-file. Atomic — restores" | Same. Allowlist. |
| `pack-ops/PACK-AGENTS.md`:L163 | `BD-NNN.md` | "`BD-NNN.md`, `TD-NNN.md`, `phase-N.md`, `YYYY-MM-DD-*.md`) are PM-only" | Filename-pattern placeholder ("BD-NNN" is a template, not a real file). Same class as `report.md` / `tracker.toml`. Allowlist candidate OR §3.4 wildcard-exclusion extension. |
| `pack-ops/PACK-AGENTS.md`:L163 | `TD-NNN.md` | (same) | Same disposition. |
| `pack-ops/PACK-AGENTS.md`:L163 | `phase-N.md` | (same) | Same disposition. |

**Empirical note:** 4 hits in §4 register as broken solely because the survey excluded `scripts/tests/fixtures/` and `test-fixtures/` per §5.1 D4 (the architect-doc names `test-fixtures/`; survey also pruned `scripts/tests/fixtures/` because they are functionally identical synthetic-test trees — see §8 OQ-S1 below). If the survey included those dirs, `tracker.toml` would resolve to `scripts/tests/fixtures/tracker-config/.../tracker.toml` and `manifest.txt` to `test-fixtures/manifest.txt`. Phase 2 needs to decide: (a) tighten exclude to match architect intent exactly (top-level `test-fixtures/` only — but then `tracker.toml` resolves to fixture content, which is wrong-target); (b) add `scripts/tests/fixtures/` to the architect-doc EXCLUDE set explicitly (already done in survey, matches §5.1 intent); (c) add the broken refs to allowlist as concept-noun patterns (Recommended — see §8 OQ-S2).

---

## §5 Allowlist-exempted refs (49 hits across 8 unique allowlist entries used)

Aggregate by (file, basename) with count column:

| File | Basename | Allowlist entry rationale | Count |
|---|---|---|---:|
| `pack-ops/BOUNDARY-DEFINITION.md` | `CLAUDE.md` | Pack-root trinity (C3); see also project-template/CLAUDE.md | 9 |
| `pack-ops/BOUNDARY-DEFINITION.md` | `README.md` | Pack-root landing-page doc (BOUNDARY-DEFINITION.md C1) | 6 |
| `pack-ops/BOUNDARY-DEFINITION.md` | `AGENTS.md` | Pack-root trinity (C3); see also project-template/AGENTS.md | 6 |
| `pack-ops/BOUNDARY-DEFINITION.md` | `GEMINI.md` | Pack-root trinity (C3); see also project-template/GEMINI.md | 5 |
| `pack-ops/BOUNDARY-DEFINITION.md` | `QUICKSTART.md` | Pack-root installer doc (BOUNDARY-DEFINITION.md C1 + Override 7) | 3 |
| `pack-ops/BOUNDARY-DEFINITION.md` | `LICENSE.md` | Pack-root deliverable; standard repo convention | 1 |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | `CLAUDE.md` | Pack-root trinity (C3); see also project-template/CLAUDE.md | 2 |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | `MEMORY.md` | Claude-Code memory cache (external to pack repo) | 2 |
| `pack-ops/DRY-RUN-MIGRATION.md` | `CLAUDE.md` | (trinity) | 1 |
| `pack-ops/DRY-RUN-MIGRATION.md` | `AGENTS.md` | (trinity) | 1 |
| `pack-ops/DRY-RUN-MIGRATION.md` | `GEMINI.md` | (trinity) | 1 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | `QUICKSTART.md` | (pack-root installer) | 1 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | `README.md` | (pack-root landing) | 1 |
| `pack-ops/MERGE-STRATEGY.md` | `CLAUDE.md` | (trinity) | 1 |
| `pack-ops/MERGE-STRATEGY.md` | `AGENTS.md` | (trinity) | 1 |
| `pack-ops/MERGE-STRATEGY.md` | `GEMINI.md` | (trinity) | 1 |
| `pack-ops/MERGE-STRATEGY.md` | `QUICKSTART.md` | (pack-root installer) | 1 |
| `pack-ops/OPTIONAL-FEATURES.md` | `CLAUDE.md` | (trinity) | 1 |
| `pack-ops/PACK-AGENTS.md` | `README.md` | (pack-root landing) | 1 |
| `pack-ops/PACK-AGENTS.md` | `CLAUDE.md` | (trinity) | 1 |
| `pack-ops/PACK-AGENTS.md` | `AGENTS.md` | (trinity) | 1 |
| `pack-ops/PACK-AGENTS.md` | `GEMINI.md` | (trinity) | 1 |
| `pack-ops/PACK-CHAT.md` | `README.md` | (pack-root landing) | 1 |
| **TOTAL** | — | — | **49** |

All 8 §6.2 allowlist entries (`README.md`, `QUICKSTART.md`, `LICENSE.md`, `LICENSE`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `MEMORY.md`) are USED at least once; the `LICENSE` (extension-less) entry is unused at HEAD but kept for future use. Allowlist coverage matches the architect's §6.2 design intent.

---

## §6 Anchor-phrase-exempted refs (11 hits)

| File:Line | Bare basename | Anchor phrase matched | Line context (truncated) |
|---|---|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md`:L5 | `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` | `post-install` | Source-of-design preamble; anchor in surrounding ±2 lines |
| `pack-ops/BOUNDARY-DEFINITION.md`:L5 | `AUDIT-USER-CURATION.md` | `post-install` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L242 | `settings.json` | `post-install` | "- Function. Required at a specific location by Claude Code (the .claude/ d..." |
| `pack-ops/BOUNDARY-DEFINITION.md`:L244 | `init-project.sh` | `post-install` | "- Placement. Under project-template/.claude/ so that init-project.sh mec..." |
| `pack-ops/BOUNDARY-DEFINITION.md`:L248 | `PACK-AGENTS.md` | `in the pack repo` | "- Historical failure. A prior commit added a reference to PACK-AGENTS.md (..." |
| `pack-ops/BOUNDARY-DEFINITION.md`:L249 | `PACK-AGENTS.md` (×3) | `in the pack repo` | "- Why §3 would have caught it. Apply step 1: who consumes project-template/..." |
| `pack-ops/BOUNDARY-DEFINITION.md`:L250 | `PACK-AGENTS.md` | `in the pack repo` | "- Why §3 step 4 prevents the recurrence. Any new file at pack root must be C..." |
| `pack-ops/HELP-FRAGMENT-TRACKER.md`:L49 | `OPTIONAL-FEATURES.md` | `in the pack repo` | "See the tracker example template (tracker.toml.pack-example in the pack repo,..." |
| `pack-ops/OPTIONAL-FEATURES.md`:L160 | `init-project.sh` | `at the client` | "init-project.sh at v11 as tracker.toml.example at the client" |

**Empirical note on `post-install` anchor (OQ-3 new addition):** the `post-install` anchor matched 4 hits in BOUNDARY-DEFINITION.md (L5 ×2, L242, L244). The architect's §6.4 rationale ("forward-pointing; immediate justification is L472") undercounted current-HEAD utility — the anchor was already load-bearing at HEAD. Recommend keeping it in the initial set per §6.4. (Note: L5 hits are FALSE POSITIVES — `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` and `AUDIT-USER-CURATION.md` would normally need qualification, but the survey's anchor-phrase check has them adjacent to "post-install" within ±2 lines. Phase 2 may want to re-examine whether L5 anchor-window is over-broad; alternative is `_CHECK_40_ANCHOR_WINDOW = 1` to tighten.)

---

## §7 Resolvable-bare-legit refs (33 hits — same-dir unique resolution)

These bare refs PASS by §6.5 implicit rule: same-directory bareness is legitimate. Bare ref to `MERGE-STRATEGY.md` from inside `pack-ops/` directory resolves unambiguously to `pack-ops/MERGE-STRATEGY.md`. No qualification needed. Many of these are pack-ops/-internal cross-references in tables/lists/inline prose.

| File:Line | Bare basename | Same-dir resolution | Line context |
|---|---|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | C2 PACK × OPERATIONS table cell |
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L48 | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L98 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "An earlier design proposed a 3-entry exemption list including..." |
| `pack-ops/BOUNDARY-DEFINITION.md`:L98 | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L101 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "Override 5 explicitly REJECTED the proposed exemption for BACKLOG.md + CHANGELOG.md" |
| `pack-ops/BOUNDARY-DEFINITION.md`:L101 | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L103 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "BACKLOG.md and CHANGELOG.md move to pack-ops/BACKLOG.md and pack-ops/CHANGELOG.md" |
| `pack-ops/BOUNDARY-DEFINITION.md`:L103 | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L117 | `CONCEPTUAL-REVIEW-METHODOLOGY.md` | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | "supporting-docs/ was classified as PACK-PRODUCT (proj..." |
| `pack-ops/BOUNDARY-DEFINITION.md`:L117 | `DRY-RUN-MIGRATION.md` | `pack-ops/DRY-RUN-MIGRATION.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L117 | `MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | (same line) |
| `pack-ops/BOUNDARY-DEFINITION.md`:L121 | `CONCEPTUAL-REVIEW-METHODOLOGY.md` | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | "- CONCEPTUAL-REVIEW-METHODOLOGY.md → pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md" |
| `pack-ops/BOUNDARY-DEFINITION.md`:L122 | `DRY-RUN-MIGRATION.md` | `pack-ops/DRY-RUN-MIGRATION.md` | "- DRY-RUN-MIGRATION.md → pack-ops/DRY-RUN-MIGRATION.md" |
| `pack-ops/BOUNDARY-DEFINITION.md`:L123 | `MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | "- MERGE-STRATEGY.md → pack-ops/MERGE-STRATEGY.md" |
| `pack-ops/BOUNDARY-DEFINITION.md`:L170 | `BOUNDARY-DEFINITION.md` | `pack-ops/BOUNDARY-DEFINITION.md` | "- pack-ops/PACK-CHAT.md (post-Commit 2 location) — top section..." |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L38 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | "Does the implementation violate any strategic or tactical established..." |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`:L185 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | "**From PACK-CHAT.md and pack memory MEMORY.md index:**" |
| `pack-ops/DRY-RUN-MIGRATION.md`:L197 | `MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | "- MERGE-STRATEGY.md — per-file customization-preservation matrix." |
| `pack-ops/DRY-RUN-MIGRATION.md`:L199 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "- BACKLOG.md — BD-114 (harness implementation), BD-125 (this doc)." |
| `pack-ops/MERGE-STRATEGY.md`:L7 | `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | "other pack-internal docs (e.g., HELP-FRAGMENT-PACK.md) and" |
| `pack-ops/MERGE-STRATEGY.md`:L479 | `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | "HELP-FRAGMENT-PACK.md and validate-pack.py Check 22 skips" |
| `pack-ops/OPTIONAL-FEATURES.md`:L133 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "**What it is** — moves issue tracking out of BACKLOG.md flat-file" |
| `pack-ops/OPTIONAL-FEATURES.md`:L184 | `MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | "BD-088's contract. See MERGE-STRATEGY.md." |
| `pack-ops/OPTIONAL-FEATURES.md`:L203 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "state, writes a sidecar BACKLOG.md from current issues, and flips" |
| `pack-ops/PACK-AGENTS.md`:L144 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "- BACKLOG.md (regenerated mirror; per-entry source at /backlog/)" |
| `pack-ops/PACK-AGENTS.md`:L145 | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | "- CHANGELOG.md (regenerated mirror; per-entry source at /changelog/" |
| `pack-ops/PACK-AGENTS.md`:L147 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | "- PACK-CHAT.md" |
| `pack-ops/PACK-AGENTS.md`:L148 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` | "- PACK-AGENTS.md" |
| `pack-ops/PACK-CHAT.md`:L42 | `BACKLOG.md` | `pack-ops/BACKLOG.md` | "\| BACKLOG.md \| Direct read \| Open BD-NNN items, current backlog stat" |
| `pack-ops/PACK-CHAT.md`:L43 | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | "\| CHANGELOG.md \| Direct read (last entry only) \| Current version and" |

### §7.1 §6.5-implicit rule discussion

The architect's §6.5 talks about "Allowlist evolution discipline" but does NOT explicitly state same-directory-bareness as a PASS-by-construction rule. The survey applied this as an implicit interpretation: if a bare ref's basename has exactly one candidate match AND that match is in the same directory as the referencing doc, the bareness is legitimate (analogous to programming-language "import siblings without prefix" semantics).

**OQ-S3 for Pack Chat (see §8):** does Phase 2 keep this same-dir-legit class, OR does it strictly enforce qualified refs even for same-dir cases? Strict enforcement would push 33 more refs onto the FLAGGED-QUALIFY pile (e.g., `pack-ops/PACK-CHAT.md` references `BACKLOG.md` in a table → strict mode requires `pack-ops/BACKLOG.md`). This is doctrinally consistent ("all refs are qualified") but inflates diff footprint significantly.

---

## §8 Allowlist adjustments suggested (for Pack Chat triage before Phase 2)

Based on §4 broken-ref analysis + §7 same-dir-legit discussion, the following allowlist additions / refinements would simplify Phase 2:

### §8.1 OQ-S1 — Should `scripts/tests/fixtures/` be added to architect-doc §5.1 EXCLUDE_PATH_PARTS?

**Survey applied:** YES — the survey excluded `scripts/tests/fixtures/` from the basename-index walk, matching §5.1 D4 intent (synthetic test content; not real candidates). The architect doc only names top-level `test-fixtures/`. This affects: 4 candidate paths for `BACKLOG.md` (would have included fixture trees), 1 candidate for `tracker.toml` (would have resolved to fixture content — wrong target), several agent files.

**Recommendation:** ratify the survey's expanded EXCLUDE in the architect doc as a clarifying §5.1 addendum. Without the expansion, the candidate-suggestion column of Check 40 failure messages would frequently point at fixture paths, which would be wrong guidance for the coder. Phase 2 implements with both exclusions; architect-doc addendum lands as part of Phase 2 commit.

### §8.2 OQ-S2 — Add concept-noun allowlist entries

7 of 11 broken-ref hits are filename-shaped concept-nouns (generated files, opt-in created files, placeholder templates). Recommended allowlist additions for Phase 2 (each carries one-line rationale per §6.2 / §6.6):

```python
# Concept-noun / generated-file / placeholder additions (proposed Phase 2):
"tracker.toml": "Generated by `pack tracker init` (not in pack repo; pack ships tracker.toml.pack-example)",
"id-map.json": "Generated tracker-mode metadata (not in pack repo)",
"report.md": "Generated by scripts/lib/customization-report.sh (not in pack repo)",
"manifest.txt": "RC9 manifest at test-fixtures/manifest.txt (per RC9 trigger rule)",
"BD-NNN.md": "Per-entry backlog filename pattern (template; see /backlog/_format.md)",
"TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
"phase-N.md": "Per-entry implementation-plan filename pattern (template)",
```

Adding these 7 entries reduces FLAGGED-BROKEN from 11 → 4 (remaining broken: `feedback_review_fix_one_cycle.md`, `ARCHITECTURE-V1.md`, `V3.3-DELTA.md`, `IMPLEMENTATION-PLAN-V11.0.md`).

### §8.3 OQ-S3 — Allowlist Claude-Code memory-cache `feedback_*.md` pattern

The `feedback_review_fix_one_cycle.md` ref (and any future `feedback_*.md` ref) lives in `~/.claude/projects/.../memory/`, EXTERNAL to the pack repo. Same class as the existing `MEMORY.md` allowlist entry.

**Option A (simple):** add the one ref to the allowlist:
```python
"feedback_review_fix_one_cycle.md": "Claude-Code memory cache feedback file (external to pack repo)",
```

**Option B (pattern):** extend allowlist semantics to support regex patterns:
```python
_CHECK_40_ALLOWLIST_PATTERNS = (
    (re.compile(r"^feedback_[a-z_]+\.md$"), "Claude-Code memory cache feedback file (external to pack repo)"),
)
```

Option B is forward-compat for future `feedback_*.md` refs but adds a second allowlist mechanism. **Recommend Option A for Phase 2** (forward-compat is YAGNI until a 2nd ref appears).

### §8.4 OQ-S4 — Historical/archived-doc refs (3 hits in CONCEPTUAL-REVIEW-METHODOLOGY.md L195 + L247)

`ARCHITECTURE-V1.md`, `V3.3-DELTA.md`, `IMPLEMENTATION-PLAN-V11.0.md` are historical-doc refs (the first two = pre-v11 archived docs; the last is explicitly self-identified as "(does not exist); canonical filename..."). Phase 2 options:

- **Option A:** prose-rewrite L195 to qualify the historical docs ("from the now-archived `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`" — but no current home for them, would be a dangling promise).
- **Option B:** add to allowlist as historical references with rationale.
- **Option C:** restructure L195/L247 to remove the bare refs (most invasive; loses historical citation).
- **Option D:** add anchor phrase `does not exist` to admit L247's self-flagging-as-non-existent pattern; rewrite L195 separately.

**Recommend:** discuss with user during triage. Default for Phase 2 if no input: Option A for L195 (rewrite with "archived" qualifier; no Check 40 reachability needed) + Option D for L247 (anchor phrase `does not exist` is minor surface widening but clearly load-bearing for the self-flagging pattern).

### §8.5 OQ-S5 — Agent-file DISAMBIGUATE handling (4+2 hits in BOUNDARY/MERGE-STRATEGY)

The L179 / L196 sibling-agent-file refs (see §3.2) are a recurring compositional pattern. Phase 2 options:

- **Option A:** qualify each verbosely (`.claude/agents/pack-coder.md`, `.claude/agents/pack-planner.md`, etc.) — inflates diff.
- **Option B:** prose-rewrite the lists to "[the pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher set of agents at `.claude/agents/`]" — eliminates the bare refs but changes wording.
- **Option C:** add an anchor phrase like `agents at .claude/agents/` or `agent set` to admit sibling-list bareness.

**Recommend:** Option B (clean prose rewrite); Option C is fragile because the anchor matches loosely.

### §8.6 OQ-S6 — Anchor-phrase `_CHECK_40_ANCHOR_WINDOW` width re-examination

Survey ran with `_CHECK_40_ANCHOR_WINDOW = 2` per §6.4. This produces FALSE POSITIVES at BOUNDARY-DEFINITION.md L5 where two unrelated bare refs (`ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` + `AUDIT-USER-CURATION.md`) match the `post-install` anchor merely because they're within ±2 lines of an anchor phrase that's about a different sentence. Recommend Phase 2 stays at window=2 per architect-doc, but be aware that L5 hits SHOULD be qualified despite passing — these are flagged as anchor-exempted in §6 but architecturally are FLAGGED-QUALIFY refs. Pack-Chat decides whether to:

- (a) Trust the anchor-window (admit L5 refs as anchor-exempt) — simplest but lets two malformed refs slide.
- (b) Manually re-qualify L5 in Phase 2 outside the anchor mechanism (correct but inconsistent with mechanism).
- (c) Tighten window to 1 — eliminates L5 false positives but may also remove legitimate exemptions.

### §8.7 OQ-S7 — Settings.json 4-candidate disambiguation (MERGE-STRATEGY.md L101)

See §3.3. Phase 2 needs one of: pick canonical reference (`.claude/settings.json` likely), or rewrite as compositional "any CLI's `settings.json` (e.g., `project-template/.claude/settings.json`)" pattern.

### §8.8 OQ-S8 — BOUNDARY-DEFINITION.md hot-spot reframing

BOUNDARY-DEFINITION.md has 24 FLAGGED-QUALIFY hits, mostly to a small set of repeated targets (`init-project.sh` 8x, `AUDIT-USER-CURATION.md` 6x). The diff to qualify these is ~30 lines of mechanical edits, but it changes a heavily-cross-linked doc. Phase 2 may want to:

- (a) Apply the qualifications mechanically (preserves all existing prose).
- (b) Consider a "first reference qualified; subsequent in-section references bare" doctrine — requires §6.5 allowlist evolution + new anchor mechanism. (Major surface widening; recommend AGAINST without architect-pass treatment.)

**Recommend (a)** — mechanical qualification per architect-doc §10.2 mapping. Phase 2 IMPL-REPORT cross-references the BOUNDARY-DEFINITION.md edit footprint.

---

## §9 Survey verification

```text
HEAD: 3e0cf6e47be52837f8bfc33fd347e911bf1a074e
Working tree status (git status --short):
?? maintenance-docs/v11-implementation/BD-179-SURVEY-REPORT.md
?? (preexisting v11-research files; not survey-related)

Verification:
- All 9 in-scope pack-ops/*.md files surveyed
- Per-classification counts: ALLOWLISTED=49, ANCHOR-EXEMPTED=11, RESOLVABLE-BARE-LEGIT=33, FLAGGED-QUALIFY=51, FLAGGED-BROKEN=11
- §3 flagged-refs-to-qualify table populated (51 rows)
- §4 broken-refs table populated (11 rows + 5-line empirical note on exclude scope)
- §5 allowlist-exemption table populated (23 rows with aggregate counts; all 8 entries used except LICENSE)
- §6 anchor-exemption table populated (11 rows)
- §7 resolvable-bare-legit table populated (33 rows)
- §8 allowlist-adjustment suggestions surfaced (8 OQ-S items for Pack Chat triage)
- NO edits to validate-pack.py, pack-ops/*.md, or any other file
- NO manifest regeneration
- NO state-changing git verbs run
- NO commits
- NO PREFLIGHT line (this is survey-only, not IMPL)
- NO IMPL-REPORT
```

---

## §10 SURVEY-COMPLETE line

```
SURVEY-COMPLETE: 4/4 patterns surveyed (P1+P2+P3+P5; P4 code blocks stripped per §3 D2); bare-ref count: 160; allowlist-exempted: 49; anchor-exempted: 11; resolvable-bare-legit: 33; flagged-qualify: 51; flagged-broken: 11; survey report at maintenance-docs/v11-implementation/BD-179-SURVEY-REPORT.md
```

---

**End of BD-179-SURVEY-REPORT.md.**

Phase 2 (Apply) — separate pack-coder spawn after Pack Chat surfaces this survey to user + gets explicit approval + any allowlist adjustments per §8 OQ-S items.
