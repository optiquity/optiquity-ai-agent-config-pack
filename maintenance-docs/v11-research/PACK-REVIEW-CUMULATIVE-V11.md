# PACK-REVIEW-CUMULATIVE-V11 — independent v11.0 surface review

- HEAD: `f9da4d1` (after F1–F14 sweep + R4 NIT cleanup)
- Reviewer: pack-reviewer (independent re-derivation pass)
- Method: re-read V1 / V2 / V3 / V3.1 / V3.2 / V3.3 contracts, re-derive expected
  surfaces, compare to landed code at HEAD; tests + validate-pack run clean.
- Test totals confirmed: 11 suites, 672 PASS / 0 FAIL
  (44 + 36 + 78 + 31 + 32 + 60 + 91 + 109 + 87 + 39 + 65 = 672).
- `python3 scripts/validate-pack.py` exits 0; new BD-063 / BD-064 checks green.
- Prior PACK-REVIEW-* docs were NOT consulted (per the prompt's exclusion list).

---

## Verdict

**GO-WITH-FIXES.**

## Net assessment

The v11.0 surface lands the documented contracts at the operation, schema, and
file-layout level. The tracker provider abstraction shape (V1 §2), the GH
capability declaration (V1 §2.7.2), the tracker.toml schema (V1 §3.1), the
form family (V2 §4 / V3.3 §6.1), the template-archive layout (V2 §19.4 +
V3.3 §6.5), the typed-error formatter (V1 §2.5 + V3 §27.1), the marker trio
(V2 §6.2), and the doctor / status / mirror-rebuild verbs (V2 §22.1) are all
present and structurally correct. The 11-step forward algorithm and 9-step
reverse algorithm match the V1 §6.2 / §6.5 step ordering. The trinity
Document-locations Source column is uniformly present in all three project-
template trinity files (D-6). The 672-test suite covers idempotency,
round-trip on the v10 grammar, atomic disable, error-mapping coverage,
and dual-carrier reconciliation.

The v11.0 surface has **one BLOCKER**: nothing in the code path flips
`migration.forward_complete = false → true` after a successful `init` +
forward run. `tracker-init.sh` writes the file with `forward_complete = false`;
forward migration writes only `last_forward_run`. The V1 §3.2 detector reads
`forward_complete` and falls back to flat-file when it is not `true`.
Consequence: every project that runs `pack tracker init` end-to-end stays in
flat-file mode by `tracker_mode()` even though the tracker is fully populated.
Tests do not catch this because every roundtrip / agent-read / config fixture
writes `forward_complete = true` literally into the fixture's tracker.toml.
The example file (`tracker.toml.example`) explicitly documents that the
migration "will set `migration.forward_complete = true`" — that documented
behaviour is not implemented anywhere.

A small set of WARNINGs and NITs accompany the BLOCKER: agent-prompt
adaptation reaches only 2 of the 5 prompts that read BACKLOG/STATUS data
(V1 §8.4 / V1 §8.3 expected ~8 of 10); `pack tracker doctor` defers
capability-cache refresh (V2 §22.1 names it as a sub-surface); 11 Python-
embedded error sites bypass `tracker_error_emit` and so omit the V3 §27.1
Layer-2 verb line; reverse-side Type field round-trip emits the literal
string `TODO(scope)` rather than `TODO(<scope-value>)`. None of these
blocks the v11.0 design intent the way the BLOCKER does, but they are all
contract divergences with traceable spec citations.

The extension-point posture for BD-072 / BD-074 / BD-089 / BD-106 / BD-108 /
BD-111 is sound: the sidecar emits all V1 §6.6 sub-blocks via overridable
hooks, the dispatcher accepts a new backend by adding one case, the
provider operation set is the documented 18 + raw, the canonical label set
is open-string for `derived-from:` / `promoted-to:` / `scope:phase-N`, and
`update-templates` reads a manifest that an empty-at-v11.0 contract
expressly designs for v11.1+ population.

---

## Findings (numbered)

### Finding 1 — BLOCKER — contract-divergence
**File / symbol:** `scripts/lib/tracker-migrate-forward.sh::_tmf_update_tracker_toml` and
`scripts/lib/tracker-init.sh::_tracker_init_write_config`
**Contract source:** ARCHITECTURE.md §3.2 (mode detection) + §6.2 step 11
("Write mapping file. Update `tracker.toml.migration.last_forward_run`")
+ tracker.toml.example documentation block ("The migration will set
`migration.forward_complete = true`, after which `tracker_mode()` resolves to
'tracker'") + Decisions table D-5 ("`mode.state = "tracker"` AND
`migration.forward_complete = true` ⇒ tracker mode").
**Observation:** `_tracker_init_write_config` writes `forward_complete = false`
into a freshly-created tracker.toml. `_tmf_update_tracker_toml` (called from
step 11 of `tracker_migrate_forward_run`) edits only `last_forward_run = "..."`.
No code path writes `forward_complete = true` after a successful forward run.
`tracker_mode()` in `scripts/lib/tracker-config.sh` returns "flat-file" when
`migration.forward_complete != "true"` (lines 197–199). Net result: a
production user who runs `pack tracker init` end-to-end with auth + repo
present + forward succeeding still sees `tracker_mode()` resolve to "flat-file"
on every subsequent invocation — the agent-read path, the doctor verb, the
status verb, and the tracker-startup skill all read flat-file. Test fixtures
under `scripts/tests/fixtures/{roundtrip,tracker-config,tracker-migrate,tracker-agent-read}`
hard-code `forward_complete = true`, so the test suite passes despite the
production gap.

### Finding 2 — WARNING — contract-divergence / test-coverage-gap
**File / symbol:** `project-template/docs/pack/prompts/{coder,auditor,reviewer}.md`
**Contract source:** ARCHITECTURE.md §8.3 ("These are encoded as required-reading
bullets in every agent prompt that touches the tracker (currently 8 of the
10 prompts)") + §8.4 (resolver-aware language: replace "Read BACKLOG.md" with
"Read BACKLOG entries (resolve via trinity Document locations)") + §8.5 D-9
choice (b).
**Observation:** Five prompts under `project-template/docs/pack/prompts/` mention
BACKLOG or STATUS literally: coder.md, auditor.md, reviewer.md, tester.md,
pm-chat.md. BD-071 updated only tester.md and pm-chat.md to the resolver-aware
language. coder.md still names `BACKLOG.md` directly (lines 52, 63, 77, 166);
auditor.md does the same (lines 42, 48, 91); reviewer.md too (lines 61, 68).
Per V1 §8.4 and the BD-071 resolution criteria, every tracker-touching prompt
must use the resolver-aware framing — the gap is 3 of the 5 prompts that
read backlog data.

### Finding 3 — WARNING — error-surface-coverage
**File / symbol:** Python-embedded error sites in
`scripts/lib/{tracker-config,tracker-agent-read,template-translations}.sh`
(11 occurrences)
**Contract source:** ARCHITECTURE-V3.md §27.1 Layer 2 ("Every error message
ends with one unambiguous 'run X to fix' line") + ARCHITECTURE.md §9.x per-code
shapes (every documented shape ends with a `Run:` directive).
**Observation:** Every bash call site uses `tracker_error_emit`, which appends
the `→ Run: <verb>` line per the V3 §27.1 contract. Python-embedded heredocs
inside `tracker_config_read`, `tracker_agent_read_entry` (flat-file branch),
`template_translations_load`, `template_translations_resolve_chain`, and
`template_translations_apply_rules` write `ERROR: <code>\nMESSAGE: <text>\n`
directly to stderr without the Layer-2 verb line. Eleven Python-emitted
error sites bypass the formatter and so are non-conformant with V3 §27.1
(verb-naming) and V1 §9 (per-code message shape ends with "Run: ...").

### Finding 4 — WARNING — contract-divergence
**File / symbol:** `scripts/tracker-migrate.sh::tracker_doctor_run`
**Contract source:** ARCHITECTURE-V2.md §22.1 row for `pack tracker doctor`
("Validates `tracker.toml`, refreshes capability cache, validates mirror
freshness, validates mapping integrity, validates template freshness").
**Observation:** Doctor implements config check, mapping integrity, mirror
freshness, template freshness, and templates-dir presence (5 of 5 named
sub-surfaces *if* mapping-integrity counts as one). The capability-cache
refresh sub-surface (V2 §22.1 explicit) is deferred — the function header
comment names it: "Capability re-probing is deferred to a future BD". V1
§9.5 and §2.7.4 connect schema-reshape recovery to the doctor verb's
capability re-probe; without it, a `schema-reshape` error has no recovery
path inside v11.0.

### Finding 5 — WARNING — round-trip / contract-divergence
**File / symbol:** `scripts/lib/tracker-migrate-reverse.sh::_tmr_decode_type`
**Contract source:** ARCHITECTURE.md §6.5 step 3 ("Type ← title prefix decode +
label scope: + label severity:") + §4.1 mapping table ("Type | type field
(org-level issue type if available; otherwise type:<value> label)") +
ARCHITECTURE-V3.3-DELTA.md §6.3 status mapping rows.
**Observation:** Reverse emits the literal string `TODO(scope)` /
`KNOWN GAP(scope)` for TD-* in the BACKLOG.md `Type:` field rather than
substituting the actual scope value (`TODO(phase-3)`, `TODO(dependency)`,
…). The scope is preserved separately on a `Scope:` line emitted only when
present. The v10 BACKLOG grammar that the test fixtures and METHODOLOGY §
Part 7 describe places the scope inside the `TODO(...)` parenthetical of the
Type field. The current reverse output is therefore a near-no-op (information
preserved, shape divergent) rather than the byte-equivalent / whitespace-
tolerant zero-diff V1 §6.7 invariant calls for on the v10 grammar.

### Finding 6 — WARNING — contract-divergence
**File / symbol:** `scripts/lib/tracker-migrate-reverse.sh::tracker_migrate_reverse_run`
**Contract source:** ARCHITECTURE.md §6.5 step 1 ("Provider.list(filter={label:
'td-entry' OR label: 'bd-entry'}, full body)") + §6.5 step 2 ("Provider.search(
query='type:Epic in:title \"Phase\"') for phase epics").
**Observation:** Reverse uses the mapping file (`.pack-tracker/id-map.json`)
as the entry index instead of `provider_list` / `provider_search`. The
function comment explicitly notes this: "We use the mapping file as the
authoritative source of which issues to fetch (BD-060's `provider_list` is
filter-based; the mapping is the ground truth of pack-managed entries)."
This decision means tracker entries that exist with the right labels but
were never registered in the mapping (e.g., a user who created a TD-NNN
issue manually via the form after init) will not round-trip on reverse.
The contract reads the labels; the implementation reads the mapping. The
divergence is defensible (mapping is authoritative for pack-managed entries)
but it is a divergence from the V1 §6.5 algorithm text and changes which
entries the disable verb reverses.

### Finding 7 — NIT — error-surface-coverage / extension-point-soundness
**File / symbol:** `scripts/lib/tracker-errors.sh::tracker_error_codes`
**Contract source:** ARCHITECTURE.md §2.5 (the 10-code typed error model).
**Observation:** `tracker_error_codes` emits 11 codes — the 10 V1 §2.5 codes
plus a v11.0-additive `not-implemented`. The verb table maps `not-implemented`
to `pack tracker doctor`. This is technically additive (it does not violate
V1 §2.5 because §2.5 is a minimum surface, not an exhaustive list), but it
is also undocumented in any architecture file. The verb table mapping is
defensible for not-yet-shipped subcommands; the divergence-from-spec
treatment requires either V2-style addendum or a `## Decisions changed`
entry recording the addition. Treating this as a NIT because it does not
break a contract — it is an unrecorded extension.

### Finding 8 — NIT — atomicity / cross-component-inconsistency
**File / symbol:** `scripts/lib/tracker-migrate-forward.sh::tmf_mapping_save`
**Contract source:** ARCHITECTURE.md §6.4 ("The script writes a checkpoint
after every 25 issues into `.pack-tracker/forward.checkpoint.json` so a
partial run is exactly resumable").
**Observation:** `tmf_mapping_save` uses write-tmp + rename for atomicity (good).
`tmf_checkpoint_write` does the same. Forward writes the mapping after
each create (line 687) and again after step 11 (line 842). This is correct
for crash-safety but means the mapping file mtime updates on every issue
creation; the doctor's mirror-freshness check uses BACKLOG.md vs
`last_forward_run` so this does not propagate. The cross-component aspect:
forward saves the mapping after each create *and* after step 11; reverse
does not modify the mapping at all (it only reads). After a `disable` run
the mapping file is left intact, which is correct for re-enable. The cross-
component inconsistency is that the cleanup convention is implicit; a
`pack tracker init` run on a tree that already has `.pack-tracker/id-map.json`
will pick up the prior mapping and skip-recover entries, which is V1 §6.7
behaviour — but if the prior tracker repo no longer matches the new
backend.repo slug, the recovery loops issue lookups against the wrong
backend until the user notices. NIT because it requires user error
(re-init-ing without `pack tracker disable`) but the safety-rail is absent.

### Finding 9 — NIT — extension-point-soundness
**File / symbol:** `scripts/pack-tracker.sh::cmd_enable_recommendations`
**Contract source:** ARCHITECTURE-V3.md §28.1.6 + V2 §22.1 row.
**Observation:** Verb stub returns `not-implemented` typed error. V2 §22.1
lists `pack tracker enable-recommendations` as required for v11.0. The
verb is wired into the dispatcher; the implementation belongs to BD-073.
Treating as NIT because the verb's plan-time scope is BD-073 not v11.0
core, and the BACKLOG entry is open. Surfaced because a literal reading
of V2 §22.1 ("Required for v11?") expects the verb to function.

### Finding 10 — NIT — test-coverage-gap
**File / symbol:** none (gap, not a defect in code under review)
**Contract source:** ARCHITECTURE.md §3.2 (mode detection) and the BLOCKER
under Finding 1.
**Observation:** No test in the 11-suite set asserts that, after a successful
`tracker_init_run` invocation, `tracker_mode($cfg_path)` returns "tracker".
Every fixture writes `forward_complete = true` directly. An end-to-end
test of `init → forward → tracker_mode` would have failed at HEAD and
caught Finding 1.

---

## Per-BD verification matrix

| BD | Subject | Contract sections checked | Status | Findings against this BD |
|----|---------|---------------------------|--------|--------------------------|
| BD-060 | TrackerProvider abstraction + GH backend | V1 §2.1, §2.2, §2.3, §2.4, §2.5, §2.6, §2.7.1, §2.7.2, §2.7.3, §2.7.4 | GREEN | none |
| BD-061 | tracker.toml schema + detection + .gitignore | V1 §3.1, §3.2, §3.4 | YELLOW | F1 (forward_complete never flips); F3 (3 of 11 Python error sites are in tracker-config.sh) |
| BD-062 | Trinity Document locations Source column (D-6) | V1 §3.3; D-6 footnote | GREEN | none |
| BD-063 | Issue forms work-item + inbound + config | V2 §4.1–§4.3, V3.3 §6.1, V3 §27.1 (form labels) | GREEN | none |
| BD-064 | Template-archive bootstrap + schemas | V2 §19.4, V3.3 §6.5 | GREEN | none |
| BD-065 | Forward migration + 11 steps + idempotency | V1 §6.2, §6.3, §6.4, V2 §6.2 addendum | YELLOW | F1 (root cause: step 11 omits forward_complete flip); F8 (mapping freshness implicit) |
| BD-066 | pack tracker init + label ensure + status verb | V1 §6.1, V2 §22.1, V3 §27.1 | GREEN | none |
| BD-067 | Reverse migration + sidecar + doctor verb | V1 §6.5, §6.6, §6.6.1, V3.1-DELTA §A2, V2 §22.1 | YELLOW | F4 (doctor missing capability re-probe); F5 (Type round-trip text divergence); F6 (mapping vs labels source choice) |
| BD-068 | Round-trip test + multi-template-version stubs | V1 §6.7, §6.6.1, V3.3 §4.4 | GREEN | none |
| BD-069 | template_version dual carrier + update-templates | V2 §19, V2 §26, D-18, V3.3 §6.5 | GREEN | none |
| BD-070 | Typed-error formatter | V1 §2.5, §9.1–§9.7, V3 §27.1 Layer 2 | YELLOW | F3 (Python sites bypass); F7 (undocumented 11th code) |
| BD-071 | Agent read-pattern adaptation | V1 §8.1, §8.3, §8.4, §8.5, D-9 | YELLOW | F2 (3 of 5 prompts not adapted) |

GREEN = no finding directed at this BD. YELLOW = at least one finding traces
to this BD. RED would mean a contract is fundamentally not implemented; no
BD reaches RED.

---

## Extension-point soundness (BD-072 / BD-074 / BD-089 / BD-106 / BD-108 / BD-111)

**BD-072 / `pack tracker enable-recommendations` + threshold-driven Layer 3.**
The verb is wired (`cmd_enable_recommendations`) and emits a typed
`not-implemented` error; BD-073 owns the implementation. The recommendation
state file is contracted at `.pack-tracker/recommendation-state.json`
(V3 §27.3 / §28.1.6) and the path lives under the `.pack-tracker/` directory
that is already gitignored at both surfaces. No surface change blocks this BD.

**BD-074 / pack-help / HELP-FRAGMENT.** No file is in scope at HEAD; the
HELP-FRAGMENT.md path under `project-template/docs/pack/` already exists
in v10 form. V2 §23.2 / §23.3 expand it; the surface is open. The pack-side
mirror path is new (HELP-FRAGMENT-PACK.md) but not yet present. No
extension-point conflict.

**BD-089 / Linear backend.** The dispatcher in `tracker-provider.sh` requires
adding one case to the switch and one `tracker-provider-linear.sh` lib (V2
§20.1 layout). The capability declaration shape is contracted (V1 §2.3) and
the GH backend is the reference implementation. The provider-test stub
backend in `scripts/tests/tracker-provider-test.sh` proves the dispatcher
seam works for non-github backends. Extension-point sound.

**BD-106 / Phase task entity.** Forward migration's body composer
(`tmf_compose_issue_body`) handles `phase-*` pack-ids with the right
template-version comment. The label canonical set already includes
`phase-task` and `template:phase-task-v11.0`. The form has the
`phase-task-skeleton` wi-type option. The sidecar has a hook
(`_tmsc_extra_fields_for_entry`) for additive fields. The deferred
parser/emitter is named in the BD-065 / BD-067 lib comments
("Phase-task parsing... deferred to BD-106 + BD-108 per Addendum 4 §2.3").
Extension surface is in place.

**BD-108 / Cross-entity dependencies.** The provider exposes `provider_link`
(V1 §2.4 reserved kinds + open-string family). The forward step 7 already
emits `blocked-by` for `BD-*` / `TD-*` references in Blockers; the additive
edges (phase-task ↔ phase-task, phase-task ↔ TD/BD) compose with the same
`provider.link()` shape per V3.3 §5.2. The BD-068 round-trip test labels
the BD-111 comment-fallback gap explicitly. Extension surface is in place.

**BD-111 / first-class GH dependency mutation.** The GH backend's
`tracker_provider_gh_link` documents the comment-based fallback explicitly
(line 463–467 comment: "fallback to comment-based marker which the
tracker-mode merge agent already understands per V3 §28"). Switching to
the GraphQL mutation requires editing one helper. The roundtrip test
(`scripts/tests/tracker-migrate-roundtrip-test.sh` lines 302–322) auto-
flips its assertion from gap-documented to passing when blocker round-trip
succeeds. Extension surface is sound.

---

## Closing line

NO-GO — Finding 1 (`forward_complete` is never flipped to true after a
successful forward run) blocks v11.0 release: every project that runs
`pack tracker init` end-to-end remains in flat-file mode by `tracker_mode()`,
which defeats the entire opt-in detection contract (V1 §3.2 / D-5). Address
Finding 1 (and ideally F2 / F3 / F4 alongside, since they are small) before
the next BD lands or v11.0 ships.
