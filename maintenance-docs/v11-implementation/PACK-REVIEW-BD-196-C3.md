# PACK-REVIEW — BD-196 Commit C3 (Reviewer pass 1 of max-3)

**Verdict:** CLEAN.
**Surface:** `scripts/validate-pack.py` (Check 45 + callsite), `scripts/tests/test-validate-pack-check-45.sh` (new), `.github/workflows/validate-pack.yml` (1 wiring line).
**HEAD reviewed:** `b98888519176c6c22b5cc3fcd1194900c3d4baf2` (`b988885`). Note: the design doc was authored at `3bef42b`; C1/C2 have since landed, advancing HEAD to `b988885` and creating `pack-ops/PACK-MEMORY-RATIONALE.md` (18 `## <slug>` sections) + 18 corpus `[rationale:]` tags. The prompt's `3bef42b` is the design's authoring HEAD, not the C3 review HEAD.
**Method:** read every changed file; RAN `validate-pack.py`, the Check 45 per-check test, the Check 42 wiring test, the 32-33-34 neighbors, and Check 43; independently re-ran the synthetic harness with my own FAIL/section-scope/negative-control fixtures (not trusting the test's silent "OK").

---

## Findings

None at any severity (no BLOCKER / MUST / SHOULD / NIT).

---

## Verification results (observed, not from the IMPL-REPORT)

**1. Check 45 logic correct (§5.2).** The function parses corpus `[rationale: slug]`
from a **section-scoped** `## Pack memory` window (heading → next top-level `## ` or EOF)
and `^##\s+slug\s*$` headings from `PACK-MEMORY-RATIONALE.md`; set-equality over the
PRESENT set; FAILs on orphan in EITHER direction with a distinct, slug-naming message;
rules without `[rationale:]` are excluded. Reuses the Check 32 `check_mirror_in_sync`
set-equality pattern soundly (sorted set difference both directions). Lenient SKIP if
either surface absent. Matches §5.2 exactly.

**2. Passes at HEAD (18==18).** `python3 scripts/validate-pack.py` → **exit 0, "PASSED — all
checks clean."** Check 45 line: `18 corpus [rationale: slug] pointer(s); 18 rationale ## <slug>
section(s); sets are equal (bijection holds, no orphans in either direction).` Independently
recomputed: corpus set == rationale set, n=18, `corpus-only=∅`, `rationale-only=∅`.

**3. The test genuinely catches failures (critical).** `bash test-validate-pack-check-45.sh`
→ **3 PASS / 0 FAIL.** I did NOT trust the silent Group-1 "OK"; I re-ran the synthetic
harness directly with my own fixtures:
- orphan-corpus → **1 failure**, slug named in output. PASS.
- orphan-rationale → **1 failure**, heading named in output. PASS.
- section-scope (in-section 1==1, out-of-section stray tags) → **0 failures**. PASS.
- **negative control** (declared the stray out-of-section tags `not-counted`/`also-not` as
  rationale headings): the check flagged them as **orphan rationale headings** → proves the
  stray tags are genuinely EXCLUDED from the corpus set, i.e. section-scoping is real, not
  vacuous. PASS.

The in-tree T1–T5 cases (balanced PASS / orphan-corpus FAIL / orphan-rationale FAIL /
section-scope PASS / both-direction ≥2 FAIL) are sound and assert on `fail_count` and on
the slug name appearing in captured output — a check whose test could not fail is excluded.
Harness is portable (tmp REPO_ROOT monkeypatch, `mod.failures` save/clear/restore,
`shutil.rmtree` on every exit path, bash 3.2 / BSD-utils safe).

**4. CI wiring.** The Check 45 test step is wired in `.github/workflows/validate-pack.yml`
after the Check 43 step (`if: always()`). Check 42 (wiring guard) RUN result:
**11 per-check test files on disk; 11 workflow invocations; zero unwired.** `test-validate-pack-check-42.sh`
→ 4 PASS / 0 FAIL.

**5. Diff confined.** `git diff --name-only HEAD` = exactly `scripts/validate-pack.py` +
`.github/workflows/validate-pack.yml`; new untracked `scripts/tests/test-validate-pack-check-45.sh`
+ the IMPL-REPORT. The `validate-pack.py` diff is purely additive (zero deletion lines; new
function before `# ── Main ──` + one callsite after Check 42). No collateral edits to any
other check, to the corpus, or to the rationale file.

**6. Robustness (edge cases I exercised).** All correct:
- rule line carrying `[roles:]` but no `[rationale:]` → excluded from set (balanced). PASS.
- rationale heading with trailing whitespace / trailing tab → matched by `\s*$`. PASS.
- corpus tag with extra internal space `[rationale:  rb]` → matched by `\s*`. PASS.
- `### subhead` in the rationale file → NOT matched (`## ` + `# subhead`; `#` ∉ slug class),
  so deeper sub-headings cannot false-match.
- FAIL messages name the offending file + slug list + remediation (verified in output).
- Real `PACK-MEMORY-RATIONALE.md` has zero fenced code blocks, and the `^##\s+slug\s*$`
  anchor would not match indented/fenced lines regardless — no fenced-block false-match risk.

**7. No regression.** Neighbors RUN: `test-validate-pack-checks-32-33-34.sh` 65/65;
`test-validate-pack-check-42.sh` 4/4; `test-validate-pack-check-43.sh` 7/7 (Check 43
leak-sweep, relevant because `scripts/` is touched). Full suite exit 0.

---

## Minor observations (non-findings — recorded, no action required)

- **`## Pack memory` heading match is a prefix match** (`line.startswith("## Pack memory")`).
  A hypothetical future H2 literally named `## Pack memory-extra` would be misclassified as
  the corpus section. Today there is exactly ONE matching heading
  (`## Pack memory (project-local learnings)`, the final H2, section running to EOF), so the
  behavior is correct at HEAD. Not a finding — the trinity files are PM-only and stable; a
  collision would require deliberately authoring a second "Pack memory…"-prefixed H2. Noted
  only for future-author awareness.
- The IMPL-REPORT §7 transcribes an ABRIDGED test file (Group 1 heredoc collapsed to a
  comment) and discloses this with a NOTE pointing at the on-disk file. I reviewed the
  full on-disk file (296 lines), not the abridged §7. No discrepancy.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| No prior reviews fed in | Referenced ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2 + the plan + the C3 IMPL-REPORT only; read NO `PACK-REVIEW-*.md`. | COMPLIANT |
| Verify against code + by running, not on trust | RAN validate-pack.py (exit 0), test-45 (3/0), test-42 (4/0), 32-33-34 (65/0), test-43 (7/0); independently re-ran the synthetic harness with my own FAIL + section-scope + negative-control fixtures; recomputed the 18==18 set equality. | COMPLIANT |
| Prison rule | Did not read/cite/trust `maintenance-docs/prison/`. | COMPLIANT |
| Agents never commit / no state change | Read-only git (`rev-parse`, `diff`, `status`); RAN read-only check/test scripts; tmp fixtures under `/tmp` cleaned by the harness; no add/commit/push/mv/rm. | COMPLIANT |
| Findings format (severity + file:line + evidence + clause) | N/A — verdict CLEAN, no findings. Verification results carry the run output + clause cites (§5.2). | N/A: clean |
| Single permitted Write = this report | Only Write is this report at the prompted path. | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |

---

**End of PACK-REVIEW-BD-196-C3.md.**
