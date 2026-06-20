# IMPL-REPORT — BD-226 COMMIT C6 (project feature doc + skill + prompts + agent-run launcher)

**Agent:** pack-coder (FRESH, isolated worktree, READ-WRITE). **BD:** BD-226. **Commit:** C6 (`project-only`).
**Branch (worktree):** `worktree-agent-a8aa498bbedb833cd`
**HEAD (worktree, `git rev-parse HEAD`):** `46dce4d7785388b19d4ff4c1737e2ee4ae582924`
**Verified runtime regime (rule 8, pwd/HEAD ground-truth):**
- `pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a8aa498bbedb833cd`
- `git rev-parse --show-toplevel` = same (an ISOLATED worktree, NOT the main `-v11-dev` checkout)
- `git log -1 --oneline` = `46dce4d feat: v11 — BD-226 pack skills + feature doc + conceptual-review: regime/handoff decouple + isolated-parallel narrative (pack-only)` — matches the expected base `46dce4d`.

**Deliverable:** the C6 edits (in-worktree) + this IMPL-REPORT. NO patch emitted (patch is produced only after review-clean, when the orchestrator re-engages). NO stage/commit/apply run.

---

## 0. Summary

C6 is `project-only`. Touched ONLY paths under `project-template/`. All edits restate the worktree-isolation model (BD-226 rules 1-10) for the PROJECT audience: "the PM chat" (never "Pack Chat"), "your `coder`/`reviewer`" (never `pack-*`), "a future pack version" (never `BD-NNN`), NO Graphify content.

**Files changed (4):**

| Path | Change type | Surface |
|---|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified | S12 |
| `project-template/skills/implementation/SKILL.md` | modified | S17 |
| `project-template/docs/pack/prompts/reviewer.md` | modified | S14 (reviewer) |
| `project-template/agent-run.sh` | modified | S-AR (2 STRIP) |

**Files VERIFIED no-op (intentional, recorded per design):**

| Path | Surface | Reason |
|---|---|---|
| `project-template/docs/pack/prompts/coder.md` | S14 (coder) | Carries ZERO placement/handoff/patch/worktree language — nothing to align to rule 4. The coder's handoff mechanics live in the implementation SKILL (S17), not this prompt template. |
| `project-template/docs/pack/prompts/repo-ops.md` | S14 (repo-ops) | Placeholder file; no placement assertion. |
| `supporting-docs/METHODOLOGY.md` | S11 | A1: substance stays in PM-CHAT.md (S10). The only "isolation" prose (L720 "re-run the owning subagent in isolation") is an audit-efficiency concept (run ONE subagent alone, no full audit) — unrelated to worktree placement; it does NOT imply a stale placement model. Zero worktree/merge-back/patch-timing prose in the file. NO EDIT. |

**Line deltas (`git diff --stat`):**
```
 project-template/agent-run.sh                   | 11 ++--
 project-template/docs/pack/OPTIONAL-FEATURES.md | 84 +++++++++++++++----------
 project-template/docs/pack/prompts/reviewer.md  |  6 ++
 project-template/skills/implementation/SKILL.md | 54 ++++++++--------
 4 files changed, 94 insertions(+), 61 deletions(-)
```

---

## 1. Per-surface detail

### S12 — `project-template/docs/pack/OPTIONAL-FEATURES.md` § "Isolated parallel agents" (B1 + F-3 + F-13, project audience)

Four targeted edits in the § "Claude Code — Isolated parallel agents (worktree isolation)" section.

**(a) "What it is" RW narrative + "Read-only agents … need NO isolation" → in-worktree-cycle + RO-to-work's-tree.**
- BEFORE anchor: "it can isolate that agent in its own git worktree … The agent edits in the worktree, emits a `git diff` patch to a named handoff directory, and returns; the PM chat reads the patch, runs the review/fix cycle, applies it onto your branch, and commits …" + "Read-only agents (…) need NO isolation — they emit a report and write nothing to the tree."
- AFTER: "it isolates that agent in its own git worktree … The first coder of a commit creates the worktree; the ENTIRE review/fix cycle for that commit runs inside it — the read-only reviewer reads the work there and a fix-coder REUSES that same worktree (never a new one). The read-write agent does NOT emit a patch up front (the work may still be wrong); the patch is produced ONLY after the reviewer confirms the work clean, by re-engaging the most-recent read-write agent (in Claude Code, via the Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh coder against the worktree to produce it). The PM chat then applies that reviewed-clean patch …" + "Read-only agents (…) run in the tree the work lives in — your main tree when the work is committed, the live worktree when the work is still uncommitted there (they cd in and verify pwd/HEAD at runtime). They write a report and emit no patch."
- rule-4 re-engagement uses the design's project-audience phrasing ("re-engage the most-recent read-write agent … in Claude Code, via the Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh coder"). No `SendMessage` / Agent-Teams-as-universal-guarantee framing.

**(b) "in-place (non-isolated) regime is the default floor" → degraded fallback.**
- BEFORE anchor: "For a single sequential coder it is optional; the in-place (non-isolated) regime is the default floor and works without any settings."
- AFTER: "Read-write agents run isolated by class … If isolation is unavailable (an environment without worktree support), the in-place (non-isolated) regime is the DEGRADED fallback — it still works without any settings, but it exposes in-progress work to your main tree, which is exactly what the isolated default avoids."

**(c) F-3 caveats (project copy).**
- "Auto-removal" caveat: KEPT the auto-removal MECHANISM fact ("Claude Code can auto-remove its worktree and branch — a branch with unmerged commits can be silently deleted"); REWORDED the patch-timing consequence → "That mechanism is exactly why the PM chat does NOT rely on auto-removal: it HOLDS the commit's worktree through the whole review/fix cycle and removes it explicitly only AFTER the commit lands (a failed commit KEEPS the worktree). The patch is produced post-review-clean and applied at commit time, never captured pre-return …" (rule 4/7/Constraint 1).
- "Best-effort isolation" caveat: REWORDED the regime-detect from a patch-handoff signal → pwd/HEAD ground-truth: "Each agent therefore VERIFIES its actual regime from its own runtime pwd/HEAD ground-truth … never from an assumed settings value or a patch-handoff signal." (rule 8).

**(d) F-13 why-not (project audience, no `pack-*`).**
- ADDED to the TRIGGER mechanism bullet (#1, the `isolation` parameter description): "Do NOT pin `isolation:"worktree"` in any read-write agent's definition frontmatter: because the parameter has only the single value `"worktree"`, a frontmatter pin forces a NEW worktree on EVERY spawn — so a fresh fix-coder could not cd into and REUSE the first coder's worktree, which breaks the reuse / in-worktree-cycle / lifecycle rules. Isolation is the PM chat's per-spawn choice, not a definition-level pin."

**(e) `agent-run.sh --worktree` launcher narrative — patch-timing reword (consistency with S-AR).**
- The launcher paragraph carried "you bring its work back via the PM-chat patch merge-back" (old up-front-patch timing, in the §5.1 phrase set). REWORDED → "the PM chat runs the review/fix cycle in the worktree and brings back the reviewed-clean patch, same merge-back model as the in-session spawn path". The "(a SECONDARY path)" / "SECONDARY/opt-in" framing of the `--worktree` FLAG itself is KEPT (launcher-level opt-in, same class as the agent-run.sh KEEP locations).

**KEEP VERBATIM (B1) — confirmed unchanged:**
- the `worktree.baseRef` JSON block + prose (L153-159 region);
- the `permissions.deny` JSON recipe block + the verb-precise prose;
- the "Claude-only note" trinity-exempt note ("This feature is specific to Claude Code's Agent-tool `isolation` parameter … Codex CLI and Antigravity CLI have no equivalent … their worktree story is tracked separately");
- the "a future pack version" framing (already present at the `bgIsolation` paragraph; NO `BD-NNN` introduced).

### S17 — `project-template/skills/implementation/SKILL.md` § "Reporting the change set (regime-aware)" (F-9 + F-10, project audience)

Body-only rewrite of the "## Reporting the change set (regime-aware)" section. Frontmatter (`name`, `description`, `allowed-tools`), the numbered rule list (1-15), and all other sections are PRESERVED (skill-agent-maintenance-mechanical: no restructure, no count change, `x-` contract untouched — this file is a single source that installs to all 3 client skill dirs at install time).

- **F-10 (DELETE the "survives auto-removal"/`persisted artifact` rationale):** the old text "The patch — not the worktree — is the persisted artifact, so the change set survives even after the isolated worktree is cleaned up" is DELETED. Replaced by the rule-4/rule-7 model: the worktree is held through the cycle; the patch is the post-review-clean artifact; the report is the on-return deliverable.
- **F-9 (DECOUPLE regime↔patch-emit):** the old binary "In-place (default)" vs "Isolated (opt-in worktree)" bullets — which conflated "which tree you write in" with "do I emit a patch" — are replaced. New text states the two facts are SEPARATE and adds the THIRD state the binary cannot express: a read-ONLY agent in a live worktree writes ONLY its report and emits NO patch. A read-WRITE agent does NOT emit a patch up front; the patch is the post-review-clean RW-only step (`git diff > <handoff>/changes.patch`).
- **REPORT-LOCATION:** "Your report ALWAYS goes to the named `/tmp` handoff directory the calling prompt supplies — whether you ran in the main tree or in an isolated worktree." (removed the in-place→parent-tree-path conditional). The `/tmp`-write-fails degradation fallback ("fall back to the report path the prompt named and note the degradation") is preserved.
- Project phrasing throughout ("the PM chat", "the `coder`/`repo-ops`", "the `reviewer`/`architect`/`planner`"); NO `pack-*` / BD-NNN / Graphify.

### S14 — `project-template/docs/pack/prompts/reviewer.md` (+ coder.md / repo-ops.md verified)

**`reviewer.md` — ADDED a Constraints bullet** under the existing "Read-only review pass" constraint:
> "**Read the work in the tree it lives in.** When the coder's work is still uncommitted in an isolated worktree, `cd` into that worktree and VERIFY your pwd/HEAD at runtime before reviewing — read the in-progress work there, not the main checkout. When the work is already on HEAD/committed, review it in the main tree. Emit no patch; your output is the report only."
This is the rule-3/rule-8 placement directive (RO reads the work in the live worktree when uncommitted there).

**`coder.md` — verified NO edit needed.** Full read: the prompt template carries no placement/handoff/patch/worktree/merge-back language. Its completion-report section says only "REPORT FILE: [PM chat supplies path]" and "report which files were modified" — no placement or patch-timing assertion to align to rule 4. (The coder's handoff mechanics live in the implementation SKILL, S17.) Recorded as intentional no-op.

**`repo-ops.md` — verified NO edit needed.** Placeholder file; no placement assertion. Recorded as intentional no-op.

### S-AR — `project-template/agent-run.sh` — FOUR locations, 2-KEEP / 2-STRIP (F-4 + F-C)

| Location (current) | Classification | Outcome |
|---|---|---|
| L173-176 (`--worktree` help: "SECONDARY/opt-in — probe cwd-scoping once …") | **KEEP** | Unchanged. The `--worktree` FLAG is a launcher-LEVEL opt-in (human-launcher choice for the separate-terminal path), distinct from the agent-placement model. |
| L275-278 (`run_in_worktree()` comment: "the PM-chat merge-back applies the patch the agent leaves") | **STRIP** | Reworded to rule 4: "Either way the agent never stages or commits. The PM chat runs the review/fix cycle in the worktree and brings back the reviewed-clean patch — same merge-back model as the in-session spawn path; only the LAUNCH mechanism (separate terminal vs in-session Agent tool) differs, with no special-casing (see docs/pack/PM-CHAT.md "In-session agent spawning" and docs/pack/OPTIONAL-FEATURES.md)." **Xref label KEPT** = `docs/pack/PM-CHAT.md "In-session agent spawning"` (the section that exists) — did NOT invent a `### Merge-back` heading. |
| L306-307 (echo: "bring its work back via the PM-chat patch merge-back") | **STRIP** | Reworded the echo to the post-review-clean model: "The agent never commits; the PM chat runs the review/fix cycle in the worktree and applies the reviewed-clean patch." (now 3 echo lines instead of 2; valid bash). |
| L606-608 (branch comment: "SECONDARY isolated-worktree path (opt-in)") | **KEEP** | Unchanged. Annotates the `if [[ -n "$WORKTREE_OPT" ]]` launcher branch that fires only on `--worktree` (launcher-level opt-in). |

Also noted (not in the design's 4-location set, KEEP as launcher-flag class): the section-header comment at L250-251 ("Isolated-worktree launch … — SECONDARY, human-driven parallel-agent path. Opt-in via --worktree [path].") describes the launcher `--worktree` flag — same KEEP class as L173-176/L606-608. No edit.

**Bash syntax check:** `bash -n project-template/agent-run.sh` → SYNTAX OK.

### S11 — `supporting-docs/METHODOLOGY.md` (A1)

**NO EDIT — intentional.** Per design §2 S11 (A1): the worktree/merge-back SUBSTANCE stays in PM-CHAT.md (S10, committed in C5). METHODOLOGY gets at most a one-line xref IF its fix-cycle prose implies a placement. The only "isolation"-adjacent prose (L719-721) is "After fixing a Critical or Major finding, the developer may re-run the owning subagent **in isolation** to verify the fix" — this is an audit-efficiency concept (re-run ONE auditor subagent alone, no full audit), NOT the worktree-placement model. The file has zero worktree/merge-back/patch-timing prose. Adding an xref would either duplicate substance (single-SSOT drift risk) or be irrelevant. NO EDIT is the correct outcome.

---

## 2. Verification results

### 2.1 validate-pack
`python3 scripts/validate-pack.py` → **EXIT 0**. Final line: "PASSED — all checks clean". All 64 registered checks OK (Check 59 confirms CHECK_REGISTRY == 62 entries plus the wiring checks; the S17 skill body-only edit left frontmatter/skill-count unaffected — Check 1 "OK: skills/implementation/SKILL.md").

### 2.2 C6-files union OLD-model grep (design §5.1 phrase set, scoped to C6's OWN files)
Phrase set run: `opt-in accelerator|spawn ISOLATED|spawn IN-PLACE|when enabled|may auto-remove|worktree may auto|on agent return|the patch the agent|persisted artifact|before it returns|writes before|patch + report|patch handoff|survives.*auto-removal|survives.*cleaned up|in the isolated regime|in the in-place regime|need NO isolation|default floor|in-place.*default|patch merge-back|SECONDARY|opt-in`

**STRIP set (OLD patch-timing model) = 0.** No hit for `the patch the agent` / `patch merge-back` / `persisted artifact` / `survives.*cleaned up` / `before it returns` / `need NO isolation` / `default floor` / `on agent return` / `in the isolated regime` etc.

**Remaining hits = intentional KEEP allowlist remainder only:**
- `agent-run.sh` L175 (`--worktree` help — design KEEP), L250-251 (section header — launcher-flag KEEP), L609 (branch comment — design KEEP).
- `OPTIONAL-FEATURES.md` L229 ("SECONDARY defence-in-depth" — describes the `PreToolUse` hook vs `permissions.deny`, B1 verbatim-block context, not a placement phrase), L236 + L243 (the `agent-run.sh --worktree` launcher-flag SECONDARY/opt-in — launcher-flag KEEP), L296/L305/L312/L325/L336/L456 (generic "opt-in" in the Codex / Antigravity / Tracker / "Adding new entries" sections — unrelated to the worktree model, pre-existing).

Conclusion: the flip is complete; only the allowlisted launcher-flag + B1-verbatim + unrelated-section KEEPs remain.

### 2.3 Project leak gates (over C6's edited + verified files)
- `grep -rnE "BD-[0-9]"` over all 7 C6-scope files → **0** (exit 1, no output).
- `grep -rnE "graphify|graph\.json|--graph"` over all 7 → **0** (exit 1, no output).
- `Pack Chat` / `pack-*` / `pack-ops/` census: all hits are PRE-EXISTING and in lines I did NOT touch:
  - `reviewer.md` L109-110 + `coder.md` L86-87, L205-206 — inside the `<!-- DENY-LIST-CONTENT -->` blocks (these ENUMERATE the deny targets so the project's agents REJECT pack-only references — intentional, not an import).
  - `METHODOLOGY.md` L194/L1635/L1655/L1663/L1665 — pre-existing PACK-FEEDBACK upstream-channel prose (a legitimate project↔pack feedback concept where "Pack Chat" names the upstream maintainer). I made NO edits to METHODOLOGY.md.
- **All ADDED (`+`) lines scanned:** `git diff | grep '^\+' | grep -E "BD-[0-9]|graphify|graph\.json|--graph|Pack Chat|pack-ops/|pack-coder|pack-reviewer|pack-architect|pack-planner"` → **NO LEAK IN ADDED LINES**.

### 2.4 Scope (Check 36, project-only)
`git diff --name-only` → 4 paths, all under `project-template/`. `git diff --name-only | grep -vE "^(project-template/|supporting-docs/)"` → no output ("SCOPE CLEAN (project-only)"). No pack path touched.

### 2.5 PREFLIGHT line emitted
`PREFLIGHT: 4/4 C6 edits complete (S12 + S17 + S14-reviewer + S-AR; S14-coder/repo-ops no-op; S11 no-op); validate-pack PASS; C6-files union-grep clean (only launcher-flag KEEPs remain); project leak gates 0/0/0; project-only scope; agent-run.sh 2-KEEP/2-STRIP applied + "In-session agent spawning" xref label kept; S11 no-op; HEAD 46dce4d; worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a8aa498bbedb833cd; about to Write IMPL-REPORT`

---

## 3. Plan deviations

**None.** Every C6 task implemented exactly per design §2 (S12 / S17 / S14 / S-AR / S11) and plan §C6. The two no-op surfaces (S11; S14-coder/repo-ops) are the design's explicitly-anticipated likely outcomes, confirmed by inspection and recorded.

One judgment within the design's intent (NOT a deviation): S12 included the `agent-run.sh --worktree` launcher NARRATIVE paragraph's patch-timing phrase ("via the PM-chat patch merge-back") in the reword set — it carried the same OLD up-front-patch timing as the agent-run.sh L306-307 STRIP and is in the §5.1 union phrase set, so it was reworded to the post-review-clean model for consistency. The launcher-FLAG "SECONDARY/opt-in" framing in that same paragraph was KEPT (launcher-level opt-in, the design's KEEP class).

## 4. New POQs introduced

**None.**

## 5. Definition-of-Done checklist

| Item | Status |
|---|---|
| S12 "What it is" RW narrative → in-worktree-cycle + patch-after-review-clean | PASS |
| S12 "Read-only agents … need NO isolation" → RO-to-work's-tree | PASS |
| S12 "default floor" → degraded fallback | PASS |
| S12 F-3 auto-removal MECHANISM kept; patch-timing consequence reworded (rule 4/7/Constraint 1) | PASS |
| S12 F-3 regime-detect → pwd/HEAD ground-truth (not patch-handoff signal) | PASS |
| S12 F-13 why-not (no `pack-*`) added | PASS |
| S12 KEEP VERBATIM baseRef/permissions.deny/Trinity-exempt/"future pack version" | PASS |
| S17 patch = POST-review-clean artifact (rule 4) | PASS |
| S17 F-10 "survives … cleaned up"/`persisted artifact` rationale DELETED | PASS |
| S17 F-9 decouple regime↔patch-emit (RO-in-worktree writes only report, no patch) | PASS |
| S17 REPORT-LOCATION → named /tmp handoff dir (no in-place conditional) | PASS |
| S17 frontmatter/skill-count/`x-` contract preserved (mechanical) | PASS |
| S14 reviewer.md: RO reads work IN live worktree when uncommitted (rule 3/8) | PASS |
| S14 coder.md verified (no placement language → no-op) | PASS |
| S14 repo-ops.md verified (placeholder → no-op) | PASS |
| S-AR L173-176 KEEP | PASS |
| S-AR L275-278 STRIP → rule-4 reword + "In-session agent spawning" xref label kept | PASS |
| S-AR L306-307 STRIP → post-review-clean echo | PASS |
| S-AR L606-608 KEEP | PASS |
| S-AR bash syntax valid | PASS |
| S11 no-op (substance stays in PM-CHAT.md; L720 already consistent) | PASS |
| validate-pack exit 0 | PASS |
| C6-files union grep clean (STRIP set 0; only KEEPs remain) | PASS |
| Project leak gates 0/0/0 (BD-NNN, graphify, no pack-ref in added lines) | PASS |
| project-only scope (Check 36) | PASS |
| No patch emitted; no stage/commit/apply | PASS |

## 6. Files changed inventory

| Path | Change type |
|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified |
| `project-template/skills/implementation/SKILL.md` | modified |
| `project-template/docs/pack/prompts/reviewer.md` | modified |
| `project-template/agent-run.sh` | modified |
| `project-template/docs/pack/prompts/coder.md` | verified, unchanged (no-op) |
| `project-template/docs/pack/prompts/repo-ops.md` | verified, unchanged (no-op) |
| `supporting-docs/METHODOLOGY.md` | verified, unchanged (no-op) |

(No new files created — C6 edits existing surfaces only, so no full-file-contents section is required.)

---

## R. Rules-Applied Verification Block

| Rule name | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran only read-only git verbs: `git rev-parse`, `git log -1`, `git status`, `git diff`, `git diff --name-only`, `git diff --stat`. No `add`/`commit`/`apply`/`stage`/`push`/etc. No `changes.patch` produced (patch is post-review-clean only). | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op run. The two STRIP rewords are in-place Edits on quoted anchors; no file deletion/overwrite of trusted content. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted exactly ONE PREFLIGHT line, AFTER all 4 edits + validate-pack PASS + union-grep + leak-gates + scope all passed. No parent stop/halt received. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All edits targeted Edit calls on quoted anchors. B1 baseRef/permissions.deny JSON blocks KEPT VERBATIM (`git diff` shows them untouched). agent-run.sh launcher-flag KEEP lines L173-176/L250-251/L609 untouched. No needless full rewrite. | COMPLIANT |
| **skill-agent-maintenance-mechanical** | S17 edit is a CONTENT edit to the skill body only: `git diff` shows the frontmatter (`name`/`description`/`allowed-tools`) and the numbered list (1-15) unchanged; validate-pack Check 1 "OK: skills/implementation/SKILL.md"; skill-count/frontmatter checks pass; `x-` contract not touched. | COMPLIANT |
| **worktree-isolation-mergeback-ops** | Verified pwd/HEAD at runtime: pwd = isolated worktree `.../agent-a8aa498bbedb833cd`, HEAD = `46dce4d`. Patch NOT produced (post-review-clean only). No commit/apply. Report → named `/tmp/handoff-bd226-C6/IMPL-REPORT.md`. | COMPLIANT |
| **enumerate-encoding-surfaces** | Edited each named C6 surface; S17 single source (installs to 3 client dirs) edited once; no validator/test asserts the OLD text — validate-pack exit 0 with the new text (no test edit needed). | COMPLIANT |
| **pack-project-separation-of-concerns** | `git diff --name-only` = 4 paths, all under `project-template/`; `grep -vE "^(project-template/|supporting-docs/)"` → no output. NO pack path touched. | COMPLIANT |
| **boundary-investigation-precedes-pack-defaults (P-missed-7)** | All edits use project terms ("the PM chat", "your `coder`/`reviewer`"). `git diff '^\+'` scan for `Pack Chat`/`pack-*`/`pack-ops/`/BD-NNN/graphify → NO LEAK IN ADDED LINES. agent-run.sh xref KEPT the existing `docs/pack/PM-CHAT.md "In-session agent spawning"` label (no invented heading). | COMPLIANT |
| **bd-pack-only-operational-rule** | `grep -rnE "BD-[0-9]"` over all C6-scope files = 0. Cross-CLI-serial deferral expressed as "tracked separately"/"a future pack version" (S12) — no `BD-NNN`. | COMPLIANT |
| **cross-cli-reference-normalization** | Project restatements audience-correct (project agent names, "the PM chat"); rule-4 re-engagement uses the design's project phrasing ("Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh coder"), not the pack's SendMessage-as-universal framing. | COMPLIANT |
| **rename-plans-measure-then-bound** | Completeness check = C6-files union grep (§5.1 phrase set) + KEEP allowlist. Ran it (§2.2): STRIP set = 0; residual = only the launcher-flag + B1-verbatim + unrelated-section KEEPs, each classified. | COMPLIANT |
| **graph-first-context** | grep/Read used as authoritative throughout (graphify-out/ not in this worktree — injected path). NO graph content added to any C6 surface (project surfaces carry no Graphify). graph leak gate = 0. | COMPLIANT |
| **rules-applied-verification-block** | This table — each rule has a measurement/quote + a terminal conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |
