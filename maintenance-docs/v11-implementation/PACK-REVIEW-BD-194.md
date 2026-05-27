# PACK-REVIEW-BD-194.md — Check 24 byte-identity gate replacement (reviewer audit pass)

Status: REVIEWER DELIVERABLE — read-only audit at HEAD `4ef6c02`.
HEAD SHA: `4ef6c02c84797ed151cffad94ca326723e6b7ff7`.
Author: pack-reviewer; produced 2026-05-27 per BD-194 pipeline.
Read-only against working tree; no source modified; no state-changing git verbs run.

Audit anchors:
- Architect deliverable: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (1179 lines; Candidate 6 user-approved)
- Planner deliverable: `maintenance-docs/v11-implementation/PLAN-BD-194.md` (946 lines; single-commit plan user-approved)
- Main coder deliverable: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md` (980 lines)
- Fix-coder deliverable: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` (442 lines)
- BD entry: `pack-ops/BACKLOG.md:3076-3124` (BD-194 Open at HEAD)
- Commit: `4ef6c02` "fix: v11 — BD-194 Check 24 byte-identity gate replacement" (14 files, +3637 / -74)

---

## §1 Scope

This review audits the BD-194 commit against the user-locked design (Candidate 6
+ 3 architect POQs + 2 planner POQs + 2 Pack Chat triage decisions) per the
three orthogonal review questions specified in the calling prompt:

- **Q1.** Was the implementation successful? (per-row coverage check against
  architect + planner + Pack Chat decisions)
- **Q2.** Are there remaining in-scope issues? (stale references, missed
  surfaces)
- **Q3.** Are there regressions? (separation discipline, trinity parity,
  manifest correctness, CI gate correctness, downstream check dependencies)

All findings are evidence-based with file:line citations against the live source
at HEAD `4ef6c02`, not against the IMPL-REPORTs.

---

## §2 Methodology

Per the `review` skill priorities (priority 0 = boundary discipline; priority 3 =
regressions), `architecture-review` skill methodology, and the `boundary-
investigation` skill (Step 4 deny-list + frame-rotation reminder).

User-locked decisions are NOT re-litigated per the calling prompt: Candidate 6,
all 3 architect POQs (Check 22 scope, README same-commit, allowlist text),
all 2 planner POQs (trinity Option A, drop-clause Sub-option A), and Pack Chat
triage on the 2 stale-ref fixes are treated as settled. The audit verifies
APPLICATION CORRECTNESS, not re-decision.

### §2.1 Disposition categories

- **CONFIRMED-CORRECT** — implementation matches design; no remediation needed.
- **REMEDIATION-NEEDED-MUST** — concrete defect requiring fix before commit
  ships to production (CI failure, broken contract, security issue).
- **REMEDIATION-NEEDED-SHOULD** — improvement that would strengthen the cleanup
  but is not blocking.
- **REMEDIATION-NEEDED-NIT** — cosmetic improvement.
- **AMBIGUOUS** — needs user discussion before disposition.

### §2.2 Frame rotation

Per `boundary-investigation` skill: this BD touches BOTH pack-side
(`scripts/validate-pack.py`, `pack-root` trinity, `README.md` version table) and
project-side (`project-template/skills/boundary-investigation/SKILL.md`)
surfaces. Findings are explicitly tagged with their surface and the relevant
SSOT cited from that surface.

---

## §3 Q1 — Implementation success verification

### §3.1 Check 24 retirement (function + callsite + comment + grep purge)

**Verification.**

- **Function removed.** `scripts/validate-pack.py:2178-2185` carries a 6-line
  retirement-comment block in the location where the function previously lived
  (architect §5.1 + IMPL-REPORT §3.1). No `def check_help_fragment_tracker_byte_identity`
  function declaration remains anywhere in the file (`grep -n
  "check_help_fragment_tracker_byte_identity"` returns only the single L6081
  retirement comment).
- **Callsite removed.** `scripts/validate-pack.py:6079-6081` carries the
  callsite-removal retirement comment between `check_help_fragment_completeness()`
  (Check 23) and `check_customization_detection_regression_guard()` (Check 25).
  No live invocation of the retired function remains.
- **Check-list comment retirement.** `scripts/validate-pack.py:62-68` replaces
  the previous 3-line Check 24 entry with the architect §5.4 step 3 drafted
  retirement-note text (6 lines naming the architect doc + pack-memory anchor
  + per-surface successor invariants).
- **Identifier purge.** `grep -n "check_help_fragment_tracker_byte_identity\|byte-identity\|Check 24" scripts/validate-pack.py`
  returns 5 retirement / audit-trail prose occurrences only:
  L63 (check-list comment retirement), L68 (check-list comment retirement),
  L2178 (function-deletion placeholder block), L4778 (allowlist comment
  explaining what was retired), L6079 (callsite-removal block), L6081
  (callsite-removal block). All 5 are INTENTIONAL per architect §5.4 +
  IMPL-REPORT §9.2 + planner G2 audit-trail prose exception.
- **Validate-pack.py PASS.** `python3 scripts/validate-pack.py` runs to
  `PASSED — all checks clean` with Check 24 absent from the output (verified
  via `grep -E "^── Check 24"` returning empty).

**Disposition.** CONFIRMED-CORRECT.

### §3.2 Check 23 fail-loud modification

**Verification.**

- **Behavior change.** `scripts/validate-pack.py:1991-2000` replaces the
  pre-BD-194 silent `if tracker_fragment.is_file():` fallback with a
  `if not tracker_fragment.is_file(): fail() return` fail-loud branch.
- **Docstring addendum.** `scripts/validate-pack.py:1985-1989` carries the
  BD-194 docstring attribution per IMPL-REPORT §4.2 (5-line addendum naming the
  BD-194 architect doc + the surface-local invariant rationale + the Check 41
  cross-reference).
- **Concatenation simplified.** L2000 now reads `text = fragment.read_text() +
  "\n" + tracker_fragment.read_text()` (no `if`-guard; the function returns
  early if either file is missing).
- **Validate-pack.py PASS.** Check 23 PASSes at HEAD per validate-pack run.

**Disposition.** CONFIRMED-CORRECT.

### §3.3 Check 22 per-surface fix

**Verification.**

- **`surfaces` dict modification.** `scripts/validate-pack.py:1897-1917` adds
  per-surface `tracker_fragment` keys: `pack-root` → `pack-ops/HELP-FRAGMENT-
  TRACKER.md` (L1907); `project-template` → `project-template/docs/pack/HELP-
  FRAGMENT-TRACKER.md` (L1915). Matches architect §5.1 implementation sketch
  + IMPL-REPORT §5.2.
- **Per-surface fragment lookup.** L1920-1931 iterates each surface, retrieves
  `cfg["tracker_fragment"]`, fails-loud if either fragment is missing
  (L1923-1929: existence checks for `frag` + `tracker_frag`), then concatenates
  ONLY the per-surface tracker fragment at L1931 (`frag_text = frag.read_text()
  + "\n" + tracker_frag.read_text()`).
- **No cross-surface concatenation.** The pre-BD-194 single-source
  `tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"`
  constant (formerly at the function head) is GONE — each surface independently
  derives its fragment path from the dict.
- **Docstring addendum.** L1887-1891 carries the BD-194 attribution per
  IMPL-REPORT §5.3 item 1.
- **Dict-block leading comment.** L1894-1896 carries the BD-194
  per-surface explanation per IMPL-REPORT §5.3 item 2.
- **Smoke test confirmed.** IMPL-REPORT §9.5 documents the local divergence
  smoke test (add `<!-- BD-194 smoke -->` to pack-side; validate-pack PASSES;
  revert). I did NOT re-run this in the review pass per read-only mandate, but
  the verification narrative is sound: the per-surface dict means pack-side
  divergence does not affect project-template's verb-presence comparison.

**Disposition.** CONFIRMED-CORRECT. The latent Check 22 bug surfaced by
architect §2.6.1 item 1 is correctly fixed.

### §3.4 Allowlist comment updates

Per architect §5.2 + planner §2.1 step 4, two in-scope allowlist locations need
their rationale text updated.

**Verification of L4762-4782 (`_BARE_REFERENCE_EXEMPTIONS` HELP-FRAGMENT.md entry).**

- Live state: L4772-L4781 is the prefatory comment block; L4782 is the actual
  dict-value rationale string for the `"HELP-FRAGMENT.md"` key.
- Prefatory comment (L4772-L4781) replaces pre-BD-194 byte-identical-mirror
  framing with: "Per BD-194 the pack-side and project-side HELP-FRAGMENT-
  TRACKER.md files are SEPARATE artifacts with SEPARATE audiences
  (feedback_pack_project_separation_of_concerns, user-locked 2026-05-26); the
  previous 'byte-identical mirror' rationale is retired with Check 24."
- Dict-value rationale (L4782): `"Project-side mirror exception; resolves at
  client-installed location (see Check 41 _CLIENT_INSTALLED_FILES)"`. Matches
  architect §5.2 drafted text.

**Verification of L5138 (`_CHECK_43_ALLOWLIST` HELP-FRAGMENT-TRACKER.md entry).**

- Live state: `"HELP-FRAGMENT-TRACKER.md": "Project-side docs/pack/HELP-FRAGMENT-
  TRACKER.md (client-installed; per-surface authoritative per BD-193 F4/F5 +
  BD-194)"`. Matches architect §5.2 drafted text.

**Verification of forbidden-phrase purge.**

- `grep -n "byte-identical mirror per Check 24\|Byte-identical mirror exception"
  scripts/validate-pack.py` returns empty. The forbidden ACTIVE-rationale
  phrases are PURGED. Only L4777 contains "byte-identical mirror" in
  past-tense quotation context inside a comment explaining what was retired —
  intentional audit-trail.

**Disposition.** CONFIRMED-CORRECT.

### §3.5 Test file updates

Per IMPL-REPORT §7 (deviation from architect/planner scope; surfaced as
planner-discovery-class finding).

**Verification of `scripts/tests/test-init-project.sh:181-191` (test 3.3).**

- Pre-BD-194: test asserted `cmp -s` between `$REPO_ROOT/pack-ops/HELP-FRAGMENT-
  TRACKER.md` and the client install. Post-BD-194: asserts `cmp -s` between
  `$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` and the
  client install. Per IMPL-REPORT §7.3, post-BD-193 F4/F5 contract.
- Comment block L181-186 attributes the change to "BD-193 F4/F5 + BD-194",
  cites the pack-memory anchor `feedback_pack_project_separation_of_concerns`,
  and explicitly notes pack-side is NOT the install source.
- t_pass / t_fail messages updated to reflect the new invariant
  ("matches project-template-side install source (BD-193 F4/F5)" /
  "install-source mismatch (expected: project-template/docs/pack/HELP-FRAGMENT-
  TRACKER.md)").

**Verification of `scripts/tests/test-migrate-v10-to-v11.sh:151-160` (test 2.5).**

- Same shape of edit; same attribution; same invariant. `cmp -s` now compares
  client install against `$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT-
  TRACKER.md` (was `$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md`).
- Migrator S5 install-source contract per BD-193 F4/F5 correctly reflected.

**Syntactic validity.**

- `bash -n scripts/tests/test-init-project.sh && bash -n scripts/tests/test-
  migrate-v10-to-v11.sh` returns clean.

**Coder pass deviation.** The coder pass authorized the test edits under the
spawn prompt's "scripts/tests/ test files (if applicable): identify any test
file that exercises Check 22/23/24" instruction. The edits ALIGN with the
architectural correction (separation of concerns) and the BD-193 F4/F5
install-source contract. Reviewer disposition: legitimate in-scope work that
was NOT pre-enumerated in the architect/planner docs but was correctly
identified during coder pass.

**Disposition.** CONFIRMED-CORRECT.

### §3.6 Stale-ref follow-on fixes

Per IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md §3 + §4, Pack Chat triage user-
disposed both follow-on fixes for inline-bundling into the BD-194 commit.

**Verification of `scripts/init-project.sh:809-813` (Fix 1).**

- Pre-fix (per IMPL-REPORT-STALE-REFS §3): 6-line comment referring to
  "byte-identity-required across pack-root and client mirror per DELTA L1
  (validate-pack Check 24); force-copy from pack-root canonical".
- Post-fix (L809-813): 5-line comment "HELP-FRAGMENT-TRACKER.md install path:
  see the comment block below for the project-template-side source-of-truth
  contract (post-BD-193 F4/F5; pack-side substitution is forbidden)."
- The downstream L819-823 comment block (untouched) already carries the full
  contract narrative. No duplication.

**Verification of `project-template/skills/boundary-investigation/SKILL.md:105-106` (Fix 2).**

- Pre-fix (per IMPL-REPORT-STALE-REFS §4): 4-line block "HELP-FRAGMENT-TRACKER.md
  (bare-filename refs from project-side; the pack-ops copy lives at
  `pack-ops/HELP-FRAGMENT-TRACKER.md` per CI Check 24 byte-identity contract
  with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),"
- Post-fix (L104-106): "HELP-FRAGMENT-TRACKER.md (bare-filename refs from
  project-side; the pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md`),"
- The "per CI Check 24 byte-identity contract with `project-template/docs/pack/
  HELP-FRAGMENT-TRACKER.md`" clause is cleanly dropped per user-locked
  Decision 2 Approach 1 (minimal surgical edit; no rephrase / no audit-trail
  addition).

**Boundary-discipline check (Fix 2).** Per IMPL-REPORT-STALE-REFS §5.3:
- Concept edited: deny-list parenthetical content.
- Project-side SSOT: the canonical `project-template/skills/boundary-
  investigation/SKILL.md` itself (Pattern A canonical single source).
- Direction: REMOVED a pack-side reference from a project-side file — opposite
  direction from the stop trigger. Per the `boundary-investigation` skill, this
  is an SSOT-respecting edit.

**Disposition.** CONFIRMED-CORRECT. Both stale-ref fixes apply correctly to
the surfaces specified.

### §3.7 README edits (4 prose locations)

Per planner §3.2 + Pack Chat POQ-2 same-commit decision.

**L60 v11.0 row prose.**

- Pre-BD-194: "validate-pack.py expanded to 41 invoked checks (39 numbered
  Check 1–11 and 16–43; ... Checks 12–15 retired per v9 sunset) — per-CLI
  parity, help-fragment freshness/completeness, byte-identity, customization
  regression guard, ..."
- Post-BD-194 (L60 verified): "validate-pack.py expanded to 40 invoked checks
  (38 numbered Check 1–11, 16–23, and 25–43; 2 unnumbered informational —
  issue-template-forms and template-archive-v11; Checks 12–15 retired per v9
  sunset; Check 24 retired per BD-194) — per-CLI parity, help-fragment
  freshness/completeness, customization regression guard, ..."
- The verb-list mid-row prose correctly drops "byte-identity," (the
  pre-BD-194 form had ", byte-identity," between "completeness" and
  "customization").

**L107 client-installed HELP-FRAGMENT-TRACKER.md note.**

- Pre-BD-194: "Shared tracker section (v11; byte-identical to pack root,
  DELTA L1)".
- Post-BD-194 (verified): "Shared tracker section (v11; project-side
  authoritative per BD-193 F4/F5)".

**L195 validate-pack.py note.**

- Pre-BD-194: "CI structural validation (41 invoked checks — 39 numbered
  Check 1–11 and 16–43; ... Checks 12–15 retired per v9 sunset; pack-internal)".
- Post-BD-194 (verified): "CI structural validation (40 invoked checks — 38
  numbered Check 1–11, 16–23, and 25–43; 2 unnumbered informational —
  issue-template-forms and template-archive-v11; Checks 12–15 retired per v9
  sunset; Check 24 retired per BD-194; pack-internal)".

**L272 pack-side HELP-FRAGMENT-TRACKER.md note.**

- Pre-BD-194: "Shared tracker section (v11; canonical; mirrored to
  project-template/docs/pack/)".
- Post-BD-194 (verified): "Shared tracker section (v11; pack-side
  authoritative; project-template/docs/pack/ is the separate project-side
  authoritative copy per BD-193 F4/F5)".

All 4 prose edits correctly drop the byte-identity / canonical-mirror framing
in favor of the per-surface-authoritative language.

**Disposition.** CONFIRMED-CORRECT.

### §3.8 Pack-root trinity edits (3 files; identical)

Per planner §3.4.1 POQ-1 Option A + §8.2 POQ-2 Sub-option A.

**Verification of byte-identical cross-trinity edit.**

`git diff HEAD~1 HEAD -- CLAUDE.md AGENTS.md GEMINI.md` shows the EXACT SAME
diff hunk in each file (5 lines context + 2 lines removed + 2 lines added):

```
-  (trinity files, per-skill `SKILL.md`, byte-identical mirrors per
-  CI Check 24, ecosystem-fixed names like `.gitignore` / `pyproject.toml`
-  / `Package.swift`); for these exempted collisions, prose references
+  (trinity files, per-skill `SKILL.md`, ecosystem-fixed names like
+  `.gitignore` / `pyproject.toml` / `Package.swift`); for these exempted collisions, prose references
```

- `CLAUDE.md:504-505`: post-edit form
- `AGENTS.md:465-466`: post-edit form (byte-identical to CLAUDE)
- `GEMINI.md:435-436`: post-edit form (byte-identical to CLAUDE)

Per `diff <(sed -n '490,520p' CLAUDE.md) <(sed -n '451,481p' AGENTS.md)` and
the matching diff against GEMINI.md L421-451, all three trinity files carry
identical content at the filename-uniqueness section — trinity parity preserved.

**Note on line length.** The new L505 / L466 / L436 line carries:

```
  `.gitignore` / `pyproject.toml` / `Package.swift`); for these exempted collisions, prose references
```

This line is wider than the surrounding ~76-char lines (the previously-wrapped
"for these exempted collisions" clause is now on the same line as the
ecosystem-fixed names). Cosmetically inconsistent with the surrounding wrap
width but not functionally defective. Surfaced as NIT only.

**Disposition.** CONFIRMED-CORRECT (with NIT — see §6).

### §3.9 Manifest regen

Per CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface commit"
(RC9) + IMPL-REPORT-STALE-REFS §6.

**Verification.**

- Main coder pass: regenerated; empty diff (legitimate per IMPL-REPORT §8.3 —
  modified files at that pass were pack-internal CI, not client-installed via
  `init-project.sh` stages S1-S11).
- Stale-refs fix pass: regenerated; 3 v11-* row SHA changes (v11-realistic-ot,
  v11-flat-file, v11-tracker-on) per IMPL-REPORT-STALE-REFS §6 — both Fix 1
  (`scripts/init-project.sh`) and Fix 2 (`project-template/skills/boundary-
  investigation/SKILL.md`) are v11-surface edits that propagate to client
  fixtures.

**Live state at HEAD.**

```
v10-minimal              19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot         4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot         570b7f8628abaa0ebe8d5580797f790f1165eea7
v11-flat-file            4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
v11-tracker-on           8f584b117f39d5826c7360f0e45a56cc6bfc1fce
existing-project-mid-dev a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

- v10-* SHAs unchanged (tag-pinned per `test-fixtures/README.md` § Determinism).
- existing-project-mid-dev SHA unchanged (synthesized pre-pack-install input
  shape).
- v11-* SHAs reflect the actual content at HEAD.

**Verify-step.** `bash test-fixtures/build.sh --verify` runs to PASS with all
6 fixtures matching the manifest. This is the BD-115 RELEASE-GATE item 5
gate; on push, the CI `fixture manifest verify` step will PASS.

**Disposition.** CONFIRMED-CORRECT.

---

## §4 Q2 — Remaining in-scope issues

### §4.1 Stale Check-24 references in pack-repo dotted-skill copies

**Finding F-1 (REMEDIATION-NEEDED-MUST).** Three pack-repo CLI skill
directories at the pack repo root carry the EXACT SAME stale parenthetical
that was fixed in the project-template canonical:

- `.claude/skills/boundary-investigation/SKILL.md:101-102`
- `.codex/skills/boundary-investigation/SKILL.md:101-102`
- `.gemini/skills/boundary-investigation/SKILL.md:101-102`

Each contains: "pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md` per CI
Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-
TRACKER.md`)".

The canonical `project-template/skills/boundary-investigation/SKILL.md:105-106`
was correctly fixed in BD-194 (Fix 2 of stale-refs pass) — but the THREE
pack-repo CLI skill mirrors at pack ROOT were not touched.

**Evidence.**

```
$ grep -n "Check 24 byte-identity" \
    .claude/skills/boundary-investigation/SKILL.md \
    .codex/skills/boundary-investigation/SKILL.md \
    .gemini/skills/boundary-investigation/SKILL.md \
    project-template/skills/boundary-investigation/SKILL.md
.claude/skills/boundary-investigation/SKILL.md:102:  Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),
.codex/skills/boundary-investigation/SKILL.md:102:  Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),
.gemini/skills/boundary-investigation/SKILL.md:102:  Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),
(project-template canonical clean — no matches)
```

**History.** Per `git log v11-dev -L "/Check 24 byte-identity contract/,+2:.claude/skills/boundary-investigation/SKILL.md"`,
the pack-repo dotted-skill copy was created at commit `f5b3998` (BD-175) and
the stale parenthetical was introduced at creation. The canonical project-
template copy has been updated through multiple BDs since (`8f6ce51`, `6e3e082`,
`78a3b80`, `85196d4`, `4ef6c02`); the pack-repo copies have NOT been kept in
sync.

**Impact.** These pack-repo SKILL.md files are LIVE OPERATIONAL skill content
loaded by pack-* agents per `.claude/agents/pack-coder.md:108`,
`.codex/agents/pack-coder.toml:51`, `.gemini/agents/pack-coder.md:104`
(which load `boundary-investigation` from the pack-repo dotted-skill
directories per the `pack-coder` agent definition's "Skills are in
`.claude/skills/`" / `.codex/skills/` / `.gemini/skills/` directive). Any
pack agent loading the skill at HEAD will read the stale "CI Check 24
byte-identity contract" reference — pointing to a retired check that no
longer exists.

**Boundary-discipline characterization (P-missed-7).** These three files
live in PACK-REPO (NOT under `project-template/`). They are pack-internal
skill content; not client-installed (clients receive `project-template/
skills/boundary-investigation/SKILL.md` via `stage_s4_skills()`). The pack-
side SSOT for these files is the file itself — there is no separate
authoritative source. The stale references are pack-side defects, fixable
in-place per pack-side discipline.

**Why this was missed.** The main IMPL-REPORT §10.3 item 2 surfaced the
project-template-side `SKILL.md` stale reference and the stale-refs fix
pass addressed THAT, but neither the architect doc, the planner doc, nor
the IMPL-REPORT enumerated the three pack-repo CLI mirrors at pack root.
The fence-allowlist (Check 37) only operates on `project-template/`
trees — the pack-repo dotted-skill copies are outside that scope.

**Recommended remediation.** Apply the same surgical edit (drop the
parenthetical clause "per CI Check 24 byte-identity contract with
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`") to all three
pack-repo dotted-skill copies. Cross-CLI byte-identical (these three
files are pack-side mirrors that should track each other; verified
byte-identical at HEAD via `diff .claude/.../SKILL.md .codex/.../SKILL.md`
returning empty).

**Disposition.** REMEDIATION-NEEDED-MUST.

### §4.2 Untracked count discrepancy in stale-refs IMPL-REPORT §5.2

**Finding F-2 (REMEDIATION-NEEDED-NIT).** IMPL-REPORT-STALE-REFS.md:209-214
claims: "Invoked checks: 41 invocations across 40 unique checks (Check 16, 18,
19 each invoked twice — once for pack-root trinity and once for project-
template trinity — yielding 3 extra invocations; 40 unique check IDs in range
1-23 + 25-43 with Check 24 absent per main BD-194 deletion)."

Actual at HEAD `4ef6c02`:

```
$ python3 scripts/validate-pack.py 2>&1 | grep -E "^── Check" | wc -l
43
```

43 invocation header lines, not 41. The 3 dual-invoked checks (16, 18, 19)
each contribute 1 extra invocation = 3 extra invocations on top of 40 unique
checks = 43 total invocation lines.

The IMPL-REPORT-STALE-REFS narrative says "41 invocations" but should say
"43 invocations". The README's "40 invoked checks" prose is correct in
referring to UNIQUE checks; the IMPL-REPORT documentation count is the
inaccurate piece.

**Impact.** Documentation-only discrepancy in an IMPL-REPORT artifact (not
in landed source). No CI gate or operational consequence.

**Recommended remediation.** Optional documentation accuracy fix in
IMPL-REPORT-STALE-REFS.md §5.2 — change "41 invocations" to "43 invocations".
NIT severity.

**Disposition.** REMEDIATION-NEEDED-NIT.

### §4.3 No new POQs surfaced

**Verification.** I performed the following surface scans:

- `grep -rn "Check 24"` repo-wide (excluding `.git`, `maintenance-docs/archive`):
  All remaining occurrences are either (a) retirement / audit-trail prose in
  BD-194's own deliverables and validate-pack.py retirement comments,
  (b) historical BACKLOG entries per IMPL-REPORT §10.3 item 3 disposition,
  (c) the F-1 pack-repo dotted-skill copies (surfaced above), or
  (d) the README's intentional "Check 24 retired per BD-194" announcement.
- `grep -rn "byte-identity\|byte-identical mirror"` repo-wide:
  All remaining occurrences are either (a) retirement-context in validate-
  pack.py, (b) UNRELATED byte-identity contracts (per-entry mirror per
  BD-164/168, tracker-link per V3.3 §5.3, BD-106 phase-task round-trip)
  per IMPL-REPORT §10.3 item 4 disposition, or (c) the BD-178 cross-CLI
  reference normalization section in pack-root trinity (unrelated to BD-194).

No additional in-scope stale references requiring action.

---

## §5 Q3 — Regressions

### §5.1 Pack-side review skill preservation

**Verification.** Per `feedback_pack_project_separation_of_concerns` — pack-side
and project-side skill copies are intentionally divergent. The pack-side
review skills at `.claude/skills/review/SKILL.md`, `.codex/skills/review/SKILL.md`,
`.gemini/skills/review/SKILL.md` all contain the "sibling BD" carry-forward
discipline references (3 occurrences each at L36, L37, L51).

```
$ grep -c "sibling BD" .claude/skills/review/SKILL.md .codex/skills/review/SKILL.md .gemini/skills/review/SKILL.md
.claude/skills/review/SKILL.md:3
.codex/skills/review/SKILL.md:3
.gemini/skills/review/SKILL.md:3
```

`git diff HEAD~1 HEAD -- .claude/skills/review/SKILL.md .codex/skills/review/SKILL.md .gemini/skills/review/SKILL.md`
returns empty — pack-side review skills NOT touched by BD-194 commit.
Separation preserved.

**Disposition.** CONFIRMED-CORRECT (no regression).

### §5.2 Trinity parity at pack-root

**Verification.** Per `commit-discipline` skill §5 trinity rule, the
filename-uniqueness section at `CLAUDE.md:495-525` / `AGENTS.md:456-486` /
`GEMINI.md:426-456` must be byte-identical across the three trinity files.

```
$ diff <(sed -n '490,520p' CLAUDE.md) <(sed -n '451,481p' AGENTS.md)
(empty)
$ diff <(sed -n '490,520p' CLAUDE.md) <(sed -n '421,451p' GEMINI.md)
(empty)
```

Both diffs return empty. Trinity parity preserved at the modified section.

**Disposition.** CONFIRMED-CORRECT (no regression).

### §5.3 Legitimate content preserved

**Verification.** Checked all 14 files in the BD-194 commit for accidental
removals or unintended truncation:

- `scripts/validate-pack.py` Check 22 / 23 / 25-43 logic remains intact; the
  retired Check 24 function is the ONLY function removal (verified by `wc -l`
  delta from pre- to post-BD-194: -34 + +54 = +20 net lines, consistent with
  IMPL-REPORT §2 line-delta claims).
- README.md changes are all line-level prose edits at L60, L107, L195, L272;
  no other prose touched.
- Trinity files: only the 2-line-removal at the filename-uniqueness section;
  no other prose touched.
- `scripts/init-project.sh`: comment block L809-813 replaced (Fix 1); no
  functional code (copy/install logic) modified.
- `project-template/skills/boundary-investigation/SKILL.md`: parenthetical
  clause dropped at L105-106; no other prose touched.
- `scripts/tests/test-init-project.sh` test 3.3 (L181-191): substance
  preserved (still asserts `cmp -s` between source and install copy); only the
  source path and prose attribution changed.
- `scripts/tests/test-migrate-v10-to-v11.sh` test 2.5 (L151-160): same shape.

No legitimate content was accidentally removed or truncated.

**Disposition.** CONFIRMED-CORRECT (no regression).

### §5.4 No new leaks introduced

**Verification.** Per `boundary-investigation` skill, scanned the BD-194 diff
for new pack-only references introduced into project-side files:

- `git diff HEAD~1 HEAD -- project-template/` shows only one project-side
  change: `boundary-investigation/SKILL.md:105-106`. The change REMOVES a
  pack-side reference ("per CI Check 24 byte-identity contract"). Direction
  is OPPOSITE the leak direction — no new leaks.
- Check 37 (project-side pack-only deny-list) PASSes at HEAD per validate-pack
  run.
- Check 43 (project-side bare cross-reference scanner) PASSes at HEAD per
  validate-pack run.

**Disposition.** CONFIRMED-CORRECT (no regression).

### §5.5 Manifest correctness

**Verification.** Per `bash test-fixtures/build.sh --verify`:

```
v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot OK: 570b7f8628abaa0ebe8d5580797f790f1165eea7
v11-flat-file OK: 4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
v11-tracker-on OK: 8f584b117f39d5826c7360f0e45a56cc6bfc1fce
existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All 6 fixture SHAs match the manifest at HEAD. v10-* + existing-* SHAs
unchanged from pre-BD-194 baseline (tag-pinned / synthesized). v11-* SHAs
reflect the legitimate post-BD-194 drift from Fix 1 + Fix 2.

**Disposition.** CONFIRMED-CORRECT (no regression).

### §5.6 CI gate correctness

**Verification of `python3 scripts/validate-pack.py`.** PASS with the new
40-unique-check (43-invocation) shape:

```
============================================================
PASSED — all checks clean
```

- Check 24 absent from the output (confirmed via `grep -E "^── Check 24"`
  returning empty).
- Check 23 fail-loud branch operates correctly (would FAIL if pack-side
  tracker fragment missing; both files present at HEAD so the branch is not
  taken).
- Check 22 per-surface logic operates correctly (each surface uses its own
  tracker fragment; both surfaces PASS the verb-presence comparison at HEAD).

**Verification of Check 22 per-surface fix functional correctness.** Per
IMPL-REPORT §9.5 + my read of the surfaces dict + iteration loop, the
per-surface tracker fragment selection works as designed: pack-root surface
uses `pack-ops/HELP-FRAGMENT-TRACKER.md`; project-template surface uses
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. Divergence in pack-side
content would NOT affect project-template surface's check (and vice versa).

**Finding F-3 (REMEDIATION-NEEDED-MUST). Pre-existing test failures inherited
from BD-193 will FAIL CI on push.**

Running per-check tests at HEAD reveals TWO failing tests:

#### F-3a: `scripts/tests/test-validate-pack-check-43.sh` Group 2 T3

```
$ bash scripts/tests/test-validate-pack-check-43.sh
=== Group 2: _iter_client_installed_files() base-set verification ===
FAILURES
  T3 _iter_client_installed_files() missing expected entry: pack-ops/HELP-FRAGMENT-TRACKER.md
  FAIL _iter_client_installed_files() base-set tests failed
...
  PASS: 6
  FAIL: 1
```

The test (L185-191) expects `pack-ops/HELP-FRAGMENT-TRACKER.md` in the
`_iter_client_installed_files()` return set. At HEAD, the function does
NOT return that path because the `_CLIENT_INSTALLED_FILES_START/_END`
inventory in `scripts/init-project.sh:1273-1311` no longer contains it
(removed in BD-193 `85196d4` when F4/F5 corrected the install source to
the project-template-side file).

#### F-3b: `scripts/tests/test-validate-pack-checks-36-37-38.sh` Group 7 T3

```
$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh
=== Group 7: Check 37 scope expansion (Guardrail 3) unit tests ===
FAILURES
  G7.T3: missing expected non-project-template extras: ['pack-ops/HELP-FRAGMENT-TRACKER.md']
  FAIL Group 7 — Guardrail 3 scope expansion unit tests failed
...
  PASS: 7
  FAIL: 1
```

Same root cause: the test (L642-654) expects `pack-ops/HELP-FRAGMENT-TRACKER.md`
in `_iter_client_installed_files()` set; HEAD inventory does not list it.

**Origin (pre-existing from BD-193).**

- `git diff 85196d4 4ef6c02 -- scripts/tests/test-validate-pack-check-43.sh
  scripts/tests/test-validate-pack-checks-36-37-38.sh` returns empty (BD-194
  did NOT modify these tests).
- `git diff 85196d4 4ef6c02 -- scripts/validate-pack.py` shows `_iter_client_
  installed_files()` body unchanged (BD-194 did NOT modify this helper).
- `git log --oneline -L "/_CLIENT_INSTALLED_FILES_START/,/_CLIENT_INSTALLED_
  FILES_END/:scripts/init-project.sh"` shows BD-193 (`85196d4`) was the
  commit that REMOVED `pack-ops/HELP-FRAGMENT-TRACKER.md` from the
  inventory.

**Why BD-193 CI didn't catch it.** Per `gh run list --branch v11-dev`, the
most recent CI runs are all on commits PRIOR to BD-193 (last successful run
was on `8b4c607` BD-185 at 2026-05-26). The BD-193 commit (`85196d4`) and
its descendants including BD-194 (`4ef6c02`) have NOT been pushed yet, so
no CI has run against the BD-193 inventory change.

**Why BD-194 didn't catch it.** The IMPL-REPORT PREFLIGHT line (§11) attests
to "`validate-pack.py` PASS at 40 invoked checks" — the validate-pack itself
runs clean. But the planner §5 verification gates (G1-G6) did NOT include
"run all per-check tests" as a gate. The IMPL-REPORT verification §9 also
does not document running per-check tests. The reviewer pass (this report)
is the first place these tests were run.

**Impact.** When the BD-194 commit is pushed to v11-dev, the `Validate Pack`
GitHub Actions workflow will FAIL at:
- Step "validate-pack Check 43 tests (BD-173 H.14, V11 leak-sweep prevention,
  project-side bare cross-reference scanner)" (workflow L184-186 per
  `.github/workflows/validate-pack.yml`).
- Step "validate-pack checks 36-37-38 tests" (workflow L162).

Both steps carry `if: always()` so both will execute and both will FAIL,
generating two test-failure annotations on the BD-194 commit. This is a
release-gate blocker even though `python3 scripts/validate-pack.py` itself
PASSes.

**Architectural intent vs test expectations.**

The architect doc §2.6.1 item 5 documents that `_CHECK_43_PACK_OPS_CLIENT_
INSTALLED = ("pack-ops/HELP-FRAGMENT-TRACKER.md",)` at L5229 still names
`pack-ops/HELP-FRAGMENT-TRACKER.md` as a Check 43 exemption (path-keyed
exemption: the pack-side file is exempt from the pack-internal-target FAIL
because it has a client-installed analog).

The TWO authoritative sources currently disagree:
- `scripts/init-project.sh:1273-1311` `_CLIENT_INSTALLED_FILES_START/_END`
  (which `_iter_client_installed_files()` reads from): does NOT list
  `pack-ops/HELP-FRAGMENT-TRACKER.md`.
- `scripts/validate-pack.py:5229` `_CHECK_43_PACK_OPS_CLIENT_INSTALLED`:
  DOES list `pack-ops/HELP-FRAGMENT-TRACKER.md`.
- The two failing tests assume the FIRST authority (the inventory) should
  list `pack-ops/HELP-FRAGMENT-TRACKER.md`.

**Recommended remediation (one of three; user decides):**

- **Option A — Update test expectations.** Modify both test files to drop
  `pack-ops/HELP-FRAGMENT-TRACKER.md` from `expected_extras` per the post-
  BD-193 F4/F5 contract. Aligns the tests with the inventory.
- **Option B — Restore inventory entry.** Add `pack-ops/HELP-FRAGMENT-
  TRACKER.md  ->  pack-ops/HELP-FRAGMENT-TRACKER.md  [stage:N/A]` to the
  inventory at `scripts/init-project.sh:1306` (or similar) to surface the
  pack-side file as a "tracked but not installed" entry. Requires updating
  the inventory schema interpretation (the existing entries are install-
  source → install-dest mappings; a pack-only entry would need a new
  marker class).
- **Option C — Add a separate authority surface.** Introduce a new
  helper or accept the existing `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` tuple
  as the second authority; update `_iter_client_installed_files()` to merge
  both. Requires more design work.

Per `feedback_pack_project_separation_of_concerns` (user-locked 2026-05-26),
**Option A** is architecturally consistent — the pack-side
`pack-ops/HELP-FRAGMENT-TRACKER.md` is NOT a client-installed file (only
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` is), and the
`_CLIENT_INSTALLED_FILES_START/_END` inventory in init-project.sh correctly
omits it. The tests should be updated to match.

Note that this finding's resolution likely requires a separate small commit
(BD-194-followup or a new BD-NNN) since the test edits are NOT in BD-194's
spawn-prompt scope and discovery happened at reviewer pass. Per
`feedback_deferral_is_scope_creep` LOGICAL FIT criterion, the test fixes
ARE in scope for a BD-194 followup — same architectural correction class
(post-BD-193 F4/F5 separation contract), same file domain (pack/project
separation).

**Disposition.** REMEDIATION-NEEDED-MUST. Block release until resolved
(either bundle into BD-194 commit before push, or land as a follow-on
fix-commit before push).

### §5.7 No downstream check dependencies on Check 24 missed

**Verification.** Architect §2.6.1 enumerated 8 downstream surfaces:

1. **Check 22 (latent bug)** — FIXED in BD-194 per §3.3 verification.
2. **Check 23 (fail-loud)** — FIXED in BD-194 per §3.2 verification.
3. **`pack-help.sh` rendering** — runtime reads one fragment per surface;
   does NOT depend on cross-surface byte-identity. NO EDIT needed.
   Verified at `scripts/pack-help.sh` (not modified by BD-194). Confirmed
   no Check-24 reference at `grep -n "Check 24" scripts/pack-help.sh`
   (empty).
4. **`scripts/init-project.sh` S11** — post-BD-193 contract intact (the
   L809-813 comment block was UPDATED by Fix 1 to reflect this).
5. **Check 43 leak-sweep exemption (`_CHECK_43_PACK_OPS_CLIENT_INSTALLED`)** —
   path-keyed, not byte-identity-keyed; behavior unchanged. Verified at
   L5229 — tuple intact.
6. **Check 40 / Check 43 allowlist comments** — UPDATED per §3.4 verification.
7. **Check 37 anchor-phrase note L4051** — comment-only context, no edit
   needed today. Verified intact.
8. **Check 41 `_CLIENT_INSTALLED_FILES`** — comment rationale unchanged
   substantively (the underlying inventory still lists the project-side
   path; Check 41 OK message intact).

`pack-help.sh` is NOT in the BD-194 commit. Confirmed via `git diff HEAD~1
HEAD -- scripts/pack-help.sh` returning empty. The runtime rendering reads
the per-surface fragment and concatenates the per-surface tracker fragment
(separately for pack-side and client-side); no cross-surface assumption.

**Disposition.** CONFIRMED-CORRECT (no missed downstream).

---

## §6 Findings summary

### §6.1 Per-category counts

| Category | Count | Findings |
|---|---|---|
| CONFIRMED-CORRECT | 11 | §3.1, §3.2, §3.3, §3.4, §3.5, §3.6, §3.7, §3.9, §5.1, §5.2, §5.3, §5.4, §5.5, §5.7 |
| REMEDIATION-NEEDED-MUST | 2 | F-1 (§4.1 pack-repo dotted-skill copies), F-3 (§5.6 pre-existing test failures: F-3a + F-3b) |
| REMEDIATION-NEEDED-SHOULD | 0 | — |
| REMEDIATION-NEEDED-NIT | 2 | §3.8 trinity-edit line-width inconsistency (cosmetic), F-2 (§4.2 IMPL-REPORT-STALE-REFS invocation-count documentation) |
| AMBIGUOUS | 0 | — |

(§3.8 disposition was CONFIRMED-CORRECT for trinity parity AND a NIT for the
line-width drift — counted in CONFIRMED-CORRECT row and in NIT row.)

### §6.2 Priority ranking

**HIGH priority (block before push):**

- **F-1** (§4.1) — Three pack-repo dotted-skill copies still reference retired
  Check 24. Live operational pack agent content. Same surgical edit pattern
  as the project-template-side fix that already landed.
- **F-3** (§5.6) — Two per-check tests (`test-validate-pack-check-43.sh`,
  `test-validate-pack-checks-36-37-38.sh`) will FAIL CI on push due to
  pre-existing BD-193 inventory/test divergence. Release-gate blocker even
  though `validate-pack.py` self-test PASSes.

**MEDIUM priority:** None.

**LOW priority:**

- §3.8 NIT — trinity-edit line-width inconsistency post-clause-drop. Cosmetic
  only; not a CI or operational defect. Optional reflow fix.
- **F-2** (§4.2) — IMPL-REPORT-STALE-REFS.md §5.2 documentation count
  inaccuracy ("41 invocations" vs actual 43). Doc-only; archive material
  per Pattern B sweep at version ship.

### §6.3 Implementation success summary

The architect's Candidate 6 design is FAITHFULLY IMPLEMENTED in the BD-194
commit:

- Check 24 fully retired (function + callsite + check-list + 5 retirement /
  audit-trail prose anchors as drafted).
- Check 23 fail-loud modification correctly applied with BD-194 docstring
  attribution.
- Check 22 per-surface fix correctly applied with per-surface `tracker_fragment`
  keys in the surfaces dict + iteration loop + fail-loud branches + BD-194
  docstring + dict-block comment.
- 2 allowlist comment-rationale updates correctly applied at L4762-4782 and
  L5138.
- 2 integration test install-source assertions correctly updated to the
  post-BD-193 F4/F5 project-template-side path.
- 2 stale-ref follow-on fixes (Fix 1 at `scripts/init-project.sh:809-813`,
  Fix 2 at `project-template/skills/boundary-investigation/SKILL.md:105-106`)
  correctly applied per user-locked Decision 2 Approach 1.
- 4 README prose edits correctly applied at L60, L107, L195, L272.
- 3 trinity edits correctly applied byte-identically at CLAUDE/AGENTS/GEMINI
  filename-uniqueness section.
- Manifest regenerated correctly; 3 v11-* fixture rows reflect Fix 1 + Fix 2
  legitimate drift; v10-* + existing-* SHAs preserved.

The architectural intent is correctly EXPRESSED in the landed source.

### §6.4 Remaining work

Two additional remediation actions are needed before the commit is fully
release-ready:

1. **Fix F-1** — Update 3 pack-repo dotted-skill copies of
   `boundary-investigation/SKILL.md` to drop the stale "per CI Check 24
   byte-identity contract" clause. Apply IDENTICAL edits across the three
   CLI variants (these are pack-side byte-identical mirrors).
2. **Fix F-3** — Update 2 per-check tests to align with the post-BD-193 F4/F5
   inventory contract. Drop `pack-ops/HELP-FRAGMENT-TRACKER.md` from the
   `expected_extras` set in:
   - `scripts/tests/test-validate-pack-check-43.sh:185-191` (Group 2 T3)
   - `scripts/tests/test-validate-pack-checks-36-37-38.sh:642-654` (Group 7 T3)

Both fixes share the same architectural correction class (post-BD-193 F4/F5
separation contract) and same SCOPE-CREEP-eligible criteria
(`feedback_deferral_is_scope_creep` LOGICAL FIT — same pack/project separation
class, same file domain).

Optional NIT fixes (§3.8 line-width reflow, F-2 IMPL-REPORT invocation count)
may be bundled or deferred per Pack Chat ergonomics; neither blocks release.

---

## §7 AMBIGUOUS surface

None. All findings are concretely categorized with evidence-backed dispositions.

---

## §8 Recommended remediation

### §8.1 Fix bundle proposal

**Recommendation for Pack Chat triage:**

Bundle Fixes F-1 and F-3 into a single follow-on fix-coder commit BEFORE the
BD-194 commit is pushed to v11-dev. Both fixes are mechanical applications of
the post-BD-193 F4/F5 separation contract, same architectural-correction
class as BD-194's existing scope.

**Edit inventory (4-5 files):**

| File | Edit |
|---|---|
| `.claude/skills/boundary-investigation/SKILL.md` (L101-102) | Drop "per CI Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`" parenthetical clause |
| `.codex/skills/boundary-investigation/SKILL.md` (L101-102) | Same edit (cross-CLI byte-identical) |
| `.gemini/skills/boundary-investigation/SKILL.md` (L101-102) | Same edit (cross-CLI byte-identical) |
| `scripts/tests/test-validate-pack-check-43.sh` (L185-191) | Drop `"pack-ops/HELP-FRAGMENT-TRACKER.md",` from `expected_extras` list |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` (L642-654) | Drop `'pack-ops/HELP-FRAGMENT-TRACKER.md',` from `expected_extras` set + update the architect §3.3 cite comment accordingly |
| `test-fixtures/manifest.txt` | Regenerate per RC9 (3 v11-* CLI skill paths affected; tests likely not since they're under `scripts/tests/` per BD-194 main pass observation §8.3) |

**Verification gates for the follow-on commit:**

1. `python3 scripts/validate-pack.py` PASS (no regression from main BD-194 pass).
2. `bash scripts/tests/test-validate-pack-check-43.sh` PASS at 7/7.
3. `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` PASS at 8/8.
4. `grep -n "Check 24 byte-identity" .claude/skills .codex/skills .gemini/skills`
   returns empty.
5. Manifest regen per RC9; v10-* + existing-* SHAs unchanged; v11-* SHAs
   reflect the 3 dotted-skill edits.

### §8.2 Commit shape alternatives

- **Option A — Inline fix-bundle commit BEFORE BD-194 push.** Pack Chat
  spawns fix-coder against the 5-file edit list above; lands as a NEW commit
  on top of `4ef6c02` BUT BEFORE pushing to remote. The single push then
  carries both BD-194 main + this follow-on cleanly. Avoids the CI-failure-
  on-push scenario.
- **Option B — Single commit by amending BD-194.** Apply edits via fix-coder
  in working tree, then amend the BD-194 commit. CLAUDE.md "Commit-subject
  scope-keyword convention" + Pack Chat memory `feedback_pack_chat_does_no_fixes`
  rules suggest a separate commit is safer than amend; amend may alter the
  audit trail of which work landed at which point.
- **Option C — Push BD-194, observe CI fail, then commit fix.** Wastes a CI
  cycle; release-gate blocker.

**Recommendation:** Option A.

### §8.3 New-BD-anchor (if needed)

If Pack Chat chooses NOT to bundle the fixes inline (e.g., user prefers a
fresh BD-NNN for audit clarity), the work qualifies as a follow-on:

- **Size:** small (5 mechanical edits + manifest regen).
- **Blocked:** no — independent of any other pending work.
- **Logical fit:** YES — same architectural-correction class as BD-194,
  same file domain, same pack-memory anchor `feedback_pack_project_separation_
  of_concerns`. Per `feedback_deferral_is_scope_creep` LOGICAL FIT criterion,
  this is EXACTLY the small-unblocked-logical-fit class that should be
  bundled or land in the very next commit.

A new BD entry would name `pack-ops/BACKLOG.md:NEXT` (highest BD-NNN + 1 per
CLAUDE.md "BD-NNN numbering"). The Pack Chat memory rule
`feedback_no_deferral_without_user_direction` indicates this should NOT defer
to v11.1; it should land in v11.0 immediately after BD-194 if not bundled.

---

## §9 Cross-references

### §9.1 Architect deliverable

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (1179 lines;
  Candidate 6 user-approved)
  - §2.6.1 — downstream dependencies enumeration (verified per §5.7).
  - §4 — Candidate 6 recommended design (faithfully implemented per §3).
  - §5.1 — implementation sketch (correctly applied per §3.2 / §3.3).
  - §5.2 — allowlist comment updates (correctly applied per §3.4).
  - §7 — POQs (all 3 settled per user-locked decisions).

### §9.2 Planner deliverable

- `maintenance-docs/v11-implementation/PLAN-BD-194.md` (946 lines)
  - §3.2 — README edit targets (all 4 applied per §3.7).
  - §3.4 — planner-discovered references (trinity + Check 22 dict-comment +
    Check 22/23 docstrings all addressed).
  - §4.1 — single-commit file list (all files accounted for).
  - §5 — verification gates (G1-G5 documented in IMPL-REPORT §9; G6 smoke
    test executed per IMPL-REPORT §9.5).
  - §8 — POQs (POQ-1 + POQ-2 settled per user-locked decisions; POQ-3
    non-blocking).

### §9.3 Coder deliverables

- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md`
  (980 lines; main pass)
  - §3, §4, §5, §6, §7 — Detail per architect/planner alignment; verified
    correct per §3 of this review.
  - §10.3 — 5 out-of-scope stale-ref classes surfaced for Pack Chat triage.
    Items 1 + 2 were dispositioned for inline fix (stale-refs pass); items 3
    + 4 + 5 correctly NO-EDIT.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md`
  (442 lines; follow-on fix pass)
  - §3 + §4 — both fixes correctly applied per §3.6 of this review.
  - §5 — verification (validate-pack PASS, stale-ref purge clean per the
    two specific patterns checked).
  - §5.2 — invocation count "41 invocations" inaccuracy surfaced as F-2
    (§4.2). Actual is 43; NIT only.

### §9.4 BD entry

- `pack-ops/BACKLOG.md:3076-3124` (BD-194 Open at HEAD).
- Status flip to Resolved is end-of-batch Pack Chat action per
  `feedback_implicit_status_flip` — after F-1 and F-3 remediations land
  and CI is green.

### §9.5 Pack memory anchors (governing rules)

- `feedback_pack_project_separation_of_concerns` — user-locked 2026-05-26;
  authoritative for the BD-194 design (Candidate 6 expression) and for the
  F-3 test-expectation alignment recommendation (Option A).
- `feedback_deferral_is_scope_creep` — applies to F-1 + F-3 LOGICAL FIT
  in-scope categorization for a bundled follow-on commit.
- `feedback_review_carry_forward_discipline` — applied; no findings deferred
  to a future review pass; F-1 and F-3 surfaced as in-scope REMEDIATION-
  NEEDED-MUST per default-fix-now.
- `feedback_fix_all_review_findings` — applied; every finding surfaced
  with severity + recommended action.
- `feedback_no_deferral_without_user_direction` — F-1 + F-3 fixes MUST
  land in v11.0; do not defer to v11.1 without explicit user authorization.
- `feedback_pack_coder_preflight_pattern` — for the follow-on fix-coder
  spawn, PREFLIGHT + STOP-MEANS-STOP pattern applies per usual.
- `feedback_manifest_regen_on_v11_surface` — F-1 fix touches `.claude/skills/`,
  `.codex/skills/`, `.gemini/skills/` (pack-repo dotted-skill dirs); these
  are NOT under the v11-surface trigger paths (`project-template/`,
  `scripts/`, `pack-ops/`, `supporting-docs/`) so manifest regen is NOT
  strictly required; however, F-3 fix touches `scripts/tests/` which IS
  under v11-surface — manifest regen required. v10-* SHAs MUST NOT drift.

### §9.6 Related architect docs

- `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
  §1.4 — Check 43 allowlist contract context (referenced by allowlist comment
  updates per §3.4).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` §5.3 —
  Check 41 `_CLIENT_INSTALLED_FILES` self-doc integrity contract (the
  project-side existence guarantee Candidate 6 relies on; still intact).
- BD-193 IMPL-REPORTs — the F4/F5 source-of-truth correction this BD-194
  pass operates against. The inventory change that landed in BD-193
  (`85196d4`) is the root cause of F-3.

### §9.7 Read-only audit confirmation

This review:

- Read but did NOT modify any source files in the working tree.
- Ran NO state-changing git verbs (no `git add`, `git commit`, `git push`,
  `git tag`, `git rebase`, `git merge`, `git reset`, `git stash`,
  `git checkout` state-changing forms, `git rm`, `git restore`, `git revert`,
  `git cherry-pick`, `git pull`, `git fetch`).
- Used only read-only git verbs (`git status`, `git diff`, `git log`,
  `git show`, `git rev-parse`).
- Wrote exactly ONE file: this report at
  `maintenance-docs/v11-implementation/PACK-REVIEW-BD-194.md`.
- HEAD SHA at audit start = HEAD SHA at audit end =
  `4ef6c02c84797ed151cffad94ca326723e6b7ff7`.

---

*End of reviewer deliverable.*
