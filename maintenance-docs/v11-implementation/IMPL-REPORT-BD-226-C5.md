# IMPL-REPORT — BD-226 COMMIT C5 (project orchestrator contract + agent defs)

**Agent:** pack-coder (FRESH, isolated-worktree regime). **Repo:** optiquity-ai-agent-config-pack.
**Branch:** `worktree-agent-a0b8a2ce7dde05dfe`
**HEAD (unchanged — no commit):** `ba3bb08f4a532f3cad189dbcd77ba90d1844b0bc` (C1: "BD-226 pack trinity + class SSOT…")
**Worktree path:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a0b8a2ce7dde05dfe`
**Regime:** ISOLATED (verified at runtime: pwd == toplevel == the `agent-*` worktree, NOT the main `-v11-dev` checkout; HEAD == ba3bb08).
**Scope:** `project-only` — touched ONLY `project-template/` paths (Check 36 clean).
**Patch:** NOT emitted (per the isolated regime: edits + report only; the orchestrator re-engages me after review-clean to produce `changes.patch`). NO `changes.patch` in the handoff dir.

---

## PREFLIGHT (re-emitted after the user-approved POQ-C5-1 fix)

```
PREFLIGHT: 10/10 C5 edits complete (incl. user-approved POQ-C5-1 fix —
PM-CHAT.md Permission-classes RW bullet flipped to post-review-clean);
validate-pack PASS; C5-files union-grep clean over PM-CHAT.md INCLUDING the
Permission-classes section (model-phrase residual 0 — OLD "patch plus a
report" / "then emit a patch" fully removed; remaining "emit...patch" hits
are the NEW-model negated phrase "does NOT emit a patch up front");
project leak gates 0/0/0 (BD-NNN 0, graphify 0, pack-self leak 0 in edits —
pre-existing PM-CHAT L342/L344 untouched); ×3 lock-step intact (coder ×3 +
repo-ops ×3, content-intent matched, verb-ban git worktree verbatim ×3);
project-only scope (0 non-project-template files);
HEAD ba3bb08f4a532f3cad189dbcd77ba90d1844b0bc;
worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a0b8a2ce7dde05dfe;
about to update IMPL-REPORT
```

**Prior PREFLIGHT (initial 9/9 pass, before the POQ-C5-1 follow-up):** 9/9 C5
edits complete; validate-pack PASS; C5-files union-grep clean; leak gates
0/0/0; ×3 lock-step intact; project-only; HEAD ba3bb08.

---

## Files changed (inventory)

| Path | Change type | Δ (git diff --stat) |
|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | modified (S10 + POQ-C5-1) | 172 changed / heaviest |
| `project-template/.claude/agents/coder.md` | modified (S13) | ~39 |
| `project-template/.agents-plugin/optiquity-agents/agents/coder.md` | modified (S13) | ~39 |
| `project-template/.codex/agents/coder.toml` | modified (S13) | ~4 (single-line TOML prose) |
| `project-template/.claude/agents/repo-ops.md` | modified (S13b, ADD para) | +23 |
| `project-template/.agents-plugin/optiquity-agents/agents/repo-ops.md` | modified (S13b, ADD para) | +23 |
| `project-template/.codex/agents/repo-ops.toml` | modified (S13b, ADD para) | +2 (single-line TOML prose) |

Total: 7 files, 213 insertions / 89 deletions. **All under `project-template/`** → project-only. (PM-CHAT.md now carries both the S10 region edits AND the user-approved POQ-C5-1 Permission-classes RW-bullet flip.)

---

## Per-surface summary

### S10 — `project-template/docs/pack/PM-CHAT.md` (heaviest project edit)

Four edit blocks in the § "Isolation is for read-write agents only" + "Merge-back" region (L470+), all audience-correct ("the PM chat", `coder`/`repo-ops`, no `pack-*`, no BD-NNN, no graph note).

**(a) "Isolation is for read-write agents only" paragraph — reworded.**
- BEFORE anchor: `"The class is the single fact that decides this: RW ⇒ isolate; RO ⇒ in-place."` + the opt-in spawn framing ("it spawns that agent with the worktree-isolation parameter").
- AFTER: "**Read-write agents (`coder`, `repo-ops`) run in an isolated worktree by class** (not opt-in): the first coder of a commit CREATES a fresh isolated worktree, and every subsequent read-write agent in that commit's cycle — fix-coders included — REUSES that same worktree (never a new worktree for a fix-coder)… **Read-only agents … run in the tree the work lives in** — your main checkout when the work is committed, the live worktree when the work is still uncommitted (cd into that worktree and VERIFY pwd/HEAD at runtime)."
- **F-13 why-not (SINGLE HOME for both RW agents)** added as a dedicated paragraph: "Do **NOT** pin `isolation:"worktree"` in any read-write agent's definition frontmatter. The parameter has only the one value `"worktree"`, so a frontmatter pin would force a NEW worktree on every spawn — and a fresh fix-coder could then not reuse the first coder's worktree…"

**(b) "no platform safety net" paragraph — flip opt-in → class-default (kept the load-bearing/no-safety-net framing).**
- BEFORE anchor: `"every read-write agent MUST be spawned with isolation:"worktree""`.
- AFTER: "by class, every read-write agent runs in an isolated worktree (the first coder of a commit creates it; later read-write agents reuse it)…".

**(c)+(d) "Merge-back" — REWRITTEN to the post-review-clean model.**
- DELETED the up-front framing `"The PM chat brings its edits back via a patch the agent writes before it returns:"` and the step-2 "emits the patch … then returns" ordering.
- Rewrote to: the whole review/fix cycle runs INSIDE the commit's worktree; the agent's on-return deliverable is its REPORT only (no patch up front); **ONLY after a read-only reviewer confirms the work clean** does the PM chat produce the patch by **re-engaging the most-recent read-write agent** — phrased per the design's project re-engagement clause: "re-engage the most-recent read-write agent (in Claude Code, via the Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh `coder` against the worktree to produce the patch)"; THEN the PM chat applies (`git apply --check`/`git apply`) + commits.
- **Rule-7 + Constraint-1 teardown** ADDED ("Remove the worktree only AFTER the commit lands" paragraph): remove orphaned worktrees only after the commit lands (exit 0), never right-after-use, never via auto-removal; **a FAILED commit KEEPS its worktree.**
- **Constraint-3 project report-preservation rule** ADDED ("Preserve the reports" paragraph): after a commit lands the PM chat MOVES every agent report from `/tmp` into the tree (paired commit); destination DERIVED at runtime — a dedicated `docs/impl-reports/**` subtree (NEW; keeps reports OUT of the installed `docs/` content), organized by the current phase read from the implementation-plan stream (`docs/project/implementation-plan/`) → `docs/impl-reports/<current-phase>/`. **Derivation stated, not a baked path.** Verified `docs/impl-reports/` is ABSENT today (NEW subtree the rule introduces by derivation).
- **Rule-9 live-worktree ASK gate** ADDED ("Ask before reusing a live worktree for off-cycle work"): commit's own reviewer/fix-coder rule-fixed (no ask); any OTHER agent spawned while a live worktree with uncommitted work exists → PM chat ASKS the developer BOTH (i) PLACEMENT and (ii) DISPOSITION (reuse vs abandon), never self-decides.
- **Rule-10 parallelization-map note** ADDED ("Plan parallel vs serial from the dependency map"): the PM chat consumes the architect/planner parallelization+dependency map to schedule parallel worktree waves vs serial commits.

**(e) Conflict protocol — KEPT, reframed to the post-review-clean apply step.**
- "On conflict, do not hand-merge" retained; reframed `git apply --check` failure to "at the apply step", cross-referenced the dependency map keeping same-file commits serialized; kept the OPTIONAL-FEATURES.md degradation xref.

**(f) POQ-C5-1 fix (user-approved, now in-scope) — § "Permission classes (read-write / read-only)" RW-class bullet flipped to post-review-clean.**
- BEFORE anchor: `"RW agents may write or edit files within the explicit scope the prompt defines, **then emit a patch plus a report.**"` (OLD up-front-patch model; the project twin of pack S4 / S-RT, which are flipped pack-side).
- AFTER: "RW agents run in an isolated worktree by class; they write or edit files within the explicit scope the prompt defines and produce a report on return. The patch is produced only AFTER review-clean — the PM chat re-engages the most-recent read-write agent to emit it, then applies it (see "Merge-back" below). They NEVER stage or commit…".
- **KEPT unchanged:** the "concurrent RW agents on non-overlapping scopes" guidance (rest of the bullet), the RO bullet, and the shared hard-rule paragraph (all correct). Cross-references the "Merge-back" section rather than duplicating the full contract. Audience-correct ("the PM chat").
- This closes the §5.1 batch-end PROJECT union-grep exposure: the OLD `patch plus a report` phrase is now removed tree-wide (`grep -rn "patch plus a report\|then emit a patch" project-template/` → exit 1, no match).

### S13 — project coder def ×3 (lock-step)

Copies: `project-template/.claude/agents/coder.md`, `…/.agents-plugin/optiquity-agents/agents/coder.md`, `…/.codex/agents/coder.toml` (TOML single-line prose — same content-intent, not byte-copied).

- **"Merge-back" block reworded** from the binary isolated/in-place framing.
  - BEFORE anchor: `"**Merge-back: emit a patch, never commit.**"` … "When the calling prompt names a `/tmp` handoff directory (the isolated regime), your sequence is: … emit the change set … (`git diff > <handoff>/changes.patch`) → write your report → return. The PM chat … applies the patch itself. … When no handoff directory is named (the in-place regime), leave the edits…".
  - AFTER: "**Merge-back: report and return; the patch comes only after review-clean.**" — edits → verification → write report to the named `/tmp` handoff dir → return; **no patch up front**; the patch is emitted ONLY after a read-only reviewer confirms clean and the PM chat re-engages you; the PM chat applies + commits.
  - **REPORT-LOCATION:** the in-place conditional REMOVED — "Your report ALWAYS goes to the named `/tmp` handoff directory."
- **"No platform safety net — spawn isolation is load-bearing" flipped opt-in → class-default** (kept the no-safety-net framing): "by class you run in an isolated worktree (the PM chat spawns the first coder of a commit with worktree isolation and re-engages later read-write agents into that same worktree)…".
- **F-13 why-not (one line):** "(The PM chat passes isolation per-spawn; it does NOT pin `isolation:"worktree"` in your definition frontmatter — a pin would force a new worktree per spawn and break fix-coder reuse. See `docs/pack/PM-CHAT.md` § "Isolation is for read-write agents only".)" — pointer to the PM-CHAT.md HOME, as designed.

### S13b — project repo-ops def ×3 (lock-step, F-6 coder-twin)

Copies: `project-template/.claude/agents/repo-ops.md`, `…/.agents-plugin/optiquity-agents/agents/repo-ops.md`, `…/.codex/agents/repo-ops.toml`.

- repo-ops had NO "Merge-back" section. **ADDED the SAME class-default merge-back paragraph coder gets**, symmetric, inserted after the "Write-capable (script)" Permission-profile paragraph (before `## Output policy`): repo-ops is an RW agent → runs in an isolated worktree by class; scripted writes + verification → report to named `/tmp` handoff dir → return; patch only after review-clean when the PM chat re-engages it; never stage/commit/apply.
- **Empty-patch note included** (settled design note): "If your task legitimately produces only gitignored generated artifacts, an EMPTY patch is the expected handoff (the work still ran in the isolated worktree)."
- **`git worktree` verb-ban line KEPT VERBATIM** in all 3 copies (the universal verb-ban — the harness creates the worktree; NOT an isolation barrier). Verified intact ×3.
- **F-13 why-not (one line):** same PM-CHAT.md pointer as coder.

---

## ×3 lock-step confirmation

Content-intent verified across each triad (multiline-collapsed grep; the `.md` copies wrap, the `.toml` is single-line — same intent, not byte-copied):

**Coder ×3** — all carry: "the patch comes only after review-clean" header; "ONLY after a read-only reviewer confirms the work clean does the PM chat re-engage you"; "Your report ALWAYS goes to the named … handoff directory"; "by class you run in an isolated worktree"; F-13 no-pin + PM-CHAT.md pointer. ✔ 3/3 each.

**repo-ops ×3** — all carry: "the patch comes only after review-clean" header; "You are a read-write agent, so by class you run in an isolated worktree"; "EMPTY patch is the expected handoff"; F-13 no-pin + PM-CHAT.md pointer; `git worktree` verb-ban verbatim. ✔ 3/3 each.

---

## Verification results

| Check | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **EXIT 0 — PASSED** (all checks incl. Check 36 commit-scope, Check 18 trinity H2 parity, Check 45 rationale bijection, Check 62, Check 64). |
| **C5-files union OLD-model grep** (design §5.1 union phrase set over the 7 C5 files, incl. the PM-CHAT.md Permission-classes section) | **model-phrase residual = 0.** The OLD `patch plus a report` / `then emit a patch` phrase is now removed tree-wide (`grep -rn "patch plus a report\|then emit a patch" project-template/` → exit 1). The only `emit[a-z]*[^.]*patch` regex matches are NEW-model phrasing ("does NOT emit a patch up front" / "the one moment a patch is emitted, never before") — correct, not OLD-model. No `isolated regime` / `in-place regime` / `RW ⇒ isolate` / `patch the agent leaves` / `before it returns` / `persisted artifact` residual in the edited surfaces. KEEP allowlist for C5 = the `git worktree` verb-ban (MOOT — never coincides with a union phrase). |
| **Leak gate 1 — `BD-[0-9]`** over the 7 C5 files | **0 hits.** |
| **Leak gate 2 — `graphify\|graph\.json\|--graph`** over the 7 C5 files | **0 hits.** |
| **Leak gate 3 — pack-self (`Pack Chat`/`pack-ops/`/`pack-coder`/`pack-reviewer`/`pack-architect`/`pack-planner`)** in my EDITS | **0 in edits.** Only pre-existing PM-CHAT.md L342/L344 "Pack Chat" refs remain — OUTSIDE the S10 edit region (L470+), untouched, NOT introduced by me (F-F). My edited text uses "the PM chat" (27 occurrences in PM-CHAT.md). |
| **Scope (Check 36 / project-only)** | `git diff --name-only` → 0 non-`project-template/` files. |
| **repo-ops verb-ban `git worktree`** | Intact verbatim in all 3 copies. |

---

## Boundary discipline check (P-missed-7)

Every C5 surface is project-side (`project-template/`). Project-side SSOTs used:
- **`project-template/docs/pack/PM-CHAT.md`** — the project orchestrator-rules SSOT (the project analog of PACK-CHAT.md). S10 restated the worktree model HERE, audience-correctly; the user-approved POQ-C5-1 fix also flipped the § "Permission classes" RW-class bullet (the project class-SSOT statement) HERE, same SSOT, audience-correctly.
- **`project-template/docs/pack/prompts/`** + the per-CLI agent def trees (`.claude/agents/`, `.agents-plugin/optiquity-agents/agents/`, `.codex/agents/`) — the project per-agent def SSOTs. S13/S13b edited the canonical defs, not pack defs.
- **`project-template/docs/project/implementation-plan/`** — the SSOT for "current phase", used to STATE the `docs/impl-reports/<current-phase>/` derivation (not a baked path).

No pack-only reference (`pack-ops/`, `Pack Chat`, `pack-*` agent, `maintenance-docs/`) was added to any project surface. The pack's Agent-Teams framing was NOT imported as a universal project guarantee — rule-4 re-engagement is phrased as the project clause with the Claude-Code parenthetical + a peer-messaging-absent degradation. NO Graphify/graph note added (Graphify is pack-only). **No boundary-discipline STOP.**

---

## Plan deviations

All three C5 surfaces (S10, S13, S13b) implemented exactly per design §2 + the §2 "Audience normalization for EVERY B-surface" + "Project-side rule-4 re-engagement" blocks. No re-design.

**One user-approved in-scope addition:** POQ-C5-1 — the PM-CHAT.md § "Permission classes" RW-class bullet (the project twin of pack S4/S-RT) was reworded to the post-review-clean model. This was surfaced in the initial pass as out-of-scope of the design's named S10 region (L470–532); the user explicitly approved fixing it NOW, in C5, as part of the same project-only PM-CHAT.md edit. It is consistent with the pack-side S4/S-RT flip and is NOT a re-design — it applies the already-settled class-default model to the one remaining OLD-model project bullet.

---

## Unplanned modifications

**None.** No file outside the planned 7-file C5 set was modified.

---

## POQ-C5-1 — RESOLVED (user-approved fix, now in-scope for C5)

**POQ-C5-1 — PM-CHAT.md § "Permission classes" RW-class bullet carried OLD-model "then emit a patch plus a report".** Surfaced in the initial 9/9 pass as out-of-scope (outside the design's S10 region L470–532); the user then approved fixing it NOW, in C5, same project-only commit. **Fixed in this follow-up.**

- **What it was.** `project-template/docs/pack/PM-CHAT.md` § "Permission classes (read-write / read-only)" **Read-write (RW)** bullet read: *"RW agents may write or edit files within the explicit scope the prompt defines, **then emit a patch plus a report.**"* — OLD up-front-patch framing; the project twin of pack S4 (PACK-AGENTS "Two agent classes" roster, flipped in C1) and pack S-RT (RUNTIME-SUBAGENT-PATTERN RW-class bullet, flipped in C2).
- **The fix (see S10 edit block (f) above).** Reworded to the post-review-clean model, consistent with the S10 "Merge-back" edits and project audience: "RW agents run in an isolated worktree by class; they write or edit files within the explicit scope the prompt defines and produce a report on return. The patch is produced only AFTER review-clean — the PM chat re-engages the most-recent read-write agent to emit it, then applies it (see "Merge-back" below). They NEVER stage or commit…". KEPT the "concurrent RW agents on non-overlapping scopes" guidance; did NOT touch the RO bullet or the shared hard-rule paragraph; cross-referenced "Merge-back" rather than duplicating the contract.
- **Verification of the fix.** OLD phrase removed tree-wide (`grep -rn "patch plus a report\|then emit a patch" project-template/` → exit 1, no match). validate-pack EXIT 0. C5-files union grep over PM-CHAT.md INCLUDING the Permission-classes section → model-phrase residual 0. Leak gates still 0/0/0. Scope still project-only. Audience-correct ("the PM chat").

This closes the §5.1 batch-end PROJECT union-grep exposure that the out-of-scope bullet would otherwise have caused.

---

## New POQ introduced

**None remaining.** POQ-C5-1 (the only one surfaced) is RESOLVED above.

---

## Definition-of-Done checklist

| Item | PASS/FAIL |
|---|---|
| Regime verified at runtime (isolated worktree, HEAD ba3bb08) | PASS |
| S10 (PM-CHAT.md) — isolation paragraph reworded (class-default) | PASS |
| S10 — no-platform-safety-net flipped opt-in → class-default | PASS |
| S10 — Merge-back rewritten (no up-front patch; post-review-clean; re-engagement clause) | PASS |
| S10 — rule-7 + Constraint-1 teardown (failed commit KEEPS worktree) | PASS |
| S10 — rule-9 ASK gate (project phrasing) | PASS |
| S10 — rule-10 parallelization-map note | PASS |
| S10 — Constraint-3 report rule (DERIVED `docs/impl-reports/<current-phase>/`, not baked) | PASS |
| S10 — conflict protocol kept + reframed to post-review-clean | PASS |
| S10 — F-13 why-not SINGLE HOME (both RW agents) | PASS |
| POQ-C5-1 (user-approved) — Permission-classes RW bullet flipped to post-review-clean; OLD "patch plus a report" removed tree-wide | PASS |
| S13 — coder ×3 Merge-back reworded to rule 4 | PASS |
| S13 — coder ×3 report ALWAYS → /tmp (in-place conditional removed) | PASS |
| S13 — coder ×3 load-bearing flipped opt-in → class-default | PASS |
| S13 — coder ×3 F-13 one-line pointer | PASS |
| S13b — repo-ops ×3 class-default merge-back para ADDED (symmetric) | PASS |
| S13b — repo-ops ×3 `git worktree` verb-ban kept VERBATIM | PASS |
| S13b — repo-ops ×3 F-13 one-line pointer | PASS |
| ×3 lock-step (coder + repo-ops) content-intent matched, no drift | PASS |
| validate-pack EXIT 0 | PASS |
| C5-files union grep — model-phrase residual 0 | PASS |
| Project leak gates — BD-NNN 0 / graphify 0 / pack-self 0 in edits | PASS |
| project-only scope (Check 36) | PASS |
| Audience-correct ("the PM chat", no `pack-*`, no BD-NNN, no graph) | PASS |
| No commit / no stage / no apply / no patch emitted | PASS |
| IMPL-REPORT written to handoff path | PASS |

---

## Rules-Applied Verification Block

| Rule name | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran read-only git only (`git rev-parse`, `git status`, `git log`, `git diff --name-only`, `git diff --stat`). `git rev-parse HEAD` = ba3bb08 unchanged (no commit). No `changes.patch` emitted to the handoff dir (isolated regime: report only; orchestrator re-engages after review-clean). Zero state-changing git verbs run. | COMPLIANT |
| **per-action-approval-sub-agents** | Initial pass: the out-of-scope L425 bullet (POQ-C5-1) was NAMED and left for orchestrator disposition rather than self-edited. Follow-up: the user EXPLICITLY APPROVED fixing it now, in-scope; only then was the edit made. No destructive op performed at any point. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line only after ALL edits + validate-pack PASS + union-grep clean + leak gates 0/0/0 + ×3 lock-step verified — first at 9/9, re-emitted at 10/10 after the user-approved POQ-C5-1 fix. No partial report; no parent stop received. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Targeted in-place edits on quoted anchors (S10 four blocks; the POQ-C5-1 Permission-classes RW bullet; S13 Merge-back+load-bearing; S13b inserted one para). Surrounding content preserved — repo-ops `git worktree` verb-ban kept verbatim (`grep -lc "git worktree"` = 3/3); conflict protocol kept; the Permission-classes RO bullet + shared hard-rule paragraph untouched; pre-existing PM-CHAT L342/L344 untouched. | COMPLIANT |
| **worktree-isolation-mergeback-ops** | Verified runtime regime (pwd == toplevel == `agent-a0b8a2ce7dde05dfe` worktree; HEAD ba3bb08). Implemented patch-only-after-review-clean across all 7 surfaces; report to named `/tmp/handoff-bd226-C5/`. No commit/apply; no up-front patch. | COMPLIANT |
| **enumerate-encoding-surfaces** | All ×3 coder copies (`.claude`/`.agents-plugin`/`.codex`) AND all ×3 repo-ops copies edited in lock-step; `.toml` carries the same content in TOML prose. Multiline-collapsed grep confirms each intent phrase present 3/3 per triad. None omitted. | COMPLIANT |
| **pack-project-separation-of-concerns** | `git diff --name-only` shows 0 non-`project-template/` files. No pack path touched. No pack-self concept added to project content. | COMPLIANT |
| **boundary-investigation-precedes-pack-defaults (P-missed-7)** | Edits use "the PM chat" (27×), `coder`/`repo-ops`; pack-self leak grep = 0 in my edits (only pre-existing L342/L344). Rule-4 re-engagement expressed as the project clause + Claude-Code parenthetical + peer-messaging-absent degradation; NOT the pack Agent-Teams guarantee. Boundary-discipline check section above documents project-side SSOTs. | COMPLIANT |
| **bd-pack-only-operational-rule** | `grep -rE "BD-[0-9]"` over the 7 C5 files = 0 hits. Deferral phrasing uses "a future pack version"/"tracked separately" semantics (no BD-NNN in any restatement). | COMPLIANT |
| **cross-cli-reference-normalization** | `.md` (Markdown, multi-line) vs `.toml` (single-line TOML prose) edits match content-intent, not byte-copied. Verified per-triad collapsed grep parity. | COMPLIANT |
| **rename-plans-measure-then-bound** | Ran the C5-files union OLD-model grep (design §5.1 phrase set) over the 7 edited files, including the PM-CHAT.md Permission-classes section after the POQ-C5-1 fix; model-phrase residual = 0; OLD `patch plus a report`/`then emit a patch` removed tree-wide (`grep -rn` → exit 1); the only `emit...patch` matches are the new-model negated phrase; KEEP allowlist for C5 = `git worktree` verb-ban (MOOT). Residual reported. | COMPLIANT |
| **graph-first-context** | Used grep/Read as authoritative for all exact-string anchor work. Added ZERO graph content to any project surface (graphify gate = 0). | COMPLIANT |
| **rules-applied-verification-block** | This table — each rule named with quoted/measured evidence and a terminal conclusion. | COMPLIANT |
