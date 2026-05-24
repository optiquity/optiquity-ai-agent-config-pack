# ARCHITECTURE-V11-GUARDRAILS-CONTRACT

**Status:** implementation-ready contract doc (architect-pass output)
**Author:** pack-architect (read-only analysis)
**Date:** 2026-05-21
**Branch:** v11-dev
**HEAD at design time:** `9da98a44d9b7c2236f8dacd8632bca6e9b662963`
**Scope:** 4 boundary-leak guardrails per `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` §4 (Guardrails 1-4). Translated from strategy-doc gap diagnosis into implementation contracts a pack-coder can apply mechanically.
**Out of scope:** D-11 cascade work (revising V1 19c plan §C placements); leak-sweep edits themselves (Categories A-F per strategy §1).

---

## §0 Cross-cutting reading aids

### 0.1 Naming conventions used in this doc

- **Guardrail N** — the strategy-doc enumerated mitigation (1 = new Check 43; 2 = per-line fence; 3 = `_PROJECT_SIDE_ROOTS` expansion; 4 = PREFLIGHT extension).
- **`<symbol>`** — Python identifier in `scripts/validate-pack.py`.
- **`<path>`** — repo-relative path from REPO_ROOT.
- **FAIL / PASS** — Check verdict for a file:line; FAIL emits the `fail(...)` helper, PASS counts toward the legitimate-hits accumulator.

### 0.2 Source-of-truth inputs

This contract is derived from:

| Source | Used for |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` §3-§4 | Gap diagnosis, intended guardrail behavior |
| `maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` §1-§2 + §4.1 | Leak inventory for fixture-spec validation |
| `scripts/validate-pack.py` Check 37 / 40 / 41 functions | Mechanism reuse (basename index, allowlist, anchor phrases, code-block stripping, `_parse_client_installed_files`) |
| `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES_START`/`_END` (lines 1275-1314) | Inventory walked by Check 43 |
| `project-template/skills/boundary-investigation/SKILL.md` (current 187 lines) | Fence-marker placement plan (Guardrail 2) |
| `pack-ops/PACK-AGENTS.md` § Pack-coder PREFLIGHT (lines 190-211) | PREFLIGHT extension anchor (Guardrail 4) |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` § Review dimensions (lines 24-44, 173-203) | Reviewer dimension extension (Guardrail 4) |
| `scripts/tests/test-validate-pack-check-40.sh` | Fixture-test pattern (Guardrail 1) |

### 0.3 Implementation order (full justification in §5.1; UPDATED 2026-05-24 for H.12/H.13 reorder)

| Order | PLAN H.N | Guardrail | Rationale |
|---|---|---|---|
| H.9.2 | PLAN H.13 (lands FIRST per 2026-05-24 reorder) | Guardrail 2 (per-line fence; **11 files** — expanded from 7 per reorder; +4 dual-surface) | Modifies validate-pack.py + boundary-investigation SKILL.md + 4 dual-surface files (RC9 fires). Per 2026-05-24 STOP-AND-ESCALATE evidence, the fence must cover 4 dual-surface files (METHODOLOGY.md + INSTALL-PROCEDURES.md + detect.sh + pack-help.sh) BEFORE scope expansion ratifies the cleaned state — otherwise 26 false-positive Check 37 fails. |
| H.9.1 | PLAN H.12 (lands AFTER per 2026-05-24 reorder) | Guardrail 3 (scope expansion) | Foundation for Guardrail 1; touches only validate-pack.py + test (no fixture-affecting beyond scripts/). Per 2026-05-24 reorder, lands AFTER Guardrail 2 (commit log shows "Batch 19c.13" BEFORE "Batch 19c.12" — intentional per user direction B2 preserving PLAN H.N names). |
| H.9.3 | PLAN H.14 | Guardrail 1 (Check 43) | New check + new fixture-test + CI wiring; depends on Guardrail 3 scope (RC9 fires) |
| H.9.4 | PLAN H.15 | Guardrail 4 (PREFLIGHT extension) | Doc-only; trinity PACK-AGENTS.md + CONCEPTUAL-REVIEW-METHODOLOGY.md + memory cache (PM-only commit; RC9 fires per BD-176 pack-ops/ expansion) |

---

## §1 Guardrail 1 — Check 43 full contract (new class-test bare-cross-reference scanner)

**Gap closed (strategy §3.5 + §3.6 + §4.1):** Check 37's deny-list enumerates 3 filenames + 2 path prefixes + 5 agent names + 1 role name. It does NOT catch bare `ARCHITECTURE-*.md`, bare `AUDIT-*.md`, bare `SETUP-NEW.md`, bare `CLI-PM-SETUP.md`, or qualified `maintenance-docs/...` cites in `scripts/` (out of scope). Check 40's mechanism (basename index + allowlist + anchor phrases + code-block stripping) is the right tool but scoped to `pack-ops/*.md` only. Check 43 reuses the Check 40 mechanism on the project-side surface; resolution against the basename index is a CLASS TEST ("does this name resolve into pack-only territory?") rather than a NAME ENUMERATION ("is this exact name in the deny-list?").

### 1.1 Function signature

```python
def check_project_side_bare_internal_refs() -> None:
    """Check 43 — project-side / client-installed bare cross-references
    to pack-internal files (V11 leak-sweep prevention; strategy §4.1).
    ...
    """
```

- **Name:** `check_project_side_bare_internal_refs`
- **Return type:** `None` (uses module-level `failures` list + `ok()` / `fail()` helpers, same as Checks 37 / 40)
- **Side effects:** print + accumulate failures via `fail()`; emit summary via `ok()` when clean
- **No parameters.** Walks the canonical client-installed surface from the module-level helper defined in §3 (Guardrail 3).

### 1.2 Walked files set

Check 43 scans the UNION of:

1. **All files under `project-template/`** (recursive; same set Check 37 walks today via `_iter_project_side_files()` with Guardrail 3's expansion). Extension filter: `{.md, .sh, .py, .toml, .yml, .yaml, .json, .txt}` (matches Check 40's `_CHECK_40_FILE_EXTS`).
2. **The explicit client-installed file subset from `_CLIENT_INSTALLED_FILES`** (parsed by Guardrail 3's `_iter_client_installed_files()`) that lives OUTSIDE `project-template/`. At HEAD, these are:
   - `pack-ops/HELP-FRAGMENT-TRACKER.md` (byte-identical mirror per Check 24)
   - `supporting-docs/METHODOLOGY.md`
   - `supporting-docs/INSTALL-PROCEDURES.md`
   - `scripts/pack-help.sh`
   - `scripts/lib/detect.sh`

**Excluded** from the walk (defensive — these are pack-only by construction):
- `project-template/` files that match `_CHECK_40_EXCLUDE_PARTS` (none today, but defensive)
- Binary files (catch `UnicodeDecodeError` per Check 37 pattern at line 4179)

### 1.3 Basename index reuse

- **Reuse `_build_basename_index()` from Check 40** (lines 4756-4786). Single basename index built ONCE per Check 43 invocation (same pattern as Check 40 §5.3). Different call from Check 40's invocation; both use the same index builder.
- **Reuse `_strip_code_blocks()` from Check 40** (lines 4663-4742). Lines inside fenced or 4-space-indented code blocks are erased before pattern matching.
- **Reuse `_CHECK_40_BARE_REF_PATTERN` + `_CHECK_40_HYPERLINK_PATTERN`** (lines 4649-4657). Same backtick-span + `[link](path)` recognition.

**No new regex.** No new exclude list. Differences from Check 40 are scope (project-side surface vs pack-ops/) and allowlist (different legitimate set).

### 1.4 Allowlist design — `_CHECK_43_ALLOWLIST`

Different shape from Check 40's `_CHECK_40_ALLOWLIST` because the project-side surface has different legitimate-resolution targets.

```python
_CHECK_43_ALLOWLIST: dict[str, str] = {
    # Project-side trinity (client-side resolution).
    "CLAUDE.md": "Project-side trinity at client root (also project-template/CLAUDE.md)",
    "AGENTS.md": "Project-side trinity at client root (also project-template/AGENTS.md)",
    "GEMINI.md": "Project-side trinity at client root (also project-template/GEMINI.md)",
    # Project-side README + LICENSE.
    "README.md": "Project-side or pack-side README (resolves at both)",
    "LICENSE.md": "Standard repo convention",
    "LICENSE": "Standard repo convention",
    # Pack-feedback cross-boundary product feature (PM chat writes here).
    "PACK-FEEDBACK.md": "Project-side cross-boundary feedback channel (docs/pack/)",
    # Project-side methodology / install docs (post-install at docs/pack/).
    "METHODOLOGY.md": "Project-side docs/pack/METHODOLOGY.md (client-installed)",
    "INSTALL-PROCEDURES.md": "Project-side docs/pack/INSTALL-PROCEDURES.md (client-installed)",
    "PM-CHAT.md": "Project-side docs/pack/PM-CHAT.md (client-installed orchestrator rules)",
    "PLATFORM-SKILLS.md": "Project-side docs/pack/PLATFORM-SKILLS.md (client-installed)",
    "OPTIONAL-FEATURES.md": "Project-side docs/pack/OPTIONAL-FEATURES.md (client-installed)",
    "HELP-FRAGMENT.md": "Project-side docs/pack/HELP-FRAGMENT.md (client-installed)",
    "HELP-FRAGMENT-TRACKER.md": "Project-side docs/pack/HELP-FRAGMENT-TRACKER.md (client-installed; byte-identical mirror per Check 24)",
    "SETUP-EXISTING.md": "Project-side docs/pack/SETUP-EXISTING.md (client-installed install doc)",
    # Per-entry skeleton filename PATTERNS (template placeholders, not real files).
    "BD-NNN.md": "Per-entry backlog filename pattern (template)",
    "TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
    "phase-N.md": "Per-entry implementation-plan filename pattern (template)",
    # Per-entry tree sibling skeleton files (resolve same-dir within docs/project/<stream>/).
    "_rules.md": "Per-entry tree per-stream rules sibling (same-dir resolution)",
    "_intro.md": "Per-entry tree intro sibling (same-dir resolution)",
    "_format.md": "Per-entry tree format sibling (same-dir resolution)",
    # Project-side mirrors (regenerated; never source of truth but resolve at client install).
    "BACKLOG.md": "Project-side mirror (regenerated); at client docs/project/",
    "CHANGELOG.md": "Project-side mirror (regenerated); at client docs/project/",
    "IMPLEMENTATION-PLAN.md": "Project-side mirror (regenerated); at client docs/project/",
    "STATUS.md": "Project-side STATUS.md (PM chat maintains)",
    "ARCHITECTURE.md": "Project-side docs/project/ARCHITECTURE.md (PM/architect maintains)",
    # Generated / opt-in / external files.
    "tracker.toml": "Generated by `pack tracker init` (not in project repo at install)",
    "tracker.toml.example": "Project-side example shipped at client root",
    "id-map.json": "Generated tracker-mode metadata",
    "MEMORY.md": "Claude-Code memory cache (~/.claude/, external to project)",
    # Standard project scripts that resolve at client install.
    "agent-run.sh": "Project-side agent launcher at client root",
}
```

**Provenance:** every entry maps to a file shipped to clients via `_CLIENT_INSTALLED_FILES` OR a name explicitly external/generated. Every entry carries a one-line rationale (per Check 40 §6.5 self-documenting allowlist convention).

### 1.5 Anchor-phrase reuse — `_CHECK_43_ANCHOR_PHRASES`

Reuse Check 40's anchor-phrase set verbatim, since the legitimate-context callouts are the same class. Trade-off: tighter coupling between Check 40 and Check 43 anchor logic; benefit: zero divergence, future anchor additions propagate.

```python
_CHECK_43_ANCHOR_PHRASES = _CHECK_40_ANCHOR_PHRASES  # alias; same set
_CHECK_43_ANCHOR_WINDOW = _CHECK_40_ANCHOR_WINDOW    # alias; 2
```

Implementation note: prefer aliasing over duplication. If a future maintainer needs to diverge, the alias is a one-line edit to a fresh tuple.

### 1.6 Supporting-docs subset rule

The 5 client-installed files in `supporting-docs/` + `pack-ops/` + `scripts/` are LEGITIMATE resolution targets. Files in `supporting-docs/` that are NOT client-installed are FORBIDDEN resolution targets.

| supporting-docs/ file | Client-installed? | Treatment in Check 43 |
|---|---|---|
| `METHODOLOGY.md` | Yes (per `_CLIENT_INSTALLED_FILES` line 1310) | Allowlist (resolution to `docs/pack/METHODOLOGY.md` post-install is legitimate) |
| `INSTALL-PROCEDURES.md` | Yes (per `_CLIENT_INSTALLED_FILES` line 1311) | Allowlist |
| `CLI-PM-SETUP.md` | **NO** (audit §0.3 Note 2) | **FAIL** if referenced from project-side |
| `SETUP-NEW.md` | **NO** (audit §0.3 Note 2) | **FAIL** if referenced from project-side |
| `SETUP_TEMPLATE.md` | **NO** (audit §0.3 Note 2) | **FAIL** if referenced from project-side |
| `AGENT_KICKOFF_TEMPLATE.md` | **NO** (audit §0.3 Note 2) | **FAIL** if referenced from project-side |
| `MIGRATION-v10-to-v11.md` | **NO** (audit §0.3 Note 2) | **FAIL** if referenced from project-side |

**Implementation:** parse `_CLIENT_INSTALLED_FILES` via the Guardrail 3 helper; build the set of supporting-docs/ filenames that ARE installed. When a bare-ref resolves to `supporting-docs/<X>` AND `<X>` is NOT in the installed-set, FAIL with the "pre-install-only" diagnostic.

### 1.7 Fail conditions and PASS conditions

Single bare ref produces ONE of these verdicts:

| Verdict | Trigger | Output |
|---|---|---|
| PASS (allowlist) | basename in `_CHECK_43_ALLOWLIST` | `hits_allowlist += 1`; no print |
| PASS (anchor) | `_CHECK_43_ANCHOR_PHRASES` match in ±2-line window | `hits_anchor += 1`; no print |
| PASS (same-dir) | exactly one candidate, candidate dir == referencing-file dir | `hits_same_dir += 1`; no print |
| PASS (client-installed) | basename resolves to a client-installed pack-ops/supporting-docs/scripts/ file | `hits_client_installed += 1`; no print |
| **FAIL (pack-internal target)** | basename resolves into `maintenance-docs/` OR `pack-ops/` (excluding client-installed `pack-ops/HELP-FRAGMENT-TRACKER.md`) | `fail(...)` with file:line + matched basename + resolution target |
| **FAIL (pre-install-only `supporting-docs/`)** | basename resolves into `supporting-docs/<X>` AND `<X>` not in client-install set | `fail(...)` with "pre-install reference; not shipped to clients" |
| **FAIL (broken)** | 0 candidates AND not on allowlist AND no anchor | `fail(...)` with "broken ref" |
| **FAIL (ambiguous)** | 2+ candidates AND none is a client-installed legitimate target AND no same-dir match | `fail(...)` with "qualify to one of" |

### 1.8 Failure message format

```
<rel_path>:<lineno> — bare cross-reference `<basename>` resolves to pack-internal target `<resolution_path>` (pack-only — not at client install). Remediation: drop the cite OR replace with a project-side SSOT (e.g., docs/pack/PM-CHAT.md for orchestration rules) OR — if intentional pack-as-product cite — add an anchor phrase like "in the pack repo" within ±2 lines OR add `<basename>` to `_CHECK_43_ALLOWLIST` in scripts/validate-pack.py with one-line rationale.
```

Variants for the other FAIL classes follow the Check 40 pattern (lines 4904-4912).

### 1.9 Mirror-skip exclusions

Exclude these from the walk because they are regenerated mirrors of project-side per-entry trees and may legitimately mirror pack-internal cites that exist in the per-entry source (pre-sweep state at HEAD):

| Excluded basename | Why |
|---|---|
| `BACKLOG.md` (under `docs/project/`) | Regenerated mirror per project trinity / `_rules.md` |
| `CHANGELOG.md` (under `docs/project/`) | Regenerated mirror |
| `IMPLEMENTATION-PLAN.md` (under `docs/project/`) | Regenerated mirror |

These are *project*-side mirrors. Check 43 walks the SOURCE trees (`docs/project/backlog/`, `docs/project/changelog/`, `docs/project/implementation-plan/`) which ARE in scope.

### 1.10 Fixture test spec — `scripts/tests/test-validate-pack-check-43.sh`

Follow the structural pattern of `test-validate-pack-check-40.sh`. Seven test groups:

| Group | Purpose |
|---|---|
| Group 0 | Module import + Check 43 symbol registration (`check_project_side_bare_internal_refs`, `_CHECK_43_ALLOWLIST`, `_iter_client_installed_files`) |
| Group 1 | `_CHECK_43_ALLOWLIST` is non-empty AND every entry has a non-empty rationale string |
| Group 2 | `_iter_client_installed_files()` returns expected base set (verifies inventory parse + path conversion) |
| Group 3 | Anchor-phrase exemption — verifies aliased anchor set works (smoke test, since Check 40 covers full case set) |
| Group 4 | End-to-end synthetic-tree check (analog of Check 40's Group 5) |
| Group 5 | Static fixture file sanity (under `scripts/tests/fixtures/project-side-refs/`) |
| Group 6 | End-to-end `validate-pack.py` exit-status on HEAD — Check 43 PASSES at HEAD AFTER the leak sweep lands (PRE-sweep, Check 43 FAILS; the test thus runs AFTER the sweep commits in Batch 19c) |

**Fixture file enumeration** (`scripts/tests/fixtures/project-side-refs/`):

| Filename | Class | Expected verdict |
|---|---|---|
| `README.md` | docs | (test fixture README) |
| `project-side-fail-per-entry-skeleton.md` | LEAK CLASS A (audit §1.19) | FAIL (1+ `ARCHITECTURE-PER-ENTRY-SPLIT.md` bare ref) |
| `project-side-fail-architect-doc-cite.md` | LEAK CLASS A (audit §1.19) | FAIL (`ARCHITECTURE-V3.3-DELTA.md` bare ref) |
| `project-side-fail-detect-sh-comment.sh` | LEAK CLASS D (audit §2.5) | FAIL (`maintenance-docs/v11-implementation/ARCHITECTURE-*.md` in shell comment) |
| `project-side-fail-pmstartup-cite.md` | LEAK CLASS E (audit §1.10) | FAIL (`ARCHITECTURE-V3.md` bare ref) |
| `project-side-fail-pmchat-self-prompt.md` | LEAK CLASS C (audit §1.14) | FAIL (`supporting-docs/SETUP-NEW.md` qualified ref to non-installed file) |
| `project-side-fail-mcp-example.json` | LEAK CLASS C (audit §1.15) | FAIL (`supporting-docs/CLI-PM-SETUP.md` ref to non-installed file) |
| `project-side-fail-audit-cite-in-skill.md` | LEAK CLASS F (audit §1.7.124) | FAIL (`AUDIT-USER-CURATION.md` bare ref — the BD-175 self-leak class) |
| `project-side-pass-pack-feedback.md` | Cross-boundary product feature | PASS (`PACK-FEEDBACK.md` allowlist entry) |
| `project-side-pass-allowlist-methodology.md` | Client-installed supporting-docs/ | PASS (`METHODOLOGY.md` allowlist entry) |
| `project-side-pass-anchor-pack-repo.md` | "in the pack repo" anchor | PASS (anchor exemption) |
| `project-side-pass-same-dir-skeleton.md` | Same-dir per-entry sibling | PASS (`_intro.md` resolves same-dir within `docs/project/backlog/`) |
| `project-side-pass-code-block.md` | Bare ref inside fenced code | PASS (code-block stripping) |

**Total: 13 fixture files (7 FAIL + 5 PASS + 1 README).**

**Synthetic-tree end-to-end tests** (Group 4): mirror Check 40's Group 5 pattern. Expected cases:

| Test | Synthetic input | Expected |
|---|---|---|
| T1 | Project-side file with `MIGRATION-v10-to-v11.md` bare ref + `supporting-docs/MIGRATION-v10-to-v11.md` exists but not in client-install set | FAIL (pre-install-only) |
| T2 | Project-side file with `PACK-FEEDBACK.md` bare ref + `project-template/docs/pack/PACK-FEEDBACK.md` exists | PASS (allowlist) |
| T3 | Project-side file with `ARCHITECTURE-V3.md` bare ref + file resolves to `maintenance-docs/v11-research/ARCHITECTURE-V3.md` | FAIL (pack-internal target) |
| T4 | Project-side file with `AUDIT-USER-CURATION.md` bare ref + file resolves to `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` | FAIL (pack-internal target — BD-175 self-leak class) |
| T5 | Project-side file with `pack-ops/MERGE-STRATEGY.md` qualified ref | FAIL (pack-only path prefix; class identical to Check 37 pack-ops/ deny-prefix) |
| T6 | Project-side file with bare ref + anchor "in the pack repo" within ±2 lines | PASS (anchor exemption) |
| T7 | Project-side file with bare ref inside a fenced code block | PASS (code-block stripping) |
| T8 | `scripts/lib/detect.sh` synthetic with `# maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md:` comment | FAIL (verifies .sh scope + path-prefix detection) |
| T9 | `project-template/docs/project/backlog/_rules.md` synthetic with same-dir bare ref `_intro.md` | PASS (allowlist same-dir; resolves via _CHECK_43_ALLOWLIST) |

**Total: 9 synthetic-tree test cases.**

### 1.11 CI wiring — `.github/workflows/validate-pack.yml`

Add the per-check test invocation (after the Check 42 wiring at line 183):

```yaml
      - name: validate-pack Check 43 tests (V11 leak-sweep prevention, project-side bare cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-43.sh
```

**Verification:** after the wiring lands, Check 42 (CI-workflow-wires-all-per-check-test-files) will PASS — the per-check test file `test-validate-pack-check-43.sh` exists on disk AND has a corresponding `bash scripts/tests/test-validate-pack-check-43.sh` invocation in the workflow.

### 1.12 Why this catches all 36 leaks (strategy §4.5 cross-walk)

| Leak class (audit + strategy) | Catch mechanism in Check 43 |
|---|---|
| 24 per-entry skeleton bare `ARCHITECTURE-*` cites | basename resolves to `maintenance-docs/v11-research/` or `maintenance-docs/v11-implementation/` → FAIL pack-internal target |
| 2 `scripts/lib/detect.sh` `maintenance-docs/` cites | scripts/lib/detect.sh in walked set per §1.2; line matches `maintenance-docs/` qualified ref → FAIL pack-internal target |
| 1 `PM-CHAT.md` `ARCHITECTURE-V3.3-DELTA.md` cite | basename resolves to `maintenance-docs/v11-research/` → FAIL pack-internal target (NOTE: PM-CHAT.md is whole-file exempt in Check 37 per `_is_legitimate_deny_list_doc()`; Check 43 does NOT inherit that exemption — Check 43's allowlist is BASENAME-keyed, not file-keyed) |
| 4 pm-startup cluster `ARCHITECTURE-V3.md §28.1.5` cites | basename resolves to `maintenance-docs/v11-research/ARCHITECTURE-V3.md` → FAIL pack-internal target |
| 3 pm-chat.md self-prompt `supporting-docs/SETUP*` cites | qualified-path-prefix detection; `supporting-docs/SETUP-NEW.md` (etc.) NOT in client-install set → FAIL pre-install-only |
| 1 `.mcp.json.example` `supporting-docs/CLI-PM-SETUP.md` cite | qualified-path detection; CLI-PM-SETUP.md NOT in client-install set → FAIL pre-install-only |
| 1 boundary-investigation `AUDIT-USER-CURATION.md` cite (BD-175 self-leak) | basename resolves to `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` → FAIL pack-internal target. **Catches only if line 124 is OUTSIDE the Guardrail 2 per-line fence.** Line 124 is instructional preamble about pack-root exemption — OUTSIDE deny-list-content fence (Guardrail 2 §2.3 places fence around enumeration block only). |

**All 36 leaks fail Check 43 under the contract above.** The BD-175 self-leak is doubly-guarded: Check 43 detects the bare `AUDIT-USER-CURATION.md` ref AND Guardrail 2's per-line fence stops the boundary-investigation skill from acquiring whole-file Check 37 exemption that would mask it.

---

## §2 Guardrail 2 — Per-line exemption fence (Check 37 modification)

**Gap closed (strategy §3.6 Gap 3-5 + §4.2):** Six files currently get whole-file exemption via `_is_legitimate_deny_list_doc()` (`boundary-investigation/SKILL.md`, `coder.md`, `reviewer.md`, project trinity ×3, PACK-FEEDBACK.md, PM-CHAT.md, METHODOLOGY.md, SETUP-EXISTING.md, INSTALL-PROCEDURES.md — 9 entries total in the current `legitimate` tuple at lines 4103-4132). The exemption is intentional for deny-list-pattern teaching content but creates a coverage hole: any pack-internal cite that creeps into an exempt file is invisible. The BD-175 self-leak proves the failure mode.

### 2.1 Fence marker syntax

```
<!-- DENY-LIST-CONTENT-START -->
... lines of intentional deny-list-pattern enumeration ...
<!-- DENY-LIST-CONTENT-END -->
```

**Design rationale:**
- HTML-comment form (`<!-- ... -->`) survives Markdown rendering invisibly (browsers don't show; pack-help readers don't see).
- Distinctive `START` / `END` suffix mirrors the `_CLIENT_INSTALLED_FILES_START` / `_END` convention already established (Check 41) — easy for future maintainers to recognize as "exactly-once paired marker."
- All-caps `DENY-LIST-CONTENT` is greppable and unambiguous.
- Pair forms one logical block; nesting is NOT supported (per §2.5 implementation contract).

**Filename uniqueness check:** `grep -rn "DENY-LIST-CONTENT" .` against the repo at HEAD finds zero matches — the marker is collision-free.

### 2.2 Marker placement in `boundary-investigation/SKILL.md`

Current file: 187 lines. Section structure (from §0.5 input read):

| Line range | Section | Content nature | Fence treatment |
|---|---|---|---|
| 1-5 | YAML frontmatter | metadata | OUTSIDE fence (no deny-list patterns by construction) |
| 7-21 | "# Boundary investigation" + "## When this skill applies" | Instructional prose (DOES name pack-only paths like `maintenance-docs/`, `pack-ops/`, etc. for "this skill applies to" / "does not apply" guidance) | OUTSIDE fence (instructional context) |
| 23-45 | "## Why this skill exists" | Instructional prose (names `Pack Chat`, `pack-architect`, `pack-coder`, `pack-ops/`, `maintenance-docs/`) | OUTSIDE fence (instructional context) |
| 47-92 | "## Methodology" Steps 1-3 | Instructional prose; SSOT table | OUTSIDE fence (instructional context) |
| 94-126 | "### Step 4 — NEVER cross-reference pack-only paths from project-side files" | **The deny-list enumeration itself** — file names, path prefixes, agent names, role names, files-exempt-at-pack-root | **INSIDE fence** |
| 128-141 | "### Step 5 — Document the investigation in the deliverable" | Instructional prose | OUTSIDE fence |
| 143-159 | "## Frame-rotation reminder" | Instructional (names pack-side paths in contrast pairs) | OUTSIDE fence |
| 161-187 | "## Worked example (BD-175 V1 anti-pattern)" | Instructional worked-example (names `PACK-AGENTS.md`, `docs/pack/PM-CHAT.md` in contrast) | OUTSIDE fence |

**Exact fence placement:**

- **Insert `<!-- DENY-LIST-CONTENT-START -->` between current line 97 and current line 98.** (After "The pack-only deny-list (not exhaustive; CI Check 37 enforces the canonical list):" and the blank line, BEFORE the bulleted list begins.) 
- **Insert `<!-- DENY-LIST-CONTENT-END -->` between current line 126 and current line 128.** (After the last bullet about `tracker.toml.pack-example` exemption, BEFORE the next blank line / next H3 "### Step 5".)

This wraps the enumeration block ONLY. Line 124 (`STAYS at pack root per AUDIT-USER-CURATION.md Override 1`) is INSIDE the fence — but this is the BD-175 self-leak, which the strategy says must be FIXED by the leak sweep (Category F) BEFORE Guardrail 2 lands. Once the line 124 cite is rewritten as prose ("STAYS at pack root per pack-repo audit finding; not installed at client"), the fenced content contains ONLY actual deny-list patterns (filenames + paths + agent names + role names + exemption notation), no pack-internal cites.

**Verification step (coder PREFLIGHT):** after placing fence markers, the coder runs `grep -nE "ARCHITECTURE-|AUDIT-|maintenance-docs/" project-template/skills/boundary-investigation/SKILL.md | grep -v "^<!--"` and confirms zero hits inside the fence range.

### 2.3 `_is_legitimate_deny_list_doc()` modification contract

**Current behavior (lines 4084-4133):** returns `True` if the file path matches one of 9 hardcoded entries. Whole-file exempt — no further line-level scrutiny.

**New behavior:** function REMOVED. Replaced by a new pair of helpers:

```python
def _has_per_line_fence(rel_path: Path) -> bool:
    """Return True if rel_path is on the per-line-fence allowlist
    (i.e., the file MAY contain deny-list patterns INSIDE the fence
    markers; outside the fence, normal Check 37 rules apply)."""
    return str(rel_path) in _CHECK_37_PER_LINE_FENCE_FILES


def _build_fence_skip_lineset(text: str) -> set[int]:
    """Parse the text for paired DENY-LIST-CONTENT-START / -END markers
    and return the set of 1-indexed line numbers INSIDE any fence (i.e.,
    lines between paired markers, exclusive of the marker lines
    themselves). Multiple non-overlapping fences supported; nested
    fences NOT supported (FAIL at validate-pack startup with clear
    diagnostic if nested markers detected)."""
    ...
```

And a new constant (UPDATED 2026-05-24 — expanded from 7 to 11 entries per H.12/H.13 reorder; see §3.3 for STOP-AND-ESCALATE evidence):

```python
_CHECK_37_PER_LINE_FENCE_FILES = (
    # Original 7 entries (project-template/ trinity + prompts + skill + PM-CHAT.md):
    "project-template/skills/boundary-investigation/SKILL.md",
    "project-template/docs/pack/PM-CHAT.md",
    "project-template/docs/pack/prompts/coder.md",
    "project-template/docs/pack/prompts/reviewer.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
    # 4 dual-surface additions (added 2026-05-24 per H.12/H.13 reorder):
    # These files have LEGITIMATE pack-internal references in functional
    # dual-surface code (scripts/) or pedagogical role-name content
    # (supporting-docs/) that the fence covers without breaking script
    # semantics or doc explanatory purpose. See ARCHITECTURE-V11-
    # GUARDRAILS-CONTRACT.md §3.3 (corrected Pre-sweep verification)
    # and IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md
    # for the 26-leak STOP-AND-ESCALATE evidence that drove this
    # expansion.
    "supporting-docs/METHODOLOGY.md",        # `Pack Chat` role-name pedagogy in client-installed doc (L119, L1561, L1579, L1585, L1587)
    "supporting-docs/INSTALL-PROCEDURES.md", # `Pack Chat` escalation refs in client-installed manual-procedures doc (L301, L609)
    "scripts/lib/detect.sh",                 # `pack-ops/` references in functional code comments (L23, L31, L43); script literally scans `$target/pack-ops/BACKLOG.md` when running in pack repo per BD-175 dual-surface design
    "scripts/pack-help.sh",                  # `HELP-FRAGMENT-PACK.md` + `pack-ops/` references in functional dual-surface code (L38-L169; 15 distinct lines); script branches on detected surface
)
```

(Note: PACK-FEEDBACK.md, SETUP-EXISTING.md from the current whole-file-exempt list are NOT in the per-line-fence list because their pack-internal vocabulary use is anchor-phrase-legitimate, NOT deny-list-enumeration — these continue to be handled by the anchor-phrase mechanism. The per-line fence covers files that LITERALLY enumerate the deny-list patterns OR carry legitimate dual-surface / pedagogical pack-internal references that cannot be removed without breaking the file's purpose. METHODOLOGY.md and INSTALL-PROCEDURES.md were added 2026-05-24 because their `Pack Chat` role-name pedagogical content + escalation references are LEGITIMATE — the docs teach the user about the pack-vs-client architecture, so naming `Pack Chat` is unavoidable; the fence covers these LEGITIMATE references without disrupting the rest of the file's Check 37 scan. detect.sh and pack-help.sh were added 2026-05-24 because their `pack-ops/` + `HELP-FRAGMENT-PACK.md` references are FUNCTIONAL dual-surface code that branches on detected surface — the references cannot be removed without breaking the script.)

**Fence-marker syntax in shell-script files** (`scripts/lib/detect.sh`, `scripts/pack-help.sh`): the HTML-comment fence syntax `<!-- DENY-LIST-CONTENT-START -->` works in shell scripts as ordinary comment text because validate-pack.py's `_build_fence_skip_lineset()` parser looks for exact marker strings at line level (not Markdown-context-aware). Coder uses the shell `#` comment form preceding the marker so the line is a valid shell comment AND a valid fence marker for the parser: `# <!-- DENY-LIST-CONTENT-START -->`. Per §2.5 invariant "each marker MUST be on its own line (no other text on the line)" — the leading `# ` is shell-comment prefix; the rest of the line is the exact marker string. Coder verifies the parser handles the `# ` prefix correctly (or proposes a parser-adjustment fix-coder commit if not). Per pack memory `Filename uniqueness heuristic`, the `# <!-- DENY-LIST-CONTENT-START -->` form is collision-free under `grep -rn "DENY-LIST-CONTENT" .` at HEAD.

**Modified `check_project_side_deny_list()` body:** in the per-file loop (current line 4173), replace:

```python
for rel_path in _iter_project_side_files():
    if _is_legitimate_deny_list_doc(rel_path):
        continue
    ...
```

with:

```python
for rel_path in _iter_client_installed_files():  # Guardrail 3 expansion
    full_path = REPO_ROOT / rel_path
    try:
        text = full_path.read_text()
    except (UnicodeDecodeError, OSError):
        continue
    files_walked += 1
    lines = text.splitlines()
    
    # Guardrail 2: per-line fence skip-set for fence-allowlisted files.
    if _has_per_line_fence(rel_path):
        fence_skip = _build_fence_skip_lineset(text)
    else:
        fence_skip = set()  # no fence support outside the allowlist
    
    for lineno, line in enumerate(lines, start=1):
        if lineno in fence_skip:
            continue  # inside fence — exempt
        # ... existing per-line deny-list scan ...
```

**Behavioral change summary:**
- Files NOT in `_CHECK_37_PER_LINE_FENCE_FILES`: scanned in full (no change for the majority of project-side files).
- Files in `_CHECK_37_PER_LINE_FENCE_FILES`: scanned for deny-list patterns OUTSIDE fence markers; fence markers themselves are content lines (skipped by the marker-line skip in `_build_fence_skip_lineset`); INSIDE fences = exempt as before.

### 2.4 Affected files — fence placement plan

Pre-leak-sweep, only `boundary-investigation/SKILL.md` actually contains a deny-list-enumeration block (Step 4). The other 6 ORIGINAL fence files in `_CHECK_37_PER_LINE_FENCE_FILES` reference pack-only patterns in instructional prose, NOT in enumeration blocks. **The 4 dual-surface files added 2026-05-24 (per H.12/H.13 reorder)** carry legitimate pack-internal references in functional dual-surface code (`scripts/`) or pedagogical role-name content (`supporting-docs/`) — these are FUNCTIONAL/PEDAGOGICAL legitimate uses, NOT enumeration teaching. Per the strategy doc + 2026-05-24 reorder, the placement plan is:

| File | Current behavior | New fence placement | Why |
|---|---|---|---|
| `project-template/skills/boundary-investigation/SKILL.md` | Whole-file exempt (deny-list teaching) | Fence around Step 4 enumeration (current lines 98-126; final line numbers shift after the Category F edit at line 124) | The enumeration IS the deny-list; instructional prose around it must still be scanned |
| `project-template/docs/pack/prompts/coder.md` | Whole-file exempt | Fence around the deny-list block in current lines 83-89 (the bracketed "(the AI Agent Config Pack repo's `PACK-AGENTS.md`, ...)" enumeration) AND lines 195-202 (same enumeration in the fix-cycle variant) | Same rationale; coder.md teaches the deny-list in its boundary-discipline-stop instruction block |
| `project-template/docs/pack/prompts/reviewer.md` | Whole-file exempt | Fence around the deny-list block in current lines 102-107 | Same rationale |
| `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | Whole-file exempt | Fence around the deny-list enumeration in the `## Project memory` § "Project SSOT-first" bullet — currently a single multi-line bullet listing pack-only files. Fence placement: open immediately before the first `"(PACK-AGENTS.md,`" mention; close immediately after the `"etc.)"` close-paren | The bullet IS a deny-list enumeration; surrounding bullet text is instructional |
| `project-template/docs/pack/PM-CHAT.md` | Whole-file exempt | Empty fence pair (per §2.5 invariant) at a defensible location; or fence around any enumeration block coder identifies at HEAD | PM-CHAT.md is in `_CHECK_37_PER_LINE_FENCE_FILES` for invariant compliance; if no enumeration block exists, place empty fence |
| **`supporting-docs/METHODOLOGY.md`** (NEW 2026-05-24) | Was anchor-phrase-legitimate (no whole-file exempt); now fence-allowlisted | Fence around the legitimate `Pack Chat` role-name pedagogical references (sites at L119 + L1561 + L1579 + L1585 + L1587 per `grep -nE "Pack Chat" supporting-docs/METHODOLOGY.md`). Multiple non-overlapping fences supported per §2.5 — coder identifies the smallest contiguous block(s) around each LEGITIMATE reference. | The METHODOLOGY doc teaches the user about pack-vs-client architecture, so naming `Pack Chat` is unavoidable; the fence covers these LEGITIMATE references without disrupting the rest of the file's Check 37 scan. Without the fence, H.12 scope expansion would surface 5 false-positive Check 37 fails. |
| **`supporting-docs/INSTALL-PROCEDURES.md`** (NEW 2026-05-24) | Was anchor-phrase-legitimate; now fence-allowlisted | Fence around the legitimate `Pack Chat` escalation references at L301 + L609 per `grep -nE "Pack Chat" supporting-docs/INSTALL-PROCEDURES.md`. Two non-overlapping fences (or a single fence covering both lines if they're close enough). | INSTALL-PROCEDURES.md teaches the user to escalate to Pack Chat when manual procedures encounter blockers — pedagogical content that must reference `Pack Chat`. Without the fence, H.12 scope expansion would surface 2 false-positive Check 37 fails. |
| **`scripts/lib/detect.sh`** (NEW 2026-05-24) | Out-of-Check-37-scope pre-Guardrail-3; now fence-allowlisted | Fence around `pack-ops/` references in functional code comments at L23, L31, L43. Use shell-comment fence syntax: `# <!-- DENY-LIST-CONTENT-START -->` / `# <!-- DENY-LIST-CONTENT-END -->`. | detect.sh literally needs to scan `$target/pack-ops/BACKLOG.md` when running in the pack repo per BD-175 dual-surface design; the `pack-ops/` references are FUNCTIONAL code that branches on detected surface. Without the fence, H.12 scope expansion would surface 3 false-positive Check 37 fails. |
| **`scripts/pack-help.sh`** (NEW 2026-05-24) | Out-of-Check-37-scope pre-Guardrail-3; now fence-allowlisted | Fence around `HELP-FRAGMENT-PACK.md` + `pack-ops/` references in functional dual-surface code at L38 + L39 + L86 + L87 + L92 + L106 + L112 + L113 + L114 + L115 + L119 + L120 + L133 + L136 + L153 + L169 (15 distinct lines). Coder identifies the smallest contiguous blocks (multiple non-overlapping fences supported); use shell-comment fence syntax. | pack-help.sh runs both in pack repo where `pack-ops/` exists AND in client repos where it doesn't, and the script branches accordingly; the `pack-ops/` and `HELP-FRAGMENT-PACK.md` references cannot be removed without breaking the script. Without the fence, H.12 scope expansion would surface 22 false-positive Check 37 fails (15 distinct lines × ~1.5 hits each). |

**Pre-fence-placement edits** (Category F + Category C remediations land BEFORE Guardrail 2 fence placement in commit order — see §5.1): once those land, every line inside every planned fence range is verifiably a deny-list pattern OR a LEGITIMATE pack-internal reference (functional dual-surface code / pedagogical role-name explanation), not an unintended pack-internal cite. Guardrail 2 then ratifies the cleaned state and prevents regression.

**Shell-script fence-marker syntax** (`scripts/lib/detect.sh`, `scripts/pack-help.sh`): per §2.3 note, use `# <!-- DENY-LIST-CONTENT-START -->` form so the line is a valid shell comment AND a valid fence marker for the parser. Coder verifies the parser handles the `# ` prefix correctly (or proposes a parser-adjustment fix-coder commit if not).

### 2.5 Fence-marker syntax invariants

| Invariant | Rationale |
|---|---|
| START + END markers are exact strings `<!-- DENY-LIST-CONTENT-START -->` and `<!-- DENY-LIST-CONTENT-END -->` | Greppability + invisibility in rendered markdown |
| Each marker MUST be on its own line (no other text on the line) | Simpler parser; consistent with existing `_CLIENT_INSTALLED_FILES_START`/`_END` convention |
| Pairs MUST be balanced (every START followed by a matching END before next START) | No nesting; validate-pack startup FAILs with clear diagnostic on imbalance |
| Fence range is EXCLUSIVE of the marker lines themselves (markers are content lines, scanned by Check 37 — they will not match any deny-list pattern by construction) | Simpler skip-set; markers cannot accidentally mask themselves |
| At least one START + END pair per fence-allowlisted file at HEAD | Avoid silent regression where a fence-allowlisted file drops its fence and silently becomes scanned-but-whole-file-exempt-removed |
| Empty fence (START immediately followed by END) is permitted | Future-proof; a file may temporarily have no deny-list-enumeration but be on the allowlist for future use |

**Validation in `_build_fence_skip_lineset()`:** if START count != END count, or END appears before matching START, return a SENTINEL value (e.g., `None`) and the caller emits a CHECK 37 fail with "fence-marker imbalance in <file>: <diagnostic>".

### 2.6 Fixture-test extension — `scripts/tests/test-validate-pack-checks-36-37-38.sh`

Add a new Group 6 (after the existing Group 5 at line 289):

```
# Group 6: Per-line fence (Guardrail 2)
```

Test cases:

| Test ID | Synthetic input | Expected |
|---|---|---|
| G6.T1 | File NOT on fence-allowlist, contains `PACK-AGENTS.md` | FAIL (Check 37 normal path; no fence support) |
| G6.T2 | File ON fence-allowlist, contains `PACK-AGENTS.md` INSIDE fence | PASS (fence exempt) |
| G6.T3 | File ON fence-allowlist, contains `PACK-AGENTS.md` OUTSIDE fence | FAIL (Check 37 scans outside-fence lines normally) |
| G6.T4 | File ON fence-allowlist, START marker without matching END | FAIL ("fence-marker imbalance") |
| G6.T5 | File ON fence-allowlist, END marker without matching START | FAIL ("fence-marker imbalance") |
| G6.T6 | File ON fence-allowlist, multiple non-overlapping fences | PASS (lines inside any fence are exempt) |
| G6.T7 | File ON fence-allowlist, empty fence (START immediately followed by END) | PASS (no error; permitted) |
| G6.T8 | File ON fence-allowlist, `AUDIT-USER-CURATION.md` ref OUTSIDE fence (BD-175 self-leak class) | FAIL (Check 37 outside-fence scan catches it) |

**Total: 8 new fixture-test cases for Guardrail 2.**

---

## §3 Guardrail 3 — `_PROJECT_SIDE_ROOTS` expansion (Check 37 scope extension)

**Gap closed (strategy §3.6 Gap 2 + §4.3):** `_PROJECT_SIDE_ROOTS = ("project-template",)` at line 3762 — Check 37 walks only `project-template/`. The 2 leaks in `scripts/lib/detect.sh` (installed verbatim per `init-project.sh:894-895`) are invisible to Check 37 because `scripts/` is not in `_PROJECT_SIDE_ROOTS`. The source of truth for "what reaches clients" is already maintained for Check 41 via `_CLIENT_INSTALLED_FILES_START`/`_END` and `_parse_client_installed_files()`.

### 3.1 New helper — `_iter_client_installed_files()`

```python
def _iter_client_installed_files() -> list[Path]:
    """Return the union of:
      (a) all regular files under project-template/ (recursive), and
      (b) the explicit non-project-template files in _CLIENT_INSTALLED_FILES.
    
    This replaces _PROJECT_SIDE_ROOTS-based walks for Checks 37 + 43.
    The source-of-truth for (b) is _CLIENT_INSTALLED_FILES_START/_END
    in scripts/init-project.sh, parsed via Check 41's
    _parse_client_installed_files() helper.
    
    Returns repo-relative Path objects, sorted, deduplicated. Skips
    binary files (deferred to caller via UnicodeDecodeError handling).
    """
    out: list[Path] = []
    # (a) project-template/ recursive walk (existing behavior).
    root = REPO_ROOT / "project-template"
    if root.is_dir():
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            out.append(path.relative_to(REPO_ROOT))
    # (b) explicit non-project-template entries from _CLIENT_INSTALLED_FILES.
    entries, _, _, _, _ = _parse_client_installed_files()
    for entry in entries:
        if entry.startswith("project-template/"):
            continue  # already covered by (a)
        full = REPO_ROOT / entry
        if full.is_file():
            rel = full.relative_to(REPO_ROOT)
            if rel not in out:  # dedup defensive (project-template/ first)
                out.append(rel)
    return out
```

**Why parse `_CLIENT_INSTALLED_FILES` rather than hardcode `scripts/lib/detect.sh`, `scripts/pack-help.sh`, etc.:** the inventory is the source of truth (Check 41 enforces its accuracy). Hardcoding would create drift; reusing the parsed inventory ensures any future addition to `_CLIENT_INSTALLED_FILES` automatically appears in Check 37 + Check 43 scope.

### 3.2 Replacement of `_PROJECT_SIDE_ROOTS`

**Before** (line 3762):
```python
_PROJECT_SIDE_ROOTS = ("project-template",)
```

**After:**
```python
# `_PROJECT_SIDE_ROOTS` is REPLACED by `_iter_client_installed_files()`.
# See ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §3 for the contract.
# Reason: the previous constant restricted Check 37 to project-template/
# only, missing scripts/lib/detect.sh (installed verbatim per
# init-project.sh:894-895) and the other 4 client-installed files in
# pack-ops/ + supporting-docs/ + scripts/. The new helper parses the
# authoritative _CLIENT_INSTALLED_FILES inventory and walks the full
# client-installed surface.
```

**Callers to update:**
- Line 4064 (inside `_iter_project_side_files`): replace `for root_name in _PROJECT_SIDE_ROOTS` + body with a call into `_iter_client_installed_files()`. Decision: KEEP `_iter_project_side_files()` as a thin alias that calls `_iter_client_installed_files()` so Check 37's call site at line 4173 does not need to change (less diff churn). The alias is documented as deprecated; future cleanup may inline.
- Line 4173 (`check_project_side_deny_list`): no change (uses `_iter_project_side_files()` which now delegates).

**`_PROJECT_SIDE_PATH_PREFIXES` is UNCHANGED.** This constant (line 3766) is used by `_is_pack_only_path()` and `_is_project_side_path()` for COMMIT SCOPE CLASSIFICATION (Check 36). Commit-scope-honesty has a different question than file-walk: a commit that touches `scripts/lib/detect.sh` is still pack-only-scoped (the file lives at the pack repo). Conflating "where does this file get installed?" with "what scope keyword does the touching commit need?" is wrong. Keep them separate.

### 3.3 Backward compatibility audit

| Existing caller | Effect of change |
|---|---|
| `_iter_project_side_files()` itself | Body rewrites to delegate; behavior preserved + extended |
| `check_project_side_deny_list()` line 4173 | Walks ~5 more files than before (the explicit client-installed non-project-template/ files); at HEAD, the 5 extras are: `pack-ops/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/pack-help.sh`, `scripts/lib/detect.sh` |
| `_PROJECT_SIDE_ROOTS` direct reads | NONE outside the line 4064 caller — confirmed by grep at §0.5 input read |
| `_PROJECT_SIDE_PATH_PREFIXES` direct reads | UNCHANGED — keeps current behavior |

**Pre-sweep PASS verification (CORRECTED 2026-05-24 per STOP-AND-ESCALATE evidence):**

The original (pre-2026-05-24) wording of this paragraph claimed: "running Check 37 with the expanded scope at HEAD (pre-sweep) will FAIL on the 2 detect.sh leaks (which qualified `maintenance-docs/` prefix already triggers Check 37's path-prefix detection) ... detect.sh failures must be FIXED (Category D sweep) BEFORE Guardrail 3 commit lands."

That wording was **factually wrong at HEAD**. Per the 2026-05-24 STOP-AND-ESCALATE evidence (see `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md`), running Check 37 with the expanded scope at HEAD post-H.10 (`6e2d406`) FAILS on **26 leaks**, not 2:

| File | Leak count | Pattern type | Architect-anticipated (pre-2026-05-24)? |
|---|---|---|---|
| `supporting-docs/METHODOLOGY.md` | 5 | `Pack Chat` capitalized role-name (L119, L1561, L1579, L1585, L1587) | NO |
| `supporting-docs/INSTALL-PROCEDURES.md` | 2 | `Pack Chat` escalation references (L301, L609) | NO |
| `scripts/pack-help.sh` | 22 (15 distinct lines × ~1.5 hits each) | `HELP-FRAGMENT-PACK.md` + `pack-ops/` path-prefix in functional dual-surface code | NO |
| `scripts/lib/detect.sh` | 3 | `pack-ops/` path-prefix in functional code comments (L23, L31, L43) | NO |

**These 26 leaks are NOT contamination — they are LEGITIMATE pack-internal references** in (a) pedagogical client-installed docs that teach the user about pack-vs-client architecture (`Pack Chat` is unavoidable when explaining the role), or (b) functional dual-surface scripts that branch on detected surface (the `pack-ops/` references are required for the script to work in the pack repo).

**Corrected ordering contract:** leak sweep (Guardrail 3 / H.10 — clears the architect-anticipated 2 detect.sh `maintenance-docs/` leaks) **AND per-line fence (Guardrail 2 / H.13 — covers the 4 dual-surface files: METHODOLOGY.md, INSTALL-PROCEDURES.md, detect.sh, pack-help.sh)** MUST BOTH be applied BEFORE scope expansion (Guardrail 3 / H.12) ratifies the cleaned state. The 4 dual-surface files carry LEGITIMATE pack-internal references that the fence wraps; the scope expansion otherwise produces 26 false-positive Check 37 fails.

**Reordered commit sequence (2026-05-24 reorder per Pack Chat user direction B2):**
1. H.10 (Cat D detect.sh fixes — clears the 2 anticipated `maintenance-docs/` leaks)
2. H.11 (Cat C pm-chat variant rewrites — clears the 3 pre-install supporting-docs/ template leaks)
3. **H.13 (per-line fence — covers 11 files: 7 original + 4 dual-surface additions)** — lands BEFORE H.12
4. **H.12 (scope expansion — ratifies the now-cleaned state)** — lands AFTER H.13
5. H.14 (Check 43 — new check; INLINE reviewer sliding-window covers H.12+H.14)
6. H.15+ (PREFLIGHT extension + remaining commits)

The PLAN H.N names are PRESERVED (per Pack Chat user direction B2 — existing H.13 references in committed BD-190 entry and 6 references in this doc would break under renumbering). Commit log will show "Batch 19c.13" landing BEFORE "Batch 19c.12" — intentional per the reorder.

**Updated "self-validating change" principle:** validate-pack.py PASSES at every commit head in the reordered sequence. H.13's expanded fence + H.10's leak sweep together guarantee H.12's scope-expansion ratifies the cleaned state without producing FAILs. Without the fence expansion (the pre-2026-05-24 understanding), H.12 alone could not land — confirmed by the STOP-AND-ESCALATE.

**Cross-reference:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md` documents the 26-leak inventory, Pack Chat triage, user direction (Option B + B2), and the corrected doc-revision chain (this paragraph + §2.3 fence-files enumeration + §5.1 commit-order text + PLAN §H.12 + §H.13 + V2 §H.12 + §H.13).

### 3.4 Fixture-test extension — `scripts/tests/test-validate-pack-checks-36-37-38.sh`

Add a new Group 7 (after Group 6 from Guardrail 2):

```
# Group 7: Check 37 scope expansion (Guardrail 3)
```

Test cases:

| Test ID | Synthetic input | Expected |
|---|---|---|
| G7.T1 | Synthetic tree with `scripts/lib/detect.sh` containing comment `# maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md:` | Check 37 walks the file; FAIL on the `maintenance-docs/` path-prefix match |
| G7.T2 | Synthetic tree with `supporting-docs/METHODOLOGY.md` (in `_CLIENT_INSTALLED_FILES`) containing legitimate `Pack Chat` anchor-phrase reference | PASS (anchor-phrase exempt, same as today) |
| G7.T3 | `_iter_client_installed_files()` returns 5 explicit non-project-template entries plus all project-template/ files | PASS (count check) |
| G7.T4 | `_iter_client_installed_files()` deduplicates a project-template/ entry that also appears as `_CLIENT_INSTALLED_FILES` entry (e.g., HELP-FRAGMENT-TRACKER.md — pack-ops/ source + project-template/ source) | PASS (no duplicate Path objects in returned list) |

**Total: 4 new fixture-test cases for Guardrail 3.**

---

## §4 Guardrail 4 — PREFLIGHT extension (pre-commit defense-in-depth)

**Gap closed (strategy §3.8 + §4.4):** No process step forces an actor to scan for "new bare-filename cite not in the deny-list" at commit time. The pack-coder PREFLIGHT line currently verifies file-edit completion + tests-pass. Check 43 catches at CI/PR time; extending PREFLIGHT to also require Check 43 PASS pulls the catch left to before-IMPL-REPORT, saving the CI round-trip.

### 4.1 PACK-AGENTS.md PREFLIGHT spec edit

**Current spec** (PACK-AGENTS.md lines 190-211):

```
- **Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation.** Every pack-coder
  (or coder-style fix-coder) agent has two non-negotiable behavioral
  obligations:

  - **PREFLIGHT line BEFORE IMPL-REPORT.** After all in-scope edits +
    verification, emit a single plain-text line of the form `PREFLIGHT:
    N/N in-scope file edits complete; verification PASS; HEAD <SHA>;
    about to Write IMPL-REPORT to <path>` before any IMPL-REPORT write.
    This is the orchestrator's trust signal that the report-write
    starts from complete-and-green state.

  - **STOP-MEANS-STOP on parent stop directives.** ...
```

**New spec** (modification to the PREFLIGHT sub-bullet):

Insert AFTER the existing PREFLIGHT line description, BEFORE the STOP-MEANS-STOP sub-bullet (between current lines 199 and 201):

```
    Verification includes BOTH the in-scope test suite for the BD AND
    Check 43 (V11 leak-sweep prevention; pack/project boundary scanner).
    When a pack-coder commit touches any file under project-template/,
    pack-ops/, supporting-docs/, or scripts/, the coder MUST run
    `python3 scripts/validate-pack.py` against the working tree before
    writing the PREFLIGHT line; Check 43 (and the rest of the validate-
    pack suite) MUST PASS. If Check 43 FAILs, the coder reports the
    failure (with file:line + matched basename + suggested remediation)
    INSTEAD OF writing the IMPL-REPORT — Pack Chat reviews and decides
    whether to fix in this commit or escalate.
```

**Insertion point cite:** `pack-ops/PACK-AGENTS.md` line 200 (after "starts from complete-and-green state.") — pin the insertion to surrounding text, NOT to line numbers (per pack memory `feedback_filename_uniqueness` line-number-drift principle):

> *Anchor:* AFTER `"complete-and-green state."` AND BEFORE the next `- ` (the STOP-MEANS-STOP bullet).

### 4.2 CONCEPTUAL-REVIEW-METHODOLOGY.md reviewer dimension extension

**Target dimension:** dimension `(d) Pack rule adherence` (line 37-38).

**Current text:**

```
### (d) Pack rule adherence
Does the implementation violate any strategic or tactical established pack rule? Reference: `CLAUDE.md`, `PACK-CHAT.md`, pack memory `MEMORY.md` index + linked feedback files, `ARCHITECTURE-V*.md` family. Cite the rule by file + section/line for every finding.
```

**New text** (append a new sentence, do NOT modify the existing text):

```
### (d) Pack rule adherence
Does the implementation violate any strategic or tactical established pack rule? Reference: `CLAUDE.md`, `PACK-CHAT.md`, pack memory `MEMORY.md` index + linked feedback files, `ARCHITECTURE-V*.md` family. Cite the rule by file + section/line for every finding. Boundary-discipline note: when reviewing changes that touch project-side surfaces (any file under `project-template/`, `pack-ops/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/pack-help.sh`, or `scripts/lib/detect.sh`), the reviewer MUST verify Check 43 (`scripts/validate-pack.py check_project_side_bare_internal_refs`) passes against the working tree; any new bare cross-reference to pack-internal targets (`maintenance-docs/`, pack-only `pack-ops/`, pre-install `supporting-docs/`) is a boundary leak per `maintenance-docs/v11-implementation/ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` §4.1. Flag as a (d) finding with file:line + matched basename.
```

**Alternative placement consideration:** also add to "Pack rules to reference (for dimension d)" list at lines 173-203, under "From `CLAUDE.md` (pack-repo workflow):", append:

```
- Project-side boundary discipline (Check 43; per ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md §4.1)
```

Both edits ship in the same commit (single-doc trinity-equivalent surface; methodology doc has no per-CLI trinity).

### 4.3 Memory cache update

**File:** `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_pack_coder_preflight_pattern.md`

This file lives outside the repo (user-local). The architect cannot edit it. Pack Chat applies the update.

**Update text (Pack Chat applies — append a new bullet to the "Coverage" or equivalent section):**

```
- **Check 43 boundary-discipline verification (V11 leak-sweep prevention).**
  When the pack-coder commit touches any file under `project-template/`,
  `pack-ops/`, `supporting-docs/`, or `scripts/`, the coder MUST run
  `python3 scripts/validate-pack.py` against the working tree before
  emitting the PREFLIGHT line. Check 43 (project-side bare-internal-ref
  scanner) MUST PASS. If Check 43 FAILs on a new leak the coder
  introduced, the coder reports the file:line + matched basename +
  suggested remediation INSTEAD OF writing the IMPL-REPORT — Pack Chat
  triages whether to fix-in-commit or escalate. The orchestrator (this
  memory file's owner) treats PREFLIGHT-with-Check-43-PASS as the
  trust signal that the report-write starts from boundary-clean state.
  See pack-ops/PACK-AGENTS.md § "Pack-coder PREFLIGHT + STOP-MEANS-STOP
  obligation" for the load-bearing spec; this memory file is the
  Tier-1.5 pointer index.
```

### 4.4 Trinity rule application

PACK-AGENTS.md is a SINGLE OPERATING DOC (lives at `pack-ops/PACK-AGENTS.md`, no per-CLI trinity). The PREFLIGHT spec is platform-neutral content per pack memory `feedback_pack_coder_preflight_pattern` and per the pack-root trinity `## Pack memory` § "Agent invocation rules" "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" bullet.

**Cross-trinity application for the same content:** the pack-root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) contains the authoritative full text of the PREFLIGHT spec (per PACK-AGENTS.md line 208-211 cite). This trinity location ALSO needs the same Check 43 addition.

**Trinity edit (parallel to §4.1):** read the PREFLIGHT bullet under `## Pack memory` → `### Agent invocation rules` → "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" in each of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root, and append the Check 43 verification step to the PREFLIGHT sub-bullet. Trinity parity rule applies (per CLAUDE.md `## Rules for agents working on this repo` "Trinity rule"): same content in all three files in the same commit, modulo provably-tool-specific exceptions. PREFLIGHT is platform-neutral content; same text in all three.

CONCEPTUAL-REVIEW-METHODOLOGY.md is a single doc (no trinity); the §4.2 edit is one place.

**Commit scope:** PM-only (per CLAUDE.md `## Rules for agents working on this repo` PM-only file list — `pack-ops/PACK-AGENTS.md` and pack-root trinity are PM-only). This is a Pack-Chat-direct edit per the "What Pack Chat CAN edit directly" rule in `## Pack memory` § "Pack Chat scope". The keyword on the commit subject MUST be `PM-only` per CI Check 36.

**CONCEPTUAL-REVIEW-METHODOLOGY.md is also in pack-ops/** — single edit, PM-only-eligible.

---

## §5 Cross-cutting integration

### 5.1 Implementation order (commit sequence)

**Cross-walk note (added 2026-05-23):** the H.9.1 / H.9.2 / H.9.3 / H.9.4 numbering used throughout §5 reflects the strategy doc's original commit-sequence proposal. V2 §H reassigned these to:
- H.9.1 → H.12 (Guardrail 3 scope expansion)
- H.9.2 → H.13 (Guardrail 2 per-line fence)
- H.9.3 → H.14 (Guardrail 1 Check 43)
- H.9.4 → H.15 (Guardrail 4 PREFLIGHT extension)

PLAN-CLEANUP-BATCH-19C.md §3 follows V2 §H numbering. Coders consuming PLAN H.12-H.15 should mentally remap when reading this contract's §5 internal commit labels.

Per the strategy doc §2.4 Option (b) commit-numbering (H.9 = leak sweep Categories A+B, H.10 = D+E+F, H.11 = Category C, H.12 = end-of-batch reviewer), the guardrail additions slot in AFTER the leak-sweep commits as defense-in-depth ratification:

| Commit | Surface | Scope keyword | RC9 fires? |
|---|---|---|---|
| **H.9** | Category A+B leak sweep (per-entry skeleton sweep) | `project-only` | YES (project-template/) |
| **H.10** | Category D+E+F leak sweep (detect.sh + pm-startup + boundary-investigation cite) | mixed (no keyword) | YES (scripts/ + project-template/) |
| **H.11** | Category C pm-chat variant rewrites (C-c decision) | `project-only` | YES (project-template/) |
| **H.9.2** = post-H.11 = PLAN H.13 (lands FIRST per 2026-05-24 reorder) | **Guardrail 2 implementation** (validate-pack.py changes + fence markers in **11 files** — expanded from 7 per 2026-05-24 reorder; +4 dual-surface files) | mixed | YES (project-template/ + scripts/ + supporting-docs/) |
| **H.9.1** = post-H.13 = PLAN H.12 (lands AFTER per 2026-05-24 reorder) | **Guardrail 3 implementation** (validate-pack.py + fixture-test extension) | `pack-only` | YES (scripts/ in trigger set per pack memory `feedback_manifest_regen_on_v11_surface`) |
| **H.9.3** = PLAN H.14 | **Guardrail 1 implementation** (Check 43 + fixture-test + CI wiring) | mixed | YES (scripts/ + .github/workflows/) — note .github/workflows/ is NOT in the RC9 trigger set; only the scripts/ change triggers RC9 |
| **H.9.4** = PLAN H.15 | **Guardrail 4 implementation** (PACK-AGENTS.md + trinity + CONCEPTUAL-REVIEW-METHODOLOGY.md + memory cache) | `PM-only` | YES (pack-ops/ in trigger set per BD-176 expansion) |
| **H.12** = PLAN H.17 | End-of-batch reviewer | (review pass; not a commit) | N/A |

**Sequence rationale (UPDATED 2026-05-24 for H.12/H.13 reorder):**
- **Leak sweep first (H.9-H.11):** the sweep clears the existing leaks the architect originally anticipated (2 detect.sh `maintenance-docs/` leaks + Cat E pm-startup cluster + Cat F boundary-investigation cite + Cat C pre-install supporting-docs/ template refs). Without the sweep, Guardrails 1+2+3 would FAIL at HEAD and block validate-pack.py from passing.
- **Guardrail 2 second (PLAN H.13; lands FIRST per 2026-05-24 reorder):** per-line fence requires the deny-list-content lines to be CLEAN of pack-internal cites (Category F edit at boundary-investigation/SKILL.md:124 must land first — that's part of H.10). Fence placement ratifies the cleaned state. Per 2026-05-24 STOP-AND-ESCALATE evidence (see §3.3 corrected verification + `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md`), the fence files list was expanded from 7 to 11 to cover 4 dual-surface files (`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/lib/detect.sh`, `scripts/pack-help.sh`) — these carry LEGITIMATE pack-internal references that the scope expansion (PLAN H.12) would otherwise surface as 26 false-positive Check 37 fails.
- **Guardrail 3 third (PLAN H.12; lands AFTER PLAN H.13 per 2026-05-24 reorder):** scope expansion ratifies the now-cleaned + fence-covered state. Touches only `scripts/validate-pack.py` and the Check 36-37-38 fixture-test; no behavioral change to project-side files. The reorder is the architectural correction to the pre-2026-05-24 ordering claim that Guardrail 3 could land before Guardrail 2 — the 26-leak STOP-AND-ESCALATE proved that wrong. Per Pack Chat user direction B2: PLAN H.N names PRESERVED (existing H.13 references in committed BD-190 entry and 6 references in this doc would break under renumbering); commit log will show "Batch 19c.13" landing BEFORE "Batch 19c.12" — intentional per the reorder.
- **Guardrail 1 fourth (PLAN H.14):** Check 43 reuses Guardrail 3's `_iter_client_installed_files()` helper (so Check 43 lands AFTER Guardrail 3 / PLAN H.12). Independent of Guardrail 2's fence placement at the function level (Check 43 has its own allowlist; Check 37's per-line fence is separate). Lands last among code changes because it's the largest single addition.
- **Guardrail 4 last (PLAN H.15):** doc-only, PM-only, no CI impact. Lands AFTER Guardrail 1 (Check 43 exists for PREFLIGHT to invoke).

**Alternative order considered and rejected:** "land Guardrails first, then sweep" — REJECTED because validate-pack.py would FAIL at HEAD after the guardrail commits, blocking the sweep commits behind a red CI gate. The sweep clears the existing leaks so validate-pack.py PASSES at every commit head.

**Alternative order considered 2026-05-24 (rejected per user direction):** Option A (extend whole-file `_is_legitimate_deny_list_doc()` exemption to cover 4 dual-surface files, keep original H.12 → H.13 → H.14 order) was REJECTED because it moves architectural direction AWAY from per-line fence (which the BD-175 / BD-179 framework was designed around) and TOWARD whole-file exemption (which the per-line fence framework was designed to reduce). User direction was Option B: re-order PLAN H.12 / H.13 so the per-line fence (with expanded 11-file scope) lands BEFORE the scope expansion ratifies the cleaned state. Option C (insert a new Cat G commit between H.11 and H.12) was procedurally honest but architecturally identical to Option A.

### 5.2 RC9 manifest regeneration

Per pack memory `feedback_manifest_regen_on_v11_surface` and CLAUDE.md `## Pack memory` § "Repo conventions" "Regenerate test-fixtures/manifest.txt on every v11-surface commit" rule, every commit whose diff includes a file under `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/` MUST regenerate `test-fixtures/manifest.txt` and stage it alongside the scope edits in the SAME commit.

| Commit | RC9 trigger | Action |
|---|---|---|
| H.9.1 (Guardrail 3) | YES (scripts/validate-pack.py + scripts/tests/) | Run `bash test-fixtures/build.sh --all --clean`; stage `test-fixtures/manifest.txt` |
| H.9.2 (Guardrail 2) | YES (project-template/ fence markers + scripts/validate-pack.py) | Run `bash test-fixtures/build.sh --all --clean`; stage |
| H.9.3 (Guardrail 1) | YES (scripts/validate-pack.py + scripts/tests/) | Run `bash test-fixtures/build.sh --all --clean`; stage |
| H.9.4 (Guardrail 4) | YES (pack-ops/ + pack-root trinity per BD-176 expansion) | Run `bash test-fixtures/build.sh --all --clean`; stage manifest if it changes (likely no change — pack-ops/PACK-AGENTS.md is not fixture-affecting at HEAD, but the rule's directory-wide trigger requires the rebuild as defense against future copy-site additions) |

For each commit, the coder PREFLIGHT line verification step includes the manifest-staging check. Pack Chat verifies before commit.

### 5.3 Self-validation contract per commit

Each commit MUST satisfy:

1. `python3 scripts/validate-pack.py` exits 0 (all checks PASS, including the newly-added Check 43 in H.9.3 and after).
2. `bash scripts/tests/test-validate-pack-check-*.sh` for every changed test file exits 0.
3. `git diff test-fixtures/manifest.txt` after `bash test-fixtures/build.sh --all --clean` is empty OR the manifest is staged in the same commit.
4. The commit subject correctly uses a scope keyword (`pack-only`, `project-only`, `PM-only`, or no keyword for mixed scope) per CI Check 36.

### 5.4 Failure-mode considerations

**What if a guardrail commit FAILs CI?** Per the per-commit-cycle pattern (pack memory `feedback_review_fix_one_cycle`), a fix-coder commit lands in the same batch to clear the failure. The end-of-batch reviewer (H.12) sees the full batch, including any fix-coder cycles.

**What if Guardrail 3's scope expansion surfaces a new leak not in the audit?** Audit was a static scan against HEAD `9da98a44`; if any post-audit commits (BD-179 etc.) introduced new leaks, Guardrail 3 will surface them. Triage per the same rules: fix-in-commit if mechanical, surface to user if structural. Per pack memory `feedback_deferral_is_scope_creep`, defer requires size/blocked/fit defense.

**What if a future maintainer adds a file to `_CLIENT_INSTALLED_FILES` without updating `_CHECK_43_ALLOWLIST`?** Check 43 will FAIL for any project-side reference to the new file's basename (treating it as unresolved or pack-internal). The fix is to add the basename + rationale to `_CHECK_43_ALLOWLIST`. The allowlist's self-documenting rationale convention (per Check 40 §6.5) catches this at PR time.

---

## §6 Verification checklist (for the coder applying this contract)

| Item | Pass condition |
|---|---|
| Guardrail 3 helper exists | `_iter_client_installed_files()` defined in scripts/validate-pack.py, returns a list of Path objects sorted + deduped |
| Guardrail 3 replaces _PROJECT_SIDE_ROOTS | `_PROJECT_SIDE_ROOTS` constant removed; `_iter_project_side_files()` delegates to `_iter_client_installed_files()` |
| Guardrail 3 fixture tests pass | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` exits 0; new Group 7 added |
| Guardrail 2 helpers exist | `_has_per_line_fence()` + `_build_fence_skip_lineset()` + `_CHECK_37_PER_LINE_FENCE_FILES` defined |
| Guardrail 2 removes `_is_legitimate_deny_list_doc()` | Function deleted; callers updated |
| Guardrail 2 fence markers placed | All 7 files in `_CHECK_37_PER_LINE_FENCE_FILES` have at least one `<!-- DENY-LIST-CONTENT-START -->`/`<!-- DENY-LIST-CONTENT-END -->` pair |
| Guardrail 2 fixture tests pass | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` Group 6 + 7 pass |
| Guardrail 1 function exists | `check_project_side_bare_internal_refs()` defined |
| Guardrail 1 allowlist populated | `_CHECK_43_ALLOWLIST` defined with ~25 entries per §1.4 |
| Guardrail 1 fixture file exists | `scripts/tests/fixtures/project-side-refs/` contains 13 files per §1.10 enumeration |
| Guardrail 1 fixture test file exists | `scripts/tests/test-validate-pack-check-43.sh` exists; exits 0 |
| Guardrail 1 CI wired | `.github/workflows/validate-pack.yml` contains `bash scripts/tests/test-validate-pack-check-43.sh` invocation |
| Guardrail 1 Check 42 passes | `python3 scripts/validate-pack.py` Check 42 PASSES (new test file is CI-wired) |
| Guardrail 4 PACK-AGENTS.md edit applied | The Check 43 verification step inserted at the §4.1 anchor |
| Guardrail 4 trinity edits applied | Pack-root `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` carry the same Check 43 addition under `## Pack memory` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" |
| Guardrail 4 CONCEPTUAL-REVIEW-METHODOLOGY.md edit applied | Dimension (d) extended per §4.2 |
| Guardrail 4 memory cache update | Pack Chat applies the §4.3 update to the user-local feedback file |
| RC9 manifest regenerated per commit | Every commit that touches project-template/, scripts/, pack-ops/, or supporting-docs/ stages test-fixtures/manifest.txt |
| All commits PASS validate-pack.py | At every commit head, `python3 scripts/validate-pack.py` exits 0 |

---

**End of contract.**
