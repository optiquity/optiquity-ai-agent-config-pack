# PACK-REVIEW-BD-180.md

Per-commit review report for BD-180 — Extend `cmd_update` mapping symmetry
coverage to remaining surfaces (observations A-G). Single review pass per
the BD-175 emergency batch elevated-care protocol.

- Reviewed commit: `78a4415` (HEAD of v11-dev at review time)
- Reviewer agent: pack-reviewer (sequential, in-place against parent worktree)
- Date: 2026-05-20
- Compared range: `git diff 47f7cbf..78a4415` (6 files, +1409 / -51)

---

## §1 Verdict

**APPROVE-WITH-FIXES.**

Implementation is substantively correct: all 7 observations (A-G) are
closed per the BACKLOG description and IMPL-REPORT decisions. The
`scripts/validate-pack.py` Check 39 reverse-direction extension and the
new Check 41 are well-designed, test-covered, and CI-green at HEAD.
The `_CLIENT_INSTALLED_FILES_START`/`_END` self-documenting inventory
realizes the ARCHITECTURE-BD-176.md §5.3 design sketch faithfully
(with documented refinements). Boundary discipline is satisfied (zero
project-template/ edits in this commit). Manifest is clean
(`build.sh --verify` passes; 3 expected v11-* drifts staged correctly).

Two SHOULD-class findings and one NIT identified. None are
blocking. The two SHOULDs are mechanical, one-line fixes that
improve the integrity contract Check 41 enforces.

---

## §2 Severity breakdown

| Severity | Count |
|---|---|
| BLOCKER | 0 |
| MUST | 0 |
| SHOULD | 2 |
| NIT | 1 |

---

## §3 Per-observation A-G verification table

| Obs | Coder claim | Reviewer finding | Status |
|---|---|---|---|
| **A** | S11 explicit-copy block added for `.gemini/commands/pm-startup.toml`; cmd_update mapping added | Verified: S11 block present at `scripts/init-project.sh:stage_s11_v11_artifacts()` parallel to `pack-help.toml` block; cmd_update entry present at the entries=() array; fixture `test-fixtures/v11-flat-file/.gemini/commands/pm-startup.toml` now exists; source `project-template/.gemini/commands/pm-startup.toml` confirmed at HEAD | Closed cleanly |
| **B** | 2 cmd_update mappings added for `.claude/skills/pm-startup/SKILL.md` + `.codex/skills/pm-startup/SKILL.md` | Verified: both entries present at `scripts/init-project.sh:cmd_update()` entries=() array with inline rationale comment; both source files exist at HEAD | Closed cleanly |
| **C** | No cmd_update mapping (intentional non-install); documented in `_CLIENT_INSTALLED_FILES` "Intentionally NOT installed" sub-section | Verified: rationale documented at `scripts/init-project.sh` inventory header comment block; `settings.local.example.json` does NOT appear in cmd_update or in the START/END entries block; no spurious install path | Closed cleanly (intentional exemption) |
| **D** | 7 cmd_update mappings added for per-entry skeleton templates | Verified: all 7 entries present (`docs/project/backlog/_rules.md`, `_intro.md`; `implementation-plan/_rules.md`, `_intro.md`; `changelog/_rules.md`, `_intro.md`, `_format.md`); all source files exist; all 7 destination paths present in fixture `test-fixtures/v11-flat-file/docs/project/` | Closed cleanly |
| **E** | Stale `PROMPT-TEMPLATES.md` mapping REMOVED; Check 39 reverse-direction extension implemented | Verified: no `PROMPT-TEMPLATES.md` mapping in cmd_update; reverse-direction `for pack_rel in sorted(entries):` loop at `scripts/validate-pack.py:check_cmd_update_symmetry()` iterates entries set and FAILs on missing source; `_CHECK_39_REVERSE_EXEMPTIONS` allowlist defined; in-line comment replaces removed entry; file genuinely absent from `project-template/` and `supporting-docs/` (grep clean) | Closed cleanly |
| **F** | 2 cmd_update mappings added: `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md` | Verified: both entries present with inline rationale; both source files exist; both destination paths (`docs/pack/METHODOLOGY.md`, `docs/pack/INSTALL-PROCEDURES.md`) present in fixture | Closed cleanly |
| **G** | `_CLIENT_INSTALLED_FILES_START`/`_END` block added immediately after `cmd_update()` body; Check 41 added in `validate-pack.py` with parser + integrity assertions (a)-(d) | Verified: 38 inventory entries parse correctly via `_parse_client_installed_files`; Check 41 passes at HEAD (38 entries resolve, 35 cmd_update cross-check shows zero drift); in-code reference `"BD-180 observation G per ARCHITECTURE-BD-176.md §5.3"` present at `scripts/init-project.sh:1237`; reconciliation chain (a) + (c) satisfied per pack memory architect-doc-vs-reality | Closed cleanly with finding §4.1 below on docstring vs. implementation contract drift |

All 7 observations closed cleanly. Findings below relate to surrounding
code-quality details, NOT to observation closure.

---

## §4 Findings

### §4.1 SHOULD-1: Check 41 docstring promises "exactly once" marker uniqueness; parser only enforces "at least once"

- **Severity:** SHOULD
- **File:symbol:** `scripts/validate-pack.py:_parse_client_installed_files` (parser) and `scripts/validate-pack.py` header docstring entry for Check 41
- **Problem:** The header docstring for Check 41 explicitly states the
  contract as `"(a) the START/END markers exist exactly once each"`.
  The parser implementation at `_parse_client_installed_files` enforces
  only `text.count(start_marker) >= 1` and `text.count(end_marker) >= 1`
  — i.e., "at least once." The IMPL-REPORT §3.5 also says "each MUST
  appear at least once," which agrees with the implementation but
  contradicts the header docstring contract.

  Practical consequence: if a future maintainer accidentally introduces
  a duplicate `_CLIENT_INSTALLED_FILES_START` or `_END` marker (e.g.,
  by copy-pasting the inventory block during a refactor), the parser
  silently uses the first START + first END (non-greedy regex match)
  and the validator passes despite the contract violation. The
  duplication is exactly the failure mode the "exactly once" contract
  is meant to catch — but the contract isn't enforced.
- **Suggested fix:** Two-line implementation change. Replace the two
  `>= 1` checks with explicit equality:
  ```python
  start_count = text.count(start_marker)
  end_count = text.count(end_marker)
  if start_count != 1 or end_count != 1:
      return ([], start_count == 1, end_count == 1)
  ```
  And update the `check_client_installed_files` failure path to surface
  duplicate-marker as a distinct error (vs. the existing missing-marker
  message). Alternatively, soften the header docstring to "at least once"
  to match implementation — but the stricter behavior is the
  defensive-by-design choice and matches Check 41's "discoverability
  contract" framing.
- **Rationale:** Documented contract should match enforced behavior;
  drift between docstring and code degrades the value of the
  self-documenting list as an integrity gate. Surface-over-silently-fail
  matches the design philosophy stated in the file header for the
  `_CHECK_*_EXEMPTIONS` allowlists ("surface-over-silently-exempt").
  Reference: review skill `correctness` priority + IMPL-REPORT §3.5
  description that disagrees with the file header docstring.

### §4.2 SHOULD-2: `_parse_client_installed_files` returns silent empty list on regex non-match without distinguishing it from empty-block

- **Severity:** SHOULD
- **File:symbol:** `scripts/validate-pack.py:_parse_client_installed_files`
- **Problem:** The regex-match path can fail (`if not m: return ([], start_seen, end_seen)`)
  for reasons other than missing markers — for example, if the END marker
  appears textually before the START marker, or if the START and END
  markers are on the same line, or if the body between markers cannot
  be matched by the non-greedy `(.+?)\n[^\n]*` capture pattern. In all
  these cases, the function returns `([], True, True)` (since both
  markers literally exist somewhere in the file), and
  `check_client_installed_files` then issues the "block contains no
  parseable entries" failure message — which is misleading because the
  underlying problem is regex-shape mismatch, not an empty block.
- **Suggested fix:** When markers exist but the regex fails to capture
  a body, surface a distinct failure such as:
  ```python
  # Markers exist but body extraction failed (out-of-order, single-line,
  # or unusual whitespace).
  if not m:
      fail(f"...markers present but block body could not be parsed...")
      return
  ```
  Or return a third signal from the parser (`(entries, start_seen, end_seen, parse_ok)`)
  so the caller can emit the correct diagnostic. At minimum, document
  the parser's behavior in its docstring — it currently claims "Comment-
  only lines... are skipped" but doesn't note that regex failures
  collapse into empty-entries silently.
- **Rationale:** Diagnostic quality matters for self-debugging integrity
  gates: when a future maintainer trips this check, the failure message
  should point at the actual cause, not a category mismatch. The
  difference between "your markers are missing" and "your block has
  weird formatting" is meaningful for the fixer. Reference: review skill
  "Error handling: no empty catch blocks, no swallowed errors, correct
  error propagation across boundaries."

### §4.3 NIT-1: Commit subject line length

- **Severity:** NIT
- **File:symbol:** commit `78a4415` subject
- **Problem:** Subject is 72 characters, 2 over the 70-character soft
  guideline in CLAUDE.md (commit-format section). Not enforced by any
  CI check; flagged for completeness only. Subject reads
  `"feat: v11 — BD-180 cmd_update mapping symmetry across remaining surfaces"`.
- **Suggested fix:** No action — subject is informative; trimming to 70
  would lose semantic content (e.g., dropping "across remaining surfaces"
  obscures the BD's scope vs. BD-175 F2a's narrower scope).
- **Rationale:** Existing commit history in the BD-175 batch contains
  multiple subjects over 70 chars (consistent with the pack's typical
  practice when subject substance is load-bearing). The guideline is
  soft; subject quality trumps strict length. Surfacing for transparency,
  not action.

---

## §5 Verification results

All five verification commands returned green:

### §5.1 `python3 scripts/validate-pack.py` at HEAD

```
── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) forward-checked; 6 have explicit `cmd_update` mappings, 0 on forward exemption allowlist. 35 `cmd_update` entries reverse-checked; 35 resolve to existing files at HEAD, 0 on reverse exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings; no stale mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

============================================================
PASSED — all checks clean
```

Exit code: 0. All 41 distinct check stages clean. Check 41 is properly
registered in `main()`.

### §5.2 `bash scripts/tests/test-validate-pack-check-39.sh`

```
PASS: 6
FAIL: 0
All tests passed.
```

Group 2b (reverse-direction T6/T7/T8/T9) passes; updated T4 (stub-source
trick) passes; Group 4 end-to-end output assertions match new
forward-checked/reverse-checked language.

### §5.3 `bash scripts/tests/test-validate-pack-check-41.sh`

```
PASS: 4
FAIL: 0
All tests passed.
```

All four groups pass:
- Group 0 (module import + symbol registration)
- Group 1 (`_parse_client_installed_files` against real init-project.sh)
- Group 2 (synthetic PASS/FAIL T1-T7: PASS, stale-source, inventory-drift,
  PASS-with-exemption, missing START, missing END, empty block)
- Group 3 (end-to-end validate-pack.py exit-status on HEAD)

### §5.4 `bash test-fixtures/build.sh --verify`

```
v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot OK: add3450a7accd73db8a84add0c975919156f5c02
v11-flat-file OK: 991dfa306b688037b5a17fbfcde8ce35cb6a46e8
v11-tracker-on OK: 9cf477864a411037ae6b3a52f03071cb458ffac7
existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All six fixture rows match. The 3 v11-* drifts (per IMPL-REPORT §8) are
present and correct: v11-realistic-ot, v11-flat-file, v11-tracker-on all
now carry post-BD-180 SHAs matching the rebuilt content. v10-* tag-pinned
rows unchanged (correct). `existing-project-mid-dev` unchanged (correct
— a synthetic Swift+Python+gRPC tree, not affected by `init-project.sh`
client-install changes).

### §5.5 Adjacent checks still green

Spot-verified other validate-pack check tests still PASS:
- `test-validate-pack-check-40.sh`: PASS 8 / FAIL 0
- `test-validate-pack-checks-36-37-38.sh`: PASS 6 / FAIL 0

Per IMPL-REPORT §6.1, the broader suite (init-project, customization-preserve,
v11-realistic-ot, migrate-v10-to-v11, persona contracts) all pass per
coder's reported counts (not re-verified here; CI green at HEAD is
the canonical signal). No reason to suspect regression based on this
diff: the changes are additive (new mappings + new check + new test).

### §5.6 Functional spot-checks

- `test-fixtures/v11-flat-file/.gemini/commands/pm-startup.toml` exists
  (was ABSENT before BD-180; confirms observation A install)
- 7 per-entry templates present at
  `test-fixtures/v11-flat-file/docs/project/{backlog,implementation-plan,changelog}/_*.md`
  (confirms observation D install path)
- `test-fixtures/v11-flat-file/docs/pack/METHODOLOGY.md` and
  `docs/pack/INSTALL-PROCEDURES.md` exist (confirms observation F install)
- No `PROMPT-TEMPLATES.md` found anywhere under `project-template/` or
  `supporting-docs/` (confirms observation E source-file absence)
- Inventory parser at HEAD returns 38 entries; cmd_update parser at HEAD
  returns 35 entries; set-difference shows the expected 3 inventory-only
  entries (`pack-ops/HELP-FRAGMENT-TRACKER.md`, `scripts/pack-help.sh`,
  `scripts/lib/detect.sh` — all `[stage:S11]`-only files); cmd_update
  minus inventory is empty (confirms Check 41 (d) cross-check rationale)

### §5.7 Boundary discipline (P-missed-7)

Zero `project-template/` edits in this commit. `git diff --name-only`
returns:
```
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180.md
scripts/init-project.sh
scripts/tests/test-validate-pack-check-39.sh
scripts/tests/test-validate-pack-check-41.sh
scripts/validate-pack.py
test-fixtures/manifest.txt
```

All changes are pack-internal: `scripts/` (pack-only by construction),
`test-fixtures/` (pack-only), `maintenance-docs/` (pack-only). No
project-side surface touched; no project-side SSOT investigation
required. Per boundary-investigation skill Step 5: the project-template/
deny-list is not engaged because no project-side file was modified.

### §5.8 Architect-doc-vs-reality reconciliation

Per pack memory `architect-doc-vs-reality-reconciliation`:
- **(a) In-code reference:** verified at `scripts/init-project.sh`
  line containing the literal `"BD-180 observation G per ARCHITECTURE-BD-176.md §5.3"`
  in the inventory header comment (also re-named in
  `_CLIENT_INSTALLED_FILES_START` symbol naming for searchability).
- **(b) Architect-doc addendum:** Per the calling prompt's explicit
  instruction `"(b) is being handled by a separate addendum coder in
  parallel — DO NOT flag (b) as a finding; Pack Chat is aware."`
  Confirmed read-only that ARCHITECTURE-BD-176.md §5.3 already carries
  an addendum block referencing commit `78a4415` and Check 41 (the
  parallel coder has already landed it in working tree). Not surfaced
  as a finding.
- **(c) IMPL-REPORT cross-reference:** §4 of IMPLEMENTATION-REPORT-BD-180.md
  documents the realization + design refinements. Verified.

Reconciliation chain complete. Pattern matches BD-119 §9.2 → BD-160
canonical worked-example anchor.

---

## §6 Carry-forward observations

**High-bar discipline applied per `.claude/skills/review/SKILL.md` §
"Carry-forward discipline" (FIX-5 in BD-179 fix-cycle).**

Zero carry-forwards survived the SIZE / BLOCKED / LOGICAL-FIT high bar.

The two SHOULD findings and one NIT in §4 are surfaced as in-scope
findings (fix-now triage by Pack Chat per default-fix-all discipline).

Specifically considered and rejected as carry-forward candidates:

1. **Extending `_cmd_update_iter_dir` to walk the canonical skills pool**
   (replacing per-CLI explicit pm-startup + pack-help mappings) — already
   considered and rejected by the coder at IMPL-REPORT §10. Reviewer
   concurs: FAILS SIZE (architect-pass material; contract surface
   re-negotiation for `_cmd_update_iter_dir` is non-trivial). FAILS
   BLOCKED (no real blocker). PASSES only "thematic resemblance" on
   LOGICAL-FIT, which is explicitly forbidden by the carry-forward
   discipline. Not surfaced as a finding (not a defect at HEAD; current
   explicit mappings are correct).

2. **Extending Check 39 forward-direction to walk other surfaces (e.g.,
   `.gemini/commands/*.toml`, `.claude/skills/*/SKILL.md`)** — BACKLOG
   1599 invites this as "coder's choice." The coder chose explicit
   cmd_update mappings + Check 41 cross-check as the discoverability
   guard. This is defensible: Check 41 (d) catches any future cmd_update
   addition that doesn't update the inventory, and the inventory IS the
   canonical broader-pattern enumeration. Forbidden carry-forward shape:
   "broader pattern" framing. The coder's design choice is correct;
   nothing to defer. Not surfaced as a finding.

3. **Soft commit-subject length** (NIT-1) — could be deferred to a
   subsequent broad batch review/fix as a class-wide cleanup. Rejected
   per the carry-forward discipline forbidden shape "End-of-batch
   reviewer might consider… Worth ~N minutes of attention before the
   batch closes." Surfaced as in-scope NIT-1 instead; Pack Chat triage
   decides per default-fix-all (NIT default also FIX per the discipline).

The two SHOULD findings (§4.1, §4.2) are concrete, fix-now defects in
the BD-180 implementation. They do NOT qualify for carry-forward — both
are small-diff fixes (a handful of lines each) within `scripts/validate-pack.py`
with no SIZE / BLOCKED / LOGICAL-FIT justification for delay.

**Forbidden carry-forward shapes self-checked against my own output:**

- Have I said "broader pattern" without expanding scope of an in-scope
  finding? No. The §6.2 "extending Check 39 forward-direction" item is
  framed as a defensible coder choice, not a deferred finding.
- Have I said "worth ~N minutes of attention before batch closes"? No.
- Have I introduced forward-looking conjecture? No. The SHOULD findings
  cite concrete current docstring text vs. implementation behavior.
- Have I tried to ratify design as "intentional tradeoff"? No.
- Have I claimed "pack memory recommends fix-now" while deferring? No.

Zero carry-forwards survive the high bar.

---

## §7 What the implementation got right

Acknowledgments per review skill principle "A review that only lists
problems is incomplete":

- **Mechanical fidelity to the F2a template.** The Check 39 reverse-
  direction extension reuses the existing `_parse_cmd_update_entries`
  parser (zero duplication; the BD-175 F2a invariant is preserved).
  Check 41 follows the same allowlist-with-rationale pattern as Check 39.
  Test harness for Check 41 closely mirrors the Check 39 harness.

- **Self-documenting list location choice** (`init-project.sh` rather
  than `validate-pack.py`) is the simpler-correct location per
  IMPL-REPORT §4.2: the inventory lives where the install logic lives,
  so an actor adding a new copy-site writes both in the same file.
  Co-location enforces same-edit maintenance.

- **Single inventory block** (rather than dual blocks above S6 + S11
  as the §5.3 sketch suggested) reduces DRY violations and gives one
  discoverability anchor. Reviewer concurs this is a correct refinement.

- **The (d) cross-check** in Check 41 (every cmd_update entry must
  appear in the inventory) is the load-bearing drift-prevention
  assertion. Without (d), the inventory could silently lag behind
  cmd_update additions. Good design.

- **Observation C handling** (intentional non-install) is documented
  in the "Intentionally NOT installed" sub-section of the inventory
  header rather than buried in a separate exemption allowlist. This
  makes the rationale discoverable from the same canonical location.
  Pattern is extensible: future intentional non-install files extend
  this list.

- **In-line removal comment for PROMPT-TEMPLATES.md** (observation E)
  preserves the institutional memory of why an entry was removed. An
  actor searching for `PROMPT-TEMPLATES.md` in `init-project.sh` still
  finds context. Good practice.

- **Boundary discipline.** Zero `project-template/` edits; no
  pack-only-into-project-side regression risk. The change is pure
  pack-internal CI tooling + install mechanism.

- **Manifest hygiene.** RC9 manifest regen completed; 3 v11-* SHAs
  drifted as expected; `build.sh --verify` clean at HEAD. The coder
  did NOT stage (per `feedback-agents-never-commit`); Pack Chat owns
  the staging step.

- **Carry-forward discipline in the IMPL-REPORT.** Coder's §10
  explicitly rejected three plausible-but-borderline deferral
  candidates with concrete SIZE / BLOCKED / LOGICAL-FIT reasoning.
  This is the discipline working as designed.

---

## §8 Summary

BD-180 commit `78a4415` is **APPROVE-WITH-FIXES**. All 7 observations
(A-G) are closed cleanly, all tests pass, validate-pack.py is CI-green,
manifest is clean, boundary discipline is satisfied, architect-doc
reconciliation chain is complete.

Two SHOULD-class fixes recommended (Check 41 docstring vs.
implementation marker-uniqueness contract; parser diagnostic quality
on regex non-match path). One NIT (commit subject length, no action
recommended). Zero carry-forwards survived the high-bar discipline.

Pack Chat to triage findings per default-fix-all and proceed to BD
flip to Resolved at batch close.
