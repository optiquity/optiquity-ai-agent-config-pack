# RESEARCH-BD-195-SEGMENT-R7-epicenter

**Segment:** R7 — Contamination epicenter (post-prison remainder).
**Author:** pack-docs-researcher (read-only audit pass; one output file).
**Repo HEAD at read time:** `8ebf8f871dbd9c0fdfc0020db1149baab2a87774` (per repo state at read).
**Branch:** v11-dev.
**Date:** 2026-05-29.
**CATEGORICAL FACT applied (not re-litigated):** v11.0 is UNRELEASED (no tag,
never frozen). Phase-parts was ALWAYS v11.0 scope, never v11.1. Any doc/code
labeling phase-parts (or other in-flight v11.0 work) "v11.1", or asserting
v11.0 was "frozen", is WRONG. EXCEPTION: GitHub Projects + groupings ARE
legitimately v11.1+ (user-authorized deferral) — not flagged as the mislabel.

---

## Segment / owned paths (manifest)

**5 HELD untracked V2 docs:** `ARCHITECTURE-BD-185-V2.md`,
`ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`, `PLAN-BD-185-V2.md`,
`PACK-REVIEW-BD-185-H.2.md` (all under `maintenance-docs/v11-implementation/`),
`maintenance-docs/v11-research/RESEARCH-BD-185-ORDERING-API.md`.

**HELD tracked BD-185-attempt records (`maintenance-docs/v11-implementation/`):**
`IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`, `-Batch-19d-H.2.md`,
`-H.1-NITS.md`, `-POST-PLANNER-POQS.md`, `-ARCHITECT-DOC-EDITS.md`,
`-ARCHITECT-DOC-REVIEW-FIXES.md`, `PACK-REVIEW-BD-185-H.1.md`;
`maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md`.

**BD-193 / BD-194 corpus (`maintenance-docs/v11-implementation/`):**
`ARCHITECTURE-BD-194.md`, `PLAN-BD-194.md`, `PACK-REVIEW-BD-194.md`,
`IMPLEMENTATION-REPORT-BD-194.md`, `-FOLLOWUP.md`, `-STALE-REFS.md`,
`IMPLEMENTATION-REPORT-BD-193.md`, `-PHASE-5.md`, `PACK-REVIEW-BD-193-PHASE-4.md`.

**Groupings docs (`maintenance-docs/v11-research/`):** `REQUIREMENTS-GROUPINGS-V11.md`,
`INTAKE-GROUPINGS-V11.md`, `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`,
`RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`,
`IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md`,
`IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md`.

**templates-archive (`maintenance-docs/v11-research/templates-archive/`):**
`README.md`, `translations.yaml`, `v11.0/` (INDEX.md + forms/ + 5 entry-type
SCHEMAs), `v11.1/` (INDEX.md + forms/work-item.yml + phase-part-v11.1/SCHEMA.md).

**Excluded:** everything under `maintenance-docs/prison/`; the BD-195 workflow
artifacts (`PLAN-BD-195-*`, `AUDIT-BD-195-*`, `RESEARCH-BD-195-SEGMENT-*`).

---

## Coverage attestation

Every owned path read. Read-depth:
- **Full line-level:** the three `templates-archive/v11.1/` files; `v11.0/INDEX.md`,
  `README.md`, `translations.yaml`; `ARCHITECTURE-BD-185-V2.md` (§0–§11);
  `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0–§2; `PLAN-BD-185-V2.md` §0–§2
  + grep-walk §4–§10; `scripts/validate-pack.py` `check_issue_template_forms()` +
  `check_template_archive_v11()`; `scripts/tests/test-issue-forms.sh` v11.1-hit lines.
- **Header + targeted grep (version/anchor/cross-ref hits):** 6 BD-185 IMPL reports;
  `PACK-REVIEW-BD-185-H.1.md`/`-H.2.md`; `RESEARCH-BD-185-ORDERING-API.md`; BD-193/
  BD-194 corpus; 6 groupings docs. Grep keys: `v11.1`, `phase-part-v11.1`,
  `work-item-v11.1`, `frozen`, prisoned-doc names, archive-path forms.
- **Corroborating non-owned (fact-check only):** `AUDIT-BD-195-R7-PREREAD.md`
  (prior scoped R7 pre-read — NOT prisoned; cross-checked + independently
  re-verified); `pack-ops/BACKLOG.md` BD-185/BD-193 (cross-segment, PM-only);
  `v11.0/phase-task-v11.0/SCHEMA.md` (fictional-claim falsification).

Skimmed-with-reason: BD-185 IMPL reports + H.1/H.2 reviews grepped not deep-read —
tracked workflow artifacts whose contamination is the v11.1 framing + prisoned-doc
anchoring; targeted grep surfaces both deterministically (hit-counts in R7-F12).

## Findings count

BLOCKER 2 / MUST 4 / SHOULD 4 / NIT 2

---

## Findings

### R7-F01 — `v11.1/INDEX.md` is the densest physical contamination: false "v11.1 cut" premise + two FICTIONAL Convention-Y edits + rejected "frozen" lock
- Severity: BLOCKER
- Category: A (version) + B (boundary, version-framing) + E (fictional encoded claims)
- Surface(s): `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (title L1; L7–10; L12 "Entry types at v11.1"; L21 "NEW in v11.1" + `phase-part-v11.1` marker/label; L32–35; L42–51; L89–93; L95–107)
- Side: pack-self (maintenance-doc; archive surface)
- Evidence: L7 "The v11.1 archive cut introduces multi-part phase mid-work expansion…"; L32–35 "The v11.0 archive remains structurally frozen at 5 entry-type subdirs … per Convention Y (v11.0 structural shape freeze; USER-LOCKED 2026-05-26)."; L47–49 claims Convention Y "exercised twice" incl. a `status:cancelled` extension to `phase-task-v11.0/SCHEMA.md` and L50–51 a v11.0-INDEX "forward-reference footnote"; L89–93 "only `work-item-v11.0` bumps to `work-item-v11.1`".
- Why it's a problem: CATEGORICAL FACT — there is NO v11.1 cut; phase-parts is v11.0. The "frozen / Convention Y / USER-LOCKED" premise is rejected by `ARCHITECTURE-BD-185-V2.md` §11 CR-1 (v11.0 unshipped → archive mutable; BD-193 already mutated it). I independently FALSIFIED both Convention-Y "exercises": (1) `grep cancelled maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` → zero hits (no `status:cancelled` state exists); (2) `grep v11.1 …/v11.0/INDEX.md` → zero hits (no forward-reference footnote). The `work-item-v11.1` bump claim (L89–93) is internally contradicted by this archive's own form snapshot, which carries `work-item-v11.0` (see R7-F03). This doc both encodes the mislabel AND fabricates edits that never happened.
- Recommendation: Per `ARCHITECTURE-BD-185-V2.md` §10 Group B — retire this INDEX; fold the phase-part row into `templates-archive/v11.0/INDEX.md` with `phase-part-v11.0` tags. Remove the false Convention-Y claims, the "frozen at 5 subdirs / USER-LOCKED" framing, the `work-item-v11.1` bump claim, and the D1–D16 decision-log block (L95–107; superseded-corpus IDs). Do NOT preserve any of this content as live.
- Cross-segment touch points: `scripts/validate-pack.py` `check_template_archive_v11()` (R7-F05); `pack-ops/BACKLOG.md` stale path prose (R7-F11, PM-only segment); `PACK-REVIEW-BD-193-PHASE-4.md` blessed this INDEX (R7-F09).
- Confidence: high (two fictional claims falsified by direct grep; framing rejected by the V2 authority + categorical fact).

### R7-F02 — `phase-part-v11.1/SCHEMA.md` carries the `phase-part-v11.1` version tag throughout (grammar correct; version label wrong) and sits in the wrong directory
- Severity: MUST
- Category: A (version) + B (boundary, version-framing) + C (cross-ref paths once relocated)
- Surface(s): `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` (title L1; §2 marker `template_version: phase-part-v11.1` at L43 + L117; §3 label `template:phase-part-v11.1` at L69; prose at L1, L4, L43, L63, L186, L219; directory name `phase-part-v11.1/` + parent `v11.1/`)
- Side: pack-self (maintenance-doc; archive SCHEMA — but deliverable-constructing per `ARCHITECTURE-BD-185-V2.md` §8.1, so the project-side phase-part concept is ALLOWED here)
- Evidence: L1 "# Schema — `phase-part-v11.1` (phase part)"; L43 `<!-- template_version: phase-part-v11.1 -->`; L69 `| `template:phase-part-v11.1` | …`.
- Why it's a problem: CATEGORICAL FACT — a new entry type introduced in the in-development version takes that version's tag (`phase-part-v11.0`), not a nonexistent v11.1. `ARCHITECTURE-BD-185-V2.md` §2.B VERSION-TAG CARVE-OUT + §3 D-1 confirm the grammar substance (§1–§6, §8) is FIXED + user-approved and stays verbatim — ONLY the embedded version tag is contamination. The corrected location `v11.0/phase-part-v11.0/SCHEMA.md` does NOT yet exist in the working tree (verified: `ls v11.0/phase-part-v11.0/` → no such dir), so the contamination is the SOLE live home of the phase-part grammar.
- Recommendation: Per V2 §10 Group A — relocate to `…/v11.0/phase-part-v11.0/SCHEMA.md`; correct the version tag at every cited location; KEEP all grammar substance verbatim; fix the §5 sibling-SCHEMA cross-refs (`../v11.0/…` → `../…` once co-located). No script consumes the SCHEMA path (verified), so relocation has zero code-consumer blast radius.
- Cross-segment touch points: `v11.0/INDEX.md` (gains the row); the §5 prerequisite-grammar cross-refs to `../v11.0/phase-epic-v11.0/SCHEMA.md` and `../v11.0/phase-task-v11.0/SCHEMA.md` (L82–84, L127–149) shift on co-location.
- Confidence: high (version tag locations verified by direct read; correction enumerated by the V2 authority).

### R7-F03 — `v11.1/forms/work-item.yml` is a misplaced duplicate snapshot whose own markers (`work-item-v11.0`) contradict the v11.1 INDEX bump claim
- Severity: MUST
- Category: A (version, by placement) + E (internal-contradiction with sibling INDEX)
- Surface(s): `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` (label `template:work-item-v11.0` at L7; body marker `<!-- template_version: work-item-v11.0 -->` at L186; directory placement `v11.1/forms/`)
- Side: pack-self (maintenance-doc; archive form snapshot — client-facing/project-template shape)
- Evidence: L7 `  - template:work-item-v11.0`; L186 `        <!-- template_version: work-item-v11.0 -->`. The form is project-template-shaped (wi-type `td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton`, L25–28; no `bd`) — correct content, wrong location.
- Why it's a problem: The form's markers are accidentally CORRECT (`work-item-v11.0`), which directly refutes the sibling `v11.1/INDEX.md` L89–93 "bump to work-item-v11.1" claim — the contamination is incoherent on its own terms (`ARCHITECTURE-BD-185-V2.md` §2.C fact 2). The duplicate also collides with the existing `v11.0/forms/work-item.yml` (currently the 3-option post-BD-193 snapshot), violating single-source for the archived form. Placement under `v11.1/` is the version-framing error.
- Recommendation: Per V2 §10 Group C / D-9 — retire this duplicate; UPDATE the existing `v11.0/forms/work-item.yml` to the current 4-option project-template shape (incl. `phase-part-skeleton`); markers stay `work-item-v11.0`. Do NOT honor the bump claim.
- Cross-segment touch points: `v11.0/forms/work-item.yml` (the update target); `v11.1/INDEX.md` (the contradicted bump claim, R7-F01); `check_template_archive_v11()` byte-compare (R7-F05).
- Confidence: high (markers read directly; contradiction confirmed against sibling INDEX).

### R7-F04 — LIVE v11.1 mislabel encoded in shipped script `scripts/validate-pack.py` comments (LEAK, code-encoded)
- Severity: BLOCKER
- Category: A (version) + E (ENCODING lock-step) + B (deliverable-only framing)
- Surface(s): `scripts/validate-pack.py` `check_issue_template_forms()` docstring L1086; inline comment L1121–1123
- Side: pack-self (tracked, shipped pack script)
- Evidence: L1086 "The `phase-part-skeleton` option was added at v11.1 (BD-185 H.2)"; L1121–1123 "`phase-part-skeleton` was added at v11.1 (BD-185 H.2) as the 4th project-side entry type, representing the mid-work phase expansion 'Part' construct introduced at v11.1." (The functional dict `expected_wi_type_options_per_surface` at L1125–1128 is CORRECT.)
- Why it's a problem: CATEGORICAL FACT — phase-part-skeleton is a v11.0 project-side entry type; "added at v11.1 / introduced at v11.1" is the mislabel, now propagated into a tracked, CI-executing pack script (the highest-stakes surface in the epicenter — it is code, not a design doc). Per the pack-memory `enumerate ENCODING surfaces in audits` rule, a comment in an ENCODING surface asserting the wrong version is the LEAK (operational, code-encoded) verdict class. `ARCHITECTURE-BD-185-V2.md` §10 Group D enumerates this exact fix.
- Recommendation: Per V2 §10 Group D — replace "added at v11.1 (BD-185 H.2)" / "introduced at v11.1" with "added in v11.0 (BD-185)". No functional change. Because `scripts/` is touched, the commit MUST regenerate `test-fixtures/manifest.txt` (pack-memory `feedback_manifest_regen_on_v11_surface`) and run the per-check tests (`test-issue-forms.sh`, `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-43.sh`) per the PREFLIGHT gate.
- Cross-segment touch points: `scripts/tests/test-issue-forms.sh` (R7-F06; same lock-step unit); `test-fixtures/manifest.txt`; CI `validate-pack.yml`.
- Confidence: high (exact lines read; functional substance confirmed correct; V2 authority enumerates the fix).

### R7-F05 — `check_template_archive_v11()` enumerates only 5 entry types; missing `phase-part` (will be incomplete once the v11.0 cut gains the 6th type)
- Severity: SHOULD
- Category: E (ENCODING lock-step) + A (version-correctness dependency)
- Surface(s): `scripts/validate-pack.py` `check_template_archive_v11()` — entry-type loop at L1237; docstring L1215; `archive_root` at L1226
- Side: pack-self (tracked, shipped pack script)
- Evidence: L1237 `for entry_type in ("bd", "td", "phase-epic", "phase-task", "inbound"):` (5 types); L1215 docstring lists the same 5; L1226 `archive_root = REPO_ROOT / "maintenance-docs" / "v11-research" / "templates-archive" / "v11.0"`.
- Why it's a problem: Once the phase-part SCHEMA relocates into the v11.0 cut (R7-F02), this check must verify `v11.0/phase-part-v11.0/SCHEMA.md` exists — otherwise the human-readable archive report is incomplete and the new entry type is unchecked. The check is INFO/soft-style (won't hard-fail CI) so this is SHOULD, not BLOCKER, but it is an ENCODING surface that must move in lock-step with the archive (`ARCHITECTURE-BD-185-V2.md` §10 Group E). NOTE: L1226 already encodes the REAL archive path (`maintenance-docs/v11-research/templates-archive/v11.0`) — this is the authority refuting the bare-path imprecision in R7-F07.
- Recommendation: Per V2 §10 Group E — add `"phase-part"` to the L1237 loop (6 types); update the L1215 docstring; function name + `v11.0` target stay correct. Manifest regen + per-check tests apply (R7-F04).
- Cross-segment touch points: `v11.0/phase-part-v11.0/SCHEMA.md` (relocation target, R7-F02); `test-fixtures/manifest.txt`.
- Confidence: high (loop + docstring read directly).

### R7-F06 — LIVE v11.1 mislabel encoded in shipped test `scripts/tests/test-issue-forms.sh` comments (LEAK, test-encoded)
- Severity: MUST
- Category: A (version) + E (ENCODING lock-step, test-encoded)
- Surface(s): `scripts/tests/test-issue-forms.sh` comments at L18–19, L94–95, L138–139, L161–162, L180, L264–265
- Side: pack-self (tracked, shipped test)
- Evidence: L18–19 "…option and `wi-part-letter` field were / added at v11.1 (BD-185 H.2)…"; L94–95 "…was added / at v11.1 (BD-185 H.2)…"; L138–139 "`phase-part-skeleton` / added to the forbidden list at v11.1 (BD-185 H.2)"; L161–162, L180, L264–265 carry the same framing. (The assertions themselves — per-surface options, `wi-part-letter` presence/absence, Part-id Blockers grammar, DISJOINT, `work-item-v11.0` marker — are CORRECT.)
- Why it's a problem: Same LEAK-test-encoded class as R7-F04. The pack-memory `enumerate ENCODING surfaces` rule was written precisely to prevent walking the validator but not its test (asymmetric coverage). `ARCHITECTURE-BD-185-V2.md` §10 Group F enumerates this; it is the same lock-step unit as the validator (PLAN-BD-185-V2 SZ-5 groups D+E+F+G together).
- Recommendation: Per V2 §10 Group F — replace the "added at v11.1 (BD-185 H.2)" framing with "added in v11.0 (BD-185)" at all six comment sites. No functional change. Lock-step with R7-F04/F05; manifest regen + per-check test runs apply.
- Cross-segment touch points: `scripts/validate-pack.py` (R7-F04/F05); `test-fixtures/manifest.txt`; CI.
- Confidence: high (exact comment lines read; assertions confirmed correct).

### R7-F07 — `ARCHITECTURE-BD-185-V2.md` §10 and `PLAN-BD-185-V2.md` commit recipes cite BARE `templates-archive/v11.1/...` paths that drop the `maintenance-docs/v11-research/` prefix
- Severity: SHOULD
- Category: C (cross-reference path-precision; filename/path-uniqueness posture)
- Surface(s): `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` §10 Groups A–C (e.g., "From: `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` To: `templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`"); `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md` §6 commit recipes (e.g., L214–215, L227–228) and §10 commit-A table (L820–822)
- Side: maintenance-doc (the active corrected design + plan)
- Evidence: V2 §10 Group A "From: `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`"; PLAN-V2 L214 "RELOCATE `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` →". There is NO repo-root `templates-archive/` — the only one is nested under `maintenance-docs/v11-research/` (verified). Mitigation: PLAN-V2 §2 file-inventory table (L129–137) DOES use the full path, and `scripts/validate-pack.py:1226` encodes the full path — so the canonical location is unambiguous; only the prose shorthand is imprecise.
- Why it's a problem: A coder executing a §10 correction or a PLAN-V2 §6 recipe against a literal `templates-archive/...` path would fail (no such dir at root). Collides with the pack-memory filename/path-uniqueness posture (prose references should resolve to a real path). Not a BLOCKER because the PLAN §2 inventory + the validator both carry the correct full path, so the ambiguity is recoverable — but the recipes a coder follows step-by-step are the bare form.
- Recommendation: Before any coder executes the §10 / PLAN-V2 §6 corrections, normalize the bare `templates-archive/...` citations to full `maintenance-docs/v11-research/templates-archive/...` paths in the recipe prose (or add a one-line "all archive paths are relative to `maintenance-docs/v11-research/`" preamble). Confirm the canonical archive location is nested (validator says nested) — do NOT silently relocate the archive to repo root without a separate scoping decision.
- Cross-segment touch points: `scripts/validate-pack.py:1226` (the path authority); PLAN-V2 §2 inventory (the correct-path counter-example).
- Confidence: high (no repo-root archive confirmed by find/ls; both bare and full forms quoted).

### R7-F08 — `ARCHITECTURE-BD-185-V2.md` carries NO forward "superseded-by ordering addendum" pointer; a reader of V2 §5.1/D-8 alone would treat the demoted Issue-Fields-primary design as live
- Severity: SHOULD
- Category: C (cross-reference) + E (lock-step between V2 and its addendum)
- Surface(s): `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` header L1–6, §0 supersession notice L9–54, §5.1 L550+, §3 D-8 L375–387, §7 ordering-ops table L722–735
- Side: maintenance-doc (active corrected design)
- Evidence: `grep -n "ORDERING-ADDENDUM\|superseded by" ARCHITECTURE-BD-185-V2.md` → zero hits. V2 §5.1 still presents "GitHub primary path: Issue Fields `Execution Order` (number)" and D-8 (L375) "Issue Fields is the GitHub primary path" as live. The addendum (`ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0.1 table) DEMOTES Issue Fields to gated-OFF and PROMOTES sub-issue-reprioritize to the v11.0 GitHub default — but the supersession pointer exists ONLY in the addendum (backward), not in V2 (forward).
- Why it's a problem: The supersession is one-directional. A reader who opens V2 first (the "Authoritative. Standalone." doc) and reads §5.1/D-8 has no in-doc signal that the ordering subsystem is superseded. This is the exact lock-step-between-paired-docs gap that produces stale-design execution. `PLAN-BD-185-V2.md` §0.1 (L29–33) DOES carry the correct "addendum wins for ordering; V2 wins for all else" reconciliation, so the plan is safe — but V2 read in isolation is not.
- Recommendation: Add a forward pointer to V2 — either in the header status line or a one-paragraph §0 note: "The tracker-mode execution-ordering subsystem (§5.1/§5.2, D-7 mechanism clause, D-8, §7 ordering ops, §6 ordering reads/writes) is SUPERSEDED by `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0.1; that addendum wins for ordering, this doc for all else." This is a held untracked design doc, so it can be corrected before BD-185 restart.
- Cross-segment touch points: `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` (the superseding doc); `PLAN-BD-185-V2.md` §0.1 (the correct reconciliation).
- Confidence: high (grep confirms no forward pointer; addendum §0.1 confirms the supersession direction).

### R7-F09 — BD-193 review + Phase-5 remediation BLESSED and DEEPENED the v11.1 mislabel (propagation; correction targets)
- Severity: MUST
- Category: A (version) + B (boundary) + process-failure signal
- Surface(s): `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md` §3.1.2 + §4.7 M-5; `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` §4 S-1
- Side: maintenance-doc (workflow artifacts of a COMPLETED Code-Red-2 BD)
- Evidence: PACK-REVIEW-BD-193-PHASE-4 §3.1.2 graded the v11.1 INDEX heading "## Entry types at v11.1" + the "new phase-part-v11.1" row CONFIRMED-CORRECT; §4.7 M-5 recommended "actually create the v11.1 archive forms directory + form file (a v11.1 archive cut decision the user makes)"; IMPLEMENTATION-REPORT-BD-193-PHASE-5 §4 S-1 rewrote the v11.1 INDEX forms paragraph to "the v11.1 forms/ subdirectory will be populated when the v11.1 archive cut is completed (architect-pass decision pending)."
- Why it's a problem: CATEGORICAL FACT — both passes treated the nonexistent "v11.1 archive cut" as a legitimate future deliverable, BLESSING (review) and DEEPENING (remediation) the mislabel during Code Red 2 instead of catching it. The Phase-5 S-1 INDEX edits are now themselves correction targets under `ARCHITECTURE-BD-185-V2.md` §10 Group B. For the BD-195 "pristine v11.0" goal this confirms the contamination was reinforced AFTER introduction. BD-193's IN-SCOPE work (the per-surface wi-type split, the `bd`-removal carve-out fact) is correct and retained — only the v11.1 framing it propagated is the issue.
- Recommendation: When the V2 §10 corrections land, ensure the Phase-5 S-1 INDEX language and the Phase-4 §3.1.2 "CONFIRMED-CORRECT" verdict are explicitly reversed (the source they blessed — `v11.1/INDEX.md` — is retired per R7-F01). As workflow artifacts these two docs sweep to archive (Pattern B) and may be left as historical record of the propagation, but the BD-195 recovery should record this as a missed-finding so the review process learns the v11.0/v11.1 categorical check.
- Cross-segment touch points: `v11.1/INDEX.md` (the blessed surface, R7-F01); the BD-195 recovery missed-finding ledger.
- Confidence: high (verdicts + rewritten language confirmed by the pre-read citations + grep; categorical-fact application is direct).

### R7-F10 — `PACK-REVIEW-BD-185-H.2.md` is UNTRACKED and anchors its review spec to the now-PRISONED `PLAN-BD-185-ADDENDUM.md`; it cites v11.1 archive paths as the legitimate spec location
- Severity: MUST
- Category: C (stale-ref to prisoned doc) + A (cites contaminated v11.1 paths without flagging them)
- Surface(s): `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md` §1 L5–7; finding/encoding-surface citations at L94, L96, L221, L224, L227, L254–255, L348
- Side: maintenance-doc (UNTRACKED workflow artifact)
- Evidence: L5–7 "INLINE per-BD review of H.2 … against the user-locked spec in `PLAN-BD-185-ADDENDUM.md` §4.2." `PLAN-BD-185-ADDENDUM.md` is now under `maintenance-docs/prison/` (verified — not in `v11-implementation/`). L254–255 lists `templates-archive/v11.1/forms/work-item.yml` + `…/v11.1/INDEX.md` as ENCODING surfaces NEW/EDITED ✓ (treats the contaminated paths as the correct spec location); L94 reproduces "introduced at v11.1" framing.
- Why it's a problem: (1) The review's spec anchor (`PLAN-BD-185-ADDENDUM.md` §4.2) is a now-prisoned/superseded doc (`PLAN-BD-185-V2.md` §0 supersedes it; the prison rule marks it IGNORED) — a stale-ref-to-prisoned finding. (2) The review treats the `v11.1/` archive paths as the legitimate spec location and reproduces the v11.1 framing without flagging the mislabel — it propagated rather than caught it (same class as R7-F09). (3) It is UNTRACKED (`git status` → `??`), so it has no committed provenance, and a same-named TRACKED variant may exist — provenance ambiguity. The H.2 FUNCTIONAL verdicts (pack-root `{bd}`-only, DISJOINT, `work-item-v11.0` markers) match what V2 §2.C confirms correct, so the verdicts are not wrong — but the anchor and framing are.
- Recommendation: The supersession-map pass owns this doc's disposition (track vs prison vs leave). I flag: it is untracked, anchored to a prisoned plan, and propagates the v11.1 framing. If retained as a historical artifact, it sweeps to archive (Pattern B); it should NOT be treated as a live spec or a clean review.
- Cross-segment touch points: `maintenance-docs/prison/PLAN-BD-185-ADDENDUM.md` (the prisoned anchor — do not read/cite); the supersession-map segment (disposition owner); any tracked same-named variant.
- Confidence: high (untracked status + prisoned anchor verified; v11.1 citations read).

### R7-F11 — `PACK-REVIEW-BD-185-H.1.md` blesses the v11.1 mislabel as the established design and anchors to two now-PRISONED docs
- Severity: SHOULD
- Category: C (stale-ref to prisoned docs) + A (blesses v11.1 framing)
- Surface(s): `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.1.md` pipeline header L8–9; §1 L17–19; §3.1 L79; §3.2 L158–167, L195; NIT table L270–272
- Side: maintenance-doc (tracked workflow artifact)
- Evidence: L8–9 "Pipeline: docs-researcher → architect (ARCHITECTURE-BD-185.md; USER-LOCKED) → planner (PLAN-BD-185.md)" — BOTH now prisoned (verified in `maintenance-docs/prison/`). L17–19 "covers BD-185 Batch 19d.H.1 — the v11.1 templates-archive cut establishing the new `phase-part-v11.1` entry type schema and `v11.1/INDEX.md` enumeration." L195 references the "template_version: work-item-v11.1" bump as expected. The review treats the entire v11.1 cut as the correct deliverable under review.
- Why it's a problem: Anchors to `ARCHITECTURE-BD-185.md` + `PLAN-BD-185.md` (now prisoned/superseded) = stale-ref-to-prisoned. Affirms "the v11.1 templates-archive cut … the new `phase-part-v11.1` entry type" as correct = same propagation class as R7-F09/F10 (this review BLESSED H.1's v11.1 framing rather than catching it). SHOULD rather than MUST because it is a completed historical review whose disposition is Pattern-B archive (it does not gate anything live), but it is a clear instance the audit must record.
- Recommendation: Record as a propagation instance for the BD-195 missed-finding ledger; leave as historical record (Pattern-B archive sweep). Do NOT treat its CONFIRMED-CORRECT verdicts on the v11.1 framing as authoritative. Its NIT-1/NIT-2 (stale architect-doc cites in the SCHEMA) overlap the R7-F02 cross-ref cleanup.
- Cross-segment touch points: `maintenance-docs/prison/ARCHITECTURE-BD-185.md` + `PLAN-BD-185.md` (prisoned anchors — do not read/cite); R7-F02 (SCHEMA cross-ref NITs); BD-195 missed-finding ledger.
- Confidence: high (prisoned-doc anchors + v11.1 affirmations read directly).

### R7-F12 — All 6 BD-185 IMPL reports carry the v11.1 mislabel framing (8–38 hits each) and 5 of 6 reference now-PRISONED docs (9–24 refs each)
- Severity: SHOULD
- Category: A (version) + C (stale-ref to prisoned docs)
- Surface(s): `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md` (38 v11.1 / 19 prisoned-refs), `-Batch-19d-H.2.md` (22 / 13), `-H.1-NITS.md` (21 / 0), `-POST-PLANNER-POQS.md` (26 / 24), `-ARCHITECT-DOC-EDITS.md` (8 / 9), `-ARCHITECT-DOC-REVIEW-FIXES.md` (2 / 22)
- Side: maintenance-doc (tracked workflow artifacts)
- Evidence: per-file `grep -c "v11.1\|phase-part-v11.1\|work-item-v11.1"` and `grep -c "ARCHITECTURE-BD-185.md\|PLAN-BD-185.md\|PLAN-BD-185-ADDENDUM\|RECONCILIATION"` hit-counts (recorded above). The prisoned-doc refs point at `ARCHITECTURE-BD-185.md`, `PLAN-BD-185.md`, `PLAN-BD-185-ADDENDUM.md`, `ARCHITECTURE-BD-185-RECONCILIATION.md` — all now under `maintenance-docs/prison/`.
- Why it's a problem: These reports document the contaminated BD-185 attempt; their v11.1 framing is the mislabel and their prisoned-doc references are stale-refs. Per `ARCHITECTURE-BD-185-V2.md` §10 Group H, these are Pattern-B archive-sweep workflow artifacts — a historical record of "what was done, including the error." So the disposition is likely "leave as historical, sweep at version ship," NOT edit. But they ARE in my owned-path manifest and carry the contamination, so I surface them as a group; the BD-195 recovery decides whether the v11.0 "pristine post-Batch-19c state" goal requires these to move to prison/archive rather than remain in `v11-implementation/`.
- Recommendation: Treat as a group: confirm Pattern-B disposition (archive-sweep, not edit) with the user. If the BD-195 "pristine" bar requires the active `v11-implementation/` tree to be free of contaminated attempt-records, move them to `maintenance-docs/archive/v11/` (or prison if deemed contaminated-superseded) per the supersession-map pass. Do NOT individually de-contaminate prose in archived workflow artifacts (rewriting history loses the audit trail).
- Cross-segment touch points: the supersession-map segment (disposition owner); prison docs they reference (do not read/cite); BD-195 "pristine state" definition.
- Confidence: high (hit-counts deterministic; prison membership of referenced docs verified).

### R7-F13 — `v11.0/INDEX.md` "Frozen forms" heading + bare "D16" cite carry the now-rejected "frozen" framing (substance correct; framing stale)
- Severity: NIT
- Category: A (version-framing) + C (bare decision-ID cite)
- Surface(s): `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` "Frozen forms" heading (L26); L33–34 "the original v11.0 shipped form admitted a 4th `bd` option; D16 removed it from the archive as a bug-fix carve-out."
- Side: pack-self (maintenance-doc; archive INDEX — the CORRECT v11.0 cut)
- Evidence: L26 "## Frozen forms"; L33 "(3-option `wi-type` dropdown per V3.3 §6.1 + BD-193 D16 carve-out)"; L34 "D16 removed it from the archive as a bug-fix carve-out."
- Why it's a problem: The carve-out FACT (BD-193 removed the stray `bd` option) is correct and retained per `ARCHITECTURE-BD-185-V2.md` §3 D-3 / §10 Group G. BUT "Frozen forms" + the bare "D16" cite reference the rejected "v11.0 structural shape frozen / Convention Y" framing (V2 CR-1) — D16 is a superseded-corpus decision ID with no live home, and "frozen" is the categorically-wrong word for an unshipped cut. The bare "D16" also violates the filename/uniqueness-spirit (a bare decision-ID the reader cannot resolve to a live doc — the live decision log is V2 §3).
- Recommendation: Per V2 §10 Group G (optional polish) — reword "Frozen forms" → "Archived forms"; replace the bare "D16" cite with "BD-193 bug-fix carve-out"; KEEP the carve-out fact. Cosmetic; no CI impact; surface to user rather than auto-apply.
- Cross-segment touch points: `v11.1/INDEX.md` D16 block (R7-F01, retired); V2 §3 D-3 (the live decision).
- Confidence: high (lines read; V2 Group G enumerates the optional reword).

### R7-F14 — `INTAKE-GROUPINGS-V11.md` self-flags unverified fidelity ("FAITHFUL SUMMARY — NOT VERBATIM"); quality caveat, not contamination
- Severity: NIT
- Category: quality caveat (not a version/boundary leak)
- Surface(s): `maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md` header (~L5); subordination note (~L25)
- Side: maintenance-doc (legitimate v11.1+ groupings input)
- Evidence: header "FAITHFUL SUMMARY — NOT VERBATIM … User should review for accuracy before treating as audit-grade record."; L25 "If this intake doc conflicts with REQUIREMENTS-GROUPINGS-V11.md, the REQUIREMENTS doc wins."
- Why it's a problem: Not a contamination — its v11.1+ framing is the LEGITIMATE user-authorized groupings deferral (REQUIREMENTS-GROUPINGS-V11.md L22, L24; corroborated by `translations.yaml` documenting v11.0 as not-yet-shipped and v11.1 as future). The only note is the self-declared unverified fidelity: it is a retroactive 2026-05-24 reconstruction subordinate to REQUIREMENTS. The user may want to confirm fidelity before relying on it as audit-grade for the BD-195 recovery.
- Recommendation: Optional — user may review INTAKE for fidelity, or rely on REQUIREMENTS (the canonical artifact) and treat INTAKE as audit-trail only. No version/boundary correction needed.
- Cross-segment touch points: `REQUIREMENTS-GROUPINGS-V11.md` (the canonical artifact that wins on conflict).
- Confidence: high (self-flag read; v11.1 framing confirmed legitimate against the categorical-fact exception).

---

## Coverage map

| Owned path | Verdict |
|---|---|
| `templates-archive/v11.1/INDEX.md` | R7-F01 (BLOCKER) |
| `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | R7-F02 (MUST) |
| `templates-archive/v11.1/forms/work-item.yml` | R7-F03 (MUST) |
| `scripts/validate-pack.py` (epicenter-encoded comments) | R7-F04 (BLOCKER) + R7-F05 (SHOULD) |
| `scripts/tests/test-issue-forms.sh` (epicenter-encoded comments) | R7-F06 (MUST) |
| `ARCHITECTURE-BD-185-V2.md` | R7-F07 (SHOULD, §10 bare paths) + R7-F08 (SHOULD, no forward addendum pointer); otherwise CLEAN (correctly applies categorical fact; de-contamination authority) |
| `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` | clean (correct supersession of V2 ordering subsystem; v11.0-framed) |
| `PLAN-BD-185-V2.md` | R7-F07 (SHOULD, §6 recipe bare paths); §0–§2 clean (binding contamination guardrail; correct addendum reconciliation) |
| `RESEARCH-BD-185-ORDERING-API.md` | clean (no v11.1 mislabel; no prisoned-doc refs; trusted external fact base) |
| `PACK-REVIEW-BD-185-H.2.md` | R7-F10 (MUST) |
| `PACK-REVIEW-BD-185-H.1.md` | R7-F11 (SHOULD) |
| 6× `IMPLEMENTATION-REPORT-BD-185-*` | R7-F12 (SHOULD, group) |
| `BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md` | clean (no v11.1 mislabel; spent process-historical prompt) |
| `ARCHITECTURE-BD-194.md`, `PLAN-BD-194.md`, `PACK-REVIEW-BD-194.md`, `IMPLEMENTATION-REPORT-BD-194*.md` (3) | clean (Code Red 2 completed-correct; the only v11.1 hits are CORRECT applications of "land in v11.0; do not defer" — not mislabels) |
| `IMPLEMENTATION-REPORT-BD-193.md` | clean (in-scope cleanup correct; explicitly left BD-185 v11.1 framing out of its scope) |
| `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` | R7-F09 (MUST, propagation) |
| `PACK-REVIEW-BD-193-PHASE-4.md` | R7-F09 (MUST, propagation) |
| `templates-archive/v11.0/INDEX.md` | R7-F13 (NIT) |
| `templates-archive/v11.0/` 5 entry-type SCHEMAs + forms/ | clean (correct v11.0 cut; phase-part-v11.0 subdir not yet created — pending R7-F02 relocation) |
| `templates-archive/README.md` | clean (archive contract; "append-only after a release tag" is the rule the categorical fact rests on) |
| `templates-archive/translations.yaml` | clean (empty `[]`; documents v11.0 not-yet-shipped + v11.1 future — corroborates categorical fact) |
| `REQUIREMENTS-GROUPINGS-V11.md`, `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`, `RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`, 2× groupings IMPL-reports | clean (legitimate user-authorized v11.1+ deferral — NOT the phase-parts mislabel) |
| `INTAKE-GROUPINGS-V11.md` | R7-F14 (NIT, quality caveat only) |

---

## Cross-segment notes (not my owned paths; flagged for the owning segment)

- `pack-ops/BACKLOG.md` (PM-only; another segment) carries stale `templates-archive/v11.1/...` path prose at L3020, L3025, L3072 (BD-185 Unblocks/File-Symbol/Position + BD-193 Resolved-line). `ARCHITECTURE-BD-185-V2.md` §10 Group H flags these for Pack-Chat reconciliation when the correction lands. Not edited here (PM-only + cross-segment).
- The prior scoped pre-read `AUDIT-BD-195-R7-PREREAD.md` (NOT prisoned) reached the same epicenter conclusions; this pass independently re-verified its leads (notably falsifying the two fictional Convention-Y claims and confirming the live code-encoded contamination) and goes deeper at exact line/symbol level.
