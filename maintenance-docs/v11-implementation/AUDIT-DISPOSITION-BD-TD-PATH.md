# AUDIT-DISPOSITION-BD-TD-PATH.md — Code Red 2 Phase 2 disposition

**Authored by:** pack-reviewer (read-only triage pass).
**Date:** 2026-05-26 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at read time:** `8b4c6076dbc0488f57f44040a83dbf4fe8b1ab5a`
(`docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only)`).
**Pipeline:** Phase 1 (inventory — `AUDIT-INVENTORY-BD-TD-PATH.md`) →
**Phase 2 (THIS doc)** → Phase 3 (fix-coder).

---

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

## §1 — Scope

This disposition report triages the inventory findings recorded in
`maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md`
(Phase 1, 782 lines, ~140 raw findings across 48 files).

Eleven small-group dispositions are already user-locked and are recapped
in §3 below WITHOUT re-triage. The remaining ~115 findings (the bulk of
which are narrative BD cites across `supporting-docs/METHODOLOGY.md`,
`supporting-docs/MIGRATION-v10-to-v11.md`, and various
`project-template/` files) are triaged per the 3-rule stack in §2.

Three classes of finding are surfaced as AMBIGUOUS in §6 for user
discussion before the fix-coder pass.

---

## §2 — Methodology

### §2.1 — 3-rule triage stack (applied IN ORDER)

For each remaining finding, the following stack is applied in order:

**Rule 1 — Operational vs explanatory** (pack memory
`feedback_bd_pack_only_operational_rule`):

> Does this reference treat BDs as something CLIENTS work with
> functionally (admit as dependency type, peer-table, parser regex,
> form field admission)?
>
> - If YES → LEAK; flag for removal.
> - If NO → continue to Rule 2.

**Rule 2 — Pack/project separation** (pack memory
`feedback_pack_project_separation_of_concerns`):

> Is this a cross-side substitution (script copying pack file to
> client; client file used for pack ops)?
>
> - If YES → VIOLATION; propose correct same-side source.
> - If NO → continue to Rule 3.

**Rule 3 — Client-facing doc token economy** (pack memory
`feedback_client_facing_token_economy`):

> 1. Does the client reader / agent NEED this reference to understand
>    the surrounding content or to do their work?
> 2. Is the same information conveyable WITHOUT mentioning a pack
>    concept (BD-NNN, architect doc, pack-version history)?
> 3. If removed, does the doc still make sense to a client?
>
> - If (1) yes AND (2) no → LEGITIMATE; keep with clear pack-only
>   disclosure.
> - If (1) no OR (2) yes → WASTE; flag for removal.
> - If genuinely AMBIGUOUS → surface to user for discussion.

### §2.2 — Disposition categories

| Category | Triggered by | Action |
|---|---|---|
| **LEAK (operational)** | Rule 1 fail | Remove the BD-NNN admission; preserve the surrounding grammar minus the BD-NNN token. |
| **VIOLATION (cross-side substitution)** | Rule 2 fail | Propose correct same-side source path. |
| **WASTE (unnecessary explanatory)** | Rule 3 fail | Remove the reference; rephrase sentence without the pack token. |
| **LEGITIMATE (necessary explanatory)** | Passes all 3 rules | Keep; ensure clear pack-only disclosure if needed. |
| **AMBIGUOUS** | Rule 3 step 1–3 not clearly answerable | Surface to user (§6); do NOT auto-decide. |

### §2.3 — Scope (what THIS report does NOT triage)

The following are LOCKED and recapped in §3 WITHOUT re-triage:

1. F1 (3 sub-locations) — INDEX segregation + bd-v11.0 PACK-INTERNAL header.
2. F2 (5 sub-locations) — BD-NNN dependency-grammar admission removal.
3. F3 (1 sub-location) — `_intro.md` L34 cross-reference list removal.
4. F4 + F5 (1 location, 4 finding rows) — init-project.sh S11 pack-ops copy.

These 11 sub-locations are user-locked per the audit prompt and are NOT
re-triaged here.

### §2.4 — Frame discipline

Per pack memory `P-missed-7` and the review skill's "Boundary discipline"
priority (`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/
.claude/skills/review/SKILL.md` priority 0):

- Project-side reviews (Surface A `project-template/**`,
  `supporting-docs/**` client-shipped) reference project-side SSOTs
  (TD-NNN, `docs/project/backlog/_rules.md`).
- Pack-side reviews (Surface B scripts) reference pack-side SSOTs
  (BD-NNN, `pack-ops/BACKLOG.md`).
- Cross-side substitution is FORBIDDEN (Rule 2).

Inventory finding rows are pre-tagged with `Surface: A|B` from Phase 1;
this report inherits that frame discipline.

---

## §3 — 11 LOCKED dispositions (recap; no triage)

The following 11 sub-locations are user-locked. They are listed here for
auditability; the fix-coder will apply the locked dispositions in Phase 3.

### §3.1 — F1 (3 sub-locations) — INDEX segregation + PACK-INTERNAL header

**Disposition:** Option C — INDEX segregation into "Client-applicable" vs
"Pack-internal" sections; PACK-INTERNAL header on bd-v11.0/SCHEMA.md.

| Sub-location | Inventory ref | File / Line | Description |
|---|---|---|---|
| F1.a | A-3.1.1 | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md:10` | BD-NNN listed as 1st of 5 entry types in v11.0 cut INDEX. **Action:** Segregate into "Client-applicable" vs "Pack-internal" sections. |
| F1.b | A-3.9.3 | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md:17` | v11.1 INDEX inherits BD-NNN entry-type row. **Action:** Same segregation. |
| F1.c | A-3.2.* (entire file) | `maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md` | BD-NNN SCHEMA grammar definition. **Action:** Add `**SCOPE: PACK-INTERNAL.**` header at top of file. |

### §3.2 — F2 (5 sub-locations) — BD-NNN dependency-grammar admission removal

**Disposition:** Option C-2 — remove BD-NNN admission from all grammars;
D16 bug-fix carve-out for v11.0 archive (2a + 2c).

| Sub-location | Inventory ref | File / Line | Description |
|---|---|---|---|
| F2.a | A-3.5.2, A-3.5.3 | `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:79,91` | Dependencies grammar admits `BD-NNN` for client phase-task entity. **Action:** Remove `BD-NNN` token; preserve `phase-N`, `phase-N.M`, `TD-NNN`. D16 bug-fix carve-out applies. |
| F2.b | A-3.10.16, A-3.10.20 | `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md:129-130,152` | Prerequisites grammar admits `BD-NNN`. **Action:** Remove `BD-NNN` token; preserve remaining Part / Task / TD grammar. |
| F2.c | A-3.7.1, A-3.7.2, A-3.7.4, A-3.7.5, A-3.7.6 | `templates-archive/v11.0/forms/work-item.yml:2,3,23,105,169` | Form admits BD-NNN as entry type AND in Blockers/Dependencies. **Action:** Per Option C-2 + D16, remove BD-NNN admission. |
| F2.d | A-3.12.1, A-3.12.5, A-3.12.6, A-3.12.7 | `project-template/.github/ISSUE_TEMPLATE/work-item.yml:2,25,107,171` | Live client-installed form: `bd` dropdown + BD-NNN in Blockers/Dependencies. **Action:** Remove `bd` dropdown option; remove BD-NNN from Blockers/Dependencies grammars. |
| F2.e | A-3.44.2 | `supporting-docs/METHODOLOGY.md:386-388` | Client-shipped Dependencies grammar parser regex admits `BD-\d+`. **Action:** Replace regex with `^\s*-\s+(phase-\d+(\.\d+)?\|TD-\d+)(\s+(.*))?$` (drop `\|BD-\d+`). |

### §3.3 — F3 (1 sub-location) — `_intro.md` cross-reference list

**Disposition:** Remove BD-NNN from inline list.

| Sub-location | Inventory ref | File / Line | Description |
|---|---|---|---|
| F3 | A-3.40.5 | `project-template/docs/project/backlog/_intro.md:34` | Cross-references bullet currently reads: `TD-NNN, BD-NNN, phase-N, phase-N.M / identifiers may appear in Blockers / Unblocks / prose.` **Action:** Remove `BD-NNN,`. New bullet: `TD-NNN, phase-N, phase-N.M / identifiers may appear in Blockers / Unblocks / prose.` |

### §3.4 — F4 + F5 (1 location, 4 finding rows) — init-project.sh S11 block

**Disposition:** Option α — source from
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`; remove pack-root
fallback.

| Sub-location | Inventory ref | File / Line | Description |
|---|---|---|---|
| F4/F5.a | B-4.1.1 | `scripts/init-project.sh:823-825` | Primary cp from `$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md`. **Action:** Replace source with `$PACK/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. |
| F4/F5.b | B-4.1.2 | `scripts/init-project.sh:820-822` | Preceding-comment context citing BD-175. **Action:** Replace with brief comment explaining project-side source-of-truth. |
| F4/F5.c | B-4.1.3 | `scripts/init-project.sh:826-828` | Fallback cp from `$PACK/HELP-FRAGMENT-TRACKER.md` (pre-v11). **Action:** REMOVE the fallback branch entirely (per Option α "remove pack-root fallback"). |
| F4/F5.d | B-4.1.4 | `scripts/init-project.sh:1308-1309` | Trailing manifest comment block. **Action:** Update to reflect single source path. |

---

## §4 — Per-file disposition tables

### §4.1 — `maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md`

Findings A-3.2.1 through A-3.2.10. **Status:** Covered by F1.c lock
(PACK-INTERNAL header). With the SCOPE header in place, the entire body
of this file is LEGITIMATE (definitional pack-internal SCHEMA), as the
header makes the pack-only scope explicit at the file top.

**Per-finding triage (post-F1.c):**

| # | Disposition | Rationale |
|---|---|---|
| A-3.2.1 (L5) | **LEGITIMATE** | Pack-internal SCHEMA references `pack tracker update-templates` verb + BD-069; PACK-INTERNAL header disclosed. |
| A-3.2.2 (L11) | **LEGITIMATE** | Header citation to BD-064 + Addendum 4 §2.2 (pack architect-doc audit-trail). |
| A-3.2.3 (L15) | **LEGITIMATE** | "Identifier: BD-NNN" is the SCHEMA's defining sentence for the pack entity. |
| A-3.2.4–10 | **LEGITIMATE** | Grammar / body-marker / reverse-emit / label-family / Blocker grammar — all definitional for the pack-internal entity contract. |

No further fix needed beyond F1.c lock action.

### §4.2 — `maintenance-docs/v11-research/templates-archive/v11.0/td-v11.0/SCHEMA.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.3.1 (L47) | **LEGITIMATE** | Path 1/2 label namespace via `promoted-to:phase-N` and `promoted-to:phase-N.M`. Consistent with user-locked Rule 3 (Path 2 target is `phase-N.M`, NOT `Phase-N.Part-x`). | KEEP. Path 1/2 lifecycle vocabulary is the user-locked normative pattern. |
| A-3.3.2 (L101 cite chain) | **LEAK (operational)** | TD dependencies grammar inherited from phase-task SCHEMA admits BD-NNN. Once F2.a removes BD-NNN from `phase-task-v11.0/SCHEMA.md`, this inherited admission is also removed. | **BEFORE:** TD dependencies grammar admits BD-NNN per phase-task SCHEMA §5.3 chain. **AFTER:** TD dependencies grammar (post-F2.a) admits `phase-N`, `phase-N.M`, `TD-NNN` only. (Verify after F2.a fix.) |

**Note:** A-3.3.2 is a downstream consequence of F2.a; no independent edit
to `td-v11.0/SCHEMA.md` is required.

### §4.3 — `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.4.1 (L11) | **LEGITIMATE** | "IMPLEMENTATION-PLAN.md BD-064 + Addendum 4 §2.2." Header citation in a `maintenance-docs/v11-research/templates-archive/` file (Surface A but pack-archive research surface; not client-shipped). | KEEP. Pack-archive surface; audit-trail to architect-doc warrants. |
| A-3.4.2 (L43) | **LEGITIMATE** | `derived-from:TD-NNN` carrier for Path 1 (TD → phase-epic) declared. This is the user-locked lifecycle pattern. | KEEP. Lifecycle carrier label per Rule 3. |
| A-3.4.3 (L114-117) | **LEGITIMATE** | `derived-from:TD-NNN` footer reverse-emit grammar. Pure TD-side carrier; no BD-NNN admission. | KEEP. |

### §4.4 — `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.5.1 (L44) | **LEGITIMATE** | `derived-from:TD-NNN` Path 2 carrier — user-locked lifecycle pattern. | KEEP. |
| A-3.5.2, A-3.5.3 (L79, L91) | **LOCKED (F2.a)** | BD-NNN dep admission. | Per §3.2 F2.a. |
| A-3.5.4 (L139-143) | **LEGITIMATE** | `derived-from:TD-NNN` reverse-emit grammar. | KEEP. |

### §4.5 — `maintenance-docs/v11-research/templates-archive/v11.0/inbound-v11.0/SCHEMA.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.6.1 (L12) | **WASTE** | "BD-064 + Addendum 4 §2.2." Header citation. Inbound SCHEMA is in a pack-research archive but the citation is to an architect doc that v11 readers are unlikely to need. | **BEFORE:** "...BD-064 + Addendum 4 §2.2." **AFTER:** Remove the BD-064 reference; the SCHEMA stands on its own as a contract document. *(Pack-research surface — token economy still applies to maintenance-docs maintenance burden.)* |
| A-3.6.2 (L17) | **LEGITIMATE** | "(no BD-NNN / TD-NNN). The GH issue number is the identifier." — NEGATIVE-form boundary statement that clarifies inbound has no pack-side namespace. **However:** under Rule 1 strict reading, even mention-to-exclude is mention. Surfaced as AMBIGUOUS §6.1 below. | KEEP pending §6.1 user decision. |
| A-3.6.3 (L114) | **LEGITIMATE** | "to BD-NNN / TD-NNN, inbound entries have no pack-side namespace" — same negative-form pattern. AMBIGUOUS per §6.1. | KEEP pending §6.1 user decision. |
| A-3.6.4 (L119-121) | **WASTE** | "Forward migration (BD-065) does not write inbound entries... Reverse migration (BD-067) excludes inbound entries." Pack-history audit-trail; no operational client need. | **BEFORE:** "Forward migration (BD-065) does not write..." / "Reverse migration (BD-067) excludes..." **AFTER:** "Forward migration does not write inbound entries to flat files... Reverse migration excludes inbound entries..." (drop BD parenthetical cites). |

### §4.6 — `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.7.1 (L2) | **LOCKED (F2.c)** | Form description admits BD-NNN entry type. | Per §3.2 F2.c. |
| A-3.7.2 (L3) | **LOCKED (F2.c)** | Default title prefix `BD-NNN:`. | Per §3.2 F2.c. |
| A-3.7.3 (L13) | **WASTE** | "chat at triage time renames the title (e.g. `BD-NNN:` becomes the assigned ID)" — exemplifies BD-NNN; with F2.c removing BD admission, this example must also change. | **BEFORE:** "(e.g. `BD-NNN:` becomes the assigned ID)" **AFTER:** "(e.g. `TD-NNN:` becomes the assigned ID)" — or drop the parenthetical entirely. |
| A-3.7.4 (L23) | **LOCKED (F2.c)** | `wi-type` dropdown `bd` option. | Per §3.2 F2.c — drop `bd` option. |
| A-3.7.5 (L105) | **LOCKED (F2.c)** | Blockers grammar admits BD-NNN. | Per §3.2 F2.c. |
| A-3.7.6 (L169) | **LOCKED (F2.c)** | Dependencies grammar admits BD-NNN. | Per §3.2 F2.c. |

**Note:** A-3.7.3 is collateral to F2.c — must be fixed alongside F2.c
actions to maintain example/text consistency.

### §4.7 — `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.9.1 (L3) | **WASTE** | "preserves the v11.1 form file (added in BD-185 H.2)" — narrative pack-history cite in pack-archive INDEX. | **BEFORE:** "preserves the v11.1 form file (added in BD-185 H.2) and" **AFTER:** "preserves the v11.1 form file and" — or rephrase as "preserves the v11.1 form file (added in v11.1) and". |
| A-3.9.2 (L7) | **WASTE** | "v11.1 archive cut is driven by BD-185" — pack-history rationale. | **BEFORE:** "The v11.1 archive cut is driven by BD-185 (Multi-part phase mid-work..." **AFTER:** "The v11.1 archive cut introduces multi-part phase mid-work..." (drop BD-185 cite; keep the descriptive content). |
| A-3.9.3 (L17) | **LOCKED (F1.b)** | INDEX row admits `bd-v11.0` as peer entry type. | Per §3.1 F1.b. |
| A-3.9.4 (L24) | **WASTE** | "Reference: ARCHITECTURE-BD-185.md §4.1 (Part-id grammar) / §4.3" — pack architect-doc cite. | **BEFORE:** "Reference: ARCHITECTURE-BD-185.md §4.1 (Part-id grammar) / §4.3" **AFTER:** Remove the reference line. (The SCHEMA file `phase-part-v11.1/SCHEMA.md` itself is the contract document.) |
| A-3.9.5 (L33) | **WASTE** | "per ARCHITECTURE-BD-185.md §10.1 Convention Y" — same pattern. | Remove reference. |
| A-3.9.6 (L39) | **WASTE** | "by BD-185 mid-work phase expansion" — pack-history. | Remove BD-185 cite; rephrase. |
| A-3.9.7 (L43) | **WASTE** | "BD-185 exercises this convention" — pack-history. | Remove cite. |
| A-3.9.8 (L48-49) | **WASTE** | "BD-185 §4.4a... BD-185 H.13" — pack architect-doc + plan cite. | Remove cites. |
| A-3.9.9 (L51) | **WASTE** | "extension lands in BD-185 H.14" — pack-plan cite. | Remove cite. |
| A-3.9.10 (L57) | **WASTE** | "byte-identical to the post-BD-185-H.2 live form" — pack-plan cite. | Rephrase: "byte-identical to the live form". |
| A-3.9.11 (L61) | **WASTE** | "CREATED in BD-185 H.2 per POQ-1 resolution 2026-05-26" — pack-history + POQ-internal jargon. | Remove sentence or rephrase to "CREATED in v11.1". |
| A-3.9.12 (L76) | **WASTE** | "Per BD-185 §4.3 template-version delta table" — pack architect-doc cite. | Remove cite. |
| A-3.9.13 (L84) | **WASTE** | "See `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §1.4" — pack architect-doc cite. | Remove cite. |

**Note:** `templates-archive/v11.1/INDEX.md` is a pack-archive surface
(Surface A but research-archive, not client-shipped). Token economy still
applies: maintenance burden + the BD-185 cites refer to a temporary
architect doc that will be archived. Most cites can be replaced with
inline descriptive text.

### §4.8 — `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`

This file is the densest contributor: 26 findings, ~25 are BD-185 cites.

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.10.1 (L5) | **WASTE** | "introduced by mid-work phase expansion (BD-185)" | **BEFORE:** "...introduced by mid-work phase expansion (BD-185). A Part groups..." **AFTER:** "...introduced by mid-work phase expansion. A Part groups..." |
| A-3.10.2 (L11) | **WASTE** | "BD-185 §4.5" pack architect-doc cite. | Remove cite; describe verb behavior inline. |
| A-3.10.3 (L13) | **WASTE** | "BD-185 §4.7 D2 no-collapse rule" | Rephrase to inline rule statement. |
| A-3.10.4 (L15) | **WASTE** | "Reference: ARCHITECTURE-BD-185.md §4.1 / §4.1a / §4.3 / §4.4 / §4.7" | Remove reference line; this SCHEMA file is itself the contract. |
| A-3.10.5 (L20) | **WASTE** | "per the C-1 grammar (BD-185 §4.1)" | **BEFORE:** "Identifier: `Phase-N.Part-x` per the C-1 grammar (BD-185 §4.1)." **AFTER:** "Identifier: `Phase-N.Part-x` per the canonical grammar." |
| A-3.10.6 (L34) | **WASTE** | "(per BD-185 §4.1)" | Remove parenthetical. |
| A-3.10.7 (L53) | **WASTE** | "BD-185 H.5 `tracker-phase-part.sh`" — pack plan-step cite. | **BEFORE:** "(BD-185 H.5 `tracker-phase-part.sh`) validates..." **AFTER:** "(`tracker-phase-part.sh`) validates..." |
| A-3.10.8 (L59) | **WASTE** | "BD-185 §4.3 5th wi-type option" | Rephrase: "form path admits an additional wi-type option for phase-parts". |
| A-3.10.9 (L75) | **WASTE** | "(per BD-185 §4.4 lifecycle invariant)" | Remove parenthetical; "(per the lifecycle invariant below)". |
| A-3.10.10 (L83-85) | **LEGITIMATE** | EXPLICIT statement that TDs do NOT derive Parts (NEGATIVE TD→Part reference); reinforces user-locked Rule 3. | KEEP. This is load-bearing boundary statement; phrasing references "§6.5 D-18 carrier matrix" (architect-doc cite) which can be replaced with inline text per Rule 3. **Fix tweak:** rephrase "(§6.5 D-18 carrier matrix)" to "(per the TD-promotion carrier matrix in `phase-epic-v11.0/SCHEMA.md` and `phase-task-v11.0/SCHEMA.md`)". |
| A-3.10.11 (L81) | **WASTE** | "BD-185 §4.4a" cite. | Remove. |
| A-3.10.12 (L89) | **WASTE** | "Per BD-185 §4.4 (LOAD-BEARING). Restrictive taxonomy:" | **BEFORE:** "Per BD-185 §4.4 (LOAD-BEARING). Restrictive taxonomy: four states only." **AFTER:** "Restrictive taxonomy: four states only (LOAD-BEARING)." |
| A-3.10.13 (L96) | **WASTE** | "(re-parenting forbidden per D4 supersede-only rule, BD-185 §4.7)" | Rephrase: "(re-parenting forbidden per supersede-only rule)". |
| A-3.10.14 (L98) | **WASTE** | "Lifecycle invariant (BD-185 §4.4):" | "Lifecycle invariant:" |
| A-3.10.15 (L108) | **WASTE** | "per BD-185 §4.8" | Rephrase: "per `pack task supersede` semantics". |
| A-3.10.16 (L129-130) | **LOCKED (F2.b)** | Prerequisites grammar admits BD-NNN. | Per §3.2 F2.b. |
| A-3.10.17 (L138) | **WASTE** | "BD-185 H.5 `tracker-phase-part.sh`" | "(`tracker-phase-part.sh`)". |
| A-3.10.18 (L142) | **WASTE** | "BD-185 §4.1 admits the additional Part-id forms" | Rephrase: "the grammar admits the additional Part-id forms". |
| A-3.10.19 (L150) | **WASTE** | "BD-185 §4.1 backward-compat shim" | "(backward-compat shim)". |
| A-3.10.20 (L152) | **LOCKED (F2.b)** | "`BD-NNN` — depends on a BD entry" — explicit BD-NNN dep type. | Per §3.2 F2.b. |
| A-3.10.21 (L180) | **WASTE** | "`pack tracker phase split` (BD-185 §4.7)" | "(`pack tracker phase split`)". |
| A-3.10.22 (L189) | **WASTE** | "TBD — defined in BD-185 H.8" | Rephrase: "TBD — defined in `tracker-migrate-reverse.sh`". |
| A-3.10.23 (L193) | **WASTE** | "via the BD-185 H.8 sequence" | "via `tracker-migrate-reverse.sh`". |
| A-3.10.24 (L196) | **WASTE** | "per BD-185 §4.6 INLINE rule" | "per the INLINE rule (see `phase-part-v11.1/SCHEMA.md` §X)". |
| A-3.10.25 (L219) | **WASTE** | "(per BD-185 §6.3a / D8)" | Rephrase inline. |
| A-3.10.26 (L226) | **WASTE** | "Cross-reference: ARCHITECTURE-BD-185.md §6.3a + D8" | Remove reference line. |

**Note:** ALL 23 BD-185 cites in this file are WASTE per Rule 3
(unnecessary explanatory; pack-archive surface, but the SCHEMA itself is
the contract — readers should not need to cross-reference an architect
doc to understand it).

### §4.9 — `maintenance-docs/v11-research/templates-archive/README.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.11.1 (L48) | **WASTE** | "directory once `pack tracker update-templates` ships (BD-069)" | **BEFORE:** "...ships (BD-069)." **AFTER:** "...ships." (BD-069 is pack-implementation backlog item; readers don't need the cite.) |
| A-3.11.2 (L69) | **WASTE** | "IMPLEMENTATION-PLAN.md BD-064 + Addendum 4 §2.2." | Remove cite. |

### §4.10 — `project-template/.github/ISSUE_TEMPLATE/work-item.yml`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.12.1 (L2) | **LOCKED (F2.d)** | Form description admits BD-NNN. | Per §3.2 F2.d. |
| A-3.12.2 (L3) | **LEGITIMATE** | Default title prefix `TD-NNN:` — project-side correct. | KEEP. |
| A-3.12.3 (L13) | **LEGITIMATE** | "chat at triage time renames the title (e.g. `TD-NNN:` becomes the assigned" — project-side correct. | KEEP. |
| A-3.12.4 (L18) | **LEGITIMATE** | "Pack-development items (BD-NNN) belong in the pack repo, not in this project." — EXPLICIT boundary-respect (NEGATIVE form). **However:** AMBIGUOUS per §6.1 (mention-to-exclude rule). | KEEP pending §6.1 user decision. |
| A-3.12.5 (L25) | **LOCKED (F2.d)** | `bd` dropdown option. | Per §3.2 F2.d. |
| A-3.12.6 (L107) | **LEGITIMATE** | "TD-NNN, #N" — Blockers grammar admits TD-NNN only (NO BD-NNN). | KEEP. Project-side correct. |
| A-3.12.7 (L171) | **LOCKED (F2.d)** | Dependencies grammar admits BD-NNN. | Per §3.2 F2.d. |

### §4.11 — `project-template/tracker.toml.project-example`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.13.1 (L71) | **WASTE** | "# Cross-entity dependency graph tuning (BD-108)." | **BEFORE:** "# Cross-entity dependency graph tuning (BD-108)." **AFTER:** "# Cross-entity dependency graph tuning." Pack-history is irrelevant to client config readers. |

### §4.12 — `project-template/.gitignore`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.14.1 (L7) | **WASTE** | "# ─── Tracker-mode local state (BD-061) ─────────────────────────" | **BEFORE:** include BD-061 cite. **AFTER:** "# ─── Tracker-mode local state ─────────────────────────────────" |

### §4.13 — `project-template/CLAUDE.md` / `project-template/AGENTS.md` / `project-template/GEMINI.md` (trinity)

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.15.1 / A-3.16.1 / A-3.17.1 (L195 / L179 / L191) | **WASTE** | "project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()`" — narrative cite to pack BD in trinity skill-loading section. | **BEFORE:** "...for every project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the..." **AFTER:** "...for every project. See `scripts/init-project.sh` `stage_s4_skills()` and the..." Drop the BD-142 cite; the surrounding paragraph already names the mechanism (`stage_s4_skills()`). **Trinity rule:** apply identically to all 3 trinity files (CLAUDE/AGENTS/GEMINI). |
| A-3.15.2 / A-3.16.2 / A-3.17.2 (L309-310 / L293-294 / L305-306) | **LEGITIMATE** | TD-TBD typed-deferral block grammar (`// TODO(scope): TD-TBD — Short title`, etc.). This is operational client-side lifecycle grammar. | KEEP. Project-side correct. |
| A-3.15.3 / A-3.16.3 / A-3.17.3 (L321 / L296 / L317) | **LEGITIMATE** | "Always write `TD-TBD` — never a real TD number..." — operational deferral discipline. | KEEP. |
| A-3.16.4 (AGENTS.md L309) | **LEGITIMATE** | "coder \| Write TD-TBD comments..." — BACKLOG-write-permissions row. Project-side TD lifecycle. | KEEP. |

### §4.14 — `project-template/.gemini/.env.example`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.18.1 (L3) | **WASTE** | "# Per BD-059, AGENT_CAPABILITIES is mirrored across the three tools:" | **BEFORE:** "# Per BD-059, AGENT_CAPABILITIES is mirrored across the three tools:" **AFTER:** "# AGENT_CAPABILITIES is mirrored across the three tools:" |
| A-3.18.2 (L11) | **WASTE** | "# BD-059 success criterion)." | **BEFORE:** "...# BD-059 success criterion)." **AFTER:** Drop the parenthetical entirely. |

### §4.15 — `project-template/.codex/config.toml` / `.codex/config.toml.example`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.19.1 (L20) | **WASTE** | "# and `.gemini/.env` AGENT_CAPABILITIES per the BD-059 trinity rule for" | **BEFORE:** "...per the BD-059 trinity rule..." **AFTER:** "...per the trinity rule..." |
| A-3.20.1 (L10) | **WASTE** | "# and the .gemini/settings.json MCP block (per BD-059 trinity-rule" | **BEFORE:** "(per BD-059 trinity-rule..." **AFTER:** "(per trinity-rule..." |

### §4.16 — `project-template/docs/pack/PM-CHAT.md`

This file carries the client-shipped TD lifecycle orchestration. Mix of
WASTE (BD cites) and LEGITIMATE (Path 1/2/3 lifecycle).

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.21.1 (L608) | **WASTE** | "`tracker_links_create_blocked_by` (BD-108)" — pack BD cite in a description of an orchestrator. | **BEFORE:** "`tracker_links_create_blocked_by` (BD-108) to wire the" **AFTER:** "`tracker_links_create_blocked_by` to wire the" |
| A-3.21.2 (L651) | **WASTE** | "Orchestration library: `scripts/lib/tracker-promote.sh` (BD-107)." | **BEFORE:** "...`scripts/lib/tracker-promote.sh` (BD-107)." **AFTER:** "...`scripts/lib/tracker-promote.sh`." |
| A-3.21.3 (L655) | **WASTE** | "the BD-108 `tracker_links_create_blocked_by` orchestrator" | **BEFORE:** "and the BD-108 `tracker_links_create_blocked_by` orchestrator; no new" **AFTER:** "and the `tracker_links_create_blocked_by` orchestrator; no new" |
| A-3.21.4 (L295) | **LEGITIMATE** | "TD-TBD → TD-NNN replacement or rejected-comment removal" — TD lifecycle. | KEEP. |
| A-3.21.5–18 (L540-650) | **LEGITIMATE** | Full TD resolution orchestration section: Path 1, Path 2, Path 3-forbidden. Consistent with user-locked Rule 3 (Path 2 target is `phase-N.M`, NOT `Phase-N.Part-x`). This entire section is the client-side normative pattern. | KEEP entirely. This is the OPERATIONAL TD-promotion contract for client PMs. |

**Verification of Path 2 target:** Per Phase 1 §3.21.6 inventory note,
PM-CHAT.md L546-547 explicitly names Path 2 target as `phase-N.M` (task),
NOT `Phase-N.Part-x` — consistent with user-locked Rule 3. No edit needed
to the Path 2 semantics.

### §4.17 — `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.22.1 (L17-32) | **LEGITIMATE** | Path 1 / Path 2 / Path 3-forbidden table. Path 2 target `phase-N.M` (task). User-locked Rule 3 compliant. | KEEP. |
| A-3.22.2 (L45-46) | **LEGITIMATE** | Colloquial mappings: "promote this TD to a new phase" → Path 1; "promote this TD to a task in phase N" → Path 2. | KEEP. |

### §4.18 — `project-template/docs/pack/HELP-FRAGMENT.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.23.1 (L11) | **LEGITIMATE** | "/pm-startup ... run TD-TBD check, report." — operational. | KEEP. |
| A-3.23.2 (L19) | **LEGITIMATE** | "`pack td promote --to=phase-N` \| Promote a TD-NNN to a new phase epic (Path 1)." | KEEP. |
| A-3.23.3 (L20) | **LEGITIMATE** | "`pack td promote --to=phase-N.M` \| Promote a TD-NNN to a new phase task under phase N (Path 2)." | KEEP. |

### §4.19 — `project-template/docs/pack/PLATFORM-SKILLS.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.24.1 (L222) | **WASTE** | "is the canonical predicate for the data-marker branch (see BD-141)" | **BEFORE:** "(see BD-141);" **AFTER:** "; this predicate names the canonical detection branch." Or simply drop "(see BD-141)" without replacement. |
| A-3.24.2 (L223) | **WASTE** | "(see BD-156)" | Drop. |
| A-3.24.3 (L224) | **WASTE** | "(see BD-162)" | Drop. |
| A-3.24.4 (L225) | **WASTE** | "(see BD-157)" | Drop. |
| A-3.24.5 (L496) | **LEGITIMATE** | "pm-startup \| PM chat session startup procedure: read state files, check TD-TBD sentinels, report ready status \| PM chat only (not an agent)" — operational TD lifecycle. | KEEP. |
| A-3.24.6 (L582) | **WASTE** | "enforcement migration is tracked under BD-155." | **BEFORE:** "...tracked under BD-155." **AFTER:** "...tracked in future pack work." Or drop sentence entirely. |
| A-3.24.7 (L599-601) | **WASTE** | "v11.0 additions: `protobuf-patterns` (BD-156, Proto3...), `apple-swiftdata-patterns` (BD-157, SwiftData...), `swift-concurrency-patterns` (BD-158, modern..." — BD parentheticals are pack-history. | **BEFORE:** "`protobuf-patterns` (BD-156, Proto3 schema design...)" **AFTER:** "`protobuf-patterns` (Proto3 schema design...)" — drop BD parentheticals; retain skill descriptions. |

### §4.20 — `project-template/docs/pack/prompts/reviewer.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.25.1 (L65) | **LEGITIMATE** | "Run `grep -rn \"TD-TBD\" .` on all files modified in this phase. Any result is ❌ FAIL" — operational TD-TBD check. | KEEP. |
| A-3.25.2 (L71) | **LEGITIMATE** | "For each TD-NNN found in reviewed files, confirm a matching BACKLOG entry" — operational. | KEEP. |

### §4.21 — `project-template/docs/pack/prompts/auditor.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.26.1 (L18) | **LEGITIMATE** | TD-NNN..TD-MMM range syntax — operational TD lifecycle. | KEEP. |

### §4.22 — `project-template/docs/pack/prompts/pm-chat.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.27.1 (L179-185) | **LEGITIMATE** | BACKLOG entry format template with TD-NNN — operational. | KEEP. |
| A-3.27.2 (L193) | **LEGITIMATE** | TD-NNN resolution append. | KEEP. |
| A-3.27.3 (L201) | **LEGITIMATE** | Blockers list TD-NNN reference. | KEEP. |

### §4.23 — `project-template/docs/pack/prompts/coder.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.28.1 (L100-103) | **LEGITIMATE** | TD-TBD typed-deferral block + discipline statement. | KEEP. |
| A-3.28.2 (L107) | **LEGITIMATE** | "TD-TBD): TD-[NNN]" | KEEP. |
| A-3.28.3 (L216-219) | **LEGITIMATE** | TD-TBD typed-deferral block (second occurrence). | KEEP. |

### §4.24 — `project-template/.claude/agents/coder.md` / `.gemini/agents/coder.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.29.1 / A-3.30.1 (L83 / L82) | **LEGITIMATE** | "TD-TBD deferral" — operational. | KEEP. |

### §4.25 — `project-template/.codex/agents/coder.toml`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.31.1 (L48) | **LEGITIMATE** | "TD-TBD deferral comments inside source files are permitted" — operational. | KEEP. |

### §4.26 — pm-startup skill files (4 mirrors)

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.32.1/.2/.3 | **LEGITIMATE** | TD-TBD sentinel check + TD-NNN reporting — operational pm-startup procedure. | KEEP all 4 mirrors. |

### §4.27 — `project-template/skills/audit-methodology/SKILL.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.33.1 (L76) | **LEAK (operational)** | Per-entry-tree example string `docs/project/backlog/BD-NNN.md` — admits BD-NNN as a project-side per-entry file pattern. **Cross-check:** `project-template/docs/project/backlog/_rules.md` L14 declares the per-entry regex `^TD-\d+\.md$` (BD-NNN.md is NOT admissible). The cite is operationally wrong. | **BEFORE:** "Per-entry tree files (`docs/project/backlog/BD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-*.md`, including each stream's `_rules.md`, `_intro.md`, `_toc.md`, `_format.md`..." **AFTER:** "Per-entry tree files (`docs/project/backlog/TD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-*.md`, including each stream's `_rules.md`, `_intro.md`, `_toc.md`, `_format.md`..." — replace `BD-NNN.md` with `TD-NNN.md` per project-side rule. |

**Note:** Phase 1 §3.33.1 / QS-17 listed this as AMBIGUOUS pending Phase
2 disambiguation. Per `_rules.md` L14 regex (positive boundary statement
that BD-NNN.md does NOT match `^TD-\d+\.md$`), the admission is wrong
and the disposition is LEAK.

### §4.28 — `project-template/skills/boundary-investigation/SKILL.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.34.1 (L33) | **AMBIGUOUS** | "The audit BD-175 (P-missed-7) documented the regression mechanism this..." Reference is to a worked example anchored in pack BD-175. **Per Rule 3 test:** (1) Does the client agent NEED this reference to understand boundary-investigation? Possibly — P-missed-7 is the pack memory rule the skill operationalizes for clients, and BD-175 is the worked example. (2) Conveyable without pack reference? Possibly — the worked-example mechanism could be described without the BD label. **Surfaced as AMBIGUOUS §6.2.** | Pending §6.2 user decision. |
| A-3.34.2 (L169) | **AMBIGUOUS** | "## Worked example (BD-175 V1 anti-pattern)" — section header. Same disposition class as A-3.34.1. | Pending §6.2 user decision. |

### §4.29 — `project-template/skills/python-data-architecture/SKILL.md` / `python-server-architecture/SKILL.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.35.1 / A-3.36.1 | **WASTE** | "skill, split in v11.0 by BD-141 (the `python_data_marker_detected()` / load predicate) and BD-143 (the trinity SKILL.md split..." — pack-history of how skill split happened. | **BEFORE:** "...split in v11.0 by BD-141 (the `python_data_marker_detected()` load predicate) and BD-143 (the trinity SKILL.md split into..." **AFTER:** "...split in v11.0 (the `python_data_marker_detected()` load predicate and the trinity SKILL.md split into..." Drop BD-141 and BD-143 parentheticals. |

### §4.30 — `project-template/skills/python-observability-patterns/SKILL.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.37.1 (L20) | **WASTE** | "(see `docs/pack/PLATFORM-SKILLS.md` Intersection table; BD-162)." | **BEFORE:** "...Intersection table; BD-162)." **AFTER:** "...Intersection table)." |

### §4.31 — `project-template/skills/swift-best-practices/SKILL.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.38.1 (L92) | **WASTE** | "(AsyncStream payload design — relocated to `swift-concurrency-patterns` as part of the BD-158 split.)" | **BEFORE:** "...as part of the BD-158 split.)" **AFTER:** "...as part of the v11.0 split into a separate skill.)" |

### §4.32 — `project-template/skills/swift-concurrency-patterns/SKILL.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.39.1 (L188) | **LEGITIMATE** | "a TD-TBD comment naming the upstream issue / version that..." — operational TD-TBD discipline. | KEEP. |

### §4.33 — `project-template/docs/project/backlog/_intro.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.40.1 (L3) | **LEGITIMATE** | "docs/project/backlog/<TD-NNN>.md per-entry file" — project-side per-entry path pattern. | KEEP. Project-side correct. |
| A-3.40.2 (L10) | **LEGITIMATE** | "tree at `docs/project/backlog/`. The per-entry tree is where TD-NNN..." | KEEP. |
| A-3.40.3 (L16-18) | **LEGITIMATE** | "TD-NNN inventory. / For a single entry, read the per-entry file directly at / `docs/project/backlog/<TD-NNN>.md`." | KEEP. |
| A-3.40.4 (L24-26) | **LEGITIMATE** | "Find the highest existing `TD-NNN`, / increment by 1, write a new per-entry file at / `docs/project/backlog/TD-NNN.md`." | KEEP. |
| A-3.40.5 (L34) | **LOCKED (F3)** | Cross-references list admits BD-NNN. | Per §3.3 F3. |

### §4.34 — `project-template/docs/project/backlog/_rules.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.41.1 (L14-15) | **LEGITIMATE** | Filename regex `^TD-\d+\.md$` — explicit boundary statement. Project-side correct. | KEEP. |
| A-3.41.2 (L22) | **LEGITIMATE** | "`**TD-NNN — <Title>**`." — entry header form. | KEEP. |

### §4.35 — `project-template/docs/project/changelog/_format.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.42.1 (L23) | **LEGITIMATE** | "Backlog items addressed: TD-NNN resolved. TD-NNN, TD-NNN" — project-side changelog format. | KEEP. |
| A-3.42.2 (L25) | **LEGITIMATE** | "TD-NNN–TD-MMM created from §N.M audit." | KEEP. |

### §4.36 — `project-template/docs/project/changelog/_rules.md`

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.43.1 (L18) | **WASTE** | "`scripts/lib/per-entry/_lib.sh` post-BD-164-retro Option B" — pack-history cite. | **BEFORE:** "...`scripts/lib/per-entry/_lib.sh` post-BD-164-retro Option B" **AFTER:** "...`scripts/lib/per-entry/_lib.sh`" |

### §4.37 — `supporting-docs/METHODOLOGY.md`

Client-shipped via init-project.sh stage S6. ~26 findings.

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.44.1 (L211) | **LEGITIMATE** | "TD-TBD in any" — operational. | KEEP. |
| A-3.44.2 (L386-388) | **LOCKED (F2.e)** | Parser regex admits `BD-\d+`. | Per §3.2 F2.e. |
| A-3.44.3 (L394) | **LEGITIMATE** | "- TD-029" example in Dependencies bullet. Project-side correct. | KEEP. |
| A-3.44.4 (L1168-1176) | **LEGITIMATE** | Typed-deferral block (`// TODO(scope): TD-TBD`, etc.) for Swift and Python. | KEEP. |
| A-3.44.5 (L1190-1192) | **LEGITIMATE** | "TD-TBD sentinel: coder always writes `TD-TBD` ..." | KEEP. |
| A-3.44.6 (L1202-1208) | **LEGITIMATE** | BACKLOG-item-format template TD-NNN. **Note:** Inventory §3.44.6 references "phase N, phase N.M (v11.0 additive), TD-NNN, or external condition" in the Blockers field — this is project-side correct (no BD-NNN admitted). | KEEP. |
| A-3.44.7 (L1248) | **LEGITIMATE** | "TD-NNN blocker: does that item have Status: Resolved?" | KEEP. |
| A-3.44.8 (L1255) | **LEGITIMATE** | "TD-NNN is now unblocked by Phase N completion." | KEEP. |
| A-3.44.9 (L1260-1261) | **LEGITIMATE** | "Run TD-TBD grep check" | KEEP. |
| A-3.44.10 (L1283-1320) | **LEGITIMATE** | Full Resolution path decision logic (Direct close / Path 1 / Path 2 / Path 3-forbidden). Path 2 target `phase-N.M` (task). User-locked Rule 3 compliant. | KEEP entirely. |
| A-3.44.11 (L1295-1307) | **LEGITIMATE** | Explicit Path 1 / Path 2 verbs + carriers. | KEEP. |
| A-3.44.12 (L1313-1320) | **LEGITIMATE** | "Path 3 is forbidden... no `--fold-into` flag." | KEEP. |
| A-3.44.13 (L1325-1338) | **LEGITIMATE** | Procedure 2 Post-session processing TD-TBD discipline. | KEEP. |
| A-3.44.14 (L1348-1349) | **LEGITIMATE** | "grep -rn \"TD-TBD\" ." | KEEP. |
| A-3.44.15 (L1375) | **LEGITIMATE** | TD-NNN Unblocked discipline. | KEEP. |
| A-3.44.16 (L1377) | **LEGITIMATE** | TD-NNN unblock review. | KEEP. |
| A-3.44.17 (L1393) | **WASTE** | "Relocated to `INSTALL-PROCEDURES.md` per BD-059." | **BEFORE:** "...per BD-059." **AFTER:** "Relocated to `INSTALL-PROCEDURES.md`. See that file for Procedure 5..." Drop BD-059 cite. |
| A-3.44.18 (L1422) | **WASTE** | "(as of BD-048) drives Form-I follow-ups" | **BEFORE:** "active dimension and (as of BD-048) drives Form-I follow-ups for any" **AFTER:** "active dimension and drives Form-I follow-ups for any" |
| A-3.44.19 (L1475) | **LEGITIMATE** | "Cancel TD-NNN" / "Deprecate TD-NNN" — operational. | KEEP. |
| A-3.44.20 (L1483) | **LEGITIMATE** | "names this TD-NNN; present each to you" | KEEP. |
| A-3.44.21 (L1492) | **LEGITIMATE** | "coder \| Write TD-TBD deferral comments..." | KEEP. |
| A-3.44.22 (L1496) | **LEGITIMATE** | "PM chat \| Write and update BACKLOG.md after user approval; replace TD-TBD with TD-NNN..." | KEEP. |
| A-3.44.23 (L1564) | **LEGITIMATE** | "Deferral comments in source \| Writes TD-TBD only" | KEEP. |
| A-3.44.24 (L1583) | **LEGITIMATE** | "Adding, modifying, or removing deferral comments in source files (TD-TBD → TD-NNN)" | KEEP. |
| A-3.44.25 (L1675) | **WASTE** | "(post-BD-042 relocation)" pack-history. | **BEFORE:** "(post-BD-042 relocation), with `BACKLOG.md` and `STATUS.md` remaining" **AFTER:** "(post-relocation), with `BACKLOG.md` and `STATUS.md` remaining" |
| A-3.44.26 (L1712) | **LEGITIMATE** | "run TD-TBD grep, run orphan audit..." | KEEP. |

### §4.38 — `supporting-docs/INSTALL-PROCEDURES.md`

Client-shipped at S6. 6 findings, all WASTE.

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.45.1 (L24) | **WASTE** | "(retired in v11 per BD-121)" | **BEFORE:** "(retired in v11 per BD-121). The project-side canonical location is" **AFTER:** "(retired in v11). The project-side canonical location is" |
| A-3.45.2 (L225) | **WASTE** | "HISTORICAL — sunset in v11 (BD-121)." | **BEFORE:** "HISTORICAL — sunset in v11 (BD-121)." **AFTER:** "HISTORICAL — sunset in v11." |
| A-3.45.3 (L228) | **WASTE** | "migrator framework (BD-119, `scripts/lib/migrator-core.sh` +" | **BEFORE:** "(BD-119, `scripts/lib/migrator-core.sh` +" **AFTER:** "(`scripts/lib/migrator-core.sh` +" |
| A-3.45.4 (L229) | **WASTE** | "the BD-088 customization-preservation library" | **BEFORE:** "the BD-088 customization-preservation library" **AFTER:** "the customization-preservation library" |
| A-3.45.5 (L664) | **WASTE** | "Apply trinity rule for tool-config parity (per BD-059 success" | **BEFORE:** "(per BD-059 success criterion)" **AFTER:** drop the parenthetical |
| A-3.45.6 (L898) | **WASTE** | "HISTORICAL — sunset in v11 (BD-121)." | Same as A-3.45.2. |

### §4.39 — `supporting-docs/MIGRATION-v10-to-v11.md`

**SURFACED AS AMBIGUOUS — see §6.3.** This file is NOT client-shipped at
S6 per Phase 1 inventory §3.46 ("supporting-docs/MIGRATION-v10-to-v11.md
edit which is a pre-install reference not copied to clients"). It is a
user-facing migration guide used pre-install.

Token economy still applies (the file IS in `supporting-docs/`), but BD
references in a migration guide are exactly the case named in
`feedback_client_facing_token_economy` worked-examples as
"JUSTIFIED" (`MIGRATION-vX-to-vY.md describing what changed in pack
version upgrades — clients need to know about migration impacts`).

**Triage tension:** the cites cluster into two classes:

- **Class A — broad migration narrative (BD-088, BD-119, BD-101,
  BD-142, BD-148 cites tied to migration mechanism descriptions):**
  Arguably LEGITIMATE per the worked example — migration-impact disclosure.
- **Class B — fine-grained pack-implementation BD cites that don't
  affect the migration narrative (BD-035 details, BD-095, BD-147):**
  Arguably WASTE — descriptive over-specification.

**Recommendation:** Surface to user as AMBIGUOUS §6.3 below. Default
position: keep Class A cites; remove Class B cites. User to confirm.

Per-finding draft dispositions (pending §6.3 user decision):

| # | Draft disposition | Inventory ref | Rationale |
|---|---|---|---|
| A-3.46.1 (L10-11) | **LEGITIMATE (Class A)** | "BD-042 doc relocation tail. Driven by `scripts/migrate-v10-to-v11.sh` (BD-085)." | Migration-step framing. |
| A-3.46.2 (L18) | **LEGITIMATE (Class A)** | "in v11 (BD-121); v9 is no longer supported." | Migration history (v9 sunset). |
| A-3.46.3 (L41) | **LEGITIMATE (Class A)** | "BD-088 customization-preservation contract" | Migration-mechanism description. |
| A-3.46.4 (L44) | **LEGITIMATE (Class A)** | "BD-042 relocation tail" | Migration step. |
| A-3.46.5 (L68) | **WASTE (Class B)** | "(BD-109 client-side, BD-110 pack-side) is on the v11.x roadmap" | Roadmap chatter; not migration-impact. |
| A-3.46.6 (L76) | **WASTE (Class B)** | "shipped in v11.0 by BD-095" | Pack-implementation detail. |
| A-3.46.7 (L83) | **WASTE (Class B)** | "## Skill model changes (BD-142, BD-148)" | Pack BD numbers in section header — replace with descriptive heading. |
| A-3.46.8 (L114) | **WASTE (Class B)** | "Python skill split shipped as BD-035" | Pack-implementation detail. |
| A-3.46.9 (L146) | **LEGITIMATE (Class A)** | "per the BD-088 customization mechanism" | Migration mechanism. |
| A-3.46.10 (L152) | **LEGITIMATE (Class A)** | "preserved by the BD-088 customization-preserve sidecar mechanism" | Migration mechanism. |
| A-3.46.11 (L156) | **WASTE (Class B)** | "Custom agents column header rename (BD-142 F3 / BD-148)" | Pack-implementation detail. |
| A-3.46.12 (L162) | **LEGITIMATE (Class A)** | "the BD-088 sidecar mechanism preserves the" | Migration mechanism. |
| A-3.46.13 (L177) | **LEGITIMATE (Class A)** | "BD-088 mechanism" | Migration mechanism. |
| A-3.46.14 (L181) | **WASTE (Class B)** | "BD-035 Python split" | Pack-implementation detail. |
| A-3.46.15 (L186) | **WASTE (Class B)** | "(it landed in v11.0 with BD-035)" | Pack-history. |
| A-3.46.16 (L188) | **WASTE (Class B)** | "PLAN-SKILL-DIMENSIONS.md BD-147" | Pack plan-doc cite. |
| A-3.46.17 (L191-194) | **WASTE (Class B)** | "BD-136 trinity-marker non-overlap" section header | Pack BD in header. |
| A-3.46.18 (L199) | **WASTE (Class B)** | "does NOT use the BD-136" | Pack-implementation detail. |
| A-3.46.19 (L203) | **WASTE (Class B)** | "BD-143 to describe the 5+3 model" | Pack-implementation detail. |
| A-3.46.20 (L209) | **WASTE (Class B)** | "list change only for the BD-035 Python split case" | Pack-implementation detail. |
| A-3.46.21 (L213-214) | **WASTE (Class B)** | "BD-088 PLATFORM-SKILLS.md customization-preservation (sidecar-based) and BD-136 trinity-marker preservation" | Pack-implementation detail. (Class A overlap with BD-088 but the redundant cite is WASTE here.) |
| A-3.46.22 (L258) | **LEAK (operational)** | "One Markdown file per entry (e.g., `docs/project/backlog/BD-NNN.md`," — same admission pattern as A-3.33.1; project-side `_rules.md` regex bars BD-NNN.md. | **BEFORE:** "One Markdown file per entry (e.g., `docs/project/backlog/BD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-<slug>.md`)" **AFTER:** "One Markdown file per entry (e.g., `docs/project/backlog/TD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-<slug>.md`)" — replace BD-NNN.md with TD-NNN.md. |
| A-3.46.23 (L343) | **WASTE (Class B)** | "mirror-vs-source treatment in the BD-088 customization-preserve" | Pack-implementation detail. |
| A-3.46.24 (L389) | **WASTE (Class B)** | "share the BD-095 sentinel" | Pack-implementation detail. |
| A-3.46.25 (L394) | **LEGITIMATE (Class A)** | "Pre-flight (pack valid, BD-088 lib present..." | Migration-stage description. |
| A-3.46.26 (L396) | **LEGITIMATE (Class A)** | "Initialize BD-088 customization-preserve state" | Migration stage. |
| A-3.46.27 (L397) | **LEGITIMATE (Class A)** | "Dispatch v10 → v11 changes via BD-088" | Migration stage. |
| A-3.46.28 (L398) | **LEGITIMATE (Class A)** | "S4a \| BD-104 rename `IMPLEMENTATION_PLAN.md` → ..." | Migration stage; BD-104 names the specific rename action. |
| A-3.46.29 (L399) | **LEGITIMATE (Class A)** | "S4b \| BD-042 relocation tail" | Migration stage. |
| A-3.46.30 (L413) | **LEGITIMATE (Class A)** | "BD-088 library missing under pack" | Error-table entry — migration impact. |
| A-3.46.31 (L415) | **LEGITIMATE (Class A)** | "BD-101 verification gate" | Migration error-handling. |
| A-3.46.32 (L417) | **LEGITIMATE (Class A)** | "BD-101 verification gates." | Migration error-handling. |
| A-3.46.33 (L445) | **WASTE (Class B)** | "(BD-059 / BD-088 contract)" | Pack contracts — describe inline instead. |
| A-3.46.34 (L576) | **WASTE (Class B)** | "## BD-059 lessons learned" | Pack BD in section header. |
| A-3.46.35 (L579-581) | **WASTE (Class B)** | "BD-121) had a defect class that shapes (BD-059 in the BACKLOG)." | Pack-implementation detail. |
| A-3.46.36 (L595-596) | **WASTE (Class B)** | "validate-pack Check 25 (BD-089) runs a / 4-fixture synthetic" | Pack-implementation detail. |
| A-3.46.37 (L599) | **WASTE (Class B)** | "BD-083." | Pack-history. |
| A-3.46.38 (L656) | **WASTE (Class B)** | "(BD-088 `claude-settings` allowlist)" | Pack-implementation detail. |
| A-3.46.39 (L711) | **WASTE (Class B)** | "(BD-059 class regression)" | Pack-history. |
| A-3.46.40 (L722) | **WASTE (Class B)** | "BD-059 class" | Pack-history. |

### §4.40 — `supporting-docs/SETUP-NEW.md`

Client-relevant pre-install. NOT shipped at S6 per inventory.

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.47.1 (L11) | **WASTE** | "v9->v10 migrator was sunset in v11 per BD-121" | **BEFORE:** "per BD-121" **AFTER:** Drop the parenthetical / cite. |
| A-3.47.2 (L94) | **WASTE** | "v9.x is no longer supported per BD-121" | Same. |
| A-3.47.3 (L156) | **WASTE** | "Step 5 by BD-047 (Phase 3-B)" | **BEFORE:** "this Step 5 by BD-047 (Phase 3-B). Step numbering is preserved..." **AFTER:** "this Step 5. Step numbering is preserved..." |
| A-3.47.4 (L466) | **WASTE** | "migrator was sunset in v11 per BD-121" | Drop cite. |

### §4.41 — `supporting-docs/SETUP-EXISTING.md`

Client-relevant pre-install. NOT shipped at S6.

| # | Disposition | Inventory ref | BEFORE / AFTER |
|---|---|---|---|
| A-3.48.1 (L150) | **WASTE** | "Step 5 by BD-047 (Phase 3-B)" | Same as A-3.47.3. |

### §4.42 — Surface B summary

All Surface B findings are covered by F4/F5 lock (§3.4). No additional
Surface B triage needed:

- **scripts/init-project.sh L820-833** — LOCKED via F4/F5.
- **scripts/pack-help.sh** — read-only resolution, not a copy violation
  (per Phase 1 §4.2). LEGITIMATE.
- **scripts/migrate-v10-to-v11.sh** — no findings.
- **scripts/pack-tracker.sh + others** — read-only surface-detection,
  not copies. LEGITIMATE.
- **scripts/lib/** — pack-internal libraries, no copies. LEGITIMATE.
- **scripts/tests/** — test-fixture provisioning into scratch repos,
  not client install. LEGITIMATE.

---

## §5 — Summary tables

### §5.1 — Counts per disposition category per file

| File | LEAK | VIOLATION | WASTE | LEGITIMATE | AMBIGUOUS | LOCKED (recap) | Total findings |
|---|---|---|---|---|---|---|---|
| `templates-archive/v11.0/INDEX.md` | 0 | 0 | 0 | 0 | 0 | 1 (F1.a) | 1 |
| `templates-archive/v11.0/bd-v11.0/SCHEMA.md` | 0 | 0 | 0 | 10 | 0 | 1 (F1.c file-wide) | 10 |
| `templates-archive/v11.0/td-v11.0/SCHEMA.md` | 1 | 0 | 0 | 1 | 0 | 0 | 2 |
| `templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md` | 0 | 0 | 0 | 3 | 0 | 0 | 3 |
| `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | 0 | 0 | 0 | 2 | 0 | 2 (F2.a) | 4 |
| `templates-archive/v11.0/inbound-v11.0/SCHEMA.md` | 0 | 0 | 2 | 0 | 2 | 0 | 4 |
| `templates-archive/v11.0/forms/work-item.yml` | 0 | 0 | 1 | 0 | 0 | 5 (F2.c) | 6 |
| `templates-archive/v11.1/INDEX.md` | 0 | 0 | 12 | 0 | 0 | 1 (F1.b) | 13 |
| `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | 0 | 0 | 23 | 1 | 0 | 2 (F2.b) | 26 |
| `templates-archive/README.md` | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | 0 | 0 | 0 | 2 | 1 | 4 (F2.d) | 7 |
| `project-template/tracker.toml.project-example` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `project-template/.gitignore` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` (trinity) | 0 | 0 | 3 | 7 | 0 | 0 | 10 |
| `project-template/.gemini/.env.example` | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| `project-template/.codex/config.toml{,.example}` | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| `project-template/docs/pack/PM-CHAT.md` | 0 | 0 | 3 | 15 | 0 | 0 | 18 |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 0 | 0 | 0 | 2 | 0 | 0 | 2 |
| `project-template/docs/pack/HELP-FRAGMENT.md` | 0 | 0 | 0 | 3 | 0 | 0 | 3 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | 0 | 0 | 6 | 1 | 0 | 0 | 7 |
| `project-template/docs/pack/prompts/*.md` | 0 | 0 | 0 | 9 | 0 | 0 | 9 |
| `project-template/.{claude,gemini,codex}/agents/coder.{md,toml}` | 0 | 0 | 0 | 3 | 0 | 0 | 3 |
| `project-template/{.claude,.codex,.gemini,project-template}/skills/pm-startup/SKILL.md` + `commands/pm-startup.toml` | 0 | 0 | 0 | 4 | 0 | 0 | 4 |
| `project-template/skills/audit-methodology/SKILL.md` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `project-template/skills/boundary-investigation/SKILL.md` | 0 | 0 | 0 | 0 | 2 | 0 | 2 |
| `project-template/skills/python-data-architecture/SKILL.md` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `project-template/skills/python-server-architecture/SKILL.md` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `project-template/skills/python-observability-patterns/SKILL.md` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `project-template/skills/swift-best-practices/SKILL.md` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `project-template/skills/swift-concurrency-patterns/SKILL.md` | 0 | 0 | 0 | 1 | 0 | 0 | 1 |
| `project-template/docs/project/backlog/_intro.md` | 0 | 0 | 0 | 4 | 0 | 1 (F3) | 5 |
| `project-template/docs/project/backlog/_rules.md` | 0 | 0 | 0 | 2 | 0 | 0 | 2 |
| `project-template/docs/project/changelog/_format.md` | 0 | 0 | 0 | 2 | 0 | 0 | 2 |
| `project-template/docs/project/changelog/_rules.md` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `supporting-docs/METHODOLOGY.md` | 0 | 0 | 4 | 21 | 0 | 1 (F2.e) | 26 |
| `supporting-docs/INSTALL-PROCEDURES.md` | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| `supporting-docs/MIGRATION-v10-to-v11.md` | 1 | 0 | (deferred §6.3) | (deferred §6.3) | 40 (all rows §6.3) | 0 | 40 |
| `supporting-docs/SETUP-NEW.md` | 0 | 0 | 4 | 0 | 0 | 0 | 4 |
| `supporting-docs/SETUP-EXISTING.md` | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| `scripts/init-project.sh` (Surface B) | 0 | 0 | 0 | 0 | 0 | 4 (F4/F5) | 4 |
| **TOTAL** | **3** | **0** | **78** | **93** | **45** | **22** | **241** |

**Notes on totals:**

- "LOCKED (recap)" counts the inventory finding rows that fall under the
  11 small-group dispositions in §3 (sub-locations like F1.c file-wide
  are counted as 1 lock action, not 10 per-line; F1.b INDEX row counts as
  1; F4/F5 counts the 4 init-project.sh rows).
- "AMBIGUOUS" total of 45 includes all 40 rows of MIGRATION-v10-to-v11.md
  pending §6.3 resolution (Class A vs Class B), plus 2 rows in
  boundary-investigation/SKILL.md (§6.2), plus 2 rows in
  inbound-v11.0/SCHEMA.md (§6.1), plus the trinity A-3.12.4 row (§6.1).
- The 241 total slightly exceeds the ~140 raw findings in Phase 1
  because some rows are listed under multiple locations (e.g., the
  trinity files have 3 mirrors).

### §5.2 — Disposition totals (de-duplicated by sub-location)

| Disposition | Count |
|---|---|
| **LEAK (operational)** | 3 (A-3.3.2 inherited, A-3.33.1 audit-methodology BD-NNN.md, A-3.46.22 MIGRATION BD-NNN.md) |
| **VIOLATION (cross-side substitution)** | 0 (all in F4/F5 lock) |
| **WASTE (unnecessary explanatory)** | 78 |
| **LEGITIMATE (necessary explanatory)** | 93 |
| **AMBIGUOUS (surface to user §6)** | 45 (40 MIGRATION + 2 boundary-investigation + 2 inbound + 1 work-item.yml L18) |
| **LOCKED (recap, §3)** | 22 (counted per finding row, including F1/F2/F3/F4-F5) |
| **TOTAL inventory rows** | 241 |

### §5.3 — High-density files by disposition

| File | Primary disposition | Volume |
|---|---|---|
| `supporting-docs/MIGRATION-v10-to-v11.md` | AMBIGUOUS (§6.3) | 40 |
| `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | WASTE (Rule 3) | 23 |
| `supporting-docs/METHODOLOGY.md` | LEGITIMATE (TD lifecycle) + WASTE | 21 LEG / 4 WASTE |
| `project-template/docs/pack/PM-CHAT.md` | LEGITIMATE (Path lifecycle) | 15 LEG / 3 WASTE |
| `templates-archive/v11.1/INDEX.md` | WASTE (BD-185 cites) | 12 |

---

## §6 — AMBIGUOUS surface (user discussion needed before fix-coder)

The following items are SURFACED AS AMBIGUOUS per the audit prompt's
guidance ("DO NOT auto-classify ambiguous cases"). Each requires user
discussion before fix-coder spawn.

### §6.1 — Mention-to-exclude rule (4 finding rows)

**Affected findings:**

- A-3.6.2 `templates-archive/v11.0/inbound-v11.0/SCHEMA.md:17` —
  "(no BD-NNN / TD-NNN). The GH issue number is the identifier." —
  inbound explicitly DOES NOT have BD-NNN ID.
- A-3.6.3 `templates-archive/v11.0/inbound-v11.0/SCHEMA.md:114` —
  "to `BD-NNN` / `TD-NNN`), inbound entries have no pack-side namespace"
- A-3.12.4 `project-template/.github/ISSUE_TEMPLATE/work-item.yml:18` —
  "Pack-development items (BD-NNN) belong in the pack repo, not in this
  project." (EXPLICIT boundary-respect statement in PROJECT-SIDE form.)

**The ambiguity:**

Each of these references mentions `BD-NNN` for the explicit purpose of
EXCLUDING it from the surrounding entity contract. Two readings:

1. **Reading A (strict Rule 1):** Even mention-to-exclude is mention.
   The reference treats BD-NNN as a thing the reader might otherwise
   admit, which itself is operational context. LEAK; remove.

2. **Reading B (boundary-defense legitimization):** The statement is
   a boundary-discipline aid: it explicitly tells the reader/agent that
   BD-NNN is OUT of scope. Particularly useful in PROJECT-SIDE work-item
   form (A-3.12.4), where it deters the kind of "import BD from pack"
   regression that recurs per pack memory `P-missed-7`. LEGITIMATE;
   keep.

**User must decide:** which reading governs?

**Reviewer recommendation (non-binding):** Reading B for A-3.12.4
(project-side form, boundary-defense critical for clients) and Reading
A for A-3.6.2 / A-3.6.3 (pack-archive surface, inbound SCHEMA doesn't
need to teach the client what an inbound IS NOT). But this is exactly
the ambiguity to surface, not auto-classify.

### §6.2 — Pack-history references in `boundary-investigation` skill (2 finding rows)

**Affected findings:**

- A-3.34.1 `project-template/skills/boundary-investigation/SKILL.md:33`
  — "The audit BD-175 (P-missed-7) documented the regression mechanism
  this skill operationalizes."
- A-3.34.2 `project-template/skills/boundary-investigation/SKILL.md:169`
  — "## Worked example (BD-175 V1 anti-pattern)" — section header.

**The ambiguity:**

The `boundary-investigation` skill is loaded by all pack agents to
prevent project-side files from importing pack-only mechanisms. BD-175
is the worked example that drove the skill's creation. Question per
Rule 3:

1. **Does the client agent NEED the BD-175 reference to understand the
   skill?** Arguably yes — the worked example is the load-bearing
   teaching mechanism. Removing the BD label leaves "the audit" /
   "the V1 anti-pattern" without an anchor.

2. **Is the same teaching conveyable WITHOUT mentioning a pack BD?**
   Yes — the worked example can be retold ("In a prior incident, a
   project-side trinity file acquired a `PACK-AGENTS.md` reference via
   a review-fix commit when the project-side SSOT was
   `docs/pack/PM-CHAT.md`...") without the BD label.

**Two readings:**

1. **Reading A:** BD-175 cite is pack-history audit-trail; rephrase
   the worked example inline without the BD label. WASTE; remove.

2. **Reading B:** BD-175 cite is load-bearing teaching anchor; the
   worked example loses concreteness without it. LEGITIMATE; keep.

**User must decide.** Note this affects the entire pattern of how
pack-memory worked-examples reference pack BDs in client-installed
skills.

### §6.3 — `supporting-docs/MIGRATION-v10-to-v11.md` — Class A vs Class B BD cites (40 finding rows)

**Affected findings:** All of A-3.46.1 through A-3.46.40 (40 rows;
A-3.46.22 is the one LEAK already handled in §4.39).

**The ambiguity:**

Pack memory `feedback_client_facing_token_economy` worked-examples
explicitly call out:

> Examples of references that may be justified: `MIGRATION-vX-to-vY.md`
> describing what changed in pack version upgrades — clients need to
> know about migration impacts.

But the MIGRATION file mixes two classes:

- **Class A** — BD cites tied to migration mechanism descriptions
  (BD-088 customization-preserve, BD-119 migrator framework, BD-101
  verification gates, BD-104 rename action, BD-042 doc relocation).
  These document MIGRATION IMPACT — what the migrator does, why,
  recovery on failure. Arguably LEGITIMATE per the worked example.

- **Class B** — Fine-grained pack-implementation BD cites that
  describe pack history but don't affect the migration narrative
  (BD-035 Python skill split rationale, BD-095 sentinel pack-implementation,
  BD-147 plan-doc cite, BD-148 column-header rename pack-history,
  BD-136 trinity-marker pack-implementation, BD-059 lessons-learned
  retrospective, BD-083 reference, BD-089 CI check, BD-109/110
  roadmap, BD-156/157/158 skill split history, BD-141/143
  refactor history). These are pack-archaeology that a user
  performing the migration doesn't need to know.

**Per-class disposition draft (§4.39 above):**

- Class A (LEGITIMATE) rows: 12 (A-3.46.1, .2, .3, .4, .9, .10, .12,
  .13, .25, .26, .27, .28, .29, .30, .31, .32) — actually 16 rows by
  recount.
- Class B (WASTE) rows: 24 rows (the rest, except A-3.46.22 which is
  separately LEAK).

**User must decide:**

1. Is the Class A / Class B split the right framing, or should ALL
   BD cites in MIGRATION-v10-to-v11.md be retained (per token economy
   worked-example allowlist), or ALL removed (per stricter Rule 3
   reading)?

2. If split, are the Class A / Class B draft assignments correct?
   The user may reassign individual rows.

**Note:** MIGRATION-v10-to-v11.md is NOT shipped to clients at S6
(per Phase 1 §3.46 note), so the RAG-context-cost angle of Rule 3
applies weakly. But it IS pre-install reading for clients executing
the migration, so it is still client-facing.

### §6.4 — General class — `MIGRATION-v8-to-v9.md` and `SETUP-NEW.md` / `SETUP-EXISTING.md` — same class as §6.3?

The two SETUP files (A-3.47.* and A-3.48.*) are tentatively triaged as
WASTE in §4.40 / §4.41 (BD-121 cites in v9-sunset notes, BD-047 in
Step 5 numbering). User may want to apply the same Class A / Class B
framing here as in MIGRATION-v10-to-v11.md.

**User must decide:** is the SETUP file BD-121 cite ("v9 sunset per
BD-121") LEGITIMATE migration-history disclosure or WASTE?

**Reviewer recommendation (non-binding):** WASTE — the SETUP files
are user-facing first-time setup guides, not migration narratives.
The reader doesn't need to know which pack BD retired v9.

---

## §7 — Cross-references

### §7.1 — Pack memory entries cited

- `feedback_bd_pack_only_operational_rule` — Rule 1 (operational vs
  explanatory). Path:
  `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_bd_pack_only_operational_rule.md`.
- `feedback_pack_project_separation_of_concerns` — Rule 2 (cross-side
  substitution). Path:
  `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_pack_project_separation_of_concerns.md`.
- `feedback_client_facing_token_economy` — Rule 3 (token economy +
  necessity test). Path:
  `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_client_facing_token_economy.md`.
- `feedback_triage_workflow_protocol` — guidance for surfacing
  ambiguous cases one at a time.
- `feedback_fix_all_review_findings` — default fix-all discipline for
  LEAK / WASTE / VIOLATION findings.
- `P-missed-7` (Pack memory in pack-root trinity `## Pack memory`) —
  boundary investigation methodology underlying Rule 1 and the
  `boundary-investigation` skill cites in §6.2.

### §7.2 — User-locked rules (audit-prompt §6.1)

1. BD entries are PACK-ONLY (operational and explanatory contexts
   separated; Rule 1).
2. TD entries are CLIENT-ONLY (operational TD lifecycle stays in
   client-facing docs).
3. TD lifecycle rules — Path 1, Path 2 with `phase-N.M` target ONLY
   (NOT `Phase-N.Part-x`), Path 3 forbidden.
4. Pack-ops/ is PACK-ONLY (Rule 2).
5. Scripts/ copying pack-ops/ to client install is categorically
   wrong (Rule 2; Surface B / F4-F5 lock).

### §7.3 — 11 user-locked dispositions

- F1 (3 sub-locations) — INDEX segregation + bd-v11.0 PACK-INTERNAL
  header.
- F2 (5 sub-locations) — BD-NNN dependency-grammar admission removal.
- F3 (1 sub-location) — `_intro.md` cross-reference removal.
- F4 + F5 (1 location cluster, 4 finding rows) — init-project.sh S11
  project-template-source.

### §7.4 — Phase 1 inventory file

`maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md`
(782 lines; HEAD `8b4c6076dbc0488f57f44040a83dbf4fe8b1ab5a`).

### §7.5 — Architect doc reference

`maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §1.4
Decision log (D15, D16) — referenced by Phase 1 §6.2 for context on
why D16 carve-out applies to F2.a / F2.c.

### §7.6 — Project-side per-stream contract

`project-template/docs/project/backlog/_rules.md` L14 — filename regex
`^TD-\d+\.md$` (positive boundary statement that BD-NNN.md is NOT a
valid project-side per-entry filename). This is the basis for the
LEAK disposition on A-3.33.1 and A-3.46.22.

### §7.7 — Read-only verification

This report was authored read-only. No source files modified. No
state-changing git verbs invoked. Single Write target: this report
file at
`maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md`.

---

## §8 — End of disposition

Phase 3 (fix-coder) takes over from here for correction implementation
of:

- 11 LOCKED dispositions (§3).
- 78 WASTE findings (§4.* tables).
- 3 LEAK findings (A-3.3.2 inherited, A-3.33.1 audit-methodology BD-NNN.md,
  A-3.46.22 MIGRATION BD-NNN.md).
- Post-§6 user resolution of 45 AMBIGUOUS rows.

LEGITIMATE findings (93) require no action; they are documented here
so the fix-coder confirms NON-removal of the operational TD lifecycle
content, the TD-TBD typed-deferral grammar, and the Path 1 / Path 2 /
Path 3-forbidden lifecycle pattern in client-shipped docs.

End of AUDIT-DISPOSITION-BD-TD-PATH.md.
