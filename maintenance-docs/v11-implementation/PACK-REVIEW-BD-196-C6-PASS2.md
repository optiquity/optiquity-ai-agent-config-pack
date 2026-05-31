# PACK-REVIEW-BD-196-C6-PASS2 — SHOULD-1 fix re-verification

- **Reviewer pass:** 2 of max-3 (C6 of 12), BD-196
- **Mode:** READ-ONLY re-verification of fix-coder pass-1 SHOULD-1 fix
- **HEAD:** `0cbd6d5f70a6730da2023d8f2bcf45fc06cd9800`
- **Scope verified:** the single SHOULD-1 finding only (no other findings
  re-opened; no prior `PACK-REVIEW-*.md` read)

## Verdict: **CLEAN — SHOULD-1 closed, logic unchanged**

## RE-VERIFY results (against the actual files + run)

### 1. SHOULD-1 CLOSED — rationale now factually accurate. PASS.

The false name-length claim is eradicated from both surfaces. A targeted
grep for the wrong-rationale phrasings returns zero hits:

```
grep -n "56 char|longest rule NAME|longest name|NAME is 56|
  comfortably longer than any rule NAME" \
  scripts/validate-pack.py IMPLEMENTATION-REPORT-BD-196-C6.md
→ (no output)
```

The `_CHECK_46_ANTI_RESTATE_MIN_LEN` comment (`scripts/validate-pack.py`
L6209-6224) now justifies the bound on the BODY scan: "Rule-NAME length is
therefore irrelevant to the bound: names are never scanned, so a long name
cannot false-positive ... The bound separates one-line NAME references from
verbatim BODY restatements — it is body-derived, not name-derived." This is
correct: `_check_46_extract_pack_memory_imperative_bodies` discards the NAME
group (`r"^- \*\*.+?\*\*\s*(.+?)..."` captures only the post-name body), so
name length cannot drive a false positive.

Report §5 Candidate-B paragraph (`IMPLEMENTATION-REPORT-BD-196-C6.md`
L164-176) carries the same corrected body-derived rationale.

### 2. Logic UNCHANGED — predicate is comment/prose-only. PASS.

The full Check 46 block is uncommitted (working-tree only; C6 itself is not
yet committed), so a `git diff HEAD` of the predicate alone is not available
— the fix is layered on top of the same uncommitted block. I verified by
direct inspection of the live predicate surface against the FIX report's
claimed scope:

- `_CHECK_46_ANTI_RESTATE_MIN_LEN = 60` — present and unchanged (L6225).
- `_check_46_extract_pack_memory_imperative_bodies` body-extraction regex
  `r"^- \*\*.+?\*\*\s*(.+?)(?=\n- \*\*|\n\n|\Z)"` + `>= min_len` filter +
  120-char window — intact, only the docstring's NAME-exclusion sentence is
  the (already-present) explanatory text; no logic touched.
- The anti-restate scan loop in `check_boundary_and_spawn_pointer_manifests`
  (substring `if body in normalized`) — intact.

The change footprint matches the FIX report's inventory exactly: comment
prose above `_CHECK_46_ANTI_RESTATE_MIN_LEN` + report §5 prose. No predicate
token changed.

### 3. validate-pack PASS — Check 46 still 0 hits. PASS.

`python3 scripts/validate-pack.py` → **PASSED — all checks clean** (exit 0).
Check 46 line:

```
Check 46 — boundary manifest: 8 surface(s) resolve their BOUNDARY-DEFINITION
pointer; spawn manifest: 6 rule(s) resolve to `## Pack memory`; anti-restate:
0 verbatim imperative-body restatements across 6 spawn-relevant surface(s)
(45 candidate bodies scanned, >= 60 chars).
```

Identical to the pre-fix Check 46 output — confirms behavior is unchanged.

### 4. No collateral. PASS.

`git diff HEAD --stat` shows only `scripts/validate-pack.py` (+ the
adjacent C6 deliverables `.github/workflows/validate-pack.yml` and
`PLAN-DOC-CONCISION-GUARDRAILS.md`, both part of the original C6 work, not
the fix). The SHOULD-1 fix touched only the comment block + report §5;
nothing else in `validate-pack.py` or the C6 deliverables was modified by
the fix.

## Observations (non-findings; no action required)

- **Count nuance (informational, not a finding).** Report §5 L168 states
  "measured: 5 rule names are themselves ≥60 chars, the longest being 66."
  Independent measurement: 4 names are ≥60 chars when the trailing markdown
  period is excluded from the name (`Per-BD review/fix runs INLINE...` is
  exactly 60 with period, 59 without); 5 when the period is counted. "Longest
  66" holds with the period (65 without). This is a measurement-convention
  nuance (does the bold-name's terminal `.` count toward name length), not a
  logic error. The load-bearing claim — "rule-NAME length is irrelevant
  because names are never scanned" — is true under either convention, and
  the "5" appears ONLY in the report, not in the shipped `validate-pack.py`
  source comment. Not a re-opened finding; the SHOULD-1 correction stands.

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| No prior reviews to reviewer | Did not read any prior `PACK-REVIEW-*.md`; re-verified only the single SHOULD-1 finding stated in the prompt, against the live files. | COMPLIANT |
| Read-only on codebase | Only `git diff/log/rev-parse/status` (read-only), `Read`, `grep`, `python3 scripts/validate-pack.py` (permitted). No Edit/Write except this report. | COMPLIANT |
| Agents never commit | No state-changing git verb run. | COMPLIANT |
| PRISON RULE | No file under `maintenance-docs/prison/` read or referenced. | COMPLIANT |
| Findings carry severity + surface + evidence | Each RE-VERIFY item records PASS + surface (file:line) + quoted evidence/command output. | COMPLIANT |
| Verify against files not report-trust | All four items verified by direct file inspection + a live `validate-pack.py` run (exit 0), not by trusting the FIX report. | COMPLIANT |
| Empirical evidence for state-claims | "False claim eradicated" backed by zero-output grep; "logic unchanged" backed by live predicate inspection; "0 hits" backed by the actual run line; count nuance backed by independent `python3` measurement (4 stripped / 5 with period). | COMPLIANT |
| Single permitted write = report at prompted path | Sole Write is this file at the prompted path. | COMPLIANT |
| Concise | Report scoped to the one re-verified finding. | COMPLIANT |
