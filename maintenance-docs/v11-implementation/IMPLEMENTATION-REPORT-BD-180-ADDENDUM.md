# IMPLEMENTATION-REPORT-BD-180-ADDENDUM.md

Small-scope reconciliation coder report for **BD-180 addendum** —
architect-doc-vs-reality reconciliation chain element (b): add an
addendum to `ARCHITECTURE-BD-176.md` §5.3 cross-referencing the
realized consumer landed by BD-180 commit `78a4415`.

- Branch: `v11-dev`
- HEAD (pre-commit): `78a44152bb7c6a4d3428246bc2477552727771ee`
- Coder agent: pack-coder (small-scope reconciliation, in-place against
  parent worktree)
- Date: 2026-05-20
- Scope: 1 file modified (architect doc addendum only).
- Architect spawn? NO — mechanical reconciliation per pack memory
  `architect-doc-vs-reality-reconciliation` worked-example pattern
  (BD-119 §9.2 → BD-160).

## §1 Problem restatement

Per pack memory `architect-doc-vs-reality reconciliation` (pack-root
`CLAUDE.md` § Pack memory § Repo conventions), when a BD realizes a
design anticipated in an architect doc, the reconciliation chain has
three required elements:

1. **In-code docstring** naming the realized consumer (file + symbol;
   never line numbers).
2. **Architect-doc addendum** cross-referencing the realized consumer.
3. **IMPL-REPORT cross-reference** linking both.

BD-180 (commit `78a4415`) realized the design sketched in
`ARCHITECTURE-BD-176.md` §5.3 (the self-documenting "files copied to
clients" list + corresponding integrity check). Status of the
reconciliation chain BEFORE this addendum:

- (1) In-code docstring: ✓ landed in BD-180 — `scripts/init-project.sh`
  `_CLIENT_INSTALLED_FILES_START`/`_END` marker block;
  `scripts/validate-pack.py:check_client_installed_files` (Check 41).
- (2) Architect-doc addendum: ✗ MISSING — this coder's scope.
- (3) IMPL-REPORT cross-reference: ✓ landed in BD-180 —
  `IMPLEMENTATION-REPORT-BD-180.md` §11 + §4.

Element (2) is the gap this addendum closes. The reconciliation chain
is load-bearing for any future-shipped surface that pre-existed in an
architect doc (per the canonical worked example: BD-119 §9.2 addendum
→ BD-160 as first realized consumer).

## §2 Inserted content (as inserted, final prose)

The following block was inserted at the end of §5.3, before the §5.4
heading:

```markdown
**Addendum (2026-05-20, BD-180):** The self-documenting "files copied
to clients" list was realized in BD-180 (commit `78a4415`) as the
`_CLIENT_INSTALLED_FILES_START`/`_END` marker block in
`scripts/init-project.sh` (the source authority — 38 entries at
landing). Integrity is enforced by
`scripts/validate-pack.py:check_client_installed_files` (Check 41),
which verifies (a) markers exist exactly once each, (b) every listed
`pack_relpath` resolves to an extant file at HEAD, and (c) every
`cmd_update` mapping source path appears in the inventory (the
cross-check that closes observation G's drift-detection gap). See
`IMPLEMENTATION-REPORT-BD-180.md` §4 for the design refinements
applied during realization — notably: single inventory block
co-located with `cmd_update()` rather than dual blocks above S6 + S11
(simpler-correct discoverability anchor); Check 41 substituted for
the sketch's "Check 40" (Check 40 was claimed by BD-179 between
this architect doc and BD-180 implementation); parser-based
inventory consumption in `validate-pack.py` rather than
`grep`-against-source matching (more robust to surrounding-prose
drift).
```

Prose refinements vs. the prompt's recommended structure:

- Opens with `**Addendum (2026-05-20, BD-180):**` to match the
  canonical worked-example pattern at
  `ARCHITECTURE-BD-119.md` §9.2 addendum (BD-160 anchor).
- Names BD-180's commit SHA (`78a4415`) explicitly, mirroring how the
  BD-119 §9.2 addendum names BD-160's commit SHA (`a57dd04`).
- Expands the "design refinements" cross-reference to enumerate the
  three refinements documented in BD-180 IMPL-REPORT §4 (single-anchor
  vs. dual-stage; Check 41 vs. Check 40; parser-based vs. grep-based)
  — gives a future reader scanning the architect doc enough context to
  understand which specific refinements were applied without needing
  to also open the IMPL-REPORT.

## §3 Insertion point cited

Section heading the addendum follows: `### §5.3 Design sketch for
BD-180 absorption (forward reference)`.

Concrete placement: the addendum is the LAST paragraph of §5.3,
inserted AFTER the existing closing sentence "This sketch is
informational only for BD-176; the design lands in BD-180." and BEFORE
the `### §5.4 Handoff to BD-180` heading.

This is the "after the original, before the next section" placement
pattern called out in the prompt — matching the BD-119 §9.2 → BD-160
worked example structure (where the addendum was appended to the end
of §9.2, before §9.3).

## §4 Files modified — diff stat

```
 maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)
```

| Path | Change type | Lines added | Purpose |
|---|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` | modified | +20 (addendum block only; no other content touched) | Close the architect-doc-vs-reality reconciliation chain for BD-180. |

No other file touched. Original §5.3 sketch content preserved
verbatim; addendum is purely additive.

## §5 Verification

### §5.1 Markdown validity

Visual inspection: addendum uses standard markdown bold-emphasis +
inline code fences (`backtick-wrapped`), no headings introduced inside
§5.3 (which would alter the §5.3/§5.4 boundary), no list-formatting
disruption. The bold `**Addendum (...)**:` opening is consistent with
the BD-119 §9.2 addendum pattern.

### §5.2 No other content modified (diff scope check)

```
$ git diff --stat maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md
 .../v11-implementation/ARCHITECTURE-BD-176.md | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)
```

20 insertions, 0 deletions. Original sketch content untouched.

```
$ git status --short
 M maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md
?? maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md
```

Exactly one modified file (the architect doc); the untracked
`V11.1-DISCUSSION-GITHUB-PROJECTS.md` is a pre-existing untracked file
from a prior session (noted in IMPLEMENTATION-REPORT-BD-180.md §15) —
NOT in this addendum's scope; do not stage.

### §5.3 Boundary check (addendum is inside §5.3, before §5.4)

```
$ grep -n "### §5.3\|### §5.4\|Addendum (2026-05-20" \
        maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md
487:### §5.3 Design sketch for BD-180 absorption (forward reference)
509:**Addendum (2026-05-20, BD-180):** The self-documenting "files copied
529:### §5.4 Handoff to BD-180
```

Addendum begins at line 509, strictly between §5.3 (line 487) and §5.4
(line 529). Placement correct.

### §5.4 References resolve at HEAD

Each cross-reference in the addendum was verified against working-tree
state at HEAD `78a4415`:

| Reference | Verification | Result |
|---|---|---|
| `scripts/init-project.sh` | `[[ -f scripts/init-project.sh ]]` | PRESENT |
| `_CLIENT_INSTALLED_FILES_START` (symbol) | `grep -c "_CLIENT_INSTALLED_FILES_START" scripts/init-project.sh` | 1 match |
| `_CLIENT_INSTALLED_FILES_END` (symbol) | `grep -c "_CLIENT_INSTALLED_FILES_END" scripts/init-project.sh` | 1 match |
| `scripts/validate-pack.py` | `[[ -f scripts/validate-pack.py ]]` | PRESENT |
| `check_client_installed_files` (symbol) | `grep -c "def check_client_installed_files" scripts/validate-pack.py` | 1 match |
| `IMPLEMENTATION-REPORT-BD-180.md` (path) | `[[ -f maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180.md ]]` | PRESENT |
| `IMPLEMENTATION-REPORT-BD-180.md §4` (section) | verified by direct Read — section exists and is titled "Self-documenting list design (observation G refinements vs. ARCHITECTURE-BD-176.md §5.3)" | PRESENT |
| Commit SHA `78a4415` | `git rev-parse HEAD` | matches `78a44152...` (7-char prefix `78a4415` is the canonical short SHA at HEAD) |
| BD-180 38 entries / Check 41 / cmd_update cross-check claims | verified against IMPLEMENTATION-REPORT-BD-180.md §7.1 (`Check 41 — 38 _CLIENT_INSTALLED_FILES entry (entries) checked ... 35 cmd_update path(s) cross-checked against inventory; 0 drift(s)`) | matches |

All references in the addendum prose resolve to extant files +
symbols + sections at HEAD.

### §5.5 No line numbers used

Per pack memory's `architect-doc-vs-reality reconciliation` rule
("file + symbol; never line numbers — line numbers drift"), the
addendum uses ONLY file:symbol references
(`scripts/init-project.sh` `_CLIENT_INSTALLED_FILES_START`/`_END`;
`scripts/validate-pack.py:check_client_installed_files`) and
section anchors (`IMPLEMENTATION-REPORT-BD-180.md §4`). Zero line
numbers introduced.

## §6 RC9 manifest status

**Manifest regen NOT required.**

- Modified file: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md`.
- RC9 trigger glob (pack-root trinity § Pack memory § Repo
  conventions): `v11-surface = files under project-template/`,
  `scripts/`, `pack-ops/`, or `supporting-docs/`.
- `maintenance-docs/` is NOT in the RC9 trigger glob.
- `maintenance-docs/` content is NOT copied to client install
  (verified: no `init-project.sh` copy site reads `maintenance-docs/`;
  the directory is internal pack design / archive surface).

Therefore: no fixture rebuild required; no manifest stage required;
no v11-* SHA drift expected from this commit.

## §7 PREFLIGHT line

Emitted in the final assistant message after this IMPL-REPORT write.
