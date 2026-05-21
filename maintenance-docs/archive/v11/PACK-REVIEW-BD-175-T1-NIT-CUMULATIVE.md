# PACK-REVIEW — BD-175 T1 NIT CUMULATIVE (fd8eb10 + ff5e9cd + 20bf767)

**Branch:** `v11-dev`
**HEAD verified:** `20bf76760addca55481c99895876ca9b751220e7`
**Date:** 2026-05-20
**Reviewer:** pack-reviewer
**Scope:** Cumulative per-commit review of three commits all touching
`maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
as one conceptual work unit:
- `fd8eb10` — T1 SHOULD-1 architect-doc addendum (§6.1)
- `ff5e9cd` — T1 NIT section-name locator (single-line fix in §6.1)
- `20bf767` — T1 NIT exhaustive sweep (17 token replacements at 13 locations)

---

## §1 — Verdict

**Cumulative result: APPROVE with two NITs.**

The three commits together correctly satisfy the two rules they intended
to address: (1) Pack-memory "Architect-doc-vs-reality reconciliation"
rule for the F4 supersession, and (2) Pack-memory "file + symbol; never
line numbers — line numbers drift" rule for `PACK-AGENTS.md` cross-refs.

The §6.1 addendum is purely additive (preserves the original architect's
prescription as audit trail and reconciles it forward to the realized
Pattern A shape via `stage_s4_skills()`). The soft-locator fix correctly
replaced `line ~329 area` with the stable section-name anchor `at the
top of §6`. The 17-token sweep converged completely — post-sweep
verification confirms zero `PACK-AGENTS.md:NNN` hits, 17 canonical-anchor
occurrences, all 11 documented LEAVE refs preserved.

Two NITs surfaced (one against `fd8eb10`, one against the multi-commit
sequence as a whole):
- **NIT-1 (fd8eb10):** §6.1 addendum does NOT explicitly cite "BD-119
  §9.2 reconciliation pattern" as the template followed (item 5 of
  prompt §1). The addendum has the SHAPE of §9.2 but no by-name
  cross-reference. Pack-memory rule cites the BD-119 §9.2 addendum as
  the "worked example" — meaning future readers using the rule have to
  walk back through pack-memory to find §9.2, rather than the addendum
  itself pointing at the pattern.
- **NIT-2 (fd8eb10, accepted by sequence):** The full reconciliation
  chain per pack-memory rule has 3 legs — (a) in-code docstring naming
  the realized consumer, (b) architect-doc addendum, (c) IMPL-REPORT
  cross-reference. The sequence delivered only leg (b). The SHOULD-1
  IMPL-REPORT §1 explicitly acknowledges the (a) and (c) legs as
  out-of-scope, citing "shell-not-Python so has no docstring slot" —
  which is a weak rationalization (bash supports function header
  comments routinely used as docstrings). Leg (c) is reasonably
  unsalvageable post-hoc (F4-bundle IMPL-REPORT already committed in
  `8f6ce51`). Whether leg (a) is required depends on whether the
  consumer is consumer-specific (BD-160 / `migrator_target_surface_for_version`
  was function-specific to the design) or generic (`stage_s4_skills()`
  is a generic per-skill loop where adding a "BD-175 §6.1 supersede"
  docstring would imply the function is BD-175-specific when it isn't).

Both NITs are documentation-completeness concerns within the reconciliation
rule. They do not block the substantive correctness of the supersession
narrative or the sweep. Pack Chat should triage them with the standard
fix-all default per pack memory "Triage all reviewer findings; default
fix-all; nits become tech debt." If FIX, both can land as a single
small follow-up commit (add a "(matches BD-119 §9.2 reconciliation
pattern)" parenthetical to §6.1, and either add a `stage_s4_skills()`
header comment naming BD-175 §6.1 or explicitly document why this
consumer is exempted from leg (a)).

---

## §2 — Independent findings (per scope-area assessment)

### Scope-area 1 — §6.1 addendum completeness (from fd8eb10)

Verified all five required items per prompt §1.

| # | Required item | Status | Evidence |
|---|---|---|---|
| 1 | F4 supersession explicit + commit `8f6ce51` back-pointer | PASS | L444-446 ("BD-175 commit `8f6ce51` (F4 bundle)") + L487-488 explicit "Back-pointer" subsection |
| 2 | Pattern A path `project-template/skills/boundary-investigation/SKILL.md` | PASS | L454-455 (named verbatim) |
| 3 | Realized consumer: `stage_s4_skills()` in `scripts/init-project.sh` | PASS | L459-460 (file + symbol, no line numbers — correct per pack-memory) |
| 4 | Pattern A vs Pattern B rationale | PASS | L466-477 ("Why Pattern A" paragraph) — covers 30+ Pattern A sibling skills, byte-identity by construction vs maintenance, when Pattern B remains valid |
| 5 | Cross-reference to BD-119 §9.2 pattern (or shape match) | PARTIAL — shape match only, no by-name cite | §6.1 mirrors the §9.2 SHAPE (reconciliation framing, named consumer, rationale) but does NOT cite "BD-119 §9.2 reconciliation pattern" by name. SHOULD-1 IMPL-REPORT §3 acknowledges the pattern explicitly (L81: "matching the BD-119 §9.2 worked-example pattern") but the architect-doc addendum itself does not. See NIT-1 in §1 above. |

### Scope-area 2 — §6.1 soft-locator fix (from ff5e9cd)

Verified single-line replacement landed correctly.

- BEFORE (per ff5e9cd diff): `(the "New skill" paragraph above, line ~329 area)`
- AFTER (HEAD L482): `(the "New skill" paragraph at the top of §6)`
- Section anchor accuracy: §6 starts at L325 (heading), "Goal" L327,
  "New skill" L329. The "at the top of §6" anchor is correct — "New
  skill" IS the first content paragraph of §6 after the "Goal" line.
- Drift-resistance: passes — grep for `~329|~ 329|line ~[0-9]` returns
  zero hits across the architect doc.
- No other "line ~N area" soft locators remain (verified via grep).

PASS.

### Scope-area 3 — PACK-AGENTS.md cross-refs sweep (from 20bf767)

Verified all 17 token replacements landed correctly.

```
$ grep -nE 'PACK-AGENTS\.md:[0-9]+' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
(zero hits)

$ grep -c 'PACK-AGENTS\.md § "PM-only files and directories"' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
17
```

PASS. Sweep converged completely.

### Scope-area 4 — Section-name accuracy (canonical anchor matches actual heading)

Verified byte-for-byte match.

```
$ grep -n '^\*\*PM-only files and directories\*\*' pack-ops/PACK-AGENTS.md
140:**PM-only files and directories** are off-limits to all agents unless the
```

The architect doc's canonical anchor `pack-ops/PACK-AGENTS.md § "PM-only
files and directories"` matches the bold-paragraph heading at L140 of
`pack-ops/PACK-AGENTS.md` byte-for-byte. The bold-paragraph form (rather
than `### Heading` form) is consistent with PACK-AGENTS.md's section
style. The `§` glyph is the standard architect-doc anchor convention.

PASS.

### Scope-area 5 — LEAVE refs preserved (11 refs unchanged)

Verified all 11 documented LEAVE refs remain unchanged.

| Line | Ref | Status |
|---|---|---|
| 416 | `docs/pack/PM-CHAT.md:47 § "Pack agent roster"` (hybrid) | UNCHANGED — confirmed via grep |
| 181 | `PACK-REVIEW-PHASE-2-DESIGNS.md §1 S4, lines 201-216` | UNCHANGED — confirmed via grep |
| 615 | `PACK-REVIEW-PHASE-2-DESIGNS.md §1 B1, lines 43-65 ... S6 ... lines 241-253` | UNCHANGED |
| 985 | `... M2, lines 86-104` | UNCHANGED |
| 1013 | `... M4, lines 127-140` | UNCHANGED |
| 1063 | `... S6, lines 241-253` | UNCHANGED |
| 1129 | `... S4, lines 201-216` | UNCHANGED |
| 1161 | `... S5, lines 219-237` | UNCHANGED |
| 1217 | `HELP-FRAGMENT-TRACKER.md (line 584 at HEAD 8014186)` | UNCHANGED — SHA-pinned |
| 1222 | `ARCHITECTURE-DIRECTORY-REORGANIZATION.md §3 row #9 (line 167)` | UNCHANGED — paragraph-scoped SHA-pin |
| 1223 | `B's M2 row in §6.1 (line 527)` | UNCHANGED — paragraph-scoped SHA-pin |

Verification grep:

```
$ grep -nE '\(line[s]? [0-9]+(-[0-9]+)?\)|^[^|]*lines [0-9]+-[0-9]+|line [0-9]+ at HEAD' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
```
returns 10 hits (L1217 + L1222 + L1223 SHA-pinned + 7 review-report refs).
The L416 hybrid is on a separate grep (file:NNN form). All 11 LEAVE refs
account for the remaining line-number-bearing references in the doc.

PASS.

### Scope-area 6 — Disambiguating prose at L603 / L608 / L1098

Verified.

| Line | Ref | Disambiguation present? |
|---|---|---|
| 603 | `pack-ops/PACK-AGENTS.md § "PM-only files and directories"` **Directories sub-list** | YES |
| 608 | `pack-ops/PACK-AGENTS.md § "PM-only files and directories"` (`**Forward-pointing note (Batch 19 → Batch 23):**` sub-block) | YES |
| 1098 | `pack-ops/PACK-AGENTS.md § "PM-only files and directories"` **Directories sub-list** | YES |

Disambiguation is load-bearing — the L603/L1098 refs target the
Directories sub-list (lines 151-158 of PACK-AGENTS.md), and L608
targets the Forward-pointing note (lines 179-187). Without
disambiguation, the canonical anchor would over-broadly point at the
umbrella section and lose the original semantic intent.

PASS.

### Scope-area 7 — Pack-side line-329 prescription correctly left unmarked

Verified.

The §6 "New skill" paragraph at L329 (which prescribes the pack-side
boundary-investigation skill at pack-repo root `.claude/skills/...`,
`.codex/skills/...`, `.gemini/skills/...`) was NOT marked as
superseded. The supersession scope is narrow to the project-side
"Project-side skill trinity" paragraph at L434 only.

The §6.1 addendum explicitly states this scope discipline (L479-485,
"Unchanged from §6: The pack-side boundary-investigation skill ...
Pack-repo agents load skills at run-time from CLI-prefixed dirs at the
pack root — this is structurally different from project-side ship-via-
install and was correctly described in §6").

The inline marker note at L436-438 is placed AFTER the L434
"Project-side skill trinity" paragraph (the Pattern B prescription) and
points to §6.1. It does NOT appear after the L329 "New skill"
prescription. Scope discipline correct.

PASS.

### Scope-area 8 — Audit trail purely additive for §6.1

Verified via `git log -p fd8eb10^..20bf767 -- ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`.

Original §6 content (L325-L434, the "New skill" prescription + skill
content sketch + skill-loading table + project-side skill trinity
prescription) is UNCHANGED across all 3 commits. Only additions:
- fd8eb10: inline marker (L436-438 quote block) + new §6.1 sub-section
  (L442-488) appended at end of §6 (+52 / -0)
- ff5e9cd: single-line replacement in §6.1 at L482 (`line ~329 area`
  → `at the top of §6`) — also additive in the sense of not perturbing
  any pre-existing §6 content; the perturbed line is inside the §6.1
  sub-section newly added by fd8eb10
- 20bf767: 19 lines changed (`+20 / -19` net, but no §6.1 lines changed
  — all 19 changes are in §§8/8.1a/10/13/16 token replacements)

The original architect's design intent for §6 is preserved as a sealed
audit-trail block; the addendum supplements without overwriting.

PASS.

### Scope-area 9 — Commit ordering coherence

Verified.

The 3 commits in order tell a coherent story:
1. `fd8eb10` ships the §6.1 addendum (resolves SHOULD-1 from F4-bundle
   review). The addendum body uses a soft-locator `line ~329 area`,
   which the addendum's own per-commit T1 reviewer flagged as a NIT.
2. `ff5e9cd` applies the T1 NIT fix to the soft-locator created by
   fd8eb10. The same fix-coder pass flagged 2 sibling `PACK-AGENTS.md:NNN`
   refs (L534/L618) as the same-class candidates discoverable by the
   broader sweep.
3. `20bf767` runs the exhaustive whole-doc sweep, bundling the L534/L618
   in-flight + 15 more refs the broader grep surfaced. Hydra contained
   (post-sweep grep returns zero).

No mid-state inconsistencies. Each commit's body is internally
consistent at the time it was written. The 3 commits flow as a clean
cascade: addendum → mini-NIT fix → broader sweep convergence.

PASS.

### Scope-area 10 — No scope creep beyond architect doc

Verified via `git show --name-only` for each commit.

| Commit | Files touched |
|---|---|
| fd8eb10 | `architect doc` + `IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md` (new) |
| ff5e9cd | `architect doc` + `IMPLEMENTATION-REPORT-BD-175-T1-NIT.md` (new) |
| 20bf767 | `architect doc` + `IMPLEMENTATION-REPORT-BD-175-T1-NIT-SWEEP.md` (new; supersedes deleted untracked `IMPLEMENTATION-REPORT-BD-175-T1-NIT-FOLLOWUP.md`) |

Zero touches to:
- `project-template/` trinity (CLAUDE.md / AGENTS.md / GEMINI.md)
- `project-template/` anything else
- `scripts/`
- `pack-ops/`
- `supporting-docs/`
- `test-fixtures/`
- pack-root trinity

PASS.

### Scope-area 11 — POQ-F4-3 correctly left for BD-178

Verified.

POQ-F4-3 is the editorial trinity note about Tier 0 base loading,
deferred to BD-178 per user direction. NONE of the 3 commits touched
project-template trinity files (CLAUDE.md / AGENTS.md / GEMINI.md at
project-template/), per scope-area 10 above. Deferral honored.

PASS.

---

## §3 — Per-commit attribution

| Finding | Severity | Attributes to commit | Notes |
|---|---|---|---|
| NIT-1: §6.1 lacks explicit "BD-119 §9.2 reconciliation pattern" by-name cite | NIT | fd8eb10 | Could be a one-parenthetical add to §6.1 addendum |
| NIT-2: Reconciliation triad legs (a) docstring + (c) IMPL-REPORT cross-ref weak | NIT | fd8eb10 (accepted as scope by ff5e9cd + 20bf767) | SHOULD-1 IMPL-REPORT §1 explicitly out-of-scopes both legs; rationalization for (a) is weak |
| Scope-area 1 items 1-4 PASS | — | fd8eb10 | — |
| Scope-area 2 soft-locator fix PASS | — | ff5e9cd | — |
| Scope-areas 3 / 5 / 6 sweep PASS | — | 20bf767 | — |
| Scope-areas 4 / 7 / 8 / 9 / 10 / 11 | — | All 3 | Cumulative properties verified across the sequence |

---

## §4 — Compare to IMPL-REPORTs

Reading the three IMPL-REPORTs after independent assessment.

### IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md (for fd8eb10)

Alignments:
- §1 acknowledges leg (a) docstring + leg (c) IMPL-REPORT cross-ref
  are out-of-scope; matches my NIT-2 finding.
- §3 L81 cites "matching the BD-119 §9.2 worked-example pattern" —
  but the cite is in the IMPL-REPORT, not the architect-doc addendum
  itself; the addendum still has no by-name §9.2 cite (NIT-1 stands).
- §7 DoD checklist marks all 5 required addendum items PASS, matching
  my scope-area 1 assessment for items 1-4. Item 5 ("cross-reference
  to BD-119 §9.2 pattern (or similar shape match)") is not in their
  explicit DoD list — they treat it as implicit via the "matches the
  BD-119 §9.2 worked-example pattern" prose at §3 L81.

Divergences:
- None substantive. The IMPL-REPORT and my review converge on the
  shape (5 items addressed, addendum purely additive, leg (a)/(c)
  acknowledged as out-of-scope).

### IMPLEMENTATION-REPORT-BD-175-T1-NIT.md (for ff5e9cd)

Alignments:
- §1 + §3 BEFORE/AFTER quotes match my scope-area 2 verification
  exactly.
- §2 acknowledges sibling line-number refs L534/L618 flagged as
  same-class candidates for follow-up — which is what 20bf767
  ultimately landed.

Divergences:
- None substantive.

### IMPLEMENTATION-REPORT-BD-175-T1-NIT-SWEEP.md (for 20bf767)

Alignments:
- §3 sub-table 3a (FIX, 17 token replacements at 13 locations) matches
  my scope-area 3 grep verification.
- §3 sub-table 3b (LEAVE, 11 refs) matches my scope-area 5 verification.
- §4 grep results match what I re-ran independently:
  - Grep 1 (file:NNN form) — only L416 hybrid remains
  - Grep 2 (English-language line refs) — 10 hits (3 SHA-pinned + 7
    review-report refs)
  - Grep 3 (canonical anchor count) — 17

- §6c IMPL-REPORT documents the discretionary L560 hybrid normalization
  (had `PACK-AGENTS.md:142-148 § "PM-only files and directories"` →
  normalized to canonical anchor without the redundant line range).
  Defensible: avoids a single hybrid form lingering after 17 same-class
  refs were normalized.

Divergences:
- None substantive. The IMPL-REPORT is unusually thorough — includes
  hydra-containment grep evidence, per-ref disposition rationale,
  surfaced-only "if Pack Chat triages differently" alternative
  disposition for the write-once review-report refs.

### Overall IMPL-REPORTs alignment

All three IMPL-REPORTs are well-aligned with the cumulative state.
The SHOULD-1 IMPL-REPORT is the only one that acknowledges a known
gap (the reconciliation triad legs (a)+(c)) — which lines up with my
NIT-2 finding.

---

## §5 — Severity-classified findings table

| Severity | ID | Finding | Affected commit | Recommendation |
|---|---|---|---|---|
| BLOCKER | — | (none) | — | — |
| MUST | — | (none) | — | — |
| SHOULD | — | (none) | — | — |
| NIT | NIT-1 | §6.1 addendum has no by-name cite of "BD-119 §9.2 reconciliation pattern" — only shape match. Future readers using pack-memory rule "Architect-doc-vs-reality reconciliation" cannot follow a forward pointer from §6.1 → §9.2 worked example. | fd8eb10 | One-parenthetical add to §6.1, e.g. at the head: `**Pattern:** Matches BD-119 §9.2 reconciliation-doc pattern (pack-memory rule "Architect-doc-vs-reality reconciliation").` |
| NIT | NIT-2 | Reconciliation triad leg (a) in-code docstring naming the realized consumer is missing. SHOULD-1 IMPL-REPORT rationalizes "shell-not-Python so has no docstring slot" — but bash supports function header comments routinely used as docstrings. Whether leg (a) is required depends on whether the consumer is design-specific (like BD-160 `migrator_target_surface_for_version`) or generic (like `stage_s4_skills()` which iterates ALL skills). The rule's worked example assumed the former; this case is the latter. | fd8eb10 (accepted by ff5e9cd + 20bf767) | EITHER (a) add a function-header comment to `stage_s4_skills()` at `scripts/init-project.sh:484` naming `boundary-investigation` as one of the F4-bundle consumers per BD-175 §6.1, OR (b) update pack-memory rule to clarify that leg (a) is optional when the consumer is a generic loop and the architect-doc addendum suffices. The latter is a structural rule clarification (architect-pass material per pack-memory "Pack-architect spawn protocol"); the former is a small mechanical edit. |

Both NITs are documentation-completeness, not substantive correctness.
The substantive content of the supersession narrative and the sweep is
correct.

---

## §6 — Verification commands ran (with output)

### Cmd 1: HEAD verification

```
$ git rev-parse HEAD
20bf76760addca55481c99895876ca9b751220e7
```

### Cmd 2: Commits-in-scope ordering

```
$ git log --oneline fd8eb10^..20bf767 -- \
    maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
20bf767 fix: v11 — BD-175 T1 NIT exhaustive sweep ...
ff5e9cd fix: v11 — BD-175 ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS T1 NIT section-name locator ...
fd8eb10 fix: v11 — BD-175 ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS architect-doc addendum ...
```

### Cmd 3: Sweep target zero hits

```
$ grep -nE 'PACK-AGENTS\.md:[0-9]+' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
(zero hits)
```

### Cmd 4: Canonical anchor count = 17

```
$ grep -c 'PACK-AGENTS\.md § "PM-only files and directories"' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
17
```

### Cmd 5: Soft-locator zero hits

```
$ grep -nE 'line ~[0-9]|line ~ [0-9]|~329|~ 329' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
(zero hits)
```

### Cmd 6: file:NNN form (verify only L416 hybrid remains)

```
$ grep -nE '[A-Za-z_.-]+\.(md|py|sh|toml):[0-9]+' \
       maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
416:docs/pack/PM-CHAT.md:47 § "Pack agent roster"). The corrected
```

### Cmd 7: PACK-AGENTS.md heading byte-for-byte match

```
$ grep -n '^\*\*PM-only files and directories\*\*' pack-ops/PACK-AGENTS.md
140:**PM-only files and directories** are off-limits to all agents unless the
```

Anchor text in architect doc matches L140 bold-paragraph heading exactly.

### Cmd 8: Realized-consumer verification

```
$ ls project-template/skills/boundary-investigation/
SKILL.md
```

Pattern A path exists at the project-template surface as named by §6.1.

```
$ grep -n "^stage_s4_skills\|^# stage_s4_skills" scripts/init-project.sh
484:stage_s4_skills() {
```

Realized consumer at L484-507 of `scripts/init-project.sh`, generic
per-skill loop that iterates `$PACK/project-template/skills/*/` and
copies each `SKILL.md` to 3 CLI dirs. No in-code docstring naming
BD-175 §6.1 as one of the F4-bundle consumers (relevant to NIT-2).

### Cmd 9: Cumulative-commits scope (only 2 files per commit; only architect doc + IMPL-REPORTs)

```
$ git show fd8eb10 --name-only --format=""
maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md

$ git show ff5e9cd --name-only --format=""
maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-T1-NIT.md

$ git show 20bf767 --name-only --format=""
maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-T1-NIT-SWEEP.md
```

Zero touches to project-template/, scripts/, pack-ops/, supporting-docs/,
test-fixtures/, pack-root trinity. POQ-F4-3 deferred-to-BD-178 honored.

---

## §7 — Out-of-scope observations

Logged but not actionable for this cumulative review:

1. **53 total `PACK-AGENTS.md` mentions in the architect doc.** 17 use
   the canonical anchor (sweep targets). The remaining 36 are bare-file-
   name references in semantic contexts where they appear by design —
   e.g., L8 (inputs-read manifest), L33/L56/L71 (boundary-discipline
   narrative naming the pack-only file as an exemplar to AVOID), L387/
   L392 (deny-list bullet lists), L569/L578/L585 (§8.1a verbatim block
   paste), L634/L640 (deny-list table cells), L796 (M1b table cell
   short-form), L865/L866/L869 (test descriptions), L1077 (§16.3 paste).
   These are legitimately out-of-scope for a "line-number drift" sweep —
   they are bare-filename mentions, not `PACK-AGENTS.md:NNN` line-number
   locators. The 20bf767 sweep commit message confirms this: scope was
   narrowed to `PACK-AGENTS.md:NNN` → canonical anchor only.

2. **L796 table cell "Per PACK-AGENTS.md PM-only list".** This is a
   table-cell short-form ref that does not carry the canonical anchor.
   The cell sits in the §10.2 keyword-table next to a richer §8.1a
   table at L534 that DOES carry the canonical anchor. The asymmetry is
   defensible (table cell brevity) but could be aligned for consistency
   if Pack Chat wants. Not flagged as a NIT because the L796 row is a
   shorter "summary" form of L534 and the architect doc is internally
   consistent on this — many table cells use the bare filename and rely
   on prose nearby for the full anchor.

3. **Test infra suggestion (not for this commit).** A CI grep gate
   could enforce the "no `PACK-AGENTS.md:NNN` in architect docs"
   rule mechanically — `grep -rE 'PACK-AGENTS\.md:[0-9]+'
   maintenance-docs/` should return zero hits across the entire
   directory. Worth considering for a future BD if the line-number-
   drift rule becomes load-bearing across more architect docs.

4. **The "write-once review-report anchor" disposition class** that the
   20bf767 IMPL-REPORT §3b surfaced is a worthwhile addition to the
   pack-memory rule vocabulary. The current rule says "never line numbers
   — line numbers drift," but the SHA-pinned audit-trail + write-once-
   review-report exemptions are legitimate carve-outs that the rule
   would benefit from naming explicitly. Whether to amend pack-memory
   is a Pack-Chat / architect-pass decision per the "Pack-architect
   spawn protocol" rule. Out-of-scope for this cumulative review.

5. **NIT-2 alternative resolution path.** If Pack Chat triages NIT-2 as
   FIX leg (a), the natural in-code docstring placement would be a
   function-header comment at `scripts/init-project.sh:484`:
   ```
   # stage_s4_skills — per-skill loop that auto-distributes pack
   #   skills to the three client CLI dirs at install time. Realizes
   #   the F4-bundle Pattern A shape for boundary-investigation skill
   #   per BD-175 §6.1 reconciliation addendum (and 30+ other skills
   #   following the same Pattern A convention). See
   #   maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-
   #   PREVENTION-MECHANISMS.md §6.1 for the supersession context.
   ```
   But this is structurally awkward because the function isn't
   boundary-investigation-specific. The alternative (clarify the rule
   that leg (a) is optional for generic-loop consumers) may be the
   cleaner long-term shape. Either is a small follow-up commit.

---

## §8 — Approval gate

The cumulative state of the architect doc at HEAD `20bf767` is:
- Substantively correct per both rules (Architect-doc-vs-reality
  reconciliation + no line-number drift).
- Mechanically complete (post-sweep grep + canonical-anchor count
  verifications all PASS).
- Scope-disciplined (zero scope creep beyond the architect doc + own
  IMPL-REPORTs).
- Coherently sequenced (addendum → mini-NIT fix → broader sweep).

Approve with two NITs (NIT-1 and NIT-2) for Pack Chat triage. Both
NITs are documentation-completeness concerns within the reconciliation
rule, not substantive correctness defects.

End of report.
