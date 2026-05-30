# IMPLEMENTATION-REPORT — BD-196 Commit C1

**Commit:** C1 — Pack-memory corpus: add `[roles:]` tags + `[rationale: slug]`
pointers + two-clause imperatives (TRINITY lock-step) — NO check wired.
**Plan:** `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` § C1.
**Design:** `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`
§5.1, §9.3, §9.4, §9.5, §11.1.
**Branch:** `v11-dev`. **HEAD at work start + end (no commits by coder):**
`96b174a6beed284b7bb90af4e56b3cc820ccb925`.
**Agent:** pack-coder. **Date:** 2026-05-30.

---

## 1. What changed

For each **spawn-relevant** `## Pack memory` rule (20 of the 45 corpus
bullets), in ALL THREE trinity files identically:

1. Rewrote the imperative line to the two-clause `<DIRECTIVE> + <TRIGGER>`
   application-grade form (C1-(i) / §5.1) — an agent that never reads the
   rationale can apply it. Where application-critical detail lived only in
   the Why/body, it was pulled UP into the imperative; meaning preserved.
2. Appended `[roles: …]` — the applicable subset of the controlled vocab
   `architect planner coder reviewer docs-researcher`, or `universal`
   (§9.4).
3. Appended `[rationale: <slug>]` — a stable kebab-case slug keying the C2
   rationale file + the C3 bijection (§5.1.ii).

Why/How-to-apply/worked-example BODIES were LEFT IN PLACE (they leave in C2).
No rule added, removed, reordered, or re-worded in substance. Only the
`## Pack memory` section was touched in each file. No check wired (per C1).

**Classification method (§9.3 "would Pack Chat paste this into a spawn
prompt?"):** Each of the 45 corpus bullets was tested. Spawn-relevant =
an imperative an AGENT must obey at spawn time (git-ban, PREFLIGHT,
permissions, Rules-Applied/Empirical-Evidence obligations, boundary
discipline, manifest-regen, etc.). NOT spawn-relevant = Pack-Chat-
orchestration rules (does-not-architect, triage gates, spawn protocol,
bounded review/fix cycle, prompt-construction rules, spawn-config rules)
and project-goals statements. 25 bullets are non-spawn-relevant and were
NOT tagged, per C1's explicit instruction. (The design's EE-6 estimate was
"~22"; the precise §9.3 test yields 20 — the imperative count was applied,
not force-fit to the estimate.)

## 2. Per-rule `[roles:]` + `[rationale: slug]` assignment table

| # | Rule (corpus bold-name) | Subsection | `[roles:]` | `[rationale: slug]` |
|---|---|---|---|---|
| 1 | Agents never commit | Workflow | universal | agents-never-commit |
| 2 | Per-action approval extends to sub-agents | Workflow | universal | per-action-approval-sub-agents |
| 3 | Deferred work needs a tracked anchor | Workflow | universal | deferred-work-tracked-anchor |
| 4 | No deferral to v11.1+ without explicit user direction | Workflow | universal | no-deferral-without-user-direction |
| 5 | Deferral IS scope creep | Workflow | universal | deferral-is-scope-creep |
| 6 | Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern | Agent invocation | universal | preflight-stop-means-stop |
| 7 | Agent output requires Rules-Applied Verification Block | Agent invocation | universal | rules-applied-verification-block |
| 8 | Architect/planner state-claims require Empirical-Evidence Blocks | Agent invocation | architect planner | empirical-evidence-blocks |
| 9 | CI guard design — measure-then-bound | Agent invocation | architect | ci-guard-measure-then-bound |
| 10 | Per-entry trees vs mirrors — mode-dependent source of truth | Repo conventions | universal | per-entry-trees-vs-mirrors |
| 11 | Separate pack ops from pack product | Repo conventions | universal | separate-ops-from-product |
| 12 | Project-side concepts on pack-side surfaces — deliverable-only | Repo conventions | universal | pack-side-project-concepts-deliverable-only |
| 13 | Enumerate ENCODING surfaces in pack-side audits | Repo conventions | reviewer coder | enumerate-encoding-surfaces |
| 14 | Test infra is self-provisioned | Repo conventions | universal | test-infra-self-provisioned |
| 15 | Skill and agent maintenance is mechanical by default | Repo conventions | universal | skill-agent-maintenance-mechanical |
| 16 | Pack-repo code-comment deferrals | Repo conventions | coder | pack-repo-code-comment-deferrals |
| 17 | Filename uniqueness heuristic | Repo conventions | universal | filename-uniqueness-heuristic |
| 18 | Architect-doc-vs-reality reconciliation | Repo conventions | architect coder | architect-doc-reality-reconciliation |
| 19 | Regenerate test-fixtures/manifest.txt on every v11-surface commit | Repo conventions | coder | regenerate-manifest-v11-surface |
| 20 | Cross-CLI reference normalization in `project-template/` trinity | Repo conventions | coder | cross-cli-reference-normalization |

**roles distribution (identical in all 3 files):** universal ×13,
coder ×3, architect ×1, architect planner ×1, architect coder ×1,
reviewer coder ×1.

**Notes on borderline classifications (decisions recorded for C2/C3
review):**
- Rule 6 (PREFLIGHT + STOP-MEANS-STOP) is ONE corpus bullet covering two
  obligations. §9.4 worked examples cite "PREFLIGHT `[roles: coder]`" and
  "STOP `[roles: universal]`" as separate examples, but they share one
  bullet/imperative line, which carries one tag. Tagged `universal` so the
  STOP half (which applies to every spawned agent) is never under-scoped.
- Rule 10 (Per-entry trees vs mirrors) is a repo-data SSOT convention an
  agent obeys when editing entry content → `universal`.
- Pack-Chat-orchestration bullets NOT tagged (correct per C1): Pack Chat
  does not architect; One review/fix cycle per batch; Implicit BD status
  flip; Per-BD review/fix runs INLINE; Pack Chat presents triage;
  Triage all reviewer findings; P-missed-7 (Pack-Chat-triage/actor framing
  — boundary-investigation skill is the agent's home, not the spawn
  imperative); Pack agent invocation; Agent prompt requirements; No
  solutions in agent prompts; No prior reviews to pack-reviewer;
  Researcher-first pipeline; Planner output → user review → coder spawn;
  Agent prompt enumerates ALL applicable rules inline; the 4 Sub-agent-
  behavior (Claude-only) bullets; the 6 Pack-Chat-scope bullets;
  BACKLOG has no Resolved section; the 2 Project-goals bullets.

## 3. Rule-count-unchanged confirmation (re-read evidence per file)

`awk` over the `## Pack memory` → `### Project goals` range, counting
`^- **` bullets, run against working tree AND `git show HEAD:`:

| File | Bullets at HEAD | Bullets after edits | Delta |
|---|---|---|---|
| `CLAUDE.md` | 45 | 45 | 0 |
| `AGENTS.md` | 41 | 41 | 0 |
| `GEMINI.md` | 41 | 41 | 0 |

The 45-vs-41 split is the PRE-EXISTING baseline (CLAUDE.md carries 4
"Sub-agent behavior (Claude-only)" sub-bullets that AGENTS/GEMINI omit per
the documented trinity exemption). My edits added/dropped ZERO bullets in
every file. No rule lost. (This satisfies the EDIT-IN-PLACE rule: targeted
per-rule Edits, never a full-file rewrite; re-read confirms counts.)

**Bullet bold-name (rule NAME) diff:** the only header-line diffs are the 4
rules whose first physical line carries both the bold name and the reshaped
first sentence (Per-action approval; Deferral IS scope creep; Pack-coder
PREFLIGHT + STOP-MEANS-STOP; Enumerate ENCODING surfaces). In each, the
`**Bold name.**` is byte-identical to HEAD; only the prose AFTER the bold
name changed (the intended two-clause reshape). All other rule names
unchanged.

## 4. Trinity parity evidence

- Tag counts per file: `[roles:` = 20, `[rationale:` = 20 — identical in
  all three.
- Slug set (sorted) byte-identical across `CLAUDE.md` / `AGENTS.md` /
  `GEMINI.md` (20 slugs each; diff is empty).
- roles-tag value distribution identical across all three files.
- Controlled-vocab check: every role token is in
  `{architect, planner, coder, reviewer, docs-researcher, universal}` —
  zero out-of-vocab tokens in any file.
- `git diff --stat`: each of the three files shows the SAME shape
  (111 changed lines; 246 insertions / 87 deletions total across the 3).

The reshaped imperatives that touch CLI-specific body tokens (Rule 2
"Per-action approval", whose body names "Claude Code"/"Codex CLI"/"Gemini
CLI" per CLI) were given a CLI-NEUTRAL reshaped opening sentence so the
tagged imperative line is byte-identical across the trinity; the CLI token
remains only in the untouched body. No new cross-CLI asymmetry introduced.

## 5. validate-pack.py PASS evidence

`python3 scripts/validate-pack.py` → exit code `0`, final line
`PASSED — all checks clean`. Relevant trinity / structure checks:

```
── Check 11: Pack agent trinity-rule symmetry (informational) ──
── Check 16 [pack-root]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
── Check 18 [pack-root]: Trinity H2 structure parity (BD-059, BD-181) ──
── Check 19 [pack-root]: Trinity templates free of body scaffolding ──
  OK: [pack-root] All three trinity templates free of body-section scaffolding comments
PASSED — all checks clean
```

The `[roles:]`/`[rationale:]` tags are inline trinity text already governed
by the trinity rule; parity holds by construction and the trinity-parity
checks stay green (they assert H2 structure / scaffolding / addenda, NOT
the new tags). No new check wired this commit (per C1).

## 6. No manifest regen (pack-root trinity)

Pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` are NOT under any of the
4 manifest-regen trigger directories (`project-template/`, `scripts/`,
`pack-ops/`, `supporting-docs/`). They are pack-self-management ops files,
not v11-surface — `scripts/init-project.sh` does not copy pack-root trinity
to clients. Per plan C1 "Working state": **no `test-fixtures/build.sh`
rebuild, no `manifest.txt` staging required for C1.** Confirmed: the
manifest-regen rule's trigger globs do not match pack-root trinity paths.

## 7. Files changed (inventory)

| Path | Change type |
|---|---|
| `CLAUDE.md` | modified (`## Pack memory` only) |
| `AGENTS.md` | modified (`## Pack memory` only) |
| `GEMINI.md` | modified (`## Pack memory` only) |

No new files. No deletions. No files outside the trinity touched.

## 8. Plan deviations

ZERO. C1 scope executed exactly: two-clause imperatives + `[roles:]` +
`[rationale: slug]` on spawn-relevant rules only; bodies stay; trinity
lock-step; no check wired; no manifest regen. The only judgment call within
scope was the spawn-relevant SET (20 vs the design's "~22" estimate) —
resolved by applying the §9.3 test literally rather than force-fitting the
estimate; documented in §2 for C2/C3 review.

## 9. New POQs introduced

None. (The 20-vs-22 count is recorded in §2 as a classification note for
downstream C2/C3, not a design gap — the design states "~22" explicitly,
and §9.3 is the governing test.)

## 10. Definition-of-Done checklist

| Item | Result |
|---|---|
| Spawn-relevant rules reshaped to two-clause `<DIRECTIVE>+<TRIGGER>` form | PASS (20 rules) |
| `[roles: …]` appended, controlled vocab only | PASS (0 out-of-vocab) |
| `[rationale: <slug>]` appended, kebab-case, stable | PASS (20 unique slugs) |
| Why/How/example bodies LEFT in place | PASS (no body moved/deleted) |
| Non-spawn-relevant rules NOT tagged | PASS (25 untagged) |
| Edit-in-place, targeted Edits (no full-file rewrite) | PASS |
| Rule count unchanged per file (re-read) | PASS (45/41/41 → 45/41/41) |
| Trinity lock-step (identical edits ×3) | PASS (slug sets + roles + diffstat identical) |
| `## Pack memory` only — no other section touched | PASS |
| `validate-pack.py` PASS (incl. Checks 11/16/18/19) | PASS (exit 0) |
| No manifest regen (pack-root trinity, not v11-surface) | PASS (documented §6) |
| No git state changes by coder | PASS (read-only verbs only) |

---

## 11. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | Coder ran only `git rev-parse HEAD`, `git status`, `git diff`, `git show`, `git diff --stat` (read-only). No `add`/`commit`/`push`/`tag`/`mv`/`rm`. HEAD unchanged `96b174a6…` at start and end. | COMPLIANT |
| EDIT IN PLACE — targeted Edits, re-read count unchanged | All changes via per-rule `Edit` calls (60 Edits); no `Write` to any trinity file. Re-read: `awk` bullet count 45/41/41 at HEAD == 45/41/41 after; `git diff --stat` = 111 changed lines/file (additive). | COMPLIANT |
| TRINITY lock-step | `grep -o "\[rationale: …\]" \| sort` byte-identical across the 3 files (20 slugs each); roles distribution identical (universal ×13, coder ×3, architect ×1, architect planner ×1, architect coder ×1, reviewer coder ×1); diffstat identical (111 lines each). | COMPLIANT |
| Preserve rule meaning | Each reshape pulls existing body detail UP into the imperative without changing the requirement; original body text retained verbatim below each reshaped opening (verified by reading each edited bullet). Bold rule NAMEs byte-identical to HEAD (header diff shows only post-name prose changed). | COMPLIANT |
| PREFLIGHT before IMPL-REPORT | Emitted the single PREFLIGHT line (`60/60 … verification PASS … HEAD 96b174a6… about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C1.md`) immediately before this Write. | COMPLIANT |
| Verification before PREFLIGHT (validate-pack 16/18/19 + suite) | `python3 scripts/validate-pack.py` exit `0`; final line `PASSED — all checks clean`; Checks 11/16/18/19 present and green; controlled-vocab grep returned zero bad tokens. | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |
| No solutions beyond scope / concise report | Only C1's three-step transform applied; no check wired, no body moved, no other section edited; report scoped to C1. | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert message received during the run; pattern acknowledged and honored throughout. | N/A: no stop signal issued |
| PERMISSION BOUNDARIES (in-scope edits + IMPL-REPORT; no git state change) | Edited only `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory` + this IMPL-REPORT; no git state-changing verb run. | COMPLIANT |
| PRISON RULE | No file under `maintenance-docs/prison/` read, cited, or trusted; sources were the plan, the design (v9), and the live trinity corpus. | COMPLIANT |
| No manifest regen needed (pack-root trinity not under 4 trigger dirs) | Edited paths are repo-root `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`; none under `project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/`. Not v11-surface; not copied by `init-project.sh`. | COMPLIANT |
