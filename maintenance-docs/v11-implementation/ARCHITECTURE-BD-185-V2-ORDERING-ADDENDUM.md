# ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md — Capability+availability execution-ordering mechanism (v11.0)

**Status:** Targeted addendum to `ARCHITECTURE-BD-185-V2.md` (the authoritative,
user-approved BD-185 architecture). This doc SUPERSEDES exactly one subsystem of
V2 — the tracker-mode execution-ordering MECHANISM — and leaves everything else
in V2 intact and binding.

**HEAD at authoring:** `e580dda7eb46c640a92afabd3469bbada17d1975`
**Author:** pack-architect (read-only design pass; one output file)
**Inputs read:** `ARCHITECTURE-BD-185-V2.md` (§2, §5, §6, §7, §8.4–§8.5, D-7, D-8);
`RESEARCH-BD-185-ORDERING-API.md` (RG-1, RG-2, full); `scripts/lib/tracker-provider.sh`;
`scripts/lib/tracker-provider-gh.sh` (`tracker_provider_gh_capabilities`, `..._raw`);
`scripts/validate-pack.py` (ordering-surface grep — none present); `supporting-docs/METHODOLOGY.md`
(§ phase format, § phase numbering, § Multi-part phases); `project-template/{CLAUDE,AGENTS,GEMINI}.md`
(ordering-surface grep — none present); `.github/workflows/validate-pack.yml`; `CLAUDE.md` § Pack memory.
**NOT read (contaminated, per prompt):** `PLAN-BD-185.md`, `PLAN-BD-185-ADDENDUM.md`.

---

## §0 — Supersession notice (read first)

### §0.1 — What this addendum SUPERSEDES in V2

This addendum REPLACES the following V2 content. Where V2 and this addendum
disagree, THIS ADDENDUM WINS for the listed items; V2 remains authoritative for
everything else.

| V2 location | What it said | Disposition in this addendum |
|---|---|---|
| **§5.1** (GitHub primary path: Issue Fields) | Issue Fields `number` is the GitHub **primary/first-choice** ordering mechanism; fallback only on 25-cap exhaustion. | **SUPERSEDED.** Issue Fields is DEMOTED to a gated, OFF-by-default strategy (A-2 below). It is no longer first-choice. Fully designed, wire-able, but gated. |
| **§5.2** (fallback: sub-issue reprioritize) | Sub-issue reprioritize against an order-root is the **fallback** for trackers lacking Issue Fields (+ GH cap-exhaustion edge). | **SUPERSEDED in role.** The order-root + sub-issue reprioritize is PROMOTED to the **v11.0 GitHub DEFAULT** and the universal floor (A-1, A-3). The mechanism design (order-root, sibling = order) is KEPT; its selection role inverts. |
| **D-7** (ordering value lives on the phase entity) | Tracker mode = "a GH Issue Field (`number`)… Fallback: sub-issue reprioritize." | **PARTIALLY SUPERSEDED.** The CORE of D-7 — *the ordering VALUE is abstract, owned by the phase entity, mechanism-agnostic, never on STATUS.md / a flat-file mirror* — is KEPT and reinforced (A-1). Only the embedded mechanism-priority clause ("a GH Issue Field… fallback…") is replaced by capability+availability selection (A-3). |
| **D-8** (Issue Fields is the GitHub primary path) | Whole decision: Issue Fields is GitHub primary, flagged for primary-source verification. | **SUPERSEDED.** RG-1 closed the research gap and proved Issue Fields is **org-only + org-admin-gated** (RESEARCH §RG-1 §5, §9) — disqualifying it as a first-choice for solo/personal-repo/non-admin users. D-8 is replaced by A-2 (demoted+gated) + A-3 (selection). |
| **§7** — the two ordering ops `provider_set_field` / `provider_get_field`, and the `provider_capabilities` claim `execution_order.mechanism ∈ {issue_fields, sub_issue_reprioritize, none}` | Defined the ordering write/read as field ops; asserted capabilities "already returns" the mechanism. | **SUPERSEDED for the ordering ops.** Replaced by the abstract ordering ops `provider_order_read` / `provider_order_write` + a capability+availability `provider_order_capability` (§4). `provider_set_field`/`provider_get_field` are RETAINED but RE-SCOPED to the gated Issue-Fields backend internals only — they are NOT the consumer-facing ordering op. The `provider_capabilities` ordering block is redesigned (§4.3); note the live `tracker_provider_gh_capabilities` does NOT emit any `execution_order` block today (verified) — V2 §7 overstated current state. |
| **§6.1–§6.4** — ordering-write + ordering-sort behavior (only) | Migration writes "the Issue Field (or fallback)"; reverse-emit reads "the `Execution Order` value." | **SUPERSEDED for ordering reads/writes only.** Migration + reverse-emit now route through the abstract ops (§6 of this addendum). The Parts creation + task re-parenting in §6.1–§6.4 (the FIXED phase-parts MIGRATION steps) are **OUT OF SCOPE and UNCHANGED.** |

### §0.2 — What this addendum LEAVES INTACT (explicitly out of scope)

FIXED by V2 and NOT reconsidered here:

- The phase-parts design (V2 D-1..D-6, §4 entire).
- The FIXED phase-part on-tracker GRAMMAR (V2 §2, the marker trio, label family,
  4-state taxonomy, body-section grammar).
- The v11.0 version correction (V2 §0, D-1..D-5, §10, §11 CR-1/CR-2/CR-3).
- The work-item form-family (V2 D-9, §4.4).
- The phase-parts MIGRATION steps — Part sub-issue creation + task re-parenting
  (V2 §6.1 Phase B, §6.2 Parts clause, §6.4 H3/H4 emit).
- V2 §5.3 (flat-file HTML marker) and §5.4 (STATUS.md is a dashboard) — KEPT;
  this addendum reinforces them as instances of the abstract-op routing (§5).
- All V2 boundary rules 1–13 (V2 §1.5, §8).

### §0.3 — Relationship to V2's RG-1/RG-2 "verify at implementation" posture

V2 §7 flagged RG-1 (Issue Fields call shape) and RG-2 (reprioritize body params)
as EXTERNAL gaps for the coder to close. `RESEARCH-BD-185-ORDERING-API.md`
**closed both** (RG-1 RESOLVED, RG-2 RESOLVED), with two named residuals (RG-1
§8 GraphQL preview header PARTIAL; the 100-children cap documented outside the
REST reference). This addendum consumes the resolved facts directly, so the
coder's verification burden shrinks to the two named residuals (§7.4).

---

## §1 — The problem this addendum solves

V2's mechanism design hard-codes a priority order: **GitHub → Issue Fields
first; everything else is fallback.** RG-1 proves that priority is wrong on
availability grounds, and the hard-coding is wrong on design grounds.

**The availability defect (the driving fact).** Issue Fields `number` requires:
(a) the repo to belong to an **organization** (no personal-account issue fields —
RESEARCH §RG-1 §5: field definition is `POST /orgs/{org}/issue-fields`, an
org-scoped endpoint); (b) **org-admin** rights to DEFINE the field (RESEARCH
§RG-1 §5 exact quote: *"the authenticated user must be an administrator for the
organization"* / `admin:org`); (c) the feature is **public preview, "subject to
change"** (RESEARCH §RG-1 §9). A first-choice mechanism that excludes solo
developers, personal repos, and org non-admins is not broadly available — it
fails the "works for typical users" bar.

**The design defect (independent of availability).** Even when Issue Fields IS
available and superior, V2 bakes the GitHub→Issue-Fields choice into D-7, §5.1,
§7, and the migration prose. Flipping the default later (when Issue Fields goes
GA + broadly available) would touch many surfaces. The user's INTENT — *a
tracker with a superior native mechanism should be able to USE it; a tracker
without one uses a universal floor; no tracker is forced to a
least-common-denominator when it has something better AND available* — is sound,
but the realization must make mechanism SELECTION a localized policy decision,
not a hard-coded prose default.

**This addendum's correction (preserves intent, fixes both defects):**

1. The ordering VALUE stays abstract, owned by the phase entity (V2 D-7 core, KEPT).
2. Mechanism selection = **capability detection × pack-level availability/enablement gate** (§3).
3. v11.0 GitHub DEFAULT = the universal **sub-issue-reprioritize-against-order-root** floor — repo-write only, GA, personal-repo + org both (RESEARCH §RG-2).
4. Issue Fields = fully-designed, **gated OFF** strategy; enabling it later is a localized policy/config change, not new design (§3.4, §8).
5. EVERY consumer routes through abstract ordering ops; mechanism-specific call shapes live ONLY in the per-backend provider layer (§5).
6. Switch-locality across ALL encoding surfaces, proven by enumeration (§8).

---

## §2 — Decision log (self-contained; this addendum's own numbering A-N)

Numbering is local to this addendum (`A-1`, `A-2`, …) to avoid collision with
V2's `D-N`. Where an A-decision supersedes a V2 D-decision, the supersession is
stated inline and recorded in §0.1.

### A-1 — The ordering VALUE is abstract, phase-owned, and mechanism-agnostic (reaffirms + sharpens V2 D-7 core)

**Decision.** Every phase carries exactly one abstract ordering value, an
`order_key`. It is owned by the phase entity (the phase epic issue in tracker
mode; the `phase-N.md` per-entry file in flat-file mode). It is NOT owned by
STATUS.md, NOT by any `_order.md` view, NOT by a flat-file mirror in tracker
mode. The value's SEMANTICS are fixed and mechanism-independent:

- **Smaller sorts earlier.** Null/absent sorts LAST (uninitialized).
- **Sparse-friendly.** The abstract contract permits gaps so an insert between
  two phases does not renumber siblings (e.g., insert "2.5" between 2 and 3).
  Whether a given backend realizes sparseness as a stored numeric (Issue Fields)
  or as relative sibling position (reprioritize) is a BACKEND concern (§5.2),
  invisible to consumers.
- **Decoupled from phase number + task ID.** Reordering NEVER mutates phase
  numbers or task IDs (V2 SC3). `order_key` is a separate axis.

**Rationale.** This is V2 D-7's load-bearing core, restated as the invariant the
whole selection design hangs on: because consumers read/write an abstract
`order_key` (never a mechanism artifact), swapping the realizing mechanism is
invisible to them (§5). KEPT from V2; this addendum only removes D-7's embedded
"Issue Field… fallback…" mechanism-priority clause (→ A-3).

### A-2 — Issue Fields is DEMOTED and GATED (supersedes V2 §5.1, D-8; revises user-locked C-2)

**Decision.** The GitHub Issue Fields `number` ordering strategy stays FULLY
DESIGNED and wire-able, but is **gated OFF by default in v11.0.** It is no longer
the GitHub first-choice. It activates ONLY when the availability gate (A-4)
passes AND a pack-level enablement flag is set.

**Why (the driving fact).** RESEARCH §RG-1 §5 + §9 prove Issue Fields is
org-only, org-admin-gated to provision, and public-preview "subject to change."
A first-choice mechanism must be available to typical users (solo / personal-repo
/ org-non-admin); Issue Fields is not. This revises the original user-locked C-2
("Issue Fields is the v11.0 first-choice") per the explicit USER DECISION
recorded in this addendum's driving inputs: Issue Fields is KEPT in the design
but DEMOTED + GATED.

**Why keep it at all (not delete).** Issue Fields is genuinely SUPERIOR where
available: a stored sparse numeric needs no order-root issue, survives
sub-issue-graph edits, and is a native sort key. The user's intent — "a tracker
with a superior native mechanism should be able to USE it" — requires the
strategy to remain present and wire-able so enabling it later is policy/config,
not new design (§3.4, §8).

### A-3 — Mechanism SELECTION is capability × availability, NOT hard-coded priority (supersedes V2 §5.1/§5.2 selection roles, D-7 mechanism clause)

**Decision.** A backend's ordering mechanism is resolved by a two-factor
function, NOT by a hard-coded "Issue-Fields-first" prose rule:

```
selected_mechanism(backend) =
    the highest-ranked mechanism M in backend.ordering_mechanisms
    such that  capability_present(M)  AND  availability_gate_open(M)
    ; else  → universal_floor(backend)
```

- **`capability_present(M)`** — does the backend EXPOSE mechanism M at all? (GitHub
  exposes both `issue_fields` and `sub_issue_reprioritize`; a hypothetical
  minimal tracker may expose neither.)
- **`availability_gate_open(M)`** — is M both ENABLED by pack policy AND USABLE in
  the concrete environment (org present, admin rights, field provisioned, preview
  cleared — A-4)? This is the single policy decision point.
- **`universal_floor(backend)`** — the mechanism that needs only the baseline
  capability every supported tracker has. For GitHub: sub-issue-reprioritize
  against an order-root (repo-write only; RESEARCH §RG-2 §2 permission =
  "Issues" repo write).

**v11.0 GitHub resolution (concrete).** `ordering_mechanisms = [issue_fields,
sub_issue_reprioritize]` (preference order: superior-first). In v11.0 the
`issue_fields` gate is **shipped OFF** (A-4 `policy_enabled = false`).
Therefore selection skips `issue_fields` and resolves to
`sub_issue_reprioritize` (the universal floor). No first-choice mechanism is
unavailable to typical users, because the resolved default needs only repo-write.

**Graceful degradation preserved.** A backend with a superior+available mechanism
gets it; a backend without one inherits the universal floor — through the SAME
selection function. No tracker is forced to a least-common-denominator when it
has something better AND available; and no tracker is forced to a mechanism it
cannot use.

### A-4 — The Issue-Fields availability gate is a precise four-condition predicate (defines D-8's replacement gate)

**Decision.** `availability_gate_open(issue_fields)` is the conjunction of FOUR
conditions, evaluated by one resolver (§4.4). The gate opens ONLY when all four hold:

| # | Condition | How detected | RESEARCH anchor |
|---|---|---|---|
| G1 | **Policy enabled** | `tracker.toml [execution_order] issue_fields_enabled = true`. SHIPPED `false` in v11.0. This is THE switch (§3.4). | design |
| G2 | **Org present** | The repo's owner is an organization (not a user account). `provider_get` / repo metadata `owner.type == "Organization"`. | RG-1 §5 (field def is org-scoped) |
| G3 | **Admin rights to provision** | The token can create/read the org field. Preflight: `GET /orgs/{org}/issue-fields` succeeds AND (the `Execution Order` field already exists OR `admin:org` provisioning succeeds). GraphQL preflight analog: `Issue.viewerCanSetFields` (RG-1 §6) for write-check. | RG-1 §5 (`admin:org` to define), §6 (`viewerCanSetFields`) |
| G4 | **Preview cleared / feature reachable** | The Issue-Fields API is reachable for this account. Empirically: a probe read of `/repos/{owner}/{repo}/issues/{n}/issue-field-values` does not 404/403-on-feature. Tracks the "public preview, subject to change" caveat (RG-1 §9) and the unconfirmed GraphQL preview header (RG-1 §8 — PARTIAL). | RG-1 §8, §9 |

**G1 is the v11.0 ship state and the single switch.** G2–G4 are environment
probes that matter only once G1 is flipped on. In v11.0, G1 = false, so the gate
is closed regardless of G2–G4 — the resolver short-circuits on G1 (cheap; no
network probe needed while the feature is off).

**On the later GA switch.** When Issue Fields goes GA + broadly available, the
switch is: flip G1 to `true` (the policy/config decision) — see §3.4 for the exact
change-points. G2–G4 then gate PER-ENVIRONMENT at runtime, so the switch is safe:
an org-admin user gets Issue Fields; a solo/personal-repo/non-admin user STILL
falls through to the universal floor automatically. The switch never strands the
typical user.

### A-5 — Consumers read/write ONLY the abstract ordering ops (supersedes V2 §7 ordering-op surface)

**Decision.** Three abstract provider ops form the ENTIRE consumer-facing ordering
surface (§4.1). No consumer (mirror sort, STATUS.md, reverse-emit, migration,
reorder verbs, validators) contains a mechanism-specific call. Mechanism-specific
call shapes (`reprioritizeSubIssue` / `PATCH .../sub_issues/priority`;
`setIssueFieldValue` / `PUT .../issue-field-values`) live ONLY inside
`tracker-provider-gh.sh`. (§5 enumerates the seven consumers and shows each routes
through the abstract ops.)

### A-6 — The order-root universal floor is the v11.0 GitHub default; its 100-child cap is handled by root-chaining (addresses RESEARCH §RG-2 §5 cap)

**Decision.** The universal floor creates a singleton **order-root** issue at
`pack tracker init`; phase epics are linked as its sub-issues; phase execution
order = sibling order under the order-root (RESEARCH §RG-2 §4: reprioritize is
sibling-only/parent-scoped — putting all phase epics under one root makes
"siblings under the root" == "global phase order"). The 100-children-per-parent
cap (RESEARCH §RG-2 §5; documented in GitHub's sub-issues feature discussion, NOT
the REST reference) is handled by **order-root chaining** (§5.4): when phase count
exceeds the cap, additional order-root segments are chained. This is a designed
behavior, not an unhandled limit. (See §5.4 for the chaining contract; this is a
boundary the prompt requires be addressed, not left open.)

### A-7 — Migration ordering-writes respect the content-generating secondary rate cap (addresses RESEARCH §RG-1 §9 / §RG-2 §5)

**Decision.** Both ordering mechanisms are content-generating for secondary
rate-limit purposes (RESEARCH §RG-1 §9: PUT issue-field-values warning; §RG-2 §5:
reprioritize PATCH is content-generating-class). Bulk ordering-write during
migration (writing initial order to every phase epic) MUST throttle to the
binding secondary cap: **≤ 80 content-generating requests/minute and ≤ 500/hour**
(TIGHTER than the 5,000/hr primary). The migrator throttles at the abstract-op
layer (`provider_order_write` batch path, §6.2), so the cap is honored regardless
of which mechanism is selected.

### A-8 — When Issue Fields IS enabled+selected, PREFER its REST path (addresses RESEARCH §RG-1 §8 PARTIAL)

**Decision.** The gated Issue-Fields backend sub-section uses the REST endpoints
(`PUT`/`GET .../issue-field-values`, RESEARCH §RG-1 §3) as the PRIMARY call path,
NOT the GraphQL `setIssueFieldValue` path. Rationale: the GraphQL preview header
`GraphQL-Features: issue_fields` is UNCONFIRMED (RESEARCH §RG-1 §8 — PARTIAL: the
header could not be located verbatim in primary HTML; mutations appear in the
production schema with no preview flag). The REST path's permission + body shape
are fully confirmed (RG-1 §3). The coder verifies the header empirically only if
a GraphQL path is later wanted; the REST-first default avoids the residual.

---

## §3 — Capability + availability selection (the mechanism, in full)

### §3.1 — The three layers

```
  ┌─────────────────────────────────────────────────────────────┐
  │  LAYER 1 — abstract ordering value (A-1)                      │
  │  order_key  (phase-owned; smaller=earlier; null=last; sparse) │
  └───────────────────────────┬─────────────────────────────────┘
                              │ consumers touch ONLY this layer
  ┌───────────────────────────┴─────────────────────────────────┐
  │  LAYER 2 — abstract ordering ops (A-5, §4.1)                  │
  │  provider_order_read / provider_order_write /                 │
  │  provider_order_capability                                    │
  └───────────────────────────┬─────────────────────────────────┘
                              │ dispatch → selected mechanism
  ┌───────────────────────────┴─────────────────────────────────┐
  │  LAYER 3 — per-backend mechanism realizations (§5)           │
  │  github:  [issue_fields (GATED OFF)] , sub_issue_reprioritize │
  │           (FLOOR, v11.0 default)                              │
  │  <future linear/jira/gitlab/redmine: own mechanisms / floor>  │
  │  mechanism-specific call shapes live ONLY here                │
  └───────────────────────────────────────────────────────────────┘
```

The selection function (A-3) lives at the LAYER-2/LAYER-3 seam. Consumers never
see it. Mechanism-specific calls never escape LAYER 3.

### §3.2 — Selection resolution, step by step (GitHub, v11.0)

1. Consumer calls an abstract op, e.g. `provider_order_write <phase-epic-id> <order_key>`.
2. The op asks the backend to resolve its mechanism: `_order_resolve_mechanism()`
   (LAYER-3, GH backend) evaluates A-3:
   - Candidate list (preference order): `[issue_fields, sub_issue_reprioritize]`.
   - `issue_fields`: `capability_present` = true (GH exposes it), but
     `availability_gate_open` evaluates A-4 → G1 (`issue_fields_enabled`) is
     **false** in v11.0 → short-circuit → gate CLOSED → skip.
   - `sub_issue_reprioritize`: `capability_present` = true; it is the universal
     floor (no gate beyond repo-write, which `pack tracker init` already required)
     → SELECTED.
3. The GH backend executes the floor's call shape (order-root reprioritize,
   RESEARCH §RG-2 §2) — invisible to the consumer.

### §3.3 — Selection resolution under a flipped gate (the GA future)

Identical to §3.2 except step 2's `issue_fields` branch: when G1 is flipped to
`true`, the resolver evaluates G2–G4 against the live environment:
- Org-admin on an org repo with the field provisioned and preview cleared → gate
  OPEN → `issue_fields` SELECTED (superior mechanism used).
- Solo / personal repo / org-non-admin → G2 or G3 fails → gate CLOSED → falls
  through to `sub_issue_reprioritize` (floor) → typical user unaffected.

The SAME resolver, the SAME candidate list, the SAME consumers. Only G1's value
and (at runtime) the environment differ. This is the localized switch (§3.4).

### §3.4 — The switch is ONE policy decision point (switch-locality, the core deliverable)

**To flip GitHub's default from the universal floor to Issue Fields when it goes
GA + broadly available, exactly TWO places change. No consumer changes. No prose
changes.**

| # | Change-point | What changes | Why it is the only place |
|---|---|---|---|
| **K1** | **The policy gate G1** — `tracker.toml [execution_order] issue_fields_enabled` default (set in `scripts/lib/tracker-init.sh` where the section is scaffolded, and the resolver's hard default in `tracker-provider-gh.sh` `_order_resolve_mechanism`). | Flip the shipped default from `false` to `true`. (A single boolean.) | This is the policy decision. The resolver (A-3) reads it; everything downstream is mechanical. G2–G4 then gate per-environment automatically (§3.3), so the flip is safe for non-admin users. |
| **K2** | **The GH Issue-Fields backend sub-section** — the body of `tracker_provider_gh__order_*_issue_fields()` internal helpers in `tracker-provider-gh.sh` (§5.3). | This code already EXISTS (designed + wired, gated off, A-2). The flip needs at most: clear any "gated/not-wired" guard stub and confirm the REST call shape (A-8). If shipped fully-wired-behind-gate (recommended, §5.3), K2 is a NO-OP and only K1 changes. | The mechanism-specific call shapes (`PUT .../issue-field-values`) live ONLY here (A-5). No other surface contains them. |

**Idealized end-state: K2 is a no-op.** If v11.0 ships the Issue-Fields backend
helpers fully wired but gated (A-2 — "wire-able-but-gated"), then enabling Issue
Fields later is the SINGLE change K1 (flip one boolean). The prompt's DESIGN GOAL
("ideally one policy/gate decision point — with zero change to consumers or
prose") is met: K1 alone, with K2 reduced to a no-op by shipping the gated code.

**Zero consumer / prose change is provable** because: (a) consumers touch only
LAYER 1/2 (A-1, A-5; enumerated §5); (b) all prose/rules/docs describe ordering
abstractly (enumerated §8); (c) the mechanism-specific calls are confined to
LAYER 3 (§5.3). The §8 enumeration is the proof.

### §3.5 — Why capability AND availability (not capability alone)

Capability detection alone (V2 §7's `provider_capabilities`-style "does the
backend support issue fields?") is insufficient: GitHub *supports* Issue Fields
org-wide, but a given *repo/account* may be a personal repo or a non-admin org
member where the feature is unusable. Availability (A-4 G2–G4) is a
PER-ENVIRONMENT runtime fact, distinct from the backend-wide capability. The
selection function multiplies both (A-3) so the resolved mechanism is always one
the concrete environment can actually execute. This is the precise defect in
treating Issue Fields as a static "GitHub primary."

---

## §4 — Abstract ordering ops + provider surface (supersedes V2 §7 ordering ops)

### §4.1 — The three abstract ops (the consumer-facing surface)

These REPLACE V2 §7's `provider_set_field` / `provider_get_field` as the
consumer-facing ordering surface. They are added to the `provider_*` public API
in `scripts/lib/tracker-provider.sh` and dispatched per backend exactly like the
existing 18 ops.

| Abstract op | Signature | Purpose | Read/Write |
|---|---|---|---|
| `provider_order_read` | `provider_order_read <phase-epic-id>` → emits the phase's abstract `order_key` (JSON number or null) | Read one phase's ordering value (mirror sort, STATUS.md, reverse-emit) | Read |
| `provider_order_write` | `provider_order_write <phase-epic-id> <order_key>` (batch form: `provider_order_write --batch <json-array>`) | Write/update one phase's ordering value (reorder verb, migration); batch form throttles per A-7 | Write |
| `provider_order_capability` | `provider_order_capability` → emits `{ "mechanism": <resolved>, "available": <bool>, "candidates": [...], "floor": <name>, "cap_per_root": <int|null> }` | Report the RESOLVED mechanism + availability for the active backend/environment (doctor, init, validators) | Read |

**Design notes.**
- `provider_order_read` returns the ABSTRACT key, not a mechanism artifact: the
  floor backend computes it from sibling position; the gated Issue-Fields backend
  reads the stored numeric. Consumers cannot tell which.
- `provider_order_write` accepts an abstract key for the stored-numeric mechanism;
  for the relative-position floor it translates the key into an
  `after`/`before` reprioritize against the resolved sibling (§5.2). The
  translation is internal to LAYER 3.
- `provider_order_capability` is what doctor/init/validators consult instead of
  parsing a mechanism name out of `provider_capabilities` — it returns the
  RESOLVED selection (A-3), already accounting for the gate.

### §4.2 — Disposition of V2's `provider_set_field` / `provider_get_field`

RETAINED but RE-SCOPED. They are NOT deleted (they are the natural primitive for
writing ANY issue field, not just ordering — a future non-ordering use may want
them). They become **internal primitives of the gated Issue-Fields backend
sub-section** (§5.3), called only by `tracker_provider_gh__order_*_issue_fields()`.
They are NO LONGER part of the consumer-facing ordering surface; no consumer
calls them directly. This keeps mechanism-specific field calls inside LAYER 3
(A-5) while preserving the primitive.

> Note: this corrects V2 §7's framing that `provider_set_field`/`provider_get_field`
> ARE the ordering ops. Under this addendum they are field-write primitives behind
> the gated backend; the ordering ops are the three in §4.1.

### §4.3 — `provider_capabilities` ordering block (redesign of V2 §7's claim)

V2 §7 asserted `provider_capabilities` "returns `execution_order.mechanism ∈
{issue_fields, sub_issue_reprioritize, none}`." VERIFIED: the live
`tracker_provider_gh_capabilities` (`tracker-provider-gh.sh:728`) emits NO
`execution_order` block today — V2 overstated current state. This addendum
specifies the block as a STATIC capability descriptor (what the backend CAN do),
distinct from the RUNTIME-resolved `provider_order_capability` (what it WILL do
here):

```json
"execution_order": {
  "mechanisms": ["issue_fields", "sub_issue_reprioritize"],
  "floor": "sub_issue_reprioritize",
  "issue_fields": { "scope": "org", "requires_admin_to_provision": true, "status": "preview" },
  "sub_issue_reprioritize": { "scope": "repo", "sibling_only": true, "children_per_root_cap": 100 }
}
```

- `mechanisms` is the STATIC candidate list (preference order). It does NOT encode
  the gate or the environment — those live in the resolver (A-3) and surface via
  `provider_order_capability` (§4.1). This keeps `provider_capabilities` a pure
  capability descriptor; the gate is policy, not capability.
- A future backend lists its own `mechanisms` + `floor` here; the resolver and
  the three abstract ops are unchanged (rule 10 / §9).

### §4.4 — Where the resolver lives

`_order_resolve_mechanism()` is a LAYER-3, per-backend internal in
`tracker-provider-gh.sh`. It reads G1 from `tracker.toml [execution_order]` (via
`tracker-config.sh`) and, only if G1 is on, probes G2–G4. It is the single
function that evaluates A-3 × A-4 for GitHub. A future backend supplies its own
`_order_resolve_mechanism` analog (or inherits a default that always returns the
floor). The abstract ops in `tracker-provider.sh` call it through the dispatcher;
they contain no selection logic themselves.

---

## §5 — Consumer routing (proves A-5: every consumer through the abstract op)

Seven consumers touch ordering. Each is shown routing through the §4.1 abstract
ops, with NO mechanism-specific call. Mechanism-specific calls appear ONLY in §5.2
(floor) and §5.3 (gated Issue Fields) — both inside `tracker-provider-gh.sh`.

### §5.1 — The seven consumers (enumerated; each routes through LAYER 2)

| # | Consumer | V2 location | Reads/writes order via | Mechanism-specific call? |
|---|---|---|---|---|
| C1 | **Mirror sort** (per-entry → `IMPLEMENTATION-PLAN.md`; tracker reverse `_tmr_emit_implementation_plan`) | V2 §5.3, §6.4 | `provider_order_read` per phase, then sort by `(order_key, phase_number, filename)` | NO |
| C2 | **STATUS.md display** (`_tmr_emit_status` / status regen) | V2 §5.4 | `provider_order_read` per phase; displays sorted; never writes | NO |
| C3 | **Reverse-emit** (tracker → flat `phase-N.md`) | V2 §6.4 | `provider_order_read`; writes the abstract value into the flat `<!-- execution-order: N -->` marker | NO |
| C4 | **Migration ordering-writes** (v10→v11 Phase B; v11.0 flat→tracker forward) | V2 §6.1, §6.2 | `provider_order_write --batch` (throttled, A-7) | NO |
| C5 | **Reorder verbs** (`pack [tracker] phase reorder`) | V2 §5.5 | `provider_order_write <phase> <key>` | NO |
| C6 | **Validators** (`pack tracker doctor`; any validate-pack ordering check) | V2 §5.1 ("doctor verifies") | `provider_order_capability` (resolved mechanism + availability) | NO |
| C7 | **Flat-file ordering** (per-phase HTML marker; flat-file reorder/sort) | V2 §5.3 | Reads/writes the `<!-- execution-order: N -->` marker directly (flat-file has no provider) — the marker IS the abstract `order_key` in flat-file mode | N/A (no tracker mechanism) |

**C7 note.** Flat-file mode has no TrackerProvider. The HTML marker is itself the
abstract `order_key` realization for that mode (A-1). Cross-mode consistency: the
SAME abstract semantics (smaller=earlier, sparse, null-last) govern both the flat
marker and the tracker `order_key`, so reverse-emit (C3) maps one to the other
losslessly. This preserves V2 §5.3 unchanged.

### §5.2 — GH LAYER-3 mechanism: sub-issue-reprioritize floor (v11.0 default)

Mechanism-specific calls (confined here). The order-root + reprioritize realizes
the abstract `order_key`:

- **Init.** `pack tracker init` creates the singleton order-root issue; links all
  phase epics as sub-issues (RESEARCH §RG-2 §2 add-sub-issue `POST
  .../sub_issues`, body `sub_issue_id`).
- **`provider_order_write <phase> <key>` realization.** Translate the abstract key
  into a sibling position: compute the target sibling whose key is the
  largest-key-less-than (`after`) or smallest-key-greater-than (`before`), then
  call reprioritize. RESEARCH §RG-2 §2 EXACT REST shape:
  `PATCH /repos/{owner}/{repo}/issues/{ROOT_NUMBER}/sub_issues/priority` with body
  `{ "sub_issue_id": <phase-epic ID>, "after_id": <sibling ID> }` (or `before_id`)
  — **issue `id` values, NOT `number` values** (RESEARCH §RG-2 §2 critical
  distinction). GraphQL analog: `reprioritizeSubIssue(input: { issueId: <root>,
  subIssueId: <phase>, afterId|beforeId: <sibling> })` (RESEARCH §RG-2 §3).
- **`provider_order_read <phase>` realization.** Read sibling order from the
  existing `provider_sub_issue_list <root>` (RESEARCH §RG-2: list returns sibling
  order); the phase's index in that ordered list IS its abstract key.
- **Append-on-create.** A mid-dev new phase appends to the END of the root's
  sibling list (GH default sub-issue append; matches V2 §11 CR-13).

### §5.3 — GH LAYER-3 mechanism: Issue Fields (DESIGNED, GATED OFF — wire-able)

Mechanism-specific calls (confined here; reached only when A-4 gate opens). Ships
in v11.0 fully designed and SHOULD ship fully wired behind the gate so the GA
switch is K1-only (§3.4):

- **Field provisioning (init, gated).** When G1 on + G2/G3 hold: detect-or-create
  the org `number` field `Execution Order` (collision fallback `Pack Execution
  Order`). RESEARCH §RG-1 §5: `POST /orgs/{org}/issue-fields` body `{ "name":
  "Execution Order", "data_type": "number" }`, requires `admin:org`. Record the
  resolved field id/name in `tracker.toml [execution_order]`.
- **`provider_order_write` realization (PREFERRED REST per A-8).** RESEARCH §RG-1
  §3: `PUT /repos/{owner}/{repo}/issues/{n}/issue-field-values` body
  `{ "issue_field_values": [ { "field_id": <id>, "value": <order_key> } ] }`
  (value is a JSON number). Internally uses the retained `provider_set_field`
  primitive (§4.2). Decimals supported (RESEARCH §RG-1 §2) → sparse keys (e.g.
  2.5) store natively.
- **`provider_order_read` realization.** RESEARCH §RG-1 §3/§6:
  `GET .../issue-field-values`, extract the `Execution Order` value (GraphQL read
  path `Issue.issueFieldValues → IssueFieldNumberValue.value` per RG-1 §6).
- **Cardinality.** Single value per (issue, field) (RESEARCH §RG-1 §7) — exactly
  one `order_key` per phase. Clear via DELETE or PUT-omit (RG-1 §3).
- **Gate guard (v11.0 ship state).** Because G1 ships `false`, these helpers are
  never reached at runtime in v11.0. They ship as dormant, correct code (A-2). The
  ONLY thing standing between them and activation is K1 (§3.4).

### §5.4 — Order-root 100-child cap handling (root-chaining; addresses A-6 / RESEARCH §RG-2 §5)

The floor's order-root is a sub-issue parent, capped at 100 children (RESEARCH
§RG-2 §5). For projects with > ~100 phases:

- **Root-chaining.** Order-roots form an ordered chain: `order-root-1`,
  `order-root-2`, … Each holds ≤ 100 phase epics. Global order = (root-segment
  index, sibling index within segment). `provider_order_read`/`_write` treat the
  chain as one logical sequence; the segment boundary is internal to LAYER 3.
- **`provider_order_capability` surfaces the cap** (`cap_per_root: 100`) so doctor
  (C6) can warn near the boundary.
- **Why chaining over alternatives.** A flat documented limit ("max 100 phases")
  would silently break a 101-phase OT-style project (the v11 goal explicitly
  targets a 60-phase OT migration, V2 §6.3 worked example — headroom matters). A
  single deep nesting violates the 8-level depth ceiling for large counts.
  Chaining keeps depth at 2 (root → phase epic) and scales linearly. The chain
  segment count = `ceil(phase_count / 100)`.
- **Gated Issue-Fields path is cap-free** for this dimension (a stored numeric has
  no per-parent child cap), which is one more reason the strategy is worth keeping
  wire-able (A-2) for very large org projects once GA.

---

## §6 — Migration ordering behavior (supersedes V2 §6.1–§6.4 ordering reads/writes only)

The Parts creation + task re-parenting in V2 §6.1–§6.4 are UNCHANGED (out of
scope, §0.2). Only the ordering-write and ordering-sort behavior is restated to
route through the abstract ops.

### §6.1 — v10→v11 migrator (BD-119 framework) — ordering writes

- **Phase A (local files)** — UNCHANGED from V2 §6.1: the decompose step writes
  `<!-- execution-order: N -->` into each `phase-N.md`, value = 1-indexed position
  in `IMPLEMENTATION-PLAN.md` (current implementation order, V2 P4). This is the
  flat-file `order_key` realization (C7); no provider, no mechanism.
- **Phase B (tracker opt-in)** — ordering write now routes through
  `provider_order_write --batch` (C4). The migrator does NOT call a mechanism
  directly. The resolver (A-3) selects the floor (v11.0, G1 off) → the batch write
  becomes order-root linking + sibling ordering (§5.2). Throttle per A-7 (≤80/min,
  ≤500/hr).

### §6.2 — v11.0 flat→tracker forward-migration — ordering writes

For each phase, read its flat `execution-order` marker (C7), then
`provider_order_write` it to the phase epic (C4). One abstract call per phase
(batched + throttled, A-7). The selected mechanism is resolved once at batch start
(A-3); the migrator is mechanism-blind.

### §6.3 — Execution-note handling — UNCHANGED

V2 §6.3 (structured warning, no auto-ordering, default = phase number) is
UNCHANGED. It operates on the abstract `order_key` (default = phase number), which
is mechanism-independent. The OT-style 60-phase worked example (V2 §6.3) holds
verbatim: phases 1..60 get `order_key = phase_number`; the floor links them as 60
ordered siblings under the order-root (one root segment, under the 100 cap, §5.4).

### §6.4 — Reverse migration (tracker → flat) — ordering reads

`_tmr_emit_implementation_plan` (C1) and `_tmr_emit_status` (C2) sort phases by
`provider_order_read` (the abstract key), NOT by a mechanism-specific field read.
The H3/H4 Part emit in V2 §6.4 is UNCHANGED (out of scope). Each emitted
`phase-N.md` carries `<!-- execution-order: N -->` = the read abstract key (C3).

---

## §7 — Tracker portability (rule 10 / BD-060)

### §7.1 — How a future backend plugs in (superior mechanism OR floor, SAME selection)

A future backend (Linear / Jira / GitLab / Redmine) plugs into the SAME selection
function (A-3) by supplying, in its `tracker-provider-<name>.sh`:

1. An `execution_order` capability block (§4.3) listing its `mechanisms` +
   `floor`. E.g., Linear lists `["properties", <its-sibling-floor>]`; Jira/GitLab/
   Redmine list `["custom_fields", <floor>]`.
2. An `_order_resolve_mechanism` analog (§4.4) — or it inherits a default that
   always returns the floor (a backend with no superior mechanism needs zero
   selection code).
3. Realizations of `provider_order_read`/`_write` for each mechanism it lists,
   with mechanism-specific call shapes confined to its own backend file.

The three abstract ops (§4.1), the consumers (§5.1), and all prose/docs/validators
(§8) are UNCHANGED when a backend is added — that is the portability guarantee.

### §7.2 — Superior-mechanism inheritance is automatic

Because selection is `capability × availability` (A-3), a future Linear backend
that exposes Properties (a superior native ordering field) and has them available
gets them through the identical resolver — no special-casing, no consumer change.
A backend without any superior mechanism inherits the universal floor through the
same function. This is the user's intent (no least-common-denominator when
something better+available exists) realized portably.

### §7.3 — v11.0 scope line (rule 12 — NOT the phase-parts error)

Per V2 §11 CR-10: non-GitHub backends are **Reserved** by the BD-185 entry's
Out-of-scope ("tracker backends other than github — reserved"). The abstract ops
+ selection + floor are DESIGNED in v11.0; concrete non-GitHub backing is Reserved
by the BD entry (a legitimate, user-sanctioned backend-coverage line — distinct
from the phase-parts version error rule 12 forbids). A v11.0 GitHub-only
dispatcher is correct; the abstract surface guarantees future backends slot in
without redesign.

### §7.4 — Residual external dependencies for the coder (shrunk from V2 §7)

RESEARCH closed RG-1 + RG-2. Two named residuals remain, both confined to the
GATED Issue-Fields path (so neither blocks the v11.0 floor default):

1. **RG-1 §8 — GraphQL preview header `GraphQL-Features: issue_fields` (PARTIAL).**
   Mitigated by A-8 (REST-first); the coder verifies the header empirically ONLY
   if a GraphQL Issue-Fields path is later wanted.
2. **RESEARCH §RG-2 §5 / §RG-1 §7 — the 100-children cap is documented outside the
   REST reference.** Mitigated by A-6/§5.4 (root-chaining); the coder confirms the
   live cap value before relying on the chaining threshold.

Both are Issue-Fields/edge concerns; the v11.0 floor default (the broadly-available
mechanism) depends on neither.

---

## §8 — ENCODING-surface enumeration (proves switch-locality across ALL surfaces)

Per the pack-memory "enumerate ENCODING surfaces" discipline, this enumerates
EVERY surface that encodes or describes the ordering mechanism, and shows each is
mechanism-AGNOSTIC — so the GA switch (K1, §3.4) touches ONLY the policy gate + the
backend sub-section, nothing here. Nine surfaces; verified against the working
tree at HEAD.

| # | Encoding surface | Current state (verified) | Mechanism-agnostic? | Touched by the GA switch? |
|---|---|---|---|---|
| S1 | **Pack memory** (`CLAUDE.md` § Pack memory; trinity `AGENTS.md`/`GEMINI.md`) | No ordering-mechanism rule exists (grep: only an unrelated "reorders future BD work" phrase). | YES (nothing to describe) | NO |
| S2 | **`project-template/` trinity** (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`) | Zero ordering-mechanism references (grep confirmed: no `execution-order`/`Issue Field`/`reprioritize`). | YES | NO |
| S3 | **`supporting-docs/METHODOLOGY.md`** | Describes ordering ABSTRACTLY: "`> **Execution note**:` … ordering constraint" (L375); "To reorder execution, use execution notes … not renumbering" (L410). Names NO mechanism. | YES (abstract by construction) | NO |
| S4 | **Reorder verb help/prose** (`pack [tracker] phase reorder`, V2 §5.5) | Describes reordering the abstract value; routes through `provider_order_write` (C5). | YES | NO |
| S5 | **`scripts/validate-pack.py`** | Zero ordering/issue-field/reprioritize references today (grep confirmed). Any future ordering check (C6) consults `provider_order_capability` — the RESOLVED mechanism — never a literal mechanism name. | YES | NO |
| S6 | **CI workflow** (`.github/workflows/validate-pack.yml`) | Zero ordering references (grep confirmed). Wires validate-pack + tests generically. | YES | NO |
| S7 | **`provider_capabilities` ordering block** (`tracker-provider-gh.sh`, §4.3) | Today emits NO `execution_order` block. The designed block lists STATIC `mechanisms` (capability), not the gate/selection. | YES (capability descriptor; gate lives in resolver) | NO — it lists candidates; the SELECTION (K1) is the gate, not this list |
| S8 | **`tracker.toml [execution_order]` section** (scaffolded by `tracker-init.sh`) | Holds `issue_fields_enabled` (G1) + resolved field name. | This IS the policy surface | **YES — K1.** This is the intended switch point (§3.4). |
| S9 | **GH backend ordering helpers** (`tracker-provider-gh.sh` LAYER 3, §5.2/§5.3) | Floor helpers (default) + gated Issue-Fields helpers (dormant). The ONLY surface holding mechanism-specific call shapes. | This IS LAYER 3 | **YES — K2** (no-op if shipped fully-wired-behind-gate). |

**Switch-locality verdict.** Of nine encoding surfaces, SEVEN (S1–S7) are
mechanism-agnostic and untouched by the GA switch. Only S8 (the policy gate = K1)
and S9 (the backend sub-section = K2, reducible to a no-op) change. This is the
proof that the prompt's switch-locality requirement is met: the GH→Issue-Fields
switch touches ONLY the policy/gate + the backend sub-section.

**Asymmetric-coverage guard (the memory rule's intent).** The enumeration walks
ALL encoding classes — rules (S1/S2), docs (S3/S4), validators (S5), CI (S6),
capability descriptor (S7), config (S8), and the code that holds the calls (S9) —
not a subset. A future ordering validator added to S5 MUST consult
`provider_order_capability` (C6), never a literal mechanism string; if it
hard-coded `"issue_fields"` it would become a NEW encoding surface that the switch
must touch — a LEAK (operational) the reviewer must reject. This is called out so
the planner/coder do not silently reintroduce a mechanism literal into S5.

### §8.1 — Boundary placement (V2 §8.4 reaffirmed; deliverable-only)

The abstract ops, the resolver, the order-root helpers, and the gated
Issue-Fields helpers are pack-side scripts that CONSTRUCT/MANAGE the project-side
tracker deliverable. Rule 3 (deliverable-only) test: constructing a project-side
deliverable → ALLOWED (same verdict as V2 §8.4). They MUST NOT reference BDs
operationally (rule 2) or carry pack-self-management semantics (rule 4). The
`tracker.toml [execution_order]` section (S8) is project-side config the client
owns — not a pack-self-management surface. PASS.

---

## §9 — Success-criteria coverage (this addendum's scope)

| Prompt success criterion | Where satisfied |
|---|---|
| C-2 revised: Issue Fields demoted + gated; sub-issue-reprioritize is v11.0 default; no first-choice mechanism unavailable to typical users | A-2 (demote+gate), A-3 (selection → floor in v11.0), A-6 (floor = repo-write only); §3.2 resolution |
| Capability + availability selection; GH→Issue-Fields switch demonstrably LOCALIZED (exact place(s) named) | A-3 (selection fn), A-4 (gate predicate), §3.4 (K1 + K2; K2 no-op-able); §8 (S8/S9 only) |
| Every consumer routes through the abstract op; no mechanism-specific calls outside per-backend provider layer | A-5; §4.1 (ops); §5.1 (7 consumers, all NO); §5.2/§5.3 (calls confined to LAYER 3) |
| ENCODING-surface enumeration proving switch-locality (rules/docs/scripts/validators/workflows) | §8 (9 surfaces S1–S9; 7 agnostic, 2 = the switch) |
| Graceful degradation preserved (superior+available → superior; else floor); tracker-portability honored | A-3 (degradation built into selection); §3.3 (GA future); §7 (portability) |
| RG-1/RG-2 verified call shapes applied; rate-limit throttle + REST-preference + 100-cap addressed | §5.2 (RG-2 §2/§3 shapes), §5.3 (RG-1 §3/§5/§6 shapes); A-7 (throttle); A-8 (REST-first); A-6/§5.4 (100-cap chaining) |
| Self-contained, addendum-scoped decision log (own numbering) | §2 (A-1..A-8) |
| Scope: ordering mechanism ONLY — phase-parts / FIXED grammar / form-family / v11.0 correction NOT re-opened | §0.2 (explicit out-of-scope list); §6 (Parts steps UNCHANGED) |

---

## §10 — Handoff notes for planner

- **Design-only.** The planner sequences the surface changes into commits and
  converts §3–§6 into ordered implementation steps. No git mechanics here.
- **Net-new surface (LAYER 2/3):** three abstract ops in `tracker-provider.sh`
  (§4.1) + dispatcher cases; `_order_resolve_mechanism` + the floor helpers +
  the gated Issue-Fields helpers in `tracker-provider-gh.sh` (§4.4, §5.2, §5.3);
  the `execution_order` capability block (§4.3); the `tracker.toml
  [execution_order]` section scaffold in `tracker-init.sh` with G1 shipped
  `false` (S8); `provider_order_capability` wiring into doctor (C6).
- **V2 §7 reconciliation:** `provider_set_field`/`provider_get_field` are
  RETAINED but re-scoped to gated-backend internals (§4.2) — they are NOT the
  consumer ordering ops. Update any V2-§7-derived planning to the §4.1 ops.
- **Architect-doc-vs-reality (pack-memory rule).** This addendum realizes a
  design V2 §7 anticipated. When the coder lands the ops, ship the reconciliation
  chain: (a) docstrings in `tracker-provider.sh` naming the three ops + the
  resolver consumer; (b) a cross-reference addendum note in V2 §7 (PM/architect
  surface) pointing at this doc; (c) the IMPL-REPORT linking both. (Follows the
  BD-119 §9.2 / BD-160 precedent in the pack-memory "Architect-doc-vs-reality
  reconciliation" rule.)
- **Switch-locality is a REVIEW INVARIANT, not just a design note.** The reviewer
  must verify (i) no consumer (C1–C7) contains a literal mechanism name or a
  mechanism-specific call; (ii) `validate-pack.py` (S5) contains no mechanism
  literal — any ordering check consults `provider_order_capability`; (iii) the
  GA switch is provably K1 (+ no-op K2). A mechanism literal leaking into S1–S7 is
  a LEAK (operational) — reject it (this is the §8 asymmetric-coverage guard).
- **K2-as-no-op is RECOMMENDED, planner-confirmed.** Shipping the gated
  Issue-Fields helpers fully wired behind G1 (so the GA switch is K1-only) is the
  design's preferred end-state (§3.4). The alternative (ship a guard stub, wire at
  GA) makes K2 a real change. The planner sizes this (full-wire-now vs
  stub-now) and surfaces it; the design supports either, but K1-only is the
  switch-locality ideal the prompt asks for.
- **Rate-limit throttle (A-7) is shared infra.** The `provider_order_write
  --batch` throttle (≤80/min, ≤500/hr) applies to BOTH mechanisms (both
  content-generating). Implement once at the abstract-op batch layer, not per
  mechanism.
- **Manifest + tests.** Touching `scripts/lib/tracker-provider*.sh`,
  `scripts/lib/tracker-init.sh`, `scripts/lib/tracker-doctor.sh`,
  `scripts/lib/tracker-mirror.sh`, the migrate libs, or `scripts/validate-pack.py`
  is a v11-surface change → regenerate `test-fixtures/manifest.txt` in the same
  commit (pack-memory manifest rule). Per-check test runs apply if
  `validate-pack.py` gains an ordering check.
- **Out of scope (do not touch):** phase-parts (V2 §4), FIXED grammar (V2 §2),
  form-family (V2 §4.4), v11.0 correction (V2 §0/§10), Parts MIGRATION steps
  (V2 §6 Parts clauses). This addendum changes ordering reads/writes + selection
  ONLY.

---

## §11 — Open question surfaced to the user (not auto-decided)

- **OQ-A1 — K2 ship posture.** Ship the gated Issue-Fields backend helpers
  fully-wired-behind-G1 (GA switch = K1-only, the switch-locality ideal) vs ship a
  guard stub now and wire at GA (smaller v11.0 surface, GA switch = K1+K2). The
  design supports either; the recommendation is fully-wired-behind-gate (§3.4,
  §10). This is a planner-sizing + user-preference call, surfaced rather than
  auto-decided. Either choice preserves the demote+gate (A-2) and the floor
  default (A-3) — it only affects whether the future switch is one change or two.
