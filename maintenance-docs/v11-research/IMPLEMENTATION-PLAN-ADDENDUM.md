# IMPLEMENTATION-PLAN-ADDENDUM — v11.0

## §0. Status

- **Date.** 2026-05-04.
- **Scope.** Closes 8 gaps in `IMPLEMENTATION-PLAN.md` (BD-060..BD-093) identified during pre-implementation review. The base plan stays unchanged; this addendum extends it.
- **Adds.** BD-094..BD-101 (8 BDs) plus one new deliverable doc (`MERGE-STRATEGY.md`).
- **Updates.** Base plan §3.3 commit-order (insertions only, no renumbering of existing 34 BDs); §6 MAINTAINER CHECK NEEDED list (3 new items §6.G, §6.H, §6.I); §7 release-readiness checklist (new checkboxes).
- **Constraints honored.** A1 failure-mode UX globally; general-use (no OT/Optiquity strings in user-facing artifacts; OT is one synthetic fixture among several); v9-and-earlier upgrade path is one paragraph in `MIGRATION-v10-to-v11.md`, no fan-out, no automation; multi-project guidance is one sentence; trinity rule applied where relevant; CI green at every BD boundary.
- **Highest BD now.** Base plan ends at BD-093. Addendum adds BD-094..BD-101 (verified by enumerating BD-NNN literals in the base plan and BACKLOG.md).
- **Acyclic.** Every `Blockers:` line in §1 names a BD that is either earlier in this addendum, in the base plan, or `None`. No new cycles introduced.

---

## §1. New BDs

### §1.1 BD-094 — `MERGE-STRATEGY.md` deliverable (per-file matrix + A1 UX)

**Title.** Author `MERGE-STRATEGY.md` — per-file customization-preservation matrix and A1 failure-mode UX

**Type.** TODO(version)

**Scope.** B

**Files.**
- `supporting-docs/MERGE-STRATEGY.md` (PACK-ROOT, new) — per-file matrix; primary strategies; A1 failure-mode UX; user-resolution workflow with `--resume`. Content spec: §2 of this addendum.
- `supporting-docs/MIGRATION-v10-to-v11.md` (BD-084, modified) — adds a "Merge strategy reference" cross-link near §6 BD-059 lessons-learned section pointing at `MERGE-STRATEGY.md`.
- `OPTIONAL-FEATURES.md` (PACK-ROOT, modified) — add cross-link from the tracker walkthrough section (BD-098) to `MERGE-STRATEGY.md` for users who hit a `*.merge-conflict` during opt-in/opt-out.
- `QUICKSTART.md` (PACK-ROOT, modified) — add a one-line "If you hit a merge conflict during upgrade, see `supporting-docs/MERGE-STRATEGY.md`" entry under the upgrade-path callout (set up by BD-090).

**Description.** The base plan ships customization-preservation logic in `scripts/lib/customization-preserve.sh` (BD-088), but the per-file matrix is buried in code and never surfaced as a user-readable doc. Real-world v9-to-v10 migration on a client project required multiple correction passes because users could not predict what the migrator would touch. `MERGE-STRATEGY.md` is the user-facing contract: for every file class the migrator touches, this doc names the primary strategy (3-way merge, allowlist-merge, marker-section, diff-recognition) and the A1 fallback (stop on unresolvable conflict, emit `*.merge-conflict` files, instruct user to resolve manually and re-run with `--resume`). Authoring is shape-agnostic: file paths and patterns are generic; no OT/Optiquity strings.

**Blockers.** BD-088 (per-file rules must exist in code first); BD-095 (the dry-run/apply CLI surface this doc references); BD-085 (the migrator script).

**Verification.**
- Manual review: every file class enumerated in `scripts/lib/customization-preserve.sh` appears in the matrix with one named primary strategy and the A1 fallback explicitly stated.
- `grep -i "OT\|Optiquity" supporting-docs/MERGE-STRATEGY.md` returns zero hits (general-use constraint).
- validate-pack Check 22 (BD-082) — every verb named in `MERGE-STRATEGY.md` (notably `migrate-v10-to-v11.sh --resume`, `restore-from-backup.sh`) appears in `HELP-FRAGMENT*.md`.
- Cross-reference check: `MIGRATION-v10-to-v11.md`, `OPTIONAL-FEATURES.md`, `QUICKSTART.md` each cite the file at its post-relocation path.

**Definition-of-Done.** File lands at `supporting-docs/MERGE-STRATEGY.md`; matrix covers every file class in BD-088; A1 UX documented end-to-end; cross-links from MIGRATION/OPTIONAL-FEATURES/QUICKSTART present; `validate-pack.py` exits 0.

---

### §1.2 BD-095 — `migrate-v10-to-v11.sh` two-phase `--dry-run` / `--apply` workflow

**Title.** Two-phase migrator: `--dry-run` produces a truthful report; `--apply` requires a fresh dry-run report; `--resume` continues from a `*.merge-conflict` resolution

**Type.** TODO(version)

**Scope.** B

**Files.**
- `scripts/migrate-v10-to-v11.sh` (modified — extends BD-085) — adds the three CLI modes below.
- `scripts/lib/migrate-v10-to-v11/dry-run.sh` (new) — produces `.pack-tracker/migrate-v10-to-v11.dry-run-report.md`. Enumerates: every file the migrator would touch; every customization detected per BD-088 rules; every file class's chosen strategy; every projected `*.merge-conflict` outcome. Read-only (no writes outside `.pack-tracker/`).
- `scripts/lib/migrate-v10-to-v11/apply.sh` (new) — runs the actual migration. **Precondition**: a dry-run report dated within the last 24 h must exist at `.pack-tracker/migrate-v10-to-v11.dry-run-report.md` and the script must verify the working-tree fingerprint (sha256 of relevant files) matches the dry-run snapshot. If the precondition fails, `--apply` exits non-zero with an actionable message ("Run `scripts/migrate-v10-to-v11.sh --dry-run` first; review the report; then re-run `--apply`.").
- `scripts/lib/migrate-v10-to-v11/resume.sh` (new) — `--resume` mode: detects `*.merge-conflict` files; verifies they have been resolved (no remaining `<<<<<<<` / `=======` / `>>>>>>>` markers and the conflict-companion `.resolved` flag-file is present); reads the BD-101 Gate-2 checkpoint at `.pack-tracker/migrate-v10-to-v11.checkpoint.json`; resumes from the last successful step. **Resume is forward-only**: it does not restart from step 0; if the user wants a fresh run, they delete the checkpoint and run `--dry-run` again.
- `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (new) — fixture tests covering: dry-run-only (no writes); apply-without-dry-run (rejected); apply-with-stale-dry-run (rejected); apply-with-fresh-dry-run (accepted); resume-with-unresolved-conflict (rejected); resume-with-resolved-conflict (accepted); resume-without-checkpoint (rejected with actionable message).

**Description.** Base plan BD-085 ships a one-shot migrator with no dry-run review. Real-world experience: the v9-to-v10 multi-pass slog could have been a single pass with a dry-run review + apply. This BD splits the migrator into the standard two-phase workflow. The dry-run report becomes the maintainer-readable input to BD-101 Gate 1 ("user reviews and approves"). `--resume` is the A1 escape-hatch consumer: when any auto-resolution fails, the migrator emits `*.merge-conflict` files, the user resolves them, then runs `--resume` to continue from the last checkpoint.

**Blockers.** BD-085 (the script the modes attach to); BD-088 (the customization-preservation rules the dry-run inspects); BD-094 (the user-facing doc the migrator's error messages cross-link to).

**Verification.**
- Each fixture in BD-096 (the synthetic-fixture set) is exercised in two-phase mode: `--dry-run` produces a truthful report; `--apply` succeeds.
- `test-migrate-v10-to-v11-dry-run.sh` covers all 7 cases in the file list above.
- Manual smoke: dry-run on the pack repo's own working tree (eat-own-dog-food); review the report; apply; verify validate-pack exits 0.

**Definition-of-Done.** Three modes (`--dry-run`, `--apply`, `--resume`) present and documented in `scripts/migrate-v10-to-v11.sh --help`; `--apply` precondition enforced; `--resume` enforces conflict-resolution check; report shape matches §2.4 of this addendum; CI test green.

---

### §1.3 BD-096 — Synthetic-fixture set (general-use coverage; OT is one example)

**Title.** Author 4 synthetic fixtures covering distinct customization shapes; ensure migrator and customization-preserve are general-use

**Type.** TODO(version)

**Scope.** B

**Files.**
- `scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/` (new) — synthetic v10 project: trinity files unchanged from pack template; one project-set permission in `.claude/settings.json`; no custom agents; no PM-CHAT.md edits. Represents the smallest plausible client surface.
- `scripts/tests/fixtures/customization-preserve/heavily-customized/` (new) — trinity files with extensive prose customizations (all six trinity files: client + per-CLI distributed copies); 3 custom `x-*` agents; PM-CHAT.md with project-name customizations and additional roles; `.codex/config.toml` with `[model_providers.ollama]` and `[model_providers.lmstudio]` removed; `.gemini/.env` with `AGENT_CAPABILITIES` set.
- `scripts/tests/fixtures/customization-preserve/language-heterogeneous/` (new) — Swift + Python + gRPC mixed: `proto/`, Swift companion files in `xcode-companion-templates/`, `pyproject.toml`, plus the standard pack files. Light customization. Proves migrator handles language-heterogeneous shapes.
- `scripts/tests/fixtures/customization-preserve/custom-agents-heavy/` (new) — pack-shipped agents present + 8 `x-*` agents + 2 `x-*` skills + 1 `x-*` Gemini command. Light prose customization. Proves the `x-` allowlist works at scale.
- `scripts/tests/fixtures/customization-preserve/v10-with-customization/` (already specified in base plan §4.3, retained as the BD-088 baseline) — modeled on a real client (OT post-migration audit). Becomes **one of five fixtures**, not the model.
- `scripts/tests/test-customization-preserve.sh` (modified, from BD-088) — exercise all 5 fixtures, not just the OT-modeled one. Each fixture has an expected `report.md` golden file the test diffs against.
- `scripts/tests/fixtures/customization-preserve/README.md` (new) — explains each fixture's shape and what it proves; explicitly states "OT-modeled fixture is one example among several; the pack is general-use."

**Description.** The base plan's BD-088 fixture is OT-modeled only. To prove general-use the customization-preservation algorithm must demonstrate correctness across at least 4 distinct shapes. This BD authors the fixture trees and extends the test runner. Each fixture is a self-contained directory the migrator runs against in CI. No fixture content uses "OT" or "Optiquity" in user-visible strings (file content); the directory naming for the OT-modeled fixture stays as `v10-with-customization` (per base plan), and its README internally documents its provenance without putting OT strings into the test output.

**Blockers.** BD-088 (the algorithm under test); BD-085 (the migrator that consumes the algorithm).

**Verification.**
- All 5 fixtures pass `test-customization-preserve.sh` end-to-end (dry-run + apply).
- BD-101 Gate 1 dry-run report shape verified against each fixture (§2.4 schema match).
- `grep -ri "Optiquity\|optiquity" scripts/tests/fixtures/customization-preserve/` returns hits only inside `README.md` provenance notes, not inside fixture content used by the migrator.
- `scripts/tests/fixtures/customization-preserve/README.md` enumerates all 5 fixtures with one paragraph each.

**Definition-of-Done.** All 5 fixture trees exist; test runner exercises all 5; golden reports diff cleanly; README authored; OT-modeled fixture explicitly framed as one of several.

---

### §1.4 BD-097 — Pre-release semantic audit pass

**Title.** `pack-reviewer` semantic audit pass before v11.0 release pin

**Type.** TODO(version)

**Scope.** B

**Files.**
- `maintenance-docs/v11-implementation/SEMANTIC-AUDIT-REPORT.md` (new — agent output) — the pack-reviewer agent's audit report. Generated by invoking `claude --agent pack-reviewer` (per pack-agent invocation reference) with input docs listed below; output written to this path.
- `maintenance-docs/v11-implementation/SEMANTIC-AUDIT-PROMPT.md` (new — agent input) — the prompt the maintainer feeds the reviewer. Includes context, output file path, read-only flag, markdown-only constraint, problem/goal/criteria, and the CLI command (per agent session prompt rules).

**Description.** validate-pack catches structural drift (file presence, schema, byte-identity, trinity parity). It does NOT catch semantic drift: e.g., a HELP-FRAGMENT entry that exists but describes the wrong verb behavior; a MIGRATION doc that says "Phase A applies trinity addenda" but the implementation actually applies them in Phase B; an OPTIONAL-FEATURES.md tracker section that contradicts `pack tracker init` actual prompts. BD-097 closes that gap with an explicit agent-driven semantic audit before BD-093 release pin.

The reviewer reads (read-only): `IMPLEMENTATION-PLAN.md` + this addendum; `ARCHITECTURE.md` (V1) + `ARCHITECTURE-V3.md` + `ARCHITECTURE-V3.1-DELTA.md`; `DESIGN-BRIEF.md`; the as-shipped working-tree state of `MIGRATION-v10-to-v11.md`, `MERGE-STRATEGY.md`, `OPTIONAL-FEATURES.md`, `QUICKSTART.md`, `HELP-FRAGMENT-*.md`, trinity files (pack + client), `PACK-CHAT.md`, `PM-CHAT.md`, all per-CLI skills/commands, and the migrator + customization-preserve sources.

**Pass/fail criteria.** Pass = report contains zero `severity: blocker` findings AND every `severity: warning` finding has either (a) a maintainer disposition note ("accepted; rationale: …") or (b) a follow-up BD opened in BACKLOG.md before BD-093. Fail = any blocker; halt; address; re-run audit.

**Blockers.** All Scope-A and Scope-B BDs except BD-086, BD-087, BD-093 (the release artifacts the audit gates).

**Verification.**
- Report exists at the named path; well-formed markdown; sections: Summary, Findings (blocker / warning / informational), Disposition.
- Every blocker addressed before BD-093; verified by re-reading the report at release-pin time.
- The prompt at `SEMANTIC-AUDIT-PROMPT.md` matches the agent session prompt rules (context, output path, read-only, markdown-only, problem/goal/criteria, CLI command, chunked-write instruction for outputs >300 lines).

**Definition-of-Done.** Audit run; report green per pass criteria; report archived with v11.0; cross-referenced in CHANGELOG v11.0 entry as "pre-release semantic audit: pass."

---

### §1.5 BD-098 — `OPTIONAL-FEATURES.md` tracker walkthrough (elevated user-doc home)

**Title.** Move GH Issue tracker enablement walkthrough to `OPTIONAL-FEATURES.md` as primary user-doc home; update cross-references

**Type.** TODO(version)

**Scope.** B

**Files.**
- `OPTIONAL-FEATURES.md` (PACK-ROOT, modified) — add a new top-level section: `## GitHub Issue Tracker (opt-in)`. Section structure (matches the existing Agent Teams template):
  - **Status** — pack v11.0+; per-surface opt-in; `gh` CLI + auth required.
  - **What it is** — one paragraph: the pack's flat-file BACKLOG/IMPLEMENTATION_PLAN/STATUS workflow can be mirrored to GitHub Issues; the mirror is bidirectional via reverse migration.
  - **When this matters for the Config Pack** — points at OQ-19 inflection signals (recommendation prompt; see `pack tracker enable-recommendations`).
  - **How to enable** — `pack tracker init` walkthrough: prereqs (`gh auth status`); the dialogue prompts; what gets written (`tracker.toml`, labels, forward migration); link to `MIGRATION-v10-to-v11.md` Phase B.
  - **How the pack's pieces work with it** — agent reads adapt automatically (D-9 LCD path); recommendation prompt fires at threshold; mirror files stay in repo for offline review.
  - **Caveats** — sidecar fields not bidirectional in raw issue body (template_version drift; see `MERGE-STRATEGY.md`); cross-machine refusal state does not survive (R16); `gh-sub-issue` extension optional.
  - **When to skip** — small projects under threshold; offline-only workflows; teams with their own tracker (note: TrackerProvider abstraction supports backends beyond GH; v11.0 ships GH only).
  - **How to disable** — `pack tracker disable` runs reverse migration; sidecar preserves tracker-only fields; flat files restored.
  - **Failure modes** — point at A1 UX in `MERGE-STRATEGY.md`; `pack tracker doctor` diagnoses; `restore-from-backup.sh` is the last resort.
- `QUICKSTART.md` (PACK-ROOT, modified — extends BD-090) — replace the brief tracker mention with a clean cross-reference: "Tracker integration is opt-in; see `OPTIONAL-FEATURES.md` § GitHub Issue Tracker."
- `supporting-docs/MIGRATION-v10-to-v11.md` (modified — extends BD-084) — Phase B section's "How to opt in" subsection cross-links to `OPTIONAL-FEATURES.md` § GitHub Issue Tracker as the canonical walkthrough; MIGRATION doc keeps the upgrade-context narrative but defers steps to OPTIONAL-FEATURES.
- `supporting-docs/DEPENDENCIES.md` (modified — see also BD-099) — gh CLI entry cross-links to `OPTIONAL-FEATURES.md`.
- `PACK-CHAT.md` and `project-template/docs/pack/PM-CHAT.md` (modified — extends BD-092) — add a one-line reference under the existing tracker-orchestration mention pointing at `OPTIONAL-FEATURES.md` § GitHub Issue Tracker.

**Description.** Base plan BD-092 sweeps cross-references and BD-090 mentions the tracker in QUICKSTART, but no single doc is the authoritative user-doc home for tracker enablement. `OPTIONAL-FEATURES.md` already has the right shape (the Agent Teams entry is the template). This BD elevates tracker enablement to that primary home and points the other docs at it. Net effect: a user reading any pack entry-point (QUICKSTART, MIGRATION, DEPENDENCIES) can reach the canonical tracker walkthrough in one hop.

**Blockers.** BD-092 (cross-reference sweep precedes the new authoritative section, so the sweep doesn't have to re-touch OPTIONAL-FEATURES); BD-073 (the verbs the section names); BD-066 (`pack tracker init`).

**Verification.**
- `OPTIONAL-FEATURES.md` § GitHub Issue Tracker section authored with all 8 sub-fields (matches Agent Teams template).
- validate-pack Check 22 (BD-082) — verbs named in OPTIONAL-FEATURES.md present in HELP-FRAGMENT.
- Manual cross-reference check: QUICKSTART, MIGRATION, DEPENDENCIES, PACK-CHAT, PM-CHAT each cite OPTIONAL-FEATURES § GitHub Issue Tracker.
- `grep -i "OT\|Optiquity" OPTIONAL-FEATURES.md` returns zero hits.

**Definition-of-Done.** Section authored; cross-references updated in 6 files; Check 22 green; CI passes.

---

### §1.6 BD-099 — `DEPENDENCIES.md` `gh` optional-dep pointer

**Title.** Add `gh` CLI entry to `DEPENDENCIES.md` Quick Reference table; cross-link to `OPTIONAL-FEATURES.md`

**Type.** TODO(version)

**Scope.** B

**Files.**
- `supporting-docs/DEPENDENCIES.md` (modified) — add a new entry under a new section `## CLI tools (optional, per-feature)`:
  - **`gh` CLI (optional — required only for tracker opt-in).** Used by `pack tracker init` and `migrate-v10-to-v11.sh` Phase B. Install: `brew install gh`. Verify: `gh auth status`. Reference: `OPTIONAL-FEATURES.md` § GitHub Issue Tracker.
  - **`gh-sub-issue` extension (optional — improves sub-issue UX).** Per V1 §2.7.3 extension policy. Install: `gh extension install yahsan2/gh-sub-issue`. Reference: `OPTIONAL-FEATURES.md` § GitHub Issue Tracker.
- Update the Quick Reference table at the bottom of DEPENDENCIES.md with one row: `gh CLI | Tracker opt-in (optional) | brew install gh`.

**Description.** Base plan does not mention DEPENDENCIES.md. The pack's GitHub-dependent features (BD-066 `pack tracker init`, BD-085 Phase B) need a visible install pointer where users actually look for tool requirements.

**Blockers.** BD-098 (the cross-link target must exist).

**Verification.**
- Manual: `gh` entry present; Quick Reference table row added; cross-link valid.
- `validate-pack.py` continues to pass.

**Definition-of-Done.** Entry authored; cross-link present; CI green.

---

### §1.7 BD-100 — Pack-implementation milestone checkpoints (3 strategic audits during v11)

**Title.** Three agent-driven audit checkpoints during v11 implementation; each gates the next phase

**Type.** TODO(version)

**Scope.** A

**Files.**
- `maintenance-docs/v11-implementation/CHECKPOINT-1-REPORT.md` (new — Scope-A backbone audit, after BD-068).
- `maintenance-docs/v11-implementation/CHECKPOINT-2-REPORT.md` (new — Scope-A surfaces audit, after BD-082).
- `maintenance-docs/v11-implementation/CHECKPOINT-3-REPORT.md` (new — Scope-B integration audit, after BD-085).
- `maintenance-docs/v11-implementation/CHECKPOINT-PROMPT-TEMPLATE.md` (new) — shared agent-prompt template the maintainer fills in for each checkpoint (context, output path, read-only, markdown-only, problem/goal/criteria, CLI command, chunked-write instruction).

**Description.** The base plan has CI per commit and one final validate-pack at release-pin. Missing: intermediate strategic audit passes that validate semantic correctness of accumulated work before progressing. BD-100 institutionalizes 3 such audits using the pack-reviewer agent.

**Checkpoint 1 — Scope-A backbone.** *When*: after BD-068 lands; before BD-069 begins. *Audit scope*: BD-060 through BD-068 (provider, config, forms, archive, errors, forward, init, reverse, round-trip).
- *Pass criteria*: round-trip-test.sh green AND `pack tracker init` round-trips on a sandbox AND error model produces all 9 typed codes correctly AND the audit report finds zero blockers.
- *Fail criteria*: any of the above false. *Action*: halt implementation; address findings (open follow-up BDs if needed); re-run checkpoint.

**Checkpoint 2 — Scope-A surfaces complete.** *When*: after BD-082 lands; before BD-083 begins. *Audit scope*: BD-069 through BD-082 (template_version, trinity Source column, agent reads, recommendation lib + verb + Step 8, pack-help script + fragments + per-CLI commands, init-project.sh extensions, trinity addenda, Checks 21–24).
- *Pass criteria*: all 7 recommendation tests green (V3 §28.1.10) AND validate-pack Checks 21–24 green AND eat-own-dog-food on the pack repo (run pack-startup; recommendation appears at threshold; refusal mechanism works) AND the audit report finds zero blockers.
- *Fail criteria*: any of the above false. *Action*: halt; address; re-run.

**Checkpoint 3 — Scope-B integrated.** *When*: after BD-085 lands; before BD-093 begins. *Audit scope*: BD-088 (customization-preserve), BD-091 (BD-042 relocation), BD-080 (init-project.sh), BD-085 (migrator), BD-094 (MERGE-STRATEGY), BD-095 (dry-run/apply), BD-096 (synthetic fixtures), and integration with Scope A.
- *Pass criteria*: all 5 BD-096 fixtures pass dry-run-then-apply with truthful reports AND validate-pack green on the pack repo AND BD-097 semantic audit pass green AND audit report finds zero blockers.
- *Fail criteria*: any of the above false. *Action*: halt; address; re-run.

Each checkpoint produces a markdown report at the named path. The report's structure mirrors the BD-097 semantic-audit-report shape (Summary, Findings, Disposition) but is narrower in scope.

**Blockers.** Per checkpoint: BD-068 (CP1); BD-082 (CP2); BD-085 (CP3).

**Verification.**
- Each report exists at its named path before the next phase begins.
- Each report's Pass criteria explicitly evaluated and marked.
- BD-097 semantic audit later reads each checkpoint report and confirms findings disposition.

**Definition-of-Done.** All three reports exist at v11.0 release pin; each marked pass; all blockers addressed; cited in CHANGELOG v11.0 entry as evidence of staged-audit discipline.

---

### §1.8 BD-101 — Client-migration validation gates (3 in-script gates with pass/fail)

**Title.** Three pass/fail gates inside `migrate-v10-to-v11.sh` (pre-migration / post-Phase-A / post-Phase-B); each gate is a script subroutine surfaced to the user

**Type.** TODO(version)

**Scope.** B

**Files.**
- `scripts/lib/migrate-v10-to-v11/gate-1-dry-run.sh` (new) — Gate 1 subroutine.
- `scripts/lib/migrate-v10-to-v11/gate-2-post-phase-a.sh` (new) — Gate 2 subroutine.
- `scripts/lib/migrate-v10-to-v11/gate-3-post-phase-b.sh` (new) — Gate 3 subroutine.
- `scripts/migrate-v10-to-v11.sh` (modified — extends BD-085 + BD-095) — wires each gate at the appropriate point in the migrator flow.
- `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (new) — manages `.pack-tracker/migrate-v10-to-v11.checkpoint.json` (gate state, last successful step) consumed by `--resume` (BD-095).
- `supporting-docs/MIGRATION-v10-to-v11.md` (modified — extends BD-084) — Section 4 (Phase A) and Section 5 (Phase B) document the three gates; user knows what to expect at each gate; rollback trigger documented.
- `scripts/tests/test-migrate-v10-to-v11-gates.sh` (new) — fixture tests for each gate's pass/fail cases.

**Description.** The base plan migrator (BD-085) has no explicit pass/fail gates; failures surface as raw script errors. BD-101 institutionalizes 3 gates as named subroutines, each with explicit pass/fail criteria, each surfaced to the user via the script's stdout.

**Gate 1 — Pre-migration dry-run.**
- *Trigger*: `migrate-v10-to-v11.sh --dry-run` (BD-095 mode).
- *Behavior*: enumerate every file the migrator would touch; every customization detected per BD-088 rules; every file class's chosen strategy; every projected `*.merge-conflict` outcome. Report at `.pack-tracker/migrate-v10-to-v11.dry-run-report.md` (per §2.4 schema).
- *Pass criteria*: report enumerates ≥ N files where N matches the file count in BD-088 customization-preserve coverage for the project's detected shape; user reviews and approves by running `--apply`.
- *Fail criteria*: user finds the report inaccurate (e.g., misses a customization the user knows exists); user aborts before `--apply`; files an issue against the pack with the report attached. **No state change** (read-only by definition).
- *Rollback*: not applicable — nothing was written.

**Gate 2 — Post-Phase-A.**
- *Trigger*: automatically at end of Phase A inside `--apply` flow.
- *Behavior*: run automatic verification: trinity addenda landed (3 pack-root files OR 6 client files, depends on surface detected via BD-075 `detect-surface.sh`); HELP-FRAGMENT files installed; `## Document locations` Source column added (project-template trinity only — D-6 footnote); relocated docs at correct paths (BD-091); client-side `validate-pack.py`-equivalent passes.
- *Pass criteria*: all checks green; script writes `gate_2_passed: true` to `.pack-tracker/migrate-v10-to-v11.checkpoint.json`; script proceeds to ask user about Phase B opt-in.
- *Fail criteria*: any check fails. *Action*: script halts; emits `*.merge-conflict` files where applicable (A1 UX); points user at `MERGE-STRATEGY.md`; user options: (a) resolve conflicts → `--resume`; (b) restore via `restore-from-backup.sh`; (c) file an issue.
- *Rollback trigger*: user invokes `restore-from-backup.sh` manually; script does not auto-rollback.

**Gate 3 — Post-Phase-B (only if user opted in to tracker).**
- *Trigger*: automatically at end of Phase B (after `pack tracker init` completes within the migrator flow, or after `pack tracker init` is run separately and the user re-runs `migrate-v10-to-v11.sh --post-tracker-verify`).
- *Behavior*: run automatic verification: forward migration completed (mapping file populated); mirror files fresh (timestamps post-init); `pack tracker doctor` (BD-066) reports green.
- *Pass criteria*: all green; script reports successful upgrade; writes `gate_3_passed: true` to checkpoint; success report at `.pack-tracker/migrate-v10-to-v11.success-report.md`.
- *Fail criteria*: `pack tracker doctor` reports inconsistency; mapping integrity broken; mirror files stale.
- *Rollback trigger*: user runs `pack tracker disable` to revert tracker opt-in (Phase A changes remain since they're separate); files an issue with the doctor output attached.

**Blockers.** BD-085 (the migrator); BD-095 (the dry-run/apply/resume CLI surface); BD-088 (customization-preserve algorithm); BD-091 (BD-042 relocation); BD-094 (MERGE-STRATEGY for the A1 escape hatch); BD-066 (`pack tracker doctor` for Gate 3).

**Verification.**
- `test-migrate-v10-to-v11-gates.sh` covers each gate's pass and fail paths against the BD-096 fixtures.
- BD-097 semantic audit confirms gate behavior matches the prose in `MIGRATION-v10-to-v11.md`.
- Manual smoke: run dry-run on the pack repo's own working tree; observe Gate 1 report; apply; observe Gate 2 result; opt in to tracker on a sandbox; observe Gate 3 result.

**Definition-of-Done.** Three gate subroutines exist; integrated with `migrate-v10-to-v11.sh`; checkpoint file managed; test green; documented in MIGRATION doc.

---

## §2. `MERGE-STRATEGY.md` content spec (authored under BD-094)

The doc is shape-agnostic, ~300–500 lines, and uses generic file paths and patterns. Its top-level structure:

### §2.1 Per-file matrix (authoritative)

A markdown table with columns: **File class** | **Path pattern** | **Primary strategy** | **A1 fallback trigger** | **Reference**.

Rows (drawn from BD-088 file list, generalized):

- Trinity files (pack-root + client-side): `(project-template/)?(CLAUDE|AGENTS|GEMINI)\.md` — 3-way merge (pack-template-old / project-current / pack-template-new) — fallback when 3-way conflicts cannot auto-resolve in non-marker prose blocks — V1 §A.2 + BD-088.
- `.claude/settings.json`: allowlist-merge via `merge-json.py` (pack-managed keys overwritten; project keys preserved) — fallback when the same key has divergent values in pack and project — BD-088.
- `.codex/config.toml`: allowlist-merge via `merge-toml.py` (pack-managed sections overwritten; project sections preserved including intentional removals) — fallback on schema-incompatible diffs — BD-088.
- `.gemini/.env`: line-level merge with project-set env preserved — fallback on collision with new pack-set defaults — BD-088.
- `.mcp.json.example`, `.codex/config.toml.example`: same allowlist pattern — fallback as above.
- `docs/pack/PM-CHAT.md` (or relocated client copy): marker-section convention (preserve `### Project-specific` blocks) with diff-recognition fallback (when no markers, inspect for project-name customizations and known-role additions) — fallback when neither marker nor diff-recognition succeeds — BD-088.
- `scripts/*` (project-added): preserve unconditionally; only update pack-shipped scripts by name — fallback unused (preservation is unconditional).
- `.claude/agents/x-*.md`, `.codex/agents/x-*.md`, `.gemini/agents/x-*.md`: preserve unconditionally (`x-` prefix is the project-custom allowlist) — fallback unused.
- `.claude/skills/x-*/`, `.codex/skills/x-*/`, `.gemini/commands/x-*.toml`: preserve unconditionally — fallback unused.
- HELP-FRAGMENT files (canonical + mirror): pack-managed; project does not customize these. Migrator overwrites; if user has customized, A1 trigger — emit `*.merge-conflict`.
- `tracker.toml` (when present): allowlist-merge; pack-managed keys (schema_version) updated; user keys (backend.repo, id_namespace) preserved — fallback on schema break.

### §2.2 Strategy descriptions (one paragraph each)

- **3-way merge.** Walk the diff between `pack-template-old` (the pack version this client is upgrading from, sourced from the templates archive) and `pack-template-new` (the v11.0 version being installed). Apply the diff to `project-current` (the client's working file). Conflicts arise when the diff touches a region the project has also touched. On conflict, A1.
- **Allowlist-merge (JSON / TOML).** A list of pack-managed keys / sections is applied; everything else is preserved. `merge-json.py` and `merge-toml.py` (existing scripts) implement the mechanic. On schema break (e.g., type-incompatible value at the same key), A1.
- **Marker-section convention.** Pack-shipped files include explicit markers (e.g., `<!-- PROJECT-CUSTOM-START --> ... <!-- PROJECT-CUSTOM-END -->`) the migrator preserves verbatim. Project content outside markers is replaced. On missing markers, fall back to diff-recognition.
- **Diff-recognition fallback.** When markers are absent, the migrator computes a diff between the file and the pack-template-old; preserved regions are heuristic-detected. On ambiguous diffs, A1.
- **Unconditional preserve (`x-*` allowlist).** Files matching the `x-` prefix in agent / skill / command directories are project-custom by convention; the migrator never touches them.

### §2.3 A1 failure-mode UX (the consistent escape hatch)

When any auto-resolution strategy cannot succeed:

1. **Migrator stops** at the failing file; does not partially-apply.
2. **Migrator emits** a `<original-path>.merge-conflict` file containing standard 3-way merge markers (`<<<<<<< pack-template-new`, `=======`, `>>>>>>> project-current`) with annotations identifying the strategy that failed.
3. **Migrator writes** a checkpoint to `.pack-tracker/migrate-v10-to-v11.checkpoint.json` recording the last successful step and the failing file.
4. **Migrator surfaces** an actionable error per the typed-error model (BD-070): error code, diagnostic, next-step verb (`→ Run: scripts/migrate-v10-to-v11.sh --resume`).
5. **User resolves** the `*.merge-conflict` file manually: edits the file, removes conflict markers, validates the result, then creates a `<original-path>.resolved` flag-file (or removes the `.merge-conflict` extension — both shapes accepted by `--resume`).
6. **User re-runs** `scripts/migrate-v10-to-v11.sh --resume`. The migrator verifies all `*.merge-conflict` files are resolved (no remaining markers; flag-file present), reads the checkpoint, and continues from the last successful step.
7. **`--resume` is forward-only** (per BD-095): if the user wants to start over, they delete the checkpoint and re-run `--dry-run`.

### §2.4 Dry-run report shape (consumed by BD-101 Gate 1)

```
# Migration dry-run report
Generated: <ISO 8601 timestamp>
Migrator: scripts/migrate-v10-to-v11.sh --dry-run
Working-tree fingerprint: <sha256>
Source pack version: <detected from sentinel>
Target pack version: v11.0

## Summary
- Files to touch: N
- Customizations detected: M
- Strategies invoked: <count by strategy>
- Projected conflicts: K (each enumerated below)

## Per-file plan
| Path | Class | Strategy | Customization detected | Projected outcome |
|------|-------|----------|------------------------|-------------------|
| ... |

## Projected conflicts (A1 triggers)
<one block per projected conflict; empty if none>

## Files preserved unconditionally
<x-* allowlist matches>

## Next steps
- If the report is accurate: scripts/migrate-v10-to-v11.sh --apply
- If the report is inaccurate: do not run --apply; file an issue with this report attached.
```

The fingerprint binds the report to a specific working-tree state; `--apply` rejects stale reports (BD-095 precondition).

### §2.5 Multi-project + earlier-than-v10 notes (cross-link section)

Two short notes:
- **Multi-project**: tracker opt-in is per-project (no cross-project state); upgrades can be done in any order. (One sentence; cross-link to `MIGRATION-v10-to-v11.md`.)
- **Earlier than v10**: this migrator expects v10. If you are on v9 or earlier, run `migrate-v9-to-v10.sh` first to reach v10, then run this migrator. (One paragraph; cross-link to `supporting-docs/MIGRATION-v9-to-v10.md`. No automation; no chained runner.)

---

## §3. Updates to base plan

### §3.1 §3.3 commit-order integration (insertions)

The base plan §3.3 is a 34-step sequence. The addendum inserts BD-094..BD-101 at the following positions (existing steps not renumbered; insertions named with letters):

- **After step 19 (BD-088 customization-preserve library), insert step 19a: BD-094 — `MERGE-STRATEGY.md`.** (Authoring depends on BD-088 file rules existing.)
- **After step 20 (BD-091 relocation), insert step 20a: BD-096 — synthetic-fixture set.** (Fixtures populate before the migrator that consumes them.)
- **After step 22 (BD-085 migrate-v10-to-v11.sh), insert step 22a: BD-095 — dry-run/apply/resume modes.** (Extends BD-085.)
- **After step 22a (BD-095), insert step 22b: BD-101 — three validation gates.** (Wires gates into BD-095 modes.)
- **After step 30 (BD-084 MIGRATION doc), insert step 30a: BD-098 — `OPTIONAL-FEATURES.md` tracker walkthrough.** (Cross-references the MIGRATION doc.)
- **After step 30a, insert step 30b: BD-099 — DEPENDENCIES.md `gh` pointer.** (Cross-links to OPTIONAL-FEATURES.)
- **BD-100 (3 checkpoints) lands non-sequentially**: CP1 between steps 9 and 10 (after BD-068, before BD-069); CP2 between steps 24 and 28 (after BD-082, before BD-083); CP3 between steps 22b and 29 (after BD-085 + BD-095 + BD-101, before BD-092). Each checkpoint is a maintainer-driven audit, not a code commit; the report file lands but no implementation code changes in that step.
- **BD-097 (pre-release semantic audit) lands as new step 33a**, between step 33 (BD-087 CHANGELOG) and step 34 (BD-093 release pin).

Updated tail of §3.3 (illustrative; full edit lands when this addendum is approved):

```
... 19. BD-088
    19a. BD-094 — MERGE-STRATEGY.md
20. BD-091
    20a. BD-096 — synthetic fixtures
21. BD-080
22. BD-085
    22a. BD-095 — dry-run/apply/resume
    22b. BD-101 — validation gates
[CP3 audit — BD-100 report]
23. BD-081
... 30. BD-084
    30a. BD-098 — OPTIONAL-FEATURES tracker section
    30b. BD-099 — DEPENDENCIES gh pointer
31. BD-090
32. BD-086
33. BD-087
    33a. BD-097 — semantic audit
34. BD-093
```

CI green at every numbered + lettered boundary (same rule as base plan).

### §3.2 §7 release-readiness checklist additions

Append to the existing `## §7. Definition of v11.0 release-readiness` checklist:

- [ ] `supporting-docs/MERGE-STRATEGY.md` authored; per-file matrix covers every BD-088 file class; A1 UX documented.
- [ ] `migrate-v10-to-v11.sh --dry-run` / `--apply` / `--resume` modes verified against all 5 BD-096 fixtures.
- [ ] BD-096 synthetic fixtures: 5 trees present (lightly-customized, heavily-customized, language-heterogeneous, custom-agents-heavy, OT-modeled); `test-customization-preserve.sh` exercises all 5 with golden reports.
- [ ] BD-097 pre-release semantic audit: `SEMANTIC-AUDIT-REPORT.md` exists; pass per criteria (zero blockers; warnings dispositioned).
- [ ] BD-098 `OPTIONAL-FEATURES.md` § GitHub Issue Tracker authored; cross-referenced from QUICKSTART, MIGRATION, DEPENDENCIES, PACK-CHAT, PM-CHAT.
- [ ] BD-099 DEPENDENCIES.md `gh` entry + Quick Reference row added; cross-link valid.
- [ ] BD-100 three checkpoint reports (CHECKPOINT-1/2/3-REPORT.md) exist; each pass per criteria.
- [ ] BD-101 three gates (Gate 1 dry-run; Gate 2 post-Phase-A; Gate 3 post-Phase-B) wired into migrator; `test-migrate-v10-to-v11-gates.sh` green; documented in MIGRATION doc.
- [ ] General-use audit: `grep -ri "OT\|Optiquity" QUICKSTART.md OPTIONAL-FEATURES.md supporting-docs/MIGRATION-v10-to-v11.md supporting-docs/MERGE-STRATEGY.md` returns zero hits in user-facing prose (provenance notes in fixture READMEs allowed).

### §3.3 §6 MAINTAINER CHECK NEEDED additions

Append to §6 of the base plan:

- **§6.G — Dry-run report freshness window for `--apply` precondition (BD-095).** The addendum specifies a 24-hour freshness window between dry-run and apply. Options:
  - (a) 24-hour window (proposed).
  - (b) Tie to working-tree fingerprint only — no time window; any fingerprint match is accepted regardless of age.
  - (c) Configurable via `tracker.toml`.
  - **Recommendation: (a) with fingerprint check.** 24 h is friendly to "review overnight, apply tomorrow" workflows; fingerprint guarantees safety on stale reports even within window. Maintainer confirms at BD-095 land-time.

- **§6.H — `--resume` resolved-flag detection mechanism (BD-095 + BD-094 §2.3).** The addendum allows two equivalent shapes for marking a `*.merge-conflict` resolved: companion `.resolved` flag-file OR removal of the `.merge-conflict` extension. Options:
  - (a) Accept both shapes (proposed; lower friction).
  - (b) Require companion `.resolved` flag-file only (simpler script; user friction).
  - (c) Require extension removal only (most natural for git-aware users; some users may prefer the explicit flag).
  - **Recommendation: (a)** — match user mental models; explicit checks in `--resume` for both shapes. Maintainer confirms at BD-095 land-time.

- **§6.I — BD-097 audit invocation: pack-reviewer vs ad-hoc.** The base plan does not commit a `pack-reviewer` agent in v11; pack agents are referenced via `claude --agent pack-<name>` (per pack-agent invocation reference). Options:
  - (a) Invoke an existing pack agent (e.g., `pack-reviewer` if present; otherwise `pack-architect`).
  - (b) Run the audit as an ad-hoc Claude Code session with the prompt at `SEMANTIC-AUDIT-PROMPT.md`.
  - (c) Add a new `pack-reviewer` agent in v11 (out of scope for this addendum; would require a separate BD).
  - **Recommendation: (b) for v11.0; revisit (a) or (c) in v11.1+.** The session prompt is the contract; the agent identity is incidental for v11.0. Maintainer confirms at BD-097 land-time.

---

## §4. Earlier-than-v10 + multi-project notes

These two text fragments belong in `supporting-docs/MIGRATION-v10-to-v11.md` (BD-084 authored content; cross-linked from `MERGE-STRATEGY.md` §2.5):

**Earlier-than-v10 path (one paragraph, in §3 "Before you start"):**

> This migrator expects your project to be on v10 (any v10.x). If you are on v9 or earlier, run `scripts/migrate-v9-to-v10.sh` first to reach v10, then run `scripts/migrate-v10-to-v11.sh`. The two migrators are independent: each backs up before writing; each produces its own report; rollback is per-migrator. Earlier-than-v10 chained automation is intentionally not provided — version-by-version migration is more reviewable and lets you commit per upgrade.

**Multi-project guidance (one sentence, in §5 "Phase B"):**

> Tracker opt-in is per-project: there is no cross-project state, so multi-project clients can opt in independently and in any order.

No fan-out into other docs; no chained-runner script; no automation BD.

---

## §5. Verification additions to base plan §4

The base plan §4 verification strategy is preserved. Additions:

### §5.1 New entries in §4.1 per-BD test plan summary

| BD | Test mechanism |
|---|---|
| BD-094 | Manual review against §2 spec; grep for OT/Optiquity (zero hits) |
| BD-095 | `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (7 cases) |
| BD-096 | `scripts/tests/test-customization-preserve.sh` extended; 5 fixtures with golden reports |
| BD-097 | Audit report exists; zero blockers; warnings dispositioned |
| BD-098 | Manual review against Agent Teams template shape; Check 22 |
| BD-099 | Manual; cross-link valid |
| BD-100 | 3 checkpoint reports exist; each marked pass |
| BD-101 | `scripts/tests/test-migrate-v10-to-v11-gates.sh` |

### §5.2 New §4.3 fixtures

Append to base plan §4.3 (existing fixtures retained):

- `scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/` (BD-096).
- `scripts/tests/fixtures/customization-preserve/heavily-customized/` (BD-096).
- `scripts/tests/fixtures/customization-preserve/language-heterogeneous/` (BD-096).
- `scripts/tests/fixtures/customization-preserve/custom-agents-heavy/` (BD-096).
- `scripts/tests/fixtures/migrate-v10-to-v11/dry-run-stale-report/` (BD-095 fail case).
- `scripts/tests/fixtures/migrate-v10-to-v11/resume-unresolved-conflict/` (BD-095 fail case).

### §5.3 New §4.4 CI gates

Append to the CI workflow runner (extends BD-083):

9. `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (BD-095).
10. `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` (BD-101).
11. `bash scripts/tests/test-customization-preserve.sh` (extended fixture set; BD-096).

### §5.4 Audit-pass discipline (BD-100 + BD-097)

Three checkpoint reports + one pre-release semantic audit produce 4 markdown audit artifacts before BD-093 release pin. Each artifact is referenced from CHANGELOG v11.0 entry as evidence that staged-audit discipline was followed. Failure of any audit halts implementation; address findings; re-run audit; only proceed when all audits green.

---

**End of addendum.**
