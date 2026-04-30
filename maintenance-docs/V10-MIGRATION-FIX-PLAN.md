# V10 Migration Fix Plan — BD-059

**Status:** Pack-planner output. Read-only audit + sequencing only.
**Author:** pack-planner session, 2026-04-30.
**Inputs:** `BACKLOG.md` BD-059; `maintenance-docs/V10-MIGRATION-FIX-DESIGN.md`
(architect, 1071 lines); user decisions on OQ-1..OQ-8; OT post-migration
evidence; current pack state at HEAD `e07c318`.
**Output of this document feeds:** Pack Chat commit-by-commit execution on
`main` (no version bump per BD-059 framing; v10.0 has not reached any
production project except OT, which is in a destroyed state and will be
reverted + re-run as the end-to-end verification per OQ-8).

This plan covers eleven commits in five groups separated by six approval
gates, ending with the OT revert-and-rerun verification and an audit-cycle
decision point.

---

## Part 1 — Goal, BD-059 mapping, user-decision absorption

### 1.1 Goal restatement

v10's `migrate-v9-to-v10.sh` and its merge helpers must preserve project
customization across the **full audited surface area** (Appendix A of the
architect's design — 22 file classes), produce a **truthful per-file
disposition report**, surface conflicts as `.v9-customized` sidecars
alongside the migrated files, and gain CI coverage that would have caught
the v10.0 release defect. METHODOLOGY.md must be reshaped so one-shot /
migration-scoped / kickoff-scoped procedures move out of it, with all
references updated. Tool-level configuration must reach **trinity
parity** across all three tools — Claude `.claude/settings.json`,
Codex `.codex/config.toml` + `.codex/requirements.toml`, and Gemini
`.gemini/settings.json` + `.gemini/.env` (the latter two NEW per user
decision 2026-04-30 folding the Gemini gap into BD-059, not deferring
to BD-060). After the fix lands and is approved, OT is reverted from its
backup and the fixed migration is re-run; a Pack Chat audit cycle then
decides whether a further architect/planner cycle is needed.

### 1.2 BD-059 success-criterion → plan-step mapping

| BD-059 criterion | Addressed by |
|---|---|
| Audit covers every migration touchpoint plus indirect blast radius | Architect Part 1 (already done; this plan inherits Appendix A); Commit C2 (audit referenced in `MIGRATION-v9-to-v10.md` updated table) |
| Design preserves customization across full surface without retroactive marker adoption | Commits C2 (three-way + classifier helpers) + C3 (migration script S1–S6 rewrite) + C4 (structured-config merge helpers + K3 inclusion) |
| Verification gap (§4.6) closure with realistic v9.3 fixture | Commit C5 (three fixtures + `scripts/test-migration.sh`) + Commit C6 (`validate-pack.py` new checks) |
| `validate-pack.py` gains coverage that would have caught BD-059 | Commit C6 (`check_three_way_helper_present`, `check_merge_helpers_consistent`, `check_disposition_table_documented`, `check_migration_test_runs_clean`, plus extension to `check_init_project_structure`) |
| Post-fix re-run on freshly reverted OT preserves customization, report is truthful | End-to-end verification in Part 5 (after Commit C11), tied to OQ-8 |
| OQ-3 user decision: relocate one-shot / migration / kickoff procedures out of METHODOLOGY | Commit C7 (relocation) + Commit C8 (cross-reference sweep) + Commit C9 (trinity + PLATFORM-SKILLS + PM-CHAT pointer updates) |
| OQ-6(a) user decision: `x-` prefix convention for skill-dir / agent-dir / scripts siblings | Commit C9 (documentation insertions) + Commit C3 + C10 (`x-` respect in deletion sites) |
| OQ-6(b) user decision: every deletion site respects `x-` prefix | Commit C10 (deletion-site sweep — migration script, init-project.sh, add-capability.sh) |
| OQ-7 user decision: Codex `requirements.toml` parallel to settings.json + Gemini parity (folded into BD-059 per user decision 2026-04-30) | Commit C4 (K3 inclusion in S3) + Commit C11 (cross-tool capability parity audit + parallel additions to Codex AND Gemini: `.codex/config.toml` `[agent_capabilities]`, `.gemini/.env` `AGENT_CAPABILITIES`, `.gemini/settings.json` MCP block; Codex MCP parity pending `V10-CODEX-MCP-RESEARCH.md`) |
| Trinity rule compliance | Commits C2, C3, C9, C11 (every change to one of the three is co-located with parallel changes to the other two) |

### 1.3 User-decision absorption (eight OQs)

- **OQ-1 (sidecars).** Sidecars are `<file>.v9-customized` **alongside** the
  migrated file, **not gitignored**. Procedure (the renamed Procedure 5-C
  per OQ-3) deletes them as its final step. **No `.gitignore` edit
  required.**
- **OQ-2 (`scripts/restore-from-backup.sh`).** Author it. Used in Part 5
  end-to-end verification (revert OT to v9.3 baseline before re-running
  fixed migration). Lives in pack `scripts/`. Inverts the
  `$BACKUP_DIR/`-flat layout (e.g., `docs-pack-PROMPT-TEMPLATES.md` →
  `docs/pack/PROMPT-TEMPLATES.md`).
- **OQ-3 (procedure naming + scope expansion).** Naming letter chosen:
  **`Procedure 5-C`** ("Customization reconciliation"). Architect leaned
  this way; we adopt it. **Major scope expansion absorbed:** one-shot,
  migration-scoped, and kickoff-scoped procedures are removed from
  METHODOLOGY.md and relocated to a new pack-shipped doc (see Commit C7
  for the new home). METHODOLOGY retains a one-line pointer per
  relocated procedure for discoverability. The relocated set is the
  **full** post-sweep set (Procedure 5, 5-R, 5-S, 7, plus the new 5-C);
  Procedure 6 is kept in METHODOLOGY (it is a normal recurring
  capability-addition workflow, not one-shot — see §1.4 for justification).
- **OQ-4 (`## Project addenda` ordering).** Lands in **Commit C9** —
  *before* the migration script's S5 rewrite is exercised against a
  customized fixture in C5/C6 (which would otherwise have nowhere to
  land Procedure 5-C-reconciled content). Sequencing rationale:
  C9 ships the trinity-template change + reconciliation home. C5's
  fixture builders use the C9 template shape so future projects
  initialize with the addenda H2 in place.
- **OQ-5 (classifier in `init-project.sh --existing`).** **Augment, not
  replace.** Reasoning: `init-project.sh --existing` already runs
  language-detection-driven *conditional removals* (init-project.sh
  lines 466–496) but does **not** preserve project customization
  against the trinity/PM-CHAT/configs surface; if a developer runs
  `init-project.sh --existing` against a project that already has a
  pack install, the same wholesale-overwrite class of bug exists.
  The four-case classifier is wired into `init-project.sh` for the
  same eight file classes the migration touches (C1–C3, D1–D2, K1, K2,
  K3, K4) when the script detects an existing pack install. Lands in
  **Commit C3** (same commit as migration-script rewrite, since both
  use the shared helper). Failure to do so leaves a parallel known
  bug under the `--existing` path.
- **OQ-6(a) (skill-dir / sibling-file `x-` prefix convention + doc home).**
  The convention is: project-added files in any pack-controlled directory
  (`.{tool}/agents/`, `.{tool}/skills/<dir>/`, `scripts/`,
  `docs/pack/prompts/`) **must use the `x-` prefix**. Documentation
  homes:
  - **Primary:** the new relocated-procedures doc (Commit C7) gets a
    `## Project file conventions in pack-controlled directories`
    section.
  - **Trinity:** `## Skill loading` and the `### Custom agents`
    sub-section in CLAUDE.md / AGENTS.md / GEMINI.md gain a one-line
    pointer to the new doc (parallel edit per trinity rule — Commit C9).
  - **PLATFORM-SKILLS.md:** the `## Custom agents` / `## Custom skills`
    project-owned-region preamble names the `x-` prefix explicitly
    (Commit C9).
  - **PM-CHAT.md:** the "Custom files via Procedure 5 only" bullet
    (line 173–177) is updated to name the `x-` prefix and the new
    doc home (Commit C9).
- **OQ-6(b) (deletion sites must respect `x-` prefix).** Audited
  deletion sites (read-only sweep, this plan):
  - `scripts/migrate-v9-to-v10.sh:84` — `rm -rf .pack-migration-backup`
    (out of scope: backup dir, not a pack-controlled location).
  - `scripts/migrate-v9-to-v10.sh:197` — `rm "$dst_dir/$name"` (S1
    agents) — **already respects `x-`** because the surrounding loop
    iterates pack-source files only; no fix needed but pin the
    behaviour with a comment + test fixture (Commit C5).
  - `scripts/migrate-v9-to-v10.sh:227` — `rm -rf "$dst_dir/$skill_name"`
    (S2 skills) — **needs fix**: today this `rm -rf`s the entire skill
    dir then re-creates with only `SKILL.md`, deleting any `x-` siblings
    in the skill dir. Architect Part 3.8 calls this out. Fixed in
    Commit C3 (skill-dir backup + selective `SKILL.md`-only replace,
    siblings preserved; `x-*` files in dir explicitly preserved per
    OQ-6(a) convention).
  - `scripts/migrate-v9-to-v10.sh:393` — `rm "$proj_file"`
    (PROMPT-TEMPLATES.md S6) — already respects intent (file is
    pack-roster, not project-added); no fix.
  - `scripts/init-project.sh:466,471,481,491,496` — conditional
    language-driven removals of pack-roster files
    (`pyproject.toml`, `bootstrap-python.sh`, `proto/`, `server/`,
    etc.). **Today these match by exact filename and never glob into
    `x-*` territory** (pack roster filenames are fixed). Add explicit
    `x-` skip guards (Commit C10) so a future refactor that switches
    to glob-based removal cannot regress the contract.
  - `scripts/test-detect.sh:24` — `rm -rf "$FIXTURE_BASE"` — fixture
    cleanup; out of scope.
  - `scripts/add-capability.sh` — no deletion sites today (verified
    via grep). Add a regression-guarding comment block (Commit C10)
    that future deletion sites must respect the `x-` convention.
- **OQ-7 (Codex `requirements.toml` v10 update + cross-tool parity).**
  Audited tool-config state at HEAD:
  - `.claude/settings.json` (44 lines) — has `permissions`, `hooks`,
    `env.AGENT_CAPABILITIES` (the v10 capabilities-pattern roster),
    `env.XCODE_SCHEME`, `env.XCODE_DESTINATION`.
  - `.codex/config.toml` (5220 bytes) — has agent registry, profile
    sections, model providers; **no v10 capabilities-pattern roster
    surfaced**.
  - `.codex/requirements.toml` (16 lines) — platform-agnostic policy
    flags only; no v10 additions.
  - `.gemini/` — only `agents/` directory; **no `settings.json`-equivalent
    config file shipped today**. **UPDATED 2026-04-30:** user decision
    folds Gemini parity into BD-059 (no BD-060). The plan's parity
    work for OQ-7 now spans **all three tools**: Codex parity (existing
    Codex-against-Claude work) PLUS Gemini config-file authorship from
    scratch, sourced from `V10-GEMINI-CONFIG-RESEARCH.md` (Gemini
    reads `.gemini/settings.json` JSON + adjuncts including
    `.gemini/.env` for env vars; per Q4 decision = Option A,
    `AGENT_CAPABILITIES` lands in `.gemini/.env`).
  - **What lands in Commit C11:** (1) extend `.codex/config.toml`
    with the v10 `[agent_capabilities]` table mirroring
    `env.AGENT_CAPABILITIES` from settings.json — TOML format. (2)
    update `.codex/requirements.toml` with v10-shipped policy flag
    additions if any (audit `git diff v9.3 main -- project-template/.codex/requirements.toml`
    in Commit C11 prep — if the file is unchanged at v10.0, the K3
    audit gap closes via S3 inclusion alone). (3) K3 added to the
    migration script S3 touched-file list with TOML key-merge logic
    (architect 3.7). (4) NEW `.gemini/.env` shipping `AGENT_CAPABILITIES`
    parity (KEY=VALUE format) and added to S3 with `.env` line-merge.
    (5) NEW `.gemini/settings.json` shipping the MCP-server block
    parallel to `.mcp.json.example` (Gemini has first-class MCP
    support per `V10-GEMINI-CONFIG-RESEARCH.md` Part 4); JSON
    key-merge via `merge-json.py`. (6) Codex MCP parity decision
    pending `V10-CODEX-MCP-RESEARCH.md` (in flight): if Codex
    supports MCP, ship parallel config; if not, document the gap as
    a tool capability gap in INSTALL-PROCEDURES.md. (7) NO BD-060
    BACKLOG entry — Gemini parity criteria are part of BD-059 and
    BD-059 does not resolve until they land.
- **OQ-8 (OT remediation).** Option 1: revert + re-run, sequenced as
  Part 5 of this plan. After verification, the Pack Chat performs an
  audit cycle and decides "done" or "another architect/planner cycle."

### 1.4 Procedure relocation scope (full sweep, not just architect's four)

A full read of `supporting-docs/METHODOLOGY.md` H3 procedures (line 1019,
1067, 1086, 1104, 1127, 1243, 1267, 1294, 1335) classifies each:

| Procedure | Title | Trigger | Classification | Relocate? |
|---|---|---|---|---|
| 1 | Phase gate check | Every phase | Recurring | Keep in METHODOLOGY |
| 2 | Post-session processing | Every coder completion | Recurring | Keep in METHODOLOGY |
| 3 | Orphan audit | Every phase gate | Recurring | Keep in METHODOLOGY |
| 4 | Resolution procedure | Item Unblocked + approved | Recurring | Keep in METHODOLOGY |
| 5 | Custom agent and skill workflow (5.1–5.6) | Custom file lifecycle | One-shot per custom file (kickoff/post-kickoff) | **Relocate** |
| 5-R | Prompt reconciliation after migration | `_v9-backup.md` exists | Migration-only | **Relocate** |
| 5-S | Post-migration housekeeping | `postrun-pending` sentinel | Migration-only | **Relocate** |
| 5-C | (NEW) Customization reconciliation | `.v9-customized` sidecars exist | Migration-only | **Born in new home** |
| 6 | Adding a pack-supported capability | `add-capability.sh` invocation | **Recurring** (not one-shot — runs each time the project gains a new capability) | Keep in METHODOLOGY |
| 7 | Kickoff auto-discovery and install-check | `Variant: kickoff` paste | Kickoff-only (one-shot per project) | **Relocate** |

Net relocations: Procedures 5, 5-R, 5-S, 5-C (new), 7. Five procedures
move to a new home. **Procedure 6 stays.** Justification: 6 fires every
time `add-capability.sh` runs, which is a recurring project-life event,
not a single-shot kickoff or migration moment. The user's framing is
"one-shot, migration-scoped, or kickoff-scoped"; 6 fits none.

### 1.5 New home for relocated procedures

A single new pack-shipped doc:
**`supporting-docs/INSTALL-PROCEDURES.md`** (canonical at the pack
repo) → copied to **`docs/pack/INSTALL-PROCEDURES.md`** at install time
(by `init-project.sh`) and at migration time (by
`migrate-v9-to-v10.sh` — new S5 sub-step).

Rationale for a single doc, not multiple:

- **Discoverability.** A single name is easy to remember; pm-startup
  Step 0 sentinel routing (today: METHODOLOGY Procedure 5-S / 5-R)
  becomes "INSTALL-PROCEDURES.md Procedure 5-S / 5-R."
- **Cross-tool parity.** Single file copied identically across the
  three tool surfaces (the procedures are PM-chat-driven, not
  tool-specific).
- **RAG ingest.** mcp-local-rag indexes `docs/pack/` by default;
  one new file is one index entry.
- **Locality.** Procedures 5 / 5-R / 5-S / 5-C / 7 are
  install/migration/kickoff plumbing — they belong together.

The doc title and structure: `# Pack install, migration, and kickoff
procedures` with H2 sections per procedure. Procedure 5 keeps its
sub-procedures 5.1–5.6.

METHODOLOGY.md retains a one-line pointer per relocated procedure under
a new H3 `### Procedure X — [title] (relocated)` stub:

```
### Procedure 5 — Custom agent and skill workflow (relocated)
See `docs/pack/INSTALL-PROCEDURES.md` § Procedure 5.
```

This satisfies the user's "METHODOLOGY may carry a one-line pointer"
constraint and preserves cross-references that cite "METHODOLOGY
Procedure 5" directly (they still resolve, they just redirect).

---

## Part 2 — Touchpoint inventory

This section enumerates every file the implementation touches.
Architect's audit (Appendix A, 22 file classes) is inherited as-is for
the **migration-mechanism surface**. Beyond that, this plan adds new
touchpoints arising from the user decisions on OQ-3, OQ-6, and OQ-7.
Each new touchpoint is tagged **[OQ-3]**, **[OQ-6]**, or **[OQ-7]** so
the Pack Chat can audit completeness against the user's expanded
success criteria.

### 2.1 New helpers and merge libraries (architect's design)

| Path | Purpose | Commit |
|---|---|---|
| `scripts/lib/three-way.sh` | Four-case classifier (BASE / OURS / THEIRS) | C2 |
| `scripts/merge-json.py` | JSON key-merge for K1, K4 | C4 |
| `scripts/merge-toml.py` | TOML table-merge for K2, K3 | C4 |
| `scripts/merge-trinity.py` (refactor) | Wrap with classifier; integrate sidecar disposition | C3 |
| `scripts/merge-platform-skills.py` (refactor) | Wrap with classifier; sidecar on Pattern P fallback | C3 |
| `scripts/restore-from-backup.sh` | Invert flat backup layout (OQ-2) | C2 |
| `scripts/test-migration.sh` | Run fixture-based migration verification | C5 |
| `scripts/migrate-v9-to-v10.sh` (rewrite) | Disposition-driven S0–S7 pipeline | C3 |
| `scripts/init-project.sh` (augment) | Wire classifier on `--existing` path (OQ-5) | C3 |

### 2.2 Fixtures (architect's design)

| Path | Purpose | Commit |
|---|---|---|
| `maintenance-docs/test-fixtures/build-migration-fixture.sh` | Fixture builder (script) | C5 |
| `maintenance-docs/test-fixtures/migration-v9.3-empty/` | Trivial-case fixture | C5 |
| `maintenance-docs/test-fixtures/migration-v9.3-customized/` | OT-shape fixture (primary regression target) | C5 |
| `maintenance-docs/test-fixtures/migration-v9.3-marker-convention/` | Marker-already-present fixture | C5 |

### 2.3 `validate-pack.py` additions (architect Part 6)

| Check | Purpose | Commit |
|---|---|---|
| `check_three_way_helper_present` | Helper exists + sourced | C6 |
| `check_merge_helpers_consistent` | Migration uses helpers per audit table | C6 |
| `check_disposition_table_documented` | MIGRATION-v9-to-v10.md has table | C6 |
| `check_migration_test_runs_clean` | `--quick` fixture runs in CI | C6 |
| `check_init_project_structure` (extend) | Cover new fixture dir + test-migration.sh | C6 |
| `check_install_procedures_doc_present` **[OQ-3 NEW]** | Asserts `supporting-docs/INSTALL-PROCEDURES.md` exists, has the five required H2 procedure sections (5, 5-R, 5-S, 5-C, 7), and is referenced by `init-project.sh` + `migrate-v9-to-v10.sh` for project-side install | C6 |
| `check_methodology_pointers_consistent` **[OQ-3 NEW]** | For each of Procedures 5 / 5-R / 5-S / 5-C / 7, METHODOLOGY.md has a one-line pointer stub matching the relocated doc; warns if the procedure body still appears in METHODOLOGY (relocation regression guard) | C6 |
| `check_x_prefix_documented` **[OQ-6 NEW]** | The new INSTALL-PROCEDURES.md `## Project file conventions` section is present and trinity files name the `x-` convention (cross-doc consistency) | C6 |
| `check_tool_config_capability_parity` **[OQ-7 NEW]** | `.claude/settings.json` `env.AGENT_CAPABILITIES` set equals the capability roster declared in `.codex/config.toml`'s `[agent_capabilities]` table; future Gemini config (when shipped) included | C6 |

### 2.4 Migration script touchpoint expansion

Today `migrate-v9-to-v10.sh` touches files at S0–S7 stages. After C3, the
script's touched-file universe gains:

- **K3** (`.codex/requirements.toml`) added to S3 [OQ-7].
- **`docs/pack/INSTALL-PROCEDURES.md`** added to S5 (canonical from pack
  `supporting-docs/INSTALL-PROCEDURES.md`) [OQ-3].
- **Disposition record file** `$BACKUP_DIR/dispositions.tsv` written by
  every stage; replaces `status.txt` (architect 4.2).
- **Three-way diff dir** `$BACKUP_DIR/diffs/` populated by the
  classifier helper (architect 3.2).
- **Sidecar files** `<file>.v9-customized` written alongside affected
  files in the project tree per disposition table (architect 3.11).

### 2.5 Doc surface — relocations + cross-references [OQ-3]

**Files written or moved in C7 (relocation):**

| Path | Operation | Notes |
|---|---|---|
| `supporting-docs/INSTALL-PROCEDURES.md` | NEW (full body) | Hosts Procedures 5, 5-R, 5-S, 5-C (new), 7 |
| `supporting-docs/METHODOLOGY.md` | EDIT | Strip Procedures 5, 5-R, 5-S, 7; replace each with a one-line pointer stub; renumber Part headings if the procedure removal collapses sections (audit during Commit C7) |
| `project-template/docs/pack/METHODOLOGY.md` | EDIT (parallel) | Same edits — this is the project-side copy of METHODOLOGY canonical at v10.0 |

**Files with stale cross-references that must update (sweep result):**

| Path | Stale text (fragment) | Updated text | Commit |
|---|---|---|---|
| `project-template/docs/pack/PM-CHAT.md:173–177, 200, 209` | "METHODOLOGY.md Procedure 5" | "INSTALL-PROCEDURES.md Procedure 5" | C8 |
| `project-template/docs/pack/PM-CHAT.md:126` | "Procedure 5.5" reference | "INSTALL-PROCEDURES.md Procedure 5.5" | C8 |
| `project-template/docs/pack/PLATFORM-SKILLS.md:299, 310, 317, 327` | "Procedure 5 (METHODOLOGY.md Part 7)" | "Procedure 5 (INSTALL-PROCEDURES.md)" | C8 |
| `project-template/docs/pack/prompts/pm-chat.md:28, 84–85` | "METHODOLOGY.md Procedure 7" | "INSTALL-PROCEDURES.md Procedure 7" (note: pm-chat.md says it reads "directly, not via RAG, because order-sensitive" — preserve that constraint, just point to the new file) | C8 |
| `project-template/skills/pm-startup/SKILL.md:23–24` | "named METHODOLOGY procedure(s)" | "named INSTALL-PROCEDURES procedure(s)" | C8 |
| `project-template/CLAUDE.md:438` (and parallel `AGENTS.md:319`, `GEMINI.md:369`) | "Project-specific agents created via Procedure 5. See [METHODOLOGY]" | "Project-specific agents created via Procedure 5. See `docs/pack/INSTALL-PROCEDURES.md`" | C9 (trinity rule) |
| `supporting-docs/SETUP-EXISTING.md:152` | "(METHODOLOGY.md Procedure 7)" | "(INSTALL-PROCEDURES.md Procedure 7)" | C8 |
| `supporting-docs/MIGRATION-v9-to-v10.md` (multiple lines: 53, 80, 151, 180, 233, 235, 243, 247, 251, 254, 257, 333, 339, 429, 511, 555) | "Procedure 5-R / 5-S / 5.4 / 6 (METHODOLOGY.md)" | "(INSTALL-PROCEDURES.md)" except Procedure 6 references which keep "METHODOLOGY.md" | C8 |
| `scripts/migrate-v9-to-v10.sh:441, 445, 455, 457` | "Procedure 5-S … METHODOLOGY" / "Procedure 5-R" | Updated to point to INSTALL-PROCEDURES.md | C8 |
| `scripts/init-project.sh:588` | "Procedure 5-R" comment | Updated pointer | C8 |
| `scripts/add-capability.sh:289, 435, 469` | "Procedure 6" — **stays in METHODOLOGY**, not relocated | No change required (verify) | C8 audit |
| `BACKLOG.md` resolved entries (BD-052, BD-053, BD-046, BD-048) | Historical — refer to procedures in METHODOLOGY at time of resolution | **Do not edit history**; these stay as-written. The pointer stubs in METHODOLOGY make them resolvable. | (none) |
| `CHANGELOG.md` | Resolved entries reference METHODOLOGY procedures | **Do not edit history**; same reasoning | (none) |
| `README.md:32` (v10.0 row) | "Procedure 7 kickoff … Procedure 5-S post-migration" | Add a v10.0.1-style addendum or a CHANGELOG entry; **do not rewrite the v10.0 row**. The CHANGELOG gains a fresh entry for the BD-059 fix that names the relocation | C8 |

### 2.6 Trinity template + PM-CHAT changes [OQ-4, OQ-6]

| Path | Edit | Commit |
|---|---|---|
| `project-template/CLAUDE.md` | Add `## Project addenda` H2 marker section near the bottom (architect 3.2 OQ-4); update `### Custom agents` to name the `x-` convention and point to `docs/pack/INSTALL-PROCEDURES.md` (OQ-6) | C9 |
| `project-template/AGENTS.md` | Same as CLAUDE.md (trinity rule) | C9 |
| `project-template/GEMINI.md` | Same as CLAUDE.md (trinity rule) | C9 |
| `project-template/docs/pack/PM-CHAT.md` | Wrap project-mutable region (H1, Role para, "Additional project documents" list) in `<!-- BEGIN project-owned -->` / `<!-- END project-owned -->` markers (architect 3.3); update the Procedure 5 / 5.4 references (already in §2.5); update "Custom files via Procedure 5 only" bullet to name the `x-` convention (OQ-6) | C9 |

### 2.7 Tool-config parity additions [OQ-7] — UPDATED 2026-04-30

User decisions on 2026-04-30 expanded OQ-7 scope: Gemini-side parity is
now **folded into BD-059** (not deferred to BD-060). BD-059 success
criterion adds: trinity rule applies to per-tool tool-level
configuration; AGENT_CAPABILITIES parity on Gemini via `.gemini/.env`
(Option A from `V10-GEMINI-CONFIG-RESEARCH.md` Q4); MCP server
configuration parity across all three tools (Claude / Gemini already
have it; Codex MCP support state is being verified by
`V10-CODEX-MCP-RESEARCH.md`, in flight).

| Path | Edit | Commit |
|---|---|---|
| `project-template/.codex/config.toml` | Add `[agent_capabilities]` table mirroring `.claude/settings.json` `env.AGENT_CAPABILITIES` set | C11 |
| `project-template/.codex/requirements.toml` | Audit against v9.3 → v10 diff; add any missing v10 policy flags. If unchanged, this entry collapses to "no edit, K3 still added to S3 touched-file list" | C11 |
| `project-template/.gemini/.env` (NEW) | Ship `.env` file with `AGENT_CAPABILITIES=...` mirroring Claude's set; format is plain `KEY=VALUE` (Gemini reads `.env` per `V10-GEMINI-CONFIG-RESEARCH.md` Part 1) | C11 |
| `project-template/.gemini/.env.example` (NEW, optional) | Match the example-pattern Claude uses with `settings.local.example.json` if needed for project copies — confirm during C11 whether `.env` ships directly or only as `.example` | C11 |
| `project-template/.mcp.json.example` | No edit (already shipped; Claude side complete) | — |
| `project-template/.codex/config.toml.example` (NEW) | Ship as sibling to live `config.toml` (matches `.mcp.json.example` pattern); contains commented `[mcp_servers.local-rag]` STDIO block mirroring Claude's example, plus note about Codex's project-trust gate. Per `V10-CODEX-MCP-RESEARCH.md` Part 1: Codex supports MCP via `[mcp_servers.<name>]` tables in `config.toml` — both STDIO (`command`) and Streamable HTTP (`url`, gated by `experimental_use_rmcp_client`). v10 ships STDIO only for now (HTTP transport stability flagged in research Part 6 OQ-1) | C11 |
| `project-template/.gemini/settings.json` (NEW) | Ship a minimal `settings.json` that includes the MCP-server block parallel to `.mcp.json.example`; v10.0 currently ships nothing in `.gemini/` for tool-level config — closing this gap is part of BD-059's trinity-rule criterion | C11 |
| `scripts/migrate-v9-to-v10.sh` (S3) | Add K3 (`.codex/requirements.toml`), and the new Gemini files (`.gemini/.env`, `.gemini/settings.json`) to S3 touched-file list with appropriate per-format merges (`.env` line-merge, JSON key-merge via `merge-json.py` from architect's design) | C3 (already covered) |
| `BACKLOG.md` | NO BD-060. Gemini parity folded into BD-059 success criteria (commit C1 BD-059 update already lands the criterion expansion) | — |

### 2.8 Documentation of new conventions [OQ-6]

| Path | Insertion | Commit |
|---|---|---|
| `supporting-docs/INSTALL-PROCEDURES.md` (NEW) | New `## Project file conventions in pack-controlled directories` section before Procedure 5; names `x-` prefix for project-added files in `.{tool}/agents/`, `.{tool}/skills/<dir>/`, `scripts/`, `docs/pack/prompts/`, plus skill-dir siblings | C7 |
| `project-template/docs/pack/PM-CHAT.md` | Update bullet to name the `x-` prefix and point to the new doc | C9 (covered in §2.6) |
| Trinity (CLAUDE.md / AGENTS.md / GEMINI.md) | `## Skill loading` and `### Custom agents` sub-section gain one-line pointer | C9 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | Project-owned-region preamble names `x-` prefix explicitly | C9 |

### 2.9 Deletion-site audit additions [OQ-6(b)]

| Path | Site | Action | Commit |
|---|---|---|---|
| `scripts/migrate-v9-to-v10.sh` line 227 (S2 skills) | `rm -rf "$dst_dir/$skill_name"` then re-create with only `SKILL.md` | Replace with selective delete: only `SKILL.md` from pack roster, preserve `x-*` siblings + non-`SKILL.md` siblings | C3 |
| `scripts/init-project.sh` lines 466, 471, 481, 491, 496 | Conditional language-driven removals | Add explicit `[[ "$f" != x-* ]] || continue` guard before each `rm` (defensive, since today the matched filenames are pack-roster only, but the guard pins the contract) | C10 |
| `scripts/add-capability.sh` | (no current deletion sites) | Add a top-of-file convention comment block: any future deletion site here MUST respect `x-` prefix; covered by `validate-pack.py` cross-doc consistency check | C10 |
| New helper invariant (architect 3.9 + OQ-6 absorption) | All future deletion sites in pack scripts | Document in INSTALL-PROCEDURES.md `## Project file conventions` and add `validate-pack.py check_x_prefix_documented` | C7 + C6 |

### 2.10 Touchpoints added beyond architect's audit (summary)

The architect's design covers 22 file classes for the migration mechanism.
This plan adds the following file touches to satisfy the user-decision
expansions:

**[OQ-3] Procedure relocation surface (12 new touchpoints):**

1. NEW `supporting-docs/INSTALL-PROCEDURES.md`
2. NEW `project-template/docs/pack/INSTALL-PROCEDURES.md` (created at
   install/migration time by C3 wiring; in the pack repo it is
   created/copied from supporting-docs at every commit only via
   `init-project.sh` + `migrate-v9-to-v10.sh` — same model as METHODOLOGY)
3. EDIT `supporting-docs/METHODOLOGY.md` (procedure body strips +
   pointer stubs)
4. EDIT `project-template/docs/pack/METHODOLOGY.md`
5. EDIT `project-template/docs/pack/PM-CHAT.md` (cross-references)
6. EDIT `project-template/docs/pack/PLATFORM-SKILLS.md` (cross-references)
7. EDIT `project-template/docs/pack/prompts/pm-chat.md`
8. EDIT `project-template/skills/pm-startup/SKILL.md` (parallel edit
   across `.claude/skills/pm-startup/SKILL.md`,
   `.codex/skills/pm-startup/SKILL.md`,
   `.gemini/skills/pm-startup/SKILL.md` — three skill-tree copies of
   pm-startup; verify with sweep)
9. EDIT `supporting-docs/SETUP-EXISTING.md`
10. EDIT `supporting-docs/MIGRATION-v9-to-v10.md` (16+ line edits
    auditable in §2.5)
11. EDIT `scripts/migrate-v9-to-v10.sh` (4 line edits + new S5 sub-step
    that copies INSTALL-PROCEDURES.md to project)
12. EDIT `scripts/init-project.sh` (1 line edit + new install step that
    copies INSTALL-PROCEDURES.md to project)

**[OQ-6] `x-` prefix convention surface (8 new touchpoints):**

1. NEW section in `supporting-docs/INSTALL-PROCEDURES.md`
   (`## Project file conventions`)
2. EDIT trinity (CLAUDE.md, AGENTS.md, GEMINI.md) — three parallel
   edits
3. EDIT `project-template/docs/pack/PLATFORM-SKILLS.md` preamble
4. EDIT `project-template/docs/pack/PM-CHAT.md` "Custom files" bullet
5. EDIT `scripts/migrate-v9-to-v10.sh` S2 (skill-dir sibling preservation
   with `x-` respect)
6. EDIT `scripts/init-project.sh` (defensive `x-` guards on conditional
   removals)
7. EDIT `scripts/add-capability.sh` (convention comment block)
8. NEW `validate-pack.py check_x_prefix_documented`

**[OQ-7] Cross-tool capability parity surface (8 new touchpoints — UPDATED 2026-04-30):**

1. EDIT `project-template/.codex/config.toml` (add `[agent_capabilities]`)
2. EDIT (audit, possibly no-edit) `project-template/.codex/requirements.toml`
3. NEW `project-template/.gemini/.env` (AGENT_CAPABILITIES parity per
   user decision Q4 = Option A; folds into BD-059, not BD-060)
4. NEW `project-template/.gemini/settings.json` (MCP-server block parity
   with `.mcp.json.example` and Gemini's first-class MCP support)
5. NEW `project-template/.codex/config.toml.example` — Codex MCP
   parity (Codex supports MCP via `[mcp_servers.<name>]`; ships as
   `.example` sibling matching `.mcp.json.example` pattern; STDIO-only
   for v10 per `V10-CODEX-MCP-RESEARCH.md` Implementer guidance)
6. EDIT `scripts/migrate-v9-to-v10.sh` S3 (add K3 + new Gemini files
   to touched list with appropriate format merges)
7. EDIT `scripts/init-project.sh` (parallel addition: ship the new
   Gemini files to fresh projects)
8. NEW `validate-pack.py check_tool_config_capability_parity`

NOTE: BD-060 is **NOT created**. The Gemini gap is folded into BD-059's
success criteria per user decision 2026-04-30; the BD-059 BACKLOG entry
already includes the trinity-rule-for-tool-config criterion. The
prior "BD-060 entry" touchpoint listed in this section's previous
revision is removed.

**Total new touchpoints beyond architect:** 28 (was 25; +3 for Gemini
parity AGENT_CAPABILITIES + Gemini settings.json + init-project.sh
parallel addition).

---

## Part 3 — Commit sequence with approval gates

Eleven commits in five groups, separated by six approval gates. Every
intermediate commit leaves the pack in a working state with
`validate-pack.py` passing — see Part 4 for the per-commit validation
ledger.

**Approval gates:**

- **Gate G0** — *before any change* — Pack Chat presents this plan,
  user approves the sequence and decisions absorbed.
- **Gate G1** — *after C2 (helpers)* — user reviews the four-case
  classifier helper + restore-from-backup helper before code that
  *uses* them lands.
- **Gate G2** — *after C4 (migration script + structured-config
  helpers)* — user reviews the migration script rewrite before the
  fixture-based verification depends on it.
- **Gate G3** — *after C7 (procedure relocation)* — user reviews the
  new `INSTALL-PROCEDURES.md` and METHODOLOGY pointer stubs before
  the cross-reference sweep edits land.
- **Gate G4** — *after C9 (trinity + PM-CHAT + PLATFORM-SKILLS edits)*
  — user reviews the trinity-rule-symmetric edits before the
  fixture and validate-pack.py work commits.
- **Gate G5** — *after C11 (final commit, pre-verification)* — user
  approves the entire pack state on `main` before the OT
  revert-and-rerun verification (Part 5) executes.

### Group A — Foundations (helpers, no integration yet)

#### Commit C1 — Architect + planner + research output landing (Pack-Chat-only commit)

**Title:** `docs: BD-059 — design + plan + research for v10 migration preservation fix`

**Files touched:**

- `maintenance-docs/V10-MIGRATION-FIX-DESIGN.md` (NEW, architect output)
- `maintenance-docs/V10-MIGRATION-FIX-PLAN.md` (this file, NEW)
- `maintenance-docs/V10-GEMINI-CONFIG-RESEARCH.md` (NEW, docs-researcher output)
- `maintenance-docs/V10-CODEX-MCP-RESEARCH.md` (NEW, docs-researcher output — pending)
- `BACKLOG.md` — BD-059 success criteria expanded with trinity-rule-for-tool-config criterion (already landed pre-C1; Pack Chat edit on 2026-04-30)
- **NO BD-060 entry.** User decision 2026-04-30 folds the Gemini gap into BD-059's success criteria; closing the gap is required for BD-059 resolution.

**Dependencies:** None.

**Validation:** `validate-pack.py` passes (no source changes). BACKLOG
edits are Pack Chat-authored per repo rules.

**Approval gate flag:** **G0** (the plan itself is the approval
artifact).

#### Commit C2 — Helpers: three-way classifier + restore-from-backup

**Title:** `feat: v10 — BD-059 add three-way classifier and backup-restore helpers`

**Files touched:**

- `scripts/lib/three-way.sh` (NEW; architect 3.1 four-case classifier)
- `scripts/restore-from-backup.sh` (NEW; OQ-2 — inverts flat backup
  layout)
- `scripts/test-restore-from-backup.sh` (NEW; small unit test fixture
  for the inversion logic — written first per architect's
  test-fixture-driven approach)

**Dependencies:** C1 approved.

**Validation:** `validate-pack.py` passes (no caller of these helpers
yet, so static checks are unaffected). The two new helpers are
unit-test-runnable in isolation.

**Approval gate flag:** **G1** at end.

### Group B — Migration script + structured config merges

#### Commit C3 — Migration script rewrite + skill-dir sibling preservation + init-project.sh classifier wiring

**Title:** `feat: v10 — BD-059 disposition-driven migration; preserve skill-dir siblings; classifier in init-project.sh --existing`

**Files touched:**

- `scripts/migrate-v9-to-v10.sh` (rewrite S0–S7; integrate
  `scripts/lib/three-way.sh`; replace `status.txt` with
  `dispositions.tsv`; populate `$BACKUP_DIR/diffs/`; write
  `<file>.v9-customized` sidecars per disposition; **fix S2 skill-dir
  rm-rf to selective `SKILL.md` replace, preserving `x-*` and non-`SKILL.md`
  siblings per OQ-6**; updated S7 report renderer per architect Part
  4.1)
- `scripts/merge-trinity.py` (refactor: wrap with classifier; new
  fallback that writes `.v9-customized` sidecar instead of degrading
  to "Active-skills line only")
- `scripts/merge-platform-skills.py` (refactor: wrap with classifier;
  Pattern P fallback writes sidecar)
- `scripts/init-project.sh` (augment `--existing` path with classifier
  for C1–C3, D1–D2, K1–K4 file classes per OQ-5)
- `scripts/init-project.sh` (defensive `x-` skip guards on conditional
  removal lines per OQ-6(b)) — **cross-references C10's audit; landing
  the guards here keeps the migration commit and the init script's
  related fix in one logical change**

**Dependencies:** C2 (helpers) merged.

**Validation:** `validate-pack.py` passes (existing checks unchanged;
new validate-pack checks land in C6, but the new merge logic must be
covered by `scripts/test-detect.sh` and a smoke run that the pack
script still parses). Run `bash -n scripts/migrate-v9-to-v10.sh` and
`python3 -m py_compile scripts/merge-*.py` as local pre-commit checks.

**Approval gate flag:** None within group.

#### Commit C4 — Structured-config merge helpers + K3 inclusion

**Title:** `feat: v10 — BD-059 JSON/TOML merge helpers; .codex/requirements.toml in S3`

**Files touched:**

- `scripts/merge-json.py` (NEW; architect 3.7 — handles K1, K4)
- `scripts/merge-toml.py` (NEW; architect 3.7 — handles K2, K3)
- `scripts/migrate-v9-to-v10.sh` (S3 stage edited: add K3
  `.codex/requirements.toml` to touched list; replace wholesale `cp`
  with `merge-json.py` / `merge-toml.py` invocations)

**Dependencies:** C3 (migration script S3 already disposition-driven;
this commit only swaps the per-file write strategy from `cp` to
`merge-*`). Splitting C3 and C4 lets C3 compile cleanly even if the
JSON/TOML helpers slip; the wholesale `cp` remains the fallback in C3
and is replaced in C4.

**Validation:** `validate-pack.py` passes. New helpers run against
fixtures hand-built in `/tmp/` as a manual pre-commit check (full
fixture suite lands in C5).

**Approval gate flag:** **G2** at end.

### Group C — Procedure relocation + cross-reference sweep + trinity edits

#### Commit C7a — Pack-roster trinity comparator (BD-059 scope expansion 2026-04-30)

**Title:** `feat: v10 — BD-059 trinity-rule comparator for pack-roster agent files`

**Files touched:**

- `scripts/compare-agent-trinity.py` (NEW) — comparator helper for
  pack-roster agent files. Parses Claude .md (YAML frontmatter +
  body), Codex .toml (`developer_instructions` field), Gemini .md
  (frontmatter + body); normalizes whitespace + Markdown formatting;
  reports body divergence. `--strict` keeps formatting chars; default
  is lenient. `--all` iterates every pack-roster agent.
- `scripts/test-compare-agent-trinity.sh` (NEW) — 10 unit tests
  covering canonical 4 cases (identical, backtick-only, substantive,
  whitespace-only) plus auxiliary (missing variant, --all summary,
  name-field mismatch).
- `scripts/validate-pack.py` — adds Check 11 (informational) that
  invokes the comparator in `--all --summary-only` mode and reports
  the count of divergent agents. Informational because hard CI
  enforcement requires a trinity-asymmetry-by-design marker convention
  the pack does not yet have; the count is a regression signal until
  that convention lands.
- `maintenance-docs/V10-PROCEDURE-5-C-DRAFT.md` (NEW) — architect's
  full draft body of Procedure 5-C and sub-procedures, persisted as
  the design artifact for C7's authoring step.
- `maintenance-docs/V10-MIGRATION-FIX-PLAN.md` (this file) — minor
  edit to drop a stale BD-061 reference and document C7a.

**Dependencies:** C4 merged (Group B complete). Lands before C7
because Procedure 5-C.6 (authored in C7) references the comparator.

**Validation:** `validate-pack.py` PASSED (Check 11 informational,
existing 10 checks unchanged); `test-compare-agent-trinity.sh` 10/10;
`test-detect.sh` 34/34; `test-restore-from-backup.sh` 36/36;
comparator runs cleanly against the 16 pack-roster agents (8 currently
divergent, all in the auditor family with legitimate tool-specific
content per architect 3.8 — informational, not a CI failure).

**Approval gate flag:** None within group.

**Scope rationale:** OQ-5C-4 from the architect's Procedure 5-C draft
flagged that 5-C.6 cannot be performed reliably without a structured-diff
helper for pack-roster agent files (Codex TOML vs Claude/Gemini Markdown
make direct diff useless). Initially scoped as BD-061 candidate /
deferred; user decision 2026-04-30 folded the work into BD-059 because
"BD-059 is not done until everything works" — a procedure that requires
eyeballed cross-format diffing is theater. C7a ships the tool that makes
5-C.6 a reliable mechanical step.

#### Commit C7 — Relocate procedures to INSTALL-PROCEDURES.md; create Procedure 5-C

(commits C5 and C6 are out-of-order on purpose for sequencing; explained
below)

**Title:** `docs: v10 — BD-059 relocate Procedures 5/5-R/5-S/7 to INSTALL-PROCEDURES.md; add Procedure 5-C`

**Files touched:**

- `supporting-docs/INSTALL-PROCEDURES.md` (NEW, full body) — hosts
  Procedures 5 / 5.1–5.6 / 5-R / 5-S / **5-C (new)** / 7; new
  `## Project file conventions in pack-controlled directories`
  section per OQ-6(a)
- `supporting-docs/METHODOLOGY.md` (EDIT) — strip Procedures 5, 5-R,
  5-S, 7 bodies; replace each with a one-line pointer stub at the
  same H3 location (preserves anchor links for legacy references);
  Part 7 numbering audit
- `project-template/docs/pack/METHODOLOGY.md` (EDIT, parallel) —
  identical edit, since this is the v10 canonical project-side copy

**Dependencies:** C4 merged. Lands *after* the migration script work
because C5/C6 (next) depend on the new doc to be testable.

**Approval gate flag:** **G3** at end.

#### Commit C8 — Cross-reference sweep

**Title:** `docs: v10 — BD-059 update cross-references to INSTALL-PROCEDURES.md`

**Files touched:**

- `project-template/docs/pack/PM-CHAT.md` (lines 126, 173, 176, 200,
  202, 209)
- `project-template/docs/pack/PLATFORM-SKILLS.md` (lines 299, 310, 317, 327)
- `project-template/docs/pack/prompts/pm-chat.md` (lines 28, 84–85)
- `project-template/skills/pm-startup/SKILL.md`
- `.claude/skills/pm-startup/SKILL.md` (pack-repo copy used by pack agents)
- `.codex/skills/pm-startup/SKILL.md` (pack-repo copy)
- `.gemini/skills/pm-startup/SKILL.md` (pack-repo copy)
- `supporting-docs/SETUP-EXISTING.md` line 152
- `supporting-docs/MIGRATION-v9-to-v10.md` (16+ lines; full sweep per
  §2.5)
- `scripts/migrate-v9-to-v10.sh` lines 441, 445, 455, 457
- `scripts/init-project.sh` line 588 (Procedure 5-R comment)
- `CHANGELOG.md` — new entry under v10.x for the BD-059 fix that
  names the procedure relocation (Pack Chat edit; lands here so a
  reader of CHANGELOG sees the move)

**Dependencies:** C7 merged (so all cross-references resolve to a
file that exists at HEAD).

**Approval gate flag:** None within group.

#### Commit C9 — Trinity edit (`## Project addenda`) + `x-` prefix doc + PM-CHAT marker block

**Title:** `feat: v10 — BD-059 trinity ## Project addenda + x- prefix convention + PM-CHAT project-owned markers`

**Files touched:** (trinity rule — all three in this commit)

- `project-template/CLAUDE.md` (add `## Project addenda` H2 near
  bottom; update `## Skill loading` and `### Custom agents` to
  mention `x-` prefix and point to `docs/pack/INSTALL-PROCEDURES.md`;
  parallel edit OQ-4 + OQ-6(a))
- `project-template/AGENTS.md` (parallel edit)
- `project-template/GEMINI.md` (parallel edit)
- `project-template/docs/pack/PM-CHAT.md` (wrap project-mutable region
  in `<!-- BEGIN project-owned -->` / `<!-- END project-owned -->`
  markers per architect 3.3; update "Custom files via Procedure 5
  only" bullet to name `x-` prefix and INSTALL-PROCEDURES.md home)
- `project-template/docs/pack/PLATFORM-SKILLS.md` (preamble of
  `## Custom agents` and `## Custom skills` updated to name `x-`
  prefix)

**Dependencies:** C8 merged (so cross-refs in trinity resolve).

**Approval gate flag:** **G4** at end.

### Group D — Fixtures, CI, validate-pack.py

#### Commit C5 — Fixtures + scripts/test-migration.sh

**Title:** `feat: v10 — BD-059 migration test fixtures and end-to-end test runner`

**Files touched:**

- `maintenance-docs/test-fixtures/build-migration-fixture.sh` (NEW)
- `maintenance-docs/test-fixtures/migration-v9.3-empty/` (NEW dir +
  contents)
- `maintenance-docs/test-fixtures/migration-v9.3-customized/` (NEW
  dir + contents — OT-shape fixture)
- `maintenance-docs/test-fixtures/migration-v9.3-marker-convention/`
  (NEW dir + contents)
- `scripts/test-migration.sh` (NEW; supports `--quick` for CI)

**Dependencies:** C9 merged (so the marker-convention fixture has the
correct trinity template shape with `## Project addenda`; building
fixtures against an in-flight template is a sequencing landmine).

**Approval gate flag:** None.

#### Commit C6 — `validate-pack.py` new checks + workflow update

**Title:** `feat: v10 — BD-059 validate-pack.py checks for migration safety + cross-doc parity`

**Files touched:**

- `scripts/validate-pack.py` — new checks:
  `check_three_way_helper_present`,
  `check_merge_helpers_consistent`,
  `check_disposition_table_documented`,
  `check_migration_test_runs_clean`,
  `check_install_procedures_doc_present` [OQ-3],
  `check_methodology_pointers_consistent` [OQ-3],
  `check_x_prefix_documented` [OQ-6],
  `check_tool_config_capability_parity` [OQ-7];
  extend `check_init_project_structure` to require fixture dir +
  test-migration.sh
- `.github/workflows/validate-pack.yml` — add a step after
  `validate-pack.py` that runs the full
  `scripts/test-migration.sh` (non-quick mode) so the three fixtures
  exercise CI

**Dependencies:** C5 (fixtures must exist before the check that
invokes them). Architect's Part 6.4 states `--quick` runs inside
`validate-pack.py`; this plan keeps that for fast feedback and adds
the full run as a separate workflow step.

**Approval gate flag:** None.

### Group E — Cross-tool config parity + final assembly

#### Commit C10 — Deletion-site `x-` prefix guards + add-capability.sh convention comment

**Title:** `fix: v10 — BD-059 defensive x- prefix guards on deletion sites`

**Files touched:**

- `scripts/init-project.sh` — defensive `x-` guards on lines 466,
  471, 481, 491, 496 (already partially landed in C3 — this commit
  only adds the comment block + any sites C3 missed)
- `scripts/add-capability.sh` — top-of-file convention comment
  block (any future deletion site MUST respect `x-`)
- `scripts/migrate-v9-to-v10.sh` — comment-only edits at deletion
  sites that already respect intent (S1 line 197) so reviewers can
  see the convention is honoured

**Dependencies:** C6 merged. (`check_x_prefix_documented` exists
before this commit but does not transitively require the comment
block — the check verifies the doc surface, not the script
comments.)

**Approval gate flag:** None.

#### Commit C11 — Cross-tool capability parity (Codex + Gemini, all three tools)

**Title:** `feat: v10 — BD-059 cross-tool capability parity: Codex [agent_capabilities] + Gemini .env + Gemini settings.json + MCP parity`

**Files touched:**

- `project-template/.codex/config.toml` — add `[agent_capabilities]`
  table mirroring `.claude/settings.json` `env.AGENT_CAPABILITIES`
- `project-template/.codex/requirements.toml` — add v10 policy flag
  additions if any (audit during commit prep)
- `project-template/.gemini/.env` (NEW) — `AGENT_CAPABILITIES=...`
  parity per user decision Q4 = Option A; KEY=VALUE format per
  `V10-GEMINI-CONFIG-RESEARCH.md` Part 1
- `project-template/.gemini/settings.json` (NEW) — minimal
  `settings.json` with the MCP-server block parallel to
  `.mcp.json.example`; Gemini's tool-level config-file home
  established here for the first time
- `project-template/.codex/config.toml.example` (NEW) — Codex MCP
  parity. Codex supports MCP via `[mcp_servers.<name>]` tables in
  `config.toml` per `V10-CODEX-MCP-RESEARCH.md` Part 1; ships as
  `.example` sibling matching the `.mcp.json.example` pattern; STDIO
  transport only for v10 (HTTP transport stability flagged as research
  open question, defer to future BD if needed)
- `scripts/migrate-v9-to-v10.sh` (S3) — extend touched-file list to
  include `.gemini/.env` and `.gemini/settings.json` with their
  respective merge formats (`.env` line-merge, JSON via
  `merge-json.py` from architect's design)
- `scripts/init-project.sh` — parallel addition: ship the new
  Gemini files to fresh projects
- `scripts/validate-pack.py` — `check_tool_config_capability_parity`
  exercised live (already shipped in C6; this commit makes it pass
  for **all three** tools, not just Codex)
- `BACKLOG.md` — BD-059 success criterion (b) [MCP parity] satisfied
  per Codex MCP research outcome; **NO BD-060 entry** (folded into
  BD-059 per user decision 2026-04-30)

**Dependencies:** C10 merged. C6 shipped the parity check, so this
commit makes it green for all three tools.

**Approval gate flag:** **G5** at end. After G5 the pack is on `main`
ready for end-to-end verification (Part 5).

### 3.1 Commit-order dependency graph

```
C1 ──── G0 ──── C2 ──── G1 ──── C3 ──── C4 ──── G2 ────
                                                       │
                                                       ▼
                            C7 ──── G3 ──── C8 ──── C9 ──── G4 ──── C5 ──── C6 ──── C10 ──── C11 ──── G5
                            (procedure relocation)            (fixtures)         (parity)
                                                                                          │
                                                                                          ▼
                                                                                Part 5 verification
```

The unusual feature: **C5 and C6 land *after* C9 (trinity edit)** rather
than after C4 (migration script). This is deliberate. Building fixtures
against a trinity template that does not yet have `## Project addenda`
would either produce fixtures that fail to land sidecar content
correctly, or force C5 to be re-done after C9. Architect's Part 7.4
listed task ordering as a planner concern; this is the planner's
chosen ordering.

---

## Part 4 — Per-commit `validate-pack.py` pass plan

The repo invariant is: every commit on `main` leaves
`validate-pack.py` exiting zero, and the GitHub Actions
`validate-pack.yml` workflow stays green. This part walks each commit
through that ledger.

The current `validate-pack.py` has 10 checks (1–10 per the file's
docstring at lines 5–28). The new architect-proposed checks (C6) are:
`three_way_helper_present`, `merge_helpers_consistent`,
`disposition_table_documented`, `migration_test_runs_clean`. The
plan-added checks (C6) are: `install_procedures_doc_present`,
`methodology_pointers_consistent`, `x_prefix_documented`,
`tool_config_capability_parity`. **All eight new checks are gated on
the artifacts they verify existing first** — they are introduced in
C6 *after* the artifacts they cover are committed.

| Commit | Existing checks (1–10) | New checks (introduced) | Pass status / notes |
|---|---|---|---|
| C1 (plan + BD-060) | All 10 pass — pure docs/BACKLOG edit | (none) | PASS |
| C2 (helpers) | All 10 pass — new files don't break anything (helpers live under `scripts/lib/` and `scripts/`, neither violates pack-scan-locations or x-prefix rules) | (none) | PASS |
| C3 (migration script + classifier wiring) | All 10 pass — script edits don't change the pack-shape surface | (none) | PASS. Migration script is bash-syntax-checked locally pre-commit (`bash -n`). Merge helpers Python-compiled (`python3 -m py_compile`). |
| C4 (structured-config helpers + K3) | All 10 pass | (none) | PASS. New `merge-json.py` / `merge-toml.py` checked with `python3 -m py_compile`. |
| C7 (relocation) | Check 4 (README version table vs git tag) — confirm the v10.0 row still matches the v10.0 tag (no version bump). Other checks unchanged. | (none) | PASS provided METHODOLOGY edit doesn't break references. **Pre-commit guard:** grep for inline anchors that depend on the removed procedure bodies (e.g., `#procedure-5` anchors in other files) — fix any broken anchor in C8. |
| C8 (cross-reference sweep) | All 10 pass — text edits only | (none) | PASS. **Pre-commit guard:** run a grep for `METHODOLOGY.md.*Procedure (5\|5-R\|5-S\|7)` across the entire repo; the only legitimate matches after this commit are in METHODOLOGY pointer stubs and historical BACKLOG/CHANGELOG entries. |
| C9 (trinity + PM-CHAT + PLATFORM-SKILLS) | Check 5 (agent count parity across three tools) — unaffected. Check 7 (pack agent roster) — unaffected. **Trinity is parsed by `merge-trinity.py` indirectly** but `validate-pack.py` does not currently parse trinity content; safe. | (none) | PASS |
| C5 (fixtures) | Check 8 (reserved x- prefix in 7 pack scan locations) — fixtures live under `maintenance-docs/test-fixtures/`, NOT a pack scan location, so x- files in fixtures don't trip the check. **Pre-commit guard:** confirm `maintenance-docs/test-fixtures/` is not added to `PACK_SCAN_LOCATIONS`. | (none) | PASS |
| C6 (validate-pack new checks) | All 10 + 8 new = 18 total; the new checks must pass against the artifacts already committed in C2/C3/C4/C5/C7/C9. | All 8 new checks introduced **and made green simultaneously** | PASS gates the entire fix landing. |
| C10 (x- guards + comment) | All 18 pass | (none) | PASS |
| C11 (Codex parity) | All 18 pass; `check_tool_config_capability_parity` (introduced C6) was previously vacuous — `.codex/config.toml` had no `[agent_capabilities]` table — but the check is written to *succeed* when the parity is structurally absent (so C6 ships green); this commit then exercises the check by *adding* the table and making the parity assertion non-vacuous. | (none) | PASS. **Implementation note for C6:** write `check_tool_config_capability_parity` to assert "if `[agent_capabilities]` exists in `.codex/config.toml`, it equals `env.AGENT_CAPABILITIES` from `.claude/settings.json`; if absent, log a warning but pass." This avoids a chicken-and-egg sequencing problem. |

### 4.1 Per-commit pre-commit checklist

The Pack Chat runs the following before every commit (read-only):

1. `python3 scripts/validate-pack.py` — must exit zero.
2. `bash -n scripts/migrate-v9-to-v10.sh` — bash syntax check.
3. `bash -n scripts/init-project.sh` — bash syntax check.
4. `python3 -m py_compile scripts/merge-trinity.py scripts/merge-platform-skills.py scripts/merge-json.py scripts/merge-toml.py` — when these files exist.
5. After C5: `bash scripts/test-migration.sh --quick` — exit zero.
6. After C5+C6: `bash scripts/test-migration.sh` (full) — exit zero.
7. `git add -A && git status` — Pack Chat shows the staged set to the
   user before commit (per pack repo CLAUDE.md rules).

### 4.2 CI-side ordering

The GitHub Actions `validate-pack.yml` workflow runs on every push.
Until C5 lands, the workflow is unchanged (just `validate-pack.py`).
C6 adds a new step after `validate-pack.py` that runs the full
`scripts/test-migration.sh`. **The new step lands in the same commit
as the validate-pack.py changes (C6)** so an in-flight CI run never
hits a half-state.

---

## Part 5 — End-to-end verification procedure

This part executes after Gate G5, on a freshly committed `main` with
all eleven commits landed. It verifies the fix against OT (the only
production-target project) per OQ-8.

### 5.1 Pre-conditions

- Pack repo on `main` at the post-C11 commit. CI green.
- OT working tree on branch `migration-v9-to-v10` with current dirty
  state (the destroyed-state evidence from 2026-04-30) preserved as
  forensic baseline. **Do not modify OT until step 2.**
- OT backup intact at
  `~/Developer/OptiquityTrader/.pack-migration-backup/v9.3-to-v10.0/`
  (verified read-only by this plan).

### 5.2 Steps

**Step 1 — Forensic snapshot (read-only).**

```
# Pack-Chat-driven; user approval required before any OT mutation.
cd ~/Developer/OptiquityTrader
git diff HEAD > /tmp/ot-pre-revert-diff.txt    # snapshot the destroyed state
git status > /tmp/ot-pre-revert-status.txt
ls .pack-migration-backup/v9.3-to-v10.0/ > /tmp/ot-backup-listing.txt
```

These three files are kept under `/tmp/` as evidence of what the
defective v10.0 migration produced.

**Step 2 — Revert OT to v9.3 baseline (mutating, requires user approval).**

```
cd ~/Developer/OptiquityTrader
# Reset working tree to last v9.3 commit on the branch.
# The destroyed state is uncommitted; `git checkout -- .` reverts it.
git checkout -- .
# Confirm clean.
git status   # expected: "nothing to commit, working tree clean"
# The branch migration-v9-to-v10 is now at the v9.3 commit it was
# created from (since the destroyed state was never committed).

# Use the new pack helper to verify backup completeness:
bash $PACK/scripts/restore-from-backup.sh --verify-only \
     --backup .pack-migration-backup/v9.3-to-v10.0/ \
     --target .
# Expected: "all backed-up files match working tree (or working tree
# matches v9.3 HEAD); restore unnecessary."
```

**Approval gate:** user explicitly approves Step 2 before it runs.
The backup is not consumed by Step 2 — it is verified against the
working tree which is already at the v9.3 baseline.

**Step 3 — Run the FIXED migration.**

```
cd ~/Developer/OptiquityTrader
# Working tree is dirty after Step 2 only if .pack-migration-backup/
# from the failed run still exists; the migration's S0 prompts to
# "Resume / Start fresh / Abort" — choose "f" (start fresh) to clear
# the partial backup.
PACK=/Users/david/Developer/optiquity-ai-agent-config-pack \
    bash $PACK/scripts/migrate-v9-to-v10.sh
```

**Step 4 — Inspect the report.**

```
cat .pack-migration-backup/v9.3-to-v10.0/report.md
```

Per the architect's Part 4 truthfulness invariant:

- **Disposition summary** must list non-zero `K` reconciliations
  needed (at minimum: trinity C1–C3 + PM-CHAT D1 + K1 + K2 + K4 from
  the audit).
- **Reconciliation required section** must list each file with a
  matching `.v9-customized` sidecar in the project tree.
- **No `customization: none` line.**

**Step 5 — Inspect content preservation.**

For each file with disposition `customization-detected-needs-reconciliation`:

```
ls CLAUDE.md.v9-customized
ls AGENTS.md.v9-customized
ls GEMINI.md.v9-customized
ls docs/pack/PM-CHAT.md.v9-customized
ls .claude/settings.json.v9-customized
ls .codex/config.toml.v9-customized
ls .mcp.json.example.v9-customized
```

For each sidecar, diff against the OT pre-revert backup snapshot:

```
diff CLAUDE.md.v9-customized .pack-migration-backup/v9.3-to-v10.0/CLAUDE.md
# expected: byte-identical (sidecar IS the pre-migration project file)
```

**Step 6 — Verify structured-config merge correctness.**

```
# K1 — XCODE_SCHEME survived:
python3 -c "import json; d=json.load(open('.claude/settings.json')); \
    assert d['env']['XCODE_SCHEME']=='OptiquityTrader', d['env']"

# K2 — model_providers.ollama is absent:
python3 -c "import tomllib; d=tomllib.load(open('.codex/config.toml','rb')); \
    assert 'ollama' not in d.get('model_providers',{}), d.get('model_providers')"
```

**Step 7 — Run the full fixture suite against the now-migrated OT
(meta-verification).**

```
PACK=/Users/david/Developer/optiquity-ai-agent-config-pack \
    bash $PACK/scripts/test-migration.sh --target . --fixture-shape ot-revert
```

**Step 8 — Run negative test against the pre-fix migration script
(one-time confidence check, optional).**

The architect's Part 7.3 negative test: confirm that the
**pre-fix** `scripts/migrate-v9-to-v10.sh` (recoverable via
`git -C $PACK show v10.0:scripts/migrate-v9-to-v10.sh`) FAILS the new
fixture-based verification. This proves the verification correctly
detects the BD-059 defect class. The Pack Chat runs this against a
fresh `/tmp/` clone of the OT-shape fixture, **not** against OT
itself.

### 5.3 Pass criteria (BD-059 success criteria mapping)

The verification PASSES if and only if all of the following hold:

| Criterion | Source | Pass signal |
|---|---|---|
| No customization lost | BD-059 SC line 80–82 + architect 7.2.1 | Every confirmed-loss content fragment from BD-059 description appears in either the post-migration OT tree or its `.v9-customized` sidecar |
| Truthful report | BD-059 SC line 56–58 + architect 7.2.2/7.2.3 | `report.md` "Reconciliation required" section non-empty; no `customization: none` line |
| Sidecars exist | architect 7.2.4 | Every reconciliation entry has a matching sidecar on disk |
| Structured-config correctness | architect 7.2.5 | K1 `XCODE_SCHEME == "OptiquityTrader"`; K2 `model_providers.ollama` absent |
| `x-` files preserved | architect 7.2.6 | `find . -name "x-*" -newer .pack-migration-backup/...` returns no churn |
| Test runner clean | architect 7.2.7 | `scripts/test-migration.sh` exits zero |
| OQ-3 procedure relocation works | OQ-3 absorption | `docs/pack/INSTALL-PROCEDURES.md` exists in OT post-migration; pm-startup SKILL Step 0 routes to INSTALL-PROCEDURES on next PM chat session |
| OQ-6 `x-` convention surfaced | OQ-6 absorption | OT trinity `## Skill loading` section names the `x-` prefix and the new doc home |
| OQ-7 K3 + Codex parity | OQ-7 absorption | OT post-migration `.codex/config.toml` contains `[agent_capabilities]` matching `.claude/settings.json`'s `env.AGENT_CAPABILITIES` |

### 5.4 Audit cycle decision (post-verification, per OQ-8)

After Step 7 completes, the Pack Chat performs an audit cycle:

1. Read the report top-to-bottom.
2. Read each `.v9-customized` sidecar against the corresponding
   pre-revert backup.
3. Compare structured-config merges against expected outcomes.
4. Compute a defect list (defects = any pass-criterion failure or any
   sidecar containing content the developer believes should have
   merged automatically without flag).

**Decision tree:**

- **All pass + no defects:** BD-059 is **Resolved**. Pack Chat
  updates `BACKLOG.md` BD-059 to Resolved with the v10.0.x commit
  hash (Pack Chat-only edit). Closes the audit cycle.
- **Pass criteria met but a new edge case surfaces:** Pack Chat
  routes the edge case to `pack-architect` for a fresh design pass
  scoped to the edge case (a new BD-NNN entry), keeps BD-059 Open,
  and re-enters the architect → planner → implementer loop.
- **Pass criteria fail:** Pack Chat routes back to `pack-architect`
  with the failure list. Possible outcomes: a new commit lands as
  a follow-up to BD-059 (no new BD entry), or the architect rejects
  the design and the cycle re-runs.

### 5.5 Forensic preservation

The pre-revert snapshot files in `/tmp/` (Step 1) are preserved until
the audit-cycle decision is made. After resolution, the Pack Chat
optionally archives them to
`maintenance-docs/V10-MIGRATION-FIX-EVIDENCE.md` for historical
reference, then deletes the `/tmp/` copies.

---

## Part 6 — Risk register

Risks identified during the read-only sweep, ordered by severity.

### 6.1 R1 — Stale references after procedure relocation [HIGH]

**Description.** OQ-3 moves Procedures 5 / 5-R / 5-S / 7 out of
METHODOLOGY into INSTALL-PROCEDURES.md. METHODOLOGY is referenced from
≈30+ locations across docs, scripts, skills, and templates (see §2.5
sweep). A missed reference produces a broken pointer that the developer
hits at the worst possible time (kickoff or migration).

**Mitigation.**

- C8 grep sweep before commit: `grep -rn "METHODOLOGY.md.*Procedure (5\|5-R\|5-S\|7)\|Procedure (5\|5-R\|5-S\|7).*METHODOLOGY"` across the entire repo (excluding `maintenance-docs/archive/`, `BACKLOG.md` resolved entries, `CHANGELOG.md` historical entries).
- C6 introduces `check_methodology_pointers_consistent` which is the CI tripwire.
- The METHODOLOGY pointer stubs are left in place (per §1.5) so legacy bookmarks still find a target.

**Residual risk.** mcp-local-rag indexes for projects that already
ingested METHODOLOGY will be stale until the next ingest. Add a
warning to MIGRATION-v9-to-v10.md Step 6 telling the developer to
re-ingest after migration.

### 6.2 R2 — Trinity-rule violation across sweep edits [HIGH]

**Description.** C9 makes parallel edits to CLAUDE.md / AGENTS.md /
GEMINI.md. C8 sweeps cross-references including the pack-repo trinity
files. A drift (one file gets the edit, the other two don't) violates
the trinity rule and gets enforced by `pack-reviewer` only at review
time, not by `validate-pack.py` directly.

**Mitigation.**

- C8 and C9 commit messages must explicitly list all three trinity
  files in the staged-files block.
- `pack-reviewer` invocation between C9 and G4 is mandatory (see
  Part 3 gate G4 — user reviews before C5/C6 land).
- A `validate-pack.py` Check 11 covers pack-roster agent trinity
  symmetry; landed in commit C7a (`scripts/compare-agent-trinity.py`
  + tests + Check 11). Folded into BD-059 scope per user decision
  2026-04-30; no BD-061. Hard CI enforcement requires a
  trinity-asymmetry-by-design marker convention which is a separate
  future BD; the v10.0 check is informational (count regression
  signal) until that convention exists.

### 6.3 R3 — Commit-ordering pitfall: helper before caller [MEDIUM]

**Description.** Architect Part 7.4 lists 10 tasks. Naive ordering
risks landing a commit that *uses* a helper before the helper exists,
breaking `validate-pack.py` mid-sequence.

**Mitigation.** The Part 3 commit sequence is dependency-ordered:

- C2 ships helpers; nothing references them yet → CI green.
- C3 ships migration-script edits that use C2 helpers → CI green.
- C5 ships fixtures that test C3+C4 → CI green (full fixture suite
  doesn't run in CI until C6).
- C6 ships `validate-pack.py` checks that verify C2/C3/C4/C5/C7/C9
  artifacts → CI green only after all dependencies committed.

The dependency graph in §3.1 is the visual sanity check.

### 6.4 R4 — CI breakage on validate-pack.yml workflow change [MEDIUM]

**Description.** C6 adds a new step to `.github/workflows/validate-pack.yml`
that runs `scripts/test-migration.sh`. If the test runner has a flake
(temp-dir collision, network dep) CI starts failing intermittently.

**Mitigation.**

- `scripts/test-migration.sh` uses `mktemp -d` and cleans up with
  `trap` (architect 5.4 implicit; planner makes it explicit).
- No network dependencies; fixtures are pure-local.
- `--quick` mode (architect 6.4) runs just the empty fixture in
  `validate-pack.py` for the fast path; the full suite runs in the
  separate workflow step where slower runtime is acceptable.

### 6.5 R5 — RAG-ingest staleness for projects indexing METHODOLOGY [MEDIUM]

**Description.** Projects using `mcp-local-rag` ingest METHODOLOGY.md.
After C7 / C8 the relocated procedures are no longer in
METHODOLOGY.md and the project's RAG index serves stale results
("Procedure 5 lives in METHODOLOGY") until re-ingest. A query like
"how do I add a custom skill" might return a stale METHODOLOGY chunk
that no longer has the Procedure 5 body.

**Mitigation.**

- METHODOLOGY pointer stubs (§1.5) ensure the RAG-returned chunk
  contains "See INSTALL-PROCEDURES.md Procedure 5" — the user is
  redirected, not stranded.
- MIGRATION-v9-to-v10.md Step 6 (post-migration) gains a bullet:
  "Re-run mcp-local-rag ingest if your project indexes
  `docs/pack/METHODOLOGY.md` or `docs/pack/INSTALL-PROCEDURES.md`."
- For new projects, `init-project.sh` already prints next-steps that
  include RAG ingest.

### 6.6 R6 — Missed cross-tool capability parity at C11 [HIGH] — UPDATED 2026-04-30

**Description.** UPDATED per user decision 2026-04-30: Gemini parity
is now folded into BD-059 (no BD-060). The risk has shifted from
"deferred work" to "C11 must successfully ship Gemini-side parity
files for the first time, plus resolve the Codex MCP question, all
in one commit." If C11 misses any of: `.gemini/.env`,
`.gemini/settings.json` MCP block, `.codex/config.toml`
`[agent_capabilities]`, OR if `V10-CODEX-MCP-RESEARCH.md` is not
landed before C11 starts, BD-059 cannot resolve.

**Mitigation.**

- `V10-CODEX-MCP-RESEARCH.md` is in flight (background docs-research
  agent); land it before C11 starts. C11 cannot proceed without it.
- `V10-GEMINI-CONFIG-RESEARCH.md` already landed; Q4 = Option A
  decided (`.gemini/.env` for AGENT_CAPABILITIES). C11 implements
  per that research.
- `check_tool_config_capability_parity` (added in C6) is written
  explicitly for the **three-tool symmetric** case and FAILS if any
  one tool's config diverges from the others on the capability
  roster. The check is tested with a negative fixture (one of the
  three tools missing the AGENT_CAPABILITIES key → assert check
  fails) so the check itself doesn't silently false-pass.
- C11 commit message must explicitly cite BD-059 success criterion
  satisfaction: `(a) AGENT_CAPABILITIES Gemini parity` and `(b) MCP
  parity (with Codex MCP outcome cited)`.

### 6.7 R7 — Validate-pack.py false-pass on new checks [MEDIUM]

**Description.** New checks introduced in C6 may have logic bugs that
let real defects through (the original BD-059 was exactly this class
of failure for §4.6).

**Mitigation.**

- Each new check has a paired *negative* test in `scripts/test-migration.sh`:
  the test deliberately corrupts an artifact and asserts the check
  FAILS. If the check doesn't fail, the check itself is buggy.
- Negative tests run in CI alongside positive tests.

### 6.8 R8 — Trinity rule violation in pack-repo skill copies [MEDIUM]

**Description.** `pm-startup/SKILL.md` exists in **four** locations:
- `project-template/skills/pm-startup/SKILL.md` (canonical)
- `.claude/skills/pm-startup/SKILL.md` (pack-repo agent skill copy)
- `.codex/skills/pm-startup/SKILL.md` (pack-repo agent skill copy)
- `.gemini/skills/pm-startup/SKILL.md` (pack-repo agent skill copy)

The C8 sweep must update all four. A miss in any copy means pack
agents (when invoked via `claude --agent pack-architect`, etc.) read
stale procedure references.

**Mitigation.** §2.5 enumerates all four explicitly. C8 commit message
lists all four files. Pre-commit grep for `Procedure 5\|Procedure 7`
across `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`.

### 6.9 R9 — Skill-dir sibling preservation regresses an existing pack invariant [LOW]

**Description.** Today S2's `rm -rf` then re-create with only `SKILL.md`
is the contract. Architect 3.8 + OQ-6 changes this to "preserve siblings."
A project that has accumulated `x-NOTES.md` files inside pack skill
dirs over multiple runs may now find them surviving the migration when
the user expected a clean wipe.

**Mitigation.** This is the user-explicit OQ-6 decision; it is not a
regression but a designed change. The migration report's "Project
files preserved (no migration touch)" section (architect 4.1) lists
every preserved sibling explicitly so the developer sees what survived.

### 6.10 R10 — `## Project addenda` template change incompatible with v9.3 trinity content [LOW]

**Description.** C9 adds `## Project addenda` H2 to v10 trinity
templates. v9.3 OT trinity does not have this section. The migration's
classifier returns `customization-detected-needs-reconciliation` for
v9.3 trinity (correct outcome), and the developer must hand-port v9.3
content into the v10 `## Project addenda` section during Procedure
5-C. Risk: the developer skips this step and v9.3 customization is
lost.

**Mitigation.**

- The `.v9-customized` sidecar persists until Procedure 5-C explicitly
  deletes it as the final step.
- The S7 report lists the sidecar prominently in "Reconciliation
  required."
- `pm-startup` SKILL Step 0 detects `.v9-customized` sidecars at
  every PM chat session (extend the sentinel grep — Commit C8) and
  routes the developer to Procedure 5-C until all sidecars are
  resolved.

---

## Part 7 — Open questions for the Pack Chat / user

The user's decisions on OQ-1..OQ-8 are absorbed in §1.3. The
following open questions emerged from the planner sweep that are
either (a) not covered by the user's eight decisions, or (b)
secondary consequences of those decisions that the planner should
not resolve unilaterally.

### 7.1 OQ-P1 — Procedure 5-C body authoring scope

The architect's Part 3.2 sketches Procedure 5-C (renamed from 5-T per
OQ-3) as: "PM chat walks each section heading present in the v9 file,
developer chooses keep-pack / keep-project / hand-merge." The
procedure body is **not authored** by the architect. The full body
needs to land in C7 alongside the relocated procedures.

**Question for Pack Chat:** Does the planner author a draft Procedure
5-C body in this plan (Part 7 appendix), or is this delegated to a
follow-up `pack-architect` invocation focused specifically on
Procedure 5-C body authoring? The procedure body is multi-file (covers
trinity + PM-CHAT + PLATFORM-SKILLS + configs + agents + skills) and
needs careful drafting to handle Pattern P prose three-way decisions
without ambiguity. Recommendation: a focused architect cycle for
Procedure 5-C body — out of scope for this plan; covered by a sub-task
in C7.

### 7.2 OQ-P2 — `pm-startup` SKILL Step 0 sentinel sweep extension

The current `pm-startup/SKILL.md` Step 0 detects two sentinels:
`POSTRUN-PENDING` (Procedure 5-S) and `PROMPT-RECON-PENDING`
(Procedure 5-R). After C3, a third sentinel-like detection is
needed: presence of any `*.v9-customized` sidecar in the project tree
(triggers Procedure 5-C).

**Question for Pack Chat:** Should the third detection be a literal
sentinel file (e.g., `$BACKUP_DIR/v9-customized-pending`) written by
the migration's S7, or a glob detection (`find . -name "*.v9-customized"`)?
Sentinel files are cleaner for re-entrancy (Procedure 5-C deletes the
sentinel as final step); glob detection is more defensive
(Procedure 5-C cannot deceive itself by deleting the sentinel while
sidecars remain). Recommendation: BOTH — sentinel for quick check, glob
for canonical truth. Lands in C3 (migration script writes sentinel) +
C8 (SKILL.md gets the new detection logic).

### 7.3 OQ-P3 — Migration of existing v10.0-mid-flight installs

If a project ran the *defective* v10.0 migration (like OT) and the
Pack Chat lands the BD-059 fix on `main`, what happens for that
project?

- **Option A (this plan's default per OQ-8):** the user reverts the
  project to v9.3 baseline and re-runs the fixed migration.
- **Option B:** ship a `migrate-v10.0-defective-to-v10.0-fixed.sh`
  helper that detects a partial defective migration and reconstructs
  the v9.3 → v10.0 transition without requiring full revert.

**Question for Pack Chat:** Option A is sufficient for OT (the only
known target). Option B is over-engineered for a known scope of one.
Recommendation: skip Option B unless another defective-v10.0 project
emerges. This plan does not author Option B.

### 7.4 OQ-P4 — Sidecar `_v9-backup.md` (PROMPT-TEMPLATES) vs `.v9-customized` naming inconsistency

Architect Part 3.6 keeps `_v9-backup.md` for PROMPT-TEMPLATES.md (existing
v10.0-shipped convention) and introduces `.v9-customized` for everything
else (OQ-1 confirmed by user). Two different sidecar conventions exist
post-fix.

**Question for Pack Chat:** Should the planner unify these to one
naming (rename existing `_v9-backup.md` to
`PROMPT-TEMPLATES.md.v9-customized`)? Pro: consistency, one Procedure
5-C handles both. Con: breaks the `_v9-backup.md` convention already
documented in MIGRATION-v9-to-v10.md and Procedure 5-R, requires
extending Procedure 5-R or merging into 5-C. Recommendation: unify in
C7 — the relocation is the natural moment to harmonize. Procedure 5-R
becomes a sub-procedure of 5-C ("Procedure 5-C.1 — Prompt-templates
reconciliation"), and the sidecar suffix unifies. **This is a planner
recommendation, not a user-approved decision; flagging here for Pack
Chat to confirm before C3 / C7 land.**

### 7.5 OQ-P5 — Capability parity check granularity (OQ-7 follow-on)

The plan's `check_tool_config_capability_parity` in C6 verifies that
`.codex/config.toml` `[agent_capabilities]` matches
`.claude/settings.json` `env.AGENT_CAPABILITIES`. Other capability-like
config could drift in the future (e.g., `permissions.allow` in
settings.json without a matching `[permissions]` table in
config.toml). The current scope is "agent capabilities only."

**Question for Pack Chat:** Is per-config-key parity checking in
scope for BD-059, or is per-key parity a separate future BD?
Recommendation: keep scope to `[agent_capabilities]` for BD-059;
per-key parity is a separate future BD. **UPDATED 2026-04-30:** user
decided to PUNT per-key parity beyond AGENT_CAPABILITIES + MCP server
config. BD-060 is **NOT created** (Gemini AGENT_CAPABILITIES + MCP
parity folded into BD-059); a future BD can pick up other-key parity
sweeps if/when it becomes a real concern.

### 7.6 OQ-P6 — `## Project addenda` template change requires new
`validate-pack.py` check?

OQ-4 architect note: "Planner to confirm whether `validate-pack.py` is
updated to require the new H2." The plan does not currently propose
such a check — adding `## Project addenda` to v10 templates is a
template-shape change that affects new-project init only;
`validate-pack.py`'s existing checks don't validate trinity content.

**Question for Pack Chat:** Should `validate-pack.py` gain a check
that asserts the v10 trinity template files contain `## Project
addenda`? Recommendation: yes — add a small `check_trinity_addenda_h2`
in C6 that greps the three template files for the H2. Trivial to
implement; locks the template shape against accidental future
removal.

### 7.7 OQ-P7 — `BACKLOG.md` handling during the BD-059 implementation

Pack repo CLAUDE.md says "BACKLOG.md edits via Pack Chat only." This
plan touches BACKLOG.md in C1 (BD-059 status update — already landed
2026-04-30 with the trinity-rule-for-tool-config criterion expansion)
and at BD-059 final resolution after end-to-end verification (Status
flip + Resolved: line). **NO BD-060 edits** — the Gemini gap is folded
into BD-059. All BACKLOG.md edits are Pack-Chat-driven per repo rules.

**Question for Pack Chat:** Confirm that Pack Chat (not pack-architect
/ pack-planner / pack-coder) is the agent making these edits, with
explicit user approval before each. Recommendation: yes — repo rules
are unambiguous; this is a confirmation only.

---

## Part 8 — Plan summary at a glance

- **11 commits** across 5 groups (A: foundations, B: migration script
  + structured-config helpers, C: procedure relocation + cross-ref
  sweep + trinity edits, D: fixtures + CI, E: parity + final).
- **6 approval gates** (G0..G5).
- **25 new touchpoints beyond architect's audit** (12 OQ-3 + 8 OQ-6
  + 5 OQ-7).
- **8 new `validate-pack.py` checks** (4 from architect + 4 from
  planner sweep).
- **End-to-end verification** via OT revert + re-run + Pack Chat
  audit cycle.
- **No version bump.** All commits land on `main` per BD-059 framing.

---

*End of plan.*
