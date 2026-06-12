# PLAN-BD-204-MODE3-OPS-CONTRACT — implementation plan (Mode-3 ops contract)

> **Agent:** pack-planner (fresh instance). **Mode:** PLAN ONLY — no repo edits other than
> this plan doc; read-only git verbs only; no live GitHub calls. **HEAD (verified):**
> `1c18b28` (`git rev-parse HEAD` → `1c18b28c4d149d3e80565beafccc84f8d25b32f2`), branch
> `v11-dev`, with the in-flight casing+cycle working-tree edits present (uncommitted
> `scripts/lib/tracker-*.sh` + `scripts/tests/*` modifications — NOT this plan's scope).
> **Date:** 2026-06-11.
>
> **Primary input:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md`
> (read in full; all design content lives THERE — this plan points, never restates).
>
> **User rulings layered on the approved strategy (FIXED, per user-prescriptive-authority):**
> 1. OQ-A RESOLVED YES — thin `pack tracker edit` + `pack tracker new-entry` verbs land in
>    the code commit (Commit 2).
> 2. Sequencing OVERRIDE — the two contract commits land BEFORE the BD-204 C-8 commit,
>    stacked on top of the casing+cycle commit (which commits first). The architect doc §6
>    "Sequencing with the pending C-8 commit" bullet ("Those land FIRST") is OVERRIDDEN by
>    user authority for C-8; the casing+cycle commit (the actual content of today's
>    uncommitted tracker-lib edits) still lands first. Flagged explicitly here — not a
>    silent deviation.
> 3. All six strategy elements approved as designed (tree-rebuild verb, committed freshness
>    keys, blob-status-truth comparator + doctor legs, Check 32′ mode-marker assertions,
>    R1–R8 project-side handoff section).
>
> **Consumers:** Pack Chat (commit sequencing + coder-prompt scoping), pack-coder ×2
> (mechanical application), pack-reviewer (per-commit review).

---

## 0. Base-state contract (what must be true before each coder spawns)

- **B0 (both commits).** The casing+cycle commit has LANDED (the `scripts/lib/tracker-*.sh`
  + `scripts/tests/*` working-tree edits visible at `git status` today are committed and CI
  is green). Every coder prompt pins the post-casing+cycle HEAD SHA as its expected base.
  Rationale: Commit 2 edits the SAME tracker-lib files; interleaving with an uncommitted
  sibling cycle is the exact hazard the architect's §6 fresh-coder note targets.
- **B1 (Commit 2 only).** Commit 1 has LANDED. The §4.2 Check 32′ extension asserts the
  `_rules.md` mode markers exist; landing it before Commit 1 is a RED check by construction
  (measure-then-bound — markers measured ABSENT at `1c18b28`, EE-1 below).
- **B2 (both commits).** The pack repo is live Mode 3 with an UNTRACKED root `tracker.toml`
  (EE-6). Verification must NOT depend on a real-tree forward run — forward over the real
  tree fails loud at parse BY DESIGN until the BD-094/BD-095 data fix lands (per calling
  prompt). All test legs are mock-/fixture-based (architecture §4.3 "all mock-based").

> **Empirical-Evidence Block EE-1 (mode markers absent at HEAD).**
> `CMD`: `grep -n "Flat-file mode\|Tracker mode\|Mode invariance" backlog/_rules.md changelog/_rules.md`
> `OUT`: (empty — zero hits in both files)
> `AT`: HEAD `1c18b28`, 2026-06-11. `INTERP`: the §1.1/§1.2 mode sections do not exist yet;
> the Check 32′ marker assertion MUST land after the docs commit. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block EE-2 (verb surface lacks the new verbs).**
> `CMD`: `grep -n "tree-rebuild\|cmd_edit\|new-entry" scripts/pack-tracker.sh`; full read of
> the dispatcher (456 lines).
> `OUT`: dispatch case = `init / status / mirror-rebuild / disable / doctor /
> update-templates / enable-recommendations` only; zero hits for the three new verbs.
> `AT`: HEAD `1c18b28` + working-tree edits. `INTERP`: Commit 2 adds, never collides.
> `CONCL`: SUPPORTED.

---

## 1. Ordered commit table

| # | Commit subject (proposed) | Contents (summary) | Check-36 keyword | Manifest expectation |
|---|---|---|---|---|
| 0 | (in flight — NOT this plan) casing+cycle commit | today's uncommitted tracker-lib + test edits | per its own cycle | per its own cycle |
| 1 | `docs: v11 — BD-204 Mode-3 ops contract on session-load surfaces (pack-chat-only)` | `/backlog/_rules.md`, `/changelog/_rules.md`, `pack-ops/PACK-CHAT.md`, root trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` | `pack-chat-only` (verified — EE-3) | Run `bash test-fixtures/build.sh --all --clean`; expected EMPTY `git diff test-fixtures/manifest.txt`; non-empty → STOP, see §2.5 |
| 2 | `feat: v11 — BD-204 Mode-3 ops verbs (tree-rebuild/edit/new-entry) + status-coherence + doctor/validator repoints (pack-only)` | `scripts/pack-tracker.sh`, `scripts/lib/tracker-migrate-reverse.sh`, `scripts/lib/tracker-edit.sh`, `scripts/lib/tracker-migrate-forward.sh`, `scripts/tracker-migrate.sh`, `scripts/lib/tracker-doctor.sh`, `scripts/validate-pack.py`, 5 test suites, `pack-ops/HELP-FRAGMENT-PACK.md`, `test-fixtures/manifest.txt` (+ `.gitignore` iff OQ-1 option (a) approved) | `pack-only` | `scripts/**` is fixture-affecting → manifest WILL drift; regenerate + stage in the SAME commit |
| — | BD-204 C-8 commit | (out of scope; stacks AFTER Commit 2 per user ruling 2) | — | — |

Both subjects are approved shapes (`docs:` / `feat: vN — BD-NNN ...` per pack-root
CLAUDE.md commit-format rules); both bind to the BD-204 anchor (same-contract LOGICAL FIT
per architecture §6 — no new-BD-open needed).

> **Empirical-Evidence Block EE-3 (Commit-1 keyword fits `pack-chat-only`).**
> `CMD`: read `scripts/validate-pack.py` `_PACK_CHAT_ONLY_PERMITTED_PATHS` +
> `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` + `_is_pack_chat_only_permitted()` (Check 36).
> `OUT`: permitted PATHS include `pack-ops/PACK-CHAT.md`, `CLAUDE.md`, `AGENTS.md`,
> `GEMINI.md`; permitted PREFIXES include `backlog/` and `changelog/`. Commit 1's six
> touched paths = {`backlog/_rules.md`, `changelog/_rules.md`, `pack-ops/PACK-CHAT.md`,
> `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`} — every one matches the permitted set.
> `test-fixtures/manifest.txt` is NOT in the permitted set (drives the §2.5 contingency).
> `AT`: HEAD `1c18b28`. `INTERP`: keyword `pack-chat-only` is Check-36-clean iff the
> manifest does not drift. `CONCL`: SUPPORTED.

---

## 2. Commit 1 — docs/contract commit (recipe)

### 2.1 File list + per-file edit recipe (architecture §-pointers; do not restate)

| File | Edit | Architecture § |
|---|---|---|
| `backlog/_rules.md` | Replace § "Source of truth — no mirror" with the mode-conditional section; replace § "Write authority" (keep the Pack-Chat-authority sentence verbatim) | §1.1 (both fenced text blocks; semantic content fixed, wording may tighten) |
| `changelog/_rules.md` | Add the one-paragraph "Mode invariance" statement to § "Source of truth — no mirror"; rest of file unchanged | §1.2 |
| `pack-ops/PACK-CHAT.md` | New § "Backlog write paths by mode (Mode-3 operations)" placed immediately after § "File access strategy", realizing content items 1–9; plus item 10's File-access-strategy table "Why"-cell touch-up on the `/backlog/<ID>.md` row | §1.3 (items 1–10) |
| `CLAUDE.md` (root) | Append the two-sentence operational imperative to the "Per-entry trees — sole SSOT (pack: no mirror)" bullet's tracker-mode arm | §1.4 (quoted text) |
| `AGENTS.md` (root) | Identical append (byte-identical to CLAUDE.md's — full parity, no tool-specific content) | §1.4 |
| `GEMINI.md` (root) | Identical append | §1.4 |

Rule-change propagation surfaces (per `pack-ops/PACK-CHAT.md` § "Rule-change propagation
procedure", all in THIS commit): surface 1 = corpus ×3 trinity (above); surface 2
(`PACK-MEMORY-RATIONALE.md`) N/A — the bullet carries no `[rationale:]` slug and the design
adds none (architecture §1.4); surface 4 (reference surfaces) = the PACK-CHAT.md §1.3
section (above); surface 5 (`pack-ops/.spawn-rule-manifest.txt`) N/A — verified (EE-4);
surface 6 (fixture manifest) = §2.5 below. Surface 3 (out-of-repo memory cache) is
Pack-Chat upkeep after the commit, not a coder action.

> **Empirical-Evidence Block EE-4 (spawn-rule manifest does not list the bullet).**
> `CMD`: `grep -n "per-entry\|sole SSOT\|tree-rebuild" pack-ops/.spawn-rule-manifest.txt`
> `OUT`: (empty — zero hits)
> `AT`: HEAD `1c18b28`. `INTERP`: surface 5 is N/A, as the architect expected ("no slug").
> `CONCL`: SUPPORTED.

### 2.2 Content constraints the coder must hold (enforced by existing CI checks)

- **Trinity parity:** the §1.4 append is byte-identical across the three root files (trinity
  parity + Check 18 H2-structure checks run in `validate-pack.py`).
- **Anti-restate (Check 46 / one-hop SSOT design):** the PACK-CHAT.md section POINTS at
  `<stream>/_rules.md` for the per-stream contract and at the trinity bullet for the
  imperative; it must NOT reproduce the §1.1 fenced text or the trinity bullet text
  verbatim (architecture §1 "no rule text is duplicated across the three layers").
- **Check 40 (pack-ops/ bare-cross-reference scanner):** in the new PACK-CHAT.md section,
  qualify file refs with paths (`/backlog/_rules.md`, `.pack-tracker/id-map.json`); bare
  `tracker.toml` and `id-map.json` are pre-allowlisted (verified: `_CHECK_40_ALLOWLIST`
  carries both entries).
- **Check 44:** N/A — neither PACK-CHAT.md nor the `_rules.md` files are in the M4
  durable-doc class (verified against `_CHECK_44_DURABLE_DOCS`).
- **Forward-naming transient (accepted):** the §1.1/§1.3 text names `pack tracker
  tree-rebuild` / `edit` / `new-entry`, which exist only after Commit 2. This is forced by
  the Check 32′ docs-before-code ordering (architecture §6) and is a one-commit-window
  transient; no CI check resolves verb names in prose. Commit 2 follows immediately.
- **OQ-1 wording dependency:** the §1.1 tracker-mode staging list names
  `.pack-tracker/id-map.json`, which is currently GITIGNORED (EE-5, §8 OQ-1). Resolve OQ-1
  with the user BEFORE the Commit-1 coder spawns; if option (b) is chosen, the staging-list
  wording drops the id-map clause (a deviation from approved §1.1 text → needs the user's
  explicit nod, which OQ-1 resolution itself provides).

### 2.3 Routing (BD-208 pack-chat-only scoping)

ALL six Commit-1 files are pack-chat-only surfaces (`/backlog/` + `/changelog/` trees,
PACK-CHAT.md, root trinity per `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and
directories"). This is a MAJOR edit (rule/contract change) → pack-coder scoped in, per
`[rationale: pack-chat-minor-edits-only]` — scoping pack-chat-only files into the coder
prompt is the SUPPORTED path. The coder prompt MUST therefore explicitly name each file
AND the section-level change (the table in §2.1), and cite BD-204 + the user-approved
architecture as the version-bump authority for editing the pack-shipped-immutable
`_rules.md` files (PACK-AGENTS.md: "updated on pack version bump only" — v11.0 is the
unreleased in-development bump that minted these contracts). The coder must NOT touch
`scripts/`, `project-template/`, or `supporting-docs/` in this commit.

### 2.4 Commit subject + Check-36 keyword

`docs: v11 — BD-204 Mode-3 ops contract on session-load surfaces (pack-chat-only)` —
keyword verified clean per EE-3. Check 36 walks HEAD at CI; Pack Chat re-runs
`python3 scripts/validate-pack.py` AFTER the commit, BEFORE the push, so Check 36 evaluates
the new HEAD locally first.

### 2.5 Manifest expectation + contingency

`pack-ops/` is v11-surface → run `bash test-fixtures/build.sh --all --clean` from pack
root, then `git diff test-fixtures/manifest.txt`. Expected EMPTY (PACK-CHAT.md, root
trinity, and the `_rules.md` trees are not fixture-affecting; the fixture-copied pack-ops
file is HELP-FRAGMENT-TRACKER.md, untouched here). Contingency: if the diff is NON-empty,
do NOT silently stage it under the `pack-chat-only` keyword (manifest path is not
Check-36-permitted, EE-3) — STOP, identify which fixture input actually drifted, and
surface to the user at the commit gate with the fallback keyword `pack-only` (all Commit-1
paths are also pack-only-clean: none under `project-template/` or `supporting-docs/`).

### 2.6 Verification recipe (Commit 1)

Coder runs, in order — the COMPLETE battery, not a subset (verify-full-ci-suite):

1. `python3 scripts/validate-pack.py` (all checks incl. trinity parity, Check 18, 32′
   pre-extension, 33, 36 [walks pre-commit HEAD], 40, 44, 45, 46).
2. `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (CI validate job step 2).
3. Every `tests:`-job suite from `.github/workflows/validate-pack.yml`, by name:
   `scripts/test-detect.sh`; `scripts/tests/tracker-provider-test.sh`;
   `tracker-config-test.sh`; `tracker-init-test.sh`; `tracker-agent-read-test.sh`;
   `tracker-migrate-forward-test.sh`; `tracker-migrate-reverse-test.sh`;
   `tracker-migrate-roundtrip-test.sh`; `test-tracker-phase-task.sh`;
   `test-tracker-links.sh`; `test-tracker-cycle-check.sh`; `tracker-errors-test.sh`;
   `tracker-config-schema-test.sh`; `recommendation-state-schema-test.sh`;
   `test-per-entry.sh`; `test-validate-pack-checks-32-33-34.sh`;
   `test-validate-pack-checks-36-37-38.sh`; `test-validate-pack-check-39.sh`;
   `test-validate-pack-check-40.sh`; `test-validate-pack-check-41.sh`;
   `test-validate-pack-check-18.sh`; `test-validate-pack-check-16.sh`;
   `test-validate-pack-check-19.sh`; `test-validate-pack-check-42.sh`;
   `test-validate-pack-check-43.sh`; `test-validate-pack-check-44.sh`;
   `test-validate-pack-check-45.sh`; `test-validate-pack-check-46.sh`;
   `test-validate-pack-check-removed-doc-advisory.sh`;
   `test-validate-pack-check-49-field-faithfulness.sh`; `tracker-bd129-gh-repo-test.sh`;
   `tracker-bd130-doctor-wired-test.sh`; `tracker-bd132-race-test.sh`;
   `tracker-bd133-header-preservation-test.sh`; `tracker-bd134-close-retry-test.sh`;
   `recommendation-test.sh`; `pack-help-test.sh`; `test-customization-preserve.sh`;
   `test-init-project.sh`; `test-migrate-v10-to-v11.sh`;
   `test-migrate-v10-to-v11-dry-run.sh`; `test-migrate-v10-to-v11-gates.sh`;
   `test-migrate-v10-to-v11-decompose.sh`; `scripts/test-migrator-core.sh`;
   `scripts/test-migrator-manifest.sh`; `scripts/test-migrator-capability-translation.sh`;
   then `bash test-fixtures/build.sh --all --clean` → `git checkout HEAD --
   test-fixtures/manifest.txt` is CI-only (the coder instead checks
   `git diff test-fixtures/manifest.txt` per §2.5) → `bash test-fixtures/build.sh
   --verify`; `scripts/tests/test-v11-realistic-ot.sh`; `scripts/test-migrator-skills.sh`;
   `scripts/test-persona-contracts.sh`; `template-translations-test.sh`;
   `template-version-test.sh`; `test-issue-forms.sh`.
4. Targeted greps: both `_rules.md` files carry the new mode headings; the three trinity
   files' appended sentences are byte-identical (`diff <(grep -A4 'sole SSOT' CLAUDE.md) …`
   pattern); the PACK-CHAT.md section does not contain the trinity bullet text verbatim.
5. NO real-tree forward run; NO live `gh` calls (B2).

PREFLIGHT line + IMPL-REPORT per the standard pack-coder pattern; then the bounded
review/fix cycle (reviewer → user triage → fix-coder), then Pack Chat stages
(`git add -A && git status`, show staged files) and commits on user approval.

---

## 3. Commit 2 — code/verbs/validation commit (recipe)

### 3.1 File list + per-file edit recipe

| File | Edit | Architecture § |
|---|---|---|
| `scripts/pack-tracker.sh` | New `cmd_tree_rebuild` (flags `--repo-root`, `--force`; mode gate fail-loud; v11.0 pack-surface-only gate — client surface fails loud naming BD-207, realizing "tree_only=1 is pack-surface-only at v11.0"); new thin `cmd_edit` (flag-parsing wrapper over `tracker_edit_entry` — maps flags to the patch-JSON keys the function already documents); new thin `cmd_new_entry` (mode gate; `--id BD-NNN` shape-validated + duplicate-id refusal against the id-map; verbatim entry-span input; compose via `tmf_compose_issue_body`; labels via the existing forward label map; `provider_create`; id-map append; `last_tracker_write` stamp; finish with the tree-rebuild path so the entry materializes + `_toc.md` regen — NO new codec, NO raw `gh`); `usage()` rows for all three; dispatch entries | §2 (verb mechanics), §0 (OQ-A recommendation — approved by user ruling 1) |
| `scripts/lib/tracker-migrate-reverse.sh` | `tracker_migrate_reverse_run` gains 6th positional `tree_only` (default 0); `tree_only=1` pack branch runs roster → reconstruct (guards intact) → `_tmr_emit_pack_tree` → timestamp stamp ONLY (skips `_tmr_emit_implementation_plan`, `_tmr_emit_status`, header strips); `last_tree_regen` stamped on EVERY pack tree materialization (tree-only arm AND full reverse/disable — extend `_tmr_update_tracker_toml` or equivalent single-home writer); new `_tmr_check_status_coherence` invoked where `_tmr_check_blob_h2_divergence` runs (inside `tracker_migrate_reverse_reconstruct`), comparing `_tmr_decode_status(issue)` vs the blob body's first `Status:` line — mismatch fails loud naming pack-ids + both values + the §3 recovery-instruction text; `--force` = blob-wins; silent-data-loss guard message "Reconstructing BACKLOG.md now would drop…" surface-neutralized | §2 (engine, freshness keys, ride-alongs a/b), §3 (comparator layer 1) |
| `scripts/lib/tracker-edit.sh` | `tracker_edit_entry` stamps `migration.last_tracker_write` AFTER the full mutation sequence succeeds (update + any boundary cross), not on failure | §2 (freshness bookkeeping) |
| `scripts/lib/tracker-migrate-forward.sh` | `mirror_only` pack-surface fail-loud message gains "run \`pack tracker tree-rebuild\` instead" (ride-along a) | §2 |
| `scripts/tracker-migrate.sh` | Help text gains the tree-rebuild pointer (reverse subcommand note) | §2 |
| `scripts/lib/tracker-doctor.sh` | Leg (d) pack arm: replace the `_toc.md`-mtime vs `last_forward_run` comparison with `last_tracker_write > last_tree_regen` WARN → "tree is stale relative to tracker writes → Run: pack tracker tree-rebuild"; keep `_toc.md`-present INFO/OK lines; absent-key tolerance (INFO, not WARN — older tracker.toml has neither key); client arm UNTOUCHED (BD-207). New leg (h): status-coherence advisory via `provider_list` (no per-issue sweep), tracker-mode + pack-surface only, INFO-skip in flat-file mode and when `gh`/network unavailable (leg-(g) graceful-degradation pattern), WARN per mismatch with the §3 recovery text | §4.1 |
| `scripts/validate-pack.py` | Extend Check 32′ (`check_mirror_in_sync`): per-stream required-marker assertion — `/backlog/_rules.md` must contain the two mode headings/markers; `/changelog/_rules.md` the "Mode invariance" marker; heading/marker-presence ONLY (no prose-pinning); allowlist sized to exactly the two pack streams; update the header check-description block (the numbered-check docstring near the top) in lock-step | §4.2 |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | New legs pinning the 32′ marker-assertion banners (present-markers PASS; absent-markers FAIL), following the suite's existing synthetic-stream pattern | §4.2 (enumerate-encoding-surfaces lock-step) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | Legs 1, 2, 5, 8 + 9 of §5 below; update any pins of the neutralized guard message | §4.3 |
| `scripts/tests/tracker-migrate-forward-test.sh` | Legs 3, 4 (extend the existing 4.5 mirror-only assertions: message still typed-validation + now NAMES tree-rebuild; client-surface byte-unchanged regression) | §4.3 |
| `scripts/tests/tracker-provider-test.sh` | Leg 6 + verb tests for `edit` / `new-entry` (extends the existing "Group 4: Mode-3 pack edit path" mock harness) | §4.3 + OQ-A |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | Leg 7 (stale-tree WARN; status-coherence WARN; both name recovery verbs); reconcile the existing 8.1–8.4 pack-arm assertions with the leg-(d) repoint | §4.3 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | The `scripts/pack-tracker.sh <subcmd>` row's verb list gains `tree-rebuild`, `edit`, `new-entry` (enumerate-encoding-surfaces; verified this is the only pack-side help surface listing the verb set — client HELP-FRAGMENT-TRACKER.md pair stays UNTOUCHED, client verbs are BD-206/207 scope per §5 R2) | §2 + repo convention |
| `test-fixtures/manifest.txt` | Regenerate + stage (scripts/** drift is certain) | manifest rule |
| `.gitignore` | IFF OQ-1 option (a) approved: add `!.pack-tracker/id-map.json` negation | §8 OQ-1 |

Test-file placement decision (architecture §4.3 left it open): EXTEND the five existing
suites rather than create `test-pack-tracker-tree-rebuild.sh`. Rationale: zero workflow-yml
edits needed (every suite is already wired — EE-7), Check 42 unaffected (it gates only
`test-validate-pack-check*` names), and each leg lands beside the harness it reuses. If the
coder finds a suite structurally unfit, a new file requires BOTH the filename-uniqueness
check AND a new workflow step — surface that in the IMPL-REPORT as a plan deviation.

In-code docstrings for the new/changed symbols name file + symbol cross-references (never
line numbers) per architect-doc-vs-reality reconciliation; the IMPL-REPORT links the
architecture doc §2/§3/§4 and this plan.

### 3.2 Routing

NO pack-chat-only files in this commit (`pack-ops/HELP-FRAGMENT-PACK.md` is NOT in the
PACK-AGENTS.md pack-chat-only Files list — it is ordinary pack-ops content agents may edit
when the task requires; verified against `_PACK_CHAT_ONLY_PERMITTED_PATHS` which is the
Files-list mirror, where it does not appear, and against PACK-AGENTS.md § "pack-chat-only
files and directories"). Standard pack-coder scope: `scripts/**`, `scripts/tests/**`,
`pack-ops/HELP-FRAGMENT-PACK.md`, `test-fixtures/manifest.txt` (+ `.gitignore` iff OQ-1(a)).
FRESH coder (never the Commit-1 instance), spawned only after Commit 1 lands; base SHA =
Commit-1 HEAD, pinned in the prompt.

### 3.3 Commit subject + Check-36 keyword

`feat: v11 — BD-204 Mode-3 ops verbs (tree-rebuild/edit/new-entry) + status-coherence +
doctor/validator repoints (pack-only)`. (The architect's §6 subject predates the OQ-A YES;
this subject names the approved verb additions. Final wording is the user's at the commit
gate.) `pack-only` is clean: every touched path is outside `project-template/` +
`supporting-docs/` (the deny set per `_PROJECT_SIDE_PATH_PREFIXES`); precedent: HEAD
`1c18b28` itself is a `(pack-only)` tracker-libs commit.

### 3.4 Manifest expectation

`scripts/**` is fixture-affecting (mass-copied by init-project stages) → run
`bash test-fixtures/build.sh --all --clean`; `git diff test-fixtures/manifest.txt` WILL be
non-empty; stage it alongside the scope edits in the SAME commit (the two-incident rule).
`pack-ops/HELP-FRAGMENT-PACK.md` is not client-copied, but the directory-wide trigger
already fires via `scripts/`.

### 3.5 Verification recipe (Commit 2)

The COMPLETE battery of §2.6 (identical enumeration — every validate-pack run, every named
suite, the fixture build/verify sequence), PLUS:

1. The new §5 test legs all PASS inside their host suites.
2. Post-fixture-rebuild assertion: NO `STATUS.md` and NO `IMPLEMENTATION-PLAN.md` at the
   pack root (`ls STATUS.md IMPLEMENTATION-PLAN.md` → both absent), and the tree-rebuild
   happy-path leg asserts the same at the FIXTURE root (architecture §2's no-stray-files
   requirement).
3. Check 32′ extension verified GREEN against the post-Commit-1 real tree (markers exist —
   B1) AND exercised RED/GREEN in the per-check test.
4. Check 42 still green (no new `test-validate-pack-check*` file; if a deviation created
   one, its workflow wiring must be in this commit).
5. NO real-tree forward run; NO live `gh` calls; doctor leg (h) exercised via mock `gh`
   only.

Same PREFLIGHT/IMPL-REPORT/bounded-review-cycle/commit-gate flow as Commit 1.

---

## 4. Ordering-dependency rationale (explicit)

- **D1 — casing+cycle commit → Commit 1.** The working tree carries that cycle's
  uncommitted edits (EE-8); Commit 1 touches none of those files, but committing around a
  dirty sibling cycle violates chat-ownership boundaries and muddies Check-36 path walks.
  Commit 1's coder spawns only after it lands.
- **D2 — Commit 1 → Commit 2 (Check 32′ measure-then-bound).** The marker assertion is RED
  at any tree without the §1.1/§1.2 sections (EE-1). Docs-first keeps `validate-pack.py`
  green at every intermediate HEAD (architecture §6).
- **D3 — Commit 2 → BD-204 C-8 (user ruling 2).** User authority; the architect's
  stack-after-C-8 recommendation is overridden. Flagged, not silent. Consequence for C-8's
  own cycle: its coder rebases its expectations on the post-Commit-2 tracker-lib state.
- **D4 — trinity append rides INSIDE Commit 1** per the rule-change propagation procedure's
  same-commit surface set (corpus ×3 + reference surface + manifests; surfaces 2/5 N/A per
  §2.1/EE-4). Order within the commit is documented-not-gate-sequenced; END-STATE checks
  (parity / bijection / anti-restate / manifest) verify it.
- **D5 — OQ-1 resolves before the Commit-1 coder spawns** (§2.2 last bullet): the §1.1
  staging-list wording depends on it; if option (a), the `.gitignore` edit lands in
  Commit 2 (it is not a docs surface and is not pack-chat-only).

Approval gates: (G1) user approves THIS plan before any coder spawn (planner→user→coder
rule); (G2) per-commit reviewer-triage gate; (G3) per-commit staged-file + commit-approval
gate; (G4) OQ-1/OQ-2 user rulings (§8).

---

## 5. Test-leg inventory (mapped to architecture §4.3, with host suite)

| Leg | Assertion | Host suite |
|---|---|---|
| 1 | `tree-rebuild` happy path (mock `gh`): tree files + `_toc.md` regenerated; `last_tree_regen` stamped; `mode.state` UNCHANGED; NO `STATUS.md`/`IMPLEMENTATION-PLAN.md` at fixture root; no monolith | `tracker-migrate-reverse-test.sh` |
| 2 | `tree-rebuild` flat-file-mode refusal (fail-loud message asserted) | `tracker-migrate-reverse-test.sh` |
| 3 | Pack-surface `mirror-rebuild` fail-loud message NAMES `tree-rebuild` | `tracker-migrate-forward-test.sh` (extends 4.5) |
| 4 | Client-surface `mirror-rebuild` behavior byte-unchanged (regression) | `tracker-migrate-forward-test.sh` |
| 5 | Status-coherence comparator: divergent label/state vs blob `Status:` → fail loud listing pack-id; `--force` → blob's `Status:` reaches the tree file | `tracker-migrate-reverse-test.sh` |
| 6 | `tracker_edit_entry` stamps `last_tracker_write` on success, NOT on failure | `tracker-provider-test.sh` (Group 4) |
| 7 | Doctor: stale-tree WARN on `last_tracker_write > last_tree_regen`; status-coherence WARN on mocked divergent issue; both name recovery verbs; absent-keys tolerance | `tracker-bd130-doctor-wired-test.sh` |
| 8 | Hand-edit overwrite demonstration: hand-edit a tree file in tracker mode, run `tree-rebuild`, hand-edit GONE (one-way write proven by test) | `tracker-migrate-reverse-test.sh` |
| 9 | (planner addition realizing §2's pack-surface-only scope) `tree-rebuild` client-surface refusal names BD-207 | `tracker-migrate-reverse-test.sh` |
| 10 | (OQ-A) `pack tracker edit` wrapper: flag→patch-JSON mapping drives the existing Group-4 mock assertions; `pack tracker new-entry`: compose + create + labels + id-map append + `last_tracker_write` stamp + tree materialization; duplicate-id refusal | `tracker-provider-test.sh` |
| 11 | Check 32′ marker assertions: markers-present PASS / markers-absent FAIL banners | `test-validate-pack-checks-32-33-34.sh` |

All mock-based; join the unattended battery; the live C-7 oracle is untouched.

---

## 6. Risks

- **R1 — Commit-1 manifest drift breaks the `pack-chat-only` claim.** Mitigated by §2.5
  contingency (STOP + `pack-only` fallback + user surfacing). Probability low (no
  fixture-affecting file touched).
- **R2 — same-file interleaving with casing+cycle / C-8.** Mitigated by D1/D3 base-SHA
  pinning + per-commit fresh coders.
- **R3 — message-pin churn:** forward test 4.5, reverse-test guard-message pins, doctor
  test 8.1–8.4 all pin text this commit changes — each is named in §3.1 for lock-step
  update (enumerate-encoding-surfaces).
- **R4 — doctor leg (d) on real Mode-3 tree:** until a tracker write stamps
  `last_tracker_write`, the key is absent → leg must INFO-skip, not WARN (named in §3.1);
  otherwise `pack tracker doctor` rc=1 noise on the live repo.
- **R5 — forward-naming transient** (§2.2): docs name verbs one commit early; accepted,
  bounded to the C1→C2 window.
- **R6 — Check 36 verifies at CI only on HEAD:** a push bundling C1+C2 evaluates only the
  last commit at CI; local post-commit `validate-pack.py` runs (§2.4) close the gap, and
  pushing after EACH commit (normal practice) keeps both gated.

---

## 7. Open questions for the user

- **OQ-1 — `.pack-tracker/id-map.json` is gitignored vs the approved §1.1 staging text.**
  EE-5: `.gitignore:12` = `.pack-tracker/`, so the approved write-procedure clause "stage …
  `.pack-tracker/id-map.json`" cannot be executed today (`git add` refuses ignored paths
  without `-f`). Options: **(a)** add `!.pack-tracker/id-map.json` to `.gitignore` in
  Commit 2 (recommended — honors the approved text + the committed-artifact freshness
  rationale; only the id-map is un-ignored, the rest of `.pack-tracker/` stays ignored);
  **(b)** drop the id-map clause from the §1.1/§1.3 staging lists (wording deviation from
  the approved design — needs your nod). Resolve before the Commit-1 coder spawns (D5).
- **OQ-2 — when to commit the live `tracker.toml` (+ id-map + first regenerated tree).**
  The committed-freshness-keys contract is fully effective only once the live Mode-3 state
  files are committed. That is a Pack-Chat state commit OUTSIDE these two commits
  (recommendation: after Commit 2 lands and at your direction, mindful that forward runs
  over the real tree fail loud at parse until the BD-094/BD-095 data fix). Nothing in
  Commits 1–2 stages `tracker.toml`.
- **OQ-3 — Commit-2 subject wording** (§3.3): architect's original vs this plan's
  verb-inclusive form — pick at the commit gate.

> **Empirical-Evidence Block EE-5 (id-map gitignored; tracker.toml untracked).**
> `CMD`: `git check-ignore -v tracker.toml .pack-tracker/id-map.json` + `git status --short`
> `OUT`: `.gitignore:12:.pack-tracker/  .pack-tracker/id-map.json` (id-map IS ignored);
> `tracker.toml` not matched by check-ignore and shows `?? tracker.toml` (untracked, not
> ignored). `AT`: HEAD `1c18b28`. `INTERP`: §1.1's staging clause conflicts with `.gitignore`
> for the id-map; tracker.toml is stageable but deliberately uncommitted. `CONCL`: SUPPORTED.

> **Empirical-Evidence Block EE-6 (live Mode-3 state).**
> `CMD`: `cat tracker.toml`
> `OUT`: `[mode] state = "tracker"`; `[migration] forward_complete = true`,
> `last_forward_run = "2026-06-11T20:03:47Z"`; no `[mirror]` table.
> `AT`: 2026-06-11. `INTERP`: the pack IS Mode 3 in the working tree; Check 29's live-config
> staleness leg soft-passes the no-[mirror] shape (verified in `_check_mirror_staleness`).
> `CONCL`: SUPPORTED.

> **Empirical-Evidence Block EE-7 (all host suites already CI-wired).**
> `CMD`: read `.github/workflows/validate-pack.yml` in full (296 lines).
> `OUT`: dedicated steps exist for `tracker-migrate-forward-test.sh`,
> `tracker-migrate-reverse-test.sh`, `tracker-provider-test.sh`,
> `tracker-bd130-doctor-wired-test.sh`, `test-validate-pack-checks-32-33-34.sh` (plus the
> rest of the battery enumerated in §2.6).
> `AT`: HEAD `1c18b28`. `INTERP`: extending these suites needs zero workflow edits.
> `CONCL`: SUPPORTED.

> **Empirical-Evidence Block EE-8 (working-tree state at planning time).**
> `CMD`: `git status --short`
> `OUT`: 12 modified tracker-lib/test files (`scripts/lib/tracker-*.sh`,
> `scripts/tests/tracker-*`, `test-validate-pack-check-40.sh`, roundtrip fixture) + 5
> untracked maintenance-docs reports + untracked `tracker.toml` — the casing+cycle cycle.
> `AT`: HEAD `1c18b28`, 2026-06-11. `INTERP`: D1's precondition is real; Commit-1/2 coders
> must wait for that commit. `CONCL`: SUPPORTED.

---

## 8. READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | File | Proof (path + line count, read this session) |
|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read in full via Read tool, 557 lines (§§0–9 incl. both ratified-text blocks, §5 R1–R8, §6 commit table). |
| 2 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | Read in full, 579 lines (incl. the complete `## Pack memory` section, lines 140–579). |
| 3 | `pack-ops/PACK-CHAT.md` | Read in full, 325 lines (incl. § "File access strategy" lines 44–57 and § "Keeping CLAUDE.md…current" + rule-change propagation procedure lines 300–325). |
| 4 | `/backlog/_rules.md` | Read in full, 95 lines. |
| 5 | `/changelog/_rules.md` | Read in full, 66 lines. |
| 6 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read in full, 15 lines; its conditional MUST-READ followed — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` read (lines 195–254 region; format template applied in §9). |
| 7 | Section-reads (verified directly, as instructed): `scripts/pack-tracker.sh` FULL (456 lines — verb table + dispatch); `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_decode_status` (231–290), `_tmr_emit_pack_tree` (1027–1098), `_tmr_emit_implementation_plan`/`_tmr_emit_status`/`_tmr_emit_changelog` (1100–1191), `_tmr_update_tracker_toml` (1199–1241), `tracker_migrate_reverse_run` orchestrator (1255–1646) + comparator invocation grep (line 626 inside `tracker_migrate_reverse_reconstruct`); `scripts/lib/tracker-edit.sh` FULL (347 lines — `tracker_edit_entry`); `scripts/lib/tracker-migrate-forward.sh` `mirror_only` arm (1340–1419); `scripts/lib/tracker-doctor.sh` FULL (304 lines); `scripts/tracker-migrate.sh` FULL (196 lines); `scripts/validate-pack.py` — Check 32′ region (3229–3478), Check 36 region (3978–4267), Check 40 patterns/allowlist (5140–5160 + allowlist greps), Check 42 (6530–6660), Check 44 header (7096–7160), `_check_mirror_staleness` (2772–2864), STREAMS (307–318); `pack-ops/PACK-AGENTS.md` FULL (223 lines); `.github/workflows/validate-pack.yml` FULL (296 lines); `.claude/skills/{planning,commit-discipline,architecture-review}/SKILL.md` FULL (32/173/47 lines); `pack-ops/.spawn-rule-manifest.txt` header + targeted greps; `tracker.toml`; test-suite surveys (`tracker-provider-test.sh` Group 4, `tracker-migrate-forward-test.sh` 4.5, `tracker-bd130-doctor-wired-test.sh` 215–244). |

No named document was derived rather than read; every file above was opened via Read/Bash
this session at HEAD `1c18b28` (+ the pending working-tree edits).

---

## 9. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Bash history this session: git verbs run were `git rev-parse HEAD`, `git log --oneline -8`, `git status --short`, `git check-ignore -v` — read-only only. Sole filesystem write: this plan doc (chunked `cat` heredoc writes to `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md`); zero `add/commit/push/tag/reset/stash/checkout` invocations. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op (no `rm -rf`, no `git rm`, no trusted-file overwrite — output path verified non-existent pre-write: `find . -name "PLAN-BD-204-MODE3-OPS-CONTRACT.md" -not -path "./.git/*"` → empty). No live GitHub call: zero `gh` invocations, zero GitHub MCP tool calls; all evidence is local reads. | COMPLIANT |
| preflight-stop-means-stop | Emitted before the first write chunk, verbatim: `PREFLIGHT: plan complete; 2 commits sequenced; about to Write to maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md`. No parent stop/halt/revert message received; work ran to completion. | COMPLIANT |
| agent-output-rules-applied-block | This table: 8 rows (one per "Rules in force" item), each with quoted command/output evidence; zero empty cells. The memory file's conditional MUST-READ honored: `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` read this session (format: per-rule table, name + quoted evidence + conclusion; empty = VIOLATED). | COMPLIANT |
| agents-read-rule-docs-in-full | §8 attestation: 6 named files read IN FULL with line counts (architecture 557; CLAUDE.md 579; PACK-CHAT.md 325; backlog/_rules.md 95; changelog/_rules.md 66; memory file 15) + every instructed section-read verified directly (§8 row 7 enumerates file + symbol + line ranges). | COMPLIANT |
| verify-full-ci-suite | §2.6 enumerates the COMPLETE workflow battery by suite name (both validate-job steps incl. the `PACK_VALIDATE_DEEP=1` run + all 50+ `tests:`-job steps + the fixture build/restore/verify sequence), captured from a full read of `.github/workflows/validate-pack.yml` (296 lines, EE-7); §3.5 binds Commit 2 to the identical enumeration plus the new legs. Neither commit's recipe is a subset. | COMPLIANT |
| user-prescriptive-authority | Ruling 1 (OQ-A YES) → §3.1 rows for `cmd_edit`/`cmd_new_entry` + legs 6/10. Ruling 2 (sequencing override) → §1 table row order + D3, with the architect-doc conflict FLAGGED explicitly (header + D3), not silently absorbed. Ruling 3 (six elements as designed) → §§2–5 implement all six with §-pointers; the single state-conflict found (id-map gitignore vs approved §1.1 text) is surfaced as OQ-1 with options, never silently deviated. | COMPLIANT |
| scope-deliverables-to-the-ask | Plan contains exactly the asked artifacts: ordered commit table (§1), per-commit recipe/verification/keyword/routing (§§2–3), ordering-dependency rationale (§4), test-leg inventory mapped to the validation element (§5), open questions (§7), this block (§9). Planner-added items are bounded realizations of approved design (leg 9 realizes §2's "pack-surface-only at v11.0"; HELP-FRAGMENT-PACK.md row realizes enumerate-encoding-surfaces) — no project-side work, no new checks beyond §4.2, no BD-opens. | COMPLIANT |

---

**End of PLAN-BD-204-MODE3-OPS-CONTRACT.md**
