# PLAN-BD-195-INVESTIGATION — Code Red 3 investigation-approach plan

**BD:** BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo).
**Pass:** BD-195 Step 0 (investigation-approach planning). Runs FIRST, before any researcher/architect work.
**Author:** pack-planner (read-only investigation-approach pass).
**HEAD at authoring:** `e580dda7eb46c640a92afabd3469bbada17d1975`.
**Status:** DRAFT — goes to the user for review before any researcher/architect work runs (per BD-195 Step 0).

---

## 0. What this document is — and is NOT

This is the **approach plan** that governs HOW the later docs-researcher
and architect passes of BD-195 run. It defines segmentation, a shared
output-shape/standard, the reconciliation pass, sequencing relative to
BD-195 Steps 1–2, and the depth gates.

It contains **NO findings and NO fix designs**. Per the BD-195 directive
and the planner constraints, this pass plans the structure of the
investigation; it does not investigate the repo for problems and does not
design fixes. Any concrete problem or fix that appears below would be a
scope violation — the researcher segments (Step 3) produce the problem
list, the architect segments (Step 5) produce the fix design.

The two known SEED failures are named ONLY as examples of the *class* of
thing every segment must surface; they are not findings produced here.

### Source directive

The governing text is the **BD-195 entry in `pack-ops/BACKLOG.md`**
(the entry begins at the line headed `**BD-195 (Code Red 3) — …**`).
Read it in full before acting on this plan. The directive's Steps 0–9,
its Surfacing standard, and its Quality bar ("broad AND deep — never
broad-but-sparse") are load-bearing inputs to everything below.

### The two known SEED failure classes (examples only)

Per the directive's "Known-broken SEED (non-exhaustive)":

1. **v11.0/v11.1 mis-versioning** — content that attributes work to the
   wrong minor version, or blurs the v11.0-ships-now vs v11.1-deferred
   boundary.
2. **pack/project boundary residue** — pack-only concepts leaking onto
   client-facing/project-side surfaces, or project-side concepts leaking
   into pack-self-management surfaces (the CLAUDE.md § Pack memory
   "deliverable-only" and "separation of concerns" rules).

The directive is explicit: **we do not know whether these are the only
ones.** Every segment must proactively surface ANY potential
inconsistency or needed fix, not just these two.

---

## 1. Repo inventory (segmentation evidence base)

Captured read-only at HEAD `e580dda` to justify the segment boundaries
in §2. Counts are tracked files via `git ls-files` unless noted.

**Total tracked files:** 1054, plus 5 untracked BD-185-V2 working-tree
docs (see §1.2).

### 1.1 Tracked-file distribution by area

| Area | Files | Notes |
|---|---|---|
| `maintenance-docs/archive/` | 252 | Historically frozen (v9/v10/v11 archived design records). `archive/v11/` = 201, `archive/v10-working/` = 25, loose v9/v10 records = the rest. |
| `maintenance-docs/v11-implementation/` | 187 | ACTIVE v11 design records, plans, impl-reports, reviews. Highest BD-185-contamination + mis-versioning density. |
| `maintenance-docs/v11-research/` | 73 | v11 research, groupings (v11.1) requirements, `templates-archive/` pack-archive surface (13 files), queued BD-185 researcher prompt. |
| `maintenance-docs/` (loose + origins + guides) | 15 | TOOL-COMPARISON, VERIFIED-NOTES, RECOMMENDATIONS, deprecated analyses, V10-* design/research docs, `origins/`, `guides/`. |
| `scripts/tests/` | 206 | Test-encoding surface (per CLAUDE.md "Enumerate ENCODING surfaces" rule). |
| `scripts/lib/` | 40 | Tracker subsystem, migrator framework, per-entry helpers, customization-preservation. |
| `scripts/` (root + persona-contracts) | 27 | `validate-pack.py`, `init-project.sh`, `migrate-v10-to-v11.sh`, `pack-tracker.sh`, `pack-td.sh`, merge-*.py, `persona-contracts/`, top-level `test-*.sh`. |
| `project-template/` | 154 | Client-shipped surface: trinity, `docs/pack/`, `docs/project/` per-entry trees, `skills/` (36), `.claude/.codex/.gemini/` (61), `scripts/` (15), `.github/` (3), proto/server/config. |
| pack-root `.claude/` `.codex/` `.gemini/` | 48 | Pack-self config: 5 pack agents ×3 CLIs (15), 11 shared skills ×3 CLIs (~31), `.gemini/commands/` (2). |
| `pack-ops/` | 12 | BACKLOG, CHANGELOG, PACK-CHAT, PACK-AGENTS, HELP-FRAGMENT-PACK/-TRACKER, BOUNDARY-DEFINITION, OPTIONAL-FEATURES, `.boundary-exempt-root.txt`. |
| `supporting-docs/` | 10 | METHODOLOGY, INSTALL-PROCEDURES, MIGRATION-v10-to-v11, MERGE-STRATEGY, DRY-RUN-MIGRATION, SETUP-*, DEPENDENCIES, CLI-PM-SETUP, AGENT_KICKOFF_TEMPLATE. |
| `xcode-companion-templates/` + `vscode-companion-templates/` | 10 | Machine-level companion configs. |
| `test-fixtures/` (tracked) | 8 | `build.sh`, `manifest.txt`, README, `.gitignore`, `v11-trinity-marker-prepped/` trinity (built fixture dirs are gitignored). |
| pack-root `.github/` | 4 | `ISSUE_TEMPLATE/{work-item,inbound,config}.yml`, `workflows/validate-pack.yml`. |
| root loose files | 8 | `README.md`, `QUICKSTART.md`, `LICENSE.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `tracker.toml.pack-example`, `.gitignore`. |

### 1.2 Untracked working-tree BD-185-V2 docs (5)

These exist in the working tree at HEAD and are IN SCOPE (the directive
supersedes "the committed H.1/H.2 + the untracked V2 analysis docs"):

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`
- `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md`
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md`
- `maintenance-docs/v11-research/RESEARCH-BD-185-ORDERING-API.md`

### 1.3 Known BD-185-attempt committed docs (prison-dir candidates)

Surfaced by name-scan only (NOT classified here — Step 1/Step 2 and the
researcher passes own classification). Committed docs whose names bind to
the BD-185 attempt, Code Red 2 (BD-193/BD-194), or v11.1 groupings:

- `v11-implementation/ARCHITECTURE-BD-185.md`, `ARCHITECTURE-BD-185-RECONCILIATION.md`
- `v11-implementation/PLAN-BD-185.md`, `PLAN-BD-185-ADDENDUM.md`
- `v11-implementation/IMPLEMENTATION-REPORT-BD-185-*` (6 files), `PACK-REVIEW-BD-185-H.1.md`
- `v11-implementation/ARCHITECTURE-BD-194.md`, `PLAN-BD-194.md`, `PACK-REVIEW-BD-194.md`, `IMPLEMENTATION-REPORT-BD-194*` (3 files)
- `v11-implementation/IMPLEMENTATION-REPORT-BD-193*` (2 files), `PACK-REVIEW-BD-193-PHASE-4.md`
- `v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md`, `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`, groupings docs (`REQUIREMENTS-GROUPINGS-V11.md`, `INTAKE-GROUPINGS-V11.md`, `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`, `RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`, 2 grouping impl-reports)

**This list is a candidate set for Step 1/Step 2 triage, NOT a
prison-membership decision.** The decision of what is "superseded /
contaminated" (→ prison) vs "active design record to be fixed in place"
belongs to Step 1 (retained-decisions extraction) + Step 2 (the user-
confirmed prison move), informed by the researcher passes. See §4.

### 1.4 Seed-class concentration (read-only scan, evidence for depth gates)

`v11.1`-string occurrences by area (excluding `archive/`): v11-research
42, v11-implementation 38, scripts/tests 10, scripts/lib 4,
validate-pack.py 1, pack-tracker.sh 1, pack-ops/BACKLOG.md 1, root
trinity 1 each. This confirms the mis-versioning seed is NOT confined to
the BD-185 docs — it has propagated into scripts, the validator, tests,
and the trinity. Segmentation must therefore cover code + tests + config,
not just the design-record docs.

---

## 2. SEGMENTATION

### 2.1 Design principles for the boundaries

The directive requires coverage of the **ENTIRE repo (pack + project),
every doc/script/file, EXCEPT the prison directory** (BD-195 Step 2),
examined **broad AND deep**. Five principles drive the boundaries:

1. **Partition, not overlap.** Every tracked file (and the 5 untracked
   V2 docs) maps to exactly ONE researcher segment as its *primary
   owner*. No file is unowned; no file is double-owned for primary
   coverage. (Cross-cutting seed sweeps in §2.4 are a SECONDARY lens
   layered on top, not a re-partition.)
2. **Cohesion by surface + audience + edit-authority.** Segment
   boundaries follow the repo's own seams: pack-side vs project-side
   (the boundary the seed-2 failure lives on), code vs docs vs config,
   and PM-only vs agent-editable. This makes each segment internally
   consistent in what "correct" means and aligns fix-authority with the
   later architect/coder split.
3. **Depth-bounded size.** No segment is so large that depth degrades to
   a skim. The two oversized raw areas — `maintenance-docs/` (527) and
   `scripts/` (273) — are split internally (active-design vs research vs
   frozen-archive; code vs tests). The depth gates in §6 enforce this.
4. **The contamination epicenter gets its own segment.** The BD-185
   attempt + Code Red 2 (BD-193/BD-194) docs are the densest
   contamination; isolating them (Segment R7) lets that segment run the
   deepest line-level read while the rest of the repo is checked for the
   *spread* of the same defects.
5. **Mirror the researcher partition into the architect partition.**
   Architect segments (§2.5) reuse the researcher segment IDs so a
   researcher segment's problem list flows to the matching architect
   segment with no re-mapping — this is what makes reconciliation smooth.

### 2.2 The single exclusion

**The prison directory (created in Step 2) is the ONLY excluded
location.** Until Step 2 runs, nothing is excluded. After Step 2, any
path the user confirms into the prison directory is out of scope for the
researcher/architect passes (Steps 3/5): presence there = contaminated =
ignored. Every other path — including `maintenance-docs/archive/` and the
5 untracked V2 docs — is IN SCOPE. See §4 for how Steps 1–2 sequence
ahead of the passes.

> Note on `maintenance-docs/archive/` (252 files): in scope, but governed
> by the special handling rule in §2.6 — archived records are read for
> *active outbound references* and *mis-versioning that misleads*, not
> rewritten as if they were live design docs. **Refinement (per
> PLAN-BD-195-EXECUTION.md §10.1):** R9 owns only the NON-SUPERSEDED
> archive REMAINDER — the superseded archive subset is moved to the
> prison in Step 2 (before Step 3) and is out of scope for R9/A9.

### 2.3 Researcher segments (primary partition — 9 segments)

Each segment lists its **owned paths** (primary coverage) and its
**core question**. Together the owned-path sets are a partition of all
1054 tracked files + 5 untracked docs.

**R1 — Pack operations & governance (PM-only + pack-self surfaces).**
Owned: `pack-ops/` (12), root trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`
(3), `README.md`, `QUICKSTART.md`, `LICENSE.md`, `.gitignore`,
`tracker.toml.pack-example`, pack-root `.github/` (4: issue forms +
`validate-pack.yml`). Core question: are the pack-self governance
surfaces internally consistent, correctly versioned, and free of
project-side concept leakage (deliverable-only rule)? Includes the
README Repository-Layout authority and version table.

**R2 — Pack-self agents & skills (pack-root configs).** Owned: pack-root
`.claude/` `.codex/` `.gemini/` (48): 5 pack agents ×3 CLIs, 11 shared
skills ×3 CLIs, `.gemini/commands/`. Core question: trinity/quad parity
across the three CLIs, agent-rule correctness, skill-content correctness,
and any stale BD/version references in agent or skill prose.

**R3 — Client-shipped product: trinity + docs/pack + docs/project.**
Owned: `project-template/CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (3),
`project-template/docs/pack/` (incl. METHODOLOGY/PLATFORM-SKILLS/PM-CHAT/
prompts/HELP-FRAGMENT), `project-template/docs/project/` per-entry trees
(backlog/implementation-plan/changelog `_rules.md`/`_intro.md`/`_format.md`),
`project-template/README.md`. Core question: client-facing correctness —
no pack-only leakage (token-economy + separation-of-concerns rules),
correct versioning, trinity parity, per-entry contract integrity.

**R4 — Client-shipped product: agents, skills, scripts, config.** Owned:
`project-template/.claude/` `.codex/` `.gemini/` (61: 16 agents ×3 +
skills + commands + config files like `settings.json`/`config.toml`/
`.env.example`), `project-template/skills/` (36), `project-template/scripts/`
(15), `project-template/.github/` (3), `project-template/proto/`,
`project-template/server/`, `project-template/{pyproject.toml,
pyrightconfig.json, .mcp.json.example, .gitignore, agent-run.sh,
tracker.toml.project-example}`. Core question: client-shipped executable
+ config + skill surface correctness, cross-CLI parity, versioning,
boundary cleanliness.

**R5 — Pack scripts: source (non-test).** Owned: `scripts/validate-pack.py`,
`scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`,
`scripts/add-capability.sh`, `scripts/pack-help.sh`, `scripts/pack-tracker.sh`,
`scripts/pack-td.sh`, `scripts/tracker-migrate.sh`,
`scripts/restore-from-backup.sh`, `scripts/dry-run-migration.sh`,
`scripts/compare-agent-trinity.py`, `scripts/merge-*.py` (4),
`scripts/lib/` (40), `scripts/persona-contracts/` (3). Core question:
behavioral correctness, check/validator definitions, version references
in code, boundary cleanliness, and whether code encodes any seed defect
(e.g., a v11.1 string in a validator allowlist).

**R6 — Pack scripts: tests + fixtures (ENCODING surfaces).** Owned:
`scripts/tests/` (206), top-level `scripts/test-*.sh` (10),
`test-fixtures/` tracked (8). Core question — per the CLAUDE.md
"Enumerate ENCODING surfaces" rule: do test assertions encode the
correct expected state, and do any tests encode a seed defect (e.g., a
hardcoded v11.1 expectation, a pack-self assertion that admits a
forbidden project-side concept)? This segment is paired with R5 (same
ENCODING-lock-step concern) and must run AFTER or alongside R5 with
cross-reference (see §2.7).

**R7 — Contamination epicenter: BD-185 attempt + Code Red 2 + groupings
design records.** Owned: the §1.2 untracked V2 docs (5) + the §1.3
committed BD-185/BD-193/BD-194/groupings docs + `templates-archive/`
(13) — i.e., the `v11-implementation/` and `v11-research/` files that
bind to the BD-185 attempt, Code Red 2, or v11.1 groupings. Core
question: deepest line-level read of the epicenter — every claimed
decision, every version attribution, every pack/project boundary
statement, every cross-reference. This is the segment most likely to
feed Step 1 (retained-decision LEADS) and to enrich the whole-repo
supersession-mapping pass's epicenter entries; prison-membership
IDENTIFICATION itself is owned by that dedicated supersession-mapping pass,
NOT by R7 (see §2.7 + PLAN-BD-195-EXECUTION.md §4.1/§5). **Note: R7's owned
set is the *complement* of R8 within `v11-implementation/` +
`v11-research/` — see R8.**

**R8 — Active v11 design records (non-epicenter maintenance-docs).**
Owned: `maintenance-docs/v11-implementation/` and
`maintenance-docs/v11-research/` files NOT owned by R7 (the architecture/
plan/impl-report/review docs for BD numbers other than BD-185/193/194 and
non-groupings research), PLUS `maintenance-docs/` loose docs (TOOL-COMPARISON,
VERIFIED-NOTES, RECOMMENDATIONS, deprecated analyses, V10-* design/research,
`origins/`, `guides/`). Core question: are the still-live v11 design
records correct, correctly versioned, and free of boundary leakage; are
the loose/deprecated docs correctly labeled (deprecated vs current)?
**This document (`PLAN-BD-195-INVESTIGATION.md`) is owned by R8** but is
exempt from findings (it is the approach plan itself).

**R9 — Frozen archive (non-superseded remainder) + companion templates.**
Owned: `maintenance-docs/archive/` MINUS the prisoned-from-archive paths,
`xcode-companion-templates/` (6), `vscode-companion-templates/` (4). Core
question — governed by the §2.6 archive rule: do frozen records contain
*active outbound references* that are now stale, or mis-versioning that
would mislead a reader treating them as current? Companion templates:
correctness + version + parity. **Owned-path manifest is computed AFTER
the Step-2 prison move** as `maintenance-docs/archive/` minus the
prisoned-from-archive paths (per PLAN-BD-195-EXECUTION.md §10.1): the
superseded archive subset is prisoned in Step 2 (before Step 3) and is
out of scope for R9/A9. (The `archive/` count of 252 in §1.1 is the
pre-prison total; R9's owned count is that total minus whatever Step 2
moves to the prison.)

### 2.4 Cross-cutting SECONDARY lenses (layered on every segment)

These are NOT segments (they do not own files); they are **mandatory
lenses every R-segment applies to its owned paths**, guaranteeing the two
known seeds plus the standing boundary rules are checked everywhere, not
just where they are "expected":

- **Lens A — version attribution (seed 1).** Every v11.0/v11.1 / vN
  reference: is it correct, and does it respect "v11.0 ships now,
  v11.1+ is deferred only on explicit user direction"?
- **Lens B — pack/project boundary (seed 2).** Every cross-surface
  reference: pack-only concept on a client-facing surface? Project-side
  concept (TD/phase/phase-part/phase-task) on a pack-self-management
  surface? (CLAUDE.md "deliverable-only", "separation of concerns",
  "token economy", "BD pack-only operational" rules.)
- **Lens C — cross-reference integrity.** Every doc/path/symbol
  reference: does the target exist at the cited location? (Filename-
  uniqueness + bare-version-shorthand leak class per CLAUDE.md.)
- **Lens D — trinity/parity.** Wherever a trinity or quad exists in the
  owned paths: parity held, asymmetry justified.
- **Lens E — ENCODING-surface lock-step.** For any owned surface with an
  invariant, is that invariant also asserted by a validator/test/CI/doc,
  and are those in lock-step? (Drives the R5↔R6 pairing.)

Each lens maps to the shared template's finding categories (§3.3) so
findings are uniformly tagged for reconciliation.

### 2.5 Architect segments (fix-design partition — mirror the 9)

The architect pass uses the **same 9 segment IDs (A1…A9 ≡ R1…R9)**. Each
architect segment consumes its matching researcher segment's problem list
plus any cross-segment findings the reconciliation routed to it (§3).
Reusing the IDs is the mechanism that makes reconciliation smooth: there
is a 1:1 channel from each researcher problem list to its fix-design
owner, and cross-cutting findings carry an explicit owner tag.

Architect segments additionally honor the boundary/process rules as
*design constraints* (not just detection lenses): a fix that moves a
concept across the pack/project boundary, or that changes a rule, is an
architect-level decision requiring the full pipeline — never a mechanical
patch (per CLAUDE.md "Skill and agent maintenance is mechanical by
default" + the architect-spawn protocol).

### 2.6 Special handling: `maintenance-docs/archive/` (R9)

Archive is frozen history. R9/A9 do NOT rewrite archived records to match
current design. **Scope refinement (per PLAN-BD-195-EXECUTION.md §10.1):**
this rule governs the NON-SUPERSEDED archive REMAINDER only. The
superseded archive subset is moved to the prison in Step 2 (before
Step 3) and is out of scope for R9/A9; R9's owned-path manifest is
therefore computed AFTER the Step-2 prison move as
`maintenance-docs/archive/` minus the prisoned-from-archive paths. The
frozen-history rule below still governs that remainder. (QG-5 is
unchanged — prisoned paths are already subtracted from both sides of
the coverage diff per §6.) The archive rule:

- **Flag** (a) *active outbound references* from an archived doc that are
  now broken/stale (a live pointer that resolves wrong), and (b)
  *mis-versioning that would mislead* a reader who treats the archived
  doc as current.
- **Do NOT flag** historically-accurate statements that were correct when
  written (e.g., "v10 will ship X") — that is the record doing its job.
- Any proposed archive edit is the narrowest possible (fix the broken
  pointer; add a "superseded" note) and is surfaced for explicit user
  decision, because editing history is itself a judgment call.

### 2.7 Parallel vs sequential execution

Researcher segments are mostly independent and run **in parallel**, with
two ordering constraints:

- **R5 → R6 (or R5 ∥ R6 with cross-reference).** R6 (tests/fixtures)
  encodes invariants defined by R5 (source). R6 must reference R5's
  findings so an ENCODING-lock-step gap (Lens E) is caught on both sides.
  Acceptable: R5 first, then R6; or both in parallel with a documented
  hand-shake at reconciliation.
- **R7 pre-read runs in parallel with Step 1 (per PLAN-BD-195-EXECUTION.md
  §4.1/§6.1).** R7 (epicenter) runs a *scoped pre-read* → `AUDIT-BD-195-R7-PREREAD.md`,
  which ENRICHES Step 1 (retained-decision LEADS — non-blocking; the Step-1
  extractor reads the epicenter directly) and ENRICHES the whole-repo
  supersession-mapping pass's epicenter entries. It is ONE of three parallel
  pre-prison read-only passes (the Step-1 extractor, the supersession-mapping
  pass, and this R7 pre-read) with NO inter-dependency; all three converge
  before Step 2. **Prison-membership IDENTIFICATION is owned by the dedicated
  whole-repo supersession-mapping pass, NOT by R7** (R7 is epicenter-scoped).
  The full R7 deep pass then runs in Step 3 over whatever epicenter docs remain
  outside the prison. Sequencing detail is in §4 + PLAN-BD-195-EXECUTION.md
  §4.1/§5/§6.1.

Architect segments run **after** the reconciled problem list exists
(§4). Within the architect phase, A1…A9 are mostly parallel; any
cross-segment fix the reconciliation flagged as coupled runs with an
explicit dependency edge (named at reconciliation, §3.4).

### 2.8 Why nothing falls through the cracks

- **Completeness check (mechanical).** Before the researcher phase is
  declared complete, run a coverage audit: `git ls-files` minus the
  prison paths, diffed against the union of the 9 segments' owned-path
  manifests. The diff MUST be empty. The 5 untracked V2 docs are added to
  the R7 manifest explicitly. This is a gate (§6, QG-5).
- **No-overlap check.** The same audit verifies no file is claimed as
  *primary* by two segments (cross-cutting lenses are secondary and do
  not count as primary ownership).
- **The partition follows real seams**, so a file's segment is
  unambiguous: a file is pack-side or project-side; code or docs or
  config; epicenter or not; frozen-archive or active. Edge cases
  (e.g., `tracker.toml.pack-example`) are pinned explicitly in §2.3.

---

## 3. SHARED STANDARDS / OUTPUT-SHAPE

One common template is used by **every researcher segment AND every
architect segment**. Uniformity is what lets the reconciliation pass
combine segment outputs without friction. Deviating from the shape is a
gate failure (§6, QG-3).

### 3.1 The surfacing standard (mandatory, from the BD-195 directive)

Every finding in every pass MUST satisfy all of:

1. **Agent-owned framing.** The finding is the AGENT's finding +
   the AGENT's recommendation. When Pack Chat relays it to the user, it
   is relayed as the agent's, never as Pack Chat's own. (Researcher
   reports state "RESEARCHER FINDING"; architect reports state "ARCHITECT
   RECOMMENDATION".)
2. **Self-contained context.** The finding carries enough context that
   the user can decide **without re-reading the chat and without
   cross-referencing any other doc.** Concretely, each finding embeds:
   the exact file path(s), the relevant quoted text or a tight excerpt,
   why it is a potential problem (which rule/expectation it violates,
   cited), and the recommended action. A finding that says "see the
   review doc §4" or "as discussed" FAILS this standard.
3. **Proactive breadth.** Each pass surfaces ANY potential inconsistency
   or needed fix — not only the two known seeds. "I was only asked about
   versioning" is not a valid reason to omit a boundary leak the segment
   noticed in its owned paths.
4. **User decides.** The agent recommends; the user decides what to act
   on, if anything. Findings never assume their own acceptance.

### 3.2 Finding record shape (identical for researcher and architect)

Per the M3 finding-record hard-cap (`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`
§6): each finding is ONE record with one-line evidence per field and every
violated rule named (not re-explained). Field order:

```
### <SEGMENT-ID>-F<NN> — <one-line title>
- Severity: BLOCKER | MUST | SHOULD | NIT
- Category: Lens A–E tag(s) + free tags (§3.3)
- Surface(s): path + symbol/anchor (never bare line numbers)
- Pack/project side: pack-self | client-shipped | maintenance-doc | frozen-archive | cross
- Evidence: one-line self-contained excerpt or precise description
- Why it's a problem: the violated rule named + where it lives (cite, do not re-explain)
- Recommendation: one-line concrete action
- Cross-segment touch points: implicated segments/files, or "none"
- Confidence: high | medium | low (one-line basis)
- Status: blank by segment; filled at reconciliation
```

Architect records add (after Recommendation): **Fix design** (what changes,
where, order; rejected alternatives) and **Blast radius** (every touch point
incl. ENCODING surfaces — validator/tests/CI/docs — and trinity/quad mirrors).

The **Cross-segment touch points** and **Blast radius** fields are the
hooks the reconciliation uses to de-duplicate and to route coupled fixes
(§3.4 / §4).

### 3.3 Category tags (controlled vocabulary)

Findings are tagged with one or more of the Lens tags from §2.4 plus
optional free tags, so reconciliation can group across segments:

- `version` (Lens A — seed 1), `boundary` (Lens B — seed 2),
  `xref` (Lens C), `parity` (Lens D), `encoding` (Lens E).
- Free tags as needed: `stale-ref`, `ci-risk`, `migration-regression`,
  `trinity`, `prison-candidate` (any deep segment may tag a doc it believes
  belongs in the prison that the whole-repo supersession-mapping pass missed —
  the late-discovery safety net per PLAN-BD-195-EXECUTION.md §4.1 residual-miss
  handling; Step 2 decides. Prison-membership IDENTIFICATION is owned by the
  dedicated supersession-mapping pass, NOT by this tag — see §2.7),
  `retained-decision` (R7 may tag a user-preapproved decision that Step 1
  should capture), `correctness`, `consistency`, `doc-accuracy`.

The two seeds are first-class tags (`version`, `boundary`) so the
reconciliation can prove they were swept everywhere AND surface the
"unknown unknowns" the directive demands under the other tags.

### 3.4 Segment report skeleton (researcher and architect)

Each segment writes ONE report file with this top-matter, then the
finding records:

```
# <RESEARCH|ARCHITECTURE>-BD-195-SEGMENT-<ID>-<short-name>.md
- Segment: <ID> (<name>)
- Pass: researcher | architect
- Owned paths (manifest): <the exact path globs/files this segment owns>
- Coverage attestation: <every owned path was read; list any path read-only-skimmed with reason>
- Lenses applied: A B C D E (+ any segment-specific)
- Depth evidence: <see §6 — the depth-gate artifacts for this segment>
- Findings count by severity: BLOCKER n / MUST n / SHOULD n / NIT n
- Open questions for the user (genuinely unanswerable — intent/judgment only): <list or "none">

## Findings
<finding records per §3.2>

## Coverage map
<owned-path → "clean" | finding-IDs, so a reader can confirm no owned path was silently dropped>
```

The **Coverage map** is what makes "broad" auditable: every owned path
appears with either "clean" or the finding-IDs against it. A path absent
from the coverage map is a gate failure (§6, QG-1).

### 3.5 Naming convention for segment outputs

To keep prose references unambiguous (CLAUDE.md filename-uniqueness rule)
and to group the BD-195 corpus:

- Researcher: `maintenance-docs/v11-implementation/RESEARCH-BD-195-SEGMENT-R<N>-<short>.md`
- Architect: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-SEGMENT-A<N>-<short>.md`
- Reconciliation (researcher side): `maintenance-docs/v11-implementation/AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`
- Reconciliation (architect side): `maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md`

(These are workflow artifacts — exempt from the "no new top-level doc"
structural signal during the batch per CLAUDE.md, and they sweep to
`maintenance-docs/archive/v11/` at version ship.)

---

## 4. SEQUENCING — Steps 1–2 vs the investigation, and overall order

The BD-195 directive's Steps 0–9 and this plan compose as follows. Each
arrow is a gate (user review where noted).

```
Step 0  Investigation-approach plan (THIS DOC) ──user review──┐
                                                              │
Step 1  Retained-Decisions extraction (one of THREE parallel pre-prison
        read-only passes — Step-1 extractor ∥ supersession-mapping pass ∥
        R7 pre-read; NO inter-dependency; R7 ENRICHES Step 1, non-blocking)
        (clean doc of user-preapproved good BD-185 decisions;
         user confirms the retained set)               ──user confirm──┐
                                                                       │
Step 2  Prison move (superseded docs → prison dir;   ◄── membership PROPOSAL assembled from the
        user-confirmed; presence = contaminated =         whole-repo SUPERSESSION-MAPPING pass
        ignored)                                          (the prison-ID owner) + Step-1 provenance
                                                          + R7 epicenter context
                                                       ──user approve the move──┐
                                                                                       │
Step 3+4  Researcher segments R1…R9 (parallel per §2.7) over   ◄── prison dir now excluded
          the entire repo EXCEPT prison; every touch point
          mapped (Step 4 = blast-radius is part of Step-3 passes)
                                                  │
          Reconciliation (researcher side) ───────┤  → AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md
                                                  │     (ONE exhaustive, de-duplicated problem list)
                                                  │     ──user review──┐
                                                                       │
Step 5    Architect segments A1…A9 (parallel per §2.7), each   ◄── consumes the reconciled problem list
          consuming its matching reconciled problems
                                                  │
          Reconciliation (architect side) ────────┤  → ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md
                                                  │     (ONE coherent fix design)
                                                  │     ──user review──┐
                                                                       │
Step 6    Fix-implementation planner (DISTINCT from this Step-0 planner) → fix plan ──user review──┐
Step 7    Implement fixes (pack-coder, per-commit; validate-pack.py green at every commit)
Step 8    Extensive reviews + audits of the fixes
Step 9    ONLY THEN fresh-start BD-185 (wipe vs proven-correct; bias: complete redo)
```

### 4.1 Why Steps 1–2 precede the researcher segments

- **Step 1 before Step 2** (directive order): the retained-decisions doc
  must be extracted from the contaminated sources BEFORE those sources
  are prisoned/deleted, or the preapproved decisions are lost.
- **Steps 1–2 before Step 3** so the prison directory exists and is
  populated before the researcher segments declare their exclusion. The
  researcher coverage audit (QG-5) diffs against `git ls-files` *minus
  the prison paths*; that subtraction is only well-defined once Step 2
  has run.
- **R7 scoped pre-read runs in PARALLEL with Step 1 (no inter-dependency).**
  R7 owns the epicenter, so it produces `AUDIT-BD-195-R7-PREREAD.md` with
  (a) `retained-decision`-tagged LEADS that ENRICH Step 1 (non-blocking — the
  Step-1 extractor reads the epicenter directly and does not wait on R7) and
  (b) epicenter-deep CONTEXT that ENRICHES the whole-repo supersession-mapping
  pass's epicenter entries. R7 is ONE of three parallel pre-prison read-only
  passes (Step-1 extractor, supersession-mapping pass, R7 pre-read); they have
  NO inter-dependency and all converge before Step 2. **Prison-membership
  IDENTIFICATION is owned by the dedicated whole-repo supersession-mapping pass,
  NOT by R7** (R7 is epicenter-scoped and would miss whole-repo supersession);
  the prison/analysis deadlock is broken by the supersession-mapping pass + R7
  reading IN PLACE before the Step-2 move, not by R7 preceding Step 1. The
  **full R7 deep pass** then runs in Step 3 over whatever epicenter docs remain
  OUTSIDE the prison. (See PLAN-BD-195-EXECUTION.md §4.1/§5/§6.1 for the
  authoritative per-pass definitions.)

### 4.2 What the Step-0 planner does NOT decide

This plan does NOT decide prison membership, does NOT extract the
retained decisions, and does NOT pre-judge any file as contaminated. The
§1.3 candidate list is raw name-scan input for the user's Step-1/Step-2
decisions, nothing more. Those are user-gated decisions (Step 1 "user
confirms"; Step 2 "user-confirmed move").

### 4.3 Prison directory placement (for Step 2 to instantiate)

The directive requires the prison be **distinct from
`maintenance-docs/archive/`**. This plan does not name the path (that is
a Step-2 decision), but flags the constraints the path must satisfy so
Step 2 can choose cleanly: (a) distinct from `archive/`; (b) unambiguous
by name that presence = superseded/contaminated; (c) outside any glob a
researcher segment owns, so the QG-5 coverage audit's "minus prison
paths" subtraction is clean; (d) outside `validate-pack.py`'s scanned
surfaces so CI does not lint prisoned content. Step 2 confirms the exact
path with the user.

---

## 5. THE FINAL RECONCILIATION PASS

Two reconciliations, one per side, each producing exactly ONE document.

### 5.1 Researcher-side reconciliation → ONE exhaustive problem list

**Input:** the 9 researcher segment reports (R1…R9).
**Output:** `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`.

Procedure:

1. **Ingest + index.** Pull every finding record into one index keyed by
   `<SEGMENT-ID>-F<NN>`. Verify each segment's Coverage map is complete
   (QG-1) before ingest; a segment missing its coverage map is bounced
   back, not reconciled around.
2. **De-duplicate.** Findings that describe the same underlying defect
   from different segments (caught via the `Cross-segment touch points`
   field and shared `Surface(s)`) are merged into one canonical finding
   that lists all reporting segments and all touch points. The merged
   finding keeps the HIGHEST severity asserted by any reporter.
3. **Resolve conflicts.** When two segments disagree (e.g., one says a
   reference is correct, another says stale), the reconciliation does NOT
   silently pick one. It records BOTH positions in the canonical finding
   and marks it `CONFLICT — user decision` (or routes to an architect
   segment if it is a design judgment). Conflicts are never dropped.
4. **Group by theme.** Cluster the de-duplicated findings by category tag
   (the two seeds `version`/`boundary` get dedicated sections so the
   directive's "did we sweep the known seeds everywhere?" question is
   answerable at a glance; all other tags follow). Within each cluster,
   order by severity.
5. **Completeness attestation.** The reconciled doc carries a coverage
   attestation: union of segment coverage maps == `git ls-files` minus
   prison (QG-5), restated here so the single problem list is provably
   exhaustive over the in-scope repo.
6. **Surfacing-standard pass.** Every canonical finding is re-checked
   against §3.1 (self-contained; agent-owned; user-decides) before the
   list is handed to the user.

The result is ONE coherent, de-duplicated, exhaustive problem list — the
directive's Step-3 deliverable.

### 5.2 Architect-side reconciliation → ONE coherent fix design

**Input:** the 9 architect segment reports (A1…A9), each keyed to the
reconciled problem list's findings.
**Output:** `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md`.

Procedure:

1. **Map fixes to problems.** Every reconciled problem must have exactly
   one owning fix design (or an explicit "no fix — user-decision/won't-
   fix recommendation with rationale"). A problem with no fix mapping is
   a gap (QG-6) and bounces back.
2. **Reconcile overlapping fixes.** When two architect segments propose
   fixes that touch the same surface (detected via the `Blast radius`
   field), reconcile into ONE fix for that surface that satisfies both
   problems, or sequence them with an explicit dependency edge and a
   single owner. No surface is edited by two uncoordinated fixes.
3. **Resolve fix conflicts.** When two segments propose incompatible
   fixes, the reconciliation records both with tradeoffs and marks it
   `DESIGN CONFLICT — user decision`. Boundary-moving or rule-changing
   fixes are flagged as requiring the full architect→planner→coder
   pipeline (not mechanical), per CLAUDE.md.
4. **Global blast-radius union.** Produce one consolidated blast-radius:
   every file the fix design will touch, every ENCODING surface
   (validator/tests/CI/docs) that must move in lock-step, every trinity/
   quad mirror, and the `test-fixtures/manifest.txt` regen trigger if any
   v11-surface path is in the union (CLAUDE.md manifest rule). This is the
   input the Step-6 fix-planner sequences into commits.
5. **Working-state guarantee design.** The fix design must be expressible
   as an ordered commit sequence where `validate-pack.py` (all invoked
   checks) passes at EVERY intermediate commit, and the per-check test
   files pass for any check touched. The reconciliation states the
   ordering constraints that make this possible (which fixes must precede
   which) so the Step-6 planner inherits a valid topological order.

The result is ONE coherent fix design covering every surfaced problem —
the directive's Step-5 deliverable.

### 5.3 How overlaps/conflicts resolve (summary rule)

- **Overlap (same defect/surface, compatible):** merge into one canonical
  finding/fix; keep highest severity; list all reporters + touch points.
- **Conflict (incompatible positions):** never silently pick; record both
  + tradeoffs; mark `user decision` (or route to architect if design).
- **Cross-segment coupling (fix in A-x needs a change owned by A-y):**
  explicit dependency edge + single owner; the Step-6 planner respects it.

---

## 6. QUALITY GATES — depth, not just coverage

These gates make "broad AND deep" true **by construction**. A segment or
reconciliation that fails any applicable gate is bounced back, not
reconciled around. The directive's "never broad-but-sparse" bar is
enforced here.

**QG-1 — Coverage map completeness (per segment, BREADTH).** Every owned
path appears in the segment's Coverage map with either "clean" or
finding-IDs. A path that was read but produced no finding is marked
"clean" explicitly — silence is not coverage. Gate: zero owned paths
absent from the coverage map.

**QG-2 — Depth evidence (per segment, DEPTH).** "Deep enough" means the
segment shows its work, not just its conclusions. Each segment's
`Depth evidence` block MUST include, proportional to its content type:

- *For doc-heavy segments (R1, R3, R7, R8, R9):* for each owned doc, the
  segment attests it read the FULL doc (not headers), and lists every
  outbound reference it resolved (Lens C) with pass/fail — depth is
  proven by the resolved-reference ledger, not by a word count.
- *For code segments (R5):* for each script/lib, the segment names the
  functions/checks it traced and the version/boundary strings it grep-
  audited, with the search commands shown.
- *For test segments (R6):* for each test surface, the segment names
  which invariant each assertion encodes and which R5 source surface it
  locks to (Lens E), with at least the R5↔R6 cross-reference table.
- *For config/parity segments (R2, R4):* the explicit trinity/quad parity
  matrix (per file group: are the N CLI variants in parity; if not, is
  the asymmetry justified) — depth is the matrix, not "looks fine".

Gate: the depth-evidence block exists and is non-trivial for every owned
path class. A segment that lists conclusions with no traceable evidence
of a full read FAILS.

**QG-3 — Output-shape conformance.** Every finding uses the §3.2 record
shape; every segment report uses the §3.4 skeleton. The surfacing
standard (§3.1) is satisfied per finding (self-contained, agent-owned,
recommends, user-decides). Gate: zero shape deviations; zero "see other
doc" findings.

**QG-4 — Seed-sweep proof (DEPTH on the known failures).** Because the
two seeds are known, every segment must PROVE it swept them across its
owned paths: the `version` and `boundary` lenses each produce either
findings or an explicit "swept, none found in <owned paths>, search
shown". A segment that is silent on a seed (neither finding nor explicit
clean-sweep) FAILS — silence on a known seed is the exact "broad-but-
sparse" failure the directive forbids.

**QG-5 — Cross-segment coverage audit (BREADTH, whole-repo).** Before the
researcher-side reconciliation completes: `git ls-files` minus the prison
paths, diffed against the union of all 9 segments' owned-path manifests
(+ the 5 untracked V2 docs on R7) == empty. No file in scope is unowned;
no file is double-owned for primary coverage. Gate: empty diff.

**QG-6 — Fix-to-problem completeness (architect side).** Every reconciled
problem maps to exactly one owning fix design or an explicit
"recommend won't-fix / user-decision" with rationale. Gate: zero
unmapped problems.

**QG-7 — Working-state design proof (architect side).** The reconciled
fix design states an ordering under which `validate-pack.py` (all invoked
checks) + the per-check test files for any touched check pass at every
intermediate commit, and names the `test-fixtures/manifest.txt` regen
obligation if any v11-surface path is in the blast radius. Gate: a valid
topological commit order is exhibited (the Step-6 planner refines it, but
feasibility is proven here).

**QG-8 — Uniformity for reconciliation.** All segments on a side used the
same template version and the same category vocabulary (§3.3), so the
reconciliation merges without per-segment special-casing. Gate:
template/vocabulary drift across segments == none.

> The depth gates (QG-2, QG-4) are the heart of "broad AND deep": QG-1/QG-5
> guarantee breadth (every file owned and mapped); QG-2/QG-4 guarantee
> depth (every owned path read in full, every seed provably swept, every
> conclusion backed by traceable evidence).

---

## 7. GOAL AND BD ITEMS ADDRESSED

**Goal of this pass (BD-195 Step 0).** Produce the investigation plan
that governs the BD-195 docs-researcher and architect passes so the work
is broad AND deep, segmented sensibly, uniform in standard/output-shape
across all segments, and combinable by a final reconciliation into ONE
exhaustive problem list + ONE coherent fix design — with Steps 1–2
sequenced ahead of the investigation.

**BD items addressed.** BD-195 (Code Red 3) Step 0 only. This plan does
not advance Steps 1–9 themselves (it structures them). It is explicitly
DISTINCT from the Step-6 fix-implementation planner. BD-185 is referenced
only as the paused, in-scope-for-supersession item whose attempt BD-195
recovers; this plan produces no BD-185 work.

**This plan fully addresses the Step-0 success criteria:**
- Segmentation covers the entire repo (pack+project), every file except
  the prison dir, with justified boundaries (§2) and a mechanical no-gap
  guarantee (§2.8, QG-5).
- One shared output-shape/standard incl. the surfacing standard (§3),
  used by all researcher + architect segments, enabling smooth
  reconciliation.
- A defined reconciliation pass producing one exhaustive problem list +
  one coherent fix design (§5), with explicit overlap/conflict resolution.
- Steps 1–2 are sequenced explicitly relative to the investigation (§4),
  including the three parallel pre-prison read-only passes (Step-1 extractor
  ∥ supersession-mapping pass ∥ R7 pre-read) that read IN PLACE before the
  Step-2 move and so break the prison/analysis ordering deadlock — with
  prison-membership identification owned by the supersession-mapping pass
  (per PLAN-BD-195-EXECUTION.md §4.1/§5/§6.1).
- Depth is enforced, not just coverage (§6, esp. QG-2/QG-4).

---

## 8. AFFECTED FILES

**Written by this pass (exactly one):**
- `maintenance-docs/v11-implementation/PLAN-BD-195-INVESTIGATION.md` (this doc).

**Files this plan SCHEDULES later passes to produce** (not written here —
named for the user's forward visibility):
- 9 researcher segment reports `RESEARCH-BD-195-SEGMENT-R<1..9>-<short>.md`
- 9 architect segment reports `ARCHITECTURE-BD-195-SEGMENT-A<1..9>-<short>.md`
- `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (researcher reconciliation)
- `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md` (architect reconciliation)
- A Step-1 Retained-Decisions doc (path/name a Step-1 decision)
- A Step-2 prison directory (path a Step-2 decision; constraints in §4.3)

**Files this plan IDENTIFIES as in-scope for the investigation** (the
whole repo): the §1.1 areas in full (1054 tracked) + the §1.2 untracked
V2 docs (5), partitioned across R1…R9 in §2.3 — minus whatever Step 2
moves to the prison directory.

**No PM-only files are edited by this pass.** `pack-ops/BACKLOG.md`,
README version table, trinity files, etc. are read-only here. (Per the
commit-discipline skill §4 + CLAUDE.md PM-only list.)

---

## 9. OPEN RISKS AND UNKNOWNS

These are risks for the LATER passes that this plan's structure is
designed to contain; they are not findings about the repo.

1. **Prison/analysis ordering deadlock.** Risk: the researcher passes
   need the prison defined, but defining the prison needs analysis.
   Containment: the three PARALLEL pre-prison read-only passes (Step-1
   extractor ∥ supersession-mapping pass ∥ R7 pre-read) read IN PLACE,
   then Step 2 moves the prison, then the full R1…R9 (incl. full-R7) run
   on the post-prison remainder (§4.1; PLAN-BD-195-EXECUTION.md §4.1/§5).
   Prison-membership identification is owned by the supersession-mapping
   pass (whole-repo), with R7 supplying epicenter enrichment. Residual
   risk: if the user's Step-2 prison set diverges from the proposed
   membership, the full passes re-scope; acceptable because they re-run on
   the post-prison remainder by design (+ the §4.1 residual-miss safety net
   in PLAN-BD-195-EXECUTION.md for any superseded doc the map missed).

2. **Mis-versioning seed is deeper than the docs.** The §1.4 scan shows
   v11.1 strings in `scripts/`, `validate-pack.py`, `scripts/tests/`, and
   the trinity — not just the BD-185 docs. Risk: a docs-only investigation
   would miss code/test/CI instances. Containment: R5 (source) + R6
   (tests) + R1 (CI workflow + trinity) own these surfaces with the
   mandatory `version` lens (QG-4). This is why segmentation spans code +
   tests + config, not just maintenance-docs.

3. **ENCODING-surface lock-step gaps.** Risk: a fix to a source surface
   (R5/A5) lands without the matching test/validator/CI/doc update (the
   BD-193/BD-194 incident class in CLAUDE.md). Containment: Lens E +
   QG-2's R5↔R6 cross-reference table + the architect `Blast radius`
   field + QG-7's working-state proof.

4. **Stale references after the prison move.** Risk: moving superseded
   docs into the prison (Step 2) breaks inbound references from in-scope
   docs/scripts to the moved files. Containment: Lens C (xref integrity)
   runs across all in-scope segments AFTER Step 2, so any reference into
   the prison is surfaced as a `stale-ref` finding; the architect side
   designs the re-point or removal.

5. **Trinity / quad CI breakage.** Risk: a fix touches one CLI variant of
   a trinity/quad and not the others, failing parity checks. Containment:
   Lens D + QG-2 parity matrices in R1/R2/R3/R4 + the architect blast-
   radius mirror obligation. CLAUDE.md trinity rule is a hard design
   constraint on every A-segment.

6. **`test-fixtures/manifest.txt` drift / CI fixture gate.** Risk: a
   v11-surface fix in Step 7 lands without regenerating the manifest
   (CLAUDE.md manifest rule; prior `667d2dd`/`4120d19` incidents).
   Containment: QG-7 makes the manifest-regen obligation part of the
   architect blast-radius union, so the Step-6 planner inherits it.

7. **Migration-regression risk.** Risk: a fix to migrator code/docs (R5
   `migrate-v10-to-v11.sh`, `lib/migrator-*`, `lib/migrate-v10-to-v11/`,
   supporting-docs MIGRATION guide) regresses the v10→v11 path or the
   BD-119 framework. Containment: R5/R6 own these with behavioral-
   correctness questions; the architect side carries the BD-119 "do not
   copy-and-rewrite the framework" constraint (CLAUDE.md).

8. **Archive over-editing.** Risk: R9/A9 rewrite frozen history to match
   current design. Containment: the §2.6 archive rule (flag active stale
   pointers + misleading versioning only; narrowest edits; user-gated).

9. **Reconciliation explosion / un-mergeable segments.** Risk: segments
   produce non-uniform outputs that the reconciliation cannot merge
   cleanly. Containment: QG-3/QG-8 (single template + vocabulary) and the
   `Cross-segment touch points` / `Blast radius` hooks (§3.2). Residual
   risk scales with finding volume; the de-dup + theme-grouping procedure
   (§5.1) is the mitigation.

10. **Scope-keyword / commit-discipline at Step 7.** Risk: a cross-
    surface fix commit mis-claims a `pack-only`/`project-only` scope
    keyword and fails CI Check 36. Containment: noted for the Step-6
    planner; the architect blast-radius reveals cross-surface fixes so
    the planner can split commits or use neutral framing (CLAUDE.md
    Check-36 convention). Out of scope for THIS plan to resolve.

### Genuinely-unanswerable items for the user (not state-verifiable)

These are intent/judgment calls that this read-only planning pass cannot
and should not pre-decide; they surface for the user at the noted gate:

- **MAINTAINER DECISION (Step 1):** which BD-185-attempt decisions are
  "preapproved good" and retained. Intent-dependent; user confirms.
- **MAINTAINER DECISION (Step 2):** the prison directory PATH/NAME and
  the exact membership set. Judgment + intent; user-confirmed move.
- **MAINTAINER DECISION (Step 9):** whether prior BD-185 work-so-far is
  wiped or salvaged. Explicitly a Step-9 decision (bias: complete redo).
- **MAINTAINER DECISION (this plan):** segment GRANULARITY. This plan
  proposes 9 researcher + 9 architect segments balancing depth-bounded
  size (§2.1 principle 3) against orchestration overhead. The user may
  prefer fewer/larger or more/smaller segments; the shared standard
  (§3), reconciliation (§5), and gates (§6) hold at any granularity, so
  re-granulating is a low-cost change at this gate.
