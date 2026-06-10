# IMPL-REPORT — BD-204 C-4.7 (schema-doc reconciliation; §3.LF.6)

**Commit:** `docs: v11 — BD-204 backlog/_rules.md field-faithful migration + Position/template contradiction fix (pack-only)` (NOT committed — agents never commit; Pack Chat stages/commits with user approval)
**Branch:** `v11-dev`
**HEAD SHA (worktree, unchanged — no git-state op performed):** `40eaa85c31d0e742338274f45fe85f9c2d6aebd0`
**Keyword:** `pack-only`
**Recipe:** PLAN-BD-204.md §3.LF.6 (read in full)
**Design:** ARCHITECTURE-BD-204-LOSSLESS-FIX.md §3.5 (+ §3.3 mechanism, read in full)

---

## 1. Scope + deliverable

Single in-place targeted edit to `backlog/_rules.md` § "Entry contract" — replace the
divergent optional-field enumeration (`Position:` named optional at the old `:49`, which
contradicted METHODOLOGY.md Part 7) with a FIELD-FAITHFUL statement that references the
template as the COMMON-field SSOT and admits + preserves EXTENSION fields. No other section
of `_rules.md` touched. No rewrite.

---

## 2. Files changed inventory

| Path | Change type |
|---|---|
| `backlog/_rules.md` | modified (in-place; § "Entry contract" only) |

Line delta: `1 file changed, 14 insertions(+), 3 deletions(-)`.

No new files (other than this IMPL-REPORT, which the caller's prompt specified as the
deliverable path). No deletions. No `scripts/` touched → NO manifest regen (confirmed
unchanged below). `test-fixtures/manifest.txt` byte-unchanged.

---

## 3. The reconciled lines — before / after

### BEFORE (old `:43`–`:50`)
```
## Entry contract

One BD entry per file. The first line is an HTML-comment back-pointer
ABOVE the bold-header; the entry's content span begins at
`**BD-NNN — <Title>**`, followed by the `Type:` / `Status:` /
`Description:` (and optional `Blockers:` / `Unblocks:` / `File/Symbol:`
/ `Resolved:` / `Position:`) fields per the standard BACKLOG item
format (METHODOLOGY.md Part 7).
```

The parenthetical `(and optional Blockers:/Unblocks:/File/Symbol:/Resolved:/Position:)`
was the §1.7 contradiction: it named `Position:` (and `Resolved:`) as part of the format
while METHODOLOGY.md Part 7's "BACKLOG item format" does NOT list `Position:`, and the
enumeration also omitted Part 7's `Context:` / `Resolution:` — a divergent, drifting
allowlist that the field-faithful carrier makes unnecessary.

### AFTER (new `:43`–`:61`)
```
## Entry contract

One BD entry per file. The first line is an HTML-comment back-pointer
ABOVE the bold-header; the entry's content span begins at
`**BD-NNN — <Title>**`, followed by the `Type:` / `Status:` /
`Description:` fields per the standard BACKLOG item format
(METHODOLOGY.md Part 7).

**Field-faithful — the contract does not gate on a field allowlist.**
The Mode-2→3 migrator is FIELD-FAITHFUL: it carries every top-level
entry field VERBATIM (the entry body is preserved byte-for-byte as the
`pack-entry-body-gz64` blob), so the contract does NOT depend on
enumerating which fields are "allowed". METHODOLOGY.md Part 7 (the
template SSOT) enumerates the COMMON fields (`Type:` / `Status:` /
`Blockers:` / `Unblocks:` / `File/Symbol:` / `Description:` /
`Context:` / `Resolution:`); EXTENSION fields (`Target:`, `Position:`,
etc.) are ADMITTED and PRESERVED. A future BD adding a field needs no
contract change here — the carrier carries whatever bytes the entry
body has.
```

This is exactly the design §3.5 architect recommendation: (a) migrator is field-faithful
(carries every top-level field verbatim via the gz64 blob); (b) the template (METHODOLOGY
Part 7) enumerates the COMMON fields; (c) extension fields (Target, Position, etc.) are
admitted + preserved; (d) the divergent optional-field list that contradicted the template
is removed. The COMMON-field list quoted matches Part 7's "BACKLOG item format" block
verbatim (Type/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution).

### Full git diff
```
diff --git a/backlog/_rules.md b/backlog/_rules.md
index 1b8f19c..86f0d8e 100644
--- a/backlog/_rules.md
+++ b/backlog/_rules.md
@@ -45,9 +45,20 @@ suffix, no pre-em-dash parenthetical).
 One BD entry per file. The first line is an HTML-comment back-pointer
 ABOVE the bold-header; the entry's content span begins at
 `**BD-NNN — <Title>**`, followed by the `Type:` / `Status:` /
-`Description:` (and optional `Blockers:` / `Unblocks:` / `File/Symbol:`
-/ `Resolved:` / `Position:`) fields per the standard BACKLOG item
-format (METHODOLOGY.md Part 7).
+`Description:` fields per the standard BACKLOG item format
+(METHODOLOGY.md Part 7).
+
+**Field-faithful — the contract does not gate on a field allowlist.**
+The Mode-2→3 migrator is FIELD-FAITHFUL: it carries every top-level
+entry field VERBATIM (the entry body is preserved byte-for-byte as the
+`pack-entry-body-gz64` blob), so the contract does NOT depend on
+enumerating which fields are "allowed". METHODOLOGY.md Part 7 (the
+template SSOT) enumerates the COMMON fields (`Type:` / `Status:` /
+`Blockers:` / `Unblocks:` / `File/Symbol:` / `Description:` /
+`Context:` / `Resolution:`); EXTENSION fields (`Target:`, `Position:`,
+etc.) are ADMITTED and PRESERVED. A future BD adding a field needs no
+contract change here — the carrier carries whatever bytes the entry
+body has.
 
 ## Lifecycle states admitted
 
```

---

## 4. Byte-unchanged attestation (rest of `_rules.md`)

After editing I re-read the entire file (95 lines) and confirmed the change is isolated to
§ "Entry contract". `git diff` shows a SINGLE hunk at the Entry-contract paragraph
(`@@ -45,9 +45,20 @@`). Every OTHER section is byte-identical to HEAD:

- header / Audience+Purpose blockquote — unchanged
- § Stream identity — unchanged
- § Source of truth — no mirror — unchanged
- § Filename convention (the grammar / `^BD-\d+\.md$` / no-letter-suffix BD-211 rule) — unchanged
- § ID-extraction rule — unchanged
- § Lifecycle states admitted (Open/Unblocked/Deferred/Resolved/Deprecated/Cancelled + resolve-in-place) — unchanged
- § Supporting files — unchanged
- § Write authority — unchanged

The grammar, lifecycle states, and ID rules named in the prompt are all byte-unchanged.

---

## 5. No-validator-pins-the-old-text grep (verification)

The old optional-field-list text is not asserted by any validator, test, or CI workflow, so
removing it does not break a check.

`CMD`: `grep -rn "Position:" scripts/ .github/` (excluding `.git/`)
`OUT`: two hits only — `scripts/tests/tracker-migrate-roundtrip-test.sh:502` and
`scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md:56` — both are ROUND-TRIP FIXTURE
DATA (a fixture entry that carries a `Position:` drop-set field to prove field-faithfulness),
NOT references to the `_rules.md` Entry-contract prose. Unaffected by this edit.

`CMD`: `grep -rn "_rules.md" scripts/ .github/` (excluding project-template)
`OUT`: validators/tests reference `_rules.md` only by FILENAME for PRESENCE checks
(`validate-pack.py` Check 32/33 family asserts `_rules.md` exists in each stream;
`init-project.sh` / `migrate-v10-to-v11.sh` copy the file by basename;
`test-per-entry.sh` builds its OWN synthetic `_rules.md` inline at `fixture_pack_backlog_rules()`
declaring only Stream identity + Supporting files — it never reads the real
`backlog/_rules.md` Entry-contract field enumeration). No validator/test pins the
optional-field-list prose (`Blockers:`/`Unblocks:`/`File/Symbol:`/`Resolved:`/`Position:`
enumeration). **CONCLUSION: no check pins the removed text → safe to remove. Did NOT need to
STOP.**

---

## 6. FULL unattended CI battery — result

Per §3.LF.9 + verify-full-ci-suite, ran the ENTIRE unattended battery enumerated from
`.github/workflows/validate-pack.yml` (every `run:` step), NOT a subset. 55 invocations.

**OVERALL: ALL GREEN — zero FAIL lines (exit 0 on every step).**

Battery executed (in workflow order):
- `python3 scripts/validate-pack.py` — **PASSED — all checks clean** (Check 34
  cross-reference integrity: OK, 2702 references / 222 files all resolved; Check 50
  OQ-4 single-source codec: OK; Check 48 removed-doc WARNs are pre-existing advisory-only,
  none introduced by this edit; deep check SKIP as expected with env unset)
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` — GREEN (deep field-faithfulness
  leg on the real ≥211 tree)
- `test-detect.sh`, `tracker-provider-test.sh`, `tracker-config-test.sh`,
  `tracker-init-test.sh`, `tracker-agent-read-test.sh`, `tracker-migrate-forward-test.sh`,
  `tracker-migrate-reverse-test.sh`, `tracker-migrate-roundtrip-test.sh`,
  `test-tracker-phase-task.sh`, `test-tracker-links.sh`, `test-tracker-cycle-check.sh`,
  `tracker-errors-test.sh`, `tracker-config-schema-test.sh`,
  `recommendation-state-schema-test.sh`, `test-per-entry.sh` — all OK
- per-check tests: `32-33-34`, `36-37-38`, `39`, `40`, `41`, `18`, `16`, `19`, `42`, `43`,
  `44`, `45`, `46`, `removed-doc-advisory`, `49-field-faithfulness` — all OK
- `tracker-bd129/130/132/133/134`, `recommendation-test.sh`, `pack-help-test.sh`,
  `test-customization-preserve.sh`, `test-init-project.sh`,
  `test-migrate-v10-to-v11{,-dry-run,-gates,-decompose}.sh` — all OK
- `test-migrator-core.sh`, `test-migrator-manifest.sh`,
  `test-migrator-capability-translation.sh`, `test-fixtures/build.sh --verify`,
  `test-v11-realistic-ot.sh` (banner-pinning), `test-migrator-skills.sh`,
  `test-persona-contracts.sh`, `template-translations-test.sh`,
  `template-version-test.sh`, `test-issue-forms.sh` — all OK

Note on the manifest step: the workflow's `git checkout HEAD -- test-fixtures/manifest.txt`
is a git-state op forbidden to agents (`agents-never-commit`); I substituted the equivalent
NON-mutating `bash test-fixtures/build.sh --verify` (manifest byte-faithful verify), which
passed. The full log lives at `/tmp/bd204-c47-battery.log`.

---

## 7. Manifest unchanged

`CMD`: `git status --short test-fixtures/manifest.txt` → empty.
`CMD`: `git diff --stat test-fixtures/manifest.txt` → empty.
No `scripts/`, `project-template/`, `pack-ops/`, or `supporting-docs/` file is in the diff
(only `backlog/_rules.md`), so `backlog/` is NOT a v11-surface dir → NO manifest regen
required, and the manifest is confirmed byte-unchanged. `build.sh --verify` GREEN.

---

## 8. Boundary discipline check (P-missed-7 pre-flight)

This edit touches a pack-ops surface (`backlog/_rules.md`), NOT a project-shipped surface
(`project-template/` / `supporting-docs/`), so it does not trip the project-side
SSOT-investigation requirement. Boundary attestations:

- **`supporting-docs/METHODOLOGY.md` — UNTOUCHED.** `git status --short` on it → empty. It
  ships to clients (`supporting-docs/`); editing it would forfeit `pack-only` and cross the
  boundary (design R9 / §3.5). It stays the COMMON-field template as-is. The reconciliation
  was done by making `backlog/_rules.md` DEFER to the template, not by editing the template.
- **3 project-side `_rules.md` (`project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md`)
  — UNTOUCHED.** `git status --short` on all three → empty. They diverge until BD-206/207 by
  design (G-3) and are out of scope.
- **No pack-only target newly referenced in a project-side surface.** The edit ADDS a
  reference FROM the pack-ops `backlog/_rules.md` TO `supporting-docs/METHODOLOGY.md Part 7`
  (a client-shipped template named as the COMMON-field SSOT). That reference direction
  (pack-ops doc → shipped template) is pre-existing in this same paragraph (the old text
  already said "per the standard BACKLOG item format (METHODOLOGY.md Part 7)") and is correct:
  `backlog/_rules.md` is a pack-ops file, free to cite METHODOLOGY. No "Boundary discipline
  stop" condition is met — no edit adds a pack-only file reference to a project-side surface.

---

## 9. Definition-of-Done checklist

| # | Item | Result |
|---|---|---|
| 1 | Field-faithful statement added (carries every top-level field verbatim via gz64 blob) | PASS |
| 2 | Template (METHODOLOGY Part 7) named as COMMON-field SSOT | PASS |
| 3 | Extension fields (Target, Position, ...) stated ADMITTED + PRESERVED | PASS |
| 4 | Divergent optional-field list (`Position:` enum contradicting template) removed | PASS |
| 5 | Targeted in-place edit, NOT a rewrite | PASS (single hunk; rest byte-unchanged) |
| 6 | Rest of `_rules.md` byte-unchanged (grammar/lifecycle/ID rules) confirmed by re-read | PASS |
| 7 | `backlog/_rules.md` is the ONLY file edited | PASS (`git status` → only `M backlog/_rules.md`) |
| 8 | `supporting-docs/METHODOLOGY.md` untouched | PASS |
| 9 | 3 project-side `_rules.md` untouched | PASS |
| 10 | `validate-pack.py` GREEN incl. Check 34 | PASS |
| 11 | No validator pins the old optional-field-list text (grep-confirmed) | PASS |
| 12 | FULL unattended battery GREEN (not a subset) | PASS (55/55, exit 0) |
| 13 | Manifest unchanged (no v11-surface dir touched) | PASS |
| 14 | No git-state change (agents never commit) | PASS (HEAD == 40eaa85, working tree only) |

---

## 10. Plan deviations

ZERO. Implemented §3.LF.6 exactly — the field-faithful statement + the contradiction fix on
`backlog/_rules.md` only, no more.

One methodological note (not a plan deviation): the workflow's manifest step uses
`git checkout HEAD -- test-fixtures/manifest.txt` (a git-state verb forbidden to agents); I
ran the equivalent non-mutating `build.sh --verify` instead. The verification intent (manifest
byte-faithful) is satisfied and the manifest is confirmed unchanged.

---

## 11. New POQs introduced

NONE.

---

## 12. CONCERNS

NONE blocking. Observations (out-of-scope, surfaced not fixed, per scope-deliverables-to-the-ask):

- **Pre-existing Check 48 WARNs** (14 removed-doc citations across `changelog/v8.md`,
  `changelog/v9.md`, `backlog/BD-030/044/046/193.md`) are advisory-only (JC-5 accurate-history
  citations, exit code unaffected), unrelated to this edit, and pre-date it. Not touched.
- The fixture round-trip tests already exercise a `Position:` extension field
  (`fixtures/roundtrip/bd-v11.0/BACKLOG.md:56`), which is consistent with the new
  field-faithful contract text — no action needed; noted as corroboration.

---

## 13. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No git-state verb run. `git rev-parse HEAD` = `40eaa85c31d0e742338274f45fe85f9c2d6aebd0` at start AND end (unchanged). `git status --short` = ` M backlog/_rules.md` only — working tree only; no add/commit/push/checkout-mutate. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op performed (no `rm`, `git rm`, overwrite of a trusted file). The only writes are the in-place Edit to `backlog/_rules.md` and this IMPL-REPORT (the caller's specified deliverable, a new unique path). | COMPLIANT |
| `preflight-stop-means-stop` | Emitted `PREFLIGHT: 1/1 in-scope edits complete; verification PASS; HEAD 40eaa85...; about to Write IMPL-REPORT to <path>` ONLY after the single edit + validate-pack Check 34/43 + the FULL battery all PASSED (battery `OVERALL FAIL FLAG: 0`). No parent stop received. | COMPLIANT |
| `verify-full-ci-suite` | Ran ALL 55 `run:` steps from `.github/workflows/validate-pack.yml` (general + deep validate-pack, all tracker tests, all per-check tests, migrators, `build.sh --verify`, `test-v11-realistic-ot.sh` banner-pinning, persona/skills/translations/issue-forms) — not a named subset. Result: `OVERALL FAIL FLAG: 0`, grep `!!!!! FAIL` → `(none)`. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | Single `Edit` call replacing only the Entry-contract paragraph. `git diff --stat` = `1 file changed, 14 insertions(+), 3 deletions(-)`; one hunk `@@ -45,9 +45,20 @@`. Re-read all 95 lines post-edit and confirmed the section map: every other § byte-unchanged. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly §3.LF.6: `backlog/_rules.md` only; field-faithful statement + contradiction fix; nothing more. `git status --short` confirms `backlog/_rules.md` is the sole modified file. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | `git status --short` on `supporting-docs/METHODOLOGY.md` and the 3 `project-template/docs/project/*/_rules.md` → all empty (untouched). Reconciliation done by `backlog/_rules.md` deferring to the existing client template, not by editing the template or reaching for a pack-style mechanism. METHODOLOGY (client-shipped) stays the SSOT it already is. | COMPLIANT |
| `rules-applied-verification-block` | This table — each in-force rule with quoted command/measurement evidence + a COMPLIANT/N/A/VIOLATED conclusion; no empty evidence. | COMPLIANT |
