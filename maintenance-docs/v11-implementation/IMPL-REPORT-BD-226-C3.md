# IMPL-REPORT — BD-226 COMMIT C3 (pack skills + feature doc + conceptual-review)

**Agent:** pack-coder (FRESH, isolated worktree, READ-WRITE). **Commit:** C3 (`pack-only`).
**No patch emitted** (per rule 4 — patch is produced only after review-clean, when the orchestrator re-engages me). No stage/commit/apply performed.

## 1. Branch + HEAD + regime

- **Regime:** ISOLATED worktree (verified at runtime per rule 8).
- **Worktree path:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-aec2b0dd51e9db179`
- **Branch:** `worktree-agent-aec2b0dd51e9db179`
- **HEAD (unchanged — agents never commit):** `28879ae598a57ce3666a0f5c6d63fc2947157549`
- **Base subject:** `feat: v11 — BD-226 pack orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (pack-only)` (= C2 landed; C3 depends on C1, which is an ancestor of C2).
- Pre-flight verification: `pwd` == `git rev-parse --show-toplevel` == the worktree path (an isolated `.claude/worktrees/agent-*` checkout, NOT the main `-v11-dev` clone); HEAD == `28879ae` as required by the prompt.

## 2. Pre-flight check output (verbatim)

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-aec2b0dd51e9db179
$ git rev-parse HEAD
28879ae598a57ce3666a0f5c6d63fc2947157549
$ git rev-parse --show-toplevel
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-aec2b0dd51e9db179
$ git log -1 --oneline
28879ae feat: v11 — BD-226 pack orchestrator contract + agent defs: in-worktree cycle + patch-after-review-clean (pack-only)
$ git status
On branch worktree-agent-aec2b0dd51e9db179
nothing to commit, working tree clean   # (pre-edit)
```
Regime confirmed ISOLATED. HEAD matches the prompt's required `28879ae`.

## 3. Per-surface summary (S6 / S15 / S16 / S18)

### S6 — `pack-ops/OPTIONAL-FEATURES.md` § "Isolated parallel agents" (B1 targeted + F-3 + F-13)

Four targeted edits inside the narrative; the B1-verbatim blocks were NOT touched.

**(a) "What it is" RW narrative — reworded to in-worktree-cycle + patch-after-review-clean (rule 3/4); RO clause reworded to rule-1 placement; F-13 why-not added.**
- BEFORE (anchor): "The agent edits in the worktree, emits a `git diff` patch to a named handoff directory, and returns; Pack Chat reads the patch, runs the review/fix cycle, applies it onto the parent branch, and commits … Read-only agents … need NO isolation — they emit a report and write nothing to the tree."
- AFTER: "The agent edits in the worktree, runs its verification, writes its report, and returns — it does NOT emit a patch up front. The ENTIRE review/fix cycle for that commit runs inside that one worktree (the reviewer reads the work there; the fix-coder REUSES the same worktree). The patch is produced ONLY after the reviewer confirms the work clean: Pack Chat SendMessage-s the most-recent read-write agent to emit it, then `git apply`s the reviewed-clean patch … Read-only agents … run in the tree the work lives in — the main checkout when the work is committed, the commit's live worktree when the work is still uncommitted there (they cd in + verify pwd/HEAD); they emit a report and no patch."
- F-13 why-not paragraph ADDED on the RW class-default narrative: "This isolation is the **default by agent class**, not an opt-in accelerator … A read-write subagent must NOT pin `isolation:"worktree"` in its definition frontmatter — the `isolation` parameter has only the value `"worktree"` (there is no `"off"`; see below), so a frontmatter pin would force a NEW worktree on EVERY spawn, and a fresh fix-coder could then not cd-REUSE the first coder's worktree (breaking the per-commit-worktree reuse …)." (The "see below" cross-points the intact B1 `isolation`-parameter-values block.)

**(b) "default floor" → degraded fallback.**
- BEFORE (anchor): "For a single sequential coder it is optional; the in-place (non-isolated) regime is the default floor and works without any settings."
- AFTER: "Isolation is the class-keyed default … The in-place (non-isolated) regime is NOT the default: it is the DEGRADED fallback the agent self-detects at runtime (pwd/HEAD ground-truth) when, despite the class default, isolation did not actually take effect (a platform fall-to-main, or a CLI without worktree support)."

**(c) F-3 caveat 1 — auto-removal: MECHANISM kept, consequence reworded.**
- KEPT verbatim mechanism: "When an isolated subagent exits cleanly, Claude Code auto-removes its worktree and branch. A branch with unmerged commits can be silently deleted —"
- REWORDED consequence: "— which is why the worktree is HELD through the whole review/fix cycle and explicitly removed only AFTER the commit lands (the lifecycle rule: tear down a worktree only once its commit is confirmed landed; a failed commit KEEPS it), and the patch is produced post-review-clean, never pre-return. Pack Chat never relies on auto-removal, and agents never commit." (was: "which is why the pack's merge-back model captures the agent's work as a patch in the handoff directory BEFORE return (the patch survives auto-removal)".)

**(d) F-3 caveat 2 — best-effort isolation regime-detect → pwd/HEAD ground-truth (rule 8).**
- BEFORE (anchor): "The orchestrator therefore detects the ACTUAL regime from what the agent reports (a patch handoff ⇒ isolated; in-place edits ⇒ in-place), never from an assumed settings value."
- AFTER: "The agent therefore detects its ACTUAL regime from its own runtime pwd/HEAD ground-truth (a `worktree-agent-*` pwd/HEAD ⇒ isolated; otherwise the degraded in-place fallback), never from an assumed settings value — settings can lie, so the runtime self-detect is the only deterministic signal."

**KEEP-VERBATIM (B1) confirmed untouched:** the `baseRef` block (the `worktree.baseRef: "head"` setting + the JSON example), the `permissions.deny` recipe (the full `Bash(git …:*)` JSON deny list + the `git apply` vs `git diff` explanation), the Trinity-exempt note (Claude-only), and the BD-217/BD-218 refs (pack-side, allowed). Verified by diff — no lines in those ranges changed.

### S15 — `commit-discipline` SKILL ×3 (F-9 decouple regime↔patch-emit)

Edited `.claude` copy; byte-copied to `.codex` and `.agents` (the 3 were byte-identical pre-edit; the edits are CLI-format-agnostic prose, so content-intent is matched across all three).

**§1 "Detect your regime" — pwd/HEAD self-detect MECHANIC KEPT; reframed so the class sets the default; in-place is the DEGRADED fallback.**
- BEFORE (anchor): "- `pwd` / HEAD indicate a `worktree-agent-*` worktree ⇒ you are **ISOLATED** … - Otherwise ⇒ you are **IN-PLACE** (the default; no `isolation` param was passed)…"
- AFTER: "The DEFAULT is set by your agent class, but you VERIFY the regime you actually got from ground truth …" with class-keyed defaults (RW ⇒ isolated worktree; RO ⇒ the work's tree) and an explicit "IN-PLACE is the DEGRADED fallback, not the default." The `worktree-agent-*` pwd/HEAD self-detect mechanic + the "settings can lie" ground-truth rule are KEPT.

**§2 "Write-target rule" — DECOUPLED regime (which tree) from patch-emit (RW-only); the THIRD state added; report → /tmp; up-front "patch + report" removed.**
- Retitled "Write-target rule (two independent questions)".
- **Question A** = which tree code Writes go to (ISOLATED default vs degraded IN-PLACE fallback).
- **Question B** = do I emit a patch (RW-only) and WHEN (post-review-clean, never up front). Read-WRITE: patch produced only after review-clean when the orchestrator re-engages (SendMessage). Read-ONLY: "you emit NO patch — ever … This is the THIRD state the old binary could not express: a read-only agent operating IN a live worktree (because the work it reviews is uncommitted there) still writes only its report and produces no patch."
- **Report location (both classes):** "the report goes to the named `/tmp` handoff dir the orchestrator supplies" (the `/tmp`-write-failure fallback prose retained).

**Two downstream model-phrase carriers also reconciled (same skill):**
- §2 "Additional working directories" note (`In the ISOLATED regime that `/tmp` handoff dir is exactly where the patch + report land; in the IN-PLACE regime it is scratch only`) → reworded to decoupled framing (report always to `/tmp`; post-review-clean patch for RW; degraded in-place = report to parent path).
- §3 deliverable sentence (`in-place working-tree edits, or — in the isolated regime — the `git diff` patch emitted to the `/tmp` handoff dir`) → "The agent's deliverable on return is the report file … A read-write agent does NOT emit a patch on return; the patch is produced ONLY after a read-only reviewer confirms the work clean, when Pack Chat re-engages the most-recent read-write agent (SendMessage) to emit it."
- §6 anti-pattern (`ISOLATED writes go under `pwd` (code) and the `/tmp` handoff dir (patch + report)`) → reworded to the decoupled targets + a new anti-pattern bullet "Emitting a patch on return → a read-write agent never emits a patch up front … A read-only agent emits no patch at all."

**KEPT in S15:** the §1 pre-flight bash block (pwd/HEAD/log/ls self-detect mechanic); the §3 git-state-change ban verb lists (incl. the `git worktree` verb-ban — allowlist KEEP); the §4 pack-chat-only boundaries; the §5 trinity cross-reference. The structural shape of the skill is unchanged (BD-235 is out of scope per `skill-agent-maintenance-mechanical`).

### S16 — `implementation-report` SKILL ×3 (F-10 delete "survives auto-removal" rationale; rework the reason)

Edited `.claude` copy; byte-copied to `.codex` and `.agents` (byte-identical pre-edit; content-intent matched).

**Intro — DELETE the "survives auto-removal" rationale; rework the reason.**
- BEFORE (anchor): "in the in-place regime the edits live in the parent working tree; in the isolated regime the change set is captured as the `git diff` patch persisted to the `/tmp` handoff dir (so it survives the worktree's auto-removal on agent return)."
- AFTER: "The agent's edits live in its worktree, which is HELD through the whole review/fix cycle and removed only after the commit lands; the `git diff` patch is the post-review-clean artifact (produced when Pack Chat re-engages the most-recent read-write agent to emit it), NOT something the agent leaves on return. So the report must carry the full change set in its own right — that is what makes it self-contained, independent of the worktree's eventual teardown." (REASON reworked: self-containment is now about carrying the change set in the report, not "surviving auto-removal".)

**§4 — rework "so the report is self-contained even after the worktree auto-removes".**
- BEFORE (anchor): "- In the ISOLATED regime the canonical change set is the `git diff` patch you emitted to the `/tmp` handoff dir; paste that patch here (and name its handoff path) so the report is self-contained even after the worktree auto-removes."
- AFTER: "This is the diff of your in-worktree edits against the worktree's base. Paste it in the report itself — the report must carry the full change set so Pack Chat can re-derive it from the report alone, independent of the worktree. (You do NOT emit a `git diff` patch on return; that patch is the post-review-clean artifact Pack Chat re-engages you to produce after the reviewer confirms the work clean.)"

**§1 KEPT (per design "KEEP the regime + `worktree-agent-*` HEAD-reporting mechanic").** The §1 base/HEAD-reporting text ("In the in-place regime the base is the parent branch HEAD; in the isolated regime it is the `worktree-agent-*` checkout's HEAD …") is the explicitly-KEPT HEAD-reporting mechanic — it carries NO auto-removal rationale, so it was left intact. The "(IN-PLACE or ISOLATED — see the `commit-discipline` skill §1)" regime cross-reference is also retained.

### S18 — `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` L194 (F-12 REQUIRED)

- BEFORE: "- Spawn sub-agents in background; sub-agents run in-place by default, with opt-in worktree isolation (BD-197)"
- AFTER: "- Spawn sub-agents in background; default by agent class — RW agents (coders/fix-coders) run in an isolated worktree, RO agents (reviewers/architects/planners/auditors/researchers) run in the tree the work lives in (BD-226)"
- Both required changes made: class-keyed default flip + citation BD-197 → BD-226.

## 4. ×3 skill-copies confirmation (lock-step)

Both triads verified byte-identical post-edit (the 3 copies of each skill live under `.claude`/`.codex`/`.agents` — the SKILL triad third member is `.agents`, NOT `.agents-plugin`; verified per plan §2.5):

```
commit-discipline:   .claude == .codex   ✓   .claude == .agents   ✓
implementation-report: .claude == .codex ✓   .claude == .agents   ✓
```

No drift; content-intent matched across all three CLI skill dirs.

## 5. validate-pack result

```
$ python3 scripts/validate-pack.py ; echo "EXIT: $?"
…
============================================================
PASSED — all checks clean
EXIT: 0
```
Check 1 (SKILL.md frontmatter) ran and passed for every skill — my edits touched skill BODY only (frontmatter + skill-count unaffected, as the plan predicted). All 64 registered checks clean.

## 6. C3-files union-grep result (per-commit completeness — F-E scope = C3's OWN files)

Ran the design §5.1 expanded union phrase set over EXACTLY the 8 C3-edited files.

**Sharp grep for genuine OLD-model ASSERTION forms → ZERO:**
```
$ grep -nE "isolation is opt-in|in-place by default|default floor|default is in-place|opt-in worktree isolation|survives.*auto-removal|emits a .*patch.*and returns|patch the agent leaves|on agent return|persisted artifact|need NO isolation|patch handoff ⇒ isolated" <8 C3 files>
=== ZERO OLD-MODEL ASSERTIONS ===
```

**Broad union grep** (incl. the over-broad `emit[a-z]*[^.]*patch`, `patch + report`, `opt-in accelerator`, `in-place regime`, `isolated regime`) returns hits, ALL classified on the KEEP allowlist — NONE is an OLD-model residual:
- `emit[a-z]*[^.]*patch` over-matches NEW-model rules: "emit NO patch" (RO rule), "do I emit a patch … and WHEN?" (Question B), "Never emit a patch on return", "does NOT emit a patch on return; the patch is [post-review-clean]", "never emits a patch up front", "does NOT emit a patch up front" (OPTIONAL-FEATURES), "emit a report and no patch", "You do NOT emit a `git diff` patch on return". All NEW-model negations/rules.
- `opt-in accelerator` → OPTIONAL-FEATURES "not an opt-in accelerator" (negation). NEW.
- `patch + report` → commit-discipline `old binary ("isolated ⇒ patch + report; in-place ⇒ report") cannot express` (quotes the old binary to NEGATE it; F-9 decouple narrative). NEW.
- `in-place regime` → commit-discipline "degraded in-place regime" (the degraded-fallback framing — allowlist). NEW.
- `in-place regime` / `isolated regime` → implementation-report §1 "In the in-place regime the base is the parent branch HEAD; in the isolated regime it is the `worktree-agent-*` checkout's HEAD" (the explicitly-KEPT HEAD-reporting MECHANIC). KEEP.

**Allowlist remainders intentionally present (per the C3 KEEP allowlist):**
- the `git worktree` verb-ban (commit-discipline §3) — universal, KEEP;
- the `worktree-agent-*` pwd/HEAD self-detect MECHANIC (commit-discipline §1 + implementation-report §1) — KEEP;
- the reworded auto-removal MECHANISM sentence (OPTIONAL-FEATURES caveat 1) — KEEP (mechanism fact; consequence reworded);
- new-model framing + negations of the old binary.

**Expected model-phrase residual = 0 → ACHIEVED** (zero OLD-model assertions; broad-regex hits all allowlist).

## 7. Scope confirmation (pack-only — Check 36)

```
$ git diff --name-only
.agents/skills/commit-discipline/SKILL.md
.agents/skills/implementation-report/SKILL.md
.claude/skills/commit-discipline/SKILL.md
.claude/skills/implementation-report/SKILL.md
.codex/skills/commit-discipline/SKILL.md
.codex/skills/implementation-report/SKILL.md
pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md
pack-ops/OPTIONAL-FEATURES.md
```
8 files, all pack-side. Zero `project-template/` or `supporting-docs/` paths → `pack-only` keyword holds; Check 36 clean. Matches the C3 file set exactly (S6 ×1 + S15 ×3 + S16 ×3 + S18 ×1 = 8).

## 8. Files changed inventory

| Path | Change type | Surface |
|---|---|---|
| `pack-ops/OPTIONAL-FEATURES.md` | modified | S6 |
| `.claude/skills/commit-discipline/SKILL.md` | modified | S15 |
| `.codex/skills/commit-discipline/SKILL.md` | modified | S15 |
| `.agents/skills/commit-discipline/SKILL.md` | modified | S15 |
| `.claude/skills/implementation-report/SKILL.md` | modified | S16 |
| `.codex/skills/implementation-report/SKILL.md` | modified | S16 |
| `.agents/skills/implementation-report/SKILL.md` | modified | S16 |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | modified | S18 |

No new files, no deletions.

## 9. Unplanned modifications

None. Every edit is one of the four planned C3 surfaces (S6, S15, S16, S18). Within S15 and S16 I reconciled ALL model-phrase carriers in the edited skill bodies (commit-discipline §2 "Additional working directories" note, §3 deliverable sentence, §6 anti-pattern; implementation-report intro + §4) — these are the SAME files the plan scopes to C3 and the design §2 S15/S16 directs ("Remove the up-front 'patch + report' framing (it is in the §5.1 phrase set)"; "rework … §1 + §4 the same way"). No file outside the C3 set was touched.

## 10. Plan deviations

Zero. The plan + design were followed exactly:
- B1-verbatim blocks (baseRef / permissions.deny / Trinity-exempt / BD-217/218 refs) preserved untouched in S6.
- F-3 two caveats reworded NOT verbatim (mechanism kept; patch-timing + regime-detect reworded).
- F-13 why-not added on the RW class-default narrative (no frontmatter pin).
- F-9 decouple (regime↔patch-emit) + the THIRD state in S15.
- F-10 delete the "survives auto-removal" rationale + rework the reason in S16; the `worktree-agent-*` HEAD-reporting mechanic kept.
- F-12 default flip + BD-197→BD-226 citation in S18.
- Both skill triads lock-step.

## 11. POQs introduced

None.

## 12. Definition-of-Done checklist

| # | Item | PASS/FAIL | Evidence |
|---|---|---|---|
| 1 | S6 "What it is" RW narrative → in-worktree-cycle + patch-after-review-clean | PASS | OPTIONAL-FEATURES "What it is" reworded (§3 S6 (a)) |
| 2 | S6 RO clause → "RO agents run in the tree the work lives in" | PASS | "Read-only agents … run in the tree the work lives in …" |
| 3 | S6 "default floor" → degraded fallback, not default | PASS | "the in-place (non-isolated) regime is NOT the default … DEGRADED fallback" |
| 4 | S6 F-3 caveat 1: keep mechanism sentence, reword consequence to rule 7 + Constraint 1 | PASS | mechanism kept verbatim; consequence "worktree is HELD … removed only AFTER the commit lands … patch produced post-review-clean, never pre-return" |
| 5 | S6 F-3 caveat 2: regime-detect on pwd/HEAD ground-truth (rule 8), not patch-handoff signal | PASS | "detects its ACTUAL regime from its own runtime pwd/HEAD ground-truth … never from an assumed settings value" |
| 6 | S6 F-13: RW must NOT pin `isolation` in frontmatter (breaks fix-coder reuse) | PASS | F-13 paragraph added on RW class-default narrative |
| 7 | S6 KEEP VERBATIM: baseRef block, permissions.deny recipe, Trinity-exempt note, BD-217/218 refs | PASS | diff shows those ranges unchanged |
| 8 | S15 §1: keep pwd/HEAD self-detect mechanic; reframe class-as-default; in-place=degraded fallback | PASS | §1 reframed; mechanic + bash block kept |
| 9 | S15 §2: decouple regime↔patch-emit; add the THIRD state (RO in live worktree, no patch); report→/tmp | PASS | "two independent questions"; Question A/B; THIRD state explicit |
| 10 | S15 remove up-front "patch + report" framing | PASS | §2 note + §3 + §6 reworded; zero OLD-model assertion (sharp grep) |
| 11 | S16 delete "survives auto-removal" rationale (intro + §1/§4); rework the reason | PASS | intro + §4 reworked; sharp grep `survives.*auto-removal`/`auto-removes` = 0 |
| 12 | S16 keep regime + `worktree-agent-*` HEAD-reporting mechanic | PASS | §1 base/HEAD text retained |
| 13 | S18 flip default to class-keyed + BD-197→BD-226 | PASS | L194 reworded with both changes |
| 14 | ×3 lock-step (both triads) intact, no drift | PASS | diff: .claude == .codex == .agents for both skills |
| 15 | validate-pack exit 0 | PASS | "PASSED — all checks clean / EXIT: 0" |
| 16 | C3-files union-grep clean (allowlist only) | PASS | §6 — zero OLD-model assertions |
| 17 | pack-only scope (no project-template/supporting-docs) | PASS | §7 — 8 pack files only |
| 18 | No patch emitted; no stage/commit/apply | PASS | only Read/Edit/Write/Bash(read-only git) used; no patch file created |

## 13. Proposed commit message

`feat: v11 — BD-226 pack skills + feature doc + conceptual-review: regime/handoff decouple + isolated-parallel narrative (pack-only)`

(Pack Chat may rewrite; the agent proposes, not decides. Patch to be emitted post-review-clean on the orchestrator's request.)

---

## Rules-Applied Verification Block

| Rule (as named) | Verification evidence (measurement / quote) | Conclusion |
|---|---|---|
| `agents-never-commit` (universal) | Only Read/Edit/Write + read-only Bash git verbs used (`git rev-parse`, `git status`, `git log`, `git diff --name-only`, `grep`). No `git add`/`commit`/`apply`/`worktree`. No patch file created. `git status` post-edit shows working-tree edits only, no staging. | COMPLIANT |
| `per-action-approval-sub-agents` (universal) | No destructive op performed; `mkdir -p /tmp/handoff-bd226-C3` is the only filesystem creation (the named handoff dir). No deletions/overwrites of trusted files on own authority. | COMPLIANT |
| `preflight-stop-means-stop` (universal) | Emitted the single PREFLIGHT line ("4/4 C3 edits complete; validate-pack PASS … HEAD 28879ae … about to Write IMPL-REPORT") ONLY after all 4 edits + all verification PASSED. No parent stop/halt received. | COMPLIANT |
| `edit-in-place-not-full-rewrite` (coder) | All edits were targeted Edit calls on quoted anchors (S6 ×4 hunks, S15 + S16 hunks). B1 baseRef/permissions.deny blocks left VERBATIM (diff shows those ranges unchanged). pwd/HEAD self-detect mechanic + bash blocks kept. Skill copies replicated by byte-copy of the in-place-edited `.claude` source — no full rewrite. | COMPLIANT |
| `skill-agent-maintenance-mechanical` (universal) | Skill edits are CONTENT edits to bodies only; frontmatter preserved (Check 1 PASS); skill-count unaffected (validate-pack PASS); no structural restructure (section numbering 1–6 in commit-discipline + sections 1–9 in implementation-report intact). BD-235 structural question untouched. | COMPLIANT |
| `worktree-isolation-mergeback-ops` (universal) | Verified ISOLATED regime at runtime (pwd == toplevel == `.claude/worktrees/agent-aec2b0dd51e9db179`; HEAD == 28879ae). NO patch produced up front. Report written to the named `/tmp` handoff dir `/tmp/handoff-bd226-C3/`. No commit/apply. | COMPLIANT |
| `enumerate-encoding-surfaces` (coder) | ALL ×3 copies of commit-discipline AND ALL ×3 of implementation-report edited (`.claude`/`.codex`/`.agents`); diff confirms each triad byte-identical post-edit (§4). None omitted. | COMPLIANT |
| `pack-project-separation-of-concerns` (universal) | `git diff --name-only` = 8 pack-side files; zero `project-template/`/`supporting-docs/` paths (§7). | COMPLIANT |
| `cross-cli-reference-normalization` (coder) | The skill triads carry CLI-format-agnostic prose (the SKILL.md bodies have no per-CLI path/command differences in the edited regions), so content-intent is identical across `.claude`/`.codex`/`.agents` — byte-copy is correct here (no per-CLI normalization needed for these prose hunks; pre-edit the 3 were already byte-identical). | COMPLIANT |
| `rename-plans-measure-then-bound` (universal) | Completeness gate = C3-files union grep + KEEP allowlist, RUN and reported (§6): sharp grep = ZERO OLD-model assertions; broad-regex hits all classified on allowlist (new-model framing / negations / KEPT mechanic). Residual = 0. | COMPLIANT |
| `graph-first-context` (universal) | grep/Read used as authoritative source for every anchor + completeness check; graph not queried (injected `graphify-out/` path not in this worktree; grep/Read is the authoritative fallback per the rule's G2). | N/A: graph path absent in isolated worktree; grep/Read authoritative per G2 fallback |
| `rules-applied-verification-block` (universal) | This table — each in-force rule with quoted/measured evidence and a terminal conclusion (no AMBIGUOUS). | COMPLIANT |
