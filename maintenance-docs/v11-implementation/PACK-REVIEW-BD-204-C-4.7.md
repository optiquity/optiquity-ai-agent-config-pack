# PACK-REVIEW — BD-204 C-4.7 (schema-doc reconciliation; §3.LF.6) — Review pass 1

**Reviewer:** pack-reviewer
**Date:** 2026-06-10
**HEAD at review:** `40eaa85c31d0e742338274f45fe85f9c2d6aebd0` (branch `v11-dev`)
**Change under review:** working-tree diff to `backlog/_rules.md` (the only modified tracked file)
**Verdict: CLEAN — 0 findings (0 BLOCKER / 0 MUST / 0 SHOULD / 0 NIT).**

---

## 1. Success-criterion verification

### SC-1 — Accuracy vs as-built migrator code: PASS

The new paragraph's three code claims are all true of the as-built migrators:

- **"carries every top-level entry field VERBATIM" / no field allowlist gating the carry.**
  `scripts/lib/tracker-migrate-forward.sh:428-455` (raw-span capture, decoupled from the
  projection) + `:504-527` (every entry-body line after the header — including interior H2
  content and unknown field lines — is appended to `raw_lines` unconditionally, BEFORE the
  `current is None` guard). The field `mapping` dict at `:538-549` gates only the label/link/H2
  PROJECTION (`key is None` → skipped from projection at `:551-553`), never the raw capture.
  The carried truth is the whole span; no allowlist gates it.
- **"preserved byte-for-byte as the `pack-entry-body-gz64` blob."** Marker confirmed verbatim:
  `tracker-migrate-forward.sh:942` (`printf '<!-- pack-entry-body-gz64: %s -->\n' "$blob"`),
  `:1060` (batch composer), and `tracker-migrate-reverse.sh:669` (decode regex). Forward
  comment `:441-442`: "raw_body equals the original file's lines 2..EOF exactly". Reverse
  emits the decoded span verbatim — `tracker-migrate-reverse.sh:1035-1040` ("No re-projection,
  no injected Blockers/Unblocks/Resolved lines, no field reordering"; `body = e.get("raw_body", "")`).
- **Scope of "byte-for-byte" is correct as worded.** `raw_body` is lines 2..EOF (the line-1
  back-pointer is stripped/re-prepended canonically — forward `:438-439`, reverse `:1018-1019`).
  The `_rules.md` paragraph says "the entry body is preserved byte-for-byte", and the same
  section defines the entry's content span as beginning at `**BD-NNN — <Title>**`
  (`backlog/_rules.md:46-47`) — so "entry body" excludes the back-pointer by the file's own
  definition. Accurate.

### SC-2 — Accuracy vs METHODOLOGY.md Part 7: PASS (read-verify only; not edited)

`supporting-docs/METHODOLOGY.md:1199-1216` ("BACKLOG item format") enumerates exactly:
`Type:` / `Status:` / `Blockers:` / `Unblocks:` / `File/Symbol:` / `Description:` /
`Context:` / `Resolution:` — the same eight fields, same order, the new paragraph attributes
to Part 7 (`backlog/_rules.md:56-58`). `Position:` / `Target:` are indeed absent from Part 7,
so classing them as EXTENSION fields is correct. `git diff --name-only` confirms
METHODOLOGY.md is byte-untouched.

### SC-3 — No dropped content / no contradictions: PASS

- Read `backlog/_rules.md` in full (95 lines, post-change). Heading map vs
  `git show HEAD:backlog/_rules.md` is identical (8 headings, text-identical; only line
  offsets shift +11 below the insertion — diff of `grep -n '^#\|^##'` on both versions shows
  line-number-only deltas at `## Lifecycle states admitted` / `## Supporting files` /
  `## Write authority`). `git diff --stat` = 1 file, 14 insertions, 3 deletions, single hunk
  `@@ -45,9 +45,20 @@`. Surgical in-place edit; no section dropped.
- No other passage implies a field allowlist. The only other field-format references are the
  ID-extraction rule (`:36-41`, header grammar — untouched, consistent) and the Lifecycle
  section's `Resolved:` line requirement (`:69`, `:73-75`) — consistent: the field-faithful
  paragraph admits any field, and the migrator even projects `resolved` →
  `resolution` (`tracker-migrate-forward.sh:548`). No contradiction remains; the §1.7
  contradiction (`Position:` named optional vs absent from Part 7) is removed.

### SC-4 — Scope: PASS

- `git status --short` → ` M backlog/_rules.md` + `?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-4.7.md` (untracked-intentional per the calling prompt) — nothing else.
- `git diff --name-only` → `backlog/_rules.md` only. `supporting-docs/METHODOLOGY.md` and the
  three `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md` are
  byte-untouched. Boundary clean — `pack-only` keyword is honest (pack-ops surface only;
  no `project-template/` or `supporting-docs/` path in the diff).

### SC-5 — Validation green: PASS

- `python3 scripts/validate-pack.py` (general path) → **exit 0**, "PASSED — all checks clean"
  (Check 34 cross-reference integrity green; Check 50 green; deep check SKIP with env unset,
  as designed).
- Stale-assertion sweep (enumerate-encoding-surfaces): `grep -rn "and optional" scripts/ .github/`
  → **zero hits**. `grep -rn "backlog/_rules" scripts/ .github/` → every hit is a
  filename/path reference only (back-pointer literals in fixtures, presence checks like
  `test-v11-realistic-ot.sh:157` `assert_file "backlog/_rules.md present"`,
  `init-project.sh:1035/1039` copy-by-basename, `test-validate-pack-checks-32-33-34.sh:422`
  delete-the-fixture-copy negative case). **No validator, test, or CI workflow pins the
  removed enumeration or any `_rules.md` Entry-contract prose.**
- Tests run (the files whose assertions touch `backlog/_rules.md` presence/structure, plus the
  field-faithfulness check): `scripts/tests/test-per-entry.sh` → exit 0;
  `scripts/tests/test-validate-pack-checks-32-33-34.sh` → exit 0;
  `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` → exit 0.
  (All three build synthetic `_rules.md` fixtures; none reads the real file's prose — run
  anyway as the closest encoding surfaces.)
- The coder's IMPL-REPORT §6 additionally attests the FULL 55-step unattended battery green
  (log `/tmp/bd204-c47-battery.log`), satisfying PLAN §3.LF.6's "+ FULL battery (3.LF.9)"
  verification clause; my independent pass covers validate-pack + the targeted encoding
  surfaces per the calling prompt's docs-only scoping.

### SC-6 — Plan conformance (PLAN-BD-204.md §3.LF.6): PASS

Every §3.LF.6 directive is satisfied:

- File scope `backlog/_rules.md` ONLY → confirmed (SC-4).
- Change recipe (design §3.5): field-faithful statement + template-as-COMMON-field-SSOT +
  extension fields admitted/preserved + stop enumerating the divergent optional-field list →
  the new paragraph matches the ARCHITECTURE-BD-204-LOSSLESS-FIX.md §3.5 architect
  recommendation (`:640-651`) point for point, including the "carries every top-level field
  verbatim" and "Target, Position, etc." phrasing.
- Edit-in-place, NOT a full rewrite → confirmed (single hunk; SC-3).
- METHODOLOGY NOT edited; 3 project-side `_rules.md` not touched (G-3 divergence-by-design) →
  confirmed (SC-4).
- Verification: validate-pack green, no validator pins the old text (coder grep-confirmed,
  reviewer independently re-confirmed), full battery per coder. No `scripts/` touched → no
  manifest regen; `git status --short test-fixtures/manifest.txt` → empty. Confirmed.

## 2. Reviewer-checklist items not covered above

- **Trinity rule:** N/A — no CLAUDE.md / AGENTS.md / GEMINI.md (pack-root or
  project-template) in the diff.
- **Cross-reference integrity:** Check 34 green (2702 references / 222 files resolved).
  Repo-wide markdown grep for the removed phrase ("and optional" + field names) finds only:
  the IMPL-REPORT's intentional BEFORE-quote, and
  `ARCHITECTURE-BD-204-LOSSLESS-FIX.md:148` (an Empirical-Evidence Block quoting the
  pre-state at its measurement HEAD — accurate history, not a stale live reference).
  PLAN §3.LF.6's "currently names `Position:` as optional at `:49`" is likewise a pre-state
  description in a plan doc; correct as written history.
- **Migration safety / README layout / validate-pack alignment:** N/A — `backlog/_rules.md`
  is a pack-ops file (not shipped to projects), no files added/moved/removed, no new
  directories.
- **BACKLOG accuracy:** BD-204 remains mid-chain (C-4.7 is one commit-unit of the §3.LF
  sequence); no status flip due at this commit.

## 3. Out of scope — surfaced (no action required for C-4.7)

- **`Resolved:` (pack-tree convention) vs `Resolution:` (METHODOLOGY Part 7) naming
  divergence is pre-existing and now implicit.** The old text explicitly listed `Resolved:`;
  the new text names Part 7's `Resolution:` among the COMMON fields while the Lifecycle
  section (`backlog/_rules.md:69`, `:73-75`) still normatively requires a `Resolved:` line.
  This is internally consistent (any field is admitted; the migrator maps both —
  `tracker-migrate-forward.sh:548` `"resolved": "resolution"`), and the divergence pre-dates
  C-4.7. Surfaced for awareness only; no change recommended within this commit-unit.
- Pre-existing Check 48 advisory WARNs (removed-doc citations in `changelog/v8.md` etc.) are
  unrelated to and pre-date this edit (also noted in IMPL-REPORT §12).

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | `agents-never-commit` | Git commands run this session: `git status --short`, `git diff --name-only`, `git rev-parse HEAD`, `git show HEAD:backlog/_rules.md`, `git diff --stat` — all read-only. `git rev-parse HEAD` → `40eaa85c31d0e742338274f45fe85f9c2d6aebd0` (unchanged start to end); no add/commit/push/tag/checkout executed. | COMPLIANT |
| 2 | `per-action-approval-sub-agents` | No destructive op run. Only file write this session: this report at the prompt-specified path `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-C-4.7.md` (new file, not overwriting a trusted file). No `rm`, no `git rm`. | COMPLIANT |
| 3 | `rules-applied-verification-block` | This table: 10/10 in-force rules, each with quoted command/path/line evidence and a terminal conclusion; no empty-evidence row, no AMBIGUOUS. | COMPLIANT |
| 4 | `deferral-is-scope-creep` | Finding count = 0; nothing deferred. The two out-of-scope observations (§3) are pre-existing conditions surfaced per BD-195 GOALS, not deferred findings on this change — evidence: `Resolved:`/`Resolution:` divergence exists at HEAD (`git show HEAD:backlog/_rules.md` old `:48` listed `Resolved:`; METHODOLOGY:1214 lists `Resolution:`), pre-dating the diff. | COMPLIANT |
| 5 | `no-deferral-without-user-direction` | No defer-recommendation issued anywhere in this report (grep this file for "defer" → only rule-text and this row). Verdict is CLEAN with zero findings to land or defer. | COMPLIANT |
| 6 | `enumerate-encoding-surfaces` | Swept ALL encoding surfaces for `backlog/_rules.md` content: `grep -rn "and optional" scripts/ .github/` → 0 hits; `grep -rn "backlog/_rules" scripts/ .github/` → 30+ hits, every one a filename/back-pointer/presence reference (e.g. `test-v11-realistic-ot.sh:157`, `init-project.sh:1035`), none pinning Entry-contract prose; ran the 3 nearest tests (`test-per-entry.sh`, `test-validate-pack-checks-32-33-34.sh`, `test-validate-pack-check-49-field-faithfulness.sh`) → all exit 0; repo-wide `.md` grep for the removed phrase → only intentional history quotes (IMPL-REPORT, ARCHITECTURE:148). | COMPLIANT |
| 7 | `P-missed-7 / boundary-investigation-precedes-pack-defaults` | `git diff --name-only` → `backlog/_rules.md` (pack-ops surface) only; `supporting-docs/METHODOLOGY.md` + `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md` not in the diff. The change DEFERS to the client-shipped template as field SSOT rather than editing it — correct boundary direction. | COMPLIANT |
| 8 | `preflight-stop-means-stop` | No stop/halt/revert message received from the parent at any point in this session; review ran to completion. | COMPLIANT |
| 9 | `edit-in-place-not-full-rewrite` | Verified the C-4.7 diff is surgical: `git diff --stat backlog/_rules.md` → `1 file changed, 14 insertions(+), 3 deletions(-)`, single hunk `@@ -45,9 +45,20 @@`; heading-map diff vs `git show HEAD:backlog/_rules.md` → text-identical headings, line-offset-only deltas (`52→63`, `66→77`, `77→88`). No section dropped. | COMPLIANT |
| 10 | `verify-full-ci-suite` | Independently ran: `python3 scripts/validate-pack.py` → `exit=0` / "PASSED — all checks clean"; `test-per-entry.sh` → `exit=0`; `test-validate-pack-checks-32-33-34.sh` → `exit=0`; `test-validate-pack-check-49-field-faithfulness.sh` → `exit=0`. Sweep (rule-6 row) proves no other battery test pins the changed doc content. Coder's IMPL-REPORT §6 attests the FULL 55-step battery green ("OVERALL: ALL GREEN — zero FAIL lines"), satisfying PLAN §3.LF.9; reviewer scope per calling prompt = validate-pack + content-touching tests, which is what was run and named. | COMPLIANT |
