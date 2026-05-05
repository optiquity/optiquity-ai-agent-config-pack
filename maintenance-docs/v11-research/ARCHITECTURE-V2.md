# v11 Architecture V2 — Optional Issue-Tracker Integration

**Status.** Architecture proposal, second pass. Refines `ARCHITECTURE.md`
(V1, 2026-04-30). Designed against `DESIGN-BRIEF.md` (the contract; updated
this round with §3.4 priorities and OQ-16 / OQ-17 / OQ-18) plus the original
research inputs `EXTERNAL-RESEARCH.md`, `INTERNAL-INVENTORY.md`, and
`RESEARCH-AUDIT.md`.

**Owner.** Pack-architect agent. Awaiting pack-maintainer review.

**Date.** 2026-04-30 (V2 pass; V1 was the same calendar day, earlier).

**Reading path.** Read V1 first; use this V2 document as a delta on top.
The Change log (§0) is the index. V2 preserves V1's section numbering for
sections 1–17 and adds §18 (P1) through §23 (P6); appendices A–C extend
V1's appendices A–B.

**Out of scope, do-not-revisit.** All `DESIGN-BRIEF.md` §1 hard exclusions
hold. The new §1 update — *no v10 non-opt-in case to design for* — is
absorbed: V2 deletes anything in V1 that hedged for that case.

---

## 0. Change log — V1 → V2

### 0.1 What changed materially

| Area | V1 state | V2 state | Why |
|---|---|---|---|
| Decisions table (§16) | 15 rows D-1..D-15 | 18 rows; D-1..D-15 reaffirmed or superseded; D-4 superseded by D-4-V2 (§4 reshape); D-16, D-17, D-18 added for OQ-16, OQ-17, OQ-18 | New OQs need explicit decisions; new §3.4 priorities force §4 reshape |
| §4 issue templates | Six separate forms (one per entry type) | Two-form *family* model: one composite "Pack work item" form (BD/TD/phase variants behind a Type dropdown gate) plus one composite "Inbound" form (bug-report / feature-request / pack-feedback behind a Category dropdown). External bug-report and feature-request collapse into the Inbound form; phase-epic remains a tracker-managed *system* issue created by Pack/PM Chat, not a user-facing form. | OQ-16 defense (§24) shows the multi-template choice loses on token economy, search/sort/filter, cross-tracker portability, and P2 maintenance ergonomics |
| §4 field structure | All structure was "structured fields where dropdowns enumerate; textareas for the rest" | Adds two structured fields where they pay rent: `td-scope`, `td-severity` move to *labels at intake* via dropdown (already in V1) but also become explicit per-form metadata; `Blockers` and `Unblocks` stay as textarea (line-per-id) — V2 defends this against more-structure and less-structure alternatives. | OQ-17 defense (§25) |
| Entry shape | `template_version` named in `DESIGN-BRIEF.md` §3.1 but had no V1 location | Carried as an HTML comment marker in body (alongside `<!-- pack-id: ... -->`), with a label `template:vN.M` set at intake by the form for cheap query. Both, by design — comment marker is round-trip authoritative; label is queryable. | OQ-18 (§26) |
| §6 forward migration | Issue-by-issue creation; mapping file; markers | Adds a `template_version` write at create time; idempotency unchanged. | P2 propagation needs the version field to function |
| Lifecycle | Implicit in V1 (§4 + §10 + §6) | Explicit per-entry-type state machines in §18 | P1 |
| Maintenance | V1 had `pack tracker doctor` only | V2 adds `pack tracker update-templates` verb in §19 with cadence, propagation rules, and staleness surfacing | P2 |
| Backend extensibility | V1 §13.3 named the file path `scripts/tracker-providers/<name>.sh` | V2 §20 specifies the contract: required interface methods, conformance test suite shape, sample second backend (Linear sketch), tier-of-support graduation rules | P3 |
| Auditability | V1 §17.2 trade-off note only | §21 designs the audit query surface, the chat-side "what changed yesterday?" / "show audit for TD-031" patterns, and the flat-file fallback to `git log` | P4 |
| Verb surface | V1 §6.1 listed three commands; risks scattered | §22 exhaustively enumerates v11's tracker verbs, colloquial mappings, and justifies every concept beyond v10 | P5 |
| Discoverability | Not addressed in V1 | §23 designs `/help`, `pack help`, the colloquial-form router, and the 5-minute onboarding path | P6 |
| §9.7 misroute guard | "Filed a pack-feedback issue" prompt | Same, but routes via the new Inbound form (Category=Workflow Observation) with body fields prefilled | Aligns with §4 reshape |
| §11 license | None new | Reaffirmed; V2 adds nothing. | unchanged |
| Item 8 (v10 non-opt-in backward compat) | V1 §17.1 R9 hinted at v9-era trinity migration risk | V2 deletes that hedging branch; OT is the only v10 project; no "pulls v11 pack updates but never opts in" scenario remains | per `DESIGN-BRIEF.md` §1 update |

### 0.2 Decisions changed (summary; details in §16)

- **Reaffirmed unchanged:** D-1, D-2, D-3, D-5, D-6, D-7, D-8, D-9, D-10, D-11, D-12, D-13, D-14, D-15.
- **Superseded:** D-4 → D-4-V2 (§4 reshape: form-family, not six separate forms).
- **New:** D-16 (OQ-16, multi-template strategy), D-17 (OQ-17, structure depth), D-18 (OQ-18, template_version placement).

### 0.3 Sections changed materially

- §4 (issue template schemas) — restructured per D-4-V2.
- §6.2 (forward mapping) — adds `template_version` write step.
- §16 (decisions) — three new rows; D-4 row marked superseded.
- §17.1 R9 — deleted (v10 non-opt-in moot).

### 0.4 Sections added

- §18 — Entry lifecycle state machines (P1).
- §19 — Maintenance ergonomics: template/label propagation (P2).
- §20 — Backend extensibility contract (P3).
- §21 — Auditability (P4).
- §22 — Cognitive load floor: verb surface (P5).
- §23 — Discoverability (P6).
- §24 — OQ-16 defense.
- §25 — OQ-17 defense.
- §26 — OQ-18 resolution.

### 0.5 Sections preserved verbatim

- §1 (architectural overview) — `Read V1 §1`.
- §2 (provider abstraction) — `Read V1 §2`.
- §3 (config / detection / trinity) — `Read V1 §3` with one V2 addendum noted in §16/D-6.
- §5 (dependency model) — `Read V1 §5`.
- §6 except §6.2 — `Read V1 §6`; §6.2 addendum below.
- §7 (chat orchestration) — `Read V1 §7`.
- §8 (agent reads) — `Read V1 §8`.
- §9 (failure UX) — `Read V1 §9` with a small §9.7 routing wording change.
- §10 (external triage) — `Read V1 §10`.
- §11 (license) — `Read V1 §11`.
- §12 (token economy) — `Read V1 §12`.
- §13 (per-CLI matrix) — `Read V1 §13`.
- §14 (tracker compatibility) — `Read V1 §14`.
- §15 (pre-existing tracker) — `Read V1 §15`.

### 0.6 Things V2 deliberately does not change

- The TrackerProvider operation set, capability schema, error model.
- Mode detection signal (`tracker.toml`).
- Trinity `## Document locations` Source-column addition.
- Migration script overall shape.
- Mirror file behavior.
- LCD = `gh`; per-CLI MCP = optional acceleration.
- Pack Chat / PM Chat exclusive write authority.
- Reverse-migration mandatory.

---

## 1–3. Architectural overview, provider abstraction, config (preserved)

V1 §1, §2, §3 stand. Read V1 directly for these. Decisions D-1, D-2, D-5,
D-6 are reaffirmed in §16 below.

The only V2 addendum is in §3.3 (trinity Document-locations table): in V2
the table is the propagation surface for the new `template_version` label
described in §26, but the *shape* of the table (Source column added) does
not change.

---

## 4. Issue template schemas (V2 — superseded V1 §4)

This section replaces V1 §4 in full. The V1 choice — six separate
`.github/ISSUE_TEMPLATE/*.yml` forms — is superseded by D-4-V2 below.
The V2 reshape comes out of §24 (OQ-16 defense). Read §24 first if the
rationale is not obvious; the section here is the spec.

### 4.1 The form family

Two user-facing issue forms ship in the pack repo, with parallel copies
in client projects when tracker mode is enabled:

1. **`.github/ISSUE_TEMPLATE/work-item.yml` — "Pack work item."** Single
   composite form for *pack-managed work*. The first field is a Type
   dropdown (`bd`, `td`, `phase-epic-skeleton`). The dropdown drives
   conditional-feeling field visibility (GH issue forms do not support
   true conditional fields, so the form lists all fields and labels each
   "(required if Type = X)" in help text; the auto-routing label set is
   driven by the Type pick). This is the entry form for BD and TD work.
2. **`.github/ISSUE_TEMPLATE/inbound.yml` — "Inbound report or
   feedback."** Single composite form for *external* and
   *upstream-feedback* reports. The first field is a Category dropdown
   (`bug`, `feature-request`, `pack-feedback-workflow`,
   `pack-feedback-prompt`, `pack-feedback-agent-perf`,
   `pack-feedback-friction`, `pack-feedback-open-question`). The
   dropdown sets labels at intake (`external + type:bug`, `external +
   type:feature`, `pack-feedback + pf-category:<value>`).

Phase-epic issues are *not* user-facing forms. They are created
exclusively by Pack/PM Chat at migration time or when the chat
introduces a new phase. A skeletal `phase-epic-skeleton` Type exists in
`work-item.yml` as a fallback for the rare case a Pack/PM Chat needs a
hand-edited create form (e.g., recreating a deleted phase epic outside
the migration script). Day-to-day, phase epics are created by
`provider.create()` calls from the chat with a fixed payload (§4.5).

A `.github/ISSUE_TEMPLATE/config.yml` ships next to the two forms with
`blank_issues_enabled: false` and a `contact_links` block pointing
casual question askers to GH Discussions. The blank-issue ban is
intentional: it keeps unrouted intake out of the triage queue.

### 4.2 work-item.yml — fields

```yaml
name: Pack work item (BD / TD / phase-epic)
description: Pack-development backlog item (BD-NNN), project technical-debt item (TD-NNN), or a phase epic skeleton.
title: "<TYPE>: <short title>"
labels: ["work-item", "needs-triage"]
body:
  - type: dropdown
    id: wi-type
    attributes:
      label: Type
      description: Pick BD for pack-development items; TD for project items; phase-epic for hand-edited phase skeletons (rare).
      options:
        - bd
        - td
        - phase-epic-skeleton
    validations:
      required: true
  - type: dropdown
    id: wi-kind
    attributes:
      label: Kind
      description: Required for BD and TD. The METHODOLOGY § Part 7 type ("feat", "fix", "refactor", "docs", "chore", "infra").
      options: [feat, fix, refactor, docs, chore, infra]
    validations:
      required: false
  - type: dropdown
    id: wi-status
    attributes:
      label: Initial status
      description: Defaults to Open. The chat changes status via labels post-creation.
      options: [Open, Unblocked, Resolved, Cancelled, Deprecated]
      default: 0
    validations:
      required: true
  - type: dropdown
    id: wi-td-scope
    attributes:
      label: TD scope (TD only)
      description: Required for Type=td. Drives the `scope:*` label.
      options: [phase-N, dependency, feature, perf, version]
    validations:
      required: false
  - type: dropdown
    id: wi-td-severity
    attributes:
      label: TD severity (TD only, for KNOWN GAP variant)
      description: Optional. Drives the `severity:*` label.
      options: [critical, functional, polish]
    validations:
      required: false
  - type: input
    id: wi-phase-number
    attributes:
      label: Phase number (phase-epic-skeleton only)
      description: Required for Type=phase-epic-skeleton. Otherwise leave blank.
  - type: textarea
    id: wi-blockers
    attributes:
      label: Blockers
      description: One per line. Either an issue id (BD-NNN, TD-NNN, #N) or a `phase-N` token. The chat resolves these to first-class links/sub-issue parents post-creation.
  - type: textarea
    id: wi-unblocks
    attributes:
      label: Unblocks
      description: Informational; one issue id per line. Inverse of Blockers across the dataset.
  - type: input
    id: wi-file-symbol
    attributes:
      label: File / Symbol
      description: Affected path or symbol (free-form).
  - type: textarea
    id: wi-description
    attributes:
      label: Description
    validations:
      required: true
  - type: textarea
    id: wi-context
    attributes:
      label: Context
  - type: textarea
    id: wi-resolution
    attributes:
      label: Resolution
      description: Filled when status flips to Resolved.
  - type: markdown
    attributes:
      value: |
        <!-- pack-id: PENDING -->
        <!-- template_version: v11.0.0/work-item -->
        <!-- pack-version: v11 -->
```

The trailing `markdown` block emits a literal HTML comment trio into the
issue body. Two facts come together here:

- **`pack-id`** is set to `PENDING` at intake by the user; the chat
  rewrites it to the canonical `BD-NNN` / `TD-NNN` during triage,
  consulting the same counter algorithm (`provider.search(in:title
  "BD-")` max+1) that v10 used on `BACKLOG.md`. (External users do not
  pick BD numbers; the chat does.)
- **`template_version`** is set at intake to the literal version string
  matching the form file path. This is one of two carriers for the
  `template_version` field; the other is a label, set by the form's
  `labels:` key. See §26.
- **`pack-version`** is the major pack version that authored the form.
  Consulted by `pack tracker update-templates` to identify entries that
  were created on an older major (§19).

Auto-routing labels (added by the form's `labels:` key plus chat
post-processing on the wi-type / wi-kind / wi-status / wi-td-scope /
wi-td-severity dropdowns):

| Dropdown | Label written | Removed when |
|---|---|---|
| Always | `work-item`, `needs-triage`, `template:bd-v11.0.0` (or `template:td-v11.0.0` after triage) | `needs-triage` removed at triage; `template:*` updated by `pack tracker update-templates` |
| `wi-type=bd` | `bd-entry` (added at triage) | never (provenance) |
| `wi-type=td` | `td-entry` (added at triage) | never |
| `wi-type=phase-epic-skeleton` | `phase-epic` (added at triage) | never |
| `wi-kind` | `type:<feat\|fix\|refactor\|docs\|chore\|infra>` | never |
| `wi-status=Open` | `status:open` | when status flips |
| `wi-td-scope` | `scope:phase-N` / `scope:dependency` / `scope:feature` / `scope:perf` / `scope:version` | never |
| `wi-td-severity` | `severity:critical` / `severity:functional` / `severity:polish` | never |

The `template:bd-v11.0.0` vs `template:td-v11.0.0` distinction is
written by the chat at triage based on `wi-type`. At intake the form
applies a coarser `template:work-item-v11.0.0` label; the chat
specializes during triage.

### 4.3 inbound.yml — fields

```yaml
name: Inbound report or feedback
description: External bug, feature request, or pack-feedback observation from a project user.
title: "<CATEGORY>: <short title>"
labels: ["inbound", "needs-triage"]
body:
  - type: dropdown
    id: in-category
    attributes:
      label: Category
      options:
        - bug
        - feature-request
        - pack-feedback-workflow
        - pack-feedback-prompt
        - pack-feedback-agent-perf
        - pack-feedback-friction
        - pack-feedback-open-question
    validations:
      required: true
  - type: input
    id: in-pack-version
    attributes:
      label: Pack version in use (pack-feedback only)
      description: Read from STATUS.md "Key Metrics" section. Required for pack-feedback-* categories.
  - type: input
    id: in-project-id
    attributes:
      label: Project identifier (pack-feedback only)
      description: Anonymized; for pattern detection only.
  - type: textarea
    id: in-observation
    attributes:
      label: Observation / steps to reproduce
    validations:
      required: true
  - type: textarea
    id: in-context
    attributes:
      label: Context (project state, agent, files, environment)
  - type: textarea
    id: in-expected
    attributes:
      label: Expected behavior (bug only)
  - type: textarea
    id: in-actual
    attributes:
      label: Actual behavior (bug only)
  - type: markdown
    attributes:
      value: |
        <!-- pack-id: PENDING -->
        <!-- template_version: v11.0.0/inbound -->
        <!-- pack-version: v11 -->
```

Auto-routing label table:

| Category pick | Labels written |
|---|---|
| `bug` | `inbound`, `external`, `type:bug`, `needs-triage`, `template:inbound-v11.0.0` |
| `feature-request` | `inbound`, `external`, `type:feature`, `needs-triage`, `template:inbound-v11.0.0` |
| `pack-feedback-*` | `inbound`, `pack-feedback`, `pf-category:<workflow\|prompt\|agent-perf\|friction\|open-question>`, `needs-triage`, `template:inbound-v11.0.0` |

`pack-feedback` issues filed via the upstream mechanism in V1 §7.5 still
land here. The mechanism is unchanged; only the form file name changes.

### 4.4 Field-to-METHODOLOGY mapping (preserved from V1 §4)

The mapping from the BACKLOG entry format (`Type:`, `Status:`,
`Blockers:`, `Unblocks:`, `File/Symbol:`, `Description:`, `Context:`,
`Resolution:`) to GH constructs is unchanged from V1 §4.1. The form
shape changed; the data shape did not. Reverse migration (V1 §6.5)
reconstructs all eight fields without modification.

### 4.5 Phase-epic system issue (created by chat, not by form)

When PM Chat creates a phase epic, it calls `provider.create()` with:

```
title: "Phase N — <phase title>"
type:  Epic
labels: ["phase-epic", "phase-N", "template:phase-epic-v11.0.0"]
body:
  Phase number: N
  IMPLEMENTATION_PLAN anchor: <computed via the v10 algorithm>
  <!-- pack-id: phase-N -->
  <!-- template_version: v11.0.0/phase-epic -->
  <!-- pack-version: v11 -->
```

No user form is needed for the common case. A `phase-epic-skeleton` Type
in `work-item.yml` covers the rare hand-edit case (e.g., a phase epic
deleted by accident; a chat creating one offline before forward
migration completes).

### 4.6 Cross-tracker compatibility (preserved from V1 §4.6)

V1 §4.6's mapping table holds: title→title, body→body/description,
status→state+label or workflow-state, etc. The form-family change is
GH-specific (it is how the user files into GH). Other backends'
equivalents — Linear's "create issue" flow with a Type field; Jira's
issue-type pick at create time — naturally collapse to a similar
"single create UI with a Type dropdown" pattern. See §24 for why this
matters.

---

## 5. Dependency model and hierarchy (preserved)

V1 §5 stands. Read V1 directly. Decision D-1 (provider surface) and the
3-level cross-tracker safe floor unchanged.

---

## 6. Migration algorithm (V1 with one §6.2 addendum)

V1 §6 stands except for §6.2 step 4c, which now writes the
`template_version` marker pair into every created issue:

### 6.2 (V2 addendum) — template_version writes

In V1 step 4c (issue create), the body assembled from BACKLOG entries
includes free-form `Description / Context / File-Symbol / Resolution`
sections plus the footer `<!-- pack-id: TD-NNN -->` marker.

In V2, the body footer is the **marker trio**:

```
<!-- pack-id: TD-031 -->
<!-- template_version: v11.0.0/work-item -->
<!-- pack-version: v11 -->
```

Plus the labels assigned at create time include
`template:td-v11.0.0` (the queryable face of the same fact). See §26.

Reverse migration (V1 §6.5) reads the trio and the label. The
authoritative source is the comment trio; the label is for cheap query
by `pack tracker update-templates`. If only one is present, the comment
wins.

The forward script's `roundtrip-test` (V1 §6.7) is unchanged. The
trio is part of the body; it round-trips trivially.

V1 §6.1, §6.3, §6.4, §6.5, §6.6, §6.7 stand without further change.

---

## 7–15. Orchestration, agent reads, failure UX, external triage, license, token economy, per-CLI, compatibility, pre-existing-tracker (preserved)

V1 §7–§15 stand. Read V1 directly. The only V2 wording change is in §9.7
(misroute guard message): the route the user is steered toward is now the
`Inbound` form with Category=pack-feedback-friction or
pack-feedback-workflow, not the V1-named `pack-feedback.yml`. Decision
D-7 is reaffirmed; the underlying behavior is unchanged.

---

## 16. Decisions (V2)

V1 had 15 rows. V2 keeps them all in place, marks each "reaffirmed" or
"superseded by D-N-V2", and adds three new rows for the new OQs. The
table is the index of V1→V2 change for the maintainer.

| ID | Date | V2 status | Decision | Rationale | Resolves | Sections |
|---|---|---|---|---|---|---|
| D-1 | 2026-04-30 | **reaffirmed** | Provider surface = the 18 ops in V1 §2.1 with `Issue` shape, capability flags, error model, pagination contract. | New priorities P1–P6 do not reshape the operation set; they constrain *what the chat does on top of it*. | OQ-1 | V1 §2 |
| D-2 | 2026-04-30 | **reaffirmed** | Tracker config = single `tracker.toml` per surface. | One file = one decision; V2 P2 (`pack tracker update-templates`) reads/writes a new section but does not change the file's role. | OQ-2 | V1 §3.1 |
| D-3 | 2026-04-30 | **reaffirmed** | Migration command surface = bash script `scripts/tracker-migrate.sh forward / reverse / status / doctor`. P5/P6 add `pack tracker init` + `pack tracker update-templates` + `pack tracker disable` / `status` verbs as wrappers over the same script and provider; the script itself is unchanged. | LCD bash works on all three CLIs. New verbs are wrappers, not new mechanisms. | OQ-3 | V1 §6.1, V2 §22 |
| D-4 | 2026-04-30 | **superseded by D-4-V2** | (V1) Six separate forms `bd-entry.yml`, `td-entry.yml`, `phase-epic.yml`, `pack-feedback.yml`, `bug-report.yml`, `feature-request.yml`. | (V1) Issue forms give validated input + structured roundtrip. | OQ-4 | V1 §4 |
| D-4-V2 | 2026-04-30 | **new** | Two forms: `work-item.yml` (Type=bd/td/phase-epic-skeleton) and `inbound.yml` (Category=bug/feature/pack-feedback-{workflow,prompt,agent-perf,friction,open-question}). Phase epics are normally created by Pack/PM Chat via `provider.create()`, not by user form. Auto-routing labels at intake; chat specializes labels at triage (§4.2 / §4.3). | Per OQ-16 defense (§24), the multi-form choice loses on token economy of the templates' GH `?template=` URL surface, on cross-tracker portability (Jira and Linear's "issue create" UI naturally collapse to one composite form), on P2 maintenance ergonomics (adding a TD field touches one file, not two; adding a new entry type adds one Type option, not a file), and on `New Issue` dropdown UX (two options dropping into a Type dropdown is familiar; six options is noisy). The two-form family preserves all V1 §4 fields and labels. | OQ-4, OQ-16 | §4, §24, §16 |
| D-5 | 2026-04-30 | **reaffirmed** | Mode detection = presence and content of `tracker.toml`. | One signal, one place. P5 (cognitive load) and P6 (discoverability) reinforce — fewer moving parts. | OQ-5 | V1 §3.2 |
| D-6 | 2026-04-30 | **reaffirmed** | Trinity `## Document locations` table gains a Source column (`flat` / `mirror-of-tracker` / `tracker-only`). | Per V2 P2, the same table propagates `template_version` notice — but the *table shape* unchanged. | OQ-6 | V1 §3.3, V2 §19 |
| D-7 | 2026-04-30 | **reaffirmed** | Failure-mode UX = typed error codes, no silent retry, mirror as fallback when fresh, message shapes in V1 §9.1–§9.7. | P4 (auditability) confirms: typed errors are the events the audit surface captures. Per V2 §9.7 wording change, the misroute prompt routes to `inbound.yml` Category=pack-feedback-friction; the *behavior* of the guard is unchanged. | OQ-7 | V1 §9 |
| D-8 | 2026-04-30 | **reaffirmed** | Reverse migration = same script, also triggered by `pack tracker disable`. Sidecar for tracker-only data. Round-trip verified. | P1 lifecycle confirms: every state transition is reverse-emittable. | OQ-8 | V1 §6.5–6.7 |
| D-9 | 2026-04-30 | **reaffirmed** | Agent reads = LCD `gh` shell-out universal; MCP per-CLI optional. | P3 (backend extensibility) confirms: backends declare both shell and MCP variants where available; the agent stays mechanism-agnostic. | OQ-9 | V1 §8 |
| D-10 | 2026-04-30 | **reaffirmed** | Auth = single `gh auth` per machine. | Unchanged. | OQ-10 | V1 §7.3 |
| D-11 | 2026-04-30 | **reaffirmed** | PACK-FEEDBACK upstream = chat command (when authenticated) or manual web-paste fallback; PACK-FEEDBACK.md remains local audit trail. | P4 (auditability) reinforces: the local PACK-FEEDBACK.md is the local audit trail when the upstream issue gets filed. The route inside the inbound form is `Category=pack-feedback-*`. | OQ-11 | V1 §7.5 |
| D-12 | 2026-04-30 | **reaffirmed** | Pre-existing tracker integration deferred to a post-v11 minor. | Unchanged; V2 priorities do not pull this back into scope. | OQ-12 | V1 §15 |
| D-13 | 2026-04-30 | **reaffirmed** | License interaction = none new in v11. | Unchanged. | OQ-13 | V1 §11 |
| D-14 | 2026-04-30 | **reaffirmed** | External-issue triage via `needs-triage` + Pack Chat triage queue. | P1 (lifecycle) makes the triage state machine explicit (§18.2); the underlying decision is unchanged. | OQ-14 | V1 §10, V2 §18.2 |
| D-15 | 2026-04-30 | **reaffirmed** | Token measurement = post-shipping side-effect verification. | Unchanged. | OQ-15 | V1 §12 |
| D-16 | 2026-04-30 | **new** | Multi-template strategy = the form-family pattern in D-4-V2 (two composite forms with Type/Category dropdowns) is the canonical strategy for v11 and the recommended shape for any future entry-type addition. New entry types add a dropdown option, not a file. | Defended in §24 against the alternative (one file per type and the alternative of one true single form for everything) on token economy, API behavior, search/sort/filter, cross-tracker portability, P2 maintenance, and UX. The form-family pattern wins on all but two axes (intake-dropdown clarity at very large type counts; per-type README discoverability). | OQ-16 | §24 |
| D-17 | 2026-04-30 | **new** | Structure-vs-free-text split = V1's choice (dropdowns for Type/Status/td-scope/td-severity; textareas for Blockers/Unblocks/File-Symbol/Description/Context/Resolution) is reaffirmed against more-structure (e.g., Blockers as repeated structured input rows; File/Symbol as repo-tree autocomplete) and less-structure (everything in one freeform body) alternatives. The line is drawn at "structured iff a finite enum drives a label, sub-issue parent, or state transition; otherwise textarea". `Blockers` and `Unblocks` are textareas with line-per-id grammar parsed by the chat at triage — structured under the hood, free-text at intake. | Defended in §25. More-structure adds intake friction beyond what label routing pays back, and breaks under capability-flag mismatches (Linear custom fields, Bugzilla keyword model). Less-structure breaks the reverse-migration grammar. | OQ-17 | §25 |
| D-18 | 2026-04-30 | **new** | `template_version` placement = HTML-comment marker in body (authoritative) **plus** label `template:<entry-type>-v<X.Y.Z>` (queryable face). The form's `markdown` block emits the comment; the form's `labels:` key + chat-side post-processing emit the label. Migration writes both. Reverse reads the comment. | Defended in §26 against label-only, body-field-only, and Projects v2 custom-field options on round-trip survival, label-budget cost, queryability for `pack tracker update-templates`, and consistency across entry types. | OQ-18 | §26 |

The decisions table is the V2 reading index for someone with V1 in mind.

---

## 17. Risks and open trade-offs (V2 update)

V1 §17 stands except R9, which V2 deletes per `DESIGN-BRIEF.md` §1
update (no v10 non-opt-in case). Renumber rationale:

- R9 (V1: "Trinity Source-column is breaking for v9-era projects") —
  **deleted in V2.** OT is the only v10 project; it migrates to v11 +
  GH Issues; no flat-file projects pulling v11 pack updates exist.

V2 adds the following risks:

**R11. Form-family Type-dropdown UX at very-large type count.** The
form-family in D-4-V2 ships with three Types in `work-item.yml` and
seven Categories in `inbound.yml`. If v12 adds many more, the dropdown
becomes noisy. Mitigation: GH supports `dropdown.multiple = true` and
`grouped` options; the V2 form does not; it can be added in a future
minor. Soft cap on Types: ~6 in `work-item.yml` and ~12 in
`inbound.yml`. Past that, split into a third form.

**R12. `template_version` label budget consumption.** Each entry uses
one of the 100-label-per-issue budget for `template:<entry>-v<X.Y.Z>`.
At 100 labels per issue this is fine; no entry will use 100 labels in
realistic operation (the typical entry uses ~6–10). But the
`template:*` family adds N distinct labels at the *repo* level over
time as the pack version advances. There is no documented hard cap on
labels per repo (audit §A.2; community confirms no enforced number).
Mitigation: `pack tracker update-templates` includes a "garbage-collect
old template:* labels at the repo level when no entry references them"
sub-step.

**R13. P3 backend extensibility tension with capability flags.** The
contract in §20 expects a backend to declare its capabilities truthfully
at compile time. If a backend's tier graduates from "experimental" to
"first-class" but it lied about a capability (e.g., declared
`hierarchy.supported = true` but actually emulates), users will hit
runtime failures the abstraction can't catch. Mitigation: §20.4
conformance test suite includes "live-API capability-truth probing" so
graduation-to-first-class requires running it.

**R14. Audit-query language drift across backends (P4).** GH's audit
trail is exposed via the issue-events API; Linear's via webhooks +
GraphQL audit log; Jira's via separate audit-log REST endpoint. The
chat-side `show audit for TD-031` resolves to different shapes per
backend. Mitigation: §21.5 designs a `provider.list_events(id)`
extension to the operation set in V1 §2.1 so the chat asks one
abstract operation; per-backend code maps to native event API. This
adds one operation to the surface (raising D-1's count from 18 to 19).
Decision: documented as an additive minor in §20.7 not as a D-1 update,
because backends without an event API can return `[]` and degrade
gracefully — not a breaking change.

V1 §17.1 R1–R8, R10 stand. V1 §17.2 trade-offs T1–T6 stand. V1 §17.3
reviewer/planner challenge list stands.

---

## 18. P1 — Entry lifecycle completeness

This section is the explicit state machine per entry type. Every
allowed transition names the trigger source (Pack Chat, PM Chat, an
external GH user, an automated triage rule, the migration script) and
the artifacts the transition produces (label change, comment with
structured prefix, link, assignee).

The shape is the same for every entry type:

```
   [created]
       │
       ▼
   needs-triage ──(triage)──> active ──(close)──> resolved
                                 │
                                 │ (later)
                                 ▼
                              superseded / cancelled / deprecated
```

The differences across entry types are:

- *Who* triages.
- What "active" looks like (the substates).
- What artifacts the close transition requires.
- Whether superseded / cancelled / deprecated apply.
- Whether duplicate detection happens at triage or at create.

### 18.1 BD entry lifecycle (pack repo)

States: `needs-triage`, `open`, `unblocked`, `in-progress`, `resolved`,
`cancelled`, `deprecated`. Tracker representation: each state is a
label `status:<state>` *except* `resolved`, which is GH-state `closed`
with `state_reason: completed`, and `cancelled` / `deprecated`, which
are GH-state `closed` with `state_reason: not_planned` and a
`status:cancelled` / `status:deprecated` provenance label.

| From | To | Trigger | Required artifacts |
|---|---|---|---|
| (none) | `needs-triage` | User submits `work-item.yml` Type=bd; or migration script imports a BACKLOG entry; or chat creates from a TD-TBD upgrade | Label `work-item`, `needs-triage`, `bd-entry` (added at triage), `template:bd-v11.0.0`; body marker trio; `<wi-kind>` → `type:<feat\|fix\|...>` label |
| `needs-triage` | `open` | Pack Chat triages (cmd `pack triage <id>` or colloquial "triage BD-NNN") | Remove `needs-triage`; add `status:open`; rewrite `pack-id: PENDING` → `pack-id: BD-NNN`; comment `Triage: accepted into v<N> scope. Owner: pack-chat.` |
| `needs-triage` | `cancelled` (close) | Pack Chat triage reject | Add `status:cancelled`; close with `state_reason: not_planned`; comment `Triage: out of scope. <reason>.` |
| `needs-triage` | `duplicates(other)` | Pack Chat triage detects duplicate | Add `status:cancelled` (provenance), `state_reason: duplicate`; close; `provider.link(id, other_id, kind="duplicates")`; comment `Triage: duplicate of #<other>.` |
| `open` | `unblocked` | Pack Chat detects all `Blockers:` entries are closed (signal: closing a blocker triggers a re-evaluation in the chat session; not an automated webhook in v11) | Remove `status:open`; add `status:unblocked`; comment `Re-label: blockers cleared at <date>.` |
| `open` / `unblocked` | `in-progress` | Pack Chat assigns the entry to the active version (added to mapping for the in-flight major) | Add `status:in-progress`; remove `status:open`/`status:unblocked`; `set_assignee(id, [pack-chat-user])`; comment `Decision: starting in v<N>.` |
| `in-progress` | `resolved` (close) | Pack Chat marks resolved; the chat post-flight regenerates README version table and CHANGELOG.md mirror | Remove `status:in-progress`; close with `state_reason: completed`; structured comment `Resolution: <text from wi-resolution textarea or chat>.`; if the chat is generating a CHANGELOG row, comment `Changelog: <one-line summary>.` |
| `in-progress` / `open` / `unblocked` | `cancelled` | Pack Chat decides not to ship | Close with `state_reason: not_planned`; add `status:cancelled`; comment `Decision: cancelled. <reason>.` |
| `in-progress` / `resolved` | `deprecated` | A successor BD entry supersedes this one | Add `status:deprecated`; if not already closed, close with `state_reason: not_planned`; **required** `provider.link(id, successor_id, kind="related")`; comment `Decision: deprecated; superseded by BD-<successor>. <reason>.` |
| `resolved` | `open` (reopen) | Pack Chat reverts | `provider.reopen(id)`; remove `status:resolved`; add `status:open`; comment `Re-open: <reason>.` |

**Triage lifecycle.** `needs-triage` is removed *only* by Pack Chat
(cmd or colloquial). It does not auto-clear. The pack-startup Step 7
(V1 §10.2) lists `needs-triage` items at session start; the user
proceeds through them in age order.

**Re-labeling cadence.** The `status:open` → `status:unblocked`
transition is signal-driven within a chat session: when the chat
closes a BD that another BD lists as a Blocker, Pack Chat scans the
mapping for downstream entries and offers to re-label. It is *not*
fully automated (no webhook in v11; the chat has to be in the loop).
A future minor with CI hooks (out of scope per V1 §11.5) could
automate.

**Comment-type conventions.** Every state-transition comment uses a
structured prefix. The reverse migration grammar in V1 §6.5 reads
these to reconstruct flat-file `Resolution:` and `Context:` fields.
Reserved prefixes:

- `Triage:` — applied at triage transition.
- `Re-label:` — applied at downstream re-labels (e.g., open → unblocked).
- `Decision:` — applied at scope/cancellation/deprecation transitions.
- `Resolution:` — applied at resolved close.
- `Re-open:` — applied at reopen.
- `Changelog:` — paired with `Resolution:` when CHANGELOG row generated.
- `Audit:` — applied by the chat for any other audit-worthy event (e.g., assignee change).

These are conventions, not enforced. The chat writes them; agents read
them for context. Reverse migration treats unrecognized comments as
free-form (preserved verbatim or sidecar'd per V1 §6.6).

**Duplicate detection workflow.** At intake (form submission), GH's
own dup-suggestion (audit §A.10) helps the user; Pack Chat at triage
runs `provider.search(query='in:title <fragment>')` plus
`provider.list(filter={label: bd-entry, label: status:open})` to spot
duplicates the user missed. If duplicate found:

1. `provider.close(id, reason="duplicate")`.
2. `provider.link(id, other_id, kind="duplicates")`.
3. Comment on **both**: `Audit: duplicate established by Pack Chat at <date>. Canonical: #<other>.`

**Deprecation vs cancellation.**

- *Cancelled* = "we decided not to do this work and there's no successor." `state_reason: not_planned`. No successor link required.
- *Deprecated* = "this work is superseded; see the successor for the canonical version." `state_reason: not_planned`. **Successor link required** (`kind="related"` since GH does not have a `replaces` link kind).

**Deletion stance.** `provider.delete()` is *not* in the operation set
(V1 §2.1). GH allows issue deletion via REST; the pack does not expose
it. The closest action is close-as-cancelled. If a maintainer truly
needs to delete (PII leak, etc.), use `gh api -X DELETE
/repos/owner/repo/issues/<n>` directly via `provider.raw(...)`. The
escape hatch is intentional.

**Assignee workflow.** Default unassigned at create. Pack Chat
self-assigns at the `→ in-progress` transition. Human maintainers can
hand-assign at any state. `provider.set_assignee()` is idempotent.

### 18.2 TD entry lifecycle (client project)

Identical shape to BD with three differences:

1. *Who triages*: PM Chat, not Pack Chat.
2. *Phase membership*: at the `→ open` transition, the chat sets
   `phase-N` label and `provider.sub_issue_create(parent=phase-N-epic, child=this)` if the entry's `wi-td-scope = phase-N`. Without phase membership the entry is `scope:dependency` / `scope:feature` / `scope:perf` / `scope:version`.
3. *KNOWN GAP variant*: when `wi-td-severity` is set, the entry carries `severity:critical/functional/polish` plus the standard TD lifecycle. Severity does not affect transitions; it informs prioritization.

State table is the same as BD but with `td-entry` label and TD-NNN id.

### 18.3 Phase epic lifecycle (client project)

States: `active`, `complete`. There is no `needs-triage` because phase
epics are created by PM Chat, not user form.

| From | To | Trigger | Required artifacts |
|---|---|---|---|
| (none) | `active` | PM Chat creates at migration time, or when adding a new phase | Labels `phase-epic`, `phase-N`, `template:phase-epic-v11.0.0`; body marker trio + Phase number + IMPLEMENTATION_PLAN anchor; comment `Audit: phase created at <date>.` |
| `active` | `complete` (close) | PM Chat marks complete when STATUS.md flips ✅ | Close with `state_reason: completed`; comment `Resolution: phase complete at <date>. Children: <count> closed of <count> total.` |
| `active` | `cancelled` | Phase scope removed | Close `state_reason: not_planned`; comment `Decision: phase cancelled. <reason>.` |
| `complete` | `active` | Phase reopened (rare) | `reopen`; comment `Re-open: <reason>.` |

Sub-issue children (TD entries) close independently. Phase epic close
is a chat action, not a cascade, because GH does not auto-close
parents on child close.

### 18.4 Pack-feedback lifecycle (cross-surface, lives in pack repo)

States: `needs-triage`, `accepted`, `acknowledged`, `resolved`,
`out-of-scope`. Tracker representation:

- `needs-triage` = label set at intake.
- `accepted` = `pack-feedback` label persists; `needs-triage` removed; chat assigns BD-NNN if becomes pack work (lifecycle then continues per §18.1, but the `pack-feedback` label persists as provenance).
- `acknowledged` = label set; not turned into BD work; the entry stays open with the chat's response in a comment.
- `resolved` = closed `state_reason: completed`.
- `out-of-scope` = closed `state_reason: not_planned`.

| From | To | Trigger | Required artifacts |
|---|---|---|---|
| (none) | `needs-triage` | External user submits `inbound.yml` with Category=pack-feedback-*; or PM Chat upstream-files | Labels per §4.3; body marker trio |
| `needs-triage` | `accepted` (becomes BD) | Pack Chat decides to take ownership | Add `bd-entry`, `status:open`, `template:bd-v11.0.0`; rewrite `pack-id: PENDING` → `pack-id: BD-NNN`; remove `needs-triage`; the entry is now also a BD entry and follows §18.1. The `pack-feedback` label persists. |
| `needs-triage` | `acknowledged` | Pack Chat does not take ownership, but acknowledges | Remove `needs-triage`; comment `Triage: acknowledged. Filed against BD backlog as <reason if applicable>. Not currently scoped.` |
| `needs-triage` | `out-of-scope` | Pack Chat declines | Close `state_reason: not_planned`; comment `Triage: out of scope. <pointer to where to go>.` |
| `accepted` | (continues per §18.1) | — | — |
| `acknowledged` | `resolved` | Underlying BD ships | Close `state_reason: completed`; comment `Resolution: addressed in v<N> via BD-<NNN>.` |

### 18.5 External bug-report / feature-request lifecycle (pack repo)

Identical to pack-feedback except the `external` label persists instead
of `pack-feedback`. The transitions and required artifacts are
identical.

### 18.6 Lifecycle invariants (cross-cutting)

- Every transition writes a comment with a structured prefix from §18.1.
- Every state is observable as a label combination (or GH state +
  `state_reason`); no state lives only in a comment.
- Every transition is reverse-emittable into the v10 BACKLOG grammar
  (per V1 §6.5) without loss except where V1 §6.6 sidecar applies.
- Deletion is forbidden by the canonical surface; escape via
  `provider.raw()` only.
- Every entry carries its `template_version` marker trio + label
  through its full lifecycle (see §19 on what happens when the
  template version becomes stale).

---

## 19. P2 — Maintenance ergonomics

This section designs the propagation of template, label, and capability
changes from the pack to opted-in projects across pack versions
(v11.0 → v11.1 → v12), and the mechanism by which the user knows when
their tracker artifacts are stale.

### 19.1 What can drift

Three classes of artifact drift over pack-version time:

1. **Issue forms.** `.github/ISSUE_TEMPLATE/work-item.yml` and
   `inbound.yml` evolve as fields are added, dropdown options expand,
   help text improves. Each evolution writes a new
   `template_version` (e.g., `v11.0.0/work-item` →
   `v11.1.0/work-item`).
2. **Labels.** New label families introduced (e.g., a `priority:*`
   family in v12), old labels deprecated, color/description updated.
3. **Capability declarations.** The GH backend's compiled-in
   capability flags (V1 §2.7.2) update as GH ships new features (e.g.,
   the depth-ceiling raises from 8 to 10).

The user-facing question: how does an existing entry, created on
`v11.0.0/work-item` and now sitting in a project on pack v11.2,
behave?

### 19.2 The `pack tracker update-templates` verb

A new wrapper command (over the existing `tracker.sh` provider). The
shape:

```
pack tracker update-templates [--apply] [--dry-run] [--scope=<bd|td|inbound|all>]
```

What it does (in order):

1. **Read pack version.** Look up the pack's current advertised
   template versions from `project-template/.github/ISSUE_TEMPLATE/`
   (in client projects after a pack upgrade) or
   `.github/ISSUE_TEMPLATE/` (pack-repo case).
2. **Read tracker entries.** `provider.list(filter={label: 'template:bd-*' or 'template:td-*' or 'template:inbound-*'}, fields=[number, title, labels])`. Identify entries with stale templates by comparing the `template:<entry>-v<X.Y.Z>` label against the current.
3. **Compute upgrade plan.** For each stale entry, look up the source
   template version's archived form file in
   `maintenance-docs/v11-templates-archive/<old-version>/work-item.yml`
   and apply the documented translation rule for that version pair (see
   §19.4). Produces a list of `(id, current_template, target_template, body_patch, label_patch)` records.
4. **Show plan to user.** Print the upgrade plan; prompt for approval
   unless `--apply`. With `--dry-run`, exit after printing.
5. **Apply.** For each entry: rewrite body (preserving the user-edited
   sections; see §19.3), rewrite labels, write a structured comment
   `Audit: template upgraded from <old> to <new> at <date> by Pack Chat.`,
   update the marker trio.

### 19.3 Body patch semantics

The body of an entry is a mix of:

- **Pack-controlled scaffolding.** Section headings ("Description",
  "Context", etc.), the marker trio comment block.
- **User content.** The actual text inside each section.

A body patch operates only on the pack-controlled scaffolding. User
content is preserved verbatim by section. If a v11.1 form removes a
field, its content is moved to a `## Context (legacy <field-name>)`
section appended at the end. If a v11.1 form adds a field, the new
section is added empty with a `<!-- TODO: pack tracker update-templates added this field; fill it in or leave blank -->` comment.

The chat never silently overwrites user content. The audit comment
records what changed.

### 19.4 Translation rules — archived-template directory

`maintenance-docs/v11-templates-archive/<version>/<form-name>.yml`
preserves every shipped template version. When a v11.1 form ships, the
v11.0 form moves to the archive (and the in-tree form file is the new
v11.1).

The archive accompanies a translation manifest:

`maintenance-docs/v11-templates-archive/translations.yaml`:

```yaml
- from: v11.0.0/work-item
  to:   v11.1.0/work-item
  rules:
    - kind: field-renamed
      from: bd-blockers
      to:   wi-blockers
    - kind: field-added
      to:   wi-priority
      default: ""
    - kind: label-renamed
      from: status:open
      to:   status:open       # no change in v11.1; example
- from: v11.1.0/work-item
  to:   v12.0.0/work-item
  ...
```

The translation manifest is the single source of truth for
`pack tracker update-templates`. The script applies rules in order; a
2-version-skip (v11.0 → v12.0) chains v11.0→v11.1→v12.0 sequentially.

`maintenance-docs/v11-templates-archive/` itself is a pack-repo
artifact, not a client-project artifact. Client projects pull the
relevant archive entries into their pack-side mirror at install /
upgrade time (handled by the existing pack-upgrade migration
sequence in `INSTALL-PROCEDURES.md`).

### 19.5 Cadence: automatic vs opt-in

| Change kind | Default behavior | Override |
|---|---|---|
| New optional field added | Opt-in. `pack tracker update-templates` shows the plan; user approves. | `--apply` skips approval. |
| New required field added | Opt-in **and** pause. The chat refuses to triage new entries until the user runs the upgrade or pins via `--pin-template`. | `--pin-template <version>` retains the old version explicitly; entries created at the pinned version stay valid. |
| Field renamed | Opt-in. The chat continues to read the old name during the un-upgraded window, but new entries on the new template only emit the new name. | `--apply` upgrades all in one pass. |
| Field removed | Opt-in. The removed-field content moves to `## Context (legacy ...)`. | none. |
| Label renamed (e.g. `status:open`→`status:active`) | **Automatic on next chat-side write** (cheap; ≤1 API call per entry). The chat performs the rename when it touches the entry next; `pack tracker update-templates` forces immediate sweep. | `--no-auto-label-rename` to defer. |
| Label removed | Opt-in. | none. |
| Capability flag update (e.g., depth ceiling raises) | Automatic on next chat session; capability cache refreshes. | `pack tracker doctor` forces immediate. |

The principle: the user *is told* before any change to existing entries
that affects observable content; pure label renames or capability
refreshes that don't alter the entry's content surface happen in the
background.

### 19.6 Staleness surfacing

Three places the user learns that templates / labels / capabilities are
stale:

1. **`pack-startup` Step 7 (tracker mode).** After listing the triage
   queue, Pack Chat reports `Template-version status: <N entries on stale templates; run pack tracker update-templates>` if any entry is more than one minor version behind. (Same step on the client side; PM Chat reports.)
2. **`pack tracker doctor`.** Validates the full surface (config,
   capabilities, mirror freshness, mapping integrity, **template
   freshness**) and prints all findings.
3. **`pack tracker status`.** A lightweight view of the current
   tracker state, including a one-line "Templates: current" or
   "Templates: <N> stale" summary.

The pack-startup surface is the *proactive* surfacing required by
P2 ("not just reactive doctor"). The user sees it at session start,
not by remembering to run a verb.

### 19.7 v11.0 → v11.1 minor-version reference flow

Concrete walk-through:

1. v11.1 ships with a new `wi-priority` dropdown in `work-item.yml`.
   The shipped form has `template_version: v11.1.0/work-item`. The
   v11.0 form is archived to
   `maintenance-docs/v11-templates-archive/v11.0.0/work-item.yml`.
2. A translation rule is added to
   `maintenance-docs/v11-templates-archive/translations.yaml`:
   `from: v11.0.0/work-item, to: v11.1.0/work-item, kind: field-added, to: wi-priority, default: ""`.
3. The pack-upgrade migration (per `INSTALL-PROCEDURES.md` Procedure 5)
   replaces the in-tree `work-item.yml` with the new version.
4. On the next Pack Chat / PM Chat session, `pack-startup` Step 7
   reports `Template-version status: <12 entries on v11.0.0; current v11.1.0>`.
5. User runs `pack tracker update-templates --dry-run`. Plan printed.
6. User runs `pack tracker update-templates --apply`. The chat
   rewrites each entry's body (adds the new section), labels (no label
   change in this minor; `priority:*` label family is added by the
   user later via the new dropdown when triaging), and writes an
   audit comment.

### 19.8 v11.x → v12 major-version flow

Major versions can introduce breaking changes (e.g., field renames
that mean the v11 reverse migration doesn't reconstruct cleanly). The
upgrade is deliberately staged:

1. `pack tracker update-templates --to=v12.0.0 --dry-run`. Prints the
   full plan; flags each breaking change.
2. The user approves; `--apply` rewrites all entries.
3. The translation manifest's v11.x→v12.0 chain is applied
   sequentially.

A v12 ship that is incompatible with v11 reverse-migration grammar
would be flagged in the v12 design brief as a constraint; not a v11
concern.

### 19.9 Labels at the repo level

Label additions / renames at the repo level happen via a separate
script step (`scripts/tracker.sh ensure-labels`) called by
`pack tracker init` and `pack tracker update-templates`. It diffs the
repo's current label set against the pack's required label set
(read from a list-of-labels.yaml shipped in the pack's
`.github/`) and creates / renames / annotates as needed.

The required label set at v11.0:

```
work-item, inbound, bd-entry, td-entry, phase-epic, external,
pack-feedback, needs-triage,
type:feat, type:fix, type:refactor, type:docs, type:chore, type:infra,
type:bug, type:feature,
status:open, status:unblocked, status:in-progress,
status:cancelled, status:deprecated,
scope:phase-N (one per active phase), scope:dependency, scope:feature, scope:perf, scope:version,
severity:critical, severity:functional, severity:polish,
pf-category:workflow, pf-category:prompt, pf-category:agent-perf, pf-category:friction, pf-category:open-question,
template:work-item-v11.0.0, template:bd-v11.0.0, template:td-v11.0.0, template:phase-epic-v11.0.0, template:inbound-v11.0.0
```

That's ~45 labels. GH has no documented hard repo-level label cap, so
this is comfortable. The `template:*` family grows monotonically over
time; R12 (§17 V2 update) covers GC.

### 19.10 Audit trail of upgrades

Every `pack tracker update-templates --apply` writes an entry to
`.pack-tracker/upgrade-log.json` (per surface). Records:
`{run_at, by, from_version, to_version, entries_touched: [<id>], rules_applied: [...]}`.
Also writes a `Audit: template upgraded from ...` comment on each
touched issue. The audit trail is queryable by P4 (§21) primitives.

---

## 20. P3 — Backend extensibility ergonomics

This section is the contract a contributor follows to add a new
tracker backend. It says where the code lives, what interface methods
are required, what tests prove conformance, what the sample reference
backend (Linear sketch) looks like, and how a backend graduates from
"experimental" to "first-class".

### 20.1 File layout

```
scripts/tracker-providers/
├── github.sh           # first-class; the LCD provider
├── github.toml         # capability declaration + backend metadata
├── linear.sh           # experimental; the sample second backend
├── linear.toml
├── _lib/
│   ├── _common.sh      # shared helpers (idempotency, logging, error mapping)
│   └── _conformance.sh # the conformance test harness
└── README.md           # how to add a backend (entry point for contributors)
```

A backend is one bash script + one TOML capability file. Both are
required. Optional addenda:

- `<backend>.<cli>.toml` — per-CLI MCP shortcuts (e.g.,
  `linear.claude.toml`, `linear.codex.toml`, `linear.gemini.toml`)
  documenting the MCP endpoint and auth shape per CLI.
- `<backend>-test-fixtures/` — curated fixtures the conformance suite
  uses to drive the backend in CI.

### 20.2 Required interface methods

Every backend script implements these functions, callable as
`./<backend>.sh <op> [arg...]`:

```
list      <filter-json> <page-json>
get       <id>
search    <query> <page-json>
create    <payload-json>
update    <id> <patch-json>
close     <id> <reason>
reopen    <id>
comment   <id> <body-file>
set_labels   <id> <set-json>
set_assignee <id> <ids-json>
set_milestone <id> <name>
link        <id> <other-id> <kind>
unlink      <id> <other-id> <kind>
sub_issue_create <parent-id> <payload-json>
sub_issue_list   <parent-id>
sub_issue_unlink <parent-id> <child-id>
capabilities       (no args; emits the capability declaration)
raw         <method> <path> [body-file]
```

(Optional, additive in a future minor:)

```
list_events <id>     # P4 audit query (§21.5); returns `[]` if backend lacks event API
```

Each function:

- Reads JSON / arguments from stdin or named file as documented in
  the function-signature comment block at the top of the script.
- Emits canonical-shape JSON to stdout.
- Emits structured errors (typed code + diagnostic) to stderr with
  exit code per V1 §2.5.

Conventions:

- Idempotent ops re-emit the canonical state without side-effect on
  retry.
- Non-idempotent ops (`create`, `comment`) require the chat to use
  the marker idempotency mechanism (V1 §6.2; V2 §26).
- `capabilities` is a static read; the backend script can implement it
  by `cat <backend>.toml` + light shell processing.

### 20.3 Capability declaration shape

The TOML format mirrors V1 §2.3 schema. Example (`github.toml`):

```toml
backend_name = "github"

[hierarchy]
supported = true
depth_ceiling = 8
children_per_parent_ceiling = 100
parent_per_child_ceiling = 1

[dependencies]
supported = true
kinds = ["blocks", "blocked-by", "duplicates", "related"]
per_relationship_ceiling = 50
cross_repo_supported = "same-org-internal-only"

[labels]
supported = true
model = "flat"
per_issue_ceiling = 100

[milestone]
supported = true
per_issue_ceiling = 1

[type_field]
supported = true
values_managed_at = "org"

[iteration]
supported = true
where = "project"

[custom_fields]
supported = true
passthrough_only = true

[search]
language = "github-qualifier"
result_ceiling_per_query = 1000

[rate_limits]
writes_per_minute_recommended = 60
reads_per_minute_recommended = 120

[escape]
raw_escape_hatch = true
```

The capability TOML is the contract the chat reads at session start
(V1 §2.3). The conformance test (§20.4) verifies the declared
capabilities match the live backend.

### 20.4 Conformance test suite

`scripts/tracker-providers/_lib/_conformance.sh` is a shell test
harness that drives a backend through the full operation set against
a real instance (or a recorded fixture for offline CI). The suite
verifies:

| Category | Tests |
|---|---|
| Surface | Every required method exists and is invocable; `capabilities` emits valid TOML; exit codes correct on success and on each error class |
| Idempotency | `update` is last-write-wins (apply twice; same result); `close` is idempotent (re-close emits success); `set_labels` is set-replace not set-merge; markers ensure `create` re-runs as no-op |
| Capability truth | Declared `hierarchy.depth_ceiling` matches live (try sub_issue_create at declared+1 depth; expect failure); declared `labels.per_issue_ceiling` matches live; declared `dependencies.per_relationship_ceiling` matches live |
| Pagination | `list` cursor returns next page until `next_cursor=null`; `search` honors `result_ceiling_per_query` |
| Round-trip | `create` then `get` returns same payload; `set_labels` then `get` reflects |
| Error model | Each typed error code is reachable with a concrete trigger (e.g., 401 by clearing auth); the error code + diagnostic string match V1 §2.5 |
| Reverse | A `migrate-roundtrip-fixture` TD-NNN entry in flat-file form, forward-migrated then reverse-migrated, diffs to the original |

The harness ships with a `--mode=fixture` (offline; replays recorded
HTTP) and `--mode=live` (online; requires auth and a sandbox repo).

A backend's conformance run produces a JUnit-XML report committed at
`maintenance-docs/v11-conformance-runs/<backend>/<date>.xml` for
auditability.

### 20.5 Sample reference backend — Linear (experimental)

The pack ships `linear.sh` as the sample second backend at v11.0.
This is **not** a v11 ship feature for users; it is the contributor
reference. Linear is chosen over Jira because:

- Linear has an official remote MCP server with OAuth 2.1 (audit
  §A.7) — the integration is straightforward.
- Linear's hierarchy and dependency model maps cleanly to the
  abstraction (§5).
- Audit §A.7's nuance (sub-issues no documented depth cap;
  sub-initiatives capped at 5 levels) gives a realistic capability
  declaration that's not just a copy of GH's.

`linear.sh` skeleton:

```bash
#!/usr/bin/env bash
# linear.sh — Linear backend for pack tracker.
# Surface mirrors github.sh. Auth via LINEAR_API_KEY or OAuth 2.1 via MCP.

set -euo pipefail
op="$1"; shift

case "$op" in
  list)        linear_graphql 'issues' "$1" "$2" ;;
  get)         linear_graphql 'issue' "$1" ;;
  search)      linear_graphql 'searchIssues' "$1" "$2" ;;
  create)      linear_graphql_mut 'issueCreate' "$1" ;;
  update)      linear_graphql_mut 'issueUpdate' "$1" "$2" ;;
  close)       linear_graphql_mut 'issueUpdate' "$1" '{"stateId":"'$(_resolve_state_id "$2")'"}' ;;
  reopen)      linear_graphql_mut 'issueUpdate' "$1" '{"stateId":"'$(_resolve_open_state_id)'"}' ;;
  comment)     linear_graphql_mut 'commentCreate' "$1" "@$2" ;;
  set_labels)  linear_graphql_mut 'issueUpdate' "$1" "$2" ;;  # GraphQL accepts labelIds set
  set_assignee) linear_graphql_mut 'issueUpdate' "$1" "$2" ;;
  set_milestone) linear_graphql_mut 'issueUpdate' "$1" '{"projectId":"'$(_resolve_project_id "$2")'"}' ;;
  link)        linear_graphql_mut 'issueRelationCreate' "$1" "$2" "$3" ;;
  unlink)      linear_graphql_mut 'issueRelationDelete' "$1" "$2" "$3" ;;
  sub_issue_create) linear_graphql_mut 'issueCreate' --parent "$1" "$2" ;;
  sub_issue_list)   linear_graphql 'issue.children' "$1" ;;
  sub_issue_unlink) linear_graphql_mut 'issueUpdate' "$2" '{"parentId":null}' ;;
  capabilities) cat linear.toml ;;
  raw)         linear_graphql_passthrough "$1" "$2" "$3" ;;
  *) echo "ERR: unknown op $op" >&2; exit 64 ;;
esac
```

The `_lib/_common.sh` provides `linear_graphql`, `linear_graphql_mut`,
and the error-mapping that turns Linear's GraphQL error envelope into
the typed codes from V1 §2.5.

The `linear.toml` capability declaration (excerpt):

```toml
backend_name = "linear"

[hierarchy]
supported = true
depth_ceiling = "unbounded"   # sub-issues; UI flattens past 2
children_per_parent_ceiling = "unbounded"
parent_per_child_ceiling = 1

[dependencies]
supported = true
kinds = ["blocks", "blocked-by", "related", "duplicates"]
per_relationship_ceiling = "unbounded"
cross_repo_supported = false   # Linear is workspace-scoped

[labels]
supported = true
model = "hierarchical"
per_issue_ceiling = "unbounded"

# ... etc
```

Linear's `model = "hierarchical"` flag is honored by the chat: when
filtering by label `phase-N`, the chat asks Linear for `phase-N` and
all its child labels; on GH the same query is a flat string match.
The chat code handles the difference behind a single
`provider.set_labels` call shape; the difference is local to
`linear.sh`.

### 20.6 Tier-of-support graduation rules

A backend lives in one of three tiers:

- **First-class.** Pack-maintained. Used by users in production. Conformance suite runs in CI on every release; failures block releases. Documented in `OPTIONAL-FEATURES.md` and the README.
- **Experimental.** Pack-maintained or contributor-maintained but not promoted in the README; documented as "available; not production-tested." Conformance suite runs in CI but failures do not block (just emit a warning). Users who opt in see a `pack tracker init` notice that the backend is experimental.
- **Community.** Contributor-maintained, not in `scripts/tracker-providers/` but in a third-party repo. The pack documents how to point at one. No CI guarantee.

Graduation rules:

| From | To | Requirements |
|---|---|---|
| Community | Experimental | Submit to `scripts/tracker-providers/<name>.sh` via PR. Pass conformance fixture mode. Capability TOML declared. Documented in README. |
| Experimental | First-class | Pass conformance live mode against a sandbox instance owned by the pack. 6-month soak time without breaking changes (capability flags stable; error codes stable). Pack maintainer accepts ongoing maintenance commitment. |
| First-class | Experimental | Conformance failures across two minor releases without a contributor fix. Pack maintainer demotes via PR. Users notified at `pack tracker doctor`. |
| First-class | (deprecated) | The pack deprecates a first-class backend only when the underlying API is shut down or the maintenance burden becomes untenable. 12-month notice; reverse-migration must work for the entire window. |

v11.0 ships with GH first-class and Linear experimental. The
maintainer can promote Linear in a v11.x or v12 minor based on user
feedback and conformance stability.

### 20.7 The "additive only" extensibility rule

The operation set in V1 §2.1 is closed for v11. A new backend cannot
require a new operation; if it does, the pack adds the operation as
**optional, additive** (every backend may emit a "not implemented"
error code). `list_events` (§17 V2 R14) is the first such addition,
shipped as part of P4.

This rule means trinity changes (adding capability flags, adding ops)
do not happen when adding a backend. A backend ships a script + TOML.

### 20.8 What the contributor README covers

`scripts/tracker-providers/README.md` documents:

1. The minimum viable backend (the 18 ops + capabilities TOML).
2. How to write `<backend>.sh` and what helper functions in `_lib/` are
   available.
3. How to write the capability TOML and what each field must declare.
4. How to run the conformance suite locally (`./conformance.sh
   <backend> --mode=fixture`).
5. How to write fixtures; how to record live API exchanges.
6. How to declare per-CLI MCP support if the backend has an MCP.
7. The typed-error mapping checklist.
8. The graduation process from community → experimental → first-class.
9. Common pitfalls (rate-limit windows, capability drift, schema
   reshape).

The README is the contributor's entry point. It is also the audit
artifact for the trinity / maintenance-docs split: the pack maintainer
can re-read it to confirm a backend submission is conformant.

---

## 21. P4 — Auditability

This section designs the audit-trail surface — what's captured, what's
queryable, and how the chat answers "what changed yesterday?" / "show
audit for TD-031".

### 21.1 What's captured per chat-side write

Every chat-side write produces a tuple recorded in **two redundant
places**:

1. **Tracker-native** (when in tracker mode). GH issue events API
   captures the labelled / closed / reopened / commented event with
   actor + timestamp + before/after content. Linear emits via webhooks
   + GraphQL audit log. Jira via the audit-log REST endpoint.
2. **Chat-side audit log** at
   `.pack-tracker/chat-audit.jsonl` (per surface). Each line:

```json
{
  "ts": "2026-05-15T12:34:56Z",
  "session_id": "<surrogate; per-chat-session UUID>",
  "actor": "pack-chat" | "pm-chat",
  "intent": "triage" | "label-flip" | "create" | "close" | "reopen" | "link" | "comment" | "set-assignee" | "set-milestone" | "set-labels" | "template-upgrade" | "audit",
  "id": "TD-031",
  "before": { "labels": [...], "state": "open", ... },
  "after":  { "labels": [...], "state": "closed", ... },
  "operation": "provider.close",
  "args": {...},
  "outcome": "ok" | "error",
  "error_code": null | "validation" | "rate-limit-secondary" | ...
}
```

The chat-side log is the local audit (per `DESIGN-BRIEF.md` §3.4 P4).
It gets written before the provider call (intent recorded) and updated
after (outcome recorded) so partial-write recovery (V1 §9.6) can
reconstruct the partial state.

`session_id` is a surrogate UUID generated per chat session; not a
long-lived identifier. The CLI does not own a long-lived chat
identity, and the design does not need one. The session_id correlates
operations within a single chat session for "what did I do today?"
queries.

### 21.2 What's captured in flat-file mode

Flat-file mode has no provider; the audit is captured by **git
commits**. The chat batches its writes per session and produces a
single commit at the end, with a structured commit message:

```
chat: pm-chat session 2026-05-15 — closed TD-031, opened TD-040, triaged TD-039

Operations:
  - close TD-031 (resolution: bug fixed in commit abc123)
  - create TD-040 (initial: open)
  - triage TD-039 (open → unblocked)

session_id: f47ac10b-58cc-4372-a567-0e02b2c3d479
```

The `session_id` stays in the commit message; `git log --grep "session_id: f47ac10b"`
recovers it. The `Operations:` block is the structured equivalent of
the JSONL log lines.

The chat-side audit log at `.pack-tracker/chat-audit.jsonl`
**also exists in flat-file mode** when the user opts to keep one (the
file is created when `pack tracker enable-audit-log` is run; default in
flat-file mode is git-only). The file is the same shape as in tracker
mode.

### 21.3 Query patterns

The chat exposes audit queries via natural-language shortcuts plus a
verb. The verb:

```
pack audit query [--since=<date>] [--actor=<...>] [--id=<TD-NNN>]
                  [--intent=<close|create|...>] [--outcome=<ok|error>]
                  [--format=jsonl|markdown]
```

Natural-language equivalents the chat answers:

- *"What changed yesterday?"* → `pack audit query --since=yesterday --format=markdown` (printed inline).
- *"Show audit for TD-031."* → `pack audit query --id=TD-031`.
- *"What did Pack Chat do this week?"* → `pack audit query --since=last-week --actor=pack-chat`.
- *"Why did TD-040's labels change at 14:23?"* → `pack audit query --id=TD-040 --since=14:00:00 --until=14:30:00`.
- *"Which entries had errors today?"* → `pack audit query --since=today --outcome=error`.

### 21.4 Backend-specific resolution

Each query mode resolves to:

| Source | Tracker-mode resolution | Flat-file resolution |
|---|---|---|
| Recent activity | `provider.list_events(id)` for each id in scope, plus chat-audit JSONL | `git log --since=<X> --grep="session_id"` + chat-audit JSONL if enabled |
| Specific id history | `provider.list_events(id)` (e.g., GH issue events API for that issue) | `git log -p -- BACKLOG.md` filtered to the section for the id |
| Cross-id session view | chat-audit JSONL filtered by `session_id` | git commit message of the session commit |
| Error events | chat-audit JSONL filtered by `outcome=error` | chat-audit JSONL only (git captures successful changes) |

The flat-file fallback to `git log` is the P4 requirement. It works
cleanly because BACKLOG.md / STATUS.md / CHANGELOG.md are versioned
files and the chat already commits per session.

### 21.5 The `provider.list_events(id)` operation

Added to the operation set as **optional, additive** per §20.7:

```
list_events(id) → [{ts, actor, kind, before, after, raw}]
```

`kind` is from a small enum: `created, labeled, unlabeled, milestoned, demilestoned, assigned, unassigned, commented, closed, reopened, locked, unlocked, transferred, linked, unlinked, sub_issue_added, sub_issue_removed`. Backend-specific events appear in `raw`.

Backend mappings:

- **GitHub**: REST `/issues/{n}/timeline` (richer than `/events`); each timeline event maps to a `kind`. ~30–50 events common per long-lived issue.
- **Linear**: GraphQL `issue.history` returns IssueHistory items with action types.
- **Jira**: `/issue/{key}/changelog` + comment endpoint.
- **Bugzilla**: `/bug/{id}/history` returns the journal.
- **Backends without an event API**: emit `[]` and the chat falls back to git log + chat-audit.jsonl.

The chat does **not** persist tracker-side events to disk; it queries
on demand. Tokens are pay-as-you-go. For "what changed yesterday?",
the chat first asks chat-audit.jsonl (cheap local read) for the IDs
that changed, then does targeted `list_events` for each.

### 21.6 Audit query token economy

| Query | Mechanism | Approx tokens |
|---|---|---|
| "what changed yesterday?" (≤30 events) | local jsonl scan + zero or one `list_events` per id | ≤2K |
| "show audit for TD-031" (~20 events) | one `list_events` call | ~3K (GH timeline) / ~2K (Linear) |
| "what did pack-chat do this week?" (~200 events) | local jsonl scan; trackers consulted only for cross-validation | ~5K |
| "which entries had errors today?" | local jsonl scan only (errors live there) | ~1K |

The local jsonl is the cheap path. The tracker is consulted only when
the question requires *backend-side state* (e.g., "did the assignee
change last week even though the chat didn't touch it?" — answer
requires backend events because that change happened outside chat).

### 21.7 Privacy / leakage

The chat-audit JSONL contains operation arguments. If those include
free-text user content (e.g., comment bodies), the JSONL grows in
size. The default behavior:

- `args` is stored as a **digest** (`{kind: "comment", body_sha256: "..."}`) by default, not the full body. The full body is in the tracker; the digest is enough to correlate.
- A `pack audit verbose` toggle in `tracker.toml` opts into full-body storage.

This keeps the JSONL bounded; a 1,000-operation log is ~500 KB at
default verbosity.

### 21.8 Audit log retention

`.pack-tracker/chat-audit.jsonl` rolls quarterly. Old logs go to
`.pack-tracker/chat-audit-archive/YYYY-Q.jsonl.gz`. The chat retains
12 quarters by default; `[audit]` block in `tracker.toml` configures
retention.

Git log retention is whatever the project chooses; the chat does not
intervene.

### 21.9 Audit and reverse migration

When reverse migration runs (V1 §6.5), the chat-audit.jsonl is preserved
as-is. It is not part of the v10 grammar; it lives as a sidecar.
Reverse-migration emits a one-line note in the sidecar: "Audit log
preserved at .pack-tracker/chat-audit.jsonl through reverse." Re-forward
of a previously-reversed surface re-reads the existing JSONL and
appends.

This makes the audit log *cumulative across modes*, which is the
right shape for P4 ("queryable, not just available").

---

## 22. P5 — Cognitive load floor: verb surface

This section enumerates every tracker-related verb v11 introduces, with
exact spelling and intent, plus the colloquial mappings the chat
recognizes. New concepts beyond v10 are justified.

### 22.1 The verb table (exhaustive)

| Verb | Form | Intent | Required for v11? |
|---|---|---|---|
| `pack tracker init` | shell wrapper over `tracker-migrate.sh + ensure-labels` | First-time opt-in; writes `tracker.toml`, validates `gh auth`, creates issue templates and labels, runs forward migration. | yes |
| `pack tracker disable` | shell wrapper | Reverse-migrates and sets `tracker.toml mode.state = "flat-file"`. | yes |
| `pack tracker doctor` | shell wrapper | Validates `tracker.toml`, refreshes capability cache, validates mirror freshness, validates mapping integrity, validates template freshness. Emits a report. | yes |
| `pack tracker status` | shell wrapper | One-screen view of current state: mode, backend, repo, mapping count, mirror freshness, template freshness, last-forward-run, last-reverse-run. | yes |
| `pack tracker update-templates` | shell wrapper | Upgrade entries from older `template_version` to current. (P2; §19.) | yes |
| `pack tracker mirror-rebuild` | shell wrapper over `tracker-migrate.sh --mirror-only` | Force regenerate mirror files from tracker state. Recovery aid for R1 (V1 §17.1). | yes |
| `pack triage <id>` | colloquial routed verb | Drive the triage state-machine transition for the named entry. (§18.) | yes |
| `pack audit query [...]` | shell wrapper | Audit query (§21.3). | yes |
| `pack feedback upstream [...]` | shell wrapper | Batch-upstream PACK-FEEDBACK.md entries to the pack repo (V1 §7.5). | yes |

That is the **9-verb surface** v11 introduces. Three of these are new
*concepts* the user must learn beyond v10's flat-file workflow:

1. **Mode** (tracker vs flat-file) — exposed by `pack tracker status` and `pack tracker init / disable`. Justified by the opt-in design itself; the user has to know which mode they're in.
2. **Mirror** — exposed by `pack tracker mirror-rebuild` and the read-only header on mirror files. Justified by the migration model (V1 §6.3); without the mirror concept, the user thinks BACKLOG.md is editable when it isn't.
3. **Template version** — exposed by `pack tracker update-templates` and `pack tracker doctor`. Justified by P2 (§19); without the concept, template drift accumulates silently.

The pack does **not** introduce concepts for:

- "Provider", "backend", "abstraction" — these are architect vocabulary; the user sees only `pack tracker init` and `pack tracker disable`.
- "Capability flags" — surfaced by `pack tracker doctor` only when a capability mismatch causes a failure; the user does not learn the term proactively.
- "Marker trio", "auto-routing label", "template_version field" — internal mechanics; the user files via the form and the chat handles the rest.

This keeps the surface bounded.

### 22.2 Colloquial mappings

The chat recognizes these natural-language phrases as the verb listed:

| Phrase | Resolves to |
|---|---|
| "set up the tracker" / "switch to GH Issues" / "enable issue tracking" | `pack tracker init` |
| "switch back to flat files" / "turn off the tracker" / "go back to BACKLOG.md" | `pack tracker disable` |
| "check tracker health" / "tracker doctor" / "are we good?" | `pack tracker doctor` |
| "tracker status" / "what's the tracker doing?" / "are we on the tracker?" | `pack tracker status` |
| "upgrade the templates" / "templates are stale" / "fix template versions" | `pack tracker update-templates` |
| "rebuild the mirror" / "regenerate BACKLOG.md" / "the mirror is wrong" | `pack tracker mirror-rebuild` |
| "triage TD-031" / "accept BD-040 into v12" / "let's triage external #42" | `pack triage <id>` |
| "what changed yesterday?" / "show audit for TD-031" / "audit log" | `pack audit query` |
| "file this upstream" / "send to the pack" / "upstream the feedback" | `pack feedback upstream` |

The chat's mapping table lives in `project-template/docs/pack/PM-CHAT.md`
"Colloquial routing" section and the parallel pack-side `PACK-CHAT.md`.
The trinity rule applies if either changes the H2 set.

### 22.3 Concepts that are *not* new

The pack's existing v10 concepts continue to apply unchanged. The user
already knows:

- BD-NNN / TD-NNN namespacing.
- Phase-N references.
- BACKLOG.md / STATUS.md / IMPLEMENTATION_PLAN.md file family.
- Pack Chat / PM Chat distinction.
- The trinity rule (and why it matters).
- TD-TBD code-comment workflow.
- PACK-FEEDBACK.md as the local upstream-feedback log.

v11 reuses every one of these. Tracker-mode does not require the user
to relearn the BD-NNN counter rule, the phase-anchor algorithm, the
BACKLOG entry format, or any of the sortable / searchable / filterable
patterns from v10 — those are now backed by the tracker, but the
*user-facing semantics* are the same.

### 22.4 Justification of every new verb (P5 bar)

P5 says: "New concepts beyond what v10 already requires must be
justified by clear user value, not architectural elegance."

| Verb | User value |
|---|---|
| `pack tracker init` | Opt-in is the design's load-bearing affordance. Without it, no user can move from flat to tracker. |
| `pack tracker disable` | Reverse migration is a `DESIGN-BRIEF.md` §3.1 mandatory feature; the user must have a way to invoke it. |
| `pack tracker doctor` | Diagnostic surface for the failure-mode UX in V1 §9; without it, the user has no recovery path beyond hand-editing config. |
| `pack tracker status` | One-line view of the current mode + freshness; saves the user from inferring state from filesystem layout. |
| `pack tracker update-templates` | Required by P2 (§19). Without it, template drift accumulates silently. |
| `pack tracker mirror-rebuild` | Required by R1 mitigation (mirror staleness). The user has a recovery verb. |
| `pack triage <id>` | The triage state machine (§18) needs a user-driven transition; this is its name. |
| `pack audit query` | Required by P4 (§21). Without it, the audit data is captured but not queryable. |
| `pack feedback upstream` | The upstream mechanism (V1 §7.5) needs a name; existing v10 had no such verb. |

Each verb is justified by a goal in the brief, not by elegance.

### 22.5 Verbs deliberately NOT added

To keep the surface bounded, V2 declines to add:

- **`pack tracker pause`** (a "muted" middle state between tracker and flat-file). Mode is binary by D-5; pause adds a third state with no clear semantics.
- **`pack tracker fork`** (start a parallel tracker on another backend). Trade-off T6 (V1) covers this; out of v11 scope.
- **`pack tracker analytics`** (token-cost view). The fixture in §12 is the v11 mechanism; not a verb the user runs interactively.
- **`pack tracker repair`** (auto-recovery shortcut). Per D-7 (no silent retry), the user always sees the diagnostic before deciding; `doctor` is enough.
- **`pack tracker squash`** (compact the audit log). Retention rolls quarterly per §21.8; manual squash is filesystem-level (`gzip` / `mv`), not a pack verb.

If user feedback in v11.x shows a need, these are easy adds in a
minor.

---

## 23. P6 — Discoverability

This section designs how a new user finds tracker commands in under 5
minutes from a fresh chat session, without external documentation.

### 23.1 The 5-minute path

A new user lands in a Pack Chat / PM Chat session for the first time
on v11. Within 5 minutes:

```
[T+0:00] User: starts session.
[T+0:10] Chat (via pack-startup or pm-startup) prints:

  Optiquity AI Agent Config Pack v11.0.
  Tracker mode: flat-file (default).
  To enable issue tracking, say "set up the tracker" or run "pack tracker init".
  See "pack help" for all commands.

[T+0:30] User says "set up the tracker."

[T+0:40] Chat prints:
  pack tracker init will:
    1. Validate your gh auth.
    2. Create .github/ISSUE_TEMPLATE/{work-item.yml, inbound.yml}.
    3. Create the v11 label set in your repo.
    4. Forward-migrate your BACKLOG.md / STATUS.md to GH Issues.
  Are you ready? (yes / no / show me the details)

[T+1:00] User: yes.

[T+1:10] Chat runs the script.

[T+3:00] Chat prints:
  Tracker enabled.
  Migrated 47 BD entries, 6 phase epics.
  Mirror files regenerated.
  Run "pack tracker doctor" any time to validate state.
  Run "pack tracker status" for a one-line view.
  Run "pack tracker disable" to revert.

[T+3:30] User explores.
```

5 minutes is a soft target; the actual time depends on backlog size
(the migration step dominates). For OT-3× scale (~340 TD entries), the
migration runs in 1–3 minutes (audit §A.5 token estimates × API
latencies). For a fresh project, sub-30 seconds.

### 23.2 `/help` integration

Each CLI's slash-help surfaces tracker verbs. The pack ships a
help-content fragment that the per-CLI integration includes:

`project-template/docs/pack/HELP-FRAGMENT.md`:

```markdown
## Tracker commands (v11+)

If issue tracking is enabled (default is flat files):
  pack tracker init                  Enable issue tracking on this surface.
  pack tracker disable               Reverse-migrate and disable.
  pack tracker doctor                Validate state.
  pack tracker status                One-line view.
  pack tracker update-templates      Upgrade entries to current templates.
  pack tracker mirror-rebuild        Regenerate mirror files.
  pack triage <id>                   Triage an entry through the state machine.
  pack audit query [...]             Query the audit trail.
  pack feedback upstream             Send PACK-FEEDBACK to the pack repo.
```

Per-CLI integration:

- **Claude Code.** `.claude/skills/pack-help/SKILL.md` reads this fragment and emits it on `pack help`.
- **Codex CLI.** `~/.codex/instructions/` includes a routing rule: when user asks for help, read the fragment.
- **Gemini CLI.** Same approach: a `commands/help.md` fragment.

The verbs are surfaced identically across the three CLIs at the LCD
floor.

### 23.3 `pack help` verb

`pack help` is a top-level verb (separate from each CLI's `/help`).
It prints the same fragment plus the colloquial mapping table from
§22.2. Implemented as a tiny shell script that cats the fragment:

`scripts/pack-help.sh`:

```bash
#!/usr/bin/env bash
cat "$(dirname "$0")/../project-template/docs/pack/HELP-FRAGMENT.md"
echo
echo "Colloquial phrases:"
echo "  'set up the tracker'           → pack tracker init"
echo "  'check tracker health'         → pack tracker doctor"
echo "  'switch back to flat files'    → pack tracker disable"
echo "  'rebuild the mirror'           → pack tracker mirror-rebuild"
echo "  'upgrade templates'            → pack tracker update-templates"
echo "  'triage TD-031'                → pack triage TD-031"
echo "  'what changed yesterday?'      → pack audit query --since=yesterday"
echo "  'file this upstream'           → pack feedback upstream"
```

### 23.4 Colloquial-form router

The chat (Pack Chat / PM Chat) routes free-form phrases to verbs via a
small declarative table in `PACK-CHAT.md` / `PM-CHAT.md`:

```markdown
## Tracker verb routing (v11)

The chat recognizes these phrases:

| Phrase | Verb |
|---|---|
| set up / enable / configure (the) tracker | pack tracker init |
| switch back / disable / turn off (the) tracker | pack tracker disable |
| ... (full table) ... |
```

The table is the same as §22.2 but lives in the chat-operating manual
trinity-adjacent file. The chat reads it at session start.

### 23.5 README discoverability

The pack repo's `README.md` Repository Layout section gains a brief
"v11+ Tracker Mode" sub-section pointing at the `OPTIONAL-FEATURES.md`
tracker section and the in-pack `pack help` verb. Two sentences,
hyperlinks. The tracker is one of the optional features documented
there alongside per-CLI MCP acceleration.

The client-project `README` (in `project-template/`) does not
hardcode tracker verbs; the project's README is project-specific. But
the project's `STATUS.md` "How to Update This File" section gains a
one-line note: "If tracker mode is on (see `pack tracker status`),
this file is a regenerated mirror; edit via PM Chat or `pack tracker
mirror-rebuild`."

### 23.6 In-error-message discoverability

Per V1 §9, every error message names the next-step verb. V2
strengthens this: every failure-mode message ends with one
unambiguous "run X to fix" line. The user discovers verbs by
encountering errors that recommend them.

Examples:

```
Tracker schema unexpected.
  Operation: sub_issue_create
  Underlying: GraphQL field 'addSubIssue' not found.
  → Run: pack tracker doctor
```

```
Templates out of date.
  12 entries on v11.0.0; current v11.1.0.
  → Run: pack tracker update-templates --dry-run
```

This is the third discoverability path (alongside `pack help` and
colloquial routing): the user learns verbs *as they need them*, not
by reading reference docs.

### 23.7 The 5-minute SLA, validated

The architecture is consistent with the 5-minute target if and only
if:

- pack-startup / pm-startup print the "set up the tracker" hint at every flat-file-mode session.
- `pack tracker init` is one prompt + one approval + a runtime equal to the migration's actual API time.
- Errors during init have one-line recoveries.
- `pack tracker status` returns in <1s.

These are designed-in. The planner verifies during implementation;
the reviewer measures during the post-ship token-fixture run (§12).

---

## 24. OQ-16 — Multi-template vs single-template strategy

V1 §4 chose six separate `.github/ISSUE_TEMPLATE/*.yml` issue forms
(D-4: bd-entry, td-entry, phase-epic, pack-feedback, bug-report,
feature-request). This section defends that choice rigorously against
two alternatives:

- **Alt A — One *true* single template** with an all-in-one Type+Category dropdown driving all entry types.
- **Alt B — Form family** (V2 D-4-V2; two composite forms: `work-item.yml` for pack-managed work and `inbound.yml` for external/feedback intake).

The verdict is **Alt B** — the form family. The rationale, axis by axis,
follows. Concrete data from `EXTERNAL-RESEARCH.md` and `RESEARCH-AUDIT.md`
is cited inline.

### 24.1 Token economy: cost per entry creation

| Axis | V1 (six forms) | Alt A (one form) | Alt B (form family) |
|---|---|---|---|
| Form payload submitted to GH | ~700 tokens equivalent (one of 6 form bodies) | ~3,500 tokens equivalent (every field rendered, regardless of which Type) | ~1,200 tokens equivalent (the relevant composite) |
| Issue body created | ~250 tokens (one form's structured fields concatenated) | ~600 tokens (all fields, including blanks for non-applicable Types) | ~280 tokens (composite's filled fields; blanks for non-applicable per Type) |
| Auto-routing labels at intake | exactly the right set per form | one Type+Category dropdown drives a label set; lookup table in chat-side post-process | composite `labels:` key + chat post-process per Type/Category |

V1 wins narrowly on per-create payload size (one form at a time).
Alt B is close (composite is small enough). Alt A loses materially:
the form rendering and the body include all fields regardless of
applicability, so empty / not-applicable sections balloon the body.

For the BD/TD/phase-epic case, V1's `bd-entry.yml` body and Alt B's
`work-item.yml` (with Type=bd) body are within ~30 tokens of each
other. The difference is irrelevant compared with one BD entry's
average free-text content (~500 tokens).

**Verdict on this axis:** V1 marginally cheapest, Alt B essentially
tied, Alt A loses. Tie-breaker between V1 and Alt B is elsewhere.

Citation: `EXTERNAL-RESEARCH.md` §6.1 (per-issue 30 tokens at minimum
projection; 200–600 tokens at full projection).

### 24.2 Token economy: cost per filter / sort / search query

This is where the analysis diverges meaningfully.

A query like *"all open BD entries in scope of phase-3"* is:

```
gh issue list --label bd-entry --label phase-3 --label status:open --json number,title
```

In all three strategies, the **labels carry the routing**. V1, Alt A,
and Alt B all use the same labels (`bd-entry`, `phase-3`, `status:open`).
The Type field on the issue is the same value (or its label
equivalent). The query cost is identical.

The difference is in *how the chat composes the filter*. V1 has
hardcoded "BD entries are filtered by `bd-entry` label" because the
form created them; Alt B has the same hardcoded fact. Alt A would
need the chat to remember "BD entries have a `type:bd` label rather
than a separate label" — same logic, slightly different surface.

| Axis | V1 | Alt A | Alt B |
|---|---|---|---|
| Default-filter ergonomics | "filter by bd-entry" — natural | "filter by Type=bd via label `type:bd`" — fine | "filter by bd-entry" — natural |
| Advanced query (boolean) | works as-is (audit §A.2 advanced search GA) | works | works |
| Per-query token cost | identical | identical | identical |

**Verdict:** wash. All three strategies query identically because
labels do the routing.

Citation: `EXTERNAL-RESEARCH.md` §1.6 (search qualifiers, advanced
search GA 2025-09-04); `RESEARCH-AUDIT.md` §A.2 (advanced search
verified).

### 24.3 Token economy: cost per migration (forward / reverse)

For forward migration of N entries (V1 §6.2 algorithm):

| Strategy | Per-entry create | Total for N=340 |
|---|---|---|
| V1 (six forms) | one `provider.create` call per entry; no form actually consulted (the script writes payloads directly) | identical |
| Alt A | identical | identical |
| Alt B | identical | identical |

**The forms are not consulted by the migration script** — the script
writes the canonical body and labels directly via `provider.create`.
The forms exist only for the *user-facing* New Issue UI.

So forward / reverse migration cost is identical across the three
strategies.

**Verdict:** wash.

Citation: V1 §6.2 (forward mapping algorithm) + `EXTERNAL-RESEARCH.md`
§7.1 (prior-art idempotency conventions).

### 24.4 API surface: GH REST behavior

GH REST does not differentiate between issues created from different
forms; the form is metadata at creation time only. The API surface is
identical across the three strategies.

The form picker (the `?template=<name>` query parameter) does change:

- V1: `?template=bd-entry.yml`, `?template=td-entry.yml`, etc. — six valid templates.
- Alt A: `?template=universal.yml` — one valid template.
- Alt B: `?template=work-item.yml`, `?template=inbound.yml` — two valid templates.

For programmatic create (the chat case), this is irrelevant — the
chat sends `provider.create(payload)`. For the user-facing UI, see
§24.13 below.

**Verdict:** wash for the chat surface. UX consideration deferred to
§24.13.

Citation: `EXTERNAL-RESEARCH.md` §1.1 (issue templates / forms; URL
parameters).

### 24.5 API surface: GH GraphQL behavior

GraphQL mirrors REST here: the issue's `body`, `labels`, `type` are
queryable identically regardless of how the issue was created.

GraphQL one-shot patterns (for sub-issue tree walks, audit §A.2)
operate on `Issue` fields, not on form provenance. Wash.

**Verdict:** wash.

Citation: `EXTERNAL-RESEARCH.md` §1.5 (Projects v2 GraphQL); §3.2 (GH
MCP issues toolset).

### 24.6 Search / sort / filter: default-query ergonomics

The chat operates on labels. With v11's label set (~45 labels per
§19.9):

- *"Show me open BDs."* — `--label bd-entry --label status:open`. Identical across strategies.
- *"Show me TDs in phase-3 with severity functional."* — `--label td-entry --label phase-3 --label severity:functional`. Identical.
- *"Show me everything that needs triage."* — `--label needs-triage`. Identical.

The default-query ergonomics depend on the label set, not the form.

**Verdict:** wash.

### 24.7 Search / sort / filter: advanced-query ergonomics

Advanced search (`type:Bug OR type:Epic`) operates on the **issue
type** field (audit §A.2 issue type GA). All three strategies use the
issue type field identically:

- V1 BD form: `type: Task` at intake.
- V1 phase-epic form: `type: Epic` at intake.
- Alt A: chat-side post-process sets `type:` based on the dropdown.
- Alt B: chat-side post-process sets `type:` based on Type/Category.

The advanced-query *user* sees the same field. The form just sets it;
the search reads it.

**Verdict:** wash.

### 24.8 Cross-tracker portability: Linear behavior

Linear's "create issue" UI presents:

- A free-text title.
- A team picker.
- An issue-type picker (per-team workflow states).
- Other fields (priority, project, cycle, parent, assignee, labels) appearing as optional.

There is no Linear "issue template" mechanism analogous to GH's. Form
shape doesn't port — what ports is the *data shape* (what fields a BD
entry needs).

| Axis | V1 | Alt A | Alt B |
|---|---|---|---|
| Translation effort to Linear | Map each of 6 GH forms to Linear's "Type + custom fields" pattern; define ~6 Linear issue types | Map one universal form to one Linear "default" issue type with everything as optional | Map two composites (work-item, inbound) to two Linear issue types |

Alt B wins here: two Linear issue types are easier to maintain than
six. V1's six map onto six Linear types or six Linear "issue
templates" (Linear has those for paid plans only — audit §A.7
acknowledges, but that's not v11 ship). Alt A maps to one bloated
type that needs every field as optional.

**Verdict:** Alt B > V1 > Alt A.

Citation: `EXTERNAL-RESEARCH.md` §9.1 (Linear capability surface);
`RESEARCH-AUDIT.md` §A.7 (Linear MCP first-party server confirmation).

### 24.9 Cross-tracker portability: Jira behavior

Jira issue creation uses *issue types* (Bug, Task, Story, Sub-task,
Epic). Each issue type has its own "create screen" with required and
optional fields.

| Axis | V1 | Alt A | Alt B |
|---|---|---|---|
| Translation effort to Jira | Six GH forms ≈ six Jira "create screens" or six issue types (~half align with Jira's natural set) | One universal form ≈ a single Jira issue type with everything optional (Jira hates this — its UI assumes type-driven required-field validation) | Two composites ≈ two Jira issue types: "Pack work item" (≈ Task) and "Inbound" (≈ Bug + Improvement variants) |

Alt B aligns with Jira's natural shape. V1 forces six separate
screens. Alt A is anti-Jira — Jira's whole structure is driven by
issue type.

**Verdict:** Alt B > V1 > Alt A.

Citation: `EXTERNAL-RESEARCH.md` §9.2 (Jira hierarchy + workflow);
`RESEARCH-AUDIT.md` §B.1 (Jira free 3-level hard cap).

### 24.10 Cross-tracker portability: Bugzilla / Trello (low-capability)

| Backend | V1 | Alt A | Alt B |
|---|---|---|---|
| Bugzilla | Six forms ≈ six "products" — but Bugzilla has only one "create bug" UI per product, with required-field config per type. Translation: collapse to a few products. | One form ≈ one product (cleaner). | Two forms ≈ two products (fits well). |
| Trello | Trello has no issue templates; cards are free-form. Translation is the same across all three: emit a card with body text + labels. | same | same |

**Verdict:** wash for Trello; Alt B = Alt A > V1 for Bugzilla.

Citation: `RESEARCH-AUDIT.md` §B.3 (Bugzilla emulation; no native
hierarchy); §B.9 (Trello).

### 24.11 P2 maintenance ergonomics: adding a field to BD-entry in v12

| Strategy | What changes |
|---|---|
| V1 | Edit `bd-entry.yml` (add field), translation rule for v12 (1 form's translation), test, commit, ship. |
| Alt A | Edit `universal.yml` (add field, mark "BD-only" in help text), translation rule covers all entry types in one rule. |
| Alt B | Edit `work-item.yml` (add field, mark "BD-only" via Type help text), translation rule for the work-item form. |

Effort:

- V1: 1 file + 1 translation rule.
- Alt A: 1 file + 1 translation rule (broader scope; risk of accidental TD breakage).
- Alt B: 1 file + 1 translation rule.

**Verdict:** Alt B = V1 > Alt A. Alt A's "broader scope" risk is
real: a v12 change targeted at BD that affects the universal form
risks affecting TD or inbound entries too unless every translation
rule is carefully scoped.

Citation: §19.4 (translation rules manifest).

### 24.12 P2 maintenance ergonomics: adding a new entry type in v12

| Strategy | What changes |
|---|---|
| V1 | New file `entry-type-X.yml`. New auto-routing labels. Translation rule for migration. New section in `pack help`. New chat triage handler. |
| Alt A | New option in the universal Type dropdown. New auto-routing labels. New chat triage handler. |
| Alt B | If the new type fits "pack-managed work", add a Type option in `work-item.yml`; if it fits "inbound", add a Category option in `inbound.yml`; if it fits neither, add a third form file. |

Effort:

- V1: 1 new file, 1 translation entry, 1 chat handler. ~80 lines of YAML + rule + handler.
- Alt A: 1 dropdown option, 1 chat handler. ~10 lines.
- Alt B: 1 dropdown option in the right form, 1 chat handler. ~10 lines (if it fits an existing family) or ~80 (if it needs a new form).

**Verdict:** Alt A > Alt B > V1. Alt A is cheapest at *raw*
add-a-type effort, but pays the cost in §24.13 (UX) and §24.11
(field-add risk).

### 24.13 P2 maintenance ergonomics: label-set evolution

The label set evolves independently of the forms (§19.9). Forms refer
to labels at intake; chat-side post-process applies the rest. Form
strategy doesn't materially affect label-set evolution.

**Verdict:** wash.

### 24.14 Future enhancements: new entry types

If v12 adds, e.g., a "spike" entry type (research spike with a
scoped budget), the cost is:

| Strategy | Cost |
|---|---|
| V1 | New `spike-entry.yml` + chat handler + label `spike-entry` + triage rule + reverse-migration grammar extension. |
| Alt A | New Type option + chat handler + label + triage rule + grammar extension. |
| Alt B | Spike fits "pack-managed work"; add `spike` to `work-item.yml` Type dropdown + chat handler + label + triage rule + grammar extension. |

V1 has the most ceremony per addition. Alt A and Alt B are tied. Alt
B's framing (which family does this belong to?) is a useful
forcing-function for the maintainer.

**Verdict:** Alt B > Alt A > V1 (with a small preference for Alt B's
forcing-function value).

### 24.15 User-facing UX: the New Issue dropdown

When a user clicks "New Issue" in the GH web UI, GH lists the
available forms in a picker. Audit §A.2 verified this is the standard
issue-form intake UX.

| Strategy | What the user sees |
|---|---|
| V1 | Six choices: "Pack development backlog item (BD-NNN)", "Project technical debt (TD-NNN)", "Phase epic", "Pack feedback (from a client project)", "Bug report", "Feature request". The blank-issue link is hidden via `config.yml`. The user has to read names, decide which fits. |
| Alt A | One choice: "Issue or feedback". The user clicks, sees a Type+Category dropdown with ~15 options. The user has to read dropdown entries to find their case. |
| Alt B | Two choices: "Pack work item" (BD/TD/phase-epic) and "Inbound report or feedback" (bug/feature/pack-feedback). Then a Type or Category dropdown with 3 or 7 options. |

User cognitive load:

- V1: 6 form names to read; pick one. ~30s.
- Alt A: 1 form to click; 15 dropdown options to read. ~45s (longer dropdown read).
- Alt B: 2 forms to read; pick one; ~3–7 dropdown options. ~20s.

Alt B wins on UX. V1 is fine but slightly noisier. Alt A's "single
massive form" anti-pattern is well known to under-perform on form
completion (every project that has tried "one form for everything"
reports it).

**Verdict:** Alt B > V1 > Alt A.

Citation: `EXTERNAL-RESEARCH.md` §1.1 (template picker behavior);
generic UX principle (no specific citation; this is a form-design
heuristic).

### 24.16 User-facing UX: filling the form

| Strategy | Form-fill experience |
|---|---|
| V1 | Each form has only its applicable fields; no irrelevant fields shown. |
| Alt A | One form with conditional-feeling visibility based on Type+Category. **GH issue forms do not support true conditional visibility** (audit §A.2; the form schema has no `visible_if` clause). All fields are shown; help text says "(applicable to Type=X)". User fills ~half the form, ignoring fields. |
| Alt B | Each composite form has its applicable fields plus 2–3 type-conditional ones. The same "no real conditional visibility" issue applies, but at smaller scope. |

V1 is the cleanest at fill time. Alt B is acceptable. Alt A is
crowded.

**Verdict:** V1 > Alt B > Alt A.

Citation: `EXTERNAL-RESEARCH.md` §1.1 (issue form field types — no
conditional visibility primitive).

### 24.17 Synthesis

The verdict matrix:

| Axis | V1 | Alt A | Alt B |
|---|---|---|---|
| Token: per-create | best | worst | tied with V1 |
| Token: per-query | tied | tied | tied |
| Token: per-migration | tied | tied | tied |
| API: REST | tied | tied | tied |
| API: GraphQL | tied | tied | tied |
| Search default ergonomics | tied | tied | tied |
| Search advanced ergonomics | tied | tied | tied |
| Cross-tracker: Linear | OK | poor | best |
| Cross-tracker: Jira | OK | poor | best |
| Cross-tracker: Bugzilla/Trello | OK | best | tied with Alt A |
| P2: add-field-to-BD | best (tied with Alt B) | risky | best |
| P2: add-new-type | worst | best | tied with Alt A |
| P2: label-set evolution | tied | tied | tied |
| Future: new entry types | worst | tied | best |
| UX: New Issue dropdown | OK | worst | best |
| UX: form-fill | best | worst | OK |

**Alt B (form family) wins overall.** It loses to V1 only on form-fill
cleanness (because composite forms show some non-applicable fields)
and ties or beats V1 elsewhere. It dominates Alt A everywhere except
"add-new-type effort" (where they tie) and "Bugzilla translation"
(where Alt A is slightly cleaner).

V1's loss to Alt B is concentrated in **cross-tracker portability**
and **future enhancements** — exactly the axes P2 (maintenance
ergonomics) and the design-brief's cross-tracker mandate (§3.1) name
as load-bearing.

**Decision: D-4 superseded by D-4-V2.** v11 ships with the form
family (Alt B): `work-item.yml` and `inbound.yml`, each with a
Type/Category dropdown driving labels and chat-side specialization.

### 24.18 What V2 keeps from V1 §4

All field semantics from V1's six forms are preserved in the two V2
forms. The mapping is:

- V1 `bd-entry.yml` fields → V2 `work-item.yml` fields with `wi-type=bd`.
- V1 `td-entry.yml` fields → V2 `work-item.yml` fields with `wi-type=td`.
- V1 `phase-epic.yml` fields → V2 `work-item.yml` fields with `wi-type=phase-epic-skeleton` (rare path) + `provider.create()` (common path).
- V1 `pack-feedback.yml` fields → V2 `inbound.yml` fields with `in-category=pack-feedback-*`.
- V1 `bug-report.yml` fields → V2 `inbound.yml` fields with `in-category=bug`.
- V1 `feature-request.yml` fields → V2 `inbound.yml` fields with `in-category=feature-request`.

No field is dropped. The METHODOLOGY § Part 7 mapping (V1 §4.1 last
table) holds verbatim.

---

## 25. OQ-17 — Structure vs free-text line in entry templates

V1 §4 made an implicit choice: dropdowns for Type, Status, td-scope,
td-severity; textareas for Blockers, Unblocks, File/Symbol,
Description, Context, Resolution. This section defends that line
against more-structured and less-structured alternatives.

### 25.1 The candidates

- **More-structure.** Treat Blockers as a structured list (one
  `input` field per blocker, with regex validation for `BD-NNN` /
  `TD-NNN` / `phase-N` / `#N` shape). Treat File/Symbol as a
  repo-tree autocomplete. Treat Description / Context / Resolution as
  rich-text editors with a markdown subset, not free textareas.
- **V1 / V2 (current).** Dropdowns for the four fields with
  enumerated values; textareas for the rest, with line-per-id grammar
  parsed by chat at triage.
- **Less-structure.** One freeform body field. The user types
  `Blockers: BD-040, BD-041` as a line in the body. Chat parses the
  body to extract structured fields.

The verdict is **V1/V2 (current)**. The defense follows axis by axis.

### 25.2 Label routing

The auto-routing label set at intake is driven by enumerated
dropdowns (Type, Status, td-scope, td-severity). Without those
dropdowns:

- More-structure does not change this — the dropdowns drive labels;
  more structure on Blockers / File-Symbol doesn't add label routing.
- Less-structure breaks: the chat would have to *parse free text* to
  decide the labels at intake. GH issue forms can't parse body text
  to set labels; the form's `labels:` key applies fixed labels at
  creation, not derived ones. The chat-side post-process would need
  to read the body, parse, and re-label — an extra round trip every
  intake.

**Verdict:** more-structure ≈ V1/V2 > less-structure.

Citation: `EXTERNAL-RESEARCH.md` §1.1 (issue forms `labels:` key
applies fixed labels at intake; field types don't include conditional
label setting).

### 25.3 State-machine transitions

The state machine in §18 keys on label state (`status:open` →
`status:unblocked`). Label state is set by the dropdowns + chat
post-process.

- More-structure: no effect on transitions. Still keys on labels.
- Less-structure: chat must parse body to know the entry's status
  before transitioning. Free-text drift means the chat occasionally
  fails to parse. At scale (hundreds of entries) this is a real cost.

**Verdict:** more-structure ≈ V1/V2 > less-structure.

### 25.4 Search / filter / sort

GH search operates on labels, fields (state, milestone, type), and
body text. The dropdown-driven labels are searchable as label
filters. Body text is searchable as `in:body` qualifier (audit §A.2)
but at lower fidelity (full-text match, not exact field).

- More-structure: marginally better search if structured Blockers
  become a *field* (not a label). But GH issue forms don't expose
  field-level search beyond labels and the issue-type field — a
  structured Blockers list goes into the body anyway.
- V1/V2: dropdowns drive labels; labels searchable; body searchable.
- Less-structure: only body search; no label filtering possible.

**Verdict:** V1/V2 > more-structure (slightly) > less-structure.

Citation: `EXTERNAL-RESEARCH.md` §1.6 (search qualifiers; `label:`,
`in:body`, etc.).

### 25.5 API / GraphQL surface

Issue API surfaces:

- Labels: a queryable array on Issue.
- Body: a string.
- State, state_reason, type: scalar fields.
- Form-specified fields: written into body at creation time; not
  individually queryable beyond `in:body` text search.

So:

- More-structure: extra structured input fields go into body.
  Queryable by `in:body` text, not by structure.
- V1/V2: dropdowns → labels (queryable as labels); textareas → body
  sections (queryable as body text).
- Less-structure: everything is body text; queryable as text only.

**Verdict:** V1/V2 ≈ more-structure (both expose what's queryable;
extra input structure doesn't earn more API queryability) >
less-structure.

### 25.6 Migration round-trip

Forward (flat → tracker):

- V1/V2: BACKLOG entry's `Type:` line → dropdown value (a label).
  `Blockers:` line(s) → textarea content (verbatim). `Description:`
  block → textarea (verbatim). Round-trip is mechanical.
- More-structure: `Blockers:` line → multiple structured input
  fields; the migration script must split the comma-separated /
  newline-separated list into N fields. Reverse must re-join. Two
  more parsing steps; two more chances to drift on edge cases (e.g.,
  a blocker whose ID is `phase-N` containing a `-` already; or an
  entry with 20 blockers exceeding GH's input field count cap if any).
- Less-structure: free-text body. Migration must regex-parse the body
  to find `Blockers:` line. Reverse re-emits the line. Works as long
  as the chat doesn't accidentally rewrite the body in a way that
  breaks the regex; this risk is real at scale.

**Verdict:** V1/V2 best; more-structure adds parsing work for no
real gain; less-structure is brittle.

Citation: `RESEARCH-AUDIT.md` §A.6 (prior-art migration patterns —
title markers + body footer markers; structured forward without
structured backward fails idempotency).

### 25.7 Capability-flag interaction

How does the structure choice port to backends with different native
structure?

- **Linear custom fields.** Linear has rich custom fields per team.
  More-structure could map structured Blockers to a Linear custom
  field; V1/V2 maps to body text; less-structure maps to body text.
  Linear custom fields are passthrough (provider's `custom_fields.passthrough_only = true`),
  so the chat does not exploit them — this advantage is theoretical.
- **Bugzilla keyword/flag/component.** Bugzilla has no general label
  concept; it has keywords (free strings), flags (boolean per-bug),
  and components (per-product taxonomy). All three structure
  alternatives map identically (their dropdowns become Bugzilla
  flags / keywords; their textareas become body content).
- **Backends without custom fields (Trello).** Trello has no
  structured field surface; everything is card body or label. Wash
  across the three.

More-structure looks attractive against Linear's surface but cannot
be exploited generically (passthrough only). V1/V2 ports cleanly
because dropdown→label is universal across all 12 trackers in the
audit set.

**Verdict:** V1/V2 ≥ more-structure (V1/V2 is the more general
choice; more-structure has only theoretical Linear gain) >
less-structure.

Citation: `RESEARCH-AUDIT.md` §A.9 (capability-flag taxonomy);
§B.3 (Bugzilla keyword/flag/component); §A.7 (Linear custom fields
passthrough).

### 25.8 User friction at create time

| Strategy | Form-fill experience |
|---|---|
| More-structure | More fields. Each Blocker is a separate row; user clicks "+" to add. File/Symbol autocomplete delays as it queries the repo tree. Description editor has chrome. ~40s longer per entry vs V1/V2. |
| V1/V2 | Type, Status, scope, severity dropdowns + 6 textareas. ~90 seconds per typical entry. |
| Less-structure | One body. User types. ~60 seconds. But the user has to remember the format. |

The user friction trade-off is between "less typing, more clicking"
(more-structure) and "more typing, less constraint" (less-structure).
V1/V2 sits in the middle.

The deciding factor is **the v10 author already knows the BACKLOG
grammar**. They type `Blockers: BD-040` reflexively. Imposing
structured input fields breaks that flow without enough payback.

**Verdict:** V1/V2 ≈ less-structure > more-structure (assuming the
author knows v10).

### 25.9 Validation rigor

GH issue forms support:

- `validations.required: true`
- `validations.regex: <pattern>` on `input` only
- `validations.required` per checkbox in `checkboxes`
- (audit §A.2 verified)

Validation surface:

- More-structure: per-Blocker regex (`(BD|TD|phase)-[0-9]+|#[0-9]+`)
  enforces ID shape at intake. Dropdowns enforce enumerated values.
  File/Symbol doesn't have a server-side autocomplete API in GH issue
  forms; "autocomplete" as proposed is not native.
- V1/V2: dropdowns enforce enumerated values. Textareas have no
  validation; chat catches malformed entries at triage.
- Less-structure: no validation. Chat catches everything at triage.

**Verdict:** more-structure > V1/V2 > less-structure on rigor; but
V1/V2's chat-at-triage catches the same errors with one extra step.

Citation: `EXTERNAL-RESEARCH.md` §1.1 (issue form field types and
validations).

### 25.10 Cross-tracker portability

Already covered in §25.7. Summary:

- More-structure: looks good on Linear; generic on Bugzilla / Trello;
  no advantage on Jira beyond what V1/V2 provides.
- V1/V2: ports cleanly across all 12 audit trackers.
- Less-structure: ports trivially (everything is body) but loses
  routing fidelity.

**Verdict:** V1/V2 most portable.

### 25.11 Synthesis

| Axis | More-structure | V1/V2 | Less-structure |
|---|---|---|---|
| Label routing | tied with V1/V2 | tied | worse |
| State transitions | tied | tied | worse |
| Search / filter / sort | slightly worse (body fields, not searchable as fields) | best | worst (body-only) |
| API / GraphQL | tied | tied | tied |
| Migration round-trip | worse (extra split/join) | best | brittle |
| Capability flags | theoretical Linear gain only | most general | tied |
| User friction | worse (more clicks) | OK | OK (but author must remember format) |
| Validation rigor | best | OK | worst |
| Cross-tracker | OK on some, awkward on others | most portable | trivial but lossy |

**V1/V2 wins on six of nine axes; ties on two; loses to
more-structure on validation rigor only.**

The validation gap is real but small: V1/V2's chat-at-triage catches
the same malformed-ID errors that more-structure catches at intake.
The triage step is required anyway for `needs-triage` lifecycle
(§18); validation lives there cheaply.

**Decision (D-17): reaffirm V1's choice.** The structured/textarea
split as V1 §4 specified (and V2 §4.2 / §4.3 carries forward) is
the right line. V2 makes one small tightening: every textarea has
**explicit grammar documentation in the help text** so the author
knows what the chat will parse:

- `Blockers`: "One per line. Each line: an issue id (`BD-NNN`,
  `TD-NNN`, `#N`) or a `phase-N` token. Spaces allowed. Comments
  after `#` allowed."
- `Unblocks`: "Same grammar as Blockers."
- `File/Symbol`: "Free-form. Affected file path or symbol name."
- `Description`, `Context`, `Resolution`: "Free-form Markdown."

The grammar lives in the form's `description:` help text and is
reproduced in `METHODOLOGY.md` Part 7 (which already has the v10
grammar; v11 just gets one new line per field about parser
expectations).

### 25.12 What V2 explicitly rejects

V2 declines to:

- Move Blockers / Unblocks to structured input rows.
- Add a File/Symbol autocomplete (not feasible in native issue forms; would require an Action; out of scope per V1 §11.5).
- Replace textareas with rich-text editors.
- Collapse all fields to one body textarea.

These are documented to prevent re-litigation in future minors;
revisit only if a new constraint surfaces.

---

## 26. OQ-18 — `template_version` placement

`DESIGN-BRIEF.md` §3.1 mandates a `template_version` field per entry.
OQ-18 names four candidate carriers:

- (a) A **dedicated body field** (a labelled section in the issue body).
- (b) An **HTML comment marker** in the body (similar to the V1 `<!-- pack-id: TD-NNN -->`).
- (c) A **label** (`template:bd-v11.0.0`).
- (d) A **Projects v2 custom field**.

The OQ's four criteria:

1. Survive forward and reverse migration round-trips.
2. Not consume one of the limited 100 labels per issue if labels are
   precious for other axes.
3. Be queryable for `pack tracker update-templates` to find stale
   entries.
4. Apply consistently to all entry types.

### 26.1 Comparison

| Criterion | (a) Body field | (b) HTML comment | (c) Label | (d) Projects v2 custom field |
|---|---|---|---|---|
| Round-trip survival | survives if reverse parser knows the section name; user could accidentally edit the value | survives across all known GH transformations (sanitizer leaves comments alone — verified §6.2 V1; comments hidden from rendered output, low risk of user tampering) | survives via labels API; immune to body edits | survives if Projects v2 link is preserved (Projects v2 has no API stability issues that affect this; audit §A.2 verified Projects v2 GraphQL surface) |
| Label-budget cost | 0 labels | 0 labels | 1 label per issue | 0 labels |
| Queryability for `pack tracker update-templates` | requires `provider.list(filter={...})` then per-issue body fetch + parse — expensive for thousands of entries | same: requires per-issue body fetch | **cheap**: `provider.list(filter={label: 'template:bd-v11.0.0'})` returns the matching set in one call | requires Projects v2 GraphQL query; cheap if the project is configured; **requires every entry to be in a Project v2** |
| Consistency across entry types | yes | yes | yes (one label family per entry type, e.g., `template:bd-v*`, `template:td-v*`) | yes if all entries are in a Project; **breaks** for entries created outside a Project (which is the default) |
| Resilience to GH change | high (body is core surface) | high (body comments are core; sanitizer policy stable) | high (labels are core) | medium (Projects v2 is newer; field schema mutability is a known pain — audit §A.4) |
| Author edit hygiene | medium (a section labelled "Template version: v11.0.0" is visible and editable) | high (HTML comments are hidden from rendered view; users won't see them while reading) | high (labels are admin/curator territory) | high |
| Cross-tracker portability | high (body is universal) | high (most trackers preserve HTML comments in markdown) | high (labels universal); some backends use different label models (Linear hierarchical) | low (Projects v2 is GH-specific) |

### 26.2 Combined

| Carrier | Strengths | Weaknesses |
|---|---|---|
| (a) Body field | universal; round-trip OK | author can accidentally edit; expensive to query |
| (b) HTML comment | universal; round-trip best; not visible to author | expensive to query at scale (per-issue body fetch) |
| (c) Label | cheap to query (single API call); not author-editable | costs 1 label/issue; depends on label naming hygiene |
| (d) Projects v2 | structured; cheap query (if entries are in a Project) | GH-specific; requires Project membership |

No single carrier satisfies all four criteria optimally. Each loses
on one axis:

- (a) and (b) lose on queryability.
- (c) loses on label-budget consumption.
- (d) loses on cross-tracker portability and Project-membership
  dependency.

### 26.3 Decision: dual carrier — comment + label

**D-18: carry `template_version` in *both* an HTML comment marker
*and* a label.**

- The comment marker is the **authoritative round-trip carrier**.
  Reverse migration reads it. The forward migration writes it. The
  user does not see it.
- The label is the **queryable carrier**. `pack tracker
  update-templates` filters by label in one API call. The label is
  set by the form's `labels:` key at intake, and updated by chat
  post-process when the chat upgrades a template.

Both writes happen in the same operation: the form's `markdown` block
emits the comment trio; the form's `labels:` key emits
`template:work-item-v11.0.0`; chat-side post-process specializes to
`template:bd-v11.0.0` / `template:td-v11.0.0` based on the Type pick.

Migration:

- Forward writes both. (V2 §6.2 addendum.)
- Reverse reads the comment. The label is dropped on reverse (it's a
  GH-specific provenance marker; flat-file BACKLOG.md does not have
  the concept).
- Round-trip: forward → reverse → forward writes both fresh from the
  comment.

Conflict resolution: if the comment and the label disagree (e.g., a
hand-edit set the label but didn't update the comment), the **comment
wins** for body-driven transformations (template translation rules
read the comment). The label is corrected at next chat-side touch.

### 26.4 Cost analysis

- Label budget: each issue carries one `template:*` label. With 100
  labels per issue (audit §A.2) and v11's typical 6–10 labels per
  entry, this is comfortable. Repo-level label count grows by one
  per shipped template version per entry type (~5 entry types ×
  ~5 versions over a major's life ≈ 25 `template:*` labels at the
  repo level over time). Repo has no documented label cap; not a
  concern.
- Body bloat: three HTML-comment lines per entry (`<!-- pack-id:
  ... -->`, `<!-- template_version: ... -->`, `<!-- pack-version:
  ... -->`) is ~120 bytes. Negligible vs the 65,536-char (gzipped)
  body cap (audit §A.2).
- Query cost: `pack tracker update-templates` scans by label only
  (one API call returns the matching set). Per-issue body fetches
  happen *only* during the upgrade itself, by which point the user
  has approved the plan.

### 26.5 Application to all entry types

| Entry type | Comment | Label |
|---|---|---|
| BD entry | `<!-- template_version: v<X.Y.Z>/work-item -->` | `template:bd-v<X.Y.Z>` |
| TD entry | `<!-- template_version: v<X.Y.Z>/work-item -->` | `template:td-v<X.Y.Z>` |
| Phase epic | `<!-- template_version: v<X.Y.Z>/phase-epic -->` | `template:phase-epic-v<X.Y.Z>` |
| Inbound bug-report | `<!-- template_version: v<X.Y.Z>/inbound -->` | `template:inbound-v<X.Y.Z>` |
| Inbound feature-request | `<!-- template_version: v<X.Y.Z>/inbound -->` | `template:inbound-v<X.Y.Z>` |
| Inbound pack-feedback | `<!-- template_version: v<X.Y.Z>/inbound -->` | `template:inbound-v<X.Y.Z>` |

The comment carries the *form-file* version (`work-item`, `inbound`,
`phase-epic`); the label carries the *entry-type* version (`bd`,
`td`, `phase-epic`, `inbound`). The two are related but not
identical: the form file may have one version while serving multiple
entry types. The label specializes by entry type so the chat can
filter "show me all stale BDs" without filtering "show me all stale
TDs that share the same form."

### 26.6 What V2 rejects

V2 explicitly does not:

- Use only a body field (a). Body fields are visible and editable;
  the author can accidentally rewrite the version. The HTML comment
  hides this from view.
- Use only a label (c). Labels are immune to body edits but consume
  one of the 100-label-per-issue budget (small) and depend on
  label-name hygiene (medium). Worse: a contributor who manually
  removes the label at triage breaks queryability without changing
  the entry's actual template state.
- Use only a Projects v2 custom field (d). Project-v2 dependency
  is GH-specific; the field is invisible to non-Project consumers;
  cross-tracker portability is poor.

---

## Appendix A — V1 Appendix A (preserved + V2 deltas)

V1 Appendix A (skill / prompt / script changes summary) is preserved
verbatim. The V2 deltas:

### A.1 V2 deltas to V1 §A.1 (new artifacts)

V1 listed six issue templates (`bd-entry`, `td-entry`, `phase-epic`,
`pack-feedback`, `bug-report`, `feature-request`). V2 reduces this to
**two** templates: `work-item.yml` and `inbound.yml`. Plus the
existing `config.yml`.

V2 also adds:

- `maintenance-docs/v11-templates-archive/` — historical form
  versions for `pack tracker update-templates` (P2; §19.4).
- `maintenance-docs/v11-templates-archive/translations.yaml` — the
  translation manifest.
- `maintenance-docs/v11-conformance-runs/<backend>/<date>.xml` —
  conformance run artifacts (P3; §20.4).
- `scripts/tracker-providers/_lib/_conformance.sh` — conformance test
  harness.
- `scripts/tracker-providers/linear.{sh,toml}` — sample second backend
  (experimental; P3; §20.5).
- `scripts/tracker-providers/README.md` — contributor entry point
  (P3; §20.8).
- `project-template/docs/pack/HELP-FRAGMENT.md` — discoverability
  shared content (P6; §23.2).
- `scripts/pack-help.sh` — `pack help` verb (P6; §23.3).
- `.pack-tracker/chat-audit.jsonl` — chat-side audit trail (P4;
  §21.1).
- `.pack-tracker/upgrade-log.json` — template upgrade history (P2;
  §19.10).

### A.2 V2 deltas to V1 §A.2 (modified artifacts)

V1 listed all 10 prompts touched. Unchanged in V2.

V2 adds modifications:

- `PACK-CHAT.md` and `project-template/docs/pack/PM-CHAT.md`: add
  "Tracker verb routing" table (P6; §23.4).
- `project-template/docs/pack/METHODOLOGY.md` Part 7: add field-grammar
  documentation lines per textarea (per §25.11).
- `scripts/validate-pack.py` Check 19 (V1) is reaffirmed; V2 does not
  add a Check 20 yet — the planner may add one for `template:*` label
  hygiene.

### A.3 V2 deltas to V1 §A.3 (out-of-scope artifacts)

Unchanged.

### A.4 New artifacts for P3 contributor flow

The contributor README and the conformance harness are the new
contributor-facing artifacts. They live in `scripts/tracker-providers/`
because that's where `_lib/_conformance.sh` and the per-backend scripts
already live. Putting them adjacent keeps the contributor's
investigation path short.

---

## Appendix B — V1 Appendix B (preserved + V2 deltas)

V1 Appendix B (citation index) is preserved verbatim. V2 deltas:

- §18 (P1 lifecycle): `DESIGN-BRIEF.md` §3.4 P1; `EXTERNAL-RESEARCH.md`
  §1.1 (issue forms; auto-routing labels); audit §A.10 (lifecycle
  upside features — duplicate suggestion, audit log, reactions).
- §19 (P2 maintenance): `DESIGN-BRIEF.md` §3.1 (`template_version`
  field requirement); §3.4 P2; `EXTERNAL-RESEARCH.md` §1.1 (issue form
  evolution patterns); audit §A.6 (prior-art conventions for
  versioning entries); §A.7 (Linear MCP first-party server affects
  tier graduation).
- §20 (P3 backend extensibility): `EXTERNAL-RESEARCH.md` §8.4
  (Backstage plugin-API pattern); §8.6 (escape hatches in OSS
  abstractions); audit Part B (per-tracker capability matrix);
  §A.7 (Linear as the natural second backend).
- §21 (P4 auditability): `EXTERNAL-RESEARCH.md` §1.10 (Discussions
  parallel; not used here); audit §A.10 (issue events API; webhook
  surface).
- §22 (P5 cognitive load): `DESIGN-BRIEF.md` §3.4 P5; INTERNAL-INVENTORY
  Pass A and Pass B (existing v10 verb / concept set).
- §23 (P6 discoverability): `EXTERNAL-RESEARCH.md` §1.1 (issue form
  picker UX); audit §A.2 (template picker behavior).
- §24 (OQ-16 defense): `EXTERNAL-RESEARCH.md` §1.1, §6.1 (token
  costs); §9.1, §9.2 (Linear / Jira surfaces); audit §A.7 (Linear
  MCP); §B.1 (Jira free 3-level cap); §B.3 (Bugzilla); §B.9 (Trello).
- §25 (OQ-17 defense): `EXTERNAL-RESEARCH.md` §1.1 (issue form field
  types); §1.6 (search qualifiers); audit §A.2 (issue forms verified;
  no conditional visibility); §A.7 (Linear custom fields passthrough);
  §A.9 (capability flags as the right axis for backend differentiation).
- §26 (OQ-18 resolution): `EXTERNAL-RESEARCH.md` §1.4, §1.5 (labels +
  Projects v2); audit §A.2 (gzipped body cap; sanitizer behavior).

---

## Appendix C — V2 traceability index

This appendix is V2-only; it indexes every V2 design call back to a
priority or OQ.

| V2 element | Drives | Resolves |
|---|---|---|
| §4 form family | OQ-16 | D-4-V2 / D-16 |
| §6.2 addendum (template_version write) | OQ-18 | D-18 |
| §16 decisions table | OQ-1 .. OQ-18 + P1..P6 | all decisions |
| §17 R11–R14 | new V2 risks | covered in §17 |
| §18 lifecycle state machines | P1 | per-entry-type design |
| §19 update-templates verb + cadence | P2 | propagation mechanism |
| §20 backend contract + conformance | P3 | extensibility ergonomics |
| §21 audit-query surface | P4 | auditability |
| §22 verb table | P5 | cognitive load floor |
| §23 5-min onboarding + colloquial routing | P6 | discoverability |
| §24 multi-template defense | OQ-16 | D-4-V2, D-16 |
| §25 structure-vs-free-text defense | OQ-17 | D-17 |
| §26 template_version dual-carrier | OQ-18 | D-18 |

---

End of architecture proposal V2. The pack-reviewer audits next; the
pack-planner breaks the architecture (V1 + V2 deltas) into BD-NNN
entries for v11 implementation.

