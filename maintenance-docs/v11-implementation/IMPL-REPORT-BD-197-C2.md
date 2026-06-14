# IMPL-REPORT — BD-197 C2: remove the worktree-isolation PROHIBITION + bug-era guardrails

**Role:** pack-coder. **Commit:** C2 (P2 — `pack-only`). **Date:** 2026-06-14.
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**Base HEAD (unchanged — agents never commit):** `220b6c7a77a7d7cc384195fd737ade3cd6eeb672`.

C2 removes the ACTUAL worktree-isolation prohibition rule (the `CLAUDE.md`
Pack-memory Claude-only worktree bullet) and the bug-era guardrails in the
pack-self `commit-discipline` + `implementation-report` skills + the `pack-coder`
agent files, replacing them with the enabled opt-in model. `pack-only`; touches
NO client surface. C4's work (full git-verb-denylist expansion, the
`git checkout -- <path>` carve-out drop, the `agents-never-commit` `### Workflow`
bullet amendment, PACK-CHAT merge-back codification, the mechanical backstop) was
NOT done — see "C2/C4 boundary verification" below.

---

## 0. Read attestation (read in full, no skim, no derivation)

I read each NAMED authoritative input DIRECTLY and IN FULL before any edit:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`
  — §0 exec summary, §1.1 FACT-1..5 (mode model), §3 (two independent mechanisms),
  §4.4 (why isolation is enabled), §5 (git-permission contract, for the C2/C4
  boundary), §10 (decisions D1–D6 + D-NEW), §11.1 (disposition table row 1),
  §11.2 (operational-coupling: impl-report ×3 + pack-coder ×3), §11.5 (the
  prohibition-only completeness gate + measured allowlist), §12.1 (the LITERAL
  replacement bullet + the C4 parts (b)/(c)), §12.4 (the commit-discipline ×3
  regime-detecting redesign). (Read pages 1–376 then the targeted §10–§13 span.)
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md`
  — §A commit sequence, §B "C2" (lines 79–88, the per-file task list) AND §B "C4"
  (lines 98–109, so I know the C2/C4 boundary), §C green-per-commit proof.
- `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and
  PACK-AGENTS.md current" → "Rule-change propagation procedure" (the ordered
  surfaces table + order note).
- `CLAUDE.md` `## Pack memory` IN FULL + the `### Sub-agent behavior (Claude-only)`
  subsection (the prohibition bullet, lines 325–334 pre-edit) + the Trinity-exemption
  note (lines 360–364).
- `backlog/BD-197.md` (all of it, incl. Notes 1 [Claude-only-first → BD-217] and 11
  [PROBE+SCHEMA correction; the corrected mode model]).
- Curated memory (each in full): `feedback_edit_in_place_not_full_rewrite.md`,
  `feedback_verify_full_ci_suite.md`, `feedback_manifest_regen_on_v11_surface.md`.
  `feedback_skill_agent_maintenance_mechanical.md` was NOT present as a file (checked);
  I applied the trinity rule `skill-agent-maintenance-mechanical` (CLAUDE.md, read in full).

Any conclusion I draw about these docs is grounded in the bytes I read, not derived.

---

## 1. Files changed inventory

| Path | Change type | Surface class |
|---|---|---|
| `CLAUDE.md` | modified | pack-root trinity (Claude-only subsection; manifest-EXEMPT) |
| `.claude/skills/commit-discipline/SKILL.md` | modified | pack-self skill |
| `.codex/skills/commit-discipline/SKILL.md` | modified | pack-self skill |
| `.gemini/skills/commit-discipline/SKILL.md` | modified | pack-self skill |
| `.claude/skills/implementation-report/SKILL.md` | modified | pack-self skill |
| `.codex/skills/implementation-report/SKILL.md` | modified | pack-self skill |
| `.gemini/skills/implementation-report/SKILL.md` | modified | pack-self skill |
| `.claude/agents/pack-coder.md` | modified | pack-self agent |
| `.codex/agents/pack-coder.toml` | modified | pack-self agent |
| `.gemini/agents/pack-coder.md` | modified | pack-self agent |

Exactly **10 files**, all pack-self. ZERO client/`project-template/`/`supporting-docs/`
files touched. ZERO new files. ZERO deletions. No v11-surface dir
(`project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/`) touched.

`git status --short` (final):
```
 M .claude/agents/pack-coder.md
 M .claude/skills/commit-discipline/SKILL.md
 M .claude/skills/implementation-report/SKILL.md
 M .codex/agents/pack-coder.toml
 M .codex/skills/commit-discipline/SKILL.md
 M .codex/skills/implementation-report/SKILL.md
 M .gemini/agents/pack-coder.md
 M .gemini/skills/commit-discipline/SKILL.md
 M .gemini/skills/implementation-report/SKILL.md
 M CLAUDE.md
```

---

## 2. Per-surface edits (before/after)

### 2.1 `CLAUDE.md` — the prohibition rule (design §12.1(a), plan §B C2 row 1)

REPLACED the `### Sub-agent behavior (Claude-only)` "Spawn all sub-agents with no
worktree isolation" bullet with the enabled-model opt-in bullet (literal text per
design §12.1(a), corrected 2026-06-14 mode model).

BEFORE (lines 325–334):
```
- **Spawn all sub-agents with no worktree isolation.** Do not pass
  `isolation: "worktree"` when calling the Agent tool from any chat in
  this repo. Run agents in-place against the parent chat's working
  tree. The Agent tool places sub-worktrees under the main clone's
  `.git/worktrees/` and checks them out at `origin/main` regardless
  of which worktree the parent chat is in — so an agent spawned from
  a v11-dev (or any non-main) chat would audit / edit stable content
  instead of the parent's branch. For parallelism across worktrees,
  open separate Claude Code chat sessions in separate worktree
  directories.
```

AFTER:
```
- **Sub-agents run in-place by default; isolation is opt-in.** Sub-agents
  run IN-PLACE against the parent chat's working tree by default (no
  isolation). A chat MAY opt a sub-agent into isolated parallel execution
  by passing the per-spawn Agent-tool `isolation:"worktree"` parameter
  (the TRIGGER; `"worktree"` is the only valid value); the developer
  should set `worktree.baseRef:"head"` in settings so the worktree bases
  at local HEAD (unset/`fresh` bases at origin/main — a documented
  wrong-base degradation) — see OPTIONAL-FEATURES. When isolation is
  active, read-write agents emit a patch to the named `/tmp` handoff dir
  and the orchestrator applies it; agents never commit. The agent
  VERIFIES its actual regime at runtime (pwd/HEAD ground-truth), never
  trusting settings. `worktree.bgIsolation` governs background SESSIONS
  only (not sub-agents) — BD-218. Trinity-exempt (Claude-only;
  Codex/Gemini = BD-217).
```

Section map verified intact after edit (re-read CLAUDE.md lines 323–364): the other
two bullets in the subsection (`Default sub-agent spawns to background`,
`Agent-team stage lifecycle`) and the `### Trinity exemption.` closing note (lines
360–364) are PRESERVED. The corrected model is used: no "9-cell matrix" and no
"bgIsolation-as-trigger" phrasing (both removed from the design §3). Trinity-exemption
framing preserved. NO `[rationale:]` slug added (see §7 POQ-1).

### 2.2 `commit-discipline` SKILL ×3 — regime-detecting redesign (design §12.4, plan §B C2)

The same edits applied to `.claude`, `.codex`, `.gemini` (the three were byte-identical
pre-edit and carry no per-CLI value in their body — verified — so identical content is
the audience-correct lockstep). Four targeted in-place edits per file:

1. **Frontmatter `description`** — `the write-target rule (under pwd only)` →
   `pre-flight regime detection, the regime-aware write-target rule` (reconcile the
   stale worktree-MODEL summary).
2. **§1 pre-flight** — REMOVED the hard asserts `pwd # Must end in worktree path`
   and `git rev-parse --abbrev-ref HEAD # Must start with worktree-agent-`; replaced
   with regime-DETECTING comments + a non-fatal "Detect your regime, then branch …
   Neither regime is an error" block (ISOLATED ⇒ `pwd`/`/tmp` handoff; IN-PLACE ⇒
   parent tree) + the ground-truth-not-settings directive. Removed the now-stale
   "`pwd` resolves to the main checkout" failure mode.
3. **§2 write-target** — REDESIGNED to regime-aware (IN-PLACE: parent tree;
   ISOLATED: `pwd` for code + `/tmp` handoff for patch+report, with the failed-handoff
   degradation fallback). KEPT the absolute ban on retargeting another agent's main
   checkout (the BD-119 C-2 guard) as a CAUTIONARY note, NOT a blanket "every Write
   under `pwd`".
4. **§3 git-state ban** — ADDED the read-only-only **PRINCIPLE line** (the catch-all)
   + noted `git diff > <file>` is the read-only patch-emit (the `>` is a shell op, not
   a git verb). NOTE: the FULL verb-denylist EXPANSION (clean/merge/rebase/etc.) is C4
   — NOT done here (see §3 boundary).
5. **§6 anti-patterns** — RETIRED the bug-era "wrote report to /tmp → wrong path"
   anti-pattern; replaced with regime-aware guidance ("Writing the report to `/tmp` is
   CORRECT when you are isolated …").

BEFORE (§1 asserts, the bug-era core):
```
pwd                                    # Must end in worktree path, not main checkout
git rev-parse --abbrev-ref HEAD        # Must start with `worktree-agent-`
```
```
## 2. Write-target rule

**Every `Write` and `Edit` MUST go to a path under `pwd`.** No exceptions.
```
```
- Writing the implementation report to `/tmp/<file>.md` because the
  worktree write rejected once → wrong path; re-issue under the
  worktree.
```

AFTER (§1 regime-detect, §2 header, §6 anti-pattern):
```
pwd                                    # Detect regime: a worktree-agent-* path = ISOLATED; otherwise IN-PLACE
git rev-parse --abbrev-ref HEAD        # A worktree-agent-* branch = ISOLATED; otherwise IN-PLACE
```
```
## 2. Write-target rule (regime-aware)

Your write-targets follow the regime you detected in section 1:
- **IN-PLACE regime (default):** code Writes/Edits go to paths under the parent working tree …
- **ISOLATED regime (opt-in, `isolation:"worktree"` was passed):** code Writes/Edits go to paths under `pwd` … the IMPL report + the `git diff` patch go to the named `/tmp` handoff dir …
**Absolute prohibition (both regimes): NEVER retarget another agent's main checkout.**
```
```
- Targeting the wrong write-path for your regime → … Writing the report to
  `/tmp` is CORRECT when you are isolated and the prompt named a `/tmp`
  handoff dir — it is NOT a "wrong path." …
```

§3 PRINCIPLE line added (verbatim):
```
**Read-only-only principle (the catch-all).** Read-only git verbs are
allowed only; any git verb that changes repository, index, working-tree,
ref, or config state is forbidden — including but not limited to the
verbs enumerated above. …
```

Section map verified intact after edit (re-read `.claude` copy in full: §1–§6 all
present, headers unchanged except §2's "(regime-aware)" qualifier). Bug-era asserts
ZERO across all three (grep evidence §5). All three byte-identical after edit (§5).

### 2.3 `implementation-report` SKILL ×3 — regime-aware redesign (design §11.2, plan §B C2)

The same three targeted edits applied to `.claude`, `.codex`, `.gemini` (byte-identical
pre-edit; identical content is the lockstep). The 4 worktree-MODEL refs reconciled:

1. **Intro (line 14, "if the worktree is lost")** → regime-aware: in-place = parent
   tree; isolated = the `git diff` patch persisted to `/tmp` (survives auto-removal).
2. **§1 header + body (line 21, "unchanged from the worktree base")** → "Branch +
   final HEAD SHA (and regime)"; base = parent HEAD (in-place) or the `worktree-agent-*`
   checkout HEAD (isolated @ `baseRef:"head"`).
3. **§4 modified-files + "see the worktree" (lines 43/48)** → diff against the
   section-1 base; ISOLATED = the `/tmp` patch is the canonical change set (paste it +
   name its handoff path); "do not say 'see the working tree.'"

BEFORE (the 4 carriers):
```
... re-derive every change from the report alone if
the worktree is lost.
```
```
does not commit, so the SHA is unchanged from the worktree base — that's
the point.
```
```
- **Modified files:** paste a unified diff against the worktree base,
... Do not abbreviate; do not say "see the worktree."
```

AFTER:
```
... Pack Chat must be able to re-derive every change from the report
alone — in the in-place regime the edits live in the parent working tree;
in the isolated regime the change set is captured as the `git diff` patch
persisted to the `/tmp` handoff dir (so it survives the worktree's
auto-removal on agent return).
```
```
### 1. Branch + final HEAD SHA (and regime)
... Pack-coder does not commit, so the SHA is unchanged from the
base it started at — that's the point. In the in-place regime the base is
the parent branch HEAD; in the isolated regime it is the
`worktree-agent-*` checkout's HEAD …
```
```
- **Modified files:** paste a unified diff against the base recorded in section 1 …
  - In the IN-PLACE regime this is the diff against the parent branch base.
  - In the ISOLATED regime the canonical change set is the `git diff` patch you emitted to the `/tmp` handoff dir; paste that patch here …
... or to `git apply` the patch) if needed. Do not abbreviate; do not say "see the working tree."
```

Section map verified intact (re-read `.claude` copy lines 1–60: §1–§9 present, only §1
gained the "(and regime)" qualifier). All three byte-identical after edit (§5).

### 2.4 `pack-coder` agent ×3 — worktree-MODEL prose only (design §11.2, plan §B C2 line 86)

UPDATE the worktree-MODEL prose only. The `.codex` `.toml` prose differs structurally
from the `.md` files, so the edits are audience-correct per-CLI (NOT byte-copy). The
worktree-MODEL carriers reconciled in each: (a) frontmatter `description`
("makes file changes in its worktree" → "in its scoped working tree (or an isolated
worktree when opted-in) … emits a patch + structured implementation report"),
(b) "# What you do" ("in your/its worktree" → "in your scoped working tree (or an
isolated worktree when opted-in — see the `commit-discipline` skill §1)" + "in the
isolated regime, also emit a `git diff` patch to the named `/tmp` handoff dir"),
(c) report-contents ("Branch + final HEAD SHA on your worktree" → "in your working
tree … and which regime you ran in (in-place or isolated)"), (d) Pre-flight ("Verify
your worktree base" → "Verify your working-tree base … and detect your regime …").

BEFORE (`.claude/agents/pack-coder.md`, representative):
```
- Branch + final HEAD SHA on your worktree (from `git rev-parse HEAD`)
```
AFTER:
```
- Branch + final HEAD SHA in your working tree (from `git rev-parse HEAD`),
  and which regime you ran in (in-place or isolated)
```

**C4 carve-out PRESERVED (not dropped):** the `git checkout -- <path>` exception in
the "No git state changes" block is UNTOUCHED in all three (`.claude:37`,
`.codex:21`, `.gemini:39`) — its drop is C4 work. grep evidence §3.

---

## 3. C2/C4 boundary verification (scope-deliverables-to-the-ask)

I did C2 ONLY. Explicit confirmation I did NOT do C4's work:

- **FULL git-verb-denylist EXPANSION** (adding `clean`/`merge`/`rebase`/`cherry-pick`/
  `revert`/`am`/`apply`/`branch -d/-D`/`switch`/`worktree`/`config`/etc. into §3 +
  agent files): NOT DONE. The §3 verb LIST in all three commit-discipline skills is
  UNCHANGED (only the read-only-only PRINCIPLE line was added per C2 scope). The
  `pack-coder` "No git state changes" verb list is UNCHANGED.
- **`git checkout -- <path>` carve-out DROP** from pack-coder ×3: NOT DONE — the
  carve-out is PRESERVED (1 occurrence each, grep below).
- **`agents-never-commit` `### Workflow` bullet amendment**: NOT TOUCHED.
- **PACK-CHAT.md merge-back codification**: NOT TOUCHED.
- **Mechanical backstop hook**: NOT created.

```
$ grep -c "checkout -- <path>" .claude/agents/pack-coder.md .codex/agents/pack-coder.toml .gemini/agents/pack-coder.md
.codex/agents/pack-coder.toml:1
.gemini/agents/pack-coder.md:1
.claude/agents/pack-coder.md:1
```

Note on the §3 PRINCIPLE-line-vs-verb-expansion split: my prompt's C2/C4 boundary +
design §12.4 §3 say C2 adds the read-only-only PRINCIPLE line; the FULL verb expansion
is C4 (plan line 103 keeps the verb-list hardening in C4). I added ONLY the principle
line; the verb enumeration is unchanged. (Plan C2 line 82 says "§3 carries the
denylist + principle line," but plan C4 line 103 + my prompt's explicit boundary
place the verb-denylist EXPANSION in C4 — I followed the boundary; recorded as a
non-blocking note, no deviation since the C2/C4 boundary is the binding instruction.)

---

## 4. Rule-change propagation procedure (PACK-CHAT.md §)

The prohibition rule is being CHANGED (prohibition → enabled opt-in). The procedure's
ordered surfaces, applied:

| # | Surface | Action taken |
|---|---|---|
| 1 | Corpus imperative ×3 trinity `## Pack memory` | EDITED `CLAUDE.md` ONLY — the bullet is in the **Claude-only / trinity-EXEMPT** subsection (`### Sub-agent behavior (Claude-only)`); root `AGENTS.md`/`GEMINI.md` carry ZERO worktree refs and MUST stay that way (§6). Editing only CLAUDE.md is the correct application of the procedure for this trinity-exempt rule. |
| 2 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## <slug>` | NO-OP — the prohibition bullet has **no `[rationale:]` slug** (verified: no worktree/isolation slug exists in the rationale; only `per-action-approval-sub-agents`, an unrelated rule). Nothing to remove/edit. (No new slug added — POQ-1.) |
| 3 | Thin memory-cache pointer (out-of-repo) | Pack-Chat upkeep, NOT coder — flagged for Pack Chat. |
| 4 | Reference surfaces (`PACK-AGENTS.md` / `PACK-CHAT.md` one-line refs) | NO-OP — ZERO references to the removed bullet's name/prose in either file (grep evidence §5). The rule was corpus-only with no collapsed reference. |
| 5 | `pack-ops/.spawn-rule-manifest.txt` slug→canonical | NO-OP — the prohibition bullet is NOT in the manifest (it tracks only rules with collapsed PACK-AGENTS/PACK-CHAT references; this rule had none). grep evidence §5. |
| 6 | `test-fixtures/manifest.txt` regen | RAN `bash test-fixtures/build.sh --all --clean`; manifest diff EMPTY (no v11-surface dir touched; pack-self surfaces don't feed client fixtures). NOT staged. §6 manifest determination. |

**Order honored:** corpus (1) edited; rationale (2)/references (4)/manifest (5) are
NO-OPs for this rule (nothing half-applied); cache (3) is Pack-Chat upkeep; manifest
regen (6) run last and empty. The procedure is END-STATE-verified (bijection /
anti-restate / trinity-parity / manifest all GREEN — §7 battery).

The C4 work routes `agents-never-commit` (a DIFFERENT rule, in `### Workflow`, which
DOES have the `agents-never-commit` slug + manifest entry) through this procedure with
its rationale/manifest edits — that is C4, not C2.

---

## 5. enumerate-encoding-surfaces sweep (every encoder of the prohibition's state)

The prohibition's expected state is encoded by: (a) the corpus bullet (CLAUDE.md),
(b) the rationale (no slug → no encoder), (c) the spawn-rule-manifest (not tracked →
no encoder), (d) any validator/TEST that asserts the prohibition prose or the removed
skill-assert strings. I swept (d) exhaustively:

**Tests/validators pinning the removed strings or worktree-MODEL prose — NONE:**
```
$ grep -rn "Must end in worktree|Must start with .worktree-agent|worktree-agent-|wrong path; re-issue|the worktree is lost|unchanged from the worktree base|see the worktree|on your worktree|in its worktree|in your worktree" scripts/ .github/
  (no matches)
```
- `scripts/tests/test-validate-pack-check-46.sh` references the string
  `"commit-discipline"` only as a synthetic skill-NAME in its own fabricated tree
  (it writes its own skill bodies) — it does NOT pin the real worktree content. No
  update needed.
- `scripts/tests/template-translations-test.sh` does NOT touch pack-side
  `commit-discipline`/`implementation-report`/`pack-coder`. No update needed.
- `scripts/tests/test-v11-realistic-ot.sh` (the integration test that historically
  pinned validator banners) references NO worktree/isolation/spawn-prohibition text.
- `scripts/validate-pack.py` contains ZERO worktree/isolation/Spawn-all assertions
  (grep clean). Check 46's anti-restate scan reads the `.claude` commit-discipline +
  implementation-report copies but asserts NO worktree content — it scans for
  verbatim `## Pack memory` IMPERATIVE BODY restatements (≥60 chars); my edits add no
  such restatement (PREFLIGHT-confirmed by the green Check 46 test).

**Cross-CLI byte-parity (the anti-restate comment's "parity-checked elsewhere"):**
No pack-side validator enforces byte-parity of these skills across the three CLIs
(`check_skill_frontmatter` operates on `project-template/skills/`, not pack-side
`.claude/skills/`). Regardless, I kept all three byte-identical to honor the trinity
discipline:
```
$ diff -q .claude/skills/commit-discipline/SKILL.md .codex/skills/commit-discipline/SKILL.md   → IDENTICAL
$ diff -q .claude/skills/commit-discipline/SKILL.md .gemini/skills/commit-discipline/SKILL.md   → IDENTICAL
$ diff -q .claude/skills/implementation-report/SKILL.md .codex/skills/implementation-report/SKILL.md → IDENTICAL
$ diff -q .claude/skills/implementation-report/SKILL.md .gemini/skills/implementation-report/SKILL.md → IDENTICAL
```

**No reference to the removed bullet in pack-ops surfaces:**
```
$ grep -rn "Spawn all sub-agents|no worktree isolation|isolation.*worktree|worktree isolation" \
    pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/.spawn-rule-manifest.txt
  (no matches)
```

**Bug-era asserts removed (grep-ZERO across the edited skills):**
```
$ grep -rn "Must end in worktree path|Must start with .worktree-agent|no worktree isolation|wrong path; re-issue under the" \
    .claude/skills/commit-discipline/SKILL.md .codex/... .gemini/...
  ZERO bug-era asserts remain
$ grep -rn "the worktree is lost|see the worktree|unchanged from the worktree base|diff against the worktree base" \
    .claude/skills/implementation-report/SKILL.md .codex/... .gemini/...
  ZERO bug-era worktree-model prose remains
```

**Prohibition-only completeness gate (design §11.5 gate (a)):** the matcher
`'no worktree isolation|Do not pass .*isolation.*worktree'` over the active tree
(`-g '!.git' -g '!test-fixtures'`) returns **23 files**, ALL in the LEAVE allowlist
(9 archive [D4] + 14 BD-197-process/review/research/history carriers, incl. the
landed C1 reports and all 3 PLAN-adversarial reviews). This matches the plan §F
measurement (23). **NONE of the 10 C2-scoped files match** (each grep-counted 0):
```
0  CLAUDE.md
0  .claude/skills/commit-discipline/SKILL.md   (×3 CLIs all 0)
0  .claude/skills/implementation-report/SKILL.md  (×3 CLIs all 0)
0  .claude/agents/pack-coder.md   (×3 CLIs all 0)
```
The STRIP set for the prohibition gate is empty post-C2 (C1 dispositioned the active
non-rule carriers; C2 strips the rule + bug-era guardrails, now clean). Conclusion:
the prohibition-only gate runs clean against EXACTLY the measured allowlist.

---

## 6. Trinity-exemption confirmation + manifest determination

**Trinity exemption (Claude-only) — HOLDS:**
```
$ grep -c 'worktree' AGENTS.md   → 0
$ grep -c 'worktree' GEMINI.md   → 0
$ grep -n "Sub-agent behavior (Claude-only)|isolation.*worktree|Spawn all sub-agents" AGENTS.md GEMINI.md
  (no matches — the Claude-only subsection correctly absent from root AGENTS/GEMINI)
```
The enabled bullet stayed Claude-only; it was NOT propagated to root AGENTS.md/GEMINI.md
(propagating it would break the documented Claude-only exemption for the whole
`### Sub-agent behavior (Claude-only)` subsection — BD-217 owns the Codex/Gemini story).
The trinity-parity checks in `validate-pack.py` stay GREEN (§7).

**Manifest determination — EMPTY, NOT staged:**
- C2 changed only `CLAUDE.md` (pack-root trinity, base-case manifest-EXEMPT) + the
  `.claude`/`.codex`/`.gemini` skill+agent dirs (NOT among the four v11-surface dirs
  `project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/`). The propagation
  rationale/manifest edits were NO-OPs (no slug), so `pack-ops/` was NOT touched.
- Ran `bash test-fixtures/build.sh --all --clean` (exit 0) defensively; the manifest
  diff is EMPTY (pack-self surfaces do not feed the client fixtures — no fixture SHA
  drift). `git diff --quiet test-fixtures/manifest.txt` → CLEAN. No manifest stage.
- `manifest.txt` left UNMODIFIED in the working tree (the battery's
  `restore committed manifest` step + the empty regen leave it at committed content).

---

## 7. Full CI suite results (verify-full-ci-suite — no sampling)

I extracted EVERY script wired in `.github/workflows/validate-pack.yml` (both
`validate`-job invocations incl. `PACK_VALIDATE_DEEP=1`, and EVERY `tests`-job step)
and ran each, quoting EXIT status. Baseline (pre-edit) = 60/60 GREEN; post-edit =
60/60 GREEN (identical — zero regression).

**validate job:**
- `EXIT 0` — `python3 scripts/validate-pack.py` (general)
- `EXIT 0` — `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (DEEP)

**tests job (58 steps, all `EXIT 0`):** detect.sh; tracker-provider; tracker-config;
tracker-init; tracker-agent-read; tracker-migrate forward/reverse/roundtrip; tracker
phase-task; tracker links; tracker cycle-check; tracker error mapping;
tracker-config-schema; recommendation-state-schema; per-entry helper; Check
32/33/34; **Check 36/37/38**; Check 39; Check 40; Check 41; Check 18; Check 16; Check
19; Check 42; Check 43; Check 44; Check 45; **Check 46**; Check 48 removed-doc-advisory;
Check 49/50 field-faithfulness; Check 50 codec-single-source; Check 51 flip-block;
tracker deferral gate; tracker BD-129/130/132/133/134; recommendation; pack-help;
customization-preserve; init-project; migrate-v10-to-v11 + dry-run + gates + decompose;
migrator-core; migrator-manifest; migrator-capability-translation; build test
fixtures; restore committed manifest; fixture manifest verify; **v11-realistic-ot
integration test**; migrator-skills; persona contracts; template-translations;
template-version; issue-forms.

```
===== BATTERY SUMMARY =====
PASS=60  FAIL=0
ALL GREEN
```

(Runner: `/tmp/bd197-c2-run-battery.sh`, a faithful per-name replay of the yml's two
jobs; macOS bash 3.2 compatible.)

---

## 8. Plan deviations

**ZERO plan deviations.** Every C2-scoped file in plan §B C2 (lines 79–88) was edited
exactly as specified; nothing out of C2 scope was touched. The §3 "principle line vs
verb-expansion" reconciliation between plan line 82 and plan line 103 + my prompt's
boundary is recorded in §3 as a non-deviation (I followed the explicit C2/C4 boundary:
principle line in C2, verb expansion in C4).

---

## 9. POQs introduced

**POQ-1 — Design §12.1(a) says "Propagate ×3 trinity + new rationale slug" for the
enabled bullet, but no slug was authored.**
- One-line problem: the literal §12.1(a) text ends "Propagate ×3 trinity + new
  rationale slug," yet (i) the pre-existing prohibition bullet had NO `[rationale:]`
  slug, (ii) plan §B C2 (line 81) gives no slug-authoring instruction and routes only
  the `## Pack memory` edit through the propagation procedure, (iii) the procedure +
  the spawn-rule-manifest header explicitly permit corpus-only rules WITHOUT a slug,
  and (iv) authoring a slug would add a `PACK-MEMORY-RATIONALE.md` `## <slug>` entry
  governed by the Check 45 bijection — out of the C2/C4 boundary's rule-change scope
  for the enable bullet (§12.1(b)'s `agent-two-class-model` slug is the C4 deliverable).
- Disposition: RESOLVED by proceeding with NO new slug for C2 (the recommended default).
  I read §12.1(a)'s "new rationale slug" as referring to the adjacent §12.1(b)/(c) C4
  slug work, not the enable bullet. The enable bullet remains a corpus-only,
  trinity-exempt rule with no slug — consistent with its prohibition predecessor and
  with the procedure's allowance for slug-less corpus rules.
- Recommended if Pack Chat disagrees: a fast-follow (C2b or fold into C4) authoring an
  `agent-isolation-opt-in` slug + its rationale entry + manifest record, routed through
  the full propagation procedure. Flagged for the user's call; I did not author it on
  my own authority (skill-agent-maintenance-mechanical: rule-structure changes escalate).

---

## 10. Definition-of-Done checklist

| # | Success criterion (from prompt / plan §B C2) | Status | Evidence |
|---|---|---|---|
| 1 | CLAUDE.md prohibition bullet REPLACED with enabled opt-in one-liner + OPTIONAL-FEATURES pointer | PASS | §2.1; CLAUDE.md lines 325–338; prohibition-matcher count 0 |
| 2 | Trinity nuance: NOT added to root AGENTS.md/GEMINI.md (Claude-only exemption preserved) | PASS | §6; `grep -c worktree AGENTS.md`=0, `GEMINI.md`=0 |
| 3 | Trinity-exemption framing preserved in CLAUDE.md subsection | PASS | §2.1; lines 360–364 "### Trinity exemption." intact + bullet's own "Trinity-exempt" close |
| 4 | Rule-change propagation procedure applied (corpus→rationale→references→manifest order) | PASS | §4; corpus edited, rationale/refs/manifest NO-OP (no slug, no refs) |
| 5 | `agents-never-commit` `### Workflow` bullet NOT touched (that is C4) | PASS | §3; bullet untouched |
| 6 | commit-discipline ×3: §1 regime-detect non-fatal both directions | PASS | §2.2; bug-era asserts grep-ZERO |
| 7 | commit-discipline ×3: §2 regime-aware + KEEP main-checkout ban | PASS | §2.2; "Absolute prohibition … NEVER retarget another agent's main checkout" retained |
| 8 | commit-discipline ×3: §3 git-state ban gains read-only-only PRINCIPLE line | PASS | §2.2; principle line present |
| 9 | commit-discipline ×3: §6 retire "/tmp = wrong path" anti-pattern | PASS | §2.2; replaced with regime-aware guidance |
| 10 | commit-discipline ×3: bug-era asserts removed (`pwd Must end…`, `Must start with worktree-agent-`) | PASS | §5; grep-ZERO |
| 11 | commit-discipline ×3: per-CLI audience-correct (NOT byte-copy where prose differs) | PASS | §5; the 3 were byte-identical w/ no per-CLI value → identical content is correct lockstep |
| 12 | commit-discipline ×3: did NOT do C4 full verb-denylist expansion | PASS | §3; §3 verb LIST unchanged |
| 13 | implementation-report ×3: regime-aware (in-place ⇒ parent base; isolated ⇒ /tmp patch artifact) | PASS | §2.3; 4 worktree refs reconciled, bug-era prose grep-ZERO |
| 14 | pack-coder ×3: worktree-MODEL prose UPDATED to "scoped working tree / isolated worktree when opted-in; emits patch + report" | PASS | §2.4; stale prose grep-ZERO |
| 15 | pack-coder ×3: did NOT drop the `git checkout -- <path>` carve-out (C4) | PASS | §3; carve-out count 1 each |
| 16 | enumerate-encoding-surfaces: every encoder updated in lockstep | PASS | §5; no test/validator pins the changed content; corpus+skills+agents edited |
| 17 | FULL CI suite green (no sampling) | PASS | §7; 60/60 GREEN, both validate invocations + all 58 tests-job steps |
| 18 | Manifest: run build, stage only if non-empty | PASS | §6; build exit 0, diff EMPTY, NOT staged |
| 19 | No client surface touched (`pack-only`) | PASS | §1; 0 `project-template/`/`supporting-docs/` files |
| 20 | agents-never-commit: no state-changing git verb run; HEAD unchanged | PASS | HEAD `220b6c7…` unchanged; only read-only git + edits |

All 20 PASS.

---

## 11. Proposed commit message

```
feat: v11 — BD-197 P2 remove the worktree prohibition + bug-era guardrails (trinity + commit-discipline ×3)
```
(Matches plan §A C2 subject; `pack-only` scope keyword — CI Check 36 will verify the
diff is pack-only.)

---

## 12. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **edit-in-place-not-full-rewrite** | All 10 files edited via targeted `Edit` calls (no full-file `Write`). Re-read CLAUDE.md (lines 323–364), `.claude` commit-discipline (full, §1–§6 intact), `.claude` implementation-report (lines 1–60, §1–§9 intact) after editing; confirmed section maps intact. Skills kept byte-identical across CLIs (`diff -q` IDENTICAL ×4). | COMPLIANT |
| **skill-agent-maintenance-mechanical** | The skill redesign applied the APPROVED design §12.4 mechanically + completely; no invented structural change. The one structural ambiguity (a new rationale slug) was ESCALATED as POQ-1, not improvised. The `x-`/frontmatter contract preserved (frontmatter `name`/`description`/`allowed-tools` intact). | COMPLIANT |
| **cross-cli-reference-normalization** | The enable bullet is Claude-only and NOT propagated to root AGENTS/GEMINI (`grep -c worktree`=0 both — exemption preserved). pack-coder `.codex .toml` edited in its own prose (differs from `.md`), NOT byte-copied. commit-discipline/implementation-report skills carry no per-CLI value in body → identical content is the audience-correct lockstep (verified no `.claude/.codex/.gemini`-specific token in the edited regions). | COMPLIANT |
| **enumerate-encoding-surfaces** | Swept scripts/ + .github/ + integration tests: NO test/validator pins the prohibition prose, the removed asserts, or the worktree-MODEL prose (grep evidence §5). Rationale (no slug) + spawn-rule-manifest (not tracked) + references (0 refs) are NO-OP encoders. Corpus + skills + agents all updated in lockstep. | COMPLIANT |
| **verify-full-ci-suite** | Ran EVERY script wired in `.github/workflows/validate-pack.yml` (both validate invocations incl. `PACK_VALIDATE_DEEP=1` + all 58 tests-job steps), quoting each EXIT status: `PASS=60 FAIL=0 ALL GREEN` (§7). No sampling. Baseline also captured (60/60) — zero regression. | COMPLIANT |
| **regenerate-manifest-v11-surface** | Ran `bash test-fixtures/build.sh --all --clean` (exit 0); `git diff --quiet test-fixtures/manifest.txt` → CLEAN (EMPTY diff). No v11-surface dir touched; pack-self surfaces don't feed client fixtures. NOT staged (correct — diff empty). | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by a command + verbatim output + HEAD `220b6c7a77a7d7cc384195fd737ade3cd6eeb672` + date 2026-06-14 (prohibition-matcher 23-file output §5; AGENTS/GEMINI worktree counts §6; byte-parity diffs §5; manifest empty §6; battery 60/60 §7). | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line ONLY after all edits + the FULL battery PASSED (`PREFLIGHT: C2 rule-removal + skill/agent redesign complete; … HEAD 220b6c7…; about to Write IMPL-REPORT to …`). No partial report. No parent stop/halt received. | COMPLIANT |
| **agents-never-commit** | Ran NO state-changing git verb. HEAD unchanged `220b6c7a77a7d7cc384195fd737ade3cd6eeb672` (= base). Only read-only git (`status`/`diff`/`rev-parse`/`show`) + Edit/Write + the build (manifest empty, unstaged). The battery's `git checkout HEAD -- test-fixtures/manifest.txt` is the yml's own verify-harness step (read-only-form path restore), not a state change of my scope edits. | COMPLIANT |
| **scope-deliverables-to-the-ask** | C2 ONLY: prohibition-bullet removal + regime-detect skill redesign + §3 PRINCIPLE line + impl-report regime redesign + pack-coder worktree-MODEL prose. Did NOT do C4 (verb-denylist expansion, checkout-carve-out drop, agents-never-commit bullet, PACK-CHAT merge-back, backstop) — §3 boundary verification with grep evidence. NO client surface touched. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |
