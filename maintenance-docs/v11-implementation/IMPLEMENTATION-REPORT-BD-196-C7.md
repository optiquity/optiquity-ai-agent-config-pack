# IMPLEMENTATION REPORT — BD-196 C7

**Commit:** C7 of 12 — Extend CI Check 37 walk to companion-template dirs (D1) + update Check 37 test
**Branch:** `v11-dev`
**Base / final HEAD on worktree:** `f2aeb62ce7c24e9fedf8488c09d07baf2cf60506` (unchanged — agent makes no commits)
**Plan:** `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` §3 C7 / §6 EE-2 / §6 G-D
**Date:** 2026-05-31

---

## 1. Pre-flight

- `git rev-parse HEAD` → `f2aeb62ce7c24e9fedf8488c09d07baf2cf60506`
- `git status` → clean working tree at start
- Scope dirs present: `xcode-companion-templates/`, `vscode-companion-templates/` (both exist)
- Companion-dir file inventory (10 files):
  ```
  vscode-companion-templates/.vscode/extensions.json
  vscode-companion-templates/.vscode/settings.json
  vscode-companion-templates/.vscode/tasks.json
  vscode-companion-templates/README.md
  xcode-companion-templates/.gitignore
  xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md
  xcode-companion-templates/ClaudeAgentConfig/settings.json
  xcode-companion-templates/Codex/AGENTS.md
  xcode-companion-templates/Codex/config.toml
  xcode-companion-templates/README.md
  ```

---

## 2. MEASURE-FIRST (mandatory) — deny-list hit counts (both dirs)

Ran each of Check 37's four deny-list pattern classes against both companion dirs
at HEAD `f2aeb62` BEFORE any edit:

| Pattern class | Patterns | Command | Hits |
|---|---|---|---|
| Filenames | `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md` | `grep -rn` | **0** (exit 1) |
| Path prefixes | `maintenance-docs/`, `pack-ops/` | `grep -rn` | **0** (exit 1) |
| Agent names | `pack-architect`, `pack-coder`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` | `grep -rnE "\b(...)\b"` | **0** (exit 1) |
| Role name | `Pack Chat` | `grep -rn` | **0** (exit 1) |

**Result:** ZERO deny-list hits across all four classes in both companion dirs.
Matches plan EE-2 / §2.2 hypothesis (both dirs grep-verified clean). Extension is
**forward-protection only — zero cleanup**. No STOP condition triggered.

---

## 3. Edits made (exact file + region)

### 3.1 `scripts/validate-pack.py`

**Edit A — new constant + rewritten `_iter_project_side_files()`** (was a thin alias
at the lines following `_iter_client_installed_files()`):

- Added module constant `_CHECK_37_COMPANION_TEMPLATE_DIRS = ("xcode-companion-templates", "vscode-companion-templates")` with an explanatory comment block stating these are pack-shipped client-facing surfaces NOT in `_CLIENT_INSTALLED_FILES`, appended to Check 37's walk ONLY (not to `_iter_client_installed_files()`).
- Rewrote `_iter_project_side_files()` from a thin alias (`return _iter_client_installed_files()`) into Check 37's walk-set builder: it starts from `list(_iter_client_installed_files())`, then `rglob`-walks each companion dir, appending de-duplicated repo-relative file paths. The companion dirs are appended **here** and deliberately NOT in `_iter_client_installed_files()`, so Check 41 (install inventory) and Check 43 (bare-cross-reference walk) remain unaffected.

**Design rationale for the chosen seam:** Check 37 (line ~4341) calls `_iter_project_side_files()`; Check 43 (line ~5322) and Check 39/42 call `_iter_client_installed_files()` directly; Check 41's inventory tests assert against the install inventory. Extending the **alias** (`_iter_project_side_files`) rather than the shared base (`_iter_client_installed_files`) is the surgical seam that adds the companion dirs to Check 37 ONLY — exactly the plan's intent ("extend Check 37's walk set") and the empirical Check-41-unaffected requirement.

**Edit B — Check 37 docstring** (`check_project_side_deny_list`): updated the
"Walks files under `project-template/`" sentence to "Walks the Check 37 surface
(`_iter_project_side_files()` — the client-installed inventory PLUS the
companion-template directories ... per BD-196 C7)". In-place docstring edit; rest of
the docstring (exemptions, anchor phrases) untouched.

### 3.2 `scripts/tests/test-validate-pack-checks-36-37-38.sh`

**Edit C — new Group 7 sub-test G7.T5** (inserted after G7.T4, before the
`if failures:` block). The file has no exact numeric walk-set-count assertion (G7
tests are membership-based — confirmed via grep for `len(` / `== N` / `>=`); the
only count assertions are unrelated: T1 exempt-list `len == 1` (line 248), fence-file
`len` (line 406)). The "update expected walk-set count" requirement is therefore
satisfied by extending the membership assertions to the new walk-set composition.
G7.T5 adds three lock-step assertions:

- **G7.T5a:** the companion-template files ARE in Check 37's walk (`_iter_project_side_files()`) — forward-protection membership.
- **G7.T5b:** the companion-template files are NOT in `_iter_client_installed_files()` — the deliberate separation that keeps Check 41/43 companion-free.
- **G7.T5c:** `_iter_client_installed_files()` is a strict subset of `_iter_project_side_files()` — companion dirs are an ADDITION, never a replacement.

### 3.3 `.github/workflows/validate-pack.yml` — NOT TOUCHED (verified)

`grep -n "36-37-38"` → `test-validate-pack-checks-36-37-38.sh` already wired at
line 162 (Check 41 at 171, Check 43 at 186). Plan §3 item 3 confirmed: no new
workflow line needed; the test is already wired at the Check-36-37-38 step. File
left unmodified.

---

## 4. Check 41 / Check 43 empirical-unaffected proof

**Empirical confirmation companion dirs are NOT installed:**
`grep -n "companion" scripts/init-project.sh` → exit 1 (no match). The
`_CLIENT_INSTALLED_FILES_START`/`_END` block (init-project.sh:1273-1311) lists
zero companion-template entries — every entry is `project-template/...`,
`supporting-docs/...`, or `scripts/...`. Companion dirs are dev-environment
editor/IDE configs applied manually, NOT auto-installed.

**Consequence:** the plan's hypothesis (G-D / §3) is CONFIRMED — Check 37's walk is a
SEPARATE set from the install inventory. Because the companion dirs were appended to
`_iter_project_side_files()` and NOT to `_iter_client_installed_files()`, neither
Check 41 (`_CLIENT_INSTALLED_FILES` inventory integrity) nor Check 43
(bare-cross-reference scanner) changes. **No lock-step Check 41/43 inventory edits
were required** (they did NOT become in-scope files).

**Verified by test deltas (see §5):** Check 41 test 4/4 PASS, Check 43 test 7/7 PASS
— both unchanged from baseline, confirming no inventory/count drift.

**Walk-set measurement (post-edit):**
- `_iter_project_side_files()` (Check 37 walk) → **171** files
- `_iter_client_installed_files()` (install inventory / Check 41+43 walk) → **161** files
- delta → **10** (exactly the 10 companion-template files)

---

## 5. Verification results (working-state proof)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **EXIT 0 — "PASSED — all checks clean"** |
| → Check 37 line | `OK: Check 37 — 168 project-side file(s) walked; zero deny-list contamination (6 anchored LEGITIMATE-context hit(s) accepted; 584 fenced LEGITIMATE-content line(s) exempt per Guardrail 2)` |
| `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` | **EXIT 0 — PASS: 8, FAIL: 0** (Group 7 incl. new G7.T5 PASS) |
| `bash scripts/tests/test-validate-pack-check-41.sh` | **EXIT 0 — PASS: 4, FAIL: 0** |
| `bash scripts/tests/test-validate-pack-check-43.sh` | **EXIT 0 — PASS: 7, FAIL: 0** |

**Note on 168 vs 171:** the iterator returns 171 paths; Check 37's `files_walked`
counter reports 168 because it skips files that raise `UnicodeDecodeError`/`OSError`
on read (the 3 non-text companion files — e.g. `.gitignore`/JSON/TOML that decode
fine are counted; binary-ish/unreadable are skipped per the existing
`except (UnicodeDecodeError, OSError): continue` path). This is pre-existing,
expected behavior — companion text files ARE walked and the deny-list applied;
zero contamination found.

**Note on stderr (corrected by C7-FIX):** the original C7 edit introduced two
`command substitution: line 585: syntax error: unexpected end of file` stderr lines.
These were **C7-introduced, NOT pre-existing**: at HEAD `f2aeb62` the test emitted 0
such lines; after the original C7 edit it emitted 2. The cause was backtick-with-parens
tokens (`` `_iter_project_side_files()` `` / `` `_iter_client_installed_files()` ``) in
the new G7.T5 **comment** lines, which the shell attempted to command-substitute inside
the unquoted `<<EOF` heredoc. The substitution failed harmlessly (test still PASS 8/0,
exit 0) but produced CI-stderr noise. The fix-coder pass (C7-FIX) removed the backticks
from those two comment lines, restoring 0 stderr lines while keeping the heredoc unquoted
(it legitimately expands `$REPO_ROOT` / `$VALIDATE`). See
`IMPLEMENTATION-REPORT-BD-196-C7-FIX.md`.

---

## 6. Manifest regeneration

- `bash test-fixtures/build.sh --all --clean` → **BUILD_EXIT 0**
- `diff` of `test-fixtures/manifest.txt` before/after → **EMPTY (no change)**
- `git status --short` after regen → only `M scripts/validate-pack.py` and `M scripts/tests/test-validate-pack-checks-36-37-38.sh` (manifest.txt unchanged, not listed)

**Manifest diff is EMPTY.** Pack Chat does NOT need to stage `test-fixtures/manifest.txt`
for this commit (the v11-surface manifest-regen rule fires only "when the manifest
diff is non-empty"). C7 touches `scripts/` but the edits do not alter fixture
manifest content.

---

## 7. 7b stale-reference sweep + Trinity

- **7b sweep:** none required — this is a purely additive walk extension; no symbol
  rename, no file move, no deletion. No orphaned/dangling references created.
  Confirmed.
- **Trinity:** N/A — C7 touches NO trinity file (`project-template/` or pack-root
  `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`). Edited files are `scripts/validate-pack.py`
  and `scripts/tests/test-validate-pack-checks-36-37-38.sh` only. Confirmed N/A.
- **Boundary discipline:** N/A — no project-side (`project-template/` / `supporting-docs/`)
  file edited. The edits are pack-side (`scripts/`) and add Check 37 protection TO
  the (project-side, pack-shipped) companion-template surfaces without editing them.

---

## 8. Plan deviations

**Zero functional deviations.** One clarification vs the plan's literal wording:

- Plan §3 item 1 says "extend `_iter_client_installed_files()` **or** the Check 37
  walk". I extended the **Check 37 walk** (`_iter_project_side_files()`) and
  deliberately did NOT extend `_iter_client_installed_files()` — the plan's "or"
  offers both; the Check-37-only seam is the correct one because §3's own
  Check-41-unaffected constraint + G-D require the install inventory (which IS
  `_iter_client_installed_files()`) to stay companion-free. Extending the base
  function would have failed that constraint.
- Plan §3 item 2 says "update expected walk-set count". The test had no numeric
  count assertion; I added membership + separation + superset assertions (G7.T5a/b/c)
  that encode the new walk-set composition more precisely than a bare count would.

---

## 9. New POQs introduced

None.

---

## 10. Definition-of-Done checklist

| Item | Status |
|---|---|
| Measure-first: both companion dirs grepped against all 4 deny-list classes; hits captured | PASS (0/0/0/0) |
| Companion dirs added to Check 37 walk | PASS (`_iter_project_side_files()` → 171, +10) |
| Check 41/43 empirically confirmed unaffected | PASS (not in `_CLIENT_INSTALLED_FILES`; tests 4/4 + 7/7) |
| Lock-step: validator + per-check test updated together | PASS (validate-pack.py + test-36-37-38.sh both edited) |
| `python3 scripts/validate-pack.py` green | PASS (exit 0, all clean) |
| `test-validate-pack-checks-36-37-38.sh` green | PASS (8/0) |
| `test-validate-pack-check-41.sh` green | PASS (4/0) |
| `test-validate-pack-check-43.sh` green | PASS (7/0) |
| Manifest regenerated; diff reported | PASS (empty diff) |
| Workflow wiring verified (no new line) | PASS (line 162 pre-wired) |
| 7b sweep | PASS (N/A — additive) |
| Trinity | PASS (N/A — no trinity file) |
| In-place edits (no full-file rewrite) | PASS (3 targeted Edits) |
| No git state change | PASS (HEAD unchanged f2aeb62) |

---

## 11. Files changed inventory

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (new `_CHECK_37_COMPANION_TEMPLATE_DIRS` const + `_iter_project_side_files()` rewrite + Check 37 docstring) |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | modified (new Group 7 sub-test G7.T5a/b/c) |
| `.github/workflows/validate-pack.yml` | NOT modified (verified pre-wired) |
| `test-fixtures/manifest.txt` | regenerated, no diff (NOT staged — empty) |

`git diff --stat`: 2 files changed, 99 insertions(+), 12 deletions(-).

---

## 12. Rules-Applied Verification Block

| Rule (as named in SECTION 2) | Verification evidence | Conclusion |
|---|---|---|
| **Agents never commit** | No `git add`/`commit`/`push`/`tag`/`mv`/`rm` run. `git rev-parse HEAD` → `f2aeb62...` (unchanged from base). `git status --short` shows 2 `M` files, no staging. | COMPLIANT |
| **Per-action approval extends to sub-agents** | No destructive file op run on own authority. `build.sh --all --clean` is the prescribed in-scope manifest-regen command (rebuilds fixtures, not a trusted-file overwrite); manifest diff empty so no trusted file altered. No `rm -rf`/`git rm`. | COMPLIANT |
| **Pack-coder PREFLIGHT + STOP-MEANS-STOP** | Emitted exactly one PREFLIGHT line `PREFLIGHT: 2/2 in-scope edits complete; verification PASS; HEAD f2aeb62...; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C7.md` AFTER validate-pack (exit 0) + all 3 per-check tests (8/0, 4/0, 7/0) PASS. No parent stop message received. | COMPLIANT |
| **Agent output requires Rules-Applied Verification Block** | This table (§12), one row per SECTION-2 rule, quoted evidence. | COMPLIANT |
| **Edit docs in place, not full rewrites** | 3 targeted `Edit` calls (no `Write` to source); re-read of validate-pack.py lines 4156-4204 confirmed const + function + docstring structure intact. | COMPLIANT |
| **Enumerate ENCODING surfaces in pack-side audits** | Surface (`validate-pack.py` Check 37 walk) + its per-check test (`test-validate-pack-checks-36-37-38.sh`) updated in lock-step. CI workflow line verified pre-wired (no edit needed). Check 41/43 ENCODING surfaces empirically confirmed unaffected (`grep companion scripts/init-project.sh` → exit 1; tests 4/0 + 7/0). | COMPLIANT |
| **Regenerate test-fixtures/manifest.txt on v11-surface commit** | C7 touches `scripts/` → ran `bash test-fixtures/build.sh --all --clean` (exit 0); `diff` before/after → EMPTY; reported empty so no staging needed. | COMPLIANT |
| **Pack-repo code-comment deferrals** | No deferral comments written. New comment block on `_CHECK_37_COMPANION_TEMPLATE_DIRS` is descriptive (states design intent), not a deferral; no `# TODO`/`# FIXME` introduced. `grep -n "TODO\|FIXME" ` of edited regions → none added. | N/A: no deferral introduced |
| **Trinity rule** | No trinity file edited — edits limited to `scripts/validate-pack.py` + `scripts/tests/test-validate-pack-checks-36-37-38.sh`. | N/A: no trinity file touched |
| **CI-guard measure-then-bound** | MEASURED both companion dirs against all 4 deny-list classes BEFORE wiring (§2: 0/0/0/0 hits). Both clean → walk extension admits no contamination; allowlist unchanged (no new exemptions added). No STOP condition. | COMPLIANT |
| **No deferral without user direction / Deferral IS scope creep** | All in-scope C7 work completed now (2 edits + verification + manifest). Nothing deferred. | COMPLIANT |
