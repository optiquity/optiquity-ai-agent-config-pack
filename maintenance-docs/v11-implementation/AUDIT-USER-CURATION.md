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

### Override 9 — C's M2 (P-missed-7 two-tier codification) is CONFIRMED

**Architect C said:** Codifies P-missed-7 in BOTH pack-root trinity Pack memory AND project-template trinity Project memory, with DIFFERENT wording per audience (pack version detailed; project version "shorter and inverted"). Frames as defense-in-depth, not byte-identical mirror.

**User decision:** **CONFIRMED.** "Different audience means different wording is fine." Two audience-specific rules, not a mirror in the byte-identical-drift sense. Compatible with D-4 ("no mirrors as default") because the two rules are substantively different even though they share the principle.

**Phase 5 coder:** implements both codification surfaces per C's M2 design. No consolidation to one surface.

**Phase 3 reviewer:** no cross-trinity drift gate needed for this codification (different wording is intentional, not drift).

### Override 8 — OQ-3 OPTIONAL-FEATURES.md SPLIT is CONFIRMED

**Architects A + B said:** Both default to SPLIT — `OPTIONAL-FEATURES.md` MOVES to `pack-ops/OPTIONAL-FEATURES.md` (pack-side) AND a new `project-template/docs/pack/OPTIONAL-FEATURES.md` is CREATED with project-side content. `init-project.sh` gains an install stage. 5 broken project-side references resolve to the new file.

**User decision:** **CONFIRMED SPLIT.** "One for pack. One for projects. There may be something common to both and maybe some individual to both. That is OK." Pack-side and project-side files are independently curated; the project-side file is NOT required to be a byte-identical mirror — content overlap is allowed where it serves both audiences, but each file's content is tailored to its audience.

**Phase 5 coder:** implements both files per B's S2 commit design. Project-side content tailored to project audience (not byte-identical copy).

**Phase 3 reviewer:** no byte-identity gate between pack-side and project-side OPTIONAL-FEATURES.md (intentional separate content).

### Override 7 — `QUICKSTART.md` STAYS at root (no SPLIT, no move)

**Architect B said:** SPLIT QUICKSTART.md into pack-side half (stays at root) + project-side half (`project-template/docs/pack/QUICKSTART.md`, ships to clients via `init-project.sh`).

**User override:** **NO SPLIT.** `QUICKSTART.md` stays at root as-is. Exception authorized — it's a 47-line pre-install pack-installer doc that serves one audience (pack-installers); SPLIT is over-engineering. GitHub-landing-page visibility is the rationale for keeping at root.

**Phase 5 coder:** no action needed for QUICKSTART.md. B's S1 (QUICKSTART SPLIT) commit is DROPPED. `project-template/docs/pack/QUICKSTART.md` is NOT created. `init-project.sh` does NOT gain a new install stage for it.

### Override 10 — Remove `docs/pack/QUICKSTART.md` references from 4 help files (M3 cascade)

**Reviewer said (M3):** Override 7 keeps QUICKSTART at root and drops B's S1 (create `docs/pack/QUICKSTART.md`). But 5 project-side references (in 4 files) still point to `docs/pack/QUICKSTART.md` — pointers that will be broken when no such file exists. Recommended Architect B fix-pass to resolve the broken references.

**User direction:** **REMOVE the `docs/pack/QUICKSTART.md` references from the 4 help files entirely.** The user's framing: install docs (QUICKSTART) are pre-install pack-installer content, not in-project help content. The 4 help files serve users using the pack inside their project — they have no business pointing at install docs. The correct fix is REMOVAL of those references, not retargeting them.

**Files affected (4 distinct files, 5 references total):**
1. `project-template/.gemini/commands/pack-help.toml:10`
2. `project-template/.claude/skills/pack-help/SKILL.md:13`
3. `project-template/.codex/skills/pack-help/SKILL.md:13`
4. `project-template/docs/pack/HELP-FRAGMENT.md` (line 4 + line 31)

**Files NOT affected:** `project-template/README.md` lines 16 + 39 — both reference QUICKSTART correctly (line 16 says "in the pack root"; line 39 lists it as a pack-supporting-doc read without copying). README.md needs no change.

**Phase 2 Architect B fix-pass:** designs the wording-removal for each of the 4 files. Architect's call HOW to reword (likely delete the QUICKSTART mention from each list while keeping PM-CHAT.md / INSTALL-PROCEDURES.md / OPTIONAL-FEATURES.md mentions intact); user's call is the REMOVE direction.

**Phase 5 coder:** mechanical wording edit per Architect B's fix-pass design. Trinity rule applies — 4 files include `.claude/`, `.codex/`, `.gemini/` parallel surfaces, so symmetry verification at edit time.

### Override 6 — `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/` (NOT `maintenance-docs/`)

**Architect B said:** Moves `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` to `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.

**User override:** **`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`.** B's "maintenance-docs/ houses live methodology" reasoning is rejected. Destination is `pack-ops/`.

**Phase 5 coder:** moves to `pack-ops/`, not `maintenance-docs/`. Path-reference updates target `pack-ops/`.

### Override 5 — Architect B's "C2 root exemption list" is REJECTED for BACKLOG.md + CHANGELOG.md

**Architect B said (in `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §2-§3):** Designed a "three-file C2 root exemption list" of files that STAY at root despite being PACK × OPERATIONS — `BACKLOG.md`, `CHANGELOG.md`, `tracker.toml.pack-example` — with "pinned by external constraints" reasoning.

**User override (no authorization for the exemption):** ONLY `tracker.toml.pack-example` was authorized to STAY per Override 1. `BACKLOG.md` and `CHANGELOG.md` MUST MOVE to a pack-only directory. The user's boundary articulation classifies them as pack operational docs (curation §5: "config pack operational docs used by the pack to do its work"), not as configs governing the pack repo (no tool reads them at a specific root location). "Pinned by external constraints" is not a valid exemption rationale — the user explicitly stated only `tracker.toml.pack-example` was exempted.

**Phase 2 architect-fix-pass:** A fresh pack-architect designs the corrected placement for `BACKLOG.md` + `CHANGELOG.md`. Output amends or supersedes the affected parts of `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`. Architect's call where to place them (likely the `pack-ops/` directory B designed for other C2 files, but architect decides).

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
