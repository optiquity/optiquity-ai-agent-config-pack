# PACK-REVIEW-BD-079-RETRO — Recommendation-state schema validator (Check 30)

**Reviewer:** `pack-reviewer` (retro per-BD review, Batch 21c)
**Date:** 2026-05-15
**Original commit under review:** `91a9fc5` ("fix: v11 — Batch 11 (BD-112 + BD-078 + BD-079: three-way diff fix + 2 validator extensions)")
**BD scope isolated:** BD-079 only (Check 30, `check_recommendation_state_schema`).
**Out of scope:** BD-078 (Check 29, tracker-config schema) and BD-112 (three-way diff filename mangling), even though they shipped in the same commit.

---

## 1. Scope declaration

**BD-079 binding statement (per BACKLOG.md:326–336):**
"If `.pack-tracker/recommendation-state.json` exists, validate against the V3 §28.1.4 v1 schema. Soft-fail if missing (lazy-create is by design). Catches state-file corruption before it causes runtime defaults."

**In-scope files (BD-079 portion of `91a9fc5`):**
- `scripts/validate-pack.py` lines 86–101 (top-of-file docstring entry for Check 30)
- `scripts/validate-pack.py` lines 2286–2378 (`_REC_STATE_SCHEMA`, `_REC_STATE_SCHEMA_VERSION`, `_REC_STATE_SURFACES`, `check_recommendation_state_schema()`)
- `scripts/validate-pack.py` line 2722 (`main()` wiring)
- `scripts/validate-pack.py` line 116 (`import json`)
- `scripts/tests/recommendation-state-schema-test.sh` (252 lines, NEW)
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md` (BD-079 section only — file is now archived per BD-150 Pattern B sweep)

**Out-of-scope artifacts that touch Check 30 numerically (read-only neighbors):**
- BD-078 Check 29 (`check_tracker_config`) at `scripts/validate-pack.py:2002–2284`
- BD-146 Check 31 (`check_skill_cell_consistency`) inserted later

**Touch-point matrix vs. other concepts:**

| Touch point | Class | Other concepts that read/write |
|---|---|---|
| `scripts/validate-pack.py` (file) | SHARED-RW | every BD that adds a numbered Check (BD-126, BD-078, BD-079, BD-146, …) |
| `_REC_STATE_SCHEMA` constant | OWNED | BD-079 only |
| `.pack-tracker/recommendation-state.json` (target file) | SHARED-RO from validator | OWNED by `scripts/lib/recommendation.sh` (BD-072 + downstream) — validator reads only; never writes |
| Schema contract per V3 §28.1.4 | CONTRACT | `recommendation_state_default()` (`scripts/lib/recommendation.sh:244`) is the runtime source of truth; validator is the static guard |
| `.github/workflows/validate-pack.yml` (CI) | SHARED-RW | every BD that adds a `*-test.sh` (race window — see F-1) |

---

## 2. Methodology notes

Surveyed:
- BACKLOG.md BD-079 entry (line 326) for binding statement + acceptance criteria
- `git show 91a9fc5 -- scripts/validate-pack.py` for the BD-079 diff portion
- Archived implementation report `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md` BD-079 section (lines 139–227)
- V3 §28.1.4 schema definition at `maintenance-docs/v11-research/ARCHITECTURE-V3.md:668–762`
- Source-of-truth `recommendation_state_default()` at `scripts/lib/recommendation.sh:244–248`
- All `recommendation_state_save` call sites for file-write timing analysis
- `.github/workflows/validate-pack.yml` to enumerate which `scripts/tests/*-test.sh` files are wired to CI
- `git diff 91a9fc5 HEAD -- scripts/validate-pack.py scripts/tests/recommendation-state-schema-test.sh` to confirm no post-ship drift in the BD-079 surface
- Live execution: `bash scripts/tests/recommendation-state-schema-test.sh` → 19/19 PASS at HEAD (test harness still green).
- `EXECUTION-PLAN-V11.0.md` Batch 11 row at line 295 to confirm scope.

Empirical anchors used: BACKLOG entry text, V3 §28.1.4 schema doc, `recommendation_state_default()` jq builder, validate-pack.yml step list, the live test run.

---

## 3. Findings

### F-1 [MUST] — `scripts/tests/recommendation-state-schema-test.sh` is not wired into CI

- **Severity:** MUST
- **Dimension:** (c) touch points + cross-concept impact
- **Touch-point class:** SHARED-RW (`.github/workflows/validate-pack.yml`)
- **Evidence:**
  - File present on disk: `scripts/tests/recommendation-state-schema-test.sh:1` (252 lines, executable, 19/19 PASS today).
  - File ABSENT from workflow: `grep -n recommendation-state-schema /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/workflows/validate-pack.yml` returns nothing (verified 2026-05-15 against HEAD).
  - The workflow's tests job lists every `*-test.sh` explicitly (22 entries, see `awk '/scripts\/tests\//' .github/workflows/validate-pack.yml | sort -u`). It does NOT use a `for f in scripts/tests/*-test.sh` discovery loop, despite the file-header comment at lines 6–8 claiming "runs every scripts/tests/*-test.sh independently". The new BD-079 test was not appended.
  - This is the exact failure mode the conceptual review methodology calls out under "Race-condition detection heuristic" — bullet 3: "CI workflow + new test scripts: test scripts exist on disk but workflow doesn't invoke them (Batch 17 BD-108 F1) — CI green doesn't mean tests ran."
- **Description:** The BD-079 fixture suite that proves Check 30 catches all 8 documented failure modes (parse error, top-level non-object, missing field, wrong type, schema_version drift, bad surface, negative `user_re_enable_count`, bool-as-int) NEVER executes on a push. The validator's `python3 scripts/validate-pack.py` runs in CI and trivially passes Check 30 because `.pack-tracker/recommendation-state.json` is gitignored and absent on the runner — so the soft-pass branch fires every time. The branch that actually exercises the schema logic is reachable only by the omitted fixture suite. Net effect: a regression that breaks Check 30 (e.g., a future PR mutates `_REC_STATE_SCHEMA` and forgets to update the test) ships green.
- **Suggested fix:** Append to `.github/workflows/validate-pack.yml` tests job, in alphabetical neighborhood with `recommendation-test.sh`:
  ```yaml
        - name: recommendation-state schema test
          run: bash scripts/tests/recommendation-state-schema-test.sh
  ```
  Same applies (separate review) to BD-078's `tracker-config-schema-test.sh` — that's out of scope here but should be flagged with the BD-078 retro reviewer.
- **Cross-concept impact:** None functional; CI-only. Same systemic issue affects BD-078's `tracker-config-schema-test.sh` (also missing from CI per the same `grep` — explicitly out-of-scope for this BD-079 review but flagged in adjacent finding for the BD-078 retro reviewer).
- **Rule violated:** `CLAUDE.md` §"CI validation" — "If it fails, fix before proceeding. Read the Actions log — errors name the exact file and problem. Never skip or disable the workflow." This finding does not violate the literal rule (the workflow runs; it just doesn't run the new test) but it violates the spirit and the empirical race pattern documented by Batch 17 BD-108 F1.

---

### F-2 [SHOULD] — `last_recommendation_signals` inner shape is unvalidated

- **Severity:** SHOULD
- **Dimension:** (a) completeness
- **Touch-point class:** OWNED
- **Evidence:**
  - V3 §28.1.4 schema example at `maintenance-docs/v11-research/ARCHITECTURE-V3.md:687–690` shows the contract:
    ```json
    "last_recommendation_signals": {
      "bd_count_active": 0,
      "backlog_kb": 0
    }
    ```
  - Validator at `scripts/validate-pack.py:2297` only asserts `(dict,)` for this field — any dict shape passes (including `{"foo": "bar"}` or `{}`).
  - `recommendation_state_default()` at `scripts/lib/recommendation.sh:247` emits `last_recommendation_signals: {}` (empty dict) at fresh-create — that is the documented canonical default, so an empty dict is correct.
  - `recommendation_record_shown()` at `scripts/lib/recommendation.sh:494–496` writes the signals JSON unmodified into this slot (`.last_recommendation_signals = $s`). The `$s` is whatever signals were computed in `recommendation_compute_signals_pack()` (line 132–143) or `recommendation_compute_signals_client()` (line 156–174). Per-surface inner key sets are: pack = `{bd_count_active, bd_count_total, backlog_kb, backlog_growth_30d}`; client = `{td_count_active, td_count_total, backlog_kb, phase_count, implementation_plan_kb, td_tbd_comment_count, typed_deferral_count}`.
  - Downstream consumer at `scripts/lib/recommendation.sh:360` reads `.last_recommendation_signals[$k]` with `// 0` default, so missing inner keys silently default to 0 at runtime.
- **Description:** A state file with `last_recommendation_signals: {"unrelated_key": "garbage"}` would PASS the validator (satisfies `(dict,)` constraint) and silently degrade the §28.1.5 "should we recommend now?" test by feeding 0 for every signal-comparison lookup. The same silent-default footgun the validator was created to catch (per its own docstring at line 2313–2315) is left uncaught for the inner-signals shape.
- **Suggested fix:** Either (a) accept this as scoped out (the V3 example is descriptive not prescriptive, and the runtime tolerates absent inner keys via `// 0`) and document the rationale in the validator function docstring; OR (b) add a soft check that, when `last_recommendation_signals` is non-empty, every key is one of the union of pack-surface and client-surface signal names, and every value is `int` (the runtime treats them as numeric). Option (b) is the stricter read; option (a) is the minimal-surface read aligned with how §28.1.4 ships the example. Recommend (a) for v11 (in-scope discipline) and queue (b) as a future BD if signal-corruption becomes a real failure mode.
- **Cross-concept impact:** Touches `scripts/lib/recommendation.sh` indirectly (the inner-key contract lives there). Any tightening would need cross-reference to `recommendation_compute_signals_pack` / `_client`.
- **Rule violated:** Conceptual review methodology dimension (a) — "was the concept fully implemented across its in-scope BDs?". The schema check is partially implemented; the inner shape is not gated.

---

### F-3 [NIT] — Docstring inaccurately states when the file is first written

- **Severity:** NIT
- **Dimension:** (e) design best practice (#1 — single source of truth: docstring should match runtime behavior)
- **Touch-point class:** OWNED
- **Evidence:**
  - `scripts/validate-pack.py:97–99` Check 30 docstring claims: "lazy-create is by design — fresh installs never write the file until first persistent-refusal toggle."
  - Actual write paths in `scripts/lib/recommendation.sh`: `recommendation_state_save` is called at line 272 + 279 (corruption-rebuild), 497 (`recommendation_record_shown`), and 526 (`recommendation_set_persistent_refusal`). The first user-visible write happens whichever of `recommendation_record_shown` (recommendation prompt fires) OR `recommendation_set_persistent_refusal` (user picks "don't ask again") happens first — typically the former, since the user sees the prompt before they can refuse.
- **Description:** The docstring is technically incorrect; it picks one of two write triggers and omits the more common one. Operator reading the validator output to debug a state-file presence question would be misled into looking only at refusal-related code paths.
- **Suggested fix:** Edit `scripts/validate-pack.py:97–99` to read: "lazy-create is by design — fresh installs never write the file until first recommendation surface or persistent-refusal toggle, whichever comes first."
- **Cross-concept impact:** None.
- **Rule violated:** Conceptual review methodology dimension (e), principle 1 — "single source of truth for content / rules / config." Docstring drifted from `scripts/lib/recommendation.sh` runtime behavior.

---

### F-4 [NIT] — BACKLOG entry references stale path for archived implementation report

- **Severity:** NIT
- **Dimension:** (c) touch points + cross-concept impact
- **Touch-point class:** SHARED-RW (`BACKLOG.md` is PM-owned; flagging only)
- **Evidence:**
  - `BACKLOG.md:336` Resolved line says: `see maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-078-BD-079.md`.
  - The file no longer lives there — it was moved to `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md` in commit `c30fa36` ("BD-150 … Pattern B archive sweep").
  - This is a systematic Pattern B side-effect that affects many BDs (BD-095, BD-096, BD-104, BD-112, BD-114, BD-115, BD-119*, BD-121, BD-122 implementation reports were also moved). Flagging here only because BD-079 is the in-scope BD.
- **Description:** The BACKLOG cross-reference dangles (well, points to a deleted location). A reader following the link gets a 404 in their editor / file browser. Same pattern across all archived reports.
- **Suggested fix:** Either (a) bulk-rewrite all stale `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-*.md` references in BACKLOG.md to `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-*.md` (one-shot sed); OR (b) add a one-liner note at the top of BACKLOG.md ("Implementation reports for closed BDs may have been swept to `maintenance-docs/archive/v11/` per Pattern B; check both locations.") Option (a) is the cleaner fix; it is PM-owned per `commit-discipline.md` §4 (BACKLOG is off-limits to agents) and should be raised with Pack Chat. Recommend (a).
- **Cross-concept impact:** Affects every previously-resolved BD whose implementation report was swept; the fix is bulk-applicable, not BD-079-specific.
- **Rule violated:** None directly; this is link-hygiene / `MEMORY.md` "filename uniqueness" hygiene by extension. NIT consistent with the methodology's principle of empirically-anchored evidence.

---

## 4. Coverage notes

In scope but explicitly NOT pursued in depth:
- **Unicode / very-large-file behavior on the JSON loader.** `json.load(f)` with default UTF-8 will raise on bad encoding; the broad `except Exception` at line 2328 captures that with a useful message. Sufficient for an operator-facing static check; not pursued further.
- **Concurrent reader/writer race between Check 30 and a live `recommendation_state_save` running in another shell.** `mv $tmp $path` (atomic rename in `recommendation_state_save:299`) means the validator either reads the old or the new file, never a torn write. Pursued only to confirm; no finding.
- **Symlink / directory-at-path edge case.** `state_file.is_file()` correctly false for both symlinks-to-dir and bare directories; soft-pass branch fires safely. Verified by reading `pathlib.Path.is_file` semantics; not pursued further.
- **Schema migration to v2 (future).** Out of scope; v11 ships v1 only. If/when v2 lands, Check 30 will need a new comparison path.
- **`tracker.toml.pack-example`-style sibling artifact** — those are BD-078 territory; not surveyed.

Out-of-scope deliberately (per BD-079 scope anchor in the prompt):
- BD-078's Check 29 (`check_tracker_config`) and `tracker-config-schema-test.sh`. Note that F-1's CI-wiring problem applies symmetrically to BD-078; flagging here for the BD-078 retro reviewer.
- BD-112's three-way diff filename fix and `customization-preserve.sh` changes.

---

## 5. Re-architect summary

No `ARCH` findings. All four findings are correctness/quality/hygiene at the BD-079 implementation level; none requires re-touching the V3 §28.1.4 contract or cross-concept ordering. F-1 is a CI-wiring miss (mechanical fix); F-2 is a scope decision (recommend "stay with current minimal-surface"); F-3 is a docstring fix; F-4 is a BACKLOG link-hygiene sweep that's PM-owned.

If only one finding is fix-shipped, prioritize **F-1**: an unwired CI test is a structural defense gap that allows future regressions to ship silently. F-3 is a 1-line edit and would naturally accompany F-1. F-2 is a deliberate-scope decision (option (a) is the principled choice). F-4 is bulk PM hygiene best done in a dedicated sweep.

---

## 6. What the implementation got right (acknowledgments)

- Validator function correctly soft-passes the absent-file case per V3 §28.1.4 lazy-create design (no false positive for fresh checkouts).
- Bool-vs-int rejection for `user_re_enable_count` is a thoughtful addition above and beyond V3 §28.1.4 — captures the Python `isinstance(True, int) == True` footgun. Test 10 in the fixture suite explicitly exercises this and passes.
- Failure messages name (a) relative file path, (b) field name, (c) expected vs. actual — meets the methodology's "names exactly what diverges" requirement.
- The `_REC_STATE_SCHEMA` tuple-of-tuples style is a straightforward source-of-truth lookup matching `recommendation_state_default()`; easy to audit field-by-field.
- The fixture-test harness pattern (`importlib` + fixture `REPO_ROOT` override + `mod.failures` reset between scenarios) is reusable and isolates Check 30 from the rest of the validator. Same harness re-used by BD-078, which is good cohesion.
- 19/19 fixture assertions PASS at HEAD (verified live in this review run).
- The check is correctly wired in `main()` after Check 29 in numerical order at `scripts/validate-pack.py:2722`; the top-of-file docstring lists Check 30 (lines 93–100); `import json` is present (line 116).
- No PM-only files were touched in the BD-079 implementation; trinity files untouched; no state-changing git verbs were run by the original agent (all per the implementation report's DoD checklist).
- Plan deviation note in the report (the bool-rejection stricter-than-spec read) is correctly surfaced at IMPLEMENTATION-REPORT-BD-078-BD-079 §279–292 — a model of explicit-deviation discipline.

---

## 7. Methodology friction notes

- **The methodology's "Race-condition detection heuristic" caught F-1 prospectively.** The doc's bullet about "CI workflow + new test scripts" matched this exact pattern, indicating the checklist is doing real work. Recommend continuing that bullet in the next methodology revision, possibly with a one-line "always grep `validate-pack.yml` for the new `*-test.sh` filename when reviewing any BD that adds a test script" worked example.
- **Pattern B sweep dangling-link impact (F-4) is structural.** This is the second time in retro reviews the BACKLOG-references-archived-report pattern surfaces. Consider promoting to a methodology rule: "When a Pattern B sweep lands, the same commit must rewrite cross-references in BACKLOG.md / CHANGELOG.md / README.md to point to the archive path." This is not a BD-079 problem; it's a BD-150 procedure problem.
- **No friction with the touch-point classification.** All four findings classified cleanly without ambiguity. The CONTRACT class for the V3 §28.1.4 schema field set was the right discriminator — the validator is a static guard around a contract owned by `scripts/lib/recommendation.sh`.
- **One-finding-per-dimension distribution:** F-1 (c), F-2 (a), F-3 (e), F-4 (c) — methodology dimensions are doing real signal-spreading work; no dimension blank.

---

## 8. Disposition recommendation

| Finding | Severity | Suggested disposition |
|---|---|---|
| F-1 | MUST | Fix in-session (one-line workflow append). Critical for CI integrity. |
| F-2 | SHOULD | Accept as-is with rationale comment in validator docstring (option (a)). |
| F-3 | NIT | Fix in-session alongside F-1 (one-line docstring edit). |
| F-4 | NIT | Defer to a dedicated PM-owned BACKLOG-sweep batch (PM-only, agent cannot fix). |

End of review. BD-079 is fundamentally sound; the most consequential gap is F-1 (CI not running the test), which is the canonical race the methodology already calls out and a one-line workflow patch resolves it.
