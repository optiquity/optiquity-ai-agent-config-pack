# PACK-REVIEW — BD-221 C7 (persona-contracts conversion + migrator bundle-install fix)

**Reviewer:** pack-reviewer (fresh, READ-ONLY). No repo edit, no git state change. The single write is this `/tmp` report.
**Runtime regime (verified at startup, ground-truth not settings):** ISOLATED git worktree.
- `pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af3fa4dbb6c6ecb18`
- `git rev-parse HEAD` = `f945fb9b56e6796fdd5c355f673eada5ec8e7f14` (`f945fb9`) — matches expected.
- `git status --short` = exactly the 5 uncommitted C7 files (3 persona-contracts + migrator + wired test). CONFIRMED.
**Date:** 2026-06-17.
**Scope:** the ENTIRE C7 change set — piece 1 (persona-contracts Gemini→Antigravity conversion, never separately reviewed) + piece 2 (migrator Antigravity-bundle-install fix). All verification re-run independently from inside this worktree; the bundle-parity / idempotence / non-clobber checks were re-run live against `/tmp` scratch.

---

## OVERALL VERDICT: **CLEAN** — ready to patch + commit

Both pieces are correct, complete, and lockstep-consistent. The full gate is green and every load-bearing behavior was independently reproduced.

- **Persona-contracts conversion (piece 1): CLEAN.** All three contracts correctly convert `claude codex gemini` → `claude codex agents` ONLY where the surrounding asserts are about the third-CLI agent/skill surface; loose claude/codex agent loops kept; Antigravity third-CLI agents modeled as the plugin BUNDLE (not a loose dir); `.gemini/commands/pack-help.toml` → `.agents/skills/pack-help/SKILL.md`; ALL `GEMINI.md` trinity asserts KEPT. `test-persona-contracts.sh` = 3/3 PASS.
- **Migrator bundle-install fix (piece 2): CLEAN.** The migrated `.agents-plugin/optiquity-agents/` is byte-identical to a fresh `init-project.sh` install (18 files, `diff -rq` clean). Idempotent (re-run = no-op, identical checksum). Non-clobber (customized agent + project extra both survive; all 16 pack agents present). Superset-tolerant count guard (OQ-1). Wired-test assertion folded in (OQ-2). No docs / install-map / Check 47 edit (OQ-3 boundary respected).
- **Boundary / manifest / grep-zero: CLEAN.** Exactly the 5 `scripts/**` files; manifest UNCHANGED; `build.sh --verify` exit 0; every remaining `gemini`-family token is KEEP-legitimate.
- **Full wired CI suite: 72/72 PASS, 0 fail** (every script in `validate-pack.yml` both jobs).

No BLOCKER, no MUST, no SHOULD findings. Two NITs (informational; no fix required).

---

## SECTION 2 — GATE VERIFICATION (independently re-run)

| Gate | Command | Result |
|---|---|---|
| Default validate-pack | `python3 scripts/validate-pack.py` | **exit 0**, `PASSED — all checks clean` |
| Default FAIL-line comm | `grep -E '^FAIL:'` on default run | **EMPTY (NEW=0)** — no C7 regression |
| DEEP validate-pack | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **exit 0**, `PASSED — all checks clean` |
| DEEP FAIL-line comm | `grep -E '^FAIL:'` on DEEP run | **EMPTY (NEW=0)** |
| Fixture manifest verify | `bash test-fixtures/build.sh --verify` | **exit 0** — fixtures match committed manifest (manifest UNCHANGED, correct) |
| Full wired CI suite | all 72 wired tests (`ci-shard-plan --print-partition` → run each) | **72/72 PASS, 0 fail** |

The base at `f945fb9` is GREEN and C7 keeps it green — both default and DEEP runs emit zero `FAIL:` lines. I did NOT run `build.sh --all --clean` (forbidden); `--verify` exit 0 confirms the manifest is correctly unchanged. The full 72-test battery is the authoritative `verify-full-ci-suite` evidence; the last red (persona-contracts) is now green (3/3).

---

## SECTION 3 — PIECE 1: PERSONA-CONTRACTS CONVERSION (verified against init-project.sh actual output)

### 3.1 contract-greenfield.sh — CLEAN
- Skill loop `for tool in claude codex gemini` → `for tool in claude codex agents` (2 occurrences: skill-presence loop + per-CLI skill-count sanity). Correct: skills DO fan out to `.agents/skills/` (verified — fresh init produces `.agents/skills/<name>/SKILL.md`).
- Assertion 2 (per-CLI agents): loose loop correctly NARROWED to `claude codex` + a NEW dedicated bundle block asserting every `project-template/.agents-plugin/optiquity-agents/agents/*.md` landed in `$SANDBOX/.agents-plugin/optiquity-agents/agents/`. Correct: Antigravity agents ship as the bundle, NOT a loose `.agents/agents/` dir (confirmed: `project-template/.agents/agents` does not exist).
- S11 client-artifact list: `.gemini/commands/pack-help.toml` → `.agents/skills/pack-help/SKILL.md` (both the prose docstring at L20x and the `s11_files=()` array at L229). Matches the converted init.
- Trinity assert (`for f in CLAUDE.md AGENTS.md GEMINI.md`) KEPT byte-identical. Correct.

### 3.2 contract-mid-dev.sh — CLEAN
- Per-CLI directory loop narrowed `claude codex gemini` → `claude codex` (loose `agents/` + `skills/` dirs) + NEW Antigravity block: asserts `.agents/skills/` created AND `.agents-plugin/optiquity-agents/agents/` created, with the accurate comment "no loose `.agents/agents/` dir — Antigravity agents ship as the plugin bundle." Verified accurate.
- Docstring item 3 updated from `.gemini/ directories` → "the Antigravity `.agents/skills/` + plugin bundle." Targeted, in place.

### 3.3 contract-migration.sh — CLEAN
- Assertion 2 loose-agent loop narrowed `claude codex gemini` → `claude codex` (the dirs `migrator_directory_sweeps` installs) + NEW superset-tolerant bundle block asserting every pack bundle agent present post-migrate + `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md` present. The gap-narration comment ("the v10→v11 migrator does not currently install that bundle…") was REWRITTEN to "…installs it additively (additive, non-clobber)…, asserted in the bundle block below." (DESIGN §5.2 satisfied.)
- pack-help skill loop `for tool in claude codex` → `for tool in claude codex agents` + the BD-080 docstring updated ("pack-help is now an ordinary pool skill fanned out to all three CLI skill homes…; Antigravity reads `.agents/skills/`; no `.toml` command form"). Matches the converted migrator artifact list (`.gemini/commands/pack-help.toml` → `.agents/skills/pack-help/SKILL.md` at L441).
- Assertion 3b widened: loose x-agent loop narrowed `claude codex gemini` → `claude codex` + a NEW third-CLI block asserting the project-owned `x-fakeot-domain.md` is PRESERVED in `gemini-retired-docs/` (NOT lost; NOT relocated into the bundle). Correct interaction with the retire step (the bundle install is additive of PACK files only).
- Trinity assert loops (`CLAUDE.md AGENTS.md GEMINI.md`) at L255 / L302 KEPT unchanged.

### 3.4 Independent cross-check against init-project.sh
- `scripts/init-project.sh:448-467` uses `cp -R` whole-bundle + strict `==` count guard (fresh-install path). This guard was **NOT changed** (init-project.sh is not in the diff). Correct — the contracts assert the converted init's actual output and the migrator uses its own additive idiom.
- `test-persona-contracts.sh` = **3/3 PASS** (greenfield + mid-dev + migration), confirming the converted contracts hold against real fixtures + a real migration run.

---

## SECTION 4 — PIECE 2: MIGRATOR BUNDLE-INSTALL FIX (independently verified)

### 4.1 Bundle parity — VERIFIED IDENTICAL
- Copied `test-fixtures/v10-realistic-ot` → `/tmp/c7-mig` (committed-git v10 baseline; `.agents-plugin/` ABSENT pre-migrate, gap confirmed).
- Ran `migrate-v10-to-v11.sh /tmp/c7-mig` (paused at S3 sidecar reconciliation as designed) → resolved 3 trinity sidecars via `.resolved` flags → `--resume` (exit 0).
- Ran `init-project.sh /tmp/c7-init` (fresh git target, `y` to proceed; exit 0).
- **`diff -rq /tmp/c7-mig/.agents-plugin/optiquity-agents /tmp/c7-init/.agents-plugin/optiquity-agents` → no output (IDENTICAL).** Both = 18 files (16 agents/*.md + plugin.json + RUNTIME-SUBAGENT-PATTERN.md). This is the gap-reconfirm inverse of EB-1: the bundle is now PRESENT and matches a fresh install.

### 4.2 Idempotence — VERIFIED
- Sourced the migrator and re-invoked `_v10_to_v11_install_v11_artifacts` against an already-installed target (and re-ran the full `--resume` path). Bundle file count stayed 18; recursive checksum identical pre/post; no duplication, no clobber. (`RERUN_EXIT=99` on the second `--resume` is the framework's "no paused conflicts to resume" guard, NOT a bundle defect.)

### 4.3 Non-clobber — VERIFIED
- Pre-seeded a scratch target with a CUSTOMIZED `coder.md` ("PROJECT-CUSTOM coder body") + an EXTRA `x-project-extra.md`, then sourced the migrator and ran `_v10_to_v11_install_v11_artifacts`:
  - Customized `coder.md` preserved verbatim (NOT overwritten).
  - `x-project-extra.md` survives.
  - All 16 pack agents present + the 1 extra = 17 (superset, correct).
  - `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md` added (were absent).
  - A non-seeded pack agent (`architect.md`) was newly installed.
  - Function exit 0.

### 4.4 Superset-tolerant count guard (OQ-1) — CORRECT
- The guard (migrate-v10-to-v11.sh:379-388) iterates `"$bundle_src"/agents/*.md` and fails `fail_stage S5` only if a PACK agent is MISSING at the target; project extras are allowed. This is NOT init's strict `==`. Matches OQ-1 = superset-tolerant. Init's strict guard is unchanged (init-project.sh not in diff).

### 4.5 BD-119 framework fit — CORRECT
- The install lives inside `_v10_to_v11_install_v11_artifacts()` (the additive S5 artifact-install sub-op), alongside the other net-new v11 surface installs (uses the same per-file `[[ ! -f ]]` idiom). It does NOT bypass the framework, does NOT use a directory sweep, does NOT copy-and-rewrite the migrator. Runs BEFORE `_v10_to_v11_retire_gemini` (verified: hook order at L143-146 is install-then-retire; the live run logged the bundle install completing before the S5b retire banner). Uses framework helper `fail_stage S5`.

### 4.6 Ancillary edits — CORRECT
- **L429-430 comment** (now at L470-474) corrected: "…the agent plugin bundle `.agents-plugin/optiquity-agents/`… are installed additively by `_v10_to_v11_install_v11_artifacts` (which runs immediately before this step)." The previously-false claim is now TRUE-and-accurate.
- **Dry-run `info` line** (L140) updated: "…v11 artifact install (incl. Antigravity agent bundle)…". Accurate.
- **contract-migration assertion-2** widened to assert the `.agents-plugin/` bundle (replacing the `claude codex`-only scoping). Verified §3.3.
- **Wired `.agents-plugin/` assertion (OQ-2)** present in `test-migrate-v10-to-v11.sh:152-161` — asserts `coder.md` + `plugin.json` present post-migrate, mirroring the pack-help-skill assertion at L149-150. Test passes (the 2 new assertions show PASS in the live run).

### 4.7 OQ-3 boundary — RESPECTED
- NO `supporting-docs/` or `project-template/` edit in the diff (the `.agents-plugin/` migration-docs mention is C11, not C7). NO `validate-pack.py` edit → install-map / Check 39/41/47 / `_SANCTIONED_PACK_SIDE_SHIPPED` UNCHANGED. Confirmed by `git diff --name-only` (exactly the 5 scripts files) and a direct grep that `validate-pack.py` is not in the diff.

---

## SECTION 5 — BOUNDARY / MANIFEST / GREP-ZERO / DEPENDENCY-DIRECTION

### 5.1 Boundary (pack-only) — CLEAN
`git diff --name-only` = exactly:
```
scripts/migrate-v10-to-v11.sh
scripts/persona-contracts/contract-greenfield.sh
scripts/persona-contracts/contract-mid-dev.sh
scripts/persona-contracts/contract-migration.sh
scripts/tests/test-migrate-v10-to-v11.sh
```
No `project-template/`, no `supporting-docs/`, no `init-project.sh`, no manifest. All `scripts/**` → cleanly `pack-only` (Check 36 will pass).

### 5.2 Manifest — UNCHANGED (correct)
`test-fixtures/manifest.txt` is NOT in the diff. `build.sh --verify` exit 0 (fixtures match the committed manifest). The migrator authors no committed fixture; it runs at test time against a copied fixture in a sandbox → no committed-fixture SHA change. RC9 satisfied (a coder regen would produce an empty diff).

### 5.3 grep-zero (`rename-plans-measure-then-bound`) — CLEAN
`grep -nE '\.gemini|[Gg]emini'` over the 5 in-scope files returns ONLY KEEP-legitimate tokens, all in documented allowlist categories:
- **Gemini→Antigravity retirement narration** (the migration ACT): migrate-v10-to-v11.sh:26, :140, :467, :501 banner "retire departing Gemini tree".
- **`.gemini/` real departing-surface refs**: the entire `_v10_to_v11_retire_gemini` function (L477-533) legitimately processes the departing `.gemini/` tree.
- **`gemini-retired-docs/` real holding-dir surface name**: the BD-221 preservation dir (migrate-v10-to-v11.sh:483/487/497/509/523/531/533; contract-migration.sh:320/328/330/333).
- **`.gemini/.env` v10-source carve-out**: test-migrate-v10-to-v11.sh:37/204-227/427-477 (v10 INPUT shape, Gemini-shaped per carve-out i; the Group-6 retire unit test).
- **`x-fakeot-domain` preserved in `gemini-retired-docs/`**: contract-migration.sh:319 narration.
No stale "should-have-been-converted" token remains. The allowlist is exactly the legitimate set (departing-surface processing + preservation-dir + v10-source carve-out + the conversion-act verb).

### 5.4 Dependency-direction — CORRECT
`grep -rn 'agents-plugin/optiquity-agents' scripts | grep -v project-template`: every reference WRITES to a target (`$_MIGRATOR_TARGET/...`, `$TARGET/...`, `$SANDBOX/...`, scratch fixtures) or READS from `$PACK/project-template/...` (the source), or is a test/validator assertion. No pack operation `source`s or executes a client-installed bundle file at runtime. The bundle is a pure pack→client deliverable; the migrator (a pack op) installs it into the client tree — the correct direction. The bundle is `project-template/`-resident (recursive-walk-covered), not a `_SANCTIONED_PACK_SIDE_SHIPPED` candidate. No inversion.

---

## SECTION 6 — FINDINGS

No BLOCKER / MUST / SHOULD findings.

### NIT-1 (informational; no fix) — count guard is a copy-failure backstop, not a divergence detector
**File:** `scripts/migrate-v10-to-v11.sh:379-388` (the superset count guard).
**Concern:** the guard runs AFTER the additive per-file copy. Because the copy re-adds any absent pack agent before the guard executes, the guard can realistically only trip if `cp` itself fails (permission error, destination-is-a-directory, etc.). In normal operation it is a defensive backstop rather than a customization-divergence detector.
**Assessment:** this is CORRECT and matches the design intent ("no pack agent silently skipped" — DESIGN §3.2 property 4). The guard's value is catching a partial/failed copy. NOT a defect; no change recommended. Noted only so a future reader does not mistake it for a divergence check.

### NIT-2 (informational; no fix) — guard message says "missing under …/agents" though it counts only `agents/*.md`
**File:** `scripts/migrate-v10-to-v11.sh:388`.
**Concern:** the `fail_stage S5` message reads "pack agent(s) missing under .agents-plugin/optiquity-agents/agents" — which is accurate (it counts only `agents/*.md`, not `plugin.json` / `RUNTIME-SUBAGENT-PATTERN.md`). The persona-contract + wired test DO separately assert `plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md` presence, so the meta-files are covered at the test layer even though the migrator guard does not assert them.
**Assessment:** acceptable. The meta-file coverage lives in the encoding-surface test layer (contract-migration.sh:209-216, test-migrate-v10-to-v11.sh:159-161), which is where DESIGN §4.2 places runtime behavioral pins. Not a defect; no change recommended.

---

## SECTION 7 — RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in CLAUDE.md ## Pack memory / MEMORY.md) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Ran only read-only git verbs: `git rev-parse HEAD`, `git status --short`, `git diff [--name-only/--stat]`. No add/commit/apply/stash/checkout/restore/worktree/mv/rm. Scratch work was `/tmp`-only (`/tmp/c7-mig`, `/tmp/c7-init`, `/tmp/c7-nc`), cleaned (`rm -rf /tmp/c7-mig /tmp/c7-init /tmp/c7-nc`). NOTE: init-project.sh's prompt needed `git init` in the `/tmp` scratch target only — those are throwaway `/tmp` repos, NOT the worktree/pack repo. Worktree state after analysis: `git status --short` = the same 5 modified files, no new edits. The single write is this `/tmp` report. | COMPLIANT |
| **verify-full-ci-suite** | Ran EVERY script in the disk-derived wired set (`ci-shard-plan.py --print-partition` → 72 tests across 4 shards). Result: `WIRED RESULTS: pass=72 fail=0 (total 72)`; `FAILED: NONE — all green`. Plus default + DEEP `validate-pack` (both exit 0, zero FAIL-lines) and `build.sh --verify` (exit 0). The fixture-dependent shard members (test-persona-contracts, test-v11-realistic-ot, test-migrator-skills, test-dry-run-migration, test-add-capability) all green. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Inspected `git diff` per file: all changes are targeted in-place hunks (narrow `for tool` loop edits, added bundle blocks, comment rewrites). No file was rewritten wholesale; no section silently dropped (the trinity assert loops + the loose-agent loops are KEPT in place alongside the new bundle blocks). | COMPLIANT |
| **rename-plans-measure-then-bound** | grep-zero gate: `grep -nE '\.gemini|[Gg]emini'` over the 5 in-scope files returns ONLY the documented KEEP allowlist (Gemini→Antigravity conversion-act narration; `.gemini/` departing-surface processing in `_v10_to_v11_retire_gemini`; `gemini-retired-docs/` holding-dir name; `.gemini/.env` v10-source carve-out; `x-fakeot-domain` preservation narration). Zero stale should-convert tokens. §5.3. | COMPLIANT |
| **manifest-regen-on-v11-surface** | `test-fixtures/manifest.txt` NOT in `git diff --name-only`; `bash test-fixtures/build.sh --verify` exit 0 (fixtures match committed manifest). The migrator authors no committed fixture → manifest correctly UNCHANGED. (Did NOT run `--all --clean` — forbidden; `--verify` is the read-only confirmation.) | COMPLIANT |
| **dependency-direction-placement** | `grep -rn 'agents-plugin/optiquity-agents' scripts | grep -v project-template`: every ref writes to `$_MIGRATOR_TARGET`/`$TARGET`/`$SANDBOX` or reads from `$PACK/project-template/...`; no pack op `source`s/executes a client-installed bundle file at runtime. Bundle is `project-template/`-resident (not a Check-47 pack-side-shipped file). No inversion. §5.4. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly C7 (the 5 files). Out-of-scope items surfaced, not chased: OQ-3 docs mention is correctly DEFERRED to C11 (verified absent from C7); init-project.sh strict guard correctly unchanged. Two NITs are informational only. No edge-case sprawl. | COMPLIANT |
| **rules-applied-verification-block** | This block; each rule has quoted command/output evidence + a terminal conclusion; runtime regime recorded in the header (isolated worktree, HEAD f945fb9, 5 uncommitted files). | COMPLIANT |

---

## End of review

**Deliverable summary for Pack Chat / the C7 commit:** C7 is **CLEAN** on both pieces. Persona-contracts conversion is correct + complete (3/3 PASS); the migrator bundle-install fix produces a byte-identical-to-init bundle (verified), is idempotent + non-clobber (verified live), uses the superset-tolerant guard (OQ-1), folds the wired-test assertion (OQ-2), and respects the OQ-3 docs boundary. Boundary is exactly the 5 `scripts/**` files; manifest unchanged; grep-zero clean; full 72/72 wired suite green; default + DEEP validate-pack green with zero NEW fail-lines. Ready to patch + commit as ONE `pack-only` commit. Two NITs are informational (no fix required).
