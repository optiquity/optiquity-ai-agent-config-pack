# DESIGN — v10→v11 Migrator: Additive Antigravity Bundle Install (BD-221 C7)

**BD:** BD-221 — convert all Gemini-CLI support to Antigravity (v11.0 LAUNCH GATE). This design closes **POQ-C7-1** (the migrator-bundle-install gap surfaced by the C7 IMPL-REPORT §7).
**Author:** pack-architect (fresh, READ-ONLY). This `/tmp` file is the ONLY write — no repo edit, no git state change.
**Runtime regime (verified at startup, not from settings):** ISOLATED git worktree.
- `pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af3fa4dbb6c6ecb18`
- `git rev-parse HEAD` = `f945fb9b56e6796fdd5c355f673eada5ec8e7f14` (`f945fb9`) — matches expected.
- `git status --short` = exactly the 3 uncommitted C7 persona-contracts (`contract-greenfield.sh`, `contract-mid-dev.sh`, `contract-migration.sh`). CONFIRMED: this worktree holds C7's uncommitted persona-contract work.
**Date:** 2026-06-17.

**Scope guard.** READ-ONLY design. I confirm the gap empirically, enumerate the complete blast radius, design HOW the migrator additively installs the Antigravity bundle within the BD-119 framework, define the additive/idempotent/customization-preserving behavior, name the order vs the `.gemini/`-retire step, prove the install-map / Check 39/41/47 impact (measure-then-bound), specify the persona-contract revision, recommend the C7 commit structure, and name the manifest impact. I do NOT implement and run NO state-changing git verb.

---

## 0. EXECUTIVE SUMMARY (read first)

### 0.1 The gap (empirically confirmed)

The v10→v11 migrator (`scripts/migrate-v10-to-v11.sh`) does NOT install the Antigravity agent bundle `.agents-plugin/optiquity-agents/` into migrated projects. A fresh `init-project.sh` install DOES (`stage_s2_agents`, init-project.sh:448-467). A migrated v11 project therefore has loose `.claude/agents` + `.codex/agents` pack agents + `.agents/skills/` + `.agents/mcp_config.json` + `gemini-retired-docs/`, but NO Antigravity agent representation — defeating the conversion (decision a=A2 + decision d) for existing projects. The migrator's own comment at L429-430 already falsely claims the bundle "is installed additively by the steps above."

### 0.2 The fix in one paragraph

Add a single bundle-install block to `_v10_to_v11_install_v11_artifacts()` in `scripts/migrate-v10-to-v11.sh` (the existing S5 artifact-install sub-op of `migrator_post_dispatch_hook`), structurally mirroring `init-project.sh:stage_s2_agents` lines 448-467 but with the migrator's additive/non-clobber idiom: stage the whole pack bundle dir `cp -R`-style, but per-file additive so a pre-existing/customized `.agents-plugin/` is never overwritten; add a count guard. Order it to run BEFORE `_v10_to_v11_retire_gemini` (so the new Antigravity surface lands first, then the departing `.gemini/` is retired). Correct the false L429-430 comment. Widen the C7 migration persona-contract's assertion 2 from `claude codex` to also assert the bundle (the C7 IMPL-REPORT explicitly scoped it narrow to match the gap; with the gap closed the contract widens in lockstep). NO install-map / Check 39/41/47 change is required — the bundle is recursive-walk-covered by the `project-template/` inventory and is keyed off `init-project.sh` (already converted at C2), NOT off the migrator. The migration-output fixtures (`test-fixtures/v11-realistic-ot`) are NOT produced by the migrator, so the committed-fixture manifest does not change from this fix.

### 0.3 Blast radius at a glance

| # | File | Class | Disposition |
|---|---|---|---|
| 1 | `scripts/migrate-v10-to-v11.sh` | CHANGE | Add bundle-install block to `_v10_to_v11_install_v11_artifacts`; reorder install-vs-retire if needed (it is already correct — install runs before retire); fix the L429-430 comment. |
| 2 | `scripts/persona-contracts/contract-migration.sh` (uncommitted, in this worktree) | CHANGE | Widen assertion 2 to assert the bundle post-migrate; update the explanatory comment (drop the "migrator does not install the bundle" narration). |
| 3 | `scripts/tests/test-migrate-v10-to-v11.sh` (or the contract above) | CHANGE (recommend) | Add an explicit `.agents-plugin/optiquity-agents/` presence assertion to the wired migration integration test (the HARD migrator-test deliverable mirror; SHOULD). |
| 4 | install-map / `_CLIENT_INSTALLED_FILES` / cmd_update / Check 39/41/47 | KEEP (no change) | Bundle is recursive-walk-covered + keyed off init-project.sh; the migrator install adds no install-map row. Proven §4. |
| 5 | `test-fixtures/manifest.txt` | KEEP (verify-only) | No committed migration-output fixture's SHA changes from this fix (the migrator runs at test time against a copied fixture; it does not author a committed fixture). Coder regenerates per RC9 and confirms empty diff. |
| 6 | `scripts/migrate-v10-to-v11.sh` L429-430 comment | CHANGE | Make accurate (sub-item of #1). |

---

## 1. EMPIRICAL GAP CONFIRMATION

### EB-1 — The migrator does NOT install the bundle; a fresh init DOES

**Command (gap-confirm run):** copied `test-fixtures/v10-realistic-ot` → `/tmp/migrator-gap-confirm/migrate-target` (a clean git repo at the v10 baseline + FakeOT-customizations commit), ran `PACK=<worktree> bash scripts/migrate-v10-to-v11.sh <target>` (bare invocation → auto dry-run → paused at S3 trinity-sidecar reconciliation), resolved the 3 trinity sidecars via `.resolved` flags (accept-pack), ran `--resume` (exit 0).

**Output (post-migrate target inspection), verbatim:**
```
=== GAP CONFIRMATION: does .agents-plugin/optiquity-agents/ exist post-migrate? ===
ABSENT — bundle NOT installed (GAP CONFIRMED)

-- .agents/ tree --
-rw-r--r--  ... mcp_config.json
drwxr-xr-x  ... skills
-- .agents/skills (count) --
7
-- .claude/agents (count) --
17
-- .codex/agents (count) --
17
-- .agents-plugin present? --
ls: .agents-plugin: No such file or directory
-- gemini-retired-docs present? --
gemini-retired-docs
-- .gemini still present? --
(gone — retired)
```

**Fresh-init comparison (target shape), verbatim:**
```
=== TARGET SHAPE: fresh init .agents-plugin/ ===
PRESENT
-- bundle agents/*.md count --
16
-- pack-side bundle source agents/*.md count --
16
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the migrated project has loose `.claude/agents`(17) + `.codex/agents`(17) + `.agents/skills`(7) + `.agents/mcp_config.json` + `gemini-retired-docs/`, the `.gemini/` retired — but `.agents-plugin/` is ABSENT. A fresh init produces the bundle with 16 `agents/*.md`. The migrator is missing exactly the bundle install.
- **Conclusion:** SUPPORTED — the gap is real and reproducible.

### EB-2 — The bundle's exact target shape (byte-identity)

**Command:** `find <fresh-init>/.agents-plugin -type f | sort`; `diff -rq <pack-source>/.agents-plugin/optiquity-agents <fresh-init>/.agents-plugin/optiquity-agents`.

**Output, verbatim (file inventory + identity):**
```
.agents-plugin/optiquity-agents/agents/architect.md
.agents-plugin/optiquity-agents/agents/auditor-architecture.md
.agents-plugin/optiquity-agents/agents/auditor-code.md
.agents-plugin/optiquity-agents/agents/auditor-docs.md
.agents-plugin/optiquity-agents/agents/auditor-ops.md
.agents-plugin/optiquity-agents/agents/auditor-security.md
.agents-plugin/optiquity-agents/agents/auditor-tests.md
.agents-plugin/optiquity-agents/agents/auditor-ui.md
.agents-plugin/optiquity-agents/agents/auditor.md
.agents-plugin/optiquity-agents/agents/coder.md
.agents-plugin/optiquity-agents/agents/docs-researcher.md
.agents-plugin/optiquity-agents/agents/grpc-schema.md
.agents-plugin/optiquity-agents/agents/planner.md
.agents-plugin/optiquity-agents/agents/repo-ops.md
.agents-plugin/optiquity-agents/agents/reviewer.md
.agents-plugin/optiquity-agents/agents/tester.md
.agents-plugin/optiquity-agents/plugin.json
.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md
=== Byte-identity: fresh-init bundle vs pack source ===
IDENTICAL (fresh init == pack source)
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the target bundle = the pack source `project-template/.agents-plugin/optiquity-agents/` copied verbatim: **18 files = 16 `agents/*.md` + `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md`**. A fresh init is byte-identical to the pack source (init does a plain `cp -R`, no transform). The migrator must produce the same.
- **Conclusion:** SUPPORTED — target shape is the verbatim pack source bundle (16 agents).

### EB-3 — init-project.sh's reference install shape

**Command:** read `scripts/init-project.sh:448-467`.

**Output, verbatim (the reference):**
```bash
    # Antigravity agents ship as a plugin BUNDLE (not loose) — stage the
    # whole client bundle dir.
    local bundle_src="$PACK/project-template/.agents-plugin/optiquity-agents"
    local bundle_dst="$TARGET/.agents-plugin/optiquity-agents"
    [[ -d "$bundle_src" ]] || fail_stage S2 "pack source missing: $bundle_src"
    mkdir -p "$TARGET/.agents-plugin"
    cp -R "$bundle_src" "$TARGET/.agents-plugin/"
    # Verify agent counts match pack
    local pack_count dst_count
    pack_count=$(find "$PACK/project-template/.claude/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    ...
    local bundle_count
    bundle_count=$(find "$bundle_dst/agents" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    (( bundle_count == pack_count )) || \
        fail_stage S2 "agent count mismatch: .agents-plugin/optiquity-agents/agents has $bundle_count, expected $pack_count"
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** init uses a whole-dir `cp -R` + a count guard against the loose-agent count (16). Init is a FRESH install (no pre-existing target), so a plain `cp -R` over an empty target is safe. The migrator runs against an EXISTING project — so it CANNOT blindly `cp -R` over a possibly-customized bundle; it must be additive (§3.2).
- **Conclusion:** SUPPORTED — reference shape is `cp -R` whole-bundle + count guard; the migrator must adapt this to its additive idiom.

### EB-4 — The migrator's L429-430 comment is FALSE

**Command:** read `scripts/migrate-v10-to-v11.sh:425-444`.

**Output, verbatim (the false claim):**
```
# The pack-standard v11 Antigravity surfaces (`.agents/skills/` distributed
# loose, the agent plugin bundle, `.agents/mcp_config.json`) are installed
# additively by the steps above. This step handles a DEPARTING `.gemini/`
# tree in the client project:
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the comment claims the bundle "is installed additively by the steps above" — but EB-1 proves it is NOT. The comment must be corrected as part of the fix (it lives in the `_v10_to_v11_retire_gemini` docstring).
- **Conclusion:** SUPPORTED — the comment is inaccurate and is itself a fix locus.

### EB-5 — The BD-119 framework helper ALREADY declares the bundle a v11 surface

**Command:** read `migrator_target_surface_for_version()` v11 case in `scripts/lib/migrator-core.sh:524-560`; read its wired test assertion `scripts/test-migrator-core.sh:388-407`.

**Output, verbatim (the helper's v11 list + the test):**
```
# core helper v11 case (migrator-core.sh):
.claude/agents
.codex/agents
.agents-plugin/optiquity-agents/agents
.agents/skills/pack-help/SKILL.md
# wired test (test-migrator-core.sh:400):
   && "$out" == *".agents-plugin/optiquity-agents/agents"* \
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the framework's surface-list helper (the BD-160-consumed `migrator_target_surface_for_version`) ALREADY lists `.agents-plugin/optiquity-agents/agents` as a v11 surface, and a wired test asserts it. This is a self-inconsistency: the framework declares the bundle a v11 surface but the v10→v11 adapter's install step never lays it down. Closing the gap makes the migrator consistent with its own framework helper. NO change to the helper or its test is needed (they are already correct).
- **Conclusion:** SUPPORTED — the framework already treats the bundle as a v11 surface; the adapter install is the only missing piece.

### EB-6 — The migrator install runs BEFORE the gemini-retire step (order is already correct)

**Command:** read `migrator_post_dispatch_hook` sub-op order in `scripts/migrate-v10-to-v11.sh:143-164`.

**Output, verbatim:**
```
    _v10_to_v11_rename_implementation_plan
    _v10_to_v11_relocate_legacy_docs
    _v10_to_v11_install_v11_artifacts        # ← bundle install belongs HERE
    _v10_to_v11_retire_gemini                # ← runs AFTER install
    _v10_to_v11_rename_python_architecture_refs
    _v10_to_v11_translate_capability_tokens
    _v10_to_v11_decompose_streams
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** `_v10_to_v11_install_v11_artifacts` (where the bundle-install belongs) already runs BEFORE `_v10_to_v11_retire_gemini`. The Antigravity surface lands first, then the departing `.gemini/` is retired. NO reorder needed; the install-vs-retire ordering is already correct. (The bundle target `.agents-plugin/` and the departing `.gemini/` are disjoint paths, so there is no path collision either way — order is correctness-neutral here, but install-before-retire is the cleanest reading.)
- **Conclusion:** SUPPORTED — order is already correct; the fix adds a block to the existing install sub-op.

---

## 2. FRAMEWORK FIT (BD-119) — WHERE THE INSTALL LIVES

### 2.1 The two framework-legal install mechanisms

The BD-119 framework (`ARCHITECTURE-BD-119.md` §3.2/§4.3) provides two ways to add a file/dir to a migrated project:
1. **Declarative `migrator_artifact_installs()`** — the canonical additive (`add`-action) hook; the engine writes only if the target is absent, and records a BD-088 disposition. The framework-preferred path for future adapters (§4.3, M9).
2. **`migrator_post_dispatch_hook()`** — an imperative escape hatch. The v10→v11 adapter ALREADY uses this for ALL its additive installs (`_v10_to_v11_install_v11_artifacts`), with a documented "monolith-faithful silent (no-record) semantics" rationale (migrate-v10-to-v11.sh:21-42).

### 2.2 Recommendation: extend the existing `_v10_to_v11_install_v11_artifacts` (post-dispatch hook), NOT the declarative hook

**Rationale (consistency + framework-legality + scope):**
- The v10→v11 adapter has DELIBERATELY chosen the post-dispatch-hook path for every additive install (HELP-FRAGMENT, ISSUE_TEMPLATE forms, pool-distributed pack-help, the per-CLI net-new skills, the per-entry templates). The architectural note at migrate-v10-to-v11.sh:21-42 documents this as an intentional v10→v11 choice (monolith-faithful stdout + no-record semantics gated by the behavior-preservation harness). Adding the bundle install via `migrator_artifact_installs()` would split the bundle's install across two mechanisms in the same adapter — an inconsistency, and a `migrator_artifact_installs` row would emit a BD-088 disposition that the other artifact installs deliberately do NOT, breaking the adapter's uniform no-record contract for additive installs.
- This is the SAME class of install as the loose `.claude/agents` + `.codex/agents` (which migrate via `migrator_directory_sweeps` for already-existing v10 agents) AND the net-new per-CLI skills (which install via `_v10_to_v11_install_v11_artifacts`). The bundle is a NET-NEW v11 surface (it did not exist in v10), exactly like the net-new skills — so it belongs alongside them in `_v10_to_v11_install_v11_artifacts`, not in the directory-sweep (sweeps migrate v10-existing dirs; the v10 fixture has no `.agents-plugin/`).
- **BD-119-legal:** `migrator_post_dispatch_hook` is a sanctioned framework hook (§3.2 "Optional adapter-declared functions"). Using it does NOT bypass the framework — the framework's safety contract (preflight, backup, dry-run short-circuit, idempotency) still wraps the hook. The fix does NOT copy-and-rewrite the migrator (the regression CLAUDE.md warns against); it adds ~12 lines to one existing adapter sub-op.

### 2.3 Why NOT a directory sweep

`migrator_directory_sweeps()` iterates a pack dir and three-way-dispatches EXISTING target files of that class (the v10→v11 sweep handles `.claude/agents` + `.codex/agents` because a v10 project HAS those dirs). A v10 project has NO `.agents-plugin/` — there is nothing to sweep/three-way-merge. The bundle is a net-new ADD, not a transform-existing. Putting it in the sweep would (a) mis-model it as a transform and (b) require a `pack-agent`-class three-way against an absent base — the wrong contract. Net-new → artifact-install. CONFIRMED by the existing adapter: the net-new v11 per-CLI skills install via `_v10_to_v11_install_v11_artifacts`, not via a sweep.

### 2.4 The dry-run path is already handled

`migrator_post_dispatch_hook` short-circuits in dry-run mode (migrate-v10-to-v11.sh:139-142: `if _migrator_is_dryrun; then info "[dry-run] would run ..."; return 0; fi`). The new bundle-install block lives inside `_v10_to_v11_install_v11_artifacts`, which is only called on the non-dry-run branch (L145) — so dry-run already skips it with no extra code. The coder SHOULD extend the dry-run `info` line text to mention the bundle install for accuracy (cosmetic, not load-bearing).

---

## 3. THE FIX — DESIGN OF THE BUNDLE-INSTALL BLOCK

### 3.1 Placement

Add the block inside `_v10_to_v11_install_v11_artifacts()` (migrate-v10-to-v11.sh:286-423), alongside the other net-new v11 surface installs. Recommend placing it immediately after the loose-agent-adjacent installs and BEFORE (or after) the per-CLI net-new skill loop — placement within the function is correctness-neutral (the bundle path is disjoint from every other install target); the coder picks a readable spot. The function as a whole runs before `_v10_to_v11_retire_gemini` (EB-6), so the Antigravity surface lands before the `.gemini/` retirement.

### 3.2 Behavior contract — additive, non-destructive, idempotent, customization-preserving

The install MUST satisfy four properties (success criteria). The block is structurally the init-project reference (EB-3) re-expressed in the migrator's additive idiom (matching the per-file `[[ ! -f $TARGET/... ]]` guard the other artifact installs use):

1. **Additive (writes the net-new bundle):** when the target has NO `.agents-plugin/optiquity-agents/`, copy the WHOLE pack bundle dir verbatim from `$PACK/project-template/.agents-plugin/optiquity-agents/` so the result is byte-identical to a fresh init (EB-2).

2. **Non-destructive / non-clobber (customization-preserve contract):** per-file additive — copy each pack bundle file ONLY if the destination file is absent (`[[ ! -f "$dest" ]]`), so a pre-existing OR project-customized `.agents-plugin/` file is NEVER overwritten. This matches the documented contract of every other artifact install in this function (e.g. the net-new skill loop at L415-421: `if [[ ! -f "$skill_dest" ]]; then ... cp ...; fi`) and the BD-088 `add`-semantics (architecture §4.3: "writes to the destination only if the target path does not already exist. A user who hand-created the file is not clobbered"). **Behavior on a pre-existing/customized bundle:** pack files absent at the target are added; files the project already has (pack-shipped or hand-edited) are LEFT UNTOUCHED — the project keeps its version. (This is the project-owned-file preservation posture; the BD-088 truthful-report mechanism surfaces any pack/project divergence on a later pack version-bump via `init-project.sh --update`, the same as for every other additive install in this function.)

3. **Idempotent (safe re-run):** a second migrator run finds every bundle file already present → the per-file `[[ ! -f ]]` guard skips them all → no-op. This satisfies the "EITHER Gemini OR Antigravity already present" idempotency the retire step already documents (migrate-v10-to-v11.sh:446-451): if `.agents-plugin/` is already present (an already-migrated or fresh-Antigravity project), the install respects it and adds nothing.

4. **Count guard (parity with init):** after the copy, verify the installed bundle agent count equals the pack bundle agent count (mirroring init-project.sh:464-467), and `fail_stage S5` on mismatch. **Caveat (non-clobber interaction):** because the install is non-clobber, a project that had a PARTIAL/customized `.agents-plugin/agents/` (e.g. deleted one agent, added an `x-custom`) would legitimately diverge from the pack count. The guard MUST therefore assert that every PACK bundle agent is PRESENT at the target (no pack agent missing), NOT strict count-equality — i.e. verify `for each pack agent file: target has it`, allowing the target to have ADDITIONAL (project-custom) agents. This preserves both "no pack agent silently skipped" and "project customs never rejected." (Init's strict `==` is fine for init because init writes into an empty target; the migrator needs the superset check.) The coder authors the exact guard; the contract is: **every pack bundle file is present post-install; project extras are allowed.**

### 3.3 Pseudo-shape (the SHAPE, not a copy directive — the coder authors exact text within BD-119 idiom)

```
# Antigravity agent plugin BUNDLE — net-new v11 surface (decision a=A2 +
# decision d). Additive + non-clobber: copy each pack bundle file iff the
# destination is absent, so a pre-existing/customized .agents-plugin/ is
# never overwritten. Mirrors init-project.sh stage_s2_agents (the fresh-
# install path) in the migrator's additive idiom.
local bundle_src="$PACK/project-template/.agents-plugin/optiquity-agents"
if [[ -d "$bundle_src" ]]; then
    # per-file additive walk of the whole bundle subtree
    while IFS= read -r pack_file; do
        rel="${pack_file#"$bundle_src/"}"
        dest="$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/$rel"
        if [[ ! -f "$dest" ]]; then
            mkdir -p "$(dirname "$dest")"
            cp "$pack_file" "$dest"
        fi
    done < <(find "$bundle_src" -type f)
    # superset count guard: every pack bundle agent present at target
    # (project extras allowed) — fail_stage S5 on any missing pack agent.
fi
```

(The exact `find`/loop form, the count-guard expression, and the banner wording are the coder's — within the framework's `say`/`info`/`fail_stage` helper set and the function's existing style.)

### 3.4 Dependency direction (confirmed correct)

**EB-7 — no pack operation depends on the client-installed bundle.**
**Command:** `grep -rn "agents-plugin/optiquity-agents" scripts --include=*.sh | grep -v project-template`.
**Output (the writers/readers), verbatim summary:** every match writes to `$TARGET/.agents-plugin/...` (init-project.sh:451, the new migrator block) or reads from `$PACK/project-template/.agents-plugin/...` (the source), or is a test asserting a migrated/init target. No pack operation `source`s or executes a client-installed bundle file at runtime.
- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the bundle is a pure CLIENT deliverable copied pack→client. The migrator's install does NOT invert any pack/project dependency (pack source → client target is the correct direction per `dependency-direction-placement`). The bundle is NOT a `_SANCTIONED_PACK_SIDE_SHIPPED` candidate (it lives under `project-template/`, recursive-walk-covered; it is not a pack-side script a client invokes).
- **Conclusion:** SUPPORTED — dependency direction is correct; Check 47's frozen 2-tuple is UNMOVED.

---

## 4. INSTALL-MAP / CHECK 39/41/47 IMPACT (measure-then-bound)

Per `ci-guard-design-measure-then-bound`: I measured each affected check against the live tree before concluding. The headline result: **NO install-map row, cmd_update entry, `_CLIENT_INSTALLED_FILES` row, or `_SANCTIONED_PACK_SIDE_SHIPPED` change is required.**

### EB-8 — The bundle is recursive-walk-covered, NOT a `_CLIENT_INSTALLED_FILES` row

**Command:** read the `_CLIENT_INSTALLED_FILES_START/END` block in `scripts/init-project.sh:1388-1421` + the bundle comment at L1360-1363.

**Output, verbatim (the bundle is intentionally NOT a START/END row):**
```
#   * project-template/.agents-plugin/optiquity-agents/   (Antigravity plugin BUNDLE)
#       -> .agents-plugin/optiquity-agents/          [S2 bundle stage + _cmd_update_iter_dir]
#       (recursive-walk-covered by the project-template/ inventory; no
#        per-file START/END rows)
```
The `_CLIENT_INSTALLED_FILES_START ... _END` block (the rows Check 41 parses) does NOT list the bundle. `grep -n "agents-plugin" validate-pack.py` shows the bundle appears in the two-class agent checks (52/55/56/57) + the Check-43 rationale strings + the recursive-walk inventory (L364/L700) — never as a `_CLIENT_INSTALLED_FILES` row.

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** Check 41 (`_CLIENT_INSTALLED_FILES` self-doc integrity) parses the START/END block FROM `init-project.sh`. The bundle is deliberately NOT a row there — it is covered by the `project-template/` recursive inventory walk. So Check 41 has nothing to add for the migrator bundle install.
- **Conclusion:** SUPPORTED — no `_CLIENT_INSTALLED_FILES` row needed.

### EB-9 — Check 39 (cmd_update symmetry) is keyed off init-project.sh, already converted at C2

**Command:** read `check_cmd_update_symmetry` (validate-pack.py:4890+) + the bundle's cmd_update leg at init-project.sh:1316-1317.

**Output, verbatim (the bundle's cmd_update directory leg + Check 39's scope):**
```
# init-project.sh:1316-1317 (cmd_update, the --update path):
    _cmd_update_iter_dir "project-template/.agents-plugin/optiquity-agents/agents" \
        ".agents-plugin/optiquity-agents/agents" pack-agent
# Check 39 docstring: "Bidirectional symmetry between scripts/init-project.sh
#   cmd_update entries=() array and project-template surface."
#   Forward: every project-template/docs/pack/*.md has a cmd_update mapping.
#   Reverse: every cmd_update entry's pack_relpath resolves at HEAD.
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** Check 39 compares `init-project.sh`'s `cmd_update` array against `project-template/docs/pack/*.md` — it does NOT inspect `migrate-v10-to-v11.sh` at all. The bundle's update path is the `_cmd_update_iter_dir` DIRECTORY leg in init-project.sh (already present, converted at C2), not an `entries=()` row, so Check 39 is unaffected by both the bundle and the migrator. The migrator install changes NOTHING Check 39 reads.
- **Conclusion:** SUPPORTED — Check 39 needs no change; it is init-project-keyed.

### EB-10 — Check 41 parses init-project.sh, not the migrator; Check 47's tuple is frozen + unmoved

**Command:** read `_SANCTIONED_PACK_SIDE_SHIPPED` (validate-pack.py:4326) + the Check-41 parse note (L6221 "Parse `_CLIENT_INSTALLED_FILES` block from `scripts/init-project.sh`").

**Output, verbatim (the frozen 2-tuple):**
```
_SANCTIONED_PACK_SIDE_SHIPPED = (
    # ... (CLAUDE.md ## Pack memory: exactly {scripts/lib/detect.sh, scripts/pack-help.sh})
```

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** Check 47 enforces install-map↔constant set-equality for PACK-SIDE-shipped files (files outside `project-template/` that ship to clients). The bundle lives UNDER `project-template/` → it is NOT a pack-side-shipped file → it is not a Check-47 concern at all. The frozen 2-tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}` is UNMOVED. Check 41 parses `init-project.sh`'s START/END block (not the migrator), so the migrator install adds no Check-41 row.
- **Conclusion:** SUPPORTED — Check 47 tuple unmoved (no architect+user sign-off needed); Check 41 unaffected.

### 4.1 Measure-then-bound conclusion table

| Check / constant | Measured relationship to the migrator-bundle-install | Disposition |
|---|---|---|
| Check 39 (cmd_update symmetry) | Keyed off `init-project.sh` cmd_update array + `docs/pack/*.md`. Bundle uses a `_cmd_update_iter_dir` dir leg (init-project, C2). Migrator not read. | NO CHANGE |
| Check 41 (`_CLIENT_INSTALLED_FILES` self-doc) | Parses init-project START/END block; bundle is recursive-walk-covered, intentionally not a row. | NO CHANGE |
| Check 47 (`_SANCTIONED_PACK_SIDE_SHIPPED` set-equality) | Pack-side-shipped files only; bundle is `project-template/`-resident. Frozen 2-tuple unmoved. | NO CHANGE (no sign-off) |
| Checks 5/27/52/55/56/57 (agent two-class + counts + canonical phrases) | Measure the bundle templates (pack-side `project-template/.agents-plugin/.../agents/*.md`); already recast/landed (C1/C4/C5). Migrator install does not change the PACK bundle, only adds it to a client TARGET (which validate-pack does not scan). | NO CHANGE |

There is NO allowlist to size, NO new install-map row, NO new constant entry. The fix is install-LOGIC only; the install-MAP (and every check that reads it) is keyed off `init-project.sh`, which already accounts for the bundle. The fix introduces ZERO new validate-pack red and clears ZERO (the gap was a silent behavioral hole, not a validate-pack-detected one — validate-pack does not run the migrator against a target).

### 4.2 Why validate-pack never caught the gap (and the test-layer remedy)

`validate-pack.py` is a STATIC pack-repo structural checker — it never runs the migrator against a target tree, so it cannot observe "the migrator failed to install X." The gap is a RUNTIME behavioral hole, caught only by exercising the migrator (the C7 persona-contract / migration integration test). Per `enumerate-encoding-surfaces`, the encoding surface that pins this behavior is the RUNTIME test layer (persona-contract + `test-migrate-v10-to-v11.sh`), NOT a validator. The fix's test coverage therefore lands in those runtime tests (§5), not in a new validate-pack check.

---

## 5. THE PERSONA-CONTRACT + TEST REVISION (lockstep with the migrator fix)

### 5.1 The C7 migration contract scoped assertion 2 NARROW to match the gap — now it widens

**EB-11 — the contract's current assertion 2 + its narration.**
**Command:** read `scripts/persona-contracts/contract-migration.sh:156-181`.
**Output, verbatim (the scoped loop + the gap narration):**
```
# ... Antigravity agents ship as a plugin
# BUNDLE (.agents-plugin/optiquity-agents/agents/); the v10→v11 migrator
# does not currently install that bundle additively, so there is no
# loose third-CLI pack-agent surface to assert here.
for tool in claude codex; do
    ... assert .${tool}/agents/ present ...
done
```
- **HEAD/date:** `f945fb9`, 2026-06-17 (uncommitted in this worktree).
- **Interpretation:** the C7 IMPL-REPORT §7 (POQ-C7-1) explicitly states the contract was scoped `claude codex` to match the migrator's ACTUAL (gap) behavior, and "If the migrator is later changed to install the bundle, this contract's assertion 2 should be widened in lockstep." This fix is that change.
- **Conclusion:** SUPPORTED — the contract must widen in the SAME cycle as the migrator fix.

### 5.2 Required contract revision (assertion 2)

In `contract-migration.sh` assertion 2:
- **ADD** a dedicated Antigravity-bundle assertion block (mirroring the bundle assertion the SAME contract's other personas now carry, and mirroring the loose-agent check): assert that every pack bundle agent `project-template/.agents-plugin/optiquity-agents/agents/*.md` is present at `$SANDBOX/.agents-plugin/optiquity-agents/agents/` post-migrate (superset-tolerant per §3.2 property 4), plus `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md` present.
- **REWRITE** the explanatory comment: drop "the v10→v11 migrator does not currently install that bundle additively, so there is no loose third-CLI pack-agent surface to assert here" → replace with "Antigravity agents ship as a plugin BUNDLE; the v10→v11 migrator installs it additively (additive, non-clobber), asserted below."
- KEEP the existing `claude codex` loose-agent loop unchanged (it is still correct — loose agents migrate via the directory sweep).

### 5.3 Interaction with assertion 3b (x-agent preservation) — CONFIRM no conflict

**EB-12 — 3b asserts the x-custom is preserved in `gemini-retired-docs/`, not in the bundle.**
**Command:** read `contract-migration.sh:283-299`.
**Output, verbatim (the third-CLI x-agent preservation assertion):**
```
# 3b (third CLI): ... The v10→v11 migrator retires the whole departing
# `.gemini/` tree into `gemini-retired-docs/` ... so the project-owned
# x-agent is PRESERVED there, not lost.
... find "$SANDBOX/gemini-retired-docs" -name "x-fakeot-domain.md" ...
```
- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the v10 fixture's third-CLI x-custom (`x-fakeot-domain`) lived under the departing `.gemini/agents/`. The migrator retires it into `gemini-retired-docs/` (it is NOT relocated into the new `.agents-plugin/` bundle — the bundle install is additive of PACK files only, never of departing-`.gemini` customs). So the bundle install does NOT change 3b's expectation: the x-custom is still preserved in `gemini-retired-docs/`, and the new bundle contains only the 16 pack agents. NO conflict; assertion 3b stays as-is. (The bundle install is non-clobber and copies only pack files; it never touches `gemini-retired-docs/` or `.gemini/`.)
- **Conclusion:** SUPPORTED — 3b is unaffected; the two behaviors are orthogonal (pack-agent bundle add vs departing-custom retirement).

### 5.4 Wired integration-test coverage (SHOULD — the HARD-deliverable mirror)

The planner plan's C3 already names a "HARD migrator-test deliverable" for the `gemini-retired-docs/` behavior in `test-customization-preserve.sh` / the migrate test. By symmetry + `enumerate-encoding-surfaces`, the bundle-install behavior SHOULD also be pinned by the wired migration integration test (`scripts/tests/test-migrate-v10-to-v11.sh`), not only by the persona-contract:
- ADD an assertion to `test-migrate-v10-to-v11.sh` that `.agents-plugin/optiquity-agents/agents/<one known agent>.md` (e.g. `coder.md`) + `plugin.json` are present post-migrate. This is the same wired test that already asserts `.agents/skills/pack-help/SKILL.md` (L149-150) — adding the bundle assertion keeps the two net-new v11 surfaces symmetrically covered.
- This is a SHOULD (the persona-contract already covers it); the planner/Pack-Chat decides whether to fold it into the C7 cycle (recommended — it is wired CI, runs at the same green-point) or note it. Given `no-deferral-without-user-direction` (v11.0 unlaunched), the default is to land it in the C7 cycle.

---

## 6. COMPLETE BLAST RADIUS (every file, categorized + dispositioned, with evidence)

Per `researcher-maps-blast-radius-before-architect`: the complete enumeration of what this fix touches. Counts reconciled against the grep/measurement evidence above.

| # | File | KEEP / CHANGE | Disposition + evidence |
|---|---|---|---|
| 1 | `scripts/migrate-v10-to-v11.sh` — `_v10_to_v11_install_v11_artifacts()` | **CHANGE** | ADD the additive non-clobber bundle-install block (§3). EB-1 (gap), EB-3 (reference shape), EB-6 (runs before retire). |
| 2 | `scripts/migrate-v10-to-v11.sh` — L429-430 retire docstring | **CHANGE** | Correct the false "installed additively by the steps above" claim (it is true ONCE #1 lands; reword to match the now-true state). EB-4. |
| 3 | `scripts/migrate-v10-to-v11.sh` — dry-run `info` line (L140) | **CHANGE (cosmetic)** | Mention the bundle install in the dry-run "would run …" message for accuracy. §2.4. |
| 4 | `scripts/persona-contracts/contract-migration.sh` (uncommitted, this worktree) | **CHANGE** | Widen assertion 2 to assert the bundle; rewrite the gap-narration comment. §5.1-5.2. EB-11. |
| 5 | `scripts/tests/test-migrate-v10-to-v11.sh` | **CHANGE (SHOULD)** | ADD a bundle-presence assertion (symmetry with the pack-help-skill assertion at L149-150). §5.4. |
| 6 | `scripts/persona-contracts/contract-{greenfield,mid-dev}.sh` (uncommitted) | **KEEP** | These are FRESH-install personas (init-project), which ALREADY install + assert the bundle (the C7 IMPL-REPORT §4a/§4b shows greenfield + mid-dev assert `.agents-plugin/optiquity-agents/agents/`). Only the MIGRATION persona was scoped narrow. No change. |
| 7 | `scripts/init-project.sh` (install-map: `_CLIENT_INSTALLED_FILES`, cmd_update, blast_radius_sweep) | **KEEP** | Bundle recursive-walk-covered + cmd_update dir-leg already present (C2). EB-8, EB-9, EB-10. NO row change. |
| 8 | `scripts/validate-pack.py` (Checks 5/27/39/41/47/52/55/56/57 + constants) | **KEEP** | None read the migrator; all keyed off pack-side surfaces / init-project. §4.1. NO change. |
| 9 | `scripts/lib/migrator-core.sh` (`migrator_target_surface_for_version` v11) + `scripts/test-migrator-core.sh` | **KEEP** | ALREADY list `.agents-plugin/optiquity-agents/agents` as a v11 surface (EB-5). The fix makes the migrator consistent with this existing declaration. NO change. |
| 10 | `scripts/lib/migrator-stages.sh`, `migrator-manifest.sh`, `customization-preserve.sh` | **KEEP** | The fix uses the existing post-dispatch hook (no declarative-hook/sweep extension), so no framework-lib change. §2.2-2.3. |
| 11 | `test-fixtures/manifest.txt` | **KEEP (verify-only)** | No committed migration-OUTPUT fixture is authored by the migrator; the migrator runs at test time against a COPIED v10 fixture in a sandbox. §7 / EB-13. Coder regenerates per RC9 and confirms empty diff. |
| 12 | `supporting-docs/MIGRATION-v10-to-v11.md`, `SETUP-EXISTING.md` (client migration docs) | **DEFER to their own commit (C-series), not C7** | These prose docs describe migrator OUTPUT and already convert under the planner's C-series docs commits (DESIGN §5.8). If they assert a specific post-migrate surface list, they SHOULD name the bundle — but that is a DOCS-commit edit (`project-only`/cross-surface), NOT a `pack-only` C7 edit. Flag to Pack Chat: ensure the client-migration docs name `.agents-plugin/` in the migrated-output description when those docs land. (Not in this fix's scope-keyword.) |

**Blast-radius count reconciliation:** 5 CHANGE loci (#1, #2, #3 within one file = the migrator; #4 the contract; #5 the wired test), all `pack-only` paths (`scripts/**`). 7 KEEP/verify/defer categories. The migrator file carries 3 sub-edits (block + comment + dry-run line) but is ONE file. No `project-template/` or `supporting-docs/` path is in the `pack-only` C7 commit.

---

## 7. MANIFEST IMPACT

### EB-13 — No committed migration-output fixture's SHA changes

**Command:** the migration persona (`build.sh --for-contract migration`) and `test-migrate-v10-to-v11.sh` COPY the committed `v10-realistic-ot` fixture into a sandbox and run the migrator there; the migrator's OUTPUT is never committed. The committed fixtures are `v10-minimal`, `v10-realistic-ot` (migration INPUTS, Gemini-shaped per carve-out i), and `v11-realistic-ot` (the Antigravity TARGET shape, authored by `_build_realistic_for_version v11` in `build.sh` — NOT by the migrator).

- **HEAD/date:** `f945fb9`, 2026-06-17.
- **Interpretation:** the migrator-bundle-install changes migrator RUNTIME behavior against a sandbox copy; it does NOT change any committed fixture's content. `v11-realistic-ot` is built by `build.sh`'s init-based path (which ALREADY installs the bundle — the fixture already HAS `.agents-plugin/` if it includes agents), not by the migrator. Therefore the fix does NOT alter any committed fixture SHA.
- **Conclusion:** SUPPORTED — no fixture SHA change is EXPECTED from this fix.

### 7.1 Manifest regen is still mandatory (RC9), but expected empty

The C7 commit touches `scripts/**` (a v11-surface per `regenerate-manifest-v11-surface`). The coder MUST run `bash test-fixtures/build.sh --all --clean` and `git diff --stat test-fixtures/manifest.txt`. **Expected: empty diff** (EB-13). If the diff is NON-empty, that is a SIGNAL that a fixture shape unexpectedly changed — the coder STOPS and surfaces it (do NOT silently stage a manifest delta the design did not predict). The C7 IMPL-REPORT already established the persona-contracts are not fixture inputs (manifest unchanged at C7 base); adding the migrator block does not change that.

---

## 8. C7 COMMIT STRUCTURE RECOMMENDATION

### 8.1 Recommendation: ONE commit (the migrator fix + the contract widening land together in C7's worktree)

The user's framing is that the migrator fix lands WITHIN C7's cycle (this worktree is reused, not abandoned). I recommend the migrator fix + the migration-contract widening + the wired-test assertion land as **ONE commit** (C7 absorbs the migrator fix), for these reasons:

1. **Lockstep correctness (`enumerate-encoding-surfaces`).** The migrator behavior and the contract that ASSERTS it are an encoding pair — the contract's assertion 2 is the test that pins the migrator's bundle install. Splitting them creates a window where either (a) the migrator installs the bundle but the contract still asserts the gap (`claude codex` only — under-asserting, a coverage hole), or (b) the contract asserts the bundle but the migrator doesn't install it (the contract goes RED). Both are asymmetric-coverage defects the rule forbids. They MUST move together.

2. **C7 is already the persona-contract cycle.** C7's deliverable is the 3 contracts; the migration contract is one of them. The migrator fix is the behavior the migration contract now asserts. Folding the migrator fix into C7 keeps "the migrator behavior + the contract that pins it" in one auditable unit — exactly the C7 scope (it makes the migration contract's assertion 2 TRUE-and-asserted rather than narrowed-to-match-a-gap).

3. **Single scope keyword (`pack-only`) — Check 36 clean.** Every CHANGE locus is under `scripts/**` (`scripts/migrate-v10-to-v11.sh`, `scripts/persona-contracts/contract-migration.sh`, `scripts/tests/test-migrate-v10-to-v11.sh`). None touches `project-template/` or `supporting-docs/`. So the commit is cleanly `pack-only` — Check 36 verifies `git diff --name-only` is all pack-side. The C7 IMPL-REPORT already declared C7 `pack-only`; this fix stays within that keyword. **No keyword conflict, no mixed-scope.** (The client-migration DOCS that also describe the bundle output — blast-radius #12 — are a SEPARATE `project-only`/cross-surface docs commit in the planner's C-series; they MUST NOT be pulled into this `pack-only` C7 commit, or Check 36 fails.)

### 8.2 Why NOT a coupled pair (two commits in the same worktree)

A coupled pair (commit A = migrator + comment; commit B = contract + test) would (a) violate the lockstep pairing in §8.1.1 between the two commits, and (b) gain nothing — both are `pack-only`, both land at the same green-point, both are one cycle's worth of review. One commit is the simpler, lockstep-correct unit. (Design-elegance: fewer commits, fewer special cases.)

### 8.3 Commit message + cycle

- **Subject (within the approved `fix:` suffix vocabulary):** since this lands inside C7's cycle and binds to BD-221, use the per-BD inline-fix form, e.g. `fix: v11 — BD-221 migrator additively installs Antigravity bundle (C7) (pack-only)` — verify the exact form against CLAUDE.md "Approved suffixes for the `fix:` form" + the `commit-subject-keyword-token-trap` (only the `pack-only` token may appear; describe nothing with another scope keyword). Pack Chat owns the final subject.
- **Cycle:** fresh pack-coder (per-commit fresh-coder) implements the §3/§5 deliverables in THIS worktree → bounded review/fix cycle → user commit-gate. The grep-zero gates (DESIGN §6.1) re-run at PREFLIGHT (the migrator + contract edits must leave only KEEP-legitimate `gemini` tokens — the migration contract's `gemini-retired-docs/` real-surface refs + `GEMINI.md` trinity refs + the v10-source carve-out narration, all already documented KEEP in the C7 IMPL-REPORT §9).

### 8.4 Verification the coder MUST run (PREFLIGHT gate)

1. `bash scripts/tests/fixture-dependent/test-persona-contracts.sh` → 3/3 (the migration contract's NEW bundle assertion must PASS against the fixed migrator).
2. `bash scripts/tests/test-migrate-v10-to-v11.sh` (+ `-decompose`, `-dry-run`, `-gates`) → green (the new bundle assertion + existing asserts).
3. `python3 scripts/validate-pack.py` (default) exit 0 + `comm` NEW=0 against base; `PACK_VALIDATE_DEEP=1` exit 0 (the fix introduces NO validate-pack delta per §4.1).
4. The FULL wired CI suite (per `verify-full-ci-suite`): every script in `validate-pack.yml` both jobs (the C7 IMPL-REPORT ran 72 wired tests — re-run after the migrator edit, since `test-migrate-v10-to-v11*` + `test-migrator-core.sh` + `test-persona-contracts.sh` are all wired and now exercise the changed behavior).
5. `bash test-fixtures/build.sh --all --clean` + `git diff --stat test-fixtures/manifest.txt` → EXPECTED EMPTY (§7.1); non-empty ⇒ STOP + surface.
6. A live gap-reconfirm: copy a v10 fixture to `/tmp`, run the migrator, assert `.agents-plugin/optiquity-agents/agents/` is now PRESENT (the inverse of EB-1) — the direct proof the fix works.

---

## 9. SUCCESS-CRITERIA TRACEABILITY

| Success criterion (from the prompt) | Met by | Evidence |
|---|---|---|
| Migrated `.agents-plugin/optiquity-agents/` identical to fresh init (same agents, same count) | §3.2 prop 1 (verbatim pack-source copy) + §3.3 | EB-2 (fresh init == pack source, 16 agents); §8.4 step 6 (gap-reconfirm asserts presence) |
| Additive + non-destructive + idempotent; pre-existing/customized bundle preserved | §3.2 props 2+3 (per-file `[[ ! -f ]]` non-clobber; re-run no-op) | matches the function's existing additive idiom (migrate-v10-to-v11.sh:415-421); BD-119 §4.3 add-semantics |
| Correct interaction with the `.gemini/`-retire step | §3.1 + EB-6 (install runs BEFORE retire; disjoint paths) | EB-6 (hook order) |
| Install-map / Check 39/41/47 stay green; row/constant change specified if needed | §4 (NO change needed — measured) | EB-8/EB-9/EB-10 (recursive-walk-covered; init-keyed; frozen tuple unmoved) |
| L429 comment becomes accurate | §3 / blast-radius #2 | EB-4 (false claim identified) |
| Migration persona-contract asserts the bundle; `test-persona-contracts.sh` passes | §5.2 + §8.4 step 1 | EB-11 (contract narrowed to match gap; widen in lockstep) |
| `test-migrate-v10-to-v11.sh` / `-skills.sh` / `test-v11-realistic-ot.sh` pass | §5.4 + §8.4 steps 2,4 | wired-suite re-run |
| No validate-pack regression (default + DEEP); no boundary/client-install regression | §4.1 (zero validate delta) + §3.4 (dependency direction correct) | EB-7 (dependency direction); §4 (no install-map change) |

## 10. OPEN QUESTIONS / CONCERNS FOR THE USER (each standalone)

**OQ-1 — Count guard: strict-equality vs superset.** §3.2 property 4 recommends the migrator's count guard assert "every PACK bundle agent present at target" (superset-tolerant), NOT init's strict `==`, so a project that customized its `.agents-plugin/agents/` (deleted/added an agent) is not falsely failed. CONCERN: this differs from init's strict guard. ASK: confirm the migrator guard should be superset-tolerant (allow project extras, require all pack agents present) — or should the migrator enforce strict count-equality like init (which would reject a customized bundle)? The superset form is the customization-preserving choice and matches the non-clobber property; init's strict form is fine only because init writes into an empty target.

**OQ-2 — Wired-test assertion (§5.4) in C7 or its own commit.** I recommend ADDING the `.agents-plugin/` presence assertion to `test-migrate-v10-to-v11.sh` inside the C7 cycle (it is wired CI, runs at the same green-point, and `no-deferral-without-user-direction` says v11.0 work lands now). CONCERN: it grows the C7 diff slightly. ASK: confirm folding the wired-test assertion into the C7 commit (recommended), or land it as a follow-on `pack-only` commit.

**OQ-3 — Client-migration DOCS (blast-radius #12).** `supporting-docs/MIGRATION-v10-to-v11.md` + `SETUP-EXISTING.md` describe migrator output; if they enumerate a post-migrate surface list, they should name `.agents-plugin/`. Those are `project-only`/cross-surface docs edits that belong in the planner's C-series docs commits, NOT this `pack-only` C7 commit (Check 36). CONCERN: a reader of the migration doc might not see the bundle mentioned until the docs commit lands. ASK: confirm the docs-surface mention of the bundle is handled in the C-series docs commit (recommended — keeps C7 single-scope), not pulled into C7.

---

## 11. RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in CLAUDE.md ## Pack memory / MEMORY.md) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran only read-only git verbs: `git rev-parse HEAD`, `git status --short`. No add/commit/apply/stash/checkout/restore/worktree. The single write is this `/tmp` design doc. Scratch dirs in `/tmp` only; cleaned up (`rm -rf /tmp/migrator-gap-confirm /tmp/init-target-shape → cleaned`). Worktree state after analysis: `git status --short` = the same 3 modified contracts, no new edits. | COMPLIANT |
| **empirical-evidence-blocks** (architect state-claims) | Every state-claim carries an EB with command + verbatim output + HEAD `f945fb9` + date 2026-06-17 + interpretation + SUPPORTED conclusion: EB-1..EB-13 (gap-confirm migration run, byte-identity, reference shape, false comment, framework helper, hook order, dependency direction, install-map non-impact ×3, contract narrowing, 3b orthogonality, manifest non-impact). | COMPLIANT |
| **ci-guard-measure-then-bound** | §4: measured every affected check (39/41/47 + 5/27/52/55/56/57) against the live tree BEFORE concluding — read the `_CLIENT_INSTALLED_FILES` START/END block (EB-8), Check 39 docstring + the bundle cmd_update dir-leg (EB-9), `_SANCTIONED_PACK_SIDE_SHIPPED` (EB-10). Conclusion: NO allowlist/row/constant change (the bundle is recursive-walk-covered + init-keyed); no widening of any allowlist. The frozen Check-47 2-tuple is verified UNMOVED. | COMPLIANT |
| **dependency-direction-placement** | §3.4 / EB-7: `grep agents-plugin scripts | grep -v project-template` shows every reference writes to `$TARGET/...` or reads from `$PACK/project-template/...` — no pack operation depends on a client-installed bundle file at runtime; pack→client copy is the correct direction; the bundle is `project-template/`-resident, not a Check-47 pack-side-shipped file. | COMPLIANT |
| **researcher-maps-blast-radius-before-architect** | §6: complete enumeration of every file the fix touches — 5 CHANGE loci + 7 KEEP/verify/defer categories — each categorized + dispositioned + evidence-tied, with a count reconciliation (all CHANGE loci `pack-only` under `scripts/**`). I performed the blast-radius enumeration directly via grep/read against the live worktree (no separate researcher spawn was available within this RO design task; the enumeration is exhaustive and evidence-backed). | COMPLIANT |
| **no-deferral-without-user-direction** | §5.4 / OQ-2: the wired-test assertion is recommended to land NOW in the C7 cycle (v11.0 unlaunched), not deferred; the only DEFER (blast-radius #12, client-migration docs) is a SCOPING split into the planner's existing C-series docs commit (Check-36 single-scope correctness), surfaced as OQ-3, not a silent push-out. | COMPLIANT |
| **fail-loud-delete-old-source** | §3 reuses the existing post-dispatch hook + does NOT create a parallel/mirror install path; §7.1 mandates the coder STOP + surface on an unexpected manifest delta (fail-loud, not silently stage). The fix corrects (not archives) the false L429 comment in place (active doc, one stale element → reconcile in place per the rule's exception (a)/(b) distinction). No old-source artifact is kept as a mirror. | COMPLIANT |
| **regenerate-manifest-v11-surface** | §7.1 / §8.4 step 5: the C7 commit touches `scripts/**` (v11-surface) → coder MUST run `build.sh --all --clean` + check the manifest diff; expected EMPTY (EB-13), non-empty ⇒ STOP. | COMPLIANT (design directs the coder) |
| **enumerate-encoding-surfaces** | §5 / §8.1: the migrator behavior + its encoding surfaces (the migration persona-contract assertion 2 + the wired `test-migrate-v10-to-v11.sh`) are enumerated and moved in lockstep in ONE commit; §4.2 names the runtime-test layer (not a validator) as the surface that pins this behavior. | COMPLIANT |
| **rules-applied-verification-block** | This block; each rule has quoted evidence + a terminal conclusion; runtime regime recorded in the header (isolated worktree, HEAD f945fb9, 3 uncommitted contracts). | COMPLIANT |

---

## End of design

**Deliverable summary for Pack Chat / the C7 coder:** add an additive non-clobber Antigravity-bundle-install block to `_v10_to_v11_install_v11_artifacts` in `scripts/migrate-v10-to-v11.sh` (mirroring init-project's `stage_s2_agents` in the migrator's additive idiom, superset-tolerant count guard), correct the false L429-430 comment + the dry-run line, widen the C7 migration persona-contract's assertion 2 to assert the bundle (with the gap-narration comment rewritten), and add a wired bundle-presence assertion to `test-migrate-v10-to-v11.sh` — ALL as ONE `pack-only` commit in the C7 worktree. No install-map / Check 39/41/47 / manifest change is required (measured). Verify via the §8.4 PREFLIGHT gate, including a live gap-reconfirm proving the bundle is now present post-migrate.
