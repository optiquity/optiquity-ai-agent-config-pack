# AUDIT — User curation (overrides on Phase 1 audit findings)

**Source audit:** `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` (Phase 1 of BD-175)
**Author:** User (captured by Pack Chat)
**Date:** 2026-05-18
**Purpose:** Authoritative user overrides on the auditor's classifications. Phase 2 architects read BOTH the audit doc AND this curation doc. **Where they disagree, this curation wins.**

---

## §1 — User overrides

### Override 1 — §A.16 `tracker.toml.pack-example` = STAYS

**Audit said:** STAYS-OR-MOVES (conservatively classified MOVES). Auditor's rationale: "Whether the pack-tracker example MUST sit at the pack root for `tracker-config.sh` detection is verify-needed — `tracker-config.sh` resolves path by call site, not root-walk, so structural requirement is unclear. Conservative: classify MOVES until verified."

**User override:** **STAYS.** Phase 2 Architect B treats this file as EXEMPT from relocation. No verification of structural requirement needed — user direction is sufficient authority.

### Override 2 — §B.B4 root `.github/` = PACK-ONLY (not SHARED-ANTI-PATTERN)

**Audit said:** SHARED-ANTI-PATTERN. Auditor's rationale: two parallel `.github/` directories exist (root + `project-template/.github/`) with three same-named files that DIFFER at HEAD (`diff -q` confirmed); BD-063 shipped lockstep edits to both.

**User override:** **PACK-ONLY.** The audit overclassified. The reasoning:
- Root `.github/` is PACK-ONLY (CI + issue templates for the pack repo itself)
- `project-template/.github/` is PROJECT-ONLY (templates shipped to client repos)
- Two SEPARATE directories with SEPARATE content in SEPARATE locations
- Same NAME because GitHub mandates `.github/` at repo root for ANY repo using GitHub features
- NOT shared in any meaningful sense

**Phase 2 architects:** treat root `.github/` and `project-template/.github/` as two independent PACK-ONLY and PROJECT-ONLY directories respectively. The parallel-name pattern is a GitHub-platform requirement, not a sharing anti-pattern.

### Override 3 — §F.F-3 reclass from structural anti-pattern to process-friction note

**Audit said:** §F-3 entry titled "`.github/` (root) parallel with `project-template/.github/`" with feasibility LOW (structurally required). The audit kept it in the SHARED-ANTI-PATTERN catalog despite acknowledging it can't be eliminated.

**User override:** This is NOT a structural anti-pattern. The lockstep-maintenance burden (e.g., BD-063 shipping edits to both in one commit) is real but it's PROCESS FRICTION, not a sharing problem. If Phase 2 Architect C wants to address the friction (e.g., a test that the two diverge intentionally rather than by drift), it can — but that's prevention-design work, not anti-pattern elimination.

**Phase 2 architects:** Drop F-3 from the SHARED-ANTI-PATTERN catalog. If process-friction mitigation is worth designing, Architect C handles it as part of structural prevention work.

### Override 4 — §F.F-7 reclass: parallel CLI dotted-dirs are NOT shared

**Audit said:** §F-7 listed `.claude/` / `.codex/` / `.gemini/` parallel pair (root vs `project-template/`) as a SHARED-ANTI-PATTERN.

**User override (same logic as Override 2 + 3):** **NOT shared.** The reasoning:
- Root `.claude/` / `.codex/` / `.gemini/` are PACK-ONLY (tool configs governing the pack repo itself — Claude Code reads its `.claude/` at the pack repo root; Codex reads `.codex/`; Gemini reads `.gemini/`)
- `project-template/.claude/` / `.codex/` / `.gemini/` are PROJECT-ONLY (tool configs that ship to client repos via install — when installed, they become the client repo's `.claude/` etc.)
- Two SEPARATE sets, SEPARATE audiences, SEPARATE content
- Same names because each tool mandates its dotted dir at the consuming repo's root

**Phase 2 architects:** treat root and project-template dotted-dirs as independent PACK-ONLY and PROJECT-ONLY directories respectively. Drop F-7 from the SHARED-ANTI-PATTERN catalog.

---

## §2 — Updated counts

After applying the three overrides:

### §A root inventory (updated)

- **STAYS:** 12 (audit count) **+ 1** (`tracker.toml.pack-example` override) = **13**
- **MOVES:** 7 conditional (audit count) **− 1** (`tracker.toml.pack-example` reclassified STAYS) = **6 confirmed MOVES**, all PACK-ONLY (5: `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`, `PACK-AGENTS.md`, `PACK-CHAT.md`) + 1 SHARED-ANTI-PATTERN-CANDIDATE (`QUICKSTART.md`)

### §B directory inventory (updated)

- **PACK-ONLY:** 26 (audit count) **+ 1** (root `.github/` override) = **27**
- **PROJECT-ONLY:** 16 (audit count — `project-template/.github/` already classified correctly) = **16**
- **SHARED-ANTI-PATTERN:** 2 (audit count) **− 1** (root `.github/` reclassified) = **1** (only `supporting-docs/` per F-1)
- **IGNORED-GENERATED:** 1 (unchanged)

### §F SHARED-ANTI-PATTERN catalog (updated)

- Audit listed 7 entries; F-3 + F-7 reclassified out. Remaining: **5 entries** (F-1 `supporting-docs/`, F-2 `project-template/docs/pack/` name, F-4 `QUICKSTART.md`, F-5 `OPTIONAL-FEATURES.md` source-vs-installed mismatch, F-6 trinity filename collisions)

### §D + §E (unchanged)

User did not override §D contamination findings or §E path-reference scan. Both stand as the audit reported.

### §C v11 commit audit (unchanged)

User did not override severity classifications or violation type assignments. All 13 boundary violations (4 HIGH + 6 MEDIUM + 3 LOW) stand for Phase 2 Architect A re-litigation.

---

## §3 — Open questions

All previously flagged open questions resolved. F-7 (parallel CLI dotted-dirs) decided by user via Override 4 above.

---

## §4 — Application instruction for Phase 2 architects

When Phase 2 architects (re-litigation / directory / prevention) read the audit:

1. **Audit is the auditor's record.** Read it for evidence, citations, scope.
2. **This curation is the user's authoritative correction.** Where this disagrees with the audit, this wins.
3. **Where this curation is silent, the audit stands.** Don't infer additional overrides.
4. **Open questions from §3 above** should be re-surfaced to the user via Pack Chat before Phase 2 architect decisions land that depend on them.

---

## §5 — User-stated boundary articulation (verbatim — input to Phase 2 Architect B)

This is the user's articulation of the boundary intent. It is INPUT to Phase 2 Architect B (who designs the formal G7 boundary definition); it is NOT the final boundary definition itself.

> Files in `project-template/` are for projects and will be in the project dirs. Not necessarily root dirs. They are the product of the config pack. They are not (a) configs used by tools governing the config pack to do its work or (b) config pack operational docs used by the pack to do its work.

**Application:** Phase 2 Architect B reads this as starting principle; refines into the formal boundary definition (G7) and ensures the definition is documented for discoverability (SC8). Architect B may extend, refine, or surface edge cases as part of the design — but the user's intent (project-template = product; pack-related = (a) tool-governing configs + (b) operational docs) is preserved.
