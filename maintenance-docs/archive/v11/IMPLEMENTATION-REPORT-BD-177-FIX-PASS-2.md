# IMPLEMENTATION-REPORT — BD-177 fix-pass-2 (CI recovery via source-direct test 2.2.c)

- **Branch:** `v11-dev`
- **HEAD at PREFLIGHT:** `43117dcc8aa06187f5e815661042488ec72904e4`
- **Scope:** CI recovery for `scripts/tests/pack-help-test.sh::test 2.2.c` (Option F2 — source-direct).
- **Pack-coder session:** background spawn from Pack Chat.

---

## §1 Summary

BD-177 fix-pass commit `43117dc` added four new tests (2.2.a/b/c/d) to
`scripts/tests/pack-help-test.sh` for dual-surface regression coverage on
`scripts/pack-help.sh`'s `emit_fragment()` substitution. Test 2.2.c was the
only one of the four with a build-order dependency: it asserted the
no-sentinel-leak / body-inlined contract against the pre-built
`test-fixtures/v11-flat-file/docs/pack/HELP-FRAGMENT*.md` artifact. Locally
that fixture is built by `bash test-fixtures/build.sh --all --clean` as
part of the standard dev loop, so 2.2.c PASSed on the author's machine.
On the CI runner, however, `pack-help-test.sh` runs before any fixture
build step, so the directory was absent and 2.2.c failed with
`FAIL 2.2.c v11-flat-file fixture missing`.

Per user-approved Option F2, fix-pass-2 refactors test 2.2.c to read the
**source-of-truth client sentinel files** at
`project-template/docs/pack/HELP-FRAGMENT.md` and
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` directly, invoking
`pack-help.sh --root "$REPO_ROOT/project-template" --surface client`.
This removes the build-order coupling entirely. The semantic equivalence
holds because `HELP-FRAGMENT*.md` are plain markdown files that the
install pipeline copies verbatim into client trees (no install-time
transform touches them) — so for the dual-surface regression class
BD-177 introduced, source-of-truth content and as-installed client content
are byte-identical. Install-pipeline corruption (a different bug class) is
already covered by the three persona contracts; adding fixture
self-provisioning to the test (Option F1) would have duplicated that
coverage while reintroducing the build-infra coupling that breaks on
fixture-name or build-script changes.

CI is now green: `pack-help-test.sh` reports 21/21 PASS with the
`test-fixtures/v11-flat-file/` directory temporarily moved out of the
tree (simulating CI runner state), and the regression-reproducer sanity
check confirms test 2.2.c still catches the original BD-177 regression
class (broken `pack-ops/`-only regex → 2.2.a/b/c all FAIL; correct
broadened regex → all PASS).

---

## §2 Files changed

| File | Change type | Lines (insert / delete) | Why |
|---|---|---|---|
| `scripts/tests/pack-help-test.sh` | modified | +21 / -21 | Refactor test 2.2.c body + comment from `test-fixtures/v11-flat-file`-dependent to source-direct (`project-template/docs/pack/`); zero net line change. |

No other files in scope were touched. `scripts/pack-help.sh` is
unchanged (BD-177 fix-pass already correctly broadened the regex; this is
a test-only fix). Source sentinels
(`project-template/docs/pack/HELP-FRAGMENT.md`,
`pack-ops/HELP-FRAGMENT-PACK.md`) are unchanged. Tests 2.2.a, 2.2.b, 2.2.d
are unchanged.

`test-fixtures/manifest.txt` was regenerated per RC9 (scripts/ touched)
and shows zero diff — the test-only edit is not a v11-surface install
artifact, so v11-* fixture row SHAs do not drift.

---

## §3 Test 2.2.c refactor — chosen implementation approach + rationale

### Chosen approach

**Source-direct invocation against `project-template/docs/pack/`.**
The new test 2.2.c body invokes:

```
bash "$REPO_ROOT/scripts/pack-help.sh" \
     --root "$REPO_ROOT/project-template" --surface client
```

and asserts the same dual-form no-sentinel-leak contract as before
(matches both `[Included from `HELP-FRAGMENT-TRACKER.md`` and
`[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md``).

### Rationale (vs the three options in the prompt)

- **Option (a) — temp dir with copies.** This is the shape already used
  by tests 2.2 / 2.2.a / 2.2.b (see L123-130: `mktemp` → `mkdir
  docs/pack` → `cp project-template/docs/pack/HELP-FRAGMENT*.md`). If
  2.2.c were rewritten to this shape, it would become structurally
  identical to 2.2.a — the no-sentinel-leak assertion against the same
  source-of-truth files in the same `mktemp/cp` setup. The original
  2.2.c intent was specifically to lock in the regression on a **second,
  differentiable** rendering surface — losing that differentiation would
  reduce 2.2.c to a redundant duplicate.
- **Option (b) — explicit mode reading from
  `project-template/docs/pack/HELP-FRAGMENT.md`.** This is what
  `pack-help.sh --root <path> --surface client` already does: the
  `client` branch (`pack-help.sh:140-143`) reads `$root/docs/pack/
  HELP-FRAGMENT.md` and `$root/docs/pack/HELP-FRAGMENT-TRACKER.md`
  directly. Pointing `--root` at the in-tree `project-template/`
  directory gets us the exact source-of-truth content with zero
  filesystem prep. **This is the chosen approach.**
- **Option (c) — extract the `awk` machinery and invoke it
  standalone.** Most decoupled but breaks the integration-test contract:
  the test would no longer exercise the surface-detection +
  fragment-resolution + substitution pipeline end-to-end, only the awk
  step in isolation. Future regex changes to the awk pattern would still
  trip the test, but a regression in (for example) the
  `_pack_fragment_path` / `emit_fragment` call-graph wiring would not.
  Rejected as too narrow.

### Why source-direct (Option b variant) is semantically equivalent to fixture-direct

The BD-177 regression class is **regex-narrowing in `emit_fragment()`'s
`awk` pattern silently dropping the client-side sentinel form** —
specifically, a regex that matches only `pack-ops/HELP-FRAGMENT-TRACKER.md`
fails to match the bare-filename client-side sentinel
`HELP-FRAGMENT-TRACKER.md` (no path prefix), so client-side rendering
emits the literal sentinel line into user-visible output instead of the
tracker-fragment body.

The content the `awk` pattern sees is identical whether it reads
`project-template/docs/pack/HELP-FRAGMENT.md` (source-of-truth) or
`test-fixtures/v11-flat-file/docs/pack/HELP-FRAGMENT.md` (as-built
fixture) — both files are byte-identical because the install pipeline
copies HELP-FRAGMENT*.md verbatim from `project-template/docs/pack/` to
the client tree (no `sed`, no `awk`, no merge-helper transform touches
these files; they are plain markdown end-user content). The
test-fixtures build step is effectively a `cp -r` for these files. So
the regression-class signal is preserved exactly.

The byte-identity claim is structural, not just observational: it
follows from the fact that there is no install-pipeline code path that
mutates HELP-FRAGMENT*.md content. The regression class this test
guards (`awk` pattern narrowing in `emit_fragment()`) is sensitive only
to the sentinel-line content of the fragment file passed in — not to
its source path, not to any install metadata, not to any container
directory structure. Other bug classes (install-pipeline corruption,
install-time copy failures, post-install permission damage, etc.) are
covered by the three persona contracts (greenfield 191/191, mid-dev
25/25, migration 37/37) — not by `pack-help-test.sh`.

### Implementation diff (exact)

The 21-line test block was replaced by an equivalent 21-line block. The
shape change:

- **Before:** wrap the assertion in an `if -d ... -f ... -f ...; then
  ... ; else t_fail "fixture missing"; fi` guard against the
  `test-fixtures/v11-flat-file` directory.
- **After:** unconditional invocation against
  `"$REPO_ROOT/project-template"` (which exists in any pack-repo
  checkout by definition). No guard needed — pack-repo invariant
  guarantees `project-template/docs/pack/HELP-FRAGMENT.md` is present;
  if it isn't, every other pack-help-test.sh test (2.2.a/b copies the
  same source files into a `mktemp` dir) would fail first with a more
  diagnostic error.

The comment block was updated to:

1. Name the new source path
   (`project-template/docs/pack/`).
2. Explain the byte-identity argument (`HELP-FRAGMENT*.md are plain
   markdown; no install transform touches them, so source-of-truth
   content is byte-identical to as-installed client content for the
   regression class this test guards`).
3. Differentiate 2.2.c from 2.2 / 2.2.a / 2.2.b (`complements 2.2/
   2.2.a/2.2.b ... 2.2.c locks in the regression by invoking
   pack-help.sh directly against the source-of-truth tree`).
4. Document the fix-pass-2 motivation (`replaced the prior
   test-fixtures/v11-flat-file dependency, which failed on CI runners
   where the fixture wasn't pre-built`).

---

## §4 Tests 2.2.a / 2.2.b / 2.2.d audit

| Test | Surface tested | Setup mechanism | Fixture dep? | Action |
|---|---|---|---|---|
| 2.2.a | Client-side rendering, sentinel-leak negative assertion | `mktemp` + `cp project-template/docs/pack/HELP-FRAGMENT*.md` (L123-130) | None — uses source-of-truth via `cp` into temp tree | No change |
| 2.2.b | Client-side rendering, tracker-body positive assertion | Same `$TR_CLI2` temp tree (L123-130, shared with 2.2.a) | None — same source-of-truth `cp` | No change |
| 2.2.d | Pack-side rendering on real pack-ops fragments | Invokes `pack-help.sh --root "$REPO_ROOT" --surface pack` (L183) | None — uses real `pack-ops/HELP-FRAGMENT-*.md` at pack-repo root | No change |

None of 2.2.a / 2.2.b / 2.2.d had a `test-fixtures/v11-flat-file/`
dependency. Only 2.2.c required the fixture, and only 2.2.c is touched
by fix-pass-2.

---

## §5 Fixture-absence verification (CI-runner simulation)

To simulate the CI runner state where `test-fixtures/v11-flat-file/`
has not been built, the directory was temporarily moved to
`/tmp/bd177-fix-pass-2-stash/v11-flat-file`, the test suite was run,
and the fixture was restored after. Result:

```
$ mkdir -p /tmp/bd177-fix-pass-2-stash
$ mv test-fixtures/v11-flat-file /tmp/bd177-fix-pass-2-stash/v11-flat-file
$ ls test-fixtures/v11-flat-file
ls: test-fixtures/v11-flat-file: No such file or directory
$ bash scripts/tests/pack-help-test.sh 2>&1 | tail -5
=== Summary ===
Passed: 21
Failed: 0
All tests passed.
$ mv /tmp/bd177-fix-pass-2-stash/v11-flat-file test-fixtures/v11-flat-file
$ ls test-fixtures/v11-flat-file/docs/pack/HELP-FRAGMENT*.md
test-fixtures/v11-flat-file/docs/pack/HELP-FRAGMENT-TRACKER.md
test-fixtures/v11-flat-file/docs/pack/HELP-FRAGMENT.md
```

21/21 PASS with fixture absent — CI recovery confirmed. Fixture
restored after test.

---

## §6 Reproduce-the-original-regression sanity check

To confirm test 2.2.c still catches the BD-177 regression class, the
`emit_fragment()` regex in `scripts/pack-help.sh` was temporarily
narrowed back to the broken `pack-ops/`-only form
(`/^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/` — no
optional group). The test suite was re-run, then the correct
broadened regex was restored. Result:

```
$ cp scripts/pack-help.sh scripts/pack-help.sh.bak
$ sed -i '' 's|/^\\\[Included from `(pack-ops\\/)?HELP-FRAGMENT-TRACKER\\.md`/|/^\\[Included from `pack-ops\\/HELP-FRAGMENT-TRACKER\\.md`/|' scripts/pack-help.sh
$ grep -n "Included from" scripts/pack-help.sh | head -5
87:    #       sentinel = `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`
90:    #       `[Included from \`HELP-FRAGMENT-TRACKER.md\` ...]`
97:        /^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/ {
$ bash scripts/tests/pack-help-test.sh 2>&1 | grep -E "(PASS|FAIL).*(2\.2\.a|2\.2\.b|2\.2\.c|2\.2\.d)"
  FAIL 2.2.a sentinel leaked — sentinel string survived substitution
  FAIL 2.2.b client tracker body — tracker-fragment body content missing post-substitution
  FAIL 2.2.c sentinel leaked on source-of-truth client fragments — BD-177 regression — client-side substitution silently failed
  PASS 2.2.d no sentinel leak on pack-repo pack-side surface
$ mv scripts/pack-help.sh.bak scripts/pack-help.sh
$ bash scripts/tests/pack-help-test.sh 2>&1 | tail -5
=== Summary ===
Passed: 21
Failed: 0
All tests passed.
```

With the broken regex, **all three client-side guards FAIL** (2.2.a,
2.2.b, 2.2.c) and the pack-side guard PASSes (2.2.d) — exactly the
asymmetric signal that BD-177's reviewer originally surfaced. With
the correct regex restored, all 21 tests PASS. Test 2.2.c is
verified to lock in the regression class on the source-of-truth
client surface.

---

## §7 `pack-help-test.sh` full output (post-edit, fixture-present)

```
=== Group 1: detect_pack_surface ===
  PASS 1.1 pack repo → pack-surface: pack
  PASS 1.2 client repo (docs/project/) → pack-surface: client
  PASS 1.3 client repo (root BACKLOG.md, TD entries) → client
  PASS 1.4 mixed BD + TD → ambiguous
  PASS 1.5 no BACKLOG.md → ambiguous

=== Group 2: pack-help.sh end-to-end ===
  PASS 2.1 pack-side header present
  PASS 2.1 pack commands section present
  PASS 2.1 tracker section inlined
  PASS 2.1 colloquial mapping inlined
  PASS 2.1 placeholder line replaced
  PASS 2.2 client-side header present
  PASS 2.2 client tracker section inlined
  PASS 2.2 client-only verb (agent-run) listed
  PASS 2.2.a no sentinel leak in rendered client-side output
  PASS 2.2.b client tracker-fragment body content inlined
  PASS 2.2.c no sentinel leak on source-of-truth client fragments
  PASS 2.2.d no sentinel leak on pack-repo pack-side surface
  PASS 2.3 --surface pack override prints pack fragment
  PASS 2.4 missing fragments → helpful stderr
  PASS 2.5 inline preserves surrounding lines + replaces placeholder
  PASS 2.6 unknown flag → typed error

=== Summary ===
Passed: 21
Failed: 0
All tests passed.
```

21/21 PASS.

---

## §8 `validate-pack.py` + 3 persona contract results

### `python3 scripts/validate-pack.py` (tail)

```
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean
```

All 39 checks PASS.

### Persona contracts

```
$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -3
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -3
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -3
=== migration contract: 37 passed, 0 failed ===
```

All three contracts GREEN: 191/191 greenfield, 25/25 mid-dev,
37/37 migration.

---

## §9 Manifest regen evidence

```
$ bash test-fixtures/build.sh --all --clean 2>&1 | tail -5
  built: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/existing-project-mid-dev
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
(empty — zero diff)

$ git diff test-fixtures/manifest.txt
(empty — zero diff)
```

Zero diff is the expected outcome. The edit is to test code only
(`scripts/tests/pack-help-test.sh`) which is not part of the
v11-surface install artifact set — `scripts/tests/` is pack-repo-only
infrastructure that never gets installed into client trees. The
v11-* fixture rows reflect installed client content; they correctly
remain unchanged. RC9 was followed (regen ran because `scripts/` was
touched), and the empty-diff outcome is the canonical authority that
no manifest staging is needed.

---

## §10 PREFLIGHT line

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD 43117dcc8aa06187f5e815661042488ec72904e4; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md
```

---

## Definition-of-Done checklist

- [x] Test 2.2.c no longer requires `test-fixtures/v11-flat-file/` to be pre-built (verified by `mv` → run → restore; 21/21 PASS with fixture absent)
- [x] All other tests in `pack-help-test.sh` STILL PASS (no regression in 2.2.a/b/d or any other test — 21/21 PASS in both fixture-present and fixture-absent runs)
- [x] `bash scripts/tests/pack-help-test.sh` reports 21/21 PASS
- [x] Reproduce-the-original-regression sanity check: broken regex → 2.2.a/b/c FAIL, 2.2.d PASS; correct regex → all PASS
- [x] `python3 scripts/validate-pack.py` exit 0 — all 39 checks PASS
- [x] 3 persona contracts STILL GREEN (greenfield 191, mid-dev 25, migration 37)
- [x] `test-fixtures/manifest.txt` regenerated; zero diff (expected for test-only edit)
- [x] Working tree at PREFLIGHT: exactly 1 modified file (`scripts/tests/pack-help-test.sh`) + this IMPL-REPORT (untracked `PACK-REVIEW-BD-178.md` pre-dated this session and was not touched)
- [x] No state-changing git verbs run
- [x] PREFLIGHT line emitted before IMPL-REPORT write

---

## Plan deviations

None. Implementation follows the user-approved Option F2 (source-direct)
exactly. Chose Option (b) variant from the three implementation shapes
the prompt listed (rationale in §3) — that selection was explicitly
delegated to the implementer ("Pick whichever shape gives clean test
code + robust regression coverage + zero fixture dependency").

## New POQs introduced

None.

## Out-of-scope items surfaced (not touched, per prompt instruction)

None to report — audit of tests 2.2.a / 2.2.b / 2.2.d (§4) found no
similar fixture dependencies. The remaining tests in
`pack-help-test.sh` (1.1-1.5, 2.1, 2.2 base, 2.3, 2.4, 2.5, 2.6) use
either `mktemp` synthetic trees, the real pack-repo tree, or
in-test-defined fragment content — none have a
`test-fixtures/v11-flat-file/`-style build-order dependency.
