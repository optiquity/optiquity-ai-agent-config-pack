# AUDIT-BD-195-VERIFIED-FINDINGS

**Status:** Verified output of the gated BD-195 fresh-discovery workflow.
**HEAD:** `3178fa4` (`3178fa4f666326ac3eac26238b6e96ad25b60f71`), branch `v11-dev`.
**Workflow:** 15-surface read-only fan-out + synthesize/dedup + 3-state
adversarial verification (every embedded prompt was approved by the
prompt-validation gate).

**Totals (verbatim from the workflow result):**

- Surfaces reporting: 15 / 15
- Raw findings: 72
- Deduped findings: 68
- **Confirmed: 67**
- Flagged (ruling-finding-absent): **0**
- False-positive: **1**

Each confirmed finding below is repo-grounded (`file:line` + verbatim
`evidence`) and adversarially verified (`status: real`). This document is
a faithful transcription FROM the workflow's result object — nothing is
added, judged, reclassified, or invented. Findings are grouped by kind in
the order K1, K2, K3, K4, K5, K7, B.

**Per-kind confirmed counts:** K1 = 14 · K2 = 2 · K3 = 13 · K4 = 5 ·
K5 = 15 · K7 = 1 · B = 17 (total 67).

---

## K1 — pack-self-token-in-project-entity-grammar (14)

### K1.1 · `scripts/lib/tracker-phase-task.sh:132` · ruling JC-1

Evidence:

```
printf '%s\n' '^[[:space:]]*-[[:space:]]+(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)([[:space:]]+(.*))?$'
```

Why: K1 (pack-self-token-in-project-entity-grammar). Emitted POSIX-ERE for
`tracker_phase_task_dependency_re()` — the canonical grammar matching a
project-side IMPLEMENTATION-PLAN.md phase-task Dependencies bullet. The
alternation admits `BD-[0-9]+` as a valid phase-task dependency target.
JC-1 names this K1 epicenter: strip BD- + add error-guard; pack own-backlog
BD- handling untouched.

### K1.2 · `scripts/lib/tracker-phase-task.sh:207-209` · ruling JC-1

Evidence:

```
DEP_ENTRY = re.compile(
    r'^\s*-\s+(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?\s*$'
)
```

Why: K1. The internal Python `DEP_ENTRY` regex (the actual parser invoked
by tracker_phase_task_parse) admits `BD-\d+` as a phase-task
Dependencies-bullet ID — canonical-Python counterpart of the bash regex at
line 132. Admits a pack identifier into a project-side phase-task entity
grammar; second encoding surface that must change in lock-step.

### K1.3 · `scripts/lib/tracker-phase-task.sh:75` · ruling JC-1

Evidence:

```
#       Dependencies entry: `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)`.
```

Why: K1. The public-API docstring for tracker_phase_task_dependency_re
documents `BD-\d+` as a recognized phase-task Dependencies-entry ID.
Documents the same project-grammar BD- admission as lines 132/208 — a
documentation surface that encodes the leaked grammar.

### K1.4 · `scripts/lib/tracker-phase-task.sh:113` · ruling JC-1

Evidence:

```
#   group 1 = the pack-id (`phase-N(.M)?` | `TD-N` | `BD-N`)
```

Why: K1. Capture-group documentation for the phase-task dependency regex
lists `BD-N` as a valid group-1 pack-id for a phase-task Dependencies entry.
Same project-grammar BD- admission, documentation surface.

### K1.5 · `scripts/lib/tracker-promote.sh:1155` · ruling JC-1

Evidence:

```
if [[ "$b_raw_id" =~ ^(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)$ ]]; then
```

Why: K1 (promotion path into project phase-task Dependencies). Guards which
TD-blocker tokens get a blocked-by link created for a newly-promoted
phase-task. The alternation admits `BD-[0-9]+` as a valid dependency target
flowing INTO a project-side phase-task entity. The TD->phase-task promotion
validator is in JC-1's blast radius. (Distinct from entry-Blockers grammar
in tracker-migrate-forward.sh:990 which JC-1 leaves untouched.)

### K1.6 · `scripts/lib/tracker-promote.sh:390-391` · ruling JC-1

Evidence:

```
# Dependencies bullet handling: the TD entry's blockers field is a
# list of v10 grammar tokens (BD-NNN, TD-NNN, phase-N, phase-N.M). We
# emit them verbatim
```

Why: K1 (documentation of BD- in emitted phase-task Dependencies).
tracker_promote_compose_phase_task_block emits the phase-task bullets for a
NEW project phase-task, and this comment documents that BD-NNN tokens from
the TD's blockers are emitted verbatim into the phase-task's Dependencies
bullet. The emitted deliverable carrying BD- violates deliverable-only
cleanliness corollary.

### K1.7 · `scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md:26` · ruling JC-1

Evidence:

```
Inside task `#### 3.3 — Cross-phase wiring`, `Dependencies:` block:
  - phase-7.4
  - BD-108
  - TD-030 see TD-029: blocking on schema-bootstrap
  - TD-031 #issue-tracker-link
```

Why: A pack identifier (`BD-108`) is admitted into a project-side
phase-task `Dependencies:` (dependency-target) grammar, beside legitimate
project tokens phase-N.M and TD-NNN. K1 verbatim. JC-1 names this: `BD-`
admitted into the project phase-task dependency grammar via the tracker
libs' tests/fixtures. Categorical-principle-first.

### K1.8 · `scripts/tests/test-tracker-phase-task.sh:113` · ruling JC-1

(encoding surface: test asserting the contaminated grammar)

Evidence:

```
assert_contains "1.2 regex names BD-NNN"      "$dep_re" "BD-[0-9]+"
```

Why: The test ENCODES the contaminated grammar: it asserts the exported
project phase-task dependency regex names `BD-[0-9]+` as a valid dependency
target alongside phase-N.M and TD-NNN. Per enumerate-encoding-surfaces, the
test asserting the grammar's content invariant is an encoding surface of the
K1 defect JC-1 targets. Surface-blind-union grammar (K7) also implicated.

### K1.9 · `scripts/tests/test-tracker-phase-task.sh:132` · ruling JC-1

(test fixture input)

Evidence:

```
    '  - BD-108  trailing spaces in annotation  '   (element of sample_lines[] fed to both the bash dep regex and the inline Python DEP regex as a representative `Dependencies:` bullet)
```

Why: A literal `BD-108` `Dependencies:`-bullet sample used as parser input
to exercise the phase-task dependency grammar — BD treated as a project-side
phase-task dependency target. K1; part of the JC-1
tracker-libs-tests/fixtures target.

### K1.10 · `scripts/tests/test-tracker-phase-task.sh:204-205` · ruling JC-1

(encoding surface: test asserting BD captured as project dep target)

Evidence:

```
# 2.5 BD reference inside Dependencies (phase-3.3 has BD-108)
assert_eq "2.5 phase-3.3 dep[1].target = BD-108" "BD-108" \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[2].dependencies[1].target')"
```

Why: The test asserts that the project-side phase-task parser captures
`BD-108` as a `dependencies[].target` — asserts the contaminated behavior is
correct. K1, and an encoding surface of the JC-1 defect (the test must flip
to a rejection/error-guard assertion once BD is stripped).

### K1.11 · `scripts/tests/test-tracker-links.sh:106` · ruling JC-1

(encoding surface: project link-target id-shape validator test)

Evidence:

```
if tracker_links_validate_id_shapes "TD-029"    "BD-108"    2>/dev/null; then t_pass "1.4 TD-NNN + BD-NNN"; else t_fail "1.4 TD-NNN + BD-NNN"; fi
```

Why: The test asserts the project-side link id-shape validator ACCEPTS
`BD-108` as a legal link target, in the same id-shape vocabulary as project
tokens phase-N / phase-N.M / TD-NNN. Admits a pack identifier into the
project-side link/dependency grammar (K1) and is exactly the validator JC-1
says must instead error-guard on `BD-`.

### K1.12 · `scripts/tests/test-tracker-links.sh:169` · ruling JC-1

(encoding surface: project blocked-by link creation with BD target)

Evidence:

```
out=$(tracker_links_create_blocked_by "TD-031" "BD-108" "$ID_MAP" "$store" "" 2>&1)
```

Why: The test creates a project-side `blocked-by` link whose target is the
pack identifier `BD-108`, exercising and validating BD-as-project-dependency-
target end-to-end. K1; part of the JC-1 tracker-links-test target.

### K1.13 · `scripts/tests/test-tracker-cycle-check.sh:168` · ruling JC-1

(encoding surface: cycle-check store seeds BD as project link nodes)

Evidence:

```
write_store "$store" "TD-031,TD-029" "BD-110,BD-108" "phase-3.1,phase-3.2"
```

Why: The cycle-check test seeds the project-side link store with pack
identifiers `BD-110,BD-108` as link nodes alongside project tokens (TD-*,
phase-*), exercising BD as a project-side dependency/link participant. K1;
part of the JC-1 tracker-libs-tests target.

### K1.14 · `scripts/tests/fixtures/tracker-links/id-map.json:5-6` · ruling JC-1

(fixture data backing the link/cycle tests)

Evidence:

```
  "BD-108": {"id": "2108", "url": "https://example.com/issues/2108"},
  "BD-110": {"id": "2110", "url": "https://example.com/issues/2110"},
```

Why: The id-map fixture that backs tracker-links / cycle-check tests lists
pack identifiers `BD-108`/`BD-110` as resolvable link nodes interleaved with
project tokens (TD-*, phase-*). The fixture data that makes
BD-as-project-link-target resolvable. K1; the JC-1 fixtures target.

---

## K2 — pack-self-ref-on-client-shipped-surface (2)

### K2.1 · `project-template/skills/pm-startup/SKILL.md` (and identical copies `project-template/.claude/skills/pm-startup/SKILL.md`, `project-template/.codex/skills/pm-startup/SKILL.md`) · lines 173-176 in all three copies; the path token at line 174 · ruling none

(also category-B path leak)

Evidence:

```
This is the expected first-run state on a project that has not yet copied `supporting-docs/METHODOLOGY.md` into `docs/pack/`. Surface it to the developer so they run `init-project.sh` (new install) or the appropriate migrator (existing project).
```

Why: `supporting-docs/` is a pack-only directory (never installed at a
client). This pm-startup skill ships to every client. Referencing
`supporting-docs/METHODOLOGY.md` as the copy-source surfaces a pack-internal
path on a client-gated surface — both a pack-self reference (Ban A / K2) and
a dangling path (category-B). No JC ruling names this occurrence; reported
explicitly per foundation §C.

### K2.2 · `project-template/scripts/bootstrap.sh` · lines 46-49 (primary); 51 (secondary/weaker) · ruling none directly

Kind: K2 (pack-self-ref-on-client-shipped-surface; Ban A) — with a K4
component (client-shipped surface references pack-only docs/scripts clients
never receive). Ruling: none directly (JC-2 broadens the client-surface leak
GUARD to catch bare pack-doc basenames + bare-prose non-backtick refs on
.example/.proto/etc.; JC-3 is the close analogue — a pack-doc ref that is a
K4 leak BY LOCATION on a client-gated project-template/ file. Neither JC
ruling names bootstrap.sh, so recorded as 'none' with JC-2/JC-3 as
governing-class analogues.)

Evidence:

```
46: # Skills are distributed at project creation time from the pack's
47: # project-template/skills/ directory directly into .claude/skills/,
48: # .codex/skills/, and .gemini/skills/ by `init-project.sh` (see
49: # in the pack repo: supporting-docs/SETUP-NEW.md Step 3).
50: # Once committed to git they do not need to be redistributed here.
51: # To update skills after a pack version upgrade, see the migration guide.
```

Why: bootstrap.sh lives under project-template/scripts/ — client-gated by
location. The comment references multiple pack-internal artifacts a client
never receives: (a) phrase 'in the pack repo' (direct pack-self ref, Ban A /
K2); (b) 'supporting-docs/SETUP-NEW.md' (pack-root-only = K4); (c)
'`init-project.sh`' (pack-root-only); (d) 'the pack's' and 'migration guide'
framing addressed to a pack-repo reader. Governing principle:
categorical-principle-first.

---

## K3 — dangling-reference-to-removed-or-superseded-doc (13)

### K3.1 · `scripts/lib/tracker-migrate-forward.sh:238` · ruling none

Evidence:

```
# documented in maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md
# §4.1 and carried forward unchanged in V3.3 §4.1.
```

Why: K3 (dangling-reference-to-removed-doc). A live source-comment in a
shipped pack library cites
`maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md` (BD-195 prison
DELETED set) as the authoritative schema-documentation source; the path no
longer resolves (find returns nothing). Content survives in
ARCHITECTURE-V3.3-DELTA.md (also cited, EXISTS), but the V3.2-DELTA.md
reference dangles. Live source file, not historical narrative; not
JC-5-protected.

### K3.2 · `scripts/lib/tracker-phase-task.sh:78-79` · ruling none

Evidence:

```
# Reference: ARCHITECTURE-V3.3-DELTA.md §2, §3.5, §4.1-§4.4, §5.3,
#            §6.4; ARCHITECTURE-V3.2-DELTA.md §4.1, §4.2, §4.3.
```

Why: K3 (dangling-reference-to-removed-doc). The Reference comment cites
`ARCHITECTURE-V3.2-DELTA.md`, a doc in the BD-195 prison DELETED set absent
at HEAD. The co-cited ARCHITECTURE-V3.3-DELTA.md DOES resolve and is NOT a
finding. The dangling V3.2-DELTA basename is a reference to a deleted doc
(K3). Bare basename, so JC-2's bare-basename concern also applies, but the
categorical defect is the dangling removed-doc reference.

### K3.3 · `pack-ops/BACKLOG.md:3135` · ruling none (K3 candidate; no JC ruling names BACKLOG.md as a target — JC-5 governs CHANGELOG, not BACKLOG)

Evidence:

```
Re-audited vs post-BD-196 HEAD `c73077d` (`maintenance-docs/v11-implementation/AUDIT-BD-195-REFRESH-POST-BD196.md`): 48/49 problems live ... Disposition (user, 2026-05-31): RE-SCOPE into FOUR work-shape segments under this BD, per `maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-SEGMENTATION.md` (which SUPERSEDES the rejected BD-185-gate `ARCHITECTURE-BD-195-RESCOPE.md`).
```

Why: K3 (reframed): a live doc cites deleted/superseded docs as
authoritative. This is the BD-195 entry itself (Status: Open) citing three
DELETED-set docs as authoritative inputs to in-progress work:
AUDIT-BD-195-REFRESH-POST-BD196.md, ARCHITECTURE-BD-195-SEGMENTATION.md,
ARCHITECTURE-BD-195-RESCOPE.md. Live forward-pointing guidance an agent is
meant to act on. Governing principle: delete-by-default +
never-read-contaminated.

### K3.4 · `pack-ops/BACKLOG.md:3137` · ruling none (K3 candidate; no JC ruling targets BACKLOG.md)

Evidence:

```
Segments (2026-05-31, per ARCHITECTURE-BD-195-SEGMENTATION.md; SERIAL execution in this branch):
```

Why: K3: the live BD-195 entry's 'Segments' subsection (Status: Open)
attributes its entire S0-S4 segmentation structure to
ARCHITECTURE-BD-195-SEGMENTATION.md, a deleted doc. An agent executing this
BD is directed to a non-resolving authority for the segment definitions it
must follow. distrust-derived-claims + never-read-contaminated.

### K3.5 · `pack-ops/BACKLOG.md:3168` · ruling none (K3 candidate; no JC ruling targets BACKLOG.md)

Evidence:

```
Detailed as P-09/P-17/P-18 in `maintenance-docs/v11-implementation/AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (G3 decision, 2026-05-29: OQ-1(3)/OQ-3; swept per S1·C5 2026-05-31).
```

Why: K3: Step 9 of the live BD-195 entry (Status: Open) cites
AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md as the authoritative detail source
for the BD-185-artifact disposition an agent must perform. The cited doc is
in the DELETED set and does not resolve. delete-by-default +
never-read-contaminated.

### K3.6 · `supporting-docs/SETUP-EXISTING.md:12, 18` · ruling none (K3/K5 candidate; JC-3 concerns project-template/README.md, a different file)

Kind: K3 — dangling-reference-to-removed-or-superseded-doc (+ K5
version-currency).

Evidence:

```
Line 12: "(If any AI config is present, `init-project.sh` stops with exit code 20 and routes you to `MIGRATION-v9-to-v10.md` or asks you to archive the other AI tooling first.)"  Line 17-18: "**If your project is already on a prior pack version (v9.3):** see `MIGRATION-v9-to-v10.md`."
```

Why: K3: SETUP-EXISTING.md is a live setup guide that twice routes the
reader to `MIGRATION-v9-to-v10.md` as a present, readable target with NO
historical/sunset framing. That doc was removed in v11 (find returns
nothing). Contrast: MIGRATION-v10-to-v11.md + INSTALL-PROCEDURES.md reference
the same basename CORRECTLY with sunset/historical framing and a `git
checkout v10` recipe. SETUP-EXISTING.md gives no such framing, so the
reference dangles. Also K5: 'prior pack version (v9.3)' and v9->v10 routing
are stale against a v11 pack.

### K3.7 · `QUICKSTART.md:34` · ruling none

Kind: K3 (dangling-reference-to-removed-or-superseded-doc).

Evidence:

```
- **v9 → v10:** [`supporting-docs/MIGRATION-v9-to-v10.md`](supporting-docs/MIGRATION-v9-to-v10.md)
```

Why: K3 dangling reference: this live doc cites
supporting-docs/MIGRATION-v9-to-v10.md as a present, linkable migration
guide, but the file does not exist. README.md:156 and :198 explicitly state
the v9->v10 migrator + guide were sunset in v11 per BD-121. The hyperlink
target no longer resolves.

### K3.8 · `README.md:163` · ruling none

Kind: K3 (dangling-reference-to-removed-or-superseded-doc) / B (dangling
internal path).

Evidence:

```
├── GEMINI-CLI-ANALYSIS.md                  Gemini CLI analysis (deprecated)
```

Why: The README Repository Layout block — the pack's LIVE authoritative
repo-layout reference — lists maintenance-docs/GEMINI-CLI-ANALYSIS.md as a
present file in the maintenance-docs/ tree, but the file is deleted (BD-195
DELETED set; ls returns No such file or directory). A reader following the
layout map finds nothing. K3 dangling-reference / category-B dangling
internal path; this is a current directory map asserting presence, not
historical narrative (not JC-5-protected).

### K3.9 · `README.md:164` · ruling none

Kind: K3 (dangling-reference-to-removed-or-superseded-doc) / B (dangling
internal path).

Evidence:

```
├── ANDROID-ANALYSIS.md                     Android support analysis (deprecated)
```

Why: The Repository Layout block lists maintenance-docs/ANDROID-ANALYSIS.md
as a present file, but it is deleted (BD-195 DELETED set; ls returns No such
file or directory). K3 dangling-reference / category-B dangling internal
path; current presence-claim map, not historical narrative.

### K3.10 · `README.md:170` · ruling none

Kind: K3 (dangling-reference-to-removed-or-superseded-doc) / B (dangling
internal path).

Evidence:

```
│   ├── V10-PREDESIGN.md, V10-DESIGN-PROCESS-PLAN.md
```

Why: The archive listing in the live authoritative Repository-Layout map
names maintenance-docs/archive/V10-PREDESIGN.md as a present archived doc,
but V10-PREDESIGN.md is deleted (BD-195 DELETED set). The sibling
V10-DESIGN-PROCESS-PLAN.md on the same line DOES exist and is NOT a defect.
Only the V10-PREDESIGN.md token is dangling. K3 / category-B dangling
internal path.

### K3.11 · `maintenance-docs/TOOL-COMPARISON.md:5-6, 217-218, 220-221` · ruling none

Kind: K3 — dangling-reference-to-removed-or-superseded-doc. Ruling: none
(K3 is governed by no JC ruling directly; JC-5 governs the
historical-narrative class but its carve-out does NOT apply here because this
is a live present-tense directive, not frozen history — distinguished from
JC-5's CHANGELOG-v8 case).

Evidence:

```
L5-6 (header banner): '*Supersedes: GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md. Deprecation notices / are added to those files in Step 2 of V9-DESIGN.md.*'  L217-218 ("### Deprecated analysis documents"): '- `maintenance-docs/GEMINI-CLI-ANALYSIS.md` — content absorbed here / - `maintenance-docs/ANDROID-ANALYSIS.md` — content absorbed here'  L220-221: 'Both files remain in the repo for historical reference but should not be / treated as current. This document takes precedence.'
```

Why: K3 (reframed): a LIVE doc cites deleted docs as present/authoritative.
TOOL-COMPARISON.md self-declares 'living reference' (L4) and 'authoritative
reference' (L12) — a current, non-archived operating reference. It asserts
GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md 'remain in the repo' (L220),
but both are in the BD-195 deleted prison set and resolve nowhere. The
L217-218 paths are dangling. The L220-221 banner directive is a live
present-tense instruction, so JC-5's carve-out does NOT cover it. Secondary:
L6's bare 'V9-DESIGN.md' now lives at maintenance-docs/archive/ (relocated)
but still resolves (weaker defect).

### K3.12 · `pack-ops/CHANGELOG.md:451, 481-482, 562, 564` · ruling JC-5 (accurate historical narrative; leave content; output is soft-advisory guard only, no hand-correction)

Kind: K3 — dangling-reference (JC-5-governed historical narrative; reported
for completeness, NOT for hand-correction).

Evidence:

```
451: V9-AUDIT-REPORT.md, GEMINI-CLI-ANALYSIS.md.
481-482: ... cross-tool operational differences. Supersedes GEMINI-CLI-ANALYSIS.md and\n  ANDROID-ANALYSIS.md.
562: - `supporting-docs/ANDROID-ANALYSIS.md` — analysis of what would be needed for
564: - `supporting-docs/GEMINI-CLI-ANALYSIS.md` — analysis of Gemini CLI integration
```

Why: These CHANGELOG entries name GEMINI-CLI-ANALYSIS.md /
ANDROID-ANALYSIS.md (DELETED prison set) within accurate v8/v9
version-history records. JC-5 EXPLICITLY rules lines 562/564 as accurate v8
history that is NOT hand-corrected; only a SOFT-advisory guard, never
hard-fail. Lines 451 and 481-482 are the same class (v8/v9 supersession
history). Reported per the foundation's 'report such findings explicitly'
instruction.

### K3.13 · `pack-ops/BACKLOG.md:3061, 3690, 4169, 4284, 4300, 4302, 4304` · ruling JC-5-class (historical/process narrative within BD entries; pattern-parallel to JC-5's CHANGELOG ruling; deep disposition is PG-12's)

Kind: K3 — dangling-reference (historical BD-entry narrative; reported for
completeness).

Evidence:

```
3061: - POQ-4 reversal documentation in `ARCHITECTURE-BD-185.md` / `PLAN-BD-185.md` (separate Pack Chat work; commits separately)
3690: and cost routing. Supersedes GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md.
4169: maintenance-docs/V10-PREDESIGN.md Candidate Decision 10.
4284: File/Symbol: maintenance-docs/V10-DESIGN.md — approved design record (supersedes V10-PREDESIGN.md)
4300/4302/4304: Full design discussion captured in V10-PREDESIGN.md ... V10-PREDESIGN.md must be updated ... should not move to Unblocked until V10-PREDESIGN.md has been through a formal design
```

Why: BACKLOG entries reference deleted prison-set docs: ARCHITECTURE-BD-185.md
/ PLAN-BD-185.md (3061; bare non-V2 variants GONE),
GEMINI-CLI-ANALYSIS.md/ANDROID-ANALYSIS.md (3690), V10-PREDESIGN.md
(4169/4284/4300/4302/4304). These read as accurate historical/process
narrative within BD entries rather than live presence-maps (JC-5-class).
Reported explicitly per the open-category rule; final FIX-vs-historical
disposition belongs to PG-12's deep scan which owns these files.

---

## K4 — client-shipped-dead-pack-doc-reference (5)

### K4.1 · `project-template/README.md:9` · ruling JC-3

Evidence:

```
Then copy the supporting docs individually (they are not part of this template). METHODOLOGY.md lives under `docs/pack/` per V10-DESIGN.md Part 7 §7.6 (alongside other pack-distributed docs):
```

Why: Foundation A/K4 + JC-3: a client-shipped surface references
V10-DESIGN.md — a pack-only doc that exists only at
maintenance-docs/archive/V10-DESIGN.md and is never delivered to clients.
JC-3 names exactly this finding: strip the V10-DESIGN.md ref.

### K4.2 · `project-template/.codex/config.toml.example:13` · ruling JC-2

Evidence:

```
# Source: V10-CODEX-MCP-RESEARCH.md (commit 73d480e). Codex supports
```

Why: Foundation A/K4 + JC-3 location principle: this file lives under
project-template/ (client-gated by location). It cites
V10-CODEX-MCP-RESEARCH.md, a pack-only maintenance doc clients never receive,
AND cites a commit SHA as provenance ('commit 73d480e') — JC-2 names bare
commit-SHA-as-provenance and scanning .example files as in-scope
client-surface leak shapes.

### K4.3 · `project-template/.gemini/commands/pm-startup.toml:171` · ruling none

Evidence:

```
first-run state on a project that has not yet copied
`supporting-docs/METHODOLOGY.md` into `docs/pack/`. Surface it to
```

Why: This client-shipped surface references `supporting-docs/METHODOLOGY.md`
— a path under the pack-only directory `supporting-docs/`, which exists only
at pack root and is never shipped to a client project. On a client install
there is no `supporting-docs/` directory, so a project-side reader cannot
resolve the cited source path (K4). No JC ruling names line 171; reported as
an open K4 candidate for Step-9 disposition.

### K4.4 · `project-template/docs/pack/PM-CHAT.md:528-530` · ruling none (JC-2 governs the guard *design* for this class but names no specific target on CS-4; reported under categorical-principle-first + directory-based principles)

Evidence:

```
For the per-file customization-preservation behavior of
`pack tracker init`'s forward migration, see
`docs/pack/MERGE-STRATEGY.md`
```

Why: PM-CHAT.md is installed into the client at docs/pack/PM-CHAT.md. The
primary reference path `docs/pack/MERGE-STRATEGY.md` does NOT resolve at a
client install: MERGE-STRATEGY.md exists only at pack-ops/MERGE-STRATEGY.md
and is NEVER staged into the client. K4 (client-shipped surface references a
pack-only doc) and K3 (dangling reference). The DENY-LIST-wrapped fallback on
lines 531-534 is correctly gated; the defect is the un-gated primary client
path on line 530.

### K4.5 · `project-template/docs/pack/OPTIONAL-FEATURES.md:174` · ruling none (the bare-pack-doc-basename concern is the subject of JC-2's guard broadening; JC-2 names no specific CS-4 target — reported under categorical-principle-first)

Kind: K4 — client-shipped-dead-pack-doc-reference (bare basename, pack-only
doc).

Evidence:

```
your pre-migration content. See `MERGE-STRATEGY.md` in the pack repo
for the per-file class matrix and sidecar conventions.
```

Why: OPTIONAL-FEATURES.md is a client-shipped surface. It directs the client
reader to a bare pack-doc basename `MERGE-STRATEGY.md` explicitly qualified
`in the pack repo` — but the pack repo is not present at a client install, so
the reference is dead. This is the exact class JC-2 calls out (bare pack-doc
basenames on a client surface) and K4. MERGE-STRATEGY.md lives only at
pack-ops/.

---

## K5 — version-currency-staleness (15)

### K5.1 · `project-template/README.md:1` · ruling JC-3

Evidence:

```
# Project Template — AI Agent Config Pack v10
```

Why: Foundation A/K5: a stale version label that misleads a reader. Current
major version is v11. This client-facing project-template README title still
reads v10. JC-3 explicitly directs de-versioning (v10→v11) of
project-template/README.md.

### K5.2 · `project-template/.codex/config.toml.example:16` · ruling none

Evidence:

```
# `experimental_use_rmcp_client`). v10 ships STDIO only; HTTP transport
```

Why: Foundation A/K5: stale version label on a client-gated surface. 'v10
ships STDIO only' refers to the prior major version; current is v11. The 'v10
ships' phrasing misleads a v11 reader about what the current pack ships.

### K5.3 · `project-template/.gemini/commands/pm-startup.toml:125` · ruling JC-6

Evidence:

```
   manifest in v10 is exactly one path: `docs/pack/METHODOLOGY.md`
```

Why: The literal phrase 'in v10' labels the RAG ingestion manifest default
against v10 while v11 is the current major version (foundation K5). This is a
client-shipped surface; the stale label misrepresents the current manifest
version baseline. JC-6 directs version-neutralizing the pm-startup
RAG-manifest 'in v10' label across the pm-startup triad; only the Gemini
variant is in CS-2.

### K5.4 · `project-template/skills/pm-startup/SKILL.md` (and identical copies `project-template/.claude/skills/pm-startup/SKILL.md`, `project-template/.codex/skills/pm-startup/SKILL.md`) · line 128 in all three copies · ruling JC-6

Kind: K5 — version-currency-staleness (governing ruling JC-6); also
category-B per JC-6 framing.

Evidence:

```
   manifest in v10 is exactly one path: `docs/pack/METHODOLOGY.md`
```

Why: v11 is the current major version. The hard-coded 'in v10' RAG-manifest
label on a client-shipped startup skill misleads a v11 reader about the
current default. Foundation §A K5. JC-6 rules: version-neutral the
pm-startup RAG-manifest 'in v10' label across the pm-startup triad.

### K5.5 · `project-template/docs/pack/HELP-FRAGMENT.md:14` · ruling none

Evidence:

```
| `bash scripts/migrate-v9-to-v10.sh` | One-time per upgrade. v10→v11 migrator ships separately. |
```

Why: HELP-FRAGMENT.md is a v11 surface. Its verb manifest lists
`migrate-v9-to-v10.sh` as the current upgrade command and relegates the
actual current migrator to a parenthetical. For a v11 client the relevant
upgrade path is v10→v11; the pack ships `scripts/migrate-v10-to-v11.sh`.
Presenting the v9→v10 migrator as the headline verb misleads (K5).
Secondary: project-template/scripts/ ships no migrator at all, so the path
also will not resolve at the client.

### K5.6 · `project-template/docs/pack/prompts/pm-chat.md:35` · ruling none

Evidence:

```
**Pack version:** AI Agent Config Pack v10
```

Why: This is the kickoff-variant template the developer pastes to start a
v11 PM chat. The default Pack version label reads `v10`. Every other
docs/pack file in this surface carries `v11`. Shipping a v11 template whose
kickoff prompt seeds `v10` as the pack version is stale-version-label
staleness (K5).

### K5.7 · `project-template/docs/pack/PACK-FEEDBACK.md:40, 163, 297, 313, 331, 337, 352, 358, 359, 372, 378, 389, 395, 414, 420, 436, 439` · ruling none (JC-5 protects accurate historical CHANGELOG narrative; it does not cover stale template-default version labels in a freshly-shipped v11 template)

Evidence:

```
L40 `| Pack version in use | v9.[N] |`; L163 `blocks the project or indicates a broken v9 defect.`; L297 `Q1–Q4 are seed questions from the v9 auditor fix pass`; L313/337/358/378/395/420 `**Asked by Pack Chat:** [v9 release date]`; L359 `After the v9 split, auditor-ui covers only`; L436 `while using v9. May take months to produce data`
```

Why: PACK-FEEDBACK.md ships as part of the v11 pack (provenance line 28). It
is a FRESH template a new v11 project installs and fills in. Its seed content
pervasively labels the pack as v9. A v11 client installing this template
receives a feedback log pre-seeded to v9 (K5). Distinct from JC-5's protected
accurate historical narrative — here the file is a live template for new v11
work, so the v9 labels are stale defaults, not history.

### K5.8 · `xcode-companion-templates/README.md:24` · ruling JC-5 (reconfirm-only — does NOT apply as protection). JC-5 protects accurate historical narrative; this line is a live parity statement, so JC-5's carve-out does not cover it.

Evidence:

```
These companion files mirror the v9 project-level policy:
```

Why: Foundation A-K5: a stale version label that misleads a reader. The line
is a LIVE policy claim — it asserts these companion files mirror current
project-level policy, anchored to 'v9'. Current pack version is v11. This is
not accurate historical narrative; it is a present-tense parity claim pinned
to a superseded version.

### K5.9 · `supporting-docs/SETUP-EXISTING.md:3` · ruling none (K5 candidate; no JC ruling targets these setup-guide headers)

Evidence:

```
This guide walks you through adding the AI Agent Config Pack v10.0 to an **existing project** ...
```

Why: K5: stale version label that misleads a reader. README version table
establishes v11.0 as the current major (May 2026); v10.0 is the prior
release. The setup guide's self-identifying header claims it installs
'v10.0'. NOT every 'v10.0' string is a defect — `git checkout v10.0`
recovery refs and `.pack-migration-backup/v9.3-to-v10.0/` backup-path refs
are accurate history; the DEFECT is the doc-identity header (line 3).

### K5.10 · `supporting-docs/SETUP-NEW.md:3-4` · ruling none (K5 candidate)

Evidence:

```
This guide walks you through setting up a **new project** with the AI Agent Config Pack v10.0. It is self-contained ...
```

Why: K5: same stale doc-identity label as SETUP-EXISTING.md. The new-project
setup guide self-identifies as 'v10.0' while the current pack major is v11.0
(README line 60). A v11 client onboarding via this guide is told they are
installing v10.0.

### K5.11 · `supporting-docs/METHODOLOGY.md:3-4, 1732` · ruling none (K5 candidate)

Evidence:

```
Line 3-4: "Version: 2.1 (v10.0, April 2026) / Applies to: All projects using Claude Code CLI, Codex CLI, or Gemini CLI with AI Agent Config Pack v10".  Line 1732: "*Version 2.1 — AI Agent Config Pack v10.0, April 2026*".
```

Why: K5: the METHODOLOGY doc's identity/version block states it 'Applies to
... AI Agent Config Pack v10' and is dated April 2026 (the v10.0 release
date), while the current major is v11.0 (May 2026). A reader treats this as
the v10-era methodology; if it is the live v11 methodology surface, the
version label misleads.

### K5.12 · `supporting-docs/DEPENDENCIES.md:3` · ruling none (K5 candidate)

Evidence:

```
This document lists all tools required or optionally used by the AI Agent Config Pack v10
```

Why: K5: the dependencies doc self-identifies as describing 'the AI Agent
Config Pack v10' while the current major is v11.0 (README line 60). A v11
client reading the dependency list is told it is the v10 list.

### K5.13 · `supporting-docs/SETUP_TEMPLATE.md:18, 35` · ruling none (K5 candidate)

Evidence:

```
Line 18: "*Generated from: supporting-docs/SETUP_TEMPLATE.md — AI Agent Config Pack v10*".  Line 35: "- AI Agent Config Pack v10 available locally".
```

Why: K5: the setup-guide template — which the PM chat reads to GENERATE a
project-specific SETUP.md (deliverable) — self-labels and prescribes
generated output as 'v10'. Under deliverable-only + cleanliness corollary,
the emitted deliverable must itself be clean; a v10 label propagated into a
generated v11-install SETUP.md misleads. README line 60 = v11.0 current.

### K5.14 · `supporting-docs/AGENT_KICKOFF_TEMPLATE.md:21` · ruling none (K5 candidate)

Evidence:

```
*Generated from: supporting-docs/AGENT_KICKOFF_TEMPLATE.md — AI Agent Config Pack v10*
```

Why: K5: this fill-in-the-blanks kickoff template stamps its generated output
provenance as 'AI Agent Config Pack v10', while the current major is v11.0
(README line 60). The generated deliverable inherits the stale label.

### K5.15 · `README.md:60, 195` · ruling none

Kind: K5 (version-currency-staleness) / B (factual error).

Evidence:

```
validate-pack.py expanded to 40 invoked checks (38 numbered Check 1–11, 16–23, and 25–43; 2 unnumbered informational ... Checks 12–15 retired per v9 sunset; Check 24 retired per BD-194)
```

Why: Both the v11.0 version-history cell (line 60) and the Repository Layout
validate-pack.py annotation (line 195) state the checks span only Check
1–11, 16–23, and 25–43 (top = 43). The actual scripts/validate-pack.py now
defines Check 44, 45, 46 (BD-196), and the workflow wires test steps for
them. README describes a stale, smaller check set. K5 version-currency /
category-B factual error. Confidence binds to whether BD-196 is in-scope for
current pristine state; the mismatch against HEAD is factual.

---

## K7 — surface-blind-union-grammar-in-dual-surface-validator (1)

### K7.1 · `scripts/tests/test-tracker-phase-task.sh:149` · ruling JC-1

Kind: K7 — surface-blind-union-grammar-in-dual-surface-validator (and K1
encoding surface).

Evidence:

```
DEP = re.compile(r"^\s*-\s+(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?\s*$")
```

Why: An inline Python dependency-grammar regex whose alternation admits a
project token group (phase-N.M, TD-NNN) AND a pack token (BD-NNN) in one
union, with no surface-gating. K7 verbatim and the same K1 contamination as
JC-1. Test's internal copy of the parser grammar used for bash-vs-Python
parity, carrying the contamination identically.

---

## B — non-contamination correctness defect (17)

### B.1 · `project-template/README.md:5-7` · ruling JC-3

Kind: B — non-contamination correctness defect (stale/misleading setup
instruction).

Evidence:

````
```bash
cp -r /path/to/pack/project-template/. /path/to/your-project/
```
````

Why: Foundation §B + JC-3: JC-3 directs redirecting the stale `cp -r` to
init-project.sh/QUICKSTART. The README instructs raw `cp -r` of the whole
template, but the pack's documented install path is init-project.sh. The bare
`cp -r` instruction is stale/misleading relative to the init-project.sh setup
flow.

### B.2 · `project-template/skills/boundary-investigation/SKILL.md:67-76` (Step 2 SSOT table); specifically line 76 · ruling JC-4

Kind: B (non-contamination correctness defect — malformed path; governing
ruling JC-4).

Evidence:

```
| Methodology + procedures | `project-template/supporting-docs/METHODOLOGY.md` (when applicable) |  — and the whole table uses pack-repo-relative `project-template/...` prefixes, e.g. line 69 `project-template/docs/pack/PM-CHAT.md`, line 74 `project-template/skills/<name>/SKILL.md`.
```

Why: This skill ships to clients at `.claude/skills/boundary-investigation/`,
etc. At a client install there is NO `project-template/` directory and NO
`supporting-docs/` directory. The `project-template/supporting-docs/METHODOLOGY.md`
path resolves to nothing at a client install. Foundation §B
(malformed/dangling internal paths) + JC-4 names exactly this SSOT-table path
as a category-B malformed-path correctness defect, NOT a K4 leak.

### B.3 · `project-template/docs/pack/PM-CHAT.md:930` · ruling none

Kind: B — non-contamination correctness defect (factual / version-currency:
wrong sidecar suffix).

Evidence:

```
for the reconciliation workflow if a migration produces a
`docs/pack/PM-CHAT.md.v9-customized` sidecar.
```

Why: PM-CHAT.md (client-installed) tells the reader a migration produces a
`.v9-customized` sidecar. The actual migrator scripts/migrate-v10-to-v11.sh
sets `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"` (line 76), so it emits
`PM-CHAT.md.v10-customized`. The documented suffix is factually wrong for a
v11-era install. Category-B factual error / version-currency.

### B.4 · `project-template/docs/pack/OPTIONAL-FEATURES.md:132-135, 164` · ruling none

Kind: B — non-contamination correctness defect (cross-surface command
inconsistency + client-path resolvability).

Evidence:

```
L132-135 `bash scripts/pack-tracker.sh init` / `status` / `doctor` / `disable`; L164 `bash scripts/pack-tracker.sh disable`, which reads live issue state
```

Why: OPTIONAL-FEATURES.md instructs the client to invoke the tracker via
`bash scripts/pack-tracker.sh <verb>`. (1) Cross-surface inconsistency —
every other doc on this client surface uses the `pack tracker <verb>`
shell-verb form. (2) Resolvability — `scripts/pack-tracker.sh` exists at PACK
root but is NOT present in project-template/scripts/, so the literal path
does not resolve at a client install. Category-B cross-surface/command-
correctness defect.

### B.5 · `project-template/docs/project/backlog/_intro.md:12` · ruling none

Kind: B (also K3-reframed: live doc cites a path that does not resolve on the
surface it ships to).

Evidence:

```
the per-entry mirror generator at `scripts/lib/per-entry/`.
```

Why: Dangling/malformed internal-path defect. The cited path
`scripts/lib/per-entry/` does not resolve inside an installed project: the
per-entry helpers live ONLY in the PACK repo and are sourced at install from
`$PACK/scripts/lib/per-entry`. They are NOT staged into the project
(verified: fixture project scripts/lib/ contains only detect.sh). A project
reader following the path finds nothing. Violates §B + directory-based
principle. UNCERTAINTY: may be intentional-descriptive but unmarked as
pack-side-only.

### B.6 · `project-template/docs/project/backlog/_rules.md:38` · ruling none

Kind: B (dangling/non-resolving project-side path).

Evidence:

```
The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime. Files not matching the entry regex AND not in this list are SKIP.
```

Why: Same dangling-path defect as the _intro.md finding:
`scripts/lib/per-entry/` does not exist on the project surface (helpers run
from $PACK/scripts/lib/per-entry). Confirmed the installed fixture project
lacks this dir. Category B. Same UNCERTAINTY caveat: may be intended as a
pack-side descriptive reference, but unmarked as such on a client-shipped
surface.

### B.7 · `project-template/docs/project/changelog/_intro.md:15` · ruling none

Kind: B (dangling/non-resolving project-side path).

Evidence:

```
read-stable concatenation produced by the per-entry mirror generator
at `scripts/lib/per-entry/`.
```

Why: Same dangling-path defect: `scripts/lib/per-entry/` does not resolve on
the project surface. Category B. Same UNCERTAINTY caveat.

### B.8 · `project-template/docs/project/changelog/_rules.md:40` · ruling none

Kind: B (dangling/non-resolving project-side path).

Evidence:

```
The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime. Files not matching the entry regex AND not in this list are SKIP.
```

Why: Same dangling-path defect: `scripts/lib/per-entry/` does not resolve on
the project surface. Category B. Same UNCERTAINTY caveat.

### B.9 · `project-template/docs/project/implementation-plan/_intro.md:14` · ruling none

Kind: B (dangling/non-resolving project-side path).

Evidence:

```
this file is a read-stable concatenation produced by the per-entry
mirror generator at `scripts/lib/per-entry/`.
```

Why: Same dangling-path defect: `scripts/lib/per-entry/` does not resolve on
the project surface. Category B. Same UNCERTAINTY caveat.

### B.10 · `project-template/docs/project/implementation-plan/_rules.md:39` · ruling none

Kind: B (dangling/non-resolving project-side path).

Evidence:

```
The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime. Files not matching the entry regex AND not in this list are SKIP.
```

Why: Same dangling-path defect: `scripts/lib/per-entry/` does not resolve on
the project surface. Category B. Same UNCERTAINTY caveat.

### B.11 · `xcode-companion-templates/Codex/config.toml:52, 56, 60, 64, 69, 73, 77` · ruling none

Kind: B — non-contamination correctness defect (dangling internal path).

Evidence:

```
[agents.planner]\nconfig_file = "agents/planner.toml"  (and identically: agents/coder.toml, agents/reviewer.toml, agents/tester.toml, agents/apple-architect.toml, agents/repo-ops.toml, agents/docs-researcher.toml)
```

Why: Foundation B: malformed/dangling internal paths. config.toml declares 7
sub-agents, each pointing to config_file = "agents/<name>.toml". No agents/
directory exists in the template tree. The README install steps copy only
Codex/AGENTS.md and Codex/config.toml — never an agents/ dir — so the
installed Codex config references 7 agent definition files never delivered
and unresolvable at install.

### B.12 · `scripts/lib/tracker-cycle-check.sh:93` · ruling none

Kind: B.

Evidence:

```
#   - ARCHITECTURE-V1.md §9 / §27.1 Layer 2 (typed errors + verb naming)
```

Why: Category B (dangling internal doc-reference / malformed-path
correctness defect). The comment cites `ARCHITECTURE-V1.md`, which does not
exist at HEAD (the research tree has ARCHITECTURE.md, ARCHITECTURE-V2.md,
ARCHITECTURE-V3.md but no V1). NOT a K3 BD-195-deleted-doc (not in the
DELETED set, predates BD-195) — a pre-existing dangling basename reference
per foundation §B.

### B.13 · `scripts/lib/tracker-links.sh:96-97` · ruling none

Kind: B.

Evidence:

```
#   - ARCHITECTURE-V1.md §5.3 (reserved link.kind open-string family)
#   - ARCHITECTURE-V1.md §9 (typed errors per category)
```

Why: Category B (dangling internal doc-reference). Two comment citations to
`ARCHITECTURE-V1.md`, a basename that does not resolve at HEAD (not in the
BD-195 DELETED set). Pre-existing dangling internal reference per foundation
§B, not a boundary leak.

### B.14 · `scripts/validate-pack.py:4241` · ruling none

Kind: B (non-contamination correctness defect — inaccurate/abbreviated
internal doc citation).

Evidence:

```
# architect-spec gap discovery, IMPL-REPORT-BD-173-Batch-19c-H.13.md
```

Why: Category-B correctness defect per foundation §B. The comment cites the
provenance doc as `IMPL-REPORT-BD-173-Batch-19c-H.13.md`, but the actual
tracked file is `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` (full
prefix). No file resolves to the abbreviated basename. The sibling citation
on line 4220 uses the correct full prefix, so the abbreviation is an
inconsistency. LOW confidence: non-load-bearing prose comment; NOT a K3
dangling-deleted-doc finding. Minor citation-accuracy nit only.

### B.15 · `README.md:152` · ruling none

Kind: B (malformed/wrong internal path — cross-doc inconsistency).

Evidence:

```
├── MERGE-STRATEGY.md                       Per-file customization-preservation matrix (v11)
```

Why: This entry sits under the `supporting-docs/` heading (README.md:143)
and thus asserts MERGE-STRATEGY.md lives at supporting-docs/MERGE-STRATEGY.md.
The actual file is at pack-ops/MERGE-STRATEGY.md (ls supporting-docs/ => No
such file; ls pack-ops/ => exists). QUICKSTART.md:41 correctly references
pack-ops/MERGE-STRATEGY.md, so README and QUICKSTART disagree. Category-B
malformed/wrong internal path + cross-doc inconsistency.

### B.16 · `README.md:154` · ruling none

Kind: B (malformed/wrong internal path).

Evidence:

```
├── DRY-RUN-MIGRATION.md                    Companion guide for scripts/dry-run-migration.sh (v11; BD-114 / BD-125)
```

Why: This entry is under the `supporting-docs/` heading (README.md:143),
asserting DRY-RUN-MIGRATION.md lives at supporting-docs/DRY-RUN-MIGRATION.md.
The actual file is at pack-ops/DRY-RUN-MIGRATION.md (find =>
./pack-ops/DRY-RUN-MIGRATION.md; not in supporting-docs/). Category-B
malformed/wrong internal path: the layout map points readers to a
non-resolving location.

### B.17 · `README.md:101` · ruling none

Kind: B (factual / count-currency error — lower confidence).

Evidence:

```
├── skills/                                 Canonical skill library (34 skills — 13 Tier 0 base + 19 dimensional/intersection + 1 trigger-loaded + 1 PM chat operational; per `docs/pack/PLATFORM-SKILLS.md` Full skill inventory) — distributed
```

Why: README claims the canonical skill library is '34 skills', but
project-template/skills/ contains 36 skill directories. The internal
breakdown text (13+19+1+1=34) is self-consistent but does not match the tree.
Category-B count-currency / factual error. LOWER-CONFIDENCE: the
authoritative count SSOT is PLATFORM-SKILLS.md; full 34-vs-36 reconciliation
belongs to the skills-inventory cross-surface audit; reported here because
the README number is on PR-13 and mismatches the tree (+2 delta).

---

## False positive (1, filtered for auditability)

### FP.1 · `project-template/skills/pm-startup/SKILL.md` (and identical copies `project-template/.claude/skills/pm-startup/SKILL.md`, `project-template/.codex/skills/pm-startup/SKILL.md`) · Step 0 block lines 10-57; concrete version tokens at lines 22, 34, 36, 48 · ruling none

Reported kind: K5 candidate / C-Open — version-currency: retained v9→v10
migration narrative on a v11 client surface (disposition open). Surface: CS-3.

Evidence:

```
[[ -f .pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] && ... ; if [[ "$(git branch --show-current 2>/dev/null)" == "migration-v9-to-v10" ]]; then ... ; Sub-procedure 5-C.1 handles the legacy `_v9-backup.md` filename for pre-C7 v10.0 installs.
```

Why (as originally reported): Under v11, pm-startup Step 0 still hard-codes a
v9.3→v10.0 migration safety-net. This is a version-currency concern
(foundation §A K5): a v11 client sees only a v9→v10 migration path and no
v10→v11 equivalent. HOWEVER this may be a deliberately-retained migration
safety net rather than a stale label — disposition is genuinely open and not
resolved by any JC ruling. Reported under foundation §C (Open).

Verifier reason (status: false-positive): Evidence reproduces verbatim at
project-template/skills/pm-startup/SKILL.md (HEAD 3178fa4), Step 0 lines
10-57. Quoted: line 22 `[[ -f
.pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] && \ echo
"POSTRUN-PENDING: Procedure 5-S"`; line 34 `if [[ "$(git branch
--show-current 2>/dev/null)" == "migration-v9-to-v10" ]]; then`; line 36
`echo "WARN: migration-v9-to-v10 branch has commits ahead of main while
sidecars are present — single-commit model breached..."`; line 48
`Sub-procedure 5-C.1 handles the legacy \`_v9-backup.md\` filename for
pre-C7 v10.0 installs.` The finding cites no JC ruling, so it is tested
adversarially against the foundation's kinds + principles. The evidence
reproduces, but it is NOT genuinely a defect under the foundation. The
finding itself frames the disposition as genuinely OPEN (reported under §C)
and concedes this "may be a deliberately-retained migration safety net rather
than a stale label." Step 0 is a one-shot post-migration safety net keyed on
the PRESENCE of v9.3→v10.0 migration artifacts on disk (sentinel files, the
`migration-v9-to-v10` branch name, the legacy `_v9-backup.md` filename).
These tokens are accurate references to a specific prior migration path that
only fire when those exact v9-era artifacts exist — they are not "v10 where
v11 is current" content misleading a reader about the current version. K5
(version-currency-staleness) requires stale labels/content that MISLEADS a
reader; a presence-gated handler for a real prior migration is accurate, not
stale-misleading. This is a legitimate case the foundation does not classify
as a defect, so per the no-ruling verification contract (status="real" only
if evidence reproduces AND it is genuinely a defect), the correct status is
false-positive.

---
