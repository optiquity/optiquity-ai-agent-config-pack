# ARCHITECTURE — Directory reorganization + boundary definition (BD-175 Phase 2 Architect B)

**Owner:** Architect B (read-only on source; output is this single doc)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 2 — multi-architect design (B = directory architecture + boundary definition)
**Date:** 2026-05-18
**Branch:** v11-dev
**HEAD at design time:** `8014186` (per gitStatus)

---

## Reader's note — scope and non-scope

This design covers four orchestration-plan goals:

1. **G7 — Boundary definition** (unimpeachable + unambiguous rules for pack-only vs project-only files).
2. **SC8 — Boundary definition discoverability** (where the rules live so every actor can find them).
3. **G2 (directory portion)** — directory architecture that eliminates the SHARED anti-pattern, including new homes for files audit §A flagged as MOVES.
4. **Path-reference update strategy** — concrete enough for Phase 5 coder execution.

This design **does NOT cover**:

- Re-litigation of the 13 audit boundary violations (Architect A's domain).
- Prevention mechanisms — CI checks, agent guardrails, P-missed-7 codification, reviewer-protocol amendments (Architect C's domain).

Where a finding implicates both directory architecture (B) and prevention (C), this doc names the architectural fact and the path constraint; Architect C designs the gate/guardrail.

Architect A's per-finding revert/replace/justify decisions will land independently in `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`. **This design assumes Architect A's decisions DO NOT change which directories exist or what the boundary rules are** — those are B's domain. If Architect A surfaces a directory-level need (e.g., "supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md must move to a pack-internal directory before re-litigation can proceed"), this doc provides that directory.

---

## §1 — The G7 boundary definition

### §1.1 The two-axis classification

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
| C2 | PACK × OPERATIONS | Pack-only operating docs and design records: `PACK-CHAT.md`, `PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`, `BACKLOG.md`, `CHANGELOG.md`, `maintenance-docs/**`, `.claude/agents/pack-*.md`, `scripts/validate-pack.py`, `scripts/pack-help.sh`, etc. |
| C3 | PACK × TOOL-CONFIG | Pack-trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root), pack-side `.claude/`, `.codex/`, `.gemini/`, `.github/` directories at pack root, root `.gitignore`. |
| C4 | PROJECT × PRODUCT | Installed-to-client content: everything under `project-template/` that ships verbatim or templated to client repos via `init-project.sh`. |
| C5 | PROJECT × OPERATIONS | Project-side operating docs that the pack provides as installable artifacts: `project-template/docs/pack/PM-CHAT.md`, `project-template/docs/pack/PACK-FEEDBACK.md`, `project-template/docs/pack/PLATFORM-SKILLS.md`, project-side agent files in `project-template/.claude/agents/*.md` (architect / coder / reviewer / ...). These are PROJECT audience because client repos read them; they are OPERATIONS because the client uses them to do work, not as the deliverable itself. |
| C6 | PROJECT × TOOL-CONFIG | Project-side trinity (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`), project-side `.claude/` / `.codex/` / `.gemini/` / `.github/` directories under `project-template/`. These exist at fixed paths so the trinity → installed-trinity path is mechanical for `init-project.sh`. |

A file or directory MUST fall into exactly one of C1–C6. Files that appear to fall into more than one (the "shared" pattern) are anti-patterns and MUST be split (§4 catalogs the current SHARED entries and their splits).

The **PROJECT × OPERATIONS** category (C5) exists for one reason: the pack ships operational content TO clients (PM chat prompts, agent definitions, methodology). The audience is PROJECT (the client's PM chat reads them in the client repo); the function is OPERATIONS (they orchestrate the client's work). This category is what makes `project-template/docs/pack/` non-anomalous — it's not "pack content in a project place"; it's "pack-AUTHORED operations content shipped for PROJECT use."

### §1.2 The placement verdict procedure

Given any artifact, classify it and place it as follows:

1. **Identify Audience.** Who runs/reads this file when it's doing its job? If the answer is "the pack's tooling, agents, or maintainers" → PACK. If "a client repo's tooling, agents, or developers (after install)" → PROJECT. If "both" → **STOP**: the artifact is a SHARED anti-pattern (§4).

2. **Identify Function.** Is the file a deliverable visible on the GitHub landing page or installed verbatim (PRODUCT), an internal operating doc / script / methodology (OPERATIONS), or required at a fixed location by a CLI/platform (TOOL-CONFIG)?

3. **Apply the placement rule from the matrix** (§3 below):
   - C1 PACK × PRODUCT → pack root (only valid PACK landing-page surface).
   - C2 PACK × OPERATIONS → `pack-ops/` (new top-level pack-only dir; see §3.1).
   - C3 PACK × TOOL-CONFIG → pack root or its mandated dotted dir.
   - C4 PROJECT × PRODUCT → under `project-template/` per the existing subtree layout.
   - C5 PROJECT × OPERATIONS → under `project-template/docs/pack/` (kept; §F-2 addressed via §4.2).
   - C6 PROJECT × TOOL-CONFIG → `project-template/` root or its mandated dotted dir.

4. **If the verdict places a NEW file at pack root**, the file MUST be either C1 or C3. Any PACK × OPERATIONS file at root is a regression and SHOULD be rejected by a CI gate (Architect C designs the gate).

### §1.3 Why this is unimpeachable

A skeptical reviewer might challenge each part of the definition. Below, each challenge is anticipated and answered.

**Challenge 1 — "Audience is fuzzy. How do you decide who 'the audience' is when multiple actors touch a file?"**

The audience is the actor that consumes the file IN THE CONTEXT WHERE THE FILE LIVES. A pack-internal agent prompt at `.claude/agents/pack-architect.md` is consumed by Claude Code WHEN THE CWD IS THE PACK REPO. The same `pack-architect` would not be invoked from a client repo — there's no `pack-architect` agent in `project-template/.claude/agents/`. So audience = PACK, unambiguously. Conversely, `project-template/.claude/agents/architect.md` is consumed by Claude Code when its CWD is the CLIENT repo (after `init-project.sh` installs it). Audience = PROJECT, unambiguously. The criterion "WHEN THE CWD IS X" resolves all real cases.

**Challenge 2 — "What about `MERGE-STRATEGY.md` — pack tooling reads it, but client developers may also read it?"**

The criterion in Challenge 1 forces the answer: in WHAT CONTEXT is the file consumed? `scripts/migrate-v10-to-v11.sh` consumes it AT THE PACK REPO (or a transient `/tmp` migrator workspace owning the pack repo). Client developers reading it post-migration are reading documentation ABOUT the pack's migration tooling — they read it AT THE PACK REPO (on GitHub) or via a link, not from a file installed into their client repo. Audience = PACK. The audit §F-1 ambiguity is genuine ("MERGE-STRATEGY.md audience-mixed") but only because the file currently has dual personality. Per this rule it is PACK × OPERATIONS, regardless of which secondary audiences happen to read it.

**Challenge 3 — "PROJECT × OPERATIONS is a strange category — isn't it really PACK content?"**

No. The CONTENT is authored by the pack (so the pack has authorial control), but the CONSUMER is the client. The file's audience determines audience-classification, not authorship. Compare to OS vendors: an OS vendor ships system manuals; the manuals are AUTHORED by the vendor but the AUDIENCE is the OS user, so the manuals belong on the OS user's machine, not on the vendor's build server. `project-template/docs/pack/PM-CHAT.md` is exactly this: pack-authored, but the project PM chat reads it AT THE CLIENT REPO, which is the audience. Mis-classifying C5 as PACK was the root mistake that produced V1 (the `PACK-AGENTS.md` reference inserted into project-template trinity — the implementer treated the project trinity as a place to reference pack-side files because the boundary was unstated).

**Challenge 4 — "TOOL-CONFIG is just a special case of OPERATIONS — why a separate function?"**

TOOL-CONFIG has a placement constraint that OPERATIONS doesn't: the location is mandated by an external tool, not chosen by the pack. `CLAUDE.md` MUST be at the repo root or Claude Code won't read it. `README.md` MUST be at the repo root or GitHub won't render it as the landing page. PACK × OPERATIONS files have no such constraint (the pack can put `PACK-AGENTS.md` wherever the pack pleases). Without the distinction, you can't reason about which root files are exempt from relocation. With it, the question becomes mechanical: "Does an external tool require this file at root? Then it's TOOL-CONFIG and STAYS. Otherwise it's not." See §2 for the full pack-root inventory under this rule.

**Challenge 5 — "What about the parallel `.github/` / `.claude/` / `.codex/` / `.gemini/` directories at root vs under project-template?"**

Per user curation Override 2 and Override 4, these are NOT shared. Each is a TOOL-CONFIG dir at the root of ITS consuming repo. Root `.claude/` is C3 (PACK × TOOL-CONFIG) — Claude Code reads it when CWD = pack repo. `project-template/.claude/` is C6 (PROJECT × TOOL-CONFIG) — Claude Code reads it when CWD = client repo (after install moves it to client's root). Two SEPARATE directories with SEPARATE content; same name because the tool mandates the name. No sharing problem.

**Challenge 6 — "How do you handle files that are valid for the pack repo AND get copied to the client (e.g., HELP-FRAGMENT-TRACKER.md is byte-identical at pack root and `project-template/docs/pack/`)?"**

Two distinct files at two distinct paths, kept byte-identical by a CI check (Check 24). Each file is classified independently per its audience+function at its own path:
- Pack-root copy → C2 (PACK × OPERATIONS): consumed by pack's `pack-help.sh` at pack root.
- `project-template/docs/pack/` copy → C5 (PROJECT × OPERATIONS): installed at client and consumed by client's `pack-help` skill.

The byte-identity is an implementation contract enforced by CI, not a sharing relationship. Both copies are pack-AUTHORED at the pack-root source; the project-side copy is shipped via `init-project.sh`. No two files share a path; nothing is in a SHARED anti-pattern.

### §1.4 Why this is unambiguous

Every conceivable artifact has a deterministic verdict:

- New file written by a pack-coder for a new BD? Apply §1.2 step 1: who consumes it? Pack agents → C2 or C3. Client agents → C5 or C6. GitHub visitors → C1. New maintenance design doc? → C2 (PACK × OPERATIONS). New project-side skill? → C4 (PROJECT × PRODUCT) under `project-template/skills/`. New project-side agent? → C5 (PROJECT × OPERATIONS) under `project-template/.claude/agents/` etc.

- New script? Apply §1.2 step 1: does it run AT the pack repo (e.g., `scripts/validate-pack.py`) or AT the client repo (e.g., `project-template/scripts/test-python.sh`)? Both options lead to a single category. If a script's purpose is "do something on a pack-managed CLIENT repo from the pack maintainer's machine" (e.g., `scripts/migrate-v10-to-v11.sh`), the CONSUMER is the pack maintainer; the SCRIPT operates ON a client repo but executes IN the pack repo's tooling context → C2 (PACK × OPERATIONS).

- New documentation? Apply §1.2 step 1: does a client repo's PM chat or developer need to read it (after install)? → C5 (and ship it under `project-template/docs/pack/`). Does only a pack maintainer or pack agent need it? → C2 (and place it under `pack-ops/` per §3.1).

- New tool? If the tool is a CLI/platform that mandates a file at a specific location, the file is TOOL-CONFIG and goes at the mandated path. If the file's location is chosen by the pack, it is OPERATIONS or PRODUCT and the matrix determines placement.

There is no case where the matrix returns two valid placements. If a designer believes a file belongs in two categories, the designer has mis-identified the audience or function (most commonly: mis-identifying PROJECT × OPERATIONS as PACK × OPERATIONS, which is the V1 / V3 / V4 contamination pattern in the audit).

### §1.5 The relationship to the user-stated boundary articulation

User stated (AUDIT-USER-CURATION.md §5):

> Files in `project-template/` are for projects and will be in the project dirs. Not necessarily root dirs. They are the product of the config pack. They are not (a) configs used by tools governing the config pack to do its work or (b) config pack operational docs used by the pack to do its work.

This design preserves the user's intent verbatim:

- "Files in `project-template/` are for projects" ↔ C4 (PROJECT × PRODUCT) and C5 (PROJECT × OPERATIONS) and C6 (PROJECT × TOOL-CONFIG) — every file in `project-template/` is one of these three PROJECT-audience categories. No exceptions.
- "They are not configs used by tools governing the config pack to do its work" ↔ those are C3 (PACK × TOOL-CONFIG) and they live at pack root, not under `project-template/`.
- "They are not config pack operational docs used by the pack to do its work" ↔ those are C2 (PACK × OPERATIONS) and they live under `pack-ops/` (new) or pre-existing pack-only top-level dirs (`maintenance-docs/`, `scripts/`, `test-fixtures/`).

The design **refines** the user's articulation by surfacing TWO things the user's wording leaves implicit:

- The user's wording binds "are for projects" to "will be in the project dirs", suggesting a directory-membership test. The refinement separates audience (who consumes) from directory (where the file lives), which lets us classify files BEFORE deciding where to put them. The user's directory-membership test is a CONSEQUENCE of audience classification, not the cause: a project-audience file ENDS UP in `project-template/` because that's the project-audience subtree.
- The user lists two NEGATIVE categories of pack-related ("not configs used by tools governing the pack" + "not config pack operational docs"). The design splits this into C3 (TOOL-CONFIG) and C2 (OPERATIONS) explicitly, which matters because TOOL-CONFIG has a placement constraint (root or mandated dir) while OPERATIONS does not. Without the split, a future maintainer could place a PACK × OPERATIONS file at root because "PACK-AGENTS.md was at root, so this is fine" — exactly the regression pattern audit §A.12 documents.

The refinement preserves user intent and surfaces no edge cases that conflict with it.

---

## §2 — Root-directory inventory under the new rules

Apply the verdict procedure to every current root entry (audit §A) plus user curation.

| # | Filename / dir | Category | Verdict | Reason |
|---|---|---|---|---|
| 1 | `.DS_Store` | — | STAYS-IGNORED | macOS artifact; not tracked. No category needed. |
| 2 | `.gitignore` | C3 | STAYS | Git mandates location at repo root. |
| 3 | `AGENTS.md` | C3 | STAYS | Codex CLI mandates location at repo root. |
| 4 | `BACKLOG.md` | C2 | STAYS (exempt) | PACK × OPERATIONS, but CI Check 32 (`mirror-in-sync`) + per-entry-tree contract pin location at repo root. **EXEMPT** from the §1.2 step 4 "no new C2 at root" rule. See §2.1 below. |
| 5 | `CHANGELOG.md` | C2 | STAYS (exempt) | Same exemption pattern as BACKLOG.md. |
| 6 | `CLAUDE.md` | C3 | STAYS | Claude Code mandates location at repo root. |
| 7 | `GEMINI.md` | C3 | STAYS | Gemini CLI mandates location at repo root. |
| 8 | `HELP-FRAGMENT-PACK.md` | C2 | **MOVES** → `pack-ops/HELP-FRAGMENT-PACK.md` | No CLI/platform requirement at root. `scripts/pack-help.sh` resolves `$root/HELP-FRAGMENT-PACK.md` parametrically; update the script. |
| 9 | `HELP-FRAGMENT-TRACKER.md` | C2 | **MOVES** → `pack-ops/HELP-FRAGMENT-TRACKER.md` | Same logic as #8. CI Check 24 byte-identity contract updates to compare `pack-ops/HELP-FRAGMENT-TRACKER.md` vs `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. |
| 10 | `LICENSE.md` | C1 | STAYS | GitHub landing-page surface for license; mandated. |
| 11 | `OPTIONAL-FEATURES.md` | C2 | **MOVES** → `pack-ops/OPTIONAL-FEATURES.md` | No CLI/platform requirement. **Important:** audit §D-8 / §E-4 show that 5 project-side files reference `docs/pack/OPTIONAL-FEATURES.md` as if it were installed at client repos, but `init-project.sh` does not install it. This is a contamination cluster (broken pointers) — Architect A re-litigates whether each project-side reference is wrong (drop the reference) or whether OPTIONAL-FEATURES.md should be split into a PACK × OPERATIONS file at `pack-ops/` AND a separate PROJECT × OPERATIONS file at `project-template/docs/pack/OPTIONAL-FEATURES.md` (which `init-project.sh` would install). This design assumes the SPLIT outcome by default (the more conservative path — preserves the existing project-side cross-references' intent without making them stale-by-pack-relocation). If Architect A determines the project-side refs are wrong and should be dropped, the split is unnecessary and `pack-ops/OPTIONAL-FEATURES.md` alone suffices. See §6 for the split implementation pattern. |
| 12 | `PACK-AGENTS.md` | C2 | **MOVES** → `pack-ops/PACK-AGENTS.md` | No CLI/platform requirement at root. Self-described pack-only (see PACK-AGENTS.md:1 "Platform-agnostic agent routing for work on the pack repo itself"). |
| 13 | `PACK-CHAT.md` | C2 | **MOVES** → `pack-ops/PACK-CHAT.md` | Self-described "specific to the pack repo and not a template" (PACK-CHAT.md:5). **Critical secondary effect:** `scripts/lib/tracker-config.sh:298` uses `[[ -f "$repo_root/PACK-CHAT.md" ]]` as the pack-vs-client auto-detection signal. Moving PACK-CHAT.md breaks this detection. See §3.2 for the auto-detection migration. |
| 14 | `QUICKSTART.md` | **SHARED** | **SPLIT** into C1 (stays at root) + C5 (`project-template/docs/pack/QUICKSTART.md`) | Audit §F-4 confirms audience-mixed. The PACK-audience portion (landing-page Quick Start: "what is this pack and how do I install it") stays at root as C1 (GitHub landing-page discoverability). The PROJECT-audience portion (post-install developer Quick Start for working on the client project) ships as C5 under `project-template/docs/pack/`. See §4.4 for split details. |
| 15 | `README.md` | C1 | STAYS | GitHub landing-page mandate. |
| 16 | `tracker.toml.pack-example` | C2 | **STAYS** (user override 1) | Per AUDIT-USER-CURATION.md §1 Override 1, user direction: EXEMPT from relocation. Sufficient authority. Adds to the C2-at-root exemption list (§2.1). |
| 17 | `.claude/` | C3 | STAYS | Claude Code mandates dotted dir at repo root. |
| 18 | `.codex/` | C3 | STAYS | Codex CLI mandates. |
| 19 | `.gemini/` | C3 | STAYS | Gemini CLI mandates. |
| 20 | `.github/` | C3 | STAYS | GitHub mandates `.github/` at repo root (per user override 2). |

### §2.1 The C2-at-root exemption list (closed set)

Per §1.2 step 4, PACK × OPERATIONS at root is a regression. The exempted set is fixed by external constraints:

- `BACKLOG.md` — pinned by CI Check 32 (`mirror-in-sync`) and `/backlog/_rules.md` write-authority contract. Moving requires invalidating those contracts.
- `CHANGELOG.md` — pinned identically.
- `tracker.toml.pack-example` — pinned by user override (AUDIT-USER-CURATION.md §1 Override 1).

No other file qualifies. Any NEW C2 file added at root after this design ships is a regression. Architect C designs the CI gate that enforces this. The closed-set list is the gate's allow-list.

The exemption list lives in §3.3 in machine-readable form (so Architect C's gate can consume it).

### §2.2 Final root inventory after MOVES

After relocations land:

**Pack-root files (15 entries):**
- C1: `LICENSE.md`, `README.md`, `QUICKSTART.md` (pack-side half).
- C2 (closed-set exempt): `BACKLOG.md`, `CHANGELOG.md`, `tracker.toml.pack-example`.
- C3 (TOOL-CONFIG): `.gitignore`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.claude/`, `.codex/`, `.gemini/`, `.github/`.
- Ignored: `.DS_Store`.

**Removed from root (6 entries, relocated):**
- `HELP-FRAGMENT-PACK.md` → `pack-ops/`
- `HELP-FRAGMENT-TRACKER.md` → `pack-ops/`
- `OPTIONAL-FEATURES.md` → `pack-ops/` (+ split copy in `project-template/docs/pack/` if Architect A confirms the project-side refs are intended)
- `PACK-AGENTS.md` → `pack-ops/`
- `PACK-CHAT.md` → `pack-ops/`
- (Plus `QUICKSTART.md` SPLIT: pack-side half stays; project-side half new under `project-template/docs/pack/`.)

Root reads cleanly: trinity + license + README + version mirrors + tracker example + four TOOL-CONFIG dotted dirs + landing-page Quick Start. Every other entry is either C1 (GitHub-mandated) or C3 (CLI-mandated). No PACK × OPERATIONS file remains at root except the closed-set exemption list.

---

## §3 — Directory architecture

### §3.1 The new top-level directory: `pack-ops/`

**Path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/pack-ops/`

**Category:** C2 (PACK × OPERATIONS) — top-level, pack-only.

**Purpose:** Home for PACK × OPERATIONS files that have no CLI/platform location constraint. Holds the §A MOVES files (HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, PACK-AGENTS, PACK-CHAT) plus the boundary-definition discoverability artifact (§5).

**Why a new top-level dir and not an existing one (e.g., `maintenance-docs/`)?**

Three existing pack-only top-level dirs already exist (`maintenance-docs/`, `scripts/`, `test-fixtures/`); the question is whether the MOVES files fit any of them.

- `maintenance-docs/` is for design/research/implementation RECORDS — historical artifacts of pack development work (ARCHITECTURE-*.md, IMPLEMENTATION-REPORT-*.md, PACK-REVIEW-*.md, etc.). The MOVES files (`PACK-CHAT.md`, `PACK-AGENTS.md`, `HELP-FRAGMENT-*.md`, `OPTIONAL-FEATURES.md`) are LIVE OPERATING DOCS read every session, not historical records. Putting them in `maintenance-docs/` conflates two distinct purposes (live ops vs. design record) and obscures Pack Chat's startup-read list. Pattern B archive sweep at version close (per CLAUDE.md "Skill and agent maintenance is mechanical by default") would also wrongly include live ops docs if they live in `maintenance-docs/`.
- `scripts/` is for executables. MOVES files are docs, not scripts.
- `test-fixtures/` is for test inputs. Not applicable.

Hence a new top-level dir. The name `pack-ops/` is chosen for these reasons:

- **Self-documenting.** "pack ops" matches the existing pack memory term ("pack ops files NEVER mixed into pack product files") so readers familiar with the trinity rule immediately recognize the category.
- **No collision risk.** `find . -name "pack-ops*" -not -path "./.git/*"` returns nothing on current HEAD.
- **Hyphenated lowercase.** Matches existing top-level dirs (`project-template`, `supporting-docs`, `vscode-companion-templates`, `xcode-companion-templates`, `test-fixtures`, `maintenance-docs`) — no conflict with style.
- **Short.** Five characters + hyphen + three. Shorter than `pack-operations`, longer than `ops` (which is ambiguous outside pack-context).

**Contents after MOVES:**

```
pack-ops/
├── BOUNDARY-DEFINITION.md         (new — §5; canonical G7 reference)
├── HELP-FRAGMENT-PACK.md          (moved from root)
├── HELP-FRAGMENT-TRACKER.md       (moved from root)
├── OPTIONAL-FEATURES.md           (moved from root; split copy may also exist at project-template/docs/pack/OPTIONAL-FEATURES.md per §6)
├── PACK-AGENTS.md                 (moved from root)
└── PACK-CHAT.md                   (moved from root)
```

The directory does NOT contain:
- `maintenance-docs/` content (that's design records, distinct purpose).
- `scripts/` content (those are executables).
- `BACKLOG.md` / `CHANGELOG.md` (those are exempted at root per §2.1).
- `tracker.toml.pack-example` (exempted at root per user override).

The directory is a flat namespace at v11.0 ship time. If future PACK × OPERATIONS docs accumulate to a degree that grouping is useful (e.g., 20+ files), a subdir convention can be introduced in a later major version. At v11.0, six files (five MOVES + one new boundary-definition doc) is tractable without grouping.

### §3.2 The `tracker-config.sh` auto-detection migration

`scripts/lib/tracker-config.sh:298` uses `[[ -f "$repo_root/PACK-CHAT.md" ]]` as the pack-vs-client surface auto-detection signal:

```bash
if [[ -f "$repo_root/PACK-CHAT.md" ]]; then
    echo "pack-surface: pack"
elif [[ -d "$repo_root/docs/pack" ]]; then
    echo "pack-surface: client"
else
    tracker_error_emit "discovery" "cannot auto-detect surface in $repo_root; pass --surface pack|client"
fi
```

After `PACK-CHAT.md` moves to `pack-ops/PACK-CHAT.md`, the detection signal must update. The replacement:

```bash
if [[ -d "$repo_root/pack-ops" ]]; then
    echo "pack-surface: pack"
elif [[ -d "$repo_root/docs/pack" ]]; then
    echo "pack-surface: client"
else
    tracker_error_emit "discovery" "cannot auto-detect surface in $repo_root; pass --surface pack|client"
fi
```

**Rationale for using `-d pack-ops` as the new signal:**

- `pack-ops/` exists only in the pack repo (it is C2; client repos do not install pack-ops/).
- The detection is structural (directory existence), not a content-match — robust to file relocations within `pack-ops/`.
- The symmetric client check (`-d docs/pack`) already uses the dir-existence pattern, so the migration is parallel.

**Alternative considered and rejected:** detect on `pack-ops/PACK-CHAT.md` file existence. Rejected because if a future BD relocates `PACK-CHAT.md` within `pack-ops/`, the detection breaks. Directory existence is more durable.

`pack-help.sh` uses a separate auto-detection function (`detect_pack_surface` from `scripts/lib/detect.sh`) which inspects `BACKLOG.md` for entry-shape patterns. That function is unaffected by file moves. (Verified: `scripts/pack-help.sh:25-26, 58-60`.)

### §3.3 The C2-at-root exemption list (machine-readable)

For Architect C's CI gate (Phase 5 implementation):

```
# pack-ops/.boundary-exempt-root.txt — machine-readable closed-set
# Format: one filename per line; lines starting with # are comments.
# Files in this list are C2 (PACK × OPERATIONS) allowed at pack root.
# Adding to this list requires explicit user approval (treat as a rule change,
# not a routine BD).
BACKLOG.md
CHANGELOG.md
tracker.toml.pack-example
```

The file lives at `pack-ops/.boundary-exempt-root.txt` so the exemption list is colocated with the boundary definition. Architect C's gate reads this file as the allow-list when checking "no new C2 docs at root."

The leading `.` makes the file ignored by default `ls` listings (consistent with `.gitignore`, `.DS_Store`). It is checked in (no `.gitignore` entry needed).

### §3.4 The C2 subset that does NOT move: existing pack-only top-level dirs

The MOVES list is limited to ROOT-level files. PACK × OPERATIONS files that already live in pack-only top-level dirs (`maintenance-docs/**`, `scripts/**`, `test-fixtures/**`, `.claude/**`, `.codex/**`, `.gemini/**`, `.github/**`) STAY where they are. No PACK × OPERATIONS file in a non-root pack-only dir is in violation of §1.2 step 4 (which only addresses root placement).

Architect C may design a related but distinct CI gate ("no PACK × OPERATIONS file under `project-template/`" — i.e., the regression-detection gate for the V1/V4 pattern). That gate is in Architect C's domain; this design states only the architectural fact: NO PACK × OPERATIONS file should ever live under `project-template/`.

---

## §4 — SHARED anti-pattern resolutions

The audit §F catalogs 7 entries. User curation Overrides 2 and 4 reclassify F-3 and F-7 OUT (parallel TOOL-CONFIG, not shared). Remaining: F-1 (`supporting-docs/`), F-2 (`project-template/docs/pack/` directory NAME), F-4 (`QUICKSTART.md`), F-5 (`OPTIONAL-FEATURES.md` installed-path mismatch), F-6 (trinity collisions).

### §4.1 F-1 resolution: `supporting-docs/` split by audience

**Problem (audit §B.B37 + §F.F-1):** `supporting-docs/` is classified by pack memory as PACK-PRODUCT (project-side — content shipped to client projects on install). But three files in this directory are PACK × OPERATIONS by content:

- `CONCEPTUAL-REVIEW-METHODOLOGY.md` — pack-internal review methodology (references Pack Chat, pack-architect, pack-reviewer, pack memory MEMORY.md). Audience: PACK.
- `DRY-RUN-MIGRATION.md` — pack-repo tooling for org maintainers ("Audience: any org maintaining a v10 (or future-vN) pack-managed client"). Audience: PACK.
- `MERGE-STRATEGY.md` — audience-mixed; consumed by `scripts/migrate-v10-to-v11.sh` (pack tooling) and referenced from project-side install docs. Per §1.3 Challenge 2, primary consumer is PACK tooling → audience PACK.

Plus `MIGRATION-v10-to-v11.md` has 4 contamination hits in audit §D (Pack Chat terminology + 3 maintenance-docs refs), suggesting it too leans PACK in places — but the file's audience is PROJECT-side (client developers migrating their pack-managed repo from v10 to v11). The contamination is in CONTENT (some lines mis-target audience) not in audience; Architect A re-litigates the content.

**Resolution:**

1. Reclassify the three PACK files OUT of `supporting-docs/`:
   - `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`. The file is methodology that informs pack-reviewer / pack-architect (PACK × OPERATIONS); `maintenance-docs/` is the existing home for pack methodology. Note: this is currently in active use ("Empirical basis: established 2026-05-15", referenced in CLAUDE.md pack-memory), so it is LIVE OPS not historical record — it lives at `maintenance-docs/` top level (not under `archive/` or `v11-implementation/`), siblings to `TOOL-COMPARISON.md` and `RECOMMENDATIONS.md` which are the existing live-methodology files there.
   - `DRY-RUN-MIGRATION.md` → `pack-ops/DRY-RUN-MIGRATION.md`. The file describes pack-repo tooling for org maintainers; it is live operating documentation for the pack's migration harness. `pack-ops/` fits.
   - `MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md`. Same reasoning — consumed primarily by `scripts/migrate-v10-to-v11.sh` (live pack tooling).

2. After the three moves, `supporting-docs/` is unambiguously C4 (PROJECT × PRODUCT) — all remaining files (`AGENT_KICKOFF_TEMPLATE.md`, `CLI-PM-SETUP.md`, `DEPENDENCIES.md`, `INSTALL-PROCEDURES.md`, `METHODOLOGY.md`, `MIGRATION-v10-to-v11.md`, `MIGRATION-v8-to-v9.md`, `SETUP-EXISTING.md`, `SETUP-NEW.md`, `SETUP_TEMPLATE.md`) are PROJECT-audience setup/migration/methodology docs installed to clients per `init-project.sh`. The directory becomes C4 cleanly.

3. The trinity rule in pack memory ("Pack ops files NEVER mixed into pack product files (`project-template/`, `supporting-docs/`)") is then TRUE by construction — `supporting-docs/` contains only PRODUCT files; PACK × OPERATIONS no longer leak in. Architect C may consider whether the rule's wording needs to update to reference the new directory architecture or whether the rule remains valid as-is (it remains valid as-is; the wording "pack product files (project-template/, supporting-docs/)" is still accurate after the moves).

**Path-reference impact:** `scripts/migrate-v10-to-v11.sh` and related scripts reference `supporting-docs/MERGE-STRATEGY.md` and `supporting-docs/DRY-RUN-MIGRATION.md`. After moves, refs update to `pack-ops/MERGE-STRATEGY.md` and `pack-ops/DRY-RUN-MIGRATION.md`. `init-project.sh` does NOT currently install MERGE-STRATEGY or DRY-RUN-MIGRATION to clients (verified by `init-project.sh` grep — the file only installs METHODOLOGY.md and INSTALL-PROCEDURES.md from supporting-docs/), so no install-logic change needed.

**Naming rationale for CONCEPTUAL-REVIEW-METHODOLOGY destination (`maintenance-docs/` vs `pack-ops/`):** `maintenance-docs/` is the existing home for cross-cutting pack methodology (siblings: `TOOL-COMPARISON.md`, `RECOMMENDATIONS.md`, `VERIFIED-NOTES.md`, `ANDROID-ANALYSIS.md`). CONCEPTUAL-REVIEW-METHODOLOGY shares that family — it is methodology that augments multiple pack agents (pack-reviewer, pack-architect, pack-coder). `pack-ops/` is for LIVE OPERATING DOCS read at the start of work cycles (PACK-CHAT.md, PACK-AGENTS.md, HELP-FRAGMENT-PACK.md) — methodology docs are read on-demand by agents, not on every session. The distinction is genuine: live-ops docs are the BACKLOG/CHANGELOG-class (consult every session), methodology docs are the textbook-class (consult when working in their domain). Keeping them in separate dirs preserves Pack Chat's startup-read efficiency and matches the existing maintenance-docs convention.

### §4.2 F-2 resolution: `project-template/docs/pack/` directory NAME

**Problem (audit §B.B21 + §F.F-2):** Directory NAME `pack/` lives inside `project-template/` (project-side) but its name implies "pack-side concerns." Contents are PROJECT-SIDE artifacts that describe pack-related concerns from the project's perspective. The name is misleading; reviewers may misread the directory's audience.

**Resolution:** **The directory NAME stays. No rename.**

Justification:

- Per §1.1, the contents are C5 (PROJECT × OPERATIONS): pack-AUTHORED operations content for PROJECT use. The directory name `pack/` is accurate in the sense that the content's AUTHOR is the pack — it is the pack's voice instructing the project.
- Renaming has a high cost: client repos already have `docs/pack/` populated. A rename to (for example) `docs/pack-operations/` or `docs/project-pm/` would require:
  - Updating ~20-50 path references across the pack repo (per audit §F-2 estimate).
  - A migrator step in `scripts/migrate-v10-to-v11.sh` (or a successor) to rename the client-side dir for existing v10/v11 client repos.
  - Client developer documentation update + announcement.
  - The risk of leaving stale `docs/pack/` references in client-side downstream forks the pack cannot see.
- The G7 boundary-definition doc (§5 below) names this directory explicitly and explains the audience (`docs/pack/` = "pack-AUTHORED operations content for PROJECT use"). With the boundary definition discoverable, the directory NAME's misleading-ness is resolved by documentation rather than rename. Anyone confused by the name reads the boundary definition and understands the category.
- The audit §F-2 contamination pathway is mitigated by Architect C's prevention mechanisms (reviewer protocol amendments + agent guardrails), not by rename. The structural fix (boundary definition + discoverable doc + reviewer/agent guardrails) addresses the root cause; rename alone wouldn't.

**Trade-off accepted:** new readers may briefly confuse the directory name. Mitigation: §5's discoverable boundary definition + Architect C's prevention mechanisms.

**Alternative considered and rejected:** rename `project-template/docs/pack/` to `project-template/docs/pack-authored/` or `project-template/docs/pm/` or `project-template/docs/orchestration/`. All have lower clarity than the current name (which truthfully says "pack-authored content for the project"), all have high migration cost, and none solve the root cause (boundary semantics unstated). Reject.

### §4.3 F-3 resolution: per user override

Per AUDIT-USER-CURATION.md Override 3, F-3 (`.github/` parallel pair) is **not** a structural anti-pattern. Dropped from the SHARED catalog. If Architect C wants to add a divergence-detection test (the two `.github/ISSUE_TEMPLATE/` directories should diverge intentionally, not by drift), Architect C designs that.

This design's response: **NO ACTION on F-3 from B's side.** B confirms the two directories are independent C3 (root) and C6 (`project-template/.github/`) per Override 2.

### §4.4 F-4 resolution: `QUICKSTART.md` split

**Problem (audit §F.F-4):** `QUICKSTART.md` is at pack root but audience-mixed. Pack-side voice ("what is this pack") AND project-side voice ("here's how to set up your coding project"). Referenced from both audiences.

**Resolution:** **SPLIT into two files, one per audience.**

- **Pack-side half** stays at `/QUICKSTART.md`. Audience: GitHub visitors evaluating the pack (C1). Content: brief pack overview, link to README for version history, link to repo for install instructions. Classification: C1 (PACK × PRODUCT, landing-page surface).
- **Project-side half** moves to `project-template/docs/pack/QUICKSTART.md`. Audience: client developer post-install ("you've just installed the pack into your project — start here"). Classification: C5 (PROJECT × OPERATIONS).
- `init-project.sh` installs the project-side half to `<client>/docs/pack/QUICKSTART.md`.

**Content split (executive sketch — Phase 5 coder finalizes content):**

Pack-side `/QUICKSTART.md` after split (~30-50 lines):
- "What is the Optiquity AI Agent Config Pack" (current QUICKSTART.md ll. 1-15 or equivalent).
- "Installing the pack into your project" (1-2 lines pointing to `scripts/init-project.sh` and `supporting-docs/SETUP-NEW.md` / `SETUP-EXISTING.md`).
- "Where to go next as a pack maintainer" — link to `pack-ops/PACK-CHAT.md` (post-relocation).
- "Where to go next as a project developer after install" — link to client-installed `docs/pack/QUICKSTART.md`.

Project-side `project-template/docs/pack/QUICKSTART.md` after split (~50-100 lines):
- "You've installed the Optiquity AI Agent Config Pack — start here."
- Project-side PM chat startup (link to `docs/pack/PM-CHAT.md`).
- Project-side agent overview (link to `docs/pack/PLATFORM-SKILLS.md`).
- Project-side migration paths (link to client-installed migration docs).

**Path-reference impact:** pack-only refs to `QUICKSTART.md` (HELP-FRAGMENT-PACK.md, BACKLOG.md, CHANGELOG.md, README.md, pack-side `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `scripts/validate-pack.py`) point to pack-side `/QUICKSTART.md` (unchanged path). Project-side refs (project-template/README.md, project-template/.gemini/commands/pack-help.toml, project-template/.claude/skills/pack-help/SKILL.md, project-template/docs/pack/HELP-FRAGMENT.md, project-template/.codex/skills/pack-help/SKILL.md) point to `docs/pack/QUICKSTART.md` (the post-install client path; new file). Supporting-docs refs (MERGE-STRATEGY.md, METHODOLOGY.md) — Architect A re-litigates each per content audience.

**`scripts/validate-pack.py:230` (REQUIRED_BD044_DOCS):** currently lists `REPO_ROOT / "QUICKSTART.md"`. This stays valid (pack-side half stays at root). No change.

**`scripts/validate-pack.py:1655` (Check 22 surfaces["pack-root"]["docs"]):** currently lists `REPO_ROOT / "QUICKSTART.md"`. Stays valid. The check needs to gain `REPO_ROOT / "project-template" / "docs" / "pack" / "QUICKSTART.md"` in surfaces["project-template"]["docs"] so the project-side QUICKSTART verbs are validated against `project-template/docs/pack/HELP-FRAGMENT.md`. Phase 5 coder handles this update.

### §4.5 F-5 resolution: `OPTIONAL-FEATURES.md` installed-path mismatch

**Problem (audit §D-8, §E-4, §F.F-5):** OPTIONAL-FEATURES.md is at pack root only, but 5 project-side files reference path `docs/pack/OPTIONAL-FEATURES.md` as if it were installed at client repos. `init-project.sh` does not install it. This is either: (a) the 5 project-side refs are wrong and should be dropped, or (b) OPTIONAL-FEATURES.md should split into pack-side + project-side copies.

**Resolution:** This is genuinely a content-classification question that Architect A re-litigates per project-side reference. B's architectural facts:

- If (a): pack-root `OPTIONAL-FEATURES.md` moves to `pack-ops/OPTIONAL-FEATURES.md` (per §2 row 11). Architect A's per-finding work drops the 5 broken project-side references. No project-side `OPTIONAL-FEATURES.md` exists. `init-project.sh` unchanged.

- If (b): pack-root `OPTIONAL-FEATURES.md` moves to `pack-ops/OPTIONAL-FEATURES.md`. A new file `project-template/docs/pack/OPTIONAL-FEATURES.md` is CREATED with project-side-audience content (subset of pack-side, project-targeted). `init-project.sh` gains a stage to install `project-template/docs/pack/OPTIONAL-FEATURES.md` → `<client>/docs/pack/OPTIONAL-FEATURES.md`. The byte-identity contract pattern (like HELP-FRAGMENT-TRACKER.md Check 24) would NOT apply — the two files differ by audience. The 5 project-side references resolve to the new file.

**B's recommended default (for Phase 5 if Architect A defers):** **(b) — split, with the pack-side half at `pack-ops/` and a new project-side half at `project-template/docs/pack/`.** Rationale:

- The 5 project-side references span 3 different surfaces (HELP-FRAGMENT.md, pack-help SKILL on 3 CLIs); they appear deliberate (multiple authors over multiple BDs added them). Dropping all 5 as "wrong" without re-architecting the project-side help flow is invasive.
- The split pattern is well-established by HELP-FRAGMENT-TRACKER.md (byte-identity) and project-side `docs/pack/HELP-FRAGMENT.md` vs pack-side `HELP-FRAGMENT-PACK.md` (independent content). The infrastructure (validate-pack Check 22 / Check 24, init-project.sh install stages) supports the split pattern.
- A split allows the project-side copy to elide pack-internal details (tracker-mode plumbing relevant only to pack maintainers) while preserving the feature toggle catalog clients need.

Architect A may override this default if the per-finding investigation reveals the project-side refs were genuinely mis-added. B's architectural readiness: both paths are supported (the directory exists in both cases; the difference is just whether the project-side file exists).

### §4.6 F-6 resolution: trinity collisions

**Problem (audit §F.F-6):** Same filenames (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) at pack root and `project-template/`. Naming collision at the prose level; can produce cross-bias when discussions slip on the prose disambiguation.

**Resolution:** **NO RENAME — structurally required pair.** Both pairs are TOOL-CONFIG (C3 at root; C6 at `project-template/`). Each is at the location its CLI mandates. The collision is unavoidable.

The pack memory "Filename uniqueness heuristic" already exempts trinity files explicitly but requires prose disambiguation ("pack-root `CLAUDE.md`" vs "project-template `CLAUDE.md`"). That mechanism is correct as-is.

Architect C's prevention mechanisms (reviewer protocol amendments, agent guardrails) handle the cross-bias risk. B's architectural fact: the collision is structural; no rename is feasible.

### §4.7 F-7 resolution: per user override

Per AUDIT-USER-CURATION.md Override 4, F-7 (parallel CLI dotted-dirs) is **not** a sharing problem. Root `.claude/` / `.codex/` / `.gemini/` are C3; `project-template/.claude/` / `.codex/` / `.gemini/` are C6. Independent TOOL-CONFIG dirs at distinct repo roots. Dropped from the SHARED catalog. **NO ACTION on F-7 from B's side.**

---

## §5 — SC8: discoverability of the boundary definition

### §5.1 The canonical location

The G7 boundary definition is documented as a discoverable file at:

```
pack-ops/BOUNDARY-DEFINITION.md
```

This is the SINGLE SOURCE OF TRUTH for the boundary rules.

**Why `pack-ops/BOUNDARY-DEFINITION.md`?**

- Co-located with the other PACK × OPERATIONS docs (PACK-CHAT, PACK-AGENTS, OPTIONAL-FEATURES, HELP-FRAGMENT-PACK). Readers reaching `pack-ops/` find the boundary definition alongside the other operating docs.
- The directory's purpose (PACK × OPERATIONS — pack-only operating docs) is itself an instance of the boundary rules; having the rules live there is self-referential in a useful way.
- Avoids cluttering pack root with another C2 file (rule consistency: no new C2 at root).

### §5.2 The cross-reference network

The boundary definition is referenced from EVERY surface where an actor might need it. The references take two forms:

1. **Active operating docs** (place a top-of-file pointer):
   - `pack-ops/PACK-CHAT.md` — add a top section "Boundary rules: see `BOUNDARY-DEFINITION.md`". Pack Chat reads PACK-CHAT.md at startup; this is the most consequential pointer.
   - `pack-ops/PACK-AGENTS.md` — add a top section pointer. Every pack agent that reads PACK-AGENTS.md gets the pointer.
   - `pack-root/CLAUDE.md`, `pack-root/AGENTS.md`, `pack-root/GEMINI.md` (pack trinity) — add a pointer in the pack-memory section ("Boundary rules: see `pack-ops/BOUNDARY-DEFINITION.md`"). All three trinity files (per trinity rule in same edit). This puts the pointer in the per-session memory load for every CLI working on the pack repo.
   - `project-template/docs/pack/PM-CHAT.md` — add a pointer to the boundary definition from the PROJECT-side PM chat operating doc. This is critical for the V1 regression pattern: PM chat needs to know that pack-only files are off-limits as references in project-side artifacts. Note the project-side pointer reads "(in the pack repo)" qualifier — clients don't install `pack-ops/`.

2. **Design / planning surfaces** (place a top-of-file pointer):
   - `README.md` § "Repository Layout" — add a one-line pointer "Boundary rules between pack-only and project-only files: see `pack-ops/BOUNDARY-DEFINITION.md`."
   - `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (after F-1 move) — add a pointer in dimension (d) Pack rule adherence so conceptual reviewers cite it.
   - `.claude/agents/pack-architect.md`, `pack-coder.md`, `pack-planner.md`, `pack-reviewer.md`, `pack-docs-researcher.md` (and trinity-parallel `.codex/agents/pack-*.toml`, `.gemini/agents/pack-*.md`) — add a "Boundary rules: read `pack-ops/BOUNDARY-DEFINITION.md` before any classification decision" line to each agent's read-list. Phase 5 coder handles trinity-parallel edits per trinity rule.

3. **Workflow / CI surfaces** (machine-readable):
   - `pack-ops/.boundary-exempt-root.txt` — the closed-set exemption list (§3.3). Co-located so the boundary definition and its mechanical allow-list live next to each other.
   - Architect C's prevention CI gate consumes both the boundary definition (as the human-readable spec) and the exemption list (as the machine-readable allow-list).

### §5.3 The BOUNDARY-DEFINITION.md doc structure

The doc itself contains:

- **§1 Purpose** — one paragraph: this doc is the canonical rule for placing files in the pack repo. Read it before classifying any new file or moving an existing one.
- **§2 The two-axis classification** — verbatim from §1.1 of this design (the matrix + 6 categories + the definitions).
- **§3 The placement verdict procedure** — verbatim from §1.2 of this design (the 4-step procedure).
- **§4 The closed-set root exemption list** — list of files allowed at root despite being C2; pointer to `pack-ops/.boundary-exempt-root.txt` as machine-readable form.
- **§5 SHARED anti-pattern catalog (post-resolution)** — names the historical SHARED entries and their resolutions (per §4 of this design), so future readers don't re-create a resolved anti-pattern.
- **§6 The cross-reference network** — verbatim from §5.2 (where the doc is referenced from, so future maintainers add a pointer to new surfaces).
- **§7 Worked examples** — 6-10 worked classification examples (one per category) showing the verdict procedure applied to real or hypothetical files.

Total length: ~250-350 lines. Pure rule reference (not commentary, not BD-specific). Stable across pack versions; updated only when the boundary definition itself changes.

### §5.4 The discoverability invariant

Any actor — Pack Chat, pack-* agents, pack maintainers, project PM chats, project developers, CI scripts — can reach the boundary definition by ONE of these paths:

- Reading the pack root README (links to `pack-ops/BOUNDARY-DEFINITION.md`).
- Reading PACK-CHAT.md (top-of-file pointer).
- Reading PACK-AGENTS.md (top-of-file pointer).
- Reading the pack trinity (CLAUDE.md / AGENTS.md / GEMINI.md, pack-memory section pointer).
- Reading any pack-* agent file (read-list entry).
- Reading the project-side PM-CHAT.md (post-install qualifier pointer).
- Running an Architect C CI gate that fails with a message naming the doc.

No actor has to GUESS where the rule lives. The invariant is: EVERY operating-doc entry point names the boundary definition. The cross-reference network is dense enough that an actor who reads ANY one of these surfaces is reached.

---

## §6 — Path-reference update strategy (for Phase 5 coder)

This section is concrete enough that a Phase 5 coder can execute mechanically. It covers:

(a) which files move,
(b) which references update,
(c) the order of operations,
(d) the per-file checklists for the relocations with the highest reference counts,
(e) the validate-pack.py constant updates,
(f) the manifest-regen trigger.

### §6.1 The MOVES list (final, after §2 + §4)

Mechanical `git mv` operations (history-preserving):

| # | Source path | Destination path | Reference-count estimate (per audit §E + §F) |
|---|---|---|---|
| M1 | `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | ~22 refs (audit §E-2) |
| M2 | `HELP-FRAGMENT-TRACKER.md` | `pack-ops/HELP-FRAGMENT-TRACKER.md` | ~25 refs (audit §E-3) |
| M3 | `OPTIONAL-FEATURES.md` | `pack-ops/OPTIONAL-FEATURES.md` | ~20+ refs (audit §E-4) |
| M4 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` | ~25+ refs (audit §E-1) |
| M5 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | ~30+ refs (audit §E-5) |
| M6 | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | ~10 refs (estimate from audit §D AMBIGUOUS-pending) |
| M7 | `supporting-docs/DRY-RUN-MIGRATION.md` | `pack-ops/DRY-RUN-MIGRATION.md` | ~5-10 refs (estimate; called by scripts/dry-run-migration.sh) |
| M8 | `supporting-docs/MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | ~15-20 refs (audit §E-2 / §E-7 partial) |

Total: 8 relocations. Aggregate path-reference update count: ~150-200 references across the repo.

### §6.2 The SPLIT list

| # | Source | Pack-side stays | Project-side new | Notes |
|---|---|---|---|---|
| S1 | `QUICKSTART.md` | `QUICKSTART.md` (content trimmed to pack-side audience) | `project-template/docs/pack/QUICKSTART.md` (new file, project-side audience) | Per §4.4. Pack-side path unchanged; project-side path new. `init-project.sh` gains an install stage. |
| S2 | `OPTIONAL-FEATURES.md` (conditional on Architect A) | `pack-ops/OPTIONAL-FEATURES.md` (moved per M3) | `project-template/docs/pack/OPTIONAL-FEATURES.md` (new file, IF B's recommended default per §4.5 is accepted) | Per §4.5. New project-side file under `init-project.sh` install. |

### §6.3 The CREATES list

| # | New file | Category | Purpose |
|---|---|---|---|
| N1 | `pack-ops/BOUNDARY-DEFINITION.md` | C2 | The G7 canonical reference (§5). |
| N2 | `pack-ops/.boundary-exempt-root.txt` | C2 (machine-readable) | The closed-set exemption list (§3.3). |

### §6.4 The order of operations

Phase 5 coder executes in this sequence (planner finalizes; this is B's architectural sequencing):

1. **Create `pack-ops/` directory.** `mkdir pack-ops/` (Phase 5 coder uses an empty placeholder file or first commits N1 to create the dir; git doesn't track empty dirs).
2. **Create N1 (BOUNDARY-DEFINITION.md) and N2 (.boundary-exempt-root.txt).** These have no prior references; they ship clean. Commit as a single commit.
3. **Execute M1-M5 (pack-root → pack-ops/) in one commit.** All five files move with `git mv`. The same commit updates all references to use the new paths (per §6.5 grep + sed plan). The commit also updates:
   - `scripts/lib/tracker-config.sh:298` — change `[[ -f "$repo_root/PACK-CHAT.md" ]]` to `[[ -d "$repo_root/pack-ops" ]]` per §3.2.
   - `scripts/validate-pack.py` constants — see §6.6.
   - `scripts/pack-help.sh` — change `$root/HELP-FRAGMENT-PACK.md` → `$root/pack-ops/HELP-FRAGMENT-PACK.md` (or refactor to a configurable HELP_FRAGMENT_DIR constant).
   - `scripts/init-project.sh:820` — change source path for HELP-FRAGMENT-TRACKER.md copy to client.
4. **Execute M6-M8 (supporting-docs/ → maintenance-docs/ + pack-ops/) in a second commit.** With reference updates for each. Update `scripts/migrate-v10-to-v11.sh` references to MERGE-STRATEGY and DRY-RUN-MIGRATION. Validate Architect A's per-content findings before any content edits to these files (M6-M8 is location-only; content stays as-is).
5. **Execute S1 (QUICKSTART.md split) as a third commit.** Pack-side QUICKSTART.md trims content; project-side QUICKSTART.md is created with project-targeted content; `init-project.sh` gains the install stage; references update. Architect A's per-content findings for QUICKSTART apply to whichever half the content lands on.
6. **Execute S2 (OPTIONAL-FEATURES.md split) as a fourth commit, CONDITIONAL on Architect A's per-finding decision.** If Architect A accepts B's recommended default (§4.5), this commit lands. If Architect A's per-finding work drops the 5 project-side refs, no S2 commit is needed.

Each commit is independently reviewable. Per pack memory "no per-CLI bias in commits", each commit's commit-message includes `BD-175` (per the architect-doc-vs-reality reconciliation pattern). Per the "Regenerate test-fixtures/manifest.txt on every v11-surface commit" rule (CLAUDE.md pack-memory), every commit in this sequence touches `project-template/` and/or `scripts/`, so EVERY commit regenerates `test-fixtures/manifest.txt` and stages it in the same commit.

**Commit decomposition rationale:** 4-5 commits (not 8 — one per MOVES file) because:
- M1-M5 are mechanically uniform (all root → pack-ops/) and best landed together to minimize half-state windows where tracker-config.sh detection and pack-help.sh resolution might disagree.
- M6-M8 are a separate semantic cluster (supporting-docs/ cleanup).
- S1 is content-split work (different shape from MOVES).
- S2 is conditional on Architect A.
- Splitting M1-M5 into 5 separate commits would create 5 partial states where some references resolve and some don't; risk of test breakage between commits.

### §6.5 The grep + sed plan for reference updates

For each MOVES file, the Phase 5 coder runs a repo-wide grep and rewrites references. The pattern is mechanical:

**For M4 (`PACK-AGENTS.md` → `pack-ops/PACK-AGENTS.md`):**

```bash
# Find all references (excluding .git/, archive/, and the file itself):
grep -rn "PACK-AGENTS\.md" . \
    --exclude-dir=.git \
    --exclude-dir=archive \
    --exclude=PACK-AGENTS.md

# Per-reference: determine the calling file's context to choose the
# replacement form:
# - If the calling file is in pack-only context (pack root, .claude/agents/pack-*,
#   .codex/agents/pack-*, .gemini/agents/pack-*, maintenance-docs/, pack-ops/,
#   scripts/, test-fixtures/), replace `PACK-AGENTS.md` → `pack-ops/PACK-AGENTS.md`.
# - If the calling file is in project-side context (project-template/, supporting-docs/),
#   the reference is a CONTAMINATION per audit §D-1 and goes to Architect A's
#   re-litigation queue, not B's mechanical sed.
```

The architectural fact for Phase 5: **B's MOVES + reference updates are mechanical ONLY for pack-only-context references**. Project-side references are Architect A's domain — they may be dropped (V1 contamination → revert), replaced (replace with project-side SSOT pointer), or justified (in the rare cases where a qualified cross-reference is acceptable, e.g., "see `PACK-AGENTS.md` in the pack repo for…" with the "in the pack repo" qualifier explicit). Phase 5 coder does NOT execute mechanical sed against project-side references; Architect A re-litigates each, then a coder applies.

**For M1-M2 (`HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`):**

Pack-only refs (HELP-FRAGMENT-PACK.md, BACKLOG.md, CHANGELOG.md, README.md, QUICKSTART.md, pack trinity, pack-* agents, scripts/, maintenance-docs/) get sed-replaced. Project-side refs in `project-template/docs/pack/HELP-FRAGMENT.md` and supporting-docs setup files: Architect A's domain.

**For M3 (`OPTIONAL-FEATURES.md`):**

Pack-only refs to bare `OPTIONAL-FEATURES.md` → `pack-ops/OPTIONAL-FEATURES.md`. Project-side refs to `docs/pack/OPTIONAL-FEATURES.md` STAY as-is IF S2 lands (the new project-side file resolves them). If Architect A's per-finding work drops the project-side refs, the refs are removed (not relocated).

**For M5 (`PACK-CHAT.md`):**

Pack-only refs → `pack-ops/PACK-CHAT.md`. CRITICAL: also update `scripts/lib/tracker-config.sh:298` per §3.2. CRITICAL: also update the boundary-detection signal in any other script or test fixture that uses `PACK-CHAT.md` existence as a "this is the pack repo" check.

```bash
# Find all PACK-CHAT.md file-existence checks:
grep -rn '\bPACK-CHAT\.md\b' --include="*.sh" --include="*.py" . | grep -E '(test -f|-f.*PACK-CHAT|exists.*PACK-CHAT)'
```

**For M6 (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` → `maintenance-docs/`):**

References in CLAUDE.md pack-memory (line range to be verified) name the file; update path. Any pack-reviewer prompt references update. Any AUDIT-*.md (this audit references it as audit §F-1).

**For M7-M8 (`supporting-docs/DRY-RUN-MIGRATION.md`, `MERGE-STRATEGY.md` → `pack-ops/`):**

Update `scripts/dry-run-migration.sh` and `scripts/migrate-v10-to-v11.sh` references. Update supporting-docs cross-references (METHODOLOGY.md, INSTALL-PROCEDURES.md, MIGRATION-v*.md may reference them).

### §6.6 `scripts/validate-pack.py` constant updates

After M1-M5, M6-M8, S1, S2 land, the following constants in `scripts/validate-pack.py` update:

| Current line | Current value | Updated value |
|---|---|---|
| `230` | `REPO_ROOT / "QUICKSTART.md"` | unchanged (S1 leaves pack-side at root) |
| `1654` | `REPO_ROOT / "PACK-CHAT.md"` | `REPO_ROOT / "pack-ops" / "PACK-CHAT.md"` |
| `1655` | `REPO_ROOT / "QUICKSTART.md"` | unchanged |
| `1656` | `REPO_ROOT / "OPTIONAL-FEATURES.md"` | `REPO_ROOT / "pack-ops" / "OPTIONAL-FEATURES.md"` |
| `1659` | `REPO_ROOT / "HELP-FRAGMENT-PACK.md"` | `REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"` |
| `1669` | `REPO_ROOT / "HELP-FRAGMENT-TRACKER.md"` | `REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"` |
| `1735` | `REPO_ROOT / "HELP-FRAGMENT-PACK.md"` | `REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"` |
| `1736` | `REPO_ROOT / "HELP-FRAGMENT-TRACKER.md"` | `REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"` |
| `1929` | `REPO_ROOT / "HELP-FRAGMENT-TRACKER.md"` (Check 24 pack-root half of byte-identity) | `REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"` |
| `1930` | `REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md"` (Check 24 client half) | unchanged |
| `2482` | `REPO_ROOT / "tracker.toml.pack-example"` | unchanged (per user override 1, STAYS at root) |

Check 22 "surfaces" dict (line 1650-1668): Phase 5 coder also adds `REPO_ROOT / "project-template" / "docs" / "pack" / "QUICKSTART.md"` to the `surfaces["project-template"]["docs"]` list per §4.4 if S1 lands.

The constant-update commit (or commits) should NOT be separated from the M-commits that move the files — that would create a window where validate-pack fails. Bundle each scripts/validate-pack.py constant update with the file-move commit that requires it.

### §6.7 The manifest-regen requirement

EVERY commit in §6.4 sequence touches `project-template/` and/or `scripts/`. Per CLAUDE.md pack-memory "Regenerate test-fixtures/manifest.txt on every v11-surface commit", every such commit MUST also regenerate `test-fixtures/manifest.txt` and stage it in the same commit. Phase 5 coder:

```bash
bash test-fixtures/build.sh --all --clean
git diff test-fixtures/manifest.txt   # If non-empty:
git add test-fixtures/manifest.txt
```

This is non-negotiable. Skipping it produces the 2026-05-17 incident pattern (recovery commit ef9e5c7 standalone).

### §6.8 Phase 5 verification protocol

After each commit lands:

1. `bash scripts/validate-pack.py` — all checks pass (especially Check 22, Check 24).
2. `bash scripts/pack-help.sh --root .` — pack-side fragment resolves from new path.
3. `bash scripts/pack-help.sh --root project-template` — project-side fragment resolves unchanged.
4. `bash scripts/lib/tracker-config.sh tracker_config_auto_surface .` — returns "pack-surface: pack" (using new `-d pack-ops` signal).
5. `bash scripts/lib/tracker-config.sh tracker_config_auto_surface project-template` — returns "pack-surface: client" unchanged.
6. CI Validate Pack workflow passes on push (per CLAUDE.md "CI validation: The Validate Pack GitHub Actions workflow runs on every push. If it fails, fix before proceeding.").

If any verification step fails, Phase 5 reverts the offending commit and re-investigates before re-landing.

---

## §7 — Architectural facts that bear on Architect A and Architect C

This section names facts B has surfaced that may be inputs to A and C, while staying in B's domain (no design in their domains).

### §7.1 For Architect A

- The 17 confirmed CONTAMINATION references (audit §D-9) become re-litigation work AT THE NEW PATHS. After M1-M5 land, references like `project-template/CLAUDE.md:366` ("see `PACK-AGENTS.md` for the full roster") become qualified pointers to `pack-ops/PACK-AGENTS.md` IF Architect A's decision is "justify with explicit pack-repo qualifier", or are dropped IF Architect A's decision is "this is contamination; remove the pointer entirely". B's architectural fact: both options are mechanically supported.
- For the V4 cluster (CONCEPTUAL-REVIEW-METHODOLOGY contamination): the file MOVES per M6 (`supporting-docs/` → `maintenance-docs/`). After M6 lands, all 11 AMBIGUOUS-pending-§F references in audit §D-2/§D-3/§D-4/§D-5 convert to LEGITIMATE (pack-only references in a pack-only file). Architect A's per-finding work on these may shorten to "confirm relocation resolves the AMBIGUOUS verdict; no per-line content change needed."
- For the V3 finding (PLATFORM-SKILLS.md `PACK-AGENTS.md` reference): the project-side PLATFORM-SKILLS.md is C5 (PROJECT × OPERATIONS); referencing pack-only `pack-ops/PACK-AGENTS.md` from client-installed PLATFORM-SKILLS.md remains a broken pointer. Architect A's per-finding decision (drop the reference vs. add a qualified "(in the pack repo)" prefix vs. relocate the rationale to project-side SSOT) is unchanged by B's MOVES.
- For OPTIONAL-FEATURES.md: B's recommended default (§4.5 option (b) — split) is mechanically supported. If Architect A chooses option (a) — drop the 5 project-side refs — the architectural readiness still holds; B's MOVES land identically and the project-side file is NOT created.

### §7.2 For Architect C

- The closed-set exemption list (`pack-ops/.boundary-exempt-root.txt`, §3.3) is the allow-list for Architect C's "no new C2 docs at root" CI gate.
- The boundary definition (`pack-ops/BOUNDARY-DEFINITION.md`, §5.3) is the human-readable spec Architect C's agent guardrails and reviewer-protocol amendments reference. Architect C decides the form of the guardrail (read-list addition, agent-prompt boilerplate, reviewer checklist item); B provides the canonical doc.
- The `tracker-config.sh` auto-detection migration (§3.2) is mechanical (changes one bash conditional) and lands as part of M5. Architect C may consider whether the detection signal itself should be more robust (e.g., a dedicated `.pack-repo-marker` file or a function-returning-from-multiple-signals), but that's a separate prevention-design decision not part of B's MOVES.
- The PROJECT-side `docs/pack/` directory NAME is preserved (per §4.2); Architect C's reviewer-protocol amendments should include an explicit "the directory `project-template/docs/pack/` is PROJECT-AUTHORED OPERATIONS content for PROJECT use, NOT a pack-side mirror" — this is the documentation-based mitigation B chose over rename.
- The F-3 / F-7 "process friction" considerations user-curation Override 3 mentions (intentional-vs-drift divergence tests for `.github/` and CLI dotted-dirs) are Architect C's domain to design or skip.

---

## §8 — Summary

### Deliverables in this design

1. **§1 — G7 boundary definition** (two-axis classification + verdict procedure + unimpeachability + unambiguity + user-intent preservation).
2. **§2 — Updated root-directory inventory** (5 PACK × OPERATIONS files MOVE; 3 stay by exemption; pack root becomes clean).
3. **§3 — New top-level directory `pack-ops/`** (home for relocated PACK × OPERATIONS files + boundary definition + machine-readable exemption list).
4. **§4 — SHARED anti-pattern resolutions** (F-1 split by audience; F-2 keep name + document; F-3/F-7 dropped per user; F-4 QUICKSTART split; F-5 OPTIONAL-FEATURES conditional split; F-6 trinity no-rename).
5. **§5 — SC8 discoverability** (canonical `pack-ops/BOUNDARY-DEFINITION.md` + dense cross-reference network across operating docs / trinity / agent files / project-side PM-CHAT.md / README + machine-readable allow-list).
6. **§6 — Path-reference update strategy** (MOVES list M1-M8 + SPLIT list S1-S2 + CREATES N1-N2 + order of operations + grep+sed plan + validate-pack.py constant updates + manifest-regen contract + verification protocol).
7. **§7 — Facts for Architect A and Architect C** (without designing in their domains).

### Final-state directory architecture

```
pack-repo-root/
├── .DS_Store                         (ignored)
├── .gitignore                        (C3)
├── .claude/, .codex/, .gemini/       (C3 — pack-side CLI configs)
├── .github/                          (C3 — pack-side CI + issue templates)
├── AGENTS.md, CLAUDE.md, GEMINI.md   (C3 — pack trinity)
├── README.md                         (C1 — GitHub landing page)
├── LICENSE.md                        (C1 — GitHub license discovery)
├── QUICKSTART.md                     (C1 — pack-side half post-split)
├── BACKLOG.md                        (C2 exempt — CI Check 32 pinned)
├── CHANGELOG.md                      (C2 exempt — CI Check 32 pinned)
├── tracker.toml.pack-example         (C2 exempt — user override)
│
├── pack-ops/                         (NEW — C2 top-level dir)
│   ├── .boundary-exempt-root.txt     (NEW — closed-set exemption list)
│   ├── BOUNDARY-DEFINITION.md        (NEW — G7 canonical reference)
│   ├── HELP-FRAGMENT-PACK.md         (moved from root)
│   ├── HELP-FRAGMENT-TRACKER.md      (moved from root)
│   ├── OPTIONAL-FEATURES.md          (moved from root)
│   ├── PACK-AGENTS.md                (moved from root)
│   ├── PACK-CHAT.md                  (moved from root)
│   ├── MERGE-STRATEGY.md             (moved from supporting-docs/)
│   └── DRY-RUN-MIGRATION.md          (moved from supporting-docs/)
│
├── maintenance-docs/                 (C2 — pack design records + cross-cutting methodology)
│   ├── CONCEPTUAL-REVIEW-METHODOLOGY.md  (moved from supporting-docs/)
│   ├── TOOL-COMPARISON.md, RECOMMENDATIONS.md, etc.
│   ├── archive/, guides/, origins/, v11-implementation/, v11-research/
│   └── (unchanged otherwise)
│
├── scripts/                          (C2 — pack-only scripts)
├── test-fixtures/                    (C2 — pack-only test infra)
│
├── supporting-docs/                  (C4 — PROJECT × PRODUCT; now clean)
│   ├── AGENT_KICKOFF_TEMPLATE.md, CLI-PM-SETUP.md, DEPENDENCIES.md
│   ├── INSTALL-PROCEDURES.md, METHODOLOGY.md
│   ├── MIGRATION-v10-to-v11.md, MIGRATION-v8-to-v9.md
│   ├── SETUP-EXISTING.md, SETUP-NEW.md, SETUP_TEMPLATE.md
│   └── (PACK × OPERATIONS files removed)
│
├── project-template/                 (C4 / C5 / C6 — project-installed)
│   ├── CLAUDE.md, AGENTS.md, GEMINI.md   (C6 — project trinity)
│   ├── .claude/, .codex/, .gemini/, .github/  (C6 — project CLI configs)
│   ├── docs/
│   │   ├── pack/                     (C5 — PROJECT × OPERATIONS, name preserved per §4.2)
│   │   │   ├── HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md
│   │   │   ├── PACK-FEEDBACK.md, PLATFORM-SKILLS.md, PM-CHAT.md
│   │   │   ├── QUICKSTART.md         (NEW — project-side half from S1 split)
│   │   │   ├── OPTIONAL-FEATURES.md  (NEW conditional — from S2 split if Architect A accepts default)
│   │   │   └── prompts/
│   │   └── project/                  (C4 — project's own work-tracking trees)
│   ├── proto/, scripts/, server/, skills/  (C4)
│   └── tracker.toml.project-example  (C6)
│
├── vscode-companion-templates/       (C4 — machine-installed companion)
└── xcode-companion-templates/        (C4 — machine-installed companion)
```

The architecture has **zero SHARED directories** post-resolution. Every directory and file fits exactly one of C1–C6.

---

## §9 — End

This design ships the G7 boundary definition, the SC8 discoverability mechanism, the G2 directory architecture, and the path-reference update strategy. Phase 5 coder executes mechanically per §6. Architect A re-litigates the 17 contamination references (which become qualified-pointer or drop decisions at the new paths). Architect C designs the CI gate against the closed-set exemption list, the reviewer-protocol amendments referencing `pack-ops/BOUNDARY-DEFINITION.md`, and the agent-prompt boilerplate that ensures every pack-* agent reads the boundary definition before any classification decision.

The user-stated boundary articulation (AUDIT-USER-CURATION.md §5) is preserved verbatim in §1.5. All four user curation overrides are honored (§2.1, §4.3, §4.5, §4.7 specifically address them). No edge case in the audit §A / §B / §F catalogs is left without a placement verdict.
