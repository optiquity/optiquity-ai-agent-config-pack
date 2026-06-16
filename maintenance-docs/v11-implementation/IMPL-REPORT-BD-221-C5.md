# IMPL-REPORT — BD-221 C5 (Pack-self agent-model fork → Antigravity plugin)

**Commit:** C5 — pack-only. **Branch:** `v11-dev`. **Regime:** in-place
(no `/tmp` handoff dir named in the prompt; edits left in the working
tree). **Base HEAD:** `f0952b6d82ed67b0e2988ad0787e7b4a773aba40`
(post-C4). **Final HEAD:** `f0952b6d82ed67b0e2988ad0787e7b4a773aba40`
(unchanged — agents never commit; this is the working-tree state at
report time). **`agy --version`:** `1.0.8`. **Date:** 2026-06-15.

> ⚠️ **PREFLIGHT NOT CLEAN — STOP-AND-REPORT (`preflight-stop-means-stop`).**
> The five C5 edits are complete and correct per the blueprint (plan §3
> C5 + §1.2 OQ-3). The baseline→post-C5 delta is **{43, 52, 56}**. Two of
> the three (52, 56) are the plan's expected hard breaks (deletion of the
> pack agent dir), restored at C8. **The third — Check 43 — is an
> UNEXPLAINED break the plan does not anticipate and assigns no restoring
> commit.** It is caused by C5 *creating* a second `plugin.json` and a
> second `RUNTIME-SUBAGENT-PATTERN.md`, which makes C1/C3's already-landed
> bare cross-references ambiguous. Per the prompt's contract ("Any
> UNEXPLAINED break → STOP and report"), I did NOT emit a green PREFLIGHT.
> The C5 in-scope work is done; Check 43 is surfaced as a new POQ
> (POQ-C5-1) requiring Pack Chat re-prompting / plan amendment. I made NO
> out-of-scope edit to fix it (the fix lives in `scripts/validate-pack.py`
> = C8 scope, or in C1/C3 client files = C1/C3 scope — both outside C5
> pack-only scope).

---

## 1. Per-task summary

### Task 1 — DELETE the 5 pack-root `.gemini/agents/pack-*.md`

Deleted via filesystem `rm` (not a git verb — `agents-never-commit`):

| Path (deleted) | Lines (at HEAD) |
|---|---|
| `.gemini/agents/pack-architect.md` | 62 |
| `.gemini/agents/pack-coder.md` | 189 |
| `.gemini/agents/pack-docs-researcher.md` | 63 |
| `.gemini/agents/pack-planner.md` | 64 |
| `.gemini/agents/pack-reviewer.md` | 67 |

`.gemini/agents/` is now empty. Verification: `ls -la .gemini/agents/`
→ no `.md` files; `git status --short` shows 5 ` D` rows.

### Task 2 — CREATE the pack-self plugin bundle `.agents-plugin/pack-agents/`

| Path (new) | Lines | Role |
|---|---|---|
| `.agents-plugin/pack-agents/plugin.json` | 7 | bundle marker (FORWARD-LOOKING field schema via `comment-RE-VERIFY`) |
| `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` | 99 | pack-audience runtime fallback hedge |
| `.agents-plugin/pack-agents/agents/pack-architect.md` | 86 | RO agent template |
| `.agents-plugin/pack-agents/agents/pack-coder.md` | 191 | RW agent template |
| `.agents-plugin/pack-agents/agents/pack-docs-researcher.md` | 84 | RO agent template |
| `.agents-plugin/pack-agents/agents/pack-planner.md` | 88 | RO agent template |
| `.agents-plugin/pack-agents/agents/pack-reviewer.md` | 88 | RO agent template |

Bundle layout matches the confirmed-stable shape (`plugin.json` marker +
`agents/` dir + the runtime hedge doc), parallel to C1's
`optiquity-agents` layout but with a different bundle name and
pack-audience content. The FORWARD-LOOKING inner-schema markers
(`<!-- RE-VERIFY at impl: ... gemini-cli #27305, antigravity.google/docs/cli-plugins -->`
HTML comment header on each agent template + plugin.json `comment-RE-VERIFY`
+ per-agent `# RE-VERIFY at impl: model IDs ...`) are present on every
template, mirroring C1.

Verification: `find .agents-plugin -type f` → exactly 7 files; `grep
"^name:"` → 5 names preserved exactly.

---

## 2. The 5 pack-agent names (old → new) — preserved EXACTLY

| Deleted (`.gemini/agents/`) | Created (`.agents-plugin/pack-agents/agents/`) | `name:` frontmatter |
|---|---|---|
| `pack-architect.md` | `pack-architect.md` | `pack-architect` |
| `pack-coder.md` | `pack-coder.md` | `pack-coder` |
| `pack-docs-researcher.md` | `pack-docs-researcher.md` | `pack-docs-researcher` |
| `pack-planner.md` | `pack-planner.md` | `pack-planner` |
| `pack-reviewer.md` | `pack-reviewer.md` | `pack-reviewer` |

Names are identical in both the filename and the YAML `name:` field —
no renames. The two-class split is preserved: pack-coder is the sole RW
(read-write) agent; pack-architect / pack-docs-researcher / pack-planner
/ pack-reviewer are RO (read-only). Each template carries the
two-class-model reference (`pack-ops/PACK-AGENTS.md` § "Two agent
classes"), the absolute git-state-change ban, the RO-emit / RW-emit
patch-handoff prose, and (for pack-coder) the full boundary-discipline
pre-flight (P-missed-7).

---

## 3. SEPARATE-from-C1 confirmation (`pack-project-separation-of-concerns`)

The pack-self bundle is a SEPARATE artifact from C1's client bundle, NOT
a byte-copy:

- **Different bundle name:** `pack-agents` (pack-root) vs `optiquity-agents`
  (`project-template/`).
- **Different audience/vocabulary:** pack-developer roles (pack-architect
  for "pack file structure and naming conventions across project-template/",
  cross-tool parity, migration strategy, version planning; pack-coder for
  "execute an approved implementation plan against pack source"; references
  to `pack-ops/PACK-AGENTS.md`, `/backlog/`, `/changelog/`, `maintenance-docs/`,
  the Pack Chat orchestrator, the `commit-discipline` / `boundary-investigation`
  pack skills). C1's templates carry client/project vocabulary (repository
  layer discipline, `ARCHITECTURE.md`, `BACKLOG.md`/`CHANGELOG.md` at the
  PROJECT root, the PM chat, `REPORT FILE:` convention).
- **Empirical byte-copy check:** ran `cmp -s` of every pack bundle file
  against every C1 bundle file (7 × 18 pairs). **Zero matches** — no pack
  file is byte-identical to any C1 file. Output: "(no BYTE-COPY lines)".
- **`diff` of the closest analog** (pack `pack-coder.md` vs client
  `coder.md`): DIFFERENT.

This is the pack-side analog of C1 (which forked the 16 CLIENT agents) —
a deliberately independent artifact, not a copy.

**Note on the bundle inner filenames (`plugin.json`,
`RUNTIME-SUBAGENT-PATTERN.md`).** These two basenames are intentionally
shared across BOTH bundles because they are structurally fixed: `plugin.json`
is the ecosystem-mandated marker name, and `RUNTIME-SUBAGENT-PATTERN.md` is
the plan-specified hedge-doc name for BOTH bundles (plan §3 C1 + §3 C5).
This is the `filename-uniqueness-heuristic` "structurally required
collision" exempt category — but it has a downstream validator consequence;
see §5 POQ-C5-1.

---

## 4. Baseline → post-C5 validate-pack delta (`verify-full-ci-suite`)

Both runs: `python3 scripts/validate-pack.py` (full battery, no
`--only-check`). Failing-check sets extracted by mapping every `FAIL:`
line to its `── Check N ... ──` section header.

- **BASELINE (post-C4):** `EXIT=1`, "FAILED — 50 issue(s) found".
  Failing checks: **{5, 17, 18, 21, 28, 39, 41, 55, 57}** — exactly the
  9 expected per the prompt's intermediate-red contract. ✅ matches.
- **POST-C5:** `EXIT=1`, "FAILED — 60 issue(s) found".
  Failing checks: **{5, 17, 18, 21, 28, 39, 41, 43, 52, 55, 56, 57}**.
- **DELTA (new failing checks added by C5):** **{43, 52, 56}.**

The 9 baseline checks are unchanged (none flipped green; none of those is
attributable to C5). The delta is the 3 new breaks below.

### Delta mapping — each new break → cause → restoring commit

| Check | Function | Cause (C5 action) | Expected? | Restoring commit |
|---|---|---|---|---|
| **52** | `check_pack_rw_ro_two_class` (Guard-B, BD-197) | DELETION of `.gemini/agents/pack-*.md` — "measured pack set is 5 agents × 3 CLIs"; the gemini leg of all 5 is now absent | **YES** — the plan's named `check_pack_rw_ro_two_class` hard break (plan §3 C5 + §4 break-inventory C5 row) | **C8** (re-express to plugin-roster) |
| **56** | `check_destructive_git_verb_parity` (Guard-C, BD-197) | DELETION of `.gemini/agents/pack-coder.md` — the representative verb-parity surface "not found (measured enumeration set is 10 surfaces)" | **YES** — the plan's named `check_destructive_git_verb_parity` hard break (plan §3 C5 + §4 break-inventory C5 row) | **C8** (re-express to plugin-roster) |
| **43** | `check_project_side_bare_internal_refs` (BD-173, "Project-side bare cross-reference scanner") | **CREATION** of `.agents-plugin/pack-agents/plugin.json` + `.../RUNTIME-SUBAGENT-PATTERN.md` — a SECOND basename for each; C1/C3's already-landed bare refs to `plugin.json` / `RUNTIME-SUBAGENT-PATTERN.md` now resolve to **2 candidates** → ambiguous → FAIL | **NO — UNEXPLAINED by the prompt's "deletion" cause; NOT anticipated anywhere in the plan; NO restoring commit assigned** | **NONE in the plan** — see POQ-C5-1 |

Check 52 / Check 56 are the clean, expected deletion breaks: their
representative-path lookups (`.gemini/agents/pack-*.md`) `fail()` once the
agents are deleted, exactly as the plan predicted, and C8 re-expresses
them to the plugin-roster shape. ✅

### Check 11 graceful-degradation CONFIRMED (the SHOULD requirement)

The plan's C5 SHOULD requires the coder to CONFIRM `compare-agent-trinity.py`
degrades gracefully (emits a parseable `summary:` line, not a crash) across
the C5→C9 window before landing C5. **CONFIRMED:**

- Check 11 (`check_pack_agent_trinity`) invokes
  `compare-agent-trinity.py --all --pack <ROOT> --summary-only`. The
  comparator's `--all` mode discovers names from
  `project-template/.claude/agents/` and reads
  `project-template/.{claude,codex,gemini}/agents/<name>.md` — it reads
  the **project-template** tree, NOT the **pack-root** `.gemini/agents/`
  that C5 deletes. So C5's deletion is structurally irrelevant to the
  comparator.
- Post-C5 run of Check 11: `OK: 16 agents checked, 16 divergent
  (informational; not a failure)` — the comparator emitted a parseable
  `summary: 16 agents checked; 16 divergent` line and Check 11 stayed
  `ok(...)` (informational on divergence per validate-pack.py
  `check_pack_agent_trinity`). It did NOT crash and did NOT hard-fail.
- Therefore Check 11 is NOT in the C5 delta (NIT-1 confirmed: informational
  on divergence; the comparator-crash hard-fail path SHOULD did not trigger).
  No need to move the comparator conversion earlier; C9 covers the steady
  state.

---

## 5. New POQ introduced

### POQ-C5-1 — Check 43 (`check_project_side_bare_internal_refs`) breaks on the dual-bundle filename collision; the plan assigns no restoring commit

**What happened.** Check 43 was GREEN at baseline (post-C4):
"157 project-side / client-installed file(s) walked; zero pack-internal
bare cross-references". C5 creates a SECOND `plugin.json` and a SECOND
`RUNTIME-SUBAGENT-PATTERN.md` (at `.agents-plugin/pack-agents/`). C1/C3's
already-landed bare references — e.g.
`project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md:10`
(``plugin.json``), `.../agents/auditor.md:36` (``RUNTIME-SUBAGENT-PATTERN.md``),
`project-template/GEMINI.md:458-459` (both basenames) — now resolve to 2
candidates each → ambiguous → 4 FAIL lines.

**Why C5 cannot fix it in-scope.** The break is real and structurally
unavoidable within C5: the two colliding basenames are ecosystem-fixed
(`plugin.json`) / plan-mandated for both bundles (`RUNTIME-SUBAGENT-PATTERN.md`),
so they cannot be renamed. The remediations Check 43 itself offers are:
(a) qualify the bare refs in the C1/C3 client files (those files are
`project-template/...` and `project-template/GEMINI.md` — **C1 / C3 scope,
already landed, out of C5 pack-only scope**); or (b) add the two basenames
to `_CHECK_43_ALLOWLIST` in `scripts/validate-pack.py` (**C8 scope — the
validator; out of C5 pack-only scope**). C5's pack-only scope is ONLY the
pack-root `.gemini/agents/pack-*.md` (delete) + `.agents-plugin/pack-agents/`
(create). I made NO edit outside that scope.

**Why this is a plan gap, not an expected red.** The plan's intermediate-red
inventory (§4) for C5 names exactly two hard breaks
(`check_destructive_git_verb_parity`, `check_pack_rw_ro_two_class`) plus the
informational Check 11. The plan's C8 PATH-TOKEN-CONVERT list names
`check_bare_pack_ops_refs` (a DIFFERENT check) but does NOT name Check 43
(`check_project_side_bare_internal_refs`) or `_CHECK_43_ALLOWLIST`. No
commit anywhere in the plan handles the dual-bundle inner-filename
collision. Grep of the whole plan for `Check 43` / `_CHECK_43` / "bare
cross-ref" / "collision" / "filename-uniqueness" → zero hits.

**Disposition (proceed-with-default per the coder POQ rule).** I did NOT
silently re-design and did NOT make any out-of-scope edit. The C5 in-scope
deliverable is complete and correct. I am surfacing POQ-C5-1 for Pack Chat
to triage. **Recommended default** (smallest correct, evidence-based): add
`plugin.json` and `RUNTIME-SUBAGENT-PATTERN.md` to `_CHECK_43_ALLOWLIST` in
`scripts/validate-pack.py` with a one-line rationale (these are
structurally-fixed bundle inner-filenames shared by both the client and
pack-self bundles — `filename-uniqueness-heuristic` exempt-collision), and
fold that into **C8** (the validator/per-check-test commit, whose Depends-on
already includes C1 + C5). Alternatively, qualify the four bare refs in the
C1/C3 client files — but that is C1/C3-surface work and the allowlist route
is cleaner (one validator edit vs four content edits across two landed
commits). Either way, Check 43 restoration must be ADDED to the plan; it is
not currently scheduled. Pack Chat should re-prompt the planner/architect to
amend the plan (assign Check 43 to C8), or scope the C8 coder to include the
`_CHECK_43_ALLOWLIST` addition.

---

## 6. Plan deviations

**One deviation, forced by an unanticipated break (POQ-C5-1).** The plan's
C5 verification criteria are all met (5 names preserved; SEPARATE artifact;
no byte-copy; bundle layout valid; `agy --version` pinned; comparator
graceful-degradation confirmed). The deviation is that the post-C5 delta is
**3** breaks, not the **2** the plan's §4 C5 inventory predicts — the extra
break (Check 43) is the plan gap documented as POQ-C5-1. I did NOT deviate
on scope: zero out-of-scope edits. No other deviations.

---

## 7. Files-changed inventory

| Path | Change type |
|---|---|
| `.gemini/agents/pack-architect.md` | deleted |
| `.gemini/agents/pack-coder.md` | deleted |
| `.gemini/agents/pack-docs-researcher.md` | deleted |
| `.gemini/agents/pack-planner.md` | deleted |
| `.gemini/agents/pack-reviewer.md` | deleted |
| `.agents-plugin/pack-agents/plugin.json` | new |
| `.agents-plugin/pack-agents/RUNTIME-SUBAGENT-PATTERN.md` | new |
| `.agents-plugin/pack-agents/agents/pack-architect.md` | new |
| `.agents-plugin/pack-agents/agents/pack-coder.md` | new |
| `.agents-plugin/pack-agents/agents/pack-docs-researcher.md` | new |
| `.agents-plugin/pack-agents/agents/pack-planner.md` | new |
| `.agents-plugin/pack-agents/agents/pack-reviewer.md` | new |

`git status --short`: 5 ` D` rows + `?? .agents-plugin/`. No edits to
`scripts/validate-pack.py`, the pack-root trinity, `pack-ops/`, the
project-side, install/migrators, or `test-fixtures/manifest.txt` — all
out of C5 scope, untouched. Manifest regeneration is C10-only (NOT done
here; `regenerate-manifest-v11-surface` is deferred to C10 per the plan's
explicit C10-only directive for this whole conversion).

---

## 8. Definition-of-Done checklist

| Item | Status |
|---|---|
| 5 pack-root `.gemini/agents/pack-*.md` deleted (via `rm`, not git) | PASS |
| `.agents-plugin/pack-agents/` bundle created (`plugin.json` + `agents/` 5 + `RUNTIME-SUBAGENT-PATTERN.md`) | PASS |
| 5 pack-agent names preserved EXACTLY (filename + `name:` field) | PASS |
| SEPARATE artifact from C1 (different name, pack-audience, no byte-copy — `cmp -s` zero matches) | PASS |
| `plugin.json` field schema FORWARD-LOOKING (`comment-RE-VERIFY` HTML/JSON-comment marker) | PASS |
| Per-agent FORWARD-LOOKING inner-schema + model-ID RE-VERIFY markers present | PASS |
| RO/RW two-class model preserved (pack-coder RW; other 4 RO) | PASS |
| `agy --version` recorded (`1.0.8`) | PASS |
| Comparator graceful-degradation CONFIRMED (Check 11 OK, parseable summary, no crash) — the SHOULD | PASS |
| Baseline captured = expected {5,17,18,21,28,39,41,55,57} | PASS |
| Post-C5 delta mapped; 52+56 expected→C8 | PASS |
| Delta is EXPECTED-ONLY (no unexplained break) | **FAIL — Check 43 unexplained (POQ-C5-1)** |
| Zero out-of-scope edits (pack-only; no validator/trinity/pack-ops/project/install/manifest edits) | PASS |
| No state-changing git verb run | PASS |
| IMPL-REPORT written to the prompt-specified path | PASS |

**Net:** all C5 in-scope deliverables PASS; the single FAIL is the
delta-purity check, driven by a plan gap (POQ-C5-1), not by a C5
scope/quality defect.

---

## 9. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | All edits in-place. Deletions via filesystem `rm .gemini/agents/pack-*.md` (not `git rm`). Read-only git only: `git rev-parse HEAD` → `f0952b6...`; `git status --short` → 5 ` D` + `?? .agents-plugin/`; pristine reads via `git show HEAD:.gemini/agents/<a>.md`. Final HEAD == base HEAD `f0952b6` (no commit). Zero state-changing git verbs run. | COMPLIANT |
| **pack-project-separation-of-concerns** | `cmp -s` over all 7×18 pack-vs-C1 file pairs → "(no BYTE-COPY lines)"; `diff` pack `pack-coder.md` vs client `coder.md` → "DIFFERENT"; bundle name `pack-agents` ≠ `optiquity-agents`; pack-audience vocabulary (pack-ops/PACK-AGENTS.md, /backlog/, /changelog/, Pack Chat, pack-architect role text on project-template structure) distinct from C1's client/project vocabulary. | COMPLIANT |
| **preflight-stop-means-stop** | Edits + baseline-delta verification ran. Delta is NOT expected-only (Check 43 unexplained). Per the rule, I did NOT emit a clean/green PREFLIGHT; instead I report what went wrong (POQ-C5-1) and emit a STOP-style preflight line. No parent stop/halt was received during the run. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All 7 bundle files are NEW (full `Write` is correct for new files). No existing file was rewritten — the 5 old agents were DELETED (not edited), and no other existing file was touched. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Implemented EXACTLY plan §3 C5: delete 5 pack-root `.gemini/agents/pack-*.md` + create `.agents-plugin/pack-agents/` (plugin.json + 5 agents + RUNTIME-SUBAGENT-PATTERN.md). `git status --short` shows ONLY those paths. No validator/trinity/pack-ops/project-side/install/manifest edit. The discovered Check 43 break was SURFACED (POQ-C5-1), not silently fixed and not ignored. | COMPLIANT |
| **verify-full-ci-suite** | Ran full `python3 scripts/validate-pack.py` (no `--only-check`) at baseline AND post-C5. Baseline {5,17,18,21,28,39,41,55,57} (50 issues); post-C5 {5,17,18,21,28,39,41,43,52,55,56,57} (60 issues); delta {43,52,56} quoted §4 with per-check section evidence + restoring-commit map. Comparator confirmed via direct `compare-agent-trinity.py --all` run + Check 11 OK banner. | COMPLIANT |
| **rules-applied-verification-block** | This table; every prompt-named rule has quoted/measured evidence + a non-empty terminal conclusion (COMPLIANT/N-A/VIOLATED — no AMBIGUOUS, no empty evidence). | COMPLIANT |

---

*End of IMPL-REPORT-BD-221-C5.md — in-place regime, working-tree HEAD
`f0952b6`, 2026-06-15. C5 in-scope work complete; Check 43 (POQ-C5-1)
surfaced for Pack Chat triage / plan amendment before C8. No commit (agents
never commit) — Pack Chat reads this report, runs the review/fix cycle, and
commits with user approval.*

