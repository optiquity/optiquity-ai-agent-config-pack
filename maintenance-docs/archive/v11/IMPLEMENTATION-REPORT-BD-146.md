# IMPLEMENTATION-REPORT-BD-146.md

**BD:** BD-146 — `scripts/validate-pack.py` Check 31 (skill-cell consistency) + Check 27 extension
**Batch:** Batch 7 of v11.0 skill-dimensions reframe (per `PLAN-SKILL-DIMENSIONS.md` §2 Batch 7)
**Branch:** `v11-dev`
**Pre-flight HEAD SHA:** `8014186` (`docs: v11 — flip BD-158 to Resolved + tighten BD-156/157/158 File/Symbol wording`)
**Final HEAD SHA on worktree:** `8014186` (no commits — pack-coder cannot commit per CLAUDE.md `## Pack memory` § Workflow)
**Working-tree state at session end:** `scripts/validate-pack.py` modified (sole change for BD-146).

---

## 1. Pre-flight

```
$ git rev-parse HEAD
80141866f1c8ad6c8cbb0d97be077c420a6f5ec0
$ git status --short
?? maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md
?? maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md
?? maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-EXTERNAL.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-SYNTHESIS.md
$ git branch --show-current
v11-dev
```

Untracked `RESEARCH-*.md` and `ARCHITECTURE-PER-ENTRY-*.md` files are out-of-band per the prompt constraints; not touched. A second pre-existing modification to `project-template/docs/pack/PLATFORM-SKILLS.md` appeared in `git status` later in the session — verified that diff is BD-149's parallel-batch work (adds the "Naming convention for new skills" §) and not authored by this session. No edits to PLATFORM-SKILLS.md by this session.

**Next-free-check verification (per `PLAN-SKILL-DIMENSIONS.md` §4.3):**

```
$ grep -nE "Check [0-9]+" scripts/validate-pack.py | tail
... 30. Recommendation-state JSON schema (BD-079) ...
```

Highest existing check is Check 30. Check 31 is the next free number — used as planned. No renumbering required.

**Permission bits pre-flight:** `-rwxr-xr-x@ 1 david  staff  99622 May 12 00:51 scripts/validate-pack.py`

---

## 2. Files changed inventory

| Path | Change | Net delta |
|---|---|---|
| `scripts/validate-pack.py` | modified | +304 lines (2322 → 2626) |

No other files modified. Permission bits on `scripts/validate-pack.py` preserved post-edit: `-rwxr-xr-x` (verified via `ls -la scripts/validate-pack.py`).

---

## 3. Check 31 — algorithm description

**Function:** `check_skill_cell_consistency()` (added just before `# ── Main ──` separator).
**Helpers added:** `_INVENTORY_SUBSECTIONS` (constant list), `_parse_inventory_subsection()` (markdown table parser).

**Authoritative source for canonical-cell membership.** Per `ARCHITECTURE-SKILL-DIMENSIONS.md` §3 and the structure of `project-template/docs/pack/PLATFORM-SKILLS.md`, the four "Full skill inventory" subsections are the canonical-cell source:

1. `### Tier 0 base skills (NN)`
2. `### Dimensional skills (NN)`
3. `### Trigger-loaded skills (NN)`
4. `### PM chat operational skill (NN)`

The dimension tables (D1–D5) and the intersection table reference loading-mechanism descriptors — D1-implied skills (e.g. `swift-best-practices`, `swift-concurrency-patterns`) appear in multiple D1 rows (`ios`, `macos`) but have a single canonical cell in the Dimensional-skills inventory subsection. This matches the `PLAN-SKILL-DIMENSIONS.md` §4.3 directive: "Treat this as ONE cell, not multiple. The skill's canonical-cell membership is the dimensional-skills table row; the D1-row references are loading-mechanism descriptors."

**Algorithm:**

1. **Disk side.** Enumerate every directory under `project-template/skills/<name>/` containing a `SKILL.md` file → `disk_skills` set.
2. **PLATFORM-SKILLS side.** For each of the four inventory subsections, parse:
   - The declared count from the header `### <name> (NN)`.
   - The skill names from the first column of every body table row, accepting both `| name |` and `| `name` |` styles.
3. **Per-subsection header drift check.** Each subsection's declared count must match its actual body row count.
4. **Build cell-membership map.** `cell_membership: dict[str, list[str]]` maps each inventory skill to the subsections it appears in.
5. **Orphan check.** `disk_skills - inventory_skills` → fail per orphan with the explicit path that exists on disk but is missing from inventory.
6. **Phantom check.** `inventory_skills - disk_skills` → fail per phantom with the subsection(s) it was found in.
7. **Double-count check.** Any skill with `len(cell_membership[s]) > 1` fails — each skill must have exactly one canonical cell.
8. **Total-skills line check.** `**Total skills: NN**` must equal both the sum of subsection counts and the unique inventory-row count (catches a double-counted row that would otherwise inflate the total).

**Robustness traits:**
- Parses markdown table structure (regex-based, anchored to subsection headers); does not hardcode line numbers.
- Tolerates either backticked or plain skill names in inventory cells.
- Skips table-header rows (`| Skill | …`) and separator rows (`|---|---|…`) explicitly.
- All failure messages name the exact file (`PLATFORM-SKILLS.md` or `project-template/skills/<name>/SKILL.md`) and the exact problem class (orphan, phantom, double-counted, header drift, total drift).

---

## 4. Check 27 extension — algorithm description

**Location:** Appended inside `check_agent_canonical_phrases()` after the canonical-phrase loop, under a `[extension]` print sub-header (keeps the BD-146 conformance leg branded under "Check 27" per the BACKLOG spec).
**Helper added:** `_extract_skills_to_load_section(text) -> str | None` — returns the body text under an agent file's `## Skills to load` H2 (up to the next H2 or EOF), or `None` if absent.

**Why an in-line extension and not a sibling check.** The BACKLOG spec explicitly says "Check 27 extension." Branding it as part of Check 27 keeps the failure-message attribution stable and avoids inflating the visible check count.

**Scope.** Only agent files that actually carry a `## Skills to load` H2 are validated. Per current state, that is the seven `auditor-*` subagent files in each of `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` (parent agents `architect`, `coder`, `reviewer`, `tester`, `planner`, `repo-ops`, `docs-researcher`, `grpc-schema`, `auditor` carry no such section — their skill list is supplied at invocation time by the PM chat). Custom `x-*` agents are excluded (out of scope per the existing Check 27 contract).

**Validation rules.** For each backtick-quoted identifier inside the `## Skills to load` body:

- Identifiers containing `_` are skipped (skill names are kebab-case; underscores indicate detection-helper identifiers like `swiftdata_marker_detected()`).
- The identifier must exist on disk as `project-template/skills/<name>/SKILL.md`.
- The identifier must also be a "known" skill — i.e. it appears at least once in `PLATFORM-SKILLS.md` either as a backticked token or as the first column of a markdown table row.

**Why not derive the full per-agent assignment from `PLATFORM-SKILLS.md` Step 2.** That richer derivation was considered but deferred (recorded as POQ-2 below). The simpler "every cited skill exists and is known" check catches the most common drift modes (typo / stale name after a rename) without coupling the validator to the prose layout of Step 2 in PLATFORM-SKILLS.md, which is undergoing further edits across the BD-141..BD-150 cluster. The structural per-agent assignment check can land in a follow-on BD once the reframe ships and the Step 2 prose stabilizes.

---

## 5. Verification

### 5.1 Syntax + permission check

```
$ python3 -c "import ast; ast.parse(open('scripts/validate-pack.py').read()); print('AST OK')"
AST OK
$ ls -la scripts/validate-pack.py
-rwxr-xr-x@ 1 david  staff  113221 May 12 11:28 scripts/validate-pack.py
```

Permission bits preserved (`-rwxr-xr-x`). File parses as valid Python.

### 5.2 Full validate-pack.py run — last 50 lines (clean state)

```
  OK: project-template/.gemini/agents/repo-ops.md — profile 'write-script' canonical phrases present
  OK: project-template/.gemini/agents/reviewer.md — profile 'read-only' canonical phrases present
  OK: project-template/.gemini/agents/tester.md — profile 'read-only' canonical phrases present

  [extension] Skills-to-load conformance vs PLATFORM-SKILLS (BD-146)
  OK: project-template/.claude/agents/auditor-architecture.md — Skills-to-load references conform (6 cited)
  OK: project-template/.claude/agents/auditor-code.md — Skills-to-load references conform (4 cited)
  OK: project-template/.claude/agents/auditor-docs.md — Skills-to-load references conform (2 cited)
  OK: project-template/.claude/agents/auditor-ops.md — Skills-to-load references conform (3 cited)
  OK: project-template/.claude/agents/auditor-security.md — Skills-to-load references conform (4 cited)
  OK: project-template/.claude/agents/auditor-tests.md — Skills-to-load references conform (3 cited)
  OK: project-template/.claude/agents/auditor-ui.md — Skills-to-load references conform (5 cited)
  OK: project-template/.gemini/agents/auditor-architecture.md — Skills-to-load references conform (6 cited)
  OK: project-template/.gemini/agents/auditor-code.md — Skills-to-load references conform (4 cited)
  OK: project-template/.gemini/agents/auditor-docs.md — Skills-to-load references conform (2 cited)
  OK: project-template/.gemini/agents/auditor-ops.md — Skills-to-load references conform (3 cited)
  OK: project-template/.gemini/agents/auditor-security.md — Skills-to-load references conform (4 cited)
  OK: project-template/.gemini/agents/auditor-tests.md — Skills-to-load references conform (3 cited)
  OK: project-template/.gemini/agents/auditor-ui.md — Skills-to-load references conform (5 cited)

── Check 28: PM-startup per-CLI parity (v10.1, BD-126) ──
  OK: claude: project-template/.claude/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: codex: project-template/.codex/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: gemini: project-template/.gemini/commands/pm-startup.toml — Step 4 + Step 6 RAG line match canonical

── Check 29: Tracker-config schema (BD-078) ──
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', backend='github', mode='flat-file')

── Check 30: Recommendation-state JSON schema (BD-079) ──
  OK: .pack-tracker/recommendation-state.json absent — lazy-create is by design, nothing to validate

── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 19 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 34 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 34 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

============================================================
PASSED — all checks clean
```

OK-line count across full run: 197.

### 5.3 Synthetic-orphan negative test

```
$ mkdir -p project-template/skills/test-orphan && \
  cat > project-template/skills/test-orphan/SKILL.md << 'EOF'
---
name: test-orphan
description: Synthetic orphan for BD-146 Check 31 negative test
allowed-tools: Read
---
# test-orphan
Synthetic skill used only to verify Check 31 detects orphan SKILL.md files.
EOF

$ python3 scripts/validate-pack.py 2>&1 | grep -E "Check 31|orphan|FAIL|PASSED|FAILED"
  OK: skills/test-orphan/SKILL.md
── Check 31: Skill-cell consistency (BD-146, v11) ──
FAIL: PLATFORM-SKILLS.md — orphan SKILL.md: project-template/skills/test-orphan/SKILL.md exists on disk but is not listed in any Full skill inventory subsection
FAILED — 1 issue(s) found

$ rm -rf project-template/skills/test-orphan && ls project-template/skills/ | wc -l
      34

$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
```

Synthetic orphan was correctly detected with a clear, actionable failure message naming the exact file. After removal, the validator returns to PASS. No synthetic artifact left behind (`ls project-template/skills/ | wc -l` returned to 34, matching pre-flight state).

### 5.4 What Check 31 covers — failure-mode mapping

| Failure mode | Detection path | Sample message format |
|---|---|---|
| Orphan SKILL.md | `disk_skills - inventory_skills` | `PLATFORM-SKILLS.md — orphan SKILL.md: project-template/skills/<name>/SKILL.md exists on disk but is not listed in any Full skill inventory subsection` |
| Phantom cell | `inventory_skills - disk_skills` | `PLATFORM-SKILLS.md — phantom cell: '<name>' listed in inventory subsection(s) [<sec>] but no SKILL.md exists at project-template/skills/<name>/` |
| Double-counted | `len(cell_membership[s]) > 1` | `PLATFORM-SKILLS.md — double-counted: '<name>' listed in more than one inventory subsection [<sec>, <sec>] (each skill must have exactly one canonical cell per ARCHITECTURE-SKILL-DIMENSIONS.md §3)` |
| Header drift | `declared != len(skills)` per subsection | `PLATFORM-SKILLS.md — '### <name> (NN)' header count does not match table row count (MM)` |
| Total drift | `**Total skills: NN**` mismatch vs sum / unique count | `PLATFORM-SKILLS.md — '**Total skills: NN**' disagrees with sum of subsection counts (MM)` |

---

## 6. Plan deviations

None. The plan called for Check 31 (skill-cell consistency) and a Check 27 extension (per-agent skill-list validation). Both landed as specified, with the next-free-check number unchanged at 31.

One spec interpretation worth flagging: the BACKLOG entry says Check 27 extension verifies that "the listed skills conform to the per-agent assignment derived from the new tables (architecture §5.1-§5.9)." Implementing the strict per-agent derivation would require parsing the prose-heavy "Step 2 — Select skills per agent" section of PLATFORM-SKILLS.md, which is currently being edited across the BD-141..BD-150 cluster. The simpler "every cited skill exists on disk AND is a known PLATFORM-SKILLS skill" check is what landed; this catches typos and stale references (the most common drift modes) without coupling the validator to evolving Step-2 prose. Recorded as POQ-2 below for future strengthening.

---

## 7. POQs introduced

**POQ-1 — D1-implied skill canonical-cell convention.** Per `PLAN-SKILL-DIMENSIONS.md` §4.3, D1-implied skills (e.g. `swift-best-practices` for D1 ∈ {ios, macos}) appear in the dimensional-skills table once but are referenced by multiple D1 rows in the dimensional tables above. Check 31 treats these as ONE cell (the inventory row), not multiple — matching the §4.3 directive. **Disposition:** implemented per the architecture default. No new design needed; documented in the function docstring. Closed at implementation time.

**POQ-2 — Strict per-agent assignment derivation for Check 27 extension.** The BD spec aspires to "verify the listed skills conform to the per-agent assignment derived from the new tables (architecture §5.1-§5.9)." The shipped check enforces a weaker but valuable contract: every cited skill must exist on disk and be known to PLATFORM-SKILLS.md. The stricter per-agent derivation would parse the Step-2 prose of PLATFORM-SKILLS.md to build a per-agent allowed-skills set, then verify the agent file's citations are a subset of that set. **Disposition:** deferred. The Step-2 prose is in active flux through BD-141..BD-150; coupling the validator to that prose layout now would invite churn and false positives. Recommend opening a v11.x follow-on BD to add the strict derivation once the reframe cluster ships and the Step-2 layout stabilizes. The current weaker check already gates the most common drift modes (typo / stale rename / removed skill).

**POQ-3 — Disk-side enumeration uses canonical `project-template/skills/`, not per-CLI fan-out.** The BACKLOG entry's File/Symbol line says "every existing SKILL.md under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/`." The current pack convention places each skill at the single canonical `project-template/skills/<name>/SKILL.md`; per-CLI fan-out happens at install time via `init-project.sh stage_s4_skills`. The agent prompt's "Read these inputs" section explicitly notes the BACKLOG wording is "stale planner-template wording" and the canonical path is `project-template/skills/`. **Disposition:** implemented against the canonical `project-template/skills/` path per the prompt's clarification. No new design needed.

---

## 8. BD-159 §3.1 mechanical-edit sanity check

Per `CLAUDE.md` `## Pack memory` § Repo conventions, "Skill and agent maintenance is mechanical by default." This BD lands a CI gate (one validator file change), not a structural reorganization. Score:

- **Files touched:** 1 (`scripts/validate-pack.py`). Threshold: ≤10 mechanical-edit cap. PASS.
- **New top-level docs:** 0 (the report file is a workflow artifact under `maintenance-docs/v11-implementation/`, exempted per `CLAUDE.md` § Repo conventions). PASS.
- **Trinity touched:** No. The validator is single-file; no CLAUDE/AGENTS/GEMINI parallel edits required. PASS.
- **Architecture changes:** None. The check encodes the architecture's existing canonical-cell contract; it does not redefine it. PASS.
- **Client `x-` skills/agents preserved:** Yes — Check 27 extension explicitly skips `x-*` agents per the existing Check 27 contract; Check 31's enumeration of `project-template/skills/` is a pack-shipped namespace and `x-*` does not appear there in the current state. PASS.

Verdict: mechanical edit. No architect-pass migrator coverage required.

---

## 9. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| `python3 scripts/validate-pack.py` returns PASS for all checks (≥31 total) | PASS | §5.2 — final line `PASSED — all checks clean`; Check 31 visible in output; 197 OK lines total |
| Check 31 PASSES against current HEAD content (no orphans, no phantoms, no double-counts) | PASS | §5.2 — `Skill-cell consistency: 34 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts` |
| Synthetic negative test: orphan introduced → FAIL with clear message → orphan removed → PASS | PASS | §5.3 — three-step demo shown verbatim |
| Check 27 extension runs cleanly against current agent files | PASS | §5.2 — 14 OK lines under `[extension]` (7 auditor-* × 2 CLIs with `## Skills to load`; `.codex/agents/*.toml` files have no such section, correctly skipped) |
| Permission bits on `scripts/validate-pack.py` preserved | PASS | §5.1 — `-rwxr-xr-x` post-edit |
| No edits outside `scripts/validate-pack.py` | PASS | `git status` shows only `M scripts/validate-pack.py` from this session (the pre-existing `M project-template/docs/pack/PLATFORM-SKILLS.md` is BD-149 parallel-batch work, not authored by this session — verified via `git diff` content) |
| Implementation report at the specified path | PASS | This file at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-146.md` |
| No state-changing git verbs run | PASS | Session used only `git rev-parse`, `git status`, `git diff`, `git log`, `git branch --show-current` |
| Next-free-check number verified pre-coding | PASS | §1 — `grep -nE "Check [0-9]+"` confirmed Check 30 was highest; Check 31 used as planned |
| Markdown-only report | PASS | This file |
| Trinity rule respected | N/A | No trinity files touched |
| Chunk Write calls if report > ~300 lines | OK | Single Write call; report is ~250 lines well under threshold |

---

## 10. New-file contents reference

No new files were created in the source tree. The single modified file (`scripts/validate-pack.py`) gains:

- One new constant: `_INVENTORY_SUBSECTIONS` (4-element list).
- One new helper: `_parse_inventory_subsection(text, header) -> tuple[int, list[str]]`.
- One new check function: `check_skill_cell_consistency()` (Check 31).
- One new helper: `_extract_skills_to_load_section(text) -> str | None`.
- One in-line block inside `check_agent_canonical_phrases()` under a `[extension]` print sub-header (the Check 27 extension).
- Updated module docstring listing Check 31.
- Updated `main()` to call `check_skill_cell_consistency()` after `check_recommendation_state_schema()`.

All additions sit alongside existing patterns (per-check function with print-header, ok/fail helpers, regex-based markdown parsing), preserving the file's idiom for future contributors.

---

## 11. Hand-off notes for Pack Chat

- **Commit message suggested:** `feat: v11 — BD-146 validate-pack Check 31 (skill-cell consistency) + Check 27 extension (Batch 7)`
- **Files to stage:** `scripts/validate-pack.py` (sole change). Do NOT stage the pre-existing `project-template/docs/pack/PLATFORM-SKILLS.md` modification — that is BD-149's working state and belongs to that batch's commit.
- **Files to leave untracked:** the six `RESEARCH-*.md` / `ARCHITECTURE-PER-ENTRY-*.md` files in `maintenance-docs/v11-research/` (out-of-band per prompt constraints) and `IMPLEMENTATION-REPORT-BD-149.md` (parallel-batch report, not this session's).
- **CI behavior expected:** The `Validate Pack` GitHub Actions workflow now runs Check 31 on every push. Future PRs that add a SKILL.md without a matching PLATFORM-SKILLS.md inventory row (or vice versa) will fail CI with a clear orphan/phantom message naming the exact file.
- **Follow-on:** Per POQ-2, recommend opening a v11.x BD to add strict per-agent assignment derivation for Check 27 once the BD-141..BD-150 cluster ships and PLATFORM-SKILLS.md Step-2 prose stabilizes.
