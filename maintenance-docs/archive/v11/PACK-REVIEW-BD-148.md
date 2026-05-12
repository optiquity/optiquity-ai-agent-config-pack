# PACK REVIEW — BD-148

**Verdict:** APPROVE WITH NITS

**One-line summary.** BD-148 lands all 7 success criteria cleanly:
the MIGRATION + MERGE-STRATEGY + INSTALL-PROCEDURES + PLATFORM-SKILLS
edits cover what the architect/planner specified, the
`Base skills | Dimensional skills` header convention is internally
consistent, validate-pack PASSES (Check 25 BD-088/089 fixture
unaffected), no out-of-scope edits were made, and the change satisfies
BD-159 §3.1 mechanical-edit conditions. Two minor nits below; neither
blocks ship.

---

## 1. Concern-by-concern findings

### Concern 1 — MIGRATION-v10-to-v11.md "Skill model changes" section

**Status:** PASS.

- New H2 inserted between "What changed in v11" (line 29) and "Before
  you start" (line 246):
  - `supporting-docs/MIGRATION-v10-to-v11.md:83` —
    `## Skill model changes (BD-142, BD-148)`.
- Sub-sections (file:line):
  - `### What changed` (line 89) — names 5 dimensions D1–D5, three
    load mechanisms (Tier 0 base / intersection / trigger), retires
    Tier 1 / Tier 2 nomenclature, calls out the four reclassifications
    (`security-patterns`, `api-design`, `debugging`,
    `ui-test-strategy`), notes no SKILL.md content changed. Matches
    architecture §3.6 + §3.7 + §3.8 + §4.1.
  - `### Behavioral impact` (line 121) — opens with the architecture
    §7.8 framing ("PM chats re-read PLATFORM-SKILLS.md every prompt;
    impact on running PM chats is minimal"). Four numbered client
    actions cover the four required cases (no manual edit, re-apply
    locally edited file, byte-identical Custom sections, manual
    column-header rename). Cross-link to BD-088 sidecar contract on
    line 147.
  - `### Migrator handling` (line 174) — correctly states the
    reframe is doc-only; references S5b for the BD-035 split case;
    points at BD-147 for the future `migrator-skills.sh` extraction.
  - `### BD-136 trinity-marker non-overlap` (line 192) — explicitly
    cites architecture §6.7, names Shape A / Shape B markers,
    confirms PLATFORM-SKILLS.md is at `docs/pack/` (not project root)
    and uses BD-088 sidecar (not BD-136 markers); confirms
    `**Active skills:**` line format unchanged. Names change only
    via S5b. Architectural fidelity is high.
  - `### D5 monorepo gotcha` (line 223) — cites architecture §7.4;
    documents global loading + per-component scoping in agent
    prompts; cross-references the same gotcha in PLATFORM-SKILLS.md
    "Monorepo D5 scoping note".
- Verification: `grep -c "^## Skill model changes"
  supporting-docs/MIGRATION-v10-to-v11.md` → 1 (matches plan line 708
  exit criterion).

### Concern 2 — MERGE-STRATEGY.md PLATFORM-SKILLS.md per-file note

**Status:** PASS.

- New H2 `## Per-file notes` inserted between class 12 `generic`
  (line 238) and `## Sidecar conventions` (line 317):
  - `supporting-docs/MERGE-STRATEGY.md:251` — `## Per-file notes`.
  - `supporting-docs/MERGE-STRATEGY.md:253` — `### docs/pack/PLATFORM-SKILLS.md (BD-148, v11 reframe)`.
- All three required architectural points present:
  - **(a) v11 reframe** — line 260, names the four → five dimension
    transition, the `transform`-class wholesale-replacement model
    for the body, and the BD-088 sidecar mechanism for `## Custom *`
    sections.
  - **(b) D5 monorepo gotcha** — line 291, cites architecture §7.4,
    names the per-component scoping responsibility, and confirms no
    preservation-strategy change.
  - **(c) D2 reshape advisory** — line 305, cites architecture §7.6,
    names the Apple-family languages move from D2 to D1-implied,
    flags programmatic readers as needing updates, confirms manual
    readers see same skills loaded.
- Plan §"Verification" criterion ("the matrix row mentions both
  `transform` and `user-owned` per the reshape") is satisfied
  (`transform`-class on line 266; `user-owned` on line 277).
- Plan §"Implementation steps" 2 nominally said "locate
  PLATFORM-SKILLS.md row in the per-file matrix" but MERGE-STRATEGY.md
  is structured per-class, not per-file. The implementer's choice to
  insert a new "## Per-file notes" H2 honors the plan's intent
  without retro-fitting per-file notes into each existing class. The
  IMPL report §6 calls this deviation out and the rationale is sound.

### Concern 3 — PLATFORM-SKILLS.md `## Custom agents` table headers

**Status:** PASS.

- `project-template/docs/pack/PLATFORM-SKILLS.md:525` — header row is
  `| Agent | Purpose | Dimension | Phase routed to | Base skills |
  Dimensional skills | Read/write mode |`.
- The illustrative `x-deployer` data row at line 527 is unchanged
  (`repo-ops` in the Base column was Tier 1; `deployment-apple,
  deployment-python` in the Dimensional column was Tier 2).
  Semantics are preserved 1:1. No data drift.
- `grep -n "Tier 1 skills\|Tier 2 skills"
  project-template/docs/pack/PLATFORM-SKILLS.md` → no matches; no
  surviving deprecated headers in the template file.

#### Header convention sanity check

**Chosen convention:** `Base skills | Dimensional skills`.

**Match against table semantics:** The `Base skills` column maps to
Tier 0 base skills (architecture §3.6 — always loaded regardless of
D1–D5). The `Dimensional skills` column maps to dimensional /
intersection-cell / trigger skills (architecture §3.7 / §3.8 — loaded
conditionally). Both map cleanly to v11 named buckets in
PLATFORM-SKILLS.md (§"Tier 0 — Base skills" at line 183;
§"Dimensional skills (16)" at line 436). The illustrative-row data
partition (always-loaded vs conditional) matches the new label
partition exactly. No semantic drift.

**Internal consistency:**
- Body of PLATFORM-SKILLS.md uses both names directly (line 183 has
  "Tier 0 — Base skills"; line 436 has "Dimensional skills (16)") —
  the table headers reuse the same vocabulary the body of the file
  defines.
- INSTALL-PROCEDURES.md Procedure 5.1 step 4 references the same two
  vocabulary anchors (`docs/pack/PLATFORM-SKILLS.md` § "Tier 0 — Base
  skills" and § "Intersection table" / § "Trigger-loaded skills").
  No translation layer needed at write time.
- The "Tier 0" prefix is reasonably retained in body section headings
  (the architecture itself names the bucket "Tier 0"). The table
  column drops the "Tier 0" prefix and uses just "Base" — slightly
  asymmetric with the body, but defensible because "Tier 0 base" in
  a column header would be redundant. The IMPL report §3 considered
  and rejected `Tier 0 | Dimensional` for this reason. Acceptable.

### Concern 4 — INSTALL-PROCEDURES.md Procedure 5 column-write logic

**Status:** PASS.

- `supporting-docs/INSTALL-PROCEDURES.md:119-136` — new
  "Column convention for the `## Custom agents` row (v11+)" prose
  block in Procedure 5.1 step 4.
- The block (a) names the new convention (`Agent | Purpose | Dimension
  | Phase routed to | Base skills | Dimensional skills | Read/write
  mode`), (b) defines what each column carries with cross-references
  to PLATFORM-SKILLS.md anchor sections, (c) instructs the PM chat to
  follow this convention exactly when writing a new row in v11+
  projects, (d) provides the manual-rename instruction for pre-v11
  projects whose `## Custom agents` section still has deprecated
  headers (Tier 1 → Base, Tier 2 → Dimensional), (e) cross-links to
  `MIGRATION-v10-to-v11.md` § "Skill model changes" for the migration
  note.
- Procedure 5.2 (Custom skills, line 141) is correctly NOT touched —
  the Custom skills table at PLATFORM-SKILLS.md line 544 has columns
  `Skill | Description | Dimension | Loaded by` with no Tier 1 / Tier
  2 column. IMPL report §2.2 correctly identifies this and skips
  Procedure 5.2.
- Re-running Procedure 5.1 against an existing client project will
  emit `Base skills | Dimensional skills` headers per the new prose,
  satisfying success-criterion 4.

**Nit (non-blocking).** The IMPL report §2.2 verification snippet
shows a misleading `grep -n "Base skills | Dimensional skills"
supporting-docs/INSTALL-PROCEDURES.md` returning a match at line 117
("the Codex/Gemini equivalents"), which is the line BEFORE the new
prose. The actual matches are at lines 121 and 132. The match shown
in the report appears to have been munged in formatting; the prose
itself is correct. Cosmetic only — does not affect correctness of
the implementation.

### Concern 5 — BD-088 invariant (Check 25 / customization-preserve)

**Status:** PASS.

`python3 scripts/validate-pack.py` PASSED — all 30 checks clean
(running with BD-147 in-flight changes also in the working tree, so
the validator includes the new Check 26 entry for `migrator-skills.sh`
syntax). Relevant checks:

- `── Check 24: HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) ──`
  — OK.
- `── Check 25: Customization-detection regression guard (BD-089) ──`
  — `4/4 fixture rows recorded with expected disposition + class`,
  `truthful-report contract: every fixture file appears in
  report.md`. This is the synthetic fixture exercising the BD-088
  customization-preserve library (`scripts/validate-pack.py:1615-1709`
  source confirms the check sources `customization-preserve.sh` and
  exercises 4 fixture cases). PASS.
- `── Check 26: BD-119 migrator-framework inventory ──` — OK
  (includes new `scripts/lib/migrator-skills.sh` from BD-147).

The IMPL report §5 thoroughly explains why the column-header rename
does not break the BD-088 invariant: BD-088 preserves project sections
verbatim (regardless of pack-template content), so client projects
with real custom-agent rows under deprecated `Tier 1 / Tier 2`
headers continue to work; the new headers apply only to fresh
projects and to v11+ Procedure 5.1 invocations that draft a new row.
The mechanism's semantics are preserved.

**Nit on validator nomenclature.** The IMPL report §4 lists "Check 25
(BD-088 customization-preserve synthetic fixture)" but the validator
labels Check 25 as `BD-089` and the docstring at
`scripts/validate-pack.py:1615` says "BD-089 — synthetic fixture
exercises the BD-088 library". The labeling is intentionally split
(BD-088 = library, BD-089 = regression-guard fixture). The IMPL
report §6 acknowledges the confusion and treats both as covered.
Cosmetic; the actual check passes.

No regression on Check 25 attributable to BD-148. No regression on
Check 24, Check 27 (per-agent canonical-phrase compliance), or
Check 28 either.

### Concern 6 — No out-of-scope edits

**Status:** PASS.

`git diff --stat` (BD-148 + BD-147 working tree) shows 9 modified
files; the BD-148 IMPL report §8 files-changed inventory matches the
4 in-scope files exactly:

| Path | BD-148 lines added | Lines removed |
|---|---|---|
| `project-template/docs/pack/PLATFORM-SKILLS.md` | 1 | 1 |
| `supporting-docs/INSTALL-PROCEDURES.md` | 19 | 0 |
| `supporting-docs/MERGE-STRATEGY.md` | 66 | 0 |
| `supporting-docs/MIGRATION-v10-to-v11.md` | 163 | 0 |

The remaining 5 modified files
(`scripts/migrate-v10-to-v11.sh`, `scripts/lib/migrator-core.sh`,
`scripts/validate-pack.py`,
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`,
`.github/workflows/validate-pack.yml`) and 2 untracked files
(`scripts/lib/migrator-skills.sh`, `scripts/test-migrator-skills.sh`)
belong to BD-147 and are explicitly out of scope for this review.
No BD-148 commits or stages of BD-147 files.

No script edits, no trinity edits, no SKILL.md edits, no new files
created (other than the IMPL report itself, which goes to
`maintenance-docs/v11-implementation/` per the workflow-artifact
exemption in CLAUDE.md "Pack memory" §"Repo conventions").

### Concern 7 — BD-159 maintainability principle

**Status:** PASS.

CLAUDE.md `## Pack memory` § "Repo conventions" rule:
"Skill and agent maintenance is mechanical by default."
BD-148's footprint:

- **File count:** 4 files modified + 1 IMPL report. Well under the
  ~10 file ceiling implied by §3.1 of
  `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`.
- **No new top-level architecture/plan doc:** the IMPL report goes
  to `maintenance-docs/v11-implementation/` (workflow-artifact
  exemption). No top-level `.md` added.
- **Mechanical-edit footprint:** the only structural change is the
  `## Per-file notes` section in MERGE-STRATEGY.md, which is a
  thematic extension of the existing per-class organization (not a
  restructuring of existing content); the rest are additions inside
  existing H2 sections.
- **Edits preserve existing dimensions / row contracts:** column
  data semantics unchanged; `## Custom *` section structure
  unchanged.
- **No `x-` skill or agent contract change:** none touched.
- **No validate-pack check count change:** still 30 checks; all PASS.
- **No architect-pass migrator coverage adjustment required:** rename
  is doc-level; client projects keep existing column headers via
  BD-088 sidecar; manual-rename instruction is documented in
  MIGRATION-v10-to-v11.md.
- **Trinity rule preserved:** trinity files unchanged in BD-148
  (BD-143 already updated CLAUDE.md / AGENTS.md / GEMINI.md to the
  5+3 model). Confirmed via `grep` — `5-dimension`, `D5`,
  `Tier 0 base`, `intersection-cell`, `trigger-loaded` present in
  AGENTS.md:164–171 and GEMINI.md:175–183, matching CLAUDE.md
  byte-equivalent prose.

BD-148 is mechanical-edit per BD-159 §3.1. No structural-change
escalation needed.

---

## 2. Cross-reference integrity check

Grep'd for stale references to the deprecated `Tier 1 skills` /
`Tier 2 skills` / `four dimension` / `four-dimension` strings across
the four BD-148 files plus PLATFORM-SKILLS.md:

| Hit | Location | Verdict |
|---|---|---|
| "four-dimension model" | `MERGE-STRATEGY.md:261` | Legitimate retrospective reference inside the v11 reframe note explaining what v10 had. |
| "Tier 1 skills \| Tier 2 skills" | `MERGE-STRATEGY.md:283` | Legitimate retrospective reference inside the user-owned-section note. |
| "the four-dimension model" | `PLATFORM-SKILLS.md:162` | Legitimate retrospective reference (existing prose, not BD-148-introduced). |
| "5 dimensions, not 4" | `MIGRATION-v10-to-v11.md:91` | Legitimate (the new section's "What changed" framing). |
| "four-dimension table is replaced wholesale" | `MIGRATION-v10-to-v11.md:143` | Legitimate (the migration's behavioral-impact framing). |
| "Tier 1 skills \| Tier 2 skills" | `MIGRATION-v10-to-v11.md:159` | Legitimate (the v10 → v11 rename note). |
| "Tier 1 skills \| Tier 2 skills" | `INSTALL-PROCEDURES.md:131` | Legitimate (the manual-rename instruction for pre-v11 projects). |

No stale references survive in pack-canonical text. All deprecated
strings are inside retrospective explanatory prose where they are
required for the reader.

---

## 3. POQs

**None blocking.**

The IMPL report §7 surfaces one POQ:

- **POQ-148-1 — Should INSTALL-PROCEDURES.md Procedure 5-C.4
  (PLATFORM-SKILLS.md reconciliation) gain analogous Pattern X
  treatment?**
  Disposition (per IMPL report §7): **No** — Procedure 5-C is
  explicitly historical (sunset for v9.3 → v10), and the v10 → v11
  reconciliation path is the new MIGRATION-v10-to-v11.md § "Skill
  model changes" content plus the BD-088 sidecar mechanism. I concur
  — touching Procedure 5-C would blur its sunset boundary, and
  PLAN-SKILL-DIMENSIONS.md Batch 9 scope does not include it.

---

## 4. Sanity check against BD-159 §3.1 mechanical-edit conditions

| §3.1 condition | BD-148 status |
|---|---|
| Edits preserve existing dimensions / row contracts | YES — `## Custom agents` row data bytewise unchanged |
| Edits do not alter `x-` skill/agent contract | YES — no `x-` files touched |
| Edits do not introduce a new top-level doc | YES — all 4 file edits are to existing `supporting-docs/` and `project-template/docs/pack/` files; IMPL report uses workflow-artifact exemption |
| Edits do not change validate-pack check count or check semantics | YES — 30 checks, same semantics |
| Edits do not require architect-pass migrator coverage adjustment | YES — rename is doc-level; BD-088 sidecar handles client preservation; manual-rename instruction documented |
| Trinity rule preserved | YES — no trinity files touched |
| Verification before reporting | YES — every change paired with a grep verification |

BD-148 is a mechanical-edit batch under §3.1.

---

## 5. Nits (non-blocking)

1. **IMPL report §2.2 verification grep snippet munged.** The grep
   match shown returns line 117 ("the Codex/Gemini equivalents")
   instead of the actual matches at INSTALL-PROCEDURES.md:121 and
   :132. The prose itself is correct; only the report's verification
   evidence is mis-pasted. Cosmetic; consider correcting in a
   follow-up edit if Pack Chat does a final sweep.
2. **IMPL report §5 / §6 conflate Check 24 and Check 25 labeling.**
   The validator labels Check 25 as BD-089 (the regression-guard
   fixture) and BD-088 as the underlying library. The IMPL report
   correctly explains the split but the §4 narrative ("Check 25
   (BD-088 customization-preserve synthetic fixture)") could be
   clearer that the validator banner reads "BD-089". The actual
   check PASSES; only the cross-reference style is loose.

Both nits are documentation-of-the-implementation nits, not
implementation defects.

---

## 6. Maintenance-docs consistency

- `ARCHITECTURE-SKILL-DIMENSIONS.md` §6.7 (BD-136 trinity-marker
  non-overlap), §7.4 (D5 monorepo gotcha), §7.6 (D2 reshape
  advisory), §7.8 (PM-chat re-read framing) — all four cited
  explicitly with section numbers in the modified files. Cross-link
  fidelity is high; future readers can trace the design origin.
- `PLAN-SKILL-DIMENSIONS.md` §7.4 (BD-148 expanded scope, BD-142 F3
  deferred fix) — the IMPL report cites this and the recommended
  default convention; the recommended `Base skills | Dimensional
  skills` from §7.4 is what was implemented. No deviation.

---

## 7. Migration safety

- `MIGRATION-v10-to-v11.md` reflects the new state explicitly
  (Skill model changes section is now the canonical migration
  reference for the v11 reframe).
- `MERGE-STRATEGY.md` documents the per-file preservation contract
  for PLATFORM-SKILLS.md including the column-header rename.
- `INSTALL-PROCEDURES.md` Procedure 5.1 will produce v11-compliant
  rows when re-run.
- `customization-preserve.sh` (BD-088 library) is unaffected; the
  mechanism preserves project sections byte-identical regardless of
  pack-template column-header content. Verified by Check 25 PASS.

Migration safety is intact.

---

## 8. Final disposition

**APPROVE WITH NITS.**

Both nits are cosmetic in the IMPL report's verification evidence
and do not affect the correctness of the on-disk implementation.
The four BD-148 files are correctly modified per the architect /
planner specs; validate-pack PASSES; BD-088 invariant holds; no
out-of-scope edits; mechanical-edit per BD-159.

Recommended next step for Pack Chat: stage and commit per the IMPL
report §12 commit-message guidance and proceed to Batch 10
(BD-149).

---

**Doc path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-BD-148.md`
