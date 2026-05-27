# ARCHITECTURE-BD-194.md — Check 24 byte-identity gate replacement

Status: ARCHITECT DELIVERABLE — design recommendation pending user review.
HEAD SHA at architect pass: `8570243` (`85702434bd8771fc964c89565491bb75e2ceec01`).
Author: pack-architect; produced 2026-05-27 per BD-194 pipeline.
Read-only against working tree; no source modified during this pass.

---

## §1 Scope & Background

### §1.1 BD-194 problem statement

`scripts/validate-pack.py` Check 24 (`check_help_fragment_tracker_byte_identity`)
enforces byte-identity between:

- `pack-ops/HELP-FRAGMENT-TRACKER.md` (pack-side; audience: pack-developers
  running `pack help` against the pack repo itself)
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (project-side;
  authoritative copy that `scripts/init-project.sh` stage S11 copies to
  client `docs/pack/HELP-FRAGMENT-TRACKER.md`)

BD-193 Code Red 2 cleanup (F4/F5) corrected `scripts/init-project.sh` S11
to source the client-installed file from the project-side path (not from
`pack-ops/`). The two files are now declared SEPARATE artifacts with
SEPARATE audiences per the user-locked pack memory
`feedback_pack_project_separation_of_concerns` (locked 2026-05-26).

Check 24's byte-identity invariant contradicts this separation rule.
The check currently PASSES (both files are byte-identical at HEAD —
49 lines each, `diff` returns empty), but this is a SNAPSHOT of today's
content, not a designed contract. The first intentional pack-side or
project-side divergence will trigger a CI failure on a check that
enforces the wrong invariant.

### §1.2 Pack memory anchors

Authoritative rules this design must satisfy:

- `feedback_pack_project_separation_of_concerns` — pack-side and
  project-side versions of any doc/file are SEPARATE artifacts with
  SEPARATE audiences; pack version NEVER a fallback for project version
  (or vice versa); byte-identity is COINCIDENCE not design rationale.
  User-locked 2026-05-26 during BD-185 Code Red 2.
- `feedback_bd_pack_only_operational_rule` — client-facing content MUST
  NOT operationally treat BDs; MAY reference in MIGRATION/glossary
  contexts. Relevant because the project-side HELP-FRAGMENT-TRACKER is
  client-facing.
- `feedback_client_facing_token_economy` — client-facing docs get
  RAG-indexed; pack-only references waste tokens. Reinforces the
  separation rule's content-divergence direction.
- `feedback_preliminary_triage_architect_challenge` — preliminary
  candidates must be challenged; pattern reuse must be evidence-based,
  not pattern-matching out of context.
- `feedback_pattern_matching_out_of_context_antipattern` — adopting
  pattern A for use case B without verifying property-fit is anti-design.

### §1.3 Cited HEAD-SHA evidence

- Working tree HEAD: `8570243`.
- `pack-ops/HELP-FRAGMENT-TRACKER.md`: 49 lines, byte-identical to
  `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (verified by
  `diff` returning empty).
- BD-194 entry: `pack-ops/BACKLOG.md:3076-3124` (mirror; per-entry tree
  pending Batch 23 per BD-102 dog-food).
- BD-193 Phase 4 review §5.6 (M-8 finding):
  `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md`
  L701-722 (the originating finding).

### §1.4 Boundary discipline (P-missed-7 application)

This BD operates ACROSS the pack/project boundary. Per the pack memory
`P-missed-7` rule and the `boundary-investigation` skill:

- `pack-ops/HELP-FRAGMENT-TRACKER.md` lives on the PACK SIDE; its audience
  is pack-developers; rules governing its content are pack-side SSOTs.
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` lives on the
  PROJECT TEMPLATE SIDE; its audience is client-project users; rules
  governing its content are project-side SSOTs.
- The check function `check_help_fragment_tracker_byte_identity` lives
  in `scripts/validate-pack.py` (PACK SIDE — this is pack-internal CI
  tooling) but its assertion crosses the boundary.

Implication for design: any invariant proposed MUST be expressible
without coupling pack-side content authority to project-side content
authority. Byte-identity does exactly that coupling; the replacement
must NOT.

---

## §2 Investigation findings

### §2.1 File content (HEAD `8570243`)

Both files are 49 lines, byte-identical. The structure is:

- L1: title `# Tracker commands (v11+)`
- L2-L6: 4-line prose intro on tracker mode (opt-in, mirror semantics,
  reversibility)
- L7-L15: 7-row "verb-table" listing `pack tracker <verb>` commands and
  one-line descriptions
- L17-L33: `## TD promotion (v11+)` section — title, 4-line prose intro,
  3-row verb-table for `pack td <verb>` commands, Path 3 forbidden note
- L34-L47: `## Colloquial mappings` section — title, 13-row phrase→verb
  mapping table covering both `pack tracker` and `pack td` verbs
- L48: blank line
- L49: "See the tracker example template (...) and `OPTIONAL-FEATURES.md`
  for full setup." cross-reference

This is a USER-FACING REFERENCE FRAGMENT. It is rendered (along with the
per-surface `HELP-FRAGMENT-PACK.md` or `HELP-FRAGMENT.md`) by `pack-help.sh`
when a user types `pack help`.

### §2.2 Natural divergence patterns (what would arise as audiences evolve)

The content fits the question "what `pack <verb>` commands can a user run
against this surface?" The pack-side surface and project-side surface
both expose the same `pack tracker ...` and `pack td ...` verb namespace
TODAY. Realistic divergence drivers:

1. **Surface-specific verbs.** If a future pack-side admin verb (e.g.,
   `pack archive-baseline`) ships for pack-developers only and is NOT
   wired into client install, the verb-tables MUST diverge: pack-side
   admits the row; project-side does NOT. This is the closest analog to
   the BD-193 F2.c precedent (`bd` wi-type option for forms — admitted
   pack-side, excluded project-side).
2. **Audience-specific phrasing.** Description text may diverge for the
   same verb if the audience phrasing changes — e.g., pack-side could
   reference "pack repo" while project-side references "your project."
   Currently description text is identical and audience-neutral.
3. **Cross-reference targets.** Line 49 references
   `tracker.toml.pack-example` (pack-side specific filename) AND
   `tracker.toml.example` (client-side specific filename) — currently
   handled by mentioning BOTH parenthetically. As content evolves, each
   surface could simplify to its own filename only.
4. **Verb-order or section-order preferences.** Operational ordering
   may differ if a future verb is more or less prominent in one
   audience.
5. **Glossary / explanatory footnotes.** Pack-side might add an
   architectural cross-reference (e.g., to a `maintenance-docs/`
   architect doc) that doesn't belong client-side per the
   `feedback_client_facing_token_economy` rule.

Implication: divergence is GUARANTEED long-term; the question is whether
the CI gate ALLOWS it or BLOCKS it. Today's byte-identity blocks all of
the above.

### §2.3 `check_issue_template_forms` pattern survey

Per `scripts/validate-pack.py` L1067-1179, `check_issue_template_forms`
is the closest existing per-surface analog:

```python
expected_wi_type_options_per_surface = {
    "pack-root": {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"},
    "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
}
```

Mechanics:
- Iterates over a list of `(surface_label, surface_dir)` pairs.
- For each surface, loads files and asserts they (a) exist, (b) parse,
  (c) contain the required structural keys, (d) have surface-specific
  expected options.
- Failures are reported with the surface label inline.

Maintenance pattern: a third surface needs a third dict entry + a third
tuple in the surfaces list. A new option added to one surface only is
encoded in the per-surface set. The OK-message includes per-surface
context.

Test pattern: `scripts/tests/test-issue-forms.sh` (78 tests, surface-aware
via 3rd-arg `surface_kind`) provides per-surface invariants.

Property-fit assessment for HELP-FRAGMENT-TRACKER:
- **MATCH:** there is a structural skeleton (sections, table headers,
  verb-row mentions) that can be expressed as per-surface expected sets.
- **MATCH:** the BD-193 F2.c precedent established that "pack admits X,
  project does NOT" is the natural shape of a content-divergent gate.
- **PARTIAL MATCH:** `check_issue_template_forms` operates on STRUCTURED
  YAML (form schemas) where the relevant assertions are over enum-typed
  fields. HELP-FRAGMENT-TRACKER is FREEFORM MARKDOWN. The closest
  structured surface inside it is the markdown verb-tables (which are
  parseable but not as schema-typed as YAML).
- **CAVEAT:** the issue-template gate has a CLEAR scope (form schemas
  loaded into GitHub Issues UI). The HELP-FRAGMENT-TRACKER gate has a
  fuzzier scope (user-facing reference text).

### §2.4 Current Check 24 implementation (`scripts/validate-pack.py:2154-2175`)

```python
def check_help_fragment_tracker_byte_identity() -> None:
    """Check 24 — Shared HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1).

    The tracker fragment is canonical at pack root and mirrored in the
    client template at project-template/docs/pack/. Per DELTA L1 the
    two MUST be byte-identical so install-time copies in BD-080 stage
    S11 produce a faithful client mirror.
    """
    print("\n── Check 24: HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) ──")
    pack_root = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
    client    = REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md"
    if not pack_root.is_file():
        fail(f"pack-root canonical missing: {pack_root.name}")
        return
    if not client.is_file():
        fail(f"client mirror missing: project-template/docs/pack/{client.name}")
        return
    if pack_root.read_bytes() != client.read_bytes():
        fail(f"byte-identity violated: {pack_root.relative_to(REPO_ROOT)} != "
             f"{client.relative_to(REPO_ROOT)}")
        return
    ok(f"HELP-FRAGMENT-TRACKER.md byte-identical across pack-root and client mirror")
```

The docstring rationale ("canonical at pack root and mirrored in the
client template ... so install-time copies in BD-080 stage S11 produce
a faithful client mirror") is THE rationale invalidated by BD-193 F4/F5.
BD-193 F4/F5 corrected S11 to source from the project-template-side
file directly; the pack-root copy is NOT the install source any longer.

Main() callsite is line 6067, ordered between
`check_help_fragment_completeness` (Check 23) and
`check_customization_detection_regression_guard` (Check 25).


### §2.5 Existing test pattern for Check 24

There is NO existing test file for Check 24. Disk survey of
`scripts/tests/` confirms no `test-validate-pack-check-24.sh`
exists. Check 22 / Check 23 likewise have no per-check test file.

Implication: Check 24 has historically relied on its OWN execution as
the test. Any replacement that introduces new behavioral nuance
(per-surface expected content, divergence allowlist, etc.) SHOULD ship
with a dedicated per-check test file per the BD-184 pattern. Per Check 42
(`check_ci_workflow_wires_per_check_tests` at L5919), any new
`test-validate-pack-check-24.sh` MUST be wired into
`.github/workflows/validate-pack.yml`.

### §2.6 Downstream dependencies on byte-identity (audit-trail dependencies)

Code-search-evidence that other CI checks and code carry the byte-identity
assumption in their comments and/or behavior:

#### §2.6.1 Behavioral dependencies — DO NOT auto-break under divergence

1. **Check 22 — `check_help_fragment_freshness` (L1903, L1913-1914).**
   Concatenates `pack-ops/HELP-FRAGMENT-TRACKER.md` to BOTH surfaces'
   HELP-FRAGMENT files for verb-presence comparison:
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
   **Status post-BD-193:** This is now WRONG for the project-template
   surface. If `pack-ops/HELP-FRAGMENT-TRACKER.md` diverges from
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`, Check 22 will
   compare project-template-surface verbs against
   `pack-ops/`-fragment-content, producing false negatives or false
   positives depending on divergence direction. **This is a SEPARATE
   bug latent under the same BD-193 architectural reframing.** Worth
   surfacing.

2. **Check 23 — `check_help_fragment_completeness` (L1970, L1975-1976).**
   Same pattern as Check 22; concatenates pack-side tracker fragment to
   pack-side HELP-FRAGMENT-PACK only. **Status post-BD-193:** Check 23's
   target IS pack-side only, so the concatenation is correct (no
   boundary crossing). Safe.

3. **`pack-help.sh` rendering (L124-150).** Reads ONE fragment per
   surface at runtime; doesn't depend on cross-surface byte-identity.
   Safe.

4. **`scripts/init-project.sh` S11 (L825-832, post-BD-193).** Copies
   project-template-side file to client; pack-side identity irrelevant.
   Safe.

5. **Check 43 leak-sweep exemption (L5217).**
   `_CHECK_43_PACK_OPS_CLIENT_INSTALLED = ("pack-ops/HELP-FRAGMENT-TRACKER.md",)`
   is keyed to the FILE PATH (the pack-side file is exempt from the
   pack-internal-target FAIL because it has a client-installed analog),
   not to byte-identity. Behaviorally safe; comment-only update needed.

6. **Check 40 / Check 43 allowlist comments (L4762-4770, L5126).**
   Use the phrase "byte-identical mirror per Check 24" as the audit-trail
   reason for the `HELP-FRAGMENT.md` and `HELP-FRAGMENT-TRACKER.md`
   exemption entries. **Status post-BD-194:** the rationale text must
   change (no more byte-identity guarantee), but the allowlist BEHAVIOR
   stays correct — both files are still client-installed per
   `_CLIENT_INSTALLED_FILES` (Check 41), so the bare-reference resolves
   at the client-installed location regardless of cross-surface identity.

7. **Check 37 anchor-phrase note (L4051).** Comments reference
   "HELP-FRAGMENT-TRACKER.md:49" as a worked example of the anchor-phrase
   pattern. Comment-only update may be needed if the cited line drifts
   under future divergence; today's content is identical so the
   reference is valid.

8. **Check 41 `_CLIENT_INSTALLED_FILES` (L5126 entry).** The OK-message
   rationale for `HELP-FRAGMENT-TRACKER.md` says "byte-identical mirror
   per Check 24" — comment-only update.

#### §2.6.2 Summary of downstream impact

- **One latent BUG exposed** (Check 22 wrong content concatenation post-
  divergence) — see §2.6.1 item 1.
- **Six comment/audit-trail rationales** need text updates if Check 24
  is removed or replaced — see §2.6.1 items 5, 6, 7, 8 (plus L4015
  reference text and L4763-4770 comment block).
- **Zero behavioral dependencies** beyond Check 22.

### §2.7 BD-193 Phase 4 candidates re-evaluated

Phase 4 §5.6 surfaced 4 candidates (the same 4 in the BD-194 PRELIMINARY
list in the architect prompt) and explicitly noted "the check should
be relaxed or removed in line with the F4/F5 contract." Phase 4 did NOT
recommend a specific candidate — it deferred to architect pass (i.e.,
this document). Phase 4 §5.6 carries the burden of identifying the
problem; this doc carries the burden of solving it.

---

## §3 Candidate evaluation

Goal criteria (re-stated from BD-194 prompt for evaluation matrix):

- **G1** — Aligns with `feedback_pack_project_separation_of_concerns`
- **G2** — Maintains a useful CI signal (catches ACCIDENTAL regressions)
- **G3** — Doesn't break BD-194 today (validate-pack PASSES post-change)
- **G4** — Maintenance burden proportionate to safety provided

### §3.1 Candidate 1 — Delete the check entirely

**Mechanic:** Remove `check_help_fragment_tracker_byte_identity` function;
remove L6067 callsite; renumber gap-acknowledged (no need to renumber,
Check 12-15 already gap per v9 sunset, so a single gap at 24 is
acceptable precedent); update L62-64 check-list comment to mark Check 24
as RETIRED.

**Per goal criteria:**

- **G1 (alignment):** STRONG. Deleting the byte-identity gate is the
  cleanest expression of "these files are separate artifacts." The
  separation rule says identity is COINCIDENCE not design contract;
  removing the contract enforcement IS the alignment.
- **G2 (CI signal):** WEAK. Loses ALL detection of accidental divergence.
  An accidental copy-paste error on one side (e.g., a developer edits
  `pack-ops/` and forgets `project-template/`) will not surface until
  someone reads the project-template file. There is no other check that
  would catch this regression class.
- **G3 (doesn't break today):** STRONG. validate-pack will PASS at HEAD
  because Check 24 is removed; nothing else fails.
- **G4 (maintenance burden):** STRONG (negative direction — none). No
  maintenance burden because no check exists.

**Challenges:**

- The "weak G2" failure mode is real but bounded: HELP-FRAGMENT-TRACKER
  is user-facing reference text — incorrect content in the project-side
  file will surface to client users on first `pack help` run. The
  feedback loop is fast (next time someone tries to use the command).
  Compare to BD-088 customization-preservation: SILENT data loss has no
  user-visible signal. HELP-FRAGMENT-TRACKER divergence is LOUD if it
  matters and INVISIBLE if it doesn't.
- The reviewer cited "an accidental copy-paste error" — but the BD-193
  F4/F5 separation rationale explicitly REJECTS the framing where
  pack-side and project-side are "supposed to" stay in sync. There IS
  no accidental class anymore; intentional divergence IS the new
  default trajectory.

**Verdict:** STRONG ALIGNMENT with separation principle. SOMEWHAT WEAK
on accidental-regression protection but the protection class is
boundedly low-impact (user-visible loud failure).

### §3.2 Candidate 2 — Per-surface structural check (mirroring `check_issue_template_forms`)

**Mechanic:** Replace byte-identity with a per-surface structural
assertion: each surface MUST exist, MUST contain a defined set of
required sections (e.g., `# Tracker commands`, `## TD promotion`,
`## Colloquial mappings`), MUST list a defined per-surface expected
set of `pack tracker` and `pack td` verbs. Per-surface expected sets
allow controlled divergence on additional verbs.

**Implementation sketch:**

```python
def check_help_fragment_tracker_per_surface() -> None:
    """Check 24 (post-BD-194) — HELP-FRAGMENT-TRACKER per-surface
    structural and content validity.

    Per pack memory feedback_pack_project_separation_of_concerns: the
    pack-side and project-side HELP-FRAGMENT-TRACKER.md files are
    SEPARATE artifacts. This check verifies each surface independently
    meets the structural contract; cross-surface divergence is ALLOWED.
    """
    required_sections_per_surface = {
        "pack-root": {"# Tracker commands", "## TD promotion", "## Colloquial mappings"},
        "project-template": {"# Tracker commands", "## TD promotion", "## Colloquial mappings"},
    }
    required_verbs_per_surface = {
        "pack-root": {"pack tracker init", "pack tracker status", "pack tracker disable",
                      "pack tracker doctor", "pack tracker mirror-rebuild",
                      "pack tracker update-templates", "pack tracker enable-recommendations",
                      "pack td promote", "pack td resolve"},
        "project-template": {"pack tracker init", "pack tracker status", "pack tracker disable",
                             "pack tracker doctor", "pack tracker mirror-rebuild",
                             "pack tracker update-templates", "pack tracker enable-recommendations",
                             "pack td promote", "pack td resolve"},
    }
    surfaces = [
        ("pack-root", REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"),
        ("project-template", REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md"),
    ]
    # ... per-surface existence + section + verb presence assertions ...
```

**Per goal criteria:**

- **G1 (alignment):** STRONG. Each surface gets its OWN expected set;
  divergence is encoded in the dicts. The BD-193 F2.c precedent
  (`expected_wi_type_options_per_surface`) is directly analogous.
- **G2 (CI signal):** STRONG. Each surface independently asserts (a)
  file exists, (b) required sections present, (c) required verbs
  present. A pack-side accidental deletion of `pack tracker disable`
  fails on pack-side. A project-side accidental deletion fails on
  project-side. Independent of cross-surface state.
- **G3 (doesn't break today):** STRONG. The required-set is satisfied
  by both files at HEAD (verified by reading both — sections + verbs
  match the set above).
- **G4 (maintenance burden):** MODERATE. A new verb addition requires
  updating the per-surface dict; current convention (BD-193 F2.c) is
  this is mechanical. A new section addition requires updating the
  required-sections set. The pattern is well-precedented and the
  surface count is fixed at 2.

**Challenges:**

- **Property-fit caution per `feedback_pattern_matching_out_of_context_antipattern`.**
  Is per-surface-structural-check actually a fit for FREEFORM MARKDOWN?
  `check_issue_template_forms` parses YAML SCHEMA (structured); this
  check would substring-match section headers and verb fragments. The
  match is FUZZIER — false-negative rate higher (e.g., a verb listed in
  prose but missing the literal exact string match would FAIL despite
  being functionally present).
- **Where does the "required set" live as source of truth?** This is
  the KEY question. Options:
  - **Inline in validate-pack.py.** Easiest; matches the BD-193 F2.c
    pattern. Risk: drift between the dict and reality each time a verb
    is added. Same risk as Check 22's "verb appears in prose, must
    appear in fragment" except the target source is the dict, not the
    other way around.
  - **Derived from the file content** (e.g., parse the verb tables on
    each surface, just verify both surfaces are structurally
    well-formed). This is closer to Candidate 3's existence + structural
    validity.
  - **Cross-referenced from another canonical source.** No obvious
    canonical source exists.
- **Per-surface expected SET vs. per-surface expected SUPERSET / SUBSET.**
  At today's HEAD, both surfaces have IDENTICAL expected sets (the verb
  namespace is the same). The future divergence pattern most likely is
  one surface ADDING a verb (e.g., pack-side admin verb). The per-
  surface dict naturally encodes this — but the "doesn't break today"
  argument hinges on the dicts being SET-EQUIVALENT at HEAD.
- **DUPLICATION risk.** The current dicts are byte-identical (literal
  set equality). Why encode the same set twice? See §3.5 hybrid
  approach.

**Verdict:** STRONG on alignment + CI signal + doesn't break today.
The maintenance burden + property-fit caveat + duplication risk are
real concerns; the pattern is at the edge of "fit" for freeform markdown.

### §3.3 Candidate 3 — Existence + structural validity invariant

**Mechanic:** Replace byte-identity with: (a) both files MUST exist,
(b) both files MUST parse as well-formed markdown, (c) neither file is
empty / truncated. No content comparison.

**Implementation sketch:**

```python
def check_help_fragment_tracker_existence() -> None:
    """Check 24 (post-BD-194) — HELP-FRAGMENT-TRACKER existence and
    structural validity.

    Per pack memory feedback_pack_project_separation_of_concerns: each
    surface is independently authoritative; content divergence is
    ALLOWED. This check verifies both files exist and are non-empty;
    content is the responsibility of the per-surface author.
    """
    surfaces = [
        ("pack-root", REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"),
        ("project-template", REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md"),
    ]
    for label, path in surfaces:
        if not path.is_file():
            fail(f"{label}: missing — {path.relative_to(REPO_ROOT)}")
            continue
        text = path.read_text()
        if len(text.strip()) < 100:  # arbitrary nonzero threshold
            fail(f"{label}: file unexpectedly small — {len(text)} chars")
            continue
        if not text.startswith("# "):
            fail(f"{label}: missing leading H1 — first line: {text.splitlines()[0][:60]!r}")
            continue
        ok(f"{label}: HELP-FRAGMENT-TRACKER.md exists and is structurally valid")
```

**Per goal criteria:**

- **G1 (alignment):** STRONG. No cross-surface coupling; each surface
  is verified independently with NO assumption about cross-surface
  content.
- **G2 (CI signal):** WEAK-TO-MODERATE. Catches "file deleted",
  "file emptied", "file truncated mid-edit," "file missing leading
  H1 header" — i.e., MECHANICAL regressions. Does NOT catch "verb
  removed from one surface but kept on the other" (the principal
  divergence-failure class).
- **G3 (doesn't break today):** STRONG. Both files are well-formed at
  HEAD.
- **G4 (maintenance burden):** STRONG (low). No per-verb update needed;
  the structural assertions are constant.

**Challenges:**

- The "structural validity" bar is LOW. "Starts with `# `" and "longer
  than 100 chars" only catches gross malformation. Compared to
  Candidate 2's verb-presence assertion, this is a much weaker safety
  net.
- One could argue this is a marginal improvement over Candidate 1
  (delete the check). The check exists but barely asserts anything.
- HOWEVER: the LOW bar is APPROPRIATELY MATCHED to the actual safety
  question. If both files are independent authoritative artifacts, the
  CI surface SHOULDN'T be asserting cross-surface content rules — it
  should be asserting MECHANICAL invariants only. This is the natural
  CI-shape under the separation principle.

**Verdict:** STRONG alignment + MODERATE CI signal + STRONG today /
maintenance. The weakness is the same as Candidate 1's weakness in a
softer form: less mechanical-regression detection.

### §3.4 Candidate 4 — Allowed-divergence allowlist

**Mechanic:** Retain byte-identity as DEFAULT; add an explicit allowlist
of "OK to diverge" section / line ranges; assert byte-identity ON THE
COMPLEMENT (i.e., everything outside the allowlist must stay identical).

**Implementation sketch:**

```python
_ALLOWED_DIVERGENT_PATTERNS = (
    # Once the pack-side and project-side surfaces diverge, populate
    # this list with regex / section markers that are allowed to differ.
    # Empty today.
)

def check_help_fragment_tracker_allowlist() -> None:
    """Check 24 (post-BD-194) — HELP-FRAGMENT-TRACKER cross-surface
    byte-identity OUTSIDE the explicit divergence allowlist.

    Allowlist entries explicitly mark sections / patterns that MAY
    diverge between pack-side and project-side per the per-surface
    audience contract.
    """
    pack_text = (REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md").read_text()
    proj_text = (REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md").read_text()
    # Apply allowlist: strip allowed-divergent regions from both texts.
    pack_normalized = _strip_allowlist(pack_text, _ALLOWED_DIVERGENT_PATTERNS)
    proj_normalized = _strip_allowlist(proj_text, _ALLOWED_DIVERGENT_PATTERNS)
    if pack_normalized != proj_normalized:
        fail(...)
```

**Per goal criteria:**

- **G1 (alignment):** WEAK. The DEFAULT contract is still "byte-identical";
  divergence is the EXCEPTION encoded in an allowlist. Per the
  `feedback_pack_project_separation_of_concerns` rule, the default
  contract should be "separate audiences with separate content" —
  Candidate 4 inverts that. The allowlist mechanism FUNCTIONALLY allows
  divergence but PHILOSOPHICALLY maintains the wrong invariant.
- **G2 (CI signal):** STRONG when allowlist is empty (catches all
  divergence). DEGRADES as the allowlist grows; eventually approaches
  Candidate 1 if many regions are allowlisted.
- **G3 (doesn't break today):** STRONG. Empty allowlist + byte-identical
  files = pass.
- **G4 (maintenance burden):** HIGH. Every intentional divergence
  requires (a) the actor making the edit, (b) the actor adding an
  allowlist entry, (c) the architect/reviewer evaluating whether the
  allowlist entry is well-scoped. The allowlist mechanism itself is
  the source of maintenance friction.

**Challenges:**

- **Philosophy mismatch with user-locked rule.** The rule says these
  are SEPARATE artifacts. Allowlist preserves the "they should be the
  same" framing; this is exactly what the rule rejects.
- **Maintenance cost is structurally HIGHER than the value provided.**
  The allowlist is a CONSTRUCTIVE specification — every divergence is
  pre-authorized. The pattern works for CSS prefixes, browser-specific
  hacks, or other clearly-scoped exception classes. It DOES NOT fit
  "user-facing reference text" where divergence is content-shaped, not
  pattern-shaped.
- **Cited as pattern-mismatch per `feedback_pattern_matching_out_of_context_antipattern`.**
  Allowlists fit where divergence is EXCEPTIONAL and CIRCUMSCRIBED;
  HELP-FRAGMENT-TRACKER divergence is EXPECTED and CONTENT-SHAPED.

**Verdict:** WEAK alignment + STRONG-INITIALLY/DECLINING CI signal +
STRONG today + HIGH maintenance burden. This candidate's value comes
from making divergence FEEL controlled, but the control is illusory —
adding an allowlist entry is essentially "yes I want to diverge here"
which is what the user-locked rule says is the DEFAULT.


### §3.5 Architect-surfaced Candidate 5 — Per-surface existence + non-empty validity (Candidate 1 + Candidate 3 hybrid, minimal)

**Mechanic:** Same as Candidate 3 (existence + structural validity)
but DROPS the "starts with H1" assertion as over-fitted. Reduces to:
(a) each surface file MUST exist, (b) each file MUST be non-empty.
That's it.

This is the SMALLEST departure from the current invariant that aligns
with the separation rule. The check stops asserting CONTENT IDENTITY
but continues to detect TRIVIAL MECHANICAL FAILURES (file deleted, file
emptied by a script bug, etc.).

**Per goal criteria:**

- **G1 (alignment):** STRONG. No content coupling.
- **G2 (CI signal):** WEAK-BUT-NONZERO. Catches accidental file deletion
  / empty-file regressions only.
- **G3 (doesn't break today):** STRONG.
- **G4 (maintenance burden):** STRONG (zero). Constant assertions.

**Challenges:**

- The CI signal is BARELY above Candidate 1. The only thing Candidate 5
  catches that Candidate 1 misses is: "the file got deleted or emptied."
  Argument FOR: that's a real failure mode worth catching (a typo in
  `init-project.sh` S11 could empty the target file). Argument AGAINST:
  Check 41 (`_CLIENT_INSTALLED_FILES` self-doc list integrity) already
  asserts the project-template file is in the install set; Check 43
  (leak-sweep) already requires the pack-side file to exist at the
  `_CHECK_43_PACK_OPS_CLIENT_INSTALLED` exemption path.

**Existing coverage cross-reference:**

- **Check 41** at L5553+ runs `_parse_client_installed_files()` which
  iterates the install set; the project-side file is listed in
  `_CLIENT_INSTALLED_FILES` and verified as present-in-pack. So
  "project-side file exists" is already enforced by Check 41.
- **Check 43** at L5217 names `pack-ops/HELP-FRAGMENT-TRACKER.md` in
  `_CHECK_43_PACK_OPS_CLIENT_INSTALLED`. Check 43's walk doesn't require
  the file to exist (it's an exemption list — present-or-absent doesn't
  affect Check 43's pass/fail), but the comment context implies pack-
  side presence is expected.
- **Check 22** at L1903 reads `pack-ops/HELP-FRAGMENT-TRACKER.md` and
  conditionally concatenates (`if tracker_fragment.is_file():`). Silent
  fallback if missing.
- **Check 23** at L1970 same pattern as Check 22.

**Verdict on existing coverage:** project-template-side existence IS
already covered by Check 41. Pack-side existence is NOT independently
asserted by any other check — Check 22 / Check 23 silently fall back
if missing. So Candidate 5 ADDS pack-side existence assertion that
isn't covered elsewhere.

### §3.6 Architect-surfaced Candidate 6 — Delete + relocate pack-side existence assertion to Check 23

**Mechanic:** Remove Check 24 entirely (Candidate 1). Modify Check 23
(`check_help_fragment_completeness`) to fail-loud if
`pack-ops/HELP-FRAGMENT-TRACKER.md` is missing, instead of silently
falling back. The project-side file's existence is already covered by
Check 41 (`_CLIENT_INSTALLED_FILES`).

**Per goal criteria:**

- **G1 (alignment):** STRONGEST. Eliminates Check 24 entirely; the
  remaining assertions (pack-side existence via Check 23, project-side
  existence via Check 41) are within their own surface boundaries.
  Truly separated.
- **G2 (CI signal):** EQUIVALENT to Candidate 5 — file-existence catches
  on both sides via existing checks; no content comparison anywhere.
- **G3 (doesn't break today):** STRONG. Both files exist; Check 23
  modified to fail-loud passes.
- **G4 (maintenance burden):** STRONG (low). No new check, one Check 23
  modification (a single `else: fail()` branch addition).

**Challenges:**

- **Scope creep risk per `feedback_deferral_is_scope_creep`.** Modifying
  Check 23 in the same commit as Check 24 retirement is THIS-BD scope
  per `feedback_deferral_is_scope_creep` — the Check 23 modification
  is "concrete same-file/same-contract fit" (same `validate-pack.py`,
  same `HELP-FRAGMENT-TRACKER.md` subject) and unblocked. NOT scope
  creep; LOGICAL FIT.
- **Implies a separate downstream LATENT issue.** §2.6.1 item 1 noted
  Check 22 also reads `pack-ops/HELP-FRAGMENT-TRACKER.md` and SILENTLY
  concatenates pack-side content to project-template-surface comparison.
  That bug is independent of Check 24; addressing it would also be
  in-scope for this BD per the same logical-fit argument.

**Verdict:** STRONGEST alignment among candidates. The scope expansion
(Check 23 fail-loud) is LOGICAL FIT and adds protection that
Candidate 1 alone would lose. Per §2.6.1 item 1, the Check 22 issue
is ADJACENT and surface-coupled; consider in-scope vs. follow-on POQ.

### §3.7 Goal-criteria matrix (all candidates)

| Candidate | G1 alignment | G2 CI signal | G3 passes today | G4 maintenance | Verdict |
|---|---|---|---|---|---|
| 1. Delete check | STRONG | WEAK | STRONG | STRONG | Aligned but lossy |
| 2. Per-surface structural | STRONG | STRONG | STRONG | MODERATE | Aligned, costly |
| 3. Existence + structural validity | STRONG | WEAK-MODERATE | STRONG | STRONG | Aligned, modest signal |
| 4. Allowed-divergence allowlist | WEAK | STRONG→DECLINING | STRONG | HIGH | Philosophically wrong |
| 5. Minimal existence + non-empty | STRONG | WEAK-NONZERO | STRONG | STRONG | Aligned, marginal value |
| 6. Delete + Check 23 fail-loud + Check 22 fix | STRONGEST | EQUIVALENT-TO-5 | STRONG | LOW | RECOMMENDED |

---

## §4 Recommended design

**Recommendation: Candidate 6** (Delete + Check 23 fail-loud + Check 22
content-source correction).

### §4.1 Rationale

Candidate 6 is the architecturally consistent expression of the user-
locked separation principle:

1. **It DELETES the cross-surface contract** that contradicts the
   separation rule. No new contract is invented to replace what the
   user-locked rule rejects.
2. **It MOVES existence-protection to surface-local invariants.**
   Pack-side existence becomes a pack-side check (Check 23 with
   fail-loud); project-side existence stays a project-side check
   (Check 41). Each surface authors its own integrity contract.
3. **It SURFACES and CORRECTS an adjacent latent bug.** §2.6.1 item 1
   identified Check 22 silently concatenating pack-side content into
   project-template-surface verb comparison; that bug is the same
   architectural-failure class as Check 24 and warrants in-scope
   correction per `feedback_deferral_is_scope_creep` LOGICAL FIT.
4. **It satisfies all four goal criteria simultaneously.** No
   tradeoffs hidden behind framing.

### §4.2 Comparison to alternatives

- **vs. Candidate 1 (delete only):** Candidate 6 ADDS pack-side
  existence protection (Check 23 fail-loud) that Candidate 1 loses,
  AND corrects the latent Check 22 bug that Candidate 1 leaves
  invisible.
- **vs. Candidate 2 (per-surface structural):** Candidate 6 avoids the
  property-fit caveat (freeform markdown vs YAML schema), the
  duplication risk in per-surface dicts, and the maintenance friction
  of keeping the dicts current. Per-surface structural makes the
  IMPLICIT cross-surface relationship EXPLICIT (in code), but if the
  surfaces are truly separate per the user-locked rule, the expected
  relationship is "independent" — not "this set vs that set."
- **vs. Candidate 3 (existence + structural validity):** Candidate 6
  uses EXISTING checks (41 and modified 23) instead of inventing a new
  check that asserts what existing checks already cover.
- **vs. Candidate 5 (minimal existence):** Candidate 6 reuses Check 23
  which already reads the pack-side file rather than introducing a
  new check for a subset of Check 23's surface.

### §4.3 In-scope vs. follow-on for Check 22 latent bug

The Check 22 latent bug (§2.6.1 item 1) is ARCHITECTURALLY THE SAME
CLASS as Check 24 — a cross-surface assumption that contradicts the
separation rule. Per `feedback_deferral_is_scope_creep`:
- **SIZE:** small (one read-line + one read-line modification of
  Check 22 to select per-surface fragment).
- **BLOCKED:** no — independent of any other work.
- **LOGICAL FIT:** YES — same file (`validate-pack.py`), same subject
  (`HELP-FRAGMENT-TRACKER.md`), same architectural correction
  (cross-surface coupling violation under BD-193 F4/F5 contract).

Per `feedback_deferral_is_scope_creep`: "When a new BD is created that
is LARGE and UNBLOCKED, insert it IMMEDIATELY AFTER the current BD or
batch — do not park at end of v11.0." For SMALL unblocked work with
logical fit, the implication is: include in scope of the originating
BD. Candidate 6 includes the Check 22 fix.

POQ-1 (see §7) is the user-resolution check: does the user agree this
is in-scope for BD-194 or split to a separate BD-NNN?

---

## §5 Implementation shape

### §5.1 Function signature changes

**Remove:**
- `def check_help_fragment_tracker_byte_identity() -> None:` at L2154-2175
- Callsite at L6067: `check_help_fragment_tracker_byte_identity()`
- Check-list comment entry at L62-64 (replace with retirement note)

**Modify Check 23 (`check_help_fragment_completeness` at L1961-?):**

Current behavior (L1968-1976):
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

Change to fail-loud on tracker_fragment missing:
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

**Modify Check 22 (`check_help_fragment_freshness` at L1894-?) to use
per-surface tracker fragment:**

Current (L1903, L1913-1914):
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

Change to per-surface tracker fragment lookup:
```python
# Per BD-194: each surface authors its own HELP-FRAGMENT-TRACKER.md.
# Per-surface fragment lookup per the surface dictionary; no
# cross-surface concatenation.
for surface, cfg in surfaces.items():
    frag = cfg["fragment"]
    tracker_frag = cfg["tracker_fragment"]  # added to cfg dict
    if not frag.is_file():
        ...
    if not tracker_frag.is_file():
        fail(f"{surface}: tracker fragment missing: {tracker_frag.relative_to(REPO_ROOT)}")
        any_failed = True
        continue
    frag_text = frag.read_text() + "\n" + tracker_frag.read_text()
    # ... existing verb-presence comparison ...
```

The `surfaces` dict needs a per-surface `tracker_fragment` path:
```python
surfaces = {
    "pack-root": {
        "root": REPO_ROOT,
        "docs": [...],
        "fragment": REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md",
        "tracker_fragment": REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md",
    },
    "project-template": {
        "root": REPO_ROOT / "project-template",
        "docs": [REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md"],
        "fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT.md",
        "tracker_fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md",
    },
}
```

### §5.2 Allowlist comment updates (audit-trail consistency)

Three comment locations cite "byte-identical mirror per Check 24" as
the rationale for allowlist exemptions; all THREE need their rationale
text updated.

- **L4762-4770** — `_BARE_REFERENCE_EXEMPTIONS` entry for
  `HELP-FRAGMENT.md` (Check 40 allowlist comment). Update text from
  "Byte-identical mirror exception (Check 24)" to "Project-side mirror
  exception; resolves at client-installed location (see Check 41
  `_CLIENT_INSTALLED_FILES`)".
- **L5126** — `_CHECK_43_ALLOWLIST` entry for `HELP-FRAGMENT-TRACKER.md`.
  Update text from "byte-identical mirror per Check 24" to "client-
  installed at `docs/pack/HELP-FRAGMENT-TRACKER.md`; per-surface
  authoritative (BD-193 F4/F5)".
- **L4045-4051** — Check 37 anchor-phrase comment. The cited
  `HELP-FRAGMENT-TRACKER.md:49` reference may drift under future
  content divergence; the anchor-phrase pattern is described abstractly
  but the SPECIFIC line citation will need a comment-only refresh if
  the future evolution lands a divergent change. No immediate edit
  needed; flagged for future reviewer awareness.

### §5.3 Per-check test file (Check 24 retirement)

Since Check 24 is RETIRED (not replaced), no
`test-validate-pack-check-24.sh` is needed. Per Check 42's
discovery mechanism (`scripts/tests/test-validate-pack-check*.sh`),
the absence of the file is correctly absent; no CI workflow wiring
required.

Existing Check 22 and Check 23 likewise have no per-check tests today.
The Check 22/23 modifications can RIDE on the existing
`validate-pack.py` self-test (the check runs as part of every CI
push). Adding a new per-check test file for Check 22 and Check 23 is
OUT OF SCOPE for BD-194 per `feedback_deferral_is_scope_creep`
LOGICAL-FIT bar (the test file would be a different surface — test
infrastructure — and the gap predates BD-194). If future divergence
work needs a per-check test, that's its own BD.

### §5.4 Step-by-step replacement check logic (final)

1. Remove `check_help_fragment_tracker_byte_identity` function
   (L2154-2175).
2. Remove the callsite at L6067.
3. Replace L62-64 check-list comment entry with "24. [RETIRED in
   BD-194 — see ARCHITECTURE-BD-194.md] HELP-FRAGMENT-TRACKER
   byte-identity (BD-082, DELTA L1; superseded by Check 22 + Check 23
   + Check 41 per-surface coverage)."
4. Modify Check 22 to use per-surface `tracker_fragment` from the
   surfaces dict (per §5.1).
5. Modify Check 23 to fail-loud if pack-side tracker fragment missing
   (per §5.1).
6. Update three allowlist-rationale comments (per §5.2).
7. Update README.md "expanded to 41 invoked checks" prose if the
   reduction counts as a check-count change — but Check 24 retirement
   is the same shape as Checks 12-15 retirement (still "invoked"
   bookkeeping). README text says "39 numbered Check 1–11 and 16–43;
   2 unnumbered informational ... Checks 12–15 retired per v9 sunset".
   Post-BD-194, the relevant edit is "Checks 12–15 retired per v9
   sunset; Check 24 retired per BD-194". This is a PM-only edit
   per CLAUDE.md trinity rules; coder writes the README diff but
   Pack Chat / PM Chat owns the version-table prose.

### §5.5 Test plan post-implementation

1. `python3 scripts/validate-pack.py` — must PASS at HEAD post-change.
   Particularly: Check 22 + Check 23 + Check 41 must all PASS, and
   Check 24 must NOT appear in the output.
2. Manual divergence test (LOCAL ONLY, not committed):
   - Add a comment line to `pack-ops/HELP-FRAGMENT-TRACKER.md`
     (single-surface divergence).
   - Re-run `validate-pack.py`; must PASS (this is the architectural
     correction).
   - Verify Check 22 still PASSES (each surface's verbs resolve from
     the per-surface tracker fragment, not the cross-surface one).
   - Revert the test change.
3. `bash scripts/tests/test-validate-pack-check-43.sh` and
   `bash scripts/tests/test-validate-pack-check-40.sh` — must continue
   to PASS (the allowlist rationale updates are comment-only).

---

## §6 Future evolution

### §6.1 Divergence scenarios + failure-mode/CI-signal mapping

Under Candidate 6, future divergence scenarios surface as follows:

| Divergence scenario | CI signal post-BD-194 | User-visible signal |
|---|---|---|
| Pack-side admin verb added; project-side stays unchanged | Check 22 PASSES on project-template surface (verb not in any prose on that surface); PASSES on pack-root surface (verb in prose; verb in fragment) | Pack help renders verb on pack-side `pack help`; absent client-side |
| Project-side phrasing simplification (e.g., dropping `tracker.toml.pack-example` mention on client side) | Check 22 PASSES (the prose reference is per-surface; project-template surface no longer references the pack-side filename) | Client `pack help` shows simplified text; pack-side unchanged |
| Pack-side accidentally truncates the file (e.g., bad sed) | Check 22 FAILS (verbs referenced in pack-side prose no longer present in fragment) AND Check 23 FAILS (scripts listed in pack-side prose missing from fragment) | Catches at CI before merge |
| Project-side accidentally truncates | Check 22 FAILS on project-template surface | Catches at CI before merge |
| Pack-side file deleted | Check 23 FAILS-LOUD per §5.1 modification | Catches at CI |
| Project-side file deleted | Check 41 FAILS (`_CLIENT_INSTALLED_FILES` self-doc integrity gate); Check 43 PASSES (file is in exemption list but content not required) | Catches at CI via Check 41 |
| Verb-table row removed on one side only | Check 22 may FAIL on that surface if any prose refers to the removed verb; otherwise silent | Surfaces at next `pack help` run for the affected audience |
| Both surfaces drift in synchronized error | All checks PASS (no cross-surface comparison); silent in CI | Surfaces only at user-visible `pack help` rendering |

The "synchronized error" case is the ONLY class of post-BD-194 silent
regression. This class is bounded by the user-visibility of the
help-text output — a wrong verb description surfaces the moment a user
runs `pack help` and sees the wrong text.

### §6.2 Scalability of the per-surface separation pattern

The Candidate 6 design scales to additional per-surface separation
cases as v11 evolves:

- **If a future pack-product file gains a separation declaration**
  (e.g., a future `HELP-FRAGMENT-EXAMPLES.md`), the same pattern
  applies: per-surface existence is asserted by surface-local checks;
  cross-surface content identity is NOT asserted.
- **If a new surface emerges** (e.g., a Codex-specific or Gemini-
  specific HELP-FRAGMENT-TRACKER variant), the `surfaces` dict in
  Checks 22 and 23 gains a third entry; per-surface tracker
  fragment lookup gains a third entry; no new check is needed.

### §6.3 Anticipated config knobs

NONE. The Candidate 6 design has NO new constants, NO new config files,
NO new dicts. The only structural change is per-surface tracker
fragment paths added to the `surfaces` dict that already exists in
Check 22. This is consistent with the user-locked rule: separation is
the DEFAULT; no opt-in / opt-out mechanism is needed.

### §6.4 Long-term content-divergence anticipation

The first realistic divergence likely surfaces in 6-12 months when:

1. A pack-developer-only verb ships (mirroring the BD-193 F2.c `bd`
   wi-type option precedent), OR
2. Client-side phrasing simplification removes pack-side-only references
   (e.g., the L49 `tracker.toml.pack-example` mention), OR
3. A glossary cross-reference becomes pack-side-specific (e.g., a
   citation of an architect doc that doesn't belong client-side).

When that first divergence lands, the candidate 6 design supports it
WITHOUT additional architect intervention. The CI gate doesn't fail;
the divergence ships; the surfaces evolve independently.

### §6.5 Naming convention for retired checks

Check 24 retirement follows the precedent of Checks 12-15 retirement
(v9 sunset, BD-121). The README version table prose codifies this
pattern:

> "39 numbered Check 1–11 and 16–43; 2 unnumbered informational ...
> Checks 12–15 retired per v9 sunset"

Post-BD-194 prose:

> "38 numbered Check 1–11, 16–23, 25–43; 2 unnumbered informational
> ... Checks 12–15 retired per v9 sunset; Check 24 retired per BD-194
> (HELP-FRAGMENT-TRACKER byte-identity superseded by per-surface
> existence coverage)"

This is a README-prose change — PM-only per CLAUDE.md "What agents
must never modify without explicit instruction" rules. Pack Chat
edits the README version-table prose post-BD-194 commit.

---

## §7 POQs requiring user resolution

### §7.1 POQ-1 — Scope inclusion of Check 22 latent bug fix

**Question.** §3.6 + §4.3 surface a latent bug in Check 22
(`check_help_fragment_freshness`) — it reads `pack-ops/HELP-FRAGMENT-
TRACKER.md` and concatenates it to BOTH surfaces' verb-presence
comparison, which is incorrect post-BD-193 F4/F5. The architect
recommendation (Candidate 6) BUNDLES this fix with Check 24 retirement
on the LOGICAL-FIT criterion: same file, same subject, same
architectural correction.

**Recommendation.** INCLUDE Check 22 fix in BD-194 scope per
`feedback_deferral_is_scope_creep` (small, unblocked, logical fit).

**Alternative.** Split into BD-194-A (Check 24 retirement only) and
BD-194-B (Check 22 + Check 23 per-surface tracker fragment correction)
— this loses some natural batching but adheres to a stricter "one
change per BD" framing.

**User decision needed before planner spawn.**

### §7.2 POQ-2 — README version-table prose update timing

**Question.** Per §5.4 step 7 and §6.5, the README version-table
"validate-pack.py expanded to 41 invoked checks" prose needs updating
post-Check-24-retirement. This is PM-only writable per the rules. Two
options:

- **Option A.** Pack Chat owns the README edit; it lands in the SAME
  BD-194 commit as the coder's `validate-pack.py` edits.
- **Option B.** README prose ships as a follow-on PM-only commit after
  BD-194 coder commit lands.

**Recommendation.** Option A — the README prose accurately reflects
the post-commit state at commit time; Option B leaves a brief
inconsistency between commits.

**User decision needed before commit-shape planning.**

### §7.3 POQ-3 — Comment-rationale text precision for allowlist updates

**Question.** Per §5.2, three comment-rationale updates are needed in
`_BARE_REFERENCE_EXEMPTIONS` (L4762-4770) and `_CHECK_43_ALLOWLIST`
(L5126). The proposed replacement text is:

- L4770: `"Byte-identical mirror exception (Check 24); ..."` →
  `"Project-side mirror exception; resolves at client-installed location (see Check 41 _CLIENT_INSTALLED_FILES)"`
- L5126: `"...byte-identical mirror per Check 24"` →
  `"...client-installed at docs/pack/HELP-FRAGMENT-TRACKER.md; per-surface authoritative (BD-193 F4/F5)"`

**Recommendation.** ACCEPT as drafted; the new text accurately reflects
the post-BD-194 invariant and cross-references the still-current
checks that provide the protection.

**User can defer this to coder pass review.** Not a blocking POQ.

---

## §8 Cross-references

### §8.1 BD-194 entry

- `pack-ops/BACKLOG.md:3076-3124` (mirror; per-entry tree pending
  Batch 23 per BD-102 dog-food).

### §8.2 Phase 4 review §5.6

- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md`
  §5.6 L701-722 (M-8 finding originating this BD).
- Phase 4 §7.1 (`maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md`
  L877) categorizes M-8 as REMEDIATION-NEEDED-SHOULD.
- Phase 4 §7.3 (L894-899) reaffirms latent-concern framing.
- Phase 4 §8 (L1028) "scripts/validate-pack.py Check 24: relax or
  remove byte-identity" — final recommendation.

### §8.3 Pack memory anchors

- `feedback_pack_project_separation_of_concerns` — user-locked
  2026-05-26. Authoritative for §1.2 + §1.4 + §3.* alignment claims.
- `feedback_bd_pack_only_operational_rule` — adjacent BD-193 user-lock.
- `feedback_client_facing_token_economy` — adjacent BD-193 user-lock.
- `feedback_preliminary_triage_architect_challenge` — applied via §3.*
  per-candidate challenges.
- `feedback_pattern_matching_out_of_context_antipattern` — applied via
  Candidate 2 property-fit caveat + Candidate 4 philosophy-mismatch
  rejection.
- `feedback_deferral_is_scope_creep` — applied via §4.3 + POQ-1 in-
  scope inclusion of Check 22 fix.

### §8.4 Related architect docs

- BD-193 architect / planner / IMPL-REPORT docs (the F4/F5 source-of-
  truth correction that established the architectural premise this
  BD operates from). Not enumerated here; trace via BD-193 entry in
  `pack-ops/BACKLOG.md:3015-3072`.
- `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
  §1.4 — defines Check 43's allowlist contract that §5.2 amends comment-
  rationale-only.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` §5.3 —
  Check 41 `_CLIENT_INSTALLED_FILES` self-doc list integrity contract
  (the project-side existence guarantee Candidate 6 relies on).

### §8.5 Affected source files (read-only at this architect pass)

- `scripts/validate-pack.py` L62-64 (check-list comment),
  L1894-1959 (Check 22), L1961-2008 (Check 23),
  L2154-2175 (Check 24 — to retire), L4015-4055 (Check 37 anchor-phrase
  context), L4762-4770 (Check 40 allowlist comment), L5108-5194
  (Check 43 allowlist), L5217 (Check 43 pack-ops-client-installed
  exemption), L6067 (Check 24 callsite).
- `pack-ops/HELP-FRAGMENT-TRACKER.md` (pack-side authoritative; no edit
  needed under Candidate 6).
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (project-side
  authoritative; no edit needed under Candidate 6).
- `README.md` version-table prose (PM-only edit per §5.4 step 7 / §6.5;
  Pack Chat owns).
- `.github/workflows/validate-pack.yml` — NO edit needed (no new test
  file landing).

### §8.6 Success criteria mapping

- SC1 (check function modified per architect-locked design decision) →
  §5.1 + §5.4.
- SC2 (replacement contract architecturally consistent with
  `feedback_pack_project_separation_of_concerns`) → §4.1 + §6.1.
- SC3 (validate-pack.py PASS at HEAD) → §5.5 step 1.
- SC4 (if divergence-allowing approach chosen: minimal test fixture
  demonstrating allowed divergence passes new check) → §5.5 step 2
  (manual local divergence test).
- SC5 (reviewer audit pass clean) → standard reviewer post-coder
  pipeline; not architect-scope.

---

*End of architect deliverable.*
