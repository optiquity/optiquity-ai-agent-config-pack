# IMPL-REPORT — BD-221 commit C0 (project-only)

**Commit:** C0 — Project-side skills re-land (the revert recovery)
**Scope keyword (Check 36):** `project-only`
**Author:** pack-coder (isolated worktree, RW-emit). No git state change made.
**Plan:** `/tmp/handoff-bd221-planner-final2/PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md` §3 C0 (lines 100-110), §4 (prose-only body), §5 row L337-L338.
**Design:** `/tmp/handoff-bd221-architect-v3/DESIGN-BD-221-ANTIGRAVITY-COMPLETION-v2.md` §2.3/§2.4/§4.

---

## Runtime regime (verified at startup, ground-truth)

- `pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a318c7f4c6f3b00d1`
- `git rev-parse HEAD` = `9d8bf22dc07b726c1bfde5230bf7ff663295ccbb` (matches expected CLEAN HEAD 9d8bf22)
- branch = `worktree-agent-a318c7f4c6f3b00d1` (off `v11-dev`)
- Regime = **ISOLATED git worktree** (RW-emit; patch to `/tmp/handoff-bd221-C0/`; orchestrator applies + commits).
- Pre-edit `git status --short` = EMPTY (clean checkout). No empty-dir residue; no `.gemini/` dirs in pack-root or `project-template/` (the `.gemini` dirs that exist are intentional v10-shaped TEST FIXTURES under `scripts/tests/fixtures/customization-preserve/`, not residue and not touched by C0).
- **HEAD after all work = `9d8bf22dc07b726c1bfde5230bf7ff663295ccbb` (unchanged — no commit).**

---

## PREFLIGHT line

```
PREFLIGHT: 6/6 C0 edits complete; validate-pack delta = CLEARED{31,21} + NEW{28×2→C4,39×4→C2,41×4→C2} net 70, all mapped; manifest blocked-reported (pre-existing init-project `.gemini/agents` dependency, C2's conversion); about to emit patch + IMPL-REPORT
```

---

## Patch

- **Path:** `/tmp/handoff-bd221-C0/changes.patch` (539 lines; non-empty)
- `git diff HEAD --stat`: 6 files changed, 12 insertions(+), 479 deletions(-)
- Captures ALL changes (4 deletes, 1 add, 1 modify); patch file list == `git diff HEAD --name-only` (verified MATCH).
- `git add -A -N` (intent-to-add only — NO content staged) used so the NEW file appears in `git diff HEAD`. No `git add`(content)/commit/push/restore/checkout/reset/apply run.
- **`git apply --check` against a CLEAN HEAD checkout = OK** (verified via `git archive HEAD … | tar -x` into a temp dir, then `git apply --check`). NOTE: `git apply --check` run INSIDE this worktree FAILS — expected, because the worktree already contains the applied edits (the patch cannot re-apply on top of itself). The orchestrator applies it to the clean main tree, where it applies cleanly. Per `feedback-worktree-isolation-mergeback-ops`: orchestrator should `git update-index -q --refresh` before `git apply` to avoid stat-cache noise.

---

## File-change manifest (ADDED / MODIFIED / DELETED)

| Change | Path | Notes |
|---|---|---|
| ADDED | `project-template/skills/pack-help/SKILL.md` | New SSOT pool entry; PROSE-ONLY body (no inline `!`cmd``); references `scripts/pack-help.sh`; project-side audience doc-refs (`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`); NO historical narration. |
| MODIFIED | `project-template/skills/pm-startup/SKILL.md` | 3 ref-swaps: `.gemini/settings.json`→`.agents/mcp_config.json` (L120); `for Gemini):`→`for Antigravity):` (L121); `Gemini without local-rag`→`Antigravity without local-rag` (L156). No other change. No remaining `gemini` token (grep verified NONE). |
| DELETED | `project-template/.claude/skills/pack-help/SKILL.md` | Committed per-CLI orphan (carried forbidden inline `!`bash scripts/pack-help.sh``). Now S4-distributed from pool. |
| DELETED | `project-template/.codex/skills/pack-help/SKILL.md` | Same — committed per-CLI orphan. |
| DELETED | `project-template/.claude/skills/pm-startup/SKILL.md` | Collapse to single pooled SSOT (the pool `pm-startup/SKILL.md` is KEPT + edited). |
| DELETED | `project-template/.codex/skills/pm-startup/SKILL.md` | Same — collapse to pool-only. |

Deletions done via filesystem `rm` (not `git rm`). The now-empty per-CLI dirs (`project-template/.claude/skills/`, `project-template/.codex/skills/`) were `rmdir`'d locally to avoid empty-dir residue; git does not track empty dirs, so the patch carries only the 6 file changes. (At HEAD these two per-CLI dirs contained ONLY pack-help + pm-startup — confirmed via `git ls-tree -r HEAD` — so emptying them is the correct end-state; per-CLI skill copies are produced at install by S4, not committed.)

---

## Verification — fail-LINE-level `comm` set-difference (CORRECTED criterion)

**BASE** (pre-edit, clean worktree at HEAD 9d8bf22): `python3 scripts/validate-pack.py` → **FAILED — 62 issue(s)**; 62 sorted FAIL lines captured.
**AFTER** (post-edit): `python3 scripts/validate-pack.py` → **FAILED — 70 issue(s)**; 70 sorted FAIL lines.
Both sets sorted via `grep -E '^FAIL:' … | sort`; delta via `comm`.

### CLEARED = BASE \ AFTER (`comm -23`) — 2 lines (EXACTLY the expected set)

1. **Check 31** — `PLATFORM-SKILLS.md — phantom cell: 'pack-help' listed in inventory subsection(s) [PM chat operational skill] but no SKILL.md exists at project-template/skills/pack-help/`
   → cleared because the pool dir `project-template/skills/pack-help/` now exists; Check 31 goes FULLY green.
2. **Check 21 (project-template leg)** — `project-template: pack-help parity violated — present in ['claude', 'codex'], missing in ['gemini']`
   → cleared because deleting BOTH per-CLI copies flips the project-template leg to consistent-absent. The **pack-ROOT leg stays red** (`pack-root: pack-help parity violated …`) and correctly retires at C4 — it is NOT in CLEARED (verified present in AFTER).

### NEW = AFTER \ BASE (`comm -13`) — 10 lines, EVERY ONE mapped to a named restore commit

| Count | Check | Fail-line family | Restore commit |
|---|---|---|---|
| 2 | **Check 28** | `claude:`/`codex: pm-startup surface missing: project-template/.{claude,codex}/skills/pm-startup/SKILL.md` | **C4** (Check 28 RETIRED) |
| 4 | **Check 39** | `cmd_update` stale for `.claude/.codex × pack-help/pm-startup` SKILL.md sources | **C2** (init-project cmd_update row removal) |
| 4 | **Check 41** | `_CLIENT_INSTALLED_FILES` stale for the same 4 per-CLI sources | **C2** (`_CLIENT_INSTALLED_FILES` row removal) |

**UNMAPPED check:** `grep -vE 'pm-startup surface missing|cmd_update|_CLIENT_INSTALLED_FILES'` over the NEW set → **NONE** (all 10 mapped). No UNEXPECTED red.

**net = 62 − 2 + 10 = 70.** ✓ Matches the plan's C0 expected delta (FINAL-2 §3 C0, correction 2) EXACTLY.

**C0 PASSES the corrected baseline-delta gate:** (a) every NEW line maps to a named later restore commit (C2/C4); (b) every line the plan says C0 clears (Check 31 phantom + Check 21 project-template leg) is in CLEARED.

(Raw `comm` outputs are in `/tmp/handoff-bd221-C0-base.txt`, `/tmp/handoff-bd221-C0-after.txt`, `/tmp/handoff-bd221-C0-new.txt`; full logs `/tmp/handoff-bd221-C0-base-full.log`, `/tmp/handoff-bd221-C0-after-full.log`.)

---

## Manifest disposition — BLOCKED-REPORTED (orchestrator decision required)

C0 touches `project-template/` (v11-surface), so `regenerate-manifest-v11-surface` requires running `bash test-fixtures/build.sh --all --clean` and staging `test-fixtures/manifest.txt` if its diff is non-empty.

**The full `--all --clean` regen is BLOCKED — by a PRE-EXISTING condition at HEAD 9d8bf22, independent of C0's edits.** Diagnosis:
- `build.sh` exits non-zero (22) at the `v11-realistic-ot` stage, which invokes `$PACK_ROOT/scripts/init-project.sh` (current-HEAD init-project, build.sh L250-255).
- That init fails at **stage S2: "pack source missing: …/project-template/.gemini/agents"** (init log `/tmp/handoff-bd221-C0-v11init2.log`).
- `project-template/.gemini/agents` does NOT exist at HEAD (`git ls-tree -r HEAD project-template/.gemini/` → empty; not on disk). `scripts/init-project.sh:422/428` still `mkdir`s + stages `.gemini/agents` as a pack source.
- **This is the C2 work** (init-project.sh `.gemini`→`.agents`/bundle conversion), which has NOT landed yet. The block exists at HEAD before any C0 edit; C0 does not cause it and cannot fix it (init-project.sh is OUT of C0 scope — `project-only`; init-project.sh is pack-side `scripts/`).

**Why this is not silently skipped / hand-edited / fabricated** (per directive step 7 + `regenerate-manifest-v11-surface`): the manifest (`test-fixtures/manifest.txt`) is a 10-line fixture-name→git-SHA map (header: "Generated by build.sh; do not hand-edit"). The v11 fixture SHAs CANNOT be recomputed while the build is blocked, and hand-editing/fabricating a SHA is forbidden. The committed manifest is UNCHANGED in the patch (verified `git status --short test-fixtures/manifest.txt` empty). The partial build left NO stray tree changes (v10 fixtures it rebuilt are gitignored, not tracked; manifest not rewritten).

**Recommended orchestrator handling:** the manifest regen is deferred to the commit(s) that unblock the v11 fixture build (C2 converts init-project.sh; the manifest naturally regenerates there). At C0 the manifest stays as-is. This matches the cluster's intermediate-red model (the build's full green is only reachable once init-project is converted at C2). The orchestrator should confirm this disposition before committing C0, or split/sequence per the plan. (The `manifest blocked-reported` token in the PREFLIGHT line reflects this — it is the directive's sanctioned disposition for a blocked v11 fixture build, not a silent skip.)

---

## Boundary discipline check (P-missed-7)

C0 is entirely project-side (`project-template/`). Per the boundary pre-flight, for each project-side edit I investigated whether a project-side SSOT exists and whether any pack-only reference would leak:

- **`project-template/skills/pack-help/SKILL.md` (ADDED):** project-side SSOT for this concept is the project-side pack-help pool body shape (plan §4 / DESIGN §4.2, project-side doc-refs). I implemented per that, citing project-side docs (`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`) — NOT pack-side docs (QUICKSTART.md/PACK-CHAT.md are the pack-side mirror's refs, reserved for C5). No pack-only reference (`pack-ops/`, `maintenance-docs/`, Pack Chat role, pack-* agent name, BD-NNN) appears in the body — grep verified NONE.
- **`project-template/skills/pm-startup/SKILL.md` (MODIFIED):** project-side SSOT is the existing pooled pm-startup body. Ref-swaps are within the existing project-side content (`.agents/mcp_config.json` is the Antigravity workspace MCP config, the project-side end-state per DESIGN §4 L194). No pack-only reference introduced.
- **DELETED per-CLI copies:** removal only; no new references.

No "Boundary discipline stop" condition (no pack-only target was about to be referenced from a project-side file).

---

## Plan deviations

**ONE deviation, anticipated by the plan + the spawn directive:** the v11-surface manifest regen is BLOCKED at C0 (pre-existing init-project `.gemini/agents` dependency = C2's work). Reported as `manifest blocked-reported` per directive step 7 (the plan/directive sanctioned path; not a silent skip, no hand-edit, no fabrication). All other C0 actions match the plan §3 C0 file set and §4 body shape verbatim. C0's edit set is unchanged from the prior (correctly-STOPPED) attempt; only the success criterion was corrected (fail-LINE `comm` delta), which this run applied.

## New POQs introduced

None.

## Full file contents of new files (for re-apply without re-derivation)

### `project-template/skills/pack-help/SKILL.md`

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

(pm-startup is a MODIFY, not new — see the 3 ref-swaps in the file-change manifest; the patch carries the exact hunk.)

---

## Definition-of-Done checklist

| Item | PASS/FAIL |
|---|---|
| ADD `project-template/skills/pack-help/SKILL.md` — prose-only, no inline `!`cmd``, references `scripts/pack-help.sh`, project-side doc-refs, no narration | PASS |
| DELETE `project-template/.claude/skills/pack-help/SKILL.md` + `.codex/…` | PASS |
| DELETE `project-template/.claude/skills/pm-startup/SKILL.md` + `.codex/…` | PASS |
| KEEP + edit pooled `project-template/skills/pm-startup/SKILL.md` (`.gemini/settings.json`→`.agents/mcp_config.json`; strip Gemini prose) | PASS |
| Did NOT edit PLATFORM-SKILLS.md | PASS |
| Did NOT touch init-project.sh / validators / any non-C0 surface | PASS |
| Clean worktree confirmed; BASE = 62 clean baseline | PASS |
| `comm` delta = CLEARED{31,21} + NEW{28×2,39×4,41×4}; net 70; all NEW mapped; zero unmapped | PASS |
| No `gemini`/narration/pack-self/BD-NNN/inline-cmd leak in edited skills | PASS (grep verified) |
| Manifest handled per plan (regen attempted; BLOCKED by pre-existing init-project dep; reported, not skipped/hand-edited/fabricated) | PASS (blocked-reported) |
| Patch emitted to `/tmp/handoff-bd221-C0/changes.patch`; non-empty; applies clean to HEAD tree | PASS |
| No git state-change verb run (HEAD == 9d8bf22; no commit/stage-content/push) | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | `git rev-parse HEAD` = `9d8bf22dc07b726c1bfde5230bf7ff663295ccbb` (unchanged). Only read-only git verbs + `git add -A -N` (intent-to-add, the sanctioned patch-emit form) + `git diff HEAD` run. Deletions via filesystem `rm`/`rmdir`, not `git rm`. Patch emitted; not staged-content/committed/applied. | COMPLIANT |
| **preflight-stop-means-stop** | PREFLIGHT line emitted ONLY after all 6 edits + the `comm` baseline-delta verification PASS. No unmapped red (grep `-vE …` → NONE). The single deviation (manifest blocked) is the directive-sanctioned `blocked-reported` disposition (PREFLIGHT format explicitly allows it), not a partial-IMPL on an unmapped red. No parent stop/halt message received. | COMPLIANT |
| **worktree-isolation-mergeback** | Isolated worktree confirmed at runtime (`pwd` under `.claude/worktrees/agent-…`, HEAD = parent local HEAD 9d8bf22). `mkdir -p /tmp/handoff-bd221-C0`; `git diff HEAD > …/changes.patch`; IMPL-REPORT to same dir. `git apply --check` against a clean HEAD archive = OK (orchestrator applies). | COMPLIANT |
| **verification = fail-LINE `comm` set-difference vs clean-62** | BASE 62 lines (`/tmp/handoff-bd221-C0-base.txt`), AFTER 70 (`…-after.txt`); `comm -23`=2 CLEARED, `comm -13`=10 NEW; per-check counts 28×2/39×4/41×4; UNMAPPED grep → NONE; net 70. | COMPLIANT |
| **regenerate-manifest-v11-surface** | C0 touches `project-template/` (v11-surface). Ran `bash test-fixtures/build.sh --all --clean` → exit 22, BLOCKED at v11-realistic-ot by pre-existing init-project `.gemini/agents` dependency (C2's work; `project-template/.gemini/agents` absent at HEAD). Reported as `blocked-reported`; manifest UNCHANGED (`git status --short test-fixtures/manifest.txt` empty); NOT skipped/hand-edited/fabricated. | COMPLIANT (blocked-reported per directive step 7) |
| **pack-vs-project separation + P-missed-7** | C0 is all `project-template/`. pack-help body cites project-side docs only (not pack-side QUICKSTART/PACK-CHAT). grep for `gemini\|formerly\|replaces\|previously\|maintenance-docs\|pack-ops\|BD-[0-9]\|!\`\|Pack Chat` over both edited skills → NONE. See Boundary discipline check above. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Exactly the 6 C0 file changes; touched nothing else (init-project.sh, validators, PLATFORM-SKILLS.md untouched — verified via `git diff HEAD --name-only`). | COMPLIANT |
| **no-historical-narration** | New pack-help body + pm-startup edits carry NO "formerly Gemini"/"replaces"/"previously" text (grep → NONE). Convert-as-if-Gemini-never-existed honored. | COMPLIANT |
| **agent-output-requires-rules-applied-verification-block** | This block. Every named rule has quoted/measured evidence + a terminal conclusion; no empty evidence. | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read DIRECTLY + IN FULL via Read tool: CLAUDE.md `## Pack memory` (in spawn context, governs); `feedback_worktree_isolation_mergeback_ops.md` (23 ln; first "name: feedback-worktree-isolation-mergeback-ops", last "…the reviewer always runs IN-PLACE…"); `feedback_manifest_regen_on_v11_surface.md` (16 ln; ends "Related: test-infra self-provisioning (distinct concern)."); `feedback_pack_project_separation_of_concerns.md` (33 ln; ends "[[pack-entry-type-data-structure-semantics]] (audience anchors)."); `feedback_scope_deliverables_to_the_ask.md` (35 ln; ends "…the user's standing preference for terse, exactly-scoped work."); `feedback_agent_output_rules_applied_block.md` (15 ln; ends "[[architect-planner-empirical-evidence]]."); `feedback_agents_read_rule_docs_in_full.md` (134 ln; ends "…accepting a derived-not-read attestation erodes the very standard that catches the dangerous cases."). Plus the plan C0 section + §4 + §5, and DESIGN §2.3/§2.4/§4, read directly. | COMPLIANT |

---

## Final files-changed inventory

| Path | Change type |
|---|---|
| `project-template/skills/pack-help/SKILL.md` | new |
| `project-template/skills/pm-startup/SKILL.md` | modified |
| `project-template/.claude/skills/pack-help/SKILL.md` | deleted |
| `project-template/.codex/skills/pack-help/SKILL.md` | deleted |
| `project-template/.claude/skills/pm-startup/SKILL.md` | deleted |
| `project-template/.codex/skills/pm-startup/SKILL.md` | deleted |

`test-fixtures/manifest.txt` — NOT changed (regen blocked; see Manifest disposition).
