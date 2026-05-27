# IMPLEMENTATION-REPORT-BD-194.md — Check 24 byte-identity gate retirement (coder pass)

Status: CODER DELIVERABLE — implementation complete; pending Pack Chat
PM-only co-edits (README + pack-root trinity) and reviewer audit pass.
HEAD SHA at coder pass start + end: `85702434bd8771fc964c89565491bb75e2ceec01`
(working-tree edits not yet staged or committed; coder writes report
and stops here per pack memory `feedback_agents_never_commit`).
Author: pack-coder; produced 2026-05-27 per BD-194 pipeline.

Mechanical companion implementation of:
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (1179 lines; Candidate 6 user-approved)
- `maintenance-docs/v11-implementation/PLAN-BD-194.md` (946 lines; single-commit plan user-approved)

---

## §1 Scope

BD-194 — Check 24 byte-identity gate replacement (post-BD-193
architectural baseline fix).

This pass implements the user-approved Candidate 6 design:

1. Delete Check 24 (`check_help_fragment_tracker_byte_identity`)
   entirely — function definition, main() callsite, and check-list
   comment.
2. Modify Check 23 (`check_help_fragment_completeness`) to fail-loud
   if `pack-ops/HELP-FRAGMENT-TRACKER.md` is missing.
3. Fix Check 22 (`check_help_fragment_freshness`) latent bug — replace
   single-source tracker-fragment concatenation with per-surface
   tracker-fragment selection.
4. Update audit-trail allowlist rationale comments (2 in-scope
   locations) to remove "byte-identical mirror per Check 24" / "Byte-
   identical mirror exception (Check 24)" language, replaced with
   per-surface-authoritative language cross-referencing Check 41
   `_CLIENT_INSTALLED_FILES`.
5. Update stale DELTA L1 byte-identity test assertions in two
   integration test files that exercise the SUBSTANCE of Check 24's
   contract (test-init-project.sh + test-migrate-v10-to-v11.sh) —
   tests now assert the post-BD-193 F4/F5 install-source invariant
   (client install matches project-template-side source, NOT pack-side
   canonical).
6. Regenerate `test-fixtures/manifest.txt` per pack memory
   `feedback_manifest_regen_on_v11_surface` (scripts/ touched).

Anchors:
- Architect deliverable: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md`
- Planner deliverable: `maintenance-docs/v11-implementation/PLAN-BD-194.md`
- BD entry: `pack-ops/BACKLOG.md:3076-3124` (BD-194 Open; Position
  Batch 19d-prep-3)
- HEAD SHA: `85702434bd8771fc964c89565491bb75e2ceec01`
- Pipeline position: fires AFTER BD-193 Resolved + BEFORE BD-185 H.2

---

## §2 Files modified

Three pack-coder-scope files modified in this pass; one file (manifest)
regenerated but produced no diff (legitimately — modified pack-internal
CI files are not client-installed).

| # | File | Edits | Line delta |
|---|---|---|---|
| 1 | `scripts/validate-pack.py` | Check 22 docstring + surfaces dict + per-surface fragment lookup; Check 23 docstring + fail-loud; Check 24 function deletion + callsite removal + check-list comment retirement note; 2 allowlist comment updates (`_BARE_REFERENCE_EXEMPTIONS` HELP-FRAGMENT.md + `_CHECK_43_ALLOWLIST` HELP-FRAGMENT-TRACKER.md) | ~24 line modifications across ~6 edit-sites |
| 2 | `scripts/tests/test-init-project.sh` | Test 3.3 assertion updated from pack-side byte-identity check to project-template-side install-source check (post-BD-193 F4/F5 contract) | -3 / +7 lines |
| 3 | `scripts/tests/test-migrate-v10-to-v11.sh` | Test 2.5 assertion updated identically (migrator S5 install-source contract per BD-193 F4/F5) | -3 / +6 lines |

**No diff produced (regenerated cleanly):**
- `test-fixtures/manifest.txt` — regenerated via `bash test-fixtures/build.sh --all --clean`; v11-* fixture row SHAs unchanged because the modified files (`scripts/validate-pack.py`, `scripts/tests/*`) are pack-internal CI files that are NOT mass-copied to clients by `init-project.sh` stages S1-S11. The trigger fired per `feedback_manifest_regen_on_v11_surface`; the empty diff is the correct outcome.

**Untouched files (PM-only or out-of-scope per spawn prompt):**

- `README.md` — Pack Chat applies the 4 prose edits per planner §4.1 row 2 (POQ-2 same-commit).
- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at pack root — Pack Chat applies the 3 trinity edits per planner §8 POQ-1 + spawn prompt (drops byte-identical-mirrors clause entirely).
- `pack-ops/BACKLOG.md` — BD-194 entry already open at HEAD; status flip is end-of-batch Pack Chat action per `feedback_implicit_status_flip`.
- All `project-template/` files — out of scope per spawn prompt §Out-of-scope.

---

## §3 Check 24 retirement details

### §3.1 Function removal

The function `check_help_fragment_tracker_byte_identity` formerly at
`scripts/validate-pack.py:2154-2175` was removed and replaced with a
6-line retirement comment block at the equivalent location. The
retirement comment names the architect doc, cites the user-locked pack
memory anchor, and identifies the surface-local successor invariants
(Check 23 fail-loud for pack-side; Check 41 `_CLIENT_INSTALLED_FILES`
for project-side):

```python
# ── Check 24 RETIRED in BD-194 (per ARCHITECTURE-BD-194.md Candidate 6).
# The pack-side HELP-FRAGMENT-TRACKER.md and project-template-side
# HELP-FRAGMENT-TRACKER.md are SEPARATE artifacts with SEPARATE audiences
# per pack memory feedback_pack_project_separation_of_concerns (user-
# locked 2026-05-26). Pack-side existence is asserted by Check 23
# (fail-loud); project-side existence is asserted by Check 41
# (_CLIENT_INSTALLED_FILES self-doc list integrity). No cross-surface
# content invariant is required or asserted.
```

### §3.2 Callsite removal

The `main()` callsite at `scripts/validate-pack.py:6067` was removed
and replaced with a 3-line callsite-retirement comment cross-referencing
the function-retirement comment block:

```python
    check_help_fragment_freshness()
    check_help_fragment_completeness()
    # ── Check 24 callsite removed in BD-194 (Candidate 6). See
    # ARCHITECTURE-BD-194.md §4-§5 + the retirement comment block above
    # the former check_help_fragment_tracker_byte_identity location.
    check_customization_detection_regression_guard()
```

### §3.3 Check-list comment retirement

The check-list comment entry at `scripts/validate-pack.py:62-64` was
replaced with the architect §5.4 step 3 drafted retirement note:

```python
  24. [RETIRED in BD-194 — see ARCHITECTURE-BD-194.md]
      HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1; superseded
      by Check 22 + Check 23 + Check 41 per-surface coverage). Per
      pack memory feedback_pack_project_separation_of_concerns
      (user-locked 2026-05-26), the pack-side and project-side
      HELP-FRAGMENT-TRACKER.md files are SEPARATE artifacts with
      SEPARATE audiences; byte-identity is coincidence, not contract.
```

This intentionally preserves the "Check 24" string for audit-trail
continuity (any future reader greping for "Check 24" finds the
retirement record + cross-reference to the architect doc). Per planner
G2: "the check-list comment at L62-64 may carry a single retirement note
line referencing 'Check 24' — that is INTENTIONAL audit-trail prose and
is acceptable."

---

## §4 Check 23 fail-loud modification details

### §4.1 Behavior change

Before (silent fallback):

```python
fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"
tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
if not fragment.is_file():
    fail(f"pack-root help fragment missing: {fragment.name}")
    return
text = fragment.read_text()
if tracker_fragment.is_file():
    text += "\n" + tracker_fragment.read_text()
```

After (fail-loud):

```python
fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"
tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
if not fragment.is_file():
    fail(f"pack-root help fragment missing: {fragment.name}")
    return
if not tracker_fragment.is_file():
    fail(f"pack-root tracker fragment missing: pack-ops/{tracker_fragment.name}")
    return
text = fragment.read_text() + "\n" + tracker_fragment.read_text()
```

### §4.2 Docstring addendum

Per CLAUDE.md "Architect-doc-vs-reality reconciliation" rule + planner
§3.4.3, a BD-194 attribution line was added to the Check 23 docstring:

> Per BD-194: pack-side tracker fragment (pack-ops/HELP-FRAGMENT-TRACKER.md)
> is REQUIRED — fail-loud if missing (no silent fallback). Pack-side
> existence is the surface-local invariant this check enforces;
> project-side existence is enforced independently by Check 41
> (_CLIENT_INSTALLED_FILES). See ARCHITECTURE-BD-194.md Candidate 6.

### §4.3 Why fail-loud (rationale)

Pre-BD-194, Check 23 silently fell back to verb-presence comparison
without the tracker fragment if it was missing. Under the BD-194
separation contract, pack-side existence is a surface-local invariant
that MUST hold for the verb-presence comparison to be sound — if the
tracker fragment is missing, the comparison is silently incorrect (false
negatives: tracker verbs are referenced in prose but absent from the
fragment because the fragment is missing entirely). Fail-loud surfaces
this regression at CI time rather than producing a silent false negative.

The change is safe: the file exists at HEAD; the fail-loud branch is
only reached if a future regression deletes or moves the file.

---

## §5 Check 22 per-surface fix details

### §5.1 Latent bug surfaced by architect §2.6.1 item 1

Pre-BD-194, Check 22 concatenated the SINGLE pack-side tracker fragment
to BOTH surfaces' verb-presence comparison:

```python
tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
...
for surface, cfg in surfaces.items():
    frag = cfg["fragment"]
    ...
    frag_text = frag.read_text()
    if tracker_fragment.is_file():
        frag_text += "\n" + tracker_fragment.read_text()
```

Post-BD-193 F4/F5, this is WRONG for the project-template surface. The
project-template surface's tracker verbs should be compared against the
project-template-side tracker fragment, not the pack-side one. If the
two files diverge (the architectural correction BD-194 enables), the
project-template surface's check would produce false negatives or false
positives depending on the divergence direction.

### §5.2 Fix applied

Per architect §5.1, the `surfaces` dict now carries a per-surface
`tracker_fragment` key:

```python
surfaces = {
    "pack-root": {
        ...
        "fragment": REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md",
        "tracker_fragment": REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md",
    },
    "project-template": {
        ...
        "fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT.md",
        "tracker_fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md",
    },
}

any_failed = False
for surface, cfg in surfaces.items():
    frag = cfg["fragment"]
    tracker_frag = cfg["tracker_fragment"]
    if not frag.is_file():
        fail(f"{surface}: help fragment missing: {frag.relative_to(REPO_ROOT)}")
        any_failed = True
        continue
    if not tracker_frag.is_file():
        fail(f"{surface}: tracker fragment missing: {tracker_frag.relative_to(REPO_ROOT)}")
        any_failed = True
        continue
    frag_text = frag.read_text() + "\n" + tracker_frag.read_text()
```

Both per-surface tracker fragments are now (a) authoritative inputs to
each surface's verb-presence comparison, (b) fail-loud if missing,
(c) decoupled from cross-surface identity assumptions.

### §5.3 Docstring addendum + dict-comment

Per architect §5.1 implementation sketch + planner §3.4.2 / §3.4.3, two
audit-trail texts were added:

1. **Function docstring trailing addendum:**

> Per BD-194: each surface authors its own HELP-FRAGMENT-TRACKER.md.
> Per-surface tracker fragment lookup via the surfaces dictionary; no
> cross-surface concatenation. Each surface's verbs are compared
> against the surface's own tracker fragment. See
> ARCHITECTURE-BD-194.md Candidate 6.

2. **Dict-block leading comment:**

```python
# Per BD-194: each surface authors its own HELP-FRAGMENT-TRACKER.md.
# Per-surface fragment lookup per the surface dictionary; no
# cross-surface concatenation.
surfaces = { ... }
```

---

## §6 Allowlist comment updates

Note on the spawn prompt's "6 allowlist comment updates" framing: the
architect §5.2 explicitly enumerates THREE locations (L4762-4770 block,
L5126, L4045-4051 Check 37 anchor-phrase context — the last flagged
"no immediate edit needed"). The planner §2.1 step 4 mentions "six
allowlist / audit-trail comments" but enumerates: (a) L62-64 check-list
comment, (b) L4762-4770 `_BARE_REFERENCE_EXEMPTIONS`, (c) L5126
`_CHECK_43_ALLOWLIST`, (d) L4051 Check 37 anchor-phrase (deferred),
(e-f) two places inside the Check 24 function itself (which disappear
with the function deletion). This implementation report addresses all
ACTIONABLE locations: §3.3 (L62-64 check-list comment), §3.1 (function-
location replacement), §3.2 (callsite-location replacement), §6.1
(L4762-4770), §6.2 (L5126), §6.3 (L4051 documented as no-edit-needed).
All forbidden phrases ("byte-identical mirror per Check 24", "Byte-
identical mirror exception (Check 24)") are removed from live rationale
strings.

### §6.1 `_BARE_REFERENCE_EXEMPTIONS` `HELP-FRAGMENT.md` entry (L4762-4770)

Before (rationale comment block + dict-value rationale string):

```python
# Project-side HELP-FRAGMENT companion (referenced from
# pack-ops/HELP-FRAGMENT-TRACKER.md, which is a byte-identical
# mirror of project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
# per Check 24). The bare ref is correct at the client-installed
# location (resolves to docs/pack/HELP-FRAGMENT.md in the
# client repo as a same-dir sibling); from pack-internal view it
# would qualify to project-template/docs/pack/HELP-FRAGMENT.md
# but qualifying it would break the byte-identity contract.
"HELP-FRAGMENT.md": "Byte-identical mirror exception (Check 24); bare ref correct at client-installed location",
```

After:

```python
# Project-side HELP-FRAGMENT companion (referenced from
# pack-ops/HELP-FRAGMENT-TRACKER.md and from project-template/docs/
# pack/HELP-FRAGMENT-TRACKER.md). Per BD-194 the pack-side and
# project-side HELP-FRAGMENT-TRACKER.md files are SEPARATE artifacts
# with SEPARATE audiences (feedback_pack_project_separation_of_concerns,
# user-locked 2026-05-26); the previous "byte-identical mirror"
# rationale is retired with Check 24. The bare ref is correct at the
# client-installed location (resolves to docs/pack/HELP-FRAGMENT.md
# in the client repo as a same-dir sibling). Resolves via Check 41
# _CLIENT_INSTALLED_FILES.
"HELP-FRAGMENT.md": "Project-side mirror exception; resolves at client-installed location (see Check 41 _CLIENT_INSTALLED_FILES)",
```

The rationale string aligns with the architect §5.2 drafted text. The
preceding multi-line comment was rewritten to (a) acknowledge BOTH
pack-side and project-side tracker fragments rather than a "byte-
identical mirror" relationship, (b) cite the user-locked pack memory
anchor by name, (c) preserve the existing same-dir-sibling resolution
explanation (still correct), (d) name Check 41 as the resolution path
(replacing the implicit Check-24 framing).

### §6.2 `_CHECK_43_ALLOWLIST` `HELP-FRAGMENT-TRACKER.md` entry (L5126)

Before:

```python
"HELP-FRAGMENT-TRACKER.md": "Project-side docs/pack/HELP-FRAGMENT-TRACKER.md (client-installed; byte-identical mirror per Check 24)",
```

After:

```python
"HELP-FRAGMENT-TRACKER.md": "Project-side docs/pack/HELP-FRAGMENT-TRACKER.md (client-installed; per-surface authoritative per BD-193 F4/F5 + BD-194)",
```

Aligns with the architect §5.2 drafted text. The post-BD-194 rationale
cites the architectural-correction provenance (BD-193 F4/F5 separation
contract + BD-194 Check 24 retirement) rather than the now-retired
byte-identity contract.

### §6.3 No edits made (architect §5.2 flagged "future reviewer awareness only")

- `scripts/validate-pack.py:4051` — Check 37 anchor-phrase comment
  mentions `HELP-FRAGMENT-TRACKER.md:49` as a worked example of the
  pack-vs-project disambiguation anchor-phrase pattern. The cited
  line 49 is the cross-reference line referencing `tracker.toml.pack-
  example` "in the pack repo"; this is the canonical anchor-phrase
  context window. Per architect §5.2: "The cited
  `HELP-FRAGMENT-TRACKER.md:49` reference may drift under future
  content divergence; the anchor-phrase pattern is described abstractly
  but the SPECIFIC line citation will need a comment-only refresh if
  the future evolution lands a divergent change. No immediate edit
  needed; flagged for future reviewer awareness." Confirmed: today's
  content has the cited line at L49 verbatim; no edit needed.

---

## §7 Test file updates

### §7.1 Discovery

The spawn prompt §Coder edits item 2 authorizes: "`scripts/tests/` test
files (if applicable): identify any test file that exercises Check
22/23/24; update per architect §5.5 test plan." A grep audit during
the coder pass surfaced TWO test files whose assertions exercise the
SUBSTANCE of Check 24's contract (the pack-side-to-client byte-identity
DELTA L1 invariant) independently from validate-pack itself:

1. `scripts/tests/test-init-project.sh:181-187` — test 3.3
2. `scripts/tests/test-migrate-v10-to-v11.sh:151-157` — test 2.5

Both tests do their own `cmp -s` between the pack-side canonical at
`$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md` and the client install
copy at `$T/docs/pack/HELP-FRAGMENT-TRACKER.md`. They invoke neither
validate-pack.py nor the retired `check_help_fragment_tracker_byte_identity`
function — they assert the same architectural invariant directly.

Neither the architect doc nor the planner doc enumerated these test
files (architect §5.5 test plan lists only `python3 scripts/validate-pack.py`,
a manual divergence test, and Check 40/43 per-check tests; planner §3.3
lists existing per-check test files but doesn't survey integration
tests). This is a planner-discovery-class finding.

### §7.2 Rationale for in-scope update

Per the spawn prompt's directive "identify any test file that exercises
Check 22/23/24", these tests exercise the SUBSTANCE of Check 24
(byte-identity contract DELTA L1). Under the BD-194 architectural
reframing, those assertions are STALE — they assert the wrong invariant:

- Pre-BD-194 invariant: pack-side canonical and client install are
  byte-identical (DELTA L1 contract — `init-project.sh` S11 was supposed
  to force-copy from pack-side).
- Post-BD-193 F4/F5 actual: `init-project.sh` S11 + `migrate-v10-to-v11.sh`
  S5 copy the client install from the PROJECT-TEMPLATE-side source
  (`$PACK/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`). The
  pack-side and project-side files are SEPARATE artifacts.
- Post-BD-194 correct invariant: the client install copy MUST match the
  project-template-side source (the install-source contract).

Today's HEAD has byte-identical pack-side and project-side content, so
the stale tests still PASS — but they assert the WRONG invariant going
forward. The first intentional pack-side-only or project-side-only
divergence will cause these tests to FAIL even though the install
behavior is correct, recreating exactly the architectural debt that
BD-194 retires elsewhere.

### §7.3 Edits applied

**`scripts/tests/test-init-project.sh:181-187` (test 3.3):**

Before:

```bash
# DELTA L1: client HELP-FRAGMENT-TRACKER.md is byte-identical to pack-side canonical.
# BD-175: pack-side canonical relocated from REPO_ROOT to REPO_ROOT/pack-ops/.
if cmp -s "$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md" "$T/docs/pack/HELP-FRAGMENT-TRACKER.md"; then
    t_pass "3.3 client HELP-FRAGMENT-TRACKER.md byte-identical to pack-side canonical (DELTA L1)"
else
    t_fail "3.3 byte-identity violated (DELTA L1)"
fi
```

After:

```bash
# BD-193 F4/F5 + BD-194: client HELP-FRAGMENT-TRACKER.md install source is the
# project-template-side file (separate-artifact, separate-audience per pack memory
# feedback_pack_project_separation_of_concerns). The pack-side
# pack-ops/HELP-FRAGMENT-TRACKER.md is a SEPARATE artifact with a SEPARATE
# audience and is NOT the install source. Test asserts the install copy matches
# the project-template-side source (init-project.sh S11 contract per BD-193 F4/F5).
if cmp -s "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md" "$T/docs/pack/HELP-FRAGMENT-TRACKER.md"; then
    t_pass "3.3 client HELP-FRAGMENT-TRACKER.md matches project-template-side install source (BD-193 F4/F5)"
else
    t_fail "3.3 install-source mismatch (expected: project-template/docs/pack/HELP-FRAGMENT-TRACKER.md)"
fi
```

**`scripts/tests/test-migrate-v10-to-v11.sh:151-157` (test 2.5):**

Before:

```bash
# DELTA L1: client tracker fragment byte-identical to pack-side canonical.
# BD-175: pack-side canonical relocated from REPO_ROOT to REPO_ROOT/pack-ops/.
if cmp -s "$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md" "$T/docs/pack/HELP-FRAGMENT-TRACKER.md"; then
    t_pass "2.5 HELP-FRAGMENT-TRACKER.md byte-identical to pack-side canonical (DELTA L1)"
else
    t_fail "2.5 byte-identity violated"
fi
```

After:

```bash
# BD-193 F4/F5 + BD-194: migrate-v10-to-v11.sh S5 install source for the client
# tracker fragment is the project-template-side file (separate-artifact, separate-
# audience per pack memory feedback_pack_project_separation_of_concerns).
# Test asserts the install copy matches the project-template-side source
# (migrator S5 contract per BD-193 F4/F5).
if cmp -s "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md" "$T/docs/pack/HELP-FRAGMENT-TRACKER.md"; then
    t_pass "2.5 HELP-FRAGMENT-TRACKER.md matches project-template-side install source (BD-193 F4/F5)"
else
    t_fail "2.5 install-source mismatch (expected: project-template/docs/pack/HELP-FRAGMENT-TRACKER.md)"
fi
```

### §7.4 Syntactic validation

Both test files pass `bash -n` syntax check:

```
$ bash -n scripts/tests/test-init-project.sh && bash -n scripts/tests/test-migrate-v10-to-v11.sh && echo "Both syntactically valid"
Both syntactically valid
```

Integration test runtime execution NOT performed by the coder: these
tests execute `init-project.sh` and `migrate-v10-to-v11.sh` against
mktemp scratch repos which would be infrastructure provisioning per
pack memory `feedback_test_infra_self_provisioned`. The substance
change is identical (different file path; same `cmp -s` mechanism) so
syntactic validation is sufficient at this pass; reviewer pass may run
them if desired.

### §7.5 Coverage of Check 22 / Check 23

No test file in `scripts/tests/` exercises Check 22 or Check 23
specifically (planner §3.3 confirmed). The Check 22 per-surface fix
+ Check 23 fail-loud modification are exercised by the validate-pack
self-test (Gate G1 PASSED at coder pass — see §9.1).

---

## §8 Manifest regen details

### §8.1 Trigger evaluation

Per CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface
commit": this commit touches files under `scripts/` (`validate-pack.py`,
`tests/test-init-project.sh`, `tests/test-migrate-v10-to-v11.sh`). The
v11-surface trigger fires. Coder ran `bash test-fixtures/build.sh --all
--clean` from pack root.

### §8.2 Build output

All 6 fixtures rebuilt cleanly:

```
v10-minimal              19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot         4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot         01e8aa40fabc464f149d459f912d4e9f10651c59
v11-flat-file            2cf7c719901aeb29d6354d2d6d0e78366f79bc68
v11-tracker-on           f51b4d3d48b8682fcff30bc7b9e0d1672d824c38
existing-project-mid-dev a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

### §8.3 Diff result

```
$ git diff test-fixtures/manifest.txt
(empty)
```

The manifest is unchanged. Initially this appeared to be a regression
(scripts/ changes should propagate to v11-* fixture SHAs), but
investigation confirmed it is the CORRECT outcome:

- `scripts/init-project.sh` stage S5 copies from
  `$PACK/project-template/scripts/` (NOT from `$PACK/scripts/`). The
  pack-internal `scripts/` directory is NOT mass-installed at client
  init.
- `scripts/validate-pack.py` is a pack-internal CI helper; not in any
  client install surface.
- `scripts/tests/test-init-project.sh` and `test-migrate-v10-to-v11.sh`
  are pack-internal CI tests; not in any client install surface.

The v11 fixtures (`v11-flat-file`, `v11-realistic-ot`, `v11-tracker-on`,
`v11-trinity-marker-prepped` — only first 3 in current manifest) capture
the CLIENT-INSTALLED surface that `init-project.sh` produces. Since the
modified files are NOT mass-copied to clients, the fixture SHAs do not
drift, and the manifest diff is legitimately empty.

The trigger fired (rebuild happened, all 6 fixtures rebuilt
deterministically); the diff result (empty) is verified clean. v10-*
SHAs unchanged (tag-pinned per `test-fixtures/README.md` § Determinism);
no v10 leak.

### §8.4 Rule compliance

Per the trigger's intentionally-inclusive design (CLAUDE.md "false
positives ... cost ~30-90s of unnecessary rebuild but produce no
incorrect manifest change"): this rebuild was a CORRECT
false-positive — the trigger fired on the directory-wide rule, the
manifest was verified, no staging needed. The rule is satisfied.

---

## §9 Verification results

### §9.1 Gate G1 — validate-pack.py PASS at new invoked-check count

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
```

Invoked-check count post-BD-194:

- 38 numbered checks: 1-11 (11), 16-23 (8), 25-43 (19) = 38
- 2 unnumbered informational: `issue-template-forms`, `template-archive-v11`
- TOTAL: 40 invoked checks (was 41 pre-BD-194)

Check 24 does NOT appear in the output. Check 22 + Check 23 + Check 41
all PASS.

### §9.2 Gate G2 — Check 24 identifier purge

```
$ grep -n "check_help_fragment_tracker_byte_identity\|byte-identity\|Check 24" scripts/validate-pack.py
63:      HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1; superseded
68:      SEPARATE audiences; byte-identity is coincidence, not contract.
2178:# ── Check 24 RETIRED in BD-194 (per ARCHITECTURE-BD-194.md Candidate 6).
4778:    # rationale is retired with Check 24. The bare ref is correct at the
6079:    # ── Check 24 callsite removed in BD-194 (Candidate 6). See
6081:    # the former check_help_fragment_tracker_byte_identity location.
```

5 occurrences remain; all are INTENTIONAL retirement / audit-trail
prose per architect §5.4 step 3 + planner G2 "the check-list comment
at L62-64 may carry a single retirement note line referencing 'Check 24'
— that is INTENTIONAL audit-trail prose and is acceptable":

| Line | Category | Architect/Planner authority |
|---|---|---|
| L63, L68 | Check-list comment retirement note | architect §5.4 step 3 (drafted text contains "Check 24" + "byte-identity") |
| L2178 | Function-deletion placeholder block | follows architect §5.4 step 1 (function removed; replaced with named retirement comment) |
| L4778 | Allowlist rationale comment (explaining what was retired) | architect §5.2 + planner §3.4 |
| L6079, L6081 | Callsite-removal retirement note | follows architect §5.4 step 2 (callsite removed; replaced with named retirement comment) |

Live function name, function definition, callsite, and forbidden
allowlist phrases ("byte-identical mirror per Check 24", "Byte-identical
mirror exception (Check 24)") are all PURGED.

### §9.3 Gate G3 — Allowlist rationale text purge

```
$ grep -n "byte-identical mirror\|Byte-identical mirror exception" scripts/validate-pack.py
4777:    # user-locked 2026-05-26); the previous "byte-identical mirror"
```

The only remaining "byte-identical mirror" occurrence is in a comment
explaining what was retired (past-tense quotation context). The
ACTIVE rationale strings at L4770 (now `_BARE_REFERENCE_EXEMPTIONS`
HELP-FRAGMENT.md value) and L5126 (now `_CHECK_43_ALLOWLIST`
HELP-FRAGMENT-TRACKER.md value) no longer contain the forbidden
phrases:

```
$ grep -n "Byte-identical mirror exception\|byte-identical mirror per Check 24" scripts/validate-pack.py
(empty)
```

Gate G3 PASS.

### §9.4 Gate G4 — Manifest regeneration

See §8 above. Trigger fired; rebuild executed; manifest verified clean;
no staging required.

### §9.5 Gate G6 — Local divergence smoke test (optional; performed)

Per planner §5.6 G6 — performed and reverted clean.

**Procedure executed:**

1. Added a single-line `<!-- BD-194 smoke test: pack-side-only divergence -->`
   comment to `pack-ops/HELP-FRAGMENT-TRACKER.md` (single-surface
   divergence; pack-side acquires a comment line not present project-
   template-side).
2. Ran `python3 scripts/validate-pack.py`. Result: PASSED — all checks
   clean.

This confirms the architectural correction works end-to-end. Under
pre-BD-194 code, this divergence would have caused Check 24 to FAIL
with "byte-identity violated". Under post-BD-194 code, the validation
PASSes because each surface's tracker fragment is treated
independently (Check 22 per-surface) and pack-side existence is
satisfied (Check 23). The divergence is allowed.

3. Reverted the change. `git diff pack-ops/HELP-FRAGMENT-TRACKER.md`
   confirms empty — clean revert.

### §9.6 Test file syntactic validation

```
$ bash -n scripts/tests/test-init-project.sh && bash -n scripts/tests/test-migrate-v10-to-v11.sh && echo "Both syntactically valid"
Both syntactically valid
```

---

## §10 Pack Chat handoff — PM-only files to edit at commit-staging

Per spawn prompt §"Pack Chat edits (NOT you)", the following PM-only
files are NOT touched by this coder pass. Pack Chat applies them at
commit-staging time, in the SAME commit as the coder edits per POQ-2
(architect §7.2 — single-commit shape user-approved).

### §10.1 `README.md` (4 edits per planner §3.2)

- **L60 version-table v11.0 row prose.** Edit "validate-pack.py
  expanded to 41 invoked checks (39 numbered Check 1–11 and 16–43;
  ..." to "validate-pack.py expanded to 40 invoked checks (38
  numbered Check 1–11, 16–23, 25–43; ..." plus update the retirement
  clause to include "; Check 24 retired per BD-194". Suggested final
  prose per architect §6.5:

  > "40 invoked checks (38 numbered Check 1–11, 16–23, 25–43; 2
  > unnumbered informational — issue-template-forms and
  > template-archive-v11; Checks 12–15 retired per v9 sunset; Check 24
  > retired per BD-194 (HELP-FRAGMENT-TRACKER byte-identity superseded
  > by per-surface existence coverage))"

- **L107 Repository Layout note for client-installed
  HELP-FRAGMENT-TRACKER.md.** Replace "Shared tracker section (v11;
  byte-identical to pack root, DELTA L1)" with the per-surface variant.
  Suggested: "Client-installed tracker section (v11; project-side
  authoritative per BD-193 F4/F5)".

- **L195 Repository Layout note for `validate-pack.py`.** Update "41
  invoked checks" to "40 invoked checks" and retirement clause
  matching L60.

- **L272 Repository Layout note for pack-side
  HELP-FRAGMENT-TRACKER.md.** Replace "Shared tracker section (v11;
  canonical; mirrored to project-template/docs/pack/)" with per-surface
  variant. Suggested: "Pack-side tracker section (v11; pack-developer
  audience; per-surface authoritative per BD-194)".

### §10.2 Pack-root trinity (3 edits per planner §3.4.1 + §8 POQ-1 Option A)

Per spawn prompt §User-locked decisions item 5 (Planner POQ-1: Pack-root
trinity edits INCLUDED in commit) and item 6 (Planner POQ-2: Drop "byte-
identical mirrors per CI Check 24" clause entirely):

- **`CLAUDE.md:505`** — Drop "byte-identical mirrors per CI Check 24,"
  clause from the Filename uniqueness heuristic exemption-class list.
  Resulting prose (per planner §8 POQ-1 Option A sub-option A):

  > "...trinity files, per-skill `SKILL.md`, ecosystem-fixed names like
  > `.gitignore` / `pyproject.toml` / `Package.swift`..."

- **`AGENTS.md:466`** — Same edit (trinity parity per CLAUDE.md trinity
  rule).

- **`GEMINI.md:436`** — Same edit (trinity parity).

All three edits are byte-identical text changes per the trinity-rule
parity requirement; no provably tool-specific variation.

### §10.3 Surfaced — out-of-scope stale references for Pack Chat triage

Per planner §7.1 "The coder MAY also surface (in the IMPL-REPORT, NOT
edit) any incidental stale references discovered during the edit", the
following stale "Check 24" references were found in pack-shipped
surfaces but NOT edited (out of scope per spawn prompt §"Out of scope"
or per pack memory rules):

1. **`scripts/init-project.sh:809-814`** — Comment block for stage S11
   HELP-FRAGMENT*.md install. Contains: "HELP-FRAGMENT-TRACKER.md is
   byte-identity-required across pack-root and client mirror per DELTA
   L1 (validate-pack Check 24); force-copy from pack-root canonical
   regardless of class so an existing-* re-run cannot leave stale
   tracker fragments in place." This comment is FACTUALLY STALE
   post-BD-193 F4/F5 (the install source is project-template-side, not
   pack-root canonical) AND post-BD-194 (no byte-identity contract).
   The next 8 lines (L820-828) already carry the post-BD-193 F4/F5
   corrected comment — the L809-814 prose is leftover from a partial
   prior update. Out of scope for BD-194 coder edits per spawn prompt
   (only `scripts/validate-pack.py` and `scripts/tests/` files listed).
   **Triage suggestion**: Pack Chat could fold this into the BD-194
   commit (one-line comment cleanup; same logical-fit class as the
   allowlist comment updates per `feedback_deferral_is_scope_creep`
   LOGICAL FIT) OR defer to a follow-on commit. If deferring, anchor
   to a new BD or attach to an upcoming `init-project.sh`-affecting BD.

2. **`project-template/skills/boundary-investigation/SKILL.md:107`** —
   Contains: "...the pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md`
   per CI Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`)..."
   This is in the deny-list-content block for project-side boundary
   investigation. The reference to "CI Check 24 byte-identity contract"
   becomes STALE post-BD-194. Out of scope for BD-194 coder edits per
   spawn prompt §3 "project-template/CLAUDE.md / AGENTS.md / GEMINI.md
   (PROJECT-side trinity; PM-only AND not in scope — the stale
   reference is at PACK-ROOT trinity, not project-template trinity)" —
   while the spawn prompt §3 explicitly lists only project-template
   trinity, the broader category "project-template files" is
   structurally similar (all project-side, PM-only writability).
   **P-missed-7 SSOT check**: this file is a project-side skill;
   the project-side SSOT for skill content is the skill's own
   `SKILL.md` (this same file). The reference to a pack-internal CI
   check from a project-side skill is a P-missed-7 leak class —
   project-side skills shouldn't operationally depend on pack-internal
   CI checks. **Triage suggestion**: Pack Chat could (a) defer with
   user discussion to a separate boundary-discipline cleanup BD,
   (b) fold into this commit as a project-side PM-only edit (Pack Chat
   has authority to edit project-template skill content directly via
   the broader PM-only file class), or (c) propose this as a separate
   pre-BD-185 H.2 spawn. NIT severity; not blocking BD-194.

3. **`pack-ops/CHANGELOG.md:62, L410`** and **`pack-ops/BACKLOG.md`
   multiple lines (L280, L357, L378, L382, L392, L401-402, L1434,
   L2447, L2451-2452, L3061, L3072, L3076, L3084, L3092, L3094,
   L3115, L3120)** — Historical changelog and backlog references to
   "Check 24" / "byte-identity per Check 24". These are historical
   audit-trail records (BACKLOG.md / CHANGELOG.md by definition record
   what was true at the time of each entry). Per CLAUDE.md
   "What agents must never modify without explicit instruction" (PM
   chat only) AND per `pack-ops/CHANGELOG.md` being a regenerated mirror
   of the per-entry `/changelog/` tree. NO EDIT — these are correctly
   stale by-design audit records. The BD-194 entry at L3076-3124 will
   pick up the architect/planner/IMPL-REPORT cross-references at
   end-of-batch when Pack Chat closes BD-194; that resolution will
   naturally cite "Check 24 RETIRED" in the Resolved: line.

4. **`scripts/tests/test-per-entry.sh:303, L333, L338`,
   `scripts/tests/test-v11-realistic-ot.sh:13`,
   `scripts/tests/test-init-project.sh:216, L284`,
   `scripts/tests/test-tracker-links.sh:27, L204`,
   `scripts/persona-contracts/contract-migration.sh:147`,
   `scripts/lib/tracker-phase-task.sh:452, L478`,
   `scripts/lib/per-entry/mirror-generate.sh:81`** — These references
   to "byte-identity" are about UNRELATED byte-identity contracts
   (per-entry mirror round-trip per BD-164/168, tracker-link round-trip
   per V3.3 §5.3, BD-106 phase-task round-trip, mirror-generate
   round-trip). These are SEPARATE invariants that REMAIN ACTIVE under
   BD-194. No edit needed.

5. **`maintenance-docs/archive/v11/` historical artifacts** — Per
   CLAUDE.md "Skill and agent maintenance is mechanical by default"
   Pattern B sweep rule, archived artifacts are NOT edited
   post-archival (they record what each batch shipped at the time).
   Planner §3.4.5 confirmed.

---

## §11 PREFLIGHT line

PREFLIGHT: 3 files edited (Check 24 retired + Check 23 fail-loud + Check 22 per-surface + 2 allowlist comment updates + 2 test-file install-source assertion updates); manifest regenerated (no diff — modified files are pack-internal CI, not client-installed); validate-pack.py PASS at 40 invoked checks; Check 24 identifier purge clean (5 retirement / audit-trail prose references remain per architect §5.4 + planner G2); HEAD 85702434bd8771fc964c89565491bb75e2ceec01; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md

---

## §12 Plan deviations + new POQs

### §12.1 Plan deviations

**One deviation from architect doc + planner doc:** updated 2 test files
(`scripts/tests/test-init-project.sh` + `test-migrate-v10-to-v11.sh`)
that exercise the substance of Check 24's DELTA L1 byte-identity
contract via direct `cmp -s`. Neither the architect nor planner doc
enumerated these test files; they were planner-discovery-class findings
at coder pass. Per spawn prompt §"Coder edits (you)" item 2
("`scripts/tests/` test files (if applicable): identify any test file
that exercises Check 22/23/24; update per architect §5.5 test plan"),
these tests exercise the SUBSTANCE of Check 24 and the spawn prompt
explicitly authorizes coder edits to such test files.

The test edits ALIGN with the architect §4 Candidate 6 design (each
surface's content is per-surface authoritative, not cross-surface
byte-identical) and the BD-193 F4/F5 install-source contract
(`init-project.sh` S11 / `migrate-v10-to-v11.sh` S5 both copy from
project-template-side). Without the test edits, those tests would
preserve the stale DELTA L1 byte-identity assertion and would FAIL on
the first intentional divergence (recreating the same architectural
bug BD-194 retires elsewhere).

Reviewer pass may verify this deviation is in-scope. If reviewer
disagrees, the test edits can be reverted in a follow-on commit; the
validate-pack.py edits are not coupled.

### §12.2 New POQs introduced

NONE.

### §12.3 No-edit items requiring Pack Chat triage

See §10.3 above for 5 surfaced-but-not-edited stale-reference classes.

---

## §13 Definition-of-Done checklist

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Check 24 fully retired (function + callsite + check-list comment) | PASS | §3.1 + §3.2 + §3.3 |
| 2 | Check 23 fail-loud modification applied | PASS | §4.1 + §4.2 |
| 3 | Check 22 per-surface tracker fragment fix applied | PASS | §5.1 + §5.2 + §5.3 |
| 4 | Allowlist comment updates applied per architect §5.2 drafted text | PASS | §6.1 + §6.2 + §6.3 |
| 5 | Manifest regenerated; staged | PASS (regen ran; diff clean by design) | §8 |
| 6 | validate-pack.py PASS at NEW invoked-count (40) | PASS | §9.1 |
| 7 | Check 24 identifier purge complete (zero residual functional occurrences) | PASS | §9.2 |
| 8 | PM-only files NOT touched (Pack Chat handoff intact) | PASS | §10 |
| 9 | PREFLIGHT line emitted | PASS | §11 |
| 10 | IMPL-REPORT written; no state-changing git verbs run | PASS | this file |

Coder pass DoD: 10/10 PASS.

---

## §14 Files-changed inventory

| Path | Change type | Owner |
|---|---|---|
| `scripts/validate-pack.py` | modified | pack-coder |
| `scripts/tests/test-init-project.sh` | modified | pack-coder |
| `scripts/tests/test-migrate-v10-to-v11.sh` | modified | pack-coder |
| `test-fixtures/manifest.txt` | regenerated (no diff) | pack-coder (regen ran; staging optional since diff empty) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` | new file (architect pass, present at coder pass start) | pack-architect |
| `maintenance-docs/v11-implementation/PLAN-BD-194.md` | new file (planner pass, present at coder pass start) | pack-planner |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md` | new file (this report) | pack-coder |
| `README.md` | NOT TOUCHED — Pack Chat applies per §10.1 | Pack Chat (PM-only) |
| `CLAUDE.md` (pack root) | NOT TOUCHED — Pack Chat applies per §10.2 | Pack Chat (PM-only) |
| `AGENTS.md` (pack root) | NOT TOUCHED — Pack Chat applies per §10.2 | Pack Chat (PM-only) |
| `GEMINI.md` (pack root) | NOT TOUCHED — Pack Chat applies per §10.2 | Pack Chat (PM-only) |

---

## §15 Cross-references

### §15.1 Architect deliverable

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (1179
  lines; Candidate 6 user-approved)
  - §2.4 — Check 24 current implementation referenced and verbatim-
    captured for retirement
  - §4 — Candidate 6 recommended design (this coder pass implements)
  - §5.1 — Check 22 + Check 23 + Check 24 signature changes (implemented)
  - §5.2 — Allowlist comment updates (implemented at L4762-4770 +
    L5126; L4051 documented as no-edit-needed per §6.3)
  - §5.4 — Step-by-step replacement logic (implemented per §2-§7
    above)
  - §5.5 — Test plan (executed: validate-pack PASS at §9.1; local
    divergence smoke at §9.5; no per-check tests added per architect
    §5.3)

### §15.2 Planner deliverable

- `maintenance-docs/v11-implementation/PLAN-BD-194.md` (946 lines;
  single-commit plan user-approved)
  - §4.2 — Edit sequencing (followed: Check 24 → Check 23 → Check 22
    → allowlist comments → PREFLIGHT → manifest)
  - §5.1 G1 — validate-pack.py PASS at 40 invoked checks (achieved)
  - §5.2 G2 — Check 24 identifier purge (achieved)
  - §5.3 G3 — allowlist rationale text purge (achieved)
  - §5.4 G4 — manifest regen per RC9 (executed; empty diff verified
    clean by design)
  - §5.5 G5 — PREFLIGHT line emitted (§11)
  - §5.6 G6 — local divergence smoke test (executed; reverted clean)
  - §7.1 — pack-coder scope (followed; surfaced stale refs per §10.3)
  - §7.5 — out-of-scope for coder pass (preserved)

### §15.3 BD-194 entry

- `pack-ops/BACKLOG.md:3076-3124` (BD-194 Open at HEAD; Position
  Batch 19d-prep-3; Blockers: BD-193 Resolved; Unblocks: BD-185 H.2;
  Pipeline: architect → user review → planner → user review → coder →
  reviewer). End-of-batch status flip to Resolved is Pack Chat action
  per `feedback_implicit_status_flip`.

### §15.4 Pack memory anchors (governing rules)

- `feedback_pack_project_separation_of_concerns` — user-locked
  2026-05-26; authoritative architectural principle Candidate 6
  expresses.
- `feedback_deferral_is_scope_creep` — applied via Check 22 fix
  in-scope (LOGICAL FIT per architect §4.3 + POQ-1 user-locked).
- `feedback_pack_coder_preflight_pattern` — PREFLIGHT line at §11.
- `feedback_manifest_regen_on_v11_surface` — trigger fired (§8).
- `feedback_agents_never_commit` — coder pass produces report + working-
  tree edits; no `git add` / `git commit` / `git push` / `git tag` /
  `git rebase` / `git merge` / `git reset` / `git stash` / `git
  checkout` (state-changing) executed.

### §15.5 Related architect docs (read-only context for reviewer)

- `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
  §1.4 — Check 43 allowlist contract context for §6.2 edit.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` §5.3 —
  Check 41 `_CLIENT_INSTALLED_FILES` integrity contract Candidate 6
  relies on (cited in §3.1 retirement comment + §4.2 docstring).
- BD-193 IMPL-REPORTs (Code Red 2; the F4/F5 source-of-truth correction
  this coder pass operates against).

---

*End of coder deliverable.*
