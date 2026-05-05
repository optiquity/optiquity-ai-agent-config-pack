# IMPLEMENTATION-PLAN — v11.0

## §0. Status and conventions

- Date: 2026-05-04
- Inputs: V1 (`maintenance-docs/v11-research/ARCHITECTURE.md`) + V2 (`ARCHITECTURE-V2.md`) + V3 (`ARCHITECTURE-V3.md`) + V3.1-DELTA (`ARCHITECTURE-V3.1-DELTA.md`) + REVIEW + REVIEW-PASS2; `DESIGN-BRIEF.md`; `INTERNAL-INVENTORY.md`; pack-state files (`BACKLOG.md`, `CHANGELOG.md`, `README.md`, `QUICKSTART.md`, `PACK-CHAT.md`, `PACK-AGENTS.md`, `OPTIONAL-FEATURES.md`, root + project-template trinity, `supporting-docs/MIGRATION-v9-to-v10.md`, `supporting-docs/INSTALL-PROCEDURES.md`).
- Highest existing BD: **BD-059** (verified by enumerating `BD-NNN` literals in `BACKLOG.md`).
- v11 BDs continue from **BD-060** monotonically. This plan defines **BD-060 through BD-093** (34 BDs).
- Existing-BD reuse: BD-042 (pack reference doc relocation) and BD-059 (v10 migration customization preservation) are open and in scope. They are **not** renumbered; the plan splits each into work-item BDs that name BD-042 / BD-059 as their parent and resolve the parents on completion.
- BD entry format used in this plan: every BD has Title, Type, Scope (A or B), Files, Description, Blockers, Verification, Definition-of-Done. The BD entries below are planning records, not BACKLOG.md text — Pack Chat writes the BACKLOG entries at approval time.
- Trinity-replication convention: every BD that touches a trinity-bound file lists "Trinity-replicated. Files: …" naming all 3 (or all 6 across pack-root + project-template) files. CI Check 18 (`check_trinity_h2_parity`) gates lockstep.
- Per-CLI symmetry convention: every BD touching a per-CLI command/skill enumerates Claude (`.claude/skills/<name>/SKILL.md`), Codex (`.codex/skills/<name>/SKILL.md` per V3 §7.1.1 corrected format), Gemini (`.gemini/commands/<name>.toml`).
- "CI green at every boundary" rule: every BD's Definition-of-Done includes "validate-pack.py exits 0 against the working tree at this BD's HEAD." BDs that introduce a new Check in `validate-pack.py` necessarily land the check together with the artifact it validates (no temporary CI exemptions are required by this plan; if one becomes necessary during implementation, the planner adds a follow-up "remove-exemption" BD before v11.0 cut).
- Surface labels used in Files lists:
  - **PACK-ROOT** = pack repo working tree top (e.g., `/CLAUDE.md`, `/scripts/...`).
  - **CLIENT** = pack-product files in `project-template/...` that ship into client repos.
- Reading shorthand: **D-N** = decision N from V3 §16; **§N.M** = section in the named architecture doc; **R-N** = risk from V3 §17.
- The plan is **acyclic**: every `Blockers:` line names a BD that appears earlier in the plan or is closed/None. §3 contains the dependency graph and the critical path.

---

## §1. Scope A — Issue-tracker integration BDs

### §1.1 Provider abstraction + config (D-1, D-2, D-5)

**BD-060 — TrackerProvider abstraction skeleton + GH backend implementation**
Type: TODO(version)
Scope: A
Files:
- `scripts/lib/tracker-provider.sh` (new) — operation set per V1 §2.1 (18 ops + `raw`); shells out via `gh` per V1 §2.7.1 mapping; implements the canonical `Issue` shape from V1 §2.2; capability flags per V1 §2.3 + GH hard-coded values from V1 §2.7.2; error model per V1 §2.5; pagination per V1 §2.6.
- `scripts/lib/tracker-provider-gh.sh` (new) — GH-specific implementation invoked by `tracker-provider.sh` when `backend.name = "github"`.
- `scripts/tests/tracker-provider-test.sh` (new) — unit tests against a recorded-fixture mode (no live network in CI by default).

Description: Implements the OQ-1 surface. The library is the read/write surface every other tracker BD calls. Includes the `gh` extension policy (V1 §2.7.3 — optional `gh-sub-issue`) and the GraphQL preview-header policy (V1 §2.7.4). The `raw(...)` escape hatch (V1 §2.1) is required.

Blockers: None

Verification:
- `scripts/tests/tracker-provider-test.sh` runs offline against fixtures and passes.
- Manual integration test (developer machine, opt-in): hit a sandbox GH repo with each operation; record fixtures.
- Capability output matches V1 §2.7.2 byte-for-byte for the GH backend.

Definition-of-Done: All 18 operations callable; `capabilities()` returns the V1 §2.7.2 schema; error codes are emitted per V1 §2.5; validate-pack.py passes.

---

**BD-061 — `tracker.toml` schema + detection helper + gitignore entry**
Type: TODO(version)
Scope: A
Files:
- `scripts/lib/tracker-config.sh` (new) — `read_tracker_toml()`, `tracker_mode()` (returns `tracker` | `flat-file`), `tracker_repo_slug()`, schema-version compatibility check.
- `tracker.toml.example` (PACK-ROOT, new) — V1 §3.1 schema with comments.
- `project-template/tracker.toml.example` (CLIENT, new) — same schema, client-side default `id_namespace.prefix = "TD"`.
- `.gitignore` (PACK-ROOT, modified) — add `.pack-tracker/` per V1 §3.4.
- `project-template/.gitignore` (CLIENT, modified) — add `.pack-tracker/`.

Description: Resolves D-2 + D-5 + R16 (state-file gitignore preservation). Detection is "presence + content of `tracker.toml`": no file = flat-file; `mode.state = "flat-file"` = flat-file; `mode.state = "tracker"` = tracker.

Blockers: BD-060 (the config helper imports the provider library for capability cache invalidation on schema change).

Verification: `validate-pack.py` Check (existing trinity / file-presence) passes. New unit fixture: provide a synthetic `tracker.toml`, assert `tracker_mode()` returns the expected value across the 3 input cases.

Definition-of-Done: `tracker.toml.example` documents every key from V1 §3.1; `.gitignore` includes `.pack-tracker/`; `tracker_mode()` correct for all three input cases.

---

**BD-062 — Trinity `## Document locations` Source column extension (D-6)**
Type: TODO(version)
Scope: A
Files (Trinity-replicated. Files: `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` — client-tree only per V3 D-6 footnote ["Source column applies to project-template trinity only; pack-repo trinity has no `## Document locations` section"]):
- `project-template/CLAUDE.md` — extend the `## Document locations` table per V1 §3.3 with a Source column ("flat" | "tracker" | "mixed").
- `project-template/AGENTS.md` — same.
- `project-template/GEMINI.md` — same.

Description: The runtime path-resolver gains a Source column so `pm-startup` Step 2 can branch by source per V1 §3.3. Pack-repo trinity is exempted by D-6 (no `## Document locations` section there).

Blockers: BD-061 (tracker mode detection must exist before the Source column has meaning).

Verification: validate-pack.py Check 18 (`check_trinity_h2_parity`) still passes; new Check (added in BD-082) verifies the Source column exists and is well-formed when present.

Definition-of-Done: All three project-template trinity files have the new column with identical headers and rows; `pm-startup` skill can read the column without errors (verified in BD-068).

---

### §1.2 Form family + intake (D-4-V2, D-16, D-17, D-18)

**BD-063 — Issue forms `work-item.yml` and `inbound.yml` (D-4-V2)**
Type: TODO(version)
Scope: A
Files:
- `.github/ISSUE_TEMPLATE/work-item.yml` (PACK-ROOT, new) — fields per V2 §4.2 (Type/Category dropdown driving labels; structured fields per V2 §4.2; free-text per OQ-17 / D-17 split; HTML-comment `template_version` marker per V2 §6.2 + D-18).
- `.github/ISSUE_TEMPLATE/inbound.yml` (PACK-ROOT, new) — fields per V2 §4.3.
- `.github/ISSUE_TEMPLATE/config.yml` (PACK-ROOT, new) — disable blank issues; per V2 §4.1 form family.
- `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (CLIENT, new) — same form, TD-NNN namespace, Pack feedback category included.
- `project-template/.github/ISSUE_TEMPLATE/inbound.yml` (CLIENT, new).
- `project-template/.github/ISSUE_TEMPLATE/config.yml` (CLIENT, new).

Description: Implements D-4-V2 + D-16 + D-17 + D-18. The form family routes by Type dropdown. Both copies are byte-identical except for namespace examples and Pack-feedback category presence.

Blockers: BD-061 (uses `id_namespace.prefix` from `tracker.toml`).

Verification: GitHub validates the YAML at PR (Forms validation runs server-side at upload). `validate-pack.py` adds a YAML well-formedness check on issue templates (extends an existing check; not a new numbered Check).

Definition-of-Done: Both forms have all required fields per V2 §4.2 / §4.3; `template_version` HTML-comment + label dual carrier per D-18; structure-vs-free-text split per D-17.

---

**BD-064 — Template-archive directory bootstrap + bd-v11.0 schemas**
Type: TODO(version)
Scope: A
Files:
- `maintenance-docs/v11-research/templates-archive/bd-v11.0/SCHEMA.md` (new) — JSON-schema-style description of `work-item.yml` fields at template version `bd-v11.0` per V2 §19.4 + V1 §6.6.1.
- `maintenance-docs/v11-research/templates-archive/bd-v11.0/work-item.yml` (new) — frozen copy of the v11.0 form for reference.
- `maintenance-docs/v11-research/templates-archive/bd-v11.0/inbound.yml` (new) — frozen copy.
- `maintenance-docs/v11-research/templates-archive/bd-v11.0/README.md` (new) — explains the archive contract per V2 §19.4.

Description: Implements the P2 maintenance-ergonomics floor: template versions are archived at every minor cut so `pack tracker update-templates` (V2 §19.2) and reverse-migration sidecar (V1 §6.6.1 / DELTA §3) can deterministically translate.

Blockers: BD-063 (the forms must exist before being archived).

Verification: validate-pack.py adds a soft check (warning, not error) that `templates-archive/<latest>/SCHEMA.md` exists and matches the live `.github/ISSUE_TEMPLATE/*.yml` field list. (Not numbered as a Check; logged in pack-internal CI for human review.)

Definition-of-Done: archive directory exists; SCHEMA.md fully describes every field; both surfaces' forms match their archived snapshot.

---

### §1.3 Migration: forward (D-3, D-8)

**BD-065 — `tracker-migrate.sh forward` + idempotency markers + checkpoint**
Type: TODO(version)
Scope: A
Files:
- `scripts/tracker-migrate.sh` (new) — V1 §6.1 surface (`forward / reverse / status / doctor`); this BD lands `forward` and `status` only.
- `scripts/lib/tracker-migrate-forward.sh` (new) — algorithm per V1 §6.2 (steps 1–11), idempotency marker logic per V1 §6.2 ("title marker + body footer marker + mapping file"), checkpoint per V1 §6.4.
- `.pack-tracker/id-map.json` (new file shape; written by the script; gitignored via BD-061).
- `.pack-tracker/forward.checkpoint.json` (script-managed; gitignored).
- `scripts/tests/tracker-migrate-forward-test.sh` (new) — fixture-driven unit tests for the parser and ID-mapping logic; integration test stub (offline / fixture).

Description: Forward migration. Implements the body-footer marker (`<!-- pack-id: TD-NNN -->`); reads BACKLOG / IMPLEMENTATION_PLAN; creates issues; resolves blockers / sub-issues; writes mapping file; regenerates mirror files. Reads from BD-060 provider lib; reads config via BD-061.

Blockers: BD-060, BD-061, BD-063.

Verification: Forward against a fixture v10-shape BACKLOG → recorded GH-mock → mapping file populated; re-running yields no new creations (idempotency proof). `tracker-migrate.sh status` reports correct freshness.

Definition-of-Done: Forward is idempotent across re-runs; checkpoint resumes a partial run exactly where it left off (V1 §6.4); status subcommand reports per V2 verb table for `pack tracker status`.

---

**BD-066 — `pack tracker init` wrapper + label / template ensure step**
Type: TODO(version)
Scope: A
Files:
- `scripts/pack-tracker.sh` (new) — verb dispatcher per V2 §22.1 (`init`, `disable`, `doctor`, `status`, `update-templates`, `mirror-rebuild`, `enable-recommendations`).
- `scripts/lib/tracker-labels.sh` (new) — ensures the label set per V1 §6.1 step 3 (`bd-entry`, `td-entry`, `status:open`, `status:unblocked`, `status:in-review`, `status:resolved`, `scope:phase-N`, etc.).
- `scripts/lib/tracker-init.sh` (new) — orchestrates the V1 §6.1 wrapper steps 1–4: dialogue → write `tracker.toml` → validate auth → ensure templates+labels → forward.

Description: Lands `pack tracker init` as the one-command opt-in path. Includes auth validation per V1 §7.3 + D-10 (`gh auth status`).

Blockers: BD-065.

Verification: From a clean `pack-repo` clone, run `scripts/pack-tracker.sh init` → answer prompts → verify `tracker.toml` written, labels created (mock), forward run completed, `pack tracker status` shows tracker mode.

Definition-of-Done: `pack tracker init`, `pack tracker status` work end-to-end; auth-missing surfaces actionable error per V1 §9.3.

---

### §1.4 Migration: reverse (D-3, D-8) — mandatory

**BD-067 — `tracker-migrate.sh reverse` + sidecar (V1 §6.6 + §6.6.1, A2)**
Type: TODO(version)
Scope: A
Files:
- `scripts/lib/tracker-migrate-reverse.sh` (new) — algorithm per V1 §6.5 steps 1–9.
- `scripts/lib/tracker-sidecar.sh` (new) — emits `.pack-tracker/reverse.sidecar.YYYY-MM-DD.md` per V1 §6.6 + §6.6.1 (DELTA A2): per-entry `template_version`, `extra_fields`, `template_archive_path`, plus reactions / comments / attachments / audit-log per V1 §6.6.
- `scripts/lib/tracker-mirror.sh` (new) — strips mirror header on reverse (V1 §6.5 step 8); writes mirror header on forward (V1 §6.3).
- `scripts/tracker-migrate.sh` (modified) — adds `reverse` and `doctor` subcommands.
- `scripts/pack-tracker.sh` (modified) — adds `disable`, `doctor`, `update-templates`, `mirror-rebuild`.

Description: Reverse migration is mandatory per `DESIGN-BRIEF.md` §3.1. Sidecar coverage extended per DELTA A2 to include template-version drift fields. The `--include-comments` flag per V1 §6.7 controls comment-thread footer behavior.

Blockers: BD-064 (templates-archive directory required for sidecar `template_archive_path`); BD-065 (shared forward-side helpers).

Verification:
- Reverse a forward-migrated fixture; resulting BACKLOG / STATUS / IMPLEMENTATION_PLAN match the original input within whitespace tolerance per V1 §6.7.
- Sidecar contains every tracker-only field for at least one fixture entry.

Definition-of-Done: Reverse is idempotent; sidecar present and well-formed; `pack tracker disable` runs reverse + flips `tracker.toml mode.state` to `flat-file`; `pack tracker doctor` reports mapping integrity per V2 §22.1.

---

**BD-068 — Round-trip test fixture + multi-template-version coverage**
Type: TODO(version)
Scope: A
Files:
- `scripts/tests/tracker-migrate-roundtrip-test.sh` (new; from V3 §I.1) — forward → reverse → forward fixture per V1 §6.7 + DELTA A2 / V1 §6.6.1.
- `scripts/tests/fixtures/roundtrip/bd-v11.0/` (new) — v11.0-template entry fixture.
- `scripts/tests/fixtures/roundtrip/bd-v11.1/` (new) — placeholder for next-minor.
- `scripts/tests/fixtures/roundtrip/bd-v11.2/` (new) — placeholder for v11.2; per V1 §6.6.1 multi-version test fixture; v11.0 ships with stub directories that are exercised when later minors add real entries. `MAINTAINER CHECK NEEDED` (item §6.A).

Description: Implements the V1 §6.7 + V3 §I.1 explicit round-trip test. v11.0 only has bd-v11.0 entries; the multi-version part is structural readiness so v11.1 can drop in fixtures without re-architecting.

Blockers: BD-067.

Verification: CI runs the roundtrip test; diff = 0 (whitespace-tolerant) on a v10-shape BACKLOG input.

Definition-of-Done: Test runs in CI; fails closed (any diff > whitespace fails); test logs document which fields round-trip and which are sidecar-only.

---

### §1.5 Sidecar + template-version drift (V1 §6.6.1, A2)

**BD-069 — `template_version` HTML-comment + label dual carrier (D-18)**
Type: TODO(version)
Scope: A
Files:
- `scripts/lib/template-version.sh` (new) — read/write the `<!-- template_version: bd-v11.0 -->` HTML comment in issue body and the parallel `template:bd-v11.0` label per D-18 / V2 §26.
- `scripts/lib/tracker-migrate-forward.sh` (modified, from BD-065) — write both carriers at create time.
- `scripts/lib/tracker-migrate-reverse.sh` (modified, from BD-067) — read both carriers; reconcile to one canonical value.
- `scripts/pack-tracker.sh` (modified) — `update-templates` subcommand reads stale carriers, applies V2 §19.3 patch semantics + §19.4 translation rules.

Description: Implements D-18 dual carrier. `update-templates` (V2 §19.2) is the user-facing verb; the dual carrier is the on-tracker representation.

Blockers: BD-064, BD-065, BD-067.

Verification: Create an issue at `bd-v11.0`; archive a synthetic `bd-v11.1` SCHEMA; run `pack tracker update-templates --dry-run`; verify the diff names the right fields.

Definition-of-Done: Both carriers are written on create; reverse reconciles; `update-templates` produces a correct patch plan for at least one synthetic version delta.

---

### §1.6 Mirror file behavior (D-7) and trinity Source column (D-6)

(Note: D-6 trinity Source column already addressed in BD-062; D-7 failure UX in §1.7. The mirror-file behavior itself ships across BD-065 forward and BD-067 reverse. No new BD here; cross-reference BD-062 and BD-065.)

---

### §1.7 Failure UX, error model, agent reads (D-7, D-9, D-10, D-11)

**BD-070 — Typed error surfacing + diagnostic helper**
Type: TODO(version)
Scope: A
Files:
- `scripts/lib/tracker-errors.sh` (new) — central error formatter; maps the 9 typed codes from V1 §2.5 to user-facing messages + next-step verb (per V3 §27.1 Layer 2).
- All BD-060/-065/-067 scripts use `tracker-errors.sh` for surface output.

Description: Implements D-7. No silent retry; every failure surfaces typed code + diagnostic + next-step verb. Every error message ends with "→ Run: pack X" per V3 §27.1.

Blockers: BD-060.

Verification: For each of the 9 error codes, simulate the failure (mock or fault injection) and assert the formatter prints the documented shape per V1 §9.

Definition-of-Done: All call sites in tracker scripts use the helper; documented failure-mode test in `scripts/tests/tracker-errors-test.sh`.

---

**BD-071 — Agent read-pattern adaptation (D-9, V1 §8 + V1 §13)**
Type: TODO(version)
Scope: A
Files (Trinity-replicated where applicable; per-CLI prompts):
- `project-template/docs/pack/prompts/architect.md` (modified, per V1 §13 / §8.4) — replace "Read BACKLOG.md" with "Read BACKLOG entries (resolve via trinity Document locations)".
- `project-template/docs/pack/prompts/auditor.md` (modified) — same.
- `project-template/docs/pack/prompts/coder.md` (modified) — same.
- `project-template/docs/pack/prompts/docs-researcher.md` (modified) — same.
- `project-template/docs/pack/prompts/grpc-schema.md` (modified) — same.
- `project-template/docs/pack/prompts/planner.md` (modified) — same.
- `project-template/docs/pack/prompts/pm-chat.md` (modified) — same.
- `project-template/docs/pack/prompts/repo-ops.md` (modified) — same.
- `project-template/docs/pack/prompts/reviewer.md` (modified) — same.
- `project-template/docs/pack/prompts/tester.md` (modified) — same.
- `scripts/lib/tracker-agent-read.sh` (new) — LCD `gh issue view --json …` shell-out path agents use when tracker mode is on per V1 §8.1.

Description: Implements D-9 LCD agent reads + V1 §8.4 prompt-language change across all 10 per-agent prompt files.

Blockers: BD-062 (Source column on trinity), BD-070 (errors).

Verification: Search every prompt file for "Read BACKLOG.md" and verify it's been replaced with the new language. validate-pack Check 22 (added BD-082) catches drift.

Definition-of-Done: All 10 prompt files updated; LCD read path verified by an integration test that runs the agents against a tracker fixture.

---

### §1.8 Inflection-point recommendation system (D-19, OQ-19)

**BD-072 — `scripts/lib/recommendation.sh` + state-file schema (D-19)**
Type: TODO(version)
Scope: A
Files:
- `scripts/lib/recommendation.sh` (new) — signal computation per V3 §28.1.1 (3 signals pack-side; 7 client-side); state I/O for `.pack-tracker/recommendation-state.json` per V3 §28.1.4 schema; `should_recommend()` test per V3 §28.1.5; prompt rendering per V3 §28.1.7.
- `scripts/tests/recommendation-test.sh` (new; per V3 §I.1) — 7 integration tests per V3 §28.1.10.

Description: Lands the OQ-19 mechanism. State file is JSON v1 schema per V3 §28.1.4; lazy-created with default values; failure-mode UX per V3 §28.1.4 last bullet (parse fail → log warning + write fresh state + defer recommendation to next session).

Blockers: BD-061 (state file lives next to `tracker.toml` semantically, gitignored via `.pack-tracker/`).

Verification: All 7 V3 §28.1.10 tests pass:
1. Threshold-cross fires once per material change.
2. "Not now" silences for the session.
3. "Don't ask again" persists across sessions.
4. `pack tracker enable-recommendations` clears.
5. Tracker mode disables recommendations entirely.
6. Corrupted state file recovers.
7. Cross-machine refusal does not survive (R16 documented behavior).

Definition-of-Done: All 7 tests pass; state file schema matches V3 §28.1.4 byte-for-byte; `should_recommend` matches the V3 §28.1.5 pseudocode including the 25%-growth Guard 4.

---

**BD-073 — `pack tracker enable-recommendations` subcommand**
Type: TODO(version)
Scope: A
Files:
- `scripts/pack-tracker.sh` (modified) — adds `enable-recommendations` subcommand per V3 §28.1.9 + D-19 verb table.

Description: Lands the re-enable path. Sets `persistent_refusal = false`; increments `user_re_enable_count`.

Blockers: BD-072.

Verification: From a `persistent_refusal = true` state, run the verb, assert state-file flag flipped, assert `user_re_enable_count` incremented.

Definition-of-Done: Verb works; colloquial "remind me about the tracker again" routes through it (BD-079 closes the routing).

---

**BD-074 — `pack-startup` Step 8 + `pm-startup` Step 8 (D-19 integration)**

Trinity-replicated per-CLI. Files (per V3 §I.2):
- `.claude/skills/pack-startup/SKILL.md` (PACK-ROOT, modified) — append Step 8 per V3 §28.1.9 + Appendix A.2.
- `.codex/skills/pack-startup/SKILL.md` (PACK-ROOT, modified) — parallel.
- `.gemini/commands/pack-startup.toml` (PACK-ROOT, modified) — parallel.
- `project-template/skills/pm-startup/SKILL.md` (CLIENT, modified) — append Step 8.
- `.claude/skills/pm-startup/SKILL.md` (CLIENT distributed copy, modified) — parallel.
- `.codex/skills/pm-startup/SKILL.md` (CLIENT distributed copy, modified) — parallel.
- `.gemini/commands/pm-startup.toml` (CLIENT distributed copy, modified) — parallel.

Type: TODO(version)
Scope: A
Description: Step 8 runs after V1's Step 7 triage queue: source `recommendation.sh`; compute signals; check state; call `should_recommend`; if true, render the V3 §28.1.7 prompt. The body content is byte-identical across the three CLIs in each surface; framing (TOML vs Markdown) differs as the per-CLI format mandates.

Blockers: BD-072 (the helper this Step 8 sources), BD-073 (verbs the Step 8 references).

Verification: Run pack-startup against a fixture project at threshold-crossing — recommendation prompt fires once. Run again — does not fire. Run pm-startup against the OT-fixture (V3 §D.2 worked example) — prompt fires; "not now" silences; state persists per the worked example.

Definition-of-Done: Both surfaces' Step 8 added; per-CLI parity verified by validate-pack Check 21 (BD-082); fixture replays match V3 worked examples §D.1–§D.4.

---

### §1.9 Help-verb system pack help / /pack-help (D-20, OQ-20, M2)

**BD-075 — `scripts/pack-help.sh` LCD shell verb + surface detection**
Type: TODO(version)
Scope: A
Files:
- `scripts/pack-help.sh` (new — V3 §I.3 says preserved-from-V2; V2 named, but no file in current `scripts/` per `ls` — therefore creating new in v11; if V2 had only specified the file in design without committing it, this BD ships it for the first time. `MAINTAINER CHECK NEEDED` §6.B).
- `scripts/lib/detect-surface.sh` (modified or extended from existing `scripts/lib/`) — adds `pack` vs `client` surface detection per V3 §28.2.3 last paragraph (presence of `BACKLOG.md` with `^\*\*BD-` → pack; `docs/project/BACKLOG.md` with `^\*\*TD-` → client).

Description: Implements the LCD floor for D-20 / OQ-20 (M2 path). Reads the appropriate `HELP-FRAGMENT-*.md` and prints to stdout. Inlines the shared `HELP-FRAGMENT-TRACKER.md` per V3 §28.2.4 + DELTA L1 (sibling-file include via text-include resolver in the same tree).

Blockers: BD-076 (the help fragments must exist for the script to read).

Verification: Run `pack help` in pack repo → outputs HELP-FRAGMENT-PACK.md content + tracker section. Run in client fixture → outputs HELP-FRAGMENT.md (client) + tracker section. Output token cost ~400 tokens per V3 §28.2.3.

Definition-of-Done: Surface detection works correctly for pack-repo, client-repo, and ambiguous (both printed) per V3 §28.2.3.

---

**BD-076 — HELP-FRAGMENT files (canonical + per-surface; L1 layout)**
Type: TODO(version)
Scope: A
Files (per V3 §I.1 + DELTA L1 — pack-root canonical, client-tree mirror):
- `HELP-FRAGMENT-PACK.md` (PACK-ROOT, new) — pack-repo verb manifest per V3 §28.2.1 + V3 §28.2.7 shape.
- `HELP-FRAGMENT-TRACKER.md` (PACK-ROOT, new — canonical) — shared tracker verb subsection.
- `project-template/docs/pack/HELP-FRAGMENT.md` (CLIENT, new) — client-repo verb manifest per V3 §28.2.1.
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (CLIENT, new — byte-identical mirror of pack-root canonical, installed by `init-project.sh` per DELTA L1).

Description: Implements D-20 + DELTA L1. Pack-root canonical is the single source of truth for the shared tracker section; client mirror is overwritten by `init-project.sh` per BD-080. The two top-level fragments diverge in the non-tracker sections per V3 §28.2.4.

Blockers: BD-066 (verbs must exist; the manifest references them), BD-073 (`enable-recommendations` listed).

Verification: validate-pack Check 24 (BD-082) verifies pack-root and client-mirror byte-identity. Check 23 verifies fragment completeness (every `scripts/` top-level executable appears unless marked `# pack-internal: true`). Check 22 verifies fragment freshness against external doc verb references.

Definition-of-Done: All four files exist; pack-root canonical and client mirror byte-identical at land-time; structure matches V3 §28.2.7 shape.

---

**BD-077 — Per-CLI `pack-help` command/skill (Trinity-replicated × 2 surfaces)**
Type: TODO(version)
Scope: A

Trinity-replicated × 2 surfaces. Files (per V3 §I.1 + V3 §28.2.3):

PACK-ROOT (pack-repo surface):
- `.claude/skills/pack-help/SKILL.md` (new) — Markdown skill body per V3 §D.6 example; invokes `bash scripts/pack-help.sh`.
- `.codex/skills/pack-help/SKILL.md` (new — V3 §7.1.1 corrected format) — Codex skill in Markdown form per V3 §28.2.3 (NOT TOML; the §7.1.1 textual fix corrects V2's earlier TOML reference).
- `.gemini/commands/pack-help.toml` (new) — TOML custom command per V3 §D.7 example.

CLIENT (project-template surface; installed by `init-project.sh`):
- `project-template/.claude/skills/pack-help/SKILL.md` (new).
- `project-template/.codex/skills/pack-help/SKILL.md` (new).
- `project-template/.gemini/commands/pack-help.toml` (new).

Description: Implements the per-CLI namespaced `/pack-help` per D-20. All six files invoke the same `scripts/pack-help.sh` via shell injection per V3 §28.2.3 / §D.6 / §D.7. Trinity rule applies — all three per surface in lockstep.

Blockers: BD-075 (the script the skills invoke).

Verification: validate-pack Check 21 (BD-082) verifies all three exist per surface (pack-side and client-side independently); each invokes the same target.

Definition-of-Done: All 6 files land in one commit; Check 21 passes; manual smoke: `/pack-help` in each CLI prints the expected fragment.

---

### §1.10 HELP-FRAGMENT canonical/mirror (L1)

(Covered by BD-076 + BD-080 install-time copy + validate-pack Check 24 from BD-082. No separate BD.)

---

### §1.11 Validate-pack Checks 21–24

**BD-078 — validate-pack.py Check 19 (`check_tracker_config`) (V1 §A.2)**
Type: TODO(version)
Scope: A
Files:
- `scripts/validate-pack.py` (modified) — adds Check 19: validates `tracker.toml` schema if present; warns if mode tracker but mirror files have stale `Last regenerated` timestamps relative to `tracker.toml.migration.last_forward_run` (per V1 §A.2).

Description: First of the v11 validate-pack additions. Numbered 19 to continue v10's check sequence (current top is Check 10 per README; v11 adds 19–24 contiguously — `MAINTAINER CHECK NEEDED` §6.C: confirm the next free check number).

Blockers: BD-061.

Verification: Add a fixture with valid `tracker.toml` → check passes. Add a fixture with malformed `tracker.toml` → check fails with line-numbered error.

Definition-of-Done: Check 19 lands; CI passes.

---

**BD-079 — validate-pack.py Check 20 (recommendation-state schema)**
Type: TODO(version)
Scope: A
Files:
- `scripts/validate-pack.py` (modified) — adds Check 20: if `.pack-tracker/recommendation-state.json` exists, validate against the V3 §28.1.4 v1 schema. Soft-fail if missing (lazy-create is by design).

Description: Catches state-file corruption before it causes runtime defaults. Pairs with BD-072's recovery path.

Blockers: BD-072.

Verification: Corrupt fixture file → Check 20 fails. Default-shape file → Check 20 passes. Missing file → Check 20 reports "not present (default state); continue."

Definition-of-Done: Check 20 lands; CI passes; handles all three input cases (valid / corrupt / missing).

---

**BD-080 — `init-project.sh` extensions for v11 artifacts**
Type: TODO(version)
Scope: A
Files:
- `scripts/init-project.sh` (modified, per V3 §A.2) — install per-CLI `pack-help/` skills and `pack-help.toml`; install `HELP-FRAGMENT.md` and `HELP-FRAGMENT-TRACKER.md` (the latter copied from pack-root canonical per DELTA L1); install `tracker.toml.example`; install issue forms (`work-item.yml`, `inbound.yml`, `config.yml`).
- `scripts/lib/init-helpers.sh` (modified, if used; or inline) — file-copy helpers for the new artifacts.

Description: Single-source for client-side artifact installation. The `--update` flag (existing) refreshes from pack-root canonical so version drift is contained.

Blockers: BD-076, BD-077, BD-063.

Verification: From a fresh client-repo fixture, run `init-project.sh` — verify all v11 client-side artifacts exist; run `init-project.sh --update` from a stale state — verify only v11 artifacts get refreshed (no destructive overwrites of customization; cross-references BD-088 / BD-059 fix).

Definition-of-Done: New install creates the full v11 client surface; `--update` is non-destructive of project customization (BD-088 contract).

---

**BD-081 — Trinity addenda: per-CLI command files at pack-root + client (P-help reference)**

Trinity-replicated × 2 surfaces. Files (per V3 §A.2 trinity addendum + V3 §28.2.5):

PACK-ROOT (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`):
- `CLAUDE.md` (modified) — add a one-line "Pack commands" reference: "Run `pack help` for the full verb list, or `/pack-help` in your CLI." Add a one-line "Recommended first action: run `pack-startup`."
- `AGENTS.md` (modified) — same.
- `GEMINI.md` (modified) — same.

CLIENT (`project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`):
- `project-template/CLAUDE.md` (modified) — add "Pack commands" line; add "Recommended first action: run `pm-startup`" line.
- `project-template/AGENTS.md` (modified) — same.
- `project-template/GEMINI.md` (modified) — same.

Type: TODO(version)
Scope: A (and B — this is one of the Scope-B trinity addenda; it appears here because the routing is part of D-20)
Description: Implements V3 §A.2 trinity addendum. Six files, two trinities, lockstep. Per the trinity rule, all three per surface get byte-identical lines (only the verb name differs by surface: `pack-startup` for pack-root, `pm-startup` for client).

Blockers: BD-077.

Verification: validate-pack Check 18 (`check_trinity_h2_parity`) still passes; new Check 21 (BD-082) confirms the per-CLI `pack-help` files are referenced correctly in the trinity body.

Definition-of-Done: All 6 files updated in one commit; trinity parity checks pass; the lines are present and identical across each trinity.

---

**BD-082 — validate-pack.py Checks 21, 22, 23, 24**
Type: TODO(version)
Scope: A
Files:
- `scripts/validate-pack.py` (modified) — adds:
  - **Check 21** (V3 §28.2.5) — Trinity per-CLI help-surface parity: verify `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`, `.gemini/commands/pack-help.toml` all exist (or all absent), per surface (pack-root + project-template). All invoke the same target (`scripts/pack-help.sh`).
  - **Check 22** (V3 §27.4.3 + §28.2.5) — Help-fragment freshness: every verb named in `PACK-CHAT.md`, `project-template/docs/pack/PM-CHAT.md`, `QUICKSTART.md`, `OPTIONAL-FEATURES.md`, `supporting-docs/INSTALL-PROCEDURES.md` appears in the corresponding `HELP-FRAGMENT*.md`.
  - **Check 23** (V3 §27.4.3 + §28.2.5) — Help-fragment completeness: every top-level executable in `scripts/` appears in `HELP-FRAGMENT*.md` unless marked with `# pack-internal: true`.
  - **Check 24** (DELTA L1 + V3 §28.2.5) — Shared-fragment byte-identity: pack-root `HELP-FRAGMENT-TRACKER.md` is byte-identical to `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`.

Description: Lands the four CI gates that prevent help-surface drift. All four are required by V3 §28.2.5 + DELTA L1.

Blockers: BD-076, BD-077, BD-080, BD-081.

Verification: For each Check, craft a failing fixture and confirm the Check fails; revert and confirm pass.

Definition-of-Done: Checks 21–24 land in `validate-pack.py`; CI passes against working tree; failing fixtures fail closed.

---

### §1.12 Per-CLI shipping (Claude / Codex / Gemini)

(All per-CLI artifacts are introduced inside the BDs above. Trinity propagation matrix per V3 §I.4 is the consolidated reference. The per-CLI surfaces touched in v11.0 are:

- `pack-help` skills/commands — BD-077 (6 files: 3 pack-root + 3 client).
- `pack-startup` skills/commands — BD-074 (3 pack-root files; pack-only).
- `pm-startup` skills/commands — BD-074 (4 client files: canonical `project-template/skills/pm-startup/SKILL.md` + 3 distributed copies).
- Issue templates — BD-063 (.github/ISSUE_TEMPLATE/* in both surfaces).

Per-CLI symmetry is enforced by validate-pack Check 21. No additional BD here; this section is the consolidated map.)

---

### §1.13 Tests and CI integration

**BD-083 — Aggregate CI workflow update + test runner**
Type: TODO(version)
Scope: A
Files:
- `.github/workflows/validate-pack.yml` (PACK-ROOT, modified) — invoke the new test scripts: `tracker-provider-test.sh`, `tracker-migrate-forward-test.sh`, `tracker-migrate-roundtrip-test.sh`, `recommendation-test.sh`, `tracker-errors-test.sh`. Stage-fence the live-network tests (skipped in CI by default; recorded fixtures used).

Description: One workflow, one runner. Each test script is independent and can fail independently. CI surfaces the per-test status.

Blockers: BD-060, BD-065, BD-068, BD-072, BD-070.

Verification: CI run shows all v11 test scripts executed; each is green.

Definition-of-Done: CI workflow updated; failures isolated to the failing test, not the whole run.

---

## §2. Scope B — v11 version cut + ride-alongs

### §2.1 MIGRATION-v10-to-v11.md (structure spec + creation BD)

#### §2.1.1 Structure spec — section by section

The new file lives at `supporting-docs/MIGRATION-v10-to-v11.md` (per pack convention, `supporting-docs/MIGRATION-vN-to-vM.md`). It mirrors `MIGRATION-v9-to-v10.md` structure for navigability:

1. **What changed in v11** — high-level summary covering both Scope A (tracker integration available as opt-in) and Scope B (BD-042 doc relocation, BD-059 migration safety improvements, trinity addenda).
2. **What does NOT change from v10** — flat-file workflow remains the default; existing `BACKLOG.md` / `STATUS.md` / `IMPLEMENTATION_PLAN.md` formats unchanged; project customization preserved (the BD-059 lessons-learned anchor).
3. **Before you start** — preconditions; recommended setup; `gh` CLI optional unless tracker mode is intended.
4. **Phase A — Forced v10 → v11 changes (everyone runs)** — these are the changes everyone upgrading must adopt:
   - Phase A.1: Run the migration script (`scripts/migrate-v10-to-v11.sh`) — applies trinity addenda (one-line "Pack commands" + "Recommended first action"); installs HELP-FRAGMENT files and per-CLI `pack-help` surfaces; adds `## Document locations` Source column to project-template trinity; relocates pack reference docs per BD-042.
   - Phase A.2: Review the migration report — accurate customization listing (the BD-059 fix); confirm what changed.
   - Phase A.3: Verify — run `validate-pack.py` (or the project-side equivalent) to confirm the upgrade landed cleanly.
5. **Phase B — Optional tracker opt-in (per surface, per user choice)** — independent of Phase A:
   - Phase B.1: When to consider opting in — references the OQ-19 inflection signals.
   - Phase B.2: How to opt in — `pack tracker init` walkthrough; auth prerequisites; what the migration does (forward + mirror).
   - Phase B.3: How to opt out — `pack tracker disable` + reverse migration; what's preserved (everything in v10 grammar) + what goes to sidecar.
   - Phase B.4: Independence axes — pack-side and client-side are independent; one client's tracker choice does not constrain the pack's (V3 §3.4 / DESIGN-BRIEF.md §5.4).
6. **BD-059 lessons-learned: customization preservation contract** — explicit section. Documents:
   - The v10 migration silently overwrote project customization in trinity files, `PM-CHAT.md`, settings, and config.
   - The v11 migration preserves customization across the full surface area touched.
   - The migration report is now truthful about what changed.
   - How to inspect / approve before commit.
7. **Step-by-step for project upgrades** — git workflow (branch, run script, review report, verify, commit, merge).
8. **Step-by-step for pack-repo upgrade** — different surface (the pack repo itself uses `pack-startup`, not `pm-startup`); same shape.
9. **Project-type-specific notes** — Swift / Apple, Python, gRPC / monorepo, Custom-agent projects.
10. **Rollback** — restore-from-backup procedure (mirrors `MIGRATION-v9-to-v10.md` Rollback section).
11. **Troubleshooting** — same shape as v9-to-v10 troubleshooting, refreshed for v11.
12. **What to do after migration** — first PM Chat run; static greeting; recommendation prompt at threshold; `pack help` discovery.
13. **Automated migration via AI CLI** — the section equivalent to the v9-to-v10 Automated section.
14. **Appendix: Trinity addenda exact text** — the byte-identical lines that appear in CLAUDE.md / AGENTS.md / GEMINI.md.
15. **Appendix: List of all v11 artifacts installed** — references V3 §I.1 / §I.2 + Scope-B additions.

**BD-084 — Create `supporting-docs/MIGRATION-v10-to-v11.md`**
Type: TODO(version)
Scope: B
Files:
- `supporting-docs/MIGRATION-v10-to-v11.md` (new) — content per §2.1.1 spec above.

Description: The authoritative v10→v11 migration narrative. Pairs with the migration script (BD-085). Length comparable to v9-to-v10 (~800 lines).

Blockers: BD-085 (the script must exist and have a known surface before the doc accurately describes it); BD-088 (BD-059 customization-preservation behavior must be defined before the doc can document it); BD-091 (BD-042 relocation must be done before the doc can describe the post-relocation layout).

Verification:
- Manual review for completeness against §2.1.1 structure spec.
- validate-pack Check 22 confirms every v11 verb named in the doc is in HELP-FRAGMENT.
- Cross-reference check: every section 1–15 above is present.

Definition-of-Done: File lands; QUICKSTART.md (BD-090) references it correctly; all v11 verbs mentioned are also in HELP-FRAGMENT.

---

### §2.2 README + CHANGELOG version cut

**BD-085 — `scripts/migrate-v10-to-v11.sh` (the migration script itself)**
Type: TODO(version)
Scope: B
Files:
- `scripts/migrate-v10-to-v11.sh` (new) — one-shot migrator paralleling `scripts/migrate-v9-to-v10.sh`. Applies Phase A only (tracker opt-in is post-migration via `pack tracker init`).
- `scripts/lib/migrate-v10-to-v11/` (new directory) — splice/merge helpers specific to v10→v11. Reuses `merge-trinity.py`, `merge-json.py`, `merge-toml.py` from existing scripts.
- `scripts/tests/test-migrate-v10-to-v11.sh` (new) — fixture tests covering the BD-088 customization-preservation contract.

Description: The script that everyone upgrading runs. Applies trinity addenda; installs help fragments + per-CLI `pack-help` surfaces; adds `## Document locations` Source column; performs BD-042 relocation; produces a truthful customization report (the BD-059 fix). Tracker opt-in is **not** part of this script — that's `pack tracker init` post-migration.

Blockers: BD-088 (customization-preservation algorithm must exist), BD-091 (BD-042 relocation logic must exist), BD-080 (`init-project.sh` extensions inform the parallel migrator behavior).

Verification:
- Fixture test on a synthetic v10 project: customization preserved; report truthful.
- Re-run yields no changes (idempotency).
- Rollback via `restore-from-backup.sh` recovers the pre-migration state.

Definition-of-Done: Script idempotent; report truthful; backup mechanism works; all v11 client-side artifacts installed.

---

**BD-086 — README.md version table v11.0 row + Repository Layout updates**
Type: TODO(version)
Scope: B
Files:
- `README.md` (PACK-ROOT, modified) — add v11.0 row to the version table per the existing format; update Repository Layout to include `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `tracker.toml.example`, `.github/ISSUE_TEMPLATE/` (pack-root); update `project-template/` subtree to reference relocated docs (BD-042) + new help fragments + tracker.toml.example + issue templates.

Description: Single-source-of-truth update for the pack version history and repo layout. Pack maintainer rule: README version table is PM Chat only — this BD must be approved by Pack Chat before commit.

Blockers: BD-091 (relocation must be reflected in the layout), BD-076 (HELP-FRAGMENT files must exist before being listed), BD-093 (the v11.0 release commit pin is needed).

Verification: README renders correctly on GitHub; version table parses; Repository Layout matches actual `find . -type d` output.

Definition-of-Done: v11.0 row added; layout matches reality.

---

**BD-087 — CHANGELOG.md v11.0 entry**
Type: TODO(version)
Scope: B
Files:
- `CHANGELOG.md` (PACK-ROOT, modified) — add a v11.0 entry covering both scopes per the existing format. Includes:
  - Scope A: D-1..D-20 list, BDs landed (BD-060..BD-083), per-CLI files added.
  - Scope B: BD-059 fix, BD-042 relocation, trinity addenda, MIGRATION-v10-to-v11.md.

Description: Pack maintainer rule: CHANGELOG only at version boundaries with explicit instruction. This BD lands at v11.0 cut.

Blockers: All other BDs in this plan land first; CHANGELOG is written from the as-shipped state. Direct blocker: BD-093 (release pin).

Verification: Manual review against this implementation plan; cross-check that every BD-060..BD-093 is reflected.

Definition-of-Done: v11.0 entry covers all changes; commit message format `feat: v11 — ship v11.0 release`.

---

### §2.3 Trinity addenda (Recommended first action; Pack commands reference)

(Already covered in BD-081. Six files, lockstep. The "Recommended first action" line and "Pack commands" line ship in the same commit per the trinity rule. Cross-reference here for visibility.)

---

### §2.4 QUICKSTART callout + OPTIONAL-FEATURES + INSTALL-PROCEDURES updates

**BD-090 — QUICKSTART.md callout + cross-references**
Type: TODO(version)
Scope: B
Files:
- `QUICKSTART.md` (PACK-ROOT, modified) — add top-of-doc "Recommended first action: run `pack-startup` (pack repo) or `pm-startup` (client repo) in your CLI" callout per V3 §A.2. Add link to `MIGRATION-v10-to-v11.md` for upgraders. Add link to HELP-FRAGMENT references and `pack help` for verb discovery. Reference `OPTIONAL-FEATURES.md` for tracker opt-in walkthrough.

Description: Implements V3 §A.2 QUICKSTART callout. Maintains the existing path-router ("New project / Existing project / Pack version upgrade") shape but adds the v11 entry-point hint.

Blockers: BD-084 (the migration doc this references must exist).

Verification: Manual; validate-pack Check 22 confirms the verbs named in QUICKSTART.md are present in HELP-FRAGMENT.

Definition-of-Done: QUICKSTART.md updated; new callout near the top; v11 migration link present.

---

**BD-091 — BD-042 doc relocation + cross-reference sweep (Phase 1: relocate)**
Type: TODO(version)
Scope: B
Files:
- `project-template/METHODOLOGY.md` → relocated to `project-template/docs/pack/METHODOLOGY.md` (BD-042 verifies METHODOLOGY isn't already at `docs/pack/`; per README v9.2 line, BD-042 in v9.2 already moved pack reference docs to docs/pack/ — `MAINTAINER CHECK NEEDED` §6.D: confirm what BD-042 still owns vs what was already shipped).
- `project-template/PROMPT-TEMPLATES.md` → relocated.
- `project-template/PM-CHAT.md` (if present at template root) → relocated.
- `project-template/PLATFORM-SKILLS.md` → relocated.
- `project-template/PACK-FEEDBACK.md` → relocated.

Description: Per BD-042. The README's v9.2 entry suggests this work was partially shipped in v9.2 (`BD-042 pack reference docs moved to docs/pack/`); v11 ships the **complete** relocation across any remaining root-level reference docs in project-template, plus the cross-reference sweep (BD-092). The `MAINTAINER CHECK NEEDED` flag invites confirmation that BD-042 remains in scope; if v9.2 already completed it, this BD reduces to a verification-only no-op and Scope B's BD-042 line is closed.

Blockers: None (relocation precedes documentation that references the new locations).

Verification:
- `find project-template -maxdepth 1 -name '*.md'` shows only the trinity (CLAUDE/AGENTS/GEMINI) + README plus any required-at-root files.
- All five named files (or those still at template root) are now under `project-template/docs/pack/`.

Definition-of-Done: Files at correct location; old paths removed; `git mv` used to preserve history.

---

**BD-092 — Cross-reference sweep for relocated docs + v11 verbs**
Type: TODO(version)
Scope: B
Files (modified):
- `project-template/docs/pack/METHODOLOGY.md` (or wherever it lives post-BD-091) — internal cross-references.
- `project-template/docs/pack/PROMPT-TEMPLATES.md` — same.
- `project-template/docs/pack/PM-CHAT.md` — same.
- `project-template/docs/pack/PLATFORM-SKILLS.md` — same.
- `project-template/docs/pack/PACK-FEEDBACK.md` — same.
- `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — references to relocated docs (Trinity-replicated).
- `project-template/skills/pm-startup/SKILL.md` (and the three distributed copies in `.claude/`, `.codex/`, `.gemini/`) — references.
- `supporting-docs/CLI-PM-SETUP.md` — references.
- `supporting-docs/SETUP_TEMPLATE.md` — references.
- `supporting-docs/SETUP-NEW.md` — references.
- `supporting-docs/SETUP-EXISTING.md` — references.
- `supporting-docs/INSTALL-PROCEDURES.md` — references.
- `supporting-docs/MIGRATION-v9-to-v10.md` — historical, does NOT change.
- `supporting-docs/MIGRATION-v10-to-v11.md` (BD-084) — references the post-relocation layout.
- `OPTIONAL-FEATURES.md` (PACK-ROOT) — adds tracker section per V3 §27.4 + Scope A; references v11 verbs; references `MIGRATION-v10-to-v11.md`.
- `PACK-CHAT.md` (PACK-ROOT, modified) — V1 §A.2 + V3 §A.2: add tracker orchestration patterns; add "Recommendation routing" section; add "Pack commands" reference.
- `project-template/docs/pack/PM-CHAT.md` (CLIENT, modified) — same parallel additions.
- `PACK-AGENTS.md` (PACK-ROOT, modified) — pack-agent invocation lines reference the v11 verb surface where applicable.

Description: One sweep BD that updates every cross-reference impacted by (a) BD-042 relocation, and (b) v11 verb additions. Touches many files but each diff is small.

Blockers: BD-091 (BD-042 relocation), BD-076 (HELP-FRAGMENT files), BD-073 (`enable-recommendations`).

Verification:
- `grep -rn "PROMPT-TEMPLATES.md" project-template/ supporting-docs/ *.md` returns only paths that include the post-relocation location.
- validate-pack Check 22 (BD-082) verifies external doc verb references match HELP-FRAGMENT.
- validate-pack existing trinity-parity Check 18 still passes after PACK-CHAT.md / PM-CHAT.md additions.

Definition-of-Done: All cross-references updated; Check 22 passes; no stale paths.

---

### §2.5 BD-059 — v10 migration customization preservation

**BD-088 — Customization-preservation algorithm + truthful report (BD-059 fix)**
Type: TODO(version)
Scope: B
Files:
- `scripts/lib/customization-preserve.sh` (new) — per-file preservation rules covering:
  - Trinity files: detect non-pack-template content (everything outside the marker sections); preserve via 3-way merge (pack-template-old / project-current / pack-template-new) — NOT the v10 algorithm that only preserved `**Active skills:**` line + `### Custom agents` section.
  - `.claude/settings.json`: preserve `XCODE_SCHEME`, `XCODE_DESTINATION`, project-tuned permissions (use `merge-json.py` with allowlist of pack-managed keys).
  - `.codex/config.toml`: preserve project-intentional removals/additions (e.g., `[model_providers.ollama]`, `[model_providers.lmstudio]`); use `merge-toml.py` with allowlist.
  - `.gemini/.env`: preserve `AGENT_CAPABILITIES` and any project-set env (per BD-059 success criterion).
  - `.mcp.json.example`, `.codex/config.toml.example`: same allowlist pattern.
  - `docs/pack/PM-CHAT.md`: detect project-name customizations and project-specific role/body content; preserve via marker-section convention OR diff-recognition fallback.
  - All scripts in `scripts/`: preserve project-added scripts; only update pack-shipped scripts.
  - All agent files in `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`: preserve `x-` prefix files (project-custom); only update pack-shipped names.
- `scripts/lib/customization-report.sh` (new) — generates a truthful `report.md` listing every customization detected, preserved, or overwritten.
- `scripts/tests/test-customization-preserve.sh` (new) — fixture tests against synthetic v10-state projects with realistic customization shapes (drawn from the OT post-migration audit per BD-059 context).

Description: Implements the BD-059 fix as a v11-cut artifact. The same library is used by `init-project.sh` `--update` (BD-080) and `migrate-v10-to-v11.sh` (BD-085) so all v11 migration paths share one customization-preservation contract.

Blockers: None (pure infrastructure; BD-085 + BD-080 consume it).

Verification:
- Realistic v10 fixture (modeled on OT) → run preservation algorithm → diff against expected output: customization preserved, pack-template content updated.
- Truthful report: every preserved file listed; every modified file listed; no `customization: none` falsehood (the BD-059 root-cause).
- v9.3 projects without v10's marker-section convention still preserved correctly via the diff-recognition fallback (BD-059 success criterion).
- validate-pack.py gains coverage that would have caught the original BD-059 defect (BD-089).

Definition-of-Done: Library lands; tests pass; consumed by BD-080 and BD-085.

---

**BD-089 — validate-pack.py Check 25 (customization-detection regression guard)**
Type: TODO(version)
Scope: B
Files:
- `scripts/validate-pack.py` (modified) — adds Check 25: a synthetic test that simulates `migrate-v10-to-v11.sh` against a fixture v10 project with known customization shapes and asserts the customization-preservation report names every preserved file.

Description: Closes the verification gap from BD-059 success criterion: "the closure includes a fixture or fixture pattern that exercises realistic v9.3 customization shapes." Runs in CI on every push.

Blockers: BD-088 (the algorithm + library), BD-085 (the migrator that uses it).

Verification: CI fails when BD-088 logic regresses; passes on the canonical fixture.

Definition-of-Done: Check 25 lands; CI passes; failure-mode demonstrated by deliberately breaking BD-088 in a temporary commit and observing the failure.

---

### §2.6 BD-042 — Pack reference doc relocation

(Covered by BD-091 (relocation) + BD-092 (cross-reference sweep). Cross-reference here for visibility.)

---

### §2.7 Doc cross-reference sweep (post-relocation + v11 refs)

(Covered by BD-092. Cross-reference here for visibility.)

---

**BD-093 — v11.0 release pin (tag, README, CHANGELOG, MIGRATION cross-link)**
Type: TODO(version)
Scope: B
Files:
- `README.md` — v11.0 row finalized with date + commit hash placeholder filled.
- `CHANGELOG.md` — v11.0 entry finalized.
- Tag operation: delete `v11` if present; recreate `v11.0` and `v11`; push.

Description: The release-cut commit. Per the trinity / version-table rules: only after Pack Chat approval.

Blockers: All BDs above (BD-060..BD-092).

Verification:
- `git tag --list v11*` shows both `v11.0` and `v11`.
- `validate-pack.py` passes on the tagged commit.
- `MIGRATION-v10-to-v11.md` references reflect the as-shipped state.

Definition-of-Done: v11.0 tag pushed; v11 floating tag updated; CHANGELOG + README v11.0 row final.

---

## §3. Cross-scope dependencies and sequencing

### §3.1 Critical path

The critical path from BD-060 to v11.0 release pin (BD-093):

```
BD-060 (provider abstraction)
  → BD-061 (tracker.toml + detection)
    → BD-063 (issue forms)
      → BD-064 (templates-archive bd-v11.0)
        → BD-065 (forward migration)
          → BD-067 (reverse migration + sidecar)
            → BD-068 (round-trip test)
              → BD-069 (template_version dual carrier)

BD-061 → BD-072 (recommendation library + state)
  → BD-073 (enable-recommendations verb)
    → BD-074 (Step 8 in pack-startup / pm-startup)

BD-066 (pack tracker init wrapper) → BD-076 (HELP-FRAGMENTs)
  → BD-077 (per-CLI pack-help)
    → BD-080 (init-project.sh extensions)
      → BD-081 (trinity addenda)
        → BD-082 (Checks 21–24)

BD-088 (customization-preserve) parallels Scope-A; gates BD-085
  → BD-085 (migrate-v10-to-v11.sh)
    → BD-091 (BD-042 relocation)
      → BD-092 (cross-ref sweep)
        → BD-084 (MIGRATION doc)
          → BD-090 (QUICKSTART callout)
            → BD-086 (README v11.0 row + Layout)
              → BD-087 (CHANGELOG v11.0 entry)
                → BD-093 (release pin)
```

The critical path is **BD-060 → BD-061 → BD-072 → BD-074 → BD-076 → BD-077 → BD-080 → BD-088 → BD-085 → BD-091 → BD-092 → BD-084 → BD-090 → BD-086 → BD-087 → BD-093**. Roughly 16 sequential BDs with parallelism opportunities at BD-063, BD-066, BD-070, BD-082, BD-083, BD-089.

### §3.2 Dependency graph

| BD | Blockers |
|---|---|
| BD-060 | None |
| BD-061 | BD-060 |
| BD-062 | BD-061 |
| BD-063 | BD-061 |
| BD-064 | BD-063 |
| BD-065 | BD-060, BD-061, BD-063 |
| BD-066 | BD-065 |
| BD-067 | BD-064, BD-065 |
| BD-068 | BD-067 |
| BD-069 | BD-064, BD-065, BD-067 |
| BD-070 | BD-060 |
| BD-071 | BD-062, BD-070 |
| BD-072 | BD-061 |
| BD-073 | BD-072 |
| BD-074 | BD-072, BD-073 |
| BD-075 | BD-076 |
| BD-076 | BD-066, BD-073 |
| BD-077 | BD-075 |
| BD-078 | BD-061 |
| BD-079 | BD-072 |
| BD-080 | BD-076, BD-077, BD-063 |
| BD-081 | BD-077 |
| BD-082 | BD-076, BD-077, BD-080, BD-081 |
| BD-083 | BD-060, BD-065, BD-068, BD-072, BD-070 |
| BD-084 | BD-085, BD-088, BD-091 |
| BD-085 | BD-088, BD-091, BD-080 |
| BD-086 | BD-091, BD-076, BD-093 (cyclic — see note) |
| BD-087 | All other BDs; BD-093 |
| BD-088 | None |
| BD-089 | BD-088, BD-085 |
| BD-090 | BD-084 |
| BD-091 | None |
| BD-092 | BD-091, BD-076, BD-073 |
| BD-093 | All BDs above |

Note on BD-086 ↔ BD-093: BD-086 lands the README row prior to release (with placeholder commit hash); BD-093 finalizes with the actual hash. The cycle is broken by treating BD-086 as a two-step BD (placeholder commit, then post-tag fixup) — the second step is part of BD-093.

### §3.3 Suggested commit order

(Each line = one commit. Each commit lands one BD unless explicitly grouped.)

1. BD-060 — provider abstraction.
2. BD-061 — tracker.toml + detection + gitignore.
3. BD-063 — issue forms (work-item + inbound, both surfaces).
4. BD-064 — templates-archive bd-v11.0.
5. BD-070 — typed errors (parallel-able with above; sequenced here for clarity).
6. BD-065 — forward migration.
7. BD-066 — pack tracker init wrapper.
8. BD-067 — reverse migration + sidecar.
9. BD-068 — round-trip test.
10. BD-069 — template_version dual carrier.
11. BD-062 — trinity Source column.
12. BD-071 — agent-prompt language change (10 prompt files).
13. BD-072 — recommendation lib + state.
14. BD-073 — enable-recommendations verb.
15. BD-074 — pack-startup / pm-startup Step 8 (7 files: 3 pack + 4 client).
16. BD-076 — HELP-FRAGMENT files (4 files).
17. BD-075 — pack-help.sh script.
18. BD-077 — per-CLI pack-help (6 files: 3 pack + 3 client). **Trinity-replicated × 2 surfaces.**
19. BD-088 — customization-preserve library.
20. BD-091 — BD-042 relocation.
21. BD-080 — init-project.sh extensions.
22. BD-085 — migrate-v10-to-v11.sh.
23. BD-081 — trinity addenda (6 files). **Trinity-replicated × 2 surfaces.**
24. BD-082 — validate-pack Checks 21–24.
25. BD-078 — Check 19.
26. BD-079 — Check 20.
27. BD-089 — Check 25.
28. BD-083 — CI workflow update.
29. BD-092 — cross-reference sweep.
30. BD-084 — MIGRATION-v10-to-v11.md.
31. BD-090 — QUICKSTART callout + cross-references.
32. BD-086 — README v11.0 row + Repository Layout.
33. BD-087 — CHANGELOG v11.0 entry.
34. BD-093 — v11.0 release pin (tag).

CI green at every numbered boundary.

---

## §4. Verification strategy

### §4.1 Per-BD test plan summary

(Each BD's Definition-of-Done includes its verification. Summary table:)

| BD | Test mechanism |
|---|---|
| BD-060 | `scripts/tests/tracker-provider-test.sh` against fixtures |
| BD-061 | tracker_mode() unit fixture (3 input cases) |
| BD-062 | Trinity Check 18 (existing); Source column well-formedness |
| BD-063 | GitHub server-side validation; YAML well-formedness in validate-pack |
| BD-064 | Manual; soft-warning check in validate-pack |
| BD-065 | `scripts/tests/tracker-migrate-forward-test.sh` |
| BD-066 | Manual smoke + auth-error test |
| BD-067 | Reverse-fixture diff (whitespace tolerant) |
| BD-068 | `scripts/tests/tracker-migrate-roundtrip-test.sh` |
| BD-069 | Synthetic version-delta patch-plan test |
| BD-070 | `scripts/tests/tracker-errors-test.sh` (9 codes) |
| BD-071 | grep audit; agent integration test |
| BD-072 | `scripts/tests/recommendation-test.sh` (7 cases per V3 §28.1.10) |
| BD-073 | State-file-flip fixture |
| BD-074 | Worked-example fixture replays (V3 §D.1–§D.4) |
| BD-075 | Surface-detection fixture (3 cases) |
| BD-076 | Manual + Check 24 byte-identity |
| BD-077 | Check 21 per-CLI parity |
| BD-078 | Check 19 lands; passing + failing fixtures |
| BD-079 | Check 20 lands; valid/corrupt/missing fixtures |
| BD-080 | Fresh-install fixture; --update fixture |
| BD-081 | Check 18 + Check 21 |
| BD-082 | Per-Check failing-fixture test |
| BD-083 | CI run shows all v11 tests executed |
| BD-084 | Manual review against §2.1.1 spec |
| BD-085 | `scripts/tests/test-migrate-v10-to-v11.sh` |
| BD-086 | Manual; GitHub render |
| BD-087 | Manual review |
| BD-088 | `scripts/tests/test-customization-preserve.sh` (OT-modeled fixture) |
| BD-089 | Check 25 lands; deliberate-break test |
| BD-090 | Manual; Check 22 |
| BD-091 | `find` audit; `git mv` history preserved |
| BD-092 | grep audit (no stale paths); Check 22 |
| BD-093 | Tag exists; validate-pack passes on tagged commit |

### §4.2 Validate-pack expansion

After v11.0, validate-pack.py runs Checks 1–20 (existing v10 + v10.x extensions; verify next-free Check number at BD-078 land-time per §6.C) plus:

- **Check 19** (BD-078) — `check_tracker_config`: `tracker.toml` schema + mirror-freshness warning.
- **Check 20** (BD-079) — `check_recommendation_state_schema`: state-file v1 schema validity.
- **Check 21** (BD-082) — Trinity per-CLI help-surface parity.
- **Check 22** (BD-082) — Help-fragment freshness against external doc verb references.
- **Check 23** (BD-082) — Help-fragment completeness against `scripts/` top-level executables.
- **Check 24** (BD-082) — Pack-root vs client-mirror byte-identity for `HELP-FRAGMENT-TRACKER.md`.
- **Check 25** (BD-089) — Customization-detection regression guard (BD-059 fix).

Total at v11.0: Checks 1–25 (with gaps if v10 used non-contiguous numbers; `MAINTAINER CHECK NEEDED` §6.C: confirm next free number for Check 19 onward).

### §4.3 Integration test fixtures

The following fixture trees must exist by v11.0 cut:

- `scripts/tests/fixtures/tracker-migrate-forward/v10-shape/` — synthetic v10 BACKLOG / IMPLEMENTATION_PLAN with ~20 entries.
- `scripts/tests/fixtures/roundtrip/bd-v11.0/` — round-trip fixture for v11.0 entries.
- `scripts/tests/fixtures/recommendation/pack-fresh/` — pack repo at v10-shipped state (under threshold).
- `scripts/tests/fixtures/recommendation/client-ot-scale/` — client repo modeled on OT (V3 §D.2).
- `scripts/tests/fixtures/customization-preserve/v10-with-customization/` — synthetic v10 project with realistic customization across trinity, settings, config (drawn from OT post-migration audit per BD-059).
- `scripts/tests/fixtures/help-fragment/canonical-vs-mirror-mismatch/` — fixture exercising Check 24 failure.
- `scripts/tests/fixtures/tracker-errors/` — fault-injection inputs for each of 9 typed codes.

### §4.4 CI gates at v11.0

The Validate Pack workflow at v11.0 runs:

1. `python scripts/validate-pack.py` (Checks 1–25).
2. `bash scripts/tests/tracker-provider-test.sh` (offline; recorded fixtures).
3. `bash scripts/tests/tracker-migrate-forward-test.sh`.
4. `bash scripts/tests/tracker-migrate-roundtrip-test.sh`.
5. `bash scripts/tests/recommendation-test.sh` (7 cases).
6. `bash scripts/tests/tracker-errors-test.sh` (9 codes).
7. `bash scripts/tests/test-customization-preserve.sh`.
8. `bash scripts/tests/test-migrate-v10-to-v11.sh`.

Live-network tests are gated behind an env var (`PACK_TEST_LIVE=1`) and not run in CI by default.

---

## §5. Risks and rollback

### §5.1 High-risk BDs and mitigations

- **BD-060 (provider abstraction).** Risk: getting the operation surface wrong forces re-design downstream. Mitigation: V1 §2.1 + §2.7.1 mapping is the contract; test against recorded fixtures before downstream BDs depend on it. Aligns with R1 (V1 §17.1).
- **BD-067 + BD-068 (reverse migration + round-trip).** Risk: round-trip regression silently loses data. Mitigation: test fixture forced into CI (Check via BD-068 round-trip-test.sh); diff = 0 is fail-closed.
- **BD-072 + BD-074 (recommendation system + Step 8 integration).** Risk: nagging-anti-pattern regression (R15). Mitigation: Guard 4 25%-growth check + `last_recommendation_signals` snapshot per V3 §28.1.5; integration test 10-session-no-refire scenario per V3 R15.
- **BD-085 + BD-088 (migration script + customization preservation).** Risk: BD-059 regression — silent customization loss. Mitigation: BD-088 algorithm tested against OT-modeled fixture; BD-089 Check 25 gates CI; BD-085 produces a backup before any destructive write (mirrors `migrate-v9-to-v10.sh` backup mechanism).
- **BD-091 + BD-092 (BD-042 relocation + cross-ref sweep).** Risk: stale references cause broken links across the pack. Mitigation: grep audit before commit; Check 22 (BD-082) catches most cases at PR time.
- **BD-077 (per-CLI pack-help × 2 surfaces).** Risk: per-CLI drift (R17). Mitigation: Check 21 (BD-082) verifies parity; trinity rule applies and is documented in `PACK-CHAT.md`.

### §5.2 Rollback procedure per BD

For any BD on the critical path that fails verification at land-time:

- Pre-tag BDs (BD-060 to BD-092): `git revert` the BD's commit; re-run validate-pack; investigate.
- BD-088 (customization-preserve): preserved snapshot from `restore-from-backup.sh` recovers any test project; the algorithm itself is reverted via `git revert`.
- BD-091 (BD-042 relocation): if BD-091 lands but BD-092 fails (stale references), `git revert BD-091` restores the prior layout while fixes are made.
- BD-093 (release tag): `git tag -d v11.0`; `git push --delete origin v11.0`; recreate after fix.

User explicit approval required for any tag deletion or `git revert` per `CLAUDE.md` rules.

---

## §6. MAINTAINER CHECK NEEDED items

These are points where the plan would otherwise force a decision that is properly an architect or maintainer call. Each is flagged with options and a recommendation; the plan does not paper over.

- **§6.A — Multi-template-version round-trip fixture at v11.0 cut.** V1 §6.6.1 specifies fixtures on `bd-v11.0`, `bd-v11.1`, `bd-v11.2`. v11.0 only has `bd-v11.0`. Options:
  - (a) Ship empty `bd-v11.1/` and `bd-v11.2/` directories with READMEs explaining "populated when minor lands."
  - (b) Defer the multi-version part to v11.1 cut; v11.0 round-trip test only covers `bd-v11.0`.
  - **Recommendation: (a)** — directory structure proves readiness and the test scaffolding is in place for v11.1 to drop in entries without re-architecting. BD-068 reflects this choice.

- **§6.B — `scripts/pack-help.sh` provenance.** V3 §I.3 lists `scripts/pack-help.sh` as "preserved (V2 already named; V3 broadens internal logic without renaming)" but the file does not currently exist in `scripts/` per the `ls` audit. Options:
  - (a) BD-075 ships `scripts/pack-help.sh` for the first time in v11.
  - (b) The architect intends v11 to rename or relocate an existing helper; identify which.
  - **Recommendation: (a)** — V2 named the file in design without committing; v11 ships it. BD-075 reflects this.

- **§6.C — Next free `validate-pack.py` Check number.** The plan numbers v11 Checks 19–25. The current v10 README states "validate-pack.py expanded to 10 checks." Some intermediate numbers (11–18) may have been added in v9.x. Options:
  - (a) Reuse the architect's V1 §A.2 numbering (Check 19 onward); audit `validate-pack.py` HEAD to confirm 11–18 are taken.
  - (b) Renumber to the actual next free integer.
  - **Recommendation: (a) with audit step.** BD-078 / BD-079 / BD-082 / BD-089 all reference the architect's numbering; the planner should run `grep "def check_" scripts/validate-pack.py` at BD-078 land-time to confirm the next free number; if 19–25 are not free, renumber the v11 Checks contiguously starting from the actual next free integer and update this plan.

- **§6.D — BD-042 scope at v11.** README v9.2 entry says "BD-042 pack reference docs moved to docs/pack/; document locations section added to context files." But `BACKLOG.md` BD-042 is still `Status: Open`. Options:
  - (a) v9.2 partially shipped BD-042 (relocated some files); v11 finishes the work — verify which files remain at template root vs already relocated.
  - (b) BD-042 is fully shipped in v9.2 and the backlog is stale; v11's role is to verify and close BD-042.
  - **Recommendation: audit at BD-091 land-time.** Run `find project-template -maxdepth 1 -name '*.md'` and reconcile against BD-042's File/Symbol list. If all files already relocated, BD-091 reduces to a verification-only no-op and BD-042 closes in v11 via the BACKLOG status flip; if any remain at template root, BD-091 ships them.

- **§6.E — Pack-repo trinity exemption from `## Document locations` (D-6 footnote).** V3 D-6 states the Source column applies to project-template trinity only ("pack-repo trinity has no `## Document locations` section"). The plan honors this in BD-062. The maintainer should confirm this asymmetry is intentional and not a gap; if the pack-repo trinity should also gain a `## Document locations` section, BD-062 expands by 3 files. **Recommendation: defer; honor V3 D-6 as stated.**

- **§6.F — Pack-repo `pack-startup` skill location.** V3 §I.2 lists `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`, `.gemini/commands/pack-startup.toml` at PACK-ROOT. The current pack repo has no `.claude/`, `.codex/`, `.gemini/` directories at the root (per `ls` — verified). Options:
  - (a) v11 introduces these directories at pack-root for the first time (BD-074 lands them).
  - (b) The architect intended a different location; clarify.
  - **Recommendation: (a)** — V3 §I.4 trinity propagation matrix names them at pack-root; BD-074 introduces them. The Pack Chat skill `pack-startup` exists per `PACK-CHAT.md` references; v11 formalizes it as Claude/Codex/Gemini skills/commands at pack-root.

---

## §7. Definition of v11.0 release-readiness

The maintainer ships v11.0 when all of:

- [ ] All 34 BDs (BD-060..BD-093) committed to main; each commit message uses `feat: v11 — BD-NNN <summary>`.
- [ ] `git log v10.0..v11.0` shows the §3.3 commit order (or an approved equivalent).
- [ ] `validate-pack.py` exits 0 on the v11.0 tagged commit. Checks 19–25 land and pass.
- [ ] All 8 CI test scripts (§4.4) green.
- [ ] `MIGRATION-v10-to-v11.md` complete per §2.1.1 structure spec; review checklist:
  - [ ] §1–§15 all present.
  - [ ] BD-059 lessons-learned section explicit.
  - [ ] Phase A (forced) and Phase B (optional tracker) clearly separated.
  - [ ] Verb references match HELP-FRAGMENT.
- [ ] `README.md` v11.0 row landed; Repository Layout reflects post-relocation tree + new fragments + tracker artifacts.
- [ ] `CHANGELOG.md` v11.0 entry covers Scope A (D-1..D-20) + Scope B (BD-059, BD-042, trinity addenda, MIGRATION doc).
- [ ] Trinity addenda (6 files) lockstep; Check 18 + Check 21 pass.
- [ ] `QUICKSTART.md` "Recommended first action" callout present.
- [ ] BD-059 fix verified: `scripts/tests/test-customization-preserve.sh` passes against the OT-modeled fixture; report is truthful.
- [ ] BD-042 closed: all five named files at relocated path; cross-reference grep audit clean.
- [ ] Tracker opt-in path verified end-to-end on the pack repo itself (eat-own-dog-food, per `DESIGN-BRIEF.md` §4.2).
- [ ] Reverse-migration verified: from tracker mode, run `pack tracker disable` against the pack repo; resulting flat files diff = whitespace-only against pre-init state.
- [ ] `v11.0` and `v11` tags pushed.
- [ ] BACKLOG.md status flipped: BD-042 `Resolved`; BD-059 `Resolved`; BD-060..BD-093 `Resolved` with v11.0 commit hashes.

When every checkbox is true, v11.0 is release-ready.
