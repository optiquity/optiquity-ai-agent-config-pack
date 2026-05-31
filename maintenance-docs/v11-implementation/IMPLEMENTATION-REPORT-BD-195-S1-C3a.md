# IMPLEMENTATION-REPORT-BD-195-S1-C3a.md — INFO-1 follow-up: 4 in-place correction notes (P-08 class)

**Authored by:** pack-coder (BD-195 S1·C3a — INFO-1 follow-up commit).
**Date:** 2026-05-31 (US/Pacific).
**Branch:** v11-dev.
**Worktree HEAD at start:** `0a05b29072dae2abf4f4517a2bbc07ad79967fa1`.
**Worktree HEAD at end:** `0a05b29072dae2abf4f4517a2bbc07ad79967fa1`
(no commits made — pack-coder produces working-tree edits only; Pack Chat
stages + commits per protocol).
**Input audit:** `maintenance-docs/v11-implementation/AUDIT-BD-195-S1-INFO1-SWEEP.md`
(architect read-only sweep; surfaces G1–G4).

---

## §1 — Task summary

Closed the audit coverage gap the C3 reviewer found (INFO-1): added one dated
in-place CORRECTION note to each of the 4 historical records that propagate the
retired phase-parts-as-v11.1 / `templates-archive/v11.1/` contamination. P-08
class treatment: bodies, findings, and verdicts preserved unaltered; a clearly
marked banner near the top of each doc supersedes the contamination framing.

**Outcome:** 4 notes added (NOT 3+1-flagged — see §3 for the #2 dormant-vs-live
determination). No body/verdict rewrites. `validate-pack.py` exit 0. Diff
confined to `maintenance-docs/`.

---

## §2 — Per-file detail

All hit counts captured at HEAD `0a05b29` via
`grep -nE "v11\.1|frozen" <file>` (full command output in §5 EB-1).

### G1 — `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`

- **Classification:** tracked HISTORICAL record. Header: "Authored by:
  pack-coder (Phase 3 of BD-193 audit pipeline)", dated 2026-05-27, "no commits
  made", "**Phase 3 (THIS report ...)**". Completed Code-Red-2 cleanup report.
- **Framing-variant / path hits superseded:** L77, L80, L126, L134, L202, L203,
  L486, L490 — 8 hits, all citing `templates-archive/v11.1/INDEX.md` +
  `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` as files BD-193
  "modified". Matches sweep EB-3 (8 uncorrected hits).
- **Note inserted:** after the `---` following the Pipeline metadata block,
  before `## §1 — Scope`. +13 lines, 0 deletions.
- **Added note text:**
  > **CORRECTION (BD-195 S1, 2026-05-31):** The `templates-archive/v11.1/` cut
  > and the phase-parts-as-v11.1 framing this report references (e.g., the
  > `templates-archive/v11.1/INDEX.md` and `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`
  > rows at §2/§3/§4 below) are **fictional contamination**, retired per BD-195
  > S1·C3. The phase-part SCHEMA was relocated to
  > `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`;
  > the `templates-archive/v11.1/` directory no longer exists. Phase-parts was
  > always **v11.0**; v11.0 is UNRELEASED and was never frozen. This is a tracked
  > historical record — its body, findings, and verdicts are preserved unaltered
  > as the record of what was done at the time, but every affected `v11.1` path
  > reference and "v11.1 cut" framing below is **superseded** by the corrected
  > v11.0 fact. See `AUDIT-BD-195-S1-INFO1-SWEEP.md` (surface G1).
- **No-rewrite confirmation:** numstat `13 0` (insertions only, zero deletions).
  All 8 original hits retained verbatim.

### G2 — `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md`

- **Classification:** DORMANT, completed read-only inventory (constraint fact
  base) → annotated with CN. See §3 for the full dormant-vs-live determination
  + evidence (this was the flagged nuance).
- **Contamination hits superseded** (per sweep §2.1 G2): L231 ("Adding
  `phase-part-v11.1` ... would extend this"), L559
  (`<!-- template_version: phase-part-v11.1 -->`), L614 ("the v11.1 cut (not
  v11.0) gains it"), L993 (`template:phase-part-v11.1?` checklist item), L998
  ("v11.0 = closed; v11.1 = new — landing under
  `templates-archive/v11.1/phase-part-v11.1/`"). 5 contamination hits.
  (The file's other `v11.1` hits — L20, L144, L392, L400, L843, L865, L869 — are
  LEGITIMATE GH-Projects / groupings / minor-version-fixture references, NOT
  superseded; the banner is worded to name only the phase-part framing.)
- **Note inserted:** between the `**Sidecar inputs:**` metadata block and
  `## Purpose`. +24 lines, 0 deletions. Per the sweep §3 sequencing note, the
  banner carries a **Held-state note** cross-referencing the PAUSED BD-185
  restart so the open Part-decision-checklist items (L991–L998) are read against
  the corrected v11.0 fact, not re-imported as live "v11.1 = new" decisions.
- **Added note text:**
  > **CORRECTION (BD-195 S1, 2026-05-31):** Several rows + decision-checklist
  > items below frame phase-parts as a **v11.1** feature landing under a
  > `templates-archive/v11.1/phase-part-v11.1/` cut (e.g., §3.I.2 L231 "Adding
  > `phase-part-v11.1` would extend this", §6 L559
  > `<!-- template_version: phase-part-v11.1 -->`, the §"check_template_archive_v11"
  > row L614 "the v11.1 cut (not v11.0) gains it", and the open Part-decision
  > checklist items L993 `template:phase-part-v11.1?` / L998 "Template archive cut
  > decision (v11.0 = closed; v11.1 = new — landing under
  > `templates-archive/v11.1/phase-part-v11.1/`)"). That phase-parts-as-v11.1
  > framing is **fictional contamination**, retired per BD-195 S1·C3. Phase-parts
  > was always **v11.0**; v11.0 is UNRELEASED and was never frozen/"closed". The
  > phase-part SCHEMA now lives at
  > `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`;
  > the `templates-archive/v11.1/` directory no longer exists. This is a tracked,
  > completed read-only inventory (a constraint fact base) — its body is preserved
  > unaltered, but every affected `v11.1` phase-part framing below is
  > **superseded** by the corrected v11.0 fact. **Held-state note:** BD-185 is
  > PAUSED pending BD-195 Step 9 (`pack-ops/BACKLOG.md` BD-185 entry), and the
  > BD-185 V2 architect substrate that consumed this inventory
  > (`ARCHITECTURE-BD-185-V2.md`) is itself held. When the BD-185 restart resumes,
  > the open Part-decision-checklist items above (L991–L998) MUST be read against
  > the corrected v11.0 fact — NOT re-imported as live "v11.1 = new" decisions.
  > See `AUDIT-BD-195-S1-INFO1-SWEEP.md` (surface G2 + §3 sequencing note).
- **No-rewrite confirmation:** numstat `24 0` (insertions only, zero deletions).
  All 5 contamination hits + all legitimate hits retained verbatim.

### G3 — `maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md`

- **Classification:** tracked HISTORICAL record. Header: "Authored by:
  pack-reviewer (read-only triage pass)", dated 2026-05-26, "**Phase 2 (THIS
  doc)**". Completed Code-Red-2 Phase-2 disposition.
- **Framing-variant / path hits superseded:** L122, L133, L230, L235, L237,
  L244, L248, L254, L283, L675, L676, L741, L744 — the `templates-archive/v11.1/`
  + `phase-part-v11.1/SCHEMA.md` disposition rows, the §4.7/§4.8 section heads,
  and the "v11.1 archive cut is driven by BD-185" rationale (~9 contamination
  framings per sweep §3; 15 raw `v11.1` token hits incl. the banner). Matches
  sweep EB-4.
- **Note inserted:** after the `---` following the Pipeline metadata block,
  before `## §1 — Scope`. +15 lines, 0 deletions.
- **Added note text:**
  > **CORRECTION (BD-195 S1, 2026-05-31):** This disposition report triages
  > against a `templates-archive/v11.1/` cut and a phase-parts-as-v11.1 framing
  > (e.g., the `templates-archive/v11.1/INDEX.md` and
  > `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` dispositions at §4.7/§4.8
  > and the "v11.1 archive cut is driven by BD-185" rationale) that are
  > **fictional contamination**, retired per BD-195 S1·C3. The phase-part SCHEMA
  > was relocated to
  > `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`;
  > the `templates-archive/v11.1/` directory no longer exists. Phase-parts was
  > always **v11.0**; v11.0 is UNRELEASED and was never frozen. This is a tracked
  > historical record — its body, findings, and dispositions are preserved
  > unaltered as the record of what was triaged at the time, but every affected
  > `v11.1` path reference and "v11.1 cut" framing below is **superseded** by the
  > corrected v11.0 fact. See `AUDIT-BD-195-S1-INFO1-SWEEP.md` (surface G3).
- **No-rewrite confirmation:** numstat `15 0` (insertions only, zero deletions).
  All original hits retained verbatim.

### G4 — `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md`

- **Classification:** tracked HISTORICAL record. Header: "Authored by:
  pack-docs-researcher (read-only inventory pass)", dated 2026-05-26, "Phase 1
  (inventory; THIS doc)". Completed Code-Red-2 Phase-1 inventory.
- **Framing-variant / path hits superseded:** L15, L50, L143, L147, L148, L149,
  L153, L155, L161, L660, L673, L674, L675, L693, L696, L719, L743, L776 — the
  `templates-archive/v11.1/` Surface-A inclusion, the "v11.1 archive cut is
  driven by BD-185" rationale, the "NEW v11.1 Prerequisites grammar" framing,
  and the D16 "structural shape frozen at 5 subdirs" wrapper (~9 contamination
  framings per sweep §3; 13 raw `v11.1` token hits incl. the banner). Matches
  sweep EB-4. **Note:** D16/L743 was the single pre-covered line (reconciled-list
  P-31b / R8-F09); the other ~8 hits were net-new gap — the banner explicitly
  names both the D16 wrapper and the net-new framings.
- **Note inserted:** after the `---` following the Pipeline metadata block,
  before `## §1 — Scope`. +17 lines, 0 deletions.
- **Added note text:**
  > **CORRECTION (BD-195 S1, 2026-05-31):** This inventory treats
  > `templates-archive/v11.1/` as a real "Surface A" client-facing audit target
  > (§1, §2, §3.9, §3.10, and the tally/quick-scan rows) and records a
  > phase-parts-as-v11.1 / "v11.1 archive cut is driven by BD-185" / "NEW v11.1
  > Prerequisites grammar" / "structural shape frozen at 5 subdirs" (D16) framing.
  > Those framings are **fictional contamination**, retired per BD-195 S1·C3 (the
  > D16 "frozen at 5 subdirs" line is also tracked as reconciled-list P-31b /
  > R8-F09). The phase-part SCHEMA was relocated to
  > `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`;
  > the `templates-archive/v11.1/` directory no longer exists. Phase-parts was
  > always **v11.0**; v11.0 is UNRELEASED and was never frozen. This is a tracked
  > historical record — its body and findings are preserved unaltered as the
  > record of what was inventoried at the time, but every affected `v11.1` path
  > reference, "v11.1 cut" framing, and "frozen at 5 subdirs" wrapper below is
  > **superseded** by the corrected v11.0 fact. See
  > `AUDIT-BD-195-S1-INFO1-SWEEP.md` (surface G4).
- **No-rewrite confirmation:** numstat `17 0` (insertions only, zero deletions).
  All original hits (incl. the P-31b-covered D16 line) retained verbatim.

---

## §3 — #2 (G2) dormant-vs-live finding + evidence (the flagged nuance)

**Determination: DORMANT completed read-only inventory → annotated with a CN
correction note (NOT flagged-for-deferral).** Matches the sweep doc's §3
classification (Net gap = 4, all CN). Evidence below.

**Q the prompt posed:** Is G2 a DORMANT historical inventory (→ correction
note, as planned), or a LIVE BD-185 planning input still actively consumed (→
do NOT annotate; defer to the BD-185 restart like the V2 substrate)?

**Evidence:**

1. **BD-185 is PAUSED.** `pack-ops/BACKLOG.md` L1749 (BD-185 entry):
   > "Paused: 2026-05-28 — PAUSED pending Code Red 3 (BD-195). The prior BD-185
   > attempt is being superseded/recovered by BD-195; no new BD-185 work begins
   > until BD-195 completes. BD-195 Step 9 decides whether the prior BD-185
   > work-so-far is wiped or salvaged."
   No active pipeline is consuming G2 to make live decisions right now.

2. **G2 is a completed read-only enumeration, not design substrate.** G2 header
   (L3): "Authored by: pack-docs-researcher (**read-only enumeration pass**)",
   dated 2026-05-24; Purpose (L16): "Comprehensive, **read-only** enumeration ...
   produced as a constraint fact base for the **forthcoming** pack-architect
   pass on BD-185." That architect pass (V2) ran and is now itself held. G2 is
   a frozen record, like G1/G3/G4 — not a doc being freshly produced/edited.

3. **All 8 referencers of G2 are either BD-195-audit inputs or HELD/PAUSED
   BD-185 substrate — no live, active consumer.** From
   `grep -rln "TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING"` (excl. `.git/`,
   `prison/`):
   - BD-195 audit context (exclude-set (c)): `AUDIT-BD-195-R7-PREREAD.md`,
     `AUDIT-BD-195-RETAINED-DECISIONS.md`, `AUDIT-BD-195-S1-INFO1-SWEEP.md`,
     `PACK-REVIEW-BD-195-S1-C3.md`, `AUDIT-INVENTORY-BD-TD-PATH.md`.
   - Held/paused BD-185 substrate (exclude-set (d) / BACKLOG-paused):
     `ARCHITECTURE-BD-185-V2.md`, `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-REVIEW-FIXES.md`,
     `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md`,
     `BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md`,
     `IMPLEMENTATION-REPORT-HANDOFF-PS-ARCHITECT.md`,
     `RESEARCH-BD-185-ORDERING-API.md`.

4. **G2 vs the V2 substrate (the key distinction the prompt drew).** V2
   (`ARCHITECTURE-BD-185-V2.md`) is correctly EXCLUDED from this sweep
   (exclude-set (d)) because it is **design substrate** that BD-195 Step-9 may
   wipe — editing it would alter held decisions. V2 cites G2 as one of its
   INPUTS (`ARCHITECTURE-BD-185-V2.md` L112: "EXTERNAL GH findings (§4) TRUSTED;
   internal form/validator facts treated as STALE and independently
   re-verified"). G2 is NOT design substrate — it is a completed read-only
   inventory. A top-banner correction note preserves G2's body verbatim (like
   G1/G3/G4) without altering any held decision, so the CN treatment is correct
   and does NOT collide with the BD-185-restart deferral.

5. **Sequencing handled.** Because G2 IS read by the held BD-185 substrate, the
   banner carries an explicit **Held-state note** (per sweep §3 sequencing note,
   L184–189) cross-referencing the paused BD-185 restart + V2, instructing that
   the open Part-decision-checklist items L991–L998 be read against the
   corrected v11.0 fact and NOT re-imported as live "v11.1 = new" decisions when
   BD-185 resumes.

**Conclusion:** G2 is DORMANT (a completed, frozen, read-only inventory). It is
*referenced by* paused substrate but is not itself live, actively-consumed
planning input being edited. CN (annotate) is correct; not FA (flag-for-defer).
4 notes added, not 3+1-flagged.

---

## §4 — Verification

| Check | Command | Result |
|---|---|---|
| validate-pack | `python3 scripts/validate-pack.py` | **EXIT 0** — "PASSED — all checks clean" (Check 44 durable-doc concision gate also OK) |
| Diff scope | `git diff --name-only` | 4 files, ALL under `maintenance-docs/` (3× v11-implementation, 1× v11-research). No `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`. |
| Additions-only (no rewrite) | `git diff --numstat` | `13 0`, `24 0`, `15 0`, `17 0` — 69 insertions, **0 deletions** across all 4 files. |
| One banner each | `grep -c 'CORRECTION (BD-195 S1, 2026-05-31)'` | 1 / 1 / 1 / 1. |
| Original hits retained | `grep -cE 'templates-archive/v11\.1\|phase-part-v11\.1'` | 10 / 10 / 15 / 13 (counts include banner refs; all original body lines intact per numstat 0-deletions). |

**Manifest:** all 4 files are `maintenance-docs/` — NOT v11-surface
(`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). Per the
`regenerate-manifest-v11-surface` rule, no `test-fixtures/manifest.txt` regen is
triggered. Confirmed: `git diff --name-only` shows zero v11-surface paths.

---

## §5 — Empirical-Evidence Blocks

### EB-1 — Hit counts per file at HEAD `0a05b29`
- **Command:** `grep -nE "v11\.1|frozen" <file>` for each of the 4 files.
- **Output (verbatim, pre-edit):**
  - G1 IMPLEMENTATION-REPORT-BD-193.md: 8 lines — L77, L80, L126, L134, L202,
    L203, L486, L490.
  - G2 TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md: raw `v11.1` lines L20, L144,
    L223, L231, L392, L400, L559, L614, L843, L865, L869, L993, L998 — of which
    the 5 CONTAMINATION (per sweep §2.1) are L231, L559, L614, L993, L998; the
    rest are legitimate GH-Projects/groupings/fixture refs.
  - G3 AUDIT-DISPOSITION-BD-TD-PATH.md: L122, L133, L230, L234, L235, L237,
    L244, L248, L254, L283, L675, L676, L741, L744 (~9 contamination framings).
  - G4 AUDIT-INVENTORY-BD-TD-PATH.md: L15, L50, L143, L147, L148, L149, L153,
    L155, L161, L660, L673, L674, L675, L693, L696, L719, L743, L776 (~9
    contamination framings; D16/L743 pre-covered as P-31b/R8-F09).
- **HEAD/date:** `0a05b29` / 2026-05-31.
- **Interpretation:** matches sweep doc §2.1 table + §3 net-gap counts (G1=8,
  G2=5 contamination, G3≈9, G4≈9).
- **Conclusion:** SUPPORTED.

### EB-2 — Diff is additions-only and maintenance-docs-confined
- **Command:** `git diff --numstat` + `git diff --name-only`.
- **Output (verbatim):**
  ```
  13	0	maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md
  24	0	maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md
  15	0	maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md
  17	0	maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md
  ```
- **HEAD/date:** `0a05b29` / 2026-05-31.
- **Interpretation:** every file `N 0` = pure insertion, zero deletion → no
  body/verdict rewrite; all paths under `maintenance-docs/`.
- **Conclusion:** SUPPORTED.

### EB-3 — G2 dormant-vs-live: BD-185 paused + all referencers paused/audit
- **Command:** `grep -nE "BD-185" pack-ops/BACKLOG.md`;
  `grep -rln "TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING" . --include="*.md"`
  (excl. `.git/`, `prison/`); `grep -n "TOUCH-POINT..." ARCHITECTURE-BD-185-V2.md`.
- **Output (verbatim, salient):** BACKLOG L1749 "Paused: 2026-05-28 — PAUSED
  pending Code Red 3 (BD-195) ... BD-195 Step 9 decides whether the prior BD-185
  work-so-far is wiped or salvaged." 8 referencer files, all BD-195-audit or
  held/paused-BD-185 substrate (enumerated §3 item 3).
  `ARCHITECTURE-BD-185-V2.md` L112 cites G2 as a TRUSTED-external/STALE-internal
  INPUT.
- **HEAD/date:** `0a05b29` / 2026-05-31.
- **Interpretation:** No live, active, non-paused, non-audit consumer of G2.
  G2 is a completed read-only inventory (its own header), not design substrate.
  → DORMANT → CN.
- **Conclusion:** SUPPORTED.

### EB-4 — validate-pack clean post-edit
- **Command:** `python3 scripts/validate-pack.py`.
- **Output (verbatim):** `EXIT: 0` … "PASSED — all checks clean" (Check 44 last:
  "OK: Check 44 — 7 durable doc(s) scanned; 0 forbidden pattern(s) outside the
  allowlist").
- **HEAD/date:** `0a05b29` / 2026-05-31.
- **Interpretation:** the 4 added banners introduce no validator regression.
- **Conclusion:** SUPPORTED.

---

## §6 — Plan deviations

**Zero.** All 4 surfaces from the INFO-1 sweep (G1–G4) annotated with CN exactly
as the sweep doc §3 classified. The flagged-nuance check on G2 resolved to the
planned CN treatment (with held-state cross-reference per the §3 sequencing
note); no FLAG-and-defer was needed.

---

## §7 — New POQs / boundary-discipline / Definition-of-Done

**New POQs:** none.

**Boundary discipline check:** all 4 edited files are `maintenance-docs/` (pack
internal records), NOT a project-shipped surface (`project-template/`,
`supporting-docs/`). No project-side SSOT applies; no pack-only reference was
added to a project-side file. The notes correctly reference pack-only artifacts
(`AUDIT-BD-195-S1-INFO1-SWEEP.md`, `pack-ops/BACKLOG.md`, BD-195/BD-185) because
the surfaces being annotated are themselves pack-internal historical records.
No boundary-discipline stop.

**Trinity rule:** N/A — no CLAUDE.md/AGENTS.md/GEMINI.md (pack-root or
project-template) touched.

**Definition-of-Done checklist:**

| Item | Status |
|---|---|
| Each of the 4 docs carries one clear dated correction note superseding the v11.1 framing | PASS (1 banner each; EB-1/§2) |
| No body/verdict rewrites | PASS (numstat 0 deletions across all 4; EB-2) |
| `validate-pack.py` exit 0 | PASS (EB-4) |
| Diff confined to `maintenance-docs/` | PASS (EB-2; §4) |
| #2 (G2) status confirmed (annotated or flagged with evidence) | PASS — DORMANT → annotated, evidence in §3 + EB-3 |
| Edit-in-place; original content intact, only note added | PASS (re-read each edited region; numstat additions-only) |
| ONLY the 4 scoped files touched | PASS (`git diff --name-only` = exactly the 4) |
| No manifest regen needed (non-v11-surface) | PASS (§4 manifest note) |
| No state-changing git verbs / no commit | PASS (HEAD unchanged `0a05b29`) |

---

## §8 — Files changed inventory

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md` | modified (+13 / −0) |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | modified (+24 / −0) |
| `maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md` | modified (+15 / −0) |
| `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md` | modified (+17 / −0) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-195-S1-C3a.md` | new (this report) |

No new non-report files (all 4 edits are in-place notes on existing files).

---

## §9 — Rules-Applied Verification Block

| Rule (as named in prompt SECTION 2 / MEMORY.md) | Verification evidence | Conclusion |
|---|---|---|
| In-place correction note, NOT rewrite (P-08 class) | `git diff --numstat` = `13 0 / 24 0 / 15 0 / 17 0` (69 ins, 0 del); bodies/findings/verdicts preserved; one dated banner near top of each. EB-2. | COMPLIANT |
| Empirical (grep hits first; count + lines; quote before/after) | Pre-edit `grep -nE "v11\.1\|frozen"` captured per file (EB-1); §2 quotes the full added note text per file; §4 quotes numstat. | COMPLIANT |
| Verify #2's status before annotating (dormant-vs-live; flag if live) | §3 + EB-3: BACKLOG L1749 BD-185 PAUSED; all 8 G2 referencers are BD-195-audit or held/paused-BD-185 substrate; G2 is a completed read-only inventory (its header), not live planning input. → DORMANT → annotated (NOT flagged). Held-state cross-ref added per sweep §3 sequencing note. | COMPLIANT |
| No scope creep (ONLY these 4 files; ONLY add notes; no body de-contamination; no legitimate-v11.1 touch) | `git diff --name-only` = exactly the 4 sweep surfaces; numstat additions-only (no body rewrite); G2 banner names only phase-part framing, leaves legitimate groupings/GH-Projects/fixture refs untouched. | COMPLIANT |
| Edit-in-place (re-read region; confirm original intact + only note added) | Re-read each edited region post-edit; numstat 0-deletions confirms original lines intact; `grep -c` confirms 1 banner each. | COMPLIANT |
| Manifest (maintenance-docs = non-v11-surface → no regen; confirm diff confined) | §4 manifest note; `git diff --name-only` shows zero v11-surface paths. No manifest regen triggered. | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat after all edits + verification PASS, before this Write. No parent stop received. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This block. | COMPLIANT |
| Agents never commit / no destructive ops / no deferral | No git state-change; HEAD unchanged `0a05b29` (start == end); no destructive op; no deferral introduced (all 4 surfaces handled this commit). | COMPLIANT |
| PRISON RULE (ignore `maintenance-docs/prison/`) | No read or edit of `prison/`; not in scope or diff. | COMPLIANT |
