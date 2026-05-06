# PACK-REVIEW-BD065 — Independent quality + contract-conformance check

**Scope.** Review of BD-065 (commit `007273c`) — the V1 §6.2 11-step
forward-migration orchestrator landing in `scripts/tracker-migrate.sh`,
`scripts/lib/tracker-migrate-forward.sh`, fixtures under
`scripts/tests/fixtures/tracker-migrate/`, and the 76-test suite at
`scripts/tests/tracker-migrate-forward-test.sh`. Predecessors BD-060
/ BD-061 / BD-070 are consumed; BD-066 will compose on top.

Contract sources consulted: `ARCHITECTURE.md` (V1) §2.5 / §4.1 / §6.0
/ §6.1 / §6.2 / §6.3 / §6.4 / §6.7 / §9.1–§9.6;
`ARCHITECTURE-V2.md` §22.1; `ARCHITECTURE-V3.3-DELTA.md` §6.3 / §6.4
/ §6.5; `IMPLEMENTATION-PLAN.md` §1.3 (BD-065 spec lines 129–145);
`IMPLEMENTATION-PLAN-ADDENDUM-4.md` §2.3.

---

## Verdict

**GO-WITH-FIXES — proceed to BD-066 after addressing findings #1, #2,
#3, #5, and #7.**

Twelve findings total: 0 BLOCKER, 6 WARNING, 6 NIT. The orchestrator
is structurally sound — the 11 V1 §6.2 steps are present, idempotency
holds at the mapping-file layer, the test suite proves zero
double-creates on second run, the BD-060/-061/-070 abstractions are
consumed cleanly, and the BD-106/-108 extension points are well-marked.
The fixes recommended are surface-level (mirror-header byte drift,
missing third-marker probe, partial-step checkpoint cadence, dropped
File/Symbol body field, untested checkpoint integration) rather than
re-architecting work.

What landed well:
- 11-step algorithm enumerated 1:1 against V1 §6.2 in the
  orchestrator's prose comments and code structure.
- Fast-path mapping check + slow-path title-marker search both wired
  (`tmf_create_or_lookup`).
- Phase epics created in a separate pass before the link loop
  (`tracker_migrate_forward_run` lidx loop runs after the pidx loop),
  so sub-issue parents exist when their members are linked — a
  non-trivial ordering invariant honoured.
- D-18 carrier (template_version + pack-id + pack-version trio)
  emitted per V3.3 §6.5.
- State mapping for Resolved / Cancelled / Deprecated lands the right
  `state_reason` per V3.3 §6.3.
- Test seam `_TRACKER_PROVIDER_BACKEND_OVERRIDE=github` works against
  the fixture `backend.name=stub`, exercising the override-wins-
  absolutely priority documented in `tracker-provider.sh`.

---

## Findings

### Finding #1 — `tmf_create_or_lookup` does not probe the body-footer marker
**Severity:** WARNING
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tmf_create_or_lookup`
**Contract source:** V1 §6.2 line 1031 ("two redundant markers ...
title marker, body footer marker, mapping file") and lines 1040–1042
("any entry without a mapping record but with a matching title marker
upstream is recovered into the mapping").
**Observation:** V1 §6.2 names three idempotency markers and frames
the body-footer marker as "preserved through edits ... if a future
GH version strips it, we fall back to title marker only."
`tmf_create_or_lookup` probes (a) the mapping file, then (b)
`provider_search "in:title \"$pack_id:\""`. The body-footer marker
`<!-- pack-id: BD-NNN -->` is **emitted** at create time (in
`tmf_compose_issue_body`) but **never read** by any recovery path in
BD-065. V1 §6.2 frames it as a third independent recovery path;
BD-065 implements it as write-only.

### Finding #2 — Mirror-header round-trip adds a blank line on every re-run
**Severity:** WARNING
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:_tmf_regen_mirror`
**Contract source:** V1 §6.3 ("flat files become read-only mirrors,
regenerated on write") and §6.7 round-trip safety ("forward → reverse
→ forward should be a no-op or near-no-op").
**Observation:** First-run prepend writes `printf '%s\n\n' "$header"`
then the original body (one blank line between `-->` and body).
Second-run replacement writes `printf '%s\n' "$header"` then
`printf '\n%s' "$body"`, where `body` is captured via
`body=$(awk ...)`. Command substitution preserves the leading blank
line that the awk filter leaves in place after stripping lines 1–6
of the prior header. The resulting file has two blank lines between
`-->` and content; a third run inherits that and produces three. The
body content is not byte-equal across re-runs modulo the header. This
violates V1 §6.7's near-no-op guarantee for the forward-twice case.

### Finding #3 — V1 §4.1 `File/Symbol` field is not emitted into the issue body
**Severity:** WARNING
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tmf_compose_issue_body`
and the create-branch in `tracker_migrate_forward_run`
**Contract source:** V1 §4.1 BD-entry mapping table ("File/Symbol →
body field (kept verbatim; not a GH first-class concept)") and Part 7
of METHODOLOGY referenced by V1 §4.1.
**Observation:** The composer emits Description, Context, and
Resolution sections only. The parser captures `file_symbol`
(`tmf_parse_backlog` writes the `file_symbol` key on every entry),
and the fixture entry `BD-001` carries `File/Symbol: scripts/foo.sh`
— but the value never reaches the issue body. V1 §4.1 says
File/Symbol is body-only ("not a GH first-class concept"), so
dropping it loses round-trip data for that field. V1 §6.0
(bidirectionality contract) names this as a defect: "for every
v10-grammar field of every entry, flat-file content == tracker
content."

### Finding #4 — Steps 8 and 9 (close + comment) execute inline with step 4 rather than after step 7
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`
(the `create)` arm of the case statement inside the per-entry loop)
**Contract source:** V1 §6.2 enumerated step list (steps 1–11 in
numeric order).
**Observation:** V1 §6.2 enumerates step 4 (per-entry create), step 5
(phase create), step 6 (sub-issue links), step 7 (blocked-by links),
step 8 (close on Resolved), step 9 (comment with Resolution). The
orchestrator collapses 8 + 9 inside the step-4 case branch. The
functional effect is identical for the happy path. The deviation
matters for failure semantics: if `provider_close` fails, the entry
is in the mapping with status uncommitted, and on resume the entry
is in `completed_ids`, so step 8 won't re-run. `provider_close`
failure is silently swallowed (`|| true`) so this is a typed-error-
coverage gap as well — see Finding #5.

### Finding #5 — Provider call failures in steps 6 / 7 / 8 / 9 are silently swallowed instead of surfacing as `partial-write`
**Severity:** WARNING
**Category:** cross-BD-composition
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`
— the `provider_close ... || true`, `provider_comment ... || true`,
`provider_sub_issue_create ... || true`, and `provider_link ... || true`
lines
**Contract source:** V1 §2.5 typed-error model ("never silently
retried; surface-able"); V1 §9.6 partial-write recovery ("Surface
with the per-step success/failure list; offer to resume from the
failed step"); V1 §6.4 failure-handling table.
**Observation:** Four provider calls suppress non-zero return codes
via `|| true`. Per V1 §2.5 + §9.6, failures of these multi-step
operations should surface a `partial-write` typed error with the
per-step success/failure list. The `tracker_error_emit "partial-write"`
path is reachable in BD-070 but is never invoked by BD-065. The
PACK-REVIEW-BD060-070 BD-065 readiness summary explicitly anticipated
that BD-065 would emit `partial-write` for multi-step failures; it
doesn't. Step-4 `provider_create` failure does propagate
(`return 1`), so the create path is correct; only the post-create
steps are silenced.

### Finding #6 — Checkpoint cadence is untested at the integration level; the 25-issue boundary is never exercised
**Severity:** WARNING
**Category:** idempotency
**File:Symbol:** `scripts/tests/tracker-migrate-forward-test.sh` Group 3;
`scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`
(the `if [[ $((idx % TMF_CHECKPOINT_INTERVAL)) -eq 0 ]]` block)
**Contract source:** V1 §6.4 ("writes a checkpoint after every 25
issues so a partial run is exactly resumable").
**Observation:** Group 3 fixture has 5 entries + 2 phases. With
`TMF_CHECKPOINT_INTERVAL=25` (the V1 §6.4 default), the checkpoint
write block at line ~621 of the orchestrator is never reached
during integration tests. The checkpoint helpers (Group 2.4) are
tested in isolation, but the production code path that writes the
checkpoint inside the per-entry loop, AND the resume-from-checkpoint
path with the `completed_ids` skip logic, are unexercised.

### Finding #7 — Failure between checkpoint write and the next entry leaves the mapping write-half-stale
**Severity:** WARNING
**Category:** idempotency
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`
(the per-entry loop's `idx=$((idx + 1))` and conditional checkpoint
block)
**Contract source:** V1 §6.4 ("partial run is exactly resumable").
**Observation:** Inside the per-entry loop, the orchestrator (a)
creates an issue, (b) updates the in-memory `mapping` JSON via
`tmf_mapping_set`, (c) appends to `completed_ids`, (d) increments
`idx`, (e) writes checkpoint + mapping to disk **only at every 25th
entry**. If the script dies between (b) and (e), entries 1–24 are in
tracker (with body markers + title markers), but `id-map.json` on
disk still reflects pre-run state. On resume, `--resume` loads the
empty `completed_ids` and the empty mapping; entries 1–24 will route
through the `provider_search` recovery path (Finding #1 only probes
title, not body), and re-runs of `provider_create` are NOT idempotent
on the GH side. Tightening the cadence (write mapping every entry) or
writing the mapping atomically per-entry would close the window.

### Finding #8 — `lookup` routing branch records a counter but does not resolve the gh-id into the mapping; deferral to BD-068 is not bounded against re-creates
**Severity:** NIT
**Category:** idempotency
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`
(the `lookup)` arm of the case)
**Contract source:** V1 §6.2 line 1011 ("if found, write to mapping
and skip"); commit message ("BD-068 round-trip lands the full
resolve-from-search behavior").
**Observation:** When `tmf_create_or_lookup` returns `lookup`, the
orchestrator increments `looked_up` and moves on without (a)
extracting the gh-id from the search hit, (b) writing it to the
mapping, or (c) emitting a typed warning. V1 §6.2 says "write to
mapping and skip"; BD-065 does neither write nor skip-with-record.
Critically, this means the entry's links (steps 6/7) and close
(step 8) **are never executed for it**: the lidx loop reads
`gh_id=$(tmf_mapping_get "$mapping" "$pack_id" || echo "")` and skips
when empty. The deferral to BD-068 is real but unbounded: the entry
stays in a half-migrated state with no warning.

### Finding #9 — Step-ordering invariants for V1 §6.2 (mapping write before mirror regen)
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`
(the post-loop block)
**Contract source:** V1 §6.2 step 10 / step 11; V1 §6.4 row "Step 10
(mirror regen): re-run with `--mirror-only` flag".
**Observation:** Ordering matches V1 §6.2 — but if `_tmf_regen_mirror`
fails (the awk/printf pipeline is not surrounded by error-checking),
the orchestrator continues to the mapping write. Since the mirror
function returns 0 even on internal awk failure, the failure mode is
silent. The mapping correctly persists, so this is recoverable, but
the sequence violates the V1 §6.4 "step 10 (mirror regen) failure:
re-run with `--mirror-only` flag" contract — there's no `--mirror-only`
flag in BD-065's script.

### Finding #10 — `--mirror-only` recovery flag named in V1 §6.4 is absent from `cmd_forward`
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/tracker-migrate.sh:cmd_forward`
**Contract source:** V1 §6.4 failure-mode table, row "Step 10".
**Observation:** The V1 §6.4 recovery row for step-10 failure says
"re-run with `--mirror-only` flag". `cmd_forward` accepts
`--repo-root`, `--dry-run`, `--resume`, but not `--mirror-only`.
V2 §22.1 also names `pack tracker mirror-rebuild` as a wrapper "over
`tracker-migrate.sh --mirror-only`"; with no `--mirror-only` to wrap,
BD-066's `pack tracker init` and the eventual `pack tracker
mirror-rebuild` lose this recovery surface.

### Finding #11 — Mirror header awk filter is whitespace-fragile and case-fragile
**Severity:** NIT
**Category:** idempotency
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:_tmf_regen_mirror`
**Contract source:** V1 §6.3 mirror-header shape.
**Observation:** The awk filter requires `$0 == "<!--"` exactly — no
trailing whitespace, no surrounding indentation. If a user (or
another tool) re-formats the mirror with leading whitespace, the
second-run header detection silently fails and `_tmf_regen_mirror`
prepends a second header on top of the existing one.

### Finding #12 — `tracker_migrate_status_report` does not surface mirror freshness or template freshness as V2 §22.1 specifies
**Severity:** NIT
**Category:** BD-066-readiness-gap
**File:Symbol:** `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_status_report`
**Contract source:** V2 §22.1 verb table row for `pack tracker status`.
**Observation:** The status report emits 4 of the 8 fields V2 §22.1
specifies. BD-066's `pack tracker status` wrapper will inherit this
surface — either BD-066 will need to extend the report or the V2
§22.1 contract will land short.

---

## Verification matrix

| BD-065 component | V1 sections checked | V2 / V3.3 | Plan refs |
|---|---|---|---|
| `tracker-migrate.sh` dispatcher | §6.1 (4-verb command surface) | V2 §22.1 | Plan §1.3 |
| `tmf_parse_backlog` | §6.2 step 2; §6.0 bidirectionality | V3.3 §6.4 | Plan §1.3; Addendum 4 §2.3 |
| `tmf_parse_implementation_plan` | §6.2 step 5; §6.5 | V3.3 §6.4 | Addendum 4 §2.3 (BD-106 ext point) |
| `tmf_mapping_*` | §6.2 step 3, step 11; §6.7 | — | Plan §1.3 |
| `tmf_checkpoint_*` | §6.4 (25-issue cadence) | — | Plan §1.3 DoD |
| `tmf_compose_issue_body` | §4.1 BD entry body field mapping | V3.3 §6.5 D-18 | Addendum 4 §2.3 |
| `_tmf_labels_for_entry` | §4.1 | V3.3 §6.3 / §6.5 | — |
| `tmf_mirror_header` + `_tmf_regen_mirror` | §6.3 + §6.7 | — | — |
| `tmf_create_or_lookup` | §6.2 lines 1031–1042 (three-marker idempotency); §2.7 | — | — |
| `tracker_migrate_forward_run` orchestrator | §6.2 (11 steps); §6.4; §2.5 | V3.3 §6.3 | Plan §1.3; Addendum 4 §2.3 |
| `_tmf_update_tracker_toml` | §3.1 + §6.2 step 11 | — | — |
| `tracker_migrate_status_report` | §6.1 | V2 §22.1 | Plan §1.3 DoD |
| Provider call sites | §2.1; §2.5; §6.2 step ordering | — | — |
| Test seam priority | §3.2 detection | — | tracker-provider.sh |

V1 §6.0 bidirectionality contract was checked against the
`file_symbol` field handling (Finding #3); V1 §6.7 round-trip safety
was checked against the mirror-header byte-equality property
(Finding #2).

---

## BD-066 readiness summary

**Net assessment.** BD-066 (`pack tracker init` wrapper + label/template
ensure step) can compose on top of BD-065 with two minor adaptations
and one extension that should ride on top of BD-066's commit:

1. **`pack tracker init` wraps `tracker-migrate.sh forward` directly.**
   The dispatcher surface in `cmd_forward` is sufficient; BD-066 will
   pass `--repo-root` and rely on the typed-error surface of BD-070 /
   BD-065 to bubble auth failures.
2. **`pack tracker status` surface is short of V2 §22.1.** BD-066's
   status wrapper will need to either extend `tracker_migrate_status_report`
   or compose a new status fan-out.
3. **`pack tracker mirror-rebuild` (V2 §22.1) is named as a wrapper
   over `tracker-migrate.sh --mirror-only`, but the flag does not
   exist (Finding #10).** BD-066 will land or defer this verb.

**Blocking-for-BD-066?** No. BD-066's scope is the wrapper, the
labels, and the auth validation — it does not require fixing the
BD-065 findings. Findings #1, #2, #3, #5 should be addressed in a
BD-065-amend (or as ride-along fixes in BD-066's commit) because they
are correctness gaps at the BD-065 level; Finding #7 should be
addressed before BD-068 round-trip lands.

---

## BD-106 / BD-108 extension-point soundness

**BD-106 (phase-task entity model + parser/emitter).** Addendum 4 §2.3
names two BD-065 extension points:

1. **Step 5 (parse) extension** — invoke BD-106's phase-task parser
   on `IMPLEMENTATION-PLAN.md`. BD-065's `tmf_parse_implementation_plan`
   recognises only `### Phase N — <title>` headings; `#### N.M`
   headings are silently skipped. This is the right shape for BD-106
   to extend without re-architecting. **Soundness: GO.**

2. **Step 7 (links) extension** — BD-065's link emission lives in the
   lidx loop, branching on `phase-[0-9]*` vs `BD-*|TD-*` token shapes.
   BD-108 can add `phase-[0-9]+\.[0-9]+)` as a new arm without
   touching existing arms. The concerning bit: links execute via
   `provider_link ... || true` (Finding #5) — BD-108's typed-error
   contract needs the silent-suppression to be removed before BD-108
   lands. **Soundness: GO with the caveat that Finding #5 should be
   fixed before or during BD-108's commit.**

**BD-108 (cross-entity dependency module).** The link-emission code
path is structured around the `case "$raw"` token-classifier. BD-108's
plan to extend admits `phase-N.M` and Dependencies-bullet entries;
both extension points slot in cleanly. Cycle-check requirement
(V3.3 §5.5; default K=10) cannot be added in-place — Finding #5's
silent-suppression of `provider_link` failures will mask cycle-check
refusals. BD-108 is structurally compatible with BD-065's link layer
if Finding #5 is fixed. **Soundness: GO conditional on Finding #5.**

---

## Closing line

**GO-WITH-FIXES — proceed to BD-066 after addressing findings #1, #2,
#3, #5, and #7. Findings #4, #6, #8–#12 may land as ride-along fixes
during BD-066 / BD-067 / BD-068 without blocking BD-066.**
