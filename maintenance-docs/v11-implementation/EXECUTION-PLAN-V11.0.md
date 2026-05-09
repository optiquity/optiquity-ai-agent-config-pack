# EXECUTION PLAN — v11.0 launch

**Owner:** v11-dev pack chat (this chat).
**Status:** Drafted 2026-05-09. Awaiting user review before any commits.
**Scope:** Sequence and govern all remaining work to land v11.0 — including
tracker-defect repairs surfaced by the BD-102 Phase A dog-food run, CI
test-suite repair, validation audits, the cross-pack rename, and the
final release pin.
**Source of authority:** This doc is strategy/sequencing. `BACKLOG.md` is
canonical for individual BD detail. When the two disagree, BACKLOG.md
wins; update this doc to match.

---

## 1. In-scope inventory for v11.0

**Total: 40 BDs in-scope** (33 tracked at session start + 7 new opened
during planning) + 1 BD to verify-and-close (BD-059) + 4 untracked
items folded into BDs.

### 1.1 Group 1 — original launch-critical (12 BDs)

Active scope inherited from the v11-dev session-scope hand-off plus the
release-pin endpoint.

- **BD-122** — Document `test-fixtures/` `<vN>-<persona>` versioning convention
- **BD-123** — Relocate `tracker.toml.example` (**disposition pending** — see §6)
- **BD-125** — `dry-run-migration.sh` input contract + usage doc
- **BD-120** — Parameterize realistic-OT fixture generator for any vN
- **BD-116** — Persona contract assertions (template-derived expected output)
- **BD-117** — `RELEASE-GATE.md` per-major-version checklist
- **BD-118** — CI wiring for persona contracts + fixture verification
- **BD-114** — `dry-run-migration.sh` parameterized read-only migration harness (status-flip; work shipped)
- **BD-121** — Sunset v9 migration infrastructure (status-flip; bulk shipped in `1daa938`)
- **BD-124** — Pack-coder skills (status-flip; work shipped)
- **BD-102** — Pack-repo dog-food migration (final v11 validation)
- **BD-093** — v11.0 release pin (tag, README, CHANGELOG, MIGRATION cross-link) — **the final-final step**

### 1.2 Group 2 — pulled in from "decide later" (7 BDs)

User decision 2026-05-09: all in for v11.0.

- **BD-095** — `migrate-v10-to-v11.sh` two-phase `--dry-run`/`--apply`/`--resume` workflow
- **BD-101** — Client-migration validation gates (3 in-script gates with pass/fail)
- **BD-100** — Pack-implementation milestone checkpoints (3 strategic audits — at minimum the v11.0 final audit)
- **BD-104** — Cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`
- **BD-112** — Three-way diff filename mangling collision fix
- **BD-078** — validate-pack.py Check (`check_tracker_config`)
- **BD-079** — validate-pack.py Check (recommendation-state schema)

### 1.3 Group 3 — pulled forward from "defer to v11.1" (14 BDs)

User decision 2026-05-09: tracker-related and validation-related items
pulled in for v11.0; non-tracker / non-validation moved to Group 4.

**Tracker (8):**
- **BD-103** — `pack tracker reset` verb + 3-level recovery documentation
- **BD-105** — STATUS.md phase-row dual-link rendering (tracker mode)
- **BD-106** — Phase task entity model + identifier scheme + parser/emitter
- **BD-107** — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close)
- **BD-108** — Cross-entity dependency link orchestration + cycle check + gate-check extension
- **BD-109** — Project-side `auditor-issue-tracking` sub-agent
- **BD-110** — Pack-side `pack-auditor` agent
- **BD-111** — Switch blocks/blocked-by from comment-marker to first-class GH dependency API

**Validation (5):**
- **BD-032** — Validate auditor observability infrastructure vs. configuration boundary
- **BD-033** — Validate auditor systemic error handling threshold
- **BD-034** — Validate auditor-ui scope breadth after ops split
- **BD-035** — Validate python-architecture skill loading for non-server Python
- **BD-048** — Capability-addition discovery + install-check symmetry with kickoff

**Test infrastructure (1):**
- **BD-096** — Synthetic-fixture set (general-use coverage; OT is one example)

### 1.4 New BDs opened during this planning (7 BDs)

Drafted in §2 below; ready to paste into BACKLOG.md once user approves.

- **BD-128** — CI test-suite repair (init-project Group 3 + v10-realistic-ot fixture build + migrator collateral)
- **BD-129** — Tracker libs pass `--repo` to all gh invocations (D-1)
- **BD-130** — Wire `tracker_doctor_run` so `pack tracker doctor` works (D-2; BD-067 fix incomplete)
- **BD-131** — Set `forward_complete = true` at end of clean forward migration (D-4)
- **BD-132** — **BLOCKER** — eliminate disable/init close-step race that silently drops ~33% of BACKLOG entries (D-5)
- **BD-133** — Reverse migration preserves BACKLOG.md header preamble byte-identical (D-6)
- **BD-134** — Forward close retry-with-backoff to eliminate ~5% partial-write rate (D-7; NIT)

### 1.5 Verify-then-close (1 BD; likely no new work)

- **BD-059** — v10 customization-preservation. Almost certainly closed by BD-088. Pack Chat verifies BD-088 closed it; flips status; adds Resolved note pointing to BD-088 commits. If verification surfaces residual gaps, opens fix-follow BD.

### 1.6 Group 4 — deferred to v11.1+ (5 BDs, NOT in v11.0)

For reference. Do NOT touch in this plan.

- BD-020 — C++ server support analysis
- BD-036 — IDE and editor coverage gaps
- BD-037 — Platform update cycle observability
- BD-039 — Prototype / speed mode
- BD-040 — Fully autonomous execution mode

---

## 2. New BD entries (ready to paste into BACKLOG.md)

When approved, Pack Chat inserts these into BACKLOG.md `## Active — v11 Scope`
section per the pack convention (newest at top of section). Each is `Status: Open`
on creation. All seven land in a single BACKLOG hygiene commit (Batch 5 below).

```markdown
**BD-134 — Tracker forward close retry-with-backoff (eliminate ~5% partial-write rate)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-7)
Status: Open
Blockers: none
Unblocks: cleaner BD-102 dog-food re-run; reduced post-init `gh issue` state drift
File/Symbol: `scripts/lib/tracker-provider-gh.sh` (close call); `scripts/lib/tracker-migrate-forward.sh` (end-of-init re-run-failed-closes step)
Description: Forward step-8 close has ~5% partial-write rate (3 of 56 named close failures observed: BD-021/022/023). Likely transient gh API rate-limiting. Add retry-with-backoff on individual close, OR end-of-init pass that re-runs failed closes once before reporting partial-write. Severity NIT — issues end up OPEN with `status:resolved` label instead of CLOSED.
Resolved: n/a

---

**BD-133 — Reverse migration preserves BACKLOG.md header preamble**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-6)
Status: Open
Blockers: none
Unblocks: BD-102 dog-food (Phase A round-trip survives without content loss)
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh` BACKLOG emission; `scripts/lib/tracker-migrate-forward.sh` checkpoint snapshot OR `scripts/lib/tracker-sidecar.sh` header preservation
Description: Reverse migration strips ALL non-entry content from BACKLOG.md — the `# Backlog` title, "All planned improvements..." paragraph, `## How to use this file` section, type explanations, format references — replacing it with bare `# BACKLOG`. Per V1 §6.5 design intent project-specific content not representable in tracker should be sidecar-preserved; this header content qualifies. Reverse must preserve everything before the first `**BD-NNN — ...**` heading byte-identical, via checkpoint snapshot, sidecar, or refusal-to-overwrite policy after first round-trip. Test fixture required.
Resolved: n/a

---

**BD-132 — BLOCKER: tracker disable/init close-step race destroys ~33% of BACKLOG entries**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-5)
Status: Open
Blockers: none
Unblocks: BD-102 dog-food (Phase A); v11.0 ship gate (silent data loss is unacceptable)
File/Symbol: `scripts/lib/tracker-migrate-reverse.sh` reconstruct loop; `scripts/pack-tracker.sh` init/disable race detection; `scripts/lib/tracker-migrate-forward.sh` close-stabilization wait
Description: First `disable` invocation immediately after `init` exit reconstructed only 60 of 93 BD entries — 33 entries silently dropped. Hypothesis: `gh issue close` is eventually consistent; `disable` running mid-close sees inconsistent issue state and silently skips entries whose body or labels appear malformed mid-update. Workaround was poll `gh issue list --state closed --limit 200 --json number --jq length` until stable, then disable. Three-part fix required: (a) `init` waits for all close ops to stabilize before exit, (b) `disable` detects "init still racing" via `forward.checkpoint.json` freshness OR issue-state stability poll, (c) reverse loop's silent-skip path must at minimum WARN ("skipping X issues whose body did not parse — re-run"). Severity effective CRITICAL: a user who runs `init` then immediately `disable` (smoke test, change of mind) loses 35% of BACKLOG content with no warning. **BLOCKER for v11.0.**
Resolved: n/a

---

**BD-131 — Set `forward_complete = true` at end of clean forward migration**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-4)
Status: Open
Blockers: none
Unblocks: correct `tracker_mode()` resolution (V1 §3.2); downstream tooling routes to tracker behavior reliably
File/Symbol: `scripts/lib/tracker-migrate-forward.sh` (or wherever final tracker.toml `[migration]` write happens); `scripts/lib/tracker-init.sh` if init owns the post-forward write
Description: After `pack tracker init --backend github --repo ... --no-interactive` succeeded (created tracker.toml, wrote 93 issues, wrote id-map.json + forward.checkpoint.json, closed 53 of 56 attempted closes), the `tracker.toml [migration]` section reads `forward_complete = false`. Per V1 §3.2 `tracker_mode()` resolves to "tracker" only when `mode.state = "tracker"` AND `migration.forward_complete = true`. Downstream tooling depending on `tracker_mode()` may incorrectly route to flat-file behavior. Fix: set `forward_complete = true` at end of clean forward. For partial-write cases (BD-134's 3-of-56 failure pattern), document semantics — does `forward_complete` mean "all closes succeeded" or "all issues created"? Recommend the latter since BD-134's fix will eliminate the close-failure case anyway.
Resolved: n/a

---

**BD-130 — Wire `tracker_doctor_run` so `pack tracker doctor` works (BD-067 fix incomplete)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-2; live regression confirmed at HEAD `240867d`)
Status: Open
Blockers: none
Unblocks: BD-102 dog-food (operator can actually run `pack tracker doctor`); BD-097 audit accuracy (NOTE N-5 said all four verbs implemented — was wrong for `doctor`)
File/Symbol: `scripts/pack-tracker.sh` (sources scripts/lib/* but never `scripts/tracker-migrate.sh` where `tracker_doctor_run` is defined at line 167); options to fix: (a) move `tracker_doctor_run` from `scripts/tracker-migrate.sh` into `scripts/lib/tracker-*.sh` and source it; (b) have `pack-tracker.sh` source `scripts/tracker-migrate.sh`; (c) duplicate the function (rejected — DRY)
Description: BD-067 Resolved-line claims `pack tracker doctor` was wired. Live test on HEAD `240867d`: `bash scripts/pack-tracker.sh doctor` returns `scripts/pack-tracker.sh: line 165: tracker_doctor_run: command not found`. Function is defined in `scripts/tracker-migrate.sh:167` but `scripts/pack-tracker.sh` only sources `scripts/lib/*.sh` files (verified — see lines 29-53 of pack-tracker.sh). Recommended fix (a): relocate to `scripts/lib/tracker-doctor.sh` (or fold into existing `scripts/lib/tracker-init.sh` since init/doctor are sibling concerns) and add a source line in pack-tracker.sh.
Resolved: n/a

---

**BD-129 — Tracker libs pass `--repo` to all gh invocations (don't depend on git remote)**
Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-1)
Status: Open
Blockers: none
Unblocks: tracker init works for repos with non-GitHub remotes, internal mirrors, GHE-on-different-host, freshly-cloned repos before remote setup, monorepo subtree imports
File/Symbol: `scripts/lib/tracker-labels.sh:172` (`_tracker_labels_existing`), `scripts/lib/tracker-labels.sh:183` (`_tracker_labels_create`), every `_gh_run gh ...` call in `scripts/lib/tracker-provider-gh.sh` that doesn't pass `--repo`. Slug source: `scripts/lib/tracker-config.sh::tracker_repo_slug`.
Description: All gh invocations in tracker libs run without `--repo`. gh resolves slug from working repo's git remote — fails with "none of the git remotes configured for this repository point to a known GitHub host" for clones from local-path sources, non-GitHub remotes, or freshly-cloned repos. `pack tracker init` then aborts at `labels_ensure: cannot read existing labels (gh auth or network failure)` — misleading error. Fix: pass `--repo "$slug"` everywhere (slug already available via `tracker_repo_slug`); OR set `GH_REPO` env in dispatcher before any gh call (cleaner — single point of control). Recommend the env-var approach: set once in `scripts/pack-tracker.sh` cmd dispatcher, applies to every gh call below it.
Resolved: n/a

---

**BD-128 — CI test-suite repair: BD-080 Group 3 + v10-realistic-ot fixture + migrator collateral**
Type: TODO(version) — surfaced by current CI baseline (red on every push since v10.1 backport landed)
Status: Open
Blockers: none — but should land BEFORE BD-102 dog-food
Unblocks: green CI on `validate-pack.yml`; BD-102 dog-food run can rely on test-suite signal
File/Symbol: `scripts/tests/test-init-project.sh` (Group 3: 13 FAILs hunting for `S11 — v11 client artifacts`, `tracker.toml.example`, `pack-help.sh`, `detect.sh` post-BD-088/BD-119/BD-121); `test-fixtures/build.sh` (exit 31 building `v10-realistic-ot` — likely v10 tag unreachable in CI checkout OR builder needs BD-120 parameterization first); `scripts/test-migrator-behavior-preservation.sh` (collateral failure on missing fixture); possibly `.github/workflows/validate-pack.yml` (verify checkout fetches tags)
Description: CI `tests` job has been red since `19755b5` (v10.1 backport optimization pass). Three failing suites: (1) BD-080 init-project Group 3 — assertions reference v11 client artifacts in paths that BD-088/BD-119/BD-121 reorganized; either update assertions OR fix install paths. (2) `test-fixtures/build.sh --all --clean` exit 31 building `v10-realistic-ot` from the v10 git tag — checkout depth or tag-fetching issue in CI, OR builder needs BD-120 parameterization. (3) BD-119 migrator behavior-preservation — depends on fixture from #2. Triage and repair each. May spawn fix-follow BDs if any failure surfaces a deeper issue. **NOTE on sequencing:** if BD-128 repair turns out to require BD-120 (fixture parameterization), batch ordering must move BD-120 ahead of BD-128. Pre-flight check is the first task.
Resolved: n/a
```

---

## 3. Cleanup status (no-action items)

- **`v10-maintenance` worktree directory** — DONE. Removed prior to this session. `git worktree list` from main clone shows main + v11-dev only. Branch `v10-maintenance` still exists locally and on origin (expected per original instruction).
- **`v10-dev` branch** — exists locally and on origin. Untouched per separate concern.
- **`/tmp/bd-102-dogfood-defect-handoff.md`** — ephemeral hand-off doc. After v11-dev chat (this chat) confirms BD entries opened, main pack chat will delete `DOG-FOOD-MIGRATION-REPORT.md` from the main worktree per the hand-off protocol.

---

## 4. Batch plan (23 batches)

Sequencing rationale up front:
- Batches 1–4 are the original Tier B + C scope (small, fast).
- Batch 5 stops the BACKLOG from claiming work is open that's already done AND opens the 7 new BDs in one hygiene commit.
- Batch 6 (CI repair) gates everything else — until CI is green, dog-food and release pin can't fire confidently.
- Batches 7–10 land the tracker stability fixes (BD-129 through BD-134) before any tracker entity-model expansions or auditor agents (Batches 17–20).
- Batches 11–16 are pre-release small wins, the cross-pack rename, and Group 2 / Group 3 implementation work.
- Batches 17–20 add the tracker entity model and auditor agents on top of stable tracker.
- Batches 21–23 close out: final audit → dog-food → release pin.

| Batch | Mode | BDs | Files (high-level) | Conflict notes |
|---|---|---|---|---|
| **1** | parallel pack-coder | BD-122 ∥ BD-123 | `test-fixtures/README.md` ∥ `tracker.toml.example` move + 10 refs | **BD-123 disposition pending — see §6** |
| **2** | sequential pack-coder | BD-125 | `supporting-docs/DRY-RUN-MIGRATION.md` (NEW) + cross-refs in README/OPTIONAL-FEATURES/MIGRATION-v10-to-v11 | Sequential after Batch 1 (cross-ref overlap with BD-123 if BD-123 ships) |
| **3** | sequential pack-coder | BD-120 → BD-116 | both touch `test-fixtures/build.sh` | Two commits; BD-120 first (BD-116 builds on parameterization) |
| **4** | sequential pack-coder | BD-117 → BD-118 | `maintenance-docs/RELEASE-GATE.md` (NEW) → `.github/workflows/validate-pack.yml` | Two commits; BD-118 depends on BD-117 surface + BD-116 contracts |
| **5** | direct (Pack Chat) | flips: BD-114, BD-121, BD-124, BD-059 → Resolved; opens: BD-128 / BD-129 / BD-130 / BD-131 / BD-132 / BD-133 / BD-134 | `BACKLOG.md` only | Single hygiene commit; PM-only file edits |
| **6** | sequential pack-coder | BD-128 (CI test-suite repair) | `scripts/tests/test-init-project.sh`, `test-fixtures/build.sh`, possibly `.github/workflows/validate-pack.yml` | **CI must turn green** — gate for downstream batches; if BD-120 prerequisite emerges, swap order with Batch 3 |
| **7** | sequential pack-coder | BD-132 (D-5 BLOCKER) | `scripts/lib/tracker-migrate-reverse.sh` + `scripts/pack-tracker.sh` + `scripts/lib/tracker-migrate-forward.sh` | Standalone commit; silent-data-loss bug warrants extra verification |
| **8** | parallel pack-coder | BD-129 ∥ BD-130 | `scripts/lib/tracker-labels.sh` + `scripts/lib/tracker-provider-gh.sh` ∥ `scripts/pack-tracker.sh` (source-add) + new `scripts/lib/tracker-doctor.sh` (or relocation target) | Different files; safe parallel |
| **9** | sequential pack-coder | BD-131 → BD-133 | `scripts/lib/tracker-migrate-forward.sh` (BD-131) → `scripts/lib/tracker-migrate-reverse.sh` (BD-133) | BD-133 sequential because BD-132 already touched reverse.sh in Batch 7 |
| **10** | sequential pack-coder | BD-134 (D-7 NIT) | `scripts/lib/tracker-provider-gh.sh` close call OR `scripts/lib/tracker-migrate-forward.sh` end-of-init pass | Standalone; small retry logic |
| **11** | parallel pack-coder | BD-112 ∥ BD-078 ∥ BD-079 | three-way diff fix ∥ validator Check `check_tracker_config` ∥ validator Check (recommendation-state schema) | Different files; safe parallel; one combined commit |
| **12** | atomic pack-coder | BD-104 | cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md` (large blast radius) | Single commit, atomic |
| **13** | sequential pack-coder | BD-095 → BD-101 | `scripts/migrate-v10-to-v11.sh` two-phase workflow → in-script validation gates | Two commits; BD-101 builds on BD-095's `--dry-run`/`--apply`/`--resume` surface |
| **14** | parallel pack-architect (audit-only) | BD-032 ∥ BD-033 ∥ BD-034 ∥ BD-035 | audit reports under `maintenance-docs/v11-implementation/AUDIT-BD-032..035.md` (no code) | Audit batch; **standing rule §5.B applies — fix-follow BD opened for every finding incl. NITs** |
| **14b** | (conditional) sequential pack-coder | fix-follow BDs from Batch 14 findings | TBD by audit output | Spawned only if audits surface defects; one commit per fix-follow BD |
| **15** | sequential pack-coder | BD-048 | `scripts/init-project.sh` capability-addition discovery + install-check symmetry with kickoff procedure | Standalone |
| **16** | sequential pack-coder | BD-096 | `test-fixtures/` synthetic-fixture set | Sequential after Batch 6 lands clean tests |
| **17** | sequential pack-coder | BD-106 → BD-107 → BD-108 | tracker entity-model expansion (phase task model + identifier scheme + parser/emitter → TD-NNN promotion → cross-entity dependency orchestration) | Three commits; intra-dependent |
| **18** | sequential pack-coder | BD-111 | switch blocks/blocked-by from comment-marker to first-class GH dependency API | After Batch 17 lands the entity model |
| **19** | parallel pack-coder | BD-105 ∥ BD-103 | STATUS.md phase-row dual-link rendering ∥ `pack tracker reset` verb + 3-level recovery doc | Different files; safe parallel |
| **20** | parallel pack-coder | BD-109 ∥ BD-110 | project-side `auditor-issue-tracking` agent files ∥ pack-side `pack-auditor` agent files | Different agent files; safe parallel; trinity rule applies inside each (per-CLI ×3) |
| **21** | sequential pack-architect + pack-reviewer (audit-only) | BD-100 final milestone audit | audit report under `maintenance-docs/v11-implementation/AUDIT-V11.0-FINAL.md` (no code) | Audit batch; **standing rule §5.B applies — fix-follow BDs opened for every finding incl. NITs**; final blocker check before BD-102 |
| **21b** | (conditional) sequential pack-coder | fix-follow BDs from Batch 21 findings | TBD by audit output | Spawned only if audit surfaces defects |
| **22** | sequential pack-coder + manual | BD-102 dog-food migration | run `migrate-v10-to-v11.sh` against pack-repo clone at v10 tag; verify clean output, customization preserved | Produces dog-food report under `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md`; **defects → fix-follow BDs incl. NITs (§5.B)** |
| **22b** | (conditional) sequential pack-coder | fix-follow BDs from Batch 22 defects | TBD by dog-food findings | Spawned only if dog-food surfaces defects |
| **23** | direct (Pack Chat) | BD-093 v11.0 release pin — final | rewrite `CHANGELOG.md` v11.0 entry; verify `README.md` version-table row; `MIGRATION-v10-to-v11.md` cross-link; `git tag v11.0`; `git tag -f v11`; `git push --tags` | **Release. Stop-before-commit + stop-before-push apply with maximum scrutiny.** |

**Total: 23 main batches + up to 3 conditional fix-follow batches = max 26 commits.** Could be more if any audit / dog-food fix-follow needs more than one commit.

---

## 5. Standing rules

These rules govern every batch in §4. They are ordered by enforcement priority — A overrides B if they conflict.

### A. Commit / push gating (Pack Chat scope)

1. **Stop-before-each-commit.** Before EVERY commit, Pack Chat shows the staged file list, diff stat, and a one-line description of what's about to commit. Wait for explicit user approval. Do not commit without it. (User rule, 2026-05-09.)
2. **No `git add -A`.** Stage explicit files. Avoids accidentally including secrets, scratch files, or out-of-scope edits.
3. **No commit or push without explicit user approval, every time.** Approval for one commit is not blanket approval for the next. Approval for a push is separate from approval for the commit.
4. **Push to `v11-dev` only.** Never push to `main` from this chat. v11.0 ships via deliberate handoff at Batch 23.
5. **Tag operations are destructive on tag space.** Treat as requiring explicit approval at Batch 23 (the only batch that creates/moves tags).

### B. Audit / fix-follow protocol (user rule, 2026-05-09)

1. Every audit pass that produces findings spawns a fix-follow batch.
2. **Even NITs get fixed.** Fix-follow scope includes every BLOCKER, SHOULD-FIX, and NIT surfaced.
3. Fix-follow runs as pack-coder (or direct edits if scope ≤ a few lines per file).
4. After fix-follow lands and validator/CI is clean, status flips per the implicit-flip rule (§C.4).
5. If fix-follow surfaces defects beyond the original audit scope, those become NEW BDs — not folded into the fix-follow batch.

### C. Agent / commit lifecycle

1. **Agents never commit.** Pack-coder, pack-architect, pack-reviewer write working-tree files + their own report file only. State-changing git verbs are forbidden to agents (memory rule).
2. **Pack Chat does not architect.** Architecture / planning / implementation / review goes to the corresponding pack agent. Pack Chat handles BACKLOG / CHANGELOG / approvals / commits / user-facing decisions (memory rule).
3. **No solutions in agent prompts.** Prompts contain context, problem, goal, success criteria, scope, and constraints — not pre-written solutions. Exception: when a user-approved decision is the goal, state it as a constraint, not as a "pick one" (memory rule).
4. **Implicit BD status flip on batch completion.** When a batch's review + fixes are clean and tests are green, flip its BDs to Resolved as the final step of the batch — no separate user approval needed (memory rule). Note this is distinct from §A.1: the BACKLOG status flip happens inside the same commit as the BD's implementation, not as a separate commit.

### D. Worktree / isolation (CLAUDE.md Pack memory)

1. **No `isolation: "worktree"` on Agent calls** from any chat in this repo. The Agent tool's worktree mode places sub-worktrees under the main clone's `.git/worktrees/` and checks out `origin/main` regardless of parent cwd — agents land on stable v10.1 content instead of v11-dev.
2. Run agents in-place against the parent chat's working tree.
3. For parallelism across worktrees, open separate Claude Code chat sessions in separate worktree directories. Never use Agent-tool worktree isolation.
4. **Parallel in-place agents are allowed** when their file sets are disjoint. Conflicting agents must be sequenced. (See per-batch conflict notes in §4.)

### E. Trinity / scope discipline

1. **Trinity rule.** Any change to one of CLAUDE.md / AGENTS.md / GEMINI.md (pack-root or `project-template/`) requires the parallel change to the other two in the same set of edits. Tool-specific exemptions require explicit justification (e.g., the Sub-agent isolation rule in pack-root CLAUDE.md). (CLAUDE.md rule.)
2. **PM-only files** are off-limits to all agents unless a caller's prompt explicitly scopes them in: BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md / AGENTS.md / GEMINI.md (root and `project-template/`). Pack Chat handles all PM-only file edits directly.
3. **Pack-ops vs pack-product separation.** Pack-ops files (pack-root governance + maintenance-docs/) NEVER mixed into pack-product files (project-template/, supporting-docs/). Same applies in reverse. (Memory rule.)
4. **Chunked-Edit on report files.** Agents authoring outputs >300 lines chunk via initial Write + Edit-append. Single >300-line Write calls are not allowed. (Memory rule, codified in `chunked-Edit` pattern in agent Hard rules; PM-CHAT.md profile description aligned in BD-127 / F-16.)

### F. Validator / CI gates

1. **`validate-pack.py` PASSES after every batch.** Pack Chat verifies before committing. Regression on any check (1–28) is a defect — fix-forward in the same batch or split a fix-follow.
2. **CI `validate` job must be green before BD-102 dog-food (Batch 22).** Currently green. Stays green = batches don't break it.
3. **CI `tests` job must be green before BD-093 release pin (Batch 23).** Currently red — Batch 6 (BD-128) is the gate that turns it green. Subsequent batches must keep it green.
4. **No `--no-verify` on commits.** No bypassing pre-commit hooks. (Standing rule.)

---

## 6. Open questions — pending user decisions

These block one or more batches. Resolve before firing the affected batches.

### Q1 — BD-123 disposition (blocks Batch 1's BD-123 leg)

The BD-123 BACKLOG entry's premise is wrong. There are TWO distinct `tracker.toml.example` files with different content for different purposes:

| File | Purpose | Distinguishers |
|---|---|---|
| `/tracker.toml.example` (root) | Pack-repo-side tracker config example | Header: "pack repo tracker configuration"; `repo = "Optiquity-Inc/optiquity-ai-agent-config-pack"`; `prefix = "BD"` |
| `/project-template/tracker.toml.example` | Client-project-side tracker config example | Header: "client project tracker configuration"; `repo = "your-org/your-project"`; `prefix = "TD"` |

README documents both intentionally (lines 128 + 226). Three options:

1. **Delete the root file** (treat as redundant).
2. **Rename the root file** to `pack-tracker.toml.example` (make asymmetry visible in filename).
3. **Close BD-123 as Cancelled / Won't Fix** (asymmetry is intentional and documented; BACKLOG author missed context).

**Pack Chat recommendation: option 3.** Reasoning: the root file is a legitimate pack-ops artifact parallel to the client-side example. Deleting loses a real artifact; renaming is cosmetic. Closing as Cancelled with a one-line BACKLOG note explaining the intentional asymmetry is the truthful outcome.

### Q2 — BD-122 commit timing (blocks Batch 1 close-out)

BD-122 work is complete: `test-fixtures/README.md` modified (+47 / −7), `IMPLEMENTATION-REPORT-BD-122.md` written. Validator green. **Commit standalone, OR bundle with whatever BD-123 becomes after Q1?**

**Pack Chat recommendation: commit standalone now.** Reasoning: BD-122 is unrelated to BD-123 substance. Bundling adds no value and delays a clean win. Per §A.1 the commit waits for explicit user approval anyway.

### Q3 — Batch 6 / Batch 3 swap?

If BD-128's CI repair (Batch 6) requires BD-120's fixture parameterization (Batch 3), Batch 3 must move ahead of Batch 6. Pre-flight check is the first task in Batch 6. Resolution is automatic — no user decision needed unless the pre-flight surfaces a deeper sequencing issue.

---

## 7. Verification gates summary

| Gate | When | Pass criteria | Fail action |
|---|---|---|---|
| Per-batch validator | After every code-change batch, before commit | `validate-pack.py` PASSED — all checks clean | Fix-forward in same batch |
| CI `validate` job | After every push | green | Fix-forward; never defer |
| CI `tests` job | After every push | green (target post-Batch 6) | Currently red; Batch 6 gates green; subsequent batches must keep it green |
| Final milestone audit | Batch 21 | audit report finds zero BLOCKER + acceptable SHOULD-FIX/NIT scope | Fix-follow batch (Batch 21b) per §5.B |
| Dog-food migration | Batch 22 | clean migrator output against v10-tag pack clone; customization preserved | Fix-follow batch (Batch 22b) per §5.B |
| Pre-tag check | Batch 23 | all BDs in §1.1–1.4 Resolved; BD-059 verified-closed; CI fully green; final audit clean | Hold release; resolve gates first |

---

## 8. Pre-flight checklist before Batch 1 fires

User must confirm:

- [ ] Q1 disposition for BD-123 (recommend option 3 = Cancel)
- [ ] Q2 BD-122 commit timing (recommend standalone commit now)
- [ ] Plan reviewed; no major restructuring needed
- [ ] Ready to fire Batch 5 (BACKLOG hygiene + new-BD opens) immediately after Batch 1's BD-122 commit

When all four are confirmed, Pack Chat:
1. Commits BD-122 (with §A.1 stop-and-show)
2. Resolves BD-123 per Q1 disposition (separate commit if Cancel; integrated commit if Delete/Rename)
3. Fires Batch 2 (BD-125)
4. Continues per §4 batch sequence with §A stop-and-show on every commit

---

## 9. Document maintenance rules

- This doc is read-only by agents. Pack Chat may update it as scope changes.
- BACKLOG.md remains the canonical source for BD detail. If this doc and BACKLOG.md disagree, BACKLOG.md wins; Pack Chat updates this doc.
- New BDs added mid-execution are added to §1 + §4 in the same Pack Chat update.
- When v11.0 ships, this doc is preserved as historical artifact (do not delete).

---
*End of plan.*
