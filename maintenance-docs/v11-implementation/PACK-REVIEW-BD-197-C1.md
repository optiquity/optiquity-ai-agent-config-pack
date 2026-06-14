# PACK-REVIEW — BD-197 C1: P2 disposition of NON-RULE worktree-prohibition carriers

**Role:** pack-reviewer (fresh, independent). **Commit under review:** C1 (`pack-only`; P2 phase).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**HEAD (pre/post, unchanged):** `e7cefbe89eecb9c9ed4ff3d5d00f79f415d4b495`.
**Date:** 2026-06-14. All findings independently re-verified (commands re-run; coder IMPL-REPORT NOT trusted).

---

## VERDICT: APPROVE

C1 dispositioned exactly the 8 NON-RULE non-process active carriers (5 prohibition/bug-era UPDATEs + 3 dangling-ref EXCISEs; RESEARCH-CLAUDE-REPOS-SURVEY is both), all reconcile-in-place to the enabled opt-in model; both strip matchers run clean against exactly the documented LEAVE set; C2 surfaces + client surfaces untouched; full CI battery independently re-verified green; manifest diff empty. No defects found.

---

## Read attestation

Read DIRECTLY and IN FULL before reviewing: the IMPL-REPORT (`IMPL-REPORT-BD-197-C1.md`, all 242 lines); plan §A + §B C0/C1 (`PLAN-BD-197-WORKTREE-ISOLATION.md` lines 1-187); design §11.1/§11.2/§11.3/§11.4/§11.5 + §12.1(a) (`ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` lines 411-499); the `git diff` of all 8 changed files; `CLAUDE.md` `## Pack memory`; memory file `feedback_fail_loud_delete_old_source.md` (case (b) reconcile-in-place clause, the load-bearing rule). Re-ran both matchers, validate-pack (standard + DEEP), the manifest build, and a representative test sample, all at HEAD `e7cefbe`.

---

## Findings by severity

**BLOCKER:** none.
**MUST:** none.
**SHOULD:** none.
**NIT:** none material to C1. (The two items the coder surfaced as out-of-scope — the BD-197 entry's stale "4 dangling refs" figure = a Pack-Chat-direct bookkeeping edit, not C1's commit; and the pre-existing cosmetic test-36/37/38 stderr noise tracked under BD-197 Note 12 — are correctly NOT C1 work. Confirmed both are accurately characterized; no action owed to C1.)

---

## Independent re-verification

### 1. Disposition correctness (read each `git diff`)

`git diff --numstat` (HEAD `e7cefbe`):
```
1	1	ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md
4	4	ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md
3	3	EXECUTION-PLAN-V11.0.md
1	1	PLAN-DOC-CONCISION-GUARDRAILS.md
25	20	PLAN-SKILL-DIMENSIONS.md
5	4	RESEARCH-19C-G-ITEMS-VERIFICATIONS.md
5	5	RESEARCH-CLAUDE-REPOS-SURVEY.md
1	1	pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md
```
Small symmetric deltas — targeted edits, not full rewrites. CONFIRMED each carrier is UPDATED to the enabled opt-in model (NOT annotated-as-superseded, NOT wholesale-rewritten):

- **CONCEPTUAL-REVIEW-METHODOLOGY.md** (digest bullet): "no worktree isolation from non-main clones" → "sub-agents run in-place by default, with opt-in worktree isolation (BD-197)". CORRECT.
- **EXECUTION-PLAN-V11.0.md §D** (items 1-3): prohibition ("No `isolation:"worktree"`… checks out `origin/main`"; "Never use Agent-tool worktree isolation") → item 1 in-place default; item 2 the full enabled model (`isolation:"worktree"` param trigger; `worktree.baseRef:"head"` required base with `fresh`=origin/main wrong-base degradation; `/tmp` patch; Claude-only/trinity-exempt; Codex/Gemini=BD-217; OPTIONAL-FEATURES pointer); item 3 opt-in OR separate sessions. Item 4 (parallel in-place) preserved. CORRECT, matches design §12.1(a) wording.
- **PLAN-SKILL-DIMENSIONS.md** (4 loci): §4.8 heading "Worktree isolation broken from v11-dev clone" → "Worktree isolation (opt-in; BD-197)" + Default/Opt-in body; §5 bullet; §6.4 spawn instruction; §8 summary line — all updated to in-place-default + opt-in. CORRECT. Section map intact (38 headings HEAD = 38 WORK; §4.8/§4.9/§6.4 all present).
- **PLAN-DOC-CONCISION-GUARDRAILS.md** (coder-spawn-template, line 187): "NO worktree isolation" → "in-place by default, with opt-in worktree isolation per BD-197". CORRECT.
- **ARCHITECTURE-BD-196-S1 row #24**: Bullet cell "Spawn all sub-agents with no worktree isolation" → "Sub-agent worktree isolation (opt-in; BD-197 replaced the prior bug-era prohibition)"; stale `L348-357` Evidence line-range → symbol-anchored "`### Sub-agent behavior (Claude-only)` worktree bullet (line numbers drift)". CORRECT — matches design §11.1 row 9 (excise stale line-range + reflect rule change) and the §11.5 row-469 update-vs-retain option (coder chose update → file drops out of the matcher; legitimate).

Dangling-ref EXCISE carriers (3):
- **RESEARCH-CLAUDE-REPOS-SURVEY.md** (5 loci): both `feedback_worktree_isolation_broken_from_v11_clone` tokens excised (L159, L299); 3 stale caveats reframed to the enabled model (L44, L300, L375). Survey integration-shape analysis preserved. CORRECT.
- **ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §6.11**: heading + dead memory-file pointer excised; "No conflict / orthogonal" analysis preserved + corrected to the enabled model. CORRECT.
- **RESEARCH-19C-G-ITEMS-VERIFICATIONS.md**: deleted-memory-pointer bullet excised; the web-evidence (GitHub issues + `baseRef="head"` workaround) and "Architect implication" prose preserved. CORRECT.

### 2. Strip-completeness gate (both matchers re-run independently)

**Prohibition matcher** — `rg -l --hidden --no-ignore 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'` → **22 files**:
- `CLAUDE.md` — the actual trinity rule (C2's job; EXPECTED to remain).
- 9× `maintenance-docs/archive/v11/*` — archive history (LEAVE per D4).
- 12× BD-197-process/history docs — RECONCILED, first design (`…WORKTREE-ISOLATION.md`), `ADVERSARIAL-REVIEW-2`, `RESEARCH-BD-197-P1`, `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY`, this PLAN, the 3 `PACK-REVIEW-…-PLAN-ADVERSARIAL{,-2,-3}`, `PACK-REVIEW-BD-197-FIX-SHOULDS`, `IMPL-REPORT-BD-197-FIX-SHOULDS`, `IMPLEMENTATION-REPORT-BD-196-C9` (history), **plus `IMPL-REPORT-BD-197-C1.md`** (the coder's own report — quotes the regex in its strip-gate evidence; legitimately a new BD-197-process artifact).

NO active non-rule non-process carrier still matches. The 3 STRIP targets (CONCEPTUAL-REVIEW-METHODOLOGY, PLAN-SKILL-DIMENSIONS, ARCHITECTURE-BD-196-S1) DROPPED OUT. **GATE CLEAN.**

**Dangling-ref matcher** — `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'` → **14 files**:
- `backlog/BD-197.md` (BD entry — Pack-Chat bookkeeping, LEAVE).
- 4× `maintenance-docs/archive/v11/*` (LEAVE per D4).
- 9× BD-197-process docs (RECONCILED, first design, `ADVERSARIAL-REVIEW`, `ADVERSARIAL-REVIEW-2`, `RESEARCH-BD-197-P1`, this PLAN, `PACK-REVIEW-…-2`, `PACK-REVIEW-…-3`, **plus `IMPL-REPORT-BD-197-C1.md`** — same self-quote rationale).

The 3 active non-process EXCISE targets DROPPED OUT. NO active non-process carrier still matches. **GATE CLEAN.**

(Note: the coder's IMPL-REPORT reported 21/13 remaining; my independent count is 22/14, the +1 each being `IMPL-REPORT-BD-197-C1.md` itself — which the coder wrote AFTER taking its measurement, so it could not have counted its own report. This is an expected artifact of the report quoting the regex, fully consistent with the design's "process-artifact set grows" mandate, and is correctly inside the LEAVE allowlist. NOT a defect.)

### 3. PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY incidental determination

`rg -n 'worktree|isolation|baseRef' …/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` → exactly 2 hits (lines 266, 268), both in the Step-S0 pre-flight ground-truth block:
```
pwd                              # Must end in worktree path or v11-dev cwd
git rev-parse --abbrev-ref HEAD  # Verify v11-dev (or worktree-agent-* if running under worktree isolation)
```
These ACCOMMODATE worktree isolation as a legitimate runtime regime; 0 prohibition-matcher hits; no `baseRef` token. Consistent with the enabled model. **INCIDENTAL → LEAVE is CORRECT.**

### 4. C2 surfaces intact

`git status --short` for `CLAUDE.md` + the 3 `commit-discipline/SKILL.md` files → all UNMODIFIED. `CLAUDE.md:325` prohibition bullet still present (C2's job). Each commit-discipline skill retains 11 `worktree` refs, unchanged. **C1 did NOT do C2's work.** CONFIRMED.

### 5. No collateral / scope

`git status --short` shows ONLY the 8 C1 disposition files (M) + `IMPL-REPORT-BD-197-C1.md` (??). Zero `project-template/` or `supporting-docs/` paths → cleanly `pack-only`. No trinity/skill/agent edit. CONFIRMED.

### 6. Full CI suite (independently re-run)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | EXIT 0 — "PASSED — all checks clean" |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | EXIT 0 — "PASSED — all checks clean" |
| `scripts/tests/test-v11-realistic-ot.sh` (banner-pin trap) | EXIT 0 — PASS 33 / FAIL 0 |
| `scripts/tests/template-translations-test.sh` (trinity/skill parity) | EXIT 0 |
| `scripts/tests/test-per-entry.sh` | EXIT 0 |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | EXIT 0 |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | EXIT 0 |
| `scripts/test-persona-contracts.sh` | EXIT 0 |
| `scripts/tests/template-version-test.sh` | EXIT 0 |

Check 48 emits 14 pre-existing JC-5 soft-advisory removed-doc WARNs (advisory only, exit-code-unaffected, unrelated to C1). The coder's "all green" claim is REPRODUCED. No non-reproduction found.

### 7. Manifest

`bash test-fixtures/build.sh --all --clean` → EXIT 0; `git status --short test-fixtures/manifest.txt` → EMPTY. pack-ops/maintenance-docs docs do not project into client fixtures → C1 stays cleanly `pack-only`. CONFIRMED. (Restored the fixture-build artifact via read-only `git checkout HEAD -- test-fixtures/manifest.txt`; working tree returns to exactly the 8 C1 files + IMPL-REPORT.)

### Section-map integrity (edit-in-place)

Heading-count HEAD-vs-working per edited doc, all identical (no dropped section):
```
EXECUTION-PLAN-V11.0: 27=27   PLAN-SKILL-DIMENSIONS: 38=38
RESEARCH-CLAUDE-REPOS-SURVEY: 28=28   ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY: 69=69
RESEARCH-19C-G-ITEMS-VERIFICATIONS: 11=11   CONCEPTUAL-REVIEW-METHODOLOGY: 28=28
```

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured, HEAD `e7cefbe`, 2026-06-14) | Conclusion |
|---|---|---|---|
| 1 | fail-loud-delete-old-source (reconcile-in-place) | Memory case (b): active doc + stale element → reconcile IN PLACE. All 8 targets are active docs reconciled via targeted `old→new` edits; `git diff` shows NO "(superseded)" annotation, NO file deletion, NO wholesale Write. §4.8 + §6.11 headings + row #24 CORRECTED in place. `--numstat` symmetric small deltas. | COMPLIANT |
| 2 | edit-in-place-not-full-rewrite | Heading counts identical HEAD-vs-working for all 6 multi-edit docs (27=27, 38=38, 28=28, 69=69, 11=11, 28=28). Diffs are localized hunks, not whole-file replacements. | COMPLIANT |
| 3 | ci-guard-design-measure-then-bound | Both matchers re-run independently: prohibition 22 files = {CLAUDE.md (C2) + 9 archive + 12 BD-197-process incl. the C1 report}; dangling-ref 14 = {BD-197 entry + 4 archive + 9 BD-197-process incl. the C1 report}. Remaining set is EXACTLY the documented LEAVE set; the 3 STRIP + 3 EXCISE targets dropped out. No active non-rule non-process carrier remains. | COMPLIANT |
| 4 | verify-full-ci-suite | validate-pack standard + DEEP both EXIT 0; banner-pin `test-v11-realistic-ot.sh` 33/33; trinity/skill `template-translations-test.sh` EXIT 0; + 5 more wired tests EXIT 0. Independently reproduced. | COMPLIANT |
| 5 | regenerate-manifest-v11-surface | `build.sh --all --clean` EXIT 0; `git status --short test-fixtures/manifest.txt` EMPTY → no manifest stage owed; C1 cleanly `pack-only`. | COMPLIANT |
| 6 | empirical-evidence-blocks | Every finding backed by the quoted command + verbatim output + HEAD `e7cefbe` + date 2026-06-14 (matcher `rg -l` lists, `--numstat`, validate-pack EXIT lines, OT 33/0 summary, manifest `git status`, heading-count diffs). | COMPLIANT |
| 7 | scope-deliverables-to-the-ask | C1 did ONLY its dispositions (8 files); C2 surfaces (CLAUDE.md:325 + 3 commit-discipline skills) UNMODIFIED; 0 client-surface paths; the 2 out-of-scope items (BD-197 "4" figure; test-36/37/38 nit) correctly surfaced not fixed. | COMPLIANT |
| 8 | agents-never-commit | Read-only git only (`rev-parse`, `status`, `diff`, `show`, the read-only `checkout HEAD -- <path>` build-artifact restore); HEAD `e7cefbe` unchanged pre/post; sole write = this review doc. | COMPLIANT |
| 9 | rules-applied-verification-block | This block addresses every Rules-in-force rule with quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

**C1 APPROVED.** 8 NON-RULE non-process active carriers reconciled in place to the enabled opt-in model (5 prohibition/bug-era UPDATEs + 3 dangling-ref EXCISEs). Both strip matchers clean against exactly the LEAVE set (trinity rule for C2 + archive + BD-197-process/history). Full CI battery independently green. Manifest diff empty. C2 + client surfaces untouched. HEAD unchanged `e7cefbe89eecb9c9ed4ff3d5d00f79f415d4b495`.

*End of PACK-REVIEW-BD-197-C1.md*
