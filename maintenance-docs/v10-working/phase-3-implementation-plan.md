# Phase 3 — v10.0 Implementation Plan

**Status:** DRAFT — PENDING REVIEW (Phase 3 output).
**Primary input:** `maintenance-docs/V10-DESIGN.md` (APPROVED, 3,423 lines).
**Secondary inputs:** `CLAUDE.md`, `PACK-AGENTS.md`, `README.md`,
`BACKLOG.md`, `scripts/validate-pack.py`.
**Consumer:** Phase 4 pack chat. This document + V10-DESIGN.md are the
sole references needed to execute v10.0.

---

## 1. Goal and BD items addressed

Implement v10.0 of the AI Agent Config Pack on a `v10-dev` branch,
commit-by-commit, with approval gates, inline verification, and a clean
CI state at every intermediate step. Ship v10.0 to `main` with tags
`v10.0` and floating `v10`.

BD items in scope (all three currently **Unblocked** in BACKLOG.md):

- **BD-045** — Champion the capabilities design pattern alongside LSP
  in architecture guidance. First in implementation order (least
  structural risk, purely additive).
- **BD-046** — v10: Custom agent/skill support, prompt template
  reorganization, migration from v9.3. Most structural. Internal order:
  prompt reorg → custom-agent mechanism → migration.
- **BD-044** — Project setup paths: init-project.sh, QUICKSTART router,
  existing-project onboarding. Last (depends on final v10 file
  structure).

Sequencing authority: V10-DESIGN Part 12 §12.1 (`BD-045 → BD-046 → BD-044`).

---

## 2. Key principles applied throughout this plan

1. **Incremental testability.** `validate-pack.py` passes after every
   commit. Each commit leaves the pack in a working state.
2. **Trinity rule (CLAUDE.md × AGENTS.md × GEMINI.md).** Every trinity
   edit is a single atomic commit touching all three files. Rows 1/2/3,
   26/27/28, 39/40/41 (Part 8 §8.2) collapse into exactly **two**
   trinity commits (one BD-045, one BD-046). Rows 7/8/9 (auditor-
   architecture) collapse into one commit with Codex formatting
   deviation per Part 3 §3.7.
3. **`x-` prefix invariant.** The pack ships zero `x-` files. Every
   commit is verified against this before push (`ls project-template/
   .claude/agents/ | grep '^x-'` must be empty).
4. **Validator-before-content or content-before-validator.** Each new
   check in `validate-pack.py` lands in the commit that includes its
   target content — never before (check would fail on missing files),
   never after content has shipped unvalidated (check drift). Exact
   sequencing in §7.
5. **Blast-radius wider than change set.** After every batch, the
   relevant Part 8 §8.6 grep sweeps run. Zero-match expectations are
   in §6.
6. **No commit or push without explicit user approval** (CLAUDE.md).
   Approval gates in §5 enumerate every stop point.
7. **Historical records are annotated, not mutated** (V9 Lesson 4,
   V9 Lesson 5). V9-DESIGN.md, V9-AUDIT-REPORT.md, V10-PREDESIGN.md
   receive supersession banners only.

---

## 3. Affected files — complete inventory

Sourced from V10-DESIGN Part 8 §8.2 (77 rows). Every row appears in a
commit below. Cross-reference rows (from Part 8 §8.4 "Combine with…")
are consolidated.

### 3.1 Pack-repository files (v10.0 edits)

| Category | Files | Part 8 rows |
|---|---|---|
| Trinity (project-template/CLAUDE.md, AGENTS.md, GEMINI.md) | 3 files, 2 commits each (BD-045, BD-046) | 1–3, 26–28, 39–41 |
| Skills with renumbered rules | `skills/apple-architecture-core/SKILL.md`, `skills/python-best-practices/SKILL.md`, `skills/architecture-review/SKILL.md` | 4, 5, 6 |
| Auditor-architecture trio | `.claude/agents/auditor-architecture.md`, `.codex/agents/auditor-architecture.toml`, `.gemini/agents/auditor-architecture.md` | 7, 8, 9 |
| audit-methodology back-reference (conditional) | `skills/audit-methodology/SKILL.md` rule 15 | Part 3 §3.10, §8.2.1 back-reference note |
| Prompts directory + 10 per-agent files + authoring guide | `docs/pack/prompts/{coder,reviewer,tester,planner,docs-researcher,architect,grpc-schema,repo-ops,auditor,pm-chat}.md`, `PROMPT-AUTHORING.md` | 11–22 |
| Stale-reference sweep (pack template) | `docs/pack/PM-CHAT.md`, `skills/pm-startup/SKILL.md`, `project-template/README.md`, `project-template/CLAUDE.md`/`AGENTS.md`/`GEMINI.md` | 24, 25, 26–28, 29 |
| PROMPT-TEMPLATES.md deletion | `supporting-docs/PROMPT-TEMPLATES.md` | 23 |
| Supporting-docs sweep | `supporting-docs/METHODOLOGY.md`, `CLI-PM-SETUP.md`, `SETUP_TEMPLATE.md`, `DEPENDENCIES.md`, `MIGRATION-v8-to-v9.md` | 30, 32, 33, 34, 35 |
| Maintenance-docs annotation | `V9-DESIGN.md`, `V9-AUDIT-REPORT.md` | 36, 37 |
| Custom agent sections | `docs/pack/PM-CHAT.md` (combined with row 24), `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `### Custom agents` (combined with rows 26–28), `docs/pack/PLATFORM-SKILLS.md` `## Custom agents` + `## Custom skills` | 38, 39–41, 42 |
| METHODOLOGY.md additions | Procedure 5, Procedure 5-R, PROMPT-TEMPLATES.md sweep (one commit) | 30 + 43 + 48 |
| Migration tooling | `scripts/migrate-v9-to-v10.sh`, `scripts/merge-platform-skills.py`, `scripts/merge-trinity.py`, `supporting-docs/MIGRATION-v9-to-v10.md` | 44–47 |
| Init tooling | `scripts/init-project.sh`, `scripts/lib/` dir, `scripts/lib/detect.sh`, `supporting-docs/SETUP-NEW.md`, `supporting-docs/SETUP-EXISTING.md`, `QUICKSTART.md`, top-level `README.md` Repository Layout | 49–55 |
| validate-pack.py | Checks 6, 7, 8, 9; Check 1/5 parity re-verify | 56–60 |
| CI workflow | `.github/workflows/validate-pack.yml` (re-verify only; no change unless checks are invoked separately) | 61 |
| Version bookkeeping | `maintenance-docs/V10-DESIGN.md` (already APPROVED), `V10-PREDESIGN.md` banner, `BACKLOG.md`, top-level `README.md` version table, `CHANGELOG.md` | 62–66 |

### 3.2 Runtime-produced files (NOT pack-repo commits)

Part 8 §8.3 rows 67–77 are produced by `init-project.sh`,
`migrate-v9-to-v10.sh`, or the PM chat in downstream projects. They
are not edited in this plan; they are validated by Part 10 tests
V-INIT-VERIFY-*, V-X-PRESERVE-*, V-PM5-*.

### 3.3 Cross-reference file sweep (must be checked in Phase 4 verification)

Every file named by the six grep targets in V10-DESIGN Part 8 §8.6 is
considered in-scope for touch even if not enumerated above. Any match
from a sweep surfaces a new file to add to the next commit.

---

## 4. v10-dev branch and overall phase sequence

### 4.1 Branch creation

Before any commit:

```bash
git checkout main
git pull --ff-only
git checkout -b v10-dev
git push -u origin v10-dev
```

All commits in Phases 1–5 below land on `v10-dev`. Merge to `main`
happens at Phase 5 ship boundary.

### 4.2 Phase map (top level)

| Phase | Scope | Commits | Approval gate at end |
|---|---|---|---|
| **0** | Branch setup | 0 | — (pre-work; user approves branch creation separately) |
| **1** | BD-045 capabilities pattern (all nine pack locations) | 4 | **Gate A** |
| **2a** | BD-046 prompt reorg (new directory, 10 files, PROMPT-AUTHORING, Check 6) | 2 | **Gate B** |
| **2b** | BD-046 custom-agent mechanism + stale-reference sweep + PROMPT-TEMPLATES.md deletion + Checks 7/8 | 10 | **Gate C** |
| **2c** | BD-046 migration (merge helpers, detect.sh, migrate-v9-to-v10.sh, guide) | 5 | **Gate D** |
| **3** | BD-044 init-project.sh + SETUP-NEW + SETUP-EXISTING + QUICKSTART + README layout + Check 9 | 6 | **Gate E** |
| **4** | Full verification pass (Part 10 critical-path tests; deferred-item smoke tests) | 0 (verification only; any fixes → `fix:` commits) | **Gate F** |
| **5** | Ship — CHANGELOG, version table, BACKLOG resolution, merge, tag | 3 commits + merge + tags | **Ship approval** |
| **6** | Post-ship — OT project migration, deferred-item follow-through | per-project | — |

Each phase's commits are defined in §5. Approval gate criteria are in §5.8.


---

## 5. Ordered commit plan

Every commit below lists: (a) commit message, (b) Part 8 rows covered,
(c) V10-DESIGN source sections the implementer reads to produce content,
(d) files touched, (e) dependencies on prior commits, (f) per-commit
verification, (g) approval gate membership.

All commits use the format from CLAUDE.md:
`feat: v10 — BD-NNN short description`
(docs-only or pack-operational commits use `docs: v10 — …`).

### 5.1 Phase 1 — BD-045 capabilities pattern

#### Commit C-045-01 — Trinity capabilities section

- **Message:** `feat: v10 — BD-045 capabilities pattern in trinity files`
- **Part 8 rows:** 1, 2, 3 (TRIO — single commit touching all three)
- **Source sections:** V10-DESIGN Part 3 §3.1, §3.2 (full section content
  and anti-pattern bullet), §3.9 (LSP-vs-capabilities exact wording),
  §3.10 handoff.
- **Files:**
  - `project-template/CLAUDE.md` — add `## Capabilities pattern`
    section after LSP section; append anti-pattern bullet.
  - `project-template/AGENTS.md` — identical change.
  - `project-template/GEMINI.md` — identical change.
- **Dependencies:** none (first v10 commit on v10-dev).
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` passes (Checks 1–5 pass
    unchanged; no new check yet).
  - Trinity-diff spot check: `diff` the three trinity files restricted
    to the new section; body byte-identical (V-BD045-01, V-BD045-02).
  - Grep: `grep -n "## Capabilities pattern" project-template/{CLAUDE,AGENTS,GEMINI}.md`
    returns exactly three matches.
- **Gate:** member of Gate A.

#### Commit C-045-02 — Skills capabilities sections (with renumbering)

- **Message:** `feat: v10 — BD-045 capabilities rules in apple / python / architecture-review skills`
- **Part 8 rows:** 4, 5, 6
- **Source sections:** Part 3 §3.3 (apple, rules 11–14, renumber 11–23 → 15–27),
  §3.4 (python, rules 14–17, renumber 14–32 → 18–36),
  §3.6 (architecture-review, rules 14–17, renumber 14–15 → 18–19).
- **Files:**
  - `project-template/skills/apple-architecture-core/SKILL.md`
  - `project-template/skills/python-best-practices/SKILL.md`
  - `project-template/skills/architecture-review/SKILL.md`
- **Dependencies:** C-045-01 (trinity context now references capabilities pattern).
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` — Check 1 (SKILL.md frontmatter)
    still passes on all three files (V-CI-08).
  - **Renumbering sweep** (Part 8 §8.6 last block):
    ```bash
    grep -rnE "rule [1-9][0-9]" \
        project-template/skills/apple-architecture-core/ \
        project-template/skills/python-best-practices/ \
        project-template/skills/architecture-review/ \
        project-template/ supporting-docs/ maintenance-docs/
    ```
    Every rule reference must point at intended content post-renumber
    (V-BD045-07). Any match referring to an old rule number is a
    regression to fix before moving on.
- **Gate:** member of Gate A.

#### Commit C-045-03 — Auditor-architecture trio

- **Message:** `feat: v10 — BD-045 capabilities scope in auditor-architecture (trio)`
- **Part 8 rows:** 7, 8, 9 (TRIO with Codex formatting deviation per §3.7)
- **Source sections:** Part 3 §3.7.
- **Files:**
  - `project-template/.claude/agents/auditor-architecture.md` — markdown bullet.
  - `project-template/.codex/agents/auditor-architecture.toml` — plain
    bullet inside `developer_instructions = """…"""`.
  - `project-template/.gemini/agents/auditor-architecture.md` — markdown bullet.
- **Dependencies:** C-045-02 (skills exist for authority reference).
- **Verification after commit:**
  - `validate-pack.py` — Check 2 (TOML parse) passes on updated
    `.codex/agents/auditor-architecture.toml` (V-CI-09).
  - Check 5 (agent-count parity) unchanged (V-CI-10).
  - Trinity-style diff: Claude vs Gemini auditor files byte-identical
    in the new bullet (V-BD045-05); Codex plain-bullet semantically
    identical.
- **Gate:** member of Gate A.

#### Commit C-045-04 — audit-methodology rule 15 back-reference (conditional)

- **Message:** `feat: v10 — BD-045 capabilities in audit-methodology rule 15` (if needed)
  or skipped entirely (if determined not needed).
- **Part 8 rows:** surfaces the back-reference handoff from V10-DESIGN
  Part 3 §3.10 and Part 13 §13.4.
- **Action:**
  1. Read `project-template/skills/audit-methodology/SKILL.md` rule 15
     verbatim.
  2. Decide: does rule 15 require a "capabilities pattern" extension to
     match the new auditor-architecture scope bullet? Per Part 13 §13.4:
     "Whether rule 15 in audit-methodology/SKILL.md needs a matching
     'capabilities' extension is a Phase 3 surfacing item."
  3. If YES → edit; single-file commit `feat: v10 — BD-045 audit-methodology rule 15 capabilities extension`.
     If NO → document the decision in the phase-3 review log (§10);
     no commit.
- **Dependencies:** C-045-03 (auditor bullet text is the authority
  reference point).
- **Verification:** if edit made, `validate-pack.py` Check 1 on the
  modified SKILL.md. Either way, add an explicit "decision" line to
  the phase-4 verification report.
- **Gate:** member of Gate A.

#### Gate A — End of BD-045

**Entry criteria:** commits C-045-01…04 complete; `validate-pack.py`
passes; renumbering sweep zero stale matches.

**Manual checks the developer runs before approving:**

1. Visual trinity diff across the three files (`diff project-template/CLAUDE.md project-template/AGENTS.md` — expect only file-header differences; Capabilities section byte-identical).
2. Run each CP test from Part 10 §10.12 V-BD045-01..07 as a manual check.
3. Read audit-methodology rule 15 decision record.
4. Confirm no trinity-rule violation introduced.

**Approve to proceed to Phase 2a or request changes.**


### 5.2 Phase 2a — BD-046 prompt reorganization

#### Commit C-046-01 — Create prompts directory and 10 per-agent files + PROMPT-AUTHORING.md

- **Message:** `feat: v10 — BD-046 per-agent prompt files under docs/pack/prompts/`
- **Part 8 rows:** 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22
- **Source sections & inputs:**
  - Part 4 §4.1 (per-template destination map — T1→pm-chat, T2→coder
    standard, T3→reviewer, T4→coder fix-cycle, T4b→architect mid-phase,
    T5→tester, T6→docs-researcher, T7→planner, T8→pm-chat
    backlog-status-update, T9→auditor, T10–12→auditor supersession
    note, T13→pm-chat generate-setup, T14→pm-chat generate-agent-kickoff).
  - Part 4 §4.2 (file list; placeholder rule for architect/grpc-schema/repo-ops).
  - Part 4 §4.3 (PROMPT-AUTHORING.md content spec).
  - Part 4 §4.5 (per-agent file format: YAML frontmatter + `## Variant:` H2).
  - Part 4 §4.6 (agent report file convention — REPORT FILE field,
    read-only vs write-capable framing, chunking instruction).
  - **Existing content source:** `supporting-docs/PROMPT-TEMPLATES.md`
    at its current HEAD on v10-dev. Line ranges per Part 4 §4.1 table.
    Copy-and-split; do not rewrite. Hoist "How to use" +
    per-agent exceptions + self-check into `PROMPT-AUTHORING.md`;
    "Prompt Authoring Principles" already lives in METHODOLOGY.md (do
    not duplicate).
- **Files created (12):**
  - `project-template/docs/pack/prompts/coder.md` (`agent: coder`; variants `standard`, `fix-cycle` from T2+T4)
  - `project-template/docs/pack/prompts/reviewer.md` (`agent: reviewer`; variants `standard` from T3)
  - `project-template/docs/pack/prompts/tester.md` (variants `standard` from T5)
  - `project-template/docs/pack/prompts/planner.md` (variants `standard` from T7)
  - `project-template/docs/pack/prompts/docs-researcher.md` (variants `standard` from T6)
  - `project-template/docs/pack/prompts/architect.md` (variants `mid-phase` from T4b)
  - `project-template/docs/pack/prompts/grpc-schema.md` (placeholder, zero variants)
  - `project-template/docs/pack/prompts/repo-ops.md` (placeholder, zero variants)
  - `project-template/docs/pack/prompts/auditor.md` (variants `standard` from T9; trailing T10–12 supersession note)
  - `project-template/docs/pack/prompts/pm-chat.md` (`agent: pm-chat`; variants `kickoff`, `backlog-status-update`, `generate-setup`, `generate-agent-kickoff` from T1/T8/T13/T14)
  - `project-template/docs/pack/prompts/PROMPT-AUTHORING.md` (§4.3 content: How to use, per-agent exceptions table, self-check rule, pointer to METHODOLOGY.md Prompt Authoring Principles)
- **Dependencies:** Phase 1 complete (trinity has capabilities section;
  prompts may reference it). `PROMPT-TEMPLATES.md` NOT yet deleted
  (deletion in C-046-11).
- **Verification after commit:**
  - **Not yet validated by Check 6** (check lands in C-046-02). Run
    the format check manually: every file starts with `---\n`,
    contains `agent:` and `variants:`, each variant slug has a
    matching `^## Variant: <slug>$` H2 (V-PROMPT-04).
  - Token count sanity: `wc -w` sum across the 10 new files × 1.3 is
    within ±5% of the v9.3 monolith's ~6,482 proxy tokens, accounting
    for hoisted Prompt Authoring Principles (V-PROMPT-01).
  - Content-accounting check: every v9.3 Template 1–14 section is
    present in its mapped file under the mapped variant slug (V-PROMPT-02).
    T1 BD-038 active-skills line present in `pm-chat.md ## Variant: kickoff`;
    T8 STATUS.md phase-title rule present in `## Variant: backlog-status-update`;
    BD-043 Gemini references preserved (V-PROMPT-03).
  - `validate-pack.py` — Check 5 (agent-count parity) unchanged
    (no agent files touched); Check 1 unchanged.
- **Gate:** member of Gate B.

#### Commit C-046-02 — validate-pack.py Check 6 (prompts-directory format)

- **Message:** `feat: v10 — BD-046 validate-pack.py Check 6 prompts-directory format`
- **Part 8 rows:** 56
- **Source sections:** Part 4 §4.5 (format rules); V10-DESIGN §5.11
  bullet 1.
- **Files:**
  - `scripts/validate-pack.py` — add `check_prompts_directory()`:
    - For each `project-template/docs/pack/prompts/*.md` (excluding
      `PROMPT-AUTHORING.md`): parse YAML frontmatter; require `agent`
      and `variants`; reject unknown top-level keys; for each variant
      slug in `variants`, confirm exactly one `^## Variant: <slug>$`
      H2 exists in the body; fail on orphan slug or orphan H2.
    - Check `PROMPT-AUTHORING.md` exists.
    - Stem of each file matches `agent:` value (except `pm-chat.md`
      which uses reserved `agent: pm-chat`).
  - Call `check_prompts_directory()` in `main()`.
- **Dependencies:** C-046-01 (target files must exist before check
  runs — otherwise CI fails).
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` — Check 6 passes on all 10
    files + PROMPT-AUTHORING.md (V-CI-01).
  - Negative test (run locally, do NOT commit): temporarily change
    `agent: reviewer` in `coder.md` — expect failure message naming
    the file (V-CI-02). Revert.
- **Gate:** member of Gate B.

#### Gate B — End of Phase 2a

**Entry criteria:** C-046-01..02 complete; Check 6 passes on all pack
prompts; v9.3 template accounting confirmed.

**Approval check:** Developer spot-reads three variant bodies against
the v9.3 source lines to confirm no content drift.

**Approve to proceed to Phase 2b.**


### 5.3 Phase 2b — BD-046 custom-agent support + stale-reference sweep + PROMPT-TEMPLATES.md deletion

This phase is the largest. PROMPT-TEMPLATES.md is deleted only at the
end, after every reference has been removed and all three new validator
checks (6, 7, 8) are live.

#### Commit C-046-03 — Trinity files: Document-locations + Custom agents sub-section (TRIO)

- **Message:** `feat: v10 — BD-046 trinity docs/pack row and custom agents sub-section`
- **Part 8 rows:** 26, 27, 28 (Document-locations row — replace
  `PROMPT-TEMPLATES.md` literal with `prompts/` directory) + 39, 40, 41
  (`### Custom agents` sub-section at end of Phase routing).
- **Source sections:** Part 4 §4.8 (stale-reference inventory);
  Part 5 §5.6 (trinity routing-table additions — exact sub-section
  markdown in Part 5 §5.6).
- **Files:** three trinity files, one commit, symmetric edits per trinity rule.
- **Dependencies:**
  - Phase 1 (BD-045 capabilities section already present — this commit
    MUST preserve it).
  - C-046-01 (`prompts/` directory exists — the Document-locations row
    now references a real path).
- **Verification after commit:**
  - `validate-pack.py` passes.
  - Trinity diff: three files byte-identical in the two new regions
    (V-BLAST-06 routing-table parity).
  - `grep -n "PROMPT-TEMPLATES" project-template/{CLAUDE,AGENTS,GEMINI}.md`
    returns zero matches in the Document-locations row specifically.
- **Gate:** member of Gate C.

#### Commit C-046-04 — PM-CHAT.md pack roster + custom-agent workflow + file-access + PROMPT-TEMPLATES drop

- **Message:** `feat: v10 — BD-046 PM-CHAT.md pack roster and custom-agent workflow`
- **Part 8 rows:** 24 + 38 (combined per Part 8).
- **Source sections:** Part 5 §5.3 (pack roster section — hardcoded
  list of v10 pack agent stems); Part 5 §5.10 (custom-agent workflow
  summary; file-access table additions — `docs/pack/prompts/<agent>.md`
  row, directory-listing row for seven detection dirs; drop
  PROMPT-TEMPLATES.md row from File-access-strategy; behavioral rule
  that PM chat always includes REPORT FILE per Part 4 §4.6); Part 4 §4.7
  (no PROMPT-TEMPLATES.md in mcp-local-rag recommendation).
- **Files:** `project-template/docs/pack/PM-CHAT.md`.
- **Dependencies:** C-046-01 (prompts directory exists); C-046-03 (trinity Document-locations row now consistent).
- **Verification after commit:**
  - `validate-pack.py` passes.
  - `grep -n "PROMPT-TEMPLATES" project-template/docs/pack/PM-CHAT.md`
    returns zero matches.
  - Roster section is valid markdown (no trailing garbage).
- **Gate:** member of Gate C.

#### Commit C-046-05 — PLATFORM-SKILLS.md Custom agents / Custom skills sections

- **Message:** `feat: v10 — BD-046 PLATFORM-SKILLS.md custom sections`
- **Part 8 rows:** 42.
- **Source sections:** Part 5 §5.2 (full spec including placeholder rows).
- **Files:** `project-template/docs/pack/PLATFORM-SKILLS.md`.
  - Add `## Custom agents` + `## Custom skills` H2 sections
    immediately after `## Full skill inventory`, with placeholder rows
    (project-owned region starts at first of these two headings per
    Part 6 §6.6 splice rule).
- **Dependencies:** C-046-04.
- **Verification after commit:**
  - `validate-pack.py` passes.
  - `grep -n "^## Custom agents$\|^## Custom skills$" project-template/docs/pack/PLATFORM-SKILLS.md`
    returns two matches.
- **Gate:** member of Gate C.

#### Commit C-046-06 — pm-startup skill drops PROMPT-TEMPLATES.md Step 4 RAG entry

- **Message:** `feat: v10 — BD-046 pm-startup skill drops PROMPT-TEMPLATES.md RAG entry`
- **Part 8 rows:** 25.
- **Source sections:** Part 4 §4.7 (pm-startup does not read prompts;
  METHODOLOGY.md retained).
- **Files:** `project-template/skills/pm-startup/SKILL.md`.
- **Dependencies:** C-046-01 (to ensure the prompts directory exists
  and pm-startup is no longer the place that reads templates).
- **Verification after commit:**
  - `validate-pack.py` Check 1 passes on pm-startup.
  - `grep -n "PROMPT-TEMPLATES" project-template/skills/pm-startup/SKILL.md`
    returns zero matches.
  - `grep -n "METHODOLOGY" project-template/skills/pm-startup/SKILL.md`
    still present.
- **Gate:** member of Gate C.

#### Commit C-046-07 — project-template/README.md PROMPT-TEMPLATES sweep

- **Message:** `docs: v10 — BD-046 project-template/README.md PROMPT-TEMPLATES sweep` (or skip if no matches)
- **Part 8 rows:** 29.
- **Source sections:** Part 4 §4.8.
- **Action:**
  1. `grep -n "PROMPT-TEMPLATES" project-template/README.md`.
  2. If matches, remove or replace per §4.8. If zero matches, document
     decision in the phase-3 review log and skip the commit.
- **Dependencies:** none beyond C-046-01.
- **Verification:** sweep returns zero matches after the commit.
- **Gate:** member of Gate C.

#### Commit C-046-08 — METHODOLOGY.md Procedure 5 + Procedure 5-R + PROMPT-TEMPLATES sweep

- **Message:** `feat: v10 — BD-046 METHODOLOGY.md Procedure 5 and 5-R`
- **Part 8 rows:** 30 + 43 + 48 (combined per Part 8 §8.4 and
  V10-DESIGN Part 12 §12.2 cross-BD coordination).
- **Source sections:** Part 5 §5.7 (Procedure 5 outline — sub-procedures
  5.1 custom-agent creation; 5.2 custom-skill creation; 5.3
  unregistered-file registration; 5.4 improperly-added adoption; 5.5
  defer workflow; 5.6 PLATFORM-SKILLS.md row authoring); Part 6 §6.5
  (Procedure 5-R reconciliation, triggered by `_v9-backup.md`); Part 4
  §4.8 (PROMPT-TEMPLATES.md replacement — do NOT modify "Prompt
  Authoring Principles" section which is already the canonical source).
- **Files:** `supporting-docs/METHODOLOGY.md`.
- **Dependencies:** C-046-05 (PLATFORM-SKILLS.md has Custom sections
  for Procedure 5.6 to reference); C-046-04 (PM-CHAT.md custom-agent
  workflow).
- **Verification after commit:**
  - `grep -n "PROMPT-TEMPLATES" supporting-docs/METHODOLOGY.md` zero matches.
  - `grep -n "^### Procedure 5\|^### Procedure 5-R\|^## Procedure 5" supporting-docs/METHODOLOGY.md`
    confirms both procedures present.
  - Prompt Authoring Principles section unchanged (diff against
    previous HEAD shows no edits inside that section).
- **Gate:** member of Gate C.

#### Commit C-046-09 — Historical maintenance-docs annotation (V9-DESIGN.md, V9-AUDIT-REPORT.md)

- **Message:** `docs: v10 — BD-046 annotate V9 design records with supersession notes`
- **Part 8 rows:** 36, 37.
- **Source sections:** Part 4 §4.8 annotate-only rule; Part 5 §5.13
  (annotate Decision 7 → V10-DESIGN Part 5 custom-agent mechanism);
  V9 Lessons 4, 5.
- **Files:**
  - `maintenance-docs/V9-DESIGN.md` — add v10 supersession annotations
    next to PROMPT-TEMPLATES.md references; annotate Decision 7
    pointer to V10-DESIGN Part 5. Do NOT mutate historical content.
  - `maintenance-docs/V9-AUDIT-REPORT.md` — same treatment.
- **Dependencies:** none within Phase 2b.
- **Verification after commit:**
  - `validate-pack.py` passes (Check 4 still OK; V9 content untouched).
  - Grep confirms annotations added but original lines preserved
    (inline note style, not deletion).
- **Gate:** member of Gate C.

#### Commit C-046-10 — supporting-docs sweep (CLI-PM-SETUP, SETUP_TEMPLATE, DEPENDENCIES, MIGRATION-v8-to-v9)

- **Message:** `docs: v10 — BD-046 supporting-docs PROMPT-TEMPLATES sweep`
- **Part 8 rows:** 32, 33, 34, 35. (Note: row 33 also involves BD-044
  changes for SETUP_TEMPLATE.md `cp -r` replacement and QUICKSTART
  Step N refs — defer those BD-044 parts until Phase 3 so this commit
  is scoped to the PROMPT-TEMPLATES sweep only, or combine here and
  label the commit carefully.)
- **Recommended split:** do only the PROMPT-TEMPLATES.md reference
  replacement in this commit; the SETUP_TEMPLATE `cp -r` replacement
  and Step-N-reference rewrite come in Phase 3 (C-044-05) when
  QUICKSTART is rewritten and SETUP-NEW.md exists as the target.
- **Source sections:** Part 4 §4.8; Part 7 §7.13 integration.
- **Files:**
  - `supporting-docs/CLI-PM-SETUP.md` — replace PROMPT-TEMPLATES
    references with `docs/pack/prompts/<agent>.md` equivalents.
  - `supporting-docs/SETUP_TEMPLATE.md` — replace PROMPT-TEMPLATES
    references only (leave `cp -r` lines for Phase 3).
  - `supporting-docs/DEPENDENCIES.md` — sweep only if PROMPT-TEMPLATES
    is enumerated; otherwise no-op.
  - `supporting-docs/MIGRATION-v8-to-v9.md` — historical; no mutation
    required. Optionally add a single-line pointer to
    `MIGRATION-v9-to-v10.md` (once that file lands in Phase 2c).
- **Dependencies:** none beyond C-046-01.
- **Verification after commit:**
  - `grep -rn "PROMPT-TEMPLATES" supporting-docs/` returns only
    `PROMPT-TEMPLATES.md` file itself (not yet deleted) and
    `MIGRATION-v8-to-v9.md` as historical text.
- **Gate:** member of Gate C.

#### Commit C-046-11 — validate-pack.py Checks 7 and 8

- **Message:** `feat: v10 — BD-046 validate-pack.py Checks 7 pack roster and 8 reserved x- prefix`
- **Part 8 rows:** 57, 58.
- **Source sections:** Part 5 §5.3 (roster; Check 7 parses PM-CHAT.md
  `## Pack agent roster` and compares to `.claude/agents/*.md` stems;
  fail on mismatch); Part 5 §5.5 (Check 8 — seven scan locations:
  `project-template/.claude/agents/`, `.codex/agents/`, `.gemini/agents/`,
  `.claude/skills/*/`, `.codex/skills/*/`, `.gemini/skills/*/`,
  `docs/pack/prompts/`; fail if any filename or top-level dir entry
  begins with `x-`).
- **Files:** `scripts/validate-pack.py`.
- **Dependencies:** C-046-04 (PM-CHAT.md has `## Pack agent roster`);
  C-046-01 (`docs/pack/prompts/` exists for Check 8 scan).
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` — Check 7 passes; Check 8
    passes (pack ships zero `x-` files) (V-CI-03, V-CI-05).
  - Negative test locally (do NOT commit): temp-add
    `project-template/docs/pack/prompts/x-test.md`; expect Check 8
    failure naming file (V-CI-06). Revert.
  - Negative test locally: add bogus name to PM-CHAT.md roster; expect
    Check 7 mismatch (V-CI-04, V-PM5-09). Revert.
- **Gate:** member of Gate C.

#### Commit C-046-12 — Delete supporting-docs/PROMPT-TEMPLATES.md

- **Message:** `feat: v10 — BD-046 delete supporting-docs/PROMPT-TEMPLATES.md`
- **Part 8 rows:** 23.
- **Pre-deletion sweep (mandatory — V9 Lesson 4):**

  ```bash
  grep -rn "PROMPT-TEMPLATES" \
      project-template/ supporting-docs/ \
      QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md \
      CLAUDE.md AGENTS.md GEMINI.md
  ```

  **Expected:** the only matches are in `supporting-docs/PROMPT-TEMPLATES.md`
  itself (about to be deleted), in `maintenance-docs/V9-DESIGN.md` and
  `V9-AUDIT-REPORT.md` (annotated, not mutated per C-046-09), and in
  `supporting-docs/MIGRATION-v8-to-v9.md` (historical). **Any other
  match is a regression; fix before deleting.**

  Note: `QUICKSTART.md` still contains references at this stage because
  the rewrite happens in Phase 3 (C-044-05). **That is acceptable**
  because QUICKSTART.md's PROMPT-TEMPLATES references are replaced in
  the same Phase 3 commit that references the new `MIGRATION-v9-to-v10.md`
  guide. The alternative (delete PROMPT-TEMPLATES.md now, rewrite
  QUICKSTART later) leaves QUICKSTART pointing at a nonexistent file
  in between. **Solution:** defer this deletion commit to Phase 3
  **after** QUICKSTART is rewritten — re-labeled as **C-044-07**. The
  slot "C-046-12" is then reassigned to migration prep if needed.

- **Resolution:** PROMPT-TEMPLATES.md deletion moves to Phase 3 as
  **C-044-07** (after C-044-05 rewrites QUICKSTART.md). Phase 2b
  completes with C-046-11; Phase 2c begins next.
- **Gate:** (the deletion itself is a Gate-E member; see §5.5.)

#### Gate C — End of Phase 2b

**Entry criteria:** commits C-046-03…11 complete; validate-pack.py
passes with Checks 6, 7, 8 active; PROMPT-TEMPLATES sweep clean except
for deferred QUICKSTART and to-be-deleted monolith and historical files.

**Approval check:**
1. Run full sweep #1 (PROMPT-TEMPLATES) — confirm only the three
   expected residuals.
2. Run Trinity integrity audit (Part 8 §8.5) — every row's BD-045 +
   BD-046 edits present symmetric across CLAUDE/AGENTS/GEMINI.
3. Confirm METHODOLOGY.md Procedure 5 and 5-R both land in same commit
   and Prompt Authoring Principles section is unchanged.

**Approve to proceed to Phase 2c.**


### 5.4 Phase 2c — BD-046 migration tooling

Migration script depends on `scripts/lib/detect.sh` (shared library per
Part 7 §7.2). `detect.sh` is a BD-044 row (51) but is sourced here.
**Decision:** build `scripts/lib/` and `scripts/lib/detect.sh` in this
phase (labeled as BD-044 in the commit message per Part 8 row-level
tagging) because migration needs it. init-project.sh (Phase 3) then
sources the same library unchanged. This order avoids creating a stub
now and rewriting later.

#### Commit C-044/046-01 — scripts/lib/ directory + scripts/lib/detect.sh

- **Message:** `feat: v10 — BD-044 scripts/lib/detect.sh shared detection library`
- **Part 8 rows:** 50, 51 (note: labeled BD-044 but created in Phase 2c
  ordering per design §12.1 "BD-046 migration depends on shared detection").
- **Source sections:** Part 7 §7.2 (function list: `detect_clean_working_tree`,
  `detect_git_repo`, `detect_pack_path`, `detect_pack_version`,
  `detect_ai_config`, `detect_x_files`, `detect_improperly_added_files`).
  `detect.sh` is sourced, not executed; every function prints
  `key: value` structured output; functions read-only.
- **Files:**
  - `scripts/lib/` (new directory).
  - `scripts/lib/detect.sh` (new).
- **Dependencies:** Phase 2b complete (seven scan locations defined by
  §5.5).
- **Verification after commit:**
  - `bash -n scripts/lib/detect.sh` parses cleanly.
  - Smoke test: `source scripts/lib/detect.sh && detect_pack_path`
    prints a valid structured line.
  - `validate-pack.py` passes (no new check yet — Check 9 adds
    `scripts/lib/` structural assertion in Phase 3 C-044-06).
- **Gate:** member of Gate D.

#### Commit C-046-13 — scripts/merge-platform-skills.py

- **Message:** `feat: v10 — BD-046 merge-platform-skills.py helper`
- **Part 8 rows:** 46.
- **Source sections:** Part 6 §6.6 (positional splice rule — project-
  owned region starts at first `## Custom agents` or `## Custom skills`
  H2; everything from there to EOF is project-owned; pack region is
  above; v10 pack template used verbatim on v9.3 projects without
  custom sections).
- **Files:** `scripts/merge-platform-skills.py`.
- **Dependencies:** C-046-05 (PLATFORM-SKILLS.md custom sections spec
  stabilized in template).
- **Verification after commit:**
  - `python3 -m py_compile scripts/merge-platform-skills.py`.
  - Smoke test against a mock v9.3 PLATFORM-SKILLS.md fixture + v10
    template — expect merged output with pack region from v10 and
    project region from v9.3 preserved verbatim.
  - `validate-pack.py` passes.
- **Gate:** member of Gate D.

#### Commit C-046-14 — scripts/merge-trinity.py

- **Message:** `feat: v10 — BD-046 merge-trinity.py helper`
- **Part 8 rows:** 47.
- **Source sections:** Part 6 §6.6 (two splices per trinity file —
  `### Custom agents` sub-section from first occurrence to next H2;
  `**Active skills:**` line — preserve project content if not
  placeholder).
- **Files:** `scripts/merge-trinity.py`.
- **Dependencies:** C-046-03 (trinity Custom agents sub-section
  introduced in pack template).
- **Verification after commit:**
  - `python3 -m py_compile scripts/merge-trinity.py`.
  - Smoke test against all three mock v9.3 trinity files + v10
    templates — expect project regions preserved atomically across all
    three; partial failure caught.
  - `validate-pack.py` passes.
- **Gate:** member of Gate D.

#### Commit C-046-15 — scripts/migrate-v9-to-v10.sh

- **Message:** `feat: v10 — BD-046 migrate-v9-to-v10.sh migration script`
- **Part 8 rows:** 45.
- **Source sections:** Part 6 §6.1 (preservation mechanism — in-place
  skip, not temp-move-and-restore); Part 6 §6.3 (S0 pre-flight checks);
  Part 6 §6.4 (OQ-3 PROMPT-TEMPLATES.md diff vs v9.3 baseline);
  Part 6 §6.6 (PLATFORM-SKILLS.md + trinity splices via Python helpers);
  Part 6 §6.7 (rollback plan — backup dir manifest, covered files);
  Part 6 §6.8 (eight stages S0–S7 with sentinels); Part 6 §6.11
  (sources `scripts/lib/detect.sh`).
- **Files:** `scripts/migrate-v9-to-v10.sh`.
- **Dependencies:** C-044/046-01 (detect.sh); C-046-13 + C-046-14
  (merge helpers).
- **Verification after commit:**
  - `bash -n scripts/migrate-v9-to-v10.sh` parses cleanly.
  - `chmod +x` applied (commit includes mode bit).
  - Dry-run on a v9.3 fixture checkout — stages S0–S7 all write
    sentinel files; `report.md` produced.
  - All incremental-testability V-INC-01..09 assertions pass on the
    fixture.
- **Gate:** member of Gate D.

#### Commit C-046-16 — supporting-docs/MIGRATION-v9-to-v10.md

- **Message:** `docs: v10 — BD-046 MIGRATION-v9-to-v10.md guide`
- **Part 8 rows:** 44.
- **Source sections:** Part 6 §6.9 (15-section outline); Part 6 §6.7
  rollback procedure verbatim; Part 6 §6.9 paste-ready automatable-
  migration prompt.
- **Files:** `supporting-docs/MIGRATION-v9-to-v10.md`.
- **Dependencies:** C-046-15 (migration script exists; guide
  references the script commands).
- **Verification after commit:**
  - Every script command in the guide is exact (copy-paste the
    invocations; confirm they match the script's actual interface).
  - Rollback block in §12 matches Part 6 §6.7 verbatim.
  - Automatable prompt in §15 matches Part 6 §6.9 verbatim.
  - `validate-pack.py` passes.
- **Gate:** member of Gate D.

#### Gate D — End of Phase 2c

**Entry criteria:** C-044/046-01, C-046-13..16 complete;
`validate-pack.py` passes; migration dry-run on v9.3 fixture succeeds
with all V-INC-* assertions green.

**Approval check:**
1. Run Part 10 V-M1-01 (CP) on a Swift-only fixture. If it passes,
   BD-046 migration is ready for BD-044 integration.
2. Confirm rollback rehearsal V-M1-ROLLBACK succeeds (post-rollback
   tree byte-identical to v9.3 fixture).
3. Confirm V-X-PRESERVE-01 on fixture with seeded `x-` files.

**Approve to proceed to Phase 3.**


### 5.5 Phase 3 — BD-044 init-project.sh, router, SETUP guides, README layout

#### Commit C-044-02 — scripts/init-project.sh

- **Message:** `feat: v10 — BD-044 init-project.sh with detection and preview-and-confirm`
- **Part 8 rows:** 49.
- **Source sections:** Part 7 §7.3 (five project classes and detection
  rules); Part 7 §7.4 (AI config stop condition — exit 20); Part 7 §7.5
  (preview-and-confirm flow, default No, `y/Y/yes` to proceed); Part 7
  §7.6 (11 stages S0–S10 with conditional-removal at S9, skip-list at
  S7 for existing projects, new-empty / new-bare copy-everything
  behavior); Part 7 §7.7 (per-stage assertions + blast-radius sweep,
  exit codes 10, 11, 12, 20, 21–30, 31, 40, 99); Part 7 §7.8 (skill-gap
  detection + end-of-run prompt with conditional blocks); Part 6 §6.11
  (sources `scripts/lib/detect.sh`).
- **Files:** `scripts/init-project.sh`.
- **Dependencies:** C-044/046-01 (`scripts/lib/detect.sh` exists);
  Phase 2a-2b complete (docs/pack/prompts/ and trinity template in
  final form — init copies them verbatim).
- **Verification after commit:**
  - `bash -n scripts/init-project.sh` parses cleanly.
  - `chmod +x` applied.
  - Run V-INIT-NEW-01 against a fresh-git-init fixture — expect all
    stage assertions pass; kickoff prompt printed with absolute
    project path, pack version, variant reference to
    `docs/pack/prompts/pm-chat.md`.
  - Run V-INIT-EXIST-07 against a fixture containing `.claude/` —
    expect exit 20 and no files written.
  - Run V-INIT-VERIFY-10 blast-radius: `grep -r PROMPT-TEMPLATES` in
    the installed project returns zero matches.
- **Gate:** member of Gate E.

#### Commit C-044-03 — supporting-docs/SETUP-NEW.md

- **Message:** `docs: v10 — BD-044 SETUP-NEW.md new-project guide`
- **Part 8 rows:** 52.
- **Source sections:** Part 7 §7.10 (section list, ~300–400 lines);
  lift from current QUICKSTART.md §§1–12 minus steps replaced by
  init-project.sh; update PROMPT-TEMPLATES.md refs to
  `docs/pack/prompts/pm-chat.md` variants; SETUP §10 references pm-chat
  variant slugs from C-046-01.
- **Files:** `supporting-docs/SETUP-NEW.md`.
- **Dependencies:** C-044-02 (init-project.sh exists; SETUP-NEW
  references it); C-046-01 (prompts variants exist).
- **Verification after commit:**
  - `validate-pack.py` passes.
  - Every script command in the guide matches the actual init-project.sh
    interface.
  - Every prompt-variant reference exists in the pack (manual check
    vs `docs/pack/prompts/*.md` frontmatter).
- **Gate:** member of Gate E.

#### Commit C-044-04 — supporting-docs/SETUP-EXISTING.md

- **Message:** `docs: v10 — BD-044 SETUP-EXISTING.md existing-project guide`
- **Part 8 rows:** 53.
- **Source sections:** Part 7 §7.11 (section list ~200–250 lines;
  preview walk-through; existing-docs pointer procedure in Step 9;
  skill-gap follow-up).
- **Files:** `supporting-docs/SETUP-EXISTING.md`.
- **Dependencies:** C-044-02 + C-044-03.
- **Verification after commit:**
  - `validate-pack.py` passes.
  - Run V-INIT-EXIST-01 by hand following the guide verbatim; expect
    preview report matches §7.5; no skip-list file modified.
- **Gate:** member of Gate E.

#### Commit C-044-05 — QUICKSTART.md rewrite (three-path router)

- **Message:** `feat: v10 — BD-044 QUICKSTART.md three-path router`
- **Part 8 rows:** 54 (which combines with row 31 — QUICKSTART.md full
  rewrite drops PROMPT-TEMPLATES.md reference as part of the rewrite).
- **Source sections:** Part 7 §7.9 (full ~30-line content verbatim);
  Part 7 §7.12 (migration-guide naming convention references).
- **Files:** `QUICKSTART.md` (top-level).
- **Dependencies:** C-044-03 + C-044-04 (links to SETUP-NEW and
  SETUP-EXISTING); C-046-16 (MIGRATION-v9-to-v10.md exists for the
  third path).
- **Verification after commit:**
  - `grep -n "PROMPT-TEMPLATES" QUICKSTART.md` zero matches.
  - Every link resolves to an existing file.
  - Line count ≤ ~40 (router, not procedure).
- **Gate:** member of Gate E.

#### Commit C-044-06 — top-level README.md Repository Layout

- **Message:** `docs: v10 — BD-044 README.md repository layout for v10`
- **Part 8 rows:** 55 (note: combines with 65 — version table — at
  Phase 5 ship commit; split the layout update here and version-table
  row at ship time).
- **Source sections:** Part 7 §7.12 (migration-guide naming convention
  authoritative note); Part 8 entries for new files.
- **Action:** update the Repository Layout section to list:
  - `scripts/lib/` (new subdirectory)
  - `scripts/init-project.sh`
  - `scripts/migrate-v9-to-v10.sh`
  - `scripts/merge-platform-skills.py`
  - `scripts/merge-trinity.py`
  - `supporting-docs/SETUP-NEW.md`
  - `supporting-docs/SETUP-EXISTING.md`
  - `supporting-docs/MIGRATION-v9-to-v10.md`
  - `project-template/docs/pack/prompts/` directory + `PROMPT-AUTHORING.md` entry
  - Remove `supporting-docs/PROMPT-TEMPLATES.md` from the listing
    (file deletion lands in C-044-07 next).
  - Add the migration-guide naming convention note under
    `supporting-docs/` per Part 7 §7.12.
- **Files:** `README.md` (top-level).
- **Dependencies:** C-044-02..05.
- **Verification after commit:**
  - `validate-pack.py` Check 4 still passes (version table unchanged;
    v10.0 row added at ship time).
  - Manual: every file listed in the layout actually exists in the repo.
- **Gate:** member of Gate E.

#### Commit C-044-07 — Delete supporting-docs/PROMPT-TEMPLATES.md

- **Message:** `feat: v10 — BD-046 delete supporting-docs/PROMPT-TEMPLATES.md`
- **Part 8 rows:** 23 (relocated from Phase 2b to here per
  Phase 2b §C-046-12 rationale — QUICKSTART.md is now rewritten and
  README layout no longer lists the file).
- **Pre-deletion mandatory sweep:**

  ```bash
  grep -rn "PROMPT-TEMPLATES" \
      project-template/ supporting-docs/ \
      QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md \
      CLAUDE.md AGENTS.md GEMINI.md
  ```

  **Expected results:**
  - `supporting-docs/PROMPT-TEMPLATES.md` itself — 0 matches (about
    to be deleted; grep excludes the file because we `rm` it in this
    same commit).
  - `supporting-docs/MIGRATION-v8-to-v9.md` — any historical references
    are acceptable; annotate with supersession note if not done.
  - `maintenance-docs/V9-DESIGN.md`, `V9-AUDIT-REPORT.md` — acceptable
    (annotated in C-046-09).
  - **Every other file: zero matches.**

  If any unexpected file has a match, fix it in this commit (same
  commit deletes the file AND fixes any stragglers — atomic).
- **Action:** `git rm supporting-docs/PROMPT-TEMPLATES.md`.
- **Dependencies:** C-044-05 + C-044-06 (no referrer remains outside
  the annotated historical set).
- **Verification after commit:**
  - `validate-pack.py` passes.
  - `grep -rn "PROMPT-TEMPLATES" .` outside maintenance-docs
    annotations and MIGRATION-v8-to-v9.md returns zero.
  - `ls supporting-docs/PROMPT-TEMPLATES.md` exits non-zero.
- **Gate:** member of Gate E.

#### Commit C-044-08 — validate-pack.py Check 9

- **Message:** `feat: v10 — BD-044 validate-pack.py Check 9 init-project structure`
- **Part 8 rows:** 59.
- **Source sections:** Part 7 §7.13 (Check 9 scope); Part 5 §5.11.
- **Files:** `scripts/validate-pack.py`.
- **Check 9 asserts:**
  1. `scripts/init-project.sh` exists and is executable.
  2. `scripts/lib/detect.sh` exists; grep for required function names
     from Part 7 §7.2.
  3. `QUICKSTART.md` exists (top-level); `supporting-docs/SETUP-NEW.md`,
     `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md` all exist.
  4. `README.md` Repository Layout mentions `scripts/lib/` and the
     migration-guide naming convention note.
- **Dependencies:** C-044-02..07 (all referenced files exist).
- **Verification after commit:**
  - `python3 scripts/validate-pack.py` — Check 9 passes (V-CI-07).
  - Negative tests locally (do NOT commit): delete each file in turn
    and confirm Check 9 names it; restore.
- **Gate:** member of Gate E.

#### Re-verify CI workflow

- **Part 8 rows:** 61 (`.github/workflows/validate-pack.yml`).
- **Action:** verify that the existing workflow still invokes
  `python3 scripts/validate-pack.py` and thus picks up Checks 6–9 with
  no workflow change. If the existing workflow separates invocations,
  update accordingly.
- **If change needed:** small commit `docs: v10 — BD-044 validate-pack workflow reaffirm` (unlikely per design).

#### Gate E — End of Phase 3

**Entry criteria:** C-044-02..08 complete; all nine `validate-pack.py`
checks pass; PROMPT-TEMPLATES.md deleted; repository layout reflects
v10 structure.

**Approval check:**
1. Run full Part 10 CP test set (V-M1-01, V-M1-04, V-M1-05, V-M1-09,
   V-M1-12, V-M1-13, V-M1-15; V-M2-01, V-M2-02, V-M2-04, V-M2-05, V-M2-08;
   V-M3-01, V-M3-04, V-M3-05, V-M3-07, V-M3-08; V-M3-10). All must pass.
2. Run V-CI-01..10 (all ten CI tests).
3. Run V-PM5-01..10 (PM chat workflow tests on a fresh v10 project).
4. Run V-PROMPT-01..05 (prompt migration correctness).
5. Run V-X-PRESERVE-01..03.
6. Run V-BD045-01..07.
7. Run V-BLAST-01..06.
8. Run V-INIT-VERIFY-01..10 and V-INIT-FAIL-01..04.
9. Run V-INC-01..09 on a migration fixture.

**Approve to proceed to Phase 4 (final verification pass) or make
`fix:` commits to resolve any failures. Each fix is a separate commit
with verification.**


### 5.6 Phase 4 — Full verification pass

No new feature commits. Only `fix:` commits if Gate E verification
surfaced issues. This phase formalizes the global pre-ship review.

#### Activities

1. **All six stale-reference sweeps** from Part 8 §8.6 (exact grep
   commands in §6 below). Each must return the expected (mostly zero)
   match set.
2. **Trinity integrity audit** (Part 8 §8.5 table). For each of the
   six section rows, diff the three trinity files to confirm
   symmetry. No divergence except Codex auditor-architecture formatting
   deviation.
3. **Deferred-item smoke tests** (V10-DESIGN Part 13):
   - Part 13 §13.1 — Codex skill loading with `x-` prefix: smoke test
     before BD-046 merge. Create a `.codex/skills/x-test/SKILL.md` in
     a throwaway fixture; launch Codex CLI; confirm the skill loads. If
     it fails, add the tool-specific footnote to Part 5 §5.1 row 4 (as
     an additional `docs:` commit on v10-dev) and update Procedure 5.2.
   - Part 13 §13.3 — Claude Code `.claude/agents/*.md` live reload: add
     a dummy `x-test.md` in an active Claude Code session; confirm
     Claude detects without restart. If not, update Part 5 §5.8 user-
     facing message to note restart requirement (add a `docs:` commit).
4. **OT project migration dry-run** (optional at this phase;
   mandatory in Phase 6): on the OT project clone, run the migration
   per MIGRATION-v9-to-v10.md against a copy of v9.3 state; confirm
   success without committing.
5. **BACKLOG.md BD status review.** Confirm that BD-044, BD-045,
   BD-046 remain Unblocked (they become Resolved at Phase 5 ship).

No commits unless fixes needed.

#### Gate F — End of Phase 4

**Entry criteria:** all Phase 3 CP tests green; all six Part 8 §8.6
sweeps produce expected results; deferred-item smoke tests pass or
have resulting `docs:` fix commits landed.

**Approval check:** developer signs off that the pack is ship-ready.

### 5.7 Phase 5 — Ship v10.0

Ship commits in strict order.

#### Commit S-01 — CHANGELOG.md v10.0 entry

- **Message:** `docs: v10 — CHANGELOG.md v10.0 entry`
- **Part 8 rows:** 66.
- **Action:** add v10.0 section summarizing BD-045, BD-046, BD-044,
  migration-script and init-project delivery, validate-pack Checks 6–9,
  migration guide, custom agent/skill support, and the deletion of
  PROMPT-TEMPLATES.md.
- **Files:** `CHANGELOG.md`.
- **Verification:** `validate-pack.py` passes.

#### Commit S-02 — README.md v10.0 version table row + V10-PREDESIGN banner

- **Message:** `docs: v10 — README v10.0 version table; V10-PREDESIGN supersession`
- **Part 8 rows:** 65, 63 (V10-PREDESIGN.md banner; row 62 V10-DESIGN
  already APPROVED).
- **Action:**
  - Add `| v10.0 | <date> | BD-045 capabilities pattern; BD-046 custom
    agent/skill support + prompt reorg + migration; BD-044 project
    setup paths + init-project.sh + QUICKSTART router |` row to the
    top-level README version table.
  - Add supersession banner to `maintenance-docs/V10-PREDESIGN.md`
    pointing at `V10-DESIGN.md`; body retained (V9 Lesson 4).
  - Confirm `V10-DESIGN.md` status line already shows APPROVED (no
    edit needed per recent commits).
- **Files:** `README.md`, `maintenance-docs/V10-PREDESIGN.md`.
- **Verification:** `validate-pack.py` Check 4 now compares the README
  v10.0 row against the (soon-to-be-created) v10.0 git tag. The tag
  is created after commit per §5.7 tagging step — expect Check 4 "dev
  branch" tolerance to pass while still on v10-dev.

#### Commit S-03 — BACKLOG.md resolve BD-044, BD-045, BD-046

- **Message:** `docs: v10 — BACKLOG BD-044 / BD-045 / BD-046 Resolved at v10.0`
- **Part 8 rows:** 64.
- **Action:** set Status: Resolved on each of BD-044, BD-045, BD-046
  with the v10.0 ship date and pointer to `v10.0` tag. Per CLAUDE.md,
  BACKLOG.md is PM-chat-only — this commit happens only after user
  approval.
- **Files:** `BACKLOG.md`.
- **Verification:** `validate-pack.py` Check 3 passes (no TD-TBD).

#### Merge to main + tags

```bash
# Pre-flight
git checkout v10-dev
python3 scripts/validate-pack.py          # must pass

# Merge
git checkout main
git pull --ff-only
git merge --no-ff v10-dev -m "Merge v10-dev into main — v10.0"

# Tags
git tag -a v10.0 -m "v10.0"
git tag -f v10 v10.0                       # floating major tag

# Push
git push origin main
git push origin v10.0
git push origin v10 --force                # floating tag move
```

Per CLAUDE.md tag-move sequence: delete local + remote, recreate, push.
`v10` floating tag is recreated each minor release.

#### Ship approval gate

Final developer confirmation: "ship v10.0." Only then does the merge
+ push run.

### 5.8 Phase 6 — Post-ship

1. **OT project migration.** Run MIGRATION-v9-to-v10.md on the OT
   project using `scripts/migrate-v9-to-v10.sh`. Confirm all
   incremental-testability assertions pass. Report any regressions to
   pack chat for a v10.1 `fix:` commit cycle.
2. **Deferred-item follow-through:**
   - Part 13 §13.1 (Codex skill loading) — resolved at Gate F smoke
     test; any remaining uncertainty becomes a BD entry in BACKLOG.md.
   - Part 13 §13.2 (Gemini CLI Hooks) — only revisited if a future
     v10.x design requires it; no action in v10.0.
   - Part 13 §13.3 (Claude Code agent live reload) — resolved at
     Gate F smoke test.
   - Part 13 §13.4 (audit-methodology rule 15 back-reference) — either
     resolved in C-045-04 (edit) or in the Phase 3 review log
     (decision: no edit). Either way, recorded.
3. **v10.x planning.** Open BD numbers for any Phase 4 or OT migration
   regressions discovered post-ship.

---

## 6. Stale-reference sweep schedule

From V10-DESIGN Part 8 §8.6. Each sweep runs after the commits noted.
Each "expected result" is the commit-blocker contract.

| # | Sweep | Runs after | Expected | Action on failure |
|---|---|---|---|---|
| S1 | `grep -rn "PROMPT-TEMPLATES" project-template/ supporting-docs/ maintenance-docs/V9-DESIGN.md maintenance-docs/V9-AUDIT-REPORT.md QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md CLAUDE.md AGENTS.md GEMINI.md` | (a) After C-046-10 — expect only: `PROMPT-TEMPLATES.md` file itself, `MIGRATION-v8-to-v9.md` historical, V9-DESIGN/V9-AUDIT-REPORT annotated. (b) After C-044-05 — expect QUICKSTART zero matches added. (c) After C-044-07 — expect only historical and annotated refs (no `PROMPT-TEMPLATES.md` file). | Add the offending file to the same commit as a sweep; do not advance past the gate |
| S2 | `grep -rnE "QUICKSTART\.md\s+Step\s+[0-9]+" project-template/ supporting-docs/ maintenance-docs/` | After C-044-05 | Zero matches in `supporting-docs/` and `project-template/`. Historical references in `maintenance-docs/` acceptable (annotate if unclear). | Fix referenced file in same phase |
| S3 | `grep -rnE "cp\s+-r\s+.*project-template" supporting-docs/ maintenance-docs/` | After C-046-10 and again after C-044-03 | Zero matches in `supporting-docs/` (replaced by `bash "$PACK/scripts/init-project.sh"`). Historical references in `maintenance-docs/` acceptable. | Update any operational doc to reference init-project.sh |
| S4 | `grep -rnE "\[agents\.(x_\|x-)" project-template/ supporting-docs/ maintenance-docs/` | After C-046-04 | Zero matches (per Part 5 §5.4 resolution — no per-agent Codex config entry). | Remove any stray documentation example |
| S5 | `ls project-template/.claude/agents/ project-template/.codex/agents/ project-template/.gemini/agents/ project-template/skills/ project-template/docs/pack/prompts/ 2>/dev/null \| grep "^x-"` | After every BD-046 commit | Zero `x-` entries (V-CI-05). Also asserted by Check 8 after C-046-11. | Remove the `x-` file before the commit is pushed |
| S6 | `grep -rnE "rule [1-9][0-9]" project-template/skills/apple-architecture-core/ project-template/skills/python-best-practices/ project-template/skills/architecture-review/ project-template/ supporting-docs/ maintenance-docs/` | After C-045-02 | Every rule reference resolves to the intended content post-renumber (V-BD045-07). | Rewrite the offending reference in the same commit |

Additional per-commit local sweeps are enumerated in each commit's
"Verification after commit" block.

---

## 7. validate-pack.py sequencing

Four new checks (6, 7, 8, 9) plus re-verify of existing Checks 1 and 5
after BD-045 edits. The sequencing rule: **each check lands in the
commit that completes its target content; never before, never after.**

| Check | Added in commit | Target content available after commit | Rationale |
|---|---|---|---|
| 6 — prompts-dir format | C-046-02 | C-046-01 (10 prompt files + PROMPT-AUTHORING.md) | Added in the next commit after content so CI passes on the content-commit, then the validator commit hardens it |
| 7 — pack-agent-roster | C-046-11 | C-046-04 (PM-CHAT.md `## Pack agent roster` section) | After roster section exists and stabilized |
| 8 — reserved `x-` prefix | C-046-11 | always (pack ships zero `x-`) | Must land with Check 7 because both concern the custom-agent mechanism; together they form the roster-consistency guard |
| 9 — BD-044 structure | C-044-08 | C-044-02..07 (all referenced files exist) | Last, so every assertion target already shipped |
| 1 re-verify | C-045-02 (in-commit manual run) | Renumbered skills | No code change to Check 1; just confirm it still passes |
| 5 re-verify | C-045-03 (in-commit manual run) | Updated auditor-architecture trio | No code change to Check 5; confirm parity |

Between commits (C-046-01 through C-046-02, etc.), CI runs the older
check set. Every intermediate CI run is green. No check references
a target file that does not yet exist at that commit.

---

## 8. Approval gates — summary

| Gate | After phase | Blocker criteria before developer approves |
|---|---|---|
| Pre-work | Branch setup | `v10-dev` branch created, pushed; CLAUDE.md commit/versioning rules acknowledged |
| **A** | Phase 1 (BD-045) | BD-045 trinity + skills + auditor trio edits done; capabilities-pattern content reviewed; renumbering sweep clean; `validate-pack.py` green |
| **B** | Phase 2a (prompt reorg) | 10 prompt files + PROMPT-AUTHORING.md present; Check 6 active and green; token-count and template-accounting sanity |
| **C** | Phase 2b (custom-agent + sweeps) | All trinity BD-046 edits combined; PM-CHAT roster; METHODOLOGY Procedure 5 + 5-R; Checks 7 + 8 green; PROMPT-TEMPLATES sweep clean except expected residuals |
| **D** | Phase 2c (migration) | merge helpers + migrate-v9-to-v10.sh + guide land; V-M1-01 + V-M1-ROLLBACK + V-X-PRESERVE-01 pass on v9.3 fixture |
| **E** | Phase 3 (BD-044) | init-project.sh + SETUP guides + QUICKSTART router + README layout + Check 9; PROMPT-TEMPLATES.md deleted; full Part 10 CP test set passes |
| **F** | Phase 4 (verification) | all six §6 sweeps clean; trinity integrity audit clean; deferred-item smoke tests resolved |
| **Ship** | Phase 5 (ship) | CHANGELOG + version table + BACKLOG updated; merged to main; tags pushed |

Each gate is a **stop**. No commit in the next phase begins until the
developer explicitly approves.


---

## 9. New-file content-source map

For every new file the implementer will create, the authoritative
V10-DESIGN source section and any additional input file needed.

| New file | Part 8 row | V10-DESIGN source | Additional input |
|---|---|---|---|
| `project-template/docs/pack/prompts/coder.md` | 12 | Part 4 §4.1 (T2+T4 line ranges) + §4.5 (format) + §4.6 (report convention) | Current `supporting-docs/PROMPT-TEMPLATES.md` lines 131–209 (T2) and 293–375 (T4) |
| `project-template/docs/pack/prompts/reviewer.md` | 13 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 211–291 (T3) |
| `project-template/docs/pack/prompts/tester.md` | 14 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 424–451 (T5) |
| `project-template/docs/pack/prompts/planner.md` | 15 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 488–511 (T7) |
| `project-template/docs/pack/prompts/docs-researcher.md` | 16 | §4.5 + §4.6 | PROMPT-TEMPLATES.md lines 453–486 (T6) |
| `project-template/docs/pack/prompts/architect.md` | 17 | §4.2 (placeholder) + §4.5 | PROMPT-TEMPLATES.md lines 377–422 (T4b, reassigned from coder) |
| `project-template/docs/pack/prompts/grpc-schema.md` | 18 | §4.2 (zero-variant placeholder) + §4.5 | none |
| `project-template/docs/pack/prompts/repo-ops.md` | 19 | §4.2 (zero-variant placeholder) + §4.5 | none |
| `project-template/docs/pack/prompts/auditor.md` | 20 | §4.5 + §4.6; T10–12 supersession note | PROMPT-TEMPLATES.md lines 572–632 (T9) + 634–653 (T10–12) |
| `project-template/docs/pack/prompts/pm-chat.md` | 21 | §4.5 + §4.6 (all four variants: kickoff, backlog-status-update, generate-setup, generate-agent-kickoff; `agent: pm-chat` reserved) | PROMPT-TEMPLATES.md lines 79–129 (T1) + 515–570 (T8) + 655–678 (T13) + 680–738 (T14) |
| `project-template/docs/pack/prompts/PROMPT-AUTHORING.md` | 22 | Part 4 §4.3 (full content spec) | PROMPT-TEMPLATES.md lines 7–17 + 48–58 + 61–76 (hoisted) |
| `scripts/lib/detect.sh` | 51 | Part 7 §7.2 (function list + behavior) | none |
| `scripts/init-project.sh` | 49 | Part 7 §§7.3, 7.4, 7.5, 7.6, 7.7, 7.8 | Sources `scripts/lib/detect.sh`; calls merge helpers if needed |
| `scripts/migrate-v9-to-v10.sh` | 45 | Part 6 §§6.1, 6.3, 6.4, 6.6, 6.7, 6.8, 6.11 | Sources `scripts/lib/detect.sh`; invokes merge helpers |
| `scripts/merge-platform-skills.py` | 46 | Part 6 §6.6 PLATFORM-SKILLS.md rule | none |
| `scripts/merge-trinity.py` | 47 | Part 6 §6.6 trinity splice rules | none |
| `supporting-docs/MIGRATION-v9-to-v10.md` | 44 | Part 6 §6.9 (15-section outline) + §6.7 rollback verbatim + §6.9 automatable prompt | none |
| `supporting-docs/SETUP-NEW.md` | 52 | Part 7 §7.10 | Current QUICKSTART.md §§1–12 as lift-source |
| `supporting-docs/SETUP-EXISTING.md` | 53 | Part 7 §7.11 | Current QUICKSTART.md as orienting input |
| `QUICKSTART.md` (rewrite) | 54 | Part 7 §7.9 verbatim | none |
| `CHANGELOG.md` v10.0 entry | 66 | Summary of Phase 1–3 outputs | none |

New validator checks (`scripts/validate-pack.py`): Check 6 content in
Part 4 §4.5; Check 7 in Part 5 §5.3; Check 8 in Part 5 §5.5; Check 9
in Part 7 §7.13.

---

## 10. Cross-BD coordination checkpoints

From V10-DESIGN Part 12 §12.2. Each coordination point maps to a single
commit in this plan so the combined edits are atomic.

| Coordination point | V10-DESIGN §12.2 rule | Plan realization |
|---|---|---|
| Trinity files — Capabilities pattern + Document-locations + `### Custom agents` | BD-045 commits its content first; BD-046 layers. Trinity rule never half-present. | C-045-01 (BD-045 part) + C-046-03 (BD-046 part) — two atomic trinity commits |
| METHODOLOGY.md — Procedure 5 + 5-R + PROMPT-TEMPLATES sweep | All in one commit (Part 8 rows 30+43+48) | C-046-08 — single commit |
| QUICKSTART.md — three-path router rewrite + PROMPT-TEMPLATES reference drop | Rewrite unifies BD-044 + BD-046 (rows 31+54) | C-044-05 — single commit |
| README.md — Repository Layout + version table row | Layout in BD-044, version row at ship (rows 55+65 split) | C-044-06 (layout) + S-02 (version row) |
| validate-pack.py — Checks 6/7/8 (BD-046) + Check 9 (BD-044) | 6/7/8 in BD-046 batch; 9 in BD-044 batch | C-046-02, C-046-11, C-044-08 |

Trinity-rule integrity audit (Part 8 §8.5) runs at Gate F across all
six section rows. Any asymmetry introduced by a commit must be caught
before Gate F.

---

## 11. Back-reference check — audit-methodology rule 15

Per Part 8 §8.2.1 back-reference note and Part 13 §13.4:

1. Phase 1 includes **commit C-045-04 (conditional)** — read
   `project-template/skills/audit-methodology/SKILL.md` rule 15; decide
   whether the `Capabilities pattern adherence` scope bullet added to
   auditor-architecture in C-045-03 requires rule 15 to be extended
   with a matching "capabilities" clause.
2. **Decision criteria:**
   - If rule 15's current wording references "LSP compliance" or
     equivalent as the auditor-architecture scope authority AND the
     v10 auditor now has a new bullet authority (capabilities), then
     extend rule 15 with parallel wording so the authority chain is
     consistent.
   - If rule 15 is a general architectural rule not tied to the
     auditor scope list, no edit needed.
3. **Output:** either (a) commit C-045-04 is authored with a single-
   file edit to `audit-methodology/SKILL.md`, or (b) the Phase 3
   review log records "no extension required" with the specific
   sentence of rule 15 that was evaluated.
4. **Downstream impact:** if extension is made, it counts as a single
   additional row in Part 8 Inventory (surface the update there too).

---

## 12. OT project migration (Phase 6)

- **Trigger:** v10.0 shipped (tag `v10.0` exists on `main`).
- **Procedure:** follow `supporting-docs/MIGRATION-v9-to-v10.md`
  verbatim on the OT project clone. Use `$PACK` pointing at the pack
  checked out to tag `v10.0` (not v10-dev).
- **Verification per-stage:** the migration script's S0–S7 sentinels +
  post-stage assertions (V-INC-01..09) provide incremental testability.
  Rollback procedure (Part 6 §6.7) applies if any assertion fails.
- **Custom-file preservation:** confirm every OT `x-*` file byte-
  identical post-migration (V-X-PRESERVE-01 pattern).
- **Reconciliation:** if OT's `docs/pack/PROMPT-TEMPLATES.md` diverges
  from v9.3 baseline, `_v9-backup.md` is written and Procedure 5-R
  runs at first PM chat startup (V-M1-CUSTOM-02 / 03 pattern).
- **Report:** OT migration generates a PACK-FEEDBACK.md entry if any
  skill gap is flagged during the first PM chat run.

---

## 13. Deferred items — revisit schedule

From V10-DESIGN Part 13:

| Deferred item | Revisit in | Plan commit or step |
|---|---|---|
| §13.1 Codex skill loading with `x-` prefix | Phase 4 Gate F smoke test (before v10.0 ship) | Activity 3 in §5.6; `docs:` fix commit on v10-dev if footnote needed |
| §13.2 Gemini CLI Hooks verification | Only if future v10.x requires. No action in v10.0. | No plan commit |
| §13.3 Claude Code `.claude/agents/*.md` live reload | Phase 4 Gate F smoke test | Activity 3 in §5.6; `docs:` fix commit on v10-dev if message update needed |
| §13.4 audit-methodology rule 15 back-reference | Phase 1 commit C-045-04 (conditional) | §11 above |

If any deferred item resolution forces a v10.x minor release (rather
than a last-minute v10.0 fix), the BD is opened in BACKLOG.md per the
PM-chat-only approval rule and addressed in v10.1.

---

## 14. Risks, unknowns, and mitigations

| # | Risk | Trigger | Mitigation |
|---|---|---|---|
| R1 | Trinity rule violation during BD-046 layering — someone edits one trinity file and forgets the others | A per-file commit instead of a TRIO commit | Gate C manual trinity diff check; Check 5 parity; Check 7 roster (which reads one trinity file and compares to others); Part 8 §8.5 audit at Gate F |
| R2 | Stale PROMPT-TEMPLATES.md references in files outside the inventory | Sweep S1 finds an unexpected match | S1 runs three times during plan (after C-046-10, C-044-05, C-044-07); any unexpected match halts advancement until resolved in same commit |
| R3 | validate-pack.py Check 6 added before content exists → CI failure | Wrong sequencing | Plan sequencing §7 places Check 6 in C-046-02 (after C-046-01); plan explicitly blocks committing Check 6 before the target files exist |
| R4 | BD-045 renumbering breaks a stale reference in maintenance-docs | Sweep S6 finds matches | S6 runs after C-045-02; every finding is fixed in the same commit before Gate A |
| R5 | Migration script order bug — detect.sh not yet present when migrate-v9-to-v10.sh is committed | Commit-order bug | Plan sequences detect.sh as C-044/046-01 before migrate-v9-to-v10.sh (C-046-15) |
| R6 | Historical docs mutated in sweep sweeps (V9 Lesson 5 regression) | Overzealous sweep | Annotate-only rule for `maintenance-docs/V9-DESIGN.md`, `V9-AUDIT-REPORT.md`, `V10-PREDESIGN.md`, `MIGRATION-v8-to-v9.md`; §5.3 C-046-09 + C-046-10 explicitly annotate, do not rewrite |
| R7 | OT project has divergent PROMPT-TEMPLATES.md → Procedure 5-R never runs because PM chat misses `_v9-backup.md` | PM chat behavior not exercised on first run | V-M1-CUSTOM-03 in Phase 3 test set; if fails, Procedure 5-R wording in METHODOLOGY.md is strengthened (C-046-08 amendment or `fix:` commit) |
| R8 | Codex TOML parse failure after BD-045 auditor edit (developer_instructions triple-quoted string) | Malformed TOML | Check 2 (V-CI-09) catches in CI; Part 3 §3.7 formatting example is the source of truth |
| R9 | init-project.sh copies `docs/pack/prompts/` before PROMPT-AUTHORING.md rename is stable | Wrong ordering | Phase 3 runs after Phase 2a complete; C-044-02 sources files that have already stabilized in C-046-01 |
| R10 | README.md version-table row added before v10.0 tag → Check 4 warns | CI Check 4 dev-branch tolerance | Check 4 already tolerates "dev" branches (validate-pack.py §138–184); S-02 ships the row while still on v10-dev, merge+tag follows per §5.7 |
| R11 | audit-methodology rule 15 decision (C-045-04) made without reading current rule 15 text | Skipped step | Gate A blocker: decision must be recorded in phase-3 review log |
| R12 | CI workflow file (`.github/workflows/validate-pack.yml`) not reviewed after new checks added | Passive assumption | Gate E explicit confirmation that workflow invokes `python3 scripts/validate-pack.py` and picks up all nine checks |
| R13 | OT migration (Phase 6) exposes a bug that could not be caught on fixture | Real-world state differs from fixture | Rollback (Part 6 §6.7) available; any bug becomes a BD for v10.1 |

---

## 15. Open unknowns (for Phase 3 developer approval before Phase 4 begins)

1. **Exact content of `PROMPT-TEMPLATES.md` at v9.3 tag.** The
   per-agent files in C-046-01 must be produced by splitting this
   file. The implementer uses the current HEAD on v10-dev (which is
   v9.3 + v10 design commits unrelated to PROMPT-TEMPLATES.md — should
   be identical to v9.3 content for this file). If v10-dev has
   unexpectedly modified PROMPT-TEMPLATES.md, reset via
   `git show v9.3:supporting-docs/PROMPT-TEMPLATES.md` as ground truth.
2. **Exact roster order for Check 7.** Pack roster in PM-CHAT.md (C-046-04)
   must be alphabetical vs. grouping-by-phase. Part 5 §5.3 shows a
   canonical format. Implementer follows §5.3 exactly.
3. **Codex TOML format for auditor-architecture capabilities bullet.**
   Part 3 §3.7 describes "plain-bullet inside
   `developer_instructions = """…"""`". Implementer confirms current
   Codex file structure permits triple-quoted string insertion without
   re-parsing adjacent strings.
4. **audit-methodology rule 15 decision (§11 above).** Must be made
   before Gate A.
5. **OT project location and current state.** Phase 6 assumes OT is
   on v9.3; implementer confirms before Phase 4 begins.

Each unknown is either resolved in the commit where it surfaces or
becomes a `fix:` commit on v10-dev before the next gate.

---

## 16. Summary — ready-to-execute commit list

Total new commits on v10-dev: **~28** (plus conditional C-045-04,
plus any `fix:` commits during Phase 4, plus 3 ship commits in Phase 5).

| # | ID | Phase | Gate | Message |
|---|---|---|---|---|
| 1 | C-045-01 | 1 | A | feat: v10 — BD-045 capabilities pattern in trinity files |
| 2 | C-045-02 | 1 | A | feat: v10 — BD-045 capabilities rules in apple / python / architecture-review skills |
| 3 | C-045-03 | 1 | A | feat: v10 — BD-045 capabilities scope in auditor-architecture (trio) |
| 4 | C-045-04 | 1 | A | feat: v10 — BD-045 audit-methodology rule 15 capabilities extension *(conditional)* |
| 5 | C-046-01 | 2a | B | feat: v10 — BD-046 per-agent prompt files under docs/pack/prompts/ |
| 6 | C-046-02 | 2a | B | feat: v10 — BD-046 validate-pack.py Check 6 prompts-directory format |
| 7 | C-046-03 | 2b | C | feat: v10 — BD-046 trinity docs/pack row and custom agents sub-section |
| 8 | C-046-04 | 2b | C | feat: v10 — BD-046 PM-CHAT.md pack roster and custom-agent workflow |
| 9 | C-046-05 | 2b | C | feat: v10 — BD-046 PLATFORM-SKILLS.md custom sections |
| 10 | C-046-06 | 2b | C | feat: v10 — BD-046 pm-startup skill drops PROMPT-TEMPLATES.md RAG entry |
| 11 | C-046-07 | 2b | C | docs: v10 — BD-046 project-template/README.md PROMPT-TEMPLATES sweep *(skip if no matches)* |
| 12 | C-046-08 | 2b | C | feat: v10 — BD-046 METHODOLOGY.md Procedure 5 and 5-R |
| 13 | C-046-09 | 2b | C | docs: v10 — BD-046 annotate V9 design records with supersession notes |
| 14 | C-046-10 | 2b | C | docs: v10 — BD-046 supporting-docs PROMPT-TEMPLATES sweep |
| 15 | C-046-11 | 2b | C | feat: v10 — BD-046 validate-pack.py Checks 7 pack roster and 8 reserved x- prefix |
| 16 | C-044/046-01 | 2c | D | feat: v10 — BD-044 scripts/lib/detect.sh shared detection library |
| 17 | C-046-13 | 2c | D | feat: v10 — BD-046 merge-platform-skills.py helper |
| 18 | C-046-14 | 2c | D | feat: v10 — BD-046 merge-trinity.py helper |
| 19 | C-046-15 | 2c | D | feat: v10 — BD-046 migrate-v9-to-v10.sh migration script |
| 20 | C-046-16 | 2c | D | docs: v10 — BD-046 MIGRATION-v9-to-v10.md guide |
| 21 | C-044-02 | 3 | E | feat: v10 — BD-044 init-project.sh with detection and preview-and-confirm |
| 22 | C-044-03 | 3 | E | docs: v10 — BD-044 SETUP-NEW.md new-project guide |
| 23 | C-044-04 | 3 | E | docs: v10 — BD-044 SETUP-EXISTING.md existing-project guide |
| 24 | C-044-05 | 3 | E | feat: v10 — BD-044 QUICKSTART.md three-path router |
| 25 | C-044-06 | 3 | E | docs: v10 — BD-044 README.md repository layout for v10 |
| 26 | C-044-07 | 3 | E | feat: v10 — BD-046 delete supporting-docs/PROMPT-TEMPLATES.md |
| 27 | C-044-08 | 3 | E | feat: v10 — BD-044 validate-pack.py Check 9 init-project structure |
| — | (any `fix:` commits from Gates D/E/F) | 3/4 | F | fix: <description> |
| 28 | S-01 | 5 | Ship | docs: v10 — CHANGELOG.md v10.0 entry |
| 29 | S-02 | 5 | Ship | docs: v10 — README v10.0 version table; V10-PREDESIGN supersession |
| 30 | S-03 | 5 | Ship | docs: v10 — BACKLOG BD-044 / BD-045 / BD-046 Resolved at v10.0 |

After S-03: merge `v10-dev` into `main`, tag `v10.0`, move `v10`
floating tag, push all. Ship complete.

---

*End of Phase 3 Implementation Plan.*
