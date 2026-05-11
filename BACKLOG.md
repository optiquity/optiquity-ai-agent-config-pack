# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.
Items use BD-NNN identifiers (pack backlog) rather than TD-NNN (project backlog).
Format follows the standard BACKLOG item format from METHODOLOGY.md Part 7.

---

## How to use this file

- Reference items in commit messages: `feat: v9 — BD-020 description`
- When an item is resolved, set Status: Resolved with the commit hash and date
- To cancel or deprecate an item: set Status to Cancelled or Deprecated, add a
  Resolution field with date, disposition (cancelled|deprecated), and brief rationale.
  Then review all items that listed this item as a blocker — they require human
  judgment, not automatic unblocking
- Items deferred to a future version: set Blockers to the target version
- New items get the next available BD-NNN number
- This file ships in the repo so agents can read it and understand current scope

---

## Active — v11 Scope

The v11.0 implementation surface. 53 BD entries (BD-060..BD-112)
derived from the planning corpus at `maintenance-docs/v11-research/`
(IMPLEMENTATION-PLAN.md + four addenda; ARCHITECTURE-V3.3-DELTA.md is
the live design). Sequencing per merged §3.3 commit order. See the
plan docs for full Verification + Definition-of-Done per BD.

---

**BD-060 — TrackerProvider abstraction skeleton + GH backend implementation**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `scripts/lib/tracker-provider.sh`, `scripts/lib/tracker-provider-gh.sh`, `scripts/tests/tracker-provider-test.sh`
Description: Lands the OQ-1 surface — the 18-operation provider library every
  other tracker BD calls. GH-backend implementation; capability flags per V1
  §2.7.2; error model per V1 §2.5; pagination per V1 §2.6. Includes the
  `gh-sub-issue` extension policy and the GraphQL preview-header policy.
  The `raw(...)` escape hatch (V1 §2.1) is required.
Resolved: 2026-05-05 — TrackerProvider abstraction + GH backend (18 ops + raw + capabilities); 65/65 tests; CI green.

---

**BD-061 — `tracker.toml` schema + detection helper + gitignore entry**
Type: TODO(version)
Status: Resolved
Blockers: BD-060
Unblocks: None
File/Symbol: `scripts/lib/tracker-config.sh`, `tracker.toml.example`, `project-template/tracker.toml.example`, `.gitignore`, `project-template/.gitignore`
Description: Resolves D-2 + D-5 + R16. Detection is "presence + content of
  `tracker.toml`": no file = flat-file; `mode.state = "flat-file"` = flat-file;
  `mode.state = "tracker"` = tracker. Adds `.pack-tracker/` to `.gitignore`
  per V1 §3.4.
Resolved: 2026-05-05 — tracker.toml schema + detection helper + .pack-tracker gitignore; tracker_mapping_file convenience getter added in 62a3465 review fix; 32/32 tests; CI green.

---

**BD-062 — Trinity `## Document locations` Source column extension (D-6)**
Type: TODO(version)
Status: Resolved
Blockers: BD-061
Unblocks: None
File/Symbol: `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (trinity-replicated; project-template trinity only per D-6 footnote)
Description: Extend the `## Document locations` table per V1 §3.3 with a
  Source column ("flat" | "tracker" | "mixed") so `pm-startup` Step 2 can
  branch by source. Pack-repo trinity is exempted by D-6 (no `## Document
  locations` section there).
Resolved: 2026-05-06 — Source column added to all 3 project-template trinity files (CLAUDE.md / AGENTS.md / GEMINI.md), trinity-replicated byte-identically. Values: docs/pack/=flat, docs/project/=`flat (or mixed in tracker mode)`, docs/reference/=flat. Brief explainer paragraph above the table documents what Source means and when docs/project/ flips to mixed (BACKLOG/STATUS/CHANGELOG/IMPLEMENTATION_PLAN tracker-mirrored; ARCHITECTURE.md stays flat). validate-pack Check 18 trinity H2 structure parity preserved. Pack-repo trinity exempted per D-6 footnote (no Document locations section). Unblocks BD-071's prompt-language change ("Read BACKLOG entries — resolve via trinity Document locations").

---

**BD-063 — Issue forms `work-item.yml` and `inbound.yml` (D-4-V2)**
Type: TODO(version)
Status: Resolved
Blockers: BD-061
Unblocks: None
File/Symbol: `.github/ISSUE_TEMPLATE/work-item.yml`, `.github/ISSUE_TEMPLATE/inbound.yml`, `.github/ISSUE_TEMPLATE/config.yml`, plus `project-template/.github/ISSUE_TEMPLATE/` mirrors
Description: Implements D-4-V2 + D-16 + D-17 + D-18. The form family routes
  by Type dropdown (bd / td / phase-epic-skeleton; phase-task-skeleton added
  by BD-106 extension). HTML-comment `template_version` marker + label per
  D-18. Both surfaces ship the same forms (TD-NNN namespace + Pack-feedback
  category on client side).
Resolved: 2026-05-05 — work-item + inbound + config forms (V2 §4 + V3.3 §6.1 4-option wi-type); validate-pack check_issue_template_forms; 78/78 tests; CI green (PyYAML CI fix in 5675b3f).

---

**BD-064 — Template-archive directory bootstrap + bd-v11.0 schemas**
Type: TODO(version)
Status: Resolved
Blockers: BD-063
Unblocks: None
File/Symbol: `maintenance-docs/v11-research/templates-archive/v11.0/{INDEX.md,bd-v11.0,td-v11.0,phase-epic-v11.0,phase-task-v11.0,inbound-v11.0,forms}`, `templates-archive/README.md`
Description: Implements P2 maintenance-ergonomics: template versions archived
  at every minor cut so `pack tracker update-templates` and reverse-migration
  sidecar (V1 §6.6.1 / DELTA §3) can deterministically translate. Phase-task
  schema added by BD-106 extension.
Resolved: 2026-05-05 — template archive bootstrap (5 entry-type SCHEMAs incl. phase-task-v11.0 per V3.3; INDEX.md; frozen byte-equal forms); validate-pack informational check_template_archive_v11; CI green. Path layout per V3.3 §6.5 (templates-archive/v11.0/&lt;entry-type&gt;-v11.0/), superseding original IMPLEMENTATION-PLAN flat layout.

---

**BD-065 — `tracker-migrate.sh forward` + idempotency markers + checkpoint**
Type: TODO(version)
Status: Resolved
Blockers: BD-060, BD-061, BD-063
Unblocks: None
File/Symbol: `scripts/tracker-migrate.sh`, `scripts/lib/tracker-migrate-forward.sh`, `.pack-tracker/id-map.json`, `.pack-tracker/forward.checkpoint.json`, `scripts/tests/tracker-migrate-forward-test.sh`
Description: Forward migration with body-footer idempotency markers
  (`<!-- pack-id: TD-NNN -->`); reads BACKLOG / IMPLEMENTATION-PLAN; creates
  issues; resolves blockers / sub-issues; writes mapping file; regenerates
  mirror files. Checkpoint per V1 §6.4. `forward` and `status` subcommands
  in this BD; `reverse` lands in BD-067.
Resolved: 2026-05-05 — V1 §6.2 11-step forward orchestrator + parser + mapping/checkpoint helpers + body composer + read-only mirror header + label set + tracker.toml updater. Review fixes in bab5122 (findings #1, #2, #3, #5, #7 from PACK-REVIEW-BD065): three-marker idempotency probe (incl. body-footer marker via provider_get), File/Symbol body field round-trip, Python-rewritten mirror regen for byte-stable output, partial-write surfacing per V1 §9.6, per-entry mapping save. 93/93 tests; CI green. Phase-task parser (BD-106) + cross-entity dependency module (BD-108) extend later.

---

**BD-066 — `pack tracker init` wrapper + label / template ensure step**
Type: TODO(version)
Status: Resolved
Blockers: BD-065
Unblocks: None
File/Symbol: `scripts/pack-tracker.sh`, `scripts/lib/tracker-labels.sh`, `scripts/lib/tracker-init.sh`, `scripts/tests/tracker-init-test.sh`
Description: Lands `pack tracker init` as the one-command opt-in path.
  Includes auth validation per V1 §7.3 + D-10 (`gh auth status`). Adds verb
  dispatcher per V2 §22.1. Auth-missing surfaces actionable error per V1 §9.3.
Resolved: 2026-05-06 — `pack tracker init` flag-driven orchestrator (V1 §6.1 5 steps), 45-label canonical set + idempotent ensure, V2 §22.1 verb dispatcher (init/status/mirror-rebuild live; 4 placeholders pointing at owning BDs), surface auto-detection (PACK-CHAT.md vs docs/pack/), opted_in_at preservation across re-runs. Includes BD-065 ride-along fixes #10 (--mirror-only flag on tracker-migrate.sh forward) and #12 (8-field V2 §22.1 status report). 73/73 BD-066 tests + 105/105 BD-065 tests (was 93); validate-pack clean. Interactive dialogue (V1 §6.1 step 1) lands as immediate fast-follow.

---

**BD-067 — `tracker-migrate.sh reverse` + sidecar (V1 §6.6 + §6.6.1, A2)**
Type: TODO(version)
Status: Resolved
Blockers: BD-064, BD-065
Unblocks: None
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh`, `scripts/lib/tracker-sidecar.sh`, `scripts/lib/tracker-mirror.sh`, `scripts/tracker-migrate.sh`, `scripts/pack-tracker.sh`, `scripts/tests/tracker-migrate-reverse-test.sh`
Description: Reverse migration is mandatory per `DESIGN-BRIEF.md` §3.1.
  Sidecar coverage extended per DELTA A2 to include template-version drift
  fields. `pack tracker disable` runs reverse + flips `tracker.toml
  mode.state` to `flat-file`; `pack tracker doctor` reports mapping integrity.
Resolved: 2026-05-06 — V1 §6.5 9-step reverse orchestrator + per-entry reconstruction (status/type/scope/severity from labels; Description/Context/File-Symbol from H2 sections; Blockers from sub-issue parent + comment markers; Unblocks computed by inverting Blockers across the dataset). V1 §6.6 + §6.6.1 sidecar with extra_fields/template_version/template_archive_path shape (extra_fields empty at v11.0; v11.x-only fields populate it). V1 §6.5 step 8 mirror-header strip refactored into shared scripts/lib/tracker-mirror.sh (forward+reverse share the helper). `pack tracker disable` and `pack tracker doctor` verbs wired (replaced BD-067-pending placeholders). 65/65 BD-067 tests; full sweep 492/492. Audit-log walking for CHANGELOG.md step 7 deferred (provider_events op not in BD-060). Reactions/attachments fetch deferred for sidecar (placeholders ship; ride-along to future BD). Capability re-probing in doctor deferred. Newline-eating regex bug in BD-065's _tmf_update_tracker_toml fixed (caught by BD-067's mode-flip test).

---

**BD-068 — Round-trip test fixture + multi-template-version coverage**
Type: TODO(version)
Status: Resolved
Blockers: BD-067
Unblocks: None
File/Symbol: `scripts/tests/tracker-migrate-roundtrip-test.sh`, `scripts/tests/fixtures/roundtrip/bd-v11.0/`, `scripts/tests/fixtures/roundtrip/bd-v11.1/`, `scripts/tests/fixtures/roundtrip/bd-v11.2/`
Description: Implements V1 §6.7 + V3 §I.1 explicit round-trip test. v11.0
  ships with bd-v11.0 entries plus stub directories for bd-v11.1 / bd-v11.2
  per §6.A maintainer check. CI runs forward → reverse → forward; diff = 0
  (whitespace-tolerant). Extended by BD-106 with phase-task fixtures.
Resolved: 2026-05-06 — Stateful fake-gh test harness maintains an in-memory tracker state across forward/reverse invocations (next-id counter + issues map + create-call signature log). bd-v11.0 fixture (3 entries: BD-001 Open, BD-002 Unblocked-with-blocker, TD-010 Open + 2 phase epics); bd-v11.1 and bd-v11.2 stub directories with READMEs documenting fill-in-when-shipped contract. Round-trip property verified: F→R reconstructs 3 entries with status/title/file-symbol/description preserved (whitespace-tolerant); F→R→F produces byte-equivalent tracker create-call signature (sorted titles+labels). Sidecar extra_fields shape ready for v11.x (5 entry sections, all empty at v11.0 — readiness guard for v11.1+ template-field additions). Multi-template-version stub directories present (per V1 §6.6.1 readiness). 39/39 BD-068 tests; full sweep 531/531; validate-pack clean. Documented gap: comment-fallback blockers (BD-111 deferral) do not round-trip — auto-flips to positive check when BD-111 closes.

---

**BD-069 — `template_version` HTML-comment + label dual carrier (D-18)**
Type: TODO(version)
Status: Resolved
Blockers: BD-064, BD-065, BD-067
Unblocks: None
File/Symbol: `scripts/lib/template-version.sh`, `scripts/lib/template-translations.sh`, `scripts/pack-tracker.sh`, `scripts/tests/template-version-test.sh`, `scripts/tests/template-translations-test.sh`, `scripts/tests/fixtures/template-versions/`, `scripts/lib/tracker-sidecar.sh` (ride-along)
Description: Implements D-18 dual carrier. `<!-- template_version: bd-v11.0 -->`
  HTML comment in body + parallel `template:bd-v11.0` label. `update-templates`
  subcommand reads stale carriers, applies V2 §19.3 patch semantics + §19.4
  translation rules. Phase-task entry added to carrier matrix by BD-106
  extension.
Resolved: 2026-05-06 — D-18 dual-carrier read/reconcile lib (template_version_read_body / read_label / reconcile / extract_version_dir / archive_path) + V2 §19 update-templates infra (template_translations_load + resolve_chain handling 2-version-skip per §19.4 line 810 + apply_rules per §19.3 patch semantics: field-renamed/added/removed/label-renamed). pack-tracker.sh cmd_update_templates wires the V2 §19.2 5-step verb (--dry-run / --apply / --scope / --manifest flags). Reads form-level template_version from .github/ISSUE_TEMPLATE/ markers; production manifest empty at v11.0 (no v11.x shipped yet) so verb reports "no upgrades available"; synthetic v11.0→v11.1 + v11.1→v12.0 fixture under scripts/tests/fixtures/template-versions/ exercises the chain resolver and apply_rules end-to-end. Ride-along: PACK-REVIEW-BD066-068 Finding #7 closed via _tmsc_extra_fields_for_entry extension hook in tracker-sidecar.sh (default emits the v11.0 empty-state notice; future BDs redefine to populate). 80 new tests (36 template-version + 44 template-translations); full sweep 616/616; validate-pack clean. Reviewer's other co-land items #5 (doctor surface incomplete) and #8 (sidecar reactions/attachments/audit_log placeholders) deferred — both need provider ops not yet defined.

---

**BD-070 — Typed error surfacing + diagnostic helper**
Type: TODO(version)
Status: Resolved
Blockers: BD-060
Unblocks: None
File/Symbol: `scripts/lib/tracker-errors.sh`, `scripts/tests/tracker-errors-test.sh`
Description: Implements D-7. Central error formatter; maps the 9 typed codes
  from V1 §2.5 to user-facing messages + next-step verb (Layer 2 per V3
  §27.1). No silent retry; every failure surfaces typed code + diagnostic +
  next-step verb. Every error message ends with "→ Run: pack X".
Resolved: 2026-05-05 — typed-error formatter covering all 10 V1 §2.5 codes (incl. partial-write); V1 §9 message shapes via caller-supplied context lines; V3 §27.1 Layer 2 verb table. Verb-table V3 §27.1 conformance fix in 62a3465 (single unambiguous verb per code, no parenthetical alternatives). Existing inline emit_error stubs in tracker-provider.sh and tracker-config.sh unified. 56/56 tests; backward-compat with BD-060/-061 first-line ERROR/MESSAGE format preserved; CI green.

---

**BD-071 — Agent read-pattern adaptation (D-9, V1 §8 + V1 §13)**
Type: TODO(version)
Status: Resolved
Blockers: BD-062, BD-070
Unblocks: None
File/Symbol: `project-template/docs/pack/prompts/{tester,pm-chat}.md`, `scripts/lib/tracker-agent-read.sh`, `scripts/tests/tracker-agent-read-test.sh`
Description: Implements D-9 LCD agent reads. Replaces "Read BACKLOG.md"
  with "Read BACKLOG entries (resolve via trinity Document locations)" across
  10 per-agent prompt files. Agents use `gh issue view --json …` shell-out
  when tracker mode is on. validate-pack Check 22 catches drift.
Resolved: 2026-05-06 — Per V1 §8.4/§8.5 prompt-language change applied to the prompt files that actually carry "Read BACKLOG.md" / "Read STATUS.md" instructions: tester.md required-reading line, pm-chat.md (2 places: project-documents-in-context list + state-change-recording required-reading line). Other 8 prompt files (architect, auditor, coder, docs-researcher, grpc-schema, planner, repo-ops, reviewer) audited — they reference BACKLOG/STATUS only in write-prohibition or concept contexts; no language change needed per V1 §8.5 narrow rule (only "Read X.md" → trinity-resolver). New scripts/lib/tracker-agent-read.sh provides the LCD agent read path per V1 §8.1 — mode-agnostic: flat-file mode greps BACKLOG.md mirror; tracker mode resolves pack-id via mapping file then provider_get. Both sourceable (tracker_agent_read_entry function) and direct-executable (`bash scripts/lib/tracker-agent-read.sh BD-001 [<repo>]`). 29/29 tests in 4 groups (mode detection, flat-file read, tracker-mode read with mocked gh, direct-execution entrypoint). Full sweep 645/645; validate-pack clean.

---

**BD-072 — `scripts/lib/recommendation.sh` + state-file schema (D-19)**
Type: TODO(version)
Status: Resolved
Blockers: BD-061
Unblocks: None
File/Symbol: `scripts/lib/recommendation.sh`, `scripts/tests/recommendation-test.sh`, `.pack-tracker/recommendation-state.json` (schema)
Description: Lands the OQ-19 mechanism. Signal computation per V3 §28.1.1
  (3 signals pack-side; 6 client-side); state I/O for state file per V3
  §28.1.4 schema; `should_recommend()` test per V3 §28.1.5; prompt rendering
  per V3 §28.1.7. State file is JSON v1 schema; lazy-created with default
  values; failure-mode UX per V3 §28.1.4 (parse fail → log warning + write
  fresh state + defer recommendation to next session). All 7 V3 §28.1.10
  tests must pass.
Resolved: 2026-05-07 — V3 §28.1 lib end-to-end. recommendation_compute_signals (3 pack / 6 client) + state I/O (default / corrupt-recover / atomic save) + 5-guard should_recommend with 25%-growth Guard 4 + prompt rendering with human-label substitution per §28.1.7. 53 tests in scripts/tests/recommendation-test.sh covering the V3 §28.1.10 7-test surface. Bash 3.2 compatible. Review fix-follow added docs/project/ BACKLOG fallback (BLOCKER F-1), human-label headline (was raw JSON keys), well-formed "Also past threshold" follow-up. Sweep 754/754; CI green.

---

**BD-073 — `pack tracker enable-recommendations` subcommand**
Type: TODO(version)
Status: Resolved
Blockers: BD-072
Unblocks: None
File/Symbol: `scripts/pack-tracker.sh`
Description: Adds `enable-recommendations` subcommand per V3 §28.1.9 +
  D-19 verb table. Sets `persistent_refusal: false`; increments
  `user_re_enable_count`. Colloquial "remind me about the tracker again"
  routes through it. v11.0 ships the verb wired into the dispatcher
  (`cmd_enable_recommendations`) emitting a typed `not-implemented`
  error so V2 §22.1's "Required for v11?" row is rationalized — the
  surface is reachable; the body lands here and depends on BD-072's
  threshold-driven Layer 3 state file
  (`.pack-tracker/recommendation-state.json`, V3 §27.3 / §28.1.6).
Resolved: 2026-05-07 — cmd_enable_recommendations replaces v11.0 not-implemented stub (V3 §28.1.6 / D-19); flips persistent_refusal=false + increments user_re_enable_count via BD-072's recommendation_set_persistent_refusal helper. Surface auto-detected (PACK-CHAT.md / docs/pack/) with --surface override; --repo-root override. Idempotent. Group 5 verb integration tests cover seeded-true→false flip, idempotent re-run, and create-from-default path.

---

**BD-074 — `pack-startup` Step 8 + `pm-startup` Step 8 (D-19 integration)**
Type: TODO(version)
Status: Resolved
Blockers: BD-072, BD-073
Unblocks: None
File/Symbol: `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`, `.gemini/commands/pack-startup.toml`, `project-template/skills/pm-startup/SKILL.md` + 3 distributed copies
Description: Step 8 runs after V1's Step 7 triage queue: source
  `recommendation.sh`; compute signals; check state; call `should_recommend`;
  if true, render the V3 §28.1.7 prompt. Trinity-replicated × 2 surfaces.
  Body content byte-identical across the three CLIs in each surface; framing
  differs as the per-CLI format mandates. Introduces `.claude/`, `.codex/`,
  `.gemini/` directories at pack-root for the first time per §6.F.
Resolved: 2026-05-07 — Step 8 (Inflection-point recommendation check) appended to 7 startup files: pack-side × 3 (.claude/skills/pack-startup/SKILL.md, .codex/skills/pack-startup/SKILL.md, .gemini/commands/pack-startup.toml) + client-side × 4 (project-template canonical + 3 distributed copies). Body sources scripts/lib/recommendation.sh, computes signals, calls should_recommend, renders prompt + records show on true; routes user response per V3 §28.1.7 (yes / not now / don't ask again). Step numbering preserves the gap at 5–7 (V1 §10.2 tracker-mode triage queue lands later) — fix-follow added explanatory HTML-comment banner in all 7 files. Pack-root .codex/skills/pack-startup/ and .gemini/commands/ directories created.

---

**BD-075 — `scripts/pack-help.sh` LCD shell verb + surface detection**
Type: TODO(version)
Status: Resolved
Blockers: BD-076
Unblocks: None
File/Symbol: `scripts/pack-help.sh`, `scripts/lib/detect.sh` (extended with `detect_pack_surface`)
Description: Implements LCD floor for D-20 / OQ-20 (M2 path). Reads the
  appropriate `HELP-FRAGMENT-*.md` and prints to stdout. Inlines the shared
  `HELP-FRAGMENT-TRACKER.md` per V3 §28.2.4 + DELTA L1 (sibling-file include).
  Surface detection for pack vs client per V3 §28.2.3. Output ~400 tokens
  per V3 §28.2.3. Ships new at v11 per §6.B.
Resolved: 2026-05-07 — scripts/pack-help.sh + detect_pack_surface() added to scripts/lib/detect.sh. Surface auto-detection per V3 §28.2.3 covering all 5 cases (BD/TD/mixed/none/legacy-root). awk-based sibling-include resolver replaces tracker-fragment placeholder line per V3 §28.2.4 / DELTA L1, preserving surrounding content. Flags --surface override, --root, --help. 17 tests in scripts/tests/pack-help-test.sh. Review fix-follow trimmed verb-tables + dropped "Underlying script" subsection: pack-side render 5215 → 2946 chars (~841 tokens; 43% reduction). §28.2.3 ~400-token target not fully hit; partial improvement.

---

**BD-076 — HELP-FRAGMENT files (canonical + per-surface; L1 layout)**
Type: TODO(version)
Status: Resolved
Blockers: BD-066, BD-073
Unblocks: None
File/Symbol: `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md` (pack root canonical), `project-template/docs/pack/HELP-FRAGMENT.md`, `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (mirror)
Description: Implements D-20 + DELTA L1. Pack-root canonical is the single
  source of truth for the shared tracker section; client mirror is overwritten
  by `init-project.sh`. The two top-level fragments diverge in non-tracker
  sections per V3 §28.2.4. Check 24 (BD-082) verifies byte-identity.
  Addendum-4 §2.8 row scope at BD-076 ship: the two `pack td promote`
  rows (verb names stable per Addendum-4 §3.1) ship at BD-076.
  The `auditor-issue-tracking` row (client) and `pack-auditor` row
  (pack) are deferred to the BD-109 / BD-110 ship commits — those
  agents do not yet exist, so adding the rows now would forward-
  reference unshipped entities. Tracked in BD-109 / BD-110.
Resolved: 2026-05-07 — 4 HELP-FRAGMENT files: HELP-FRAGMENT-PACK.md (pack-root), HELP-FRAGMENT-TRACKER.md (pack-root canonical, byte-identical mirror in project-template/docs/pack/), project-template/docs/pack/HELP-FRAGMENT.md (client). Per-surface verb manifests per V3 §28.2.1 / §28.2.4 / §28.2.7. Review fix-follow added Addendum-4 §2.8 `pack td promote --to=phase-N` / `--to=phase-N.M` rows to client fragment; BD-109 `auditor-issue-tracking` and BD-110 `pack-auditor` agent rows deferred (those agents not yet shipped). Token-budget trim (~43% reduction); client-side Notes-block path issue closed; Notes references corrected to docs/pack/.

---

**BD-077 — Per-CLI `pack-help` command/skill (Trinity-replicated × 2 surfaces)**
Type: TODO(version)
Status: Resolved
Blockers: BD-075
Unblocks: None
File/Symbol: `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`, `.gemini/commands/pack-help.toml` (pack-side); `project-template/.claude/skills/pack-help/SKILL.md` + 2 per-CLI mirrors (client-side)
Description: Implements per-CLI namespaced `/pack-help` per D-20. All 6
  files invoke the same `scripts/pack-help.sh` via shell injection per V3
  §28.2.3 / §D.6 / §D.7. Trinity rule applies: all three per surface in
  lockstep. Codex form per V3 §7.1.1 corrected format (.codex/skills/pack-help/SKILL.md, NOT .toml).
  Note: the BD-077 commit message asserts `init-project.sh` installs
  `scripts/pack-help.sh` + `scripts/lib/` into the client project at
  install time. That wiring is BD-080 scope (still Open) — at the
  BD-077 ship commit those files are NOT yet copied by
  `init-project.sh`, so client-side `/pack-help` becomes functional
  only after BD-080 lands.
Resolved: 2026-05-07 — 6 per-CLI pack-help files (Trinity × 2 surfaces): Markdown SKILL.md for Claude/Codex per V3 §28.2.3 + §7.1.1 corrected format; TOML for Gemini per V3 §D.7. All 6 invoke scripts/pack-help.sh shell injection. Pack-root and client-tree per-CLI variants byte-equal at each (Claude/Codex/Gemini). Review fix-follow corrected client-side Notes-block paths from pack-only references (PACK-CHAT.md, bare QUICKSTART.md) to docs/pack/* paths. Note: client-side install gap (init-project.sh doesn't yet copy scripts/lib/ + pack-help.sh) closed by BD-080.

---

**BD-078 — validate-pack.py Check (`check_tracker_config`) (V1 §A.2)**
Type: TODO(version)
Status: Resolved
Blockers: BD-061
Unblocks: None
File/Symbol: `scripts/validate-pack.py`
Description: First v11 validate-pack addition. Validates `tracker.toml`
  schema if present; warns if mode tracker but mirror files have stale
  `Last regenerated` timestamps relative to `tracker.toml.migration.last_forward_run`
  (per V1 §A.2). Check number is pedagogical — verify next-free integer at
  land-time per §6.C.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-078-BD-079.md`. **Check 29** (`check_tracker_config`) added to scripts/validate-pack.py — uses `tomllib` to validate both `tracker.toml.pack-example` (root) and `project-template/tracker.toml.project-example` for: TOML parse correctness, `schema_version == 1` (int), allowed-set membership on `backend.name` / `mode.state` / `cli_acceleration.prefer`, presence + types of all `[mirror]` keys, per-surface `id_namespace.prefix` (BD pack / TD client), bool + non-empty-string typing on `[migration]` keys. Wired in `main()` after Check 28 in numerical order. New regression test `scripts/tests/tracker-config-schema-test.sh` 17/17 PASS (1 well-formed + 8 distinct failure modes). Validator now reports 30 numbered checks + 2 informational, all clean.

---

**BD-079 — validate-pack.py Check (recommendation-state schema)**
Type: TODO(version)
Status: Resolved
Blockers: BD-072
Unblocks: None
File/Symbol: `scripts/validate-pack.py`
Description: If `.pack-tracker/recommendation-state.json` exists, validate
  against the V3 §28.1.4 v1 schema. Soft-fail if missing (lazy-create is by
  design). Catches state-file corruption before it causes runtime defaults.
  Check number per §6.C audit at land-time.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-078-BD-079.md`. **Check 30** (`check_recommendation_state_schema`) added to scripts/validate-pack.py — soft-passes when `.pack-tracker/recommendation-state.json` is absent (lazy-create design); otherwise validates JSON parse, all v1 schema fields per `recommendation_state_default()`, `schema_version == "v1"`, `surface ∈ {pack, client}`, `user_re_enable_count` non-negative-int (with explicit bool rejection). Wired in `main()` after Check 29 in numerical order. New regression test `scripts/tests/recommendation-state-schema-test.sh` 19/19 PASS (file-absent soft-pass + well-formed PASS + 8 distinct failure modes).

---

**BD-080 — `init-project.sh` extensions for v11 artifacts**
Type: TODO(version)
Status: Resolved
Blockers: BD-076, BD-077, BD-063
Unblocks: None
File/Symbol: `scripts/init-project.sh`, `scripts/lib/init-helpers.sh`
Description: Single-source for client-side artifact installation. Installs
  per-CLI `pack-help/` skills and `pack-help.toml`; installs `HELP-FRAGMENT.md`
  and `HELP-FRAGMENT-TRACKER.md` (latter copied from pack-root canonical per
  DELTA L1); installs `tracker.toml.example`; installs issue forms.
  `--update` flag refreshes from pack-root canonical without destroying
  customization (BD-088 contract).
Resolved: 2026-05-07, v11.0 — stage S11 + cmd_update + 30 fixture tests.
  Stage S11 installs HELP-FRAGMENT*.md, tracker.toml.example, issue forms,
  per-CLI pack-help surfaces. cmd_update consumes BD-088 over a 23-entry
  list plus iteration of project-template/scripts/ + per-CLI agents/ for
  parity with BD-085. HELP-FRAGMENT-TRACKER.md force-copied from pack-root
  canonical for DELTA L1 byte-identity. Sidecar-presence gate on re-run
  prevents single-slot sidecar overwrite. Review fixes (PACK-REVIEW-BD-080-
  BD-085) addressed B1, M1–M5, m1–m4, m6, m7 in fix-follow.

---

**BD-081 — Trinity addenda: per-CLI command files at pack-root + client (P-help reference)**
Type: TODO(version)
Status: Resolved
Blockers: BD-077
Unblocks: None
File/Symbol: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack-root); `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (client) — 6 files trinity-replicated × 2 surfaces
Description: Implements V3 §A.2 trinity addendum. Adds one-line "Pack
  commands" reference (`pack help` / `/pack-help`) AND one-line "Recommended
  first action: run `pack-startup` (pack repo) or `pm-startup` (client repo)"
  line. The second line makes §28.2.6 Layer 1's static greeting a documented
  contract. All 6 files in lockstep.
Resolved: 2026-05-08, v11.0 — "## Quick reference" block added in
  lockstep across all 6 trinity files. Block lines byte-identical
  within each surface; only inter-surface difference is `pack-startup`
  vs `pm-startup`. Verified by Check 18 (trinity H2 parity) still
  green. Pack-Reviewer Batch 5 confirmed byte-identity.

---

**BD-082 — validate-pack.py Checks for help / per-CLI parity / byte-identity**
Type: TODO(version)
Status: Resolved
Blockers: BD-076, BD-077, BD-080, BD-081
Unblocks: None
File/Symbol: `scripts/validate-pack.py`
Description: Lands the four CI gates that prevent help-surface drift per V3
  §28.2.5 + DELTA L1: (a) trinity per-CLI help-surface parity, (b)
  help-fragment freshness against external doc verb references, (c)
  help-fragment completeness against `scripts/` top-level executables, (d)
  shared-fragment byte-identity (pack-root vs client-mirror). V3.3-introduced
  Checks (phase-task coverage / cross-entity ref resolution / promotion-label
  consistency / per-CLI parity for `auditor-issue-tracking.md`) ride a later
  extension at step 24a per Addendum 4. Check numbers per §6.C / §6.O / §6.O.1
  audit at land-time.
Resolved: 2026-05-08, v11.0 — Checks 21–24 landed in validate-pack.py.
  Check 21 per-CLI parity (claude/codex skill + gemini command).
  Check 22 freshness (verb regex with surface-aware existence filter +
  pack-internal exemption shared with Check 23). Check 23 completeness
  (every executable listed unless `# pack-internal: true`). Check 24
  DELTA L1 byte-identity. Drift surfaced + fixed: HELP-FRAGMENT-PACK.md
  gained 7-row "Pack scripts" section; 9 helpers marked pack-internal
  (CI runners + migrator-only merge helpers).

---

**BD-083 — Aggregate CI workflow update + test runner**
Type: TODO(version)
Status: Resolved
Blockers: BD-060, BD-065, BD-068, BD-072, BD-070
Unblocks: None
File/Symbol: `.github/workflows/validate-pack.yml`
Description: One workflow, one runner. Invokes the new test scripts:
  `tracker-provider-test.sh`, `tracker-migrate-forward-test.sh`,
  `tracker-migrate-roundtrip-test.sh`, `recommendation-test.sh`,
  `tracker-errors-test.sh`. Stage-fence the live-network tests (skipped in
  CI by default; recorded fixtures used). Each test independent.
Resolved: 2026-05-08, v11.0 — workflow split into `validate` (25
  Checks) + `tests` (17 independent test suites with `if: always()`
  isolation). All offline (tracker-* uses PATH-prepended fake gh
  stubs). Branch protection note in workflow comments — must re-apply
  to require both jobs (one-time admin action).

---

**BD-084 — Create `supporting-docs/MIGRATION-v10-to-v11.md`**
Type: TODO(version)
Status: Resolved
Blockers: BD-085, BD-088, BD-091
Unblocks: None
File/Symbol: `supporting-docs/MIGRATION-v10-to-v11.md`
Description: Authoritative v10→v11 migration narrative. Two-phase: forced
  v10→v11 changes (everyone runs) then optional tracker opt-in (per surface,
  per user). Includes BD-059 lessons-learned section (customization
  preservation contract); v9-or-earlier upgrade path paragraph (chained via
  migrate-v9-to-v10.sh first); multi-project guidance (one sentence). Length
  comparable to v9-to-v10 (~800 lines).
Resolved: 2026-05-08, v11.0 — 453-line user-facing migration doc.
  Two-phase structure (forced + tracker opt-in); 7-stage table matching
  migrate-v10-to-v11.sh; 7-row exit-code table; project-type-specific
  notes (Apple/Swift, Python, mixed/gRPC); troubleshooting recipes;
  BD-059 lessons-learned; automated-via-AI-CLI variant; multi-project
  guidance. Cross-links MERGE-STRATEGY.md (per-file matrix) +
  OPTIONAL-FEATURES.md (Phase B walkthrough).

---

**BD-085 — `scripts/migrate-v10-to-v11.sh` (the migration script itself)**
Type: TODO(version)
Status: Resolved
Blockers: BD-088, BD-091, BD-080
Unblocks: None
File/Symbol: `scripts/migrate-v10-to-v11.sh`, `scripts/lib/migrate-v10-to-v11/`, `scripts/tests/test-migrate-v10-to-v11.sh`
Description: One-shot migrator paralleling `migrate-v9-to-v10.sh`. Applies
  Phase A only (tracker opt-in is post-migration via `pack tracker init`).
  Applies trinity addenda; installs help fragments + per-CLI `pack-help`
  surfaces; adds Source column to project-template trinity; performs BD-042
  relocation; produces a truthful customization report (BD-059 fix). Tracker
  opt-in is NOT part of this script. Extended by BD-095 with `--dry-run` /
  `--apply` / `--resume` modes.
Resolved: 2026-05-07, v11.0 — 7-stage migrator (S0 pre-flight / S1 backup
  / S2 BD-088 init / S3 dispatch / S4 BD-042 relocation / S5 v11 artifacts
  / S6 truthful report). 35 fixture tests including end-to-end with
  genuine v10-tag baseline content. Backup captures full working tree
  (M1 fix — preserves gitignored .gemini/.env). git mv failures fail
  loudly rather than silently falling back (M4 fix). User-facing restore
  messages give explicit working `rsync` commands (B1 fix). BD-095 will
  later extend with --dry-run / --apply / --resume modes.

---

**BD-086 — README.md version table v11.0 row + Repository Layout updates**
Type: TODO(version)
Status: Resolved
Blockers: BD-091, BD-076, BD-093
Unblocks: None
File/Symbol: `README.md`
Description: Adds v11.0 row to the version table (newest-first per recent
  v10.x convention); updates Repository Layout to include `HELP-FRAGMENT-PACK.md`,
  `HELP-FRAGMENT-TRACKER.md`, `tracker.toml.example`, `.github/ISSUE_TEMPLATE/`,
  per-CLI agent / skill / command directories; reflects post-relocation tree.
  Lands as two-step (placeholder → final hash at BD-093).
Resolved: 2026-05-08, v11.0 — v11.0 row added to version table
  (newest-first); Repository Layout updated to include all new v11
  artifacts (per-CLI pack-help, ISSUE_TEMPLATE, HELP-FRAGMENT*.md,
  tracker.toml.example) and expanded scripts/lib/ tree (BD-088 +
  tracker subsystem + recommendation). Final hash placeholder retained
  for BD-093.

---

**BD-087 — CHANGELOG.md v11.0 entry**
Type: TODO(version)
Status: Resolved
Blockers: All other v11 BDs land first; BD-093
Unblocks: None
File/Symbol: `CHANGELOG.md`
Description: Adds v11.0 entry covering Scope A (D-1..D-23 list, BDs landed)
  and Scope B (BD-059 fix, BD-042 relocation, trinity addenda,
  MIGRATION-v10-to-v11.md, dog-food validation, pack tracker reset).
  Cites the 5 audit artifacts (3 CP reports + semantic audit + dog-food
  report) as release evidence. Pack maintainer rule: CHANGELOG only at
  version boundaries with explicit instruction.
Resolved: 2026-05-08, v11.0 — v11.0 entry lands. Scope A enumerates
  D-1..D-23 with BD-NNN per dimension; Scope B enumerates BD-088 +
  BD-080 + BD-085 + BD-081 + BD-082 + BD-089 + BD-083 + BD-091/042 +
  BD-084/094 + BD-090/092/086/087. Audit artifacts cited
  (test-customization-preserve.sh + Check 25 + semantic audit doc).
  Carried-over future work captured (BD-093, BD-095, BD-097, BD-098,
  BD-110, BD-111, BD-112).

---

**BD-088 — Customization-preservation algorithm + truthful report (BD-059 fix)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-042, BD-059 (resolves both)
File/Symbol: `scripts/lib/customization-preserve.sh`, `scripts/lib/customization-report.sh`, `scripts/tests/test-customization-preserve.sh`
Description: BD-059 fix as a v11-cut artifact. Per-file preservation rules
  for trinity (3-way merge), `.claude/settings.json` (allowlist via
  merge-json.py), `.codex/config.toml` (allowlist via merge-toml.py),
  `.gemini/.env`, `.mcp.json.example`, PM-CHAT.md (marker-section + diff-
  recognition), `scripts/`, `x-*` agents. Truthful customization report
  listing every preserved/modified file. Same library used by `init-project.sh
  --update` (BD-080) and `migrate-v10-to-v11.sh` (BD-085).
Resolved: 2026-05-07, v11.0 — library + report renderer + 72 fixture tests
  shipped. Public API: customization_preserve_init, customization_classify,
  customization_preserve, customization_findings_count,
  customization_findings_tsv_path, customization_report. Covers 12 file
  classes; routes through three_way_classify for 8 canonical dispositions
  plus catch-all unknown-classification surfaced in the report's
  "Unhandled dispositions" section. BD-088 review (PACK-REVIEW-BD-088)
  surfaced 1 BLOCKER + 3 MAJOR (init-time guard, gemini-env routing
  through three_way_classify, dup-key dedup, leading-whitespace handling)
  + cheap-correctness fixes; all addressed in fix-follow. m7 (flat-name
  collision; pre-existing in migrate-v9-to-v10.sh too) tracked as BD-112.

---

**BD-089 — validate-pack.py Check (customization-detection regression guard)**
Type: TODO(version)
Status: Resolved
Blockers: BD-088, BD-085
Unblocks: None
File/Symbol: `scripts/validate-pack.py`
Description: Synthetic test that simulates `migrate-v10-to-v11.sh` against a
  fixture v10 project with known customization shapes and asserts the
  customization-preservation report names every preserved file. Closes the
  verification gap from BD-059 success criterion. Runs in CI on every push.
  Check name (`check_customization_detection_regression_guard`) is stable;
  number per §6.C / §6.O.1 audit at land-time.
Resolved: 2026-05-08, v11.0 — Check 25 lands. 4-fixture driver covers
  trinity real-merge / gemini-env / custom-agent / unchanged-pack
  classes; asserts each produces exactly one finding with expected
  disposition + class + appears in rendered report. Exhaustive class
  coverage (sidecar / structured-config / pm-chat / all-three-absent)
  delegated to test-customization-preserve.sh which now runs in CI
  per BD-083.

---

**BD-090 — QUICKSTART.md callout + cross-references**
Type: TODO(version)
Status: Resolved
Blockers: BD-084
Unblocks: None
File/Symbol: `QUICKSTART.md`
Description: Adds top-of-doc "Recommended first action: run `pack-startup`
  (pack repo) or `pm-startup` (client repo) in your CLI" callout per V3
  §A.2. Adds link to `MIGRATION-v10-to-v11.md` for upgraders. References
  HELP-FRAGMENT and `pack help` for verb discovery. References
  `OPTIONAL-FEATURES.md` for tracker opt-in walkthrough. Maintains existing
  path-router shape.
Resolved: 2026-05-08, v11.0 — top-of-doc callout added pointing at
  /pack-startup or /pm-startup; HELP-FRAGMENT-PACK.md and `pack help`
  surfaced for verb discovery. v10→v11 cross-link added (alongside
  v9→v10) plus references to MERGE-STRATEGY.md and OPTIONAL-FEATURES.md.
  Path-router (NEW / EXISTING / MIGRATE) shape preserved.

---

**BD-091 — BD-042 doc relocation (Phase 1: relocate)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-042 (resolves)
File/Symbol: `project-template/METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md` → `project-template/docs/pack/`
Description: Per BD-042 (open since v9). Relocates pack reference docs from
  `project-template/` root to `project-template/docs/pack/`. Per §6.D
  audit at land-time: README v9.2 entry suggests this work was partially
  shipped; this BD ships the complete relocation across any remaining root-
  level reference docs. `git mv` preserves history.
Resolved: 2026-05-07 — verification-only no-op. State audit confirmed the
  relocation already shipped in prior versions: `project-template/` root now
  contains only the four files BD-042 explicitly preserved (CLAUDE.md,
  AGENTS.md, GEMINI.md, README.md); the five named reference docs are present
  at `project-template/docs/pack/` (PM-CHAT.md, PLATFORM-SKILLS.md,
  PACK-FEEDBACK.md) or moved pack-side to `supporting-docs/` (METHODOLOGY.md;
  PROMPT-TEMPLATES.md retired into prompt skills). No further file moves
  required. BD-042 is unblocked and resolves with this BD.

---

**BD-092 — Cross-reference sweep for relocated docs + v11 verbs**
Type: TODO(version)
Status: Resolved
Blockers: BD-091, BD-076, BD-073
Unblocks: None
File/Symbol: `project-template/docs/pack/*.md`, trinity files, prompts, supporting-docs/SETUP-*.md, INSTALL-PROCEDURES.md, MIGRATION-v10-to-v11.md, OPTIONAL-FEATURES.md, PACK-CHAT.md, PACK-AGENTS.md
Description: One sweep BD that updates every cross-reference impacted by
  (a) BD-091 / BD-042 relocation, and (b) v11 verb additions. Touches many
  files but each diff is small. Adds tracker section to OPTIONAL-FEATURES.md
  (elevated by BD-098). Adds Recommendation routing section to PACK-CHAT.md /
  PM-CHAT.md.
Resolved: 2026-05-08, v11.0 — sweep landed in commit 8497b03 + fix-
  follow. OPTIONAL-FEATURES.md gained 7-point "Tracker integration
  (v11)" section; PACK-CHAT.md and project-template PM-CHAT.md gained
  parallel "Recommendation routing (v11+)" sections (pack-side 3
  signals; client-side 6 signals — verified against
  recommendation.sh::_rec_signal_names per Batch 6 review M1);
  template-instruction blocks in project-template/docs/pack/PM-CHAT.md
  + PACK-FEEDBACK.md updated to post-relocation install path;
  METHODOLOGY.md PACK-FEEDBACK reference updated to docs/pack/
  location.

---

**BD-093 — v11.0 release pin (tag, README, CHANGELOG, MIGRATION cross-link)**
Type: TODO(version)
Status: Open
Blockers: All BDs above (BD-060..BD-092) plus all addenda BDs
Unblocks: None
File/Symbol: `README.md`, `CHANGELOG.md`, git tags
Description: The release-cut commit. Pack maintainer rule: tag operations
  only after Pack Chat approval. Delete `v11` if present; recreate `v11.0`
  and `v11`; push. validate-pack must pass on the tagged commit;
  MIGRATION-v10-to-v11.md references reflect as-shipped state.
Resolved: n/a

---

**BD-094 — `MERGE-STRATEGY.md` deliverable (per-file matrix + A1 UX)**
Type: TODO(version)
Status: Resolved
Blockers: BD-088, BD-095, BD-085
Unblocks: None
File/Symbol: `supporting-docs/MERGE-STRATEGY.md`, cross-links from `MIGRATION-v10-to-v11.md`, `OPTIONAL-FEATURES.md`, `QUICKSTART.md`
Description: Surfaces the per-file customization-preservation matrix as a
  user-readable deliverable (rules buried in BD-088 code). For every file
  class the migrator touches: primary strategy (3-way merge / allowlist-merge
  / marker-section / diff-recognition / unconditional-preserve) + A1 fallback
  (stop on unresolvable conflict; emit `*.merge-conflict`; user resolves and
  runs `--resume`). Includes IMPLEMENTATION-PLAN.md row (BD-106 extension).
Resolved: 2026-05-08, v11.0 — 290-line user-readable per-file matrix.
  12 classes documented (trinity / claude-settings / claude-mcp-example
  / codex-config / codex-config-example / gemini-env / pm-chat /
  custom-agent / pack-agent / custom-script / pack-script / generic).
  Each class entry: strategy, what's preserved, what's updated,
  disposition tokens, what to do on
  customization-detected-needs-reconciliation. Single-slot sidecar
  conventions documented; A1 UX deferred to BD-095 (--dry-run / --apply
  / --resume) with forward-pointing section. Cross-references closed:
  customization-preserve.sh, customization-report.sh,
  test-customization-preserve.sh, MIGRATION-v10-to-v11.md,
  OPTIONAL-FEATURES.md, QUICKSTART.md, validate-pack Check 25. Note
  on lib/ being intentionally hidden from `pack help` added.

---

**BD-095 — `migrate-v10-to-v11.sh` two-phase `--dry-run` / `--apply` / `--resume` workflow**
Type: TODO(version)
Status: Resolved
Blockers: BD-085, BD-088, BD-094
Unblocks: None
File/Symbol: `scripts/migrate-v10-to-v11.sh`, `scripts/lib/migrate-v10-to-v11/dry-run.sh`, `apply.sh`, `resume.sh`, `scripts/tests/test-migrate-v10-to-v11-dry-run.sh`
Description: Splits the migrator into the standard two-phase workflow.
  `--dry-run` produces report; `--apply` requires fresh dry-run report
  matching working-tree fingerprint (24h freshness window per §6.G);
  `--resume` continues from `*.merge-conflict` resolution per A1 UX.
  `--resume` is forward-only; accept both `.resolved` flag-file and
  extension removal (§6.H).
Resolved: 2026-05-10 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-095.md`. Three new lib files: `scripts/lib/migrate-v10-to-v11/dry-run.sh` (216 lines), `apply.sh` (384 lines — fingerprint check + 24h freshness window per §6.G + bare-invocation auto-rerun for single-shot UX preservation), `resume.sh` (252 lines — sentinel-based forward-only with both `.resolved` flag-file AND extension-removal conflict-resolution signals per §6.H). `scripts/migrate-v10-to-v11.sh` adapter parses `--dry-run` / `--apply` / `--resume` flags and dispatches; bare invocation defaults to `--apply` and auto-runs `--dry-run` first if no fresh fingerprint, preserving backwards-compat single-shot UX. Stage sentinels written as `stage-S<N>.done` in the migrator's state directory. New regression test `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` 40/40 PASS. Existing test surface green: `test-migrate-v10-to-v11.sh` 39/39, `test-migrator-core.sh` 19/19, `test-migrator-manifest.sh` 12/12. Validator: 30 checks PASS. Scope-adjacent change: one-line dry-run gate in `migrator_post_dispatch_hook` (without it, dry-run would mutate the working tree because the BD-119 framework's dry-run plumbing only short-circuits framework stage helpers, not adapter post-dispatch hooks). Companion doc updates: `supporting-docs/MERGE-STRATEGY.md` §A1 (was-future → now-shipped + Class B `MIGRATOR_OWN_SIDECAR_SUFFIX` parameterization), `supporting-docs/MIGRATION-v10-to-v11.md` lines 75-76 (same), `BACKLOG.md` BD-101 description (replaced bare `*.merge-conflict` with parameterized form). 4 POQs surfaced — POQ-1 (doc lag) and POQ-2 (sidecar terminology) closed in this commit; POQ-3 (v9→v10 historical layout unverified per BD-121 deletion) and POQ-4 (bare-invocation auto-rerun on stale/drifted not just missing — strict superset of literal spec) accepted as-shipped per implementation report §11.

---

**BD-096 — Synthetic-fixture set (general-use coverage; OT is one example)**
Type: TODO(version)
Status: Open
Blockers: BD-088, BD-085
Unblocks: None
File/Symbol: `scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/`, `heavily-customized/`, `language-heterogeneous/`, `custom-agents-heavy/`, `v10-with-customization/`
Description: 4 new synthetic fixtures + the OT-modeled fixture from BD-088
  (now one of five). Proves migrator handles distinct customization shapes;
  OT becomes one example among several (general-use). README explains each
  fixture; all 5 pass `test-customization-preserve.sh` end-to-end. Phase-task
  fixtures added by BD-106 extension.
Resolved: n/a

---

**BD-097 — Pre-release semantic audit pass**
Type: TODO(version)
Status: Resolved
Blockers: All Scope-A and Scope-B BDs except BD-086, BD-087, BD-093
Unblocks: BD-093
File/Symbol: `maintenance-docs/v11-implementation/SEMANTIC-AUDIT-REPORT.md`, `SEMANTIC-AUDIT-PROMPT.md`
Description: Agent-driven semantic audit before release pin. Catches
  semantic drift validate-pack can't catch (HELP-FRAGMENT entries that
  describe wrong verb behavior; MIGRATION doc that disagrees with code;
  etc.). Pass = zero blockers + every warning dispositioned. Per §6.I
  resolution: ad-hoc Claude Code session for v11.0; revisit dedicated agent
  in v11.1+.
Resolved: 2026-05-08, v11.0 — pack-architect agent ran the semantic
  audit; produced 480-line SEMANTIC-AUDIT-REPORT.md. Found 1 BLOCKER
  (B-1: client `/pack-help` skill referenced a script the install
  never delivered) + 11 WARNINGs + 6 NOTEs. B-1 fixed by extending
  init-project S11 + migrator S5 to install `pack-help.sh` +
  `lib/detect.sh` into client (with fixture tests verifying
  `bash scripts/pack-help.sh` succeeds from a fresh project root).
  10 of 11 WARNINGs fixed; remainder dispositioned as deferred (1
  cosmetic skipped). All 25 validate-pack Checks remain green; 137
  BD-088/080/085 fixture tests + 17 pack-help tests + 53
  recommendation tests pass on bash 3.2.57. Audit clears BD-093 for
  release-pin per re-audit gate.

---

**BD-098 — `OPTIONAL-FEATURES.md` tracker walkthrough (elevated user-doc home)**
Type: TODO(version)
Status: Resolved
Blockers: BD-092, BD-073, BD-066
Unblocks: None
File/Symbol: `OPTIONAL-FEATURES.md`, plus cross-links from QUICKSTART.md, MIGRATION-v10-to-v11.md, DEPENDENCIES.md, PACK-CHAT.md, PM-CHAT.md
Description: Elevates GH Issue tracker enablement to OPTIONAL-FEATURES.md
  as primary user-doc home (matching existing Agent Teams template shape).
  Status / What it is / When this matters / How to enable (`pack tracker
  init` walkthrough) / How the pack's pieces work with it / Caveats / When
  to skip / How to disable / Failure modes (cross-link to MERGE-STRATEGY).
  3-level recovery (BD-103) lands here too.
Resolved: 2026-05-08, v11.0 — full 9-section tracker entry in
  OPTIONAL-FEATURES.md (Status, What it is, When it matters, How to
  enable, How to use, Caveats, When to skip, How to disable, Failure
  modes — cross-linked to MERGE-STRATEGY.md). Initial 7-section shape
  shipped in BD-092; BD-098 adds the explicit "How to disable"
  (`pack tracker disable`) + "Failure modes" (truthful-report contract
  + sidecar reconciliation recipe) sections per the BD spec. 3-level
  recovery (BD-103) deferred to v11.x.

---

**BD-099 — `DEPENDENCIES.md` `gh` optional-dep pointer**
Type: TODO(version)
Status: Resolved
Blockers: BD-098
Unblocks: None
File/Symbol: `supporting-docs/DEPENDENCIES.md`
Description: Adds `gh` CLI entry under new `## CLI tools (optional, per-feature)`
  section. Includes `gh-sub-issue` extension entry. Cross-link to
  OPTIONAL-FEATURES.md § GitHub Issue Tracker. Quick Reference table row
  added: `gh CLI | Tracker opt-in (optional) | brew install gh`.
Resolved: 2026-05-08, v11.0 — Quick Reference table gained two rows
  (`gh CLI` + `gh-sub-issue`); new "## CLI tools (optional, per-feature)"
  section with full install + auth + verify recipe and cross-link to
  OPTIONAL-FEATURES.md § Tracker integration (v11).

---

**BD-100 — Pack-implementation milestone checkpoints (3 strategic audits during v11)**
Type: TODO(version)
Status: Open
Blockers: BD-068 (CP1), BD-082 (CP2), BD-085 (CP3)
Unblocks: BD-093
File/Symbol: `maintenance-docs/v11-implementation/CHECKPOINT-{1,2,3}-REPORT.md`, `CHECKPOINT-PROMPT-TEMPLATE.md`
Description: 3 strategic agent-driven audit passes during v11 implementation.
  CP1 (Scope-A backbone after BD-068): tracker provider + forward + reverse
  + round-trip work. CP2 (Scope-A surfaces after BD-082): help system +
  recommendation system wired. CP3 (Scope-B integrated after BD-085):
  migration script + customization-preserve + MERGE-STRATEGY produce
  truthful reports against multiple fixtures. Each CP has explicit
  pass/fail criteria. Extended by BD-110 to invoke `pack-auditor`.
Resolved: n/a

---

**BD-101 — Client-migration validation gates (3 in-script gates with pass/fail)**
Type: TODO(version)
Status: Resolved
Blockers: BD-085, BD-095, BD-088, BD-091, BD-094, BD-066
Unblocks: None
File/Symbol: `scripts/lib/migrate-v10-to-v11/gate-{1,2,3}-*.sh`, `checkpoint.sh`, `scripts/tests/test-migrate-v10-to-v11-gates.sh`
Description: 3 gates inside `migrate-v10-to-v11.sh` with explicit pass/fail.
  Gate 1: pre-migration dry-run (read-only; user reviews and approves).
  Gate 2: post-Phase-A (trinity addenda; HELP-FRAGMENT files; Source column;
  relocated docs; validate-pack). Gate 3: post-Phase-B (only if user opted
  into tracker; mapping integrity; mirror freshness; `pack tracker doctor`
  green). Failures route through A1 UX (sidecar files written with the
  per-migrator suffix `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}` — currently
  `*.v10-customized` for the v10→v11 migrator; `restore-from-backup.sh`
  if needed).
Resolved: 2026-05-11 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-101.md`. Four new lib files: `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (8 verification helpers + 1 mode-detect), `gate-1-dry-run-summary.sh`, `gate-2-phase-a-verify.sh`, `gate-3-phase-b-verify.sh`. Wired Gate 1 into `dry-run.sh`; Gate 2 + Gate 3 into both `apply.sh` (post-report wrapper) and `resume.sh` (tail). Added `EXIT_GATE_FAILED=31` to `scripts/lib/migrator-core.sh` (first slot above the stage-failure cap of 30) so gate failures are cleanly distinguishable from stage failures (20–30), preflight failures (10–16), and internal errors (99) — supports BD-095's `--resume` reconciliation. New regression test `scripts/tests/test-migrate-v10-to-v11-gates.sh` 38/38 PASS. All existing test surface green: test-migrate-v10-to-v11.sh 43/43 (per BD-139 extension), test-migrate-v10-to-v11-dry-run.sh 40/40, test-migrator-core.sh 19/19, test-migrator-manifest.sh 12/12. Validator: 30/30 PASS. No mode-bit regressions. Co-shipped with BD-139 (Batch 12 fix-follow) — both ran in parallel under separate pack-coder agents; both edits to `scripts/migrate-v10-to-v11.sh` coexist line-disjoint.

---

**BD-102 — Pack-repo dog-food migration (final v11 validation)**
Type: TODO(version)
Status: Open
Blockers: BD-101, BD-097, BD-100, BD-067, BD-066, BD-085, BD-084
Unblocks: BD-093
File/Symbol: `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md`, `scripts/tests/dog-food-checkpoint.sh`
Description: Pack-Chat-direct workflow: maintainer runs `migrate-v10-to-v11.sh`
  + `pack tracker init` against the pack's own real BACKLOG. Final pre-release
  validation. Procedure: pre-checkpoint → dry-run → apply → tracker init →
  doctor → disable → reverse-round-trip diff → author report → ship decision.
  Per §6.J ship decision: pack ships v11.0 in flat-file mode (reverse before
  release pin). Highest-confidence validation; predicts client migration.
Resolved: n/a

---

**BD-103 — `pack tracker reset` verb + 3-level recovery documentation**
Type: TODO(version)
Status: Open
Blockers: BD-066, BD-067, BD-070, BD-076, BD-084, BD-098
Unblocks: None
File/Symbol: `scripts/pack-tracker.sh`, `scripts/lib/pack-tracker/reset.sh`, `scripts/tests/test-tracker-reset.sh`, plus prose in MIGRATION-v10-to-v11.md, OPTIONAL-FEATURES.md, HELP-FRAGMENT files, PACK-CHAT.md, PM-CHAT.md
Description: Friction-by-design bulk-delete for pack-marked GH issues.
  Confirm flag per §6.K: `--confirm-i-have-admin-and-want-to-delete-all-pack-issues`.
  Admin permission check; marker-scoped delete (only `<!-- pack-id: -->`
  matches; user-created issues safe); 100ms throttle. 3-level recovery
  documented in OPTIONAL-FEATURES.md "Failure modes": soft (reverse + fix
  + re-forward), hard (reset + re-forward), nuclear (restore-from-backup).
Resolved: n/a

---

**BD-104 — Cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`**
Type: TODO(version)
Status: Resolved
Blockers: BD-085, BD-091, BD-076, BD-070
Unblocks: None
File/Symbol: project-template trinity, prompts, PM-CHAT.md, pm-startup SKILL.md, supporting-docs/METHODOLOGY.md and SETUP-*.md, BACKLOG.md, maintenance-docs/TOOL-COMPARISON.md (40+ specific line-numbered references); migrator `git mv` step
Description: Forced v10→v11 client change. Naming consistency: hyphenated
  all-caps convention. Pack-side string sweep + client-side `git mv`
  (history-preserving) in migrate-v10-to-v11.sh Phase A. Historical files
  (MIGRATION-v9-to-v10.md, MIGRATION-v8-to-v9.md, CHANGELOG v10 entry)
  explicitly allowlisted. Collision case surfaces typed error
  `migration-rename-collision`.
Resolved: 2026-05-10 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-104.md` (commits `ef20113` BD-104 sweep + `5e77939` mode-bit fix-up). 31 pack-shipped files updated; 2 fixture files renamed (git auto-detected via content similarity). Migrator `scripts/migrate-v10-to-v11.sh` gained Phase-A stage S4 (lines 141-181) handling all five edge cases: source-absent no-op; collision (both names exist) surfaces `migration-rename-collision` typed error per BD-070 / ARCHITECTURE.md §2.5 contract; tracked-source `git mv` history-preserving; untracked-source plain `mv` fallback; post-rename verification. 179 remaining `IMPLEMENTATION_PLAN` references audited and explicitly allowlisted as of commit `ef20113` (archives, MIGRATION-v8-to-v9.md, CHANGELOG, BACKLOG historical context, EXECUTION-PLAN, migrator script which references both names by necessity). Count is point-in-time at the rename commit; subsequent commits (BACKLOG entries, audit reports, fix-follow descriptions, migrator code/tests) necessarily quote the v10 form `IMPLEMENTATION_PLAN.md` by name and grow the count organically. Per BD-139 F-5 reconciliation: the AUDIT-BD-104.md count of 181 was 2 higher because of two BACKLOG additions in commits between `ef20113` and audit base `f1dc255` (the BD-104 status-flip entry and BD-137 description), both legitimate historical-context references. Validator: 30 checks PASS. Tests: 12 runners green. **KNOWN-TEMPORARY:** `scripts/test-migrator-behavior-preservation.sh` (BD-119 byte-equivalence harness) goes from 15-pass to 13-pass-2-fail because the new BD-104 stdout banner intentionally diverges from the pre-refactor monolith pinned at SHA `d7b3f07`. Harness header (PLAN §13.3) explicitly forbids redaction-based fixes. The BD-119 refactor that harness gated has shipped, so the harness itself is now obsolete. Fast-follow tracked as **BD-137** — retire the harness.

---

**BD-105 — STATUS.md phase-row dual-link rendering (tracker mode)**
Type: TODO(version)
Status: Open
Blockers: BD-065, BD-067, BD-068, BD-066, BD-084
Unblocks: None
File/Symbol: `scripts/lib/tracker-migrate-forward.sh`, `tracker-migrate-reverse.sh`, `scripts/lib/pack-tracker/doctor.sh`, `scripts/tests/tracker-migrate-roundtrip-test.sh`, MIGRATION-v10-to-v11.md
Description: When tracker mode is active, STATUS.md phase-row titles render
  in Option A middle-dot inline format: `[Phase Title](IMPLEMENTATION-PLAN.md#anchor)
  · [#N](issue-URL)`. Reverse strips ` · [#N](URL)` to restore single-link
  form. 4 edge cases dispositioned (orphan / multi-epic / direct edits /
  closed). Bidirectionality contract honored: dual-link is tracker-only
  enrichment.
Resolved: n/a

---

**BD-106 — Phase task entity model + identifier scheme + parser/emitter**
Type: TODO(version)
Status: Open
Blockers: BD-063, BD-064, BD-065, BD-067
Unblocks: BD-107, BD-108
File/Symbol: `scripts/lib/pack-tracker/phase-task-parser.py`, `phase-task-emitter.py`, `sidecar-schema.py` (extend), `labels.py` (extend), `id-map.py` (extend), `scripts/tests/test-phase-task-parser.sh`
Description: Phase task as first-class L2 entity per V3.3 D-21. Identifier
  `phase-N.M` (lowercase, dash-separated; M is integer task number from .md).
  Parser reads `### Tasks` blocks under `## Phase N` headings; emitter
  reverses. Sidecar gains `phase_tasks` block + per-task `dependency_edges`
  with `annotation` sub-field per §6.R. Label family: `derived-from:` and
  `promoted-to:` only (NOT `folded-into:` per Path-3 forbidden).
Resolved: n/a

---

**BD-107 — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close)**
Type: TODO(version)
Status: Open
Blockers: BD-106, BD-108
Unblocks: None
File/Symbol: `scripts/lib/pack-tracker/promote.sh`, `promote.py`, `project-template/docs/pack/PM-CHAT.md`, `METHODOLOGY.md` § Part 7 lines 1057-1064, `project-template/HELP-FRAGMENT.md`, 3 test scripts
Description: PM Chat orchestration for `pack td promote --to=phase-N`
  (Path 1; new phase epic) and `pack td promote --to=phase-N.M` (Path 2;
  new phase task); direct close uses v10 lifecycle unchanged. Path 3
  forbidden. PM Chat invokes architect by default for Path 1 (per §6.P
  resolution); planner conditional on architect's call. Path 2 typically
  goes direct. PM Chat advises threshold per V3.3 §7.1; user can override.
Resolved: n/a

---

**BD-108 — Cross-entity dependency link orchestration + cycle check + gate-check extension**
Type: TODO(version)
Status: Open
Blockers: BD-106, BD-070
Unblocks: None
File/Symbol: `scripts/lib/pack-tracker/links.py`, `cycle-check.py`, `dependencies-bullet-parser.py`, `blockers-grammar.py` (extend), `METHODOLOGY.md` § Part 4 line 263 + § Part 7 lines 990-993 + 1025-1029, 2 test scripts
Description: Uniform cross-entity dependency model across 6 entity-pair
  types (TD↔phase epic, TD↔phase task, phase task↔phase task same/cross-phase,
  TD↔TD, TD↔BD). Uses V1 §5.3 reserved `link.kind` open-string family; no
  new provider operation. Cycle check at link-creation time (K=10 default
  per §6.Q; configurable via `tracker.toml [graph] cycle_check_k`). Flat-file
  Blockers grammar gains `phase-N.M` (additive); Dependencies bullet grammar
  codified.
Resolved: n/a

---

**BD-109 — Project-side `auditor-issue-tracking` sub-agent**
Type: TODO(version)
Status: Open
Blockers: None on critical path; recommended sequencing pairs with BD-082 ext (Check 28) at step 23a/23b
Unblocks: None
File/Symbol: `project-template/.claude/agents/auditor-issue-tracking.md`, `.codex/agents/auditor-issue-tracking.toml`, `.gemini/agents/auditor-issue-tracking.md`, `auditor.md` parent extension × 3 CLIs, `audit-methodology/SKILL.md` × 3 CLIs, `scripts/tests/test-auditor-issue-tracking.sh`
Description: New 8th cluster under existing `auditor` parent fan-out per
  V3.3 D-23. Audits issue-tracking-surface health: dependency-graph
  integrity, syntax conformance, semantic consistency, drift detection.
  Read-only. Trinity-replicated × 3 CLIs in one commit (Check 28 enforces).
  Skip rule: brand-new project (no BACKLOG.md and no IMPLEMENTATION-PLAN.md)
  skips this cluster.
Resolved: n/a

---

**BD-110 — Pack-side `pack-auditor` agent**
Type: TODO(version)
Status: Open
Blockers: BD-074
Unblocks: None
File/Symbol: `.claude/agents/pack-auditor.md`, `.codex/agents/pack-auditor.toml`, `.gemini/agents/pack-auditor.md` (per-CLI per §6.M), `PACK-CHAT.md` Audit cadence section, `BD-100` CP-prompt extensions, `scripts/tests/test-pack-auditor.sh`
Description: New pack-side ongoing-state-audit agent peer to `pack-reviewer`
  per V3.3 D-23. Distinct role: review = pre-commit change-scoped;
  pack-auditor = ongoing-state surface-scoped (BACKLOG dependency graph,
  BD entry semantic consistency, drift over time, pack-product/pack-ops
  separation, version-table consistency, tracker-mode health). Per-CLI
  replicated to match existing pack-side layout per §6.M (a). Loads
  `audit-methodology` always; `architecture-review` conditionally for
  layer-discipline findings. Skill provenance via §6.N audit at land-time
  (BD-074 vs BD-110).
Resolved: n/a

**BD-111 — Switch blocks/blocked-by from comment-marker to first-class GH dependency API**
Type: TODO(version)
Status: Open
Blockers: Live GH repo access — pairs naturally with BD-088 or BD-093 integration
  test land-time, where introspection against the live GraphQL schema confirms
  the exact mutation name.
Unblocks: First-class blocker enumeration in `auditor-issue-tracking` (Check 28)
  without comment-body parsing.
File/Symbol: `scripts/lib/tracker-provider-gh.sh` —
  `tracker_provider_gh_link()` `blocks|blocked-by` case;
  `scripts/tests/tracker-provider-test.sh` test 1.17;
  new fixture under `scripts/tests/fixtures/tracker-provider/`.
Description: BD-060 ships `blocks`/`blocked-by` via comment markers (the
  documented V3 §28 fallback). GitHub issue dependencies went GA 2025-08-21
  (EXTERNAL-RESEARCH §1.5); the exact GraphQL mutation name was not pinned
  at BD-060 land-time and could not be verified offline. At BD-088 or BD-093
  land-time, run a GraphQL schema introspection against the live repo, swap
  the comment-based branch in `tracker_provider_gh_link()` for the actual
  mutation, add a fixture-driven test mirroring test 1.17, and remove the
  "GA 2025-08-21; mutation name verified at first live use" deferral note
  from the comment block above the function. Public `provider_link()` shape
  is unchanged. Comment-based markers remain available via `provider_raw()`
  for callers that explicitly want the V3 §28 fallback path.
Resolved: n/a

---

**BD-112 — Three-way diff filename mangling can collide on similar paths**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `scripts/lib/customization-preserve.sh` `_cp_write_diff()`;
  `scripts/migrate-v9-to-v10.sh` `write_three_way_diff()`
Description: Both helpers flatten relative paths into diff filenames via
  `${rel//\//-}` then strip a leading `.`. Two distinct rels can collapse
  to the same flattened name — e.g. `.claude/agents/foo.md` and
  `claude/agents/foo.md` both produce `claude-agents-foo.md`, so the
  second write silently overwrites the first's diff. The defect is a
  port-fidelity carryover from `migrate-v9-to-v10.sh` (low probability in
  practice — projects rarely shadow dotfile paths — but a truthfulness
  violation by another route, since the report references a diff path
  that no longer reflects the file it was written for). Fix in both
  locations in lockstep: include a stable disambiguator (short hash of
  rel, or sequence index) when a flattened name is already in use.
  Discovered during BD-088 review (PACK-REVIEW-BD-088 finding m7,
  2026-05-07).
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-112.md`. NEW `_cp_flat_name()` helper in scripts/lib/customization-preserve.sh maps each rel to `<rel-with-/-replaced-by-__>__<sha1-6hex>`. Deterministic, collision-resistant (different paths produce both different sanitized prefixes AND different hash suffixes), human-readable for debugging, macOS bash 3.2 + BSD-utils compatible (`shasum -a 1`). Both call sites that previously used `${rel//\//-}` with leading-dot strip — `_cp_write_diff` (`.three-way.diff` artifacts) and `_cp_strategy_structured` (`.merge-warnings.log` artifacts) — now route through the helper. Note: the BACKLOG entry's secondary surface (`scripts/migrate-v9-to-v10.sh`) was deleted by BD-121 and required no fix. test-customization-preserve 79/79 (was 72; +7 BD-112 collision/determinism asserts in new Group 6c, including the exact `.claude/agents/foo.md` vs `claude/agents/foo.md` pair from the BACKLOG entry). test-migrator-behavior-preservation 15/15. test-migrate-v10-to-v11 39/39. Validator clean.

---

**BD-113 — `test-fixtures/` persistent baseline directory + deterministic rebuild**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-102 re-validation
File/Symbol: `test-fixtures/.gitignore`, `test-fixtures/README.md`, `test-fixtures/build.sh`, `test-fixtures/manifest.txt`
Description: Persistent on-disk fixture baselines for the v10/v11
  client shapes the dog-food and migrator tests need. Each fixture is
  itself a git repo with deterministic content (pinned author/email,
  pinned commit dates, pinned source pack-version SHA) so re-builds
  are byte-identical. Build script supports `--all`, `--name`,
  `--clean`, `--verify` modes. Manifest records expected git SHAs.
  Fixture directories themselves are gitignored; build script + README
  + manifest are committed. Fixtures: `v10-minimal` (bare v10 install),
  `v10-realistic-ot` (fake-OT shape — project-name fills, x-agent,
  ollama removed, TD BACKLOG), `v11-flat-file` (v11 client, no tracker),
  `v11-tracker-on` (v11 client with tracker.toml mode=tracker for
  code-path testing without live GH).
Resolved: 2026-05-08, v11.0 — 4 fixtures shipped via deterministic
  build.sh. Pinned env (FIXTURE_EPOCH, FIXTURE_AUTHOR_NAME/EMAIL)
  guarantees byte-identical rebuilds; verified by running
  `--all --clean` twice and diffing the manifest. `--verify` mode
  cross-checks built fixtures against manifest.txt. Fixture content
  gitignored via per-dir `.gitignore`; recipe + README + manifest
  committed. Pack-root README Repository Layout updated. Will be
  consumed by BD-102 re-validation (Phase A + Phase B) once Phase A
  defects (D-1..D-7) are addressed.

---

**BD-114 — `dry-run-migration.sh` parameterized read-only migration harness**
Type: TODO(version)
Status: Resolved
Blockers: BD-119
Unblocks: v11.0 ship gate (Criterion 2); same harness reused for v12+; first public-release usability for any org maintaining a v10 client
File/Symbol: `scripts/dry-run-migration.sh` (NEW); referenced by BD-117 (RELEASE-GATE.md) and BD-118 (CI wiring) — both BDs should be updated to use the new file name when they implement
Description: Read-only migration dry-run harness that works for **any
  v10 client repo** — not just Optiquity's OT. Originally scoped as
  `dry-run-real-ot.sh` with OT's URL baked in; revised to be
  parameterized so the same harness serves Optiquity's release gate
  AND public users who maintain their own v10 clients.

  **Public-friendly design:**
  Required first arg = a git URL (HTTPS or SSH) OR a local filesystem
  path to a v10 client repo. The harness clones (URL) or copies (local
  path) read-only into /tmp, sets `pushurl` to `/dev/null` on the
  clone (push physically impossible from the working copy), auto-
  detects the target's current pack version via
  `detect_target_pack_version` (BD-119 lib/detect.sh), picks the
  appropriate `migrate-v<N>-to-v<N+1>.sh` from `scripts/`, runs it
  against the clone, captures the full diff to a report artifact, and
  removes the clone via EXIT trap regardless of pass / fail / Ctrl-C.
  Refuses to run if the working dir resolves anywhere outside /tmp or
  $TMPDIR. The original target (URL or local path) is never opened in
  write mode by this harness.

  **Three usage modes (all the same script):**
  1. *Synthetic fixture (CI / smoke test):* `dry-run-migration.sh
     test-fixtures/v10-realistic-ot` — works for everyone; no network
     required; serves as the regression floor.
  2. *Public user, their own v10 client:* `dry-run-migration.sh
     /path/to/their/v10/clone` or `dry-run-migration.sh
     https://github.com/their-org/their-v10-repo` — they preview the
     migration result before applying it for real.
  3. *Optiquity release gate:* `dry-run-migration.sh "$OT_URL"` —
     where `$OT_URL` is set via Optiquity's internal CI secret /
     env var; the URL is NOT hardcoded in the pack. Single code
     path, target supplied at invocation time.

  **Input contract** (documented in BD-125, the companion doc):
  target must be a clean v10 install (no uncommitted changes), no
  in-flight prior migration, accessible via `git clone` or readable
  as a local directory.

  Manual gate (not in CI for the URL-based modes since they touch
  network); the synthetic-fixture mode (#1 above) IS in CI per
  BD-118. Required before tagging v11.0, v12.0, ... etc.
Resolved: 2026-05-09 — work shipped earlier; status flip in Batch 5 hygiene. See `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-114.md`.

---

**BD-115 — `existing-project-mid-dev` fixture (pack added to in-progress project)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-116
File/Symbol: `test-fixtures/build.sh` (new builder), `test-fixtures/README.md`
Description: Today there is no fixture for "user has a real project
  mid-development and adds the pack on top." Persona coverage gap —
  currently zero. Add a deterministic builder `_build_existing_project_mid_dev`
  that produces a starting state with realistic non-pack content
  (e.g. Package.swift, src/, tests/, README, pre-existing .git/
  history) before any pack files are present. Used by BD-116 to assert
  `init-project.sh --update` lands the pack cleanly without clobbering
  user files. Version-agnostic: same fixture serves v11, v12, ... since
  the input shape (a generic in-progress project) doesn't change with
  pack version.
Resolved: 2026-05-08, v11.0 — `_build_existing_project_mid_dev` shipped
  in `test-fixtures/build.sh`, fixture lives at
  `test-fixtures/existing-project-mid-dev/` with deterministic SHA
  `a54e081a9e1d04f293bfb38fa0af77fd9f7f8619`. Mixed Swift+Python+gRPC
  starter shape (Package.swift + Sources/AcmeWidget/ + Tests/ +
  proto/catalog.proto + service/ + .gitignore + README.md), 3 commits
  of pre-existing project history, zero pack files. Two `--all --clean`
  runs produce byte-identical manifest; `--verify` exits 0. Documented
  in `test-fixtures/README.md` and pack-root `README.md` Repository
  Layout. Pack-reviewer audited the fixture (PACK-REVIEW-BD-115-BD-119)
  and accepted as correct; only finding was BD-118-scope (CI workflow
  needs `--all --clean` before `--verify` step), not a defect in the
  fixture itself. Trinity rule untouched.

---

**BD-116 — Persona contract assertions (template-derived expected output)**
Type: TODO(version)
Status: Open
Blockers: BD-115
Unblocks: BD-118
File/Symbol: `scripts/persona-contracts/` (new), `test-fixtures/build.sh`
Description: Today fixtures are *built* but no test asserts the result
  is *correct*. Silent regressions in `init-project.sh` or migrators
  go undetected. Add per-persona contract scripts that diff post-init /
  post-migration output against an expected manifest **derived from
  the pack templates themselves**, not hand-written. When
  `project-template/` or `init-project.sh` changes for v12, contracts
  auto-evolve — no per-release contract maintenance. Three contracts:
  (1) greenfield — init on empty dir matches template; (2) mid-dev —
  init --update on BD-115 fixture leaves user files intact + lands
  pack correctly; (3) migration — synthetic OT-shape fixture through
  migrator produces expected vN+1 shape with customizations preserved.

  **Sequencing note:** technically only BD-115 is a hard blocker — the
  migration contract could be wired against today's monolithic
  `migrate-v10-to-v11.sh` and pass, then auto-pass against the BD-119
  framework adapter post-cutover (C-5's behavior-preservation harness
  guarantees the adapter produces equivalent output). However, doing
  the migration contract pre-BD-119-close means duplicating effort if
  the contract assertion needs adjustment for the adapter's report.md
  or exit-code shape. Recommended: land BD-116 after BD-119 closes to
  avoid potential rework.
Resolved: n/a

---

**BD-117 — `RELEASE-GATE.md` per-major-version checklist**
Type: TODO(version)
Status: Open
Blockers: BD-114, BD-116
Unblocks: v11.0 tag; reused for every future major
File/Symbol: `maintenance-docs/RELEASE-GATE.md` (new)
Description: Authoritative pre-tag checklist that must complete before
  any major version vN+1 is tagged: (1) per-version migrator
  `migrate-v<N>-to-v<N+1>.sh` written using the BD-119 framework;
  (2) BD-114 dry-run against real OT passes with expected diff shape;
  (3) all three BD-116 persona contracts pass; (4) BD-118 CI workflow
  green on the release commit; (5) `test-fixtures/build.sh --verify`
  passes against committed manifest. Single document; updated with
  each release if the gate evolves.
Resolved: n/a

---

**BD-118 — CI wiring for persona contracts + fixture verification**
Type: TODO(version)
Status: Open
Blockers: BD-114, BD-115, BD-116
Unblocks: v11.0 ship
File/Symbol: `.github/workflows/validate-pack.yml`
Description: Wire BD-116 persona contracts and `test-fixtures/build.sh
  --verify` into validate-pack.yml so every push runs: (1) fixture
  rebuild + manifest verify (catches non-deterministic drift);
  (2) greenfield contract; (3) mid-dev contract (BD-115 fixture);
  (4) synthetic migration contract through `v10-realistic-ot` (or
  whichever vN-realistic fixture is current). BD-114 real-OT dry-run
  is **not** in CI — manual release-gate step per BD-117 since it
  touches a real network repo. Catches regressions before they ship.
Resolved: n/a

---

**BD-119 — General N→N+1 migrator framework (`scripts/lib/migrator-core.sh`)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-114, BD-120; every future per-version migrator
File/Symbol: `scripts/lib/migrator-core.sh` (new), `scripts/migrate-v10-to-v11.sh` (refactor)
Description: Today `migrate-v10-to-v11.sh` is monolithic — every
  release we'd write a new monolithic script and risk re-introducing
  the same defect classes (customization preservation, sidecar
  handling, BACKLOG migration, trinity diff, dry-run mode). Extract
  shared concerns into `scripts/lib/migrator-core.sh`. Each
  per-version migrator becomes a thin adapter that declares "what to
  add / remove / transform from vN to vN+1," and inherits the shared
  safety / preservation logic. Refactor `migrate-v10-to-v11.sh` to use
  the framework as the first consumer + reference implementation.
  Makes v12, v13, ... migration "just work" — no full rewrite per
  version.
Resolved: 2026-05-08, v11.0 — Framework shipped across 8 commits
  (C-1..C-7 + C-4b) per ARCHITECTURE-BD-119.md + PLAN-BD-119.md.
  3 new lib files: `scripts/lib/migrator-core.sh` (496 lines,
  6 frozen public-API functions + 8 exit-code constants +
  `EXIT_NOT_V10` synonym), `scripts/lib/migrator-stages.sh`
  (529 lines, 7 stage functions implementing architecture §6
  invariants), `scripts/lib/migrator-manifest.sh` (528 lines,
  4-verb declarative parser + dispatcher with trinity-parity
  validator). `scripts/migrate-v10-to-v11.sh` refactored from
  437-line monolith to 247-line adapter (5 `MIGRATOR_*` env vars +
  4 declarative hooks + post-dispatch hook for v10-specific
  inline behaviors). 3 new test scripts: `test-migrator-core.sh`
  (19 cases), `test-migrator-manifest.sh` (12 cases),
  `test-migrator-behavior-preservation.sh` (15 cases — 2 fixtures
  × 5 axes + 5 negative-leg exit-code parity tests). All wired
  into `validate-pack.yml` CI. New `validate-pack.py` Check 26
  enforces public-API surface lock + exit-code constants + lib
  presence + bash-n syntax. Cross-version dispatch via
  `detect_target_pack_version` (scripts/lib/detect.sh, 5-signal
  cascade) + `migrator_select_adapter` (filename-glob discovery).
  Pack-reviewer audited the batch (PACK-REVIEW-BD-115-BD-119);
  fix-follow `79f3aef` addressed 1 BLOCKER (PACK auto-resolve
  removal) + 5 SHOULD-FIX (CI wiring, harness expansion to 15/15,
  CHANGELOG mid-version revert, trinity wording alignment, Check 26
  docstring). Existing `test-migrate-v10-to-v11.sh` regression
  suite restored to 39/39 post-fix-follow. Trinity rule respected
  (CLAUDE/AGENTS/GEMINI byte-identical "Migrator framework" bullet).
  v12+ migrators are now small adapters atop the framework.
  **2026-05-10 addendum (BD-137):** the byte-equivalence harness
  (`scripts/test-migrator-behavior-preservation.sh`) was retired
  by BD-137. Its purpose — gating the BD-119 refactor by proving
  byte-equivalence vs the pre-refactor monolith pinned at SHA
  `d7b3f07` — is fulfilled. Post-refactor surface drift (banner
  changes from BD-104, etc.) cannot be accommodated by the harness
  per its anti-redaction policy (PLAN §13.3). The remaining BD-119
  test surface (`test-migrator-core.sh` 19 cases +
  `test-migrator-manifest.sh` 12 cases + Check 26) continues to
  guard the framework's public API and structural invariants.

---

**BD-120 — Parameterize realistic-OT fixture generator for any vN**
Type: TODO(version)
Status: Open
Blockers: BD-119
Unblocks: future-version migration testing
File/Symbol: `test-fixtures/build.sh`
Description: Today `_build_v10_realistic_ot` is hardcoded to v10. When
  OT migrates to v11, we'll need `v11-realistic-ot` as the *next*
  migration baseline (then v12-realistic-ot, etc). Refactor into
  `_build_realistic_for_version <vN>` so the same OT-shape
  customization patterns (project-name fills, x-agent on all 3 CLIs,
  ollama removed, TD BACKLOG) apply against any pack tag. Cheap once
  BD-119 establishes the per-version adapter pattern. Lets BD-114's
  dry-run harness exercise vN+1→vN+2 migrations once we ship v11.
Resolved: n/a

---

**BD-121 — Sunset v9 migration infrastructure**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-122 (test-fixtures convention doc no longer has to disambiguate from a live v9 system)
File/Symbol: `maintenance-docs/test-fixtures/` (DELETE), `scripts/test-migration.sh` (DELETE), `scripts/migrate-v9-to-v10.sh` (DELETE if present), `scripts/lib/three-way.sh` + 4 merge helpers in `scripts/lib/` (audit — keep if used by v10→v11 migrator, delete if v9-exclusive), `scripts/validate-pack.py` (remove v9-specific Checks — at least the test-migration harness check + the 4-merge-helpers check + the MIGRATION-v9-to-v10.md stages check), `supporting-docs/MIGRATION-v9-to-v10.md` (DELETE), `supporting-docs/MIGRATION-v10-to-v11.md` (3 references to remove/rephrase), `supporting-docs/SETUP-NEW.md` (1 reference), `supporting-docs/INSTALL-PROCEDURES.md` (4 references), `README.md` (audit), `CHANGELOG.md` (audit), `.github/workflows/validate-pack.yml` (audit — verify no standalone test-migration.sh invocation)
Description: Two parallel test-fixture systems exist today: the legacy
  `maintenance-docs/test-fixtures/` (v9.3 → v10 migration regression
  fixtures, BD-059 era; tracks fixture content in git via overlay-on-
  baseline pattern) and the newer `test-fixtures/` at repo root
  (BD-113; gitignored content, deterministic rebuild + manifest
  verification). No clients are on v9 anymore, so the v9→v10 migration
  script and its fixtures are dead code. Keeping them risks confusing
  contributors about which fixture system to extend and bloats CI.

  Scope is larger than initial estimate (validated against current
  repo state): validate-pack.py has multiple v9-specific checks tied
  to the migrate-v9-to-v10.sh script + its merge helpers + its
  documentation; supporting-docs/ has four files that reference v9
  migration tooling. All must be addressed in lockstep with the
  deletions or `validate-pack.py` will fail on the missing files
  immediately after `git rm`.

  Action plan for the implementer:
  1. Audit which `scripts/lib/` files are v9-only vs. shared with v10
     (`three-way.sh` is shared; 4 merge helpers may be v9-only — read
     them to determine).
  2. Delete v9-only library files; preserve shared ones.
  3. Delete `scripts/migrate-v9-to-v10.sh`, `scripts/test-migration.sh`,
     `maintenance-docs/test-fixtures/` (16 files), and
     `supporting-docs/MIGRATION-v9-to-v10.md`.
  4. Remove v9-specific Checks from `validate-pack.py` — typically the
     test-migration harness check, the merge-helper presence check,
     and the MIGRATION-v9-to-v10.md stages check. Renumber subsequent
     checks if numbering must stay sequential, otherwise leave gaps.
  5. Update `supporting-docs/MIGRATION-v10-to-v11.md` (3 references —
     "if you're on v9.x, run migrate-v9-to-v10.sh first" lines should
     become "v9.x is no longer supported; reach out for migration
     guidance" or similar).
  6. Update `supporting-docs/SETUP-NEW.md` (1 reference) and
     `supporting-docs/INSTALL-PROCEDURES.md` (4 references) similarly.
  7. Verify `.github/workflows/validate-pack.yml` does not invoke the
     deleted scripts standalone; remove any v9-only steps if found.
  8. Verify `python3 scripts/validate-pack.py` passes after all
     deletions + edits.

  **Do NOT modify CHANGELOG.md.** Per pack rule + PLAN-BD-119 §2.3,
  CHANGELOG is touched only at version boundaries (e.g., v11.0
  release). The v9 sunset will be summarized in the v11.0 CHANGELOG
  entry when v11 ships, alongside the other v11.0 scope items. The
  Resolved: line in this BACKLOG entry is the in-flight audit trail.

  If a v9 client unexpectedly surfaces post-deletion, they recover the
  migrator via `git checkout v9 -- scripts/migrate-v9-to-v10.sh` from
  history.
Resolved: 2026-05-09 — deletions shipped in `1daa938`; v10.1 backport pulled in residual cross-doc cleanup; bare-prose `(historical)` qualifiers added by BD-127 (PACK-REVIEW F-4). Status flip in Batch 5 hygiene.

---

**BD-122 — Document `test-fixtures/` `<vN>-<persona>` versioning convention**
Type: TODO(version)
Status: Resolved
Blockers: BD-121 (cleaner once the legacy system is gone)
Unblocks: future-version fixture additions (no re-derivation by next contributor)
File/Symbol: `test-fixtures/README.md`
Description: The root `test-fixtures/` directory holds fixtures named
  `<vN>-<persona>` (e.g. `v10-minimal`, `v11-flat-file`,
  `v11-tracker-on`, `existing-project-mid-dev`). The convention is
  implicit today; an explicit section in `test-fixtures/README.md`
  prevents future-vN contributors from re-deriving the layout or
  re-introducing a parallel system. Add a "Naming convention" section:
  major-version prefix for version-pinned fixtures (`v10-`, `v11-`,
  ...), bare descriptors for version-agnostic fixtures (`existing-
  project-mid-dev`). Add a "When to add a fixture here vs. elsewhere"
  paragraph. Keep it short — implementation is one or two paragraphs
  and a row-by-row update of the existing fixture table. Tiny.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-122.md`

---

**BD-156 — protobuf-patterns skill — extract Proto3 schema rules from grpc-patterns; standalone-usable via intersection table**
Type: TODO(version) — surfaced 2026-05-11 during BD-142 model-validation checkpoint discussion (gap in 5+3 model for standalone Protocol Buffers usage — Proto3 rules currently bundled inside `grpc-patterns` exclude non-gRPC scenarios); slotted before BD-149 per user direction so the `*-patterns` naming convention has a worked example AND so the standalone-protobuf gap closes before v11.0 ships
Status: Open
Blockers: BD-142 (PLATFORM-SKILLS.md intersection table must exist for the new skill row); BD-141 (predicate-helper precedent — `python_data_marker_detected()` pattern in `scripts/lib/detect.sh` that this BD's `protobuf_marker_detected()` mirrors)
Unblocks: BD-149 (naming-convention codification — `protobuf-patterns` is a worked example of the `*-patterns` convention; per user direction BD-156 is a hard blocker for BD-149 so the convention can be codified with a concrete reference and the standalone-protobuf gap is guaranteed to close before v11.0 ships); standalone Protocol Buffers usage in client projects (binary file format, IPC payloads, non-gRPC RPC frameworks like Twirp / Connect, persistent storage formats, log formats — currently uncovered by any skill)
File/Symbol: NEW `project-template/.claude/skills/protobuf-patterns/SKILL.md` + `.codex/skills/protobuf-patterns/SKILL.md` + `.gemini/skills/protobuf-patterns/SKILL.md` (trinity copies, byte-identical per Check 9); MODIFIED 3× `grpc-patterns/SKILL.md` trinity copies — Proto3 schema-design rules removed and cross-referenced to `protobuf-patterns`; gRPC-specific rules (servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics) retained; MODIFIED `project-template/docs/pack/PLATFORM-SKILLS.md` — new intersection-table row for `protobuf-patterns`; updated `grpc-patterns` description in dimensional-skills table to drop Proto3 schema language; updated `### Dimensional skills (16)` header to `(17)` and Full skill inventory totals (31 → 32 total); MODIFIED `scripts/lib/detect.sh` — new function `protobuf_marker_detected()` (markers: project tree contains any `.proto` files OR dependency manifests list any of `protobuf`, `swift-protobuf` / `SwiftProtobuf`, `grpc-tools`, `grpc-swift-2`, or `protoc` tooling); MODIFIED `scripts/init-project.sh` — wire `protobuf_marker_detected()` into `pack_skill_coverage_for()` for proto-marker detection at scaffold time; MODIFIED `scripts/add-capability.sh` — capability_skills row or comment cross-reference for protobuf-patterns intersection loading; MODIFIED `scripts/validate-pack.py` Check 31 (skill-cell consistency, added by BD-146) — must pass with new skill in intersection table
Description: Per the BD-142 model-validation checkpoint discussion (2026-05-11), the 5+3 dimension model has a gap for standalone Protocol Buffers usage. Today Proto3 schema rules are bundled inside `grpc-patterns` (D4=grpc) per the skill description "Proto3 schema, grpc-swift-2, grpc.aio, cross-language conventions" — honest for the pack's primary gRPC use case but excludes standalone protobuf scenarios (binary file format, IPC payloads, non-gRPC RPC frameworks like Twirp / Connect, persistent storage formats, log formats). Standalone protobuf has substantial schema-design rules independent of gRPC: field numbering invariants (never reuse, gaps OK, `reserved` keyword for safe deletion, 1-15 are 1-byte tags); backward / forward compatibility (additions OK with new tag; type changes mostly forbidden; `reserved` required for safe deletion); Proto3 vs Proto2 differences (`optional`, default values, presence); `oneof` semantics and migration rules; well-known types (Timestamp, Duration, Any, Empty, FieldMask, wrapper types); map types (lower compat-set than messages); code-generation options (`option swift_prefix`, `option java_package`, `option go_package`); imports and package conventions. BD-156 creates a new `protobuf-patterns` skill encoding these rules and loads it via the intersection table per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3.7 (matches the existing `python-data-architecture` pattern of intersection-cell loading by language ∩ marker). Predicate: any host language (D2=python ∪ D1-implied Swift / Kotlin / Java / Go / etc.) ∩ "project has `.proto` files" marker (or dependency manifest lists protobuf tooling). The new helper `protobuf_marker_detected()` in `scripts/lib/detect.sh` parallels BD-141's `python_data_marker_detected()`. Naming `protobuf-patterns` matches architecture §7.10 naming convention for cross-cutting concerns (parallels `grpc-patterns`, `rest-patterns`, `security-patterns`). Effect on `grpc-patterns`: refocused on gRPC-specific rules; the Proto3 schema-design rules currently bundled there move to `protobuf-patterns`; `grpc-patterns` ships with a one-paragraph "see `protobuf-patterns` for schema rules; load both when gRPC is in use" pointer. Loaded by: architect, grpc-schema, coder, reviewer, auditor-architecture, auditor-code (same agent set as `grpc-patterns` since the rules apply to the same concern set). JSON / YAML / TOML are explicitly NOT given their own skills in this BD per the BD-142 model-validation discussion — their standalone rules are minimal and fold into `api-design` (Tier 0) and `rest-patterns` (D4=rest); a separate BD can be opened later if standalone schema work for those formats becomes a need.
Resolved:

---

**BD-150 — CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh**
Type: TODO(version) — Batch 11 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 11)
Status: Open
Blockers: BD-146 (Check 31 must gate the new tables before the version-row CHANGELOG entry goes in), BD-148 (MIGRATION + MERGE-STRATEGY behavioral notes must exist before CHANGELOG quotes them)
Unblocks: v11.0 release-pin readiness (cross-cutting with BD-093 release pin); machine-readable skill counts in README are reconciled to post-reframe reality; downstream Phase 2A architect handoff (per `PLAN-SKILL-DIMENSIONS.md` §6)
File/Symbol: `CHANGELOG.md` v11.0 section (single entry referencing BD-141..BD-150 cluster as "skill-dimensions reframe — 5 dimensions + Tier 0 + intersection + trigger tables; behavioral note per `MIGRATION-v10-to-v11.md`"); `README.md` skill-count mentions ("30 skills" / "31 skills" instances must be reconciled to the post-reframe count); `README.md` v11.0 row in version table picks up the reframe BD references
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 11, the closing batch of the skill-dimensions reframe lands the CHANGELOG entry plus README skill-count refresh. Single CHANGELOG.md v11.0 entry referencing the BD-141..BD-150 cluster. README.md "30 skills" / "31 skills" mentions reconciled to the post-reframe count (which depends on whether the python split BD landed before or after the count was last touched — implementor verifies via `grep -n "skill" README.md`). README v11.0 row in version table picks up the reframe BD references. Critical-path gating per `PLAN-SKILL-DIMENSIONS.md` §1: BD-146 (Check 31 internal-consistency gate) and BD-148 (MIGRATION + MERGE-STRATEGY behavioral note) must have shipped first.
Resolved:

---

**BD-149 — PLATFORM-SKILLS.md "Extending this file" naming convention codification (no skill renames)**
Type: TODO(version) — Batch 10 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 10)
Status: Open
Blockers: BD-142 (PLATFORM-SKILLS.md must be reframed before the "Extending this file" section can codify the new convention); **BD-156 (HARD BLOCKER per user direction 2026-05-11 — `protobuf-patterns` skill must exist before BD-149 ships so the `*-patterns` naming convention has a worked example AND so the standalone-protobuf gap closes before v11.0 ships; this guarantees BD-156 is not lost / forgotten / deferred)**
Unblocks: BD-155 (the v12 enforcement migration — cannot rename existing skills to comply with a convention that has not yet been codified)
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" section (NEW or extended; documents the four-suffix naming convention)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10, the skill catalog has four suffixes in active use: `*-best-practices` (`swift-best-practices`, `python-best-practices` — language style); `*-language` (`c-language`, `cpp-language`, `objc-language` — language structure where ownership / memory / interop dominate); `*-architecture` (`ios-architecture`, `macos-architecture`, `python-server-architecture`, `python-data-architecture`, `apple-architecture-core` — platform-specific structural rules); `*-patterns` (`grpc-patterns`, `rest-patterns`, `security-patterns`, and the new `protobuf-patterns` per BD-156 — cross-cutting concerns). The convention is not enforced; BD-149 documents it explicitly in PLATFORM-SKILLS.md "Extending this file" section per architecture §7.10 recommended disposition. Existing skills are NOT renamed in v11.0 — the cost of breaking external references outweighs the consistency benefit at this point; new skills must follow the convention. **BD-156 (`protobuf-patterns` skill creation) is a hard blocker per user direction 2026-05-11** — the new skill is a worked example of the `*-patterns` convention and ensures the standalone-protobuf gap (surfaced during BD-142 model-validation checkpoint) closes before v11.0 ships. Enforcement migration (renaming existing non-compliant skills) is deferred to v12 (BD-155).
Resolved:

---

**BD-148 — MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md skill-model-changes documentation**
Type: TODO(version) — Batch 9 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 9)
Status: Open
Blockers: BD-142 (PLATFORM-SKILLS.md reframe must exist before MIGRATION + MERGE-STRATEGY can describe the change), BD-143 (trinity prose must be updated before MIGRATION can reference the new Skill-loading section)
Unblocks: BD-150 (CHANGELOG entry references the MIGRATION + MERGE-STRATEGY behavioral notes); v11.0 release-pin readiness on the migration-doc surface
File/Symbol: `supporting-docs/MIGRATION-v10-to-v11.md` (new "Skill model changes" section documenting the reframe as a behavioral note per architecture §7.8); `supporting-docs/MERGE-STRATEGY.md` (per-file matrix entry for PLATFORM-SKILLS.md updated to note the reframe; D5 monorepo gotcha per architecture §7.4; D2 reshape advisory per architecture §7.6); cross-link to BD-136 trinity-marker non-overlap (architecture §6.7); `project-template/docs/pack/PLATFORM-SKILLS.md` `## Custom agents` table column-header rename (deferred from BD-142 F3 — requires Procedure-5 coordination); `supporting-docs/INSTALL-PROCEDURES.md` Procedure 5 (column-write logic and any procedure prose referencing the deprecated `Tier 1 skills | Tier 2 skills` column convention)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 9, MIGRATION-v10-to-v11.md and MERGE-STRATEGY.md gain skill-model-change documentation. Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.8, the dimension reframe is a pack-product change masquerading as a doc change — PM chats re-read PLATFORM-SKILLS.md every time they generate a prompt, so the actual impact is minimal, but the v11.0 release notes and migration doc must call it out as a behavioral change, not a doc-only change. MIGRATION-v10-to-v11.md gets a new "Skill model changes" section. MERGE-STRATEGY.md per-file matrix entry for PLATFORM-SKILLS.md is updated; D5 monorepo gotcha (architecture §7.4 — "deployment skills load globally; agent prompts scope to component") and D2 reshape advisory (architecture §7.6 — "if you have locally edited PLATFORM-SKILLS.md, re-apply your edits manually") are documented. Cross-link to BD-136 trinity-marker non-overlap (architecture §6.7) confirms PLATFORM-SKILLS.md edits do not overlap with trinity Shape A / Shape B marker territory. **Includes BD-142 F3 deferred fix:** `## Custom agents` table column header `Tier 1 skills | Tier 2 skills` (PLATFORM-SKILLS.md line 510 in the v11.0 reframe state) reflects deprecated pre-v11 framing — replace with new-model-aligned headers (recommended: `Base skills | Dimensional skills`, but the exact convention is a Procedure-5 design decision). The rename touches a section that BD-142 preserved byte-identical to maintain BD-088 customization-preserve invariants; BD-148 is the right batch for it because it (a) coordinates with the Procedure-5 column-write logic in INSTALL-PROCEDURES.md and (b) ships in MIGRATION-v10-to-v11.md as part of the documented skill-model migration so client projects that already have Custom agents rows know to re-apply with the new header convention. See `maintenance-docs/v11-implementation/PACK-REVIEW-BD-142.md` §10 F3 for the original finding.
Resolved:

---

**BD-147 — Extract S5b BD-035 rename helper into scripts/lib/migrator-skills.sh + Check 26 extension + BD-119 docs update**
Type: TODO(version) — Batch 8 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 8 + §7.2 expanded scope)
Status: Open
Blockers: BD-142 (the reframe must establish the post-v11 skill catalog before the rename helper is generalized; otherwise the API would be designed against the v10 skill set)
Unblocks: future N→N+1 migrations needing skill renames or splits (e.g., the v12 BD-155 naming-convention enforcement migration); cleaner BD-119 migrator-core composition (skill-rename becomes a reusable adapter rather than an ad-hoc S5b inline helper)
File/Symbol: NEW `scripts/lib/migrator-skills.sh` (extracts BD-035 rename helper into reusable `migrator_skill_rename` API per architecture §6.5); `scripts/migrate-v10-to-v11.sh` S5b stage (rewritten to call the extracted helper); `scripts/validate-pack.py` Check 26 extension (recognizes the new lib in the migrator-core sourcing graph); `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` (docs update describing `migrator-skills.sh` as a sibling to `migrator-core.sh`); golden-snapshot fixture in `test-fixtures/v10-realistic-ot/` (pre-extraction migrator S5b output state-dir, used as behavior-equivalence baseline per BD-035 regression risk in `PLAN-SKILL-DIMENSIONS.md` §4.5)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.5 and `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 8 + §7.2 expanded scope, the BD-035 rename helper currently lives inline in the `scripts/migrate-v10-to-v11.sh` S5b stage. Extracting it into `scripts/lib/migrator-skills.sh` makes it reusable for future N→N+1 migrations needing skill renames or splits (notably the v12 BD-155 naming-convention enforcement migration). New API: `migrator_skill_rename <old-skill-dir> <new-skill-dir> [<advisory-text>]` plus a future `migrator_skill_split` for one-to-many cases (forward-declared; BD-035 only needs rename in v11.0). S5b is rewritten to call the extracted helper. Behavior-equivalence test per `PLAN-SKILL-DIMENSIONS.md` §4.5 mitigation: golden-snapshot the migrator's S5b output state-dir against the v10-realistic-ot fixture pre-extraction; compare post-extraction byte-for-byte. validate-pack.py Check 26 (BD-119 migrator-core sourcing graph) extended to recognize `migrator-skills.sh`. ARCHITECTURE-BD-119.md updated to describe the new sibling library.
Resolved:

---

**BD-146 — validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension**
Type: TODO(version) — Batch 7 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 7)
Status: Open
Blockers: BD-142 (Check 31 parses the new D1-D5 + Tier 0 + intersection tables — they must exist first), BD-143 (Check 31 also verifies agent files' "Skills to load" lists conform to the reframe-derived per-agent assignment; trinity prose update must precede)
Unblocks: BD-150 (CHANGELOG entry depends on Check 31 gating — proves the new tables are internally consistent before the version-row CHANGELOG goes in); ongoing CI gate for any future PLATFORM-SKILLS.md edit
File/Symbol: `scripts/validate-pack.py` NEW Check 31 (parses `project-template/docs/pack/PLATFORM-SKILLS.md`; verifies every existing SKILL.md under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` appears in exactly one cell of the D1-D5 / Tier 0 / trigger-loaded tables; verifies no skill is missing or double-counted); Check 27 extension (extends agent-file `Skills to load:` validation to conform to per-agent assignment derived from the new tables per architecture §5)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 7 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3-§5 + §3.7-§3.8, validate-pack.py gains Check 31 enforcing skill-cell consistency: every SKILL.md appears in exactly one cell across D1-D5 + Tier 0 + trigger-loaded tables; no orphan SKILL.md (present on disk but missing from PLATFORM-SKILLS.md); no phantom cell (referenced in PLATFORM-SKILLS.md but no SKILL.md on disk). Check 27 (per-agent skill-list validation, currently agent-file scoped) extends to verify the listed skills conform to the per-agent assignment derived from the new tables (architecture §5.1-§5.9). Per `PLAN-SKILL-DIMENSIONS.md` §4.3, the next free check number is 31; coder must `grep -nE "Check [0-9]+" scripts/validate-pack.py | tail` immediately before coding to verify still-free in case of mid-flight collision.
Resolved:

---

**BD-145 — init-project.sh — D1/D5 detection hint + python-data marker integration**
Type: TODO(version) — Batch 6 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 6)
Status: Open
Blockers: BD-141 (`python_data_marker_detected()` must exist for `pack_skill_coverage_for()` to call it), BD-142 (post-install hint points the PM chat at the new D1-D5 tables — those must exist first)
Unblocks: clean fresh-init flow under the reframed dimension model; eliminates the "init unconditionally lists `python-data-architecture`" detection inconsistency per architecture §7.5
File/Symbol: `scripts/init-project.sh` `pack_skill_coverage_for()` (line 219-228) — wires `python_data_marker_detected()` from BD-141 for the python row; post-install hint output at end of init pointing the PM chat at the new D1-D5 tables in PLATFORM-SKILLS.md
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 6, init-project.sh's `pack_skill_coverage_for()` is extended to (a) consult D1/D5 markers when listing applicable skills (per the reframed dimension model from BD-142), and (b) call `python_data_marker_detected()` from BD-141 for the python row so `python-data-architecture` is loaded conditionally rather than unconditionally. Per architecture §7.5 the current behavior at line 224 unconditionally lists `python-data-architecture` even for projects that are pure Python scripts with no data-access markers — a known detection inconsistency. Post-install hint at end of `init-project.sh` adds a one-liner pointing the PM chat at the new D1-D5 tables in PLATFORM-SKILLS.md so first-edit awareness lands at the right moment. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene mitigation: `ls -l scripts/init-project.sh` after editing to confirm `-rwxr-xr-x` exec bit unchanged.
Resolved:

---

**BD-144 — add-capability.sh D5 rename (role:apple-app → deployment:apple) + role:python-server intersection fix + v10→v11 migrator translation**
Type: TODO(version) — Batch 5 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 + §7.1 expanded scope)
Status: Open
Blockers: BD-142 (the reframe must establish D5 deployment surface and the new D2 ∩ D3 intersection model before add-capability.sh can be aligned)
Unblocks: clean `add-capability.sh` UX under the reframed dimension model; v10→v11 migrator translation stage so existing client `tracker.toml` / `add-capability` invocations keep working
File/Symbol: `scripts/add-capability.sh` — RENAME row `role:apple-app` → `deployment:apple` (D5 dimension assignment); NEW rows `deployment:linux-container` / `platform:android` / `platform:web-browser` / `platform:embedded-mcu` (forward-declared per `PLAN-SKILL-DIMENSIONS.md` §4.6 — SKILL.md files ship in Phase 3); FIX `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` (drops the obsolete `deployment-python`, per architecture §3.3 + §3.5 corrected intersection); `scripts/migrate-v10-to-v11.sh` NEW translation stage that maps any `role:apple-app` in client `tracker.toml` to `deployment:apple` per §7.1 expanded scope; golden-snapshot fixture for the migrator translation in `test-fixtures/v10-realistic-ot/`
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 and §7.1 expanded scope, add-capability.sh is realigned to the reframed dimensions: `role:apple-app` becomes `deployment:apple` (D5 — deployment surface, the missing dimension per architecture §3.5); new rows for `deployment:linux-container` (D5), `platform:android` / `platform:web-browser` / `platform:embedded-mcu` (D1 — runtime/OS substrate, per architecture §3.1) are added as forward-declared (the SKILL.md files ship in Phase 3 per `PLAN-SKILL-DIMENSIONS.md` §6; default to gating with directory-exists check + warning per §4.6 mitigation); `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` and DROPS the obsolete `deployment-python` (per architecture §3.3 + §3.5 corrected D2 ∩ D3 intersection — the old `deployment-python` was a misnamed catch-all). v10→v11 migrator translation stage maps any `role:apple-app` in a client's existing `tracker.toml` (or other capability config) to `deployment:apple` so existing client invocations keep working. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene: `ls -l scripts/add-capability.sh scripts/migrate-v10-to-v11.sh` after editing to confirm exec bit unchanged.
Resolved:

---

**BD-143 — Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list**
Type: TODO(version) — Batch 4 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 4)
Status: Open
Blockers: BD-142 (trinity prose points at PLATFORM-SKILLS.md as the authoritative reframe — the file must be reframed first)
Unblocks: BD-146 (Check 31 verifies agent files' "Skills to load" lists against the reframed per-agent assignment — those lists must be updated first), BD-148 (MIGRATION + MERGE-STRATEGY can reference the new Skill-loading section)
File/Symbol: `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` "Skill loading" section (trinity-replicated; reframe prose to 5-dimension D1-D5 + Tier 0 + intersection model; retire "Tier 1 / Tier 2" nomenclature); pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` parallel edits per Trinity rule; `audit-methodology/SKILL.md` rule 20 (cross-platform UI bullet seam extension per architecture §6.1, §6.3); `architecture-review/SKILL.md` skill-list update (4 trinity copies under `.claude/skills/` / `.codex/skills/` / `.gemini/skills/`; pack-repo template + project-template instances)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 4 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.1 + §6.3, the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) carry "Skill loading" prose that must be re-aligned to the reframed 5-dimension model; "Tier 1 / Tier 2" nomenclature is retired (per architecture §3.6-§3.9 the new model is Tier 0 base + D1-D5 dimensions + trigger-loaded). Trinity rule applies: project-template trinity AND pack-repo trinity get the parallel edit in the same set of changes (pack-repo CLAUDE.md / AGENTS.md / GEMINI.md). audit-methodology/SKILL.md rule 20 extended for the cross-platform UI bullet seam (per architecture §6.3 — the rule currently has Apple-specific UI accessibility hardcoded; extension lets the auditor consume PLATFORM-SKILLS.md to find applicable UI skills per architecture §7.7). architecture-review/SKILL.md skill list updated under all four trinity copies. Per `PLAN-SKILL-DIMENSIONS.md` §4.1 trinity-violation mitigation: verification step requires `diff` between every pair of trinity files in the section body and `diff` between every pair of architecture-review SKILL.md copies; Check 9 (init-project structure) and Check 18 (trinity H2 parity) enforce structurally.
Resolved:

---

**BD-142 — PLATFORM-SKILLS.md — 5 dimensions + Tier 0 + intersection + trigger tables**
Type: TODO(version) — Batch 3 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 3)
Status: Resolved
Blockers: BD-141 (PLATFORM-SKILLS.md text references `python_data_marker_detected()` for the python-data-architecture row; the helper must exist first)
Unblocks: BD-143 (trinity Skill-loading prose), BD-144 (add-capability.sh D5 rename), BD-145 (init-project.sh detection), BD-146 (validate-pack Check 31), BD-147 (migrator-skills.sh extraction), BD-148 (MIGRATION + MERGE-STRATEGY docs), BD-149 (naming-convention codification) — all downstream batches depend on the reframed PLATFORM-SKILLS.md
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` — major rewrite per architecture §3-§5: D1 (Runtime / OS substrate), D2 (Cross-platform languages), D3 (Component role / app-layer), D4 (Communication protocols), D5 (Deployment surface) tables; Tier 0 base-skills section (loaded for every project, every agent, per architecture §3.6); intersection-table sparse-cell layout (per architecture §3.7); trigger-loaded skills section (loaded by agent role, not project shape, per architecture §3.8); preserve project-owned `## Custom agents` and `## Custom skills` sections (lines 310-345) byte-identical per `PLAN-SKILL-DIMENSIONS.md` §4.4
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 3 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3-§5, PLATFORM-SKILLS.md is rewritten to the explicit five-dimension model + 3 orthogonal load mechanisms (Tier 0 base + dimension-implied + trigger-loaded). The reframe replaces the implicit four-dimension model documented today: D1 Runtime/OS substrate (apple-platform, linux, windows, web-browser, android, embedded-mcu); D2 Cross-platform languages (only swift / c / cpp / objc / python that have multi-platform applicability); D3 Component role / app-layer (cli, daemon, ui-app, library, service); D4 Communication protocols (grpc, rest, websocket); D5 Deployment surface NEW (apple-distribution, linux-container, native-binary, web-deploy). Tier 0 base skills load for every project, every agent (e.g., `audit-methodology`, `architecture-review`, `documentation`). Intersection table is sparse — most cells empty (per architecture §3.7). Trigger-loaded skills load by agent role (per architecture §3.8 — e.g., `repo-ops` triggers `git-operations`). Per `PLAN-SKILL-DIMENSIONS.md` §4.4, the project-owned `## Custom agents` and `## Custom skills` sections at lines 310-345 are NOT edited (BD-088 customization-preserve sidecar tests depend on the illustrative `x-deployer` / `x-brokerage-api` rows). No SKILL.md content changes in this batch — those are deferred to Phase 2A/2B/3.
Resolved: 2026-05-11 — see commit 58f79f0 (`feat: v11 — BD-142 PLATFORM-SKILLS.md reframed as 5 dimensions + Tier 0 + intersection + trigger tables`); pack-reviewer F1 SHOULD-FIX (header arithmetic mismatch 15 vs 16) + F2 SHOULD-FIX (silent omission of 3 pack-repo trigger-loaded skills) + F4 NIT (D1 framing-rule "executable target" too narrow) all resolved in-session; F3 NIT (Custom agents column-header rename) deferred to BD-148 (which now has F3 scope explicitly recorded in its File/Symbol + Description fields); 31 skills enumerated correctly (13 Tier 0 + 16 dimensional/intersection + 1 trigger + 1 PM-chat); custom sections byte-identical; validate-pack 30/30 PASS.

---

**BD-141 — Concrete python-data-architecture load predicate (lib/detect.sh marker function)**
Type: TODO(version) — Batch 2 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 2)
Status: Resolved
Blockers: BD-140 (BACKLOG entries must exist before downstream batches reference each other by BD number)
Unblocks: BD-142 (PLATFORM-SKILLS.md text references the helper for the python-data-architecture row), BD-145 (init-project.sh `pack_skill_coverage_for()` calls the helper)
File/Symbol: `scripts/lib/detect.sh` — NEW function `python_data_marker_detected()` around line 230 (after `detect_installed_capabilities`), sourceable by init-project.sh and add-capability.sh (~30-40 LoC); `scripts/init-project.sh` `pack_skill_coverage_for()` (line 219-228) — wires the helper for the python row (~5-line change); `scripts/add-capability.sh` A1 resolver — comment-references the helper as the canonical predicate when `language:python` is added without explicit `role:python-server` (~5-10 line change near line 110)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.5 and `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 2, the current `python-data-architecture` load predicate is fuzzy ("multi-file Python with data access, async I/O, or ML inference; otherwise omit" — PLATFORM-SKILLS.md line 54); init-project.sh `pack_skill_coverage_for python` row (line 224) unconditionally lists it; auditor-architecture (line 198) tries to thread the conditional through prose — detection inconsistency between init-project, add-capability, and PM chat is possible. BD-141 makes the predicate concrete: new function `python_data_marker_detected()` in `scripts/lib/detect.sh` returns yes if ANY of these markers are true: (a) `requirements.txt` or `pyproject.toml` lists any of `sqlalchemy`, `alembic`, `pydantic`, `aiohttp`, `httpx`, `psycopg`, `aiomysql`, `asyncpg`, `redis`, `pymongo`, `motor`, `boto3`, `aioboto3`, `grpc-tools`, `protobuf`, `pyarrow`, `pandas`, `numpy`, `scikit-learn`, `torch`, `tensorflow`; (b) ≥5 `.py` files outside `tests/`. Implementation uses `grep -lE` and `find ... -not -path '*/tests/*' | wc -l`. init-project.sh `pack_skill_coverage_for()` calls the helper for the python row; add-capability.sh A1 resolver comment-references the helper as the canonical predicate. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene: `ls -l scripts/lib/detect.sh scripts/init-project.sh scripts/add-capability.sh` after editing to confirm exec bit unchanged (lib/detect.sh is sourced, not exec).
Resolved: 2026-05-11 — see commit a64c639 (`feat: v11 — BD-141 python_data_marker_detected() helper for python-data-architecture predicate`); pack-reviewer F-1 BLOCKER (regex POSIX-ERE bracket-class defect failing versioned manifests like `sqlalchemy>=2.0`) resolved in-session by replacing positive bracket class with negated character classes `(^|[^A-Za-z0-9_-])(${pkgs})($|[^A-Za-z0-9_.-])`; F-2 NIT (parser tightness) resolved in-session by comparing full literal `python-data: yes` instead of awk-parsing; 16/16 verification cases PASS post-fix; validate-pack 30/30 PASS.

---

**BD-140 — Skill-dimensions reframe — BACKLOG entries (umbrella)**
Type: TODO(version) — surfaced 2026-05-11 during pack-planner Phase 1 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 1; spawns BD-141..BD-150 sequenced batches plus BD-151..BD-155 v12-deferred entries)
Status: Resolved
Blockers: none
Unblocks: BD-141..BD-150 (the 10 sequenced execution batches of the skill-dimensions reframe); BD-151..BD-155 (the 5 v12-deferred entries created inline by this batch)
File/Symbol: `BACKLOG.md` (this file — the only file edited in BD-140's batch); references `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` as the authoritative plan + architecture for the reframe
Description: Umbrella BD for the skill-dimensions reframe v11.0 work. Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §0 batch summary and §2 per-batch detail, BD-140 is the BACKLOG-ops batch that lands the 16 new BD entries (BD-140..BD-155) all in one commit and unblocks downstream sequenced execution. The reframe replaces the implicit four-dimension PLATFORM-SKILLS.md model with an explicit five-dimension model (D1 Runtime/OS substrate, D2 Cross-platform languages, D3 Component role / app-layer, D4 Communication protocols, D5 Deployment surface NEW) plus 3 orthogonal load mechanisms (Tier 0 base, dimension-implied, trigger-loaded), plus `scripts/lib/migrator-skills.sh` extraction (BD-147), naming-convention codification (BD-149), and supporting trinity / validator / migrator / docs work. BD-141..BD-150 sequence the v11.0 execution per the critical-path diagram in `PLAN-SKILL-DIMENSIONS.md` §1 (BD-140 → BD-141 → BD-142 → BD-143 → BD-146 → BD-150 critical path). BD-151..BD-155 are v12-deferred items recorded inline per architecture §7.1 (observability skill), §7.2 (accessibility skill), §7.3 (concurrency-architecture skill), §7.9 (skill-versioning frontmatter), §7.10 (naming-convention enforcement migration). After BD-150 ships, Pack Chat spawns a fresh `pack-architect` session for Phase 2A per `PLAN-SKILL-DIMENSIONS.md` §6 (per-skill rule designs for `web-architecture`, `android-architecture`, `embedded-mcu-architecture`).
Resolved: 2026-05-11 — see commit dba6dc0 (`docs: v11 — BD-140 BACKLOG entries for skill-dimensions reframe ...`); pack-reviewer SHOULD-FIX-1+2 (Status: Deferred entries placed in Active section) resolved in-session by relocating BD-151..BD-155 to `## Deferred` section in ascending order; 2 NITs skipped per user decision; validate-pack 30/30 PASS.

---

**BD-139 — BD-104 audit fix-follow (1 MAJOR + 2 MINOR + 2 NIT)**
Type: TODO(version) — fix-follow per standing rule §5.B (Batch 12 audit `maintenance-docs/v11-implementation/AUDIT-BD-104.md`, 2026-05-10)
Status: Resolved
Blockers: none — purely fix-follow polish + the missing test
Unblocks: closes the BD-104 audit; restores test-coverage compliance with `IMPLEMENTATION-PLAN-ADDENDUM-3.md:235`
File/Symbol:
  - `scripts/tests/test-migrate-v10-to-v11.sh` — extend with 4 BD-104 test cases (F-1, MAJOR): rename happy-path; source-absent no-op; untracked-source `mv` fallback; `migration-rename-collision` typed-error contract per `scripts/lib/tracker-errors.sh` lines 25-31. ~80 lines bash + assertions. Spec reference: `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-3.md:235`.
  - `supporting-docs/MIGRATION-v10-to-v11.md` lines 119-129 — update stage table to include the new S4 rename stage (F-2, MINOR). User-facing doc currently never mentions the BD-104 rename.
  - `scripts/migrate-v10-to-v11.sh` — disambiguate the two functions both emitting "── S4 ──" banner (F-3, MINOR). Either give the second a distinct stage label OR add a sub-banner that distinguishes. Current ambiguity confuses both stdout output and `fail_stage` reports.
  - `scripts/migrate-v10-to-v11.sh` lines 191-201 — surface `$mv_stderr` in the git-mv fallback failure path (F-4, NIT). Currently silently dropped, hindering operator diagnostics.
  - `BACKLOG.md` BD-104 Resolved line + commit message of `ef20113` + `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` (if applicable) — reconcile the allowlist count (F-5, NIT). Audit found 181 remaining `IMPLEMENTATION_PLAN` references; docs say 179. Either find the 2 missing allowlist entries to bring to 179, OR correct the docs to say 181.
Description: Standing rule §5.B mandates fix-follow BDs for every audit finding including NITs. BD-104 audit (`maintenance-docs/v11-implementation/AUDIT-BD-104.md`) surfaced 1 MAJOR + 2 MINOR + 2 NIT. The MAJOR (F-1) is a real test-coverage gap — all four BD-104 migrator code paths (rename happy-path, source-absent no-op, untracked `mv` fallback, `migration-rename-collision` typed-error contract) are uncovered. Spec `maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-3.md:235` explicitly calls for the test extension. The other 4 findings are smaller (doc table, banner disambiguation, stderr surfacing, count reconciliation). All 5 fit one batch; one commit.
Resolved: 2026-05-11 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-139.md`. All 5 findings PASS. F-1 (MAJOR): added Group 5 with 4 BD-104 cases to `scripts/tests/test-migrate-v10-to-v11.sh`; test count 39 → 43. F-2 (MINOR): `supporting-docs/MIGRATION-v10-to-v11.md` stage table now distinguishes S4a (rename) and S4b (relocate) with a lead-in note; exit-code table updated to reflect the merged S4 framework stage. F-3 (MINOR): banners in `scripts/migrate-v10-to-v11.sh` relabeled to `S4a (rename)` / `S4b (relocate)` with sub-stage prefixes in fail_stage messages (`S4a-rename:` / `S4b-relocate:`); the `fail_stage S4` arity is preserved so the BD-095 sentinel (`stage-S4.done`) and exit code 24 stay stable. F-4 (NIT): added `info "git mv hint (taking untracked-fallback branch): $mv_stderr"` to surface the captured stderr in the BD-104 fallback branch. F-5 (NIT): clarified `BACKLOG.md` BD-104 Resolved line — the "179" figure is point-in-time at commit `ef20113`; the audit's "181" represents legitimate post-commit BACKLOG growth (BD-138 + BD-139 entries themselves added new references), NOT an allowlist defect. Validator: 30 checks PASS. All test suites green: 43/43 + 19/19 + 12/12 + 40/40. Co-shipped with BD-101 (Batch 13 part 2) — both ran in parallel under separate pack-coder agents; both edits to `scripts/migrate-v10-to-v11.sh` coexist line-disjoint.

---

**BD-138 — Schedule BD-136 implementation as a v11.0 batch (no v11.1 deferral)**
Type: TODO(version) — surfaced 2026-05-10 during v11.0 plan review (no batch was scheduled for BD-136 implementation despite BD-136 being a v11.0 ship-gate item per user direction)
Status: Resolved
Blockers: none
Unblocks: BD-136 implementation actually happens in v11.0; downstream Batch 21 (BD-100 final audit) and Batch 22 (BD-102 dog-food) can rely on the marker-aware merger being live
File/Symbol:
  - `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` — insert new **Batch 20b** for BD-136 implementation between Batch 20 (auditor agents) and Batch 21 (BD-100 final audit). Batch 20b is sequential (4 sub-commits — see scope below). Update Batch 21 (BD-100) audit scope to include BD-136 verification. Update Batch 22 (BD-102) to specify dog-food MUST exercise the marker-aware merge path.
  - `BACKLOG.md` — this entry (BD-138) flips to Resolved in the same commit as the EXECUTION-PLAN amendment.
Description: BD-136 currently has spec (3 amendments) but no scheduled implementation batch. Without a batch slot it would default-slip to v11.1. User direction (2026-05-10): no v11.1 deferral — schedule it. Batch 20b lands BD-136 implementation in 4 sub-commits: (1) marker-aware merger in `scripts/lib/customization-preserve.sh` (or new sibling `marker-preserve.sh`) implementing L-1..L-10 + the override mechanism; (2) `scripts/validate-pack.py` new Check enforcing V-1..V-8 validator surface; (3) PM-CHAT.md authoring procedure section (P-1..P-8) + cross-references in INSTALL-PROCEDURES.md / SETUP-NEW.md / SETUP-EXISTING.md / init-project.sh post-install hint + seed Shape A marker pair in `project-template/{CLAUDE,AGENTS,GEMINI}.md` + `[CONDITIONAL]` retirement in canonical templates; (4) `scripts/tests/test-customization-preserve-bd136.sh` covering M-1..M-10 + add M-11/M-12 fixtures to `test-fixtures/`. Each sub-commit is independently approve-able per the stop-before-commit rule. Existing M-8 fixture (`test-fixtures/v11-trinity-marker-prepped/`) becomes the round-trip golden the merger must reproduce byte-identical.
Resolved: 2026-05-10 — EXECUTION-PLAN-V11.0.md amended to insert Batch 20b for BD-136 implementation; Batch 21 (BD-100) and Batch 22 (BD-102) scope updated to reference BD-136 verification + marker-aware merge path. BD-138 was a scheduling-only BD; resolved in the same commit as the plan amendment.

---

**BD-137 — Retire `scripts/test-migrator-behavior-preservation.sh` (BD-119 byte-equivalence harness)**
Type: TODO(version) — fast-follow from BD-104 commit (2026-05-10) + standing rule §5.B
Status: Resolved
Blockers: none (BD-119 refactor it gated has shipped at commit `91a9fc5` — Batch 11)
Unblocks: green CI on the `tests` job (currently red on `test-migrator-behavior-preservation.sh` after BD-104's stdout banner intentionally diverged from the pre-refactor monolith pinned at SHA `d7b3f07`)
File/Symbol:
  - `scripts/test-migrator-behavior-preservation.sh` — DELETE (entire file). The harness was created for BD-119 to prove the migrator-core refactor preserved monolith behavior byte-equivalent. The refactor shipped clean; the harness's purpose is fulfilled. Its header (PLAN §13.3) explicitly forbids redaction-based fixes for surface drift, so it cannot adapt to legitimate post-refactor banner / stdout changes.
  - `.github/workflows/validate-pack.yml` — remove the harness invocation from the `tests` job. Verify the rest of the test job remains intact.
  - `scripts/tests/` directory — audit for any other test that sources or invokes the harness; remove the dependency if present.
  - `BACKLOG.md` BD-119 entry — append a Resolved-line addendum noting the harness retirement (the BD-119 entry itself is already Resolved; this is just a paper-trail update).
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-104.md` POQ-1 — mark resolved by BD-137.
  - `supporting-docs/MIGRATION-v10-to-v11.md` — audit for any reference to the harness; remove if present (low likelihood — the harness was internal pack tooling).
Description: BD-104's pack-side string sweep (Batch 12) included one rename in the migrator's stdout (a banner line referencing `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`). The BD-119 byte-equivalence harness (`scripts/test-migrator-behavior-preservation.sh`) compares the current migrator's stdout against a frozen baseline captured before the BD-119 refactor (pinned at SHA `d7b3f07`). The new banner is legitimate post-refactor surface drift that the harness cannot accommodate without redaction — and the harness header explicitly forbids redaction-based fixes (PLAN §13.3). The harness was created as a one-shot proof for the BD-119 refactor (which shipped clean); its purpose is fulfilled. Retiring it is the correct fix. Alternative considered: re-pin the harness baseline to current `HEAD` — rejected because future legitimate stdout changes would face the same problem repeatedly, and the harness's anti-redaction policy makes it perpetually fragile to surface evolution. Retirement is one commit (delete the script + remove its workflow invocation + paper-trail addenda).
Resolved: 2026-05-10 — direct execution by Pack Chat (no pack-coder agent needed; mechanical change). Deleted `scripts/test-migrator-behavior-preservation.sh` (entire file). Removed harness invocation from `.github/workflows/validate-pack.yml` (the 3-line step under `migrator behavior-preservation tests (BD-119)`). Removed harness row from `README.md` script-table. Updated `scripts/validate-pack.py` line 789 comment list (removed harness mention; added a one-liner noting BD-137 retirement). Trinity update across `.claude/skills/verification-harness/SKILL.md`, `.codex/skills/verification-harness/SKILL.md`, `.gemini/skills/verification-harness/SKILL.md`: removed harness from the example test list (line 14) and re-pointed the "behavior-preservation harness pattern" example reference (line 213-214) to `test-migrator-core.sh`. Appended addendum to BD-119 Resolved: line documenting the harness retirement and the surviving BD-119 test surface (`test-migrator-core.sh` 19/19 + `test-migrator-manifest.sh` 12/12 + validate-pack Check 26). Validator: 30 checks PASS. Tests: surviving BD-119 test runners green. CI tests job is now expected to be green on next push (the BD-104 known-temporary failure goes away with this commit).

---

**BD-136 — Trinity marker-section preservation pattern (Shape A + Shape B) + PM-chat authoring procedure**
Type: TODO(version) — surfaced 2026-05-10 during OT v10→v11 trinity prep; verified scope against `scripts/lib/customization-preserve.sh:145-179` (12-class file inventory), `supporting-docs/MERGE-STRATEGY.md`, and `supporting-docs/INSTALL-PROCEDURES.md` lines 472-479 (`[CONDITIONAL]` H2 convention)
Status: Open
Blockers: none (independent of remaining v11.0 batches; can land any time before Batch 22 BD-102 dog-food migration)
Unblocks: byte-identical preservation of project-customized prose inside trinity files across pack updates; eliminates the OT-style "one-shot manual re-merge after every pack refresh" burden; closes the explicit BD-088/MERGE-STRATEGY.md §1 placeholder ("Future BDs may add explicit marker-section + diff-recognition fallback"); resolves the empty-pack-H2 problem and provides a clean override mechanism for project-overrides-pack-section cases
**Spec — Two H2 ownership shapes:**
  - **Shape A — Pack-owned H2 with project body extensions.** H2/H3 line OUTSIDE markers; pack-owned body content OUTSIDE markers; project additions wrapped in marker pairs WITHIN the section body. Pack owns the H2 name and the canonical body. Project may ADD content (fill-in placeholders, additional bullets, sub-paragraphs) inside markers but cannot delete pack body or rename the H2. On pack update: pack body refreshes via 3-way merge; project marker contents preserved byte-identical.
      ```
      ## Pack-shipped section name
      pack-owned body content
      <!-- BEGIN project-owned -->
      project additions
      <!-- END project-owned -->
      more pack-owned body content
      ```
  - **Shape B — Project-owned section (whole H2 or H3).** Marker pair encloses both the heading line (H2 or H3) AND its entire body, ending at the natural section boundary (the next same-or-lower-depth heading). Project owns everything: heading name, body content, structure. Used for THREE cases: (1) brand-new project sections the pack has no analog for; (2) project-renamed `[CONDITIONAL]` sections; (3) project-overrides-pack sections (the override mechanism — same H2 name as a pack section signals "suppress the pack version"). On pack update: byte-identical preservation; if the pack canonical also ships an H2 with the same name, the merger SUPPRESSES the pack version and the project's wrapped section wins.
      ```
      <!-- BEGIN project-owned -->
      ## Project-defined or project-renamed section name
      entire body content
      <!-- END project-owned -->
      ```
  - **`[CONDITIONAL]` H2s** are RETIRED in v11 canonical (per FP2 verification spec gap S-G-1). v9.3-era pack templates used `## [CONDITIONAL] X` as init-time scaffolding for "decide whether to keep this section." v11 canonical drops the literal prefix entirely and uses HTML-comment hints above each optional section instead: `<!-- OPTIONAL: keep this section if your project targets <X> -->`. This makes Shape B override-by-name (L-4) cleanly applicable to project-renamed sections. After init, no `[CONDITIONAL]` prefix may exist in any committed file (pack canonical OR project copy).
  - **`renamed-from` override annotation.** A Shape B section that overrides a canonical pack section UNDER A DIFFERENT NAME (e.g., project rename + body override) MUST carry an annotation in the BEGIN marker: `<!-- BEGIN project-owned: renamed-from "## <exact canonical H2 name>" -->`. The merger uses this annotation (when present) as the override match key in addition to strict name equality (L-4). Without `renamed-from`, only strict H2 name equality applies — which means a rename without annotation creates a duplicate (pack canonical H2 + project Shape B H2) on update. The annotation is the explicit pact: project says "this Shape B section IS the override of pack's `## <X>`."
File/Symbol:
  - `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` — two coordinated edits per file: (1) seed `<!-- BEGIN project-owned --> ... <!-- END project-owned -->` marker pair around the `## Project addenda` body content (Shape A — pack owns the `## Project addenda` H2; body is intentionally empty-with-marker-pair as the seed slot for project additions per the L-1 seed-slot exception). (2) RETIRE the literal `[CONDITIONAL]` prefix from every H2 in the canonical templates (per L-9). For each retired `[CONDITIONAL]` H2, replace with the bare H2 (drop the prefix) AND add an HTML-comment hint on the line above: `<!-- OPTIONAL: keep this section if your project targets <X>; delete the entire section if not applicable -->`. Affected canonical H2s in v10.1 (subject to v11 scope confirmation): `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features`, `## [CONDITIONAL] Architecture rules — platform-specific`, `## [CONDITIONAL] Language-specific coding rules`, `## [CONDITIONAL] gRPC and Proto3 rules`, `## [CONDITIONAL] Anti-patterns — never introduce these`. Trinity-symmetric across CLAUDE/AGENTS/GEMINI.
  - `scripts/lib/customization-preserve.sh` — extend (or add sibling `scripts/lib/marker-preserve.sh`) implementing Shape A + Shape B detection and preservation. Multiple marker pairs per file MUST be supported. Unclosed/orphaned markers MUST fail loud (not silent). Concrete merger requirements:
      - **L-1.** Each marker pair MUST be either Shape A (entirely between two same-depth headings, no heading inside) or Shape B (BEGIN immediately precedes a heading; END at the natural section boundary — next same-or-lower-depth heading or EOF). Any other shape (e.g., partial wrap that includes a heading but not its full body, or a pair spanning two H2s) is a defect — validator catches. **Seed-slot exception (per FP2 verification spec gap S-G-2):** the seed Shape A body wrap directly under `## Project addenda` is permitted to contain project-added H3/H4 headings — that section's body is by-design entirely project-owned, so the no-heading-inside-Shape-A rule does not apply. The exception is scoped narrowly: ONLY the single seed Shape A pair under `## Project addenda`. Any other Shape A pair containing a heading is still a defect.
      - **L-2.** Shape A body extensions: when canonical adds new pack content above the project's marker pair within the same H2 section, merger MUST emit a sidecar warning ("canonical added new pack content above your marker pair under `## <heading>` — review and either accept the new pack content or fold into your wrap").
      - **L-3.** Fill-in placeholders are a sub-class WITHIN Shape A bodies (Class B at the line level): `**Active skills:**`, `[PROJECT_NAME]`, `[PLATFORM_DEFAULTS]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, `[PLATFORM_TESTING]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_ANTIPATTERNS]`. Resolved procedurally: PM-CHAT.md procedure requires every fill-in value be wrapped inline in single-line Shape-A-body markers. Without this, fill-ins silently revert to placeholders on every pack update (real OT defect: `**Active skills:** apple-architecture-core, …` would have been lost).
      - **L-4 (override mechanism).** No H2/H3 name may appear more than once per file across both Shape A and Shape B in the same file (no duplicates). When the project has a Shape B section with the same H2 name as a pack canonical H2, the merger SUPPRESSES the pack version and the project's wrapped section wins — this is the documented override mechanism. When a Shape B H2 name does NOT match any pack canonical, the merger checks for a `renamed-from` annotation on the BEGIN marker (per spec section above): if present, treats the annotation's quoted name as the override match key; if absent, treats the section as project-original. Validator surfaces a Shape B section with no name match AND no `renamed-from` annotation as a soft warn ("project-original section" — confirm it is intentional).
      - **L-5.** New pack H2 inserted between existing project Shape B sections MUST be additive — insert in correct lexical position, leave both surrounding Shape B sections byte-identical.
      - **L-6.** Orphan/unbalanced markers fail loud. Validator checks: BEGIN count == END count; strict alternation; no nesting; markers never inside fenced code blocks.
      - **L-7.** Trinity-symmetry on marker placement is a soft-warn (not hard-fail) — legitimate tool-specific exceptions exist (e.g., GEMINI.md's `## Agent roster` has no CLAUDE/AGENTS analog).
      - **L-8.** Per-file H2 spelling diff against canonical MUST run as part of marker-aware merge — for Shape A H2s only (Shape B H2s are project-owned and exempt). Drift in a Shape A H2 line itself is a defect that the merger MUST surface as a sidecar conflict, never silently overwrite or silently keep.
      - **L-9.** `[CONDITIONAL]` retirement (per FP2 verification spec gap S-G-1): v11 canonical drops the literal `[CONDITIONAL]` prefix from all H2s. Optional sections are signaled by HTML-comment hints above each: `<!-- OPTIONAL: keep this section if your project targets <X> -->`. Migrator behavior at migration time: if a project trinity file still carries a `[CONDITIONAL]` prefix on any H2 (carryover from a v10 / v9.3 init), the migrator MUST treat it as either kept-and-transitioned-to-Shape-B (rename + wrap entire H2+body, optionally with `renamed-from` annotation pointing to the canonical pre-retirement name) or deleted. The literal `[CONDITIONAL]` prefix MUST NOT appear in ANY committed file (pack canonical OR project copy). Validator catches both sides.
      - **L-10 (`renamed-from` annotation).** When a Shape B BEGIN marker carries `renamed-from "## <name>"`, the merger treats the annotation's quoted name as an override match key in addition to strict H2 name equality (see L-4). Annotation grammar: `<!-- BEGIN project-owned: renamed-from "<exact heading line>"[, "<exact heading line>"]* -->` where each `<exact heading line>` includes the heading prefix (`## ` or `### `) and matches the canonical heading byte-for-byte. Multiple comma-separated names ARE supported in v11.0 — the override-by-merge case where one project Shape B section is the successor of two-or-more canonical sections (real OT case: `## Swift coding rules` collapses canonical `## Architecture rules — platform-specific` + `## Language-specific coding rules`). When multiple names are listed, ALL named canonical sections are suppressed in merge output. Annotations are validator-checked for syntactic correctness; semantic match (does each quoted name exist in canonical?) is checked by the merger at migration time and surfaces as a sidecar conflict if any quoted name has no match.
  - `project-template/docs/pack/PM-CHAT.md` — three coordinated edits: (1) NEW H2 section "How to add project-owned content to trinity files" with the full Shape A + Shape B authoring procedure: WHEN to use Shape A vs Shape B with concrete examples; markers around body only for Shape A (never around pack H2/H3 headers); markers around H2/H3 + entire body for Shape B; multiple marker pairs per file allowed and encouraged; never edit pack-owned text outside markers in Shape A sections — if pack text needs changing that is a BD against the pack; the override mechanism (Shape B with same H2 name as pack section); how to handle nested customization; what to do if the pack ships a new H2 that overlaps an existing project Shape B section. (2) UPDATE the file-ownership / edit-permissions table so trinity files are listed as "pack-owned with Shape A and Shape B project sections — see §How to add project-owned content to trinity files" rather than the current generic "PM chat may edit" entry. (3) UPDATE the PM-chat startup checklist to include a one-liner reminder pointing at the new H2. Concrete procedure requirements:
      - **P-1.** Shape A vs Shape B decision rule with concrete WRONG/RIGHT examples for both shapes. The OT prep author read the body-only rule and then violated it 4 times per file by partially wrapping H2s — Shape A and Shape B must be visually unambiguous in the procedure doc.
      - **P-2.** "Do not edit pack-owned text outside markers in Shape A sections" enforced procedurally: PM chat (a) re-reads the canonical version of any trinity file before editing, (b) diffs working copy against canonical before any edit, (c) refuses to write Shape A edits that fall outside marker pairs unless user explicitly approves "edit pack-owned text" — which the procedure re-routes as "open a BD against the pack" or "convert the section to Shape B (override)."
      - **P-3.** Fill-in placeholders enumerated explicitly (all the patterns listed under L-3) with the wrap-inline-in-single-line-Shape-A-markers requirement.
      - **P-4.** Shape A surgical-wrap vs Shape B whole-section-wrap decision rule. "If you need to add a few bullets or fill in placeholders within an existing pack section: Shape A. If you need to override the entire body of a pack section, OR you are renaming a `[CONDITIONAL]` section, OR you are adding a wholly new project section: Shape B."
      - **P-5.** Diff against the file's OWN canonical, not against a sibling trinity file. Cross-trinity convergence (e.g., making AGENTS.md look like CLAUDE.md) is a pack-level decision that requires a BD against the pack, NOT a project-side edit. (Real OT defect: the AGENTS.md `## Agent behavior` body was restructured to mirror CLAUDE/GEMINI shape, in pack territory.)
      - **P-6.** `[CONDITIONAL]` H2 handling: when the PM chat encounters a `[CONDITIONAL]` H2 during init or migration, the procedure is: "decide whether the project needs this section. If YES: rename per project specifics AND wrap the entire renamed H2 + body in Shape B markers. If NO: delete the section entirely from all three trinity files. The literal `[CONDITIONAL]` prefix must never remain in committed project files."
      - **P-7.** New project-original H2 sections: always Shape B. Do NOT introduce new H2s outside markers. Do NOT relocate semantically-anchored project content into a single `## Project addenda` dump — Shape B preserves semantic anchoring at top-level H2.
      - **P-8 (`renamed-from` annotation).** When converting a pack-shipped section to a Shape B override under a project-chosen name, the PM chat MUST add the `renamed-from "<exact canonical heading line>"` annotation to the BEGIN marker. The procedure section MUST show the annotation syntax with a worked example (e.g., `<!-- BEGIN project-owned: renamed-from "## iOS / Xcode platform features" -->` for an OT-style rename to `## Xcode 26.4 platform features`). Without the annotation, the override fails on update and the project ends up with both the canonical H2 and the project Shape B H2 in its file.
  - Comment block inside each trinity file's seed `## Project addenda` section pointing to PM-CHAT.md §How to add project-owned content — discoverable from the file being edited.
  - `supporting-docs/INSTALL-PROCEDURES.md` — (a) cross-reference to the PM-CHAT.md procedure section MUST cover all THREE trinity entry-point flows (fresh init via `SETUP-NEW.md`; existing-project adoption via `SETUP-EXISTING.md`; v10→v11 migration via `MIGRATION-v10-to-v11.md`) — not just migration; (b) update lines 472-479 (the `[CONDITIONAL]` H2 convention) to reference Shape B as the canonical post-init state for kept `[CONDITIONAL]` sections (per L-9 retirement, the literal `[CONDITIONAL]` prefix is dropped from canonical; the Shape B transition still applies for kept optional sections).
  - `supporting-docs/SETUP-NEW.md` — NEW section "Customizing the trinity files" with a one-paragraph summary of the Shape A + Shape B model + a pointer to `docs/pack/PM-CHAT.md` §How to add project-owned content (which carries the full P-1..P-8 procedure). PM chats running fresh-init must encounter this rule BEFORE making their first trinity edit; without the SETUP-NEW pointer they will edit pack-owned text and lose customizations on every pack update.
  - `supporting-docs/SETUP-EXISTING.md` — same NEW section as SETUP-NEW.md (identical wording where possible). Existing-project PM chats face the additional risk of pre-existing project documentation overlapping with pack-shipped trinity sections; the procedure pointer must call out the override mechanism (Shape B with same H2 name as canonical, plus `renamed-from` annotation when the project's section name differs) as the resolution path.
  - `scripts/init-project.sh` — at the end of the install (after copying `project-template/{CLAUDE,AGENTS,GEMINI}.md` to the target), log a discoverable hint: `Trinity files include marker-pair seed slots for project customizations — see docs/pack/PM-CHAT.md §How to add project-owned content before editing`. Same hint for both fresh-init and `--update` paths. The hint surfaces the BD-136 procedure at the moment a PM chat is most likely to start editing the trinity.
  - `supporting-docs/MERGE-STRATEGY.md` §1 — replace the "Future BDs may add explicit marker-section…" placeholder with the actual Shape A + Shape B specification (definitions, override mechanism, validator surface, sidecar behavior).
  - `scripts/validate-pack.py` — new Check (next available number; current count is 30 per Batch 8/9 work) enforcing the full validator surface:
      - **V-1.** Every trinity file in `project-template/` (and any seed marker file under `project-template/docs/pack/`) MUST have well-formed marker pairs: matched count, no nesting, no orphans, BEGIN precedes its END.
      - **V-2.** Each marker pair MUST conform to either Shape A (no heading line inside) or Shape B (BEGIN immediately precedes a heading; END at the natural section boundary). Partial wraps (heading inside but section body extends past END) are defects.
      - **V-3.** No marker may sit inside a fenced code block (track triple-backtick state line-by-line).
      - **V-4.** The `## Project addenda` H2 MUST exist in each trinity file (Shape A) and MUST contain at least one marker pair (the seed Shape A body wrap from File/Symbol bullet 1).
      - **V-5.** Trinity-symmetry warn (per L-7): emit a warning, not error, if a marker pair count differs across CLAUDE / AGENTS / GEMINI.
      - **V-6.** No H2 name may appear in BOTH Shape A and Shape B in the same file (per L-4 — duplicate H2 detection enforces the override mechanism's contract).
      - **V-7.** No `[CONDITIONAL]` prefix may appear on any H2 in any committed file — pack canonical OR project copy (per L-9 retirement). Validator enforces both surfaces: the pack repo's own `project-template/` trinity templates AND any project trinity under test. Replacement signal in canonical is the HTML-comment `<!-- OPTIONAL: ... -->` hint above each optional H2.
      - **V-8 (`renamed-from` annotation).** Each Shape B BEGIN marker carrying `renamed-from "..."` MUST conform to the grammar in L-10 (exact `## ` or `### ` heading prefix; double-quoted; one annotation per BEGIN). Validator checks syntactic conformance only; semantic-match validation (does the quoted heading exist in canonical?) is the merger's responsibility at migration time.
  - `scripts/tests/test-customization-preserve-bd136.sh` (NEW) — round-trip tests covering the full BD-136 surface:
      - **M-1.** Shape A round-trip: project file with N=3 Shape A body-extension marker pairs across distinct H2 anchors; verify in-marker content byte-identical AND outside-marker pack content adopted via 3-way merge.
      - **M-2.** Shape B round-trip: project file with N=3 Shape B sections (one project-original, one project-renamed-from-`[CONDITIONAL]`, one project-overrides-pack); verify all three byte-identical post-migration AND the overridden pack section is suppressed in output.
      - **M-3.** Pack update inserts new canonical H2 between two existing project Shape B sections; verify new H2 lands in correct lexical position and both Shape B sections byte-identical.
      - **M-4.** Pack update adds new canonical bullet at the top of a Shape A section the project has wrapped; verify merger emits sidecar warning and project Shape A content byte-identical.
      - **M-5.** Negative test: file with the same H2 name in both Shape A and Shape B MUST cause migration to fail loud (per L-4 / V-6).
      - **M-6.** Negative test: file with one orphan BEGIN MUST cause migration to fail loud (per L-6).
      - **M-7.** Negative test: file with `[CONDITIONAL]` prefix on a project H2 MUST cause migration to fail loud (per L-9 / V-7) — surface as "decide whether to keep this section."
      - **M-8.** OT-derived golden fixture: once OT's re-prepped trinity files exist (clean per `PACK-REVIEW-OT-TRINITY-PREP.md`), copy them into `test-fixtures/v11-trinity-marker-prepped/` as a real-world golden example — round-trip migration produces byte-identical OT customizations with zero manual reconciliation.
      - **M-9 (`renamed-from` override).** Project file with a Shape B section carrying `renamed-from "## <canonical name>"`; verify merger SUPPRESSES the canonical version in output (no duplicate H2 in result) and project Shape B section byte-identical. Negative variant: `renamed-from "## <name that does not exist in canonical>"` MUST surface as a sidecar conflict, not silently suppress nothing or silently keep both.
      - **M-10 (Project addenda seed-slot exception).** Project file with the `## Project addenda` Shape A body wrap containing N=5 project-added H3 subsections; verify validator passes (per L-1 / V-2 seed-slot exception) and merger preserves the entire body byte-identical including the H3 headings. Negative variant: a non-Project-addenda Shape A pair containing an H3 MUST cause migration to fail loud (the seed-slot exception is narrowly scoped).
      - **M-11 (fresh-init + customized fixture).** Sibling to M-8: a `v11-flat-file`-derived fixture that simulates a PM chat running fresh `init-project.sh` and then customizing the trinity per the BD-136 procedure (P-1..P-8). At least one Shape A body extension (e.g., `**Active skills:**` fill-in), at least one project-original Shape B section, at least one `## Project addenda` H3 subsection. Verify a subsequent `init --update` against the fixture preserves all project content byte-identical with zero manual reconciliation. Captures the fresh-init flow (SETUP-NEW.md path).
      - **M-12 (existing-adoption + customized fixture).** Sibling to M-11: an `existing-project-mid-dev`-derived fixture where `init-project.sh` was run against an existing project, the PM chat then applied the BD-136 procedure to wrap pre-existing project documentation (overlapping with pack-shipped trinity sections) using Shape B with the override mechanism (same-H2-name + optional `renamed-from`). Verify a subsequent `init --update` preserves all project content and respects every Shape B override. Captures the existing-project-adoption flow (SETUP-EXISTING.md path).
Description: The trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) mix pack-managed prose (capability policy, operating rules, agent inventory) with project-side customizations of three kinds: extensions to pack-shipped sections (Shape A — fill-ins, additional bullets), wholly project-owned sections (Shape B — brand-new sections, project-renamed `[CONDITIONAL]` sections), and overrides of pack-shipped sections (Shape B — same H2 name as a pack section). Today the migrator routes the trinity through the generic 3-way text dispatcher, which on `real-merge-required` writes the new pack template at the destination and saves the project copy as a `.pre-update` / `.v10-customized` sidecar — preserving content but forcing manual re-merge on every pack refresh. The OT v10→v11 trinity-prep exercise (2026-05-10) surfaced the full design space: OT has 12+ project-owned sections per file with all three customization kinds (Shape A body extensions for fill-ins; Shape B project-renamed `[CONDITIONAL]` sections like `## Xcode 26.4 platform features` and `## Swift coding rules`; Shape B project-overrides-pack like the AGENTS.md `## Agent behavior` body restructure). The marker-section pattern is already proven at minimum in `project-template/docs/pack/PM-CHAT.md` (single Shape A pair around the "Additional project documents" section). BD-136 generalizes that proven pattern to trinity with the full Shape A + Shape B model. **Three problems the Shape A + Shape B model solves that earlier marker-only specs did not:** (1) the empty-pack-H2 problem — a non-Apple project should not carry an empty `## Xcode platform features` H2 in its committed trinity; under Shape B, project-renamed sections carry their own H2s and non-applicable sections are simply absent; (2) the project-overrides-pack problem — a project that wants to replace a pack section's body wholesale needs an override mechanism, which Shape B provides via the duplicate-H2 suppression rule (L-4); (3) the project-original-H2 problem — project-original top-level sections should retain their semantic anchoring at H2 level rather than being relocated into a `## Project addenda` H3 dump. Scope is INTENTIONALLY trinity-only: every other project-modifiable file in `project-template/` is correctly handled by its existing class — structured configs (JSON/TOML/env) by key-merge; reserved-prefix `x-*` files by project-only-by-prefix; `pack-agent` / `pack-script` files by 3-way merge with sidecar fallback; `PACK-FEEDBACK.md` and `README.md` (project-owns-the-body shape) by generic 3-way (acceptable; sidecar preserves project content; manual re-merge burden is rare). The PM-chat authoring procedure deliverable is non-negotiable per user requirement (2026-05-10): without it the PM chat will drift the moment it adds a new project-owned section. Procedure must be explicit on the Shape A vs Shape B decision rule (P-1 / P-4), the `[CONDITIONAL]` H2 handling (P-6), the override mechanism (P-4 / L-4), the do-not-edit-pack-text-outside-markers rule for Shape A (P-2), and the diff-against-own-canonical-not-sibling rule (P-5). The full lessons-learned matrix (L-1..L-9 merger, P-1..P-7 procedure, V-1..V-7 validator, M-1..M-8 tests) is documented in this entry and in `maintenance-docs/v11-implementation/PACK-REVIEW-OT-TRINITY-PREP.md`. Partial-pack-content-delete (e.g., "keep canonical Build and repo hygiene mostly, but delete bullet 3") is NOT supported by the Shape A + Shape B model — a project that needs partial deletion must convert the section to Shape B (whole-section override) and accept the maintenance burden of tracking pack updates manually. A future `<!-- DELETE pack-line: "exact text" -->` syntax could address this; deferred to a separate post-v11.0 BD if the need arises.
Resolved:

---

**BD-135 — Disambiguate `tracker.toml.example` filename pair (rename pack-side and client-side)**
Type: TODO(version) — surfaced during BD-123 disposition discussion (2026-05-09); new BD per `feedback_filename_uniqueness.md` heuristic memory
Status: Resolved
Blockers: BD-123 (must be Cancelled first; its premise was incompatible with this approach — BD-123 assumed one file misplaced, BD-135 keeps both files where they are with distinct names)
Unblocks: unambiguous prose references to either tracker-example file without a path qualifier; reduces future-author confusion (the BD-123 author was tripped by the matching filenames)
File/Symbol:
  - RENAME `tracker.toml.example` → `tracker.toml.pack-example` (pack root) — proposed name; final name at implementor's discretion provided it is distinct from the project-template peer AND remains self-evidently a tracker-config template
  - RENAME `project-template/tracker.toml.example` → `project-template/tracker.toml.project-example` — same naming flexibility
  - Update `init-project.sh` lines 14 (comment), 722–725 (the copy block), and 878 (manifest entry) to read the new pack-side source path AND write to the new client-side basename at install destination
  - Update `migrate-v10-to-v11.sh` lines 25 (comment), 181–185 (copy block) — same shape
  - Update `README.md` line 128 (project-template/ layout block) and line 226 (pack-repo root layout block) to reflect new filenames
  - Update `OPTIONAL-FEATURES.md` lines 156–158 (the install-narrative paragraph)
  - Update `HELP-FRAGMENT-TRACKER.md` line 29 AND `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` line 29 — trinity-mirrored byte-identical per DELTA L1; edit both lockstep; CI Check 24 enforces byte-identity
  - Update `supporting-docs/MERGE-STRATEGY.md` line 243 (the catch-all classifier paragraph)
  - Update `supporting-docs/MIGRATION-v10-to-v11.md` lines 8, 48, 118, 226, 252 — five references describing where the file lands during v10→v11 migration; line 252 is the forward-setup read step
  - Update `scripts/tests/test-init-project.sh` and `scripts/tests/test-migrate-v10-to-v11.sh` if they assert the basename (verify and update if so)
Description: Two `tracker.toml.example` files exist for legitimate, distinct reasons — pack-side template (BD-prefix, Optiquity URL, "pack repo tracker configuration" header) for opting the pack repo itself into tracker mode, and client-side template (TD-prefix, your-org placeholder, "client project tracker configuration" header) that ships into client projects via `init-project.sh`. The matching filenames led the BD-123 author to mis-frame the work as "one file in the wrong directory." Investigation revealed the asymmetry is intentional and documented in `README.md` at lines 128 and 226. Renaming both to filename-distinct forms eliminates the recurring confusion vector and aligns with the codified `feedback_filename_uniqueness.md` heuristic. Mechanical rename + reference sweep across ~9 files. Verification: validator PASS (no Check regression); HELP-FRAGMENT-TRACKER mirror byte-identity preserved (Check 24); a fresh `init-project.sh` run installs the renamed file at the new client-side basename; v10→v11 migration test still copies the renamed source.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-135.md`. Final names: `tracker.toml.pack-example` (pack root) and `project-template/tracker.toml.project-example` (client-side template source). Install destination at client deliberately stays as `tracker.toml.example` (unique-filename heuristic only applies inside the pack repo where both files coexist; client projects only ever have one tracker example file). Validator PASS (28 checks); HELP-FRAGMENT-TRACKER trinity byte-identity preserved.

---

**BD-134 — Tracker forward close retry-with-backoff (eliminate ~5% partial-write rate)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-7)
Status: Resolved
Blockers: none
Unblocks: cleaner BD-102 dog-food re-run; reduced post-init `gh issue` state drift
File/Symbol: `scripts/lib/tracker-provider-gh.sh` (close call); `scripts/lib/tracker-migrate-forward.sh` (end-of-init re-run-failed-closes step)
Description: Forward step-8 close has ~5% partial-write rate (3 of 56 named close failures observed: BD-021/022/023). Likely transient gh API rate-limiting. Add retry-with-backoff on individual close, OR end-of-init pass that re-runs failed closes once before reporting partial-write. Severity NIT — issues end up OPEN with `status:resolved` label instead of CLOSED.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-134.md`. Approach (b): end-of-init re-run-failed-closes pass in `scripts/lib/tracker-migrate-forward.sh` (new step-8.4 helper) — composes cleanly with BD-132's `_tmf_wait_for_close_stabilization` (retry sweep runs first, then stabilization sees the post-retry close count). Retry bounds: `TMF_CLOSE_RETRY_MAX_ATTEMPTS=3` (1 original + 2 retries), `TMF_CLOSE_RETRY_BACKOFF_SECS="1 2 4"` exponential schedule; both env-overridable. Bounded by construction (helper iterates exactly `MAX_ATTEMPTS - 1` times — no recursion, no extension). New regression test `scripts/tests/tracker-bd134-close-retry-test.sh` 24/24 PASS across 3 groups (transient close recovers with 0 partial-writes; persistent close surfaces partial-write after exactly 3 attempts per id with proven bounded-loop assertions; helper-level isolation tests). All 7 pinned suites green: bd129 11/11, bd130 8/8, bd132 29/29, bd133 30/30, forward 126/126, reverse 93/93, roundtrip 39/39. Validator clean. **Closes BD-102 Phase A dog-food triage cluster: D-1..D-7 all addressed (D-3 was withdrawn at hand-off).**

---

**BD-133 — Reverse migration preserves BACKLOG.md header preamble**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-6)
Status: Resolved
Blockers: none
Unblocks: BD-102 dog-food (Phase A round-trip survives without content loss)
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh` BACKLOG emission; `scripts/lib/tracker-migrate-forward.sh` checkpoint snapshot OR `scripts/lib/tracker-sidecar.sh` header preservation
Description: Reverse migration strips ALL non-entry content from BACKLOG.md — the `# Backlog` title, "All planned improvements..." paragraph, `## How to use this file` section, type explanations, format references — replacing it with bare `# BACKLOG`. Per V1 §6.5 design intent project-specific content not representable in tracker should be sidecar-preserved; this header content qualifies. Reverse must preserve everything before the first `**BD-NNN — ...**` heading byte-identical, via checkpoint snapshot, sidecar, or refusal-to-overwrite policy after first round-trip. Test fixture required.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-133.md`. Approach (b): NEW `scripts/lib/tracker-header-snapshot.sh` module (sidecar storage at `<repo-root>/.pack-tracker/backlog-header.snapshot`); reverse calls `tracker_header_snapshot_capture` before `_tmr_emit_backlog` and `tracker_header_snapshot_apply` after, prepending the snapshot to the entries-only body. First-write-wins semantics (capture is no-op if snapshot already exists) guarantee N round-trips don't degrade the preamble. Trivial preambles (whitespace-only or bare `# BACKLOG` from a prior reverse) are skipped to prevent bootstrap from a never-had-preamble repo locking in a bad value. Approach (a) (forward-time checkpoint snapshot) was rejected because it would have required editing tracker-migrate-forward.sh which BD-131 owns in this same Batch 9 — the sidecar approach has zero file conflict with BD-131. New round-trip test `scripts/tests/tracker-bd133-header-preservation-test.sh` 30/30 PASS across 4 groups (module API isolation, reverse-only round-trip, full forward→reverse via stateful fake gh, multi-cycle stability N=5). All existing tracker test suites green: reverse 93/93, roundtrip 39/39, forward 126/126 (BD-131 intact), bd132-race 29/29. Validator clean.

---

**BD-132 — BLOCKER: tracker disable/init close-step race destroys ~33% of BACKLOG entries**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-5)
Status: Resolved
Blockers: none
Unblocks: BD-102 dog-food (Phase A); v11.0 ship gate (silent data loss is unacceptable)
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh` reconstruct loop; `scripts/pack-tracker.sh` init/disable race detection; `scripts/lib/tracker-migrate-forward.sh` close-stabilization wait
Description: First `disable` invocation immediately after `init` exit reconstructed only 60 of 93 BD entries — 33 entries silently dropped. Hypothesis: `gh issue close` is eventually consistent; `disable` running mid-close sees inconsistent issue state and silently skips entries whose body or labels appear malformed mid-update. Workaround was poll `gh issue list --state closed --limit 200 --json number --jq length` until stable, then disable. Three-part fix required: (a) `init` waits for all close ops to stabilize before exit, (b) `disable` detects "init still racing" via `forward.checkpoint.json` freshness OR issue-state stability poll, (c) reverse loop's silent-skip path must at minimum WARN ("skipping X issues whose body did not parse — re-run"). Severity effective CRITICAL: a user who runs `init` then immediately `disable` (smoke test, change of mind) loses 35% of BACKLOG content with no warning. **BLOCKER for v11.0.**
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-132.md` + `IMPLEMENTATION-REPORT-BD-132-FIX-FOLLOW.md` (PACK-REVIEW-BD-132 8-finding fix-follow absorbed into the same commit). All three parts of the fix landed: (1) `_tmf_wait_for_close_stabilization` in tracker-migrate-forward.sh polls provider for closed entry-issues (label-scoped to `bd-entry`/`td-entry`/`phase-epic` so production repos with >200 unrelated closed issues do not trivialize the count) until the count is stable across two consecutive reads AND >= the closes attempted (bounded 30×2s = 60s, env-overridable; consecutive provider failures bounded by `TMF_STABILIZE_FAIL_LIMIT`); on stabilization timeout the forward checkpoint is preserved as a downstream race-detection signal; (2) `tracker_migrate_reverse_run` in disable mode refuses (without `--force`) when `forward.checkpoint.json` is present OR the mapping file's mtime is younger than `TMR_RACE_FRESHNESS_SECS` (default 60s, matching the stabilization ceiling so the windows do not gap). The mtime read uses Python3 `os.path.getmtime()` for unambiguous portability across macOS BSD and Linux GNU stat (the prior BSD/GNU stat-flag fallback was broken on Linux); (3) reverse-loop silent-skip → loud-failure: per-issue WARN with gh id + reason, refuses to write half-data into BACKLOG.md (returns 1 with `partial-write` typed error) unless `--force`. `cmd_disable` accepts new `--force` flag. New race-test fixture `scripts/tests/tracker-bd132-race-test.sh` 29/29 PASS (now exercises both the `provider_get fails` and `body missing pack-id marker` skip paths — the actual BD-102 Phase A failure mode). All 17 existing test suites green. Validator PASS. Honest risk assessment: silent loss is converted-to-loud-failure in every covered path on both macOS and Linux/CI; full prevention depends on Part 1's heuristic holding in production — Parts 2 and 3 are explicit safety nets that catch any race the wait misses.

---

**BD-131 — Set `forward_complete = true` at end of clean forward migration**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-4)
Status: Resolved
Blockers: none
Unblocks: correct `tracker_mode()` resolution (V1 §3.2); downstream tooling routes to tracker behavior reliably
File/Symbol: `scripts/lib/tracker-migrate-forward.sh` (or wherever final tracker.toml `[migration]` write happens); `scripts/lib/tracker-init.sh` if init owns the post-forward write
Description: After `pack tracker init --backend github --repo ... --no-interactive` succeeded (created tracker.toml, wrote 93 issues, wrote id-map.json + forward.checkpoint.json, closed 53 of 56 attempted closes), the `tracker.toml [migration]` section reads `forward_complete = false`. Per V1 §3.2 `tracker_mode()` resolves to "tracker" only when `mode.state = "tracker"` AND `migration.forward_complete = true`. Downstream tooling depending on `tracker_mode()` may incorrectly route to flat-file behavior. Fix: set `forward_complete = true` at end of clean forward. For partial-write cases (BD-134's 3-of-56 failure pattern), document semantics — does `forward_complete` mean "all closes succeeded" or "all issues created"? Recommend the latter since BD-134's fix will eliminate the close-failure case anyway.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-131.md`. Fix landed in `tracker_migrate_forward_run` step 11 + `_tmf_update_tracker_toml` (writer takes `"true"|"false"` positional arg with defensive value-validation) + NEW helper `_tmf_verify_forward_complete` (defense-in-depth read-back; emits stderr WARN if on-disk value disagrees with what was written). Semantics: `forward_complete = true` iff all create operations succeeded (the strong signal for `tracker_mode()`); partial-close is BD-134's concern, not BD-131's. Any create failure (entry or phase epic) early-returns at the create site so step 11 never runs and `forward_complete` stays at the init-time `false`. tracker-migrate-forward-test 126/126 PASS (was 111; +15 new asserts in Group 5 and added to 4.3). All other tracker suites green; validator clean.

---

**BD-130 — Wire `tracker_doctor_run` so `pack tracker doctor` works (BD-067 fix incomplete)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-2; live regression confirmed at HEAD `240867d`)
Status: Resolved
Blockers: none
Unblocks: BD-102 dog-food (operator can actually run `pack tracker doctor`); BD-097 audit accuracy (NOTE N-5 said all four verbs implemented — was wrong for `doctor`)
File/Symbol: `scripts/pack-tracker.sh` (sources scripts/lib/* but never `scripts/tracker-migrate.sh` where `tracker_doctor_run` is defined at line 167); options to fix: (a) move `tracker_doctor_run` from `scripts/tracker-migrate.sh` into `scripts/lib/tracker-*.sh` and source it; (b) have `pack-tracker.sh` source `scripts/tracker-migrate.sh`; (c) duplicate the function (rejected — DRY)
Description: BD-067 Resolved-line claims `pack tracker doctor` was wired. Live test on HEAD `240867d`: `bash scripts/pack-tracker.sh doctor` returns `scripts/pack-tracker.sh: line 165: tracker_doctor_run: command not found`. Function is defined in `scripts/tracker-migrate.sh:167` but `scripts/pack-tracker.sh` only sources `scripts/lib/*.sh` files (verified — see lines 29-53 of pack-tracker.sh). Recommended fix (a): relocate to `scripts/lib/tracker-doctor.sh` (or fold into existing `scripts/lib/tracker-init.sh` since init/doctor are sibling concerns) and add a source line in pack-tracker.sh.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-130.md`. Approach (a): extracted `tracker_doctor_run` into NEW `scripts/lib/tracker-doctor.sh` (203 lines, function body verbatim), sourced from both `scripts/pack-tracker.sh` and `scripts/tracker-migrate.sh`; inline definition in tracker-migrate.sh removed and replaced with pointer comment. Smoke-tested: `bash scripts/pack-tracker.sh doctor` from scratch dir now emits doctor-formatted output (`doctor: <target>` banner + WARN/INFO lines + completion summary), no shell error. New regression test `scripts/tests/tracker-bd130-doctor-wired-test.sh` 8/8 PASS. tracker-migrate-reverse-test groups 6.2 + 6.3 confirm legacy entry path still resolves the function. v11.0 BLOCKER count 1 → 0 after this commit.

---

**BD-129 — Tracker libs pass `--repo` to all gh invocations (don't depend on git remote)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-1)
Status: Resolved
Blockers: none
Unblocks: tracker init works for repos with non-GitHub remotes, internal mirrors, GHE-on-different-host, freshly-cloned repos before remote setup, monorepo subtree imports
File/Symbol: `scripts/lib/tracker-labels.sh:172` (`_tracker_labels_existing`), `scripts/lib/tracker-labels.sh:183` (`_tracker_labels_create`), every `_gh_run gh ...` call in `scripts/lib/tracker-provider-gh.sh` that doesn't pass `--repo`. Slug source: `scripts/lib/tracker-config.sh::tracker_repo_slug`.
Description: All gh invocations in tracker libs run without `--repo`. gh resolves slug from working repo's git remote — fails with "none of the git remotes configured for this repository point to a known GitHub host" for clones from local-path sources, non-GitHub remotes, or freshly-cloned repos. `pack tracker init` then aborts at `labels_ensure: cannot read existing labels (gh auth or network failure)` — misleading error. Fix: pass `--repo "$slug"` everywhere (slug already available via `tracker_repo_slug`); OR set `GH_REPO` env in dispatcher before any gh call (cleaner — single point of control). Recommend the env-var approach: set once in `scripts/pack-tracker.sh` cmd dispatcher, applies to every gh call below it.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-129.md`. Approach (b): `GH_REPO` env-var export via new helper `tracker_gh_repo_setup` in `scripts/lib/tracker-config.sh`; called from `_gh_run` (covers 24 sites in `tracker-provider-gh.sh`) and from `tracker_labels_ensure` (covers 2 raw `gh label list`/`create` sites in `tracker-labels.sh`). 26 gh-invocation sites total routed through `GH_REPO` from active `tracker.toml`'s `backend.repo`. Helper is no-op when caller pre-sets `GH_REPO` (preserves test seam) or when no tracker config in scope. New regression test `scripts/tests/tracker-bd129-gh-repo-test.sh` 11/11 PASS — Group 3 reproduces the exact failure scenario (`git init` directory with no remote, run `tracker_labels_ensure`, verify all 46 expected gh calls succeed and every one carried `GH_REPO=owner/repo`). 10 tracker test suites = 566/566 PASS. Validator clean.

---

**BD-128 — CI test-suite repair: BD-080 Group 3 + v10-realistic-ot fixture + migrator collateral**
Type: TODO(version) — surfaced by current CI baseline (red on every push since v10.1 backport landed)
Status: Resolved
Blockers: none — but should land BEFORE BD-102 dog-food
Unblocks: green CI on `validate-pack.yml`; BD-102 dog-food run can rely on test-suite signal
File/Symbol: `scripts/tests/test-init-project.sh` (Group 3: 13 FAILs hunting for `S11 — v11 client artifacts`, `tracker.toml.example`, `pack-help.sh`, `detect.sh` post-BD-088/BD-119/BD-121); `test-fixtures/build.sh` (exit 31 building `v10-realistic-ot` — likely v10 tag unreachable in CI checkout OR builder needs BD-120 parameterization first); `scripts/test-migrator-behavior-preservation.sh` (collateral failure on missing fixture); possibly `.github/workflows/validate-pack.yml` (verify checkout fetches tags)
Description: CI `tests` job has been red since `19755b5` (v10.1 backport optimization pass). Three failing suites: (1) BD-080 init-project Group 3 — assertions reference v11 client artifacts in paths that BD-088/BD-119/BD-121 reorganized; either update assertions OR fix install paths. (2) `test-fixtures/build.sh --all --clean` exit 31 building `v10-realistic-ot` from the v10 git tag — checkout depth or tag-fetching issue in CI, OR builder needs BD-120 parameterization. (3) BD-119 migrator behavior-preservation — depends on fixture from #2. Triage and repair each. May spawn fix-follow BDs if any failure surfaces a deeper issue. **NOTE on sequencing:** if BD-128 repair turns out to require BD-120 (fixture parameterization), batch ordering must move BD-120 ahead of BD-128. Pre-flight check is the first task.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-128.md`. Root cause: v10.1 added documentary PROMPT-TEMPLATES references in `project-template/docs/pack/PM-CHAT.md` orphan table, but `init-project.sh::blast_radius_sweep` exclude list was not updated to match (PM-CHAT.md sat alongside METHODOLOGY.md and INSTALL-PROCEDURES.md as legitimate documentation files referencing legacy names). Fix: added `PM-CHAT.md` AND `detect.sh` (uses PROMPT-TEMPLATES as a v10-shape negative marker) to the exclude list. v10-tag work-around: idempotent post-clone `sed` patch in `test-fixtures/build.sh::_setup_v10_pack_src` injecting the exclude into v10's frozen init-project.sh. Bonus: pack-coder also surfaced and fixed BD-135-induced baseline drift in `scripts/test-migrator-behavior-preservation.sh` (BASELINE migrator at SHA `d7b3f07` referenced the pre-rename tracker.toml.example path). All three failing suites now pass: test-init-project 34/34, build.sh --all --clean 5/5 fixtures with deterministic SHAs, test-migrator-behavior-preservation 15/15. BD-120 NOT a prerequisite — fixture build needed only the v10-tag sweep work-around, not parameterization.

---

**BD-127 — v10.1 backport doc-tidy: HISTORICAL prose qualifiers, METHODOLOGY CLI-PM-SETUP rephrase, agent-list pointer, PM-CHAT Edit-allowed alignment**
Type: TODO(version) — fix-follow on v10.1 backport (PACK-REVIEW F-4, F-5, F-7, F-16)
Status: Resolved
Blockers: none
Unblocks: closes the 4 SHOULD-FIX + actionable NIT cluster from `maintenance-docs/v11-implementation/PACK-REVIEW-V10.1-BACKPORT.md`
File/Symbol:
  - `supporting-docs/INSTALL-PROCEDURES.md` lines 220, 246, 802, 881 — bare `migrate-v9-to-v10.sh` / `MIGRATION-v9-to-v10.md` prose references outside the HISTORICAL block scope
  - `supporting-docs/METHODOLOGY.md` § RAG index hygiene — parenthetical that wrongly classifies `CLI-PM-SETUP.md` as a pack-only doc
  - `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` — Project memory section agent-list parenthetical (trinity edit, lockstep)
  - `project-template/docs/pack/PM-CHAT.md` lines 313–317 — agent-run.sh read-only flag profile lists `Edit` on the denied-tools list, contradicting chunked-Edit-on-report pattern in agent files
Description: Small targeted doc edits surfaced by the v10.1 backport reviewer pass.

  1. **F-4 — Add `(historical)` qualifier inline** at each of the four bare references (lines 220, 246, 802, 881). Do not expand the HISTORICAL block-quote scope; inline qualifiers preserve the procedure structure.
  2. **F-5 — Rephrase the parenthetical** to: "the `CLI-PM-SETUP.md` companion doc covers MCP / RAG setup; copy it alongside `METHODOLOGY.md` during install." Drop the false "pack-only" claim while preserving the navigation aid.
  3. **F-7 — Append "(`auditor` covers the 7 variant agents — see PACK-AGENTS.md for the full roster)"** to the 9-agent enumeration in the Project memory bullet "PM chat does not architect." Trinity edit — apply lockstep to all three files.
  4. **F-16 — Update PM-CHAT.md lines 313–317** to remove `Edit` from the read-only profile's denied-tools list and add a one-line note: "Edit is permitted only on the agent's report file, per the chunked-Edit pattern in agent Hard rules."

  Verification: `validate-pack.py` PASS; trinity symmetry preserved on F-7 (Check 16 / 18); PM-CHAT.md profile description consistent with all 14 read-only agent files.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-126-BD-127.md`

---

**BD-126 — pm-startup per-CLI sync + Procedure 5-S revert + validator Check 28 + manifest-missing handling**
Type: TODO(version) — fix-follow on v10.1 backport (PACK-REVIEW F-8, F-9, F-11, F-17)
Status: Resolved
Blockers: none
Unblocks: closes the 3 BLOCKER cluster from `maintenance-docs/v11-implementation/PACK-REVIEW-V10.1-BACKPORT.md` so the v10.1 backport can ship cleanly
File/Symbol:
  - `project-template/.claude/skills/pm-startup/SKILL.md` — Step 4 + Step 6 RAG: summary line (sync from canonical)
  - `project-template/.codex/skills/pm-startup/SKILL.md` — Step 4 + Step 6 RAG: summary line (sync from canonical)
  - `project-template/.gemini/commands/pm-startup.toml` — Step 4 + Step 6 RAG: summary line inside the `prompt = """..."""` block (sync from canonical)
  - `project-template/skills/pm-startup/SKILL.md` (canonical) — add manifest-missing branch to Step 4 and matching state to the Step 6 `RAG:` summary template (F-17)
  - `supporting-docs/INSTALL-PROCEDURES.md` Procedure 5-S — revert Task C addition (line ~892), step 4 addition (lines ~902-906), and the "two tasks → three tasks" count change introduced by `45d2098`. Leave Procedure 5-S in its pre-v10.1 frozen form with the HISTORICAL banner intact.
  - `supporting-docs/METHODOLOGY.md` § RAG index hygiene — add brief sentence: "PM Chat reconciles RAG manifest on every `/pm-startup` per Step 4; the `RAG:` summary line surfaces the result. No separate post-migration procedure is needed in v11+."
  - `scripts/validate-pack.py` — NEW Check 28: `check_pm_startup_per_cli_parity()` modeled on Check 21 (pack-help parity). Asserts canonical SKILL and the three per-CLI surfaces agree on Step 4 substance + Step 6 RAG-line template. Gemini `.toml` requires extracting prose from the `prompt = """..."""` block before comparison.
Description: The v10.1 cherry-pick (`eec122e` + `45d2098`) updated only the canonical pm-startup SKILL — leaving the three live per-CLI surfaces with stale Step 4 (the pre-v10.1 single-file freshness check) and adding Procedure 5-S Task C that reads a `RAG:` line none of the live surfaces emit. Compounded: Task C was added to a procedure already marked `> HISTORICAL — sunset in v11 (BD-121)`. Result: Gemini `/pm-startup` ships stale Step 4; Procedure 5-S Task C is unrunnable; validator silence on pm-startup parity is what allowed the cherry-pick gap to land green.

  Verification: validator Check 28 passes; full `validate-pack.py` PASS; manual diff confirms Step 4 + Step 6 byte-equivalent across canonical + 3 per-CLI surfaces; Procedure 5-S diff vs `1daa938` shows zero net additions.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-126-BD-127.md`

---

**BD-125 — `dry-run-migration.sh` input contract + usage doc**
Type: TODO(version)
Status: Resolved
Blockers: BD-114
Unblocks: first public-release usability for the dry-run harness; clearer Optiquity release-gate procedure
File/Symbol: `supporting-docs/DRY-RUN-MIGRATION.md` (NEW); cross-references in `supporting-docs/MIGRATION-v10-to-v11.md`, `README.md`, `OPTIONAL-FEATURES.md` (audit and update if the dry-run is mentioned)
Description: Companion documentation for the parameterized BD-114
  harness. Must be public-friendly because the harness is now usable
  by any org maintaining a v10 client (not just Optiquity).

  Contents:
  1. **Input contract** — what state the target repo must be in for
     the dry-run to produce meaningful output: clean v10 install
     (CLAUDE.md present, .claude/ etc.), no uncommitted changes, no
     in-flight prior migration sentinel, no merge conflicts, on the
     primary branch.
  2. **Usage examples** — all three modes (synthetic fixture, public
     user with their own clone, URL-based against any git remote).
     Show the exact invocation for each.
  3. **Reading the output** — what the captured diff means, how to
     tell "this migration looks safe" from "this migration would
     break my customizations." Reference BD-088 customization-
     preservation report semantics.
  4. **Optiquity-style release gate** — how an org integrates the
     harness into their CI pipeline as a release gate: secret /
     env var convention for the target URL, recommended exit-code
     interpretation, when to treat a non-zero exit as a release
     blocker vs. a known-acceptable diff.
  5. **Limitations** — explicit list of what the harness does NOT
     verify (e.g., post-migration runtime behavior, downstream tool
     compatibility, anything outside the file-tree diff).
  6. **Recovery** — what to do if a real migration produces a
     different diff than the dry-run predicted (rare; means the
     target's state changed between dry-run and real run).

  Public-facing tone — the doc lives in `supporting-docs/` because
  consumers (any org running a pack-managed v10 client) will read it,
  not just pack maintainers. Keep it under ~150 lines; reference
  BD-114's harness usage output for the exhaustive flag/option
  listing rather than duplicating it.
Resolved: 2026-05-09 — see `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-125.md`. NEW `supporting-docs/DRY-RUN-MIGRATION.md` (199 lines — slightly over the ~150 target but all six BACKLOG-required sections covered). Cross-references added: README.md supporting-docs tree listing (+1 line) and MIGRATION-v10-to-v11.md "Before you start" checklist as new optional-but-recommended item 6 (+7 lines). OPTIONAL-FEATURES.md audited and left untouched (file scope is tool-specific opt-in features, not pack scripts; no existing dry-run mention to update). Every flag and exit code in the doc verified against as-shipped `scripts/dry-run-migration.sh --help` and source. Validator clean.

---

**BD-124 — Pack-coder skills: `implementation-report`, `verification-harness`, `commit-discipline`**
Type: TODO(version)
Status: Resolved
Blockers: BD-119 (let the pack-coder patterns settle through C-7 before formalizing)
Unblocks: shorter / more uniform pack-coder prompts for every future implementation BD
File/Symbol: `.claude/skills/implementation-report/SKILL.md`, `.claude/skills/verification-harness/SKILL.md`, `.claude/skills/commit-discipline/SKILL.md` (+ trinity peers in `.codex/skills/` and `.gemini/skills/`); `PACK-AGENTS.md` skills table; `.claude/agents/pack-coder.md` (and trinity peers) "Skills loaded by pack-coder" reference
Description: BD-119's C-1..C-7 sequence has surfaced three repeatable
  patterns that pack-coder produces or follows on every run. Today
  each is hand-encoded into every per-commit prompt (~30% boilerplate
  per agent invocation). Promote each to a trinity-mirrored skill so
  pack-coder loads them by reference and per-invocation prompts shrink
  to scope + goal + DoD.

  Three skills, three files each (trinity rule):

  1. `implementation-report` — required sections of every pack-coder
     report: pre-flight evidence (pwd / HEAD SHA / file existence
     checks), per-task summary, full file contents for new files,
     unified diffs for modified files, verification output (literal
     commands + tail), plan deviations log (zero is the expected
     case), POQs introduced + disposition, Definition-of-Done
     checklist (PASS/FAIL per item), proposed commit message in pack
     convention. Includes the chunking rule for >~300-line writes
     (initial Write + subsequent Edit-append) and the
     deferred-work-becomes-Cnb-commit pattern (lesson from C-4 →
     C-4b POQ-6).

  2. `verification-harness` — the pack test-script pattern: bash
     header, fixture-temp setup with `mktemp -d` + EXIT trap cleanup,
     per-case `pass:` / `fail:` lines with one-line description,
     final `=== Results: N passed, M failed ===` summary, exit 0 iff
     M=0. Documents the assertion-helper conventions that
     `test-detect.sh`, `test-migrator-manifest.sh`, and
     `test-migrator-core.sh` (BD-119 C-4b) all share. Consumed by
     pack-coder (writing new tests) and any future BD that adds a
     test runner (BD-116 persona contracts, BD-118 CI wiring, BD-114
     dry-run-real-ot harness).

  3. `commit-discipline` — pre-flight checks every pack-coder run
     does (`pwd` ends in worktree path, HEAD at expected base SHA,
     files-exist sanity), write-target rule (every Write/Edit goes
     under `pwd`; never under the main-checkout absolute path),
     and the absolute git-state-change ban (cross-references the
     CLAUDE.md "Pack memory" rule but enumerates the forbidden verb
     list explicitly so the skill is self-contained for any agent
     loading it). Codifies the BD-119 C-2 mis-routed-Write lesson.

  Touch-points beyond the skill files themselves:
    - `PACK-AGENTS.md` "Skills loaded by pack agents" table gets
      three new rows (which skills which agents load)
    - `.claude/agents/pack-coder.md` (trinity) "Before executing"
      section adds: "Load skills: implementation-report,
      verification-harness, commit-discipline. Skills are in
      `.claude/skills/`."
    - Existing pack-coder prompts in flight at the time should be
      regenerated to drop the now-skill-covered boilerplate; not
      retroactive (don't rewrite landed C-1..C-7 reports).

  **Sequencing:** depends on BD-119 closing first so the report /
  test-script / pre-flight patterns are fully settled. Doing this
  earlier risks formalizing a pattern that's still moving.
Resolved: 2026-05-09 — work shipped earlier; status flip in Batch 5 hygiene. See `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-124.md`.

---

**BD-123 — Relocate `tracker.toml.example` from repo root to `project-template/`**
Type: TODO(version)
Status: Cancelled
Blockers: BD-119 (must land AFTER BD-119 closes to avoid coordinating with the in-flight migrator refactor)
Unblocks: cleaner repo-root surface (root holds entry-point docs and pack ops files only)
File/Symbol: `tracker.toml.example` (move from repo root to `project-template/`); references in `README.md`, `OPTIONAL-FEATURES.md`, `HELP-FRAGMENT-TRACKER.md`, `CHANGELOG.md`, `BACKLOG.md`, `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/MERGE-STRATEGY.md`, `supporting-docs/MIGRATION-v10-to-v11.md`, `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh` (the BD-119 adapter shim post-cutover), `scripts/tests/test-init-project.sh`, `scripts/tests/test-migrate-v10-to-v11.sh`
Description: `tracker.toml.example` is template-source content — it's
  copied into a project on `init-project.sh` so the user can reference
  the canonical tracker.toml shape. It currently lives at repo root,
  which mixes user-facing example content with pack ops files
  (CLAUDE.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc.) and
  entry-point docs (README.md, QUICKSTART.md, OPTIONAL-FEATURES.md).
  Move to `project-template/tracker.toml.example` so it lives with the
  rest of project-template content. The user-facing path inside an
  initialized project does NOT change (still `tracker.toml.example` at
  the project root after init copies it). Update the 7 doc references
  + 4 script references. **Sequencing:** must land AFTER BD-119 closes
  — `migrate-v10-to-v11.sh` is being refactored from a monolith into a
  thin adapter via BD-119; doing this rename mid-refactor would force
  coordinating updates across both the monolith and the eventual
  adapter shim. Post-BD-119 the adapter is small and the rename
  touches it cheaply.
Resolution: 2026-05-09 cancelled — investigation revealed the BACKLOG entry's premise was wrong. There are TWO distinct `tracker.toml.example` files: pack-side at root (BD-prefix, Optiquity URL, "pack repo tracker configuration" header) for opting the pack repo itself into tracker mode, and client-side at `project-template/` (TD-prefix, your-org placeholder, "client project tracker configuration" header) that ships into client projects via `init-project.sh`. README.md documents both intentionally at lines 128 and 226. Moving one into the other's location would destroy the other. The underlying confusion (matching filenames) is addressed by BD-135, which renames both to filename-distinct forms per the `feedback_filename_uniqueness.md` heuristic.

---

## Active — v10 Scope

**BD-059 — v10 migration silently destroys project customization**
Type: TODO(version)
Status: Resolved
Blockers: None — pack-architect read-only audit of the OT post-migration state
  is the first step; pack-planner sequencing follows; both run in this session.
Unblocks: None
File/Symbol: pending architect output (design report under `maintenance-docs/`);
  pending planner output (implementation plan under `maintenance-docs/`); fix
  surface in pack repo to be defined by those documents.
Description:
  **Problem:** v10.0 migration (`scripts/migrate-v9-to-v10.sh` and the
  splice/merge helpers it calls) silently destroyed substantial project
  customization when run against the OT (OptiquityTrader) repo on
  2026-04-30. Confirmed losses on the OT branch `migration-v9-to-v10`:
  trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) — only the
  `**Active skills:**` line preserved, ~635 / 327 / 297 diff-lines of
  project-specific content (platform defaults, Xcode 26 features,
  domain model, broker integrations, Swift coding rules, security
  policy, refactoring policy, anti-patterns, phase routing, agent
  behavior) overwritten by pack template; `docs/pack/PM-CHAT.md` —
  project-name customizations and project-specific role/body content
  overwritten verbatim by pack template; `.claude/settings.json` —
  XCODE_SCHEME and XCODE_DESTINATION env values reset to empty, project-
  tuned permissions altered; `.codex/config.toml` — project-intentional
  removal of `[model_providers.ollama]` / `[model_providers.lmstudio]`
  reverted. The migration's `report.md` falsely declared
  `customization: none`. These confirmed losses are **non-exhaustive**:
  the audit needs to define the universe of files and customization
  patterns that the migration could have damaged, not stop at this list.

  **Goal:** v10 migration preserves project customization across the
  full surface area of files the migration touches, and produces a
  truthful customization report so the developer can review what
  changed before committing the migration. The architect defines the
  preservation and detection mechanism; the planner sequences the
  implementation; the fix lands directly in main.

  **Success criteria:**
  - Architect's audit covers every file and directory the migration
    script touches plus the project files the migration's blast radius
    can reach indirectly (e.g., via wholesale-overwrite stages). The
    set of files-with-customization is derived from the audit, not
    pre-supplied.
  - Architect's design preserves project customization across that
    full surface — trinity, PM-CHAT.md, settings.json, config.toml,
    .mcp.json.example, scripts, agent files, skill files, and any
    others the audit identifies — without requiring v9.3 projects to
    adopt v10's marker-section convention retroactively.
  - Architect's design closes the verification gap that allowed
    `V10-PHASE-4-VERIFICATION.md` §4.6 (OT real-project migration smoke)
    to pass while the production migration corrupted OT trinity content.
    The closure includes a fixture or fixture pattern that exercises
    realistic v9.3 customization shapes.
  - `validate-pack.py` (or equivalent) gains coverage that would have
    caught this defect before release.
  - On a post-fix re-run of the migration against a freshly reverted
    OT, the project customization listed above survives the migration
    and the report accurately characterizes what changed.
  - **Trinity rule applies to per-tool tool-level configuration.** Every
    capability one of the three tools expresses in its config-file
    surface (`.claude/settings.json`, `.codex/config.toml` +
    `requirements.toml`, `.gemini/settings.json` and adjuncts including
    `.gemini/.env`) is expressed by the other two via their own
    config-file conventions, OR the asymmetry is explicitly documented
    as a tool capability gap (not a pack defect). Specifically required
    by user decisions on 2026-04-30: (a) `AGENT_CAPABILITIES` parity on
    the Gemini side via `.gemini/.env` (Option A from
    `V10-GEMINI-CONFIG-RESEARCH.md` Q4); (b) MCP server configuration
    parity across all three tools — Claude already ships
    `.mcp.json.example`, Gemini already supports MCP via
    `.gemini/settings.json`, and Codex supports MCP via
    `[mcp_servers.<name>]` tables in `config.toml` per
    `V10-CODEX-MCP-RESEARCH.md` Part 1 (STDIO + Streamable HTTP; v10
    ships STDIO via `.codex/config.toml.example` sibling matching the
    `.mcp.json.example` pattern). BD-059 does not resolve until both
    (a) and (b) are satisfied.

Context: Incident discovered 2026-04-30 by user inspection of the OT
  post-migration state. v10.0 has not reached any production project
  yet (OT is the only target and was the verification fixture itself);
  the fix lands in main without a version bump or branch. Audit of the
  OT post-migration state recorded in this session's transcript
  identified the confirmed losses above and the root cause: stages S3
  and S5 of `migrate-v9-to-v10.sh` overwrite project files from pack
  templates, and `merge-trinity.py` preserves only the
  `**Active skills:**` line and `### Custom agents` sub-section
  (assuming a marker-section structure that v9.3 projects do not
  have). The customization-detection that drives `report.md` and any
  `_v9-backup.md` triggering is scoped only to `PROMPT-TEMPLATES.md`
  text comparison, leaving every other potential customization point
  unaudited and unreported.
Resolved: 2026-05-09 — closed by BD-088 (Customization-preservation algorithm + truthful report; explicitly framed as "BD-059 fix as v11-cut artifact"). BD-088 shipped 2026-05-07 with `scripts/lib/customization-preserve.sh` + `customization-report.sh` + 72 fixture tests covering 12 file classes via 8 canonical dispositions. BD-088's `Unblocks` line names BD-059 explicitly. Status flip in Batch 5 hygiene.

---

**BD-020 — C++ server support analysis**
Type: TODO(version)
Status: Open
Blockers:
  - No concrete C++ project need has arisen
Unblocks: None
File/Symbol: n/a — new file `maintenance-docs/CPP-SERVER-ANALYSIS.md` to be created
Description: C++ is a common choice for high-performance gRPC servers and
  systems-level services. The `cpp-language` skill already exists in the v9
  unified template (created as part of BD-024). This analysis covers the
  remaining server-specific gap: C++ gRPC library choices (grpc++ official
  library), build system options (CMake, Bazel, Makefile), what a
  `cpp-server-architecture` skill would need to cover beyond what
  `cpp-language` already provides, toolchain differences from Python/Swift,
  and whether any existing pack files apply unchanged.
Context: Analysis only — no implementation until a concrete project need arises.
  Original framing assumed a new template directory; updated April 2026 to reflect
  the unified template model from BD-024. BD-024 resolved in v9 — the
  `cpp-language` skill now exists; only the server-specific analysis remains.
Resolved: n/a

---

**BD-021 — Redesign Apple platform architecture skills (three-tier)**
Type: TODO(version)
Status: Deprecated
Blockers:
  - BD-022 c-language skill must exist first (shared dependency between Apple and C templates)
  - v9 planning conversation needed to confirm skill boundaries
Unblocks: None
File/Symbol: n/a — modifications across apple-app and monorepo template files
Description: The current `ios-architecture` skill applies to all Apple targets but macOS
  and iOS are not a superset/subset of each other — they are siblings with significant
  platform-specific differences. A single combined skill either includes irrelevant checklist
  items or misses platform-specific ones. Universal apps complicate this further.

  Proposed three-tier design:

  1. `apple-architecture-core` skill (new) — patterns shared across all Apple platforms:
     SwiftUI-first design, protocol abstractions at layer boundaries, immutability defaults,
     actor isolation, typed IDs, LSP compliance, SPM module structure. ~60% of current
     `ios-architecture` skill content.

  2. `ios-architecture` skill (refocus existing) — iOS/iPadOS-specific: scene lifecycle,
     UIKit interop justification, background task design, App Store/extension boundaries,
     touch-first interaction model. Remove overlap with core.

  3. `macos-architecture` skill (new) — macOS-specific: NSDocument-based architecture,
     multiple NSWindow management, AppDelegate lifecycle and Dock behavior, menu bar ownership
     and command validation, AppKit interop patterns, Services/AppleScript/Shortcuts
     integration, sandboxed file access model, floating panels and inspector windows.

  For universal apps: `apple-architect` agent uses all three skills — core plus both
  platform skills. Agent description updated to specify the combination per project target type.

  For future platforms (watchOS, visionOS, tvOS): same pattern — platform-specific skill
  alongside core. Not in scope for this item.

  Also required: Update `apple-architect` agent description and phase routing tables in
  CLAUDE.md and AGENTS.md to reference the correct skill combination per project type.
Context: macOS and iOS are siblings, not superset/subset. A single combined skill
  produces irrelevant checklist items for platform-specific projects. Universal apps
  need all three skills; single-platform projects need core + platform skill only.
Resolution: April 2026, deprecated — superseded by BD-024 (unified template and
  platform skills redesign). The three-tier skill design (apple-architecture-core,
  ios-architecture, macos-architecture) is preserved and becomes part of BD-024's
  skill library. The template-directory framing is dropped.

---

**BD-022 — C project template and c-language skill**
Type: TODO(version)
Status: Deprecated
Blockers:
  - v9 planning conversation needed to confirm build system and test framework choices
Unblocks: BD-021 (c-language skill is a shared dependency)
File/Symbol: n/a — new `c-project-template/` directory; new `c-language` skill file
Description: Standalone C projects (command-line tools initially; embedded code and libraries
  in scope for later iterations) currently have no pack support. A lightweight template is
  needed with a minimal agent set and simple tooling choices.

  Template scope — v9 target (command-line tools):
  - Agents: `architect`, `planner`, `coder`, `reviewer` — no grpc-schema, no docs-researcher,
    no Python-specific agents
  - Build system: Makefile (simple, universally available, no dependencies)
  - Testing framework: one lightweight C test framework (e.g. Unity or Check — decide at
    implementation time based on simplicity and macOS/Linux compatibility)
  - Static analysis: `clang-tidy` or `cppcheck` (decide at implementation time)
  - Scripts: `bootstrap.sh`, `build.sh`, `test.sh`, `format.sh` (clang-format), `validate.sh`
  - CLAUDE.md and AGENTS.md: C-specific rules (memory management, no hidden allocations,
    explicit ownership, no undefined behavior, const correctness, header hygiene)
  - No gRPC, no proto scaffold, no Python tooling

  Later iterations (deferred):
  - Embedded code: cross-compiler support, hardware abstraction layer patterns, interrupt safety
  - Libraries: shared library vs static library conventions, versioned ABI, pkg-config

  c-language skill (also needed for BD-023 — Apple mixed-language projects):
  A `c-language` skill for use in `coder`, `reviewer`, and `architect` agents across any
  template where C code may appear. Covers: memory ownership and lifecycle, pointer safety,
  buffer handling, null termination discipline, const correctness, header include guards,
  function naming conventions, interop with Swift (bridging headers), interop with Python
  (ctypes/cffi/Cython), and common C anti-patterns to avoid.
Context: SPM vs Makefile was discussed — Makefile chosen for simplicity and zero dependencies.
  c-language skill is created here and shared with BD-023 to avoid duplication.
Resolution: April 2026, deprecated — superseded by BD-024 (unified template and
  platform skills redesign). The c-project-template directory is dropped; a C project
  will use the single unified template with c-language skill loaded. The c-language
  skill content is preserved and becomes part of BD-024's skill library.

---

**BD-023 — Mixed-language skills for Apple projects (Objective-C, C, C++, graphics)**
Type: TODO(version)
Status: Deprecated
Blockers:
  - BD-022 must be completed first — c-language skill is shared between C template and Apple projects
Unblocks: None
File/Symbol: n/a — new skill files for use in apple-app and monorepo template agents
Description: Apple projects may contain Objective-C (legacy code), C (performance routines,
  third-party library bridges), or C++ (performance-critical code, graphics). New projects
  will not use Objective-C, but old projects may require modifications. New projects may add
  C or C++ for performance or graphics. Agents need targeted skills for each case — not a
  combined skill, since the contexts and patterns differ significantly.

  Skills to create:

  `objc-language` skill — for `coder` and `reviewer` agents:
  Read/modify legacy Objective-C code in Swift-first projects. Covers: ARC memory management,
  nullability annotations (`_Nullable`, `_Nonnull`), bridging header patterns, NS_SWIFT_NAME
  and NS_REFINED_FOR_SWIFT, @objc attribute usage, property declaration patterns, avoid writing
  new Objective-C unless there is no Swift alternative. Writing new Objective-C is a last resort
  only — document why no Swift alternative exists. No Objective-C++ (`.mm` files) in scope.

  `c-language` skill — shared with BD-022:
  See BD-022. Same skill, used here when C appears in Apple projects: wrapping third-party C
  libraries via bridging headers, writing performance-critical routines called from Swift via
  a C shim, C interop patterns. Covers ownership, pointer safety, const correctness, and
  Swift-C bridging conventions.

  `cpp-language` skill — for `coder` and `reviewer` agents:
  C++ in Apple projects for performance-critical code or graphics work. Covers: RAII and
  ownership (no raw `new`/`delete` in modern C++), `std::unique_ptr` and `std::shared_ptr`
  patterns, Swift-C++ interoperability (Swift 5.9+ direct C++ interop), header organization
  (`.hpp`/`.cpp` split), avoiding exceptions in performance paths, const correctness, rule of
  five, and common C++ anti-patterns. Does not cover Objective-C++ (`.mm`) — that is a
  separate concern handled at the architecture level if ever needed.

  Graphics engine skills (separate skills, each focused on one engine/framework):
  These are distinct enough from general C/C++ to warrant their own skills. Each engine has
  its own patterns, asset pipeline, and integration model. To be created when a concrete
  project need arises:
  - `metal-cpp-language` skill — Metal C++ API patterns (distinct from Swift Metal)
  - `unity-cpp-language` skill — Unity C++ native plugin patterns
  - `unreal-cpp-language` skill — Unreal Engine C++ patterns (UObject, UFUNCTION, etc.)
  Note: Metal via Swift bridge already works with existing Apple skills — no new skill
  needed for Swift Metal usage.

  Agent integration:
  These are skills used by existing agents, not new agents. The `apple-architect` agent
  (and future platform-specific variants per BD-021) would reference the appropriate skills
  when the project contains mixed-language code. The `coder` and `reviewer` agents include
  the skill when working on files of the relevant type.

  Objective-C template: Not planned. Objective-C support is skill-only. A full
  `objc-project-template` is out of scope unless a concrete project need arises.
Context: Skills-only approach chosen over a new template. Graphics engine skills deferred
  until a concrete project need arises — they are too engine-specific to define speculatively.
Resolution: April 2026, deprecated — superseded by BD-024 (unified template and
  platform skills redesign). The Apple-specific framing is dropped; all skills
  (objc-language, c-language, cpp-language, graphics engine skills) become part of
  the unified skill library available to any project. Skill content from this item
  is fully preserved in BD-024.

---

## Resolved — v8 (March 2026)

All BD-001 through BD-019 items resolved across Groups 1–6.

| Item | Description | Commit |
|---|---|---|
| BD-001 | Rename ios-architect → apple-architect | 08f7158 |
| BD-002 | Add post_edit_command to .codex/config.toml (all 3 templates) | 08f7158 |
| BD-003 | Add scripts setup and usage docs to CLAUDE.md, AGENTS.md, QUICKSTART.md | 9cd9a7f |
| BD-004 | Resolve format.sh hook discrepancy | 08f7158 |
| BD-005 | Add XCODE_SCHEME warnings to validate.sh, test.sh, agent-post-edit-check.sh | 08f7158 |
| BD-006 | Add python-architect agent + python-architecture skill (python-server, monorepo) | 61b3381 |
| BD-007 | New-project generation templates (SETUP_TEMPLATE.md, AGENT_KICKOFF_TEMPLATE.md) | 2fc4a0c |
| BD-008 | Add METHODOLOGY.md to all templates and supporting-docs | 2fc4a0c |
| BD-009 | Add PROMPT-TEMPLATES.md to supporting-docs (14 templates) | 2fc4a0c |
| BD-010 | Update QUICKSTART.md Steps 11–13 for PM chat and new-project workflow | 2fc4a0c |
| BD-011 | Add VS Code companion files in vscode-companion-templates/ | 61b3381 |
| BD-012 | Commit Methodology Guide v1 to maintenance-docs/origins/ | 2fc4a0c |
| BD-013 | Gemini CLI analysis document | 9a6ba5b |
| BD-014 | Android support analysis document | 9a6ba5b |
| BD-015 | Document SETUP.md/AGENT_KICKOFF.md generation workflow | 2fc4a0c |
| BD-016 | Merge OT content into apple-app CLAUDE.md/AGENTS.md | 9cd9a7f |
| BD-017 | Fix availability guard omission in iOS 26 platform features section | 08f7158 |
| BD-018 | v7→v8 migration guide | 9a6ba5b |
| BD-019 | Desktop Commander usage and PM chat scope limits (METHODOLOGY.md) | 2fc4a0c |

---

**BD-024 — Unified template and platform skills redesign**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-020 (C++ analysis outcome depends on unified model being settled)
File/Symbol: n/a — replaces three template directories with one; new skill library
Description: Replace the three template directories (apple-app-template,
  python-server-template, apple-app-plus-python-server-template) with a single
  unified template containing platform-agnostic agents and a composable skill
  library. The PM chat selects the appropriate skills per project at prompt
  generation time based on the project's platform profile in CLAUDE.md.

  **Motivation:** Adding any new platform (Android, Windows, C++ server, embedded)
  currently requires a new template directory with ~25 duplicated files. This is
  unsustainable. Under the unified model, adding a platform requires only new skill
  files and a documentation update — no new agents, no new template directories.

  **Agent changes:**
  - `apple-architect` and `python-architect` merge into a single `architect` agent
    with a platform-agnostic system prompt. Platform knowledge comes from skills.
  - All other agents (coder, reviewer, tester, docs-researcher, planner, repo-ops,
    grpc-schema) are already platform-agnostic — no changes required.
  - Agent files move from three template directories into one.

  **Skill library to create** (all skills are platform-agnostic and composable):
  - `swift-best-practices` — Swift language, concurrency, type system, Swift 6 rules
  - `apple-architecture-core` — patterns shared across all Apple platforms: SwiftUI,
    protocol abstractions, actor isolation, typed IDs, LSP compliance, SPM structure
  - `ios-architecture` — iOS/iPadOS-specific: scene lifecycle, UIKit interop,
    background tasks, App Store boundaries, touch-first interaction model
  - `macos-architecture` — macOS-specific: NSDocument, multiple NSWindow management,
    AppDelegate, menu bar, AppKit interop, sandbox, notarization, Services integration
  - `python-best-practices` — Python patterns, async, type hints, ruff/pyright rules
  - `grpc-patterns` — Protobuf schema design, gRPC service patterns, buf tooling
  - `c-language` — memory ownership, pointer safety, buffer handling, const
    correctness, header guards, Swift/Python interop (from BD-022)
  - `objc-language` — ARC, nullability annotations, bridging headers, NS_SWIFT_NAME,
    legacy code modification patterns (from BD-023)
  - `cpp-language` — RAII, smart pointers, Swift-C++ interop, header organization,
    rule of five, C++ anti-patterns (from BD-023)

  **Skill selection by project type** (PM chat uses this at prompt generation time):
  - macOS Swift app: swift-best-practices + apple-architecture-core + macos-architecture
  - iOS Swift app: swift-best-practices + apple-architecture-core + ios-architecture
  - Universal app: swift-best-practices + apple-architecture-core + ios-architecture
    + macos-architecture
  - Python gRPC server: python-best-practices + grpc-patterns
  - Swift app + Python runtime (e.g., embedded interpreter): swift-best-practices
    + macos-architecture + c-language (Python C API is the bridge)
  - Mixed-language Apple: add objc-language or cpp-language as needed

  **Scripts:** bootstrap.sh, validate.sh, format.sh require platform-aware logic or
  a lightweight generator that assembles the correct script content at project setup
  time based on answered platform questions. Strategy to be decided during v9 planning.

  **METHODOLOGY.md update required:** Add a skill-selection section describing how
  the PM chat determines which skills to load for a given project type, and where
  the project's platform profile is declared (CLAUDE.md).

  **Deferred to future items:**
  - Android, Windows, embedded platform skills — new skill files only when needed
  - watchOS, visionOS, tvOS — apple-architecture-core covers shared patterns;
    platform-specific skills to be added when a concrete project need arises
  - Graphics engine skills (Metal-cpp, Unity, Unreal) — deferred per BD-023
  - Codex (.codex/) port — Claude Code version must be stable first

Context: Emerged from April 2026 design analysis. The three existing template
  directories are structurally identical — only CLAUDE.md and a few agent files
  differ per platform. The real platform specialization already flows through
  documents (ARCHITECTURE.md, CLAUDE.md), not agents. Skills make this explicit
  and extensible. BD-021, BD-022, and BD-023 are deprecated into this item;
  all skill content from those items is preserved here.
Resolved: April 2026, v9.0 — unified template with 16 agents, 30 skills,
  15 scripts in `project-template/`. Three old template directories removed.
  Commits f61c776 through d4dc6f3 on v9-dev, merged to main.

---

**BD-025 — Update DEPENDENCIES.md for Codex and Gemini CLIs**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/DEPENDENCIES.md
Description: DEPENDENCIES.md currently documents only Claude Code CLI and
  project-level tools (Swift, Python, buf, etc.). Codex CLI and Gemini CLI are
  not listed. Node.js (required by Gemini CLI) is not listed. Add: Codex CLI
  installation and version requirements; Gemini CLI installation (npm global);
  Node.js as a shared dependency; any future C/C++ toolchain entries.
Context: Part of BD-024 Step 12 scope. Can be drafted independently.
Resolved: April 2026, v9.0 — DEPENDENCIES.md covers Claude Code CLI, Codex CLI,
  Gemini CLI, and Node.js. Commit 5035328.

---

**BD-026 — Split scripts by language/platform**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: scripts/ directory in unified template
Description: The current monolithic format.sh and validate.sh handle all
  languages with nested conditionals. Under the unified template, language-specific
  scripts (format-swift.sh, format-python.sh, validate-swift.sh, validate-python.sh,
  validate-proto.sh, bootstrap-swift.sh, bootstrap-python.sh, test-swift.sh,
  test-python.sh) replace the monoliths. Thin wrapper scripts (format.sh,
  validate.sh, bootstrap.sh, test.sh) detect the project type and call the
  appropriate language-specific scripts. agent-post-edit-check.sh becomes
  language-aware. agent-run.sh is updated for the v9 agent roster and Gemini CLI.
  proto-gen.sh is carried forward unchanged.
Context: Part of BD-024 Step 9. See V9-DESIGN.md Decision 4 for full rationale.
Resolved: April 2026, v9.0 — language-specific scripts (format-swift.sh,
  format-python.sh, validate-swift.sh, validate-python.sh, validate-proto.sh,
  bootstrap-swift.sh, bootstrap-python.sh, test-swift.sh, test-python.sh) with
  wrapper scripts. agent-run.sh updated for v9 roster including auditor and
  Gemini CLI. Commit fd03d11.

---

**BD-027 — Auditor agent design and implementation**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: .claude/agents/, .codex/agents/, GEMINI.md,
  supporting-docs/METHODOLOGY.md, supporting-docs/PROMPT-TEMPLATES.md,
  .claude/skills/audit-methodology/
Description: Add a new auditor agent for full-codebase structural audits.
  Unlike reviewer (per-phase) and tester (pre-implementation strategy), the
  auditor is retrospective and periodic — run after multiple phases to find
  systemic gaps. Uses a parent + seven subagent architecture:
  auditor-architecture, auditor-code, auditor-tests, auditor-docs,
  auditor-security, auditor-ui, auditor-ops. Parent coordinates subagents
  and consolidates their reports. Requires a new audit-methodology skill.
  Also serves as the pack's reference example of subagent orchestration.
  Templates 9-12 in PROMPT-TEMPLATES.md: Template 9 rewritten as the
  auditor invocation template; Templates 10-12 superseded.
Context: Part of BD-024 Steps 10-11. See V9-DESIGN.md Decision 6 for
  full design. Updated April 2026: auditor-ui split into auditor-ui (UI
  compliance only) and auditor-ops (deployment readiness, config management,
  observability wiring) — seven subagents total.
Resolved: April 2026, v9.0 — parent auditor + 7 subagents across Claude,
  Codex, and Gemini. audit-methodology skill created. Template 9 rewritten;
  Templates 10-12 superseded. Commits d2c3599, 5135732.

---

**BD-028 — PM-CHAT.md expansion for all three tools**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: PM-CHAT.md (template), supporting-docs/PM-CHAT.md (source),
  PLATFORM-SKILLS.md (new), GEMINI.md (new project template file),
  .claude/skills/pm-startup/SKILL.md
Description: The current PM-CHAT.md covers only Claude PM chat architecture.
  Expand to cover: Claude Web Projects, Gemini CLI, and ChatGPT Web / Codex
  — each with startup procedures, file write mechanisms, context compression,
  and cross-tool switching guidance. Create PLATFORM-SKILLS.md (skill-selection
  matrix by project type and agent). Create GEMINI.md project template context
  file. Update pm-startup skill to include PLATFORM-SKILLS.md in RAG check.
  Decide and document whether pm-startup is ported to Codex and Gemini.
Context: Part of BD-024 Step 5. See V9-DESIGN.md Part 3 for PM chat architecture.
Resolved: April 2026, v9.0 — PM-CHAT.md covers Claude, Codex, and Gemini.
  PLATFORM-SKILLS.md created. Template GEMINI.md created. pm-startup skill
  updated with PLATFORM-SKILLS.md check. Commit 215f413.

---

**BD-029 — Pack self-validation CI/CD**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: .github/workflows/ (new)
Description: Add a GitHub Actions workflow that validates on every push to the
  pack repo: all SKILL.md files have valid frontmatter (name, description,
  allowed-tools); all .codex/agents/*.toml files parse correctly; no BACKLOG.md
  entries contain TD-TBD sentinels; README.md version table is consistent with
  the most recent git tag. Deliberate structural errors should cause clear
  workflow failures.
Context: Post-v9, after all v9 files exist. See V9-DESIGN.md Step 14.
Resolved: April 2026, v9.0 — `.github/workflows/validate-pack.yml` with
  SKILL.md frontmatter validation, TOML parsing, TD-TBD sentinel check,
  and version table consistency. Commit 8fe8dce.

---

**BD-030 — TOOL-COMPARISON.md living capability reference**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: maintenance-docs/TOOL-COMPARISON.md
Description: Create a structured, date-stamped capability reference covering
  all three AI tools: PM chat capability matrix, agent invocation differences,
  skill loading mechanisms, approval model defaults, context window guidance,
  and cost routing. Supersedes GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md.
Context: Created during v9 planning phase. Committed as part of v8.10.
Resolved: April 2026, v8.10 planning docs commit.

---

**BD-032 — Validate auditor observability infrastructure vs. configuration boundary**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project with cloud-deployed observability runs a full audit (PACK-FEEDBACK.md Q1)
Unblocks: None
File/Symbol: `project-template/skills/audit-methodology/SKILL.md` — rule 21 (auditor-ops scope)
Description: The auditor splits observability into auditor-architecture (does
  the wiring exist in code?) and auditor-ops (is it configured correctly for
  the deployment target?). This boundary is logically sound but untested on
  real observability code. If the first real audit shows findings that sit at
  the boundary with no clear owner, refine rule 21 and the subagent files
  with concrete "if X, it belongs to auditor-ops; if Y, auditor-architecture"
  examples.
Context: Deferred from the v9 auditor fix pass (d2c3599). The pack repo has
  no observability code to test against. Tracked as PACK-FEEDBACK.md Q1 in
  every downstream project.
Resolved: n/a

---

**BD-033 — Validate auditor systemic error handling threshold**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project with non-trivial error handling runs a full audit (PACK-FEEDBACK.md Q2)
Unblocks: None
File/Symbol: `project-template/skills/audit-methodology/SKILL.md` — rule 16 (auditor-code scope)
Description: auditor-code audits "systemic error handling" (boundary mapping
  consistency, retry policy uniformity) as distinct from per-function
  error-handling bugs. The threshold between systemic and per-function is not
  quantified. If the first real audit shows auditor-code struggling to
  distinguish the two, add a concrete threshold to rule 16 and consider
  whether the error-handling skill needs systemic rules split from
  per-function rules.
Context: Deferred from the v9 auditor fix pass (d2c3599). The pack repo has
  no Swift/Python domain code to audit for error handling patterns. Tracked
  as PACK-FEEDBACK.md Q2.
Resolved: n/a

---

**BD-034 — Validate auditor-ui scope breadth after ops split**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project with substantial UI runs a full audit (PACK-FEEDBACK.md Q3)
Unblocks: None
File/Symbol: `project-template/skills/audit-methodology/SKILL.md` — rule 20 (auditor-ui scope)
Description: After splitting auditor-ui (UI compliance only) from auditor-ops
  (deployment readiness), auditor-ui covers 4 specific checks: view thickness,
  accessibility gaps, incomplete UI states, platform-specific UI conventions.
  A traditional UI audit might expect more (localization, dark mode, Dynamic
  Type, iPad split-view, custom gestures). If the first real UI audit shows
  the scope is too narrow, extend rule 20 with additional examples.
Context: Deferred from the v9 auditor fix pass (d2c3599). The pack repo has
  no UI layer. Tracked as PACK-FEEDBACK.md Q3.
Resolved: n/a

---

**BD-035 — Validate python-architecture skill loading for non-server Python**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 non-server multi-file Python project runs a full audit (PACK-FEEDBACK.md Q4)
Unblocks: None
File/Symbol: `project-template/PLATFORM-SKILLS.md` — auditor-code skill assignment
Description: PLATFORM-SKILLS.md loads python-architecture for auditor-code
  only when a Python server is present. Performance anti-patterns (N+1
  queries, blocking I/O in async handlers) apply to any multi-file Python
  project. If the first real audit on a non-server Python project misses
  findings that python-architecture would have caught, expand the loading
  rule.
Context: Deferred from the v9 auditor fix pass (d2c3599). No non-server
  Python project exists to test against. Tracked as PACK-FEEDBACK.md Q4.
Resolved: n/a

---

**BD-036 — IDE and editor coverage gaps**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project reports IDE/editor coverage observations (PACK-FEEDBACK.md Q5)
Unblocks: None
File/Symbol: `xcode-companion-templates/`, `vscode-companion-templates/`,
  project-template context files (CLAUDE.md, AGENTS.md, GEMINI.md)
Description: The pack has deep Xcode integration (companion templates,
  post-edit hooks, scheme config, iOS doc sync) but thin VS Code coverage
  (basic companion templates only) and no coverage for JetBrains, Cursor,
  or other editors. If the first v9 project using a non-Xcode IDE reports
  missing workflow guidance, hook integration, or editor-specific config,
  create the relevant companion templates or skill content. Even Xcode-only
  projects may report gaps when new Xcode versions ship.
Context: Deferred from v9 Step 12 doc pass. The pack's Apple heritage means
  Xcode is deeply covered; other editors need real-world data to determine
  what's missing. Tracked as PACK-FEEDBACK.md Q5.
Resolved: n/a

---

**BD-037 — Platform update cycle observability**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project encounters a major platform update (PACK-FEEDBACK.md Q6)
Unblocks: None
File/Symbol: `project-template/skills/` (platform skills may need updates),
  project-template context files (availability guards, API references)
Description: When a major platform update ships (iOS 27, macOS 27, Python
  3.14, Swift 7, new CLI tool versions), pack skills and context files may
  become stale. Currently there is no mechanism to detect this proactively
  — the PM chat must notice and report. If the first platform update cycle
  on a v9 project reveals a pattern (which content goes stale first, how
  quickly, how the gap was discovered), use that data to build a proactive
  update checklist or CI check into the pack.
Context: Deferred from v9 Step 12 doc pass. Needs real-world observation of
  at least one platform update cycle. Tracked as PACK-FEEDBACK.md Q6.
Resolved: n/a

---

**BD-038 — Dynamic skill management mid-project**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: project-level CLAUDE.md/AGENTS.md/GEMINI.md (Active skills line),
  skills/pm-startup/SKILL.md, supporting-docs/METHODOLOGY.md (Procedure 1 step 6),
  project-level PM-CHAT.md, supporting-docs/PROMPT-TEMPLATES.md (Template 1)
Description: Projects need to add or remove skills mid-project as needs evolve.

  Implemented mechanism: An **Active skills** line in the Skill loading section
  of CLAUDE.md, AGENTS.md, and GEMINI.md lists the skills currently loaded for
  the project. The PM chat writes this line during project kickoff by deriving
  skills from PLATFORM-SKILLS.md for the project's type. Mid-project changes
  update this line and the project description, then commit.

  Proactive detection: At Procedure 1 step 6 (phase gate check), the PM chat
  scans the upcoming phase for technology references not covered by the active
  skills. If a matching skill exists in the pack, it flags the developer to add
  it. If no matching skill exists, it records the gap in PACK-FEEDBACK.md for
  the pack maintainer.

  pm-startup reads and reports the active skills list at session start.

Encapsulation: Additive changes to Skill loading section (trinity files),
  pm-startup (one step), Procedure 1 (one step), PM-CHAT.md (one rule),
  Template 1 (one instruction), Workflow 1 (one sub-step), migration guide
  (one note). No agent files change. No workflow structure changes. Revertable
  by removing the Active skills line and reverting the additive steps.
Context: Design discussion April 2026. Initial design proposed a separate
  `skills:` field; revised to use an Active skills line in the existing Skill
  loading section — additive on top of PLATFORM-SKILLS.md, not a replacement.
Resolved: April 2026, v9.1 — commit f8758f9.

---

**BD-039 — Prototype / speed mode**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: BD-040 (autonomous mode references prototype gate definitions)
File/Symbol: project-level CLAUDE.md (mode: field),
  supporting-docs/METHODOLOGY.md (Procedure 1 conditional logic, new Mode section),
  supporting-docs/PM-CHAT.md
Description: Projects sometimes need to prioritize speed over correctness —
  prototypes, proof-of-concept builds, throwaway experiments. The pack currently
  has one quality setting. Prototype mode selectively relaxes gates without
  changing any agent behavior or files.

  Mode declaration: `mode: prototype` in project-level CLAUDE.md. Default is
  `mode: standard` (current behavior). Toggling requires a CLAUDE.md edit and
  commit — not a session flag — so the mode is visible in git history.
  The mode is always prominently reported in pm-startup output.

  What changes in prototype mode:
  - Reviewer findings are logged to BACKLOG.md as tech debt items but are
    non-blocking (PM chat proceeds without requiring fixes first)
  - Tester agent is skipped unless explicitly requested
  - Architect is optional before coder for phases marked exploratory in the
    implementation plan
  - validate.sh runs but non-zero exit does not block proceeding (warning logged)

  What does NOT change:
  - Agent files, scripts, skills — unchanged
  - The reviewer still runs and its output is still recorded
  - BACKLOG.md tracks all accumulated tech debt automatically; these items
    become the cleanup list when mode returns to standard

Encapsulation: All logic lives in Procedure 1 conditional branches and the PM
  chat's prompt generation. Zero changes to agent files, skill files, or scripts.
  Revertable by removing the mode: field from CLAUDE.md and reverting the
  Procedure 1 additions. Tech debt items accumulated during prototype mode
  remain in BACKLOG.md permanently.
Context: See design discussion April 2026.
Resolved: n/a

---

**BD-040 — Fully autonomous execution mode**
Type: TODO(version)
Status: Open
Blockers: BD-039 (autonomous mode references prototype gate definitions;
  both modify Procedure 1 and must be sequenced to avoid conflicts)
Unblocks: None
File/Symbol: project-level CLAUDE.md (mode: autonomous, autonomous_threshold: field),
  STATUS.md (stop marker convention), supporting-docs/METHODOLOGY.md
  (new Procedure 5 — autonomous execution loop), supporting-docs/PM-CHAT.md
Description: For well-defined projects with complete implementation plans, the
  PM chat should be able to execute an entire coder → reviewer → fix cycle
  without developer interaction, stopping only at genuine blockers.

  Mode declaration: `mode: autonomous` in project-level CLAUDE.md, with optional
  `autonomous_threshold:` specifying the reviewer finding severity that triggers a
  stop (default: any Critical finding). Toggling follows the same commit-based
  mechanism as BD-039.

  Autonomous execution loop (new Procedure 5):
  1. Read current phase from STATUS.md
  2. Verify phase is fully defined in IMPLEMENTATION-PLAN.md with a mechanically
     verifiable definition of done — if not, stop and report immediately
  3. Generate coder prompt, invoke agent, collect output
  4. Generate reviewer prompt, invoke agent, collect output
  5. If reviewer passes: commit, update STATUS.md, advance to next phase, loop
  6. If findings are below threshold: generate fix prompt, invoke coder, re-run
     reviewer, loop (max 2 fix cycles per phase before stopping)
  7. If Critical finding, fix cycles exhausted, or plan is ambiguous: write
     ⚠️ AUTONOMOUS STOP to STATUS.md with reason, commit current state, halt

  Hard limits — autonomous mode cannot:
  - Modify ARCHITECTURE.md
  - Create new phases in IMPLEMENTATION-PLAN.md
  - Skip a reviewer pass
  - Proceed past a Critical reviewer finding
  - Handle external dependencies (credentials, env setup, API keys)
  - Proceed if build fails after 2 fix cycles

  Notification: The ⚠️ AUTONOMOUS STOP marker in STATUS.md is the signal.
  Developer checks STATUS.md to see where execution stopped and why.

Encapsulation: All logic in Procedure 5 and STATUS.md conventions. Zero changes
  to agent files, skills, or scripts — agents run identically. Stop marker is
  additive to STATUS.md. Revertable by removing mode: and autonomous_threshold:
  from CLAUDE.md and removing Procedure 5 from METHODOLOGY.md.

Risk note: Requires the implementation plan phase to have a complete, mechanically
  verifiable definition of done. If the plan is vague, autonomous mode refuses to
  start for that phase. This check is the primary safeguard against wrong
  implementations being committed without review.
Context: See design discussion April 2026.
Resolved: n/a

---

**BD-041 — Project initialization brief guidance**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: project-template/PM-CHAT.md, QUICKSTART.md
Description: The PM chat currently has no guidance on what to do when a project
  starts without a defined platform, skill set, or architecture. Left unguided,
  a PM chat will attempt design decisions it is not positioned to make well.

  The correct split: platform selection, feature scope, and architecture decisions
  belong in a design conversation (Claude Web side chat or equivalent), not in the
  PM chat. The PM chat is a consumer of a design brief, not its author.

  Implemented: "Before starting a new project" section added to PM-CHAT.md
  requiring a design brief before the PM chat proceeds. Prerequisite callout
  added to QUICKSTART.md Step 10 pointing to PM-CHAT.md for the full rule.

Encapsulation: Two documentation additions only. No workflow, agent, skill, or
  script changes. Fully revertable.
Context: See design discussion April 2026.
Resolved: April 2026, v9.1 — commit 5847208.

---

**BD-042 — Move pack reference docs out of project root**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: METHODOLOGY.md, PROMPT-TEMPLATES.md, PM-CHAT.md, PLATFORM-SKILLS.md,
  PACK-FEEDBACK.md — all currently in project root
Description: The project root accumulates 15+ markdown files, mixing project
  state files the developer uses daily (BACKLOG, STATUS, CHANGELOG, ARCHITECTURE,
  IMPLEMENTATION-PLAN) with pack reference docs rarely touched after setup
  (METHODOLOGY, PROMPT-TEMPLATES, PM-CHAT, PLATFORM-SKILLS, PACK-FEEDBACK).
  Move the five pack reference docs to a subdirectory (e.g., `docs/` or
  `pack-docs/`) to reduce root clutter.

  Files that must stay in root: CLAUDE.md, AGENTS.md, GEMINI.md (tool convention),
  README.md (git convention), agent-run.sh (invoked as ./agent-run.sh).

  Blast radius is large: every cross-reference to these files in METHODOLOGY.md,
  PROMPT-TEMPLATES.md, PM-CHAT.md, QUICKSTART.md, CLAUDE.md template, AGENTS.md
  template, GEMINI.md template, pm-startup skill, CLI-PM-SETUP.md, MIGRATION
  guide, and SETUP_TEMPLATE.md must be updated. Every existing project needs the
  same migration. Scope as a major version change with its own migration step.

Context: Identified April 2026 during v9.1 work. Deferred to reduce risk —
  v9.1 is shipping BD-038 and BD-041; adding a file-move migration on top
  would increase the blast radius beyond what a minor version should carry.
Resolved: 2026-05-07, v11.0 — resolved via BD-091 verification audit. The
  relocation shipped incrementally across prior versions; v11.0 confirms
  end state and closes this long-standing item.

---

**BD-043 — Gemini CLI native subagent architecture and full doc audit**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `.gemini/agents/` (new directory, 16 agent files),
  `project-template/GEMINI.md` (strip inline role definitions),
  `project-template/agent-run.sh` (Gemini invocation redesign),
  `maintenance-docs/TOOL-COMPARISON.md`, `README.md`, `CHANGELOG.md`,
  and all files referencing Gemini agent architecture
Description: The pack currently defines all 16 Gemini agent roles inline in
  GEMINI.md and uses external orchestration via agent-run.sh for invocation.
  This is incorrect. Gemini CLI supports native subagents as individual `.md`
  files with YAML frontmatter (`name`, `description`, `tools`, `mcpServers`,
  `model`, `temperature`, `max_turns`, `timeout_mins`) stored in
  `.gemini/agents/` (project-level) or `~/.gemini/agents/` (global).
  Subagents are invoked via `@agent-name` syntax or automatic delegation —
  there is no `--agent` CLI flag. GEMINI.md is strictly a project context
  file (equivalent to CLAUDE.md), not an agent definition file.

  Scope — three workstreams:

  1. **Structural migration:** Create `.gemini/agents/` with 16 agent `.md`
     files using correct YAML frontmatter. Each file needs appropriate `tools`
     lists (read-only agents get restricted tool sets, not `*`), `model`
     selection, `temperature`, and `max_turns` values tuned per role. Strip
     all role definitions from GEMINI.md, leaving only project context.
     Redesign auditor orchestration: the auditor parent must run as the main
     session (not a subagent) to delegate to auditor-* subagents, since
     subagents cannot call other subagents. Update `agent-run.sh` Gemini
     invocation to use native subagent mechanisms.

  2. **Content audit:** Review every Gemini-related file in the pack for
     correctness against the official Gemini CLI documentation
     (https://geminicli.com/docs/). Verify directory structure, file format,
     invocation patterns, approval modes, skill loading, and MCP server
     configuration are all optimal for how Gemini CLI expects and uses them.

  3. **Documentation audit:** Exhaustive audit of ALL references to Gemini
     agents, invocation, subagents, GEMINI.md role sections, agent-run.sh
     Gemini behavior, and tool comparison entries across every file in the
     pack. This includes but is not limited to: TOOL-COMPARISON.md,
     METHODOLOGY.md, PROMPT-TEMPLATES.md, PM-CHAT.md, PLATFORM-SKILLS.md,
     PACK-AGENTS.md, QUICKSTART.md, CLI-PM-SETUP.md, MIGRATION guide,
     README.md, CHANGELOG.md, CLAUDE.md (pack), AGENTS.md (pack),
     GEMINI.md (pack), and all skill SKILL.md files that reference Gemini.

  This is v9.3.

Context: Identified April 2026 via Gemini web chat feedback. The pack's Gemini
  architecture was designed during v9 planning based on incomplete understanding
  of Gemini CLI's subagent capabilities. Official docs confirm `.gemini/agents/`
  with YAML frontmatter is the correct mechanism. See
  https://geminicli.com/docs/core/subagents/ ("Creating custom subagents" section).
Resolved: April 2026, v9.3 — 16 Gemini agent files in `.gemini/agents/`,
  GEMINI.md stripped to project context, agent-run.sh transparent translation,
  validate-pack.py three-tool parity, audit-methodology and TOOL-COMPARISON
  corrected, full doc audit across 11 files.

---

**BD-044 — Project setup paths: init-project.sh, QUICKSTART router, and existing-project onboarding**
Type: TODO(version)
Status: Resolved
Blockers: None (design approval pass completed 2026-04-21; V10-DESIGN.md approved)
Unblocks: None
File/Symbol: `QUICKSTART.md`, `scripts/init-project.sh` (new), `supporting-docs/SETUP-NEW.md` (new), `supporting-docs/SETUP-EXISTING.md` (new), `supporting-docs/SETUP_TEMPLATE.md`, `README.md`

Description: The pack has no supported path for adding it to a project already
  under development with no AI tooling. QUICKSTART.md assumes a new project
  started from scratch. This item introduces a general-purpose onboarding
  flow for both new and existing projects and restructures QUICKSTART.md as
  the single entry point for all setup scenarios.

  Target scenario: a project with no existing AI config and no existing PM docs,
  making file conflicts minimal. Full merging of existing AI config or PM docs
  is explicitly out of scope — the PM chat handles that after the pack is
  installed and working.

  **Step 1 — Planning (required before any implementation):**
  Produce a complete list of every file that needs to change and every task
  required to implement this item. Known touch points: `QUICKSTART.md`,
  `scripts/init-project.sh` (new), `supporting-docs/SETUP-NEW.md` (new),
  `supporting-docs/SETUP-EXISTING.md` (new), `supporting-docs/SETUP_TEMPLATE.md`
  (stale `cp -r` command and QUICKSTART.md step number references), `README.md`
  (layout section). Additional touch points must be identified by auditing every
  file in the pack that references QUICKSTART.md steps, the `cp -r` setup
  command, or the project creation procedure. No implementation begins until
  this list is complete and approved.

  **Step 2 — Implementation:**
  Execute all tasks from Step 1 in a logical sequence with approval gates.
  Key deliverables:

  - `scripts/init-project.sh`: single pack-level script handling both new and
    existing projects. Runs a detection pass first and reports what it found
    and what it will do — the developer confirms before any files are written.
    Detection covers: presence of source files and git history (new vs. existing);
    language/platform markers (`.swift`, `Package.swift`, `pyproject.toml`,
    `.kt`, etc.); existing AI config (`.claude/`, `.codex/`, `.gemini/`,
    `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — stop condition: report and require
    removal before proceeding). When a detected language or platform has no pack
    skill coverage, reports the gap; the generated PM chat prompt instructs the
    PM chat to log it to `PACK-FEEDBACK.md`.
    New project path: automates the `cp -r` and skill distribution steps.
    Existing project path: selective copy (add-don't-overwrite), `.gitignore`
    merge (append and deduplicate), skip `README.md` / `pyproject.toml` /
    `Package.swift` / any existing scripts. Script output explicitly tells the
    developer that their previous file structure is replaced by the pack's
    structure and that pack file names and locations are the standard going
    forward. At the end, outputs a one-time PM chat prompt for the developer
    to paste. The prompt includes an instruction to the developer to point the
    PM chat at any existing documentation (architecture notes, README, inline
    comments, etc.) before context file generation begins, so the PM chat can
    read them for context. No persistent onboarding skill is added to projects.

  - `QUICKSTART.md` restructured as a three-path router: new project →
    `SETUP-NEW.md`; existing project → `SETUP-EXISTING.md`; pack version
    upgrade → `MIGRATION-vN-to-vM.md` for the relevant version pair. One or
    two sentences per path. No procedural content.

  - `supporting-docs/SETUP-NEW.md`: current QUICKSTART.md procedural content
    updated to reference `init-project.sh` instead of the manual `cp -r` step.

  - `supporting-docs/SETUP-EXISTING.md`: existing-project procedure referencing
    `init-project.sh`, describing the preview-and-confirm flow, and describing
    the one-time PM chat onboarding step. Must clearly state that the old
    project file structure is gone and the pack's file names and locations are
    used from this point forward.

  - Migration guide convention: version-specific migration guides are always
    named `MIGRATION-vN-to-vM.md` and always land in `supporting-docs/`. This
    convention must be documented in `SETUP-NEW.md`, `SETUP-EXISTING.md`, or
    a central reference so it is followed consistently for all future major
    version upgrades.

  - All additional doc updates identified in Step 1.

  **Step 3 — Verification:**
  Manual testing against real repos covering all three paths:
  - New project: run `init-project.sh` against an empty directory; verify
    all template files land correctly, skills distribute, bootstrap runs.
  - Existing project: run against a real project with no AI config; verify
    preview output is accurate, selective copy and `.gitignore` merge are
    correct, no existing files are overwritten, developer transition message
    is present, PM chat prompt is generated and includes the existing-docs
    pointer instruction.
  - Pack version upgrade: follow `MIGRATION-vN-to-vM.md` end-to-end; verify
    no regressions in the migration procedure from the QUICKSTART.md restructure.
  Update `validate-pack.py` if new required pack files are introduced.
  Confirm `SETUP_TEMPLATE.md` still produces a correct project `SETUP.md`
  after its content is updated.

Context: Design discussion April 2026. The pack currently has no onboarding
  path for projects already under development. `init-project.sh` usage must
  be clearly documented — when to run it (once per project, from the pack
  directory), how it differs from `bootstrap.sh` (bootstrap runs inside a
  project repeatedly on each machine checkout; init-project.sh runs once from
  the pack to create or configure a project). Moved to v10 scope — migration
  automation overlaps with the v10 migration script (BD-046). See
  maintenance-docs/V10-PREDESIGN.md Candidate Decision 10.
Resolved: April 2026, v10.0 — release merge commit 6bd18b1. `scripts/init-project.sh` and `scripts/lib/detect.sh` shipped with three-class detection (new / existing-empty / existing-with-marker-conflict / existing-clean) and 10-stage preview-and-confirm flow; QUICKSTART.md rewritten as three-path router (NEW / EXISTING / MIGRATE); SETUP-NEW.md and SETUP-EXISTING.md added; SETUP_TEMPLATE.md rewritten; validate-pack.py Check 9 enforces init-project structure. See CHANGELOG v10.0.

---

**BD-045 — Champion the capabilities design pattern alongside LSP in architecture guidance**
Type: TODO(version)
Status: Resolved
Blockers: None (design approval pass completed 2026-04-21; V10-DESIGN.md approved;
  sequencing confirmed: BD-045 first in implementation order)
Unblocks: None
File/Symbol: `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `project-template/skills/apple-architecture-core/SKILL.md`, `project-template/skills/python-best-practices/SKILL.md`, `project-template/skills/architecture-review/SKILL.md`, `project-template/.claude/agents/auditor-architecture.md`, `project-template/.codex/agents/auditor-architecture.toml`, `project-template/.gemini/agents/auditor-architecture.md`

Description: The pack mentions capability checks only reactively, as the approved
  escape hatch for LSP compliance ("use capability flags or feature checks for
  all implementation differences"). It never defines the capabilities pattern,
  never explains why it works, and never champions it as a design tool to reach
  for during architecture. Agents reading the pack understand that capability
  flags are acceptable — not that they are a first-class architectural pattern
  worth designing for from the start.

  **What the capabilities pattern is:**
  The capabilities pattern makes what a type supports an explicit, queryable
  first-class concern — so callers can check support before invoking behavior,
  rather than discovering unsupported operations through exceptions or silent
  failures at runtime. It takes two complementary forms:

  - **Value-based capabilities:** A type exposes a value (bitmask, flag set,
    enum set, or similar) enumerating the operations it supports. A caller
    checks the capability value before invoking the corresponding operation.
    Capability validation happens at association or initialization time —
    incompatible pairings are rejected before they can produce runtime errors.
    No exceptions are thrown for unsupported operations because callers never
    invoke them without first confirming support.

  - **Interface-based capabilities:** A type declares conformance to a small,
    focused interface (protocol, trait, interface, abstract base class, or
    equivalent in the implementation language) only when it genuinely supports
    that behavior. Callers query for the interface before invoking. Types that
    don't support a behavior simply don't expose the interface — no silent
    no-ops, no unconditional throws. The language mechanism varies
    (compile-time or runtime conformance checks, duck typing, structural
    subtyping, etc.) but the intent is the same: make the capability
    discoverable without invoking it.

  Both forms share the same intent: make supported behaviors explicit and
  queryable, eliminating the need for callers to discover limitations through
  exceptions, silent failures, or branching on concrete types.

  **How capabilities and LSP relate:**
  LSP and the capabilities pattern are both required coding practices, applied
  independently. LSP is a correctness constraint on interface design — every
  method declared in an interface must have a meaningful implementation in
  every conforming type. The capabilities pattern is an architectural tool for
  making supported behaviors explicit and queryable. Neither is a prerequisite
  for the other, and neither is the motivation for the other.

  They work well together when both are present: a codebase that applies both
  avoids a wide class of runtime surprises — callers know what an abstraction
  supports before invoking it, and every declared interface method is
  meaningfully implemented. But this is a benefit of using both, not a
  dependency between them. Each stands on its own merits and is required
  regardless of whether the other is in use.

  **What to add — all nine locations:**

  1. **Trinity files (CLAUDE.md, AGENTS.md, GEMINI.md):** Add a "Capabilities
     pattern" section near the existing Liskov Substitution Principle section.
     Define both forms (value-based and interface-based) in language-agnostic
     terms. Explicitly state that capabilities and LSP are independent required
     practices that work well together. Add "Branching on concrete types to
     discover what an abstraction supports, instead of querying a capability
     value or interface" to the anti-patterns list. Update all three files in
     the same commit per the trinity rule. The pattern is not tool- or
     language-specific.

  2. **Language-specific skills (`apple-architecture-core`,
     `python-best-practices`, and any future language skills):** Each skill
     should express the capabilities pattern in language-appropriate terms —
     what the idiomatic value-based and interface-based forms look like in
     that language, and where capability validation belongs in that language's
     typical architecture. Implementation details (language mechanisms, naming
     conventions) are language-specific; the pattern's intent is not.

  3. **`architecture-review` skill:** Extend the LSP compliance rule to also
     flag: interface implementations that throw "not supported" for operations
     that could instead be gated by a capability check; caller code that
     branches on concrete types to discover what an abstraction supports; and
     absence of any capability mechanism in types that have variable supported
     operation sets across implementations.

  4. **`auditor-architecture` agent (all three tool versions):** Extend the
     "LSP compliance" audit bullet to also cover capability pattern adherence —
     specifically: concrete type interrogation that could be replaced by
     capability checks, and "not supported" throws or silent no-ops that
     indicate a missing capability gate.

Context: Identified April 2026 via OT project, which implements capability
  masks and interface-based capability checks as the sole sanctioned mechanism
  for handling implementation differences across broker, account, and quote
  service types. The pattern prevents both LSP violations and encapsulation
  violations and is documented in OT ARCHITECTURE.md §2h. The pack's current
  guidance leads agents to discover the pattern reactively (when fixing an LSP
  violation) rather than reaching for it proactively during design. The pattern
  is language-agnostic — the implementation mechanism varies by language but
  the design intent is consistent across all typed systems.
Resolved: April 2026, v10.0 — release merge commit 6bd18b1. Capabilities pattern section added to trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) covering both value-based and interface-based forms with explicit LSP-relationship guidance; parallel content added to `apple-architecture-core`, `python-architecture`, and `architecture-review` skills; `auditor-architecture` agent extended with capabilities-scope rules; `audit-methodology` SKILL rule 15 covers the extension. See CHANGELOG v10.0.

---

**BD-046 — v10: Custom agent/skill support and prompt template reorganization**
Type: TODO(version)
Status: Resolved
Blockers: None (design approval pass completed 2026-04-21; V10-DESIGN.md approved)
Unblocks: None
File/Symbol: maintenance-docs/V10-DESIGN.md — approved design record (supersedes V10-PREDESIGN.md)
Description: v10 addresses three problems in one major version. First:
  no structured mechanism exists for projects to add custom agents or
  skills — manual additions are invisible to the PM chat workflow and
  destroyed by pack upgrades. Second: PROMPT-TEMPLATES.md is a 765-line
  monolith with no per-agent organization and no home for custom agent
  prompts. Third: BD-044 (init-project.sh and QUICKSTART router) and
  BD-045 (capabilities pattern in architecture guidance) are folded into
  v10 because they touch the same files as the core v10 work and
  batching avoids multiple migration passes. Solution summary: x-
  prefixed custom files in existing tool directories, PM-chat-driven
  creation and registration workflow, per-agent prompt files in
  docs/pack/prompts/, automatic x- file preservation in migration
  scripts, and init-project.sh for new and existing project onboarding.
  Requires MIGRATION-v9-to-v10.md with automatable migration option.
  Migration baseline: latest v9.x only.
Context: Full design discussion captured in V10-PREDESIGN.md including
  candidate decisions, open questions, touch point inventory, and PM
  chat workflow outline. V10-PREDESIGN.md must be updated with approved
  design before any implementation begins. This item should not move
  to Unblocked until V10-PREDESIGN.md has been through a formal design
  approval pass and all Part 3 open questions are resolved.
Resolved: April 2026, v10.0 — release merge commit 6bd18b1. x-prefixed custom agent/skill mechanism shipped (validate-pack.py Check 8 enforces reserved x- prefix); PROMPT-TEMPLATES.md replaced with per-agent files in `project-template/docs/pack/prompts/` (10 files with `## Variant: <name>` sections; validate-pack.py Check 6 enforces format, Check 10 enforces triad compliance per BD-049); `scripts/migrate-v9-to-v10.sh` ships with 8-stage backup-by-default pipeline plus splice/merge helpers (`merge-platform-skills.py`, `merge-trinity.py`); MIGRATION-v9-to-v10.md guide added; METHODOLOGY § Procedure 5 (custom agent/skill workflow), § Procedure 5-R (prompt reconciliation), and § Procedure 6 (capability addition) added; `scripts/add-capability.sh` ships. See CHANGELOG v10.0.

---

**BD-047 — PM chat kickoff auto-discovery and install-check enhancement**
Type: TODO(version)
Status: Resolved
Blockers: None (can begin after Phase 3-AC completes; planner/architect pass
  is the first implementation step, not a backlog-level blocker). **v10.0 ship-blocker.**
Unblocks: None
File/Symbol: `project-template/docs/pack/prompts/pm-chat.md` (Variant: kickoff),
  `supporting-docs/SETUP-NEW.md` (Steps 5–6), `supporting-docs/SETUP-EXISTING.md`
  (Steps 5–6)

Description: Enhance `pm-chat.md` Variant: kickoff so the PM chat auto-discovers
  Xcode scheme / simulator values (via `xcodebuild -list` and
  `xcrun simctl list devices available`), detects missing brew tools
  (swift-format, buf, swift-protobuf, grpc-swift), prompts for `brew install`
  with developer approval, edits `scripts/validate.sh`, `scripts/test.sh`,
  `.claude/settings.json`, and `scripts/format.sh` with the resolved values,
  and handles Xcode companion files (machine-level `cp` with confirmation).

  **Shell-out-capability detection:** Adapt behavior to Bash-capable CLI
  surfaces (Claude Code CLI, Codex CLI, Gemini CLI, Claude Desktop with
  filesystem MCP / Desktop Commander) vs. Claude Web without Desktop Commander
  — the latter falls back to the manual instructions documented in current
  SETUP-NEW.md / SETUP-EXISTING.md Steps 5–6.

  **Documentation updates:** SETUP-NEW.md and SETUP-EXISTING.md Steps 5–6
  change to "PM chat handles this during kickoff" with a manual-alternative
  fallback section for non-Bash surfaces.

  **Principle:** Developer is the decision-maker, not a copy/paste executor.
  Every auto-discovered value and every install/edit action is confirmed
  before the PM chat writes or runs anything.

  **Phase 3-B scope outline (in v10 implementation sequence, between
  Phase 3-AC Gate E2 and Phase 4 Gate F):**
  1. Planner/architect pass designing auto-discovery flow, confirmation
     gates, and error handling for each branch (missing Xcode, missing
     brew, ambiguous scheme list, no simulators available, non-Bash surface).
  2. Enhance `docs/pack/prompts/pm-chat.md` Variant: kickoff with the
     auto-discovery + install-check segment.
  3. Update `SETUP-NEW.md` and `SETUP-EXISTING.md` Steps 5–6.
  4. Shell-out-capability detection logic with documented fallback path.

  Estimated 2–3 commits plus the Phase 3-B design doc.

Context: Current SETUP-NEW.md and SETUP-EXISTING.md describe manual
  copy/paste steps (Step 5 Xcode scheme vars; Step 6 brew installs; Step 6
  in SETUP-NEW for Xcode companion files) in surfaces where the PM chat has
  Bash capability and could automate the work behind confirmation gates.
  Identified 2026-04-24 as the v10 implementer reached Gate E; designated
  a v10.0 ship-blocker the same day. Lands as Phase 3-B between Phase 3-AC
  (Gate E2) and Phase 4 (Gate F).
Resolved: 2026-04-24 — Phase 3-B landed on v10-dev (commits 1c5116c, db416a0, 2a0c8d5; design/plan prep in 6d6ab6a). METHODOLOGY.md Procedure 7 hosts the K1/K2/K3 auto-discovery + Forms R/I/E/M; pm-chat.md Variant: kickoff slimmed with continuation pointer; SETUP-NEW.md § Manual fallback (5.A–5.D) + SETUP-EXISTING.md Step 5 rewrite provide the non-shell path.

---

**BD-048 — Capability-addition discovery + install-check symmetry with kickoff**
Type: TODO(version)
Status: Open
Blockers: None (BD-047 was the blocker; it is now Resolved)
Unblocks: None
File/Symbol: `scripts/add-capability.sh`; `supporting-docs/METHODOLOGY.md` Procedure 6

Description: `scripts/add-capability.sh` today only performs trinity-placeholder
  file plumbing; it does not propose `brew install grpcio-tools` / `uv add ...` /
  machine-level installs when the developer adds a new pack-supported dimension
  (platform, language, protocol). Mirror the BD-047 kickoff auto-discovery +
  install-check pattern at capability-addition time. Implementation options:
  either extend Procedure 6 with a kickoff-style Form R/I/E/M sub-procedure,
  or add a new Variant: capability-added-kickoff to
  `docs/pack/prompts/pm-chat.md` that the `add-capability.sh` A7 stage invokes.
Context: Identified during BD-047 Phase 3-B planning (2026-04). Drafted in
  V10-PHASE-3B-PLAN-v2.md Part 10. Deferred out of v10.0 scope per
  V10-PHASE-3B-DESIGN.md Part 14 / V10-PHASE-3B-PLAN.md Q14-5 — keeps v10.0
  ship-blocker surface focused on kickoff. Candidate for v10.1 or later.
Resolved: n/a

---

**BD-049 — Prompt template labeled-section convention + validate-pack.py Check 10**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: project-template/docs/pack/prompts/architect.md,
  project-template/docs/pack/prompts/auditor.md,
  project-template/docs/pack/prompts/coder.md,
  project-template/docs/pack/prompts/docs-researcher.md,
  project-template/docs/pack/prompts/planner.md,
  project-template/docs/pack/prompts/pm-chat.md,
  project-template/docs/pack/prompts/reviewer.md,
  project-template/docs/pack/prompts/tester.md,
  project-template/docs/pack/prompts/PROMPT-AUTHORING.md (DELETED in v10.0),
  supporting-docs/METHODOLOGY.md § Prompt Authoring Principles,
  scripts/validate-pack.py (Check 10 added; Check 6 reformulated),
  scripts/lib/detect.sh,
  scripts/test-detect.sh,
  scripts/init-project.sh,
  scripts/migrate-v9-to-v10.sh,
  README.md,
  project-template/docs/pack/PM-CHAT.md,
  supporting-docs/MIGRATION-v9-to-v10.md

Description: Phase 4 audit of v10.0 surfaced inconsistency between the pack's
  stated Prompt Authoring Principles in METHODOLOGY.md and the actual
  content of the ten prompt templates that ship. Only coder.md Variant:
  fix-cycle surfaced the labeled triad (Problem / Expected behavior /
  Success criteria); the other variants either buried the triad in prose
  or omitted it entirely. METHODOLOGY's existing "Exceptions — where
  prescriptive content is appropriate" subsection was murky enough to be
  read as licensing solutions in the prompt.

  This item lands the labeled-section convention across all 12 in-scope
  prompt template variants, replaces METHODOLOGY's § Prompt Authoring
  Principles with the architect's draft text (mandatory triad on every
  prompt, format-vs-solution distinction, file-based-reporting rule,
  canonical section order), DELETES PROMPT-AUTHORING.md (the directory-
  guidance file collapsed to a 16-line cross-reference per the planner
  spec, which the project lead then chose to delete entirely; the
  surviving directory-guidance content moved into METHODOLOGY.md as a
  new "About docs/pack/prompts/" subsection), updates 8 deletion-
  cascade dependents (validate-pack.py Check 6, detect.sh,
  test-detect.sh, init-project.sh, migrate-v9-to-v10.sh, README.md,
  PM-CHAT.md, MIGRATION-v9-to-v10.md), and adds a new validate-pack.py
  Check 10 that enforces triad presence on every in-scope variant.

  Per the resolved Q1b: the per-fix middle label in coder.md Variant:
  fix-cycle was renamed Expected behavior: → Goal: for label
  consistency with the prompt-level triad.

  Per the resolved Q2b: pm-chat.md Variant: kickoff (a context handoff,
  not an agent-task prompt) is the one exception to the convention; an
  inline **Convention exception:** callout marks it, and the new
  Check 10 identifies the exemption via that literal substring.

  Per the resolved Q4b: the multi-part phase header convention moved
  from PROMPT-AUTHORING.md into METHODOLOGY.md § Prompt Authoring
  Principles alongside the file-based-reporting subsection.

Context: Identified during Phase 4 audit (April 2026). The audit closed
  with C-V10-01 through C-V10-14 landed (v10-dev tip 459161b or
  descendant); this work landed before C-V10-15 final verification per
  architect design pass V10-PROMPT-STRUCTURE-DESIGN.md (committed
  aff447f) and planner pass V10-PROMPT-STRUCTURE-PLAN.md (committed
  aff447f). Implementation commit follows this Pack Chat work.
Resolved: April 2026, v10.0 — commit f81678f.

---

**BD-050 — Kickoff surface-declaration gate auto-inferable + kickoff prose hardcoded environmental assumptions (F-A)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.0,
  supporting-docs/METHODOLOGY.md § Procedure 7.6 (Preview rendering rule),
  supporting-docs/METHODOLOGY.md § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 (cross-references),
  project-template/docs/pack/prompts/pm-chat.md Variant: kickoff lines 42–58, 84,
  project-template/docs/pack/prompts/pm-chat.md Variant: generate-agent-kickoff line 276 (path piggyback)

Description: Two related sub-defects in the kickoff variant of pm-chat.md surfaced
  during Phase 4 verification. F-A.1: assistant proceeded past the surface-declaration
  gate without explicit reply when running on shell-capable surfaces (observed in
  §4.1 F1 + §4.7 M-OT; predicted on Codex/Gemini/Desktop Commander per §4.2
  docs-research). Same auto-inference pattern collapsed Form I + Form M into Form R
  results table. F-A.2: kickoff body declared "GitHub connector is connected" +
  "search project knowledge" as facts (false on plain Web with no Project + connector
  per §4.3 evidence).

  Resolution: F-A.1 direction β (semantic acceptance with one-message no-action exit
  ramp; sanctioned-by-inference) + Form I/M preview formalization in METHODOLOGY § 7.6.
  F-A.2 direction (b) always-discover (decouple project-context doc list from
  retrieval mechanism — same principle as F-G applied to kickoff prose). Plus
  piggyback F-D path-stale fixes on pm-chat.md lines 84 + 276.

  Behavioral re-test confirmed (V10-PHASE-4-VERIFICATION.md §14): assistant
  declared `shell` AND paused for explicit `yes` reply before Form R discovery;
  assistant read 4 project docs by filesystem (no GitHub-connector assertion);
  Form I idempotency note rendered inline in Form R results table per § 7.6 Preview.
Context: Identified during Phase 4 verification (April 2026). See
  maintenance-docs/V10-F-A-DESIGN.md and maintenance-docs/V10-F-A-PLAN.md for full
  design rationale and implementation plan. Cross-surface verification on Codex/
  Gemini/Desktop Commander deferred to BD-055/BD-056/BD-057/BD-058 (v10.1).
Resolved: April 2026, v10.0 — commits cc5d7d0 (design+plan) + 385dfe2 (10-edit
  patch including 4 METHODOLOGY edits + 6 pm-chat.md edits) + 92c2428 (§13 delta
  verification) + c1039cd (§14 post-ship behavioral re-test).

---

**BD-051 — METHODOLOGY canonical location at docs/pack/ + legacy cleanup (F-C + F-D, combined)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: scripts/init-project.sh (S6 stage + blast_radius_sweep PROMPT-TEMPLATES exclusion),
  scripts/migrate-v9-to-v10.sh (S5 stage),
  supporting-docs/MIGRATION-v9-to-v10.md (S5 row prose),
  project-template/README.md (cp example + directory-boundary prose),
  maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md (path-assertion alignment)

Description: Two related defects with one root cause and one fix. F-C: legacy
  docs/pack/METHODOLOGY.md not cleaned up by migrate-v9-to-v10.sh — projects
  with METHODOLOGY at docs/pack/ pre-migration ended up with both root and
  docs/pack/ copies. F-D: v10 design contradiction — trinity files (CLAUDE.md
  line 275, AGENTS.md line 198, GEMINI.md line 229) said canonical location is
  docs/pack/METHODOLOGY.md, but init-project.sh and migrate-v9-to-v10.sh installed
  to project root. M-OT post-migration assistant in §4.7 read the trinity, picked
  docs/pack/ as canonical, and recommended `git mv root → docs/pack/` — direct
  evidence of downstream-agent confusion from the contradiction.

  Resolution: V10-DESIGN.md prescribed docs/pack/ in three independent places
  (Part 7 §7.6 init S6, S5 migration spec, init banner); the scripts drifted
  off-spec without an overruling design decision. F-D fix restores implementation
  to V10-DESIGN.md spec: canonical METHODOLOGY.md location is docs/pack/
  METHODOLOGY.md. Migration script S5 handles all 4 pre-states (docs/pack only /
  root only / both / neither): backs up whichever is present, writes v10 content
  to docs/pack/, removes any stale root copy. F-C auto-resolved by same script
  edit. Init-project.sh warns on stale root for existing projects (does not
  delete — operator action expected); blast_radius_sweep grep extended with
  --exclude='METHODOLOGY.md' so legitimate Procedure 5-R PROMPT-TEMPLATES
  references in METHODOLOGY don't trip the post-S6 sweep.

  Delta verification (V10-PHASE-4-VERIFICATION.md §10) confirmed all 4
  pre-state cases produce correct post-state with backup contracts honored.
Context: F-D discovered during project-lead post-§4.8 inspection of OT clone
  (April 2026); F-C identified separately during §4.6 OT migration. Combined into
  single BD per architect rec (V10-F-D-DESIGN.md §6) — shared root cause and
  shared fix. See V10-F-D-DESIGN.md and V10-F-D-PLAN.md for full design and
  cascade rationale.
Resolved: April 2026, v10.0 — commits 1de2d23 (design+plan) + 603234e (5-file
  patch) + 55d1834 (blast_radius_sweep follow-on fix surfaced during §10.1
  harness) + 9ae09c8 (§10 delta verification).

---

**BD-052 — Migration leaves Pack version stale in STATUS.md (F-E)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 5-S (Task A),
  scripts/migrate-v9-to-v10.sh (S7 sentinel write),
  project-template/skills/pm-startup/SKILL.md (Step 0 trigger detection),
  supporting-docs/MIGRATION-v9-to-v10.md (Step 4 routing inventory)

Description: migrate-v9-to-v10.sh did not update project-internal "Pack version"
  markers that v9.3 user projects commonly carry (e.g., **AI Agent Config Pack**:
  v9 in docs/project/STATUS.md). Post-migration the project said it was still on
  v9 even though the pack content had been migrated to v10. The PM chat's
  /pm-startup correctly flagged this in OT (reported Pack version: v9 despite
  v10-migrated content). Real-world impact: developers reading STATUS.md
  post-migration get inconsistent signals about which pack version they're on.

  Resolution: combined with BD-053 (F-F) under one Procedure 5-S — Post-migration
  housekeeping. Triggered by sentinel `.pack-migration-backup/v9.3-to-v10.0/
  postrun-pending` written unconditionally by migrate-v9-to-v10.sh S7. Procedure
  5-S Task A scans STATUS.md priority list (docs/project/STATUS.md →
  docs/STATUS.md → STATUS.md, first-existing-wins) for case-insensitive lines
  containing both "AI Agent Config Pack" (or "Pack version") and a v9 token.
  Per match: PM chat proposes update to current pack version (read from
  docs/pack/METHODOLOGY.md first 5 lines, matching pm-startup Step 6).
  Developer approves / edits / skips per match.

  Behavioral re-test (V10-PHASE-4-VERIFICATION.md §14.4) confirmed: /pm-startup
  Step 0 detected POSTRUN-PENDING sentinel, routed to Procedure 5-S, Task A
  found 1 match (STATUS.md:113 v9 marker), proposed update, awaited authorization.
Context: Discovered during Phase 4 supplementary findings (post-§4.8 /pm-startup
  on OT clone, April 2026). See V10-F-E-F-F-DESIGN.md and V10-F-E-F-F-PLAN.md.
Resolved: April 2026, v10.0 — commits 9b8af6c (design+plan) + f266166 (4-file
  patch including Procedure 5-S body + S7 sentinel write + pm-startup Step 0 +
  MIGRATION doc routing) + 6d296f8 (§11 delta verification).

---

**BD-053 — Migration does not address unfilled trinity placeholders (F-F)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 5-S (Task B)

Description: A v9.3 user project may have left [PROJECT_NAME], [PLATFORM_TARGETS],
  [TRANSPORT], and Active-skills line placeholders unfilled in CLAUDE.md /
  AGENTS.md / GEMINI.md (this is the case in OT — placeholders never filled).
  Pre-migration migrate-v9-to-v10.sh S5 trinity splice/merge ran unconditionally
  but did not detect or surface unfilled placeholders. Post-migration projects
  could carry literal [PROJECT_NAME] text in their context files indefinitely;
  AI agents reading those files would get template-default identifiers.

  Resolution: Task B of Procedure 5-S (combined with BD-052/F-E under one
  procedure per architect rec — shared trigger, shared lifecycle, shared cleanup).
  Greps CLAUDE.md / AGENTS.md / GEMINI.md for whitelist placeholders
  ([PROJECT_NAME], [PLATFORM_TARGETS], [TRANSPORT], [PLATFORM_DEFAULTS],
  [PLATFORM_ARCHITECTURE], [LANGUAGE_RULES], [GRPC_RULES], [PLATFORM_SECURITY],
  [PLATFORM_TESTING], [PLATFORM_ANTIPATTERNS]) plus the literal Active-skills
  placeholder line. For project-identifier placeholders: standalone Q&A (NOT
  full Procedure 7 kickoff per OQ-F-F-1) — PM chat proposes values; developer
  approves; PM chat applies TRIO-byte-identical across all three trinity files.
  For section placeholders: references loaded skills' content. Active-skills
  line: simpler standalone Q&A reading docs/pack/PLATFORM-SKILLS.md.

  Behavioral re-test (V10-PHASE-4-VERIFICATION.md §14.4) confirmed: Task B
  found whitelist matches in OT trinity (TRIO-symmetric: [PROJECT_NAME] × 2,
  [PLATFORM_TARGETS] × 2, [TRANSPORT] × 1 per file); Active-skills correctly
  identified as already-populated (no Q&A needed); section placeholders
  correctly identified as already filled by skills (no matches). Standalone
  Q&A initiated for project identifiers.
Context: Discovered during Phase 4 supplementary findings (post-§4.8 /pm-startup
  on OT clone, April 2026). Same patch as BD-052.
Resolved: April 2026, v10.0 — same commits as BD-052 (combined Procedure 5-S
  patch in commit f266166).

---

**BD-054 — Solution leakage in PM-chat-generated prompts (F-G)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Prompt Authoring Principles (per-agent table + Format-vs-solutions: worked examples subsection),
  project-template/docs/pack/prompts/pm-chat.md Variant: generate-agent-kickoff lines 264–287,
  project-template/skills/swift-best-practices/SKILL.md (## Design choices section, entries 39–40)

Description: Phase 4 supplementary findings (Phase 28 + Phase 32 paraphrased
  coder-prompt walk-throughs against OT clone) revealed that the v10 prompt-
  template structure (BD-049 labeled-section convention) ships a strong scaffold,
  and the PM chat applies it well, but generated prompts cross from
  format/scope/constraints into solution territory in several documented cases.
  Examples observed: parameter-injection-for-testability (Phase 28); polling
  rate, timer-suspend lifecycle, snapshot-as-value-type architectural details,
  presentation rendering choices (Phase 32). METHODOLOGY § Prompt Authoring
  Principles touched the distinction but apparently not in a way the prompt-
  generating PM chat fully internalized. Self-consistency check found one
  template (pm-chat.md Variant: generate-agent-kickoff lines 264–287) violated
  the existing METHODOLOGY rule at line 687 ("A proposed solution in an
  architect prompt is not a suggestion — it anchors the agent.").

  Resolution: new "Format-vs-solutions: worked examples" subsection in METHODOLOGY
  § Prompt Authoring Principles (between "Format requirements vs. solutions" and
  "File-based reporting"). 5 phase-anonymous Negative/Positive/Why examples
  covering testability technique, API/framework name, architectural-shape
  invention, timing/lifecycle prescription, plus 1 clarifying example that
  Files-in-scope is NOT solution leakage (recurring point of confusion).
  Per-agent table extended with `pm-chat (self-prompt)` row clarifying that
  PM chat self-prompts inherit the solution-forbidden list of every agent it
  prompts. pm-chat.md Variant: generate-agent-kickoff cleanup: delete the three
  prescriptive Notes (LSP/type-erasure, AsyncStream<Void>, ViewModel-no-SwiftUI);
  replace with single pointer checklist item naming all three trinity files +
  active skills + cross-reference to new METHODOLOGY subsection. Substantive
  lessons preserved in swift-best-practices SKILL.md "## Design choices"
  section (entries 39 + 40 — AsyncStream payload-design trade-offs and
  type-erasure-vs-protocol-elevation, framed as patterns rather than
  prescriptions). Note 3 (ViewModel-no-SwiftUI-import) already in
  apple-architecture-core SKILL.md line 11; not duplicated.
Context: Identified during Phase 4 supplementary findings (April 2026). See
  V10-F-G-DESIGN.md and V10-F-G-PLAN.md. Per-agent table pm-chat row was OQ-F-G-2
  reversal (architect recommended v10.1 defer; project lead overrode to v10.0).
  Trinity-asymmetry on the type-erasure anti-pattern (CLAUDE.md line 395 has it;
  AGENTS.md/GEMINI.md don't) implicitly resolved by substantive lesson now living
  in swift-best-practices SKILL.md.
Resolved: April 2026, v10.0 — commits f9ebff2 (design+plan) + a7d3542 (3-file
  patch) + d7ff978 (§12 delta verification).

---

## Deferred

**BD-031 — Evaluate publishing pack skills to skills.sh**
Type: TODO(version)
Status: Deferred
Blockers: Skills must be stable through at least one real project audit cycle
  before publication
Unblocks: None
File/Symbol: n/a — external publication; no pack files change
Description: skills.sh (Vercel's cross-platform skill package manager,
  npx skills add) is becoming the standard install method for agent skills
  across Claude Code, Codex, and Gemini CLI. Publishing pack skills there
  would enable one-command installation for new projects. Evaluate feasibility,
  naming conventions, and versioning strategy for publishing the pack's Tier 1
  and Tier 2 skill libraries.
Context: Deferred until v9 skills are stable. See V9-DESIGN.md Decision 3.
Resolved: n/a

---

**BD-055 — Codex CLI: confirm surface-declaration gate behavior under workspace-write sandbox**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: None
File/Symbol: maintenance-docs/V10-PHASE-4-VERIFICATION.md §4.2 DR1 Codex CLI
  (deviation analysis); future maintenance-docs/V10-PHASE-4-VERIFICATION-v10.1.md
  for live-run capture
Description: §4.2 docs-research pass predicted that the F-A.1 auto-inference
  pattern would recur on Codex CLI (it's a prompt-shape issue, not model-specific).
  Codex CLI runs in a workspace-write sandbox by default. Live-run verification
  needed to confirm: (1) the new F-A.1 β semantic-gate behavior fires correctly
  (assistant declares surface AND pauses for reply); (2) Form R discovery commands
  execute correctly under workspace-write sandbox without escalation prompts;
  (3) the (b) discovery instruction works on Codex's filesystem access.
Context: Deferred to v10.1 per project-lead Reading A interpretation of "no v10.1
  defects": F-B (b) cross-surface live runs are scope decisions, not defects.
  Both `codex` and `gemini` are present on the implementer's PATH but were not
  exercised live for v10.0 per §1.3 silent-scope-expansion rule.
Resolved: n/a

---

**BD-056 — Codex CLI: document Form I `yes`-path sandbox escalation in METHODOLOGY § Procedure 7.3**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: BD-055
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.3 (Codex-specific
  sandbox-escalation paragraph to add)
Description: §4.2 DR1 docs-research identified that Form I default is `skip`,
  but if a developer replies `yes` on Codex CLI, `brew install` (Apple-side gRPC)
  or `uv add` (Python-side gRPC) would require explicit out-of-sandbox escalation
  due to Codex's workspace-write sandbox model. METHODOLOGY § Procedure 7.3
  doesn't currently document this. Fix: add a Codex-specific sandbox-escalation
  paragraph to Procedure 7.3 explaining the prompt the developer will see and
  how to handle it. Live verification under BD-055 should confirm the prompt
  shape before the documentation lands.
Context: Identified during V10-PHASE-4-VERIFICATION.md §4.2 DR1 deviation
  analysis (April 2026). Out of v10.0 scope per §0.6.
Resolved: n/a

---

**BD-057 — Gemini CLI: add plan-mode-detection check at start of Procedure 7 Form R**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.1 (pre-flight check
  to add); project-template/docs/pack/prompts/pm-chat.md kickoff variant line 26
  (existing developer-facing plan-mode warning may become obsolete)
Description: §4.2 DR2 docs-research identified that Gemini CLI's `/plan` mode
  blocks shell execution (TOOL-COMPARISON.md Part 4 line 121). pm-chat.md line 26
  has a developer-facing warning ("If you are running Gemini CLI and currently in
  plan mode, exit plan mode before continuing"), but Procedure 7 itself doesn't
  detect plan-mode programmatically. If a developer replies `shell` while in plan
  mode, Form R discovery will fail with confusing errors. Fix: add a pre-flight
  check at start of Procedure 7.1 (Form R) that, if surface is Gemini, attempts
  a no-op shell command first; if it fails with the plan-mode-blocked error,
  re-prompt the developer to exit plan mode and retry. Live verification needed
  to confirm exact error shape before METHODOLOGY documentation lands.
Context: Identified during V10-PHASE-4-VERIFICATION.md §4.2 DR2 deviation
  analysis (April 2026). Architect's F-A design (V10-F-A-DESIGN.md OQ-F-A-2)
  noted: "the kickoff Before-pasting preamble's Gemini plan-mode warning becomes
  unnecessary if v10.1 lands the plan-mode-detection candidate."
Resolved: n/a

---

**BD-058 — Desktop Commander: document MCP-scope check in pre-Form-M discovery**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.2.4 (pre-Form-M
  MCP-scope check paragraph to add)
Description: §4.2 DR3 docs-research identified that Desktop Commander writes
  via filesystem-MCP, which has an allowlist. Writing to ~/Library/Developer/
  Xcode/CodingAssistant/ (Form M target) requires the MCP's allowlist to include
  that path — most default MCP configs scope to project root only. METHODOLOGY
  § Procedure 7.2.4 Form M default `skip` is correct (machine-level write
  requires explicit allowlist), but doesn't document the MCP-scope check or
  failure-handling. Fix: add a pre-Form-M check that, if surface is Desktop
  Commander, confirms ~/Library/Developer/Xcode/CodingAssistant/ is in the
  filesystem-MCP allowlist; if not, skip Form M and report which path needs
  adding. Live verification needed (Desktop Commander not currently present on
  implementer's machine — would need separate setup for v10.1).
Context: Identified during V10-PHASE-4-VERIFICATION.md §4.2 DR3 deviation
  analysis (April 2026). Lower priority than BD-055/BD-056/BD-057 because
  Desktop Commander is the most surface-similar to Claude Code CLI of the three
  deferred surfaces, and Form M default `skip` already protects against the
  failure mode.
Resolved: n/a

---

**BD-151 — Tier 0 observability skill (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.1 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — extracting observability into a Tier 0 skill requires re-numbering rules in `ios-architecture`, `macos-architecture`, and `python-server-architecture` (which `auditor-architecture` cites by number), plus redrawing the `auditor-architecture` (infrastructure) vs `auditor-ops` (configuration) cluster boundary; the cost is non-trivial and best done with the v12 skill-catalog cleanup pass
Unblocks: a single Tier 0 home for "observability infrastructure" rules currently scattered as sub-bullets across `ios-architecture` (PLATFORM-SKILLS.md line 278), `macos-architecture` (line 279), `python-server-architecture` (line 282), with adjacent `auditor-ops` reading `deployment-apple` / `deployment-python` for "observability *configuration*" (line 224); two adjacent concerns split across four skills today
File/Symbol: NEW `project-template/.claude/skills/observability-architecture/SKILL.md` (and `.codex/skills/...` / `.gemini/skills/...` trinity copies, byte-identical); existing source skills carrying observability sub-bullets today: `ios-architecture/SKILL.md`, `macos-architecture/SKILL.md`, `python-server-architecture/SKILL.md` (rule extraction + re-numbering); `project-template/docs/pack/PLATFORM-SKILLS.md` Tier 0 section (add the new skill row); `auditor-architecture/SKILL.md` and `auditor-ops/SKILL.md` (cluster-boundary redefinition)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.1, `ios-architecture`, `macos-architecture`, and `python-server-architecture` each carry "observability infrastructure" as a sub-bullet (PLATFORM-SKILLS.md lines 278, 279, 282), while `auditor-ops` reads `deployment-apple` / `deployment-python` for "observability *configuration*" (line 224). Two adjacent concerns (infrastructure rules vs. config rules) are split across four skills. A dedicated Tier 0 `observability` skill would absorb the scattered sub-bullets. Absorption requires re-numbering rules in the existing platform skills (`auditor-architecture` cites by number) and redrawing the `auditor-architecture` (infrastructure) vs `auditor-ops` (config) cluster boundary. Defer until v12 per architecture §7.1 disposition.
Resolved: n/a

---

**BD-152 — Tier 0 accessibility skill (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.2 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — adding an accessibility skill before the non-Apple UI skills land (web-architecture, android-architecture, embedded-mcu-architecture; Phase 2A/2B/3 of skill-dimensions reframe) would force premature factoring; once those skills are in, the shared accessibility patterns become visible and the right factoring obvious
Unblocks: a Tier 0 home for the universal accessibility principles (semantic landmarks, focus order, screen reader announcements as design constraints) currently scattered across `apple-architecture-core`, `ios-architecture`, `macos-architecture`, and the proposed `web-architecture` / `android-architecture`; complements the cross-platform audit-methodology rule 20 extension (architecture-doc §6.3, BD-143)
File/Symbol: NEW `project-template/.claude/skills/accessibility-architecture/SKILL.md` (and `.codex/skills/...` / `.gemini/skills/...` trinity copies, byte-identical); existing source skills carrying accessibility rules today: `apple-architecture-core/SKILL.md`, `ios-architecture/SKILL.md`, `macos-architecture/SKILL.md`, future `web-architecture/SKILL.md` and `android-architecture/SKILL.md` (rule extraction + re-numbering); `project-template/docs/pack/PLATFORM-SKILLS.md` Tier 0 section (add the new skill row); `audit-methodology/SKILL.md` rule 20 (cross-link)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.2, accessibility rules live in `apple-architecture-core`, `ios-architecture`, `macos-architecture`, and the proposed `web-architecture` / `android-architecture`. The proposed cross-platform audit-methodology rule 20 extension (architecture-doc §6.3, BD-143) addresses the audit side. The skill side does not have a Tier 0 home for the universal principles. Defer to v12 per architecture §7.2 disposition: adding the skill before the non-Apple UI skills land would force premature factoring; once web + Android + embedded-MCU are in, the shared patterns will be visible and the right factoring obvious.
Resolved: n/a

---

**BD-153 — Tier 0 concurrency-architecture skill (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.3 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — same reorganization-cost rationale as BD-151 (observability) and BD-152 (accessibility); concurrency rules currently embedded in language-specific skills (`swift-best-practices` Swift 6 strict concurrency, `python-best-practices` asyncio, `apple-architecture-core` actor isolation) would need re-numbering to factor out
Unblocks: a single Tier 0 home for the universal concurrency principles (actor model, structured concurrency, cancellation propagation, backpressure); cleaner cross-language reasoning about concurrency patterns in audit-methodology and architecture review
File/Symbol: NEW `project-template/.claude/skills/concurrency-architecture/SKILL.md` (and `.codex/skills/...` / `.gemini/skills/...` trinity copies, byte-identical); existing source skills carrying concurrency rules today: `swift-best-practices/SKILL.md`, `python-best-practices/SKILL.md`, `apple-architecture-core/SKILL.md` (rule extraction + re-numbering); `project-template/docs/pack/PLATFORM-SKILLS.md` Tier 0 section (add the new skill row)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.3, concurrency rules are spread across `swift-best-practices` (Swift 6 strict concurrency), `python-best-practices` (asyncio), and `apple-architecture-core` (actor isolation). A Tier 0 `concurrency-architecture` skill would carry the universal principles (actor model, structured concurrency, cancellation propagation, backpressure). Same factoring risk as observability (BD-151) and accessibility (BD-152) — extracting the rules requires re-numbering the existing skills, which `auditor-architecture` cites by number, plus revising the audit-methodology cluster boundaries. Defer until v12 per architecture §7.3 disposition (note in BACKLOG as a known factoring opportunity).
Resolved: n/a

---

**BD-154 — Skill-versioning frontmatter convention (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.9 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — adding versioning frontmatter requires the v12 skill-catalog cleanup pass (BD-155) so the version-stamp design lands once across a stabilized name set, not twice
Unblocks: machine-readable skill-version detection (today the migrator's S5b advisory pattern catches renames but a content-only major revision of a SKILL.md has no signal); cross-version drift diagnostics; `pack tracker doctor`-style skill-revision reporting
File/Symbol: every `SKILL.md` under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` (frontmatter addition); `scripts/validate-pack.py` (new check enforcing version frontmatter presence and well-formedness); `scripts/lib/detect.sh` (loader of the skill version stamp); `supporting-docs/MIGRATION-vN-to-vM.md` template (cross-version skill-revision diff section)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.9, skills do not carry a version stamp in their frontmatter. When the Python split happened (Python `python-architecture` → `python-server-architecture` + `python-data-architecture`, IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md), a project on v10.x reading `python-architecture/SKILL.md` and a project on v11.0 reading `python-server-architecture/SKILL.md` had no machine-readable way to know which version of the skill ruleset they were on. The migrator's BD-035 / S5b advisory pattern catches the rename, but if a SKILL.md gets a content-only major revision (no name change), there is no signal. v12 design: add a `version: <semver>` frontmatter key to every SKILL.md (Tier 0 base + Tier 1 + Tier 2); validator enforces presence + monotonic-bump on content change; loader exposes the version to consumers (auditor agents, migrator advisory). Defer until v12 per architecture §7.9 disposition.
Resolved: n/a

---

**BD-155 — Naming-convention enforcement migration (deferred to v12)**
Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10 deferral disposition); recorded as part of BD-140 batch
Status: Deferred
Blockers: v12 — naming-convention codification (BD-149) lands in v11.0 as documentation-only ("Extending this file" prose); enforcement migration (rename existing skills to comply) is the v12 follow-on
Unblocks: full naming-convention compliance across the skill catalog (today the suffixes `*-best-practices`, `*-language`, `*-architecture`, `*-patterns` are all in active use without enforcement)
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" section (the convention codified by BD-149); skill directories under `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` (rename targets in v12); `scripts/lib/migrator-skills.sh` (BD-147 deliverable would be reused for v11→v12 client-side renames)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10 the skill catalog uses four suffixes inconsistently — `*-best-practices` (idiomatic-style rules), `*-language` (ownership/memory/interop), `*-architecture` (platform-specific structural rules), `*-patterns` (cross-cutting concerns). The convention is not enforced. BD-149 codifies the convention in PLATFORM-SKILLS.md "Extending this file" so new skills follow it; existing skills are NOT renamed in v11.0 because the cost of breaking external references outweighs the consistency benefit at this point. v12 enforcement migration: identify non-compliant existing skill names, rename them, run BD-147's `migrator_skill_rename` API across client projects, update all SKILL.md cross-references and trinity prose, ship a v11→v12 migrator stage analogous to BD-035 / S5b. Defer until v12 per architecture §7.10 disposition.
Resolved: n/a

*(Items move here when pushed to a future version beyond v9, with the target version noted)*
