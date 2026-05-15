# PACK-REVIEW-BD-112 — three-way diff filename mangling fix (Batch 21c retroactive)

**Reviewer scope:** BD-112 (originally shipped in Batch 11 combined commit `91a9fc5`)
**Reviewer:** pack-reviewer (Batch 21c retroactive per-BD; trial run; 2026-05-15)
**Date:** 2026-05-15

## Summary

**Verdict: clean-with-nits.** BD-112's primary fix is correct, well-scoped,
and well-tested. The `_cp_flat_name()` helper is deterministic,
collision-resistant in both general and pathological cases, and
human-readable for operator debugging. Both call sites
(`_cp_write_diff` and `_cp_strategy_structured`) are routed through the
helper. Audit confirmed no other consumer of the diff/log filenames
exists outside `customization-preserve.sh` itself, and no drift between
the original `91a9fc5` version and HEAD on `customization-preserve.sh`.
Tests landed for the exact BD-112 collision pair plus determinism plus
end-to-end via `customization_preserve`.

**Counts:** BLOCKER 0, MUST 0, SHOULD 0, NIT 3.

The three NITs are: (N1) a `CHANGELOG.md` entry that names a now-deleted
file (`migrate-v9-to-v10.sh`) as a fix surface without acknowledging the
BD-121 deletion the BACKLOG entry properly notes; (N2) the helper does
not protect against `set -u` callers passing zero arguments — reaches
through `local rel="$1"` and would error rather than emit a diagnostic
(low priority because all in-tree call sites pass the well-formed
`"$rel"` arg); (N3) `_cp_strategy_gemini_env` (which also writes a
three-way diff via `_cp_write_diff` on line 503) is not exercised by
the new Group 6c collision tests, leaving one of the three diff-writing
strategies covered only indirectly.

**Retroactive-review value-add (trial framing).** This pass surfaced
three NITs that a per-BD review at Batch 11 ship-time would have caught
inexpensively. None rise to MUST or SHOULD; the implementation is sound
and CI green has remained representative. The trial validates that
retroactive per-BD reviews can find legitimate (if non-blocking) issues
on already-shipped code, but also that the cost is low because the
reviewer rebuilds context from spec + diff + current state in roughly
the same shape an at-ship review would have. See Coverage Notes for
methodology friction observed.

## Findings

### Finding F1
- **Severity:** NIT
- **Location:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CHANGELOG.md:121-122`
- **Title:** CHANGELOG entry names a deleted file as a fix surface without flagging deletion
- **Description:** The CHANGELOG line for BD-112 reads "Three-way diff
  filename mangling collision fix (affects both `customization-preserve.sh`
  and `migrate-v9-to-v10.sh`)." `scripts/migrate-v9-to-v10.sh` no longer
  exists at HEAD — it was deleted by BD-121, as the BD-112 BACKLOG
  resolution note (`BACKLOG.md:1013`) explicitly acknowledges ("the
  BACKLOG entry's secondary surface (`scripts/migrate-v9-to-v10.sh`)
  was deleted by BD-121 and required no fix"). A reader auditing
  CHANGELOG-only would conclude two files were modified, then `grep`
  for the second file and find nothing — minor truthfulness drift.
- **Suggested fix:** Edit CHANGELOG.md:121-122 to read e.g. "Three-way
  diff filename mangling collision fix in `customization-preserve.sh`
  (the originally-paired `migrate-v9-to-v10.sh` surface was retired by
  BD-121 and required no fix)." — leave to author judgment whether to
  defer until the next CHANGELOG sweep.
- **Source:** Pack memory truthfulness norm (BACKLOG/CHANGELOG must
  faithfully reflect what shipped). Cross-checked against
  `scripts/migrate-v9-to-v10.sh` deletion (file confirmed absent at HEAD)
  and BD-121 BACKLOG entry at `BACKLOG.md:1274-1336`.

### Finding F2
- **Severity:** NIT
- **Location:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/customization-preserve.sh:100-106`
- **Title:** `_cp_flat_name` has no defensive arg-count guard for set-u callers
- **Description:** The helper begins with `local rel="$1"`. Under
  `set -uo pipefail` (which the migrator at `scripts/migrate-v10-to-v11.sh:67`
  runs with), invoking `_cp_flat_name` with no arguments aborts the
  caller with `unbound variable` rather than emitting a clear diagnostic
  about the missing arg. The peer helper `_cp_require_three_way` (lines
  69-74) demonstrates the in-file convention of returning a structured
  error to stderr. Current in-tree call sites (`_cp_write_diff` line 216,
  `_cp_strategy_structured` line 349) always pass `"$rel"` from a
  validated path through `customization_preserve()`, so this is a
  defense-in-depth concern rather than a live bug.
- **Suggested fix:** Optional. Add `[[ -n "${1:-}" ]] || { printf
  'error: _cp_flat_name: REL required\n' >&2; return 1; }` as the first
  line. Skip if author judges the in-file convention is "private helpers
  trust their callers" — consistency-only matter.
- **Source:** Convention established by peer helper `_cp_require_three_way`
  in the same file (lines 69-74).

### Finding F3
- **Severity:** NIT
- **Location:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-customization-preserve.sh:419-491` (Group 6c)
- **Title:** Group 6c end-to-end coverage skips the gemini-env strategy
- **Description:** `_cp_write_diff` has three callers in
  `customization-preserve.sh`: `_cp_strategy_text` (line 277),
  `_cp_strategy_structured` (line 357), and `_cp_strategy_gemini_env`
  (line 503). Group 6c.4's end-to-end witness drives only the text
  strategy (via the `generic` class default for `.claude/agents/foo.md`
  rels — see `customization_preserve` dispatch lines 530-557). The
  gemini-env strategy also writes both a diff (via `_cp_write_diff`,
  inheriting the BD-112 fix automatically) and a sidecar; under a
  hypothetical user shape where two `.gemini/.env`-shaped rels collide
  (e.g. `.gemini/.env` and `gemini/.env`), the helper would still
  disambiguate correctly because it routes through the same helper —
  but the test set does not prove this. The structured strategy is also
  not exercised end-to-end in 6c (only the helper-level + text-strategy
  paths). Risk is low because all three strategies share the
  `_cp_write_diff` code path; a single helper-level test covers the
  collision math, and the text-strategy test covers
  helper-call-from-strategy. But explicit end-to-end via the structured
  + gemini-env paths would close the matrix.
- **Suggested fix:** Optional. Add 6c.5 + 6c.6 end-to-end witnesses
  driving `_cp_strategy_structured` (with a JSON or TOML fmt) and
  `_cp_strategy_gemini_env` for a colliding rel pair, asserting both
  diff files exist. Or leave as-is and document in the test header that
  helper-level coverage suffices because all three strategies share the
  `_cp_write_diff` helper. Author judgment.
- **Source:** Test-coverage matrix completeness. No spec rule violated.

## Coverage notes

**What I reviewed (in-scope, BD-112 only).**

- `git show 91a9fc5 -- scripts/lib/customization-preserve.sh` — full
  BD-112 diff (helper add + two call-site replacements).
- `git show 91a9fc5 -- scripts/tests/test-customization-preserve.sh`
  (BD-112 portion: Group 6c addition, test 2.4 update).
- `scripts/lib/customization-preserve.sh` (HEAD) — verified zero drift
  on the BD-112 helper + call sites since `91a9fc5` via
  `git log --oneline -- scripts/lib/customization-preserve.sh`
  (touched by `91a9fc5` and `d98ce52`; reading HEAD confirms `d98ce52`
  did not touch the BD-112 region).
- `scripts/lib/three-way.sh` — confirmed BD-112 did NOT touch this file
  (the prompt mentioned `three-way.sh` but the BACKLOG entry, commit
  message, and IMPLEMENTATION-REPORT-BD-112.md all consistently name
  `customization-preserve.sh` as the surface; `three-way.sh` is the
  classifier and does no filename construction).
- `scripts/lib/customization-report.sh` — verified the consumer reads
  `$3` (rel_path) and `$5` (sidecar) from the dispositions TSV; the
  diff path in column 6 is internal-only and not surfaced to users in
  the rendered report. The flat-name change is correctly scoped.
- BD-112 BACKLOG entry (`BACKLOG.md:993-1013`) — Status: Resolved,
  resolution note matches the implementation faithfully (including the
  BD-121 secondary-surface acknowledgment).
- `IMPLEMENTATION-REPORT-BD-112.md` (in
  `maintenance-docs/archive/v11/`) — implementation report is thorough,
  honest about scope, lists alternatives considered.
- `scripts/validate-pack.py` Check 25 (BD-089 customization-detection
  regression guard, lines 1745-1862) — exercises the BD-088 library
  end-to-end but does not specifically assert on flat-name uniqueness
  (BD-112 has its own dedicated coverage in test Group 6c, run in CI
  per BD-083).
- `scripts/migrate-v10-to-v11.sh` — grep for any independent flat-name
  construction returned only the `sed -E 's/[[:space:]]+$//'` line
  (unrelated). All work-dir artifact naming flows through
  `customization-preserve.sh` as the implementation report claims.
- BD-121 deletion confirmed: `scripts/migrate-v9-to-v10.sh` is absent
  at HEAD.
- `printf '%s'` use in the helper — verified safe against rels with
  `%` characters (no format-string risk).
- shasum portability claim — verified `/usr/bin/shasum` exists on the
  host and produces the exact `93c9f2` / `c37c90` hash6 values cited
  in IMPLEMENTATION-REPORT-BD-112.md for the BD-112 BACKLOG pair.
- Pathological collision case from the implementation report
  (`a__b/c.md` vs `a/b__c.md`) — verified the sanitized prefixes
  coincide as `a__b__c.md` but hash6 differs (`0e7eb0` vs `17a88a`).
- Trinity files (`project-template/CLAUDE.md`, `AGENTS.md`,
  `GEMINI.md`) — grep confirmed no references to diff filename
  construction or three-way diff paths; Trinity rule N/A for this BD.
- README.md repository layout — `customization-preserve.sh` and
  `three-way.sh` listed in scripts/lib/ section; no BD-112-specific
  layout change required.

**Areas intentionally not exercised.**

- I did NOT run any test scripts (`bash scripts/tests/...`) — the
  permission was denied by the harness, and re-running tests was not
  load-bearing for the review (the test code itself is auditable as
  source, and the IMPLEMENTATION-REPORT-BD-112.md cites 79/79 + 15/15
  + 39/39 + validator-clean numbers). Findings are from static read.
- I did NOT read any prior `PACK-REVIEW-*.md` (per pack memory rule).
- BD-078 / BD-079 changes from the same `91a9fc5` commit were
  explicitly out of scope and not opened.

**Retroactive-review value-add (trial commentary).**

This review surfaced three legitimate NITs on already-shipped code, all
of which a per-BD review at Batch 11 ship-time would also have caught
without ambiguity (CHANGELOG truthfulness, defensive-coding
consistency, test-matrix completeness). None became live defects in
the intervening time. The retroactive cost was modest:
~15 read calls + 6 bash inspections, no test runs, no external context
beyond the commit + spec + current state. The signal-to-noise of the
trial is positive — the review found real items per-BD reviews would
catch — but also confirms that a single combined-commit batch review
(which Batch 11 effectively skipped) is unlikely to catch these without
explicit per-BD focus, because the BD-078/079 validator changes
dominate cognitive surface area in the combined-commit diff.

**Methodology friction observed.**

1. The review prompt named `scripts/lib/three-way.sh` as the file in
   scope, but the actual BD-112 surface is `scripts/lib/customization-
   preserve.sh`. The BACKLOG entry, commit message, and implementation
   report all agree on the correct file; the prompt's reference is the
   only outlier. Future retroactive-review prompts should source the
   "files in scope" list from the BACKLOG `File/Symbol:` field plus
   the commit `--stat` output, not from prose recall.
2. The prompt referenced `ARCHITECTURE-V1.md` and `ARCHITECTURE-V3.md`
   as inputs; only `ARCHITECTURE.md`, various `ARCHITECTURE-V3.x-DELTA.md`
   files, and several `ARCHITECTURE-PER-ENTRY-*.md` files exist with
   slightly different names. None of them spec'd the diff-filename
   construction (which was an implementation detail, not an
   architectural decision), so this had no review impact — but a future
   prompt that points to non-existent files for a BD whose spec lives
   elsewhere could cause a reviewer to spend time hunting. Prompts
   should glob/verify the architecture-doc paths exist before listing
   them.
3. The denied test-execution permission is appropriate for a strictly
   read-only review and added no friction; the implementation report's
   passing-test counts are sufficient.
4. One observation for the trial calibration: this review took roughly
   the same shape as a fresh per-BD review would have (read spec, read
   diff, read current state, audit consumers, check edge cases) — the
   "retroactive" framing did not materially alter effort. The main
   difference is no opportunity to surface findings in time to influence
   Batch 11 implementation; nits land as tech debt on `v11-dev` instead.
