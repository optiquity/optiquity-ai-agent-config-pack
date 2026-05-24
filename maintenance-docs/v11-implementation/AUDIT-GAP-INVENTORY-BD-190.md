# AUDIT-GAP-INVENTORY-BD-190

**Pass:** BD-190 Phase 1 — INVENTORY ONLY (no code edits).
**BD:** BD-190 — Comprehensive audit-vocabulary-gap sweep across pack-shipped files.
**Branch:** v11-dev
**HEAD at start:** `642191e65a2559eb9e8758cf5debb984520b945c`
**Author:** pack-coder (inventory pass, background subagent)
**Date:** 2026-05-24

---

## §0 — Methodology

Inventoried every match returned by the extended grep:

```bash
grep -rnE "V[0-9]+(\.[0-9]+)? §|ARCHITECTURE-V[0-9.]+|ARCHITECTURE-V11-|AUDIT-USER-CURATION|AUDIT-PRE-19C|RESEARCH-PER-ENTRY|RESEARCH-TRACKER|RESEARCH-AUDIT|EXTERNAL-RESEARCH|IMPLEMENTATION-PLAN-ADDENDUM|IMPLEMENTATION-PLAN\.md|maintenance-docs/" \
   project-template/ supporting-docs/METHODOLOGY.md supporting-docs/INSTALL-PROCEDURES.md pack-ops/HELP-FRAGMENT-TRACKER.md
```

Total raw matches across INCLUDE set: **107**.

Each match was classified by reading 3–5 lines of surrounding context:

- **Class A** — Real leak, Cat A drop fix (bare-version cite or pack-internal `*.md` cite where rule wording stands without it; cite is footnote-style provenance, not load-bearing).
- **Class B** — Real leak, Cat B substitute fix (cite where rule needs substantive replacement — sibling reference or descriptive prose; rule cannot stand alone after a bare drop).
- **Class C** — Legitimate (false positive) — three sub-classes:
  - **C-pedagogical:** boundary-definition pedagogical content (the skill or doc DEFINES the boundary by enumerating pack-only paths/names; H.13 fence-marker scope or boundary-investigation skill content).
  - **C-client-side:** filename refers to a client-installed regenerated mirror (`docs/project/IMPLEMENTATION-PLAN.md`, `docs/project/CHANGELOG.md`, etc.); the bare filename resolves at client install.
  - **C-defer-H11-H13:** match lives inside a file that H.11 or H.13 will modify in the same fix-shape pattern (per PLAN-CLEANUP-BATCH-19C.md §H.11 / §H.13).

---

## §1 — Summary table

| Class | Count | Sweep disposition |
|---|---|---|
| **A** (Cat A drop fix) | 29 | Phase 2 sweep |
| **B** (Cat B substitute fix) | 0 | Phase 2 sweep |
| **C-pedagogical (stays as-is)** | 2 | LEGITIMATE — leave |
| **C-defer-H13** | 8 | DEFER to H.13 (fence-marker wraps content) |
| **C-client-side** | 68 | LEGITIMATE — leave (client-side filename refs) |
| **D** (qualified-filename + pack-internal §X; Cat A drop fix) | 2 | Phase 2 sweep (added by mini-inventory §12) |
| **E** (qualified-filename + client-resolvable §X; legitimate) | 12 | LEGITIMATE — leave (sections exist in pack-shipped destination files) |
| **Total** | **121** | (31 real leaks: 29 Class A + 2 Class D; 90 legitimate or H.13-deferred) |

**Real leaks for Phase 2 sweep: 31** (29 Class A + 2 Class D — all Cat A drops).

**File-count for Phase 2 sweep: 11 files** (1 tracker example + 2 byte-identical HELP-FRAGMENT-TRACKER pair + 1 HELP-FRAGMENT + 2 issue templates + 1 METHODOLOGY + 4 pm-startup cluster). Mini-inventory §12 adds 2 Class D leaks to the existing `tracker.toml.project-example` file already in scope; no new files added to Phase 2 sweep scope.

---

## §2 — Real leaks per file (Class A + Class B)

All 29 real leaks are Class A — Cat A drops (bare-version `V1 §X.Y` / `V2 §X.Y` / `V3.3 §X.Y` shorthand cites to pack-internal architect docs). No Class B substitutions identified — every cite is footnote-style provenance whose drop leaves the surrounding rule wording intact.

**Note on V1-class classification (correcting H.10 §2.4.2.a).** The H.10 IMPL-REPORT §2.4.2.a classified `V1 §10.2` in `pm-startup` cluster files as LEGITIMATE on the grounds that "V1 references the project-side context file." Investigation for this inventory shows this claim was UNSUPPORTED:

1. The project-template trinity (CLAUDE.md / AGENTS.md / GEMINI.md) has NO numbered `§X.Y` sections — section structure is unnumbered H2 / H3.
2. `maintenance-docs/v11-research/ARCHITECTURE.md` (the V1 architect doc) has §8.4 ("Prompt language change"), §8.5 ("Per-agent prompt adaptation strategy"), §7.5 ("PACK-FEEDBACK upstreaming (OQ-11)"), §10.2 ("How Pack Chat discovers / triages") — section content matches the topic of each cite.
3. `project-template/docs/pack/PLATFORM-SKILLS.md` does NOT contain any `V1 §X.Y` reference form (the H.10 claim that "V1 cites resolve to the project-template trinity file `# V1 §8.4` form documented in PLATFORM-SKILLS.md style" is not borne out by grep).

Conclusion: **V1 cites are pack-internal architect doc references**, same leak class as V3.3 / V2 cites. Per the trinity Filename uniqueness rule (commit `1121b3d`): "bare-version shorthand like `V3.3 §3.X` as a reference to `ARCHITECTURE-V3.3-DELTA.md` sections is a leak under the rule's spirit because the reader has no filename to follow, no path to resolve." The same applies to V1 → ARCHITECTURE.md, V2 → ARCHITECTURE-V2.md.

This inventory classifies all V1 / V2 / V3.3 bare-version cites as Class A real leaks.

### §2.1 `project-template/tracker.toml.project-example` (3 leaks)

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 15 | `# Pack-side and client-side modes are independent (V1 §3.4).` | A | Drop ` (V1 §3.4)` parenthetical; sentence ends at `independent.` |
| 71 | `# Cross-entity dependency graph tuning (V3.3 §5.5; BD-108).` | A | Replace ` (V3.3 §5.5; BD-108)` with ` (BD-108)` — preserve BD provenance (client-resolvable), drop bare-version cite. |
| 75 | `# cycle_check_k = 10  # K-hop bound for link-creation cycle check (V3.3 §5.5)` | A | Drop ` (V3.3 §5.5)` parenthetical; comment ends at `cycle check`. |

**Out-of-scope sites for completeness (not flagged by inventory grep):** L11 `ARCHITECTURE.md §6` and L17 `ARCHITECTURE.md §3.1` — these cite `ARCHITECTURE.md` (client-side filename), but the cited sections describe pack-side migration / tracker-config-spec content, NOT project-side architecture content. They WILL not resolve at a client install. These are a SEPARATE leak class (qualified-filename + §X.Y where target file exists client-side but the section is pack-internal). They are NOT flagged by this inventory's grep vocabulary (no `V[0-9] §` match; no `maintenance-docs/`); flagged here for Pack Chat awareness — recommend a NEW BD to address if not covered by other batch work.

### §2.2 `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (5 leaks)

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 19 | `` `pack td <verb>` orchestrates the V3.3 §3 two-path TD promotion + the `` | A | Drop ` V3.3 §3` (rewrite as "the two-path TD promotion" — `the two-path` introduces the subject). |
| 27 | `` ... Path 1 — promote TD to a new phase epic (V3.3 §3.3). PM Chat invokes architect by default per §7.2. \| `` | A | Drop ` (V3.3 §3.3)` parenthetical and ` per §7.2` clause; final reads `Path 1 — promote TD to a new phase epic. PM Chat invokes architect by default.` (continuation `per §7.2` is anaphoric to V3.3; falls with the parent). |
| 28 | `` ... Path 2 — promote TD to a new phase task under phase N (V3.3 §3.4). Wires `Dependencies` bullets to cross-entity `blocked-by` edges per §5.1. \| `` | A | Drop ` (V3.3 §3.4)` parenthetical and ` per §5.1` clause; final reads `Path 2 — promote TD to a new phase task under phase N. Wires Dependencies bullets to cross-entity blocked-by edges.` |
| 29 | `` ... Direct close (V3.3 §3.2). No promotion label; no new entity. \| `` | A | Drop ` (V3.3 §3.2)` parenthetical; sentence ends at `Direct close.` |
| 31 | `Path 3 is forbidden per V3.3 §1 supersession + §3 line 27. There is` | A | Drop ` per V3.3 §1 supersession + §3 line 27` clause; sentence ends at `Path 3 is forbidden.` (same fix as H.10 §2.4.1 Leak 1 in PM-CHAT.md L544). |

### §2.3 `pack-ops/HELP-FRAGMENT-TRACKER.md` (5 leaks)

**Byte-identical content to `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per CI Check 24.** Same 5 leaks at same line numbers as §2.2. Phase 2 sweep MUST modify both files byte-identically to preserve the Check 24 invariant.

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 19 | `` `pack td <verb>` orchestrates the V3.3 §3 two-path TD promotion + the `` | A | (same as §2.2 line 19) |
| 27 | `` ... Path 1 — promote TD to a new phase epic (V3.3 §3.3). PM Chat invokes architect by default per §7.2. \| `` | A | (same as §2.2 line 27) |
| 28 | `` ... Path 2 — promote TD to a new phase task under phase N (V3.3 §3.4). Wires `Dependencies` bullets to cross-entity `blocked-by` edges per §5.1. \| `` | A | (same as §2.2 line 28) |
| 29 | `` ... Direct close (V3.3 §3.2). No promotion label; no new entity. \| `` | A | (same as §2.2 line 29) |
| 31 | `Path 3 is forbidden per V3.3 §1 supersession + §3 line 27. There is` | A | (same as §2.2 line 31) |

### §2.4 `project-template/docs/pack/HELP-FRAGMENT.md` (3 leaks)

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 19 | `` \| `pack td promote --to=phase-N` \| Promote a TD-NNN to a new phase epic (Path 1; V3.3 §3.1 / §3.3). \| `` | A | Drop `; V3.3 §3.1 / §3.3` from parenthetical; final reads `(Path 1).` |
| 20 | `` \| `pack td promote --to=phase-N.M` \| Promote a TD-NNN to a new phase task under phase N (Path 2; V3.3 §3.1 / §3.4). \| `` | A | Drop `; V3.3 §3.1 / §3.4` from parenthetical; final reads `(Path 2).` |
| 21 | `` \| `pack td resolve <td-id>` \| Direct-close wrapper (V3.3 §3.2). No promotion label; no new entity. \| `` | A | Drop ` (V3.3 §3.2)` parenthetical; final reads `Direct-close wrapper.` |

### §2.5 `project-template/.github/ISSUE_TEMPLATE/inbound.yml` (3 leaks)

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 2 | `description: External bug, feature request, or pack-feedback observation. Pack-feedback categories file upstream against the pack repo per V1 §7.5.` | A | Drop ` per V1 §7.5` clause; sentence ends at `against the pack repo.` |
| 15 | `        V1 §7.5; the chat at triage time emits the upstream issue automatically.` | A | Rewrite — drop bare-version cite. Suggested: `the chat at triage time emits the upstream issue automatically.` (drops `V1 §7.5; ` prefix). Need to verify YAML indentation preserved in the value-block. |
| 20 | `      description: Select the category that best matches your report. Pack-feedback subcategories file upstream against the pack repo per V1 §7.5.` | A | Drop ` per V1 §7.5` clause; sentence ends at `against the pack repo.` |

### §2.6 `project-template/.github/ISSUE_TEMPLATE/config.yml` (1 leak)

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 1 | `# GitHub Issues form-family configuration (V2 §4.1).` | A | Drop ` (V2 §4.1)` parenthetical; comment ends at `configuration.` |

### §2.7 `supporting-docs/METHODOLOGY.md` (1 leak — H.9-NIT-1 gap)

| Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|
| 1169 | `     Document-locations resolver (V1 §8.5 / D-6).` | A | Drop ` (V1 §8.5 / D-6)` parenthetical; sentence ends at `Document-locations resolver.` |

**Note on H.9-NIT-1 gap:** H.9-NIT-1 fix swept 11 bare-V3.3 sites in METHODOLOGY.md at L312, L1166, L1170, L1176, L1207 (Cat B), L1213–L1237 cluster. L1169's `V1 §8.5 / D-6` cite was OUT-OF-SCOPE for H.9-NIT-1 (different bare-version class — V1 not V3.3) and not absorbed. This is the SAME leak class as the 8 V1 cites in the pm-startup cluster (per the V1-classification correction above) but not absorbed under H.10 either. It is in BD-190 scope.

### §2.8 H.10-classified-legitimate sites re-classified per V1-classification correction

Per the V1-classification correction at the top of §2, the following 8 sites previously classified LEGITIMATE in H.10 §2.4.2.a are re-classified Class A real leaks:

| File | Line | Content (excerpt) | Class | Proposed fix shape (Cat A) |
|---|---|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` | 84 | `the trinity \`## Document locations\` table in the project context file (V1 §8.4).` | A | Drop ` (V1 §8.4)` parenthetical; sentence ends at `in the project context file.` |
| `project-template/skills/pm-startup/SKILL.md` | 211 | `Step 7 is reserved. The V1 §10.2 tracker-mode triage queue` | A | Drop ` V1 §10.2` (rewrite as "The tracker-mode triage queue..."). |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 84 | (mirror — same content as canonical) | A | (same fix) |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 211 | (mirror — same content as canonical) | A | (same fix) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 84 | (mirror — same content as canonical) | A | (same fix) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 211 | (mirror — same content as canonical) | A | (same fix) |
| `project-template/.gemini/commands/pm-startup.toml` | 81 | (mirror — TOML body equivalent) | A | (same fix; mirror-sync invariant applies) |
| `project-template/.gemini/commands/pm-startup.toml` | 208 | (mirror — TOML body equivalent) | A | (same fix; mirror-sync invariant applies) |

**Cluster-sync invariant:** The 4 pm-startup cluster files (canonical SKILL.md + .claude mirror + .codex mirror + .gemini .toml) MUST be edited byte-identically in the canonical / .claude / .codex `.md` siblings. The `.gemini/.toml` requires the same edit inside the TOML triple-quoted string wrapping the prompt body. Same H.10 §2.4.2.c invariant.

**Phase 2 sweep MUST include this cluster** despite H.10 having touched these files — H.10 classified these 8 sites LEGITIMATE; BD-190's V1-classification correction overrides that decision.

**Total Class A leaks per §2.8:** 8.

### §2.9 Class A real-leak totals by file (Phase 2 sweep scope)

| File | Class A count | RC9 surface? |
|---|---|---|
| `project-template/tracker.toml.project-example` | 3 | Yes (`project-template/`) |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 5 | Yes (`project-template/`) |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | 5 | Yes (`pack-ops/`) |
| `project-template/docs/pack/HELP-FRAGMENT.md` | 3 | Yes (`project-template/`) |
| `project-template/.github/ISSUE_TEMPLATE/inbound.yml` | 3 | Yes (`project-template/`) |
| `project-template/.github/ISSUE_TEMPLATE/config.yml` | 1 | Yes (`project-template/`) |
| `supporting-docs/METHODOLOGY.md` | 1 | Yes (`supporting-docs/`) |
| `project-template/skills/pm-startup/SKILL.md` | 2 | Yes (`project-template/`) |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 2 | Yes (`project-template/`) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 2 | Yes (`project-template/`) |
| `project-template/.gemini/commands/pm-startup.toml` | 2 | Yes (`project-template/`) |
| **Total** | **29** | All RC9-fixture-surface |

**Files-touched count for Phase 2: 11** (the 4 pm-startup cluster files + 7 unique files). Per RC9 (manifest-regen rule), the Phase 2 commit MUST regenerate `test-fixtures/manifest.txt` (multiple v11-surface roots touched).

---

## §3 — Class C-pedagogical legitimate matches (boundary-definition content)

These 10 matches are pedagogical content that EXPLAINS the pack/project boundary by naming pack-only paths. Removing them would defeat the document's purpose. They are LEGITIMATE; no Phase 2 edit.

**Of these 10**, 8 are inside H.13 PLAN fence-marker scope (will be wrapped with `<!-- DENY-LIST-CONTENT-START -->` / `<!-- ... -END -->` markers — content stays unchanged, just becomes Check-37-exempt). The remaining 2 (boundary-investigation/SKILL.md L19, L27) stay as-is and continue to be flagged by future verification greps but are LEGITIMATE per the rule's intent (the skill DEFINES the boundary).

### §3.1 `project-template/skills/boundary-investigation/SKILL.md` (4 matches)

| Line | Content (excerpt) | Why legitimate |
|---|---|---|
| 19 | `` root), `pack-ops/` (any file there), `maintenance-docs/`, `scripts/`, `` | Inside § "When this skill applies" — explicitly defines the NOT-applies enumeration (pack-only files). Removing breaks the skill's WHEN-applies / WHEN-not-applies contract. |
| 27 | `` / etc. agent roster, `pack-ops/` operational docs, `maintenance-docs/` `` | Inside § "Why this skill exists" — describes pack-only infrastructure that the skill teaches readers NOT to import into project files. Removing breaks the why-this-exists rationale. |
| 105 | `` - **Path prefixes:** `maintenance-docs/`, `pack-ops/` (any file there — `` | Inside § "Step 4 — Deny-list" — the canonical deny-list enumeration (the SUBSTANTIVE content the skill teaches). H.13 PLAN step 5 wraps this WITH fence markers (`<!-- DENY-LIST-CONTENT-START/END -->`); content stays, gets explicitly fence-marked. |
| 152 | `` (`CLAUDE.md` at pack root / `pack-ops/PACK-AGENTS.md` / `` `maintenance-docs/`).`` | Inside § "Frame-rotation reminder" — pedagogical pack-side example contrasting with project-side example. Removing breaks the contrast/teaching purpose. |

**Class C-pedagogical rationale:** the `boundary-investigation` skill is the project-side SSOT for boundary discipline; mentioning pack-only path prefixes (`pack-ops/`, `maintenance-docs/`, etc.) IS the skill's pedagogical purpose. The H.13 fence-marker mechanism (per `_CHECK_37_PER_LINE_FENCE_FILES`) is the structural solution: validate-pack.py Check 37 stops flagging fence-wrapped content, but the content itself stays.

### §3.2 `project-template/docs/pack/prompts/coder.md` (2 matches)

| Line | Content (excerpt) | Why legitimate |
|---|---|---|
| 85 | `` `maintenance-docs/`, a pack-* agent name, the `Pack Chat` capitalized `` | Inside the standard-variant boundary-discipline block (L83-89). Per H.13 PLAN step 6 (item Pair 1), this block will be wrapped with `<!-- DENY-LIST-CONTENT-START/END -->` fence markers. DEFER to H.13. |
| 200 | `` pack-repo `maintenance-docs/`, pack-* agent names, `Pack Chat` `` | Inside the fix-cycle-variant boundary-discipline block (L195-202). Per H.13 PLAN step 6 (item Pair 2), this block will be wrapped with fence markers. DEFER to H.13. |

### §3.3 `project-template/docs/pack/prompts/reviewer.md` (1 match)

| Line | Content (excerpt) | Why legitimate |
|---|---|---|
| 103 | `     under the pack-repo `maintenance-docs/`, a pack-* agent name, or the `Pack Chat`` | Inside the boundary-discipline review-dimension block (L102-107). Per H.13 PLAN step 7, this block will be wrapped with fence markers. DEFER to H.13. |

### §3.4 `project-template/CLAUDE.md` (1 match)

| Line | Content (excerpt) | Why legitimate |
|---|---|---|
| 390 | `  PACK-CHAT.md, pack-* agent prompts, pack-repo \`maintenance-docs/\`,` | Inside § "Project memory" > "Project SSOT-first" bullet — the canonical project-side boundary-deny-list enumeration. Per H.13 PLAN step 8, this parenthetical (`maintenance-docs/`, etc.) will be wrapped with fence markers. DEFER to H.13. |

### §3.5 `project-template/AGENTS.md` (1 match)

| Line | Content (excerpt) | Why legitimate |
|---|---|---|
| 367 | `  PACK-CHAT.md, pack-* agent prompts, pack-repo \`maintenance-docs/\`,` | Project trinity parallel of CLAUDE.md L390. Per project-template trinity rule + H.13 PLAN step 8 byte-identical placement. DEFER to H.13. |

### §3.6 `project-template/GEMINI.md` (1 match)

| Line | Content (excerpt) | Why legitimate |
|---|---|---|
| 386 | `  PACK-CHAT.md, pack-* agent prompts, pack-repo \`maintenance-docs/\`,` | Project trinity parallel of CLAUDE.md L390. Per project-template trinity rule + H.13 PLAN step 8. DEFER to H.13. |

### §3.7 `scripts/pack-tracker.sh:227` (out-of-scope; not in INCLUDE grep)

Not flagged by the INCLUDE-set grep but noted here for completeness: `manifest="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"` — `scripts/` is OUT-OF-SCOPE for BD-190 (BACKLOG entry explicitly excludes scripts beyond detect.sh). This is a pack-side file referencing a pack-side path inside pack-side code. LEGITIMATE pack-side reference. No action.

### §3.8 Class C-pedagogical total

10 matches across 6 files (boundary-investigation/SKILL.md L19 + L27 + L105 + L152 = 4; coder.md L85 + L200 = 2; reviewer.md L103 = 1; project trinity CLAUDE L390 + AGENTS L367 + GEMINI L386 = 3).

**H.13-fence coverage breakdown:**

- **C-defer-H13 (8 matches inside H.13 fence scope):** boundary-investigation/SKILL.md L105 + L152 (PLAN step 5); coder.md L85 + L200 (PLAN step 6); reviewer.md L103 (PLAN step 7); trinity CLAUDE L390 + AGENTS L367 + GEMINI L386 (PLAN step 8).
- **C-pedagogical-stays-as-is (2 matches outside H.13 fence scope):** boundary-investigation/SKILL.md L19 (When-this-skill-applies enumeration) + L27 (Why-this-skill-exists pedagogical) — pedagogical content the skill needs to teach the boundary; LEGITIMATE per the trinity Filename uniqueness rule's exception for content-that-defines-the-boundary.

---

## §4 — Class C-client-side legitimate matches (`IMPLEMENTATION-PLAN.md` client-installed filename refs)

These 68 matches reference `IMPLEMENTATION-PLAN.md` as a bare filename. At client install, the project's `docs/project/IMPLEMENTATION-PLAN.md` is a regenerated mirror of the per-entry tree at `docs/project/implementation-plan/`. The bare-filename reference resolves to a client-side file; this is LEGITIMATE per audit §0.1 vocabulary (client-installed filenames are not leaks).

**Class C-client-side rationale:** `IMPLEMENTATION-PLAN.md` is in the `_CLIENT_INSTALLED_FILES` set (per `scripts/init-project.sh`); the per-entry tree + monolithic mirror both exist at client install. Project-side prompts, skills, and methodology docs that say "read IMPLEMENTATION-PLAN.md Phase N" are pointing at a real client-resolvable file. Audit §0.1 explicitly distinguishes "bare client-side filenames" (LEGITIMATE) from "bare pack-internal filenames + `*.md` extension cites" (LEAK class).

### §4.1 File enumeration (68 matches across 18 files)

| File | Lines | Count | Class |
|---|---|---|---|
| `project-template/GEMINI.md` | 220, 227, 237 | 3 | C-client-side |
| `project-template/CLAUDE.md` | 224, 231, 241 | 3 | C-client-side |
| `project-template/AGENTS.md` | 208, 215, 225 | 3 | C-client-side |
| `project-template/.gemini/commands/pm-startup.toml` | 76, 89 | 2 | C-client-side |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 79, 92 | 2 | C-client-side |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 79, 92 | 2 | C-client-side |
| `project-template/skills/pm-startup/SKILL.md` | 79, 92 | 2 | C-client-side |
| `project-template/skills/audit-methodology/SKILL.md` | 77 | 1 | C-client-side |
| `project-template/docs/pack/PM-CHAT.md` | 123, 323, 324, 506, 600, 708, 751, 796, 833, 879 | 10 | C-client-side |
| `project-template/docs/pack/prompts/architect.md` | 25, 35, 56 | 3 | C-client-side |
| `project-template/docs/pack/prompts/docs-researcher.md` | 18 | 1 | C-client-side |
| `project-template/docs/pack/prompts/reviewer.md` | 21 | 1 | C-client-side |
| `project-template/docs/pack/prompts/planner.md` | 16 | 1 | C-client-side |
| `project-template/docs/pack/prompts/pm-chat.md` | 52, 170, 174 | 3 | C-client-side |
| `project-template/docs/pack/prompts/coder.md` | 14, 18, 52, 63, 153, 190 | 6 | C-client-side |
| `project-template/docs/project/implementation-plan/_rules.md` | 46 | 1 | C-client-side |
| `supporting-docs/METHODOLOGY.md` | 113, 124, 128, 293, 345, 388, 440, 462, 510, 566, 579, 604, 659, 681, 688, 718, 933, 1190, 1291, 1372, 1481, 1513, 1611 | 23 | C-client-side |
| `supporting-docs/INSTALL-PROCEDURES.md` | 1262 | 1 | C-client-side |
| **Total** | | **68** | |

**Note on `IMPLEMENTATION-PLAN.md` vs `IMPLEMENTATION-PLAN-ADDENDUM-*.md`:** The grep pattern matched `IMPLEMENTATION-PLAN.md` literally (68 matches) and `IMPLEMENTATION-PLAN-ADDENDUM` separately (0 matches at HEAD — already swept by H.10 §2.4.1 Leak 7). The 68 `IMPLEMENTATION-PLAN.md` matches all refer to the client-installed file.

---

## §5 — Verification grep on already-swept files (expected: clean for Class A leaks)

Per pre-flight, ran extended grep on the H.9-swept and H.10-swept file sets. **Result is NOT fully clean for H.10-swept files** because H.10 §2.4.2.a classified 8 V1 cites in pm-startup cluster as LEGITIMATE (a classification this inventory disputes — see §2 V1-classification correction).

### §5.1 H.9-swept files (7 per-entry skeleton files)

Verification grep on H.9-swept files:

```
grep -nE "V[0-9]+(\.[0-9]+)? §|ARCHITECTURE-V[0-9.]+|RESEARCH-PER-ENTRY|maintenance-docs/" \
  project-template/docs/project/{backlog,implementation-plan,changelog}/{_rules,_intro,_format}.md
```

**Result:** zero matches → BOUNDARY OK. H.9 + H.9-NIT-1 + H.9 audit-gap absorption swept all classes (architect-doc cites + audit-gap RESEARCH-* + audit-gap bare-V3.3) in these files cleanly. No anomalies.

### §5.2 H.10-swept files (7 files: PM-CHAT.md + 4 pm-startup cluster + boundary-investigation skill + detect.sh)

Verification grep on H.10-swept files:

```
grep -nE "V[0-9]+(\.[0-9]+)? §|ARCHITECTURE-V[0-9.]+|RESEARCH-PER-ENTRY|AUDIT-USER-CURATION|IMPLEMENTATION-PLAN-ADDENDUM|maintenance-docs/" \
  project-template/skills/pm-startup/SKILL.md \
  project-template/.claude/skills/pm-startup/SKILL.md \
  project-template/.codex/skills/pm-startup/SKILL.md \
  project-template/.gemini/commands/pm-startup.toml \
  project-template/skills/boundary-investigation/SKILL.md \
  scripts/lib/detect.sh
```

**Result:**

- `project-template/skills/pm-startup/SKILL.md` L84 + L211: V1 cites (2 hits)
- `project-template/.claude/skills/pm-startup/SKILL.md` L84 + L211: V1 cites (2 hits)
- `project-template/.codex/skills/pm-startup/SKILL.md` L84 + L211: V1 cites (2 hits)
- `project-template/.gemini/commands/pm-startup.toml` L81 + L208: V1 cites (2 hits)
- `project-template/skills/boundary-investigation/SKILL.md` L19, L27, L105, L152: `maintenance-docs/` (4 hits)
- `scripts/lib/detect.sh`: zero matches → BOUNDARY OK
- `project-template/docs/pack/PM-CHAT.md`: zero V-version matches (only client-side `IMPLEMENTATION-PLAN.md` filename refs — counted in §4 not §5)

**Anomaly classification:**

1. **pm-startup cluster V1 cites (8 sites).** H.10 §2.4.2.a INTENTIONALLY classified these LEGITIMATE on the grounds that V1 references the project-side context file. This inventory disputes that classification (see §2 V1-classification correction): V1 IS a pack-internal architect doc cite. **Disposition: Phase 2 sweep absorbs these 8 sites per §2.8.** This is a CORRECTION to an H.10 decision, not a verification anomaly — Pack Chat triages whether to accept the correction.

2. **boundary-investigation skill `maintenance-docs/` cites (4 sites at L19, L27, L105, L152).** H.10 Cat F intentionally REMOVED the L124 `AUDIT-USER-CURATION.md` cite but DID NOT modify the pedagogical `pack-ops/` / `maintenance-docs/` enumerations at L19, L27, L105, L152. These remain because they ARE the skill's pedagogical purpose. **Disposition: LEGITIMATE Class C-pedagogical (see §3.1).** L105 + L152 are inside H.13 PLAN step 5 fence scope (will be fence-wrapped); L19 + L27 stay as-is (outside fence; still pedagogical). NOT a verification anomaly.

### §5.3 Already-swept METHODOLOGY.md sites (H.9-NIT-1)

H.9-NIT-1 swept 12 cite-drops at L312, L1166, L1170, L1176, L1207 (Cat B), L1214, L1220, L1223, L1225, L1230, L1232, L1237 (×2). Verification:

```
grep -nE "V3.3 §|ARCHITECTURE-V3.3-DELTA" supporting-docs/METHODOLOGY.md
```

**Result:** zero matches → BOUNDARY OK for V3.3 class.

The remaining METHODOLOGY.md leak is at L1169 (`V1 §8.5 / D-6`), which was NOT in H.9-NIT-1's V3.3 sweep scope (different bare-version class). This is a NEW BD-190 finding (§2.7).

### §5.4 Verification summary

- **H.9-swept files: PASS (clean for all classes).**
- **H.10-swept files: PASS for V3.3 / AUDIT-USER-CURATION / IMPLEMENTATION-PLAN-ADDENDUM classes; 8 V1 cites + 4 `maintenance-docs/` cites remain by intentional H.10 / pedagogical classification, NOT anomalies.**
- **H.9-NIT-1-swept METHODOLOGY.md sites: PASS for V3.3 class; L1169 V1 cite remains (new BD-190 finding, §2.7).**

No surprise anomalies. The 8 V1-cite sites are a documented re-classification (this inventory disputes H.10 §2.4.2.a); Pack Chat triages.

---

## §6 — Recommended Phase 2 sweep scope (file list for Pack Chat approval)

Pack Chat should approve the following file list for the BD-190 Phase 2 sweep commit:

### §6.1 In-scope files (11 files; 31 leaks total — 29 Class A + 2 Class D)

1. `project-template/tracker.toml.project-example` (5 leaks — 3 Class A + 2 Class D from §12)
2. `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (5 leaks)
3. `pack-ops/HELP-FRAGMENT-TRACKER.md` (5 leaks — byte-identical to #2 per Check 24)
4. `project-template/docs/pack/HELP-FRAGMENT.md` (3 leaks)
5. `project-template/.github/ISSUE_TEMPLATE/inbound.yml` (3 leaks)
6. `project-template/.github/ISSUE_TEMPLATE/config.yml` (1 leak)
7. `supporting-docs/METHODOLOGY.md` (1 leak at L1169 — H.9-NIT-1 gap)
8. `project-template/skills/pm-startup/SKILL.md` (2 leaks — V1-classification correction)
9. `project-template/.claude/skills/pm-startup/SKILL.md` (2 leaks — V1-classification correction)
10. `project-template/.codex/skills/pm-startup/SKILL.md` (2 leaks — V1-classification correction)
11. `project-template/.gemini/commands/pm-startup.toml` (2 leaks — V1-classification correction)

### §6.2 Invariants the Phase 2 coder must preserve

- **CI Check 24 byte-identity** between `pack-ops/HELP-FRAGMENT-TRACKER.md` and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (#2 + #3).
- **Cluster-sync invariant** across the 4 pm-startup cluster files (#8 + #9 + #10 byte-identical canonical/.claude/.codex; #11 byte-equivalent inside TOML triple-quoted string).
- **RC9 manifest regeneration:** Phase 2 commit MUST rebuild `test-fixtures/manifest.txt` (multiple v11-surface roots — `project-template/`, `pack-ops/`, `supporting-docs/` — all touched).
- **Trinity exemption:** No project-template trinity (CLAUDE.md / AGENTS.md / GEMINI.md) files in scope here (those are deferred to H.13 fence-marker pass).

### §6.3 Out-of-scope (already deferred per BD-190 entry)

- H.9-swept 7 per-entry skeleton files (BOUNDARY OK; not modified by Phase 2)
- H.10-swept 5 files for V3.3 / AUDIT-USER-CURATION / IMPLEMENTATION-PLAN-ADDENDUM classes (already absorbed); EXCEPT the 4 pm-startup cluster files for V1 cites (these ARE in §6.1 per V1-classification correction)
- H.11 scope: `project-template/docs/pack/prompts/pm-chat.md` (3 supporting-docs cites — different leak class; H.11 absorbs)
- H.13 scope: 7 fence-marker files (`scripts/validate-pack.py`, `project-template/skills/boundary-investigation/SKILL.md`, `project-template/docs/pack/prompts/coder.md`, `project-template/docs/pack/prompts/reviewer.md`, `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `project-template/docs/pack/PM-CHAT.md`); H.13 wraps pedagogical `maintenance-docs/` enumerations with fence markers (content stays).
- All of `scripts/` except `scripts/lib/detect.sh:22` (already absorbed by H.10 19th-leak pass).

### §6.4 Sweep-time triage required from Pack Chat

The 8 sites in §2.8 (pm-startup cluster V1-cite re-classification) require explicit Pack Chat triage before Phase 2 coder spawn:

- Pack Chat reviews this inventory's V1-classification correction.
- If Pack Chat ACCEPTS the correction: the 8 sites are in Phase 2 scope (per §6.1 items 8–11).
- If Pack Chat REJECTS the correction (preserves H.10 §2.4.2.a's LEGITIMATE classification): the 8 sites stay; §6.1 items 8–11 drop from scope; Phase 2 closes 21 leaks across 7 files instead of 29 across 11.

This inventory's recommendation: ACCEPT the correction. The V1-as-pack-internal-architect-doc evidence (§2 V1-classification correction items 1–3) is unambiguous; preserving H.10's LEGITIMATE classification would leave a documented audit-vocabulary-gap leak class in client-shipped surface.

### §6.5 Verification grep for the Phase 2 IMPL-REPORT

After Phase 2 sweep, this grep should return zero matches across the BD-190 INCLUDE set (excluding H.13-deferred pedagogical content and Class C-client-side `IMPLEMENTATION-PLAN.md` legitimate refs):

```bash
grep -rnE "V[0-9]+(\.[0-9]+)? §|ARCHITECTURE-V[0-9.]+|ARCHITECTURE-V11-|AUDIT-USER-CURATION|AUDIT-PRE-19C|RESEARCH-PER-ENTRY|RESEARCH-TRACKER|RESEARCH-AUDIT|EXTERNAL-RESEARCH|IMPLEMENTATION-PLAN-ADDENDUM" \
   project-template/ supporting-docs/METHODOLOGY.md supporting-docs/INSTALL-PROCEDURES.md pack-ops/HELP-FRAGMENT-TRACKER.md
```

Expected: zero `V[0-9] §` matches in §6.1 in-scope files; zero matches anywhere outside the H.13-deferred files and the boundary-investigation skill (which keeps L19/L27 pedagogical content). The `maintenance-docs/` substring will still appear in the H.13-deferred files (CLAUDE.md, AGENTS.md, GEMINI.md, coder.md, reviewer.md, boundary-investigation/SKILL.md) and the bullet-list inside each — H.13 will wrap with fence markers later (and Check 37 fence support comes online in H.13 to skip those lines).

**Qualified-filename verification grep (added by mini-inventory §12):** After Phase 2 sweep, this grep should return zero matches for `ARCHITECTURE.md §` in `tracker.toml.project-example`:

```bash
grep -rnE "(ARCHITECTURE|METHODOLOGY|INSTALL-PROCEDURES|PM-CHAT|PLATFORM-SKILLS|PACK-FEEDBACK|CHANGELOG|BACKLOG|STATUS|IMPLEMENTATION-PLAN|README)\.md §" \
   project-template/ supporting-docs/METHODOLOGY.md supporting-docs/INSTALL-PROCEDURES.md pack-ops/HELP-FRAGMENT-TRACKER.md
```

Expected after Phase 2: zero `ARCHITECTURE.md §` matches in `tracker.toml.project-example` (the only Class D leaks identified). The 12 Class E matches (METHODOLOGY.md / INSTALL-PROCEDURES.md / PM-CHAT.md qualified-filename refs in PM-CHAT.md / PLATFORM-SKILLS.md / pm-startup cluster / pm-chat.md prompt / METHODOLOGY.md cross-refs) remain — they are legitimate cross-references to pack-shipped destination files whose `§X` sections exist client-side.

---

## §7 — Other findings (out-of-scope but flagged)

### §7.1 `tracker.toml.project-example` L11 + L17 `ARCHITECTURE.md §X.Y` qualified-name leak class

L11 (`ARCHITECTURE.md §6`) and L17 (`ARCHITECTURE.md §3.1`) — these cite `ARCHITECTURE.md` (a client-side filename) followed by `§6` / `§3.1`. At client install, `docs/project/ARCHITECTURE.md` exists, but the §6 / §3.1 sections described here ("forward migration script", "tracker config spec") describe PACK-internal content, NOT project-side architecture content. The project's own ARCHITECTURE.md is project-specific (broker integrations, app architecture per `project-template/CLAUDE.md`) and will not have §6 / §3.1 with matching content.

This is a SEPARATE leak class from BD-190's scope:

- BD-190 vocabulary: bare-version `V[0-9] §`, explicit pack-internal `*.md`, qualified `maintenance-docs/` prefix.
- L11 + L17 vocabulary: qualified-filename cite + §X.Y where the target file exists at client install but the SECTION described is pack-internal.

The grep pattern in BD-190's prompt does NOT match this leak class (no `V[0-9] §`, no `maintenance-docs/`, the `ARCHITECTURE.md §X` substring is bare). Recommendation: Pack Chat consider a NEW BD to address this leak class across pack-shipped files (potentially affects other `ARCHITECTURE.md §X` / `INSTALL-PROCEDURES.md §X` / `METHODOLOGY.md §X` cites in pack-shipped surface).

### §7.2 H.10 §2.4.2.a V1-classification disposition history

This inventory disputes H.10 §2.4.2.a's classification of V1 cites as LEGITIMATE. The H.10 implementer-side reasoning ("V1 references the project-side context file") was unsupported by evidence:

1. Project trinity has no `§X.Y` numbered sections.
2. `maintenance-docs/v11-research/ARCHITECTURE.md` has §X.Y sections that match cite topic.
3. PLATFORM-SKILLS.md has no `V1 §X.Y` reference form.

**Pack Chat may revisit H.10 §2.4.2.a triage decision** in the Phase 2 review cycle. Either resolution is defensible:
- Accept V1-classification correction → Phase 2 absorbs all 29 cite-line sites (13 V1 + 1 V2 + 15 V3.3); V1 breakdown: 8 pm-startup cluster + 3 inbound.yml + 1 METHODOLOGY.md L1169 + 1 tracker.toml.project-example L15.
- Preserve H.10 §2.4.2.a → Phase 2 absorbs ONLY non-pm-startup-cluster sites (21 sites: 5 V1 + 1 V2 + 15 V3.3); the 8 pm-startup cluster V1 sites stay LEGITIMATE per H.10.

Recommendation noted in §6.4.

### §7.3 No new POQs from this inventory pass

This inventory pass did NOT discover new architectural questions or design gaps beyond the V1-classification correction noted above. The trinity Filename uniqueness rule at commit `1121b3d` formally classifies bare-version shorthand as a leak class — V1 / V2 / V3.3 / V3 all fall under "bare-version shorthand to pack-internal docs" by the rule's plain reading. No new POQs.

---

## §8 — Definition-of-Done checklist

| # | Criterion | Status |
|---|---|---|
| 1 | Inventory doc written at `maintenance-docs/v11-implementation/AUDIT-GAP-INVENTORY-BD-190.md` | PASS |
| 2 | All Class A/B/C matches across INCLUDE set documented (107 matches enumerated) | PASS |
| 3 | Class C judgments include WHY rationale (per file/pattern) | PASS (§3 + §4) |
| 4 | Defer files (H.11/H.13 scope) identified by reading PLAN | PASS (§6.3) |
| 5 | Verification grep on already-swept files reported | PASS (§5) |
| 6 | §6 includes recommended sweep scope file list for Pack Chat approval | PASS (§6.1) |
| 7 | V1-classification correction documented with evidence | PASS (§2 head note + §5.2 anomaly classification + §7.2) |
| 8 | No code edits made this pass (inventory only) | PASS |
| 9 | HEAD verified `642191e` at start | PASS (git rev-parse HEAD output) |
| 10 | RC9 invariants documented for Phase 2 coder (§6.2) | PASS |

---

## §9 — Files changed inventory

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/AUDIT-GAP-INVENTORY-BD-190.md` | new (this file) |

**Total: 1 file created. Zero source-file edits this pass.**

---

## §10 — Boundary discipline check (P-missed-7)

This inventory pass writes ONLY to `maintenance-docs/v11-implementation/` (pack-internal). No project-side or pack-shipped file is touched. P-missed-7 boundary investigation NOT triggered (no project-side edits). Boundary discipline stop: not applicable to this pass.

---

## §11 — PREFLIGHT trace

After inventory + verification + IMPL-REPORT write, emitting PREFLIGHT line to parent session per system prompt.

---

## §12 — Qualified-filename leak class extension (mini-inventory)

**Pass:** BD-190 mini-inventory — scope expansion to absorb the qualified-filename leak class flagged in §7.1.
**Date:** 2026-05-24
**Trigger:** Pack Chat (A2) triage decision following §7.1 finding: EXPAND BD-190's scope to absorb `<client-installed-filename>.md §X.Y` leak class (no new BD; no delays).
**HEAD at start:** `642191e65a2559eb9e8758cf5debb984520b945c` (unchanged from inventory start).

### §12.0 Methodology

Ran grep across BD-190 INCLUDE set with qualified-filename vocabulary:

```bash
grep -rnE "(ARCHITECTURE|METHODOLOGY|INSTALL-PROCEDURES|PM-CHAT|PLATFORM-SKILLS|PACK-FEEDBACK|CHANGELOG|BACKLOG|STATUS|IMPLEMENTATION-PLAN|README)\.md §" \
   project-template/ supporting-docs/METHODOLOGY.md supporting-docs/INSTALL-PROCEDURES.md pack-ops/HELP-FRAGMENT-TRACKER.md
```

Total raw matches: **14**.

Classified by reading surrounding context AND verifying whether the cited `§X.Y` section exists in the pack-shipped destination file:

- **Class D — Real leak (Cat A drop fix):** filename resolves at client install BUT cited section content is pack-internal (the corresponding `§X.Y` section in the client-installed file describes UNRELATED content — typically project-side architecture rather than pack-internal tracker/migration content).
- **Class E — Legitimate (false positive):** filename resolves AND cited `§X.Y` section exists in the client-installed file with matching content. Pack-shipped files (`METHODOLOGY.md`, `INSTALL-PROCEDURES.md`, `PM-CHAT.md`) preserve their `§X.Y` numbered / headed structure at client install — these cross-references work as-shipped.

**Verification of pack-shipped destinations:**

| Destination heading cited | Pack-shipped file | Verified line | Verdict |
|---|---|---|---|
| `METHODOLOGY.md § RAG index hygiene` | `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` | L140 (`### RAG index hygiene`) | EXISTS |
| `METHODOLOGY.md § Format-vs-solutions: worked examples` | `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` | L833 (`### Format-vs-solutions: worked examples`) | EXISTS |
| `INSTALL-PROCEDURES.md § 7.5 reply grammar` | `supporting-docs/INSTALL-PROCEDURES.md` → `docs/pack/INSTALL-PROCEDURES.md` | L1201 (`### 7.5 Reply grammar`) | EXISTS |
| `INSTALL-PROCEDURES.md § 7.2.3` | (same) | L1067 (`#### 7.2.3 swift-format install`) | EXISTS |
| `INSTALL-PROCEDURES.md § 7.3.1 / 7.3.2` | (same) | L1124 / L1138 | EXISTS |
| `INSTALL-PROCEDURES.md § "Project file conventions in pack-controlled directories"` | (same) | L29 (`## Project file conventions in pack-controlled directories`) | EXISTS |
| `PM-CHAT.md § Behavioral rules` | `project-template/docs/pack/PM-CHAT.md` | L176 (`## Behavioral rules`) | EXISTS |
| `ARCHITECTURE.md §6` | `maintenance-docs/v11-research/ARCHITECTURE.md` (pack-internal V1 architect doc) | L943 (`## 6. Migration algorithm`) | PACK-INTERNAL ONLY |
| `ARCHITECTURE.md §3.1` | (same) | L473 (`### 3.1 Where tracker config lives`) | PACK-INTERNAL ONLY |

The client-installed `docs/project/ARCHITECTURE.md` is project-authored architecture content per `project-template/CLAUDE.md` § Architecture (broker integrations, app architecture). It will NOT contain `§6 Migration algorithm` or `§3.1 Where tracker config lives` — those sections describe pack-internal tracker / migration spec content that has no place in a project's own architecture document.

### §12.1 Per-match classification table

| # | File | Line | Match content (excerpt) | Class | Rationale |
|---|---|---|---|---|---|
| 1 | `project-template/tracker.toml.project-example` | 11 | `# 3. Run the forward migration script (see ARCHITECTURE.md §6).` | **D** | Cites `ARCHITECTURE.md §6` which contains pack-internal "Migration algorithm" content (`maintenance-docs/v11-research/ARCHITECTURE.md` L943). The client-side `docs/project/ARCHITECTURE.md` is project-authored and has no migration spec section. |
| 2 | `project-template/tracker.toml.project-example` | 17 | `# Read by scripts/lib/tracker-config.sh; spec: ARCHITECTURE.md §3.1.` | **D** | Cites `ARCHITECTURE.md §3.1` which contains pack-internal "Where tracker config lives" spec (`maintenance-docs/v11-research/ARCHITECTURE.md` L473). The client-side `docs/project/ARCHITECTURE.md` has no tracker-config spec section. |
| 3 | `project-template/.gemini/commands/pm-startup.toml` | 112 | `` `METHODOLOGY.md § RAG index hygiene` for the principle. `` | E | METHODOLOGY.md is pack-shipped to `docs/pack/METHODOLOGY.md` at client install; the `### RAG index hygiene` heading exists at L140 in the pack-shipped file. Client-resolvable. |
| 4 | `project-template/docs/pack/prompts/pm-chat.md` | 49 | `per the INSTALL-PROCEDURES.md § 7.5 reply grammar` | E | INSTALL-PROCEDURES.md is pack-shipped to `docs/pack/INSTALL-PROCEDURES.md`; `### 7.5 Reply grammar` exists at L1201. Client-resolvable. |
| 5 | `project-template/docs/pack/prompts/pm-chat.md` | 284 | `per `docs/pack/METHODOLOGY.md § Format-vs-solutions: worked examples`` | E | `### Format-vs-solutions: worked examples` exists at METHODOLOGY.md L833. Client-resolvable (and explicitly path-qualified to the pack-shipped location). |
| 6 | `project-template/.claude/skills/pm-startup/SKILL.md` | 115 | `` `METHODOLOGY.md § RAG index hygiene` for the principle. `` | E | (same as match #3 — pm-startup cluster mirror) |
| 7 | `project-template/docs/pack/PM-CHAT.md` | 157 | `` See `METHODOLOGY.md § RAG index hygiene` for the `` | E | METHODOLOGY.md `### RAG index hygiene` exists at L140. Client-resolvable. |
| 8 | `project-template/docs/pack/PLATFORM-SKILLS.md` | 533 | `` INSTALL-PROCEDURES.md § "Project file conventions in pack-controlled directories" `` | E | `## Project file conventions in pack-controlled directories` exists at INSTALL-PROCEDURES.md L29. Client-resolvable. |
| 9 | `project-template/docs/pack/PLATFORM-SKILLS.md` | 553 | (same heading, second cite) | E | (same as #8) |
| 10 | `project-template/.codex/skills/pm-startup/SKILL.md` | 115 | `` `METHODOLOGY.md § RAG index hygiene` for the principle. `` | E | (pm-startup cluster mirror — same as #3) |
| 11 | `project-template/skills/pm-startup/SKILL.md` | 115 | `` `METHODOLOGY.md § RAG index hygiene` for the principle. `` | E | (canonical pm-startup — same as #3) |
| 12 | `supporting-docs/METHODOLOGY.md` | 1360 | `render a **Form I** in the shape of `INSTALL-PROCEDURES.md § 7.2.3`` | E | `#### 7.2.3 swift-format install` exists at INSTALL-PROCEDURES.md L1067. Client-resolvable (and METHODOLOGY.md ships to `docs/pack/`, alongside INSTALL-PROCEDURES.md). |
| 13 | `supporting-docs/METHODOLOGY.md` | 1377 | `mirrors INSTALL-PROCEDURES.md § 7.2.3 (kickoff swift-format install)` (+ `§ 7.3.1 / 7.3.2`) | E | `§ 7.2.3` at L1067, `§ 7.3.1` at L1124, `§ 7.3.2` at L1138 — all client-resolvable. |
| 14 | `supporting-docs/METHODOLOGY.md` | 1542 | `trinity § Project memory + PM-CHAT.md § Behavioral rules` | E | `## Behavioral rules` exists at `project-template/docs/pack/PM-CHAT.md` L176 (PM-CHAT.md is pack-shipped to `docs/pack/PM-CHAT.md`). Client-resolvable. |

### §12.2 Class D per-file totals (Phase 2 sweep additions)

| File | Class D count | Aggregate with existing Class A | RC9 surface? |
|---|---|---|---|
| `project-template/tracker.toml.project-example` | 2 | 3 Class A + 2 Class D = 5 leaks | Yes (`project-template/`) |
| **Total Class D** | **2** | (all in 1 file — same file already in §6.1) | |

### §12.3 Proposed fix shapes (Cat A drops)

Both Class D leaks fall to the same Cat A drop shape as the broader BD-190 pattern (drop the bare cite; surrounding sentence stands without it).

| Line | Current content | Proposed Cat A drop |
|---|---|---|
| 11 | `#   3. Run the forward migration script (see ARCHITECTURE.md §6).` | `#   3. Run the forward migration script.` (drop `(see ARCHITECTURE.md §6)`; the surrounding step numbering already describes the action — the cite was provenance, not load-bearing instruction) |
| 17 | `# Read by scripts/lib/tracker-config.sh; spec: ARCHITECTURE.md §3.1.` | `# Read by scripts/lib/tracker-config.sh.` (drop `; spec: ARCHITECTURE.md §3.1`; comment reverts to identifying the consumer script — the spec cite was footnote-style provenance) |

**Alternative Cat B substitute shape (NOT recommended):** Replace `ARCHITECTURE.md §X.Y` with an inline descriptive phrase (e.g., L11: "Run the forward migration script (see `tracker.toml` documentation for trigger semantics)."). Rejected because (a) the surrounding wording already conveys the action; (b) Cat B substitutes add wording without adding signal; (c) consistent with the 29 Class A drops already proposed across the inventory.

### §12.4 Class E rationale (12 legitimate cross-references — leave as-is)

The 12 Class E matches reference `METHODOLOGY.md`, `INSTALL-PROCEDURES.md`, and `PM-CHAT.md` with section headings that exist verbatim in the pack-shipped destination files. These files are copied into client installs via `scripts/init-project.sh` stage S6 (METHODOLOGY.md / INSTALL-PROCEDURES.md) and the standard `project-template/` mass-copy (PM-CHAT.md). The cross-references will resolve at client install (reader follows `docs/pack/METHODOLOGY.md § RAG index hygiene` → existing heading at L140).

**Note: this is the same Class C-client-side rationale generalized to qualified-filename + heading-cite form.** Class C-client-side (existing §4) covered bare `IMPLEMENTATION-PLAN.md` filename refs; Class E extends that legitimacy reasoning to filename + section combinations where BOTH the filename AND the section exist client-side. The vocabulary distinction matters because the audit-vocabulary-gap question is "does the reader land somewhere coherent at the client install?" — for Class E, yes; for Class D, no (the file lands but the section either doesn't exist or has unrelated project-authored content).

### §12.5 Cross-reference back to existing inventory §7.1

§7.1 ("`tracker.toml.project-example` L11 + L17 `ARCHITECTURE.md §X.Y` qualified-name leak class") originally recommended Pack Chat consider a NEW BD for this leak class. Pack Chat triage decision (A2) was to ABSORB the class into BD-190's Phase 2 scope rather than open a separate BD. This mini-inventory implements that scope absorption:

- The 2 sites flagged in §7.1 are now §12 Class D leaks #1 and #2.
- The §7.1 recommendation ("recommend a NEW BD to address if not covered by other batch work") is SUPERSEDED — covered by BD-190 Phase 2 expanded scope.
- File count for Phase 2 stays at 11 (no new file added — both Class D leaks live in `tracker.toml.project-example`, which is item #1 in §6.1).
- Total Phase 2 leaks: 29 → 31 (added 2 Class D drops to item #1).

### §12.6 Sweep-time invariants (additions for Phase 2 coder)

No new invariants beyond those already documented in §6.2. Both Class D fixes are simple Cat A drops on the existing in-scope file (`tracker.toml.project-example`); the RC9 manifest-regen requirement already applies (file is under `project-template/`); the file has no byte-identical mirror to maintain.

The Phase 2 coder should treat the 5 leaks in `tracker.toml.project-example` as a single coherent edit (3 V-class + 2 qualified-filename), not as separate passes.

### §12.7 Mini-inventory verification

Verification grep across BD-190 INCLUDE set, restricted to the qualified-filename vocabulary:

```bash
grep -rnE "(ARCHITECTURE|METHODOLOGY|INSTALL-PROCEDURES|PM-CHAT|PLATFORM-SKILLS|PACK-FEEDBACK|CHANGELOG|BACKLOG|STATUS|IMPLEMENTATION-PLAN|README)\.md §" \
   project-template/ supporting-docs/METHODOLOGY.md supporting-docs/INSTALL-PROCEDURES.md pack-ops/HELP-FRAGMENT-TRACKER.md
```

**Result:** 14 matches enumerated above. **Of the 14:** 2 are Class D real leaks (Phase 2 sweep); 12 are Class E legitimate cross-references (no action). All 14 reviewed via either (a) direct context read for Class D candidates, or (b) destination-file heading-existence verification (table in §12.0). No matches deferred — full classification this pass.

### §12.8 Mini-inventory totals

- **Class D (Phase 2 sweep additions):** 2 leaks in 1 file (already in §6.1 in-scope list).
- **Class E (legitimate, no action):** 12 matches across 9 files (METHODOLOGY.md ×4, INSTALL-PROCEDURES.md targets ×4, PM-CHAT.md target ×1, pm-startup cluster ×3 with shared content).
- **New files added to §6.1 Phase 2 sweep scope:** 0 (Class D leaks consolidate into an existing in-scope file).
- **Updated Phase 2 totals:** 31 leaks across 11 files (was 29 across 11; +2 leaks, +0 files).

### §12.9 Pack Chat decision input — Phase 2 spawn

This mini-inventory pass requires NO additional Pack Chat triage decisions beyond the original §6.4 (the V1-classification correction for pm-startup cluster). The Class D additions are mechanically isomorphic to the existing Class A drops (same Cat A "drop the parenthetical" fix shape on the same in-scope file). Phase 2 coder spawn is unblocked when Pack Chat resolves §6.4 (accept or reject V1-classification correction); §12 adds 2 cite-drops to that work without any cross-cutting design implication.

---

(End of report.)
