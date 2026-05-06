# PACK-REVIEW-BD060-070 — Independent quality + contract-conformance check

**Scope.** Review of the five v11 BDs landed at HEAD in commit-order positions
1–5 of `IMPLEMENTATION-PLAN.md` §3.3:

| Order | Commit | BD | Subject |
|---|---|---|---|
| 1 | `cf9ddd3` | BD-060 | TrackerProvider abstraction + GH backend |
| 2 | `c0f29ab` | BD-061 | `tracker.toml` schema + detection helper + `.pack-tracker` gitignore |
| 3 | `12243e1` | BD-063 | Issue forms `work-item.yml` + `inbound.yml` + `config.yml` |
| 4 | `6c43238` | BD-064 | Template-archive bootstrap (v11.0 SCHEMA.md set + frozen forms) |
| 5 | `7617ae5` | BD-070 | Typed-error formatter + 10-code surface |
| — | `5675b3f` | (CI fix) | PyYAML in CI for the BD-063 check |
| — | `b5887d4` | BD-111 | BACKLOG entry deferring first-class GH deps API mutation |

Predecessor of BD-065 (forward migration). The contract sources consulted are
V1 (`ARCHITECTURE.md`), V2 (`ARCHITECTURE-V2.md`), V3 (`ARCHITECTURE-V3.md`),
and V3.3-DELTA (`ARCHITECTURE-V3.3-DELTA.md`), plus
`IMPLEMENTATION-PLAN.md` §3.3 and `IMPLEMENTATION-PLAN-ADDENDUM-4.md` §2.1–§2.2.

---

## Verdict

**GO-WITH-FIXES — proceed to BD-065 after addressing findings #2, #3, and #5.**

Eleven findings total: 0 BLOCKER, 5 WARNING, 6 NIT. None are correctness
defects in the four predecessors that BD-065 will inherit; all are surface
gaps or contract-divergences that BD-065 should know about before it imports
these abstractions. The four most important findings (#2, #3, #5, #11) are
all in BD-070's verb-table and BD-061's parser surface — both readily
addressable without re-architecting any landed BD.

The biggest landed-quality items reviewed:
- TrackerProvider's 18 ops + raw + capabilities are all wired through the
  dispatcher (`scripts/lib/tracker-provider.sh:provider_*`); the public
  surface matches V1 §2.1 verbatim.
- Multi-backend extensibility test (Group 3 of `tracker-provider-test.sh`)
  is structurally sound — the dispatcher routes to a non-github backend via
  the test seam without any caller change.
- Trinity rule for the issue forms is intact: pack-side and client-side
  differ only in BD-vs-TD namespace and the description text, all of which
  is justified by V3.3 §6.1 + V2 §4 (D-4-V2).
- Typed-error formatter covers all 10 V1 §2.5 codes with a verb table and
  preserves the BD-060 / BD-061 first-line format (`ERROR: <code>` /
  `MESSAGE: <msg>`); the 56-test BD-070 suite plus the 65 + 31 prior
  suites all pass, evidencing backward compatibility.

---

## Findings

### Finding #1 — Multi-backend extensibility claim is one-edit-stronger than the dispatcher allows
**Severity:** NIT  
**Category:** cross-BD-inconsistency  
**File:Symbol:** `scripts/lib/tracker-provider.sh:_tracker_provider_dispatch`;
`scripts/tests/tracker-provider-test.sh` Group 3.  
**Contract source:** Commit cf9ddd3 message ("adding a new backend in a future
minor requires only a new sibling lib file and one case in the dispatcher's
switch — no callers change") + V1 §2 line 171.  
**Observation:** The stub-backend test exercises a `case stub)` branch that
is **already wired into the production dispatcher** (lines 109–113 of
`tracker-provider.sh`). The structural extensibility claim is therefore
verified for one specific stub backend; it does not verify that **adding**
a hitherto-unknown backend via a single new `case` is sufficient (the live
test does not add a new case at runtime). The comment on lines 105–113 also
documents the stub case as production-resident, which is mildly misleading
for an artifact used only by tests.  
**Recommendation:** None — the dispatcher works as intended and BD-065 will
not exercise this path. Future BDs adding a new backend should re-read this
finding before claiming "no callers change"; the dispatcher itself is a
caller-of-sorts.

### Finding #2 — Verb-table formatting violates V3 §27.1 "one unambiguous verb" intent for two codes
**Severity:** WARNING  
**Category:** contract-divergence  
**File:Symbol:** `scripts/lib/tracker-errors.sh:_tracker_error_verb`,
cases `network-unreachable`, `rate-limit-primary|rate-limit-secondary`,
`auth-insufficient-scope`, `partial-write`.  
**Contract source:** V3 §27.1 Layer 2 (one unambiguous "→ Run: <verb>" line);
V1 §9 per-code message shapes.  
**Observation:** Four of the ten verb-table entries embed parenthetical
alternatives or qualifications inside the verb string:
- `network-unreachable` → `gh api rate_limit  (then re-run the operation)`
- `rate-limit-{primary,secondary}` → `wait for the rate-limit reset window  (or use provider.list instead of search where possible)`
- `auth-insufficient-scope` → `gh auth refresh -s <scope>  (substitute the missing scope name)`
- `partial-write` → `pick a resume option from the list above; idempotent re-run is supported`

V3 §27.1 frames Layer 2 as "one unambiguous next-step verb," and V1 §9.1–§9.6
call out a single `Run:` line per failure mode. The current strings encode a
verb plus a follow-on hint as a single output line; tools and humans parsing
the trailing line by `→ Run: ` prefix get a verb-plus-hint blob instead of a
verb. The "wait for the rate-limit reset window …" entry is also non-imperative
(no command).  
**Recommendation:** None imposed by this review. The contract source says
the verb line should be a single unambiguous next step; the implementation
adds inline alternatives. BD-065 callers that surface partial-write recovery
will need to reconcile the resume-option set with whatever this verb
actually means.

### Finding #3 — Verb-table entry for `network-unreachable` does not match V1 §9.1 message shape
**Severity:** WARNING  
**Category:** contract-divergence  
**File:Symbol:** `scripts/lib/tracker-errors.sh:_tracker_error_verb`
case `network-unreachable`.  
**Contract source:** V1 §9.1 message-shape block; specifically the line
"Try `gh api rate_limit` to confirm connectivity."  
**Observation:** V1 §9.1 says the next step on network-unreachable is to
**confirm connectivity** via `gh api rate_limit`. The implementation emits
`gh api rate_limit  (then re-run the operation)` — phrased as a recovery
step, not a connectivity check. The semantic load is shifted: V1 wants
the user to verify their network, then the user re-runs the failing op
themselves; the implementation suggests the diagnostic verb *is* the
recovery verb.  
**Recommendation:** None imposed. The contract source says "to confirm
connectivity"; the implementation says "(then re-run the operation)".

### Finding #4 — `_gh_classify_error` "auth-missing" pattern set inverts V1 §9.3 detection precedence
**Severity:** NIT  
**Category:** contract-divergence  
**File:Symbol:** `scripts/lib/tracker-provider-gh.sh:_gh_classify_error`,
the `*"gh auth login"*` glob.  
**Contract source:** V1 §9.3 detection ("401 / `gh auth status` reports
expired or absent").  
**Observation:** The classifier puts `*"gh auth login"*` in the
`auth-missing` arm and `*"HTTP 401"*|*"Bad credentials"*` in
`auth-expired`. The `gh` CLI emits the literal string "gh auth login" in
**both** the no-token and the expired-token cases (the message is "you may
need to run `gh auth login`"), so a 401-on-expired-token can match the
auth-missing arm first and be misclassified. In practice the order is:
`gh auth login` token → matches `auth-missing` even when the underlying
cause is auth-expired. The user-visible damage is small (both arms suggest
running `gh auth login`) but the typed code surfaced to BD-065 is wrong,
which matters because BD-065 may want to differentiate the two for resume
semantics.  
**Recommendation:** None imposed.

### Finding #5 — `tracker.toml.example` files include `[mirror]` and `[cli_acceleration]` sections that the parser supports but no convenience getter or schema-version-check exists for
**Severity:** WARNING  
**Category:** BD-065-readiness-gap  
**File:Symbol:** `tracker.toml.example` + `project-template/tracker.toml.example`
(both surfaces); `scripts/lib/tracker-config.sh` (the convenience getters).  
**Contract source:** V1 §3.1 schema (lines ~480–515 of ARCHITECTURE.md).  
**Observation:** V1 §3.1 lists the full schema as `schema_version`,
`[backend]` (`name`, `repo`, `host`, `instance`), `[mode]` (`state`,
`opted_in_at`, `opted_in_by`), `[mirror]` (`enabled`, `location_*`,
`regenerate_on_write`), `[id_namespace]` (`prefix`), `[cli_acceleration]`
(`prefer`), and `[migration]` (`forward_complete`, `reverse_available`,
`last_*_run`, `mapping_file`). The parser handles every value type these
fields use (string, bool, integer, null). However, `tracker-config.sh`
ships convenience getters only for `backend.name`, `backend.repo`, and
`id_namespace.prefix` — none for `mode.state` (used inside `tracker_mode`
via dotted-key lookup but not exposed), `migration.forward_complete` (also
used inside `tracker_mode`), `migration.mapping_file` (BD-065 needs this
for the id-map sidecar), `mirror.enabled`, `mirror.regenerate_on_write`,
or `cli_acceleration.prefer`. BD-065 will compose its own
`tracker_config_get "$path" "migration.mapping_file"` call site — workable,
but the schema-coverage asymmetry is a readiness gap: BD-065 readers must
know to use the generic getter for `migration.*` keys, while
`backend.repo` has the symmetric `tracker_repo_slug` shorthand.  
**Recommendation:** None imposed; flag for BD-065 to consume
`migration.mapping_file` via the generic `tracker_config_get` API.

### Finding #6 — Pack-side and client-side issue forms have an arguably-spurious surface name in the work-item form description
**Severity:** NIT  
**Category:** cross-BD-inconsistency  
**File:Symbol:** `.github/ISSUE_TEMPLATE/work-item.yml:description` (pack);
`project-template/.github/ISSUE_TEMPLATE/work-item.yml:description` (client).  
**Contract source:** V3.3 §6.1 (pack-side may use BD-NNN; client-side
should not); CLAUDE.md trinity rule.  
**Observation:** The `wi-type` dropdown on **both** surfaces ships all four
options (`bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton`), and the
client-side form includes a description on the dropdown that says "The bd
option exists for parity with the pack-side form but is not used in
projects." This is the right answer per V3.3 §6.1's symmetry-by-default
posture. However: client-side users picking `bd` from the dropdown will
ship a bd-typed issue against their project repo with no chat-side handler
(BD logic is pack-only). The form does not validate this. Justified by
schema-parity per V3.3 §6.5, but BD-065 will not migrate client-side `bd`
entries (it never sees them), and an adventurous client-side user could
silently file one. Note for BD-065: the inverse, BD entries created on
the pack repo, is the expected path.  
**Recommendation:** None — the divergence is justified by V3.3.

### Finding #7 — Pack-side `inbound.yml` does not document upstream-mirroring behavior its client-side counterpart does
**Severity:** NIT  
**Category:** cross-BD-inconsistency  
**File:Symbol:** `.github/ISSUE_TEMPLATE/inbound.yml` (pack); same in
client-side.  
**Contract source:** V1 §7.5 (pack-feedback upstreaming); V3.3 §6.1
trinity-by-surface.  
**Observation:** The client-side `inbound.yml` description mentions "Pack-feedback
subcategories file upstream against the pack repo per V1 §7.5". The pack-side
form does not — its description says only "Pack-feedback categories land
here per V1 §7.5". The asymmetry is correct (the pack is the upstream
target; nothing further upstream exists), but it is the only place where
the trinity surfaces actually differ in user-visible explanation. Justified
by the surface-asymmetric semantic of V1 §7.5.  
**Recommendation:** None — divergence is justified.

### Finding #8 — `inbound-v11.0/SCHEMA.md` Identifier scheme allows pack-id to remain `PENDING` permanently
**Severity:** WARNING  
**Category:** contract-divergence  
**File:Symbol:**
`maintenance-docs/v11-research/templates-archive/v11.0/inbound-v11.0/SCHEMA.md` §1, §2.  
**Contract source:** V2 §4.3 + V1 §7.5; V3.3 §6.5 D-18 carrier matrix.  
**Observation:** §1 and §2 of inbound-v11.0/SCHEMA.md state: "no BD-NNN /
TD-NNN. The GH issue number is the identifier." and "(which stays `PENDING`
for external bugs and feature requests; pack-feedback entries get rewritten
on the pack side after upstream receipt)". V2 §4.3 + V1 §7.5 say
pack-feedback entries reach the **pack** repo and are rewritten there, but
they don't define what happens to the *client-side* pack-id marker after
the upstream pack-side issue is created. The client-side issue body marker
is left as `PENDING` indefinitely; there is no back-pointer to the upstream
pack-side BD/inbound number. BD-065 reverse migration drops inbound
entries entirely (`§6 Reverse-emit grammar`), so the asymmetry is not
visible after migration. But forward migration will now silently
serialize the `PENDING` marker into the v11 mirror, which mismatches the
BD/TD body-marker contract that says `pack-id: PENDING` is a transitional
state.  
**Recommendation:** None imposed; flag for BD-065's mirror-emit logic.

### Finding #9 — Phase-task SCHEMA.md "Files created/modified" section title differs from the form field label
**Severity:** NIT  
**Category:** cross-BD-inconsistency  
**File:Symbol:**
`templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` §4 ("## Files
created/modified"); `.github/ISSUE_TEMPLATE/work-item.yml:wi-files`
attribute (`label: "Files created / modified (phase-task-skeleton only)"`)
+ description.  
**Contract source:** Addendum 4 §2.1 ("`wi-files` (textarea, optional) — body
section `## Files created/modified`").  
**Observation:** Addendum 4 §2.1 prescribes `## Files created/modified`
(no spaces around the slash). The schema doc uses `## Files created/modified`,
matching the addendum. The form uses `Files created / modified` (with
spaces around the slash) as the *form-field label*. The form-field label
is user-facing copy; the body-section heading is the parsed grammar.
BD-065 / BD-067 reverse migration parses on the schema-doc heading, so
the asymmetry is harmless for round-trip — but it surfaces in user-facing
help text as inconsistency between "what you fill in" and "where it
lands."  
**Recommendation:** None — informational.

### Finding #10 — `validate-pack.py:check_template_archive_v11` only diffs pack-side live forms against the archive, not client-side
**Severity:** WARNING  
**Category:** BD-065-readiness-gap  
**File:Symbol:** `scripts/validate-pack.py:check_template_archive_v11`
(the live-vs-archived byte-equality loop).  
**Contract source:** V2 §19.4 (archive contract); BD-064 plan
(per-surface form parity).  
**Observation:** The check sets `live = REPO_ROOT / ".github" /
"ISSUE_TEMPLATE" / form_name`, comparing only the **pack-side** form to
the archived copy. Per the trinity rule, the client-side
`project-template/.github/ISSUE_TEMPLATE/{work-item,inbound}.yml` files
must also stay in lockstep with the archive (or with their pack-side
counterparts, which themselves are byte-equal to the archive). The
`check_issue_template_forms` helper does test both surfaces structurally,
but byte-level drift between the client-side form and the archive is
unmonitored. BD-065 will write client-side issues using the client-side
form's body-marker shape; if the client-side form drifts (a future BD
edits one and forgets the trinity edit), the archive will not catch it.  
**Recommendation:** None — informational.

### Finding #11 — `tracker-config.sh` parser does not expose schema_version error details in `tracker_schema_version_check` output
**Severity:** NIT  
**Category:** BD-065-readiness-gap  
**File:Symbol:** `scripts/lib/tracker-config.sh:tracker_schema_version_check`.  
**Contract source:** V1 §3.1 + V1 §9.5 (schema-reshape error semantics).  
**Observation:** When `tracker_schema_version_check` finds a mismatch, it
emits a `validation` typed code with one line of context. V1 §9.5 maps
schema-reshape conditions (where the on-disk schema does not match the
runtime's expected schema) to the `schema-reshape` typed code, with
`pack tracker doctor` as the next step. `tracker_schema_version_check`
emits `validation` (correct per BD-061's plan that `validation` is the
catch-all for caller-input mismatches) but BD-065 reading "schema_version=2,
expected 1" might prefer `schema-reshape` to surface the doctor
recommendation. The classifier choice is intentional (pre-migration
schema is caller-supplied, not GraphQL-detected), but worth noting as a
typed-code routing decision BD-065 inherits.  
**Recommendation:** None imposed.

---

## Verification matrix

| Landed BD | V1 sections checked | V2 sections checked | V3 / V3.3 sections checked | Plan refs |
|---|---|---|---|---|
| BD-060 (provider) | §2.1 (op set), §2.2 (canonical Issue), §2.3 (capability schema), §2.4 (link.kind), §2.5 (10 typed codes), §2.6 (pagination), §2.7.1 (op→cmd map), §2.7.2 (GH capabilities), §2.7.3 (extension policy), §2.7.4 (preview header) | — | V3.3 reaffirmed § via §6 (templates) — provider unchanged | §3.3 step 1 |
| BD-061 (config + detection) | §3.1 (schema), §3.2 (detection), §3.4 (independence axes) | — | V3.3 §6.4 (identifier scheme references id_namespace.prefix) | §3.3 step 2 |
| BD-063 (issue forms) | §4.1, §4.2, §4.3, §4.4, §4.6 (cross-tracker compatibility) | §4.1 (form family), §4.2 (work-item fields), §4.3 (inbound fields) | V3.3 §6.1 (4-option wi-type), §6.5 (D-18 carrier matrix) | §3.3 step 3; Addendum 4 §2.1 |
| BD-064 (template archive) | §6.6.1 (template-version drift) | §19.4 (archive layout) | V3.3 §6.5 (D-18 matrix), §6.3 (state mapping), §6.4 (identifier scheme) | §3.3 step 4; Addendum 4 §2.2 |
| BD-070 (typed errors) | §2.5 (10 codes), §9.1–§9.7 (per-code UX) | — | V3 §27.1 Layer 2 (verb line) | §3.3 step 5 |
| BD-111 (deferred) | §2.7.1 row 12 (link op); EXTERNAL §1.5 (deps GA date) | — | — | (BACKLOG only) |

CLAUDE.md trinity rule applied to: pack ↔ client `work-item.yml`,
`inbound.yml`, `config.yml`. Pack-side and client-side differ only by
the BD/TD namespace, the surface-name (Pack vs Project), and the V1 §7.5
upstreaming sentence (client mentions upstream; pack does not — surface-
asymmetric by design). All other dropdowns, fields, body markers, and
labels are byte-identical modulo the namespace substitution.

---

## BD-065 readiness summary

**The four predecessors collectively give BD-065 everything it needs.**
Specifically:

1. **`provider.create` + `provider.sub_issue_create`** for issue/parent
   emission — both wired through the dispatcher, both tested against
   fixtures, capability-flag-aware (will detect `gh-sub-issue` extension
   or fall back to GraphQL).
2. **`tracker_config_get "$path" "id_namespace.prefix"`** (or the
   convenience `tracker_id_prefix`) for BD-NNN/TD-NNN namespace resolution.
3. **`tracker_config_get "$path" "migration.mapping_file"`** for the
   id-map sidecar path. No convenience helper, but the generic getter
   covers it (Finding #5).
4. **`tracker_error_emit "partial-write" "..."`** for surfacing partial
   migration failures with the V3 §27.1 Layer-2 next-step verb. Verb-table
   text for `partial-write` is "pick a resume option from the list above"
   — BD-065 must emit the resume-option list as the message body
   *before* invoking `tracker_error_emit`, since the formatter appends
   the verb but does not generate the option list.
5. **All 10 typed codes** are emit-ready; BD-065 should additionally
   consume `not-found` (issue id resolution), `validation` (caller-input
   errors), `schema-reshape` (capability-flag mismatch on a backend the
   pack thought it knew), and `partial-write` (multi-step failure).

**Non-blocker readiness gaps** (Findings #5, #8, #10, #11):
- Migration callers must read `migration.mapping_file` via the generic
  getter, not a convenience wrapper.
- Inbound entries' `pack-id: PENDING` body marker stays `PENDING` after
  forward migration; BD-065's mirror-emit logic should know.
- Client-side form drift is not byte-checked against the archive; BD-065
  itself does not introduce drift, but a follow-on BD might.
- `tracker_schema_version_check` emits the `validation` typed code on
  schema mismatch, not `schema-reshape`. BD-065 callers reading the
  result should expect `validation` and re-classify if surfacing
  doctor-recommended recovery.

**No correctness defects** were observed in any of the five landed BDs.
Tests pass: tracker-provider 65/65, tracker-config 31/31, test-issue-forms
78/78, tracker-errors 56/56. validate-pack: clean.

---

## Closing line

**GO-WITH-FIXES — proceed to BD-065 after addressing findings #2, #3, and #5.**
