# AUDIT-BD-195-R7-PREREAD.md

**What this pass is.** A SCOPED pre-read of the BD-195 / "Code Red 3"
contamination epicenter (the BD-185 attempt + Code Red 2 (BD-193 / BD-194) +
the v11.1-mislabeled groupings/archive docs). It produces (a) retained-decision
LEADS so the parent can cross-check the Step-1 retained-decisions extraction,
and (b) epicenter CONTEXT for a later whole-repo supersession map. It does NOT
decide prison membership and is NOT the full R7 deep audit. Read-only pass;
prison directory does not yet exist; all sources read in place.

**Pass:** R7 scoped pre-read (parallel with Step-1 extractor + supersession map).
**Author:** pack-docs-researcher.
**Repo HEAD at read time:** `8ebf8f871dbd9c0fdfc0020db1149baab2a87774`.
**Branch:** v11-dev.
**CATEGORICAL FACT applied (not re-litigated):** v11.0 is UNRELEASED (no tag,
never frozen). Phase-parts was ALWAYS v11.0 scope, never v11.1. Any doc/claim
labeling phase-parts (or other in-flight v11.0 work) "v11.1", or asserting v11.0
content was "frozen", is categorically WRONG and is itself a contamination
signal — noted where seen.

---

## §1 — Coverage attestation

Every epicenter doc below was read in place at HEAD `8ebf8f8`. Items marked
(full) were read end-to-end; (sampled) were read at header + all
version-scope / approval / supersession grep-hits + the cited sections.

**The 5 untracked V2 docs (per Step-1 task body):**

| Doc | Read |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` | full |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` | full (§0–§2; sampled §3–§11) |
| `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md` | full (§0; sampled rest) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md` | sampled (header + §1–§3 D1) |
| `maintenance-docs/v11-research/RESEARCH-BD-185-ORDERING-API.md` | sampled (header + RG-1 §1–§3) |

**Committed BD-185-attempt docs (the contamination sources V2 supersedes):**

| Doc | Read |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` (original) | sampled (header §1–§1.2) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md` | sampled (header §1) |

**BD-194 corpus:**

| Doc | Read |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` | sampled (header + §1) |
| `maintenance-docs/v11-implementation/PLAN-BD-194.md` | sampled (header + grep) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-194.md` | sampled (header + grep) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md` | sampled (header + grep) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-FOLLOWUP.md` | sampled (header + grep) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` | sampled (header + grep) |

**BD-193 corpus:**

| Doc | Read |
|---|---|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md` | sampled (header + §1–§2) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` | sampled (header + §4 S-1/S-2 + grep) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md` | sampled (header + §3.1.2/§4.7 + grep) |

**Queued prompt:**

| Doc | Read |
|---|---|
| `maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md` | full |

**Groupings docs + v11.1 SCHEMA:**

| Doc | Read |
|---|---|
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | sampled (header + §scope + grep) |
| `maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md` | sampled (header + grep) |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` | sampled (header + §1 + grep) |
| `maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md` | sampled (header + grep) |
| `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` | sampled (header + grep) |
| `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` | sampled (header + grep) |
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | full (§1–§3) + grep |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | full |
| `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | metadata only (existence + markers per BD-193 cite) |

**Corroborating non-epicenter files read for fact-checking (not in scope as
audit targets, read to verify the CATEGORICAL FACT):**
`pack-ops/BACKLOG.md` BD-185 + BD-186 entries (L1746–1832);
`maintenance-docs/v11-research/templates-archive/README.md` (append-only rule);
`maintenance-docs/v11-research/templates-archive/translations.yaml`;
`scripts/validate-pack.py` `check_template_archive_v11()` (archive-root path).

---

## §2 — Retained-decision leads

Pointers to preapproved / locked / user-resolved decisions visible in the
epicenter, so the parent can confirm the Step-1 extractor caught them all. Each
is a one-line decision + exact source path + quoted approval marker. I make NO
prison-membership call here — I only surface that the decision exists and is
marked retained.

> **Framing caveat for the parent (read before using these leads).** The
> epicenter contains TWO classes of "locked" markers: (a) decisions the V2
> corrected design explicitly KEEPS and re-justifies under the v11.0 premise
> (genuinely retained), and (b) decisions the prior corpus marked "USER-LOCKED"
> that V2 explicitly REJECTS as contamination (D16 "Convention Y / frozen",
> the "v11.1 cut", the "work-item bump"). A "USER-LOCKED" string in a prior doc
> is NOT proof the decision survives — V2 §11 CR-1/CR-2/CR-3 reject three of
> them. I flag the class on each lead.

### RESEARCHER FINDING (RDL-1): FIXED phase-part lifecycle semantics — RETAINED (class a)

- **Decision (1 line):** Phases begin with zero Parts; a too-big phase splits
  into two phases (never born-split); Parts are evolution-only via
  `pack phase split` / `pack tracker phase split`; no collapse, no delete, no
  empty Parts, no mid-life re-parenting; deferral is the only exit for an
  unused Part.
- **Source:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md`
  §2.A (L165–176), reaffirmed as challenge-record CR-6.
- **Quoted approval marker:** §2.A heading — *"Phase-part creation & usage
  semantics (FIXED — not challenged)"*; CR-6 (L988–990): *"kept verbatim (FIXED
  §2.A); these are user-approved lifecycle invariants."*
- **Cross-ref to prior corpus:** prior `ARCHITECTURE-BD-185.md` D2/D3/D4
  (collapse rejected / empty Parts forbidden / re-parenting forbidden).

### RESEARCHER FINDING (RDL-2): FIXED phase-part on-tracker GRAMMAR — RETAINED in substance, version-tag carve-out (class a, with one correction)

- **Decision (1 line):** The phase-part identifier scheme, body-marker trio,
  label family, restrictive 4-state taxonomy, body-section grammar, sub-issue
  hierarchy, and body-marker reservations are FIXED user-approved inputs and
  adopted verbatim in substance — EXCEPT the embedded `phase-part-v11.1` version
  tag, which is contamination and corrects to `phase-part-v11.0`.
- **Source:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md`
  §2.B (L178–206); the FIXED grammar lives at
  `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`.
- **Quoted approval marker:** §2.B heading — *"Phase-part on-tracker GRAMMAR
  (FIXED — adopted verbatim in substance)"*; carve-out (L201–206): *"VERSION-TAG
  CARVE-OUT (the ONE thing in the SCHEMA that is NOT fixed)… part of the v11.1
  contamination, not the approved grammar."*
- **Lead for Step-1 extractor:** the GRAMMAR is retained; the SCHEMA's own
  `phase-part-v11.1` tag is NOT (it is a correction target). Confirm the
  extractor records BOTH halves.

### RESEARCHER FINDING (RDL-3): OQ-A1 implement-vs-stub boundary — USER-RESOLVED (class a)

- **Decision (1 line):** Issue-Fields LAYER-3 call shapes ship as DOCUMENTED
  STUBS (typed-TODOs carrying the RG-1 verified shapes); the abstract ordering
  ops + capability×availability selector + 4-condition gate + universal
  sub-issue-reprioritize floor + all seven consumers + migration writes are
  FULLY IMPLEMENTED + TESTED. (The "middle path" / K2-stub posture.)
- **Source:** `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md` §0.3
  (L53–76) and SZ-2 (L83); resolves addendum §11 OQ-A1.
- **Quoted approval marker:** §0.3 (L55–56): *"Per the user decision recorded in
  the addendum §11 OQ-A1 (resolved to the middle path)"*; SZ-2 (L83): *"The user
  resolved OQ-A1 to the middle path (§0.3)."*

### RESEARCHER FINDING (RDL-4): Issue Fields DEMOTED + GATED OFF — USER-DECISION revising prior user-locked C-2 (class a; supersedes a prior lock)

- **Decision (1 line):** GitHub Issue Fields `number` ordering is DEMOTED from
  GitHub first-choice to a fully-designed, gated-OFF-by-default v11.0 strategy;
  the universal sub-issue-reprioritize-against-order-root floor becomes the
  v11.0 GitHub DEFAULT.
- **Source:**
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`
  A-2 (L129–142), supersession table §0.1 (L30–34).
- **Quoted approval marker:** A-2 (L139–142): *"This revises the original
  user-locked C-2 ('Issue Fields is the v11.0 first-choice') per the explicit
  USER DECISION recorded in this addendum's driving inputs: Issue Fields is KEPT
  in the design but DEMOTED + GATED."*
- **Lead for Step-1 extractor:** this is a case where a PRIOR user-locked
  decision (C-2) was SUPERSEDED by a later user decision. The extractor should
  record the LIVE decision (demoted+gated), not the prior C-2 lock. Flag any
  extraction that still carries "Issue Fields first-choice" as the live state.

### RESEARCHER FINDING (RDL-5): BD-185 sequencing + scope — USER-APPROVED (class a; pack-only BD)

- **Decision (1 line):** BD-185 is Batch 19d, immediately after Batch 19c
  (BD-173); phase-parts + tracker-mode execution ordering land in v11.0; the
  only legitimate v11.1 reference is GH Projects integration (Out of scope).
- **Source:** `pack-ops/BACKLOG.md` BD-185 entry L1747 (Type line), L1780 (SC8),
  L1782–1783 (Out of scope), L1792 (Position).
- **Quoted approval marker:** L1747: *"user-approved as Batch 19d (immediately
  after Batch 19c) 2026-05-21"*; L1783: *"GH Projects integration (v11.1 scope…)"*;
  L1780 (SC8): *"any v11.0 forward-migration (flat-file → tracker mode)…"*
- **Why this is the load-bearing CATEGORICAL-FACT anchor:** BD-185's OWN entry
  scopes phase-parts to v11.0 (SC8) and names GH Projects as the ONLY v11.1
  item. Any phase-parts "v11.1" label contradicts the BD entry itself.

### RESEARCHER FINDING (RDL-6): Groupings → v11.1+ deferral — USER-AUTHORIZED (class a; LEGITIMATE v11.1, distinct from the phase-parts mislabel)

- **Decision (1 line):** All 17 groupings capabilities (BD-186) defer to v11.1+
  implementation; v11.0 ships without groupings; v11.0→v11.1 groupings migration
  must be fully architected/planned/implemented as v11.1 work (not ad-hoc copies).
- **Source:** `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md`
  L22, L24; corroborated by `pack-ops/BACKLOG.md` BD-186 (L1797, Resolved) and
  BD-185 Out-of-scope L1783.
- **Quoted approval marker:** REQUIREMENTS L24: *"User authorized the v11.1+
  deferral 2026-05-23 with the constraint that v11.0 → v11.1 migration must be
  fully architected, planned, and implemented as part of v11.1 work."*
- **CRITICAL distinction (apply the CATEGORICAL FACT carefully here):** the
  groupings v11.1 framing is CORRECT and user-authorized — groupings is the
  GH-Projects-adjacent feature that BD-185 itself defers (L1783). This is NOT
  the phase-parts mislabel. Do NOT let a blanket "v11.1 == contamination" sweep
  flag the groupings docs' v11.1 framing. See §3 entries for groupings docs.

### RESEARCHER FINDING (RDL-7): Groupings design principles + locked constraints — USER-LOCKED (class a)

- **Decision (1 line):** 5 core design principles + C6 external-tool
  accommodation + C7 graceful tracker degradation + the `GRP-NNN.md` filename
  convention are AUTHORITATIVE for the v11.1+ groupings architect pass.
- **Source:** `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md`
  §design-principles (L41+), §constraints (L67+);
  `maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md` L143.
- **Quoted approval marker:** REQUIREMENTS L41: *"They are AUTHORITATIVE for the
  v11.1 architect pass — the architect MUST respect them"*; INTAKE L143:
  *"Filename convention locked: `GRP-NNN.md`."*
- **Cross-ref:** matches pack memory `feedback_groupings_design_principles`.

### RESEARCHER FINDING (RDL-8): Groupings amendments §5.1 / §5.3 / §5.4 / §5.6 + Goal 18 — USER-APPROVED 2026-05-24 (class a; preliminary-status disclaimer)

- **Decision (1 line):** A set of groupings/PS amendments (cycle-detection
  SC13.22, mvp_priority REJECT, Goal 18 PS-to-pack-entry-type boundary
  principle) landed user-approved 2026-05-24 under a "preliminary; subject to
  architect challenge at v11.1+ groupings design pass" disclaimer.
- **Source:**
  `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md`
  L10, L35;
  `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md`
  L10, L41.
- **Quoted approval marker:** AMENDMENT-5-1 L10: *"User approval: 2026-05-24
  (amendment landed in v11.1+ scope; no v11.0 deferral)"*; PS-BATCH-2 L10:
  *"User approval: 2026-05-24 (settled positions from multi-day BD-191 sidecar
  triage…)."*
- **Lead for Step-1 extractor:** these are PRELIMINARY (architect-challengeable),
  not fully locked — confirm the extractor records them with the preliminary
  qualifier, not as hard locks.

### RESEARCHER FINDING (RDL-9): BD-194 Check 24 retirement (byte-identity → separate-artifact) — USER-PIPELINE-APPROVED (class a; COMPLETED work)

- **Decision (1 line):** Check 24 (`check_help_fragment_tracker_byte_identity`)
  is retired/replaced because byte-identity contradicts the user-locked
  pack/project separation-of-concerns rule; the two HELP-FRAGMENT-TRACKER files
  are SEPARATE artifacts with SEPARATE audiences.
- **Source:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md`
  §1.1–§1.2 (L23–51).
- **Quoted approval marker:** §1.2 anchor — *"`feedback_pack_project_separation_of_concerns`
  — pack-side and project-side versions of any doc/file are SEPARATE artifacts…
  User-locked 2026-05-26 during BD-185 Code Red 2."*
- **Note:** this is a COMPLETED, correct BD (Code Red 2). The retained decision
  is the separation-of-concerns rule it enforces.

### RESEARCHER FINDING (RDL-10): BD-193 per-surface wi-type + D16 carve-out dispositions — USER-LOCKED / USER-RESOLVED (class a substance; class b version-framing)

- **Decision (1 line):** BD-193 locked 11 dispositions (F1–F5) including the
  pack-root `{bd}`-only / project-template-no-`bd` per-surface wi-type split and
  the removal of the stray `bd` option from the archived v11.0 form ("D16
  bug-fix carve-out").
- **Source:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
  §1 (L30–54);
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md`
  S-2 (L174–182).
- **Quoted approval marker:** IMPL-BD-193 L30: *"11 LOCKED dispositions (§3 of
  disposition report, user-pre-locked)."*
- **MIXED-CLASS WARNING:** the per-surface wi-type SUBSTANCE is retained
  (class a). But BD-193 Phase-5 S-2 framed the archived-form carve-out as a
  "D16 carve-out" — and V2 §3 D-3 / §11 CR-1 REJECT the broader D16 "frozen"
  premise while KEEPING the BD-193 carve-out FACT. The extractor should record:
  carve-out fact = retained; "D16 / Convention Y / frozen" framing = rejected.

---

## §3 — Epicenter context (one entry per doc)

For each doc: what it is; what it claims to supersede or be superseded by
(factual, quoting any in-doc "supersedes"/"superseded by" note); any
version-mislabel or boundary-leak signal. I do NOT rank or decide prison
membership — I report what the text says, for the later whole-repo supersession
map to use.

### The 2 prior BD-185 architecture docs (CONTAMINATION SOURCES — explicitly superseded by V2)

#### `ARCHITECTURE-BD-185.md` (original, 2026-05-25)

- **What it is:** The original BD-185 architect design (per its header,
  1233 lines, 16 USER-LOCKED decisions D1-D16; D15+D16 locked 2026-05-26).
- **Superseded by (in-doc note in the SUPERSEDING doc):**
  `ARCHITECTURE-BD-185-V2.md` §0 (L13): *"This document SUPERSEDES both prior
  BD-185 architect docs in their entirety: `ARCHITECTURE-BD-185.md` (original)…"*
- **Contamination signal (CATEGORICAL FACT):** this doc is the ROOT of the
  v11.1 mis-versioning. Per V2 §0 (L20–22): *"Both prior docs carry one
  categorical error: they treated v11.0 as a closed/shipped version and routed
  all phase-parts work into a nonexistent 'v11.1 archive cut.'"* Its D16
  ("Convention Y: v11.0 structural shape frozen; USER-LOCKED 2026-05-26") is the
  premise V2 CR-1 rejects. CONTAMINATED.

#### `ARCHITECTURE-BD-185-RECONCILIATION.md` (2026-05-27)

- **What it is (per header):** A post-Code-Red-2 re-validation of
  `ARCHITECTURE-BD-185.md` (D1-D16) + `PLAN-BD-185.md` (H.1-H.16) against the
  new BD-193/BD-194 baseline; pipeline position "→ user review → planner
  addendum → H.2 coder spawn."
- **Superseded by:** `ARCHITECTURE-BD-185-V2.md` §0 (L14): *"…and
  `ARCHITECTURE-BD-185-RECONCILIATION.md`."*
- **Contamination signal:** per V2 §11 CR-1 (L962–964): *"The prior
  RECONCILIATION graded D16 NEEDS-ADJUSTMENT but patched the symptom (added a
  'Class B carve-out' exception) instead of rejecting the premise — a
  missed-finding the new pass corrects at root."* It also carried a STALE
  pack-root form premise (V2 CR-5, L980–987): it treated pack-root as a
  4-option form and prescribed extending to 5, which post-BD-194 `{bd}`-only is
  WRONG (a deliverable-only-rule regression risk). CONTAMINATED (kept the v11.1
  framing + stale pack-root premise).

### The 5 untracked V2 docs (CORRECTED design — these CORRECT the contamination)

#### `ARCHITECTURE-BD-185-V2.md`

- **What it is:** The corrected, standalone, self-contained BD-185 architecture
  landing phase-parts in v11.0. Header: *"Status: Authoritative. Standalone.
  Self-contained."* Carries the full decision log (§3 D-1..D-N), challenge
  record (§11 CR-1..CR-16), and contamination-correction enumeration (§10
  Groups A–H).
- **Supersedes (in-doc):** §0 (L11–14) — *"This document SUPERSEDES both prior
  BD-185 architect docs in their entirety."*
- **Superseded by (in-doc):**
  `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0.1 supersedes V2's ordering
  subsystem ONLY (V2 §5.1/§5.2, D-7 mechanism clause, D-8, §7 ordering ops,
  §6 ordering reads/writes); V2 wins for everything else.
- **Version/boundary signal:** This doc APPLIES the CATEGORICAL FACT correctly —
  it is the de-contamination authority, not a contamination instance. It quotes
  the README append-only rule and translations.yaml to prove v11.0 is unfrozen
  (§0, L31–35). One precision concern I flag (see §4 OQ-R7-1): its §10 cites
  archive paths as bare `templates-archive/v11.0/...` while the archive ACTUALLY
  lives at `maintenance-docs/v11-research/templates-archive/v11.0/...`.

#### `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`

- **What it is:** A targeted addendum that supersedes exactly ONE subsystem of
  V2 — the tracker-mode execution-ordering MECHANISM — and leaves all else
  intact. Introduces capability×availability mechanism selection (A-1..A-N),
  demotes Issue Fields to gated-OFF (A-2), promotes sub-issue-reprioritize floor
  to GitHub default (A-3).
- **Supersedes (in-doc):** §0.1 table (L28–35) — itemizes the V2 ordering
  content it replaces; *"V2 remains authoritative for everything else."*
- **Superseded by:** nothing (it is the live ordering authority).
- **Version/boundary signal:** clean — explicitly v11.0 in title; consumes
  `RESEARCH-BD-185-ORDERING-API.md` RG-1/RG-2 resolved facts. No mislabel.

#### `PLAN-BD-185-V2.md`

- **What it is:** Commit-sequenced implementation plan (12 commits: A=2, B=4,
  C=6) for the corrected BD-185. Header: *"Authoritative. Standalone. Supersedes
  the two prior plan docs in full."*
- **Supersedes (in-doc):** §0 (L14–17) — *"This plan SUPERSEDES both prior
  BD-185 plan docs in their entirety: `PLAN-BD-185.md`, `PLAN-BD-185-ADDENDUM.md`.
  Neither was read during this planning pass (they carry the same categorical
  'v11.1' mis-versioning…)."*
- **Superseded by:** nothing.
- **Version/boundary signal:** clean + ACTIVELY GUARDS the CATEGORICAL FACT.
  §0.2 (L42–51) is a binding "contamination guardrail": *"If any commit in this
  plan produces a v11.1 tag, label, marker, directory, or 'bump' for a
  phase-parts/ordering artifact, that is the contamination — STOP."* Names the
  SCHEMA correction `phase-part-v11.1` → `phase-part-v11.0`.

#### `PACK-REVIEW-BD-185-H.2.md`

- **What it is:** An INLINE per-BD reviewer audit of the H.2 form-family
  extension (project-template-only), landed at HEAD `e580dda`, verdicts
  CONFIRMED-CORRECT for the boundary discipline.
- **Supersedes / superseded by:** no in-doc supersession note.
- **Version/boundary signal:** It reviews H.2 AGAINST `PLAN-BD-185-ADDENDUM.md`
  §4.2 as the spec (header L6–7) — i.e., it was authored under the OLD
  (contaminated) plan corpus, BEFORE the V2 correction. The H.2 FUNCTIONAL
  substance it confirms (pack-root `{bd}`-only, `work-item-v11.0` markers,
  DISJOINT invariant) matches what V2 §2.C verifies as already-correct, so the
  review's verdicts are not themselves wrong — but it is anchored to a
  superseded plan. NOTE: this file is UNTRACKED (`git status` shows `??`), so a
  separate same-named tracked file may exist in history; the parent should
  confirm which copy is authoritative. POTENTIAL STALE-ANCHOR (references the
  superseded ADDENDUM plan).

#### `RESEARCH-BD-185-ORDERING-API.md`

- **What it is:** Primary-GitHub-docs research closing RG-1 (Issue Fields
  `number`) + RG-2 (sub-issue reprioritize). Both RESOLVED; two named residuals
  (RG-1 §8 GraphQL preview header PARTIAL; 100-children cap documented outside
  REST reference).
- **Supersedes (in-doc):** corrects the snippet-sourced §4.2 of
  `TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` (header inputs note: leads
  "CONFIRMED or SUPERSEDED below").
- **Superseded by:** nothing.
- **Version/boundary signal:** clean. Facts-only; no version label issue. Read
  as the trusted external fact base by the ordering addendum.

### The BD-194 corpus (Code Red 2 — COMPLETED, correct; not contaminated)

#### `ARCHITECTURE-BD-194.md`

- **What it is:** Architect design for retiring/replacing validate-pack Check 24
  (byte-identity gate on the two HELP-FRAGMENT-TRACKER files) because
  byte-identity contradicts the separation-of-concerns rule.
- **Supersedes / superseded by:** no in-doc note; it is a discrete BD design.
- **Version/boundary signal:** clean. Explicit P-missed-7 boundary discipline
  (§1.4). No v11.1 mislabel.

#### `PLAN-BD-194.md`, `PACK-REVIEW-BD-194.md`, `IMPLEMENTATION-REPORT-BD-194.md`, `-FOLLOWUP.md`, `-STALE-REFS.md`

- **What they are:** The BD-194 planner/reviewer/coder pipeline + two small
  follow-on coder reports (3 reviewer findings; stale Check-24 reference fix).
  All workflow artifacts of a COMPLETED BD.
- **Supersedes / superseded by:** none (sequential pipeline; the FOLLOWUP +
  STALE-REFS bundle INTO the BD-194 commit, not supersede it — per their
  headers).
- **Version/boundary signal:** The only "v11.1" hits are in `PACK-REVIEW-BD-194.md`
  L970 + L1035, and they are CORRECT applications of the CATEGORICAL FACT, not
  mislabels: L1035 — *"land in v11.0; do not defer to v11.1 without explicit
  user authorization."* The "superseded" hits in `IMPLEMENTATION-REPORT-BD-194.md`
  (L124/604/705) refer to the RETIRED Check 24 / BD-082 DELTA byte-identity
  invariant being superseded by BD-194 — internal to the BD's own work, not a
  doc-level supersession. Clean.

### The BD-193 corpus (Code Red 2 — COMPLETED, BUT propagated the v11.1 mislabel)

#### `IMPLEMENTATION-REPORT-BD-193.md`

- **What it is:** Phase-3 coder report applying the Code Red 2 BD/TD/Path scope
  contamination cleanup (11 LOCKED dispositions + 3 LEAK fixes + ~85 WASTE fixes).
- **Supersedes / superseded by:** none.
- **Version/boundary signal:** Out-of-scope note (L58–60) explicitly leaves
  "POQ-4 reversal in `ARCHITECTURE-BD-185.md` and `PLAN-BD-185.md`" untouched —
  i.e., BD-193 KNEW the BD-185 corpus had pending corrections but did not touch
  the v11.1 framing. Clean as a Code-Red-2 cleanup; did not address the v11.1
  mislabel (out of its scope).

#### `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` — KEY PROPAGATION SIGNAL

- **What it is:** Phase-5 remediation of Phase-4 audit findings. It EDITED the
  v11.1 archive docs (file row 9: `templates-archive/v11.1/INDEX.md`; row 14:
  `…/v11.1/phase-part-v11.1/SCHEMA.md`).
- **Supersedes / superseded by:** none.
- **Version/boundary signal — CONTAMINATION PROPAGATION (CATEGORICAL FACT):**
  its §4 S-1 (L141–172) REWROTE the v11.1 INDEX forms paragraph to ACTIVELY
  REINFORCE the wrong framing — *"Not yet created. The v11.1 forms/ subdirectory
  will be populated when the v11.1 archive cut is completed (architect-pass
  decision pending)."* That is, BD-193 Phase-5 treated the nonexistent "v11.1
  archive cut" as a legitimate future deliverable. Per the CATEGORICAL FACT this
  is WRONG (phase-parts is v11.0; there is no v11.1 cut). This is a doc that
  EDITED a contaminated surface and deepened the contamination. SIGNAL for the
  supersession map: the edits this report records are now themselves correction
  targets per V2 §10 Group B.

#### `PACK-REVIEW-BD-193-PHASE-4.md` — KEY PROPAGATION SIGNAL

- **What it is:** Phase-4 extensive post-implementation audit of the BD-193
  cleanup.
- **Supersedes / superseded by:** none.
- **Version/boundary signal — CONTAMINATION PROPAGATION:** §3.1.2 (L93–97)
  graded the v11.1 INDEX heading *"## Entry types at v11.1"* and the
  *"new phase-part-v11.1"* row as **CONFIRMED-CORRECT** — i.e., the reviewer
  BLESSED the v11.1 mislabel. §4.7 M-5 (L559–592) correctly caught a stale
  byte-identity claim but recommended remediation option (a) *"actually create
  the v11.1 archive forms directory + form file (a v11.1 archive cut decision
  the user makes)"* — again treating the v11.1 cut as legitimate. Per the
  CATEGORICAL FACT, both are WRONG. This review propagated rather than caught the
  v11.1 contamination.

### The queued prompt

#### `BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md`

- **What it is:** A QUEUED (not-yet-fired) docs-researcher prompt persisted
  2026-05-21, fire condition "Batch 19c closes + user approval." It targets the
  TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING fact base (which DID get produced).
- **Supersedes / superseded by:** no in-doc note. It is the prompt that produced
  the inventory the V2 design consumed.
- **Version/boundary signal:** clean. No v11.1 mislabel; states the BD-185
  problems P1–P4 in plain v11.0 terms. Process-historical artifact. (It is now
  effectively SPENT — the inventory it queued was produced and consumed — but it
  carries no contamination.)

### The groupings docs (LEGITIMATE v11.1+ deferral — NOT the phase-parts mislabel)

> **Blanket caution for the supersession map.** Every groupings doc below is
> framed "v11.1+" and that framing is CORRECT and user-authorized (RDL-6). A
> naive "v11.1 == contamination" scan WILL false-positive on all of these. The
> distinguishing test: groupings (BD-186) IS the GH-Projects-adjacent feature
> that BD-185's own Out-of-scope line (BACKLOG L1783) defers to v11.1. Phase-
> parts is NOT — it is v11.0 per BD-185 SC8.

#### `REQUIREMENTS-GROUPINGS-V11.md`

- **What it is:** The single requirements artifact for groupings (BD-186); 17
  capabilities with problem/goal/SC + user-approved design decisions; canonical
  input for the v11.1 groupings architect pass.
- **Supersedes / superseded by:** no in-doc note (it is a primary input;
  INTAKE-GROUPINGS-V11.md L25 declares REQUIREMENTS wins on conflict).
- **Version signal:** "v11.1+" framing is CORRECT (L22: *"All 17 capabilities
  defer to v11.1+ implementation. v11.0 ships the existing scope… without
  groupings"*). NOT contamination.

#### `INTAKE-GROUPINGS-V11.md`

- **What it is:** Retroactive intake doc (2026-05-24) capturing the user-intent
  discussion behind BD-186. Self-declares *"FAITHFUL SUMMARY — NOT VERBATIM"*
  and *"User should review for accuracy before treating as audit-grade record."*
- **Supersedes / superseded by:** INTAKE is subordinate to REQUIREMENTS (L25:
  *"If this intake doc conflicts with REQUIREMENTS-GROUPINGS-V11.md, the
  REQUIREMENTS doc wins."*).
- **Version signal:** "v11.0/v11.1 scope decision" framing CORRECT. NOT
  contamination. (Minor: self-flagged not-yet-verified fidelity — a quality note,
  not a version mislabel.)

#### `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`

- **What it is:** Read-only constraint enumeration (2026-05-21) of current v11
  design + external tracker capabilities for the groupings feature; sourced from
  `main:…V11.1-DISCUSSION-GITHUB-PROJECTS.md`.
- **Supersedes / superseded by:** `RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`
  header states it *"supersedes/extends"* this doc's §2 baseline (factual
  in-doc note in the OTHER doc).
- **Version signal:** Its C7 row (L78) correctly states *"groupings layer in
  v11.1+ as overlay"* — CORRECT framing. L905 also correctly records *"BD-185
  must precede groupings work"* and that the grouping grammar "must accept
  whatever BD-185 produces" — consistent with the CATEGORICAL FACT. NOT
  contamination. (Note: this is the file listed in the untracked git status as a
  V2 doc; it is the groupings touch-point inventory, distinct from the BD-185 V2
  architecture docs.)

#### `RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`

- **What it is:** Per-backend (6 + extended tiers) tracker-primitive research for
  the v11.1+ groupings architect.
- **Supersedes / superseded by:** header — *"TOUCH-POINT-INVENTORY-GROUPINGS-V2.md
  §2 (2026-05-21 baseline; this doc supersedes/extends)."*
- **Version signal:** "v11.1+" framing CORRECT throughout. NOT contamination.

#### `IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` and `IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md`

- **What they are:** Coder reports applying user-approved (2026-05-24) groupings
  + PS amendments to REQUIREMENTS-GROUPINGS-V11.md + HANDOFF-V11.1-ARCHITECT.md
  (cycle-detection SC13.22, mvp_priority REJECT, Goal 18).
- **Supersedes / superseded by:** none.
- **Version signal:** "v11.1+ scope" framing CORRECT; amendments carry the
  explicit *"Preliminary; subject to architect challenge at v11.1+ groupings
  design pass"* disclaimer (PS-BATCH-2 L41). NOT contamination.

### The v11.1 archive artifacts (THE PHYSICAL CONTAMINATION — correction targets per V2 §10)

#### `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`
(actual path: `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`)

- **What it is:** The phase-part on-tracker grammar schema (identifier scheme,
  marker trio, label family, 4-state taxonomy, body-section grammar, sub-issue
  hierarchy). The GRAMMAR SUBSTANCE is user-approved + retained (RDL-2).
- **Supersedes / superseded by:** no in-doc note.
- **Version signal — PHYSICAL CONTAMINATION (CATEGORICAL FACT):** the version
  tag is `phase-part-v11.1` throughout — title L1 *"Schema — `phase-part-v11.1`"*,
  §2 marker L43 *"template_version: phase-part-v11.1"* (+ L117), §3 label
  *"template:phase-part-v11.1"* (L69), prose L4/L49/L63/L187/L217. Per the
  CATEGORICAL FACT and V2 §2.B carve-out + §10 Group A, every `v11.1` here is
  WRONG and corrects to `phase-part-v11.0`. The grammar stays; the version label
  moves. PHYSICAL CONTAMINATION (version-tag only; grammar correct).

#### `templates-archive/v11.1/INDEX.md`
(actual path: `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`)

- **What it is:** The "Template archive — v11.1" index claiming a v11.1 archive
  cut with phase-part as the "6th entry type, NEW in v11.1."
- **Supersedes / superseded by:** no in-doc note; V2 §10 Group B retires it
  (folds into the v11.0 INDEX).
- **Version signal — DENSE CONTAMINATION (CATEGORICAL FACT, multiple):**
  - L7: *"The v11.1 archive cut introduces multi-part phase mid-work
    expansion…"* — there is NO v11.1 cut (V2 CR-2). WRONG.
  - L21: *"Phase part… NEW in v11.1"* with `phase-part-v11.1` marker + label —
    WRONG (RDL-2).
  - L32–35: *"The v11.0 archive remains structurally frozen at 5 entry-type
    subdirs… per Convention Y (v11.0 structural shape freeze; USER-LOCKED
    2026-05-26)."* — the "frozen" assertion is categorically WRONG (v11.0 is
    untagged; V2 CR-1). The "USER-LOCKED" marker here is the prior lock V2
    explicitly REJECTS — a class-(b) lock (see §2 framing caveat).
  - L47–49: claims Convention Y is "exercised twice," incl. a
    `status:cancelled` extension — V2 §11 gap-1 (L1022–1024) + CR-15 find this
    FICTIONAL (the SCHEMA never got `cancelled`).
  - L89–93: *"only `work-item-v11.0` bumps to `work-item-v11.1`"* — the bump
    never happened (V2 CR-3); the contaminated form snapshot's own markers read
    `work-item-v11.0`, contradicting the bump claim (V2 §2.C fact 2).
  - L95–107: a D1–D16 decision-log cross-reference block carrying the rejected
    D16 "Convention Y frozen" entry.
  - DENSE PHYSICAL CONTAMINATION (the single most contaminated artifact in the
    epicenter).

#### `templates-archive/v11.1/forms/work-item.yml`
(actual path: `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`)

- **What it is:** A duplicate work-item form snapshot under the v11.1 cut.
- **Version signal:** per V2 §2.C fact 2 (L234–238) it INTERNALLY contradicts
  the INDEX — it carries `template:work-item-v11.0` (L7) + body marker
  `work-item-v11.0` (L186) while the v11.1 INDEX claims a `work-item-v11.1`
  bump. V2 §10 Group C retires this duplicate (the single correct v11.0 archive
  form already exists). PHYSICAL CONTAMINATION (the dir placement is wrong; the
  internal markers are accidentally correct).

---

## §4 — Open questions for the user

These are MY findings + recommendations (labeled). The user decides; I do not
assume acceptance. Several go beyond the items the prompt named (proactive
breadth).

### RESEARCHER FINDING (OQ-R7-1): the templates-archive is NOT at repo root — it lives nested under `maintenance-docs/v11-research/`, and V2 §10 cites bare `templates-archive/...` paths that omit this prefix

- **What I found:** There is NO repo-root `templates-archive/` (`ls templates-archive`
  → does not exist; `find` confirms the ONLY `templates-archive` dir is
  `maintenance-docs/v11-research/templates-archive/`, git-tracked). Yet the V2
  architecture's §10 contamination-correction enumeration cites correction
  targets as e.g. *"From: `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`
  To: `templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`"*
  (`ARCHITECTURE-BD-185-V2.md` L840–841) — dropping the
  `maintenance-docs/v11-research/` prefix. V2 §0 quotes are accurate
  (`templates-archive/README.md` and `translations.yaml` text both verified),
  but the §10 path citations are bare.
- **Why it matters:** A coder executing the V2 §10 corrections against a
  literal `templates-archive/v11.0/...` path would fail (no such dir at root).
  The validator already encodes the REAL path:
  `scripts/validate-pack.py:1226` — `archive_root = REPO_ROOT / "maintenance-docs"
  / "v11-research" / "templates-archive" / "v11.0"`. So the archive is
  intentionally nested; the V2 doc's bare paths are a shorthand that loses the
  prefix. This collides with the pack memory **filename/path-precision** posture
  (prose references should resolve to a real path).
- **Possible deeper issue I cannot resolve here:** is the archive SUPPOSED to be
  at repo root (and is currently mis-located under `v11-research/`), or is the
  nested location correct and the V2 doc simply abbreviated? The validator
  treats nested as correct. Either way the V2 §10 paths are imprecise.
- **Recommended action:** Before any coder executes V2 §10, reconcile the path:
  confirm the canonical archive location (validator says nested under
  `maintenance-docs/v11-research/`) and either (a) annotate/correct V2 §10 to
  carry the full `maintenance-docs/v11-research/templates-archive/...` paths, or
  (b) if the archive is meant to move to repo root, raise that as a separate
  scoping decision. Do not let the bare paths reach a coder un-reconciled.

### RESEARCHER FINDING (OQ-R7-2): BD-193's review + remediation BLESSED and DEEPENED the v11.1 mislabel — these are correction targets, and they are a process-failure signal worth noting for the BD-195 recovery

- **What I found:** `PACK-REVIEW-BD-193-PHASE-4.md` §3.1.2 graded the v11.1
  INDEX framing **CONFIRMED-CORRECT**, and §4.7 M-5 recommended *"actually
  create the v11.1 archive forms directory"*; `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md`
  §4 S-1 then rewrote the v11.1 INDEX to say *"the v11.1 archive cut will be
  completed (architect-pass decision pending)."* Both treated the nonexistent
  v11.1 cut as a legitimate future deliverable.
- **Why it matters (CATEGORICAL FACT):** these passes had the opportunity to
  catch the v11.1 mis-versioning during Code Red 2 and instead propagated it.
  The edits Phase-5 S-1 made are now themselves correction targets under V2 §10
  Group B. For BD-195's "pristine v11.0 following Batch 19c" goal, this confirms
  the contamination was reinforced AFTER it was introduced.
- **Recommended action:** When the V2 §10 corrections land, ensure the specific
  Phase-5 S-1 INDEX language and the Phase-4 §3.1.2 "CONFIRMED-CORRECT" framing
  are explicitly reversed (not just edited around). Consider whether the BD-195
  recovery should record this as a missed-finding (analogous to V2 §11 gap-list)
  so the review process learns the v11.0/v11.1 categorical check.

### RESEARCHER FINDING (OQ-R7-3): the ENCODING surfaces for the v11.1 mislabel reach into `scripts/` (validator + test) and require lock-step de-contamination + a manifest regen

- **What I found:** V2 §10 Groups D + E + F name the encoding surfaces:
  `scripts/validate-pack.py` `check_issue_template_forms()` comments (L1086,
  L1121–1123) and `check_template_archive_v11()` loop (L1237, currently 5 entry
  types), and `scripts/tests/test-issue-forms.sh` comments (L18–19, L94–95,
  L138–142, L162–164, L180–183, L264–265) — all carry the *"added at v11.1
  (BD-185 H.2)"* framing. V2 §10 flags these as a LEAK (operational,
  test-encoded) per the pack memory `feedback_enumerate_encoding_surfaces_in_audits`.
- **Why it matters:** This is exactly the asymmetric-coverage gap the pack
  memory rule warns about — the test/validator COMMENTS encode the wrong version
  even though the functional assertions are correct. And because Groups D/E/F
  touch `scripts/`, those commits MUST regenerate `test-fixtures/manifest.txt`
  in the same commit (pack memory `feedback_manifest_regen_on_v11_surface`) —
  V2 §10 and §12 both flag this.
- **Recommended action:** Treat the validator + test comment de-contamination as
  in-scope for the BD-195 / V2 §10 correction (not optional cosmetic), and
  budget the manifest regen + per-check test runs (`test-issue-forms.sh`,
  `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-43.sh`) per
  the PREFLIGHT per-check-test-runs gate.

### RESEARCHER FINDING (OQ-R7-4): `PACK-REVIEW-BD-185-H.2.md` is UNTRACKED and anchored to the superseded `PLAN-BD-185-ADDENDUM.md`

- **What I found:** `git status` shows `PACK-REVIEW-BD-185-H.2.md` as untracked
  (`??`). Its header reviews H.2 against `PLAN-BD-185-ADDENDUM.md` §4.2 — a plan
  that `PLAN-BD-185-V2.md` §0 explicitly supersedes and declares contaminated
  ("not read… they carry the same categorical 'v11.1' mis-versioning").
- **Why it matters:** The review's verdicts are not wrong (the H.2 substance it
  confirms matches V2 §2.C), but it is anchored to a superseded spec, and being
  untracked means there is no committed provenance. For the supersession map,
  this is a STALE-ANCHOR doc that references the contaminated plan corpus.
- **Recommended action:** The parent should decide this doc's disposition during
  the supersession-map pass (it is the supersession-map pass's call, not mine).
  I flag only that it exists, is untracked, and points at a superseded plan.

### RESEARCHER FINDING (OQ-R7-5): do NOT let a blanket "v11.1 == contamination" sweep flag the groupings docs

- **What I found:** Six groupings docs + `HANDOFF-V11.1-ARCHITECT.md` +
  `V11.1-DISCUSSION-GITHUB-PROJECTS.md` are pervasively framed "v11.1+", and
  that framing is CORRECT and user-authorized (RDL-6; BD-185 Out-of-scope
  L1783 defers GH Projects to v11.1; BD-186 is that feature's requirements).
- **Why it matters:** The CATEGORICAL FACT applies to PHASE-PARTS (and other
  in-flight v11.0 work) wrongly labeled v11.1. It does NOT apply to groupings /
  GH Projects, which BD-185 itself legitimately defers. A mechanical
  version-string sweep would generate large-volume false positives across the
  groupings corpus.
- **Recommended action:** Scope any "v11.1 mislabel" correction strictly to
  phase-parts / ordering / archive artifacts (the §3 "physical contamination"
  set + the prior BD-185 corpus). Explicitly exclude the groupings corpus from
  the v11.1-mislabel correction. The distinguishing test is in this report's §3
  groupings caution box.

### RESEARCHER FINDING (OQ-R7-6): the prior BD-185 corpus carries MORE superseded docs than the two V2 names — the full superseded set should be enumerated by the supersession-map pass

- **What I found:** `find … -iname "*BD-185*"` returns a large prior corpus:
  `ARCHITECTURE-BD-185.md`, `ARCHITECTURE-BD-185-RECONCILIATION.md`,
  `PLAN-BD-185.md`, `PLAN-BD-185-ADDENDUM.md`, `PACK-REVIEW-BD-185-H.1.md`,
  `PACK-REVIEW-BD-185-H.2.md` (tracked variant — note a same-named UNTRACKED
  file also exists, OQ-R7-4), `IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`,
  `IMPLEMENTATION-REPORT-BD-185-H.1-NITS.md`,
  `IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md`,
  `IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md`,
  `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-REVIEW-FIXES.md`,
  `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md`. V2 §0 names only the 2
  architect docs + 2 plan docs as superseded "in their entirety"; the H.1/H.2
  review + IMPL reports are workflow artifacts V2 §10 Group H says sweep at
  version ship (Pattern B), keeping the historical record incl. the error.
- **Why it matters:** This R7 pass was SCOPED to the 5 untracked V2 docs + the
  BD-194/BD-193 corpus + groupings; the FULL prior BD-185 H.1/H.2 workflow
  corpus is in-territory for the whole-repo supersession map but I did not
  deep-read each. They almost certainly carry the same v11.1 framing.
- **Recommended action:** The whole-repo supersession-map pass should enumerate
  the FULL prior BD-185 corpus (12+ files above) and classify each
  (superseded-by-V2 vs historical-workflow-artifact). I flag the inventory so it
  is not missed; I do not classify them here (out of this scoped pass).

### RESEARCHER FINDING (OQ-R7-7): `INTAKE-GROUPINGS-V11.md` self-flags unverified fidelity

- **What I found:** `INTAKE-GROUPINGS-V11.md` header (L5) — *"FAITHFUL SUMMARY —
  NOT VERBATIM… User should review for accuracy before treating as audit-grade
  record."*
- **Why it matters:** It is a retroactive (2026-05-24, from chat memory)
  reconstruction subordinate to REQUIREMENTS-GROUPINGS-V11.md (it loses on
  conflict). Not a contamination, but a quality caveat the user may want to
  resolve before relying on it as audit-grade for the BD-195 recovery.
- **Recommended action:** Optional — user may review INTAKE for fidelity, or
  simply rely on REQUIREMENTS (the canonical artifact) and treat INTAKE as
  audit-trail only.

---

## §5 — Pass summary (non-authoritative orientation)

- **The de-contamination AUTHORITY already exists** in the working tree: the 5
  untracked V2 docs (chiefly `ARCHITECTURE-BD-185-V2.md` §0/§10/§11 +
  `PLAN-BD-185-V2.md` §0.2) correctly diagnose and enumerate the phase-parts
  v11.1 mislabel and its corrections. They APPLY the CATEGORICAL FACT.
- **The contamination SOURCES** are the two prior architect docs
  (`ARCHITECTURE-BD-185.md` D16, `ARCHITECTURE-BD-185-RECONCILIATION.md`) and the
  two prior plan docs, all explicitly superseded by V2.
- **The PHYSICAL contamination** is the `…/v11.1/` archive triplet (INDEX,
  phase-part SCHEMA, forms snapshot) — correction targets per V2 §10 Groups A–C.
- **The PROPAGATION** happened in BD-193 Phase-4 review + Phase-5 remediation,
  which blessed/deepened the v11.1 framing (OQ-R7-2).
- **The ENCODING surfaces** reach into `scripts/` (validator + test comments) —
  lock-step de-contamination + manifest regen required (OQ-R7-3).
- **The groupings corpus is CLEAN** — its v11.1+ framing is the legitimate
  GH-Projects deferral, not the phase-parts mislabel (OQ-R7-5).
- **Open path question:** the archive lives nested under
  `maintenance-docs/v11-research/`, not repo root, and V2 §10 cites bare paths —
  reconcile before any coder runs the §10 corrections (OQ-R7-1).
