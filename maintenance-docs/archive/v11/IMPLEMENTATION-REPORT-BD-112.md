# IMPLEMENTATION-REPORT-BD-112

**BD:** BD-112 — Three-way diff filename mangling can collide on similar paths
**Branch:** `v11-dev`
**Base HEAD at session start:** `8432984fe280e723312ba102bbfc019105b4c5fc`
**Worktree HEAD at session end:** `8432984fe280e723312ba102bbfc019105b4c5fc` (no commits — agents never commit per pack memory)
**Date:** 2026-05-09
**Agent:** pack-coder

---

## Summary

Replaced the legacy flat-name scheme (`${rel//\//-}` + leading-dot strip) in
`scripts/lib/customization-preserve.sh` — which collapsed distinct rels onto
the same per-file artifact name and silently overwrote the first writer's
diff — with a deterministic, collision-safe helper `_cp_flat_name` that maps
each rel to `<rel-with-/-as-__>__<sha1-6hex>`. Both call sites (the
`_cp_write_diff` artifact and the structured-strategy `merge-warnings.log`
artifact) now route through the helper. Test 2.4's hard-coded expected diff
filename was updated to use the helper; a new Group 6c was added with four
collision/determinism cases including the exact pair from the BD-112
description (`.claude/agents/foo.md` vs `claude/agents/foo.md`). Validator,
the customization-preserve test, the migrator-behavior-preservation harness,
and the migrate-v10-to-v11 test all pass green.

---

## Design choice

**Mangling scheme.** `<sanitized>__<hash6>` where:

- `sanitized` = `rel` with every `/` replaced by `__` (no leading-dot
  stripping; no information discarded)
- `hash6` = first 6 hex chars of `shasum -a 1` over the **full** rel path

**Why.**

- *Deterministic.* Same rel → same name across runs and hosts (the SHA-1
  prefix and the `/`→`__` substitution are both pure functions of the input).
- *Collision-resistant.* Two distinct rels with the same basename (the
  BD-112 case, e.g. `.claude/agents/foo.md` vs `claude/agents/foo.md`)
  produce different sanitized prefixes *and* different hash suffixes — so
  even pathological inputs that share a sanitized prefix (e.g.
  `a__b/c.md` vs `a/b__c.md`) are still disambiguated by hash6.
- *Human-readable for debugging.* The sanitized prefix shows the path
  shape (path-separators visible as `__`); the short hash sits at the end
  as a stable suffix. Operators eyeballing `state/diffs/` can still locate
  artifacts by rel.
- *macOS bash 3.2 + BSD utils compatible.* `shasum -a 1` is shipped on
  macOS by default and is present on Linux via Perl's `shasum`; no
  GNU-only tools, no bash-4 features, no `&>`.
- *Minimum surface area.* The change is one new helper plus two
  call-site replacements (3 + 5 lines). No public API change. No
  classifier behavior change. No caller signatures change.

**Alternatives considered.**

- *Hash only* (`<hash6>`) — collision-resistant but loses
  human-readability; rejected.
- *Hash-prefix* (`<hash6>-<sanitized>`) — works but the visual primary
  key (the human-readable shape) becomes harder to scan; rejected.
- *Sequence index* (`<sanitized>-<seqN>`) — not stable across runs (same
  rel can get a different N if the iteration order shifts); rejected.
- *Full base32/base64 of the rel* — bulletproof but unreadable; rejected.

---

## Files modified

| Path | Change | Lines | Notes |
| --- | --- | --- | --- |
| `scripts/lib/customization-preserve.sh` | modified | +35 / −4 | added `_cp_flat_name()` helper; replaced flat-name construction at the two call sites in `_cp_write_diff` and `_cp_strategy_structured` |
| `scripts/tests/test-customization-preserve.sh` | modified | +75 / −3 | updated test 2.4's hard-coded expected diff path to use the helper; added Group 6c (BD-112) with 7 new pass-checks covering (a) the exact BD-112 collision pair at helper level, (b) determinism, (c) a second basename-collision pair, (d) end-to-end via `customization_preserve` confirming both diff files exist on disk and contain the right per-rel header |

**Files NOT touched (out-of-scope or PM-only):**

- `scripts/validate-pack.py` — owned by the parallel BD-078/BD-079 agent in
  this batch. Its working-tree modification visible in `git status` is
  that agent's work, not mine.
- `scripts/lib/three-way.sh` — audited; the classifier itself does no
  filename construction (BACKLOG entry's File/Symbol pointer to
  `_cp_write_diff` is accurate; `three-way.sh` is unaffected).
- `scripts/migrate-v10-to-v11.sh` — audited via grep; no independent
  flat-name construction. All work-dir artifact naming flows through
  `customization-preserve.sh`.
- `scripts/lib/customization-report.sh` — audited; reads the diff path
  out of column 6 of the dispositions TSV (path-agnostic). Nothing
  to update.
- BACKLOG.md, CHANGELOG.md, README.md, PACK-CHAT.md, PACK-AGENTS.md,
  CLAUDE.md, AGENTS.md, GEMINI.md — PM-only per the prompt scope and
  pack memory.

---

## How verified

Each verification command was run from the pack-repo root.

| Command | Result | Notes |
| --- | --- | --- |
| `bash scripts/tests/test-customization-preserve.sh` | **79 passed, 0 failed** | up from 72 (existing) + 7 new BD-112 assertions in Group 6c |
| `python3 scripts/validate-pack.py` | **PASSED — all checks clean** | all 28 checks green (Check 28 last reported); confirms no validator regression from the lib change |
| `bash scripts/test-migrator-behavior-preservation.sh` | **15 passed, 0 failed** | A1–A5 byte-equality across `v10-realistic-ot` + `v10-minimal` fixtures, plus N1–N5 negative-leg exit-code parity. The harness explicitly excludes `.pack-migrate-*` (state + backup dirs) from A1/A2 comparison, so the work-dir filename change is correctly outside the byte-equality contract — confirming the rename is migrator-internal only and does not break the v11 migrator's pre-refactor behavior preservation. |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | **39 passed, 0 failed** | end-to-end migration + customization-preservation + BD-042 relocation + Group 4 customization-preservation flow. Confirms the lib change does not break a real migration. |

### Specific BD-112 assertions added (Group 6c)

```
6c.1 helper distinguishes .claude/agents/foo.md vs claude/agents/foo.md
       (.claude__agents__foo.md__93c9f2 vs claude__agents__foo.md__c37c90)   PASS
6c.2 deterministic (same input → same output)                               PASS
6c.3 helper distinguishes scripts/lib vs tests/lib (same basename)          PASS
6c.4 expected diff paths differ                                             PASS
6c.4 both diff files exist on disk                                          PASS
6c.4 diff_a header names .claude/agents/foo.md                              PASS
6c.4 diff_b header names claude/agents/foo.md                               PASS
```

The 6c.4 trio is the end-to-end witness: under the legacy scheme, the
second `customization_preserve` call would have overwritten the first's
diff file (silent truthfulness violation per BD-112). Under the new
scheme, both diff files exist with the correct per-rel `# Three-way diff
for <rel>` header.

---

## Working-tree state (final)

```
$ git rev-parse HEAD
8432984fe280e723312ba102bbfc019105b4c5fc

$ git status --short
 M scripts/lib/customization-preserve.sh           ← BD-112 (this report)
 M scripts/tests/test-customization-preserve.sh    ← BD-112 (this report)
 M scripts/validate-pack.py                        ← parallel BD-078/BD-079 agent (NOT this report)
```

No new files created. No files deleted. No git state changes performed
(read-only verbs only: `git rev-parse`, `git status`, `git diff --stat`).

---

## Plan deviations

None.

---

## New POQs introduced

None. The fix is a self-contained internal naming change with no
architecture, contract, or surface-area implications.

---

## Definition-of-Done checklist

| Item | Status | Evidence |
| --- | --- | --- |
| Two distinct source paths with the same basename produce distinct work-directory filenames | **PASS** | Group 6c.1 + 6c.3 + 6c.4; all 4 helper-level + end-to-end checks green |
| Existing callers (`migrate-v10-to-v11.sh`, `customization-preserve.sh`) continue to work | **PASS** | `test-migrate-v10-to-v11.sh` 39/39, `test-migrator-behavior-preservation.sh` 15/15 |
| `python3 scripts/validate-pack.py` PASSES — all 28 checks clean | **PASS** | Validator output ends with `PASSED — all checks clean` |
| `bash scripts/tests/test-customization-preserve.sh` passes | **PASS** | 79/79 |
| `bash scripts/test-migrator-behavior-preservation.sh` passes | **PASS** | 15/15 |
| Add a small test case that exercises the collision | **PASS** | Group 6c (7 new checks, including the exact BD-112 pair) |
| BD-112 status NOT flipped | **PASS** | `BACKLOG.md` not modified; Pack Chat owns the flip |
| No state-changing git verbs run | **PASS** | only `git rev-parse`, `git status`, `git diff --stat` |
| Trinity files not touched | **PASS** | no edits to CLAUDE.md / AGENTS.md / GEMINI.md (root or template) |
| Out-of-scope file `scripts/validate-pack.py` not touched by this agent | **PASS** | parallel agent's modification is visible in `git status` but I performed no edits to it (no `Edit`/`Write` tool calls against that path) |

---

## Files-changed inventory

| Path | Type | Owner |
| --- | --- | --- |
| `scripts/lib/customization-preserve.sh` | modified | BD-112 (this agent) |
| `scripts/tests/test-customization-preserve.sh` | modified | BD-112 (this agent) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-112.md` | new | BD-112 (this agent — this report) |
| `scripts/validate-pack.py` | modified | parallel BD-078/BD-079 agent (NOT this agent) |

---

## Deferred items

None.
