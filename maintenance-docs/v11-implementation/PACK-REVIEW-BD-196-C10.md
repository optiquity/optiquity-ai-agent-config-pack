# PACK-REVIEW — BD-196 C10 (M4 concision gate, Check 44) — Reviewer pass 1

**Verdict: CLEAN.** The M4 concision gate has REAL TEETH (independently
confirmed by live STRIP injection → exit 1, reverted) and the allowlist is
BOUND EXACTLY to the 6 measured KEEP occurrences (no widening, no
over-binding). All four ENCODING surfaces landed in lock-step; Check 42 =
13/13; validate-pack exit 0; test-44 3/3; neighbors green; only the 4
in-scope files changed; manifest diff empty.

- **Branch / HEAD:** `v11-dev`, HEAD `60ec0db` (C10 edits uncommitted).
- **Reference docs:** PLAN-DOC-CONCISION-GUARDRAILS.md §3 C10 + EE-P1;
  ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §6 (M1–M4) + §7. No prior
  PACK-REVIEW read.
- **Findings:** none (0 BLOCKER / 0 MUST / 0 SHOULD / 0 NIT).

---

## 1. CI-guard measure-then-bound (THE priority check) — PASS

### 1.1 Independent live-tree measure (HEAD 60ec0db)

> **Empirical-Evidence — STRIP-class = 0 across all 7 M4 docs.**
> Command: `grep -nE '20[0-9]{2}-[0-9]{2}-[0-9]{2}|\b[0-9a-f]{7,40}\b|Commit [0-9]|Override [0-9]|post-Commit' pack-ops/<doc>.md`
> for each of the 7. HEAD `60ec0db`, 2026-05-31.
> Output: `BOUNDARY-DEFINITION STRIP=0`, `CONCEPTUAL-REVIEW-METHODOLOGY
> STRIP=0`, `DRY-RUN-MIGRATION STRIP=0`, `HELP-FRAGMENT-PACK STRIP=0`,
> `HELP-FRAGMENT-TRACKER STRIP=0`, `MERGE-STRATEGY STRIP=0`,
> `OPTIONAL-FEATURES STRIP=0`.
> Conclusion: **SUPPORTED** — zero STRIP-class contamination; C4/C9 were
> complete; no route-back; allowlist correctly NOT widened.

> **Empirical-Evidence — exactly 6 `\bwill ` hits, all 6 allowlisted.**
> Command: `grep -nE '\bwill ' pack-ops/<doc>.md` for each of the 7.
> Output: DRY-RUN 156 (`It will say a sidecar`), DRY-RUN 185 (`the exact
> state the real run will start from`), MERGE 214 (`will route through
> pack-script 3-way text dispatch`), MERGE 216 (`not present in the pack
> repo will hit`), OPTIONAL 176 (`provider abstraction the agent will
> consume`), OPTIONAL 194 (`The recommendation system will not nag`).
> BOUNDARY / CONCEPTUAL-REVIEW / HELP-PACK / HELP-TRACKER = 0 will-hits.
> Conclusion: **SUPPORTED** — the live `will` set = 6, identical to the
> 6 allowlist records. KEEP set is neither under- nor over-bound.

### 1.2 Per-allowlist-entry legitimacy scrutiny (6 of 6 genuine operational KEEP)

Read the surrounding context of each. All 6 describe what a SHIPPED pack
mechanism DOES (behavioral), not a roadmap/temporal promise:

| Doc:line | Snippet | Context verdict |
|---|---|---|
| DRY-RUN:156 | `It will say a sidecar` | Harness OUTPUT behavior ("It will say a sidecar *would* be written"). Operational. KEEP. |
| DRY-RUN:185 | `the exact state the real run will start from` | Recovery-procedure behavior. Operational. KEEP. |
| MERGE:214 | `will route through pack-script 3-way text dispatch` | Migrator routing behavior. Operational. KEEP. |
| MERGE:216 | `not present in the pack repo will hit` | Three-way classification outcome. Operational. KEEP. |
| OPTIONAL:176 | `provider abstraction the agent will consume but not the agent file` | Provider-abstraction consumption behavior. Sits one line below the word "roadmap" (BD-109/110 mention) — but the `will consume` clause itself describes what the v11.0-shipped abstraction does, not a future promise. Operational. KEEP. |
| OPTIONAL:194 | `The recommendation system will not nag in this regime` | Recommendation-system behavior in the low-BD regime. Operational. KEEP. |

No borderline/contamination hit smuggled in. The one entry that warranted
scrutiny (OPTIONAL:176, adjacent to "roadmap") is legitimate: the `will`
governs the shipped abstraction's consumption, not the deferred agent file.

### 1.3 Over-binding check (snippet specificity) — PASS

> **Empirical-Evidence — each snippet matches exactly ONE line, and that
> line is a `will` line.**
> Method: for each of the 6 records, counted lines in its doc where
> `snippet in line`, and of those how many also match `\bwill `. HEAD
> `60ec0db`.
> Output: every snippet → `match_lines=[<single line>]`,
> `of_which_have_will=[<same line>]` (DRY-RUN 156/185, MERGE 214/216,
> OPTIONAL 176/194 — each a 1-element list).
> Conclusion: **SUPPORTED** — no snippet is broad enough to silently cover
> a second/different line (so a snippet can never mask future
> contamination on another line); each is content-anchored to its KEEP
> occurrence. Allowlist sized to EXACTLY the KEEP set, no broader, no
> narrower.

### 1.4 Parser correctness — PASS

`_check_44_load_allowlist()` reuses `_parse_manifest_records()` (shared with
Check 46). Independently loaded the allowlist: **6 records parsed**, mapped
to `{DRY-RUN:2, MERGE:2, OPTIONAL:2}` = 6 snippets total. Comment lines and
blank-line-separated records are handled correctly.

---

## 2. Gate has real teeth (independently verified) — PASS

### 2.1 Live STRIP-injection (the decisive test)

> **Empirical-Evidence — injecting a real STRIP hit into a live M4 doc
> hard-fails the gate.**
> Method: appended `This line was locked on 2026-05-30 during recovery.`
> to `pack-ops/OPTIONAL-FEATURES.md`; ran `python3 scripts/validate-pack.py`.
> Output: `exit=1`; Check 44 emitted `FAIL: pack-ops/OPTIONAL-FEATURES.md:237
> — M4 concision-gate forbidden pattern ['date'] OUTSIDE the allowlist:
> 'This line was locked on 2026-05-30 during recovery.'` with the full
> remediation message ("MUST NOT be widened to admit this hit").
> Cleanup: reverted from backup; `git diff --stat` = empty (no
> contamination left behind).
> Conclusion: **SUPPORTED** — the gate is NOT theater. An out-of-allowlist
> STRIP-class hit fails the whole validator (exit 1), names the offending
> file:line and pattern, and instructs strip-not-widen.

### 2.2 test-44 assertions genuinely exercise the teeth — PASS

Read `scripts/tests/test-validate-pack-check-44.sh` (T1–T5). The harness
monkeypatches `_CHECK_44_DURABLE_DOCS` to a synthetic doc in a tmp
`REPO_ROOT` and invokes the REAL `check_durable_doc_concision()` — not a
stub. The assertions are real:

- **T1** clean tree → 0 failures + "0 = clean" (happy path).
- **T2** injected date, NO allowlist → asserts `>=1` failure AND "OUTSIDE
  the allowlist" AND the offending snippet present (teeth).
- **T3** allowlisted `will` (snippet-covered) → 0 failures + "1
  allowlisted" (allowlist admits its KEEP).
- **T4** over-ceiling, no forbidden pattern → asserts 0 failures + an
  "ADVISORY:" notice (proves length is SOFT).
- **T5** SHA injected on a doc whose only allowlist record is a `will`
  snippet → asserts `>=1` failure (proves the allowlist is NOT a blanket;
  covers exactly its snippet-matched lines).

T2 + T5 are the teeth (out-of-allowlist STRIP fails); T3 the allowlisted
pass; T1 the clean pass. This is not happy-path-only. test-44 = PASS 3 /
FAIL 0.

---

## 3. No silent caps — PASS

### 3.1 Advisory derived, not round

> **Empirical-Evidence — every coded advisory ceiling = ceil(measured ×
> 1.15).**
> Method: `wc`-equivalent line count of each doc vs the coded ceiling in
> `_CHECK_44_DURABLE_DOCS`. HEAD `60ec0db`.
> Output: BOUNDARY 135→156, CONCEPTUAL-REVIEW 298→343, DRY-RUN 199→229,
> HELP-PACK 42→49, HELP-TRACKER 49→57, MERGE 484→557, OPTIONAL 235→271 —
> every coded ceiling == `ceil(lines*1.15)` (all `match=OK`).
> Conclusion: **SUPPORTED** — per-doc, content-derived, non-round. Not a
> single uniform cap.

### 3.2 Advisory-vs-hard-fail scope documented

The function docstring, the inline comment block, the allowlist header, and
IMPL-REPORT §8 all state: forbidden-pattern count (0-outside-allowlist) =
HARD teeth; per-doc length = ADVISORY (OK-notice via `ok()`, never `fail()`).
Confirmed in code: the advisory branch calls `ok(...)`, never `fail(...)`,
and does not set `any_fail`. Doc-set scope (7 docs; PACK-AGENTS/PACK-CHAT
and the mirrors explicitly OUT) is logged in IMPL-REPORT §8 — nothing reads
as "covered everything." No silent bound.

---

## 4. Enumerate ENCODING surfaces (4-surface lock-step) — PASS

| Surface | State | Evidence |
|---|---|---|
| (a) `check_durable_doc_concision` + helper + 2 consts in `validate-pack.py` | landed | diff vs HEAD = pure addition; function runs; emits Check 44 banner |
| (b) `pack-ops/.concision-allowlist.txt` | landed | 6 KEEP records; parsed 6/6 |
| (c) `scripts/tests/test-validate-pack-check-44.sh` | landed (exec, `-rwxr-xr-x`) | T1–T5; PASS 3/0 |
| (d) CI wiring line in `validate-pack.yml` | landed | step added before Check 45 step; Check 42 = 13/13 |

> **Empirical-Evidence — Check 42 (CI-wiring guard) = 13/13.**
> Command: `python3 scripts/validate-pack.py 2>&1 | grep 'Check 42'`. HEAD
> `60ec0db`.
> Output: `OK: Check 42 — 13 per-check test file(s) on disk; 13 workflow
> invocation(s) found; zero unwired tests. CI workflow wiring is complete.`
> Conclusion: **SUPPORTED** — no asymmetry; the new test is wired.

No asymmetric coverage (validator without test, or test without CI line).

---

## 5. Edit-in-place — PASS

> **Empirical-Evidence — validate-pack.py change is pure addition.**
> Command: `git diff HEAD -- scripts/validate-pack.py | grep -E '^-' |
> grep -v '^---'`. HEAD `60ec0db`.
> Output: (empty — no removed content lines).
> Interpretation: the new function + consts were inserted between the
> Check 46 tail and the `# ── Main` banner; the callsite inserted between
> `check_boundary_and_spawn_pointer_manifests()` and the summary. No
> existing check function (37/45/46/etc.) was modified.
> Conclusion: **SUPPORTED** — targeted addition, not a full-file rewrite.
> Corroborated: full validate-pack still runs all prior checks and exits 0;
> neighbors 42/45/46/32-33-34 all green.

Docstring "Checks:" inventory was intentionally NOT extended — matches the
C3/C6 precedent (Checks 45/46 added without inventory entries). Consistent
with existing convention; not a defect.

---

## 6. Working-state green + no collateral — PASS

- `python3 scripts/validate-pack.py` → `PASSED — all checks clean`,
  **exit 0**. Check 44: `7 durable doc(s) scanned; 0 forbidden pattern(s)
  outside the allowlist (0 = clean); 6 allowlisted operational
  occurrence(s) admitted`.
- test-44 → **PASS 3 / FAIL 0**.
- Neighbors: test-42 → 4/0; test-45 → 3/0; test-46 → 3/0;
  test-checks-32-33-34 → 65/0.
- `git status --short` → exactly the 4 in-scope files (validate-pack.py,
  validate-pack.yml, .concision-allowlist.txt, test-44) + the IMPL-REPORT.
  No collateral.
- Manifest: `bash test-fixtures/build.sh --all --clean` → exit 0;
  `git diff --stat test-fixtures/manifest.txt` → **empty** (allowlist +
  test + validator are not init-installed; nothing to stage). Correctly
  reported, not staged.

---

## 7. Filenames unique — PASS

> **Empirical-Evidence — no collision.**
> Command: `find . -name '.concision-allowlist.txt' -not -path './.git/*'`
> and `find . -name 'test-validate-pack-check-44.sh' -not -path './.git/*'`.
> Output: each returns exactly the single new path.
> Conclusion: **SUPPORTED** — both names unique; prose references are
> unambiguous.

---

## 8. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| CI-guard measure-then-bound | §1: independent measure → STRIP=0 all 7 docs; exactly 6 `\bwill ` hits = 6 allowlist records; per-entry legitimacy all operational; over-binding check = each snippet matches 1 line only. Allowlist sized to KEEP exactly, not widened. | COMPLIANT |
| Gate has real teeth | §2: live date injection into OPTIONAL-FEATURES.md → `exit=1` + `FAIL ... OUTSIDE the allowlist`, reverted clean (`git diff --stat` empty); T2/T5 assert out-of-allowlist STRIP fails against the real function. | COMPLIANT |
| No silent caps | §3: every coded ceiling == ceil(lines*1.15) (derived, non-round); advisory branch calls `ok()` never `fail()`; doc-set scope logged in IMPL-REPORT §8. | COMPLIANT |
| Enumerate ENCODING surfaces | §4: all 4 surfaces present + consistent; Check 42 = 13/13 (no asymmetry). | COMPLIANT |
| Edit-in-place | §5: `git diff HEAD` of validate-pack.py has zero removed content lines (pure addition); existing checks run + exit 0. | COMPLIANT |
| Empirical-Evidence for state-claims | Every §1–§7 claim carries command + verbatim output + HEAD `60ec0db` + conclusion. | COMPLIANT |
| Agents never commit / no destructive ops | Only read-only git verbs + per-check tests + ONE temporary live-doc injection, reverted from backup (`git diff --stat` empty). No state-changing git verb. | COMPLIANT |
| Rules-Applied Verification Block | This table. | COMPLIANT |
| Prison rule | `maintenance-docs/prison/` not read. | COMPLIANT |
| No prior reviews fed in | Referenced only PLAN §3 C10 + ARCHITECTURE §6; no PACK-REVIEW-* read. | COMPLIANT |

**End of PACK-REVIEW-BD-196-C10.md.**
