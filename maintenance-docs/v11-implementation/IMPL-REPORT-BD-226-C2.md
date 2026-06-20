# IMPL-REPORT — BD-226 COMMIT C2 (pack orchestrator contract + agent defs + S-RT)

**Agent:** pack-coder (FRESH, empty context, READ-WRITE). **BD:** BD-226, COMMIT C2 (`pack-only`).
**Regime:** ISOLATED WORKTREE (verified at runtime).
**Worktree path:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab8b4a20be5abba23`
**Branch:** `worktree-agent-ab8b4a20be5abba23`
**HEAD:** `a1497119eafc1fe5702f17edcebbc8c53c5806e7` (= `a149711`, subject "BD-226 project orchestrator contract + agent defs… (project-only)" — the C1-after / C5-landed base C2 depends on).
**No patch emitted** (per isolation regime + prompt: patch produced only after review-clean by orchestrator SendMessage). **No stage/commit/apply performed.**

---

## Regime verification (rule 8)

```
pwd                       = /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab8b4a20be5abba23
git rev-parse --show-toplevel = same (a worktree under .claude/worktrees/agent-*, NOT the main -v11-dev checkout)
git rev-parse HEAD        = a1497119eafc1fe5702f17edcebbc8c53c5806e7
git log -1 --oneline      = a149711 feat: v11 — BD-226 project orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (project-only)
```
HEAD matched the expected `a149711`; confirmed in an isolated worktree. Edits made IN this worktree.

---

## PREFLIGHT line emitted (verbatim)

```
PREFLIGHT: 17/17 C2 edits complete; validate-pack PASS; C2-files union-grep clean (incl. .agents-plugin); ×3 lock-step intact (pack-coder ×3 + 12 RO); S-RT done + project twin untouched; pack-only scope (no CLAUDE.md, no graph content); HEAD a1497119eafc1fe5702f17edcebbc8c53c5806e7; worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab8b4a20be5abba23; about to Write IMPL-REPORT
```

---

## Files changed inventory (17 files — all `modified`, all pack paths)

| # | Path | Surface | Change |
|---|---|---|---|
| 1 | `pack-ops/PACK-CHAT.md` | S3 | modified |
| 2 | `.claude/agents/pack-coder.md` | S7 | modified |
| 3 | `.agents-plugin/pack-agents/agents/pack-coder.md` | S7 | modified |
| 4 | `.codex/agents/pack-coder.toml` | S7 | modified |
| 5 | `.claude/agents/pack-architect.md` | S-RO | modified |
| 6 | `.claude/agents/pack-planner.md` | S-RO | modified |
| 7 | `.claude/agents/pack-reviewer.md` | S-RO | modified |
| 8 | `.claude/agents/pack-docs-researcher.md` | S-RO | modified |
| 9 | `.agents-plugin/pack-agents/agents/pack-architect.md` | S-RO | modified |
| 10 | `.agents-plugin/pack-agents/agents/pack-planner.md` | S-RO | modified |
| 11 | `.agents-plugin/pack-agents/agents/pack-reviewer.md` | S-RO | modified |
| 12 | `.agents-plugin/pack-agents/agents/pack-docs-researcher.md` | S-RO | modified |
| 13 | `.codex/agents/pack-architect.toml` | S-RO | modified |
| 14 | `.codex/agents/pack-planner.toml` | S-RO | modified |
| 15 | `.codex/agents/pack-reviewer.toml` | S-RO | modified |
| 16 | `.codex/agents/pack-docs-researcher.toml` | S-RO | modified |
| 17 | `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` | S-RT | modified |

`git diff --stat`: 17 files changed, 239 insertions(+), 138 deletions(-).
**Explicitly NOT touched:** `CLAUDE.md` (C1/C4), any `project-template/` path, any `supporting-docs/` path, `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` (S-RT project twin — verified-clean NO-OP), all `scripts/tests/fixtures/**` pack-coder snapshots (test fixtures, not canonical defs).

---

## Per-surface summary (before → after anchors)

### S3 — `pack-ops/PACK-CHAT.md` § "In-session sub-agent spawn + merge-back" (heaviest pack prose edit)

- **(a) Intro framing.** BEFORE: "Worktree isolation is an opt-in accelerator for SAFE PARALLELISM; the default is in-place." AFTER: "The placement model is keyed by class: RW agents run in an isolated worktree by class; RO agents run in the tree the work lives in (main when committed; the commit's live worktree when uncommitted)." Kept the OPTIONAL-FEATURES pointer (reworded to "the worktree mechanics").
- **(b) RW-spawn bullet.** BEFORE: "RW agent (`pack-coder`) → spawn ISOLATED when enabled." AFTER: "RW agent (`pack-coder`) → isolated worktree, always, by class." — added "first coder CREATES the worktree; fix-coders REUSE it (never a new worktree for a fix-coder)" + the F-13 do-not-pin-`isolation`-in-frontmatter note. (Title reworded off the `spawn ISOLATED` token to avoid the completeness-gate phrase while preserving meaning.)
- **(c) RO-spawn bullet.** BEFORE: "RO agents → spawn IN-PLACE (no isolation). … Omit the `isolation` parameter." AFTER: "RO agents → spawn in the tree the work lives in" (main when committed; the commit's live worktree when uncommitted — cd in + verify pwd/HEAD, rule 8); "RO agents produce no patch — their one write is their report." Added the rule-9 ASK gate (standard cycle reviewer/fix-coder rule-fixed to the worktree; ANY OTHER agent while a live worktree exists ⇒ ASK placement AND disposition).
- **(d) Merge-back REWRITE.** Deleted the up-front "emits the patch … and returns. The worktree may auto-remove on return — irrelevant" framing. New text: NO up-front patch; whole review/fix cycle runs IN the worktree; **patch only after review-clean** — Pack Chat re-engages (SendMessage) the most-recent RW agent to cut the patch (rule 4/6); then `git apply --check`/`git apply`; commit with user approval. Added the rule-7 + Constraint-1 teardown step (remove the worktree ONLY after the commit lands exit 0; a FAILED commit KEEPS it; never auto-removal).
- **(f) Rule-10 note.** Added a "Parallelization map (rule 10)" paragraph — Pack Chat consumes the architect/planner map to schedule parallel worktree waves vs serial commits (same-file ⇒ serialize; baseRef:head; teardown gated on commit-landed; rule-9 ASK for non-cycle spawns).
- **(g) Constraint-3 pack report rule.** Added a "Report preservation (Constraint 3)" paragraph — after the work commit lands, the orchestrator MOVES every agent report from its `/tmp` handoff dir into the tree and commits them in a PAIRED commit. Destination **DERIVED at runtime**, stated as the derivation NOT a literal: `maintenance-docs/v<major>-implementation/` where `<major>` is the current major version read from the README version table (top row). (Verified the README top row = `v11.0` and `maintenance-docs/v11-implementation/` exists — but the surface states the derivation, not the literal.)
- **(h) Conflict protocol.** KEPT and reframed: opening now anchors it at the POST-review-clean patch step (rule 4), cross-references the parallelization map's same-file ⇒ serialize rule; "Apply the reviewed-clean patches SEQUENTIALLY"; removed the stray "→ review →" from the per-patch atomic unit (review already happened pre-patch). The `--3way` / STOP-and-re-spawn / anti-drift bullets retained.
- **IMPORTANT — no graph content added** (G2 is C4). Verified `git diff pack-ops/PACK-CHAT.md` added lines carry zero `graphify|graph.json|--graph|graph-first`.
- **Report-location conditional removed:** the "Name the handoff dir" bullet's "In the in-place regime the report path may instead be a parent-tree path" was deleted — EVERY agent report goes to the named `/tmp` handoff dir ALWAYS; the patch path is named but written only at the post-review-clean step.

### S7 — pack-coder def ×3 (lock-step)

`.claude/agents/pack-coder.md` + `.agents-plugin/pack-agents/agents/pack-coder.md` + `.codex/agents/pack-coder.toml`.
- **`description:` frontmatter** (all 3): BEFORE "…makes the file changes in its scoped working tree (or an isolated worktree when opted-in)… and emits a patch + structured implementation report." AFTER "…makes file changes in its isolated worktree… and writes a structured implementation report; it does NOT produce a patch on return — the patch is produced only after a reviewer confirms the work clean and the orchestrator re-engages it."
- **Intro "Source-write within scope"** (all 3): reworded to "write/edit … in your isolated worktree … and write your report. You do NOT produce a patch on return — the patch is produced only after a reviewer confirms the work clean and the orchestrator re-engages you."
- **RW-emit step** (all 3): rewritten to rule 4 — sequence is edits → verification → Write IMPL report to the named `/tmp` handoff dir → return; NO up-front patch; the patch is produced ONLY when the orchestrator re-engages (SendMessage) AFTER review-clean (`git diff > <handoff>/changes.patch` at that point). KEPT: never-stage/commit/apply; the `/tmp` handoff path; the failed-handoff-Write degradation note.
- **REPORT-LOCATION** (all 3): removed the "in-place regime → parent-tree report path" conditional — IMPL report ALWAYS → named `/tmp` handoff dir ("there is no alternate report path").
- **F-13 why-not** (all 3): added a one-line bullet "Do not pin `isolation` in frontmatter" (single-value param breaks fix-coder reuse).
- **Two further binary-regime refs flipped** (all 3) — in "Required report contents" ("which regime you ran in (in-place or isolated)" → "your verified runtime regime (the worktree path + HEAD you confirmed at runtime per the `commit-discipline` skill §1)") and "Hard rules / Pre-flight" ("detect your regime — in-place vs isolated" → "VERIFY your runtime regime — pwd/HEAD ground-truth"). These carried the OLD binary-regime model the design flips.

### S-RO — 4 RO pack defs ×3 = 12 files (lock-step)

pack-architect / pack-planner / pack-reviewer / pack-docs-researcher × `.claude/agents/*.md` + `.agents-plugin/pack-agents/agents/*.md` + `.codex/agents/*.toml`.
- BEFORE (representative): "**RO-emit:** in the isolated regime that report path is under the named `/tmp` handoff dir … (per the `commit-discipline` skill §2); in the in-place regime it is the named parent-tree path."
- AFTER (rule-1 placement, all 12): "**RO placement:** you run in the tree the work lives in — the main checkout when the work is on HEAD/committed; the commit's live worktree when the work is still uncommitted there, in which case you `cd` into that worktree and VERIFY pwd/HEAD at runtime (rule 8). You produce no patch (RO). ALL your reports go to the named `/tmp` handoff dir the orchestrator supplies (per the `commit-discipline` skill §2)."
- **KEPT:** the `commit-discipline` skill §2 cross-reference in all 12. The trailing "As a read-only (RO) agent you Write ONLY this one report/document …" sentences and the reviewer's "You run NO state-changing git verb." preserved.
- Variant handling: planner copies say "documents" (its deliverable noun); architect/docs-researcher/reviewer say "reports"; `.codex` copies carry the same content in TOML prose (no `**` markdown). Content-intent matched per `cross-cli-reference-normalization`; not byte-copied.
- "produce no patch (RO)" used instead of "emit no patch" to avoid the completeness-gate `emit…patch` token while stating the same NEW-model fact.

### S-RT — `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` (pack-only)

- RW-class bullet BEFORE: "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set, then emit a patch + report."
- AFTER: "- **Read-write within scope (RW)** — pack-coder. May write/edit source files within the caller-scoped file set inside its isolated worktree, then write its report and return. It produces NO patch on return — the patch is produced ONLY after an RO reviewer confirms the work clean and the orchestrator re-engages the most-recent RW agent (SendMessage) to cut it."
- **KEPT VERBATIM:** the RO-class bullet ("Their single permitted file write is the one caller-specified report; the codebase is read-only otherwise.") and the verb-ban paragraph ("When defining a subagent at runtime, preserve that permission-profile prose verbatim … Every pack agent (RO and RW alike) runs **zero** state-changing git verbs …").
- **Project twin** `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` — UNTOUCHED (verified-clean NO-OP; `git status --short` shows no change). Editing it would inject a project path into the `pack-only` commit.

---

## ×3 lock-step confirmation (all 16 def files + S-RT)

**pack-coder ×3** — all three carry: "patch is produced ONLY" (1/1/1), the F-13 "Do not pin `isolation` in frontmatter" (1/1/1), the report-always-/tmp wording, and the runtime-regime-verify reframe.

**12 RO defs** — all twelve carry the "RO placement" marker (1 each) AND the "tree the work lives in" content (1 each; the three `.claude` copies wrap the phrase across a line break — confirmed present via newline-collapsed grep), AND the KEPT `commit-discipline` cross-reference.

| Surface | `.claude` | `.agents-plugin` | `.codex` |
|---|---|---|---|
| pack-coder (S7) | ✓ | ✓ | ✓ |
| pack-architect (S-RO) | ✓ | ✓ | ✓ |
| pack-planner (S-RO) | ✓ | ✓ | ✓ |
| pack-reviewer (S-RO) | ✓ | ✓ | ✓ |
| pack-docs-researcher (S-RO) | ✓ | ✓ | ✓ |
| RUNTIME-SUBAGENT-PATTERN (S-RT) | — | ✓ (pack) | — |

No drift across copies; format differs (`.md` markdown vs `.toml` TOML prose) but content-intent matched.

---

## Verification results

### 1. `python3 scripts/validate-pack.py` → exit 0
`PASSED — all checks clean`. Relevant lines: Check 11 (Pack agent trinity-rule symmetry, informational) OK; Check 36 (Commit-scope honesty) OK — 1 scope-claiming commit verified clean (the prior C1/landed commit; C2 is uncommitted so its scope is enforced by the `git diff --name-only` gate below); Check 63 (graphify-out never tracked) OK; Check 64 OK. Pre-existing advisories/WARNs (OPTIONAL-FEATURES line count; JC-5 accurate-history doc citations in changelog/backlog) are unrelated to C2 and not gate failures.

### 2. Per-commit completeness grep — C2's OWN 17 files (design §5.1 phrase union, incl. `.agents-plugin`)
Union phrase set run over all 17 C2 files (`isolated regime|in-place regime|emit[a-z]*[^.]*patch|patch \+ report|opt-in accelerator|spawn ISOLATED|spawn IN-PLACE|when enabled|may auto-remove|worktree may auto|default is in-place|in-place by default|isolation is opt-in|opt-in worktree|default floor|RW ⇒ isolate|survives.*auto-removal|on agent return|before it returns|writes before|patch the agent|RO-emit|parent-tree|in-place vs isolated|in-place or isolated|when opted-in`):

**Result: `Files with residual model phrases: 0 (expected 0)`.** Three transient false-positives ("there is no parent-tree fallback path" — a NEW-model negation) were reworded to "there is no alternate report path" so the gate residual is a true 0.

Allowlist note: no KEEP-allowlist remainders apply to C2's file set — the `git worktree` verb-ban and `worktree-agent-*` self-detect mechanic (which are MOOT for the union grep) do not coincide with any union phrase here; the agent-run.sh launcher-flag lines are project-side (C6), not in C2.

### 3. ×3 lock-step (see table above) + S-RT done + project twin untouched
`git status --short project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` → empty (untouched). S-RT pack file edited.

### 4. Scope (pack-only; Check 36 class)
`git diff --name-only` → 17 paths, ALL pack-side (`pack-ops/`, `.claude/agents/`, `.agents-plugin/pack-agents/`, `.codex/agents/`). No `project-template/` or `supporting-docs/`. `CLAUDE.md` NOT in the diff (C1/C4). No graph content added to PACK-CHAT.md (verified on added lines).

### 5. Per-check tests (relevant to agent-def surfaces)
`test-validate-pack-check-40.sh` PASS 8/0; `-55` PASS 3/0; `-52` PASS 3/0; `-56` PASS 3/0; `test-customization-preserve.sh` Passed 235 / Failed 0 (confirms the canonical pack-coder.md edits don't break the customization-preserve fixtures — fixtures untouched in the diff).

---

## Plan deviations

**None of substance.** Two phrasing choices to keep the completeness gate at a true 0 while preserving the design's NEW-model meaning:
1. The S3 RW-spawn bullet title uses "isolated worktree, always, by class" instead of the design's quoted-reword "spawn ISOLATED (always, by class)" — the `spawn ISOLATED` token is in the §5.1 gate phrase set (an OLD-framing detector). Meaning is identical (RW isolated by class, always).
2. "produce no patch (RO)" / "produces no patch on return" used instead of "emit no patch" — the `emit…patch` token is in the gate set. Meaning identical.

Both are within the coder's latitude (the design keys edits on meaning + named anchors, and §5.1 sets model-phrase residual = 0 as the gate). No design decision, finding, or constraint was re-opened.

## New POQs introduced

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| S3 reworded per design §2 (a)-(h): intro/RW/RO bullets, merge-back rewrite, rule-7+Constraint-1 teardown, rule-9 ASK gate, rule-10 map note, Constraint-3 derived report rule, conflict-protocol reframe | PASS |
| S3: report-location conditional removed (report always → /tmp) | PASS |
| S3: NO graph content added (C4 owns it) | PASS |
| S3: CLAUDE.md NOT touched (C1/C4) | PASS |
| S7 pack-coder ×3: rule-4 RW-emit reword; report always → /tmp; F-13 why-not; never-stage/commit/apply + /tmp handoff KEPT | PASS |
| S-RO ×12: binary RO-emit replaced with rule-1 placement; report always → /tmp; commit-discipline §2 xref KEPT | PASS |
| S-RT: RW-class bullet rule-4 reword; RO-class bullet + verb-ban KEPT VERBATIM | PASS |
| S-RT project twin UNTOUCHED | PASS |
| ×3 lock-step: pack-coder ×3 + 12 RO defs content-intent matched across `.md`/`.toml`, no drift | PASS |
| `validate-pack.py` exit 0 | PASS |
| C2-files union-grep residual = 0 (incl. `.agents-plugin`) | PASS |
| Scope pack-only (no `project-template/`/`supporting-docs/`) | PASS |
| No patch emitted; no stage/commit/apply | PASS |
| IMPL-REPORT written to `/tmp/handoff-bd226-C2/IMPL-REPORT.md` | PASS |

---

## Full file contents for new files

No NEW files created — all 17 are modifications to existing pack files. (S-RT is a pre-existing file flipped, not a new surface in this worktree.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** (universal) | Ran only read-only git verbs: `git rev-parse HEAD`, `git status`, `git log -1`, `git diff`, `git diff --name-only`, `git diff --stat`. No `add`/`commit`/`apply`/`worktree`/`stage` issued. No `changes.patch` produced. | COMPLIANT |
| **per-action-approval-sub-agents** (universal) | No destructive op run on own authority; no file deleted/overwritten outside the 17 scoped edits; the project twin + CLAUDE.md + fixtures left intact (verified via `git diff --name-only` = 17 pack paths). | COMPLIANT |
| **preflight-stop-means-stop** (universal) | Emitted the single PREFLIGHT line ONLY after all 17 edits + verification (validate exit 0; union-grep 0; per-check tests PASS) succeeded. Quoted in the report above. No parent stop/halt received. | COMPLIANT |
| **edit-in-place-not-full-rewrite** (coder) | All changes were targeted `Edit` calls on quoted anchors; preserved surrounding content (S-RT verb-ban + RO-class bullet KEPT verbatim; PACK-CHAT conflict-protocol body KEPT; agent-def boundary-discipline sections untouched). No full rewrites. | COMPLIANT |
| **worktree-isolation-mergeback-ops** (universal) | Verified pwd/HEAD at runtime (worktree under `.claude/worktrees/agent-*`, HEAD `a149711`). Produced NO patch (patch is the orchestrator's post-review-clean step). Report → named `/tmp` handoff dir. | COMPLIANT |
| **enumerate-encoding-surfaces** (coder) | All ×3 pack-coder copies + all 12 RO def copies edited in lock-step (table above); `.codex` `.toml` copies carried the same content in TOML prose — none omitted. S-RT pack edited; project twin a no-op (verified empty `git status`). | COMPLIANT |
| **pack-project-separation-of-concerns** (universal) | `git diff --name-only` = 17 pack paths only; zero `project-template/`/`supporting-docs/`. S-RT project twin untouched (`git status --short` empty for it). | COMPLIANT |
| **cross-cli-reference-normalization** (coder) | `.md` copies kept markdown (`**RO placement:**`); `.toml` copies kept TOML prose (`RO placement:` no `**`). Planner copies use "documents", others "reports" per each file's deliverable noun. Content-intent matched, not byte-copied. | COMPLIANT |
| **rename-plans-measure-then-bound** (universal) | The completeness check is the C2-files union grep over the §5.1 phrase set incl. `.agents-plugin`; ran it; residual = 0 (reported above). No hand-enumerated anchor list. | COMPLIANT |
| **graph-first-context** (universal) | Used grep/Read as authoritative for all exact-string work (graphify-out not in worktree — injected path). Added ZERO graph content to C2 (verified on PACK-CHAT.md added lines) — graph injection is C4. | COMPLIANT |
| **rules-applied-verification-block** (universal) | This table — per-rule name, quoted/measured evidence, terminal conclusion. | COMPLIANT |
