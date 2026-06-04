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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md`. **Check 29** (`check_tracker_config`) added to scripts/validate-pack.py — uses `tomllib` to validate both `tracker.toml.pack-example` (root) and `project-template/tracker.toml.project-example` for: TOML parse correctness, `schema_version == 1` (int), allowed-set membership on `backend.name` / `mode.state` / `cli_acceleration.prefer`, presence + types of all `[mirror]` keys, per-surface `id_namespace.prefix` (BD pack / TD client), bool + non-empty-string typing on `[migration]` keys. Wired in `main()` after Check 28 in numerical order. New regression test `scripts/tests/tracker-config-schema-test.sh` 17/17 PASS (1 well-formed + 8 distinct failure modes). Validator now reports 30 numbered checks + 2 informational, all clean.

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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md`. **Check 30** (`check_recommendation_state_schema`) added to scripts/validate-pack.py — soft-passes when `.pack-tracker/recommendation-state.json` is absent (lazy-create design); otherwise validates JSON parse, all v1 schema fields per `recommendation_state_default()`, `schema_version == "v1"`, `surface ∈ {pack, client}`, `user_re_enable_count` non-negative-int (with explicit bool rejection). Wired in `main()` after Check 29 in numerical order. New regression test `scripts/tests/recommendation-state-schema-test.sh` 19/19 PASS (file-absent soft-pass + well-formed PASS + 8 distinct failure modes).

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
File/Symbol: `README.md`, `CHANGELOG.md`, git tags, `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` (final Pattern B sweep target)
Description: The release-cut commit. Pack maintainer rule: tag operations
  only after Pack Chat approval. Delete `v11` if present; recreate `v11.0`
  and `v11`; push. validate-pack must pass on the tagged commit;
  MIGRATION-v10-to-v11.md references reflect as-shipped state.
  **CHANGELOG audit-artifacts consolidation pass (carried from BD-150
  PACK-REVIEW §2.1 advisory nit, 2026-05-12):** the v11.0 Scope C
  audit-artifacts subsection (CHANGELOG lines 248-266 at BD-150 ship time)
  is wedged between "Carried over to future work" and the v10 H3 instead
  of consolidated with the other audit-artifacts blocks. Consolidate all
  v11.0 audit-artifacts blocks into one position at the v11.0-section tail
  (or another single canonical position) as part of the release-pin
  CHANGELOG polish. **Final Pattern B sweep:** move
  `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` and the
  BD-150 IMPL/REVIEW reports (and any other workflow artifacts that
  accumulated during the safe-window batches) to
  `maintenance-docs/archive/v11/` via `git mv` — BD-150's Pattern B sweep
  intentionally retained EXECUTION-PLAN and BD-150's own reports because
  they were still being referenced by the remaining safe-window batches.
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
Resolved: 2026-05-10 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-095.md`. Three new lib files: `scripts/lib/migrate-v10-to-v11/dry-run.sh` (216 lines), `apply.sh` (384 lines — fingerprint check + 24h freshness window per §6.G + bare-invocation auto-rerun for single-shot UX preservation), `resume.sh` (252 lines — sentinel-based forward-only with both `.resolved` flag-file AND extension-removal conflict-resolution signals per §6.H). `scripts/migrate-v10-to-v11.sh` adapter parses `--dry-run` / `--apply` / `--resume` flags and dispatches; bare invocation defaults to `--apply` and auto-runs `--dry-run` first if no fresh fingerprint, preserving backwards-compat single-shot UX. Stage sentinels written as `stage-S<N>.done` in the migrator's state directory. New regression test `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` 40/40 PASS. Existing test surface green: `test-migrate-v10-to-v11.sh` 39/39, `test-migrator-core.sh` 19/19, `test-migrator-manifest.sh` 12/12. Validator: 30 checks PASS. Scope-adjacent change: one-line dry-run gate in `migrator_post_dispatch_hook` (without it, dry-run would mutate the working tree because the BD-119 framework's dry-run plumbing only short-circuits framework stage helpers, not adapter post-dispatch hooks). Companion doc updates: `supporting-docs/MERGE-STRATEGY.md` §A1 (was-future → now-shipped + Class B `MIGRATOR_OWN_SIDECAR_SUFFIX` parameterization), `supporting-docs/MIGRATION-v10-to-v11.md` lines 75-76 (same), `BACKLOG.md` BD-101 description (replaced bare `*.merge-conflict` with parameterized form). 4 POQs surfaced — POQ-1 (doc lag) and POQ-2 (sidecar terminology) closed in this commit; POQ-3 (v9→v10 historical layout unverified per BD-121 deletion) and POQ-4 (bare-invocation auto-rerun on stale/drifted not just missing — strict superset of literal spec) accepted as-shipped per implementation report §11.

---

**BD-096 — Synthetic-fixture set (general-use coverage; OT is one example)**
Type: TODO(version)
Status: Resolved
Blockers: BD-088, BD-085
Unblocks: None
File/Symbol: `scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/`, `heavily-customized/`, `language-heterogeneous/`, `custom-agents-heavy/`, `v10-with-customization/`, `pack-retires-files/` (added during fix-cycle per F-5(a))
Description: 4 new synthetic fixtures + the OT-modeled fixture from BD-088
  (now one of five). Proves migrator handles distinct customization shapes;
  OT becomes one example among several (general-use). README explains each
  fixture; all 5 pass `test-customization-preserve.sh` end-to-end. Phase-task
  fixtures added by BD-106 extension.
Resolved: 2026-05-14 in commits 4a5a6e5 (impl) + db1ed87 (review fix-cycle) — Batch 16 single batch with 6 fixture directories total under `scripts/tests/fixtures/customization-preserve/` (5 originally specified + 6th `pack-retires-files/` added during F-5(a) fix-cycle to cover file-removal dispositions). `test-customization-preserve.sh` extended with Group 8 driver (data-driven; auto-discovers fixtures via `LC_ALL=C ls -d ... | sort`; supports negative-substring `!` assertions); BD-088 inline TSV cases (Groups 1–7) preserved byte-identical. Test count 79 → 233 (+154 new). Pack-reviewer end-of-batch review (`maintenance-docs/v11-implementation/REVIEW-BD-096.md`) found 1 BLOCKER (CI failure: 4 `.gemini/.env` fixture files git-ignored by `.gitignore:38`) + 4 SHOULD-FIX + 4 NIT — all 9 fixed in commit db1ed87 with narrow `.gitignore` exception (`!scripts/tests/fixtures/**/.env`) preserving security-relevant `.env` ignore everywhere else. validate-pack 35/35 PASS at both commits; CI green confirmed at db1ed87. Implementation report: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-096.md`.

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
File/Symbol: `maintenance-docs/v11-implementation/CHECKPOINT-{1,2,3}-REPORT.md`, `CHECKPOINT-PROMPT-TEMPLATE.md`. **Batch 21c retro carry-forwards** (verify in CP3 / final milestone audit; from PACK-REVIEW-BD-116-RETRO §5): (a) `scripts/validate-pack.py` Check 23 (`pack-internal: true` marker enforcement) recurses into `scripts/persona-contracts/` — BD-116 retro F5 added the markers but Check 23 currently only scans top-level `scripts/`; (b) `scripts/persona-contracts/contract-greenfield.sh` carries an inline note mapping its Assertion-N numbering to `init-project.sh stage_sN_*` source-stage numbering (currently mismatched cosmetically — Assertions 1-7 vs Stages S2/S4/S5/S6/S7/S8/S11); (c) `scripts/persona-contracts/contract-mid-dev.sh` carries an inline rationale comment explaining the deliberate absence of S6/S8/S11 mirror coverage (mid-dev verifies user-domain preservation only; greenfield owns install-verification surface — splitting prevents redundant assertion duplication).
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
File/Symbol: `scripts/lib/migrate-v10-to-v11/gate-{1,2,3}-*.sh`, `scripts/lib/migrate-v10-to-v11/checkpoint.sh`, `scripts/tests/test-migrate-v10-to-v11-gates.sh`
Description: 3 gates inside `migrate-v10-to-v11.sh` with explicit pass/fail.
  Gate 1: pre-migration dry-run (read-only; user reviews and approves).
  Gate 2: post-Phase-A (trinity addenda; HELP-FRAGMENT files; Source column;
  relocated docs; validate-pack). Gate 3: post-Phase-B (only if user opted
  into tracker; mapping integrity; mirror freshness; `pack tracker doctor`
  green). Failures route through A1 UX (sidecar files written with the
  per-migrator suffix `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}` — currently
  `*.v10-customized` for the v10→v11 migrator; `restore-from-backup.sh`
  if needed).
Resolved: 2026-05-11 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-101.md`. Four new lib files: `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (8 verification helpers + 1 mode-detect), `gate-1-dry-run-summary.sh`, `gate-2-phase-a-verify.sh`, `gate-3-phase-b-verify.sh`. Wired Gate 1 into `dry-run.sh`; Gate 2 + Gate 3 into both `apply.sh` (post-report wrapper) and `resume.sh` (tail). Added `EXIT_GATE_FAILED=31` to `scripts/lib/migrator-core.sh` (first slot above the stage-failure cap of 30) so gate failures are cleanly distinguishable from stage failures (20–30), preflight failures (10–16), and internal errors (99) — supports BD-095's `--resume` reconciliation. New regression test `scripts/tests/test-migrate-v10-to-v11-gates.sh` 38/38 PASS. All existing test surface green: test-migrate-v10-to-v11.sh 43/43 (per BD-139 extension), test-migrate-v10-to-v11-dry-run.sh 40/40, test-migrator-core.sh 19/19, test-migrator-manifest.sh 12/12. Validator: 30/30 PASS. No mode-bit regressions. Co-shipped with BD-139 (Batch 12 fix-follow) — both ran in parallel under separate pack-coder agents; both edits to `scripts/migrate-v10-to-v11.sh` coexist line-disjoint.

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
  release pin).

  Batch 23 ordering (per 2026-05-17 user-Pack Chat discussion): BD-102
  runs LAST in the live-GH test trio. BD-174 (scratch-pack-clone multi-toggle)
  runs FIRST as safe-env pack code validation; BD-171 (real-OT scratch-clone
  multi-toggle) runs SECOND as scratch-env client validation; BD-102 runs
  THIRD as the final ship-decision gate on the real pack repo, informed by
  all three test reports. Should "just work" because BD-174 + BD-171 caught
  earlier-stage issues in safer environments. If BD-102 surfaces NEW issues
  that BD-174/BD-171 missed, that's actionable feedback for hardening their
  test surfaces in v11.1+.
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
Resolved: 2026-05-10 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-104.md` (commits `ef20113` BD-104 sweep + `5e77939` mode-bit fix-up). 31 pack-shipped files updated; 2 fixture files renamed (git auto-detected via content similarity). Migrator `scripts/migrate-v10-to-v11.sh` gained Phase-A stage S4 (lines 141-181) handling all five edge cases: source-absent no-op; collision (both names exist) surfaces `migration-rename-collision` typed error per BD-070 / ARCHITECTURE.md §2.5 contract; tracked-source `git mv` history-preserving; untracked-source plain `mv` fallback; post-rename verification. 179 remaining `IMPLEMENTATION_PLAN` references audited and explicitly allowlisted as of commit `ef20113` (archives, MIGRATION-v8-to-v9.md, CHANGELOG, BACKLOG historical context, EXECUTION-PLAN, migrator script which references both names by necessity). Count is point-in-time at the rename commit; subsequent commits (BACKLOG entries, audit reports, fix-follow descriptions, migrator code/tests) necessarily quote the v10 form `IMPLEMENTATION_PLAN.md` by name and grow the count organically. Per BD-139 F-5 reconciliation: the AUDIT-BD-104.md count of 181 was 2 higher because of two BACKLOG additions in commits between `ef20113` and audit base `f1dc255` (the BD-104 status-flip entry and BD-137 description), both legitimate historical-context references. Validator: 30 checks PASS. Tests: 12 runners green. **KNOWN-TEMPORARY:** `scripts/test-migrator-behavior-preservation.sh` (BD-119 byte-equivalence harness) goes from 15-pass to 13-pass-2-fail because the new BD-104 stdout banner intentionally diverges from the pre-refactor monolith pinned at SHA `d7b3f07`. Harness header (PLAN §13.3) explicitly forbids redaction-based fixes. The BD-119 refactor that harness gated has shipped, so the harness itself is now obsolete. Fast-follow tracked as **BD-137** — retire the harness.

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
Status: Resolved
Blockers: BD-063, BD-064, BD-065, BD-067
Unblocks: BD-107, BD-108
File/Symbol: NEW `scripts/lib/tracker-phase-task.sh` (parser + emitter; coder may split into `tracker-phase-task-parser.sh` + `tracker-phase-task-emitter.sh` per the existing `tracker-migrate-forward.sh`/`tracker-migrate-reverse.sh` split convention — planner-deferred); EXTEND `scripts/lib/tracker-sidecar.sh` (`phase_tasks` block + per-task `dependency_edges` with `annotation` sub-field per V3.3 §6.R); EXTEND `scripts/lib/tracker-labels.sh` (`derived-from:` + `promoted-to:` label family; NOT `folded-into:` per Path-3 forbidden); EXTEND `scripts/lib/tracker-migrate-forward.sh` + `scripts/lib/tracker-migrate-reverse.sh` (id-map handling for phase tasks; `.pack-tracker/id-map.json` is runtime data, not new code); NEW `scripts/tests/test-tracker-phase-task.sh`. **(File/Symbol corrected 2026-05-14 from stale Python paths in non-existent `scripts/lib/pack-tracker/` subdirectory to bash convention per existing `scripts/lib/tracker-*.sh` files; `.pack-tracker/` is the client runtime data directory not a code subdirectory.)**
Description: Phase task as first-class L2 entity per V3.3 D-21. Identifier
  `phase-N.M` (lowercase, dash-separated; M is integer task number from .md).
  Parser reads `### Tasks` blocks under `## Phase N` headings; emitter
  reverses. Sidecar gains `phase_tasks` block + per-task `dependency_edges`
  with `annotation` sub-field per §6.R. Label family: `derived-from:` and
  `promoted-to:` only (NOT `folded-into:` per Path-3 forbidden).
Resolved: 2026-05-15 — Phase task as L2 entity per V3.3 D-21; identifier `phase-N.M`; single-file `scripts/lib/tracker-phase-task.sh` parser/emitter; sidecar `phase_tasks` block + per-task `dependency_edges` per V3.3 §6.R (architect-ratified MATCH 16/16 per ARCHITECTURE-V3.3-DELTA-ADDENDUM-1 §A.6); `derived-from:`/`promoted-to:` label registration (no `folded-into:`). Per-BD review-fix in deecb08 addressed F1-F13 (typed-error contract 7 sites; bash↔Python regex parity; validate-pack Check 32 — `check_tracker_phase_task_invariants`). End-of-batch fix (8ccf30d) added cycle-store population on initial forward migration (per V3.3 §5.5/§5.7). 90/90 tests; CI green. Batch 17 commit 1.

---

**BD-107 — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close)**
Type: TODO(version)
Status: Resolved
Blockers: BD-106, BD-108
Unblocks: None
File/Symbol: NEW `scripts/lib/tracker-promote.sh` (Path 1 + Path 2 + direct close orchestration; consumes BD-108's `tracker-links.sh` for Path 2's "new phase task + dependency edge" case per V3.3 §3); NEW `scripts/pack-td.sh` (verb dispatcher for the `pack td <verb>` namespace per existing `scripts/pack-<noun>.sh` convention; wires `pack td promote --to=phase-N` and `pack td promote --to=phase-N.M`; coder verifies whether the existing `pack td resolve` baseline — if any — should consolidate here); EXTEND `project-template/docs/pack/PM-CHAT.md` (PM Chat orchestration: invokes architect by default for Path 1 per V3.3 §6.P resolution; planner conditional on architect's call; threshold advice per V3.3 §7.1); EXTEND `supporting-docs/METHODOLOGY.md` § Part 7 lines 1057-1064 (TD resolution-path decision logic per V3.3 §3); EXTEND `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (or wherever the tracker help fragment lives — coder verifies; note `HELP-FRAGMENT.md` lines 20-21 already reference these verbs, so reconcile to avoid duplication); NEW 3 test scripts (e.g., `test-tracker-promote-path1.sh`, `test-tracker-promote-path2.sh`, `test-tracker-promote-direct.sh` — coder may consolidate into one combined runner per pack convention). **(File/Symbol corrected 2026-05-14 from stale Python `promote.py` and non-existent `scripts/lib/pack-tracker/` subdirectory to bash convention per existing `scripts/lib/tracker-*.sh` files. Second correction 2026-05-14: `EXTEND scripts/pack-tracker.sh` → `NEW scripts/pack-td.sh` since `pack-tracker.sh` dispatches the `pack tracker` namespace, not `pack td`; per existing one-script-per-noun convention. HELP-FRAGMENT reconciliation note added.)**
Description: PM Chat orchestration for `pack td promote --to=phase-N`
  (Path 1; new phase epic) and `pack td promote --to=phase-N.M` (Path 2;
  new phase task); direct close uses v10 lifecycle unchanged. Path 3
  forbidden. PM Chat invokes architect by default for Path 1 (per §6.P
  resolution); planner conditional on architect's call. Path 2 typically
  goes direct. PM Chat advises threshold per V3.3 §7.1; user can override.
Resolved: 2026-05-15 — TD promotion verb surface per V3.3 §3 D-22: Path 1 `pack td promote --to=phase-N` (new phase epic); Path 2 `pack td promote --to=phase-N.M` (new phase task; consumes BD-108's `tracker_links_create_blocked_by`); direct close via existing v10 lifecycle. Path 3 forbidden (5 grep invariants verified). PM Chat invokes architect by default for Path 1 per §6.P recommendation (a). NEW `scripts/pack-td.sh` dispatcher per `scripts/pack-<noun>.sh` convention. Per-BD impl + review-fix combined in 1a5944b addressed F1-F13 (dispatcher set-u guards on 4 value-bearing flags; Path 1 idempotency right-anchored regex; GH label pre-creation with partial-write surfacing; jq `--arg` discipline; failure-path tests). End-of-batch fix (8ccf30d) added `provider_update` Resolution-body sync and `tmf_mapping_save` id-map persistence. 159/159 BD-107 tests + 444 regressions; CI green. Batch 17 commit 3.

---

**BD-108 — Cross-entity dependency link orchestration + cycle check + gate-check extension**
Type: TODO(version)
Status: Resolved
Blockers: BD-106, BD-070
Unblocks: None
File/Symbol: NEW `scripts/lib/tracker-links.sh` (uniform cross-entity dependency model across 6 entity-pair types per V3.3 §5.1; uses V1 §5.3 reserved `link.kind = "blocks"/"blocked-by"` open-string family; no new provider operation; no new capability flag); NEW `scripts/lib/tracker-cycle-check.sh` (cycle check at link-creation time; K=10 default per V3.3 §6.Q; configurable via `tracker.toml [graph] cycle_check_k`); EXTEND `scripts/lib/tracker-migrate-forward.sh` + `scripts/lib/tracker-migrate-reverse.sh` (Dependencies bullet parser + Blockers grammar `phase-N.M` admission; flat-file ↔ tracker round-trip per V3.3 §5.2 / §5.3); EXTEND `supporting-docs/METHODOLOGY.md` § Part 4 line 263 (Dependencies bullet codification) + § Part 7 lines 990-993 (Blockers grammar `phase-N.M` admission) + 1025-1029 (gate-check extension); NEW 2 test scripts (`test-tracker-links.sh` + `test-tracker-cycle-check.sh`). **(File/Symbol corrected 2026-05-14 from stale Python paths in non-existent `scripts/lib/pack-tracker/` subdirectory to bash convention per existing `scripts/lib/tracker-*.sh` files.)**
Description: Uniform cross-entity dependency model across 6 entity-pair
  types (TD↔phase epic, TD↔phase task, phase task↔phase task same/cross-phase,
  TD↔TD, TD↔BD). Uses V1 §5.3 reserved `link.kind` open-string family; no
  new provider operation. Cycle check at link-creation time (K=10 default
  per §6.Q; configurable via `tracker.toml [graph] cycle_check_k`). Flat-file
  Blockers grammar gains `phase-N.M` (additive); Dependencies bullet grammar
  codified.
Resolved: 2026-05-15 — Uniform cross-entity dependency model (V3.3 §5.1, 6 pair types) via `tracker-links.sh` (uses V1 §5.3 `link.kind` open-string family; no new provider op; no new capability flag); cycle check K=10 default per §6.Q recommendation (a) configurable via `tracker.toml [graph] cycle_check_k`; flat-file Blockers grammar admits `phase-N.M` additive; Dependencies bullet codified per V3.3 §5.3. Per-BD review-fix in 430c637 addressed F1-F12 (CI workflow wire-up for BD-108 + BD-106 cross-cut tests; cycle-check self-loop verb consistency; `tracker_links_validate_pair_type` → `tracker_links_validate_id_shapes` rename; tracker.toml example documentation). End-of-batch fix (8ccf30d) added rc=2 cycle-vs-traversal disambiguation. 64/64 BD-108 tests (43 links + 21 cycle-check, +4 rc=2) + 270 migration regressions; CI green. Batch 17 commit 2. Note: V3.3 §5.5 spec wording on cycle traversal direction is logically inverted from the implementation (which is correct); pending PM-only V3.3-DELTA edit.

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
Status: Resolved
Blockers: Live GH repo access — pairs naturally with BD-088 or BD-093 integration
  test land-time, where introspection against the live GraphQL schema confirms
  the exact mutation name.
Unblocks: First-class blocker enumeration in `auditor-issue-tracking` (Check 28)
  without comment-body parsing.
File/Symbol: `scripts/lib/tracker-provider-gh.sh` —
  `tracker_provider_gh_link()` `blocks|blocked-by` case **+ `tracker_provider_gh_unlink()` `blocks|blocked-by` case (scope extended 2026-05-15, first extension)** + `_gh_classify_error` (FORBIDDEN pattern addition for EMU wire shape — added by BD-111 link work; called out for traceability per PACK-REVIEW-BD-111 F10);
  `scripts/tests/tracker-provider-test.sh` test 1.17 **+ test 1.20 unlink coverage (scope extended 2026-05-15, first extension)**;
  new fixtures under `scripts/tests/fixtures/tracker-provider/` (`gh-add-blocked-by.json` for link, `gh-remove-blocked-by.json` for unlink, **`gh-list-blocked-by.json` for reverse-decoder read query — scope extended 2026-05-15, second extension**);
  **`scripts/lib/tracker-migrate-reverse.sh` — `_tmr_decode_blockers` extended to query first-class `getBlockedBy` GraphQL edges in addition to body comment markers; `scripts/tests/tracker-migrate-reverse-test.sh` + `tracker-migrate-roundtrip-test.sh` extended to assert positive round-trip for post-BD-111 writes (scope extended 2026-05-15, second extension)**. **(Scope extended 2026-05-15, FIRST extension to include the symmetric `removeBlockedBy` unlink path. Original BACKLOG named only `tracker_provider_gh_link()`; the BD-111 coder's first pass surfaced the link/unlink asymmetry as a known limitation. Extending in-session is correct per pack rule "BDs are reserved for new scope / new feature / new architecture" — `removeBlockedBy` is the symmetric pair of `addBlockedBy`, not new architecture; same API surface, same files, same integration-test verification ask. Avoids artificial BD-split for one feature.)** **(Scope extended 2026-05-15, SECOND extension to include the reverse-decoder retrofit per PACK-REVIEW-BD-111 finding F1. The BD-111 forward-write swap to first-class `addBlockedBy` created a round-trip asymmetry: `tracker-migrate-reverse.sh:_tmr_decode_blockers` still reads only body comment markers, so post-BD-111 writes were silently invisible to reverse and `pack tracker disable` would lose Blockers fields — violating V1 §6.0 round-trip contract. The retrofit adds a `getBlockedBy` GraphQL query path to `_tmr_decode_blockers` that complements the existing body-marker reader (legacy markers continue to work). The BACKLOG title "Switch blocks/blocked-by from comment-marker to first-class GH dependency API" implied bidirectional completeness; closing the read half is symmetric completion of the feature, not new architecture. Different file than the link/unlink work but same feature surface; same integration-test verification ask. Per user direction "lean to v11.0, not v11.1" the round-trip gap closes in this batch rather than deferring to a follow-up BD.)**
Description: BD-060 ships `blocks`/`blocked-by` via comment markers (the
  documented V3 §28 fallback). GitHub issue dependencies went GA 2025-08-21
  (EXTERNAL-RESEARCH §1.3); the exact GraphQL mutation name was not pinned
  at BD-060 land-time and could not be verified offline. At BD-088 or BD-093
  land-time, run a GraphQL schema introspection against the live repo, swap
  the comment-based branch in `tracker_provider_gh_link()` for the actual
  mutation, add a fixture-driven test mirroring test 1.17, and remove the
  "GA 2025-08-21; mutation name verified at first live use" deferral note
  from the comment block above the function. Public `provider_link()` shape
  is unchanged. Comment-based markers remain available via `provider_raw()`
  for callers that explicitly want the V3 §28 fallback path.
Resolved: 2026-05-15 — Shipped across three commits: 0ec5eaf (link + unlink: `addBlockedBy` / `removeBlockedBy` GraphQL mutations in `tracker_provider_gh_link()` / `tracker_provider_gh_unlink()` for `blocks|blocked-by`; `_gh_classify_error` FORBIDDEN pattern for EMU wire shape; 8 fixture-driven test groups), 46c86fe (scope-extension doc for reverse-decoder retrofit), and this commit (F1 reverse-decoder retrofit: new `_tmr_fetch_first_class_blocked_by` helper queries `Issue.blockedByIssues` GraphQL via `provider_raw "POST" "graphql"`; `_tmr_decode_blockers` extended with first-class-edges arg; new Group 7 reverse-test suite; stateful fake-gh extended for `addBlockedBy` / `removeBlockedBy` / `blockedByIssues` / `api /repos/.../issues/N --jq .node_id` / `repo view --jq .nameWithOwner`; BD-002 Blockers + TD-040 Blockers narrative branches flipped to positive round-trip assertions; plus F2-F12 cleanup: EXTERNAL-RESEARCH §1.5→§1.3 cite fixes across 8 sites, stale doc-comments in `tracker-links.sh` + `tracker-migrate-forward-test.sh`, redundant assertion removal, IMPL-REPORT count corrections, escape-hatch comment rewrites). Public `provider_link()` / `provider_unlink()` shapes unchanged. Comment-based markers remain available via `provider_raw()` for callers that want the V3 §28 fallback path. Reverse decoder reads first-class edges first then body markers (de-dups; first-class wins by source order); legacy comment-marker writes continue to round-trip. V1 §6.0 round-trip safety contract restored for blocks/blocked-by. Tests: tracker-provider 98/98, tracker-migrate-reverse 113/113 (+18 Group 7), tracker-migrate-roundtrip 45/45, 19 other tracker tests zero regressions, validate-pack 32/32 PASS, `bash -n` syntax check on all 7 modified `.sh` files OK. Closes Batch 18.

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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-112.md`. NEW `_cp_flat_name()` helper in scripts/lib/customization-preserve.sh maps each rel to `<rel-with-/-replaced-by-__>__<sha1-6hex>`. Deterministic, collision-resistant (different paths produce both different sanitized prefixes AND different hash suffixes), human-readable for debugging, macOS bash 3.2 + BSD-utils compatible (`shasum -a 1`). Both call sites that previously used `${rel//\//-}` with leading-dot strip — `_cp_write_diff` (`.three-way.diff` artifacts) and `_cp_strategy_structured` (`.merge-warnings.log` artifacts) — now route through the helper. Note: the BACKLOG entry's secondary surface (`scripts/migrate-v9-to-v10.sh`) was deleted by BD-121 and required no fix. test-customization-preserve 79/79 (was 72; +7 BD-112 collision/determinism asserts in new Group 6c, including the exact `.claude/agents/foo.md` vs `claude/agents/foo.md` pair from the BACKLOG entry). test-migrator-behavior-preservation 15/15. test-migrate-v10-to-v11 39/39. Validator clean.

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
Resolved: 2026-05-09 — work shipped earlier; status flip in Batch 5 hygiene. See `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-114.md`.

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
Status: Resolved
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
Resolved: 2026-05-12 in commit 72789fc — 3 contracts under scripts/persona-contracts/ (greenfield 166/0, mid-dev 25/0, migration 30/0); aggregator scripts/test-persona-contracts.sh wired into CI; test-fixtures/build.sh extended with --for-contract flag (existing fixture SHAs unchanged); README Repository Layout updated; cross-reference comments added to S11 artifact lists pointing to scripts/init-project.sh:stage_s11_v11_artifacts(); contracts derive expected manifests from project-template/ + BD-088 invariants (zero hand-written file lists). Two POQs handled: POQ-BD-116-1 → BD-161 (migrator missing skill installs + UX wording bug); POQ-BD-116-2 → no action (inline-documented). validate-pack 31/31 PASS; reviewer APPROVE WITH NITS (both N1/N2 fixed in same commit).

---

**BD-117 — `RELEASE-GATE.md` per-major-version checklist**
Type: TODO(version)
Status: Resolved
Blockers: BD-114, BD-116
Unblocks: v11.0 tag; reused for every future major
File/Symbol: `maintenance-docs/v11-implementation/RELEASE-GATE.md` (new)
Description: Authoritative pre-tag checklist that must complete before
  any major version vN+1 is tagged: (1) per-version migrator
  `migrate-v<N>-to-v<N+1>.sh` written using the BD-119 framework;
  (2) BD-114 dry-run against real OT passes with expected diff shape;
  (3) all three BD-116 persona contracts pass; (4) BD-118 CI workflow
  green on the release commit; (5) `test-fixtures/build.sh --verify`
  passes against committed manifest. Single document; updated with
  each release if the gate evolves.
Resolved: 2026-05-12 in commit 6b2d5fc — maintenance-docs/v11-implementation/RELEASE-GATE.md (263 lines) with 5 enumerated gate items in BD-117 spec order, each with concrete commands + pass criteria + common-failure-mode tips; version-agnostic via <N>/<N+1> placeholders with v11.0 worked-example labels; §4 Maintenance locks the five-item count and delegates expansion to architect+planner per BD-159; cross-references to BD-093/BD-114/BD-115/BD-116/BD-118/BD-119 + EXECUTION-PLAN §7. Original placement at maintenance-docs/RELEASE-GATE.md (root) corrected to v11-implementation/ to satisfy BD-159 §3.2 condition 5 literal-enumeration; cross-references updated in BACKLOG, EXECUTION-PLAN-V11.0.md, IMPL-REPORT, PACK-REVIEW. validate-pack 31/31 PASS; reviewer APPROVE no code-fix nits.

---

**BD-118 — CI wiring for persona contracts + fixture verification**
Type: TODO(version)
Status: Resolved
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
Resolved: 2026-05-12 in commit b93d22b — NEW "fixture manifest verify (BD-115, RELEASE-GATE item 5)" step inserted between existing fixture-rebuild and persona-contracts steps, so manifest drift is caught before contracts run; persona-contracts step name suffixed "RELEASE-GATE item 3" for traceability; new 19-line header comment block maps RELEASE-GATE items → CI steps (items 3/4/5 in CI; items 1/2 explicitly NOT in CI per BD-117 spec); tag-along: stale "26 Checks" → "31 Checks" in 2 header strings; BD-114 real-OT dry-run intentionally NOT added (manual pre-tag per RELEASE-GATE item 2); YAML parses cleanly (29 steps in tests job); independent CI sequence simulation 5/5 + 5/5 + 3/3 PASS; validate-pack 31/31 PASS; reviewer APPROVE no nits no advisories.

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
Status: Resolved
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
Resolved: 2026-05-12 in commit 3fa3322 — _build_v10_realistic_ot() refactored into _build_realistic_for_version <vN> with v10/v11 case-dispatch; backwards-compat shim retained; dispatcher routes v10 unchanged through it; pattern mirrors BD-119's migrator_target_surface_for_version (single string arg, case dispatch, no global state); v10-realistic-ot byte-identical pre/post (HEAD/tree/ls-tree-sha256 all match); test-fixtures/README.md per-version pattern subsection added; manifest.txt regenerated; validate-pack 31/31 + test-detect 64/64 + test-migrator-core 19/19 + test-migrate-v10-to-v11 43/43 PASS; reviewer APPROVE 3 non-blocking nits.
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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-122.md`

---

**BD-172 — Extend Gate 2 (Phase A verify) to cover post-dispatch operations (BD-104 rename + BD-035 advisory + BD-144 advisory)**
Type: TODO(version) — surfaced 2026-05-15 from PACK-REVIEW-BD-101-RETRO.md MAJOR-2 (per-BD retro review revealed Gate 2 does not verify post-dispatch hook outputs; reviewer estimated 3 helpers + 9 test cases — too large for in-session fix at BD-101 retro time)
Status: Open
Blockers: BD-101 (the gate framework BD-172 extends — already Resolved)
Unblocks: Truthful Gate 2 PASS verdict for migrations that exercise the BD-104 rename, BD-035 python-architecture-rename advisory, or BD-144 capability-rename advisory paths; Batch 22 milestone audit (BD-100) and Batch 23 dog-food migration (BD-102) can rely on Gate 2 verdict actually meaning what it claims
File/Symbol:
  - `scripts/lib/migrate-v10-to-v11/checkpoint.sh` — three new verification helpers per the PACK-REVIEW-BD-101-RETRO MAJOR-2 spec, mirroring the existing 8 verification helpers' signature: (a) `_cp_verify_bd104_rename_outcome` (assert IMPLEMENTATION_PLAN→IMPLEMENTATION-PLAN rename completed for any tracked source paths; consumes the migrator's S4 stage sentinel + post-dispatch hook output); (b) `_cp_verify_bd035_python_arch_advisory` (assert advisory was printed if the python-architecture-rename path was applicable); (c) `_cp_verify_bd144_capability_advisory` (assert advisory was printed if the capability-rename path was applicable)
  - `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh` — wire the three new helpers into Gate 2's verify list; ensure each returns non-zero exit if its sub-stage outcome was incomplete or absent (so silent partial failures cause Gate 2 FAIL instead of stamping PASS)
  - `scripts/tests/test-migrate-v10-to-v11-gates.sh` — nine new test cases (3 helpers × 3 cases each: happy path with the sub-stage applied + verifier passes; sub-stage applicable but advisory missing → verifier fails loud; sub-stage failed silently mid-run → verifier catches via state-dir absence)
  - **Carry-forward from PACK-REVIEW-BD-101-RETRO MINOR-4 (POQ-1):** while editing `scripts/lib/migrate-v10-to-v11/{apply,resume}.sh` to wire the new Gate 2 helpers, also reorder the `_v10_to_v11_orig_post_report` invocation to run AFTER Gate 2/3 verdict (currently runs before, so the gate-failure banner is silenced by the "pack tracker init" success hint). ≤10 LOC change in each of `apply.sh` + `resume.sh`. Folded here per BD-101 retro fix coder's recommendation to avoid opening a separate small BD when BD-172 already plans to touch the same file surface.
Description: Per `PACK-REVIEW-BD-101-RETRO.md` MAJOR-2, BD-101's Gate 2 (Phase-A verify) currently checks the framework stage outputs but does not verify the three post-dispatch operations that run inside `migrator_post_dispatch_hook`: BD-104's `IMPLEMENTATION_PLAN`→`IMPLEMENTATION-PLAN` rename outcome; BD-035's python-architecture-rename advisory; BD-144's capability-rename advisory. A silent partial failure in any of those three sub-stages would ship with Gate 2 stamping PASS, so a user running `--apply` would get a green Gate 2 verdict despite an incomplete migration. Reviewer estimated this fix at 3 new helpers + 9 new test cases — too large for an in-session fix at BD-101 retro time, so BD-172 is opened explicitly per the deferred-work tracking rule. Lands in v11.0 to keep the Gate 2 contract truthful before Batch 22 (BD-100) milestone audit and Batch 23 (BD-102) dog-food migration. Implementation pattern mirrors the existing 8 verification helpers in `checkpoint.sh` (no new dependencies, no architecture change). Each new helper consults the migrator's state directory and the post-dispatch hook's output fingerprint to decide pass/fail.

  **Position:** Batch 21.5 — single-BD lightweight batch between Batch 21 (auditor agents) and Batch 22 (milestone audit). User-approved 2026-05-24. Position lands precisely where the BD entry's own guidance places it ("before Batch 22 milestone audit and Batch 23 dog-food migration") so Gate 2 PASS verdict is truthful when BD-100 audits and BD-102 dog-foods.
Resolved: n/a

---

**BD-175 — EMERGENCY: pack/project boundary audit + re-architecture (v11 pack-bias remediation)**
Type: TODO(version) — CODE RED, surfaced 2026-05-18 from PATH-C-CURATION walk-through; two confirmed pack-bias contamination instances (commits `240867d`, `aaa61b3`); true scope unknown (surface triage acknowledged incomplete)
Status: Resolved
Blockers: none on critical path; PAUSES BD-173 (Batch 19c) until Resolved
Unblocks: BD-173 (19c resumes after BD-175 Resolved); structural prevention against future pack-bias regressions; clean pack/project boundary architecture before public release
File/Symbol:
  - All v11 commits — Phase 1 audit determines full scope
  - Root-directory docs needing relocation (e.g., `PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`) — Phase 2 Architect B designs new pack-only directory homes
  - Project-side files contaminated with pack-bias references — Phase 2 Architect A re-litigates per finding
  - CI checks, agent prompts, reviewer protocol — Phase 2 Architect C designs structural prevention
  - Implementation work spans: pack-root trinity, project-template trinity, scripts/, supporting-docs/, project-template/.claude/agents/, PACK-CHAT.md, PACK-AGENTS.md, agent prompt files, CI workflow files (final scope per Architect B + planner)
Description: Multiple v11 commits introduced pack-design bias into project-
  side files. Two instances confirmed (commit `240867d` added PACK-AGENTS.md
  reference to project-template trinity bypassing PM-CHAT.md SSOT; commit
  `aaa61b3` modified `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`
  during the pack-only Batch 19b in violation of stated guiding principle).
  Surface triage incomplete; true scope unknown. Additionally, no formal
  pack/project file+directory classification exists; shared files/
  directories is an anti-pattern requiring re-architecture; root directory
  holds pack docs needing new pack-only directory homes; path references
  need lockstep updating.

  Six problems (P1-P6), seven goals (G1-G7 with G2 expanded for directory
  architecture and G7 adding stated boundary definition), eight success
  criteria (SC1-SC8) — full text in
  `maintenance-docs/archive/v11/ORCHESTRATION-PLAN-BD-175.md`.

  Orchestration (7 phases): (1) discovery via docs-researcher audit;
  (2) three SEPARATE architects per blast-radius concern (re-litigation /
  directory architecture / structural prevention); (3) independent
  reviewer; (4) planner resolves ambiguities; (5) per-task coder spawns;
  (6) verification; (7) close + 19c resume decision.

  Different-agents-per-blast-radius rule honored across orchestration per
  pack memory + user direction.
Resolved: 2026-05-21

---

**BD-176 — Expand RC9 manifest-regen trigger to cover all fixture-affecting surfaces (pack-ops/ + supporting-docs/install-to-client files)**
Type: TODO(version) — surfaced 2026-05-19 during BD-175 Phase 5 Commit 2 fix triage (pack-ops/ defensive); SCOPE EXPANDED 2026-05-19 during BD-175 Phase 5 Commit 8 CI failure (supporting-docs/install-to-client empirical false-negative). User-explicit defer to immediately-after-BD-175.
Status: Resolved
Blockers: BD-175 (must close successfully first per user direction 2026-05-19)
Unblocks:
  (a) defensive future-proofing of RC9 manifest-regen rule for any future pack-ops/ additions that may affect fixtures
  (b) close the CONFIRMED FALSE-NEGATIVE in RC9 for supporting-docs/ files that get installed to clients via `scripts/init-project.sh` (e.g., `supporting-docs/METHODOLOGY.md` — installed to client `<repo>/docs/pack/METHODOLOGY.md` at L565-570 of init-project.sh; its content IS captured in v11-* fixture SHAs but supporting-docs/ is NOT triggered by current RC9 strict rule)
File/Symbol:
  - `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack root) "Pack memory" § "Repo conventions" RC9 bullet — trinity rule applies
  - `~/.claude/projects/<slug>/memory/feedback_manifest_regen_on_v11_surface.md` (user memory cache update)
  - Possibly `scripts/init-project.sh` (consider adding a self-documenting list of "files copied to clients" for RC9's reference, OR keep RC9 as inclusive directory-trigger model)
Description: When RC9 was created, only `project-template/` and `scripts/` were directories whose content affected fixture SHAs. Two new false-negatives have surfaced:

  **(a) pack-ops/ (defensive, currently empirical zero-impact):** BD-175 introduced `pack-ops/` as a new top-level pack-side directory hosting LIVE OPS docs (PACK-CHAT, PACK-AGENTS, BACKLOG, CHANGELOG, HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, BOUNDARY-DEFINITION, plus future additions). Empirical state 2026-05-19: pack-ops/ files do NOT currently affect manifest (test-fixtures/build.sh doesn't read pack-ops/ directly; init-project.sh doesn't copy pack-ops/ to clients; byte-identity contract Check 24 enforced separately). Defensive change adds pack-ops/ to RC9 trigger to defend against future commits that may capture pack-ops/ content in fixtures.

  **(b) supporting-docs/ files that install to clients (CONFIRMED FALSE-NEGATIVE — CI failure 2026-05-19):** `scripts/init-project.sh:565-570` copies `supporting-docs/METHODOLOGY.md` to client `<repo>/docs/pack/METHODOLOGY.md` during install. So when `test-fixtures/build.sh` invokes `init-project.sh` to build v11-* fixture artifacts, METHODOLOGY.md's content IS captured in fixture SHAs. BD-175 Phase 5 Commit 8 (`4120d19`) modified METHODOLOGY.md without manifest regen per current RC9 strict rule; CI `fixture manifest verify` step FAILED on the push; recovery commit `6c48f88` had to land as a separate `fix:` commit to restore the manifest. This is the first empirical confirmation of the supporting-docs/ false-negative class.

  Note: not ALL supporting-docs/ files install to clients. Per audit, init-project.sh copies METHODOLOGY.md and INSTALL-PROCEDURES.md (and possibly a small list of others) to client `docs/pack/`. MIGRATION-v10-to-v11.md does NOT install (it's a pre-install reference). The RC9 expansion needs to address the install-to-client subset, not all of supporting-docs/.

  Defensive design philosophy per current RC9: "false positives cost ~30-90s of unnecessary rebuild but produce no incorrect manifest change; false negatives within v11-surface are impossible." Adding both pack-ops/ and supporting-docs/install-to-client extends "within v11-surface" appropriately.

  Scope:
  - Trinity edit in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` "Pack memory" § "Repo conventions" RC9 bullet — update "v11-surface = files under `project-template/` or `scripts/`" to include `pack-ops/` AND a supporting-docs/install-to-client trigger. Architect decides whether to enumerate the install-to-client files explicitly or to broaden RC9's trigger to "any supporting-docs/ file" (false-positive trade-off acceptable per RC9's inclusive design).
  - Update RC9's narrative explanation to enumerate the new triggers and cite the 2026-05-19 BD-175 Phase 5 Commit 8 CI failure as the precedent
  - Update memory cache file `feedback_manifest_regen_on_v11_surface.md` to match
  - Optionally: add a code-level safety check (e.g., `scripts/init-project.sh` audit that prints the list of supporting-docs/ files it installs, used by RC9 as authoritative source). Architect's call.

  Implementation pattern: pack-architect spawn (per pack-memory pack-architect-spawn protocol for rules/operating-docs/memory/trinity-Pack-memory-section changes) → strategy doc → pack-coder applies mechanically → Pack Chat commits.

  Position: Insert immediately after BD-175 (per user direction 2026-05-19). Implement immediately after BD-175 Resolved.
Resolved: 2026-05-21

---

**BD-177 — Coordinate scripts/pack-help.sh:86 sentinel-regex with pack-ops/HELP-FRAGMENT-PACK.md:37 prose post-BD-175 Commit 2 relocation**
Type: TODO(version) — surfaced 2026-05-19 during BD-175 Phase 5 Commit 2 fix-pass execution (PACK-REVIEW-BD-175-COMMIT-2.md D-4 sublocation L37 + IMPLEMENTATION-REPORT-BD-175-COMMIT-2-FIX.md §8 OQ-FIX-1); user-explicit defer to immediately-after-BD-176.
Status: Resolved
Blockers: BD-175 + BD-176 (must close successfully in that order per user direction 2026-05-19)
Unblocks: path-accurate prose at HELP-FRAGMENT-PACK.md L37; closes OQ-FIX-1 anchor in Commit 2 fix-pass IMPL-REPORT
File/Symbol:
  - `scripts/pack-help.sh` line 86 awk regex (currently matches sentinel `/^\[Included from \`HELP-FRAGMENT-TRACKER\.md\`/`)
  - `pack-ops/HELP-FRAGMENT-PACK.md` line 37 sentinel prose (currently says "at pack root" — stale post-Commit-2)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `scripts/pack-help.sh` is v11-surface)
Description: BD-175 Commit 2 relocated `HELP-FRAGMENT-TRACKER.md` from pack root to `pack-ops/`. Commit 2 fix-pass identified `pack-ops/HELP-FRAGMENT-PACK.md` L37 as stale prose ("at pack root"). Naive D-4 fix attempted but reverted when `scripts/tests/pack-help-test.sh` test 2.1 ("colloquial mapping inlined") FAILED — the L37 string is a load-bearing sentinel matched by `scripts/pack-help.sh:86` awk regex; changing prose without coordinating regex breaks tracker-fragment substitution.

  User-impact severity: ZERO (sentinel substituted out at render time; never user-visible in `pack help` output).

  Coordinated 2-file fix:
  1. Update `pack-ops/HELP-FRAGMENT-PACK.md` L37 sentinel to path-accurate form (e.g., `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` via \`pack-help.sh\`.]`)
  2. Update `scripts/pack-help.sh:86` awk regex to match the new sentinel form
  3. Re-run `scripts/tests/pack-help-test.sh` — verify substitution still fires (test 2.1)
  4. Regenerate `test-fixtures/manifest.txt` per RC9 (`scripts/pack-help.sh` is v11-surface)

  ~3-line, ~10-minute mechanical change once correctly scoped. No architect spawn needed (mechanical pack-coder work).

  Position: Insert immediately after BD-176 (per user direction 2026-05-19 — both small follow-ups to BD-175, but BD-177 MUST be implemented directly after BD-176 is resolved).
Resolved: 2026-05-21

---

**BD-178 — Align pre-existing trinity asymmetries in `project-template/{CLAUDE,AGENTS,GEMINI}.md`**
Type: TODO(version) — surfaced 2026-05-19 during BD-175 Phase 5 Commit 4 review (PACK-REVIEW-BD-175-COMMIT-4.md "pre-existing trinity asymmetry" finding); per Architect A §2 V1, pre-existing trinity wording variation was explicitly anticipated and triaged out of BD-175 scope; user-directed to address as a small follow-up BD before Batch 19c resumes.
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 (must close successfully in that order per user direction 2026-05-19)
Unblocks: clean trinity baseline for Batch 19c (BD-173 project-side cleanup) — Batch 19c work touches the project-template trinity files extensively and benefits from starting on a fully-symmetric baseline; closes the "pre-existing asymmetry" finding from PACK-REVIEW-BD-175-COMMIT-4.md.
File/Symbol:
  - `project-template/CLAUDE.md` (3 known asymmetric loci: Trinity rule bullet ~L354-357, "No destructive operations" bullet ~L358-361, phase-routing intro line ~L372)
  - `project-template/AGENTS.md` (matching loci: Trinity rule bullet ~L332-334, "No destructive operations" bullet ~L335-338, phase-routing intro line ~L349)
  - `project-template/GEMINI.md` (matching loci: Trinity rule bullet ~L347-349, "No destructive operations" bullet ~L350-353, phase-routing intro line ~L364)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `project-template/` is v11-surface)
Description: BD-175 Phase 5 Commit 4 reviewer flagged that bullets in `project-template/{CLAUDE,AGENTS,GEMINI}.md` carry pre-existing asymmetric wording that predates BD-175 (since `991d9e3`, v10.1 era). Architect A §2 V1 explicitly anticipated this pattern, so the asymmetries were triaged out of BD-175 Commit 4's scope. User direction 2026-05-19 opens BD-178 to address them as a small follow-up before Batch 19c (BD-173) resumes — Batch 19c touches the project-template trinity extensively and benefits from a fully-symmetric baseline.

  Implementation should run a FRESH full trinity-asymmetry sweep (e.g., 3-way diff on `project-template/{CLAUDE,AGENTS,GEMINI}.md` for every shared section) rather than fixing only the 3 loci identified below — pre-existing asymmetries beyond the known 3 may exist and should be captured in the same sweep.

  **Known asymmetric loci (from initial scoping sweep) and proposed canonical wording:**

  **(1) "No destructive operations" bullet** — currently asymmetric between GEMINI.md and CLAUDE.md/AGENTS.md:
    - **CLAUDE.md + AGENTS.md (current):** "Before any `git rm`, `rm -rf`, file deletion, overwrite, or `git reset --hard`, state exactly what will be destroyed and wait for explicit approval — even when the overall task is approved."
    - **GEMINI.md (current):** "Before any `git rm`, `rm -rf`, deletion, overwrite, or `git reset --hard`, state what will be destroyed and wait for explicit approval — even when the overall task is approved."
    - **Differences:** GEMINI drops "file " from "file deletion"; GEMINI drops "exactly" from "state exactly what will be destroyed".
    - **Proposed canonical wording (adopt CLAUDE.md/AGENTS.md form into GEMINI.md):** "Before any `git rm`, `rm -rf`, file deletion, overwrite, or `git reset --hard`, state exactly what will be destroyed and wait for explicit approval — even when the overall task is approved."
    - **Reasoning:** CLAUDE/AGENTS form is more precise. "file deletion" is more specific than bare "deletion" (which could ambiguously refer to database rows, log lines, branches, etc.); "state exactly what will be destroyed" is more enforceable than "state what will be destroyed" (the word "exactly" signals that vague paraphrases like "I'll clean up" are not acceptable). Adopting the CLAUDE/AGENTS form into GEMINI keeps the higher-precision wording.

  **(2) Phase-routing intro (tool-list line)** — currently asymmetric between AGENTS.md and CLAUDE.md/GEMINI.md:
    - **CLAUDE.md + GEMINI.md (current):** "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase."
    - **AGENTS.md (current):** "Both Codex and Claude Code can execute any engineering phase in this repo."
    - **Differences:** AGENTS uses "Both" (two-tool framing — pre-Gemini era) and excludes Gemini CLI from the list; AGENTS uses "any engineering phase in this repo" vs CLAUDE/GEMINI's shorter "any phase".
    - **Proposed canonical wording (adopt CLAUDE.md/GEMINI.md form into AGENTS.md):** "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase."
    - **Reasoning:** CLAUDE/GEMINI form correctly reflects the current three-tool trinity (Claude Code, Codex CLI, Gemini CLI). AGENTS.md's "Both" framing is a stale relic of the two-tool era predating Gemini CLI's addition — leaving it in place is a correctness defect, not a style preference. The shorter "any phase" is also cleaner than "any engineering phase in this repo" (no information loss — context is already established by the section heading "Phase routing — default agent assignments"). Adopting the CLAUDE/GEMINI form into AGENTS updates the tool count and trims redundant words.

  **(3) Trinity rule bullet** — currently asymmetric between GEMINI.md and CLAUDE.md/AGENTS.md (newly identified during BD-178 scoping sweep, not flagged in PACK-REVIEW-BD-175-COMMIT-4.md but caught by the broader sweep this BD authorizes):
    - **CLAUDE.md + AGENTS.md (current):** "When modifying `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` at the project root, the same change applies to all three in the same set of edits. Symmetry is the default; asymmetry requires justification as provably tool-specific."
    - **GEMINI.md (current):** "When modifying `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` at the project root, the same change applies to all three. Asymmetry requires justification as provably tool-specific."
    - **Differences:** GEMINI drops "in the same set of edits" (the operational constraint); GEMINI drops "Symmetry is the default;" (the framing principle).
    - **Proposed canonical wording (adopt CLAUDE.md/AGENTS.md form into GEMINI.md):** "When modifying `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` at the project root, the same change applies to all three in the same set of edits. Symmetry is the default; asymmetry requires justification as provably tool-specific."
    - **Reasoning:** CLAUDE/AGENTS form is more enforceable. "in the same set of edits" is the load-bearing operational constraint that prevents trinity drift across commits — without it, an agent could legitimately edit one trinity file in commit A and the other two in commit B, leaving an interim state where the trinity is inconsistent. "Symmetry is the default" establishes the framing principle (the burden of proof is on the asymmetry, not on the symmetry); dropping it inverts the default. GEMINI's shorter form loses both load-bearing elements. Adopting the CLAUDE/AGENTS form into GEMINI restores the operational rigor.

  **General canonicalization heuristic for any additional asymmetries found in the fresh sweep:** prefer the wording variant that (a) is more enforceable / less ambiguous, (b) preserves operational constraints (the "in the same set of edits" pattern above), (c) reflects current state (e.g., three-tool trinity vs two-tool framing). If two variants are equally valid (wording-only stylistic differences with no precision delta), prefer the CLAUDE.md form for consistency with the pack-repo's existing "CLAUDE-first" convention (CLAUDE.md is typically edited first in trinity commits; AGENTS.md and GEMINI.md mirror).

  **POQ-F4-3 absorbed scope (2026-05-19 — per F4-bundle review SHOULD-2 user-approved absorb):** in addition to the asymmetric-loci alignment work above, this BD also absorbs the editorial trinity note about Tier 0 base loading that PACK-REVIEW-BD-175-F4-BUNDLE.md SHOULD-2 deferred. Add a brief informational note (1-2 sentences) in `project-template/{CLAUDE,AGENTS,GEMINI}.md` § "Skill loading" (or equivalent section header — coder picks the natural placement based on each file's existing section topology) explaining the Tier 0 base-loading concept: skills at `project-template/skills/` are auto-distributed to all 3 client CLI skill directories via `stage_s4_skills()` at install time; Tier 0 skills are loaded by all agents by default per BD-142. This is informational only — no behavior change. Apply per-trinity-file lockstep (all 3 in same edit per Trinity rule). Cross-reference: `BD-142` and `boundary-investigation` (the Tier 0 skill added by BD-175 Commit 12 + F4 bundle that motivated this note). Decline-precedence: if BD-178's broader sweep finds the trinity already has equivalent language, NO duplicate addition — document the find in IMPL-REPORT.

  Scope:
  - Mechanical trinity edits in `project-template/{CLAUDE,AGENTS,GEMINI}.md` to converge on the canonical wording for each identified asymmetric locus (the 3 above + any additional surfaced by the fresh sweep)
  - Fresh full 3-way diff sweep across `project-template/{CLAUDE,AGENTS,GEMINI}.md` shared sections to catch any pre-existing asymmetries not yet identified; document each one in the IMPL-REPORT with proposed canonical wording + reasoning (same template as the 3 above)
  - POQ-F4-3 absorbed: add the Tier 0 base-loading informational note per the section above (trinity lockstep)
  - Regenerate `test-fixtures/manifest.txt` per RC9 (`project-template/` is v11-surface)

  Implementation pattern: mechanical pack-coder work (no architect spawn needed — wording proposals embedded in this BD for the 3 known loci; coder applies the canonicalization heuristic to any additional asymmetries found in the sweep and surfaces them in the IMPL-REPORT for Pack Chat triage before commit). Per per-BD review/fix pattern, single pack-reviewer pass after the trinity edit lands.

  Position: Insert immediately after BD-177 (per user direction 2026-05-19 — must be implemented directly after BD-177 Resolved AND before Batch 19c / BD-173 resumes; BD-173 touches project-template trinity extensively and benefits from a fully-symmetric baseline).
Resolved: 2026-05-21

---

**BD-179 — Validate-pack.py Check 40 pack-ops/ bare cross-reference scanner (F3 — architect-pass)**
Type: TODO(version) — surfaced 2026-05-19 during BD-175 Phase 5 Commit 10 review feed-in observation #4 + Commit 9b IMPL-REPORT §6.3 prevention candidate; user-explicit fold into BD-175 emergency batch 2026-05-19 (option F3); user-explicit pre-approval for pack-architect spawn 2026-05-19.
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 + BD-178 (must close successfully in that order per user direction 2026-05-19)
Unblocks: closes the bare-cross-reference defect class in `pack-ops/` markdown docs (e.g., `pack-ops/MERGE-STRATEGY.md` had 3 sibling bare refs at L471/L473/L474 partially closed by F1 commit `88a0aea`; 8 inline-prose bare refs at L271/L313/L329/L426/L440 + L270/L412/L479 + L226 still open; L472 audience-mismatch where pack-internal doc points at post-install project-side path still open); systematic prevention via new validate-pack.py check.
File/Symbol:
  - `scripts/validate-pack.py` (NEW Check 40 — bare cross-reference scanner for `pack-ops/` markdown)
  - `scripts/tests/` (new fixture test for Check 40)
  - `pack-ops/MERGE-STRATEGY.md` (and possibly other pack-ops/ docs) — qualified per architect's design after Check 40 lands
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `scripts/` + `pack-ops/` both v11-surface post-BD-176)
Description: F1 commit `88a0aea` qualified 3 sibling bare refs in `pack-ops/MERGE-STRATEGY.md` cross-references list (L471/L473/L474) per user-approved tight scope. F1 IMPL-REPORT §6 flagged 8 OTHER bare refs to the same 2 files in inline prose elsewhere in MERGE-STRATEGY.md (5 bare `MIGRATION-v10-to-v11.md` refs at L271/L313/L329/L426/L440 + 3 bare `validate-pack.py` refs at L270/L412/L479 + 1 narrative shorthand `validate-pack` at L226 — line numbers may drift). F1 per-commit reviewer (PACK-REVIEW-BD-175-F1.md NIT) additionally flagged L472 audience-mismatch (`docs/pack/OPTIONAL-FEATURES.md` is the POST-install project-side path; MERGE-STRATEGY.md self-identifies "Audience: pack-internal" at L3 — pack-internal doc pointing at client-side path).

  User-approved fold to BD-179 architect-pass per Pack Chat triage 2026-05-19 (T3a). Architect designs Check 40 to systematically address all bare-ref patterns including inline prose, with per-pattern triage decisions:
  - Cross-references list refs: load-bearing precision (canonical "where to look next" pointer set); MUST resolve unambiguously per F1's edits
  - Inline prose refs: softer-quality concern; architect decides whether to qualify all uniformly OR adopt per-pattern heuristic (e.g., qualify on first occurrence, bare for subsequent; or qualify when referent lives in subdirectory)
  - Audience-mismatch refs (L472 pattern): pack-internal doc pointing at post-install client path — architect decides whether to qualify to pack-repo path (consistency wins) OR keep client-side path (Override 8 explicitly chose this — content discusses install-time migration scenarios that resolve at client repos post-install) and document the intentional audience-bridge

  Scope:
  - Architect-pass design: systematic identification of bare cross-reference patterns in `pack-ops/` markdown; per-pattern classification (load-bearing vs softer-quality vs audience-bridge); per-CLI heuristic for whether to qualify/preserve
  - NEW `scripts/validate-pack.py` Check 40 implementing the architect's design (regex/AST-based bare-ref scanner; per-pattern allow/deny lists)
  - Test fixtures for Check 40 (PASS + FAIL + exemption cases per the architect's design)
  - Apply architect's per-pattern decisions to `pack-ops/MERGE-STRATEGY.md` (8 inline-prose refs + L472 audience-mismatch) — coder mechanical work after architect lands strategy doc
  - Regenerate `test-fixtures/manifest.txt` per RC9 (`scripts/` + `pack-ops/` both v11-surface post-BD-176)

  Implementation pattern: **pack-architect spawn FIRST** (per pack-memory pack-architect-spawn protocol — touches `pack-ops/` docs + new validate-pack.py check). User-explicit pre-approval for BD-179 architect spawn 2026-05-19 — Pack Chat spawns architect without re-asking when BD-179 work begins. Architect → strategy doc → coder applies mechanically → Pack Chat commits. Per per-BD review/fix pattern, single pack-reviewer pass after the changes land.

  Override 9 compliance: bare-cross-reference scanner applies to `pack-ops/` markdown ONLY (pack-internal docs; auditing internal consistency). Does NOT apply to project-template/ trinity or pack-root trinity (those have separate cross-CLI reference concerns under BD-182).

  Position: Insert immediately after BD-178 (per user direction 2026-05-19 — must be implemented directly after BD-178 Resolved AND before BD-180 to maintain batch chain order); architect-pass work; closes a real bare-cross-reference defect class before batch audit.
Resolved: 2026-05-21

---

**BD-180 — Extend `cmd_update` mapping symmetry coverage to remaining surfaces (gemini commands + pm-startup skill + .claude settings example + per-entry templates)**
Type: TODO(version) — surfaced 2026-05-19 during BD-175 F2a (Check 39) implementation; user-explicit fold into BD-175 emergency batch per Pack Chat triage 2026-05-19 (T3a).
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 + BD-178 + BD-179 (must close successfully in that order per user direction 2026-05-19)
Unblocks: closes 4 operational-drift gaps at surfaces BEYOND F2a Check 39's narrow `project-template/docs/pack/*.md` scope; brings `pack update` parity to all surfaces that fresh-install covers; completes the F2a-pattern coverage before batch audit.
File/Symbol:
  - `scripts/init-project.sh` (`cmd_update` mapping list + S4/S6/S11 install loops at multiple surfaces — exact lines TBD by coder/architect investigation)
  - `scripts/validate-pack.py` (possibly: extend Check 39 to broader scope, OR add Check 41/42 — implementation choice per simplest-correct-design heuristic)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `scripts/` touched)
Description: BD-175 F2a (commit `bee710c`) implemented `validate-pack.py` Check 39 cmd_update mapping symmetry with intentionally narrow scope (`project-template/docs/pack/*.md` only) per user-approved tight F2a fold-in. F2a's IMPL-REPORT §6 surfaced 4 OTHER surfaces where similar asymmetry exists — Check 39 doesn't catch them by design (narrow scope). Each is a small fix candidate:

  **A — `project-template/.gemini/commands/pm-startup.toml` never installed (fresh-install OR update):** file exists at the project-template path but neither stage S4 nor S6 nor S11 nor `cmd_update` covers it. Possibly a missing install-loop entry, or an intentional exclusion (e.g., `.toml` not in install scope) that needs documentation. Verify intent before fix.

  **B — `project-template/.claude/skills/pm-startup/SKILL.md` + `.codex/skills/pm-startup/SKILL.md` not in `cmd_update`:** S4 distributes at fresh-install (the Pattern A auto-distribute path), but `cmd_update` explicit mapping doesn't propagate — existing clients running `pack update` won't receive pm-startup skill updates. Add explicit mappings or document why pm-startup updates skip `pack update`.

  **C — `project-template/.claude/settings.local.example.json` not in either path:** likely intentional (settings.local files are user-specific per project — clients customize, don't sync from pack) but needs explicit verification + documentation.

  **D — Per-entry skeleton templates (`project-template/docs/project/{backlog,implementation-plan,changelog}/_*.md`) in S11 fresh-install but not in `cmd_update`:** existing clients won't receive template updates via `pack update`. Per pack memory, per-entry templates are load-bearing for BD-167 scaffolding — `pack update` should propagate template fixes.

  **E — Stale `cmd_update` mapping entry (reverse-direction asymmetry, absorbed from F2a per-commit review F2A-S1 2026-05-20):** Check 39 (F2a, commit `bee710c`) only verifies one direction (file-on-disk → cmd_update mapping). The reverse direction (mapping entry → file-on-disk exists) is unverified. At HEAD, `scripts/init-project.sh:1122` maps `project-template/docs/pack/PROMPT-TEMPLATES.md` but that file was RETIRED in v10.0 (PM-CHAT.md:149-150 confirms retirement). Without bidirectional verification, stale mappings can accumulate over multiple release cycles — `pack update` may silently no-op (or fail noisily depending on cp behavior) for entries whose source files no longer exist. Scope addition: BD-180 implementation should ALSO add reverse-direction check (extension to Check 39 OR new Check 41) that flags `cmd_update` entries whose source path doesn't exist at HEAD. The PROMPT-TEMPLATES.md entry should be REMOVED from `cmd_update` as part of this BD's fixes.

  **F — `cmd_update` missing `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` entries (absorbed from BD-176 architect notable finding 2; user-approved fold 2026-05-20):** BD-176 ARCHITECTURE-BD-176.md research confirmed these 2 files install to clients via init-project.sh stage S11 (fresh-install path) but are NOT in `cmd_update`'s explicit-mapping list (the `pack update` path). Same gap class as observations B/D — files reach fresh-init clients but not update clients. Scope addition: BD-180 implementation should add explicit `cmd_update` mappings for both files (or document as intentional exemptions with rationale if architect/coder determines they should NOT install via update). These 2 files share the same install-stage code path as METHODOLOGY.md's BD-175 Commit 8 CI-failure precedent — confirming they ARE fixture-affecting + ARE distributed to clients at install time.

  **G — Self-documenting "files copied to clients" list in init-project.sh (absorbed from BD-176 OQ-2 D4 deferral; user-approved fold 2026-05-20):** BD-176 architect §5.3 sketched a self-documenting authoritative list inside `scripts/init-project.sh` (or `scripts/validate-pack.py`) of files copied to clients, that RC9 + future audits could reference. Deferred from BD-176 per LOGICAL FIT — BD-180 already targets validate-pack.py / init-project.sh extensions; this fits naturally. BD-180 implementation should design + implement the self-documenting list as part of the broader cmd_update symmetry work. Design sketch in ARCHITECTURE-BD-176.md §5.3 (coder reads for context, not as required prescription).

  Scope:
  - Verify each of A/B/C/D — is the asymmetry intentional (with rationale) or accidental?
  - For accidental cases: add missing `cmd_update` mappings to `scripts/init-project.sh` per the F2a Check 39 template
  - For intentional cases: add exemption-allowlist entries to `_CHECK_39_EXEMPTIONS` (or new check exemptions) with rationale comment per file
  - Remove the stale `PROMPT-TEMPLATES.md` mapping per E (verify nothing else references it; the file was retired in v10.0)
  - Add reverse-direction check (extension to Check 39 OR new Check 41) per E — flags cmd_update entries whose source path doesn't exist at HEAD
  - Add explicit `cmd_update` mappings for `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md` per F (or document intentional exemption with rationale)
  - Implement self-documenting "files copied to clients" list per G (design sketch in `ARCHITECTURE-BD-176.md` §5.3)
  - Consider extending Check 39's scope OR adding Check 41/42 to cover the broader pattern (e.g., `.gemini/commands/*.toml`, `.claude/skills/*/SKILL.md`, per-entry templates) — coder's choice based on simplest-correct-design heuristic + minimizing check-count proliferation
  - Regenerate `test-fixtures/manifest.txt` per RC9

  Implementation pattern: mechanical pack-coder work (no architect spawn needed — F2a's Check 39 implementation is the template; this BD extends the pattern to additional surfaces). Per per-BD review/fix pattern, single pack-reviewer pass after the changes land.

  Position: Insert immediately after BD-179 (per user direction 2026-05-19 — last BD before end-of-batch reviewer; BD-180 completes the F2a-pattern coverage at all surfaces before batch audit).
Resolved: 2026-05-21

---

**BD-181 — Extend `scripts/validate-pack.py` Check 18 H2 to cover pack-root trinity (parity guard)**
Type: TODO(version) — surfaced 2026-05-20 during BD-176 ARCHITECTURE-BD-176.md research (Notable Finding 3); user-approved fold into BD-175 emergency batch 2026-05-20.
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 + BD-178 + BD-179 + BD-180 (must close successfully in that order per user direction 2026-05-20)
Unblocks: closes the pack-root trinity drift gap that currently has NO mechanical guard (only Trinity-rule discipline + reviewer attention). BD-178 exists explicitly because pre-existing trinity asymmetries crept in at project-template level despite Trinity-rule discipline — same risk applies to pack-root trinity, possibly worse (fewer eyeballs in PR review).
File/Symbol:
  - `scripts/validate-pack.py` Check 18 H2 implementation around lines 1295-1300 (currently hardcodes `REPO_ROOT / "project-template" / name`; extend to take base-path parameter + add second invocation for pack root)
  - `scripts/tests/` new fixture test for Check 18 pack-root coverage (or extension to existing test)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `scripts/` touched)
Description: BD-176 architect's research (ARCHITECTURE-BD-176.md §7 D6) confirmed that Check 18 H2 (`scripts/validate-pack.py:1295-1300`) is hardcoded to verify within-trinity parity ONLY for `project-template/{CLAUDE,AGENTS,GEMINI}.md`. Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at repo root) has NO mechanical parity guard — drift between pack-root trinity files is undetected by CI until manual reviewer audit catches it.

  This is brittle. BD-178 was opened specifically because pre-existing trinity asymmetries crept in at project-template level despite Trinity-rule discipline. Same risk applies to pack-root trinity — the difference is that pack-root trinity edits are typically Pack-Chat-direct (more centralized), while project-template trinity is more broadly edited. Both surfaces benefit from automated parity guards.

  Scope:
  - Generalize Check 18 H2 function: take a base-path parameter (currently hardcoded `REPO_ROOT / "project-template"`)
  - Add a second invocation for pack-root trinity (REPO_ROOT directly)
  - Both invocations independent — enforces within-trinity parity at EACH location separately (does NOT enforce cross-trinity parity, per Override 9 — pack-root and project-template can differ by design)
  - Add test fixtures for new pack-root coverage (PASS + FAIL synthetic cases)
  - Regenerate `test-fixtures/manifest.txt` per RC9

  Implementation pattern: mechanical pack-coder work (no architect spawn needed — generalizing an existing check is mechanical extension of a proven pattern). Per per-BD review/fix pattern, single pack-reviewer pass after the changes land.

  Override 9 compliance: this BD does NOT enforce cross-trinity parity. Both Check 18 invocations are independent — pack-root and project-template can have DIFFERENT bullet bodies (as designed per Override 9). Only WITHIN each trinity location (across the 3 CLI files) is byte identity enforced.

  Position: Insert immediately after BD-180 (per user direction 2026-05-20 — between BD-180 cmd_update work and end-of-batch reviewer; small mechanical extension; closes a real brittleness gap before batch audit).
Resolved: 2026-05-21

---

**BD-182 — Cross-CLI reference normalization across project-template trinity (settings paths, commands, tool-specific URIs)**
Type: TODO(version) — surfaced 2026-05-20 during BD-178 SHOULD-1 fix-coder implementation (IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md §3.1 observation); user-approved fold into BD-175 emergency batch 2026-05-20.
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 + BD-178 + BD-179 + BD-180 + BD-181 (must close successfully in that order per user direction 2026-05-20)
Unblocks: closes the cross-CLI reference asymmetry that lurked under BD-178 SHOULD-1's byte-identical body-text alignment (a Gemini-CLI-running user reading project-template/GEMINI.md gets wrong settings-file path because CLAUDE-canonical wording references `.claude/settings.json`); provides systematic per-CLI reference table for future trinity edits.
File/Symbol:
  - `project-template/CLAUDE.md` (CLI-specific references throughout — settings paths like `.claude/settings.json`, commands like `claude help`, etc.)
  - `project-template/AGENTS.md` (CLI-specific references for Codex CLI)
  - `project-template/GEMINI.md` (CLI-specific references for Gemini CLI)
  - Possibly `pack-root` trinity (CLAUDE.md / AGENTS.md / GEMINI.md at repo root) — separate trinity location with similar cross-CLI reference concerns
  - `scripts/init-project.sh` (verify install-time tool-specific path adjustments if any)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `project-template/` is v11-surface)
Description: BD-178 SHOULD-1 fix-coder (commit `fa605a9`) aligned project-template/GEMINI.md body text to CLAUDE.md for 4 sections (iOS 26, Architecture, Security, Scripts) per Option 1A. The byte-identical adoption per pack memory CLAUDE-first General canonicalization heuristic correctly closed UNRESOLVED-DRIFT (per archived ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md §D.4 L432-436 classification) — BUT side-cased a different concern: the CLAUDE-canonical iOS-26 wording references `.claude/settings.json`, which is Claude-CLI-specific. A Gemini-CLI-running user reading GEMINI.md now gets the wrong settings-file path (Gemini installs use `.gemini/`, not `.claude/`).

  Per Override 9 principle (different audience = different wording; NO cross-trinity drift gate), tool-specific references ARE legitimate divergence. Each trinity file should reference its OWN CLI's settings paths, commands, etc. — NOT byte-identically copy the Claude-specific references.

  This is a DIFFERENT class of issue than body-text drift:
  - Body-text drift (SHOULD-1): same conceptual content but different wording → align to canonical (CLAUDE-first)
  - Cross-CLI references (this BD): same conceptual content but DIFFERENT correct values per CLI → tool-specific divergence is REQUIRED (Override 9 authorized)

  The same issue likely exists across the trinity for ALL CLI-specific references:
  - Settings files: `.claude/settings.json` vs `.codex/config.toml` (or equivalent) vs `.gemini/settings.json` (or equivalent)
  - CLI commands: `claude` vs `codex` vs `gemini` invocations
  - Hook paths, command directories, skill directories, agent directories (per-CLI prefixes throughout)
  - Documentation URIs, troubleshooting references

  Scope:
  - Architect-pass analysis: systematic identification of all cross-CLI references in `project-template/{CLAUDE,AGENTS,GEMINI}.md` (and possibly pack-root trinity)
  - Per-reference classification: tool-specific (per-CLI canonical) vs tool-neutral (CLAUDE-first canonical)
  - Per-CLI canonical reference table: for each cross-CLI reference, what's the correct per-CLI value?
  - Trinity edits applying tool-specific canonicalization per the table
  - Verify scripts/init-project.sh install-time path adjustments are consistent with the trinity references
  - Regenerate `test-fixtures/manifest.txt` per RC9
  - Update Check 18 (or add a new check) to recognize that cross-CLI references in trinity are EXPECTED to differ per Override 9 — don't false-positive as within-trinity parity violations

  Implementation pattern: pack-architect spawn (per pack-memory pack-architect-spawn protocol — touches trinity Pack memory section + rules/operating-docs; user approval required for architect spawn) → strategy doc with per-reference table → pack-coder applies mechanically → Pack Chat commits.

  Position: Insert immediately after BD-181 (per user direction 2026-05-20 — last BD before end-of-batch reviewer; provides clean cross-CLI reference baseline before batch audit).
Resolved: 2026-05-21

---

**BD-183 — Extend `scripts/validate-pack.py` Check 16 + Check 19 to cover pack-root trinity (parity guard, mirroring BD-181) + BD-181 NIT-1 fold-in**
Type: TODO(version) — surfaced 2026-05-20 during BD-181 per-commit review (PACK-REVIEW-BD-181.md §6 Observation A); user-approved fold into BD-175 emergency batch 2026-05-20 ("must be done in this batch before 19c restart").
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 + BD-178 + BD-179 + BD-180 + BD-181 + BD-182 (must close successfully in that order per user direction 2026-05-20)
Unblocks: closes the parity-guard gap for Check 16 (`check_trinity_addenda_h2`) and Check 19 (`check_trinity_no_scaffolding_comments`) at pack-root trinity. Same parity-gap risk that drove BD-181 (Check 18 H2): pack-root trinity has NO mechanical guard for these two checks today; drift detected only by manual reviewer audit. Also folds in BD-181 NIT-1 (sentinel-None call-site contract comment) per logical-fit (same file + same check-family + same docstring style).
File/Symbol:
  - `scripts/validate-pack.py:check_trinity_addenda_h2` (Check 16) — generalize to take base-path parameter; mirror BD-181 sentinel-None default + label threading pattern
  - `scripts/validate-pack.py:check_trinity_no_scaffolding_comments` (Check 19) — same generalization pattern
  - `scripts/validate-pack.py:check_trinity_h2_parity` — fold in BD-181 NIT-1 sentinel-None call-site contract comment (1-3 line code-comment addition per PACK-REVIEW-BD-181.md §4 NIT-1)
  - `scripts/validate-pack.py:main` — add two new invocations for pack-root trinity (Check 16 [pack-root] + Check 19 [pack-root])
  - `scripts/tests/` — extend existing Check 16 + Check 19 test fixtures OR add new sibling tests (coder's choice; mirror BD-181 `test-validate-pack-check-18.sh` pattern including Override 9 isolation test)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `scripts/` touched but pack-internal scripts; rebuild likely empty diff)
Description: BD-181 PACK-REVIEW-BD-181.md §6 Observation A identified that Check 16 + Check 19 remain `REPO_ROOT / "project-template" / name`-hardcoded after BD-181's Check 18 H2 generalization. By the same parity-gap argument BD-181 applied to Check 18, the pack-root trinity has NO Check 16 or Check 19 guard. Drift between pack-root trinity files for these check classes is undetected by CI until manual reviewer audit catches it. BD-181 set the precedent + design pattern; BD-183 mechanically extends to the remaining two trinity checks. BD-181 NIT-1 is folded in per logical fit (same file + same check-family + same docstring style; the 4-line zero-risk sentinel-None contract comment fits naturally alongside BD-181's `check_trinity_h2_parity` that the BD-183 generalization will reference as a template).

  Scope:
  - Generalize Check 16 (`check_trinity_addenda_h2`) with base-path parameter; mirror BD-181 sentinel-None + label-threading pattern
  - Generalize Check 19 (`check_trinity_no_scaffolding_comments`) similarly
  - Add second invocations for pack-root trinity in `main()` for both checks
  - Both invocations INDEPENDENT per Override 9 (no cross-trinity parity gate)
  - **Empirical pre-implementation drift check (per BD-181 pattern)**: BEFORE landing the pack-root invocations, run the new generalized functions against live pack-root trinity at HEAD; if drift surfaces, BLOCKING surface to Pack Chat for triage (analogous to BD-181's precondition handoff)
  - Fold in BD-181 NIT-1 sentinel-None call-site contract comment at `check_trinity_h2_parity` (1-3 line code comment)
  - Extend/add test fixtures for new pack-root coverage (PASS + FAIL synthetic cases for both checks); mirror BD-181 Override 9 isolation test pattern
  - Regenerate `test-fixtures/manifest.txt` per RC9 (expected empty diff)

  Override 9 compliance: BOTH new Check 16 + Check 19 invocations enforce within-trinity parity at EACH location separately (does NOT enforce cross-trinity parity — pack-root and project-template can have different content by design).

  Implementation pattern: mechanical pack-coder work (no architect spawn needed — generalizing existing checks is mechanical extension of the proven BD-181 pattern). Per per-BD review/fix pattern, single pack-reviewer pass after the changes land.

  Position: Insert immediately after BD-182 (per user direction 2026-05-20 — same parity-gap class as BD-181; mechanical extension; mandatory pre-19c-restart per user direction "must be done in this batch before 19c restart"; last BD before end-of-batch reviewer).
Resolved: 2026-05-21

---

**BD-184 — Add Check 42 — CI workflow wires all per-check test files (prevention check for "test silently dead in CI" gap class)**
Type: TODO(version) — surfaced 2026-05-21 during BD-183 FIX-1 per-commit review (PACK-REVIEW-BD-183-FIX-1.md SHOULD-A + Pack Chat exhaustive scanner result); user-approved fold into BD-175 emergency batch 2026-05-21 ("Open now. Implement immediately after BD-183 closes").
Status: Resolved
Blockers: BD-175 + BD-176 + BD-177 + BD-178 + BD-179 + BD-180 + BD-181 + BD-182 + BD-183 (must close successfully in that order per user direction 2026-05-21)
Unblocks: closes the "missing test wiring" gap class permanently via mechanical CI guard. The same gap surfaced 5 times across 3 fix cycles in the BD-175 batch — discipline (reviewer attention) caught all 5 but a mechanical guard at commit time is cheaper than reviewer cycles.
File/Symbol:
  - `scripts/validate-pack.py` — new Check 42 (`check_ci_workflow_wires_per_check_tests`) — greps `scripts/tests/test-validate-pack-check-*.sh` files, compares against `.github/workflows/validate-pack.yml` `bash scripts/tests/test-validate-pack-check-*.sh` invocations; FAILs if any test file exists without corresponding workflow step
  - `scripts/tests/test-validate-pack-check-42.sh` — new test for the new check (per user-approved per-check naming convention; mirror BD-181/BD-183 test pattern with synthetic fixture for FAIL case)
  - `.github/workflows/validate-pack.yml` — wire the new `test-validate-pack-check-42.sh` invocation (must also be a sister-step per the very convention this BD enforces)
  - `test-fixtures/manifest.txt` (regenerate per RC9 — `scripts/` touched but pack-internal; expected empty diff)
Description: The "missing test wiring" gap class has surfaced 5 times across the BD-175 batch:
  - BD-179 FIX-1 (`1e644d1`): wired 3 unwired tests (`test-validate-pack-checks-36-37-38.sh` since BD-175 Commit 12; `test-validate-pack-check-39.sh` since BD-175 F2a; `test-validate-pack-check-40.sh` since BD-179 main)
  - BD-183 FIX-1 (`5f8f683`): wired `test-validate-pack-check-18.sh` (unwired since BD-181 main `c244314`)
  - BD-183 FIX-2 (pending): wires `test-validate-pack-check-41.sh` (unwired since BD-180 main `78a4415`)

  Each occurrence was caught by reviewer attention applying the new carry-forward discipline (BD-179 FIX-5, `ff23a00`). The discipline works, but a mechanical guard is cheaper than per-cycle reviewer attention.

  Scope:
  - Implement Check 42: parse `scripts/tests/test-validate-pack-check-*.sh` (glob with `-* matches numbered or bundled forms like `-16`, `-checks-36-37-38`); parse `.github/workflows/validate-pack.yml` for `bash scripts/tests/test-validate-pack-check-*.sh` invocations; report FAIL with specific filename(s) for any file existing without a corresponding workflow step
  - Add test fixture `test-validate-pack-check-42.sh` mirroring BD-181/BD-183 test pattern (signature group + PASS group + FAIL synthetic group + e2e regression guard)
  - Wire `test-validate-pack-check-42.sh` into `.github/workflows/validate-pack.yml` (this BD's own test must pass the check it implements — self-referential closure)
  - Verify Check 42 PASSes at HEAD after the new wiring (all 9 test files including check-42 itself now wired)
  - Regenerate `test-fixtures/manifest.txt` per RC9 (expected empty diff; pack-internal)

  Implementation pattern: mechanical pack-coder work (no architect spawn needed — Check 42 is a straightforward file-glob-vs-workflow-grep comparison; pattern mirrors existing checks). Per per-BD review/fix pattern, single pack-reviewer pass after the changes land.

  Position: Insert immediately after BD-183 (per user direction 2026-05-21 — "Implement immediately after BD-183 closes"; last BD before end-of-batch reviewer for the BD-175 emergency batch).
Resolved: 2026-05-21

---

**BD-185 — Phase parts hierarchy + tracker-mode execution ordering**
Type: feat — surfaced 2026-05-21 from Pack Chat design discussion (main v10.1 chat); user-approved as Batch 19d (immediately after Batch 19c) 2026-05-21
Status: Open
Paused: 2026-05-28 — PAUSED pending Code Red 3 (BD-195). The prior BD-185 attempt is being superseded/recovered by BD-195; no new BD-185 work begins until BD-195 completes. BD-195 Step 9 decides whether the prior BD-185 work-so-far is wiped or salvaged.
Blockers: Batch 19c (BD-173) completion — fires after BD-173 closes and commits. Docs-researcher prompt persisted at `maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md` (one-time exception to "Pack Chat does not edit maintenance-docs/" rule per user direction 2026-05-21) for use at fire time; firing requires explicit user approval.
Unblocks: Real-OT migration test (BD-171, Batch 23) gains the new form-family + ordering mechanism for empirical validation; v10→v11 and v11.0 flat→tracker migrators carry pre-existing whole-number phases through cleanly; mid-work phase-to-parts expansion gains first-class tracker representation; tracker-mode execution ordering becomes expressible without flat-file SSOT or GH Projects abuse.
File/Symbol:
  - `project-template/.github/ISSUE_TEMPLATE/work-item.yml` — Part field + part:M label namespace (NEW) per BD-068 form-family rules + BD-069 template_version delta
  - `supporting-docs/METHODOLOGY.md` Part 3 § "Multi-part phases" (lines ~339-366) — extend for mid-work phase-to-parts expansion mechanism
  - `scripts/lib/tracker-provider-*.sh` (BD-060 TrackerProvider) — bi-directional sync of part membership + execution order across forward (flat→tracker) and reverse (tracker→flat) operations
  - `scripts/migrate-v10-to-v11.sh` + any v11.0 flat→tracker migrator — pre-existing whole-number phases pass through without renumbering; new ordering mechanism initialized from current implementation order
  - `scripts/validate-pack.py` — new check(s) enforcing part-membership + ordering invariants (architect determines specifics)
  - `project-template/docs/pack/PM-CHAT.md` — PM-chat orchestration text for mid-work phase-to-parts expansion (architect determines)
  - `project-template/STATUS.md` — confirm role does NOT change (remains dashboard, not promoted to ordering SSOT)
Description: Pack-side design work to address four problems framing the BD:

  **P1.** Mid-work phase splits have no first-class tracker representation. METHODOLOGY.md §339-366 defines "Part 1, Part 2" sub-sections inside IMPLEMENTATION-PLAN.md, but the tracker form-family (`.github/ISSUE_TEMPLATE/work-item.yml`) has no Part field, no part:M label, and computes task titles as `Phase N.M` with no part awareness.

  **P2.** The hierarchy changes when parts are added. Pre-mitigation: Phase N → Tasks N.1..N.k. Post-mitigation: Phase N → Parts (1..p), each part containing its own tasks. Existing task IDs (N.1..N.k) must survive this transition without renumbering. Current v11 design has no documented mechanism for grouping existing tasks under parts.

  **P3.** Tracker-mode execution ordering has no native mechanism. GH Issues lack a user-mutable execution-order field. Issue numbers reflect creation order. Blockers/dependencies give only partial order. Sub-issues give containment, not sibling order. In flat-file mode, ordering lives in IMPLEMENTATION-PLAN.md as "execution notes" (METHODOLOGY:335). In tracker mode, IMPLEMENTATION-PLAN.md is a regenerated mirror — execution notes do not survive sync.

  **P4.** v10→v11 and flat-file→tracker migrations must handle pre-existing whole-number phases without manual intervention, including initializing the new ordering mechanism from current implementation order. All v10.x and v11 projects already have whole-number-only phases; whatever solution is designed must absorb that state cleanly.

  **Goal:** Both flat-file and tracker modes can express phase splits at creation, mid-work phase-to-parts expansion, and explicit execution ordering — all without renumbering existing phase or task IDs and without flat-file artifacts serving as the SSOT in tracker mode.

  **Success Criteria:**
  - SC1. Phases that grow too large at creation time can be split into multiple phases (each with a new immutable number), in both modes.
  - SC2. Phases that grow too large mid-work can be expanded into multi-part form (Phase N → Part 1..p, each part containing tasks), preserving the existing phase number and all existing task IDs, in both modes.
  - SC3. Phase numbers and task IDs (N.M) are never renumbered. Tracker entity IDs (GH Issue numbers) are inherently immutable. This invariant holds across all operations defined by this BD.
  - SC4. Execution ordering of phases is expressible in both modes. In tracker mode, ordering does NOT depend on any flat-file artifact and does NOT use GH Projects as a single-phase ordering substitute.
  - SC5. STATUS.md remains a dashboard. Its role does not expand to ordering SSOT in either mode.
  - SC6. Tracker form-family (`work-item.yml` + label namespace + template_version per BD-069) supports parts and ordering with the smallest possible template_version delta consistent with BD-068 form-family rules.
  - SC7. Bi-directional sync (BD-060 TrackerProvider, mirror semantics) preserves part membership and execution order across forward (flat→tracker) and reverse (tracker→flat) operations.
  - SC8. The v10→v11 migrator and any v11.0 forward-migration (flat-file → tracker mode) pass pre-existing whole-number phases through unchanged and initialize the new ordering mechanism from current implementation order without manual intervention.

  **Out of scope:**
  - GH Projects integration (v11.1 scope; see `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` in main branch — not present on v11-dev yet).
  - Tracker backends other than github (linear/jira/redmine — reserved).
  - STATUS.md schema changes beyond its current dashboard role.
  - Letter-suffix phase forms (7a, 7b — rejected).

  **Pipeline:** docs-researcher → revised-architect-prompt → architect → user review → planner → user review → coder (per pack memory `feedback_researcher_architect_planner_pipeline`). Docs-researcher prompt queued at `maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md`; fires only after Batch 19c (BD-173) closes and commits AND explicit user approval.

  **Form-family decisions reserved for architect:** labeling-overlay vs sub-issue-hierarchy for parts; ordering mechanism shape. Do NOT pre-bias in docs-researcher pass.

  **Position:** Batch 19d, immediately after Batch 19c (BD-173). User-approved sequencing 2026-05-21.
Resolved: n/a

---

**BD-186 — Groupings requirements + v11.0/v11.1 scope decision**
Type: feat — surfaced 2026-05-21 from sidecar Pack Chat session for v11.1+ groupings requirements gathering; user-approved as parallel to Batch 19d (BD-185) 2026-05-21
Status: Resolved
Blockers: None. Independent of BD-185 — phase identifier grammar `phase-N` is stable across BD-185 SC3 (no renumbering invariant); user constraint C1 excludes phase parts from grouping membership; tracker-side surfaces (BD-185 part labels + execution-ordering field vs. groupings Project/Epic/Version) do not collide. Runs parallel to Batch 19d.
Unblocks: Downstream architect / planner / coder cycles for the groupings feature implementation (architect pass reads BD-186's REQUIREMENTS-GROUPINGS-V11.md as its primary input). Per-capability v11.0-vs-v11.1 scope decisions surfaced by this BD inform whether any capability folds into existing v11.0 batches and what new BDs open for v11.1+ deferral.
File/Symbol:
  - NEW `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` — single requirements artifact + per-capability v11.0/v11.1 scope verdicts
  - INPUTS (read-only, not modified): `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` (constraint enumeration), `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` (parking-lot brainstorm), `pack-ops/BACKLOG.md` BD-185 entry (phase-parts adjacency context)
Description: Pack-side requirements-gathering work to refine the "groupings of phases" feature shape and produce a per-capability v11.0/v11.1 scope verdict. This BD covers the REQUIREMENTS pass only; downstream architect / planner / coder cycles open as separate BDs once the requirements artifact lands and capabilities have verdicts.

  **Inputs:** Touch-point inventory V2 (constraint enumeration of current v11 design + external tracker capabilities), V11.1 discussion (parking-lot brainstorm of feature shape), user-stated design principles (5 core + C6 external-tool import + C7 graceful tracker degradation). The inventory tells us blast radius; this BD refines the feature set bounded by what is best for users, current v11 design constraints, and external tracker capabilities — explicitly purpose-driven per design principle #1.

  **Goal:** Produce a single requirements artifact at `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` capturing:
  - Refined user-facing capability set (extract from V11.1 brainstorm; absorb capabilities surfaced during triage)
  - Per-capability disposition (keep / modify / drop / GH-conditional) with rationale tied to design principles
  - Per-capability v11.0/v11.1 scope verdict with rationale
  - For v11.0-absorbed capabilities: insertion target (existing batch fold-in OR proposed new BD-NNN with position)
  - For v11.1+ capabilities: live forward-pointing anchor (this artifact + cross-reference back to V11.1-DISCUSSION-GITHUB-PROJECTS.md where applicable)

  **Success Criteria:**
  - SC1. Every user-facing capability proposed in V11.1 §13 + every capability surfaced during this BD's triage has a documented disposition + scope verdict.
  - SC2. Every break-point (7), major-revision flag (3), and open observation (14) in TOUCH-POINT-INVENTORY-GROUPINGS-V2.md has a documented resolution — inline in this artifact or folded into capability-disposition rationale.
  - SC3. Disposition + scope verdicts cite the user-stated design principles (purpose-driven, first-class entity, reversibility, tracker portability, compatibility, plus C6 external-tool import + C7 graceful tracker degradation) as the rationale basis.
  - SC4. v11.0-absorbed capabilities have either a target existing batch (with cross-reference to that batch's BD) or a proposed new BD-NNN (with insertion position per `feedback_deferral_is_scope_creep`).
  - SC5. v11.1+ capabilities are listed on a live forward-pointing surface — this artifact, with cross-reference back to V11.1-DISCUSSION-GITHUB-PROJECTS.md.

  **Out of scope:**
  - Architecture (doc shape, schema, sidecar layouts, provider op signatures, validate-pack check details) — downstream architect pass.
  - Implementation planning (commit sequencing, per-BD breakdown beyond proposed BD-NNNs) — downstream planner pass.
  - Edits to V11.1-DISCUSSION-GITHUB-PROJECTS.md beyond an optional cross-reference at file foot.
  - Edits to TOUCH-POINT-INVENTORY-GROUPINGS-V2.md (treated as constraint snapshot; this BD's artifact supersedes for forward-pointing purposes).
  - Opening new BDs for groupings IMPLEMENTATION work (those open later, once the requirements doc settles and the user authorizes them per OQ-1).

  **Pipeline:** Pack Chat sidecar (this work) → REQUIREMENTS-GROUPINGS-V11.md → user review + approval → BD-186 Resolved → downstream architect/planner/coder cycles open as separate BDs per scope decisions.

  **Position:** Parallel to Batch 19d (BD-185 — phase parts + tracker-mode execution ordering). Independence from BD-185 verified — see sidecar Pack Chat analysis 2026-05-21 (phase identifier grammar stable across BD-185 SC3; user's C1 constraint excludes phase parts from grouping membership). No hard sequencing dependency in either direction; downstream grouping architect can run before/after BD-185 architect as scheduling permits.
Resolved: 2026-05-23 — REQUIREMENTS-GROUPINGS-V11.md landed at `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (908 lines; 17 capabilities with problem/goal/SC + user-approved design decisions + architect-level surfaces). Sidecar Pack Chat session 2026-05-21..2026-05-23 produced the artifact. BD-187 (entry-type instruction doc parking-lot) + BD-188 (sprint view parking-lot) opened during triage. Memory: feedback_groupings_design_principles + feedback_user_prescriptive_authority saved at session end. Architect-pass-ready: v11.1+ groupings architect reads this artifact as primary input.

---

**BD-174 — Scratch-pack-clone migration + multi-toggle test harness**
Type: TODO(version) — surfaced 2026-05-17 from session discussion of test fixture thoroughness pre-public-release (gap identified: BD-102 dog-food runs on real pack repo; no scratch-clone equivalent for pack-on-pack code-bug-catching in safe environment)
Status: Open
Blockers: None on critical path; recommended sequencing pairs with BD-171 (real-OT scratch-clone) + BD-102 (real-pack dog-food) to share live-GH test infra. Position in Batch 23: FIRST in the live-GH test trio (BD-174 → BD-171 → BD-102 per 2026-05-17 ordering rationale).
Unblocks: BD-102 dog-food (less likely to fail because BD-174 catches code bugs in safe env first); pre-public-release pack-on-pack validation in scratch environment (recovery via re-provisioning scratch — much cheaper than recovering from real-pack-repo damage if dog-food fails).
File/Symbol:
  - NEW `scripts/tests/test-scratch-pack-clone.sh` (harness: provision scratch GH repo via `gh repo create`, clone the pack repo into `/tmp`, push to scratch, run end-to-end migration on the scratch clone, full multi-toggle test (flat → GH Issues → flat → GH Issues), verify state integrity at each toggle, tear down scratch repo via `gh repo delete --yes`)
  - EXTEND `.github/workflows/validate-pack.yml` (gated CI run with `if: github.event_name == 'workflow_dispatch'` — manual trigger only; same pattern as BD-171)
  - EXTEND `test-fixtures/README.md` table (note scratch-pack-clone harness pattern alongside BD-171's scratch-OT-clone pattern)
Description: Pack-repo dog-food test in safe scratch environment. Provisions
  a scratch GH repo via `gh repo create`, clones the pack repo to scratch,
  pushes scratch, runs the actual v10 → v11.0 migration end-to-end ON THE
  SCRATCH CLONE (never the real pack repo), then runs full multi-toggle test
  pattern (flat-file → GH Issues → flat-file → GH Issues). Each transition
  verifies state integrity, data preservation, BACKLOG entry survival, mode-
  file `tracker.toml` correctness. Failure at any step → re-provision scratch
  repo + retry (recovery is cheap; original pack repo untouched).

  Distinguishes from BD-102 (real-pack dog-food) in 3 ways:
  - Repo: scratch clone vs real pack repo
  - Toggle pattern: multi-toggle (flat→GH→flat→GH) vs single round-trip (init → reverse)
  - Failure recovery: re-provision scratch (cheap) vs manual git revert (risky)

  Ordering rationale (per 2026-05-17 user-Pack Chat discussion):
  - BD-174 first in Batch 23: catches code bugs in safe env (pack-on-pack)
  - BD-171 second: validates client surface (pack-on-OT-content)
  - BD-102 last: final ship-decision gate on real pack repo, should "just work"
    because BD-174 caught the issues in safe env first

  Per pack-memory rule (`feedback_test_infra_self_provisioned.md`):
  "provision scratch GH repos via gh CLI with per-step approval; clean up after;
  never touch existing real repos." Closes pre-public-release gap surfaced
  during BD-171 discussion: there's no equivalent safe-env validation for
  pack-on-pack code bugs.
Resolved: n/a

---

**BD-173 — Project-side cleanup (project-template/ trinity + agents + skills + ops docs consolidation)**
Type: TODO(version) — surfaced 2026-05-17 from Batch 19b architect-doc out-of-scope flag + user direction to schedule project-side equivalent of Batch 19b before Batch 21
Status: Resolved
Blockers: Batch 19b completion (in_progress); also see pack-chat task list Task #13
Unblocks: Batch 20 (BD-105/BD-103); Batch 21 (BD-109/BD-110 auditor agents) — both informed by new project-side rules; Batch 22 (BD-100 milestone audit covers both pack-side from Batch 19b AND project-side from BD-173); Batch 23 (BD-102 dog-food validates by using cleaned project-template)
File/Symbol:
  - `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` — project trinity v11.0 ship-readiness consolidation
  - `project-template/.claude/agents/`, `.codex/agents/`, `.gemini/agents/` — project-side agent definitions
  - `project-template/skills/`, `.codex/skills/`, `.gemini/commands/` — project-side skills + commands
  - `project-template/docs/pack/` — project-side ops docs (PM-CHAT.md and siblings)
Description: Project-side analog to Batch 19b (which consolidated pack-side
  rules/memories/ops-docs). Architect-led consolidation pass on project-template/
  surface for v11.0 ship-readiness, informed by:
  - User-provided OT content + memories at
    `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/OT Project Untracked and Tracked Memories.txt`
  - Existing project-template/ surface
  - Anticipated client needs (validated by subsequent batches per
    "every subsequent batch is a validation pass" logic)

  Process (multi-pass per Batch 19b precedent, per 2026-05-17 user direction):
  user-input collection → architect (first pass) → user review →
  architect addendum/V2 → user review → planner → user review →
  pack-coder × N per-commit with inline reviewers → end-of-batch
  broad reviewer → BD status flip.

  Position: Batch 19c, between Batch 19b (cleanup) and Batch 20
  (features). Earlier-rather-than-later per user 2026-05-17 direction
  so every subsequent batch becomes a validation pass for the new
  project-side rules.

  NOT in scope:
  - Pack-side files (separation rule; covered by Batch 19b)
  - Per-CLI memory-cache (only Claude has it; project-side may have
    none per Batch 19b BD-19b research; architect determines)
Resolved: 2026-05-24 — Batch 19c (H.1-H.17). 36-leak boundary sweep (Categories A+B+C+D+E+F per AUDIT-PRE-19C-BOUNDARY-LEAKS.md) + 4 Guardrails (G1 Check 43 project-side bare cross-reference scanner + G2 per-line fence Check 37 modification across 12 dual-surface files + G3 _PROJECT_SIDE_ROOTS scope expansion to _iter_client_installed_files() helper + G4 pack-coder PREFLIGHT extension with Check 43 verification step) + D-11 PM-chat omniscience principle landed in METHODOLOGY.md Part 1 + OT-UT-1 Claude Code Agent Teams informational paragraph + salvageability B1/B2/B3/B5/B9 word-level cleanups. End-of-batch review PASS-WITH-NITS (single F-1 README check-count staleness fix folded into H.17 combined commit). 43/43 validate-pack checks PASS at HEAD; 10/10 per-check test files CI-wired (Check 42); 7/7 Check 43 fixture-test groups PASS; 8/8 Check 36/37/38 fixture-test groups PASS; fixture manifest verifies clean.

---

**BD-171 — Real-OT scratch-GH-repo migration test fixture + harness**
Type: TODO(version) — surfaced 2026-05-15 from session discussion of test fixture thoroughness pre-public-release
Status: Open
Blockers: None on critical path; recommended sequencing pairs with BD-102 (Batch 23 dog-food) to share live-GH test infra and amortize test-time cost. Can also run standalone in Batch 22b or 23.
Unblocks: Empirical validation of v10.1 → v11.0 migration on a real OT clone (not synthetic `v10-realistic-ot` fixture); reusable harness pattern for v11 → v12 real-clone testing in future major versions; closes pre-public-release gap identified 2026-05-15 (synthetic fixture coverage is necessary but not sufficient for real-client validation).
File/Symbol:
  - NEW `scripts/tests/test-real-ot-migration.sh` (harness: provision scratch GH repo via `gh` CLI per pack-memory test-infra rule, clone real OT into `/tmp` at v10.1 tag, push to scratch, run `migrate-v10-to-v11.sh`, verify outcome incl. customization preservation + trinity invariants + tracker-mode round-trip if applicable, teardown scratch repo with per-step approval).
  - NEW `test-fixtures/v10-real-ot-snapshot/README.md` (documentation of the harness pattern + provenance; the live-clone fixture itself is not committed since it's a runtime pattern not a static fixture).
  - EXTEND `.github/workflows/validate-pack.yml` (gated CI run with `if: github.event_name == 'workflow_dispatch'` so the test runs on manual trigger only; auto-CI shouldn't provision scratch repos every push).
  - EXTEND `test-fixtures/README.md` table (note the live-clone harness pattern complements the persistent fixtures).
Description: Real-OT migration test that complements `v10-realistic-ot` synthetic
  fixture (BD-113) and BD-102 dog-food on pack-repo. Provisions a scratch GH repo
  via `gh repo create`, clones the real OT project into `/tmp` at v10.1 tag,
  pushes to scratch, runs the actual v10.1 → v11.0 migration end-to-end, verifies
  preservation invariants (BD-088 customization survival; BD-136 marker round-trip
  if applicable), then tears down the scratch repo via `gh repo delete --yes`.
  Original OT repo is read-only; no destructive operations on the source. Per
  pack-memory rule (`feedback_test_infra_self_provisioned.md`): "provision scratch
  GH repos via gh CLI with per-step approval; clean up after; never touch existing
  real repos." Pattern reusable for v11 → v12 real-clone testing in future
  versions. Closes pre-public-release gap: synthetic + dog-food-on-pack-repo
  coverage is good but cannot substitute for real-client-shape validation (real
  OT may have customization patterns the synthetic fixture doesn't model — history
  depth, file-removal patterns, conflicting `[CONDITIONAL]` block edits, edge
  `x-`-prefix conventions).

  Test suite includes the FULL multi-toggle pattern (per 2026-05-17
  user-Pack Chat discussion): flat-file (post-migration default) → GH Issues
  (via `pack tracker init`) → flat-file (via reverse) → GH Issues (via
  `pack tracker init` again). Each transition verifies state integrity, data
  preservation, BACKLOG entry survival, mode-file `tracker.toml` correctness.
  Failure at any step → re-provision scratch repo + retry (recovery is cheap;
  original OT untouched).

  Batch 23 ordering: BD-171 runs in position 2 of the live-GH test trio,
  AFTER BD-174 (scratch-pack-clone, which catches pack code bugs symmetrically
  in safe env) and BEFORE BD-102 (real-pack final ship gate). This positions
  client-content validation after pack-on-pack validation for diagnostic
  clarity — BD-171 failures after BD-174 passed are unambiguously client-
  content-specific.
Resolved: n/a

---

**BD-170 — Pre-decomposed v11-realistic-ot fixture per-entry tree extension (combined with BD-160 in commit 19f per Pack-Chat-direct R-2 resolution)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-164 (BD-160 dependency satisfied trivially — BD-160 ships in same commit per Pack-Chat-direct R-2 resolution per `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §10.2)
Unblocks: BD-102 dog-food (Batch 23 per Addendum #1 §2.2 renumber cascade — was Batch 22)
File/Symbol:
  - `test-fixtures/build.sh` (`_build_realistic_for_version` v11 case dispatch per BD-160 + extension to call BD-164 decompose helper per integration parent §12.1; coder picks fixture-generator function structure per Addendum #1 §9.1)
  - `test-fixtures/manifest.txt` (regeneration per integration parent §12.4)
  - `test-fixtures/README.md` (table row for `v11-realistic-ot` per BD-160 spec)
Description: Combined commit shipping BD-160 (v11 case dispatch + C2/C3 customization re-verification on v11 surface) + BD-170 (per-entry tree extension + round-trip test) per Pack-Chat-direct R-2 resolution. Both BDs are v11-realistic-ot fixture surface work and share the same dependency on BD-164 helpers; combining them avoids artificial separation. Per `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §12.1 + §8.7 + Addendum #1 §6.4 BD table + PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.7.
Resolved: 2026-05-16 — combined with BD-160 in commit a57dd04 per Pack-Chat-direct R-2 resolution (v11-realistic-ot fixture per-entry tree extension via BD-164 helpers; round-trip byte-identical across all 3 project streams verified at build time); inline review/fix in commit 9c238ab (3 FIX: 2 SHOULD + 1 NIT). Broad batch review/fix in commit 479fef5 added test-v11-realistic-ot.sh integration test runner (33/33 PASS) closing the cross-BD integration-boundary gap.

---

**BD-169b — Per-entry split PM-only wording updates (PACK-CHAT.md row + README.md Repository Layout entries)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass; split from BD-169 per Addendum #1 §6.3
Status: Resolved
Blockers: BD-169
Unblocks: none
File/Symbol (PM-only — Pack Chat applies):
  - `PACK-CHAT.md` (file-access strategy table — two new rows at lines 38–47 per Addendum #2 §5.2 verbatim)
  - `README.md` (Repository Layout entries naming pack-side `/backlog/`, `/changelog/` and project-template-side `docs/project/{backlog,implementation-plan,changelog}/` per `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §4.4.3 + Addendum #1 §6.3)
Description: PM-only wording updates for per-entry decomposition; paired with BD-169 pack-product wording. Per `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.9 + §6.1 BD-169b sample text.
Resolved: 2026-05-16 — PM-only wording updates (PACK-CHAT.md two file-access strategy rows verbatim from Addendum #2 §5.2 + README.md Repository Layout pack-self per-entry tree entries for /backlog/ and /changelog/) landed in commit 27374b4. Pack Chat direct (no agent — all targets are PM-only). Project-template-side docs/project/{backlog,implementation-plan,changelog}/ entries already in README from earlier batch (BD-167 retro fix) — not re-duplicated.

---

**BD-169 — Per-entry split pack-product wording updates (PM-CHAT.md + STATUS.md disclaimer + MERGE-STRATEGY + MIGRATION-v10-to-v11 + audit-methodology SKILL.md scope + skill directives)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-167
Unblocks: none
File/Symbol (coder authors final wording per planner-deferred items in PLAN §5.8):
  - `project-template/docs/pack/PM-CHAT.md` (TWO additions: file-access strategy table row addition per Addendum #2 §5.4 verbatim; STATUS.md disclaimer guidance paragraph per Pack-Chat-direct R-3 resolution at integration parent §5.3 disclaimer shape)
  - `supporting-docs/MERGE-STRATEGY.md` (one paragraph per integration parent §4.4.3 explaining v11.0 per-entry-tree mirror-vs-source distinction)
  - `supporting-docs/MIGRATION-v10-to-v11.md` (~30-line section per integration parent §4.4.3 covering decomposition behavior + backup rollback + `--force-overwrite-mirror` semantics + BD-095 bridge)
  - `project-template/skills/audit-methodology/SKILL.md` (audit-scope rule extension per Pack-Chat-direct R-4 resolution: per-entry tree files in scope under auditor-docs rule 29; regenerated mirrors out of scope when per-entry tree present; auditor agent files NOT modified — skill is authoritative source per its own §66 + per `auditor.md` line 11-12)
  - `.claude/skills/pack-startup/SKILL.md` + `.codex/skills/pack-startup/SKILL.md` + `.gemini/commands/pack-startup.toml` (one-line directive per Addendum #1 §1.3)
  - `project-template/skills/pm-startup/SKILL.md` (canonical) + `.claude/skills/`, `.codex/skills/`, `.gemini/commands/` per-CLI mirrors (one-line directive)
Description: Pack-product wording updates for per-entry decomposition. Excludes PM-only edits (PACK-CHAT.md row + README.md Repository Layout — those land in BD-169b). Per `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §4.4.3 + Addendum #1 §6.3 + Pack-Chat-direct R-3 + R-4 resolutions + PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8. Auditor agent files (`auditor.md` / `auditor.toml` × 3 CLIs) are NOT modified per R-4 resolution — the audit-methodology SKILL.md is the authoritative source for audit-scope rules and the agent files delegate to the skill per `auditor.md` line 11-12.
Resolved: 2026-05-16 — pack-product wording updates (PM-CHAT.md additions A+B + MERGE-STRATEGY.md catch-all classifier paragraph + MIGRATION-v10-to-v11.md "Per-entry decomposition" section + audit-methodology rule 29 clarifications + pack-startup × 3 + pm-startup × 4 body directives) landed in commit cf67a96; inline review/fix in commit 62f9eec (5 FIX: 1 MUST pre-commit-hook reframe + 2 SHOULD + 2 NIT). Trinity rule observed for pack-startup × 3 and pm-startup × 4.

---

**BD-168 — `validate-pack.py` Check 32 (mirror-in-sync) + Check 33 (TOC-in-sync) + Check 34 (cross-reference integrity)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-164, BD-167
Unblocks: none
File/Symbol:
  - `scripts/validate-pack.py` (three new check functions appended after current Check 31 at line 2425 + new `STREAMS` constant; coder picks function names + STREAMS constant shape per Addendum #1 §9.1 + integration parent §18.2 #5)
  - `scripts/tests/test-validate-pack-checks-32-33-34.sh` (new test runner; coder picks placement vs folding into existing test surface per integration parent §18.2 #6)
Description: Three new validator checks per `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §10. Each is a Signal 4 trip per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2; THIS architect+planner pass IS the defense. Each SKIPs gracefully when per-entry tree is absent (per integration parent §10.5 backward-compat for pre-v11.0 clients). Pack-side scope only per integration parent §10.6. Per `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.6.
Resolved: 2026-05-16 — validate-pack.py Checks 32/33/34 + test-validate-pack-checks-32-33-34.sh runner landed in commit 6696182; retro review/fix in commit bd022e9 (11 FIX: 2 MUST + 5 SHOULD + 4 NIT; test suite expanded 46→65 PASS); broad batch review/fix in commit 479fef5 (33-checks arithmetic harmonization at 3 sites).

---

**BD-167b — Per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md PM-only directories list + CLAUDE.md pack-memory bullet + pack-* agent prompts × 15)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass; split from BD-167 per Addendum #1 §6.2
Status: Resolved
Blockers: BD-167
Unblocks: none
File/Symbol (PM-only — Pack Chat applies; trinity rule applies per trinity sets and pack-* agent set):
  - `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack root) — Key files line addition + Pack-memory mode-aware bullet per Addendum #1 §3.4
  - `project-template/CLAUDE.md` / `project-template/AGENTS.md` / `project-template/GEMINI.md` — Key files / Document locations line addition
  - `PACK-AGENTS.md` (lines 139–142) — PM-only directories list expansion per integration parent §6.4 + Addendum #1 §3.1 honest Signal 9 trip framing (NOT "refactor not expansion")
  - `.claude/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md` (5 files; Markdown bullet additions to "Inputs to read" block per Addendum #1 §1.4)
  - `.codex/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.toml` (5 files; TOML format per Addendum #2 §1 BLOCKER correction; same substantive addition placed inside existing `prompt = """..."""` per Addendum #2 §1.4)
  - `.gemini/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md` (5 files; Markdown with YAML frontmatter)
  - (STATUS.md disclaimer surface — RESOLVED per Pack-Chat-direct R-3 Option A: lives in BD-169 19g-pack PM-CHAT.md guidance; NOT in BD-167b)
Description: PM-only edits paired with BD-167 client artifact installs. Trinity rule applies for the trinity sets (pack-root × 3, project-template × 3) and pack-* agent set (5 agents × 3 CLIs = 15 files). Layer 1 + Layer 4 of the four-layer discoverability cascade per Addendum #1 §1. Honest Signal 9 trip framing per Addendum #1 §3.1 (THIS architect+planner pass IS the justification). Per `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.3.
Resolved: 2026-05-16 — PM-only edits landed in commit 8ba0164 (trinity Key files + PACK-AGENTS.md PM-only directories list + CLAUDE.md pack-memory bullet + pack-* agent prompts × 15 across 3 CLIs); retro review/fix in commit 8fac7d0 (N1 architect-doc sync + N3 forward-ref note + O1 gemini-planner trinity sync). Trinity rule observed for pack-root × 3 + project-template × 3 + pack-* agent set × 3 CLIs.

---

**BD-167 — Per-entry split client artifact installs (pack-product templates + install plumbing; absorbs BD-161)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-164
Unblocks: BD-165, BD-166, BD-168, BD-169
File/Symbol:
  - `project-template/docs/project/backlog/_rules.md`, `_intro.md` (canonical per-stream contract + preamble per sidecar §4 + Addendum #1 §3 mode-aware)
  - `project-template/docs/project/implementation-plan/_rules.md`, `_intro.md` (canonical per-stream contract + preamble)
  - `project-template/docs/project/changelog/_rules.md`, `_intro.md`, `_format.md` (canonical per-stream contract + preamble + project-changelog Format Rules per sidecar §3.5 — project-side asymmetry; pack changelog has no `_format.md` analog)
  - `scripts/migrate-v10-to-v11.sh` (`_v10_to_v11_install_v11_artifacts` extension at lines 144–148 to install new templates + BD-161 net-new SKILL.md installs; coder picks function placement per integration parent §3.1)
  - `scripts/lib/tracker-agent-read.sh` (`_tar_read_entry_flat` at line 153 extended to prefer per-entry file when tree exists; mode-aware per Addendum #1 §3.2; backward-compat for pre-v11.0 client repos via mirror fallback)
  - BD-161 net-new SKILL.md installs absorbed: `swift-concurrency-patterns`, `apple-swiftdata-patterns`, `protobuf-patterns` (BD-156/157/158) + `python-server-architecture`, `python-data-architecture`, `python-observability-patterns` (BD-162) per integration parent §17.2 + §8.14
Description: Ship pack-product canonical templates for per-entry trees + extend migrator install step to ship them + extend `tracker-agent-read.sh` `_tar_read_entry_flat` for per-entry-prefer-mirror-fallback. Includes BD-161 absorption for client artifact install batch. Per integration parent §17.2 + Addendum #1 §6.2 + `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.2.
Resolved: 2026-05-16 — pack-product canonical templates + migrator install plumbing + tracker-agent-read.sh extension landed in commit 142d160; retro review/fix in commit 80b025a (M1 contract regex + M2 per-stream-aware fallback + S1/N2/N3 nits). Absorbed BD-161 (net-new v11 SKILL.md installs).

---

**BD-166 — `init-project.sh` greenfield per-entry tree install (S11 stage extension)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-164, BD-167
Unblocks: none
File/Symbol:
  - `scripts/init-project.sh` (`stage_s11_v11_artifacts` at line 803 extended; coder picks stage extension vs new stage per integration parent §8.17 + §18.1 #5; PLAN recommendation: extend S11 with precondition check `[[ -d project-template/docs/project/<stream> ]]` per PLAN §10.6 R-6)
Description: Extend `init-project.sh` greenfield path to install per-entry tree skeleton + supporting files + regenerated empty mirrors. Reads canonical templates from `project-template/docs/project/<stream>/` (created by BD-167); writes to client `docs/project/<stream>/`. Per integration parent §8.17 + §9.3 + `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.5.
Resolved: 2026-05-16 — stage_s11_v11_artifacts extension landed in commit 91e497c (greenfield per-entry tree install via 2 new sub-steps: canonical templates copy + BD-164 helper-driven empty mirror+TOC regen, greenfield-only gated on CLASS == new-*); retro review/fix in commit b2b7e4c (6 FIX + 1 obs-routed-to-FIX; test-init-project.sh expanded 34→67 PASS).

---

**BD-165 — `_v10_to_v11_decompose_streams` 6th sub-operation in v10→v11 post-dispatch hook + `--force-overwrite-mirror` flag (BD-095 bridge)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-164
Unblocks: BD-167
File/Symbol:
  - `scripts/migrate-v10-to-v11.sh` (post-dispatch hook 6th sub-op addition at lines 144–148; coder picks function name / position per integration parent §3.1 + §18.1 #4; post-report hook gains v11.0 decomposition advisory paragraph per integration parent §8.18 sample text ~12 lines)
  - `scripts/lib/migrate-v10-to-v11/decompose.sh` (NEW adapter-private helper that wraps the BD-164 decompose helper)
  - `scripts/lib/migrator-core.sh` (mode-flag parser at lines 264–276 extension for `--force-overwrite-mirror` per Addendum #2 §4.5; default `_MIGRATOR_FORCE_OVERWRITE_MIRROR="0"` near `_MIGRATOR_MODE` initialization at line 121; usage line addition near lines 243–245)
Description: Add 6th sub-op to v10→v11 migrator's post-dispatch hook (currently 5 sub-ops at lines 144–148). Constraint: MUST run AFTER all 5 existing sub-ops so the decompose step reads final v11-shape monolithic files (per integration parent §3.1 constraint statement). Bridges to BD-095 two-phase `--dry-run` / `--apply` / `--resume` contract per Addendum #2 §4: dry-run reports divergence informationally (exit 0); apply/resume blocks with `EXIT_GATE_FAILED=31` (verified at `scripts/lib/migrator-core.sh:70`) unless `--force-overwrite-mirror` is passed. Post-report hook gains v11.0 decomposition advisory paragraph per integration parent §8.18 sample text (~12 lines, names rollback path). Per `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.4.
Resolved: 2026-05-16 — migrator 6th sub-op (_v10_to_v11_decompose_streams) + --force-overwrite-mirror flag (BD-095 bridge) landed in commit a5b4a6e; retro review/fix in commit c0723b7 (5 FIX + 5 observations; new test-migrate-v10-to-v11-decompose.sh runner at 45/45 PASS); broad batch review/fix in commit 479fef5 (stale Batch-22 wording swept to Batch-23 BD-102 dog-food).

---

**BD-164 — Per-entry split helpers (decompose + mirror generator + `_toc.md` regenerator)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Resolved
Blockers: BD-104 (rename), BD-128 (CI green), BD-131..BD-134 (tracker repairs), BD-111 (final tracker dependency surface per integration parent §17.2 + Addendum #1 §2.3)
Unblocks: BD-165, BD-166, BD-167, BD-168, BD-170
File/Symbol:
  - `scripts/lib/per-entry/` (NEW directory; coder picks file structure per integration parent §18.1 #2 + Addendum #1 §9 qualifier; PLAN recommendation: sub-directory with `decompose.sh`, `mirror-generate.sh`, `toc-regenerate.sh`, `_lib.sh` shared parser helper)
  - `scripts/tests/test-per-entry.sh` (NEW test runner: round-trip identity / empty-tree / supporting-file admission / regenerator divergence-warning behavior per integration parent §18.2 #1)
Description: Implement per-entry decomposition helpers per `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §6.2 (mirror generator) + §5.2 (TOC regenerator) + sidecar parent `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md` §3 (decompose helper). Library helpers in `scripts/lib/` per signal-6 carve-out (no new top-level scripts). Mirror generator + TOC regenerator + decompose helper share parsing logic (per sidecar §6.2). Decompose adds line-1 HTML-comment back-pointer per Addendum #2 §2 (no body-field back-pointer; superseded the body-field upgrade in Addendum #1 §1.2 because it violated V3.1-DELTA §3 A2 + sidecar parent §3.1's byte-additive invariant). Mirror generator strips line-1 HTML-comment when emitting (preserves byte-additive grammar invariant per integration parent §4.2). Helper reads `_rules.md` at runtime ONLY for the supporting-file basename list (per integration parent §7.5 split — entry regex + state vocabulary + grammar field labels are hard-coded). Test fixtures cover round-trip identity / empty-tree / supporting-file admission per integration parent §18.2 #1. Per `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.1.
Resolved: 2026-05-16 — per-entry helpers landed in commit ab51d76 (scripts/lib/per-entry/ with decompose.sh + mirror-generate.sh + toc-regenerate.sh + _lib.sh + test-per-entry.sh at 57/57 PASS); retro review/fix in commit 03d0dd9 (M1 CI wire + S1-S4 contract/regex + 7 nits/observations). Unblocked BD-165, BD-166, BD-167, BD-168, BD-170 (all now Resolved in this 19h flip).

---

**BD-163 — CI repair: declare fixture dependencies in test runners + reorder workflow + audit + document invariant (retroactive BD-147 CI fix)**
Type: TODO(version) — surfaced 2026-05-12 by parallel pack chat noting the Validate Pack workflow has been failing on v11-dev for 4 consecutive runs at the `migrator-skills tests (BD-147)` step. Root cause: BD-147 commit 0622c82 wired `scripts/test-migrator-skills.sh` into the workflow BEFORE the `build test fixtures (BD-115/116/117)` step; G1 has a silent, undeclared, unchecked dependency on `test-fixtures/v10-realistic-ot/` which is gitignored and only exists post-build. CI runner had no fixture → cryptic `cp: cannot stat ...` error → 4 consecutive red CI builds since BD-147.
Status: Resolved
Blockers: none — fix is mechanical
Unblocks: green CI on v11-dev (currently red since BD-147); BD-093 release pin (which requires green CI per EXECUTION-PLAN-V11.0.md §7); confidence in subsequent batch test results
File/Symbol: `scripts/test-migrator-skills.sh` (Change A: add `require_fixture <name>` helper + call at G1; document preconditions in header); `.github/workflows/validate-pack.yml` (Change B: reorder steps so all fixture-dependent tests run AFTER `build test fixtures`; add header comment documenting the invariant); `scripts/test-migrator-core.sh`, `scripts/test-migrator-manifest.sh`, `scripts/test-migrator-capability-translation.sh`, `scripts/tests/test-migrate-v10-to-v11.sh`, `scripts/tests/test-migrate-v10-to-v11-dry-run.sh`, `scripts/tests/test-migrate-v10-to-v11-gates.sh`, `scripts/tests/test-init-project.sh`, `scripts/test-persona-contracts.sh`, `scripts/tests/test-customization-preserve.sh` (Change C: audit each for similar silent fixture dependencies; apply `require_fixture` where applicable)
Description: BD-147 commit 0622c82 introduced `scripts/test-migrator-skills.sh` and wired it into `.github/workflows/validate-pack.yml` BEFORE the existing `build test fixtures (BD-115/116/117)` step. The new test runner's G1 (golden-snapshot regression for v10→v11 S5b helper) requires `test-fixtures/v10-realistic-ot/` — which is intentionally gitignored (build artifact, not source) and only materialized by `bash test-fixtures/build.sh --name v10-realistic-ot` in the later workflow step. CI runner has no built fixture when G1 runs → `cp: cannot stat ...` failure → red CI for every push since BD-147 (4+ consecutive runs).

**The real fix addresses the root cause** (silent undeclared dependency), not the symptom (CI step ordering). Three changes:

**Change A (test-runner self-documenting precondition):** add `require_fixture <name>` helper to `scripts/test-migrator-skills.sh`. The helper checks `test-fixtures/<name>/` exists and is a built fixture (presence of `.git/HEAD` or sentinel marker); if missing, exits with a clear error naming the missing fixture AND the exact command to build it (`bash test-fixtures/build.sh --name <name>`). G1 (and any future fixture-dependent G-section) calls `require_fixture v10-realistic-ot` before any fixture access. Test-runner header documents preconditions explicitly.

**Change B (CI workflow ordering with documented invariant):** reorder `.github/workflows/validate-pack.yml` so all fixture-dependent test runners run AFTER `build test fixtures (BD-115/116/117)`. Add a header comment block documenting the invariant: "Tests that depend on built fixtures (test-migrator-skills G1, persona contracts, etc.) must come AFTER `build test fixtures` step."

**Change C (audit other fixture-dependent test runners + apply pattern):** check every existing test runner for similar silent fixture dependencies. For each: either confirm no fixture dep (test against synthetic temp dir), OR apply `require_fixture` for explicit dep. This prevents the same anti-pattern recurring.

**Process gap fix (parallel):** post-push CI verification via `mcp__github__list_workflow_runs` should be mandatory (not relying on user to flag failures). Will be added to documented workflow rules in the rules-documentation work.

Single commit (changes A + B + C), single flip commit. validate-pack 31/31 PASS expected; CI green expected after push.
Resolved: 2026-05-12 in commit 422ec12 (fix) + d5b7d54 (BD-163 opening). Change A: require_fixture helper added to test-migrator-skills.sh + Preconditions header documented + G1 calls helper at top. Change B: validate-pack.yml step ordering reordered so migrator-skills tests runs AFTER build test fixtures + fixture manifest verify; new header comment block documents the invariant. Change C audit: of 9 sibling test runners, ONLY test-migrator-skills.sh had the silent-undeclared-dep anti-pattern (test-persona-contracts.sh already protected via build.sh die-check; 7 others synthesize own mktemp fixtures). Helper kept inline (YAGNI on shared lib — only one consumer). Fail-fast smoke verified (fixture moved aside → exit 3 with actionable error). validate-pack 31/31 PASS locally; **CI green confirmed via `gh run watch 25775179582` — all steps PASS in both validate + tests jobs on commit 422ec12.** First green CI on v11-dev since BD-147. Process gap fix (post-push CI verification) tracked for the rules-documentation work. Node.js 20 deprecation warning noted in CI annotations (informational, not blocking; tracked separately for BD-093 housekeeping or new BD before September 2026 deadline).

---

**BD-162 — Extend `deployment-python/SKILL.md` with metrics + tracing + sampling + alerting + retention rules (cross-cutting from BD-032 audit)**
Type: TODO(version) — surfaced 2026-05-12 from BD-032 audit cross-cutting note (audit-methodology rule 21 names metrics + tracing + sampling rate + alerting / SLO + log retention as observability sub-domains, but the loaded `deployment-python` skill carries only one observability rule (JSON logging) — rule's reach exceeds loaded skills' grasp)
Status: Resolved
Blockers: none (research not blocked by anything; pipeline-internal sequencing only — researcher → architect → planner → coder)
Unblocks: BD-032's cross-cutting concern fully closed; auditor-ops can enforce rule 21's observability sub-domains against actual rule content rather than against an empty skill; subsequent v12+ migrators can re-use the rule set as canonical Python observability guidance
File/Symbol: `project-template/skills/deployment-python/SKILL.md` (primary — append metrics + tracing + sampling + alerting + retention rule clusters); possibly `project-template/skills/python-server-architecture/SKILL.md` (some rules may belong here instead — architect decides); possibly NEW `project-template/skills/python-observability-patterns/SKILL.md` (if architect determines a separate `*-patterns` skill is the right home — would parallel BD-156 protobuf-patterns / BD-158 swift-concurrency-patterns precedent); `project-template/docs/pack/PLATFORM-SKILLS.md` (loading rule + skill inventory if a new skill lands); `scripts/init-project.sh` + `scripts/add-capability.sh` (if a new skill); `scripts/test-detect.sh` (if a new marker helper); `maintenance-docs/v11-implementation/RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (NEW — docs-researcher output); `maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (NEW — architect output); `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (NEW — planner output)
Description: Per BD-032 PACK-REVIEW (2026-05-12), `audit-methodology/SKILL.md` rule 21 was extended with metrics / tracing / sampling rate / alerting / log retention sub-domains, BUT `deployment-python/SKILL.md` carries only one observability rule (JSON logging). The auditor-ops agent loads `deployment-python` for D2=python deployments and would surface findings in the new sub-domains — but with no rule content to cite, those findings would be content-free. **This is content authoring at substantial scope — comparable to BD-156 protobuf-patterns (234 lines, 45 rules) or BD-158 swift-concurrency-patterns (418 lines, 66 rules).** Domain knowledge needs verification against authoritative external sources (OpenTelemetry Python SDK semantic conventions, Prometheus client library conventions, structured logging landscape, SLO frameworks, sampling strategies). **Pipeline:** (1) `pack-docs-researcher` surveys the landscape and outputs `RESEARCH-DEPLOYMENT-PYTHON-OBSERVABILITY.md` with citations + currency dates; (2) `pack-architect` designs the rule set (deployment-python vs python-server-architecture vs new `python-observability-patterns` skill — architect decides) and outputs `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md`; (3) `pack-planner` sequences implementation and outputs `PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md`; (4) `pack-coder` writes the rules per the plan. Each stage gets explicit user approval before spawning the next. Per BD-159 maintainability principle: substantive content authoring with architect+planner coverage is the canonical structural-change pattern (matches BD-156/157/158 in shape). v11.0 ship-readiness: BD-032 itself is Resolved with this BD-162 as the tracked follow-up; whether BD-162 must ship before v11.0 tag depends on user decision (recommended: defer to v11.1 unless BD-032 audit findings include observability findings the auditor cannot act on without BD-162's content — current BD-032 audit didn't flag any specific real findings, just the rule-vs-skill capacity gap).
Resolved: 2026-05-13 in commit 2a6f032 — NEW `project-template/skills/python-observability-patterns/SKILL.md` (527 lines, 65 rules across 11 sections §A–§K) closes the BD-032 cross-cutting auditor-coverage gap with full coverage of OpenTelemetry tracing + Prometheus metrics + structured logging + sampling + SLO/retention shape. Architect chose Option C (NEW skill at single canonical path) over options A (append to deployment-python) and B (split deployment-python + python-server-architecture); intersection-cell loading `D2=python ∩ (D3=server ∨ python_observability_marker_detected())` parallels BD-141/156/157 marker pattern. `deployment-python` rule 21 + `python-server-architecture` rule 8 replaced/extended with cross-references (placement vs content boundary preserved). Loaded by 7 agents (architect/coder/reviewer/auditor-architecture/auditor-code/auditor-ops/docs-researcher) with in-skill-body per-rule `(ops)`/`(arch)`/`(code)`/`(both)` owner-tag rubric per audit-methodology rule 21. PLATFORM-SKILLS.md counts: dimensional 19→20, total 34→35; +17 test-detect cases (T1–T17, 95/95 PASS); validate-pack PASSED — all checks clean (Check 31 + Check 27 extension green). Future-extension architecture (ARCHITECTURE §8.5): §A–§E + §I (OTel-side), §F–§G + Prometheus-shape part of §J (Prometheus-side), §H (foundation glue) preserve clean lift-out seams for future `python-otel-patterns` / `python-prometheus-patterns` / `python-structlog-patterns` siblings. Reviewer APPROVE 0 MUST-FIX 2 SHOULD-FIX 3 NIT all fixed in fix-pass per "no tech debt" rule (PLATFORM-SKILLS row placement + auditor-ops prose + IMPLEMENTATION-REPORT validator-string verbatim + rule 41 calibration tightening from literal-shape to durable-shape). Pipeline executed researcher → architect → planner → coder → reviewer → fix-pass with all live agents kept alive per agent-teams policy.

---

**BD-161 — v10→v11 migrator: install net-new v11 SKILL.md dirs (BD-156/157/158 + python-server-architecture / python-data-architecture split)**
Type: TODO(version) — surfaced 2026-05-12 from BD-116 POQ-BD-116-1 (persona-contracts found the v10→v11 migrator does NOT install net-new v11 SKILL.md directories created by the BD-141..BD-150 + BD-156..BD-159 cluster)
Status: Resolved
Blockers: none (all required v11 SKILL.md content already shipped — BD-156/157/158 + the python split)
Unblocks: client v10→v11 upgrade path includes new v11 skills automatically (no manual SKILL.md copy required); persona-contract migration assertion can be tightened to require post-migration v11 skill-inventory parity
File/Symbol: `scripts/migrate-v10-to-v11.sh` (NEW install stage that copies missing SKILL.md dirs from `project-template/skills/<name>/` per the v11 catalog); possibly extend `scripts/lib/migrator-skills.sh` (BD-147) with a reusable `migrator_skill_install` helper paralleling `migrator_skill_rename`; new test cases in `scripts/test-migrator-skills.sh` covering the install path; persona-contract update — `scripts/persona-contracts/contract-migration.sh` should verify post-migration projects have all v11 catalog skills present (or document why the contract doesn't enforce this)
Description: Per BD-116 POQ-BD-116-1 (2026-05-12), the persona-contracts test surfaced that the v10→v11 migrator does NOT install net-new v11 SKILL.md directories. Specifically missing: `apple-swiftdata-patterns` (BD-157), `swift-concurrency-patterns` (BD-158), `protobuf-patterns` (BD-156), and the post-split `python-server-architecture` / `python-data-architecture` SKILL.md dirs (created when the python skill was split during the BD-141..BD-150 reframe cluster). Today a client migrating from v10→v11 retains their v10 SKILL.md inventory; the new v11 skills are silently absent unless the client manually copies them from `project-template/skills/<name>/`. This is a real gap — the client is unaware of the new v11 capabilities and the PM chat will not load them. **Implementation:** add a new migrator stage (likely between S5b skill-rename and S6) in `scripts/migrate-v10-to-v11.sh` that enumerates skills from `project-template/skills/<name>/` against what's currently installed in the target's `<cli>/skills/` trees, copies any missing skill into all three per-CLI trees, and writes an advisory entry to the migrator report listing the newly-installed skills. The skill-installation logic should ideally extract into `scripts/lib/migrator-skills.sh` (BD-147 sibling) as `migrator_skill_install <skill-dir>` for v12+ reuse. Add test cases to `scripts/test-migrator-skills.sh` covering: (a) v10 client missing all 4 new skills → all 4 installed post-migration; (b) v10 client with a manually-copied subset → only the missing ones installed; (c) v10 client with `x-`-prefixed customizations preserved (BD-088 invariant). Update `scripts/persona-contracts/contract-migration.sh` to verify the post-migration v11 skill inventory matches the v11 catalog. **Additional UX fix bundled in this BD (surfaced 2026-05-12 by the BD-116 pack-coder via SendMessage roundtrip):** the v10→v11 migrator emits `warning: migration failed (exit 0)` when it actually pauses cleanly at the BD-101 reconciliation gate. The wording is misleading for a successful pause-and-wait state — first-time users will think the migration broke when in fact it's correctly waiting for sidecar resolution. Fix: change the message to something like `paused at BD-101 reconciliation gate — resolve sidecars and re-run with --resume` (or whatever phrasing matches the BD-101 gate UX in `scripts/lib/migrate-v10-to-v11/checkpoint.sh` / `gate-{1,2,3}-*.sh`). Locate the offending message via `grep -rn "migration failed" scripts/migrate-v10-to-v11.sh scripts/lib/migrate-v10-to-v11/`. Add a test case asserting the new wording.
Resolved: 2026-05-16 — absorbed into BD-167 per integration parent §17.2 + Addendum #1 §6.4 BD table. Net-new v11 SKILL.md installs (swift-concurrency-patterns BD-158, apple-swiftdata-patterns BD-157, protobuf-patterns BD-156, python-server-architecture, python-data-architecture, python-observability-patterns BD-162) ship via the BD-167 client artifact install plumbing landed in commit 142d160. The "migration failed (exit 0)" wording UX fix is tracked separately (not part of BD-161 absorption — surface for a future BD or batch cleanup).

---

**BD-160 — Wire `v11-realistic-ot` fixture (extend `_build_realistic_for_version v11` case dispatch + verify C2/C3 customizations apply on v11 surface)**
Type: TODO(version) — surfaced 2026-05-12 from BD-120 PACK-REVIEW NIT 2 (v11 dispatch path of `_build_realistic_for_version` is unexercised because no v11-realistic-ot fixture exists yet) + §3.1 follow-on (C2 ollama-strip and C3 x-agent payload paths reference v10-shape that needs re-verification on v11 surface)
Status: Resolved
Blockers: BD-114 (the dry-run-migration harness that consumes realistic-OT fixtures — already Resolved); BD-161 is a soft pre-req — if BD-161 lands first, the v11-realistic-ot fixture will reflect post-migration v11 state including the new SKILL.md dirs from BD-156/157/158 + python split
Unblocks: vN+1→vN+2 migration testing baseline once OT migrates to v11; exercises the BD-120 `_build_realistic_for_version v11` dispatch path (currently dead code); closes BD-120 NIT 2 carry-forward (PACK-REVIEW-BD-120 §6.2)
File/Symbol: `test-fixtures/build.sh` `FIXTURE_NAMES` array (add `v11-realistic-ot`); `_build_realistic_for_version` v11 case body (validate C2 ollama-strip path — `[[ -f ]]` guard at line 226 catches missing v11 file; validate C3 x-agent payload writes correctly to v11's `.codex/agents/`, `.claude/agents/`, `.gemini/agents/` dirs per the `migrator_target_surface_for_version v11` enumeration in `scripts/lib/migrator-core.sh` lines 459-513); `test-fixtures/manifest.txt` (regenerate for new fixture); `test-fixtures/README.md` (table row for `v11-realistic-ot`); possibly extend `scripts/persona-contracts/contract-migration.sh` to v11→v12 dry-run once a v12 migrator exists — likely deferred. Additional carry-forwards from `PACK-REVIEW-BD-120-RETRO.md` §5 (tracked here because BD-160 wires the helper consumption that closes both items): `scripts/lib/migrator-core.sh` `migrator_target_surface_for_version` docstring (line ~462) currently claims "Used by BD-120 fixture parameterization", which is no longer true post-BD-120-retro F1 fix (BD-120 dropped the docs claim because the helper is not actually sourced or called from `test-fixtures/build.sh`); update the docstring to reflect BD-160 as the helper's first real consumer when BD-160 wires the v11 dispatch. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2 currently describes BD-120 as the helper's first consumer in the architectural contract; update to reflect BD-160 (architectural intent shifted per BD-120 retro F1's option-(b) framing); may warrant a brief architect-pass review when BD-160 lands. Note: the BD-160 line-number reference to `[[ -f ]]` guard at line 226 will drift after BD-120 retro fix lands (which adds ~32 net lines to `build.sh` above line 226); BD-160's coder should re-grep for the actual `[[ -f ]]` site.
Description: Per BD-120 PACK-REVIEW NIT 2 (2026-05-12), the `_build_realistic_for_version` v11 dispatch path landed in commit 3fa3322 but is currently unexercised — no `v11-realistic-ot` fixture is wired. When the v11 fixture is needed (e.g., as the migration baseline for v12 development, or for vN+1→vN+2 dry-run testing), the C2 ollama-strip and C3 x-agent payloads (currently using v10-shape paths like `FakeOT` Package.swift fills and `.codex/config.toml` ollama strip) MUST be re-verified against v11's surface per `migrator_target_surface_for_version v11`. Specifically: (a) confirm v11's surface still has `.codex/config.toml` (or whether ollama is removed differently in v11); (b) confirm v11's per-CLI agent dirs (`.codex/agents/`, `.claude/agents/`, `.gemini/agents/`) accept the same x-agent file shape as v10. The `[[ -f ]]` guard at `test-fixtures/build.sh` line 226 catches missing files defensively, so calling `_build_realistic_for_version v11` today wouldn't crash — but the fixture would be functionally incomplete. **Implementation:** add `v11-realistic-ot` to `FIXTURE_NAMES`; extend the `_build_realistic_for_version` v11 case to source-clone from the v11 git tag, run `_run_v11_init` (or whatever the v11 init function is named), apply re-verified C2/C3 customization patterns; regenerate `manifest.txt` with the new fixture's deterministic SHA; document the new fixture in `test-fixtures/README.md` table.
Resolved: 2026-05-16 — combined with BD-170 in commit a57dd04 per Pack-Chat-direct R-2 resolution (v11 case dispatch in test-fixtures/build.sh _build_realistic_for_version; C2 ollama-strip + C3 x-agent payload re-verified on v11 surface; FIXTURE_NAMES + dispatcher + v11 case body + C4 version branch + migrator_target_surface_for_version docstring carry-forward updated to BD-160); inline review/fix in commit 9c238ab (3 FIX: 2 SHOULD + 1 NIT including ARCHITECTURE-BD-119.md §9.2 addendum naming BD-160 as the realized consumer per feedback_deferred_work_tracking).

---

**BD-159 — Codify skill / agent maintainability principle in pack memory + PACK-AGENTS pointer + PACK-CHAT triage rule**
Type: TODO(version) — surfaced 2026-05-11 from pack-architect maintainability design pass (`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`); per user direction shipped in v11.0 BEFORE BD-149 so the PLATFORM-SKILLS.md "Extending this file" naming-convention codification can reference the principle
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md must be reframed to provide the structural underpinning the principle defends — satisfied 2026-05-11 per commit ccb6b61)
Unblocks: BD-149 (BD-159 ships before BD-149 so the PLATFORM-SKILLS.md "Extending this file" section can reference the principle in a one-line pointer per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §4.4 cross-reference shape); guards against future skill / agent / dimension scope creep across the pack lifecycle
File/Symbol: `CLAUDE.md` (pack-repo root) `## Pack memory` § "Repo conventions" — append canonical maintainability principle bullet; `AGENTS.md` (pack-repo root) — same trinity edit; `GEMINI.md` (pack-repo root) — same trinity edit; `PACK-AGENTS.md` — append one-line pointer bullet; `PACK-CHAT.md` "Behavioral rules" — append negative-rule bullet preventing commit-staging beyond mechanical-edit threshold without architect justification
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §2 / §4 / §5, the maintainability principle for skills, agents, and their relationships is codified in pack-repo trinity `## Pack memory` § "Repo conventions" with one-line pointers in `PACK-AGENTS.md` and (via BD-149) `PLATFORM-SKILLS.md`. The canonical principle in 22 words: "Maintenance is mechanical, complete, reviewed, and rule-strict. Structural change — including rule changes — requires architect-then-planner, never convenience." Full canonical paragraph adds: client `x-` skills/agents preserve their dimension contracts (breaking escalates to structural with migrator coverage); workflow artifacts (architect/planner/coder/reviewer/auditor outputs) are exempted from the "no new top-level doc" structural signal during their batch's active development and sweep to `maintenance-docs/archive/vN/` at version ship as the final pre-tag step (Pattern B). PACK-CHAT.md gains a negative rule: Pack Chat does not stage commits for batches whose footprint exceeds the mechanical-edit threshold without an architect-pass justification recorded in the BD. Threshold conditions and worked examples are referenced via the canonical paragraph's pointer to `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3 (no duplicated content per the principle's own no-duplication clause). BD-159 is itself a mechanical change under its own principle (per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §8.3 sanity check): 5 file edits + BACKLOG entry; 0 new files in pack-product scope; 0 new top-level docs in pack-product or pack-ops scope; 0 new scripts; 0 new validate-pack checks. Sequencing: BD-159 ships before BD-149; BD-149 BACKLOG entry's Blockers field gains BD-159 in this same commit (per Step 6 below) AND BD-149's File/Symbol field gains the PLATFORM-SKILLS.md "Extending this file" pointer requirement (so BD-149's coder writes the L5 pointer per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §4.4 wording).
Resolved: 2026-05-12 — see commit 3d79edd (`feat: v11 — BD-159 codify skill/agent maintainability principle in pack memory + pointers`); pack-reviewer verdict Clean — ready for commit; sanity check PASSES (BD-159's commit footprint satisfies the principle's own §3.1 mechanical-edit threshold conditions on every dimension); NIT 1 (architecture doc enumeration lag — RESEARCH-*.md / *-DISCOVERY.md / docs-researcher missing from §3.2 condition 5) fixed in-session; NIT 2 (multi-line wrap of canonical phrase in PACK-AGENTS / PACK-CHAT) accepted as-is per reviewer recommendation; validate-pack 30/30 PASS.

---

**BD-158 — swift-concurrency-patterns skill — Modern Swift Concurrency (async/await, actors, Sendable) + Grand Central Dispatch (GCD)**
Type: TODO(version) — surfaced 2026-05-11 during BD-142 model-validation checkpoint discussion (concurrency rules currently scattered across `swift-best-practices` and `apple-architecture-core` without a dedicated home); per user direction added as v11.0 scope parallel to BD-149 like BD-156 / BD-157; hard blocker for BD-149
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md must be reframed before the new dimensional-skills row lands)
Unblocks: BD-149 (hard blocker per user direction); concurrency rules for Apple/Swift projects currently scattered (`swift-best-practices` mentions "Swift 6 strict concurrency" generically; `apple-architecture-core` mentions "actor isolation" — but no dedicated skill for the substantial async/await + actors + Sendable + GCD rule set); BD-153 (the v12-deferred Tier 0 `concurrency-architecture` skill — when it lands in v12, this Apple-Swift specialization will reference it for universal cross-language principles)
File/Symbol: NEW `project-template/skills/swift-concurrency-patterns/SKILL.md` (single canonical path per pack convention; per-CLI fan-out happens at install time via `init-project.sh stage_s4_skills`); MODIFIED `project-template/docs/pack/PLATFORM-SKILLS.md` — new row in dimensional-skills table (D1-implied for D1 ∈ {ios, macos}, parallel to `swift-best-practices` loading) + Full skill inventory update + dimensional count bump; MODIFIED `project-template/skills/swift-best-practices/SKILL.md` — strip the brief Swift 6 concurrency mention; cross-reference to `swift-concurrency-patterns` for the substantive rules; MODIFIED `project-template/skills/apple-architecture-core/SKILL.md` — strip the brief actor-isolation mention; cross-reference to the new skill; MODIFIED `scripts/init-project.sh` — `pack_skill_coverage_for()` swift case adds `swift-concurrency-patterns` to the unconditional Apple skill set; MODIFIED `scripts/add-capability.sh` — capability_skills update; MODIFIED `scripts/validate-pack.py` Check 31 (skill-cell consistency, added by BD-146) — must pass with new skill
Description: Modern Swift Concurrency (introduced in Swift 5.5, hardened in Swift 6 with strict concurrency checking) and Grand Central Dispatch (GCD via DispatchQueue / DispatchGroup / DispatchSemaphore / DispatchSource) are the two concurrency models in active use across every nontrivial Apple project. Per the BD-142 model-validation checkpoint discussion (2026-05-11), concurrency has substantial Apple/Swift-specific rules currently scattered across `swift-best-practices` (brief Swift 6 mention) and `apple-architecture-core` (brief actor-isolation mention) without a dedicated home. BD-158 creates `swift-concurrency-patterns` encoding: **Modern Swift Concurrency** — async/await semantics; structured concurrency (`async let`, TaskGroup, Task hierarchy); cancellation propagation; actor isolation (actor, `@MainActor`, GlobalActor, isolated parameters); Sendable conformance design; `@preconcurrency` boundaries; AsyncSequence / AsyncStream patterns; data-race avoidance under Swift 6 strict checking; bridging to legacy callback APIs via `withCheckedContinuation` / `withCheckedThrowingContinuation`. **GCD** — DispatchQueue type selection (.main, .global QoS, custom serial vs concurrent); DispatchGroup for fan-out/fan-in; DispatchSemaphore caveats (deadlock with `await`; prefer AsyncSemaphore); barrier writes for reader-writer patterns; QoS escalation rules; DispatchSource for kernel-event monitoring; do-not-mix anti-patterns (avoid GCD inside actors; avoid blocking `await` with `semaphore.wait()`); modernization guidance (when to migrate GCD code to async/await). Loads as **D1-implied** for D1 ∈ {ios, macos} per architecture §3.2 D1-implied semantics (matches `swift-best-practices` loading pattern) — every Apple project deals with concurrency, no marker predicate needed. Naming `swift-concurrency-patterns` matches architecture §7.10 naming convention (`*-patterns` for cross-cutting concerns; `swift-` prefix indicates language scope, parallel to `swift-best-practices`). Loaded by: architect, coder, reviewer, auditor-architecture, auditor-code. Relationship to BD-153 (v12-deferred Tier 0 `concurrency-architecture`): when BD-153 lands in v12 with universal concurrency principles (actor model, structured concurrency, cancellation propagation, backpressure — language-independent), `swift-concurrency-patterns` becomes a Swift-specific specialization that references BD-153 for cross-language principles and adds Swift/Apple-specific rules.
Resolved: 2026-05-12 in commit 8c117cf — NEW project-template/skills/swift-concurrency-patterns/SKILL.md (418 lines, 14 sections, 66 numbered rules) at single canonical path; swift-best-practices + apple-architecture-core concurrency mentions stripped + companion-skill cross-references; PLATFORM-SKILLS.md dimensional row (D1-implied — KEY DIFFERENCE from BD-156/157 which are intersection-loaded) + counts 18→19 / 33→34 + per-agent + worked examples; init-project.sh swift case extended (both branches); add-capability.sh language:swift row extended; NO marker helper (D1-implied); validate-pack 30/30 PASS; test-detect 64/0 PASS; test-init-project 34/0 PASS; reviewer APPROVE no defects.

---

**BD-157 — apple-swiftdata-patterns skill — SwiftData object-store rules for Apple platforms**
Type: TODO(version) — surfaced 2026-05-11 during BD-142 model-validation checkpoint discussion (worked example demonstrating the maintainability property — intersection-cell additions are mechanical); per user direction added as v11.0 scope parallel to BD-149 like BD-156 / BD-158; hard blocker for BD-149
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md intersection table must exist for the new skill row); BD-141 (predicate-helper precedent established `python_data_marker_detected()` pattern in `scripts/lib/detect.sh` that this BD's `swiftdata_marker_detected()` mirrors); BD-156 (parallel `*-patterns` skill establishes the intersection-cell + helper precedent for non-Python host languages)
Unblocks: BD-149 (hard blocker per user direction); standalone SwiftData usage in client projects currently uncovered (`apple-architecture-core` / `ios-architecture` / `macos-architecture` descriptions don't mention SwiftData explicitly; OT itself uses SwiftData)
File/Symbol: NEW `project-template/skills/apple-swiftdata-patterns/SKILL.md` (single canonical path per pack convention; per-CLI fan-out happens at install time via `init-project.sh stage_s4_skills`); MODIFIED `project-template/docs/pack/PLATFORM-SKILLS.md` — new intersection-table row + Full skill inventory update + dimensional/intersection count bump; MODIFIED `scripts/lib/detect.sh` — new `swiftdata_marker_detected()` function (markers: project source contains `import SwiftData` OR `@Model` macro usage in any `.swift` file OR `Package.swift` / `Podfile` lists SwiftData explicitly — note SwiftData is first-party so usually no explicit dep, the `import` and `@Model` markers are primary); MODIFIED `scripts/init-project.sh` — wire helper into `pack_skill_coverage_for()` Apple coverage; MODIFIED `scripts/add-capability.sh` — capability_skills row or comment cross-reference for the intersection loading; MODIFIED `scripts/validate-pack.py` Check 31 (skill-cell consistency, added by BD-146) — must pass with new skill
Description: SwiftData (iOS 17+ / macOS 14+) is Apple's modern declarative object-store API on top of SQLite, replacing CoreData for new development. Per the BD-142 model-validation checkpoint discussion (2026-05-11), SwiftData has substantial framework-specific rules that aren't covered by `apple-architecture-core` / `ios-architecture` / `macos-architecture`: `@Model` macro design (relationships, transient properties, attribute hints, deletion-rule semantics); `ModelContainer` and `ModelContext` lifecycle and threading rules (`@MainActor` isolation, sendable contexts, fetch on background context, child-context patterns); `FetchDescriptor` construction with type-safe predicates and sort descriptors; relationship traversal performance (N+1 prevention through `relationshipKeyPathsForPrefetching`); schema migration (`SchemaMigrationPlan` with lightweight vs custom `MigrationStage`); history tracking (`HistoryDescriptor` for change tracking); CloudKit sync integration (`ModelConfiguration` cloudKitDatabase); transactionality and `save()` semantics; query performance and index hints. BD-157 creates `apple-swiftdata-patterns` encoding these rules and loads it via the intersection table per architecture §3.7 (matches `python-data-architecture` and BD-156's `protobuf-patterns` patterns of intersection-cell loading). Predicate: `D1 ∈ {ios, macos} ∩ swiftdata-marker`. The new helper `swiftdata_marker_detected()` in `scripts/lib/detect.sh` parallels BD-141's `python_data_marker_detected()` and BD-156's `protobuf_marker_detected()`. Naming `apple-swiftdata-patterns` matches architecture §7.10 naming convention (`*-patterns` for cross-cutting framework concerns; `apple-` prefix mirrors `apple-architecture-core` for D1=apple-scoped clarity). Loaded by: architect, coder, reviewer, auditor-architecture, auditor-code. Companion future skills (NOT in v11.0 scope): `apple-coredata-patterns` (CoreData precedessor; many older Apple projects still use it), `apple-sqlite-patterns` (direct SQLite via GRDB or sqlite3). Demonstrates the maintainability property the BD-142 checkpoint validated: new skills under the 5+3 model are mechanical intersection-table additions, not architectural changes.
Resolved: 2026-05-12 in commit c2beaa0 — NEW project-template/skills/apple-swiftdata-patterns/SKILL.md (272 lines, 9 sections, 45 numbered rules) at single canonical path; PLATFORM-SKILLS.md intersection row + counts 17→18 / 32→33 + per-agent rows + worked example; new swiftdata_marker_detected() in detect.sh mirroring BD-156 pattern with literal "swiftdata-marker: yes|no" tight-contract output and boundary discipline (rejects @ModelAttribute / SwiftDataKit / etc.); init-project.sh swift) case wired; add-capability.sh comment cross-reference at deployment:apple; test-detect.sh +12 cases (52→64 PASS); validate-pack 30/30 PASS; reviewer APPROVE no nits.

---

**BD-156 — protobuf-patterns skill — extract Proto3 schema rules from grpc-patterns; standalone-usable via intersection table**
Type: TODO(version) — surfaced 2026-05-11 during BD-142 model-validation checkpoint discussion (gap in 5+3 model for standalone Protocol Buffers usage — Proto3 rules currently bundled inside `grpc-patterns` exclude non-gRPC scenarios); slotted before BD-149 per user direction so the `*-patterns` naming convention has a worked example AND so the standalone-protobuf gap closes before v11.0 ships
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md intersection table must exist for the new skill row); BD-141 (predicate-helper precedent — `python_data_marker_detected()` pattern in `scripts/lib/detect.sh` that this BD's `protobuf_marker_detected()` mirrors)
Unblocks: BD-149 (naming-convention codification — `protobuf-patterns` is a worked example of the `*-patterns` convention; per user direction BD-156 is a hard blocker for BD-149 so the convention can be codified with a concrete reference and the standalone-protobuf gap is guaranteed to close before v11.0 ships); standalone Protocol Buffers usage in client projects (binary file format, IPC payloads, non-gRPC RPC frameworks like Twirp / Connect, persistent storage formats, log formats — currently uncovered by any skill)
File/Symbol: NEW `project-template/skills/protobuf-patterns/SKILL.md` (single canonical path per pack convention; per-CLI fan-out happens at install time via `init-project.sh stage_s4_skills`); MODIFIED `project-template/skills/grpc-patterns/SKILL.md` — Proto3 schema-design rules removed and cross-referenced to `protobuf-patterns`; gRPC-specific rules (servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics) retained; MODIFIED `project-template/docs/pack/PLATFORM-SKILLS.md` — new intersection-table row for `protobuf-patterns`; updated `grpc-patterns` description in dimensional-skills table to drop Proto3 schema language; updated `### Dimensional skills (16)` header to `(17)` and Full skill inventory totals (31 → 32 total); MODIFIED `scripts/lib/detect.sh` — new function `protobuf_marker_detected()` (markers: project tree contains any `.proto` files OR dependency manifests list any of `protobuf`, `swift-protobuf` / `SwiftProtobuf`, `grpc-tools`, `grpc-swift-2`, or `protoc` tooling); MODIFIED `scripts/init-project.sh` — wire `protobuf_marker_detected()` into `pack_skill_coverage_for()` for proto-marker detection at scaffold time; MODIFIED `scripts/add-capability.sh` — capability_skills row or comment cross-reference for protobuf-patterns intersection loading; MODIFIED `scripts/validate-pack.py` Check 31 (skill-cell consistency, added by BD-146) — must pass with new skill in intersection table
Description: Per the BD-142 model-validation checkpoint discussion (2026-05-11), the 5+3 dimension model has a gap for standalone Protocol Buffers usage. Today Proto3 schema rules are bundled inside `grpc-patterns` (D4=grpc) per the skill description "Proto3 schema, grpc-swift-2, grpc.aio, cross-language conventions" — honest for the pack's primary gRPC use case but excludes standalone protobuf scenarios (binary file format, IPC payloads, non-gRPC RPC frameworks like Twirp / Connect, persistent storage formats, log formats). Standalone protobuf has substantial schema-design rules independent of gRPC: field numbering invariants (never reuse, gaps OK, `reserved` keyword for safe deletion, 1-15 are 1-byte tags); backward / forward compatibility (additions OK with new tag; type changes mostly forbidden; `reserved` required for safe deletion); Proto3 vs Proto2 differences (`optional`, default values, presence); `oneof` semantics and migration rules; well-known types (Timestamp, Duration, Any, Empty, FieldMask, wrapper types); map types (lower compat-set than messages); code-generation options (`option swift_prefix`, `option java_package`, `option go_package`); imports and package conventions. BD-156 creates a new `protobuf-patterns` skill encoding these rules and loads it via the intersection table per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3.7 (matches the existing `python-data-architecture` pattern of intersection-cell loading by language ∩ marker). Predicate: any host language (D2=python ∪ D1-implied Swift / Kotlin / Java / Go / etc.) ∩ "project has `.proto` files" marker (or dependency manifest lists protobuf tooling). The new helper `protobuf_marker_detected()` in `scripts/lib/detect.sh` parallels BD-141's `python_data_marker_detected()`. Naming `protobuf-patterns` matches architecture §7.10 naming convention for cross-cutting concerns (parallels `grpc-patterns`, `rest-patterns`, `security-patterns`). Effect on `grpc-patterns`: refocused on gRPC-specific rules; the Proto3 schema-design rules currently bundled there move to `protobuf-patterns`; `grpc-patterns` ships with a one-paragraph "see `protobuf-patterns` for schema rules; load both when gRPC is in use" pointer. Loaded by: architect, grpc-schema, coder, reviewer, auditor-architecture, auditor-code (same agent set as `grpc-patterns` since the rules apply to the same concern set). JSON / YAML / TOML are explicitly NOT given their own skills in this BD per the BD-142 model-validation discussion — their standalone rules are minimal and fold into `api-design` (Tier 0) and `rest-patterns` (D4=rest); a separate BD can be opened later if standalone schema work for those formats becomes a need.
Resolved: 2026-05-12 in commit af2f651 — NEW project-template/skills/protobuf-patterns/SKILL.md (234 lines, 9 sections, 45 numbered rules) at single canonical path (per pack convention; per-CLI fan-out happens via init-project.sh); grpc-patterns Proto3 rules stripped + companion-skill cross-reference + rule renumbering 44→33; PLATFORM-SKILLS.md intersection row + counts 16→17 / 31→32 + per-agent rows + worked examples; new protobuf_marker_detected() in detect.sh mirroring BD-141 pattern with literal "protobuf-marker: yes|no" tight-contract output; init-project.sh proto) case wired; add-capability.sh comment cross-reference at protocol:grpc; test-detect.sh +10 cases (42→52 PASS); validate-pack 30/30 PASS; reviewer APPROVE no nits.

---

**BD-150 — CHANGELOG v11.0 entry for skill-dimensions reframe + README skill-count refresh**
Type: TODO(version) — Batch 11 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 11)
Status: Resolved
Blockers: BD-146 (Check 31 must gate the new tables before the version-row CHANGELOG entry goes in), BD-148 (MIGRATION + MERGE-STRATEGY behavioral notes must exist before CHANGELOG quotes them)
Unblocks: v11.0 release-pin readiness (cross-cutting with BD-093 release pin); machine-readable skill counts in README are reconciled to post-reframe reality; downstream Phase 2A architect handoff (per `PLAN-SKILL-DIMENSIONS.md` §6)
File/Symbol: `CHANGELOG.md` v11.0 section (single entry referencing BD-141..BD-150 cluster as "skill-dimensions reframe — 5 dimensions + Tier 0 + intersection + trigger tables; behavioral note per `MIGRATION-v10-to-v11.md`"); `README.md` skill-count mentions ("30 skills" / "31 skills" instances must be reconciled to the post-reframe count); `README.md` v11.0 row in version table picks up the reframe BD references
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 11, the closing batch of the skill-dimensions reframe lands the CHANGELOG entry plus README skill-count refresh. Single CHANGELOG.md v11.0 entry referencing the BD-141..BD-150 cluster. README.md "30 skills" / "31 skills" mentions reconciled to the post-reframe count (which depends on whether the python split BD landed before or after the count was last touched — implementor verifies via `grep -n "skill" README.md`). README v11.0 row in version table picks up the reframe BD references. Critical-path gating per `PLAN-SKILL-DIMENSIONS.md` §1: BD-146 (Check 31 internal-consistency gate) and BD-148 (MIGRATION + MERGE-STRATEGY behavioral note) must have shipped first.
Resolved: 2026-05-12 in commit c30fa36 — CHANGELOG.md v11.0 Scope C section covers BD-141..BD-150 cluster + behavioral note + Check 31 + 3 new *-patterns skills + BD-119/144/147 framework work; README.md skill count 30 → 34 with subsection breakdown reconciled to PLATFORM-SKILLS.md Full skill inventory total + v11.0 row in version table extended with cluster references + archive description updated; Pattern B archive sweep moved 78 per-batch IMPLEMENTATION-REPORT-* / PACK-REVIEW-* / AUDIT-* / RESEARCH-* / *-DISCOVERY artifacts to maintenance-docs/archive/v11/ (durable design docs ARCHITECTURE-* / PLAN-* / EXECUTION-PLAN-* retained in v11-implementation/); validate-pack 31/31 PASS (Check 31 reports 34 skills consistent).

---

**BD-149 — PLATFORM-SKILLS.md "Extending this file" naming convention codification (no skill renames)**
Type: TODO(version) — Batch 10 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 10)
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md must be reframed before the "Extending this file" section can codify the new convention); **BD-156, BD-157, BD-158 (HARD BLOCKERS per user direction 2026-05-11 — three new `*-patterns` skills must exist before BD-149 ships so the naming convention has worked examples AND so the standalone-protobuf / SwiftData / Swift-concurrency gaps close before v11.0 ships; this guarantees these BDs are not lost / forgotten / deferred)**; **BD-159 (HARD BLOCKER per user direction 2026-05-11 — maintainability principle must be codified in pack memory before BD-149 adds the PLATFORM-SKILLS.md "Extending this file" pointer to it)**
Unblocks: BD-155 (the v12 enforcement migration — cannot rename existing skills to comply with a convention that has not yet been codified)
File/Symbol: `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" section (NEW or extended; documents the four-suffix naming convention AND adds a single-line cross-reference to the maintainability principle in pack-repo trinity `## Pack memory` § "Repo conventions" per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §4.4 cross-reference shape — recommended wording: "**Maintainability rule.** Adding a new skill is a mechanical edit when it fits the existing dimensions, patterns, and naming conventions documented above. See the pack-repo trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory`) for the full mechanical-vs-structural threshold and the client `x-` preservation rule.")
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10, the skill catalog has four suffixes in active use: `*-best-practices` (`swift-best-practices`, `python-best-practices` — language style); `*-language` (`c-language`, `cpp-language`, `objc-language` — language structure where ownership / memory / interop dominate); `*-architecture` (`ios-architecture`, `macos-architecture`, `python-server-architecture`, `python-data-architecture`, `apple-architecture-core` — platform-specific structural rules); `*-patterns` (`grpc-patterns`, `rest-patterns`, `security-patterns`, and the new `protobuf-patterns` per BD-156, `apple-swiftdata-patterns` per BD-157, `swift-concurrency-patterns` per BD-158 — cross-cutting concerns). The convention is not enforced; BD-149 documents it explicitly in PLATFORM-SKILLS.md "Extending this file" section per architecture §7.10 recommended disposition. Existing skills are NOT renamed in v11.0 — the cost of breaking external references outweighs the consistency benefit at this point; new skills must follow the convention. **BD-156 (`protobuf-patterns`), BD-157 (`apple-swiftdata-patterns`), and BD-158 (`swift-concurrency-patterns`) are hard blockers per user direction 2026-05-11** — the three new skills are worked examples of the `*-patterns` convention and ensure the standalone-protobuf, SwiftData, and Swift-concurrency gaps (surfaced during BD-142 model-validation checkpoint) all close before v11.0 ships. Per BD-159 (`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §4.4), BD-149 also adds a single-line cross-reference at the end of the "Extending this file" section pointing readers to the maintainability principle in pack-repo trinity `## Pack memory` (where the full mechanical-vs-structural threshold and the client `x-` preservation rule live). Enforcement migration (renaming existing non-compliant skills) is deferred to v12 (BD-155).
Resolved: 2026-05-12 in commit 09b609a — PLATFORM-SKILLS.md "Extending this file" section extended with new "### Naming convention for new skills" subsection (4 suffix bullets with worked examples + BD-156/157/158 cited as recent *-patterns examples + v11.0 no-renames stance with BD-155 v12 follow-on + ambiguity tie-breaker for dominant-content suffix); closing **Maintainability rule.** blockquote uses BACKLOG-spec wording verbatim pointing to pack-repo trinity ## Pack memory § "Repo conventions"; +39/-0 lines additive only; validate-pack 31/31 PASS; reviewer APPROVE no nits.

---

**BD-148 — MIGRATION-v10-to-v11.md + MERGE-STRATEGY.md skill-model-changes documentation**
Type: TODO(version) — Batch 9 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 9)
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md reframe must exist before MIGRATION + MERGE-STRATEGY can describe the change), BD-143 (trinity prose must be updated before MIGRATION can reference the new Skill-loading section)
Unblocks: BD-150 (CHANGELOG entry references the MIGRATION + MERGE-STRATEGY behavioral notes); v11.0 release-pin readiness on the migration-doc surface
File/Symbol: `supporting-docs/MIGRATION-v10-to-v11.md` (new "Skill model changes" section documenting the reframe as a behavioral note per architecture §7.8); `supporting-docs/MERGE-STRATEGY.md` (per-file matrix entry for PLATFORM-SKILLS.md updated to note the reframe; D5 monorepo gotcha per architecture §7.4; D2 reshape advisory per architecture §7.6); cross-link to BD-136 trinity-marker non-overlap (architecture §6.7); `project-template/docs/pack/PLATFORM-SKILLS.md` `## Custom agents` table column-header rename (deferred from BD-142 F3 — requires Procedure-5 coordination); `supporting-docs/INSTALL-PROCEDURES.md` Procedure 5 (column-write logic and any procedure prose referencing the deprecated `Tier 1 skills | Tier 2 skills` column convention)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 9, MIGRATION-v10-to-v11.md and MERGE-STRATEGY.md gain skill-model-change documentation. Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §7.8, the dimension reframe is a pack-product change masquerading as a doc change — PM chats re-read PLATFORM-SKILLS.md every time they generate a prompt, so the actual impact is minimal, but the v11.0 release notes and migration doc must call it out as a behavioral change, not a doc-only change. MIGRATION-v10-to-v11.md gets a new "Skill model changes" section. MERGE-STRATEGY.md per-file matrix entry for PLATFORM-SKILLS.md is updated; D5 monorepo gotcha (architecture §7.4 — "deployment skills load globally; agent prompts scope to component") and D2 reshape advisory (architecture §7.6 — "if you have locally edited PLATFORM-SKILLS.md, re-apply your edits manually") are documented. Cross-link to BD-136 trinity-marker non-overlap (architecture §6.7) confirms PLATFORM-SKILLS.md edits do not overlap with trinity Shape A / Shape B marker territory. **Includes BD-142 F3 deferred fix:** `## Custom agents` table column header `Tier 1 skills | Tier 2 skills` (PLATFORM-SKILLS.md line 510 in the v11.0 reframe state) reflects deprecated pre-v11 framing — replace with new-model-aligned headers (recommended: `Base skills | Dimensional skills`, but the exact convention is a Procedure-5 design decision). The rename touches a section that BD-142 preserved byte-identical to maintain BD-088 customization-preserve invariants; BD-148 is the right batch for it because it (a) coordinates with the Procedure-5 column-write logic in INSTALL-PROCEDURES.md and (b) ships in MIGRATION-v10-to-v11.md as part of the documented skill-model migration so client projects that already have Custom agents rows know to re-apply with the new header convention. See `maintenance-docs/v11-implementation/PACK-REVIEW-BD-142.md` §10 F3 for the original finding.
Resolved: 2026-05-12 in commit d197483 — MIGRATION-v10-to-v11.md "Skill model changes" H2 + MERGE-STRATEGY.md "Per-file notes" H2 with PLATFORM-SKILLS.md sub-section (D5 monorepo gotcha + D2 reshape advisory) + INSTALL-PROCEDURES.md Procedure 5.1 v11 column-write convention + PLATFORM-SKILLS.md ## Custom agents column header rename to "Base skills | Dimensional skills"; BD-088 invariant preserved (Check 25 PASS); validate-pack 30/30 PASS; reviewer APPROVE WITH NITS (both cosmetic IMPL-report nits, no code fix required).

---

**BD-147 — Extract S5b BD-035 rename helper into scripts/lib/migrator-skills.sh + Check 26 extension + BD-119 docs update**
Type: TODO(version) — Batch 8 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 8 + §7.2 expanded scope)
Status: Resolved
Blockers: BD-142 (the reframe must establish the post-v11 skill catalog before the rename helper is generalized; otherwise the API would be designed against the v10 skill set)
Unblocks: future N→N+1 migrations needing skill renames or splits (e.g., the v12 BD-155 naming-convention enforcement migration); cleaner BD-119 migrator-core composition (skill-rename becomes a reusable adapter rather than an ad-hoc S5b inline helper)
File/Symbol: NEW `scripts/lib/migrator-skills.sh` (extracts BD-035 rename helper into reusable `migrator_skill_rename` API per architecture §6.5); `scripts/migrate-v10-to-v11.sh` S5b stage (rewritten to call the extracted helper); `scripts/validate-pack.py` Check 26 extension (recognizes the new lib in the migrator-core sourcing graph); `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` (docs update describing `migrator-skills.sh` as a sibling to `migrator-core.sh`); golden-snapshot fixture in `test-fixtures/v10-realistic-ot/` (pre-extraction migrator S5b output state-dir, used as behavior-equivalence baseline per BD-035 regression risk in `PLAN-SKILL-DIMENSIONS.md` §4.5)
Description: Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.5 and `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 8 + §7.2 expanded scope, the BD-035 rename helper currently lives inline in the `scripts/migrate-v10-to-v11.sh` S5b stage. Extracting it into `scripts/lib/migrator-skills.sh` makes it reusable for future N→N+1 migrations needing skill renames or splits (notably the v12 BD-155 naming-convention enforcement migration). New API: `migrator_skill_rename <old-skill-dir> <new-skill-dir> [<advisory-text>]` plus a future `migrator_skill_split` for one-to-many cases (forward-declared; BD-035 only needs rename in v11.0). S5b is rewritten to call the extracted helper. Behavior-equivalence test per `PLAN-SKILL-DIMENSIONS.md` §4.5 mitigation: golden-snapshot the migrator's S5b output state-dir against the v10-realistic-ot fixture pre-extraction; compare post-extraction byte-for-byte. validate-pack.py Check 26 (BD-119 migrator-core sourcing graph) extended to recognize `migrator-skills.sh`. ARCHITECTURE-BD-119.md updated to describe the new sibling library.
Resolved: 2026-05-12 in commit 0622c82 — scripts/lib/migrator-skills.sh extracted as sibling lib (no copy-and-rewrite); migrate-v10-to-v11.sh S5b dispatches to extracted helper (golden-snapshot byte-equivalent: 5/5 sha256 match); Check 26 extended to 4 libs + 2 new sub-checks; ARCHITECTURE-BD-119.md §3.1 sibling-lib paragraph; new test-migrator-skills.sh (19/0 PASS) wired into CI; PLAN-BD-119.md inventory + README layout updated (reviewer NIT fixes); all 8 framework + v10→v11 test suites green; validate-pack 30/30 PASS; reviewer APPROVE WITH NITS (both nits fixed in same commit).

---

**BD-146 — validate-pack.py Check 31 (skill-cell consistency) + Check 27 extension**
Type: TODO(version) — Batch 7 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 7)
Status: Resolved
Blockers: BD-142 (Check 31 parses the new D1-D5 + Tier 0 + intersection tables — they must exist first), BD-143 (Check 31 also verifies agent files' "Skills to load" lists conform to the reframe-derived per-agent assignment; trinity prose update must precede)
Unblocks: BD-150 (CHANGELOG entry depends on Check 31 gating — proves the new tables are internally consistent before the version-row CHANGELOG goes in); ongoing CI gate for any future PLATFORM-SKILLS.md edit
File/Symbol: `scripts/validate-pack.py` NEW Check 31 (parses `project-template/docs/pack/PLATFORM-SKILLS.md`; verifies every existing SKILL.md under `project-template/skills/<name>/` (single canonical path per pack convention) appears in exactly one cell of the D1-D5 / Tier 0 / trigger-loaded / PM chat operational subsections; verifies no skill is missing or double-counted; verifies per-subsection header counts and total-line drift); Check 27 extension (extends agent-file `Skills to load:` validation to conform to per-agent assignment derived from the new tables per architecture §5)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 7 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §3-§5 + §3.7-§3.8, validate-pack.py gains Check 31 enforcing skill-cell consistency: every SKILL.md appears in exactly one cell across D1-D5 + Tier 0 + trigger-loaded tables; no orphan SKILL.md (present on disk but missing from PLATFORM-SKILLS.md); no phantom cell (referenced in PLATFORM-SKILLS.md but no SKILL.md on disk). Check 27 (per-agent skill-list validation, currently agent-file scoped) extends to verify the listed skills conform to the per-agent assignment derived from the new tables (architecture §5.1-§5.9). Per `PLAN-SKILL-DIMENSIONS.md` §4.3, the next free check number is 31; coder must `grep -nE "Check [0-9]+" scripts/validate-pack.py | tail` immediately before coding to verify still-free in case of mid-flight collision.
Resolved: 2026-05-12 in commit d994a33 — NEW Check 31 (check_skill_cell_consistency) parses 4 Full skill inventory subsections, enumerates SKILL.md at canonical project-template/skills/<name>/ path, detects 5 failure modes (orphan / phantom / double-counted / per-subsection header drift / total-line drift); D1-implied skills counted as one cell per PLAN §4.3; structurally-robust regex parser tolerates additive prose changes from BD-149. Check 27 extension validates "## Skills to load" agent-file lists against disk + PLATFORM-SKILLS.md known set (skips x-* agents, filters helper-function identifiers). Synthetic-orphan negative test PASS-FAIL-PASS verified; no artifact left behind. validate-pack 31/31 PASS; permission bits preserved (-rwxr-xr-x); reviewer APPROVE no defects (POQs 1/2/3 all accepted).

---

**BD-145 — init-project.sh — D1/D5 detection hint + python-data marker integration**
Type: TODO(version) — Batch 6 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 6)
Status: Resolved
Blockers: BD-141 (`python_data_marker_detected()` must exist for `pack_skill_coverage_for()` to call it), BD-142 (post-install hint points the PM chat at the new D1-D5 tables — those must exist first)
Unblocks: clean fresh-init flow under the reframed dimension model; eliminates the "init unconditionally lists `python-data-architecture`" detection inconsistency per architecture §7.5
File/Symbol: `scripts/init-project.sh` `pack_skill_coverage_for()` (line 219-228) — wires `python_data_marker_detected()` from BD-141 for the python row; post-install hint output at end of init pointing the PM chat at the new D1-D5 tables in PLATFORM-SKILLS.md
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 6, init-project.sh's `pack_skill_coverage_for()` is extended to (a) consult D1/D5 markers when listing applicable skills (per the reframed dimension model from BD-142), and (b) call `python_data_marker_detected()` from BD-141 for the python row so `python-data-architecture` is loaded conditionally rather than unconditionally. Per architecture §7.5 the current behavior at line 224 unconditionally lists `python-data-architecture` even for projects that are pure Python scripts with no data-access markers — a known detection inconsistency. Post-install hint at end of `init-project.sh` adds a one-liner pointing the PM chat at the new D1-D5 tables in PLATFORM-SKILLS.md so first-edit awareness lands at the right moment. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene mitigation: `ls -l scripts/init-project.sh` after editing to confirm `-rwxr-xr-x` exec bit unchanged.
Resolved: 2026-05-12 in commit 77d3560 — pack_skill_coverage_for() header reframed for 5+3 model + per-language D1/D5 hint comments + post-install prompt updated; validate-pack 30/30 PASS; exec bit preserved; reviewer APPROVE no nits.

---

**BD-144 — add-capability.sh D5 rename (role:apple-app → deployment:apple) + role:python-server intersection fix + v10→v11 migrator translation**
Type: TODO(version) — Batch 5 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 + §7.1 expanded scope)
Status: Resolved
Blockers: BD-142 (the reframe must establish D5 deployment surface and the new D2 ∩ D3 intersection model before add-capability.sh can be aligned)
Unblocks: clean `add-capability.sh` UX under the reframed dimension model; v10→v11 migrator translation stage so existing client `tracker.toml` / `add-capability` invocations keep working
File/Symbol: `scripts/add-capability.sh` — RENAME row `role:apple-app` → `deployment:apple` (D5 dimension assignment); NEW rows `deployment:linux-container` / `platform:android` / `platform:web-browser` / `platform:embedded-mcu` (forward-declared per `PLAN-SKILL-DIMENSIONS.md` §4.6 — SKILL.md files ship in Phase 3); FIX `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` (drops the obsolete `deployment-python`, per architecture §3.3 + §3.5 corrected intersection); `scripts/migrate-v10-to-v11.sh` NEW translation stage that maps any `role:apple-app` in client `tracker.toml` to `deployment:apple` per §7.1 expanded scope; golden-snapshot fixture for the migrator translation in `test-fixtures/v10-realistic-ot/`
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 and §7.1 expanded scope, add-capability.sh is realigned to the reframed dimensions: `role:apple-app` becomes `deployment:apple` (D5 — deployment surface, the missing dimension per architecture §3.5); new rows for `deployment:linux-container` (D5), `platform:android` / `platform:web-browser` / `platform:embedded-mcu` (D1 — runtime/OS substrate, per architecture §3.1) are added as forward-declared (the SKILL.md files ship in Phase 3 per `PLAN-SKILL-DIMENSIONS.md` §6; default to gating with directory-exists check + warning per §4.6 mitigation); `role:python-server` resolves to `python-server-architecture` + `python-data-architecture` and DROPS the obsolete `deployment-python` (per architecture §3.3 + §3.5 corrected D2 ∩ D3 intersection — the old `deployment-python` was a misnamed catch-all). v10→v11 migrator translation stage maps any `role:apple-app` in a client's existing `tracker.toml` (or other capability config) to `deployment:apple` so existing client invocations keep working. Per `PLAN-SKILL-DIMENSIONS.md` §4.2 permission-bit hygiene: `ls -l scripts/add-capability.sh scripts/migrate-v10-to-v11.sh` after editing to confirm exec bit unchanged.
Resolved: 2026-05-12 in commit f5900e1 — D5 rename + role:python-server intersection fix + forward-declared platform rows with directory-exists guard via warn_if_missing_skills + reciprocal mapping flip in detect.sh + new S5c capability-translation stage in migrator wired through BD-119 framework + new test-migrator-capability-translation.sh (12/12 PASS) + CI wiring; test-detect.sh 42/42 PASS; validate-pack 30/30 PASS; reviewer APPROVE WITH NITS (CI wiring nit fixed in same commit).

---

**BD-143 — Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list**
Type: TODO(version) — Batch 4 of skill-dimensions reframe (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 4)
Status: Resolved
Blockers: BD-142 (trinity prose points at PLATFORM-SKILLS.md as the authoritative reframe — the file must be reframed first)
Unblocks: BD-146 (Check 31 verifies agent files' "Skills to load" lists against the reframed per-agent assignment — those lists must be updated first), BD-148 (MIGRATION + MERGE-STRATEGY can reference the new Skill-loading section)
File/Symbol: `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` "Skill loading" section (trinity-replicated; reframe prose to 5-dimension D1-D5 + Tier 0 + intersection model; retire "Tier 1 / Tier 2" nomenclature); pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` parallel edits per Trinity rule; `audit-methodology/SKILL.md` rule 20 (cross-platform UI bullet seam extension per architecture §6.1, §6.3); `architecture-review/SKILL.md` skill-list update (4 trinity copies under `.claude/skills/` / `.codex/skills/` / `.gemini/skills/`; pack-repo template + project-template instances)
Description: Per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2 Batch 4 and `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.1 + §6.3, the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) carry "Skill loading" prose that must be re-aligned to the reframed 5-dimension model; "Tier 1 / Tier 2" nomenclature is retired (per architecture §3.6-§3.9 the new model is Tier 0 base + D1-D5 dimensions + trigger-loaded). Trinity rule applies: project-template trinity AND pack-repo trinity get the parallel edit in the same set of changes (pack-repo CLAUDE.md / AGENTS.md / GEMINI.md). audit-methodology/SKILL.md rule 20 extended for the cross-platform UI bullet seam (per architecture §6.3 — the rule currently has Apple-specific UI accessibility hardcoded; extension lets the auditor consume PLATFORM-SKILLS.md to find applicable UI skills per architecture §7.7). architecture-review/SKILL.md skill list updated under all four trinity copies. Per `PLAN-SKILL-DIMENSIONS.md` §4.1 trinity-violation mitigation: verification step requires `diff` between every pair of trinity files in the section body and `diff` between every pair of architecture-review SKILL.md copies; Check 9 (init-project structure) and Check 18 (trinity H2 parity) enforce structurally.
Resolved: 2026-05-12 in commit af66c62 — template trinity 5+3 framing block (3 files) + audit-methodology rule 20 cross-platform UI checklist sub-bullet + architecture-review SKILL.md line-7 parenthetical (4 copies); pack-repo trinity skipped per spec escape clause (no `## Skill loading` section); validate-pack 30/30 PASS; trinity diffs show only per-tool path variation; reviewer APPROVE WITH NITS (planner-doc nits only, no code fix required).

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
Resolved: 2026-05-11 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-139.md`. All 5 findings PASS. F-1 (MAJOR): added Group 5 with 4 BD-104 cases to `scripts/tests/test-migrate-v10-to-v11.sh`; test count 39 → 43. F-2 (MINOR): `supporting-docs/MIGRATION-v10-to-v11.md` stage table now distinguishes S4a (rename) and S4b (relocate) with a lead-in note; exit-code table updated to reflect the merged S4 framework stage. F-3 (MINOR): banners in `scripts/migrate-v10-to-v11.sh` relabeled to `S4a (rename)` / `S4b (relocate)` with sub-stage prefixes in fail_stage messages (`S4a-rename:` / `S4b-relocate:`); the `fail_stage S4` arity is preserved so the BD-095 sentinel (`stage-S4.done`) and exit code 24 stay stable. F-4 (NIT): added `info "git mv hint (taking untracked-fallback branch): $mv_stderr"` to surface the captured stderr in the BD-104 fallback branch. F-5 (NIT): clarified `BACKLOG.md` BD-104 Resolved line — the "179" figure is point-in-time at commit `ef20113`; the audit's "181" represents legitimate post-commit BACKLOG growth (BD-138 + BD-139 entries themselves added new references), NOT an allowlist defect. Validator: 30 checks PASS. All test suites green: 43/43 + 19/19 + 12/12 + 40/40. Co-shipped with BD-101 (Batch 13 part 2) — both ran in parallel under separate pack-coder agents; both edits to `scripts/migrate-v10-to-v11.sh` coexist line-disjoint.

---

**BD-138 — Schedule BD-136 implementation as a v11.0 batch (no v11.1 deferral)**
Type: TODO(version) — surfaced 2026-05-10 during v11.0 plan review (no batch was scheduled for BD-136 implementation despite BD-136 being a v11.0 ship-gate item per user direction)
Status: Resolved
Blockers: none
Unblocks: BD-136 implementation actually happens in v11.0; downstream Batch 22 (BD-100 final audit) and Batch 23 (BD-102 dog-food) can rely on the marker-aware merger being live
File/Symbol:
  - `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` — insert new **Batch 21b** for BD-136 implementation between Batch 21 (auditor agents) and Batch 22 (BD-100 final audit). Batch 21b is sequential (4 sub-commits — see scope below). Update Batch 22 (BD-100) audit scope to include BD-136 verification. Update Batch 23 (BD-102) to specify dog-food MUST exercise the marker-aware merge path.
  - `BACKLOG.md` — this entry (BD-138) flips to Resolved in the same commit as the EXECUTION-PLAN amendment.
Description: BD-136 currently has spec (3 amendments) but no scheduled implementation batch. Without a batch slot it would default-slip to v11.1. User direction (2026-05-10): no v11.1 deferral — schedule it. Batch 21b lands BD-136 implementation in 4 sub-commits: (1) marker-aware merger in `scripts/lib/customization-preserve.sh` (or new sibling `marker-preserve.sh`) implementing L-1..L-10 + the override mechanism; (2) `scripts/validate-pack.py` new Check enforcing V-1..V-8 validator surface; (3) PM-CHAT.md authoring procedure section (P-1..P-8) + cross-references in INSTALL-PROCEDURES.md / SETUP-NEW.md / SETUP-EXISTING.md / init-project.sh post-install hint + seed Shape A marker pair in `project-template/{CLAUDE,AGENTS,GEMINI}.md` + `[CONDITIONAL]` retirement in canonical templates; (4) `scripts/tests/test-customization-preserve-bd136.sh` covering M-1..M-10 + add M-11/M-12 fixtures to `test-fixtures/`. Each sub-commit is independently approve-able per the stop-before-commit rule. Existing M-8 fixture (`test-fixtures/v11-trinity-marker-prepped/`) becomes the round-trip golden the merger must reproduce byte-identical.
Resolved: 2026-05-10 — EXECUTION-PLAN-V11.0.md amended to insert Batch 21b for BD-136 implementation; Batch 22 (BD-100) and Batch 23 (BD-102) scope updated to reference BD-136 verification + marker-aware merge path. BD-138 was a scheduling-only BD; resolved in the same commit as the plan amendment. (Batch labels backstamped 2026-05-14 from Batch 20b/21/22 to Batch 21b/22/23 per Addendum #1 §2.2 renumber cascade — per-entry split inserted as NEW Batch 19, pushing existing 19+ up by one.)

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
  - `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-104.md` POQ-1 — mark resolved by BD-137.
  - `supporting-docs/MIGRATION-v10-to-v11.md` — audit for any reference to the harness; remove if present (low likelihood — the harness was internal pack tooling).
Description: BD-104's pack-side string sweep (Batch 12) included one rename in the migrator's stdout (a banner line referencing `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`). The BD-119 byte-equivalence harness (`scripts/test-migrator-behavior-preservation.sh`) compares the current migrator's stdout against a frozen baseline captured before the BD-119 refactor (pinned at SHA `d7b3f07`). The new banner is legitimate post-refactor surface drift that the harness cannot accommodate without redaction — and the harness header explicitly forbids redaction-based fixes (PLAN §13.3). The harness was created as a one-shot proof for the BD-119 refactor (which shipped clean); its purpose is fulfilled. Retiring it is the correct fix. Alternative considered: re-pin the harness baseline to current `HEAD` — rejected because future legitimate stdout changes would face the same problem repeatedly, and the harness's anti-redaction policy makes it perpetually fragile to surface evolution. Retirement is one commit (delete the script + remove its workflow invocation + paper-trail addenda).
Resolved: 2026-05-10 — direct execution by Pack Chat (no pack-coder agent needed; mechanical change). Deleted `scripts/test-migrator-behavior-preservation.sh` (entire file). Removed harness invocation from `.github/workflows/validate-pack.yml` (the 3-line step under `migrator behavior-preservation tests (BD-119)`). Removed harness row from `README.md` script-table. Updated `scripts/validate-pack.py` line 789 comment list (removed harness mention; added a one-liner noting BD-137 retirement). Trinity update across `.claude/skills/verification-harness/SKILL.md`, `.codex/skills/verification-harness/SKILL.md`, `.gemini/skills/verification-harness/SKILL.md`: removed harness from the example test list (line 14) and re-pointed the "behavior-preservation harness pattern" example reference (line 213-214) to `test-migrator-core.sh`. Appended addendum to BD-119 Resolved: line documenting the harness retirement and the surviving BD-119 test surface (`test-migrator-core.sh` 19/19 + `test-migrator-manifest.sh` 12/12 + validate-pack Check 26). Validator: 30 checks PASS. Tests: surviving BD-119 test runners green. CI tests job is now expected to be green on next push (the BD-104 known-temporary failure goes away with this commit).

---

**BD-136 — Trinity marker-section preservation pattern (Shape A + Shape B) + PM-chat authoring procedure**
Type: TODO(version) — surfaced 2026-05-10 during OT v10→v11 trinity prep; verified scope against `scripts/lib/customization-preserve.sh:145-179` (12-class file inventory), `supporting-docs/MERGE-STRATEGY.md`, and `supporting-docs/INSTALL-PROCEDURES.md` lines 472-479 (`[CONDITIONAL]` H2 convention)
Status: Open
Blockers: none (independent of remaining v11.0 batches; can land any time before Batch 23 BD-102 dog-food migration)
Position: Batch 20.5 — dedicated multi-commit architect-led batch between Batch 20 (STATUS.md + tracker reset) and Batch 21 (auditor agents). User-approved 2026-05-24. Multi-commit scope (trinity ×3 + customization-preserve.sh extension + PM-CHAT.md authoring procedure + INSTALL-PROCEDURES.md + SETUP-NEW.md + validator) warrants its own batch. Landing before Batch 21 lets the BD-109/BD-110 auditor agents potentially exercise marker-section validation. Also lands well before Batch 23 dog-food per the existing constraint.
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
  - `test-fixtures/README.md` — convention text (originally codified in BD-122 commit `400928a`) needs refinement to name the "frozen real-world snapshot" subclass distinct from "tagged release" / "current pack HEAD" subclasses; surfaced by the M-8 fixture introduction (carry-forward from `PACK-REVIEW-BD-122-RETRO.md` §5 methodology-friction item 2). Update the version-pinned bullet of the Naming convention section to enumerate three subclasses; ensure the M-8 `v11-trinity-marker-prepped` fixture's `Versioning` column value remains correct or pivots to a new explicit subclass label. Coder may pick the subclass naming.
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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-135.md`. Final names: `tracker.toml.pack-example` (pack root) and `project-template/tracker.toml.project-example` (client-side template source). Install destination at client deliberately stays as `tracker.toml.example` (unique-filename heuristic only applies inside the pack repo where both files coexist; client projects only ever have one tracker example file). Validator PASS (28 checks); HELP-FRAGMENT-TRACKER trinity byte-identity preserved.

---

**BD-134 — Tracker forward close retry-with-backoff (eliminate ~5% partial-write rate)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-7)
Status: Resolved
Blockers: none
Unblocks: cleaner BD-102 dog-food re-run; reduced post-init `gh issue` state drift
File/Symbol: `scripts/lib/tracker-provider-gh.sh` (close call); `scripts/lib/tracker-migrate-forward.sh` (end-of-init re-run-failed-closes step)
Description: Forward step-8 close has ~5% partial-write rate (3 of 56 named close failures observed: BD-021/022/023). Likely transient gh API rate-limiting. Add retry-with-backoff on individual close, OR end-of-init pass that re-runs failed closes once before reporting partial-write. Severity NIT — issues end up OPEN with `status:resolved` label instead of CLOSED.
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-134.md`. Approach (b): end-of-init re-run-failed-closes pass in `scripts/lib/tracker-migrate-forward.sh` (new step-8.4 helper) — composes cleanly with BD-132's `_tmf_wait_for_close_stabilization` (retry sweep runs first, then stabilization sees the post-retry close count). Retry bounds: `TMF_CLOSE_RETRY_MAX_ATTEMPTS=3` (1 original + 2 retries), `TMF_CLOSE_RETRY_BACKOFF_SECS="1 2 4"` exponential schedule; both env-overridable. Bounded by construction (helper iterates exactly `MAX_ATTEMPTS - 1` times — no recursion, no extension). New regression test `scripts/tests/tracker-bd134-close-retry-test.sh` 24/24 PASS across 3 groups (transient close recovers with 0 partial-writes; persistent close surfaces partial-write after exactly 3 attempts per id with proven bounded-loop assertions; helper-level isolation tests). All 7 pinned suites green: bd129 11/11, bd130 8/8, bd132 29/29, bd133 30/30, forward 126/126, reverse 93/93, roundtrip 39/39. Validator clean. **Closes BD-102 Phase A dog-food triage cluster: D-1..D-7 all addressed (D-3 was withdrawn at hand-off).**

---

**BD-133 — Reverse migration preserves BACKLOG.md header preamble**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-6)
Status: Resolved
Blockers: none
Unblocks: BD-102 dog-food (Phase A round-trip survives without content loss)
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh` BACKLOG emission; `scripts/lib/tracker-migrate-forward.sh` checkpoint snapshot OR `scripts/lib/tracker-sidecar.sh` header preservation
Description: Reverse migration strips ALL non-entry content from BACKLOG.md — the `# Backlog` title, "All planned improvements..." paragraph, `## How to use this file` section, type explanations, format references — replacing it with bare `# BACKLOG`. Per V1 §6.5 design intent project-specific content not representable in tracker should be sidecar-preserved; this header content qualifies. Reverse must preserve everything before the first `**BD-NNN — ...**` heading byte-identical, via checkpoint snapshot, sidecar, or refusal-to-overwrite policy after first round-trip. Test fixture required.
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-133.md`. Approach (b): NEW `scripts/lib/tracker-header-snapshot.sh` module (sidecar storage at `<repo-root>/.pack-tracker/backlog-header.snapshot`); reverse calls `tracker_header_snapshot_capture` before `_tmr_emit_backlog` and `tracker_header_snapshot_apply` after, prepending the snapshot to the entries-only body. First-write-wins semantics (capture is no-op if snapshot already exists) guarantee N round-trips don't degrade the preamble. Trivial preambles (whitespace-only or bare `# BACKLOG` from a prior reverse) are skipped to prevent bootstrap from a never-had-preamble repo locking in a bad value. Approach (a) (forward-time checkpoint snapshot) was rejected because it would have required editing tracker-migrate-forward.sh which BD-131 owns in this same Batch 9 — the sidecar approach has zero file conflict with BD-131. New round-trip test `scripts/tests/tracker-bd133-header-preservation-test.sh` 30/30 PASS across 4 groups (module API isolation, reverse-only round-trip, full forward→reverse via stateful fake gh, multi-cycle stability N=5). All existing tracker test suites green: reverse 93/93, roundtrip 39/39, forward 126/126 (BD-131 intact), bd132-race 29/29. Validator clean.

---

**BD-132 — BLOCKER: tracker disable/init close-step race destroys ~33% of BACKLOG entries**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-5)
Status: Resolved
Blockers: none
Unblocks: BD-102 dog-food (Phase A); v11.0 ship gate (silent data loss is unacceptable)
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh` reconstruct loop; `scripts/pack-tracker.sh` init/disable race detection; `scripts/lib/tracker-migrate-forward.sh` close-stabilization wait
Description: First `disable` invocation immediately after `init` exit reconstructed only 60 of 93 BD entries — 33 entries silently dropped. Hypothesis: `gh issue close` is eventually consistent; `disable` running mid-close sees inconsistent issue state and silently skips entries whose body or labels appear malformed mid-update. Workaround was poll `gh issue list --state closed --limit 200 --json number --jq length` until stable, then disable. Three-part fix required: (a) `init` waits for all close ops to stabilize before exit, (b) `disable` detects "init still racing" via `forward.checkpoint.json` freshness OR issue-state stability poll, (c) reverse loop's silent-skip path must at minimum WARN ("skipping X issues whose body did not parse — re-run"). Severity effective CRITICAL: a user who runs `init` then immediately `disable` (smoke test, change of mind) loses 35% of BACKLOG content with no warning. **BLOCKER for v11.0.**
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-132.md` + `IMPLEMENTATION-REPORT-BD-132-FIX-FOLLOW.md` (PACK-REVIEW-BD-132 8-finding fix-follow absorbed into the same commit). All three parts of the fix landed: (1) `_tmf_wait_for_close_stabilization` in tracker-migrate-forward.sh polls provider for closed entry-issues (label-scoped to `bd-entry`/`td-entry`/`phase-epic` so production repos with >200 unrelated closed issues do not trivialize the count) until the count is stable across two consecutive reads AND >= the closes attempted (bounded 30×2s = 60s, env-overridable; consecutive provider failures bounded by `TMF_STABILIZE_FAIL_LIMIT`); on stabilization timeout the forward checkpoint is preserved as a downstream race-detection signal; (2) `tracker_migrate_reverse_run` in disable mode refuses (without `--force`) when `forward.checkpoint.json` is present OR the mapping file's mtime is younger than `TMR_RACE_FRESHNESS_SECS` (default 60s, matching the stabilization ceiling so the windows do not gap). The mtime read uses Python3 `os.path.getmtime()` for unambiguous portability across macOS BSD and Linux GNU stat (the prior BSD/GNU stat-flag fallback was broken on Linux); (3) reverse-loop silent-skip → loud-failure: per-issue WARN with gh id + reason, refuses to write half-data into BACKLOG.md (returns 1 with `partial-write` typed error) unless `--force`. `cmd_disable` accepts new `--force` flag. New race-test fixture `scripts/tests/tracker-bd132-race-test.sh` 29/29 PASS (now exercises both the `provider_get fails` and `body missing pack-id marker` skip paths — the actual BD-102 Phase A failure mode). All 17 existing test suites green. Validator PASS. Honest risk assessment: silent loss is converted-to-loud-failure in every covered path on both macOS and Linux/CI; full prevention depends on Part 1's heuristic holding in production — Parts 2 and 3 are explicit safety nets that catch any race the wait misses.

---

**BD-131 — Set `forward_complete = true` at end of clean forward migration**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-4)
Status: Resolved
Blockers: none
Unblocks: correct `tracker_mode()` resolution (V1 §3.2); downstream tooling routes to tracker behavior reliably
File/Symbol: `scripts/lib/tracker-migrate-forward.sh` (or wherever final tracker.toml `[migration]` write happens); `scripts/lib/tracker-init.sh` if init owns the post-forward write
Description: After `pack tracker init --backend github --repo ... --no-interactive` succeeded (created tracker.toml, wrote 93 issues, wrote id-map.json + forward.checkpoint.json, closed 53 of 56 attempted closes), the `tracker.toml [migration]` section reads `forward_complete = false`. Per V1 §3.2 `tracker_mode()` resolves to "tracker" only when `mode.state = "tracker"` AND `migration.forward_complete = true`. Downstream tooling depending on `tracker_mode()` may incorrectly route to flat-file behavior. Fix: set `forward_complete = true` at end of clean forward. For partial-write cases (BD-134's 3-of-56 failure pattern), document semantics — does `forward_complete` mean "all closes succeeded" or "all issues created"? Recommend the latter since BD-134's fix will eliminate the close-failure case anyway.
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-131.md`. Fix landed in `tracker_migrate_forward_run` step 11 + `_tmf_update_tracker_toml` (writer takes `"true"|"false"` positional arg with defensive value-validation) + NEW helper `_tmf_verify_forward_complete` (defense-in-depth read-back; emits stderr WARN if on-disk value disagrees with what was written). Semantics: `forward_complete = true` iff all create operations succeeded (the strong signal for `tracker_mode()`); partial-close is BD-134's concern, not BD-131's. Any create failure (entry or phase epic) early-returns at the create site so step 11 never runs and `forward_complete` stays at the init-time `false`. tracker-migrate-forward-test 126/126 PASS (was 111; +15 new asserts in Group 5 and added to 4.3). All other tracker suites green; validator clean.

---

**BD-130 — Wire `tracker_doctor_run` so `pack tracker doctor` works (BD-067 fix incomplete)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-2; live regression confirmed at HEAD `240867d`)
Status: Resolved
Blockers: none
Unblocks: BD-102 dog-food (operator can actually run `pack tracker doctor`); BD-097 audit accuracy (NOTE N-5 said all four verbs implemented — was wrong for `doctor`)
File/Symbol: `scripts/pack-tracker.sh` (sources scripts/lib/* but never `scripts/tracker-migrate.sh` where `tracker_doctor_run` is defined at line 167); options to fix: (a) move `tracker_doctor_run` from `scripts/tracker-migrate.sh` into `scripts/lib/tracker-*.sh` and source it; (b) have `pack-tracker.sh` source `scripts/tracker-migrate.sh`; (c) duplicate the function (rejected — DRY)
Description: BD-067 Resolved-line claims `pack tracker doctor` was wired. Live test on HEAD `240867d`: `bash scripts/pack-tracker.sh doctor` returns `scripts/pack-tracker.sh: line 165: tracker_doctor_run: command not found`. Function is defined in `scripts/tracker-migrate.sh:167` but `scripts/pack-tracker.sh` only sources `scripts/lib/*.sh` files (verified — see lines 29-53 of pack-tracker.sh). Recommended fix (a): relocate to `scripts/lib/tracker-doctor.sh` (or fold into existing `scripts/lib/tracker-init.sh` since init/doctor are sibling concerns) and add a source line in pack-tracker.sh.
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md`. Approach (a): extracted `tracker_doctor_run` into NEW `scripts/lib/tracker-doctor.sh` (203 lines, function body verbatim), sourced from both `scripts/pack-tracker.sh` and `scripts/tracker-migrate.sh`; inline definition in tracker-migrate.sh removed and replaced with pointer comment. Smoke-tested: `bash scripts/pack-tracker.sh doctor` from scratch dir now emits doctor-formatted output (`doctor: <target>` banner + WARN/INFO lines + completion summary), no shell error. New regression test `scripts/tests/tracker-bd130-doctor-wired-test.sh` 8/8 PASS. tracker-migrate-reverse-test groups 6.2 + 6.3 confirm legacy entry path still resolves the function. v11.0 BLOCKER count 1 → 0 after this commit.

---

**BD-129 — Tracker libs pass `--repo` to all gh invocations (don't depend on git remote)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-1)
Status: Resolved
Blockers: none
Unblocks: tracker init works for repos with non-GitHub remotes, internal mirrors, GHE-on-different-host, freshly-cloned repos before remote setup, monorepo subtree imports
File/Symbol: `scripts/lib/tracker-labels.sh:172` (`_tracker_labels_existing`), `scripts/lib/tracker-labels.sh:183` (`_tracker_labels_create`), every `_gh_run gh ...` call in `scripts/lib/tracker-provider-gh.sh` that doesn't pass `--repo`. Slug source: `scripts/lib/tracker-config.sh::tracker_repo_slug`.
Description: All gh invocations in tracker libs run without `--repo`. gh resolves slug from working repo's git remote — fails with "none of the git remotes configured for this repository point to a known GitHub host" for clones from local-path sources, non-GitHub remotes, or freshly-cloned repos. `pack tracker init` then aborts at `labels_ensure: cannot read existing labels (gh auth or network failure)` — misleading error. Fix: pass `--repo "$slug"` everywhere (slug already available via `tracker_repo_slug`); OR set `GH_REPO` env in dispatcher before any gh call (cleaner — single point of control). Recommend the env-var approach: set once in `scripts/pack-tracker.sh` cmd dispatcher, applies to every gh call below it.
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`. Approach (b): `GH_REPO` env-var export via new helper `tracker_gh_repo_setup` in `scripts/lib/tracker-config.sh`; called from `_gh_run` (covers 24 sites in `tracker-provider-gh.sh`) and from `tracker_labels_ensure` (covers 2 raw `gh label list`/`create` sites in `tracker-labels.sh`). 26 gh-invocation sites total routed through `GH_REPO` from active `tracker.toml`'s `backend.repo`. Helper is no-op when caller pre-sets `GH_REPO` (preserves test seam) or when no tracker config in scope. New regression test `scripts/tests/tracker-bd129-gh-repo-test.sh` 11/11 PASS — Group 3 reproduces the exact failure scenario (`git init` directory with no remote, run `tracker_labels_ensure`, verify all 46 expected gh calls succeed and every one carried `GH_REPO=owner/repo`). 10 tracker test suites = 566/566 PASS. Validator clean.

---

**BD-128 — CI test-suite repair: BD-080 Group 3 + v10-realistic-ot fixture + migrator collateral**
Type: TODO(version) — surfaced by current CI baseline (red on every push since v10.1 backport landed)
Status: Resolved
Blockers: none — but should land BEFORE BD-102 dog-food
Unblocks: green CI on `validate-pack.yml`; BD-102 dog-food run can rely on test-suite signal
File/Symbol: `scripts/tests/test-init-project.sh` (Group 3: 13 FAILs hunting for `S11 — v11 client artifacts`, `tracker.toml.example`, `pack-help.sh`, `detect.sh` post-BD-088/BD-119/BD-121); `test-fixtures/build.sh` (exit 31 building `v10-realistic-ot` — likely v10 tag unreachable in CI checkout OR builder needs BD-120 parameterization first); `scripts/test-migrator-behavior-preservation.sh` (collateral failure on missing fixture); possibly `.github/workflows/validate-pack.yml` (verify checkout fetches tags)
Description: CI `tests` job has been red since `19755b5` (v10.1 backport optimization pass). Three failing suites: (1) BD-080 init-project Group 3 — assertions reference v11 client artifacts in paths that BD-088/BD-119/BD-121 reorganized; either update assertions OR fix install paths. (2) `test-fixtures/build.sh --all --clean` exit 31 building `v10-realistic-ot` from the v10 git tag — checkout depth or tag-fetching issue in CI, OR builder needs BD-120 parameterization. (3) BD-119 migrator behavior-preservation — depends on fixture from #2. Triage and repair each. May spawn fix-follow BDs if any failure surfaces a deeper issue. **NOTE on sequencing:** if BD-128 repair turns out to require BD-120 (fixture parameterization), batch ordering must move BD-120 ahead of BD-128. Pre-flight check is the first task.
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-128.md`. Root cause: v10.1 added documentary PROMPT-TEMPLATES references in `project-template/docs/pack/PM-CHAT.md` orphan table, but `init-project.sh::blast_radius_sweep` exclude list was not updated to match (PM-CHAT.md sat alongside METHODOLOGY.md and INSTALL-PROCEDURES.md as legitimate documentation files referencing legacy names). Fix: added `PM-CHAT.md` AND `detect.sh` (uses PROMPT-TEMPLATES as a v10-shape negative marker) to the exclude list. v10-tag work-around: idempotent post-clone `sed` patch in `test-fixtures/build.sh::_setup_v10_pack_src` injecting the exclude into v10's frozen init-project.sh. Bonus: pack-coder also surfaced and fixed BD-135-induced baseline drift in `scripts/test-migrator-behavior-preservation.sh` (BASELINE migrator at SHA `d7b3f07` referenced the pre-rename tracker.toml.example path). All three failing suites now pass: test-init-project 34/34, build.sh --all --clean 5/5 fixtures with deterministic SHAs, test-migrator-behavior-preservation 15/15. BD-120 NOT a prerequisite — fixture build needed only the v10-tag sweep work-around, not parameterization.

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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-126-BD-127.md`

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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-126-BD-127.md`

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
Resolved: 2026-05-09 — see `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-125.md`. NEW `supporting-docs/DRY-RUN-MIGRATION.md` (199 lines — slightly over the ~150 target but all six BACKLOG-required sections covered). Cross-references added: README.md supporting-docs tree listing (+1 line) and MIGRATION-v10-to-v11.md "Before you start" checklist as new optional-but-recommended item 6 (+7 lines). OPTIONAL-FEATURES.md audited and left untouched (file scope is tool-specific opt-in features, not pack scripts; no existing dry-run mention to update). Every flag and exit code in the doc verified against as-shipped `scripts/dry-run-migration.sh --help` and source. Validator clean.

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
Resolved: 2026-05-09 — work shipped earlier; status flip in Batch 5 hygiene. See `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-124.md`.

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

**BD-187 — Standalone entry-type instruction doc for external-tool consumption**
Type: TODO(version) — surfaced 2026-05-22 from BD-186 groupings requirements triage; idea to capture for future scheduling per pack memory `feedback_deferred_work_tracking` (live forward-pointing surface anchor)
Status: Open
Blockers: Authoring blocker — BD-186 closes (REQUIREMENTS-GROUPINGS-V11.md lands; locks grouping shape). Backlog / phase / task shapes already settled in v11.0. Scheduling judgment (separate from authoring blocker) — recommend post-v11.1 groupings ship so the doc reflects shipped reality, but technically authorable any time after BD-186 closes.
Unblocks: Developers can hand the standalone doc to external tools (AI assistants, brainstorming systems, PMs in planning sessions, PRD authoring tools) to produce pack-compatible content without the external tool needing to ingest pack docs or learn pack internals.
File/Symbol:
  - NEW `supporting-docs/<filename-TBD>.md` — standalone reference doc; ships in pack repo. Filename + exact siting (supporting-docs/ vs project-template/docs/pack/) reserved for architect decision.
  - Pack-side awareness (architect-decided extent): cross-references in `supporting-docs/METHODOLOGY.md`, `project-template/docs/pack/OPTIONAL-FEATURES.md`, possibly `supporting-docs/QUICKSTART.md`
Description: A standalone reference doc capturing the pack's requirements + template structures for all entry types — backlog entries, phases, tasks, groupings. Developers hand this doc to external tools (AI assistants, brainstorming docs, planning sessions, PMs working outside the pack) as instructions for producing pack-compatible output.

  **Critical scope boundary:** the doc is OUTPUT (a reference users give to others), not INPUT (the pack does NOT consume externally-produced docs in this format — that would be ingest, which V11.1-DISCUSSION-GITHUB-PROJECTS.md §11 + BD-186 framing rejects). The pack SHOULD know about the doc (METHODOLOGY cross-reference, OPTIONAL-FEATURES row) but MUST NOT require it for any pack-internal operation.

  **User-facing value:** developers using external tools for brainstorming / PRDs / journey design / sprint planning can ensure their work is pack-compatible without needing to learn pack internals OR adopt the pack as the source-of-truth for that external work.

  **Out of scope (clarify upfront so future architect doesn't expand):**
  - Pack-side parsing of externally-produced content following this format (that's ingest; not in this BD)
  - Automated round-trip between external tools and pack
  - Deep integration with any specific external tool (Notion, Linear, Productboard, etc.)
  - The doc is reference material; how external tools consume it is the external tool's concern

  **Position:** v11.1+ deferred — see EXECUTION-PLAN-V11.0.md §1.6 (Group 4 deferred-to-v11.1+ list). User-approved 2026-05-24. Scheduling: starts after v11.0 ships and v11.1 cycle begins; the standalone doc benefits from groupings implementation reality before authoring (currently shipping types: backlog / phase / task; groupings ship in v11.1+ per BD-189).
Resolved: n/a

---

**BD-188 — Phase-Iteration sprint view (single all-phases tracker Project sliced by Iteration field)**
Type: TODO(version) — surfaced 2026-05-22 from BD-186 groupings requirements triage; V11.1 §13 row Y-6 optional capability deferred from v11.1 groupings scope
Status: Open
Blockers: Authoring blocker — BD-186 closes (REQUIREMENTS-GROUPINGS-V11.md locks grouping shape) AND v11.1+ groupings implementation lands (provides tracker projection infrastructure this BD builds on). Scheduling judgment — recommend post-v11.1 groupings ship + observed user demand for sprint-board view; not blocking v11.1.
Unblocks: Teams that work in sprint cycles gain a pack-managed tracker view organized by Phase ID as Iteration values. Provides sprint-board-style temporal view orthogonal to grouping-based views (per V11.1 §7 footnote alternative — "single all-phases Project, sliced by Iteration field").
File/Symbol:
  - NEW `pack tracker iterations init` (or similar) verb in `scripts/pack-tracker.sh`
  - NEW `scripts/lib/tracker-iteration.sh` helper library
  - `tracker.toml` extension for `[iteration]` config section
  - Per-backend Iteration primitive support via BD-060 TrackerProvider abstraction extension
Description: V11.1 §13 row Y-6 optional capability: a single all-phases tracker Project sliced by Iteration field, where each Phase ID becomes an Iteration value. Sprint-board-style temporal view orthogonal to grouping-based Projects (per V11.1 §7 footnote alternative).

  **Distinction from grouping-as-Project:** Grouping-as-Project (BD-186 main feature) organizes phases by purpose/theme. Phase-as-Iteration organizes phases by sprint sequence. Both can coexist on capable trackers (one phase can live in multiple Projects with different Project semantics per V11.1 §8 dedup).

  **Critical scope boundary:** Per V11.1 §15 working assumption, "Phase-as-Project is rejected; Grouping-as-Project is the granularity" — this BD does NOT introduce phase-as-Project. Phases remain at L1 issue level per V3.3-DELTA §6.3. The Iteration FIELD/PRIMITIVE on a separate Project is what carries phase identity; phases themselves are not promoted.

  **Out of scope (for clarity):**
  - Changes to grouping primitive, grouping doc shape, or grouping per-entry tree (BD-186 territory)
  - Phase-as-Project promotion
  - Forced adoption — sprint view is opt-in
  - PRD/journey doc parsing (V11.1 §11 still applies)

  **Per-backend support (architect designs per #11 capability matrix at scheduling time):**
  - GH: Iteration field (custom field type per V11.1 §2.1) — native support
  - Linear: Cycle (separate primitive) — native support
  - Jira: Sprint (separate primitive) — native support
  - GitLab: Iteration (separate primitive) — native support
  - Forgejo / Gitea: no native Iteration primitive — requires emulation OR unsupported declaration per C7 graceful degradation
  - Redmine: no native Iteration primitive — same as Forgejo

  **Position:** v11.1+ deferred — see EXECUTION-PLAN-V11.0.md §1.6 (Group 4 deferred-to-v11.1+ list). User-approved 2026-05-24. Hard blocker on BD-189 v11.1+ groupings infrastructure (provides tracker projection infrastructure this BD builds on); cannot ship in v11.0. Scheduling additionally gated on observed user demand for sprint-board view. Per pack memory `feedback_deferred_work_tracking`, this BD entry IS the live forward-pointing anchor.
Resolved: n/a

---

**BD-189 — v11.1+ groupings implementation (architect/planner/coder cycle)**
Type: TODO(version) — surfaced 2026-05-23 from BD-186 sidecar wrap; live forward-pointing anchor for v11.1+ groupings core implementation per pack memory `feedback_deferred_work_tracking`
Status: Open
Blockers: v11.0 ships (then v11.1 cycle architect pass can start)
Unblocks: Per-capability implementation BDs that the v11.1 planner produces (BD-A through BD-K speculative per REQUIREMENTS-GROUPINGS-V11.md §5 v11.1 BD landscape); v11.1+ user-facing groupings feature
File/Symbol:
  - NEW `maintenance-docs/v11-implementation/ARCHITECTURE-GROUPINGS.md` (architect deliverable)
  - NEW `maintenance-docs/v11-implementation/PLAN-GROUPINGS.md` (planner deliverable)
  - Per-BD implementation surfaces TBD by planner (spans 17 capabilities)
  - PRIMARY INPUTS (read-only):
    - `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` (READ FIRST — orientation; 155 lines)
    - `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (primary input; 908 lines; 17 capabilities + design principles + scope decisions)
    - `maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md` (verified per-backend facts; 1762 lines; Pass-1 + Pass-2; §7 0-5 graded matrix)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md` (research methodology + open questions; 390 lines)
    - `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` (constraint baseline; 910 lines; already triaged but useful for deeper detail per touch-point)
    - `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` (original brainstorm; superseded but §10 grouping doc shape + §14 open questions remain useful context)
    - `maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` §1-§5 + §6-§8 + §10-§12 (canonical for GitHub Issues / gh CLI / MCP / Codex / Gemini integration patterns + token cost + migration prior art + OSS abstraction patterns + failure modes + lesser-known features + CLI version verification; tracker primitive details superseded per staleness redirect at top of that doc)
    - `pack-ops/BACKLOG.md` entries BD-186 (Resolved) + BD-187 (parking-lot, dependency: external-tool instruction doc) + BD-188 (parking-lot, dependency: sprint view) for adjacent-work context and dependency-chain visibility
    - `CLAUDE.md` `## Pack memory` (pack-repo-trinity rules; standard pack-agent context)
Description: Live forward-pointing anchor for the v11.1+ groupings core implementation work. All 17 capabilities of the groupings feature (per REQUIREMENTS-GROUPINGS-V11.md §4) defer to v11.1+ implementation; this BD captures the umbrella work that the v11.1 architect / planner / coder pipeline will break into per-capability BDs.

  Without this BD, the deferred work would lack a live forward-pointing anchor per pack memory `feedback_deferred_work_tracking` (BD-186 is Resolved, not a live anchor; the requirements artifact alone is "input" not a forward-pointing surface). This BD-189 satisfies the rule by providing the umbrella entry until the v11.1 architect/planner work decomposes it.

  **Inbound deferral (from BD-195 audit, 2026-05-31):** P-31l — `INTAKE-GROUPINGS-V11.md` self-flags unverified fidelity (a quality caveat, not contamination). Deferred out of the BD-195 v11.0 sweep as legit v11.1 groupings scope; address here (review fidelity, or rely on `REQUIREMENTS-GROUPINGS-V11.md`, canonical, which wins on conflict).

  **Pipeline (per REQUIREMENTS-GROUPINGS-V11.md §6):**
  1. Architect pass produces ARCHITECTURE-GROUPINGS.md
  2. User review
  3. Planner pass produces PLAN-GROUPINGS.md with per-BD breakdown
  4. User review
  5. Coder cycles per BD with reviewer cycles per pack memory `feedback_review_fix_one_cycle`
  6. **Migration architect/planner/coder pass is SEPARATELY scoped** per REQUIREMENTS-GROUPINGS-V11.md #16 SC16.10; the v11.1 architect will likely open it as a sibling BD (architect/planner/coder rigor required; NOT ad-hoc file copies)
  7. End-of-batch reviewer + per-BD status flips + MIGRATION-v11.0-to-v11.x.md landing + release pin

  **Scope boundary:** This BD covers the CORE groupings implementation per capabilities #1-#17 + #11 (#11 capability matrix for additional backends). BD-187 (entry-type instruction doc) and BD-188 (sprint view) are SIBLING parking-lot BDs for ADJACENT future work; they are NOT subsumed by BD-189.

  **Resolution:** This BD resolves when the v11.1 planner has produced per-capability BDs and the umbrella role is no longer needed (i.e., the children carry the work forward). Alternatively, it could resolve at v11.1 ship with all children Resolved. Architect/planner decides at scheduling time.

  **Position:** v11.1+ deferred — see EXECUTION-PLAN-V11.0.md §1.6 (Group 4 deferred-to-v11.1+ list). User-approved 2026-05-24 (title literally declares v11.1+ scope). Scheduling: starts when v11.0 ships and v11.1 cycle begins.
Resolved: n/a

---

**BD-190 — Comprehensive audit-vocabulary-gap sweep across pack-shipped files (post-H.9/H.10 cascade)**
Type: TODO(version) — surfaced 2026-05-24 during Batch 19c.H.10 audit-gap absorption pattern; trinity Filename uniqueness rule update at commit `1121b3d` formally classifies bare-version shorthand for pack-internal docs as same leak class as explicit `*.md` cites
Status: Resolved
Blockers:
  - Batch 19c.H.10 commits first (BD-190 must not double-touch H.10's 7 files; H.10 audit-gap absorption pass already closes that set) — RESOLVED: H.10 landed at commit `6e3e082` 2026-05-24
Unblocks:
  - Batch 19c.H.14 (Check 43 PASS at HEAD when it lands; basename-index class-test would fail on remaining bare-version refs)
  - Batch 19c.H.17 end-of-batch reviewer
  - v11.0 ship (Check 43 PASS is RELEASE-GATE-eligible)
File/Symbol:
  - PRIMARY INPUTS (read-only):
    - `maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` (audit snapshot — DO NOT modify; gap is documented in IMPL-REPORT not audit)
    - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9.md` §1.1 (H.9 audit-gap discoveries — 2 RESEARCH-* catches in main commit)
    - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9-NIT-1-fix.md` §1.1 (H.9 NIT-1 audit-gap — 12 bare-V3.3 + ARCHITECTURE-V3.3-DELTA cites in METHODOLOGY.md)
    - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.10.md` §7.2 + §7.4 (H.10 audit-gap discoveries — 19 absorbed: 18 bare-V3.X + 1 detect.sh L22)
    - `CLAUDE.md` `## Pack memory` > `### Repo conventions` > "Filename uniqueness heuristic" (extended bullet — leak-class formal definition)
  - SWEEP TARGETS (pack-shipped files at client install):
    - `project-template/**` (excluding H.9-swept per-entry skeleton tree at `project-template/docs/project/`; excluding H.10-swept 5 files: PM-CHAT.md + 4 pm-startup cluster + boundary-investigation/SKILL.md)
    - `supporting-docs/METHODOLOGY.md` (excluding H.9 NIT-1 fix at L1207 + 11 bare-V3.3 already-swept sites)
    - `supporting-docs/INSTALL-PROCEDURES.md`
    - `pack-ops/HELP-FRAGMENT-TRACKER.md` (S11 client install)
    - Also-excluded (already swept this batch): `scripts/lib/detect.sh` (H.10 Cat D drops at L335, L678 + audit-gap drop at L22)
  - DEFER-TO-SIBLING (don't sweep in BD-190; let the H.N coder catch and absorb in same-file-fit):
    - H.11 files (Cat C scope per PLAN H.11)
    - H.13 files (per-line fence scope per PLAN H.13)
Description:
  Comprehensive sweep to close all audit-vocabulary-gap leaks in pack-shipped files not covered by per-commit absorption in H.9, H.10, H.11, or H.13. The audit at `AUDIT-PRE-19C-BOUNDARY-LEAKS.md` used a filename-based regex vocabulary that missed BARE-VERSION SHORTHAND (`V3.3 §X.Y`, `V3 §28.1.X`) and certain non-`*.md` cite forms.

  **Pattern observation.** 33 audit-gap leaks have already been absorbed per-commit through Batch 19c.H.10 (H.9: 2 RESEARCH-* in main commit + 12 bare-V3.3 / ARCHITECTURE-V3.3-DELTA cites in NIT-1 fix commit = 14; H.10: 19 absorbed (18 bare-V3.X + 1 detect.sh L22); total 33). The trinity Filename uniqueness rule update at commit `1121b3d` (2026-05-24) formally classifies the gap. The pattern is systemic: files H.11/H.13 won't touch ALSO contain leaks of this class.

  **Pipeline (per pack memory `feedback_researcher_architect_planner_pipeline`):**
  1. pack-docs-researcher inventories audit-vocabulary-gap leaks across pack-shipped files via extended grep vocabulary:
     - Bare-version shorthand: `V[0-9]+(\.[0-9]+)? §` patterns (excluding legitimate project-version refs like `v10`/`v11.0`)
     - Explicit pack-internal doc cites: any `*.md` cite where target lives at `maintenance-docs/`
     - Architecture/research/audit-doc references whose basename resolves to pack-internal target
  2. Pack Chat reviews inventory + scope; user approves
  3. pack-coder closes leaks via Cat A drops (preserve rule wording) or Cat B substitutions (where rule cannot stand alone)
  4. INLINE reviewer (sliding window = BD-190 alone) verifies sweep completeness via the same extended grep
  5. Commit: `feat: v11 — BD-190 comprehensive audit-vocabulary-gap sweep (Batch 19c)`

  **Scope expansion (2026-05-24, post-Phase 1 inventory).** Phase 1 inventory at `maintenance-docs/v11-implementation/AUDIT-GAP-INVENTORY-BD-190.md` cataloged 29 Class A leaks across 11 files matching the original audit-vocabulary-gap vocabulary. Inventory §7.1 flagged a SEPARATE leak class NOT covered by the original grep vocabulary: qualified-filename + pack-internal-section cites (e.g., `ARCHITECTURE.md §6` where the filename resolves at client install but the cited section content is pack-internal). Pack Chat triage decision: ABSORB the qualified-filename class into BD-190 rather than open a separate BD (no new BD; no delays). Mini-inventory pass cataloged 2 additional Class D leaks in `tracker.toml.project-example` L11 + L17. Phase 2 sweep scope: **31 leaks total (29 Class A + 2 Class D) across 11 files**. V1-classification correction per inventory §2: H.10 §2.4.2.a classified 8 V1 cites in pm-startup cluster as LEGITIMATE on unsupported grounds; this inventory corrects to Class A. Pack Chat ACCEPTS the correction per user direction 2026-05-24.

  **Scope boundary.** Includes pack-shipped files at client install MINUS files swept by H.9 / H.10. EXCLUDES files in H.11's Cat C scope and H.13's per-line-fence scope (those commits absorb in-file fit). If H.11 or H.13 coder DISCOVERS additional audit-gap leaks in their files, Pack Chat triages whether they absorb or BD-190 picks up.

  **Resolution.** This BD resolves when extended-vocabulary grep across pack-shipped files (post-H.9/H.10/H.11/H.13) returns zero matches. Check 43 (H.14) PASS at HEAD is the proof.

  **Position:** insert immediately after H.10 in Batch 19c sequence (between H.10 commit `6e3e082` and H.11). Per user direction 2026-05-24.
Resolved: 2026-05-24 — Phase 1 inventory (`maintenance-docs/v11-implementation/AUDIT-GAP-INVENTORY-BD-190.md`, 593 lines) + Phase 2 sweep (commit `df1e97d`, 31 cite-drops across 11 pack-shipped files: 29 Class A bare-version + 2 Class D qualified-filename). IMPL-REPORT at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-190.md`. Resolution criterion proven: extended-vocabulary grep (`V[0-9]+(\.[0-9]+)? §` + `ARCHITECTURE.md §X` qualified-filename) returns ZERO matches across all 11 sweep target files at HEAD; Check 43 PASSES at HEAD with 152 client-installed files walked + zero pack-internal bare cross-references. Status-flip delayed because BD-190 Phase 2 swept BEFORE H.14 landed (Check 43 was the resolution proof but didn't exist at sweep time); flip applied post-Batch-19c-close once H.14 PASS at HEAD made the proof testable.

---

**BD-191 — Product Specialist (PS) requirements + v11.0/v11.1+ scope decision**
Type: feat — surfaced 2026-05-24 from sidecar Pack Chat session for v11.1+ Product Specialist feature requirements gathering; user-approved 2026-05-24
Status: Resolved
Blockers: None — independent of v11.0 work; runs parallel; integrates with groupings (BD-186/189) via existing #7 from-external ingest workflow with ZERO hard dependency
Unblocks: Downstream architect / planner / coder cycles for Product Specialist feature implementation (architect pass reads BD-191's REQUIREMENTS-PS-V11.md as primary input; RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md as ancillary fact base; INTAKE-PS-V11.md as user-intent audit trail)
File/Symbol:
  - NEW `maintenance-docs/v11-research/REQUIREMENTS-PS-V11.md` — primary deliverable; capability requirements + v11.0/v11.1+/v11.2+ scope decision
  - NEW (post-this-BD's-triage, end-of-sidecar) `maintenance-docs/v11-research/HANDOFF-PS-ARCHITECT.md` — entry-point doc for the v11.x PS architect (similar to HANDOFF-V11.1-ARCHITECT.md for groupings). Architect/planner may rename with a version anchor (e.g., `HANDOFF-V11.1-PS-ARCHITECT.md` or `HANDOFF-V11.2-PS-ARCHITECT.md`) at write time once scheduling is settled.
  - INPUTS (read-only):
    - `maintenance-docs/v11-research/INTAKE-PS-V11.md` (raw user-intent discussion: initial framing + Q1-Q10 + naming decision + research approval + §7 quality-mitigation intuition; high-fidelity verbatim user messages)
    - `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (PS landscape Pass-1; 985 lines; 7 categories + cross-cat synthesis + §9 pack-relevance observations)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (research methodology + open questions)
    - `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` (pack-architect OT-pattern synthesis; 638 lines; §3 transferable patterns + §4 failure modes + §5 groupings amendment dispositions + §6 PS capability recommendations + §7 architect investigation areas + §8 challenge questions; shaped §5 groupings amendments + §6 PS preliminary restructure)
    - `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (companion v11.1+ feature; PS docs feed into #7 from-external ingest)
    - `maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md` (groupings intake; audit-trail companion to REQUIREMENTS-GROUPINGS-V11.md; faithful-summary fidelity; OPTIONAL for context)
    - `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` (groupings architect handoff; received §5.1 cycle-detection + §5.2 architectural-seam Kind defer architect-investigation entries during this BD's work)
    - `pack-ops/BACKLOG.md` entries BD-186 (Resolved) + BD-189 (groupings implementation umbrella) for cross-feature context
    - `CLAUDE.md` `## Pack memory` (pack-repo-trinity rules)
  - AUDIT-TRAIL / IMPL-REPORTs (audit-trail of sidecar work; no-orphans capture per user direction 2026-05-24):
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-PLANNING-PROCESS-INSIGHTS-FROM-OT.md` (pack-architect IMPL-REPORT for OT synthesis pass; methodology + sources + SC mapping)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-INTAKE-PS-V11-GOALS-INDEX.md` (pack-coder IMPL-REPORT for §9 goals consolidated index addition + Goal 16/17 capture)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` (pack-coder IMPL-REPORT for §5.1 cycle-detection amendment to REQUIREMENTS-GROUPINGS-V11.md / TOUCH-POINT-INVENTORY-GROUPINGS-V2.md / HANDOFF-V11.1-ARCHITECT.md)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` (pack-coder IMPL-REPORT for §5.2/§5.3/§5.4/§5.6 groupings amendments + Goal 18 cross-surface landing + §6 PS sub-decisions Foundation/Interview/Deliverables/Pack-integration/Workflow/Boundary)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` (pack-coder IMPL-REPORT for INTAKE §7.5 interview flow dynamics + §8 walkthrough results subsection + §9.5 Goal 19 + §9.6 mapping renumber + Goals 5/7/10 refinements + Cap N8 + cross-ref to PLANNING-PROCESS-INSIGHTS)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-REQUIREMENTS-PS-V11.md` (pack-coder IMPL-REPORT for REQUIREMENTS-PS-V11.md authoring; 21 preliminary capabilities + 30 open architect decisions consolidated)
    - `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-HANDOFF-PS-ARCHITECT.md` (pack-coder IMPL-REPORT for HANDOFF-PS-ARCHITECT.md authoring; navigation + framing entry-point doc for v11.x+ PS architect)
Description: Pack-side requirements-gathering work to refine the "Product Specialist" feature shape and produce a per-capability v11.0/v11.1+/v11.2+ scope verdict. This BD covers the REQUIREMENTS pass only; downstream architect/planner/coder cycles open as separate BDs once the requirements artifact lands and capabilities have verdicts.

  **Critical scope boundary:** PS is CLIENT-SIDE ONLY. Affects `project-template/` surface only; NEVER applies to pack-self development workflow. PS is for the developer's product work (PRDs, journeys, features, mappings); the existing PM Chat (project manager) continues to orchestrate pack work itself.

  **Naming decision (resolved 2026-05-24):** Product Specialist (PS) over Product Manager (PM) to avoid collision with existing PM Chat terminology. Selected from options (A) full TPM rename of existing PM, (B) prose-discipline-only, (C) hybrid, (D-PS) Product Specialist abbreviation. Option (D-PS) chosen for cleanest semantic + abbreviation separation; "Specialist" semantically fits the episodic-expertise-contribution pattern better than "Manager."

  **BD numbering history (2026-05-24):** This BD was originally drafted as BD-190 during the sidecar planning session. Main chat opened BD-190 in parallel for an audit-vocabulary-gap sweep (Batch 19c); PS work renumbered to BD-191 per pack memory `reference_pack_backlog_structure` ("always read the live BACKLOG before assigning"). Renumbering tracked in commit `337ac47`. Pre-renumbering commits (`17682c7` research, `df64afc` intake docs, `a6423c3` §7 add) preserved with "BD-190" in commit message text as historical record of the working assumption.

  **Cross-feature relationship with groupings (BD-186 / BD-189):**
  - ZERO HARD DEPENDENCY in either direction. Groupings stand alone per BD-186; PS is an OPTIONAL upstream feeder.
  - PS produces PRDs / journey docs / mapping docs / feature lists that feed groupings via the existing #7 from-external ingest workflow.
  - PS NEVER produces `GRP-NNN.md` files directly — that's groupings/coder scope (per user direction 2026-05-24).
  - PS awareness for v11.1 groupings architect: documented in HANDOFF-V11.1-ARCHITECT.md; may be updated during this BD's work if integration surfaces requiring architect awareness emerge.

  **Two modes of operation (per user direction 2026-05-24):**
  - Mode 1: From-scratch authoring (interview + write PRD + research)
  - Mode 2: Existing-PRD ingest + gap-fill (read existing user PRD + identify pack-integration gaps + interview to fill + restructure if needed)

  **Inputs:** RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md (pre-BD-191 landscape research with quality-filtered findings across 7 categories — OSS PM tools / professional products / methodologies + frameworks / PRD templates / interview frameworks / AI-LLM tooling / dev-tool integration); INTAKE-PS-V11.md (user-intent audit trail including §7 quality-mitigation intuition); user-stated design principles (TBD during this BD's triage); existing v11 design (especially BD-186 groupings work as integration point).

  **Goal:** Produce a single requirements artifact at `maintenance-docs/v11-research/REQUIREMENTS-PS-V11.md` capturing:
  - Refined user-facing capability set (informed by RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md §9 pack-relevance observations + §9.5 defensible methodology positions + INTAKE-PS-V11.md §7 quality-mitigation intuition)
  - Per-capability disposition (keep / modify / drop / GH-conditional / mode-1-only / mode-2-only)
  - Per-capability v11.0 vs v11.1+ vs v11.2+ scope verdict with rationale
  - For v11.1+ absorbed capabilities: insertion target (existing batch fold-in OR proposed new BD-NNN with position)
  - For deferred capabilities: live forward-pointing anchor (this artifact + cross-reference to landscape research where applicable)
  - Documented scope boundary against Wave 3 agentic-PM vapor (per §9.4 cautious framing)
  - Cross-feature integration points with groupings explicit
  - Tactical guiding principles for interview structure + "complete" criteria (per §7 investigation outcomes)

  **Success Criteria:**
  - SC1. Every user-facing capability surfaced during this BD's triage has a documented disposition + scope verdict.
  - SC2. Every §9 pack-relevance observation from PS landscape research has a documented influence on the capability set OR a documented rationale for non-influence.
  - SC3. Disposition + scope verdicts cite design principles surfaced during this BD's triage (drawn from §9 hard-things-to-be-careful + §9.2 underserved-gaps + §9.3 familiar-patterns + §9.4 LLM-PM boundary + §9.5 methodology positions + §7 quality-mitigation tactical principles).
  - SC4. v11.1+ absorbed capabilities have either a target existing batch (with cross-reference) or a proposed new BD-NNN.
  - SC5. Deferred capabilities are listed on a live forward-pointing surface — this artifact, optionally with new parking-lot BDs (parallel to BD-187 / BD-188 pattern for groupings).
  - SC6. Cross-feature integration with groupings (BD-186 / BD-189) is explicit; any required modifications to BD-186 artifact or HANDOFF doc are surfaced as proposed amendments.
  - SC7. Two operational modes (from-scratch + existing-PRD ingest) are explicitly covered with per-capability triage.
  - SC8. Methodology-position recommendations from §9.5 are surfaced as candidate defaults for architect consideration (NOT prescribed; defensible defaults).
  - SC9. Wave 3 vapor (autonomous agentic PM) is explicitly documented as out-of-scope per §9.4 cautious framing.
  - SC10. **Quality-mitigation principles investigation.** The triage walkthrough must address the user-stated quality-mitigation intuition surfaced in `maintenance-docs/v11-research/INTAKE-PS-V11.md §7`:
    - (a) Interview-structure requirements: clear problems / goals / success criteria framing; structured sections (NOT a random walk); gap-identification process across market research / ideation / creativity / scope / resources / priorities / constraints; same structured approach used for both from-scratch and existing-PRD-ingest modes
    - (b) Audience-aware-deliverable requirements: deliverable shapes informed by pack integration knowledge (workflows / docs / scripts / tracker / groupings / phases / tasks / backlog entries) — narrower / more-specific than open-ended PM tools, which gain unknown audiences
    - Investigation outcomes define tactical (not just strategic) guiding principles AND "complete" criteria for the interview process
    - Investigation directly mitigates §9.1 quality-pitfall findings ("AI PRDs without facilitation = decorative artifacts"; "AI methodology selection muddles")
    - Without this address, the requirements doc risks anchoring the PS feature on the §9.1 quality pitfalls the landscape research surfaced
  - SC11. **Priority elicitation, documentation, propagation, and scope-test mechanisms.** The triage walkthrough must address priorities as a first-class cross-cutting driver of PS outcomes, captured in `maintenance-docs/v11-research/INTAKE-PS-V11.md §9` Goal 17:
    - (a) Elicitation: priorities are a required structured section in the PS interview (paired with §7.1 interview structure); axes include product/market fit, competitive necessity vs. competitive advantage, technical constraints, resource constraints (time/money/team-size/expertise), scope decisions (MVP vs. Phase 2 vs. Phase N; in/out/conditional), plus the original cost/speed/quality/feature-sets/user-journeys axes from INTAKE §1 (a); user-named axes supported
    - (b) Documentation: priorities surface in PRD sections, feature-inventory rows, anti-pillar reasoning, and conditional-inclusion triggers across PS deliverable shapes
    - (c) Propagation: PS priority output flows into pack-side primitives (MVP-line → grouping membership; feature priority → phase ordering via Blockers/Unblocks and backlog severity; anti-pillar triggers → conditional-inclusion table in PRD)
    - (d) Scope test: priorities serve as the criterion for evaluating whether added scope (capabilities, deliverables, workflow steps) genuinely advances product outcomes vs. constitutes scope creep — pairs with the user-stated scope-discipline meta-criterion captured in INTAKE-PS-V11.md §9 Goal 16
    - Without this address, the requirements doc risks producing capability decisions disconnected from the scope-shaping force priorities exert across product success outcomes
  - SC12. **PS-to-pack-entry-type boundary contract.** The triage walkthrough must address Goal 18 (`maintenance-docs/v11-research/INTAKE-PS-V11.md §9.4`) — PS workflows produce context-rich, audience-aware inputs that enable pack ENTRY-TYPE workflows (phases / groupings primarily; backlog only as track-without-schedule edge case) to build their canonical artifacts. PS does NOT create canonical pack entry-type artifacts directly:
    - (a) Audience-awareness contract: PS workflows are INFORMED BY pack entry-type data-structure requirements (phases never created with parts; tasks are phase components — inline flat-file or tracker work items; groupings contain phases only; phase parts are evolution-only artifact PS shouldn't know about) per pack memory `reference_pack_entry_type_semantics`
    - (b) Gap-filling responsibility: where input gaps would prevent any relevant pack entry-type workflow from generating its canonical artifact, PS workflows fill gaps via interview / research / additional content collection (PS-side responsibility, not pack-side)
    - (c) Architectural-knowledge propagation: architectural seams, NFRs, anti-pillars, conditional-inclusions live in PS deliverables (PRD architectural-commitments section; feature inventory `seam_refs:` field; audit-pass coverage checks) and propagate to pack workflows via conversion — the PS-side structural surfaces are the canonical home, not field replication on every pack entry-type schema
    - (d) Cross-feature integration: groupings-side conversion responsibility (handles multiple project-doc input types — PS-produced + project-provided + non-PS varied formats) lands in REQUIREMENTS-GROUPINGS-V11.md Capability #7 SC7.8 per §5.3 + Goal 18 amendments (user-approved 2026-05-24); changes to existing pack entry-type architecture have a HIGH challenge bar per pack memory `feedback_preliminary_triage_architect_challenge` (architect cannot arbitrarily change boundary out of scope; must investigate thoroughly)
    - Without this address, the requirements doc risks PS scope leaking into canonical pack entry-type authoring (violating the boundary) OR leaving gaps in the PS→pack conversion path (orphaning architectural knowledge that lives in PS deliverables)
  - SC13. **Human-readable PRD rendering generator for user verification.** The triage walkthrough must address user-experience requirement that PS deliverables include a complementary human-readable PRD rendering generated from pack-primary sources, captured as Goal 19 in `maintenance-docs/v11-research/INTAKE-PS-V11.md §9.5`:
    - (a) Pack-primary remains canonical: PS deliverables (N4 narrative PRD + N5 structured journey docs + N6 feature inventory + mapping per Cluster 3 walkthrough results) are the source-of-truth; Goal 7 audience-priority unchanged
    - (b) Rendering generator capability (Cap N8 per INTAKE §8 walkthrough-results subsection): reads pack-primary sources and produces a human-targeted PRD document optimized for visual verification; NOT pack-ingested; secondary artifact derived from pack-primary
    - (c) Architect-decided at PS design time: generator implementation shape (skill / sub-agent / external tool / pack-adjacent script); output format (markdown / HTML / PDF); section structure favoring human comprehension; trigger semantics (on-demand vs auto-generate on milestone)
    - (d) User-experience failure mode without it: users reviewing PS output get docs aimed at config pack; cannot visually verify accuracy of PS-captured content; frustration leads to abandonment of PS feature entirely
    - Without this address, the requirements doc risks producing pack-primary-only PS output that creates user frustration during review and undermines PS adoption

  **Out of scope:**
  - Architecture (specific agent/skill design, prompt content, methodology selection algorithm, output doc shapes) — downstream architect pass per pack memory `feedback_pack_chat_does_not_architect`.
  - Implementation planning (commit sequencing, per-BD breakdown beyond proposed BD-NNNs) — downstream planner pass per `feedback_planner_user_review_before_coder`.
  - Edits to BD-186 / BD-189 entries or their artifacts (only PROPOSED amendments via this BD's artifact; landing requires separate Pack Chat commit + user approval).
  - Pack-self application of PS (CLIENT-SIDE ONLY constraint per user direction 2026-05-24).
  - Opening new BDs for PS IMPLEMENTATION work (those open later via downstream planner output OR as parking-lots if specific items defer beyond v11.1+).

  **Pipeline:** Pack Chat sidecar (this work) → REQUIREMENTS-PS-V11.md → user review + approval → BD-191 Resolved → downstream architect / planner / coder cycles open as separate BDs per scope decisions.

  **Position:** v11.1+ deferred — see EXECUTION-PLAN-V11.0.md §1.6 (Group 4 deferred-to-v11.1+ list). User-approved 2026-05-24. Independent of v11.0 work; runs parallel as a v11.1+ requirements pass. Implementation BDs surface from this requirements artifact; per-capability scope verdicts (v11.1 vs v11.2) decided by the sidecar's scope-verdict output. Architect/planner judgment at scheduling time.
Resolved: 2026-05-25 — BD-191 closed after full sidecar requirements-gathering cycle. Primary deliverables landed: `maintenance-docs/v11-research/REQUIREMENTS-PS-V11.md` (commit `e2a0c65`; 1195 lines; 21 preliminary capabilities + 30 open architect decisions across 6 clusters); `maintenance-docs/v11-research/HANDOFF-PS-ARCHITECT.md` (commit `2ca740d`; 227 lines; navigation + framing for v11.x+ PS architect). Companion deliverables landed across 11 commits (`337ac47` renumber → `5748181` audit-fixes): INTAKE-PS-V11.md (audit trail with 19-goal index at §9 + §7.5 interview flow dynamics + §8 walkthrough results), RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md, PLANNING-PROCESS-INSIGHTS-FROM-OT.md (OT-pattern synthesis), 8 IMPL-REPORTs (per-pass audit trail), 2 audit reports (parallel pack-architect + pack-reviewer; 22 fixes applied per IMPLEMENTATION-REPORT-AUDIT-FIXES.md). Cross-feature integration with groupings (BD-186 Resolved / BD-189 v11.1+ umbrella) landed via §5 amendments (REQUIREMENTS-GROUPINGS-V11.md §5.1 cycle-detection + §5.3 SC7.7 + §5.4 mvp_priority REJECT + §5.6 SC17.10 + new SC7.8 for Goal 18); HANDOFF-V11.1-ARCHITECT.md received §5.1 + §5.2 architect-investigation entries. New pack memory rules established and indexed: `feedback_preliminary_triage_architect_challenge`; `reference_pack_entry_type_semantics`; `feedback_pattern_matching_out_of_context_antipattern`. v11.1+ scope per main-chat BD scope markers commit `2e2f6ab`. Downstream pickup: v11.x+ PS architect reads HANDOFF-PS-ARCHITECT.md as direct entry point; locks the 30 preliminary architect decisions in REQUIREMENTS-PS-V11.md §10; produces ARCHITECTURE-PS-V11.x.md per standard pack architect/planner/coder pipeline. All preliminary positions remain subject to architect challenge per `feedback_preliminary_triage_architect_challenge`.

---

**BD-192 — v11.1+ Product Specialist (PS) implementation (architect/planner/coder cycle)**
Type: TODO(version) — surfaced 2026-05-25 from BD-191 sidecar wrap; live forward-pointing anchor for v11.1+ PS core implementation per pack memory `feedback_deferred_work_tracking`
Status: Open
Blockers: v11.0 ships (then v11.1 cycle architect pass can start); BD-189 v11.1+ groupings implementation should land first per user direction 2026-05-24 (groupings infrastructure provides #7 from-external ingest path PS feeds; PS architect needs locked groupings architecture for cross-feature integration design)
Unblocks: Per-capability implementation BDs that the v11.1 planner produces (21 preliminary capabilities + 30 open architect decisions per REQUIREMENTS-PS-V11.md §10); v11.1+ user-facing Product Specialist feature
File/Symbol:
  - NEW `maintenance-docs/v11-implementation/ARCHITECTURE-PS.md` (architect deliverable; may be versioned as `ARCHITECTURE-PS-V11.x.md` per HANDOFF-PS-ARCHITECT.md §10)
  - NEW `maintenance-docs/v11-implementation/PLAN-PS.md` (planner deliverable)
  - Per-BD implementation surfaces TBD by planner (spans 21 preliminary capabilities)
  - PRIMARY INPUTS (read-only):
    - `maintenance-docs/v11-research/HANDOFF-PS-ARCHITECT.md` (READ FIRST — orientation; 227 lines; navigation + framing + discipline + reading order)
    - `maintenance-docs/v11-research/REQUIREMENTS-PS-V11.md` (primary input; 1195 lines; 21 preliminary capabilities + 30 open architect decisions + constraints C1-C7 + design principles)
    - `maintenance-docs/v11-research/INTAKE-PS-V11.md` (user-intent audit trail; verbatim user framing + 19 goals + §7 quality-mitigation + §7.5 interview flow dynamics + §8 walkthrough results)
    - `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (landscape facts; 985 lines; §9 pack-relevance observations + §9.5 defensible methodology positions)
    - `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` (pack-architect OT-pattern synthesis; 638 lines; §3 patterns + §4 failure modes + §7 architect investigation areas + §8 challenge questions)
    - `maintenance-docs/v11-research/AUDIT-PS-FULL-SESSION-ARCHITECT.md` + `maintenance-docs/v11-research/AUDIT-PS-FULL-SESSION-REVIEWER.md` (full-session audit reports from BD-191 close-out; informative context for fix-applied state)
    - `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (companion v11.1+ feature; PS docs feed groupings via #7 from-external ingest; Cap #7 SC7.8 for cross-feature contract)
    - `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` (groupings architect handoff; cross-feature peer doc)
    - `pack-ops/BACKLOG.md` entries BD-186 (Resolved) + BD-189 (groupings implementation umbrella) + BD-191 (Resolved; PS requirements source-of-truth) for cross-feature and BD-context
    - `CLAUDE.md` `## Pack memory` (pack-repo-trinity rules; standard pack-agent context; includes preliminary-triage-architect-challenge + pattern-matching-anti-pattern + pack-entry-type-semantics + user-prescriptive-authority rules established during BD-191)
Description: Live forward-pointing anchor for the v11.1+ Product Specialist (PS) core implementation work. All 21 preliminary capabilities of the PS feature (per REQUIREMENTS-PS-V11.md §4) defer to v11.1+ implementation; this BD captures the umbrella work that the v11.1 architect / planner / coder pipeline will break into per-capability BDs.

  Without this BD, the deferred work would lack a live forward-pointing anchor per pack memory `feedback_deferred_work_tracking` (BD-191 is Resolved, not a live anchor; the requirements artifact + handoff doc are "inputs" not forward-pointing surfaces). This BD-192 satisfies the rule by providing the umbrella entry until the v11.1 architect/planner work decomposes it.

  **Pipeline (per REQUIREMENTS-PS-V11.md §11 + HANDOFF-PS-ARCHITECT.md §10):**
  1. Architect pass produces `ARCHITECTURE-PS.md` (locks the 30 open architect decisions in REQUIREMENTS §10 + any additional decisions identified during deeper investigation)
  2. User review of architect output (cheap-redirect window before planner spawn)
  3. Planner pass produces `PLAN-PS.md` with per-BD breakdown + sequencing + verification strategy
  4. User review of planner output (cheap-redirect window before coder spawn)
  5. Coder cycles per BD with reviewer cycles per pack memory `feedback_review_fix_one_cycle`
  6. End-of-batch reviewer + per-BD status flips
  7. **Cross-feature coordination with groupings architecture (BD-189):** the PS architect's Cap #13 work (cross-feature integration) may surface a proposed amendment to HANDOFF-V11.1-ARCHITECT.md or REQUIREMENTS-GROUPINGS-V11.md Cap #7; coordination protocol per HANDOFF-PS-ARCHITECT.md §7 (PS architect surfaces; Pack Chat / groupings team coordinates writing).

  **Discipline (per pack memory established during BD-191):**
  - All preliminary positions in REQUIREMENTS-PS-V11.md §4 (21 capabilities) + §10 (30 architect decisions) are subject to architect challenge per `feedback_preliminary_triage_architect_challenge`. Tiered challenge bar: LOW (PS-internal) vs HIGH (boundary-with-existing-pack).
  - User retains final authority on architect challenges per `feedback_user_prescriptive_authority`.
  - Pattern-matching from adjacent pack mechanisms requires property-fit verification per `feedback_pattern_matching_out_of_context_antipattern` (especially relevant for Cap N1 PS deliverable directory structure).
  - Pack entry-type data-structure semantics are locked per `reference_pack_entry_type_semantics` (PS workflows feed; do NOT create canonical pack entry-type artifacts).

  **Scope boundary:** This BD covers the CORE PS implementation per the 21 preliminary capabilities. CLIENT-SIDE ONLY constraint (C1) applies — affects `project-template/` surface only; NEVER applies to pack-self workflow. Wave 3 (autonomous agentic PM) explicitly OUT of scope (C6 / Goal 13).

  **Resolution:** This BD resolves when the v11.1 planner has produced per-capability BDs and the umbrella role is no longer needed (i.e., the children carry the work forward). Alternatively, it could resolve at v11.1 ship with all children Resolved. Architect/planner decides at scheduling time.

  **Position:** v11.1+ deferred — see EXECUTION-PLAN-V11.0.md §1.6 (Group 4 deferred-to-v11.1+ list; main-chat may add this BD to the list as a separate PM-only edit). Scheduling: starts when v11.0 ships and v11.1 cycle begins. User direction 2026-05-24 indicated PS implementation follows groupings implementation (BD-189 lands first); PS scheduling likely v11.1+ or v11.2 per architect/planner judgment at scheduling time.
Resolved: n/a

---

**BD-193 — Code Red 2: BD/TD/Path scope contamination cleanup (Batch 19d-prep)**
Type: fix — surfaced 2026-05-26 during BD-185 H.1 INLINE review prep from cross-cutting audit; user-locked 3-rule triage stack (operational vs explanatory + pack/project separation + token economy) established 2026-05-26 in pack memory `feedback_bd_pack_only_operational_rule`, `feedback_pack_project_separation_of_concerns`, `feedback_client_facing_token_economy`
Status: Resolved
Blockers: None. Cleanup applies to client-facing surfaces (project-template/, supporting-docs/) and pack-archive (templates-archive/v11.0/, v11.1/) PLUS one pack-script source (scripts/init-project.sh F4/F5). All in-scope surfaces are accessible at v11-dev HEAD.
Unblocks: BD-185 H.2 fires only after this BD lands clean — BD-185 H.2 modifies the same phase-part SCHEMA surface that this BD cleans up (the 23 BD-185 cite removals); that SCHEMA was relocated by BD-195 S1·C3 from the retired `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` to `templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`. Without this BD, H.2 would build on contaminated baseline.
File/Symbol:
  - PRIMARY INPUTS (read-only):
    - `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md` (Phase 1 docs-researcher output; 782 lines; raw inventory of ~140 findings across 48 files)
    - `maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md` (Phase 2 pack-reviewer disposition; 987 lines; per-row triage with BEFORE/AFTER text; 11 LOCKED + 3 LEAK + 105 WASTE + 110 LEGITIMATE; §6.1/§6.2/§6.3/§6.4 user-resolutions applied)
  - **Pack-archive (templates-archive)** — F1 INDEX segregation (v11.0/v11.1/INDEX.md), F1.c PACK-INTERNAL header (bd-v11.0/SCHEMA.md), F2.a/F2.b/F2.c grammar admissions removal (phase-task-v11.0/SCHEMA.md, phase-part-v11.1/SCHEMA.md, forms/work-item.yml), 47 BD-185 narrative WASTE cites (v11.1/INDEX.md + phase-part-v11.1/SCHEMA.md), 2 §6.1 inbound-v11.0/SCHEMA.md mention-to-exclude removals
  - **Project-template** — F2.d work-item.yml admissions removal, F3 _intro.md cross-reference removal, trinity (CLAUDE/AGENTS/GEMINI) BD-142 cite removal (identical edit; trinity-rule), 6 PLATFORM-SKILLS.md WASTE, 2 boundary-investigation/SKILL.md (§6.2 BD-175 label removal), 1 audit-methodology/SKILL.md LEAK (BD-NNN.md → TD-NNN.md), various skill/agent WASTE cites
  - **Supporting-docs** — F2.e METHODOLOGY.md parser regex (`BD-\d+` token removal), 4 METHODOLOGY.md WASTE, 6 INSTALL-PROCEDURES.md WASTE, MIGRATION-v10-to-v11.md 1 LEAK + 23 Class B WASTE (§6.3 split; 16 Class A LEGITIMATE preserved), 5 SETUP-NEW.md/SETUP-EXISTING.md WASTE (§6.4)
  - **Scripts** — F4/F5 init-project.sh S11 block (replace pack-ops/HELP-FRAGMENT-TRACKER.md source with project-template/docs/pack/HELP-FRAGMENT-TRACKER.md; remove pre-v11 pack-root fallback per `feedback_pack_project_separation_of_concerns`)
  - **Test fixtures** — `test-fixtures/manifest.txt` regeneration (v11-surface trigger per `feedback_manifest_regen_on_v11_surface`)
  - PRIMARY OUTPUT: `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
Description: Cleanup of pack-only / client-facing scope contamination surfaced during BD-185 H.1 INLINE review preparation on 2026-05-26. Three classes of contamination identified + remediated via 3-rule triage stack:

  **Class 1 — Operational BD-NNN leakage in client-facing content (LEAK).** Client-side entity contracts (phase-task, phase-part, work-item form) admitted BD-NNN as a dependency/blocker/peer type. Clients work with TD entries; BDs are pack-development-only. The operational admission was a boundary violation that, left uncorrected, would let client agents file BD-shaped work in client repos (a recurring `P-missed-7` regression class). 11 LOCKED dispositions (§3 of disposition report) close this class.

  **Class 2 — Cross-side substitution in scripts (VIOLATION).** `scripts/init-project.sh` S11 block sourced HELP-FRAGMENT-TRACKER.md from `pack-ops/` (PACK-ONLY) and copied to client install path. The BD-175 reorg decision that established "pack-ops/HELP-FRAGMENT-TRACKER.md is the canonical source" violated pack/project separation of concerns. Even when byte-identical to the project-template/ version today, the pack and project copies serve separate audiences and can diverge. F4/F5 lock corrects the source to `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` and removes the pre-v11 pack-root fallback.

  **Class 3 — Token-economy waste in client-facing content (WASTE).** Client-facing docs (METHODOLOGY.md, SKILLS files, PLATFORM-SKILLS.md, agent definitions, trinity, INSTALL-PROCEDURES.md, SETUP-* files, templates-archive narrative) contained ~105 narrative BD-NNN cites describing pack-implementation history that clients don't need. Per pack memory `feedback_client_facing_token_economy` + RAG-indexing concern: every narrative BD cite is a few tokens of irrelevant pack-history that wastes client agent context-window space at query time. 105 WASTE rows remove BD labels while preserving descriptive content per the BEFORE/AFTER text in disposition report §4.

  **Pipeline (executed):**
  1. Phase 1 (pack-docs-researcher) — comprehensive cross-surface inventory (Surface A client-facing + Surface B scripts)
  2. Phase 2 (pack-reviewer) — 3-rule triage stack disposition; 11 LOCKED + 4 AMBIGUOUS classes user-resolved (§6.1/§6.2/§6.3/§6.4)
  3. Phase 3 (pack-coder; THIS BD) — single cross-surface commit applying all locked + disposed corrections
  4. Phase 4 (pack-reviewer extensive audit; per user directive) — verify Phase 3 successful, no regressions, no remaining in-scope issues

  **Success Criteria:**
  - SC1. All 11 LOCKED dispositions applied per disposition report §3 (F1/F2/F3/F4-F5)
  - SC2. All 3 LEAK fixes applied (A-3.3.2 verified inherited from F2.a; A-3.33.1 audit-methodology BD-NNN.md → TD-NNN.md; A-3.46.22 MIGRATION-v10-to-v11.md BD-NNN.md → TD-NNN.md)
  - SC3. All 105 WASTE fixes applied per disposition report §4 BEFORE/AFTER tables
  - SC4. §6.1 split-reading applied (keep work-item.yml:18 project-side boundary-defense; remove inbound-v11.0 mention-to-exclude rows 1+2)
  - SC5. §6.2 Reading A applied (BD-175 label removal in boundary-investigation/SKILL.md; worked-example content retained)
  - SC6. §6.3 Class A/B split applied (16 Class A LEGITIMATE preserved; 23 Class B WASTE removed)
  - SC7. §6.4 Reading A applied (all 5 SETUP-NEW.md/SETUP-EXISTING.md WASTE removed)
  - SC8. Trinity-rule parity preserved (CLAUDE/AGENTS/GEMINI BD-142 cite removal identical across all 3 files)
  - SC9. `test-fixtures/manifest.txt` regenerated; staged in same commit
  - SC10. `python3 scripts/validate-pack.py` PASS (especially Check 43 leak-sweep prevention)
  - SC11. Phase 4 reviewer audit PASS (no regressions; no remaining in-scope issues; Phase 3 successful)

  **Out of scope:**
  - POQ-4 reversal documentation in `ARCHITECTURE-BD-185.md` / `PLAN-BD-185.md` (separate Pack Chat work; commits separately)
  - BD-185 H.1 NIT-2 / NIT-3 cosmetic fixes (held pending Code Red 2 close)
  - BD-185 H.2-H.16 implementation (fires after Code Red 2 lands clean)
  - Check 24 byte-identity rule re-examination (flagged for separate architect concern; not blocking Code Red 2)

  **Pack memory anchors:**
  - `feedback_bd_pack_only_operational_rule` (Rule 1; operational vs explanatory)
  - `feedback_pack_project_separation_of_concerns` (Rule 2; cross-side substitution forbidden)
  - `feedback_client_facing_token_economy` (Rule 3; RAG-cost necessity test)
  - `feedback_review_fix_one_cycle` (Phase 4 extensive audit is end-of-batch reviewer pass)
  - `feedback_manifest_regen_on_v11_surface` (manifest regeneration requirement)
  - `P-missed-7` (boundary discipline; underlying motivation for Class 1 fix)

  **Position:** Batch 19d-prep — fires IMMEDIATELY after H.1 commit lands and BEFORE H.2 spawns. BD-185 H.2 builds on the cleaned-up phase-part-v11.1/SCHEMA.md surface; Code Red 2 must close before H.2 begins.
Resolved: 2026-05-27 — Code Red 2 BD/TD/Path scope contamination cleanup completed across pack-archive (templates-archive/v11.0 + v11.1), client-facing surfaces (project-template/, supporting-docs/), and scripts (init-project.sh F4/F5). Phase 3 cleanup at 85196d4 applied 11 LOCKED + 3 LEAK + ~85 WASTE + 4 §6.* user-resolutions. Phase 4 extensive audit (PACK-REVIEW-BD-193-PHASE-4.md at 8b0718e) found 11 follow-on findings: 5 MUST + 2 SHOULD + 2 NIT + 1 AMBIGUOUS-resolved + 1 SHOULD-deferred to BD-194 (Check 24 architect-led fix). Phase 5 remediation at 8b0718e applied 10 fixes; Check 24 work tracked as BD-194 (Batch 19d-prep-3, fires before BD-185 H.2). 3-rule triage stack (operational vs explanatory + pack/project separation + token economy) captured as pack memory.

---

**BD-194 — Check 24 byte-identity gate replacement (post-BD-193 architectural baseline fix)**
Type: fix — surfaced 2026-05-27 from BD-193 Phase 4 audit §5.6 (M-8); architect-pass concern flagged pre-Code-Red-2 in pack memory `feedback_pack_project_separation_of_concerns`
Status: Resolved
Blockers: BD-193 Resolved (this BD presupposes the pack/project separation contract that BD-193's F4/F5 established).
Unblocks: BD-185 H.2 (H.2 fires after this BD lands to ensure no latent CI inconsistencies on the post-BD-193 baseline before BD-185 builds further form/SCHEMA divergence).
File/Symbol:
  - PRIMARY INPUT (read-only):
    - `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md` §5.6 (M-8 finding + 4 candidate design options)
    - `scripts/validate-pack.py` `check_help_fragment_tracker()` (current byte-identity gate implementation)
    - `pack-ops/HELP-FRAGMENT-TRACKER.md` (pack-side file)
    - `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (project-side file; F4/F5 source-of-truth for client install)
  - PRIMARY OUTPUT:
    - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` (architect deliverable; design selection + rationale)
    - `maintenance-docs/v11-implementation/PLAN-BD-194.md` (planner deliverable; single-commit plan)
    - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md` (coder deliverable)
    - `scripts/validate-pack.py` (modified `check_help_fragment_tracker` per architect decision)
Description: Replace `validate-pack.py` Check 24 (`check_help_fragment_tracker`) byte-identity gate between `pack-ops/HELP-FRAGMENT-TRACKER.md` and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` with an architecturally-consistent contract aligned with the BD-193 F4/F5 pack/project separation-of-concerns principle.

  **Problem:** Per pack memory `feedback_pack_project_separation_of_concerns` (user-locked 2026-05-26) and BD-193 F4/F5 LOCKED disposition: `pack-ops/HELP-FRAGMENT-TRACKER.md` and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` are declared SEPARATE artifacts with SEPARATE audiences. The current Check 24 byte-identity gate contradicts this architectural rule — currently passes (both files happen to be byte-identical at HEAD `85196d4`) but will FAIL on the first intentional divergence.

  **Latency:** Latent inconsistency. CI green at v11-dev HEAD. First future divergence (e.g., a pack-side verb description added that doesn't apply to clients) will surface this as a CI break.

  **Design candidates (architect to choose / surface alternatives):**
  1. **Delete the check entirely.** Loses safety net against accidental divergence.
  2. **Per-surface check** (mirroring the `check_issue_template_forms` pattern adopted in BD-193 collateral CI edits). Define what each surface MUST contain; allow controlled divergence.
  3. **Existence + structural validity invariant.** Both files must exist and parse as valid markdown; no content comparison.
  4. **Allowed-divergence allowlist.** Byte-identity gate retained but with explicit allowlist of "OK to diverge" sections / patterns.
  5. **Other** — architect may surface new candidates during design pass.

  **Pipeline:** architect → user review → planner → user review → coder → reviewer (researcher SKIPPED — design space is already enumerated; no external research needed).

  **Success Criteria:**
  - SC1. Check function modified per architect-locked design decision
  - SC2. Replacement contract is architecturally consistent with `feedback_pack_project_separation_of_concerns`
  - SC3. validate-pack.py PASS at HEAD (`python3 scripts/validate-pack.py`)
  - SC4. If divergence-allowing approach chosen: a minimal test fixture demonstrating allowed divergence (e.g., pack-side comment added) PASSES the new check
  - SC5. Reviewer audit pass clean

  **Out of scope:**
  - Other byte-identity checks in validate-pack.py (each requires its own architect pass; this BD scoped to Check 24 only)
  - Modifications to `HELP-FRAGMENT-TRACKER.md` content itself (this BD modifies the CI gate, not the content)
  - BD-185 H.2-H.16 implementation (resumes after this BD)

  **Pack memory anchors:**
  - `feedback_pack_project_separation_of_concerns` (the architectural principle Check 24 must align with)
  - `feedback_review_fix_one_cycle` (single review pass per BD)

  **Position:** Batch 19d-prep-3 — fires AFTER BD-193 Resolved + BEFORE BD-185 H.2 spawns. BD-185 H.2 builds on the post-BD-193 + post-BD-194 baseline.
Resolved: 2026-05-27 — Check 24 byte-identity gate replacement completed via Candidate 6 design: Check 24 retired entirely; Check 23 modified to fail-loud on missing pack-side tracker fragment; Check 22 corrected to per-surface tracker fragment selection (latent bug fix surfaced by BD-193 Phase 4 §5.6). Implementation at 4ef6c02 across 14 files; follow-on at 6c76582 addressed 3 reviewer findings (F-1: stale refs in 3 pack-repo dotted-skill mirrors; F-3: pre-existing test failures inherited from BD-193 inventory change — CI blocker resolved; F-2: doc count NIT). validate-pack now PASS at 40 invoked checks (down from 41); 2 per-check test files updated. Pipeline: architect → planner → coder → reviewer → fix-coder; researcher SKIPPED (design space pre-enumerated). Process gap surfaced for separate update: pack-coder PREFLIGHT pattern should require per-check test runs as a verification gate.

**BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**
Type: fix — pack-only operational; recovery of v11.0 to a pristine post-Batch-19c state prior to restarting BD-185 (phase parts).
Status: Resolved
Resolved: 2026-06-03 — v11.0-pristine recovery complete. Executed PLAN-BD-195-REMEDIATION.md C1–C9 (audit fix set + NL leak set) across PG-1/PG-2 + a batched final push; added the architect-designed client-surface v10→v11 currency sweep; then ran a parallel multi-agent COMPLETENESS RE-AUDIT (6 dimensions) that surfaced + fixed 12 net-new findings (v10-currency, dangling removed-doc cites, cross-CLI/RAG capability notes, docstring/fixture drift) the first audit missed, plus the trinity `## Project addenda` reconciliation-pointer correction. validate-pack GREEN; full per-check CI suite GREEN (run 26927439269, ~4min, on `1fa4c95`). Project-side capability-addition work (add-capability.sh pack-only verdict; Procedure 6 redesign) carved out to BD-200 per user direction. The C2-introduced validate-pack runtime regression split out + resolved as BD-199. Final HEAD 1fa4c95.
Alias: "Code Red 3" and "BD-195" refer to the same item (interchangeable).
Surfaced: 2026-05-28 (user direction, after the BD-185 attempt fractured).

State (2026-05-31): committed work reached end of Step 3 (reconciled problem list + prison). A Step-5/6/7 fix attempt was committed then HARD-RESET to `e0239f3` — those fixes are NOT in the tree. Re-audited vs post-BD-196 HEAD `c73077d` (findings consolidated in `maintenance-docs/v11-implementation/AUDIT-BD-195-VERIFIED-FINDINGS.md`): 48/49 problems live (both BLOCKERs P-01/P-02 live), 1 closed by BD-196 (P-29a), 1 changed (P-09); 7 OQ open + 1 partial (OQ-3) + 4 new (NQ-1…NQ-4). Disposition (user, 2026-05-31): RE-SCOPE into FOUR work-shape segments under this BD (a rejected BD-185-gate rescope was superseded); the segmentation and the full remediation strategy are consolidated in the execution plan `maintenance-docs/v11-implementation/PLAN-BD-195-REMEDIATION.md` (sole trusted basis: `maintenance-docs/v11-implementation/BD-195-CLEAN-FOUNDATION.md`). v11.0 sweep = 48 problems (P-31l deferred to v11.1 groupings → BD-189). Executed serially; BD-196 (Resolved) gives a cleaner corpus to fix into, not a smaller count. See Segments below.

Segments (2026-05-31, consolidated into the execution plan `maintenance-docs/v11-implementation/PLAN-BD-195-REMEDIATION.md`; SERIAL execution in this branch):
  - S0 — re-anchor (NQ-1): re-anchor the problem-list citations to the BD-196-relocated rule-corpus locations. Prep; runs first.
  - S1 — Mis-versioning de-contamination (12): P-01, P-02, P-08, P-09, P-12, P-13, P-16, P-17, P-18, P-31a/b/k. Both BLOCKERs. Intra-order: P-13 → P-01 → P-02 (+P-12/P-08/P-31a lock-step). Hard prerequisite for the BD-185 restart.
  - S2 — Client-surface integrity + currency (13): everything a v11.0 client install receives. Launch-visible.
  - S3 — Pack-internal hygiene + currency (18; 17 in the v11.0 sweep after P-31l→v11.1): pack docs/product/prison-refs, not shipped.
  - S4 — Pack-self governance + agent/skill parity (6): PM-only governance + pack-agent trinity.
  Coverage: the 49 live problems partition disjointly across S1–S4 (12+13+18+6=49); P-29a struck (closed by BD-196). v11.0 sweep = 48 (P-31l → BD-189). The 12 open decisions (OQ-1,2,4,5,6,7 + OQ-3 partial + OQ-8 + NQ-1…NQ-4) are surfaced + resolved per-segment.
  Order: S0 → S1 → S2 → S3 → S4 (BD-195 complete) → BD-185 restart → v11.0 launch. Launch gate = S1 ∧ S2 ∧ S3 ∧ S4 ∧ BD-185. Each segment runs the standard per-commit bounded review/fix cycle; S1 takes a planner pass (de-contaminate/adapt the held V2 §10 recipes).
  Missed-finding ledger (S1·C3, 2026-05-31): the BD-193 PHASE-4 (§3.1.2 / §4.7-M-5) "CONFIRMED-CORRECT" verdicts + PHASE-5 §4 S-1 framing, and the BD-185 H.1 review, BLESSED the fictional `templates-archive/v11.1/` cut rather than catching it (P-08). Corrected in S1·C3 — those records carry in-place reversal notes; the v11.1 cut is retired + the SCHEMA relocated to v11.0. Lesson for the review process: apply a v11.0-vs-v11.1 categorical check (phase-parts was always v11.0).

Goal: Bring v11.0 to a pristine state following Batch 19c BEFORE any new BD-185 work begins. Supersede the entire prior BD-185 attempt with new docs while retaining the user's preapproved good decisions so they need not be re-explained. FORWARD FIX BIASED TOWARD COMPLETE REDO of the BD-185 attempt; prior committed work is not anchored on or salvaged unless a fix pass independently proves it correct.

Scope: EVERYTHING — entire repo, pack and project sides, every doc/script/file, including all BD-185-attempt work, Batch 19c, and prior. No carve-outs; no prior BD (incl. BD-193/BD-194) is special-cased. ONLY excluded location: the prison directory (Step 2).

Known-broken SEED (non-exhaustive): v11.0/v11.1 mis-versioning + pack/project boundary residue are the two we currently KNOW about. We do not know whether these are the only ones — the investigation must surface the rest.

Surfacing standard (applies to every researcher/audit/architect pass): proactively highlight ANY potential inconsistency or needed fix, not just the known seed. Each item is presented as the AGENT's finding + recommendation (Pack Chat relays it as the agent's, never its own), with enough self-contained context that the user can decide WITHOUT re-reading the chat or cross-referencing other docs. The user decides what to act on, if anything.

Quality bar: broad AND deep — never broad-but-sparse. The work may be segmented across multiple docs-researcher passes and multiple architect passes; that is expected and fine, provided all segments share the same standards, guidelines, and output-shape so the final reconciliation combines them smoothly.

Steps:
  STATUS (2026-05-31): Steps 0–4 done (investigation + audit, re-audited post-BD-196). Steps 5–8 now run PER-SEGMENT per the Segments subsection above, in order S0→S1→S2→S3→S4. Step 9 (BD-185 restart) runs AFTER the full sweep (its S1-complete precondition is honored by the ordering).
  0. Investigation-approach planning (runs FIRST): a planner agent takes this BD-195 directive and produces the INVESTIGATION PLAN — segmentation of the docs-researcher and architect passes (broad + deep), the shared standards / guidelines / output-shape across all segments (incl. the surfacing standard above), and the final reconciliation pass that combines the segments. Goes to the user for review before any researcher/architect work runs. This plan also sequences how Steps 1-2 relate to the investigation. (Distinct from the Step-6 fix-implementation planner.)
  1. Extract the user's preapproved good BD-185 decisions into a clean Retained-Decisions doc; user confirms the retained set. Runs before Step 2 so the decisions survive prisoning/deletion of the contaminated sources.
  2. Create a dedicated "prison" directory (distinct from maintenance-docs/archive/) and move EVERY superseded doc into it — INCLUDING superseded docs already in maintenance-docs/archive/ (archived AND superseded = doubly useless → prison). maintenance-docs/archive/ retains ONLY non-superseded historical records. Presence in the prison = superseded/contaminated = IGNORED at every step; status is unambiguous without opening the file. PRISON DISPOSITION RULE (must be stated identically in every step and every agent prompt): no agent ever audits, edits, trusts, or treats as authoritative any doc inside the prison directory — its sole status is "superseded, ignore."
  3. Per the Step-0 plan: segmented docs-researcher + audit passes over the ENTIRE repo (pack + project), every file except the prison directory, producing ONE exhaustive, reconciled problem list (the known seed + ALL other surfaced potential issues, each per the surfacing standard). No piecemeal NIT-patching that interrupts core work.
  4. Verify + blast radius: part of Step 3's passes (every touch point mapped).
  5. Per the Step-0 plan: segmented architect passes design fixes for ALL surfaced problems — every touch point including the BD-185 work — combined by the final reconciliation pass.
  6. Fix-implementation planner produces the fix plan — every touch point including the BD-185 files.
  7. Implement the fixes.
  8. Extensive reviews + audits of the fixes.
  9. ONLY then, fresh-start BD-185 — decide whether the BD-185 work-so-far is wiped or the fix pass proved it correct (bias: complete redo). Step 9 MUST examine the BD-185-attempt artifacts for disposition (fix-in-place / prison / wipe): (a) the **4 held design-substrate docs that STAY LIVE** for the restart — `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md`, `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`, `PLAN-BD-185-V2.md`, `maintenance-docs/v11-research/RESEARCH-BD-185-ORDERING-API.md`; (b) the **8 contaminated attempt-records** (`PACK-REVIEW-BD-185-H.2.md` [P-09], `PACK-REVIEW-BD-185-H.1.md` [P-18], the 6 `IMPLEMENTATION-REPORT-BD-185-*` [P-17]) — **Pattern-B swept to `maintenance-docs/archive/v11/` per BD-195 S1·C5** (their v11.1 framing preserved as history; out of the active tree). Detailed as P-09/P-17/P-18 in `maintenance-docs/v11-implementation/AUDIT-BD-195-VERIFIED-FINDINGS.md` (G3 decision, 2026-05-29: OQ-1(3)/OQ-3; swept per S1·C5 2026-05-31).

Position: precedes the BD-185 restart; fires before any new BD-185 work. The prior BD-185 attempt (committed H.1/H.2 + the untracked V2 analysis docs) is paused (see BD-185) and in-scope for supersession.

---

**BD-196 — Document concision + boundary-completeness guardrails (rule-corpus restructure + single-SSOT discoverability)**
Type: feat — pack-only operational; STRUCTURAL (amends pack-memory rules, adds validator checks, reshapes durable pack-ops docs).
Status: Resolved
Resolved: 2026-05-31 — implemented per PLAN C1–C12 + the S1 corpus-reconciliation follow-up; 14 CI-green commits (baseline 96b174a → S1 f52752d). One SSOT per concept (`pack-ops/PACK-MEMORY-RATIONALE.md`, bijection 20==20 via Check 45); M4 concision gate (Check 44) + B5 manifests / spawn-rule anti-restate (Check 46) + extended Check 37 companion-template walk; forward-only durable docs (history → `maintenance-docs/archive/v11/`); one-hop §11.3 routing + §12 propagation procedure. C12 end-of-batch audit CLEAN; S1 47-bullet corpus classification confirms the rule corpus is fully reconciled. Out of scope as planned: fence-marker refactor (§8 step 8); no new standing rule added.
Surfaced: 2026-05-30 — user-directed effort during BD-195 to fix document bloat while keeping the guardrails authoritative.
Blockers: None — design (`maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` v9) + plan (`maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md`, commits C1–C12) complete and user-approved.
Unblocks: BD-195's downstream fixes inherit a concise, single-SSOT, discoverable rule corpus; future rule changes follow the §12 propagation procedure.
File/Symbol: per `PLAN-DOC-CONCISION-GUARDRAILS.md` C1–C12 — `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory` (imperative + `[roles:]` + `[rationale: slug]`); NEW `pack-ops/PACK-MEMORY-RATIONALE.md`; reshaped `pack-ops/BOUNDARY-DEFINITION.md`; `pack-ops/PACK-CHAT.md` / `pack-ops/PACK-AGENTS.md` (collapse restatements + routing + §12 procedure); `scripts/validate-pack.py` Checks 44 (M4 concision gate) / 45 (C3 bijection) / 46 (B5 + spawn-rule) + per-check tests + CI; NEW `pack-ops/.spawn-rule-manifest.txt` / `.boundary-pointer-manifest.txt` / `.concision-allowlist.txt`; the 6 other durable `pack-ops/` docs.
Description:
  **Problem:** pack rule/SSOT docs accreted proof / rationale / history / temporal-provenance content (bloat), and the spawn-relevant rules are fragmented + duplicated across four surfaces with no single discoverable SSOT — rules are hard to find, drift-prone, and the guardrails are not authoritative.
  **Goal:** eliminate the bloat AND retain the guardrails — one SSOT per concept; concise forward-only durable docs; rules discoverable one hop from each actor's entry doc; enforcement composed from validator checks. Not additive-only — stale content removed + orphaned references repaired (design §8 step 7b).
  **Success criteria:** the v9 design's locked decisions implemented per the plan — C1 imperative+rationale split; C3 single rationale file + bijection (Check 45); M1–M4 concision incl. the M4 gate (Check 44); B5 pointer-manifest + spawn-rule anti-restate/reference-resolution (Check 46); §9 single spawn-source + `[roles:]` role-tags; §11 discoverability (index dropped, one-hop routing); §12 rule-change propagation procedure; D1 companion-template Check-37 walk; D2 purpose-classifies-location; §8 step 7b stale-reference blast-radius sweep; validate-pack + per-check tests green at every commit; C12 final end-of-batch review + whole-repo completeness audit (no surface missed).
  **Out of scope:** the optional fence-marker refactor (design §8 step 8, deferred); BD-195's own scope; any NEW standing rule.
  **Pipeline:** design → plan (both complete) → implementation C1–C12 with the per-commit bounded review/fix cadence + the end-of-batch reviewer (existing rule).
Position: worked immediately; per user direction 2026-05-30 no other BD is worked until BD-196 resolves. BD-195 disposition was decided after BD-196 completed (2026-05-31): re-scope, option C — see the BD-195 State line.

---

**BD-197 — Worktree isolation: remove the prohibition and enable safe, opt-in parallel agent execution (pack + client; graceful degradation)**
Type: feat — STRUCTURAL. Spans pack-self governance + client-shipped workflow; requires the full pipeline (researcher → architect → planner → coder → bounded review/fix). Supersedes the original removal-only BD-197 (committed d4252d3) per user direction 2026-06-02. No scope keyword asserted — phase commits declare their own.
Status: Unblocked
Target: v11.0 (user direction 2026-06-04 — BD-197 is in v11.0 scope).
Blockers: ALL phases (P1 brainstorm/research through P2/P3 editing) wait until BD-195 is complete — not split, not started early. Even the audit/research needs a stable tree: BD-195's S2/S3/S4 churn the same files (CLAUDE.md ## Pack memory, maintenance-docs/ plans, commit-discipline mirrors, pack-ops/) and S4 may relocate or add worktree content. Timing after BD-195 is the user's call — possibly directly after, possibly after further BD batches (other work may be more urgent). The user moves this to Open/Unblocked when ready. UPDATE 2026-06-04: BD-195 Resolved 2026-06-03 → this gate is CLEARED; Status moved to Unblocked; confirmed v11.0 scope per user. Start timing remains the user's call.
Unblocks: A developer who opts in can run spawned agents in isolated worktrees for safe parallel execution; the pack no longer prohibits isolation and instead supports it where the developer enables it — while continuing to work with zero failures for developers (and CLIs) that do not.
File/Symbol: Two distinct surfaces, both audit-refreshed at implementation time (line numbers drift):
  - REMOVAL targets (P2) — the current prohibition + bug-era content (pack + client). Starting list from the 2026-05-31 prework inventory (~15 carriers): `CLAUDE.md` worktree bullet in the `### Sub-agent behavior (Claude-only)` subsection; `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`; `maintenance-docs/v11-implementation/` EXECUTION-PLAN-V11.0 §D / PLAN-SKILL-DIMENSIONS §4.8 / PLAN-DOC-CONCISION-GUARDRAILS / ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION (stale-line-range row); `.claude` + `.codex` + `.gemini` `skills/commit-discipline/SKILL.md`; 4 dangling refs to deleted `feedback_worktree_isolation_broken_from_v11_clone.md` (ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY, RESEARCH-CLAUDE-REPOS-SURVEY, RESEARCH-19C-G-ITEMS-VERIFICATIONS); 4 historical decision-records (dispositioned per audit). The fresh P2 audit rebuilds this list.
  - ADDITIVE surfaces (P3) — to be defined by P1, but anticipated: pack-side + client-side `OPTIONAL-FEATURES.md` (the `worktree.baseRef:"head"` prerequisite, associated with the existing Agent-Teams opt-in pattern — `pack-ops/OPTIONAL-FEATURES.md` + `project-template/docs/pack/OPTIONAL-FEATURES.md`; final placement identified in design); a redesigned `commit-discipline` capability; pack-self + client agent-workflow rules/docs for the persist + merge-back mechanism.
  - PREWORK reference: the 2026-06-01 (v3) blast-radius inventory prompt, saved at `maintenance-docs/v11-implementation/PREWORK-BD-197-WORKTREE-ISOLATION-AUDIT-PROMPT.md`. It is **BD-197 PREWORK ONLY — a non-binding starting reference for the P2 removal audit, NOT the final audit prompt or scope.** P1/P2 author their own prompts fresh.
Description:
  **Problem:** Pack and client content currently PROHIBITS Claude Code Agent-tool worktree isolation (a rule in `CLAUDE.md ## Pack memory` + reproductions across multiple v11-dev planning/skill docs + bug-era assumptions in the `commit-discipline` mirrors). The prohibition existed because of an Anthropic-side bug (isolated worktrees created at `origin/main` HEAD regardless of parent branch). A developer-side workaround now exists and is verified: `"worktree": { "baseRef": "head" }` in `~/.claude/settings.json` makes isolated worktrees check out at the parent chat's local HEAD (probes 2026-05-31 / 2026-06-01). The goal is no longer to stay silent — it is to REMOVE the prohibition and make safe, opt-in isolated parallel agent execution POSSIBLE, should the developer choose it.
  **Position — EXPLORATORY, phased; the shape is NOT yet decided.** The user has deliberately not committed to the end-state UX or option-set. The right shape is settled by a brainstorm + researcher/architect/planner pipeline, not prescribed here. Pack Chat authors no design; the agents reach their own conclusions and surface them for user decision.
  **Phases (PROVISIONAL — P1 defines the rest; "there may be more"):**
    - **P1 — Brainstorm + research the shape.** Define the developer experience and the option-set for safe isolated parallel execution: candidate persist + merge-back mechanisms, cross-CLI behavior, graceful-degradation model. researcher + architect (planner as needed). Research/design only. Output defines P2/P3 and any further phases.
    - **P2 — Remove the prohibition + all bug-era guardrails/mentions everywhere (pack + client).** The prohibition rule, the reproductions, the stale commit-discipline assumptions, the 4 dangling memory-pointer refs, and the 4 historical decision-records (dispositioned). Fresh audit (`--hidden --no-ignore`, dual-tree v11-dev + main clone, project-template + AGENTS/GEMINI verification) seeded by the prework prompt. Clean slate before P3 builds.
    - **P3 — Implement safe, opt-in isolated parallel execution.** Rules + mechanism + docs for spawned agents in isolated worktrees, pack-self AND client, designed in P1. Resolves the two known problems (below) and degrades gracefully.
    - Pipeline: researcher → architect → planner → coder → per-commit bounded review/fix cycle.
  **Known problems for the architect to solve (from the 2026-06-01 probes):**
    - **(A) Work-not-persisted.** Agent-tool `isolation:"worktree"` worktrees are auto-removed on agent return, and the `agents-never-commit` rule bars the agent from persisting via commit → edits made in an isolated worktree are lost.
    - **(B) No clean merge-back.** The `worktree-agent-*` branch is auto-deleted on agent return (probe-confirmed) → any commits become dangling; no supported path to merge an isolated agent's work into the parent branch.
  **Hard constraints on the design:**
    - **`agents-never-commit` is challenged, not relaxed by default.** The architect MUST rigorously exhaust alternatives (e.g., a Pack-Chat-mediated capture/merge protocol) before considering any relaxation. Letting agents commit is an ABSOLUTE LAST RESORT, permitted only if no other solution is possible, and ONLY with explicit user sign-off at design time. The architect must not accept it lazily; the default expectation is that it is NOT needed.
    - **Document the `worktree.baseRef:"head"` prerequisite; ship/auto-write NO settings file.** Associate it with the existing Agent-Teams opt-in documentation pattern in `OPTIONAL-FEATURES.md` (pack-side + client-side; exact placement identified in design). The pack never writes or ships a user/project settings file for this.
    - **Graceful degradation is REQUIRED.** Without the `baseRef` setting, and on Codex CLI and Gemini CLI (NEITHER of which supports this isolation feature), the pack MUST work fully and without failure — degrading to non-isolated sequential agents / each CLI's native behavior. The isolated-parallel capability is Claude-only (trinity-exemption pattern); its absence is never an error.
  **Scope:** pack-self workflow (PACK-CHAT / PACK-AGENTS / pack-* agents / commit-discipline) AND client projects (`project-template/` agent workflow + client docs).
  **Out of scope:** the `main` branch (v11-dev edits reach main at v11.0 merge); shipping or auto-writing any `.claude/settings.json` / `settings.local.json` at any scope (user-global, pack, or project-template); further exclusions as P1 determines.
  **Process note (P2/P3 implementer):** edits to `CLAUDE.md ## Pack memory` follow the PM-chat / trinity-governed propagation procedure in `pack-ops/PACK-CHAT.md` (§12), not ordinary doc edits.
  **Acceptance criteria (PROVISIONAL — refined by P1):**
    - The prohibition and all bug-era worktree-isolation content are gone from pack-side and `project-template/` content.
    - Safe opt-in isolated parallel execution is documented and functional on Claude Code when the developer enables `baseRef:"head"`.
    - Graceful degradation verified: with no setting, and on Codex + Gemini, the pack runs with zero failures (non-isolated fallback).
    - `agents-never-commit` is preserved, unless a user-signed-off last-resort exception is recorded with the architect's exhaustion rationale.
    - The 4 dangling memory-pointer refs are excised; the stale line-range citation in ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION is removed; the 4 historical records dispositioned.
    - `scripts/validate-pack.py` passes; no settings file shipped/auto-written; no edits outside v11-dev.
  **References:** Probes 2026-05-31 (bug confirmation: agent landed at `origin/main` `7ccbba9`) and 2026-06-01 (baseRef at project-level, then user-global only — agent landed at parent HEAD `3178fa4`, confirming user-global suffices) + the 2026-05-31/06-01 blast-radius inventories (captured as the prework artifact above).
Position: fully queued behind BD-195 — no phase begins until BD-195 is complete; the user decides the exact start (immediately after, or after further batches) and moves it to Open/Unblocked then.
Resolved: n/a

---

**BD-198 — Formalize `pack-ops/PACK-MEMORY-RATIONALE.md` as a PM-only surface (close BD-196 classification gap)**
Type: fix — pack-self governance. Registers an existing pack-memory surface in the two PM-only lists + a guard test. No scope keyword on the entry; the commit is pack-only.
Status: Open
Blockers: none (independent of BD-195; rides the same branch).
Unblocks: Pack Chat may edit the rationale doc directly under the PM-only contract, and a `## Pack memory` rule-change commit that updates the rule + its rationale section may correctly claim the `PM-only` scope keyword (Check 36).
File/Symbol:
  - `pack-ops/PACK-AGENTS.md` § "PM-only files and directories" Files list — add `PACK-MEMORY-RATIONALE.md` (the edit-authority SSOT).
  - `scripts/validate-pack.py` `_PM_ONLY_PERMITTED_PATHS` (~:3788) — add `pack-ops/PACK-MEMORY-RATIONALE.md` (the Check-36 mirror, kept in sync with the SSOT).
  - `scripts/tests/` Check-36 test — assert a PM-only commit touching the rationale doc passes.
Description:
  **Problem:** `pack-ops/PACK-MEMORY-RATIONALE.md` (created by BD-196 as the rule↔rationale bijection partner for trinity `## Pack memory`) is edited ONLY in lockstep with `## Pack memory` rule changes (Check 45 forces a rationale-section edit whenever a `[rationale: slug]` is added) — so it is intrinsically PM-only. But BD-196 never registered it in either PM-only list (`PACK-AGENTS.md` § "PM-only files and directories", nor `validate-pack.py` `_PM_ONLY_PERMITTED_PATHS`). Surfaced during BD-195 PM-step-DD, where a `PM-only` commit including the rationale doc would have failed Check 36.
  **Fix:** add it to both lists (kept in sync) + a Check-36 regression test.
  **Scope:** pack-self governance only.
  **Out of scope:** the per-entry `/backlog/`, `/changelog/` trees (not yet created); any other surface.
  **Acceptance criteria:** doc listed in PACK-AGENTS PM-only Files; present in `_PM_ONLY_PERMITTED_PATHS`; Check-36 test asserts a PM-only commit touching it passes; `validate-pack.py` PASSES.
  **References:** surfaced in BD-195 PM-step-DD (the dependency-direction-placement rule, 2026-06-03); the BD-196 bijection that introduced the unregistered doc.
Resolved: n/a

---

**BD-199 — Optimize validate-pack.py runtime regression (Check 43 per-iteration regex recompilation)**
Type: fix — pack tooling performance. Behavior-preserving optimization of the project-side bare-cross-reference scanner. Commit pack-only (`scripts/` only).
Status: Resolved
Blockers: Lands AFTER BD-195's content commits (C6–C8) and BEFORE the BD-195 batched push — the fix touches `scripts/validate-pack.py`, which C5/C6 also edit, so sequencing avoids conflict. Design doc: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-199-VALIDATE-PACK-PERF.md`.
Unblocks: CI `tests` job returns to minutes (from ~2h); every reviewer/coder validate-pack verification + every test that invokes validate-pack speeds up proportionally.
File/Symbol:
  - `scripts/validate-pack.py` `check_project_side_bare_internal_refs` (~:5474, Check 43) — eliminate per-iteration regex (re)compilation (pre-compile once / collapse per-candidate patterns into one combined regex / plain string ops where a literal suffices). Behavior-preserving.
  - Sibling scanners (Check 40 `pack-ops/` bare-ref scanner; Check 47 sanctioned-shipped) — sweep for the same anti-pattern; fix if cheap + identical pattern, else note as negligible.
Description:
  **Problem:** validate-pack.py has a severe runtime regression — a full run takes minutes; the CI `tests` job (invoking validate-pack across ~38 steps) takes ~2h, vs under 4min at commit C1 (before C2). A cProfile run (HEAD `696528b`, 2026-06-03) attributes ~99.9% of the runtime to `check_project_side_bare_internal_refs` (Check 43, broadened by BD-195 C2): it calls `re.search`/`re.compile` ~11.4M times — recompiling a regex per loop iteration (compiles ≈ searches → essentially every search is a regex-cache MISS).
  **Fix:** behavior-preserving optimization so Check 43 detects IDENTICALLY but in ~seconds. Pre-compile patterns once / combined alternation / string ops. Sweep Check 40/47 for the same anti-pattern.
  **Scope:** pack tooling performance only (`scripts/validate-pack.py`). Behavior-equivalence is MANDATORY (the existing Check-43 test + a before/after validate-pack output diff must show identical findings).
  **Out of scope:** any change to WHAT Check 43 detects; the test-suite structure (reducing redundant validate-pack invocations across CI steps is a separate possible follow-up).
  **Acceptance criteria:** validate-pack wall-time drops from minutes to ~seconds; `re._compile` call count drops from ~11.4M to ~K; validate-pack findings byte-identical before/after; existing Check-43 test passes; validate-pack GREEN (fire-set 0).
  **References:** `ARCHITECTURE-BD-199-VALIDATE-PACK-PERF.md` (design, in progress); cProfile data 2026-06-03 (HEAD `696528b`); regression introduced by BD-195 C2 (broadened Check 43 file walk).
Resolved: 2026-06-03 — Check 43 (`check_project_side_bare_internal_refs`) optimized behavior-identically: per-iteration regex (re)compilation replaced by a precompiled, length-sorted alternation + per-line candidate dedupe + hoisted prefix patterns. Equivalence proven (exhaustive OLD-vs-NEW finding diff over the full project-side tree = 0 mismatches; Check-43 test passes). Check-43 wall 355s→0.62s; `re._compile` ~11.4M→3; full validate-pack minutes→~1.2s; CI tests job ~2h→~4min (run 26927439269). Commit `bf9d157`; design `ARCHITECTURE-BD-199-VALIDATE-PACK-PERF.md`.

---

**BD-200 — Project-side capability ACTIVATION (no pack-clone dependency): project-side `activate-capability.sh` + tracked conditional-file pool + single-source capability tables + Procedure 6 redesign**
Type: feat — STRUCTURAL. Spans client-shipped scripts, the conditional-file distribution mechanism, a capability-table single-source refactor, and multiple client docs (METHODOLOGY Procedure 6, HELP-FRAGMENT, PM-CHAT, INSTALL-PROCEDURES). The cross-version `pack update` pool refresh + the general update-propagation engine moved to BD-202 (see Scope split). Requires the full pipeline (first architect → ADVERSARIAL fresh-architect review → planner → coder → bounded review/fix). No scope keyword on the entry; phase commits declare their own.
Status: Resolved
Blockers: Follows BD-195 (Resolved 2026-06-03). The ADVERSARIAL fresh-architect review COMPLETED 2026-06-04 (`ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md`) — it is the AUTHORITATIVE corrected design (the first `ARCHITECTURE-BD-200.md` is the superseded subject). It corrected the gitignored-pool choice + 4 further gaps (GAP-A root-files-never-installed, GAP-B total update delete gap, GAP-C `.pack-*` name reflex, GAP-D single-source unresolved). Planner next, against the corrected design. NOT blocked by BD-202 (only the deferred cross-version pool refresh is BD-202-coupled).
Unblocks: a client project can ACTIVATE a pack-supported capability (a D1–D5 dimension — platform / language / protocol / deployment surface, e.g. add Python or a server component to an existing Swift/iOS project) WITHOUT a pack-repo clone, on ANY clone of the project. Precedes v11.0 launch (launch gate: S1 ∧ S2 ∧ S3 ∧ S4 ∧ BD-195 ∧ **BD-200** ∧ BD-203 ∧ BD-204 ∧ BD-197 ∧ BD-185 ∧ BD-205 — BD-203/204 (pack self-migration, pack-only) + BD-205 (final v11.0 readiness audit) added per user direction 2026-06-04; launch order: BD-200 → BD-203 → BD-204 → BD-197 → BD-185 → BD-205 → launch).
Corrected problem (measure-first, HEAD `972c3a1`, 2026-06-03):
  - Copy-ALL-skills is ALREADY the install behavior (`stage_s4_skills()` copies every skill to all three trinity dirs unconditionally); skill count (36) is ALREADY reconciled in README + PLATFORM-SKILLS. These are NO-OPS, not work items — the original entry's "copy all skills at install" + "skill-count reconcile" directives were STALE and are removed in this re-scope (architect §7 + user direction 2026-06-04).
  - The real pack-clone dependency: `add-capability.sh` copies conditional files (`pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`, per-language `*-python.sh`/`*-swift.sh`/`proto-*.sh`) from `$PACK/project-template/`, and `stage_s9_conditional_remove()` DELETES exactly those at install for languages the project lacks. A client without the pack clone has no source to re-materialize them — THIS is the problem BD-200 solves.
Goal: make capability ACTIVATION a project-side ability with NO pack-clone dependency, working on any clone of the project.
Binding design decisions (user, 2026-06-03/2026-06-04 — FIXED inputs to the adversarial architect; not for re-litigation, though the architect MUST surface any it finds unrealizable rather than silently deviate):
  - REPLACE (OQ-1): the project-side script is a NEW self-contained artifact reusing the capability tables as DATA only; pack-side `add-capability.sh` stays unchanged.
  - NO guard change (OQ-2): no `_SANCTIONED_PACK_SIDE_SHIPPED` growth, no Check 47/41/39 movement, no architect+user sign-off.
  - Placement + name (OQ-3): `project-template/scripts/activate-capability.sh` — distinct name ("activate" = skills already shipped, conditional files re-materialized; sidesteps the pack-vs-project basename collision; no `x-` prefix).
  - Pool TRACKED, not gitignored: the conditional-file pool is a tracked client artifact (consistent with skills + conditional files, which ARE tracked), so activation works on ANY clone with no pack. Gitignoring REJECTED — it version-excludes the only re-materialization source (defeats the no-pack-clone goal on fresh clones) and contradicts the install model where all pack-provided masters are tracked.
  - SINGLE-SOURCE capability tables: `capability_skills`/`capability_files`/`capability_install_checks` live in ONE authored source consumed by BOTH `add-capability.sh` and `activate-capability.sh` (the client gets its own tracked copy) — eliminate drift by construction, not a parity check.
  - SCOPE SPLIT (user 2026-06-04, Option 1, adversarial review §10): BD-200 owns FRESH-INSTALL pool population (pure copy; no prior-state reconciliation). The pool's cross-version `pack update` REFRESH + the general update-propagation engine (delete + clean-modify correctness across asset classes AC-1..AC-4, `x-`-safe, customization-preserving) move to BD-202 — the pool is BD-202's degenerate AC-1 consumer. BD-200 ships its full user-visible capability (activate on a fresh clone) on the sequencing-INDEPENDENT parts + fresh-install pool; only the cross-version refresh is BD-202-coupled, so BD-200 is NOT blocked by BD-202.
File/Symbol:
  - NEW `project-template/scripts/activate-capability.sh` — client-runnable, NO `$PACK`; re-materializes conditional files from the tracked client-local pool.
  - NEW tracked client-local pool `pack-capability-pool/` (TRACKED, non-dotted — `.pack-*` denotes gitignored local state, GAP-C). Holds the full conditional-master set so `activate-capability.sh` re-materializes any conditional file with NO `$PACK`.
  - `scripts/init-project.sh` — NEW language-independent FRESH-INSTALL stage (S5b) populating `pack-capability-pool/` DIRECTLY from `$PACK/project-template/` conditional masters (GAP-A: the root files `pyproject.toml`/`pyrightconfig.json`/`server/`/`proto/` are NEVER otherwise installed, so they cannot be captured from the live tree); `stage_s9_conditional_remove()` unchanged + a defensive skip so it never touches the pool. The cross-version `pack update` pool REFRESH → BD-202 (AC-1 consumer).
  - Capability tables (`capability_skills`/`capability_files`/`capability_install_checks`, today inline in `scripts/add-capability.sh`) — refactor to a single authored source consumed by both scripts.
  - `scripts/add-capability.sh` — pack-side tool, scope UNCHANGED.
  - `supporting-docs/METHODOLOGY.md` Procedure 6 — redesign as a self-contained project-side workflow (no "run from the pack"; zero pack-self tokens).
  - `project-template/docs/pack/HELP-FRAGMENT.md` (re-add a corrected `activate-capability.sh` verb row — reverses BD-195 C1's delete, since the underlying fact changed), `project-template/docs/pack/PM-CHAT.md` "Capability addition" rule, `supporting-docs/INSTALL-PROCEDURES.md` — rework references to the project-side mechanism.
  - `project-template/.gitignore` — NO pool ignore line (pool is tracked).
  - `scripts/validate-pack.py` — confirm Check 41/47/39 stay green with no allowlist growth; Check 43 (pack-self-leak) clean on the redesigned Procedure 6 + references; Check 22 (help-fragment freshness) verb-token consistency.
Description:
  **Problem:** see "Corrected problem" above — copy-all-skills is already done; the real dependency is conditional-file re-materialization without `$PACK`.
  **Goal:** project-side capability ACTIVATION with no pack-clone dependency, on any clone; see "Binding design decisions" for the fixed constraints.
  **Scope:** project-side `activate-capability.sh` + the tracked `pack-capability-pool/` + its FRESH-INSTALL population stage (S5b) + the `stage_s9_conditional_remove()` defensive skip + the single-source `capability-tables.sh` refactor (incl. the ratified behavior-preserving `add-capability.sh` source-line edit) + Procedure 6 redesign + client-surface reference rework. EXCLUDES the cross-version `pack update` pool refresh + the general update engine (→ BD-202).
  **Out of scope:** BD-195's other v11.0-pristine findings (handled in BD-195); the copy-all-skills install change + skill-count reconciliation (NO-OPS — removed from scope).
  **Acceptance criteria:** a client can ACTIVATE a capability (e.g. add Python to a Swift-only project) with NO pack clone present, on a FRESH clone of the project; `pack-capability-pool/` is tracked and travels with the repo; capability tables single-sourced (zero drift by construction); Procedure 6 + client-surface references describe the project-side mechanism (no "run from the pack", zero pack-self tokens — Check 43 + Check 37 clean); `validate-pack` green; dependency-direction rule + Check 47 honored (no allowlist growth). (Cross-version `pack update` pool-refresh correctness → BD-202 acceptance, not BD-200's.)
  **References:** `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (AUTHORITATIVE corrected design — §1-9 + the §10 BD-200↔BD-202 sequencing); `ARCHITECTURE-BD-200.md` (superseded first design — the review's subject); `ARCHITECTURE-BD-195-ADD-CAPABILITY-SHIPPING.md` (the verdict that triggered this); BD-202 (the general update engine the pool refresh registers with); user design decisions 2026-06-03 / 2026-06-04 (OQ-1/2/3 + tracked pool + single-source + Option-1 scope split); `dependency-direction-placement` (trinity `## Pack memory`).
Resolved: 2026-06-04 — shipped C1–C5 + the integrated close-out review. C1 single-source `capability-tables.sh` (+ behavior-preserving `add-capability.sh` refactor); C2 fresh-install pool stage (S5b) + S9 pool-skip + detector pool-exclusions + the F1 `detect.sh` cross-ref; C3 client `activate-capability.sh` (P0–P8, no `$PACK`, `x-`-on-overwrite guard, prompt-gitignore) + verb/reference rework (incl. the R3 INSTALL-PROCEDURES correctness fix) + a 27/0 activation harness; C4 self-contained Procedure 6 redesign (zero pack-self tokens). The integrated close-out review (`PACK-REVIEW-BD-200-INTEGRATED.md`) was CLEAN on every acceptance criterion (fresh-clone no-`$PACK` activation, tracked pool incl. GAP-A root files, single-source, whole-surface boundary, detection completeness, Check 47 frozen); its one finding (F-1 misleading P0 message) was fixed in C5. The cross-version `pack update` pool refresh + general update engine are deferred to BD-202 (Option-1 scope split). validate-pack GREEN; full CI suite GREEN (run on `3e8a8a4`; close-out review committed `cbcc79e`). Advances the v11.0 launch gate.

---

**BD-202 — Universal `pack update` propagation engine (delete + clean-modify correctness across asset classes; `x-`-safe, customization-preserving)**
Type: feat — STRUCTURAL. Pack-side update mechanism (`cmd_update` / `customization-preserve` / `three-way`). Requires architect → planner → coder → bounded review/fix. No scope keyword; phase commits declare their own.
Status: Open
Target: v11.1 (NOT v11.0) — see Disposition + reversal trigger.
Blockers: Co-design with BD-200's pool (the pool is this engine's degenerate AC-1 consumer — `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §10). Architect pass precedes implementation.
Unblocks: correct `pack update` across pack versions — pack-retired files removed, clean pack updates applied (not flagged for manual reconciliation), without clobbering project customizations or removing `x-` files. BD-200's pool cross-version refresh registers as the AC-1 consumer.
Problem (measure-first, HEAD `93a3337`; adversarial review §10.1-10.2, EEB-BASE/CLASSIFY/PRESERVE/XCLASS): `cmd_update` always calls `customization_preserve` with BASE="", so every delete arm in `three_way_classify` is unreachable → `pack update` propagates ZERO deletes for ANY asset class (a pack-retired master → `project-only-file` → PRESERVED), and clean pack modifications to un-customized files → `project-shadows-new-pack` → needs-reconciliation (over-conservative; no clean fast-path). The v10→v11 MIGRATOR is NOT affected (own manifest-driven `remove`/`removed-by-design` handling); the gap is specific to the in-place `--update` path.
Asset taxonomy (§10.2): AC-1 pack-owned never-modified `x-`-free (→ wipe-repopulate, lossless — the BD-200 pool); AC-2 customizable text (→ 3-way merge-preserve + delete-with-no-`x-`); AC-3 structured config (→ key-level structured merge); AC-4 mixed dirs holding `x-` files (→ per-file: pack→merge, `x-`→never touch). Change-patterns: CP-add (works), CP-modify-clean (broken — lossy reconcile), CP-modify-customized (works via shadow), CP-delete (broken — zero propagation), CP-x-preserve (works by-omission).
Scope: make CP-delete + CP-modify-clean correct across AC-1..AC-4 in `cmd_update` without clobbering customizations or removing `x-` files — via a real per-version pack BASE baseline OR an authoritative-roster reconciler + `x-`-guard hook; register BD-200's pool as the AC-1 consumer.
Doc-currency requirement (user 2026-06-04): BD-202 MUST fix not only the update-engine SCRIPTS but every DOC that DESCRIBES update / delete / `x-` / overwrite behavior (e.g., `INSTALL-PROCEDURES.md` `x-` guarantees; any doc disclosing `pack update` behavior). Docs are an encoding surface (`enumerate-encoding-surfaces`); behavior-describing docs must not drift from the corrected scripts. The BD-200 R3 `INSTALL-PROCEDURES` inaccuracy (`add-capability.sh` listed among file-deleting scripts when it deletes nothing) is the exemplar of the doc-drift to prevent — enumerate + update the doc surfaces in lock-step with the engine code.
Out of scope: the v10→v11 migrator path (separate, already delete-correct); BD-200's fresh-install pool population + client script (independent, in BD-200).
Disposition: TARGET v11.1. Rationale (user 2026-06-04): the gap is non-breaking and first exercised only at the FIRST post-v11.0 `pack update` (v11.1 or a content-changing v11.0.x patch); v11.0 fresh install + v10→v11 migration do not depend on it.
REVERSAL TRIGGER (user 2026-06-04): if ANY v11.0-process repo test breaks BECAUSE of this `cmd_update` delete/modify gap, BD-202 is PULLED INTO v11.0. Watch the later v11.0 test phases (live-GH test trio / Batch 23) for update-path failures attributable to this gap.
Acceptance criteria: `pack update` propagates pack deletes (AC-1..AC-4) with `x-` files never removed + customizations never clobbered; clean pack updates to un-customized files apply without spurious reconciliation; the BD-200 pool refreshes correctly as an AC-1 consumer; `validate-pack` green; no migrator-path regression.
References: `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §10 (taxonomy + sequencing + EEB-BASE/CLASSIFY/PRESERVE/XCLASS + the EEB-B self-correction); BD-200 (pool = AC-1 consumer).
Resolved: n/a
Position: v11.1; co-design with BD-200; must land by the first post-v11.0 `pack update` unless the reversal trigger pulls it into v11.0.

---

**BD-203 — Pack self-migration Phase 1: monolithic flat files → per-entry directory trees (Mode 1 → Mode 2)**
Type: feat — STRUCTURAL, pack-only. The pack DOGFOODS its own Mode-1→2 per-entry conversion on its OWN `pack-ops/BACKLOG.md` + `CHANGELOG.md` (TWO streams only — the pack has NO implementation-plan monolith; that earlier mention was an erroneous insertion, corrected 2026-06-04). Requires the pipeline: BOTH pack-side + project-side blast-radius RESEARCH first (`RESEARCH-BD-203-BLAST-RADIUS.md` + `RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS.md`) → an architect that reviews BOTH and DECIDES whether the pack + project designs are done together or separately (user 2026-06-04; the two prior designs `ARCHITECTURE-BD-203.md` + `ARCHITECTURE-BD-203-ADVERSARIAL.md` are REJECTED + superseded) → planner → (coder → bounded review/fix) per commit + a full integrated correctness audit at the end. The pack CONVERSION is pack-only; phase commits declare `pack-only`.
Status: Open
Target: v11.0 (launch-gate item, user 2026-06-04).
Blockers: Follows BD-200 (Resolved 2026-06-04). Sequenced BEFORE BD-197 (user 2026-06-04). Phase 1 of the two-phase pack self-migration; BD-204 (Mode 2→3 GH Issues) follows and depends on this.
Unblocks: the pack's backlog + changelog become per-entry DIRECTORY trees (`/backlog/`, `/changelog/`) as the SOLE SSOT + readable form (with a TOC index); the monolithic `pack-ops/BACKLOG.md` + `CHANGELOG.md` are DELETED (NO mirror — the per-entry tree IS both the source and the readable form). EVERY entry (Open, Deferred, Resolved, …) is preserved as a status-flagged per-entry file. BD-204 (GH Issues) builds on it.
Problem (measured 2026-06-04): the pack is fully MONOLITHIC — `/backlog/`, `/changelog/` do NOT exist; no `tracker.toml`; `pack-ops/BACKLOG.md` is the de-facto primary — yet `CLAUDE.md` (~lines 30/31/34) + README describe the pack as already per-entry-SSOT-with-mirrors (referencing nonexistent `/backlog/_rules.md`). A live doc-vs-reality gap.
Binding decisions (user 2026-06-03/04 — FIXED; the THIRD architect designs WITHIN them, designs the source-doc model correction + the pack conversion TOGETHER, and CHALLENGES every other choice the prior two designs made):
  - GENERAL STANDARD — retire the monolithic mirror (user 2026-06-04, scope A): the per-entry tree (+ a TOC index) is the SOLE SSOT AND the readable form. There is NO monolithic mirror. The monolith `pack-ops/BACKLOG.md`/`CHANGELOG.md` is the CONVERSION INPUT ONLY; after conversion it is DELETED (no mirror, no kept copy) — there must be NO case in which it is useful (agents repeatedly source from stale/wrong primaries; deletion forces dangling references to BREAK + SURFACE + be fixed). This is the corrected STANDARD for BOTH pack and project (same rules, different assets); BD-203 applies it to PACK assets + corrects the source docs.
  - CORRECT THE WRONG SOURCE DOCS (root cause): ~16 surfaces state "monolith = regenerated mirror" — the trinity `## Pack memory` "Per-entry trees vs mirrors" RULE + the trinity/README/`PACK-AGENTS.md`/`MERGE-STRATEGY.md` structure lines + the per-entry tooling comments. They are WRONG and MISLED the prior two architects. Correct them to the new standard as PART of BD-203. The convention is a trinity `## Pack-memory` rule → THIS architect pass IS the architect-first strategy for that rule change (coder applies after user approval). Correcting the shared convention must NOT create a NEW client doc-vs-implementation gap in v11.0 (client per-entry tooling still generates mirrors) — design how (scope/note the client side as pending BD-206).
  - PRESERVE EVERY ENTRY: every BD entry (Open, Deferred, Resolved, Deprecated, Cancelled, …) becomes a status-flagged per-entry file. Removing ANY entry is a VIOLATION — this is a format CONVERSION of existing state, NOT a restart; state must be fully preserved (same for BD-204's GH Issues). Per-entry GRANULAR access (+ TOC) inherently solves the monolithic-context-bloat worry; NO entry is archived out. (TRUE non-entry content — section labels, redundant summary tables, intra-section prose, old changelog FORMATTING — may be reorganized/dropped, but only after verifying it duplicates no entry STATE; when in doubt, preserve.)
  - SAFE before DELETE: confirm the per-entry tree captures EVERY entry content-faithfully (no BD/version/state lost) BEFORE deleting the monolith (the destructive step, gated on verification).
  - The deletion FORCES reference fixes: removing the monolith breaks every reference naming `pack-ops/BACKLOG.md`/`CHANGELOG.md` as a mirror/source (validators incl. Check 32, governance, tooling). Enumerate the full blast radius; fix each so validate-pack is GREEN with NO monolith. Supersedes the earlier "don't pre-edit the trinity" (the wrong docs ARE the root cause — fix them).
  - pack-only CONVERSION: the actual asset conversion + deletion touches ONLY pack assets (`pack-ops/`, the new pack trees, `scripts/`, validators, the shared trinity rule). The PROJECT-SIDE per-entry IMPLEMENTATION (client tooling dropping mirrors, `supporting-docs/MIGRATION-v10-to-v11.md`) is deferred to BD-206 (same standard, project assets, later).
Scope: design + apply the source-doc model correction (retire the monolithic-mirror across the ~16 surfaces, per the architect-first strategy) + create `/backlog/` + `/changelog/` per-entry SSOT trees from the monolith preserving EVERY entry (status-flagged) + a TOC index + the no-mirror `_rules.md` contracts + fix the full deletion blast radius (Check 32 + governance + tooling references) + DELETE the monolith last, gated on a verified-complete tree.
Out of scope: GH Issues / tracker Mode 3 (→ BD-204); the PROJECT-SIDE per-entry implementation (client tooling + MIGRATION doc) (→ BD-206); any implementation-plan stream (the pack has none).
Acceptance criteria (END-OF-BD FULL CORRECTNESS AUDIT): `/backlog/` + `/changelog/` are the SOLE per-entry SSOT + readable form (+ TOC); EVERY entry preserved content-faithfully + status-flagged (the per-entry BD count == the pre-conversion entry count; no entry lost) — verified BEFORE deletion; the monolith flat files DELETED (grep proves no surviving `pack-ops/BACKLOG.md`/`CHANGELOG.md`); the ~16 wrong source surfaces corrected to the new standard (no surviving "monolith = regenerated mirror" for the pack); every reference fixed (validate-pack GREEN with no monolith); NO new client doc-vs-implementation gap introduced; a full integrated correctness audit confirms no state lost + no stale-source path remains + reality matches the corrected docs.
References: `project_pack_self_migration_launch_gate` (pack memory); `ARCHITECTURE-BD-203.md` (the REJECTED first design — the adversarial architect's subject to challenge); `CLAUDE.md` repo-structure §; the client-shipped per-entry feature (Mode 1/2); BD-200 (precedes); BD-204 (follows).
Resolved: n/a
Position: v11.0 launch gate; after BD-200, before BD-197 (user 2026-06-04); BD-204 follows.

---

**BD-204 — Pack self-migration Phase 2: per-entry directory trees → GH Issues (tracker Mode 2 → Mode 3)**
Type: feat — STRUCTURAL, **pack-only (HARD CONSTRAINT)**. The pack DOGFOODS its own Mode-2→3 tracker (GH Issues) migration on its OWN backlog. Full pipeline (architect → planner → (coder → bounded review/fix) per commit) + a full integrated correctness audit at the end. Phase commits declare `pack-only`.
Status: Open
Target: v11.0 (launch-gate item, user 2026-06-04).
Blockers: Follows BD-203 (the per-entry trees must exist first). Sequenced BEFORE BD-197 (user 2026-06-04).
Unblocks: the pack tracks its OWN backlog in GH Issues (tracker Mode 3); the per-entry tree is regenerated-FROM-tracker per the Mode-2↔3 contract (NO monolithic mirror — corrected standard); exercises the TrackerProvider / GH-Issues machinery on the pack's own backlog (real dogfood).
HARD CONSTRAINT (user 2026-06-04): **pack-only — this BD must NOT touch `project-template/` or ANY project-side / client asset or workflow. If it affects the project side at all, that is a VIOLATION.** CI Check 36 `pack-only` enforces every commit; any project-side diff fails the gate.
REVERSIBILITY (HARD REQUIREMENT, user 2026-06-04): the per-entry ↔ GH-Issues conversion MUST round-trip LOSSLESSLY (per-entry → GH-Issues → per-entry == original) — not a one-way push. BD-204's full spec (no-mirror, reversible, entry-preserving) is designed in the BD-203 architect pass.
Problem: Phase 2 of the pack dogfooding its own tracker feature — after BD-203 makes the pack per-entry, this moves the SSOT to GH Issues, proving the reversible Mode-2↔3 migration on the pack itself.
Scope: migrate the pack's per-entry backlog → GH Issues (tracker Mode 3) per the forward-migration contract; `tracker.toml` (`mode.state = "tracker"`, `migration.forward_complete = true`); the per-entry tree is regenerated-from-tracker (NO monolithic mirror); verify forward + REVERSE (lossless round-trip) on the pack's own backlog — all pack-side only.
Out of scope: BD-203's per-entry conversion (prerequisite); ANY project-side change (a violation if it occurs); the PROJECT tracker (→ BD-207).
Acceptance criteria (END-OF-BD FULL CORRECTNESS AUDIT): the pack's backlog is tracked in GH Issues; forward migration LOSSLESS (every BD → an issue, content-faithful, EVERY entry preserved); REVERSIBILITY verified — the round-trip per-entry → GH-Issues → per-entry is LOSSLESS (== original); the Mode-2↔3 contract honored (per-entry tree regenerates from tracker, NO monolithic mirror); validate-pack green; **zero project-side changes (Check 36 `pack-only` clean on every commit)**; full integrated correctness audit.
References: `project_pack_self_migration_launch_gate`; BD-060 TrackerProvider abstraction; the tracker Mode 1/2/3 feature; BD-203 (prerequisite).
Resolved: n/a
Position: v11.0 launch gate; after BD-203, before BD-197 (user 2026-06-04).

---

**BD-205 — v11.0 final repo readiness audit + full test/audit/fix cycle (the last gate before launch)**
Type: feat/audit — STRUCTURAL. The comprehensive pre-launch readiness gate: a full test → audit → fix cycle, iterated until clean (auditor/reviewer agents + fix-coders per the loop).
Status: Open
Target: v11.0 (launch-gate item — the FINAL one, user 2026-06-04).
Blockers: AFTER BD-185 (user 2026-06-04) — runs only once every other launch-gate item (BD-195, BD-200, BD-203, BD-204, BD-197, BD-185) is Resolved. It is the LAST gate before launch.
Unblocks: v11.0 launch — a verified-ready, correct repo.
Scope: run ALL repo tests (every test suite + validate-pack); a whole-repo v11.0 readiness audit (every launch-gate BD landed correctly; whole-repo correctness; the pack self-migration is sound; no contamination/regressions); the live-GH dog-food (incorporating the prior Batch 23 trio — BD-174 scratch-clone multi-toggle, BD-171, BD-102 dog-food migration) + the prior Batch 22 (BD-100) milestone-audit scope; iterate test → audit → fix until ZERO findings.
Out of scope: net-new features (this is a readiness GATE, not a build phase); any fix it surfaces is applied in-cycle, not deferred.
Acceptance criteria: every repo test green; the readiness audit CLEAN (no outstanding findings after the final pass); the live-GH dog-food passes; no launch blockers remain; the repo is verified v11.0-ready and correct.
Note: this incorporates/supersedes the stale `EXECUTION-PLAN-V11.0.md` Batch 22 (BD-100 final audit) + Batch 23 (live-GH trio) ordering, repositioned AFTER BD-185 as the single final gate. Confirm those BDs' scope is folded in (not duplicated) when BD-205 fires; the live-GH test trio still needs its architect+planner coverage-gap pass before firing (see `project_batch23_test_coverage_gaps`).
References: `project_pack_self_migration_launch_gate`; `project_batch23_test_coverage_gaps` (pack memory); `EXECUTION-PLAN-V11.0.md` Batch 22/23; BD-100, BD-102, BD-174, BD-171.
Resolved: n/a
Position: v11.0 launch gate — the FINAL item; after BD-185; immediately before launch (user 2026-06-04).

---

**BD-206 — Project-side per-entry no-mirror application (apply the corrected standard to client assets)**
Type: feat — STRUCTURAL. Apply the no-monolithic-mirror per-entry STANDARD (the rule corrected in BD-203) to the CLIENT-shipped per-entry feature + its assets, so the shipped product matches its own corrected convention. Project-side product change. Full pipeline.
Status: Open
Target: TBD — likely v11.0 for launch coherence (see Blockers). The user deferred the project-side IMPLEMENTATION here (2026-06-04: "later, whatever's easiest").
Blockers: Follows BD-203 (which corrects the shared standard + converts the pack). LAUNCH-COHERENCE FLAG: BD-203 corrects the shared trinity convention (which SHIPS to clients) to "no monolithic mirror," but the client per-entry tooling still GENERATES mirrors + `supporting-docs/MIGRATION-v10-to-v11.md` still says "monolith becomes a mirror." If v11.0 ships the corrected convention WITHOUT this implementation, it ships an INCOHERENT product (convention says no-mirror; client feature makes mirrors). So BD-206 likely must be v11.0 (before launch) — confirm target + gate membership with user; or BD-203 scopes the convention to mark the client side explicitly pending.
Unblocks: the client per-entry feature matches the corrected standard — client projects' per-entry trees (+ TOC) are the SSOT + readable form; no monolithic client mirror; client conversions preserve every entry (same standard as the pack).
Scope: the client per-entry tooling behavior (stop generating monolithic client mirrors; per-entry + TOC is the readable form); `supporting-docs/MIGRATION-v10-to-v11.md` + any client per-entry doc / `_rules.md` corrected to the no-mirror standard; the client-side validators/checks. Same standard as BD-203, applied to project assets.
Out of scope: the pack-side conversion (BD-203); GH Issues (BD-204).
Acceptance criteria (full correctness audit): the client per-entry feature produces NO monolithic mirror; client docs/rules state the no-mirror standard; a client conversion preserves every entry; NO client doc-vs-implementation gap; validate-pack green.
References: `project_pack_self_migration_launch_gate` (pack memory); BD-203 (corrects the standard + converts the pack); the client per-entry feature (Mode 1/2) + `supporting-docs/MIGRATION-v10-to-v11.md`.
Resolved: n/a
Position: after BD-203; target TBD (v11.0 launch-coherence likely — confirm).

---

**BD-207 — Project-side per-entry ↔ GH-Issues reversible tracker (apply the tracker standard to client assets)**
Type: feat — STRUCTURAL. The PROJECT analog of BD-204: the client-shipped per-entry → GH-Issues (tracker Mode 3) conversion + its REVERSE (Mode 3 → per-entry), made REVERSIBLE/round-trippable + no-mirror + entry-preserving per the corrected standard. Project-side product change. Full pipeline. Designed in/with the BD-203 architect pass (per the architect's together-vs-separate decision); implemented later.
Status: Open
Target: TBD — project-side implementation, later. Launch-coherence flag (like BD-206): the corrected tracker standard ships to clients via the trinity; if v11.0 ships it, the client tracker feature ideally matches before launch — confirm v11.0-vs-later with user (after the architect's design clarifies).
Blockers: Follows BD-206 (project per-entry trees must exist first) + the corrected standard (BD-203). Designed alongside BD-203/BD-206 per the architect's together-vs-separate decision (user 2026-06-04).
Unblocks: client projects convert their per-entry trees ↔ GH Issues REVERSIBLY (lossless round-trip), no monolithic mirror, every entry preserved — the same standard as the pack (BD-204).
REVERSIBILITY (HARD REQUIREMENT, user 2026-06-04): the client per-entry ↔ GH-Issues conversion MUST round-trip LOSSLESSLY (per-entry → GH-Issues → per-entry == original); not a one-way push.
Scope: the client-shipped tracker feature (Mode 2↔3) corrected to no-mirror + REVERSIBLE + entry-preserving; the reverse-migration path; client tracker docs/rules/validators. Same standard as BD-204, applied to project assets.
Out of scope: the pack tracker (BD-204); the project monolith→per-entry conversion (BD-206); the pack conversion (BD-203).
Acceptance criteria (full correctness audit): the client per-entry ↔ GH-Issues round-trips LOSSLESSLY (verified); NO monolithic mirror; every entry preserved; reversibility proven; validate-pack green.
References: `project_pack_self_migration_launch_gate` (pack memory); BD-204 (pack analog); BD-206 (project per-entry prerequisite); BD-203 (corrected standard + design); the tracker Mode 1/2/3 feature (BD-060 TrackerProvider).
Resolved: n/a
Position: project-side tracker; after BD-206; target TBD (confirm with user).

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
Status: Resolved
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
Resolved: 2026-05-12 in commits 50d1a57 (BD-032 audit + rule 21 fixes + boundary prose dedup) — pack-architect audit (NEEDS FIXES verdict) ran desk-audit; 5 fixes applied: F1 metrics/tracing examples, F2 uncertainty triggers (a/b/c), F3 sub-domains (sampling rate / alerting / log retention), F4 named-test ownership rubric (value vs type/call-graph/wiring), F5 boundary prose dedup across 6 agent files (3 auditor-ops trinity + 3 auditor-architecture trinity) replaced with cross-references to canonical rule 21. Cross-cutting concern (deployment-python missing metrics/tracing rules) tracked separately via docs-researcher → architect → planner → coder cycle (see batch follow-up). validate-pack 31/31 PASS.

---

**BD-033 — Validate auditor systemic error handling threshold**
Type: TODO(version)
Status: Resolved
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
Resolved: 2026-05-12 in commit d059d5f (BD-033 audit + rule 16 reformat + auditor-code trinity prose-parity) — pack-architect audit (CLEAN WITH NITS verdict) found original "threshold not quantified" hypothesis factually false against current rule 16 (v11 work already addressed core concern); 4 actionable nits fixed: F1 paragraph-per-dimension (a)–(e) reformat, F2 inline definition of "independent call site", F4 worked examples (Scenarios A/B/C from audit §5), F6 boundary-with-auditor-architecture sub-section. F3 (no-change — error-handling routing tags already correct). F5 trinity prose drift fixed: Claude version selected canonical, Codex .toml + Gemini .md brought to prose-parity. validate-pack 31/31 PASS.

---

**BD-034 — Validate auditor-ui scope breadth after ops split**
Type: TODO(version)
Status: Resolved
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
Resolved: 2026-05-12 in commit e9c44e7 (BD-034 audit + Apple skill additions + phase identifier dedrift) — pack-architect audit (CLEAN WITH NITS verdict) found BD-143 (cross-platform UI checklist) already addressed the original "scope too narrow" concern; 4 NITs fixed in adjacent skills: F2 ios-architecture rule 28 haptic feedback (UIKit feedback generators + SwiftUI .sensoryFeedback + Reduce Motion / Reduce Haptics respect; rules 28-33 renumbered 29-34), F3 apple-architecture-core rules 28-29 animation correctness (state-driven over imperative + explicit/implicit selection + Reduce Motion respect), F4 apple-architecture-core rules 30-31 Liquid Glass (system materials + light/dark + Increase Contrast), F10 phase identifier drift between rule 20 and rule 44 standardized to "deferred to a future version (currently planned post-v11.0)". validate-pack 31/31 PASS.

---

**BD-035 — Validate python-architecture skill loading for non-server Python**
Type: TODO(version)
Status: Resolved
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
Resolved: 2026-05-12 in commit 523be4b (BD-035 audit + python_data_marker stdlib + protobuf-overlap fixes) — pack-architect audit (CLEAN WITH NITS verdict) found post-reframe split (BD-141 + BD-156 cluster) materially closes original gap; 4 fixes applied: F1 extended python_data_marker_detected() with marker (c) for stdlib `import sqlite3` / `import csv` (closes blind-spot for sqlite3 CLIs / csv ETLs), F2 cross-reference between python-best-practices rule 26 and auditor-code performance-anti-pattern scope, F3 attribution corrected in python-server-architecture + python-data-architecture SKILL.md (BD-141 + BD-143, not BD-035), F5 removed protobuf/grpc-tools from python-data-marker package list (now protobuf-marker territory per BD-156). test-detect.sh +14 cases (64 → 78 PASS); validate-pack 31/31 PASS.

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
Status: Resolved
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
Resolved: 2026-05-12 in commit e175b78 (Option A: extended add-capability.sh script-side; Procedure 6 updated). New capability_install_checks() table + probe_tool_present() helper + stage_a7_install_check() stage; existing A7 (prompt emit) renumbered to A8; write_prompt_file() embeds discovery + install-hint blocks via Form R script-side ↔ Form I PM-chat-side per BD-047 kickoff symmetry. Procedure 6 expanded to 7 steps with new G6-install gate + Symmetry with Procedure 7 paragraph + Adding a new capability row guidance. Field-delimiter switched from `|` to `:::` after smoke testing caught install-command leak (regression-guard test included). New scripts/tests/test-add-capability.sh (19/19 PASS). Manual test on test-fixtures/v11-flat-file with --add protocol:grpc confirmed A6 placeholders + A7 probe + A8 prompt with discovery+install commands. validate-pack 31/31 PASS; reviewer APPROVE WITH NITS (NIT N1 line 1194 A7→A8 fixed in same commit).

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

---

**BD-201 — Antigravity (Gemini CLI successor) MCP config relocation: settings.json → mcp_config.json**
Type: TODO(version) — client config currency; deferred to a later v11.x minor. To be grouped with the larger Gemini → Antigravity support transition (a v11 minor-version upgrade), NOT implemented in v11.0.
Status: Deferred
Blockers: EXTERNAL — Antigravity GA + published migration docs (~2026-06-18); AND a product decision to undertake the full Gemini → Antigravity support transition as a v11.x minor. Cannot be worked until the exact `mcp_config.json` path/mechanics are documented by Google.
Unblocks: Antigravity-native MCP config for client projects (the `mcpServers` block relocated to `mcp_config.json`).
File/Symbol: `project-template/.gemini/settings.json` (`_tools` forward-looking note); `project-template/.mcp.json.example` (`_tools` forward-looking note); `project-template/GEMINI.md` if it references the `mcpServers` location — replace the "exact path per Antigravity migration docs" placeholders with the real `mcp_config.json` path; add the `settings.json` → `mcp_config.json` migration step to the Gemini setup docs.
Description: The v11.0 completeness re-audit (BD-195, 2026-06-03) shipped forward-looking notes in the two Gemini/MCP config files stating that Gemini's successor Antigravity preserves MCP but relocates the `mcpServers` block from `settings.json` to a dedicated `mcp_config.json` (exact path per Antigravity migration docs; stdio command/args/env shape unchanged). Those notes are correct as-is for v11.0. This BD captures the concrete relocation work — substitute the real `mcp_config.json` path, document the migration step, verify the stdio shape is unchanged — to be done as part of the larger Gemini → Antigravity support transition, scheduled as a v11.x minor-version upgrade after Antigravity GA.
Context: Surfaced 2026-06-03 during BD-195 completeness re-audit (RAG/cross-CLI fix, commit `cad79f7`). User direction 2026-06-03: do NOT implement in v11.0; group with the broader Gemini → Antigravity transition and schedule as a later v11 minor.
Resolved: n/a

*(Items move here when pushed to a future version beyond v9, with the target version noted)*
