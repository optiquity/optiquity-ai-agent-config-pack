# PACK-REVIEW — BD-197 C6a (P3 PROJECT-side RW/RO two-class model — DATA half)

## VERDICT: APPROVE

C6a lands the project RW/RO SSOT (PM-CHAT permission classes), the truthful
`agent-run.sh` comment fix, and a triple-reinforcement-consistent 2 RW + 14 RO
declaration — client-native with zero pack-self refs; the C0 Check-36 manifest
carve-out PASSES its first live `project-only` exercise; full CI is green; and
all scope boundaries (no C6b/C7a leak; project carve-out still present) hold.
No defects found.

**Reviewer:** fresh pack-reviewer (read-only). **Regime:** in-place.
**HEAD:** `8e62a2ecf88fb017273379a1781957b4b6d14d82` (v11-dev). **Date:** 2026-06-14.
All commands below re-run independently; the coder's IMPL-REPORT was NOT trusted.

---

## Read attestation (read before applying the checklist)

- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §0–§5 in full (incl. §4.3
  PROJECT RW/RO triple-reinforcement, lines 254–261) + §13.2 (Guard-B project).
- `PLAN-BD-197-WORKTREE-ISOLATION.md` §B "C6a" + "C6b" + "C7a" (the boundary).
- The `git diff` of all three C6a files (PM-CHAT.md, agent-run.sh, manifest.txt).
- `IMPL-REPORT-BD-197-C6a.md` (coder claims incl. not-re-author deviation +
  surfaced `coder.toml:47` carve-out).
- `scripts/validate-pack.py` Check 36 + the `_SCOPE_NEUTRAL_GENERATED_PATHS`
  carve-out + `_is_project_side_path` / `_is_scope_neutral_generated`.
- `CLAUDE.md` `## Pack memory` in full.

---

## Findings by severity

**BLOCKER:** none.
**MUST:** none.
**SHOULD:** none.
**NIT:** none.

No real defects surfaced. The commit is clean. Sections below give the
independent evidence per checklist item.

---

## (a) The carve-out's first live exercise — VERDICT: PASSES

This is the first `project-only` commit and the first real exercise of C0's
manifest carve-out. I simulated the EXACT Check-36 `project-only` offender
comprehension (`validate-pack.py:4349–4362`) over the C6a commit set, using the
constants read from source (`_PROJECT_SIDE_PATH_PREFIXES = ("project-template/",
"supporting-docs/")` at `:4126`; `_SCOPE_NEUTRAL_GENERATED_PATHS =
frozenset({"test-fixtures/manifest.txt"})` at `:4136`):

```
project-template/docs/pack/PM-CHAT.md   project_side=True  scope_neutral=False -> OK
project-template/agent-run.sh           project_side=True  scope_neutral=False -> OK
test-fixtures/manifest.txt              project_side=False scope_neutral=True  -> OK
project-only offenders: []  -> PASS (zero offenders)
```

Counterfactual (carve-out load-bearing proof): WITHOUT the carve-out the manifest
would be the sole offender (`offenders without carve-out: ['test-fixtures/manifest.txt']`)
→ `project-only` would FAIL. The carve-out is therefore load-bearing AND correctly
sized — it exempts exactly the one forced-co-variant path and nothing else, so no
non-project content can smuggle past the boundary (the two real edits are
project-side; the manifest is the only scope-neutral path).

The carve-out gate's own regression test passes:
`scripts/tests/test-validate-pack-checks-36-37-38.sh` → EXIT 0 ("All tests passed.").

**Conclusion: the carve-out holds for its first live exercise. APPROVE.**

## (b) The not-re-author deviation (48 headers verified, not edited) — VERDICT: JUSTIFIED

The coder did NOT edit the 48 per-agent prose mandate headers (plan §B C6a lists
header reinforcement as a deliverable); it verified them instead. I confirmed:

- `git status --short` over all three agent dirs (`.claude/agents`,
  `.codex/agents`, `.gemini/agents`) shows ZERO modified files — the 48 are
  untouched.
- The headers were introduced in `43b5fe1` ("docs: v10.1 — codify per-agent
  permission profiles across all 48 project-template agent files", 2026-05-08),
  predating BD-197 — confirmed via `git log -S '**Write-capable (scoped).**'`
  on `coder.md` and `git log -L` on `.gemini/agents/architect.md`'s
  `**Read-only.**` header.
- Per-CLI survey of the actual headers: each of the 3 CLIs = 14 RO + 2 RW +
  0 NONE; RW set = `{coder (scoped), repo-ops (script)}` on every CLI.

The C6a deliverable for the headers is the third reinforcement leg being PRESENT,
CORRECT, and CONSISTENT — which it already is. Re-editing 48 correct files to
add no design/plan-specified content would violate `scope-deliverables-to-the-ask`
and `edit-in-place`, and risk introducing the very inconsistency the leg must
avoid. **Not re-authoring is the right call. JUSTIFIED.**

## Triple-reinforcement SET-CONSISTENCY (2 RW + 14 RO, set-identical)

Independently extracted all three legs and diffed the sorted RO name lists:

- **Leg 1 (PM-CHAT Profile assignment table):** 14 `Read-only` rows + `coder`
  (Write-capable scoped) + `repo-ops` (Write-capable script) = 14 RO, 2 RW.
- **Leg 2 (`agent-run.sh READONLY_AGENTS`):** 14 entries.
- **Leg 3 (48 per-file prose headers):** each CLI 14 RO + 2 RW, 0 NONE.
- **`diff` of sorted leg1 RO vs leg2 RO → IDENTICAL** (both 14 names:
  architect, auditor, auditor-architecture, auditor-code, auditor-docs,
  auditor-ops, auditor-security, auditor-tests, auditor-ui, docs-researcher,
  grpc-schema, planner, reviewer, tester). Leg 3 RO set matches the same 14.
- RW set = `{coder, repo-ops}` across all three legs.

This is exactly what C6b's Guard-B(project) (design §13.2) will assert — it is
GREEN on arrival. The new PM-CHAT prose enumerates "seven `auditor-*` cluster
members" which matches the 7 hyphenated auditor agents exactly (7 singletons +
7 auditor-* = 14 RO). Counts and names reconcile.

## PM-CHAT RW/RO SSOT (the new subsection)

`project-template/docs/pack/PM-CHAT.md` +38/-0: a new `### Permission classes
(read-write / read-only)` subsection inserted between the intro and the
`### Profile assignment` table (no existing content rewritten). It establishes:
2 RW (`coder` scoped, `repo-ops` script) + 14 RO; names this `## Permission
profiles` section authoritative; states the RO `Write`/`Edit`-for-report-only
nuance (tool set does NOT classify the agent — class carried by the prose header
+ table + `READONLY_AGENTS`); the shared no-state-changing-git-verb hard rule;
and the closing three-legs-must-agree invariant. Orchestrator = "PM chat"
(lowercase, matches the file's own convention) — client-native.

## agent-run.sh stale-comment fix

`project-template/agent-run.sh` +8/-3: only the comment block (lines ~91–100)
changed; the `READONLY_AGENTS` array is UNCHANGED (no array lines in the diff).
The false claim `"excluded at the agent-definition level"` is GONE (grep count
0), replaced by the truthful enforcement model (launch-time `--disallowedTools`
flag profile + the read-only mandate header; RO agents keep Write/Edit for the
report). `bash -n` → SYNTAX OK.

## ZERO pack-self refs (bd-pack-only-operational-rule)

Token sweep over the project-template diff's added lines — all 0:
`BD-[0-9]`, `maintenance-docs`, `pack-ops`, `PACK-AGENTS`, `PACK-CHAT`,
`Pack Chat`, `pack-coder`/`-architect`/`-reviewer`/`-planner`/`-docs-researcher`,
`Two agent classes`, `pack-self`, `pack-only`, `pack-chat-only`. A broader
`pack-` (hyphenated) grep over the added lines → none. (The file lives under
`project-template/docs/pack/` — a pre-existing client-shipped path where "pack"
denotes the installed config inside a client project, not pack-self ops; C6a
only modified the file, did not introduce the directory.)

## Manifest correctness

`git diff` = exactly 3 insertions / 3 deletions — the three v11 fixture SHAs
changed (v11-realistic-ot, v11-flat-file, v11-tracker-on); v10-minimal,
v10-realistic-ot, existing-project-mid-dev UNCHANGED (correct — only v11 fixtures
project `project-template/`). `bash test-fixtures/build.sh --verify` → EXIT 0,
all 6 fixtures "OK" against the NEW manifest. Rebuild (`--all --clean`) is
deterministic (diff stays exactly the 3 v11 lines; SHAs reproduce). The NEW v11
SHAs differ from the HEAD-committed (old) ones — the manifest was KEPT, not
restored; no `git checkout` residue.

## Full CI (independently re-run)

- `python3 scripts/validate-pack.py` → EXIT 0 ("PASSED — all checks clean").
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → EXIT 0 ("PASSED —
  all checks clean"). Check 56 (Guard-C) passes with the project-side changes;
  no pack-side guard regressed.
- Representative sample, all EXIT 0: `test-validate-pack-checks-36-37-38.sh`
  (the carve-out gate's own test), `test-validate-pack-check-56.sh`,
  `test-per-entry.sh` (57/57), `template-translations-test.sh`,
  `test-issue-forms.sh`, `test-v11-realistic-ot.sh` (33/33 — exercises the
  project-template projection + new manifest).

## Scope discipline

`git status --short`: ONLY `project-template/agent-run.sh`,
`project-template/docs/pack/PM-CHAT.md`, `test-fixtures/manifest.txt` (M) +
the untracked IMPL-REPORT. No pack-side surface touched. Boundaries confirmed:

- `project-template/.codex/agents/coder.toml:47` `git checkout (except
  \`git checkout -- <path>\`)` carve-out is STILL PRESENT (C7a drops it). ✓
- `agent-run.sh --disallowedTools` still only `Bash(git commit:*)` +
  `Bash(git push:*)` (C7a adds the hardening verbs). ✓
- No Check 55 / Guard-B(project) introduced (that is C6b). ✓
- No C7a in-session spawn content (`isolation`/`/tmp`/handoff/merge-back/Agent
  tool) leaked into the PM-CHAT diff (grep count 0). ✓

The coder correctly surfaced (not fixed) the out-of-scope `coder.toml:47`
carve-out as a C7a deliverable — consistent with the plan.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **bd-pack-only-operational-rule** | Token sweep over `git diff -- project-template/` added lines: `BD-[0-9]` 0, `maintenance-docs` 0, `pack-ops` 0, `PACK-AGENTS` 0, `PACK-CHAT` 0, `Pack Chat` 0, all `pack-*` agent names 0, `Two agent classes` 0, `pack-self` 0; broad `pack-` grep over added lines → none. | COMPLIANT |
| **pack-project-separation-of-concerns** | New PM-CHAT subsection authored client-native: orchestrator "PM chat" (lowercase, 3 occurrences in added lines), references project SSOTs (`## Permission profiles` table, `agent-run.sh READONLY_AGENTS`, per-file headers) only; not the pack `## Two agent classes` / `pack-ops/PACK-AGENTS.md`. Separate artifact, not byte-copy. | COMPLIANT |
| **cross-cli-reference-normalization** | Headers audience-correct per-CLI and UNCHANGED: `.md` vs `.toml`; `grep -rln '^tools:' project-template/.gemini/agents/` = 0/16 (Gemini prose-only). The two edits (PM-CHAT.md, agent-run.sh) are single-file, not cross-trinity. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `build.sh --all --clean` deterministic; `git diff` non-empty (3 v11 SHAs); `--verify` EXIT 0; new SHAs ≠ HEAD SHAs (KEPT, no `git checkout` restore); working tree shows manifest M (unstaged — orchestrator stages WITH commit). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Simulated Check-36 `project-only` offender logic from source constants over the C6a set → `[]` (zero offenders) → PASS; counterfactual without carve-out → manifest is sole offender (load-bearing). Carve-out sized to exactly 1 path (`test-fixtures/manifest.txt`); no broader prefix (`:4273` note + `_is_scope_neutral_generated` exact-string membership). | COMPLIANT |
| **verify-full-ci-suite** | `validate-pack.py` general + DEEP both EXIT 0; sample tests all EXIT 0 incl. check-36/37/38 (carve-out gate), check-56, per-entry (57/57), template-translations, issue-forms, v11-realistic-ot (33/33). | COMPLIANT |
| **empirical-evidence-blocks** | Every claim above carries command + verbatim output + HEAD `8e62a2e` + date 2026-06-14 + interpretation (carve-out sim, triple-leg diff, blame `43b5fe1`, manifest verify, zero-pack-self sweep). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Only PM-CHAT.md (DATA) + agent-run.sh (comment) + manifest (regen) changed; no C6b (Check 55 absent), no C7a (no in-session spawn / `--disallowedTools` hardening; `coder.toml:47` carve-out still present), no pack-side edit. Not-re-author deviation assessed JUSTIFIED. | COMPLIANT |
| **agents-never-commit** | Ran only read-only git verbs (`rev-parse`, `status`, `diff`, `log`, `show`, `branch`) + `build.sh` + `bash -n` + a python simulation; NO `git add`/`commit`/`checkout`/`apply`/any state-changing verb. Single file write = this review doc. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |
