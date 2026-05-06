# PACK-REVIEW — BD-066 / BD-067 / BD-068

**Verdict:** GO-WITH-FIXES.

The trio lands the V1 §6.1 wrapper, V1 §6.5/§6.6/§6.6.1 reverse path,
and the V1 §6.7 round-trip property test in coherent shape. Tests are
real, the stateful fake-gh harness is the right design, the F→R→F
byte-equivalent assertion is meaningful, and the BD-065 review's
fix-list (regex newline, mapping persist, mirror-only, status surface)
landed. BD-069 can compose on top.

The fixes flagged below are correctness gaps and contract divergences,
not blockers for BD-069 specifically — but several should be addressed
in BD-069's commit window because BD-069 reads and reconciles the
same carriers BD-066/067/068 wrote. One blocker is a hard-coded
`v11.0` literal in the sidecar's `template_archive_path` that BD-069
will need to read; landing BD-069 without removing the literal will
emit broken paths for v11.x entries.

---

## Findings

### Finding #1 — `tracker_init_run` does not create issue templates; only verifies presence
**Severity:** WARNING
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-init.sh:_tracker_init_verify_templates`
**Contract source:** ARCHITECTURE.md §6.1 step 3.
**Observation:** V1 §6.1 step 3 says `pack tracker init` performs
"Create issue templates (`.github/ISSUE_TEMPLATE/*.yml`) and the
labels". The implementation only verifies that work-item.yml /
inbound.yml / config.yml are present in the working copy and emits a
`not-found` typed error otherwise (with a comment "BD-063 ships them;
init only confirms they are present"). Init creates labels (step 4)
but never creates templates. A user who runs `pack tracker init` on
a clean working copy that has not yet pulled BD-063's templates will
see a not-found error from init; spec says init should create the
templates itself.

---

### Finding #2 — Reverse / status / doctor / mirror-rebuild hard-code surface=pack
**Severity:** WARNING
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:tracker_migrate_reverse_run`,
`scripts/lib/tracker-migrate-forward.sh:tracker_migrate_status_report`,
`scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run`,
`scripts/tracker-migrate.sh:tracker_doctor_run`
**Contract source:** ARCHITECTURE.md §3.4 (independence axes); BD-066's
own `tracker_init_run` accepts `--surface pack|client` and routes the
config path to `<root>/tracker.toml` vs `<root>/docs/pack/tracker.toml`.
**Observation:** Every other entry point hard-codes
`tracker_config_resolve_path pack "$repo_root"`, so on a client repo
they will look at `<root>/tracker.toml` (which does not exist) instead
of `<root>/docs/pack/tracker.toml` (which does). BD-066's `init` is
surface-aware; `status`, `mirror-rebuild`, `disable` (which is the
reverse path), and `doctor` are not. All four wrappers exposed in the
V2 §22.1 verb table become pack-only at v11.0.

---

### Finding #3 — `pack tracker disable` is not atomic with respect to mode flip
**Severity:** WARNING
**Category:** disable-flow-correctness
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:tracker_migrate_reverse_run`
(steps 4–9), `_tmr_update_tracker_toml`
**Contract source:** ARCHITECTURE.md §6.5 step 9 + §6.0 bidirectionality.
**Observation:** The `disable` flow is an ordered sequence: emit flat
files (steps 4–7) → emit sidecar (7.5) → strip mirror header (8) →
update tracker.toml + flip mode (9). BACKLOG.md / STATUS.md /
CHANGELOG.md are overwritten unconditionally in step 4 (no backup /
no rename / no atomic-write). If any python3 heredoc in steps 4–8
fails (file system error, parse error from a malformed body), the
function returns early with `set -e` and tracker.toml is never updated;
the working copy is left with: (a) flat files in post-reverse shape
without mirror headers, (b) tracker.toml still saying
`mode.state = "tracker"`. The next `pack tracker status` reports
"no mirror header" but the user's mode says tracker. There is no
recovery handler that detects this split state.

---

### Finding #4 — `_tmr_decode_status` ignores the canonical Issue `state` / `stateReason` fields
**Severity:** WARNING
**Category:** round-trip / contract-divergence
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:_tmr_decode_status`
**Contract source:** ARCHITECTURE-V3.3-DELTA.md §6.3 (state mapping
per entity type — "closed + state_reason: completed + status:resolved");
ARCHITECTURE.md §2.2 canonical Issue shape.
**Observation:** The decoder reads the labels array and ignores the
`state` and `stateReason` fields entirely. V3.3 §6.3 names both as
load-bearing for the Resolved/Cancelled/Deprecated rows. Forward
writes both (labels via `_tmf_labels_for_entry` + state via
`provider_close`), so the round-trip case is symmetric. But any
issue closed manually outside the pack (no `status:*` label, only
GH's state=closed) is reverse-decoded as Status: Open. The decoder's
default-to-Open fallback (`*) echo "Open" ;;`) silently misclassifies
this case.

---

### Finding #5 — `tracker_doctor_run` is missing the V2 §22.1 capability-cache refresh check
**Severity:** WARNING
**Category:** contract-divergence
**File:Symbol:** `scripts/tracker-migrate.sh:tracker_doctor_run`
**Contract source:** ARCHITECTURE-V2.md §22.1 (`pack tracker doctor`
verb table row): "Validates `tracker.toml`, **refreshes capability
cache**, validates mirror freshness, validates mapping integrity,
validates template freshness."
**Observation:** Of the five spec checks, doctor implements four
shapes (config schema, mapping integrity via shape + per-entry
pack-id format, mirror via header presence, templates via directory
presence). Capability-cache refresh is not implemented; the function
explicitly says "Capability re-probing is deferred to a future BD."
Mirror "freshness" is checked as header presence only (not mtime
comparison or staleness vs tracker last-update). Template "freshness"
is checked as directory existence (not comparison of in-tree
template_version against entry-label `template:*-vX.Y` set, which
is what BD-069 will need). Three of the five V2 §22.1 sub-checks are
shape-incomplete or missing.

---

### Finding #6 — `tracker_sidecar_emit` hard-codes `v11.0` literal in `template_archive_path`
**Severity:** BLOCKER (for BD-069)
**Category:** BD-069-readiness-gap / extension-point-soundness
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:_tmsc_emit_entry_section`
**Contract source:** ARCHITECTURE.md §6.6.1 (DELTA A2):
"`template_archive_path`: the relative path to the template archive
used to produce this entry, so a re-forward migration can re-hydrate
the v11.x-only fields deterministically."
**Observation:** The path is composed as
`maintenance-docs/v11-research/templates-archive/v11.0/$template_version/SCHEMA.md`.
The `v11.0` segment is a literal. The archive layout under
`maintenance-docs/v11-research/templates-archive/` already shows the
intended shape: `v11.0/bd-v11.0/SCHEMA.md`. When v11.1 ships, the
archive grows `v11.1/bd-v11.1/SCHEMA.md`. With the literal in place,
a v11.1-template entry's sidecar will emit
`templates-archive/v11.0/bd-v11.1/SCHEMA.md` — which does not exist —
and BD-069's re-forward "deterministically re-hydrate" requirement
breaks. The sidecar test only asserts the heading shape, not the
path.

---

### Finding #7 — Sidecar `extra_fields` block is hard-coded "(empty at v11.0)"; no extension seam for BD-069
**Severity:** WARNING
**Category:** extension-point-soundness / BD-069-readiness-gap
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:_tmsc_emit_entry_section`
**Contract source:** ARCHITECTURE-V3.1-DELTA.md §A2 / §6.6.1.
**Observation:** The implementation emits
`echo '(empty at v11.0; v11.x-only fields populate this section)'`
directly. There is no helper hook (e.g. `_tmsc_extra_fields_for_entry
"$pack_id" "$issue"`) that BD-069 can extend. BD-069 will land
template_version dual-carrier reconciliation and the `extra_fields`
emitter together; without an extension point, BD-069 has to rewrite
the section. The test asserts the literal "empty at v11.0" string
(`assert_contains "4.4 sidecar empty extra_fields at v11.0"
"empty at v11.0"`), so any seam refactor will need a parallel test
update.

---

### Finding #8 — Sidecar `reactions`, `attachments`, `audit_log` blocks are placeholders, not contract-conformant
**Severity:** WARNING
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:_tmsc_emit_entry_section`
**Contract source:** ARCHITECTURE.md §6.6 ("the reverse migration
captures what the v10 grammar captures and emits a sidecar file for
everything else: reaction counts, comment thread (with author and
date), attachment URLs, audit log of state changes").
**Observation:** All four V1 §6.6 blocks are emitted as literal
text saying "not implemented at v11.0". The sidecar is thus
structurally present but content-empty for the V1 §6.6 surface.
Inline comments name the missing provider ops (reactions need a
separate `gh api /repos/.../reactions` call; events need
`provider_events` which BD-060 did not ship). The user prompt's
expectation was that v11.0 sidecars would "match the documented field
set" of V1 §6.6 + DELTA A2; v11.0 ships only the section skeletons.
The test (4.4) asserts presence of the section headings but not their
content, so the gap is not failure-detectable from CI.

---

### Finding #9 — `tracker_doctor_run` warning lines are inconsistent with V3 §27.1 Layer-2 verb naming
**Severity:** NIT
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/tracker-migrate.sh:tracker_doctor_run`
**Contract source:** ARCHITECTURE-V3.md §27.1 Layer 2: "Every error
message ends with one unambiguous 'run X to fix' line."
**Observation:** Of doctor's five `[WARN]` lines, only one names a
recovery verb: `[WARN] .github/ISSUE_TEMPLATE absent (run \`pack
tracker init\`)`. The other four (`tracker.toml absent`,
`tracker.toml schema_version unsupported`, `mapping file is
malformed JSON`, `mapping has malformed pack-ids`) name the issue
but not the recovery verb. The Layer-2 contract is per-error.

---

### Finding #10 — Reverse blocker decode does not match what forward writes (BD-111 gap is documented but cross-BD asymmetric)
**Severity:** WARNING
**Category:** round-trip
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:_tmr_decode_blockers` vs
`scripts/lib/tracker-provider-gh.sh:tracker_provider_gh_link` (kind=blocked-by branch)
**Contract source:** ARCHITECTURE.md §6.7 round-trip safety; BACKLOG.md
BD-111.
**Observation:** Forward step 7 calls
`provider_link "$gh_id" "$other_gh_id" "blocked-by"`, which (per
BD-060's GH backend) writes a separate **issue comment**
`Blocked by #$other_id` on the source issue. Reverse's
`_tmr_decode_blockers` reads only the issue **body** (not comments)
for the marker pattern. The two never meet. BD-068's round-trip
test documents this gap and auto-flips when BD-111 lands; the test
assertion is correct. The cross-BD finding: the asymmetry is between
forward's link writer (BD-060/065 path) and reverse's link reader
(BD-067 path). Either side could be the "true" carrier; the design
needs to pick one. The current state is that reverse's decoder
expects body markers but forward's writer never emits them.

---

### Finding #11 — Forward writes a body comment for `blocked-by` only via a separate `tracker_provider_gh_comment` call; reverse cannot find the marker even after the v11.0 fallback path
**Severity:** WARNING
**Category:** round-trip / extension-point-soundness
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:_tmr_decode_blockers` regex
**Contract source:** ARCHITECTURE.md §6.0 bidirectionality contract.
**Observation:** The regex
`(?:Blocked by|blocked-by|blocks)[\s:]*#(\d+)` would match a
"Blocked by #N" string in the issue body if it were ever written
there. Forward never writes it to body — only to a separate comment.
A future BD that adds in-body inline blocker markers (e.g., to satisfy
the round-trip property without waiting for BD-111's GraphQL mutation)
is a viable shape; the regex is forward-compatible. NIT for
documentation: the regex's `blocks` alternation matches on lowercase,
but `tracker_provider_gh_link` writes "Blocks #N" with leading capital
B — the regex `blocks` only catches the lowercase form (and is
shadowed by `Blocked by` precedence in any case).

---

### Finding #12 — Sidecar date in filename is not stable across multi-call runs
**Severity:** NIT
**Category:** idempotency
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:tracker_sidecar_emit`
**Contract source:** ARCHITECTURE.md §6.7 round-trip safety
("byte-equivalent on tracker side").
**Observation:** Sidecar path is
`.pack-tracker/reverse.sidecar.$(date -u '+%Y-%m-%d').md`. Two reverse
runs straddling UTC midnight emit two different sidecar files. The
older one is not cleaned up. Round-trip property is unaffected (the
file isn't read by forward at v11.0), but disk state grows. Tests
do not exercise this edge.

---

### Finding #13 — `_tmr_emit_*` helpers embed jq-emitted JSON inside python3 triple-quoted heredocs without escape guarding
**Severity:** NIT
**Category:** correctness
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:_tmr_emit_backlog`,
`_tmr_emit_implementation_plan`, `_tmr_emit_status`
**Contract source:** ARCHITECTURE.md §6.0 bidirectionality contract
(v10-grammar content equivalence).
**Observation:** Each emitter uses the pattern
`entries = json.loads("""$entries""")`. The `$entries` JSON comes from
jq, which escapes quotes as `\"` — but a description containing the
literal sequence `"""` (three consecutive escaped quotes in JSON,
i.e. `\"\"\"`) embeds inside the python triple-quoted string and
terminates it early, producing a SyntaxError. The same shell
substitution into a triple-quoted block recurs across three emitters.
Real-world frequency is low; but the contract says "Type:
TODO(version)" must round-trip every v10-grammar field, including
description text with arbitrary quotes. A user description like
`"""quoted block"""` would crash reverse.

---

### Finding #14 — Round-trip test fixture's BD-002 blocker assertion documents the BD-111 gap but does not exercise the v11.0+ path through forward step 7 idempotency
**Severity:** NIT
**Category:** round-trip
**File:Symbol:** `scripts/tests/tracker-migrate-roundtrip-test.sh` (group 2.2 "BD-002 Blockers gap documented")
**Contract source:** ARCHITECTURE.md §6.7 + BD-111.
**Observation:** The test correctly documents that BD-002's Blockers
field decodes to None on reverse (not BD-001) because forward's
comment-marker write doesn't appear in body. The gap is real and
auto-flips when BD-111 lands. What the test does NOT exercise: the
F→R→F **second** forward step 7. After reverse, BD-002's parsed
blockers list is empty (`Blockers: None`), so the second forward
emits zero `provider_link` calls for BD-002. This means the second
forward's create_log signature matches the first's — but only because
both signatures exclude link emissions (the create_log only logs
`issue create`, not `issue comment`). The test passes for a reason
the test does not assert. When BD-111 lands and reverse reads real
dependency edges, the second forward will emit links, and the test
will need a parallel "link signature" comparison alongside the
create signature.

---

### Finding #15 — Stub directory README contract names a JSON file shape (`extra_fields.json`) the round-trip test does not yet read
**Severity:** NIT
**Category:** BD-069-readiness-gap / extension-point-soundness
**File:Symbol:** `scripts/tests/fixtures/roundtrip/bd-v11.1/README.md`
**Contract source:** ARCHITECTURE.md §6.6.1.
**Observation:** The README documents that future v11.1 fixtures will
include `extra_fields.json` ("v11.x-only fields the entry's body
carries"). At v11.0 the round-trip test does not read JSON sidecar
files. BD-069 will land the read path. The README is accurate in
what it tells a future v11.1 author to drop in, but ambiguous about
which BD reads the file (BD-069 vs the round-trip test extension)
and what shape the JSON should take (no schema reference). A future
maintainer landing v11.1 will need to read both BD-069 and BD-068's
test to fill in the fixture.

---

### Finding #16 — Forward's BD-067 mirror-helper refactor preserves byte-stability, but `tracker_mirror_header_write` strip pattern accepts trailing-content drift
**Severity:** NIT
**Category:** idempotency
**File:Symbol:** `scripts/lib/tracker-mirror.sh:tracker_mirror_header_write`,
`tracker_mirror_header_strip`
**Contract source:** ARCHITECTURE.md §6.3 (header shape) + §6.7
(byte-equivalent on tracker side).
**Observation:** The regex `\s*<!--\s*\n.*?\n\s*-->\s*\n+` strips a
leading header + adjacent blank-line gap. Two consecutive header
writes produce byte-equal output modulo the timestamp line — verified
by tests. The strip pattern correctly inverts write. NIT: `\s*` at
the start tolerates leading whitespace **lines** before the header
(because `\s` includes `\n`). If a file ever begins with a blank
line followed by the mirror header, strip removes both; write
re-prepends just the header. The BD-065 review's Finding #7 (newline-
eating regex in `_tmf_update_tracker_toml`) was correctly fixed in
both forward (`[ \t]*` not `\s*`) and reverse `_tmr_update_tracker_toml`
(line 462-471). The mirror-header python regex is a different code
path with `re.DOTALL` and is acceptable for the leading-anchor case.

---

### Finding #17 — `_tracker_init_verify_templates` emits the same template directory for pack and client surfaces
**Severity:** NIT
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/lib/tracker-init.sh:_tracker_init_verify_templates`
**Contract source:** ARCHITECTURE.md §3.4 (independence axes); §3.3
(trinity Document locations).
**Observation:** The function's case statement maps both `pack` and
`client` surfaces to `$repo_root/.github/ISSUE_TEMPLATE`. For pack
this is correct (BD-063 ships templates at the repo root). For
client, the templates live under the project's actual `.github/`
(per V1 §3.3 the client repo's `.github/` lives at the repo root,
not under `docs/pack/`). The two cases are functionally identical
because both are just `<root>/.github/ISSUE_TEMPLATE`. The collapse
is fine, but the case statement carries no surface-specific
information, suggesting either the case is a no-op or a future
client-surface override is intended.

---

### Finding #18 — Reverse's `_tmr_emit_implementation_plan` and `_tmr_emit_changelog` are reverse-only writers; STATUS.md is reverse-overwrite
**Severity:** NIT
**Category:** round-trip
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:_tmr_emit_implementation_plan`,
`_tmr_emit_changelog`, `_tmr_emit_status`
**Contract source:** ARCHITECTURE.md §6.5 step 5–7.
**Observation:** IMPLEMENTATION_PLAN.md and CHANGELOG.md are
"emit only if absent". STATUS.md is "always overwrite". Forward
does not touch any of these three. The asymmetry: a project with a
pre-existing IMPLEMENTATION_PLAN.md keeps it; a project with a
pre-existing STATUS.md gets it overwritten by reverse output. This
is a design choice (STATUS is mostly tracker-derived; PLAN is
authored), but it should be either documented in V1 §6.5 or made
uniform.

---

### Finding #19 — `tracker_labels_ensure` summary line reports `already-present=0` always
**Severity:** NIT
**Category:** correctness
**File:Symbol:** `scripts/lib/tracker-labels.sh:tracker_labels_ensure`
**Contract source:** Self-documenting summary line per V1 §6.1
step 3 ergonomics.
**Observation:** The cat heredoc emits
`already-present=$((missing_count - missing_count))` which is
always 0. The intent appears to be `total_canonical - missing_count`,
i.e. how many of the canonical set were already present. The actual
"already present" count is computed by the loop's first `continue`
(label is in `existing`) but never tallied. Cosmetic; the WARN/fail
paths still surface failed creates correctly.

---

### Finding #20 — V2 §22.1 verb table is fully wired in `pack-tracker.sh` but `update-templates` and `enable-recommendations` emit `validation` typed errors instead of `not-implemented`
**Severity:** NIT
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/pack-tracker.sh:cmd_update_templates`,
`cmd_enable_recommendations`
**Contract source:** ARCHITECTURE.md §2.5 (typed-error shape);
ARCHITECTURE-V3.md §27.1 Layer 2 (verb-naming).
**Observation:** Both unimplemented verbs use `tracker_error_emit
"validation"` to surface "not implemented in this build". `validation`
is an input-shape error code (per V1 §2.5); the deferral is not a
validation problem. A `not-implemented` typed code would be more
honest, and Layer-2 verb-naming would say "Run: pack tracker doctor"
or similar to point the user somewhere useful. Minor.

---

## Verification matrix

| BD | V1 sections checked | V2 / V3 / V3.1 / V3.3 sections | Plan refs | Findings |
|---|---|---|---|---|
| **BD-066** init wrapper | §6.1 (5-step sequence), §7.3 (auth), §3.1 (tracker.toml schema), §3.4 (independence axes) | V2 §22.1 (verb table — init / status / mirror-rebuild rows), V3 §27.1 Layer 2 | Plan §1.3 lines 149–163 | #1, #2, #17 |
| **BD-066** label ensure | §6.1 step 3, §4.1 BD/TD label set | V2 §4.2 / §4.3 (pf-category), V3.3 §6.3 (status family), §6.5 (template-version family D-18) | Plan §1.3 line 154 | #19 |
| **BD-066** verb dispatcher | §6.1 trigger surface | V2 §22.1 (full 9-verb surface), V3 §27.1 Layer 2 | Plan §1.3 line 153 | #20 |
| **BD-067** reverse migration | §6.5 (9 steps), §6.0 bidirectionality, §6.7 round-trip | V3.3 §6.3 (state mapping per entity type), V3.3 §6.4 (identifier scheme) | Plan §1.4 lines 169–187 | #2, #3, #4, #10, #11, #13, #18 |
| **BD-067** sidecar emitter | §6.6 (reactions, comments, attachments, audit_log), §6.6.1 (template_version, extra_fields, template_archive_path) | V3.1 DELTA §A2 (sidecar template-version drift fields), V3.3 §6.5 (D-18 carrier matrix) | Plan §1.4 line 174 | #6, #7, #8, #12 |
| **BD-067** mirror header refactor | §6.3 (read-only header), §6.5 step 8 (strip on reverse), §6.7 (byte-equivalence) | — | Plan §1.4 line 175 | #16 |
| **BD-067** doctor verb | §6.1 doctor mention | V2 §22.1 (doctor verb table row — five sub-checks), V3 §27.1 Layer 2 | Plan §1.4 line 176 | #5, #9 |
| **BD-068** round-trip fixture | §6.7 (round-trip safety), §6.0 (bidirectionality) | V3.1 DELTA §A2 (test extension), V3.3 §6.4 (identifier scheme — multi-template-version readiness) | Plan §1.4 lines 191–206; Addendum 4 §2.5 | #14 |
| **BD-068** stateful fake gh | §2.2 canonical Issue shape | V3.3 §6.3 (state mapping for stub correctness) | Addendum 4 §2.5 | — |
| **BD-068** multi-template-version stubs | §6.6.1 (2-version-skip case readiness) | V3.1 DELTA §A2 (template_version + extra_fields + template_archive_path) | Plan §1.4 line 198 | #15 |

---

## Closing summary

### BD-069 readiness

BD-069 lands `template_version` HTML-comment + label dual carrier
(D-18 / V3.3 §6.5) and the `pack tracker update-templates` verb
(V2 §19.2). What it inherits from BD-066/067/068:

- **Both carriers already written** — forward writes
  `<!-- template_version: bd-v11.0 -->` in body
  (`tmf_compose_issue_body`) and `template:bd-v11.0` in labels
  (`_tmf_labels_for_entry`). BD-069's reconciliation reader can
  diff the two.
- **Reverse reads body comment** — `tracker_sidecar_emit` extracts
  template_version via `<!--\s*template_version:\s*([^\s]+)\s*-->`.
  BD-069 will need to add the parallel label-side reader and the
  reconcile-to-canonical step.
- **Sidecar shape ready** — `extra_fields` block is structurally
  present per entry. BD-069 fills it.
- **Stub directories ready** — `bd-v11.1/`, `bd-v11.2/` in place;
  README contracts the fixture file shape.

What BD-069 must address first (gaps from this review):

1. **Finding #6 (BLOCKER)** — sidecar's `template_archive_path`
   hard-codes `v11.0`. BD-069's "deterministic re-hydrate" requirement
   per §6.6.1 cannot land until the literal is removed. **Must be
   fixed in BD-069's commit window or as a ride-along immediately
   before.**
2. **Finding #7 (WARNING)** — sidecar's `extra_fields` block is a
   hard-coded literal with no helper hook. BD-069's emitter will
   either refactor the `_tmsc_emit_entry_section` shape or land an
   adjacent helper. The existing test asserts the literal string,
   so BD-069's commit must update the test too.
3. **Finding #5 (WARNING)** — doctor's "template freshness" check is
   shape-incomplete; BD-069 will land the actual freshness diff (in-
   tree template_version vs entry-label `template:*-vX.Y` set).
   Doctor will need a parallel update.
4. **Finding #8 (WARNING)** — sidecar's reactions / attachments /
   audit_log placeholders should land their real fetchers as
   ride-along to BD-069 or as separate BDs. Right now they ship
   structurally present but content-empty, which is honest but
   does not satisfy V1 §6.6's "audit log of state changes" contract.

Net BD-069 readiness: **GO with Finding #6 as a hard precondition.**
Findings #5, #7, #8 are quality-of-implementation gaps that BD-069
will touch the same surfaces of; landing them together is cleaner
than leaving them to ride along after.

### Cumulative extension-point soundness

- **BD-072 (recommendation library reads `tracker.toml`).** BD-066's
  `tracker_init_run` writes a complete v11.0-shape tracker.toml with
  schema_version, backend, mode, mirror, id_namespace,
  cli_acceleration, migration sections. BD-072's reader has
  everything it needs. Idempotent re-run preserves opted_in_at /
  opted_in_by. **Soundness: GO.**

- **BD-074 (pack-startup checks tracker mode + freshness).** BD-066's
  `tracker_migrate_status_report` emits the 8-field state
  surface; BD-074 can read this directly. The "freshness" component
  reuses the same per-field strings (mapping_age, mirror_age,
  tmpl_age, last_forward, last_reverse). **Soundness: GO** — but
  BD-074 will inherit Finding #2 (status hard-codes pack surface) if
  it is exposed through pm-startup on the client side.

- **BD-106 (phase-task parser extends BD-065 forward path which
  BD-067 also reads).** BD-067's reverse path has a phase decoder
  branch (`case "$pack_id" in phase-*)`) that handles `phase-N` titles
  but does not handle `phase-N.M` (phase-task identifier per V3.3
  §6.4). The branch will need an additive arm for phase-N.M.
  Forward step 7 link emission likewise has `phase-[0-9]*` token
  matching that does not match `phase-N.M`. BD-106's plan to extend
  these arms (per Addendum 4 §2.4 — BD-067 phase-task extension)
  remains structurally sound: both forward and reverse classifier
  branches admit additional cases without re-architecting.
  **Soundness: GO.**

### Closing line

**GO-WITH-FIXES — the trio is BD-069-ready conditional on resolving
Finding #6 (sidecar hard-coded `v11.0` literal in `template_archive_path`)
in BD-069's commit window. Findings #5, #7, #8 are recommended for
co-landing with BD-069. All other findings (#1–#4, #9–#20) are
correctness or cross-BD-consistency issues that should be tracked as
ride-along fixes through BD-069 / BD-074 / BD-106 windows; none block
BD-069 specifically.**
