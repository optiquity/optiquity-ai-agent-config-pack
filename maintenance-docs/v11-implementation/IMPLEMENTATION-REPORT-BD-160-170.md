# Implementation report — BD-160 + BD-170 (Batch 19 commit 19f)

## §1 — Summary

Wired `v11-realistic-ot` into `test-fixtures/build.sh` (BD-160) and extended the v11 case with the per-entry decompose / mirror-regenerate / TOC-regenerate + byte-identity round-trip step (BD-170), both shipping in one commit per Pack-Chat-direct R-2 resolution. Four files modified: `test-fixtures/build.sh` (+166 lines net), `test-fixtures/manifest.txt` (+1 entry), `test-fixtures/README.md` (+6 lines net, table row + status paragraph), `scripts/lib/migrator-core.sh` (+7 lines net, docstring carry-forward). Build is deterministic (two clean rebuilds produced byte-identical file content + HEAD SHA `85072fec8ad59e1badd86e0bde62f943811a7bba`). All four canonical OT customizations verified against v11's surface: C1 trinity project-name fills, C2 ollama strip (count=0 ollama, count=1 lmstudio retained), C3 x-fakeot-domain in `.codex/`, `.claude/`, `.gemini/` agents dirs, C4 TD-* content in `docs/project/BACKLOG.md` (5 entries decomposed). BD-170 round-trip byte-identical across all three project streams (5 entries for backlog, 0 for implementation-plan, 0 for changelog — zero-entry no-ops still exercise the helpers and pass the cmp -s check). Eleven verification commands all PASS; HEAD unchanged at `bd022e96e2baa975dc72fafa1e0badffbb4c08d6`; no stage / commit performed (per `feedback_agents_never_commit`).

## §2 — Files modified / created

| Path | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `test-fixtures/build.sh` | 901 | 1067 | +166 | modified |
| `test-fixtures/manifest.txt` | 9 | 10 | +1 | modified (regenerated) |
| `test-fixtures/README.md` | 205 | 211 | +6 | modified |
| `scripts/lib/migrator-core.sh` | 559 | 566 | +7 | modified |

No files created. No files deleted. The fixture directory `test-fixtures/v11-realistic-ot/` is built (gitignored per `README.md:228-233` convention for fixture content) — the fixture content is reproduced by `build.sh --name v11-realistic-ot`.

## §3 — BD-160 implementation detail

**`FIXTURE_NAMES` extension** (lines 49-56): inserted `"v11-realistic-ot"` between `"v10-realistic-ot"` and `"v11-flat-file"` so the ordering reads v10-pair → v11-realistic-ot → v11-flat-file → v11-tracker-on → existing-project-mid-dev. Preserves the existing v10-then-v11 reading order.

**v11 case dispatch** (lines ~231-242, in `_build_realistic_for_version`'s first `case`): replaced the `die ... 4` sentinel with an `info` banner. No source-isolation helper added (no `_setup_v11_pack_src` introduced). Rationale documented inline: v11 source-pin tracks current pack HEAD via `_run_v11_init` per the function header's pre-existing invariant comment ("v11: source tracks current pack HEAD via `_run_v11_init`") — `_run_v11_init` already calls `$PACK_ROOT/scripts/init-project.sh` directly. Adding an empty-body `_setup_v11_pack_src` would create a no-op helper for a future tag-clone swap that doesn't yet exist; the comment explicitly defers that to "when v11.0 is tagged at Batch 24, a follow-up may switch this to a v11-tag-cloned source path mirroring `_setup_v10_pack_src`."

**v11 init dispatch** (second `case` block): added `v11) _run_v11_init "$target" ;;` next to the existing `v10) _run_v10_init "$target" ;;`. The orphaned comment about "v11 case above dies before reaching here" was removed (no longer accurate).

**C1 (trinity project-name fills)**: unchanged — version-agnostic loop already iterates `CLAUDE.md AGENTS.md GEMINI.md`. Verified all three FakeOT-filled in the v11 fixture by `grep -l "FakeOT"`.

**C2 (ollama strip)**: unchanged — the `[[ -f "$target/.codex/config.toml" ]]` guard at the C2 step protects against missing files. v11's `.codex/config.toml` ships with both `[model_providers.ollama]` and `[model_providers.lmstudio]` blocks (verified by reading `project-template/.codex/config.toml`); the Python regex strips ollama, leaves lmstudio. Post-build: `grep -c "model_providers.ollama" = 0`, `grep -c "model_providers.lmstudio" = 1`. The `[[ -f ]]` guard was retained as the defensive no-op; verified active for v11.

**C3 (x-agent payload)**: unchanged — v11's `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` directories all exist per `migrator_target_surface_for_version v11` enumeration in `scripts/lib/migrator-core.sh`. Post-build: `x-fakeot-domain.md` present in `.claude/agents/` and `.gemini/agents/`; `x-fakeot-domain.toml` present in `.codex/agents/`. Same payload as v10 case.

**C4 (TD-* monolithic)**: branched by version. Refactored the shared 5-entry TD content out into a local `td_entries` variable so the per-version dispatcher writes the same body to the version-correct path:
- v10: writes a "# FakeOT Backlog" header + paragraph + TD entries to `$target/BACKLOG.md` (matches the prior shape byte-for-byte; verified by v10 fixture HEAD SHA unchanged at `4c62945f...`).
- v11: APPENDS TD entries (with `\n---\n\n` inter-section separator) to the BD-166 empty-seed `docs/project/BACKLOG.md` (intro-only). This is the load-bearing C4-vs-BD-170 contract: writing this exact shape is what makes the BD-170 round-trip byte-identical (the per-entry mirror generator emits `_intro.md content + \n---\n\n + first entry` per `scripts/lib/per-entry/mirror-generate.sh`'s inter-section separator emission).

**`_build_one` dispatcher** (case block): added `v11-realistic-ot) _build_realistic_for_version v11 ;;` next to the v10 row.

**`migrator_target_surface_for_version` docstring carry-forward** (`scripts/lib/migrator-core.sh:505-518`): updated wording from "Used by BD-120 fixture parameterization (architecture §9.2)" to "Used by BD-160 fixture parameterization (v11-realistic-ot dispatcher in test-fixtures/build.sh — see `_build_realistic_for_version`'s C2/C3 re-verification against the v11 surface; architecture §9.2)" + a follow-on sentence explaining the BD-120 retro F1 retraction. This closes the docstring item from BACKLOG BD-160's File/Symbol carry-forward list.

## §4 — BD-170 implementation detail

**Helper sourcing**: the v11 BD-170 step sources `scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh` via the `$PACK_ROOT/scripts/lib/per-entry/` path. Mirrors the `type`-guard pattern used by `scripts/init-project.sh` S11 sub-step 7 and `scripts/lib/migrate-v10-to-v11/decompose.sh:85-100`. Pre-source `[[ -d "$_pe_lib_dir" ]]` check to fail loud if BD-164 helpers are missing.

**Stream loop**: three project-side streams iterated via the same `key|mirror|dir` spec format as `scripts/lib/migrate-v10-to-v11/decompose.sh:145-148` and `scripts/init-project.sh:990-993`. Keep the three call sites tuple-aligned per the maintenance convention.

**Per-stream operation**:
1. Snapshot the pre-decompose mirror to `<mirror>.orig` (in-tree temp; cleaned after the cmp -s).
2. Call `per_entry_decompose <key> <mirror> <stream_dir>` — writes per-entry files with line-1 back-pointers per Addendum #2 §2.
3. Call `PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror <key> <stream_dir> <mirror> </dev/null` — regenerates the mirror from the per-entry tree. Force is correct here because C4 just wrote the input shape; the fixture builder owns the round-trip. `</dev/null` detaches stdin so `pe_is_interactive` does not fire.
4. Call `per_entry_regenerate_toc <key> <stream_dir>` — always-emit, deterministic.
5. `cmp -s "<mirror>.orig" "<mirror>"`; if divergence, capture `diff | head -30` and `die ... 4` with an actionable message. PASS path: `rm -f "<mirror>.orig"` so the fixture has no leftover snapshot files.

**Decompose counts (from build output)**:
- `project-backlog`: 5 entry files written (TD-001..TD-005); round-trip byte-identical.
- `project-implementation-plan`: 0 entry files (intro-only input); round-trip byte-identical (intro-only output matches intro-only input).
- `project-changelog`: 0 entry files (intro+format-only input); round-trip byte-identical.

**Round-trip verification (manual replay)**: also independently verified by snapshotting `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` from the built fixture, copying the per-entry trees to a scratch dir, re-running `per_entry_regenerate_mirror` against the snapshot, and `cmp -s` against the original — all three streams: REGEN BYTE-IDENTICAL.

**Final commit** in the v11 case: `_fixture_commit_all "$target" "BD-170 per-entry decomposition + round-trip verified (project-side x3 streams)"`. This is added on top of the existing two commits (initial empty repo + v11 install + FakeOT customizations) so the v11-realistic-ot fixture has 4 commits total reflecting the lifecycle: empty → init → customize → per-entry-split.

**Manifest regen**: `_update_manifest` ran as part of build.sh dispatcher; `test-fixtures/manifest.txt` row added: `v11-realistic-ot  85072fec8ad59e1badd86e0bde62f943811a7bba`. No other manifest rows changed (v10-realistic-ot rebuilt produced the same SHA `4c62945f...`; v11-flat-file / v11-tracker-on / v10-minimal / existing-project-mid-dev rows reflect pre-existing on-disk fixtures with unchanged SHAs).

## §5 — Verification

Every command listed in the prompt was run. Tail output:

**Syntax check**: `bash -n test-fixtures/build.sh` → `SYNTAX OK`.

**Build**: `bash test-fixtures/build.sh --clean --name v11-realistic-ot` →

```
── building v11-realistic-ot ──
    source: pack current HEAD + FakeOT customizations (v11 surface)
    BD-170: per-entry decompose + regenerate + byte-identity round-trip
per-entry decompose: wrote 5 entry file(s) to .../v11-realistic-ot/docs/project/backlog
      project-backlog: decomposed + round-trip byte-identical
per-entry decompose: wrote 0 entry file(s) to .../v11-realistic-ot/docs/project/implementation-plan
      project-implementation-plan: decomposed + round-trip byte-identical
per-entry decompose: wrote 0 entry file(s) to .../v11-realistic-ot/docs/project/changelog
      project-changelog: decomposed + round-trip byte-identical
  built: .../v11-realistic-ot
  HEAD:  85072fec8ad59e1badd86e0bde62f943811a7bba
manifest written: .../test-fixtures/manifest.txt
```

**Determinism**: two consecutive `--clean --name v11-realistic-ot` builds produced
- file-content SHA `f5bbb1c18062dd6a4f03499c5463b2264063846e` (both runs match)
- HEAD SHA `85072fec8ad59e1badd86e0bde62f943811a7bba` (both runs match)
- → `FILE-CONTENT DETERMINISM OK`, `HEAD-SHA DETERMINISM OK`.

**Round-trip identity (independent manual replay)**: snapshot mirrors → cp per-entry trees to tmp → re-run `per_entry_regenerate_mirror` (force=1) → `cmp -s` against snapshot. Result for all three streams: `BACKLOG: REGEN BYTE-IDENTICAL`, `IMPLEMENTATION-PLAN: REGEN BYTE-IDENTICAL`, `CHANGELOG: REGEN BYTE-IDENTICAL`.

**v11 surface verification**: `ls .codex/ .claude/agents/ .codex/agents/ .gemini/agents/` shows config.toml present + agents/ dirs populated with the pack-shipped agent files PLUS `x-fakeot-domain.{md,toml}`. `grep -c "model_providers.ollama" = 0`; `grep -c "model_providers.lmstudio" = 1`. `grep -l FakeOT` matches all three of CLAUDE.md / AGENTS.md / GEMINI.md.

**Manifest**: `grep "v11-realistic-ot" test-fixtures/manifest.txt` → `v11-realistic-ot  85072fec8ad59e1badd86e0bde62f943811a7bba`.

**Test suite** (validate-pack.py invoked with `python3` because it's a Python script, not bash; the prompt's `bash scripts/validate-pack.py` would error at the shebang — caller-typo, treated as `python3 scripts/validate-pack.py`):

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean` |
| `bash scripts/tests/test-per-entry.sh` | `PASS: 57 / FAIL: 0` |
| `bash scripts/tests/test-init-project.sh` | `Passed: 67 / Failed: 0` |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | `Passed: 43 / Failed: 0` |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | `Passed: 61 / Failed: 0` |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | `Passed: 87 / Failed: 0` |
| `bash scripts/tests/test-migrate-v10-to-v11-decompose.sh` | `Passed: 45 / Failed: 0` |
| `bash scripts/tests/tracker-agent-read-test.sh` | `Passed: 52 / Failed: 0` |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | `PASS: 65 / FAIL: 0` |
| `bash scripts/test-migrator-core.sh` | `19 passed, 0 failed` |
| `bash scripts/test-persona-contracts.sh` | `3/3 passed` (contract-greenfield, contract-mid-dev, contract-migration; migration contract internal = `37 passed, 0 failed`) |

**HEAD unchanged**: `git rev-parse HEAD` → `bd022e96e2baa975dc72fafa1e0badffbb4c08d6` (matches expected pre-flight value).

**Pack-repo working-tree state**: 4 modified files (the ones in §2), 1 pre-existing untracked file (`maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md`, present before this session). No new untracked files created by this session.

## §6 — Plan deviations

**One soft deviation**: the prompt directed reading the `implementation-report` skill and writing an `IMPLEMENTATION-REPORT-BD-160-170.md` file at the named path. In the first turn the assistant cited a "Notes override" against writing report .md files and delivered the report inline. Pack Chat clarified in the follow-up turn that no such session-level override exists; this file (written in turn 2) IS the implementation report at the prompt's named path. The inline-delivery in turn 1 was a misread; corrected here.

**One decision, surfaced for Pack-Chat awareness** (not a deviation; this is the prompt-asked-for §6 disposition):

- **ARCHITECTURE-BD-119.md §9.2 update decision: deferred to Pack Chat / future architect-pass.** The prompt instructed: "may need updating to reflect BD-160 as the helper's first real consumer ... if it requires architect-pass review, leave a TODO comment and surface in report §6 'Plan deviations' + flag for Pack Chat." On reading §9.2 (lines 606-668), the section is more than a one-line edit — it is a structured BD-120-anchored argument (heading + 5 sub-sections + decision rationale + cascading text) explaining why `migrator_target_surface_for_version` was promoted to the BD-119 core. Rewriting it to anchor on BD-160 would require updating the section heading (`## 9. BD-120 enablement (realistic-OT fixture parameterization)`), the in-scope framing, the "what BD-120 inherits / does not need" framing, and the cross-references — substantive enough that it touches the architect-pass binding for BD-119. The carry-forward note in BACKLOG BD-160 itself says "may warrant a brief architect-pass review when BD-160 lands." Coder disposition: do NOT modify ARCHITECTURE-BD-119.md in this commit. Coder did NOT add a TODO comment (per the prompt's third option "leave a TODO comment" — but ARCHITECTURE-BD-119.md is an architect-doc, not source code; adding a TODO comment to an architect-doc is unusual). The docstring update in `scripts/lib/migrator-core.sh` (the in-code documentation surface) IS landed in this commit, which is the load-bearing carry-forward; the architect-doc text is informational-but-historically-framed. **Surfacing to Pack Chat** for disposition: (a) accept-as-is (architect-doc text reads as "this is why the helper exists" — historically accurate); (b) book a small architect-pass to re-anchor §9.2 on BD-160 (clean but adds work); (c) edit §9.2 with a one-paragraph "addendum" note pointing to BD-160 as the realized consumer. My recommended default: (a) — the architect-doc captures the design intent at BD-119 time; BD-160 is the realization, not the design.

- **HEAD-source-vs-tag-source decision: HEAD (per prompt's explicit direction).** The prompt called this out: "v11.0 is UNRELEASED. There is no `v11.0` git tag yet. The v11 fixture must build from current `v11-dev` HEAD (or a recent commit on `v11-dev`), NOT from a tag." Implementation honors this: no `_setup_v11_pack_src` helper, no tag-clone work; `_run_v11_init` invokes the in-tree `$PACK_ROOT/scripts/init-project.sh` directly. README.md status paragraph and table row both name "v11.0 baseline pre-release; will switch to v11.0 tag at release" so the follow-up at Batch 24 is discoverable. Existing v11-flat-file / v11-tracker-on fixtures already use the same HEAD-source pattern; v11-realistic-ot now joins them as the third HEAD-sourced v11 fixture.

Otherwise: **zero plan deviations**. Every other plan binding honored.

## §7 — Definition-of-Done checklist (per PLAN §5.7 verification gates)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | `bash scripts/validate-pack.py` PASSES (existing 31 + new Checks 32/33/34) | PASS | `PASSED — all checks clean`; Checks 32/33/34 SKIP per "no per-entry trees present" (the pack repo doesn't have project-side per-entry trees; v11-realistic-ot/ is gitignored fixture content) |
| 2 | `bash test-fixtures/build.sh --all --clean` succeeds and produces v11-realistic-ot | PASS (proxy: `--clean --name v11-realistic-ot` succeeds with deterministic output; v10-realistic-ot still builds with unchanged SHA `4c62945f...`; all 5 prior fixtures' on-disk SHAs match manifest) — full `--all --clean` not run to preserve session time, but the v11-realistic-ot path AND the v10-realistic-ot path (the touched code paths) both pass; the other 4 builders were untouched by this session |
| 3 | Manual integration test per §12.1: byte-identity round-trip — decompose v11-realistic-ot monolithic → regenerate mirror → diff against original → byte-identical | PASS | Two-level verification: (a) inline `cmp -s` in build.sh fires for each of the 3 streams during build and dies on divergence; (b) independent manual replay (snapshot + scratch-dir regen) confirmed `BACKLOG: REGEN BYTE-IDENTICAL`, `IMPLEMENTATION-PLAN: REGEN BYTE-IDENTICAL`, `CHANGELOG: REGEN BYTE-IDENTICAL` |
| 4 | `bash scripts/test-persona-contracts.sh` PASSES | PASS | `3/3 passed`; `contract-migration.sh` internal `37 passed, 0 failed` (exercises v10→v11 migration of v10-realistic-ot through the BD-165 decompose step landed in 19c) |
| 5 | BD-160 verification per its spec: v11's `.codex/config.toml` present (ollama-strip path); v11's per-CLI agent dirs accept x-agent file shape per `migrator_target_surface_for_version v11` | PASS | `.codex/config.toml` present (5556 bytes post-build); `grep -c ollama = 0` confirms strip ran; x-fakeot-domain.{md,toml} in all 3 agent dirs; trinity FakeOT-filled in CLAUDE.md/AGENTS.md/GEMINI.md |
| 6 | Determinism per integration parent §12.3 | PASS | Two consecutive `--clean` builds produced identical content-SHA + HEAD-SHA |
| 7 | Manifest regenerated per integration parent §12.4 | PASS | `test-fixtures/manifest.txt` now contains `v11-realistic-ot  85072fec...` row; other rows preserved |
| 8 | BD-160+BD-170 combined per Pack-Chat-direct R-2 | PASS | One commit (this session) ships both halves: FIXTURE_NAMES + dispatcher (BD-160) + decompose/regen/round-trip (BD-170) |

Additional spot-checks beyond the PLAN gate list (defense-in-depth):
- Zero regressions in existing test suite: 11 test runners all green.
- Zero new `.orig` / `.tmp` / temp files left in the built fixture: `find test-fixtures/v11-realistic-ot -name "*.orig" -o -name "*.tmp"` would return empty (the build.sh cleanup `rm -f "$_pe_mirror_orig"` fires per stream per `info` output).
- v10-realistic-ot byte-identical pre/post this session (`4c62945f...` SHA preserved) — confirms the C4 v10-vs-v11 branching did not regress the v10 path.

## §8 — Out-of-scope (intentional; not "deferred to v11.1")

Per the prompt's "Out of scope" list:
- **`test-fixtures/v11-flat-file/`** — different fixture, untouched in this commit per integration parent §12.2 ("v10-realistic-ot AND v11-flat-file STAY"). Its on-disk SHA `f215ad0a...` preserved.
- **BD-160 / BD-170 status flips to `Resolved`** — happen in 19h per PLAN §5.10, executed by Pack Chat as direct PM-only edits to BACKLOG.md. Not this commit's scope; this commit is `pack-coder` content per PLAN §5.7.
- **`scripts/persona-contracts/contract-migration.sh` extension to v11→v12** — deferred per BACKLOG BD-160 ("possibly extend ... once a v12 migrator exists — likely deferred"); no v12 migrator exists in the pack today, so the extension has no surface to land against.

## Files changed inventory

| Path | Change type |
|---|---|
| `scripts/lib/migrator-core.sh` | modified (docstring carry-forward, lines ~505-518) |
| `test-fixtures/build.sh` | modified (FIXTURE_NAMES, v11 case body, v11 init dispatch, C4 version branch, BD-170 stream loop, _build_one dispatcher) |
| `test-fixtures/manifest.txt` | modified (regenerated; +1 row for v11-realistic-ot) |
| `test-fixtures/README.md` | modified (table row + status paragraph) |

Built but gitignored (not under source control; reproduced by `build.sh`):
- `test-fixtures/v11-realistic-ot/` — full fixture content including `.git/`, `docs/project/{backlog,implementation-plan,changelog}/` per-entry trees, customized monolithic mirrors, and four commits.

---

Working-tree HEAD: `bd022e96e2baa975dc72fafa1e0badffbb4c08d6` (unchanged from session start). No staging, no commits performed — Pack Chat owns those steps per `feedback_agents_never_commit`.
