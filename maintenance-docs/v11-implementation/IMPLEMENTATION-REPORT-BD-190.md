# IMPLEMENTATION-REPORT-BD-190

**BD:** BD-190 — Comprehensive audit-vocabulary-gap sweep across pack-shipped files (Phase 2).
**Branch:** v11-dev
**HEAD at start:** `642191e65a2559eb9e8758cf5debb984520b945c`
**HEAD at end:** `642191e65a2559eb9e8758cf5debb984520b945c` (no commits made; coder is read-only on git state)
**Author:** pack-coder (Phase 2 sweep, background subagent)
**Date:** 2026-05-24

---

## §1 — Scope

BD-190 Phase 2 — apply 31 audit-vocabulary-gap cite-drops across 11 pack-shipped files per `AUDIT-GAP-INVENTORY-BD-190.md` §2 + §12 specs.

| Class | Count | Disposition |
|---|---|---|
| **Class A** (bare-version cite drops) | 29 | All applied (Cat A drops) |
| **Class D** (qualified-filename `ARCHITECTURE.md §X` pack-internal sections) | 2 | All applied (Cat A drops) |
| **Total** | **31** | All applied |

**Pack Chat triage decisions absorbed by this Phase 2:**
- Class D V1-classification correction (§2.8 of inventory): ACCEPT — V1 cites in pm-startup cluster classified as pack-internal architect doc cites (same leak class as V3.3 / V2), 8 sites swept.
- Class D qualified-filename absorption (§12 of inventory): ABSORB into BD-190 — no new BD; 2 sites in `tracker.toml.project-example`.
- §7.1 finding ABSORB: the 2 `ARCHITECTURE.md §X.Y` sites (L11 + L17 of `tracker.toml.project-example`) folded into Phase 2.

---

## §2 — Edits applied (per file, per leak, BEFORE/AFTER)

### §2.1 `project-template/tracker.toml.project-example` (5 leaks: 3 Class A + 2 Class D)

| Leak | Line | BEFORE | AFTER |
|---|---|---|---|
| Class D #1 | 11 | `#   3. Run the forward migration script (see ARCHITECTURE.md §6).` | `#   3. Run the forward migration script.` |
| Class A #1 | 15 | `# Pack-side and client-side modes are independent (V1 §3.4).` | `# Pack-side and client-side modes are independent.` |
| Class D #2 | 17 | `# Read by scripts/lib/tracker-config.sh; spec: ARCHITECTURE.md §3.1.` | `# Read by scripts/lib/tracker-config.sh.` |
| Class A #2 | 71 | `# Cross-entity dependency graph tuning (V3.3 §5.5; BD-108).` | `# Cross-entity dependency graph tuning (BD-108).` |
| Class A #3 | 75 | `# cycle_check_k = 10  # K-hop bound for link-creation cycle check (V3.3 §5.5)` | `# cycle_check_k = 10  # K-hop bound for link-creation cycle check` |

### §2.2 `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (5 Class A leaks)

| Leak | Line | BEFORE | AFTER |
|---|---|---|---|
| #1 | 19 | `` `pack td <verb>` orchestrates the V3.3 §3 two-path TD promotion + the `` | `` `pack td <verb>` orchestrates the two-path TD promotion + the `` |
| #2 | 27 | `... Path 1 — promote TD to a new phase epic (V3.3 §3.3). PM Chat invokes architect by default per §7.2.` | `... Path 1 — promote TD to a new phase epic. PM Chat invokes architect by default.` |
| #3 | 28 | `... Path 2 — promote TD to a new phase task under phase N (V3.3 §3.4). Wires Dependencies bullets to cross-entity blocked-by edges per §5.1.` | `... Path 2 — promote TD to a new phase task under phase N. Wires Dependencies bullets to cross-entity blocked-by edges.` |
| #4 | 29 | `... Direct close (V3.3 §3.2). No promotion label; no new entity.` | `... Direct close. No promotion label; no new entity.` |
| #5 | 31 | `Path 3 is forbidden per V3.3 §1 supersession + §3 line 27. There is\nno --fold-into flag.` | `Path 3 is forbidden. There is\nno --fold-into flag.` |

### §2.3 `pack-ops/HELP-FRAGMENT-TRACKER.md` (5 identical Class A leaks)

Byte-identical edits applied per inventory §2.3. Same 5 leaks at same lines, same fix shapes. CI Check 24 byte-identity preserved (verified — see §3.2).

### §2.4 `project-template/docs/pack/HELP-FRAGMENT.md` (3 Class A leaks)

| Leak | Line | BEFORE | AFTER |
|---|---|---|---|
| #1 | 19 | `... Promote a TD-NNN to a new phase epic (Path 1; V3.3 §3.1 / §3.3).` | `... Promote a TD-NNN to a new phase epic (Path 1).` |
| #2 | 20 | `... Promote a TD-NNN to a new phase task under phase N (Path 2; V3.3 §3.1 / §3.4).` | `... Promote a TD-NNN to a new phase task under phase N (Path 2).` |
| #3 | 21 | `... Direct-close wrapper (V3.3 §3.2). No promotion label; no new entity.` | `... Direct-close wrapper. No promotion label; no new entity.` |

### §2.5 `project-template/.github/ISSUE_TEMPLATE/inbound.yml` (3 Class A leaks)

| Leak | Line | BEFORE | AFTER |
|---|---|---|---|
| #1 | 2 | `description: ... Pack-feedback categories file upstream against the pack repo per V1 §7.5.` | `description: ... Pack-feedback categories file upstream against the pack repo.` |
| #2 | 14–15 | (block-scalar): `...route upstream to the pack repo per\n        V1 §7.5; the chat at triage time emits the upstream issue automatically.` | `...route upstream to the pack repo;\n        the chat at triage time emits the upstream issue automatically.` |
| #3 | 20 | `description: Select the category that best matches your report. Pack-feedback subcategories file upstream against the pack repo per V1 §7.5.` | `description: Select the category that best matches your report. Pack-feedback subcategories file upstream against the pack repo.` |

YAML indentation preserved in block-scalar at lines 14–15 (8-space indent under `value: |` directive).

### §2.6 `project-template/.github/ISSUE_TEMPLATE/config.yml` (1 Class A leak)

| Leak | Line | BEFORE | AFTER |
|---|---|---|---|
| #1 | 1 | `# GitHub Issues form-family configuration (V2 §4.1).` | `# GitHub Issues form-family configuration.` |

### §2.7 `supporting-docs/METHODOLOGY.md` (1 Class A leak — H.9-NIT-1 gap)

| Leak | Line | BEFORE | AFTER |
|---|---|---|---|
| #1 | 1169 | `     Document-locations resolver (V1 §8.5 / D-6).` | `     Document-locations resolver.` |

5-space indentation preserved (sub-bullet inside a numbered list inside a fenced code block).

### §2.8 pm-startup cluster (8 Class A leaks across 4 files — V1-classification correction)

The 4 cluster files share two identical edit sites in canonical / .claude / .codex Markdown form. The .gemini TOML wraps the body in a triple-quoted string but the prose content is byte-equivalent at those two sites.

**Edit site 1 — Step 2 V1 §8.4 cite:**
| File | Line | BEFORE | AFTER |
|---|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` | 84 | `the trinity ## Document locations table in the project context file (V1 §8.4).` | `the trinity ## Document locations table in the project context file.` |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 84 | (same) | (same) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 84 | (same) | (same) |
| `project-template/.gemini/commands/pm-startup.toml` | 81 | (same prose inside `"""..."""`) | (same prose) |

**Edit site 2 — Step 7-reserved V1 §10.2 cite:**
| File | Line | BEFORE | AFTER |
|---|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` | 211 | `Step 7 is reserved. The V1 §10.2 tracker-mode triage queue` | `Step 7 is reserved. The tracker-mode triage queue` |
| `project-template/.claude/skills/pm-startup/SKILL.md` | 211 | (same) | (same) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | 211 | (same) | (same) |
| `project-template/.gemini/commands/pm-startup.toml` | 208 | (same prose inside `"""..."""`) | (same prose) |

Cluster-sync invariant preserved (verified — see §3.3).

### §2.9 Per-leak grand total

| Class | Sites | File-coverage |
|---|---|---|
| Class A (Cat A drops, bare-version) | 29 | tracker.toml.project-example (3) + HELP-FRAGMENT-TRACKER pair (10) + HELP-FRAGMENT.md (3) + inbound.yml (3) + config.yml (1) + METHODOLOGY.md (1) + pm-startup cluster (8) |
| Class D (Cat A drops, qualified-filename) | 2 | tracker.toml.project-example (2) |
| **Total** | **31** | 11 distinct files |

---

## §3 — Verification

### §3.1 Pack validator

```bash
python3 scripts/validate-pack.py
```

Result: **PASSED — all checks clean** (Check 1 through Check 42 all OK).

Notable passes for this BD:
- Check 24 (byte-identical mirrors): OK — HELP-FRAGMENT-TRACKER pair preserved.
- Check 31 (skill-cell consistency): OK — 36 SKILL.md on disk, all map to inventory cells.
- Check 37 (project-side pack-only deny-list): OK — 146 project-side files walked; zero deny-list contamination.
- Check 38 (pack-only-file siting): OK.
- Check 39 (cmd_update mapping/glob symmetry): OK — 6 project-template/docs/pack/*.md forward-checked + 35 cmd_update entries reverse-checked.
- Check 40 (pack-ops/ bare cross-reference): OK — 9 pack-ops/*.md walked; zero unqualified bare cross-references.

### §3.2 CI Check 24 byte-identity (HELP-FRAGMENT-TRACKER pair)

```bash
diff project-template/docs/pack/HELP-FRAGMENT-TRACKER.md pack-ops/HELP-FRAGMENT-TRACKER.md
```

Result: **(no output) — Check 24: OK**. Pair remains byte-identical after both files received identical edits.

### §3.3 pm-startup cluster sync

```bash
diff project-template/skills/pm-startup/SKILL.md project-template/.claude/skills/pm-startup/SKILL.md
```

Result: **(no output) — Cluster sync .claude: OK**.

```bash
diff project-template/skills/pm-startup/SKILL.md project-template/.codex/skills/pm-startup/SKILL.md
```

Result: **(no output) — Cluster sync .codex: OK**.

The .gemini TOML mirror is byte-equivalent at the two edit sites (prose inside the triple-quoted block); TOML wrapping preserved. Verification grep on the .toml shows no V-version cites remain.

### §3.4 TOML / YAML validity

```bash
python3 -c "import tomllib; tomllib.load(open('project-template/.gemini/commands/pm-startup.toml','rb'))"
```
Result: **pm-startup.toml: PARSES OK**.

```bash
python3 -c "import yaml; yaml.safe_load(open('project-template/.github/ISSUE_TEMPLATE/inbound.yml'))"
python3 -c "import yaml; yaml.safe_load(open('project-template/.github/ISSUE_TEMPLATE/config.yml'))"
```
Result: **inbound.yml: PARSES OK; config.yml: PARSES OK**.

### §3.5 Boundary grep (combined audit-vocabulary)

```bash
grep -rnE "V[0-9]+(\.[0-9]+)? §|ARCHITECTURE-V[0-9.]+|AUDIT-USER-CURATION|AUDIT-PRE-19C|RESEARCH-PER-ENTRY|RESEARCH-TRACKER|RESEARCH-AUDIT|EXTERNAL-RESEARCH|IMPLEMENTATION-PLAN-ADDENDUM|maintenance-docs/" \
   project-template/tracker.toml.project-example \
   project-template/docs/pack/HELP-FRAGMENT-TRACKER.md \
   pack-ops/HELP-FRAGMENT-TRACKER.md \
   project-template/docs/pack/HELP-FRAGMENT.md \
   project-template/.github/ISSUE_TEMPLATE/inbound.yml \
   project-template/.github/ISSUE_TEMPLATE/config.yml \
   supporting-docs/METHODOLOGY.md \
   project-template/skills/pm-startup/SKILL.md \
   project-template/.claude/skills/pm-startup/SKILL.md \
   project-template/.codex/skills/pm-startup/SKILL.md \
   project-template/.gemini/commands/pm-startup.toml
```

Result: **BOUNDARY OK — no audit-vocabulary-gap leaks remain in BD-190 in-scope files**. Zero matches across all 11 in-scope files.

### §3.6 Class D qualified-filename verification

```bash
grep -nE "ARCHITECTURE\.md §" project-template/tracker.toml.project-example
```

Result: **BOUNDARY OK — tracker.toml.project-example clean for ARCHITECTURE.md §X**. Both Class D sites at L11 + L17 cleared.

### §3.7 Fixture rebuild + manifest

```bash
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

Result: fixtures rebuilt deterministically; manifest drifted on the expected v11-* rows only:

```
-v11-realistic-ot  8595cea270e77ee68ec8ce4cf585c9004118d5c6
-v11-flat-file     1968349c22598ce11496b6f49c11e3c94238f7e1
-v11-tracker-on    88e8585d7e03bcd017baa2f8cc03c0f0f21f82db
+v11-realistic-ot  c2d59cd515bcf0b432435b0cf3b5d0dfcfb55a91
+v11-flat-file     cc4668bca45bed6a50ac1d5c7620d62d263beb0e
+v11-tracker-on    d91065a7ef87a587ac9fdd81cb34808dabfd6a08
```

v10-* rows tag-pinned, unchanged. Manifest staged in working tree (NOT committed per coder permission profile).

---

## §4 — Cross-references

- **BD entry:** `pack-ops/BACKLOG.md` BD-190 (Pack Chat updates the entry separately — this coder did NOT modify BACKLOG).
- **Inventory:** `maintenance-docs/v11-implementation/AUDIT-GAP-INVENTORY-BD-190.md` §2 + §12 (authoritative BEFORE/AFTER specs followed verbatim). Immutable snapshot post-mini-inventory; NOT modified by this coder.
- **Trinity Filename uniqueness rule:** pack-repo `CLAUDE.md` § "Filename uniqueness heuristic" (anchor commit `1121b3d`). This Phase 2 implements the rule's audit-vocabulary-gap dimension across pack-shipped files: bare-version `V[N] §X.Y` shorthand and `ARCHITECTURE.md §X.Y` qualified-name + pack-internal-section variants are leaks under the rule's plain reading.
- **H.9 / H.9-NIT-1 history:** H.9 absorbed 11 bare-V3.3 sites in METHODOLOGY.md L312/L1166/L1170/L1176/L1207 + cluster. L1169 (`V1 §8.5 / D-6`) was OUT-OF-SCOPE for H.9-NIT-1's V3.3 sweep — different bare-version class — and is absorbed here.
- **H.10 history (V1-classification correction):** H.10 §2.4.2.a classified pm-startup cluster `V1 §8.4` / `V1 §10.2` cites as LEGITIMATE on grounds "V1 references the project-side context file." Inventory §2 disputes this: (a) project trinity has no numbered `§X.Y` sections; (b) the pack-internal architect doc `maintenance-docs/v11-research/ARCHITECTURE.md` has matching §X.Y sections (§8.4, §10.2); (c) PLATFORM-SKILLS.md has no `V1 §X.Y` reference form. Pack Chat accepted the correction; this Phase 2 sweeps the 8 cluster sites.
- **§7.1 / §12 history (Class D absorption):** Inventory §7.1 originally recommended a NEW BD for the `<client-filename>.md §X.Y` leak class. Pack Chat A2 triage decided to ABSORB the 2 sites into BD-190 without a new BD; mini-inventory §12 implemented the scope expansion. Phase 2 file count stays at 11 (both Class D sites in `tracker.toml.project-example`, already in scope for 3 Class A sites).

---

## §5 — Success criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | All 31 cite-drops applied per inventory §2 + §12 specs | **PASS** (29 Class A + 2 Class D applied verbatim) |
| 2 | CI Check 24 byte-identity preserved | **PASS** (§3.2 diff empty) |
| 3 | Cluster-sync invariant preserved (4 pm-startup files) | **PASS** (§3.3 diffs empty; TOML body byte-equivalent at edit sites) |
| 4 | YAML + TOML validity preserved | **PASS** (§3.4 — tomllib + yaml.safe_load both parse) |
| 5 | `python3 scripts/validate-pack.py` PASS | **PASS** (§3.1 — Check 1 through Check 42 all OK) |
| 6 | Boundary grep returns "BOUNDARY OK" on all 11 in-scope files | **PASS** (§3.5) |
| 7 | Manifest v11-* row drift (regenerated) | **PASS** (§3.7 — 3 v11-* rows updated; v10-* unchanged; left in working tree as instructed) |
| 8 | IMPL-REPORT at canonical path | **PASS** (this file) |

---

## §6 — Out-of-scope confirmations

The following sites/files were considered and explicitly NOT touched per inventory + Pack Chat triage:

- **pack-ops/BACKLOG.md** — NOT modified. Pack Chat updates BD-190 entry separately.
- **AUDIT-GAP-INVENTORY-BD-190.md** — NOT modified. Immutable snapshot post-mini-inventory.
- **H.13-deferred fence-marker files** (7 files: `scripts/validate-pack.py`, `project-template/skills/boundary-investigation/SKILL.md`, `project-template/docs/pack/prompts/coder.md`, `project-template/docs/pack/prompts/reviewer.md`, `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `project-template/docs/pack/PM-CHAT.md`) — pedagogical content; will be wrapped with fence markers in H.13. Not in BD-190 scope.
- **Class C-pedagogical boundary-investigation sites** at L19 + L27 of `boundary-investigation/SKILL.md` — outside H.13 fence scope but legitimate per skill's pedagogical purpose (define the boundary by enumerating pack-only paths). Not in BD-190 scope.
- **Class C-client-side IMPLEMENTATION-PLAN.md references** (68 matches across 18 files) — bare filename refs that resolve at client install. Not leaks; not in BD-190 scope.
- **Class E legitimate qualified-filename references** (12 matches: METHODOLOGY.md `§ RAG index hygiene` / `§ Format-vs-solutions` ; INSTALL-PROCEDURES.md `§ 7.5` / `§ 7.2.3` / `§ 7.3.1/7.3.2` / `§ Project file conventions...` ; PM-CHAT.md `§ Behavioral rules`) — file + section both exist at client install. Not in BD-190 scope.
- **H.11 scope** — `project-template/docs/pack/prompts/pm-chat.md` supporting-docs cites (different leak class). H.11 absorbs separately.
- **scripts/ tree** (except `scripts/lib/detect.sh:22` already absorbed by H.10 19th-leak pass) — BD-190 BACKLOG entry excludes scripts beyond detect.sh.

No edits were made outside the 11 in-scope files + `test-fixtures/manifest.txt` (regenerated by `build.sh`) + this IMPL-REPORT.

---

## §7 — Open questions / deferrals

None.

The mini-inventory `§12.9` explicitly noted: "Phase 2 coder spawn is unblocked when Pack Chat resolves §6.4 (accept or reject V1-classification correction); §12 adds 2 cite-drops to that work without any cross-cutting design implication." Pack Chat accepted both decisions before this coder spawn; this Phase 2 executed the resulting 31-leak scope without any new architectural questions surfacing.

No deferrals introduced. No new POQs (per inventory §7.3, "this inventory pass did NOT discover new architectural questions or design gaps beyond the V1-classification correction").

---

## §8 — Files changed inventory

| Path | Change type | Lines touched |
|---|---|---|
| `project-template/tracker.toml.project-example` | modified | 5 |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | modified | 6 (1 leak spans 2 lines at L31) |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | modified | 6 (byte-identical to above) |
| `project-template/docs/pack/HELP-FRAGMENT.md` | modified | 3 |
| `project-template/.github/ISSUE_TEMPLATE/inbound.yml` | modified | 4 (1 leak spans 2 lines in block-scalar) |
| `project-template/.github/ISSUE_TEMPLATE/config.yml` | modified | 1 |
| `supporting-docs/METHODOLOGY.md` | modified | 1 |
| `project-template/skills/pm-startup/SKILL.md` | modified | 2 |
| `project-template/.claude/skills/pm-startup/SKILL.md` | modified | 2 |
| `project-template/.codex/skills/pm-startup/SKILL.md` | modified | 2 |
| `project-template/.gemini/commands/pm-startup.toml` | modified | 2 |
| `test-fixtures/manifest.txt` | modified (regenerated by `build.sh --all --clean`) | 3 (v11-* rows) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-190.md` | new (this file) | — |

**Total: 12 files modified + 1 new (IMPL-REPORT). Zero out-of-scope edits.**

---

## §9 — Boundary discipline check (P-missed-7)

Edits touched both pack-side (`pack-ops/HELP-FRAGMENT-TRACKER.md`) and project-side (`project-template/`, `supporting-docs/METHODOLOGY.md`) surfaces. Per the pre-flight requirement:

- **Project-side SSOT investigation**: The audit-vocabulary-gap leak class is governed by the trinity Filename uniqueness rule documented in `CLAUDE.md` at pack root (commit `1121b3d`). The rule's application to project-side files (drop the bare-version cite where the surrounding wording stands) does NOT have a separate project-side SSOT — the rule is universal across pack-internal references in both pack-shipped and pack-internal files. No project-side SSOT augmentation is implicated.
- **No pack-only-target references introduced**: Verified by `grep -nE "pack-ops/|maintenance-docs/|PACK-AGENTS|PACK-CHAT.md|pack-\*"` post-edit on the 4 project-side touched files (METHODOLOGY.md, HELP-FRAGMENT*.md, pm-startup cluster, ISSUE_TEMPLATE/*.yml, HELP-FRAGMENT.md, tracker.toml.project-example). All edits were DROPS of pack-internal cites; no pack-only references added. Check 37 (project-side deny-list) passed in §3.1.
- **Frame rotation**: pack-side `pack-ops/HELP-FRAGMENT-TRACKER.md` carries the same drops as project-side `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per CI Check 24 byte-identity requirement. The "same edit on both surfaces" is the byte-identity invariant, NOT a P-missed-7 violation; both files cite the same pack-internal `V3.3 §3.X` content and both should drop the citation.

No boundary discipline stop triggered.

---

## §10 — PREFLIGHT trace

After all 31 edits + verification + IMPL-REPORT write, emitting PREFLIGHT line to parent session per system prompt.

---

(End of report.)
