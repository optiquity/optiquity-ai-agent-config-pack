# BOUNDARY-DEFINITION-HISTORY — relocated history for `pack-ops/BOUNDARY-DEFINITION.md`

**What this file is.** This archive holds the historical / rationale content that
was relocated out of the durable rule doc `pack-ops/BOUNDARY-DEFINITION.md` when it
was reshaped to a forward-only rule reference. The active rule (the two-axis matrix,
the four-step verdict procedure, the root-exemption rule, and the content rules)
lives in `pack-ops/BOUNDARY-DEFINITION.md`. The material below is preserved verbatim
so future readers do not re-create a resolved issue or re-litigate a decided question.

**Provenance.** Originally §4 "Why only 1 entry," §5 (SHARED anti-pattern catalog),
§6 (cross-reference network), and §7 (worked examples) of
`pack-ops/BOUNDARY-DEFINITION.md`. Source-of-design:
`maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §1.1, §1.2,
§3.3 (machine-readable format), §4, §5.2 +
`maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §4
(1-entry shrink) + `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`
Overrides 1 + 5.

---

## Root exemption — Why only 1 entry and not 3?

An earlier design (`maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §2.1 + §3.3) proposed a 3-entry exemption list including `BACKLOG.md` and `CHANGELOG.md` with a "pinned by external constraints" rationale. That design was REJECTED:

- **Override 1** (`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` §1) authorized ONLY `tracker.toml.pack-example` to STAY at root.
- **Override 5** (`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` §1) explicitly REJECTED the proposed exemption for `BACKLOG.md` + `CHANGELOG.md`. User direction: both files MUST MOVE to `pack-ops/`. The user's boundary articulation classifies them as pack operational docs (curation §5: "config pack operational docs used by the pack to do its work"), not as configs governing the pack repo. "Pinned by external constraints" was not accepted as a valid exemption rationale — no tool reads either file at a specific root location; the asserted CI Check 32 and per-entry-tree contracts pin file CONTENT (mirror-in-sync) not file LOCATION.

The shortened 1-entry list is the result. `BACKLOG.md` and `CHANGELOG.md` move to `pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md` per the directory reorganization (encoded as ABSENCE from this exemption list — they are not exempted, they are relocated).

---

## SHARED anti-pattern catalog (post-resolution)

When the boundary rules were first articulated, the audit (`maintenance-docs/archive/v11/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` §F) identified seven candidate SHARED anti-patterns — artifacts that appeared to span PACK and PROJECT audiences. User curation (`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Overrides 3 + 4) reclassified two of them OUT (they are independent parallel TOOL-CONFIG dirs, not shared). The remaining FIVE anti-patterns and their structural resolutions are catalogued here so future readers do not re-create a resolved issue.

### F-1: `supporting-docs/` audience-mixed

**Problem.** `supporting-docs/` was classified as PACK-PRODUCT (project-side — content shipped to clients), but three files in the directory were PACK × OPERATIONS by content (`CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`, `MERGE-STRATEGY.md`).

**Resolution.** Split by audience. The three PACK-audience files move OUT of `supporting-docs/`:

- `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6 — destination is `pack-ops/`, NOT `maintenance-docs/`).
- `DRY-RUN-MIGRATION.md` → `pack-ops/DRY-RUN-MIGRATION.md`.
- `MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md`.

After the three moves, `supporting-docs/` is unambiguously C4 (PROJECT × PRODUCT). The pack-memory trinity rule ("Pack ops files NEVER mixed into pack product files") becomes true by construction.

### F-2: `project-template/docs/pack/` directory NAME

**Problem.** Directory NAME `pack/` lives inside `project-template/` (project-side) but its name implies "pack-side concerns." Reviewers may misread the directory's audience and treat its contents as PACK files.

**Resolution.** **NO rename.** Per the §2 matrix the contents are C5 (PROJECT × OPERATIONS): pack-AUTHORED operations content for PROJECT use. The directory name `pack/` is accurate in the sense that the content's AUTHOR is the pack — it is the pack's voice instructing the project. The misleading-ness is resolved by the boundary doc being discoverable from every entry point rather than by rename. Rename costs (~20-50 path updates, migrator step for existing v10/v11 client repos, downstream-fork breakage) are not justified once the boundary rule is documented.

### F-4: `QUICKSTART.md` audience-mixed

**Problem.** `QUICKSTART.md` is at pack root but contains both pack-side voice ("what is this pack") and project-side voice ("here's how to set up your coding project"). Referenced from both audiences.

**Resolution.** **NO SPLIT** (per `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 7). User exception authorized: `QUICKSTART.md` is a ~47-line pre-install pack-installer doc that serves ONE audience (pack-installers); SPLIT is over-engineering. GitHub-landing-page visibility is the rationale for keeping at root. The 5 project-side references to `docs/pack/QUICKSTART.md` (in 4 files) are REMOVED entirely per Override 10 — install docs are not in-project help content. The classification stands as C1 (PACK × PRODUCT, landing-page).

### F-5: `pack-ops/OPTIONAL-FEATURES.md` installed-path mismatch

**Problem.** `pack-ops/OPTIONAL-FEATURES.md` was at pack root only, but 5 project-side files referenced path `docs/pack/OPTIONAL-FEATURES.md` as if it were installed at client repos. `scripts/init-project.sh` did not install it.

**Resolution.** **SPLIT** (per `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 8). The pack-root file moves to `pack-ops/OPTIONAL-FEATURES.md` (pack-side, C2). A NEW file is created at `project-template/docs/pack/OPTIONAL-FEATURES.md` with project-side-audience content (C5). `scripts/init-project.sh` gains an install stage. The two files are independently curated — content overlap is allowed where it serves both audiences, but each file's content is tailored to its audience. The 5 project-side references resolve to the new file.

### F-6: trinity filename collisions

**Problem.** Same filenames (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) at pack root and `project-template/`. Naming collision at the prose level; can produce cross-bias when discussions slip on the prose disambiguation.

**Resolution.** **NO RENAME — structurally required pair.** Both pairs are TOOL-CONFIG (C3 at root; C6 at `project-template/`). Each is at the location its CLI mandates (Claude Code reads `CLAUDE.md` at the consuming repo's root; Codex reads `AGENTS.md`; Gemini reads `GEMINI.md`). The collision is unavoidable. The pack-memory "Filename uniqueness heuristic" already exempts trinity files but requires prose disambiguation ("pack-root `CLAUDE.md`" vs "project-template `CLAUDE.md`"). The cross-bias risk is handled by reviewer protocol amendments and agent guardrails, not by rename.

### What was DROPPED from the catalog (Overrides 3 + 4)

Two audit-flagged SHARED entries were reclassified out of the catalog by user curation:

- **F-3** (`.github/` parallel pair at root and `project-template/`) — per Override 3, root `.github/` is PACK-ONLY (C3, CI + issue templates for the pack repo) and `project-template/.github/` is PROJECT-ONLY (C6, templates shipped to client repos). Same NAME because GitHub mandates `.github/` at repo root for ANY repo using GitHub features. Not shared in any meaningful sense; lockstep maintenance is process friction, not a structural anti-pattern.
- **F-7** (parallel CLI dotted-dirs `.claude/` / `.codex/` / `.gemini/` at root vs `project-template/`) — per Override 4, root dotted-dirs are PACK-ONLY (C3, tool configs governing the pack repo) and `project-template/` dotted-dirs are PROJECT-ONLY (C6, tool configs that ship to client repos via install). Two SEPARATE sets, SEPARATE audiences, SEPARATE content. Same names because each tool mandates its dotted dir at the consuming repo's root.

The resulting catalog is 5 entries, not 7.

---

## Cross-reference network (historical prose; superseded by the pointer manifest)

The boundary doc is the SINGLE SOURCE OF TRUTH for the boundary rules. Historically it enumerated every surface where an actor might need it; that enumeration is superseded by the machine-readable `pack-ops/.boundary-pointer-manifest.txt` and its asserting check. The historical prose is preserved here:

### Active operating docs (top-of-file pointer)

The `pack-ops/PACK-*.md` paths below reflect the location after the BD-175 Phase 5 relocation that moved these files from pack root to `pack-ops/`.

- `pack-ops/PACK-CHAT.md` — top section "Boundary rules: see `BOUNDARY-DEFINITION.md`". Pack Chat reads PACK-CHAT.md at startup; this is the most consequential pointer.
- `pack-ops/PACK-AGENTS.md` — top section pointer. Every pack agent that reads PACK-AGENTS.md gets the pointer.
- Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) — pointer in the pack-memory section ("Boundary rules: see `pack-ops/BOUNDARY-DEFINITION.md`"). All three trinity files (per trinity rule in same edit). This puts the pointer in the per-session memory load for every CLI working on the pack repo.
- `project-template/docs/pack/PM-CHAT.md` — pointer to the boundary definition from the PROJECT-side PM chat operating doc. This is critical for the V1 regression pattern (see the V1 worked example below): PM chat needs to know that pack-only files are off-limits as references in project-side artifacts. Note the project-side pointer reads "(in the pack repo)" qualifier — clients don't install `pack-ops/`.

### Design / planning surfaces (top-of-file pointer)

- `README.md` § "Repository Layout" — one-line pointer "Boundary rules between pack-only and project-only files: see `pack-ops/BOUNDARY-DEFINITION.md`."
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (after the F-1 move) — pointer in dimension (d) Pack rule adherence so conceptual reviewers cite it.
- the pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher set of agents at `.claude/agents/` (and trinity-parallel `.codex/agents/pack-*.toml`, `.gemini/agents/pack-*.md`) — "Boundary rules: read `pack-ops/BOUNDARY-DEFINITION.md` before any classification decision" line in each agent's read-list. Trinity-parallel edits required per trinity rule.

### Workflow / CI surfaces (machine-readable)

- `pack-ops/.boundary-exempt-root.txt` — the closed-set exemption list. Co-located so the boundary definition and its mechanical allow-list live next to each other.
- The prevention CI gate consumes BOTH this boundary definition (as the human-readable spec) AND the exemption list (as the machine-readable allow-list).

### The discoverability invariant

Any actor — Pack Chat, pack-* agents, pack maintainers, project PM chats, project developers, CI scripts — can reach the boundary doc by ONE of these paths: reading README, reading PACK-CHAT.md, reading PACK-AGENTS.md, reading the pack trinity, reading any pack-* agent file, reading project-side PM-CHAT.md, or hitting a CI gate failure message that names the doc. No actor has to GUESS where the rule lives.

When adding a NEW operating-doc surface to the pack, the surface SHOULD acquire a pointer to the boundary doc; the pointer network is intentionally dense so the network remains complete as the pack grows.

---

## Worked examples

The verdict procedure applied to representative files. Each example states (a) the file's path, (b) the audience identification, (c) the function identification, (d) the resulting category, (e) the placement verdict.

### C1 PACK × PRODUCT — `README.md`

- **Path.** `/README.md` (pack root).
- **Audience.** GitHub visitors evaluating the pack; the GitHub repo landing page renders this file. The audience is anyone who lands on the GitHub project URL — primarily pack-installers evaluating "should I use this pack" and existing pack maintainers reaching for the version history. The actor reads this file when the file's CONTEXT is the GitHub landing page. → **PACK.**
- **Function.** A file rendered by GitHub at a mandated location (the repo root); also the public-facing description of the pack as a deliverable. The placement constraint is external (GitHub mandates `README.md` at root). → **TOOL-CONFIG** is the dominant function (placement constraint wins) and **PRODUCT** is the secondary function. GitHub-mandated landing-page docs are catalogued as C1 because the file's primary user-visible role is "the pack as it is shipped" — TOOL-CONFIG and PRODUCT both apply, and the example list in C1 names `README.md` explicitly.
- **Category.** C1 (PACK × PRODUCT, with the GitHub-mandated location).
- **Placement.** STAYS at pack root.

### C2 PACK × OPERATIONS — `pack-ops/PACK-AGENTS.md`

- **Path.** `pack-ops/PACK-AGENTS.md`.
- **Audience.** Read by every pack-* agent that the pack spawns and by Pack Chat when triaging which agent to route work to. No client repo reads this file (it has no installer stage in `scripts/init-project.sh`). The actor consumes the file when CWD = pack repo. → **PACK.**
- **Function.** Operating doc — agent routing table for pack development work. Not a deliverable (clients don't see it). Not a CLI-mandated location (the pack chose where to put it). → **OPERATIONS.**
- **Category.** C2 (PACK × OPERATIONS).
- **Placement.** `pack-ops/PACK-AGENTS.md` per the verdict procedure step 3. NOT loose at pack root: step 4 forbids new loose C2 at root and the file is not in the root exemption list.

### C3 PACK × TOOL-CONFIG — `CLAUDE.md` (pack root)

- **Path.** `/CLAUDE.md` (pack root, NOT `project-template/CLAUDE.md`).
- **Audience.** Claude Code CLI when it starts a session WHERE CWD = pack repo. Pack agents (pack-architect / pack-coder / etc.) inherit this file as their session memory. No client repo's Claude Code session loads this file (the project-template parallel `project-template/CLAUDE.md` is what installs to clients). → **PACK.**
- **Function.** Required at a specific location by Claude Code (per the Claude Code CLI contract, `CLAUDE.md` must be at the repo root or it is not loaded). → **TOOL-CONFIG.**
- **Category.** C3 (PACK × TOOL-CONFIG).
- **Placement.** STAYS at pack root. (The path is mandated; moving it would break Claude Code memory loading entirely.)

### C4 PROJECT × PRODUCT — `project-template/skills/audit-methodology/SKILL.md`

- **Path.** `project-template/skills/audit-methodology/SKILL.md`.
- **Audience.** Client repos that have installed the pack. `scripts/init-project.sh` (or the per-CLI install stage) installs this file into the client repo at the corresponding skill location. Client developers and client-side AI agents read it when they perform audit work in the client repo. → **PROJECT.**
- **Function.** A deliverable — the pack ships this file as part of the skill set that clients receive. The client uses the skill as part of their work. → **PRODUCT.**
- **Category.** C4 (PROJECT × PRODUCT).
- **Placement.** Under `project-template/skills/` per the existing subtree layout — already correctly placed.

### C5 PROJECT × OPERATIONS — `project-template/docs/pack/PM-CHAT.md`

- **Path.** `project-template/docs/pack/PM-CHAT.md`.
- **Audience.** Client repos. The file installs to `<client>/docs/pack/PM-CHAT.md` and the client's PM chat reads it at startup. NOT consumed by Pack Chat in the pack repo (Pack Chat reads `pack-ops/PACK-CHAT.md`, the parallel pack-side doc — a deliberate separation per F-1). → **PROJECT.**
- **Function.** Operating doc — orchestrates the client's PM workflow. Not a deliverable in the "ships verbatim" sense (it is updated per project conventions over time), and not CLI-mandated (the path under `docs/pack/` is the pack's chosen convention). → **OPERATIONS.**
- **Category.** C5 (PROJECT × OPERATIONS). The category exists for exactly this case: pack-AUTHORED operations content for PROJECT use.
- **Placement.** Under `project-template/docs/pack/` per the verdict procedure step 3. Already correctly placed.

### C6 PROJECT × TOOL-CONFIG — `project-template/.claude/settings.json`

- **Path.** `project-template/.claude/settings.json`.
- **Audience.** Client repos. After `scripts/init-project.sh` installs it, Claude Code in the client repo reads `<client>/.claude/settings.json` to configure its session behavior. The pack repo's own Claude Code does NOT read this file (it reads `/.claude/settings.json` at the pack root — a separate C3 file). → **PROJECT.**
- **Function.** Required at a specific location by Claude Code (the `.claude/` dotted dir is mandated by Claude Code at the consuming repo's root, and `settings.json` is the mandated filename within it). → **TOOL-CONFIG.**
- **Category.** C6 (PROJECT × TOOL-CONFIG).
- **Placement.** Under `project-template/.claude/` so that `scripts/init-project.sh` mechanically installs it to `<client>/.claude/` — already correctly placed. The path inside `project-template/` mirrors the post-install client path, which is the convention for all C6 files.

### Anti-pattern (V1 failure mode) — project trinity acquired PACK-AGENTS.md reference

- **Historical failure.** A prior commit added a reference to `PACK-AGENTS.md` (a PACK-only file) into the PROJECT trinity (`project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`). The implementer treated the project trinity as a place to reference pack-side files because the boundary was unstated.
- **Why the verdict procedure would have caught it.** Apply step 1: who consumes `project-template/CLAUDE.md`? Client repos (via install) — PROJECT audience. Apply step 1 to `PACK-AGENTS.md`: who consumes it? Pack-* agents in the pack repo — PACK audience. Step 1's final clause forbids cross-audience references: a PROJECT-audience file (the project trinity) cannot reference a PACK-only file (`PACK-AGENTS.md`) because the PROJECT consumer (client repo) cannot reach the PACK file — `PACK-AGENTS.md` is not installed to clients. The placement procedure flags this as the SHARED anti-pattern variant: a reference that effectively asks one audience to read another audience's file.
- **Why step 4 prevents the recurrence.** Any new loose file at pack root must be C1 or C3. A new `PACK-AGENTS.md`-equivalent C2 file loose at root would also be rejected by the CI gate (the file is not in `pack-ops/.boundary-exempt-root.txt`). Combined: the boundary rule rejects the file-path attempt; the cross-reference rule rejects the prose-reference attempt; the CI gate enforces both.
- **Resolution applied to this specific failure.** The contamination was removed from the project trinity (BD-175 Phase 5, TASK-T1 trinity REPLACE). Post-fix, the project trinity contains only PROJECT × OPERATIONS pointers (e.g., `docs/pack/PM-CHAT.md`); pack-side pointers belong in pack trinity, not project trinity. This example illustrates what the verdict procedure would have flagged at the time the V1 contamination first landed.
