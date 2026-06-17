# IMPL-REPORT — BD-221 C7 migrator-fix (Antigravity bundle install)

**Agent:** fresh pack-coder (subsequent RW agent in C7's review/fix cycle — REUSED the existing C7 worktree; did NOT create a new one).
**BD:** BD-221 (Gemini→Antigravity, v11.0 LAUNCH GATE). Closes POQ-C7-1 (migrator-bundle-install gap surfaced by the C7 IMPL-REPORT §7).
**Regime:** ISOLATED git worktree (verified at runtime via pwd + HEAD).
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af3fa4dbb6c6ecb18`
**Branch HEAD (final, unchanged — no commit by agent):** `f945fb9b56e6796fdd5c355f673eada5ec8e7f14` (`f945fb9`)
**Spec followed:** `/tmp/handoff-bd221-migrator-fix/DESIGN-MIGRATOR-BUNDLE-INSTALL.md` (in full).
**Scope keyword:** `pack-only` — every touched path is under `scripts/**`.
**Patch status:** NO patch emitted. All edits left UNCOMMITTED in the worktree per the live worktree-isolation model. Awaiting the post-review-clean SendMessage to produce the patch.

---

## 1. Definition-of-Done checklist (PASS/FAIL)

| # | DoD item | Result |
|---|---|---|
| 1 | (A) Bundle-install block added to `_v10_to_v11_install_v11_artifacts` (BD-119 post-dispatch sub-op; additive, non-clobber, idempotent, superset-tolerant guard) | PASS |
| 2 | (A-guard) Count guard is SUPERSET-tolerant (every pack agent present; project extras allowed) — NOT init's strict `==` | PASS |
| 3 | (B) False L429-430 comment fixed (now accurate); dry-run info line updated | PASS |
| 4 | (C) `contract-migration.sh` assertion-2 widened to assert the bundle (+ gap-narration comment rewritten); trinity asserts kept | PASS |
| 5 | (D) Wired-test bundle-presence assertion added to `test-migrate-v10-to-v11.sh` | PASS |
| 6 | Empirical bundle parity: migrated == fresh-init == pack source (byte-identical, 18 files / 16 agents) | PASS |
| 7 | Idempotence proven (re-run no-op) | PASS |
| 8 | Non-clobber proven (customized file untouched; project extra survives) | PASS |
| 9 | Superset guard fires `fail_stage S5` when a pack agent is missing | PASS |
| 10 | `test-persona-contracts.sh` → 3/3 (migration contract 40 passed/0) | PASS |
| 11 | `test-migrate-v10-to-v11.sh` → 51/0 (incl. 2 new bundle assertions) | PASS |
| 12 | migrator-skills / dry-run / realistic-ot → pass | PASS |
| 13 | `validate-pack.py` default → exit 0; DEEP → exit 0; NEW fail-lines EMPTY | PASS |
| 14 | Full wired CI suite (72 scripts in validate-pack.yml) → 72/72, 0 FAILED | PASS |
| 15 | `test-fixtures/manifest.txt` UNCHANGED (not in `git diff --name-only`) | PASS |
| 16 | grep-zero: every residual gemini token is KEEP-legitimate (no new ones introduced) | PASS |
| 17 | Boundary: `git diff --name-only` = exactly the 5 `scripts/**` files; no `supporting-docs/`/`project-template/`/`init-project.sh` | PASS |

---

## 2. Files changed inventory

| Path | Change type | Author |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | modified (Edits A + B + B-cosmetic) | THIS agent |
| `scripts/persona-contracts/contract-migration.sh` | modified (Edit C, on top of C7-first-coder content) | THIS agent (further edit) |
| `scripts/tests/test-migrate-v10-to-v11.sh` | modified (Edit D) | THIS agent |
| `scripts/persona-contracts/contract-greenfield.sh` | modified (carried unchanged from C7's first coder) | C7 first coder (untouched by me) |
| `scripts/persona-contracts/contract-mid-dev.sh` | modified (carried unchanged from C7's first coder) | C7 first coder (untouched by me) |

**Line deltas (`git diff --numstat`):**
```
48	4	scripts/migrate-v10-to-v11.sh
49	18	scripts/persona-contracts/contract-greenfield.sh   (C7 first coder — not mine)
17	3	scripts/persona-contracts/contract-mid-dev.sh       (C7 first coder — not mine)
78	10	scripts/persona-contracts/contract-migration.sh
10	0	scripts/tests/test-migrate-v10-to-v11.sh
```

**Final `git diff --name-only` (exactly 5 files):**
```
scripts/migrate-v10-to-v11.sh
scripts/persona-contracts/contract-greenfield.sh
scripts/persona-contracts/contract-mid-dev.sh
scripts/persona-contracts/contract-migration.sh
scripts/tests/test-migrate-v10-to-v11.sh
```

---

## 3. Per-task summary

### (A) Bundle-install block — `scripts/migrate-v10-to-v11.sh`

**Where:** inside `_v10_to_v11_install_v11_artifacts()`, immediately after the
`scripts/lib/detect.sh` install and before the BD-167 per-entry-tree templates
(a readable spot alongside the other net-new v11-surface installs). The function
runs at `migrator_post_dispatch_hook` step 3, BEFORE `_v10_to_v11_retire_gemini`
(verified: install at L145, retire at L146) — the Antigravity surface lands first;
the departing `.gemini/` and the new `.agents-plugin/` are disjoint paths.

**How it fits the BD-119 framework:** uses the existing post-dispatch hook
(ARCHITECTURE-BD-119 §3.2 "Optional adapter-declared functions" sanctions
`migrator_post_dispatch_hook`; §4.3 documents the `add` semantics). NOT the
declarative `migrator_artifact_installs` hook (the v10→v11 adapter deliberately
keeps ALL additive installs on the post-dispatch hook for monolith-faithful
no-record semantics — adding a declarative row would split the bundle's install
across two mechanisms and emit a BD-088 disposition the other installs don't).
NOT a directory sweep (sweeps transform v10-EXISTING dirs; `.agents-plugin/` is
net-new). NOT copy-and-rewrite (it adds ~44 lines to one existing sub-op). Uses
the framework's `fail_stage` helper (from migrator-core.sh) and `$_MIGRATOR_TARGET`
(both already used 35× in the file).

**Semantics (design §3.2 props 1-4):**
- **Additive:** per-file walk of `$PACK/project-template/.agents-plugin/optiquity-agents`
  via `find -type f`; copies each file IFF the destination is absent.
- **Non-clobber:** the `[[ ! -f "$bundle_dest" ]]` guard — a pre-existing or
  project-customized bundle file is NEVER overwritten (matches the BD-088
  add-semantics every other install in the function uses).
- **Idempotent:** a re-run finds every file present → the guard skips all → no-op.
- **Superset-tolerant count guard:** after the copy, asserts every PACK bundle
  `agents/*.md` is present at the target (counts the missing); `fail_stage S5` on
  any missing pack agent. Project extras (e.g. an `x-custom` agent) are ALLOWED
  (no strict `==`). The `fail_stage S5` tag matches the function's `── S5 ──` banner.

**architect-doc-reality-reconciliation:** the in-code comment names the realized
surface + that it mirrors `init-project.sh stage_s2_agents` (the fresh-install
path), with no line numbers.

**New code (the block):**
```bash
    # Antigravity agent plugin BUNDLE — net-new v11 surface (BD-221). v11
    # ships the third-CLI agents as a plugin bundle at
    # project-template/.agents-plugin/optiquity-agents/ (16 agents/*.md +
    # plugin.json + RUNTIME-SUBAGENT-PATTERN.md). This realizes for the
    # migration path the same bundle install that init-project.sh's
    # stage_s2_agents lays down on a fresh install — re-expressed in the
    # migrator's additive idiom: per-file copy IFF the destination is
    # absent, so a pre-existing or project-customized .agents-plugin/ is
    # NEVER overwritten (matches the BD-088 add-semantics every other
    # install in this function uses). Idempotent: a re-run finds every
    # bundle file present and is a no-op. Runs before _v10_to_v11_retire_gemini
    # (the departing .gemini/ tree and this new .agents-plugin/ surface are
    # disjoint paths), so the Antigravity surface lands first.
    local bundle_src="$PACK/project-template/.agents-plugin/optiquity-agents"
    if [[ -d "$bundle_src" ]]; then
        local bundle_file rel bundle_dest
        while IFS= read -r bundle_file; do
            rel="${bundle_file#"$bundle_src/"}"
            bundle_dest="$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/$rel"
            if [[ ! -f "$bundle_dest" ]]; then
                mkdir -p "$(dirname "$bundle_dest")"
                cp "$bundle_file" "$bundle_dest"
            fi
        done < <(find "$bundle_src" -type f)
        # Superset-tolerant count guard (NOT init's strict ==): the
        # non-clobber copy means a project that customized its
        # .agents-plugin/agents/ (deleted/added an agent) legitimately
        # diverges from the pack count. Assert every PACK bundle agent is
        # PRESENT at the target (no pack agent silently skipped); project
        # extras are allowed.
        local pack_agent agent_name missing_bundle=0
        for pack_agent in "$bundle_src"/agents/*.md; do
            [[ -e "$pack_agent" ]] || continue
            agent_name=$(basename "$pack_agent")
            if [[ ! -f "$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/agents/$agent_name" ]]; then
                missing_bundle=$((missing_bundle + 1))
            fi
        done
        (( missing_bundle == 0 )) || \
            fail_stage S5 "Antigravity bundle install incomplete: $missing_bundle pack agent(s) missing under .agents-plugin/optiquity-agents/agents"
    fi
```

### (B) False comment fix + dry-run line — `scripts/migrate-v10-to-v11.sh`

The `_v10_to_v11_retire_gemini` docstring formerly claimed the bundle "are
installed additively by the steps above" — false at the time (EB-4), now TRUE
after (A). Reconciled in place (active doc, one stale element → reconcile per
fail-loud rule exception, not delete):

OLD:
```
# The pack-standard v11 Antigravity surfaces (`.agents/skills/` distributed
# loose, the agent plugin bundle, `.agents/mcp_config.json`) are installed
# additively by the steps above. This step handles a DEPARTING `.gemini/`
# tree in the client project:
```
NEW:
```
# The pack-standard v11 Antigravity surfaces (`.agents/skills/` distributed
# loose, the agent plugin bundle `.agents-plugin/optiquity-agents/`,
# `.agents/mcp_config.json`) are installed additively by
# `_v10_to_v11_install_v11_artifacts` (which runs immediately before this
# step). This step handles a DEPARTING `.gemini/` tree in the client
# project:
```

Dry-run `info` line (the `_migrator_is_dryrun` branch) now mentions the bundle:
`"... + v11 artifact install (incl. Antigravity agent bundle) + Gemini→Antigravity retirement + ..."`.

### (C) Migration persona-contract widened — `scripts/persona-contracts/contract-migration.sh`

- Rewrote the assertion-2 gap-narration comment: dropped "the v10→v11 migrator
  does not currently install that bundle additively, so there is no loose
  third-CLI pack-agent surface to assert here" → now "the v10→v11 migrator
  installs it additively (additive, non-clobber — see
  `_v10_to_v11_install_v11_artifacts`), asserted in the bundle block below."
- ADDED a bundle-assertion block after the `claude codex` loop, mirroring the
  greenfield contract's pattern: superset-tolerant per-pack-agent presence loop
  against `$SANDBOX/.agents-plugin/optiquity-agents/agents/` (`t_fail` only if a
  pack agent is MISSING; project extras allowed), plus `plugin.json` +
  `RUNTIME-SUBAGENT-PATTERN.md` presence asserts.
- KEPT the `claude codex` loose-agent loop unchanged (still correct — loose
  agents migrate via the directory sweep).
- KEPT all `GEMINI.md` trinity asserts (assertion 2 L148, 3a L240, skill-rename
  L281) and assertion 3b (x-agent preserved in `gemini-retired-docs/`) — confirmed
  orthogonal to the bundle install (design §5.3 / EB-12).

### (D) Wired-test assertion — `scripts/tests/test-migrate-v10-to-v11.sh`

Added after the `.agents pack-help skill` assertion (Group-2 end-to-end run),
symmetric with the existing pack-help-skill pins:
```bash
[[ -f "$T/.agents-plugin/optiquity-agents/agents/coder.md" ]] \
    && t_pass "2.4 .agents-plugin bundle agent (coder.md) installed (Antigravity bundle)" \
    || t_fail "2.4 .agents-plugin bundle agent coder.md missing"
[[ -f "$T/.agents-plugin/optiquity-agents/plugin.json" ]] \
    && t_pass "2.4 .agents-plugin/optiquity-agents/plugin.json installed" \
    || t_fail "2.4 .agents-plugin/optiquity-agents/plugin.json missing"
```

---

## 4. Empirical evidence (verification commands + results)

### 4.1 Bundle parity (migrated == fresh-init == pack source)

- **Gap baseline (UNPATCHED migrator)** against a fresh copy of
  `test-fixtures/v10-realistic-ot` (apply paused at 3 trinity sidecars →
  accept-pack via `.resolved` flags → `--resume`, exit 0):
  `.agents-plugin/` ABSENT (GAP CONFIRMED); loose `.claude/agents`=17,
  `.agents/skills`=7, `gemini-retired-docs/` present, `.gemini/` retired —
  matches design EB-1 exactly.
- **Fresh init reference** (`init-project.sh` non-interactive via `<<<"y"`):
  18 bundle files = 16 `agents/*.md` + `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md`.
- **PATCHED migrator** against a fresh v10 copy (apply + resume, exit 0):
  bundle PRESENT, 18 files, 16 agents.
  - `diff` of file inventories: `INVENTORY IDENTICAL` (migrated vs fresh-init).
  - `diff -rq project-template/.agents-plugin/optiquity-agents <migrated>`:
    `BYTE-IDENTICAL: migrated == pack source`.
  - `diff -rq <fresh-init> <migrated>`: `BYTE-IDENTICAL: migrated == fresh-init`.

### 4.2 Idempotence + non-clobber + guard-fires (install-block logic exercised directly)

- **Non-clobber:** seeded a target with a CUSTOMIZED `coder.md` + a project-extra
  `x-project-custom.md`, ran the block:
  - `coder.md` after run = `CUSTOM PROJECT EDIT — do not clobber` (UNCHANGED).
  - `x-project-custom.md` SURVIVES.
  - 17 agents total (16 pack + 1 extra) — superset guard PASSED (`block ran OK`, rc=0).
  - missing `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md` were ADDED additively.
- **Idempotence:** second run against the now-full target →
  `IDEMPOTENT: no change on re-run` (shasum snapshot before==after); custom intact.
- **Guard fires:** seeded a target with the bundle but `coder.md` deleted, ran the
  guard logic → `FAIL_STAGE S5 Antigravity bundle install incomplete: 1 pack agent(s) missing`,
  rc=99. The guard is not a no-op.
- **Framework idempotency (whole re-run):** re-running the full migrator against an
  already-migrated v11 tree → exit 16 (`target already migrated`), the BD-119 I8
  idempotency guard.

### 4.3 Wired tests

| Test | Result |
|---|---|
| `scripts/tests/fixture-dependent/test-persona-contracts.sh` | rc=0 — **3/3** (migration contract: **40 passed, 0 failed**) |
| `scripts/tests/test-migrate-v10-to-v11.sh` | rc=0 — **Passed 51, Failed 0** (incl. the 2 new bundle assertions) |
| `scripts/tests/fixture-dependent/test-migrator-skills.sh` | rc=0 — 19 passed, 0 failed |
| `scripts/tests/fixture-dependent/test-dry-run-migration.sh` | rc=0 — 7 passed, 0 failed |
| `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh` | rc=0 — 33/33 |

### 4.4 validate-pack (default + DEEP), fail-line comm vs GREEN base @ f945fb9

- BASE (before edits): default exit 0, DEEP exit 0, both with ZERO `FAIL:` lines.
- AFTER (post-edits): default exit 0, DEEP exit 0.
- `comm -13 base after` (NEW fail-lines) for BOTH default and DEEP: EMPTY.
  AFTER-total fail-lines: 0 (default), 0 (DEEP).

### 4.5 Full wired CI suite (verify-full-ci-suite)

- Enumerated the wired set from `.github/workflows/validate-pack.yml` via
  `scripts/lib/ci-shard-plan.py --print-partition` → 72 wired KEEP tests across
  4 shards (the disk-derived `{scripts/test*.sh + scripts/tests/*.sh +
  scripts/tests/fixture-dependent/*.sh}` set).
- Built fixtures first (`bash test-fixtures/build.sh --all --clean`, exit 0) +
  `--verify` (exit 0) — fixture-dependent shard precondition.
- Ran EVERY one of the 72 scripts, accumulating per-test rc:
  **RAN 72 tests; 0 FAILED.** (The `validate` job's validate-pack default+DEEP
  covered in §4.4.)

### 4.6 Manifest unchanged

- `bash test-fixtures/build.sh --all --clean` → `git diff --name-only test-fixtures/manifest.txt`
  is EMPTY; `git diff --stat` EMPTY. After the full suite, the final
  `git diff --name-only` does NOT include `test-fixtures/manifest.txt`
  (grep count = 0). Confirms the migrator authors no committed fixture (design EB-13).

---

## 5. grep-zero residue (rename-plans-measure-then-bound)

`grep -niE 'gemini'` across my 3 edited files — every residual token is
KEEP-legitimate, and **none of my new lines introduced any gemini token**
(my additions reference only `.agents-plugin/optiquity-agents/` / Antigravity):

| Category | Examples (file:line) | Why KEEP |
|---|---|---|
| `GEMINI.md` trinity name | migrate L87/93/554/614/642; migration-contract L18/148/240/281; wired-test L43 | Trinity file name — structurally required |
| `.gemini/` departing-surface refs (retire logic) | migrate L321/360/467/474-525; wired-test L37/204-227/411-477 | Real v10 client surface the migrator legitimately retires (v10 carve-out) |
| `gemini-retired-docs/` holding-dir surface | migrate L483/487/497/523/530-533; migration-contract L320/328/330/333; wired-test L421/444-456 | Real v11 holding-dir surface name (frozen) |
| `Gemini→Antigravity` transition prose | migrate L26/140; wired-test L411 header | Correctly describes the conversion action |
| `.gemini/commands/pack-help.toml` legacy command | migrate L321; wired-test L430 | v10 carve-out (departing legacy form) |

No old token remains that should have been converted. Gate PASSES.

---

## 6. Boundary discipline check

C7 is `pack-only`; every edit is under `scripts/**`. No edit touches a
project-side surface (`project-template/`, `supporting-docs/`), so the
project-side-SSOT pre-flight does not apply (no project-side file edited).
Explicitly held OUT of scope per the prompt + design:
- `supporting-docs/MIGRATION-v10-to-v11.md` / `SETUP-EXISTING.md` (OQ-3 → C11,
  `project-only`) — NOT touched.
- install-map / Check 39/41/47 / `_SANCTIONED_PACK_SIDE_SHIPPED` — NOT touched
  (design measured: not needed; bundle is recursive-walk-covered + init-keyed).
- `scripts/init-project.sh` strict count guard — NOT touched (init's `==` correct
  for an empty target).

**Boundary verification:** `git diff --name-only` = exactly the 5 `scripts/**`
files; no `supporting-docs/`, no `project-template/`, no `init-project.sh`.

---

## 7. Plan deviations

ZERO. The implementation follows the design spec exactly: the additive
post-dispatch sub-op block with superset-tolerant guard (§3), the L429 comment +
dry-run fix (§3 / blast-radius #2-3), the migration-contract assertion-2 widening
(§5.1-5.2), the wired-test assertion (§5.4), and the single `pack-only` scope (§8).
The design's three frozen OQ answers are honored: OQ-1 superset-tolerant guard,
OQ-2 wired-test assertion folded into C7, OQ-3 docs deferred to C11 (untouched).

---

## 8. New POQs introduced

NONE. POQ-C7-1 (the gap) is CLOSED by this fix. The design's OQ-1/2/3 were
pre-frozen (per the prompt: "the 3 frozen OQ answers") and are all honored.

---

## 9. Handoff status

NO patch produced. All edits are UNCOMMITTED in the worktree
`agent-af3fa4dbb6c6ecb18` (HEAD `f945fb9`, nothing staged). Per the live
worktree-isolation model (BD-226), I await the post-review-clean SendMessage to
produce the `git diff` patch to the `/tmp` handoff dir; the orchestrator then
applies + commits with user approval. I ran NO state-changing git verb.

---

## 10. Rules-Applied Verification Block

| Rule (from prompt §7 / CLAUDE.md ## Pack memory) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran only read-only git verbs: `git rev-parse HEAD`, `git status --short`, `git diff --name-only`, `git diff --numstat`, `git -C <scratch> status`. No add/commit/apply/stash/checkout/restore/worktree on the worktree. Final `git status --short` = the 5 modified files; HEAD still `f945fb9`. Edits via Edit tool only. | COMPLIANT |
| **per-action-approval-sub-agents** | Section-0 worktree state confirmed BEFORE any edit (HEAD f945fb9 + the 3 expected uncommitted contracts). Destructive ops limited to `rm -rf` of my OWN `/tmp` scratch dirs (never a real project/committed fixture); `git status --short` after cleanup unchanged. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted ONE PREFLIGHT line only after ALL Section-3 gates PASS (4/4 edits; bundle parity; persona 3/3; full suite 72/72; validate default+DEEP NEW=0; manifest unchanged). No stop/halt message received. | COMPLIANT |
| **worktree-isolation-model** | REUSED the existing C7 worktree (did not create one); first action `cd` + pwd/HEAD/status confirm. No patch emitted up front; edits left uncommitted; awaiting post-review SendMessage for the patch. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All changes via targeted Edit calls (old_string→new_string), not full-file Writes. Re-read the touched migrator region (L344-395) after editing; re-read assertion-2 region before the bundle-block insert. No section drops. | COMPLIANT |
| **verify-full-ci-suite** | Ran EVERY one of the 72 wired test scripts from `validate-pack.yml` (enumerated via `ci-shard-plan.py --print-partition`), not just validate-pack: "RAN 72 tests; 0 FAILED." Plus validate-pack default+DEEP. Fixtures built + `--verify` first. | COMPLIANT |
| **rename-plans-measure-then-bound** | grep-zero gate: `grep -niE 'gemini'` over the 3 edited files; every residual token categorized KEEP-legitimate (§5); zero new gemini tokens introduced by my edits. | COMPLIANT |
| **architect-doc-reality-reconciliation** | In-code comment for the new block names the realized surface (`.agents-plugin/optiquity-agents/`) + that it mirrors `init-project.sh stage_s2_agents`, no line numbers. IMPL-REPORT §3(A) cross-references the design + init reference. | COMPLIANT |
| **dependency-direction-placement** | The bundle is a CLIENT deliverable copied pack→client (`$PACK/project-template/...` → `$_MIGRATOR_TARGET/.agents-plugin/...`). The migrator (a pack op) WRITES into the client tree; no pack operation `source`s/executes a client-installed bundle file — no inversion. Bundle is `project-template/`-resident (not a `_SANCTIONED_PACK_SIDE_SHIPPED` candidate); Check 47 untouched. | COMPLIANT |
| **manifest-regen-on-v11-surface** | Ran `bash test-fixtures/build.sh --all --clean`; `git diff --name-only test-fixtures/manifest.txt` EMPTY; manifest NOT in the final change set (grep count 0). Not staged (no staging at all). | COMPLIANT |
| **rules-applied-verification-block** | This block — each rule has quoted evidence + a terminal conclusion; worktree-reuse behavior recorded (Section 0 / row above). | COMPLIANT |

---

## End of IMPL-REPORT
