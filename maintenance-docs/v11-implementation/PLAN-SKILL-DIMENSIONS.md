# PLAN — Skill Dimensions Reframe (v11.0)

**Type:** Pack-planner sequencing plan (read-only).
**Status:** Draft for pack-coder execution. No implementation in this doc.
**Date:** 2026-05-11.
**Branch context:** `v11-dev`.

This plan sequences the work designed in
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`
into independently-committable batches that ship as part of v11.0 BEFORE
all other remaining v11.0 batches. Every batch leaves the pack passing
`scripts/validate-pack.py` and the `Validate Pack` GitHub Actions
workflow on its own.

Inputs:
- `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`
  — primary design.
- `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`
  — Phase-1 inputs for Phase 2A handoff.
- `BACKLOG.md` — highest existing BD = **BD-139**; new BDs start at
  BD-140 and run contiguously through BD-150.
- `README.md` Repository Layout — authoritative pack structure.
- `project-template/docs/pack/PLATFORM-SKILLS.md` (current 4-dimension
  matrix, 31 skills).
- `scripts/validate-pack.py` (current Checks 1-30, with a known
  numbering inversion: Check 21 = pack-help parity; Check 27 = agent
  canonical-phrase; Check 28 = pm-startup parity; Check 29 = tracker
  config; Check 30 = recommendation-state JSON. **Next free integer =
  Check 31.** The architecture doc proposes "Check 32"; the actual next
  free check is 31. This plan uses **Check 31** as the new check number
  to avoid collision with future numbering. PLANNER NOTE: confirm the
  check numbering with maintainer before coding — the architecture doc
  said 32; the actual next-free is 31.).

## 0. Batch summary (read this first)

| # | BD | Title | One-line scope |
|---|---|---|---|
| 1 | BD-140 | BACKLOG entries: dimension reframe + v12 deferrals | Open BD-140..BD-150 placeholders + 5 v12-deferred BDs (observability, accessibility, concurrency, skill versioning, naming-convention enforcement) |
| 2 | BD-141 | `python_data_marker_detected()` in lib/detect.sh + callers | Concrete predicate for python-data-architecture (per architecture §7.5); init-project.sh + add-capability.sh + PLATFORM-SKILLS.md text use it |
| 3 | BD-142 | PLATFORM-SKILLS.md 5-dimension reframe (D1-D5 + Tier 0 + intersection + trigger tables) | Major rewrite of PLATFORM-SKILLS.md per architecture §3-§5; no SKILL.md content changes |
| 4 | BD-143 | Trinity "Skill loading" prose update + Tier 0/1/2 nomenclature retirement | CLAUDE.md / AGENTS.md / GEMINI.md edits in template + pack-repo copies + audit-methodology rule 20 cross-platform UI bullet seam + architecture-review SKILL.md skill list update |
| 5 | BD-144 | add-capability.sh D5 rename + platform extensions + role intersection fix + v10→v11 migrator translation | Rename `role:apple-app` → `deployment:apple`; new `deployment:linux-container` / `platform:android` / `platform:web-browser` / `platform:embedded-mcu` rows; `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` (drops `deployment-python`); v10→v11 migrator translation stage + golden-snapshot fixture (per §7.1) |
| 6 | BD-145 | init-project.sh detection + skill-coverage extension | `pack_skill_coverage_for()` consults D1/D5 markers; uses `python_data_marker_detected()`; post-install hint points PM chat at new D1-D5 tables |
| 7 | BD-146 | validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension | Parses PLATFORM-SKILLS.md; verifies every SKILL.md appears in exactly one cell; verifies agent files' "Skills to load" lists conform to per-agent assignment |
| 8 | BD-147 | `scripts/lib/migrator-skills.sh` extraction + S5b rewrite to call it | Extract BD-035 rename helper into reusable `migrator_skill_rename` API; v10→v11 S5b rewritten to call it; tests cover both rename and split |
| 9 | BD-148 | MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md "Skill model changes" section | Documents reframe as behavioral note (per architecture §7.8); BD-136 trinity-marker non-overlap noted; D5 monorepo gotcha (architecture §7.4); D2 reshape advisory (architecture §7.6) |
| 10 | BD-149 | PLATFORM-SKILLS.md "Extending this file" naming-convention codification | Documents `*-best-practices` / `*-language` / `*-architecture` / `*-patterns` convention per architecture §7.10; no skill renames |
| 11 | BD-150 | CHANGELOG.md + README.md skill-count + version-table update | Single CHANGELOG entry; README "30 skills" / "31 skills" mentions reconciled; v11.0 row picks up reframe BD references |
| 12 | BD-156 | `protobuf-patterns` skill — extract Proto3 schema rules from grpc-patterns; standalone-usable via intersection table | NEW skill creation (3 trinity copies); refocus `grpc-patterns` (×3 trinity) to gRPC-only; PLATFORM-SKILLS.md intersection-table row + dimensional-skills count update; new `protobuf_marker_detected()` helper in `scripts/lib/detect.sh` (parallels BD-141 pattern); `add-capability.sh` row; validate-pack Check 31 must pass with new skill. **Hard blocker for BD-149** per user direction 2026-05-11. *Added 2026-05-11 post-planner — see §7.3.* |
| 13 | BD-157 | `apple-swiftdata-patterns` skill — SwiftData object-store rules for Apple platforms (intersection-cell loading) | NEW skill (3 trinity copies); PLATFORM-SKILLS.md intersection-table row + inventory update; new `swiftdata_marker_detected()` helper in `scripts/lib/detect.sh` (parallels BD-141 / BD-156 pattern); `init-project.sh` / `add-capability.sh` wiring; validate-pack Check 31 must pass. **Hard blocker for BD-149** per user direction 2026-05-11. *Added 2026-05-11 post-planner — see §7.3.* |
| 14 | BD-158 | `swift-concurrency-patterns` skill — Modern Swift Concurrency (async/await, actors, Sendable) + GCD (D1-implied loading) | NEW skill (3 trinity copies); PLATFORM-SKILLS.md dimensional-skills row (D1-implied for D1 ∈ {ios, macos}, parallels `swift-best-practices` loading) + inventory update; modify `swift-best-practices` (×3 trinity) and `apple-architecture-core` (×3 trinity) to strip brief concurrency mentions and cross-reference; `init-project.sh` swift-coverage update; `add-capability.sh` update; validate-pack Check 31 must pass. **Hard blocker for BD-149** per user direction 2026-05-11. *Added 2026-05-11 post-planner — see §7.3.* |
| FINAL | — | Spawn pack-architect for **Phase 2A** | Per-skill rule design for `web-architecture`, `android-architecture`, `embedded-mcu-architecture` |

**Total batches: 14.** **Total new BDs: 14 batch BDs (BD-140..BD-150 + BD-156, BD-157, BD-158) + 5 v12-deferred BDs (BD-140 batch creates them as BD-151..BD-155).**

PLANNER NOTE: BD-140 is the "BACKLOG ops" batch and itself creates the
five v12-deferred entries inline. So the new-BD inventory is BD-140
(BACKLOG-ops batch) plus BD-141..BD-150 (ten implementation batches)
plus BD-151..BD-155 (five v12-deferred BACKLOG entries created inside
BD-140's batch) plus BD-156, BD-157, BD-158 (post-planner additions
for the standalone-protobuf, SwiftData, and Swift-concurrency gaps
surfaced during the BD-142 model-validation checkpoint, 2026-05-11).
Total new BD numbers consumed: **19** (BD-140..BD-158).

## 1. Critical-path diagram

```
BD-140 (BACKLOG ops) ──┐
                       │
BD-141 (detect helper) ┼─► BD-142 (PLATFORM-SKILLS reframe) ──► BD-143 (trinity + skill SKILL.md)
                       │           │
                       │           ├─► BD-144 (add-capability.sh)  ─┐
                       │           │                                 │
                       │           ├─► BD-145 (init-project.sh)     ─┤
                       │           │                                 │
                       │           └─► BD-146 (validate-pack Check 31) ─┐
                       │                                              │
                       │   BD-147 (migrator-skills.sh extract) ───────┤
                       │                                              │
                       └────────────────────► BD-148 (MIGRATION docs) ┤
                                                                      │
                                              BD-156 (protobuf-patterns) ──┐
                                              BD-157 (apple-swiftdata-patterns) ──┤
                                              BD-158 (swift-concurrency-patterns) ──┼─► BD-149 (naming convention) ─┤
                                                                                                                    │
                                                                                        BD-150 (CHANGELOG + README) ┘
                                                                                                                    │
                                                                                                      FINAL ─► Phase 2A
```

**Critical path: BD-140 → BD-141 → BD-142 → BD-143 → BD-146 → BD-150 (6 batches).** BD-156, BD-157, BD-158 sit off the critical path but are hard blockers for BD-149 (off-path) per user direction 2026-05-11. They can ship in parallel with each other (file-disjoint: each new skill's SKILL.md trinity is its own directory; BD-156 and BD-157 each add a new intersection-table row, BD-158 adds a dimensional-skills row — only BD-158 cross-edits existing skills `swift-best-practices` and `apple-architecture-core`).

Rationale: BD-141 must precede BD-142 because BD-142's text references
the new detection helper. BD-142 must precede BD-143 because trinity
prose points at PLATFORM-SKILLS.md as the authoritative reframe. BD-146
must precede BD-150 because Check 31 is the gate that proves the new
tables are internally consistent before the version-row CHANGELOG
goes in. BD-144, BD-145, BD-147, BD-148, BD-149 sit off the critical
path and may be parallelized in execution if multiple coder sessions
are available, but each still depends on BD-142 having shipped.


---

## 2. Per-batch detail

### Batch 1 — BD-140: BACKLOG entries (dimension reframe + v12 deferrals)

**BD assignment.** BD-140. Title: "Skill-dimensions reframe — BACKLOG
entries (umbrella + v12 deferrals)". Status: Open. Blockers: None.
Unblocks: BD-141..BD-150.

**Scope.** Single file: `BACKLOG.md`. Adds 11 new BD entries
(BD-140..BD-150 as Open work-items targeting v11.0) plus 5 v12-deferred
BD entries (BD-151..BD-155) per the deferred items in architecture
§7.1, §7.2, §7.3, §7.9, §7.10. No other file edits.

**Implementation steps.**

1. Append BD-140 entry to BACKLOG.md (after BD-139). Type:
   TODO(version). Description: "Umbrella: skill-dimensions reframe per
   ARCHITECTURE-SKILL-DIMENSIONS.md; spawns BD-141..BD-150 as
   sequenced batches."
2. Append BD-141..BD-150 entries with their batch titles, blockers per
   the critical-path diagram (§1), File/Symbol pointers per each
   batch's Scope subsection below, and Description text quoting the
   relevant architecture-doc sections.
3. Append v12-deferred BD-151 (observability skill, ref §7.1), BD-152
   (accessibility skill, ref §7.2), BD-153 (concurrency skill, ref
   §7.3), BD-154 (skill-versioning frontmatter, ref §7.9), BD-155
   (naming-convention enforcement migration, ref §7.10). Each entry:
   Status: Open. Blockers: v12. Description: motivation paragraph plus
   a one-line pointer to its architecture-doc section.

**Trinity considerations.** None — BACKLOG.md only.

**Verification.**
- `python3 scripts/validate-pack.py` (Checks 1-30 all pass; Check 3 may
  flag TD-TBD sentinels — none introduced here).
- `grep -nE "^\\*\\*BD-(14[0-9]|15[0-5])" BACKLOG.md` returns 16 lines.
- `grep -c "Status: Open" BACKLOG.md` increased by exactly 16 vs
  pre-batch.

**Risk.** Numbering collision if another in-flight batch grabs BD-140
first. Mitigation: this is the first batch; commit before spawning any
other planner/architect work. Risk of BD entries referencing files
that do not yet exist (e.g., `scripts/lib/migrator-skills.sh`); that is
acceptable per pack convention — File/Symbol fields may forward-declare.

**Commit message.** `docs: v11 — BD-140 BACKLOG entries for skill-dimensions reframe (BD-141..BD-150) + v12 deferrals (BD-151..BD-155)`

---

### Batch 2 — BD-141: `python_data_marker_detected()` helper

**BD assignment.** BD-141. Title: "Concrete python-data-architecture
load predicate (lib/detect.sh marker function)". Status: Open.
Blockers: BD-140. Unblocks: BD-142, BD-145.

**Scope.**
- `scripts/lib/detect.sh` — add new function around line 230 (after
  `detect_installed_capabilities`), sourceable by init-project.sh and
  add-capability.sh. ~30-40 LoC.
- `scripts/init-project.sh` — `pack_skill_coverage_for()` (line
  219-228) wires the helper for the python row; ~5-line change.
- `scripts/add-capability.sh` — A1 resolver consults the helper when
  `language:python` is added without explicit `role:python-server`;
  ~5-10 line change near line 110.

**Implementation steps.**

1. Edit `scripts/lib/detect.sh`. Add `python_data_marker_detected()`
   per architecture §7.5 marker list. Function takes target dir as $1;
   echoes `python-data: yes|no` on stdout. Markers (any one true →
   yes): (a) `requirements.txt` or `pyproject.toml` lists any of:
   `sqlalchemy`, `alembic`, `pydantic`, `aiohttp`, `httpx`, `psycopg`,
   `aiomysql`, `asyncpg`, `redis`, `pymongo`, `motor`, `boto3`,
   `aioboto3`, `grpc-tools`, `protobuf`, `pyarrow`, `pandas`, `numpy`,
   `scikit-learn`, `torch`, `tensorflow`; (b) ≥5 `.py` files outside
   `tests/`. Implementation uses `grep -lE` and `find ... -not -path
   '*/tests/*'` with `wc -l`.
2. Edit `scripts/init-project.sh` `pack_skill_coverage_for python` row
   (line 224) to call the helper and emit `python-data-architecture`
   conditionally. Keep `python-best-practices` unconditional.
3. Edit `scripts/add-capability.sh` `capability_skills` line for
   `language:python` (line 110) to keep current behavior (skill list
   stays, helper documents the predicate). Add a comment line
   referencing the helper as the canonical predicate.
4. **Permission-bit hygiene check** — both scripts begin
   non-executable (lib/detect.sh is sourced, not exec). Run `ls -l
   scripts/lib/detect.sh scripts/init-project.sh scripts/add-capability.sh`
   after editing to confirm exec bit unchanged.

**Trinity considerations.** None — script-only batch.

**Verification.**
- `python3 scripts/validate-pack.py` (must pass).
- `bash -n scripts/lib/detect.sh` (syntax check).
- `bash -n scripts/init-project.sh scripts/add-capability.sh`.
- Smoke: source detect.sh in a subshell; create scratch dir with
  `pyproject.toml` containing `sqlalchemy`; assert
  `python_data_marker_detected /tmp/scratch` echoes `python-data: yes`.
- `ls -l scripts/init-project.sh scripts/add-capability.sh` — exec bit
  preserved (`-rwxr-xr-x`).

**Risk.** Edit tool stripping `+x` on the `.sh` files — mitigated by
post-edit `chmod +x` if `ls -l` shows `-rw-`. Wrong fast-path behavior
for projects with `pyproject.toml` but no relevant deps — verify the
marker regex anchors to `^[name]` (TOML key) and `^\s*"name"` (JSON
manifests are out of scope; only TOML and requirements.txt).

**Commit message.** `feat: v11 — BD-141 python_data_marker_detected() in lib/detect.sh + init/add-capability wiring`

---

### Batch 3 — BD-142: PLATFORM-SKILLS.md 5-dimension reframe

**BD assignment.** BD-142. Title: "PLATFORM-SKILLS.md — 5 dimensions +
Tier 0 + intersection + trigger tables". Status: Open. Blockers:
BD-141. Unblocks: BD-143, BD-144, BD-145, BD-146, BD-148, BD-150.

**Scope.** Single file: `project-template/docs/pack/PLATFORM-SKILLS.md`
(355 lines today; will grow to ~500 lines). Major rewrite of:
- Lines 8-22: "How skill selection works" — replaces 2-tier framing
  with 5+3 framing.
- Lines 25-150: "Step 1 — Build the project's skill profile" — D1-D5
  tables per architecture §3.1-§3.5 plus new "Tier 0 base" §3.6 +
  "Intersection table" §3.7 + "Trigger-loaded skills" §3.8.
- Lines 154-225: "Step 2 — Select skills per agent" — re-derived
  per-agent tables per architecture §5.1-§5.9.
- Lines 246-296: "Full skill inventory" — relabel Tier 1/Tier 2 to
  Tier 0 base / dimensional / trigger / intersection. Skill count
  unchanged at 31.
- Lines 298-306: "Deferred skills" — keep, prune entries that move into
  D1 deferred values.

**Implementation steps.**

1. Replace §"How skill selection works" with the architecture §0
   summary text plus a one-paragraph "Three load mechanisms" preamble.
2. Rewrite Step 1 Dimensions:
   - **D1 Runtime/OS substrate** table per architecture §3.1
     (including `linux-server` row that loads no skills — matrix
     uniformity per user decision 4).
   - **D2 Cross-platform languages** per architecture §3.2 (only
     `python` populated for v11.0; rust/go marked deferred).
   - **D3 Component role** per architecture §3.3 (predicate-only;
     skills loaded via intersections).
   - **D4 Communication protocols** per architecture §3.4 (no change
     except explicit `none` value).
   - **D5 Deployment surface** per architecture §3.5 — NEW section.
   - **Tier 0 base skills** per architecture §3.6.
   - **Intersection table** per architecture §3.7 (cite
     `python_data_marker_detected` in
     `python-data-architecture` predicate row, referencing
     `scripts/lib/detect.sh`).
   - **Trigger-loaded skills** per architecture §3.8.
3. Rewrite Step 2 per-agent tables per architecture §5. Promote
   `security-patterns`, `api-design`, `debugging`,
   `ui-test-strategy` from Tier 1/2 to Tier 0; document the moves.
   Add `architecture-review` to planner per §5.5; add `api-design` +
   `debugging` to reviewer per §5.3.
4. Rewrite "Full skill inventory" table headers to use Tier 0 base /
   dimensional / trigger / intersection; total stays at 31.
5. Add a new subsection "Monorepo D5 scoping note" per architecture
   §7.4 — one paragraph documenting the monorepo gotcha.
6. **Do NOT** edit `## Custom agents` and `## Custom skills` (lines
   310-345); these are project-owned per BD-088 customization-preserve
   contract. The illustrative `x-deployer` and `x-brokerage-api` rows
   stay byte-identical.
7. Worked examples (lines 116-150): refresh under the new model — D5
   row added to each example. 5 examples total.

**Trinity considerations.** None directly — but BD-143 (next batch)
edits trinity files to point at this rewrite. Sequencing matters:
BD-142 must merge before BD-143 so trinity prose can reference
finalized section names.

**Verification.**
- `python3 scripts/validate-pack.py` (must pass; Check 9 init-project
  structure should not regress).
- `grep -c "^### Dimension" project-template/docs/pack/PLATFORM-SKILLS.md`
  → 5 (one per D1..D5).
- `grep -c "Tier 0 base" project-template/docs/pack/PLATFORM-SKILLS.md`
  → ≥1.
- `grep -c "Intersection table" project-template/docs/pack/PLATFORM-SKILLS.md`
  → ≥1.
- Manual: open file in pager, confirm `## Custom agents` /
  `## Custom skills` byte-identical to pre-batch (use `git diff
  --stat`; line-shift expected, but body bytes inside those headers
  unchanged).
- Skill count audit: every SKILL.md in `project-template/skills/*/`
  appears in exactly one cell (D1, D2, D3-intersect, D4, D5, Tier 0,
  trigger). Manual count.

**Risk.** Drift between the rewrite and the per-agent assignments in
the agent files (`project-template/.claude/agents/*.md` etc.). BD-146
adds Check 31 to enforce; until then this is a manual-eyes risk.
Mitigation: the BD-146 Check 31 implementation includes back-fill
auditing as part of its test pass — coder may discover inconsistencies
that require returning to BD-142. Treat as iterative within the BD-142
→ BD-146 window.

**Commit message.** `docs: v11 — BD-142 PLATFORM-SKILLS.md reframed as 5 dimensions + Tier 0 base + intersection + trigger tables`

---

### Batch 4 — BD-143: trinity prose update + audit-methodology rule 20 + architecture-review skill list

**BD assignment.** BD-143. Title: "Trinity Skill-loading prose +
audit-methodology rule 20 cross-platform UI bullets +
architecture-review skill list". Status: Open. Blockers: BD-142.
Unblocks: BD-148.

**Scope.** Six trinity files (template + pack-repo) plus two SKILL.md
files. **Trinity rule applies — same edit in all three template
trinity files; same edit in all three pack-repo trinity files. Six
files in this batch share the prose change.**

- `project-template/CLAUDE.md` — §"Skill loading" lines ~152-176.
- `project-template/AGENTS.md` — §"Skill loading" line 158 onward.
- `project-template/GEMINI.md` — §"Skill loading" line 169 onward.
- `CLAUDE.md` (pack repo root) — corresponding section.
- `AGENTS.md` (pack repo root) — corresponding section.
- `GEMINI.md` (pack repo root) — corresponding section.
- `project-template/skills/audit-methodology/SKILL.md` — rule 20 (line
  48) and the auditor-ui skip rule 44 (line 95).
- `project-template/skills/architecture-review/SKILL.md` — line 7
  platform-skill list (and 3 distributed copies under
  `project-template/.claude/skills/architecture-review/`,
  `.codex/skills/architecture-review/`,
  `.gemini/skills/architecture-review/`).

**Implementation steps.**

1. **Trinity prose** — in each of the six trinity files, edit
   §"Skill loading" so the framing paragraph names the 5+3 model and
   says PLATFORM-SKILLS.md is authoritative. Keep the
   `**Active skills:**` line format identical (the marker pattern is a
   public contract used by add-capability.sh A2). Same exact wording
   in all six files.
2. **audit-methodology rule 20** (line 48): add a sub-bullet listing
   the four cross-platform UI concerns per architecture §6.3 +
   RESEARCH-NON-APPLE-UI-SKILLS.md §5: state source-of-truth,
   interactive reachability, externalized strings, layout adapts to
   translation growth. Mention these apply when web / Android /
   embedded-MCU UI skills are loaded.
3. **audit-methodology rule 44** (line 95): keep current
   "in-development for v11.0" sentence; once Phase 2A+2B+3 land,
   replace with concrete reference. PLANNER NOTE: this batch leaves
   rule 44 prose unchanged; Phase-3 batch will revise.
4. **architecture-review SKILL.md** line 7: keep current platform
   skills listed; add a parenthetical "(plus future
   web-architecture / android-architecture / embedded-mcu-architecture
   when loaded — predicate per PLATFORM-SKILLS.md intersection
   table)". Apply identically in all 4 copies (template + 3
   distributed).
5. Verify the 4 architecture-review SKILL.md copies are byte-identical
   post-edit (Check 9 enforces).
6. Verify the 6 trinity files' §"Skill loading" sections are byte-
   identical post-edit (per pack convention — trinity rule).

**Trinity considerations.** This batch IS the trinity edit. All three
template files + all three pack-repo files in the same commit. Per
CLAUDE.md "trinity rule" and architecture doc §6.1.

**Verification.**
- `python3 scripts/validate-pack.py` — Check 5 (agent file count),
  Check 9 (init-project structure), Check 18 (trinity H2 parity),
  Check 19 (trinity body scaffolding), Check 27 (agent canonical
  phrase) all must pass.
- `diff <(sed -n '/^## Skill loading/,/^## /p'
  project-template/CLAUDE.md) <(sed -n '/^## Skill loading/,/^## /p'
  project-template/AGENTS.md)` — produces only frontmatter delta if
  any (expected zero diff in the section body).
- Same diff for pack-repo trinity.
- `diff project-template/skills/architecture-review/SKILL.md
  project-template/.claude/skills/architecture-review/SKILL.md` →
  empty.
- `grep -n "cross-platform UI"
  project-template/skills/audit-methodology/SKILL.md` → 1 line in
  rule 20.

**Risk.** Trinity asymmetry creep — easy to edit CLAUDE.md and forget
AGENTS.md / GEMINI.md. Mitigation: implement as one Edit call per
file in a single batch; reviewer flags any asymmetry. Also: the four
architecture-review copies are byte-identical mirrors enforced by
Check 9; coder must edit all four or Check 9 fails.

**Commit message.** `docs: v11 — BD-143 trinity Skill-loading prose + audit-methodology rule 20 cross-platform UI + architecture-review skill list`


---

### Batch 5 — BD-144: add-capability.sh D5 + platform extensions

**BD assignment.** BD-144. Title: "add-capability.sh — D5 deployment
rows + platform:android/web-browser/embedded-mcu rows + intersection
load fix for role:python-server". Status: Open. Blockers: BD-142.
Unblocks: None.

**Scope.** Single file: `scripts/add-capability.sh` (lines 107-127
`capability_skills()` and 129-140 `capability_files()`). Plus
`scripts/lib/detect.sh` `detect_installed_capabilities()` (line 242)
needs reciprocal additions for skill→capability reverse mapping.

**Implementation steps.**

1. Edit `capability_skills()` (line 107) — add rows:
   - `deployment:apple` → `deployment-apple`
   - `deployment:linux-container` → `deployment-python` (with comment
     noting D2=python precondition per architecture §3.5).
   - `platform:android` → `android-architecture` (skill not yet
     present — Phase 3 will add it; row exists for forward
     compatibility).
   - `platform:web-browser` → `web-architecture`.
   - `platform:embedded-mcu` → `embedded-mcu-architecture` (renamed
     from any prior `platform:embedded` entries — there are none
     today).
   - PLANNER NOTE: confirm with maintainer whether forward-declared
     rows are acceptable when the SKILL.md is not yet shipped, or
     whether these rows should land in Phase 3 alongside the SKILLs.
2. Edit `role:python-server` row (line 124) — change skill list to
   include both `python-server-architecture` and
   `python-data-architecture` (currently only the server skill;
   architecture §3.7 intersection table mandates both load when D2=python
   ∩ D3=server).
3. Edit `scripts/lib/detect.sh` `detect_installed_capabilities()` (line
   275-292 case statement) — add reciprocal mappings: `deployment-apple
   → deployment:apple`, `deployment-python → deployment:linux-container`
   (replacing the current `role:apple-app` and `role:python-server`
   mappings, which are wrong dimensions). Keep the `role:` mappings as
   well if migration ergonomics demand backward compat — PLANNER
   NOTE: the current `role:apple-app` and `role:python-server`
   capability mappings are mis-classified per the new D5; coordinate
   the rename with the user before flipping. Safe default:
   ADD the new `deployment:` rows and DEPRECATE the `role:` rows in
   a follow-up.
4. Edit `capability_files()` (line 129) — no new rows yet; the new
   platforms have no conditional script files to copy.
5. **Permission-bit hygiene** — `ls -l scripts/add-capability.sh
   scripts/lib/detect.sh` after edits. add-capability.sh must remain
   executable.

**Trinity considerations.** None — script-only batch.

**Verification.**
- `python3 scripts/validate-pack.py`.
- `bash -n scripts/add-capability.sh scripts/lib/detect.sh`.
- Smoke: `bash scripts/add-capability.sh --help` runs to exit 0.
- Smoke: source detect.sh, build a fake CLAUDE.md with
  `**Active skills:** deployment-apple` and assert
  `detect_installed_capabilities` echoes `deployment:apple` (or both
  the new and old, depending on PLANNER NOTE resolution).
- `ls -l scripts/add-capability.sh` shows `-rwxr-xr-x`.

**Risk.** Forward-declared platform skills (`web-architecture` etc.)
that don't yet exist will cause `add-capability.sh --add
platform:web-browser` to "succeed" but the PM-chat follow-up to fail
when it tries to read the SKILL.md. Mitigation: gate the
forward-declared rows behind a directory-exists check, or emit a
warning when the resolved skill directory is missing. Coder picks the
implementation per maintainer guidance from PLANNER NOTE.

**Commit message.** `feat: v11 — BD-144 add-capability.sh D5 deployment rows + role:python-server intersection fix`

---

### Batch 6 — BD-145: init-project.sh detection extension

**BD assignment.** BD-145. Title: "init-project.sh — D1/D5 detection
hint + python-data marker integration". Status: Open. Blockers:
BD-141, BD-142. Unblocks: None.

**Scope.** Single file: `scripts/init-project.sh`. Two edit sites:
- `pack_skill_coverage_for()` lines 219-228 — already touched by
  BD-141 for the python row; this batch adds D1 hints for
  swift/proto/python rows pointing at PLATFORM-SKILLS.md's new D1-D5
  tables.
- Post-install hint that mentions BD-136 trinity markers (search for
  the term `BD-136` near the end-of-run prompt) — add one line
  pointing the PM chat at PLATFORM-SKILLS.md's new "Tier 0 base" and
  "Intersection table" sections.

**Implementation steps.**

1. Edit `pack_skill_coverage_for()` at lines 219-228. Update each
   language case to emit the dimension membership in a comment (e.g.,
   `# swift: D1=ios|macos (D1-implied) + D2=swift via D1`). Skill list
   itself does not change.
2. Locate end-of-run prompt block (greppable
   `'Active skills:'` near a `cat <<EOF` site). Insert one paragraph:
   "PLATFORM-SKILLS.md was reframed in v11 to use 5 dimensions plus
   Tier 0 base / trigger / intersection mechanisms. Read §"How skill
   selection works" for the new framing before generating prompts."
3. **Permission-bit hygiene** — `ls -l scripts/init-project.sh`.

**Trinity considerations.** None — script-only batch.

**Verification.**
- `python3 scripts/validate-pack.py` (Check 9 — init-project
  structure — must pass).
- `bash -n scripts/init-project.sh`.
- Smoke against a scratch dir: `bash scripts/init-project.sh
  --project /tmp/scratch-init` and inspect the printed prompt; verify
  the new paragraph appears.
- `ls -l scripts/init-project.sh` shows `-rwxr-xr-x`.

**Risk.** Check 9 (init-project structure) is sensitive to the prompt
format. Mitigation: the post-install prompt is prose; Check 9 enforces
file-tree shape, not prompt prose. Coder verifies Check 9 outputs are
unchanged.

**Commit message.** `feat: v11 — BD-145 init-project.sh prompt hints for 5-dimension PLATFORM-SKILLS.md`

---

### Batch 7 — BD-146: validate-pack.py Check 31 + Check 27 extension

**BD assignment.** BD-146. Title: "validate-pack.py Check 31
(skill-cell consistency) + Check 27 extension (per-agent skill list
conformance)". Status: Open. Blockers: BD-142, BD-143. Unblocks:
BD-150.

**Scope.** Single file: `scripts/validate-pack.py`. Two edit sites:
- New Check 31 function (~80-120 LoC) appended after existing Check 30
  (line ~2174). PLANNER NOTE: architecture doc says "Check 32"; actual
  next free is **31**. Use 31 unless maintainer overrides.
- Extension to existing Check 27 (line 1304-1369) to read each agent
  file's "Skills to load" block (where present) and verify it matches
  PLATFORM-SKILLS.md's per-agent assignment.

**Implementation steps.**

1. Add Check 31 function `check_skill_cell_consistency()`:
   - Parse PLATFORM-SKILLS.md tables (D1, D2, D3, D4, D5, Tier 0
     base, intersection, trigger). Build set of skill names appearing
     in any cell.
   - Enumerate `project-template/skills/*/` directories. Build set of
     SKILL.md skill names.
   - Assert: every skill in `project-template/skills/` appears in
     exactly one PLATFORM-SKILLS.md cell (modulo the intersection
     table, which is allowed to repeat a skill from a dimension cell
     for the predicate).
   - Assert: every skill name referenced in any agent file
     (`project-template/.claude/agents/*.md`,
     `project-template/.codex/agents/*.toml`,
     `project-template/.gemini/agents/*.md`) exists as a SKILL.md
     directory.
   - Assert: intersection-table predicate strings parse as
     `D{1-5}={value}( ∩ D{1-5}={value})*`.
2. Extend Check 27 (or add a new case under it) — for each agent file
   that declares a "Skills to load:" block, parse the skill list and
   compare against PLATFORM-SKILLS.md §"Step 2 — Select skills per
   agent" table for that agent. Asymmetry → fail with file:line
   pointer.
3. Register Check 31 in the main runner (search the existing checks
   registration block).
4. Update the docstring header at line ~785 that lists checks 25, 26,
   etc., to add Check 31.

**Trinity considerations.** None directly. But Check 27 extension may
flag agent files where the agent's "Skills to load" diverges from the
new PLATFORM-SKILLS.md per-agent table — those divergences are
PLATFORM-SKILLS-truth bugs, not agent-file bugs (resolution: edit
PLATFORM-SKILLS.md or amend BD-142). PLANNER NOTE: if Check 27
extension produces unexpected fails after BD-142 + BD-143, return to
BD-142 and reconcile.

**Verification.**
- `python3 scripts/validate-pack.py` — all 31 checks (1-30 + new 31)
  pass.
- Manual: introduce a scratch agent file with a bogus skill name in
  its "Skills to load" block; assert Check 31 fails with that
  filename. Revert.
- Manual: manually add a SKILL.md directory not referenced anywhere in
  PLATFORM-SKILLS.md; assert Check 31 fails. Revert.

**Risk.** False positives if PLATFORM-SKILLS.md table parsing is
brittle. Mitigation: parser uses Markdown-table heuristics (look for
`| skill-name |` patterns under each `### Dimension N` heading) —
keep the parser tolerant, prefer false-negative (allow) over
false-positive (reject) when ambiguous, and emit warnings in those
cases per the existing validate-pack.py warning convention.

**Commit message.** `feat: v11 — BD-146 validate-pack.py Check 31 (skill-cell consistency) + Check 27 per-agent skill-list conformance`

---

### Batch 8 — BD-147: scripts/lib/migrator-skills.sh extraction + S5b rewrite

**BD assignment.** BD-147. Title: "Extract S5b BD-035 rename helper
into scripts/lib/migrator-skills.sh; rewrite migrate-v10-to-v11.sh
S5b to call it". Status: Open. Blockers: BD-142. Unblocks: None.

**Scope.**
- New file: `scripts/lib/migrator-skills.sh` (~150-200 LoC).
- Edit: `scripts/migrate-v10-to-v11.sh` lines 338-500 (S5b helper
  `_v10_to_v11_rename_python_architecture_refs`). Replace inline
  body with a call to the new library API.
- New tests: `scripts/test-migrator-skills.sh` (~100-200 LoC) covering
  both rename and split paths.

**Implementation steps.**

1. Create `scripts/lib/migrator-skills.sh` with public function
   `migrator_skill_rename` per architecture §6.5 contract:
   - Args (long-flag, per pack convention): `--from <old>`,
     `--to-server <name>`, `--to-data <name>`, `--to <new>`,
     `--advisory <path>`, `--files <space-list>`,
     `--server-signal <regex>`, `--data-signal <regex>`.
   - Either `--to <new>` (rename) OR `--to-server`+`--to-data` (split)
     must be present, not both.
   - Behavior: per-line scan + disambiguation per the existing S5b
     rules (lines 365-377). Writes advisory file when ambiguous
     sites found.
   - Shellcheck-clean.
2. Rewrite `scripts/migrate-v10-to-v11.sh` S5b function (line 388) to:
   - Source `lib/migrator-skills.sh` via the existing source pattern
     (relative to script dir).
   - Call `migrator_skill_rename --from python-architecture
     --to-server python-server-architecture --to-data
     python-data-architecture --advisory
     "$_MIGRATOR_STATE_DIR/python-architecture-rename.advisory"
     --files "..." --server-signal "..." --data-signal "..."`.
   - Preserve the user-facing log output (`info`, `say` lines) so
     migrator UX is byte-equivalent.
3. Create `scripts/test-migrator-skills.sh` covering: (a) clean
   rename of fictional skill `foo-bar` → `baz-quux`; (b) split with
   server/data disambiguation; (c) ambiguous case generates advisory;
   (d) idempotent re-run is a no-op.
4. Add the test to the aggregate CI runner (search for the existing
   `test-migrator-core.sh` registration site).
5. **Permission-bit hygiene** — `ls -l scripts/migrate-v10-to-v11.sh
   scripts/test-migrator-skills.sh`. Both must be `-rwxr-xr-x`.
   `migrator-skills.sh` is sourced (no exec bit needed).

**Trinity considerations.** None.

**Verification.**
- `python3 scripts/validate-pack.py` — Check 26 (BD-119 framework
  inventory) must still pass; if it lists scripts/lib/* explicitly,
  the new file may need to be added to its inventory. **PLANNER
  NOTE: confirm Check 26's inventory matcher behavior before BD-147
  ships; if Check 26 enforces an exact list, BD-147 must also patch
  Check 26.**
- `bash scripts/test-migrator-skills.sh` — passes all cases.
- `bash scripts/test-migrate-v10-to-v11-dry-run.sh` (existing) — still
  passes (S5b output byte-equivalent).
- `shellcheck scripts/lib/migrator-skills.sh` (if shellcheck is in CI;
  otherwise visual review).
- `ls -l scripts/migrate-v10-to-v11.sh scripts/test-migrator-skills.sh`
  — both `-rwxr-xr-x`.

**Risk.** Behavior drift from the original inline S5b (subtle regex
differences in disambiguation). Mitigation: the test suite covers the
exact rules in the original (lines 365-377). Run dry-run migrator
against the v10-realistic-ot fixture and diff the output state dir
against a golden snapshot taken pre-extraction.

**Commit message.** `refactor: v11 — BD-147 extract BD-035 skill-rename helper to scripts/lib/migrator-skills.sh; S5b calls library API`

---

### Batch 9 — BD-148: MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md "Skill model changes" section

**BD assignment.** BD-148. Title: "MIGRATION-v10-to-v11.md +
MERGE-STRATEGY.md skill-model-changes documentation". Status: Open.
Blockers: BD-142, BD-143. Unblocks: BD-150.

**Scope.**
- `supporting-docs/MIGRATION-v10-to-v11.md` — add new H2 "Skill model
  changes" near the existing skill-rename section. ~50-80 lines.
- `supporting-docs/MERGE-STRATEGY.md` — verify PLATFORM-SKILLS.md
  preservation rules still hold under the reshape; note the D1-D5
  table reshape is `transform`-class, not user-customization-class.
  ~10-line update.

**Implementation steps.**

1. Edit `supporting-docs/MIGRATION-v10-to-v11.md`. Add H2 "Skill
   model changes (BD-142)" with subsections:
   - "What changed" — 4 → 5 dimensions; Tier 1/Tier 2 →
     Tier 0 base / dimensional / trigger / intersection.
   - "Behavioral impact" — per architecture §7.8: PLATFORM-SKILLS.md
     reshape is a behavioral change, not a doc-only change. Locally-
     edited PLATFORM-SKILLS.md will need re-application (per
     architecture §7.6).
   - "Migrator handling" — references S5b for the BD-035 split case;
     notes the dimension reframe itself requires no migrator work
     (clients see identical SKILL.md files in identical directories).
   - "BD-136 trinity-marker non-overlap" — per architecture §6.7 —
     S5b advisory and trinity-marker preservation are
     non-overlapping mechanisms.
   - "D5 monorepo gotcha" — per architecture §7.4 — document the
     monorepo-scoping convention.
2. Edit `supporting-docs/MERGE-STRATEGY.md` — locate
   PLATFORM-SKILLS.md row in the per-file matrix; add a note that
   §"How skill selection works" through §"Full skill inventory" are
   `transform`-class (pack-managed), and `## Custom agents` /
   `## Custom skills` remain user-owned.

**Trinity considerations.** None — supporting-docs only.

**Verification.**
- `python3 scripts/validate-pack.py`.
- `grep -c "^## Skill model changes" supporting-docs/MIGRATION-v10-to-v11.md`
  → 1.
- `grep -n "PLATFORM-SKILLS.md" supporting-docs/MERGE-STRATEGY.md` —
  the matrix row mentions both `transform` and `user-owned` per the
  reshape.

**Risk.** Stale references in MIGRATION-v10-to-v11.md to the old
"4 dimensions" framing. Mitigation: `grep -n "four dimension" supporting-docs/`
audit before commit; replace any survivors.

**Commit message.** `docs: v11 — BD-148 MIGRATION-v10-to-v11 + MERGE-STRATEGY skill-model-changes section`

---

### Batch 10 — BD-149: PLATFORM-SKILLS.md "Extending this file" naming convention codification

**BD assignment.** BD-149. Title: "Document skill naming convention in
PLATFORM-SKILLS.md (no skill renames)". Status: Open. Blockers:
BD-142. Unblocks: None.

**Scope.** Single file:
`project-template/docs/pack/PLATFORM-SKILLS.md` — §"Extending this
file" (currently lines 349-356). Adds ~15 lines under that heading.

**Implementation steps.**

1. Edit §"Extending this file" to add a "Naming convention for new
   skills" subsection per architecture §7.10:
   - `*-best-practices` — languages with idiomatic-style rules.
   - `*-language` — languages where ownership / memory / interop
     dominate.
   - `*-architecture` — platform-specific structural rules.
   - `*-patterns` — cross-cutting concerns.
   - Existing skills are NOT renamed (architecture §7.10 user
     decision 7); convention applies to NEW skills only.
2. Add a one-line note: "BD-155 tracks a future v12 enforcement
   migration; v11 is documentation-only."

**Trinity considerations.** None.

**Verification.**
- `python3 scripts/validate-pack.py` — Check 31 (BD-146) must still
  pass (no skill name changes; tables remain consistent).
- `grep -n "Naming convention" project-template/docs/pack/PLATFORM-SKILLS.md`
  → 1.
- Skill-directory listing diff against pre-batch is empty (no
  renames).

**Risk.** Coder accidentally renames an existing skill thinking the
convention applies retroactively. Mitigation: the BD entry, the
architecture doc, and the user decision 7 all explicitly say "do
not rename"; the prompt and review check `git status` pre-commit to
confirm only PLATFORM-SKILLS.md is modified.

**Commit message.** `docs: v11 — BD-149 codify skill naming convention in PLATFORM-SKILLS.md (no renames)`

---

### Batch 11 — BD-150: CHANGELOG.md + README.md skill-count + version-table touch

**BD assignment.** BD-150. Title: "CHANGELOG v11.0 entry for skill
dimensions reframe + README.md skill-count and version-table refresh".
Status: Open. Blockers: BD-146, BD-148. Unblocks: FINAL Phase-2A
handoff.

**Scope.**
- `CHANGELOG.md` — single new entry line under the v11.0 section
  referencing BD-140..BD-150.
- `README.md` — Repository Layout `skills/` line currently says
  "(30 skills)" (line 101) — change to "(31 skills)" to match the
  current count and PLATFORM-SKILLS.md's "Total skills: 31". Version
  table v11.0 row (line 60) gains `BD-142 skill-dimensions reframe`
  mention if the row text is editable in this batch (per CLAUDE.md
  policy, README version table edits are PM-chat-only — PLANNER NOTE:
  confirm whether BD-150 may touch the version table or only the
  layout count).

**Implementation steps.**

1. Edit `CHANGELOG.md`. Locate the v11.0 entry block (or insert if
   the entry is currently a placeholder). Add a bullet:
   "Skill-dimensions reframe (BD-140..BD-150, design at
   maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md):
   PLATFORM-SKILLS.md restructured from 4 dimensions to 5 dimensions +
   Tier 0 base / trigger / intersection load mechanisms; trinity prose
   updated; new validate-pack Check 31; migrator-skills.sh shared
   library for skill renames; new python_data_marker_detected
   detection helper."
2. Edit `README.md` line 101 (Repository Layout `skills/` line) —
   change "(30 skills)" to "(31 skills)" to reconcile with
   PLATFORM-SKILLS.md count.
3. **DO NOT** edit the README version table (line 58-83) without
   explicit user/PM-chat approval per CLAUDE.md "What agents must
   never modify without explicit instruction". PLANNER NOTE: the
   architecture doc says the version table "may want a 'skill model
   reframed (BD-NNN)' mention". Defer this to a Pack Chat decision; do
   NOT include in BD-150 unless explicitly approved.

**Trinity considerations.** None.

**Verification.**
- `python3 scripts/validate-pack.py` — Check 4 (README version table
  vs git tag) must still pass.
- `grep -c "31 skills" README.md` → ≥1.
- `grep -n "BD-142" CHANGELOG.md` → ≥1.

**Risk.** Skill count drift if any of BD-141..BD-149 inadvertently add
or remove a skill directory. Mitigation: this is the last batch in
sequence; coder runs `find project-template/skills -maxdepth 1 -type d
| wc -l` and confirms the count matches "31 skills" before the
README edit.

**Commit message.** `docs: v11 — BD-150 CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh`


---

## 3. BACKLOG additions table

| BD | Title | Classification | Batch |
|---|---|---|---|
| BD-140 | Skill-dimensions reframe — BACKLOG entries (umbrella) | Open / v11.0 | Batch 1 |
| BD-141 | Concrete python-data-architecture load predicate (lib/detect.sh marker) | Open / v11.0 | Batch 2 |
| BD-142 | PLATFORM-SKILLS.md 5-dimension reframe + Tier 0 + intersection + trigger tables | Open / v11.0 | Batch 3 |
| BD-143 | Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list | Open / v11.0 | Batch 4 |
| BD-144 | add-capability.sh D5 rename + platform extensions + role:python-server intersection fix + v10→v11 migrator translation | Open / v11.0 | Batch 5 |
| BD-145 | init-project.sh detection + skill-coverage extension | Open / v11.0 | Batch 6 |
| BD-146 | validate-pack.py Check 31 + Check 27 extension | Open / v11.0 | Batch 7 |
| BD-147 | scripts/lib/migrator-skills.sh extraction + S5b rewrite | Open / v11.0 | Batch 8 |
| BD-148 | MIGRATION-v10-to-v11 + MERGE-STRATEGY skill-model-changes documentation | Open / v11.0 | Batch 9 |
| BD-149 | PLATFORM-SKILLS.md "Extending this file" naming convention codification | Open / v11.0 | Batch 10 |
| BD-150 | CHANGELOG v11.0 entry + README skill-count refresh | Open / v11.0 | Batch 11 |
| BD-151 | Tier 0 observability skill (per architecture §7.1) | Open / Deferred to v12 | Created in Batch 1 |
| BD-152 | Tier 0 accessibility skill (per architecture §7.2) | Open / Deferred to v12 | Created in Batch 1 |
| BD-153 | Tier 0 concurrency-architecture skill (per architecture §7.3) | Open / Deferred to v12 | Created in Batch 1 |
| BD-154 | Skill-versioning frontmatter convention (per architecture §7.9) | Open / Deferred to v12 | Created in Batch 1 |
| BD-155 | Naming-convention enforcement migration (per architecture §7.10) | Open / Deferred to v12 | Created in Batch 1 |
| BD-156 | `protobuf-patterns` skill — extract Proto3 schema rules from grpc-patterns; standalone-usable via intersection table | Open / v11.0 | Batch 12 (added 2026-05-11 post-planner; hard blocker for BD-149) |
| BD-157 | `apple-swiftdata-patterns` skill — SwiftData object-store rules for Apple platforms (intersection-cell loading) | Open / v11.0 | Batch 13 (added 2026-05-11 post-planner; hard blocker for BD-149) |
| BD-158 | `swift-concurrency-patterns` skill — Modern Swift Concurrency + GCD (D1-implied loading for D1 ∈ {ios, macos}) | Open / v11.0 | Batch 14 (added 2026-05-11 post-planner; hard blocker for BD-149) |

**Total new BDs: 19** (14 v11.0 batch BDs + 5 v12-deferred BDs).

---

## 4. Cross-cutting risks and mitigations

### 4.1 Trinity rule violations

- **Risk.** BD-143 edits 6 trinity files (3 template + 3 pack-repo)
  plus 4 architecture-review SKILL.md copies. Easy to miss one.
- **Mitigation.** BD-143 verification step requires `diff` between
  every pair of trinity files in the section body and `diff` between
  every pair of architecture-review SKILL.md copies. Reviewer
  pre-commit pass catches asymmetry. Check 9 (init-project structure)
  and Check 18 (trinity H2 parity) enforce structurally.

### 4.2 Permission-bit hygiene

- **Risk.** The Edit tool has been observed stripping `+x` on `.sh`
  files in prior batches. BD-141, BD-144, BD-145, BD-147 all edit
  executable scripts.
- **Mitigation.** Every batch that edits a `.sh` file ends with
  `ls -l <files>` and asserts `-rwxr-xr-x`. If stripped, run
  `chmod +x <file>` before commit. Reviewer enforces.

### 4.3 validate-pack.py check numbering

- **Risk.** Architecture doc says "Check 32"; actual next-free check is
  31. If two simultaneous BDs (e.g., BD-146 and an unrelated
  in-flight BD) both grab Check 31, collision.
- **Mitigation.** This plan uses **Check 31**. PLANNER NOTE in §0
  asks maintainer to confirm. Coder for BD-146 must `grep -nE "Check
  [0-9]+" scripts/validate-pack.py | tail` immediately before coding
  to verify still-free.

### 4.4 PLATFORM-SKILLS.md — pack product vs pack ops separation

- **Risk.** PLATFORM-SKILLS.md's `## Custom agents` and `## Custom
  skills` sections are project-owned per BD-088 customization-preserve.
  An over-eager rewrite in BD-142 deletes the illustrative `x-deployer`
  / `x-brokerage-api` rows, breaking the BD-088 sidecar tests.
- **Mitigation.** BD-142 implementation step 6 explicitly says "do not
  edit lines 310-345"; verification step requires `git diff
  --stat` to confirm those line bytes are unchanged.

### 4.5 BD-035 S5b regression in BD-147 extraction

- **Risk.** Extracting the inline S5b helper to a library may
  introduce subtle regex / edge-case differences that break the
  client-side rename for v10→v11 migrations.
- **Mitigation.** BD-147 includes a behavior-equivalence test:
  golden-snapshot the migrator's S5b output state-dir against the
  v10-realistic-ot fixture pre-extraction; compare post-extraction.

### 4.6 Forward-declared platform skills (BD-144)

- **Risk.** BD-144 adds `platform:android` / `platform:web-browser` /
  `platform:embedded-mcu` rows to add-capability.sh, but the SKILL.md
  files don't ship until Phase 3. PM chat or developer running
  `add-capability.sh --add platform:web-browser` mid-v11.0 hits a
  missing skill.
- **Mitigation.** PLANNER NOTE in BD-144 step 1 — coordinate with
  maintainer; default to gating with directory-exists check + warning.

### 4.7 Stale "four dimensions" references

- **Risk.** Other docs (METHODOLOGY.md, supporting-docs/*) may
  reference "four dimensions" or "Tier 1/Tier 2"; missed updates leave
  stale prose.
- **Mitigation.** Pre-final-batch grep audit:
  `grep -rn "four dimension\|Tier 1\|Tier 2" project-template/
  supporting-docs/ maintenance-docs/v11-implementation/` — expected
  matches only inside this PLAN doc and the architecture doc.

### 4.8 Worktree isolation broken from v11-dev clone

- **Risk.** When Pack Chat spawns sub-agents via the Agent tool, the
  sub-worktree lands at `origin/main` (v10.1 HEAD), not v11-dev.
  Sub-agents would audit / edit stable content instead of the v11-dev
  branch.
- **Mitigation.** **Do not pass `isolation: "worktree"` when spawning
  sub-agents from any chat in this repo.** Run agents in-place against
  the parent chat's working tree. For the FINAL Phase-2A handoff
  spawning, this rule applies.

### 4.9 CI gating

- **Risk.** Mid-batch CI break from a single missed update.
- **Mitigation.** Each batch's verification step lists the exact
  validate-pack.py check that proves correctness. Pack Chat runs
  `python3 scripts/validate-pack.py` locally pre-commit; CI reruns
  on push. Never skip or disable the workflow.

---

## 5. Operating discipline

- **Stop-before-each-commit.** This plan does NOT include `git commit`
  or `git push` commands. Pack-coder edits the working tree and writes
  a report; Pack Chat reviews the report and commits with explicit
  user approval per batch.
- **One review/fix cycle per batch.** Spawn pack-reviewer once per
  batch, fix once, mark Resolved. Do NOT propose a second review
  pass; final audit is user-initiated.
- **Implicit BD status flip on batch completion.** When a batch's
  review + fixes are clean and validate-pack passes, flip the BD to
  Resolved as the final step of the batch — no separate user
  approval needed.
- **Agent prompt rules.** Every coder prompt includes context, output
  file path, read-only flags where applicable, markdown-only
  directive, problem/goal/success criteria, and the chunk-long-writes
  instruction. No proposed solutions in prompts; coder reaches own
  conclusions.
- **Sub-agent isolation.** Do not pass `isolation: "worktree"` when
  spawning. Run in-place against the parent chat's working tree.

---

## 6. Phase 2A handoff

After all 14 batches above ship and BD-150 is Resolved, Pack Chat
spawns a fresh `pack-architect` session to design Phase 2A: per-skill
rule designs for `web-architecture`, `android-architecture`, and
`embedded-mcu-architecture`. This planner does NOT plan the SKILL.md
authoring itself — Phase 2B (planning) and Phase 3 (coder
implementation) follow the architect's Phase 2A output.

### 6.1 Architect-prompt input list (concrete)

The Phase 2A architect prompt must include pointers to:

- **`maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`**
  — full document. Specifically:
  - §2 (web-architecture rule list, ~12 + 6 localization rules,
    proposed Pattern C per architecture §2.4).
  - §3 (android-architecture, ~13 + 6 localization rules, Pattern C
    per architecture §2.4).
  - §4 (embedded-mcu-architecture, ~11 + 5 localization rules,
    Pattern C, renamed from `embedded-architecture` per architecture
    §2.5).
  - §5 (cross-platform UI checklist — already absorbed into
    audit-methodology rule 20 by BD-143).
  - Risk 1 (embedded-Linux scope — DEFERRED to later v11.x or v12.0
    per architecture §2.5).
  - Risk 2 (Pattern C decision — already settled for all three).
  - Risk 3 (auditor-ui detection markers reading PLATFORM-SKILLS.md —
    already addressed in BD-143).
- **`project-template/docs/pack/PLATFORM-SKILLS.md`** as it stands
  AFTER BD-142 + BD-149 ship — the new D1 table will already have
  the deferred `android`, `web-browser`, `embedded-mcu` rows; Phase 2A
  populates the skills they reference.
- **`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`**
  §2.4-§2.6 (pattern-selection rules), §6.6 (Phase 2A scope
  definition).
- **User decisions to bake in:**
  - Web → **Pattern C** (single skill).
  - Android → **Pattern C** (single skill).
  - Embedded → **embedded-MCU only** (Pattern C); **embedded-Linux
    deferred** to a later minor.
  - Each new SKILL.md ships in its own commit with its corresponding
    PLATFORM-SKILLS.md row addition (per user decision 2).

### 6.2 Architect output expected

A new design doc:
`maintenance-docs/v11-implementation/ARCHITECTURE-NON-APPLE-UI-SKILLS-PHASE-2A.md`
containing:

- Per-skill rule list (numbered, applicability section, examples
  pattern matching the existing apple-architecture-core /
  python-server-architecture / python-data-architecture shape).
- Per-skill agent assignment (which agents load it under the
  PLATFORM-SKILLS.md per-agent table — to be reconciled by Phase 2B
  planner against the post-BD-142 tables).
- Detection-marker list per skill (consumed by add-capability.sh and
  the auditor-ui detection extension).
- Localization-rule sub-list per skill.
- Pattern justification (Pattern C per user decision; architect
  confirms or surfaces a counter-recommendation with rationale).

### 6.3 Subsequent Phases

- **Phase 2B** — pack-planner pass: sequences the 3 SKILL.md writes
  + PLATFORM-SKILLS.md row populations + add-capability.sh / auditor
  detection updates into 3 commit batches (one per skill, per user
  decision 2).
- **Phase 3** — pack-coder: implements each batch.

This planner's job ends at the Phase-2A architect prompt. Pack Chat
is the convener for the Phase 2A spawn.

### 6.4 Sub-agent spawn instruction

When spawning the Phase 2A architect: **do NOT pass
`isolation: "worktree"`.** Run in-place against the v11-dev working
tree. Per CLAUDE.md "Sub-agent isolation" — worktree isolation lands
at `origin/main`, not v11-dev. Use a fresh non-worktree-isolated
sub-agent or open a separate Claude Code chat session in the v11-dev
worktree directory.

---

## 7. Resolved planner-note decisions (2026-05-11)

All five planner notes have been resolved by the user (2026-05-11).
The resolutions below are authoritative. The §2 batch sections still
contain "PLANNER NOTE:" prefixed lines; treat those as resolved per
the corresponding entry below. Scope deltas where the resolution
expanded a batch's work are described in §7.1 (BD-144) and §7.2
(BD-147) as additive sections rather than in-place §2 rewrites.

1. **Check number for new validate-pack.py check.** **RESOLVED: 31.**
   Architecture doc said 32; actual next-free is 31. BD-146 uses 31.
2. **add-capability.sh forward-declared platform rows (BD-144).**
   **RESOLVED: forward-declared with directory-exists guard + warning.**
   Rows ship in BD-144; resolution warns when the SKILL.md directory is
   absent until Phase 3 lands the SKILLs.
3. **detect_installed_capabilities reciprocal mapping + token rename.**
   **RESOLVED: replace immediately, with full migrator translation
   coverage. Bundled into BD-144 (no v11.1 deferral).** See §7.1 below
   for the expanded BD-144 scope (8 file changes including migrator
   translation stage and v10-fixture golden-snapshot test).
4. **README version table edit (BD-150).** **RESOLVED: skip entirely.**
   BD-150 does NOT touch the version table at all. PM Chat does a single
   pre-release pass at v11.0 close to reconcile the v11.0 row
   description across all v11 batches. BD-150 only updates
   `README.md:101` `(30 skills)` → `(31 skills)` layout count line.
5. **Check 26 inventory enforcement (BD-147).** **RESOLVED: extend
   Check 26.** `migrator-skills.sh` is blessed as a fourth BD-119
   framework lib. BD-147 also patches `ARCHITECTURE-BD-119.md` and
   `PLAN-BD-119.md` to mention it. See §7.2 below for the expanded
   BD-147 scope.

### 7.1 BD-144 expanded scope (per resolution 3)

BD-144's title and scope grow to include token rename + migrator
translation. The `role:apple-app` token is renamed to `deployment:apple`
(it was always misnamed — Apple-app is a D5 deployment surface, not a
D3 architectural role); `role:python-server` is preserved (legitimate
D3 role) but its resolved skill list changes (drops `deployment-python`,
adds `python-data-architecture` per intersection); a new
`deployment:linux-container` capability row carries `deployment-python`.

**Updated title:** "add-capability.sh D5 rename + platform extensions
+ role:python-server intersection fix + v10→v11 migrator translation
stage".

**Updated scope.** Files touched grow from 2 to 6:
- `scripts/add-capability.sh` (token rename + new rows + intersection)
- `scripts/lib/detect.sh` (reciprocal mapping update)
- `scripts/test-detect.sh` (assertion updates for new resolution)
- `scripts/migrate-v10-to-v11.sh` (NEW migrator translation stage)
- A v10-fixture golden-snapshot test (location TBD by coder; likely
  `scripts/test-migrate-v10-to-v11-dry-run.sh` extension or a sibling
  test file)
- `add-capability.sh --help` text (grep + replace `role:apple-app`)

**Additional implementation steps** (append to BD-144 §2 step list):

- Step 6 (NEW). **Migrator translation stage.** Add a stage to
  `scripts/migrate-v10-to-v11.sh` that translates v10.x trinity-file
  capability lines:
  - `capabilities: ...role:apple-app...` → `...deployment:apple...`
    (token rename in CLAUDE.md / AGENTS.md / GEMINI.md `capabilities:`
    line at the top of each trinity file).
  - For projects with `role:python-server` in `capabilities:`, append
    `deployment:linux-container` to the same line so the project does
    not silently lose its `deployment-python` skill.
  - Stage is idempotent (re-running on an already-translated line is
    a no-op).
  - Stage emits an advisory file
    (`.pack-migrate-v10-to-v11/capability-rename.advisory`) listing
    every line touched, the before/after, and the per-trinity-file
    rationale.
- Step 7 (NEW). **Test-detect.sh assertion update.** The existing
  test at line 285 calls add-capability.sh with `role:python-server`;
  update its asserted resolved skill list to drop `deployment-python`
  and add `python-data-architecture`.
- Step 8 (NEW). **--help text grep + replace.** Run
  `grep -n "role:apple-app" scripts/add-capability.sh` — replace any
  in-line --help text or comments with `deployment:apple`.
- Step 9 (NEW). **Golden-snapshot test for migrator translation.**
  Build (or extend) a v10-fixture project with
  `capabilities: language:python, role:python-server, role:apple-app`
  in CLAUDE.md / AGENTS.md / GEMINI.md. After dry-run migration,
  assert the resulting trinity files contain
  `capabilities: language:python, role:python-server,
  deployment:linux-container, deployment:apple` (order tolerant) and
  that the advisory file lists 6 line-touches (3 trinity files × 2
  edits each).

**Additional verification** (append to BD-144 §2 verification list):

- `bash scripts/test-migrate-v10-to-v11-dry-run.sh` (or successor)
  passes the new fixture.
- `grep -nR "role:apple-app" scripts/ project-template/` returns zero
  hits in pack-product files (archive / maintenance-docs may retain
  historical references; those are out of scope).
- The advisory file pattern matches the BD-035 S5b advisory shape
  (key/value blocks with file paths and per-line before/after).

**Additional risk.** Migrator translation regression for projects
with already-edited `capabilities:` lines (line was hand-edited
post-init, contains atypical whitespace). Mitigation: the translation
matches on the token boundary, not on full-line anchor; the advisory
file lists every touch so the user can review before accepting.

**Updated commit message.** `feat: v11 — BD-144 add-capability.sh
D5 rename (role:apple-app → deployment:apple) + role:python-server
intersection fix + v10→v11 migrator translation stage`.

### 7.2 BD-147 expanded scope (per resolution 5)

BD-147 also extends Check 26 in `validate-pack.py` to include
`migrator-skills.sh` as a blessed fourth BD-119 framework lib, and
updates `ARCHITECTURE-BD-119.md` + `PLAN-BD-119.md` to mention it.

**Additional scope.** Files touched grow from 3 to 5:
- `scripts/validate-pack.py` Check 26 (line 1783-~1880) — add
  `migrator-skills.sh` to the required-libs list with its own public-
  API function-name regex (`migrator_skill_rename`).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` — add a
  one-paragraph subsection naming `migrator-skills.sh` as a member of
  the BD-119 framework family with its API contract.
- `maintenance-docs/v11-implementation/PLAN-BD-119.md` — add the lib
  to the inventory list.

**Additional implementation steps** (append to BD-147 §2 step list):

- Step 6 (NEW). **Extend Check 26 in validate-pack.py.** Add
  `migrator-skills.sh` to the `for lib in (core, stages, manifest):`
  loop (becomes 4-element tuple). Add a regex-required public-API
  function name `migrator_skill_rename`. Update the docstring at line
  1788 to mention the fourth lib.
- Step 7 (NEW). **Update BD-119 docs.** In `ARCHITECTURE-BD-119.md`,
  add a §3.x subsection "migrator-skills.sh — skill-rename adapter"
  that names the public API and its purpose. In `PLAN-BD-119.md`,
  add the lib to the framework-inventory list.

**Additional verification.**
- `python3 scripts/validate-pack.py` — Check 26 now requires 4 libs;
  must pass with `migrator-skills.sh` present.
- `grep -n "migrator-skills.sh" maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
  → ≥1.
- `grep -n "migrator-skills.sh" maintenance-docs/v11-implementation/PLAN-BD-119.md`
  → ≥1.

### 7.3 BD-156, BD-157, BD-158 added post-planner (2026-05-11)

Three skill-content gaps were identified during the BD-142
model-validation checkpoint (2026-05-11) and added as v11.0 scope per
user direction. All three are hard blockers for BD-149 so the
`*-patterns` naming convention has worked examples AND the gaps close
before v11.0 ships rather than being deferred.

**BD-156: `protobuf-patterns`.** Today Proto3 schema rules are bundled
inside `grpc-patterns` (D4=grpc) — honest for the pack's gRPC use case
but excludes non-gRPC scenarios (binary file format, IPC payloads,
Twirp / Connect, persistent storage, log formats). BD-156 creates a
new `protobuf-patterns` skill loaded via the intersection table
(matches the `python-data-architecture` pattern of intersection-cell
loading by language ∩ marker). Predicate: any host language ∩ "project
has `.proto` files" marker. New helper `protobuf_marker_detected()`
in `scripts/lib/detect.sh` parallels BD-141's
`python_data_marker_detected()` shape.

**BD-157: `apple-swiftdata-patterns`.** SwiftData (iOS 17+ / macOS 14+)
is Apple's modern declarative object-store API on top of SQLite,
replacing CoreData for new development. Has substantial framework-
specific rules (`@Model` macro design, `ModelContainer`/`ModelContext`
threading, `FetchDescriptor` predicates, schema migrations, history
tracking, CloudKit sync) currently uncovered by `apple-architecture-core`
/ `ios-architecture` / `macos-architecture`. OT itself uses SwiftData,
making this immediately consequential. Predicate: `D1 ∈ {ios, macos} ∩
swiftdata-marker`. New helper `swiftdata_marker_detected()` parallels
BD-141 / BD-156 helper pattern. Demonstrates the maintainability
property — adding a new intersection-cell skill is a mechanical change.

**BD-158: `swift-concurrency-patterns`.** Modern Swift Concurrency
(async/await, actors, Sendable, Swift 6 strict checking) and Grand
Central Dispatch (GCD) are the two concurrency models in active use
across every nontrivial Apple project. Currently scattered across
`swift-best-practices` (brief Swift 6 mention) and
`apple-architecture-core` (brief actor-isolation mention). BD-158
creates a dedicated skill encoding both Modern Swift Concurrency rules
and GCD rules including modernization guidance. Loads as **D1-implied**
for D1 ∈ {ios, macos} per architecture §3.2 (matches `swift-best-practices`
loading pattern — every Apple project deals with concurrency, no marker
predicate needed). When BD-153 (the v12-deferred Tier 0
`concurrency-architecture` skill) lands, this Apple-Swift specialization
references BD-153 for cross-language principles.

**Sequencing:** All three ship before BD-149. BD-156 / BD-157 / BD-158
sit off the critical path (depend only on BD-142, plus BD-141 for the
helper-pattern precedent for the marker-using skills); BD-149 (also
off-path) gains all three as Blockers. BD-156 / BD-157 / BD-158 are
file-disjoint at the SKILL.md level (each new skill in its own
directory) and can ship in parallel; BD-158 additionally cross-edits
`swift-best-practices` and `apple-architecture-core` to strip brief
concurrency mentions and cross-reference, which is the only intra-
batch sequencing constraint.

**Effect on `grpc-patterns`:** refocused on gRPC-specific rules
(servicers, interceptors, streaming, deadlines, error model, async
handlers, grpc-swift-2 / grpc.aio specifics). The Proto3 schema-design
rules currently bundled there move to `protobuf-patterns`;
`grpc-patterns` ships with a one-paragraph "see `protobuf-patterns`
for schema rules; load both when gRPC is in use" pointer.

**Naming:** `protobuf-patterns` matches architecture §7.10 naming
convention for cross-cutting concerns (parallels `grpc-patterns`,
`rest-patterns`, `security-patterns`).

**Out of scope (explicitly):** no separate skills for JSON / YAML /
TOML — minimal standalone rules; fold into `api-design` (Tier 0) and
`rest-patterns` (D4=rest). A separate BD can be opened later if
standalone schema work for those formats becomes a need.

### 7.4 BD-148 expanded scope (BD-142 F3 deferred fix)

The BD-142 pack-reviewer surfaced F3 (NIT): the `## Custom agents`
table in PLATFORM-SKILLS.md (line 510 in the v11.0 reframe state)
carries column headers `Tier 1 skills | Tier 2 skills` from the
deprecated pre-v11 framing. BD-142 preserved the section byte-identical
per BD-088 customization-preserve invariants, so the rename was
deferred to BD-148 (which already coordinates skill-model migration
across MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md + Procedure-5
documentation). BD-148's File/Symbol and Description fields were
expanded inline in the BD-142 commit (`58f79f0`) to record the F3
scope so it is not forgotten. Recommended new column convention
(per the architecture §3.6 Tier 0 / dimensional / intersection /
trigger nomenclature): `Base skills | Dimensional skills`, but the
exact convention is a Procedure-5 design decision that BD-148 must
make.

---

## 8. Final summary

- **Doc path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md`
- **Total batches: 14** (BD-140..BD-150 + BD-156, BD-157, BD-158).
- **Total new BDs: 19** (14 v11.0 batch BDs + 5 v12-deferred BDs).
- **Critical path: 6 batches** (BD-140 → BD-141 → BD-142 → BD-143 → BD-146 → BD-150). BD-156, BD-157, BD-158 sit off-path; all three hard-block BD-149.
- **After BD-150 ships and is Resolved:** spawn `pack-architect` for
  Phase 2A (web / Android / embedded-MCU per-skill rule design). Do
  NOT pass `isolation: "worktree"` to the spawn.

