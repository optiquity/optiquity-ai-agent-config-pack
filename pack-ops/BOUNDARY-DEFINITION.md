# BOUNDARY-DEFINITION — pack/project boundary rules

**Status:** canonical rule reference (stable across pack versions; updated only when the boundary definition itself changes).
**Audience:** pack maintainers, pack agents (pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher), future architects, project PM chats (post-install qualifier — see §5).
**Source-of-design + history:** `maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md` (anti-pattern catalog, worked examples, override-history, and the originating design records).

---

## §1 Purpose

This document is the canonical rule for placing any file in the AI Agent Config Pack repository, and for referencing files across the pack/project boundary. Read it BEFORE classifying any new file, moving an existing one, or referencing one across the boundary.

The pack repo houses two distinct audiences whose files MUST remain separated: **PACK files** (read or executed by actors operating ON the pack repo — Pack Chat, pack-* agents, pack maintainers, pack CI) and **PROJECT files** (read or executed by actors operating IN client repos that have installed the pack — project PM chat, project agents, client developers, client CI).

The boundary is a deterministic rule expressed as a two-axis matrix (§2) and a four-step placement procedure (§3). Every artifact has exactly one valid placement.

---

## §2 The two-axis classification matrix (C1-C6)

Every file or directory in the pack repo is classified by two orthogonal questions. The classification is the answer to both.

**Axis 1 — Audience.** Who reads or runs this file?

| Audience value | Definition |
|---|---|
| **PACK** | Read or executed by actors operating ON the pack repo: Pack Chat, pack-* agents (pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher), pack maintainers, pack CI, pack-only scripts (`scripts/validate-pack.py`, `scripts/migrate-v10-to-v11.sh`, `scripts/pack-help.sh` when invoked at pack root). |
| **PROJECT** | Read or executed by actors operating IN client repos that have installed the pack: project PM chat, project agents (architect / coder / reviewer / tester / etc.), client developers, client CI. Files installed to client repos via `scripts/init-project.sh` or refreshed via `scripts/migrate-vN-to-vM.sh`. |

**Axis 2 — Function.** What role does this file play?

| Function value | Definition |
|---|---|
| **PRODUCT** | A file that is or becomes part of the deliverable the pack ships. For PROJECT audience: installed into client repos. For PACK audience: shipped as repo artifacts visible at HEAD (e.g., README on GitHub landing page). |
| **OPERATIONS** | A file used to do the work but not itself a deliverable. Operating rules, orchestration prompts, agent definitions, internal methodology, design records, planning artifacts, CI configuration, scripts that DO the work. |
| **TOOL-CONFIG** | A file mandated at a specific location by a CLI, build tool, or platform (Claude Code reads `CLAUDE.md` at root; GitHub renders `README.md` at root; Codex reads `AGENTS.md` at root; each CLI reads its dotted dir at the consuming repo's root). |

The cross-product gives **six valid combinations**:

| # | Audience × Function | Examples |
|---|---|---|
| C1 | PACK × PRODUCT | Pack repo's landing-page docs read by GitHub visitors evaluating the pack: `README.md`, `LICENSE.md`. |
| C2 | PACK × OPERATIONS | Pack-only operating docs and design records: `PACK-CHAT.md`, `PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`, `pack-ops/OPTIONAL-FEATURES.md`, `/backlog/`, `/changelog/`, `maintenance-docs/**`, `.claude/agents/pack-*.md`, `scripts/validate-pack.py`, `scripts/pack-help.sh`, etc. |
| C3 | PACK × TOOL-CONFIG | Pack-trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root), pack-side `.claude/`, `.codex/`, `.agents/`, `.agents-plugin/`, `.github/` directories at pack root, root `.gitignore`. |
| C4 | PROJECT × PRODUCT | Installed-to-client content: everything under `project-template/` that ships verbatim or templated to client repos via `scripts/init-project.sh`. |
| C5 | PROJECT × OPERATIONS | Project-side operating docs that the pack provides as installable artifacts: `project-template/docs/pack/PM-CHAT.md`, `project-template/docs/pack/PACK-FEEDBACK.md`, `project-template/docs/pack/PLATFORM-SKILLS.md`, project-side agent files in `project-template/.claude/agents/*.md` (architect / coder / reviewer / ...). These are PROJECT audience because client repos read them; they are OPERATIONS because the client uses them to do work, not as the deliverable itself. |
| C6 | PROJECT × TOOL-CONFIG | Project-side trinity (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`), project-side `.claude/` / `.codex/` / `.agents/` / `.agents-plugin/` / `.github/` directories under `project-template/`. These exist at fixed paths so the trinity → installed-trinity path is mechanical for `scripts/init-project.sh`. |

A file or directory MUST fall into exactly one of C1–C6. Files that appear to fall into more than one (the "shared" pattern) are anti-patterns and MUST be split.

The **PROJECT × OPERATIONS** category (C5) exists for one reason: the pack ships operational content TO clients (PM chat prompts, agent definitions, methodology). The audience is PROJECT (the client's PM chat reads them in the client repo); the function is OPERATIONS (they orchestrate the client's work). This category is what makes `project-template/docs/pack/` non-anomalous — it's not "pack content in a project place"; it's "pack-AUTHORED operations content shipped for PROJECT use."

### §2.2 Companion-template surfaces — governed by project-side content rules

The companion-template trees (`xcode-companion-templates/`, `vscode-companion-templates/`) hold project-related developer/IDE configs a developer applies to their machine or editor workspace — they are NOT pack internals. They are **governed by the SAME content rules as any project-side asset**: their contents MUST NOT reference pack internals (pack-only docs, `pack-ops/` paths, pack-* agents, the `Pack Chat` role, BDs operationally). Bans A/B (§5) apply to these trees exactly as they apply to `project-template/`. There is no new matrix category, no rename, and no new audience: the Check 37 deny-list walk (`_iter_client_installed_files()`) is extended to cover both companion-template dirs as forward protection.

### §2.3 Purpose classifies; location is convention

**Governing principle: PURPOSE classifies; LOCATION is convention.** An operations directory is correctly placed wherever it sits — `scripts/`, `maintenance-docs/`, `test-fixtures/` are PACK × OPERATIONS by PURPOSE, and root-vs-`pack-ops/` is irrelevant to their correctness. The only placement teeth that remain: **no NEW loose file is dumped at pack root** — a new loose file goes to its purpose-directory (a new pack-only prose doc → `pack-ops/`; a new script → `scripts/`; etc.), enforced by Check 38 + `pack-ops/.boundary-exempt-root.txt`.

---

## §3 The placement verdict procedure

Given any artifact, classify it and place it as follows:

1. **Identify Audience.** Who runs/reads this file when it's doing its job? If the answer is "the pack's tooling, agents, or maintainers" → PACK. If "a client repo's tooling, agents, or developers (after install)" → PROJECT. If "both" → **STOP**: the artifact is a SHARED anti-pattern and MUST be split.

2. **Identify Function.** Is the file a deliverable visible on the GitHub landing page or installed verbatim (PRODUCT), an internal operating doc / script / methodology (OPERATIONS), or required at a fixed location by a CLI/platform (TOOL-CONFIG)?

3. **Apply the placement rule from the matrix:**
   - C1 PACK × PRODUCT → pack root (only valid PACK landing-page surface).
   - C2 PACK × OPERATIONS → its purpose-directory (`pack-ops/` for prose ops docs; `scripts/` for scripts; `maintenance-docs/` for design records). Per §2.3, purpose classifies and location is convention.
   - C3 PACK × TOOL-CONFIG → pack root or its mandated dotted dir.
   - C4 PROJECT × PRODUCT → under `project-template/` per the existing subtree layout.
   - C5 PROJECT × OPERATIONS → under `project-template/docs/pack/` (kept; the directory NAME is accurate — pack-AUTHORED content).
   - C6 PROJECT × TOOL-CONFIG → `project-template/` root or its mandated dotted dir.

4. **If the verdict places a NEW loose file at pack root**, the file MUST be either C1 or C3. Any PACK × OPERATIONS file appearing loose at root is a regression and is rejected by a CI gate (the prevention CI gate consumes the closed-set exemption list — see §4).

**The criterion that resolves all real ambiguity:** the audience is the actor that consumes the file IN THE CONTEXT WHERE THE FILE LIVES. A pack-internal agent prompt at `.claude/agents/pack-architect.md` is consumed by Claude Code WHEN THE CWD IS THE PACK REPO. Audience = PACK, unambiguously. Conversely, `project-template/.claude/agents/architect.md` is consumed by Claude Code when its CWD is the CLIENT repo (after `scripts/init-project.sh` installs it). Audience = PROJECT, unambiguously. The criterion "WHEN THE CWD IS X" resolves all real cases.

**HOW + WHEN addendum.** Placement (WHERE) is only one column; each rule also has a HOW (how it is applied) and a WHEN (its trigger/timing):

| Rule | WHERE (placement) | HOW (applied) | WHEN (trigger/timing) |
|---|---|---|---|
| Audience×function verdict | per C1–C6 | run §3 four-step procedure on the artifact | at file CREATE or MOVE, before commit; CI Check 38 at PR-time (loose root files) |
| One-directional ban (§5) | n/a (content) | Check 37 deny-list grep | at every commit touching `project-template/` (CI) |
| Separated-not-combined (§5) | n/a (content) | opt-in labeled-block convention + EXISTING Check 37 (no new detection check) | enforced continuously by Check 37 (CI); convention applied at authoring |
| Cross-ref-network (§6) | machine-readable | check asserts pointer set | at commit touching a doc in the pointer set (CI) |
| Concision gate (M4) | durable rule-doc class | pattern scan + per-doc advisory length | at commit touching a named durable rule doc (CI) |
| Rule↔rationale lock-step | `pack-ops/PACK-MEMORY-RATIONALE.md` | 1:1 slug bijection check | at commit touching CLAUDE.md pack-memory or the rationale file (CI) |

The principle: **every boundary/content/concision rule is a CI check with a stated trigger**, so "when" is mechanical, not memory.

---

## §4 Closed-set root exemption list

The pack repo permits exactly ONE PACK × OPERATIONS file at root despite §3 step 4. The exempted set is fixed by external constraints and codified in machine-readable form at:

```
pack-ops/.boundary-exempt-root.txt
```

**Current contents (1 entry):**

| # | Filename | Reason exempt |
|---|---|---|
| 1 | `tracker.toml.pack-example` | User-approved root exemption. |

**Adding to this list requires explicit user approval.** Adding an entry is a rule change, not a routine BD. The prevention CI gate consumes this file as its allow-list — any new C2 file appearing loose at root that is not in the list fails the gate. (The history of why the list is 1 entry rather than 3 lives in `maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md`.)

**Why the leading `.`?** Default `ls` listings hide files starting with `.` (consistent with `.gitignore`, `.DS_Store`). The file IS checked into git (no `.gitignore` entry is needed); the leading dot is presentation, not visibility from git.

---

## §5 Content rules (cross-boundary references)

Placement (§2–§3) governs WHERE a file lives. These content rules govern what a file's CONTENT may REFERENCE across the boundary. Each is a named rule with its enforcing check:

- **Ban A** — nothing under `project-template/` (and the rest of the client-installed set, including the companion-template trees per §2.2) may reference pack-side docs/paths/agent-names or the `Pack Chat` role. Enforced by Check 37 (`check_project_side_deny_list`).
- **Ban B** — client-facing surfaces never treat BDs operationally (no BD dependency grammars / form admissions / parser regexes on client surfaces; explanatory mention with pack-only disclosure is allowed). Enforced by the BD-pack-only check family.
- **Ban C (reverse direction)** — pack-self-management surfaces never use project-side concepts (TD / phase / phase-part / phase-task) operationally (the construct-a-deliverable exception stands). Enforced at review-time by the enumerate-ENCODING-surfaces audit methodology.
- **Separated-not-combined** — a client-installed doc MAY legitimately reference BOTH the pack-side and the project-side version of a concept; when it does, the two MUST be kept SEPARATED (clearly distinguished), never conflated into one claim that erases the boundary. Enforced by the already-shipping Check 37 (a conflation — a pack-side token used as a live project instruction, outside an anchor/fence — is a Check-37 failure); an opt-in `<!-- PACK-SIDE -->` / `<!-- PROJECT-SIDE -->` labeled-block convention is available as authoring guidance (not a mandate, not a separate check).

---

## §6 Pointer network

This doc is the SINGLE SOURCE OF TRUTH for the boundary rules and is referenced from every operating-doc entry point in the pack. The pointer network is CI-asserted via the surface→pointer manifest at `pack-ops/.boundary-pointer-manifest.txt`; the manifest file and its asserting validator check both exist and enforce the surface→pointer mapping.

---

**End of BOUNDARY-DEFINITION.md.** When this doc changes, update the pointer manifest (§6) in the same commit so readers reaching from any entry point see consistent rules.
