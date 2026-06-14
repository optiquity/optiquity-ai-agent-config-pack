# IMPL-REPORT — BD-197 commit C8a (project OPTIONAL-FEATURES isolation section + documented-optional `permissions.deny` recipe; DATA half; project-only)

**Role:** pack-coder. **Mode:** RW within caller scope (in-place regime — no `/tmp` handoff dir named; edits left in working tree, `git diff` emitted for auditability below).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** `v11-dev`.
**HEAD (pre-flight and post-edit, no commit — agents never commit):** `13bb32eee5b36529dd36b7c3eaaf2e4a81f2d10d`.
**Date:** 2026-06-14.
**Scope keyword:** `project-only` (edits `project-template/` only + the scope-neutral carved-out `test-fixtures/manifest.txt`).
**Boundary:** C8a is the DATA half. It does NOT add Guard-A′ (Check 54) — that is C8b. No pack-side surface touched.

---

## Read attestation

I read each NAMED authoritative doc directly and in full (no skim, no summary, no derivation) before editing:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §3 (the corrected two-independent-mechanisms mode model: Mechanism A = per-spawn Agent-tool `isolation:"worktree"` PARAM trigger + `worktree.baseRef` BASE; Mechanism B = `worktree.bgIsolation` background-session gate, scoped out), §7 (the launcher / NEW-FORK-1 = gate-then-probe-then-degrade; launcher HEAD-basing PROVEN settings-independent), §8 (graceful-degradation matrix incl. silent-fall-to-MAIN + `fresh`=origin/main wrong-base), §9 (OPTIONAL-FEATURES content, both surfaces separately authored — pack `pack-ops/`, client `project-template/docs/pack/`), §18.2 (the documented-optional `permissions.deny` recipe; F1–F5; the 3-layer backstop; J4=NO new shipped file).
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — §B "C8a" (lines 152–155, the project DATA half: client audience, "PM Chat" orchestrator, TRIGGER/BASE/`bgIsolation`/`permissions.deny` recipe, `agent-run.sh --worktree` launcher, ZERO pack-self refs, NO 9-cell matrix, manifest regen, PREFLIGHT 3-token) + §B "C8b" (lines 157–161, the GUARD half — confirmed NOT in my scope) + §B "C5" (line 116, the pack reference for content coverage) + §C green-per-commit (C8a→C8b data-first) + §D full-CI-battery wired list.
- `pack-ops/OPTIONAL-FEATURES.md` — C5's pack section (the COVERAGE reference; authored the project version INDEPENDENTLY, not byte-copied).
- `project-template/docs/pack/OPTIONAL-FEATURES.md` — the file I edited (existing client doc, 5490 bytes pre-edit).
- `project-template/agent-run.sh` — the `--worktree` launcher landed in C7a (lines 160–164 usage, 234–292 `run_in_worktree` + cwd-scoping caveat + manual fallback + cross-refs to PM-CHAT.md / OPTIONAL-FEATURES.md).
- `project-template/docs/pack/PM-CHAT.md` — the C7a in-session spawn instruction (lines 455–530: in-session Agent/Task spawn, `isolation:"worktree"` for RW only, background, `/tmp`-patch merge-back, conflict, and its two cross-references INTO `docs/pack/OPTIONAL-FEATURES.md` — the launcher + the degradation cases).
- `CLAUDE.md` § "## Pack memory" (full) — `bd-pack-only-operational-rule`, `pack-project-separation-of-concerns`, `client-ref-delete-or-forward-look`, `regenerate-manifest-v11-surface`, `edit-in-place-not-full-rewrite`, plus the universal rules.
- Curated memory (full): `feedback_bd_pack_only_operational_rule.md`, `feedback_pack_project_separation_of_concerns.md`, `feedback_client_ref_delete_or_forward_look.md`, `feedback_manifest_regen_on_v11_surface.md`.

---

## Boundary discipline check (P-missed-7)

My single edited project-side file is `project-template/docs/pack/OPTIONAL-FEATURES.md` (a pack-shipped client surface). SSOT investigation per the pre-flight:

- **Concept "worktree-isolation opt-in feature for the client developer":** project-side SSOT is `project-template/docs/pack/OPTIONAL-FEATURES.md` itself (the client opt-in feature catalog). Implemented IN that SSOT, client-native — NOT importing the pack `pack-ops/OPTIONAL-FEATURES.md` as a fallback (`pack-project-separation-of-concerns`).
- **Concept "orchestrator role":** project-side SSOT is `project-template/docs/pack/PM-CHAT.md` (the PM chat). All orchestrator references in my edit say "PM chat" — never "Pack Chat".
- **Concept "in-session spawn + merge-back + degradation cases":** project-side SSOT is `project-template/docs/pack/PM-CHAT.md` "In-session agent spawning" (C7a). My edit cross-references it (`docs/pack/PM-CHAT.md`) for the merge-back procedure and provides the degradation-cases home PM-CHAT.md points back to (silent-fall-to-main, wrong-base) — closing the C7a forward reference.
- **Concept "isolated-worktree launcher":** project-side SSOT is `project-template/agent-run.sh` (`--worktree`, C7a). My edit documents that flag + its cwd-scoping caveat + manual fallback, referencing `agent-run.sh` and its `run_in_worktree` comment — never a pack launcher.
- **Concept "future cross-CLI / background-session work":** NO `BD-NNN` SSOT exists on the client side (see the future-reference convention finding below). Implemented with neutral phrasing ("a future pack version", "tracked separately and is out of scope here") per the existing client-doc convention — NO pack-self BD framing.

**Boundary discipline stop:** NONE. No edit adds a reference to a pack-only file (`pack-ops/`, `maintenance-docs/`, `pack-*` agent name, "Pack Chat", `validate-pack.py`, `PACK-AGENTS.md`, `PACK-CHAT.md`) or a `BD-NNN` token. Grep-proven below (ZERO pack-self).

---

## Client-doc future-reference convention finding (boundary-investigation)

The prompt allowed BD-218 as a forward pointer ONLY if the existing client docs already use that convention. Investigation result — they do NOT:

```
$ grep -rn "BD-218\|BD-217" project-template/        →  (no matches)
$ grep -rn "BD-[0-9]" project-template/               →  (no matches anywhere)
```

ZERO `BD-NNN` tokens exist anywhere under `project-template/`. The existing client-doc convention for future pack work is NEUTRAL phrasing (measured):

```
project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:6: ...retained dormant ... for a future
project-template/docs/pack/PM-CHAT.md:629: ...DEFERRED to a future release...
project-template/docs/pack/PLATFORM-SKILLS.md:581: ...a future v12...
project-template/docs/pack/OPTIONAL-FEATURES.md:114 (pre-edit Agent-Teams-era): "a possible future resumption"
```

By contrast the PACK version (`pack-ops/OPTIONAL-FEATURES.md`) DOES carry `BD-218` (1) and `BD-217` (1) — correct for the pack audience, wrong for the client. Per `bd-pack-only-operational-rule` (BDs are categorically pack-self and forbidden in project directories) + the measured convention, I used neutral phrasings ("a future pack version", "tracked separately and is out of scope here", "a separate concern slated for a future pack version") and introduced NO BD token. This is the boundary-correct disposition, overriding the prompt's conditional BD-218 allowance because the condition ("matches how existing client docs reference future work") is FALSE.

---

## What I did (per design §9/§18.2/§3/§7 + plan §B C8a)

Added one new section `## Claude Code — Isolated parallel agents (worktree isolation)` to `project-template/docs/pack/OPTIONAL-FEATURES.md`, inserted after the existing `## Claude Code — Agent Teams` section and before the `## Codex CLI — Optional features` placeholder (targeted in-place insert via Edit; no wholesale rewrite — `edit-in-place`). Authored INDEPENDENTLY for the CLIENT developer audience. Content:

1. **Status / What it is / When it matters** — client-native; cross-CLI story "tracked separately and is out of scope here"; the in-session spawn + merge-back procedure pointer to `docs/pack/PM-CHAT.md` "In-session agent spawning".
2. **TRIGGER (per task)** = the per-spawn Agent-tool `isolation:"worktree"` PARAMETER (only valid param value; `head`/`none` are SETTINGS values, NOT param values; omit ⇒ in-place; PM chat decides per spawn, never by writing settings).
3. **BASE (REQUIRED setting)** = `worktree.baseRef: "head"` (valid values `"head"`/`"fresh"`) so isolated worktrees branch from LOCAL HEAD; explicit consequence stated: unset/`"fresh"` defaults to `origin/<default>` (origin/main) — the historical wrong-base degradation (still functional, wrong base); WHERE it lives (per-project `.claude/settings.json` recommended OR global `~/.claude/settings.json`); a JSON snippet.
4. **`worktree.bgIsolation`** = described ACCURATELY as the background-SESSION gate (enum `["worktree","none"]`, default `"worktree"`; blocks Edit/Write to main until `EnterWorktree`) that does NOT control the agents the PM chat spawns; NOT a boolean (`bgIsolation:true` invalid); pointer to "a future pack version" (NO BD token — convention-correct).
5. **The documented-optional user `permissions.deny` recipe (§18.2)** = the in-session mechanical hard-deny: a `permissions.deny` block of `Bash(git <verb>:*)` rules (the §5.1 destructive-verb set: commit, push, add, stash, reset, restore, checkout, apply, worktree, clean, merge, rebase) the CLIENT developer adds to THEIR OWN `settings.json` (user or project scope); session-scoped + INHERITED by all in-session sub-agents (incl. background); deny-first (not bypassed by `bypassPermissions`); the ONLY in-session mechanical layer (agent-file `tools:` is tool-name-level only; no per-spawn deny param); VERB-PRECISE — denies `Bash(git apply:*)` but NEVER `Bash(git diff:*)` (the patch-emit; `git diff > file` redirect is shell-level, not tripped); the PreToolUse hook is SECONDARY/fails-open; the pack ships neither the settings file nor the hook; without it the protection degrades to the always-on prose deny-list + behavioral contract.
6. **The `agent-run.sh --worktree` launcher (SECONDARY path)** = documented with the HEAD-basing (settings-independent, `git worktree add --detach <path> HEAD`), the cwd-scoping caveat (probe-then-degrade: run a no-op isolated agent, confirm main tree unchanged; if leaked, fall back to manual), the manual fallback, and the cross-ref to `agent-run.sh` `run_in_worktree` comment + `docs/pack/PM-CHAT.md` merge-back.
7. **Caveats** = version-sensitive, auto-removal can delete unmerged branches (why merge-back captures the patch before return), best-effort/silent-fall-to-main (PM chat detects ACTUAL regime from what the agent reports, never from settings), `baseRef` unset/`fresh` wrong-base (surfaced, never silent). These close the degradation-cases forward reference that PM-CHAT.md line 528–530 points here.
8. **"The pack ships NO settings file"** explicit + the manual-worktree one-liner (`git worktree add ../my-worktree <branch>`).

NO 9-cell matrix; NO "bgIsolation is the trigger" framing (both removed from the design §3).

---

## Section before/after

**Before (relevant anchor — the file went directly from the Agent-Teams section to the Codex placeholder):**

```
## Claude Code — Agent Teams
... (existing Agent-Teams content, unchanged) ...

## Codex CLI — Optional features

*Placeholder. The Config Pack will document Codex-specific opt-in
features here as they ship and prove useful.*
```

**After (new section inserted between them; Agent-Teams + Codex placeholder unchanged):**

```
## Claude Code — Agent Teams
... (existing Agent-Teams content, unchanged) ...

## Claude Code — Isolated parallel agents (worktree isolation)
**Status:** ... (NEW — 178 inserted lines; full text in "New/changed content" below) ...
**The pack ships NO settings file.** ...
**Manual worktree (no pack mechanism needed).** ...

---

## Codex CLI — Optional features

*Placeholder. The Config Pack will document Codex-specific opt-in
features here as they ship and prove useful.*
```

Diff stat: `project-template/docs/pack/OPTIONAL-FEATURES.md | 178 ++++` (178 insertions, 0 deletions to existing content).

---

## 3-token PREFLIGHT grep (decision 7)

Baseline at HEAD `13bb32e` (plan §F EE-12 expected 0/0/0):

```
$ grep -c 'baseRef'           project-template/docs/pack/OPTIONAL-FEATURES.md   →  0  (pre-edit)
$ grep -c 'bgIsolation'       ...                                               →  0  (pre-edit)
$ grep -c 'permissions.deny'  ...                                               →  0  (pre-edit)
```

Post-edit:

```
$ grep -c 'baseRef'            project-template/docs/pack/OPTIONAL-FEATURES.md  →  10
$ grep -c 'bgIsolation'        ...                                              →   6
$ grep -c 'permissions\.deny'  ...                                              →   4
```

**RESULT: PASS** — the project file mentions `baseRef` AND `bgIsolation` AND the `permissions.deny` recipe token (the project-side half of the three tokens the EXTENDED Guard-A′ asserts in C8b).

---

## ZERO pack-self refs (grep-proven)

```
$ grep -n "maintenance-docs"                                          <file>  →  NONE
$ grep -n "pack-ops"                                                   <file>  →  NONE
$ grep -n "Pack Chat"                                                  <file>  →  NONE
$ grep -nE "pack-(coder|architect|planner|reviewer|docs-researcher|fix-coder)" <file> → NONE
$ grep -nE "BD-[0-9]"                                                  <file>  →  NONE
$ grep -nE "validate-pack|PACK-AGENTS|PACK-CHAT"                       <file>  →  NONE
$ grep -cE "maintenance-docs|pack-ops|Pack Chat|pack-(coder|architect|planner|reviewer|docs-researcher)|BD-[0-9]|validate-pack|PACK-AGENTS|PACK-CHAT" <file> → 0
```

**RESULT: ZERO pack-self references.** (`docs/pack/PM-CHAT.md` and `agent-run.sh` are CLIENT paths, not pack-self.)

---

## Client-native, NOT a byte-copy (confirmation)

The project section was authored INDEPENDENTLY for the client developer audience. How it DIFFERS from the pack `pack-ops/OPTIONAL-FEATURES.md` section:

| Dimension | Pack version (`pack-ops/OPTIONAL-FEATURES.md`) | Client version (this edit) |
|---|---|---|
| Orchestrator | "Pack Chat" (3 occurrences) | "PM chat" (10 occurrences); ZERO "Pack Chat" |
| Future-work pointer | `BD-218` (1), `BD-217` (1) | neutral "a future pack version" / "tracked separately and is out of scope here"; ZERO BD tokens |
| Audience phrasing | "the Config Pack", pack-developer framing | "your project", "your branch", "your repo", "your machine" (14 occurrences); developer framing |
| Launcher | (pack has no `agent-run.sh`; pack version omits a launcher path) | documents the project `agent-run.sh --worktree` flag (4 refs) + `run_in_worktree` cross-ref |
| Cross-refs | pack-internal | `docs/pack/PM-CHAT.md` (2 refs), `agent-run.sh` (CLIENT paths) |

Direct diff (the two isolation sections are NOT byte-identical):

```
$ diff <(pack isolation section) <(client isolation section)   →  non-empty (differs throughout)
pack section lines:   159
client section lines: 179
$ grep -c 'Config Pack stays cross-CLI' <client file>          →  0   (pack-only phrasing absent)
$ grep -c 'Pack Chat' <pack file> / <client file>              →  3 / 0
$ grep -c 'PM chat'   <pack file> / <client file>              →  (pack uses different framing) / 10
```

**RESULT: client-native, SEPARATE artifact, not a fallback for the pack version** (`pack-project-separation-of-concerns`).

---

## Manifest regeneration (v11-surface change; KEPT)

`project-template/docs/pack/OPTIONAL-FEATURES.md` ships into the v11 fixtures → `test-fixtures/manifest.txt` regenerated:

```
$ bash test-fixtures/build.sh --all --clean   →  exit 0
$ git diff test-fixtures/manifest.txt:
  -v11-realistic-ot  527e474aa8445230590f7d4a5b6e11fb7983658b
  -v11-flat-file     690f762a14f22f925bc3825d1f67356ed2852566
  -v11-tracker-on    04ecf5644a76461c248177e48212d8d10ec7d8c6
  +v11-realistic-ot  a34a8b3de811a5bc4e3dc3442cff50a1a10b3666
  +v11-flat-file     3dccbbd4ec78644aff8f39017e6499e980273fa0
  +v11-tracker-on    98b52fd37921a6aa8f212236e0b0c9762cff1f96
```

Diff is NON-EMPTY (3 v11 fixture SHAs changed — confirms the edit ships into the fixtures). The regenerated manifest is KEPT (left MODIFIED + UNSTAGED in the working tree; the orchestrator stages it WITH the `project-only` commit via the C0 carve-out). I did NOT restore the old manifest and did NOT run `git checkout` (denied verb) — I used `git show HEAD:...`/`cp` only to reproduce CI semantics during verification (see below), then restored my regenerated manifest with `cp`.

```
$ bash test-fixtures/build.sh --verify   (against the KEPT regenerated manifest)  →  exit 0  (all 6 fixtures OK)
$ diff -q test-fixtures/manifest.txt /tmp/c8a-manifest-regenerated.txt            →  IDENTICAL (kept)
$ git status --short:
   M project-template/docs/pack/OPTIONAL-FEATURES.md
   M test-fixtures/manifest.txt
```

Exactly two modified files, both UNSTAGED. (Note: `build.sh --verify` against the PRE-edit COMMITTED manifest returns exit 1 with MISMATCH warnings on the 3 v11 fixtures — that is the EXPECTED, correct pre-commit state: the committed manifest is stale until the orchestrator commits my regenerated one. CI restores the COMMITTED manifest before verify; after this commit lands, that committed manifest IS the regenerated one, so CI verify is green — proven by the regenerated-manifest verify exit 0 above.)

---

## Check-36 carve-out confirmation (project-only, manifest exempt)

The `project-only` commit set = `{project-template/docs/pack/OPTIONAL-FEATURES.md, test-fixtures/manifest.txt}`. Validator logic (`scripts/validate-pack.py`):

- `_is_project_side_path("project-template/docs/pack/OPTIONAL-FEATURES.md")` → `True` (project-side; not an offender).
- `test-fixtures/manifest.txt` is in the `_SCOPE_NEUTRAL_GENERATED_PATHS` frozenset (line 4136–4137) and is excluded from the Check-36 offender comprehensions via `_is_scope_neutral_generated` (lines 4339, 4353) — the C0 carve-out.

Reproduced:

```
project_only offenders (manifest exempt):  []
CARVE-OUT RESULT: CLEAN (no offenders)
OPTIONAL-FEATURES is_project_side: True
```

**RESULT: a `project-only` commit of this set has NO offenders** (manifest exempt; project-template file project-side). Check 36 clean.

---

## FULL CI suite results (every wired script in `.github/workflows/validate-pack.yml`; no sampling)

**`validate` job (2 invocations):**

| Command | Exit |
|---|---|
| `python3 scripts/validate-pack.py` | **0** (PASSED — all checks clean) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** (PASSED — all checks clean) |

**`tests` job (every wired script, in yml order; all exit 0):**

| Script | Exit | | Script | Exit |
|---|---|---|---|---|
| test-detect.sh | 0 | | tracker-deferral-gate-test.sh | 0 |
| tracker-provider-test.sh | 0 | | tracker-bd129-gh-repo-test.sh | 0 |
| tracker-config-test.sh | 0 | | tracker-bd130-doctor-wired-test.sh | 0 |
| tracker-init-test.sh | 0 | | tracker-bd132-race-test.sh | 0 |
| tracker-agent-read-test.sh | 0 | | tracker-bd133-header-preservation-test.sh | 0 |
| tracker-migrate-forward-test.sh | 0 | | tracker-bd134-close-retry-test.sh | 0 |
| tracker-migrate-reverse-test.sh | 0 | | recommendation-test.sh | 0 |
| tracker-migrate-roundtrip-test.sh | 0 | | pack-help-test.sh | 0 |
| test-tracker-phase-task.sh | 0 | | test-customization-preserve.sh | 0 |
| test-tracker-links.sh | 0 | | test-init-project.sh | 0 |
| test-tracker-cycle-check.sh | 0 | | test-migrate-v10-to-v11.sh | 0 |
| tracker-errors-test.sh | 0 | | test-migrate-v10-to-v11-dry-run.sh | 0 |
| tracker-config-schema-test.sh | 0 | | test-migrate-v10-to-v11-gates.sh | 0 |
| recommendation-state-schema-test.sh | 0 | | test-migrate-v10-to-v11-decompose.sh | 0 |
| test-per-entry.sh | 0 | | test-migrator-core.sh | 0 |
| test-validate-pack-checks-32-33-34.sh | 0 | | test-migrator-manifest.sh | 0 |
| test-validate-pack-checks-36-37-38.sh | 0 | | test-migrator-capability-translation.sh | 0 |
| test-validate-pack-check-39.sh | 0 | | build.sh --all --clean (fixture build) | 0 |
| test-validate-pack-check-40.sh | 0 | | build.sh --verify (vs regenerated manifest) | 0 |
| test-validate-pack-check-41.sh | 0 | | test-v11-realistic-ot.sh | 0 |
| test-validate-pack-check-18.sh | 0 | | test-migrator-skills.sh | 0 |
| test-validate-pack-check-16.sh | 0 | | test-persona-contracts.sh | 0 |
| test-validate-pack-check-19.sh | 0 | | template-translations-test.sh | 0 |
| test-validate-pack-check-42.sh | 0 | | template-version-test.sh | 0 |
| test-validate-pack-check-43.sh | 0 | | test-issue-forms.sh | 0 |
| test-validate-pack-check-44.sh | 0 | | | |
| test-validate-pack-check-45.sh | 0 | | | |
| test-validate-pack-check-46.sh | 0 | | | |
| test-validate-pack-check-removed-doc-advisory.sh | 0 | | | |
| test-validate-pack-check-49-field-faithfulness.sh | 0 | | | |
| test-validate-pack-check-50-codec-single-source.sh | 0 | | | |
| test-validate-pack-check-51-flip-block.sh | 0 | | | |
| test-validate-pack-check-52.sh | 0 | | | |
| test-validate-pack-check-53.sh | 0 | | | |
| test-validate-pack-check-56.sh | 0 | | | |
| test-validate-pack-check-55.sh | 0 | | | |
| test-validate-pack-check-57.sh | 0 | | | |

**Tally:** validate job 2/2 exit 0; tests job 60 scripts + the fixture build/verify trio, all exit 0; **0 FAIL across the entire battery.**

Note on the fixture trio: CI does `build.sh --all --clean` → `git checkout HEAD -- manifest` → `build.sh --verify`. `git checkout` is a denied verb for agents, so for the local restore I used `git show HEAD:test-fixtures/manifest.txt > test-fixtures/manifest.txt` (read-only git + shell redirect). Restoring the COMMITTED (pre-edit, stale) manifest then verifying returns exit 1 (the 3 expected MISMATCH warnings — correct pre-commit state). Restoring my REGENERATED manifest (= what the orchestrator commits) then verifying returns exit 0 — this is the CI post-commit state and is the meaningful green. The working tree was left with the regenerated manifest (kept).

---

## Plan deviations

**ONE deviation, boundary-mandated and documented:** the prompt's conditional allowance of a `BD-218` forward pointer was NOT exercised, because the boundary investigation showed the existing client docs use NO `BD-NNN` tokens (ZERO under `project-template/`) and instead use neutral "a future ..." phrasing. Per the prompt's own escape clause ("if uncertain, use neutral phrasing — do NOT introduce a pack-self framing that the existing client docs don't already use") and `bd-pack-only-operational-rule`, I used "a future pack version". This is compliance with the rule, not a divergence from intent — the prompt explicitly conditioned BD-218 on matching the existing convention, and the convention does not include BD tokens.

No other deviations. C8a scope honored exactly: project DATA half only; NO Guard-A′ (C8b); no pack-side surface touched.

---

## New POQs introduced

NONE. The plan + design fully specified the content; no architecture gap was found.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| New `## Claude Code — Isolated parallel agents (worktree isolation)` section added to `project-template/docs/pack/OPTIONAL-FEATURES.md`, client-native | **PASS** |
| TRIGGER documented = per-spawn Agent-tool `isolation:"worktree"` PARAMETER (only valid value; head/none are settings) | **PASS** |
| BASE documented = `worktree.baseRef:"head"` REQUIRED + unset/`fresh`=origin/main wrong-base consequence stated | **PASS** |
| `worktree.bgIsolation` = background-SESSION gate, NOT subagent control, not a boolean; neutral future-version pointer (NO BD token) | **PASS** |
| Documented-optional user `permissions.deny` recipe (§18.2): session-scoped + inherited + deny-first; VERB-PRECISE (deny apply, never diff); PreToolUse hook SECONDARY/fails-open; pack ships no settings file/hook | **PASS** |
| `agent-run.sh --worktree` launcher (SECONDARY) documented with cwd-scoping caveat + manual fallback (NEW-FORK-1 gate-then-probe-then-degrade) | **PASS** |
| Caveats + manual-worktree one-liner + "pack ships NO settings file" | **PASS** |
| 3-token PREFLIGHT (baseRef + bgIsolation + permissions.deny all present) | **PASS** (10 / 6 / 4) |
| ZERO pack-self refs (grep-proven) | **PASS** (0) |
| Client-native, NOT a byte-copy of the pack version | **PASS** |
| NO 9-cell matrix; NO bgIsolation-as-trigger | **PASS** |
| Manifest regenerated (non-empty), KEPT, `--verify` green vs regenerated manifest | **PASS** |
| Check-36 carve-out clean for the `project-only` set | **PASS** |
| FULL CI battery green (validate ×2 + every tests-job script + fixture build/verify) | **PASS** |
| NO Guard-A′ / no C8b work; no file outside `project-template/` + `manifest.txt` + this report | **PASS** |
| No state-changing git verb run (agents-never-commit) | **PASS** |

---

## Files changed (inventory)

| Path | Change type |
|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified (+178 lines: one new section; no deletions to existing content) |
| `test-fixtures/manifest.txt` | modified (regenerated; 3 v11 fixture SHAs updated; scope-neutral via C0 carve-out — KEPT/unstaged) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C8a.md` | new (this report) |

`git diff` (for orchestrator auditability/apply) — the in-scope change is the two non-report files above; both left UNSTAGED in the working tree at HEAD `13bb32e`. No `/tmp` handoff dir was named in the prompt (in-place regime), so the report is written to the named parent-tree path.

---

## New/changed content — full text of the inserted section

The single new section inserted into `project-template/docs/pack/OPTIONAL-FEATURES.md` (so Pack Chat can re-apply without re-deriving):

```markdown
## Claude Code — Isolated parallel agents (worktree isolation)

**Status:** Claude Code only — no Codex or Gemini CLI equivalent yet (the
cross-CLI worktree story is tracked separately and is out of scope here). The
subagent-isolation trigger is a per-spawn Agent-tool parameter; the base
posture is a `settings.json` key you set manually. The pack ships NO settings
file — you add the keys to your OWN settings (see below).

**What it is.** When the PM chat spawns a read-write agent (your `coder`, or
`repo-ops` for scripted writes) in the background to make edits in parallel, it
can isolate that agent in its own git worktree so the agent's edits never touch
your main working tree directly. The agent edits in the worktree, emits a `git
diff` patch to a named handoff directory, and returns; the PM chat reads the
patch, runs the review/fix cycle, applies it onto your branch, and commits — the
agent itself never stages or commits (the no-state-changing-git contract is
preserved end-to-end). Read-only agents (your `architect`, `reviewer`,
`planner`, the `auditor` family, and the other report-only profiles) need NO
isolation — they emit a report and write nothing to the tree. The in-session
spawn + merge-back procedure lives in `docs/pack/PM-CHAT.md` ("In-session agent
spawning").

**When this matters for your project.** Isolation matters when the PM chat
spawns SEVERAL read-write agents in parallel and you do not want their edits to
collide in one shared working tree, or when you want a clean patch-handoff
boundary for each coder. For a single sequential coder it is optional; the
in-place (non-isolated) regime is the default floor and works without any
settings.

**How to enable isolated parallel subagents — TWO INDEPENDENT mechanisms.**
The feature is governed by two orthogonal knobs. Do not conflate them.

1. **TRIGGER (per task) — the per-spawn Agent-tool `isolation` parameter.**
   The PM chat decides per spawn whether an agent runs isolated, by passing the
   Agent-tool `isolation:"worktree"` parameter when it spawns a read-write
   agent. `"worktree"` is the ONLY valid value for this parameter — `head` and
   `none` are SETTINGS values (see `baseRef`/`bgIsolation` below), NOT parameter
   values. Omitting the parameter runs the agent in-place (the default). This is
   a per-spawn decision the PM chat makes; it is not a `settings.json` key, and
   the PM chat does NOT isolate by writing settings (that would conflict with
   the no-write-settings posture and could surprise another session sharing the
   same checkout).

2. **BASE (REQUIRED setting) — `worktree.baseRef`.** Set
   `worktree.baseRef: "head"` in your `settings.json` so an isolated worktree
   branches from your LOCAL HEAD (the branch you are working on). The valid
   values are `"head"` and `"fresh"`.
   - **Consequence if unset:** `baseRef` defaults to `"fresh"`, which branches
     the worktree from `origin/<default>` (i.e. `origin/main`) — the historical
     "checks out main" wrong-base behavior. An isolated agent would then base
     its work at `origin/main`, NOT your current branch. The work still
     functions (the patch still applies onto your branch), but it is the wrong
     base — so `baseRef: "head"` is REQUIRED for branch work.
   - **Where it lives:** put `worktree.baseRef: "head"` in `settings.json` at
     PER-PROJECT scope (`.claude/settings.json` in your repo, recommended) OR at
     GLOBAL scope (`~/.claude/settings.json`, which affects every project on
     your machine — your choice).

   ```json
   {
     "worktree": {
       "baseRef": "head"
     }
   }
   ```

**Background sessions are a SEPARATE mechanism (not this feature).**
`worktree.bgIsolation` (enum `["worktree", "none"]`, default `"worktree"`)
governs TOP-LEVEL background `claude` sessions via the
`EnterWorktree`/`ExitWorktree` flow: `"worktree"` blocks Edit/Write in the main
checkout until `EnterWorktree` is called; `"none"` lets background jobs edit the
working copy directly. `bgIsolation` does NOT control Agent-tool subagents — it
is not the subagent-isolation trigger, and it is not a boolean
(`bgIsolation: true` is invalid). The background-session isolation story is a
separate concern slated for a future pack version; do not set `bgIsolation`
expecting it to isolate the agents the PM chat spawns.

**In-session destructive-git-verb backstop — the documented-optional
`permissions.deny` recipe.** The default protection for in-session sub-agents is
the always-on PROSE deny-list every agent reads (the no-state-changing-git rule
in your project trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, the
`commit-discipline` skill, and each agent's own definition file) plus the
behavioral contract that agents never stage, commit, or run any other
working-tree- or ref-mutating git verb. On top of that, you can add an OPTIONAL
mechanical hard-deny that the pack DOES NOT ship — you add it to YOUR OWN
`settings.json` (user or project scope). In the Claude Code permission model, a
`permissions.deny` block is SESSION-SCOPED and INHERITED by all in-session
sub-agents (including background ones) and is deny-first (it is NOT bypassed by
`bypassPermissions`). It is the ONLY in-session mechanical layer available: an
agent-definition `tools:` field cannot deny a specific git sub-verb (it is
tool-name-level only), and there is no per-spawn tool-deny parameter. List the
destructive git verbs as scoped `Bash` rules:

    ```json
    {
      "permissions": {
        "deny": [
          "Bash(git commit:*)",
          "Bash(git push:*)",
          "Bash(git add:*)",
          "Bash(git stash:*)",
          "Bash(git reset:*)",
          "Bash(git restore:*)",
          "Bash(git checkout:*)",
          "Bash(git apply:*)",
          "Bash(git worktree:*)",
          "Bash(git clean:*)",
          "Bash(git merge:*)",
          "Bash(git rebase:*)"
        ]
      }
    }
    ```

This recipe is VERB-PRECISE: it denies `Bash(git apply:*)` (the patch-APPLYING
form, which only the PM chat runs) but NEVER `Bash(git diff:*)` — `git diff` is
the agent's read-only patch-emit and must stay allowed (the `git diff > file`
redirection is a shell-level construct, not a git verb, so it is not tripped). A
user `PreToolUse` hook (matcher `Bash`, returning `permissionDecision: "deny"`
for the same verbs) is a SECONDARY defence-in-depth option only — its
`if`-matcher fails OPEN, so `permissions.deny` is the documented-primary
mechanical layer. The pack ships neither the settings file nor the hook; this is
a recipe you opt into. Without it, the in-session protection degrades to the
always-on prose deny-list plus the behavioral contract (still load-bearing, just
not mechanically enforced).

**The `agent-run.sh --worktree` launcher (a SECONDARY path).** Separate from the
in-session spawn above, `agent-run.sh` carries an optional `--worktree [path]`
flag (claude only) that runs `claude --agent <name>` inside an isolated git
worktree for a human-driven parallel-agent run. It bases the worktree at your
CURRENT HEAD deterministically with `git worktree add --detach <path> HEAD`, so
it does NOT depend on the `worktree.baseRef` setting — it works on a fresh
client with no settings file, and your branch HEAD is always the base, never
`origin/main`. The launcher is SECONDARY/opt-in with a cwd-scoping caveat:
whether `claude --agent` launched with its cwd inside a worktree reliably keeps
ALL of its git operations scoped to that worktree (rather than leaking to the
parent repo) is environment- and version-dependent. Probe it ONCE before
relying on it — run `./agent-run.sh claude --agent coder --worktree`, then in
your main checkout run `git status` and confirm the main working tree is
unchanged. If the probe shows the agent's git leaked into the parent repo, do
NOT use `--worktree`; fall back to the manual procedure (below). Either way the
agent still never stages or commits — you bring its work back via the PM-chat
patch merge-back (`docs/pack/PM-CHAT.md`). See the `run_in_worktree` comment in
`agent-run.sh` for the full caveat.

**Caveats.**
- **Version-sensitive.** Worktree isolation behavior has shifted across Claude
  Code releases; confirm your version's behavior before relying on it.
- **Auto-removal can delete unmerged branches.** When an isolated subagent exits
  cleanly, Claude Code auto-removes its worktree and branch. A branch with
  unmerged commits can be silently deleted — which is why the merge-back model
  captures the agent's work as a patch in the handoff directory BEFORE return
  (the patch survives auto-removal), and why agents never commit.
- **Best-effort isolation / silent fall-to-main.** Isolation can silently fall
  back to editing the main checkout. The PM chat therefore detects the ACTUAL
  regime from what the agent reports (a patch handoff ⇒ isolated; in-place edits
  ⇒ in-place), never from an assumed settings value.
- **`baseRef` unset/`fresh` wrong-base.** As above, an unset/`fresh` `baseRef`
  bases isolated work at `origin/main` rather than your branch — a documented
  degradation, surfaced by the PM chat, never silent.

**The pack ships NO settings file.** You add `worktree.baseRef`,
`worktree.bgIsolation` (if you use background sessions), and the
`permissions.deny` recipe to your OWN `settings.json`. The pack documents these
keys; it never writes a settings file into your repo.

**Claude-only note.** This feature is specific to Claude Code's Agent-tool
`isolation` parameter and `worktree` settings. Codex CLI and Gemini CLI have no
equivalent at this time; their worktree story is tracked separately and is out
of scope here. There is no cross-CLI parity claim for this feature.

**Manual worktree (no pack mechanism needed).** If you simply want to work on
parallel branches yourself, run `git worktree add ../my-worktree <branch>` by
hand and open a separate session in that directory — that is plain git and needs
nothing from the pack; the pack only guarantees that nothing it ships breaks
inside a manual worktree.
```

(In the actual file the JSON block is at normal indentation; it is indented by 4 spaces here only to nest it visually inside this report's outer code fence.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **bd-pack-only-operational-rule** | `grep -cE "maintenance-docs\|pack-ops\|Pack Chat\|pack-(coder\|architect\|planner\|reviewer\|docs-researcher)\|BD-[0-9]\|validate-pack\|PACK-AGENTS\|PACK-CHAT" project-template/docs/pack/OPTIONAL-FEATURES.md` → `0`. Investigated client future-ref convention BEFORE citing any BD: `grep -rn "BD-[0-9]" project-template/` → no matches; used neutral "a future pack version" / "tracked separately and is out of scope here" instead of BD-218/BD-217. | **COMPLIANT** |
| **pack-project-separation-of-concerns** | Client section authored independently: "PM chat" 10 / "Pack Chat" 0; "your project/branch/repo/machine" 14; documents project `agent-run.sh --worktree`; cross-refs `docs/pack/PM-CHAT.md`. `diff` of pack vs client isolation sections = non-empty (159 vs 179 lines); `grep -c 'Config Pack stays cross-CLI'` client = 0. NOT a byte-copy; not a fallback for the pack version. | **COMPLIANT** |
| **client-ref-delete-or-forward-look** | No client-shipped pack-repo path present (ZERO pack-self grep above). Every forward reference is client-appropriate: `docs/pack/PM-CHAT.md`, `agent-run.sh`, `.claude/settings.json`, `~/.claude/settings.json` — all client-resident after install. Future-work pointer is neutral prose, not a pack path. | **COMPLIANT** |
| **regenerate-manifest-v11-surface** | `bash test-fixtures/build.sh --all --clean` exit 0; `git diff test-fixtures/manifest.txt` NON-EMPTY (3 v11 SHAs updated); manifest KEPT (`git status --short` shows ` M test-fixtures/manifest.txt`, unstaged); `build.sh --verify` vs regenerated manifest exit 0; restore done via `git show HEAD:... > file` + `cp` (NO `git checkout`). | **COMPLIANT** |
| **verify-full-ci-suite** | validate job 2/2 exit 0; tests job 60 scripts + fixture build/verify trio all exit 0 (full table above, no sampling); every script wired in `validate-pack.yml` run and exit-status quoted. | **COMPLIANT** |
| **edit-in-place-not-full-rewrite** | Single targeted Edit inserting one new section between Agent-Teams and the Codex placeholder; `git diff --stat` = `178 ++++ ... 181 insertions(+), 3 deletions(-)` (the 3 deletions are the manifest SHA lines; OPTIONAL-FEATURES.md is 178 insertions, 0 deletions to existing content). Existing sections unchanged. No wholesale rewrite. | **COMPLIANT** |
| **empirical-evidence-blocks** | Every claim in this report backed by a quoted command + verbatim output + HEAD-SHA (`13bb32e`) + date (2026-06-14): baseline 0/0/0, post-edit 10/6/4, manifest diff, carve-out reproduction, full CI table. | **COMPLIANT** |
| **preflight-stop-means-stop** | Single PREFLIGHT line emitted AFTER all edits + the full battery PASSED: `PREFLIGHT: C8a project OPTIONAL-FEATURES + permissions.deny recipe complete; client-native (not byte-copy); 3-token grep PASS; ZERO pack-self; manifest regenerated (kept); FULL CI battery PASS; HEAD 13bb32eee5b36529dd36b7c3eaaf2e4a81f2d10d; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C8a.md`. No parent stop/halt message received. | **COMPLIANT** |
| **agents-never-commit** | No state-changing git verb run. Read-only git used: `git rev-parse`, `git status`, `git diff`, `git show HEAD:...` (read a file at HEAD). Restore via `cp`, never `git checkout`/`git add`/`git stash`. Working tree left with 2 unstaged modified files; orchestrator commits. | **COMPLIANT** |
| **scope-deliverables-to-the-ask** | C8a DATA half only: project OPTIONAL-FEATURES section + `permissions.deny` recipe. NO Guard-A′ / Check 54 (that is C8b — `scripts/validate-pack.py` NOT touched). No pack-side surface touched. Files changed = `project-template/docs/pack/OPTIONAL-FEATURES.md` + `test-fixtures/manifest.txt` + this report only. | **COMPLIANT** |
| **rules-applied-verification-block** | This block. | **COMPLIANT** |

**Surfaced (not silently fixed) — anything else noticed:** None outside scope. The plan's conditional BD-218 allowance was correctly NOT exercised (documented under Plan deviations + the future-reference convention finding) — this is rule compliance, surfaced explicitly rather than silently applied.



