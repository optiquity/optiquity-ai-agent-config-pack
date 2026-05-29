# AUDIT-BD-195-SUPERSEDED-MAP

**What this pass is.** Step-1b whole-repo supersession-mapping pass for BD-195
("Code Red 3"). This is the single FACTUAL evidence base of which docs are
superseded and by what, across the ENTIRE repo (pack + project). It records only
the factual "doc X is superseded by doc Y/Z" relationship plus its establishing
evidence (in-doc statement and/or commit message + SHA). It expresses NO opinion
on purpose, contamination, prison membership, or why a doc was replaced.

**Author:** pack-docs-researcher (read-only pass; one output file).
**Date:** 2026-05-28. **Branch:** v11-dev. **Repo HEAD at pass:** `8ebf8f8`.
**Read disposition:** All sources read IN PLACE (the prison directory does not
yet exist). Repo has 1,056 tracked files; 524 tracked `.md` under
`maintenance-docs/` plus 5 untracked working-tree docs.

---

## 1. Coverage attestation — doc AREAS read

The mapping is whole-repo, not epicenter-only. Areas enumerated and read (prose
read inside; fixture/agent/skill bodies enumerated + scanned for supersession
banners):

| Area | Path glob | Read disposition |
|---|---|---|
| maintenance-docs top-level | `maintenance-docs/*.md` (ANDROID-ANALYSIS, GEMINI-CLI-ANALYSIS, TOOL-COMPARISON, RECOMMENDATIONS, VERIFIED-NOTES, V10-* research/fix docs) | Banners + supersession grep; key docs read in full |
| maintenance-docs/archive/ (v9, v10, v10-working) | `archive/V9-*`, `archive/V10-*`, `archive/v10-working/*` | Banners; supersession grep across all |
| maintenance-docs/archive/v11/ | `archive/v11/*` (~200 files: IMPL-REPORTs, PACK-REVIEWs, ARCHITECTURE-*, PLAN-*, RESEARCH-*, AUDIT-*) | Enumerated + supersession grep; key docs read |
| maintenance-docs/v11-implementation/ | `v11-implementation/*` (ARCHITECTURE-*, PLAN-*, PACK-REVIEW-*, IMPL-REPORT-*, AUDIT-*, RESEARCH-*, EXECUTION-PLAN, RELEASE-GATE) | Banners; epicenter docs (BD-185, 19c, per-entry-split) read in full |
| maintenance-docs/v11-research/ | `v11-research/*` (ARCHITECTURE V1/V2/V3/V3.1/V3.2/V3.3-DELTA, REVIEW-PASS1/2/3, IMPL-PLAN + 4 addenda, INTAKE/REQUIREMENTS-PS, GROUPINGS, PLANNING-PROCESS-INSIGHTS, templates-archive) | Banners + headers; version-chain docs read in full |
| templates-archive | `v11-research/templates-archive/v11.0/**`, `v11.1/**` (SCHEMA.md, INDEX.md, forms/) | Read in full (v11.1 cut + v11.0 cut) |
| origins / guides | `maintenance-docs/origins/*`, `maintenance-docs/guides/*` | Banners |
| supporting-docs/ | all 10 `.md` (METHODOLOGY, MIGRATION-v8-to-v9, MIGRATION-v10-to-v11, INSTALL-PROCEDURES, DEPENDENCIES, CLI-PM-SETUP, SETUP-*, AGENT_KICKOFF_TEMPLATE) | Banners + supersession grep |
| pack-ops/ | all `.md` (BACKLOG, CHANGELOG, PACK-CHAT, PACK-AGENTS, BOUNDARY-DEFINITION, CONCEPTUAL-REVIEW-METHODOLOGY, MERGE-STRATEGY, OPTIONAL-FEATURES, DRY-RUN-MIGRATION, HELP-FRAGMENT-*) | Banners + supersession grep |
| pack-root trinity + root docs | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, `QUICKSTART.md`, `LICENSE.md` | Banners + supersession grep |
| project-template/ prose | `project-template/{CLAUDE,AGENTS,GEMINI,README}.md`, `docs/pack/**`, `docs/project/**`, `skills/**/SKILL.md` (37 skills), `.claude/.gemini` agents, prompts | Enumerated (99 `.md`); supersession grep |
| scripts/ prose | (no standalone prose `.md` outside `scripts/tests/fixtures/`; verified none) | Enumerated — none to read |
| companion / fixtures | `xcode-companion-templates/*`, `vscode-companion-templates/*`, `test-fixtures/*` | Enumerated; supersession grep (none) |
| git history | `git log --all`, `--diff-filter=D`, `--diff-filter=R`, `--grep` supersede/archive/replace/discard/obsolete | Commit messages + rename/delete events read |

**Untracked working-tree docs read** (on disk, not yet committed):
`ARCHITECTURE-BD-185-V2.md`, `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`,
`PLAN-BD-185-V2.md`, `PACK-REVIEW-BD-185-H.2.md`,
`RESEARCH-BD-185-ORDERING-API.md` — all read in full (they carry the most recent
supersession declarations).

**Scope boundary noted:** Gemini->Antigravity docs
(`REFERENCE-GEMINI-TO-ANTIGRAVITY.md`, `RESEARCH-ANTIGRAVITY-CLI-MIGRATION.md`,
Antigravity snapshot tree) exist on the `main` branch only and are NOT in the
v11-dev working tree (`8ebf8f8`). Their supersession relationship is real but
off-tree for this pass — see §5 Open Questions.

---

## 2. Supersession map

Each record: **superseded path -> superseding path(s)** + verbatim evidence
(in-doc and/or commit + SHA). Grouped by kind: WHOLE-DOC (entire doc replaced)
vs SECTION/PARTIAL (named sections superseded; doc otherwise stands). Quotes are
verbatim from HEAD `8ebf8f8`.

### 2.A — WHOLE-DOC supersession (in-doc evidence)

**R1. `maintenance-docs/GEMINI-CLI-ANALYSIS.md` -> `maintenance-docs/TOOL-COMPARISON.md`**
In-doc (superseded), `GEMINI-CLI-ANALYSIS.md:1-3`:
> **⚠️ DEPRECATED — April 2026** / This document is superseded by [`TOOL-COMPARISON.md`]... / It is retained as a historical record. Do not use it as a current reference.
Corroborating (superseding), `TOOL-COMPARISON.md:5` + `:215-218`:
> *Supersedes: GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md...* / "...has been superseded by this document: `...GEMINI-CLI-ANALYSIS.md` — content absorbed here".

**R2. `maintenance-docs/ANDROID-ANALYSIS.md` -> `maintenance-docs/TOOL-COMPARISON.md`**
In-doc (superseded), `ANDROID-ANALYSIS.md:1-3`:
> **⚠️ DEPRECATED — April 2026** / This document is superseded by [`TOOL-COMPARISON.md`]... / Do not use it as a current reference.
Corroborating (superseding), `TOOL-COMPARISON.md:215-218`:
> "...superseded by this document: ... `...ANDROID-ANALYSIS.md` — content absorbed here".

**R3. `maintenance-docs/archive/V10-PREDESIGN.md` -> `maintenance-docs/V10-DESIGN.md`**
In-doc (superseded), `archive/V10-PREDESIGN.md:4,6-10`:
> *Status: SUPERSEDED by `maintenance-docs/V10-DESIGN.md` (approved 2026-04-21)* / "> **This document has been superseded.** The approved v10 design is in `maintenance-docs/V10-DESIGN.md`. ... Do not use this document for implementation decisions — use V10-DESIGN.md."
Note: the named successor `maintenance-docs/V10-DESIGN.md` is NOT in the current
tree (it lives at `maintenance-docs/archive/V10-DESIGN.md`). The supersession
relationship is unambiguous; the path reference is stale — see §4.

**R4. `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md` -> `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`**
In-doc (superseding), `ARCHITECTURE-V3.3-DELTA.md:7` (§0 Scope):
> "Scope: supersedes ARCHITECTURE-V3.2-DELTA.md in full. V3.2 is a historical proposal; it has not been integrated."
And `:909`:
> "| V3.2-DELTA | (entirely) | Superseded by this delta — Path 3 / `--fold-into` / L3-typology removed |"
Corroborating: `ARCHITECTURE-REVIEW-PASS3.md:53-54` lists D-21/D-22 V3.2 rows as
"superseded by D-21/D-22 V3.3". WHOLE-DOC; V1+V2+V3+V3.1-DELTA "stand otherwise".

**R5. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-DISCARDED.md` (V0) -> `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md` (V1)**
In-doc (superseding V1), `ARCHITECTURE-CLEANUP-BATCH-19C.md:3-4`:
> "**Author:** pack-architect (first pass; V1 — supersedes a prior V0 attempt that was DISCARDED per user direction without being read here)."
Corroborating V0=DISCARDED refs: `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md:373`;
`ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md:18`; `RESEARCH-BATCH-19B-STRATEGIC-RULES.md:551`.

**R6. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md` (V1) AND `...ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md` -> `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` (V2)**
In-doc (superseding V2), `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md:7`:
> "**Supersedes:** V1 at `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md` and its PRINCIPLE-CHECK sidecar at `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md`. V1 is retained as a historical input; V2 is the implementation-ready design from this point forward."
WHOLE-DOC supersession of BOTH V1 (19C.md) and its PRINCIPLE-CHECK sidecar.
(V2 §A.1 carries forward specific V1 outputs verbatim, but the V1 DOC is superseded.)

**R7. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` (original) AND `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md` -> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md`** (superseding doc is UNTRACKED working-tree)
In-doc (superseding V2), `ARCHITECTURE-BD-185-V2.md:9-18` (§0 Supersession notice):
> "This document **SUPERSEDES** both prior BD-185 architect docs in their entirety: - `...ARCHITECTURE-BD-185.md` (original) - `...ARCHITECTURE-BD-185-RECONCILIATION.md`. A reader needs **neither** superseded doc to act on this one."
Also `:20-22`:
> "**Why supersession is required.** Both prior docs carry one categorical error: they treated **v11.0 as a closed/shipped version** and routed all phase-parts work into a nonexistent **\"v11.1 archive cut.\"** That premise is false."
The two superseded docs carry no self-supersession banner; the superseding doc
names them explicitly. WHOLE-DOC.

**R8. `maintenance-docs/v11-implementation/PLAN-BD-185.md` AND `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` -> `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md`** (superseding doc is UNTRACKED working-tree)
In-doc (superseding V2), `PLAN-BD-185-V2.md:3` + `:12-22` (§0 Supersession notice):
> "**Status:** Authoritative. Standalone. Supersedes the two prior plan docs in full."
> "This plan **SUPERSEDES** both prior BD-185 plan docs in their entirety: - `...PLAN-BD-185.md` - `...PLAN-BD-185-ADDENDUM.md`. Neither was read during this planning pass (they carry the same categorical \"v11.1\" mis-versioning the architecture corrected)."
WHOLE-DOC. NOTE: `PLAN-BD-185-ADDENDUM.md:8` self-frames as "**Supplements (does
NOT replace):** `...PLAN-BD-185.md`" — the addendum's own "supplements" framing
is OVERRIDDEN by the later PLAN-BD-185-V2 whole-doc supersession claim. Recorded
as a framing conflict, not a contradiction of the supersession evidence.

### 2.B — SECTION / PARTIAL supersession (named sections; doc otherwise stands)

**R9. `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (original) -> corrected/extended by `...ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` (Addendum #1)**
In-doc (Addendum #1), `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md:13-18`:
> "This addendum bundles 10 items decided in user-Pack-Chat discussion following the reviewer pass on `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (3,477 lines). The original integration architect doc is NOT edited; this addendum corrects + extends it..."
Specific superseded sections enumerated in Addendum #1 (e.g. `:281` "Original §4.2 Layer 3: SUPERSEDED by §1.3 above"; `:1245` "Original §17.2 BD table: REPLACED by §6.4 above"; `:1247` §17.3 commit ordering; `:1486` §7.2 cost table; `:1551` §17.2 BD table). PARTIAL: parent doc retained verbatim; named sections superseded.

**R10. `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` (Addendum #1) -> corrected/superseded-in-part by `...ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` (Addendum #2)**
In-doc (Addendum #2), `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md:14-20`:
> "This Addendum #2 bundles 5 items decided in user-Pack-Chat discussion following the reviewer pass on Addendum #1 ... Addendum #1 is NOT edited; this Addendum #2 corrects + supersedes specific sections of Addendum #1 (parallel to the sidecar's addendum-of-addendum supersession pattern; preserves iteration history)."
Specific sections: `:508` "DROPPED — superseded by Addendum #2 §2"; `:668` "Addendum #1 §2.4 row 4 — superseded by §3.3 above". PARTIAL.

**R11. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` (one subsystem only) -> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`** (both UNTRACKED working-tree)
In-doc (the addendum), `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md:3-6` + `:20-26` (§0):
> "This doc SUPERSEDES exactly one subsystem of V2 — the tracker-mode execution-ordering MECHANISM — and leaves everything else in V2 intact and binding."
> "This addendum REPLACES the following V2 content. Where V2 and this addendum disagree, THIS ADDENDUM WINS for the listed items; V2 remains authoritative for everything else."
Superseded V2 elements named in the §0.1 table: D-7 (PARTIALLY SUPERSEDED, `:32`),
D-8 (SUPERSEDED, `:33`), §7 ordering ops (SUPERSEDED for ordering ops, `:34`).
PARTIAL — single subsystem.

**R12. `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` — version tag superseded (grammar substance carried forward) -> by `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` §2.B + §3 D-1** (superseding doc UNTRACKED)
In-doc (superseding V2), `ARCHITECTURE-BD-185-V2.md:201-206` (§2.B VERSION-TAG CARVE-OUT):
> "The embedded `phase-part-v11.1` tag — the title string, the §2 `template_version` marker value, and the §3 `template:phase-part-v11.1` label — is part of the v11.1 contamination, **not** the approved grammar. It corrects to the v11.0 framing this doc designs (§3 D-1: `phase-part-v11.0`). The grammar substance is unchanged; only the version label moves."
And `:248` (§3 D-1): "Phase-part template version is `phase-part-v11.0` (NOT v11.1)".
PARTIAL/VERSION-LEVEL: the SCHEMA's §1-§8 GRAMMAR is adopted verbatim in
substance; only the `v11.1` version tag/placement is superseded by the v11.0
framing. (Per the BD-195 categorical fact, the v11.1 tag is the contamination
signal — see §5.)

**R13. `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (v11.1 cut placement/claims) -> corrected to v11.0 placement by `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` §3 D-1 + §10** (superseding doc UNTRACKED)
In-doc (superseding V2), `ARCHITECTURE-BD-185-V2.md:259-261` (§3 D-1):
> "BD-185 does **not** mint a `templates-archive/v11.1/` directory. The [phase-part] entry type ... [is added to the] existing `templates-archive/v11.0/` cut..."
And `:101-104` lists `templates-archive/v11.1/INDEX.md`, `.../phase-part-v11.1/SCHEMA.md`,
`.../v11.1/forms/work-item.yml` among the surfaces the design corrects.
The v11.1 INDEX.md claims (`v11.1/INDEX.md:7-10`): "The v11.1 archive cut introduces
multi-part phase mid-work expansion + execution-order mechanism. v11.0 remains the
prior archive cut..." — V2 §0 / §3 D-1 corrects the entire "v11.1 archive cut"
framing to v11.0. PARTIAL (placement/version claims superseded; entry-type
substance moves to v11.0).

### 2.C — SECTION supersession recorded INSIDE design-version chains (in-doc reference convention)

**R14. `maintenance-docs/v11-research/ARCHITECTURE.md` (V1) — "(superseded)" per downstream reference convention**
Evidence: `RESEARCH-PER-ENTRY-SPLIT.md:6` front-matter `out-of-scope:` line:
> "out-of-scope: STATUS.md, PACK-FEEDBACK.md, ARCHITECTURE.md (superseded), maintenance-docs/archive/v11/*"
Also `ARCHITECTURE-V3.3-DELTA.md:208` (ARCHITECTURE-REVIEW-PASS3 referenced): "V1 §5.1 ... **Superseded by V3.3 §2.6.** V1 unchanged; supersession by reference is the architect's convention."
NUANCE: the V1->V2->V3 chain is REFINEMENT, not whole-doc supersession. V2 header
`:3` "Refines `ARCHITECTURE.md` (V1...)"; V3 header `:3` "Refines `ARCHITECTURE-V2.md`
... which itself refined `ARCHITECTURE.md` (V1...)"; `ARCHITECTURE-V3.md:54`
"**Superseded:** none. V3 adds; it does not retract." The "(superseded)" label on
V1 in RESEARCH-PER-ENTRY-SPLIT is a downstream researcher's convention for "do not
read V1 as current; read the latest delta." Recorded as SECTION/by-reference
supersession, NOT whole-doc — the chain explicitly carries V1/V2/V3 forward.

**R15. `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §6.1 / §6.2 / §6 (Item-6 bar) — REVISED in walkthrough -> `INTAKE-PS-V11.md` §8 + `REQUIREMENTS-PS-V11.md` Cap N1 / #11 / §7**
In-doc (superseded doc carries its own REVISED note), `PLANNING-PROCESS-INSIGHTS-FROM-OT.md:426`:
> "**Status: REVISED 2026-05-24 per walkthrough decision (Sub-A revised to \"architect-decides structure\").** The original recommendation here (adopt per-stream-tree pattern...) was REVISED ... see `INTAKE-PS-V11.md` §8 Walkthrough results Cap N1 row..."
Also `:443` (§6.2 split #11 REJECTED) and `:482` (§6 7-item bar EXTENDED to 8-item).
PARTIAL/SECTION: named recommendations inside the doc superseded; the doc as a
whole self-frames "informative, not prescriptive" (`:16`) and is retained for
audit trail. The AUDIT-PS-FULL-SESSION-ARCHITECT.md M-7 (`:185`) recommended this
note; it was applied (the note is present at `:426`).

---

## 3. Archived-AND-superseded subset (archived AND superseded -> directive sends to prison)

This subset = docs that already live under `maintenance-docs/archive/` AND carry
an explicit supersession relationship. Per the PRISON DISPOSITION RULE these are
"doubly useless" (archived + superseded). Listed factually with evidence; no
prison-membership recommendation is made here.

| Archived path | Superseded by | Evidence (verbatim, in-doc) |
|---|---|---|
| `maintenance-docs/archive/V10-PREDESIGN.md` | `maintenance-docs/V10-DESIGN.md` (live at `archive/V10-DESIGN.md`) | `:4` "*Status: SUPERSEDED by ...V10-DESIGN.md*"; `:6` "This document has been superseded." (= R3) |
| `maintenance-docs/archive/V9-DESIGN.md` | BD-043 / BD-046 resolution (sections) | `:13` "The inline GEMINI.md approach described in this document has been superseded. See BD-043..." (= R4; SECTION-level) |

ADDITIONAL archived docs whose supersession is recorded BY OTHER docs (the
archived doc itself may not carry the banner):

| Archived path | Superseded by | Evidence (verbatim) + SHA |
|---|---|---|
| `maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B.md` (V1) | `archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` (V2) | `archive/v11/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md:181`: "`ARCHITECTURE-CLEANUP-BATCH-19B.md` ... V1 architect doc, superseded by V2 ... superseded V1 architect doc; will be archived in 19b-7". Both V1 and V2 were archived together in commit `efd9a32` ("Batch 19b cleanup — archive workflow artifacts to maintenance-docs/archive/v11/"). |
| `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §349 (CONCEPTUAL-REVIEW-METHODOLOGY destination rationale) | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` placement per AUDIT-USER-CURATION Override 6 | `archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md:349`: "**Naming rationale ... — SUPERSEDED by Override 6:** ... The original `maintenance-docs/` rationale ... is REJECTED." (SECTION-level within an archived doc.) |
| `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md` records the deletion of `IMPLEMENTATION-REPORT-BD-175-F4.md` (a never-committed intermediate doc) | this bundle IMPL-REPORT | `:41` "...IMPLEMENTATION-REPORT-BD-175-F4.md | DELETED | Prior coder pass's F4-only IMPL-REPORT; superseded by THIS bundle report"; `:356` same. The F4-only doc was NEVER tracked in git (no `git log` record), so this is a record of a working-tree-only supersession; the F4 doc does not exist to send anywhere. |

NOTE on the BD-175 archive sweep (commit `9da98a4`, "archive BD-175 batch
artifacts (99 files)"): this commit was a pure RENAME (`v11-implementation/ ->
archive/v11/`) of ~46+ workflow artifacts (IMPL-REPORTs, PACK-REVIEWs,
ORCHESTRATION-PLAN, etc.) per the Pattern B end-of-batch sweep. These are
ARCHIVED but NOT superseded — they are non-superseded historical records. They
are listed here only to disambiguate "archived" from "archived AND superseded";
they do NOT belong in this §3 subset.

---

## 4. SUSPECTED, evidence-thin (appears superseded; no citable establishing evidence)

**S1. `maintenance-docs/v11-research/ARCHITECTURE-V3.1-DELTA.md`** — appears
fully integrated/absorbed into the V3.3 line. ARCHITECTURE-V3.3-DELTA `:7` says
"V1 + V2 + V3 + V3.1-DELTA stand otherwise" (i.e. NOT superseded). No supersession
evidence found; listed only to record that it was checked and is NOT superseded.

**S2. `maintenance-docs/v11-research/ARCHITECTURE-REVIEW.md` (PASS1) /
`ARCHITECTURE-REVIEW-PASS2.md`** — PASS3 (`ARCHITECTURE-REVIEW-PASS3.md:6`)
references them as "Prior reviews" whose findings were "fully resolved per PASS2"
/ "substantially absorbed into V3.3 + Addendum 4." This is sequential review
accumulation, NOT whole-doc supersession; no review doc says it "supersedes" a
prior review. Evidence-thin for a supersession claim — recorded as SUSPECTED-NOT.

**S3. `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md` (UNTRACKED)**
— reviews H.2 against `PLAN-BD-185-ADDENDUM.md` §4.2 (`:5`), which is now
superseded by PLAN-BD-185-V2 (R8). The review's BASELINE is superseded, but no
doc states the review itself is superseded by a successor review. SUSPECTED that
its authority is stale-by-baseline; no direct supersession evidence.

**S4. `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md`** —
`HANDOFF-V11.1-ARCHITECT.md:19` says it is "Mostly superseded by
REQUIREMENTS-GROUPINGS-V11.md, but §10's grouping doc shape example and §14 open
questions remain useful context. **OPTIONAL.**" This is a "mostly superseded"
hedge, not a clean whole-doc supersession (parts explicitly remain useful).
SUSPECTED partial-supersession; evidence is a single secondary reference.

**S5. `maintenance-docs/V10-DESIGN.md` path-resolution gap** — R3's named
successor `maintenance-docs/V10-DESIGN.md` does NOT exist at that path; the live
file is `maintenance-docs/archive/V10-DESIGN.md`. The supersession (PREDESIGN ->
DESIGN) is solid; the path in the banner is stale (the DESIGN doc was later
archived). Flagged so the parent does not chase a missing path.

**S6. `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` + ADDENDUM-2/3/4** —
the per-entry-split / V3.3 work re-planned much of this corpus
(`ARCHITECTURE-V3.3-DELTA.md:7` "The base IMPLEMENTATION-PLAN.md and Addenda 1, 2,
3 are approved and unchanged at the BD-content level"). No supersession evidence;
explicitly "unchanged at BD-content level." SUSPECTED-NOT-superseded; recorded as
checked.

---

## 5. Open questions for the user

**OQ1 — Off-tree Gemini->Antigravity supersession (main branch only).** Commit
`7ccbba9` ("docs: reference doc consolidating Gemini CLI -> Antigravity CLI state")
created `maintenance-docs/REFERENCE-GEMINI-TO-ANTIGRAVITY.md`, whose message states
it "supersedes the 2026-05-21 research doc" (= `RESEARCH-ANTIGRAVITY-CLI-MIGRATION.md`,
created in `4234cde`). NEITHER file is an ancestor of v11-dev HEAD `8ebf8f8`
(`git merge-base --is-ancestor` returns false for both; both live on `main`). They
are NOT in the v11-dev working tree. Does the BD-195 supersession map need to
account for main-branch-only docs, or is the prison scoped to the v11-dev tree?

**OQ2 — `templates-archive/v11.1/` cut is the categorical-error contamination.**
Per the BD-195 CATEGORICAL FACT (v11.0 unreleased; phase-parts always v11.0;
"v11.1 cut" / "frozen v11.0" is wrong), the entire `templates-archive/v11.1/`
subtree (`INDEX.md`, `phase-part-v11.1/SCHEMA.md`, `forms/work-item.yml`) encodes
the false "v11.1 archive cut" premise. ARCHITECTURE-BD-185-V2 §3 D-1 / §10
explicitly corrects this to v11.0 (R12, R13). RESEARCHER FINDING: the v11.1
SCHEMA's grammar substance is carried forward (adopted verbatim per V2 §2.B), but
its v11.1 version tag + placement are superseded. The user should decide whether
the superseding artifact (v11.0 placement) is the live V2 design or a yet-to-be-
created `templates-archive/v11.0/phase-part-v11.0/` — the latter does not exist
yet, so R12/R13 point at a DESIGN, not a shipped successor file.

**OQ3 — Untracked superseding docs.** R7, R8, R11, R12, R13 are established by
UNTRACKED working-tree docs (`ARCHITECTURE-BD-185-V2.md`, `PLAN-BD-185-V2.md`,
`ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`). If a doc's superseding successor
is itself uncommitted, the parent should confirm those V2 docs are the intended
authoritative successors before treating the originals (BD-185.md,
BD-185-RECONCILIATION.md, PLAN-BD-185.md, PLAN-BD-185-ADDENDUM.md) as superseded.

**OQ4 — PLAN-BD-185-ADDENDUM "supplements vs superseded" conflict.**
PLAN-BD-185-ADDENDUM.md:8 says it "**Supplements (does NOT replace)**" PLAN-BD-185.md,
but PLAN-BD-185-V2.md §0 supersedes BOTH in their entirety. The addendum's
self-framing and the V2's claim disagree. The V2 (later, authoritative-claimed)
wins on the evidence, but the user should confirm.

**OQ5 — `/backlog/` and `/changelog/` per-entry trees referenced by CLAUDE.md do
not exist on disk.** CLAUDE.md repeatedly cites `/backlog/_rules.md` and
`/changelog/_rules.md` as per-entry source-of-truth trees, but neither directory
exists in the v11-dev tree (`git ls-files` returns nothing; `ls` returns "No such
file or directory"). This is NOT a supersession finding (out of scope for this
pass), but it is a structural inconsistency I encountered while enumerating and
flag for the parent: either the trees were never created on this branch, or the
CLAUDE.md references are stale. The pack `BACKLOG.md`/`CHANGELOG.md` exist only as
monoliths at `pack-ops/`.
