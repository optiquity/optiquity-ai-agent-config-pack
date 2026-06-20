# REVIEW — BD-226 COMMIT C6 (project feature doc + skill + prompts + agent-run launcher)

**Reviewer:** pack-reviewer (FRESH, READ-ONLY). **BD:** BD-226. **Commit:** C6 (`project-only`, pre-commit).
**Worktree (verified `pwd`):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a8aa498bbedb833cd`
**HEAD (verified `git rev-parse HEAD`):** `46dce4d7785388b19d4ff4c1737e2ee4ae582924` (matches expected base `46dce4d`).
**Branch:** `worktree-agent-a8aa498bbedb833cd`.
**Date of measurement:** 2026-06-19.
**Deliverable:** this review only. No patch emitted; no stage/commit/apply/edit run.

---

## VERDICT: CLEAN

All six C6 surfaces match the STANDARD (design §2 S12/S17/S14/S-AR/S11 + plan COMMIT C6). The two intentional no-op prompt files (coder.md / repo-ops.md) and the S11 METHODOLOGY no-op are genuine. The agent-run.sh 4-location 2-KEEP/2-STRIP classification is correct, the xref label is the existing-section label (no invented heading), bash is syntactically valid, validate-pack exits 0 in the worktree, the completeness-gate STRIP set is 0, every residual is allowlisted, and the project leak/audience gates are 0/0/0 with project-only scope. **No findings.**

## Findings table

| # | Severity | Surface | Finding |
|---|---|---|---|
| — | — | — | NONE. All dimensions re-measured PASS. |

---

## Per-dimension evidence

### D1 — S12 `project-template/docs/pack/OPTIONAL-FEATURES.md` — MATCHES (SUPPORTED)

- **"What it is" RW narrative → in-worktree-cycle + patch-after-review-clean.** The diff replaces the up-front-patch narrative with "The first coder of a commit creates the worktree; the ENTIRE review/fix cycle for that commit runs inside it — the read-only reviewer reads the work there and a fix-coder REUSES that same worktree (never a new one). The read-write agent does NOT emit a patch up front … the patch is produced ONLY after the reviewer confirms the work clean, by re-engaging the most-recent read-write agent (in Claude Code, via the Agent-team peer-message path; if your CLI offers no peer-messaging, re-spawn a fresh coder …)." Matches design §2 S12 + the project-side rule-4 re-engagement phrasing (design L226). No `SendMessage`/Agent-Teams-as-universal framing.
- **"Read-only agents … need NO isolation" → RO-to-work's-tree.** Reworded to "run in the tree the work lives in — your main tree when the work is committed, the live worktree when the work is still uncommitted there (they cd in and verify pwd/HEAD at runtime). They write a report and emit no patch." Matches.
- **"default floor" → degraded fallback.** "If isolation is unavailable (an environment without worktree support), the in-place (non-isolated) regime is the DEGRADED fallback … it exposes in-progress work to your main tree, which is exactly what the isolated default avoids." Matches §2 S12.
- **F-3 caveats (current file L259-272).** Auto-removal MECHANISM fact KEPT ("Claude Code can auto-remove its worktree and branch — a branch with unmerged commits can be silently deleted"); patch-timing consequence reworded to rule 4/7/Constraint 1 ("HOLDS the commit's worktree through the whole review/fix cycle and removes it explicitly only AFTER the commit lands (a failed commit KEEPS the worktree). The patch is produced post-review-clean and applied at commit time, never captured pre-return"). Regime-detect reworded from a patch-handoff signal → pwd/HEAD ground-truth ("Each agent therefore VERIFIES its actual regime from its own runtime pwd/HEAD ground-truth … never from an assumed settings value or a patch-handoff signal"). Matches §2 S12 F-3 (rule 8).
- **F-13 why-not (no `pack-*`).** Added to the TRIGGER bullet: "Do NOT pin `isolation:"worktree"` in any read-write agent's definition frontmatter … a frontmatter pin forces a NEW worktree on EVERY spawn — so a fresh fix-coder could not cd into and REUSE the first coder's worktree, which breaks the reuse / in-worktree-cycle / lifecycle rules. Isolation is the PM chat's per-spawn choice, not a definition-level pin." Matches §2 S12 F-13; no `pack-*`.
- **KEPT VERBATIM (B1).** `git diff` hunks for this file are confined to L103-155 and L233-276. The baseRef JSON block + prose (L153-177), the `permissions.deny` recipe block + verb-precise prose (L188-230), the "Claude-only note" trinity-exempt note (L281-284: "This feature is specific to Claude Code's Agent-tool `isolation` parameter and `worktree` settings. Codex CLI and Antigravity CLI have no equivalent at this time; their worktree story is tracked separately …"), and the "a future pack version" framing (L184) all fall OUTSIDE the diff hunks → byte-unchanged. SUPPORTED.
- **Launcher narrative patch-timing (1(e)).** The "you bring its work back via the PM-chat patch merge-back" phrase was reworded → "the PM chat runs the review/fix cycle in the worktree and brings back the reviewed-clean patch, same merge-back model as the in-session spawn path" (current L252). The "(a SECONDARY path)" framing of the FLAG itself is KEPT (launcher-flag class). SUPPORTED.

### D2 — S17 `project-template/skills/implementation/SKILL.md` — MATCHES (SUPPORTED)

- **Patch = POST-review-clean artifact (rule 4).** New bullet: "A read-WRITE agent (the `coder`/`repo-ops`) does NOT emit a patch up front. … The patch is produced ONLY after a read-only reviewer confirms the work clean: the PM chat re-engages you to run the read-only patch-emit at that point (`git diff > <handoff>/changes.patch`)." Matches §2 S17.
- **F-10 (DELETE "survives … cleaned up"/`persisted artifact`).** The old "The patch — not the worktree — is the persisted artifact, so the change set survives even after the isolated worktree is cleaned up" is fully removed (diff `-` lines). Grep over the file for `persisted artifact` and `survives.*cleaned up` = 0. SUPPORTED.
- **F-9 (DECOUPLE regime↔patch-emit) + RO-in-worktree third state.** New text states the two facts are SEPARATE ("WHICH TREE you write in … and WHETHER YOU EMIT A PATCH") and adds the third state: "A read-ONLY agent (the `reviewer`/`architect`/`planner`) running in a live worktree writes ONLY its report and emits NO patch. It reads the uncommitted work in the worktree it cd'd into (verifying pwd/HEAD) and reports its findings; it never produces a change set." Matches §2 S17 F-9.
- **Report → /tmp always.** "Your report ALWAYS goes to the named `/tmp` handoff directory the calling prompt supplies — whether you ran in the main tree or in an isolated worktree." The in-place→parent-tree-path conditional is removed; the `/tmp`-write-fails degradation fallback is preserved. SUPPORTED.
- **Frontmatter / skill-count / `x-` contract preserved.** The diff begins at body L34 (`## Reporting the change set (regime-aware)`); frontmatter L1-5 (`name: implementation` / `description` / `allowed-tools`) is unchanged. validate-pack Check 1 "OK". Body-only edit; no restructure. SUPPORTED.

### D3 — S14 prompts — MATCHES (SUPPORTED)

- **reviewer.md** — ADDED a 6-line Constraints bullet under "Read-only review pass" (current L46-51): "**Read the work in the tree it lives in.** When the coder's work is still uncommitted in an isolated worktree, `cd` into that worktree and VERIFY your pwd/HEAD at runtime before reviewing — read the in-progress work there, not the main checkout. When the work is already on HEAD/committed, review it in the main tree. Emit no patch; your output is the report only." Matches §2 S14 (rule 3/8). The diff added exactly 6 lines (matches `git diff --stat`).
- **coder.md — NO-OP confirmed.** `grep -niE "worktree|merge-back|patch|handoff|in-place|isolat|persisted|changes\.patch|regime"` → exit 1 (zero hits). The report section (L117-124) says only `REPORT FILE: [PM chat supplies path; e.g., docs/project/coder-phase-N-pass-1.md]` and "Then report which files were modified and the final test count." No placement/handoff/patch-timing assertion to align to rule 4. Genuine no-op.
- **repo-ops.md — NO-OP confirmed.** 13-line placeholder file ("Placeholder. No standard variants ship for this agent yet."); same grep → exit 1 (zero hits). No placement assertion. Genuine no-op.

### D4 — S-AR `project-template/agent-run.sh` — MATCHES (SUPPORTED)

4-location KEEP/STRIP classification verified against current file state (line numbers shifted slightly from the design's anchors due to the STRIP additions, as expected):

| Design anchor | Current loc | Class | Verified outcome |
|---|---|---|---|
| L173-176 `--worktree` help | L173-176 | **KEEP** | "SECONDARY/opt-in — probe cwd-scoping once before relying on it" — UNCHANGED (outside diff hunks). Launcher-flag. |
| L275-278 `run_in_worktree()` comment | L275-280 | **STRIP** | Reworded to rule 4: "Either way the agent never stages or commits. The PM chat runs the review/fix cycle in the worktree and brings back the reviewed-clean patch — same merge-back model as the in-session spawn path; only the LAUNCH mechanism … differs, with no special-casing (see docs/pack/PM-CHAT.md "In-session agent spawning" and docs/pack/OPTIONAL-FEATURES.md)." |
| L306-307 echo | L308-310 | **STRIP** | Reworded echo (now 3 echo lines): "The agent never commits; the PM chat runs the review/fix cycle in the worktree and applies the reviewed-clean patch." |
| L606-608 branch comment | L608-610 | **KEEP** | "SECONDARY isolated-worktree path (opt-in). See run_in_worktree for the cwd-scoping caveat + manual fallback." — UNCHANGED (outside diff hunks). Launcher-flag. |

- **Xref label.** The reworded comment keeps `docs/pack/PM-CHAT.md "In-session agent spawning"`. VERIFIED that `### In-session agent spawning` EXISTS in PM-CHAT.md (L454) and a literal `### Merge-back` heading does NOT exist (`grep -nE "^#+\s*Merge-back"` → exit 1). The coder correctly did NOT invent a `### Merge-back` heading reference — this is the prescribed behavior and avoids a dangling xref. SUPPORTED.
- **Bash syntax.** `bash -n project-template/agent-run.sh` → exit 0 (SYNTAX OK).

### D5 — S11 `supporting-docs/METHODOLOGY.md` — NO-OP confirmed (SUPPORTED)

- `git diff --name-only | grep -i methodology` → exit 1 (NOT in the diff).
- L719-720: "After fixing a Critical or Major finding, the developer may re-run the owning subagent **in isolation** to verify the fix without paying for a full audit (per `audit-methodology` rule 70)" — this is an audit-efficiency concept (re-run ONE auditor subagent alone), NOT a worktree-placement model statement. No edit warranted.
- `grep -niE "worktree|merge-back|changes\.patch|patch handoff|in-place regime|isolated regime"` over the file → exit 1 (zero). Genuine no-op; substance correctly stays in PM-CHAT.md (S10, C5).

### D6 — Completeness gate (§5.1 union) — SUPPORTED

Ran the §5.1 OLD-model union phrase set over C6's edited files (OPTIONAL-FEATURES.md, SKILL.md, reviewer.md, coder.md, repo-ops.md, agent-run.sh):

- **STRIP set = 0.** Each of `the patch the agent`, `patch the agent leaves`, `patch merge-back`, `persisted artifact`, `survives.*cleaned up`, `survives.*auto-removal`, `before it returns`, `writes before`, `need NO isolation`, `default floor`, `on agent return`, `in the isolated regime`, `in the in-place regime`, `patch \+ report`, `opt-in accelerator`, `RW ⇒ isolate`, `patch handoff`, `BEFORE return` → 0 hits.
- `isolated regime` / `in-place regime` over OPTIONAL-FEATURES + SKILL → exit 1 (0).
- **Residual hits = allowlisted KEEPs only:**
  - `SECONDARY`: agent-run.sh L175 (`--worktree` help, launcher-flag KEEP), L250 (section-header comment, launcher-flag class), L609 (branch comment, launcher-flag KEEP); OPTIONAL-FEATURES L229 ("SECONDARY defence-in-depth" — `PreToolUse` hook vs `permissions.deny`, B1-verbatim context), L236 + L243 (`agent-run.sh --worktree` launcher-flag SECONDARY). **None added by the diff** (`git diff … | grep '^\+' | grep -iE 'SECONDARY|opt-in'` → exit 1).
  - `opt-in`: OPTIONAL-FEATURES L243 (launcher-flag), L296/L305/L312/L325/L336/L456 (generic, in Codex/Antigravity/Tracker/"Adding new entries" sections, unrelated to the worktree model, pre-existing); agent-run.sh L175/L251/L609 (launcher-flag). All allowlisted.

Each residual is on the design §5.1 KEEP allowlist (agent-run.sh launcher-flag + B1-verbatim + unrelated-section). The flip is complete.

### D7 — Project boundary / audience (P-missed-7) — SUPPORTED

- ADDED (`+`) lines across all edited surfaces: `grep -E '^\+' | grep -E 'BD-[0-9]|graphify|graph\.json|--graph|Pack Chat|pack-ops/|pack-coder|pack-reviewer|pack-architect|pack-planner|pack-docs-researcher'` → exit 1 (NO LEAK in added lines).
- Full edited-files `grep -rnE "BD-[0-9]"` → exit 1 (0).
- Full edited-files `grep -rniE "graphify|graph\.json|--graph"` → exit 1 (0).
- Audience term: new prose uses "the PM chat" (8 added occurrences across S12/S17), never "Pack Chat".
- The single `Pack Chat` hit (reviewer.md L110) is INSIDE the pre-existing `<!-- DENY-LIST-CONTENT-START/END -->` block (L107-112) — intentional deny-list enumeration so the project's reviewer REJECTS pack-only refs; NOT added by this diff (`git diff … | grep '^\+' | grep -iE 'Pack Chat'` → exit 1). Pre-existing deny-list / PACK-FEEDBACK references untouched.

### D8 — Scope + verification — SUPPORTED

- `git diff --name-only` = exactly 4 paths, all under `project-template/`: agent-run.sh, docs/pack/OPTIONAL-FEATURES.md, docs/pack/prompts/reviewer.md, skills/implementation/SKILL.md. (S11 no-op → `supporting-docs/` absent; still consistent with the `project-only` keyword which permits `project-template/` + `supporting-docs/`.)
- `git diff --name-only | grep -vE "^(project-template/|supporting-docs/)"` → exit 1 (no out-of-scope path). No pack-side path touched (`grep -E "^(pack-ops/|scripts/|…|\.agents-plugin/)"` → exit 1). Check 36 `project-only` holds.
- `python3 scripts/validate-pack.py` → **EXIT 0** ("PASSED — all checks clean"; 64 checks, Check 59 CHECK_REGISTRY == 62).
- No drift, no re-opened decision: every edit traces to a design §2 delta / plan C6 task; no scope beyond the named surfaces.

---

## Empirical-Evidence Blocks

**EB-1 — runtime regime (placement, rule 8).**
- Command: `pwd`; `git rev-parse HEAD`; `git rev-parse --abbrev-ref HEAD`.
- Output: pwd = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a8aa498bbedb833cd`; HEAD = `46dce4d7785388b19d4ff4c1737e2ee4ae582924`; branch = `worktree-agent-a8aa498bbedb833cd`.
- HEAD `46dce4d` / 2026-06-19. Interpretation: reviewing IN the commit's live isolated worktree, the expected base. Conclusion: **SUPPORTED**.

**EB-2 — changed-file set / scope (Check 36).**
- Command: `git diff --name-only`; `git diff --name-only | grep -vE "^(project-template/|supporting-docs/)"`.
- Output: 4 paths all under `project-template/`; out-of-scope grep exit 1 (empty).
- HEAD `46dce4d` / 2026-06-19. Interpretation: clean `project-only`. Conclusion: **SUPPORTED**.

**EB-3 — S12 KEEP-verbatim blocks unchanged.**
- Command: `git diff project-template/docs/pack/OPTIONAL-FEATURES.md` (hunk ranges) cross-referenced with `grep -n` for baseRef (L153-177), permissions.deny (L188-230), Trinity-exempt note (L281-284), "future pack version" (L184).
- Output: diff hunks confined to L103-155 + L233-276; all four KEEP regions fall outside the hunks.
- HEAD `46dce4d` / 2026-06-19. Interpretation: baseRef/permissions.deny/Trinity-exempt/"future pack version" byte-unchanged. Conclusion: **SUPPORTED**.

**EB-4 — S17 frontmatter / body-only.**
- Command: `Read SKILL.md L1-12`; `git diff project-template/skills/implementation/SKILL.md`.
- Output: frontmatter L1-5 (`name`/`description`/`allowed-tools`) unchanged; diff begins at body L34.
- HEAD `46dce4d` / 2026-06-19. Interpretation: body-only edit; frontmatter/skill-count/`x-` contract preserved (validate-pack Check 1 OK). Conclusion: **SUPPORTED**.

**EB-5 — S14 no-ops (coder.md / repo-ops.md).**
- Command: `grep -niE "worktree|merge-back|merge back|patch|handoff|in-place|isolat|persisted|changes\.patch|regime"` on each.
- Output: both → exit 1 (zero hits). coder.md report section = `REPORT FILE: [PM chat supplies path]`; repo-ops.md = 13-line placeholder.
- HEAD `46dce4d` / 2026-06-19. Interpretation: no placement language to align; genuine no-ops. Conclusion: **SUPPORTED**.

**EB-6 — S-AR 4-location KEEP/STRIP + bash valid.**
- Command: `git diff project-template/agent-run.sh`; `sed -n` on L173-176 / L600-615; `bash -n project-template/agent-run.sh`.
- Output: L173-176 + L606-610 KEEP (unchanged, outside diff); L275-280 + L308-310 STRIP (reworded to post-review-clean); `bash -n` → exit 0.
- HEAD `46dce4d` / 2026-06-19. Interpretation: 2-KEEP/2-STRIP applied exactly; syntactically valid. Conclusion: **SUPPORTED**.

**EB-7 — agent-run.sh xref label (no invented heading).**
- Command: `grep -niE "In-session agent spawning" project-template/docs/pack/PM-CHAT.md`; `grep -nE "^#+\s*Merge-back" project-template/docs/pack/PM-CHAT.md`.
- Output: `### In-session agent spawning` exists at L454; `### Merge-back` → exit 1 (does not exist).
- HEAD `46dce4d` / 2026-06-19. Interpretation: xref kept to an EXISTING section; no dangling `### Merge-back` invented. Conclusion: **SUPPORTED**.

**EB-8 — S11 METHODOLOGY no-op.**
- Command: `git diff --name-only | grep -i methodology`; `sed -n '715,725p'`; `grep -niE "worktree|merge-back|changes\.patch|patch handoff|in-place regime|isolated regime"` on METHODOLOGY.md.
- Output: not in diff (exit 1); L719-720 is the "re-run … in isolation to verify the fix … without paying for a full audit (per audit-methodology rule 70)" audit-efficiency prose; worktree/placement grep → exit 1.
- HEAD `46dce4d` / 2026-06-19. Interpretation: L720 is audit-efficiency, not a placement model; no edit warranted. Conclusion: **SUPPORTED**.

**EB-9 — completeness gate (§5.1 union over C6 files).**
- Command: STRIP-set union grep + residual `SECONDARY`/`opt-in`/regime grep over the 6 edited surfaces; `git diff … | grep '^\+' | grep -iE 'SECONDARY|opt-in'`.
- Output: STRIP set = 0 for every phrase; `isolated/in-place regime` = 0; residual SECONDARY/opt-in are all pre-existing (no added-line hit, exit 1) and on the launcher-flag / B1-verbatim / unrelated-section allowlist.
- HEAD `46dce4d` / 2026-06-19. Interpretation: flip complete; only allowlisted KEEPs remain. Conclusion: **SUPPORTED**.

**EB-10 — project leak / audience gates.**
- Command: `git diff … | grep '^\+' | grep -E 'BD-[0-9]|graphify|graph\.json|--graph|Pack Chat|pack-ops/|pack-coder|pack-reviewer|pack-architect|pack-planner'`; `grep -rnE "BD-[0-9]"` + `grep -rniE "graphify|graph\.json|--graph"` over edited surfaces.
- Output: added-lines leak grep → exit 1; BD-NNN census → exit 1 (0); graphify census → exit 1 (0). Sole `Pack Chat` hit (reviewer.md L110) is pre-existing DENY-LIST content (not in added lines).
- HEAD `46dce4d` / 2026-06-19. Interpretation: 0/0/0 leak; project audience preserved. Conclusion: **SUPPORTED**.

**EB-11 — validate-pack in the worktree.**
- Command: `python3 scripts/validate-pack.py; echo $?`.
- Output: "PASSED — all checks clean"; exit code 0.
- HEAD `46dce4d` / 2026-06-19. Interpretation: full check battery green with the C6 edits. Conclusion: **SUPPORTED**.

---

## Rules-Applied Verification Block

| Rule name | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran only read-only git verbs: `git rev-parse`, `git status`, `git diff`, `git diff --name-only`. No add/commit/apply/stage/restore/checkout. Single write = this report at `/tmp/handoff-bd226-C6/REVIEW.md`. No patch emitted. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op performed or proposed; review is observation-only. | COMPLIANT |
| **graph-first-context** | grep/Read used as authoritative throughout; the injected `graphify-out/` path is absent from this worktree → fell back to grep/Read with zero friction (no graph query needed). | COMPLIANT |
| **preflight-stop-means-stop** | No parent stop/halt message received during the review. | N/A: no stop signal arrived |
| **rules-applied-verification-block** | This table — each rule carries a measurement/quote and a terminal conclusion; no empty evidence. | COMPLIANT |
| **empirical-evidence-blocks** | EB-1..EB-11 above: each review state-claim (placement, scope, KEEP-verbatim, frontmatter, no-ops, KEEP/STRIP, xref, S11 no-op, completeness gate, leak gates, validate-pack) carries command + actual output + HEAD `46dce4d`/2026-06-19 + interpretation + SUPPORTED. Re-measured in the worktree; IMPL-REPORT not trusted. | COMPLIANT |
| **worktree-isolation-mergeback-ops** | Reviewed IN the commit's live worktree (pwd/HEAD verified EB-1); emitted NO patch; report → named `/tmp/handoff-bd226-C6/` dir. | COMPLIANT |
| **skill-agent-maintenance-mechanical** | S17 verified body-only: frontmatter L1-5 unchanged (EB-4), diff begins at L34, no skill-count/restructure change, validate-pack Check 1 OK, no `x-` key disturbed. | COMPLIANT |
| **pack-project-separation-of-concerns** | `git diff --name-only` = 4 paths all under `project-template/`; out-of-scope + pack-side greps → exit 1 (EB-2). Check 36 `project-only` holds. | COMPLIANT |
| **boundary-investigation-precedes-pack-defaults (P-missed-7)** | Added lines carry no `pack-*`/`pack-ops/`/BD-NNN/graphify (EB-10); new prose uses "the PM chat"; agent-run.sh xref keeps the existing `docs/pack/PM-CHAT.md "In-session agent spawning"` label, no invented heading (EB-7). | COMPLIANT |
| **bd-pack-only-operational-rule** | `grep -rnE "BD-[0-9]"` over the edited project text → exit 1 (0); cross-CLI-serial deferral expressed as "tracked separately" / "a future pack version" (EB-10, EB-3). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | B1 baseRef/permissions.deny blocks + agent-run.sh launcher-flag KEEP lines verified byte-unchanged (EB-3, EB-6); all edits are targeted (S14 = +6 lines; S-AR = 2 reworded comments); no needless rewrite. | COMPLIANT |
| **rename-plans-measure-then-bound** | Re-ran the §5.1 C6-files union grep with the KEEP allowlist (EB-9): STRIP set = 0; every residual classified to the launcher-flag / B1-verbatim / unrelated-section allowlist; no hand-enumerated anchor list relied on. | COMPLIANT |

---

## Bottom line: CLEAN — APPROVE C6

All six surfaces match the standard; the two prompt no-ops and the S11 METHODOLOGY no-op are genuine; agent-run.sh 4-location 2-KEEP/2-STRIP is correct with the existing-section xref label (no invented `### Merge-back` heading); bash valid; validate-pack exit 0 in the worktree; completeness-gate STRIP set 0 with only allowlisted KEEPs remaining; project leak/audience gates 0/0/0; project-only scope. No findings.
