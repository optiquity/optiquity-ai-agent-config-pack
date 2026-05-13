# TOUCH-POINT-INVENTORY-PER-ENTRY-ADDENDUM.md

Addendum to `TOUCH-POINT-INVENTORY-PER-ENTRY.md` (2026-05-12). Resolves
clarifications raised by Pack Chat and surfaces additional ambiguities
noticed during the original walk. Read-only; cite file:line throughout.

---

## Clarification 1 — `project-template/.github/ISSUE_TEMPLATE/` directory

**Resolution:** Case (a). The directory exists at HEAD; the original
§10 observation 3 was stale (likely caused by the depth limit on the
initial `find` walk during the original pass).

**Evidence at HEAD:**

- `find /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev -name ISSUE_TEMPLATE -type d` returns four directories:
  - `./.github/ISSUE_TEMPLATE` (pack root — already inventoried)
  - `./project-template/.github/ISSUE_TEMPLATE` (client template mirror — present at HEAD)
  - `./test-fixtures/v11-flat-file/.github/ISSUE_TEMPLATE` (test fixture)
  - `./test-fixtures/v11-tracker-on/.github/ISSUE_TEMPLATE` (test fixture)
- `scripts/validate-pack.py:941-942` Check 19 iterates both pack and
  project-template locations: `("pack-root", REPO_ROOT / ".github" / "ISSUE_TEMPLATE")` and `("project-template", REPO_ROOT / "project-template" / ".github" / "ISSUE_TEMPLATE")`. The check would fail at HEAD if the project-template directory were absent.
- `scripts/validate-pack.py:1055-1056` Check 20 (`check_template_archive_v11()`) also iterates both locations.
- `scripts/init-project.sh:815-822` Stage S11-equivalent copies forms from `$PACK/project-template/.github/ISSUE_TEMPLATE/*.yml` to `$TARGET/.github/ISSUE_TEMPLATE/$name`. Guarded by `if [[ -d "$PACK/project-template/.github/ISSUE_TEMPLATE" ]]`.
- `scripts/init-project.sh:966-968` lists `project-template/.github/ISSUE_TEMPLATE/{work-item,inbound,config}.yml` as `:generic` copies into `.github/ISSUE_TEMPLATE/` at the client target.
- `scripts/migrate-v10-to-v11.sh:292-301` does the same in stage S2 / S3 / S? — sources from `$PACK/project-template/.github/ISSUE_TEMPLATE` to `$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE`.
- `scripts/pack-tracker.sh:243-245` resolves `live_template_dir` to `$repo_root/.github/ISSUE_TEMPLATE` for both `pack` and `client` surfaces (same path component, different `repo_root`).
- `BACKLOG.md:81` File/Symbol set for BD-063 lists `project-template/.github/ISSUE_TEMPLATE/` mirrors — confirmed present.

**Conclusion (facts only):** The project-template ISSUE_TEMPLATE
mirror IS checked in as a static directory at
`project-template/.github/ISSUE_TEMPLATE/`. Both `init-project.sh`
and `migrate-v10-to-v11.sh` copy from that static source into
`<client-repo>/.github/ISSUE_TEMPLATE/` at runtime. The original
inventory's §10 observation 3 wording — "either runtime-installed or
planned-but-not-realized" — is incorrect; the directory is a
checked-in static template at HEAD.

**Implication for §1.H of the original inventory:** The row "`.github/ISSUE_TEMPLATE/work-item.yml`" and its siblings should be read as having parallel client-template mirrors at the corresponding `project-template/.github/ISSUE_TEMPLATE/` paths. The architect should treat the pack-root and project-template ISSUE_TEMPLATE copies as a dual-location surface (analogous to `HELP-FRAGMENT-TRACKER.md`'s pack-vs-template dual-location). validate-pack Checks 19 and 20 already enforce byte-equality / structural-equivalence across both locations.

---

## Clarification 2 — `Optiquity-Inc` → `DShaneNYC` rename post-fix verification

**Active-tree state at HEAD:**

- `grep -rn "Optiquity-Inc" . 2>/dev/null | grep -v '^\./\.git/' | grep -v 'maintenance-docs/archive/'` returns zero hits. The active tree is clean.

**Remaining legitimate `Optiquity-Inc` / `Optiquity, Inc.` references (not defects):**

- `LICENSE.md:5,21,63,70` — `Optiquity, Inc.` (with comma — legal entity name, not a GitHub org slug). Not a target of the rename.
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md:165` — `GH_REPO=Optiquity-Inc/example-repo` inside an archived workflow-artifact report. Pre-rename historical record; intentionally not rewritten per the archive-as-history convention.

**Inventory file post-fix state:**

- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PER-ENTRY.md:328` (§2.A Tracker-mode interaction row, pack-side column) now reads `DShaneNYC/optiquity-ai-agent-config-pack` (verified via grep — single hit; zero remaining `Optiquity-Inc` hits in the inventory file).
- §10 observation 2 of the original inventory mentioned `tracker.toml.pack-example:21` `repo = "..."`. At HEAD `tracker.toml.pack-example:21` now reads `repo = "DShaneNYC/optiquity-ai-agent-config-pack"` (verified). The companion `project-template/tracker.toml.project-example:25` retains the placeholder `repo = "your-org/your-project"` — by design (it is a client template).

**Statement:** The original inventory's §2.A row 8 (Tracker-mode interaction, pack-side) and any §10 prose that cited the stale `Optiquity-Inc/` repo slug are now correct under commit `6350337`. Future grep audits should expect the two legitimate residual hits enumerated above (`LICENSE.md` company-name and `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md` historical record).


---

## Clarification 3 — Additional ambiguities surfaced

Items set aside during the original walk that didn't quite fit Section
6's buckets, or where the pack / project / both assignment was
unclear, or where two sources gave non-identical guidance. Stated as
facts with file:line evidence; the architect decides resolution.

### 3.1 — STATUS.md ownership prose differs across rule sites

The METHODOLOGY Part 2 Document table at
`supporting-docs/METHODOLOGY.md:116` lists "Who writes" for STATUS.md
as "PM chat or developer" (two parties). The Part 9 "What agents can
and cannot modify" table at `supporting-docs/METHODOLOGY.md:1321`
lists STATUS.md write permission as "PM chat: Yes — after phase
completion" with all agents at "Never". The
`project-template/docs/pack/PM-CHAT.md:201-203` Behavioral rule says
"You may write to BACKLOG.md, STATUS.md, and deferral comments in
source files — but only after explicit user approval." None of the
three mentions "developer" as a writer except Part 2. **Unclear:**
whether the "developer" writer in Part 2 is current-design or a
holdover from a pre-PM-chat era. The architect must decide whether to
codify "PM chat only" (matching Parts 9 + PM-CHAT) or "PM chat +
developer" (matching Part 2).

### 3.2 — STATUS reads via trinity-resolver; STATUS writes via direct path

Already noted as observation §10 #8 of the original inventory, but
flagged again here because it is rule-relevant for the architect's
Section-6-equivalent. Reads go through the trinity `## Document
locations` resolver (`project-template/skills/pm-startup/SKILL.md:69-87`).
Writes target the flat file directly
(`project-template/docs/pack/prompts/pm-chat.md:127` "BACKLOG.md
and/or STATUS.md only"). **Unclear:** whether this asymmetry is the
intended invariant ("writes always to flat; tracker mirror
regenerates downstream") or a pre-tracker-mode rule that needs
trinity-resolver-symmetric update in tracker mode.

### 3.3 — pack-self vs project for METHODOLOGY hygiene rules

Section 6.A of the original inventory marked most METHODOLOGY hygiene
rules as "both" (pack and project). The pack-repo trinity (`CLAUDE.md`,
`AGENTS.md`, `GEMINI.md` at pack root) does NOT actually reference
METHODOLOGY.md as authoritative — `CLAUDE.md:28-33` "Key files to
read before working on the pack" lists `README.md`, `BACKLOG.md`,
`CHANGELOG.md`, `PACK-CHAT.md`, `PACK-AGENTS.md` — no METHODOLOGY.md.
The pack-repo's own commit/versioning/BD-numbering rules live inline
in `CLAUDE.md:46-89` and the Pack memory section
(`CLAUDE.md:93-190`). **Unclear:** whether METHODOLOGY Part 7
Procedures 1–4 (`supporting-docs/METHODOLOGY.md:1065-1171`) actually
apply to pack-self BD processing, or whether pack-self has its own
parallel procedure inheritance through CLAUDE.md + PACK-CHAT.md +
PACK-AGENTS.md. The architect should declare which document is the
authoritative source for pack-self workflow rules.

### 3.4 — `tracker.toml.example` installed name vs source-tree name

Per `scripts/init-project.sh:805-812` and
`scripts/migrate-v10-to-v11.sh:283-289`, the client install always
produces `tracker.toml.example` (no `-pack-` or `-project-` qualifier)
at the client repo root, sourced from
`project-template/tracker.toml.project-example`. Per BD-135 the
source-tree name uses the `-pack-` / `-project-` qualifier to
disambiguate the two source-tree templates. **Unclear:** the
`scripts/lib/migrator-core.sh:501` v11 customization surface manifest
entry `tracker.toml.example` — does it match the installed name (so
customization-preserve operates on client-side files only) or is it
ambiguous between the two source-tree names? Read of the line at
`scripts/lib/migrator-core.sh:501` shows the bare `tracker.toml.example`. Given the manifest is consumed against the
client target (`_MIGRATOR_TARGET` per migrator-core's adapter
contract), the architect should confirm the manifest is intended to
name client-side filenames only; if so, the documentation comment
above the case statement could note that explicitly.

### 3.5 — `mode.state = "tracker"` is only effective when `migration.forward_complete = true`

Per `tracker.toml.pack-example:54-56` and the parallel
`project-template/tracker.toml.project-example:58-61`:
"Set true once forward migration to tracker is complete. Until then,
`tracker_mode()` returns 'flat-file' even when state = 'tracker'."
This is a two-flag effective-mode gate, not a single boolean.
**Unclear:** which code path implements the gate (the `tracker_mode()`
resolver in `scripts/lib/tracker-config.sh` is the implied home, but
the original walk did not verify which function name carries the
gate). The architect must cite the exact resolver function when
documenting the effective-mode rule.

### 3.6 — Recommendation signal documentation drift

Original inventory §10 observation 9 noted that CHANGELOG.md:32-33
describes "Pack-side 3 signals + client-side 6 signals" while the
live code at `scripts/lib/recommendation.sh:141-142` emits 4 pack
signals (`bd_count_active`, `bd_count_total`, `backlog_kb`,
`backlog_growth_30d`) and `:173-174` emits 7 client signals (the 6
the CHANGELOG names plus `td_count_total` as a separate field from
`td_count_active`). **Unclear:** whether the prose "3 / 6" was meant
to count "primary signals fed to the should-recommend test" (with
total / active treated as one logical signal each), or whether the
prose is straight count-drift. The architect should reconcile when
documenting the recommendation surface in any per-entry-shape impact
analysis.

### 3.7 — Pack-feedback-* in-category enum has 5 sub-values; corresponding pack-feedback file is project-only

`.github/ISSUE_TEMPLATE/inbound.yml:23-27` defines 5
`pack-feedback-*` in-category values. The pack-feedback running doc
lives at `docs/pack/PACK-FEEDBACK.md` per
`supporting-docs/METHODOLOGY.md:1382-1393` Part 10 — project-only.
**Unclear:** whether pack-feedback-* inbound issues filed against
the pack repo itself are intended to be the pack's read-side of the
project-PACK-FEEDBACK.md → pack ingestion flow (i.e., the bridge
between the project's append-only `PACK-FEEDBACK.md` and the pack's
inbound triage queue), or whether pack-feedback-* is a separate
inbound surface unrelated to PACK-FEEDBACK.md. METHODOLOGY Part 10
describes batch delivery at workflow boundaries
(`supporting-docs/METHODOLOGY.md:1367`) but does not name a
mechanical delivery target. The architect should declare how the
five `pack-feedback-*` in-category values relate to the
PACK-FEEDBACK.md schema (or that they are decoupled by design).

### 3.8 — BACKLOG.md prose-line inheritance of TD-NNN schema across BD-NNN prefix

`BACKLOG.md:5` reads "Format follows the standard BACKLOG item format
from METHODOLOGY.md Part 7." METHODOLOGY Part 7 BACKLOG item format
at `supporting-docs/METHODOLOGY.md:1030-1047` uses `TD-NNN` in the
schema header (`**TD-NNN — [Short title]**`) and TD-NNN throughout.
Pack-self entries at `BACKLOG.md:33-…` use `BD-NNN` headers. The
inheritance is implicit — the BD-vs-TD substitution lives in prose
at `BACKLOG.md:4` ("Items use BD-NNN identifiers (pack backlog)
rather than TD-NNN (project backlog)"). **Unclear:** whether the
METHODOLOGY schema is canonical (and the BD-vs-TD substitution is a
namespace projection), or whether pack-self has its own schema that
happens to mirror METHODOLOGY's. The architect should pick one and
codify.

### 3.9 — `## Active — v11 Scope` partitioning is not a documented rule

`BACKLOG.md:23` ("## Active — v11 Scope") and `:1941` ("## Active —
v10 Scope") partition active entries by major-version scope. The
"How to use this file" preamble at `BACKLOG.md:9-19` does not
mention this partitioning. METHODOLOGY Part 7 does not mention it.
**Unclear:** whether the version-scope partitioning is a documented
convention (the architect should locate it) or an organic accretion
that should be codified by the per-entry-shape pass. The
`## Resolved — v8 (March 2026)` section at `:2214` is the only
historical Resolved section, retained as transitional per the
pack-memory rule `CLAUDE.md:157-159`.

### 3.10 — `Type: TODO(version)` is the universal pack-self entry type

Every sampled BD entry at `BACKLOG.md:34, 49, 63, 77, 92, 106, 121,
134, 148, 162, …` has `Type: TODO(version)`. METHODOLOGY Part 7
"Valid scope values for TODO" includes `version` as one of five
(`supporting-docs/METHODOLOGY.md:1010-1012`), so this is schema-
conformant. **Unclear (a question for architect-time, not a
defect):** whether the pack-self BD population's monoculture of
`TODO(version)` reflects intentional design (all pack work is
version-scoped) or whether it indicates that other Type values
(`KNOWN GAP`, `VERIFY`) are reserved for client-side TD entries and
pack-self never uses them in practice. If the latter, the per-entry
shape can simplify the pack-self entry schema accordingly.

### 3.11 — pack-coder agent rule "No BD status flips" is duplicative with `CLAUDE.md` pack-memory implicit-flip rule

`.claude/agents/pack-coder.md:38` says "No BD status flips. BACKLOG.md
`Status:` flips happen post-review." `CLAUDE.md:115-117` Pack
memory § Workflow says "Implicit BD status flip on batch completion.
When a batch's review + fixes are clean and tests are green, flip
its BDs to `Resolved` as the final step of the batch — no separate
user approval needed." The pack-coder rule disallows the coder from
flipping; the pack-memory rule sanctions Pack-Chat flipping at batch
completion without separate approval. **Unclear:** the boundary
between the two — specifically, who runs the "flip step" when
pack-coder's working-tree edits already include a BACKLOG.md status
flip (e.g., from the coder anticipating the implicit-flip rule). The
agent file is authoritative per
`project-template/docs/pack/PM-CHAT.md:262-267` ("The agent file is
authoritative; this section is the PM-chat-facing reinforcement").
The architect should resolve whether pack-coder is permitted to
include status-flip edits in its working-tree output, or whether the
flip is exclusively a Pack-Chat post-commit edit.

### 3.12 — `agent-run.sh` is project-only; pack agents use direct CLI invocation

Per `CLAUDE.md:121-125` Pack memory § Agent invocation rules: "Pack
agents are invoked via `claude --agent pack-<name>` (separate
session) or via the Agent tool with `subagent_type=pack-<name>`. The
pack repo has no `agent-run.sh` — that's a project template helper,
not a pack invocation method." Confirmed by directory walk:
`agent-run.sh` exists at `project-template/agent-run.sh` (referenced
by `project-template/AGENTS.md:215, 358`) but not at pack root.
**Not a defect or ambiguity per se** — flagged here because the
architect's stream-relevant agent-invocation references should not
assume `agent-run.sh` exists on the pack side. Per-CLI `agent-run.sh`
flag profiles for read-only / write-capable agents
(`project-template/docs/pack/PM-CHAT.md:313-360`) apply project-side
only.

### 3.13 — `pack-feedback-*` inbound issues vs BACKLOG.md inbound section

The original inventory's §1.A pack-self BACKLOG.md row lists
sections `## Active — v11 Scope`, `## Active — v10 Scope`, `##
Resolved — v8`, `## Deferred`. No `## Inbound` section is documented.
`.github/ISSUE_TEMPLATE/inbound.yml` routes inbound issues but
inbound.yml has no documented down-stream into BACKLOG.md (vs.
work-item.yml's clear "Pack-development backlog item" lineage).
**Unclear:** whether inbound issues flow into BACKLOG.md via a
triage step (PM-chat-side review), into PACK-FEEDBACK.md (the
project-feedback ingestion path), or stay only as GitHub Issues
state with no flat-file landing. The architect should declare the
inbound → BACKLOG lineage if one is intended.

### 3.14 — `recommendation_state.json` schema check (BD-079) is in code but the BD entry is carried-over Open

CHANGELOG.md:93 lists BD-079 ("validate-pack recommendation-state
schema check") as one of the "v11-Active BDs Open at v11.0 cut" /
carried-over items. However, `scripts/validate-pack.py:2304-2393`
defines `check_recommendation_state_schema()` and `main()` at
`:2579-…` invokes it at HEAD. **Unclear:** whether the BD is in
fact resolved and the CHANGELOG carry-over list is stale, or whether
the function is a partial implementation that does not meet BD-079's
DoD. The architect should not assume CHANGELOG accuracy for BD-079
without reading the BACKLOG entry directly.

### 3.15 — `check_tracker_config` (BD-078) similarly listed as carried-over but present in code

CHANGELOG.md:92 lists BD-078 ("validate-pack check_tracker_config")
as carried-over Open. `scripts/validate-pack.py:2266-2302` defines
`check_tracker_config()` and `main()` invokes it at HEAD. Same
ambiguity as 3.14 above — Status mismatch between CHANGELOG carry-over
list and live code. The architect should consult BACKLOG.md for
BD-078's actual Status field.


---

TOUCH-POINT-INVENTORY-ADDENDUM-COMPLETE: 2026-05-12 — Clarification 1 resolves that `project-template/.github/ISSUE_TEMPLATE/` is a checked-in static directory (not runtime-only) with full file:line evidence; Clarification 2 confirms zero remaining `Optiquity-Inc` defects in the active tree post-commit `6350337`; Clarification 3 surfaces 15 additional ambiguities the architect should resolve (STATUS ownership prose drift, METHODOLOGY applicability to pack-self, tracker.toml.example installed-vs-source name, two-flag effective-mode gate, recommendation signal count drift, pack-feedback-* inbound lineage, BD-078/BD-079 status drift, and 8 others).
