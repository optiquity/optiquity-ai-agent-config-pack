# RESEARCH — Tracker-Deferral Blast-Radius Census (BD-214)

**Author:** pack-docs-researcher (fresh spawn). **Date:** 2026-06-12.
**Purpose:** exhaustive census of EVERY tracker-related artifact in the repo,
feeding the BD-214 architect pass (keep-dormant vs block vs delete line).
**Read-only:** this report is the only file written.

## 0. Method, provenance, and primary reconciliation

**HEAD provenance.** Census began at HEAD `cf599a2deb4ad6082b0225b61ad6f13bad9ea634`
with a dirty tree (M: backlog/BD-094.md, BD-204.md, BD-207.md, _toc.md; ??:
BD-214.md, BD-215.md). Mid-census the parent session committed exactly those 6
files as `0027b106789e09bad2d7cdb380c8c499d7d0f747` ("docs: v11 — tracker
deferred indefinitely; BD-204/BD-207 deferred, BD-214 cleanup + BD-215
format-redesign opened"). Verified: `git diff --name-status cf599a2..0027b10`
= exactly those 6 paths (3 M + 2 A + _toc M). All measurements below were taken
against the working tree, which is byte-identical to `0027b10`; the tree is now
clean. **No git-state-changing verb was run by this census** (only status / log
/ diff / show / ls-files / rev-parse / check-ignore).

**Primary sweep.** Case-insensitive token `tracker`, whole tree, `.git` excluded.

> EE-0a — whole-tree totals
> Cmd: `grep -ric 'tracker' . --exclude-dir=.git | awk -F: '$2>0' | wc -l` and sum.
> Output: `767` files, `16757` occurrences. HEAD cf599a2 (tree == 0027b10).
> Conclusion: SUPPORTED.

**Reconciliation way 1 — per-directory sums vs whole-tree:**

| Surface | Files w/ hits | Occurrences |
|---|---|---|
| `backlog/` | 79 | 324 |
| `changelog/` | 2 | 23 |
| `scripts/` | 99 | 3,315 |
| `project-template/` | 25 | 178 |
| `maintenance-docs/` | 526 | 12,580 |
| `supporting-docs/` | 3 | 46 |
| `pack-ops/` | 10 | 96 |
| `.claude/` | 4 | 18 |
| `.codex/` | 4 | 18 |
| `.gemini/` | 3 | 17 |
| `.github/` | 1 | 35 |
| `test-fixtures/` | 4 | 27 |
| Root files: README 13, QUICKSTART 1, tracker.toml.pack-example 20, .gitignore 7, CLAUDE 13, AGENTS 13, GEMINI 13 | 7 | 80 |
| **Sum** | **767** | **16,757** |

Arithmetic: dirs = 324+23+3315+178+12580+46+96+18+18+17+35+27 = 16,677;
+ root 80 = **16,757 = whole-tree total (exact)**. Files: 760 + 7 = **767 (exact)**.
The initial per-dir pass missed QUICKSTART.md (1) and tracker.toml.pack-example
(20) at root; the gap (21 occ / 2 files) was hunted down and closed exactly.

**Reconciliation way 2 — filename-based vs content-based:**

> EE-0b — Cmd: `find . -name '*tracker*' -not -path './.git/*' | sort`
> Output: 61 paths (19 `scripts/lib/tracker-*.sh`, `scripts/pack-tracker.sh`,
> `scripts/tracker-migrate.sh`, 21 tracker-named test files, 6 tracker fixture
> dirs + their `tracker.toml` files, `tracker.toml.pack-example`,
> `project-template/tracker.toml.project-example`, 4 `test-fixtures/` tracker
> paths incl. the gitignored `v11-tracker-on/`). Every tracker-NAMED file also
> appears in the content sweep (each contains the token) — no filename-only
> artifact escapes the content sweep. Conclusion: SUPPORTED.

**Reconciliation way 3 — maintenance-docs name-based split:**
`find maintenance-docs -iname '*BD-204*'` = 92; `*MODE3*` = 16; `*TRACKER*` = 3;
`*BD-207*` = 0. Combined pattern find = 107. Overlap check: 92+16+3 = 111;
the 4 `*BD-204-MODE3-OPS-CONTRACT*` files match both patterns; 111 − 4 = **107
(exact match with the combined find)**.

**Surface tags used below:** PACK (pack repo ops/state), PROJ (client-shipped
`project-template/` + `supporting-docs/`), COMBINED (one mechanism spanning
both), USER (user-facing read/run surface). **Disposition vocabulary
(PRELIMINARY — architect decides):** KEEP (not tracker cruft), KEEP-DORMANT
(retain code/doc, block activation), BLOCK (flip-block target), UPDATE
(surface-sweep rewording: stop presenting tracker as usable), DELETE?
(candidate deletion — architect), BD-215 (format-redesign scope, NOT BD-214),
USER (user decision per BD-214 scope 5). `ARCH?` flags genuine uncertainty.

---

## 1. Axis A — Entry content (`/backlog/`, `/changelog/`)

**Inventory:** 215 `BD-NNN.md` files + `_rules.md`/`_intro.md`/`_toc.md` in
`/backlog/`; 11 `vN.md` + same 3 support files in `/changelog/`.

> EE-1a — machine artifacts (blobs/markers) in entry content
> Cmd: `grep -rln 'pack-entry-body-gz64\|pack-extra-fields' backlog/ changelog/`
> Output: `backlog/BD-204.md`, `backlog/_rules.md` — BOTH are PROSE mentions
> (BD-204's LOSSLESS-FIX paragraph; _rules.md contract text), NOT literal blobs.
> Cmd: `grep -rn 'gz64\|base64' backlog/ changelog/` → 5 files, all prose:
> BD-204 (3), BD-207 (1), BD-214 (2), BD-215 (2), _rules.md (2).
> Conclusion: SUPPORTED — **ZERO literal gz64/base64 blobs exist in committed
> entry content.** The blob carrier lived only in GH Issue bodies + local caches
> (deleted 2026-06-12), never in the committed tree.

> EE-1b — HTML comments in entry content
> Cmd: `grep -rn '<!--' backlog/ changelog/ | grep -v 'per-entry source:'`
> Output: per-entry source headers = 215 files (backlog) + 11 (changelog) —
> BD-203 flat-file format's own header, **NOT tracker cruft**. Remaining
> `<!--` hits are: `_toc.md` generated-by banners (×2, format-own); inline-code
> PROSE examples of markers in BD-103/BD-065/BD-212/_rules (`<!-- pack-id: -->`
> quoted as code spans) and BD-136/BD-069 (project-owned-section /
> template_version markers — unrelated to tracker). Conclusion: SUPPORTED —
> **ZERO tracker-purpose HTML comment markers exist as actual markers in
> entry content.**

**Per-entry `tracker` prose hits:** 76 of 215 BD files + `_rules.md` (23) +
`_intro.md` (1) + `_toc.md` (24, all derived title text — regenerates) = 79
files / 324 occ (reconciles with §0 table). Top: BD-204 (21), BD-185 (15),
BD-215 (10), BD-207 (9), BD-214 (8), BD-194 (8), BD-123 (7), BD-135 (7),
BD-111 (7), BD-212 (7); remaining 66 files ≤ 5 each (full per-file list
reproducible via `grep -ric tracker backlog/`).

| Artifact class | Count | Surface | Prelim. disposition |
|---|---|---|---|
| Literal gz64/base64 blobs in entries | **0** | PACK | n/a — nothing to strip (verify with the same grep as the BD-214 grep-zero gate) |
| Tracker-purpose HTML markers in entries | **0** | PACK | n/a — same |
| `<!-- per-entry source: ... -->` headers | 215 + 11 | PACK | KEEP — BD-203 flat-file format's own header |
| `backlog/_rules.md` tracker-mode sections (§ SSOT mode-dependent, § tracker-mode write authority, gz64 contract refs; 23 occ, ~70 lines) | 1 file | PACK | UPDATE — rewrite to flat-file-only with tracker-deferred note (ARCH? exact wording) |
| `changelog/_rules.md` mode-invariance § (4 occ) | 1 file | PACK | UPDATE |
| `backlog/_intro.md` tracker-mode pointer (1 occ) | 1 file | PACK | UPDATE |
| Resolved/Deprecated entries describing tracker work (BD-060..BD-135 era + others; ~60 files) | ~60 files | PACK | KEEP — immutable history of resolved work; not cruft |
| Live tracker BDs: BD-204, BD-207, BD-215 (Deferred), BD-214 (Open) | 4 files | PACK | KEEP — already re-scoped by the 2026-06-12 commit 0027b10 |
| OPEN tracker BDs needing re-disposition (see §10) | 4+ files | PACK | USER/ARCH? — Track-2 re-baseline items |

**BD-214 note:** the entry-cleanup grep-zero gate over "gz64/base64 blobs +
tracker-purpose HTML comments" is ALREADY satisfied in committed entry content;
the real axis-A work is the `_rules.md`/`_intro.md` mode-section rewrite and
the open-BD re-dispositions.

---

## 2. Axis B — Code

> EE-2a — Cmd: `wc -l scripts/pack-tracker.sh scripts/tracker-migrate.sh scripts/lib/tracker-*.sh scripts/lib/recommendation.sh`
> Output: 21 files, **13,053 lines** (verbatim per-file below). HEAD cf599a2.
> Conclusion: SUPPORTED.

**Dedicated tracker code (PACK-side, none shipped to clients):**

| File | Lines | `tracker` occ | Role | Prelim. disposition |
|---|---|---|---|---|
| scripts/pack-tracker.sh | 824 | 113 | `pack tracker` verb dispatcher (init/status/tree-rebuild/edit/new-entry/mirror-rebuild/disable/doctor/reset/update-templates/enable-recommendations) | KEEP-DORMANT + **BLOCK** the `init`/opt-in verb (deferred message) |
| scripts/tracker-migrate.sh | 200 | 33 | low-level forward/reverse wrapper | KEEP-DORMANT |
| scripts/lib/tracker-provider.sh | 142 | 52 | TrackerProvider abstraction (BD-060) | KEEP-DORMANT (BD-214 scope 3 names it well-designed) |
| scripts/lib/tracker-provider-gh.sh | 974 | 104 | gh backend | KEEP-DORMANT |
| scripts/lib/tracker-migrate-forward.sh | 2,549 | 116 | forward migrator (gz64 composer) | KEEP-DORMANT |
| scripts/lib/tracker-migrate-reverse.sh | 1,798 | 106 | reverse migrator (gz64 decoder) | KEEP-DORMANT |
| scripts/lib/tracker-config.sh | 333 | 75 | tracker.toml reader; `tracker_mode()` three-part test | KEEP-DORMANT — **BLOCK point candidate** (mode detection is the activation seam) ARCH? |
| scripts/lib/tracker-init.sh | 447 | 67 | opt-in/init path | **BLOCK** (refuse with deferred message) |
| scripts/lib/tracker-edit.sh | 567 | 87 | Mode-3 edit verbs (H2 projection + blob recompose) | KEEP-DORMANT |
| scripts/lib/tracker-doctor.sh | 411 | 66 | coherence doctor | KEEP-DORMANT |
| scripts/lib/tracker-labels.sh | 246 | 31 | pack-managed label set | KEEP-DORMANT |
| scripts/lib/tracker-errors.sh | 124 | 19 | typed error mapping | KEEP-DORMANT |
| scripts/lib/tracker-agent-read.sh | 336 | 46 | mode-agnostic agent read path | KEEP-DORMANT (flat-file branch is live? ARCH? — verify call sites) |
| scripts/lib/tracker-mirror.sh | 105 | 13 | mirror generation | KEEP-DORMANT |
| scripts/lib/tracker-header-snapshot.sh | 324 | 35 | header snapshot (BD-207 scope says BD-207 deletes it later) | KEEP-DORMANT (deletion anchored in BD-207) |
| scripts/lib/tracker-sidecar.sh | 377 | 21 | sidecar carrier (same BD-207 deletion anchor) | KEEP-DORMANT |
| scripts/lib/tracker-phase-task.sh | 617 | 23 | phase/task entities (D-21) | KEEP-DORMANT |
| scripts/lib/tracker-cycle-check.sh | 386 | 51 | Blockers-cycle check | KEEP-DORMANT — NOTE: BD-204's 2026-06-12 note re-anchors a tree-level validate-pack Blockers-cycle check to Track-2 execution; this lib is its natural seed (ARCH?) |
| scripts/lib/tracker-links.sh | 366 | 54 | blocked-by link orchestration (gh-sub-issue) | KEEP-DORMANT |
| scripts/lib/tracker-promote.sh | 1,381 | 178 | TD promotion paths (V3.3 §3) | KEEP-DORMANT |
| scripts/lib/recommendation.sh | 546 | 19 | D-19 inflection-point recommendation system (pack-startup/pm-startup Step 8) | **BLOCK** the tracker-opt-in recommendation (BD-214 scope 2 names D-19 explicitly); lib itself KEEP-DORMANT |

**Tracker-touching shared code (not dedicated):**

| File | occ | What | Surface | Prelim. |
|---|---|---|---|---|
| scripts/pack-td.sh (51) | 51 | `pack td` promote/resolve verbs — routes through tracker-promote.sh in tracker mode; flat-file paths exist | PACK | KEEP; UPDATE tracker-mode prose/paths (ARCH? — split live flat-file behavior from dormant tracker branch). Carries the BD-204-noted `Resolution: n/a` advisory-typo |
| scripts/pack-help.sh (30) | 30 | inlines HELP-FRAGMENT-TRACKER.md into help output (pack + client roots) | COMBINED/USER | UPDATE — help must stop advertising tracker as usable (fragment content change; mechanism can stay) |
| scripts/init-project.sh (22) | 22 | S11 installs `docs/pack/HELP-FRAGMENT-TRACKER.md` + `tracker.toml.example` to CLIENTS (install-map lines 1248-1250, 1405, 1419) | PROJ/USER | **BLOCK/UPDATE** — this is the project-side flip-enabling install path; architect decides install-vs-skip vs install-deferred-stub |
| scripts/migrate-v10-to-v11.sh (17) + scripts/lib/migrate-v10-to-v11/{checkpoint.sh 35, gate-3-phase-b-verify.sh 27, gate-2 1, apply.sh 1} | 81 | v10→v11 migrator emits/validates client tracker artifacts (Phase B) | PROJ/USER | UPDATE (ARCH? — migration of existing v10 clients must still produce a coherent v11 tree without advertising tracker) |
| scripts/lib/detect.sh (5), scripts/lib/template-version.sh (11), scripts/lib/template-translations.sh (6), scripts/lib/migrator-core.sh (3), scripts/lib/migrator-stages.sh (12), scripts/lib/per-entry/decompose.sh (1, comment), scripts/persona-contracts/contract-{greenfield 6, migration 5}.sh, scripts/test-migrator-manifest.sh (10), scripts/test-migrator-core.sh (4), scripts/test-detect.sh (8) | 71 | incidental tracker references (file lists, version maps, comments) | PACK | KEEP; UPDATE only where prose presents tracker as usable (mostly mechanical refs) |
| project-template/scripts/* | **0** | — | PROJ | n/a — **zero tracker code ships in client scripts** (EE: `grep -ric tracker project-template/scripts/` → all 0) |

---

## 3. Axis C — Validators + CI

> EE-3a — Cmd: python split of `scripts/validate-pack.py` (47 `def check_` total;
> 138 `tracker` occ file-wide) listing functions whose body mentions tracker.
> Output (function: occ): check_help_fragment_freshness 15, check_help_fragment_completeness 8,
> check_customization_detection_regression_guard 2, check_pm_startup_per_cli_parity 6,
> _validate_tracker_toml 14, _check_mirror_staleness 6, check_tracker_config 31,
> check_recommendation_state_schema 3, _list_unknown_files 1, check_mirror_in_sync 1,
> check_tracker_phase_task_invariants 17, _read_boundary_exempt_root 1,
> check_commit_scope_honesty 4, check_project_side_deny_list 2,
> check_pack_only_file_siting 1, check_cmd_update_symmetry 7, check_bare_pack_ops_refs 8,
> _build_pack_only_doc_basenames 2, check_project_side_bare_internal_refs 1,
> check_boundary_and_spawn_pointer_manifests 2, check_removed_doc_advisory 7, main 5.
> Conclusion: SUPPORTED.

| Check | Function | Tracker-awareness | Prelim. |
|---|---|---|---|
| 29 (BD-078) | check_tracker_config + _validate_tracker_toml + _check_mirror_staleness | validates tracker.toml EXAMPLES schema + mirror staleness | KEEP-DORMANT/UPDATE — examples stay only if the example files stay (ARCH?) |
| 30 (BD-079) | check_recommendation_state_schema | D-19 state JSON schema | follows the D-19 disposition |
| 32′ (BD-203) | check_mirror_in_sync | no-monolith guard; 1 tracker mention | KEEP — flat-file infrastructure, not tracker cruft |
| 35 (BD-106) | check_tracker_phase_task_invariants | phase-task lib invariants | KEEP-DORMANT (guards dormant lib health) |
| 49 (BD-204 §4.2/§4.6) | migrator field/body faithfulness — **gated: runs ONLY under `PACK_VALIDATE_DEEP=1`** (line 7656-7657: SKIP otherwise) | exercises gz64 codec on the REAL tree | KEEP-DORMANT or RETIRE — ARCH? (it asserts the migrator stays correct for resumption; costs nothing un-gated) |
| 50 (BD-204 §4.5) | check_validate_pack_no_reproduced_codec | single-source codec guard | same ARCH? as 49 |
| unnumbered (BD-063) | check_issue_template_forms (line 1202) | GH issue form family shape | KEEP if inbound feedback channel stays (see §7) ARCH? |
| 22/23 (BD-082) | help-fragment freshness/completeness | asserts HELP-FRAGMENT-TRACKER content/byte-identity rules | UPDATE in lock-step with fragment edits (enumerate-encoding-surfaces) |
| 25, 28, 36, 37, 38, 39, 40, 43, 46, 48 + helpers | various | incidental tracker refs (file lists, allowlists, e.g. tracker.toml.pack-example in boundary-exempt) | KEEP; mechanical updates where file sets change |

**CI workflow:** `.github/workflows/validate-pack.yml` (only workflow; 35
tracker mentions) wires **16 tracker test steps** (lines 122-157: provider,
config, init, agent-read, migrate-fwd/rev/roundtrip, phase-task, links,
cycle-check, errors, config-schema; lines 209-223: bd129/130/132/133/134
regression suites) plus recommendation tests. Check 42 (BD-184) enforces that
per-check test files stay wired — pruning a test step requires the
Check-42-aware edit. Prelim.: KEEP-DORMANT tests running green (keeps dormant
code healthy for resumption) — ARCH? confirms.

---

## 4. Axis D — Tests + fixtures

> EE-4a — Cmd: `wc -l scripts/tests/tracker-*.sh scripts/tests/test-tracker-*.sh scripts/tests/recommendation-*.sh scripts/tests/test-issue-forms.sh scripts/tests/test-validate-pack-check-49*.sh`
> Output: **25 files, 15,334 lines** (largest: tracker-migrate-forward-test.sh
> 2,295; tracker-provider-test.sh 1,607; tracker-migrate-reverse-test.sh 1,447).
> `ls scripts/tests | grep -c '\.sh$'` = 52 total test files. No `*check-50*`
> test file exists (Check 50 has no dedicated per-check test — flag). HEAD cf599a2.
> Conclusion: SUPPORTED.

| Class | Files | Lines | Surface | Prelim. |
|---|---|---|---|---|
| tracker-named unit/regression tests | 21 | 13,448 | PACK | KEEP-DORMANT, stay CI-green (ARCH?) |
| recommendation tests (recommendation-test.sh 371, recommendation-state-schema-test.sh 252) | 2 | 623 | PACK | follows D-19 disposition |
| test-issue-forms.sh | 1 | 296 | PACK | follows form-family disposition (§7) |
| test-validate-pack-check-49-field-faithfulness.sh | 1 | 567 | PACK | follows Check 49 |
| tracker-touching other tests: pack-help-test.sh (33 occ), test-migrate-v10-to-v11-gates.sh (26), recommendation refs in test-init-project.sh (14), test-validate-pack-check-40.sh (14), template-translations-test.sh (11), test-v11-realistic-ot.sh (0 — clean), others ≤ 8 | ~8 | — | PACK | UPDATE in lock-step with surface edits (enumerate-encoding-surfaces; remember the BD-203 lesson: integration tests pin validator OUTPUT) |
| scripts/tests/fixtures/: tracker-config/ (6 toml), tracker-migrate/, tracker-provider/ (stub-backend.sh 24 occ + 2 json), tracker-promote/, tracker-phase-task/, tracker-links/, tracker-bd204-lossless/, roundtrip/bd-v11.0+v11.1, plus tracker-mentioning fixtures under bare-cross-refs/ + boundary-checks/ | ~25 files | — | PACK | KEEP-DORMANT with their tests |
| test-fixtures/v11-tracker-on/ (synthesized client w/ tracker.toml + .pack-tracker/id-map.json) | gitignored | — | PACK (local) | KEEP-DORMANT — EE: `git check-ignore test-fixtures/v11-tracker-on/tracker.toml` → IGNORED; not committed. Synthesis code lives in test-fixtures/build.sh (17 occ) + manifest.txt line 9 (`v11-tracker-on <sha>`); build.sh UPDATE follows architect line |

---

## 5. Axis E — Operating docs (PACK/PM chats + agents)

| Surface | occ | What | Prelim. |
|---|---|---|---|
| Root trinity CLAUDE.md / AGENTS.md / GEMINI.md | 13 each | § Repo conventions "Per-entry trees — sole SSOT" bullet (CLAUDE lines 476-501: full Mode-2/Mode-3 contract) + § Project goals v11 ("tracker is opt-in but easy", lines 587-588) | UPDATE — trinity-parallel edit; the goals bullet contradicts the deferral outright |
| pack-ops/PACK-CHAT.md | 20 | § Backlog write paths by mode (Mode-3 operations) lines 53-114 + D-19 tracker-recommendation behavior lines 288-307 | UPDATE |
| pack-ops/PACK-AGENTS.md | **0** | — | n/a (EE: grep -c = 0) |
| pack-ops/.spawn-rule-manifest.txt | **0** | — | n/a |
| pack-ops/PACK-MEMORY-RATIONALE.md | 3 | rationale entries referencing tracker | UPDATE (mechanical) |
| pack-ops/BOUNDARY-DEFINITION.md | 2 | boundary prose | UPDATE/KEEP (mechanical) |
| pack-ops/.boundary-exempt-root.txt | 1 | line 5: `tracker.toml.pack-example` exempt | follows the example-file disposition |
| backlog/_rules.md (23) + changelog/_rules.md (4) + backlog/_intro.md (1) | 28 | mode contracts (§1) | UPDATE |
| Agent definitions .claude/agents/, .codex/, .gemini/ + project-template agents | **0** | — | n/a (EE: grep across all = 0 hits) |
| Skills — pack-startup SKILL.md (.claude 12, .codex 12) + .gemini/commands/pack-startup.toml (12) | 36 | **Step 8 = D-19 tracker-opt-in recommendation** (lines 73-117: tracker-mode detection, recommendation_state at .pack-tracker/, "suggest `pack tracker init`") + Step 7 reserved for tracker triage | **BLOCK** — BD-214 scope 2 names this explicitly |
| Skills — pm-startup (project-side analog): project-template/{.claude,.codex,skills}/pm-startup/SKILL.md (13 each) + .gemini/commands/pm-startup.toml (13) | 52 | client Step 8 analog | **BLOCK** (project analog, same scope item) |
| Skills — boundary-investigation (4 × 3 CLIs, pack) + project-template/skills/boundary-investigation (4) | 16 | tracker as worked example in boundary prose | UPDATE/KEEP (mechanical mentions) ARCH? |
| Skills — documentation (1 × 3 + project 1), pack-help SKILL (1 × .claude/.codex + project 1×2) | ~7 | incidental | KEEP/UPDATE mechanical |

---

## 6. Axis F — User-facing surfaces

| Surface | occ / size | What | Prelim. |
|---|---|---|---|
| pack-ops/HELP-FRAGMENT-TRACKER.md | 22 occ / 53 lines | pack-side help fragment — whole file is tracker | UPDATE (deferred wording) or DELETE? — ARCH?; Checks 22/23 + pack-help-test.sh pin its content |
| project-template/docs/pack/HELP-FRAGMENT-TRACKER.md | 18 occ / 49 lines | project-side authoritative copy (BD-193 F4/F5); installed to clients by init S11 | same as above, project flavor |
| pack-ops/HELP-FRAGMENT-PACK.md (5) + project HELP-FRAGMENT.md (2) | 7 | `pack tracker` verb rows + fragment-include sentinel | UPDATE |
| pack-ops/OPTIONAL-FEATURES.md §"Tracker integration (v11)" (24 occ, §125) + project-template/docs/pack/OPTIONAL-FEATURES.md (16 occ, §110) | 40 | the opt-in walkthrough | UPDATE — primary "tracker is usable" advertisement |
| project-template/docs/pack/PM-CHAT.md | 19 | client PM-chat D-19 recommendation behavior (lines 512-531) + tracker-mode read/write paths (591-884) | UPDATE/BLOCK (client analog of PACK-CHAT) |
| README.md | 13 | version-table v11.0 row (tracker feature description), layout rows for tracker files (107, 138, 197-215, 255-271) | UPDATE — version-table row is PM-chat-only authority |
| QUICKSTART.md | 1 | line 43 pointer to tracker opt-in | UPDATE |
| supporting-docs/DEPENDENCIES.md | 11 | gh CLI + gh-sub-issue rows/sections marked "required for v11 tracker opt-in" (lines 129-162) | UPDATE — mark deferred (deps stay documented for the dormant code) |
| supporting-docs/MIGRATION-v10-to-v11.md | 34 | Phase B tracker opt-in migration steps | UPDATE |
| supporting-docs/METHODOLOGY.md | 1 | incidental | UPDATE/KEEP |
| project-template/docs/pack/prompts/{reviewer 3, pm-chat 3, coder 3, auditor 2, tester 2} | 13 | trinity-resolver phrasing "flat-file mode reads X; tracker mode reads the tracker" | UPDATE (mechanical, repeated phrase) |
| project-template/docs/project/{backlog,implementation-plan,changelog}/_intro.md (5 each) | 15 | client stream-mode descriptions | UPDATE. NOTE: client `_rules.md` files have **0** tracker refs (EE: grep -c = 0 ×3) — client mode prose lives in _intro only |
| changelog/v11.md | 19 | v11.0 release notes describing the tracker feature (D-1..D-23, BD rows) | KEEP as history vs UPDATE the unreleased v11.0 block — ARCH?/USER (v11.0 is unlaunched; the release text currently advertises a feature that won't ship usable) |
| pack-ops/MERGE-STRATEGY.md (10), pack-ops/DRY-RUN-MIGRATION.md (2), pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md (7) | 19 | per-file matrix rows + walkthrough mentions | UPDATE (mechanical rows for tracker files) |
| .mcp.json.example (root + project) | 0 | — | n/a |

---

## 7. Axis G — Config + repo plumbing

| Artifact | Evidence | Prelim. |
|---|---|---|
| .gitignore lines 9-17: `.pack-tracker/` + `/tracker.toml` (root-anchored, BD-061/BD-204 comments) | EE: grep -n = 7 occ | **KEEP** — this IS the BD-214 scope-6 guard against local-state recreation |
| project-template/.gitignore lines 7-10: `.pack-tracker/` | 3 occ | KEEP (same guard, client side) |
| tracker.toml.pack-example (root, committed, 88 lines, 20 occ) | wc -l | KEEP-DORMANT vs DELETE? — ARCH? It is the pack-side opt-in template; boundary-exempt line 5 + Check 29 + README row follow it |
| project-template/tracker.toml.project-example (75 lines, 15 occ) | wc -l | same ARCH?; init-project S11 installs it as client `tracker.toml.example` — the flip-block decision controls whether the install ships |
| .github/ISSUE_TEMPLATE/ — work-item.yml (105), inbound.yml (76), config.yml (9) = 190 lines | ls/wc | SPLIT: inbound.yml = feedback channel that works in flat-file mode (per backlog/_rules.md: "inbound-feedback issues are a human/PM triage channel only" in flat-file) → KEEP; work-item.yml = tracker-entry intake (BD-204 LOCKED form family) → KEEP-DORMANT/ARCH? |
| project-template/.github/ISSUE_TEMPLATE/ — work-item.yml (187), inbound.yml (77), config.yml (12) = 276 lines | ls/wc | same split, client side; checked by check_issue_template_forms + test-issue-forms.sh |
| Local state `tracker.toml` + `.pack-tracker/` at repo root | EE: `ls tracker.toml .pack-tracker` → both "No such file or directory" | CONFIRMED deleted (2026-06-12); .gitignore keeps them un-recreatable-by-commit |

---

## 8. Axis H — Maintenance docs (historical records)

> EE-8a — per-subdir 'tracker' totals (files-with-hits / total files; occ):
> archive/v10-working 1/25 (2); archive/v11 150/211 (2,025);
> v11-implementation 312/425 (8,247); v11-research 62/71 (2,305).
> Sum = 525 files / 12,579 occ + 1 file / 1 occ elsewhere under maintenance-docs
> root-level docs = 526 / 12,580 (matches §0 table). Conclusion: SUPPORTED.

**Tracker-core docs (name-based): 107 files** — 92 `*BD-204*` + 16 `*MODE3*` +
3 `*TRACKER*` (RESEARCH-TRACKER-LANDSCAPE-RULES.md,
IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md,
RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md) − 4 overlap; 0 `*BD-207*`.
Plus the BD-204-entry-named DESIGN BASELINE set living under v11-research/
(DESIGN-BRIEF.md, ARCHITECTURE-V3.md, V3.1/V3.3 deltas, ARCHITECTURE.md, etc.).

Prelim.: **KEEP as history — flag for architect.** Tension to resolve: the
fail-loud memory (`feedback_fail_loud_delete_old_source`) says DELETE
superseded docs, but BD-204 names several of these as the LOCKED resumption
baseline and BD-215 names the GH-rules + tracker-landscape censuses as
provider-constraint inputs. Deleting the baseline contradicts
keep-for-future-resumption; the architect should partition
resumption-baseline (KEEP) vs churn-era working reports (DELETE?-candidates).
A PRE-LAUNCH maintenance-docs delete-cleanup BD anchor already exists in pack
memory (`project_pack_self_migration_launch_gate`).

---

## 9. Axis I — External GH state (read-only census; NOTHING touched)

> EE-9a — Cmds (read-only): `gh api 'search/issues?q=repo:DShaneNYC/optiquity-ai-agent-config-pack+type:issue'`
> → total_count **213**; `+state:open` → **41**; `+state:closed` → **172**;
> `+label:bd-entry` → **213** (every issue carries the bd-entry lane label).
> `gh label list --limit 200` → **58 labels**, of which **49** carry description
> "v11 pack-managed label" (status:* ×10, type:* ×7+, scope:*, lane labels
> bd-entry/td-entry/phase-epic/phase-task/work-item/external/inbound/
> pack-feedback/needs-triage, derived-from:TD-031/TD-040,
> promoted-to:phase-7/phase-3.4) + 9 GitHub defaults. Date 2026-06-12.
> Conclusion: SUPPORTED.

| External artifact | Count | Prelim. |
|---|---|---|
| GH Issues (inert; flat-file tooling ignores them) | 213 (41 open / 172 closed; all bd-entry) | USER decision per BD-214 scope 5 — PAT has no delete; close/archive vocabulary only |
| Pack-managed labels | 49 | USER/ARCH? — rides the issues disposition |
| Live issue forms (rendered from committed .github/ISSUE_TEMPLATE) | 3 | follows §7 form-family split |
| Local-state backups | /tmp (per user memory; id-map reconstructible from labels) | out of repo; note only |

---

## 10. Discovered axis — OPEN tracker-adjacent BDs (re-disposition rows for Track-2 restart)

| BD | Status | Title evidence | Why it's a census row |
|---|---|---|---|
| BD-212 | Open | "`pack tracker reset` verb + 3-level recovery (pack side…)" | pure tracker scope; candidate Deferred-with-BD-204 (USER) |
| BD-213 | Open | "`pack tracker reset` + 3-level recovery, project-side…" | same, project side (USER) |
| BD-185 | Open | "Phase parts hierarchy + tracker-mode execution ordering" (15 occ) | v11.1-scoped; tracker-mode portion needs re-scope (USER) |
| BD-188 | Open | "Phase-Iteration sprint view (single all-phases tracker Project…)" | tracker-Project dependent; parking-lot (USER) |
| BD-154 | Deferred | tracker mention | verify mention is incidental |
| BD-100/102/105/110/136/171/172/174 | Open | incidental tracker mentions (≤ 4 each; e.g., BD-105 "STATUS.md phase-row dual-link rendering (tracker mode)") | sweep each for tracker-mode clauses during Track-2 re-baseline |

---

## 11. Secondary token families (whole tree, files / occurrences)

> EE-11 — Cmd loop: `grep -rl "$t" . --exclude-dir=.git | wc -l` + occ sum. HEAD cf599a2.

| Token | Files | Occ | Concentration outside maintenance-docs |
|---|---|---|---|
| `gz64` | 62 | 551 | 18 files: 5 backlog prose (§1), validate-pack.py (10), pack-tracker.sh (2), 3 lib, 7 tests/fixtures — all in §§2-4 rows |
| `pack-id` | 142 | 493 | code/tests + prose examples; no live marker in entries (§1) |
| `.pack-tracker` | 168 | 683 | 30 non-maintenance files — all captured in §§2-7 rows (gitignores, examples, skills, PACK-CHAT, PM-CHAT, build.sh, code, tests, MIGRATION doc, changelog/v11, 8 backlog prose) |
| `tracker.toml` | 330 | 1,899 | examples, code, tests, docs — captured above |
| `pack tracker ` (verb) | 219 | 926 | help/docs/skills/code — captured above |
| `needs-triage` | 39 | 100 | 16 non-maintenance: issue forms ×4, pm/pack-startup ×7, PACK-CHAT, tracker-labels.sh, 2 tests, BD-204 |
| `TrackerProvider` | 49 | 87 | abstraction name — code + README + BD entries |
| `provider_` | 150 | 1,493 | provider op surface — code/tests |
| `recommendation` | 418 | 1,801 | D-19 system + generic English uses (the token over-matches; D-19-specific artifacts are the §2/§4/§5 rows) |

---

## 12. The BD-214 vs BD-215 line (as applied above)

- **BD-214 (now):** flip-block (init paths, D-19 Step 8 both sides, init-project
  S11 installs), surface sweep (§§5-6 UPDATE rows), validator/test lock-step
  edits, GH-issues disposition (USER), local-state guard (KEEP .gitignore),
  open-BD re-dispositions (§10), `_rules.md`/`_intro.md` mode-section rewrite.
- **BD-215 (future, NOT now):** any change to entry FORMAT (field sets, header
  comment scheme, body shape), any re-author of entry content, any removal of
  the blob/HTML-comment MACHINERY's reason-to-exist. §1 shows entry content
  needs NO blob/marker stripping — so nothing in axis A bleeds into BD-215
  except the format-redesign itself.
- **Explicitly neither:** deleting dormant tracker code wholesale (out of
  BD-214 scope per the entry); BD-204/BD-207 resumption.

## 13. Completeness self-check

1. **Token coverage:** primary sweep is case-insensitive `tracker` — catches
   Tracker/TRACKER/tracker.toml/pack-tracker/TrackerProvider. Artifacts named
   WITHOUT the token were hunted via secondary families (§11: gz64, pack-id,
   .pack-tracker, needs-triage, provider_, recommendation, pack-id) and
   filename sweep (§0 way 2). Residual risk: a tracker-purpose artifact using
   NONE of these tokens (e.g., a generic helper only called by tracker code).
   Mitigation: the 21 dedicated files' `source` graphs are enumerable by the
   architect from §2; per-entry/ hooks checked (1 comment hit only).
2. **Binary/hidden files:** sweep included dotfiles (.github, .gitignore,
   .boundary-exempt-root.txt, .spawn-rule-manifest.txt all checked). `.git/`
   internals excluded by design (history is not a cleanup surface).
3. **Uncommitted state:** baseline dirty files were committed mid-census as
   0027b10 with byte-identical content; no other working-tree drift
   (`git status --short` clean at census end).
4. **External:** GH issues/labels/forms enumerated read-only; /tmp backups
   noted from user memory (out of repo, not independently verified — flagged,
   not guessed).
5. **vscode-companion-templates/ + xcode-companion-templates/ + LICENSE.md +
   maintenance-docs root docs:** zero `tracker` hits except 1 occ inside
   maintenance-docs tree counted in §8 (whole-tree total closes exactly, so
   no top-level surface holds uncounted hits).
6. **Axes not in the prompt that were added:** §10 open-BD re-disposition rows;
   the mid-census external commit provenance; Check-50-has-no-test gap;
   client `_rules.md` zero-hit finding (mode prose is in `_intro.md` instead).

## 14. Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| Agents never commit | Command history contains only `git rev-parse / status / log / diff / show / ls-files / check-ignore / branch --show-current`. The mid-census commit `0027b10` was made by the parent session (subject "docs: v11 — tracker deferred indefinitely…"), not this agent; proven by `git diff --name-status cf599a2..0027b10` = exactly the 6 files already dirty at this agent's baseline snapshot before any census work ran. | COMPLIANT |
| Read-only mandate | Baseline `git status --short` = ` M backlog/BD-094.md, M BD-204.md, M BD-207.md, M _toc.md, ?? BD-214.md, ?? BD-215.md`; end-of-census `git status --short` = clean (delta = the parent's commit of those same 6 files, not an edit by this agent). Only write performed: this report file (untracked, the sanctioned deliverable). | COMPLIANT |
| Researcher maps the blast radius exhaustively | §0: whole-tree 767/16,757 reconciled against per-directory sums to the file and occurrence (16,677+80=16,757; 760+7=767) after closing a 21-occ gap; way 2 filename-vs-content (61 paths all content-matched); way 3 maintenance-docs name-split (92+16+3−4=107 = combined find). Every non-maintenance hit file appears in a §§1-7 row; maintenance-docs censused at subdir + name-core granularity (§8). | COMPLIANT |
| Empirical-Evidence Blocks | EE-0a/0b, EE-1a/1b, EE-2a, EE-3a, EE-4a, EE-8a, EE-9a, EE-11 each carry command, verbatim counts/output, HEAD SHA (cf599a2, tree == 0027b10) or date, interpretation, and SUPPORTED conclusion. | COMPLIANT |
| Rules-Applied Verification Block | This table; per-rule quoted evidence; no empty cells. | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: census complete; report about to Write to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/RESEARCH-TRACKER-DEFERRAL-CENSUS.md` in the chat turn immediately before this file was written. No stop message was received at any point. | COMPLIANT |
| Mandatory read-in-full list | Read via Read tool, complete files: CLAUDE.md (591 lines incl. all of ## Pack memory), project_tracker_deferred_indefinitely.md (61 lines), backlog/BD-214.md (15), BD-215.md (16), BD-204.md (37), BD-207.md (19), backlog/_rules.md (152), changelog/_rules.md (77); plus the three named skills (documentation, dependency-intake, commit-discipline SKILL.md, complete). | COMPLIANT |
