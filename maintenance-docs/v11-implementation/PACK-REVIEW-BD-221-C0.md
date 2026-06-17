# PACK-REVIEW-C0 — BD-221 completion cluster, commit C0 (pre-commit, in-place)

- **Reviewer regime:** IN-PLACE, read-only, in the main working tree
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (verified:
  `git branch --show-current` = `v11-dev`, `git rev-parse HEAD` = `9d8bf22…`).
- **Commit under review:** C0 — "Project-side skills re-land (the revert recovery)"
  `(project-only)`, applied uncommitted in the working tree.
- **Spec:** `/tmp/handoff-bd221-planner-final2/PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md`
  §C0 (L100–110), §4 (L285–299), §5 row L337–338.
- **Design:** `/tmp/handoff-bd221-architect-v3/DESIGN-BD-221-ANTIGRAVITY-COMPLETION-v2.md`
  §2.1–§2.4 (L69–117), §3.3 (L137–139), §4 (L147–151).
- **Clean baseline:** `/tmp/validate-head-9d8bf22-clean.log` (62 FAIL lines).
- **No files modified / staged / committed by this review.**

## OVERALL VERDICT: **CLEAN**

C0's file set, content, boundary posture, and validate-pack fail-LINE delta all
match the FINAL-2 plan + v3 design exactly. The net-70 validate state is the
EXPECTED intermediate red; all 10 NEW fail-lines map to a named later restore
commit (C2/C4) and ZERO are unmapped. No BLOCKER / MUST / SHOULD / NIT findings.

---

## Checklist results (evidence-backed)

### 1. File set matches the plan's C0 exactly — PASS

`git status --porcelain` shows exactly the C0 set, nothing out of scope:

```
 D project-template/.claude/skills/pack-help/SKILL.md
 D project-template/.claude/skills/pm-startup/SKILL.md
 D project-template/.codex/skills/pack-help/SKILL.md
 D project-template/.codex/skills/pm-startup/SKILL.md
 M project-template/skills/pm-startup/SKILL.md
?? project-template/skills/pack-help/
```

- 1 ADD: `project-template/skills/pack-help/SKILL.md` (new untracked SSOT pool dir).
- 1 MODIFY: `project-template/skills/pm-startup/SKILL.md` (pool body ref-swap).
- 4 DELETE: the per-CLI copies under `.claude/skills/` + `.codex/skills/`.

No `init-project.sh`, no `validate-pack.py`, no tests, no supporting-docs, no
pack-ops, no other surfaces touched (plan assigns those to C2/C3/C4/C5/C10/C11).
Matches PLAN §C0 File-set (L101–106) + §5 rows L337–338.

### 2. pack-help SSOT body — PASS

`project-template/skills/pack-help/SKILL.md` (full content):

```
---
name: pack-help
description: Show all pack commands and colloquial mappings (semantic trigger — "what pack commands exist", "how do I run X", or a quick reference for `pm-startup`, `init-project.sh`, `agent-run.sh`, or any top-level pack verb).
allowed-tools: Bash
---

Run `scripts/pack-help.sh` (it lives at the project root) and present its
output to the user verbatim. For full docs see `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
```

- **PROSE-ONLY**: instructs the agent to run `scripts/pack-help.sh` and present
  output verbatim. NO inline `` !`cmd` `` (grep `'^\s*!`|!`bash'` → no match).
  This is the ALIGNED Antigravity mechanism per DESIGN §4.1 (codelab fact:
  inline `` !`cmd` `` unsupported; skill body instructs `run_command`).
- **Frontmatter**: `name` + `description` (a *semantic trigger*, matching the
  design's frozen decision 3 that Antigravity skills are agent-triggered by the
  `description`, not a literal `/name`) + `allowed-tools: Bash`. Matches the §4
  shape (PLAN L289–296) and the pool-skill convention.
- **NO historical narration**: grep for `formerly|former|replaces|gemini|
  antigravity` → no match. (The reverted prior body carried a "replaces the
  former Gemini-CLI" narration per DESIGN §2.3/L55 — correctly absent here.)
- **Doc-refs are project-side only**: `docs/pack/PM-CHAT.md`,
  `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md` — exactly
  the project-audience set named in PLAN L297. NO pack-self / BD-NNN / pack-ops /
  maintenance-docs / Pack-Chat / validate-pack leak (grep over the full
  pack-self pattern set → no match). P-missed-7 / bd-pack-only / separation:
  satisfied.
- **Folded Check-1 assertion (added at C4)** requires the body to reference
  `scripts/pack-help.sh` — the prose body names it (PLAN L299). Forward-safe.
- **Bonus correctness:** the prior per-CLI HEAD copy's `description` listed
  `pack tracker *` (a deferred surface — BD-214); the new SSOT description
  correctly DROPS it (grep `tracker` → no match), keeping the description
  consistent with flat-file-only mode.

### 3. pm-startup pool body — PASS

`git diff project-template/skills/pm-startup/SKILL.md` is exactly two hunks,
three ref-swaps, no narration added:

- `.gemini/settings.json` → `.agents/mcp_config.json` (L120, MCP-channel para).
- `for Gemini):` → `for Antigravity):` (L121).
- `Gemini without local-rag configured` → `Antigravity without local-rag
  configured` (L156).

Matches CENSUS §7.1 L120/121/156 (PLAN L105, §5 row L337). Verified:
- NO leftover gemini token remains anywhere in the file (grep `-i gemini`
  → no match).
- NO narration added (grep `formerly|replaces|BD-[0-9]|pack-ops|…` → no match).
- The pooled `pm-startup/SKILL.md` is RETAINED (`git ls-files` confirms it is
  still tracked) — only the two per-CLI copies are removed (collapse to pool).

### 4. The 4 deletions are the correct per-CLI copies — PASS

```
 D project-template/.claude/skills/pack-help/SKILL.md
 D project-template/.claude/skills/pm-startup/SKILL.md
 D project-template/.codex/skills/pack-help/SKILL.md
 D project-template/.codex/skills/pm-startup/SKILL.md
```

Exactly the {pack-help, pm-startup} × {.claude/skills, .codex/skills} per-CLI
copies — the committed orphans that become S4-distributed from the pool
(DESIGN §2.2 L95 + §2.4 L107–109; PLAN L103–104). At HEAD, `git show
HEAD:project-template/skills/pack-help/SKILL.md` did NOT exist (the SSOT was
absent; pack-help lived only as the per-CLI copies carrying the inline
`` !`bash scripts/pack-help.sh` `` exec) — so deleting the per-CLI copies + adding
the prose SSOT is the correct re-land.

### 5. Boundary + scope — PASS

C0 is project-side only (all paths under `project-template/`). Verified no
pack-self leak in either authored/edited file (checklist 2 + 3 greps). No
out-of-C0 surface touched. The `(project-only)` scope keyword is correct for
Check 36 (all touched paths are under `project-template/`; the deferred
`test-fixtures/manifest.txt` is scope-neutral per PLAN RISK-8 L475 and is not
modified here anyway). `scope-deliverables-to-the-ask`: C0 does exactly its
assigned surface, no sprawl.

### 6. Independent validate-pack confirmation (fail-LINE comm delta) — PASS

Re-ran `python3 scripts/validate-pack.py` myself in the working tree:
`exit=1`, `FAILED — 70 issue(s) found`.

`comm` set-difference, sorted `^FAIL:` lines, clean-62 baseline vs C0:

- **base.txt (clean baseline):** 62 lines.
- **after.txt (C0):** 70 lines.
- **NEW = `comm -13 base.txt after.txt`: 10 lines** — classified:
  - Check 28 ×2: `claude:` + `codex: pm-startup surface missing:
    project-template/.{claude,codex}/skills/pm-startup/SKILL.md` → **restore C4**.
  - Check 39 ×4: `cmd_update` stale for `.claude/.codex` × `{pack-help,pm-startup}`
    SKILL.md sources → **restore C2**.
  - Check 41 ×4: `_CLIENT_INSTALLED_FILES` stale for the same 4 per-CLI sources
    → **restore C2**.
- **CLEARED = `comm -23 base.txt after.txt`: 2 lines** —
  - Check 31 phantom: `PLATFORM-SKILLS.md — phantom cell: 'pack-help' … no
    SKILL.md exists at project-template/skills/pack-help/` (pool dir now exists).
  - Check 21 project-template leg: `project-template: pack-help parity violated —
    present in ['claude','codex'], missing in ['gemini']` (both per-CLI copies
    deleted → leg flips consistent).
- **Net:** 62 − 2 + 10 = **70**. Confirmed.
- **pack-ROOT Check 21 leg correctly STAYS red** (`FAIL: pack-root: pack-help
  parity violated …`) — this retires at C4, not C0 (PLAN L108, L155). Expected.

**Every one of the 10 NEW lines maps to a named later restore commit
(28→C4, 39→C2, 41→C2). ZERO unmapped. No BLOCKER.** This is exactly the
PLAN C0 expected delta (L108, L412 step 4, §8 matrix C0 row L433).

### 7. Manifest deferral — CORRECTLY NOT FLAGGED

`test-fixtures/manifest.txt` is NOT modified in C0 (`git status --porcelain
test-fixtures/manifest.txt` → empty), and the new `skills/pack-help` SSOT is
absent from the manifest. Per the task §7 (and PLAN §C0 note that `build.sh` is
blocked at HEAD because `init-project.sh` still expects the absent
`project-template/.gemini/agents` — fixed at C2), the manifest regen is a
user-authorized deferral to C2. This is EXPECTED and CORRECT — **NOT flagged
as a defect.** (The `regenerate-manifest-v11-surface` rule is satisfied at the
cluster level: the regen lands in C2 alongside the install-engine conversion
that unblocks `build.sh`.)

---

## Findings by severity

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT:** none.

---

## Rules-Applied Verification Block

| # | Rule (as named) | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | pack-project-separation-of-concerns | New SSOT pack-help body doc-refs are project-side only (`docs/pack/PM-CHAT.md`, `INSTALL-PROCEDURES.md`, `OPTIONAL-FEATURES.md`); no pack-internal path substituted. grep over pack-self pattern set on both C0 files → "(none — CLEAN)". | COMPLIANT |
| 2 | bd-pack-only-operational-rule (P-missed-7) | `grep -niE "BD-[0-9]|pack-ops|maintenance-docs|pack-chat|pack-architect|pack-coder|pack-reviewer|pack-planner|validate-pack"` on `skills/pack-help/SKILL.md` AND `skills/pm-startup/SKILL.md` → "(none — CLEAN)". No pack-self reference in project-side content. | COMPLIANT |
| 3 | no-historical-narration (cross-cutting) | `grep -niE "formerly|former|replaces|gemini|antigravity"` on the new pack-help SSOT → "(none — CLEAN)"; pm-startup diff adds only Antigravity ref-swaps, no narration; `grep -i gemini` on pm-startup → "(none — CLEAN)". | COMPLIANT |
| 4 | scope-deliverables-to-the-ask-no-noise | `git status --porcelain` = exactly the 6 C0 lines (1 add dir, 1 modify, 4 delete); no out-of-scope surface (init-project.sh / validate-pack.py / tests / supporting-docs absent). | COMPLIANT |
| 5 | verification = fail-LINE comm set-difference vs clean-62; only UNMAPPED new red is a defect | Independent `python3 scripts/validate-pack.py` → "FAILED — 70 issue(s) found"; `comm -13` = 10 NEW (28×2→C4, 39×4→C2, 41×4→C2, all mapped); `comm -23` = 2 CLEARED (31 phantom, 21 proj-tmpl leg); zero unmapped. | COMPLIANT |
| 6 | agents-never-commit / read-only | No Write/Edit on any C0 file; no `git add`/`commit`/`stage`/`mv`/`rm`/`restore` run; only read-only `git status`/`diff`/`show`/`ls-files` + a non-mutating `validate-pack.py` run. The sole Write is this report at the prompted `/tmp` path. | COMPLIANT |
| 7 | agent-output-requires-rules-applied-verification-block | This block + per-checklist evidence + the "Files read in full" attestation below. | COMPLIANT |
| 8 | agents-read-rule-docs-in-full | Files-read-in-full attestation below, each with a direct Read-tool proof (line count + first/last anchors). | COMPLIANT |

## Files read in full (direct-read attestation)

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` —
  604 lines; first line `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`; last
  line `testing (use /tmp clones or scratch fixtures, never write to real OT).`
  Read in full (incl. the entire `## Pack memory` section L140–603).
- `…/memory/feedback_pack_project_separation_of_concerns.md` — 32 lines; first
  `---`; last line cross-refs `[[bd-pack-only-operational-rule]] …
  [[pack-entry-type-data-structure-semantics]]`.
- `…/memory/feedback_bd_pack_only_operational_rule.md` — 34 lines; first `---`;
  last line cross-refs `[[pack-project-separation-of-concerns]] … the
  ENCODING-surface enumeration rule … is in trinity § Repo conventions.`
- `…/memory/feedback_scope_deliverables_to_the_ask.md` — 34 lines; first `---`;
  last line `…the user's standing preference for terse, exactly-scoped work.`
- `…/memory/feedback_agent_output_rules_applied_block.md` — 15 lines; first
  `---`; last line `Related: [[agent-prompt-enumerates-rules]],
  [[architect-planner-empirical-evidence]].`
- `…/memory/feedback_agents_read_rule_docs_in_full.md` — 133 lines; first `---`;
  last line ends `…accepting a derived-not-read attestation erodes the very
  standard that catches the dangerous cases.`

Spec/design also read directly: PLAN §C0 (L100–110), §4 (L285–299), §5
(L337–338); DESIGN §2.1–§2.4, §3.3, §4.1.

---

*End of PACK-REVIEW-C0 — in-place read-only pack-reviewer pass, HEAD `9d8bf22`,
branch v11-dev, 2026-06-16. VERDICT: CLEAN.*
