---
title: REVIEW-BD-096 — Synthetic-fixture set (Batch 16)
author: pack-reviewer (v11-dev, end-of-batch review)
date: 2026-05-14
target-commit: 4a5a6e5fa8b78dd82ffb2c56d2d1a48fe66bd90d
spec: BACKLOG.md BD-096 (line 702)
implementation-report: maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-096.md
---

# Review — BD-096 Synthetic-fixture set (Batch 16)

## Verdict

**REJECT-AND-RESPIN** — one BLOCKER (F-1) defeats the batch. The
implementation passes locally on the coder/Pack-Chat machine but FAILS
on Linux CI due to gitignored fixture content that never landed in the
commit. The shipped commit cannot be left at HEAD because the next clean
clone, the next CI run on any branch, and any contributor without the
local working-tree state will all hit the same 8-test failure.

The structure is sound and the other fixtures are well-designed; only
the gitignore-collision needs surgical correction (one `.gitignore`
exception line + the four `.env` files re-added with `git add -f`).
Once F-1 is resolved, F-2..F-9 are SHOULD-FIX / NIT scope and can ride
in the same fix commit.

## 1. Pre-flight evidence

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
$ git rev-parse HEAD
4a5a6e5fa8b78dd82ffb2c56d2d1a48fe66bd90d
$ git rev-parse --abbrev-ref HEAD
v11-dev
$ git log --oneline -3
4a5a6e5 feat: v11 — BD-096 synthetic-fixture set (Batch 16)
91e7563 docs: v11 — Graphify + Claude-ecosystem-repos research artifacts
3b9b658 docs: v11 — Batch 19 setup (open BD-164..BD-170 + ...)
```

HEAD matches the prompt's expected base. v11-dev branch confirmed. No
worktree drift.

## 2. Verification gate evidence (re-run by reviewer)

### 2.1 Local run on macOS — PASS

```
$ bash scripts/tests/test-customization-preserve.sh
… (Groups 1-7 unchanged) …
=== Group 8: BD-096 directory-based fixtures ===
--- 8.lightly-customized-minimal ---
… all PASS …
--- 8.heavily-customized ---
… all PASS …
--- 8.language-heterogeneous ---
… all PASS …
--- 8.custom-agents-heavy ---
… all PASS …
--- 8.v10-with-customization ---
… all PASS …
=== Summary ===
Passed: 210
Failed: 0
All tests passed.
```

```
$ python3 scripts/validate-pack.py
… (29 numbered Checks plus 4 informational) …
PASSED — all checks clean
```

(Side note on N-1 below: the coder report claims "35/35 PASS" for
validate-pack; the actual numbered Checks visible at console are 29
plus a few informational. PASS verdict is correct; the count phrasing
is loose.)

### 2.2 CI run on Linux (ubuntu-latest) — FAIL

`gh run view 25892912819 --log-failed`:

```
=== Group 8: BD-096 directory-based fixtures ===
--- 8.language-heterogeneous ---
  FAIL 8.language-heterogeneous/.gemini/.env disposition —
       expected='customization-detected-needs-reconciliation' got='removed-everywhere'
  PASS 8.language-heterogeneous/.gemini/.env class
  … (other rows PASS) …
  FAIL 8.language-heterogeneous/.gemini/.env (dest) target missing —
       expected /tmp/cp-language-heterogeneous.79wr3s/proj/.gemini/.env  (×3)
  FAIL 8.language-heterogeneous/.gemini/.env (sidecar) target missing
  …
--- 8.v10-with-customization ---
  FAIL 8.v10-with-customization/.gemini/.env disposition —
       expected='customization-detected-needs-reconciliation' got='removed-everywhere'
  PASS 8.v10-with-customization/.gemini/.env class
  … (other rows PASS) …
  FAIL 8.v10-with-customization/.gemini/.env (dest) target missing  (×2)

Failed: 8
##[error]Process completed with exit code 1.
```

The local pass / CI fail divergence is the F-1 defect.

### 2.3 Determinism (two consecutive local runs)

```
$ bash scripts/tests/test-customization-preserve.sh > /tmp/run1.log 2>&1
$ bash scripts/tests/test-customization-preserve.sh > /tmp/run2.log 2>&1
$ diff /tmp/run1.log /tmp/run2.log
31c31
<   PASS 2.4 three-way diff written (/var/folders/.../cp-text.XXXXXX.j32rSXByvl/state/diffs/...)
---
>   PASS 2.4 three-way diff written (/var/folders/.../cp-text.XXXXXX.15OTTwwWbC/state/diffs/...)
```

The single difference is the `mktemp` random suffix in a Group-2
diagnostic message — Group 8 produces zero between-run diffs.
Determinism: PASS.

### 2.4 No regression in Groups 1-7

```
$ git diff 91e7563 4a5a6e5 --shortstat -- scripts/tests/test-customization-preserve.sh
 1 file changed, 156 insertions(+)
$ git diff 91e7563 4a5a6e5 -- scripts/tests/test-customization-preserve.sh | grep -E '^\-[^\-]'
(empty)
```

Zero deletions in the test runner. Groups 1-7 are byte-identical to
the pre-batch state. Coder claim verified.

(Side note on N-2 below: the coder report says "+162 lines"; the
actual diff is +156 lines. Coder was off by 6 lines, possibly counting
the diff context noise.)

## 3. Findings

### F-1 — BLOCKER — Fixture `.gemini/.env` files gitignored, missing from commit

- **File reference:**
  - `.gitignore:38` (`.env`)
  - `scripts/tests/fixtures/customization-preserve/language-heterogeneous/{ours,theirs}/.gemini/.env`
  - `scripts/tests/fixtures/customization-preserve/v10-with-customization/{ours,theirs}/.gemini/.env`

- **Evidence:**

  ```
  $ git check-ignore -v scripts/tests/fixtures/customization-preserve/language-heterogeneous/ours/.gemini/.env
  .gitignore:38:.env  scripts/tests/fixtures/customization-preserve/language-heterogeneous/ours/.gemini/.env

  $ find scripts/tests/fixtures/customization-preserve -type f | wc -l
  91
  $ git ls-files scripts/tests/fixtures/customization-preserve/ | wc -l
  87
  ```

  Disk has 91 fixture files; commit has 87. The 4 missing files are
  exactly the four `.gemini/.env` fixture files (two per failing
  fixture × ours + theirs).

- **Description:** Root `.gitignore:38` ignores all `.env` files. The
  4 `.gemini/.env` fixture files exist on the implementer's local
  working tree (they were created by the coder and the local test run
  saw them via direct filesystem access — the runner reads
  `$fdir/ours/$rel` directly, bypassing git). The pre-commit local
  test pass was therefore an artifact of local working-tree state,
  not of committed content.

  When CI checks out the commit, the four `.env` files are absent.
  In the runner:

  ```bash
  base_path=""
  ours_path=""
  theirs_path=""
  [[ -f "$fdir/base/$rel" ]]   && base_path="$fdir/base/$rel"
  [[ -f "$fdir/ours/$rel" ]]   && ours_path="$fdir/ours/$rel"
  [[ -f "$fdir/theirs/$rel" ]] && theirs_path="$fdir/theirs/$rel"
  ```

  All three remain `""`. `customization_preserve` then hits its
  early-return at `scripts/lib/customization-preserve.sh:525`:

  ```bash
  if [[ ! -e "$base" && ! -e "$ours" && ! -e "$theirs" ]]; then
      _cp_record "removed-everywhere" "$class" "$rel" "none" ...
  ```

  …and records `removed-everywhere`, which mismatches the manifest's
  expected `customization-detected-needs-reconciliation`. Eight
  individual t_fail records → CI fails → red push at
  `https://github.com/.../actions/runs/25892912819`.

  This BLOCKER also breaks the coder report's DoD line "Fixtures
  deterministic (no timestamps, no machine paths) — PASS": the
  fixtures are deterministic, but they are NOT _portable_ —
  reproducibility from a fresh clone is broken.

- **Recommended fix:** Add an exception for fixture-tree `.env` files
  to the root `.gitignore`, then `git add -f` the four files. The
  exception must be narrow (do NOT relax `.env` ignoring for the
  whole tree — that's a security-relevant rule). Concretely:

  In `.gitignore`, after line 38 (`.env`), add:

  ```
  # Exception: synthetic test fixtures intentionally ship .env files
  # (BD-096; reproducibility from a fresh clone requires them in git)
  !scripts/tests/fixtures/**/.env
  ```

  Then:

  ```
  git add -f scripts/tests/fixtures/customization-preserve/language-heterogeneous/ours/.gemini/.env
  git add -f scripts/tests/fixtures/customization-preserve/language-heterogeneous/theirs/.gemini/.env
  git add -f scripts/tests/fixtures/customization-preserve/v10-with-customization/ours/.gemini/.env
  git add -f scripts/tests/fixtures/customization-preserve/v10-with-customization/theirs/.gemini/.env
  ```

  After the exception lands, `git check-ignore` should return empty
  for all four paths and `find scripts/tests/fixtures/customization-preserve
  -type f | wc -l` should equal `git ls-files | wc -l`.

  A defense-in-depth follow-up (consider as F-1b): teach
  `validate-pack.py` to compare `find -type f` vs `git ls-files`
  under `scripts/tests/fixtures/customization-preserve/` and fail on
  any disk file not tracked. This catches the same class of defect
  for any future fixture addition that trips a different gitignore
  pattern. Defense-in-depth is optional in this batch.

### F-2 — SHOULD-FIX — `v10-with-customization/.codex/config.toml` lacks "ollama removed" assertion

- **File reference:** `scripts/tests/fixtures/customization-preserve/v10-with-customization/assertions.tsv:5`
- **Description:** The fixture's customization shape per the README
  says `[model_providers.ollama]` was REMOVED by project, and
  `[model_providers.lmstudio]` was ADDED by pack. The merged dest
  must (a) keep `ollama` removed AND (b) include `lmstudio`. The
  assertions row 5 only checks `lmstudio`. An algorithm regression
  that re-introduces `ollama` (e.g., via a future `merge-toml.py`
  change that defaults to "union all top-level keys") would still
  PASS this fixture. I verified by running the SUT directly:

  ```
  $ bash /tmp/merge-test.sh
  ----- merged dest -----
  [model_providers.openai]    ← present (unchanged)
  [model_providers.lmstudio]  ← present (pack adoption verified by current assertion)
  ----- (ollama section absent — but no assertion guards this) -----
  ```

  The "ollama removal honored" property is the project-edit-preservation
  property; it is the entire point of the fixture per README §5. It
  is also the scenario most likely to silently regress in
  `merge-toml.py` refactors.
- **Recommended fix:** Add an assertion type for negative substring
  ("must NOT contain"), then add a row:

  ```
  .codex/config.toml	dest	!ollama	project removal of ollama honored
  ```

  Pattern: assertion side-strings prefixed with `!` mean the
  substring must NOT appear. Update the runner's assertions loop to
  detect a leading `!` and invert the assertion. A simpler
  alternative — without runner changes — is to assert that
  `[model_providers.openai]` and `[model_providers.lmstudio]` are
  present AND the count of `[model_providers.` lines equals 2 (which
  forbids ollama). This is workable but less expressive than a
  proper not-contains primitive.

### F-3 — SHOULD-FIX — `lightly-customized-minimal` assertion misses pack-side adoption

- **File reference:** `scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/assertions.tsv:2`
- **Description:** The fixture's `.claude/settings.json` shape: ours
  added `Bash(project-perm)`, theirs added `Bash(pack-new-perm)`,
  manifest expects `merged-with-customization`. The assertion only
  checks `project-perm` is in dest; it does NOT check `pack-new-perm`
  is also in dest. An algorithm regression that drops new pack-added
  allow-list entries would still PASS. The same property IS asserted
  in `heavily-customized/assertions.tsv:8` (line `pack-new-perm`),
  so the test suite knows about this property — it just isn't
  applied to the smallest fixture.
- **Recommended fix:** Append to
  `lightly-customized-minimal/assertions.tsv`:
  ```
  .claude/settings.json	dest	pack-new-perm	pack allow-list addition adopted
  ```

### F-4 — SHOULD-FIX — `custom-agents-heavy` undertested dispositions

- **File reference:** `scripts/tests/fixtures/customization-preserve/custom-agents-heavy/assertions.tsv` (only 1 row of 9 manifest rows)
- **Description:** The fixture's whole point is exercising the
  three pack-agent dispositions side-by-side
  (sidecar / pack-update-applied / merged-with-customization).
  Only the sidecar case (`pack-reviewer.md`) has a content
  assertion. The two other pack-agent dispositions have no content
  check at all. An algorithm bug that wrote stale content to
  `pack-coder.md` (pack-update-applied case) or stripped the project
  edit from `pack-architect.md` (merged-with-customization case)
  would still PASS — only the disposition token check would fire,
  not the actual file content.
- **Recommended fix:** Add three rows to
  `custom-agents-heavy/assertions.tsv`:
  ```
  .codex/agents/pack-coder.md	dest	state-changing git verbs forbidden	pack-update-applied took theirs's v11 wording
  .gemini/agents/pack-architect.md	dest	data-flow diagram	project edit preserved (no pack change)
  .gemini/agents/pack-architect.md	dest	No implementation	pack baseline content present
  ```
  (Substrings chosen from the existing fixture file content.)

### F-5 — SHOULD-FIX — Group 8 doesn't exercise pack-retired-file dispositions

- **File reference:** `scripts/tests/fixtures/customization-preserve/*/manifest.tsv` (no rows cover removal)
- **Description:** None of the 5 fixtures include a row that exercises
  `removed-by-design`, `removed-by-pack-clean`,
  `removed-by-pack-customized`, `project-deleted-pack-kept`, or
  `removed-everywhere`. These dispositions are exercised by the
  inline Group 1-7 cases (line 374+) but the directory-based
  end-to-end coverage (Group 8) skips them. BD-096's success
  criterion says "5 fixtures together cover the practical
  customization-shape space" — file-removal IS part of the practical
  shape space for v10→v11 (per the BD-088 12-class catalog at
  `customization-preserve.sh:30`).

  Since the inline TSV cases DO cover removal at the algorithmic
  level, this is not a coverage hole at the SUT level — it's a hole
  in the end-to-end fixture coverage. The risk is low (Group 8 isn't
  the only safety net) but the README claim that "the five fixtures
  span the practical customization-shape space" is overstated by one
  axis (file-removal).
- **Recommended fix:** Either (a) add a 6th fixture
  `pack-retires-files/` with rows exercising
  `removed-by-pack-clean`, `removed-by-pack-customized`,
  `project-deleted-pack-kept`, OR (b) tighten the README's claim from
  "spans the practical shape space" to "spans the practical
  edit/add shape space; file-removal cases covered by Groups 1-7
  inline." (b) is the cheap fix; (a) is the principled one. Prefer
  (a) if a 6th fixture is acceptable scope; otherwise (b).

### F-6 — NIT — Runner `assertions.tsv` row width tolerated implicitly

- **File reference:** `scripts/tests/test-customization-preserve.sh:644`

  ```bash
  while IFS=$'\t' read -r a_rel a_side a_sub a_notes; do
  ```

- **Description:** The runner reads 4 tab-separated fields from each
  assertion row but does not validate field count. If a future
  `assertions.tsv` row is missing the `notes` field (3 fields) or
  splits the substring across tabs (5+ fields), the resulting
  behavior is ambiguous (`a_sub` would be empty string, or extra
  fields silently dropped). All current `assertions.tsv` files have
  exactly 4 fields per row (verified by `awk -F'\t' 'NF != 4'`),
  so the issue is latent.
- **Recommended fix:** Optional — add a guard at top of the
  assertion loop:

  ```bash
  if [[ -z "$a_rel" || -z "$a_side" || -z "$a_sub" ]]; then
      t_fail "8.$fname assertion row malformed" \
          "expected 4 tab-separated fields, got rel='$a_rel' side='$a_side' sub='$a_sub'"
      continue
  fi
  ```

  Same shape applies at the manifest loop (line 594).

### F-7 — NIT — README "addable without code changes" claim is true but undocumented

- **File reference:** `scripts/tests/fixtures/customization-preserve/README.md` (no section)
- **Description:** The implementation report §"Test runner extension
  approach" claims new fixtures are addable without code changes.
  Inspection confirms this for the inner loop, BUT the outer fixture
  list at `test-customization-preserve.sh:687-693` is hard-coded:

  ```bash
  for fixture in \
      lightly-customized-minimal \
      heavily-customized \
      language-heterogeneous \
      custom-agents-heavy \
      v10-with-customization
  do
  ```

  Adding a 6th fixture requires editing this list. The "no code
  changes" claim is therefore subject to the caveat that the fixture
  list itself is code. Either (a) auto-discover via `for fixture in
  $(ls -d "$FIXTURES_DIR"/*/)` (with a sort for determinism), or
  (b) document the caveat in README under "How to add a fixture."
- **Recommended fix:** Replace hard-coded list with auto-discovery:

  ```bash
  for fixture_path in "$FIXTURES_DIR"/*/; do
      [[ -d "$fixture_path" ]] || continue
      fixture=$(basename "$fixture_path")
      printf "\n--- 8.%s ---\n" "$fixture"
      run_fixture "$fixture"
  done
  ```

  Auto-discovery makes the README claim accurate and matches the
  pattern used by other fixture-driven test scripts in the pack.
  Output ordering becomes filesystem-dependent — wrap in
  `LC_ALL=C` `sort` if deterministic ordering matters (it does for
  PASS/FAIL diffability across machines).

### F-8 — NIT — Manifest `notes` column is documented but unused

- **File reference:** `scripts/tests/fixtures/customization-preserve/README.md:114`
- **Description:** README says column 4 (`notes`) is "human-readable
  description (not asserted; for fixture authors)". The runner reads
  it into `$notes` and never uses it. This is fine — the column has
  documentary value — but a reader who runs `grep -nE notes
  test-customization-preserve.sh` will be confused that the variable
  is read and never referenced. A `# notes is unused but kept for
  manifest-row symmetry` comment near the read would close the gap.
- **Recommended fix:** Add a one-line comment in the runner near
  line 594 explaining `notes` is read for column-position discipline
  only.

### F-9 — NIT — Heavily-customized PM-CHAT.md sidecar untested for content

- **File reference:** `scripts/tests/fixtures/customization-preserve/heavily-customized/assertions.tsv:5`
- **Description:** The PM-CHAT.md sidecar assertion checks for
  `project-pm-rule` substring. That confirms the project edit was
  preserved, but doesn't confirm the dest got the new pack content.
  Symmetric to F-3 / F-4 — the "needs-reconciliation" disposition
  pair (sidecar = ours, dest = theirs) needs paired assertions to
  catch a regression that swaps them. Same shape applies to
  `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `bootstrap.sh` rows. (Grouped
  here as one NIT to avoid clutter.)
- **Recommended fix:** Add `dest` assertions for the
  customization-detected-needs-reconciliation rows mirroring the
  existing sidecar assertions, picking a substring unique to
  `theirs/` content (e.g., `v11 addition` for trinity files,
  `step two (added in v11)` for bootstrap.sh).

## 4. Cross-fixture coverage matrix

The 5 fixtures together exercise these (class × disposition) pairs.
"X" = exercised; "—" = not exercised. Reviewer-built table from
manifest inspection.

| Class                | unchanged | pack-update | merged-with-cust | needs-reconciliation | project-only | removed-by-* | project-deleted | removed-everywhere |
|----------------------|-----------|-------------|-------------------|---------------------|--------------|--------------|-----------------|--------------------|
| trinity              | X (light) | —           | —                 | X (heavy, v10)      | —            | —            | —               | —                  |
| pack-agent           | —         | X (caa)     | X (caa)           | X (caa)             | —            | —            | —               | —                  |
| pack-script          | —         | X (lang)    | X (lang)          | X (heavy, lang)     | —            | —            | —               | —                  |
| pm-chat              | —         | —           | —                 | X (heavy)           | —            | —            | —               | —                  |
| custom-agent         | —         | —           | —                 | —                   | X (all 5)    | —            | —               | —                  |
| custom-script        | —         | —           | —                 | —                   | X (heavy)    | —            | —               | —                  |
| claude-settings      | —         | —           | X (light, heavy, v10) | —              | —            | —            | —               | —                  |
| codex-config         | —         | —           | X (heavy, v10)    | —                   | —            | —            | —               | —                  |
| gemini-env           | —         | —           | —                 | X (lang, v10)       | —            | —            | —               | —                  |
| generic              | —         | —           | —                 | —                   | —            | —            | —               | —                  |

(`light`=lightly-customized-minimal, `heavy`=heavily-customized,
`lang`=language-heterogeneous, `caa`=custom-agents-heavy,
`v10`=v10-with-customization)

**Gaps:**

- All four removal columns (`removed-by-pack-clean`,
  `removed-by-pack-customized`, `project-deleted-pack-kept`,
  `removed-everywhere`) are completely empty (F-5).
- `unchanged-pack` is exercised only for `trinity` (light fixture).
  Other classes never exercise the no-op happy path.
- `merged-with-customization` for `pack-script` (lang fixture
  format-python.sh) only — no parallel for trinity / pack-agent /
  pack-script edits where ours edited but theirs didn't beyond the
  one case.
- `claude-mcp-example` (`.mcp.json.example`) is in the SUT classifier
  but no fixture row exercises it. (`codex-config-example` similar.)
- `pm-chat` only exercised in the `needs-reconciliation` disposition.
- `generic` (catch-all class) not exercised by any fixture row.

The inline TSV cases at Groups 1-7 cover most of these algorithmic
unit cases. Group 8 is end-to-end and is intentionally narrower. The
README's "spans the practical customization-shape space" claim should
be tightened to reflect this (per F-5).

## 5. Spec compliance checklist

| BD-096 spec item                                              | Status | Evidence |
|---------------------------------------------------------------|--------|----------|
| 5 fixture directories                                         | PASS   | `ls scripts/tests/fixtures/customization-preserve/` shows 5 dirs |
| OT-modeled fixture is one of five                             | PASS   | `v10-with-customization/` per README §5 |
| README explains each fixture                                  | PASS   | `scripts/tests/fixtures/customization-preserve/README.md` §1-5 |
| All 5 pass `test-customization-preserve.sh` end-to-end        | FAIL   | CI run 25892912819 fails 8 tests (F-1) |
| Phase-task fixtures NOT included (deferred to BD-106)         | PASS   | No phase-task content in any manifest |
| Pack memory: BD-088 OT cases preserved                        | PASS   | Groups 1-7 byte-identical (`git diff` 0 deletions) |
| Pack memory: Trinity rule N/A (no pack trinity files modified)| PASS   | `git show 4a5a6e5 --name-only \| grep -E '^(CLAUDE\|AGENTS\|GEMINI)\.md$'` empty |
| Pack memory: PM-only files untouched                          | PASS   | Commit touches only fixture files + test runner + IMPLEMENTATION-REPORT |
| Pack memory: agent did not commit                             | PASS   | Commit author = David Shane (Pack Chat), not agent |
| README repository layout updated                              | INFO   | README.md `scripts/tests/` section pre-existing gap (not new); see N-3 |

## 6. Architectural soundness

The data-driven manifest+assertions approach is structurally sound and
matches how `customization_preserve` is exercised in production
(`scripts/migrate-v10-to-v11.sh` + `scripts/init-project.sh --update`,
both of which iterate over a per-file class+rel list and call the
strategy function once per file). The fixture loop's
init-once-per-fixture pattern correctly mirrors the production
init-once-per-migration pattern.

One architectural concern (worth surfacing but not blocking): the
fixtures encode the EXPECTED disposition per row. When the algorithm's
disposition vocabulary evolves (e.g., a new disposition added in
v11.1), every fixture that touches the affected class must be updated
in lockstep. The manifest format does not have a way to express
"any of these dispositions is acceptable" — useful for future-proofing
when the algorithm's exact disposition is implementation-detail and
the assertion really cares about "preserved vs not preserved." Defer
to a future BD if/when this becomes painful.

## 7. Notes (non-findings)

- **N-1.** Implementation report §"Verification gate evidence" claims
  validate-pack ships "Checks 1-31 plus 4 informational" and reports
  "35/35 PASS." The actual count of `── Check` headers visible at
  console is 29; the wording is inconsistent. Functional outcome is
  fine (PASSED — all checks clean). Suggest tightening the report's
  count phrasing to match the visible header count or removing the
  count entirely.
- **N-2.** Implementation report §"Files changed" claims `+162
  lines`; `git diff --shortstat` reports `+156 insertions(+)`. Off
  by 6 lines, possibly counted with surrounding diff context.
  Cosmetic; no action.
- **N-3.** README.md `scripts/tests/` listing (lines 218-219) names
  two test runners but omits `test-customization-preserve.sh` and
  the new `fixtures/customization-preserve/` tree. This is a
  pre-existing README gap, not introduced by this batch — but a
  follow-up README update (Pack Chat-only) would close it. Out of
  scope for this batch's fix cycle but worth flagging to the user.
- **N-4.** The fixture trinity files (CLAUDE.md / AGENTS.md /
  GEMINI.md per fixture) intentionally have non-symmetric per-tool
  H1 (`# CLAUDE.md` vs `# AGENTS.md` vs `# GEMINI.md`) and per-tool
  intro lines (`Project rules for Claude Code CLI.` vs `Codex CLI
  agents` vs `Gemini CLI agents`). The remaining content (Project-
  extension rules) IS parallel across the three. This matches the
  pack's trinity convention (per-tool H1 OK, body parallel). No
  finding.

## 8. What the implementation got right

- The 5-fixture directory structure with separate `base/`, `ours/`,
  `theirs/` subtrees mirrors how three-way merges work in production
  and makes it visually obvious which side contributed what edit.
- The TSV manifest format is self-describing: the header line
  documents the columns inline, and the `auto` class sentinel cleanly
  routes to the SUT's auto-classifier when the fixture author wants
  to test the classifier rather than pin its output.
- The README.md (147 lines) is genuinely useful for future fixture
  authors — it documents the manifest schema, the assertion schema,
  the per-fixture customization shape, and the determinism contract.
- Groups 1-7 are byte-identical to the pre-batch state. This is the
  hardest discipline in test-runner extension and the implementation
  honored it.
- The runner's `customization_preserve_init` per-fixture call
  correctly resets state between fixtures, so cross-fixture
  contamination cannot cause spurious passes/fails.
- BD-088 OT preservation is genuinely additive (inline TSV cases
  intact + new `v10-with-customization/` directory), which is the
  right call — converting the inline cases to directory form would
  have lost the algorithmic-unit-test surface that Groups 1-7
  provide.
- The runner correctly runs under `set -uo pipefail` (no `set -e`)
  and uses explicit `if !` failure-handling, so a SUT call returning
  rc=1 cleanly produces a t_fail rather than aborting the whole
  Group 8 run.
- The fixture content uses bash 3.2-compatible constructs throughout
  (no `mapfile`, no `${var,,}`, no associative arrays). macOS
  default bash will not be a portability issue.

## 9. Required pre-merge actions

1. **Apply F-1 fix.** Add the `.gitignore` exception line + `git add
   -f` the four `.env` files. Re-push. Verify CI run goes green
   (`gh run list --workflow=validate-pack.yml --limit 1`).
2. **Apply F-2..F-9** per Pack Chat's per-finding fix-or-defer call
   (per pack memory rule "Fix all review findings including nits;
   nits become tech debt"). Default-fix recommended for F-2..F-4
   (assertion gaps) and F-7 (auto-discovery) since they tighten the
   fixture suite without scope expansion. F-5 is the only finding
   with potential scope debate (whether to add a 6th fixture or just
   tighten the README claim) — surface to the user.
3. After F-1 lands and CI is green, the BD-096 status flip is safe.
   Per the "implicit BD status flip on batch completion" pack-memory
   rule, no separate user approval is needed for the flip itself
   once the green-CI condition is met.

End of review.
