# PACK-REVIEW-BD-197-C3 — P3 pack RW/RO two-class model + Guard-B (Check 52)

**Role:** pack-reviewer (fresh). **Mode:** read-only on the codebase; this
review doc is the sole write. **Repo:** optiquity-ai-agent-config-pack-v11-dev
· **Branch:** v11-dev. **HEAD:** `f6ee0882d6288150cb9394cdb5d666ae3ce695b3`.
**Date:** 2026-06-14. **Commit under review:** C3 (`pack-only`). All findings
independently re-verified (commands re-run; the coder's IMPL-REPORT was NOT
trusted).

## VERDICT: APPROVE-WITH-FIXES

C3 is correct, complete, and faithful to design §4.3/§13.2 + plan §B C3: the
`Class` SSOT column, the 15 audience-correct prose headers, and Guard-B
(Check 52) all landed in lockstep; the guard provably binds to the PROSE
header (NOT `tools:`), is measure-then-bound to exactly the 5 pack agents,
single-pass + runtime-guarded; the C4 carve-out is correctly still present;
scope is clean `pack-only`; full CI is green. The ONE issue is a NIT: an
internal cross-reference in `pack-ops/PACK-AGENTS.md:22` calls the subsection
`"## Two agent classes"` (H2 marker) but it actually landed as `### Two agent
classes` (H3). Fix the marker; everything else ships as-is.

## Read attestation

Read IN FULL before re-verifying: `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-
RECONCILED.md` (§0/§1/§3/§4.3/§5.3/§13.2/§14/§17), `PLAN-BD-197-WORKTREE-
ISOLATION.md` (§A/§B C0–C8/§C), `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`
(full; §1.1 pack classification + pack-reviewer tools anomaly), `IMPL-REPORT-
BD-197-C3.md` (full), `CLAUDE.md ## Pack memory` (full), and the git diff of
every C3 path.

---

## Findings by severity

### BLOCKER — none.

### MUST — none.

### SHOULD — none.

### NIT

**N-1 — `pack-ops/PACK-AGENTS.md:22` cross-reference uses the wrong heading
marker (`##` vs the actual `###`).** The SSOT note prose reads:

```
two-class agent model (see "## Two agent classes" below). It is checked
```

but the subsection landed (correctly) at line 135 as `### Two agent classes`
(H3, nested under the `## Agent permission rules` H2 at line 115). The design
literal said `"## Two agent classes"` as shorthand; the coder correctly
resolved the actual heading to H3 (an H2 would be wrong under an H2 parent —
the coder flagged this honestly in the DoD). But the in-file prose reference
was left carrying the literal `##` marker, so it now names a heading level
that does not exist in the file.
- Evidence: `grep -n 'Two agent classes' pack-ops/PACK-AGENTS.md` →
  `22:two-class agent model (see "## Two agent classes" below).` and
  `135:### Two agent classes`.
- Note: the 15 agent-file references all use the clean form `§ "Two agent
  classes"` (no marker) and are correct; only this one in-file reference is
  affected. No validator/test keys on the marker, so this is cosmetic — but
  it is a real stale reference within the C3-authored content.
- Concrete fix: change line 22 to `see "### Two agent classes" below` (or drop
  the marker entirely: `see the "Two agent classes" subsection below`).

---

## Independent re-verification (per the 7-point spec)

### 1. Class column (SSOT) — PASS
`git diff pack-ops/PACK-AGENTS.md`: roster header changed
`| Agent | Role | Mode |` → `| Agent | Class | Role | Mode |`; cells =
`pack-architect RO`, `pack-planner RO`, `pack-coder RW`, `pack-reviewer RO`,
`pack-docs-researcher RO` = 1 RW + 4 RO (matches RESEARCH §1.1). SSOT note
added naming the `Class` column the pack-side SSOT + pointing to Check 52
(set-equality; binds to prose header, never `tools:`). `### Two agent classes`
subsection added under `## Agent permission rules` (H2→H3 nesting verified:
`## Agent permission rules` at :115 → `### Two agent classes` at :135),
inserted after the "Source-write scope is the per-agent `Mode`" paragraph,
before the "pack-chat-only files" block — exactly the design §4.3 location.
Subsection body covers: no-safety-net framing, RW=`pack-coder` / RO=4,
pack-reviewer-Write/Edit-yet-RO, both-classes-obey-agents-never-commit, and
the triple reinforcement. No stale 3-column roster assertion exists anywhere
(`grep 'Agent | Role | Mode'` → only the new 4-col header + the test's
synthetic 4-col roster).

### 2. 15 prose headers — PASS
Per-file grep (RW = `Source-write within scope.`, RO = `**Read-only.**`):
all 5 ×3 = 15 carry exactly one header; exactly 3 RW (pack-coder ×3) + 12 RO
(4 agents ×3) — set-equal with the roster. Audience-correct per CLI
(decisively, the pack-reviewer trio):
- `.claude/agents/pack-reviewer.md` (has `tools: ... Write, Edit` at :6):
  header INCLUDES the `tools:` clause ("Your `tools:` lists `Write, Edit`
  ONLY to enable that report deliverable…").
- `.codex/agents/pack-reviewer.toml`: header uses the `workspace-write`
  sandbox clause (Codex mechanism), single-line TOML-style prose (no md
  wrap).
- `.gemini/agents/pack-reviewer.md` (no `tools:` field): header OMITS the
  `tools:` clause.
This is genuine per-CLI normalization, NOT a byte-copy. All 5 Codex `.toml`
files re-validated parseable (`tomllib.load` ×5 → OK). `template-translations-
test.sh` (agent-file parity ×3 CLIs) → EXIT 0 after the edits.

### 3. Guard-B (Check 52) binds to PROSE header, NOT `tools:` — PASS (decisively proven)
Code reading: `_check_52_header_class()` reads ONLY `_CHECK_52_RW_HEADER`
(`**Source-write within scope.**`) / `_CHECK_52_RO_HEADER` (`**Read-only.**`);
it never reads `tools:` / `sandbox_mode`. `_check_52_roster_classes()` parses
the roster `Class` column (second pipe cell). Failure modes covered: missing
roster cell, non-RW/RO Class value, missing file, no/both header
(unclassified), roster≠header mismatch.

Independent mutation proof on a `/tmp` copy (real tree NOT mutated — verified
pack-coder still `RW` after):

| Case | Mutation | Result |
|---|---|---|
| MUT-0 | none | 0 fails (clean) |
| MUT-A | roster pack-coder `RW`→`RO` | 3 fails — `class MISMATCH … roster RO ≠ prose header RW` (×3 CLIs) |
| MUT-B | `.claude` coder header `RW`→`RO` | 1 fail — mismatch |
| **MUT-C** | strip pack-reviewer RO header, **KEEP `Write, Edit` tools** | 1 fail — "carries no single recognized prose mandate header" |
| **MUT-D** | give RO `pack-architect` write-capable tools, **keep RO header** | **0 fails** — guard ignores `tools:` |
| MUT-E | drop pack-planner roster Class cell | caught (column-shift → "Class is `<role text>`") |
| MUT-F | roster Class=`WRITE` (bad value) | caught — "expected exactly `RW`/`RO`" |

MUT-C and MUT-D are the decisive pair: stripping the prose header fails even
though `tools:` survives (MUT-C); adding write-capable `tools:` to an RO agent
does NOT misclassify it as long as the RO header stays (MUT-D). If the check
keyed on `tools:`, MUT-D would have fired a spurious mismatch — it did not.
**Conclusively binds to prose, not tools.** Set-equality holds on the real
tree (Check 52 OK). Measure-then-bound: `_CHECK_52_PACK_AGENTS` = exactly the
5 names, `_CHECK_52_AGENT_DIRS` = exactly the 3 CLIs, with a maintenance
comment requiring lock-step extension — no broader. Single-pass (≤16
`read_text()` calls; no whole-tree scan, no subprocess-per-entry). Wall-time
measured **0.474 ms** vs the per-check WARN budget `RUN_CHECK_PER_CHECK_WARN_
BUDGET_S = 2.0 s` (~4200× under; reproduces the coder's 0.45 ms). Registered
in `main()` via `run_check("check_pack_rw_ro_two_class", …)` after the
tracker-deferral check, with a BD-197 §13.2/§4.3 cross-reference comment.

### 4. Run-before-wire + encoding surfaces — PASS
`scripts/tests/test-validate-pack-check-52.sh` exists (chmod +x, 10999 bytes),
follows the Check-51 pattern: Group 0 (symbol), Group 1 (synthetic T1–T6,
incl. T4 strip-header-unclassified and **T5 RO-despite-write-tools binds to
prose header**), Group 2 (HEAD exit-status). Couples to impl via
`mod._CHECK_52_*` constants; restores `mod.failures`/`mod.REPO_ROOT` per case.
Re-run: `bash scripts/tests/test-validate-pack-check-52.sh` → EXIT 0 (PASS 3 /
FAIL 0). Wired into `.github/workflows/validate-pack.yml` `tests` job as a
sister step right after the Check-51 step; the yml-wiring gate
`test-validate-pack-check-42.sh` → EXIT 0 (the new test is wired). SSOT + 15
headers + check source + test + yml all changed in lockstep — no orphan.

### 5. Full CI (independent) — PASS
- `python3 scripts/validate-pack.py` → EXIT 0, "PASSED — all checks clean";
  Check 52 OK line present.
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → EXIT 0.
- `test-validate-pack-check-52.sh` → EXIT 0; `test-validate-pack-check-42.sh`
  → EXIT 0; `template-translations-test.sh` → EXIT 0; `test-v11-realistic-
  ot.sh` → EXIT 0 (33/33); `test-per-entry.sh` → EXIT 0; `pack-help-test.sh`
  → EXIT 0; `template-version-test.sh` → EXIT 0; `scripts/test-persona-
  contracts.sh` → EXIT 0. No non-reproduction of the coder's green result.
  (Note: `test-persona-contracts.sh` lives at `scripts/`, NOT
  `scripts/tests/` — an initial wrong-path run gave a spurious exit 127; the
  correct-path run is EXIT 0. Not a C3 defect.)

### 6. Scope/boundary — PASS
`git status --short`: exactly the C3 paths — PACK-AGENTS.md + the 15 agent
files + validate-pack.py + validate-pack.yml (18 modified) + the IMPL-REPORT
+ test-validate-pack-check-52.sh (2 untracked). NO `project-template/` or
`supporting-docs/` path touched (`pack-only` confirmed). The `git checkout --
<path>` carve-out is STILL PRESENT in pack-coder ×3 (count = 1 each) —
correctly NOT dropped in C3 (that is C4 work per design §5.3/G-4); the
pack-coder diffs are purely additive (16 insertions = the headers only, 0
deletions). No C4/C6 work leaked in (no merge-back prose, no project RW/RO,
no carve-out drop, no OPTIONAL-FEATURES).

### 7. Manifest — PASS
Independently re-ran `bash test-fixtures/build.sh --all --clean` (EXIT 0);
`git status --short test-fixtures/manifest.txt` → 0 lines (empty diff).
Pack-self surfaces (PACK-AGENTS, agents, validate-pack, yml) don't feed the
client fixtures → manifest unchanged → cleanly `pack-only`. Matches PLAN §G
expected-empty.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | ci-guard-design-measure-then-bound | `_CHECK_52_PACK_AGENTS`=5 names, `_CHECK_52_AGENT_DIRS`=3 CLIs (sized to the measured set, lock-step maintenance comment). Binds to prose: `_check_52_header_class()` reads only the `**…**` markers, never `tools:`. Proven via MUT-C (strip RO header, keep tools → FAIL) + MUT-D (RO agent + write tools, keep header → 0 fails). Catches mismatch: MUT-A=3, MUT-B=1, MUT-F caught. | COMPLIANT |
| 2 | ci-check-runtime-compounding | ≤16 `read_text()` calls; no whole-tree scan; no subprocess-per-entry. Measured wall-time **0.474 ms** < 2.0 s WARN budget; full validate-pack EXIT 0 (no RUNTIME-BUDGET WARN). | COMPLIANT |
| 3 | enumerate-encoding-surfaces | SSOT (`Class` col) + 15 prose headers + Check-52 source + check-52 test + yml wiring all in the C3 diff; Check 42 (wiring gate) EXIT 0; template-translations EXIT 0. No validator-without-test or test-without-wiring asymmetry. | COMPLIANT |
| 4 | verify-full-ci-suite | Re-ran validate-pack (EXIT 0) + DEEP (EXIT 0) + check-52 (EXIT 0) + check-42, template-translations, realistic-ot (33/33), per-entry, pack-help, template-version, persona-contracts — all EXIT 0. | COMPLIANT |
| 5 | cross-cli-reference-normalization | pack-reviewer trio proven audience-correct: `.claude`=`tools:` clause, `.codex`=`workspace-write` sandbox clause (single-line TOML), `.gemini`=clause OMITTED (no `tools:` field). md CLIs wrap; Codex does not. Not byte-copied. All 5 Codex `.toml` parse. | COMPLIANT |
| 6 | regenerate-manifest-v11-surface | Independently ran `build.sh --all --clean` (EXIT 0); `git status --short test-fixtures/manifest.txt` → 0 lines (empty). Correctly not staged. | COMPLIANT |
| 7 | empirical-evidence-blocks | Every finding/claim carries command + verbatim output + HEAD `f6ee0882d6288150cb9394cdb5d666ae3ce695b3` + date 2026-06-14 (status, diffs, grep counts, mutation table, wall-time, test exits, manifest). | COMPLIANT |
| 8 | scope-deliverables-to-the-ask | C3 pack-side only; `git status` = C3 paths only; no client surface; C4 carve-out still present (count 1 ×3); no C4/C6/C5 leakage. Surfaced the one real defect (N-1 heading-marker) without inventing nits. | COMPLIANT |
| 9 | agents-never-commit | Ran only read-only git (`rev-parse`, `status`, `diff`) + non-git reads (`grep`, `python3`, `ls`, `bash <test>`, `build.sh`). No state-changing git verb. Only file written = this review doc. | COMPLIANT |
| 10 | rules-applied-verification-block | This block; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |
