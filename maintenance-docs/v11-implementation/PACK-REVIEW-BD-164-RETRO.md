---
title: PACK-REVIEW-BD-164-RETRO
author: pack-reviewer (v11-dev, retroactive per-BD review)
scope: BD-164 (Batch 19 commit 19a) — per-entry split helper foundation
inputs-consulted:
  - maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.1
  - maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (sidecar parent)
  - maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md (sidecar addendum)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §4.2 / §7.5 / §10 / §13.3 / §18
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md §1 / §3 / §5 / §6 / §10
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md §1 / §2 / §3 / §4 / §6
  - maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164.md
  - scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh
  - scripts/tests/test-per-entry.sh (executed locally — 57/57 PASS confirmed)
  - .github/workflows/validate-pack.yml
  - scripts/lib/migrator-core.sh (EXIT_GATE_FAILED context)
  - BACKLOG.md BD-164 entry
authority-precedence: Addendum #2 > Addendum #1 > integration parent > sidecar parent (per plan §1.3 + Addendum #2 §0.4)
date: 2026-05-16
---

# Pack review — BD-164 (retro)

## §1 — Summary

BD-164 delivers the five-file per-entry helper foundation (`scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh` + `scripts/tests/test-per-entry.sh`) and the helpers honor the load-bearing architect-doc bindings: line-1 HTML-comment back-pointer per Addendum #2 §2 (NO body field), `_rules.md` runtime-read scoped to supporting-file basename list per integration parent §7.5, hard-coded entry regex / state vocab / grammar field labels, deterministic + idempotent mirror generator per sidecar §6.2, divergence-warning routing split between interactive prompt / `PE_FORCE_OVERWRITE_MIRROR` force / `_MIGRATOR_MODE`-aware non-interactive paths. Test suite is comprehensive (11 groups, 57/57 PASS) and bash-3.2 compatible.

**Verdict:** correctness baseline solid; one MUST-fix (test runner not wired into CI — a delivered test that never runs in pack CI is a known gap per Batch 21c "test-not-in-CI" heuristic and per plan §5.1 verification gate intent), three SHOULD-fix (regex inconsistency across siblings, fragile temp-file rename atomicity in `pe_ensure_backpointer`, project-changelog `id_extract` can produce a filename that won't match the entry regex), and several NITs.

## §2 — Findings

### MUST findings

**M1 — `scripts/tests/test-per-entry.sh` is NOT wired into `.github/workflows/validate-pack.yml`.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/workflows/validate-pack.yml`

The workflow currently runs 28 enumerated `scripts/tests/*.sh` and `scripts/test-*.sh` test runners (lines 117–238 of the workflow). `test-per-entry.sh` is not among them. Grep confirms:

```
$ grep -n "test-per-entry" .github/workflows/validate-pack.yml
NOT WIRED IN CI
```

Plan §5.1 verification gate names "New `scripts/tests/test-per-entry.sh` PASSES (all test cases per integration parent §18.2 #1)" as a gate for the BD-164 commit — but the only mechanism that enforces "PASSES on every push" is CI. Without CI wiring, a future refactor of the helpers (BD-165 / BD-166 / BD-167 / BD-168 will all source the helpers; Batch 23 dog-food fires the migrator-decompose path that exercises them end-to-end) can silently regress the 57 invariants this test asserts.

The workflow file ALSO references `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` at line 156 — a test that does NOT exist yet (it lands in BD-168). So the workflow is already being extended for Batch 19; the omission of `test-per-entry.sh` is asymmetric.

The integration parent §18.2 #1 names BD-164's test cases as a coder-pass deliverable; §10.1 / §10.2 / §10.3 / §18.2 #6 wires BD-168's checks into CI via `test-validate-pack-checks-32-33-34.sh`. The BD-164 helpers underpin all three of those checks (Check 32 calls the mirror generator; Check 33 calls the TOC regenerator; the helpers' contract is what the checks validate against). A regression in the BD-164 helpers that survives review surfaces only at Batch 23 dog-food — far too late.

**Fix:** add a `test-per-entry (BD-164)` step to `.github/workflows/validate-pack.yml` in the `tests:` job alongside the other `scripts/tests/*.sh` runners. Sample shape mirroring the existing lines 117–192:

```yaml
      - name: test-per-entry (BD-164)
        run: bash scripts/tests/test-per-entry.sh
```

Land it in this commit's working tree so the gate fires on first push.

---

### SHOULD findings

**S1 — pack-changelog entry-regex inconsistency across `_lib.sh` / `decompose.sh` / `toc-regenerate.sh`.**
Files:
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh:77`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/decompose.sh:114-115`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/toc-regenerate.sh:85`

The three helpers carry three subtly different regex forms for the pack-changelog version suffix:

- `_lib.sh:77`  — `'^v[0-9]+\.[0-9]+(-[a-z0-9-]+)?\.md$'` (lowercase + hyphen, suffix REQUIRES a leading hyphen)
- `toc-regenerate.sh:85` — `r"^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$"` (matches `_lib.sh` shape)
- `decompose.sh:114-115` — `r"^### (v\d+\.\d+(?:[-A-Za-z0-9]+)?)\b"` (BROADER: mixed case via `A-Za-z`, suffix character class admits any of `[-A-Za-z0-9]` — no leading-hyphen requirement)

Three concrete divergences:
1. `decompose.sh` admits mixed-case suffix (e.g. `v11.0-RC1`); the other two reject it.
2. `decompose.sh`'s suffix character class does not require a leading hyphen — `### v11.0post-release` would be parsed as `v11.0post-release`, but the same content saved as `v11.0post-release.md` would FAIL `_lib.sh`'s regex and be invisible to `pe_list_entry_files`.
3. Sidecar §3.2 line 302 names `v10.0-post-release` as the established pack convention (lowercase, hyphen-prefixed); decompose.sh's broader regex is unnecessarily permissive given that convention.

Integration parent §7.5 explicitly names the entry regex as "hard-coded… because the regex is part of the v10 grammar and changes trip V3.1-DELTA §3 A2." Three different shapes for the same grammar invariant violate the §7.5 intent — `_lib.sh` is canonical (it is the value returned by `pe_entry_regex_for_stream`), and the sibling files should mirror it exactly.

**Fix:** harmonize all three patterns to the canonical shape `^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$` (or its anchor variant `^### (v\d+\.\d+(?:-[a-z0-9-]+)?) — ` for decompose). Concretely:

- In `decompose.sh:114-115`, change `(?:[-A-Za-z0-9]+)?` to `(?:-[a-z0-9-]+)?` and add a trailing ` — ` if you also want to anchor on the dash-em-dash separator (current `\b` boundary is loose).

The `toc-regenerate.sh:139` regex `^### (v\d+\.\d+(?:-[a-z0-9-]+)?) — (.+)$` is already consistent with `_lib.sh` — only `decompose.sh` is divergent.

**S2 — `pe_ensure_backpointer` writes its temp file in TMPDIR, not the destination directory, breaking atomic-rename guarantee.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh:319-337`

```
333:    tmp=$(mktemp -t per-entry-bp.XXXXXX) || return 1
334:    printf '%s\n' "$bp" >"$tmp"
335:    cat "$path" >>"$tmp"
336:    mv "$tmp" "$path"
```

`mktemp -t` creates the temp file under `$TMPDIR` (typically `/tmp` or `/var/folders/...` on macOS). `mv "$tmp" "$path"` is then a cross-filesystem move when `$path` lives outside TMPDIR (the common case — `/Users/david/.../backlog/BD-100.md`). POSIX `mv` across filesystems is implemented as `copy + unlink`, NOT atomic rename — readers can see partial state and a power loss / signal can leave both files present or the destination missing.

`pe_write_atomic` already shows the correct pattern (line 363): `tmp=$(mktemp "$dir/.per-entry.XXXXXX")` creates the temp in the same directory as the destination, guaranteeing same-filesystem rename. The integration parent §4.2 Layer 2 says decompose ADDS the back-pointer "idempotently" — atomicity is required for the idempotency guarantee to hold under concurrent reads.

Note: `decompose.sh:235-238` independently writes per-entry files atomically via `os.replace(tmp_path, out_path)` where `tmp_path = out_path + ".per-entry-tmp"` (same directory) — so the BD-164 decompose path is already safe. The `pe_ensure_backpointer` helper is the unsafe shim; it isn't called by any of the BD-164 shipped helpers, but it is a published public API per `_lib.sh:26-37` and will be reached by BD-165/166/167 downstream code that wants to "add a back-pointer to an existing per-entry file."

**Fix:** change line 333 to follow the `pe_write_atomic` pattern. Same-directory mktemp:

```bash
local dir
dir=$(dirname "$path")
tmp=$(mktemp "$dir/.per-entry-bp.XXXXXX") || return 1
```

Optionally also align the temp-file naming with the existing `.per-entry.XXXXXX` convention used in `pe_write_atomic` / `per_entry_regenerate_mirror` for grep-ability of stale temp files.

**S3 — `project-changelog` `id_extract` can return an ID whose filename fails the stream's own entry regex.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/decompose.sh:131-145`

The decompose path for `project-changelog` produces a filename `<id>.md` where `id` comes from `id_extract(line)`. For an H3 anchor of bare form `### 2026-05-15` (no phase, no slug), the code returns `date` (line 144) — yielding a filename like `2026-05-15.md`. But the canonical regex in `_lib.sh:101` is `'^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$'` which REQUIRES a `-<something>` suffix after the date.

Consequence: an entry written under that bare-date branch survives decompose but is invisible to `pe_list_entry_files` (because that helper filters by the entry regex per `_lib.sh:407`), to `pe_supporting_files_admitted` filtering, to TOC regeneration (which compiles the same regex at `toc-regenerate.sh:88`), and to Check 32's "regenerate mirror" path — the entry vanishes from the regenerated mirror, which IS the source-of-truth divergence Goal 2 is supposed to prevent.

Sidecar §3.5 + §5.1 do not require a slug for project-changelog entries (the OT convention typically carries a slug, but the design does not lock it). The decompose helper's fall-back is consistent with that flexibility — but the stream's own entry regex contradicts it.

**Fix (pick one):**
- Tighten the decompose `id_extract` so the bare-date fall-back returns `f"{date}-untitled"` (or some sentinel-suffix that satisfies the regex), AND add a `pe_warn` so the operator sees the renaming.
- Loosen `_lib.sh:101` regex to `'^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$'` (optional suffix) AND match in `toc-regenerate.sh:88`.

Either choice eliminates the gap. The first is more conservative (preserves the convention); the second is more permissive (matches the decompose contract as currently coded). Whichever is picked, all three regex sites in `_lib.sh`, `decompose.sh`, `toc-regenerate.sh` must be aligned per finding S1.

**S4 — `pe_strip_backpointer_stdin` and `pe_first_line_is_backpointer` reject back-pointer lines with trailing whitespace.**
Files: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh:305-314, 291-300, 325-328`

The awk regex in `pe_strip_backpointer_stdin` requires the line to end exactly at `-->`:

```
308:            if ($0 ~ /^<!-- per-entry source: .*; contract: .* -->$/) {
```

The case-glob in `pe_first_line_is_backpointer` and `pe_ensure_backpointer` is equally strict (the pattern must consume the whole string). Verified locally: a back-pointer line with one trailing space passes through unchanged (not stripped), and `pe_first_line_is_backpointer` returns 1 on it.

Editor auto-fix-on-save settings sometimes inject trailing whitespace on edit; if a downstream contributor accidentally hand-edits a per-entry file's back-pointer line and triggers trailing-whitespace insertion, the mirror generator will emit the back-pointer into the regenerated mirror (because `pe_strip_backpointer_stdin` no longer recognizes it as a back-pointer). The mirror then differs from the architect-doc-bound shape (integration parent §4.2 says back-pointer is stripped at emit).

This is brittle but consistent (strip and detect agree). It is SHOULD-level rather than MUST because (a) hand-edits to back-pointer lines are unusual, (b) the layered defenses per Addendum #1 §5 catch divergence via Check 32 at CI time. But the cost of a relaxed regex is one extra `\s*$` and the consistency-improvement is non-trivial.

**Fix:** relax the regex on line 308 to tolerate trailing whitespace:

```awk
if ($0 ~ /^<!-- per-entry source: .*; contract: .* -->[ \t]*$/) {
```

And update both case-glob patterns (`_lib.sh:295` and `_lib.sh:326`) to use awk/grep instead — case-glob cannot express trailing-whitespace-optional cleanly. Or, equivalently, normalize-then-check: pipe `head -n 1` through a `sed 's/[ \t]*$//'` before the case-glob comparison.

---

### NIT findings

**N1 — Stale "BSD-grep ERE" claim in `_lib.sh:53` / `_lib.sh:406` while the regex is consumed by Python `re.compile` in two of three helpers.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh:53, 406`

The header comment says "Position 2: entry-file regex (BSD-grep ERE; matched against basename)" and `pe_list_entry_files` uses `grep -E -q "$regex"` (so BSD-grep ERE is accurate there). But `decompose.sh:106-146` and `toc-regenerate.sh:83-89` compile the SAME regex strings into Python `re.compile` patterns. Python's regex engine accepts the BSD-grep ERE subset, but the doc claim is incomplete.

**Fix:** rewrite the comment as "regex is a portable extended-regex subset accepted by both BSD `grep -E` and Python `re.compile`; see `pe_list_entry_files` for the BSD-grep use site and decompose.sh / toc-regenerate.sh for the Python use sites."

**N2 — `pe_supporting_files_known_for_stream` and `pe_supporting_files_effective` use single-string concatenation with embedded spaces as the "list" return shape; consumers iterate via word-split (`for item in $list`).**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh:225-248`

Bash 3.2 has no proper "return an array" idiom, so the design is forced. The code handles this correctly. But the lack of any defensive `IFS=` reset in callers (`pe__effective_contains` walks `case " $effective " in *" $needle "*` which is robust to whitespace, good) and the lack of a `pe_supporting_files_as_lines` accessor (one-per-line for downstream `while read` loops) means future BD-167 / BD-168 work that wants to print the effective list will have to reinvent the line-split.

**Fix (optional):** add a one-line helper `pe_supporting_files_lines <key> <stream_dir>` that does `pe_supporting_files_effective "$@" | tr ' ' '\n'`. Low-stakes ergonomic addition; can be deferred to whichever downstream BD first needs it.

**N3 — `decompose.sh` Python heredoc uses `os.environ[...]` for four PE_DECOMPOSE_* vars without a fallback, but the bash dispatcher always sets them. Belt-and-braces fine; explicit `EnvironmentError` on the Python side would aid debug if a future refactor breaks the dispatch contract.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/decompose.sh:66-69`

```python
key = os.environ["PE_DECOMPOSE_KEY"]
mono_path = os.environ["PE_DECOMPOSE_MONO"]
stream_dir = os.environ["PE_DECOMPOSE_DIR"]
entry_regex = os.environ["PE_DECOMPOSE_REGEX"]
```

If any var is missing, Python raises `KeyError: 'PE_DECOMPOSE_KEY'` with no `pe_die`-style framing. The bash side wraps the whole dispatch with `|| pe_die ...` so the user sees "per_entry_decompose: python parser failed" — but the KeyError trace goes to stderr separately, which can be confusing.

**Fix:** wrap each `os.environ[…]` access in a `try/except KeyError` that prints a single `per-entry decompose: missing env var …` to stderr and `sys.exit(2)`. Same trace, clearer framing.

**N4 — TOC regenerator's `entry_sort_key` for `project-changelog` (descending-by-filename via `-ord(c)` tuple) is correct but obfuscated.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/toc-regenerate.sh:241-244`

```python
if key == "project-changelog":
    # Descending date (lex sort of inverted strings).
    return tuple(-ord(c) for c in filename)
```

This works because Python's tuple comparison is lexicographic and negating per-char ord values inverts the order. But it's non-obvious and would benefit from a one-line comment naming the technique, or a simpler `reverse=True` on the outer `items.sort` call (which it already does NOT use; the sort at line 260 uses `key=` not `reverse=`).

**Fix:** replace with `return tuple(filename)` and let the caller use `items.sort(key=…, reverse=True)` for project-changelog. Or add a one-line comment: "# negate-ord trick: lex-compares as descending date".

**N5 — Implementation report claim "57 test cases" matches the actual count, but the report at §5 names "all integration-parent §18.2 #1 cases" as the gate; §18.2 #1 enumerates 4 specific scenarios (round-trip, empty-tree, supporting-file admission, cross-reference resolution). The first 3 are covered (groups 3 / 6 / 7); the fourth ("cross-reference resolution: Check 34 detects `Blockers: BD-999` when BD-999 has no entry file") is correctly scoped to BD-168 (Check 34 is the validator's responsibility, not the helper library's), but the report could be more explicit that #1's 4th case is out-of-scope for BD-164 by design.**
File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164.md:5, 138`

Not a defect; clarity nit.

**Fix:** in §5 of the impl report (the verification table), the row "Round-trip identity (decompose → regenerate yields byte-identical mirror)" is followed by other rows but does not explicitly call out that §18.2 #1's "cross-reference resolution" case ships in BD-168. A line under §6 ("Out-of-scope items") naming this would close the loop.

**N6 — Comment in `_lib.sh:7-9` refers to `_rules.md` runtime read happening "per integration parent §7.5" but more recent guidance is in Addendum #2 §1.4 (Codex `.toml` correction unrelated, but the addenda-supersede-parent ordering applies elsewhere too).**

Minor. The §7.5 reference is correct for the runtime-read scope split (Addenda do not modify §7.5).

---

## §3 — Verification

Commands run (read-only):

1. `wc -l` on the five BD-164 source files — line counts match the report:
   - `_lib.sh` 419, `decompose.sh` 280, `mirror-generate.sh` 331 (NOT 276 — BD-165 added the 54-line mode-aware case block; flagged as expected per prompt context), `toc-regenerate.sh` 285, `test-per-entry.sh` 610.
2. `bash scripts/tests/test-per-entry.sh` — `57 / 57 PASS`. Confirms the report's claim and the contract correctness for all 11 groups.
3. `grep -nE 'readarray|mapfile|<<<|&>|associative|declare -A' scripts/lib/per-entry/*.sh scripts/tests/test-per-entry.sh` — zero hits in the helpers; one mention of "readarray" in a comment about WHY it's not used. Bash 3.2 compatibility holds.
4. `grep -n 'test-per-entry' .github/workflows/validate-pack.yml` — **no hits** (M1 confirmed).
5. `grep -nE "\.backlog|\.changelog" scripts/lib/per-entry/*.sh` — zero stale leading-dot references; Addendum #1 §10 path-cascade respected.
6. `grep -n 'stream-discovery' scripts/lib/per-entry/*.sh scripts/tests/test-per-entry.sh maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164.md` — zero references; Addendum #1 §1.3 drop of `stream-discovery` skill respected.
7. `grep -nE 'v\\d|v\[0-9\]' scripts/lib/per-entry/*.sh` — three different pack-changelog regex shapes confirmed (S1).
8. Live bash test of `pe_strip_backpointer_stdin` and `pe_first_line_is_backpointer` against trailing-whitespace edge case — both reject (S4).
9. Live bash test of `pe_supporting_files_admitted /tmp/nonexistent` — empty output, RC=0 per design (good).
10. Live bash test of `pe_stream_for_path /tmp/random/unrecognized` — RC=1 (good — confirms the documented unrecognized-path contract).
11. `grep -nE "EXIT_GATE_FAILED" scripts/lib/migrator-core.sh` — confirms `readonly EXIT_GATE_FAILED=31` at line 74; mirror-generate.sh's `${EXIT_GATE_FAILED:-31}` fallback is sound.
12. `grep -n BD-164 BACKLOG.md` — BD-164 entry at line 1509; Status: Open (correct for pre-19h batch state per implicit-flip rule).

Round-trip and byte-identity invariants verified by the test suite; no manual additional check necessary.

## §4 — Out-of-scope observations

These are not BD-164 territory but were noticed while reviewing.

**O1 — `.github/workflows/validate-pack.yml:156` references `test-validate-pack-checks-32-33-34.sh` which does not yet exist (BD-168 ships it in commit 19e).** If CI is run today (before BD-168 lands) the step will fail with "No such file or directory." This is a known pre-existing condition introduced by whichever commit wired BD-168's test into CI ahead of the test runner's creation. Not BD-164's bug, but worth flagging because BD-164's M1 fix lands in the same workflow file — Pack Chat should resolve the ordering when applying the M1 fix (either add BD-164's runner alone, or pair it with a BD-168 runner stub).

**O2 — Sidecar §3.4 originally allowed `phase-N.M.md` per-task files; Addendum #1 §6.4 BD-167 spec locked "tasks inline / no per-task files."** The BD-164 implementation correctly applies the addendum (`^phase-[0-9]+\.md$` only). Per the authority-precedence ordering (Addendum #1 > sidecar), this is correct — but a reader of just the sidecar would expect `phase-N.M.md` admitted. A one-line comment in `_lib.sh:91-97` noting "per Addendum #1 §6.4 override of sidecar §3.4" would aid future archeology. Same observation already appears in `decompose.sh:125` — bring the parallel comment to `_lib.sh`.

**O3 — Sidecar §5.1 names a "trailer line stamping the regeneration time and the generator version" as a third element of `_toc.md`.** The BD-164 TOC regenerator emits a single `<!-- generated by … DO NOT EDIT BY HAND -->` HTML comment near the top (toc-regenerate.sh:250) but NO version stamp. This may be deliberate (a generator-version stamp would make the TOC mtime/content unstable across pack version-bumps, breaking determinism); if so, the deviation from sidecar §5.1 deserves explicit acknowledgement in the impl report or a one-line comment in the helper. If not deliberate, it's an omission worth picking up.

**O4 — Plan §5.1 names `scripts/lib/per-entry/_lib.sh` as a "recommended sub-helper for shared parsing logic; planner picks final."** The coder shipped it. The integration parent §18.1 #2 explicitly recommends "a sub-directory because three helpers have distinct surfaces and shared parsing logic suggests a `_lib.sh` helper too. Planner-final." Decision is fully concordant with all upstream guidance; no defect, just confirmation.

**O5 — `IMPLEMENTATION-REPORT-BD-164.md:57` claims `mirror-generate.sh` is "276 lines"; current file is 331 lines.** Expected per prompt context (BD-165 added 54 lines for the `_MIGRATOR_MODE`-aware case block). Worth noting that the impl report's line counts capture the BD-164-only state; downstream reviewers reading the impl report after BD-165 lands may be confused. A one-line "as of pre-BD-165" note would help.

---

**Total findings:** 1 MUST, 4 SHOULD, 6 NIT, 5 OUT-OF-SCOPE.
