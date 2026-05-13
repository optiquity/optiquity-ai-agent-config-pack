# TOUCH-POINT-INVENTORY-PER-ENTRY.md

**Authored by:** pack-docs-researcher (read-only enumeration pass).
**Date:** 2026-05-12 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at authoring:** see `git log -1 --oneline` — 8014186 docs: v11 — flip BD-158 to Resolved + tighten BD-156/157/158 File/Symbol wording.

## Purpose

Comprehensive, read-only enumeration of every file in the pack repo
that touches the four project-management streams (BACKLOG,
IMPLEMENTATION-PLAN, CHANGELOG, STATUS). Produced as a constraint for
the forthcoming pack-architect pass on per-entry / flat-file shape.

Every row in Section 1 must be covered by the architecture doc (cited
by section number) or explicitly deferred with rationale. The
architect cannot redesign past locked decisions, but they must not
skip touch points either. This inventory makes the touch-points
explicit so the architect cannot miss anything.

## Conventions

- Paths are repo-root-relative unless otherwise noted.
- `Scope` is one of `pack` / `project` / `both` (see brief §
  "Pack vs. project boundary").
- `Streams touched` is a comma-separated subset of
  `{backlog, implementation-plan, changelog, status, none}`. `none`
  means the file is structurally relevant but does not currently
  read or write any of the four streams.
- Citations use `path:line`. Some sections gather their evidence into
  a single citation block instead of repeating refs per row.
- The four streams are referred to by the canonical filename even
  when (in v11 client projects) they live under `docs/project/` —
  this inventory traces touch points, not directory layout.
- All file-line citations were verified at the HEAD recorded above.
  Use `git diff` to validate freshness if reading this doc on a
  later commit.

## Section index

1. Section 1 — Touch-point table
2. Section 2 — Pack-vs-client divergence by stream
3. Section 3 — STATUS.md nature verification
4. Section 4 — v11 tracker template / form-family inventory
5. Section 5 — RAG manifest current state and extension surface
6. Section 6 — Operational rules currently embedded outside `_rules.md`
7. Section 7 — Per-CLI surface
8. Section 8 — v10 → v11 migration touch points
9. Section 9 — Setup-path touch points
10. Section 10 — Open observations


---

## Section 1 — Touch-point table

A single flat table of every file that touches the four streams plus
files that are structurally relevant but stream-neutral (e.g., the RAG
manifest declaration host). Rows are grouped under sub-headings for
readability; the heading order has no semantic meaning beyond browsing.

### 1.A — Stream-owned files (pack-self)

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `BACKLOG.md` | pack | stream-owned, defines-rules-for | backlog | high | n/a | 3593 lines, single flat file; BD-NNN prefix per `id_namespace.prefix = "BD"` (`tracker.toml.pack-example:44`); preamble `BACKLOG.md:1-19` includes "How to use this file" embedded rules (`BACKLOG.md:9-19`); sections `## Active — v11 Scope` (`BACKLOG.md:23`), `## Active — v10 Scope` (`BACKLOG.md:1941`), `## Resolved — v8 (March 2026)` (`BACKLOG.md:2214` — historical only; new entries flip Status in place per pack memory rule `CLAUDE.md:157-159`), `## Deferred` (`BACKLOG.md:3423`). Entry format follows METHODOLOGY Part 7 `BACKLOG item format` (`supporting-docs/METHODOLOGY.md:1030-1047`). Every entry currently has Type `TODO(version)` (sampled — BACKLOG.md:34,49,63,…). |
| `CHANGELOG.md` | pack | stream-owned, defines-rules-for | changelog | high | n/a | 733 lines; preamble `CHANGELOG.md:1-6`; version-scoped sections like `## v11 — May 2026` (`CHANGELOG.md:8`), `### v11.0 — Issue-tracker integration + customization-preservation fix` (`CHANGELOG.md:10`). Append-only per METHODOLOGY (`supporting-docs/METHODOLOGY.md:114,125`). No `IMPLEMENTATION-PLAN.md` or `STATUS.md` exists in pack-self at HEAD. |

### 1.B — Stream-owned files (project-template / client surface)

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` § "File access strategy" table | project | defines-rules-for | backlog, status, changelog, implementation-plan | high | n/a (project-only) | `project-template/docs/pack/PM-CHAT.md:117-131` — table specifies "Direct read" / "Direct read (last entry only)" / "Direct read (current phase section only)" for each stream. Single template; not copied to pack-self. |
| `project-template/CLAUDE.md` § "Document locations" table | project | defines-rules-for | backlog, status, changelog, implementation-plan | high | n/a | `project-template/CLAUDE.md:222-226`. `docs/project/` row lists `ARCHITECTURE.md, IMPLEMENTATION-PLAN.md, BACKLOG.md, STATUS.md, CHANGELOG.md` with Source = `flat (or mixed in tracker mode)`. Pack-repo trinity has no `## Document locations` section per BD-062 D-6 footnote (`BACKLOG.md:67-71`). |
| `project-template/AGENTS.md` § "Document locations" table | project | defines-rules-for | backlog, status, changelog, implementation-plan | high | n/a | `project-template/AGENTS.md:205-211` (byte-equivalent to CLAUDE.md per trinity rule). |
| `project-template/GEMINI.md` § "Document locations" table | project | defines-rules-for | backlog, status, changelog, implementation-plan | high | n/a | `project-template/GEMINI.md:217-221` (byte-equivalent to CLAUDE.md per trinity rule). |

### 1.C — Pack-root trinity + roster (key-files lists)

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `CLAUDE.md` (pack root) | pack | defines-rules-for, cross-references | backlog, changelog | medium | n/a | Lists `BACKLOG.md`, `CHANGELOG.md` in "Key files to read before working on the pack" (`CLAUDE.md:28-33`); BD-NNN numbering rule (`CLAUDE.md:60-62`); "What agents may modify" (`CLAUDE.md:64-68`) — `CHANGELOG.md only at version boundaries`; "What agents must never modify without explicit instruction" (`CLAUDE.md:82-86`) — `BACKLOG.md (PM chat only, after user approval)`; Pack memory § "Repo conventions" — `BACKLOG.md has no Resolved section` (`CLAUDE.md:157-159`); commit format `feat: vN — BD-NNN ...` (`CLAUDE.md:46-52`). |
| `AGENTS.md` (pack root) | pack | defines-rules-for, cross-references | backlog, changelog | medium | n/a | Same content as CLAUDE.md per trinity rule. `AGENTS.md:24-25` lists BACKLOG/CHANGELOG; `AGENTS.md:55` BD numbering; `AGENTS.md:61` "CHANGELOG.md only at version boundaries"; `AGENTS.md:77` "BACKLOG.md (PM chat only, after user approval)"; `AGENTS.md:104` "BACKLOG/CHANGELOG entries"; `AGENTS.md:134-138` "BACKLOG.md has no Resolved section". |
| `GEMINI.md` (pack root) | pack | defines-rules-for, cross-references | backlog, changelog | medium | n/a | Same content per trinity rule. `GEMINI.md:19-20` key docs; `GEMINI.md:41` BD numbering; `GEMINI.md:46` CHANGELOG version-boundary rule; `GEMINI.md:50` BACKLOG PM-chat-only; `GEMINI.md:85,112,116` Pack memory rules. |
| `PACK-AGENTS.md` (pack root) | pack | defines-rules-for | backlog, changelog | medium | n/a | "When agents are used vs. pack chat direct" table (`PACK-AGENTS.md:95-105`) reserves "Writing BACKLOG.md entries" and "Writing CHANGELOG.md entries" to Pack Chat only. "PM-only files off-limits to all agents" (`PACK-AGENTS.md:139-142`) lists BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md/AGENTS.md/GEMINI.md. |
| `PACK-CHAT.md` (pack root) | pack | defines-rules-for | backlog, changelog | medium | n/a | Role description (`PACK-CHAT.md:13-16`): "Track open backlog items (BD-NNN format in BACKLOG.md); Maintain CHANGELOG.md and README.md version history". File access strategy table (`PACK-CHAT.md:38-47`) lists direct-read for `BACKLOG.md`, `CHANGELOG.md`, `README.md`. Recommendation routing § (`PACK-CHAT.md:110-135`) describes recommendation-system trigger based on BACKLOG signals. Behavioral rule on commit-staging threshold (`PACK-CHAT.md:90-97`). |

### 1.D — Pack-side help / discovery surface

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `HELP-FRAGMENT-PACK.md` | pack | cross-references | backlog, changelog | low | dual-location (project copy at `project-template/docs/pack/HELP-FRAGMENT.md`) | `HELP-FRAGMENT-PACK.md:40-41` references BACKLOG.md, CHANGELOG.md in pack key files paragraph. |
| `HELP-FRAGMENT-TRACKER.md` | pack | cross-references | backlog | low | byte-identical to `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per BD-077 / validate-pack Check 24 | `HELP-FRAGMENT-TRACKER.md:13` (`pack tracker mirror-rebuild` — refresh BACKLOG.md mirror header); `HELP-FRAGMENT-TRACKER.md:26` ("rebuild the mirror / regenerate BACKLOG.md"). |
| `project-template/docs/pack/HELP-FRAGMENT.md` | project | cross-references | backlog | low | dual-location (pack copy at `HELP-FRAGMENT-PACK.md`) | `project-template/docs/pack/HELP-FRAGMENT.md:32` references `docs/project/BACKLOG.md`. |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | project | cross-references | backlog | low | byte-identical mirror | Same content as pack copy. |
| `scripts/pack-help.sh` | pack | reads-programmatically | backlog | low | n/a (pack-only helper; client uses project-template/docs/pack/HELP-FRAGMENT.md) | `scripts/pack-help.sh:33` — heuristic that classifies the repo by inspecting `BACKLOG.md` for `^**BD-` vs `^**TD-` entry headers. |
| `OPTIONAL-FEATURES.md` | pack | cross-references | backlog | low | n/a (pack-only doc; describes tracker integration that affects both surfaces) | "Tracker integration (v11)" section (`OPTIONAL-FEATURES.md:125-211`) describes tracker as "moves issue tracking out of `BACKLOG.md` flat-file format" (`OPTIONAL-FEATURES.md:133`); recommendation signals reference "BD count, BACKLOG size, 30-day growth" (`OPTIONAL-FEATURES.md:138`); reverse migration "writes a sidecar BACKLOG.md from current issues" (`OPTIONAL-FEATURES.md:180,195`). |


### 1.E — Methodology and project-template procedure docs

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `supporting-docs/METHODOLOGY.md` | project | defines-rules-for | backlog, status, changelog, implementation-plan | high | n/a (pack-authored doc, ships to client via init-project.sh + migrate-v10-to-v11.sh; canonical project tree location is `docs/pack/METHODOLOGY.md`) | The most rule-dense file in the inventory. Part 2 "Standard Project Documents" table (`supporting-docs/METHODOLOGY.md:110-120`) defines all 4 streams + ARCHITECTURE.md + CLAUDE/AGENTS/GEMINI + PACK-FEEDBACK + METHODOLOGY. Part 2 "Document hygiene rules (inviolable)" (`supporting-docs/METHODOLOGY.md:122-138`) — 6 numbered rules covering ARCHITECTURE/IMPLEMENTATION-PLAN truth, CHANGELOG append-only, BACKLOG never-deleted, STATUS update-after-every-phase, agent constraint, deferral-comment / TD-TBD rule. Part 7 in full (`supporting-docs/METHODOLOGY.md:979-1263`): Comment format, BACKLOG item format, Status transitions, Procedure 1 phase gate check (reads BACKLOG.md, IMPLEMENTATION-PLAN.md, STATUS.md, CLAUDE.md), Procedure 2 post-session, Procedure 3 orphan audit, Procedure 4 resolution, Procedure 5 pointers to INSTALL-PROCEDURES.md, Procedure 6 capability addition, Procedure 7 kickoff, Cancelling/Deprecating (`supporting-docs/METHODOLOGY.md:1234-1247`), Agent BACKLOG write permissions table (`supporting-docs/METHODOLOGY.md:1249-1262`). Part 8 warning signs reference BACKLOG/CHANGELOG drift (`supporting-docs/METHODOLOGY.md:1283-1286,1302-1307`). Part 9 § "What agents can and cannot modify" full per-document table (`supporting-docs/METHODOLOGY.md:1313-1325`); Desktop Commander scope (`supporting-docs/METHODOLOGY.md:1327-1344`). Part 10 references PACK-FEEDBACK.md. Appendix § "New Project Checklist" (`supporting-docs/METHODOLOGY.md:1397-1436`) — Day 1 includes "Create BACKLOG.md, STATUS.md, CHANGELOG.md (empty with structure)" (`supporting-docs/METHODOLOGY.md:1408`); pre-phase Procedure 1 (`supporting-docs/METHODOLOGY.md:1418-1420`); post-phase STATUS.md update (`supporting-docs/METHODOLOGY.md:1429`). |
| `supporting-docs/INSTALL-PROCEDURES.md` | project | defines-rules-for | none | medium | n/a (project-installed alongside METHODOLOGY.md per BD-059) | Hosts Procedures 5, 5-C, 5-R, 5-S, 7 (per METHODOLOGY pointer stubs at `supporting-docs/METHODOLOGY.md:1175,1179,1183,1187,1232`). Not directly stream-touching but referenced by stream-related procedures (Procedure 7 kickoff installs the docs that become stream-readers). |
| `supporting-docs/MERGE-STRATEGY.md` | project | cross-references | backlog | low | n/a (project-installed) | Referenced from `PACK-CHAT.md:135` for per-file customization-preservation of `pack tracker init`'s forward migration; from `OPTIONAL-FEATURES.md:204-206` for `customization-detected-needs-reconciliation` disposition; per BD-094 / BD-088. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | project | cross-references | backlog | low | n/a | Per BD-084; user-facing migration narrative. References BD-088 sidecar `docs/pack/PLATFORM-SKILLS.md.v10-customized` per CHANGELOG entry (`CHANGELOG.md:140-141`); Skill-model-changes section is referenced from `CHANGELOG.md:135-142`. |
| `supporting-docs/SETUP-NEW.md` | project | cross-references | implementation-plan | low | n/a | `supporting-docs/SETUP-NEW.md:392` references `IMPLEMENTATION-PLAN.md` ("the architect writes these files as its output"). |
| `supporting-docs/SETUP-EXISTING.md` | project | cross-references | changelog | low | n/a | `supporting-docs/SETUP-EXISTING.md:219` references `Historical CHANGELOG.md entries.` |
| `supporting-docs/CLI-PM-SETUP.md` | project | cross-references | backlog, status, implementation-plan | low | n/a | `supporting-docs/CLI-PM-SETUP.md:119` "phase gate checks, BACKLOG processing, prompt generation"; `supporting-docs/CLI-PM-SETUP.md:146-147` "Read BACKLOG.md, STATUS.md, PLATFORM-SKILLS.md, and the current phase from IMPLEMENTATION-PLAN.md"; `supporting-docs/CLI-PM-SETUP.md:157` "(BACKLOG.md, STATUS.md, PLATFORM-SKILLS.md) to restore accuracy"; `supporting-docs/CLI-PM-SETUP.md:178-179` "Re-paste BACKLOG.md, STATUS.md, and the current phase from IMPLEMENTATION-PLAN.md"; `supporting-docs/CLI-PM-SETUP.md:240` "/pm-startup — re-reads BACKLOG.md, STATUS.md, and other key files". |

### 1.F — Init / migrate scripts and migrator libs

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `scripts/init-project.sh` | project | migrates | none (no direct stream mutation) | medium | n/a (client-side install only) | Searched at HEAD — no direct references to BACKLOG.md/STATUS.md/CHANGELOG.md/IMPLEMENTATION-PLAN.md (grep returned no hits). Streams are created by the developer / PM chat per METHODOLOGY § Appendix Day 1 step "Create BACKLOG.md, STATUS.md, CHANGELOG.md (empty with structure)" (`supporting-docs/METHODOLOGY.md:1408`). Per-entry shape would need to decide whether init-project.sh installs scaffolds or remains stream-mutation-free. |
| `scripts/migrate-v10-to-v11.sh` | project | migrates | implementation-plan | high (per-entry shape forces decision on per-stream layout in client repos) | n/a (client-side migration) | BD-104 cross-pack rename: S4a stage renames client `IMPLEMENTATION_PLAN.md` (underscore) → `IMPLEMENTATION-PLAN.md` (hyphen). See `scripts/migrate-v10-to-v11.sh:151-218`. Stage uses `git mv` with fallback to plain mv (lines 201-211). The conflict-handling case at lines 188-194 fails the stage if both filenames exist. Other streams (BACKLOG.md / STATUS.md / CHANGELOG.md) are not migrated by this script — they are user-owned content. |
| `scripts/lib/migrator-core.sh` | project | migrates | backlog | high | n/a (used by migrate-v10-to-v11.sh and any future migrate-vN-to-vM.sh per BD-119) | `migrator_target_surface_for_version()` (line 471) emits the customization-surface manifest used by BD-088 customization-preserve. Both v10 (line 474-484) and v11 (line 486-506) surfaces list `BACKLOG.md` as a customizable file class. v11 also lists `tracker.toml.example`, `.github/ISSUE_TEMPLATE/work-item.yml`, the per-CLI pack-help skill files, and `docs/pack/HELP-FRAGMENT.md` — but not CHANGELOG.md, STATUS.md, or IMPLEMENTATION-PLAN.md. |
| `scripts/lib/migrator-stages.sh` | project | migrates | none | low | n/a | Searched — no stream filename references. Houses the canonical stage hooks consumed by adapters. |
| `scripts/lib/migrator-manifest.sh` | project | migrates | none | low | n/a | Searched — no stream filename references. |
| `scripts/lib/migrator-skills.sh` | project | migrates | none | none | n/a (BD-147 reusable skill-rename helper) | Out of scope for streams. |
| `scripts/lib/customization-preserve.sh` | project | migrates | backlog (via manifest only) | medium | n/a | Consumes the surface manifest from migrator-core. Per BD-088 / CHANGELOG `CHANGELOG.md:44-51`. The 12 file-class / 8 disposition-token framework treats BACKLOG.md as one of the protected files when both pack and project have edits since baseline. |
| `scripts/lib/detect.sh` | both | reads-programmatically | backlog | medium | n/a (`detect_pack_path()` distinguishes pack vs client by sniffing BACKLOG.md) | `scripts/lib/detect.sh:23-24` comment: "Pack repo: BACKLOG.md at <target>/ with `^\*\*BD-` entries. Client repo: BACKLOG.md at <target>/ OR <target>/docs/project/`". `scripts/lib/detect.sh:35` iterates `"$target/BACKLOG.md" "$target/docs/project/BACKLOG.md"`. This is the heuristic that drives every downstream consumer's pack-vs-client branch. |


### 1.G — Tracker infrastructure (scripts/lib/tracker-*.sh + scripts/{pack-tracker,tracker-migrate}.sh)

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `scripts/pack-tracker.sh` | both | writes (via libs) | backlog, implementation-plan, status, changelog | high | works identically on pack-self and client repos; called from `bash scripts/pack-tracker.sh init/status/doctor/disable` per `OPTIONAL-FEATURES.md:149-153` | Verb dispatcher for `pack tracker init / status / mirror-rebuild / doctor / disable / update-templates`. Per BD-066 / BD-067 / BD-069. |
| `scripts/tracker-migrate.sh` | both | migrates | backlog, implementation-plan | high | works identically on pack-self and client | `scripts/tracker-migrate.sh:51` usage prose: "Migrate flat-file BACKLOG.md / IMPLEMENTATION-PLAN.md content". Subcommands: `forward`, `reverse`, `status`. |
| `scripts/lib/tracker-config.sh` | both | reads-programmatically | none (config-only) | low | n/a | Reads `tracker.toml` to determine mode and mapping-file location. BD-061. |
| `scripts/lib/tracker-provider.sh` | both | mirrors (provider abstraction) | none directly; 18 ops are pure-tracker | low (abstraction layer) | n/a | The 18-operation provider abstraction surface per V1 §2.1; consumed by all tracker libs. BD-060. Includes `raw()` escape hatch. |
| `scripts/lib/tracker-provider-gh.sh` | both | mirrors | none directly | low | n/a | GH backend implementation. BD-060. |
| `scripts/lib/tracker-labels.sh` | both | mirrors | none directly | low | n/a | 45-label canonical set per BD-066. |
| `scripts/lib/tracker-init.sh` | both | writes | backlog, implementation-plan, status, changelog (via downstream forward call) | medium | n/a | `scripts/lib/tracker-init.sh:356-358` references default `[mirror]` `location_backlog = "BACKLOG.md"`, `location_status = "STATUS.md"`, `location_changelog = "CHANGELOG.md"`. Per BD-066. |
| `scripts/lib/tracker-errors.sh` | both | mirrors | none | low | n/a | 10 typed error codes. BD-070. |
| `scripts/lib/tracker-migrate-forward.sh` | both | migrates, writes | backlog, implementation-plan | high (this is the core forward path) | n/a (same library reads pack BD or client TD per id_namespace) | `scripts/lib/tracker-migrate-forward.sh:234` "Parse a v10-shape BACKLOG.md and emit JSON array of entries"; `:266-271` not-found error: "BACKLOG.md not found at $path"; `:391-402` "Parse IMPLEMENTATION-PLAN.md and emit JSON array of phase entries"; `:433` "Compose the issue body for a parsed BACKLOG entry"; `:626-633` `--mirror-only` flag operates on `$repo_root/BACKLOG.md`; `:644-646` 11-step orchestrator reads `BACKLOG.md` at root or `maintenance-docs/IMPLEMENTATION-PLAN.md`; `:659` "forward: parsed $n_entries BACKLOG entries, $n_phases phase(s)"; `:962-975` Step 10 mirror regeneration; `:1083-1096` Step 11 mirror-freshness report; `:1169` regenerate BACKLOG.md mirror in place. BD-065. |
| `scripts/lib/tracker-migrate-reverse.sh` | both | migrates, writes | backlog, implementation-plan, status, changelog | high (writes all 4 stream files from tracker on disable / reverse) | n/a | `scripts/lib/tracker-migrate-reverse.sh:20-34` docstring lists steps 3 (reconstruct v10 BACKLOG record), 4 (emit BACKLOG.md), 5 (emit IMPLEMENTATION-PLAN.md from phase epics), 6 (emit STATUS.md from phase-epic state), 7 (emit CHANGELOG.md skeleton — audit-log walking deferred). `:406-439` BACKLOG.md emitter with header `# BACKLOG`. `:483-513` IMPLEMENTATION-PLAN skeleton emitter. `:513-545` STATUS.md skeleton emitter. `:547-570` CHANGELOG.md skeleton emitter. `:853-856` write paths: `$repo_root/BACKLOG.md`, `IMPLEMENTATION-PLAN.md`, `STATUS.md`, `CHANGELOG.md`. `:871,922` overwrite loops iterate the same 4 filenames. `:881-898` BD-133 header preamble snapshot/restore for BACKLOG.md. BD-067 / BD-133. |
| `scripts/lib/tracker-mirror.sh` | both | writes | backlog | medium | n/a | Mirror-header strip + write helper shared by forward + reverse (per BD-067 resolved note `BACKLOG.md:143`). |
| `scripts/lib/tracker-sidecar.sh` | both | writes (sidecar only) | none (sidecar lives under `.pack-tracker/`) | low (does not touch streams; captures tracker-only data) | n/a | `scripts/lib/tracker-sidecar.sh:1-30` docstring: captures reactions, comments, attachments, audit-log, per-entry template_version, per-entry extra_fields, per-entry template_archive_path. Empty extra_fields at v11.0. Sidecar path: `.pack-tracker/reverse.sidecar.<date>.md`. BD-067 / DELTA A2. |
| `scripts/lib/tracker-doctor.sh` | both | reads-programmatically | backlog | low | n/a | `scripts/lib/tracker-doctor.sh:85-109` (d) mirror-freshness check on `$repo_root/BACKLOG.md` — reads first line, compares mtime against `last_forward_run`, surfaces WARN / OK / INFO. BD-067. |
| `scripts/lib/tracker-header-snapshot.sh` | both | reads-programmatically, writes | backlog | medium | n/a | `scripts/lib/tracker-header-snapshot.sh:1-69` docstring: snapshot BACKLOG.md preamble (everything before first `**BD-` / `**TD-` / entry heading) so reverse-emit preserves user-edited preamble. Round-trip dependency. BD-133. |
| `scripts/lib/tracker-agent-read.sh` | both | reads-programmatically | backlog | medium | n/a | `scripts/lib/tracker-agent-read.sh:7,156-183` — LCD agent read path per V1 §8.1. Flat-file mode greps BACKLOG.md mirror; tracker mode resolves pack-id via mapping file then provider_get. Per BD-071. Direct-executable as `bash scripts/lib/tracker-agent-read.sh BD-001 [<repo>]`. |
| `scripts/lib/template-version.sh` | both | reads-programmatically | none directly (operates on issue bodies + form yamls) | low | n/a | BD-069. Reads `<!-- template_version: ... -->` HTML comment from issue body, label, and form yaml. `scripts/lib/template-version.sh:6,25-35,56-70,78-100,107-135,142-180`. |
| `scripts/lib/template-translations.sh` | both | reads-programmatically | none directly | low | n/a | BD-069. Version-skip resolver + patch rules. |
| `scripts/lib/recommendation.sh` | both | reads-programmatically | backlog, implementation-plan | high (per-entry shape forces decision on signal computation) | pack signals: 3 (`bd_count_active`, `bd_count_total`, `backlog_kb`, `backlog_growth_30d`); client signals: 6+ (`td_count_active`, `td_count_total`, `backlog_kb`, `phase_count`, `implementation_plan_kb`, `td_tbd_comment_count`, `typed_deferral_count`) — `scripts/lib/recommendation.sh:129-175` | `_rec_compute_pack_signals()` `scripts/lib/recommendation.sh:129-143` reads `$repo_root/BACKLOG.md`, counts entries via regex `^\*\*BD-[0-9]+ `. `_rec_compute_client_signals()` `:145-175` reads `$repo_root/BACKLOG.md` or `$repo_root/docs/project/BACKLOG.md`, and `$repo_root/IMPLEMENTATION-PLAN.md` or `$repo_root/docs/project/IMPLEMENTATION-PLAN.md`. `:199` 30-day growth via git log commit count. `:389-396` signal-label map. `:462` "reading BACKLOG.md in full". D-19 / BD-072 / BD-073 / BD-074. |


### 1.H — Tracker config / form-family / template-archive

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `tracker.toml.pack-example` | pack | form-family (config template) | none directly | medium | client copy at `project-template/tracker.toml.project-example`; renamed per BD-135 (filename note: prior name `tracker.toml.example` retained as installed name at client root) | Schema_version 1; `[backend] name = "github"` `tracker.toml.pack-example:18`; `[mode] state = "flat-file"` default `tracker.toml.pack-example:28`; `[mirror] location_backlog = "BACKLOG.md"`, `location_status = "STATUS.md"`, `location_changelog = "CHANGELOG.md"` `tracker.toml.pack-example:37-39`; `[id_namespace] prefix = "BD"` `tracker.toml.pack-example:44`; mapping_file = `.pack-tracker/id-map.json` `tracker.toml.pack-example:63`. |
| `project-template/tracker.toml.project-example` | project | form-family | none directly | medium | byte-different (prefix=TD vs BD; `your-org/your-project` placeholder for repo) | `project-template/tracker.toml.project-example:49` `prefix = "TD"`. Otherwise structurally identical. |
| `.github/ISSUE_TEMPLATE/work-item.yml` | pack | form-family | backlog (entry-shape source), implementation-plan (phase-task / phase-epic skeleton path) | high | client-template mirror is referenced but not present in repo at HEAD — verify by listing | wi-type enum 4 values: `bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton` (`.github/ISSUE_TEMPLATE/work-item.yml:22-26`). wi-kind enum 6 values: `feat`, `fix`, `refactor`, `docs`, `chore`, `infra` (`work-item.yml:34-40`). wi-status enum 9 values: `Open, Unblocked, Pending, In Progress, Resolved, Done, Deferred, Cancelled, Deprecated` (`work-item.yml:48-57`). wi-td-scope 5 values: `phase-N, dependency, feature, perf, version` (`work-item.yml:67-72`). wi-td-severity 3 values: `critical, functional, polish` (`work-item.yml:80-83`). Title prefix `BD-NNN:` (`work-item.yml:3`). Labels prefilled: `work-item`, `needs-triage`, `template:work-item-v11.0` (`work-item.yml:5-7`). HTML-comment carriers: `<!-- pack-id: PENDING -->`, `<!-- template_version: work-item-v11.0 -->`, `<!-- pack-version: v11 -->` (`work-item.yml:175-177`). |
| `.github/ISSUE_TEMPLATE/inbound.yml` | pack | form-family | none directly (lands inbound feedback, not entries) | medium | n/a | in-category enum 7 values: `bug, feature-request, pack-feedback-workflow, pack-feedback-prompt, pack-feedback-agent-perf, pack-feedback-friction, pack-feedback-open-question` (`.github/ISSUE_TEMPLATE/inbound.yml:21-27`). Title prefix `<category>:` (`inbound.yml:3`). Labels prefilled: `inbound`, `needs-triage`, `template:inbound-v11.0` (`inbound.yml:5-7`). HTML-comment carriers same shape as work-item (`inbound.yml:74-76`). |
| `.github/ISSUE_TEMPLATE/config.yml` | pack | form-family | none | low | n/a | `blank_issues_enabled: false` (`config.yml:5`); contact link to Discussions for open-ended questions (`config.yml:6-9`). |
| `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | pack | form-family | none | low | n/a | Bootstrap of P2 maintenance-ergonomics archive per BD-064. |
| `maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md` | pack | form-family | backlog (BD entry schema) | medium | n/a | BD entry archived schema. |
| `maintenance-docs/v11-research/templates-archive/v11.0/td-v11.0/SCHEMA.md` | pack | form-family | backlog (TD entry schema) | medium | n/a | TD entry archived schema. |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md` | pack | form-family | implementation-plan | medium | n/a | Phase epic schema. |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | pack | form-family | implementation-plan | medium | n/a | Phase task schema (added by BD-106 extension per BACKLOG `BACKLOG.md:101`). |
| `maintenance-docs/v11-research/templates-archive/v11.0/inbound-v11.0/SCHEMA.md` | pack | form-family | none | low | n/a | Inbound schema archive. |
| `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` | pack | form-family | backlog, implementation-plan | low | n/a (frozen byte-equal copy of `.github/ISSUE_TEMPLATE/work-item.yml`) | Frozen at v11.0 cut. |
| `maintenance-docs/v11-research/templates-archive/v11.0/forms/inbound.yml` | pack | form-family | none | low | n/a (frozen byte-equal copy) | Frozen at v11.0 cut. |
| `maintenance-docs/v11-research/templates-archive/translations.yaml` | pack | form-family | none | low | n/a | Cross-version translation manifest for BD-069 `update-templates`. |
| `maintenance-docs/v11-research/templates-archive/README.md` | pack | cross-references | none | low | n/a | README explaining the archive. |
| `test-fixtures/v11-flat-file/tracker.toml.example` | pack | form-family (test fixture) | none | none | n/a | Test fixture. |
| `test-fixtures/v11-tracker-on/tracker.toml` | pack | form-family (test fixture) | none | none | n/a | Test fixture. |
| `test-fixtures/v11-tracker-on/tracker.toml.example` | pack | form-family (test fixture) | none | none | n/a | Test fixture. |

### 1.I — validate-pack checks

`scripts/validate-pack.py` is the single Python check runner. Stream-touching
checks below; full file path is `scripts/validate-pack.py`.

| Path / function | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `check_td_tbd_sentinels()` Check 3 | pack | validates | backlog | medium | pack-only (runs on `REPO_ROOT/BACKLOG.md`) | `scripts/validate-pack.py:262-281` — reads `REPO_ROOT/BACKLOG.md` and fails on any line matching `**TD-TBD —` entry header. Note: comment at `:183` clarifies the only meaningful TD-TBD check is "does BACKLOG.md have unprocessed entries". |
| `check_issue_template_forms()` Check 19 | pack | validates | backlog, implementation-plan | high (validates form-family enum values, label set, HTML-comment carriers) | n/a | `scripts/validate-pack.py:908-1011`. Per BD-063. |
| `check_template_archive_v11()` Check 20 | pack | validates | backlog, implementation-plan | medium | n/a | `scripts/validate-pack.py:1012-1086`. Per BD-064. Informational check. |
| `check_tracker_config()` Check 29 | pack | validates | none directly (validates config schema) | medium | validates both pack-example (prefix=BD) and client-example (prefix=TD) | `scripts/validate-pack.py:2266-2302` — wraps `_validate_tracker_toml()` (`:2159-2265`). Validates schema_version, mirror sub-keys (`location_backlog`, `location_status`, `location_changelog` — see `:2224`), `id_namespace.prefix` match. Per BD-078 (recorded as Open in `CHANGELOG.md:92` carry-over). At HEAD the check is present and wired (`:2612`). |
| `check_recommendation_state_schema()` Check 30 | pack | validates | none directly | low | n/a | `scripts/validate-pack.py:2304-2393`. BD-079 (was Open per CHANGELOG `CHANGELOG.md:93`). At HEAD the check is present. |

Note: All listed `check_*` functions also run at `main()` (`scripts/validate-pack.py:2579-…`). The numbering "Check N" used in commit messages and docs reflects historical accretion (Checks 1-31 currently); the actual function-call order is the source of truth.


### 1.J — Project-template agent files (client side)

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `project-template/.claude/agents/coder.md` | project | cross-references (write-prohibition) | backlog, changelog, status | medium | Codex/Gemini mirrors are byte-equivalent in content (different file format) | `project-template/.claude/agents/coder.md:81` — coder must not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`. |
| `project-template/.codex/agents/coder.toml` | project | cross-references | backlog, changelog, status | medium | n/a | TOML mirror of the above. |
| `project-template/.gemini/agents/coder.md` | project | cross-references | backlog, changelog, status | medium | n/a | Markdown mirror. |
| `project-template/.claude/agents/auditor.md` | project | cross-references | backlog | medium | n/a | `project-template/.claude/agents/auditor.md:42` "Append `## Next steps` section listing Critical and Major findings in priority order, cross-referencing the PM chat's BACKLOG processing workflow." |
| `project-template/.codex/agents/auditor.toml` | project | cross-references | backlog | medium | n/a | TOML mirror. |
| `project-template/.gemini/agents/auditor.md` | project | cross-references | backlog | medium | n/a | Markdown mirror. |
| `project-template/.claude/agents/auditor-docs.md` | project | cross-references | changelog | medium | n/a | `project-template/.claude/agents/auditor-docs.md:3,28-29,62` — "CHANGELOG drift" finding category; "CHANGELOG entry claiming a security fix that was not committed is Critical." |
| `project-template/.codex/agents/auditor-docs.toml` | project | cross-references | changelog | medium | n/a | TOML mirror. |
| `project-template/.gemini/agents/auditor-docs.md` | project | cross-references | changelog | medium | n/a | Markdown mirror. |
| `project-template/.claude/agents/repo-ops.md` | project | cross-references | backlog, changelog, status | medium | n/a | `project-template/.claude/agents/repo-ops.md:69-70` "No PM-only file edits. Do not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`". |
| `project-template/.codex/agents/repo-ops.toml` | project | cross-references | backlog, changelog, status | medium | n/a | TOML mirror. |
| `project-template/.gemini/agents/repo-ops.md` | project | cross-references | backlog, changelog, status | medium | n/a | Markdown mirror. |
| `project-template/.claude/agents/{architect,planner,reviewer,tester,docs-researcher,grpc-schema,auditor-architecture,auditor-code,auditor-ops,auditor-security,auditor-tests,auditor-ui}.md` and `.codex`/`.gemini` peers | project | cross-references (read-only by profile) | varies (most reference at least one stream as read-input) | low | n/a | grep returned no direct stream-write references — these are read-only by permission profile per `project-template/docs/pack/PM-CHAT.md:271-289`. Per-prompt stream references are in the prompts (`project-template/docs/pack/prompts/*.md`), not in the agent files. |

### 1.K — Project-template prompt files

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `project-template/docs/pack/prompts/pm-chat.md` | project | writes (PM chat self-prompts) | backlog, status, implementation-plan, changelog | high | n/a | Variant `kickoff` (`:18-96`) lists "ARCHITECTURE.md, IMPLEMENTATION-PLAN.md (current phase), STATUS entries, BACKLOG entries" (`:51-52`); trinity-resolver framing (`:53-58`); "For small doc updates (STATUS.md, BACKLOG.md): use Desktop Commander" (`:69`). Variant `backlog-status-update` (`:98-178`): BACKLOG/STATUS state-change recording; full schema template at `:135-178`; STATUS.md phase-title link rule at `:164-174`. Variant `generate-setup` (`:180-…`). Variant `generate-agent-kickoff` (`:…`). |
| `project-template/docs/pack/prompts/coder.md` | project | cross-references | backlog, changelog, implementation-plan, status | high | n/a | `:14-18` required reading "IMPLEMENTATION-PLAN.md Phase [N] in full"; `:52` "do not write to ARCHITECTURE.md, IMPLEMENTATION-PLAN.md, or BACKLOG.md"; `:62-67` "Root .md file prohibition: Do not write to `CHANGELOG.md`, `STATUS.md`, `BACKLOG.md`, `ARCHITECTURE.md`, `IMPLEMENTATION-PLAN.md`, `CLAUDE.md`, … This restriction applies identically in tracker mode: BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION-PLAN are tracker-mirrored read-only files"; `:81` "Do not write to BACKLOG.md — the PM chat handles that"; `:99-102` "Proposed CHANGELOG entry section in this report"; `:133` second variant required reading "ARCHITECTURE.md in full. IMPLEMENTATION-PLAN.md"; `:169-170` second variant root-md prohibition; `:217-219` "Do not include a Proposed CHANGELOG entry. The PM chat will update the entry … in CHANGELOG.md." |
| `project-template/docs/pack/prompts/reviewer.md` | project | cross-references | backlog, changelog, implementation-plan | high | n/a | `:20-22` required reading: "ARCHITECTURE.md in full. CHANGELOG.md (Phase [X] entry). CLAUDE.md. IMPLEMENTATION-PLAN.md Phase [X] in full. BACKLOG entries (resolve via the trinity `## Document locations` table…)"; `:64,71-73` "BACKLOG and deferral comment hygiene — For each TD-NNN found in reviewed files, confirm a matching BACKLOG entry … in flat-file mode read BACKLOG.md, in tracker mode read the tracker". Per BD-071. |
| `project-template/docs/pack/prompts/architect.md` | project | cross-references | implementation-plan | high | n/a | `:25-35,56` required reading + report shape both reference `IMPLEMENTATION-PLAN.md` and propose-text-changes-to. |
| `project-template/docs/pack/prompts/planner.md` | project | cross-references | implementation-plan | high | n/a | `:16` required reading: "ARCHITECTURE.md in full. IMPLEMENTATION-PLAN.md". |
| `project-template/docs/pack/prompts/tester.md` | project | cross-references | backlog, changelog | medium | n/a | `:17-30,37,56` reference CHANGELOG.md, BACKLOG entries (trinity-resolved), and mapping tests to BACKLOG items. Per BD-071. |
| `project-template/docs/pack/prompts/docs-researcher.md` | project | cross-references | implementation-plan | medium | n/a | `:18` references `IMPLEMENTATION-PLAN.md Phase [N]`. |
| `project-template/docs/pack/prompts/auditor.md` | project | cross-references | backlog, status | medium | n/a | `:42,48-49,93` "cross-referencing METHODOLOGY.md Part 6 BACKLOG processing"; "Read-only audit. Do not write to BACKLOG.md, STATUS.md … In tracker mode the BACKLOG/STATUS mirrors are read-only by design"; "cross-referencing this PM chat's BACKLOG processing workflow". |
| `project-template/docs/pack/prompts/grpc-schema.md` | project | cross-references | (no stream references found) | none | n/a | grep negative result; out of scope. |
| `project-template/docs/pack/prompts/repo-ops.md` | project | cross-references | (no stream references found) | none | n/a | grep negative result. |


### 1.L — Pack-root agent files

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `.claude/agents/pack-architect.md` | pack | cross-references | backlog | medium | n/a | `:27` "BACKLOG.md (open BD items and their constraints)" listed as required-reading. |
| `.codex/agents/pack-architect.toml` | pack | cross-references | backlog | medium | n/a | TOML mirror per trinity rule. |
| `.gemini/agents/pack-architect.md` | pack | cross-references | backlog | medium | n/a | Markdown mirror. |
| `.claude/agents/pack-planner.md` | pack | cross-references | backlog | medium | n/a | `:32` "BACKLOG.md (BD items in scope)". |
| `.codex/agents/pack-planner.toml` | pack | cross-references | backlog | medium | n/a | TOML mirror. |
| `.gemini/agents/pack-planner.md` | pack | cross-references | backlog | medium | n/a | Markdown mirror. |
| `.claude/agents/pack-coder.md` | pack | cross-references (write-prohibition) | backlog, changelog | medium | n/a | `:34` "modify BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md, …" — listed as prohibited surface; `:38` "No BD status flips. BACKLOG.md `Status:` flips happen post-review". |
| `.codex/agents/pack-coder.toml` | pack | cross-references | backlog, changelog | medium | n/a | TOML mirror. |
| `.gemini/agents/pack-coder.md` | pack | cross-references | backlog, changelog | medium | n/a | Markdown mirror. |
| `.claude/agents/pack-reviewer.md` | pack | cross-references | backlog | medium | n/a | `:28-29` "BACKLOG accuracy. If the change resolves or modifies a BD item, verify the BACKLOG entry is updated with the correct status and resolution." |
| `.codex/agents/pack-reviewer.toml` | pack | cross-references | backlog | medium | n/a | TOML mirror. |
| `.gemini/agents/pack-reviewer.md` | pack | cross-references | backlog | medium | n/a | Markdown mirror. |
| `.claude/agents/pack-docs-researcher.md` | pack | cross-references | (no stream references found at grep) | none | n/a | grep negative; this agent's outputs are read-only inventories like the present file. |
| `.codex/agents/pack-docs-researcher.toml` | pack | cross-references | (no) | none | n/a | TOML mirror. |
| `.gemini/agents/pack-docs-researcher.md` | pack | cross-references | (no) | none | n/a | Markdown mirror. |

### 1.M — Pack-root skill files

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `.claude/skills/pack-startup/SKILL.md` | pack | reads-programmatically (instructs the chat to read) | backlog, changelog | high | byte-equivalent content in `.codex/skills/pack-startup/SKILL.md` and `.gemini/commands/pack-startup.toml` per validate-pack per-CLI parity check (Check 28) | `:19-29` Step 2: "Read `BACKLOG.md` in full"; "Read only the most recent dated entry from `CHANGELOG.md`"; "Read the version table section from `README.md`"; "Read `PACK-CHAT.md` in full". `:44-58` Step 4 output template: "**Open backlog items (BD):** [count of Status: Open + Status: Unblocked] / **Last BD number:** BD-NNN". `:70-108` Step 8 inflection-point recommendation (D-19) — sources `scripts/lib/recommendation.sh`, calls `recommendation_compute_signals pack`. |
| `.codex/skills/pack-startup/SKILL.md` | pack | reads-programmatically | backlog, changelog | high | byte-equivalent per BD-076 / Check 28 | Codex mirror of pack-startup. |
| `.gemini/commands/pack-startup.toml` | pack | reads-programmatically | backlog, changelog | high | TOML format; content equivalent per BD-076 | Gemini mirror of pack-startup. |
| `.claude/skills/pack-help/SKILL.md` | pack | cross-references | (no) | none | n/a | `pack-help` skill output mirrors HELP-FRAGMENT-*.md. |
| `.codex/skills/pack-help/SKILL.md` | pack | cross-references | (no) | none | n/a | Codex mirror. |
| `.gemini/commands/pack-help.toml` | pack | cross-references | (no) | none | n/a | Gemini mirror. |
| `.claude/skills/documentation/SKILL.md` | pack | defines-rules-for | changelog | medium | n/a (also exists at `.codex/skills/documentation/SKILL.md`, `project-template/skills/documentation/SKILL.md`) | Pack-side documentation skill rule reads (`project-template/skills/documentation/SKILL.md:41` rule 18 about CHANGELOG drift; pack copy mirrors). |
| `.codex/skills/documentation/SKILL.md` | pack | defines-rules-for | changelog | medium | n/a | Mirror. |
| `.claude/skills/commit-discipline/SKILL.md` | pack | defines-rules-for | none directly | low | n/a | Read by pack-* agents; lists pre-flight checks and forbidden git verbs. |
| `.codex/skills/commit-discipline/SKILL.md` | pack | defines-rules-for | none directly | low | n/a | Mirror. |
| `.claude/skills/implementation-report/SKILL.md` | pack | defines-rules-for | none directly | low | n/a | Used by pack-coder for report shape. |
| `.codex/skills/implementation-report/SKILL.md` | pack | defines-rules-for | none directly | low | n/a | Mirror. |
| `.claude/skills/{architecture-review,dependency-intake,planning,review,verification-harness}/SKILL.md` and `.codex/skills/…` peers | pack | defines-rules-for | none directly | none | n/a | Out of scope for streams. |

### 1.N — Project-template skill files

| Path | Scope | Type | Streams touched | Per-entry impact | Pack-vs-client divergence | Notes |
|---|---|---|---|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` | project | reads-programmatically | backlog, status, implementation-plan, changelog | high | byte-equivalent mirrors at `project-template/.claude/skills/pm-startup/SKILL.md`, `project-template/.codex/skills/pm-startup/SKILL.md`, `project-template/.gemini/commands/pm-startup.toml` per BD-076 / validate-pack `check_pm_startup_per_cli_parity` Check 27 | `:69-87` Step 2 reads "BACKLOG entries (resolve via the trinity `## Document locations` table; reads `BACKLOG.md` in flat-file mode, the tracker in tracker mode)", same for STATUS, `PM-CHAT.md`, `PLATFORM-SKILLS.md`. "Read only the most recent dated section from `CHANGELOG.md`." "Identify the current phase from STATUS, then read only that phase's section from `IMPLEMENTATION-PLAN.md`." Trinity-resolver framing at `:83-87`. `:96-169` Step 4 RAG reconciliation. `:171-178` Step 5 TD-TBD grep. `:180-201` Step 6 startup report references "**Open BACKLOG items:**" and "**Last TD number:**". `:211-253` Step 8 inflection-point recommendation (D-19). |
| `project-template/.claude/skills/pm-startup/SKILL.md` | project | reads-programmatically | backlog, status, implementation-plan, changelog | high | byte-equivalent | Claude mirror (per Check 28 parity). |
| `project-template/.codex/skills/pm-startup/SKILL.md` | project | reads-programmatically | backlog, status, implementation-plan, changelog | high | byte-equivalent | Codex mirror. |
| `project-template/.gemini/commands/pm-startup.toml` | project | reads-programmatically | backlog, status, implementation-plan, changelog | high | TOML; content-equivalent | Gemini mirror. |
| `project-template/.claude/skills/pack-help/SKILL.md` | project | cross-references | (no) | none | n/a | Mirror of HELP-FRAGMENT.md. |
| `project-template/.codex/skills/pack-help/SKILL.md` | project | cross-references | (no) | none | n/a | Codex mirror. |
| `project-template/.gemini/commands/pack-help.toml` | project | cross-references | (no) | none | n/a | Gemini mirror. |
| `project-template/skills/audit-methodology/SKILL.md` | project | defines-rules-for | backlog, changelog, status | medium | n/a | `:46` "auditor-docs — documentation accuracy vs. actual code … CHANGELOG drift"; `:55` "auditor's report ends with `## Next steps` … cross-reference to PM chat's BACKLOG processing"; `:68` "auditor does not write to BACKLOG.md, STATUS.md, or any other project file"; `:69` "PM chat processes the consolidated report per METHODOLOGY.md Part 6: creates one BACKLOG entry per Critical finding (immediate work), one per Major finding (deferred but tracked), and summarizes Minor/Info findings as a single observations entry." |
| `project-template/skills/documentation/SKILL.md` | project | defines-rules-for | changelog | medium | n/a | `:41` rule 18 "CHANGELOG drift — CHANGELOG entries must match git history"; `:44` rule 21 "CHANGELOG entry claiming a security fix that was not actually committed is Critical". |
| `project-template/skills/{planning,review,implementation,debugging,…}/SKILL.md` | project | defines-rules-for | (varies; mostly none directly) | low | n/a | Out of scope; rule content lives in METHODOLOGY for streams. |


### 1.O — Pack BD entries that define stream-related contract

The v11 tracker BDs are themselves stream-relevant because they define
the entry model the per-entry shape must respect. Each is listed by
BACKLOG.md line; full content lives in the BACKLOG entries.

| BD | Status | BACKLOG line | What it defines / why per-entry-relevant |
|---|---|---|---|
| BD-060 | Resolved | `BACKLOG.md:33-44` | TrackerProvider abstraction (18 ops + raw + capabilities). Defines the surface every per-entry tracker read/write must go through. |
| BD-062 | Resolved | `BACKLOG.md:62-72` | Trinity `## Document locations` Source column extension. Defines how agents/skills branch on flat-file vs tracker. Pack-repo trinity is exempted (no `## Document locations` section there). |
| BD-063 | Resolved | `BACKLOG.md:76-87` | Issue forms `work-item.yml` and `inbound.yml`. Defines the form family routing by wi-type and the template_version label. |
| BD-064 | Resolved | `BACKLOG.md:91-101` | Template archive bootstrap. Defines `templates-archive/v11.0/<entry-type>-v11.0/SCHEMA.md` layout per V3.3 §6.5. |
| BD-066 | Resolved | `BACKLOG.md:120-129` | `pack tracker init` wrapper. Defines opt-in path and verb dispatcher. |
| BD-067 | Resolved | `BACKLOG.md:133-143` | Reverse migration + sidecar. Defines the round-trip property and the v11.0 deferral of CHANGELOG audit-log walking. |
| BD-068 | Resolved | `BACKLOG.md:147-157` | Round-trip test fixture. Documents that comment-fallback blockers do not round-trip (BD-111 deferral). |
| BD-069 | Resolved | `BACKLOG.md:161-172` | template_version HTML-comment + label dual carrier. Defines `<!-- template_version: bd-v11.0 -->` and the parallel `template:bd-v11.0` label. |
| BD-070 | Resolved | `BACKLOG.md:176-186` | Typed error surfacing. Defines the 10 typed codes + Layer-2 verb table. |
| BD-071 | Resolved | `BACKLOG.md:190-200` | Agent read-pattern adaptation (D-9). Replaces "Read BACKLOG.md" → trinity-resolver in 10 per-agent prompt files. Defines `scripts/lib/tracker-agent-read.sh`. |
| BD-072..BD-074 | (varies — see lines) | `BACKLOG.md` later | D-19 recommendation system: 3 pack-side signals + 6 client-side signals. |
| BD-075..BD-077 | (varies) | `BACKLOG.md` later | D-20 help-verb system; `HELP-FRAGMENT-PACK.md`, `docs/pack/HELP-FRAGMENT.md`, byte-identical `HELP-FRAGMENT-TRACKER.md` mirror. |
| BD-088 | Resolved | (in CHANGELOG `CHANGELOG.md:44-51`) | Customization-preserve library; 12 file classes; 8 disposition tokens. The forward-migration's customization-preservation behavior. |
| BD-104 | Carried over (Open at v11.0 cut) | `CHANGELOG.md:110-111` | Cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`. |
| BD-105 | Carried over | `CHANGELOG.md:112` | STATUS.md phase-row dual-link rendering (tracker mode). |
| BD-106 | Carried over | `CHANGELOG.md:113` | Phase task entity model + identifier scheme + parser/emitter. |
| BD-107 | Carried over | `CHANGELOG.md:114` | TD-NNN promotion-path tooling. |
| BD-108 | Carried over | `CHANGELOG.md:115-116` | Cross-entity dependency link orchestration + cycle check + gate-check extension. |
| BD-109 / BD-110 | Carried over | `CHANGELOG.md:117-118` | Project-side / pack-side `auditor-issue-tracking` agent. |
| BD-111 | Carried over | `CHANGELOG.md:119-120` | First-class GitHub dependency-API mutation (replaces comment-marker fallback). Round-trip property auto-flips when this closes (per BD-068 deferred note). |
| BD-133 | (resolved, location TBD via grep — referenced from `scripts/lib/tracker-header-snapshot.sh:1,69` and `scripts/lib/tracker-migrate-reverse.sh:881-889`) | grep `BACKLOG.md` for `BD-133` | BACKLOG.md header preamble snapshot/restore on reverse-emit. |
| BD-135 | (resolved, location TBD) | grep `BACKLOG.md` for `BD-135` | `tracker.toml.example` rename to `tracker.toml.pack-example` / `tracker.toml.project-example`. |
| BD-119 | (resolved/in flight per CLAUDE.md:35-40 reference) | `BACKLOG.md` — see grep | Migrator framework — `scripts/lib/migrator-core.sh` + adapter contract for `scripts/migrate-vN-to-vM.sh`. |


---

## Section 2 — Pack-vs-client divergence by stream

STATUS is excluded from this section (covered in Section 3).

### 2.A — Stream: backlog

| Dimension | Pack-self | Client-project |
|---|---|---|
| Identifier prefix | `BD` (`tracker.toml.pack-example:44`; CLAUDE.md:60-62 commit-format rule `feat: vN — BD-NNN`) | `TD` (`project-template/tracker.toml.project-example:49`; METHODOLOGY.md:1030-1033 BACKLOG item format uses `**TD-NNN — [Short title]**`) |
| Content domain | Pack-development work: agent/skill/script changes, methodology decisions, tracker infra, migration paths (sampled BD-060 through BD-159 in `BACKLOG.md`) | Project technical debt: implementation gaps, deferred work, KNOWN-GAP / VERIFY / TODO comments in code (`supporting-docs/METHODOLOGY.md:992-1023`) |
| Agent population — who reads | Pack agents: pack-architect (`.claude/agents/pack-architect.md:27`), pack-planner (`:32`), pack-reviewer (`:28-29`); plus Pack Chat (`PACK-CHAT.md:13-16,42`) | Per-agent prompts list BACKLOG as required reading: reviewer.md:20-22, tester.md:17-20, coder.md required-reading in coder.md:14-18; PM chat (`PM-CHAT.md:117-119`); auditor (`auditor.md:42,48-49`) |
| Agent population — who writes | Pack Chat only (`CLAUDE.md:82-86`; `PACK-AGENTS.md:97-105`). No pack agent writes. | PM chat only (`PM-CHAT.md:201-203`; METHODOLOGY.md:1320). No project agent writes; coder writes TD-TBD deferral comments in source, never BACKLOG itself (METHODOLOGY.md:1249-1262). |
| Cross-reference targets | Commit messages (`CLAUDE.md:46-52`), `CHANGELOG.md` entries (each BD listed in v11.0 entry `CHANGELOG.md:32-122`), `README.md` version table | Commit messages, `CHANGELOG.md`, source-code deferral comments (`// TODO(scope): TD-NNN — title` per METHODOLOGY.md:992-1023), STATUS.md phase tables when items relate to current phase |
| Lifecycle / cadence | Entry created when Pack Chat opens new work (`CLAUDE.md:60-62`); flipped Resolved in place at batch completion (`CLAUDE.md:113-117`, "Implicit BD status flip on batch completion"); no Resolved section move (`CLAUDE.md:157-159`, "BACKLOG.md has no Resolved section") | Open at deferral / unblock-detection time; flipped Resolved by Procedure 4 after reviewer confirms work + comment removal (`supporting-docs/METHODOLOGY.md:1150-1171`); also Cancelled / Deprecated via Procedure 7 / cancel-deprecate procedure (`supporting-docs/METHODOLOGY.md:1234-1247`). Counter tracking per Procedure (`supporting-docs/METHODOLOGY.md:1061-1063`) |
| Version-namespace | n/a (BACKLOG is stream, version-versioning happens in CHANGELOG only) | n/a |
| Form-family / template usage | `bd-v11.0` schema (`maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md`); wi-type = `bd` (`.github/ISSUE_TEMPLATE/work-item.yml:23`); `template:bd-v11.0` label + HTML-comment carrier per BD-069 | `td-v11.0` schema; wi-type = `td` (`work-item.yml:24`); wi-td-scope enum (`:67-72`) and wi-td-severity enum (`:80-83`) populated only for TD; `template:td-v11.0` label |
| Tracker-mode interaction | Pack-self tracker opt-in independent of client (`tracker.toml.pack-example` lives at pack root); forward migration via `pack tracker init` lifts BACKLOG.md → GitHub Issues at `DShaneNYC/optiquity-ai-agent-config-pack`; mirror header writes back to BACKLOG.md; reverse rewrites BACKLOG.md from issues + preserves preamble snapshot per BD-133 | Per-project tracker opt-in independent of pack-self; client `tracker.toml` lives at `docs/pack/tracker.toml` (`project-template/tracker.toml.project-example:3` comment line); forward / reverse symmetric to pack; client trinity Source column flips `docs/project/` to `mixed` in tracker mode (`project-template/CLAUDE.md:223-224`) |

### 2.B — Stream: implementation-plan

| Dimension | Pack-self | Client-project |
|---|---|---|
| Identifier prefix | n/a (no IMPLEMENTATION-PLAN.md exists in pack-self at HEAD; pack development tracks phases inside maintenance-docs/v11-research/ as ad-hoc docs like IMPLEMENTATION-PLAN.md addendum chain) | `phase-N`, `phase-N.M`; epic skeleton via wi-type=`phase-epic-skeleton`, task skeleton via wi-type=`phase-task-skeleton` (`work-item.yml:25-26`) |
| Content domain | Pack-self uses `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` + addenda 2/3/4 as planning corpus per `BACKLOG.md:25-29` ("derived from the planning corpus at `maintenance-docs/v11-research/` (IMPLEMENTATION-PLAN.md + four addenda; ARCHITECTURE-V3.3-DELTA.md is the live design)"). Not the canonical "live plan" file the client sees. | Phase-by-phase work plan per METHODOLOGY Part 4 (`supporting-docs/METHODOLOGY.md:291-358`); each phase has Goal / Prerequisite / Tasks / Verification / Agent / Risks |
| Agent population — who reads | Pack agents reference design docs in `maintenance-docs/` not a single IMPLEMENTATION-PLAN.md file | architect / planner / coder / reviewer / docs-researcher (`project-template/docs/pack/prompts/{architect,planner,coder,reviewer,docs-researcher}.md` — see Section 1.K); PM chat (`PM-CHAT.md:121-123`); pm-startup skill (`project-template/skills/pm-startup/SKILL.md:78-87`) |
| Agent population — who writes | n/a directly; architect/planner produce ARCHITECTURE-V*.md / IMPLEMENTATION-PLAN.md addenda under `maintenance-docs/v11-research/` | architect agent (kickoff) + planner agent per METHODOLOGY Part 2 (`supporting-docs/METHODOLOGY.md:113`); coder may not modify unless explicitly instructed (Part 2 rule 5 `:128-132`; Part 9 table `:1318`) |
| Cross-reference targets | `CHANGELOG.md` entries reference V1 / V2 / V3.3 design doc sections; tracker BDs cite plan via section numbers in the addenda | `STATUS.md` phase-title links target IMPLEMENTATION-PLAN.md headings (`project-template/docs/pack/PM-CHAT.md:204-209` STATUS.md phase-title-links rule; `prompts/pm-chat.md:164-174` example) |
| Lifecycle / cadence | Living planning corpus; v11.0 superseded by ARCHITECTURE-V3.3-DELTA.md per BACKLOG.md:25-29 | Phases appended over project lifetime; never deleted (`supporting-docs/METHODOLOGY.md:113,1318`); each phase has DoD + verification + agent assignment |
| Form-family / template usage | n/a (pack uses ad-hoc design docs) | `phase-epic-v11.0` schema, `phase-task-v11.0` schema; wi-phase-number field (`work-item.yml:88`); wi-task-title (`:95`); wi-problem-goal-success (`:145`); wi-files (`:152`); wi-definition-of-done (`:159`); wi-dependencies (`:166`) per BD-106 extension |
| Tracker-mode interaction | n/a | In tracker mode, IMPLEMENTATION-PLAN.md is tracker-mirrored read-only (per CLAUDE.md:212-218 trinity rule paragraph); coder prompt explicitly states "BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION-PLAN are tracker-mirrored read-only files" (`coder.md:66-67`); recommendation surface uses `implementation_plan_kb` signal (`scripts/lib/recommendation.sh:153-170`) |


### 2.C — Stream: changelog

| Dimension | Pack-self | Client-project |
|---|---|---|
| Identifier prefix | Version-scoped sections like `## v11 — May 2026`, `### v11.0 — Issue-tracker integration + customization-preservation fix` (`CHANGELOG.md:8-10`); inside sections, items cite BD-NNN (`CHANGELOG.md:14-122`) | Version-scoped phases; items cite TD-NNN and Phase N references |
| Content domain | Pack version history: release scope, BD lists per minor, audit artifacts, deferred items, ride-along fixes (`CHANGELOG.md:1-733`) | Project history per phase: tasks completed, files created/modified, test count, proposed-CHANGELOG-entry section in coder reports per METHODOLOGY (`supporting-docs/METHODOLOGY.md:114`) |
| Agent population — who reads | Pack agents read recent entries for version context (`PACK-CHAT.md:42-43,45`; `.claude/skills/pack-startup/SKILL.md:21`) | coder reads CHANGELOG.md (`coder.md:17`); reviewer reads phase-X entry (`reviewer.md:20-21`); tester reads CHANGELOG.md (`tester.md:17`); auditor-docs flags CHANGELOG drift (`audit-methodology/SKILL.md:46`) |
| Agent population — who writes | Pack Chat only (`CLAUDE.md:67`, "CHANGELOG.md only at version boundaries with explicit instruction"; `PACK-AGENTS.md:103`; pack-coder explicitly prohibited `.claude/agents/pack-coder.md:34`) | PM chat only after reviewer approval (`supporting-docs/METHODOLOGY.md:114`, "One entry per phase, after reviewer approval; coder proposes entry in completion report"; Part 9 table `:1319`); coder may propose in completion report only (`coder.md:99-102`) |
| Cross-reference targets | Version tags (v8 / v9 / v10 / v11), BD-NNN entries, README version table, design-doc sections (V1 §, V2 §, V3.3 §, DELTA L1 etc.) | Phase N references, TD-NNN entries, file paths, test counts |
| Lifecycle / cadence | Append-only by version (`supporting-docs/METHODOLOGY.md:125`, "CHANGELOG.md is append-only — never edit old entries"); section per minor version; v11.0 entry runs `CHANGELOG.md:10-266` | Append-only per phase; proposed-entry pattern bridges coder → PM chat (`project-template/CLAUDE.md:272-275`, "At the end of every implementation phase, include a `Proposed CHANGELOG entry` section in your completion report") |
| Version-namespace | Major: v1..v11 (`CHANGELOG.md` H2 headings); minor: vN.0, vN.1, … (`CLAUDE.md:54-58` versioning rule); commit format `feat: vN — BD-NNN ...` (`CLAUDE.md:46-52`) | Per-pack-version inside the project's CHANGELOG entries; the project's own version conventions per project |
| Form-family / template usage | n/a (CHANGELOG entries are free-form prose; no issue-template) | n/a directly; reverse-emit skeleton from tracker (`scripts/lib/tracker-migrate-reverse.sh:547-570`) is structural-stub-only ("Real audit-log walking deferred" per BD-067 resolved note `BACKLOG.md:143`) |
| Tracker-mode interaction | Pack tracker keeps issue history; CHANGELOG.md remains flat-file even when tracker is on (CHANGELOG isn't issue-state-tracked) | In tracker mode, CHANGELOG.md becomes tracker-mirrored read-only per the same trinity Source-column rule, but the audit-log walker to produce real entries from tracker state is deferred to a future BD (`scripts/lib/tracker-migrate-reverse.sh:547-562`, "CHANGELOG was reverse-emitted from the tracker") |


---

## Section 3 — STATUS.md nature verification

**Pack-self STATUS.md.** Searched at HEAD — no `STATUS.md` file exists
in the pack repo root. Pack-development workflow does not maintain a
STATUS.md; pack state is read from `git log`, `BACKLOG.md` open
counts, and `README.md` version-table. The pack-startup skill
(`.claude/skills/pack-startup/SKILL.md:44-58`) reports "Current
version / Open backlog items (BD) / Last BD number / Last commit /
CI tooling" — no Phase Completion table, no Current Phase line.

**Client STATUS.md.** Expected at `docs/project/STATUS.md` in v11
projects (per trinity table `project-template/CLAUDE.md:223-224`).

**METHODOLOGY.md description of STATUS.md role.**

`supporting-docs/METHODOLOGY.md:116` (Part 2 Standard Project
Documents table) — "`STATUS.md` | Current phase, phase table, next
actions, key metrics | PM chat or developer | After every phase
completion".

`supporting-docs/METHODOLOGY.md:127` (Part 2 hygiene rule 4) — "STATUS.md
is updated after every phase — stale status is worse than no status."

`supporting-docs/METHODOLOGY.md:1321` (Part 9 What agents can and
cannot modify) — "`STATUS.md` | Never | Never | Yes — after phase
completion | Update after every phase".

`supporting-docs/METHODOLOGY.md:1330` (Part 9 Desktop Commander scope)
— "Updating STATUS.md after a phase completes" is sanctioned PM-chat
Desktop-Commander use.

`supporting-docs/METHODOLOGY.md:1429` (Appendix New Project Checklist
After each phase) — "Update STATUS.md: mark phase ✅, update current
phase, update test count in metrics".

**What writes to STATUS.md.**

- PM chat via Procedure 4 resolution path (`supporting-docs/METHODOLOGY.md:1150-1171`).
- PM chat after phase completion via `project-template/docs/pack/prompts/pm-chat.md`
  Variant `backlog-status-update` (`:98-178`) — schema for STATUS.md update
  at `:164-174` including phase-table link rule.
- PM chat per `PM-CHAT.md:204-209` STATUS.md phase title links rule.
- Reverse-emit from tracker via `scripts/lib/tracker-migrate-reverse.sh:513-545`
  (emit STATUS.md skeleton from phase-epics + entry counts).
- BD-105 (carried over from v11.0) is "STATUS.md phase-row dual-link
  rendering (tracker mode)" (`CHANGELOG.md:112`).

**What reads STATUS.md.**

- `project-template/skills/pm-startup/SKILL.md:71-79` — Step 2 reads
  STATUS entries to identify current phase.
- Procedure 1 phase gate check uses STATUS to verify prior phase ✅
  (`supporting-docs/METHODOLOGY.md:1072-1073`).
- `supporting-docs/CLI-PM-SETUP.md:146,157,178,240` — STATUS in the
  files-to-read list across all four PM-chat surfaces.
- `project-template/docs/pack/PM-CHAT.md:117-120` direct read.
- Auditor agents may read STATUS read-only
  (`project-template/.claude/agents/auditor.md`; per-prompt at
  `project-template/docs/pack/prompts/auditor.md:48-49`).

**File structure.** STATUS.md is a dashboard, not a stream:

- "Phase table" plus "Current Phase" line plus "Next Actions" list
  plus "Key Metrics" line — single live document overwritten as
  phases progress.
- Reverse-emit skeleton (`scripts/lib/tracker-migrate-reverse.sh:535`):
  `lines = ["# STATUS", "", "## Phases", ""]` — emitter writes a
  flat list of phase entries, not a sequence of timestamped status
  updates. This confirms the dashboard model.
- `project-template/docs/pack/prompts/pm-chat.md:164-174` schema for
  STATUS.md update is mutation in place ("Mark Phase [N] as ✅
  Complete in the phase table; Update `Current Phase` to: Phase
  [N+1] — [Title] (not started); Update `Next Actions`; Update `Key
  Metrics`") — overwrite semantics.

**Stream consumers that would break under per-entry shape.**

Searched at HEAD — no current consumer treats STATUS.md as a
sequence of entries. The reverse-emit step 6 writes a flat phase
table. Procedure 1 step 2 in METHODOLOGY (`supporting-docs/METHODOLOGY.md:1071-1073`)
reads STATUS to check `Phase N blocker: has that phase been
committed and marked ✅ in STATUS.md?` — this expects the phase
table format, not entry parsing.

The recommendation system does NOT compute a STATUS-derived signal —
client signals (`scripts/lib/recommendation.sh:145-175`) compute
from BACKLOG + IMPLEMENTATION-PLAN only, not STATUS.

Conclusion (facts only, no design): STATUS.md at HEAD is structured
and treated as a single-file dashboard with overwrite semantics;
there is no extant consumer treating it as a stream of entries.

---

## Section 4 — v11 tracker template / form-family inventory

### Form file paths

- `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root).
- `.github/ISSUE_TEMPLATE/inbound.yml` (pack-root).
- `.github/ISSUE_TEMPLATE/config.yml` (pack-root).
- Client-side mirrors of these forms ship to project repos via
  init-project.sh + migrate-v10-to-v11.sh per BD-063 BACKLOG entry
  (`BACKLOG.md:81`, "plus `project-template/.github/ISSUE_TEMPLATE/`
  mirrors"). At HEAD `find /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev -name ISSUE_TEMPLATE -type d` returns only the pack-root `.github/ISSUE_TEMPLATE/`. The client-template mirror under `project-template/.github/` is not present in the working tree at this commit. This is an inventory observation, not a conclusion.

### wi-type enumeration values

`.github/ISSUE_TEMPLATE/work-item.yml:22-26` — 4 values:

1. `bd` — Pack-development backlog item
2. `td` — Project technical-debt item
3. `phase-epic-skeleton` — Hand-edited phase epic (rare; day-to-day
   phase work created by Pack Chat at migration time per
   `work-item.yml:14-16`)
4. `phase-task-skeleton` — Phase task (BD-106 extension per
   `BACKLOG.md:101`)

### wi-kind enumeration values (BD/TD only)

`.github/ISSUE_TEMPLATE/work-item.yml:34-40` — 6 values: `feat`,
`fix`, `refactor`, `docs`, `chore`, `infra`. Maps to METHODOLOGY §
Part 7 type taxonomy (per the field's own description at `:33`).

### wi-status enumeration values

`.github/ISSUE_TEMPLATE/work-item.yml:48-57` — 9 values: `Open`,
`Unblocked`, `Pending`, `In Progress`, `Resolved`, `Done`, `Deferred`,
`Cancelled`, `Deprecated`. Default index 0 (`Open`). Phase tasks
default to `Pending` per the field description at `:47`.

### wi-td-scope enumeration values (TD only)

`.github/ISSUE_TEMPLATE/work-item.yml:67-72` — 5 values: `phase-N`,
`dependency`, `feature`, `perf`, `version`. Mirrors METHODOLOGY §
Part 7 "Valid scope values for TODO" (`supporting-docs/METHODOLOGY.md:1010-1012`).

### wi-td-severity enumeration values (TD KNOWN GAP variant)

`.github/ISSUE_TEMPLATE/work-item.yml:80-83` — 3 values: `critical`,
`functional`, `polish`. Mirrors METHODOLOGY § Part 7 "Valid severity
values for KNOWN GAP" (`supporting-docs/METHODOLOGY.md:1014-1017`).

### in-category enumeration values

`.github/ISSUE_TEMPLATE/inbound.yml:21-27` — 7 values: `bug`,
`feature-request`, `pack-feedback-workflow`, `pack-feedback-prompt`,
`pack-feedback-agent-perf`, `pack-feedback-friction`,
`pack-feedback-open-question`. Pack-feedback subcategories land here
per V1 §7.5 (per `inbound.yml:11-13`).

### template_version marker pattern (BD-069)

Two carriers per BD-069 D-18 (`BACKLOG.md:167-172`):

1. **HTML comment carrier** — embedded in issue body. Examples:
   - `<!-- template_version: work-item-v11.0 -->`
     (`.github/ISSUE_TEMPLATE/work-item.yml:176`)
   - `<!-- template_version: inbound-v11.0 -->`
     (`.github/ISSUE_TEMPLATE/inbound.yml:75`)
   - Per-entry-type spelling: `bd-v11.0`, `td-v11.0`,
     `phase-epic-v11.0`, `phase-task-v11.0`, `inbound-v11.0`
     (corresponding SCHEMA.md files in templates-archive).
2. **Label carrier** — parallel `template:<entry-type-version>`
   label. Examples:
   - `template:work-item-v11.0` (`.github/ISSUE_TEMPLATE/work-item.yml:7`)
   - `template:inbound-v11.0` (`.github/ISSUE_TEMPLATE/inbound.yml:7`)

Source-doc preamble references at HEAD (current locations):

- `BACKLOG.md:84` description text uses "HTML-comment `template_version` marker"
- `BACKLOG.md:143,161,167` reference template_version in BD-067 and BD-069 descriptions/resolutions
- `scripts/lib/template-version.sh:6,25-180` defines the read/reconcile API
- `scripts/lib/tracker-sidecar.sh:1-20` lists template_version among
  tracker-only sidecar fields

Form-level template_version markers also live at the bottom of each
issue-template yaml (`work-item.yml:172-177`, `inbound.yml:71-76`).
The HTML-comment block at the end is read by
`template_version_read_form()` (`scripts/lib/template-version.sh:169-190`).

### Label-to-attribute map

Per `scripts/lib/tracker-labels.sh` (BD-066, 45-label canonical set per
`BACKLOG.md:129` resolved note). Not enumerated here at function-level
detail — the label set is its own file; the architect should cite that
file directly for the full mapping. Known categories at HEAD:

- `status:*` (e.g., `status:open`, `status:resolved`, `status:cancelled`,
  `status:deprecated`) per wi-status enum
- `wi-type:*` (`bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton`)
- `kind:*` (`feat`, `fix`, `refactor`, `docs`, `chore`, `infra`)
- `scope:*` (`phase-N`, `dependency`, `feature`, `perf`, `version`)
- `severity:*` (`critical`, `functional`, `polish`)
- `template:*` (template_version dual-carrier per BD-069)
- `phase-N` (phase membership; numeric)
- `work-item`, `inbound`, `needs-triage` (form-applied per
  `work-item.yml:5-7` and `inbound.yml:5-7`)


### Round-trip property (BD-068)

Per `BACKLOG.md:147-157`: "F→R reconstructs 3 entries with
status/title/file-symbol/description preserved (whitespace-tolerant);
F→R→F produces byte-equivalent tracker create-call signature (sorted
titles+labels)."

Fields preserved byte-for-byte across forward → reverse:

- pack_id (BD-NNN / TD-NNN)
- title
- File/Symbol
- Description
- Status (status reconstruction from labels per BD-067 `BACKLOG.md:143`)
- Type / wi-kind / wi-td-scope / wi-td-severity (from labels)
- Blockers (from sub-issue parent + comment markers)
- Unblocks (computed by inverting Blockers across the dataset)
- Context, Resolution H2 sections

Fields with documented gaps in v11.0:

- Comment-fallback blockers do NOT round-trip — BD-111 deferral
  (auto-flips to positive check when BD-111 closes, per `BACKLOG.md:157`)
- Audit-log walking for CHANGELOG.md step 7 deferred (no
  `provider_events` op in BD-060 per `BACKLOG.md:143`)
- Reactions / attachments / audit_log: sidecar placeholders only
  (per BD-067 resolved note `BACKLOG.md:143`; ride-along to future BD)

Test fixture: `scripts/tests/tracker-migrate-roundtrip-test.sh` and
`scripts/tests/fixtures/roundtrip/bd-v11.0/` (per `BACKLOG.md:152`);
`bd-v11.1/` and `bd-v11.2/` stub directories with READMEs.

### Source column convention (BD-062)

Trinity `## Document locations` table (`project-template/CLAUDE.md:218-226`,
`AGENTS.md:205-211`, `GEMINI.md:213-221`) — Source column values:

- `flat` — directory contains files that are the source of truth
- `mixed` — directory contains a mix of flat files and tracker mirrors
  (only `docs/project/` flips to `mixed` in tracker mode, because
  BACKLOG.md / STATUS.md / CHANGELOG.md / IMPLEMENTATION-PLAN.md become
  tracker-mirrored while ARCHITECTURE.md stays flat — per the
  explainer paragraph at `project-template/CLAUDE.md:214-219`)
- `tracker` — directory contents are tracker-mirrored read-only
  (not currently used in v11.0 — all rows are `flat` or `mixed`)

Pack-repo trinity exempted per D-6 footnote (no `## Document
locations` section there) — confirmed by absence in pack-root
`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`.

`pm-startup` Step 2 reads this column to branch by source
(`project-template/skills/pm-startup/SKILL.md:83-87`).

### Provider abstraction (BD-060)

Per `BACKLOG.md:33-44`: 18 provider operations + `raw()` escape hatch
+ capability flags. GH backend at `scripts/lib/tracker-provider-gh.sh`
(BD-060 resolved). Other backends (Forgejo / Linear / Jira) reserved
per `OPTIONAL-FEATURES.md:128-131`.

Surface that is GH-specific vs. provider-agnostic:

- GH-specific: `gh-sub-issue` extension policy, GraphQL preview-header
  policy (`BACKLOG.md:42-43`); `gh auth status` validation
  (`BACKLOG.md:128`); label-set semantics depend on GitHub Issues
  labels.
- Provider-agnostic: the 18-op surface (`provider_list`, `provider_get`,
  `provider_create`, `provider_update`, `provider_link`, etc.); the
  `raw()` escape hatch.

The architect downstream should consult `scripts/lib/tracker-provider.sh`
directly for the full 18-op list — listing them here would double the
inventory length without adding new touch-point information.

---

## Section 5 — RAG manifest current state and extension surface

### Where the RAG manifest is declared

- Authoritative declaration: `project-template/docs/pack/PM-CHAT.md:133-171`
  § "RAG ingestion manifest" — names the file
  `docs/pack/METHODOLOGY.md` as the default single manifest path;
  lists 4 retired paths (`PROMPT-TEMPLATES.md` root, `docs/pack/PROMPT-TEMPLATES.md`,
  `METHODOLOGY.md` root, `ARCHITECTURE.md` root) that must be
  orphan-deleted from the index.
- Principle reference: `supporting-docs/METHODOLOGY.md:140-185` §
  "RAG index hygiene" — explains why orphans are not benign,
  reconciliation procedure, triggers beyond `/pm-startup`.

### Default manifest contents

Single path: `docs/pack/METHODOLOGY.md`
(`project-template/docs/pack/PM-CHAT.md:135-137,148-152`). Plus any
custom project documents declared under
`## Additional project documents` near the bottom of the same file
(`project-template/docs/pack/PM-CHAT.md:159-170,629-647`). The
discriminator is the access-method column: `RAG query` → joins
manifest; `Direct read` → direct-read only.

### How the manifest is reconciled at startup

Step 4 of `/pm-startup` (`project-template/skills/pm-startup/SKILL.md:96-169`):

1. List current ingest via `local-rag` `list` MCP tool.
2. Read manifest from `docs/pack/PM-CHAT.md` § RAG ingestion manifest.
3. Compute diff: orphans, stale, missing.
4. For each orphan: `local-rag` `delete` (no user approval per
   METHODOLOGY:160-166).
5. For each stale or missing: `local-rag` `delete` then `ingest`.
6. Record diff for Step 6 startup-summary line `RAG: …`.

Surface-specific handling at
`project-template/skills/pm-startup/SKILL.md:149-169` for `local-rag`
unavailable, manifest missing/malformed, manifest target missing.

Step 4 of `/pack-startup` (`.claude/skills/pack-startup/SKILL.md`)
does NOT include RAG reconciliation — the pack chat has no RAG
manifest, by design. Pack chat is the author of METHODOLOGY.md /
PROMPT-TEMPLATES.md, not a consumer (per `CHANGELOG.md:539-543`
explains the v8.8 removal of mcp-local-rag from pack CLI chat).

### Per-CLI mirrors of the startup skills

- Claude: `project-template/.claude/skills/pm-startup/SKILL.md`
- Codex: `project-template/.codex/skills/pm-startup/SKILL.md`
- Gemini: `project-template/.gemini/commands/pm-startup.toml`
- Source-of-truth: `project-template/skills/pm-startup/SKILL.md`
  (copied to the three per-CLI mirrors via init-project.sh)

Parity enforcement: validate-pack `check_pm_startup_per_cli_parity()`
function defined at `scripts/validate-pack.py:2042-2158`. Helper
`_extract_pm_startup_sections()` at `:2021-2041`. Listed in
`main()` per `:2579-…` (Check 28, per CHANGELOG `CHANGELOG.md:61-63` BD-082
description). 

### Surface a future change would touch (enumeration)

Per the discriminator-column architecture, adding or removing a RAG
manifest entry currently touches:

- `project-template/docs/pack/PM-CHAT.md` — the table at `:117-131` and
  the manifest section at `:133-171`.
- `project-template/skills/pm-startup/SKILL.md` — Step 4
  reconciliation logic (`:96-169`) if the discriminator algorithm
  changes; pure manifest additions do not require code changes per
  the discriminator design.
- Per-CLI mirrors of pm-startup (3 surfaces above).
- `supporting-docs/METHODOLOGY.md:140-185` — principle-level RAG
  index hygiene description references the manifest indirectly.
- `supporting-docs/CLI-PM-SETUP.md` and `supporting-docs/DEPENDENCIES.md`
  (per `CHANGELOG.md:530-531`) — mcp-local-rag setup / update / re-ingest
  cross-references.


---

## Section 6 — Operational rules currently embedded outside `_rules.md`

This section is the most important output for preventing the previous
architect pass's gaps. The rules below currently live in their cited
locations and govern BACKLOG / IMPLEMENTATION-PLAN / CHANGELOG /
STATUS usage; none of them live in a per-stream `_rules.md` file
(because no such file exists at HEAD).

### 6.A — METHODOLOGY.md rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| `STATUS.md` purpose: "Current phase, phase table, next actions, key metrics; PM chat or developer; After every phase completion" | `supporting-docs/METHODOLOGY.md:116` | status | project (also describes pack-self informally — but pack-self has no STATUS.md) |
| `BACKLOG.md` purpose: "Technical debt, deferred items, known gaps; PM chat; Add/resolve; never delete items" | `supporting-docs/METHODOLOGY.md:115` | backlog | both |
| `CHANGELOG.md` purpose: "Permanent dated history of what was built; PM chat; One entry per phase, after reviewer approval; coder proposes entry in completion report" | `supporting-docs/METHODOLOGY.md:114` | changelog | both |
| `IMPLEMENTATION-PLAN.md` purpose: "All phases with tasks, DoD, agent, risks; PM chat + planner agent; Each phase adds entries; never delete old phases" | `supporting-docs/METHODOLOGY.md:113` | implementation-plan | project |
| Hygiene rule 1: "ARCHITECTURE.md and IMPLEMENTATION-PLAN.md are source of truth — they must reflect reality." | `supporting-docs/METHODOLOGY.md:124` | implementation-plan | project |
| Hygiene rule 2: "CHANGELOG.md is append-only — never edit old entries." | `supporting-docs/METHODOLOGY.md:125` | changelog | both |
| Hygiene rule 3: "BACKLOG.md items are never deleted — mark resolved with a note." | `supporting-docs/METHODOLOGY.md:126` | backlog | both |
| Hygiene rule 4: "STATUS.md is updated after every phase — stale status is worse than no status." | `supporting-docs/METHODOLOGY.md:127` | status | project |
| Hygiene rule 5: "Agents must not modify `ARCHITECTURE.md` or `IMPLEMENTATION-PLAN.md` unless explicitly instructed in the prompt. `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, and all other root `.md` files are exclusively the PM chat's responsibility — no agent should write them, and no agent prompt should instruct them to. Include root `.md` file constraints in every coder prompt." | `supporting-docs/METHODOLOGY.md:128-134` | backlog, changelog, status, implementation-plan | both |
| Hygiene rule 6: every deferral comment must have a corresponding BACKLOG.md entry; `TD-TBD` in any committed file is a defect | `supporting-docs/METHODOLOGY.md:135-138` | backlog | both |
| Procedure 1 (Phase gate check) step 1: "Read BACKLOG.md in full" | `supporting-docs/METHODOLOGY.md:1070` | backlog | project |
| Procedure 1 step 2: blocker resolution by Phase N (read STATUS) or TD-NNN (read BACKLOG); `Phase N blocker: has that phase been committed and marked ✅ in STATUS.md?` | `supporting-docs/METHODOLOGY.md:1071-1075` | backlog, status | project |
| Procedure 1 step 4: TD-TBD grep across repo | `supporting-docs/METHODOLOGY.md:1080-1082` | backlog | project |
| Procedure 1 step 5: orphan audit (Procedure 3) | `supporting-docs/METHODOLOGY.md:1083` | backlog | project |
| Procedure 1 step 6: Skill gap check reads Active skills line + IMPLEMENTATION-PLAN.md upcoming phase | `supporting-docs/METHODOLOGY.md:1084-1101` | implementation-plan | project |
| Procedure 2 (post-session): TD-TBD → TD-NNN assignment | `supporting-docs/METHODOLOGY.md:1113-1130` | backlog | project |
| Procedure 3 (orphan audit) | `supporting-docs/METHODOLOGY.md:1132-1148` | backlog | project |
| Procedure 4 (resolution path on Unblocked items) | `supporting-docs/METHODOLOGY.md:1150-1171` | backlog | project |
| Cancelling or deprecating a BACKLOG item (5-step procedure) | `supporting-docs/METHODOLOGY.md:1234-1247` | backlog | project |
| Agent BACKLOG write permissions table | `supporting-docs/METHODOLOGY.md:1249-1262` | backlog | project |
| PM chat comment-edit carve-out (only permitted source file edit) | `supporting-docs/METHODOLOGY.md:1259-1262` | backlog | project |
| Part 8 warning: "CHANGELOG.md entry doesn't match git diff." | `supporting-docs/METHODOLOGY.md:1283-1286` | changelog | both |
| Part 8 warning: BACKLOG grows faster than it shrinks → run LSP audit | `supporting-docs/METHODOLOGY.md:1306-1307` | backlog | project |
| Part 9 What agents can and cannot modify — full per-document table | `supporting-docs/METHODOLOGY.md:1313-1325` | backlog, changelog, status, implementation-plan | both |
| Desktop Commander scope: STATUS update + BACKLOG add + CHANGELOG append; never source code | `supporting-docs/METHODOLOGY.md:1327-1344` | backlog, changelog, status | project |
| Day-1 setup: "Create BACKLOG.md, STATUS.md, CHANGELOG.md (empty with structure)" | `supporting-docs/METHODOLOGY.md:1408` | backlog, changelog, status | project |
| After each phase: "Update STATUS.md: mark phase ✅, update current phase, update test count in metrics" | `supporting-docs/METHODOLOGY.md:1429` | status | project |
| RAG index hygiene principle (orphans not benign) | `supporting-docs/METHODOLOGY.md:140-185` | none (about RAG, but inventoried for completeness) | project |


### 6.B — BACKLOG.md preamble rules ("How to use this file")

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| "Reference items in commit messages: `feat: v9 — BD-020 description`" | `BACKLOG.md:11` | backlog | pack |
| "When an item is resolved, set Status: Resolved with the commit hash and date" | `BACKLOG.md:12` | backlog | pack |
| "To cancel or deprecate an item: set Status to Cancelled or Deprecated, add a Resolution field with date, disposition (cancelled\|deprecated), and brief rationale. Then review all items that listed this item as a blocker — they require human judgment, not automatic unblocking" | `BACKLOG.md:13-16` | backlog | pack |
| "Items deferred to a future version: set Blockers to the target version" | `BACKLOG.md:17` | backlog | pack |
| "New items get the next available BD-NNN number" | `BACKLOG.md:18` | backlog | pack |
| "This file ships in the repo so agents can read it and understand current scope" | `BACKLOG.md:19` | backlog | pack |
| "Format follows the standard BACKLOG item format from METHODOLOGY.md Part 7." | `BACKLOG.md:5` | backlog | pack (uses TD-NNN format from METHODOLOGY despite pack-self using BD-NNN — a documented inheritance that maps the schema across prefixes) |

### 6.C — CHANGELOG.md preamble rules

`CHANGELOG.md:1-6` preamble: "All notable changes to the AI Agent
Config Pack are documented here. Each version is available as a git
tag (v1, v2, …)."

No additional preamble rules; the bulk of CHANGELOG operational
behavior is governed by METHODOLOGY.md and the pack-root trinity
"What agents may modify" rule (`CLAUDE.md:67`).

### 6.D — Pack-root CLAUDE/AGENTS/GEMINI rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| Commit format: `feat: vN — BD-NNN short description` | `CLAUDE.md:46-52` (mirrored in `AGENTS.md`, `GEMINI.md`) | backlog, changelog | pack |
| Versioning: minor for incremental, major for breaking, bare tag floats to latest minor | `CLAUDE.md:54-58` | changelog | pack |
| BD-NNN numbering: read BACKLOG.md, find highest, increment by 1 | `CLAUDE.md:60-62` | backlog | pack |
| What agents may modify: CHANGELOG.md only at version boundaries with explicit instruction | `CLAUDE.md:64-68` | changelog | pack |
| What agents must never modify without explicit instruction: BACKLOG.md (PM chat only, after user approval); README.md version table (PM chat only); PACK-CHAT.md; CLAUDE.md/AGENTS.md/GEMINI.md/PACK-AGENTS.md | `CLAUDE.md:82-86` | backlog | pack |
| Pack memory § Workflow: "Agents never commit." | `CLAUDE.md:102-107` | backlog, changelog (all streams via commit-relation) | pack |
| Pack memory § Workflow: "Pack Chat does not architect." Architecture/planning/implementation/review goes to pack-architect/pack-planner/pack-coder/pack-reviewer; Pack Chat handles BACKLOG/CHANGELOG entries, routing, approvals, commits, user-facing decisions | `CLAUDE.md:108-111` | backlog, changelog | pack |
| Pack memory § Workflow: "One review/fix cycle per batch." Fixes land in current session, never as new BD; BDs reserved for new scope/feature/architecture; only user can initiate BD-for-fix | `CLAUDE.md:112-114` | backlog | pack |
| Pack memory § Workflow: "Implicit BD status flip on batch completion." When review + fixes clean + tests green, flip BDs to Resolved as final step — no separate approval | `CLAUDE.md:115-117` | backlog | pack |
| Pack memory § Repo conventions: "BACKLOG.md has no Resolved section." Entries resolve in place by flipping `Status: Open` to `Status: Resolved` and filling the `Resolved:` line | `CLAUDE.md:157-159` | backlog | pack |
| Pack memory § Repo conventions: "Separate pack ops from pack product." | `CLAUDE.md:160-163` | (cross-cutting) | pack |

### 6.E — Project-template trinity rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| Document locations table: `docs/project/` contains BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION-PLAN/ARCHITECTURE; updated by PM chat + developer; Source `flat (or mixed in tracker mode)` | `project-template/CLAUDE.md:222-224`, `AGENTS.md:205-208`, `GEMINI.md:217-220` | all four streams | project |
| Build hygiene: "At the end of every implementation phase, include a `Proposed CHANGELOG entry` section in your completion report, formatted exactly as it would appear in `CHANGELOG.md`; Do not write to `CHANGELOG.md` or any other `.md` file in the project root — the PM chat applies the entry after reviewer approval." | `project-template/CLAUDE.md:271-277`, `AGENTS.md:249-252`, `GEMINI.md:266-272` | changelog | project |
| Deferral comments and BACKLOG hygiene § "Do not write to `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, or any other `.md` file in the project root" | `project-template/CLAUDE.md:303-309`, `AGENTS.md:266-272`, `GEMINI.md:298-305` | all four streams | project |
| TD-TBD sentinel: always write `TD-TBD` never a real number | `project-template/CLAUDE.md:293-296`, etc. | backlog | project |
| Trinity rule (universal) | `project-template/CLAUDE.md:340-344` (Project memory § Trinity rule) | all streams (since trinity files carry stream rules) | project |
| PM chat does not architect (Project memory) | `project-template/CLAUDE.md:353-360` | all streams | project |
| Custom agents `x-` prefix; pack-supplied skills never begin with `x-`; full convention in INSTALL-PROCEDURES.md | `project-template/CLAUDE.md:316-322` | (cross-cutting) | project |

### 6.F — PM-CHAT.md and PACK-CHAT.md rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| Maintain BACKLOG / STATUS / CHANGELOG after user approval | `project-template/docs/pack/PM-CHAT.md:36` | all four | project |
| File access strategy table: direct-read for BACKLOG / STATUS / CHANGELOG (last entry) / IMPLEMENTATION-PLAN (current phase section) | `project-template/docs/pack/PM-CHAT.md:117-131` | all four | project |
| Behavioral rule: "Source file edits. You may write to BACKLOG.md, STATUS.md, and deferral comments in source files — but only after explicit user approval." | `project-template/docs/pack/PM-CHAT.md:201-203` | backlog, status | project |
| Behavioral rule: STATUS.md phase title links must link to IMPLEMENTATION-PLAN.md heading with specific anchor format | `project-template/docs/pack/PM-CHAT.md:204-209` | status, implementation-plan | project |
| Behavioral rule: Recommendation routing (D-19) — `pm-startup` Step 8 surfaces opt-in question; PM chat does not silently opt in | `project-template/docs/pack/PM-CHAT.md:364-391` | backlog | project |
| Pack Chat role: "Track open backlog items (BD-NNN format in BACKLOG.md); Maintain CHANGELOG.md and README.md version history" | `PACK-CHAT.md:13-16` | backlog, changelog | pack |
| Pack Chat file access strategy: direct-read for BACKLOG / CHANGELOG (last entry) / README | `PACK-CHAT.md:38-47` | backlog, changelog | pack |
| Pack Chat recommendation routing (mirror of PM-CHAT rule) | `PACK-CHAT.md:110-135` | backlog | pack |
| Pack Chat behavioral rule: "No commit-staging beyond mechanical-edit threshold without architect justification." | `PACK-CHAT.md:90-97` | (cross-cutting) | pack |


### 6.G — Agent-file embedded rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| coder may not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md` | `project-template/.claude/agents/coder.md:81` (+ Codex/Gemini mirrors) | all four | project |
| auditor "Append `## Next steps` section listing Critical and Major findings in priority order, cross-referencing the PM chat's BACKLOG processing workflow" | `project-template/.claude/agents/auditor.md:42` | backlog | project |
| auditor-docs flags CHANGELOG drift (Critical when claiming uncommitted security fix) | `project-template/.claude/agents/auditor-docs.md:3,28-29,62` | changelog | project |
| repo-ops "No PM-only file edits. Do not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`" | `project-template/.claude/agents/repo-ops.md:69-70` | all four | project |
| pack-architect required reading includes "BACKLOG.md (open BD items and their constraints)" | `.claude/agents/pack-architect.md:27` | backlog | pack |
| pack-planner required reading includes "BACKLOG.md (BD items in scope)" | `.claude/agents/pack-planner.md:32` | backlog | pack |
| pack-coder: "modify BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md, …" listed as PM-only off-limits | `.claude/agents/pack-coder.md:34` | backlog, changelog | pack |
| pack-coder: "No BD status flips. BACKLOG.md `Status:` flips happen post-review" | `.claude/agents/pack-coder.md:38` | backlog | pack |
| pack-reviewer: "BACKLOG accuracy. If the change resolves or modifies a BD item, verify the BACKLOG entry is updated with the correct status and resolution." | `.claude/agents/pack-reviewer.md:28-29` | backlog | pack |
| PACK-AGENTS.md "When agents are used vs. pack chat direct" table: Writing BACKLOG.md / CHANGELOG.md / README.md version table → Pack Chat only | `PACK-AGENTS.md:102-104` | backlog, changelog | pack |
| PACK-AGENTS.md "PM-only files off-limits to all agents": BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md/AGENTS.md/GEMINI.md | `PACK-AGENTS.md:139-142` | backlog, changelog | pack |

### 6.H — Prompt-template embedded rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| coder root .md prohibition: full per-file list including BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION-PLAN; explicit tracker-mode equivalence ("BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION-PLAN are tracker-mirrored read-only files") | `project-template/docs/pack/prompts/coder.md:62-67, 169-170` | all four | project |
| coder proposed-CHANGELOG-entry pattern | `project-template/docs/pack/prompts/coder.md:99-102, 217-219` | changelog | project |
| reviewer required reading includes BACKLOG entries (trinity-resolved), CHANGELOG.md Phase [X] entry, IMPLEMENTATION-PLAN.md Phase [X] in full | `project-template/docs/pack/prompts/reviewer.md:20-22` | backlog, changelog, implementation-plan | project |
| reviewer BACKLOG hygiene check: for each TD-NNN in reviewed files, confirm matching BACKLOG entry | `project-template/docs/pack/prompts/reviewer.md:64,71-73` | backlog | project |
| tester required reading includes BACKLOG entries (trinity-resolved) | `project-template/docs/pack/prompts/tester.md:17-20` | backlog | project |
| auditor read-only audit: "Do not write to BACKLOG.md, STATUS.md, or any other project file. In tracker mode the BACKLOG/STATUS mirrors are read-only by design" | `project-template/docs/pack/prompts/auditor.md:48-49` | backlog, status | project |
| pm-chat Variant kickoff: "ARCHITECTURE.md, IMPLEMENTATION-PLAN.md (current phase), STATUS entries, BACKLOG entries" — full project-documents-in-context list; trinity-resolver framing | `project-template/docs/pack/prompts/pm-chat.md:51-58` | all four | project |
| pm-chat Variant backlog-status-update: full BACKLOG-entry schema + STATUS update schema (phase-title-link format) | `project-template/docs/pack/prompts/pm-chat.md:98-178` | backlog, status, implementation-plan | project |

### 6.I — Skill-file embedded rules

| Rule | Currently lives at | Stream affected | Applies to pack / project / both |
|---|---|---|---|
| pm-startup Step 2: trinity-resolver framing for BACKLOG/STATUS/IMPLEMENTATION-PLAN/CHANGELOG reads | `project-template/skills/pm-startup/SKILL.md:69-87` + 3 per-CLI mirrors | all four | project |
| pm-startup Step 4: RAG manifest reconciliation | `project-template/skills/pm-startup/SKILL.md:96-169` | none (RAG; logged for completeness) | project |
| pm-startup Step 5: TD-TBD grep | `project-template/skills/pm-startup/SKILL.md:171-178` | backlog | project |
| pm-startup Step 6 output: "Open BACKLOG items: [count]; Last TD number" | `project-template/skills/pm-startup/SKILL.md:191-192` | backlog | project |
| pm-startup Step 8: recommendation check D-19 (computes 6 client signals; surfaces prompt; routes per V3 §28.1.7) | `project-template/skills/pm-startup/SKILL.md:211-253` | backlog, implementation-plan | project |
| pack-startup Step 2: "Read BACKLOG.md in full; Read only the most recent dated entry from CHANGELOG.md" | `.claude/skills/pack-startup/SKILL.md:19-29` + 2 per-CLI mirrors | backlog, changelog | pack |
| pack-startup Step 4 output: "Open backlog items (BD): [count]; Last BD number" | `.claude/skills/pack-startup/SKILL.md:44-58` | backlog | pack |
| pack-startup Step 8: recommendation check D-19 (computes 3 pack signals) | `.claude/skills/pack-startup/SKILL.md:70-108` | backlog | pack |
| audit-methodology rule 55: auditor's report `## Next steps` cross-references PM chat's BACKLOG processing workflow | `project-template/skills/audit-methodology/SKILL.md:55` | backlog | project |
| audit-methodology rule 68: auditor does not write to BACKLOG.md, STATUS.md, or any other project file | `project-template/skills/audit-methodology/SKILL.md:68` | backlog, status | project |
| audit-methodology rule 69: PM chat processes consolidated report per METHODOLOGY § Part 6 — one BACKLOG entry per Critical, one per Major, single observations entry for Minor/Info | `project-template/skills/audit-methodology/SKILL.md:69` | backlog | project |
| documentation rule 18: CHANGELOG drift — entries must match git history | `project-template/skills/documentation/SKILL.md:41` (+ pack copy + Codex pack copy) | changelog | both |
| documentation rule 21: drift severity — CHANGELOG entry claiming uncommitted security fix is Critical | `project-template/skills/documentation/SKILL.md:44` | changelog | both |


---

## Section 7 — Per-CLI surface

### 7.A — Claude

**Pack-side agent files that touch streams:**

- `.claude/agents/pack-architect.md:27` — required-reading: BACKLOG.md
- `.claude/agents/pack-planner.md:32` — required-reading: BACKLOG.md
- `.claude/agents/pack-coder.md:34,38` — PM-only off-limits: BACKLOG/CHANGELOG/README version; "No BD status flips"
- `.claude/agents/pack-reviewer.md:28-29` — BACKLOG accuracy verification
- `.claude/agents/pack-docs-researcher.md` — no direct stream references (grep negative)

**Client-side agent files that touch streams (project-template):**

- `project-template/.claude/agents/coder.md:81` — root .md prohibition (BACKLOG/CHANGELOG/STATUS/PACK-FEEDBACK)
- `project-template/.claude/agents/auditor.md:42` — Next steps cross-references BACKLOG processing
- `project-template/.claude/agents/auditor-docs.md:3,28-29,62` — CHANGELOG drift severity
- `project-template/.claude/agents/repo-ops.md:69-70` — root .md prohibition

**Pack-side skill files that touch streams:**

- `.claude/skills/pack-startup/SKILL.md:19-29,44-58,70-108` — Step 2 reads BACKLOG/CHANGELOG; Step 4 output cites BD counts; Step 8 recommendation
- `.claude/skills/documentation/SKILL.md` — CHANGELOG drift rule (byte-equivalent to project-template skill source)
- `.claude/skills/commit-discipline/SKILL.md` — no direct stream rules; covers pre-flight + forbidden git verbs
- `.claude/skills/implementation-report/SKILL.md` — report-shape rules; no direct stream rules
- `.claude/skills/{architecture-review,dependency-intake,planning,review,verification-harness,pack-help}/SKILL.md` — no direct stream rules

**Client-side skill files that touch streams (project-template):**

- `project-template/.claude/skills/pm-startup/SKILL.md` — full mirror of `project-template/skills/pm-startup/SKILL.md`; reads BACKLOG/STATUS/IMPLEMENTATION-PLAN/CHANGELOG; D-19 client signals
- `project-template/.claude/skills/pack-help/SKILL.md` — no direct stream references
- `project-template/skills/pm-startup/SKILL.md` — source-of-truth for the per-CLI mirrors (per BD-076)
- `project-template/skills/audit-methodology/SKILL.md:46,55,68-69` — auditor BACKLOG / CHANGELOG / STATUS rules
- `project-template/skills/documentation/SKILL.md:41,44` — CHANGELOG drift rules

**Trinity (pack-root):**

- `CLAUDE.md` — pack-root rules; key files list, BD numbering, what-agents-may-modify
- `AGENTS.md` — Codex mirror (trinity rule)
- `GEMINI.md` — Gemini mirror

**Trinity (project-template):**

- `project-template/CLAUDE.md:222-226,271-277,303-309` — Document locations table, CHANGELOG proposed-entry rule, BACKLOG hygiene
- `project-template/AGENTS.md:205-211,249-252,266-272` — same content per trinity rule
- `project-template/GEMINI.md:217-221,266-272,298-305` — same content per trinity rule

**Per-CLI parity checks already enforced:**

- `check_pm_startup_per_cli_parity()` Check 27 (`scripts/validate-pack.py:2042-2158`) — pm-startup byte-equivalence across 3 surfaces per BD-076
- `check_pack_help_per_cli_parity()` Check 28 / 21 (`scripts/validate-pack.py:1507-1569`) — pack-help byte-equivalence per BD-076 / BD-082
- `check_pack_agent_trinity()` Check 14 (`scripts/validate-pack.py:714-806`) — pack-agent files appear in all three CLI directories
- `check_agent_count()` Check 5 (`scripts/validate-pack.py:337-381`) — three-tool agent parity (file count + name correspondence)
- `check_help_fragment_tracker_byte_identity()` Check 24 (`scripts/validate-pack.py:1865-1890`) — HELP-FRAGMENT-TRACKER.md byte-identity between pack and project copies (per BD-077)

### 7.B — Codex

**Pack-side agent files:** `.codex/agents/pack-*.toml` (5 files) — content mirrors `.claude/agents/pack-*.md` per trinity per `PACK-AGENTS.md:170-176`.

**Client-side agent files:** `project-template/.codex/agents/{architect,coder,reviewer,…}.toml` (16 files) — TOML format; content equivalent to `.claude/agents/*.md` per trinity.

**Pack-side skill files:** `.codex/skills/{pack-startup,pack-help,documentation,commit-discipline,implementation-report,architecture-review,dependency-intake,planning,review,verification-harness}/SKILL.md` — same content as Claude pack-root mirrors per per-CLI parity.

**Client-side skill files:** `project-template/.codex/skills/{pm-startup,pack-help}/SKILL.md` per the directory listing; rest of skills consumed via `.claude/skills/` and `.codex/skills/` runtime copies populated by init-project.sh.

**Trinity:** Codex CLI loads `AGENTS.md` at pack-root or project-root; trinity rule applies (Pack memory § Trinity rule mirrored across the three files).

**Per-CLI parity:** Same checks as Section 7.A (validate-pack.py).

### 7.C — Gemini

**Pack-side agent files:** `.gemini/agents/pack-*.md` (5 files) — markdown with YAML frontmatter per Gemini's native subagent format (per `CHANGELOG.md:425-431` BD-043 description: "Markdown with YAML frontmatter: name, description, model, temperature, max_turns").

**Client-side agent files:** `project-template/.gemini/agents/{architect,coder,reviewer,…}.md` (16 files) — same format.

**Pack-side skill / command files:** `.gemini/commands/pack-startup.toml`, `.gemini/commands/pack-help.toml` — TOML format. Gemini-side "skills" live under `.gemini/commands/` per directory listing.

**Client-side command files:** `project-template/.gemini/commands/pm-startup.toml`, `project-template/.gemini/commands/pack-help.toml`.

**Trinity:** `GEMINI.md` at pack-root and project-template.

**Per-CLI parity:** Same validate-pack checks as Section 7.A (the parity check is symmetric across CLAUDE / Codex / Gemini per BD-043 + BD-076 + BD-082).


---

## Section 8 — v10 → v11 migration touch points

### Direct stream-file handling

| Stream | Handled by | Location | Notes |
|---|---|---|---|
| IMPLEMENTATION-PLAN.md | Stage S4a rename | `scripts/migrate-v10-to-v11.sh:151-218` | BD-104 cross-pack rename: `IMPLEMENTATION_PLAN.md` (underscore, v10 form) → `IMPLEMENTATION-PLAN.md` (hyphen, v11 form). Uses `git mv` with fallback to plain `mv` for untracked. Both-exist conflict fails the stage (`:188-194`). Post-rename verification at `:217`. |
| BACKLOG.md | Customization-preserve via surface manifest | `scripts/lib/migrator-core.sh:483,499` | Listed in both v10 and v11 customization surface manifests emitted by `migrator_target_surface_for_version()`. Treated as one of the 12 file-class protected files per BD-088. Pack-side and project-side both. |
| CHANGELOG.md | Not migrated | n/a | Not in the customization surface manifest at `scripts/lib/migrator-core.sh:474-506`. User-owned content; migrator does not write. |
| STATUS.md | Not migrated | n/a | Not in the customization surface manifest. User-owned content. |

### Other v11-specific files added by the migrator

Per `scripts/lib/migrator-core.sh:486-506` (the v11 surface manifest
adds these to the v10 surface):

- `docs/pack/HELP-FRAGMENT.md`
- `tracker.toml.example`
- `.github/ISSUE_TEMPLATE/work-item.yml`
- `.claude/skills/pack-help/SKILL.md`
- `.codex/skills/pack-help/SKILL.md`
- `.gemini/commands/pack-help.toml`

These are not stream files but they ride along the migration via the
same customization-preserve framework.

### Customization-preserve interaction (BD-088)

Per `CHANGELOG.md:44-51` (BD-088 description) and the surface manifest
above:

- 12 file classes; 8 canonical disposition tokens
- Single-slot sidecars (`.v10-customized` for migrator,
  `.pre-update` for `init-project.sh --update`)
- Truthful report (every file accounted for; no silent drops)
- Per-file customization-preservation matrix in
  `supporting-docs/MERGE-STRATEGY.md` (BD-094 — `CHANGELOG.md:72-73`)

Per `OPTIONAL-FEATURES.md:202-211`, the same customization-preserve
disposition (`customization-detected-needs-reconciliation`) is used
by the tracker migration when forward/reverse encounters a file with
both project-side and pack-side edits.

### Migrator framework (BD-119)

Per `CLAUDE.md:35-40`: "Migrator framework (BD-119). When authoring
a new `scripts/migrate-vN-to-vM.sh`, source
`scripts/lib/migrator-core.sh` and supply the adapter contract
(`MIGRATOR_*` vars + the hook functions). See
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` for the
contract. Do NOT copy `scripts/migrate-v10-to-v11.sh` and rewrite —
that regresses the framework."

The contract structure means any per-entry shape that affects
migration would need:

1. A new MIGRATOR-stage hook (per `scripts/lib/migrator-stages.sh`)
   if the per-entry layout differs from v11 layout.
2. An updated `migrator_target_surface_for_version()` entry
   (`scripts/lib/migrator-core.sh:471-510`) listing whatever new
   files the per-entry shape introduces.
3. A BD-088 customization-preserve disposition for the new files.

### Migrator skill-rename helper (BD-147)

Per `CHANGELOG.md:178-184`: BD-147 extracted BD-035 rename helper into
`scripts/lib/migrator-skills.sh` (`migrator_skill_rename` API).
Not stream-related but relevant context for the framework.

---

## Section 9 — Setup-path touch points

### scripts/init-project.sh

Direct grep at HEAD: no references to BACKLOG.md / STATUS.md /
CHANGELOG.md / IMPLEMENTATION-PLAN.md.

Streams are created by the developer / PM chat per
`supporting-docs/METHODOLOGY.md:1408` ("Create BACKLOG.md, STATUS.md,
CHANGELOG.md (empty with structure)"). The init-script orchestrates:

- Stage S6 copies INSTALL-PROCEDURES.md (`CHANGELOG.md:313-315`)
- Stage S3 copies `.gemini/.env`, `.gemini/settings.json`,
  `.codex/config.toml.example` (`CHANGELOG.md:339-347`)
- Stage S11 in v11 mode adds v11 client artifacts (per BD-080,
  `CHANGELOG.md:52-54`); the v11 client artifacts include
  `tracker.toml.example` and the issue-template forms

PM chat kickoff prompt emitted at end-of-run (per
`CHANGELOG.md:361` BD-044 description).

### supporting-docs/SETUP-NEW.md

Direct grep at HEAD: 1 reference — `:392` `IMPLEMENTATION-PLAN.md` in
context "the architect writes these files as its output".

No direct mention of BACKLOG / STATUS / CHANGELOG creation steps —
these are referenced via METHODOLOGY pointers and INSTALL-PROCEDURES
Procedure 7 auto-discovery (per `CHANGELOG.md:367-373` BD-047
description).

### supporting-docs/SETUP-EXISTING.md

Direct grep at HEAD: 1 reference — `:219` "Historical `CHANGELOG.md`
entries" in the existing-project context.

Otherwise stream-neutral; the SETUP-EXISTING path is primarily about
auditing what exists vs. what the pack expects.

### supporting-docs/CLI-PM-SETUP.md

Direct grep at HEAD: 6 references (per Section 1.E above) —
`:119,146,147,157,178,179,240`. These are PM-chat-startup-related,
not setup-of-stream-files-related. Streams are referenced as
required-reading for `/pm-startup`, not as files to create at setup.


---

## Section 10 — Open observations

Anomalies, inconsistencies, or curiosities noticed during the walk —
without proposing fixes.

1. **BACKLOG.md preamble references a section that doesn't match by
   exact name.** `BACKLOG.md:5` says "Format follows the standard
   BACKLOG item format from METHODOLOGY.md Part 7." The METHODOLOGY
   sub-heading is "BACKLOG item format" at
   `supporting-docs/METHODOLOGY.md:1030`, not "standard BACKLOG item
   format". The intended reference is unambiguous in context but the
   prose phrasing implies a more specific heading. Pack-self uses
   BD-NNN identifiers while METHODOLOGY documents TD-NNN — this is a
   documented inheritance, but the inheritance lives only in the
   prose-line at `BACKLOG.md:5`, not in a separate cross-namespace
   rule.

2. **`tracker.toml.example` rename per BD-135.** Files at HEAD:
   - Pack root: `tracker.toml.pack-example`
   - Project-template: `project-template/tracker.toml.project-example`
   - Test fixtures: `test-fixtures/v11-flat-file/tracker.toml.example`,
     `test-fixtures/v11-tracker-on/tracker.toml`, `…/tracker.toml.example`
   - `scripts/lib/migrator-core.sh:501` still lists
     `tracker.toml.example` (without the `-pack-` or `-project-`
     qualifier) in the v11 customization surface manifest.
   - `OPTIONAL-FEATURES.md:156-161` describes the pack-side example
     template as installed by `init-project.sh` at v11 as
     `tracker.toml.example` at the client project root — implying the
     installed name lacks the `-pack-` / `-project-` qualifier even
     though the source-tree templates have the qualifier. This is the
     post-BD-135 designed asymmetry between source-tree filename and
     installed filename, and the migrator surface manifest references
     the installed name not the source-tree name.

3. **No client-template mirror of `.github/ISSUE_TEMPLATE/` at HEAD.**
   The BD-063 BACKLOG entry (`BACKLOG.md:76-87`) names
   `project-template/.github/ISSUE_TEMPLATE/` mirrors as part of the
   File/Symbol set, but `find … -name ISSUE_TEMPLATE -type d` returns
   only the pack-root copy. Either the client template installs to
   `<client-repo>/.github/ISSUE_TEMPLATE/` at runtime via
   init-project.sh / migrate-v10-to-v11.sh (not via a checked-in
   `project-template/.github/` directory), or the BD-063 File/Symbol
   set names a planned location not yet realized. The architect
   should resolve which.

4. **No `STATUS.md` exists in the pack repo.** Pack-self treats STATUS
   as a non-stream — there is no Phase Completion / Current Phase /
   Key Metrics dashboard for pack-development work. The closest
   equivalent is the `## Active — v11 Scope` / `## Active — v10 Scope`
   / `## Deferred` partitioning inside `BACKLOG.md` itself. If
   per-entry shape adds a STATUS-like dashboard requirement, the
   pack-self side has no pre-existing structure to extend.

5. **STATUS.md write rules cite "the chat" not "the agent."** Per
   `project-template/docs/pack/PM-CHAT.md:204-209` and METHODOLOGY
   Part 9 (`:1321`), STATUS.md is written exclusively by the PM
   chat. No coder, reviewer, planner, or auditor agent writes STATUS.
   The reverse-emit step in tracker mode is the only programmatic
   writer (`scripts/lib/tracker-migrate-reverse.sh:513-545`).

6. **CHANGELOG reverse-emit is a stub.** The tracker reverse
   migration writes a CHANGELOG.md skeleton with the disclaimer "This
   CHANGELOG was reverse-emitted from the tracker" (per
   `scripts/lib/tracker-migrate-reverse.sh:547-562`). The real
   audit-log walking is deferred per the BD-067 resolved note
   (`BACKLOG.md:143`) because no `provider_events` operation exists
   in BD-060. If per-entry shape proposes a richer CHANGELOG model,
   it must account for this deferral.

7. **Round-trip property has a documented gap that auto-flips.**
   BD-068 (`BACKLOG.md:157`) notes that comment-fallback blockers do
   not round-trip; this auto-flips to a positive check when BD-111
   closes. BD-111 is carried over from v11.0 (`CHANGELOG.md:119-120`).
   Per-entry shape decisions touching Blockers / Unblocks should be
   aware that the round-trip guarantee is provisional.

8. **STATUS reads use trinity-resolver framing; STATUS writes use
   direct file path.** `pm-startup` Step 2
   (`project-template/skills/pm-startup/SKILL.md:69-87`) resolves
   STATUS reads through the trinity `## Document locations` table.
   The `backlog-status-update` variant
   (`project-template/docs/pack/prompts/pm-chat.md:127`) writes
   directly to "BACKLOG.md and/or STATUS.md only" with no trinity
   resolver. This asymmetry is consistent with the dashboard model
   (writes are always to the flat file; tracker-mode reads go through
   the resolver because the flat file is a mirror).

9. **Recommendation signals diverge in count.** Pack-side computes 4
   numeric signals (`bd_count_active`, `bd_count_total`,
   `backlog_kb`, `backlog_growth_30d` — `scripts/lib/recommendation.sh:141-142`).
   Client-side computes 7 (`td_count_active`, `td_count_total`,
   `backlog_kb`, `phase_count`, `implementation_plan_kb`,
   `td_tbd_comment_count`, `typed_deferral_count` — `:173-174`).
   The CHANGELOG description (`CHANGELOG.md:32-33`) says "Pack-side 3
   signals + client-side 6 signals" — the live count is 4 and 7
   respectively. Not a defect, just count-drift in the prose.

10. **BACKLOG.md `## Resolved — v8 (March 2026)` section coexists
    with the pack-memory rule "BACKLOG.md has no Resolved section".**
    The pack-memory rule (`CLAUDE.md:157-159`) says entries resolve
    in place. The Resolved section at `BACKLOG.md:2214` is
    historical — entries from v8 that were resolved before the rule
    was codified. New entries flip status in place. The architect
    should be aware the file contains a transitional artifact.

11. **`detect.sh` is the pack-vs-client discriminator.** Every
    downstream behavior branches on `detect_pack_path()` which sniffs
    for `^**BD-` vs `^**TD-` in `BACKLOG.md` (`scripts/lib/detect.sh:23-35`).
    A per-entry shape that changes the entry-line format (no longer
    `**BD-NNN ` at line start) would break this discriminator. The
    `pack-help.sh:33` heuristic has the same dependency.

12. **CLAUDE.md / AGENTS.md / GEMINI.md trinity at pack-root has no
    `## Document locations` section.** Confirmed by grep negative.
    The exemption is documented in BD-062 (`BACKLOG.md:67-71`,
    "Pack-repo trinity is exempted by D-6 (no `## Document
    locations` section there)"). Pack-self pack-root trinity carries
    "Key files to read" lists instead (`CLAUDE.md:28-33`).

13. **PACK-FEEDBACK.md is project-only and is not one of the four
    streams.** METHODOLOGY Part 10 covers it
    (`supporting-docs/METHODOLOGY.md:1348-1393`); it lives at
    `docs/pack/PACK-FEEDBACK.md` (`supporting-docs/METHODOLOGY.md:1382`).
    Multiple agent files prohibit writing to it
    (`coder.md:81`, `repo-ops.md:69-70`, etc.). It is append-only and
    PM-chat-owned. The previous architect pass may have conflated it
    with the four streams; this inventory keeps it out of scope
    because the brief defines only BACKLOG / STATUS / CHANGELOG /
    IMPLEMENTATION-PLAN as in-scope streams.

14. **The 18-operation `provider_*` API is not enumerated in
    `OPTIONAL-FEATURES.md`.** Per `OPTIONAL-FEATURES.md:130-131`,
    "Other backends (Forgejo / Linear / Jira) plug in via the
    TrackerProvider abstraction in `scripts/lib/tracker-provider.sh`
    but are not implemented in v11." The op list lives only in
    `scripts/lib/tracker-provider.sh` and the BD-060 entry
    (`BACKLOG.md:33-44`). The architect should cite the script
    directly for the full op surface.

15. **`location_backlog`/`location_status`/`location_changelog` keys
    in `tracker.toml` are bare filenames.** Per
    `tracker.toml.pack-example:36-39` and
    `project-template/tracker.toml.project-example:36-43`: "Bare
    names; trinity ## Document locations resolves to actual paths."
    The trinity table is the authoritative path resolver, not the
    tracker.toml entries. This is the central design symmetry between
    flat-file mode and tracker mode — both modes use the trinity for
    path resolution. Any per-entry shape change must respect this.

16. **The BD-088 customization surface manifest does NOT include
    CHANGELOG.md or STATUS.md.** Per `scripts/lib/migrator-core.sh:474-506`
    only BACKLOG.md is listed among the 4 streams. STATUS / CHANGELOG /
    IMPLEMENTATION-PLAN are entirely user-owned and not preserved by
    the migrator. This is consistent with the "user-owned content"
    role of those three files (pack does not ship templates for them
    beyond METHODOLOGY-described structure).

---

TOUCH-POINT-INVENTORY-COMPLETE: 2026-05-12 — Comprehensive read-only enumeration of every pack-repo file that touches BACKLOG / IMPLEMENTATION-PLAN / CHANGELOG / STATUS streams, with file:line citations, pack-vs-client divergence per stream, STATUS dashboard verification, v11 tracker form-family enumeration, RAG manifest surface, full embedded-rules inventory (Sections 6.A-6.I), per-CLI agent/skill rosters, v10→v11 migration touch points, setup-path references, and 16 open observations.
