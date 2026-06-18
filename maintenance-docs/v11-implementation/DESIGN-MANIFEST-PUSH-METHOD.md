# DESIGN — Push-Time Manifest Regeneration Method + Enforcing Check

**Author:** pack-architect (read-only design pass)
**Date:** 2026-06-17
**Pack repo HEAD at design time:** `1143267` (full `1143267dba9ba30a439fe17150989bdc61b0a871`), branch `v11-dev`
**Output regime:** IN-PLACE in MAIN checkout (`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`); read-only; only write is this doc.
**Anchoring:** see §10 — this is NOT a fit for BD-226 (worktree-isolation); flag a new BD to the user.

---

## 0. Scope statement (what this design delivers)

Per the user-frozen direction, this design replaces the per-commit prose
obligation `regenerate-manifest-v11-surface` (RC9) with TWO implemented
mechanisms:

- **(A) A push-time manifest method** — a pack-side tool that, immediately
  before a push, regenerates `test-fixtures/manifest.txt` **exactly once iff a
  fixture-input file changed** in the commits about to be pushed, and is a
  **complete no-op** otherwise. Commit-count-agnostic.
- **(B) An enforcing CHECK** — machine verification at the pushed HEAD that the
  manifest is correct (never stale), so correctness does not depend on anyone
  remembering to run the method. The existing `build.sh --verify` CI step is
  already most of this; this design proves it is sufficient as the
  correctness gate and adds ONE cheap validate-pack staleness pre-screen
  (Check 62) only where it buys a faster, clearer failure.

The per-commit RC9 obligation is REMOVED from prose; a minimal pointer at the
tool/check remains.

This design does NOT touch the determinism pins, the fixture builders, the
shard matrix, or the worktree model.

---

## 1. Grounding — Empirical Evidence

### EB-1 — manifest is a generated 6-row artifact; fixtures are gitignored; manifest is tracked

- **Command:** `git ls-files test-fixtures/manifest.txt` ; `cat test-fixtures/.gitignore` ; `cat test-fixtures/manifest.txt`
- **Output (verbatim, abridged to load-bearing lines):**
  ```
  test-fixtures/manifest.txt          # tracked
  .gitignore pattern:  *  / !manifest.txt  / !build.sh  / !README.md   # manifest committed, fixture dirs ignored
  manifest rows:
    v10-minimal  19558cba...
    v10-realistic-ot  4c62945f...
    v11-realistic-ot  49a4b801...
    v11-flat-file  688fbff2...
    v11-tracker-on  67fa09c0...
    existing-project-mid-dev  a54e081a...
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** the manifest is a committed, generated artifact (6 fixture
  rows = `git rev-parse HEAD` per built fixture). Fixture build dirs are
  gitignored; the manifest is the only committed product of `build.sh`.
- **Conclusion:** SUPPORTED.

### EB-2 — `build.sh --verify` is a working enforcing check; exit 0 on intact, returns mismatch on stale

- **Command:** `bash test-fixtures/build.sh --verify; echo "exit=$?"` ; plus read of `_verify()` lines 964-992.
- **Output (verbatim):**
  ```
    v10-minimal OK: 19558cba...
    ...
    existing-project-mid-dev OK: a54e081a...
  exit=0
  ```
  `_verify()` body: for each fixture, `actual=$(git -C "$target" rev-parse HEAD)`;
  if `"$expected" == "$actual"` → `info OK`, else `warn ... MISMATCH; mismatch=1`;
  `return "$mismatch"`. Missing fixture (`! -d "$target/.git"`) also sets
  `mismatch=1`.
- **HEAD-SHA:** `1143267`
- **Interpretation:** `--verify` returns non-zero on ANY stale OR missing
  manifest row vs the freshly-built fixture HEADs. CI rebuilds fixtures, restores
  the committed manifest (step a2: `git checkout HEAD -- test-fixtures/manifest.txt`),
  then runs `--verify` — so a committed-but-stale manifest fails CI.
- **Conclusion:** SUPPORTED — the correctness gate (B) ALREADY EXISTS in CI as
  `build.sh --verify`. The problem statement's "no check enforces correctness" is
  about the PER-COMMIT obligation; the PUSHED-HEAD correctness gate is live.

### EB-3 — CI verifies at push-HEAD via build.sh --verify; runs on push

- **Command:** read `.github/workflows/validate-pack.yml` lines 103, 182-196.
- **Output (verbatim):**
  ```
  on: push
  - name: build test fixtures (only if this shard needs them)
      run: |
        if python3 scripts/lib/ci-shard-plan.py --shard ${{ matrix.shard }} --needs-fixtures; then
          bash test-fixtures/build.sh --all --clean
          git checkout HEAD -- test-fixtures/manifest.txt   # restore committed manifest before --verify
          bash test-fixtures/build.sh --verify
        fi
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** the fixture-owning shard rebuilds fixtures, restores the
  COMMITTED manifest, then `--verify` compares the committed manifest's SHAs
  against the freshly-built fixture HEADs. This runs on every push. A stale or
  missing committed manifest fails this step (RED).
- **Conclusion:** SUPPORTED.

### EB-4 — Determinism: identical inputs ⇒ identical fixture SHA ⇒ manifest changes IFF a fixture input changes

- **Command:** read `test-fixtures/build.sh` lines 44-47, 99-111; `git log -12 --format="%h|%s"`; `git log -8 ... -- test-fixtures/manifest.txt`.
- **Output (verbatim, load-bearing):**
  ```
  readonly FIXTURE_EPOCH="2026-01-01T00:00:00Z"
  readonly FIXTURE_AUTHOR_NAME="Test Fixture"
  _fixture_commit_all: GIT_AUTHOR_DATE=$FIXTURE_EPOCH GIT_COMMITTER_DATE=$FIXTURE_EPOCH
     GIT_AUTHOR_NAME=$FIXTURE_AUTHOR_NAME ... git commit -q --allow-empty -m "$msg"

  Recent pack-only commits that did NOT touch the manifest (empty manifest diff):
    438ec4d docs ... BD-221 CX1 agent-migration design ... (pack-only)   [maintenance-docs/]
    9a2d9b9 feat ... BD-221 CX1 agent-migration model ... (pack-only)
    c4beb8d docs ... BD-189 split audit trail ... (pack-only)            [maintenance-docs/]
    bc7e762 docs ... BD-221 C7 audit reports ... (pack-only)            [maintenance-docs/]
    f945fb9 docs ... BD-221 C6 audit reports ... (pack-only)            [maintenance-docs/]
  Recent commits that DID touch the manifest:
    2af84b3 ... BD-221 C6 build.sh EB-21 version-branch ... + manifest regen (pack-only)  [build.sh = fixture builder]
    1143267 ... BD-221 C10 ... client deliverables (project-template) (project-only)       [project-template/ = fixture input]
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** the commit identity is fully pinned (epoch + author + empty
  msg), so two builds from the same pack source produce byte-identical fixture
  SHAs. Empirically, commits touching ONLY `maintenance-docs/` (a non-input)
  produced empty manifest diffs; commits touching `build.sh` (the builder) or
  `project-template/` (the bulk input) changed the manifest. → the manifest
  changes IFF a fixture input (or the builder) changes.
- **Conclusion:** SUPPORTED.

### EB-5 — The precise fixture-input source set is THREE top-level dirs (a strict subset of RC9's four)

- **Command:** `grep -oE '\$PACK/[a-z][a-z0-9./_-]*' scripts/init-project.sh | awk -F/ '{print $1}' | sort | uniq -c`; install-map source-prefix extraction; `grep -n 'PACK/pack-ops\|pack-ops/' scripts/init-project.sh | grep -i 'cp\|copy\|install'`; `grep -n pack-ops test-fixtures/build.sh`.
- **Output (verbatim):**
  ```
  $PACK/<dir> source references in init-project.sh:
     25 project-template
      7 scripts
      9 supporting-docs
  install-map source-side top-level prefixes: project-template, supporting-docs
  pack-ops fixture-input copy sites in init-project.sh:   (none)
  pack-ops references in build.sh:                          (none)
  per-entry helpers sourced by build.sh at runtime:        scripts/lib/per-entry/*.sh  (under scripts/)
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** every file that init-project.sh installs into a fixture, or
  that build.sh sources at fixture-build time, lives under exactly one of
  `project-template/`, `scripts/`, or `supporting-docs/`. **`pack-ops/` is NOT a
  fixture input** — zero copy sites, zero build.sh references. RC9's claim that
  `pack-ops/HELP-FRAGMENT-TRACKER.md` is copied is STALE: init-project.sh line
  951 copies `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (project-side),
  not the pack-ops copy.
- **Conclusion:** SUPPORTED. The current RC9 4-dir trigger (`project-template/`,
  `scripts/`, `pack-ops/`, `supporting-docs/`) is OVER-broad by one full
  directory (`pack-ops/`), plus most of `supporting-docs/` (only 2 named files
  are actual inputs — see EB-6).

### EB-6 — Within supporting-docs/, only 2 files are fixture inputs

- **Command:** read `scripts/init-project.sh` lines 677-693, 1294-1295.
- **Output (verbatim):**
  ```
  supporting-docs/METHODOLOGY.md:docs/pack/METHODOLOGY.md:generic
  supporting-docs/INSTALL-PROCEDURES.md:docs/pack/INSTALL-PROCEDURES.md:generic
  (S6 copies METHODOLOGY.md + INSTALL-PROCEDURES.md to client docs/pack/)
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** only `supporting-docs/METHODOLOGY.md` and
  `supporting-docs/INSTALL-PROCEDURES.md` reach a fixture. The remaining 7
  `supporting-docs/` files referenced in init-project.sh are pre-install
  references not copied to clients.
- **Conclusion:** SUPPORTED.

### EB-7 — No validate-pack check enforces per-commit manifest freshness; manifest is scope-neutral for Check 36

- **Command:** `grep -n "_SCOPE_NEUTRAL_GENERATED_PATHS\|manifest.txt\|build.sh --verify" scripts/validate-pack.py`; highest Check number.
- **Output (verbatim):**
  ```
  _SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({ "test-fixtures/manifest.txt", })
  (Check 36 _is_scope_neutral_generated → excludes the manifest from scope honesty)
  highest validate-pack Check number: 61
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** no validate-pack check verifies the manifest reflects
  current inputs; only CI's `build.sh --verify` does (at push-HEAD). The manifest
  is already exempt from Check 36. A new check would be Check 62.
- **Conclusion:** SUPPORTED.

### EB-8 — Existing commit-range + diff machinery in validate-pack.py is reusable

- **Command:** read `_commits_to_walk()` (lines 4023-4069) + `_commit_paths()` (4072-4085).
- **Output (verbatim, load-bearing):**
  ```
  range_spec = os.environ.get("PACK_CHECK_36_RANGE", "HEAD~0..HEAD")
  ... git log --reverse --format=%H%x09%s <range>
  _commit_paths(sha): git show --name-only --format= <sha>  → list of touched paths
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** the pack already has a tested helper that walks a git range
  and returns touched paths per commit. The push-time predicate can reuse this
  exact pattern (git-diff-name-only over the push range) rather than inventing
  new machinery.
- **Conclusion:** SUPPORTED.

### EB-9 — CI test set is disk-derived via globs; a new test auto-wires by name; a new non-test tool does not collide

- **Command:** read `scripts/lib/ci-shard-plan.py` lines 38-41, 80, 119; `cat scripts/ci-test-wiring-allowlist.txt`; `ls scripts/tests/`.
- **Output (verbatim, load-bearing):**
  ```
  disk KEEP set = {scripts/test*.sh + scripts/tests/*.sh
                   + scripts/tests/fixture-dependent/*.sh} − allowlist
  allowlist currently: exactly 1 entry (tracker-bd204 live-GH oracle)
  scripts/tests/ holds *-test.sh files (pack-help-test.sh, etc.)
  ```
- **HEAD-SHA:** `1143267`
- **Interpretation:** a new test placed at `scripts/tests/manifest-method-test.sh`
  is auto-discovered + sharded on next push (no manual wiring). A new NON-test
  tool placed at `scripts/manifest-sync.sh` does NOT match `scripts/test*.sh`
  (does not begin with `test`), so it is NOT swept into the test set — no
  allowlist entry needed. A library helper under `scripts/lib/` is likewise not
  in the test glob.
- **Conclusion:** SUPPORTED.

### EB-10 — No existing pack-side push-time / pre-push tool exists

- **Command:** `ls scripts/*.sh scripts/lib/*.sh`; `grep -rln "pre-push\|push-time" scripts/ pack-ops/ .claude/skills/`.
- **Output (verbatim):** the script list (init-project.sh, add-capability.sh,
  migrate-v10-to-v11.sh, pack-help.sh, … tracker-*.sh); push-time grep returned
  nothing.
- **HEAD-SHA:** `1143267`
- **Interpretation:** there is no existing push/release helper; this is a clean
  net-new addition under `scripts/`.
- **Conclusion:** SUPPORTED.

---

## 2. The method (A) — `scripts/manifest-sync.sh`

### 2.1 Where it lives + dependency-direction justification

**Path:** `scripts/manifest-sync.sh` (pack-side, top-level scripts dir).

**Justification (dependency-direction-placement):** this is a pack-internal
build/release tool. It is invoked by the pack orchestrator (Pack Chat) at
push-time against the pack repo; it `source`s pack-side knowledge of the
fixture-input set and calls `test-fixtures/build.sh` (pack-side). It is NEVER a
runtime dependency of any project-side deliverable, and no project surface
invokes it. It is therefore correctly pack-side and MUST NOT ship to clients —
it does not enter the install-map and is NOT added to
`_SANCTIONED_PACK_SIDE_SHIPPED` (per CI Check 47, the sanctioned shipped set
stays exactly `{scripts/lib/detect.sh, scripts/pack-help.sh}`).

The fixture-input PREDICATE data (the input-path globs) lives in a single
pack-side source of truth so it cannot silently drift — see §2.3.

### 2.2 How it is invoked at push (and by whom)

**Agents never push.** The orchestrator (Pack Chat) — the only actor that runs
`git push` — runs `manifest-sync.sh` as the pre-push step, immediately before
the push, AFTER all commits for the push are landed locally. Concretely the
push sequence becomes:

```
# Pack Chat, immediately before `git push`:
bash scripts/manifest-sync.sh          # regen-iff-needed over the unpushed range
#  → if it staged a manifest change, Pack Chat amends/commits it (see §2.5) with user approval
git push
```

`manifest-sync.sh` itself NEVER pushes and NEVER commits (agents/tools do not
commit; only the orchestrator commits, with user approval). It REGENERATES the
manifest file on disk and reports whether the file changed; the orchestrator
decides how to land it (§2.5).

The tool is also runnable ad-hoc by a developer at any time (idempotent — §2.6).

### 2.3 The fixture-input-change predicate (precise + drift-proof)

**Decision: use the EXACT fixture-input path set, not the v11-surface superset.**

**The exact set (derived in EB-5/EB-6), expressed as path predicates:**

1. Any path under `project-template/`
2. Any path under `scripts/` **EXCEPT** the test set + this tool itself
   (rationale below)
3. `test-fixtures/build.sh` (the builder is itself a fixture-determining input)
4. Exactly `supporting-docs/METHODOLOGY.md`
5. Exactly `supporting-docs/INSTALL-PROCEDURES.md`

**Why exact, not the v11-surface superset — the trade-off:**

- The v11-surface superset (`project-template/` + `scripts/` + `pack-ops/` +
  `supporting-docs/`) is SAFE (no false negatives) but produces FALSE POSITIVES:
  EB-4 shows `maintenance-docs/`-style and `pack-ops/`-only and
  `supporting-docs/`-non-input commits trigger a needless ~30-90s rebuild that
  yields an EMPTY manifest diff. The user-frozen direction #1 explicitly forbids
  "wasted rebuild when nothing affecting the manifest changed." The superset
  violates that intent for the `pack-ops/`-heavy and `supporting-docs/`-doc
  commit traffic that dominates this repo (EB-4: 4 of the last ~7 pack commits
  were `maintenance-docs`/`pack-ops` non-inputs).
- The EXACT set has NO false negatives **so long as the input set is kept in
  sync with init-project.sh**, and it eliminates the wasted-rebuild class
  entirely.

**Drift-proofing (the maintainability mechanism) — single source of truth +
CI guard:**

The predicate must not silently drift from init-project.sh's actual copy sites.
Two layers:

- **(a) Single SoT for the input globs:** the predicate path-set lives in ONE
  place — a small declarative list at the top of `manifest-sync.sh` (or, if the
  enforcing check also needs it, a tiny shared `scripts/lib/manifest-inputs.sh`
  that both the tool and the check source). Format: an array of repo-relative
  globs + a deny-array (test set + the tool). This is the ONLY place the set is
  written.
- **(b) Anti-drift completeness guard (folded into the enforcing check, §3):**
  the safety net for "init-project.sh grew a new copy site outside the declared
  set." This is handled WITHOUT re-listing init-project.sh: the enforcing
  correctness check (`build.sh --verify` at push-HEAD, EB-2/EB-3) is the
  backstop — if a NEW fixture-input dir is added to init-project.sh and the
  predicate does NOT yet cover it, then a commit touching ONLY that new
  input would (under the exact predicate) skip regeneration, ship a stale
  manifest, and `build.sh --verify` would FAIL on the next push (RED). So the
  exact predicate cannot ship a SILENTLY stale manifest — the correctness gate
  catches it. The failure is loud, attributable, and self-documenting (the
  remediation is "add the new input dir to manifest-inputs"). This is the
  measure-then-bound contract: the predicate is sized to the measured input set,
  and the correctness gate (which is input-set-agnostic — it rebuilds ALL
  fixtures from ALL of init-project.sh's actual sources) is the bound's backstop.

**Why `scripts/test*.sh` + `scripts/tests/**` are EXCLUDED from input set (2):**
test scripts are not installed into any fixture by init-project.sh (init copies
`scripts/pack-help.sh` + `scripts/lib/detect.sh` only — EB-9 / init lines
992-997). A `scripts/tests/foo-test.sh` edit does not change any fixture SHA.
Including them would re-introduce false positives. The deny-list keeps the
input predicate faithful. **Conservative refinement:** because init-project.sh
copies only a SUBSET of `scripts/` into fixtures (`pack-help.sh`, `lib/detect.sh`,
`lib/per-entry/*.sh` sourced by build.sh), the predicate MAY be tightened to
exactly those, but the safe-and-simple choice is "all of `scripts/` minus the
test set minus this tool," which has no false negatives and only the minor
false positive of a `scripts/`-non-installed edit (rare; far smaller than the
`pack-ops/` class). **Pick: all-`scripts/`-minus-tests** (simplicity + zero
false-negative risk; the false-positive surface is tiny). State this trade-off
explicitly so the planner does not re-litigate.

**The predicate range (commit-count-agnostic):** the predicate keys off "fixture
inputs changed since the last pushed state," NOT commit count. Compute the
range as the unpushed commits:

```
RANGE="@{upstream}..HEAD"          # commits not yet on the tracking remote
#   fallback if no upstream configured: origin/<branch>..HEAD
#   fallback if neither resolves:       HEAD (screen the tip only) + warn
CHANGED=$(git diff --name-only "$RANGE")    # union of all paths in the push
```

Then: `regen_needed = any(path in CHANGED matches an input glob and not a deny
glob)`. This is identical for a single commit or a 20-commit batch — it is a set
test over the union diff, not a per-commit loop. (Reusing the EB-8 pattern;
`git diff --name-only <range>` is the union form of `_commit_paths` across the
range.)

### 2.4 What it does on change (regenerate once)

If `regen_needed`:

1. Run the canonical rebuild ONCE: `bash test-fixtures/build.sh --all --clean`
   (rebuilds all 6 fixtures deterministically and rewrites `manifest.txt` via
   `_update_manifest`). This is the SAME command RC9 prescribed, run ONCE at
   push instead of N times across N commits.
2. Report the manifest diff: `git diff --quiet -- test-fixtures/manifest.txt`.
   - If the manifest file CHANGED on disk → print
     `MANIFEST-CHANGED: test-fixtures/manifest.txt` and exit 10 (a distinct
     non-zero "action needed" code, NOT an error).
   - If the manifest did NOT change despite a matching input (a legitimate case
     — e.g., a comment-only edit to an input file) → print `MANIFEST-NOOP` and
     exit 0.
3. The tool NEVER stages or commits (tools don't commit). It leaves the
   regenerated `manifest.txt` in the working tree and signals the orchestrator
   via exit code + stdout token.

### 2.5 How the orchestrator lands the regenerated manifest

Per `agents-never-commit` + `pack-chat-minor-edits-only`: the manifest is a
bookkeeping/generated artifact in the pack-chat-direct set
(`_SCOPE_NEUTRAL_GENERATED_PATHS`), so when `manifest-sync.sh` exits 10
(MANIFEST-CHANGED), Pack Chat — with user approval — commits the regenerated
manifest. Two landing shapes (orchestrator chooses per situation; both
commit-count-agnostic):

- **Amend** the last unpushed commit if it is the fixture-input commit and not
  yet pushed (keeps the manifest with its cause). OR
- **Separate trailing commit** `chore: vN — regen test-fixtures/manifest.txt at
  push (fixture inputs changed)` if the push batches multiple commits (the
  manifest reflects the push's cumulative input state).

Either way the PUSHED HEAD carries a correct manifest. The choice is an
orchestrator/user decision at push time, not a tool decision.

### 2.6 No-op path + idempotency

- **No-op:** if `regen_needed` is false (no input path in the union diff), the
  tool prints `MANIFEST-SKIP: no fixture-input changed in <RANGE>` and exits 0
  WITHOUT running build.sh. Zero rebuild cost — satisfies user direction #1.
- **Idempotent:** re-running the tool when the manifest is already current
  produces MANIFEST-NOOP/MANIFEST-SKIP and exit 0 (rebuild is deterministic;
  `build.sh --all --clean` from unchanged inputs reproduces the same SHAs →
  empty diff). Running twice never produces a different result.

### 2.7 Exit-code contract (for the orchestrator)

```
0   → no action needed (SKIP: no input changed, or NOOP: input changed but manifest unchanged)
10  → MANIFEST-CHANGED: regenerated manifest differs; orchestrator must commit it before push
1   → error (build.sh failed, git range unresolvable in a hard way, etc.)
```

---

## 3. The check (B) — correctness enforcement at pushed HEAD

### 3.1 The existing `build.sh --verify` IS the correctness gate (sufficient as the hard gate)

EB-2 + EB-3 prove CI already, on every push, rebuilds all fixtures, restores the
committed manifest, and `--verify`s the committed manifest against freshly-built
fixture HEADs — failing RED on any stale or missing row. This is exactly the
"pushed HEAD's manifest is correct (never stale)" guarantee, and it does NOT
require or assume per-commit regeneration (it is a whole-manifest comparison at
HEAD, agnostic to how many commits or when the manifest was last regenerated).

**Conclusion: `build.sh --verify` is SUFFICIENT as the enforcing correctness
gate.** No change to the gate's logic is required. The method (A) exists to make
this gate GREEN cheaply (regen-iff-needed) rather than the gate existing because
of the method.

### 3.2 Add ONE cheap validate-pack pre-screen — Check 62 (manifest-staleness fast-fail)

`build.sh --verify` is correct but EXPENSIVE: it rebuilds all 6 fixtures
(~30-90s) and only runs in the fixture-owning shard. A developer running
`validate-pack.py` locally gets no manifest signal. Add a CHEAP structural
pre-screen so a stale/missing manifest fails fast and clearly in the always-run
`validate` job too.

**Check 62 — manifest-input-coherence (cheap, no fixture rebuild):**

- **What it asserts:** for the commit(s) in the walk range (reuse
  `_commits_to_walk` / `_commit_paths`, EB-8), IF any touched path matches the
  fixture-input predicate (§2.3, sourced from the SAME `manifest-inputs`
  SoT) THEN `test-fixtures/manifest.txt` MUST ALSO be in the touched-path set
  of the range. I.e., "an input changed in this push but the manifest did not"
  ⇒ FAIL (stale-manifest signal). Conversely, if no input changed, the manifest
  need not change (no false positive).
- **Why this is correct + cheap:** it is a PURE git-metadata + set-membership
  check — NO fixture rebuild, NO subprocess-per-entry, NO whole-real-tree scan.
  Cost is one `git log`/`git show` over a tiny range (the same calls Check 36
  already makes) + O(paths) membership tests. Per `ci-check-runtime-compounding`,
  this adds negligible per-invocation cost across the ~155 validate-pack battery
  invocations (it does the same kind of work Check 36 already does cheaply).
- **What it CANNOT do (honest limitation):** Check 62 cannot detect a
  comment-only input edit that legitimately produces no manifest change (it would
  false-positive on "input touched, manifest not touched" when the manifest
  genuinely shouldn't change). To avoid false positives, Check 62 is a
  **screen, not the authority** — it must allow the MANIFEST-NOOP case. Two
  options, pick (ii):
  - (i) Make Check 62 a soft WARN. (Rejected — user wants enforcement, not
    advisory.)
  - (ii) **Make Check 62 assert the WEAKER, ALWAYS-TRUE-WHEN-CORRECT invariant:**
    it does NOT require the manifest to be in the diff; instead it runs the
    cheap half of correctness — it recomputes whether the COMMITTED manifest is
    structurally well-formed (6 rows, names == build.sh FIXTURE_NAMES, each SHA
    is a 40-hex) AND defers the SHA-correctness to `build.sh --verify`. This
    keeps Check 62 a cheap structural screen (catches a truncated/garbled/wrong-
    row-count manifest instantly in the always-run job) while `build.sh
    --verify` remains the authoritative SHA-correctness gate. **This avoids the
    comment-only-edit false positive entirely** because it never asserts "input
    touched ⇒ manifest touched."

**Decision: Check 62 = cheap structural well-formedness screen** (row count ==
6, names == `_fixture_names_from_build_sh()` which already exists at validate-pack
line 6714, each value is `[0-9a-f]{40}` or a documented sentinel). The
SHA-correctness authority stays `build.sh --verify` (§3.1). This gives:
fast/clear local + always-run-job failure on a malformed manifest, plus the
authoritative SHA gate in CI. It respects `ci-check-runtime-compounding` (pure
file-read + regex; no rebuild).

**Net:** the hard correctness gate is the EXISTING `build.sh --verify` (no
change). Check 62 is a NEW cheap structural backstop. Neither requires
per-commit regeneration.

### 3.3 Proof the check catches a stale/missing manifest

- **Stale SHA (wrong row):** `build.sh --verify` rebuilds the fixture, computes
  the true HEAD, compares to the committed (stale) row → MISMATCH → `mismatch=1`
  → step fails RED (EB-2). PROVEN by the `_verify()` body.
- **Missing manifest file:** `_verify()` `die "manifest.txt missing"` exit 3
  (build.sh lines 966-968) → RED.
- **Missing row:** `_verify()` warns "not in manifest" / "built fixture not
  present" and sets `mismatch=1` → RED.
- **Malformed manifest (truncated / wrong row count / garbage SHA):** Check 62
  fails in the always-run `validate` job (fast), before the expensive rebuild
  even runs.
- **The "input changed but operator forgot to regen" case:** the operator did
  not run `manifest-sync.sh` (or ran it and ignored exit 10). The committed
  manifest is stale → `build.sh --verify` MISMATCH → RED. The method being
  skipped does NOT silently ship a stale manifest; the gate catches it. This is
  the load-bearing CI-safety property (§6).

---

## 4. Removal of the per-commit RC9 obligation (§ user direction #2)

### 4.1 Every RC9 prose surface (measured)

| # | Surface | Lines | Disposition |
|---|---------|-------|-------------|
| 1 | `CLAUDE.md` `## Pack memory` → "Regenerate test-fixtures/manifest.txt on every v11-surface commit." | 568-575 | REMOVE the per-commit obligation; REPLACE with a 1-line pointer at the method + check (§4.2). Trinity edit. |
| 2 | `AGENTS.md` same bullet | 527-534 | Same, lock-step (trinity rule). |
| 3 | `GEMINI.md` same bullet | 504-511 | Same, lock-step (trinity rule). |
| 4 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## regenerate-manifest-v11-surface` | 505-559 | REWRITE the section: keep the WHY (incident history is valuable provenance) but re-cast HOW-to-apply from "per-commit run build.sh --all --clean + stage" to "the push-time `manifest-sync.sh` regenerates iff needed; `build.sh --verify` (CI) + Check 62 enforce correctness." Update the stale `pack-ops/HELP-FRAGMENT-TRACKER.md`-is-an-input claim (EB-5). |
| 5 | memory cache `~/.claude/projects/<slug>/memory/feedback_manifest_regen_on_v11_surface.md` | whole file | REVISE: the recall line + MUST-READ pointer re-aimed at the method + check, not the per-commit run. (Pack-Chat-direct upkeep, NOT pack-coder — memory files are Pack Chat's own state.) |
| 6 | `pack-ops/PACK-CHAT.md` propagation table row 6 ("manifest regen if a v11-surface path changed") | 433, 435 | UPDATE the row to reference `manifest-sync.sh` at push, not a per-commit regen step in the propagation order. |

Note row 5 is a MEMORY file (Pack-Chat-direct, out-of-repo); rows 1-4 + 6 are
in-repo and go to pack-coder. Row 6 is `pack-ops/PACK-CHAT.md` which is
pack-chat-only — but a SUBSTANTIVE rewrite of landed content is MAJOR → routes
to coder per `pack-chat-minor-edits-only`.

### 4.2 What the minimal pointer says (replaces the per-commit obligation)

The trinity bullet (rows 1-3) shrinks to a pointer, e.g.:

> **Manifest is push-time, tool-enforced — not a per-commit chore.**
> `test-fixtures/manifest.txt` is regenerated **only at push, only when a
> fixture input changed**, by `scripts/manifest-sync.sh` (run by the
> orchestrator before `git push`). Correctness is enforced by CI
> `build.sh --verify` + validate-pack Check 62 — do NOT regenerate the manifest
> per-commit. `[rationale: regenerate-manifest-v11-surface]`

The authority now lives in the TOOL (`manifest-sync.sh`) + the CHECK
(`build.sh --verify` / Check 62), not in prose. The `[rationale: ...]` tag is
retained so the cross-reference machinery (bijection / anti-restate per
PACK-CHAT.md propagation) stays satisfied; the RATIONALE section (row 4) is the
landing place for the WHY.

### 4.3 `[roles: coder]` tag

The bullet's `[roles: coder]` tag should change to reflect the new owner:
the per-commit chore was a coder obligation; the push-time regen is an
ORCHESTRATOR action. Recommend `[roles: universal]` for the pointer (any actor
should know not to regen per-commit) — flag for planner/user.

---

## 5. Measure-then-bound blast radius (every surface, categorized + sized)

| Surface | Path | Change | Category | Size |
|---------|------|--------|----------|------|
| NEW tool | `scripts/manifest-sync.sh` | create | ADD | ~120-180 lines bash |
| NEW shared input SoT (optional) | `scripts/lib/manifest-inputs.sh` | create | ADD (only if Check 62 + tool share it; else inline in tool) | ~30 lines |
| Builder | `test-fixtures/build.sh` | NONE | UNCHANGED | 0 — `--all --clean` + `--verify` already do the job |
| Validator | `scripts/validate-pack.py` | add Check 62 (structural manifest screen) + register | ADD | ~50-70 lines (1 check fn + registry entry); reuses `_fixture_names_from_build_sh` (line 6714) + `_commits_to_walk`/`_commit_paths` |
| CI workflow | `.github/workflows/validate-pack.yml` | NONE | UNCHANGED | 0 — `build.sh --verify` step already present (EB-3); manifest-sync runs at the ORCHESTRATOR's push, not in CI |
| RC9 trinity ×3 | `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | shrink bullet to pointer | EDIT | ~8 lines each → ~5 lines each, lock-step |
| RC9 rationale | `pack-ops/PACK-MEMORY-RATIONALE.md` | rewrite HOW; fix stale input claim | EDIT | ~55-line section rewrite |
| RC9 memory cache | `feedback_manifest_regen_on_v11_surface.md` | revise recall + pointer | EDIT (Pack-Chat-direct) | ~1 file |
| RC9 propagation row | `pack-ops/PACK-CHAT.md` rows 433/435 | update row 6 + order note | EDIT | ~2 lines |
| NEW test (tool) | `scripts/tests/manifest-method-test.sh` | create (auto-wires by glob, EB-9) | ADD | ~120-200 lines |
| NEW test (Check 62) | folded into validate-pack per-check test infra (Check 62 gets a per-check test per `check_ci_workflow_wires_per_check_tests`, validate-pack line 6553) | create/extend | ADD | per existing per-check-test convention |
| manifest itself | `test-fixtures/manifest.txt` | regenerated once if this BD's commits touch an input (they touch `scripts/` → YES) | REGEN | the BD's own push runs manifest-sync once |

**NOT changed (explicitly bounded out):** determinism pins, fixture builders'
per-fixture logic, the shard matrix / ci-shard-plan.py (the new test
auto-wires; the new tool is not a test so it is not swept — EB-9), the worktree
model, `_SANCTIONED_PACK_SIDE_SHIPPED` (the tool does not ship), the install-map.

**Check 62 cost bound:** pure git-metadata + file-read + regex; no fixture
rebuild, no subprocess-per-entry, no whole-real-tree scan → safe under
`ci-check-runtime-compounding` across the ~155-invocation battery.

---

## 6. CI-safety proof

**Claim:** the pushed HEAD is always manifest-correct under the method, and a
missed/failed regen is CAUGHT by the check (RED), never silently shipped.

1. **Happy path:** orchestrator runs `manifest-sync.sh` before push. If an input
   changed, it regenerates once (exit 10), orchestrator commits the manifest,
   push carries a correct manifest. `build.sh --verify` GREEN.
2. **Operator skips the tool / ignores exit 10 (the failure mode RC9 prose was
   guarding against — EB-7 incidents `667d2dd`, `4120d19`):** the committed
   manifest is stale at the pushed HEAD. CI rebuilds fixtures, restores the
   committed manifest, `--verify` → MISMATCH → RED (EB-2/EB-3). The stale
   manifest CANNOT ship green. This is strictly STRONGER than the old prose
   regime, where the same gate already caught it — but now the method makes the
   GREEN path cheap and the gate is documented as the authority, not honor-system
   prose.
3. **New fixture input added to init-project.sh but not to the predicate (drift):**
   a commit touching only the new input would skip regen under the exact
   predicate → stale manifest → `build.sh --verify` rebuilds from ALL of
   init-project.sh's actual sources (input-set-agnostic) → MISMATCH → RED. Loud,
   attributable, self-documenting remediation (add the dir to `manifest-inputs`).
   The exact predicate therefore cannot silently ship a stale manifest.
4. **Malformed manifest:** Check 62 fails fast in the always-run `validate` job.

In every failure path the result is RED, never a silent stale ship. QED.

---

## 7. Test plan (the method AND the check are themselves tested)

Per `enumerate-encoding-surfaces`, every surface that encodes the new behavior
gets test/validator coverage in lock-step.

### 7.1 `scripts/tests/manifest-method-test.sh` (auto-wired, EB-9)

A self-provisioned test (per "Test infra is self-provisioned") using a `/tmp`
scratch clone of the pack repo so it never mutates the real tree or the real
manifest. Cases:

- **POSITIVE (input change → regen happens):** in the scratch clone, modify a
  `project-template/` file, commit it (unpushed), run `manifest-sync.sh` →
  assert exit 10 + `MANIFEST-CHANGED` + the on-disk manifest differs from the
  pre-run manifest.
- **POSITIVE (builder change → regen happens):** modify `test-fixtures/build.sh`
  in a way that does not change SHAs... (NOTE: a builder change that changes the
  commit message/content DOES change SHAs; use a real input change for the
  SHA-change assertion). Assert predicate matches `test-fixtures/build.sh`.
- **NEGATIVE (no input change → no-op):** commit a `maintenance-docs/` or
  `pack-ops/`-only file (non-input, EB-5), run `manifest-sync.sh` → assert exit 0
  + `MANIFEST-SKIP` + NO build.sh invocation (assert via a build.sh spy/timing or
  a sentinel) + manifest byte-unchanged.
- **NEGATIVE (comment-only input edit → NOOP):** edit a comment in an input file
  such that fixture SHAs are unchanged → assert exit 0 + `MANIFEST-NOOP` +
  manifest unchanged (rebuild ran but produced no diff).
- **IDEMPOTENCY:** run the tool twice on a current tree → both exit 0, manifest
  unchanged.
- **RANGE / commit-count-agnostic:** stage 1 input commit vs 3 input commits in
  the unpushed range → both yield exit 10 with the same final manifest;
  assert build.sh ran exactly ONCE in the 3-commit case (not 3×).
- **PREDICATE drift screen:** assert the input globs in `manifest-inputs`
  include `project-template/`, `scripts/` (minus tests), `test-fixtures/build.sh`,
  and the two named `supporting-docs/` files; assert they EXCLUDE `pack-ops/`
  and `maintenance-docs/`.

### 7.2 Check 62 coverage

- **STALE / MALFORMED → check RED:** a per-check test (per
  `check_ci_workflow_wires_per_check_tests`, validate-pack line 6553) that
  builds a malformed manifest (5 rows; or a garbage SHA; or wrong fixture name)
  in a scratch fixture and asserts Check 62 fails; and a well-formed manifest
  asserts Check 62 passes.
- **`build.sh --verify` stale → RED:** already covered by the existing fixture
  manifest-verify CI step + the determinism corroboration; the new test adds a
  scratch-clone case that hand-corrupts one manifest row and asserts
  `build.sh --verify` exits non-zero (proves the authoritative gate).

### 7.3 Enumerate-encoding-surfaces lock-step

Surfaces that ENCODE the behavior and MUST be updated/covered together: the tool
(`manifest-sync.sh`) + its test; Check 62 + its per-check test; the shared
`manifest-inputs` SoT (asserted by the predicate-drift test); the RC9 pointer
(trinity ×3 — trinity-parity validated by existing Check 16/18 trinity checks);
the rationale section + cache (cross-reference bijection per PACK-CHAT.md). The
coder updates all in lock-step; the reviewer verifies no asymmetric coverage.

### 7.4 Manifest regen for THIS BD's own commits

This BD touches `scripts/` (new tool + Check 62) → fixture inputs change
(`scripts/` is in the predicate). So this BD's own push MUST run
`manifest-sync.sh` and commit the regenerated manifest — a live first exercise
of the method. (Self-hosting: the BD that introduces the method also uses it.)
The coder/orchestrator must NOT hand-edit the manifest; run the tool.

---

## 8. Mechanical-apply plan (planner → coder; no open design decisions)

**Commit grouping (suggested; planner finalizes):**

- **C1 — the method + its test (pack-only).**
  - Create `scripts/manifest-sync.sh` per §2: input predicate (§2.3), range
    resolution (`@{upstream}..HEAD` with fallbacks), `git diff --name-only`
    union, membership test against `manifest-inputs`, `build.sh --all --clean`
    on match, diff-report, exit-code contract (§2.7). Tool NEVER commits/pushes.
  - (Optional) `scripts/lib/manifest-inputs.sh` shared SoT if Check 62 reuses it.
  - Create `scripts/tests/manifest-method-test.sh` per §7.1 (scratch-clone,
    self-provisioned, auto-wired by glob).
  - Run `manifest-sync.sh` at this BD's push; commit regenerated manifest.

- **C2 — Check 62 + per-check test (pack-only).**
  - Add `check_manifest_structural()` to `scripts/validate-pack.py`: row count
    == 6, names == `_fixture_names_from_build_sh()` (existing, line 6714), each
    value matches `^[0-9a-f]{40}$` (or documented sentinel). Register as Check 62
    (highest is 61, EB-7). Cheap: pure file-read + regex; reuse existing helpers.
  - Add the Check 62 per-check test per the wiring convention (Check 53/
    `check_ci_workflow_wires_per_check_tests`, line 6553).

- **C3 — RC9 prose removal/replacement (mixed: trinity coder + rationale coder;
  memory cache + PACK-CHAT.md propagation row).**
  - Trinity ×3 (`CLAUDE.md` 568-575, `AGENTS.md` 527-534, `GEMINI.md` 504-511):
    replace the per-commit bullet with the §4.2 pointer, lock-step (trinity rule).
  - `pack-ops/PACK-MEMORY-RATIONALE.md` 505-559: rewrite HOW-to-apply to the
    push-time tool + `build.sh --verify` + Check 62; KEEP the incident WHY; FIX
    the stale `pack-ops/HELP-FRAGMENT-TRACKER.md`-is-an-input claim (EB-5).
  - `pack-ops/PACK-CHAT.md` rows 433/435: update propagation row 6 + order note.
  - memory cache `feedback_manifest_regen_on_v11_surface.md`: Pack-Chat-direct
    revise.

**Concrete function/check names:**
- Tool: `scripts/manifest-sync.sh` (functions: `_resolve_push_range`,
  `_fixture_inputs_changed`, `_regen_manifest`, `main`).
- Check: `check_manifest_structural()` → Check 62; reuses
  `_fixture_names_from_build_sh()`, no new git calls beyond the existing
  range helpers.

**No open design decisions remain** — every fork in this doc is resolved with a
PICK (exact predicate; all-`scripts/`-minus-tests; Check 62 = structural screen;
`build.sh --verify` = authoritative SHA gate; amend-or-trailing-commit at
orchestrator discretion).

---

## 9. Design-elegance note (fewer files / fewer special cases)

- The correctness gate is REUSED, not rebuilt (`build.sh --verify` already
  exists and already runs on push). The only NEW machine surface is one cheap
  structural check (Check 62) + one tool.
- The predicate is a single declarative input set with a CI backstop, not a
  hand-maintained mirror of init-project.sh's copy sites — drift fails loud.
- The per-commit prose (an honor-system rule that produced 2 documented CI-red
  incidents) collapses to a one-line pointer at code. Net: fewer conventions,
  fewer wasted rebuilds, the authority in code.

---

## 10. BD anchoring — flag for the user (do NOT open)

The prompt anchors this as "BD-226-anchored work." **BD-226 is NOT a fit.**
BD-226 (read at `backlog/BD-226.md`, HEAD `1143267`) is titled "Sub-agent
worktree-isolation overhaul … in-worktree review/fix cycle, patch-only-after-
review-clean" — its entire scope is the AGENT-EXECUTION / worktree-placement
model (rules 1-9 about which tree each agent runs in, the SendMessage patch
handoff, worktree lifecycle). It has zero overlap with fixture-manifest
regeneration. Folding the manifest method into BD-226 would violate
`feedback-no-unfounded-logic-leaps` (two unrelated concepts) and muddy BD-226's
launch-gate scope.

**Recommendation:** this warrants its OWN BD (next integer — highest existing is
BD-227, so BD-228; re-verify the live `/backlog/` tree before assigning per the
BD-numbering rule). Title suggestion: "Push-time manifest regeneration method +
enforcing check; retire the per-commit RC9 prose obligation." Type: feat —
build/release tooling + CI check. Target: v11.0 (it removes an honor-system rule
that caused 2 CI-red incidents; small, self-contained, fits before launch).
**I am NOT opening it** — flagging for the user per the prompt's hard constraint.

---

## 11. Rules-Applied Verification Block

For each rule in the prompt's "Rules in force" block: (a) rule name; (b)
verification evidence (quoted command/path/count); (c) conclusion.

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | This pass ran only read-only git: `git rev-parse --short HEAD` → `1143267`; `git ls-files`, `git log`, `git diff --name-only` (inspection), `bash test-fixtures/build.sh --verify` (read-only verify, exit 0). No `git add/commit/push/tag/stash/checkout`/etc. was run. Only filesystem write = this design doc under `/tmp/handoff-bd226-manifest-method/`. Design explicitly states the tool "NEVER pushes and NEVER commits … only the orchestrator commits, with user approval" (§2.2, §2.5). | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op performed. Only write is the single caller-specified design doc. `bash test-fixtures/build.sh --verify` is read-only (compares SHAs; does not rebuild or write). No `rm`, no `git rm`, no overwrite of a tracked file. | COMPLIANT |
| 3 | **preflight-stop-means-stop** | No parent stop/halt message was received during this pass; design delivered complete. Had a stop arrived, I would have halted immediately and reported. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | Verified at STEP 0: `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (MAIN, not a `worktree-agent-*` path); `git rev-parse --abbrev-ref HEAD` → `v11-dev`; HEAD `1143267`. Did not read/touch/reason about the two live worktrees (analysis targets committed MAIN state only). | COMPLIANT |
| 5 | **empirical-evidence-blocks** | Every state-claim carries an Empirical-Evidence Block EB-1…EB-10 (§1), each with the actual command, verbatim output, HEAD-SHA `1143267`, interpretation, and SUPPORTED/PARTIAL conclusion. Examples: EB-2 (`build.sh --verify` exit 0 + `_verify()` body); EB-5 (`uniq -c` of `$PACK/<dir>` → `25 project-template / 7 scripts / 9 supporting-docs`, pack-ops zero copy sites). | COMPLIANT |
| 6 | **ci-guard-measure-then-bound** | Measured the actual fixture-input tree BEFORE bounding the predicate (EB-5/EB-6: input set = `project-template/` + `scripts/` + 2 named `supporting-docs/` files + `build.sh`; `pack-ops/` measured as NON-input). Sized the predicate EXACTLY to the measured input set (§2.3), not the broader v11-surface superset; the rejected superset's false-positive class is quantified from EB-4. Designed the CI backstop (`build.sh --verify`, input-set-agnostic) as the bound's safety net (§2.3b, §6.3). Verified the post-change model runs clean (§6 all paths RED on failure / GREEN on correct). | COMPLIANT |
| 7 | **ci-check-runtime-compounding** | New Check 62 is bounded to pure file-read + regex over `test-fixtures/manifest.txt` (6 rows) + reuse of existing `_fixture_names_from_build_sh()` (validate-pack line 6714); NO fixture rebuild, NO subprocess-per-entry, NO whole-real-tree scan (§3.2, §5 cost bound). Design explicitly prefers the EXISTING push-time `build.sh --verify` as the heavy authoritative gate (§3.1) and adds only the cheap screen — "prefer the existing push-time build.sh --verify if it already suffices" satisfied. | COMPLIANT |
| 8 | **dependency-direction-placement** | `scripts/manifest-sync.sh` justified pack-side: a pack-internal build/release tool, invoked by the orchestrator against the pack repo, never a runtime dependency of any project deliverable, no project surface invokes it; explicitly NOT added to install-map or `_SANCTIONED_PACK_SIDE_SHIPPED` (Check 47 sanctioned set stays `{scripts/lib/detect.sh, scripts/pack-help.sh}`) (§2.1). | COMPLIANT |
| 9 | **enumerate-encoding-surfaces** | §5 blast-radius table enumerates every surface (tool, optional shared SoT, build.sh=UNCHANGED, validate-pack Check 62, CI yml=UNCHANGED, RC9 trinity ×3, rationale, memory cache, PACK-CHAT.md row, both new tests, manifest regen) with category + size. §7.3 explicitly calls out the lock-step encoding surfaces (tool+test, check+per-check-test, shared SoT, RC9 pointer trinity-parity, rationale/cache bijection) so coverage is symmetric. | COMPLIANT |
| 10 | **rules-applied-verification-block** | This table. Each rule has a name + quoted evidence + COMPLIANT/N-A/VIOLATED conclusion; no empty-evidence cells. | COMPLIANT |
| 11 | **scope-deliverables-to-the-ask** | Doc delivers exactly the manifest method (A) + enforcing check (B) + RC9 removal + blast radius + test plan + CI-safety proof + mechanical-apply plan + BD-anchoring flag — the 7 success criteria. No tangential sprawl; no SUSPECTED/edge-case coverage padding; the one out-of-band finding (RC9's stale `pack-ops/HELP-FRAGMENT-TRACKER.md` input claim) is surfaced because it is load-bearing for the predicate, not as noise. | COMPLIANT |

---

**End of design.**
