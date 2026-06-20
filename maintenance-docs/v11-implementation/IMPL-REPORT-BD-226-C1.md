# IMPL-REPORT — BD-226 COMMIT C1 (pack trinity keystone + class SSOT)

**Agent:** pack-coder (FRESH, empty context, isolated-worktree regime).
**BD:** BD-226 (sub-agent worktree-isolation overhaul). **Commit:** C1 (the pack KEYSTONE), `pack-only`.
**Status:** COMPLETE — all C1 edits made, verification PASS. NO patch emitted (per the isolation regime: the orchestrator requests the patch via SendMessage AFTER review-clean). NO stage/commit/apply performed.

## Regime + location (for routing the reviewer + later patch request)

- **Regime:** ISOLATED WORKTREE (verified at runtime — rule 8).
- **Worktree path (toplevel):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a4dc87e8f68933d75`
- **Branch:** `worktree-agent-a4dc87e8f68933d75`
- **HEAD (base, unchanged — agents never commit):** `a84094aa7fa2bda0213f66fb1588fdd162d92247`
- **Pre-flight verification:** `pwd` == `git rev-parse --show-toplevel` == the worktree path above (under `.claude/worktrees/agent-*`, NOT the main `-v11-dev` checkout); HEAD == `a84094a` as instructed. Regime MATCH confirmed before any edit.
- **Patch:** NOT produced (no `changes.patch`). The orchestrator will SendMessage this worktree after review-clean to run `git diff > /tmp/handoff-bd226-C1/changes.patch` at THAT point.

## Files changed inventory

| Path | Change type | Surface |
|---|---|---|
| `CLAUDE.md` | modified | S1 (keystone bullet rewrite + Agent-team-lifecycle minimal extension) |
| `pack-ops/PACK-AGENTS.md` | modified | S4 ("Two agent classes" class-default flip) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | modified | S8 (`## agents-never-commit` patch-timing retarget) |
| `AGENTS.md` | **NOT touched** | S2 EXPLICIT NO-OP (intentional Claude-only exemption) |
| `GEMINI.md` | **NOT touched** | S2 EXPLICIT NO-OP (intentional Claude-only exemption) |
| `pack-ops/.spawn-rule-manifest.txt` | **NOT touched** | S9 verify-only — no slug churn → no structural change needed |
| `pack-ops/PACK-CHAT.md` | **NOT touched** | S9 propagation-section: no slug add/remove → no edit needed |

`git diff --stat`: 3 files changed, 68 insertions(+), 28 deletions(-)
(`CLAUDE.md` 60±; `pack-ops/PACK-AGENTS.md` 25±; `pack-ops/PACK-MEMORY-RATIONALE.md` 11±).

**Pack-only scope check:** `git diff --name-only | grep -E "project-template/|supporting-docs/"` → 0 hits. No project path touched; `pack-only` keyword holds for Check 36.

## Per-surface summary (before/after for each edited anchor)

### S1 — `CLAUDE.md` § "Sub-agent behavior (Claude-only)" keystone (CLAUDE.md ONLY)

**Edit 1 — opening bullet REPLACED.**
- **BEFORE (anchor):** `- **Sub-agents run in-place by default; isolation is opt-in.** Sub-agents run IN-PLACE against the parent chat's working tree by default (no isolation). A chat MAY opt a sub-agent into isolated parallel execution by passing the per-spawn Agent-tool isolation:"worktree" parameter ... When isolation is active, read-write agents emit a patch to the named /tmp handoff dir and the orchestrator applies it; agents never commit. ...`
- **AFTER (anchor):** `- **Sub-agent isolation is keyed by agent class (RW → isolated worktree; RO → the work's tree).** Read-WRITE sub-agents ... run in an ISOLATED worktree by class. The FIRST coder of a commit CREATES the worktree ... every subsequent read-write agent in that commit's cycle — fix-coders included — REUSES that same worktree, NEVER a new one for a fix-coder. Read-ONLY sub-agents ... run in the tree the work lives in: the main checkout when the work is committed/on HEAD; the commit's live worktree when the work is still uncommitted there (cd in + verify pwd/HEAD). RO is NOT "always in-place" ... **No up-front patch.** Read-write agents produce NO patch on return; the ENTIRE review/fix cycle for a commit runs INSIDE that one worktree ... The patch is produced ONLY after a read-only reviewer confirms the work CLEAN — Pack Chat SendMessage-s the most-recent read-write agent to produce it (git diff > <handoff>/changes.patch at THAT point), then applies that reviewed-clean patch and commits ... **Worktree lifecycle (with the teardown gate).** ... remove a worktree ONLY after its commit is CONFIRMED landed (commit exit 0) ... a FAILED/aborted commit KEEPS the worktree ... NEVER rely on auto-removal. **Live-worktree ASK gate (rule 9).** A commit's own reviewer/fix-coder is RULE-FIXED ...; any OTHER agent spawned while a live worktree with uncommitted work exists ⇒ Pack Chat ASKS the user BOTH placement AND disposition ... **Parallelization map (rule 10).** ... Pack Chat consumes the map to schedule parallel worktree waves vs serial commits ...`

Encodes per design §2 S1: class-keyed default (rule 1); first-coder-creates / fix-coder-reuses-never-new; RO-to-work's-tree (not "always in-place"); no up-front patch + patch-after-review-clean via SendMessage the most-recent RW agent (rule 4); rule-7 lifecycle + Constraint 1 (teardown gate: only after commit exit 0; failed commit keeps; never auto-removal); rule-9 ASK gate; rule-10 parallelization-map pointer.

**KEEP-VERBATIM preserved (verified present in the AFTER text):**
- runtime-verify-regime line: "The agent VERIFIES its actual regime at runtime (pwd/HEAD ground-truth), never trusting settings." — present.
- `agents-never-commit`: "agents never commit." — present.
- `bgIsolation`→BD-218: "worktree.bgIsolation governs background SESSIONS only (not sub-agents) — BD-218." — present.
- `baseRef:"head"` settings line — present.
- the standalone "### Trinity exemption" bullet (L377+) — UNCHANGED.

**Edit 2 — "Agent-team stage lifecycle" bullet minimally extended (rule 6).**
- **BEFORE:** `... Pack Chat uses SendMessage for follow-ups against the same instance. After the stage's commit lands, close ALL stage sub-agents ...`
- **AFTER:** `... Pack Chat uses SendMessage for follow-ups against the same instance — including the sanctioned rule-4 post-review-clean patch step (SendMessage-ing the most-recent read-write agent to produce its git diff patch only after the review is clean). After the stage's commit lands, close ALL stage sub-agents ...`

Names the rule-4 patch step as a sanctioned SendMessage use (design §2 S1 final sentence). The rest of the bullet (per-commit fresh-coder, Claude-specific Trinity exemption) is UNCHANGED.

The keystone bullet carries NO `[rationale:]` tag → OUTSIDE the Check-45 bijection. No slug minted/changed by S1.

### S2 — `AGENTS.md` / `GEMINI.md` § Pack memory — EXPLICIT NO-OP

- `grep -c "Sub-agent behavior" AGENTS.md GEMINI.md` → `AGENTS.md:0`, `GEMINI.md:0` (before AND after; both files untouched per `git status --short`).
- The "Sub-agent behavior" section is INTENTIONALLY ABSENT from AGENTS.md / GEMINI.md. This is the Claude-only exemption (the section concerns Claude Code's Agent tool / `isolation:"worktree"` parameter / SendMessage — none of which have Codex/Antigravity equivalents). Adding it would assert FALSE cross-CLI parity. NOT a parity break — recorded so no future maintainer "restores parity."

### S4 — `pack-ops/PACK-AGENTS.md` § "Two agent classes"

**Edit 1 — framing paragraph: opt-in → class-default.**
- **BEFORE:** `... so RW agents MUST be spawned with worktree isolation, and the class is what makes that enforceable.`
- **AFTER:** `... so RW agents run in an isolated worktree by class-default (not opt-in), and the class is what makes that enforceable. RO agents run in the tree the work lives in.`

**Edit 2 — RW bullet: patch-after-review-clean.**
- **BEFORE:** `... runs verification, and emits a patch plus its report. NEVER runs a state-changing git verb. When isolation is opted-in, an RW agent emits its git diff patch to the named /tmp handoff dir and the orchestrator applies it.`
- **AFTER:** `... runs verification, and writes its report. NEVER runs a state-changing git verb. RW agents run in an isolated worktree (class-default); the patch is NOT emitted up front. The patch is produced only after review-clean — the orchestrator SendMessage-s the most-recent RW agent to produce its git diff patch into the named /tmp handoff dir; only the orchestrator applies it.`

**Edit 3 — RO bullet: run-in-the-work's-tree (not "always in-place").**
- **BEFORE:** `... read-only on the codebase otherwise. (pack-reviewer carries Write, Edit ...)`
- **AFTER:** `... read-only on the codebase otherwise. RO agents run in the tree the work lives in — the main checkout when the work is committed; the commit's live worktree when the work is still uncommitted there (cd in + verify pwd/HEAD); RO is NOT "always in-place". (pack-reviewer carries Write, Edit ...)`

Matches design §2 S4 exactly: flip "RW MUST be spawned with worktree isolation" framing to class-default; reword the opted-in patch sentence to patch-after-review-clean + SendMessage + only-orchestrator-applies; add RO-to-work's-tree. The `pack-reviewer`/`tools:` parenthetical (correct, unrelated) preserved verbatim.

### S8 — `pack-ops/PACK-MEMORY-RATIONALE.md` `## agents-never-commit`

**Edit — patch-timing sentence retargeted to post-review-clean (rule 4).**
- **BEFORE:** `The agent's output is its report file plus working-tree edits (or, in the isolated regime, a git diff patch emitted to the named /tmp handoff dir); Pack Chat reads the report, verifies / applies the patch, then commits.`
- **AFTER:** `The agent's on-return deliverable is its report file plus its worktree edits (held in the commit's isolated worktree). The git diff patch is NOT emitted up front — it is the POST-review-clean artifact: only after a read-only reviewer confirms the work clean does Pack Chat re-engage the most-recent read-write agent (SendMessage) to produce the patch into the named /tmp handoff dir; Pack Chat then reads the report, applies that reviewed-clean patch, and commits.`

Matches design §2 S8: patch = the POST-review-clean artifact produced by re-engaging (SendMessage) the most-recent RW agent after review-clean; the report is the on-return deliverable. SLUG header `## agents-never-commit` UNCHANGED (still the H2 at RATIONALE L29). Body-only edit (Check 45 is body-agnostic — slug set-equality).

**`## pack-chat-minor-edits-only` routing rationale (~L597): UNTOUCHED** (correct + unrelated, per design directive).

**Whole-RATIONALE union grep reconciliation:** Before editing, the design §5.1 expanded phrase union over the WHOLE RATIONALE returned exactly ONE OLD-model hit (L35, inside `## agents-never-commit` — the sentence I retargeted). The `## bounded-review-fix-cycle` section (L324+) was hand-read and carries NO OLD patch-timing claim — its cycle description (coder → reviewer → fix-coder) is placement-agnostic and stays correct under the new model; NO edit needed there. After the S8 edit, the whole-RATIONALE union grep is clean.

### S9 — propagation + `.spawn-rule-manifest.txt`

- S1 keystone bullet has NO `[rationale:]` tag → no slug churn → no AGENTS/GEMINI edit needed (trinity-parity at the H2 level is automatic; the section is CLAUDE-only).
- S8 edited the `agents-never-commit` BODY only (manifest-tracked but body-agnostic). Slug name unchanged.
- `.spawn-rule-manifest.txt` verified: `agents-never-commit` slug present (manifest L24), canonical home + references unchanged. NO slug added/removed → NO structural manifest change → file NOT edited (the correct outcome; editing it without a slug change would be churn).
- PACK-CHAT.md propagation section NOT edited (propagation procedure is triggered only by a rule add/change/remove; none occurred).
- Anti-restate intact: the S4 edit touched the "Two agent classes" section, NOT the "Agent permission rules" section (PACK-AGENTS.md L119+, which is the `agents-never-commit` manifest reference surface). Check 46 confirms 0 verbatim imperative-body restatements.

## Verification (commands + results)

1. **`python3 scripts/validate-pack.py`** → **EXIT 0, "PASSED — all checks clean"** (full registry of 62 checks). Spot-confirmed:
   - **Check 18 [pack-root]** (Trinity H2 structure parity): OK — "CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections)"; "GEMINI.md adds 1 intrinsic H2(s); otherwise matches (5 sections)". The S1 bullet edit lives inside an existing H3 under the `## Pack memory` H2 → no H2 structure change.
   - **Check 45** (pack-memory rule↔rationale bijection): OK — "23 corpus pointers; 23 rationale sections; sets are equal (bijection holds, no orphans)". S8 body edit + S1 (no slug) leave the slug set unchanged.
   - **Check 36** (commit-scope honesty): OK.
   - **Check 43** (project-side bare cross-reference scanner): OK.
   - **Check 46** (boundary + spawn manifest + anti-restate): OK — "anti-restate: 0 verbatim imperative-body restatements".
   - **Check 52** (pack RW/RO two-class set-equality): OK — 5 agents × 3 CLIs.
   - **Check 56** (destructive-git-verb enumeration parity): OK across 10 surfaces incl. PACK-MEMORY-RATIONALE (the S8 edit did not disturb the verb-ban paragraph).

2. **C1-files union grep (design §5.1 expanded phrase set, scoped to C1's OWN edited files):**
   `grep -nE "<union phrases>" CLAUDE.md pack-ops/PACK-AGENTS.md pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/.spawn-rule-manifest.txt`
   → **EXIT 1 (no matches) = 0 model-phrase residual.** Allowlist-only confirmed (no allowlist remainders in C1's files — the KEEP allowlist entries [the `git worktree` verb-ban, the `worktree-agent-*` pwd/HEAD self-detect mechanic, the reworded auto-removal mechanism sentence] are MOOT for the union grep and/or live in other commits' files; expected residual in C1 = 0, achieved).
   - Note: an interim grep flagged one transitional phrase "do NOT emit a patch on return" (matched by `emit[a-z]*[^.]*patch` even though it is a NEW-model NEGATION). Reworded to "produce NO patch on return" so the gate emits a clean 0 and no manual reviewer classification is needed. Meaning unchanged.

3. **Trinity body-parity hand-verify:**
   - `grep -c "Sub-agent behavior" AGENTS.md GEMINI.md` → 0/0 (section stays absent — intentional Claude-only exemption).
   - `git status --short AGENTS.md GEMINI.md` → empty (both files untouched; no false-parity assertion added).
   - S8 slug: `grep -c "rationale: agents-never-commit" CLAUDE.md` = 1; `grep -c "^## agents-never-commit" pack-ops/PACK-MEMORY-RATIONALE.md` = 1 → slug unchanged, bijection pair intact.

4. **Pack-only scope:** `git diff --name-only | grep -E "project-template/|supporting-docs/"` → 0 hits.

## Plan deviations

**None.** All five C1 tasks (T-C1-S1, T-C1-S4, T-C1-S8, T-C1-S9, T-C1-S2) executed exactly per plan §C1 + design §2. S9 and S2 are verify/no-op tasks by design — no file edit required, and none made (the absence of a manifest/AGENTS/GEMINI edit is the planned correct outcome, not a deviation).

## New POQs introduced

**None.** No design gap encountered; the design was self-contained for C1.

## Unplanned modifications

**None.** Only the three planned C1 surfaces (S1/S4/S8) were edited. The one in-flight reword (S1 "do NOT emit a patch" → "produce NO patch") is a within-S1 polish to keep the completeness gate clean, not an unplanned surface.

## Definition-of-Done checklist (PASS/FAIL per item)

| Item | Status |
|---|---|
| S1 keystone bullet replaced with class-keyed model (rules 1/4/7/9/10 + Constraint 1) | PASS |
| S1 KEEP-verbatim parts preserved (runtime-verify line, agents-never-commit, bgIsolation→BD-218, Trinity exemption bullet, baseRef line) | PASS |
| S1 Agent-team-lifecycle bullet minimally extended for the rule-4 SendMessage patch step (rule 6) | PASS |
| S1 is CLAUDE.md ONLY (nothing added to AGENTS/GEMINI) | PASS |
| S4 framing flipped opt-in → class-default | PASS |
| S4 RW bullet reworded to patch-after-review-clean + SendMessage + only-orchestrator-applies | PASS |
| S4 RO bullet gains run-in-the-work's-tree (not "always in-place") | PASS |
| S8 patch-timing sentence retargeted to post-review-clean (rule 4); slug unchanged | PASS |
| S8 `## pack-chat-minor-edits-only` routing rationale left untouched | PASS |
| S8 whole-RATIONALE union-grep reconciled (incl. bounded-review-fix-cycle hand-read) | PASS |
| S9 manifest consistency verified; no slug add/remove → no structural manifest change | PASS |
| S2 NO-OP confirmed (Sub-agent behavior 0/0 in AGENTS/GEMINI) + recorded | PASS |
| validate-pack.py exit 0 (Checks 18/36/43/45/46/52/56 green) | PASS |
| C1-files union grep = 0 model-phrase residual (allowlist only) | PASS |
| Trinity body-parity intact; CLAUDE-only divergence intentional + documented | PASS |
| pack-only scope (no project-template/ or supporting-docs/ path) | PASS |
| No stage/commit/apply; no patch emitted; HEAD unchanged at a84094a | PASS |

## Full file contents for new files

**None** — C1 created no new files; all three edits are in-place modifications of existing tracked files. (The orchestrator can re-derive the changes from this report's before/after anchors or from the patch it will request post-review-clean.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` (universal) | Only read-only git verbs run: `git rev-parse`, `git status`, `git diff` (read-only patch-emit form `git diff CLAUDE.md ...` for review, NOT `git diff > file`), `git ls-files`-class. NO `git add`/`commit`/`apply`/`worktree`/`branch`/`reset`/`restore`/`checkout`/`stash` invoked. NO `changes.patch` written (patch deferred to post-review-clean SendMessage). `git rev-parse HEAD` == `a84094a` after all edits (unchanged). | COMPLIANT |
| `per-action-approval-sub-agents` (universal) | No destructive op performed. `mkdir -p /tmp/handoff-bd226-C1` (non-destructive, creating the named handoff dir) is the only filesystem create outside the edits. No `rm`, no overwrite of an out-of-scope trusted file. | COMPLIANT |
| `preflight-stop-means-stop` (universal) | Emitted the single PREFLIGHT line ("5/5 C1 edits complete ... validate-pack PASS ... union-grep clean ... trinity parity intact ... HEAD a84094a ... worktree <path> ... about to Write IMPL-REPORT") ONLY after all edits + verification PASS (validate-pack exit 0; union grep exit 1). No partial-report path taken (nothing failed). No stop/halt message received. | COMPLIANT |
| `edit-in-place-not-full-rewrite` (coder) | All 4 edits are targeted Edit-tool string replacements keyed on the quoted design anchors (S1 opening bullet; S1 Agent-team-lifecycle sentence; S4 framing + RW + RO bullets in one block; S8 patch-timing sentence). No whole-section rewrite. KEEP-verbatim parts (S1 runtime-verify/bgIsolation/Trinity-exemption; S4 `pack-reviewer`/`tools:` parenthetical; S8 verb-ban paragraph) preserved — confirmed by the `git diff` showing only the targeted hunks. | COMPLIANT |
| `worktree-isolation-mergeback-ops` (universal) | Verified pwd/HEAD at runtime (rule 8): toplevel = `/Users/.../.claude/worktrees/agent-a4dc87e8f68933d75`, HEAD = `a84094a`. NO patch produced up front (rule 4 — patch is the post-review-clean artifact the orchestrator requests via SendMessage). No commit/apply. Report written to the named `/tmp/handoff-bd226-C1/` dir. | COMPLIANT |
| `enumerate-encoding-surfaces` (coder) | C1 has no ×3 duplicated def (S1 is CLAUDE-only single). S2 (AGENTS/GEMINI) confirmed a NO-OP: `grep -c "Sub-agent behavior" AGENTS.md GEMINI.md` = 0/0, files untouched. S8 slug `agents-never-commit` unchanged across the corpus↔RATIONALE bijection (Check 45 OK: 23↔23 equal). Manifest reference surface (PACK-AGENTS.md "Agent permission rules") not disturbed (anti-restate Check 46 OK). | COMPLIANT |
| `pack-project-separation-of-concerns` (universal) | `git diff --name-only | grep -E "project-template/|supporting-docs/"` → 0 hits. Only pack-side files touched (CLAUDE.md, pack-ops/*). No pack-self leak concern (pack surface). | COMPLIANT |
| `rename-plans-measure-then-bound` (universal) | Completeness verified by the design §5.1 union grep over C1's OWN files (not a hand-enumerated anchor list): `grep -nE "<union phrase set>" CLAUDE.md pack-ops/PACK-AGENTS.md pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/.spawn-rule-manifest.txt` → EXIT 1 (0 matches). Whole-RATIONALE pre-edit measure = 1 hit (L35, the S8 target); post-edit = 0. Every remaining hit on the KEEP allowlist (none remain in C1's files). | COMPLIANT |
| `graph-first-context` (universal) | grep/Read used as authoritative for this exact-string editing work (the graph token-collides on prose, per the prompt). Graph not queried (the injected absolute graph path is outside the worktree; for exact-string edits grep/Read is the correct tool — the rule's fall-through clause for "exact-string / token search" and "whole-file exact content" applies). No graph dependency; no block. | COMPLIANT (graph N/A by the rule's own fall-through for exact-string edits) |
| `rules-applied-verification-block` (universal) | This block: each in-force rule has a named row with quoted-measurement evidence (command output / grep counts / git state) and a terminal COMPLIANT conclusion; no empty evidence; no AMBIGUOUS terminal state. | COMPLIANT |

**End of IMPL-REPORT — C1.** NO patch emitted (awaiting orchestrator SendMessage after review-clean). HEAD `a84094a`; worktree `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a4dc87e8f68933d75`.
